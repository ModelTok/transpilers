from gtest.gtest import testing
from sys import printf

alias GTEST_OS_ESP8266 = False
alias GTEST_OS_ESP32 = False

if GTEST_OS_ESP8266 or GTEST_OS_ESP32:
    if GTEST_OS_ESP8266:

    def setup():
        testing.InitGoogleTest()
    def loop():
        RUN_ALL_TESTS()
    if GTEST_OS_ESP8266:

else:
    def main(argc: Int, argv: Pointer[Pointer[UInt8]]) -> Int:
        printf("Running main() from %s\n", __FILE__)
        testing.InitGoogleTest(argc, argv)
        return RUN_ALL_TESTS()