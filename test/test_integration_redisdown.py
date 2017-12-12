import unittest
import http.client
import time
import json
import subprocess
import docker
from logging import exception


class DockerCtrl:
    def __init__(self):
        self.client = docker.from_env()
        self.redis_container = self.client.containers.list(filters={'label': 'kv=redis-dyn'})[0]
        self.state = "unpaused"
    def pauseRedis(self):
        if self.state == "unpaused":
            self.redis_container.pause()
            self.state = "paused"
            time.sleep(10)
    def unpauseRedis(self):
        if self.state == "paused":
            self.redis_container.unpause()
            self.state = "unpaused"
            time.sleep(5)
    def clearRedis(self):
        try:
            self.redis_container.exec_run("redis-cli FLUSHALL")
        except Exception as ex:
            print(ex)


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
        dockerctl.clearRedis()
        dockerctl.pauseRedis()
        response, _ = TestUtils.sendRequest("localhost",8666,"GET","/httpbin")
        dockerctl.unpauseRedis()
        dockerctl.clearRedis()
        self.assertEqual(503, response.status)

    def test_404NoConfigRedisDownRemoveLocation(self):
        dockerctl = DockerCtrl()
        dockerctl.clearRedis()
        dockerctl.pauseRedis()
        response, _ = TestUtils.sendRequest("localhost",8888,"DELETE","/configure?location=/httpbin")
        dockerctl.unpauseRedis()
        dockerctl.clearRedis()
        self.assertEqual(500, response.status)

    def test_404NoConfigRedisDownFlushAll(self):
        dockerctl = DockerCtrl()
        dockerctl.clearRedis()
        dockerctl.pauseRedis()
        response, _ = TestUtils.sendRequest("localhost",8888,"DELETE","/configure?flushall=true")
        dockerctl.unpauseRedis()
        dockerctl.clearRedis()
        self.assertEqual(500, response.status)

    def test_DownBeforeConfig(self):
        dockerctl = DockerCtrl()
        dockerctl.pauseRedis()
        response, _ = TestUtils.sendRequest("localhost",8888,"GET","/configure?location=/httpbin&upstream=http://httpbin.org/anything&ttl=5")
        dockerctl.unpauseRedis()
        dockerctl.clearRedis()
        time.sleep(5)
        self.assertEqual(500, response.status)

    def test_DownAfterConfig(self):
        dockerctl = DockerCtrl()
        response, _ = TestUtils.sendRequest("localhost",8888,"GET","/configure?location=/httpbin2&upstream=http://httpbin.org/anything&ttl=5")
        self.assertEqual(200, response.status)
        dockerctl.pauseRedis()
        response, _ = TestUtils.sendRequest("localhost",8666,"GET","/httpbin2")
        dockerctl.unpauseRedis()
        dockerctl.clearRedis()
        time.sleep(8)
        self.assertEqual(503, response.status)

    def test_DownAfterCached(self):
        dockerctl = DockerCtrl()
        response, _ = TestUtils.sendRequest("localhost",8888,"GET","/configure?location=/httpbin3&upstream=http://httpbin.org/anything&ttl=5")
        self.assertEqual(200, response.status)
        response, _ = TestUtils.sendRequest("localhost",8666,"GET","/httpbin3")
        self.assertEqual(200, response.status)
        dockerctl.pauseRedis()
        response, _ = TestUtils.sendRequest("localhost",8666,"GET","/httpbin3")
        dockerctl.unpauseRedis()
        dockerctl.clearRedis()
        time.sleep(8)
        self.assertEqual(200, response.status)

    def test_DownAfterCachedAndStale(self):
        dockerctl = DockerCtrl()
        response, _ = TestUtils.sendRequest("localhost",8888,"GET","/configure?location=/httpbin4&upstream=http://httpbin.org/anything&ttl=5")
        self.assertEqual(200, response.status)
        response, _ = TestUtils.sendRequest("localhost",8666,"GET","/httpbin4")
        self.assertEqual(200, response.status)
        time.sleep(8)
        dockerctl.pauseRedis()
        response, _ = TestUtils.sendRequest("localhost",8666,"GET","/httpbin4")
        dockerctl.unpauseRedis()
        dockerctl.clearRedis()
        time.sleep(8)
        self.assertEqual(200, response.status)

if __name__ == '__main__':   
    unittest.main()
