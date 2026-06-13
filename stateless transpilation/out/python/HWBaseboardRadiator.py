# EnergyPlus, Copyright (c) 1996-present, The Board of Trustees of the University of Illinois,
# The Regents of the University of California, through Lawrence Berkeley National Laboratory
# (subject to receipt of any required approvals from the U.S. Dept. of Energy), Oak Ridge
# National Laboratory, managed by UT-Battelle, Alliance for Energy Innovation, LLC, and other
# contributors. All rights reserved.

from dataclasses import dataclass, field
from typing import Protocol, Optional, List
import math

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


cCMO_BBRadiator_Water = "ZoneHVAC:Baseboard:RadiantConvective:Water"
cCMO_BBRadiator_Water_Design = "ZoneHVAC:Baseboard:RadiantConvective:Water:Design"


@dataclass
class HWBaseboardParams:
    Name: str = ""
    EquipType: int = None  # DataPlant.PlantEquipmentType.Invalid
    designObjectName: str = ""
    DesignObjectPtr: int = 0
    SurfacePtr: List[int] = field(default_factory=list)
    ZonePtr: int = 0
    availSched: Optional[object] = None
    WaterInletNode: int = 0
    WaterOutletNode: int = 0
    TotSurfToDistrib: int = 0
    ControlCompTypeNum: int = 0
    CompErrIndex: int = 0
    AirMassFlowRate: float = 0.0
    AirMassFlowRateStd: float = 0.0
    WaterTempAvg: float = 0.0
    RatedCapacity: float = 0.0
    UA: float = 0.0
    WaterMassFlowRate: float = 0.0
    WaterMassFlowRateMax: float = 0.0
    WaterMassFlowRateStd: float = 0.0
    WaterVolFlowRateMax: float = 0.0
    WaterInletTempStd: float = 0.0
    WaterInletTemp: float = 0.0
    WaterInletEnthalpy: float = 0.0
    WaterOutletTempStd: float = 0.0
    WaterOutletTemp: float = 0.0
    WaterOutletEnthalpy: float = 0.0
    AirInletTempStd: float = 0.0
    AirInletTemp: float = 0.0
    AirOutletTemp: float = 0.0
    AirInletHumRat: float = 0.0
    AirOutletTempStd: float = 0.0
    FracConvect: float = 0.0
    FracDistribToSurf: List[float] = field(default_factory=list)
    TotPower: float = 0.0
    Power: float = 0.0
    ConvPower: float = 0.0
    RadPower: float = 0.0
    TotEnergy: float = 0.0
    Energy: float = 0.0
    ConvEnergy: float = 0.0
    RadEnergy: float = 0.0
    plantLoc: Optional[object] = None
    BBLoadReSimIndex: int = 0
    BBMassFlowReSimIndex: int = 0
    BBInletTempFlowReSimIndex: int = 0
    HeatingCapMethod: int = 0
    ScaledHeatingCapacity: float = 0.0
    ZeroBBSourceSumHATsurf: float = 0.0
    QBBRadSource: float = 0.0
    QBBRadSrcAvg: float = 0.0
    LastSysTimeElapsed: float = 0.0
    LastTimeStepSys: float = 0.0
    LastQBBRadSrc: float = 0.0


@dataclass
class HWBaseboardDesignData(HWBaseboardParams):
    designName: str = ""
    HeatingCapMethod: int = None  # DataSizing.DesignSizingType.Invalid
    ScaledHeatingCapacity: float = 0.0
    Offset: float = 0.0
    FracRadiant: float = 0.0
    FracDistribPerson: float = 0.0


@dataclass
class HWBaseboardNumericFieldData:
    FieldNames: List[str] = field(default_factory=list)


@dataclass
class HWBaseboardDesignNumericFieldData:
    FieldNames: List[str] = field(default_factory=list)


@dataclass
class HWBaseboardRadiatorData:
    MySizeFlag: List[bool] = field(default_factory=list)
    CheckEquipName: List[bool] = field(default_factory=list)
    SetLoopIndexFlag: List[bool] = field(default_factory=list)
    NumHWBaseboards: int = 0
    NumHWBaseboardDesignObjs: int = 0
    HWBaseboard: List[HWBaseboardParams] = field(default_factory=list)
    HWBaseboardDesignObject: List[HWBaseboardDesignData] = field(default_factory=list)
    HWBaseboardNumericFields: List[HWBaseboardNumericFieldData] = field(default_factory=list)
    GetInputFlag: bool = True
    MyOneTimeFlag: bool = True
    Iter: int = 0
    MyEnvrnFlag2: bool = True
    MyEnvrnFlag: List[bool] = field(default_factory=list)

    def clear_state(self):
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


def SimHWBaseboard(state, EquipName: str, ControlledZoneNum: int, FirstHVACIteration: bool) -> tuple:
    BaseboardNum = 0
    QZnReq = 0.0
    MaxWaterFlow = 0.0
    MinWaterFlow = 0.0
    PowerMet = 0.0
    CompIndex = 0

    if state.dataHWBaseboardRad.GetInputFlag:
        GetHWBaseboardInput(state)
        state.dataHWBaseboardRad.GetInputFlag = False

    NumHWBaseboards = state.dataHWBaseboardRad.NumHWBaseboards

    if CompIndex == 0:
        BaseboardNum = find_item_in_list(EquipName, state.dataHWBaseboardRad.HWBaseboard)
        if BaseboardNum == -1:
            raise RuntimeError(f"SimHWBaseboard: Unit not found={EquipName}")
        CompIndex = BaseboardNum
    else:
        BaseboardNum = CompIndex
        if BaseboardNum >= NumHWBaseboards or BaseboardNum < 0:
            raise RuntimeError(
                f"SimHWBaseboard: Invalid CompIndex passed={BaseboardNum}, "
                f"Number of Units={NumHWBaseboards}, Entered Unit name={EquipName}"
            )
        if state.dataHWBaseboardRad.CheckEquipName[BaseboardNum]:
            if EquipName != state.dataHWBaseboardRad.HWBaseboard[BaseboardNum].Name:
                raise RuntimeError(
                    f"SimHWBaseboard: Invalid CompIndex passed={BaseboardNum}, "
                    f"Unit name={EquipName}, "
                    f"stored Unit Name for that index="
                    f"{state.dataHWBaseboardRad.HWBaseboard[BaseboardNum].Name}"
                )
            state.dataHWBaseboardRad.CheckEquipName[BaseboardNum] = False

    if CompIndex >= 0:
        HWBaseboard = state.dataHWBaseboardRad.HWBaseboard[BaseboardNum]
        HWBaseboardDesignDataObject = state.dataHWBaseboardRad.HWBaseboardDesignObject[
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

        if HWBaseboard.EquipType == 1:  # Baseboard_Rad_Conv_Water
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
                None,
                None,
                None,
                None,
                None,
                HWBaseboard.plantLoc,
            )
        else:
            raise RuntimeError(
                f"SimBaseboard: Errors in Baseboard={HWBaseboard.Name}, "
                f"Invalid or unimplemented equipment type={HWBaseboard.EquipType}"
            )

        PowerMet = HWBaseboard.TotPower

        UpdateHWBaseboard(state, BaseboardNum)
        ReportHWBaseboard(state, BaseboardNum)
    else:
        raise RuntimeError(f"SimHWBaseboard: Unit not found={EquipName}")

    return PowerMet, CompIndex


