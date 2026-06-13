from math import exp, log
from collections import Dict

# EXTERNAL DEPS (to wire in glue):
# - state: Combined state object holding:
#   - total_warning_errors, total_severe_errors, total_errors (from DataStringGlobals)
#   - progname, file_name_path, file_ok, ver_string (from DataStringGlobals)
#   - upper_case, lower_case (from DataStringGlobals)
#   - echo_input_file (from InputProcessor)
#   - fatal_error (mutable flag)
#   - show_error_message_unit (SAVE variable for ShowErrorMessage)
#   - open_units (file unit tracking)

struct FileUnitManager:
    var open_units: Dict[Int, Int]
    
    fn __init__(inout self):
        self.open_units = Dict[Int, Int]()
    
    fn inquire_unit(self, unit: Int) -> Tuple[Bool, Bool, Int]:
        let exists = True
        let opened = unit in self.open_units
        let ios = 0
        return (exists, opened, ios)
    
    fn open_unit(inout self, unit: Int, filename: String, position: String = "ASIS"):
        pass
    
    fn close_unit(inout self, unit: Int):
        if unit in self.open_units:
            self.open_units.pop(unit)
    
    fn write_to_unit(self, unit: Int, message: String):
        if unit == 6:
            print(message)

struct TransitionState:
    var total_warning_errors: Int
    var total_severe_errors: Int
    var total_errors: Int
    var progname: String
    var file_name_path: String
    var file_ok: Bool
    var ver_string: String
    var upper_case: String
    var lower_case: String
    var echo_input_file: Int
    var fatal_error: Bool
    var show_error_message_unit: Int
    var file_unit_manager: FileUnitManager
    
    fn __init__(inout self):
        self.total_warning_errors = 0
        self.total_severe_errors = 0
        self.total_errors = 0
        self.progname = "EnergyPlus"
        self.file_name_path = ""
        self.file_ok = False
        self.ver_string = ""
        self.upper_case = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        self.lower_case = "abcdefghijklmnopqrstuvwxyz"
        self.echo_input_file = 0
        self.fatal_error = False
        self.show_error_message_unit = -1
        self.file_unit_manager = FileUnitManager()

fn trim_right(s: String) -> String:
    let trimmed = s.rstrip()
    return trimmed

fn lstrip_str(s: String) -> String:
    return s.lstrip()

fn abort_energyplus(inout state: TransitionState) -> None:
    let num_warnings = str(state.total_warning_errors).lstrip()
    let num_severe = str(state.total_severe_errors).lstrip()
    
    show_message(state, 
                 state.progname.rstrip() + " Terminated--Fatal Error Detected. " + 
                 num_warnings.rstrip() + " Warning; " + 
                 num_severe.rstrip() + " Severe Errors")
    print("Error messages saved on " + state.file_name_path.rstrip() + ".VCperr")
    state.fatal_error = True

fn close_misc_open_files(inout state: TransitionState) -> None:
    let max_unit_number = 1000
    for unit_number in range(1, max_unit_number + 1):
        let (exists, opened, ios) = state.file_unit_manager.inquire_unit(unit_number)
        if exists and opened and ios == 0:
            state.file_unit_manager.close_unit(unit_number)

fn close_out(inout state: TransitionState) -> None:
    let num_warnings = str(state.total_warning_errors).lstrip()
    let num_severe = str(state.total_severe_errors).lstrip()
    
    show_message(state,
                 state.progname.rstrip() + " Completed Successfully-- " + 
                 num_warnings.rstrip() + " Warning; " + 
                 num_severe.rstrip() + " Severe Errors")
    
    if state.echo_input_file > 0:
        state.file_unit_manager.close_unit(state.echo_input_file)
    
    state.total_warning_errors = 0
    state.total_severe_errors = 0
    state.total_errors = 0

