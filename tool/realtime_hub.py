"""Loopback WebSocket hub for SOYLE's study room."""

from __future__ import annotations

import json
import logging
import secrets
import threading
import time
from collections import deque
from datetime import datetime, timezone
from typing import Any

from websockets.sync.server import ServerConnection, serve

logger = logging.getLogger('soyle.realtime')


class RealtimeHub:
    def __init__(self, host: str = '127.0.0.1', port: int = 8767, history_limit: int = 100):
        self.host = host
        self.port = port
        self.history_limit = max(1, history_limit)
        self._history: deque[dict[str, Any]] = deque(maxlen=self.history_limit)
        self._clients: set[ServerConnection] = set()
        self._client_times: dict[ServerConnection, deque[float]] = {}
        self._lock = threading.RLock()
        self._ready = threading.Event()
        self._thread: threading.Thread | None = None
        self._server = None
        self.startup_error: BaseException | None = None

    @property
    def history(self) -> list[dict[str, Any]]:
        with self._lock:
            return list(self._history)

    @property
    def clients(self) -> int:
        with self._lock:
            return len(self._clients)

    def start(self) -> None:
        if self._thread and self._thread.is_alive():
            return
        self._ready.clear()
        self.startup_error = None
        self._thread = threading.Thread(target=self._run, name='soyle-realtime', daemon=True)
        self._thread.start()
        if not self._ready.wait(5):
            raise TimeoutError('WebSocket service did not start in 5 seconds')
        if self.startup_error:
            raise RuntimeError('Could not start the WebSocket service') from self.startup_error

    def _run(self) -> None:
        try:
            self._server = serve(
                self._handle,
                self.host,
                self.port,
                max_size=4096,
                ping_interval=20,
                ping_timeout=20,
                close_timeout=2,
                server_header='SOYLE realtime',
            )
            self.port = self._server.socket.getsockname()[1]
            self._ready.set()
            logger.info('Realtime WebSocket listening on %s:%s', self.host, self.port)
            self._server.serve_forever()
        except BaseException as error:
            self.startup_error = error
            self._ready.set()
            if not isinstance(error, OSError):
                logger.exception('Realtime WebSocket stopped unexpectedly')

    def _handle(self, connection: ServerConnection) -> None:
        with self._lock:
            self._clients.add(connection)
            self._client_times[connection] = deque()
            history = list(self._history)
        try:
            connection.send(json.dumps({'type': 'history', 'messages': history}, ensure_ascii=False))
            logger.info('Study room client connected; active=%s', self.clients)
            for payload in connection:
                self._receive(connection, payload)
        except Exception:
            logger.info('Study room client connection ended')
        finally:
            with self._lock:
                self._clients.discard(connection)
                self._client_times.pop(connection, None)
            logger.info('Study room client disconnected; active=%s', self.clients)

    def _receive(self, connection: ServerConnection, payload: str) -> None:
        try:
            data = json.loads(payload)
            if not isinstance(data, dict) or data.get('type') != 'chat':
                raise ValueError('Unsupported message type')
            author = str(data.get('author', '')).strip()[:40]
            message = str(data.get('text', '')).strip()
            if not author or not message or len(message) > 500:
                raise ValueError('Enter a name and a message of at most 500 characters')
            if not self._allow_message(connection):
                raise ValueError('Please wait before sending another message')
            self.publish({'type': 'chat', 'author': author, 'text': message})
        except (ValueError, TypeError, json.JSONDecodeError) as error:
            self._send(connection, {'type': 'error', 'message': str(error)})
            logger.warning('Rejected invalid realtime chat message')

    def _allow_message(self, connection: ServerConnection) -> bool:
        now = time.monotonic()
        with self._lock:
            times = self._client_times.get(connection)
            if times is None:
                return False
            while times and times[0] < now - 10:
                times.popleft()
            if len(times) >= 8:
                return False
            times.append(now)
            return True

    @staticmethod
    def _send(connection: ServerConnection, event: dict[str, Any]) -> None:
        try:
            connection.send(json.dumps(event, ensure_ascii=False))
        except Exception:
            logger.debug('Could not send a realtime event to a client', exc_info=True)

    def publish(self, event: dict[str, Any]) -> dict[str, Any]:
        message = {
            'id': secrets.token_hex(8),
            'createdAt': datetime.now(timezone.utc).isoformat(),
            **event,
        }
        with self._lock:
            self._history.append(message)
            clients = list(self._clients)
        payload = json.dumps({'type': message['type'], 'message': message}, ensure_ascii=False)
        for client in clients:
            try:
                client.send(payload)
            except Exception:
                logger.debug('Realtime broadcast skipped a disconnected client', exc_info=True)
        logger.info('Realtime %s broadcast to %d clients', message['type'], len(clients))
        return message

    def announce(self, text: str) -> dict[str, Any]:
        text = text.strip()
        if not text or len(text) > 500:
            raise ValueError('Announcement must contain 1 to 500 characters')
        return self.publish({'type': 'announcement', 'author': 'SOYLE', 'text': text})

    def close(self) -> None:
        server = self._server
        if server is not None:
            server.shutdown()
        if self._thread is not None:
            self._thread.join(timeout=3)