def GetHWBaseboardInput(state):
    RoutineName = "GetHWBaseboardInput:"
    routineName = "GetHWBaseboardInput"

    MaxFraction = 1.0
    MinFraction = 0.0
    MaxWaterTempAvg = 150.0
    MinWaterTempAvg = 20.0
    HighWaterMassFlowRate = 10.0
    LowWaterMassFlowRate = 0.00001
    MaxWaterFlowRate = 10.0
    MinWaterFlowRate = 0.00001
    WaterMassFlowDefault = 0.063
    MinDistribSurfaces = 1
    iHeatCAPMAlphaNum = 2
    iHeatDesignCapacityNumericNum = 3
    iHeatCapacityPerFloorAreaNumericNum = 1
    iHeatFracOfAutosizedCapacityNumericNum = 2

    ErrorsFound = False

    NumHWBaseboards = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, cCMO_BBRadiator_Water
    )
    NumHWBaseboardDesignObjs = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, cCMO_BBRadiator_Water_Design
    )

    state.dataHWBaseboardRad.NumHWBaseboards = NumHWBaseboards
    state.dataHWBaseboardRad.NumHWBaseboardDesignObjs = NumHWBaseboardDesignObjs

    state.dataHWBaseboardRad.HWBaseboard = [HWBaseboardParams() for _ in range(NumHWBaseboards)]
    state.dataHWBaseboardRad.HWBaseboardDesignObject = [
        HWBaseboardDesignData() for _ in range(NumHWBaseboardDesignObjs)
    ]
    state.dataHWBaseboardRad.CheckEquipName = [True] * NumHWBaseboards
    state.dataHWBaseboardRad.HWBaseboardNumericFields = [
        HWBaseboardNumericFieldData() for _ in range(NumHWBaseboards)
    ]
    HWBaseboardDesignNames = [""] * NumHWBaseboardDesignObjs

    for BaseboardDesignNum in range(NumHWBaseboardDesignObjs):
        thisHWBaseboardDesign = state.dataHWBaseboardRad.HWBaseboardDesignObject[BaseboardDesignNum]

        cAlphaArgs, NumAlphas, rNumericArgs, NumNumbers, IOStat = (
            state.dataInputProcessing.inputProcessor.getObjectItem(
                state,
                cCMO_BBRadiator_Water_Design,
                BaseboardDesignNum,
            )
        )

        thisHWBaseboardDesign.designName = cAlphaArgs[0]
        HWBaseboardDesignNames[BaseboardDesignNum] = thisHWBaseboardDesign.designName

        thisHWBaseboardDesign.HeatingCapMethod = get_enum_value_heating_cap_method(cAlphaArgs[iHeatCAPMAlphaNum])

        if thisHWBaseboardDesign.HeatingCapMethod == 1:  # CapacityPerFloorArea
            if NumNumbers > iHeatCapacityPerFloorAreaNumericNum:
                thisHWBaseboardDesign.ScaledHeatingCapacity = rNumericArgs[
                    iHeatCapacityPerFloorAreaNumericNum
                ]
                if thisHWBaseboardDesign.ScaledHeatingCapacity <= 0.0:
                    raise RuntimeError(
                        f"GetHWBaseboardInput: Illegal heating capacity "
                        f"{thisHWBaseboardDesign.ScaledHeatingCapacity}"
                    )
            else:
                raise RuntimeError("GetHWBaseboardInput: Blank field not allowed for capacity per floor area")
        elif thisHWBaseboardDesign.HeatingCapMethod == 2:  # FractionOfAutosizedHeatingCapacity
            if NumNumbers > iHeatFracOfAutosizedCapacityNumericNum:
                thisHWBaseboardDesign.ScaledHeatingCapacity = rNumericArgs[
                    iHeatFracOfAutosizedCapacityNumericNum
                ]
                if thisHWBaseboardDesign.ScaledHeatingCapacity < 0.0:
                    raise RuntimeError(
                        f"GetHWBaseboardInput: Illegal fraction "
                        f"{thisHWBaseboardDesign.ScaledHeatingCapacity}"
                    )
            else:
                raise RuntimeError(
                    "GetHWBaseboardInput: Blank field not allowed for fraction of autosized capacity"
                )

        thisHWBaseboardDesign.Offset = rNumericArgs[3] if NumNumbers > 3 else 0.001
        if thisHWBaseboardDesign.Offset <= 0.0:
            thisHWBaseboardDesign.Offset = 0.001

        thisHWBaseboardDesign.FracRadiant = rNumericArgs[4] if NumNumbers > 4 else 0.0
        if thisHWBaseboardDesign.FracRadiant < MinFraction:
            thisHWBaseboardDesign.FracRadiant = MinFraction
        if thisHWBaseboardDesign.FracRadiant > MaxFraction:
            thisHWBaseboardDesign.FracRadiant = MaxFraction

        thisHWBaseboardDesign.FracDistribPerson = rNumericArgs[5] if NumNumbers > 5 else 0.0
        if thisHWBaseboardDesign.FracDistribPerson < MinFraction:
            thisHWBaseboardDesign.FracDistribPerson = MinFraction
        if thisHWBaseboardDesign.FracDistribPerson > MaxFraction:
            thisHWBaseboardDesign.FracDistribPerson = MaxFraction

    for BaseboardNum in range(NumHWBaseboards):
        thisHWBaseboard = state.dataHWBaseboardRad.HWBaseboard[BaseboardNum]
        HWBaseboardNumericFields = state.dataHWBaseboardRad.HWBaseboardNumericFields[BaseboardNum]

        cAlphaArgs, NumAlphas, rNumericArgs, NumNumbers, IOStat = (
            state.dataInputProcessing.inputProcessor.getObjectItem(
                state,
                cCMO_BBRadiator_Water,
                BaseboardNum,
            )
        )

        HWBaseboardNumericFields.FieldNames = cAlphaArgs if NumAlphas > 0 else []

        thisHWBaseboard.Name = cAlphaArgs[0]
        thisHWBaseboard.EquipType = 1  # Baseboard_Rad_Conv_Water

        set_design_object_name_and_pointer(
            state,
            thisHWBaseboard,
            cAlphaArgs[2] if len(cAlphaArgs) > 2 else "",
            HWBaseboardDesignNames,
        )

        HWBaseboardDesignDataObject = state.dataHWBaseboardRad.HWBaseboardDesignObject[
            thisHWBaseboard.DesignObjectPtr
        ]

        thisHWBaseboard.availSched = get_schedule(state, cAlphaArgs[3] if len(cAlphaArgs) > 3 else "")

        thisHWBaseboard.WaterInletNode = get_only_single_node(state, cAlphaArgs[4] if len(cAlphaArgs) > 4 else "")
        thisHWBaseboard.WaterOutletNode = get_only_single_node(state, cAlphaArgs[5] if len(cAlphaArgs) > 5 else "")

        thisHWBaseboard.WaterTempAvg = rNumericArgs[0] if NumNumbers > 0 else 0.0
        if thisHWBaseboard.WaterTempAvg > MaxWaterTempAvg + 0.001:
            thisHWBaseboard.WaterTempAvg = MaxWaterTempAvg
        elif thisHWBaseboard.WaterTempAvg < MinWaterTempAvg - 0.001:
            thisHWBaseboard.WaterTempAvg = MinWaterTempAvg

        thisHWBaseboard.WaterMassFlowRateStd = rNumericArgs[1] if NumNumbers > 1 else 0.0
        if (
            thisHWBaseboard.WaterMassFlowRateStd < LowWaterMassFlowRate - 0.0001
            or thisHWBaseboard.WaterMassFlowRateStd > HighWaterMassFlowRate + 0.0001
        ):
            thisHWBaseboard.WaterMassFlowRateStd = WaterMassFlowDefault

        thisHWBaseboard.HeatingCapMethod = HWBaseboardDesignDataObject.HeatingCapMethod
        if thisHWBaseboard.HeatingCapMethod == 0:  # HeatingDesignCapacity
            thisHWBaseboard.ScaledHeatingCapacity = rNumericArgs[iHeatDesignCapacityNumericNum] if NumNumbers > iHeatDesignCapacityNumericNum else 0.0
        elif thisHWBaseboard.HeatingCapMethod == 1:  # CapacityPerFloorArea
            thisHWBaseboard.ScaledHeatingCapacity = HWBaseboardDesignDataObject.ScaledHeatingCapacity
        elif thisHWBaseboard.HeatingCapMethod == 2:  # FractionOfAutosizedHeatingCapacity
            thisHWBaseboard.ScaledHeatingCapacity = HWBaseboardDesignDataObject.ScaledHeatingCapacity

        thisHWBaseboard.WaterVolFlowRateMax = rNumericArgs[3] if NumNumbers > 3 else 0.0
        if abs(thisHWBaseboard.WaterVolFlowRateMax) <= MinWaterFlowRate:
            thisHWBaseboard.WaterVolFlowRateMax = MinWaterFlowRate
        elif thisHWBaseboard.WaterVolFlowRateMax > MaxWaterFlowRate:
            thisHWBaseboard.WaterVolFlowRateMax = MaxWaterFlowRate

        if HWBaseboardDesignDataObject.FracRadiant > MaxFraction:
            HWBaseboardDesignDataObject.FracRadiant = MaxFraction
            thisHWBaseboard.FracConvect = 0.0
        else:
            thisHWBaseboard.FracConvect = 1.0 - HWBaseboardDesignDataObject.FracRadiant

        thisHWBaseboard.TotSurfToDistrib = NumNumbers - 4
        if thisHWBaseboard.TotSurfToDistrib < MinDistribSurfaces and HWBaseboardDesignDataObject.FracRadiant > MinFraction:
            ErrorsFound = True
            thisHWBaseboard.TotSurfToDistrib = 0

        thisHWBaseboard.SurfacePtr = [0] * thisHWBaseboard.TotSurfToDistrib
        thisHWBaseboard.FracDistribToSurf = [0.0] * thisHWBaseboard.TotSurfToDistrib

        thisHWBaseboard.ZonePtr = get_zone_equip_controlled_zone_num(state, thisHWBaseboard.Name)

        AllFracsSummed = HWBaseboardDesignDataObject.FracDistribPerson
        for SurfNum in range(thisHWBaseboard.TotSurfToDistrib):
            thisHWBaseboard.SurfacePtr[SurfNum] = get_radiant_system_surface(
                state,
                cCMO_BBRadiator_Water,
                thisHWBaseboard.Name,
                thisHWBaseboard.ZonePtr,
                cAlphaArgs[SurfNum + 6] if len(cAlphaArgs) > SurfNum + 6 else "",
            )
            thisHWBaseboard.FracDistribToSurf[SurfNum] = (
                rNumericArgs[SurfNum + 4] if NumNumbers > SurfNum + 4 else 0.0
            )
            if thisHWBaseboard.FracDistribToSurf[SurfNum] > MaxFraction:
                thisHWBaseboard.TotSurfToDistrib = MaxFraction
            if thisHWBaseboard.FracDistribToSurf[SurfNum] < MinFraction:
                thisHWBaseboard.TotSurfToDistrib = MinFraction

            AllFracsSummed += thisHWBaseboard.FracDistribToSurf[SurfNum]

        if AllFracsSummed > MaxFraction + 0.01:
            ErrorsFound = True
        if AllFracsSummed < MaxFraction - 0.01 and HWBaseboardDesignDataObject.FracRadiant > MinFraction:
            pass

    if ErrorsFound:
        raise RuntimeError(f"{RoutineName}{cCMO_BBRadiator_Water}Errors found getting input.")

    for BaseboardNum in range(NumHWBaseboards):
        thisHWBaseboard = state.dataHWBaseboardRad.HWBaseboard[BaseboardNum]
        setup_output_variable(
            state,
            "Baseboard Total Heating Rate",
            "W",
            thisHWBaseboard,
            "TotPower",
            thisHWBaseboard.Name,
        )
        setup_output_variable(
            state,
            "Baseboard Convective Heating Rate",
            "W",
            thisHWBaseboard,
            "ConvPower",
            thisHWBaseboard.Name,
        )
        setup_output_variable(
            state,
            "Baseboard Radiant Heating Rate",
            "W",
            thisHWBaseboard,
            "RadPower",
            thisHWBaseboard.Name,
        )
        setup_output_variable(
            state,
            "Baseboard Total Heating Energy",
            "J",
            thisHWBaseboard,
            "TotEnergy",
            thisHWBaseboard.Name,
        )
        setup_output_variable(
            state,
            "Baseboard Convective Heating Energy",
            "J",
            thisHWBaseboard,
            "ConvEnergy",
            thisHWBaseboard.Name,
        )
        setup_output_variable(
            state,
            "Baseboard Radiant Heating Energy",
            "J",
            thisHWBaseboard,
            "RadEnergy",
            thisHWBaseboard.Name,
        )
        setup_output_variable(
            state,
            "Baseboard Hot Water Energy",
            "J",
            thisHWBaseboard,
            "Energy",
            thisHWBaseboard.Name,
        )
        setup_output_variable(
            state,
            "Baseboard Hot Water Mass Flow Rate",
            "kg/s",
            thisHWBaseboard,
            "WaterMassFlowRate",
            thisHWBaseboard.Name,
        )
        setup_output_variable(
            state,
            "Baseboard Air Mass Flow Rate",
            "kg/s",
            thisHWBaseboard,
            "AirMassFlowRate",
            thisHWBaseboard.Name,
        )
        setup_output_variable(
            state,
            "Baseboard Air Inlet Temperature",
            "C",
            thisHWBaseboard,
            "AirInletTemp",
            thisHWBaseboard.Name,
        )
        setup_output_variable(
            state,
            "Baseboard Air Outlet Temperature",
            "C",
            thisHWBaseboard,
            "AirOutletTemp",
            thisHWBaseboard.Name,
        )
        setup_output_variable(
            state,
            "Baseboard Water Inlet Temperature",
            "C",
            thisHWBaseboard,
            "WaterInletTemp",
            thisHWBaseboard.Name,
        )
        setup_output_variable(
            state,
            "Baseboard Water Outlet Temperature",
            "C",
            thisHWBaseboard,
            "WaterOutletTemp",
            thisHWBaseboard.Name,
        )


