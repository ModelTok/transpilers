/* Copyright (c) 2019 Big Ladder Software LLC. All rights reserved.
 * See the LICENSE file for additional terms and conditions. */
from .. import SimpleCourierr, CourierrException
from testing import assert_eq, assert_true
from sys import info
from string import String, StringRef
from memory import Buffer

# Simulated EXPECT_STDOUT macro
def expect_stdout[action: fn() captures() -> None](expected: String):
    var original_out = info().stdout
    var buffer = Buffer[String]()
    info().stdout = buffer
    action()
    var captured = buffer.to_string()
    info().stdout = original_out
    assert_eq(captured, expected)

def test_Courierr_Warning():
    var courier = SimpleCourierr()
    courier.warning("This is a warning.")

def test_Courierr_Error():
    var courier = SimpleCourierr()

def test_CourierrException_Error():
    var courier = SimpleCourierr()
    var expected_output = String("[ERROR] This is an error!")
    try:
        throw CourierrException("This is an error!", courier)
        expect_stdout[fn() -> None:
            var i = 0
        ](expected_output)
    except CourierrException:

def main() -> None:
    test_Courierr_Warning()
    test_Courierr_Error()
    test_CourierrException_Error()