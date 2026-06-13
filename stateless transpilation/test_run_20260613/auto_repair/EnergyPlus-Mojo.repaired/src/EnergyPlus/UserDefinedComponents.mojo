from std import format, floor, min, max
from Psychrometrics import PsyHFnTdbW, PsyRhoAirFnPbTdbW, PsyCpAirFnW
from PlantUtilities import InitComponentNodes, RegisterPlantCompDesignFlow, SetComponentFlowRate, SafeCopyPlantNode, ScanPlantLoopsForObject
from Node.DataLoopNode import Node, GetOnlySingleNode, TestCompSet, ConnectionObjectType, FluidType, ConnectionType, CompFluidStream, ObjectIsNotParent
from Plant.DataPlant import DataPlant, LoopFlowStatus, HowMet, PlantEquipmentType, CompData
from Plant.PlantLocation import PlantLocation
from EMSManager import EMSManager, EMSCallFrom
from WaterManager import SetupTankDemandComponent, SetupTankSupplyComponent
from UtilityRoutines import ShowFatalError, ShowSevereError, ShowContinueError, FindItemInList, FindItem, makeUPPER
from GlobalNames import VerifyUniqueCoilName
from DataHeatBalance import DataHeatBalance, IntGainType
from HeatBalanceInternalHeatGains import SetupZoneInternalGain
from DataRuntimeLanguage import EMSProgramCallManager
from DataLoopNode import NodeID

# Forward declarations for structs defined elsewhere
struct EnergyPlusData:

# For SetupEMSActuator and SetupEMSInternalVariable - assume they are imported
from EMSManager import SetupEMSActuator, SetupEMSInternalVariable

# For getEnumValue - assume imported from some utility
from UtilityRoutines import getEnumValue

# For InputProcessor
from InputProcessing.InputProcessor import InputProcessor

# For DataEnvironment
from DataEnvironment import dataEnvrn

# For DataHeatBalance Zone list
from DataHeatBalance import dataHeatBal

# For DataGlobal
from DataGlobals import dataGlobal

# For DataWater
from DataWater import dataWaterData

# For DataZoneEnergyDemands
from DataZoneEnergyDemands import ZoneSysEnergyDemand, ZoneSysMoistureDemand

# For DataZoneEquipment
from DataZoneEquipment import ZoneEquipConfig

# For DataDefineEquip
from DataDefineEquip import AirDistUnit, dataDefineEquipment

# For PluginManager
from PluginManager import pluginManager

# For RuntimeLanguage
from DataRuntimeLanguage import dataRuntimeLang

# For Loop flow status and how met type names
from Plant.Enums import HowMetTypeNamesUC, LoopFlowStatusTypeNamesUC

# For fluid properties
from FluidProperties import getDensity, getSpecificHeat

# For AirDistUnit's TermUnitSizingNum, ZoneEqNum etc. - some struct fields

struct PlantConnectionStruct:
    var ErlInitProgramMngr: Int
    var ErlSimProgramMngr: Int
    var simPluginLocation: Int
    var initPluginLocation: Int
    var simCallbackIndex: Int = -1
    var initCallbackIndex: Int = -1
    var plantLoc: PlantLocation
    var InletNodeNum: Int
    var OutletNodeNum: Int
    var FlowPriority: DataPlant.LoopFlowStatus
    var HowLoadServed: DataPlant.HowMet
    var LowOutTempLimit: Float64
    var HiOutTempLimit: Float64
    var MassFlowRateRequest: Float64
    var MassFlowRateMin: Float64
    var MassFlowRateMax: Float64
    var DesignVolumeFlowRate: Float64
    var MyLoad: Float64
    var MinLoad: Float64
    var MaxLoad: Float64
    var OptLoad: Float64
    var InletRho: Float64
    var InletCp: Float64
    var InletTemp: Float64
    var InletMassFlowRate: Float64
    var OutletTemp: Float64

    def __init__(inout self):
        self.ErlInitProgramMngr = 0
        self.ErlSimProgramMngr = 0
        self.simPluginLocation = -1
        self.initPluginLocation = -1
        self.simCallbackIndex = -1
        self.initCallbackIndex = -1
        # plantLoc default initialized (empty PlantLocation)
        self.plantLoc = PlantLocation()
        self.InletNodeNum = 0
        self.OutletNodeNum = 0
        self.FlowPriority = DataPlant.LoopFlowStatus.Invalid
        self.HowLoadServed = DataPlant.HowMet.Invalid
        self.LowOutTempLimit = 0.0
        self.HiOutTempLimit = 0.0
        self.MassFlowRateRequest = 0.0
        self.MassFlowRateMin = 0.0
        self.MassFlowRateMax = 0.0
        self.DesignVolumeFlowRate = 0.0
        self.MyLoad = 0.0
        self.MinLoad = 0.0
        self.MaxLoad = 0.0
        self.OptLoad = 0.0
        self.InletRho = 0.0
        self.InletCp = 0.0
        self.InletTemp = 0.0
        self.InletMassFlowRate = 0.0
        self.OutletTemp = 0.0

struct AirConnectionStruct:
    var InletNodeNum: Int
    var OutletNodeNum: Int
    var InletRho: Float64
    var InletCp: Float64
    var InletTemp: Float64
    var InletHumRat: Float64
    var InletMassFlowRate: Float64
    var OutletTemp: Float64
    var OutletHumRat: Float64
    var OutletMassFlowRate: Float64

    def __init__(inout self):
        self.InletNodeNum = 0
        self.OutletNodeNum = 0
        self.InletRho = 0.0
        self.InletCp = 0.0
        self.InletTemp = 0.0
        self.InletHumRat = 0.0
        self.InletMassFlowRate = 0.0
        self.OutletTemp = 0.0
        self.OutletHumRat = 0.0
        self.OutletMassFlowRate = 0.0

struct WaterUseTankConnectionStruct:
    var SuppliedByWaterSystem: Bool
    var SupplyTankID: Int
    var SupplyTankDemandARRID: Int
    var SupplyVdotRequest: Float64
    var CollectsToWaterSystem: Bool
    var CollectionTankID: Int
    var CollectionTankSupplyARRID: Int
    var CollectedVdot: Float64

    def __init__(inout self):
        self.SuppliedByWaterSystem = False
        self.SupplyTankID = 0
        self.SupplyTankDemandARRID = 0
        self.SupplyVdotRequest = 0.0
        self.CollectsToWaterSystem = False
        self.CollectionTankID = 0
        self.CollectionTankSupplyARRID = 0
        self.CollectedVdot = 0.0

struct ZoneInternalGainsStruct:
    var DeviceHasInternalGains: Bool
    var ZoneNum: Int
    var ConvectionGainRate: Float64
    var ReturnAirConvectionGainRate: Float64
    var ThermalRadiationGainRate: Float64
    var LatentGainRate: Float64
    var ReturnAirLatentGainRate: Float64
    var CarbonDioxideGainRate: Float64
    var GenericContamGainRate: Float64

    def __init__(inout self):
        self.DeviceHasInternalGains = False
        self.ZoneNum = 0
        self.ConvectionGainRate = 0.0
        self.ReturnAirConvectionGainRate = 0.0
        self.ThermalRadiationGainRate = 0.0
        self.LatentGainRate = 0.0
        self.ReturnAirLatentGainRate = 0.0
        self.CarbonDioxideGainRate = 0.0
        self.GenericContamGainRate = 0.0

