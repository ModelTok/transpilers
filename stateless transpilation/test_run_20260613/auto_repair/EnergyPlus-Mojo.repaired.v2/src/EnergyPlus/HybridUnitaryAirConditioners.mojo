from .Data.EnergyPlusData import EnergyPlusData
from Data.BaseData import BaseGlobalStruct
from DataGlobals import *
from DataZoneEquipment import *
from EnergyPlus import *
from HybridEvapCoolingModel import CSetting, Model, ObjectiveFunctionType, objectiveFunctionNamesUC
from Psychrometrics import PsyRhFnTdbWPb
from BranchNodeConnections import *
from DataEnvironment import *
from DataHVACGlobals import *
from DataLoopNode import *
from DataSizing import calcDesignSpecificationOutdoorAir
from DataZoneEnergyDemands import *
from .InputProcessing.InputProcessor import *
from NodeInputManager import GetOnlySingleNode, SetUpCompSets, TestCompSet
from OutputProcessor import SetupOutputVariable, TimeStepType, StoreType, Group, EndUseCat
from Psychrometrics import *
from ScheduleManager import *
from UtilityRoutines import ReduceItem, FindItemInList, makeUPPER, SameString
from .Autosizing.Base import BaseSizer
from Constant import Units, eResource, eFuel, eFuel2eResource, eFuelNamesUC
from Data import *

# Constants
t alias TEMP_CURVE: Int = 0
t alias W_CURVE: Int = 1
t alias POWER_CURVE: Int = 2

# Data structure
struct HybridUnitaryAirConditionersData(BaseGlobalStruct):
    var NumZoneHybridEvap: Int = 0
    var GetInputZoneHybridEvap: Bool = True
    var ZoneEquipmentListChecked: Bool = False
    var HybridCoolOneTimeFlag: Bool = True
    var CheckZoneHybridEvapName: List[Bool] = List[Bool]()
    var ZoneHybridUnitaryAirConditioner: List[Model] = List[Model]()
    var MySizeFlag: List[Bool] = List[Bool]()
    var MyEnvrnFlag: List[Bool] = List[Bool]()
    var MyFanFlag: List[Bool] = List[Bool]()
    var MyZoneEqFlag: List[Bool] = List[Bool]()

    def init_constant_state(inout state: EnergyPlusData):

    def init_state(inout state: EnergyPlusData):

    def clear_state(inout self):
        self.NumZoneHybridEvap = 0
        self.GetInputZoneHybridEvap = True
        self.ZoneEquipmentListChecked = False
        self.HybridCoolOneTimeFlag = True
        self.CheckZoneHybridEvapName = List[Bool]()
        self.ZoneHybridUnitaryAirConditioner = List[Model]()
        self.MySizeFlag = List[Bool]()
        self.MyEnvrnFlag = List[Bool]()
        self.MyFanFlag = List[Bool]()
        self.MyZoneEqFlag = List[Bool]()

# Functions
def SimZoneHybridUnitaryAirConditioners(
    inout state: EnergyPlusData,
    CompName: String,
    ZoneNum: Int,
    inout SensibleOutputProvided: Float64,
    inout LatentOutputProvided: Float64,
    inout CompIndex: Int
):
    var CompNum: Int
    if state.dataHybridUnitaryAC.GetInputZoneHybridEvap:
        var errorsfound: Bool = False
        GetInputZoneHybridUnitaryAirConditioners(state, errorsfound)
        state.dataHybridUnitaryAC.GetInputZoneHybridEvap = False
    if CompIndex == 0:
        CompNum = FindItemInList(CompName, state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner)
        if CompNum == 0:
            ShowFatalError(state, "SimZoneHybridUnitaryAirConditioners: ZoneHVAC:HybridUnitaryHVAC not found.")
        CompIndex = CompNum
    else:
        CompNum = CompIndex
        if CompNum < 1 or CompNum > state.dataHybridUnitaryAC.NumZoneHybridEvap:
            ShowFatalError(
                state,
                "SimZoneHybridUnitaryAirConditioners: Invalid CompIndex passed={}, Number of units ={}, Entered Unit name = {}".format(
                    CompNum, state.dataHybridUnitaryAC.NumZoneHybridEvap, CompName
                )
            )
        if state.dataHybridUnitaryAC.CheckZoneHybridEvapName[CompNum - 1]:
            if CompName != state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[CompNum - 1].Name:
                ShowFatalError(
                    state,
                    "SimZoneHybridUnitaryAirConditioners: Invalid CompIndex passed={}, Unit name={}, stored unit name for that index={}".format(
                        CompNum, CompName, state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[CompNum - 1].Name
                    )
                )
            state.dataHybridUnitaryAC.CheckZoneHybridEvapName[CompNum - 1] = False
    try:
        InitZoneHybridUnitaryAirConditioners(state, CompNum, ZoneNum)
    except Int as e:
        ShowFatalError(state,
            "An exception occurred in InitZoneHybridUnitaryAirConditioners{}, Unit name={}, stored unit name for that index={}. Please check idf.".format(
                CompNum, CompName, state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[CompNum - 1].Name
            )
        )
        return
    try:
        CalcZoneHybridUnitaryAirConditioners(state, CompNum, ZoneNum, SensibleOutputProvided, LatentOutputProvided)
    except Int as e:
        ShowFatalError(state,
            "An exception occurred in CalcZoneHybridUnitaryAirConditioners{}, Unit name={}, stored unit name for that index={}. Please check idf.".format(
                CompNum, CompName, state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[CompNum - 1].Name
            )
        )
        return
    try:
        ReportZoneHybridUnitaryAirConditioners(state, CompNum)
    except Int as e:
        ShowFatalError(state,
            "An exception occurred in ReportZoneHybridUnitaryAirConditioners{}, Unit name={}, stored unit name for that index={}. Please check idf.".format(
                CompNum, CompName, state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[CompNum - 1].Name
            )
        )
        return

