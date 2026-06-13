from collections import InlineArray
from math import exp, log

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object aggregating all simulation data structures
# - Sched.Schedule: schedule object with getCurrentVal() method
# - DataPlant.PlantEquipmentType: enum for equipment types
# - DataPlant.LoopSideLocation: enum for plant loop side
# - PlantLocation: struct with loop attribute
# - Node: node data with Temp, Enthalpy, MassFlowRate, etc.
# - ZoneSysEnergyDemand: struct with RemainingOutputReqToHeatSP
# - HeatBal.Zone: zone data with sumHATsurf() method
# - Surface: surface data with Area and Name
# - Utility functions: ShowFatalError, ShowSevereError, ShowWarningError, ShowContinueError
# - Util.FindItemInList: locate item in list by name
# - GetOnlySingleNode, GetZoneEquipControlledZoneNum, etc.: input functions
# - Psychrometrics.PsyCpAirFnW: humid air specific heat
# - PlantUtilities functions: various plant system utilities
# - OutputProcessor.SetupOutputVariable: variable output setup
# - Other EnergyPlus utilities as used


alias cCMO_BBRadiator_Water = "ZoneHVAC:Baseboard:RadiantConvective:Water"
alias cCMO_BBRadiator_Water_Design = "ZoneHVAC:Baseboard:RadiantConvective:Water:Design"


@register_passable("trivial")
struct HWBaseboardParams:
    var Name: String
    var EquipType: Int32
    var designObjectName: String
    var DesignObjectPtr: Int32
    var SurfacePtr: List[Int32]
    var ZonePtr: Int32
    var availSched: AnyType
    var WaterInletNode: Int32
    var WaterOutletNode: Int32
    var TotSurfToDistrib: Int32
    var ControlCompTypeNum: Int32
    var CompErrIndex: Int32
    var AirMassFlowRate: Float64
    var AirMassFlowRateStd: Float64
    var WaterTempAvg: Float64
    var RatedCapacity: Float64
    var UA: Float64
    var WaterMassFlowRate: Float64
    var WaterMassFlowRateMax: Float64
    var WaterMassFlowRateStd: Float64
    var WaterVolFlowRateMax: Float64
    var WaterInletTempStd: Float64
    var WaterInletTemp: Float64
    var WaterInletEnthalpy: Float64
    var WaterOutletTempStd: Float64
    var WaterOutletTemp: Float64
    var WaterOutletEnthalpy: Float64
    var AirInletTempStd: Float64
    var AirInletTemp: Float64
    var AirOutletTemp: Float64
    var AirInletHumRat: Float64
    var AirOutletTempStd: Float64
    var FracConvect: Float64
    var FracDistribToSurf: List[Float64]
    var TotPower: Float64
    var Power: Float64
    var ConvPower: Float64
    var RadPower: Float64
    var TotEnergy: Float64
    var Energy: Float64
    var ConvEnergy: Float64
    var RadEnergy: Float64
    var plantLoc: AnyType
    var BBLoadReSimIndex: Int32
    var BBMassFlowReSimIndex: Int32
    var BBInletTempFlowReSimIndex: Int32
    var HeatingCapMethod: Int32
    var ScaledHeatingCapacity: Float64
    var ZeroBBSourceSumHATsurf: Float64
    var QBBRadSource: Float64
    var QBBRadSrcAvg: Float64
    var LastSysTimeElapsed: Float64
    var LastTimeStepSys: Float64
    var LastQBBRadSrc: Float64

    fn __init__(inout self):
        self.Name = ""
        self.EquipType = 0
        self.designObjectName = ""
        self.DesignObjectPtr = 0
        self.SurfacePtr = List[Int32]()
        self.ZonePtr = 0
        self.availSched = AnyType()
        self.WaterInletNode = 0
        self.WaterOutletNode = 0
        self.TotSurfToDistrib = 0
        self.ControlCompTypeNum = 0
        self.CompErrIndex = 0
        self.AirMassFlowRate = 0.0
        self.AirMassFlowRateStd = 0.0
        self.WaterTempAvg = 0.0
        self.RatedCapacity = 0.0
        self.UA = 0.0
        self.WaterMassFlowRate = 0.0
        self.WaterMassFlowRateMax = 0.0
        self.WaterMassFlowRateStd = 0.0
        self.WaterVolFlowRateMax = 0.0
        self.WaterInletTempStd = 0.0
        self.WaterInletTemp = 0.0
        self.WaterInletEnthalpy = 0.0
        self.WaterOutletTempStd = 0.0
        self.WaterOutletTemp = 0.0
        self.WaterOutletEnthalpy = 0.0
        self.AirInletTempStd = 0.0
        self.AirInletTemp = 0.0
        self.AirOutletTemp = 0.0
        self.AirInletHumRat = 0.0
        self.AirOutletTempStd = 0.0
        self.FracConvect = 0.0
        self.FracDistribToSurf = List[Float64]()
        self.TotPower = 0.0
        self.Power = 0.0
        self.ConvPower = 0.0
        self.RadPower = 0.0
        self.TotEnergy = 0.0
        self.Energy = 0.0
        self.ConvEnergy = 0.0
        self.RadEnergy = 0.0
        self.plantLoc = AnyType()
        self.BBLoadReSimIndex = 0
        self.BBMassFlowReSimIndex = 0
        self.BBInletTempFlowReSimIndex = 0
        self.HeatingCapMethod = 0
        self.ScaledHeatingCapacity = 0.0
        self.ZeroBBSourceSumHATsurf = 0.0
        self.QBBRadSource = 0.0
        self.QBBRadSrcAvg = 0.0
        self.LastSysTimeElapsed = 0.0
        self.LastTimeStepSys = 0.0
        self.LastQBBRadSrc = 0.0


