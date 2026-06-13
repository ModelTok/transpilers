from collections import InlineArray
from sys import external_call

# EXTERNAL DEPS (to wire in glue):
# - MaxNameLength: Int (from DataGlobals)
# - ShowFatalError, ShowWarningError: callables (from DataGlobals)
# - withUnits: Bool (from DataVCompareGlobals)
# - VersionNum: Float64 (from DataVCompareGlobals)
# - Auditf: file object (from DataVCompareGlobals)
# - OldObjectNames, NewObjectNames: DynamicVector[String] (from DataVCompareGlobals)
# - NumRenamedObjects: Int (from DataVCompareGlobals)
# - PrognameConversion: String (from DataStringGlobals)
# - MakeUPPERCase, SameString, ProcessNumber: callables (from InputProcessor)
# - TrimSigDigits: callable (from General)
# - FindItemInSortedList: callable (from InputProcessor)
# - GetNewUnitNumber: callable (external function)

trait VCompareGlobalsProtocol:
    fn get_with_units(self) -> Bool: ...
    fn get_version_num(self) -> Float64: ...
    fn get_auditf(self) -> object: ...
    fn get_old_object_names(self) -> DynamicVector[String]: ...
    fn get_new_object_names(self) -> DynamicVector[String]: ...
    fn get_num_renamed_objects(self) -> Int: ...
    fn get_progname_conversion(self) -> String: ...
    fn get_max_name_length(self) -> Int: ...
    fn show_fatal_error(self, msg: String) -> None: ...
    fn show_warning_error(self, msg: String, unit: object = None) -> None: ...
    fn make_upper_case(self, s: String) -> String: ...
    fn same_string(self, s1: String, s2: String) -> Bool: ...
    fn process_number(self, s: String) -> (Float64, Bool): ...
    fn trim_sig_digits(self, n: Int) -> String: ...
    fn find_item_in_sorted_list(self, item: String, items: DynamicVector[String], n: Int) -> Int: ...
    fn get_new_unit_number(self) -> Int: ...


fn add_field_name_to_line(line: String, l_string: String, field_name: String) -> String:
    """Add field name to output line at column 30."""
    var line_trimmed = line.rstrip()
    if len(line_trimmed) > 29:
        return line_trimmed + l_string + field_name.rstrip()
    else:
        var line_out = line_trimmed
        var padding_needed = 30 - len(line_out)
        if padding_needed > 0:
            for _ in range(padding_needed):
                line_out += " "
        line_out += l_string.strip() + " " + field_name.rstrip()
        return line_out


fn add_units_to_line(line: String, units_arg_chr: String) -> String:
    """Add units to output line."""
    return line.rstrip() + " {" + units_arg_chr.rstrip() + "}"


fn write_out_idf_lines(
    dif_unit: object,
    object_name: String,
    cur_args: Int,
    out_args: DynamicVector[String],
    field_names: DynamicVector[String],
    field_units: DynamicVector[String],
    globals_state: VCompareGlobalsProtocol,
) -> None:
    """Write IDF object with field names and units."""
    var comma_string = ", "
    var semi_string = "; "
    var blank = " "
    
    var max_size = len(field_names)
    dif_unit.write("  " + object_name.rstrip() + ",\n")
    
    for arg in range(cur_args):
        var l_string1 = comma_string if arg != cur_args - 1 else semi_string
        var line_out = "    " + out_args[arg].rstrip() + l_string1
        
        if arg < max_size:
            line_out = add_field_name_to_line(line_out, "  !- ", field_names[arg])
            if globals_state.get_with_units() and field_units[arg].rstrip() != blank:
                line_out = add_units_to_line(line_out, field_units[arg])
        else:
            line_out = add_field_name_to_line(line_out, "  !- ", "Extended Field")
        
        dif_unit.write(line_out.rstrip() + "\n")
    
    dif_unit.write("\n")


fn write_out_idf_lines_as_single_line(
    dif_unit: object,
    object_name: String,
    cur_args: Int,
    out_args: DynamicVector[String],
    field_names: Optional[DynamicVector[String]],
    field_units: Optional[DynamicVector[String]],
    globals_state: VCompareGlobalsProtocol,
) -> None:
    """Write IDF object as single line."""
    var comma_string = ", "
    var semi_string = "; "
    
    dif_unit.write("  " + object_name.rstrip() + ",")
    
    for arg in range(cur_args):
        var l_string1 = comma_string if arg != cur_args - 1 else semi_string
        var line_out = out_args[arg].rstrip() + l_string1
        
        if arg != cur_args - 1:
            dif_unit.write(line_out)
        else:
            dif_unit.write(line_out + "\n")
    
    dif_unit.write("\n")


