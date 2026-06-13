import unittest

struct a:
    let a1 = 0
    let a2 = 1
    let a3 = 2

struct b:
    let b1 = 0
    let b2 = 1
    let b3 = 2

struct A:
    let a1 = 0
    let a2 = 1
    let a3 = 2

struct B:
    let b1 = 0
    let b2 = 1
    let b3 = 2

class MMapTest: unittest.TestCase:
    fn setUp(self):
        pass

    fn test_double(self):
        self.assertEqual("Begin Test: Multimap with doubles.", "Begin Test: Multimap with doubles.")
        
        var aMap: Dict[(Int, Int), Double] = [:]
        aMap[(a().a1, b().b1)] = 1.0
        aMap[(a().a2, b().b2)] = 2.0

        self.assertEqual(1.0, aMap[(a().a1, b().b1)])
        self.assertEqual(2.0, aMap[(a().a2, b().b2)])

    fn test_string(self):
        self.assertEqual("Begin Test: Multimap with strings.", "Begin Test: Multimap with strings.")
        
        var aMap: Dict[(Int, Int), String] = [:]
        aMap[(A().a1, B().b1)] = "Value1"
        aMap[(A().a2, B().b2)] = "Value2"

        self.assertEqual("Value1", aMap[(A().a1, B().b1)])
        self.assertEqual("Value2", aMap[(A().a2, B().b2)])

unittest.main()