def InitHWBaseboard(state, BaseboardNum: int, ControlledZoneNum: int, FirstHVACIteration: bool):
    Constant = 0.0062
    Coeff = 0.0000275
    RoutineName = "BaseboardRadiatorWater:InitHWBaseboard"

    NumHWBaseboards = state.dataHWBaseboardRad.NumHWBaseboards
    HWBaseboard = state.dataHWBaseboardRad.HWBaseboard[BaseboardNum]

    if state.dataHWBaseboardRad.MyOneTimeFlag:
        state.dataHWBaseboardRad.MyEnvrnFlag = [True] * NumHWBaseboards
        state.dataHWBaseboardRad.MySizeFlag = [True] * NumHWBaseboards
        state.dataHWBaseboardRad.SetLoopIndexFlag = [True] * NumHWBaseboards
        state.dataHWBaseboardRad.MyOneTimeFlag = False

        for hWBB in state.dataHWBaseboardRad.HWBaseboard:
            hWBB.ZeroBBSourceSumHATsurf = 0.0
            hWBB.QBBRadSource = 0.0
            hWBB.QBBRadSrcAvg = 0.0
            hWBB.LastQBBRadSrc = 0.0
            hWBB.LastSysTimeElapsed = 0.0
            hWBB.LastTimeStepSys = 0.0
            hWBB.AirMassFlowRateStd = Constant + Coeff * hWBB.RatedCapacity

    if state.dataHWBaseboardRad.SetLoopIndexFlag[BaseboardNum]:
        if hasattr(state.dataPlnt, "PlantLoop") and state.dataPlnt.PlantLoop is not None:
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
        WaterInletNode = HWBaseboard.WaterInletNode

        rho = HWBaseboard.plantLoc.loop.glycol.getDensity(state, 60.0, RoutineName)
        HWBaseboard.WaterMassFlowRateMax = rho * HWBaseboard.WaterVolFlowRateMax

        init_component_nodes(state, 0.0, HWBaseboard.WaterMassFlowRateMax, HWBaseboard.WaterInletNode, HWBaseboard.WaterOutletNode)

        state.dataLoopNodes.Node[WaterInletNode].Temp = 60.0
        Cp = HWBaseboard.plantLoc.loop.glycol.getSpecificHeat(state, state.dataLoopNodes.Node[WaterInletNode].Temp, RoutineName)

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
        ZoneNum = HWBaseboard.ZonePtr
        HWBaseboard.ZeroBBSourceSumHATsurf = state.dataHeatBal.Zone[ZoneNum].sumHATsurf(state)
        HWBaseboard.QBBRadSrcAvg = 0.0
        HWBaseboard.LastQBBRadSrc = 0.0
        HWBaseboard.LastSysTimeElapsed = 0.0
        HWBaseboard.LastTimeStepSys = 0.0

    WaterInletNode = HWBaseboard.WaterInletNode
    ZoneNode = state.dataZoneEquip.ZoneEquipConfig[ControlledZoneNum].ZoneNode
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


