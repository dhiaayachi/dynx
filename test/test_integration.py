import unittest
import http.client
import time

class TestStringMethods(unittest.TestCase):

    def test_404NoConfig(self):
        connRouter = http.client.HTTPConnection("localhost", 8666)
        connConfig = http.client.HTTPConnection("localhost", 8888)
        connRouter.request("GET", "/httpbin")
        response = connRouter.getresponse()
        data = response.read()
        connRouter.close()
        self.assertEqual(response.status, 404)

    def test_200WithConfig(self):
        connConfig = http.client.HTTPConnection("localhost", 8888)
        connConfig.request("GET","/configure?location=/httpbin&upstream=http://httpbin.org/anything&ttl=10")
        response = connConfig.getresponse()
        data = response.read()
        connConfig.close()
        self.assertEqual(response.status, 200)

        connRouter = http.client.HTTPConnection("localhost", 8666)
        connRouter.request("GET", "/httpbin")
        response = connRouter.getresponse()
        data = response.read()
        self.assertEqual(response.status, 200)
        connRouter.close()

        connConfig2 = http.client.HTTPConnection("localhost", 8888)
        connConfig2.request("DELETE","/configure?location=/httpbin")
        response2 = connConfig2.getresponse()
        data = response2.read()
        self.assertEqual(response2.status, 200)
        connConfig2.close()
        time.sleep(20)
        




if __name__ == '__main__':
    unittest.main()
