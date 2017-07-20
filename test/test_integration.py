import unittest
import http.client

class TestStringMethods(unittest.TestCase):

    def test_404NoConfig(self):
        connRouter = http.client.HTTPConnection("localhost", 8666)
        connConfig = http.client.HTTPConnection("localhost", 8888)
        connRouter.request("GET", "/google")
        response = connRouter.getresponse()
        self.assertEqual(response.status, 404)

    def test_200NoConfig(self):
        connRouter = http.client.HTTPConnection("localhost", 8666)
        connConfig = http.client.HTTPConnection("localhost", 8888)
        connConfig.request("GET","/configure?location=/google&upstream=http://www.google.com&ttl=10")
        response = conn.getresponse()
        self.assertEqual(response.status, 200)
        connRouter.request("GET", "/google")
        response = conn.getresponse()
        self.assertEqual(response.status, 200)
        




if __name__ == '__main__':
    unittest.main()