@register_passable("trivial")
struct HWBaseboardDesignData(HWBaseboardParams):
    var designName: String
    var HeatingCapMethodDesign: Int32
    var ScaledHeatingCapacityDesign: Float64
    var Offset: Float64
    var FracRadiant: Float64
    var FracDistribPerson: Float64

    fn __init__(inout self):
        HWBaseboardParams.__init__(self)
        self.designName = ""
        self.HeatingCapMethodDesign = 0
        self.ScaledHeatingCapacityDesign = 0.0
        self.Offset = 0.0
        self.FracRadiant = 0.0
        self.FracDistribPerson = 0.0


@register_passable("trivial")
struct HWBaseboardNumericFieldData:
    var FieldNames: List[String]

    fn __init__(inout self):
        self.FieldNames = List[String]()


@register_passable("trivial")
struct HWBaseboardDesignNumericFieldData:
    var FieldNames: List[String]

    fn __init__(inout self):
        self.FieldNames = List[String]()


@register_passable("trivial")
struct HWBaseboardRadiatorData:
    var MySizeFlag: List[Bool]
    var CheckEquipName: List[Bool]
    var SetLoopIndexFlag: List[Bool]
    var NumHWBaseboards: Int32
    var NumHWBaseboardDesignObjs: Int32
    var HWBaseboard: List[HWBaseboardParams]
    var HWBaseboardDesignObject: List[HWBaseboardDesignData]
    var HWBaseboardNumericFields: List[HWBaseboardNumericFieldData]
    var GetInputFlag: Bool
    var MyOneTimeFlag: Bool
    var Iter: Int32
    var MyEnvrnFlag2: Bool
    var MyEnvrnFlag: List[Bool]

    fn __init__(inout self):
        self.MySizeFlag = List[Bool]()
        self.CheckEquipName = List[Bool]()
        self.SetLoopIndexFlag = List[Bool]()
        self.NumHWBaseboards = 0
        self.NumHWBaseboardDesignObjs = 0
        self.HWBaseboard = List[HWBaseboardParams]()
        self.HWBaseboardDesignObject = List[HWBaseboardDesignData]()
        self.HWBaseboardNumericFields = List[HWBaseboardNumericFieldData]()
        self.GetInputFlag = True
        self.MyOneTimeFlag = True
        self.Iter = 0
        self.MyEnvrnFlag2 = True
        self.MyEnvrnFlag = List[Bool]()

    fn clear_state(inout self):
        self.MySizeFlag.clear()
        self.CheckEquipName.clear()
        self.SetLoopIndexFlag.clear()
        self.NumHWBaseboards = 0
        self.NumHWBaseboardDesignObjs = 0
        self.HWBaseboard.clear()
        self.HWBaseboardDesignObject.clear()
        self.HWBaseboardNumericFields.clear()
        self.GetInputFlag = True
        self.MyOneTimeFlag = True
        self.MyEnvrnFlag.clear()
        self.Iter = 0
        self.MyEnvrnFlag2 = True


