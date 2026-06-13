# Mojo translation of DataZoneEquipment.cc
# Faithful 1:1 translation, no refactoring.

from DataGlobals import *
from DataHVACSystems import *
from DataLoopNode import *
from DataZoneEnergyDemands import *
from EnergyPlus import *
from ExhaustAirSystemManager import *
from InputProcessing.InputProcessor import *
from OutputProcessor import *
from SystemAvailabilityManager import *
from SystemReports import *
from Data.BaseData import *
from Data.EnergyPlusData import *
from Autosizing.Base import *
from BranchNodeConnections import *
from DataContaminantBalance import *
from DataDefineEquip import *
from DataEnvironment import *
from DataHVACGlobals import *
from DataHeatBalance import *
from DataSizing import *
from General import *
from GeneralRoutines import *
from GlobalNames import *
from NodeInputManager import *
from Psychrometrics import *
from ScheduleManager import *
from UnitarySystem import *
from UtilityRoutines import *
from ZoneEquipmentManager import *
from ZoneTempPredictorCorrector import *

# Helper functions to mimic ObjexxFCL
def nint(x: Float64) -> Int:
    return Int(round(x))

def count_eq[T: Equatable](arr: List[T], val: T) -> Int:
    var count: Int = 0
    for i in range(len(arr)):
        if arr[i] == val:
            count += 1
    return count

def present(opt: Optional[Int]) -> Bool:
    return opt is not None

# Enums
enum AirNodeType(Int):
    Invalid = -1
    PathInlet = 0
    CompInlet = 1
    Intermediate = 2
    Outlet = 3
    Num = 4

enum AirLoopHVACZone(Int):
    Invalid = -1
    Splitter = 0
    SupplyPlenum = 1
    Mixer = 2
    ReturnPlenum = 3
    Num = 4

let AirLoopHVACTypeNamesCC: StaticTuple[String, 4] = (
    "AirLoopHVAC:ZoneSplitter",
    "AirLoopHVAC:SupplyPlenum",
    "AirLoopHVAC:ZoneMixer",
    "AirLoopHVAC:ReturnPlenum"
)

let AirLoopHVACTypeNamesUC: StaticTuple[String, 4] = (
    "AIRLOOPHVAC:ZONESPLITTER",
    "AIRLOOPHVAC:SUPPLYPLENUM",
    "AIRLOOPHVAC:ZONEMIXER",
    "AIRLOOPHVAC:RETURNPLENUM"
)

enum ZoneEquipType(Int):
    Invalid = -1
    DUMMY = 0
    FourPipeFanCoil = 1
    PackagedTerminalHeatPump = 2
    PackagedTerminalAirConditioner = 3
    PackagedTerminalHeatPumpWaterToAir = 4
    WindowAirConditioner = 5
    UnitHeater = 6
    UnitVentilator = 7
    EnergyRecoveryVentilator = 8
    VentilatedSlab = 9
    OutdoorAirUnit = 10
    VariableRefrigerantFlowTerminal = 11
    PurchasedAir = 12
    EvaporativeCooler = 13
    HybridEvaporativeCooler = 14
    AirDistributionUnit = 15
    BaseboardConvectiveWater = 16
    BaseboardConvectiveElectric = 17
    BaseboardSteam = 18
    BaseboardWater = 19
    BaseboardElectric = 20
    HighTemperatureRadiant = 21
    LowTemperatureRadiantConstFlow = 22
    LowTemperatureRadiantVarFlow = 23
    LowTemperatureRadiantElectric = 24
    ExhaustFan = 25
    HeatExchanger = 26
    HeatPumpWaterHeaterPumpedCondenser = 27
    HeatPumpWaterHeaterWrappedCondenser = 28
    DehumidifierDX = 29
    RefrigerationChillerSet = 30
    UserDefinedHVACForcedAir = 31
    CoolingPanel = 32
    UnitarySystem = 33
    AirTerminalDualDuctConstantVolume = 34
    AirTerminalDualDuctVAV = 35
    AirTerminalSingleDuctConstantVolumeReheat = 36
    AirTerminalSingleDuctConstantVolumeNoReheat = 37
    AirTerminalSingleDuctVAVReheat = 38
    AirTerminalSingleDuctVAVNoReheat = 39
    AirTerminalSingleDuctSeriesPIUReheat = 40
    AirTerminalSingleDuctParallelPIUReheat = 41
    AirTerminalSingleDuctCAVFourPipeInduction = 42
    AirTerminalSingleDuctVAVReheatVariableSpeedFan = 43
    AirTerminalSingleDuctVAVHeatAndCoolReheat = 44
    AirTerminalSingleDuctVAVHeatAndCoolNoReheat = 45
    AirTerminalSingleDuctConstantVolumeCooledBeam = 46
    AirTerminalDualDuctVAVOutdoorAir = 47
    AirLoopHVACReturnAir = 48
    Num = 49

let NumValidSysAvailZoneComponents: Int = 14

let cValidSysAvailManagerCompTypes: List[String] = List[String](
    "ZoneHVAC:FourPipeFanCoil",
    "ZoneHVAC:PackagedTerminalHeatPump",
    "ZoneHVAC:PackagedTerminalAirConditioner",
    "ZoneHVAC:WaterToAirHeatPump",
    "ZoneHVAC:WindowAirConditioner",
    "ZoneHVAC:UnitHeater",
    "ZoneHVAC:UnitVentilator",
    "ZoneHVAC:EnergyRecoveryVentilator",
    "ZoneHVAC:VentilatedSlab",
    "ZoneHVAC:OutdoorAirUnit",
    "ZoneHVAC:TerminalUnit:VariableRefrigerantFlow",
    "ZoneHVAC:IdealLoadsAirSystem",
    "ZoneHVAC:EvaporativeCoolerUnit",
    "ZoneHVAC:HybridUnitaryHVAC"
)

