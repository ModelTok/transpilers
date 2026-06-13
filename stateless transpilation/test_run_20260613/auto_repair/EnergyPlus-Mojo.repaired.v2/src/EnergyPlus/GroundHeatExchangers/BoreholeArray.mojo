from utils.memory import Arc
from python import PythonObject

# Assume JSON type mapping
alias JSON = PythonObject

from ...Data.EnergyPlusData import EnergyPlusData
from ...UtilityRoutines import ShowFatalError, ShowSevereError, format, makeUPPER
from ..State import GroundHeatExchangerData
from ..Properties import GLHEVertProps

module EnergyPlus.GroundHeatExchangers:

    struct GLHEVertArray:
        static let moduleName: String = "GroundHeatExchanger:Vertical:Array"
        var name: String
        var numBHinXDirection: Int = 0
        var numBHinYDirection: Int = 0
        var bhSpacing: Float64 = 0.0
        var props: Arc[GLHEVertProps]

        def __init__(inout self, state: EnergyPlusData, objName: String, j: JSON):
            for existingObj in state.dataGroundHeatExchanger[].vertArraysVector:
                if objName == existingObj[].name:
                    ShowFatalError(state, format("Invalid input for {} object: Duplicate name found: {}", Self.moduleName, existingObj[].name))
            self.name = objName
            self.props = GLHEVertProps.GetVertProps(state, makeUPPER(j["ghe_vertical_properties_object_name"].to[String]()))
            self.numBHinXDirection = j["number_of_boreholes_in_x_direction"].to[Int]()
            self.numBHinYDirection = j["number_of_boreholes_in_y_direction"].to[Int]()
            self.bhSpacing = j["borehole_spacing"].to[Float64]()

        @staticmethod
        def GetVertArray(state: EnergyPlusData, objectName: String) -> Arc[GLHEVertArray]:
            for existingObj in state.dataGroundHeatExchanger[].vertArraysVector:
                if existingObj[].name == objectName:
                    return existingObj
            ShowSevereError(state, format("Object=GroundHeatExchanger:Vertical:Array, Name={} - not found.", objectName))
            ShowFatalError(state, "Preceding errors cause program termination")
            # Unreachable, but Mojo requires a return
            return Arc[GLHEVertArray]()