@export
fn SimHWBaseboard(state: AnyType, EquipName: StringRef, ControlledZoneNum: Int32, FirstHVACIteration: Bool) -> Tuple[Float64, Int32]:
    var BaseboardNum: Int32 = 0
    var QZnReq: Float64 = 0.0
    var MaxWaterFlow: Float64 = 0.0
    var MinWaterFlow: Float64 = 0.0
    var PowerMet: Float64 = 0.0
    var CompIndex: Int32 = 0

    if state.dataHWBaseboardRad.GetInputFlag:
        GetHWBaseboardInput(state)
        state.dataHWBaseboardRad.GetInputFlag = False

    var NumHWBaseboards: Int32 = state.dataHWBaseboardRad.NumHWBaseboards

    if CompIndex == 0:
        BaseboardNum = find_item_in_list(EquipName, state.dataHWBaseboardRad.HWBaseboard)
        if BaseboardNum == -1:
            raise_error("SimHWBaseboard: Unit not found=" + String(EquipName))
        CompIndex = BaseboardNum
    else:
        BaseboardNum = CompIndex
        if BaseboardNum >= NumHWBaseboards or BaseboardNum < 0:
            raise_error("SimHWBaseboard: Invalid CompIndex passed=" + String(BaseboardNum))
        if state.dataHWBaseboardRad.CheckEquipName[BaseboardNum]:
            if String(EquipName) != state.dataHWBaseboardRad.HWBaseboard[BaseboardNum].Name:
                raise_error("SimHWBaseboard: Invalid CompIndex passed=" + String(BaseboardNum))
            state.dataHWBaseboardRad.CheckEquipName[BaseboardNum] = False

    if CompIndex >= 0:
        var HWBaseboard = state.dataHWBaseboardRad.HWBaseboard[BaseboardNum]
        var HWBaseboardDesignDataObject = state.dataHWBaseboardRad.HWBaseboardDesignObject[
            HWBaseboard.DesignObjectPtr
        ]

        InitHWBaseboard(state, BaseboardNum, ControlledZoneNum, FirstHVACIteration)

        QZnReq = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ControlledZoneNum].RemainingOutputReqToHeatSP

        if FirstHVACIteration:
            MaxWaterFlow = HWBaseboard.WaterMassFlowRateMax
            MinWaterFlow = 0.0
        else:
            MaxWaterFlow = state.dataLoopNodes.Node[HWBaseboard.WaterInletNode].MassFlowRateMaxAvail
            MinWaterFlow = state.dataLoopNodes.Node[HWBaseboard.WaterInletNode].MassFlowRateMinAvail

        if HWBaseboard.EquipType == 1:
            ControlCompOutput(
                state,
                HWBaseboard.Name,
                cCMO_BBRadiator_Water,
                BaseboardNum,
                FirstHVACIteration,
                QZnReq,
                HWBaseboard.WaterInletNode,
                MaxWaterFlow,
                MinWaterFlow,
                HWBaseboardDesignDataObject.Offset,
                HWBaseboard.ControlCompTypeNum,
                HWBaseboard.CompErrIndex,
                HWBaseboard.plantLoc,
            )
        else:
            raise_error("SimBaseboard: Errors in Baseboard")

        PowerMet = HWBaseboard.TotPower

        UpdateHWBaseboard(state, BaseboardNum)
        ReportHWBaseboard(state, BaseboardNum)
    else:
        raise_error("SimHWBaseboard: Unit not found=" + String(EquipName))

    return PowerMet, CompIndex


fn GetHWBaseboardInput(state: AnyType):
    var RoutineName: String = "GetHWBaseboardInput:"
    var routineName: String = "GetHWBaseboardInput"

    let MaxFraction: Float64 = 1.0
    let MinFraction: Float64 = 0.0
    let MaxWaterTempAvg: Float64 = 150.0
    let MinWaterTempAvg: Float64 = 20.0
    let HighWaterMassFlowRate: Float64 = 10.0
    let LowWaterMassFlowRate: Float64 = 0.00001
    let MaxWaterFlowRate: Float64 = 10.0
    let MinWaterFlowRate: Float64 = 0.00001
    let WaterMassFlowDefault: Float64 = 0.063
    let MinDistribSurfaces: Int32 = 1
    let iHeatCAPMAlphaNum: Int32 = 2
    let iHeatDesignCapacityNumericNum: Int32 = 3
    let iHeatCapacityPerFloorAreaNumericNum: Int32 = 1
    let iHeatFracOfAutosizedCapacityNumericNum: Int32 = 2

    var ErrorsFound: Bool = False

    var NumHWBaseboards: Int32 = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, cCMO_BBRadiator_Water
    )
    var NumHWBaseboardDesignObjs: Int32 = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, cCMO_BBRadiator_Water_Design
    )

    state.dataHWBaseboardRad.NumHWBaseboards = NumHWBaseboards
    state.dataHWBaseboardRad.NumHWBaseboardDesignObjs = NumHWBaseboardDesignObjs

    for _ in range(NumHWBaseboards):
        state.dataHWBaseboardRad.HWBaseboard.append(HWBaseboardParams())

    for _ in range(NumHWBaseboardDesignObjs):
        state.dataHWBaseboardRad.HWBaseboardDesignObject.append(HWBaseboardDesignData())

    for _ in range(NumHWBaseboards):
        state.dataHWBaseboardRad.CheckEquipName.append(True)

    for _ in range(NumHWBaseboards):
        state.dataHWBaseboardRad.HWBaseboardNumericFields.append(HWBaseboardNumericFieldData())

    var HWBaseboardDesignNames = List[String]()
    for _ in range(NumHWBaseboardDesignObjs):
        HWBaseboardDesignNames.append("")

    for BaseboardDesignNum in range(NumHWBaseboardDesignObjs):
        var thisHWBaseboardDesign = state.dataHWBaseboardRad.HWBaseboardDesignObject[BaseboardDesignNum]
        thisHWBaseboardDesign.designName = ""
        HWBaseboardDesignNames[BaseboardDesignNum] = thisHWBaseboardDesign.designName

    for BaseboardNum in range(NumHWBaseboards):
        var thisHWBaseboard = state.dataHWBaseboardRad.HWBaseboard[BaseboardNum]
        var HWBaseboardNumericFields = state.dataHWBaseboardRad.HWBaseboardNumericFields[BaseboardNum]

        thisHWBaseboard.Name = ""
        thisHWBaseboard.EquipType = 1

    if ErrorsFound:
        raise_error(RoutineName + cCMO_BBRadiator_Water + "Errors found getting input.")


