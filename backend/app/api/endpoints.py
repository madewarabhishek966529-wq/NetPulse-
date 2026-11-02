import os
import logging
from pathlib import Path
from datetime import datetime, timezone
from typing import List, Dict, Any, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.database.db import (
    get_db,
    DownloadRecord,
    DownloadHistoryRecord,
    SettingRecord,
    BrowserEventRecord,
    AnalyzerHistoryRecord,
)
from app.models.schemas import (
    AnalyzeRequest,
    AnalyzeResponse,
    DownloadCreateRequest,
    DownloadItemResponse,
    BrowserLinkRequest,
    SettingsResponse,
    HealthResponse,
)
from app.services.analyzer_service import analyzer_service
from app.services.aria2_service import aria2_service
from app.websocket.manager import ws_manager

logger = logging.getLogger("netpulse.api")
router = APIRouter(prefix="/api")


# -------------------------------------------------------------------------
# Health & Status
# -------------------------------------------------------------------------
@router.get("/health", response_model=HealthResponse)
async def check_health():
    is_connected = False
    ver_str = None
    try:
        ver_info = await aria2_service.get_version()
        if ver_info and "version" in ver_info:
            is_connected = True
            ver_str = ver_info["version"]
    except Exception as e:
        logger.debug("Health check aria2 probe error: %s", e)

    return HealthResponse(
        status="ok",
        version="1.0.0",
        aria2_connected=is_connected,
        aria2_version=ver_str,
    )


# -------------------------------------------------------------------------
# Smart URL Analyzer
# -------------------------------------------------------------------------
@router.post("/analyze", response_model=AnalyzeResponse)
async def analyze_webpage(request: AnalyzeRequest, db: Session = Depends(get_db)):
    if not request.url or not request.url.strip():
        raise HTTPException(status_code=400, detail="A valid URL must be provided.")

    logger.info("Analyzing URL: %s", request.url)
    res = await analyzer_service.analyze(request.url.strip())

    # Record analysis in history
    try:
        history_rec = AnalyzerHistoryRecord(
            original_url=request.url.strip(),
            discovered_count=res.total_discovered,
            filtered_count=res.total_filtered,
            analysis_status=res.status,
            created_at=datetime.now(timezone.utc),
        )
        db.add(history_rec)
        db.commit()
    except Exception as e:
        logger.error("Failed to save analyzer history: %s", e)
        db.rollback()

    # Broadcast event via WebSocket
    await ws_manager.broadcast_json({
        "event": "analysis_completed",
        "url": request.url,
        "discovered_count": res.total_discovered,
        "status": res.status,
    })

    return res


# -------------------------------------------------------------------------
# Downloads Management
# -------------------------------------------------------------------------
@router.post("/downloads", response_model=DownloadItemResponse)
async def create_download(req: DownloadCreateRequest, db: Session = Depends(get_db)):
    url = req.url.strip()
    if not url:
        raise HTTPException(status_code=400, detail="Download URL cannot be empty.")

    # Determine default destination directory
    dest = req.destination
    if not dest:
        # Default to Windows Downloads folder
        userprofile = os.environ.get("USERPROFILE", str(Path.home()))
        dest = str(Path(userprofile) / "Downloads")

    Path(dest).mkdir(parents=True, exist_ok=True)

    # Prepare aria2 options
    options: Dict[str, str] = {
        "dir": dest,
        "split": str(req.connections),
        "max-connection-per-server": str(req.connections),
        "file-allocation": "none",
    }
    if req.filename:
        options["out"] = req.filename

    if req.headers:
        header_list = [f"{k}: {v}" for k, v in req.headers.items()]
        options["header"] = "\n".join(header_list)

    # Call aria2
    gid = None
    try:
        if req.is_torrent and not url.startswith("http") and not url.startswith("magnet:"):
            # Assume base64 torrent file
            gid = await aria2_service.add_torrent(url, options)
        else:
            gid = await aria2_service.add_uri([url], options)
    except Exception as e:
        logger.error("Failed to add download to aria2: %s", e)
        raise HTTPException(status_code=500, detail=f"Failed to submit task to aria2: {e}")

    if not gid:
        raise HTTPException(status_code=502, detail="aria2 rejected the download request.")

    # Infer fallback filename if not given
    filename = req.filename or url.split("?")[0].split("/")[-1] or "download"

    # Save to database
    record = DownloadRecord(
        gid=gid,
        url=url,
        filename=filename,
        file_size=0,
        downloaded_size=0,
        speed=0,
        status="active",
        destination=dest,
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc),
    )
    db.add(record)
    db.commit()
    db.refresh(record)

    # Broadcast event
    await ws_manager.broadcast_json({
        "event": "download_created",
        "gid": gid,
        "filename": filename,
        "url": url,
    })

    return DownloadItemResponse(
        id=record.id,
        gid=record.gid,
        url=record.url,
        filename=record.filename,
        file_size=record.file_size,
        downloaded_size=record.downloaded_size,
        speed=record.speed,
        status=record.status,
        destination=record.destination,
        progress=0.0,
        created_at=record.created_at.isoformat() if record.created_at else None,
    )


