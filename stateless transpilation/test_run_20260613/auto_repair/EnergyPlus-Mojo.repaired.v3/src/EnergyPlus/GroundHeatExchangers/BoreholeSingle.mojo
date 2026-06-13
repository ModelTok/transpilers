from ..Data.EnergyPlusData import EnergyPlusData
from BoreholeSingle import GLHEVertSingle, MyCartesian
from Properties import GLHEVertProps
from ..GroundHeatExchangers.State import State
from ..UtilityRoutines import ShowFatalError, ShowSevereError, format, makeUPPER
from memory import Pointer
from utils import String
from vector import DynamicVector

@value
struct GLHEVertSingle:
    var name: String
    var xLoc: Float64
    var yLoc: Float64
    var dl_i: Float64
    var dl_ii: Float64
    var dl_j: Float64
    var props: Pointer[GLHEVertProps]
    var pointLocations_i: DynamicVector[MyCartesian]
    var pointLocations_ii: DynamicVector[MyCartesian]
    var pointLocations_j: DynamicVector[MyCartesian]

    def __init__(inout self, state: EnergyPlusData, objName: String, j: Dict[String, Any]):
        for existingObj in state.dataGroundHeatExchanger.singleBoreholesVector:
            if objName == existingObj[].name:
                ShowFatalError(state, format("Invalid input for {} object: Duplicate name found: {}", "GroundHeatExchanger:Vertical:Single", existingObj[].name))
        self.name = objName
        self.props = GLHEVertProps.GetVertProps(state, makeUPPER(j["ghe_vertical_properties_object_name"] as String))
        self.xLoc = j["x_location"] as Float64
        self.yLoc = j["y_location"] as Float64
        self.dl_i = 0.0
        self.dl_ii = 0.0
        self.dl_j = 0.0

    @staticmethod
    def GetSingleBH(state: EnergyPlusData, objectName: String) -> Pointer[GLHEVertSingle]:
        var thisObj: Optional[Pointer[GLHEVertSingle]] = None
        for existingObj in state.dataGroundHeatExchanger.singleBoreholesVector:
            if existingObj[].name == objectName:
                thisObj = existingObj
                break
        if thisObj:
            return thisObj.value()
        ShowSevereError(state, format("Object=GroundHeatExchanger:Vertical:Single, Name={} - not found.", objectName))
        ShowFatalError(state, "Preceding errors cause program termination")
        return Pointer[GLHEVertSingle]()  # unreachable but required for return type

@value
struct MyCartesian:
    var x: Float64
    var y: Float64
    var z: Float64

    def __init__(inout self):
        self.x = 0.0
        self.y = 0.0
        self.z = 0.0