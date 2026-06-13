from typing import Protocol, List, Optional, Callable
from dataclasses import dataclass, field
import os

# EXTERNAL DEPS (to wire in glue):
# - MaxNameLength: int (from DataGlobals)
# - ShowFatalError, ShowWarningError: callables (from DataGlobals)
# - withUnits: bool (from DataVCompareGlobals)
# - VersionNum: float (from DataVCompareGlobals)
# - Auditf: file object (from DataVCompareGlobals)
# - OldObjectNames, NewObjectNames: List[str] (from DataVCompareGlobals)
# - NumRenamedObjects: int (from DataVCompareGlobals)
# - PrognameConversion: str (from DataStringGlobals)
# - MakeUPPERCase, SameString, ProcessNumber: callables (from InputProcessor)
# - TrimSigDigits: callable (from General)
# - FindItemInSortedList: callable (from InputProcessor)
# - GetNewUnitNumber: callable (external function)

class VCompareGlobalsProtocol(Protocol):
    withUnits: bool
    VersionNum: float
    Auditf: object
    OldObjectNames: List[str]
    NewObjectNames: List[str]
    NumRenamedObjects: int
    PrognameConversion: str
    MaxNameLength: int
    
    def show_fatal_error(self, msg: str) -> None: ...
    def show_warning_error(self, msg: str, unit: object = None) -> None: ...
    def make_upper_case(self, s: str) -> str: ...
    def same_string(self, s1: str, s2: str) -> bool: ...
    def process_number(self, s: str) -> tuple[float, bool]: ...
    def trim_sig_digits(self, n: int) -> str: ...
    def find_item_in_sorted_list(self, item: str, items: List[str], n: int) -> int: ...
    def get_new_unit_number(self) -> int: ...


def add_field_name_to_line(line: str, l_string: str, field_name: str) -> str:
    """Add field name to output line at column 30."""
    if len(line.rstrip()) > 29:
        line_out = line.rstrip() + l_string + field_name.rstrip()
    else:
        line_out = line.rstrip()
        padding_needed = 30 - len(line_out)
        if padding_needed > 0:
            line_out += ' ' * padding_needed
        line_out += l_string.strip() + ' ' + field_name.rstrip()
    return line_out


def add_units_to_line(line: str, units_arg_chr: str) -> str:
    """Add units to output line."""
    return line.rstrip() + ' {' + units_arg_chr.rstrip() + '}'


def write_out_idf_lines(
    dif_unit: object,
    object_name: str,
    cur_args: int,
    out_args: List[str],
    field_names: List[str],
    field_units: List[str],
    globals_state: VCompareGlobalsProtocol
) -> None:
    """Write IDF object with field names and units."""
    comma_string = ', '
    semi_string = '; '
    blank = ' '
    
    max_size = len(field_names)
    dif_unit.write('  ' + object_name.rstrip() + ',\n')
    
    for arg in range(cur_args):
        if arg != cur_args - 1:
            l_string1 = comma_string
        else:
            l_string1 = semi_string
        
        line_out = '    ' + out_args[arg].rstrip() + l_string1
        
        if arg < max_size:
            line_out = add_field_name_to_line(line_out, '  !- ', field_names[arg])
            if globals_state.withUnits and field_units[arg].rstrip() != blank:
                line_out = add_units_to_line(line_out, field_units[arg])
        else:
            line_out = add_field_name_to_line(line_out, '  !- ', 'Extended Field')
        
        dif_unit.write(line_out.rstrip() + '\n')
    
    dif_unit.write('\n')


def write_out_idf_lines_as_single_line(
    dif_unit: object,
    object_name: str,
    cur_args: int,
    out_args: List[str],
    field_names: Optional[List[str]],
    field_units: Optional[List[str]],
    globals_state: VCompareGlobalsProtocol
) -> None:
    """Write IDF object as single line."""
    comma_string = ', '
    semi_string = '; '
    
    dif_unit.write('  ' + object_name.rstrip() + ',')
    
    for arg in range(cur_args):
        if arg != cur_args - 1:
            l_string1 = comma_string
        else:
            l_string1 = semi_string
        
        line_out = out_args[arg].rstrip() + l_string1
        
        if arg != cur_args - 1:
            dif_unit.write(line_out)
        else:
            dif_unit.write(line_out + '\n')
    
    dif_unit.write('\n')


def write_out_partial_idf_lines(
    dif_unit: object,
    object_name: str,
    cur_args: int,
    out_args: List[str],
    field_names: List[str],
    field_units: List[str],
    globals_state: VCompareGlobalsProtocol
) -> None:
    """Write partial IDF object (no terminating semicolon or blank line)."""
    comma_string = ', '
    blank = ' '
    
    max_size = len(field_names)
    dif_unit.write('  ' + object_name.rstrip() + ',\n')
    
    for arg in range(cur_args):
        l_string1 = comma_string
        line_out = '    ' + out_args[arg].rstrip() + l_string1
        
        if arg < max_size:
            line_out = add_field_name_to_line(line_out, '  !- ', field_names[arg])
            if globals_state.withUnits and field_units[arg].rstrip() != blank:
                line_out = add_units_to_line(line_out, field_units[arg])
        else:
            line_out = add_field_name_to_line(line_out, '  !- ', 'Extended Field')
        
        dif_unit.write(line_out.rstrip() + '\n')


