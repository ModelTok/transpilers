from dataclasses import dataclass, field
from typing import Optional, Protocol, List, Any

# EXTERNAL DEPS (to wire in glue):
# EnergyPlusData - main simulation state object
# state.dataBaseboardElectric - module-level state container
# state.dataInputProcessing.inputProcessor - input processor with getNumObjectsFound, getObjectItem
# state.dataIPShortCut - input processor shortcuts (cAlphaArgs, rNumericArgs, etc.)
# state.dataZoneEnergyDemand - zone energy demand data
# state.dataHVACGlobal - HVAC globals (TimeStepSysSec)
# state.dataZoneEquip - zone equipment config
# state.dataLoopNodes - loop node data
# state.dataSize - sizing data
# state.dataGlobal - global data (SysSizingCalc)
# state.dataHeatBal - heat balance data (Zone)
# Util.FindItemInList - find item by attribute in list
# Util.makeUPPER - uppercase string
# Util.SameString - case-insensitive string comparison
# Sched.GetScheduleAlwaysOn - get always-on schedule
# Sched.GetSchedule - get schedule by name
# DataZoneEquipment.GetZoneEquipControlledZoneNum - get zone number
# Psychrometrics.PsyCpAirFnW - specific heat of air
# ShowFatalError, ShowSevereItemNotFound, ShowSevereError, ShowContinueError - error reporting
# SetupOutputVariable - output processor setup
# CheckZoneSizing - sizing checker
# HeatingCapacitySizer - sizing utility
# HVAC.SmallLoad - small load threshold
# HVAC.HeatingCapacitySizing - sizing method enum
# DataSizing constants - AutoSize, CapacityPerFloorArea, etc.
# Constant.Units, Constant.eResource - unit and resource enums
# OutputProcessor - output processor enums and functions
# ErrorObjectHeader - error reporting utility


@dataclass
class BaseboardParams:
    EquipName: str = ""
    EquipType: str = ""
    Schedule: str = ""
    availSched: Optional[Any] = None
    NominalCapacity: float = 0.0
    BaseboardEfficiency: float = 0.0
    AirInletTemp: float = 0.0
    AirInletHumRat: float = 0.0
    AirOutletTemp: float = 0.0
    Power: float = 0.0
    Energy: float = 0.0
    ElecUseLoad: float = 0.0
    ElecUseRate: float = 0.0
    ZonePtr: int = 0
    HeatingCapMethod: int = 0
    ScaledHeatingCapacity: float = 0.0
    MySizeFlag: bool = True
    CheckEquipName: bool = True
    FieldNames: List[str] = field(default_factory=list)


cCMO_BBRadiator_Electric = "ZoneHVAC:Baseboard:Convective:Electric"
SimpConvAirFlowSpeed = 0.5


def SimElectricBaseboard(state: Any, EquipName: str, ControlledZoneNum: int, CompIndex: int) -> tuple[float, int]:
    """
    Simulates the Electric Baseboard units.
    """
    if state.dataBaseboardElectric.getInputFlag:
        GetBaseboardInput(state)
        state.dataBaseboardElectric.getInputFlag = False

    baseboard = state.dataBaseboardElectric

    if CompIndex == 0:
        BaseboardNum = Util.FindItemInList(EquipName, baseboard.baseboards, lambda x: x.EquipName)
        if BaseboardNum == 0:
            ShowFatalError(state, f"SimElectricBaseboard: Unit not found={EquipName}")
        CompIndex = BaseboardNum
    else:
        BaseboardNum = CompIndex
        numBaseboards = len(baseboard.baseboards)
        if BaseboardNum > numBaseboards or BaseboardNum < 1:
            ShowFatalError(state, 
                f"SimElectricBaseboard:  Invalid CompIndex passed={BaseboardNum}, "
                f"Number of Units={numBaseboards}, Entered Unit name={EquipName}")
        if baseboard.baseboards[BaseboardNum - 1].CheckEquipName:
            if EquipName != baseboard.baseboards[BaseboardNum - 1].EquipName:
                ShowFatalError(state,
                    f"SimElectricBaseboard: Invalid CompIndex passed={BaseboardNum}, "
                    f"Unit name={EquipName}, "
                    f"stored Unit Name for that index={baseboard.baseboards[BaseboardNum - 1].EquipName}")
            baseboard.baseboards[BaseboardNum - 1].CheckEquipName = False

    InitBaseboard(state, BaseboardNum, ControlledZoneNum)

    QZnReq = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ControlledZoneNum].RemainingOutputReqToHeatSP

    SimElectricConvective(state, BaseboardNum, QZnReq)

    PowerMet = baseboard.baseboards[BaseboardNum - 1].Power

    baseboard.baseboards[BaseboardNum - 1].Energy = baseboard.baseboards[BaseboardNum - 1].Power * state.dataHVACGlobal.TimeStepSysSec
    baseboard.baseboards[BaseboardNum - 1].ElecUseLoad = baseboard.baseboards[BaseboardNum - 1].ElecUseRate * state.dataHVACGlobal.TimeStepSysSec

    return PowerMet, CompIndex


