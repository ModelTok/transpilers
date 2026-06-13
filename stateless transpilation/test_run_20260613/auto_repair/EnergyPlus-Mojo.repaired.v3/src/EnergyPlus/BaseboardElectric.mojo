from .Autosizing.HeatingCapacitySizing import HeatingCapacitySizer
from BaseboardElectric import BaseboardElectricData, BaseboardParams
from .Data.EnergyPlusData import EnergyPlusData
from DataHVACGlobals import TimeStepSysSec
from DataHeatBalance import Zone
from DataIPShortCuts import DataIPShortCut
from DataLoopNode import Node
from DataSizing import AutoSize, CapacityPerFloorArea, FractionOfAutosizedHeatingCapacity, HeatingDesignCapacity
from DataZoneEnergyDemands import ZoneSysEnergyDemand
from DataZoneEquipment import ZoneEquipConfig, GetZoneEquipControlledZoneNum, ZoneEquipType
from GeneralRoutines import CheckZoneSizing
from GlobalNames import VerifyUniqueBaseboardName
from .InputProcessing.InputProcessor import InputProcessor
from OutputProcessor import SetupOutputVariable, TimeStepType, StoreType, Group, EndUseCat
from Psychrometrics import PsyCpAirFnW
from ScheduleManager import Schedule, GetSchedule, GetScheduleAlwaysOn
from UtilityRoutines import FindItemInList, makeUPPER, SameString
from UtilityRoutines import ShowFatalError, ShowSevereError, ShowSevereItemNotFound, ShowContinueError
from UtilityRoutines import ErrorObjectHeader
from DataGlobals import SysSizingCalc
from DataHVACGlobals import SmallLoad
from DataSizing import DataScalableCapSizingON, CurZoneEqNum, ZoneEqSizing, DataFracOfAutosizedHeatingCapacity, DataZoneNumber, FinalZoneSizing
from DataSizing import HeatingCapacitySizing
from Constant import Units, eResource

const cCMO_BBRadiator_Electric: StringLiteral = "ZoneHVAC:Baseboard:Convective:Electric"
const SimpConvAirFlowSpeed: Float64 = 0.5

def SimElectricBaseboard(
    state: EnergyPlusData,
    EquipName: String,
    ControlledZoneNum: Int,
    PowerMet: Float64,
    CompIndex: Int,
):
    var BaseboardNum: Int
    var QZnReq: Float64

    if state.dataBaseboardElectric.getInputFlag:
        GetBaseboardInput(state)
        state.dataBaseboardElectric.getInputFlag = False

    var baseboard = state.dataBaseboardElectric

    if CompIndex == 0:
        BaseboardNum = FindItemInList(EquipName, baseboard.baseboards, BaseboardParams.EquipName)
        if BaseboardNum == 0:
            ShowFatalError(state, "SimElectricBaseboard: Unit not found=" + EquipName)
        CompIndex = BaseboardNum
    else:
        BaseboardNum = CompIndex
        var numBaseboards: Int = len(baseboard.baseboards)
        if BaseboardNum > numBaseboards or BaseboardNum < 1:
            ShowFatalError(
                state,
                "SimElectricBaseboard:  Invalid CompIndex passed=" + str(BaseboardNum) + ", Number of Units=" + str(numBaseboards) + ", Entered Unit name=" + EquipName,
            )
        if baseboard.baseboards[BaseboardNum - 1].CheckEquipName:
            if EquipName != baseboard.baseboards[BaseboardNum - 1].EquipName:
                ShowFatalError(
                    state,
                    "SimElectricBaseboard: Invalid CompIndex passed=" + str(BaseboardNum) + ", Unit name=" + EquipName + ", stored Unit Name for that index=" + baseboard.baseboards[BaseboardNum - 1].EquipName,
                )
            baseboard.baseboards[BaseboardNum - 1].CheckEquipName = False

    InitBaseboard(state, BaseboardNum, ControlledZoneNum)
    QZnReq = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ControlledZoneNum - 1].RemainingOutputReqToHeatSP
    SimElectricConvective(state, BaseboardNum, QZnReq)
    PowerMet = baseboard.baseboards[BaseboardNum - 1].Power
    baseboard.baseboards[BaseboardNum - 1].Energy = baseboard.baseboards[BaseboardNum - 1].Power * state.dataHVACGlobal.TimeStepSysSec
    baseboard.baseboards[BaseboardNum - 1].ElecUseLoad = baseboard.baseboards[BaseboardNum - 1].ElecUseRate * state.dataHVACGlobal.TimeStepSysSec