@export
fn InitHWBaseboard(state: AnyType, BaseboardNum: Int32, ControlledZoneNum: Int32, FirstHVACIteration: Bool):
    let Constant: Float64 = 0.0062
    let Coeff: Float64 = 0.0000275
    let RoutineName: String = "BaseboardRadiatorWater:InitHWBaseboard"

    var NumHWBaseboards: Int32 = state.dataHWBaseboardRad.NumHWBaseboards
    var HWBaseboard = state.dataHWBaseboardRad.HWBaseboard[BaseboardNum]

    if state.dataHWBaseboardRad.MyOneTimeFlag:
        for _ in range(NumHWBaseboards):
            state.dataHWBaseboardRad.MyEnvrnFlag.append(True)
            state.dataHWBaseboardRad.MySizeFlag.append(True)
            state.dataHWBaseboardRad.SetLoopIndexFlag.append(True)

        state.dataHWBaseboardRad.MyOneTimeFlag = False

        for i in range(state.dataHWBaseboardRad.HWBaseboard.size()):
            var hWBB = state.dataHWBaseboardRad.HWBaseboard[i]
            hWBB.ZeroBBSourceSumHATsurf = 0.0
            hWBB.QBBRadSource = 0.0
            hWBB.QBBRadSrcAvg = 0.0
            hWBB.LastQBBRadSrc = 0.0
            hWBB.LastSysTimeElapsed = 0.0
            hWBB.LastTimeStepSys = 0.0
            hWBB.AirMassFlowRateStd = Constant + Coeff * hWBB.RatedCapacity

    if state.dataHWBaseboardRad.SetLoopIndexFlag[BaseboardNum]:
        if True:
            scan_plant_loops_for_object(state, HWBaseboard.Name, HWBaseboard.EquipType, HWBaseboard.plantLoc)
            state.dataHWBaseboardRad.SetLoopIndexFlag[BaseboardNum] = False

    if (
        not state.dataGlobal.SysSizingCalc
        and state.dataHWBaseboardRad.MySizeFlag[BaseboardNum]
        and not state.dataHWBaseboardRad.SetLoopIndexFlag[BaseboardNum]
    ):
        SizeHWBaseboard(state, BaseboardNum)
        state.dataHWBaseboardRad.MySizeFlag[BaseboardNum] = False

    if state.dataGlobal.BeginEnvrnFlag and state.dataHWBaseboardRad.MyEnvrnFlag[BaseboardNum]:
        var WaterInletNode: Int32 = HWBaseboard.WaterInletNode

        var rho: Float64 = HWBaseboard.plantLoc.loop.glycol.getDensity(state, 60.0, RoutineName)
        HWBaseboard.WaterMassFlowRateMax = rho * HWBaseboard.WaterVolFlowRateMax

        init_component_nodes(state, 0.0, HWBaseboard.WaterMassFlowRateMax, HWBaseboard.WaterInletNode, HWBaseboard.WaterOutletNode)

        state.dataLoopNodes.Node[WaterInletNode].Temp = 60.0
        var Cp: Float64 = HWBaseboard.plantLoc.loop.glycol.getSpecificHeat(state, state.dataLoopNodes.Node[WaterInletNode].Temp, RoutineName)

        state.dataLoopNodes.Node[WaterInletNode].Enthalpy = Cp * state.dataLoopNodes.Node[WaterInletNode].Temp
        state.dataLoopNodes.Node[WaterInletNode].Quality = 0.0
        state.dataLoopNodes.Node[WaterInletNode].Press = 0.0
        state.dataLoopNodes.Node[WaterInletNode].HumRat = 0.0

        HWBaseboard.ZeroBBSourceSumHATsurf = 0.0
        HWBaseboard.QBBRadSource = 0.0
        HWBaseboard.QBBRadSrcAvg = 0.0
        HWBaseboard.LastQBBRadSrc = 0.0
        HWBaseboard.LastSysTimeElapsed = 0.0
        HWBaseboard.LastTimeStepSys = 0.0

        state.dataHWBaseboardRad.MyEnvrnFlag[BaseboardNum] = False

    if not state.dataGlobal.BeginEnvrnFlag:
        state.dataHWBaseboardRad.MyEnvrnFlag[BaseboardNum] = True

    if state.dataGlobal.BeginTimeStepFlag and FirstHVACIteration:
        var ZoneNum: Int32 = HWBaseboard.ZonePtr
        HWBaseboard.ZeroBBSourceSumHATsurf = state.dataHeatBal.Zone[ZoneNum].sumHATsurf(state)
        HWBaseboard.QBBRadSrcAvg = 0.0
        HWBaseboard.LastQBBRadSrc = 0.0
        HWBaseboard.LastSysTimeElapsed = 0.0
        HWBaseboard.LastTimeStepSys = 0.0

    var WaterInletNode: Int32 = HWBaseboard.WaterInletNode
    var ZoneNode: Int32 = state.dataZoneEquip.ZoneEquipConfig[ControlledZoneNum].ZoneNode
    HWBaseboard.WaterMassFlowRate = state.dataLoopNodes.Node[WaterInletNode].MassFlowRate
    HWBaseboard.WaterInletTemp = state.dataLoopNodes.Node[WaterInletNode].Temp
    HWBaseboard.WaterInletEnthalpy = state.dataLoopNodes.Node[WaterInletNode].Enthalpy
    HWBaseboard.AirInletTemp = state.dataLoopNodes.Node[ZoneNode].Temp
    HWBaseboard.AirInletHumRat = state.dataLoopNodes.Node[ZoneNode].HumRat

    HWBaseboard.TotPower = 0.0
    HWBaseboard.Power = 0.0
    HWBaseboard.ConvPower = 0.0
    HWBaseboard.RadPower = 0.0
    HWBaseboard.TotEnergy = 0.0
    HWBaseboard.Energy = 0.0
    HWBaseboard.ConvEnergy = 0.0
    HWBaseboard.RadEnergy = 0.0


