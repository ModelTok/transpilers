import unittest

class MMapTest(unittest.TestCase):
    def setUp(self):
        pass

    def test_double(self):
        self.assertEqual("Begin Test: Multimap with doubles.", "Begin Test: Multimap with doubles.")

        class a:
            a1 = 0
            a2 = 1
            a3 = 2

        class b:
            b1 = 0
            b2 = 1
            b3 = 2

        aMap = {}
        aMap[(a.a1, b.b1)] = 1
        aMap[(a.a2, b.b2)] = 2

        self.assertEqual(1, aMap[(a.a1, b.b1)])
        self.assertEqual(2, aMap[(a.a2, b.b2)])

    def test_string(self):
        self.assertEqual("Begin Test: Multimap with strings.", "Begin Test: Multimap with strings.")

        class A:
            a1 = 0
            a2 = 1
            a3 = 2

        class B:
            b1 = 0
            b2 = 1
            b3 = 2

        aMap = {}
        aMap[(A.a1, B.b1)] = "Value1"
        aMap[(A.a2, B.b2)] = "Value2"

        self.assertEqual("Value1", aMap[(A.a1, B.b1)])
        self.assertEqual("Value2", aMap[(A.a2, B.b2)])

if __name__ == '__main__':
    unittest.main()
