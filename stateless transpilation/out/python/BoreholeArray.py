from typing import Protocol, List, Optional, Any

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state container from EnergyPlus/Data/EnergyPlusData.hh
# - GLHEVertProps: class from EnergyPlus/GroundHeatExchangers/Properties.hh
# - ShowFatalError, ShowSevereError: from EnergyPlus/UtilityRoutines.hh
# - Util.makeUPPER: from EnergyPlus/UtilityRoutines.hh
# - format: from EnergyPlus namespace

class GLHEVertProps(Protocol):
    @staticmethod
    def GetVertProps(state: 'EnergyPlusData', props_name: str) -> 'GLHEVertProps': ...

class GroundHeatExchangerData(Protocol):
    vertArraysVector: List['GLHEVertArray']

class EnergyPlusData(Protocol):
    dataGroundHeatExchanger: GroundHeatExchangerData

def ShowFatalError(state: EnergyPlusData, message: str) -> None: ...
def ShowSevereError(state: EnergyPlusData, message: str) -> None: ...
def makeUPPER(s: str) -> str: ...
def format(template: str, *args: Any) -> str: ...

class GLHEVertArray:
    moduleName: str = "GroundHeatExchanger:Vertical:Array"
    
    def __init__(self, state: EnergyPlusData, obj_name: str, j: dict) -> None:
        self.name: str = ""
        self.numBHinXDirection: int = 0
        self.numBHinYDirection: int = 0
        self.bhSpacing: float = 0.0
        self.props: Optional[GLHEVertProps] = None
        
        for existing_obj in state.dataGroundHeatExchanger.vertArraysVector:
            if obj_name == existing_obj.name:
                ShowFatalError(state, 
                    format("Invalid input for {} object: Duplicate name found: {}", 
                           self.moduleName, existing_obj.name))
        
        self.name = obj_name
        self.props = GLHEVertProps.GetVertProps(state, 
                                                makeUPPER(j["ghe_vertical_properties_object_name"]))
        self.numBHinXDirection = j["number_of_boreholes_in_x_direction"]
        self.numBHinYDirection = j["number_of_boreholes_in_y_direction"]
        self.bhSpacing = j["borehole_spacing"]
    
    @staticmethod
    def GetVertArray(state: EnergyPlusData, object_name: str) -> 'GLHEVertArray':
        for my_obj in state.dataGroundHeatExchanger.vertArraysVector:
            if my_obj.name == object_name:
                return my_obj
        
        ShowSevereError(state, 
            format("Object=GroundHeatExchanger:Vertical:Array, Name={} - not found.", object_name))
        ShowFatalError(state, "Preceding errors cause program termination")