fn end_energyplus(inout state: TransitionState) -> None:
    let num_warnings = str(state.total_warning_errors).lstrip()
    let num_severe = str(state.total_severe_errors).lstrip()
    
    show_message(state,
                 state.progname.rstrip() + " Completed Successfully-- " + 
                 num_warnings.rstrip() + " Warning; " + 
                 num_severe.rstrip() + " Severe Errors")
    
    if state.echo_input_file > 0:
        state.file_unit_manager.close_unit(state.echo_input_file)
    
    close_misc_open_files(state)

fn get_new_unit_number(inout state: TransitionState) -> Int:
    let default_input_unit = 5
    let default_output_unit = 6
    let preconnected_units = (5, 6)
    let max_unit_number = 1000
    
    for unit_number in range(1, max_unit_number + 1):
        if unit_number == default_input_unit or unit_number == default_output_unit:
            continue
        if unit_number == 5 or unit_number == 6:
            continue
        
        let (exists, opened, ios) = state.file_unit_manager.inquire_unit(unit_number)
        if exists and not opened and ios == 0:
            return unit_number
    
    return -1

fn find_unit_number(inout state: TransitionState, file_name: String) -> Int:
    let max_unit_number = 1000
    
    let (exists_file, opened, ios) = state.file_unit_manager.inquire_unit(-1)
    
    var unit_number = 0
    if not opened:
        unit_number = get_new_unit_number(state)
        state.file_unit_manager.open_unit(unit_number, file_name, position="APPEND")
    else:
        let file_name_length = len(file_name.rstrip())
        unit_number = -1
        for un in range(1, max_unit_number + 1):
            let (exists, opened_un, _) = state.file_unit_manager.inquire_unit(un)
            let test_file_name = ""
            let test_file_length = len(test_file_name.rstrip())
            let pos = test_file_name.find(file_name)
            if pos >= 0:
                if pos + file_name_length == test_file_length:
                    unit_number = un
                    break
    
    return unit_number

fn convert_case_to_upper(inout state: TransitionState, input_string: String) -> String:
    var output_string = input_string
    let trimmed_len = len(input_string.rstrip())
    
    for a in range(trimmed_len):
        let b = state.lower_case.find(input_string[a])
        if b >= 0:
            output_string[a] = state.upper_case[b]
        else:
            output_string[a] = input_string[a]
    
    return output_string.rstrip()

fn convert_case_to_lower(inout state: TransitionState, input_string: String) -> String:
    var output_string = input_string
    let trimmed_len = len(input_string.rstrip())
    
    for a in range(trimmed_len):
        let b = state.upper_case.find(input_string[a])
        if b >= 0:
            output_string[a] = state.lower_case[b]
        else:
            output_string[a] = input_string[a]
    
    return output_string.rstrip()

fn find_non_space(input_string: String) -> Int:
    var find_non_space_result = 0
    let ilen = len(input_string.rstrip())
    for i in range(ilen):
        if input_string[i] != " ":
            find_non_space_result = i + 1
            break
    return find_non_space_result

fn show_fatal_error(inout state: TransitionState, error_message: String, 
                    out_unit1: Int = -1, out_unit2: Int = -1) -> None:
    show_error_message(state, " **  Fatal  ** " + error_message, out_unit1, out_unit2)
    abort_energyplus(state)

fn show_severe_error(inout state: TransitionState, error_message: String,
                     out_unit1: Int = -1, out_unit2: Int = -1) -> None:
    state.total_severe_errors += 1
    show_error_message(state, " ** Severe  ** " + error_message, out_unit1, out_unit2)

fn show_continue_error(inout state: TransitionState, message: String,
                       out_unit1: Int = -1, out_unit2: Int = -1) -> None:
    show_error_message(state, " **   ~~~   ** " + message, out_unit1, out_unit2)

fn show_message(inout state: TransitionState, message: String,
                out_unit1: Int = -1, out_unit2: Int = -1) -> None:
    show_error_message(state, " ************* " + message, out_unit1, out_unit2)

fn show_warning_error(inout state: TransitionState, error_message: String,
                      out_unit1: Int = -1, out_unit2: Int = -1) -> None:
    state.total_warning_errors += 1
    show_error_message(state, " ** Warning ** " + error_message, out_unit1, out_unit2)

