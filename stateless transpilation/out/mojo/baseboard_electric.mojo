from collections import Dict
from math import sqrt


struct BaseboardParams:
    var EquipName: String
    var EquipType: String
    var Schedule: String
    var availSched: Any
    var NominalCapacity: Float64
    var BaseboardEfficiency: Float64
    var AirInletTemp: Float64
    var AirInletHumRat: Float64
    var AirOutletTemp: Float64
    var Power: Float64
    var Energy: Float64
    var ElecUseLoad: Float64
    var ElecUseRate: Float64
    var ZonePtr: Int
    var HeatingCapMethod: Int
    var ScaledHeatingCapacity: Float64
    var MySizeFlag: Bool
    var CheckEquipName: Bool
    var FieldNames: List[String]

    fn __init__(inout self):
        self.EquipName = ""
        self.EquipType = ""
        self.Schedule = ""
        self.availSched = None
        self.NominalCapacity = 0.0
        self.BaseboardEfficiency = 0.0
        self.AirInletTemp = 0.0
        self.AirInletHumRat = 0.0
        self.AirOutletTemp = 0.0
        self.Power = 0.0
        self.Energy = 0.0
        self.ElecUseLoad = 0.0
        self.ElecUseRate = 0.0
        self.ZonePtr = 0
        self.HeatingCapMethod = 0
        self.ScaledHeatingCapacity = 0.0
        self.MySizeFlag = True
        self.CheckEquipName = True
        self.FieldNames = List[String]()


alias CMO_BBRadiator_Electric = "ZoneHVAC:Baseboard:Convective:Electric"
alias SimpConvAirFlowSpeed = 0.5


fn SimElectricBaseboard(inout state: EnergyPlusData, EquipName: String, ControlledZoneNum: Int, inout CompIndex: Int) -> Float64:
    """
    Simulates the Electric Baseboard units.
    """
    if state.dataBaseboardElectric.getInputFlag:
        GetBaseboardInput(state)
        state.dataBaseboardElectric.getInputFlag = False

    var baseboard = state.dataBaseboardElectric
    var BaseboardNum: Int = 0

    if CompIndex == 0:
        BaseboardNum = Util.FindItemInList(EquipName, baseboard.baseboards)
        if BaseboardNum == 0:
            ShowFatalError(state, "SimElectricBaseboard: Unit not found=" + EquipName)
        CompIndex = BaseboardNum
    else:
        BaseboardNum = CompIndex
        var numBaseboards: Int = len(baseboard.baseboards)
        if BaseboardNum > numBaseboards or BaseboardNum < 1:
            ShowFatalError(state, 
                "SimElectricBaseboard:  Invalid CompIndex passed=" + str(BaseboardNum) + 
                ", Number of Units=" + str(numBaseboards) + 
                ", Entered Unit name=" + EquipName)
        if baseboard.baseboards[BaseboardNum - 1].CheckEquipName:
            if EquipName != baseboard.baseboards[BaseboardNum - 1].EquipName:
                ShowFatalError(state,
                    "SimElectricBaseboard: Invalid CompIndex passed=" + str(BaseboardNum) + 
                    ", Unit name=" + EquipName + 
                    ", stored Unit Name for that index=" + baseboard.baseboards[BaseboardNum - 1].EquipName)
            baseboard.baseboards[BaseboardNum - 1].CheckEquipName = False

    InitBaseboard(state, BaseboardNum, ControlledZoneNum)

    var QZnReq: Float64 = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ControlledZoneNum].RemainingOutputReqToHeatSP

    SimElectricConvective(state, BaseboardNum, QZnReq)

    var PowerMet: Float64 = baseboard.baseboards[BaseboardNum - 1].Power

    baseboard.baseboards[BaseboardNum - 1].Energy = baseboard.baseboards[BaseboardNum - 1].Power * state.dataHVACGlobal.TimeStepSysSec
    baseboard.baseboards[BaseboardNum - 1].ElecUseLoad = baseboard.baseboards[BaseboardNum - 1].ElecUseRate * state.dataHVACGlobal.TimeStepSysSec

    return PowerMet