struct UserPlantComponentStruct:
    var Name: String
    var ErlSimProgramMngr: Int
    var simPluginLocation: Int
    var simCallbackIndex: Int = -1
    var NumPlantConnections: Int
    var Loop: List[PlantConnectionStruct]
    var Air: AirConnectionStruct
    var Water: WaterUseTankConnectionStruct
    var Zone: ZoneInternalGainsStruct
    var myOneTimeFlag: Bool

    def __init__(inout self):
        self.ErlSimProgramMngr = 0
        self.simPluginLocation = -1
        self.simCallbackIndex = -1
        self.NumPlantConnections = 0
        self.Loop = List[PlantConnectionStruct]()
        self.Air = AirConnectionStruct()
        self.Water = WaterUseTankConnectionStruct()
        self.Zone = ZoneInternalGainsStruct()
        self.myOneTimeFlag = True

    @staticmethod
    def factory(state: EnergyPlusData, objectName: String) -> PlantComponent:
        if state.dataUserDefinedComponents.GetPlantCompInput:
            GetUserDefinedPlantComponents(state)
            state.dataUserDefinedComponents.GetPlantCompInput = False
        for i in range(len(state.dataUserDefinedComponents.UserPlantComp)):
            thisComp = state.dataUserDefinedComponents.UserPlantComp[i]  # 0-based
            if thisComp.Name == objectName:
                return &thisComp
        ShowFatalError(state,
            format("LocalUserDefinedPlantComponentFactory: Error getting inputs for object named: {}", objectName))
        return None

    def onInitLoopEquip(inout self, state: EnergyPlusData, calledFromLocation: PlantLocation):
        var myLoad: Float64 = 0.0
        var thisLoop: Int = -1
        self.oneTimeInit(state)
        for loop in range(self.NumPlantConnections):
            if calledFromLocation.loopNum != self.Loop[loop].plantLoc.loopNum:
                continue
            if calledFromLocation.loopSideNum != self.Loop[loop].plantLoc.loopSideNum:
                continue
            thisLoop = loop
            break
        if thisLoop >= 0:
            self.initialize(state, thisLoop, myLoad)
            plantConnection = self.Loop[thisLoop]
            if plantConnection.ErlInitProgramMngr > 0:
                anyEMSRan: Bool
                EMSManager.ManageEMS(state, EMSManager.EMSCallFrom.UserDefinedComponentModel, anyEMSRan, plantConnection.ErlInitProgramMngr)
            elif plantConnection.initPluginLocation > -1:
                state.dataPluginManager.pluginManager.runSingleUserDefinedPlugin(state, plantConnection.initPluginLocation)
            elif plantConnection.initCallbackIndex > -1:
                state.dataPluginManager.pluginManager.runSingleUserDefinedCallback(state, plantConnection.initCallbackIndex)
            InitComponentNodes(state, plantConnection.MassFlowRateMin, plantConnection.MassFlowRateMax, plantConnection.InletNodeNum, plantConnection.OutletNodeNum)
            RegisterPlantCompDesignFlow(state, plantConnection.InletNodeNum, plantConnection.DesignVolumeFlowRate)
        else:
            ShowFatalError(state,
                format("SimUserDefinedPlantComponent: did not find where called from. Loop number called from ={}, loop side called from ={}.",
                    calledFromLocation.loopNum,
                    calledFromLocation.loopSideNum))

    def getDesignCapacities(inout self, state: EnergyPlusData, calledFromLocation: PlantLocation, MaxLoad: Float64, MinLoad: Float64, OptLoad: Float64):
        var thisLoop: Int = -1
        for loop in range(self.NumPlantConnections):
            if calledFromLocation.loopNum != self.Loop[loop].plantLoc.loopNum:
                continue
            if calledFromLocation.loopSideNum != self.Loop[loop].plantLoc.loopSideNum:
                continue
            thisLoop = loop
            break
        if thisLoop < 0:
            ShowFatalError(state,
                format("SimUserDefinedPlantComponent: did not find plant connection for {}. Loop number called from ={}, loop side called from ={}.",
                    self.Name,
                    calledFromLocation.loopNum,
                    calledFromLocation.loopSideNum))
        plantConnection = self.Loop[thisLoop]
        MinLoad = plantConnection.MinLoad
        MaxLoad = plantConnection.MaxLoad
        OptLoad = plantConnection.OptLoad

    def simulate(inout self, state: EnergyPlusData, calledFromLocation: PlantLocation, FirstHVACIteration: Bool, CurLoad: Float64, RunFlag: Bool):
        if state.dataGlobal.BeginEnvrnFlag:
            self.onInitLoopEquip(state, calledFromLocation)
        anyEMSRan: Bool
        var thisLoop: Int = -1
        for loop in range(self.NumPlantConnections):
            if calledFromLocation.loopNum != self.Loop[loop].plantLoc.loopNum:
                continue
            if calledFromLocation.loopSideNum != self.Loop[loop].plantLoc.loopSideNum:
                continue
            thisLoop = loop
            break
        if thisLoop < 0:
            ShowFatalError(state,
                format("SimUserDefinedPlantComponent: did not find plant connection for {}. Loop number called from ={}, loop side called from ={}.",
                    self.Name,
                    calledFromLocation.loopNum,
                    calledFromLocation.loopSideNum))
        self.initialize(state, thisLoop, CurLoad)
        plantConnection = self.Loop[thisLoop]
        if plantConnection.ErlSimProgramMngr > 0:
            EMSManager.ManageEMS(state, EMSManager.EMSCallFrom.UserDefinedComponentModel, anyEMSRan, plantConnection.ErlSimProgramMngr)
        elif plantConnection.simPluginLocation > -1:
            state.dataPluginManager.pluginManager.runSingleUserDefinedPlugin(state, plantConnection.simPluginLocation)
        elif plantConnection.simCallbackIndex > -1:
            state.dataPluginManager.pluginManager.runSingleUserDefinedCallback(state, plantConnection.simCallbackIndex)
        if self.ErlSimProgramMngr > 0:
            EMSManager.ManageEMS(state, EMSManager.EMSCallFrom.UserDefinedComponentModel, anyEMSRan, self.ErlSimProgramMngr)
        elif self.simPluginLocation > -1:
            state.dataPluginManager.pluginManager.runSingleUserDefinedPlugin(state, self.simPluginLocation)
        elif self.simCallbackIndex > -1:
            state.dataPluginManager.pluginManager.runSingleUserDefinedCallback(state, self.simCallbackIndex)
        self.report(state, thisLoop)

    def initialize(inout self, state: EnergyPlusData, LoopNum: Int, MyLoad: Float64):
        const RoutineName: String = "InitPlantUserComponent"
        self.oneTimeInit(state)
        if LoopNum < 0 or LoopNum >= self.NumPlantConnections:
            return
        plantConnection = self.Loop[LoopNum]
        plantConnection.MyLoad = MyLoad
        plantConnection.InletRho = plantConnection.plantLoc.loop.glycol.getDensity(state, state.dataLoopNodes.Node[plantConnection.InletNodeNum].Temp, RoutineName)
        plantConnection.InletCp = plantConnection.plantLoc.loop.glycol.getSpecificHeat(state, state.dataLoopNodes.Node[plantConnection.InletNodeNum].Temp, RoutineName)
        plantConnection.InletMassFlowRate = state.dataLoopNodes.Node[plantConnection.InletNodeNum].MassFlowRate
        plantConnection.InletTemp = state.dataLoopNodes.Node[plantConnection.InletNodeNum].Temp
        if self.Air.InletNodeNum > 0:
            self.Air.InletRho = PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress, state.dataLoopNodes.Node[self.Air.InletNodeNum].Temp, state.dataLoopNodes.Node[self.Air.InletNodeNum].HumRat, RoutineName)
            self.Air.InletCp = PsyCpAirFnW(state.dataLoopNodes.Node[self.Air.InletNodeNum].HumRat)
            self.Air.InletTemp = state.dataLoopNodes.Node[self.Air.InletNodeNum].Temp
            self.Air.InletMassFlowRate = state.dataLoopNodes.Node[self.Air.InletNodeNum].MassFlowRate
            self.Air.InletHumRat = state.dataLoopNodes.Node[self.Air.InletNodeNum].HumRat

    def report(inout self, state: EnergyPlusData, LoopNum: Int):
        if LoopNum < 0 or LoopNum >= self.NumPlantConnections:
            return
        plantConnection = self.Loop[LoopNum]
        SafeCopyPlantNode(state, plantConnection.InletNodeNum, plantConnection.OutletNodeNum)
        state.dataLoopNodes.Node[plantConnection.OutletNodeNum].Temp = plantConnection.OutletTemp
        SetComponentFlowRate(state, plantConnection.MassFlowRateRequest, plantConnection.InletNodeNum, plantConnection.OutletNodeNum, plantConnection.plantLoc)
        if self.Air.OutletNodeNum > 0:
            state.dataLoopNodes.Node[self.Air.OutletNodeNum].Temp = self.Air.OutletTemp
            state.dataLoopNodes.Node[self.Air.OutletNodeNum].HumRat = self.Air.OutletHumRat
            state.dataLoopNodes.Node[self.Air.OutletNodeNum].MassFlowRate = self.Air.OutletMassFlowRate
            state.dataLoopNodes.Node[self.Air.OutletNodeNum].Enthalpy = PsyHFnTdbW(self.Air.OutletTemp, self.Air.OutletHumRat)
        if self.Water.SuppliedByWaterSystem:
            state.dataWaterData.WaterStorage[self.Water.SupplyTankID].VdotRequestDemand[self.Water.SupplyTankDemandARRID] = self.Water.SupplyVdotRequest
        if self.Water.CollectsToWaterSystem:
            state.dataWaterData.WaterStorage[self.Water.CollectionTankID].VdotAvailSupply[self.Water.CollectionTankSupplyARRID] = self.Water.CollectedVdot
        if plantConnection.HowLoadServed == DataPlant.HowMet.ByNominalCapLowOutLimit:
            CompData.getPlantComponent(state, plantConnection.plantLoc).MinOutletTemp = plantConnection.LowOutTempLimit
        if plantConnection.HowLoadServed == DataPlant.HowMet.ByNominalCapHiOutLimit:
            CompData.getPlantComponent(state, plantConnection.plantLoc).MaxOutletTemp = plantConnection.HiOutTempLimit

    def oneTimeInit(inout self, state: EnergyPlusData):
        if self.myOneTimeFlag:
            for connectionIndex in range(self.NumPlantConnections):
                plantConnection = self.Loop[connectionIndex]
                errFlag: Bool = False
                ScanPlantLoopsForObject(state, self.Name, PlantEquipmentType.PlantComponentUserDefined, plantConnection.plantLoc, errFlag, _, _, _, plantConnection.InletNodeNum, None)
                if errFlag:
                    ShowFatalError(state, "InitPlantUserComponent: Program terminated due to previous condition(s).")
                CompData.getPlantComponent(state, plantConnection.plantLoc).FlowPriority = plantConnection.FlowPriority
                CompData.getPlantComponent(state, plantConnection.plantLoc).HowLoadServed = plantConnection.HowLoadServed
            self.myOneTimeFlag = False