fn show_error_message(inout state: TransitionState, error_message: String,
                      out_unit1: Int = -1, out_unit2: Int = -1) -> None:
    let done = error_message.find("Completed Successfully")
    if state.total_errors == 0 and done < 0:
        state.show_error_message_unit = get_new_unit_number(state)
        if state.file_ok:
            state.file_unit_manager.open_unit(
                state.show_error_message_unit,
                state.file_name_path.rstrip() + ".VCpErr")
        else:
            state.file_unit_manager.open_unit(
                state.show_error_message_unit,
                "eplusout.err")
        state.file_unit_manager.write_to_unit(
            state.show_error_message_unit,
            "Program Version," + state.ver_string.rstrip())
    
    if done < 0 or (done >= 0 and state.total_errors > 0):
        state.total_errors += 1
        state.file_unit_manager.write_to_unit(
            state.show_error_message_unit,
            error_message.rstrip())
        print(error_message.rstrip())
        if done >= 0:
            print("Error messages saved on " + state.file_name_path.rstrip() + ".VCperr")
            state.file_unit_manager.close_unit(state.show_error_message_unit)
        if out_unit1 >= 0:
            state.file_unit_manager.write_to_unit(out_unit1, error_message.rstrip())
        if out_unit2 >= 0:
            state.file_unit_manager.write_to_unit(out_unit2, error_message.rstrip())

fn get_sat_vap_press_from_dry_bulb(tdb: Float64) -> Float64:
    let c1 = -5674.5359
    let c2 = 6.3925247
    let c3 = -0.009677843
    let c4 = 0.00000062215701
    let c5 = 2.0747825e-09
    let c6 = -9.484024e-13
    let c7 = 4.1635019
    let c8 = -5800.2206
    let c9 = 1.3914993
    let c10 = -0.048640239
    let c11 = 0.000041764768
    let c12 = -0.000000014452093
    let c13 = 6.5459673
    
    let tk = tdb + 273.15
    var retval: Float64 = 0.0
    
    if tk <= 273.15:
        retval = exp(c1/tk + c2 + c3*tk + c4*tk**2 + c5*tk**3 + 
                     c6*tk**4 + c7*log(tk)) / 1000.0
    else:
        retval = exp(c8/tk + c9 + c10*tk + c11*tk**2 + c12*tk**3 + 
                     c13*log(tk)) / 1000.0
    
    return retval

fn calculate_mu_empd(a: Float64, b: Float64, c: Float64, d: Float64, 
                     d_empd: Float64, density_matl: Float64) -> Float64:
    let t = 24
    let rh = 0.45
    let p_ambient = 101325
    let t_p = 24 * 60 * 60
    
    let slope_mc = a * b * (rh ** (b - 1)) + c * d * (rh ** (d - 1))
    let pv_sat = get_sat_vap_press_from_dry_bulb(Float64(t)) * 1000.0
    let diffusivity_empd = (d_empd ** 2 * 3.1415926535 * slope_mc * density_matl / 
                           (Float64(t_p) * pv_sat))
    let diffusivity_air = 2.0e-7 * ((Float64(t) + 273.15) ** 0.81) / Float64(p_ambient)
    
    let mu_empd = diffusivity_air / diffusivity_empd
    return mu_empd

fn get_year_from_start_day_string(s_day: String) -> Int:
    if (s_day[0:2] == "SU" or s_day[0:2] == "Su" or 
        s_day[0:2] == "sU" or s_day[0:2] == "su"):
        return 2017
    elif s_day[0:1] == "M" or s_day[0:1] == "m":
        return 2007
    elif (s_day[0:2] == "TU" or s_day[0:2] == "Tu" or 
          s_day[0:2] == "tU" or s_day[0:2] == "tu"):
        return 2013
    elif s_day[0:1] == "W" or s_day[0:1] == "w":
        return 2014
    elif (s_day[0:2] == "TH" or s_day[0:2] == "Th" or 
          s_day[0:2] == "tH" or s_day[0:2] == "th"):
        return 2015
    elif s_day[0:1] == "F" or s_day[0:1] == "f":
        return 2010
    elif (s_day[0:2] == "SA" or s_day[0:2] == "Sa" or 
          s_day[0:2] == "sA" or s_day[0:2] == "sa"):
        return 2011
    else:
        return 2018