fn write_out_partial_idf_lines(
    dif_unit: object,
    object_name: String,
    cur_args: Int,
    out_args: DynamicVector[String],
    field_names: DynamicVector[String],
    field_units: DynamicVector[String],
    globals_state: VCompareGlobalsProtocol,
) -> None:
    """Write partial IDF object (no terminating semicolon or blank line)."""
    var comma_string = ", "
    var blank = " "
    
    var max_size = len(field_names)
    dif_unit.write("  " + object_name.rstrip() + ",\n")
    
    for arg in range(cur_args):
        var l_string1 = comma_string
        var line_out = "    " + out_args[arg].rstrip() + l_string1
        
        if arg < max_size:
            line_out = add_field_name_to_line(line_out, "  !- ", field_names[arg])
            if globals_state.get_with_units() and field_units[arg].rstrip() != blank:
                line_out = add_units_to_line(line_out, field_units[arg])
        else:
            line_out = add_field_name_to_line(line_out, "  !- ", "Extended Field")
        
        dif_unit.write(line_out.rstrip() + "\n")


fn write_out_idf_lines_as_comments(
    dif_unit: object,
    object_name: String,
    cur_args: Int,
    out_args: DynamicVector[String],
    field_names: DynamicVector[String],
    field_units: DynamicVector[String],
    globals_state: VCompareGlobalsProtocol,
) -> None:
    """Write IDF object as comments."""
    var comma_string = ", "
    var semi_string = "; "
    var blank = " "
    
    var max_size = len(field_names)
    dif_unit.write("!  " + object_name.rstrip() + ",\n")
    
    for arg in range(cur_args):
        var l_string1 = comma_string if arg != cur_args - 1 else semi_string
        var line_out = "!    " + out_args[arg].rstrip() + l_string1
        
        if arg < max_size:
            line_out = add_field_name_to_line(line_out, "  !- ", field_names[arg])
            if globals_state.get_with_units() and field_units[arg].rstrip() != blank:
                line_out = add_units_to_line(line_out, field_units[arg])
        else:
            line_out = add_field_name_to_line(line_out, "  !- ", "Extended Field")
        
        dif_unit.write(line_out.rstrip() + "\n")
    
    dif_unit.write("\n")


fn write_preprocessor_object(
    dif_unit: object,
    prog_name: String,
    obj_type: String,
    message: String,
) -> None:
    """Write preprocessor object."""
    dif_unit.write("! Transition: " + obj_type + " - " + message + "\n")