def write_out_idf_lines_as_comments(
    dif_unit: object,
    object_name: str,
    cur_args: int,
    out_args: List[str],
    field_names: List[str],
    field_units: List[str],
    globals_state: VCompareGlobalsProtocol
) -> None:
    """Write IDF object as comments."""
    comma_string = ', '
    semi_string = '; '
    blank = ' '
    
    max_size = len(field_names)
    dif_unit.write('!  ' + object_name.rstrip() + ',\n')
    
    for arg in range(cur_args):
        if arg != cur_args - 1:
            l_string1 = comma_string
        else:
            l_string1 = semi_string
        
        line_out = '!    ' + out_args[arg].rstrip() + l_string1
        
        if arg < max_size:
            line_out = add_field_name_to_line(line_out, '  !- ', field_names[arg])
            if globals_state.withUnits and field_units[arg].rstrip() != blank:
                line_out = add_units_to_line(line_out, field_units[arg])
        else:
            line_out = add_field_name_to_line(line_out, '  !- ', 'Extended Field')
        
        dif_unit.write(line_out.rstrip() + '\n')
    
    dif_unit.write('\n')


def write_preprocessor_object(
    dif_unit: object,
    prog_name: str,
    obj_type: str,
    message: str
) -> None:
    """Write preprocessor object."""
    dif_unit.write(f'! Transition: {obj_type} - {message}\n')


