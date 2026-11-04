"""Owner-only, loopback curriculum editor and realtime study room service."""

from __future__ import annotations

import argparse
import hashlib
import hmac
import json
import logging
import os
import secrets
import time
from datetime import datetime
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from threading import Lock
from typing import Any

from build_curriculum import CATALOG, OUTPUT, compile_catalog, validate
from realtime_hub import RealtimeHub

logger = logging.getLogger('soyle.admin')
MAX_REQUEST_BYTES = 200_000
ALLOWED_LEVELS = {'A1', 'A2', 'B1', 'B2', 'C1'}


def _read_json(handler: BaseHTTPRequestHandler, *, limit: int = MAX_REQUEST_BYTES) -> Any:
    length = int(handler.headers.get('Content-Length', '0'))
    if not 0 < length <= limit:
        raise ValueError('Invalid request size')
    return json.loads(handler.rfile.read(length))


def _save_catalog(catalog_path: Path, output_path: Path, lessons: list[dict]) -> None:
    validate(lessons)
    backup_dir = catalog_path.parent / '.backups'
    backup_dir.mkdir(exist_ok=True)
    stamp = datetime.now().strftime('%Y%m%d-%H%M%S-%f')
    (backup_dir / f'{stamp}.json').write_bytes(catalog_path.read_bytes())
    compile_catalog(lessons, output_path)
    temporary = catalog_path.with_suffix('.tmp')
    temporary.write_text(json.dumps(lessons, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    temporary.replace(catalog_path)


def make_server(
    catalog: Path = CATALOG,
    output: Path = OUTPUT,
    token: str | None = None,
    port: int = 8766,
    password: str | None = None,
    realtime: RealtimeHub | None = None,
) -> ThreadingHTTPServer:
    owner_token = token or secrets.token_urlsafe(32)
    catalog_lock = Lock()
    password = password or os.environ.get('SOYLE_ADMIN_PASSWORD')
    password_file = Path(__file__).with_name('.admin-password')
    if password is None:
        if not password_file.exists():
            password_file.write_text(secrets.token_urlsafe(14), encoding='utf-8')
        password = password_file.read_text(encoding='utf-8').strip()
    password_digest = hashlib.sha256(password.encode()).digest()
    failures: list[float] = []
    sessions: dict[str, float] = {}

    class Handler(BaseHTTPRequestHandler):
        server_version = 'SOYLE/1.0'

        def log_message(self, format: str, *args: object) -> None:
            logger.info('admin %s - %s', self.client_address[0], format % args)

        def respond(self, status: int, data: Any, mime: str = 'application/json; charset=utf-8') -> None:
            body = data if isinstance(data, bytes) else json.dumps(data, ensure_ascii=False).encode('utf-8')
            self.send_response(status)
            self.send_header('Content-Type', mime)
            self.send_header('Cache-Control', 'no-store')
            self.send_header('X-Content-Type-Options', 'nosniff')
            self.send_header('Content-Length', str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def authorized(self) -> bool:
            bearer_ok = hmac.compare_digest(
                self.headers.get('Authorization', ''), 'Bearer ' + owner_token
            )
            cookies = self.headers.get('Cookie', '').split(';')
            session = next(
                (part.strip()[14:] for part in cookies if part.strip().startswith('soyle_session=')),
                '',
            )
            return bearer_ok or sessions.get(session, 0) > time.time()

        def valid_origin(self) -> bool:
            origin = self.headers.get('Origin')
            if not origin:
                return True
            expected = {
                f'http://127.0.0.1:{self.server.server_port}',
                f'http://localhost:{self.server.server_port}',
            }
            return origin in expected

        def require_owner(self) -> bool:
            if not self.authorized():
                self.respond(401, {'error': 'Unauthorized'})
                logger.warning('Rejected unauthenticated admin request to %s', self.path)
                return False
            if not self.valid_origin():
                self.respond(403, {'error': 'Origin rejected'})
                return False
            return True

        def do_GET(self) -> None:
            if self.path == '/login':
                return self.respond(
                    200,
                    Path(__file__).with_name('admin_login.html').read_bytes(),
                    'text/html; charset=utf-8',
                )
            if self.path == '/':
                return self.respond(
                    200,
                    Path(__file__).with_name('admin.html').read_bytes(),
                    'text/html; charset=utf-8',
                )
            if self.path == '/api/health':
                return self.respond(200, {'ok': True, 'realtime': bool(realtime)})
            if self.path == '/api/catalog':
                if not self.require_owner():
                    return
                with catalog_lock:
                    return self.respond(200, json.loads(catalog.read_text(encoding='utf-8')))
            self.respond(404, {'error': 'Not found'})

        def do_POST(self) -> None:
            if self.path == '/api/login':
                if not self.valid_origin():
                    return self.respond(403, {'error': 'Origin rejected'})
                try:
                    data = _read_json(self, limit=4096)
                    with catalog_lock:
                        failures[:] = [stamp for stamp in failures if stamp > time.time() - 60]
                        if len(failures) >= 5:
                            logger.warning('Admin login temporarily rate limited')
                            return self.respond(429, {'error': 'Too many attempts. Wait 60 seconds.'})
                        submitted = hashlib.sha256(str(data.get('password', '')).encode()).digest()
                        if not hmac.compare_digest(submitted, password_digest):
                            failures.append(time.time())
                            logger.warning('Admin login failed')
                            return self.respond(401, {'error': 'Incorrect password'})
                        session = secrets.token_urlsafe(32)
                        sessions[session] = time.time() + 3600
                    self.send_response(200)
                    self.send_header(
                        'Set-Cookie',
                        f'soyle_session={session}; HttpOnly; SameSite=Strict; Path=/; Max-Age=3600',
                    )
                    self.send_header('Content-Type', 'application/json; charset=utf-8')
                    self.send_header('Cache-Control', 'no-store')
                    self.end_headers()
                    self.wfile.write(b'{"ok":true}')
                    logger.info('Owner signed in to the curriculum panel')
                except (ValueError, TypeError, json.JSONDecodeError):
                    self.respond(400, {'error': 'Invalid request'})
                return

            if not self.require_owner():
                return
            if self.path == '/api/announcement':
                if realtime is None:
                    return self.respond(503, {'error': 'Realtime service is unavailable'})
                try:
                    data = _read_json(self, limit=4096)
                    event = realtime.announce(str(data.get('text', '')))
                    return self.respond(200, {'ok': True, 'message': event})
                except (ValueError, TypeError, json.JSONDecodeError) as error:
                    return self.respond(400, {'error': str(error) or 'Invalid announcement'})

            if self.path != '/api/lesson':
                return self.respond(404, {'error': 'Not found'})
            try:
                lesson = _read_json(self)
                if not isinstance(lesson, dict):
                    raise ValueError('Expected a lesson object')
                if type(lesson.get('id')) is not int or lesson['id'] <= 0:
                    raise ValueError('Invalid lesson id')
                if lesson.get('level') not in ALLOWED_LEVELS:
                    raise ValueError('Invalid course level')
                if type(lesson.get('minutes')) is not int or not 5 <= lesson['minutes'] <= 120:
                    raise ValueError('Duration must be 5-120 minutes')
                with catalog_lock:
                    lessons = json.loads(catalog.read_text(encoding='utf-8'))
                    match = next((i for i, item in enumerate(lessons) if item['id'] == lesson['id']), None)
                    action = 'updated' if match is not None else 'created'
                    if match is None:
                        lessons.append(lesson)
                    else:
                        lessons[match] = lesson
                    _save_catalog(catalog, output, lessons)
                logger.info('Owner %s curriculum lesson id=%s', action, lesson['id'])
                return self.respond(200, {'ok': True, 'count': len(lessons), 'action': action})
            except (AssertionError, ValueError, KeyError, TypeError, json.JSONDecodeError) as error:
                logger.warning('Rejected invalid lesson save: %s', error)
                return self.respond(400, {'error': str(error) or 'Incomplete lesson content'})

        def do_DELETE(self) -> None:
            if not self.require_owner():
                return
            prefix = '/api/lesson/'
            if not self.path.startswith(prefix):
                return self.respond(404, {'error': 'Not found'})
            try:
                lesson_id = int(self.path[len(prefix):])
                with catalog_lock:
                    lessons = json.loads(catalog.read_text(encoding='utf-8'))
                    remaining = [lesson for lesson in lessons if lesson['id'] != lesson_id]
                    if len(remaining) == len(lessons):
                        return self.respond(404, {'error': 'Lesson not found'})
                    _save_catalog(catalog, output, remaining)
                logger.info('Owner deleted curriculum lesson id=%s', lesson_id)
                return self.respond(200, {'ok': True, 'count': len(remaining)})
            except (AssertionError, ValueError, KeyError, TypeError) as error:
                logger.warning('Rejected curriculum deletion: %s', error)
                return self.respond(400, {'error': str(error) or 'Invalid lesson id'})

    server = ThreadingHTTPServer(('127.0.0.1', port), Handler)
    server.realtime = realtime
    server.access_token = owner_token
    return server


def main() -> None:
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s %(levelname)s %(name)s %(message)s',
    )
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--port', type=int, default=8766)
    parser.add_argument('--realtime-port', type=int, default=8767)
    args = parser.parse_args()
    realtime = RealtimeHub(port=args.realtime_port)
    realtime.start()
    server = make_server(port=args.port, realtime=realtime)
    logger.info('Admin login: http://127.0.0.1:%s/login', server.server_port)
    logger.info('Realtime study room: ws://127.0.0.1:%s', realtime.port)
    logger.info('Owner password is stored in tool/.admin-password')
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        logger.info('Shutting down SOYLE local services')
    finally:
        server.server_close()
        realtime.close()


if __name__ == '__main__':
    main()
