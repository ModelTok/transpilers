from vartab import var_table, var_data, vt_get_int, vt_get_number, vt_get_matrix
from ...shared.lib_util import util
from ...shared.lib_time import extrapolate_timeseries
from sscapi import ssc_data_t
from math import pow

def mp_ancillary_services(data: ssc_data_t):
    var error: String = ""
    var ancillary_services_success: Bool = False
    var calculate_revenue: Bool = False
    var vt = data as var_table
    try:
        if not vt:
            raise Error("ssc_data_t data invalid")
    except e:
        error = String(e)

    try:
        var gen_is_assigned: Bool = False
        var mp_enable_energy_market_revenue: Int
        var mp_enable_ancserv1: Int
        var mp_enable_ancserv2: Int
        var mp_enable_ancserv3: Int
        var mp_enable_ancserv4: Int
        var system_use_lifetime_output: Int
        var mp_calculate_revenue: Int
        var analysis_period: Float64
        var system_capacity: Float64
        var mp_energy_market_revenue: Matrix[Float64]
        var mp_ancserv1_revenue: Matrix[Float64]
        var mp_ancserv2_revenue: Matrix[Float64]
        var mp_ancserv3_revenue: Matrix[Float64]
        var mp_ancserv4_revenue: Matrix[Float64]
        var system_gen: Matrix[Float64]
        var degradation: Matrix[Float64]
        /*
        { SSC_INPUT,        SSC_NUMBER,     "mp_enable_energy_market_revenue",		      "Enable energy market revenue",   "0/1",   "",    "",  "*",	"INTEGER,MIN=0,MAX=1",      "" },
        { SSC_INPUT, SSC_MATRIX, "mp_energy_market_revenue", "Energy market revenue input", "", "","*", "", ""},
        { SSC_INPUT,        SSC_NUMBER,     "mp_enable_ancserv1",		      "Enable ancillary services 1 revenue",   "0/1",   "",    "",  "*",	"INTEGER,MIN=0,MAX=1",      "" },
        { SSC_INPUT, SSC_MATRIX, "mp_ancserv1_revenue", "Ancillary services 1 revenue input", "", "","*", "", "" },
        { SSC_INPUT,        SSC_NUMBER,     "mp_enable_ancserv2",		      "Enable ancillary services 2 revenue",   "0/1",   "",    "",  "*",	"INTEGER,MIN=0,MAX=1",      "" },
        { SSC_INPUT, SSC_MATRIX, "mp_ancserv2_revenue", "Ancillary services 2 revenue input", "", "","*", "", "" },
        { SSC_INPUT,        SSC_NUMBER,     "mp_enable_ancserv3",		      "Enable ancillary services 3 revenue",   "0/1",   "",    "",  "*",	"INTEGER,MIN=0,MAX=1",      "" },
        { SSC_INPUT, SSC_MATRIX, "mp_ancserv3_revenue", "Ancillary services 3 revenue input", "", "","*", "", "" },
        { SSC_INPUT,        SSC_NUMBER,     "mp_enable_ancserv4",		      "Enable ancillary services 4 revenue",   "0/1",   "",    "",  "*",	"INTEGER,MIN=0,MAX=1",      "" },
        { SSC_INPUT, SSC_MATRIX, "mp_ancserv4_revenue", "Ancillary services 4 revenue input", "", "","*", "", "" },
        */
        vt_get_int(vt, "system_use_lifetime_output", &system_use_lifetime_output)
        vt_get_number(vt, "analysis_period", &analysis_period)
        vt_get_int(vt, "mp_enable_energy_market_revenue", &mp_enable_energy_market_revenue)
        vt_get_int(vt, "mp_enable_ancserv1", &mp_enable_ancserv1)
        vt_get_int(vt, "mp_enable_ancserv2", &mp_enable_ancserv2)
        vt_get_int(vt, "mp_enable_ancserv3", &mp_enable_ancserv3)
        vt_get_int(vt, "mp_enable_ancserv4", &mp_enable_ancserv4)
        vt_get_matrix(vt, "mp_energy_market_revenue", mp_energy_market_revenue)
        vt_get_matrix(vt, "mp_ancserv1_revenue", mp_ancserv1_revenue)
        vt_get_matrix(vt, "mp_ancserv2_revenue", mp_ancserv2_revenue)
        vt_get_matrix(vt, "mp_ancserv3_revenue", mp_ancserv3_revenue)
        vt_get_matrix(vt, "mp_ancserv4_revenue", mp_ancserv4_revenue)
        gen_is_assigned = (vt.lookup("gen") != None)
        if gen_is_assigned:
            system_capacity = 0.0
            vt_get_matrix(vt, "gen", system_gen)
            vt_get_matrix(vt, "degradation", degradation)
        else:
            vt_get_number(vt, "system_capacity", &system_capacity)
        calculate_revenue = (vt.lookup("mp_calculate_revenue") != None)
        if calculate_revenue:
            vt_get_int(vt, "mp_calculate_revenue", &mp_calculate_revenue)
            calculate_revenue = bool(mp_calculate_revenue)
        system_capacity /= 1000.0
        var en_mp_energy_market: Bool = (mp_enable_energy_market_revenue > 0.5)
        var en_mp_ancserv1: Bool = (mp_enable_ancserv1 > 0.5)
        var en_mp_ancserv2: Bool = (mp_enable_ancserv2 > 0.5)
        var en_mp_ancserv3: Bool = (mp_enable_ancserv3 > 0.5)
        var en_mp_ancserv4: Bool = (mp_enable_ancserv4 > 0.5)
        ancillary_services_success = (not mp_enable_energy_market_revenue and not mp_enable_ancserv1 and not mp_enable_ancserv2 and not mp_enable_ancserv3 and not mp_enable_ancserv4)
        var nsteps: Int = 0
        var nsteps_per_year: Int = 8760
        if en_mp_energy_market:
            nsteps = max(nsteps, mp_energy_market_revenue.nrows())
        if en_mp_ancserv1:
            nsteps = max(nsteps, mp_ancserv1_revenue.nrows())
        if en_mp_ancserv2:
            nsteps = max(nsteps, mp_ancserv2_revenue.nrows())
        if en_mp_ancserv3:
            nsteps = max(nsteps, mp_ancserv3_revenue.nrows())
        if en_mp_ancserv4:
            nsteps = max(nsteps, mp_ancserv4_revenue.nrows())
        if nsteps < (8760 * Int(analysis_period)):
            nsteps = 8760 * Int(analysis_period) # extrapolated timeseries has minimum of hourly values for use in all forecasting 
        var energy_market_revenue = List[Float64](nsteps, 0.0)
        var ancillary_services1_revenue = List[Float64](nsteps, 0.0)
        var ancillary_services2_revenue = List[Float64](nsteps, 0.0)
        var ancillary_services3_revenue = List[Float64](nsteps, 0.0)
        var ancillary_services4_revenue = List[Float64](nsteps, 0.0)
        if not ancillary_services_success:
            if analysis_period > 0:
                if en_mp_energy_market:
                    nsteps = max(nsteps, mp_energy_market_revenue.nrows())
                if en_mp_ancserv1:
                    nsteps = max(nsteps, mp_ancserv1_revenue.nrows())
                if en_mp_ancserv2:
                    nsteps = max(nsteps, mp_ancserv2_revenue.nrows())
                if en_mp_ancserv3:
                    nsteps = max(nsteps, mp_ancserv3_revenue.nrows())
                if en_mp_ancserv4:
                    nsteps = max(nsteps, mp_ancserv4_revenue.nrows())
                if nsteps > 0:
                    if nsteps < (8760 * Int(analysis_period)):
                        nsteps = 8760 * Int(analysis_period) # extrapolated timeseries has minimum of hourly values for use in all forecasting 
                    var cleared_capacity_sum = List[Float64](nsteps, 0.0)
                    var system_generation = List[Float64](nsteps, 0.0)
                    var energy_market_capacity = List[Float64](nsteps, 0.0)
                    var ancillary_services1_capacity = List[Float64](nsteps, 0.0)
                    var ancillary_services2_capacity = List[Float64](nsteps, 0.0)
                    var ancillary_services3_capacity = List[Float64](nsteps, 0.0)
                    var ancillary_services4_capacity = List[Float64](nsteps, 0.0)
                    var current_year_capacity = List[Float64]()
                    var extrapolated_current_year_capacity = List[Float64]()
                    var current_year_revenue = List[Float64]()
                    var extrapolated_current_year_revenue = List[Float64]()
                    nsteps_per_year = nsteps / Int(analysis_period)
                    if nsteps_per_year < 8760:
                        nsteps_per_year = 8760 # for use of extrapolated_timeseries
                    var steps_per_hour: Int = nsteps_per_year / 8760
                    var current_num_per_year: Int
                    for iyear in range(Int(analysis_period)):
                        if gen_is_assigned:
                            current_year_capacity.clear()
                            if system_use_lifetime_output > 0.5: # lifetime "gen" = "system_gen"
                                current_num_per_year = system_gen.ncols() / Int(analysis_period)
                            else: # adjust single year for lifetime system_generation
                                current_num_per_year = system_gen.ncols()
                            current_year_capacity.reserve(current_num_per_year)
                            for ic in range(current_num_per_year):
                                if system_use_lifetime_output > 0.5: # lifetime "gen" = "system_gen"
                                    if (ic + iyear * current_num_per_year) < system_gen.ncols():
                                        current_year_capacity.append(system_gen[0, ic + iyear * current_num_per_year] / 1000.0) # kW to MW
                                else: # single year - adjust with degradation
                                    if system_use_lifetime_output < 1: # adjust single year for lifetime system_generation
                                        var degrade_factor: Float64
                                        if degradation.nrows() == 1:
                                            degrade_factor = pow((1.0 - degradation[0, 0] / 100.0), iyear)
                                        else:
                                            degrade_factor = (1.0 - degradation[0, ic] / 100.0)
                                        current_year_capacity.append((system_gen[0, ic] * degrade_factor) / 1000.0) # kW to MW
                            extrapolated_current_year_capacity = extrapolate_timeseries(current_year_capacity, steps_per_hour)
                            for ic in range(extrapolated_current_year_capacity.size):
                                if (ic + iyear * current_num_per_year) < cleared_capacity_sum.size:
                                    system_generation[ic + iyear * nsteps_per_year] = extrapolated_current_year_capacity[ic]
                        else:
                            for ic in range(nsteps_per_year):
                                system_generation[ic + iyear * nsteps_per_year] = system_capacity
                        if en_mp_energy_market:
                            current_year_capacity.clear()
                            current_num_per_year = mp_energy_market_revenue.nrows() / Int(analysis_period)
                            current_year_capacity.reserve(current_num_per_year)
                            for ic in range(current_num_per_year):
                                if (ic + iyear * current_num_per_year) < mp_energy_market_revenue.nrows():
                                    current_year_capacity.append(mp_energy_market_revenue[ic + iyear * current_num_per_year, 0])
                            extrapolated_current_year_capacity = extrapolate_timeseries(current_year_capacity, steps_per_hour)
                            for ic in range(extrapolated_current_year_capacity.size):
                                if (ic + iyear * current_num_per_year) < cleared_capacity_sum.size:
                                    energy_market_capacity[ic + iyear * nsteps_per_year] = extrapolated_current_year_capacity[ic]
                                    cleared_capacity_sum[ic + iyear * nsteps_per_year] += extrapolated_current_year_capacity[ic]
                            if calculate_revenue:
                                current_year_revenue.clear()
                                current_year_revenue.reserve(current_num_per_year)
                                for ic in range(current_num_per_year):
                                    if (ic + iyear * current_num_per_year) < mp_energy_market_revenue.nrows():
                                        current_year_revenue.append(mp_energy_market_revenue[ic + iyear * current_num_per_year, 1])
                                extrapolated_current_year_revenue = extrapolate_timeseries(current_year_revenue, steps_per_hour)
                                for ic in range(extrapolated_current_year_revenue.size):
                                    if (ic + iyear * current_num_per_year) < energy_market_revenue.size:
                                        energy_market_revenue[ic + iyear * nsteps_per_year] = extrapolated_current_year_revenue[ic] # $/MWh
                        if en_mp_ancserv1:
                            current_year_capacity.clear()
                            current_num_per_year = mp_ancserv1_revenue.nrows() / Int(analysis_period)
                            current_year_capacity.reserve(current_num_per_year)
                            for ic in range(current_num_per_year):
                                if (ic + iyear * current_num_per_year) < mp_ancserv1_revenue.nrows():
                                    current_year_capacity.append(mp_ancserv1_revenue[ic + iyear * current_num_per_year, 0])
                            extrapolated_current_year_capacity = extrapolate_timeseries(current_year_capacity, steps_per_hour)
                            for ic in range(extrapolated_current_year_capacity.size):
                                if (ic + iyear * current_num_per_year) < cleared_capacity_sum.size:
                                    ancillary_services1_capacity[ic + iyear * nsteps_per_year] = extrapolated_current_year_capacity[ic]
                                    cleared_capacity_sum[ic + iyear * nsteps_per_year] += extrapolated_current_year_capacity[ic]
                            if calculate_revenue:
                                current_year_revenue.clear()
                                current_year_revenue.reserve(current_num_per_year)
                                for ic in range(current_num_per_year):
                                    if (ic + iyear * current_num_per_year) < mp_ancserv1_revenue.nrows():
                                        current_year_revenue.append(mp_ancserv1_revenue[ic + iyear * current_num_per_year, 1])
                                extrapolated_current_year_revenue = extrapolate_timeseries(current_year_revenue, steps_per_hour)
                                for ic in range(extrapolated_current_year_revenue.size):
                                    if (ic + iyear * current_num_per_year) < ancillary_services1_revenue.size:
                                        ancillary_services1_revenue[ic + iyear * nsteps_per_year] = extrapolated_current_year_revenue[ic] # $/MWh
                        if en_mp_ancserv2:
                            current_year_capacity.clear()
                            current_num_per_year = mp_ancserv2_revenue.nrows() / Int(analysis_period)
                            current_year_capacity.reserve(current_num_per_year)
                            for ic in range(current_num_per_year):
                                if (ic + iyear * current_num_per_year) < mp_ancserv2_revenue.nrows():
                                    current_year_capacity.append(mp_ancserv2_revenue[ic + iyear * current_num_per_year, 0])
                            extrapolated_current_year_capacity = extrapolate_timeseries(current_year_capacity, steps_per_hour)
                            for ic in range(extrapolated_current_year_capacity.size):
                                if (ic + iyear * current_num_per_year) < cleared_capacity_sum.size:
                                    ancillary_services2_capacity[ic + iyear * nsteps_per_year] = extrapolated_current_year_capacity[ic]
                                    cleared_capacity_sum[ic + iyear * nsteps_per_year] += extrapolated_current_year_capacity[ic]
                            if calculate_revenue:
                                current_year_revenue.clear()
                                current_year_revenue.reserve(current_num_per_year)
                                for ic in range(current_num_per_year):
                                    if (ic + iyear * current_num_per_year) < mp_ancserv2_revenue.nrows():
                                        current_year_revenue.append(mp_ancserv2_revenue[ic + iyear * current_num_per_year, 1])
                                extrapolated_current_year_revenue = extrapolate_timeseries(current_year_revenue, steps_per_hour)
                                for ic in range(extrapolated_current_year_revenue.size):
                                    if (ic + iyear * current_num_per_year) < ancillary_services2_revenue.size:
                                        ancillary_services2_revenue[ic + iyear * nsteps_per_year] = extrapolated_current_year_revenue[ic] # $/MWh
                        if en_mp_ancserv3:
                            current_year_capacity.clear()
                            current_num_per_year = mp_ancserv3_revenue.nrows() / Int(analysis_period)
                            current_year_capacity.reserve(current_num_per_year)
                            for ic in range(current_num_per_year):
                                if (ic + iyear * current_num_per_year) < mp_ancserv3_revenue.nrows():
                                    current_year_capacity.append(mp_ancserv3_revenue[ic + iyear * current_num_per_year, 0])
                            extrapolated_current_year_capacity = extrapolate_timeseries(current_year_capacity, steps_per_hour)
                            for ic in range(extrapolated_current_year_capacity.size):
                                if (ic + iyear * current_num_per_year) < cleared_capacity_sum.size:
                                    ancillary_services3_capacity[ic + iyear * nsteps_per_year] = extrapolated_current_year_capacity[ic]
                                    cleared_capacity_sum[ic + iyear * nsteps_per_year] += extrapolated_current_year_capacity[ic]
                            if calculate_revenue:
                                current_year_revenue.clear()
                                current_year_revenue.reserve(current_num_per_year)
                                for ic in range(current_num_per_year):
                                    if (ic + iyear * current_num_per_year) < mp_ancserv3_revenue.nrows():
                                        current_year_revenue.append(mp_ancserv3_revenue[ic + iyear * current_num_per_year, 1])
                                extrapolated_current_year_revenue = extrapolate_timeseries(current_year_revenue, steps_per_hour)
                                for ic in range(extrapolated_current_year_revenue.size):
                                    if (ic + iyear * current_num_per_year) < ancillary_services3_revenue.size:
                                        ancillary_services3_revenue[ic + iyear * nsteps_per_year] = extrapolated_current_year_revenue[ic] # $/MWh
                        if en_mp_ancserv4:
                            current_year_capacity.clear()
                            current_num_per_year = mp_ancserv4_revenue.nrows() / Int(analysis_period)
                            current_year_capacity.reserve(current_num_per_year)
                            for ic in range(current_num_per_year):
                                if (ic + iyear * current_num_per_year) < mp_ancserv4_revenue.nrows():
                                    current_year_capacity.append(mp_ancserv4_revenue[ic + iyear * current_num_per_year, 0])
                            extrapolated_current_year_capacity = extrapolate_timeseries(current_year_capacity, steps_per_hour)
                            for ic in range(extrapolated_current_year_capacity.size):
                                if (ic + iyear * current_num_per_year) < cleared_capacity_sum.size:
                                    ancillary_services4_capacity[ic + iyear * nsteps_per_year] = extrapolated_current_year_capacity[ic]
                                    cleared_capacity_sum[ic + iyear * nsteps_per_year] += extrapolated_current_year_capacity[ic]
                            if calculate_revenue:
                                current_year_revenue.clear()
                                current_year_revenue.reserve(current_num_per_year)
                                for ic in range(current_num_per_year):
                                    if (ic + iyear * current_num_per_year) < mp_ancserv4_revenue.nrows():
                                        current_year_revenue.append(mp_ancserv4_revenue[ic + iyear * current_num_per_year, 1])
                                extrapolated_current_year_revenue = extrapolate_timeseries(current_year_revenue, steps_per_hour)
                                for ic in range(extrapolated_current_year_revenue.size):
                                    if (ic + iyear * current_num_per_year) < ancillary_services4_revenue.size:
                                        ancillary_services4_revenue[ic + iyear * nsteps_per_year] = extrapolated_current_year_revenue[ic] # $/MWh
                    if cleared_capacity_sum.size != system_generation.size:
                        error = util.format("cleared capacity size %d and capacity check size %d do not match", Int(cleared_capacity_sum.size), Int(system_generation.size))
                    else:
                        for i in range(cleared_capacity_sum.size):
                            if i >= system_generation.size:
                                break
                            /*
                             if (energy_market_capacity[i] < 0)
                            {
                                error = util::format("energy market cleared capacity %g is less than zero at timestep %d", energy_market_capacity[i], int(i));
                                break;
                            }
                            else if (ancillary_services1_capacity[i] < 0)
                            {
                                error = util::format("ancillary services 1 market cleared capacity %g is less than zero at timestep %d", ancillary_services1_capacity[i], int(i));
                                break;
                            }
                            else if (ancillary_services2_capacity[i] < 0)
                            {
                                error = util::format("ancillary services 2 market cleared capacity %g is less than zero at timestep %d", ancillary_services2_capacity[i], int(i));
                                break;
                            }
                            else if (ancillary_services3_capacity[i] < 0)
                            {
                                error = util::format("ancillary services 3 market cleared capacity %g is less than zero at timestep %d", ancillary_services3_capacity[i], int(i));
                                break;
                            }
                            else if (ancillary_services4_capacity[i] < 0)
                            {
                                error = util::format("ancillary services 4 market cleared capacity %g is less than zero at timestep %d", ancillary_services4_capacity[i], int(i));
                                break;
                            }
                            else */  
                            if (cleared_capacity_sum[i] > 0) and (cleared_capacity_sum[i] > system_generation[i]):
                                error = util.format("sum of cleared capacity %g MW exceeds system capacity %g MW at timestep %d", cleared_capacity_sum[i], system_generation[i], Int(i))
                                break
                    if calculate_revenue:
                        # all user specified capacities are greater than zero and sum of all less than system generation at timestep i
                        vt.assign("mp_energy_market_cleared_capacity", var_data(energy_market_capacity.data(), energy_market_capacity.size))
                        vt.assign("mp_ancillary_services1_cleared_capacity", var_data(ancillary_services1_capacity.data(), ancillary_services1_capacity.size))
                        vt.assign("mp_ancillary_services2_cleared_capacity", var_data(ancillary_services2_capacity.data(), ancillary_services2_capacity.size))
                        vt.assign("mp_ancillary_services3_cleared_capacity", var_data(ancillary_services3_capacity.data(), ancillary_services3_capacity.size))
                        vt.assign("mp_ancillary_services4_cleared_capacity", var_data(ancillary_services4_capacity.data(), ancillary_services4_capacity.size))
                        vt.assign("mp_energy_market_price", var_data(energy_market_revenue.data(), energy_market_revenue.size))
                        vt.assign("mp_ancillary_services1_price", var_data(ancillary_services1_revenue.data(), ancillary_services1_revenue.size))
                        vt.assign("mp_ancillary_services2_price", var_data(ancillary_services2_revenue.data(), ancillary_services2_revenue.size))
                        vt.assign("mp_ancillary_services3_price", var_data(ancillary_services3_revenue.data(), ancillary_services3_revenue.size))
                        vt.assign("mp_ancillary_services4_price", var_data(ancillary_services4_revenue.data(), ancillary_services4_revenue.size))
                        vt.assign("mp_total_cleared_capacity", var_data(cleared_capacity_sum.data(), cleared_capacity_sum.size))
                        for i in range(system_generation.size):
                            if i >= energy_market_capacity.size or i >= energy_market_revenue.size:
                                break
                            if en_mp_energy_market:
                                energy_market_revenue[i] *= energy_market_capacity[i] / Float64(steps_per_hour) # [MW] * [$/MWh] / fraction per hour [1/h]
                            else:
                                energy_market_revenue[i] = 0.0
                            if en_mp_ancserv1:
                                ancillary_services1_revenue[i] *= ancillary_services1_capacity[i] / Float64(steps_per_hour) # [MW] * [$/MWh] / fraction per hour [1/h]
                            else:
                                ancillary_services1_revenue[i] = 0.0
                            if en_mp_ancserv2:
                                ancillary_services2_revenue[i] *= ancillary_services2_capacity[i] / Float64(steps_per_hour) # [MW] * [$/MWh] / fraction per hour [1/h]
                            else:
                                ancillary_services2_revenue[i] = 0.0
                            if en_mp_ancserv3:
                                ancillary_services3_revenue[i] *= ancillary_services3_capacity[i] / Float64(steps_per_hour) # [MW] * [$/MWh] / fraction per hour [1/h]
                            else:
                                ancillary_services3_revenue[i] = 0.0
                            if en_mp_ancserv4:
                                ancillary_services4_revenue[i] *= ancillary_services4_capacity[i] / Float64(steps_per_hour) # [MW] * [$/MWh] / fraction per hour [1/h]
                            else:
                                ancillary_services4_revenue[i] = 0.0
                else:
                    error = util.format("Invalid number of timesteps requested %d", Int(analysis_period))
            else:
                error = util.format("Invalid analysis period %d", Int(analysis_period))
        vt.assign("mp_energy_market_generated_revenue", var_data(energy_market_revenue.data(), energy_market_revenue.size))
        vt.assign("mp_ancillary_services1_generated_revenue", var_data(ancillary_services1_revenue.data(), ancillary_services1_revenue.size))
        vt.assign("mp_ancillary_services2_generated_revenue", var_data(ancillary_services2_revenue.data(), ancillary_services2_revenue.size))
        vt.assign("mp_ancillary_services3_generated_revenue", var_data(ancillary_services3_revenue.data(), ancillary_services3_revenue.size))
        vt.assign("mp_ancillary_services4_generated_revenue", var_data(ancillary_services4_revenue.data(), ancillary_services4_revenue.size))
    except e:
        error = String(e)
    ancillary_services_success = (error == "")
    vt.assign("mp_ancillary_services", var_data(ancillary_services_success))
    vt.assign("mp_ancillary_services_error", var_data(error))