def InitZoneHybridUnitaryAirConditioners(
    inout state: EnergyPlusData,
    UnitNum: Int,
    ZoneNum: Int
):
    from Psychrometrics import *
    from DataZoneEquipment import CheckZoneEquipmentList

    var InletNode: Int
    if state.dataHybridUnitaryAC.HybridCoolOneTimeFlag:
        state.dataHybridUnitaryAC.MySizeFlag = [True for _ in range(state.dataHybridUnitaryAC.NumZoneHybridEvap)]
        state.dataHybridUnitaryAC.MyEnvrnFlag = [True for _ in range(state.dataHybridUnitaryAC.NumZoneHybridEvap)]
        state.dataHybridUnitaryAC.MyFanFlag = [True for _ in range(state.dataHybridUnitaryAC.NumZoneHybridEvap)]
        state.dataHybridUnitaryAC.MyZoneEqFlag = [True for _ in range(state.dataHybridUnitaryAC.NumZoneHybridEvap)]
        state.dataHybridUnitaryAC.HybridCoolOneTimeFlag = False
    if not state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].Initialized:
        state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].Initialize(ZoneNum)
    state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].RequestedLoadToHeatingSetpoint = 0
    state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].RequestedLoadToCoolingSetpoint = 0
    state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].RequestedHumidificationMass = 0
    state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].RequestedHumidificationLoad = 0
    state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].RequestedHumidificationEnergy = 0
    state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].RequestedDeHumidificationMass = 0
    state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].RequestedDeHumidificationLoad = 0
    state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].RequestedDeHumidificationEnergy = 0
    state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].UnitTotalCoolingRate = 0.0
    state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].UnitTotalCoolingEnergy = 0.0
    state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].UnitSensibleCoolingRate = 0.0
    state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].UnitSensibleCoolingEnergy = 0.0
    state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].UnitLatentCoolingRate = 0.0
    state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].UnitLatentCoolingEnergy = 0.0
    state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].availStatus = Avail.Status.NoAction
    if allocated(state.dataAvail.ZoneComp):
        var availMgr = state.dataAvail.ZoneComp[DataZoneEquipment.ZoneEquipType.HybridEvaporativeCooler].ZoneCompAvailMgrs[UnitNum - 1]
        if state.dataHybridUnitaryAC.MyZoneEqFlag[UnitNum - 1]:
            availMgr.AvailManagerListName = state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].AvailManagerListName
            availMgr.ZoneNum = ZoneNum
            state.dataHybridUnitaryAC.MyZoneEqFlag[UnitNum - 1] = False
        state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].availStatus = availMgr.availStatus
    if not state.dataHybridUnitaryAC.ZoneEquipmentListChecked and state.dataZoneEquip.ZoneEquipInputsFilled:
        state.dataHybridUnitaryAC.ZoneEquipmentListChecked = True
        for Loop in range(state.dataHybridUnitaryAC.NumZoneHybridEvap):
            if CheckZoneEquipmentList(state, "ZoneHVAC:HybridUnitaryHVAC", state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[Loop].Name):
                state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[Loop].ZoneNodeNum = state.dataZoneEquip.ZoneEquipConfig[ZoneNum - 1].ZoneNode
            else:
                ShowSevereError(
                    state,
                    "InitZoneHybridUnitaryAirConditioners: ZoneHVAC:HybridUnitaryHVAC = {}, is not on any ZoneHVAC:EquipmentList. It will not be simulated.".format(
                        state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[Loop].Name
                    )
                )
    state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].InitializeModelParams()
    InletNode = state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].InletNode
    state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].InletMassFlowRate = state.dataLoopNodes.Node[InletNode - 1].MassFlowRate
    if state.dataEnvrn.StdRhoAir > 1:
        state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].InletVolumetricFlowRate = (
            state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].InletMassFlowRate / state.dataEnvrn.StdRhoAir
        )
    else:
        state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].InletVolumetricFlowRate = (
            state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].InletMassFlowRate / 1.225
        )
    state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].InletTemp = state.dataLoopNodes.Node[InletNode - 1].Temp
    state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].InletHumRat = state.dataLoopNodes.Node[InletNode - 1].HumRat
    state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].InletEnthalpy = state.dataLoopNodes.Node[InletNode - 1].Enthalpy
    state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].InletPressure = state.dataLoopNodes.Node[InletNode - 1].Press
    state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].InletRH = PsyRhFnTdbWPb(
        state,
        state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].InletTemp,
        state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].InletHumRat,
        state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].InletPressure,
        "InitZoneHybridUnitaryAirConditioners"
    )
    state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].OutletTemp = (
        state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].InletTemp
    )
    state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].OutletHumRat = (
        state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].InletHumRat
    )
    state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].OutletEnthalpy = (
        state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].InletEnthalpy
    )
    state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].OutletPressure = (
        state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].InletPressure
    )
    state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].OutletRH = PsyRhFnTdbWPb(
        state,
        state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].OutletTemp,
        state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].OutletHumRat,
        state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].OutletPressure,
        "InitZoneHybridUnitaryAirConditioners"
    )
    state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].OutletMassFlowRate = (
        state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].InletMassFlowRate
    )
    state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].SecInletTemp = (
        state.dataLoopNodes.Node[state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].SecondaryInletNode - 1].Temp
    )
    state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].SecInletHumRat = (
        state.dataLoopNodes.Node[state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].SecondaryInletNode - 1].HumRat
    )
    state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].SecInletEnthalpy = (
        state.dataLoopNodes.Node[state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].SecondaryInletNode - 1].Enthalpy
    )
    state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].SecInletPressure = (
        state.dataLoopNodes.Node[state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].SecondaryInletNode - 1].Press
    )
    state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].SecInletRH = PsyRhFnTdbWPb(
        state,
        state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].SecInletTemp,
        state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].SecInletHumRat,
        state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].SecInletPressure,
        "InitZoneHybridUnitaryAirConditioners"
    )
    state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].SecInletMassFlowRate = (
        state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].SupplyVentilationAir
    )
    state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].SecOutletTemp = (
        state.dataLoopNodes.Node[state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].SecondaryInletNode - 1].Temp
    )
    state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].SecOutletHumRat = (
        state.dataLoopNodes.Node[state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].SecondaryInletNode - 1].HumRat
    )
    state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].SecOutletEnthalpy = (
        state.dataLoopNodes.Node[state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].SecondaryInletNode - 1].Enthalpy
    )
    state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].SecOutletPressure = (
        state.dataLoopNodes.Node[state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].SecondaryInletNode - 1].Press
    )
    state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].SecOutletRH = PsyRhFnTdbWPb(
        state,
        state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].SecInletTemp,
        state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].SecInletHumRat,
        state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].SecInletPressure,
        "InitZoneHybridUnitaryAirConditioners"
    )

