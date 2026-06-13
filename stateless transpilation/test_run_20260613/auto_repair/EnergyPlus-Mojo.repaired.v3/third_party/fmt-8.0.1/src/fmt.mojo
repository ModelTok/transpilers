// Original C++ file: fmt.cc  (faithful 1:1 translation to Mojo)
module fmt:

// #ifndef __cpp_modules
// #  error Module not supported.
// #endif
// #if !defined(_CRT_SECURE_NO_WARNINGS) && defined(_MSC_VER)
// #  define _CRT_SECURE_NO_WARNINGS
// #endif
// #if !defined(WIN32_LEAN_AND_MEAN) && defined(_WIN32)
// #  define WIN32_LEAN_AND_MEAN
// #endif

// Standard library includes - translated to Mojo imports
from python.sys import *  // approximates <cstddef>, <cstdint>, etc.
from python.cstdlib import *  // for malloc, free, etc.
from python.cstdio import *  // for printf, FILE, etc.
from python.cstring import *  // for memcpy, strlen, etc.
from python.ctime import *  // for time, clock
from python.cerrno import *  // for errno
from python.cwchar import *  // for wchar_t functions
from python.cmath import *  // for math functions
from python.clocale import *  // for locale functions
from python.climits import *  // for integer limits
from python.cctype import *  // for isdigit, etc.
from python.exception import *  // for exception
from python.functional import *  // for function, etc.
from python.iterator import *  // for iterator traits
from python.limits import *  // for numeric_limits
from python.locale import *  // for locale
from python.memory import *  // for unique_ptr, etc.
from python.ostream import *  // for ostream
from python.sstream import *  // for stringstream
from python.stdexcept import *  // for runtime_error, etc.
from python.string import *  // for string
from python.string_view import *  // for string_view
from python.system_error import *  // for system_error
from python.type_traits import *  // for is_same, etc.
from python.utility import *  // for pair, move
from python.vector import *  // for vector
from python.algorithm import *  // for min, max, etc.
from python.chrono import *  // for chrono
from python.cstdarg import *  // for va_list

// Compiler-specific includes (conditionally imported)
@parameter
if _MSC_VER:
    from python.intrin import *  // for __cpuid, etc.

@parameter
if __APPLE__ or __FreeBSD__:
    from python.xlocale import *  // for locale_t

@parameter
if __has_include(<winapifamily.h>):
    from python.winapifamily import *

@parameter
if ((__has_include(<fcntl.h>) or __APPLE__ or __linux__) and (
    not WINAPI_FAMILY or WINAPI_FAMILY == WINAPI_FAMILY_DESKTOP_APP)):
    from python.fcntl import *
    from python.sys_stat import *
    from python.sys_types import *
    @parameter
    if not _WIN32:
        from python.unistd import *
    else:
        from python.io import *

@parameter
if _WIN32:
    from python.windows import *

// Module export macros - replaced with Mojo public keyword
alias FMT_MODULE_EXPORT = public
// FMT_MODULE_EXPORT_BEGIN: use public { ... } wrapper
// FMT_MODULE_EXPORT_END: close block

// FMT_BEGIN_DETAIL_NAMESPACE and FMT_END_DETAIL_NAMESPACE are no-ops in Mojo

// Include fmt library headers (assuming they are translated to .mojo files)
from fmt.args import *
from fmt.chrono import *
from fmt.color import *
from fmt.compile import *
from format import *
from os import *
from fmt.printf import *
from fmt.xchar import *

// Private module fragment (skipped if FMT_GCC_VERSION is set)
@parameter
if not FMT_GCC_VERSION:
    // module : private; - not applicable in Mojo, keep as comment

// Include implementation files
include "format.mojo"
include "os.mojo"

// End of module