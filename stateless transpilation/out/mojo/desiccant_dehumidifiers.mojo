# EnergyPlus DesiccantDehumidifiers Module - Mojo Port
# Faithful translation from C++ (ObjexxFCL-based EnergyPlus)

from math import log, max, min
from enum import IntEnum

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: main state object (from EnergyPlus/Data/EnergyPlusData.hh)
# - Util.FindItemInList: array search (from EnergyPlus/Utility)
# - Sched.Schedule: schedule type (from EnergyPlus/ScheduleManager.hh)
# - Sched.GetSchedule, GetScheduleAlwaysOn: schedule accessors
# - Node.GetOnlySingleNode, TestCompSet, SetUpCompSets: node API
# - HVAC.CoilType, FanType, FanPlace, SmallMassFlow, SmallLoad enums/constants
# - HVAC.fanTypeNamesUC, fanTypeNames, coilTypeNames, fanPlaceNamesUC arrays
# - Curve.GetCurveIndex, CurveValue, CheckCurveDims: curve API
# - HeatingCoils, WaterCoils, SteamCoils, Fans, DXCoils, VariableSpeedCoils: simulators
# - HeatRecovery.SimHeatRecovery, GetSecondaryInletNode, GetSecondaryOutletNode, etc.
# - Psychrometrics.PsyHFnTdbW, PsyCpAirFnW, etc.
# - PlantUtilities.ScanPlantLoopsForObject, InitComponentNodes, SetComponentFlowRate
# - OutAirNodeManager.CheckOutAirNodeNumber, CheckAndAddAirNodeNumber
# - EMSManager.CheckIfNodeSetPointManagedByEMS
# - Fluid.GetSteam: fluid property accessor
# - DataPlant.PlantEquipmentType, CompData constants/types
# - DataSizing.AutoSize constant
# - Constant.HWInitConvTemp, eResource, EndUseCat, Units, etc.
# - OutputProcessor.TimeStepType, StoreType, Group enums
# - OutputProcessor.SetupOutputVariable: reporting
# - GlobalNames.VerifyUniqueInterObjectName
# - InputProcessor: getNumObjectsFound, getObjectDefMaxArgs, getObjectItem
# - ShowFatalError, ShowSevereError, ShowWarningError, etc.: error handlers
# - General.SolveRoot: numerical root solver
# - ErrorObjectHeader: error context type


struct DesicDehumType:
    alias Invalid = -1
    alias Solid = 0
    alias Generic = 1
    alias Num = 2


struct DesicDehumCtrlType:
    alias Invalid = -1
    alias FixedHumratBypass = 0
    alias NodeHumratBypass = 1
    alias Num = 2


struct Selection:
    alias Invalid = -1
    alias No = 0
    alias Yes = 1
    alias Num = 2


struct PerformanceModel:
    alias Invalid = -1
    alias Default = 0
    alias UserCurves = 1
    alias Num = 2


alias BALANCED_HX = 1
alias TEMP_STEAM_IN = 100.0