let zoneEquipTypeNamesUC: StaticTuple[String, 49] = (
    "DUMMY",
    "ZONEHVAC:FOURPIPEFANCOIL",
    "ZONEHVAC:PACKAGEDTERMINALHEATPUMP",
    "ZONEHVAC:PACKAGEDTERMINALAIRCONDITIONER",
    "ZONEHVAC:WATERTOAIRHEATPUMP",
    "ZONEHVAC:WINDOWAIRCONDITIONER",
    "ZONEHVAC:UNITHEATER",
    "ZONEHVAC:UNITVENTILATOR",
    "ZONEHVAC:ENERGYRECOVERYVENTILATOR",
    "ZONEHVAC:VENTILATEDSLAB",
    "ZONEHVAC:OUTDOORAIRUNIT",
    "ZONEHVAC:TERMINALUNIT:VARIABLEREFRIGERANTFLOW",
    "ZONEHVAC:IDEALLOADSAIRSYSTEM",
    "ZONEHVAC:EVAPORATIVECOOLERUNIT",
    "ZONEHVAC:HYBRIDUNITARYHVAC",
    "ZONEHVAC:AIRDISTRIBUTIONUNIT",
    "ZONEHVAC:BASEBOARD:CONVECTIVE:WATER",
    "ZONEHVAC:BASEBOARD:CONVECTIVE:ELECTRIC",
    "ZONEHVAC:BASEBOARD:RADIANTCONVECTIVE:STEAM",
    "ZONEHVAC:BASEBOARD:RADIANTCONVECTIVE:WATER",
    "ZONEHVAC:BASEBOARD:RADIANTCONVECTIVE:ELECTRIC",
    "ZONEHVAC:HIGHTEMPERATURERADIANT",
    "ZONEHVAC:LOWTEMPERATURERADIANT:CONSTANTFLOW",
    "ZONEHVAC:LOWTEMPERATURERADIANT:VARIABLEFLOW",
    "ZONEHVAC:LOWTEMPERATURERADIANT:ELECTRIC",
    "FAN:ZONEEXHAUST",
    "HEATEXCHANGER:AIRTOAIR:FLATPLATE",
    "WATERHEATER:HEATPUMP:PUMPEDCONDENSER",
    "WATERHEATER:HEATPUMP:WRAPPEDCONDENSER",
    "ZONEHVAC:DEHUMIDIFIER:DX",
    "ZONEHVAC:REFRIGERATIONCHILLERSET",
    "ZONEHVAC:FORCEDAIR:USERDEFINED",
    "ZONEHVAC:COOLINGPANEL:RADIANTCONVECTIVE:WATER",
    "AIRLOOPHVAC:UNITARYSYSTEM",
    "AIRTERMINAL:DUALDUCT:CONSTANTVOLUME",
    "AIRTERMINAL:DUALDUCT:VAV",
    "AIRTERMINAL:SINGLEDUCT:CONSTANTVOLUME:REHEAT",
    "AIRTERMINAL:SINGLEDUCT:CONSTANTVOLUME:NOREHEAT",
    "AIRTERMINAL:SINGLEDUCT:VAV:REHEAT",
    "AIRTERMINAL:SINGLEDUCT:VAV:NOREHEAT",
    "AIRTERMINAL:SINGLEDUCT:SERIESPIU:REHEAT",
    "AIRTERMINAL:SINGLEDUCT:PARALLELPIU:REHEAT",
    "AIRTERMINAL:SINGLEDUCT:CONSTANTVOLUME:FOURPIPEINDUCTION",
    "AIRTERMINAL:SINGLEDUCT:VAV:REHEAT:VARIABLESPEEDFAN",
    "AIRTERMINAL:SINGLEDUCT:VAV:HEATANDCOOL:REHEAT",
    "AIRTERMINAL:SINGLEDUCT:VAV:HEATANDCOOL:NOREHEAT",
    "AIRTERMINAL:SINGLEDUCT:CONSTANTVOLUME:COOLEDBEAM",
    "AIRTERMINAL:DUALDUCT:VAV:OUTDOORAIR",
    "AIRLOOPHVACRETURNAIR"
)

enum PerPersonVentRateMode(Int):
    Invalid = -1
    DCVByCurrentLevel = 0
    ByDesignLevel = 1
    Num = 2

enum LoadDist(Int):
    Invalid = -1
    Sequential = 0
    Uniform = 1
    UniformPLR = 2
    SequentialUniformPLR = 3
    Num = 4

let LoadDistNamesUC: StaticTuple[String, 4] = (
    "SEQUENTIALLOAD",
    "UNIFORMLOAD",
    "UNIFORMPLR",
    "SEQUENTIALUNIFORMPLR"
)

enum LightReturnExhaustConfig(Int):
    Invalid = -1
    NoExhast = 0
    Single = 1
    Multi = 2
    Shared = 3
    Num = 4

enum ZoneEquipTstatControl(Int):
    Invalid = -1
    SingleSpace = 0
    Maximum = 1
    Ideal = 2
    Num = 3

let zoneEquipTstatControlNamesUC: StaticTuple[String, 3] = (
    "SINGLESPACE",
    "MAXIMUM",
    "IDEAL"
)

enum SpaceEquipSizingBasis(Int):
    Invalid = -1
    DesignCoolingLoad = 0
    DesignHeatingLoad = 1
    FloorArea = 2
    Volume = 3
    PerimeterLength = 4
    Num = 5

let spaceEquipSizingBasisNamesUC: StaticTuple[String, 5] = (
    "DESIGNCOOLINGLOAD",
    "DESIGNHEATINGLOAD",
    "FLOORAREA",
    "VOLUME",
    "PERIMETERLENGTH"
)

# Structs
struct SubSubEquipmentData:
    var TypeOf: String
    var Name: String
    var EquipIndex: Int
    var ON: Bool
    var InletNodeNum: Int
    var OutletNodeNum: Int
    var NumMeteredVars: Int
    var MeteredVar: List[OutputProcessor.MeterData]
    var EnergyTransComp: Int
    var ZoneEqToPlantPtr: Int
    var OpMode: Int
    var Capacity: Float64
    var Efficiency: Float64
    var TotPlantSupplyElec: Float64
    var TotPlantSupplyGas: Float64
    var TotPlantSupplyPurch: Float64

    def __init__(inout self):
        self.TypeOf = ""
        self.Name = ""
        self.EquipIndex = 0
        self.ON = True
        self.InletNodeNum = 0
        self.OutletNodeNum = 0
        self.NumMeteredVars = 0
        self.MeteredVar = List[OutputProcessor.MeterData]()
        self.EnergyTransComp = 0
        self.ZoneEqToPlantPtr = 0
        self.OpMode = 0
        self.Capacity = 0.0
        self.Efficiency = 0.0
        self.TotPlantSupplyElec = 0.0
        self.TotPlantSupplyGas = 0.0
        self.TotPlantSupplyPurch = 0.0

struct SubEquipmentData:
    var Parent: Bool
    var NumSubSubEquip: Int
    var TypeOf: String
    var Name: String
    var EquipIndex: Int
    var ON: Bool
    var InletNodeNum: Int
    var OutletNodeNum: Int
    var NumMeteredVars: Int
    var MeteredVar: List[OutputProcessor.MeterData]
    var SubSubEquipData: List[SubSubEquipmentData]
    var EnergyTransComp: Int
    var ZoneEqToPlantPtr: Int
    var OpMode: Int
    var Capacity: Float64
    var Efficiency: Float64
    var TotPlantSupplyElec: Float64
    var TotPlantSupplyGas: Float64
    var TotPlantSupplyPurch: Float64

    def __init__(inout self):
        self.Parent = False
        self.NumSubSubEquip = 0
        self.TypeOf = ""
        self.Name = ""
        self.EquipIndex = 0
        self.ON = True
        self.InletNodeNum = 0
        self.OutletNodeNum = 0
        self.NumMeteredVars = 0
        self.MeteredVar = List[OutputProcessor.MeterData]()
        self.SubSubEquipData = List[SubSubEquipmentData]()
        self.EnergyTransComp = 0
        self.ZoneEqToPlantPtr = 0
        self.OpMode = 0
        self.Capacity = 0.0
        self.Efficiency = 0.0
        self.TotPlantSupplyElec = 0.0
        self.TotPlantSupplyGas = 0.0
        self.TotPlantSupplyPurch = 0.0

struct AirIn:
    var InNode: Int
    var OutNode: Int
    var SupplyAirPathExists: Bool
    var AirLoopNum: Int
    var MainBranchIndex: Int
    var SupplyBranchIndex: Int
    var AirDistUnitIndex: Int
    var TermUnitSizingIndex: Int
    var SupplyAirPathIndex: Int
    var SupplyAirPathOutNodeIndex: Int
    var Coil: List[SubSubEquipmentData]

    def __init__(inout self):
        self.InNode = 0
        self.OutNode = 0
        self.SupplyAirPathExists = False
        self.AirLoopNum = 0
        self.MainBranchIndex = 0
        self.SupplyBranchIndex = 0
        self.AirDistUnitIndex = 0
        self.TermUnitSizingIndex = 0
        self.SupplyAirPathIndex = 0
        self.SupplyAirPathOutNodeIndex = 0
        self.Coil = List[SubSubEquipmentData]()