fn check_special_objects(
    dif_unit: object,
    object_name: String,
    cur_args: Int,
    out_args: DynamicVector[String],
    field_names: DynamicVector[String],
    field_units: DynamicVector[String],
    globals_state: VCompareGlobalsProtocol,
) -> Bool:
    """Check and write special objects. Returns True if written, False otherwise."""
    
    var comma_string = ", "
    var semi_string = "; "
    var blank = " "
    var vertex_string = "X,Y,Z ==> Vertex"
    
    var written = True
    var compact_warning = False
    
    var surface_space_field_shift = 0 if globals_state.get_version_num() < 9.6 else 1
    
    var obj_upper = globals_state.make_upper_case(object_name)
    
    if globals_state.get_version_num() < 3.0:
        if obj_upper == "BUILDING":
            if out_args[2].rstrip() == "1":
                out_args[2] = "Country"
            if out_args[2].rstrip() == "2":
                out_args[2] = "Suburbs"
            if out_args[2].rstrip() == "3":
                out_args[2] = "City"
            if out_args[5].rstrip() == "-1":
                out_args[5] = "MinimalShadowing"
            if out_args[5].rstrip() == "0":
                out_args[5] = "FullExterior"
            if out_args[5].rstrip() == "1":
                out_args[5] = "FullInteriorAndExterior"
            
            var i_cur_args = cur_args
            if i_cur_args == 8:
                if globals_state.make_upper_case(out_args[7]).strip() == "YES":
                    out_args[5] = out_args[5].rstrip() + "WithReflections"
                    out_args[7] = blank
                    i_cur_args = 7
                elif globals_state.make_upper_case(out_args[7]).strip() == "NO":
                    out_args[7] = blank
                    i_cur_args = 7
            
            write_out_idf_lines(dif_unit, object_name, i_cur_args, out_args, field_names, field_units, globals_state)
        
        elif obj_upper == "SOLUTION ALGORITHM":
            if out_args[0].rstrip() == "0":
                out_args[0] = "CTF"
            if globals_state.make_upper_case(out_args[0]).strip() == "DEFAULT":
                out_args[0] = "CTF"
            if out_args[0].rstrip() == "2":
                out_args[0] = "EMPD"
            if out_args[0].rstrip() == "3":
                out_args[0] = "MTF"
            write_out_idf_lines_as_single_line(dif_unit, object_name, cur_args, out_args, field_names, field_units, globals_state)
        
        elif obj_upper == "OUTSIDE CONVECTION ALGORITHM":
            if out_args[0].rstrip() == "0":
                out_args[0] = "Simple"
            if out_args[0].rstrip() == "1":
                out_args[0] = "Detailed"
            write_out_idf_lines_as_single_line(dif_unit, object_name, cur_args, out_args, field_names, field_units, globals_state)
        
        elif obj_upper == "INSIDE CONVECTION ALGORITHM":
            if out_args[0].rstrip() == "0":
                out_args[0] = "Simple"
            if out_args[0].rstrip() == "1":
                out_args[0] = "Detailed"
            write_out_idf_lines_as_single_line(dif_unit, object_name, cur_args, out_args, field_names, field_units, globals_state)
        
        elif obj_upper == "REPORT VARIABLE":
            if out_args[0].rstrip() == blank:
                out_args[0] = "*"
            write_out_idf_lines_as_single_line(dif_unit, object_name, cur_args, out_args, field_names, field_units, globals_state)
        
        elif obj_upper == "SURFACE:HEATTRANSFER" or obj_upper == "SURFACE:HEATTRANSFER:SUB":
            var n_vert = 0
            if globals_state.make_upper_case(out_args[9]).strip() == "AUTOCALCULATE":
                n_vert = (cur_args - 10) // 3
            elif out_args[9].rstrip() == "":
                n_vert = (cur_args - 10) // 3
            else:
                var num_val = 0.0
                var err_flag = False
                num_val, err_flag = globals_state.process_number(out_args[9])
                n_vert = int(num_val)
                if err_flag:
                    n_vert = (cur_args - 10) // 3
                    out_args[9] = "Autocalculate"
                    globals_state.show_warning_error(
                        "For " + object_name + " named '" + out_args[0] + "', "
                        + "Number of vertices is not a number, defaulting to Autocalculate (N="
                        + globals_state.trim_sig_digits(n_vert) + ")",
                        globals_state.get_auditf(),
                    )
                else:
                    out_args[9] = globals_state.trim_sig_digits(n_vert)
            
            write_out_partial_idf_lines(dif_unit, object_name, 10, out_args, field_names, field_units, globals_state)
            
            var v_arg = 10
            for arg in range(1, n_vert + 1):
                var l_string = ",  !- " if arg != n_vert else ";  !- "
                var v_string = String(arg)
                
                if globals_state.get_with_units() and field_units[v_arg].rstrip() != blank:
                    dif_unit.write(
                        "    " + out_args[v_arg].rstrip() + "," + out_args[v_arg + 1].rstrip() + ","
                        + out_args[v_arg + 2].rstrip() + l_string + vertex_string + " " + v_string + " {"
                        + field_units[v_arg].rstrip() + "}\n"
                    )
                else:
                    dif_unit.write(
                        "    " + out_args[v_arg].rstrip() + "," + out_args[v_arg + 1].rstrip() + ","
                        + out_args[v_arg + 2].rstrip() + l_string + vertex_string + " " + v_string + "\n"
                    )
                v_arg += 3
            
            dif_unit.write("\n")
        
        elif obj_upper == "SURFACE:SHADING:DETACHED" or obj_upper == "SURFACE:SHADING:DETACHED:FIXED" or obj_upper == "SURFACE:SHADING:DETACHED:BUILDING":
            var n_vert = 0
            if globals_state.make_upper_case(out_args[2]).strip() == "AUTOCALCULATE":
                n_vert = (cur_args - 3) // 3
            elif out_args[2].rstrip() == "":
                n_vert = (cur_args - 3) // 3
            else:
                var num_val = 0.0
                var err_flag = False
                num_val, err_flag = globals_state.process_number(out_args[2])
                n_vert = int(num_val)
                if err_flag:
                    n_vert = (cur_args - 3) // 3
                    out_args[2] = "Autocalculate"
                    globals_state.show_warning_error(
                        "For " + object_name + " named '" + out_args[0] + "', "
                        + "Number of vertices is not a number, defaulting to Autocalculate (N="
                        + globals_state.trim_sig_digits(n_vert) + ")",
                        globals_state.get_auditf(),
                    )
                else:
                    out_args[2] = globals_state.trim_sig_digits(n_vert)
            
            if object_name == "SURFACE:SHADING:DETACHED":
                write_out_partial_idf_lines(dif_unit, "SURFACE:SHADING:DETACHED:FIXED", 3, out_args, field_names, field_units, globals_state)
            else:
                write_out_partial_idf_lines(dif_unit, object_name, 3, out_args, field_names, field_units, globals_state)
            
            v_arg = 3
            for arg in range(1, n_vert + 1):
                var l_string = ",  !- " if arg != n_vert else ";  !- "
                var v_string = String(arg)
                
                if globals_state.get_with_units() and field_units[v_arg].rstrip() != blank:
                    dif_unit.write(
                        "    " + out_args[v_arg].rstrip() + "," + out_args[v_arg + 1].rstrip() + ","
                        + out_args[v_arg + 2].rstrip() + l_string + vertex_string + " " + v_string + " {"
                        + field_units[v_arg].rstrip() + "}\n"
                    )
                else:
                    dif_unit.write(
                        "    " + out_args[v_arg].rstrip() + "," + out_args[v_arg + 1].rstrip() + ","
                        + out_args[v_arg + 2].rstrip() + l_string + vertex_string + " " + v_string + "\n"
                    )
                v_arg += 3
            
            dif_unit.write("\n")
        
        elif obj_upper == "SURFACE:SHADING:ATTACHED":
            var n_vert = 0
            if globals_state.make_upper_case(out_args[3]).strip() == "AUTOCALCULATE":
                n_vert = (cur_args - 4) // 3
            elif out_args[3].rstrip() == "":
                n_vert = (cur_args - 4) // 3
            else:
                var num_val = 0.0
                var err_flag = False
                num_val, err_flag = globals_state.process_number(out_args[3])
                n_vert = int(num_val)
                if err_flag:
                    n_vert = (cur_args - 4) // 3
                    out_args[3] = "Autocalculate"
                    globals_state.show_warning_error(
                        "For " + object_name + " named '" + out_args[0] + "', "
                        + "Number of vertices is not a number, defaulting to Autocalculate (N="
                        + globals_state.trim_sig_digits(n_vert) + ")",
                        globals_state.get_auditf(),
                    )
                else:
                    out_args[3] = globals_state.trim_sig_digits(n_vert)
            
            write_out_partial_idf_lines(dif_unit, object_name, 4, out_args, field_names, field_units, globals_state)
            
            v_arg = 4
            for arg in range(1, n_vert + 1):
                var l_string = ",  !- " if arg != n_vert else ";  !- "
                var v_string = String(arg)
                
                if globals_state.get_with_units() and field_units[v_arg].rstrip() != blank:
                    dif_unit.write(
                        "    " + out_args[v_arg].rstrip() + "," + out_args[v_arg + 1].rstrip() + ","
                        + out_args[v_arg + 2].rstrip() + l_string + vertex_string + " " + v_string + " {"
                        + field_units[v_arg].rstrip() + "}\n"
                    )
                else:
                    dif_unit.write(
                        "    " + out_args[v_arg].rstrip() + "," + out_args[v_arg + 1].rstrip() + ","
                        + out_args[v_arg + 2].rstrip() + l_string + vertex_string + " " + v_string + "\n"
                    )
                v_arg += 3
            
            dif_unit.write("\n")
        
        elif obj_upper == "WINDOWGLASSSPECTRALDATA":
            write_out_partial_idf_lines(dif_unit, object_name, 1, out_args, field_names, field_units, globals_state)
            var arg = 1
            while arg < cur_args:
                var vargs = arg
                var varge = min(arg + 3, cur_args - 1)
                var l_string = "," if varge != cur_args - 1 else ";"
                
                var line_out = "    " + out_args[vargs].rstrip()
                for v_arg in range(vargs + 1, varge + 1):
                    line_out += "," + out_args[v_arg]
                
                line_out += l_string
                dif_unit.write(line_out.rstrip() + "\n")
                arg += 4
            
            dif_unit.write("\n")
        
        elif obj_upper == "FLUIDPROPERTYTEMPERATURES":
            write_out_partial_idf_lines(dif_unit, object_name, 1, out_args, field_names, field_units, globals_state)
            var arg = 1
            while arg < cur_args:
                var vargs = arg
                var varge = min(arg + 6, cur_args - 1)
                var l_string = "," if varge != cur_args - 1 else ";"
                
                var line_out = "    " + out_args[vargs].rstrip()
                for v_arg in range(vargs + 1, varge + 1):
                    line_out += "," + out_args[v_arg]
                
                line_out += l_string
                dif_unit.write(line_out.rstrip() + "\n")
                arg += 7
            
            dif_unit.write("\n")
        
        elif obj_upper == "FLUIDPROPERTYSATURATED" or obj_upper == "FLUIDPROPERTYSUPERHEATED" or obj_upper == "FLUIDPROPERTYCONCENTRATION":
            write_out_partial_idf_lines(dif_unit, object_name, 4, out_args, field_names, field_units, globals_state)
            var arg = 4
            while arg < cur_args:
                var vargs = arg
                var varge = min(arg + 6, cur_args - 1)
                var l_string = "," if varge != cur_args - 1 else ";"
                
                var line_out = "    " + out_args[vargs].rstrip()
                for v_arg in range(vargs + 1, varge + 1):
                    line_out += "," + out_args[v_arg]
                
                line_out += l_string
                dif_unit.write(line_out.rstrip() + "\n")
                arg += 7
            
            dif_unit.write("\n")
        
        else:
            written = False
    
    else:
        if obj_upper == "VERSION" or obj_upper == "SURFACECONVECTIONALGORITHM:INSIDE" or obj_upper == "SURFACECONVECTIONALGORITHM:OUTSIDE" or obj_upper == "HEATBALANCEALGORITHM" or obj_upper == "ZONECAPACITANCEMULTIPLIER" or obj_upper == "TIMESTEP" or obj_upper == "SITE:GROUNDTEMPERATURE:BUILDINGSURFACE" or obj_upper == "SITE:GROUNDTEMPERATURE:FCFACTORMETHOD" or obj_upper == "SITE:GROUNDTEMPERATURE:SHALLOW" or obj_upper == "SITE:GROUNDTEMPERATURE:DEEP" or obj_upper == "SITE:GROUNDREFLECTANCE" or obj_upper == "OUTPUT:METER" or obj_upper == "OUTPUT:METER:METERFILEONLY" or obj_upper == "OUTPUT:METER:CUMULATIVE" or obj_upper == "OUTPUT:METER:CUMULATIVE:METERFILEONLY" or obj_upper == "OUTPUT:VARIABLEDICTIONARY" or obj_upper == "OUTPUT:SURFACES:LIST" or obj_upper == "OUTPUT:SURFACES:DRAWING" or obj_upper == "OUTPUT:SCHEDULES" or obj_upper == "OUTPUT:CONSTRUCTIONS" or obj_upper == "SCHEDULE:CONSTANT":
            write_out_idf_lines_as_single_line(dif_unit, object_name, cur_args, out_args, field_names, field_units, globals_state)
        
        elif obj_upper == "SCHEDULE:COMPACT":
            compact_warning = False
            write_out_partial_idf_lines(dif_unit, object_name, 2, out_args, field_names, field_units, globals_state)
            var arg = 2
            while arg < cur_args:
                if globals_state.same_string(out_args[arg][:5], "Until"):
                    var l_string = "," if arg + 1 != cur_args else ";"
                    
                    if arg == cur_args - 1:
                        l_string = ";"
                        compact_warning = True
                    
                    var line_out = "    " + out_args[arg].rstrip() + "," + out_args[arg + 1].rstrip() + l_string
                    if len(line_out.rstrip()) > 29:
                        dif_unit.write(line_out.rstrip() + " !- " + field_names[arg].rstrip() + "\n")
                    else:
                        line_out = line_out.rstrip()
                        var padding = 30 - len(line_out)
                        if padding > 0:
                            for _ in range(padding):
                                line_out += " "
                        line_out += "!- " + field_names[arg].rstrip()
                        dif_unit.write(line_out.rstrip() + "\n")
                    
                    arg += 2
                else:
                    var l_string = "," if arg != cur_args - 1 else ";"
                    var line_out = "    " + out_args[arg].rstrip() + l_string
                    if len(line_out.rstrip()) > 29:
                        dif_unit.write(line_out.rstrip() + " !- " + field_names[arg].rstrip() + "\n")
                    else:
                        line_out = line_out.rstrip()
                        var padding = 30 - len(line_out)
                        if padding > 0:
                            for _ in range(padding):
                                line_out += " "
                        line_out += "!- " + field_names[arg].rstrip()
                        dif_unit.write(line_out.rstrip() + "\n")
                    
                    arg += 1
            
            dif_unit.write("\n")
            if compact_warning:
                write_preprocessor_object(
                    dif_unit,
                    globals_state.get_progname_conversion(),
                    "Warning",
                    "Compact Schedule object=\"" + out_args[0].rstrip() + "\" terminated early.  Check for accuracy.",
                )
        
        elif obj_upper == "OUTPUT:VARIABLE":
            if out_args[0].rstrip() == blank:
                out_args[0] = "*"
            write_out_idf_lines_as_single_line(dif_unit, object_name, cur_args, out_args, field_names, field_units, globals_state)
        
        elif obj_upper == "BUILDINGSURFACE:DETAILED":
            var n_vert_field_num = 10 + surface_space_field_shift
            var n_vert = 0
            if globals_state.make_upper_case(out_args[n_vert_field_num - 1]).strip() == "AUTOCALCULATE":
                n_vert = (cur_args - n_vert_field_num) // 3
            elif out_args[n_vert_field_num - 1].rstrip() == "":
                n_vert = (cur_args - n_vert_field_num) // 3
            else:
                var num_val = 0.0
                var err_flag = False
                num_val, err_flag = globals_state.process_number(out_args[n_vert_field_num - 1])
                n_vert = int(num_val)
                if err_flag:
                    n_vert = (cur_args - n_vert_field_num) // 3
                    out_args[n_vert_field_num - 1] = "Autocalculate"
                    globals_state.show_warning_error(
                        "For " + object_name + " named '" + out_args[0] + "', "
                        + "Number of vertices is not a number, defaulting to Autocalculate (N="
                        + globals_state.trim_sig_digits(n_vert) + ")",
                        globals_state.get_auditf(),
                    )
                else:
                    out_args[n_vert_field_num - 1] = globals_state.trim_sig_digits(n_vert)
            
            write_out_partial_idf_lines(dif_unit, object_name, n_vert_field_num, out_args, field_names, field_units, globals_state)
            
            v_arg = n_vert_field_num
            for arg in range(1, n_vert + 1):
                var l_string = ",  !- " if arg != n_vert else ";  !- "
                var v_string = String(arg)
                
                if globals_state.get_with_units() and field_units[v_arg].rstrip() != blank:
                    dif_unit.write(
                        "    " + out_args[v_arg].rstrip() + "," + out_args[v_arg + 1].rstrip() + ","
                        + out_args[v_arg + 2].rstrip() + l_string + vertex_string + " " + v_string + " {"
                        + field_units[v_arg].rstrip() + "}\n"
                    )
                else:
                    dif_unit.write(
                        "    " + out_args[v_arg].rstrip() + "," + out_args[v_arg + 1].rstrip() + ","
                        + out_args[v_arg + 2].rstrip() + l_string + vertex_string + " " + v_string + "\n"
                    )
                v_arg += 3
            
            dif_unit.write("\n")
        
        elif obj_upper == "FENESTRATIONSURFACE:DETAILED":
            if globals_state.get_version_num() < 9.0:
                var n_vert = 0
                if globals_state.make_upper_case(out_args[9]).strip() == "AUTOCALCULATE":
                    n_vert = (cur_args - 10) // 3
                elif out_args[9].rstrip() == "":
                    n_vert = (cur_args - 10) // 3
                else:
                    var num_val = 0.0
                    var err_flag = False
                    num_val, err_flag = globals_state.process_number(out_args[9])
                    n_vert = int(num_val)
                    if err_flag:
                        n_vert = (cur_args - 10) // 3
                        out_args[9] = "Autocalculate"
                        globals_state.show_warning_error(
                            "For " + object_name + " named '" + out_args[0] + "', "
                            + "Number of vertices is not a number, defaulting to Autocalculate (N="
                            + globals_state.trim_sig_digits(n_vert) + ")",
                            globals_state.get_auditf(),
                        )
                    else:
                        out_args[9] = globals_state.trim_sig_digits(n_vert)
                
                write_out_partial_idf_lines(dif_unit, object_name, 10, out_args, field_names, field_units, globals_state)
                
                v_arg = 10
                for arg in range(1, n_vert + 1):
                    var l_string = ",  !- " if arg != n_vert else ";  !- "
                    var v_string = String(arg)
                    
                    if globals_state.get_with_units() and field_units[v_arg].rstrip() != blank:
                        dif_unit.write(
                            "    " + out_args[v_arg].rstrip() + "," + out_args[v_arg + 1].rstrip() + ","
                            + out_args[v_arg + 2].rstrip() + l_string + vertex_string + " " + v_string + " {"
                            + field_units[v_arg].rstrip() + "}\n"
                        )
                    else:
                        dif_unit.write(
                            "    " + out_args[v_arg].rstrip() + "," + out_args[v_arg + 1].rstrip() + ","
                            + out_args[v_arg + 2].rstrip() + l_string + vertex_string + " " + v_string + "\n"
                        )
                    v_arg += 3
                
                dif_unit.write("\n")
            else:
                var n_vert = 0
                if globals_state.make_upper_case(out_args[8]).strip() == "AUTOCALCULATE":
                    n_vert = (cur_args - 9) // 3
                elif out_args[8].rstrip() == "":
                    n_vert = (cur_args - 9) // 3
                else:
                    var num_val = 0.0
                    var err_flag = False
                    num_val, err_flag = globals_state.process_number(out_args[8])
                    n_vert = int(num_val)
                    if err_flag:
                        n_vert = (cur_args - 9) // 3
                        out_args[8] = "Autocalculate"
                        globals_state.show_warning_error(
                            "For " + object_name + " named '" + out_args[0] + "', "
                            + "Number of vertices is not a number, defaulting to Autocalculate (N="
                            + globals_state.trim_sig_digits(n_vert) + ")",
                            globals_state.get_auditf(),
                        )
                    else:
                        out_args[8] = globals_state.trim_sig_digits(n_vert)
                
                write_out_partial_idf_lines(dif_unit, object_name, 9, out_args, field_names, field_units, globals_state)
                
                v_arg = 9
                for arg in range(1, n_vert + 1):
                    var l_string = ",  !- " if arg != n_vert else ";  !- "
                    var v_string = String(arg)
                    
                    if globals_state.get_with_units() and field_units[v_arg].rstrip() != blank:
                        dif_unit.write(
                            "    " + out_args[v_arg].rstrip() + "," + out_args[v_arg + 1].rstrip() + ","
                            + out_args[v_arg + 2].rstrip() + l_string + vertex_string + " " + v_string + " {"
                            + field_units[v_arg].rstrip() + "}\n"
                        )
                    else:
                        dif_unit.write(
                            "    " + out_args[v_arg].rstrip() + "," + out_args[v_arg + 1].rstrip() + ","
                            + out_args[v_arg + 2].rstrip() + l_string + vertex_string + " " + v_string + "\n"
                        )
                    v_arg += 3
                
                dif_unit.write("\n")
        
        elif obj_upper == "WALL:DETAILED" or obj_upper == "ROOFCEILING:DETAILED" or obj_upper == "FLOOR:DETAILED":
            var n_vert_field_num = 9 + surface_space_field_shift
            var n_vert = 0
            if globals_state.make_upper_case(out_args[n_vert_field_num - 1]).strip() == "AUTOCALCULATE":
                n_vert = (cur_args - n_vert_field_num) // 3
            elif out_args[n_vert_field_num - 1].rstrip() == "":
                n_vert = (cur_args - n_vert_field_num) // 3
            else:
                var num_val = 0.0
                var err_flag = False
                num_val, err_flag = globals_state.process_number(out_args[n_vert_field_num - 1])
                n_vert = int(num_val)
                if err_flag:
                    n_vert = (cur_args - n_vert_field_num) // 3
                    out_args[n_vert_field_num - 1] = "Autocalculate"
                    globals_state.show_warning_error(
                        "For " + object_name + " named '" + out_args[0] + "', "
                        + "Number of vertices is not a number, defaulting to Autocalculate (N="
                        + globals_state.trim_sig_digits(n_vert) + ")",
                        globals_state.get_auditf(),
                    )
                else:
                    out_args[n_vert_field_num - 1] = globals_state.trim_sig_digits(n_vert)
            
            write_out_partial_idf_lines(dif_unit, object_name, n_vert_field_num, out_args, field_names, field_units, globals_state)
            
            v_arg = n_vert_field_num
            for arg in range(1, n_vert + 1):
                var l_string = ",  !- " if arg != n_vert else ";  !- "
                var v_string = String(arg)
                
                if globals_state.get_with_units() and field_units[v_arg].rstrip() != blank:
                    dif_unit.write(
                        "    " + out_args[v_arg].rstrip() + "," + out_args[v_arg + 1].rstrip() + ","
                        + out_args[v_arg + 2].rstrip() + l_string + vertex_string + " " + v_string + " {"
                        + field_units[v_arg].rstrip() + "}\n"
                    )
                else:
                    dif_unit.write(
                        "    " + out_args[v_arg].rstrip() + "," + out_args[v_arg + 1].rstrip() + ","
                        + out_args[v_arg + 2].rstrip() + l_string + vertex_string + " " + v_string + "\n"
                    )
                v_arg += 3
            
            dif_unit.write("\n")
        
        elif obj_upper == "SHADING:SITE:DETAILED" or obj_upper == "SHADING:BUILDING:DETAILED":
            var n_vert = 0
            if globals_state.make_upper_case(out_args[2]).strip() == "AUTOCALCULATE":
                n_vert = (cur_args - 3) // 3
            elif out_args[2].rstrip() == "":
                n_vert = (cur_args - 3) // 3
            else:
                var num_val = 0.0
                var err_flag = False
                num_val, err_flag = globals_state.process_number(out_args[2])
                n_vert = int(num_val)
                if err_flag:
                    n_vert = (cur_args - 3) // 3
                    out_args[2] = "Autocalculate"
                    globals_state.show_warning_error(
                        "For " + object_name + " named '" + out_args[0] + "', "
                        + "Number of vertices is not a number, defaulting to Autocalculate (N="
                        + globals_state.trim_sig_digits(n_vert) + ")",
                        globals_state.get_auditf(),
                    )
                else:
                    out_args[2] = globals_state.trim_sig_digits(n_vert)
            
            write_out_partial_idf_lines(dif_unit, object_name, 3, out_args, field_names, field_units, globals_state)
            
            v_arg = 3
            for arg in range(1, n_vert + 1):
                var l_string = ",  !- " if arg != n_vert else ";  !- "
                var v_string = String(arg)
                
                if globals_state.get_with_units() and field_units[v_arg].rstrip() != blank:
                    dif_unit.write(
                        "    " + out_args[v_arg].rstrip() + "," + out_args[v_arg + 1].rstrip() + ","
                        + out_args[v_arg + 2].rstrip() + l_string + vertex_string + " " + v_string + " {"
                        + field_units[v_arg].rstrip() + "}\n"
                    )
                else:
                    dif_unit.write(
                        "    " + out_args[v_arg].rstrip() + "," + out_args[v_arg + 1].rstrip() + ","
                        + out_args[v_arg + 2].rstrip() + l_string + vertex_string + " " + v_string + "\n"
                    )
                v_arg += 3
            
            dif_unit.write("\n")
        
        elif obj_upper == "SHADING:ZONE:DETAILED":
            var n_vert = 0
            if globals_state.make_upper_case(out_args[3]).strip() == "AUTOCALCULATE":
                n_vert = (cur_args - 4) // 3
            elif out_args[3].rstrip() == "":
                n_vert = (cur_args - 4) // 3
            else:
                var num_val = 0.0
                var err_flag = False
                num_val, err_flag = globals_state.process_number(out_args[3])
                n_vert = int(num_val)
                if err_flag:
                    n_vert = (cur_args - 4) // 3
                    out_args[3] = "Autocalculate"
                    globals_state.show_warning_error(
                        "For " + object_name + " named '" + out_args[0] + "', "
                        + "Number of vertices is not a number, defaulting to Autocalculate (N="
                        + globals_state.trim_sig_digits(n_vert) + ")",
                        globals_state.get_auditf(),
                    )
                else:
                    out_args[3] = globals_state.trim_sig_digits(n_vert)
            
            write_out_partial_idf_lines(dif_unit, object_name, 4, out_args, field_names, field_units, globals_state)
            
            v_arg = 4
            for arg in range(1, n_vert + 1):
                var l_string = ",  !- " if arg != n_vert else ";  !- "
                var v_string = String(arg)
                
                if globals_state.get_with_units() and field_units[v_arg].rstrip() != blank:
                    dif_unit.write(
                        "    " + out_args[v_arg].rstrip() + "," + out_args[v_arg + 1].rstrip() + ","
                        + out_args[v_arg + 2].rstrip() + l_string + vertex_string + " " + v_string + " {"
                        + field_units[v_arg].rstrip() + "}\n"
                    )
                else:
                    dif_unit.write(
                        "    " + out_args[v_arg].rstrip() + "," + out_args[v_arg + 1].rstrip() + ","
                        + out_args[v_arg + 2].rstrip() + l_string + vertex_string + " " + v_string + "\n"
                    )
                v_arg += 3
            
            dif_unit.write("\n")
        
        elif obj_upper == "MATERIALPROPERTY:GLAZINGSPECTRALDATA":
            write_out_partial_idf_lines(dif_unit, object_name, 1, out_args, field_names, field_units, globals_state)
            var arg = 1
            while arg < cur_args:
                var vargs = arg
                var varge = min(arg + 3, cur_args - 1)
                var l_string = "," if varge != cur_args - 1 else ";"
                
                var line_out = "    " + out_args[vargs].rstrip()
                for v_arg in range(vargs + 1, varge + 1):
                    line_out += "," + out_args[v_arg]
                
                line_out += l_string
                dif_unit.write(line_out.rstrip() + "\n")
                arg += 4
            
            dif_unit.write("\n")
        
        elif obj_upper == "FLUIDPROPERTIES:TEMPERATURES":
            write_out_partial_idf_lines(dif_unit, object_name, 1, out_args, field_names, field_units, globals_state)
            var arg = 1
            while arg < cur_args:
                var vargs = arg
                var varge = min(arg + 6, cur_args - 1)
                var l_string = "," if varge != cur_args - 1 else ";"
                
                var line_out = "    " + out_args[vargs].rstrip()
                for v_arg in range(vargs + 1, varge + 1):
                    line_out += "," + out_args[v_arg]
                
                line_out += l_string
                dif_unit.write(line_out.rstrip() + "\n")
                arg += 7
            
            dif_unit.write("\n")
        
        elif obj_upper == "FLUIDPROPERTIES:SATURATED" or obj_upper == "FLUIDPROPERTIES:SUPERHEATED" or obj_upper == "FLUIDPROPERTIES:CONCENTRATION":
            write_out_partial_idf_lines(dif_unit, object_name, 4, out_args, field_names, field_units, globals_state)
            var arg = 4
            while arg < cur_args:
                var vargs = arg
                var varge = min(arg + 6, cur_args - 1)
                var l_string = "," if varge != cur_args - 1 else ";"
                
                var line_out = "    " + out_args[vargs].rstrip()
                for v_arg in range(vargs + 1, varge + 1):
                    line_out += "," + out_args[v_arg]
                
                line_out += l_string
                dif_unit.write(line_out.rstrip() + "\n")
                arg += 7
            
            dif_unit.write("\n")
        
        else:
            written = False
    
    return written