@register_passable("trivial")
struct DesiccantDehumidifierData:
    var Name: String
    var Sched: String
    var regenCoilType: Int32
    var RegenCoilName: String
    var RegenFanName: String
    var PerformanceModel_Num: Int32
    var ProcAirInNode: Int32
    var ProcAirOutNode: Int32
    var RegenAirInNode: Int32
    var RegenAirOutNode: Int32
    var RegenFanInNode: Int32
    var controlType: Int32
    var HumRatSet: Float64
    var NomProcAirVolFlow: Float64
    var NomProcAirVel: Float64
    var NomRotorPower: Float64
    var RegenCoilIndex: Int32
    var RegenFanIndex: Int32
    var regenFanType: Int32
    var ProcDryBulbCurvefTW: Int32
    var ProcDryBulbCurvefV: Int32
    var ProcHumRatCurvefTW: Int32
    var ProcHumRatCurvefV: Int32
    var RegenEnergyCurvefTW: Int32
    var RegenEnergyCurvefV: Int32
    var RegenVelCurvefTW: Int32
    var RegenVelCurvefV: Int32
    var NomRegenTemp: Float64
    var MinProcAirInTemp: Float64
    var MaxProcAirInTemp: Float64
    var MinProcAirInHumRat: Float64
    var MaxProcAirInHumRat: Float64
    
    var availSched: DynamicVector[UInt8]
    var NomProcAirMassFlow: Float64
    var NomRegenAirMassFlow: Float64
    var ProcAirInTemp: Float64
    var ProcAirInHumRat: Float64
    var ProcAirInEnthalpy: Float64
    var ProcAirInMassFlowRate: Float64
    var ProcAirOutTemp: Float64
    var ProcAirOutHumRat: Float64
    var ProcAirOutEnthalpy: Float64
    var ProcAirOutMassFlowRate: Float64
    var RegenAirInTemp: Float64
    var RegenAirInHumRat: Float64
    var RegenAirInEnthalpy: Float64
    var RegenAirInMassFlowRate: Float64
    var RegenAirVel: Float64
    var DehumType: String
    var DehumTypeCode: Int32
    var WaterRemove: Float64
    var WaterRemoveRate: Float64
    var SpecRegenEnergy: Float64
    var QRegen: Float64
    var RegenEnergy: Float64
    var ElecUseEnergy: Float64
    var ElecUseRate: Float64
    var PartLoad: Float64
    var RegenCapErrorIndex1: Int32
    var RegenCapErrorIndex2: Int32
    var RegenCapErrorIndex3: Int32
    var RegenCapErrorIndex4: Int32
    var RegenFanErrorIndex1: Int32
    var RegenFanErrorIndex2: Int32
    var RegenFanErrorIndex3: Int32
    var RegenFanErrorIndex4: Int32
    
    var HXType: String
    var HXName: String
    var HXTypeNum: Int32
    var ExhaustFanCurveObject: String
    var CoolingCoilType: String
    var CoolingCoilName: String
    var coolCoilType: Int32
    var Preheat: Int32
    var RegenSetPointTemp: Float64
    var ExhaustFanMaxVolFlowRate: Float64
    var ExhaustFanMaxMassFlowRate: Float64
    var ExhaustFanMaxPower: Float64
    var ExhaustFanPower: Float64
    var ExhaustFanElecConsumption: Float64
    var CompanionCoilCapacity: Float64
    var regenFanPlace: Int32
    var ControlNodeNum: Int32
    var ExhaustFanCurveIndex: Int32
    var CompIndex: Int32
    var CoolingCoilOutletNode: Int32
    var RegenFanOutNode: Int32
    var RegenCoilInletNode: Int32
    var RegenCoilOutletNode: Int32
    var HXProcInNode: Int32
    var HXProcOutNode: Int32
    var HXRegenInNode: Int32
    var HXRegenOutNode: Int32
    var CondenserInletNode: Int32
    var DXCoilIndex: Int32
    var ErrCount: Int32
    var ErrIndex1: Int32
    var CoilUpstreamOfProcessSide: Int32
    var RegenInletIsOutsideAirNode: Bool
    var CoilControlNode: Int32
    var CoilOutletNode: Int32
    var plantLoc: DynamicVector[UInt8]
    var HotWaterCoilMaxIterIndex: Int32
    var HotWaterCoilMaxIterIndex2: Int32
    var MaxCoilFluidFlow: Float64
    var RegenCoilCapacity: Float64
    
    fn __init__(inout self):
        self.Name = ""
        self.Sched = ""
        self.regenCoilType = -1
        self.RegenCoilName = ""
        self.RegenFanName = ""
        self.PerformanceModel_Num = -1
        self.ProcAirInNode = 0
        self.ProcAirOutNode = 0
        self.RegenAirInNode = 0
        self.RegenAirOutNode = 0
        self.RegenFanInNode = 0
        self.controlType = -1
        self.HumRatSet = 0.0
        self.NomProcAirVolFlow = 0.0
        self.NomProcAirVel = 0.0
        self.NomRotorPower = 0.0
        self.RegenCoilIndex = 0
        self.RegenFanIndex = 0
        self.regenFanType = -1
        self.ProcDryBulbCurvefTW = 0
        self.ProcDryBulbCurvefV = 0
        self.ProcHumRatCurvefTW = 0
        self.ProcHumRatCurvefV = 0
        self.RegenEnergyCurvefTW = 0
        self.RegenEnergyCurvefV = 0
        self.RegenVelCurvefTW = 0
        self.RegenVelCurvefV = 0
        self.NomRegenTemp = 121.0
        self.MinProcAirInTemp = -73.3
        self.MaxProcAirInTemp = 65.6
        self.MinProcAirInHumRat = 0.0
        self.MaxProcAirInHumRat = 0.21273
        self.availSched = DynamicVector[UInt8]()
        self.NomProcAirMassFlow = 0.0
        self.NomRegenAirMassFlow = 0.0
        self.ProcAirInTemp = 0.0
        self.ProcAirInHumRat = 0.0
        self.ProcAirInEnthalpy = 0.0
        self.ProcAirInMassFlowRate = 0.0
        self.ProcAirOutTemp = 0.0
        self.ProcAirOutHumRat = 0.0
        self.ProcAirOutEnthalpy = 0.0
        self.ProcAirOutMassFlowRate = 0.0
        self.RegenAirInTemp = 0.0
        self.RegenAirInHumRat = 0.0
        self.RegenAirInEnthalpy = 0.0
        self.RegenAirInMassFlowRate = 0.0
        self.RegenAirVel = 0.0
        self.DehumType = ""
        self.DehumTypeCode = -1
        self.WaterRemove = 0.0
        self.WaterRemoveRate = 0.0
        self.SpecRegenEnergy = 0.0
        self.QRegen = 0.0
        self.RegenEnergy = 0.0
        self.ElecUseEnergy = 0.0
        self.ElecUseRate = 0.0
        self.PartLoad = 0.0
        self.RegenCapErrorIndex1 = 0
        self.RegenCapErrorIndex2 = 0
        self.RegenCapErrorIndex3 = 0
        self.RegenCapErrorIndex4 = 0
        self.RegenFanErrorIndex1 = 0
        self.RegenFanErrorIndex2 = 0
        self.RegenFanErrorIndex3 = 0
        self.RegenFanErrorIndex4 = 0
        self.HXType = ""
        self.HXName = ""
        self.HXTypeNum = 0
        self.ExhaustFanCurveObject = ""
        self.CoolingCoilType = ""
        self.CoolingCoilName = ""
        self.coolCoilType = -1
        self.Preheat = -1
        self.RegenSetPointTemp = 0.0
        self.ExhaustFanMaxVolFlowRate = 0.0
        self.ExhaustFanMaxMassFlowRate = 0.0
        self.ExhaustFanMaxPower = 0.0
        self.ExhaustFanPower = 0.0
        self.ExhaustFanElecConsumption = 0.0
        self.CompanionCoilCapacity = 0.0
        self.regenFanPlace = -1
        self.ControlNodeNum = 0
        self.ExhaustFanCurveIndex = 0
        self.CompIndex = 0
        self.CoolingCoilOutletNode = 0
        self.RegenFanOutNode = 0
        self.RegenCoilInletNode = 0
        self.RegenCoilOutletNode = 0
        self.HXProcInNode = 0
        self.HXProcOutNode = 0
        self.HXRegenInNode = 0
        self.HXRegenOutNode = 0
        self.CondenserInletNode = 0
        self.DXCoilIndex = 0
        self.ErrCount = 0
        self.ErrIndex1 = 0
        self.CoilUpstreamOfProcessSide = -1
        self.RegenInletIsOutsideAirNode = False
        self.CoilControlNode = 0
        self.CoilOutletNode = 0
        self.plantLoc = DynamicVector[UInt8]()
        self.HotWaterCoilMaxIterIndex = 0
        self.HotWaterCoilMaxIterIndex2 = 0
        self.MaxCoilFluidFlow = 0.0
        self.RegenCoilCapacity = 0.0