def SizeHWBaseboard(state, BaseboardNum: int):
    AirInletTempStd = 18.0
    CPAirStd = 1005.0
    Constant = 0.0062
    Coeff = 0.0000275
    RoutineName = "SizeHWBaseboard"
    RoutineNameFull = "BaseboardRadiatorWater:SizeHWBaseboard"

    PltSizHeatNum = 0
    DesCoilLoad = 0.0
    ErrorsFound = False
    WaterVolFlowRateMaxDes = 0.0
    WaterVolFlowRateMaxUser = 0.0
    RatedCapacityDes = 0.0

    hWBaseboard = state.dataHWBaseboardRad.HWBaseboard[BaseboardNum]

    if state.dataSize.CurZoneEqNum > 0:
        zoneEqSizing = state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum]
        CompName = hWBaseboard.Name
        state.dataSize.DataHeatSizeRatio = 1.0
        state.dataSize.DataFracOfAutosizedHeatingCapacity = 1.0
        state.dataSize.DataZoneNumber = hWBaseboard.ZonePtr
        SizingMethod = 1  # HeatingCapacitySizing
        FieldNum = 3
        SizingString = state.dataHWBaseboardRad.HWBaseboardNumericFields[BaseboardNum].FieldNames[FieldNum] + " [W]"
        CapSizingMethod = hWBaseboard.HeatingCapMethod
        zoneEqSizing.SizingMethod[SizingMethod] = CapSizingMethod

        if CapSizingMethod in (0, 1, 2):
            CompType = cCMO_BBRadiator_Water
            if CapSizingMethod == 0:  # HeatingDesignCapacity
                if hWBaseboard.ScaledHeatingCapacity == -999:  # AutoSize
                    zoneEqSizing.HeatingCapacity = True
                    zoneEqSizing.DesHeatingLoad = state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].NonAirSysDesHeatLoad
                TempSize = hWBaseboard.ScaledHeatingCapacity
            elif CapSizingMethod == 1:  # CapacityPerFloorArea
                zoneEqSizing.HeatingCapacity = True
                zoneEqSizing.DesHeatingLoad = (
                    hWBaseboard.ScaledHeatingCapacity * state.dataHeatBal.Zone[state.dataSize.DataZoneNumber].FloorArea
                )
                TempSize = zoneEqSizing.DesHeatingLoad
                state.dataSize.DataScalableCapSizingON = True
            elif CapSizingMethod == 2:  # FractionOfAutosizedHeatingCapacity
                zoneEqSizing.HeatingCapacity = True
                state.dataSize.DataFracOfAutosizedHeatingCapacity = hWBaseboard.ScaledHeatingCapacity
                zoneEqSizing.DesHeatingLoad = state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].NonAirSysDesHeatLoad
                TempSize = -999  # AutoSize
                state.dataSize.DataScalableCapSizingON = True
            else:
                TempSize = hWBaseboard.ScaledHeatingCapacity

            TempSize = size_heating_capacity(state, CompType, CompName, TempSize, RoutineName)
            if hWBaseboard.ScaledHeatingCapacity == -999:  # AutoSize
                hWBaseboard.RatedCapacity = -999
            else:
                hWBaseboard.RatedCapacity = TempSize
            RatedCapacityDes = TempSize
            state.dataSize.DataScalableCapSizingON = False

    PltSizHeatNum = hWBaseboard.plantLoc.loop.PlantSizNum if hWBaseboard.plantLoc and hWBaseboard.plantLoc.loop else 0

    if PltSizHeatNum > 0:
        if state.dataSize.CurZoneEqNum > 0:
            FlowAutoSize = False
            if hWBaseboard.WaterVolFlowRateMax == -999:  # AutoSize
                FlowAutoSize = True

            if not FlowAutoSize and not state.dataSize.ZoneSizingRunDone:
                if hWBaseboard.WaterVolFlowRateMax > 0.0:
                    report_sizer_output(
                        state,
                        cCMO_BBRadiator_Water,
                        hWBaseboard.Name,
                        "User-Specified Maximum Water Flow Rate [m3/s]",
                        hWBaseboard.WaterVolFlowRateMax,
                    )
            else:
                DesCoilLoad = RatedCapacityDes
                if DesCoilLoad >= 100.0:
                    Cp = hWBaseboard.plantLoc.loop.glycol.getSpecificHeat(state, 60.0, RoutineName)
                    rho = hWBaseboard.plantLoc.loop.glycol.getDensity(state, 60.0, RoutineName)
                    WaterVolFlowRateMaxDes = DesCoilLoad / (state.dataSize.PlantSizData[PltSizHeatNum].DeltaT * Cp * rho)
                else:
                    WaterVolFlowRateMaxDes = 0.0

                if FlowAutoSize:
                    hWBaseboard.WaterVolFlowRateMax = WaterVolFlowRateMaxDes
                    report_sizer_output(
                        state,
                        cCMO_BBRadiator_Water,
                        hWBaseboard.Name,
                        "Design Size Maximum Water Flow Rate [m3/s]",
                        WaterVolFlowRateMaxDes,
                    )
                else:
                    if hWBaseboard.WaterVolFlowRateMax > 0.0 and WaterVolFlowRateMaxDes > 0.0:
                        WaterVolFlowRateMaxUser = hWBaseboard.WaterVolFlowRateMax
                        report_sizer_output(
                            state,
                            cCMO_BBRadiator_Water,
                            hWBaseboard.Name,
                            "Design Size Maximum Water Flow Rate [m3/s]",
                            WaterVolFlowRateMaxDes,
                            "User-Specified Maximum Water Flow Rate [m3/s]",
                            WaterVolFlowRateMaxUser,
                        )

            if hWBaseboard.WaterTempAvg > 0.0 and hWBaseboard.WaterMassFlowRateStd > 0.0 and hWBaseboard.RatedCapacity > 0.0:
                DesCoilLoad = hWBaseboard.RatedCapacity
                WaterMassFlowRateStd = hWBaseboard.WaterMassFlowRateStd
            elif hWBaseboard.RatedCapacity == -999 or hWBaseboard.RatedCapacity == 0.0:
                DesCoilLoad = RatedCapacityDes
                rho = hWBaseboard.plantLoc.loop.glycol.getDensity(state, 60.0, RoutineNameFull)
                WaterMassFlowRateStd = hWBaseboard.WaterVolFlowRateMax * rho
            else:
                DesCoilLoad = hWBaseboard.RatedCapacity
                WaterMassFlowRateStd = hWBaseboard.WaterMassFlowRateStd

            if DesCoilLoad >= 100.0:
                AirMassFlowRate = Constant + Coeff * DesCoilLoad
                Cp = hWBaseboard.plantLoc.loop.glycol.getSpecificHeat(state, hWBaseboard.WaterTempAvg, RoutineName)
                WaterInletTempStd = (DesCoilLoad / (2.0 * WaterMassFlowRateStd * Cp)) + hWBaseboard.WaterTempAvg
                WaterOutletTempStd = abs((2.0 * hWBaseboard.WaterTempAvg) - WaterInletTempStd)
                AirOutletTempStd = (DesCoilLoad / (AirMassFlowRate * CPAirStd)) + AirInletTempStd
                hWBaseboard.AirMassFlowRateStd = AirMassFlowRate

                if AirOutletTempStd >= WaterInletTempStd:
                    AirOutletTempStd = WaterInletTempStd - 0.01
                if AirInletTempStd >= WaterOutletTempStd:
                    WaterOutletTempStd = AirInletTempStd + 0.01

                DeltaT1 = WaterInletTempStd - AirOutletTempStd
                DeltaT2 = WaterOutletTempStd - AirInletTempStd
                LMTD = (DeltaT1 - DeltaT2) / math.log(DeltaT1 / DeltaT2)
                hWBaseboard.UA = DesCoilLoad / LMTD
            else:
                hWBaseboard.UA = 0.0

            report_sizer_output(state, cCMO_BBRadiator_Water, hWBaseboard.Name, "U-Factor times Area [W/C]", hWBaseboard.UA)
    else:
        if hWBaseboard.WaterVolFlowRateMax == -999 or hWBaseboard.RatedCapacity == -999 or hWBaseboard.RatedCapacity == 0.0:
            raise RuntimeError("SizeHWBaseboard: Autosizing requires a heating loop Sizing:Plant object")

        hWBaseboard.RatedCapacity = RatedCapacityDes
        DesCoilLoad = RatedCapacityDes

        if DesCoilLoad >= 100.0:
            WaterMassFlowRateStd = hWBaseboard.WaterMassFlowRateStd
            AirMassFlowRate = Constant + Coeff * DesCoilLoad
            Cp = hWBaseboard.plantLoc.loop.glycol.getSpecificHeat(state, hWBaseboard.WaterTempAvg, RoutineName)
            WaterInletTempStd = (DesCoilLoad / (2.0 * WaterMassFlowRateStd * Cp)) + hWBaseboard.WaterTempAvg
            WaterOutletTempStd = abs((2.0 * hWBaseboard.WaterTempAvg) - WaterInletTempStd)
            AirOutletTempStd = (DesCoilLoad / (AirMassFlowRate * CPAirStd)) + AirInletTempStd
            hWBaseboard.AirMassFlowRateStd = AirMassFlowRate

            if AirOutletTempStd >= WaterInletTempStd:
                AirOutletTempStd = WaterInletTempStd - 0.01
            if AirInletTempStd >= WaterOutletTempStd:
                WaterOutletTempStd = AirInletTempStd + 0.01

            DeltaT1 = WaterInletTempStd - AirOutletTempStd
            DeltaT2 = WaterOutletTempStd - AirInletTempStd
            LMTD = (DeltaT1 - DeltaT2) / math.log(DeltaT1 / DeltaT2)
            hWBaseboard.UA = DesCoilLoad / LMTD
        else:
            hWBaseboard.UA = 0.0

        report_sizer_output(state, cCMO_BBRadiator_Water, hWBaseboard.Name, "U-Factor times Area [W/C]", hWBaseboard.UA)

    register_plant_comp_design_flow(state, hWBaseboard.WaterInletNode, hWBaseboard.WaterVolFlowRateMax)

    if ErrorsFound:
        raise RuntimeError("Preceding sizing errors cause program termination")


