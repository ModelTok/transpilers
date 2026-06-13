from os import getenv, setenv
from string.functions import rstrip
from builtin import Optional

def GET_ENVIRONMENT_VARIABLE(
    name: String,
    value: Optional[String] = None,
    length: Optional[Int] = None,
    status: Optional[Int] = None,
    trim_name: Optional[Bool] = None
):
    var cval: Optional[String] = getenv(name)
    var val: String = cval.value() if cval.is_some() else ""
    if (not trim_name.is_some()) or (trim_name.value()):
        rstrip(val)  # Strip any trailing spaces
    if value.is_some():
        value = val
    if length.is_some():
        length = Int(val.length())
    if status.is_some():
        if not cval.is_some():  # Env var does not exist
            status = 1
        else:  # Env var exists
            if value.is_some():
                status = 0 if value.value().length() >= val.length() else -1
            else:
                status = 0

def get_environment_variable(
    name: String,
    value: Optional[String] = None,
    length: Optional[Int] = None,
    status: Optional[Int] = None,
    trim_name: Optional[Bool] = None
):
    var cval: Optional[String] = getenv(name)
    var val: String = cval.value() if cval.is_some() else ""
    if (not trim_name.is_some()) or (trim_name.value()):
        rstrip(val)  # Strip any trailing spaces
    if value.is_some():
        value = val
    if length.is_some():
        length = Int(val.length())
    if status.is_some():
        if not cval.is_some():  # Env var does not exist
            status = 1
        else:  # Env var exists
            if value.is_some():
                status = 0 if value.value().length() >= val.length() else -1
            else:
                status = 0

def GETENV(name: String, value: String):
    var cval: Optional[String] = getenv(name)
    value = cval.value() if cval.is_some() else ""

def GETENVQQ(name: String, value: String) -> Int:
    var cval: Optional[String] = getenv(name)
    value = cval.value() if cval.is_some() else ""
    return value.length()

def GET_ENV_VAR(name: String) -> String:
    var cval: Optional[String] = getenv(name)
    return String(cval.value() if cval.is_some() else "")

def SETENV(name: String, value: String) -> Bool:
    #ifdef OBJEXXFCL_NO_PUTENV
    #    return False
    #elif defined(_MSC_VER) && !defined(__INTEL_COMPILER)
    #    return ( _putenv_s( name.c_str(), value.c_str() ) == 0 )
    #elif defined(__GNUC__) && !defined(_WIN32)
    #    return ( setenv( name.c_str(), value.c_str(), 1 ) == 0 )
    #else
    #    string const name_eq_value( name + '=' + value );
    #    return ( putenv( name_eq_value.c_str() ) == 0 ); // Not standard but widely supported
    #endif
    # Using os.setenv for Linux (GCC) path
    return setenv(name, value, overwrite=True) == 0

def split_name_eq_value(name_eq_value: String, name: String, value: String):
    name = ""
    value = ""
    if name_eq_value.empty():
        return
    var l: Int = name_eq_value.length()
    var i: Int = 0
    while (i < l) and (name_eq_value[i] != '='):
        name += name_eq_value[i]
        i += 1
    if (i < l) and (name_eq_value[i] == '='):
        i += 1
    while i < l:
        value += name_eq_value[i]
        i += 1

def SETENVQQ(name_eq_value: String) -> Bool:
    #ifdef OBJEXXFCL_NO_PUTENV
    #    return False
    #elif defined(_MSC_VER) && !defined(__INTEL_COMPILER)
    #    return ( _putenv( name_eq_value.c_str() ) == 0 );
    #elif defined(__GNUC__) && !defined(_WIN32)
    #    string name, value;
    #    split_name_eq_value( name_eq_value, name, value );
    #    return ( setenv( name.c_str(), value.c_str(), 1 ) == 0 );
    #else
    #    return ( putenv( name_eq_value.c_str() ) == 0 ); // Not standard but widely supported
    #endif
    # Using os.setenv for Linux (GCC) path
    var name: String
    var value: String
    split_name_eq_value(name_eq_value, name, value)
    return setenv(name, value, overwrite=True) == 0