def CalcZoneHybridUnitaryAirConditioners(
    inout state: EnergyPlusData,
    UnitNum: Int,
    ZoneNum: Int,
    inout SensibleOutputProvided: Float64,
    inout LatentOutputProvided: Float64
):
    from Psychrometrics import *
    var EnvDryBulbT: Float64
    var AirTempRoom: Float64
    var EnvRelHumm: Float64
    var RoomRelHum: Float64
    var DesignMinVR: Float64
    var ZoneCoolingLoad: Float64 = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNum - 1].RemainingOutputReqToCoolSP
    var ZoneHeatingLoad: Float64 = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNum - 1].RemainingOutputReqToHeatSP
    var OutputRequiredToHumidify: Float64 = state.dataZoneEnergyDemand.ZoneSysMoistureDemand[ZoneNum - 1].OutputRequiredToHumidifyingSP
    var OutputRequiredToDehumidify: Float64 = state.dataZoneEnergyDemand.ZoneSysMoistureDemand[ZoneNum - 1].OutputRequiredToDehumidifyingSP
    SensibleOutputProvided = 0.0
    LatentOutputProvided = 0.0
    EnvDryBulbT = state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].SecInletTemp
    AirTempRoom = state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].InletTemp
    EnvRelHumm = state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].SecInletRH
    RoomRelHum = state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].InletRH
    var UseOccSchFlag: Bool = True
    var UseMinOASchFlag: Bool = True
    DesignMinVR = calcDesignSpecificationOutdoorAir(
        state,
        state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].OARequirementsPtr,
        ZoneNum,
        UseOccSchFlag,
        UseMinOASchFlag
    )
    var DesignMinVRMassFlow: Float64 = 0.0
    if state.dataEnvrn.StdRhoAir > 1:
        DesignMinVRMassFlow = DesignMinVR * state.dataEnvrn.StdRhoAir
    else:
        DesignMinVRMassFlow = DesignMinVR * 1.225
    state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].doStep(
        state, ZoneCoolingLoad, ZoneHeatingLoad, OutputRequiredToHumidify, OutputRequiredToDehumidify, DesignMinVRMassFlow
    )
    SensibleOutputProvided = -state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].QSensZoneOut
    LatentOutputProvided = -state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].QLatentZoneOutMass

def ReportZoneHybridUnitaryAirConditioners(inout state: EnergyPlusData, UnitNum: Int):
    from Psychrometrics import *
    state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].PrimaryMode = (
        state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].PrimaryMode
    )
    state.dataLoopNodes.Node[state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].InletNode - 1].Temp = (
        state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].InletTemp
    )
    state.dataLoopNodes.Node[state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].InletNode - 1].HumRat = (
        state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].InletHumRat
    )
    state.dataLoopNodes.Node[state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].InletNode - 1].MassFlowRate = (
        state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].InletMassFlowRate
    )
    state.dataLoopNodes.Node[state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].InletNode - 1].Enthalpy = (
        state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].InletEnthalpy
    )
    state.dataLoopNodes.Node[state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].OutletNode - 1].Temp = (
        state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].OutletTemp
    )
    state.dataLoopNodes.Node[state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].OutletNode - 1].HumRat = (
        state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].OutletHumRat
    )
    state.dataLoopNodes.Node[state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].OutletNode - 1].MassFlowRate = (
        state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].OutletMassFlowRate
    )
    state.dataLoopNodes.Node[state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].OutletNode - 1].Enthalpy = (
        state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].OutletEnthalpy
    )
    state.dataLoopNodes.Node[state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].SecondaryInletNode - 1].Temp = (
        state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].SecInletTemp
    )
    state.dataLoopNodes.Node[state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].SecondaryInletNode - 1].HumRat = (
        state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].SecInletHumRat
    )
    state.dataLoopNodes.Node[state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].SecondaryInletNode - 1].Enthalpy = (
        state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].SecInletEnthalpy
    )
    state.dataLoopNodes.Node[state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].SecondaryInletNode - 1].MassFlowRate = (
        state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].SecInletMassFlowRate
    )
    state.dataLoopNodes.Node[state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].SecondaryOutletNode - 1].Temp = (
        state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].SecOutletTemp
    )
    state.dataLoopNodes.Node[state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].SecondaryOutletNode - 1].HumRat = (
        state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].SecOutletHumRat
    )
    state.dataLoopNodes.Node[state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].SecondaryOutletNode - 1].Enthalpy = (
        state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].SecOutletEnthalpy
    )
    state.dataLoopNodes.Node[state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].SecondaryOutletNode - 1].MassFlowRate = (
        state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitNum - 1].SecOutletMassFlowRate
    )