def CalcHWBaseboard(state, BaseboardNum: int) -> float:
    MinFrac = 0.0005
    RoutineName = "CalcHWBaseboard"

    hWBaseboard = state.dataHWBaseboardRad.HWBaseboard[BaseboardNum]

    ZoneNum = hWBaseboard.ZonePtr
    QZnReq = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNum].RemainingOutputReqToHeatSP
    AirInletTemp = hWBaseboard.AirInletTemp
    WaterInletTemp = hWBaseboard.WaterInletTemp
    WaterMassFlowRate = state.dataLoopNodes.Node[hWBaseboard.WaterInletNode].MassFlowRate

    LoadMet = 0.0

    if (
        QZnReq > 100.0
        and not state.dataZoneEnergyDemand.CurDeadBandOrSetback[ZoneNum]
        and (hWBaseboard.availSched is not None and hWBaseboard.availSched.getCurrentVal() > 0)
        and (WaterMassFlowRate > 0.0)
    ):

        HWBaseboardDesignDataObject = state.dataHWBaseboardRad.HWBaseboardDesignObject[hWBaseboard.DesignObjectPtr]

        AirMassFlowRate = hWBaseboard.AirMassFlowRateStd * (WaterMassFlowRate / hWBaseboard.WaterMassFlowRateMax)
        CapacitanceAir = psychrometrics_psy_cp_air_fn_w(hWBaseboard.AirInletHumRat) * AirMassFlowRate
        Cp = hWBaseboard.plantLoc.loop.glycol.getSpecificHeat(state, WaterInletTemp, RoutineName)

        CapacitanceWater = Cp * WaterMassFlowRate
        CapacitanceMax = max(CapacitanceAir, CapacitanceWater)
        CapacitanceMin = min(CapacitanceAir, CapacitanceWater)
        CapacityRatio = CapacitanceMin / CapacitanceMax if CapacitanceMax > 0 else 0
        NTU = hWBaseboard.UA / CapacitanceMin if CapacitanceMin > 0 else 0

        AA = -CapacityRatio * (NTU ** 0.78)
        if AA < -20.0:
            BB = 0.0
        else:
            BB = math.exp(AA)
        CC = (1.0 / CapacityRatio) * (NTU ** 0.22) * (BB - 1.0) if CapacityRatio > 0 else 0
        if CC < -20.0:
            Effectiveness = 1.0
        else:
            Effectiveness = 1.0 - math.exp(CC)

        AirOutletTemp = AirInletTemp + Effectiveness * CapacitanceMin * (WaterInletTemp - AirInletTemp) / CapacitanceAir if CapacitanceAir > 0 else AirInletTemp
        WaterOutletTemp = WaterInletTemp - CapacitanceAir * (AirOutletTemp - AirInletTemp) / CapacitanceWater if CapacitanceWater > 0 else WaterInletTemp
        BBHeat = CapacitanceWater * (WaterInletTemp - WaterOutletTemp)
        RadHeat = BBHeat * HWBaseboardDesignDataObject.FracRadiant
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
        CapacitanceWater = 0.0
        CapacitanceMax = 0.0
        CapacitanceMin = 0.0
        NTU = 0.0
        Effectiveness = 0.0
        AirOutletTemp = AirInletTemp
        WaterOutletTemp = WaterInletTemp
        BBHeat = 0.0
        LoadMet = 0.0
        RadHeat = 0.0
        WaterMassFlowRate = 0.0
        AirMassFlowRate = 0.0
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


