# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state container from EnergyPlus/Data/EnergyPlusData.hh
# - GLHEVertProps: struct from EnergyPlus/GroundHeatExchangers/Properties.hh
# - ShowFatalError, ShowSevereError: from EnergyPlus/UtilityRoutines.hh
# - Util.makeUPPER: from EnergyPlus/UtilityRoutines.hh
# - format: from EnergyPlus namespace

struct GLHEVertProps:
    fn GetVertProps(state: Pointer[EnergyPlusData], props_name: String) -> Pointer[GLHEVertProps]:
        pass

struct GroundHeatExchangerData:
    var vertArraysVector: List[Pointer[GLHEVertArray]]

struct EnergyPlusData:
    var dataGroundHeatExchanger: Pointer[GroundHeatExchangerData]

fn ShowFatalError(state: Pointer[EnergyPlusData], message: String):
    pass

fn ShowSevereError(state: Pointer[EnergyPlusData], message: String):
    pass

fn makeUPPER(s: String) -> String:
    pass

fn format(template: String, *args: String) -> String:
    pass

struct GLHEVertArray:
    var moduleName: String
    var name: String
    var numBHinXDirection: Int
    var numBHinYDirection: Int
    var bhSpacing: Float64
    var props: Pointer[GLHEVertProps]
    
    fn __init__(inout self, state: Pointer[EnergyPlusData], obj_name: String, j: Dict[String, String]):
        self.moduleName = "GroundHeatExchanger:Vertical:Array"
        self.name = ""
        self.numBHinXDirection = 0
        self.numBHinYDirection = 0
        self.bhSpacing = 0.0
        self.props = Pointer[GLHEVertProps]()
        
        for existing_obj in state[].dataGroundHeatExchanger[].vertArraysVector:
            if obj_name == existing_obj[].name:
                ShowFatalError(state, 
                    format("Invalid input for {} object: Duplicate name found: {}", 
                           self.moduleName, existing_obj[].name))
        
        self.name = obj_name
        self.props = GLHEVertProps.GetVertProps(state, 
                                                 makeUPPER(j["ghe_vertical_properties_object_name"]))
        self.numBHinXDirection = int(j["number_of_boreholes_in_x_direction"])
        self.numBHinYDirection = int(j["number_of_boreholes_in_y_direction"])
        self.bhSpacing = float(j["borehole_spacing"])

fn GetVertArray(state: Pointer[EnergyPlusData], object_name: String) -> Pointer[GLHEVertArray]:
    for my_obj in state[].dataGroundHeatExchanger[].vertArraysVector:
        if my_obj[].name == object_name:
            return my_obj
    
    ShowSevereError(state, 
        format("Object=GroundHeatExchanger:Vertical:Array, Name={} - not found.", object_name))
    ShowFatalError(state, "Preceding errors cause program termination")