fn GetBaseboardInput(inout state: EnergyPlusData) -> None:
    """
    Gets the input for the Baseboard units.
    """
    var baseboard = state.dataBaseboardElectric
    var cCurrentModuleObject: String = CMO_BBRadiator_Electric

    var NumConvElecBaseboards: Int = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, cCurrentModuleObject)

    baseboard.baseboards = List[BaseboardParams](capacity=NumConvElecBaseboards)

    if NumConvElecBaseboards > 0:
        var ErrorsFound: Bool = False
        var s_ipsc = state.dataIPShortCut
        
        for ConvElecBBNum in range(1, NumConvElecBaseboards + 1):
            var NumAlphas: Int = 0
            var NumNums: Int = 0
            var IOStat: Int = 0
            
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

            var BaseboardNum: Int = ConvElecBBNum
            var thisBaseboard = BaseboardParams()
            thisBaseboard.FieldNames = List[String](s_ipsc.cNumericFieldNames)

            var eoh = ErrorObjectHeader("GetBaseboardInput", cCurrentModuleObject, s_ipsc.cAlphaArgs[0])
            
            VerifyUniqueBaseboardName(
                state, cCurrentModuleObject, s_ipsc.cAlphaArgs[0], ErrorsFound,
                cCurrentModuleObject + " Name")

            thisBaseboard.EquipName = s_ipsc.cAlphaArgs[0]
            thisBaseboard.EquipType = Util.makeUPPER(cCurrentModuleObject)
            thisBaseboard.Schedule = s_ipsc.cAlphaArgs[1]
            
            if s_ipsc.lAlphaFieldBlanks[1]:
                thisBaseboard.availSched = Sched.GetScheduleAlwaysOn(state)
            else:
                thisBaseboard.availSched = Sched.GetSchedule(state, s_ipsc.cAlphaArgs[1])
                if thisBaseboard.availSched == None:
                    ShowSevereItemNotFound(state, eoh, s_ipsc.cAlphaFieldNames[1], s_ipsc.cAlphaArgs[1])
                    ErrorsFound = True

            thisBaseboard.BaseboardEfficiency = s_ipsc.rNumericArgs[3]

            var iHeatCAPMAlphaNum: Int = 2
            var iHeatDesignCapacityNumericNum: Int = 0
            var iHeatCapacityPerFloorAreaNumericNum: Int = 1
            var iHeatFracOfAutosizedCapacityNumericNum: Int = 2

            if Util.SameString(s_ipsc.cAlphaArgs[iHeatCAPMAlphaNum], "HeatingDesignCapacity"):
                thisBaseboard.HeatingCapMethod = 1
                if not s_ipsc.lNumericFieldBlanks[iHeatDesignCapacityNumericNum]:
                    thisBaseboard.ScaledHeatingCapacity = s_ipsc.rNumericArgs[iHeatDesignCapacityNumericNum]
                    if thisBaseboard.ScaledHeatingCapacity < 0.0 and thisBaseboard.ScaledHeatingCapacity != -999.0:
                        ShowSevereError(state, cCurrentModuleObject + " = " + thisBaseboard.EquipName)
                        ShowContinueError(state,
                            "Illegal " + s_ipsc.cNumericFieldNames[iHeatDesignCapacityNumericNum] + 
                            " = " + str(s_ipsc.rNumericArgs[iHeatDesignCapacityNumericNum]))
                        ErrorsFound = True
                else:
                    ShowSevereError(state, cCurrentModuleObject + " = " + thisBaseboard.EquipName)
                    ShowContinueError(state,
                        "Input for " + s_ipsc.cAlphaFieldNames[iHeatCAPMAlphaNum] + " = " + 
                        s_ipsc.cAlphaArgs[iHeatCAPMAlphaNum])
                    ShowContinueError(state,
                        "Blank field not allowed for " + s_ipsc.cNumericFieldNames[iHeatDesignCapacityNumericNum])
                    ErrorsFound = True
            elif Util.SameString(s_ipsc.cAlphaArgs[iHeatCAPMAlphaNum], "CapacityPerFloorArea"):
                thisBaseboard.HeatingCapMethod = 2
                if not s_ipsc.lNumericFieldBlanks[iHeatCapacityPerFloorAreaNumericNum]:
                    thisBaseboard.ScaledHeatingCapacity = s_ipsc.rNumericArgs[iHeatCapacityPerFloorAreaNumericNum]
                    if thisBaseboard.ScaledHeatingCapacity <= 0.0:
                        ShowSevereError(state, cCurrentModuleObject + " = " + thisBaseboard.EquipName)
                        ShowContinueError(state,
                            "Input for " + s_ipsc.cAlphaFieldNames[iHeatCAPMAlphaNum] + " = " + 
                            s_ipsc.cAlphaArgs[iHeatCAPMAlphaNum])
                        ShowContinueError(state,
                            "Illegal " + s_ipsc.cNumericFieldNames[iHeatCapacityPerFloorAreaNumericNum] + 
                            " = " + str(s_ipsc.rNumericArgs[iHeatCapacityPerFloorAreaNumericNum]))
                        ErrorsFound = True
                    elif thisBaseboard.ScaledHeatingCapacity == -999.0:
                        ShowSevereError(state, cCurrentModuleObject + " = " + thisBaseboard.EquipName)
                        ShowContinueError(state,
                            "Input for " + s_ipsc.cAlphaFieldNames[iHeatCAPMAlphaNum] + " = " + 
                            s_ipsc.cAlphaArgs[iHeatCAPMAlphaNum])
                        ShowContinueError(state,
                            "Illegal " + s_ipsc.cNumericFieldNames[iHeatCapacityPerFloorAreaNumericNum] + " = AutoSize")
                        ErrorsFound = True
                else:
                    ShowSevereError(state, cCurrentModuleObject + " = " + thisBaseboard.EquipName)
                    ShowContinueError(state,
                        "Input for " + s_ipsc.cAlphaFieldNames[iHeatCAPMAlphaNum] + " = " + 
                        s_ipsc.cAlphaArgs[iHeatCAPMAlphaNum])
                    ShowContinueError(state,
                        "Blank field not allowed for " + s_ipsc.cNumericFieldNames[iHeatCapacityPerFloorAreaNumericNum])
                    ErrorsFound = True
            elif Util.SameString(s_ipsc.cAlphaArgs[iHeatCAPMAlphaNum], "FractionOfAutosizedHeatingCapacity"):
                thisBaseboard.HeatingCapMethod = 3
                if not s_ipsc.lNumericFieldBlanks[iHeatFracOfAutosizedCapacityNumericNum]:
                    thisBaseboard.ScaledHeatingCapacity = s_ipsc.rNumericArgs[iHeatFracOfAutosizedCapacityNumericNum]
                    if thisBaseboard.ScaledHeatingCapacity < 0.0:
                        ShowSevereError(state, cCurrentModuleObject + " = " + thisBaseboard.EquipName)
                        ShowContinueError(state,
                            "Illegal " + s_ipsc.cNumericFieldNames[iHeatFracOfAutosizedCapacityNumericNum] + 
                            " = " + str(s_ipsc.rNumericArgs[iHeatFracOfAutosizedCapacityNumericNum]))
                        ErrorsFound = True
                else:
                    ShowSevereError(state, cCurrentModuleObject + " = " + thisBaseboard.EquipName)
                    ShowContinueError(state,
                        "Input for " + s_ipsc.cAlphaFieldNames[iHeatCAPMAlphaNum] + " = " + 
                        s_ipsc.cAlphaArgs[iHeatCAPMAlphaNum])
                    ShowContinueError(state,
                        "Blank field not allowed for " + s_ipsc.cNumericFieldNames[iHeatFracOfAutosizedCapacityNumericNum])
                    ErrorsFound = True
            else:
                ShowSevereError(state, cCurrentModuleObject + " = " + thisBaseboard.EquipName)
                ShowContinueError(state,
                    "Illegal " + s_ipsc.cAlphaFieldNames[iHeatCAPMAlphaNum] + " = " + 
                    s_ipsc.cAlphaArgs[iHeatCAPMAlphaNum])
                ErrorsFound = True

            thisBaseboard.ZonePtr = DataZoneEquipment.GetZoneEquipControlledZoneNum(
                state, DataZoneEquipment.ZoneEquipType.BaseboardConvectiveElectric, thisBaseboard.EquipName)

            baseboard.baseboards.append(thisBaseboard)

        if ErrorsFound:
            ShowFatalError(state, "GetBaseboardInput: Errors found in getting input.  Preceding condition(s) cause termination.")

    for BaseboardNum in range(1, NumConvElecBaseboards + 1):
        var thisBaseboard = baseboard.baseboards[BaseboardNum - 1]
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