fn SizeHWBaseboard(state: AnyType, BaseboardNum: Int32):
    let AirInletTempStd: Float64 = 18.0
    let CPAirStd: Float64 = 1005.0
    let Constant: Float64 = 0.0062
    let Coeff: Float64 = 0.0000275
    let RoutineName: String = "SizeHWBaseboard"
    let RoutineNameFull: String = "BaseboardRadiatorWater:SizeHWBaseboard"

    var PltSizHeatNum: Int32 = 0
    var DesCoilLoad: Float64 = 0.0
    var ErrorsFound: Bool = False
    var WaterVolFlowRateMaxDes: Float64 = 0.0
    var WaterVolFlowRateMaxUser: Float64 = 0.0
    var RatedCapacityDes: Float64 = 0.0

    var hWBaseboard = state.dataHWBaseboardRad.HWBaseboard[BaseboardNum]

    if state.dataSize.CurZoneEqNum > 0:
        pass

    PltSizHeatNum = 0

    if PltSizHeatNum > 0:
        if state.dataSize.CurZoneEqNum > 0:
            pass
    else:
        if hWBaseboard.WaterVolFlowRateMax == -999:
            raise_error("SizeHWBaseboard: Autosizing requires a heating loop Sizing:Plant object")

        hWBaseboard.RatedCapacity = RatedCapacityDes
        DesCoilLoad = RatedCapacityDes

        if DesCoilLoad >= 100.0:
            var WaterMassFlowRateStd: Float64 = hWBaseboard.WaterMassFlowRateStd
            var AirMassFlowRate: Float64 = Constant + Coeff * DesCoilLoad
            var Cp: Float64 = hWBaseboard.plantLoc.loop.glycol.getSpecificHeat(state, hWBaseboard.WaterTempAvg, RoutineName)
            var WaterInletTempStd: Float64 = (DesCoilLoad / (2.0 * WaterMassFlowRateStd * Cp)) + hWBaseboard.WaterTempAvg
            var WaterOutletTempStd: Float64 = abs((2.0 * hWBaseboard.WaterTempAvg) - WaterInletTempStd)
            var AirOutletTempStd: Float64 = (DesCoilLoad / (AirMassFlowRate * CPAirStd)) + AirInletTempStd
            hWBaseboard.AirMassFlowRateStd = AirMassFlowRate

            if AirOutletTempStd >= WaterInletTempStd:
                AirOutletTempStd = WaterInletTempStd - 0.01
            if AirInletTempStd >= WaterOutletTempStd:
                WaterOutletTempStd = AirInletTempStd + 0.01

            var DeltaT1: Float64 = WaterInletTempStd - AirOutletTempStd
            var DeltaT2: Float64 = WaterOutletTempStd - AirInletTempStd
            var LMTD: Float64 = (DeltaT1 - DeltaT2) / log(DeltaT1 / DeltaT2)
            hWBaseboard.UA = DesCoilLoad / LMTD
        else:
            hWBaseboard.UA = 0.0

        report_sizer_output(state, cCMO_BBRadiator_Water, hWBaseboard.Name, "U-Factor times Area [W/C]", hWBaseboard.UA)

    register_plant_comp_design_flow(state, hWBaseboard.WaterInletNode, hWBaseboard.WaterVolFlowRateMax)

    if ErrorsFound:
        raise_error("Preceding sizing errors cause program termination")