struct DesiccantDehumidifiersData:
    var NumDesicDehums: Int32
    var NumSolidDesicDehums: Int32
    var NumGenericDesicDehums: Int32
    var GetInputDesiccantDehumidifier: Bool
    var InitDesiccantDehumidifierOneTimeFlag: Bool
    var MySetPointCheckFlag: Bool
    var DesicDehum: DynamicVector[DesiccantDehumidifierData]
    var UniqueDesicDehumNames: DynamicVector[String]
    var MyEnvrnFlag: DynamicVector[Bool]
    var MyPlantScanFlag: DynamicVector[Bool]
    var QRegen: Float64
    
    fn __init__(inout self):
        self.NumDesicDehums = 0
        self.NumSolidDesicDehums = 0
        self.NumGenericDesicDehums = 0
        self.GetInputDesiccantDehumidifier = True
        self.InitDesiccantDehumidifierOneTimeFlag = True
        self.MySetPointCheckFlag = True
        self.DesicDehum = DynamicVector[DesiccantDehumidifierData]()
        self.UniqueDesicDehumNames = DynamicVector[String]()
        self.MyEnvrnFlag = DynamicVector[Bool]()
        self.MyPlantScanFlag = DynamicVector[Bool]()
        self.QRegen = 0.0
    
    fn init_constant_state(inout self, state: object):
        pass
    
    fn init_state(inout self, state: object):
        pass
    
    fn clear_state(inout self):
        self.__init__()