struct UserCoilComponentStruct:
    var Name: String
    var ErlSimProgramMngr: Int
    var ErlInitProgramMngr: Int
    var initPluginLocation: Int
    var simPluginLocation: Int
    var initCallbackIndex: Int = -1
    var simCallbackIndex: Int = -1
    var NumAirConnections: Int
    var PlantIsConnected: Bool
    var AirConnections: List[AirConnectionStruct]
    var Loop: PlantConnectionStruct
    var Water: WaterUseTankConnectionStruct
    var Zone: ZoneInternalGainsStruct
    var myOneTimeFlag: Bool

    def __init__(inout self):
        self.ErlSimProgramMngr = 0
        self.ErlInitProgramMngr = 0
        self.initPluginLocation = -1
        self.simPluginLocation = -1
        self.initCallbackIndex = -1
        self.simCallbackIndex = -1
        self.NumAirConnections = 0
        self.PlantIsConnected = False
        self.AirConnections = List[AirConnectionStruct]()
        self.Loop = PlantConnectionStruct()
        self.Water = WaterUseTankConnectionStruct()
        self.Zone = ZoneInternalGainsStruct()
        self.myOneTimeFlag = True

    def initialize(inout self, state: EnergyPlusData):
        const RoutineName: String = "InitCoilUserDefined"
        if self.myOneTimeFlag:
            if self.PlantIsConnected:
                errFlag: Bool = False
                ScanPlantLoopsForObject(state, self.Name, PlantEquipmentType.CoilUserDefined, self.Loop.plantLoc, errFlag)
                if errFlag:
                    ShowFatalError(state, "InitPlantUserComponent: Program terminated due to previous condition(s).")
                CompData.getPlantComponent(state, self.Loop.plantLoc).FlowPriority = self.Loop.FlowPriority
                CompData.getPlantComponent(state, self.Loop.plantLoc).HowLoadServed = self.Loop.HowLoadServed
            self.myOneTimeFlag = False
        for loop in range(self.NumAirConnections):
            airConnection = self.AirConnections[loop]
            airConnection.InletRho = PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress, state.dataLoopNodes.Node[airConnection.InletNodeNum].Temp, state.dataLoopNodes.Node[airConnection.InletNodeNum].HumRat, RoutineName)
            airConnection.InletCp = PsyCpAirFnW(state.dataLoopNodes.Node[airConnection.InletNodeNum].HumRat)
            airConnection.InletTemp = state.dataLoopNodes.Node[airConnection.InletNodeNum].Temp
            airConnection.InletMassFlowRate = state.dataLoopNodes.Node[airConnection.InletNodeNum].MassFlowRate
            airConnection.InletHumRat = state.dataLoopNodes.Node[airConnection.InletNodeNum].HumRat
        if self.PlantIsConnected:
            self.Loop.InletRho = self.Loop.plantLoc.loop.glycol.getDensity(state, state.dataLoopNodes.Node[self.Loop.InletNodeNum].Temp, RoutineName)
            self.Loop.InletCp = self.Loop.plantLoc.loop.glycol.getSpecificHeat(state, state.dataLoopNodes.Node[self.Loop.InletNodeNum].Temp, RoutineName)
            self.Loop.InletTemp = state.dataLoopNodes.Node[self.Loop.InletNodeNum].Temp
            self.Loop.InletMassFlowRate = state.dataLoopNodes.Node[self.Loop.InletNodeNum].MassFlowRate

    def report(inout self, state: EnergyPlusData):
        for loop in range(self.NumAirConnections):
            airConnection = self.AirConnections[loop]
            if airConnection.OutletNodeNum > 0:
                state.dataLoopNodes.Node[airConnection.OutletNodeNum].Temp = airConnection.OutletTemp
                state.dataLoopNodes.Node[airConnection.OutletNodeNum].HumRat = airConnection.OutletHumRat
                state.dataLoopNodes.Node[airConnection.OutletNodeNum].MassFlowRate = airConnection.OutletMassFlowRate
                state.dataLoopNodes.Node[airConnection.OutletNodeNum].Enthalpy = PsyHFnTdbW(airConnection.OutletTemp, airConnection.OutletHumRat)
                state.dataLoopNodes.Node[airConnection.OutletNodeNum].MassFlowRateMinAvail = state.dataLoopNodes.Node[airConnection.InletNodeNum].MassFlowRateMinAvail
                state.dataLoopNodes.Node[airConnection.OutletNodeNum].MassFlowRateMaxAvail = state.dataLoopNodes.Node[airConnection.InletNodeNum].MassFlowRateMaxAvail
        if self.PlantIsConnected:
            SetComponentFlowRate(state, self.Loop.MassFlowRateRequest, self.Loop.InletNodeNum, self.Loop.OutletNodeNum, self.Loop.plantLoc)
            SafeCopyPlantNode(state, self.Loop.InletNodeNum, self.Loop.OutletNodeNum)
            state.dataLoopNodes.Node[self.Loop.OutletNodeNum].Temp = self.Loop.OutletTemp
        if self.Water.SuppliedByWaterSystem:
            state.dataWaterData.WaterStorage[self.Water.SupplyTankID].VdotRequestDemand[self.Water.SupplyTankDemandARRID] = self.Water.SupplyVdotRequest
        if self.Water.CollectsToWaterSystem:
            state.dataWaterData.WaterStorage[self.Water.CollectionTankID].VdotAvailSupply[self.Water.CollectionTankSupplyARRID] = self.Water.CollectedVdot

struct UserAirComponentStruct:
    var Name: String
    var ErlSimProgramMngr: Int
    var ErlInitProgramMngr: Int
    var initPluginLocation: Int
    var simPluginLocation: Int
    var initCallbackIndex: Int = -1
    var simCallbackIndex: Int = -1
    var SourceAir: AirConnectionStruct
    var NumPlantConnections: Int
    var Loop: List[PlantConnectionStruct]
    var Water: WaterUseTankConnectionStruct
    var Zone: ZoneInternalGainsStruct
    var RemainingOutputToHeatingSP: Float64
    var RemainingOutputToCoolingSP: Float64
    var RemainingOutputReqToHumidSP: Float64
    var RemainingOutputReqToDehumidSP: Float64
    var myOneTimeFlag: Bool
    var AirConnection: AirConnectionStruct

    def __init__(inout self):
        self.ErlSimProgramMngr = 0
        self.ErlInitProgramMngr = 0
        self.initPluginLocation = -1
        self.simPluginLocation = -1
        self.initCallbackIndex = -1
        self.simCallbackIndex = -1
        self.SourceAir = AirConnectionStruct()
        self.NumPlantConnections = 0
        self.Loop = List[PlantConnectionStruct]()
        self.Water = WaterUseTankConnectionStruct()
        self.Zone = ZoneInternalGainsStruct()
        self.RemainingOutputToHeatingSP = 0.0
        self.RemainingOutputToCoolingSP = 0.0
        self.RemainingOutputReqToHumidSP = 0.0
        self.RemainingOutputReqToDehumidSP = 0.0
        self.myOneTimeFlag = True
        self.AirConnection = AirConnectionStruct()