fn CalcHWBaseboard(state: AnyType, BaseboardNum: Int32) -> Float64:
    let MinFrac: Float64 = 0.0005
    let RoutineName: String = "CalcHWBaseboard"

    var hWBaseboard = state.dataHWBaseboardRad.HWBaseboard[BaseboardNum]

    var ZoneNum: Int32 = hWBaseboard.ZonePtr
    var QZnReq: Float64 = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNum].RemainingOutputReqToHeatSP
    var AirInletTemp: Float64 = hWBaseboard.AirInletTemp
    var WaterInletTemp: Float64 = hWBaseboard.WaterInletTemp
    var WaterMassFlowRate: Float64 = state.dataLoopNodes.Node[hWBaseboard.WaterInletNode].MassFlowRate

    var LoadMet: Float64 = 0.0

    if (
        QZnReq > 100.0
        and not state.dataZoneEnergyDemand.CurDeadBandOrSetback[ZoneNum]
        and (hWBaseboard.availSched is not None and get_schedule_value(hWBaseboard.availSched) > 0)
        and (WaterMassFlowRate > 0.0)
    ):

        var HWBaseboardDesignDataObject = state.dataHWBaseboardRad.HWBaseboardDesignObject[hWBaseboard.DesignObjectPtr]

        var AirMassFlowRate: Float64 = hWBaseboard.AirMassFlowRateStd * (WaterMassFlowRate / hWBaseboard.WaterMassFlowRateMax)
        var CapacitanceAir: Float64 = psychrometrics_psy_cp_air_fn_w(hWBaseboard.AirInletHumRat) * AirMassFlowRate
        var Cp: Float64 = hWBaseboard.plantLoc.loop.glycol.getSpecificHeat(state, WaterInletTemp, RoutineName)

        var CapacitanceWater: Float64 = Cp * WaterMassFlowRate
        var CapacitanceMax: Float64 = max(CapacitanceAir, CapacitanceWater)
        var CapacitanceMin: Float64 = min(CapacitanceAir, CapacitanceWater)
        var CapacityRatio: Float64 = CapacitanceMin / CapacitanceMax if CapacitanceMax > 0 else 0.0
        var NTU: Float64 = hWBaseboard.UA / CapacitanceMin if CapacitanceMin > 0 else 0.0

        var AA: Float64 = -CapacityRatio * (NTU ** 0.78)
        var BB: Float64 = 0.0
        if AA >= -20.0:
            BB = exp(AA)

        var CC: Float64 = (1.0 / CapacityRatio) * (NTU ** 0.22) * (BB - 1.0) if CapacityRatio > 0 else 0.0
        var Effectiveness: Float64 = 1.0
        if CC >= -20.0:
            Effectiveness = 1.0 - exp(CC)

        var AirOutletTemp: Float64 = AirInletTemp + Effectiveness * CapacitanceMin * (WaterInletTemp - AirInletTemp) / CapacitanceAir if CapacitanceAir > 0 else AirInletTemp
        var WaterOutletTemp: Float64 = WaterInletTemp - CapacitanceAir * (AirOutletTemp - AirInletTemp) / CapacitanceWater if CapacitanceWater > 0 else WaterInletTemp
        var BBHeat: Float64 = CapacitanceWater * (WaterInletTemp - WaterOutletTemp)
        var RadHeat: Float64 = BBHeat * HWBaseboardDesignDataObject.FracRadiant
        hWBaseboard.QBBRadSource = RadHeat

        if HWBaseboardDesignDataObject.FracRadiant <= MinFrac:
            LoadMet = BBHeat
        else:
            DistributeBBRadGains(state)
            calc_heat_balance_outside_surf(state, ZoneNum)
            calc_heat_balance_inside_surf(state, ZoneNum)
            LoadMet = (
                (state.dataHeatBal.Zone[ZoneNum].sumHATsurf(state) - hWBaseboard.ZeroBBSourceSumHATsurf)
                + (BBHeat * hWBaseboard.FracConvect)
                + (RadHeat * HWBaseboardDesignDataObject.FracDistribPerson)
            )

        hWBaseboard.WaterOutletEnthalpy = hWBaseboard.WaterInletEnthalpy - BBHeat / WaterMassFlowRate if WaterMassFlowRate > 0 else hWBaseboard.WaterInletEnthalpy
    else:
        var AirOutletTemp: Float64 = AirInletTemp
        var WaterOutletTemp: Float64 = WaterInletTemp
        var BBHeat: Float64 = 0.0
        LoadMet = 0.0
        var RadHeat: Float64 = 0.0
        WaterMassFlowRate = 0.0
        var AirMassFlowRate: Float64 = 0.0
        hWBaseboard.QBBRadSource = 0.0
        hWBaseboard.WaterOutletEnthalpy = hWBaseboard.WaterInletEnthalpy
        set_actuated_branch_flow_rate(state, WaterMassFlowRate, hWBaseboard.WaterInletNode, hWBaseboard.plantLoc, False)

        hWBaseboard.WaterOutletTemp = WaterOutletTemp
        hWBaseboard.AirOutletTemp = AirOutletTemp
        hWBaseboard.WaterMassFlowRate = WaterMassFlowRate
        hWBaseboard.AirMassFlowRate = AirMassFlowRate
        hWBaseboard.TotPower = LoadMet
        hWBaseboard.Power = BBHeat
        hWBaseboard.ConvPower = BBHeat - RadHeat
        hWBaseboard.RadPower = RadHeat

    return LoadMet


