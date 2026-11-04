import copy
import json
import tempfile
import threading
import unittest
from pathlib import Path
from urllib.request import Request, urlopen
from urllib.error import HTTPError
from admin_server import make_server
from build_curriculum import CATALOG
from realtime_hub import RealtimeHub

class AdminTests(unittest.TestCase):
    def setUp(self):
        temp_root = CATALOG.parents[2] / '.test-tmp'
        temp_root.mkdir(exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(dir=temp_root)
        self.catalog = Path(self.temp.name) / 'catalog.json'
        self.catalog.write_bytes(CATALOG.read_bytes())
        self.output = Path(self.temp.name) / 'catalog.dart'
        self.realtime = RealtimeHub(port=0)
        self.realtime.start()
        self.server = make_server(self.catalog, self.output, 'owner-secret', 0, password='TestOwner9', realtime=self.realtime)
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()
        self.url = f'http://127.0.0.1:{self.server.server_port}'
    def tearDown(self):
        self.server.shutdown(); self.server.server_close(); self.thread.join(); self.realtime.close(); self.temp.cleanup()
    def request(self, path, data=None, token='owner-secret', method=None):
        headers = {'Authorization': 'Bearer ' + token, 'Content-Type': 'application/json'}
        return urlopen(Request(self.url + path, data=None if data is None else json.dumps(data).encode(), headers=headers, method=method), timeout=5)
    def test_unauthorized_cannot_read_or_change_catalog(self):
        for path, data, method in [('/api/catalog', None, 'GET'), ('/api/lesson', {}, 'POST'), ('/api/lesson/1', None, 'DELETE')]:
            with self.assertRaises(HTTPError) as error: self.request(path, data, token='learner', method=method)
            self.assertEqual(error.exception.code, 401)
    def test_password_login_sets_private_session_and_rejects_wrong_password(self):
        with self.assertRaises(HTTPError) as error: self.request('/api/login', {'password': 'wrong'}, token='')
        self.assertEqual(error.exception.code, 401)
        response = self.request('/api/login', {'password': 'TestOwner9'}, token='')
        cookie = response.headers['Set-Cookie']
        self.assertIn('HttpOnly', cookie)
        request = Request(self.url + '/api/catalog', headers={'Cookie': cookie.split(';')[0]})
        self.assertEqual(len(json.loads(urlopen(request).read())), 75)
    def test_login_rate_limits_password_guesses(self):
        for _ in range(5):
            with self.assertRaises(HTTPError): self.request('/api/login', {'password': 'wrong'}, token='')
        with self.assertRaises(HTTPError) as error: self.request('/api/login', {'password': 'TestOwner9'}, token='')
        self.assertEqual(error.exception.code, 429)
    def test_incomplete_content_is_rejected_without_writing(self):
        original = self.catalog.read_bytes()
        with self.assertRaises(HTTPError) as error: self.request('/api/lesson', {'id': 7, 'minutes': 18})
        self.assertEqual(error.exception.code, 400)
        self.assertEqual(original, self.catalog.read_bytes())
    def test_owner_edits_both_languages_and_generates_flutter_catalog(self):
        data = json.loads(self.request('/api/catalog').read())
        lesson = copy.deepcopy(data[0]); lesson['title']['en'] = 'Alphabet and pronunciation'
        self.assertEqual(json.loads(self.request('/api/lesson', lesson).read())['ok'], True)
        self.assertIn('Alphabet and pronunciation', self.output.read_text(encoding='utf-8'))
        self.assertEqual(len(list((self.catalog.parent / '.backups').glob('*.json'))), 1)
        self.assertEqual(len(json.loads(self.catalog.read_text(encoding='utf-8'))), 75)

    def test_owner_can_delete_a_lesson_and_create_a_backup(self):
        lesson_id = max(item['id'] for item in json.loads(self.catalog.read_text(encoding='utf-8')))
        response = self.request(f'/api/lesson/{lesson_id}', method='DELETE')
        self.assertEqual(json.loads(response.read())['count'], 74)
        self.assertFalse(any(item['id'] == lesson_id for item in json.loads(self.catalog.read_text(encoding='utf-8'))))
        self.assertTrue(self.output.exists())
        self.assertEqual(len(list((self.catalog.parent / '.backups').glob('*.json'))), 1)

    def test_owner_can_send_an_announcement_to_the_realtime_room(self):
        response = self.request('/api/announcement', {'text': 'Жаңа сабақ дайын!'})
        body = json.loads(response.read())
        self.assertTrue(body['ok'])
        self.assertEqual(self.realtime.history[-1]['type'], 'announcement')
        self.assertEqual(self.realtime.history[-1]['text'], 'Жаңа сабақ дайын!')

    def test_announcement_length_is_validated(self):
        with self.assertRaises(HTTPError) as error:
            self.request('/api/announcement', {'text': ' '})
        self.assertEqual(error.exception.code, 400)

if __name__ == '__main__': unittest.main()
