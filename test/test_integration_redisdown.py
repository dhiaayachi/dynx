import unittest
import http.client
import time
import json
import subprocess


class DockerCtrl:
    def __init__(self):
        self.state = "unpaused"
        self.redis_id = ""
    def pauseRedis(self):
        if self.state == "unpaused":
            self.redis_id = subprocess.check_output(['docker', 'ps', '--quiet', '--filter', 'ancestor=redis:4.0-alpine']).decode("utf-8", "ignore").rstrip()
            print("pause: " + self.redis_id)
            cmd_id = subprocess.check_output(['docker', 'pause', self.redis_id]).decode("utf-8", "ignore").rstrip()
            print(cmd_id)
            if cmd_id != self.redis_id:
                raise ValueError("Message")
            self.state = "paused"
    def unpauseRedis(self):
        if self.state == "paused":
            print("unpause: " + self.redis_id)
            cmd_id = subprocess.check_output(['docker', 'unpause', self.redis_id]).decode("utf-8", "ignore").rstrip()
            print(cmd_id)
            if cmd_id != self.redis_id:
                raise ValueError("Message")
            self.state = "unpaused"


class TestUtils:
    def sendRequest(host, port, method, path):
        conn = http.client.HTTPConnection(host, port)
        conn.request(method, path)
        response = conn.getresponse()
        data = response.read()
        conn.close()
        return response, data
    


class TestDynxRedisDown(unittest.TestCase):

    def test_404NoConfigRedisDown(self):
        dockerctl = DockerCtrl()
        dockerctl.pauseRedis()
        response, _ = TestUtils.sendRequest("localhost",8666,"GET","/httpbin")
        self.assertEqual(response.status, 404)
        dockerctl.unpauseRedis()

    def test_DownBeforeConfig(self):
        dockerctl = DockerCtrl()
        dockerctl.pauseRedis()
        response, _ = TestUtils.sendRequest("localhost",8888,"GET","/configure?location=/httpbin&upstream=http://httpbin.org/anything&ttl=5")
        dockerctl.unpauseRedis()
        self.assertEqual(response.status, 500)

    def test_DownAfterConfig(self):
        dockerctl = DockerCtrl()
        response, _ = TestUtils.sendRequest("localhost",8888,"GET","/configure?location=/httpbin&upstream=http://httpbin.org/anything&ttl=5")
        self.assertEqual(response.status, 200)
        dockerctl.pauseRedis()
        response, _ = TestUtils.sendRequest("localhost",8666,"GET","/httpbin")
        dockerctl.unpauseRedis()
        self.assertEqual(response.status, 503)

    def test_DownAfterCached(self):
        dockerctl = DockerCtrl()
        response, _ = TestUtils.sendRequest("localhost",8888,"GET","/configure?location=/httpbin&upstream=http://httpbin.org/anything&ttl=5")
        self.assertEqual(response.status, 200)
        response, _ = TestUtils.sendRequest("localhost",8666,"GET","/httpbin")
        self.assertEqual(response.status, 200)
        dockerctl.pauseRedis()
        response, _ = TestUtils.sendRequest("localhost",8666,"GET","/httpbin")
        dockerctl.unpauseRedis()
        self.assertEqual(response.status, 200)

    def test_DownAfterCachedAndStale(self):
        dockerctl = DockerCtrl()
        response, _ = TestUtils.sendRequest("localhost",8888,"GET","/configure?location=/httpbin&upstream=http://httpbin.org/anything&ttl=5")
        self.assertEqual(response.status, 200)
        response, _ = TestUtils.sendRequest("localhost",8666,"GET","/httpbin")
        self.assertEqual(response.status, 200)
        time.sleep(8)
        dockerctl.pauseRedis()
        response, _ = TestUtils.sendRequest("localhost",8666,"GET","/httpbin")
        dockerctl.unpauseRedis()
        self.assertEqual(response.status, 200)

if __name__ == '__main__':   
    unittest.main()