@export
fn UpdateHWBaseboard(state: AnyType, BaseboardNum: Int32):
    if state.dataGlobal.BeginEnvrnFlag and state.dataHWBaseboardRad.MyEnvrnFlag2:
        state.dataHWBaseboardRad.Iter = 0
        state.dataHWBaseboardRad.MyEnvrnFlag2 = False
    if not state.dataGlobal.BeginEnvrnFlag:
        state.dataHWBaseboardRad.MyEnvrnFlag2 = True

    var thisHWBB = state.dataHWBaseboardRad.HWBaseboard[BaseboardNum]

    if thisHWBB.LastSysTimeElapsed == state.dataHVACGlobal.SysTimeElapsed:
        thisHWBB.QBBRadSrcAvg -= thisHWBB.LastQBBRadSrc * thisHWBB.LastTimeStepSys / state.dataGlobal.TimeStepZone

    thisHWBB.QBBRadSrcAvg += thisHWBB.QBBRadSource * state.dataHVACGlobal.TimeStepSys / state.dataGlobal.TimeStepZone

    thisHWBB.LastQBBRadSrc = thisHWBB.QBBRadSource
    thisHWBB.LastSysTimeElapsed = state.dataHVACGlobal.SysTimeElapsed
    thisHWBB.LastTimeStepSys = state.dataHVACGlobal.TimeStepSys

    var WaterInletNode: Int32 = thisHWBB.WaterInletNode
    var WaterOutletNode: Int32 = thisHWBB.WaterOutletNode

    safe_copy_plant_node(state, WaterInletNode, WaterOutletNode)
    state.dataLoopNodes.Node[WaterOutletNode].Temp = thisHWBB.WaterOutletTemp
    state.dataLoopNodes.Node[WaterOutletNode].Enthalpy = thisHWBB.WaterOutletEnthalpy


fn UpdateBBRadSourceValAvg(state: AnyType) -> Bool:
    var HWBaseboardSysOn: Bool = False

    if state.dataHWBaseboardRad.NumHWBaseboards == 0:
        return HWBaseboardSysOn

    for i in range(state.dataHWBaseboardRad.HWBaseboard.size()):
        var thisHWBaseboard = state.dataHWBaseboardRad.HWBaseboard[i]
        thisHWBaseboard.QBBRadSource = thisHWBaseboard.QBBRadSrcAvg
        if thisHWBaseboard.QBBRadSrcAvg != 0.0:
            HWBaseboardSysOn = True

    DistributeBBRadGains(state)
    return HWBaseboardSysOn


fn DistributeBBRadGains(state: AnyType):
    let SmallestArea: Float64 = 0.001
    let MaxRadHeatFlux: Float64 = 5000.0

    for i in range(state.dataHWBaseboardRad.HWBaseboard.size()):
        var thisHWBB = state.dataHWBaseboardRad.HWBaseboard[i]
        for radSurfNum in range(thisHWBB.TotSurfToDistrib):
            var surfNum: Int32 = thisHWBB.SurfacePtr[radSurfNum]
            if surfNum >= 0 and surfNum < state.dataHeatBalFanSys.surfQRadFromHVAC.size():
                state.dataHeatBalFanSys.surfQRadFromHVAC[surfNum].HWBaseboard = 0.0

    for ZoneNum in range(state.dataHeatBalFanSys.ZoneQHWBaseboardToPerson.size()):
        state.dataHeatBalFanSys.ZoneQHWBaseboardToPerson[ZoneNum] = 0.0

    for i in range(state.dataHWBaseboardRad.HWBaseboard.size()):
        var thisHWBB = state.dataHWBaseboardRad.HWBaseboard[i]
        var HWBaseboardDesignDataObject = state.dataHWBaseboardRad.HWBaseboardDesignObject[thisHWBB.DesignObjectPtr]
        var ZoneNum: Int32 = thisHWBB.ZonePtr
        if ZoneNum <= 0:
            continue

        state.dataHeatBalFanSys.ZoneQHWBaseboardToPerson[ZoneNum] += (
            thisHWBB.QBBRadSource * HWBaseboardDesignDataObject.FracDistribPerson
        )

        for RadSurfNum in range(thisHWBB.TotSurfToDistrib):
            var SurfNum: Int32 = thisHWBB.SurfacePtr[RadSurfNum]
            if state.dataSurface.Surface[SurfNum].Area > SmallestArea:
                var ThisSurfIntensity: Float64 = (
                    thisHWBB.QBBRadSource * thisHWBB.FracDistribToSurf[RadSurfNum] / state.dataSurface.Surface[SurfNum].Area
                )
                state.dataHeatBalFanSys.surfQRadFromHVAC[SurfNum].HWBaseboard += ThisSurfIntensity
                if ThisSurfIntensity > MaxRadHeatFlux:
                    raise_error("DistributeBBRadGains: excessive thermal radiation heat flux intensity detected")
            else:
                raise_error("DistributeBBRadGains: surface not large enough to receive thermal radiation heat flux")


