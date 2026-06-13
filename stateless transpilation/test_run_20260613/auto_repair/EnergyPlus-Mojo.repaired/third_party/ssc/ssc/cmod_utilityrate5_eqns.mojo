from sscapi import *
from vartab import *
from cmod_utilityrate5_eqns.h import *

def try_get_rate_schedule(vt: var_table, ssc_name: String, schedule_matrix: matrix_t[Float64]) -> Bool:
    schedule_matrix.clear()
    var vd = vt.lookup(ssc_name)
    if not vd:
        return False
    var mat = vd.num
    schedule_matrix.copy(mat)
    for i in range(mat.nrows()):
        for j in range(mat.ncols()):
            schedule_matrix.at(i, j) -= 1
    return True

def try_get_rate_structure(vt: var_table, ssc_name: String, power_units: Bool,
                            rate_structure: List[List[var_data]]) -> Bool:
    rate_structure.clear()
    var vd = vt.lookup(ssc_name)
    if not vd:
        return False
    var rate_matrix: List[List[Float64]] = vd.matrix_vector()
    var n_periods: Int = Int(max(rate_matrix, key=lambda row: row[0])[0])
    rate_structure.resize(n_periods)
    rate_matrix.sort(key=lambda row: row[1])
    rate_matrix.sort(key=lambda row: row[0])
    if power_units:
        vt.assign("demandrateunit", var_data("kW"))
    for row in rate_matrix:
        var period: Int = Int(row[0])
        var max_val: Float64 = row[2]
        var buy: Float64
        var rate_data: var_data
        rate_data.type = SSC_TABLE
        if not power_units:
            var unit_type: Int = Int(row[3])
            buy = row[4]
            var sell: Float64 = row[5]
            if unit_type == 0 or (unit_type == -1 and max_val > 1e36):
                rate_data.table.assign("unit", var_data("kWh"))
            elif unit_type == 2:
                rate_data.table.assign("unit", var_data("kWh daily"))
            else:
                raise Error("ElectricityRates_format_as_URDBv7 error. Unit type in " + ssc_name + " not allowed.")
            rate_data.table.assign("sell", sell)
        else:
            buy = row[3]
        rate_data.table.assign("max", max_val)
        rate_data.table.assign("rate", buy)
        rate_structure[period - 1].append(rate_data)
    return True

@export
def ElectricityRates_format_as_URDBv7(data: ssc_data_t):
    var vt = data as var_table
    if not vt:
        raise Error("ssc_data_t data invalid")
    var urdb_data = var_table()
    var log: String
    var net_metering: Int
    vt_get_int(vt, "ur_metering_option", net_metering)
    var dgrules: String
    if net_metering == 0:
        dgrules = "Net Metering"
    elif net_metering == 1 or net_metering == 3:
        raise Error("ElectricityRates_format_as_URDBv7 error. ur_net_metering_option not available in URDBv7.")
    elif net_metering == 2:
        dgrules = "Net Billing Hourly"
    elif net_metering == 4:
        dgrules = "Buy All Sell All"
    else:
        raise Error("ElectricityRates_format_as_URDBv7 error. ur_net_metering_option not recognized.")
    urdb_data.assign("dgrules", dgrules)
    var monthly_fixed: Float64
    var monthly_min: Float64
    vt_get_number(vt, "ur_monthly_fixed_charge", monthly_fixed)
    urdb_data.assign("fixedmonthlycharge", monthly_fixed)
    vt_get_number(vt, "ur_monthly_min_charge", monthly_min)
    urdb_data.assign("minmonthlycharge", monthly_min)
    try:
        var annual_min: Float64
        vt_get_number(vt, "ur_annual_min_charge", annual_min)
        urdb_data.assign("annualmincharge", annual_min)
    except:

    var sched_matrix: matrix_t[Float64]
    if try_get_rate_schedule(vt, "ur_ec_sched_weekday", sched_matrix):
        urdb_data.assign("energyweekdayschedule", sched_matrix)
    if try_get_rate_schedule(vt, "ur_ec_sched_weekend", sched_matrix):
        urdb_data.assign("energyweekendschedule", sched_matrix)
    var rate_structure: List[List[var_data]]
    if try_get_rate_structure(vt, "ur_ec_tou_mat", False, rate_structure):
        urdb_data.assign("energyratestructure", rate_structure)
    sched_matrix.clear()
    if vt.is_assigned("ur_dc_flat_mat"):
        sched_matrix = vt.lookup("ur_dc_flat_mat").num
        var n_rows: Int = sched_matrix.nrows()
        var flatdemand: List[List[Float64]]
        for i in range(n_rows):
            var row: List[Float64]
            row.append(sched_matrix.at(i, 0))
            row.append(sched_matrix.at(i, 1))
            row.append(sched_matrix.at(i, 2))
            row.append(sched_matrix.at(i, 3))
            flatdemand.append(row)
        var flat_demand_structure: List[List[var_data]]
        var flat_demand_months: List[Float64]
        flat_demand_months.resize(12)
        for i in range(n_rows):
            var tier: Float64 = sched_matrix.at(i, 1)
            if tier != 1:
                continue
            var month: Float64 = sched_matrix.at(i, 0)
            var max_val: Float64 = sched_matrix.at(i, 2)
            var charge: Float64 = sched_matrix.at(i, 3)
            var row: List[var_data]
            var period: Int = -1
            for j in range(flat_demand_structure.size()):
                var j_max: Float64 = flat_demand_structure[j][0].table.lookup("max").num[0]
                var j_charge: Float64 = flat_demand_structure[j][0].table.lookup("rate").num[0]
                if abs(max_val - j_max) < 1e-3 and abs(charge - j_charge) < 1e-3:
                    period = j
                    break
            if period == -1:
                var rate_data: var_data
                rate_data.type = SSC_TABLE
                rate_data.table.assign("max", max_val)
                rate_data.table.assign("rate", charge)
                row.append(rate_data)
                flat_demand_structure.append(row)
                period = flat_demand_structure.size() - 1
            flat_demand_months[Int(month)] = Float64(period)
        for i in range(n_rows):
            var tier: Float64 = sched_matrix.at(i, 1)
            if tier == 1:
                continue
            var month: Float64 = sched_matrix.at(i, 0)
            var max_val: Float64 = sched_matrix.at(i, 2)
            var charge: Float64 = sched_matrix.at(i, 3)
            var period: Float64 = flat_demand_months[Int(month)]
            var rate_data: var_data
            rate_data.type = SSC_TABLE
            rate_data.table.assign("max", max_val)
            rate_data.table.assign("rate", charge)
            flat_demand_structure[Int(period)].append(rate_data)
        urdb_data.assign("flatdemandstructure", flat_demand_structure)
        urdb_data.assign("flatdemandmonths", flat_demand_months)
    if try_get_rate_schedule(vt, "ur_dc_sched_weekday", sched_matrix):
        urdb_data.assign("demandweekdayschedule", sched_matrix)
    if try_get_rate_schedule(vt, "ur_dc_sched_weekend", sched_matrix):
        urdb_data.assign("demandweekendschedule", sched_matrix)
    if try_get_rate_structure(vt, "ur_dc_tou_mat", True, rate_structure):
        urdb_data.assign("demandratestructure", rate_structure)
    vt.assign("urdb_data", urdb_data)