struct EquipConfiguration:
    var ZoneName: String
    var EquipListName: String
    var EquipListIndex: Int
    var ControlListName: String
    var ZoneNode: Int
    var NumInletNodes: Int
    var NumExhaustNodes: Int
    var NumReturnNodes: Int
    var NumReturnFlowBasisNodes: Int
    var returnFlowFracSched: Optional[Sched.Schedule]
    var FlowError: Bool
    var InletNode: List[Int]
    var InletNodeAirLoopNum: List[Int]
    var InletNodeADUNum: List[Int]
    var ExhaustNode: List[Int]
    var ReturnNode: List[Int]
    var ReturnNodeAirLoopNum: List[Int]
    var ReturnNodeRetPathNum: List[Int]
    var ReturnNodeRetPathCompNum: List[Int]
    var ReturnNodeInletNum: List[Int]
    var FixedReturnFlow: List[Bool]
    var ReturnNodePlenumNum: List[Int]
    var ReturnFlowBasisNode: List[Int]
    var ReturnNodeExhaustNodeNum: List[Int]
    var SharedExhaustNode: List[LightReturnExhaustConfig]
    var returnNodeSpaceMixerIndex: List[Int]
    var ZonalSystemOnly: Bool
    var IsControlled: Bool
    var ZoneExh: Float64
    var ZoneExhBalanced: Float64
    var PlenumMassFlow: Float64
    var ExcessZoneExh: Float64
    var TotAvailAirLoopOA: Float64
    var TotInletAirMassFlowRate: Float64
    var TotExhaustAirMassFlowRate: Float64
    var AirDistUnitHeat: List[AirIn]
    var AirDistUnitCool: List[AirIn]
    var InFloorActiveElement: Bool
    var InWallActiveElement: Bool
    var InCeilingActiveElement: Bool
    var ZoneHasAirLoopWithOASys: Bool
    var ZoneAirDistributionIndex: Int
    var ZoneDesignSpecOAIndex: Int
    var AirLoopDesSupply: Float64

    def __init__(inout self):
        self.ZoneName = "Uncontrolled Zone"
        self.EquipListName = ""
        self.EquipListIndex = 0
        self.ControlListName = ""
        self.ZoneNode = 0
        self.NumInletNodes = 0
        self.NumExhaustNodes = 0
        self.NumReturnNodes = 0
        self.NumReturnFlowBasisNodes = 0
        self.returnFlowFracSched = None
        self.FlowError = False
        self.InletNode = List[Int]()
        self.InletNodeAirLoopNum = List[Int]()
        self.InletNodeADUNum = List[Int]()
        self.ExhaustNode = List[Int]()
        self.ReturnNode = List[Int]()
        self.ReturnNodeAirLoopNum = List[Int]()
        self.ReturnNodeRetPathNum = List[Int]()
        self.ReturnNodeRetPathCompNum = List[Int]()
        self.ReturnNodeInletNum = List[Int]()
        self.FixedReturnFlow = List[Bool]()
        self.ReturnNodePlenumNum = List[Int]()
        self.ReturnFlowBasisNode = List[Int]()
        self.ReturnNodeExhaustNodeNum = List[Int]()
        self.SharedExhaustNode = List[LightReturnExhaustConfig]()
        self.returnNodeSpaceMixerIndex = List[Int]()
        self.ZonalSystemOnly = False
        self.IsControlled = False
        self.ZoneExh = 0.0
        self.ZoneExhBalanced = 0.0
        self.PlenumMassFlow = 0.0
        self.ExcessZoneExh = 0.0
        self.TotAvailAirLoopOA = 0.0
        self.TotInletAirMassFlowRate = 0.0
        self.TotExhaustAirMassFlowRate = 0.0
        self.AirDistUnitHeat = List[AirIn]()
        self.AirDistUnitCool = List[AirIn]()
        self.InFloorActiveElement = False
        self.InWallActiveElement = False
        self.InCeilingActiveElement = False
        self.ZoneHasAirLoopWithOASys = False
        self.ZoneAirDistributionIndex = 0
        self.ZoneDesignSpecOAIndex = 0
        self.AirLoopDesSupply = 0.0

    def setTotalInletFlows(inout self, state: EnergyPlusData):
        self.TotInletAirMassFlowRate = 0.0
        var TotInletAirMassFlowRateMax: Float64 = 0.0
        var TotInletAirMassFlowRateMaxAvail: Float64 = 0.0
        var TotInletAirMassFlowRateMin: Float64 = 0.0
        var TotInletAirMassFlowRateMinAvail: Float64 = 0.0
        for NodeNum in range(1, self.NumInletNodes + 1):
            var thisNode = state.dataLoopNodes.Node[self.InletNode[NodeNum - 1]]
            self.TotInletAirMassFlowRate += thisNode.MassFlowRate
            TotInletAirMassFlowRateMax += thisNode.MassFlowRateMax
            TotInletAirMassFlowRateMaxAvail += thisNode.MassFlowRateMaxAvail
            TotInletAirMassFlowRateMin += thisNode.MassFlowRateMin
            TotInletAirMassFlowRateMinAvail += thisNode.MassFlowRateMinAvail
        var zoneSpaceNode = state.dataLoopNodes.Node[self.ZoneNode]
        zoneSpaceNode.MassFlowRate = self.TotInletAirMassFlowRate
        zoneSpaceNode.MassFlowRateMax = TotInletAirMassFlowRateMax
        zoneSpaceNode.MassFlowRateMaxAvail = TotInletAirMassFlowRateMaxAvail
        zoneSpaceNode.MassFlowRateMin = TotInletAirMassFlowRateMin
        zoneSpaceNode.MassFlowRateMinAvail = TotInletAirMassFlowRateMinAvail

    def beginEnvirnInit(inout self, state: EnergyPlusData):
        var zoneNode = state.dataLoopNodes.Node[self.ZoneNode]
        zoneNode.Temp = 20.0
        zoneNode.MassFlowRate = 0.0
        zoneNode.Quality = 1.0
        zoneNode.Press = state.dataEnvrn.OutBaroPress
        zoneNode.HumRat = state.dataEnvrn.OutHumRat
        zoneNode.Enthalpy = Psychrometrics.PsyHFnTdbW(zoneNode.Temp, zoneNode.HumRat)
        if state.dataContaminantBalance.Contaminant.CO2Simulation:
            zoneNode.CO2 = state.dataContaminantBalance.OutdoorCO2
        if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
            zoneNode.GenContam = state.dataContaminantBalance.OutdoorGC
        for nodeNum in self.InletNode:
            var inNode = state.dataLoopNodes.Node[nodeNum]
            inNode.Temp = 20.0
            inNode.MassFlowRate = 0.0
            inNode.Quality = 1.0
            inNode.Press = state.dataEnvrn.OutBaroPress
            inNode.HumRat = state.dataEnvrn.OutHumRat
            inNode.Enthalpy = Psychrometrics.PsyHFnTdbW(inNode.Temp, inNode.HumRat)
            if state.dataContaminantBalance.Contaminant.CO2Simulation:
                inNode.CO2 = state.dataContaminantBalance.OutdoorCO2
            if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
                inNode.GenContam = state.dataContaminantBalance.OutdoorGC
        for nodeNum in self.ExhaustNode:
            var exhNode = state.dataLoopNodes.Node[nodeNum]
            exhNode.Temp = 20.0
            exhNode.MassFlowRate = 0.0
            exhNode.Quality = 1.0
            exhNode.Press = state.dataEnvrn.OutBaroPress
            exhNode.HumRat = state.dataEnvrn.OutHumRat
            exhNode.Enthalpy = Psychrometrics.PsyHFnTdbW(exhNode.Temp, exhNode.HumRat)
            if state.dataContaminantBalance.Contaminant.CO2Simulation:
                exhNode.CO2 = state.dataContaminantBalance.OutdoorCO2
            if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
                exhNode.GenContam = state.dataContaminantBalance.OutdoorGC
        var NumRetNodes = self.NumReturnNodes
        if NumRetNodes > 0:
            for nodeNum in self.ReturnNode:
                var returnNode = state.dataLoopNodes.Node[nodeNum]
                returnNode.Temp = 20.0
                returnNode.MassFlowRate = 0.0
                returnNode.Quality = 1.0
                returnNode.Press = state.dataEnvrn.OutBaroPress
                returnNode.HumRat = state.dataEnvrn.OutHumRat
                returnNode.Enthalpy = Psychrometrics.PsyHFnTdbW(returnNode.Temp, returnNode.HumRat)
                if state.dataContaminantBalance.Contaminant.CO2Simulation:
                    returnNode.CO2 = state.dataContaminantBalance.OutdoorCO2
                if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
                    returnNode.GenContam = state.dataContaminantBalance.OutdoorGC

    def hvacTimeStepInit(inout self, state: EnergyPlusData, FirstHVACIteration: Bool):
        var zoneNode = state.dataLoopNodes.Node[self.ZoneNode]
        self.ExcessZoneExh = 0.0
        if FirstHVACIteration:
            for nodeNum in self.ExhaustNode:
                var exhNode = state.dataLoopNodes.Node[nodeNum]
                exhNode.Temp = zoneNode.Temp
                exhNode.HumRat = zoneNode.HumRat
                exhNode.Enthalpy = zoneNode.Enthalpy
                exhNode.Press = zoneNode.Press
                exhNode.Quality = zoneNode.Quality
                exhNode.MassFlowRate = 0.0
                exhNode.MassFlowRateMaxAvail = 0.0
                exhNode.MassFlowRateMinAvail = 0.0
                if state.dataContaminantBalance.Contaminant.CO2Simulation:
                    exhNode.CO2 = zoneNode.CO2
                if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
                    exhNode.GenContam = zoneNode.GenContam

    def calcReturnFlows(inout self, state: EnergyPlusData, inout ExpTotalReturnMassFlow: Float64, inout FinalTotalReturnMassFlow: Float64):
        var numRetNodes = self.NumReturnNodes
        var totReturnFlow: Float64 = 0.0
        var totVarReturnFlow: Float64 = 0.0
        var returnSchedFrac = self.returnFlowFracSched.getCurrentVal()
        self.FixedReturnFlow = List[Bool](len=self.NumReturnNodes, fill=False)
        FinalTotalReturnMassFlow = 0.0
        self.TotAvailAirLoopOA = 0.0
        for returnNum in range(1, numRetNodes + 1):
            var retNode = self.ReturnNode[returnNum - 1]
            if retNode > 0:
                var returnNodeMassFlow: Float64 = 0.0
                var retNodeData = state.dataLoopNodes.Node[retNode]
                var inletNum = self.ReturnNodeInletNum[returnNum - 1]
                var ADUNum: Int = 0
                if inletNum > 0:
                    ADUNum = self.InletNodeADUNum[inletNum - 1]
                var airLoop = self.ReturnNodeAirLoopNum[returnNum - 1]
                var airLoopReturnFrac: Float64 = 1.0
                if airLoop > 0:
                    var inletMassFlow: Float64 = 0.0
                    var maxMinNodeNum: Int = 0
                    var thisAirLoopFlow = state.dataAirLoop.AirLoopFlow[airLoop]
                    if ADUNum > 0:
                        inletMassFlow = state.dataDefineEquipment.AirDistUnit[ADUNum].MassFlowRateZSup + state.dataDefineEquipment.AirDistUnit[ADUNum].MassFlowRatePlenInd
                        maxMinNodeNum = state.dataDefineEquipment.AirDistUnit[ADUNum].OutletNodeNum
                    elif inletNum > 0:
                        inletMassFlow = state.dataLoopNodes.Node[self.InletNode[inletNum - 1]].MassFlowRate
                        maxMinNodeNum = self.InletNode[inletNum - 1]
                    if maxMinNodeNum > 0:
                        var maxMinNodeData = state.dataLoopNodes.Node[maxMinNodeNum]
                        retNodeData.MassFlowRateMax = maxMinNodeData.MassFlowRateMax
                        retNodeData.MassFlowRateMin = maxMinNodeData.MassFlowRateMin
                        retNodeData.MassFlowRateMaxAvail = maxMinNodeData.MassFlowRateMaxAvail
                    else:
                        var zoneNodeData = state.dataLoopNodes.Node[self.ZoneNode]
                        retNodeData.MassFlowRateMax = zoneNodeData.MassFlowRateMax
                        retNodeData.MassFlowRateMin = zoneNodeData.MassFlowRateMin
                        retNodeData.MassFlowRateMaxAvail = zoneNodeData.MassFlowRateMaxAvail
                    airLoopReturnFrac = thisAirLoopFlow.DesReturnFrac
                    if state.dataAirSystemsData.PrimaryAirSystems[airLoop].OASysExists and (thisAirLoopFlow.MaxOutAir > 0.0):
                        returnNodeMassFlow = airLoopReturnFrac * inletMassFlow
                        self.TotAvailAirLoopOA += thisAirLoopFlow.MaxOutAir
                    else:
                        returnNodeMassFlow = inletMassFlow
                        self.FixedReturnFlow[returnNum - 1] = True
                else:
                    returnNodeMassFlow = 0.0
                if returnNum == 1:
                    if (state.dataGlobal.DoingSizing) and numRetNodes == 1:
                        returnNodeMassFlow = ExpTotalReturnMassFlow
                        if airLoop > 0:
                            if not state.dataAirSystemsData.PrimaryAirSystems[airLoop].OASysExists or (state.dataAirLoop.AirLoopFlow[airLoop].MaxOutAir == 0.0):
                                ExpTotalReturnMassFlow = max(0.0, ExpTotalReturnMassFlow - self.ZoneExhBalanced + self.ZoneExh)
                                returnNodeMassFlow = ExpTotalReturnMassFlow
                    elif not state.dataGlobal.DoingSizing:
                        if self.NumReturnFlowBasisNodes > 0:
                            var basisNodesMassFlow: Float64 = 0.0
                            for nodeNum in range(1, self.NumReturnFlowBasisNodes + 1):
                                basisNodesMassFlow += state.dataLoopNodes.Node[self.ReturnFlowBasisNode[nodeNum - 1]].MassFlowRate
                            returnNodeMassFlow = max(0.0, (basisNodesMassFlow * returnSchedFrac))
                            self.FixedReturnFlow[returnNum - 1] = True
                        else:
                            if (numRetNodes == 1) and not self.FixedReturnFlow[returnNum - 1]:
                                returnNodeMassFlow = max(0.0, (ExpTotalReturnMassFlow * returnSchedFrac * airLoopReturnFrac))
                totReturnFlow += returnNodeMassFlow
                retNodeData.MassFlowRate = returnNodeMassFlow
                retNodeData.MassFlowRateMinAvail = 0.0
                if not self.FixedReturnFlow[returnNum - 1]:
                    totVarReturnFlow += returnNodeMassFlow
        if state.dataHeatBal.ZoneAirMassFlow.ZoneFlowAdjustment != DataHeatBalance.AdjustmentType.NoAdjustReturnAndMixing:
            ExpTotalReturnMassFlow = returnSchedFrac * ExpTotalReturnMassFlow
            var zoneTotReturnFlow: Float64 = 0.0
            var returnNodeMassFlow: Float64 = 0.0
            for returnNum in range(1, numRetNodes + 1):
                var retNode = self.ReturnNode[returnNum - 1]
                if retNode > 0:
                    if numRetNodes == 1:
                        returnNodeMassFlow = ExpTotalReturnMassFlow
                    else:
                        if ExpTotalReturnMassFlow > 0.0:
                            var returnAdjFactor = state.dataLoopNodes.Node[retNode].MassFlowRate / ExpTotalReturnMassFlow
                            returnNodeMassFlow = returnAdjFactor * ExpTotalReturnMassFlow
                        else:
                            returnNodeMassFlow = 0.0
                zoneTotReturnFlow += returnNodeMassFlow
            if zoneTotReturnFlow > 0.0:
                for returnNum in range(1, numRetNodes + 1):
                    var retNode = self.ReturnNode[returnNum - 1]
                    if retNode > 0:
                        if numRetNodes == 1:
                            state.dataLoopNodes.Node[retNode].MassFlowRate = ExpTotalReturnMassFlow
                            FinalTotalReturnMassFlow = ExpTotalReturnMassFlow
                        else:
                            var newReturnFlow: Float64 = 0.0
                            var returnAdjFactor = ExpTotalReturnMassFlow / zoneTotReturnFlow
                            var curReturnFlow = state.dataLoopNodes.Node[retNode].MassFlowRate
                            newReturnFlow = curReturnFlow * returnAdjFactor
                            state.dataLoopNodes.Node[retNode].MassFlowRate = newReturnFlow
                            FinalTotalReturnMassFlow += newReturnFlow
            else:
                FinalTotalReturnMassFlow = ExpTotalReturnMassFlow
        else:
            if (totReturnFlow > ExpTotalReturnMassFlow) and (totVarReturnFlow > 0.0):
                var newReturnFlow: Float64 = 0.0
                var returnAdjFactor = (1 - ((totReturnFlow - ExpTotalReturnMassFlow) / totVarReturnFlow))
                for returnNum in range(1, numRetNodes + 1):
                    var retNode = self.ReturnNode[returnNum - 1]
                    var curReturnFlow = state.dataLoopNodes.Node[retNode].MassFlowRate
                    if retNode > 0:
                        if not self.FixedReturnFlow[returnNum - 1]:
                            newReturnFlow = curReturnFlow * returnAdjFactor
                            FinalTotalReturnMassFlow += newReturnFlow
                            state.dataLoopNodes.Node[retNode].MassFlowRate = newReturnFlow
                        else:
                            FinalTotalReturnMassFlow += curReturnFlow
            else:
                FinalTotalReturnMassFlow = totReturnFlow

