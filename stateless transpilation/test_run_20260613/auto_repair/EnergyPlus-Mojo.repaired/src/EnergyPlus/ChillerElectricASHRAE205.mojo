import "objexxFCL/Array1D"
import "EnergyPlus/ChillerElectricEIR"
import "rs0001"
import "EnergyPlus/Data/BaseData"
import "EnergyPlus/DataGlobals"
import "EnergyPlus/EnergyPlus"
import "EnergyPlus/Autosizing/All_Simple_Sizing"
import "EnergyPlus/BranchNodeConnections"
import "EnergyPlus/CurveManager"
import "EnergyPlus/Data/EnergyPlusData"
import "EnergyPlus/DataBranchAirLoopPlant"
import "EnergyPlus/DataEnvironment"
import "EnergyPlus/DataHVACGlobals"
import "EnergyPlus/DataHeatBalance"
import "EnergyPlus/DataIPShortCuts"
import "EnergyPlus/DataLoopNode"
import "EnergyPlus/DataSizing"
import "EnergyPlus/DataSystemVariables"
import "EnergyPlus/EMSManager"
import "EnergyPlus/EnergyPlusLogger"
import "EnergyPlus/FaultsManager"
import "EnergyPlus/FileSystem"
import "EnergyPlus/FluidProperties"
import "EnergyPlus/General"
import "EnergyPlus/GeneralRoutines"
import "EnergyPlus/GlobalNames"
import "EnergyPlus/HeatBalanceInternalHeatGains"
import "EnergyPlus/InputProcessing/InputProcessor"
import "EnergyPlus/NodeInputManager"
import "EnergyPlus/OutAirNodeManager"
import "EnergyPlus/OutputProcessor"
import "EnergyPlus/OutputReportPredefined"
import "EnergyPlus/Plant/DataPlant"
import "EnergyPlus/Plant/PlantLocation"
import "EnergyPlus/PlantUtilities"
import "EnergyPlus/ScheduleManager"
import "EnergyPlus/UtilityRoutines"
import "EnergyPlus/ZoneTempPredictorCorrector"
import "rs0001_factory"
def assert(cond: Bool, msg: String = "") -> None:
    if not cond:
        raise Error(msg)