@router.get("/downloads", response_model=List[DownloadItemResponse])
async def list_downloads(
    status: Optional[str] = None,
    limit: int = 100,
    offset: int = 0,
    db: Session = Depends(get_db),
):
    query = db.query(DownloadRecord)
    if status:
        query = query.filter(DownloadRecord.status == status)

    records = query.order_by(DownloadRecord.id.desc()).offset(offset).limit(limit).all()

    # Query live stats from aria2 for active ones
    results = []
    for r in records:
        progress = 0.0
        speed = r.speed
        down_size = r.downloaded_size
        total_size = r.file_size
        st = r.status

        # If download is supposedly active or waiting, refresh live from aria2
        if st in ("active", "waiting"):
            try:
                live = await aria2_service.tell_status(r.gid)
                if live:
                    aria_status = live.get("status", st)
                    down_size = int(live.get("completedLength", down_size))
                    total_size = int(live.get("totalLength", total_size))
                    speed = int(live.get("downloadSpeed", 0))

                    if aria_status == "complete":
                        st = "completed"
                    elif aria_status == "paused":
                        st = "paused"
                    elif aria_status == "error":
                        st = "failed"
                    elif aria_status == "active":
                        st = "active"

                    # Update record in DB
                    r.downloaded_size = down_size
                    r.file_size = total_size
                    r.speed = speed
                    r.status = st
                    db.commit()
            except Exception:
                pass

        if total_size > 0:
            progress = min(1.0, down_size / total_size)

        eta = None
        if speed > 0 and total_size > down_size:
            eta = int((total_size - down_size) / speed)

        results.append(
            DownloadItemResponse(
                id=r.id,
                gid=r.gid,
                url=r.url,
                filename=r.filename,
                file_size=total_size,
                downloaded_size=down_size,
                speed=speed,
                status=st,
                destination=r.destination,
                progress=progress,
                eta_seconds=eta,
                created_at=r.created_at.isoformat() if r.created_at else None,
                completed_at=r.completed_at.isoformat() if r.completed_at else None,
            )
        )

    return results


@router.get("/downloads/{gid}", response_model=DownloadItemResponse)
async def get_download_detail(gid: str, db: Session = Depends(get_db)):
    record = db.query(DownloadRecord).filter(DownloadRecord.gid == gid).first()
    if not record:
        raise HTTPException(status_code=404, detail="Download not found.")

    down_size = record.downloaded_size
    total_size = record.file_size
    speed = record.speed
    st = record.status

    try:
        live = await aria2_service.tell_status(gid)
        if live:
            down_size = int(live.get("completedLength", down_size))
            total_size = int(live.get("totalLength", total_size))
            speed = int(live.get("downloadSpeed", 0))
            aria_st = live.get("status", st)
            if aria_st == "complete":
                st = "completed"
            elif aria_st == "paused":
                st = "paused"
            elif aria_st == "error":
                st = "failed"
    except Exception:
        pass

    progress = (down_size / total_size) if total_size > 0 else 0.0

    return DownloadItemResponse(
        id=record.id,
        gid=record.gid,
        url=record.url,
        filename=record.filename,
        file_size=total_size,
        downloaded_size=down_size,
        speed=speed,
        status=st,
        destination=record.destination,
        progress=min(1.0, progress),
        created_at=record.created_at.isoformat() if record.created_at else None,
        completed_at=record.completed_at.isoformat() if record.completed_at else None,
    )