struct UserZoneHVACForcedAirComponentStruct:
    var base: UserAirComponentStruct

    def __init__(inout self):
        self.base = UserAirComponentStruct()

    def initialize(inout self, state: EnergyPlusData, ZoneNum: Int):
        const RoutineName: String = "InitZoneAirUserDefined"
        if self.base.myOneTimeFlag:
            if self.base.NumPlantConnections > 0:
                for loop in range(self.base.NumPlantConnections):
                    plantConnection = self.base.Loop[loop]
                    errFlag: Bool = False
                    ScanPlantLoopsForObject(state, self.base.Name, PlantEquipmentType.ZoneHVACAirUserDefined, plantConnection.plantLoc, errFlag, _, _, _, plantConnection.InletNodeNum, None)
                    if errFlag:
                        ShowFatalError(state, "InitPlantUserComponent: Program terminated due to previous condition(s).")
                    CompData.getPlantComponent(state, plantConnection.plantLoc).FlowPriority = plantConnection.FlowPriority
                    CompData.getPlantComponent(state, plantConnection.plantLoc).HowLoadServed = plantConnection.HowLoadServed
            self.base.myOneTimeFlag = False
        self.base.RemainingOutputToHeatingSP = state.dataZoneEnergyDemand.ZoneSysEnergyDemand(ZoneNum).RemainingOutputReqToHeatSP
        self.base.RemainingOutputToCoolingSP = state.dataZoneEnergyDemand.ZoneSysEnergyDemand(ZoneNum).RemainingOutputReqToCoolSP
        self.base.RemainingOutputReqToDehumidSP = state.dataZoneEnergyDemand.ZoneSysMoistureDemand(ZoneNum).RemainingOutputReqToDehumidSP
        self.base.RemainingOutputReqToHumidSP = state.dataZoneEnergyDemand.ZoneSysMoistureDemand(ZoneNum).RemainingOutputReqToHumidSP
        self.base.AirConnection.InletRho = PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress, state.dataLoopNodes.Node[self.base.AirConnection.InletNodeNum].Temp, state.dataLoopNodes.Node[self.base.AirConnection.InletNodeNum].HumRat, RoutineName)
        self.base.AirConnection.InletCp = PsyCpAirFnW(state.dataLoopNodes.Node[self.base.AirConnection.InletNodeNum].HumRat)
        self.base.AirConnection.InletTemp = state.dataLoopNodes.Node[self.base.AirConnection.InletNodeNum].Temp
        self.base.AirConnection.InletHumRat = state.dataLoopNodes.Node[self.base.AirConnection.InletNodeNum].HumRat
        if self.base.SourceAir.InletNodeNum > 0:
            self.base.SourceAir.InletRho = PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress, state.dataLoopNodes.Node[self.base.SourceAir.InletNodeNum].Temp, state.dataLoopNodes.Node[self.base.SourceAir.InletNodeNum].HumRat, RoutineName)
            self.base.SourceAir.InletCp = PsyCpAirFnW(state.dataLoopNodes.Node[self.base.SourceAir.InletNodeNum].HumRat)
            self.base.SourceAir.InletTemp = state.dataLoopNodes.Node[self.base.SourceAir.InletNodeNum].Temp
            self.base.SourceAir.InletHumRat = state.dataLoopNodes.Node[self.base.SourceAir.InletNodeNum].HumRat
        if self.base.NumPlantConnections > 0:
            for loop in range(self.base.NumPlantConnections):
                plantConnection = self.base.Loop[loop]
                plantConnection.InletRho = plantConnection.plantLoc.loop.glycol.getDensity(state, state.dataLoopNodes.Node[plantConnection.InletNodeNum].Temp, RoutineName)
                plantConnection.InletCp = plantConnection.plantLoc.loop.glycol.getSpecificHeat(state, state.dataLoopNodes.Node[plantConnection.InletNodeNum].Temp, RoutineName)
                plantConnection.InletTemp = state.dataLoopNodes.Node[plantConnection.InletNodeNum].Temp
                plantConnection.InletMassFlowRate = state.dataLoopNodes.Node[plantConnection.InletNodeNum].MassFlowRate

    def report(inout self, state: EnergyPlusData):
        state.dataLoopNodes.Node[self.base.AirConnection.InletNodeNum].MassFlowRate = self.base.AirConnection.InletMassFlowRate
        state.dataLoopNodes.Node[self.base.AirConnection.OutletNodeNum].Temp = self.base.AirConnection.OutletTemp
        state.dataLoopNodes.Node[self.base.AirConnection.OutletNodeNum].HumRat = self.base.AirConnection.OutletHumRat
        state.dataLoopNodes.Node[self.base.AirConnection.OutletNodeNum].MassFlowRate = self.base.AirConnection.OutletMassFlowRate
        state.dataLoopNodes.Node[self.base.AirConnection.OutletNodeNum].Enthalpy = PsyHFnTdbW(self.base.AirConnection.OutletTemp, self.base.AirConnection.OutletHumRat)
        if self.base.SourceAir.OutletNodeNum > 0:
            state.dataLoopNodes.Node[self.base.SourceAir.OutletNodeNum].Temp = self.base.SourceAir.OutletTemp
            state.dataLoopNodes.Node[self.base.SourceAir.OutletNodeNum].HumRat = self.base.SourceAir.OutletHumRat
            state.dataLoopNodes.Node[self.base.SourceAir.OutletNodeNum].MassFlowRate = self.base.SourceAir.OutletMassFlowRate
            state.dataLoopNodes.Node[self.base.SourceAir.OutletNodeNum].Enthalpy = PsyHFnTdbW(self.base.SourceAir.OutletTemp, self.base.SourceAir.OutletHumRat)
        if self.base.NumPlantConnections > 0:
            for loop in range(self.base.NumPlantConnections):
                plantConnection = self.base.Loop[loop]
                SetComponentFlowRate(state, plantConnection.MassFlowRateRequest, plantConnection.InletNodeNum, plantConnection.OutletNodeNum, plantConnection.plantLoc)
                SafeCopyPlantNode(state, plantConnection.InletNodeNum, plantConnection.OutletNodeNum)
                state.dataLoopNodes.Node[plantConnection.OutletNodeNum].Temp = plantConnection.OutletTemp
        if self.base.Water.SuppliedByWaterSystem:
            state.dataWaterData.WaterStorage[self.base.Water.SupplyTankID].VdotRequestDemand[self.base.Water.SupplyTankDemandARRID] = self.base.Water.SupplyVdotRequest
        if self.base.Water.CollectsToWaterSystem:
            state.dataWaterData.WaterStorage[self.base.Water.CollectionTankID].VdotAvailSupply[self.base.Water.CollectionTankSupplyARRID] = self.base.Water.CollectedVdot

struct UserAirTerminalComponentStruct:
    var base: UserAirComponentStruct
    var ActualCtrlZoneNum: Int
    var ADUNum: Int

    def __init__(inout self):
        self.base = UserAirComponentStruct()
        self.ActualCtrlZoneNum = 0
        self.ADUNum = 0

    def initialize(inout self, state: EnergyPlusData, ZoneNum: Int):
        const RoutineName: String = "InitAirTerminalUserDefined"
        if self.base.myOneTimeFlag:
            if self.base.NumPlantConnections > 0:
                for loop in range(self.base.NumPlantConnections):
                    plantConnection = self.base.Loop[loop]
                    errFlag: Bool = False
                    ScanPlantLoopsForObject(state, self.base.Name, PlantEquipmentType.AirTerminalUserDefined, plantConnection.plantLoc, errFlag, _, _, _, plantConnection.InletNodeNum, None)
                    if errFlag:
                        ShowFatalError(state, "InitPlantUserComponent: Program terminated due to previous condition(s).")
                    CompData.getPlantComponent(state, plantConnection.plantLoc).FlowPriority = plantConnection.FlowPriority
                    CompData.getPlantComponent(state, plantConnection.plantLoc).HowLoadServed = plantConnection.HowLoadServed
            self.base.myOneTimeFlag = False
        self.base.RemainingOutputToHeatingSP = state.dataZoneEnergyDemand.ZoneSysEnergyDemand(ZoneNum).RemainingOutputReqToHeatSP
        self.base.RemainingOutputToCoolingSP = state.dataZoneEnergyDemand.ZoneSysEnergyDemand(ZoneNum).RemainingOutputReqToCoolSP
        self.base.RemainingOutputReqToDehumidSP = state.dataZoneEnergyDemand.ZoneSysMoistureDemand(ZoneNum).RemainingOutputReqToDehumidSP
        self.base.RemainingOutputReqToHumidSP = state.dataZoneEnergyDemand.ZoneSysMoistureDemand(ZoneNum).RemainingOutputReqToHumidSP
        self.base.AirConnection.InletRho = PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress, state.dataLoopNodes.Node[self.base.AirConnection.InletNodeNum].Temp, state.dataLoopNodes.Node[self.base.AirConnection.InletNodeNum].HumRat, RoutineName)
        self.base.AirConnection.InletCp = PsyCpAirFnW(state.dataLoopNodes.Node[self.base.AirConnection.InletNodeNum].HumRat)
        self.base.AirConnection.InletTemp = state.dataLoopNodes.Node[self.base.AirConnection.InletNodeNum].Temp
        self.base.AirConnection.InletHumRat = state.dataLoopNodes.Node[self.base.AirConnection.InletNodeNum].HumRat
        if self.base.SourceAir.InletNodeNum > 0:
            self.base.SourceAir.InletRho = PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress, state.dataLoopNodes.Node[self.base.SourceAir.InletNodeNum].Temp, state.dataLoopNodes.Node[self.base.SourceAir.InletNodeNum].HumRat, RoutineName)
            self.base.SourceAir.InletCp = PsyCpAirFnW(state.dataLoopNodes.Node[self.base.SourceAir.InletNodeNum].HumRat)
            self.base.SourceAir.InletTemp = state.dataLoopNodes.Node[self.base.SourceAir.InletNodeNum].Temp
            self.base.SourceAir.InletHumRat = state.dataLoopNodes.Node[self.base.SourceAir.InletNodeNum].HumRat
        if self.base.NumPlantConnections > 0:
            for loop in range(self.base.NumPlantConnections):
                plantConnection = self.base.Loop[loop]
                plantConnection.InletRho = plantConnection.plantLoc.loop.glycol.getDensity(state, state.dataLoopNodes.Node[plantConnection.InletNodeNum].Temp, RoutineName)
                plantConnection.InletCp = plantConnection.plantLoc.loop.glycol.getSpecificHeat(state, state.dataLoopNodes.Node[plantConnection.InletNodeNum].Temp, RoutineName)
                plantConnection.InletTemp = state.dataLoopNodes.Node[plantConnection.InletNodeNum].Temp
                plantConnection.InletMassFlowRate = state.dataLoopNodes.Node[plantConnection.InletNodeNum].MassFlowRate

    def report(inout self, state: EnergyPlusData):
        state.dataLoopNodes.Node[self.base.AirConnection.InletNodeNum].MassFlowRate = self.base.AirConnection.InletMassFlowRate
        state.dataLoopNodes.Node[self.base.AirConnection.OutletNodeNum].Temp = self.base.AirConnection.OutletTemp
        state.dataLoopNodes.Node[self.base.AirConnection.OutletNodeNum].HumRat = self.base.AirConnection.OutletHumRat
        state.dataLoopNodes.Node[self.base.AirConnection.OutletNodeNum].MassFlowRate = self.base.AirConnection.OutletMassFlowRate
        state.dataLoopNodes.Node[self.base.AirConnection.OutletNodeNum].Enthalpy = PsyHFnTdbW(self.base.AirConnection.OutletTemp, self.base.AirConnection.OutletHumRat)
        if self.base.SourceAir.OutletNodeNum > 0:
            state.dataLoopNodes.Node[self.base.SourceAir.OutletNodeNum].Temp = self.base.SourceAir.OutletTemp
            state.dataLoopNodes.Node[self.base.SourceAir.OutletNodeNum].HumRat = self.base.SourceAir.OutletHumRat
            state.dataLoopNodes.Node[self.base.SourceAir.OutletNodeNum].MassFlowRate = self.base.SourceAir.OutletMassFlowRate
            state.dataLoopNodes.Node[self.base.SourceAir.OutletNodeNum].Enthalpy = PsyHFnTdbW(self.base.SourceAir.OutletTemp, self.base.SourceAir.OutletHumRat)
        if self.base.NumPlantConnections > 0:
            for loop in range(self.base.NumPlantConnections):
                plantConnection = self.base.Loop[loop]
                SetComponentFlowRate(state, plantConnection.MassFlowRateRequest, plantConnection.InletNodeNum, plantConnection.OutletNodeNum, plantConnection.plantLoc)
                SafeCopyPlantNode(state, plantConnection.InletNodeNum, plantConnection.OutletNodeNum)
                state.dataLoopNodes.Node[plantConnection.OutletNodeNum].Temp = plantConnection.OutletTemp
        if self.base.Water.SuppliedByWaterSystem:
            state.dataWaterData.WaterStorage[self.base.Water.SupplyTankID].VdotRequestDemand[self.base.Water.SupplyTankDemandARRID] = self.base.Water.SupplyVdotRequest
        if self.base.Water.CollectsToWaterSystem:
            state.dataWaterData.WaterStorage[self.base.Water.CollectionTankID].VdotAvailSupply[self.base.Water.CollectionTankSupplyARRID] = self.base.Water.CollectedVdot