struct EquipmentData:
    var Parent: Bool
    var NumSubEquip: Int
    var TypeOf: String
    var Name: String
    var ON: Bool
    var NumInlets: Int
    var NumOutlets: Int
    var InletNodeNums: List[Int]
    var OutletNodeNums: List[Int]
    var NumMeteredVars: Int
    var MeteredVar: List[OutputProcessor.MeterData]
    var SubEquipData: List[SubEquipmentData]
    var EnergyTransComp: Int
    var ZoneEqToPlantPtr: Int
    var TotPlantSupplyElec: Float64
    var TotPlantSupplyGas: Float64
    var TotPlantSupplyPurch: Float64
    var OpMode: Int

    def __init__(inout self):
        self.Parent = False
        self.NumSubEquip = 0
        self.TypeOf = ""
        self.Name = ""
        self.ON = True
        self.NumInlets = 0
        self.NumOutlets = 0
        self.InletNodeNums = List[Int]()
        self.OutletNodeNums = List[Int]()
        self.NumMeteredVars = 0
        self.MeteredVar = List[OutputProcessor.MeterData]()
        self.SubEquipData = List[SubEquipmentData]()
        self.EnergyTransComp = 0
        self.ZoneEqToPlantPtr = 0
        self.TotPlantSupplyElec = 0.0
        self.TotPlantSupplyGas = 0.0
        self.TotPlantSupplyPurch = 0.0
        self.OpMode = 0