@router.post("/downloads/{gid}/pause")
async def pause_download(gid: str, db: Session = Depends(get_db)):
    record = db.query(DownloadRecord).filter(DownloadRecord.gid == gid).first()
    if not record:
        raise HTTPException(status_code=404, detail="Download not found.")

    try:
        await aria2_service.pause(gid)
    except Exception as e:
        logger.warning("aria2 pause error: %s", e)

    record.status = "paused"
    db.commit()
    await ws_manager.broadcast_json({"event": "download_paused", "gid": gid})
    return {"status": "paused", "gid": gid}


@router.post("/downloads/{gid}/resume")
async def resume_download(gid: str, db: Session = Depends(get_db)):
    record = db.query(DownloadRecord).filter(DownloadRecord.gid == gid).first()
    if not record:
        raise HTTPException(status_code=404, detail="Download not found.")

    try:
        await aria2_service.unpause(gid)
    except Exception as e:
        logger.warning("aria2 unpause error: %s", e)

    record.status = "active"
    db.commit()
    await ws_manager.broadcast_json({"event": "download_resumed", "gid": gid})
    return {"status": "active", "gid": gid}


@router.post("/downloads/{gid}/cancel")
async def cancel_download(gid: str, db: Session = Depends(get_db)):
    record = db.query(DownloadRecord).filter(DownloadRecord.gid == gid).first()
    if not record:
        raise HTTPException(status_code=404, detail="Download not found.")

    try:
        await aria2_service.remove(gid)
    except Exception:
        pass

    try:
        await aria2_service.remove_download_result(gid)
    except Exception:
        pass

    record.status = "canceled"
    db.commit()
    await ws_manager.broadcast_json({"event": "download_canceled", "gid": gid})
    return {"status": "canceled", "gid": gid}


@router.post("/downloads/{gid}/retry")
async def retry_download(gid: str, db: Session = Depends(get_db)):
    record = db.query(DownloadRecord).filter(DownloadRecord.gid == gid).first()
    if not record:
        raise HTTPException(status_code=404, detail="Download not found.")

    # Re-submit to aria2
    options = {
        "dir": record.destination,
        "out": record.filename,
        "file-allocation": "none",
    }
    new_gid = await aria2_service.add_uri([record.url], options)
    if not new_gid:
        raise HTTPException(status_code=502, detail="Failed to re-submit download to aria2.")

    record.gid = new_gid
    record.status = "active"
    record.downloaded_size = 0
    record.speed = 0
    db.commit()

    await ws_manager.broadcast_json({"event": "download_retried", "gid": new_gid})
    return {"status": "active", "gid": new_gid}


# -------------------------------------------------------------------------
# Download History
# -------------------------------------------------------------------------
@router.get("/history")
async def get_download_history(
    limit: int = 50,
    offset: int = 0,
    db: Session = Depends(get_db),
):
    items = (
        db.query(DownloadHistoryRecord)
        .order_by(DownloadHistoryRecord.id.desc())
        .offset(offset)
        .limit(limit)
        .all()
    )
    return [
        {
            "id": h.id,
            "filename": h.filename,
            "source_url": h.source_url,
            "file_size": h.file_size,
            "status": h.status,
            "completed_at": h.completed_at.isoformat() if h.completed_at else None,
        }
        for h in items
    ]


@router.delete("/history/{item_id}")
async def delete_history_item(item_id: int, db: Session = Depends(get_db)):
    item = db.query(DownloadHistoryRecord).filter(DownloadHistoryRecord.id == item_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="History item not found.")
    db.delete(item)
    db.commit()
    return {"status": "deleted", "id": item_id}


