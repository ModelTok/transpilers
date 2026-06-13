from collections import List
from typing import Optional

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state container (source: EnergyPlus.Data.EnergyPlusData)
# - GLHEVertProps: struct (source: EnergyPlus.GroundHeatExchangers.Properties)
# - ShowFatalError: function (source: EnergyPlus.UtilityRoutines)
# - ShowSevereError: function (source: EnergyPlus.UtilityRoutines)
# - format: function (source: EnergyPlus)
# - makeUPPER: function (source: EnergyPlus.UtilityRoutines)

struct MyCartesian:
    var x: Float64
    var y: Float64
    var z: Float64
    
    fn __init__(inout self, x: Float64 = 0.0, y: Float64 = 0.0, z: Float64 = 0.0):
        self.x = x
        self.y = y
        self.z = z

struct GLHEVertSingle:
    var name: String
    var xLoc: Float64
    var yLoc: Float64
    var dl_i: Float64
    var dl_ii: Float64
    var dl_j: Float64
    var props: object
    var pointLocations_i: List[MyCartesian]
    var pointLocations_ii: List[MyCartesian]
    var pointLocations_j: List[MyCartesian]
    
    alias MODULE_NAME = "GroundHeatExchanger:Vertical:Single"
    
    fn __init__(inout self, state: object, obj_name: String, j: object):
        # Check for duplicates
        for existing_obj in state.dataGroundHeatExchanger.singleBoreholesVector:
            if obj_name == existing_obj.name:
                ShowFatalError(state, format(
                    "Invalid input for {} object: Duplicate name found: {}",
                    Self.MODULE_NAME,
                    existing_obj.name
                ))
        
        self.name = obj_name
        self.props = GLHEVertProps.GetVertProps(
            state,
            makeUPPER(j["ghe_vertical_properties_object_name"])
        )
        self.xLoc = j["x_location"]
        self.yLoc = j["y_location"]
        self.dl_i = 0.0
        self.dl_ii = 0.0
        self.dl_j = 0.0
        self.pointLocations_i = List[MyCartesian]()
        self.pointLocations_ii = List[MyCartesian]()
        self.pointLocations_j = List[MyCartesian]()
    
    @staticmethod
    fn GetSingleBH(state: object, object_name: String) -> Optional[object]:
        # Check if this instance of this model has already been retrieved
        for obj in state.dataGroundHeatExchanger.singleBoreholesVector:
            if obj.name == object_name:
                return Optional(obj)
        
        ShowSevereError(state, format(
            "Object=GroundHeatExchanger:Vertical:Single, Name={} - not found.",
            object_name
        ))
        ShowFatalError(state, "Preceding errors cause program termination")