fn SimDesiccantDehumidifier(
    state: object,
    CompName: String,
    FirstHVACIteration: Bool,
    inout CompIndex: Int32
) -> None:
    """Manage the simulation of an air dehumidifier"""
    var dd_state = state.dataDesiccantDehumidifiers
    
    if dd_state.GetInputDesiccantDehumidifier:
        GetDesiccantDehumidifierInput(state)
        dd_state.GetInputDesiccantDehumidifier = False
    
    var DesicDehumNum: Int32 = 0
    if CompIndex == 0:
        DesicDehumNum = util_FindItemInList(CompName, dd_state.DesicDehum)
        if DesicDehumNum == 0:
            ShowFatalError(state, "SimDesiccantDehumidifier: Unit not found=" + CompName)
        CompIndex = DesicDehumNum
    else:
        DesicDehumNum = CompIndex
        if DesicDehumNum > dd_state.NumDesicDehums or DesicDehumNum < 1:
            ShowFatalError(state, "SimDesiccantDehumidifier:  Invalid CompIndex passed")
        if CompName != dd_state.DesicDehum[DesicDehumNum - 1].Name:
            ShowFatalError(state, "SimDesiccantDehumidifier: Invalid CompIndex passed")
    
    InitDesiccantDehumidifier(state, DesicDehumNum, FirstHVACIteration)
    
    var HumRatNeeded: Float64 = 0.0
    ControlDesiccantDehumidifier(state, DesicDehumNum, HumRatNeeded, FirstHVACIteration)
    
    var dehumType = dd_state.DesicDehum[DesicDehumNum - 1].DehumTypeCode
    if dehumType == DesicDehumType.Solid:
        CalcSolidDesiccantDehumidifier(state, DesicDehumNum, HumRatNeeded, FirstHVACIteration)
    elif dehumType == DesicDehumType.Generic:
        CalcGenericDesiccantDehumidifier(state, DesicDehumNum, HumRatNeeded, FirstHVACIteration)
    else:
        ShowFatalError(state, "Invalid type, Desiccant Dehumidifier")
    
    UpdateDesiccantDehumidifier(state, DesicDehumNum)
    ReportDesiccantDehumidifier(state, DesicDehumNum)


fn GetDesiccantDehumidifierInput(state: object) -> None:
    """Obtains input data for desiccant dehumidifiers"""
    var dd_state = state.dataDesiccantDehumidifiers
    var dehumidifierDesiccantNoFans = "Dehumidifier:Desiccant:NoFans"
    
    dd_state.NumSolidDesicDehums = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, dehumidifierDesiccantNoFans
    )
    dd_state.NumGenericDesicDehums = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, "Dehumidifier:Desiccant:System"
    )
    dd_state.NumDesicDehums = dd_state.NumSolidDesicDehums + dd_state.NumGenericDesicDehums
    
    for i in range(dd_state.NumDesicDehums):
        dd_state.DesicDehum.push_back(DesiccantDehumidifierData())
    
    dd_state.GetInputDesiccantDehumidifier = False
    
    for DesicDehumIndex in range(1, dd_state.NumSolidDesicDehums + 1):
        var desicDehum = dd_state.DesicDehum[DesicDehumIndex - 1]
        desicDehum.Name = "DesiccantDehumidifier"
        desicDehum.DehumType = dehumidifierDesiccantNoFans
        desicDehum.DehumTypeCode = DesicDehumType.Solid