def GetBaseboardInput(state: Any) -> None:
    """
    Gets the input for the Baseboard units.
    """
    baseboard = state.dataBaseboardElectric
    cCurrentModuleObject = cCMO_BBRadiator_Electric

    NumConvElecBaseboards = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, cCurrentModuleObject)

    baseboard.baseboards = [None] * NumConvElecBaseboards

    if NumConvElecBaseboards > 0:
        ErrorsFound = False
        s_ipsc = state.dataIPShortCut
        
        for ConvElecBBNum in range(1, NumConvElecBaseboards + 1):
            NumAlphas = 0
            NumNums = 0
            IOStat = 0
            
            state.dataInputProcessing.inputProcessor.getObjectItem(
                state,
                cCurrentModuleObject,
                ConvElecBBNum,
                s_ipsc.cAlphaArgs,
                NumAlphas,
                s_ipsc.rNumericArgs,
                NumNums,
                IOStat,
                s_ipsc.lNumericFieldBlanks,
                s_ipsc.lAlphaFieldBlanks,
                s_ipsc.cAlphaFieldNames,
                s_ipsc.cNumericFieldNames
            )

            BaseboardNum = ConvElecBBNum
            thisBaseboard = BaseboardParams()
            thisBaseboard.FieldNames = s_ipsc.cNumericFieldNames[:]

            eoh = ErrorObjectHeader(f"GetBaseboardInput", cCurrentModuleObject, s_ipsc.cAlphaArgs[0])
            
            VerifyUniqueBaseboardName(
                state, cCurrentModuleObject, s_ipsc.cAlphaArgs[0], ErrorsFound,
                f"{cCurrentModuleObject} Name")

            thisBaseboard.EquipName = s_ipsc.cAlphaArgs[0]
            thisBaseboard.EquipType = Util.makeUPPER(cCurrentModuleObject)
            thisBaseboard.Schedule = s_ipsc.cAlphaArgs[1]
            
            if s_ipsc.lAlphaFieldBlanks[1]:
                thisBaseboard.availSched = Sched.GetScheduleAlwaysOn(state)
            elif (thisBaseboard.availSched := Sched.GetSchedule(state, s_ipsc.cAlphaArgs[1])) is None:
                ShowSevereItemNotFound(state, eoh, s_ipsc.cAlphaFieldNames[1], s_ipsc.cAlphaArgs[1])
                ErrorsFound = True

            thisBaseboard.BaseboardEfficiency = s_ipsc.rNumericArgs[3]

            iHeatCAPMAlphaNum = 2
            iHeatDesignCapacityNumericNum = 0
            iHeatCapacityPerFloorAreaNumericNum = 1
            iHeatFracOfAutosizedCapacityNumericNum = 2

            if Util.SameString(s_ipsc.cAlphaArgs[iHeatCAPMAlphaNum], "HeatingDesignCapacity"):
                thisBaseboard.HeatingCapMethod = 1
                if not s_ipsc.lNumericFieldBlanks[iHeatDesignCapacityNumericNum]:
                    thisBaseboard.ScaledHeatingCapacity = s_ipsc.rNumericArgs[iHeatDesignCapacityNumericNum]
                    if thisBaseboard.ScaledHeatingCapacity < 0.0 and thisBaseboard.ScaledHeatingCapacity != -999.0:
                        ShowSevereError(state, f"{cCurrentModuleObject} = {thisBaseboard.EquipName}")
                        ShowContinueError(state,
                            f"Illegal {s_ipsc.cNumericFieldNames[iHeatDesignCapacityNumericNum]} = {s_ipsc.rNumericArgs[iHeatDesignCapacityNumericNum]:.7f}")
                        ErrorsFound = True
                else:
                    ShowSevereError(state, f"{cCurrentModuleObject} = {thisBaseboard.EquipName}")
                    ShowContinueError(state,
                        f"Input for {s_ipsc.cAlphaFieldNames[iHeatCAPMAlphaNum]} = {s_ipsc.cAlphaArgs[iHeatCAPMAlphaNum]}")
                    ShowContinueError(state,
                        f"Blank field not allowed for {s_ipsc.cNumericFieldNames[iHeatDesignCapacityNumericNum]}")
                    ErrorsFound = True
            elif Util.SameString(s_ipsc.cAlphaArgs[iHeatCAPMAlphaNum], "CapacityPerFloorArea"):
                thisBaseboard.HeatingCapMethod = 2
                if not s_ipsc.lNumericFieldBlanks[iHeatCapacityPerFloorAreaNumericNum]:
                    thisBaseboard.ScaledHeatingCapacity = s_ipsc.rNumericArgs[iHeatCapacityPerFloorAreaNumericNum]
                    if thisBaseboard.ScaledHeatingCapacity <= 0.0:
                        ShowSevereError(state, f"{cCurrentModuleObject} = {thisBaseboard.EquipName}")
                        ShowContinueError(state,
                            f"Input for {s_ipsc.cAlphaFieldNames[iHeatCAPMAlphaNum]} = {s_ipsc.cAlphaArgs[iHeatCAPMAlphaNum]}")
                        ShowContinueError(state,
                            f"Illegal {s_ipsc.cNumericFieldNames[iHeatCapacityPerFloorAreaNumericNum]} = {s_ipsc.rNumericArgs[iHeatCapacityPerFloorAreaNumericNum]:.7f}")
                        ErrorsFound = True
                    elif thisBaseboard.ScaledHeatingCapacity == -999.0:
                        ShowSevereError(state, f"{cCurrentModuleObject} = {thisBaseboard.EquipName}")
                        ShowContinueError(state,
                            f"Input for {s_ipsc.cAlphaFieldNames[iHeatCAPMAlphaNum]} = {s_ipsc.cAlphaArgs[iHeatCAPMAlphaNum]}")
                        ShowContinueError(state,
                            f"Illegal {s_ipsc.cNumericFieldNames[iHeatCapacityPerFloorAreaNumericNum]} = AutoSize")
                        ErrorsFound = True
                else:
                    ShowSevereError(state, f"{cCurrentModuleObject} = {thisBaseboard.EquipName}")
                    ShowContinueError(state,
                        f"Input for {s_ipsc.cAlphaFieldNames[iHeatCAPMAlphaNum]} = {s_ipsc.cAlphaArgs[iHeatCAPMAlphaNum]}")
                    ShowContinueError(state,
                        f"Blank field not allowed for {s_ipsc.cNumericFieldNames[iHeatCapacityPerFloorAreaNumericNum]}")
                    ErrorsFound = True
            elif Util.SameString(s_ipsc.cAlphaArgs[iHeatCAPMAlphaNum], "FractionOfAutosizedHeatingCapacity"):
                thisBaseboard.HeatingCapMethod = 3
                if not s_ipsc.lNumericFieldBlanks[iHeatFracOfAutosizedCapacityNumericNum]:
                    thisBaseboard.ScaledHeatingCapacity = s_ipsc.rNumericArgs[iHeatFracOfAutosizedCapacityNumericNum]
                    if thisBaseboard.ScaledHeatingCapacity < 0.0:
                        ShowSevereError(state, f"{cCurrentModuleObject} = {thisBaseboard.EquipName}")
                        ShowContinueError(state,
                            f"Illegal {s_ipsc.cNumericFieldNames[iHeatFracOfAutosizedCapacityNumericNum]} = {s_ipsc.rNumericArgs[iHeatFracOfAutosizedCapacityNumericNum]:.7f}")
                        ErrorsFound = True
                else:
                    ShowSevereError(state, f"{cCurrentModuleObject} = {thisBaseboard.EquipName}")
                    ShowContinueError(state,
                        f"Input for {s_ipsc.cAlphaFieldNames[iHeatCAPMAlphaNum]} = {s_ipsc.cAlphaArgs[iHeatCAPMAlphaNum]}")
                    ShowContinueError(state,
                        f"Blank field not allowed for {s_ipsc.cNumericFieldNames[iHeatFracOfAutosizedCapacityNumericNum]}")
                    ErrorsFound = True
            else:
                ShowSevereError(state, f"{cCurrentModuleObject} = {thisBaseboard.EquipName}")
                ShowContinueError(state,
                    f"Illegal {s_ipsc.cAlphaFieldNames[iHeatCAPMAlphaNum]} = {s_ipsc.cAlphaArgs[iHeatCAPMAlphaNum]}")
                ErrorsFound = True

            thisBaseboard.ZonePtr = DataZoneEquipment.GetZoneEquipControlledZoneNum(
                state, DataZoneEquipment.ZoneEquipType.BaseboardConvectiveElectric, thisBaseboard.EquipName)

            baseboard.baseboards[BaseboardNum - 1] = thisBaseboard

        if ErrorsFound:
            ShowFatalError(state, "GetBaseboardInput: Errors found in getting input.  Preceding condition(s) cause termination.")

    for BaseboardNum in range(1, NumConvElecBaseboards + 1):
        thisBaseboard = baseboard.baseboards[BaseboardNum - 1]
        SetupOutputVariable(state,
            "Baseboard Total Heating Energy",
            Constant.Units.J,
            thisBaseboard.Energy,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Sum,
            thisBaseboard.EquipName,
            Constant.eResource.EnergyTransfer,
            OutputProcessor.Group.HVAC,
            OutputProcessor.EndUseCat.Baseboard)

        SetupOutputVariable(state,
            "Baseboard Total Heating Rate",
            Constant.Units.W,
            thisBaseboard.Power,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            thisBaseboard.EquipName)

        SetupOutputVariable(state,
            "Baseboard Electricity Energy",
            Constant.Units.J,
            thisBaseboard.ElecUseLoad,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Sum,
            thisBaseboard.EquipName,
            Constant.eResource.Electricity,
            OutputProcessor.Group.HVAC,
            OutputProcessor.EndUseCat.Heating)

        SetupOutputVariable(state,
            "Baseboard Electricity Rate",
            Constant.Units.W,
            thisBaseboard.ElecUseRate,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            thisBaseboard.EquipName)


