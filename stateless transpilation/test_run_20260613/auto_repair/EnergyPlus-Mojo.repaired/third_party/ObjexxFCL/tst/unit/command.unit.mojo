from ObjexxFCL.command import (
    GET_COMMAND_ARGUMENT_COUNT,
    IARGC,
    IARG,
    NUMARG,
    NARGS,
    GET_COMMAND,
    get_command,
    GET_COMMAND_ARGUMENT,
    get_command_argument,
    GETARG,
    getarg,
)
from ObjexxFCL.unit import *  # assuming this provides necessary test setup

alias OBJEXX_BUILD = True  # Assuming defined for translation
alias _WIN32 = False  # Assuming non-Windows for this translation

@test
def CommandTest_GetCommandArgumentCount_Test():
    assert(GET_COMMAND_ARGUMENT_COUNT() >= 0)

@test
def CommandTest_Iargc_Test():
    assert(IARGC() >= 0)

@test
def CommandTest_Iarg_Test():
    assert(IARG() >= 0)

@test
def CommandTest_Numarg_Test():
    assert(NUMARG() >= 0)

@test
def CommandTest_Nargs_Test():
    assert(NARGS() >= 1)

@test
def CommandTest_GetCommand_Test():
    {
        var command: String
        var length: Int
        var status: Int
        GET_COMMAND(command, length, status)
        if OBJEXX_BUILD:
            assert(command[:14] == "ObjexxFCL.unit")
            assert(14 <= length)
        assert(status == 0)
    }
    {
        var command: String
        var length: Int
        var status: Int
        get_command(command, length, status)
        if OBJEXX_BUILD:
            assert(command[:14] == "ObjexxFCL.unit")
            assert(14 <= length)
        assert(status == 0)
    }

@test
def CommandTest_GetCommandArgument_Test():
    {
        var value: String
        var length: Int
        var status: Int
        GET_COMMAND_ARGUMENT(0, value, length, status)
        if OBJEXX_BUILD:
            if _WIN32:
                assert(value == "ObjexxFCL.unit.exe")
                assert(length == 18)
            else:
                assert(value == "ObjexxFCL.unit")
                assert(length == 14)
        assert(status == 0)
    }
    {
        var value: String
        var length: Int
        var status: Int
        GET_COMMAND_ARGUMENT(999, value, length, status)  # No argument number 999
        assert(value == "")
        assert(length == 0)
        assert(status == 1)
    }
    {
        var value: String
        var length: Int
        var status: Int
        get_command_argument(0, value, length, status)
        if OBJEXX_BUILD:
            if _WIN32:
                assert(value == "ObjexxFCL.unit.exe")
                assert(length == 18)
            else:
                assert(value == "ObjexxFCL.unit")
                assert(length == 14)
        assert(status == 0)
    }
    {
        var value: String
        var length: Int
        var status: Int
        get_command_argument(999, value, length, status)  # No argument number 999
        assert(value == "")
        assert(length == 0)
        assert(status == 1)
    }

@test
def CommandTest_Getarg_Test():
    {
        var buffer: String
        var status: Int
        GETARG(0, buffer, status)
        if OBJEXX_BUILD:
            if _WIN32:
                assert(buffer == "ObjexxFCL.unit.exe")
                assert(status == 18)
            else:
                assert(buffer == "ObjexxFCL.unit")
                assert(status == 14)
    }
    {
        var buffer: String
        var status: Int
        GETARG(999, buffer, status)  # No argument number 999
        assert(buffer == "")
        assert(status == -1)
    }
    {
        var buffer: String
        var status: Int
        getarg(0, buffer, status)
        if OBJEXX_BUILD:
            if _WIN32:
                assert(buffer == "ObjexxFCL.unit.exe")
                assert(status == 18)
            else:
                assert(buffer == "ObjexxFCL.unit")
                assert(status == 14)
    }
    {
        var buffer: String
        var status: Int
        getarg(999, buffer, status)  # No argument number 999
        assert(buffer == "")
        assert(status == -1)
    }