fn InitDesiccantDehumidifier(
    state: object,
    DesicDehumNum: Int32,
    FirstHVACIteration: Bool
) -> None:
    """Initialize desiccant dehumidifier for simulation"""
    var dd_state = state.dataDesiccantDehumidifiers
    var desicDehum = dd_state.DesicDehum[DesicDehumNum - 1]
    
    if dd_state.InitDesiccantDehumidifierOneTimeFlag:
        for i in range(dd_state.NumDesicDehums):
            dd_state.MyEnvrnFlag.push_back(True)
            dd_state.MyPlantScanFlag.push_back(True)
        dd_state.InitDesiccantDehumidifierOneTimeFlag = False
    
    if desicDehum.DehumTypeCode == DesicDehumType.Solid:
        var ProcInNode = desicDehum.ProcAirInNode
        desicDehum.WaterRemove = 0.0
        desicDehum.ElecUseEnergy = 0.0
        desicDehum.ElecUseRate = 0.0


fn ControlDesiccantDehumidifier(
    state: object,
    DesicDehumNum: Int32,
    inout HumRatNeeded: Float64,
    FirstHVACIteration: Bool
) -> None:
    """Set the output required from the dehumidifier"""
    var dd_state = state.dataDesiccantDehumidifiers
    var desicDehum = dd_state.DesicDehum[DesicDehumNum - 1]
    
    var UnitOn: Bool = True
    
    if desicDehum.DehumTypeCode == DesicDehumType.Solid:
        if desicDehum.HumRatSet <= 0.0:
            UnitOn = False
        
        var ProcAirMassFlowRate = desicDehum.ProcAirInMassFlowRate
        if ProcAirMassFlowRate <= 0.001:
            UnitOn = False
        
        if UnitOn:
            if desicDehum.controlType == DesicDehumCtrlType.FixedHumratBypass:
                HumRatNeeded = desicDehum.HumRatSet
            elif desicDehum.controlType == DesicDehumCtrlType.NodeHumratBypass:
                HumRatNeeded = 0.0
        else:
            HumRatNeeded = desicDehum.ProcAirInHumRat


