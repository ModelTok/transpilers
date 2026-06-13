# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state container (EnergyPlus.Data.EnergyPlusData)
# - ShowWarningError: error reporting function (EnergyPlus.UtilityRoutines)

from EnergyPlus.UtilityRoutines import ShowWarningError

DEFAULT_COLORNO = [3, 43, 143, 143, 45, 8, 15, 195, 9, 13, 174, 143, 143, 10, 5]

class ColorNo:
    INVALID = -1
    TEXT = 0
    WALL = 1
    WINDOW = 2
    GLASS_DOOR = 3
    DOOR = 4
    FLOOR = 5
    ROOF = 6
    SHD_DET_BLDG = 7
    SHD_DET_FIX = 8
    SHD_ATT = 9
    PV = 10
    TDD_DOME = 11
    TDD_DIFFUSER = 12
    DAYL_SENSOR_1 = 13
    DAYL_SENSOR_2 = 14
    NUM = 15

COLOR_KEYS = [
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
]

def get_enum_value(keys, search_str):
    try:
        return keys.index(search_str)
    except ValueError:
        return -1

def same_string(str1, str2):
    return str1.upper() == str2.upper()

def make_upper(s):
    return s.upper()

class SurfaceColorData:
    def __init__(self):
        self.dxfcolorno = DEFAULT_COLORNO.copy()
    
    def init_constant_state(self, state):
        pass
    
    def init_state(self, state):
        pass
    
    def clear_state(self):
        self.dxfcolorno = DEFAULT_COLORNO.copy()

def match_and_set_color_text_string(state, string, set_value, color_type):
    if color_type != "DXF":
        return False
    
    found_idx = get_enum_value(COLOR_KEYS, make_upper(string))
    if found_idx == -1:
        return False
    
    state.data_surf_color.dxfcolorno[found_idx] = set_value
    return True

def set_up_scheme_colors(state, scheme_name, color_type):
    state.data_surf_color.dxfcolorno = DEFAULT_COLORNO.copy()
    
    input_processor = state.data_input_processing.input_processor
    
    if "OutputControl:SurfaceColorScheme" not in input_processor.ep_json:
        ShowWarningError(state, f"SetUpSchemeColors: Name={scheme_name} not on input file. Default colors will be used.")
        return
    
    surface_color_schemes = input_processor.ep_json["OutputControl:SurfaceColorScheme"]
    
    matched_scheme = None
    for scheme_key in surface_color_schemes:
        if same_string(scheme_key, scheme_name):
            matched_scheme = scheme_key
            break
    
    if matched_scheme is None:
        ShowWarningError(state, f"SetUpSchemeColors: Name={scheme_name} not on input file. Default colors will be used.")
        return
    
    scheme_fields = surface_color_schemes[matched_scheme]
    input_processor.mark_object_as_used("OutputControl:SurfaceColorScheme", matched_scheme)
    
    numargs = 1
    while True:
        drawing_element_key = f"drawing_element_{numargs}_type"
        color_key = f"color_for_drawing_element_{numargs}"
        
        has_drawing_element = drawing_element_key in scheme_fields
        has_color = color_key in scheme_fields
        
        if not has_drawing_element and not has_color:
            break
        
        drawing_element_field_name = f"Drawing Element {numargs} Type"
        color_field_name = f"Color for Drawing Element {numargs}"
        
        drawing_element = scheme_fields.get(drawing_element_key, "")
        
        if not has_color:
            if drawing_element:
                ShowWarningError(state,
                                f"SetUpSchemeColors: Name={scheme_name}, {drawing_element_field_name}={drawing_element}, "
                                f"{color_field_name} was blank.  Default color retained.")
            numargs += 1
            continue
        
        num_ptr = scheme_fields[color_key]
        if not match_and_set_color_text_string(state, drawing_element, num_ptr, color_type):
            ShowWarningError(state,
                            f"SetUpSchemeColors: Name={scheme_name}, {drawing_element_field_name}={drawing_element}, is invalid.  No color set.")
        
        numargs += 1
