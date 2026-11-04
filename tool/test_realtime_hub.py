import json
import unittest

from websockets.sync.client import connect

from realtime_hub import RealtimeHub


class RealtimeHubTests(unittest.TestCase):
    def setUp(self):
        self.hub = RealtimeHub(port=0, history_limit=3)
        self.hub.start()
        self.uri = f'ws://127.0.0.1:{self.hub.port}'

    def tearDown(self):
        self.hub.close()

    @staticmethod
    def receive(connection):
        return json.loads(connection.recv(timeout=2))

    def test_client_receives_recent_history_on_connect(self):
        self.hub.publish({'type': 'chat', 'author': 'A', 'text': 'One'})
        self.hub.publish({'type': 'announcement', 'author': 'SOYLE', 'text': 'Two'})
        with connect(self.uri) as client:
            event = self.receive(client)
        self.assertEqual(event['type'], 'history')
        self.assertEqual([item['text'] for item in event['messages']], ['One', 'Two'])

    def test_chat_message_is_broadcast_to_all_connected_students(self):
        with connect(self.uri) as sender, connect(self.uri) as receiver:
            self.receive(sender)
            self.receive(receiver)
            sender.send(json.dumps({'type': 'chat', 'author': 'Dana', 'text': 'Сәлем!' }))
            event = self.receive(receiver)
        self.assertEqual(event['type'], 'chat')
        self.assertEqual(event['message']['text'], 'Сәлем!')
        self.assertEqual(event['message']['author'], 'Dana')

    def test_invalid_chat_is_rejected_and_never_saved(self):
        with connect(self.uri) as client:
            self.receive(client)
            client.send(json.dumps({'type': 'chat', 'author': '', 'text': 'Hello'}))
            event = self.receive(client)
        self.assertEqual(event['type'], 'error')
        self.assertEqual(self.hub.history, [])

    def test_admin_announcement_reaches_connected_clients(self):
        with connect(self.uri) as client:
            self.receive(client)
            message = self.hub.announce('Жаңа сабақ дайын!')
            event = self.receive(client)
        self.assertEqual(event['type'], 'announcement')
        self.assertEqual(event['message']['id'], message['id'])

    def test_history_is_capped_to_prevent_unbounded_memory_growth(self):
        for number in range(5):
            self.hub.publish({'type': 'chat', 'author': 'A', 'text': str(number)})
        self.assertEqual([item['text'] for item in self.hub.history], ['2', '3', '4'])

    def test_message_rate_limit_sends_error_after_eight_messages(self):
        with connect(self.uri) as client:
            self.receive(client)
            for number in range(9):
                client.send(json.dumps({'type': 'chat', 'author': 'A', 'text': str(number)}))
            events = [self.receive(client) for _ in range(9)]
        self.assertEqual(events[-1]['type'], 'error')
        self.assertEqual(sum(event['type'] == 'chat' for event in events), 8)


if __name__ == '__main__':
    unittest.main()