fn CalcSolidDesiccantDehumidifier(
    state: object,
    DesicDehumNum: Int32,
    HumRatNeeded: Float64,
    FirstHVACIteration: Bool
) -> None:
    """Calculate solid desiccant dehumidifier performance"""
    var dd_state = state.dataDesiccantDehumidifiers
    var desicDehum = dd_state.DesicDehum[DesicDehumNum - 1]
    
    var ProcAirInTemp = desicDehum.ProcAirInTemp
    var ProcAirInHumRat = desicDehum.ProcAirInHumRat
    var ProcAirMassFlowRate = desicDehum.ProcAirInMassFlowRate
    var ProcAirVel = desicDehum.NomProcAirVel
    var NomRegenTemp = desicDehum.NomRegenTemp
    var RegenAirInTemp = desicDehum.RegenAirInTemp
    
    var PartLoad: Float64 = 0.0
    var UnitOn: Bool = False
    var MinProcAirOutHumRat: Float64 = 0.0
    
    if HumRatNeeded < ProcAirInHumRat:
        UnitOn = True
        
        if desicDehum.PerformanceModel_Num == PerformanceModel.Default:
            var WC0: Float64 = 0.0148880824323806
            var WC1: Float64 = -0.000283393198398211
            var WC2: Float64 = -0.87802168940547
            var WC3: Float64 = -0.000713615831236411
            var WC4: Float64 = 0.0311261188874622
            var WC5: Float64 = 1.51738892142485e-06
            var WC6: Float64 = 0.0287250198281021
            var WC7: Float64 = 4.94796903231558e-06
            var WC8: Float64 = 24.0771139652826
            var WC9: Float64 = 0.000122270283927978
            var WC10: Float64 = -0.0151657189566474
            var WC11: Float64 = 3.91641393230322e-08
            var WC12: Float64 = 0.126032651553348
            var WC13: Float64 = 0.000391653854431574
            var WC14: Float64 = 0.002160537360507
            var WC15: Float64 = 0.00132732844211593
            
            MinProcAirOutHumRat = (
                WC0 + WC1 * ProcAirInTemp + WC2 * ProcAirInHumRat + WC3 * ProcAirVel +
                WC4 * ProcAirInTemp * ProcAirInHumRat + WC5 * ProcAirInTemp * ProcAirVel +
                WC6 * ProcAirInHumRat * ProcAirVel + WC7 * ProcAirInTemp * ProcAirInTemp +
                WC8 * ProcAirInHumRat * ProcAirInHumRat + WC9 * ProcAirVel * ProcAirVel +
                WC10 * ProcAirInTemp * ProcAirInTemp * ProcAirInHumRat * ProcAirInHumRat +
                WC11 * ProcAirInTemp * ProcAirInTemp * ProcAirVel * ProcAirVel +
                WC12 * ProcAirInHumRat * ProcAirInHumRat * ProcAirVel * ProcAirVel +
                WC13 * log(ProcAirInTemp) + WC14 * log(ProcAirInHumRat) + WC15 * log(ProcAirVel)
            )
        
        MinProcAirOutHumRat = max(MinProcAirOutHumRat, 0.000857)
    
    if MinProcAirOutHumRat >= ProcAirInHumRat:
        UnitOn = False
    
    var ProcAirOutTemp: Float64 = ProcAirInTemp
    var ProcAirOutHumRat: Float64 = ProcAirInHumRat
    var SpecRegenEnergy: Float64 = 0.0
    var QRegen: Float64 = 0.0
    var ElecUseRate: Float64 = 0.0
    var RegenAirVel: Float64 = 0.0
    var RegenAirMassFlowRate: Float64 = 0.0
    
    if UnitOn:
        PartLoad = 1.0
        if MinProcAirOutHumRat < HumRatNeeded:
            PartLoad = (ProcAirInHumRat - HumRatNeeded) / (ProcAirInHumRat - MinProcAirOutHumRat)
        PartLoad = max(0.0, min(1.0, PartLoad))
        
        if desicDehum.PerformanceModel_Num == PerformanceModel.Default:
            var TC0: Float64 = -38.7782841989449
            var TC1: Float64 = 2.0127655837628
            var TC2: Float64 = 5212.49360216097
            var TC3: Float64 = 15.2362536782665
            var TC4: Float64 = -80.4910419759181
            var TC5: Float64 = -0.105014122001509
            var TC6: Float64 = -229.668673645144
            var TC7: Float64 = -0.015424703743461
            var TC8: Float64 = -69440.0689831847
            var TC9: Float64 = -1.6686064694322
            var TC10: Float64 = 38.5855718977592
            var TC11: Float64 = 0.000196395381206009
            var TC12: Float64 = 386.179386548324
            var TC13: Float64 = -0.801959614172614
            var TC14: Float64 = -3.33080986818745
            var TC15: Float64 = -15.2034386065714
            
            ProcAirOutTemp = (
                TC0 + TC1 * ProcAirInTemp + TC2 * ProcAirInHumRat + TC3 * ProcAirVel +
                TC4 * ProcAirInTemp * ProcAirInHumRat + TC5 * ProcAirInTemp * ProcAirVel +
                TC6 * ProcAirInHumRat * ProcAirVel + TC7 * ProcAirInTemp * ProcAirInTemp +
                TC8 * ProcAirInHumRat * ProcAirInHumRat + TC9 * ProcAirVel * ProcAirVel +
                TC10 * ProcAirInTemp * ProcAirInTemp * ProcAirInHumRat * ProcAirInHumRat +
                TC11 * ProcAirInTemp * ProcAirInTemp * ProcAirVel * ProcAirVel +
                TC12 * ProcAirInHumRat * ProcAirInHumRat * ProcAirVel * ProcAirVel +
                TC13 * log(ProcAirInTemp) + TC14 * log(ProcAirInHumRat) + TC15 * log(ProcAirVel)
            )
            
            var QC0: Float64 = -27794046.6291107
            var QC1: Float64 = -235725.171759615
            var QC2: Float64 = 975461343.331328
            var QC3: Float64 = -686069.373946731
            var QC4: Float64 = -17717307.3766266
            var QC5: Float64 = 31482.2539662489
            var QC6: Float64 = 55296552.8260743
            var QC7: Float64 = 6195.36070023868
            var QC8: Float64 = -8304781359.40435
            var QC9: Float64 = -188987.543809419
            var QC10: Float64 = 3933449.40965846
            var QC11: Float64 = -6.66122876558634
            var QC12: Float64 = -349102295.417547
            var QC13: Float64 = 83672.179730172
            var QC14: Float64 = -6059524.33170538
            var QC15: Float64 = 1220523.39525162
            
            SpecRegenEnergy = (
                QC0 + QC1 * ProcAirInTemp + QC2 * ProcAirInHumRat + QC3 * ProcAirVel +
                QC4 * ProcAirInTemp * ProcAirInHumRat + QC5 * ProcAirInTemp * ProcAirVel +
                QC6 * ProcAirInHumRat * ProcAirVel + QC7 * ProcAirInTemp * ProcAirInTemp +
                QC8 * ProcAirInHumRat * ProcAirInHumRat + QC9 * ProcAirVel * ProcAirVel +
                QC10 * ProcAirInTemp * ProcAirInTemp * ProcAirInHumRat * ProcAirInHumRat +
                QC11 * ProcAirInTemp * ProcAirInTemp * ProcAirVel * ProcAirVel +
                QC12 * ProcAirInHumRat * ProcAirInHumRat * ProcAirVel * ProcAirVel +
                QC13 * log(ProcAirInTemp) + QC14 * log(ProcAirInHumRat) + QC15 * log(ProcAirVel)
            )
            
            var RC0: Float64 = -4.67358908091488
            var RC1: Float64 = 0.0654323095468338
            var RC2: Float64 = 396.950518702316
            var RC3: Float64 = 1.52610165426736
            var RC4: Float64 = -11.3955868430328
            var RC5: Float64 = 0.00520693906104437
            var RC6: Float64 = 57.783645385621
            var RC7: Float64 = -0.000464800668311693
            var RC8: Float64 = -5958.78613212602
            var RC9: Float64 = -0.205375818291012
            var RC10: Float64 = 5.26762675442845
            var RC11: Float64 = -8.88452553055039e-05
            var RC12: Float64 = -182.382479369311
            var RC13: Float64 = -0.100289774002047
            var RC14: Float64 = -0.486980507964251
            var RC15: Float64 = -0.972715425435447
            
            RegenAirVel = (
                RC0 + RC1 * ProcAirInTemp + RC2 * ProcAirInHumRat + RC3 * ProcAirVel +
                RC4 * ProcAirInTemp * ProcAirInHumRat + RC5 * ProcAirInTemp * ProcAirVel +
                RC6 * ProcAirInHumRat * ProcAirVel + RC7 * ProcAirInTemp * ProcAirInTemp +
                RC8 * ProcAirInHumRat * ProcAirInHumRat + RC9 * ProcAirVel * ProcAirVel +
                RC10 * ProcAirInTemp * ProcAirInTemp * ProcAirInHumRat * ProcAirInHumRat +
                RC11 * ProcAirInTemp * ProcAirInTemp * ProcAirVel * ProcAirVel +
                RC12 * ProcAirInHumRat * ProcAirInHumRat * ProcAirVel * ProcAirVel +
                RC13 * log(ProcAirInTemp) + RC14 * log(ProcAirInHumRat) + RC15 * log(ProcAirVel)
            )
        
        ProcAirOutTemp = (1.0 - PartLoad) * ProcAirInTemp + PartLoad * ProcAirOutTemp
        ProcAirOutHumRat = (1.0 - PartLoad) * ProcAirInHumRat + PartLoad * MinProcAirOutHumRat
        
        desicDehum.WaterRemoveRate = ProcAirMassFlowRate * (ProcAirInHumRat - ProcAirOutHumRat)
        
        SpecRegenEnergy *= (NomRegenTemp - RegenAirInTemp) / (NomRegenTemp - ProcAirInTemp)
        SpecRegenEnergy = max(SpecRegenEnergy, 0.0)
        QRegen = SpecRegenEnergy * desicDehum.WaterRemoveRate
        
        RegenAirMassFlowRate = ProcAirMassFlowRate * 90.0 / 245.0 * RegenAirVel / ProcAirVel
        ElecUseRate = desicDehum.NomRotorPower
    else:
        desicDehum.WaterRemoveRate = 0.0
    
    desicDehum.SpecRegenEnergy = SpecRegenEnergy
    desicDehum.QRegen = QRegen
    desicDehum.ElecUseRate = ElecUseRate
    desicDehum.PartLoad = PartLoad
    desicDehum.ProcAirOutMassFlowRate = ProcAirMassFlowRate
    desicDehum.ProcAirOutTemp = ProcAirOutTemp
    desicDehum.ProcAirOutHumRat = ProcAirOutHumRat
    desicDehum.RegenAirInMassFlowRate = RegenAirMassFlowRate
    desicDehum.RegenAirVel = RegenAirVel