def check_special_objects(
    dif_unit: object,
    object_name: str,
    cur_args: int,
    out_args: List[str],
    field_names: List[str],
    field_units: List[str],
    globals_state: VCompareGlobalsProtocol
) -> bool:
    """Check and write special objects. Returns True if written, False otherwise."""
    
    comma_string = ', '
    semi_string = '; '
    blank = ' '
    vertex_string = 'X,Y,Z ==> Vertex'
    
    written = True
    compact_warning = False
    
    # Surface fields shifted by one with addition of Space Name field
    if globals_state.VersionNum < 9.6:
        surface_space_field_shift = 0
    else:
        surface_space_field_shift = 1
    
    obj_upper = globals_state.make_upper_case(object_name)
    
    if globals_state.VersionNum < 3.0:
        if obj_upper == 'BUILDING':
            if out_args[2].rstrip() == '1':
                out_args[2] = 'Country'
            if out_args[2].rstrip() == '2':
                out_args[2] = 'Suburbs'
            if out_args[2].rstrip() == '3':
                out_args[2] = 'City'
            if out_args[5].rstrip() == '-1':
                out_args[5] = 'MinimalShadowing'
            if out_args[5].rstrip() == '0':
                out_args[5] = 'FullExterior'
            if out_args[5].rstrip() == '1':
                out_args[5] = 'FullInteriorAndExterior'
            
            i_cur_args = cur_args
            if i_cur_args == 8:
                if globals_state.make_upper_case(out_args[7]).strip() == 'YES':
                    out_args[5] = out_args[5].rstrip() + 'WithReflections'
                    out_args[7] = blank
                    i_cur_args = 7
                elif globals_state.make_upper_case(out_args[7]).strip() == 'NO':
                    out_args[7] = blank
                    i_cur_args = 7
            
            write_out_idf_lines(dif_unit, object_name, i_cur_args, out_args, field_names, field_units, globals_state)
        
        elif obj_upper == 'SOLUTION ALGORITHM':
            if out_args[0].rstrip() == '0':
                out_args[0] = 'CTF'
            if globals_state.make_upper_case(out_args[0]).strip() == 'DEFAULT':
                out_args[0] = 'CTF'
            if out_args[0].rstrip() == '2':
                out_args[0] = 'EMPD'
            if out_args[0].rstrip() == '3':
                out_args[0] = 'MTF'
            write_out_idf_lines_as_single_line(dif_unit, object_name, cur_args, out_args, field_names, field_units, globals_state)
        
        elif obj_upper == 'OUTSIDE CONVECTION ALGORITHM':
            if out_args[0].rstrip() == '0':
                out_args[0] = 'Simple'
            if out_args[0].rstrip() == '1':
                out_args[0] = 'Detailed'
            write_out_idf_lines_as_single_line(dif_unit, object_name, cur_args, out_args, field_names, field_units, globals_state)
        
        elif obj_upper == 'INSIDE CONVECTION ALGORITHM':
            if out_args[0].rstrip() == '0':
                out_args[0] = 'Simple'
            if out_args[0].rstrip() == '1':
                out_args[0] = 'Detailed'
            write_out_idf_lines_as_single_line(dif_unit, object_name, cur_args, out_args, field_names, field_units, globals_state)
        
        elif obj_upper == 'REPORT VARIABLE':
            if out_args[0].rstrip() == blank:
                out_args[0] = '*'
            write_out_idf_lines_as_single_line(dif_unit, object_name, cur_args, out_args, field_names, field_units, globals_state)
        
        elif obj_upper in ('SURFACE:HEATTRANSFER', 'SURFACE:HEATTRANSFER:SUB'):
            if globals_state.make_upper_case(out_args[9]).strip() == 'AUTOCALCULATE':
                n_vert = (cur_args - 10) // 3
            elif out_args[9].rstrip() == '':
                n_vert = (cur_args - 10) // 3
            else:
                n_vert, err_flag = globals_state.process_number(out_args[9])
                n_vert = int(n_vert)
                if err_flag:
                    n_vert = (cur_args - 10) // 3
                    out_args[9] = 'Autocalculate'
                    globals_state.show_warning_error(
                        f'For {object_name} named \'{out_args[0]}\', '
                        f'Number of vertices is not a number, defaulting to Autocalculate (N={globals_state.trim_sig_digits(n_vert)})',
                        globals_state.Auditf
                    )
                else:
                    out_args[9] = globals_state.trim_sig_digits(n_vert)
            
            write_out_partial_idf_lines(dif_unit, object_name, 10, out_args, field_names, field_units, globals_state)
            
            v_arg = 10
            for arg in range(1, n_vert + 1):
                if arg != n_vert:
                    l_string = ',  !- '
                else:
                    l_string = ';  !- '
                
                v_string = str(arg)
                if globals_state.withUnits and field_units[v_arg].rstrip() != blank:
                    dif_unit.write(
                        f'    {out_args[v_arg].rstrip()},{out_args[v_arg+1].rstrip()},{out_args[v_arg+2].rstrip()}'
                        f'{l_string}{vertex_string} {v_string} {{{field_units[v_arg].rstrip()}}}\n'
                    )
                else:
                    dif_unit.write(
                        f'    {out_args[v_arg].rstrip()},{out_args[v_arg+1].rstrip()},{out_args[v_arg+2].rstrip()}'
                        f'{l_string}{vertex_string} {v_string}\n'
                    )
                v_arg += 3
            
            dif_unit.write('\n')
        
        elif obj_upper in ('SURFACE:SHADING:DETACHED', 'SURFACE:SHADING:DETACHED:FIXED', 'SURFACE:SHADING:DETACHED:BUILDING'):
            if globals_state.make_upper_case(out_args[2]).strip() == 'AUTOCALCULATE':
                n_vert = (cur_args - 3) // 3
            elif out_args[2].rstrip() == '':
                n_vert = (cur_args - 3) // 3
            else:
                n_vert, err_flag = globals_state.process_number(out_args[2])
                n_vert = int(n_vert)
                if err_flag:
                    n_vert = (cur_args - 3) // 3
                    out_args[2] = 'Autocalculate'
                    globals_state.show_warning_error(
                        f'For {object_name} named \'{out_args[0]}\', '
                        f'Number of vertices is not a number, defaulting to Autocalculate (N={globals_state.trim_sig_digits(n_vert)})',
                        globals_state.Auditf
                    )
                else:
                    out_args[2] = globals_state.trim_sig_digits(n_vert)
            
            if object_name == 'SURFACE:SHADING:DETACHED':
                write_out_partial_idf_lines(dif_unit, 'SURFACE:SHADING:DETACHED:FIXED', 3, out_args, field_names, field_units, globals_state)
            else:
                write_out_partial_idf_lines(dif_unit, object_name, 3, out_args, field_names, field_units, globals_state)
            
            v_arg = 3
            for arg in range(1, n_vert + 1):
                if arg != n_vert:
                    l_string = ',  !- '
                else:
                    l_string = ';  !- '
                
                v_string = str(arg)
                if globals_state.withUnits and field_units[v_arg].rstrip() != blank:
                    dif_unit.write(
                        f'    {out_args[v_arg].rstrip()},{out_args[v_arg+1].rstrip()},{out_args[v_arg+2].rstrip()}'
                        f'{l_string}{vertex_string} {v_string} {{{field_units[v_arg].rstrip()}}}\n'
                    )
                else:
                    dif_unit.write(
                        f'    {out_args[v_arg].rstrip()},{out_args[v_arg+1].rstrip()},{out_args[v_arg+2].rstrip()}'
                        f'{l_string}{vertex_string} {v_string}\n'
                    )
                v_arg += 3
            
            dif_unit.write('\n')
        
        elif obj_upper == 'SURFACE:SHADING:ATTACHED':
            if globals_state.make_upper_case(out_args[3]).strip() == 'AUTOCALCULATE':
                n_vert = (cur_args - 4) // 3
            elif out_args[3].rstrip() == '':
                n_vert = (cur_args - 4) // 3
            else:
                n_vert, err_flag = globals_state.process_number(out_args[3])
                n_vert = int(n_vert)
                if err_flag:
                    n_vert = (cur_args - 4) // 3
                    out_args[3] = 'Autocalculate'
                    globals_state.show_warning_error(
                        f'For {object_name} named \'{out_args[0]}\', '
                        f'Number of vertices is not a number, defaulting to Autocalculate (N={globals_state.trim_sig_digits(n_vert)})',
                        globals_state.Auditf
                    )
                else:
                    out_args[3] = globals_state.trim_sig_digits(n_vert)
            
            write_out_partial_idf_lines(dif_unit, object_name, 4, out_args, field_names, field_units, globals_state)
            
            v_arg = 4
            for arg in range(1, n_vert + 1):
                if arg != n_vert:
                    l_string = ',  !- '
                else:
                    l_string = ';  !- '
                
                v_string = str(arg)
                if globals_state.withUnits and field_units[v_arg].rstrip() != blank:
                    dif_unit.write(
                        f'    {out_args[v_arg].rstrip()},{out_args[v_arg+1].rstrip()},{out_args[v_arg+2].rstrip()}'
                        f'{l_string}{vertex_string} {v_string} {{{field_units[v_arg].rstrip()}}}\n'
                    )
                else:
                    dif_unit.write(
                        f'    {out_args[v_arg].rstrip()},{out_args[v_arg+1].rstrip()},{out_args[v_arg+2].rstrip()}'
                        f'{l_string}{vertex_string} {v_string}\n'
                    )
                v_arg += 3
            
            dif_unit.write('\n')
        
        elif obj_upper == 'WINDOWGLASSSPECTRALDATA':
            write_out_partial_idf_lines(dif_unit, object_name, 1, out_args, field_names, field_units, globals_state)
            arg = 1
            while arg < cur_args:
                vargs = arg
                varge = min(arg + 3, cur_args - 1)
                if varge != cur_args - 1:
                    l_string = ','
                else:
                    l_string = ';'
                
                line_out = '    ' + out_args[vargs].rstrip()
                for v_arg in range(vargs + 1, varge + 1):
                    line_out += ',' + out_args[v_arg]
                
                line_out += l_string
                dif_unit.write(line_out.rstrip() + '\n')
                arg += 4
            
            dif_unit.write('\n')
        
        elif obj_upper == 'FLUIDPROPERTYTEMPERATURES':
            write_out_partial_idf_lines(dif_unit, object_name, 1, out_args, field_names, field_units, globals_state)
            arg = 1
            while arg < cur_args:
                vargs = arg
                varge = min(arg + 6, cur_args - 1)
                if varge != cur_args - 1:
                    l_string = ','
                else:
                    l_string = ';'
                
                line_out = '    ' + out_args[vargs].rstrip()
                for v_arg in range(vargs + 1, varge + 1):
                    line_out += ',' + out_args[v_arg]
                
                line_out += l_string
                dif_unit.write(line_out.rstrip() + '\n')
                arg += 7
            
            dif_unit.write('\n')
        
        elif obj_upper in ('FLUIDPROPERTYSATURATED', 'FLUIDPROPERTYSUPERHEATED', 'FLUIDPROPERTYCONCENTRATION'):
            write_out_partial_idf_lines(dif_unit, object_name, 4, out_args, field_names, field_units, globals_state)
            arg = 4
            while arg < cur_args:
                vargs = arg
                varge = min(arg + 6, cur_args - 1)
                if varge != cur_args - 1:
                    l_string = ','
                else:
                    l_string = ';'
                
                line_out = '    ' + out_args[vargs].rstrip()
                for v_arg in range(vargs + 1, varge + 1):
                    line_out += ',' + out_args[v_arg]
                
                line_out += l_string
                dif_unit.write(line_out.rstrip() + '\n')
                arg += 7
            
            dif_unit.write('\n')
        
        else:
            written = False
    
    else:
        if obj_upper in (
            'VERSION', 'SURFACECONVECTIONALGORITHM:INSIDE',
            'SURFACECONVECTIONALGORITHM:OUTSIDE', 'HEATBALANCEALGORITHM',
            'ZONECAPACITANCEMULTIPLIER', 'TIMESTEP',
            'SITE:GROUNDTEMPERATURE:BUILDINGSURFACE',
            'SITE:GROUNDTEMPERATURE:FCFACTORMETHOD',
            'SITE:GROUNDTEMPERATURE:SHALLOW',
            'SITE:GROUNDTEMPERATURE:DEEP', 'SITE:GROUNDREFLECTANCE',
            'OUTPUT:METER', 'OUTPUT:METER:METERFILEONLY',
            'OUTPUT:METER:CUMULATIVE',
            'OUTPUT:METER:CUMULATIVE:METERFILEONLY',
            'OUTPUT:VARIABLEDICTIONARY', 'OUTPUT:SURFACES:LIST',
            'OUTPUT:SURFACES:DRAWING', 'OUTPUT:SCHEDULES',
            'OUTPUT:CONSTRUCTIONS', 'SCHEDULE:CONSTANT'
        ):
            write_out_idf_lines_as_single_line(dif_unit, object_name, cur_args, out_args, field_names, field_units, globals_state)
        
        elif obj_upper == 'SCHEDULE:COMPACT':
            compact_warning = False
            write_out_partial_idf_lines(dif_unit, object_name, 2, out_args, field_names, field_units, globals_state)
            arg = 2
            while arg < cur_args:
                if globals_state.same_string(out_args[arg][:5], 'Until'):
                    if arg + 1 != cur_args:
                        l_string = ','
                    else:
                        l_string = ';'
                    
                    if arg == cur_args - 1:
                        l_string = ';'
                        compact_warning = True
                    
                    line_out = '    ' + out_args[arg].rstrip() + ',' + out_args[arg + 1].rstrip() + l_string
                    if len(line_out.rstrip()) > 29:
                        dif_unit.write(line_out.rstrip() + ' !- ' + field_names[arg].rstrip() + '\n')
                    else:
                        line_out = line_out.rstrip()
                        padding = 30 - len(line_out)
                        if padding > 0:
                            line_out += ' ' * padding
                        line_out += '!- ' + field_names[arg].rstrip()
                        dif_unit.write(line_out.rstrip() + '\n')
                    
                    arg += 2
                else:
                    if arg != cur_args - 1:
                        l_string = ','
                    else:
                        l_string = ';'
                    
                    line_out = '    ' + out_args[arg].rstrip() + l_string
                    if len(line_out.rstrip()) > 29:
                        dif_unit.write(line_out.rstrip() + ' !- ' + field_names[arg].rstrip() + '\n')
                    else:
                        line_out = line_out.rstrip()
                        padding = 30 - len(line_out)
                        if padding > 0:
                            line_out += ' ' * padding
                        line_out += '!- ' + field_names[arg].rstrip()
                        dif_unit.write(line_out.rstrip() + '\n')
                    
                    arg += 1
            
            dif_unit.write('\n')
            if compact_warning:
                write_preprocessor_object(
                    dif_unit,
                    globals_state.PrognameConversion,
                    'Warning',
                    f'Compact Schedule object="{out_args[0].rstrip()}" terminated early.  Check for accuracy.'
                )
        
        elif obj_upper == 'OUTPUT:VARIABLE':
            if out_args[0].rstrip() == blank:
                out_args[0] = '*'
            write_out_idf_lines_as_single_line(dif_unit, object_name, cur_args, out_args, field_names, field_units, globals_state)
        
        elif obj_upper == 'BUILDINGSURFACE:DETAILED':
            n_vert_field_num = 10 + surface_space_field_shift
            if globals_state.make_upper_case(out_args[n_vert_field_num - 1]).strip() == 'AUTOCALCULATE':
                n_vert = (cur_args - n_vert_field_num) // 3
            elif out_args[n_vert_field_num - 1].rstrip() == '':
                n_vert = (cur_args - n_vert_field_num) // 3
            else:
                n_vert, err_flag = globals_state.process_number(out_args[n_vert_field_num - 1])
                n_vert = int(n_vert)
                if err_flag:
                    n_vert = (cur_args - n_vert_field_num) // 3
                    out_args[n_vert_field_num - 1] = 'Autocalculate'
                    globals_state.show_warning_error(
                        f'For {object_name} named \'{out_args[0]}\', '
                        f'Number of vertices is not a number, defaulting to Autocalculate (N={globals_state.trim_sig_digits(n_vert)})',
                        globals_state.Auditf
                    )
                else:
                    out_args[n_vert_field_num - 1] = globals_state.trim_sig_digits(n_vert)
            
            write_out_partial_idf_lines(dif_unit, object_name, n_vert_field_num, out_args, field_names, field_units, globals_state)
            
            v_arg = n_vert_field_num
            for arg in range(1, n_vert + 1):
                if arg != n_vert:
                    l_string = ',  !- '
                else:
                    l_string = ';  !- '
                
                v_string = str(arg)
                if globals_state.withUnits and field_units[v_arg].rstrip() != blank:
                    dif_unit.write(
                        f'    {out_args[v_arg].rstrip()},{out_args[v_arg+1].rstrip()},{out_args[v_arg+2].rstrip()}'
                        f'{l_string}{vertex_string} {v_string} {{{field_units[v_arg].rstrip()}}}\n'
                    )
                else:
                    dif_unit.write(
                        f'    {out_args[v_arg].rstrip()},{out_args[v_arg+1].rstrip()},{out_args[v_arg+2].rstrip()}'
                        f'{l_string}{vertex_string} {v_string}\n'
                    )
                v_arg += 3
            
            dif_unit.write('\n')
        
        elif obj_upper == 'FENESTRATIONSURFACE:DETAILED':
            if globals_state.VersionNum < 9.0:
                if globals_state.make_upper_case(out_args[9]).strip() == 'AUTOCALCULATE':
                    n_vert = (cur_args - 10) // 3
                elif out_args[9].rstrip() == '':
                    n_vert = (cur_args - 10) // 3
                else:
                    n_vert, err_flag = globals_state.process_number(out_args[9])
                    n_vert = int(n_vert)
                    if err_flag:
                        n_vert = (cur_args - 10) // 3
                        out_args[9] = 'Autocalculate'
                        globals_state.show_warning_error(
                            f'For {object_name} named \'{out_args[0]}\', '
                            f'Number of vertices is not a number, defaulting to Autocalculate (N={globals_state.trim_sig_digits(n_vert)})',
                            globals_state.Auditf
                        )
                    else:
                        out_args[9] = globals_state.trim_sig_digits(n_vert)
                
                write_out_partial_idf_lines(dif_unit, object_name, 10, out_args, field_names, field_units, globals_state)
                
                v_arg = 10
                for arg in range(1, n_vert + 1):
                    if arg != n_vert:
                        l_string = ',  !- '
                    else:
                        l_string = ';  !- '
                    
                    v_string = str(arg)
                    if globals_state.withUnits and field_units[v_arg].rstrip() != blank:
                        dif_unit.write(
                            f'    {out_args[v_arg].rstrip()},{out_args[v_arg+1].rstrip()},{out_args[v_arg+2].rstrip()}'
                            f'{l_string}{vertex_string} {v_string} {{{field_units[v_arg].rstrip()}}}\n'
                        )
                    else:
                        dif_unit.write(
                            f'    {out_args[v_arg].rstrip()},{out_args[v_arg+1].rstrip()},{out_args[v_arg+2].rstrip()}'
                            f'{l_string}{vertex_string} {v_string}\n'
                        )
                    v_arg += 3
                
                dif_unit.write('\n')
            else:
                if globals_state.make_upper_case(out_args[8]).strip() == 'AUTOCALCULATE':
                    n_vert = (cur_args - 9) // 3
                elif out_args[8].rstrip() == '':
                    n_vert = (cur_args - 9) // 3
                else:
                    n_vert, err_flag = globals_state.process_number(out_args[8])
                    n_vert = int(n_vert)
                    if err_flag:
                        n_vert = (cur_args - 9) // 3
                        out_args[8] = 'Autocalculate'
                        globals_state.show_warning_error(
                            f'For {object_name} named \'{out_args[0]}\', '
                            f'Number of vertices is not a number, defaulting to Autocalculate (N={globals_state.trim_sig_digits(n_vert)})',
                            globals_state.Auditf
                        )
                    else:
                        out_args[8] = globals_state.trim_sig_digits(n_vert)
                
                write_out_partial_idf_lines(dif_unit, object_name, 9, out_args, field_names, field_units, globals_state)
                
                v_arg = 9
                for arg in range(1, n_vert + 1):
                    if arg != n_vert:
                        l_string = ',  !- '
                    else:
                        l_string = ';  !- '
                    
                    v_string = str(arg)
                    if globals_state.withUnits and field_units[v_arg].rstrip() != blank:
                        dif_unit.write(
                            f'    {out_args[v_arg].rstrip()},{out_args[v_arg+1].rstrip()},{out_args[v_arg+2].rstrip()}'
                            f'{l_string}{vertex_string} {v_string} {{{field_units[v_arg].rstrip()}}}\n'
                        )
                    else:
                        dif_unit.write(
                            f'    {out_args[v_arg].rstrip()},{out_args[v_arg+1].rstrip()},{out_args[v_arg+2].rstrip()}'
                            f'{l_string}{vertex_string} {v_string}\n'
                        )
                    v_arg += 3
                
                dif_unit.write('\n')
        
        elif obj_upper in ('WALL:DETAILED', 'ROOFCEILING:DETAILED', 'FLOOR:DETAILED'):
            n_vert_field_num = 9 + surface_space_field_shift
            if globals_state.make_upper_case(out_args[n_vert_field_num - 1]).strip() == 'AUTOCALCULATE':
                n_vert = (cur_args - n_vert_field_num) // 3
            elif out_args[n_vert_field_num - 1].rstrip() == '':
                n_vert = (cur_args - n_vert_field_num) // 3
            else:
                n_vert, err_flag = globals_state.process_number(out_args[n_vert_field_num - 1])
                n_vert = int(n_vert)
                if err_flag:
                    n_vert = (cur_args - n_vert_field_num) // 3
                    out_args[n_vert_field_num - 1] = 'Autocalculate'
                    globals_state.show_warning_error(
                        f'For {object_name} named \'{out_args[0]}\', '
                        f'Number of vertices is not a number, defaulting to Autocalculate (N={globals_state.trim_sig_digits(n_vert)})',
                        globals_state.Auditf
                    )
                else:
                    out_args[n_vert_field_num - 1] = globals_state.trim_sig_digits(n_vert)
            
            write_out_partial_idf_lines(dif_unit, object_name, n_vert_field_num, out_args, field_names, field_units, globals_state)
            
            v_arg = n_vert_field_num
            for arg in range(1, n_vert + 1):
                if arg != n_vert:
                    l_string = ',  !- '
                else:
                    l_string = ';  !- '
                
                v_string = str(arg)
                if globals_state.withUnits and field_units[v_arg].rstrip() != blank:
                    dif_unit.write(
                        f'    {out_args[v_arg].rstrip()},{out_args[v_arg+1].rstrip()},{out_args[v_arg+2].rstrip()}'
                        f'{l_string}{vertex_string} {v_string} {{{field_units[v_arg].rstrip()}}}\n'
                    )
                else:
                    dif_unit.write(
                        f'    {out_args[v_arg].rstrip()},{out_args[v_arg+1].rstrip()},{out_args[v_arg+2].rstrip()}'
                        f'{l_string}{vertex_string} {v_string}\n'
                    )
                v_arg += 3
            
            dif_unit.write('\n')
        
        elif obj_upper in ('SHADING:SITE:DETAILED', 'SHADING:BUILDING:DETAILED'):
            if globals_state.make_upper_case(out_args[2]).strip() == 'AUTOCALCULATE':
                n_vert = (cur_args - 3) // 3
            elif out_args[2].rstrip() == '':
                n_vert = (cur_args - 3) // 3
            else:
                n_vert, err_flag = globals_state.process_number(out_args[2])
                n_vert = int(n_vert)
                if err_flag:
                    n_vert = (cur_args - 3) // 3
                    out_args[2] = 'Autocalculate'
                    globals_state.show_warning_error(
                        f'For {object_name} named \'{out_args[0]}\', '
                        f'Number of vertices is not a number, defaulting to Autocalculate (N={globals_state.trim_sig_digits(n_vert)})',
                        globals_state.Auditf
                    )
                else:
                    out_args[2] = globals_state.trim_sig_digits(n_vert)
            
            write_out_partial_idf_lines(dif_unit, object_name, 3, out_args, field_names, field_units, globals_state)
            
            v_arg = 3
            for arg in range(1, n_vert + 1):
                if arg != n_vert:
                    l_string = ',  !- '
                else:
                    l_string = ';  !- '
                
                v_string = str(arg)
                if globals_state.withUnits and field_units[v_arg].rstrip() != blank:
                    dif_unit.write(
                        f'    {out_args[v_arg].rstrip()},{out_args[v_arg+1].rstrip()},{out_args[v_arg+2].rstrip()}'
                        f'{l_string}{vertex_string} {v_string} {{{field_units[v_arg].rstrip()}}}\n'
                    )
                else:
                    dif_unit.write(
                        f'    {out_args[v_arg].rstrip()},{out_args[v_arg+1].rstrip()},{out_args[v_arg+2].rstrip()}'
                        f'{l_string}{vertex_string} {v_string}\n'
                    )
                v_arg += 3
            
            dif_unit.write('\n')
        
        elif obj_upper == 'SHADING:ZONE:DETAILED':
            if globals_state.make_upper_case(out_args[3]).strip() == 'AUTOCALCULATE':
                n_vert = (cur_args - 4) // 3
            elif out_args[3].rstrip() == '':
                n_vert = (cur_args - 4) // 3
            else:
                n_vert, err_flag = globals_state.process_number(out_args[3])
                n_vert = int(n_vert)
                if err_flag:
                    n_vert = (cur_args - 4) // 3
                    out_args[3] = 'Autocalculate'
                    globals_state.show_warning_error(
                        f'For {object_name} named \'{out_args[0]}\', '
                        f'Number of vertices is not a number, defaulting to Autocalculate (N={globals_state.trim_sig_digits(n_vert)})',
                        globals_state.Auditf
                    )
                else:
                    out_args[3] = globals_state.trim_sig_digits(n_vert)
            
            write_out_partial_idf_lines(dif_unit, object_name, 4, out_args, field_names, field_units, globals_state)
            
            v_arg = 4
            for arg in range(1, n_vert + 1):
                if arg != n_vert:
                    l_string = ',  !- '
                else:
                    l_string = ';  !- '
                
                v_string = str(arg)
                if globals_state.withUnits and field_units[v_arg].rstrip() != blank:
                    dif_unit.write(
                        f'    {out_args[v_arg].rstrip()},{out_args[v_arg+1].rstrip()},{out_args[v_arg+2].rstrip()}'
                        f'{l_string}{vertex_string} {v_string} {{{field_units[v_arg].rstrip()}}}\n'
                    )
                else:
                    dif_unit.write(
                        f'    {out_args[v_arg].rstrip()},{out_args[v_arg+1].rstrip()},{out_args[v_arg+2].rstrip()}'
                        f'{l_string}{vertex_string} {v_string}\n'
                    )
                v_arg += 3
            
            dif_unit.write('\n')
        
        elif obj_upper == 'MATERIALPROPERTY:GLAZINGSPECTRALDATA':
            write_out_partial_idf_lines(dif_unit, object_name, 1, out_args, field_names, field_units, globals_state)
            arg = 1
            while arg < cur_args:
                vargs = arg
                varge = min(arg + 3, cur_args - 1)
                if varge != cur_args - 1:
                    l_string = ','
                else:
                    l_string = ';'
                
                line_out = '    ' + out_args[vargs].rstrip()
                for v_arg in range(vargs + 1, varge + 1):
                    line_out += ',' + out_args[v_arg]
                
                line_out += l_string
                dif_unit.write(line_out.rstrip() + '\n')
                arg += 4
            
            dif_unit.write('\n')
        
        elif obj_upper == 'FLUIDPROPERTIES:TEMPERATURES':
            write_out_partial_idf_lines(dif_unit, object_name, 1, out_args, field_names, field_units, globals_state)
            arg = 1
            while arg < cur_args:
                vargs = arg
                varge = min(arg + 6, cur_args - 1)
                if varge != cur_args - 1:
                    l_string = ','
                else:
                    l_string = ';'
                
                line_out = '    ' + out_args[vargs].rstrip()
                for v_arg in range(vargs + 1, varge + 1):
                    line_out += ',' + out_args[v_arg]
                
                line_out += l_string
                dif_unit.write(line_out.rstrip() + '\n')
                arg += 7
            
            dif_unit.write('\n')
        
        elif obj_upper in ('FLUIDPROPERTIES:SATURATED', 'FLUIDPROPERTIES:SUPERHEATED', 'FLUIDPROPERTIES:CONCENTRATION'):
            write_out_partial_idf_lines(dif_unit, object_name, 4, out_args, field_names, field_units, globals_state)
            arg = 4
            while arg < cur_args:
                vargs = arg
                varge = min(arg + 6, cur_args - 1)
                if varge != cur_args - 1:
                    l_string = ','
                else:
                    l_string = ';'
                
                line_out = '    ' + out_args[vargs].rstrip()
                for v_arg in range(vargs + 1, varge + 1):
                    line_out += ',' + out_args[v_arg]
                
                line_out += l_string
                dif_unit.write(line_out.rstrip() + '\n')
                arg += 7
            
            dif_unit.write('\n')
        
        else:
            written = False
    
    return written