def UpdateHWBaseboard(state, BaseboardNum: int):
    if state.dataGlobal.BeginEnvrnFlag and state.dataHWBaseboardRad.MyEnvrnFlag2:
        state.dataHWBaseboardRad.Iter = 0
        state.dataHWBaseboardRad.MyEnvrnFlag2 = False
    if not state.dataGlobal.BeginEnvrnFlag:
        state.dataHWBaseboardRad.MyEnvrnFlag2 = True

    thisHWBB = state.dataHWBaseboardRad.HWBaseboard[BaseboardNum]

    if thisHWBB.LastSysTimeElapsed == state.dataHVACGlobal.SysTimeElapsed:
        thisHWBB.QBBRadSrcAvg -= thisHWBB.LastQBBRadSrc * thisHWBB.LastTimeStepSys / state.dataGlobal.TimeStepZone

    thisHWBB.QBBRadSrcAvg += thisHWBB.QBBRadSource * state.dataHVACGlobal.TimeStepSys / state.dataGlobal.TimeStepZone

    thisHWBB.LastQBBRadSrc = thisHWBB.QBBRadSource
    thisHWBB.LastSysTimeElapsed = state.dataHVACGlobal.SysTimeElapsed
    thisHWBB.LastTimeStepSys = state.dataHVACGlobal.TimeStepSys

    WaterInletNode = thisHWBB.WaterInletNode
    WaterOutletNode = thisHWBB.WaterOutletNode

    safe_copy_plant_node(state, WaterInletNode, WaterOutletNode)
    state.dataLoopNodes.Node[WaterOutletNode].Temp = thisHWBB.WaterOutletTemp
    state.dataLoopNodes.Node[WaterOutletNode].Enthalpy = thisHWBB.WaterOutletEnthalpy