fn InitBaseboard(inout state: EnergyPlusData, BaseboardNum: Int, ControlledZoneNum: Int) -> None:
    """
    Initializes the Baseboard units during simulation.
    """
    var baseboard = state.dataBaseboardElectric

    if not state.dataGlobal.SysSizingCalc and baseboard.baseboards[BaseboardNum - 1].MySizeFlag:
        SizeElectricBaseboard(state, BaseboardNum)
        baseboard.baseboards[BaseboardNum - 1].MySizeFlag = False

    baseboard.baseboards[BaseboardNum - 1].Energy = 0.0
    baseboard.baseboards[BaseboardNum - 1].Power = 0.0
    baseboard.baseboards[BaseboardNum - 1].ElecUseLoad = 0.0
    baseboard.baseboards[BaseboardNum - 1].ElecUseRate = 0.0

    var ZoneNode: Int = state.dataZoneEquip.ZoneEquipConfig[ControlledZoneNum].ZoneNode
    baseboard.baseboards[BaseboardNum - 1].AirInletTemp = state.dataLoopNodes.Node[ZoneNode].Temp
    baseboard.baseboards[BaseboardNum - 1].AirInletHumRat = state.dataLoopNodes.Node[ZoneNode].HumRat


fn SizeElectricBaseboard(inout state: EnergyPlusData, BaseboardNum: Int) -> None:
    """
    Sizes the electric baseboard component.
    """
    var TempSize: Float64 = 0.0
    state.dataSize.DataScalableCapSizingON = False

    if state.dataSize.CurZoneEqNum > 0:
        var ZoneEqSizing = state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum]
        var baseboard = state.dataBaseboardElectric.baseboards[BaseboardNum - 1]

        var CompType: String = baseboard.EquipType
        var CompName: String = baseboard.EquipName
        state.dataSize.DataFracOfAutosizedHeatingCapacity = 1.0
        state.dataSize.DataZoneNumber = baseboard.ZonePtr
        var SizingMethod: Int = HVAC.HeatingCapacitySizing
        var FieldNum: Int = 1
        var SizingString: String = baseboard.FieldNames[FieldNum - 1] + " [W]"
        var CapSizingMethod: Int = baseboard.HeatingCapMethod
        ZoneEqSizing.SizingMethod[SizingMethod] = CapSizingMethod

        if CapSizingMethod == 1 or CapSizingMethod == 2 or CapSizingMethod == 3:
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

            var PrintFlag: Bool = True
            var errorsFound: Bool = False
            var sizerHeatingCapacity = HeatingCapacitySizer()
            sizerHeatingCapacity.overrideSizingString(SizingString)
            sizerHeatingCapacity.initializeWithinEP(state, CompType, CompName, PrintFlag, "SizeElectricBaseboard")
            baseboard.NominalCapacity = sizerHeatingCapacity.size(state, TempSize, errorsFound)
            state.dataSize.DataScalableCapSizingON = False


