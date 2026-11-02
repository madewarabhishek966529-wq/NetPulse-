import logging
import json
from typing import Set
from fastapi import WebSocket

logger = logging.getLogger("netpulse.websocket")


class ConnectionManager:
    """
    Manages active WebSocket connections from Flutter frontend or Browser extension,
    broadcasting real-time download and analyzer state changes.
    """

    def __init__(self):
        self.active_connections: Set[WebSocket] = set()

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.add(websocket)
        logger.info("WebSocket client connected. Active: %d", len(self.active_connections))

    def disconnect(self, websocket: WebSocket):
        self.active_connections.discard(websocket)
        logger.info("WebSocket client disconnected. Active: %d", len(self.active_connections))

    async def broadcast_json(self, data: dict):
        if not self.active_connections:
            return

        dead_connections = set()
        message_str = json.dumps(data)

        for connection in self.active_connections:
            try:
                await connection.send_text(message_str)
            except Exception as e:
                logger.warning("Failed to send WebSocket message: %s", e)
                dead_connections.add(connection)

        for dead in dead_connections:
            self.disconnect(dead)


ws_manager = ConnectionManager()