def GetInputZoneHybridUnitaryAirConditioners(inout state: EnergyPlusData, inout Errors: Bool):
    from Node import GetOnlySingleNode, SetUpCompSets, TestCompSet
    from InputProcessing import InputProcessor, ErrorObjectHeader, ShowSevereItemNotFound, ShowSevereInvalidKey
    from ScheduleManager import Sched
    from UtilityRoutines import makeUPPER, SameString, FindItemInList
    from HybridEvapCoolingModel import CSetting, Model, ObjectiveFunctionType, objectiveFunctionNamesUC
    from DataSizing import OARequirements
    from Autosizing.Base import BaseSizer
    from Constant import eFuel, eFuelNamesUC, eFuel2eResource, Units, eResource

    var cCurrentModuleObject: String = "ZoneHVAC:HybridUnitaryHVAC"
    var Alphas: List[String] = List[String]()
    var Numbers: List[Float64] = List[Float64]()
    var cAlphaFields: List[String] = List[String]()
    var cNumericFields: List[String] = List[String]()
    var lAlphaBlanks: List[Bool] = List[Bool]()
    var lNumericBlanks: List[Bool] = List[Bool]()
    var NumAlphas: Int
    var NumNumbers: Int
    var NumFields: Int
    var ErrorsFound: Bool = False
    var UnitLoop: Int
    var routineName: String = "GetInputZoneHybridUnitaryAirConditioners"

    state.dataHybridUnitaryAC.NumZoneHybridEvap = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, cCurrentModuleObject)
    var tmpMaxArgs = state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, cCurrentModuleObject, NumFields, NumAlphas, NumNumbers)
    var MaxNumbers: Int = max(0, NumNumbers)
    var MaxAlphas: Int = max(0, NumAlphas)

    Alphas = ["" for _ in range(MaxAlphas)]
    Numbers = [0.0 for _ in range(MaxNumbers)]
    cAlphaFields = ["" for _ in range(MaxAlphas)]
    cNumericFields = ["" for _ in range(MaxNumbers)]
    lAlphaBlanks = [True for _ in range(MaxAlphas)]
    lNumericBlanks = [True for _ in range(MaxNumbers)]

    if state.dataHybridUnitaryAC.NumZoneHybridEvap > 0:
        state.dataHybridUnitaryAC.CheckZoneHybridEvapName = [True for _ in range(state.dataHybridUnitaryAC.NumZoneHybridEvap)]
        state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner = [Model() for _ in range(state.dataHybridUnitaryAC.NumZoneHybridEvap)]
        var IOStatus: Int = 0
        for UnitLoop in range(state.dataHybridUnitaryAC.NumZoneHybridEvap):
            state.dataInputProcessing.inputProcessor.getObjectItem(
                state,
                cCurrentModuleObject,
                UnitLoop + 1,  # getObjectItem expects 1-based index
                Alphas,
                NumAlphas,
                Numbers,
                NumNumbers,
                IOStatus,
                lNumericBlanks,
                lAlphaBlanks,
                cAlphaFields,
                cNumericFields
            )
            var eoh = ErrorObjectHeader(routineName, cCurrentModuleObject, Alphas[0])
            var hybridUnitaryAC = state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitLoop]
            hybridUnitaryAC.Name = Alphas[0]
            if lAlphaBlanks[1]:
                hybridUnitaryAC.availSched = Sched.GetScheduleAlwaysOn(state)
            else:
                hybridUnitaryAC.availSched = Sched.GetSchedule(state, Alphas[1])
                if hybridUnitaryAC.availSched == None:
                    ShowSevereItemNotFound(state, eoh, cAlphaFields[1], Alphas[1])
                    ErrorsFound = True
            if not lAlphaBlanks[2]:
                hybridUnitaryAC.AvailManagerListName = Alphas[2]
            if lAlphaBlanks[3]:

            else:
                hybridUnitaryAC.TsaMinSched = Sched.GetSchedule(state, Alphas[3])
                if hybridUnitaryAC.TsaMinSched == None:
                    ShowSevereItemNotFound(state, eoh, cAlphaFields[3], Alphas[3])
                    ErrorsFound = True
            if lAlphaBlanks[4]:

            else:
                hybridUnitaryAC.TsaMaxSched = Sched.GetSchedule(state, Alphas[4])
                if hybridUnitaryAC.TsaMaxSched == None:
                    ShowSevereItemNotFound(state, eoh, cAlphaFields[4], Alphas[4])
                    ErrorsFound = True
            if lAlphaBlanks[5]:

            else:
                hybridUnitaryAC.RHsaMinSched = Sched.GetSchedule(state, Alphas[5])
                if hybridUnitaryAC.RHsaMinSched == None:
                    ShowSevereItemNotFound(state, eoh, cAlphaFields[5], Alphas[5])
                    ErrorsFound = True
            if lAlphaBlanks[6]:

            else:
                hybridUnitaryAC.RHsaMaxSched = Sched.GetSchedule(state, Alphas[6])
                if hybridUnitaryAC.RHsaMaxSched == None:
                    ShowSevereItemNotFound(state, eoh, cAlphaFields[6], Alphas[6])
                    ErrorsFound = True
            hybridUnitaryAC.InletNode = GetOnlySingleNode(
                state,
                Alphas[8],
                ErrorsFound,
                Node.ConnectionObjectType.ZoneHVACHybridUnitaryHVAC,
                Alphas[0],
                Node.FluidType.Air,
                Node.ConnectionType.Inlet,
                Node.CompFluidStream.Primary,
                Node.ObjectIsNotParent
            )
            hybridUnitaryAC.SecondaryInletNode = GetOnlySingleNode(
                state,
                Alphas[9],
                ErrorsFound,
                Node.ConnectionObjectType.ZoneHVACHybridUnitaryHVAC,
                Alphas[0],
                Node.FluidType.Air,
                Node.ConnectionType.OutsideAir,
                Node.CompFluidStream.Primary,
                Node.ObjectIsNotParent
            )
            hybridUnitaryAC.OutletNode = GetOnlySingleNode(
                state,
                Alphas[10],
                ErrorsFound,
                Node.ConnectionObjectType.ZoneHVACHybridUnitaryHVAC,
                Alphas[0],
                Node.FluidType.Air,
                Node.ConnectionType.Outlet,
                Node.CompFluidStream.Primary,
                Node.ObjectIsNotParent
            )
            hybridUnitaryAC.SecondaryOutletNode = GetOnlySingleNode(
                state,
                Alphas[11],
                ErrorsFound,
                Node.ConnectionObjectType.ZoneHVACHybridUnitaryHVAC,
                Alphas[0],
                Node.FluidType.Air,
                Node.ConnectionType.ReliefAir,
                Node.CompFluidStream.Primary,
                Node.ObjectIsNotParent
            )
            TestCompSet(state, cCurrentModuleObject, Alphas[0], Alphas[8], Alphas[10], "Hybrid Evap Air Zone Nodes")
            TestCompSet(state, cCurrentModuleObject, Alphas[0], Alphas[9], Alphas[11], "Hybrid Evap Air Zone Secondary Nodes")
            hybridUnitaryAC.SystemMaximumSupplyAirFlowRate = Numbers[0]
            hybridUnitaryAC.FanHeatGain = False
            if not lAlphaBlanks[12]:
                if SameString(Alphas[12], "Yes"):
                    hybridUnitaryAC.FanHeatGain = False
                elif SameString(Alphas[12], "No"):
                    hybridUnitaryAC.FanHeatGain = True
                else:
                    ShowSevereError(state, "{} = {}".format(cCurrentModuleObject, hybridUnitaryAC.Name))
                    ShowContinueError(state, "Illegal {} = {}".format(cAlphaFields[12], Alphas[12]))
                    ErrorsFound = True
            if not lAlphaBlanks[13]:
                hybridUnitaryAC.FanHeatGainLocation = Alphas[13]
            hybridUnitaryAC.FanHeatInAirFrac = Numbers[2]
            hybridUnitaryAC.ScalingFactor = Numbers[3]
            hybridUnitaryAC.ScaledSystemMaximumSupplyAirVolumeFlowRate = Numbers[0] * Numbers[3]
            if state.dataEnvrn.StdRhoAir > 1:
                hybridUnitaryAC.ScaledSystemMaximumSupplyAirMassFlowRate = (
                    hybridUnitaryAC.ScaledSystemMaximumSupplyAirVolumeFlowRate * state.dataEnvrn.StdRhoAir
                )
            else:
                hybridUnitaryAC.ScaledSystemMaximumSupplyAirMassFlowRate = hybridUnitaryAC.ScaledSystemMaximumSupplyAirVolumeFlowRate * 1.225
            if lAlphaBlanks[14]:

            else:
                hybridUnitaryAC.firstFuel = static_cast[Constant.eFuel](getEnumValue(Constant.eFuelNamesUC, makeUPPER(Alphas[14])))
                if hybridUnitaryAC.firstFuel == Constant.eFuel.Invalid:
                    ShowSevereInvalidKey(state, eoh, cAlphaFields[14], Alphas[14])
                    ErrorsFound = True
            if not lAlphaBlanks[15] and Alphas[15] != "NONE":
                hybridUnitaryAC.secondFuel = static_cast[Constant.eFuel](getEnumValue(Constant.eFuelNamesUC, makeUPPER(Alphas[15])))
                if hybridUnitaryAC.secondFuel == Constant.eFuel.Invalid:
                    ShowSevereInvalidKey(state, eoh, cAlphaFields[15], Alphas[15])
                    ErrorsFound = True
            if not lAlphaBlanks[16] and Alphas[16] != "NONE":
                hybridUnitaryAC.thirdFuel = static_cast[Constant.eFuel](getEnumValue(Constant.eFuelNamesUC, makeUPPER(Alphas[16])))
                if hybridUnitaryAC.thirdFuel == Constant.eFuel.Invalid:
                    ShowSevereInvalidKey(state, eoh, cAlphaFields[16], Alphas[16])
                    ErrorsFound = True
            if not lAlphaBlanks[17]:
                hybridUnitaryAC.ObjectiveFunction = static_cast[HybridEvapCoolingModel.ObjectiveFunctionType](
                    getEnumValue(HybridEvapCoolingModel.objectiveFunctionNamesUC, makeUPPER(Alphas[17]))
                )
                if hybridUnitaryAC.ObjectiveFunction == HybridEvapCoolingModel.ObjectiveFunctionType.Invalid:
                    ShowSevereInvalidKey(state, eoh, cAlphaFields[17], Alphas[17])
                    ErrorsFound = True
            if not lAlphaBlanks[18]:
                hybridUnitaryAC.OARequirementsPtr = FindItemInList(Alphas[18], state.dataSize.OARequirements)
                if hybridUnitaryAC.OARequirementsPtr == 0:
                    ShowSevereError(state, "{}: {} = {} invalid data".format(routineName, cCurrentModuleObject, Alphas[0]))
                    ShowContinueError(state, "Invalid-not found {}=\"{}\".".format(cAlphaFields[18], Alphas[18]))
                    ErrorsFound = True
                else:
                    hybridUnitaryAC.OutdoorAir = True
            var FirstModeAlphaNumber: Int = 19  # 0-indexed: alpha index 19 is 20th item (C++ 1-indexed 20)
            var NumberOfAlphasPerMode: Int = 9
            var Numberofoperatingmodes: Int = 0
            for i in range(FirstModeAlphaNumber, NumAlphas, NumberOfAlphasPerMode):
                if not lAlphaBlanks[i]:
                    Numberofoperatingmodes += 1
                else:
                    break
            for modeIter in range(Numberofoperatingmodes):
                ErrorsFound = hybridUnitaryAC.ParseMode(state, Alphas, cAlphaFields, Numbers, lAlphaBlanks, lNumericBlanks, cCurrentModuleObject)
                if ErrorsFound:
                    ShowFatalError(state, "{}: Errors found parsing modes".format(routineName))
                    ShowContinueError(state, "... Preceding condition causes termination.")
                    break
            BaseSizer.reportSizerOutput(
                state,
                cCurrentModuleObject,
                hybridUnitaryAC.Name,
                "Scaled Maximum Supply Air Volume Flow Rate [m3/s]",
                hybridUnitaryAC.ScaledSystemMaximumSupplyAirVolumeFlowRate
            )

    for UnitLoop in range(state.dataHybridUnitaryAC.NumZoneHybridEvap):
        var hybridUnitaryAC = state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitLoop]
        SetUpCompSets(
            state,
            cCurrentModuleObject,
            hybridUnitaryAC.Name,
            cCurrentModuleObject,
            hybridUnitaryAC.Name,
            state.dataLoopNodes.NodeID[hybridUnitaryAC.InletNode - 1],
            state.dataLoopNodes.NodeID[hybridUnitaryAC.OutletNode - 1]
        )
        SetUpCompSets(
            state,
            cCurrentModuleObject,
            hybridUnitaryAC.Name,
            cCurrentModuleObject,
            hybridUnitaryAC.Name,
            state.dataLoopNodes.NodeID[hybridUnitaryAC.SecondaryInletNode - 1],
            state.dataLoopNodes.NodeID[hybridUnitaryAC.SecondaryOutletNode - 1]
        )
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC System Total Cooling Rate", Units.W, hybridUnitaryAC.SystemTotalCoolingRate, TimeStepType.System, StoreType.Average, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC System Total Cooling Energy", Units.J, hybridUnitaryAC.SystemTotalCoolingEnergy, TimeStepType.System, StoreType.Sum, hybridUnitaryAC.Name, eResource.EnergyTransfer, Group.HVAC, EndUseCat.CoolingCoils)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC System Sensible Cooling Rate", Units.W, hybridUnitaryAC.SystemSensibleCoolingRate, TimeStepType.System, StoreType.Average, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC System Sensible Cooling Energy", Units.J, hybridUnitaryAC.SystemSensibleCoolingEnergy, TimeStepType.System, StoreType.Sum, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC System Latent Cooling Rate", Units.W, hybridUnitaryAC.SystemLatentCoolingRate, TimeStepType.System, StoreType.Average, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC System Latent Cooling Energy", Units.J, hybridUnitaryAC.SystemLatentCoolingEnergy, TimeStepType.System, StoreType.Sum, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Zone Total Cooling Rate", Units.W, hybridUnitaryAC.UnitTotalCoolingRate, TimeStepType.System, StoreType.Average, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Zone Total Cooling Energy", Units.J, hybridUnitaryAC.UnitTotalCoolingEnergy, TimeStepType.System, StoreType.Sum, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Zone Sensible Cooling Rate", Units.W, hybridUnitaryAC.UnitSensibleCoolingRate, TimeStepType.System, StoreType.Average, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Zone Sensible Cooling Energy", Units.J, hybridUnitaryAC.UnitSensibleCoolingEnergy, TimeStepType.System, StoreType.Sum, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Zone Latent Cooling Rate", Units.W, hybridUnitaryAC.UnitLatentCoolingRate, TimeStepType.System, StoreType.Average, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Zone Latent Cooling Energy", Units.J, hybridUnitaryAC.UnitLatentCoolingEnergy, TimeStepType.System, StoreType.Sum, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC System Total Heating Rate", Units.W, hybridUnitaryAC.SystemTotalHeatingRate, TimeStepType.System, StoreType.Average, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC System Total Heating Energy", Units.J, hybridUnitaryAC.SystemTotalHeatingEnergy, TimeStepType.System, StoreType.Sum, hybridUnitaryAC.Name, eResource.EnergyTransfer, Group.HVAC, EndUseCat.HeatingCoils)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC System Sensible Heating Rate", Units.W, hybridUnitaryAC.SystemSensibleHeatingRate, TimeStepType.System, StoreType.Average, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC System Sensible Heating Energy", Units.J, hybridUnitaryAC.SystemSensibleHeatingEnergy, TimeStepType.System, StoreType.Sum, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC System Latent Heating Rate", Units.W, hybridUnitaryAC.SystemLatentHeatingRate, TimeStepType.System, StoreType.Average, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC System Latent Heating Energy", Units.J, hybridUnitaryAC.SystemLatentHeatingEnergy, TimeStepType.System, StoreType.Sum, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Zone Total Heating Rate", Units.W, hybridUnitaryAC.UnitTotalHeatingRate, TimeStepType.System, StoreType.Average, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Zone Total Heating Energy", Units.J, hybridUnitaryAC.UnitTotalHeatingEnergy, TimeStepType.System, StoreType.Sum, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Zone Sensible Heating Rate", Units.W, hybridUnitaryAC.UnitSensibleHeatingRate, TimeStepType.System, StoreType.Average, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Zone Sensible Heating Energy", Units.J, hybridUnitaryAC.UnitSensibleHeatingEnergy, TimeStepType.System, StoreType.Sum, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Zone Latent Heating Rate", Units.W, hybridUnitaryAC.UnitLatentHeatingRate, TimeStepType.System, StoreType.Average, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Zone Latent Heating Energy", Units.J, hybridUnitaryAC.UnitLatentHeatingEnergy, TimeStepType.System, StoreType.Sum, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Predicted Sensible Load to Setpoint Heat Transfer Rate", Units.W, hybridUnitaryAC.RequestedLoadToCoolingSetpoint, TimeStepType.System, StoreType.Average, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Error Code", Units.None, hybridUnitaryAC.ErrorCode, TimeStepType.System, StoreType.Average, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Supply Air Temperature", Units.C, hybridUnitaryAC.OutletTemp, TimeStepType.System, StoreType.Average, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Return Air Temperature", Units.C, hybridUnitaryAC.InletTemp, TimeStepType.System, StoreType.Average, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Outdoor Air Temperature", Units.C, hybridUnitaryAC.SecInletTemp, TimeStepType.System, StoreType.Average, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Relief Air Temperature", Units.C, hybridUnitaryAC.SecOutletTemp, TimeStepType.System, StoreType.Average, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Supply Air Humidity Ratio", Units.kgWater_kgDryAir, hybridUnitaryAC.OutletHumRat, TimeStepType.System, StoreType.Average, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Return Air Humidity Ratio", Units.kgWater_kgDryAir, hybridUnitaryAC.InletHumRat, TimeStepType.System, StoreType.Average, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Outdoor Air Humidity Ratio", Units.kgWater_kgDryAir, hybridUnitaryAC.SecInletHumRat, TimeStepType.System, StoreType.Average, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Relief Air Humidity Ratio", Units.kgWater_kgDryAir, hybridUnitaryAC.SecOutletHumRat, TimeStepType.System, StoreType.Average, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Supply Air Relative Humidity", Units.Perc, hybridUnitaryAC.OutletRH, TimeStepType.System, StoreType.Average, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Return Air Relative Humidity", Units.Perc, hybridUnitaryAC.InletRH, TimeStepType.System, StoreType.Average, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Outdoor Air Relative Humidity", Units.Perc, hybridUnitaryAC.SecInletRH, TimeStepType.System, StoreType.Average, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Relief Air Relative Humidity", Units.Perc, hybridUnitaryAC.SecOutletRH, TimeStepType.System, StoreType.Average, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Supply Air Mass Flow Rate", Units.kg_s, hybridUnitaryAC.OutletMassFlowRate, TimeStepType.System, StoreType.Average, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Supply Air Standard Density Volume Flow Rate", Units.m3_s, hybridUnitaryAC.OutletVolumetricFlowRate, TimeStepType.System, StoreType.Average, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Return Air Mass Flow Rate", Units.kg_s, hybridUnitaryAC.InletMassFlowRate, TimeStepType.System, StoreType.Average, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Return Air Standard Density Volume Flow Rate", Units.m3_s, hybridUnitaryAC.InletVolumetricFlowRate, TimeStepType.System, StoreType.Average, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Relief Air Mass Flow Rate", Units.kg_s, hybridUnitaryAC.SecOutletMassFlowRate, TimeStepType.System, StoreType.Average, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Relief Air Standard Density Volume Flow Rate", Units.m3_s, hybridUnitaryAC.SecOutletVolumetricFlowRate, TimeStepType.System, StoreType.Average, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Ventilation Air Standard Density Volume Flow Rate", Units.m3_s, hybridUnitaryAC.SupplyVentilationVolume, TimeStepType.System, StoreType.Average, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Electricity Rate", Units.W, hybridUnitaryAC.FinalElectricalPower, TimeStepType.System, StoreType.Average, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Electricity Energy", Units.J, hybridUnitaryAC.FinalElectricalEnergy, TimeStepType.System, StoreType.Sum, hybridUnitaryAC.Name, eResource.Electricity, Group.HVAC, EndUseCat.Cooling, "Hybrid HVAC Cooling")
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Requested Outdoor Air Ventilation Mass Flow Rate", Units.kg_s, hybridUnitaryAC.MinOA_Msa, TimeStepType.System, StoreType.Average, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Ventilation Air Mass Flow Rate", Units.kg_s, hybridUnitaryAC.SupplyVentilationAir, TimeStepType.System, StoreType.Average, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Availability Status", Units.None, hybridUnitaryAC.UnitOn, TimeStepType.System, StoreType.Average, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Outdoor Air Fraction", Units.None, hybridUnitaryAC.averageOSAF, TimeStepType.System, StoreType.Average, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Dehumidification Load to Humidistat Setpoint Moisture Transfer Rate", Units.kg_s, hybridUnitaryAC.RequestedDeHumidificationMass, TimeStepType.System, StoreType.Average, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Dehumidification Load to Humidistat Setpoint Heat Transfer Rate", Units.W, hybridUnitaryAC.RequestedDeHumidificationLoad, TimeStepType.System, StoreType.Average, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Dehumidification Load to Humidistat Setpoint Heat Transfer Energy", Units.J, hybridUnitaryAC.RequestedDeHumidificationEnergy, TimeStepType.System, StoreType.Average, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Humidification Load to Humidistat Setpoint Moisture Transfer Rate", Units.kg_s, hybridUnitaryAC.RequestedHumidificationMass, TimeStepType.System, StoreType.Average, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Humidification Load to Humidistat Setpoint Heat Transfer Rate", Units.W, hybridUnitaryAC.RequestedHumidificationLoad, TimeStepType.System, StoreType.Average, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Humidification Load to Humidistat Setpoint Heat Transfer Energy", Units.J, hybridUnitaryAC.RequestedHumidificationEnergy, TimeStepType.System, StoreType.Average, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Supply Fan Electricity Rate", Units.W, hybridUnitaryAC.SupplyFanElectricPower, TimeStepType.System, StoreType.Average, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Supply Fan Electricity Energy", Units.J, hybridUnitaryAC.SupplyFanElectricEnergy, TimeStepType.System, StoreType.Sum, hybridUnitaryAC.Name, eResource.Electricity, Group.HVAC, EndUseCat.Fans, "Hybrid HVAC Fans")
        if hybridUnitaryAC.secondFuel != Constant.eFuel.Invalid:
            SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Secondary Fuel Consumption Rate", Units.W, hybridUnitaryAC.SecondaryFuelConsumptionRate, TimeStepType.System, StoreType.Average, hybridUnitaryAC.Name)
            SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Secondary Fuel Consumption", Units.J, hybridUnitaryAC.SecondaryFuelConsumption, TimeStepType.System, StoreType.Sum, hybridUnitaryAC.Name, eFuel2eResource[int(hybridUnitaryAC.secondFuel)], Group.HVAC, EndUseCat.Cooling, "Hybrid HVAC Cooling")
        if hybridUnitaryAC.thirdFuel != Constant.eFuel.Invalid:
            SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Third Fuel Consumption Rate", Units.W, hybridUnitaryAC.ThirdFuelConsumptionRate, TimeStepType.System, StoreType.Average, hybridUnitaryAC.Name)
            SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Third Fuel Consumption", Units.J, hybridUnitaryAC.ThirdFuelConsumption, TimeStepType.System, StoreType.Sum, hybridUnitaryAC.Name, eFuel2eResource[int(hybridUnitaryAC.thirdFuel)], Group.HVAC, EndUseCat.Cooling, "Hybrid HVAC Cooling")
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Water Consumption Rate", Units.kgWater_s, hybridUnitaryAC.WaterConsumptionRate, TimeStepType.System, StoreType.Average, hybridUnitaryAC.Name)
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Water Consumption", Units.m3, hybridUnitaryAC.WaterConsumption, TimeStepType.System, StoreType.Sum, hybridUnitaryAC.Name, eResource.Water, Group.HVAC, EndUseCat.Cooling, "Hybrid HVAC Cooling")
        SetupOutputVariable(state, "Zone Hybrid Unitary HVAC External Static Pressure", Units.Pa, hybridUnitaryAC.ExternalStaticPressure, TimeStepType.System, StoreType.Average, hybridUnitaryAC.Name)
        if hybridUnitaryAC.FanHeatGain:
            SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Fan Rise in Air Temperature", Units.deltaC, hybridUnitaryAC.FanHeatTemp, TimeStepType.System, StoreType.Average, hybridUnitaryAC.Name)
            SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Fan Heat Gain to Air", Units.W, hybridUnitaryAC.PowerLossToAir, TimeStepType.System, StoreType.Average, hybridUnitaryAC.Name)
        var index: Int = 0
        for thisSetting in hybridUnitaryAC.CurrentOperatingSettings:
            SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Runtime Fraction in Setting {}".format(index), Units.None, thisSetting.Runtime_Fraction, TimeStepType.Zone, StoreType.Average, hybridUnitaryAC.Name)
            SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Mode in Setting {}".format(index), Units.None, thisSetting.Mode, TimeStepType.Zone, StoreType.Average, hybridUnitaryAC.Name)
            SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Outdoor Air Fraction in Setting {}".format(index), Units.kg_s, thisSetting.Outdoor_Air_Fraction, TimeStepType.Zone, StoreType.Average, hybridUnitaryAC.Name)
            SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Supply Air Mass Flow Rate in Setting {}".format(index), Units.kg_s, thisSetting.Unscaled_Supply_Air_Mass_Flow_Rate, TimeStepType.Zone, StoreType.Average, hybridUnitaryAC.Name)
            SetupOutputVariable(state, "Zone Hybrid Unitary HVAC Supply Air Mass Flow Rate Ratio in Setting {}".format(index), Units.None, thisSetting.Supply_Air_Mass_Flow_Rate_Ratio, TimeStepType.Zone, StoreType.Average, hybridUnitaryAC.Name)
            index += 1

    Errors = ErrorsFound
    if ErrorsFound:
        ShowFatalError(state, "{}: Errors found in getting input.".format(routineName))
        ShowContinueError(state, "... Preceding condition causes termination.")