def read_renamed_objects(file_name: str, globals_state: VCompareGlobalsProtocol) -> None:
    """Read renamed objects from file."""
    
    if not os.path.exists(file_name):
        globals_state.show_fatal_error(f'File={file_name} not found.  Transition terminates without completing.')
        return
    
    globals_state.NumRenamedObjects = 0
    cur_num = 0
    
    try:
        with open(file_name, 'r') as f:
            line = f.readline().strip()
            num_objects = int(line)
            
            globals_state.OldObjectNames = ['' for _ in range(num_objects)]
            globals_state.NewObjectNames = ['' for _ in range(num_objects)]
            
            for line in f:
                line = line.rstrip('\n')
                tab_index = line.find('\t')
                if tab_index > 0:
                    cur_num += 1
                    globals_state.OldObjectNames[cur_num - 1] = line[:tab_index]
                    globals_state.NewObjectNames[cur_num - 1] = line[tab_index + 1:]
                else:
                    globals_state.Auditf.write(f'file={file_name} blank line after {cur_num} renamed objects read\n')
                    break
            
            globals_state.NumRenamedObjects = cur_num
    
    except Exception as e:
        globals_state.Auditf.write(f'file={file_name} not found\n')
        globals_state.show_fatal_error(f'File={file_name} not found.  Transition terminates without completing.')


