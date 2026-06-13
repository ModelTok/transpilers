from sscapi import ssc_data_t
from common_financial import Const_per_principal, Const_per_interest, Const_per_total
from vartab import var_table, vt_get_number

def Financial_Construction_Financing_Equations(data: ssc_data_t) raises:
    var vt = data as var_table
    if not vt:
        raise Error("ssc_data_t data invalid")
    var total_installed_cost: Float64
    var const_per_percent1: Float64
    var const_per_principal1: Float64
    var const_per_interest1: Float64
    var const_per_interest_rate1: Float64
    var const_per_months1: Float64
    var const_per_upfront_rate1: Float64
    var const_per_total1: Float64
    var const_per_percent2: Float64
    var const_per_principal2: Float64
    var const_per_interest2: Float64
    var const_per_interest_rate2: Float64
    var const_per_months2: Float64
    var const_per_upfront_rate2: Float64
    var const_per_total2: Float64
    var const_per_percent3: Float64
    var const_per_principal3: Float64
    var const_per_interest3: Float64
    var const_per_interest_rate3: Float64
    var const_per_months3: Float64
    var const_per_upfront_rate3: Float64
    var const_per_total3: Float64
    var const_per_percent4: Float64
    var const_per_principal4: Float64
    var const_per_interest4: Float64
    var const_per_interest_rate4: Float64
    var const_per_months4: Float64
    var const_per_upfront_rate4: Float64
    var const_per_total4: Float64
    var const_per_percent5: Float64
    var const_per_principal5: Float64
    var const_per_interest5: Float64
    var const_per_interest_rate5: Float64
    var const_per_months5: Float64
    var const_per_upfront_rate5: Float64
    var const_per_total5: Float64
    var const_per_principal_total: Float64
    var const_per_percent_total: Float64
    var construction_financing_cost: Float64
    var const_per_interest_total: Float64
    vt_get_number(vt, "total_installed_cost", total_installed_cost)
    vt_get_number(vt, "const_per_interest_rate1", const_per_interest_rate1)
    vt_get_number(vt, "const_per_months1", const_per_months1)
    vt_get_number(vt, "const_per_percent1", const_per_percent1)
    vt_get_number(vt, "const_per_upfront_rate1", const_per_upfront_rate1)
    const_per_principal1 = Const_per_principal(const_per_percent1, total_installed_cost)
    const_per_interest1 = Const_per_interest(const_per_principal1, const_per_interest_rate1, const_per_months1)
    const_per_total1 = Const_per_total(const_per_interest1, const_per_principal1, const_per_upfront_rate1)
    vt.assign("const_per_principal1", const_per_principal1)
    vt.assign("const_per_interest1", const_per_interest1)
    vt.assign("const_per_total1", const_per_total1)
    vt_get_number(vt, "const_per_interest_rate2", const_per_interest_rate2)
    vt_get_number(vt, "const_per_months2", const_per_months2)
    vt_get_number(vt, "const_per_percent2", const_per_percent2)
    vt_get_number(vt, "const_per_upfront_rate2", const_per_upfront_rate2)
    const_per_principal2 = Const_per_principal(const_per_percent2, total_installed_cost)
    const_per_interest2 = Const_per_interest(const_per_principal2, const_per_interest_rate2, const_per_months2)
    const_per_total2 = Const_per_total(const_per_interest2, const_per_principal2, const_per_upfront_rate2)
    vt.assign("const_per_principal2", const_per_principal2)
    vt.assign("const_per_interest2", const_per_interest2)
    vt.assign("const_per_total2", const_per_total2)
    vt_get_number(vt, "const_per_interest_rate3", const_per_interest_rate3)
    vt_get_number(vt, "const_per_months3", const_per_months3)
    vt_get_number(vt, "const_per_percent3", const_per_percent3)
    vt_get_number(vt, "const_per_upfront_rate3", const_per_upfront_rate3)
    const_per_principal3 = Const_per_principal(const_per_percent3, total_installed_cost)
    const_per_interest3 = Const_per_interest(const_per_principal3, const_per_interest_rate3, const_per_months3)
    const_per_total3 = Const_per_total(const_per_interest3, const_per_principal3, const_per_upfront_rate3)
    vt.assign("const_per_principal3", const_per_principal3)
    vt.assign("const_per_interest3", const_per_interest3)
    vt.assign("const_per_total3", const_per_total3)
    vt_get_number(vt, "const_per_interest_rate4", const_per_interest_rate4)
    vt_get_number(vt, "const_per_months4", const_per_months4)
    vt_get_number(vt, "const_per_percent4", const_per_percent4)
    vt_get_number(vt, "const_per_upfront_rate4", const_per_upfront_rate4)
    const_per_principal4 = Const_per_principal(const_per_percent4, total_installed_cost)
    const_per_interest4 = Const_per_interest(const_per_principal4, const_per_interest_rate4, const_per_months4)
    const_per_total4 = Const_per_total(const_per_interest4, const_per_principal4, const_per_upfront_rate4)
    vt.assign("const_per_principal4", const_per_principal4)
    vt.assign("const_per_interest4", const_per_interest4)
    vt.assign("const_per_total4", const_per_total4)
    vt_get_number(vt, "const_per_interest_rate5", const_per_interest_rate5)
    vt_get_number(vt, "const_per_months5", const_per_months5)
    vt_get_number(vt, "const_per_percent5", const_per_percent5)
    vt_get_number(vt, "const_per_upfront_rate5", const_per_upfront_rate5)
    const_per_principal5 = Const_per_principal(const_per_percent5, total_installed_cost)
    const_per_interest5 = Const_per_interest(const_per_principal5, const_per_interest_rate5, const_per_months5)
    const_per_total5 = Const_per_total(const_per_interest5, const_per_principal5, const_per_upfront_rate5)
    vt.assign("const_per_principal5", const_per_principal5)
    vt.assign("const_per_interest5", const_per_interest5)
    vt.assign("const_per_total5", const_per_total5)
    const_per_principal_total = const_per_principal1 + const_per_principal2 + const_per_principal3 + const_per_principal4 + const_per_principal5
    const_per_percent_total = const_per_percent1 + const_per_percent2 + const_per_percent3 + const_per_percent4 + const_per_percent5
    construction_financing_cost = const_per_total1 + const_per_total2 + const_per_total3 + const_per_total4 + const_per_total5
    const_per_interest_total = const_per_interest1 + const_per_interest2 + const_per_interest3 + const_per_interest4 + const_per_interest5
    vt.assign("const_per_principal_total", const_per_principal_total)
    vt.assign("const_per_percent_total", const_per_percent_total)
    vt.assign("construction_financing_cost", construction_financing_cost)
    vt.assign("const_per_interest_total", const_per_interest_total)

def Financial_Capacity_Payments_Equations(data: ssc_data_t) raises:
    var vt = data as var_table
    if not vt:
        raise Error("ssc_data_t data invalid")
    var system_capacity: Float64
    var cp_system_nameplate: Float64
    vt_get_number(vt, "system_capacity", system_capacity)
    cp_system_nameplate = system_capacity / 1000.0
    vt.assign("cp_system_nameplate", cp_system_nameplate)