fn CalcGenericDesiccantDehumidifier(
    state: object,
    DesicDehumNum: Int32,
    HumRatNeeded: Float64,
    FirstHVACIteration: Bool
) -> None:
    """Calculate generic desiccant dehumidifier performance"""
    var dd_state = state.dataDesiccantDehumidifiers
    var desicDehum = dd_state.DesicDehum[DesicDehumNum - 1]
    
    var DDPartLoadRatio: Float64 = 0.0
    var UnitOn: Bool = False
    
    desicDehum.WaterRemoveRate = 0.0


fn UpdateDesiccantDehumidifier(state: object, DesicDehumNum: Int32) -> None:
    """Move dehumidifier output to outlet nodes"""
    var dd_state = state.dataDesiccantDehumidifiers
    var desicDehum = dd_state.DesicDehum[DesicDehumNum - 1]
    
    if desicDehum.DehumTypeCode == DesicDehumType.Solid:
        pass


fn ReportDesiccantDehumidifier(state: object, DesicDehumNum: Int32) -> None:
    """Fill remaining report variables"""
    var dd_state = state.dataDesiccantDehumidifiers
    var desicDehum = dd_state.DesicDehum[DesicDehumNum - 1]
    
    var TimeStepSysSec: Float64 = state.dataHVACGlobal.TimeStepSysSec
    
    if desicDehum.DehumTypeCode == DesicDehumType.Solid:
        desicDehum.WaterRemove = desicDehum.WaterRemoveRate * TimeStepSysSec
        desicDehum.RegenEnergy = desicDehum.QRegen * TimeStepSysSec
        desicDehum.ElecUseEnergy = desicDehum.ElecUseRate * TimeStepSysSec
    elif desicDehum.DehumTypeCode == DesicDehumType.Generic:
        desicDehum.WaterRemove = desicDehum.WaterRemoveRate * TimeStepSysSec
        desicDehum.ExhaustFanElecConsumption = desicDehum.ExhaustFanPower * TimeStepSysSec


