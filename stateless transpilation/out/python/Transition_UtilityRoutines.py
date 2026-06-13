import math
import os
from dataclasses import dataclass
from typing import Optional

# EXTERNAL DEPS (to wire in glue):
# - state: Combined state object holding:
#   - total_warning_errors, total_severe_errors, total_errors (from DataStringGlobals)
#   - progname, file_name_path, file_ok, ver_string (from DataStringGlobals)
#   - upper_case, lower_case (from DataStringGlobals)
#   - echo_input_file (from InputProcessor)
#   - fatal_error (mutable flag)
#   - show_error_message_unit (SAVE variable for ShowErrorMessage)
#   - open_units (file unit tracking)

@dataclass
class FileUnitManager:
    open_units: dict = None
    
    def __post_init__(self):
        if self.open_units is None:
            self.open_units = {}
    
    def inquire_unit(self, unit: int) -> tuple:
        exists = True
        opened = unit in self.open_units
        ios = 0
        return exists, opened, ios
    
    def open_unit(self, unit: int, filename: str, position: str = 'ASIS'):
        try:
            mode = 'a' if position == 'APPEND' else 'w'
            self.open_units[unit] = open(filename, mode)
        except:
            pass
    
    def close_unit(self, unit: int):
        if unit in self.open_units:
            try:
                self.open_units[unit].close()
            except:
                pass
            del self.open_units[unit]
    
    def write_to_unit(self, unit: int, message: str):
        if unit in self.open_units:
            self.open_units[unit].write(message + '\n')
        elif unit == 6:
            print(message)

@dataclass
class TransitionState:
    total_warning_errors: int = 0
    total_severe_errors: int = 0
    total_errors: int = 0
    progname: str = "EnergyPlus"
    file_name_path: str = ""
    file_ok: bool = False
    ver_string: str = ""
    upper_case: str = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    lower_case: str = "abcdefghijklmnopqrstuvwxyz"
    echo_input_file: int = 0
    fatal_error: bool = False
    show_error_message_unit: int = -1
    file_unit_manager: FileUnitManager = None
    
    def __post_init__(self):
        if self.file_unit_manager is None:
            self.file_unit_manager = FileUnitManager()


def abort_energyplus(state: TransitionState) -> None:
    num_warnings = str(state.total_warning_errors).lstrip()
    num_severe = str(state.total_severe_errors).lstrip()
    
    show_message(state, 
                 state.progname.rstrip() + ' Terminated--Fatal Error Detected. ' + 
                 num_warnings.rstrip() + ' Warning; ' + 
                 num_severe.rstrip() + ' Severe Errors')
    print('Error messages saved on ' + state.file_name_path.rstrip() + '.VCperr')
    state.fatal_error = True


def close_misc_open_files(state: TransitionState) -> None:
    max_unit_number = 1000
    for unit_number in range(1, max_unit_number + 1):
        exists, opened, ios = state.file_unit_manager.inquire_unit(unit_number)
        if exists and opened and ios == 0:
            state.file_unit_manager.close_unit(unit_number)


def close_out(state: TransitionState) -> None:
    num_warnings = str(state.total_warning_errors).lstrip()
    num_severe = str(state.total_severe_errors).lstrip()
    
    show_message(state,
                 state.progname.rstrip() + ' Completed Successfully-- ' + 
                 num_warnings.rstrip() + ' Warning; ' + 
                 num_severe.rstrip() + ' Severe Errors')
    
    if state.echo_input_file > 0:
        state.file_unit_manager.close_unit(state.echo_input_file)
    
    state.total_warning_errors = 0
    state.total_severe_errors = 0
    state.total_errors = 0


def end_energyplus(state: TransitionState) -> None:
    num_warnings = str(state.total_warning_errors).lstrip()
    num_severe = str(state.total_severe_errors).lstrip()
    
    show_message(state,
                 state.progname.rstrip() + ' Completed Successfully-- ' + 
                 num_warnings.rstrip() + ' Warning; ' + 
                 num_severe.rstrip() + ' Severe Errors')
    
    if state.echo_input_file > 0:
        state.file_unit_manager.close_unit(state.echo_input_file)
    
    close_misc_open_files(state)