struct EquipList:
    var Name: String
    var LoadDistScheme: DataZoneEquipment.LoadDist
    var NumOfEquipTypes: Int
    var NumAvailHeatEquip: Int
    var NumAvailCoolEquip: Int
    var EquipTypeName: List[String]
    var EquipType: List[DataZoneEquipment.ZoneEquipType]
    var EquipName: List[String]
    var EquipIndex: List[Int]
    var zoneEquipSplitterIndex: List[Int]
    var compPointer: List[Optional[HVACSystemData]]
    var CoolingPriority: List[Int]
    var HeatingPriority: List[Int]
    var sequentialCoolingFractionScheds: List[Optional[Sched.Schedule]]
    var sequentialHeatingFractionScheds: List[Optional[Sched.Schedule]]
    var CoolingCapacity: List[Int]
    var HeatingCapacity: List[Int]
    var EquipData: List[EquipmentData]

    def __init__(inout self):
        self.Name = ""
        self.LoadDistScheme = DataZoneEquipment.LoadDist.Sequential
        self.NumOfEquipTypes = 0
        self.NumAvailHeatEquip = 0
        self.NumAvailCoolEquip = 0
        self.EquipTypeName = List[String]()
        self.EquipType = List[DataZoneEquipment.ZoneEquipType]()
        self.EquipName = List[String]()
        self.EquipIndex = List[Int]()
        self.zoneEquipSplitterIndex = List[Int]()
        self.compPointer = List[Optional[HVACSystemData]]()
        self.CoolingPriority = List[Int]()
        self.HeatingPriority = List[Int]()
        self.sequentialCoolingFractionScheds = List[Optional[Sched.Schedule]]()
        self.sequentialHeatingFractionScheds = List[Optional[Sched.Schedule]]()
        self.CoolingCapacity = List[Int]()
        self.HeatingCapacity = List[Int]()
        self.EquipData = List[EquipmentData]()

    def getPrioritiesForInletNode(inout self, state: EnergyPlusData, inletNodeNum: Int, inout coolingPriority: Int, inout heatingPriority: Int):
        var equipFound: Bool = False
        for equipNum in range(1, self.NumOfEquipTypes + 1):
            if self.EquipType[equipNum - 1] == DataZoneEquipment.ZoneEquipType.AirDistributionUnit:
                if inletNodeNum == state.dataDefineEquipment.AirDistUnit[self.EquipIndex[equipNum - 1]].OutletNodeNum:
                    equipFound = True
            if equipFound:
                coolingPriority = self.CoolingPriority[equipNum - 1]
                heatingPriority = self.HeatingPriority[equipNum - 1]
                break
        var minIterations = state.dataHVACGlobal.MinAirLoopIterationsAfterFirst
        if self.LoadDistScheme == DataZoneEquipment.LoadDist.Sequential:
            minIterations = max(coolingPriority, heatingPriority, minIterations)
        elif self.LoadDistScheme == DataZoneEquipment.LoadDist.Uniform:

        elif self.LoadDistScheme == DataZoneEquipment.LoadDist.UniformPLR:
            minIterations = max(2, minIterations)
        elif self.LoadDistScheme == DataZoneEquipment.LoadDist.SequentialUniformPLR:
            minIterations = max((coolingPriority + 1), (heatingPriority + 1), minIterations)
        state.dataHVACGlobal.MinAirLoopIterationsAfterFirst = minIterations

    def SequentialHeatingFraction(inout self, state: EnergyPlusData, equipNum: Int) -> Float64:
        return self.sequentialHeatingFractionScheds[equipNum - 1].getCurrentVal()

    def SequentialCoolingFraction(inout self, state: EnergyPlusData, equipNum: Int) -> Float64:
        return self.sequentialCoolingFractionScheds[equipNum - 1].getCurrentVal()

struct ZoneEquipSplitterMixerSpace:
    var spaceIndex: Int
    var fraction: Float64
    var spaceNodeNum: Int

    def __init__(inout self):
        self.spaceIndex = 0
        self.fraction = 0.0
        self.spaceNodeNum = 0

