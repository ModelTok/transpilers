from testing import test, expect_eq
from ...ssc.vartab import var_table, var_data, ssc_data_t, json_to_ssc_data, ssc_data_free, ssc_data_to_json

@test
def json_to_ssc_data():
    var json_string = String('{"num": 5}')
    var dat = json_to_ssc_data(json_string)
    var vt = dat as var_table
    expect_eq(vt.lookup("num").num[0], 5)
    ssc_data_free(dat)
    json_string = String('{"str": "string"}')
    dat = json_to_ssc_data(json_string)
    vt = dat as var_table
    expect_eq(vt.lookup("str").str.lower(), "string")
    ssc_data_free(dat)
    json_string = String('{"arr": [1, 2]}')
    dat = json_to_ssc_data(json_string)
    vt = dat as var_table
    expect_eq(vt.lookup("arr").num[0], 1)
    expect_eq(vt.lookup("arr").num[1], 2)
    ssc_data_free(dat)
    json_string = String('{"mat": [[1, 2], [3, 4]]}')
    dat = json_to_ssc_data(json_string)
    vt = dat as var_table
    expect_eq(vt.lookup("mat").num[0], 1)
    expect_eq(vt.lookup("mat").num[1], 2)
    expect_eq(vt.lookup("mat").num[2], 3)
    expect_eq(vt.lookup("mat").num[3], 4)
    ssc_data_free(dat)
    json_string = String('{"datarr": ["one", 2]}')
    dat = json_to_ssc_data(json_string)
    vt = dat as var_table
    expect_eq(vt.lookup("datarr").vec[0].str.lower(), "one")
    expect_eq(vt.lookup("datarr").vec[1].num[0], 2)
    ssc_data_free(dat)
    json_string = String('{"datmat": [["one", 2], [3, {"four": 4}]]}')
    dat = json_to_ssc_data(json_string)
    vt = dat as var_table
    expect_eq(vt.lookup("datmat").vec[0].vec[0].str.lower(), "one")
    expect_eq(vt.lookup("datmat").vec[0].vec[1].num[0], 2)
    expect_eq(vt.lookup("datmat").vec[1].vec[0].num[0], 3)
    expect_eq(vt.lookup("datmat").vec[1].vec[1].table.lookup("four").num[0], 4)
    ssc_data_free(dat)
    json_string = String('{"table": {"entry": 1}}')
    dat = json_to_ssc_data(json_string)
    vt = dat as var_table
    expect_eq(vt.lookup("table").table.lookup("entry").num[0], 1)
    ssc_data_free(dat)
    json_string = String('{"wrong": format}')
    dat = json_to_ssc_data(json_string)
    vt = dat as var_table
    expect_gt(vt.lookup("error").str.size(), 0)

@test
def ssc_data_to_json():
    var vt = var_table()
    vt.assign("num", 1)
    var json_string = ssc_data_to_json(&vt)
    expect_eq(json_string.lower(), '{"num":1.0}')
    vt.clear()
    del json_string
    vt.assign("str", var_data("string"))
    json_string = ssc_data_to_json(&vt)
    expect_eq(json_string.lower(), '{"str":"string"}')
    vt.clear()
    del json_string
    vt.assign("arr", List[Float64]([1, 2]))
    json_string = ssc_data_to_json(&vt)
    expect_eq(json_string.lower(), '{"arr":[1.0,2.0]}')
    vt.clear()
    del json_string
    var vals = List[Float64]([1, 2, 3, 4])
    vt.assign("mat", var_data(vals, 2, 2))
    json_string = ssc_data_to_json(&vt)
    expect_eq(json_string.lower(), '{"mat":[[1.0,2.0],[3.0,4.0]]}')
    vt.clear()
    del json_string
    var vars = List[var_data]([var_data("one"), 2])
    vt.assign("datarr", vars)
    json_string = ssc_data_to_json(&vt)
    expect_eq(json_string.lower(), '{"datarr":["one",2.0]}')
    vt.clear()
    del json_string
    var vars_mat = List[List[var_data]]([vars, List[var_data]([3, 4])])
    vt.assign("datmat", vars_mat)
    json_string = ssc_data_to_json(&vt)
    expect_eq(json_string.lower(), '{"datmat":[["one",2.0],[3.0,4.0]]}')
    vt.clear()
    var tab = var_table()
    tab.assign("entry", 1)
    vt.assign("table", tab)
    json_string = ssc_data_to_json(&vt)
    expect_eq(json_string.lower(), '{"table":{"entry":1.0}}')
    vt.clear()
    del json_string