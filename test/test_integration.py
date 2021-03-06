import unittest
import http.client
import time
import json

class TestUtils:
    def sendRequest(host, port, method, path):
        conn = http.client.HTTPConnection(host, port)
        conn.request(method, path)
        response = conn.getresponse()
        data = response.read()
        conn.close()
        return response, data


class TestDynxConfig(unittest.TestCase):

    def test_404NoConfig(self):
        response, _ = TestUtils.sendRequest("localhost",8666,"GET","/httpbin")
        self.assertEqual(response.status, 404)

    def test_200WithConfig(self):
        response, _ = TestUtils.sendRequest("localhost",8888,"GET","/configure?location=/httpbin&upstream=http://httpbin.org/anything&ttl=5")
        self.assertEqual(response.status, 200)

        response, _ = TestUtils.sendRequest("localhost",8666,"GET","/httpbin")
        self.assertEqual(response.status, 200)

        response, _ = TestUtils.sendRequest("localhost",8888,"DELETE","/configure?location=/httpbin")
        self.assertEqual(response.status, 200)
        time.sleep(8)

        response, _ = TestUtils.sendRequest("localhost",8666,"GET","/httpbin")

        self.assertEqual(response.status, 404)

        response, _ = TestUtils.sendRequest("localhost",8888,"GET","/configure?location=/httpbin&upstream=http://httpbin.org/anything&ttl=5")
        self.assertEqual(response.status, 200)
        time.sleep(10)

        response, _ = TestUtils.sendRequest("localhost",8666,"GET","/httpbin")
        self.assertEqual(response.status, 200)

        response, _ = TestUtils.sendRequest("localhost",8888,"DELETE","/configure?location=/httpbin")
        self.assertEqual(response.status, 200)
        time.sleep(10)

        response, _ = TestUtils.sendRequest("localhost",8666,"GET","/httpbin")
        self.assertEqual(response.status, 404)

    def test_flushAll(self):
        response, _ = TestUtils.sendRequest("localhost",8888,"GET","/configure?location=/httpbin2&upstream=http://httpbin.org/anything&ttl=5")
        self.assertEqual(response.status, 200)

        response, _ = TestUtils.sendRequest("localhost",8888,"GET","/configure?location=/httpbinip&upstream=http://httpbin.org/anything&ttl=5")
        self.assertEqual(response.status, 200)

        response, _ = TestUtils.sendRequest("localhost",8666,"GET","/httpbin2")
        self.assertEqual(response.status, 200)

        response, _ = TestUtils.sendRequest("localhost",8666,"GET","/httpbinip")
        self.assertEqual(response.status, 200)

        response, _ = TestUtils.sendRequest("localhost",8888,"DELETE","/configure?flushall=true")
        self.assertEqual(response.status, 200)
        time.sleep(8)

        response, _ = TestUtils.sendRequest("localhost",8666,"GET","/httpbin")
        self.assertEqual(response.status, 404)

        response, _ = TestUtils.sendRequest("localhost",8666,"GET","/httpbinip")
        self.assertEqual(response.status, 404)


    def test_200WithQueryParams(self):
        response, _ = TestUtils.sendRequest("localhost",8888,"GET","/configure?location=/httpbinq&upstream=http://httpbin.org/get&ttl=5")
        self.assertEqual(response.status, 200)

        response, body = TestUtils.sendRequest("localhost",8666,"GET","/httpbinq?dummyq=true&dummyq2=shouldwork")
        self.assertEqual(response.status, 200)
        body_dict = json.loads(body.decode("utf-8", "replace"))
        self.assertEqual(body_dict["args"]["dummyq"],"true")
        self.assertEqual(body_dict["args"]["dummyq2"],"shouldwork")

        response, _ = TestUtils.sendRequest("localhost",8888,"DELETE","/configure?location=/httpbinq")
        self.assertEqual(response.status, 200)
        time.sleep(8)

        response, _ = TestUtils.sendRequest("localhost",8666,"GET","/httpbinq")
        self.assertEqual(response.status, 404)




if __name__ == '__main__':
    unittest.main()