struct ZoneEquipmentSplitterMixer:
    var Name: String
    var spaceEquipType: Node.ConnectionObjectType
    var spaceSizingBasis: DataZoneEquipment.SpaceEquipSizingBasis
    var spaces: List[ZoneEquipSplitterMixerSpace]

    def __init__(inout self):
        self.Name = ""
        self.spaceEquipType = Node.ConnectionObjectType.Invalid
        self.spaceSizingBasis = DataZoneEquipment.SpaceEquipSizingBasis.Invalid
        self.spaces = List[ZoneEquipSplitterMixerSpace]()

    def size(inout self, state: EnergyPlusData):
        var anyAutoSize: Bool = False
        for s in self.spaces:
            if s.fraction == DataSizing.AutoSize:
                anyAutoSize = True
                break
        if not anyAutoSize:
            return
        if not state.dataHeatBal.doSpaceHeatBalanceSizing and (self.spaceSizingBasis == DataZoneEquipment.SpaceEquipSizingBasis.DesignCoolingLoad or self.spaceSizingBasis == DataZoneEquipment.SpaceEquipSizingBasis.DesignHeatingLoad):
            ShowSevereError(state, "ZoneEquipmentSplitterMixer::size: " + DataZoneEquipment.spaceEquipSizingBasisNamesUC[Int(self.spaceSizingBasis)] + " is unknown for " + Node.ConnectionObjectTypeNames[Int(self.spaceEquipType)] + "=" + self.Name + ". Unable to autosize Space Fractions.")
            ShowFatalError(state, "Set \"Do Space Heat Balance for Sizing\" to Yes in ZoneAirHeatBalanceAlgorithm or choose a different Space Fraction Method.")
            return
        var spacesTotal: Float64 = 0.0
        if self.spaceSizingBasis == DataZoneEquipment.SpaceEquipSizingBasis.DesignCoolingLoad:
            for thisSpace in self.spaces:
                spacesTotal += state.dataSize.FinalSpaceSizing[thisSpace.spaceIndex].DesCoolLoad
        elif self.spaceSizingBasis == DataZoneEquipment.SpaceEquipSizingBasis.DesignHeatingLoad:
            for thisSpace in self.spaces:
                spacesTotal += state.dataSize.FinalSpaceSizing[thisSpace.spaceIndex].DesHeatLoad
        elif self.spaceSizingBasis == DataZoneEquipment.SpaceEquipSizingBasis.FloorArea:
            for thisSpace in self.spaces:
                spacesTotal += state.dataHeatBal.space[thisSpace.spaceIndex].FloorArea
        elif self.spaceSizingBasis == DataZoneEquipment.SpaceEquipSizingBasis.Volume:
            for thisSpace in self.spaces:
                spacesTotal += state.dataHeatBal.space[thisSpace.spaceIndex].Volume
        elif self.spaceSizingBasis == DataZoneEquipment.SpaceEquipSizingBasis.PerimeterLength:
            for thisSpace in self.spaces:
                spacesTotal += state.dataHeatBal.space[thisSpace.spaceIndex].extPerimeter
        else:
            return
        if spacesTotal < 0.00001:
            ShowSevereError(state, "ZoneEquipmentSplitterMixer::size: Total " + DataZoneEquipment.spaceEquipSizingBasisNamesUC[Int(self.spaceSizingBasis)] + " is zero for " + Node.ConnectionObjectTypeNames[Int(self.spaceEquipType)] + "=" + self.Name + ". Unable to autosize Space Fractions.")
            var spaceFrac: Float64 = 1.0 / Float64(len(self.spaces))
            ShowContinueError(state, "Setting space fractions to 1/number of spaces = " + str(spaceFrac) + ".")
            for thisSpace in self.spaces:
                thisSpace.fraction = spaceFrac
        else:
            for thisSpace in self.spaces:
                if thisSpace.fraction == DataSizing.AutoSize:
                    if self.spaceSizingBasis == DataZoneEquipment.SpaceEquipSizingBasis.DesignCoolingLoad:
                        thisSpace.fraction = state.dataSize.FinalSpaceSizing[thisSpace.spaceIndex].DesCoolLoad / spacesTotal
                    elif self.spaceSizingBasis == DataZoneEquipment.SpaceEquipSizingBasis.DesignHeatingLoad:
                        thisSpace.fraction = state.dataSize.FinalSpaceSizing[thisSpace.spaceIndex].DesHeatLoad / spacesTotal
                    elif self.spaceSizingBasis == DataZoneEquipment.SpaceEquipSizingBasis.FloorArea:
                        thisSpace.fraction = state.dataHeatBal.space[thisSpace.spaceIndex].FloorArea / spacesTotal
                    elif self.spaceSizingBasis == DataZoneEquipment.SpaceEquipSizingBasis.Volume:
                        thisSpace.fraction = state.dataHeatBal.space[thisSpace.spaceIndex].Volume / spacesTotal
                    elif self.spaceSizingBasis == DataZoneEquipment.SpaceEquipSizingBasis.PerimeterLength:
                        thisSpace.fraction = state.dataHeatBal.space[thisSpace.spaceIndex].extPerimeter / spacesTotal
        var spaceCounter: Int = 0
        for thisSpace in self.spaces:
            spaceCounter += 1
            BaseSizer.reportSizerOutput(state, Node.ConnectionObjectTypeNames[Int(self.spaceEquipType)], self.Name, "Space " + str(spaceCounter) + " Fraction", thisSpace.fraction)

