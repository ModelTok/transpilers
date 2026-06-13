from vartab import var_table, var_data, vt_get_number, vt_get_int
from ...shared.lib_util import matrix_t
from math import pow, sqrt, pi as M_PI
from builtin import String, Int, Float64

def Turbine_calculate_powercurve(data: ssc_data_t):
    var vt: var_table = data as var_table
    if not vt:
        raise Error("ssc_data_t data invalid")

    var turbine_size: Float64
    var rotor_diameter: Float64
    var elevation: Float64
    var max_cp: Float64
    var max_tip_speed: Float64
    var max_tip_sp_ratio: Float64
    var cut_in: Float64
    var cut_out: Float64
    var drive_train: Int

    vt_get_number(vt, "turbine_size", turbine_size)
    vt_get_number(vt, "wind_turbine_rotor_diameter", rotor_diameter)
    vt_get_number(vt, "elevation", elevation)
    vt_get_number(vt, "wind_turbine_max_cp", max_cp)
    vt_get_number(vt, "max_tip_speed", max_tip_speed)
    vt_get_number(vt, "max_tip_sp_ratio", max_tip_sp_ratio)
    vt_get_number(vt, "cut_in", cut_in)
    vt_get_number(vt, "cut_out", cut_out)
    vt_get_int(vt, "drive_train", drive_train)

    var powercurve_windspeeds: matrix_t[ssc_number_t]
    var powercurve_powerout: matrix_t[ssc_number_t]
    var powercurve_hub_efficiency: matrix_t[ssc_number_t]

    var errmsg: String
    var region2_slope: Float64 = 5
    var a: Float64
    var b: Float64
    var c: Float64
    var drive_train_type: Int = drive_train + 1
    if drive_train_type == 1:
        a = 0.012894
        b = 0.085095
        c = 0.000000
    elif drive_train_type == 2:
        a = 0.013307
        b = 0.036547
        c = 0.061067
    elif drive_train_type == 3:
        a = 0.015474
        b = 0.044631
        c = 0.057898
    elif drive_train_type == 4:
        a = 0.010072
        b = 0.019995
        c = 0.068990
    else:
        raise Error("drive_train must be between 0 and 3")

    var eff: Float64 = 1.0 - (a + b + c)
    var rated_hub_power: Float64 = turbine_size / eff
    var air_density: Float64 = 101325.0 * pow(1 - (0.0065 * elevation / 288.15), (9.80665 / (0.0065 * 287.15))) / (287.15 * (288.15 - 0.0065 * elevation))
    var omega_m: Float64 = max_tip_speed / rotor_diameter * 2.0
    var omega_0: Float64 = omega_m / (1.0 + region2_slope / 100.0)
    var t_sub_m: Float64 = rated_hub_power * 1000.0 / omega_m
    var k: Float64 = air_density * M_PI * pow(rotor_diameter, 5) * max_cp / (64.0 * pow(max_tip_sp_ratio, 3))
    var omegaT_a: Float64 = k
    var omegaT_b: Float64 = -t_sub_m / (omega_m - omega_0)
    var omegaT_c: Float64 = t_sub_m * omega_0 / (omega_m - omega_0)
    var omegaT: Float64 = -(omegaT_b / (2.0 * omegaT_a)) - (sqrt(pow(omegaT_b, 2) - (4.0 * omegaT_a * omegaT_c)) / (2.0 * omegaT_a))
    var wind_at_omegaT: Float64 = omegaT * rotor_diameter / 2.0 / max_tip_sp_ratio
    var power_at_omegaT: Float64 = k * pow(omegaT, 3.0) / 1000.0
    var rated_wind_speed: Float64 = 0.33 * pow(2.0 * rated_hub_power * 1000.0 / (air_density * M_PI * pow(rotor_diameter, 2) / 4.0 * max_cp), (1.0 / 3.0)) + 0.67 * (((1.0 / (1.5 * air_density * M_PI * pow(rotor_diameter, 2) * 0.25 * max_cp * pow(wind_at_omegaT, 2))) * 1000.0 * (rated_hub_power - power_at_omegaT)) + wind_at_omegaT)

    if omegaT > omega_m:
        errmsg = "Turbine inputs are not valid, please adjust the inputs. omegaT: " + str(omegaT) + ", omegaM: " + str(omega_m)
        vt.assign("error", errmsg)

    var step: Float64 = 0.25
    var array_size: Int = 1 + Int(40 / step)
    powercurve_windspeeds.resize(array_size)
    powercurve_powerout.resize(array_size)
    powercurve_hub_efficiency.resize(array_size)

    for i in range(array_size):
        var ws: Float64 = i * step
        var hub_power: Float64
        if ws <= cut_in or ws >= cut_out:
            hub_power = 0.0
        elif ws < wind_at_omegaT:
            hub_power = k * pow(ws * max_tip_sp_ratio / rotor_diameter * 2.0, 3) / 1000.0
        elif ws <= rated_wind_speed:
            hub_power = (rated_hub_power - power_at_omegaT) / (rated_wind_speed - wind_at_omegaT) * (ws - wind_at_omegaT) + power_at_omegaT
        else:
            hub_power = rated_hub_power

        if hub_power > rated_hub_power:
            errmsg = "Turbine power curve calculation calculated power > rated output at windspeed " + str(ws)
            vt.assign("error", errmsg)
            hub_power = rated_hub_power

        if hub_power == 0.0:
            powercurve_hub_efficiency[i] = 0
        else:
            powercurve_hub_efficiency[i] = ((hub_power / rated_hub_power) - (a + b * (hub_power / rated_hub_power) + c * pow(hub_power / rated_hub_power, 2))) / (hub_power / rated_hub_power)

        powercurve_powerout[i] = hub_power * powercurve_hub_efficiency[i]
        powercurve_windspeeds[i] = ws

    var windspeeds: var_data = var_data(powercurve_windspeeds.data(), powercurve_windspeeds.ncols())
    var powerout: var_data = var_data(powercurve_powerout.data(), powercurve_powerout.ncols())
    var hub_eff: var_data = var_data(powercurve_hub_efficiency.data(), powercurve_hub_efficiency.ncols())
    vt.assign("wind_turbine_powercurve_windspeeds", windspeeds)
    vt.assign("wind_turbine_powercurve_powerout", powerout)
    vt.assign("rated_wind_speed", rated_wind_speed)
    vt.assign("hub_efficiency", hub_eff)