def replace_renamed_object_fields(
    old_name: str,
    globals_state: VCompareGlobalsProtocol
) -> tuple[str, bool]:
    """Replace renamed object fields. Returns (new_name, err_flag)."""
    
    err_flag = False
    found_item = globals_state.find_item_in_sorted_list(
        old_name,
        globals_state.OldObjectNames,
        globals_state.NumRenamedObjects
    )
    
    if found_item > 0:
        new_name = globals_state.NewObjectNames[found_item - 1]
    else:
        new_name = old_name
        err_flag = True
    
    return new_name, err_flag


def is_valid_output_units(string: str) -> bool:
    """Check if string is valid output units."""
    
    valid_output_units = [
        '%',
        'A',
        'ach',
        'Ah',
        'C',
        'cd/m2',
        'deg',
        'deltaC',
        'hr',
        'J',
        'J/kg',
        'J/kgWater',
        'J/m2',
        'K/m',
        'kg',
        'kg/kg',
        'kg/m3',
        'kg/s',
        'kgWater/kgDryAir',
        'kgWater/s',
        'kmol/s',
        'L',
        'lum/W',
        'lux',
        'm',
        'm/s',
        'm2',
        'm3',
        'm3/s',
        'Pa',
        'ppm',
        'rad',
        's',
        'units',
        'V',
        'W',
        'W/K',
        'W/m2',
        'W/m2-C',
        'W/m2-K',
        'W/W',
    ]
    
    for unit in valid_output_units:
        if string.rstrip() == unit:
            return True
    
    return False