struct ZoneEquipmentSplitter(ZoneEquipmentSplitterMixer):
    var zoneEquipType: DataZoneEquipment.ZoneEquipType
    var zoneEquipName: String
    var zoneEquipOutletNodeNum: Int
    var tstatControl: DataZoneEquipment.ZoneEquipTstatControl
    var controlSpaceIndex: Int
    var controlSpaceNumber: Int
    var saveZoneSysSensibleDemand: DataZoneEnergyDemands.ZoneSystemSensibleDemand
    var saveZoneSysMoistureDemand: DataZoneEnergyDemands.ZoneSystemMoistureDemand

    def __init__(inout self):
        super().__init__()
        self.zoneEquipType = DataZoneEquipment.ZoneEquipType.Invalid
        self.zoneEquipName = ""
        self.zoneEquipOutletNodeNum = 0
        self.tstatControl = DataZoneEquipment.ZoneEquipTstatControl.Invalid
        self.controlSpaceIndex = 0
        self.controlSpaceNumber = 0
        self.saveZoneSysSensibleDemand = DataZoneEnergyDemands.ZoneSystemSensibleDemand()
        self.saveZoneSysMoistureDemand = DataZoneEnergyDemands.ZoneSystemMoistureDemand()

    def distributeOutput(inout self, state: EnergyPlusData, zoneNum: Int, sysOutputProvided: Float64, latOutputProvided: Float64, nonAirSysOutput: Float64, equipTypeNum: Int):
        for splitterSpace in self.spaces:
            if self.tstatControl != DataZoneEquipment.ZoneEquipTstatControl.Ideal:
                state.dataZoneEnergyDemand.ZoneSysEnergyDemand[zoneNum] = self.saveZoneSysSensibleDemand
                state.dataZoneEnergyDemand.ZoneSysMoistureDemand[zoneNum] = self.saveZoneSysMoistureDemand
            var spaceFraction: Float64 = splitterSpace.fraction
            if self.tstatControl == DataZoneEquipment.ZoneEquipTstatControl.Ideal:
                var thisZoneSysEnergyDemand = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[zoneNum]
                if thisZoneSysEnergyDemand.RemainingOutputRequired != 0.0:
                    spaceFraction = state.dataZoneEnergyDemand.spaceSysEnergyDemand[splitterSpace.spaceIndex].RemainingOutputRequired / thisZoneSysEnergyDemand.RemainingOutputRequired
            var spaceSysOutputProvided: Float64 = sysOutputProvided * spaceFraction
            var spaceLatOutputProvided: Float64 = latOutputProvided * spaceFraction
            state.dataZoneTempPredictorCorrector.spaceHeatBalance[splitterSpace.spaceIndex].NonAirSystemResponse += nonAirSysOutput * spaceFraction
            if self.zoneEquipOutletNodeNum > 0 and splitterSpace.spaceNodeNum > 0:
                var equipOutletNode = state.dataLoopNodes.Node[self.zoneEquipOutletNodeNum]
                var spaceInletNode = state.dataLoopNodes.Node[splitterSpace.spaceNodeNum]
                spaceInletNode.MassFlowRate = equipOutletNode.MassFlowRate * spaceFraction
                spaceInletNode.MassFlowRateMaxAvail = equipOutletNode.MassFlowRateMaxAvail * spaceFraction
                spaceInletNode.MassFlowRateMinAvail = equipOutletNode.MassFlowRateMinAvail * spaceFraction
                spaceInletNode.Temp = equipOutletNode.Temp
                spaceInletNode.HumRat = equipOutletNode.HumRat
                spaceInletNode.CO2 = equipOutletNode.CO2
            ZoneEquipmentManager.updateSystemOutputRequired(state, zoneNum, spaceSysOutputProvided, spaceLatOutputProvided, state.dataZoneEnergyDemand.spaceSysEnergyDemand[splitterSpace.spaceIndex], state.dataZoneEnergyDemand.spaceSysMoistureDemand[splitterSpace.spaceIndex], equipTypeNum)

    def adjustLoads(inout self, state: EnergyPlusData, zoneNum: Int, equipTypeNum: Int):
        var thisZoneEnergyDemand = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[zoneNum]
        var thisZoneMoistureDemand = state.dataZoneEnergyDemand.ZoneSysMoistureDemand[zoneNum]
        var zoneTstatSetpt = state.dataHeatBalFanSys.zoneTstatSetpts[zoneNum]
        var sensibleRatio: Float64 = 1.0
        var latentRatio: Float64 = 1.0
        if self.tstatControl == DataZoneEquipment.ZoneEquipTstatControl.Ideal:
            return
        elif self.tstatControl == DataZoneEquipment.ZoneEquipTstatControl.SingleSpace:
            var controlSpaceFrac: Float64 = self.spaces[self.controlSpaceNumber].fraction
            if controlSpaceFrac > 0.0:
                if thisZoneEnergyDemand.RemainingOutputRequired != 0.0:
                    sensibleRatio = (state.dataZoneEnergyDemand.spaceSysEnergyDemand[self.controlSpaceIndex].RemainingOutputRequired / thisZoneEnergyDemand.RemainingOutputRequired) / controlSpaceFrac
                if thisZoneMoistureDemand.RemainingOutputRequired != 0.0:
                    latentRatio = (state.dataZoneEnergyDemand.spaceSysMoistureDemand[self.controlSpaceIndex].RemainingOutputRequired / thisZoneMoistureDemand.RemainingOutputRequired) / controlSpaceFrac
        elif self.tstatControl == DataZoneEquipment.ZoneEquipTstatControl.Maximum:
            var maxSpaceIndex: Int = 0
            var maxDeltaTemp: Float64 = 0.0
            var maxSpaceFrac: Float64 = 1.0
            for splitterSpace in self.spaces:
                var spaceTemp = state.dataZoneTempPredictorCorrector.spaceHeatBalance[splitterSpace.spaceIndex].T1
                var spaceDeltaTemp = max((zoneTstatSetpt.setptLo - spaceTemp), (spaceTemp - zoneTstatSetpt.setptHi))
                if spaceDeltaTemp > maxDeltaTemp:
                    maxSpaceIndex = splitterSpace.spaceIndex
                    maxSpaceFrac = splitterSpace.fraction
                    maxDeltaTemp = spaceDeltaTemp
            if (maxSpaceIndex > 0) and (maxSpaceFrac > 0.0):
                if thisZoneEnergyDemand.RemainingOutputRequired != 0.0:
                    sensibleRatio = (state.dataZoneEnergyDemand.spaceSysEnergyDemand[maxSpaceIndex].RemainingOutputRequired / thisZoneEnergyDemand.RemainingOutputRequired) / maxSpaceFrac
                if thisZoneMoistureDemand.RemainingOutputRequired != 0.0:
                    latentRatio = (state.dataZoneEnergyDemand.spaceSysMoistureDemand[maxSpaceIndex].RemainingOutputRequired / thisZoneMoistureDemand.RemainingOutputRequired) / maxSpaceFrac
        self.saveZoneSysSensibleDemand = thisZoneEnergyDemand
        self.saveZoneSysMoistureDemand = thisZoneMoistureDemand
        ZoneEquipmentManager.adjustSystemOutputRequired(sensibleRatio, latentRatio, state.dataZoneEnergyDemand.ZoneSysEnergyDemand[zoneNum], state.dataZoneEnergyDemand.ZoneSysMoistureDemand[zoneNum], equipTypeNum)

struct ZoneMixer(ZoneEquipmentSplitterMixer):
    var outletNodeNum: Int

    def __init__(inout self):
        super().__init__()
        self.outletNodeNum = 0

    def setOutletConditions(inout self, state: EnergyPlusData):
        if self.outletNodeNum == 0:
            return
        var sumEnthalpy: Float64 = 0.0
        var sumHumRat: Float64 = 0.0
        var sumCO2: Float64 = 0.0
        var sumGenContam: Float64 = 0.0
        var sumPressure: Float64 = 0.0
        var sumFractions: Float64 = 0.0
        var outletNode = state.dataLoopNodes.Node[self.outletNodeNum]
        for mixerSpace in self.spaces:
            var spaceOutletNode = state.dataLoopNodes.Node[mixerSpace.spaceNodeNum]
            sumEnthalpy += spaceOutletNode.Enthalpy * mixerSpace.fraction
            sumHumRat += spaceOutletNode.HumRat * mixerSpace.fraction
            if state.dataContaminantBalance.Contaminant.CO2Simulation:
                sumCO2 += spaceOutletNode.CO2 * mixerSpace.fraction
            if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
                sumGenContam += spaceOutletNode.GenContam * mixerSpace.fraction
            sumPressure += spaceOutletNode.Press * mixerSpace.fraction
            sumFractions += mixerSpace.fraction
        if sumFractions > 0:
            outletNode.Enthalpy = sumEnthalpy / sumFractions
            outletNode.HumRat = sumHumRat / sumFractions
            if state.dataContaminantBalance.Contaminant.CO2Simulation:
                outletNode.CO2 = sumCO2 / sumFractions
            if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
                outletNode.GenContam = sumGenContam / sumFractions
            outletNode.Press = sumPressure / sumFractions
            outletNode.Temp = Psychrometrics.PsyTdbFnHW(outletNode.Enthalpy, outletNode.HumRat)

struct ZoneEquipmentMixer(ZoneMixer):
    def __init__(inout self):
        super().__init__()

    def setInletFlows(inout self, state: EnergyPlusData):
        if self.outletNodeNum == 0:
            return
        var equipInletNode = state.dataLoopNodes.Node[self.outletNodeNum]
        for mixerSpace in self.spaces:
            var spaceOutletNode = state.dataLoopNodes.Node[mixerSpace.spaceNodeNum]
            spaceOutletNode.MassFlowRate = equipInletNode.MassFlowRate * mixerSpace.fraction
            spaceOutletNode.MassFlowRateMaxAvail = equipInletNode.MassFlowRateMaxAvail * mixerSpace.fraction
            spaceOutletNode.MassFlowRateMinAvail = equipInletNode.MassFlowRateMinAvail * mixerSpace.fraction

