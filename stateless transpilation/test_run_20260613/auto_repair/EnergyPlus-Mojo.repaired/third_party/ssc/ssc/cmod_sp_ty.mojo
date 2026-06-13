# C++ header includes translated to Mojo imports
from core import *
from lk_stdlib import *
from lk_absyn import *
from sam_csp_util import *
from lib_weatherfile import weatherfile
from lib_irradproc import *
from lib_pvwatts import pvwatts_celltemp
import math
import sys
import os

# static var_info _cm_vtab_sp_ty[] = { ... }
_cm_vtab_sp_ty = [
    { "type": SSC_INPUT,  "data_type": SSC_STRING, "name": "solar_resource_file", "label": "Weather file in TMY2, TMY3, EPW, or SMW.", "units": "", "group": "", "meta_group": "sp_ty", "required": "*", "constraints": "LOCAL_FILE", "description": "" },
    { "type": SSC_OUTPUT, "data_type": SSC_NUMBER, "name": "a", "label": "Modified nonideality factor", "units": "1/V", "group": "", "meta_group": "6 Parameter Solver", "required": "*", "constraints": "", "description": "" },
    var_info_invalid
]

# class cm_sp_ty : public compute_module
class cm_sp_ty(compute_module):
    def __init__(self):
        self.add_var_info(_cm_vtab_sp_ty)

    # double powerout(...)
    def powerout(self, dc_nameplate: float, ac_nameplate: float, inv_eff_percent: float, loss_percent: float, ts_hour: float, poa: float, wspd: float, tdry: float) -> float:
        wspd_corr = 0.0 if wspd < 0 else wspd
        tpoa = poa
        if tpoa < 0.0:
            tpoa = 0.0
        inoct = 45 + 273.15
        height = 5.0
        tccalc = pvwatts_celltemp(inoct, height, ts_hour)
        pvt = tccalc(poa, wspd_corr, tdry)
        gamma = -0.0047
        dc = dc_nameplate * (1.0 + gamma * (pvt - 25.0)) * tpoa / 1000.0
        dc = dc * (1 - loss_percent / 100)
        etanom = inv_eff_percent / 100.0
        etaref = 0.9637
        A = -0.0162
        B = -0.0059
        C = 0.9858
        pdc0 = ac_nameplate / etanom
        plr = dc / pdc0
        ac = 0.0
        if plr > 0:
            eta = (A * plr + B / plr + C) * etanom / etaref
            ac = dc * eta
        if ac > ac_nameplate:
            ac = ac_nameplate
        if ac < 0:
            ac = 0
        return ac

    # void exec()
    def exec(self):
        DNI_cutoff = 250.0		            	# [W/m2]
        eta_rec_therm = 0.9		            	# [-] Estimated receiver thermal efficiency
        eta_cycle = 0.5						# [-] Estimated power cycle efficiency
        eta_csp_parasitics = 0.93           	# [-] Receiver parasitics that scale with thermal power (HTF pumping power, BOP, etc)
        dispatch_price_multiplier = 1.0     	# [-] Annualized additional value of CSP realized by dispatching during peak demand
        pv_area_frac = 0.95					# [-] Fraction of back area that contains PV
        eta_pv = 0.17						# [-] Design efficiency of PV
        eta_inverter = 0.97					# [-] Inverter efficiency
        eta_pv_losses = 0.946				# [-] Other pv losses (from detailed PV model Losses page)
        Q_delivered_CSP_min = 990.0			# [kWh/m2] Minimum annual thermal energy delivered by heliostat for 'standard' case
        availability_csp = 0.96				# [-] Fraction of annual energy calculated assuming continuous operation that can be realized by actual plant considering O&M and other shutdowns
        A_hel = 20.0						# [m2] Heliostat structure area
        A_hel_refl_frac = 0.97				# [-] Reflective surface ratio
        pv_cost_frac = 0.5					# [-] Cost of PV installed on heliostat relative to pv-only installation
        annual_output_pv = 6009.0			# [kWh] PVWatts calculated output for 'pv_watts_nameplate' calculated below
        dc_ac_ratio = 1.1
        inv_eff_percent = 97.0
        loss_percent = 10.0
        A_pv = A_hel * pv_area_frac						# [m2]
        pv_watts_nameplate = A_pv * eta_pv * 1000.0		# [Wdc]		
        ac_nameplate = pv_watts_nameplate / dc_ac_ratio
        file_dir = "C:/Users/tneises/Documents/2015 LPDP/csp pv/rotate vs static cavity/Analysis with helfieldpos 180 field"
        if not lk.dir_exists(file_dir):
            raise exec_error("SP_ty", util.format("Directory does not exist"))

        eta_files = lk.dir_list(file_dir, "csv", False)
        n_eta_files = len(eta_files)
        n_sol_pos = n_eta_files

        for i in range(n_eta_files):
            eta_files[i] = file_dir + "/" + eta_files[i]

        opt_line = ""
        n_heliostats_per_sol_pos = [0] * n_sol_pos
        azimuth_per_sol_pos = [0.0] * n_sol_pos
        zenith_per_sol_pos = [0.0] * n_sol_pos

        fp = None
        for i in range(n_eta_files):
            fp = open(eta_files[i], "r")
            if not fp:
                raise exec_error("SP_ty", util.format("there was a problem opening the file"))
            line_ok = lk.read_line(fp, opt_line)
            line_ok = lk.read_line(fp, opt_line)
            comma1 = opt_line.find(",")
            comma1 = opt_line.find(",", comma1 + 1)
            if comma1 == -1:
                raise exec_error("SP_ty", util.format("file does not seem to have zenith angle"))
            comma2 = opt_line.find(",", comma1 + 1)
            if comma2 == -1:
                raise exec_error("SP_ty", util.format("file does not seem to have zenith angle"))
            zenith = 90.0 - float(opt_line[comma1+1:comma2])
            line_ok = lk.read_line(fp, opt_line)
            comma1 = opt_line.find(",")
            comma1 = opt_line.find(",", comma1 + 1)
            if comma1 == -1:
                raise exec_error("SP_ty", util.format("file does not seem to have azimuth angle"))
            comma2 = opt_line.find(",", comma1 + 1)
            if comma2 == -1:
                raise exec_error("SP_ty", util.format("file does not seem to have azimuth angle"))
            azimuth = float(opt_line[comma1+1:comma2])
            line_ok = lk.read_line(fp, opt_line)
            line_ok = lk.read_line(fp, opt_line)
            line_ok = lk.read_line(fp, opt_line)
            line_ok = lk.read_line(fp, opt_line)
            line_ok = lk.read_line(fp, opt_line)
            line_ok = lk.read_line(fp, opt_line)
            line_ok = lk.read_line(fp, opt_line)
            n_heliostats = 0
            while True:
                if not lk.read_line(fp, opt_line):
                    break
                else:
                    n_heliostats += 1
            n_heliostats_per_sol_pos[i] = n_heliostats
            azimuth_per_sol_pos[i] = azimuth
            zenith_per_sol_pos[i] = zenith
            fp.close()

        for i in range(1, n_sol_pos):
            if n_heliostats_per_sol_pos[i] != n_heliostats_per_sol_pos[0]:
                raise exec_error("SP_ty", util.format("All files do not contain the same number of heliostats"))

        n_heliostats_field = n_heliostats_per_sol_pos[0]
        listed_azimuth = [azimuth_per_sol_pos[0]]
        n_zenith_per_az = [0]
        listed_zenith = [zenith_per_sol_pos[0]]

        for i in range(n_sol_pos):
            n_listed_azimuth = len(listed_azimuth)
            new_az_pos = True
            j = 0
            while j < n_listed_azimuth:
                if azimuth_per_sol_pos[i] == listed_azimuth[j]:
                    new_az_pos = False
                    break
                j += 1
            if new_az_pos:
                listed_azimuth.append(azimuth_per_sol_pos[i])
                n_zenith_per_az.append(1)
            else:
                n_zenith_per_az[j] += 1

            n_listed_zenith = len(listed_zenith)
            new_zen_pos = True
            for jj in range(n_listed_zenith):
                if zenith_per_sol_pos[i] == listed_zenith[jj]:
                    new_zen_pos = False
                    break
            if new_zen_pos:
                listed_zenith.append(zenith_per_sol_pos[i])

        n_azimuth = len(listed_azimuth)
        if n_azimuth < 3:
            raise exec_error("SP_ty", util.format("Need at least 3 azimuth angles"))

        for i in range(1, len(n_zenith_per_az)):
            if n_zenith_per_az[i] != n_zenith_per_az[0]:
                raise exec_error("SP_ty", util.format("Need same number of zenith angles for each azimuth angle"))

        if n_zenith_per_az[0] < 2:
            raise exec_error("SP_ty", util.format("Need at least 2 zenith angles"))

        n_zenith = len(listed_zenith)
        found_zenith_90 = False
        for i in range(n_zenith):
            if listed_zenith[i] == 0.0:
                found_zenith_90 = True
                break
        if not found_zenith_90:
            raise exec_error("SP_ty", util.format("Need a zenith angle = 0 degrees"))

        found_az_180 = False
        found_az_n_180 = False
        for i in range(n_azimuth):
            if listed_azimuth[i] == 180:
                found_az_180 = True
            if listed_azimuth[i] == -180:
                found_az_n_180 = True
        if not found_az_180 or not found_az_n_180:
            raise exec_error("SP_ty", util.format("Need azimuth angles =  +/- 180 degrees"))

        sorted_azimuth = listed_azimuth[:]
        sorted_zenith = listed_zenith[:]
        max_az = 1000.0
        min_az = -1000.0
        local_max = max_az
        save_index = -1
        for i in range(len(listed_azimuth)):
            for j in range(len(listed_azimuth)):
                if listed_azimuth[j] < local_max and listed_azimuth[j] > min_az:
                    local_max = listed_azimuth[j]
                    save_index = j
            sorted_azimuth[i] = listed_azimuth[save_index]
            min_az = sorted_azimuth[i]
            local_max = max_az

        max_zen = 1000.0
        min_zen = -1000.0
        local_max = max_zen
        save_index = -1
        for i in range(len(listed_zenith)):
            for j in range(len(listed_zenith)):
                if listed_zenith[j] < local_max and listed_zenith[j] > min_zen:
                    local_max = listed_zenith[j]
                    save_index = j
            sorted_zenith[i] = listed_zenith[save_index]
            min_zen = sorted_zenith[i]
            local_max = max_zen

        combined_eta_opt = util.matrix_t[float](n_sol_pos, n_heliostats_field, 0.0)
        r_hel = [0.0] * n_heliostats_field
        az_hel = [0.0] * n_heliostats_field

        for i in range(n_eta_files):
            fp = open(eta_files[i], "r")
            line_ok = lk.read_line(fp, opt_line)
            line_ok = lk.read_line(fp, opt_line)
            line_ok = lk.read_line(fp, opt_line)
            line_ok = lk.read_line(fp, opt_line)
            line_ok = lk.read_line(fp, opt_line)
            line_ok = lk.read_line(fp, opt_line)
            line_ok = lk.read_line(fp, opt_line)
            line_ok = lk.read_line(fp, opt_line)
            line_ok = lk.read_line(fp, opt_line)
            line_ok = lk.read_line(fp, opt_line)
            n_heliostats = 0
            x_pos = 0.0
            y_pos = 0.0
            z_pos = 0.0
            opt_eta_single = 0.0
            az_local = 0.0
            while True:
                if not lk.read_line(fp, opt_line):
                    break
                else:
                    comma1 = opt_line.find(",")
                    comma2 = opt_line.find(",", comma1 + 1)
                    x_pos = float(opt_line[comma1+1:comma2])
                    comma1 = comma2
                    comma2 = opt_line.find(",", comma1 + 1)
                    y_pos = float(opt_line[comma1+1:comma2])
                    comma1 = comma2
                    comma2 = opt_line.find(",", comma1 + 1)
                    z_pos = float(opt_line[comma1+1:comma2])
                    if i == 0:
                        r_hel[n_heliostats] = math.sqrt(y_pos * y_pos + x_pos * x_pos)
                        if y_pos == 0.0:
                            if x_pos < 0.0:
                                az_local = -90.0
                            else:
                                az_local = 90.0
                        else:
                            az_local = math.atan(x_pos / y_pos) * 180.0 / 3.1412
                        az_hel[n_heliostats] = az_local
                    comma1 = comma2
                    comma2 = opt_line.find(",", comma1 + 1)
                    opt_eta_single = float(opt_line[comma1+1:comma2])
                    combined_eta_opt[i, n_heliostats] = opt_eta_single
                    n_heliostats += 1
            fp.close()

        test_radius = float('nan')
        test_radius_0az_index = -1
        for i in range(n_heliostats_field):
            if r_hel[i] > 450.0 and r_hel[i] < 550.0 and az_hel[i] == 0.0:
                test_radius = r_hel[i]
                test_radius_0az_index = i

        if math.isnan(test_radius):
            raise exec_error("sp_ty", "couldn't find radius within band that had az = 0")

        hel_id_test_radius = []
        for i in range(n_heliostats_field):
            if abs(r_hel[i] - test_radius) < 0.1:
                hel_id_test_radius.append(i)
        n_heliostats_test_radius = len(hel_id_test_radius)

        hel_id_test_radius_az_sorted = [0] * n_heliostats_test_radius
        max_az = 1000.0
        min_az = -1000.0
        local_max = max_az
        save_index = -1
        for i in range(n_heliostats_test_radius):
            for j in range(n_heliostats_test_radius):
                if az_hel[hel_id_test_radius[j]] < local_max and az_hel[hel_id_test_radius[j]] > min_az:
                    local_max = az_hel[hel_id_test_radius[j]]
                    save_index = j
            hel_id_test_radius_az_sorted[i] = hel_id_test_radius[save_index]
            min_az = az_hel[hel_id_test_radius[save_index]]
            local_max = max_az

        rec_rotate_span = 0.0
        for index_rec_rot in range(18, 19):
            rec_rotate_span = 10 * (index_rec_rot)
            hel_csp_to_rec_annual = [0.0] * n_heliostats_test_radius
            csp_available_relval_annual = [0.0] * n_heliostats_test_radius
            csp_produced_relval_annual = [0.0] * n_heliostats_test_radius
            pv_available_relval_annual = [0.0] * n_heliostats_test_radius
            pv_produced_relval_annual = [0.0] * n_heliostats_test_radius
            annual_bin0_10 = [0.0] * n_heliostats_test_radius
            annual_bin11_20 = [0.0] * n_heliostats_test_radius
            annual_bin21_30 = [0.0] * n_heliostats_test_radius
            annual_bin31_40 = [0.0] * n_heliostats_test_radius
            annual_bin41_50 = [0.0] * n_heliostats_test_radius
            annual_bin51_60 = [0.0] * n_heliostats_test_radius
            annual_bin61_70 = [0.0] * n_heliostats_test_radius
            annual_bin71_80 = [0.0] * n_heliostats_test_radius
            annual_bin81_90 = [0.0] * n_heliostats_test_radius
            annual_bin91_100 = [0.0] * n_heliostats_test_radius

            # assign (already initialized)
            for index_nh in range(n_heliostats_test_radius):
                wf = weatherfile(self.as_string("solar_resource_file"))
                if not wf.ok():
                    raise exec_error("sp_ty", wf.error_message())
                nrec = wf.nrecords
                step_per_hour = nrec // 8760
                if step_per_hour < 1 or step_per_hour > 60 or step_per_hour * 8760 != nrec:
                    raise exec_error("sp_ty", util.format("invalid number of data records (%d): must be an integer multiple of 8760", int(nrec)))
                ts_hour = 1.0 / step_per_hour
                sun_up_hours = 0
                bin0_10 = 0
                bin11_20 = 0
                bin21_30 = 0
                bin31_40 = 0
                bin41_50 = 0
                bin51_60 = 0
                bin61_70 = 0
                bin71_80 = 0
                bin81_90 = 0
                bin91_100 = 0
                idx = 0
                hour = 0
                while hour < 8760:
                    sum_opt_eta_dni_product = 0.0
                    sum_csp_available_relval_ts = 0.0
                    sum_csp_produced_relval_ts = 0.0
                    sum_pv_available_relval_ts = 0.0
                    sum_pv_produced_relval_ts = 0.0
                    for jj in range(step_per_hour):
                        if not wf.read():
                            raise exec_error("sp_ty", "could not read data line " + util.to_string(int(idx + 1)) + " in weather file")
                        if wf.dn < 0 or wf.dn > 1500.0:
                            self.log(util.format("invalid beam irradiance %lg W/m2 at time [y:%d m:%d d:%d h:%d], set to zero",
                                wf.dn, wf.year, wf.month, wf.day, wf.hour), SSC_WARNING, float(idx))
                            wf.dn = 0
                        irr = irrad()
                        irr.set_time(wf.year, wf.month, wf.day, wf.hour, wf.minute, ts_hour)
                        irr.set_location(wf.lat, wf.lon, wf.tz)
                        irr.set_optional()
                        skymodel = 2
                        alb = 0.2
                        irr.set_sky_model(skymodel, alb)
                        irr.set_beam_diffuse(wf.dn, wf.df)
                        track_mode = 2
                        irr.set_surface(2, 0.0, 0.0, 0.0, False, 0.3)
                        code = irr.calc()
                        if code != 0:
                            raise exec_error("pvsamv1",
                                util.format("failed to process irradiation on surface %d (code: %d) [y:%d m:%d d:%d h:%d]",
                                    1, code, wf.year, wf.month, wf.day, wf.hour))
                        solazi = 0.0
                        solzen = 0.0
                        solalt = 0.0
                        sunup = 0
                        irr.get_sun(&solazi, &solzen, &solalt, 0, 0, 0, &sunup, 0, 0, 0)
                        ibeam = 0.0
                        iskydiff = 0.0
                        ignddiff = 0.0
                        irr.get_poa(&ibeam, &iskydiff, &ignddiff, 0, 0, 0)
                        poa_pv = ibeam + iskydiff + ignddiff
                        opt_eta_dni_product = 0.0
                        csp_available_relval_ts = 0.0
                        csp_produced_relval_ts = 0.0
                        pv_available_relval_ts = 0.0
                        pv_produced_relval_ts = 0.0
                        if sunup == 1:
                            sun_up_hours += 1
                            az_sp = 0.0
                            if solazi > 180.0:
                                az_sp = solazi - 360.0
                            else:
                                az_sp = solazi
                            az_sp360 = az_sp
                            if az_sp360 < 0.0:
                                az_sp360 += 360
                            az_rec360 = 0.0
                            min_az360 = 180.0 - 0.5 * rec_rotate_span
                            max_az360 = 180.0 + 0.5 * rec_rotate_span
                            if az_sp360 < min_az360:
                                az_rec360 = min_az360
                            elif az_sp360 > max_az360:
                                az_rec360 = max_az360
                            else:
                                az_rec360 = az_sp360
                            az_hel_local360 = az_hel[hel_id_test_radius_az_sorted[index_nh]] + 180.0
                            delta_az_hel_rec = az_hel_local360 - az_rec360
                            index_hel_proxy = -1
                            for i in range(n_heliostats_test_radius):
                                if az_hel[hel_id_test_radius_az_sorted[i]] > delta_az_hel_rec:
                                    index_hel_proxy = hel_id_test_radius_az_sorted[i]
                                    break
                            opt_eta_point = 0.0
                            if index_hel_proxy > -1:
                                check_az = az_hel[index_hel_proxy]
                                az_solar_proxy360 = 180.0
                                if az_sp360 < min_az360:
                                    az_solar_proxy360 = az_sp360 - min_az360
                                if az_sp360 > max_az360:
                                    az_solar_proxy360 = az_sp360 - max_az360
                                optical_table = OpticalDataTable()
                                xax = [0.0] * n_azimuth
                                for i in range(n_azimuth):
                                    xax[i] = sorted_azimuth[i]
                                yax = [0.0] * (n_zenith + 1)
                                for i in range(n_zenith):
                                    yax[i] = sorted_zenith[i]
                                yax[n_zenith] = 90.0
                                data = [0.0] * ((n_zenith + 1) * n_azimuth)
                                for i in range(n_sol_pos):
                                    z_local = zenith_per_sol_pos[i]
                                    a_local = azimuth_per_sol_pos[i]
                                    i_local = -1
                                    for ii in range(n_azimuth):
                                        if sorted_azimuth[ii] == a_local:
                                            i_local = ii
                                            break
                                    j_local = -1
                                    for ii in range(n_zenith):
                                        if sorted_zenith[ii] == z_local:
                                            j_local = ii
                                            break
                                    data[i_local + (n_azimuth) * j_local] = combined_eta_opt[i, index_hel_proxy]
                                for i in range(n_azimuth):
                                    data[i + (n_azimuth) * n_zenith] = 0.0
                                optical_table.AddXAxis(xax, n_azimuth)
                                optical_table.AddYAxis(yax, n_zenith + 1)
                                optical_table.AddData(data)
                                # delete not needed in Mojo (GC)
                                opt_eta_point = optical_table.interpolate(az_sp, solzen)
                            else:
                                opt_eta_point = 0.0

                            pv_available_relval_ts = self.powerout(pv_watts_nameplate, ac_nameplate, inv_eff_percent, loss_percent, ts_hour, poa_pv, wf.wspd, wf.tdry) / 1000.0
                            if wf.dn > DNI_cutoff:
                                opt_eta_dni_product = opt_eta_point * wf.dn * 0.001
                                csp_available_relval_ts = opt_eta_point * wf.dn * 0.001 * eta_rec_therm * eta_cycle * eta_csp_parasitics * dispatch_price_multiplier * A_hel * A_hel_refl_frac
                                if csp_available_relval_ts > pv_available_relval_ts:
                                    csp_produced_relval_ts = csp_available_relval_ts
                                    pv_produced_relval_ts = 0.0
                                else:
                                    csp_produced_relval_ts = 0.0
                                    pv_produced_relval_ts = pv_available_relval_ts
                            else:
                                opt_eta_dni_product = 0.0
                                csp_available_relval_ts = 0.0
                                csp_produced_relval_ts = 0.0
                                pv_produced_relval_ts = pv_available_relval_ts
                            opt_eta_point = opt_eta_dni_product / (950.0 * 0.001)
                            if opt_eta_point <= 0.10:
                                bin0_10 += 1
                            elif opt_eta_point <= 0.20:
                                bin11_20 += 1
                            elif opt_eta_point <= 0.30:
                                bin21_30 += 1
                            elif opt_eta_point <= 0.40:
                                bin31_40 += 1
                            elif opt_eta_point <= 0.50:
                                bin41_50 += 1
                            elif opt_eta_point <= 0.60:
                                bin51_60 += 1
                            elif opt_eta_point <= 0.70:
                                bin61_70 += 1
                            elif opt_eta_point <= 0.80:
                                bin71_80 += 1
                            elif opt_eta_point <= 0.90:
                                bin81_90 += 1
                            else:
                                bin91_100 += 1
                        else:
                            opt_eta_dni_product = 0.0
                            csp_available_relval_ts = 0.0
                            csp_produced_relval_ts = 0.0
                            pv_available_relval_ts = 0.0
                            pv_produced_relval_ts = 0.0
                        sum_opt_eta_dni_product += opt_eta_dni_product * ts_hour
                        sum_csp_available_relval_ts += csp_available_relval_ts * ts_hour
                        sum_csp_produced_relval_ts += csp_produced_relval_ts * ts_hour
                        sum_pv_available_relval_ts += pv_available_relval_ts * ts_hour
                        sum_pv_produced_relval_ts += pv_produced_relval_ts * ts_hour
                        idx += 1
                    hel_csp_to_rec_annual[index_nh] += sum_opt_eta_dni_product
                    csp_available_relval_annual[index_nh] += sum_csp_available_relval_ts
                    csp_produced_relval_annual[index_nh] += sum_csp_produced_relval_ts
                    pv_available_relval_annual[index_nh] += sum_pv_available_relval_ts
                    pv_produced_relval_annual[index_nh] += sum_pv_produced_relval_ts
                    hour += 1

                sun_up_total = float(sun_up_hours)
                annual_bin0_10[index_nh] = float(bin0_10) / sun_up_total
                annual_bin11_20[index_nh] = float(bin11_20) / sun_up_total
                annual_bin21_30[index_nh] = float(bin21_30) / sun_up_total
                annual_bin31_40[index_nh] = float(bin31_40) / sun_up_total
                annual_bin41_50[index_nh] = float(bin41_50) / sun_up_total
                annual_bin51_60[index_nh] = float(bin51_60) / sun_up_total
                annual_bin61_70[index_nh] = float(bin61_70) / sun_up_total
                annual_bin71_80[index_nh] = float(bin71_80) / sun_up_total
                annual_bin81_90[index_nh] = float(bin81_90) / sun_up_total
                annual_bin91_100[index_nh] = float(bin91_100) / sun_up_total

            hel_performance_processed = file_dir + "/hel_performance_processed_rotate_" + str(rec_rotate_span) + ".txt"
            hel_output_file = open(hel_performance_processed, "w")
            out_line = "heliostat id,azimuth,radius,Q_deliver_hel (kWh_per_m2),CSP_avail_relval (kWeh),CSP_produced_relval (kWeh),PV_avail_relval (kWeh),PV_produced_relval (kWeh),bin0-11,bin11-20,bin21-30,bin31-40,bin41-50,bin51-60,bin61-70,bin71-80,bin81-90,bin91-100\n"
            hel_output_file.write(out_line)
            for i in range(n_heliostats_test_radius):
                hel_output_file.write(
                    str(hel_id_test_radius_az_sorted[i]) + "," +
                    str(az_hel[hel_id_test_radius_az_sorted[i]]) + "," +
                    str(r_hel[hel_id_test_radius_az_sorted[i]]) + "," +
                    str(hel_csp_to_rec_annual[i]) + "," +
                    str(csp_available_relval_annual[i] * availability_csp) + "," +
                    str(csp_produced_relval_annual[i] * availability_csp) + "," +
                    str(pv_available_relval_annual[i]) + "," +
                    str(availability_csp * (pv_produced_relval_annual[i] - pv_available_relval_annual[i]) + pv_available_relval_annual[i]) + "," +
                    str(annual_bin0_10[i]) + "," +
                    str(annual_bin11_20[i]) + "," +
                    str(annual_bin21_30[i]) + "," +
                    str(annual_bin31_40[i]) + "," +
                    str(annual_bin41_50[i]) + "," +
                    str(annual_bin51_60[i]) + "," +
                    str(annual_bin61_70[i]) + "," +
                    str(annual_bin71_80[i]) + "," +
                    str(annual_bin81_90[i]) + "," +
                    str(annual_bin91_100[i]) + "\n"
                )
            hel_output_file.close()

        # return; // C++ return here, but we continue for static simulation (dead code)
        return

        # Dead code below (static simulation)
        hel_csp_to_rec_annual = [0.0] * n_heliostats_field
        csp_available_relval_annual = [0.0] * n_heliostats_field
        csp_produced_relval_annual = [0.0] * n_heliostats_field
        pv_available_relval_annual = [0.0] * n_heliostats_field
        pv_produced_relval_annual = [0.0] * n_heliostats_field
        annual_bin0_10 = [0.0] * n_heliostats_field
        annual_bin11_20 = [0.0] * n_heliostats_field
        annual_bin21_30 = [0.0] * n_heliostats_field
        annual_bin31_40 = [0.0] * n_heliostats_field
        annual_bin41_50 = [0.0] * n_heliostats_field
        annual_bin51_60 = [0.0] * n_heliostats_field
        annual_bin61_70 = [0.0] * n_heliostats_field
        annual_bin71_80 = [0.0] * n_heliostats_field
        annual_bin81_90 = [0.0] * n_heliostats_field
        annual_bin91_100 = [0.0] * n_heliostats_field

        # assign calls (already initialized)
        for index_nh in range(n_heliostats_test_radius):
            if index_nh % (n_heliostats_test_radius) == 0:
                percent = 100.0 * (float(index_nh) + 1) / float(n_heliostats_test_radius)
                if not self.update("", percent, float(index_nh)):
                    raise exec_error("sp_ty", "update failed")

            optical_table = OpticalDataTable()
            xax = [0.0] * n_azimuth
            for i in range(n_azimuth):
                xax[i] = sorted_azimuth[i]
            yax = [0.0] * (n_zenith + 1)
            for i in range(n_zenith):
                yax[i] = sorted_zenith[i]
            yax[n_zenith] = 90.0
            data = [0.0] * ((n_zenith + 1) * n_azimuth)
            for i in range(n_sol_pos):
                z_local = zenith_per_sol_pos[i]
                a_local = azimuth_per_sol_pos[i]
                i_local = -1
                for ii in range(n_azimuth):
                    if sorted_azimuth[ii] == a_local:
                        i_local = ii
                        break
                j_local = -1
                for ii in range(n_zenith):
                    if sorted_zenith[ii] == z_local:
                        j_local = ii
                        break
                data[i_local + (n_azimuth) * j_local] = combined_eta_opt[i, hel_id_test_radius_az_sorted[index_nh]]
            for i in range(n_azimuth):
                data[i + (n_azimuth) * n_zenith] = 0.0
            optical_table.AddXAxis(xax, n_azimuth)
            optical_table.AddYAxis(yax, n_zenith + 1)
            optical_table.AddData(data)

            wf = weatherfile(self.as_string("solar_resource_file"))
            if not wf.ok():
                raise exec_error("sp_ty", wf.error_message())
            nrec = wf.nrecords
            step_per_hour = nrec // 8760
            if step_per_hour < 1 or step_per_hour > 60 or step_per_hour * 8760 != nrec:
                raise exec_error("sp_ty", util.format("invalid number of data records (%d): must be an integer multiple of 8760", int(nrec)))
            ts_hour = 1.0 / step_per_hour
            sun_up_hours = 0
            bin0_10 = 0
            bin11_20 = 0
            bin21_30 = 0
            bin31_40 = 0
            bin41_50 = 0
            bin51_60 = 0
            bin61_70 = 0
            bin71_80 = 0
            bin81_90 = 0
            bin91_100 = 0
            idx = 0
            hour = 0
            while hour < 8760:
                sum_opt_eta_dni_product = 0.0
                sum_csp_available_relval_ts = 0.0
                sum_csp_produced_relval_ts = 0.0
                sum_pv_available_relval_ts = 0.0
                sum_pv_produced_relval_ts = 0.0
                for jj in range(step_per_hour):
                    if not wf.read():
                        raise exec_error("sp_ty", "could not read data line " + util.to_string(int(idx + 1)) + " in weather file")
                    if wf.dn < 0 or wf.dn > 1500.0:
                        self.log(util.format("invalid beam irradiance %lg W/m2 at time [y:%d m:%d d:%d h:%d], set to zero",
                            wf.dn, wf.year, wf.month, wf.day, wf.hour), SSC_WARNING, float(idx))
                        wf.dn = 0
                    irr = irrad()
                    irr.set_time(wf.year, wf.month, wf.day, wf.hour, wf.minute, ts_hour)
                    irr.set_location(wf.lat, wf.lon, wf.tz)
                    irr.set_optional()
                    skymodel = 2
                    alb = 0.2
                    irr.set_sky_model(skymodel, alb)
                    irr.set_beam_diffuse(wf.dn, wf.df)
                    track_mode = 2
                    irr.set_surface(2, 0.0, 0.0, 0.0, False, 0.3)
                    code = irr.calc()
                    if code != 0:
                        raise exec_error("pvsamv1",
                            util.format("failed to process irradiation on surface %d (code: %d) [y:%d m:%d d:%d h:%d]",
                                1, code, wf.year, wf.month, wf.day, wf.hour))
                    solazi = 0.0
                    solzen = 0.0
                    solalt = 0.0
                    sunup = 0
                    irr.get_sun(&solazi, &solzen, &solalt, 0, 0, 0, &sunup, 0, 0, 0)
                    ibeam = 0.0
                    iskydiff = 0.0
                    ignddiff = 0.0
                    irr.get_poa(&ibeam, &iskydiff, &ignddiff, 0, 0, 0)
                    poa_pv = ibeam + iskydiff + ignddiff
                    az_sp = 0.0
                    if solazi > 180.0:
                        az_sp = solazi - 360.0
                    else:
                        az_sp = solazi
                    opt_eta_point = 0.0
                    if sunup:
                        opt_eta_point = optical_table.interpolate(az_sp, solzen)
                    else:
                        opt_eta_point = 0.0
                    opt_eta_dni_product = 0.0
                    csp_available_relval_ts = 0.0
                    csp_produced_relval_ts = 0.0
                    pv_available_relval_ts = 0.0
                    pv_produced_relval_ts = 0.0
                    if sunup == 1:
                        sun_up_hours += 1
                        pv_available_relval_ts = self.powerout(pv_watts_nameplate, ac_nameplate, inv_eff_percent, loss_percent, ts_hour, poa_pv, wf.wspd, wf.tdry) / 1000.0
                        if wf.dn > DNI_cutoff:
                            opt_eta_dni_product = opt_eta_point * wf.dn * 0.001
                            csp_available_relval_ts = opt_eta_point * wf.dn * 0.001 * eta_rec_therm * eta_cycle * eta_csp_parasitics * dispatch_price_multiplier * A_hel * A_hel_refl_frac
                            if csp_available_relval_ts > pv_available_relval_ts:
                                csp_produced_relval_ts = csp_available_relval_ts
                                pv_produced_relval_ts = 0.0
                            else:
                                csp_produced_relval_ts = 0.0
                                pv_produced_relval_ts = pv_available_relval_ts
                        else:
                            opt_eta_dni_product = 0.0
                            csp_available_relval_ts = 0.0
                            csp_produced_relval_ts = 0.0
                            pv_produced_relval_ts = pv_available_relval_ts
                        opt_eta_point = opt_eta_dni_product / (950.0 * 0.001)
                        if opt_eta_point <= 0.10:
                            bin0_10 += 1
                        elif opt_eta_point <= 0.20:
                            bin11_20 += 1
                        elif opt_eta_point <= 0.30:
                            bin21_30 += 1
                        elif opt_eta_point <= 0.40:
                            bin31_40 += 1
                        elif opt_eta_point <= 0.50:
                            bin41_50 += 1
                        elif opt_eta_point <= 0.60:
                            bin51_60 += 1
                        elif opt_eta_point <= 0.70:
                            bin61_70 += 1
                        elif opt_eta_point <= 0.80:
                            bin71_80 += 1
                        elif opt_eta_point <= 0.90:
                            bin81_90 += 1
                        else:
                            bin91_100 += 1
                    else:
                        opt_eta_dni_product = 0.0
                        csp_available_relval_ts = 0.0
                        csp_produced_relval_ts = 0.0
                        pv_available_relval_ts = 0.0
                        pv_produced_relval_ts = 0.0
                    sum_opt_eta_dni_product += opt_eta_dni_product * ts_hour
                    sum_csp_available_relval_ts += csp_available_relval_ts * ts_hour
                    sum_csp_produced_relval_ts += csp_produced_relval_ts * ts_hour
                    sum_pv_available_relval_ts += pv_available_relval_ts * ts_hour
                    sum_pv_produced_relval_ts += pv_produced_relval_ts * ts_hour
                    idx += 1
                hel_csp_to_rec_annual[index_nh] += sum_opt_eta_dni_product
                csp_available_relval_annual[index_nh] += sum_csp_available_relval_ts
                csp_produced_relval_annual[index_nh] += sum_csp_produced_relval_ts
                pv_available_relval_annual[index_nh] += sum_pv_available_relval_ts
                pv_produced_relval_annual[index_nh] += sum_pv_produced_relval_ts
                hour += 1

            sun_up_total = float(sun_up_hours)
            annual_bin0_10[index_nh] = float(bin0_10) / sun_up_total
            annual_bin11_20[index_nh] = float(bin11_20) / sun_up_total
            annual_bin21_30[index_nh] = float(bin21_30) / sun_up_total
            annual_bin31_40[index_nh] = float(bin31_40) / sun_up_total
            annual_bin41_50[index_nh] = float(bin41_50) / sun_up_total
            annual_bin51_60[index_nh] = float(bin51_60) / sun_up_total
            annual_bin61_70[index_nh] = float(bin61_70) / sun_up_total
            annual_bin71_80[index_nh] = float(bin71_80) / sun_up_total
            annual_bin81_90[index_nh] = float(bin81_90) / sun_up_total
            annual_bin91_100[index_nh] = float(bin91_100) / sun_up_total

        hel_performance_processed = file_dir + "/hel_performance_processed_static.txt"
        hel_output_file = open(hel_performance_processed, "w")
        out_line = "heliostat id,azimuth,radius,Q_deliver_hel (kWh_per_m2),CSP_avail_relval (kWeh),CSP_produced_relval (kWeh),PV_avail_relval (kWeh),PV_produced_relval (kWeh),bin0-11,bin11-20,bin21-30,bin31-40,bin41-50,bin51-60,bin61-70,bin71-80,bin81-90,bin91-100\n"
        hel_output_file.write(out_line)
        for i in range(n_heliostats_test_radius):
            hel_output_file.write(
                str(hel_id_test_radius_az_sorted[i]) + "," +
                str(az_hel[hel_id_test_radius_az_sorted[i]]) + "," +
                str(r_hel[hel_id_test_radius_az_sorted[i]]) + "," +
                str(hel_csp_to_rec_annual[i]) + "," +
                str(csp_available_relval_annual[i] * availability_csp) + "," +
                str(csp_produced_relval_annual[i] * availability_csp) + "," +
                str(pv_available_relval_annual[i]) + "," +
                str(availability_csp * (pv_produced_relval_annual[i] - pv_available_relval_annual[i]) + pv_available_relval_annual[i]) + "," +
                str(annual_bin0_10[i]) + "," +
                str(annual_bin11_20[i]) + "," +
                str(annual_bin21_30[i]) + "," +
                str(annual_bin31_40[i]) + "," +
                str(annual_bin41_50[i]) + "," +
                str(annual_bin51_60[i]) + "," +
                str(annual_bin61_70[i]) + "," +
                str(annual_bin71_80[i]) + "," +
                str(annual_bin81_90[i]) + "," +
                str(annual_bin91_100[i]) + "\n"
            )
        hel_output_file.close()

        self.assign("a", 1.23456)
    # End of ssc exec()

# Module entry point
def DEFINE_MODULE_ENTRY(name: String, description: String, version: Int):
    # This function would register the module; placeholder

# Call entry
DEFINE_MODULE_ENTRY("sp_ty", "blah blah blah", 1)