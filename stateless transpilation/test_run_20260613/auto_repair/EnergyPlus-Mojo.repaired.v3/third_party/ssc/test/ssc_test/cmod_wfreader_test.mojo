from vartab import *
from testing import *

@testing.fixture
def Wfreader_cmod_wfreader_Test():
    var filepath: StaticString[1024]
    var n1: Int = sprintf(filepath, "%s/test/input_docs/weather_30m.epw", std.getenv("SSCDIR"))
    var mod = ssc_module_create("wfreader")
    var data = ssc_data_create()
    ssc_data_set_string(data, "file_name", filepath)
    ssc_data_set_number(data, "header_only", 1)
    assert_true(ssc_module_exec(mod, data))