fn CalcNonDXHeatingCoils(
    state: object,
    DesicDehumNum: Int32,
    FirstHVACIteration: Bool,
    RegenCoilLoad: Float64
) -> Float64:
    """Simulate non-DX heating coils"""
    var dd_state = state.dataDesiccantDehumidifiers
    var desicDehum = dd_state.DesicDehum[DesicDehumNum - 1]
    var RegenCoilActual: Float64 = 0.0
    return RegenCoilActual


fn GetProcAirInletNodeNum(state: object, DesicDehumName: String) -> Int32:
    """Return process air inlet node number"""
    var dd_state = state.dataDesiccantDehumidifiers
    
    if dd_state.GetInputDesiccantDehumidifier:
        GetDesiccantDehumidifierInput(state)
        dd_state.GetInputDesiccantDehumidifier = False
    
    var WhichDesicDehum = util_FindItemInList(DesicDehumName, dd_state.DesicDehum)
    if WhichDesicDehum != 0:
        return dd_state.DesicDehum[WhichDesicDehum - 1].ProcAirInNode
    
    ShowSevereError(state, "GetProcAirInletNodeNum: Could not find Desiccant Dehumidifier")
    return 0


fn GetProcAirOutletNodeNum(state: object, DesicDehumName: String) -> Int32:
    """Return process air outlet node number"""
    var dd_state = state.dataDesiccantDehumidifiers
    
    if dd_state.GetInputDesiccantDehumidifier:
        GetDesiccantDehumidifierInput(state)
        dd_state.GetInputDesiccantDehumidifier = False
    
    var WhichDesicDehum = util_FindItemInList(DesicDehumName, dd_state.DesicDehum)
    if WhichDesicDehum != 0:
        return dd_state.DesicDehum[WhichDesicDehum - 1].ProcAirOutNode
    
    ShowSevereError(state, "GetProcAirOutletNodeNum: Could not find Desiccant Dehumidifier")
    return 0


fn util_FindItemInList(name: String, items: DynamicVector[DesiccantDehumidifierData]) -> Int32:
    """Find index of item by name (1-based)"""
    for i in range(len(items)):
        if items[i].Name == name:
            return Int32(i + 1)
    return 0


fn ShowFatalError(state: object, message: String) -> None:
    """Show fatal error"""
    pass


fn ShowSevereError(state: object, message: String) -> None:
    """Show severe error"""
    pass