def UpdateBBRadSourceValAvg(state) -> bool:
    HWBaseboardSysOn = False

    if state.dataHWBaseboardRad.NumHWBaseboards == 0:
        return HWBaseboardSysOn

    for thisHWBaseboard in state.dataHWBaseboardRad.HWBaseboard:
        thisHWBaseboard.QBBRadSource = thisHWBaseboard.QBBRadSrcAvg
        if thisHWBaseboard.QBBRadSrcAvg != 0.0:
            HWBaseboardSysOn = True

    DistributeBBRadGains(state)
    return HWBaseboardSysOn


def DistributeBBRadGains(state):
    SmallestArea = 0.001
    MaxRadHeatFlux = 5000.0

    for thisHWBB in state.dataHWBaseboardRad.HWBaseboard:
        for radSurfNum in range(thisHWBB.TotSurfToDistrib):
            surfNum = thisHWBB.SurfacePtr[radSurfNum]
            if surfNum >= 0 and surfNum < len(state.dataHeatBalFanSys.surfQRadFromHVAC):
                state.dataHeatBalFanSys.surfQRadFromHVAC[surfNum].HWBaseboard = 0.0

    state.dataHeatBalFanSys.ZoneQHWBaseboardToPerson = [0.0] * len(state.dataHeatBalFanSys.ZoneQHWBaseboardToPerson)

    for thisHWBB in state.dataHWBaseboardRad.HWBaseboard:
        HWBaseboardDesignDataObject = state.dataHWBaseboardRad.HWBaseboardDesignObject[thisHWBB.DesignObjectPtr]
        ZoneNum = thisHWBB.ZonePtr
        if ZoneNum <= 0:
            continue

        state.dataHeatBalFanSys.ZoneQHWBaseboardToPerson[ZoneNum] += (
            thisHWBB.QBBRadSource * HWBaseboardDesignDataObject.FracDistribPerson
        )

        for RadSurfNum in range(thisHWBB.TotSurfToDistrib):
            SurfNum = thisHWBB.SurfacePtr[RadSurfNum]
            if state.dataSurface.Surface[SurfNum].Area > SmallestArea:
                ThisSurfIntensity = (
                    thisHWBB.QBBRadSource * thisHWBB.FracDistribToSurf[RadSurfNum] / state.dataSurface.Surface[SurfNum].Area
                )
                state.dataHeatBalFanSys.surfQRadFromHVAC[SurfNum].HWBaseboard += ThisSurfIntensity
                if ThisSurfIntensity > MaxRadHeatFlux:
                    raise RuntimeError(
                        f"DistributeBBRadGains: excessive thermal radiation heat flux intensity detected "
                        f"for surface {state.dataSurface.Surface[SurfNum].Name}"
                    )
            else:
                raise RuntimeError(
                    f"DistributeBBRadGains: surface not large enough to receive thermal radiation heat flux "
                    f"for surface {state.dataSurface.Surface[SurfNum].Name}"
                )