# -------------------------------------------------------------------------
# Application Settings
# -------------------------------------------------------------------------
@router.get("/settings", response_model=SettingsResponse)
async def get_settings(db: Session = Depends(get_db)):
    records = db.query(SettingRecord).all()
    settings_dict = {r.key: r.value for r in records}

    # Ensure standard defaults if not present
    defaults = {
        "max_concurrent_downloads": "5",
        "default_connections_per_download": "8",
        "download_directory": str(Path(os.environ.get("USERPROFILE", str(Path.home()))) / "Downloads"),
        "speed_limit_enabled": "false",
        "max_download_speed": "0",
        "ad_blocking_enabled": "true",
        "smart_analyzer_depth": "1",
    }
    for k, v in defaults.items():
        if k not in settings_dict:
            settings_dict[k] = v

    return SettingsResponse(settings=settings_dict)


@router.put("/settings")
async def update_settings(payload: Dict[str, str], db: Session = Depends(get_db)):
    for key, value in payload.items():
        rec = db.query(SettingRecord).filter(SettingRecord.key == key).first()
        if rec:
            rec.value = str(value)
        else:
            rec = SettingRecord(key=key, value=str(value))
            db.add(rec)
    db.commit()
    return {"status": "updated", "count": len(payload)}


# -------------------------------------------------------------------------
# Browser Extension Integration
# -------------------------------------------------------------------------
@router.post("/browser/link")
async def receive_browser_link(req: BrowserLinkRequest, db: Session = Depends(get_db)):
    """
    Direct HTTP endpoint for Chrome/Edge extensions when user clicks
    'Download with NetPulse' or browser download interception triggers.
    """
    url = req.url.strip()
    if not url:
        raise HTTPException(status_code=400, detail="URL cannot be empty.")

    # Record event
    event = BrowserEventRecord(
        source=req.source,
        url=url,
        received_at=datetime.now(timezone.utc),
        status="received",
    )
    db.add(event)
    db.commit()

    # Automatically add download to aria2
    dest = str(Path(os.environ.get("USERPROFILE", str(Path.home()))) / "Downloads")
    options = {
        "dir": dest,
        "split": "8",
        "max-connection-per-server": "8",
        "file-allocation": "none",
    }
    if req.filename:
        options["out"] = req.filename
    if req.referrer:
        options["referer"] = req.referrer

    gid = await aria2_service.add_uri([url], options)
    if gid:
        filename = req.filename or url.split("?")[0].split("/")[-1] or "browser_download"
        rec = DownloadRecord(
            gid=gid,
            url=url,
            filename=filename,
            file_size=0,
            downloaded_size=0,
            speed=0,
            status="active",
            destination=dest,
            created_at=datetime.now(timezone.utc),
            updated_at=datetime.now(timezone.utc),
        )
        db.add(rec)
        db.commit()

        await ws_manager.broadcast_json({
            "event": "browser_download_added",
            "gid": gid,
            "filename": filename,
            "url": url,
            "source": req.source,
        })
        return {"status": "success", "gid": gid, "filename": filename}

    return {"status": "queued", "message": "Link recorded for processing"}


@router.post("/browser/analyze")
async def receive_browser_analyze(req: AnalyzeRequest, db: Session = Depends(get_db)):
    """
    Called by browser extension when user selects 'Analyze page with NetPulse'.
    """
    return await analyze_webpage(req, db)


@router.get("/browser/status")
async def get_browser_integration_status(db: Session = Depends(get_db)):
    events_count = db.query(BrowserEventRecord).count()
    recent = (
        db.query(BrowserEventRecord)
        .order_by(BrowserEventRecord.id.desc())
        .limit(10)
        .all()
    )
    return {
        "is_ready": True,
        "total_intercepted": events_count,
        "recent_events": [
            {
                "id": e.id,
                "source": e.source,
                "url": e.url,
                "received_at": e.received_at.isoformat() if e.received_at else None,
            }
            for e in recent
        ],
    }