# Free functions in UserDefinedComponents namespace

def SimCoilUserDefined(state: EnergyPlusData, EquipName: String, CompIndex: Int, AirLoopNum: Int, HeatingActive: Bool, CoolingActive: Bool):
    var CompNum: Int
    if state.dataUserDefinedComponents.GetPlantCompInput:
        GetUserDefinedPlantComponents(state)
        state.dataUserDefinedComponents.GetPlantCompInput = False
    if CompIndex == 0:
        CompNum = FindItemInList(EquipName, state.dataUserDefinedComponents.UserCoil)
        if CompNum == 0:
            ShowFatalError(state, "SimUserDefinedPlantComponent: User Defined Coil not found")
        CompIndex = CompNum
    else:
        CompNum = CompIndex
        if CompNum < 1 or CompNum > state.dataUserDefinedComponents.NumUserCoils:
            ShowFatalError(state,
                format("SimUserDefinedPlantComponent: Invalid CompIndex passed={}, Number of units ={}, Entered Unit name = {}",
                    CompNum, state.dataUserDefinedComponents.NumUserCoils, EquipName))
        if state.dataUserDefinedComponents.CheckUserCoilName[CompNum - 1]:
            if EquipName != state.dataUserDefinedComponents.UserCoil[CompNum - 1].Name:
                ShowFatalError(state,
                    format("SimUserDefinedPlantComponent: Invalid CompIndex passed={}, Unit name={}, stored unit name for that index={}",
                        CompNum, EquipName, state.dataUserDefinedComponents.UserCoil[CompNum - 1].Name))
            state.dataUserDefinedComponents.CheckUserCoilName[CompNum - 1] = False
    anyEMSRan: Bool
    if state.dataGlobal.BeginEnvrnFlag:
        if state.dataUserDefinedComponents.UserCoil[CompNum - 1].ErlInitProgramMngr > 0:
            EMSManager.ManageEMS(state, EMSManager.EMSCallFrom.UserDefinedComponentModel, anyEMSRan, state.dataUserDefinedComponents.UserCoil[CompNum - 1].ErlInitProgramMngr)
        elif state.dataUserDefinedComponents.UserCoil[CompNum - 1].initPluginLocation > -1:
            state.dataPluginManager.pluginManager.runSingleUserDefinedPlugin(state, state.dataUserDefinedComponents.UserCoil[CompNum - 1].initPluginLocation)
        elif state.dataUserDefinedComponents.UserCoil[CompNum - 1].initCallbackIndex > -1:
            state.dataPluginManager.pluginManager.runSingleUserDefinedCallback(state, state.dataUserDefinedComponents.UserCoil[CompNum - 1].initCallbackIndex)
        if state.dataUserDefinedComponents.UserCoil[CompNum - 1].PlantIsConnected:
            InitComponentNodes(state,
                state.dataUserDefinedComponents.UserCoil[CompNum - 1].Loop.MassFlowRateMin,
                state.dataUserDefinedComponents.UserCoil[CompNum - 1].Loop.MassFlowRateMax,
                state.dataUserDefinedComponents.UserCoil[CompNum - 1].Loop.InletNodeNum,
                state.dataUserDefinedComponents.UserCoil[CompNum - 1].Loop.OutletNodeNum)
            RegisterPlantCompDesignFlow(state,
                state.dataUserDefinedComponents.UserCoil[CompNum - 1].Loop.InletNodeNum,
                state.dataUserDefinedComponents.UserCoil[CompNum - 1].Loop.DesignVolumeFlowRate)
    state.dataUserDefinedComponents.UserCoil[CompNum - 1].initialize(state)
    if state.dataUserDefinedComponents.UserCoil[CompNum - 1].ErlSimProgramMngr > 0:
        EMSManager.ManageEMS(state, EMSManager.EMSCallFrom.UserDefinedComponentModel, anyEMSRan, state.dataUserDefinedComponents.UserCoil[CompNum - 1].ErlSimProgramMngr)
    elif state.dataUserDefinedComponents.UserCoil[CompNum - 1].simPluginLocation > -1:
        state.dataPluginManager.pluginManager.runSingleUserDefinedPlugin(state, state.dataUserDefinedComponents.UserCoil[CompNum - 1].simPluginLocation)
    elif state.dataUserDefinedComponents.UserCoil[CompNum - 1].simCallbackIndex > -1:
        state.dataPluginManager.pluginManager.runSingleUserDefinedCallback(state, state.dataUserDefinedComponents.UserCoil[CompNum - 1].simCallbackIndex)
    state.dataUserDefinedComponents.UserCoil[CompNum - 1].report(state)
    if AirLoopNum != -1:
        primaryAirConnection = state.dataUserDefinedComponents.UserCoil[CompNum - 1].AirConnections[primaryConnIdx]
        HeatingActive = state.dataLoopNodes.Node[primaryAirConnection.InletNodeNum].Temp < state.dataLoopNodes.Node[primaryAirConnection.OutletNodeNum].Temp
        EnthInlet = PsyHFnTdbW(state.dataLoopNodes.Node[primaryAirConnection.InletNodeNum].Temp, state.dataLoopNodes.Node[primaryAirConnection.InletNodeNum].HumRat)
        EnthOutlet = PsyHFnTdbW(state.dataLoopNodes.Node[primaryAirConnection.OutletNodeNum].Temp, state.dataLoopNodes.Node[primaryAirConnection.OutletNodeNum].HumRat)
        CoolingActive = EnthInlet > EnthOutlet

