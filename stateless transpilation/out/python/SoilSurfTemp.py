import sys
import math

# EXTERNAL DEPS (to wire in glue):
# - WDay: list of objects indexed [day_index] with attributes wind_spd, rel_hum, dry_bulb, glob_horz_rad (2D arrays [hour][interval])
# - NumDays: int, total days in data
# - NumIntervalsPerHour: int, intervals per hour
# - NumDataPeriods: int, number of data periods
# - ReadEPW: function(filename: str) -> tuple(errors_found: bool, error_message: str)

A = 103.0
B = 609.0
GROUND_EMIT = 0.95
RAD_CONSTANT = 63.0
BLANK = ' '

def main(WDay, NumDays, NumIntervalsPerHour, NumDataPeriods, ReadEPW):
    numcmdargs = len(sys.argv) - 1
    if numcmdargs == 0:
        input_file_name = 'in.epw'
    else:
        input_file_name = sys.argv[1].strip()
        if input_file_name == BLANK or not input_file_name:
            input_file_name = 'in.epw'
    
    while True:
        print('Select the soil condition surrounding the Earth Tube')
        print('1. HEAVY AND SATURATED')
        print('2. HEAVY AND DAMP')
        print('3. HEAVY AND DRY')
        print('4. LIGHT AND DRY')
        soil_condition = int(input())
        
        if soil_condition == 1:
            soil_therm_diff = 0.0032544
            soil_therm_cond = 2.42
            break
        elif soil_condition == 2:
            soil_therm_diff = 0.002322
            soil_therm_cond = 1.3
            break
        elif soil_condition == 3:
            soil_therm_diff = 0.0018576
            soil_therm_cond = 0.865
            break
        elif soil_condition == 4:
            soil_therm_diff = 0.001008
            soil_therm_cond = 0.346
            break
        else:
            print('Invalid value for the soil condition surrounding the Earth Tube')
    
    while True:
        print('Select the condition of the ground surface above the Earth Tube')
        print('1. BARE AND WET')
        print('2. BARE AND MOIST')
        print('3. BARE AND ARID')
        print('4. BARE AND DRY')
        print('5. COVERED AND WET')
        print('6. COVERED AND MOIST')
        print('7. COVERED AND ARID')
        print('8. COVERED AND DRY')
        ground_surface = int(input())
        
        if ground_surface == 1:
            absorb_coef = 0.9
            evap_frac = 0.7
            break
        elif ground_surface == 2:
            absorb_coef = 0.8
            evap_frac = 0.45
            break
        elif ground_surface == 3:
            absorb_coef = 0.8
            evap_frac = 0.15
            break
        elif ground_surface == 4:
            absorb_coef = 0.7
            evap_frac = 0.0
            break
        elif ground_surface == 5:
            absorb_coef = 0.9
            evap_frac = 0.49
            break
        elif ground_surface == 6:
            absorb_coef = 0.8
            evap_frac = 0.315
            break
        elif ground_surface == 7:
            absorb_coef = 0.8
            evap_frac = 0.105
            break
        elif ground_surface == 8:
            absorb_coef = 0.7
            evap_frac = 0.0
            break
        else:
            print('Invalid value for the condition of the ground surface above the Earth Tube')
    
    errors_found, error_message = ReadEPW(input_file_name)
    if errors_found:
        with open('CalcSoilSurfTemp.out', 'w') as f:
            f.write(f' Weather file used={input_file_name}\n')
            f.write(f'Errors occured in reading weather file={error_message}\n')
        sys.exit(1)
    
    if NumDataPeriods > 1:
        with open('CalcSoilSurfTemp.out', 'w') as f:
            f.write(f' Weather file used={input_file_name}\n')
            f.write('Number of Data Periods on Weather File not = 1.\n')
        sys.exit(1)
    
    daily_wind_vel = [0.0] * NumDays
    for jul_day in range(NumDays):
        w = 0.0
        for hh in range(24):
            for interval in range(NumIntervalsPerHour):
                w += WDay[jul_day].wind_spd[hh][interval]
        daily_wind_vel[jul_day] = w / 24.0 / NumIntervalsPerHour
    
    r = 0.0
    for jul_day in range(NumDays):
        r += daily_wind_vel[jul_day]
    mean_wind_vel = r / NumDays
    
    daily_relat_hum = [0.0] * NumDays
    for jul_day in range(NumDays):
        w = 0.0
        for hh in range(24):
            for interval in range(NumIntervalsPerHour):
                w += WDay[jul_day].rel_hum[hh][interval]
        daily_relat_hum[jul_day] = w / 24.0 / NumIntervalsPerHour
    
    r = 0.0
    for jul_day in range(NumDays):
        r += daily_relat_hum[jul_day]
    mean_relat_hum = r / NumDays
    
    soil_heat_tran_coef = 3.8 * mean_wind_vel + 5.7
    he = (0.0168 * A * evap_frac + 1.0) * soil_heat_tran_coef
    hr = (0.0168 * A * evap_frac * mean_relat_hum / 100.0 + 1.0) * soil_heat_tran_coef
    
    angular_freq = 2.0 * math.pi / (NumDays * 24.0)
    damp_depth = math.sqrt(2.0 * soil_therm_diff / angular_freq)
    
    daily_air_temp = [0.0] * NumDays
    for jul_day in range(NumDays):
        s = 0.0
        for hh in range(24):
            for interval in range(NumIntervalsPerHour):
                s += WDay[jul_day].dry_bulb[hh][interval]
        daily_air_temp[jul_day] = s / 24.0 / NumIntervalsPerHour
    
    g = 0.0
    for jul_day in range(NumDays):
        g += daily_air_temp[jul_day]
    mean_air_temp = g / NumDays
    
    max_air_temp = daily_air_temp[0]
    for i in range(1, NumDays):
        if daily_air_temp[i] > max_air_temp:
            max_air_temp = daily_air_temp[i]
    
    min_air_temp = daily_air_temp[0]
    phase_con_air_temp = 1
    for j in range(2, NumDays + 1):
        if daily_air_temp[j - 1] < min_air_temp:
            min_air_temp = daily_air_temp[j - 1]
            phase_con_air_temp = j
    
    ampl_air_temp = (max_air_temp - min_air_temp) / 2.0
    
    daily_solar_rad = [0.0] * NumDays
    for jul_day in range(NumDays):
        s = 0.0
        for hh in range(24):
            for interval in range(NumIntervalsPerHour):
                s += WDay[jul_day].glob_horz_rad[hh][interval]
        daily_solar_rad[jul_day] = s / 24.0 / NumIntervalsPerHour
    
    g = 0.0
    for jul_day in range(NumDays):
        g += daily_solar_rad[jul_day]
    mean_solar_rad = g / NumDays
    
    max_solar_rad = daily_solar_rad[0]
    for i in range(1, NumDays):
        if daily_solar_rad[i] > max_solar_rad:
            max_solar_rad = daily_solar_rad[i]
    
    min_solar_rad = daily_solar_rad[0]
    phase_con_solar_rad = 1
    for j in range(2, NumDays + 1):
        if daily_solar_rad[j - 1] < min_solar_rad:
            min_solar_rad = daily_solar_rad[j - 1]
            phase_con_solar_rad = j
    
    ampl_solar_rad = (max_solar_rad - min_solar_rad) / 2.0
    
    phase_angle = (phase_con_air_temp - phase_con_solar_rad) * 2.0 * math.pi / NumDays
    
    aver_soil_sur_temp = (hr * mean_air_temp - GROUND_EMIT * RAD_CONSTANT + 
                          absorb_coef * mean_solar_rad - 
                          0.0168 * soil_heat_tran_coef * evap_frac * B * (1.0 - mean_relat_hum / 100.0)) / he
    
    process1 = he + soil_therm_cond / damp_depth
    process2 = soil_therm_cond / damp_depth
    process3 = hr * ampl_air_temp
    process4 = absorb_coef * ampl_solar_rad * math.cos(phase_angle)
    process5 = absorb_coef * ampl_solar_rad * math.sin(phase_angle)
    real_part = (process1 * (process3 - process4) + process2 * (-process5)) / (process1**2 + process2**2)
    imag_part = (process1 * (-process5) - process2 * (process3 - process4)) / (process1**2 + process2**2)
    ampl_soil_sur_temp = math.sqrt(real_part**2 + imag_part**2)
    phase_angle_air_soil = -math.atan(imag_part / real_part)
    
    j = phase_con_air_temp + int(phase_angle_air_soil / angular_freq / 24.0) + 1
    
    if j <= 0:
        i = 1
    else:
        i = j
    
    if i > 365:
        soil_sur_phase_const = i - 365
    else:
        soil_sur_phase_const = i
    
    print()
    print()
    print('Annual Average Soil Surface Temperature', aver_soil_sur_temp)
    print('Amplitude of Soil Surface Temperature', ampl_soil_sur_temp)
    print('Phase Constant of Soil Surface Temperature', soil_sur_phase_const)
    print('Output can also be found in CalcSoilSurfTemp.out file')
    
    with open('CalcSoilSurfTemp.out', 'w') as f:
        f.write(f' Weather file used={input_file_name}\n')
        f.write(f'Annual Average Soil Surface Temperature {aver_soil_sur_temp:18.12f}\n')
        f.write(f'Amplitude of Soil Surface Temperature {ampl_soil_sur_temp:18.12f}\n')
        f.write(f'Phase Constant of Soil Surface Temperature {soil_sur_phase_const:3d}\n')
