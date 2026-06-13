from Optional import Optional
from memory import Pointer
from sys import argv, argc

# Global variables to mimic C++ __argc and __argv
var __argc: Int = 0
var __argv: Pointer[Pointer[UInt8]] = Pointer[Pointer[UInt8]]()

# Initialize from Python sys module
def init_globals():
    __argc = argc()
    # __argv is not directly accessible in Mojo, so we leave it as null
    # The functions will handle null pointers gracefully

@always_inline
def GET_COMMAND_ARGUMENT_COUNT() -> Int:
    return (__argc > 0 ? __argc - 1 : 0)

@always_inline
def IARGC() -> Int:
    return (__argc > 0 ? __argc - 1 : 0)

@always_inline
def IARG() -> Int:
    return (__argc > 0 ? __argc - 1 : 0)

@always_inline
def NUMARG() -> Int:
    return (__argc > 0 ? __argc - 1 : 0)

@always_inline
def NARGS() -> Int:
    return __argc

def GET_COMMAND(
    command: Optional[String] = Optional[String](),
    length: Optional[Int] = Optional[Int](),
    status: Optional[Int] = Optional[Int]()
):
    var c: String = String()
    for i in range(__argc):  # Reconstruct the command line with single spacing
        try:
            if __argv[i] != Pointer[UInt8]():
                c += String(__argv[i])
                if i + 1 < __argc:
                    c += " "
        except:
            pass  # Keep going
    if command.present():
        command = c
    if length.present():
        length = len(c)  # This doesn't account for multiple spaces between entered arguments
    if status.present():
        if __argc == 0:  # Assume command retrieval failed
            status = 1
        elif command.present() and len(command()) < len(c):
            status = -1
        else:
            status = 0

def get_command(
    command: Optional[String] = Optional[String](),
    length: Optional[Int] = Optional[Int](),
    status: Optional[Int] = Optional[Int]()
):
    var c: String = String()
    for i in range(__argc):  # Reconstruct the command line with single spacing
        try:
            if __argv[i] != Pointer[UInt8]():
                c += String(__argv[i])
                if i + 1 < __argc:
                    c += " "
        except:
            pass  # Keep going
    if command.present():
        command = c
    if length.present():
        length = len(c)  # This doesn't account for multiple spaces between entered arguments
    if status.present():
        if __argc == 0:  # Assume command retrieval failed
            status = 1
        else:
            status = 0

def GET_COMMAND_ARGUMENT(
    n: Int,
    value: Optional[String] = Optional[String](),
    length: Optional[Int] = Optional[Int](),
    status: Optional[Int] = Optional[Int]()
):
    var a: String = String()
    if (0 <= n) and (n <= __argc):  # Get the argument
        try:
            if __argv[n] != Pointer[UInt8]():
                a = String(__argv[n])
        except:
            pass  # Keep going
    if value.present():
        value = a
    if length.present():
        length = len(a)
    if status.present():
        if (n < 0) or (__argc < n):  # Command retrieval failed
            status = 1
        elif value.present() and len(value()) < len(a):
            status = -1
        else:
            status = 0

def get_command_argument(
    n: Int,
    value: Optional[String] = Optional[String](),
    length: Optional[Int] = Optional[Int](),
    status: Optional[Int] = Optional[Int]()
):
    var a: String = String()
    if (0 <= n) and (n <= __argc):  # Get the argument
        try:
            if __argv[n] != Pointer[UInt8]():
                a = String(__argv[n])
        except:
            pass  # Keep going
    if value.present():
        value = a
    if length.present():
        length = len(a)
    if status.present():
        if (n < 0) or (__argc < n):  # Command retrieval failed
            status = 1
        else:
            status = 0

def GETARG(
    n: Int,
    buffer: Pointer[String],
    status: Optional[Int] = Optional[Int]()
):
    var a: String = String()
    if (0 <= n) and (n <= __argc):  # Get the argument
        try:
            if __argv[n] != Pointer[UInt8]():
                a = String(__argv[n])
        except:
            pass  # Keep going
    buffer[0] = a
    if status.present():
        if (n < 0) or (__argc < n):  # Command retrieval failed
            status = -1
        else:
            status = Int(len(a))

def getarg(
    n: Int,
    buffer: Pointer[String],
    status: Optional[Int] = Optional[Int]()
):
    var a: String = String()
    if (0 <= n) and (n <= __argc):  # Get the argument
        try:
            if __argv[n] != Pointer[UInt8]():
                a = String(__argv[n])
        except:
            pass  # Keep going
    buffer[0] = a
    if status.present():
        if (n < 0) or (__argc < n):  # Command retrieval failed
            status = -1
        else:
            status = Int(len(a))