struct ZoneReturnMixer(ZoneMixer):
    def __init__(inout self):
        super().__init__()

    def setInletConditions(inout self, state: EnergyPlusData):
        for mixerSpace in self.spaces:
            var spaceOutletNode = state.dataLoopNodes.Node[mixerSpace.spaceNodeNum]
            var spaceZoneNodeNum = state.dataZoneEquip.spaceEquipConfig[mixerSpace.spaceIndex].ZoneNode
            var spaceNode = state.dataLoopNodes.Node[spaceZoneNodeNum]
            spaceOutletNode.Temp = spaceNode.Temp
            spaceOutletNode.HumRat = spaceNode.HumRat
            spaceOutletNode.Enthalpy = spaceNode.Enthalpy
            spaceOutletNode.Press = spaceNode.Press
            if state.dataContaminantBalance.Contaminant.CO2Simulation:
                spaceOutletNode.CO2 = spaceNode.CO2
            if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
                spaceOutletNode.GenContam = spaceNode.GenContam

    def setInletFlows(inout self, state: EnergyPlusData):
        if self.outletNodeNum == 0:
            return
        var outletNode = state.dataLoopNodes.Node[self.outletNodeNum]
        var sumMixerInletMassFlow: Float64 = 0.0
        for mixerSpace in self.spaces:
            var spaceEquipConfig = state.dataZoneEquip.spaceEquipConfig[mixerSpace.spaceIndex]
            var outletMassFlowRate: Float64 = outletNode.MassFlowRate
            var spaceReturnFlow: Float64 = 0.0
            spaceEquipConfig.calcReturnFlows(state, outletMassFlowRate, spaceReturnFlow)
            sumMixerInletMassFlow += spaceReturnFlow
        for mixerSpace in self.spaces:
            var spaceOutletNode = state.dataLoopNodes.Node[mixerSpace.spaceNodeNum]
            if sumMixerInletMassFlow > 0.0:
                mixerSpace.fraction = spaceOutletNode.MassFlowRate / sumMixerInletMassFlow
            else:
                mixerSpace.fraction = 0.0
            spaceOutletNode.MassFlowRate = outletNode.MassFlowRate * mixerSpace.fraction
            spaceOutletNode.MassFlowRateMaxAvail = outletNode.MassFlowRateMaxAvail * mixerSpace.fraction
            spaceOutletNode.MassFlowRateMinAvail = outletNode.MassFlowRateMinAvail * mixerSpace.fraction

struct ControlList:
    var Name: String
    var NumOfControls: Int
    var ControlType: List[String]
    var ControlName: List[String]

    def __init__(inout self):
        self.Name = ""
        self.NumOfControls = 0
        self.ControlType = List[String]()
        self.ControlName = List[String]()

struct SupplyAir:
    var Name: String
    var NumOfComponents: Int
    var InletNodeNum: Int
    var ComponentType: List[String]
    var ComponentTypeEnum: List[DataZoneEquipment.AirLoopHVACZone]
    var ComponentName: List[String]
    var ComponentIndex: List[Int]
    var SplitterIndex: List[Int]
    var PlenumIndex: List[Int]
    var NumOutletNodes: Int
    var OutletNode: List[Int]
    var OutletNodeSupplyPathCompNum: List[Int]
    var NumNodes: Int
    var Node: List[Int]
    var NodeType: List[DataZoneEquipment.AirNodeType]

    def __init__(inout self):
        self.Name = ""
        self.NumOfComponents = 0
        self.InletNodeNum = 0
        self.ComponentType = List[String]()
        self.ComponentTypeEnum = List[DataZoneEquipment.AirLoopHVACZone]()
        self.ComponentName = List[String]()
        self.ComponentIndex = List[Int]()
        self.SplitterIndex = List[Int]()
        self.PlenumIndex = List[Int]()
        self.NumOutletNodes = 0
        self.OutletNode = List[Int]()
        self.OutletNodeSupplyPathCompNum = List[Int]()
        self.NumNodes = 0
        self.Node = List[Int]()
        self.NodeType = List[DataZoneEquipment.AirNodeType]()

struct ReturnAir:
    var Name: String
    var NumOfComponents: Int
    var OutletNodeNum: Int
    var OutletRetPathCompNum: Int
    var ComponentType: List[String]
    var ComponentTypeEnum: List[DataZoneEquipment.AirLoopHVACZone]
    var ComponentName: List[String]
    var ComponentIndex: List[Int]

    def __init__(inout self):
        self.Name = ""
        self.NumOfComponents = 0
        self.OutletNodeNum = 0
        self.OutletRetPathCompNum = 0
        self.ComponentType = List[String]()
        self.ComponentTypeEnum = List[DataZoneEquipment.AirLoopHVACZone]()
        self.ComponentName = List[String]()
        self.ComponentIndex = List[Int]()

# Functions
def GetZoneEquipmentData(state: EnergyPlusData):
    using Node.CheckUniqueNodeNames
    using Node.CheckUniqueNodeNumbers
    using Node.EndUniqueNodeCheck
    using Node.GetNodeNums
    using Node.GetOnlySingleNode
    using Node.InitUniqueNodeCheck
    let RoutineName: String = "GetZoneEquipmentData: "
    var NumAlphas: Int
    var NumNums: Int
    var IOStat: Int
    var AlphArray: List[String]
    var NumArray: List[Float64]
    var MaxAlphas: Int
    var MaxNums: Int
    var NumParams: Int
    var NodeNums: List[Int]
    var IsNotOK: Bool
    var CurrentModuleObject: String
    var cAlphaFields: List[String]
    var cNumericFields: List[String]
    var lAlphaBlanks: List[Bool]
    var lNumericBlanks: List[Bool]

    struct EquipListAudit:
        var ObjectType: String
        var ObjectName: String
        var OnListNum: Int
        def __init__(inout self):
            self.ObjectType = ""
            self.ObjectName = ""
            self.OnListNum = 0

    var ZoneEquipListAcct: List[EquipListAudit]

    var numControlledZones = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "ZoneHVAC:EquipmentConnections")
    var numControlledSpaces = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "SpaceHVAC:EquipmentConnections")
    state.dataZoneEquip.NumOfZoneEquipLists = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "ZoneHVAC:EquipmentList")
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, "NodeList", NumParams, NumAlphas, NumNums)
    NodeNums = List[Int](len=NumParams, fill=0)
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, "ZoneHVAC:EquipmentList", NumParams, NumAlphas, NumNums)
    MaxAlphas = NumAlphas
    MaxNums = NumNums
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, "ZoneHVAC:EquipmentConnections", NumParams, NumAlphas, NumNums)
    MaxAlphas = max(MaxAlphas, NumAlphas)
    MaxNums = max(MaxNums, NumNums)
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, "SpaceHVAC:EquipmentConnections", NumParams, NumAlphas, NumNums)
    MaxAlphas = max(MaxAlphas, NumAlphas)
    MaxNums = max(MaxNums, NumNums)
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, "AirLoopHVAC:SupplyPath", NumParams, NumAlphas, NumNums)
    MaxAlphas = max(MaxAlphas, NumAlphas)
    MaxNums = max(MaxNums, NumNums)
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, "AirLoopHVAC:ReturnPath", NumParams, NumAlphas, NumNums)
    MaxAlphas = max(MaxAlphas, NumAlphas)
    MaxNums = max(MaxNums, NumNums)
    AlphArray = List[String](len=MaxAlphas, fill="")
    NumArray = List[Float64](len=MaxNums, fill=0.0)
    cAlphaFields = List[String](len=MaxAlphas, fill="")
    cNumericFields = List[String](len=MaxNums, fill="")
    lAlphaBlanks = List[Bool](len=MaxAlphas, fill=True)
    lNumericBlanks = List[Bool](len=MaxNums, fill=True)

    if not state.dataZoneEquip.SupplyAirPath:
        state.dataZoneEquip.NumSupplyAirPaths = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "AirLoopHVAC:SupplyPath")
        state.dataZoneEquip.SupplyAirPath = List[SupplyAir](len=state.dataZoneEquip.NumSupplyAirPaths, fill=SupplyAir())
    if not state.dataZoneEquip.ReturnAirPath:
        state.dataZoneEquip.NumReturnAirPaths = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "AirLoopHVAC:ReturnPath")
        state.dataZoneEquip.ReturnAirPath = List[ReturnAir](len=state.dataZoneEquip.NumReturnAirPaths, fill=ReturnAir())
    if not state.dataHeatBal.ZoneIntGain:
        DataHeatBalance.AllocateIntGains(state)
    state.dataZoneEquip.ZoneEquipConfig = List[EquipConfiguration](len=state.dataGlobal.NumOfZones, fill=Equ