fn SimElectricConvective(inout state: EnergyPlusData, BaseboardNum: Int, LoadMet: Float64) -> None:
    """
    Calculates heat exchange rate in electric convective baseboard heater.
    """
    var baseboard = state.dataBaseboardElectric.baseboards[BaseboardNum - 1]

    var AirInletTemp: Float64 = baseboard.AirInletTemp
    var CpAir: Float64 = Psychrometrics.PsyCpAirFnW(baseboard.AirInletHumRat)
    var AirMassFlowRate: Float64 = SimpConvAirFlowSpeed
    var CapacitanceAir: Float64 = CpAir * AirMassFlowRate
    var Effic: Float64 = baseboard.BaseboardEfficiency

    if baseboard.availSched.getCurrentVal() > 0.0 and LoadMet >= HVAC.SmallLoad:
        var QBBCap: Float64
        if LoadMet > baseboard.NominalCapacity:
            QBBCap = baseboard.NominalCapacity
        else:
            QBBCap = LoadMet

        var AirOutletTemp: Float64 = AirInletTemp + QBBCap / CapacitanceAir
        baseboard.ElecUseRate = QBBCap / Effic
        baseboard.AirOutletTemp = AirOutletTemp
        baseboard.Power = QBBCap
    else:
        var AirOutletTemp: Float64 = AirInletTemp
        var QBBCap: Float64 = 0.0
        baseboard.ElecUseRate = 0.0
        baseboard.AirOutletTemp = AirOutletTemp
        baseboard.Power = QBBCap


struct BaseboardElectricData:
    var getInputFlag: Bool
    var baseboards: List[BaseboardParams]

    fn __init__(inout self):
        self.getInputFlag = True
        self.baseboards = List[BaseboardParams]()

    fn init_constant_state(inout self, inout state: EnergyPlusData) -> None:
        pass

    fn init_state(inout self, inout state: EnergyPlusData) -> None:
        pass

    fn clear_state(inout self) -> None:
        self.getInputFlag = True
        self.baseboards = List[BaseboardParams]()
