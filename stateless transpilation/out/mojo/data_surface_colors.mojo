# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state container (EnergyPlus.Data.EnergyPlusData)
# - ShowWarningError: error reporting function (EnergyPlus.UtilityRoutines)

from collections import InlineArray

alias DEFAULT_COLORNO = InlineArray[Int, 15](3, 43, 143, 143, 45, 8, 15, 195, 9, 13, 174, 143, 143, 10, 5)

struct ColorNo:
    alias INVALID = -1
    alias TEXT = 0
    alias WALL = 1
    alias WINDOW = 2
    alias GLASS_DOOR = 3
    alias DOOR = 4
    alias FLOOR = 5
    alias ROOF = 6
    alias SHD_DET_BLDG = 7
    alias SHD_DET_FIX = 8
    alias SHD_ATT = 9
    alias PV = 10
    alias TDD_DOME = 11
    alias TDD_DIFFUSER = 12
    alias DAYL_SENSOR_1 = 13
    alias DAYL_SENSOR_2 = 14
    alias NUM = 15

fn make_color_keys() -> InlineArray[StringLiteral, 15]:
    return InlineArray[StringLiteral, 15](
        "TEXT",
        "WALLS",
        "WINDOWS",
        "GLASSDOORS",
        "DOORS",
        "ROOFS",
        "FLOORS",
        "DETACHEDBUILDINGSHADES",
        "DETACHEDFIXEDSHADES",
        "ATTACHEDBUILDINGSHADES",
        "PHOTOVOLTAICS",
        "TUBULARDAYLIGHTDOMES",
        "TUBULARDAYLIGHTDIFFUSERS",
        "DAYLIGHTREFERENCEPOINT1",
        "DAYLIGHTREFERENCEPOINT2",
    )

alias COLOR_KEYS = make_color_keys()

fn get_enum_value(keys: InlineArray[StringLiteral, 15], search_str: String) -> Int:
    for i in range(15):
        if keys[i] == search_str:
            return i
    return -1

fn same_string(str1: String, str2: String) -> Bool:
    return str1.upper() == str2.upper()

fn make_upper(s: String) -> String:
    return s.upper()

struct SurfaceColorData:
    var dxfcolorno: List[Int]
    
    fn __init__(inout self):
        self.dxfcolorno = List[Int](capacity=15)
        for i in range(15):
            self.dxfcolorno.append(DEFAULT_COLORNO[i])
    
    fn init_constant_state(self, state: EnergyPlusData):
        pass
    
    fn init_state(self, state: EnergyPlusData):
        pass
    
    fn clear_state(inout self):
        self.dxfcolorno.clear()
        for i in range(15):
            self.dxfcolorno.append(DEFAULT_COLORNO[i])

fn match_and_set_color_text_string(state: EnergyPlusData, string: String, set_value: Int, color_type: String) -> Bool:
    if color_type != "DXF":
        return False
    
    var found_idx = get_enum_value(COLOR_KEYS, make_upper(string))
    if found_idx == -1:
        return False
    
    state.data_surf_color.dxfcolorno[found_idx] = set_value
    return True

fn set_up_scheme_colors(state: EnergyPlusData, scheme_name: String, color_type: String):
    state.data_surf_color.dxfcolorno.clear()
    for i in range(15):
        state.data_surf_color.dxfcolorno.append(DEFAULT_COLORNO[i])
    
    var input_processor = state.data_input_processing.input_processor
    
    if "OutputControl:SurfaceColorScheme" not in input_processor.ep_json:
        show_warning_error(state, "SetUpSchemeColors: Name=" + scheme_name + " not on input file. Default colors will be used.")
        return
    
    var surface_color_schemes = input_processor.ep_json["OutputControl:SurfaceColorScheme"]
    
    var matched_scheme: String = ""
    var found_scheme = False
    for scheme_key in surface_color_schemes:
        if same_string(scheme_key, scheme_name):
            matched_scheme = scheme_key
            found_scheme = True
            break
    
    if not found_scheme:
        show_warning_error(state, "SetUpSchemeColors: Name=" + scheme_name + " not on input file. Default colors will be used.")
        return
    
    var scheme_fields = surface_color_schemes[matched_scheme]
    input_processor.mark_object_as_used("OutputControl:SurfaceColorScheme", matched_scheme)
    
    var numargs = 1
    while True:
        var drawing_element_key = "drawing_element_" + str(numargs) + "_type"
        var color_key = "color_for_drawing_element_" + str(numargs)
        
        var has_drawing_element = drawing_element_key in scheme_fields
        var has_color = color_key in scheme_fields
        
        if not has_drawing_element and not has_color:
            break
        
        var drawing_element_field_name = "Drawing Element " + str(numargs) + " Type"
        var color_field_name = "Color for Drawing Element " + str(numargs)
        
        var drawing_element = ""
        if has_drawing_element:
            drawing_element = scheme_fields[drawing_element_key]
        
        if not has_color:
            if len(drawing_element) > 0:
                show_warning_error(state,
                                "SetUpSchemeColors: Name=" + scheme_name + ", " + drawing_element_field_name + "=" + drawing_element + ", "
                                + color_field_name + " was blank.  Default color retained.")
            numargs += 1
            continue
        
        var num_ptr = scheme_fields[color_key]
        if not match_and_set_color_text_string(state, drawing_element, num_ptr, color_type):
            show_warning_error(state,
                            "SetUpSchemeColors: Name=" + scheme_name + ", " + drawing_element_field_name + "=" + drawing_element + ", is invalid.  No color set.")
        
        numargs += 1

fn show_warning_error(state: EnergyPlusData, message: String):
    pass
