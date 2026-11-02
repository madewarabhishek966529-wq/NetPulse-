import os
import asyncio
import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware

from app.database.db import init_db, SessionLocal, DownloadRecord
from app.api.endpoints import router as api_router
from app.websocket.manager import ws_manager
from app.services.aria2_service import aria2_service

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] [%(name)s] %(message)s"
)
logger = logging.getLogger("netpulse.backend")


async def sync_aria2_status_loop():
    """
    Background worker periodically querying active aria2 downloads
    and broadcasting live metrics over WebSockets every second.
    """
    logger.info("Starting background aria2 synchronization worker...")
    while True:
        try:
            active_downloads = await aria2_service.tell_active()
            if active_downloads and ws_manager.active_connections:
                metrics = []
                for item in active_downloads:
                    gid = item.get("gid")
                    completed = int(item.get("completedLength", 0))
                    total = int(item.get("totalLength", 0))
                    speed = int(item.get("downloadSpeed", 0))
                    progress = (completed / total) if total > 0 else 0.0

                    metrics.append({
                        "gid": gid,
                        "downloaded_bytes": completed,
                        "total_bytes": total,
                        "speed_bps": speed,
                        "progress": round(progress, 4),
                        "status": item.get("status", "active")
                    })

                await ws_manager.broadcast_json({
                    "event": "download_tick",
                    "downloads": metrics
                })
        except Exception as e:
            logger.debug("Aria2 sync error (normal if engine is idle): %s", e)

        await asyncio.sleep(1.0)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    logger.info("Initializing NetPulse backend database...")
    init_db()
    sync_task = None
    if os.environ.get("TESTING") != "1":
        sync_task = asyncio.create_task(sync_aria2_status_loop())
    yield
    # Shutdown
    if sync_task:
        sync_task.cancel()
    logger.info("NetPulse backend stopped.")



app = FastAPI(
    title="NetPulse Core API",
    description="High-Speed Smart Download Manager Backend with Smart URL Analyzer and aria2 RPC integration.",
    version="1.0.0",
    lifespan=lifespan,
)

# Configure CORS for Flutter desktop and Chrome/Edge extensions
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount REST API
app.include_router(api_router)


@app.websocket("/ws/downloads")
async def websocket_endpoint(websocket: WebSocket):
    await ws_manager.connect(websocket)
    try:
        while True:
            # Keep connection alive & listen for client messages
            msg = await websocket.receive_text()
            logger.debug("Received WebSocket message: %s", msg)
    except WebSocketDisconnect:
        ws_manager.disconnect(websocket)
    except Exception as e:
        logger.warning("WebSocket connection dropped: %s", e)
        ws_manager.disconnect(websocket)


@app.get("/")
async def root():
    return {
        "app": "NetPulse Download Manager",
        "status": "online",
        "api_docs": "/docs"
    }