def GetHybridUnitaryACOutAirNode(inout state: EnergyPlusData, CompNum: Int) -> Int:
    if state.dataHybridUnitaryAC.GetInputZoneHybridEvap:
        var errorsfound: Bool = False
        GetInputZoneHybridUnitaryAirConditioners(state, errorsfound)
        state.dataHybridUnitaryAC.GetInputZoneHybridEvap = False
    var GetHybridUnitaryACOutAirNode: Int = 0
    if CompNum > 0 and CompNum <= state.dataHybridUnitaryAC.NumZoneHybridEvap:
        GetHybridUnitaryACOutAirNode = state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[CompNum - 1].SecondaryInletNode
    return GetHybridUnitaryACOutAirNode

def GetHybridUnitaryACZoneInletNode(inout state: EnergyPlusData, CompNum: Int) -> Int:
    if state.dataHybridUnitaryAC.GetInputZoneHybridEvap:
        var errorsfound: Bool = False
        GetInputZoneHybridUnitaryAirConditioners(state, errorsfound)
        state.dataHybridUnitaryAC.GetInputZoneHybridEvap = False
    var GetHybridUnitaryACZoneInletNode: Int = 0
    if CompNum > 0 and CompNum <= state.dataHybridUnitaryAC.NumZoneHybridEvap:
        GetHybridUnitaryACZoneInletNode = state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[CompNum - 1].OutletNode
    return GetHybridUnitaryACZoneInletNode