def InitBaseboard(state: Any, BaseboardNum: int, ControlledZoneNum: int) -> None:
    """
    Initializes the Baseboard units during simulation.
    """
    baseboard = state.dataBaseboardElectric

    if not state.dataGlobal.SysSizingCalc and baseboard.baseboards[BaseboardNum - 1].MySizeFlag:
        SizeElectricBaseboard(state, BaseboardNum)
        baseboard.baseboards[BaseboardNum - 1].MySizeFlag = False

    baseboard.baseboards[BaseboardNum - 1].Energy = 0.0
    baseboard.baseboards[BaseboardNum - 1].Power = 0.0
    baseboard.baseboards[BaseboardNum - 1].ElecUseLoad = 0.0
    baseboard.baseboards[BaseboardNum - 1].ElecUseRate = 0.0

    ZoneNode = state.dataZoneEquip.ZoneEquipConfig[ControlledZoneNum].ZoneNode
    baseboard.baseboards[BaseboardNum - 1].AirInletTemp = state.dataLoopNodes.Node[ZoneNode].Temp
    baseboard.baseboards[BaseboardNum - 1].AirInletHumRat = state.dataLoopNodes.Node[ZoneNode].HumRat


def SizeElectricBaseboard(state: Any, BaseboardNum: int) -> None:
    """
    Sizes the electric baseboard component.
    """
    TempSize = 0.0
    state.dataSize.DataScalableCapSizingON = False

    if state.dataSize.CurZoneEqNum > 0:
        ZoneEqSizing = state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum]
        baseboard = state.dataBaseboardElectric.baseboards[BaseboardNum - 1]

        CompType = baseboard.EquipType
        CompName = baseboard.EquipName
        state.dataSize.DataFracOfAutosizedHeatingCapacity = 1.0
        state.dataSize.DataZoneNumber = baseboard.ZonePtr
        SizingMethod = HVAC.HeatingCapacitySizing
        FieldNum = 1
        SizingString = f"{baseboard.FieldNames[FieldNum - 1]} [W]"
        CapSizingMethod = baseboard.HeatingCapMethod
        ZoneEqSizing.SizingMethod[SizingMethod] = CapSizingMethod

        if CapSizingMethod in [1, 2, 3]:
            if CapSizingMethod == 1:
                if baseboard.ScaledHeatingCapacity == -999.0:
                    CheckZoneSizing(state, CompType, CompName)
                    ZoneEqSizing.HeatingCapacity = True
                    ZoneEqSizing.DesHeatingLoad = state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].NonAirSysDesHeatLoad
                TempSize = baseboard.ScaledHeatingCapacity
            elif CapSizingMethod == 2:
                ZoneEqSizing.HeatingCapacity = True
                ZoneEqSizing.DesHeatingLoad = baseboard.ScaledHeatingCapacity * state.dataHeatBal.Zone[state.dataSize.DataZoneNumber].FloorArea
                TempSize = ZoneEqSizing.DesHeatingLoad
                state.dataSize.DataScalableCapSizingON = True
            elif CapSizingMethod == 3:
                CheckZoneSizing(state, CompType, CompName)
                ZoneEqSizing.HeatingCapacity = True
                state.dataSize.DataFracOfAutosizedHeatingCapacity = baseboard.ScaledHeatingCapacity
                ZoneEqSizing.DesHeatingLoad = state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].NonAirSysDesHeatLoad
                TempSize = -999.0
                state.dataSize.DataScalableCapSizingON = True
            else:
                TempSize = baseboard.ScaledHeatingCapacity

            PrintFlag = True
            errorsFound = False
            sizerHeatingCapacity = HeatingCapacitySizer()
            sizerHeatingCapacity.overrideSizingString(SizingString)
            sizerHeatingCapacity.initializeWithinEP(state, CompType, CompName, PrintFlag, "SizeElectricBaseboard")
            baseboard.NominalCapacity = sizerHeatingCapacity.size(state, TempSize, errorsFound)
            state.dataSize.DataScalableCapSizingON = False