def ReportHWBaseboard(state, BaseboardNum: int):
    thisHWBB = state.dataHWBaseboardRad.HWBaseboard[BaseboardNum]
    timeStepSysSec = state.dataHVACGlobal.TimeStepSysSec

    thisHWBB.TotEnergy = thisHWBB.TotPower * timeStepSysSec
    thisHWBB.Energy = thisHWBB.Power * timeStepSysSec
    thisHWBB.ConvEnergy = thisHWBB.ConvPower * timeStepSysSec
    thisHWBB.RadEnergy = thisHWBB.RadPower * timeStepSysSec


def UpdateHWBaseboardPlantConnection(
    state,
    BaseboardTypeNum: int,
    BaseboardName: str,
    EquipFlowCtrl: int,
    LoopNum: int,
    LoopSide: int,
    FirstHVACIteration: bool,
) -> tuple:
    CompIndex = 0
    InitLoopEquip = False
    NumHWBaseboards = state.dataHWBaseboardRad.NumHWBaseboards

    if CompIndex == 0:
        BaseboardNum = find_item_in_list(BaseboardName, state.dataHWBaseboardRad.HWBaseboard)
        if BaseboardNum == -1:
            raise RuntimeError(f"UpdateHWBaseboardPlantConnection: Specified baseboard not valid ={BaseboardName}")
        CompIndex = BaseboardNum
    else:
        BaseboardNum = CompIndex
        if BaseboardNum >= NumHWBaseboards or BaseboardNum < 0:
            raise RuntimeError(
                f"UpdateHWBaseboardPlantConnection: Invalid CompIndex passed={BaseboardNum}, "
                f"Number of baseboards={NumHWBaseboards}, Entered baseboard name={BaseboardName}"
            )
        if state.dataGlobal.KickOffSimulation:
            if BaseboardName != state.dataHWBaseboardRad.HWBaseboard[BaseboardNum].Name:
                raise RuntimeError(
                    f"UpdateHWBaseboardPlantConnection: Invalid CompIndex passed={BaseboardNum}, "
                    f"baseboard name={BaseboardName}, stored baseboard Name for that index="
                    f"{state.dataHWBaseboardRad.HWBaseboard[BaseboardNum].Name}"
                )

    if InitLoopEquip:
        return CompIndex, InitLoopEquip

    thisHWBaseboard = state.dataHWBaseboardRad.HWBaseboard[BaseboardNum]
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


# External stub functions (to be implemented by caller)

def find_item_in_list(name: str, items: List) -> int:
    for i, item in enumerate(items):
        if hasattr(item, 'Name') and item.Name == name:
            return i
    return -1


def get_enum_value_heating_cap_method(name: str) -> int:
    mapping = {
        "HEATINGDESIGNCAPACITY": 0,
        "CAPACITYPERFLOORAREA": 1,
        "FRACTIONOFAUTOSIZEDHEATINGCAPACITY": 2,
    }
    return mapping.get(name.upper(), 0)


def set_design_object_name_and_pointer(state, baseboard, design_name: str, design_names_list: List[str]):
    baseboard.designObjectName = design_name
    baseboard.DesignObjectPtr = design_names_list.index(design_name) if design_name in design_names_list else 0


def get_schedule(state, sched_name: str):
    return None  # Stub


def get_only_single_node(state, node_name: str) -> int:
    return 0  # Stub


def get_zone_equip_controlled_zone_num(state, baseboard_name: str) -> int:
    return 0  # Stub


def get_radiant_system_surface(state, object_type: str, baseboard_name: str, zone_num: int, surface_name: str) -> int:
    return 0  # Stub


def setup_output_variable(state, var_name: str, units: str, obj: object, field: str, name: str):
    pass  # Stub


def init_component_nodes(state, min_flow: float, max_flow: float, inlet_node: int, outlet_node: int):
    pass  # Stub


def scan_plant_loops_for_object(state, name: str, equip_type: int, plant_loc: object):
    pass  # Stub


def size_heating_capacity(state, comp_type: str, comp_name: str, temp_size: float, routine_name: str) -> float:
    return temp_size


def report_sizer_output(state, comp_type: str, comp_name: str, desc: str, value: float, desc2: str = "", value2: float = 0.0):
    pass  # Stub


def register_plant_comp_design_flow(state, inlet_node: int, volume_flow_rate: float):
    pass  # Stub


def psychrometrics_psy_cp_air_fn_w(hum_rat: float) -> float:
    return 1005.0  # Stub


def safe_copy_plant_node(state, from_node: int, to_node: int):
    pass  # Stub


def set_actuated_branch_flow_rate(state, flow_rate: float, inlet_node: int, plant_loc: object, available: bool):
    pass  # Stub


def calc_heat_balance_outside_surf(state, zone_num: int):
    pass  # Stub


def calc_heat_balance_inside_surf(state, zone_num: int):
    pass  # Stub


def pull_comp_interconnect_trigger(state, plant_loc_from: object, index: int, plant_loc_to: object, criteria_type: int, value: float):
    pass  # Stub


def control_comp_output(state, *args, **kwargs):
    pass  # Stub