def GetHybridUnitaryACReturnAirNode(inout state: EnergyPlusData, CompNum: Int) -> Int:
    if state.dataHybridUnitaryAC.GetInputZoneHybridEvap:
        var errorsfound: Bool = False
        GetInputZoneHybridUnitaryAirConditioners(state, errorsfound)
        state.dataHybridUnitaryAC.GetInputZoneHybridEvap = False
    var GetHybridUnitaryACReturnAirNode: Int = 0
    if CompNum > 0 and CompNum <= state.dataHybridUnitaryAC.NumZoneHybridEvap:
        GetHybridUnitaryACReturnAirNode = state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[CompNum - 1].InletNode
    return GetHybridUnitaryACReturnAirNode

def getHybridUnitaryACIndex(inout state: EnergyPlusData, CompName: String) -> Int:
    if state.dataHybridUnitaryAC.GetInputZoneHybridEvap:
        var errFlag: Bool = False
        GetInputZoneHybridUnitaryAirConditioners(state, errFlag)
        state.dataHybridUnitaryAC.GetInputZoneHybridEvap = False
    for UnitLoop in range(state.dataHybridUnitaryAC.NumZoneHybridEvap):
        if SameString(state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[UnitLoop].Name, CompName):
            return UnitLoop + 1  # return 1-based index
    return 0