def GetBaseboardInput(state: EnergyPlusData):
    var RoutineName: StringLiteral = "GetBaseboardInput: "
    var routineName: StringLiteral = "GetBaseboardInput"
    var iHeatCAPMAlphaNum: Int = 3
    var iHeatDesignCapacityNumericNum: Int = 1
    var iHeatCapacityPerFloorAreaNumericNum: Int = 2
    var iHeatFracOfAutosizedCapacityNumericNum: Int = 3

    var baseboard = state.dataBaseboardElectric
    var cCurrentModuleObject: StringLiteral = cCMO_BBRadiator_Electric
    var NumConvElecBaseboards: Int = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, cCurrentModuleObject)
    baseboard.baseboards.allocate(NumConvElecBaseboards)

    if NumConvElecBaseboards > 0:
        var ErrorsFound: Bool = False
        var NumAlphas: Int = 0
        var NumNums: Int = 0
        var IOStat: Int = 0
        var BaseboardNum: Int = 0
        var s_ipsc = state.dataIPShortCut

        for ConvElecBBNum in range(1, NumConvElecBaseboards + 1):
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
                s_ipsc.cNumericFieldNames,
            )
            baseboard.baseboards[ConvElecBBNum - 1].FieldNames.assign(s_ipsc.cNumericFieldNames.begin(), s_ipsc.cNumericFieldNames.end())
            var eoh = ErrorObjectHeader(routineName, cCurrentModuleObject, s_ipsc.cAlphaArgs[0])
            VerifyUniqueBaseboardName(
                state, cCurrentModuleObject, s_ipsc.cAlphaArgs[0], ErrorsFound, cCurrentModuleObject + " Name",
            )
            BaseboardNum += 1
            var thisBaseboard = baseboard.baseboards[BaseboardNum - 1]
            thisBaseboard.EquipName = s_ipsc.cAlphaArgs[0]
            thisBaseboard.EquipType = makeUPPER(cCurrentModuleObject)
            thisBaseboard.Schedule = s_ipsc.cAlphaArgs[1]
            if s_ipsc.lAlphaFieldBlanks[1]:
                thisBaseboard.availSched = GetScheduleAlwaysOn(state)
            elif (thisBaseboard.availSched = GetSchedule(state, s_ipsc.cAlphaArgs[1])) is None:
                ShowSevereItemNotFound(state, eoh, s_ipsc.cAlphaFieldNames[1], s_ipsc.cAlphaArgs[1])
                ErrorsFound = True
            thisBaseboard.BaseboardEfficiency = s_ipsc.rNumericArgs[3]
            if SameString(s_ipsc.cAlphaArgs[iHeatCAPMAlphaNum - 1], "HeatingDesignCapacity"):
                thisBaseboard.HeatingCapMethod = HeatingDesignCapacity
                if not s_ipsc.lNumericFieldBlanks[iHeatDesignCapacityNumericNum - 1]:
                    thisBaseboard.ScaledHeatingCapacity = s_ipsc.rNumericArgs[iHeatDesignCapacityNumericNum - 1]
                    if thisBaseboard.ScaledHeatingCapacity < 0.0 and thisBaseboard.ScaledHeatingCapacity != AutoSize:
                        ShowSevereError(state, cCurrentModuleObject + " = " + thisBaseboard.EquipName)
                        ShowContinueError(
                            state,
                            "Illegal " + s_ipsc.cNumericFieldNames[iHeatDesignCapacityNumericNum - 1] + " = " + str(s_ipsc.rNumericArgs[iHeatDesignCapacityNumericNum - 1]),
                        )
                        ErrorsFound = True
                else:
                    ShowSevereError(state, cCurrentModuleObject + " = " + thisBaseboard.EquipName)
                    ShowContinueError(
                        state,
                        "Input for " + s_ipsc.cAlphaFieldNames[iHeatCAPMAlphaNum - 1] + " = " + s_ipsc.cAlphaArgs[iHeatCAPMAlphaNum - 1],
                    )
                    ShowContinueError(
                        state,
                        "Blank field not allowed for " + s_ipsc.cNumericFieldNames[iHeatDesignCapacityNumericNum - 1],
                    )
                    ErrorsFound = True
            elif SameString(s_ipsc.cAlphaArgs[iHeatCAPMAlphaNum - 1], "CapacityPerFloorArea"):
                thisBaseboard.HeatingCapMethod = CapacityPerFloorArea
                if not s_ipsc.lNumericFieldBlanks[iHeatCapacityPerFloorAreaNumericNum - 1]:
                    thisBaseboard.ScaledHeatingCapacity = s_ipsc.rNumericArgs[iHeatCapacityPerFloorAreaNumericNum - 1]
                    if thisBaseboard.ScaledHeatingCapacity <= 0.0:
                        ShowSevereError(state, cCurrentModuleObject + " = " + thisBaseboard.EquipName)
                        ShowContinueError(
                            state,
                            "Input for " + s_ipsc.cAlphaFieldNames[iHeatCAPMAlphaNum - 1] + " = " + s_ipsc.cAlphaArgs[iHeatCAPMAlphaNum - 1],
                        )
                        ShowContinueError(
                            state,
                            "Illegal " + s_ipsc.cNumericFieldNames[iHeatCapacityPerFloorAreaNumericNum - 1] + " = " + str(s_ipsc.rNumericArgs[iHeatCapacityPerFloorAreaNumericNum - 1]),
                        )
                        ErrorsFound = True
                    elif thisBaseboard.ScaledHeatingCapacity == AutoSize:
                        ShowSevereError(state, cCurrentModuleObject + " = " + thisBaseboard.EquipName)
                        ShowContinueError(
                            state,
                            "Input for " + s_ipsc.cAlphaFieldNames[iHeatCAPMAlphaNum - 1] + " = " + s_ipsc.cAlphaArgs[iHeatCAPMAlphaNum - 1],
                        )
                        ShowContinueError(
                            state,
                            "Illegal " + s_ipsc.cNumericFieldNames[iHeatCapacityPerFloorAreaNumericNum - 1] + " = AutoSize",
                        )
                        ErrorsFound = True
                else:
                    ShowSevereError(state, cCurrentModuleObject + " = " + thisBaseboard.EquipName)
                    ShowContinueError(
                        state,
                        "Input for " + s_ipsc.cAlphaFieldNames[iHeatCAPMAlphaNum - 1] + " = " + s_ipsc.cAlphaArgs[iHeatCAPMAlphaNum - 1],
                    )
                    ShowContinueError(
                        state,
                        "Blank field not allowed for " + s_ipsc.cNumericFieldNames[iHeatCapacityPerFloorAreaNumericNum - 1],
                    )
                    ErrorsFound = True
            elif SameString(s_ipsc.cAlphaArgs[iHeatCAPMAlphaNum - 1], "FractionOfAutosizedHeatingCapacity"):
                thisBaseboard.HeatingCapMethod = FractionOfAutosizedHeatingCapacity
                if not s_ipsc.lNumericFieldBlanks[iHeatFracOfAutosizedCapacityNumericNum - 1]:
                    thisBaseboard.ScaledHeatingCapacity = s_ipsc.rNumericArgs[iHeatFracOfAutosizedCapacityNumericNum - 1]
                    if thisBaseboard.ScaledHeatingCapacity < 0.0:
                        ShowSevereError(state, cCurrentModuleObject + " = " + thisBaseboard.EquipName)
                        ShowContinueError(
                            state,
                            "Illegal " + s_ipsc.cNumericFieldNames[iHeatFracOfAutosizedCapacityNumericNum - 1] + " = " + str(s_ipsc.rNumericArgs[iHeatFracOfAutosizedCapacityNumericNum - 1]),
                        )
                        ErrorsFound = True
                else:
                    ShowSevereError(state, cCurrentModuleObject + " = " + thisBaseboard.EquipName)
                    ShowContinueError(
                        state,
                        "Input for " + s_ipsc.cAlphaFieldNames[iHeatCAPMAlphaNum - 1] + " = " + s_ipsc.cAlphaArgs[iHeatCAPMAlphaNum - 1],
                    )
                    ShowContinueError(
                        state,
                        "Blank field not allowed for " + s_ipsc.cNumericFieldNames[iHeatFracOfAutosizedCapacityNumericNum - 1],
                    )
                    ErrorsFound = True
            else:
                ShowSevereError(state, cCurrentModuleObject + " = " + thisBaseboard.EquipName)
                ShowContinueError(
                    state,
                    "Illegal " + s_ipsc.cAlphaFieldNames[iHeatCAPMAlphaNum - 1] + " = " + s_ipsc.cAlphaArgs[iHeatCAPMAlphaNum - 1],
                )
                ErrorsFound = True
            thisBaseboard.ZonePtr = GetZoneEquipControlledZoneNum(
                state, ZoneEquipType.BaseboardConvectiveElectric, thisBaseboard.EquipName,
            )

        if ErrorsFound:
            ShowFatalError(state, RoutineName + "Errors found in getting input.  Preceding condition(s) cause termination.")

    for BaseboardNum in range(1, NumConvElecBaseboards + 1):
        var thisBaseboard = baseboard.baseboards[BaseboardNum - 1]
        SetupOutputVariable(
            state,
            "Baseboard Total Heating Energy",
            Units.J,
            thisBaseboard.Energy,
            TimeStepType.System,
            StoreType.Sum,
            thisBaseboard.EquipName,
            eResource.EnergyTransfer,
            Group.HVAC,
            EndUseCat.Baseboard,
        )
        SetupOutputVariable(
            state,
            "Baseboard Total Heating Rate",
            Units.W,
            thisBaseboard.Power,
            TimeStepType.System,
            StoreType.Average,
            thisBaseboard.EquipName,
        )
        SetupOutputVariable(
            state,
            "Baseboard Electricity Energy",
            Units.J,
            thisBaseboard.ElecUseLoad,
            TimeStepType.System,
            StoreType.Sum,
            thisBaseboard.EquipName,
            eResource.Electricity,
            Group.HVAC,
            EndUseCat.Heating,
        )
        SetupOutputVariable(
            state,
            "Baseboard Electricity Rate",
            Units.W,
            thisBaseboard.ElecUseRate,
            TimeStepType.System,
            StoreType.Average,
            thisBaseboard.EquipName,
        )

