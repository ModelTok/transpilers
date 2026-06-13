from typing import Optional, List, Any

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state container (source: EnergyPlus.Data.EnergyPlusData)
# - GLHEVertProps: from GroundHeatExchangers.Properties
# - ShowFatalError: from UtilityRoutines
# - ShowSevereError: from UtilityRoutines
# - format: from EnergyPlus
# - Util.makeUPPER: from UtilityRoutines

class MyCartesian:
    def __init__(self, x: float = 0.0, y: float = 0.0, z: float = 0.0):
        self.x = x
        self.y = y
        self.z = z

class GLHEVertSingle:
    MODULE_NAME = "GroundHeatExchanger:Vertical:Single"
    
    def __init__(self, state: Any, obj_name: str, j: dict):
        from EnergyPlus.UtilityRoutines import ShowFatalError
        from EnergyPlus.GroundHeatExchangers.Properties import GLHEVertProps
        from EnergyPlus.UtilityRoutines import makeUPPER
        from EnergyPlus import format
        
        # Check for duplicates
        for existing_obj in state.dataGroundHeatExchanger.singleBoreholesVector:
            if obj_name == existing_obj.name:
                ShowFatalError(
                    state,
                    format(
                        "Invalid input for {} object: Duplicate name found: {}",
                        self.MODULE_NAME,
                        existing_obj.name
                    )
                )
        
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
        self.pointLocations_i: List[MyCartesian] = []
        self.pointLocations_ii: List[MyCartesian] = []
        self.pointLocations_j: List[MyCartesian] = []
    
    @staticmethod
    def GetSingleBH(state: Any, object_name: str) -> Optional['GLHEVertSingle']:
        from EnergyPlus.UtilityRoutines import ShowFatalError, ShowSevereError
        from EnergyPlus import format
        
        # Check if this instance of this model has already been retrieved
        for obj in state.dataGroundHeatExchanger.singleBoreholesVector:
            if obj.name == object_name:
                return obj
        
        ShowSevereError(
            state,
            format(
                "Object=GroundHeatExchanger:Vertical:Single, Name={} - not found.",
                object_name
            )
        )
        ShowFatalError(state, "Preceding errors cause program termination")
