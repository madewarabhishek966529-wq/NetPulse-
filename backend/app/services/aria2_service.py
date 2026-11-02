import os
import json
import socket
import logging
from pathlib import Path
from typing import Dict, Any, List, Optional
import httpx

logger = logging.getLogger("netpulse.aria2")


def _get_engine_config() -> tuple[int, Optional[str]]:
    """
    Attempts to read active aria2 port and secret saved by NetPulse.
    """
    candidates = [
        Path(".netpulse") / "engine_config.json",
        Path(".netpulse_data") / "engine_config.json",
    ]
    for cfg_file in candidates:
        if cfg_file.exists():
            try:
                with open(cfg_file, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    return int(data.get("port", 6800)), data.get("secret")
            except Exception:
                pass
    return 6800, None


def is_port_open(port: int = 6800, timeout: float = 0.05) -> bool:
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(timeout)
    try:
        res = s.connect_ex(("127.0.0.1", port))
        return res == 0
    except Exception:
        return False
    finally:
        s.close()


class Aria2Service:
    """
    Communicates with the local aria2 JSON-RPC server.
    Supports queries, task additions, pauses, resumes, and status checks.
    """

    def __init__(
        self,
        rpc_url: Optional[str] = None,
        secret: Optional[str] = None
    ):
        self._custom_rpc_url = rpc_url
        self._custom_secret = secret
        self._request_id = 1

    @property
    def rpc_info(self) -> tuple[str, Optional[str], int]:
        if self._custom_rpc_url:
            return self._custom_rpc_url, self._custom_secret, 6800
        port, secret = _get_engine_config()
        return f"http://127.0.0.1:{port}/jsonrpc", secret, port

    async def _call(self, method: str, params: Optional[List[Any]] = None) -> Any:
        if os.environ.get("TESTING") == "1":
            return None

        url, secret, port = self.rpc_info

        # Fast socket check - do not hang if daemon is offline
        if not is_port_open(port):
            return None

        if params is None:
            params = []

        if secret:
            params = [f"token:{secret}"] + params

        payload = {
            "jsonrpc": "2.0",
            "id": f"netpulse_backend_{self._request_id}",
            "method": method,
            "params": params,
        }
        self._request_id += 1

        try:
            async with httpx.AsyncClient(timeout=httpx.Timeout(5.0, connect=1.0)) as client:
                resp = await client.post(url, json=payload)
                resp.raise_for_status()
                data = resp.json()
                if "error" in data:
                    logger.error("aria2 RPC error: %s", data["error"])
                    raise RuntimeError(f"aria2 RPC error: {data['error'].get('message', 'Unknown')}")
                return data.get("result")
        except (httpx.ConnectError, httpx.TimeoutException, OSError) as e:
            logger.warning("aria2 JSON-RPC not reachable at %s: %s", url, e)
            return None
        except Exception as e:
            logger.error("aria2 call exception on %s: %s", method, e)
            raise

    async def get_version(self) -> Optional[Dict[str, Any]]:
        try:
            return await self._call("aria2.getVersion")
        except Exception:
            return None

    async def is_connected(self) -> bool:
        ver = await self.get_version()
        return ver is not None and "version" in ver

    async def add_uri(
        self,
        uris: List[str],
        options: Optional[Dict[str, str]] = None
    ) -> Optional[str]:
        opts = options or {}
        if "file-allocation" not in opts:
            opts["file-allocation"] = "none"
        params = [uris, opts]
        return await self._call("aria2.addUri", params)

    async def add_torrent(
        self,
        torrent_base64: str,
        options: Optional[Dict[str, str]] = None
    ) -> Optional[str]:
        opts = options or {}
        if "file-allocation" not in opts:
            opts["file-allocation"] = "none"
        params = [torrent_base64, [], opts]
        return await self._call("aria2.addTorrent", params)

    async def tell_status(
        self,
        gid: str,
        keys: Optional[List[str]] = None
    ) -> Optional[Dict[str, Any]]:
        params = [gid]
        if keys:
            params.append(keys)
        return await self._call("aria2.tellStatus", params)

    async def tell_active(self, keys: Optional[List[str]] = None) -> List[Dict[str, Any]]:
        params = []
        if keys:
            params.append(keys)
        res = await self._call("aria2.tellActive", params)
        return res if isinstance(res, list) else []

    async def tell_waiting(
        self,
        offset: int = 0,
        num: int = 100,
        keys: Optional[List[str]] = None
    ) -> List[Dict[str, Any]]:
        params = [offset, num]
        if keys:
            params.append(keys)
        res = await self._call("aria2.tellWaiting", params)
        return res if isinstance(res, list) else []

    async def tell_stopped(
        self,
        offset: int = 0,
        num: int = 100,
        keys: Optional[List[str]] = None
    ) -> List[Dict[str, Any]]:
        params = [offset, num]
        if keys:
            params.append(keys)
        res = await self._call("aria2.tellStopped", params)
        return res if isinstance(res, list) else []

    async def pause(self, gid: str) -> Optional[str]:
        return await self._call("aria2.pause", [gid])

    async def unpause(self, gid: str) -> Optional[str]:
        return await self._call("aria2.unpause", [gid])

    async def remove(self, gid: str) -> Optional[str]:
        return await self._call("aria2.remove", [gid])

    async def remove_download_result(self, gid: str) -> Optional[str]:
        return await self._call("aria2.removeDownloadResult", [gid])

    async def get_global_stat(self) -> Optional[Dict[str, Any]]:
        return await self._call("aria2.getGlobalStat")

    async def set_global_option(self, options: Dict[str, str]) -> Optional[str]:
        return await self._call("aria2.changeGlobalOption", [options])


# Global singleton instance
aria2_service = Aria2Service()
