from math import pi, sqrt, cos, sin, atan
import sys

# EXTERNAL DEPS (to wire in glue):
# - WDayData: struct with wind_spd, rel_hum, dry_bulb, glob_horz_rad (2D arrays [hour][interval])
# - WDay: List[WDayData] indexed [day_index]
# - NumDays: int, total days in data
# - NumIntervalsPerHour: int, intervals per hour
# - NumDataPeriods: int, number of data periods
# - ReadEPW: fn(filename: String) -> (bool, String) returns (errors_found, error_message)

alias A = 103.0
alias B = 609.0
alias GROUND_EMIT = 0.95
alias RAD_CONSTANT = 63.0
alias BLANK = " "

struct WDayData:
    var wind_spd: List[List[Float32]]
    var rel_hum: List[List[Float32]]
    var dry_bulb: List[List[Float32]]
    var glob_horz_rad: List[List[Float32]]

fn main(WDay: List[WDayData], NumDays: Int, NumIntervalsPerHour: Int, NumDataPeriods: Int, ReadEPW: fn(String) -> (Bool, String)):
    var numcmdargs = len(sys.argv()) - 1
    var input_file_name: String
    
    if numcmdargs == 0:
        input_file_name = "in.epw"
    else:
        input_file_name = sys.argv()[1]
        var trimmed = input_file_name.strip()
        if trimmed == BLANK or trimmed == "":
            input_file_name = "in.epw"
        else:
            input_file_name = trimmed
    
    var soil_therm_diff: Float32
    var soil_therm_cond: Float32
    var ground_surface: Int
    var absorb_coef: Float32
    var evap_frac: Float32
    
    var soil_loop = True
    while soil_loop:
        print("Select the soil condition surrounding the Earth Tube")
        print("1. HEAVY AND SATURATED")
        print("2. HEAVY AND DAMP")
        print("3. HEAVY AND DRY")
        print("4. LIGHT AND DRY")
        var soil_condition = int(input())
        
        if soil_condition == 1:
            soil_therm_diff = 0.0032544
            soil_therm_cond = 2.42
            soil_loop = False
        elif soil_condition == 2:
            soil_therm_diff = 0.002322
            soil_therm_cond = 1.3
            soil_loop = False
        elif soil_condition == 3:
            soil_therm_diff = 0.0018576
            soil_therm_cond = 0.865
            soil_loop = False
        elif soil_condition == 4:
            soil_therm_diff = 0.001008
            soil_therm_cond = 0.346
            soil_loop = False
        else:
            print("Invalid value for the soil condition surrounding the Earth Tube")
    
    var ground_loop = True
    while ground_loop:
        print("Select the condition of the ground surface above the Earth Tube")
        print("1. BARE AND WET")
        print("2. BARE AND MOIST")
        print("3. BARE AND ARID")
        print("4. BARE AND DRY")
        print("5. COVERED AND WET")
        print("6. COVERED AND MOIST")
        print("7. COVERED AND ARID")
        print("8. COVERED AND DRY")
        ground_surface = int(input())
        
        if ground_surface == 1:
            absorb_coef = 0.9
            evap_frac = 0.7
            ground_loop = False
        elif ground_surface == 2:
            absorb_coef = 0.8
            evap_frac = 0.45
            ground_loop = False
        elif ground_surface == 3:
            absorb_coef = 0.8
            evap_frac = 0.15
            ground_loop = False
        elif ground_surface == 4:
            absorb_coef = 0.7
            evap_frac = 0.0
            ground_loop = False
        elif ground_surface == 5:
            absorb_coef = 0.9
            evap_frac = 0.49
            ground_loop = False
        elif ground_surface == 6:
            absorb_coef = 0.8
            evap_frac = 0.315
            ground_loop = False
        elif ground_surface == 7:
            absorb_coef = 0.8
            evap_frac = 0.105
            ground_loop = False
        elif ground_surface == 8:
            absorb_coef = 0.7
            evap_frac = 0.0
            ground_loop = False
        else:
            print("Invalid value for the condition of the ground surface above the Earth Tube")
    
    var errors_found: Bool
    var error_message: String
    errors_found, error_message = ReadEPW(input_file_name)
    
    if errors_found:
        var f = open("CalcSoilSurfTemp.out", "w")
        f.write(" Weather file used=" + input_file_name + "\n")
        f.write("Errors occured in reading weather file=" + error_message + "\n")
        f.close()
        return
    
    if NumDataPeriods > 1:
        var f = open("CalcSoilSurfTemp.out", "w")
        f.write(" Weather file used=" + input_file_name + "\n")
        f.write("Number of Data Periods on Weather File not = 1.\n")
        f.close()
        return
    
    var daily_wind_vel = List[Float32](capacity=NumDays)
    for j in range(NumDays):
        daily_wind_vel.append(0.0)
    
    for jul_day in range(NumDays):
        var w: Float32 = 0.0
        for hh in range(24):
            for interval in range(NumIntervalsPerHour):
                w += WDay[jul_day].wind_spd[hh][interval]
        daily_wind_vel[jul_day] = w / 24.0 / Float32(NumIntervalsPerHour)
    
    var r: Float32 = 0.0
    for jul_day in range(NumDays):
        r += daily_wind_vel[jul_day]
    var mean_wind_vel = r / Float32(NumDays)
    
    var daily_relat_hum = List[Float32](capacity=NumDays)
    for j in range(NumDays):
        daily_relat_hum.append(0.0)
    
    for jul_day in range(NumDays):
        var w: Float32 = 0.0
        for hh in range(24):
            for interval in range(NumIntervalsPerHour):
                w += WDay[jul_day].rel_hum[hh][interval]
        daily_relat_hum[jul_day] = w / 24.0 / Float32(NumIntervalsPerHour)
    
    r = 0.0
    for jul_day in range(NumDays):
        r += daily_relat_hum[jul_day]
    var mean_relat_hum = r / Float32(NumDays)
    
    var soil_heat_tran_coef = 3.8 * mean_wind_vel + 5.7
    var he = (0.0168 * A * evap_frac + 1.0) * soil_heat_tran_coef
    var hr = (0.0168 * A * evap_frac * mean_relat_hum / 100.0 + 1.0) * soil_heat_tran_coef
    
    var angular_freq = 2.0 * pi / Float32(NumDays * 24)
    var damp_depth = sqrt(2.0 * soil_therm_diff / angular_freq)
    
    var daily_air_temp = List[Float32](capacity=NumDays)
    for j in range(NumDays):
        daily_air_temp.append(0.0)
    
    for jul_day in range(NumDays):
        var s: Float32 = 0.0
        for hh in range(24):
            for interval in range(NumIntervalsPerHour):
                s += WDay[jul_day].dry_bulb[hh][interval]
        daily_air_temp[jul_day] = s / 24.0 / Float32(NumIntervalsPerHour)
    
    var g: Float32 = 0.0
    for jul_day in range(NumDays):
        g += daily_air_temp[jul_day]
    var mean_air_temp = g / Float32(NumDays)
    
    var max_air_temp = daily_air_temp[0]
    for i in range(1, NumDays):
        if daily_air_temp[i] > max_air_temp:
            max_air_temp = daily_air_temp[i]
    
    var min_air_temp = daily_air_temp[0]
    var phase_con_air_temp = 1
    for j in range(2, NumDays + 1):
        if daily_air_temp[j - 1] < min_air_temp:
            min_air_temp = daily_air_temp[j - 1]
            phase_con_air_temp = j
    
    var ampl_air_temp = (max_air_temp - min_air_temp) / 2.0
    
    var daily_solar_rad = List[Float32](capacity=NumDays)
    for j in range(NumDays):
        daily_solar_rad.append(0.0)
    
    for jul_day in range(NumDays):
        var s: Float32 = 0.0
        for hh in range(24):
            for interval in range(NumIntervalsPerHour):
                s += WDay[jul_day].glob_horz_rad[hh][interval]
        daily_solar_rad[jul_day] = s / 24.0 / Float32(NumIntervalsPerHour)
    
    g = 0.0
    for jul_day in range(NumDays):
        g += daily_solar_rad[jul_day]
    var mean_solar_rad = g / Float32(NumDays)
    
    var max_solar_rad = daily_solar_rad[0]
    for i in range(1, NumDays):
        if daily_solar_rad[i] > max_solar_rad:
            max_solar_rad = daily_solar_rad[i]
    
    var min_solar_rad = daily_solar_rad[0]
    var phase_con_solar_rad = 1
    for j in range(2, NumDays + 1):
        if daily_solar_rad[j - 1] < min_solar_rad:
            min_solar_rad = daily_solar_rad[j - 1]
            phase_con_solar_rad = j
    
    var ampl_solar_rad = (max_solar_rad - min_solar_rad) / 2.0
    
    var phase_angle = Float32(phase_con_air_temp - phase_con_solar_rad) * 2.0 * pi / Float32(NumDays)
    
    var aver_soil_sur_temp = (hr * mean_air_temp - GROUND_EMIT * RAD_CONSTANT + 
                              absorb_coef * mean_solar_rad - 
                              0.0168 * soil_heat_tran_coef * evap_frac * B * (1.0 - mean_relat_hum / 100.0)) / he
    
    var process1 = he + soil_therm_cond / damp_depth
    var process2 = soil_therm_cond / damp_depth
    var process3 = hr * ampl_air_temp
    var process4 = absorb_coef * ampl_solar_rad * cos(phase_angle)
    var process5 = absorb_coef * ampl_solar_rad * sin(phase_angle)
    var real_part = (process1 * (process3 - process4) + process2 * (-process5)) / (process1**2 + process2**2)
    var imag_part = (process1 * (-process5) - process2 * (process3 - process4)) / (process1**2 + process2**2)
    var ampl_soil_sur_temp = sqrt(real_part**2 + imag_part**2)
    var phase_angle_air_soil = -atan(imag_part / real_part)
    
    var j_val = phase_con_air_temp + Int(phase_angle_air_soil / angular_freq / 24.0) + 1
    
    var i_val: Int
    if j_val <= 0:
        i_val = 1
    else:
        i_val = j_val
    
    var soil_sur_phase_const: Int
    if i_val > 365:
        soil_sur_phase_const = i_val - 365
    else:
        soil_sur_phase_const = i_val
    
    print()
    print()
    print("Annual Average Soil Surface Temperature", aver_soil_sur_temp)
    print("Amplitude of Soil Surface Temperature", ampl_soil_sur_temp)
    print("Phase Constant of Soil Surface Temperature", soil_sur_phase_const)
    print("Output can also be found in CalcSoilSurfTemp.out file")
    
    var f = open("CalcSoilSurfTemp.out", "w")
    f.write(" Weather file used=" + input_file_name + "\n")
    f.write("Annual Average Soil Surface Temperature " + str(aver_soil_sur_temp) + "\n")
    f.write("Amplitude of Soil Surface Temperature " + str(ampl_soil_sur_temp) + "\n")
    f.write("Phase Constant of Soil Surface Temperature " + str(soil_sur_phase_const) + "\n")
    f.close()