def get_new_unit_number(state: TransitionState) -> int:
    end_of_record = -2
    end_of_file = -1
    default_input_unit = 5
    default_output_unit = 6
    number_of_preconnected_units = 2
    preconnected_units = (5, 6)
    max_unit_number = 1000
    
    for unit_number in range(1, max_unit_number + 1):
        if unit_number == default_input_unit or unit_number == default_output_unit:
            continue
        if unit_number in preconnected_units:
            continue
        
        exists, opened, ios = state.file_unit_manager.inquire_unit(unit_number)
        if exists and not opened and ios == 0:
            return unit_number
    
    return -1


def find_unit_number(state: TransitionState, file_name: str) -> int:
    max_unit_number = 1000
    
    exists_file, opened, ios = state.file_unit_manager.inquire_unit(-1)
    
    if not opened:
        unit_number = get_new_unit_number(state)
        state.file_unit_manager.open_unit(unit_number, file_name, position='APPEND')
    else:
        file_name_length = len(file_name.rstrip())
        unit_number = -1
        for un in range(1, max_unit_number + 1):
            exists, opened_un, _ = state.file_unit_manager.inquire_unit(un)
            test_file_name = ""
            
            test_file_length = len(test_file_name.rstrip())
            pos = test_file_name.find(file_name)
            if pos >= 0:
                if pos + file_name_length == test_file_length:
                    unit_number = un
                    break
    
    return unit_number


def convert_case_to_upper(state: TransitionState, input_string: str) -> str:
    output_string = list(input_string)
    
    for a in range(len(input_string.rstrip())):
        b = state.lower_case.find(input_string[a])
        if b >= 0:
            output_string[a] = state.upper_case[b]
        else:
            output_string[a] = input_string[a]
    
    return ''.join(output_string).rstrip()


def convert_case_to_lower(state: TransitionState, input_string: str) -> str:
    output_string = list(input_string)
    
    for a in range(len(input_string.rstrip())):
        b = state.upper_case.find(input_string[a])
        if b >= 0:
            output_string[a] = state.lower_case[b]
        else:
            output_string[a] = input_string[a]
    
    return ''.join(output_string).rstrip()


def find_non_space(input_string: str) -> int:
    find_non_space_result = 0
    ilen = len(input_string.rstrip())
    for i in range(ilen):
        if input_string[i] != ' ':
            find_non_space_result = i + 1
            break
    return find_non_space_result


def show_fatal_error(state: TransitionState, error_message: str, 
                     out_unit1: Optional[int] = None, 
                     out_unit2: Optional[int] = None) -> None:
    show_error_message(state, ' **  Fatal  ** ' + error_message, out_unit1, out_unit2)
    abort_energyplus(state)


def show_severe_error(state: TransitionState, error_message: str,
                      out_unit1: Optional[int] = None,
                      out_unit2: Optional[int] = None) -> None:
    state.total_severe_errors += 1
    show_error_message(state, ' ** Severe  ** ' + error_message, out_unit1, out_unit2)


def show_continue_error(state: TransitionState, message: str,
                        out_unit1: Optional[int] = None,
                        out_unit2: Optional[int] = None) -> None:
    show_error_message(state, ' **   ~~~   ** ' + message, out_unit1, out_unit2)


def show_message(state: TransitionState, message: str,
                 out_unit1: Optional[int] = None,
                 out_unit2: Optional[int] = None) -> None:
    show_error_message(state, ' ************* ' + message, out_unit1, out_unit2)


def show_warning_error(state: TransitionState, error_message: str,
                       out_unit1: Optional[int] = None,
                       out_unit2: Optional[int] = None) -> None:
    state.total_warning_errors += 1
    show_error_message(state, ' ** Warning ** ' + error_message, out_unit1, out_unit2)