fn get_leap_year_from_start_day_string(s_day: String) -> Int:
    if (s_day[0:2] == "SU" or s_day[0:2] == "Su" or 
        s_day[0:2] == "sU" or s_day[0:2] == "su"):
        return 2012
    elif s_day[0:1] == "M" or s_day[0:1] == "m":
        return 1996
    elif (s_day[0:2] == "TU" or s_day[0:2] == "Tu" or 
          s_day[0:2] == "tU" or s_day[0:2] == "tu"):
        return 2008
    elif s_day[0:1] == "W" or s_day[0:1] == "w":
        return 1992
    elif (s_day[0:2] == "TH" or s_day[0:2] == "Th" or 
          s_day[0:2] == "tH" or s_day[0:2] == "th"):
        return 2004
    elif s_day[0:1] == "F" or s_day[0:1] == "f":
        return 2016
    elif (s_day[0:2] == "SA" or s_day[0:2] == "Sa" or 
          s_day[0:2] == "sA" or s_day[0:2] == "sa"):
        return 2000
    else:
        return 2016

fn get_weekday_num_from_string(s_day: String) -> Int:
    if (s_day[0:2] == "SU" or s_day[0:2] == "Su" or 
        s_day[0:2] == "sU" or s_day[0:2] == "su"):
        return 1
    elif s_day[0:1] == "M" or s_day[0:1] == "m":
        return 2
    elif (s_day[0:2] == "TU" or s_day[0:2] == "Tu" or 
          s_day[0:2] == "tU" or s_day[0:2] == "tu"):
        return 3
    elif s_day[0:1] == "W" or s_day[0:1] == "w":
        return 4
    elif (s_day[0:2] == "TH" or s_day[0:2] == "Th" or 
          s_day[0:2] == "tH" or s_day[0:2] == "th"):
        return 5
    elif s_day[0:1] == "F" or s_day[0:1] == "f":
        return 6
    elif (s_day[0:2] == "SA" or s_day[0:2] == "Sa" or 
          s_day[0:2] == "sA" or s_day[0:2] == "sa"):
        return 7
    return 0

fn calculate_day_of_year(i_month: Int, i_day: Int, leap_year: Bool) -> Int:
    let days_before = InlineArray[Int, 12](0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334)
    let days_before_leap = InlineArray[Int, 12](0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335)
    
    var day: Int = 0
    if leap_year:
        day = days_before_leap[i_month - 1] + i_day
    else:
        day = days_before[i_month - 1] + i_day
    
    return day

fn find_year_for_week_day(i_month: Int, i_day: Int, c_weekday: String) -> Int:
    let default_year = InlineArray[Int, 13](2013, 2014, 2015, 2010, 2011, 2017, 2007, 
                                           2013, 2014, 2015, 2010, 2011, 2017)
    let default_leap_year = InlineArray[Int, 13](2008, 1992, 2004, 2016, 2000, 2012, 1996, 
                                                2008, 1992, 2004, 2016, 2000, 2012)
    
    var leap_year = False
    if i_month == 2 and i_day == 29:
        leap_year = True
    
    let i_weekday = get_weekday_num_from_string(c_weekday)
    let ordinal = calculate_day_of_year(i_month, i_day, leap_year)
    let rem = ordinal % 7
    
    var year: Int = 0
    if leap_year:
        year = default_leap_year[i_weekday - rem + 5]
    else:
        year = default_year[i_weekday - rem + 5]
    
    return year

fn is_year_number_a_leap_year(year_number: Int) -> Bool:
    if (Float64(year_number) / 4.0) == Float64(Int(Float64(year_number) / 4.0)):
        if (Float64(year_number) / 1000.0) == Float64(Int(Float64(year_number) / 1000.0)):
            return True
    return False