def SimZoneAirUserDefined(state: EnergyPlusData, CompName: String, ZoneNum: Int, SensibleOutputProvided: Float64, LatentOutputProvided: Float64, CompIndex: Int):
    var CompNum: Int
    if state.dataUserDefinedComponents.GetInput:
        GetUserDefinedComponents(state)
        state.dataUserDefinedComponents.GetInput = False
    if CompIndex == 0:
        CompNum = FindItemInList(CompName, state.dataUserDefinedComponents.UserZoneAirHVAC)
        if CompNum == 0:
            ShowFatalError(state, "SimUserDefinedPlantComponent: User Defined Coil not found")
        CompIndex = CompNum
    else:
        CompNum = CompIndex
        if CompNum < 1 or CompNum > state.dataUserDefinedComponents.NumUserZoneAir:
            ShowFatalError(state,
                format("SimUserDefinedPlantComponent: Invalid CompIndex passed={}, Number of units ={}, Entered Unit name = {}",
                    CompNum, state.dataUserDefinedComponents.NumUserZoneAir, CompName))
        if state.dataUserDefinedComponents.CheckUserZoneAirName[CompNum - 1]:
            if CompName != state.dataUserDefinedComponents.UserZoneAirHVAC[CompNum - 1].Name:
                ShowFatalError(state,
                    format("SimUserDefinedPlantComponent: Invalid CompIndex passed={}, Unit name={}, stored unit name for that index={}",
                        CompNum, CompName, state.dataUserDefinedComponents.UserZoneAirHVAC[CompNum - 1].Name))
            state.dataUserDefinedComponents.CheckUserZoneAirName[CompNum - 1] = False
    anyEMSRan: Bool
    if state.dataGlobal.BeginEnvrnFlag:
        state.dataUserDefinedComponents.UserZoneAirHVAC[CompNum - 1].initialize(state, ZoneNum)
        if state.dataUserDefinedComponents.UserZoneAirHVAC[CompNum - 1].ErlInitProgramMngr > 0:
            EMSManager.ManageEMS(state, EMSManager.EMSCallFrom.UserDefinedComponentModel, anyEMSRan, state.dataUserDefinedComponents.UserZoneAirHVAC[CompNum - 1].ErlInitProgramMngr)
        elif state.dataUserDefinedComponents.UserZoneAirHVAC[CompNum - 1].initPluginLocation > -1:
            state.dataPluginManager.pluginManager.runSingleUserDefinedPlugin(state, state.dataUserDefinedComponents.UserZoneAirHVAC[CompNum - 1].initPluginLocation)
        elif state.dataUserDefinedComponents.UserZoneAirHVAC[CompNum - 1].initCallbackIndex > -1:
            state.dataPluginManager.pluginManager.runSingleUserDefinedCallback(state, state.dataUserDefinedComponents.UserZoneAirHVAC[CompNum - 1].initCallbackIndex)
        if state.dataUserDefinedComponents.UserZoneAirHVAC[CompNum - 1].NumPlantConnections > 0:
            for loop in range(state.dataUserDefinedComponents.UserZoneAirHVAC[CompNum - 1].NumPlantConnections):
                plantConnection = state.dataUserDefinedComponents.UserZoneAirHVAC[CompNum - 1].Loop[loop]
                InitComponentNodes(state, plantConnection.MassFlowRateMin, plantConnection.MassFlowRateMax, plantConnection.InletNodeNum, plantConnection.OutletNodeNum)
                RegisterPlantCompDesignFlow(state, plantConnection.InletNodeNum, plantConnection.DesignVolumeFlowRate)
    state.dataUserDefinedComponents.UserZoneAirHVAC[CompNum - 1].initialize(state, ZoneNum)
    if state.dataUserDefinedComponents.UserZoneAirHVAC[CompNum - 1].ErlSimProgramMngr > 0:
        EMSManager.ManageEMS(state, EMSManager.EMSCallFrom.UserDefinedComponentModel, anyEMSRan, state.dataUserDefinedComponents.UserZoneAirHVAC[CompNum - 1].ErlSimProgramMngr)
    elif state.dataUserDefinedComponents.UserZoneAirHVAC[CompNum - 1].simPluginLocation > -1:
        state.dataPluginManager.pluginManager.runSingleUserDefinedPlugin(state, state.dataUserDefinedComponents.UserZoneAirHVAC[CompNum - 1].simPluginLocation)
    elif state.dataUserDefinedComponents.UserZoneAirHVAC[CompNum - 1].simCallbackIndex > -1:
        state.dataPluginManager.pluginManager.runSingleUserDefinedCallback(state, state.dataUserDefinedComponents.UserZoneAirHVAC[CompNum - 1].simCallbackIndex)
    state.dataUserDefinedComponents.UserZoneAirHVAC[CompNum - 1].report(state)
    AirMassFlow = min(state.dataLoopNodes.Node[state.dataUserDefinedComponents.UserZoneAirHVAC[CompNum - 1].AirConnection.InletNodeNum].MassFlowRate,
        state.dataLoopNodes.Node[state.dataUserDefinedComponents.UserZoneAirHVAC[CompNum - 1].AirConnection.OutletNodeNum].MassFlowRate)
    MinHumRat = min(state.dataLoopNodes.Node[state.dataUserDefinedComponents.UserZoneAirHVAC[CompNum - 1].AirConnection.InletNodeNum].HumRat,
        state.dataLoopNodes.Node[state.dataUserDefinedComponents.UserZoneAirHVAC[CompNum - 1].AirConnection.OutletNodeNum].HumRat)
    SensibleOutputProvided = AirMassFlow * (PsyHFnTdbW(state.dataLoopNodes.Node[state.dataUserDefinedComponents.UserZoneAirHVAC[CompNum - 1].AirConnection.OutletNodeNum].Temp, MinHumRat) -
        PsyHFnTdbW(state.dataLoopNodes.Node[state.dataUserDefinedComponents.UserZoneAirHVAC[CompNum - 1].AirConnection.InletNodeNum].Temp, MinHumRat))
    SpecHumOut = state.dataLoopNodes.Node[state.dataUserDefinedComponents.UserZoneAirHVAC[CompNum - 1].AirConnection.OutletNodeNum].HumRat
    SpecHumIn = state.dataLoopNodes.Node[state.dataUserDefinedComponents.UserZoneAirHVAC[CompNum - 1].AirConnection.InletNodeNum].HumRat
    LatentOutputProvided = AirMassFlow * (SpecHumOut - SpecHumIn)

def SimAirTerminalUserDefined(state: EnergyPlusData, CompName: String, FirstHVACIteration: Bool, ZoneNum: Int, ZoneNodeNum: Int, CompIndex: Int):
    var CompNum: Int
    if state.dataUserDefinedComponents.GetAirTerminalInput:
        GetUserDefinedAirComponent(state)
        state.dataUserDefinedComponents.GetAirTerminalInput = False
    if CompIndex == 0:
        CompNum = FindItemInList(CompName, state.dataUserDefinedComponents.UserAirTerminal)
        if CompNum == 0:
            ShowFatalError(state, "SimUserDefinedPlantComponent: User Defined Coil not found")
        CompIndex = CompNum
    else:
        CompNum = CompIndex
        if CompNum < 1 or CompNum > state.dataUserDefinedComponents.NumUserAirTerminals:
            ShowFatalError(state,
                format("SimUserDefinedPlantComponent: Invalid CompIndex passed={}, Number of units ={}, Entered Unit name = {}",
                    CompNum, state.dataUserDefinedComponents.NumUserAirTerminals, CompName))
        if state.dataUserDefinedComponents.CheckUserAirTerminal[CompNum - 1]:
            if CompName != state.dataUserDefinedComponents.UserAirTerminal[CompNum - 1].Name:
                ShowFatalError(state,
                    format("SimUserDefinedPlantComponent: Invalid CompIndex passed={}, Unit name={}, stored unit name for that index={}",
                        CompNum, CompName, state.dataUserDefinedComponents.UserAirTerminal[CompNum - 1].Name))
            state.dataUserDefinedComponents.CheckUserAirTerminal[CompNum - 1] = False
    anyEMSRan: Bool
    if state.dataGlobal.BeginEnvrnFlag:
        state.dataUserDefinedComponents.UserAirTerminal[CompNum - 1].initialize(state, ZoneNum)
        if state.dataUserDefinedComponents.UserAirTerminal[CompNum - 1].ErlInitProgramMngr > 0:
            EMSManager.ManageEMS(state, EMSManager.EMSCallFrom.UserDefinedComponentModel, anyEMSRan, state.dataUserDefinedComponents.UserAirTerminal[CompNum - 1].ErlInitProgramMngr)
        elif state.dataUserDefinedComponents.UserAirTerminal[CompNum - 1].initPluginLocation > -1:
            state.dataPluginManager.pluginManager.runSingleUserDefinedPlugin(state, state.dataUserDefinedComponents.UserAirTerminal[CompNum - 1].initPluginLocation)
        elif state.dataUserDefinedComponents.UserAirTerminal[CompNum - 1].initCallbackIndex > -1:
            state.dataPluginManager.pluginManager.runSingleUserDefinedCallback(state, state.dataUserDefinedComponents.UserAirTerminal[CompNum - 1].initCallbackIndex)
        if state.dataUserDefinedComponents.UserAirTerminal[CompNum - 1].NumPlantConnections > 0:
            for loop in range(state.dataUserDefinedComponents.UserAirTerminal[CompNum - 1].NumPlantConnections):
                plantConnection = state.dataUserDefinedComponents.UserAirTerminal[CompNum - 1].Loop[loop]
                InitComponentNodes(state, plantConnection.MassFlowRateMin, plantConnection.MassFlowRateMax, plantConnection.InletNodeNum, plantConnection.OutletNodeNum)
                RegisterPlantCompDesignFlow(state, plantConnection.InletNodeNum, plantConnection.DesignVolumeFlowRate)
    state.dataUserDefinedComponents.UserAirTerminal[CompNum - 1].initialize(state, ZoneNum)
    if state.dataUserDefinedComponents.UserAirTerminal[CompNum - 1].ErlSimProgramMngr > 0:
        EMSManager.ManageEMS(state, EMSManager.EMSCallFrom.UserDefinedComponentModel, anyEMSRan, state.dataUserDefinedComponents.UserAirTerminal[CompNum - 1].ErlSimProgramMngr)
    elif state.dataUserDefinedComponents.UserAirTerminal[CompNum - 1].simPluginLocation > -1:
        state.dataPluginManager.pluginManager.runSingleUserDefinedPlugin(state, state.dataUserDefinedComponents.UserAirTerminal[CompNum - 1].simPluginLocation)
    elif state.dataUserDefinedComponents.UserAirTerminal[CompNum - 1].simCallbackIndex > -1:
        state.dataPluginManager.pluginManager.runSingleUserDefinedCallback(state, state.dataUserDefinedComponents.UserAirTerminal[CompNum - 1].simCallbackIndex)
    state.dataUserDefinedComponents.UserAirTerminal[CompNum - 1].report(state)