def SimElectricConvective(state: Any, BaseboardNum: int, LoadMet: float) -> None:
    """
    Calculates heat exchange rate in electric convective baseboard heater.
    """
    baseboard = state.dataBaseboardElectric.baseboards[BaseboardNum - 1]

    AirInletTemp = baseboard.AirInletTemp
    CpAir = Psychrometrics.PsyCpAirFnW(baseboard.AirInletHumRat)
    AirMassFlowRate = SimpConvAirFlowSpeed
    CapacitanceAir = CpAir * AirMassFlowRate
    Effic = baseboard.BaseboardEfficiency

    if baseboard.availSched.getCurrentVal() > 0.0 and LoadMet >= HVAC.SmallLoad:
        if LoadMet > baseboard.NominalCapacity:
            QBBCap = baseboard.NominalCapacity
        else:
            QBBCap = LoadMet

        AirOutletTemp = AirInletTemp + QBBCap / CapacitanceAir
        baseboard.ElecUseRate = QBBCap / Effic
    else:
        AirOutletTemp = AirInletTemp
        QBBCap = 0.0
        baseboard.ElecUseRate = 0.0

    baseboard.AirOutletTemp = AirOutletTemp
    baseboard.Power = QBBCap


class BaseboardElectricData:
    def __init__(self):
        self.getInputFlag = True
        self.baseboards: List[BaseboardParams] = []

    def init_constant_state(self, state: Any) -> None:
        pass

    def init_state(self, state: Any) -> None:
        pass

    def clear_state(self) -> None:
        self.getInputFlag = True
        self.baseboards = []