var AmbientTempNamesUC: List[String] = ["SCHEDULE", "ZONE", "OUTDOORS"]
var InterpMethods: Dict[String, Btwxt.InterpolationMethod] = {
    "LINEAR": Btwxt.InterpolationMethod.linear,
    "CUBIC": Btwxt.InterpolationMethod.cubic,
}
def getChillerASHRAE205Input(state: EnergyPlusData) -> None:
    var RoutineName: String = "getChillerASHRAE205Input: "
    var routineName: String = "getChillerASHRAE205Input"
    using tk205
    RSInstanceFactory.register_factory("RS0001", std.make_shared[RS0001Factory]())
    var ErrorsFound: Bool = False
    var s_ip = state.dataInputProcessing.inputProcessor
    var s_ipsc = state.dataIPShortCut
    state.dataIPShortCut.cCurrentModuleObject = ChillerElectricASHRAE205.ASHRAE205ChillerSpecs.ObjectType
    var numElectric205Chillers: Int = s_ip.getNumObjectsFound(state, state.dataIPShortCut.cCurrentModuleObject)
    if numElectric205Chillers <= 0:
        ShowSevereError(state, format("No {} equipment specified in input file", state.dataIPShortCut.cCurrentModuleObject))
        ErrorsFound = True
    state.dataChillerElectricASHRAE205.Electric205Chiller.allocate(numElectric205Chillers)
    var ChillerInstances = s_ip.epJSON.find(state.dataIPShortCut.cCurrentModuleObject).value()
    var ChillerNum: Int = 0
    var objectSchemaProps = s_ip.getObjectSchemaProps(state, state.dataIPShortCut.cCurrentModuleObject)
    for instance in ChillerInstances.items():
        let fields = instance.value()
        let thisObjectName: String = instance.key()
        var eoh: ErrorObjectHeader = ErrorObjectHeader(routineName, s_ipsc.cCurrentModuleObject, thisObjectName)
        GlobalNames.VerifyUniqueChillerName(
            state, state.dataIPShortCut.cCurrentModuleObject, thisObjectName, ErrorsFound, state.dataIPShortCut.cCurrentModuleObject + " Name")
        ChillerNum += 1
        var thisChiller = state.dataChillerElectricASHRAE205.Electric205Chiller[ChillerNum - 1]  # 0-based index
        thisChiller.Name = Util.makeUPPER(thisObjectName)
        s_ip.markObjectAsUsed(state.dataIPShortCut.cCurrentModuleObject, thisObjectName)
        var rep_file_name: String = s_ip.getAlphaFieldValue(fields, objectSchemaProps, "representation_file_name")
        var rep_file_path = DataSystemVariables.CheckForActualFilePath(state, FileSystem.path(rep_file_name), String(RoutineName))
        if rep_file_path.empty():
            ErrorsFound = True
            ShowFatalError(state, "Program terminates due to the missing ASHRAE 205 RS0001 representation file.")
        thisChiller.LoggerContext = (state, format("{} \"{}\"", state.dataIPShortCut.cCurrentModuleObject, thisObjectName))
        thisChiller.Representation = std.dynamic_pointer_cast[tk205.rs0001_ns.RS0001](
            RSInstanceFactory.create("RS0001", FileSystem.toString(rep_file_path).c_str(), std.make_shared[EnergyPlusLogger]()))
        if thisChiller.Representation == None:
            ShowSevereError(state, format("{} is not an instance of an ASHRAE205 Chiller.", rep_file_path.string()))
            ErrorsFound = True
        thisChiller.Representation.performance.performance_map_cooling.get_logger().set_message_context(&thisChiller.LoggerContext)
        thisChiller.Representation.performance.performance_map_standby.get_logger().set_message_context(&thisChiller.LoggerContext)
        thisChiller.InterpolationType = InterpMethods[Util.makeUPPER(s_ip.getAlphaFieldValue(fields, objectSchemaProps, "performance_interpolation_method"))]
        var compressorSequence = thisChiller.Representation.performance.performance_map_cooling.grid_variables.compressor_sequence_number
        var minmaxSequenceNum = std.minmax_element(compressorSequence.begin(), compressorSequence.end())
        thisChiller.MinSequenceNumber = minmaxSequenceNum.first[]
        thisChiller.MaxSequenceNumber = minmaxSequenceNum.second[]
        if fields.count("rated_capacity") != 0:
            ShowWarningError(state,
                             format("{}{}=\"{}\"", String(RoutineName), state.dataIPShortCut.cCurrentModuleObject, thisChiller.Name))
            ShowContinueError(state, "Rated Capacity field is not yet supported for ASHRAE 205 representations.")
        thisChiller.RefCap = 0.0
        thisChiller.RefCapWasAutoSized = False
        var evap_inlet_node_name: String = s_ip.getAlphaFieldValue(fields, objectSchemaProps, "chilled_water_inlet_node_name")
        var evap_outlet_node_name: String = s_ip.getAlphaFieldValue(fields, objectSchemaProps, "chilled_water_outlet_node_name")
        if evap_inlet_node_name.empty() or evap_outlet_node_name.empty():
            ShowSevereError(state,
                            format("{}{}=\"{}\"", String(RoutineName), state.dataIPShortCut.cCurrentModuleObject, thisChiller.Name))
            ShowContinueError(state, "Evaporator Inlet or Outlet Node Name is blank.")
            ErrorsFound = True
        thisChiller.EvapInletNodeNum = Node.GetOnlySingleNode(state,
                                                              evap_inlet_node_name,
                                                              ErrorsFound,
                                                              Node.ConnectionObjectType.ChillerElectricASHRAE205,
                                                              thisChiller.Name,
                                                              Node.FluidType.Water,
                                                              Node.ConnectionType.Inlet,
                                                              Node.CompFluidStream.Primary,
                                                              Node.ObjectIsNotParent)
        thisChiller.EvapOutletNodeNum = Node.GetOnlySingleNode(state,
                                                               evap_outlet_node_name,
                                                               ErrorsFound,
                                                               Node.ConnectionObjectType.ChillerElectricASHRAE205,
                                                               thisChiller.Name,
                                                               Node.FluidType.Water,
                                                               Node.ConnectionType.Outlet,
                                                               Node.CompFluidStream.Primary,
                                                               Node.ObjectIsNotParent)
        Node.TestCompSet(
            state, state.dataIPShortCut.cCurrentModuleObject, thisChiller.Name, evap_inlet_node_name, evap_outlet_node_name, "Chilled Water Nodes")
        thisChiller.CondenserType = DataPlant.CondenserType.WaterCooled
        var cond_inlet_node_name: String = s_ip.getAlphaFieldValue(fields, objectSchemaProps, "condenser_inlet_node_name")
        var cond_outlet_node_name: String = s_ip.getAlphaFieldValue(fields, objectSchemaProps, "condenser_outlet_node_name")
        if cond_inlet_node_name.empty() or cond_outlet_node_name.empty():
            ShowSevereError(state,
                            format("{}{}=\"{}\"", String(RoutineName), state.dataIPShortCut.cCurrentModuleObject, thisChiller.Name))
            ShowContinueError(state, "Condenser Inlet or Outlet Node Name is blank.")
            ErrorsFound = True
        thisChiller.CondInletNodeNum = Node.GetOnlySingleNode(state,
                                                              cond_inlet_node_name,
                                                              ErrorsFound,
                                                              Node.ConnectionObjectType.ChillerElectricASHRAE205,
                                                              thisChiller.Name,
                                                              Node.FluidType.Water,
                                                              Node.ConnectionType.Inlet,
                                                              Node.CompFluidStream.Secondary,
                                                              Node.ObjectIsNotParent)
        thisChiller.CondOutletNodeNum = Node.GetOnlySingleNode(state,
                                                               cond_outlet_node_name,
                                                               ErrorsFound,
                                                               Node.ConnectionObjectType.ChillerElectricASHRAE205,
                                                               thisChiller.Name,
                                                               Node.FluidType.Water,
                                                               Node.ConnectionType.Outlet,
                                                               Node.CompFluidStream.Secondary,
                                                               Node.ObjectIsNotParent)
        Node.TestCompSet(state,
                         state.dataIPShortCut.cCurrentModuleObject,
                         thisChiller.Name,
                         cond_inlet_node_name,
                         cond_outlet_node_name,
                         "Condenser Water Nodes")
        thisChiller.FlowMode = static_cast[DataPlant.FlowMode](
            getEnumValue(DataPlant.FlowModeNamesUC, s_ip.getAlphaFieldValue(fields, objectSchemaProps, "chiller_flow_mode")))
        if thisChiller.FlowMode == DataPlant.FlowMode.Invalid:
            ShowSevereError(state, format("{}{}=\"{}\"", String(RoutineName), state.dataIPShortCut.cCurrentModuleObject, thisObjectName))
            ShowContinueError(state, format("Invalid Chiller Flow Mode = {}", fields.at("chiller_flow_mode").get[String]()[0]))
            ShowContinueError(state, "Available choices are ConstantFlow, NotModulated, or LeavingSetpointModulated")
            ShowContinueError(state, "Flow mode NotModulated is assumed and the simulation continues.")
            thisChiller.FlowMode = DataPlant.FlowMode.NotModulated
        }
        thisChiller.SizFac = fields.at("sizing_factor").get[Float64]()[0]
        if thisChiller.SizFac <= 0.0:
            thisChiller.SizFac = 1.0
    if ErrorsFound:
        ShowFatalError(state, format("Errors found in processing input for {}", state.dataIPShortCut.cCurrentModuleObject))