fn read_renamed_objects(file_name: String, globals_state: VCompareGlobalsProtocol) -> None:
    """Read renamed objects from file."""
    
    if not file_exists(file_name):
        globals_state.show_fatal_error("File=" + file_name + " not found.  Transition terminates without completing.")
        return
    
    var cur_num = 0
    
    try:
        with open(file_name, "r") as f:
            var line = f.readline().rstrip("\n")
            var num_objects = int(line)
            
            var old_names = DynamicVector[String](num_objects)
            var new_names = DynamicVector[String](num_objects)
            
            for line in f:
                line = line.rstrip("\n")
                var tab_index = line.find("\t")
                if tab_index > 0:
                    cur_num += 1
                    old_names[cur_num - 1] = line[:tab_index]
                    new_names[cur_num - 1] = line[tab_index + 1:]
                else:
                    globals_state.get_auditf().write("file=" + file_name + " blank line after " + String(cur_num) + " renamed objects read\n")
                    break
    
    except:
        globals_state.get_auditf().write("file=" + file_name + " not found\n")
        globals_state.show_fatal_error("File=" + file_name + " not found.  Transition terminates without completing.")


fn replace_renamed_object_fields(
    old_name: String,
    globals_state: VCompareGlobalsProtocol,
) -> (String, Bool):
    """Replace renamed object fields. Returns (new_name, err_flag)."""
    
    var err_flag = False
    var found_item = globals_state.find_item_in_sorted_list(
        old_name,
        globals_state.get_old_object_names(),
        globals_state.get_num_renamed_objects(),
    )
    
    if found_item > 0:
        return globals_state.get_new_object_names()[found_item - 1], False
    else:
        return old_name, True


fn is_valid_output_units(string: String) -> Bool:
    """Check if string is valid output units."""
    
    var valid_output_units = InlineArray[String, 41](
        "%",
        "A",
        "ach",
        "Ah",
        "C",
        "cd/m2",
        "deg",
        "deltaC",
        "hr",
        "J",
        "J/kg",
        "J/kgWater",
        "J/m2",
        "K/m",
        "kg",
        "kg/kg",
        "kg/m3",
        "kg/s",
        "kgWater/kgDryAir",
        "kgWater/s",
        "kmol/s",
        "L",
        "lum/W",
        "lux",
        "m",
        "m/s",
        "m2",
        "m3",
        "m3/s",
        "Pa",
        "ppm",
        "rad",
        "s",
        "units",
        "V",
        "W",
        "W/K",
        "W/m2",
        "W/m2-C",
        "W/m2-K",
        "W/W",
    )
    
    var s_trimmed = string.rstrip()
    for i in range(41):
        if s_trimmed == valid_output_units[i]:
            return True
    
    return False
