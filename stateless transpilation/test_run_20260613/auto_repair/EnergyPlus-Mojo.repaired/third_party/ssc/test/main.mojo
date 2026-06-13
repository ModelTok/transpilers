from gtest import *
from memory import memset
from os import getenv
from sys import argv

def main(argc: Int, argv: Pointer[Pointer[UInt8]]) -> Int:
    print("Running main() from gtest_main.cc")
    testing.InitGoogleTest(argc, argv)
    var status: Int = RUN_ALL_TESTS()
    if not status:
        print("Tests Pass!")
    return status