from gmock import *
from gtest.gtest import *
from memory import memset, memcpy
from sys import argv, argc
from os import environ

# GTEST_OS_ESP8266 and GTEST_OS_ESP32 are not defined in Mojo, so we skip those branches
# GTEST_OS_WINDOWS_MOBILE is not defined in Mojo, so we skip that branch

def main() -> Int32:
    print("Running main() from gmock_main.cc")
    testing.InitGoogleMock(addr(argc), addr(argv))
    return RUN_ALL_TESTS()