def GetUserDefinedPlantComponents(state: EnergyPlusData):
    var ErrorsFound: Bool = False
    var NumAlphas: Int
    var NumNums: Int
    var IOStat: Int
    var TotalArgs: Int
    cAlphaFieldNames: List[String]
    lAlphaFieldBlanks: List[Bool]
    cAlphaArgs: List[String]
    rNumericArgs: List[Float64]
    var cCurrentModuleObject: String
    cCurrentModuleObject = "PlantComponent:UserDefined"
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, cCurrentModuleObject, TotalArgs, NumAlphas, NumNums)
    cAlphaFieldNames = List[String](size=NumAlphas)
    cAlphaArgs = List[String](size=NumAlphas)
    lAlphaFieldBlanks = List[Bool](size=NumAlphas, value=False)
    rNumericArgs = List[Float64](size=NumNums, value=0.0)
    state.dataUserDefinedComponents.NumUserPlantComps = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, cCurrentModuleObject)
    if state.dataUserDefinedComponents.NumUserPlantComps > 0:
        state.dataUserDefinedComponents.UserPlantComp = List[UserPlantComponentStruct](size=state.dataUserDefinedComponents.NumUserPlantComps)
        state.dataUserDefinedComponents.CheckUserPlantCompName = List[Bool](size=state.dataUserDefinedComponents.NumUserPlantComps, value=True)
        for CompLoop in range(1, state.dataUserDefinedComponents.NumUserPlantComps + 1):
            state.dataInputProcessing.inputProcessor.getObjectItem(state,
                cCurrentModuleObject, CompLoop, cAlphaArgs, NumAlphas, rNumericArgs, NumNums, IOStat, _, lAlphaFieldBlanks, cAlphaFieldNames, _)
            # Use 0-based index for rows
            idx = CompLoop - 1
            state.dataUserDefinedComponents.UserPlantComp[idx].Name = cAlphaArgs[0]
            if not lAlphaFieldBlanks[1]:
                StackMngrNum = FindItemInList(cAlphaArgs[1], state.dataRuntimeLang.EMSProgramCallManager)
                if StackMngrNum > 0:
                    state.dataUserDefinedComponents.UserPlantComp[idx].ErlSimProgramMngr = StackMngrNum
                else:
                    state.dataUserDefinedComponents.UserPlantComp[idx].simPluginLocation = state.dataPluginManager.pluginManager.getLocationOfUserDefinedPlugin(state, cAlphaArgs[1])
                    if state.dataUserDefinedComponents.UserPlantComp[idx].simPluginLocation == -1:
                        state.dataUserDefinedComponents.UserPlantComp[idx].simCallbackIndex = state.dataPluginManager.pluginManager.getUserDefinedCallbackIndex(state, cAlphaArgs[1])
                        if state.dataUserDefinedComponents.UserPlantComp[idx].simCallbackIndex == -1:
                            ShowSevereError(state, format("Invalid {}={}", cAlphaFieldNames[1], cAlphaArgs[1]))
                            ShowContinueError(state, format("Entered in {}={}", cCurrentModuleObject, cAlphaArgs[0]))
                            ShowContinueError(state, "Program Manager Name not found as an EMS Program Manager, API callback or a Python Plugin Instance object.")
                            ErrorsFound = True
            NumPlantConnections = floor(rNumericArgs[0])
            userPlantComp = state.dataUserDefinedComponents.UserPlantComp[idx]
            if (NumPlantConnections >= 1) and (NumPlantConnections <= 4):
                userPlantComp.Loop = List[PlantConnectionStruct](size=NumPlantConnections)
                userPlantComp.NumPlantConnections = NumPlantConnections
                for connectionIndex in range(NumPlantConnections):
                    connectionNum = connectionIndex + 1
                    plantConnection = userPlantComp.Loop[connectionIndex]
                    LoopStr = str(connectionNum)
                    aArgCount = connectionIndex * 6 + 3
                    plantConnection.InletNodeNum = GetOnlySingleNode(state, cAlphaArgs[aArgCount], ErrorsFound, ConnectionObjectType.PlantComponentUserDefined, cAlphaArgs[0], FluidType.Water, ConnectionType.Inlet, static_cast[CompFluidStream](connectionNum), ObjectIsNotParent)
                    plantConnection.OutletNodeNum = GetOnlySingleNode(state, cAlphaArgs[aArgCount+1], ErrorsFound, ConnectionObjectType.PlantComponentUserDefined, cAlphaArgs[0], FluidType.Water, ConnectionType.Outlet, static_cast[CompFluidStream](connectionNum), ObjectIsNotParent)
                    TestCompSet(state, cCurrentModuleObject, cAlphaArgs[0], cAlphaArgs[aArgCount], cAlphaArgs[aArgCount+1], "Plant Nodes " + LoopStr)
                    plantConnection.HowLoadServed = getEnumValue(HowMetTypeNamesUC, makeUPPER(cAlphaArgs[aArgCount+2]))
                    if plantConnection.HowLoadServed == DataPlant.HowMet.ByNominalCapLowOutLimit:
                        SetupEMSActuator(state, "Plant Connection " + LoopStr, userPlantComp.Name, "Low Outlet Temperature Limit", "[C]", state.dataUserDefinedComponents.lDummy_EMSActuatedPlantComp, plantConnection.LowOutTempLimit)
                    elif plantConnection.HowLoadServed == DataPlant.HowMet.ByNominalCapHiOutLimit:
                        SetupEMSActuator(state, "Plant Connection " + LoopStr, userPlantComp.Name, "High Outlet Temperature Limit", "[C]", state.dataUserDefinedComponents.lDummy_EMSActuatedPlantComp, plantConnection.HiOutTempLimit)
                    plantConnection.FlowPriority = getEnumValue(LoopFlowStatusTypeNamesUC, makeUPPER(cAlphaArgs[aArgCount+3]))
                    if not lAlphaFieldBlanks[aArgCount+4]:
                        StackMngrNum = FindItemInList(cAlphaArgs[aArgCount+4], state.dataRuntimeLang.EMSProgramCallManager)
                        if StackMngrNum > 0:
                            plantConnection.ErlInitProgramMngr = StackMngrNum
                        else:
                            plantConnection.initPluginLocation = state.dataPluginManager.pluginManager.getLocationOfUserDefinedPlugin(state, cAlphaArgs[aArgCount+4])
                            if plantConnection.initPluginLocation == -1:
                                plantConnection.initCallbackIndex = state.dataPluginManager.pluginManager.getUserDefinedCallbackIndex(state, cAlphaArgs[aArgCount+4])
                                if plantConnection.initCallbackIndex == -1:
                                    ShowSevereError(state, format("Invalid {}={}", cAlphaFieldNames[aArgCount+4], cAlphaArgs[aArgCount+4]))
                                    ShowContinueError(state, format("Entered in {}={}", cCurrentModuleObject, cAlphaArgs[0]))
                                    ShowContinueError(state, "Program Manager Name not found as an EMS Program Manager, API callback, or a Python Plugin Instance object.")
                                    ErrorsFound = True
                    if not lAlphaFieldBlanks[aArgCount+5]:
                        StackMngrNum = FindItemInList(cAlphaArgs[aArgCount+5], state.dataRuntimeLang.EMSProgramCallManager)
                        if StackMngrNum > 0:
                            plantConnection.ErlSimProgramMngr = StackMngrNum
                        else:
                            plantConnection.simPluginLocation = state.dataPluginManager.pluginManager.getLocationOfUserDefinedPlugin(state, cAlphaArgs[aArgCount+5])
                            if plantConnection.simPluginLocation == -1:
                                plantConnection.simCallbackIndex = state.dataPluginManager.pluginManager.getUserDefinedCallbackIndex(state, cAlphaArgs[aArgCount+5])
                                if plantConnection.simCallbackIndex == -1:
                                    ShowSevereError(state, format("Invalid {}={}", cAlphaFieldNames[aArgCount+4], cAlphaArgs[aArgCount+4]))
                                    ShowContinueError(state, format("Entered in {}={}", cCurrentModuleObject, cAlphaArgs[0]))
                                    ShowContinueError(state, "Program Manager Name not found as EMS Program, API callback, or Python Plugin.")
                                    ErrorsFound = True
                    SetupEMSInternalVariable(state, "Inlet Temperature for Plant Connection " + LoopStr, userPlantComp.Name, "[C]", plantConnection.InletTemp)
                    SetupEMSInternalVariable(state, "Inlet Mass Flow Rate for Plant Connection " + LoopStr, userPlantComp.Name, "[kg/s]", plantConnection.InletMassFlowRate)
                    if plantConnection.HowLoadServed != DataPlant.HowMet.NoneDemand:
                        SetupEMSInternalVariable(state, "Load Request for Plant Connection " + LoopStr, userPlantComp.Name, "[W]", plantConnection.MyLoad)
                    SetupEMSInternalVariable(state, "Inlet Density for Plant Connection " + LoopStr, userPlantComp.Name, "[kg/m3]", plantConnection.InletRho)
                    SetupEMSInternalVariable(state, "Inlet Specific Heat for Plant Connection " + LoopStr, userPlantComp.Name, "[J/kg-C]", plantConnection.InletCp)
                    SetupEMSActuator(state, "Plant Connection " + LoopStr, userPlantComp.Name, "Outlet Temperature", "[C]", state.dataUserDefinedComponents.lDummy_EMSActuatedPlantComp, plantConnection.OutletTemp)
                    SetupEMSActuator(state, "Plant Connection " + LoopStr, userPlantComp.Name, "Mass Flow Rate", "[kg/s]", state.dataUserDefinedComponents.lDummy_EMSActuatedPlantComp, plantConnection.MassFlowRateRequest)
                    SetupEMSActuator(state, "Plant Connection " + LoopStr, userPlantComp.Name, "Minimum Mass Flow Rate", "[kg/s]", state.dataUserDefinedComponents.lDummy_EMSActuatedPlantComp, plantConnection.MassFlowRateMin)
                    SetupEMSActuator(state, "Plant Connection " + LoopStr, userPlantComp.Name, "Maximum Mass Flow Rate", "[kg/s]", state.dataUserDefinedComponents.lDummy_EMSActuatedPlantComp, plantConnection.MassFlowRateMax)
                    SetupEMSActuator(state, "Plant Connection " + LoopStr, userPlantComp.Name, "Design Volume Flow Rate", "[m3/s]", state.dataUserDefinedComponents.lDummy_EMSActuatedPlantComp, plantConnection.DesignVolumeFlowRate)
                    SetupEMSActuator(state, "Plant Connection " + LoopStr, userPlantComp.Name, "Minimum Loading Capacity", "[W]", state.dataUserDefinedComponents.lDummy_EMSActuatedPlantComp, plantConnection.MinLoad)
                    SetupEMSActuator(state, "Plant Connection " + LoopStr, userPlantComp.Name, "Maximum Loading Capacity", "[W]", state.dataUserDefinedComponents.lDummy_EMSActuatedPlantComp, plantConnection.MaxLoad)
                    SetupEMSActuator(state, "Plant Connection " + LoopStr, userPlantComp.Name, "Optimal Loading Capacity", "[W]", state.dataUserDefinedComponents.lDummy_EMSActuatedPlantComp, plantConnection.OptLoad)
            if not lAlphaFieldBlanks[27]:
                state.dataUserDefinedComponents.UserPlantComp[idx].Air.InletNodeNum = GetOnlySingleNode(state, cAlphaArgs[27], ErrorsFound, ConnectionObjectType.PlantComponentUserDefined, state.dataUserDefinedComponents.UserPlantComp[idx].Name, FluidType.Air, ConnectionType.OutsideAirReference, CompFluidStream.Primary, ObjectIsNotParent)
                SetupEMSInternalVariable(state, "Inlet Temperature for Air Connection", state.dataUserDefinedComponents.UserPlantComp[idx].Name, "[C]", state.dataUserDefinedComponents.UserPlantComp[idx].Air.InletTemp)
                SetupEMSInternalVariable(state, "Inlet Mass Flow Rate for Air Connection", state.dataUserDefinedComponents.UserPlantComp[idx].Name, "[kg/s]", state.dataUserDefinedComponents.UserPlantComp[idx].Air.InletMassFlowRate)
                SetupEMSInternalVariable(state, "Inlet Humidity Ratio for Air Connection", state.dataUserDefinedComponents.UserPlantComp[idx].Name, "[kgWater/kgDryAir]", state.dataUserDefinedComponents.UserPlantComp[idx].Air.InletHumRat)
                SetupEMSInternalVariable(state, "Inlet Density for Air Connection", state.dataUserDefinedComponents.UserPlantComp[idx].Name, "[kg/m3]", state.dataUserDefinedComponents.UserPlantComp[idx].Air.InletRho)
                SetupEMSInternalVariable(state, "Inlet Specific Heat for Air Connection", state.dataUserDefinedComponents.UserPlantComp[idx].Name, "[J/kg-C]", state.dataUserDefinedComponents.UserPlantComp[idx].Air.InletCp)
            if not lAlphaFieldBlanks[28]:
                state.dataUserDefinedComponents.UserPlantComp[idx].Air.OutletNodeNum = GetOnlySingleNode(state, cAlphaArgs[28], ErrorsFound, ConnectionObjectType.PlantComponentUserDefined, state.dataUserDefinedComponents.UserPlantComp[idx].Name, FluidType.Air, ConnectionType.ReliefAir, CompFluidStream.Primary, ObjectIsNotParent)
                SetupEMSActuator(state, "Air Connection", state.dataUserDefinedComponents.UserPlantComp[idx].Name, "Outlet Temperature", "[C]", state.dataUserDefinedComponents.lDummy_EMSActuatedPlantComp, state.dataUserDefinedComponents.UserPlantComp[idx].Air.OutletTemp)
                SetupEMSActuator(state, "Air Connection", state.dataUserDefinedComponents.UserPlantComp[idx].Name, "Outlet Humidity Ratio", "[kgWater/kgDryAir]", state.dataUserDefinedComponents.lDummy_EMSActuatedPlantComp, state.dataUserDefinedComponents.UserPlantComp[idx].Air.OutletHumRat)
                SetupEMSActuator(state, "Air Connection", state.dataUserDefinedComponents.UserPlantComp[idx].Name, "Mass Flow Rate", "[kg/s]", state.dataUserDefinedComponents.lDummy_EMSActuatedPlantComp, state.dataUserDefinedComponents.UserPlantComp[idx].Air.OutletMassFlowRate)
            if not lAlphaFieldBlanks[29]:
                SetupTankDemandComponent(state, cAlphaArgs[0], cCurrentModuleObject, cAlphaArgs[29], ErrorsFound, state.dataUserDefinedComponents.UserPlantComp[idx].Water.SupplyTankID, state.dataUserDefinedComponents.UserPlantComp[idx].Water.SupplyTankDemandARRID)
                state.dataUserDefinedComponents.UserPlantComp[idx].Water.SuppliedByWaterSystem = True
                SetupEMSActuator(state, "Water System", state.dataUserDefinedComponents.UserPlantComp[idx].Name, "Supplied Volume Flow Rate", "[m3/s]", state.dataUserDefinedComponents.lDummy_EMSActuatedPlantComp, state.dataUserDefinedComponents.UserPlantComp[idx].Water.SupplyVdotRequest)
            if not lAlphaFieldBlanks[30]:
                SetupTankSupplyComponent(state, cAlphaArgs[0], cCurrentModuleObject, cAlphaArgs[30], ErrorsFound, state.dataUserDefinedComponents.UserPlantComp[idx].Water.CollectionTankID, state.dataUserDefinedComponents.UserPlantComp[idx].Water.CollectionTankSupplyARRID)
                state.dataUserDefinedComponents.UserPlantComp[idx].Water.CollectsToWaterSystem = True
                SetupEMSActuator(state, "Water System", state.dataUserDefinedComponents.UserPlantComp[idx].Name, "Collected Volume Flow Rate", "[m3/s]", state.dataUserDefinedComponents.lDummy_EMSActuatedPlantComp, state.dataUser