@export
fn ReportHWBaseboard(state: AnyType, BaseboardNum: Int32):
    var thisHWBB = state.dataHWBaseboardRad.HWBaseboard[BaseboardNum]
    let timeStepSysSec: Float64 = state.dataHVACGlobal.TimeStepSysSec

    thisHWBB.TotEnergy = thisHWBB.TotPower * timeStepSysSec
    thisHWBB.Energy = thisHWBB.Power * timeStepSysSec
    thisHWBB.ConvEnergy = thisHWBB.ConvPower * timeStepSysSec
    thisHWBB.RadEnergy = thisHWBB.RadPower * timeStepSysSec


@export
fn UpdateHWBaseboardPlantConnection(
    state: AnyType,
    BaseboardTypeNum: Int32,
    BaseboardName: StringRef,
    EquipFlowCtrl: Int32,
    LoopNum: Int32,
    LoopSide: Int32,
    FirstHVACIteration: Bool,
) -> Tuple[Int32, Bool]:
    var CompIndex: Int32 = 0
    var InitLoopEquip: Bool = False
    var NumHWBaseboards: Int32 = state.dataHWBaseboardRad.NumHWBaseboards

    if CompIndex == 0:
        var BaseboardNum: Int32 = find_item_in_list(BaseboardName, state.dataHWBaseboardRad.HWBaseboard)
        if BaseboardNum == -1:
            raise_error("UpdateHWBaseboardPlantConnection: Specified baseboard not valid")
        CompIndex = BaseboardNum
    else:
        var BaseboardNum: Int32 = CompIndex
        if BaseboardNum >= NumHWBaseboards or BaseboardNum < 0:
            raise_error("UpdateHWBaseboardPlantConnection: Invalid CompIndex passed")
        if state.dataGlobal.KickOffSimulation:
            if String(BaseboardName) != state.dataHWBaseboardRad.HWBaseboard[BaseboardNum].Name:
                raise_error("UpdateHWBaseboardPlantConnection: Invalid CompIndex passed")

    if InitLoopEquip:
        return CompIndex, InitLoopEquip

    var thisHWBaseboard = state.dataHWBaseboardRad.HWBaseboard[CompIndex]
    pull_comp_interconnect_trigger(
        state,
        thisHWBaseboard.plantLoc,
        thisHWBaseboard.BBLoadReSimIndex,
        thisHWBaseboard.plantLoc,
        0,
        thisHWBaseboard.Power,
    )

    pull_comp_interconnect_trigger(
        state,
        thisHWBaseboard.plantLoc,
        thisHWBaseboard.BBMassFlowReSimIndex,
        thisHWBaseboard.plantLoc,
        1,
        thisHWBaseboard.WaterMassFlowRate,
    )

    pull_comp_interconnect_trigger(
        state,
        thisHWBaseboard.plantLoc,
        thisHWBaseboard.BBInletTempFlowReSimIndex,
        thisHWBaseboard.plantLoc,
        2,
        thisHWBaseboard.WaterOutletTemp,
    )

    return CompIndex, InitLoopEquip


fn find_item_in_list(name: StringRef, items: List[HWBaseboardParams]) -> Int32:
    for i in range(items.size()):
        if items[i].Name == String(name):
            return i
    return -1


fn raise_error(msg: String):
    pass


fn init_component_nodes(state: AnyType, min_flow: Float64, max_flow: Float64, inlet_node: Int32, outlet_node: Int32):
    pass


fn scan_plant_loops_for_object(state: AnyType, name: String, equip_type: Int32, plant_loc: AnyType):
    pass


fn report_sizer_output(state: AnyType, comp_type: String, comp_name: String, desc: String, value: Float64):
    pass


fn register_plant_comp_design_flow(state: AnyType, inlet_node: Int32, volume_flow_rate: Float64):
    pass


fn psychrometrics_psy_cp_air_fn_w(hum_rat: Float64) -> Float64:
    return 1005.0


fn safe_copy_plant_node(state: AnyType, from_node: Int32, to_node: Int32):
    pass


fn set_actuated_branch_flow_rate(state: AnyType, flow_rate: Float64, inlet_node: Int32, plant_loc: AnyType, available: Bool):
    pass


fn calc_heat_balance_outside_surf(state: AnyType, zone_num: Int32):
    pass


fn calc_heat_balance_inside_surf(state: AnyType, zone_num: Int32):
    pass


fn pull_comp_interconnect_trigger(state: AnyType, plant_loc_from: AnyType, index: Int32, plant_loc_to: AnyType, criteria_type: Int32, value: Float64):
    pass


fn control_comp_output(state: AnyType, *args, **kwargs):
    pass


fn get_schedule_value(sched: AnyType) -> Float64:
    return 1.0