def InitBaseboard(state: EnergyPlusData, BaseboardNum: Int, ControlledZoneNum: Int):
    var baseboard = state.dataBaseboardElectric
    if not state.dataGlobal.SysSizingCalc and baseboard.baseboards[BaseboardNum - 1].MySizeFlag:
        SizeElectricBaseboard(state, BaseboardNum)
        baseboard.baseboards[BaseboardNum - 1].MySizeFlag = False

    baseboard.baseboards[BaseboardNum - 1].Energy = 0.0
    baseboard.baseboards[BaseboardNum - 1].Power = 0.0
    baseboard.baseboards[BaseboardNum - 1].ElecUseLoad = 0.0
    baseboard.baseboards[BaseboardNum - 1].ElecUseRate = 0.0

    var ZoneNode: Int = state.dataZoneEquip.ZoneEquipConfig[ControlledZoneNum - 1].ZoneNode
    baseboard.baseboards[BaseboardNum - 1].AirInletTemp = state.dataLoopNodes.Node[ZoneNode - 1].Temp
    baseboard.baseboards[BaseboardNum - 1].AirInletHumRat = state.dataLoopNodes.Node[ZoneNode - 1].HumRat

def SizeElectricBaseboard(state: EnergyPlusData, BaseboardNum: Int):
    var RoutineName: StringLiteral = "SizeElectricBaseboard"
    var TempSize: Float64

    state.dataSize.DataScalableCapSizingON = False
    if state.dataSize.CurZoneEqNum > 0:
        var ZoneEqSizing = state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum - 1]
        var baseboard = state.dataBaseboardElectric.baseboards[BaseboardNum - 1]
        var CompType: StringLiteral = baseboard.EquipType
        var CompName: StringLiteral = baseboard.EquipName
        state.dataSize.DataFracOfAutosizedHeatingCapacity = 1.0
        state.dataSize.DataZoneNumber = baseboard.ZonePtr
        var SizingMethod: Int = HeatingCapacitySizing
        var FieldNum: Int = 1
        var SizingString: String = baseboard.FieldNames[FieldNum - 1] + " [W]"
        var CapSizingMethod: Int = baseboard.HeatingCapMethod
        ZoneEqSizing.SizingMethod[SizingMethod - 1] = CapSizingMethod
        if CapSizingMethod == HeatingDesignCapacity or CapSizingMethod == CapacityPerFloorArea or CapSizingMethod == FractionOfAutosizedHeatingCapacity:
            if CapSizingMethod == HeatingDesignCapacity:
                if baseboard.ScaledHeatingCapacity == AutoSize:
                    CheckZoneSizing(state, CompType, CompName)
                    ZoneEqSizing.HeatingCapacity = True
                    ZoneEqSizing.DesHeatingLoad = state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].NonAirSysDesHeatLoad
                TempSize = baseboard.ScaledHeatingCapacity
            elif CapSizingMethod == CapacityPerFloorArea:
                ZoneEqSizing.HeatingCapacity = True
                ZoneEqSizing.DesHeatingLoad = baseboard.ScaledHeatingCapacity * state.dataHeatBal.Zone[state.dataSize.DataZoneNumber - 1].FloorArea
                TempSize = ZoneEqSizing.DesHeatingLoad
                state.dataSize.DataScalableCapSizingON = True
            elif CapSizingMethod == FractionOfAutosizedHeatingCapacity:
                CheckZoneSizing(state, CompType, CompName)
                ZoneEqSizing.HeatingCapacity = True
                state.dataSize.DataFracOfAutosizedHeatingCapacity = baseboard.ScaledHeatingCapacity
                ZoneEqSizing.DesHeatingLoad = state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].NonAirSysDesHeatLoad
                TempSize = AutoSize
                state.dataSize.DataScalableCapSizingON = True
            else:
                TempSize = baseboard.ScaledHeatingCapacity
            var PrintFlag: Bool = True
            var errorsFound: Bool = False
            var sizerHeatingCapacity = HeatingCapacitySizer()
            sizerHeatingCapacity.overrideSizingString(SizingString)
            sizerHeatingCapacity.initializeWithinEP(state, CompType, CompName, PrintFlag, RoutineName)
            baseboard.NominalCapacity = sizerHeatingCapacity.size(state, TempSize, errorsFound)
            state.dataSize.DataScalableCapSizingON = False

def SimElectricConvective(state: EnergyPlusData, BaseboardNum: Int, LoadMet: Float64):
    var AirOutletTemp: Float64
    var QBBCap: Float64
    var baseboard = state.dataBaseboardElectric.baseboards[BaseboardNum - 1]
    var AirInletTemp: Float64 = baseboard.AirInletTemp
    var CpAir: Float64 = PsyCpAirFnW(baseboard.AirInletHumRat)
    var AirMassFlowRate: Float64 = SimpConvAirFlowSpeed
    var CapacitanceAir: Float64 = CpAir * AirMassFlowRate
    var Effic: Float64 = baseboard.BaseboardEfficiency

    if baseboard.availSched.getCurrentVal() > 0.0 and LoadMet >= SmallLoad:
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