def show_error_message(state: TransitionState, error_message: str,
                       out_unit1: Optional[int] = None,
                       out_unit2: Optional[int] = None) -> None:
    error_format = '(2X,A)'
    fmta = '(A)'
    
    done = error_message.find('Completed Successfully')
    if state.total_errors == 0 and done < 0:
        state.show_error_message_unit = get_new_unit_number(state)
        if state.file_ok:
            state.file_unit_manager.open_unit(
                state.show_error_message_unit,
                state.file_name_path.rstrip() + '.VCpErr')
        else:
            state.file_unit_manager.open_unit(
                state.show_error_message_unit,
                'eplusout.err')
        state.file_unit_manager.write_to_unit(
            state.show_error_message_unit,
            'Program Version,' + state.ver_string.rstrip())
    
    if done < 0 or (done >= 0 and state.total_errors > 0):
        state.total_errors += 1
        state.file_unit_manager.write_to_unit(
            state.show_error_message_unit,
            error_message.rstrip())
        print(error_message.rstrip())
        if done >= 0:
            print('Error messages saved on ' + state.file_name_path.rstrip() + '.VCperr')
            state.file_unit_manager.close_unit(state.show_error_message_unit)
        if out_unit1 is not None:
            state.file_unit_manager.write_to_unit(out_unit1, error_message.rstrip())
        if out_unit2 is not None:
            state.file_unit_manager.write_to_unit(out_unit2, error_message.rstrip())


def get_sat_vap_press_from_dry_bulb(tdb: float) -> float:
    c1 = -5674.5359
    c2 = 6.3925247
    c3 = -0.009677843
    c4 = 0.00000062215701
    c5 = 2.0747825e-09
    c6 = -9.484024e-13
    c7 = 4.1635019
    c8 = -5800.2206
    c9 = 1.3914993
    c10 = -0.048640239
    c11 = 0.000041764768
    c12 = -0.000000014452093
    c13 = 6.5459673
    
    tk = tdb + 273.15
    
    if tk <= 273.15:
        retval = math.exp(c1/tk + c2 + c3*tk + c4*tk**2 + c5*tk**3 + 
                         c6*tk**4 + c7*math.log(tk)) / 1000.0
    else:
        retval = math.exp(c8/tk + c9 + c10*tk + c11*tk**2 + c12*tk**3 + 
                         c13*math.log(tk)) / 1000.0
    
    return retval


def calculate_mu_empd(a: float, b: float, c: float, d: float, 
                      d_empd: float, density_matl: float) -> float:
    t = 24
    rh = 0.45
    p_ambient = 101325
    t_p = 24 * 60 * 60
    
    slope_mc = a * b * (rh ** (b - 1)) + c * d * (rh ** (d - 1))
    pv_sat = get_sat_vap_press_from_dry_bulb(t) * 1000.0
    diffusivity_empd = (d_empd ** 2 * 3.1415926535 * slope_mc * density_matl / 
                       (t_p * pv_sat))
    diffusivity_air = 2.0e-7 * ((t + 273.15) ** 0.81) / p_ambient
    
    mu_empd = diffusivity_air / diffusivity_empd
    return mu_empd


def get_year_from_start_day_string(s_day: str) -> int:
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


def get_leap_year_from_start_day_string(s_day: str) -> int:
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


def get_weekday_num_from_string(s_day: str) -> int:
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


def calculate_day_of_year(i_month: int, i_day: int, leap_year: bool) -> int:
    days_before = (0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334)
    days_before_leap = (0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335)
    
    if leap_year:
        day = days_before_leap[i_month - 1] + i_day
    else:
        day = days_before[i_month - 1] + i_day
    
    return day


def find_year_for_week_day(i_month: int, i_day: int, c_weekday: str) -> int:
    default_year = (2013, 2014, 2015, 2010, 2011, 2017, 2007, 
                   2013, 2014, 2015, 2010, 2011, 2017)
    default_leap_year = (2008, 1992, 2004, 2016, 2000, 2012, 1996, 
                        2008, 1992, 2004, 2016, 2000, 2012)
    
    leap_year = False
    if i_month == 2 and i_day == 29:
        leap_year = True
    
    i_weekday = get_weekday_num_from_string(c_weekday)
    ordinal = calculate_day_of_year(i_month, i_day, leap_year)
    rem = ordinal % 7
    
    if leap_year:
        year = default_leap_year[i_weekday - rem + 5]
    else:
        year = default_year[i_weekday - rem + 5]
    
    return year


def is_year_number_a_leap_year(year_number: int) -> bool:
    if (year_number / 4.0) == int(year_number / 4.0):
        if (year_number / 1000.0) == int(year_number / 1000.0):
            return True
    return False
