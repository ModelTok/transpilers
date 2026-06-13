from Data.BaseData import BaseGlobalStruct
from Data.EnergyPlusData import EnergyPlusData
from DataEnvironment import *
from DataHeatBalFanSys import *
from DataHeatBalance import *
from DataIPShortCuts import *
from DataRoomAirModel import *
from DataRuntimeLanguage import *
from DataStringGlobals import *
from DataViewFactorInformation import *
from DataZoneControls import *
from DataZoneEquipment import *
from EMSManager import *
from General import *
from GeneralRoutines import *
from GlobalNames import *
from HVACManager import *
from InputProcessing.InputProcessor import *
from InternalHeatGains import *
from OutputProcessor import *
from Psychrometrics import *
from ScheduleManager import *
from SystemAvailabilityManager import *
from UtilityRoutines import *
from ZoneTempPredictorCorrector import *
from HeatBalanceAirManager import *

from memory import UnsafePointer
from utils import StringRef, String
from math import max
from sys import print

alias Real64 = Float64

enum AirflowSpec(Int32):
    Invalid = -1
    FlowPerZone = 0
    FlowPerArea = 1
    FlowPerExteriorArea = 2
    FlowPerExteriorWallArea = 3
    FlowPerPerson = 4
    AirChanges = 5
    Num = 6

var airflowSpecNamesUC = StaticTuple[StringRef, 6](
    "FLOW/ZONE", "FLOW/AREA", "FLOW/EXTERIORAREA", "FLOW/EXTERIORWALLAREA", "FLOW/PERSON", "AIRCHANGES/HOUR"
)

var ventilationTypeNamesUC = StaticTuple[StringRef, 4](
    "NATURAL", "INTAKE", "EXHAUST", "BALANCED"
)

var infVentDensityBasisNamesUC = StaticTuple[StringRef, 3](
    "OUTDOOR", "STANDARD", "INDOOR"
)

var roomAirModelNamesUC = StaticTuple[StringRef, 8](
    "USERDEFINED",
    "MIXING",
    "ONENODEDISPLACEMENTVENTILATION",
    "THREENODEDISPLACEMENTVENTILATION",
    "CROSSVENTILATION",
    "UNDERFLOORAIRDISTRIBUTIONINTERIOR",
    "UNDERFLOORAIRDISTRIBUTIONEXTERIOR",
    "AIRFLOWNETWORK"
)

var couplingSchemeNamesUC = StaticTuple[StringRef, 2](
    "DIRECT", "INDIRECT"
)

def ManageAirHeatBalance(inout state: EnergyPlusData):
    if state.dataHeatBalAirMgr.ManageAirHeatBalanceGetInputFlag:
        GetAirHeatBalanceInput(state)
        state.dataHeatBalAirMgr.ManageAirHeatBalanceGetInputFlag = False
    InitAirHeatBalance(state)
    CalcHeatBalanceAir(state)
    ReportZoneMeanAirTemp(state)

def GetAirHeatBalanceInput(inout state: EnergyPlusData):
    var ErrorsFound = False
    GetAirFlowFlag(state, ErrorsFound)
    SetZoneMassConservationFlag(state)
    GetRoomAirModelParameters(state, ErrorsFound)
    if ErrorsFound:
        ShowFatalError(state, "GetAirHeatBalanceInput: Errors found in getting Air inputs")

def GetAirFlowFlag(inout state: EnergyPlusData, inout ErrorsFound: Bool):
    state.dataHeatBal.AirFlowFlag = True
    GetSimpleAirModelInputs(state, ErrorsFound)
    if state.dataHeatBal.TotInfiltration + state.dataHeatBal.TotVentilation + state.dataHeatBal.TotMixing + state.dataHeatBal.TotCrossMixing + state.dataHeatBal.TotRefDoorMixing > 0:
        var Format_720 = "! <AirFlow Model>, Simple\n AirFlow Model, {}\n"
        print(state.files.eio, Format_720, "Simple")

def SetZoneMassConservationFlag(inout state: EnergyPlusData):
    if state.dataHeatBal.ZoneAirMassFlow.EnforceZoneMassBalance and state.dataHeatBal.ZoneAirMassFlow.ZoneFlowAdjustment != DataHeatBalance.AdjustmentType.NoAdjustReturnAndMixing:
        for Loop in range(1, state.dataHeatBal.TotMixing + 1):
            state.dataHeatBalFanSys.ZoneMassBalanceFlag[state.dataHeatBal.Mixing[Loop].ZonePtr] = True
            state.dataHeatBalFanSys.ZoneMassBalanceFlag[state.dataHeatBal.Mixing[Loop].FromZone] = True

def GetSimpleAirModelInputs(inout state: EnergyPlusData, inout ErrorsFound: Bool):
    var VentilTempLimit: Real64 = 100.0
    var MixingTempLimit: Real64 = 100.0
    var VentilWSLimit: Real64 = 40.0
    var RoutineName = "GetSimpleAirModelInputs: "
    var routineName = "GetSimpleAirModelInputs"
    var RefDoorNone: Real64 = 0.0
    var RefDoorAirCurtain: Real64 = 0.5
    var RefDoorStripCurtain: Real64 = 0.9
    var NumAlpha: Int32
    var NumNumber: Int32
    var NumArgs: Int32
    var IOStat: Int32
    var cAlphaFieldNames: Array1D_string
    var cNumericFieldNames: Array1D_string
    var lNumericFieldBlanks: Array1D_bool
    var lAlphaFieldBlanks: Array1D_bool
    var cAlphaArgs: Array1D_string
    var rNumericArgs: Array1D[Real64]
    var RepVarSet: Array1D_bool
    var StringOut: String
    var NameThisObject: String
    var TotInfilVentFlow: Array1D[Real64]
    var TotMixingFlow: Array1D[Real64]
    var ZoneMixingNum: Array1D[Real64]
    var ConnectionNumber: Int32
    var ZoneNumA: Int32
    var ZoneNumB: Int32
    var Format_720 = " {} Airflow Stats Nominal, {},{},{},{},{:.2f},{:.2f},"
    var Format_721 = "! <{} Airflow Stats Nominal>,Name,Input Object, Schedule Name,Zone Name, Zone Floor Area {{m2}}, # Zone Occupants,{}\n"
    var Format_722 = " {}, {}\n"
    RepVarSet.dimension(state.dataGlobal.NumOfZones, True)
    state.dataHeatBal.ZnAirRpt.allocate(state.dataGlobal.NumOfZones)
    if state.dataHeatBal.doSpaceHeatBalanceSizing or state.dataHeatBal.doSpaceHeatBalanceSimulation:
        state.dataHeatBal.spaceAirRpt.allocate(state.dataGlobal.numSpaces)
    for Loop in range(1, state.dataGlobal.NumOfZones + 1):
        var name = state.dataHeatBal.Zone[Loop].Name
        var thisZnAirRpt = state.dataHeatBal.ZnAirRpt[Loop]
        thisZnAirRpt.setUpOutputVars(state, DataStringGlobals.zonePrefix, name)
        if state.dataHeatBal.doSpaceHeatBalanceSimulation:
            for spaceNum in state.dataHeatBal.Zone[Loop].spaceIndexes:
                state.dataHeatBal.spaceAirRpt[spaceNum].setUpOutputVars(state, DataStringGlobals.spacePrefix, state.dataHeatBal.space[spaceNum].Name)
        if state.dataGlobal.DisplayAdvancedReportVariables:
            SetupOutputVariable(state, "Zone Phase Change Material Melting Enthalpy", Constant.Units.J_kg, thisZnAirRpt.SumEnthalpyM, OutputProcessor.TimeStepType.Zone, OutputProcessor.StoreType.Average, name)
            SetupOutputVariable(state, "Zone Phase Change Material Freezing Enthalpy", Constant.Units.J_kg, thisZnAirRpt.SumEnthalpyH, OutputProcessor.TimeStepType.Zone, OutputProcessor.StoreType.Average, name)
        SetupOutputVariable(state, "Zone Exfiltration Heat Transfer Rate", Constant.Units.W, thisZnAirRpt.ExfilTotalLoss, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, name)
        SetupOutputVariable(state, "Zone Exfiltration Sensible Heat Transfer Rate", Constant.Units.W, thisZnAirRpt.ExfilSensiLoss, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, name)
        SetupOutputVariable(state, "Zone Exfiltration Latent Heat Transfer Rate", Constant.Units.W, thisZnAirRpt.ExfilLatentLoss, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, name)
        SetupOutputVariable(state, "Zone Exhaust Air Heat Transfer Rate", Constant.Units.W, thisZnAirRpt.ExhTotalLoss, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, name)
        SetupOutputVariable(state, "Zone Exhaust Air Sensible Heat Transfer Rate", Constant.Units.W, thisZnAirRpt.ExhSensiLoss, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, name)
        SetupOutputVariable(state, "Zone Exhaust Air Latent Heat Transfer Rate", Constant.Units.W, thisZnAirRpt.ExhLatentLoss, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, name)
    SetupOutputVariable(state, "Site Total Zone Exfiltration Heat Loss", Constant.Units.J, state.dataHeatBal.ZoneTotalExfiltrationHeatLoss, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, "Environment")
    SetupOutputVariable(state, "Site Total Zone Exhaust Air Heat Loss", Constant.Units.J, state.dataHeatBal.ZoneTotalExhaustHeatLoss, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, "Environment")
    var cCurrentModuleObject = "ZoneAirBalance:OutdoorAir"
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, cCurrentModuleObject, NumArgs, NumAlpha, NumNumber)
    var maxAlpha = NumAlpha
    var maxNumber = NumNumber
    cCurrentModuleObject = "ZoneInfiltration:EffectiveLeakageArea"
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, cCurrentModuleObject, NumArgs, NumAlpha, NumNumber)
    maxAlpha = max(NumAlpha, maxAlpha)
    maxNumber = max(NumNumber, maxNumber)
    cCurrentModuleObject = "ZoneInfiltration:FlowCoefficient"
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, cCurrentModuleObject, NumArgs, NumAlpha, NumNumber)
    maxAlpha = max(NumAlpha, maxAlpha)
    maxNumber = max(NumNumber, maxNumber)
    cCurrentModuleObject = "ZoneInfiltration:DesignFlowRate"
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, cCurrentModuleObject, NumArgs, NumAlpha, NumNumber)
    maxAlpha = max(NumAlpha, maxAlpha)
    maxNumber = max(NumNumber, maxNumber)
    cCurrentModuleObject = "ZoneVentilation:DesignFlowRate"
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, cCurrentModuleObject, NumArgs, NumAlpha, NumNumber)
    maxAlpha = max(NumAlpha, maxAlpha)
    maxNumber = max(NumNumber, maxNumber)
    cCurrentModuleObject = "ZoneVentilation:WindandStackOpenArea"
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, cCurrentModuleObject, NumArgs, NumAlpha, NumNumber)
    maxAlpha = max(NumAlpha, maxAlpha)
    maxNumber = max(NumNumber, maxNumber)
    cCurrentModuleObject = "ZoneMixing"
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, cCurrentModuleObject, NumArgs, NumAlpha, NumNumber)
    maxAlpha = max(NumAlpha, maxAlpha)
    maxNumber = max(NumNumber, maxNumber)
    cCurrentModuleObject = "ZoneCrossMixing"
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, cCurrentModuleObject, NumArgs, NumAlpha, NumNumber)
    maxAlpha = max(NumAlpha, maxAlpha)
    maxNumber = max(NumNumber, maxNumber)
    cCurrentModuleObject = "ZoneRefrigerationDoorMixing"
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, cCurrentModuleObject, NumArgs, NumAlpha, NumNumber)
    maxAlpha = max(NumAlpha, maxAlpha)
    maxNumber = max(NumNumber, maxNumber)
    cAlphaArgs.allocate(maxAlpha)
    cAlphaFieldNames.allocate(maxAlpha)
    cNumericFieldNames.allocate(maxNumber)
    rNumericArgs.dimension(maxNumber, 0.0)
    lAlphaFieldBlanks.dimension(maxAlpha, True)
    lNumericFieldBlanks.dimension(maxNumber, True)
    cCurrentModuleObject = "ZoneAirBalance:OutdoorAir"
    state.dataHeatBal.TotZoneAirBalance = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, cCurrentModuleObject)
    state.dataHeatBal.ZoneAirBalance.allocate(state.dataHeatBal.TotZoneAirBalance)
    for Loop in range(1, state.dataHeatBal.TotZoneAirBalance + 1):
        state.dataInputProcessing.inputProcessor.getObjectItem(state, cCurrentModuleObject, Loop, cAlphaArgs, NumAlpha, rNumericArgs, NumNumber, IOStat, lNumericFieldBlanks, lAlphaFieldBlanks, cAlphaFieldNames, cNumericFieldNames)
        var eoh = ErrorObjectHeader(routineName, cCurrentModuleObject, cAlphaArgs[1])
        var IsNotOK = False
        var thisZoneAirBalance = state.dataHeatBal.ZoneAirBalance[Loop]
        thisZoneAirBalance.Name = cAlphaArgs[1]
        thisZoneAirBalance.ZoneName = cAlphaArgs[2]
        thisZoneAirBalance.ZonePtr = Util.FindItemInList(cAlphaArgs[2], state.dataHeatBal.Zone)
        if thisZoneAirBalance.ZonePtr == 0:
            ShowSevereError(state, "{}" + cCurrentModuleObject + "=\"{}\", invalid (not found) {}" + "=\"{}\".".format(RoutineName, cAlphaArgs[1], cAlphaFieldNames[2], cAlphaArgs[2]))
            ErrorsFound = True
        else:
            state.dataHeatBal.Zone[thisZoneAirBalance.ZonePtr].zoneOABalanceIndex = Loop
        GlobalNames.IntraObjUniquenessCheck(state, cAlphaArgs[2], cCurrentModuleObject, cAlphaFieldNames[2], state.dataHeatBalAirMgr.UniqueZoneNames, IsNotOK)
        if IsNotOK:
            ShowSevereError(state, "{}" + cCurrentModuleObject + "=\"{}\", a duplicated object {}" + "=\"{}\" is found.".format(RoutineName, cAlphaArgs[1], cAlphaFieldNames[2], cAlphaArgs[2]))
            ShowContinueError(state, "A zone can only have one {} object.".format(cCurrentModuleObject))
            ErrorsFound = True
        thisZoneAirBalance.BalanceMethod = DataHeatBalance.AirBalance(getEnumValue(DataHeatBalance.AirBalanceTypeNamesUC, Util.makeUPPER(cAlphaArgs[3])))
        if thisZoneAirBalance.BalanceMethod == DataHeatBalance.AirBalance.Invalid:
            thisZoneAirBalance.BalanceMethod = DataHeatBalance.AirBalance.None
            ShowWarningError(state, "{}{} = {} not valid choice for {}={}".format(RoutineName, cAlphaFieldNames[3], cAlphaArgs[3], cCurrentModuleObject, cAlphaArgs[1]))
            ShowContinueError(state, "The default choice \"NONE\" is assigned")
        thisZoneAirBalance.InducedAirRate = rNumericArgs[1]
        if rNumericArgs[1] < 0.0:
            ShowSevereError(state, "{}{}=\"{}\", invalid Induced Outdoor Air Due to Duct Leakage Unbalance specification [<0.0]={:#G}".format(RoutineName, cCurrentModuleObject, cAlphaArgs[1], rNumericArgs[1]))
            ErrorsFound = True
        if lAlphaFieldBlanks[4]:
            ShowSevereEmptyField(state, eoh, cAlphaFieldNames[4])
        elif (thisZoneAirBalance.inducedAirSched = Sched.GetSchedule(state, cAlphaArgs[4])) == None:
            ShowSevereItemNotFound(state, eoh, cAlphaFieldNames[4], cAlphaArgs[4])
            ErrorsFound = True
        elif not thisZoneAirBalance.inducedAirSched.checkMinMaxVals(state, Clusive.In, 0.0, Clusive.In, 1.0):
            Sched.ShowSevereBadMinMax(state, eoh, cAlphaFieldNames[4], cAlphaArgs[4], Clusive.In, 0.0, Clusive.In, 1.0)
            ErrorsFound = True
        var ControlFlag = Avail.GetHybridVentilationControlStatus(state, thisZoneAirBalance.ZonePtr)
        if ControlFlag and thisZoneAirBalance.BalanceMethod == DataHeatBalance.AirBalance.Quadrature:
            thisZoneAirBalance.BalanceMethod = DataHeatBalance.AirBalance.None
            ShowWarningError(state, "{} = {}: This Zone ({}) is controlled by AvailabilityManager:HybridVentilation with Simple Airflow Control Type option.".format(cCurrentModuleObject, thisZoneAirBalance.Name, cAlphaArgs[2]))
            ShowContinueError(state, "Air balance method type QUADRATURE and Simple Airflow Control Type cannot co-exist. The NONE method is assigned")
        if thisZoneAirBalance.BalanceMethod == DataHeatBalance.AirBalance.Quadrature:
            state.dataHeatBal.Zone[thisZoneAirBalance.ZonePtr].zoneOAQuadratureSum = True
            SetupOutputVariable(state, "Zone Combined Outdoor Air Sensible Heat Loss Energy", Constant.Units.J, state.dataHeatBal.ZnAirRpt[thisZoneAirBalance.ZonePtr].OABalanceHeatLoss, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, state.dataHeatBal.Zone[thisZoneAirBalance.ZonePtr].Name)
            SetupOutputVariable(state, "Zone Combined Outdoor Air Sensible Heat Gain Energy", Constant.Units.J, state.dataHeatBal.ZnAirRpt[thisZoneAirBalance.ZonePtr].OABalanceHeatGain, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, state.dataHeatBal.Zone[thisZoneAirBalance.ZonePtr].Name)
            SetupOutputVariable(state, "Zone Combined Outdoor Air Latent Heat Loss Energy", Constant.Units.J, state.dataHeatBal.ZnAirRpt[thisZoneAirBalance.ZonePtr].OABalanceLatentLoss, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, state.dataHeatBal.Zone[thisZoneAirBalance.ZonePtr].Name)
            SetupOutputVariable(state, "Zone Combined Outdoor Air Latent Heat Gain Energy", Constant.Units.J, state.dataHeatBal.ZnAirRpt[thisZoneAirBalance.ZonePtr].OABalanceLatentGain, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, state.dataHeatBal.Zone[thisZoneAirBalance.ZonePtr].Name)
            SetupOutputVariable(state, "Zone Combined Outdoor Air Total Heat Loss Energy", Constant.Units.J, state.dataHeatBal.ZnAirRpt[thisZoneAirBalance.ZonePtr].OABalanceTotalLoss, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, state.dataHeatBal.Zone[thisZoneAirBalance.ZonePtr].Name)
            SetupOutputVariable(state, "Zone Combined Outdoor Air Total Heat Gain Energy", Constant.Units.J, state.dataHeatBal.ZnAirRpt[thisZoneAirBalance.ZonePtr].OABalanceTotalGain, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, state.dataHeatBal.Zone[thisZoneAirBalance.ZonePtr].Name)
            SetupOutputVariable(state, "Zone Combined Outdoor Air Current Density Volume Flow Rate", Constant.Units.m3_s, state.dataHeatBal.ZnAirRpt[thisZoneAirBalance.ZonePtr].OABalanceVdotCurDensity, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, state.dataHeatBal.Zone[thisZoneAirBalance.ZonePtr].Name)
            SetupOutputVariable(state, "Zone Combined Outdoor Air Standard Density Volume Flow Rate", Constant.Units.m3_s, state.dataHeatBal.ZnAirRpt[thisZoneAirBalance.ZonePtr].OABalanceVdotStdDensity, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, state.dataHeatBal.Zone[thisZoneAirBalance.ZonePtr].Name)
            SetupOutputVariable(state, "Zone Combined Outdoor Air Current Density Volume", Constant.Units.m3, state.dataHeatBal.ZnAirRpt[thisZoneAirBalance.ZonePtr].OABalanceVolumeCurDensity, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, state.dataHeatBal.Zone[thisZoneAirBalance.ZonePtr].Name)
            SetupOutputVariable(state, "Zone Combined Outdoor Air Standard Density Volume", Constant.Units.m3, state.dataHeatBal.ZnAirRpt[thisZoneAirBalance.ZonePtr].OABalanceVolumeStdDensity, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, state.dataHeatBal.Zone[thisZoneAirBalance.ZonePtr].Name)
            SetupOutputVariable(state, "Zone Combined Outdoor Air Mass", Constant.Units.kg, state.dataHeatBal.ZnAirRpt[thisZoneAirBalance.ZonePtr].OABalanceMass, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, state.dataHeatBal.Zone[thisZoneAirBalance.ZonePtr].Name)
            SetupOutputVariable(state, "Zone Combined Outdoor Air Mass Flow Rate", Constant.Units.kg_s, state.dataHeatBal.ZnAirRpt[thisZoneAirBalance.ZonePtr].OABalanceMdot, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, state.dataHeatBal.Zone[thisZoneAirBalance.ZonePtr].Name)
            SetupOutputVariable(state, "Zone Combined Outdoor Air Changes per Hour", Constant.Units.ach, state.dataHeatBal.ZnAirRpt[thisZoneAirBalance.ZonePtr].OABalanceAirChangeRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, state.dataHeatBal.Zone[thisZoneAirBalance.ZonePtr].Name)
            SetupOutputVariable(state, "Zone Combined Outdoor Air Fan Electricity Energy", Constant.Units.J, state.dataHeatBal.ZnAirRpt[thisZoneAirBalance.ZonePtr].OABalanceFanElec, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, state.dataHeatBal.Zone[thisZoneAirBalance.ZonePtr].Name, Constant.eResource.Electricity, OutputProcessor.Group.Building, OutputProcessor.EndUseCat.Fans, "Ventilation (simple)", state.dataHeatBal.Zone[thisZoneAirBalance.ZonePtr].Name)
    cCurrentModuleObject = "ZoneInfiltration:DesignFlowRate"
    var numDesignFlowInfiltrationObjects: Int32 = 0
    var totDesignFlowInfiltration: Int32 = 0
    var infiltrationDesignFlowRateObjects: EPVector[InternalHeatGains.GlobalInternalGainMiscObject]
    InternalHeatGains.setupIHGZonesAndSpaces(state, cCurrentModuleObject, infiltrationDesignFlowRateObjects, numDesignFlowInfiltrationObjects, totDesignFlowInfiltration, ErrorsFound)
    cCurrentModuleObject = "ZoneInfiltration:EffectiveLeakageArea"
    var numLeakageAreaInfiltrationObjects: Int32 = 0
    var totLeakageAreaInfiltration: Int32 = 0
    var infiltrationLeakageAreaObjects: EPVector[InternalHeatGains.GlobalInternalGainMiscObject]
    var zoneListNotAllowed = True
    InternalHeatGains.setupIHGZonesAndSpaces(state, cCurrentModuleObject, infiltrationLeakageAreaObjects, numLeakageAreaInfiltrationObjects, totLeakageAreaInfiltration, ErrorsFound, zoneListNotAllowed)
    cCurrentModuleObject = "ZoneInfiltration:FlowCoefficient"
    var numFlowCoefficientInfiltrationObjects: Int32 = 0
    var totFlowCoefficientInfiltration: Int32 = 0
    var infiltrationFlowCoefficientObjects: EPVector[InternalHeatGains.GlobalInternalGainMiscObject]
    InternalHeatGains.setupIHGZonesAndSpaces(state, cCurrentModuleObject, infiltrationFlowCoefficientObjects, numFlowCoefficientInfiltrationObjects, totFlowCoefficientInfiltration, ErrorsFound, zoneListNotAllowed)
    state.dataHeatBal.TotInfiltration = totDesignFlowInfiltration + totLeakageAreaInfiltration + totFlowCoefficientInfiltration
    state.dataHeatBal.Infiltration.allocate(state.dataHeatBal.TotInfiltration)
    state.dataHeatBalAirMgr.UniqueInfiltrationNames.reserve(state.dataHeatBal.TotInfiltration)
    var infiltrationNum: Int32 = 0
    if totDesignFlowInfiltration > 0:
        cCurrentModuleObject = "ZoneInfiltration:DesignFlowRate"
        for infilInputNum in range(1, numDesignFlowInfiltrationObjects + 1):
            state.dataInputProcessing.inputProcessor.getObjectItem(state, cCurrentModuleObject, infilInputNum, cAlphaArgs, NumAlpha, rNumericArgs, NumNumber, IOStat, lNumericFieldBlanks, lAlphaFieldBlanks, cAlphaFieldNames, cNumericFieldNames)
            var eoh = ErrorObjectHeader(routineName, cCurrentModuleObject, cAlphaArgs[1])
            var thisInfiltrationInput = infiltrationDesignFlowRateObjects[infilInputNum]
            for Item1 in range(1, thisInfiltrationInput.numOfSpaces + 1):
                infiltrationNum += 1
                var thisInfiltration = state.dataHeatBal.Infiltration[infiltrationNum]
                thisInfiltration.Name = thisInfiltrationInput.names[Item1]
                thisInfiltration.spaceIndex = thisInfiltrationInput.spaceNums[Item1]
                var thisSpace = state.dataHeatBal.space[thisInfiltration.spaceIndex]
                thisInfiltration.ZonePtr = thisSpace.zoneNum
                var thisZone = state.dataHeatBal.Zone[thisSpace.zoneNum]
                thisInfiltration.ModelType = DataHeatBalance.InfiltrationModelType.DesignFlowRate
                if lAlphaFieldBlanks[3]:
                    thisInfiltration.sched = Sched.GetScheduleAlwaysOn(state)
                elif (thisInfiltration.sched = Sched.GetSchedule(state, cAlphaArgs[3])) == None:
                    if Item1 == 1:
                        ShowSevereItemNotFound(state, eoh, cAlphaFieldNames[3], cAlphaArgs[3])
                        ErrorsFound = True
                var flow = AirflowSpec(getEnumValue(airflowSpecNamesUC, cAlphaArgs[4]))
                match flow:
                    case AirflowSpec.FlowPerZone:
                        if lNumericFieldBlanks[1]:
                            ShowWarningError(state, "{}{}=\"{}\", {} specifies {}, but that field is blank.  0 Infiltration will result.".format(RoutineName, cCurrentModuleObject, thisInfiltration.Name, cAlphaFieldNames[4], cNumericFieldNames[1]))
                        else:
                            var spaceFrac: Real64 = 1.0
                            if not thisInfiltrationInput.spaceListActive and (thisInfiltrationInput.numOfSpaces > 1):
                                var zoneVolume = thisZone.Volume
                                if zoneVolume > 0.0:
                                    spaceFrac = thisSpace.Volume / zoneVolume
                                else:
                                    ShowSevereError(state, "{}Zone volume is zero when allocating Infiltration to Spaces.".format(RoutineName))
                                    ShowContinueError(state, "Occurs for {}=\"{}\" in Zone=\"{}\".".format(cCurrentModuleObject, thisInfiltrationInput.Name, thisZone.Name))
                                    ErrorsFound = True
                            thisInfiltration.DesignLevel = rNumericArgs[1] * spaceFrac
                    case AirflowSpec.FlowPerArea:
                        if thisInfiltration.ZonePtr != 0:
                            if rNumericArgs[2] >= 0.0:
                                thisInfiltration.DesignLevel = rNumericArgs[2] * thisSpace.FloorArea
                                if thisInfiltration.ZonePtr > 0:
                                    if thisSpace.FloorArea <= 0.0:
                                        ShowWarningError(state, "{}{}=\"{}\", {} specifies {}, but Space Floor Area = 0.  0 Infiltration will result.".format(RoutineName, cCurrentModuleObject, thisInfiltration.Name, cAlphaFieldNames[4], cNumericFieldNames[2]))
                            else:
                                ShowSevereError(state, "{}{}=\"{}\", invalid flow/area specification [<0.0]={:#G}".format(RoutineName, cCurrentModuleObject, thisInfiltration.Name, rNumericArgs[2]))
                                ErrorsFound = True
                        if lNumericFieldBlanks[2]:
                            ShowWarningError(state, "{}{}=\"{}\", {} specifies {}, but that field is blank.  0 Infiltration will result.".format(RoutineName, cCurrentModuleObject, thisInfiltration.Name, cAlphaFieldNames[4], cNumericFieldNames[2]))
                    case AirflowSpec.FlowPerExteriorArea:
                        if thisInfiltration.ZonePtr != 0:
                            if rNumericArgs[3] >= 0.0:
                                thisInfiltration.DesignLevel = rNumericArgs[3] * thisSpace.ExteriorTotalSurfArea
                                if thisSpace.ExteriorTotalSurfArea <= 0.0:
                                    ShowWarningError(state, "{}{}=\"{}\", {} specifies {}, but Exterior Surface Area = 0.  0 Infiltration will result.".format(RoutineName, cCurrentModuleObject, thisInfiltration.Name, cAlphaFieldNames[4], cNumericFieldNames[3]))
                            else:
                                ShowSevereError(state, "{}{} = \"{}\", invalid flow/exteriorarea specification [<0.0]={:#G}".format(RoutineName, cCurrentModuleObject, thisInfiltration.Name, rNumericArgs[3]))
                                ErrorsFound = True
                        if lNumericFieldBlanks[3]:
                            ShowWarningError(state, "{}{}=\"{}\", {} specifies {}, but that field is blank.  0 Infiltration will result.".format(RoutineName, cCurrentModuleObject, thisInfiltration.Name, cAlphaFieldNames[4], cNumericFieldNames[3]))
                    case AirflowSpec.FlowPerExteriorWallArea:
                        if thisInfiltration.ZonePtr != 0:
                            if rNumericArgs[3] >= 0.0:
                                thisInfiltration.DesignLevel = rNumericArgs[3] * thisSpace.ExtGrossWallArea
                                if thisSpace.ExtGrossWallArea <= 0.0:
                                    ShowWarningError(state, "{}{}=\"{}\", {} specifies {}, but Exterior Wall Area = 0.  0 Infiltration will result.".format(RoutineName, cCurrentModuleObject, thisInfiltration.Name, cAlphaFieldNames[4], cNumericFieldNames[3]))
                            else:
                                ShowSevereError(state, "{}{} = \"{}\", invalid flow/exteriorwallarea specification [<0.0]={:#G}".format(RoutineName, cCurrentModuleObject, thisInfiltration.Name, rNumericArgs[3]))
                                ErrorsFound = True
                        if lNumericFieldBlanks[3]:
                            ShowWarningError(state, "{}{}=\"{}\", {} specifies {}, but that field is blank.  0 Infiltration will result.".format(RoutineName, cCurrentModuleObject, thisInfiltration.Name, cAlphaFieldNames[4], cNumericFieldNames[3]))
                    case AirflowSpec.AirChanges:
                        if thisInfiltration.spaceIndex != 0:
                            if rNumericArgs[4] >= 0.0:
                                thisInfiltration.DesignLevel = rNumericArgs[4] * thisSpace.Volume / Constant.rSecsInHour
                                if thisSpace.Volume <= 0.0:
                                    ShowWarningError(state, "{}{}=\"{}\", {} specifies {}, but Space Volume = 0.  0 Infiltration will result.".format(RoutineName, cCurrentModuleObject, thisInfiltration.Name, cAlphaFieldNames[4], cNumericFieldNames[4]))
                            else:
                                ShowSevereError(state, "{}In {} = \"{}\", invalid ACH (air changes per hour) specification [<0.0]={:#G}".format(RoutineName, cCurrentModuleObject, thisInfiltration.Name, rNumericArgs[4]))
                                ErrorsFound = True
                        if lNumericFieldBlanks[4]:
                            ShowWarningError(state, "{}{}=\"{}\", {} specifies {}, but that field is blank.  0 Infiltration will result.".format(RoutineName, cCurrentModuleObject, thisInfiltrationInput.Name, cAlphaFieldNames[4], cNumericFieldNames[4]))
                    case _:
                        if Item1 == 1:
                            ShowSevereError(state, "{}{}=\"{}\", invalid calculation method={}".format(RoutineName, cCurrentModuleObject, cAlphaArgs[1], cAlphaArgs[4]))
                            ErrorsFound = True
                thisInfiltration.ConstantTermCoef = rNumericArgs[5] if not lNumericFieldBlanks[5] else 1.0
                thisInfiltration.TemperatureTermCoef = rNumericArgs[6] if not lNumericFieldBlanks[6] else 0.0
                thisInfiltration.VelocityTermCoef = rNumericArgs[7] if not lNumericFieldBlanks[7] else 0.0
                thisInfiltration.VelocitySQTermCoef = rNumericArgs[8] if not lNumericFieldBlanks[8] else 0.0
                if thisInfiltration.ConstantTermCoef == 0.0 and thisInfiltration.TemperatureTermCoef == 0.0 and thisInfiltration.VelocityTermCoef == 0.0 and thisInfiltration.VelocitySQTermCoef == 0.0:
                    if Item1 == 1:
                        ShowWarningError(state, "{}{}=\"{}\", in {}" + "=\"{}\".".format(RoutineName, cCurrentModuleObject, cAlphaArgs[1], cAlphaFieldNames[2], cAlphaArgs[2]))
                        ShowContinueError(state, "Infiltration Coefficients are all zero.  No Infiltration will be reported.")
                thisInfiltration.densityBasis = DataHeatBalance.InfVentDensityBasis(getEnumValue(infVentDensityBasisNamesUC, cAlphaArgs[5]))
    if totLeakageAreaInfiltration > 0:
        cCurrentModuleObject = "ZoneInfiltration:EffectiveLeakageArea"
        for infilInputNum in range(1, numLeakageAreaInfiltrationObjects + 1):
            state.dataInputProcessing.inputProcessor.getObjectItem(state, cCurrentModuleObject, infilInputNum, cAlphaArgs, NumAlpha, rNumericArgs, NumNumber, IOStat, lNumericFieldBlanks, lAlphaFieldBlanks, cAlphaFieldNames, cNumericFieldNames)
            var eoh = ErrorObjectHeader(routineName, cCurrentModuleObject, cAlphaArgs[1])
            var thisInfiltrationInput = infiltrationLeakageAreaObjects[infilInputNum]
            for Item1 in range(1, thisInfiltrationInput.numOfSpaces + 1):
                infiltrationNum += 1
                var thisInfiltration = state.dataHeatBal.Infiltration[infiltrationNum]
                thisInfiltration.Name = thisInfiltrationInput.names[Item1]
                thisInfiltration.spaceIndex = thisInfiltrationInput.spaceNums[Item1]
                var thisSpace = state.dataHeatBal.space[thisInfiltration.spaceIndex]
                thisInfiltration.ZonePtr = thisSpace.zoneNum
                var thisZone = state.dataHeatBal.Zone[thisSpace.zoneNum]
                thisInfiltration.ModelType = DataHeatBalance.InfiltrationModelType.ShermanGrimsrud
                if lAlphaFieldBlanks[3]:
                    thisInfiltration.sched = Sched.GetScheduleAlwaysOn(state)
                elif (thisInfiltration.sched = Sched.GetSchedule(state, cAlphaArgs[3])) == None:
                    ShowSevereItemNotFound(state, eoh, cAlphaFieldNames[3], cAlphaArgs[3])
                    ErrorsFound = True
                thisInfiltration.BasicStackCoefficient = rNumericArgs[2]
                thisInfiltration.BasicWindCoefficient = rNumericArgs[3]
                if lNumericFieldBlanks[1]:
                    ShowWarningError(state, "{}{}=\"{}\", field {} is blank.  0 Infiltration will result.".format(RoutineName, cCurrentModuleObject, thisInfiltrationInput.Name, cNumericFieldNames[1]))
                else:
                    var spaceFrac: Real64 = 1.0
                    if not thisInfiltrationInput.spaceListActive and (thisInfiltrationInput.numOfSpaces > 1):
                        var zoneExteriorTotalSurfArea = thisZone.ExteriorTotalSurfArea
                        if zoneExteriorTotalSurfArea > 0.0:
                            spaceFrac = thisSpace.ExteriorTotalSurfArea / zoneExteriorTotalSurfArea
                        else:
                            ShowSevereError(state, "{}Zone exterior surface area is zero when allocating Infiltration to Spaces.".format(RoutineName))
                            ShowContinueError(state, "Occurs for {}=\"{}\" in Zone=\"{}\".".format(cCurrentModuleObject, thisInfiltrationInput.Name, thisZone.Name))
                            ErrorsFound = True
                    thisInfiltration.LeakageArea = rNumericArgs[1] * spaceFrac
                if thisInfiltration.spaceIndex > 0:
                    if thisSpace.ExteriorTotalSurfArea <= 0.0:
                        ShowWarningError(state, "{}{}=\"{}\", Space=\"{}\" does not have surfaces exposed to outdoors.".format(RoutineName, cCurrentModuleObject, thisInfiltrationInput.Name, thisSpace.Name))
                        ShowContinueError(state, "Infiltration model is appropriate for exterior spaces not interior spaces, simulation continues.")
    if totFlowCoefficientInfiltration > 0:
        cCurrentModuleObject = "ZoneInfiltration:FlowCoefficient"
        for infilInputNum in range(1, numFlowCoefficientInfiltrationObjects + 1):
            state.dataInputProcessing.inputProcessor.getObjectItem(state, cCurrentModuleObject, infilInputNum, cAlphaArgs, NumAlpha, rNumericArgs, NumNumber, IOStat, lNumericFieldBlanks, lAlphaFieldBlanks, cAlphaFieldNames, cNumericFieldNames)
            var eoh = ErrorObjectHeader(routineName, cCurrentModuleObject, cAlphaArgs[1])
            var thisInfiltrationInput = infiltrationFlowCoefficientObjects[infilInputNum]
            for Item1 in range(1, thisInfiltrationInput.numOfSpaces + 1):
                infiltrationNum += 1
                var thisInfiltration = state.dataHeatBal.Infiltration[infiltrationNum]
                thisInfiltration.Name = thisInfiltrationInput.names[Item1]
                thisInfiltration.spaceIndex = thisInfiltrationInput.spaceNums[Item1]
                var thisSpace = state.dataHeatBal.space[thisInfiltration.spaceIndex]
                thisInfiltration.ZonePtr = thisSpace.zoneNum
                var thisZone = state.dataHeatBal.Zone[thisSpace.zoneNum]
                thisInfiltration.ModelType = DataHeatBalance.InfiltrationModelType.AIM2
                if lAlphaFieldBlanks[3]:
                    thisInfiltration.sched = Sched.GetScheduleAlwaysOn(state)
                elif (thisInfiltration.sched = Sched.GetSchedule(state, cAlphaArgs[3])) == None:
                    ShowSevereItemNotFound(state, eoh, cAlphaFieldNames[3], cAlphaArgs[3])
                    ErrorsFound = True
                thisInfiltration.AIM2StackCoefficient = rNumericArgs[2]
                thisInfiltration.PressureExponent = rNumericArgs[3]
                thisInfiltration.AIM2WindCoefficient = rNumericArgs[4]
                thisInfiltration.ShelterFactor = rNumericArgs[5]
                if lNumericFieldBlanks[1]:
                    ShowWarningError(state, "{}{}=\"{}\", field {} is blank.  0 Infiltration will result.".format(RoutineName, cCurrentModuleObject, thisInfiltrationInput.Name, cNumericFieldNames[1]))
                else:
                    var spaceFrac: Real64 = 1.0
                    if not thisInfiltrationInput.spaceListActive and (thisInfiltrationInput.numOfSpaces > 1):
                        var zoneExteriorTotalSurfArea = thisZone.ExteriorTotalSurfArea
                        if zoneExteriorTotalSurfArea > 0.0:
                            spaceFrac = thisSpace.ExteriorTotalSurfArea / zoneExteriorTotalSurfArea
                        else:
                            ShowSevereError(state, "{}Zone exterior surface area is zero when allocating Infiltration to Spaces.".format(RoutineName))
                            ShowContinueError(state, "Occurs for {}=\"{}\" in Zone=\"{}\".".format(cCurrentModuleObject, thisInfiltrationInput.Name, thisZone.Name))
                            ErrorsFound = True
                    thisInfiltration.FlowCoefficient = rNumericArgs[1] * spaceFrac
                    if thisInfiltration.spaceIndex > 0:
                        if thisSpace.ExteriorTotalSurfArea <= 0.0:
                            ShowWarningError(state, "{}{}=\"{}\", Space=\"{}\" does not have surfaces exposed to outdoors.".format(RoutineName, cCurrentModuleObject, thisInfiltrationInput.Name, thisSpace.Name))
                            ShowContinueError(state, "Infiltration model is appropriate for exterior spaces not interior spaces, simulation continues.")
    for Loop in range(1, state.dataHeatBal.TotInfiltration + 1):
        if state.dataHeatBal.Infiltration[Loop].ZonePtr > 0 and not state.dataHeatBal.Zone[state.dataHeatBal.Infiltration[Loop].ZonePtr].zoneOAQuadratureSum:
            SetupOutputVariable(state, "Infiltration Sensible Heat Loss Energy", Constant.Units.J, state.dataHeatBal.Infiltration[Loop].InfilHeatLoss, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, state.dataHeatBal.Infiltration[Loop].Name)
            SetupOutputVariable(state, "Infiltration Sensible Heat Gain Energy", Constant.Units.J, state.dataHeatBal.Infiltration[Loop].InfilHeatGain, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, state.dataHeatBal.Infiltration[Loop].Name)
            SetupOutputVariable(state, "Infiltration Latent Heat Loss Energy", Constant.Units.J, state.dataHeatBal.Infiltration[Loop].InfilLatentLoss, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, state.dataHeatBal.Infiltration[Loop].Name)
            SetupOutputVariable(state, "Infiltration Latent Heat Gain Energy", Constant.Units.J, state.dataHeatBal.Infiltration[Loop].InfilLatentGain, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, state.dataHeatBal.Infiltration[Loop].Name)
            SetupOutputVariable(state, "Infiltration Total Heat Loss Energy", Constant.Units.J, state.dataHeatBal.Infiltration[Loop].InfilTotalLoss, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, state.dataHeatBal.Infiltration[Loop].Name)
            SetupOutputVariable(state, "Infiltration Total Heat Gain Energy", Constant.Units.J, state.dataHeatBal.Infiltration[Loop].InfilTotalGain, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, state.dataHeatBal.Infiltration[Loop].Name)
            SetupOutputVariable(state, "Infiltration Current Density Volume Flow Rate", Constant.Units.m3_s, state.dataHeatBal.Infiltration[Loop].InfilVdotCurDensity, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, state.dataHeatBal.Infiltration[Loop].Name)
            SetupOutputVariable(state, "Infiltration Standard Density Volume Flow Rate", Constant.Units.m3_s, state.dataHeatBal.Infiltration[Loop].InfilVdotStdDensity, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, state.dataHeatBal.Infiltration[Loop].Name)
            SetupOutputVariable(state, "Infiltration Outdoor Density Volume Flow Rate", Constant.Units.m3_s, state.dataHeatBal.Infiltration[Loop].InfilVdotOutDensity, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, state.dataHeatBal.Infiltration[Loop].Name)
            SetupOutputVariable(state, "Infiltration Current Density Volume", Constant.Units.m3, state.dataHeatBal.Infiltration[Loop].InfilVolumeCurDensity, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, state.dataHeatBal.Infiltration[Loop].Name)
            SetupOutputVariable(state, "Infiltration Standard Density Volume", Constant.Units.m3, state.dataHeatBal.Infiltration[Loop].InfilVolumeStdDensity, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, state.dataHeatBal.Infiltration[Loop].Name)
            SetupOutputVariable(state, "Infiltration Mass", Constant.Units.kg, state.dataHeatBal.Infiltration[Loop].InfilMass, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, state.dataHeatBal.Infiltration[Loop].Name)
            SetupOutputVariable(state, "Infiltration Mass Flow Rate", Constant.Units.kg_s, state.dataHeatBal.Infiltration[Loop].InfilMdot, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, state.dataHeatBal.Infiltration[Loop].Name)
            SetupOutputVariable(state, "Infiltration Current Density Air Change Rate", Constant.Units.ach, state.dataHeatBal.Infiltration[Loop].InfilAirChangeRateCurDensity, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, state.dataHeatBal.Infiltration[Loop].Name)
            SetupOutputVariable(state, "Infiltration Standard Density Air Change Rate", Constant.Units.ach, state.dataHeatBal.Infiltration[Loop].InfilAirChangeRateStdDensity, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, state.dataHeatBal.Infiltration[Loop].Name)
            SetupOutputVariable(state, "Infiltration Outdoor Density Air Change Rate", Constant.Units.ach, state.dataHeatBal.Infiltration[Loop].InfilAirChangeRateOutDensity, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, state.dataHeatBal.Infiltration[Loop].Name)
            if RepVarSet[state.dataHeatBal.Infiltration[Loop].ZonePtr]:
                RepVarSet[state.dataHeatBal.Infiltration[Loop].ZonePtr] = False
                SetupOutputVariable(state, "Zone Infiltration Sensible Heat Loss Energy", Constant.Units.J, state.dataHeatBal.ZnAirRpt[state.dataHeatBal.Infiltration[Loop].ZonePtr].InfilHeatLoss, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, state.dataHeatBal.Zone[state.dataHeatBal.Infiltration[Loop].ZonePtr].Name)
                SetupOutputVariable(state, "Zone Infiltration Sensible Heat Gain Energy", Constant.Units.J, state.dataHeatBal.ZnAirRpt[state.dataHeatBal.Infiltration[Loop].ZonePtr].InfilHeatGain, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, state.dataHeatBal.Zone[state.dataHeatBal.Infiltration[Loop].ZonePtr].Name)
                SetupOutputVariable(state, "Zone Infiltration Latent Heat Loss Energy", Constant.Units.J, state.dataHeatBal.ZnAirRpt[state.dataHeatBal.Infiltration[Loop].ZonePtr].InfilLatentLoss, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, state.dataHeatBal.Zone[state.dataHeatBal.Infiltration[Loop].ZonePtr].Name)
                SetupOutputVariable(state, "Zone Infiltration Latent Heat Gain Energy", Constant.Units.J, state.dataHeatBal.ZnAirRpt[state.dataHeatBal.Infiltration[Loop].ZonePtr].InfilLatentGain, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, state.dataHeatBal.Zone[state.dataHeatBal.Infiltration[Loop].ZonePtr].Name)
                SetupOutputVariable(state, "Zone Infiltration Total Heat Loss Energy", Constant.Units.J, state.dataHeatBal.ZnAirRpt[state.dataHeatBal.Infiltration[Loop].ZonePtr].InfilTotalLoss, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, state.dataHeatBal.Zone[state.dataHeatBal.Infiltration[Loop].ZonePtr].Name)
                SetupOutputVariable(state, "Zone Infiltration Total Heat Gain Energy", Constant.Units.J, state.dataHeatBal.ZnAirRpt[state.dataHeatBal.Infiltration[Loop].ZonePtr].InfilTotalGain, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, state.dataHeatBal.Zone[state.dataHeatBal.Infiltration[Loop].ZonePtr].Name)
                SetupOutputVariable(state, "Zone Infiltration Current Density Volume Flow Rate", Constant.Units.m3_s, state.dataHeatBal.ZnAirRpt[state.dataHeatBal.Infiltration[Loop].ZonePtr].InfilVdotCurDensity, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, state.dataHeatBal.Zone[state.dataHeatBal.Infiltration[Loop].ZonePtr].Name)
                SetupOutputVariable(state, "Zone Infiltration Standard Density Volume Flow Rate", Constant.Units.m3_s, state.dataHeatBal.ZnAirRpt[state.dataHeatBal.Infiltration[Loop].ZonePtr].InfilVdotStdDensity, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, state.dataHeatBal.Zone[state.dataHeatBal.Infiltration[Loop].ZonePtr].Name)
                SetupOutputVariable(state, "Zone Infiltration Outdoor Density Volume Flow Rate", Constant.Units.m3_s, state.dataHeatBal.ZnAirRpt[state.dataHeatBal.Infiltration[Loop].ZonePtr].InfilVdotOutDensity, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, state.dataHeatBal.Zone[state.dataHeatBal.Infiltration[Loop].ZonePtr].Name)
                SetupOutputVariable(state, "Zone Infiltration Current Density Volume", Constant.Units.m3, state.dataHeatBal.ZnAirRpt[state.dataHeatBal.Infiltration[Loop].ZonePtr].InfilVolumeCurDensity, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, state.dataHeatBal.Zone[state.dataHeatBal.Infiltration[Loop].ZonePtr].Name)
                SetupOutputVariable(state, "Zone Infiltration Standard Density Volume", Constant.Units.m3, state.dataHeatBal.ZnAirRpt[state.dataHeatBal.Infiltration[Loop].ZonePtr].InfilVolumeStdDensity, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, state.dataHeatBal.Zone[state.dataHeatBal.Infiltration[Loop].ZonePtr].Name)
                SetupOutputVariable(state, "Zone Infiltration Mass", Constant.Units.kg, state.dataHeatBal.ZnAirRpt[state.dataHeatBal.Infiltration[Loop].ZonePtr].InfilMass, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, state.dataHeatBal.Zone[state.dataHeatBal.Infiltration[Loop].ZonePtr].Name)
                SetupOutputVariable(state, "Zone Infiltration Mass Flow Rate", Constant.Units.kg_s, state.dataHeatBal.ZnAirRpt[state.dataHeatBal.Infiltration[Loop].ZonePtr].InfilMdot, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, state.dataHeatBal.Zone[state.dataHeatBal.Infiltration[Loop].ZonePtr].Name)
                SetupOutputVariable(state, "Zone Infiltration Current Density Air Change Rate", Constant.Units.ach, state.dataHeatBal.ZnAirRpt[state.dataHeatBal.Infiltration[Loop].ZonePtr].InfilAirChangeRateCurDensity, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, state.dataHeatBal.Zone[state.dataHeatBal.Infiltration[Loop].ZonePtr].Name)
                SetupOutputVariable(state, "Zone Infiltration Standard Density Air Change Rate", Constant.Units.ach, state.dataHeatBal.ZnAirRpt[state.dataHeatBal.Infiltration[Loop].ZonePtr].InfilAirChangeRateStdDensity, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, state.dataHeatBal.Zone[state.dataHeatBal.Infiltration[Loop].ZonePtr].Name)
                SetupOutputVariable(state, "Zone Infiltration Outdoor Density Air Change Rate", Constant.Units.ach, state.dataHeatBal.ZnAirRpt[state.dataHeatBal.Infiltration[Loop].ZonePtr].InfilAirChangeRateOutDensity, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, state.dataHeatBal.Zone[state.dataHeatBal.Infiltration[Loop].ZonePtr].Name)
        if state.dataGlobal.AnyEnergyManagementSystemInModel:
            SetupEMSActuator(state, "Zone Infiltration", state.dataHeatBal.Infiltration[Loop].Name, "Air Exchange Flow Rate", "[m3/s]", state.dataHeatBal.Infiltration[Loop].EMSOverrideOn, state.dataHeatBal.Infiltration[Loop].EMSAirFlowRateValue)
    RepVarSet = True
    cCurrentModuleObject = "ZoneVentilation:DesignFlowRate"
    var numDesignFlowVentilationObjects: Int32 = 0
    var totDesignFlowVentilation: Int32 = 0
    var ventilationDesignFlowRateObjects: EPVector[InternalHeatGains.GlobalInternalGainMiscObject]
    InternalHeatGains.setupIHGZonesAndSpaces(state, cCurrentModuleObject, ventilationDesignFlowRateObjects, numDesignFlowVentilationObjects, totDesignFlowVentilation, ErrorsFound)
    cCurrentModuleObject = "ZoneVentilation:WindandStackOpenArea"
    var numWindStackVentilationObjects: Int32 = 0
    var totWindStackVentilation: Int32 = 0
    var ventilationWindStackObjects: EPVector[InternalHeatGains.GlobalInternalGainMiscObject]
    InternalHeatGains.setupIHGZonesAndSpaces(state, cCurrentModuleObject, ventilationWindStackObjects, numWindStackVentilationObjects, totWindStackVentilation, ErrorsFound, zoneListNotAllowed)
    state.dataHeatBal.TotVentilation = totDesignFlowVentilation + totWindStackVentilation
    state.dataHeatBal.Ventilation.allocate(state.dataHeatBal.TotVentilation)
    var ventilationNum: Int32 = 0
    if numDesignFlowVentilationObjects > 0:
        cCurrentModuleObject = "ZoneVentilation:DesignFlowRate"
        for ventInputNum in range(1, numDesignFlowVentilationObjects + 1):
            state.dataInputProcessing.inputProcessor.getObjectItem(state, cCurrentModuleObject, ventInputNum, cAlphaArgs, NumAlpha, rNumericArgs, NumNumber, IOStat, lNumericFieldBlanks, lAlphaFieldBlanks, cAlphaFieldNames, cNumericFieldNames)
            var eoh = ErrorObjectHeader(routineName, cCurrentModuleObject, cAlphaArgs[1])
            var thisVentilationInput = ventilationDesignFlowRateObjects[ventInputNum]
            for Item1 in range(1, thisVentilationInput.numOfSpaces + 1):
                ventilationNum += 1
                var thisVentilation = state.dataHeatBal.Ventilation[ventilationNum]
                thisVentilation.Name = thisVentilationInput.names[Item1]
                thisVentilation.spaceIndex = thisVentilationInput.spaceNums[Item1]
                var thisSpace = state.dataHeatBal.space[thisVentilation.spaceIndex]
                thisVentilation.ZonePtr = thisSpace.zoneNum
                var thisZone = state.dataHeatBal.Zone[thisSpace.zoneNum]
                thisVentilation.ModelType = DataHeatBalance.VentilationModelType.DesignFlowRate
                if lAlphaFieldBlanks[3]:
                    thisVentilation.availSched = Sched.GetScheduleAlwaysOn(state)
                elif (thisVentilation.availSched = Sched.GetSchedule(state, cAlphaArgs[3])) == None:
                    if Item1 == 1:
                        ShowSevereItemNotFound(state, eoh, cAlphaFieldNames[3], cAlphaArgs[3])
                        ErrorsFound = True
                var flow = AirflowSpec(getEnumValue(airflowSpecNamesUC, cAlphaArgs[4]))
                match flow:
                    case AirflowSpec.FlowPerZone:
                        thisVentilation.DesignLevel = rNumericArgs[1]
                        if lNumericFieldBlanks[1]:
                            ShowWarningError(state, "{}{}=\"{}\", {} specifies {}, but that field is blank. Zero ventilation will result.".format(RoutineName, cCurrentModuleObject, thisVentilation.Name, cAlphaFieldNames[4], cNumericFieldNames[1]))
                    case AirflowSpec.FlowPerArea:
                        if thisVentilation.spaceIndex != 0:
                            if rNumericArgs[2] >= 0.0:
                                thisVentilation.DesignLevel = rNumericArgs[2] * thisSpace.FloorArea
                                if thisSpace.FloorArea <= 0.0:
                                    ShowWarningError(state, "{}{}=\"{}\", {} specifies {}, but Space Floor Area = 0. Zero ventilation will result.".format(RoutineName, cCurrentModuleObject, thisVentilation.Name, cAlphaFieldNames[4], cNumericFieldNames[2]))
                            else:
                                ShowSevereError(state, "{}{}=\"{}\", invalid flow/area specification [<0.0]={:#G}".format(RoutineName, cCurrentModuleObject, thisVentilation.Name, rNumericArgs[2]))
                                ErrorsFound = True
                        if lNumericFieldBlanks[2]:
                            ShowWarningError(state, "{}{}=\"{}\", {} specifies {}, but that field is blank. Zero ventilation will result.".format(RoutineName, cCurrentModuleObject, thisVentilation.Name, cAlphaFieldNames[4], cNumericFieldNames[2]))
                    case AirflowSpec.FlowPerPerson:
                        if thisVentilation.spaceIndex != 0:
                            if rNumericArgs[3] >= 0.0:
                                thisVentilation.DesignLevel = rNumericArgs[3] * thisSpace.TotOccupants
                                if thisSpace.TotOccupants <= 0.0:
                                    ShowWarningError(state, "{}{}=\"{}\", {} specifies {}, but Zone Total Occupants = 0. Zero ventilation will result.".format(RoutineName, cCurrentModuleObject, thisVentilation.Name, cAlphaFieldNames[4], cNumericFieldNames[3]))
                            else:
                                ShowSevereError(state, "{}{}=\"{}\", invalid flow/person specification [<0.0]={:#G}".format(RoutineName, cCurrentModuleObject, thisVentilation.Name, rNumericArgs[3]))
                                ErrorsFound = True
                        if lNumericFieldBlanks[3]:
                            ShowWarningError(state, "{}{}=\"{}\", {} specifies {}, but that field is blank. Zero Ventilation will result.".format(RoutineName, cCurrentModuleObject, thisVentilation.Name, cAlphaFieldNames[4], cNumericFieldNames[3]))
                    case AirflowSpec.AirChanges:
                        if thisVentilation.spaceIndex != 0:
                            if rNumericArgs[4] >= 0.0:
                                thisVentilation.DesignLevel = rNumericArgs[4] * thisSpace.Volume / Constant.rSecsInHour
                                if thisSpace.Volume <= 0.0:
                                    ShowWarningError(state, "{}{}=\"{}\", {} specifies {}, but Space Volume = 0. Zero ventilation will result.".format(RoutineName, cCurrentModuleObject, thisVentilation.Name, cAlphaFieldNames[4], cNumericFieldNames[4]))
                            else:
                                ShowSevereError(state, "{}{}=\"{}\", invalid ACH (air changes per hour) specification [<0.0]={:#G}".format(RoutineName, cCurrentModuleObject, thisVentilation.Name, rNumericArgs[5]))
                                ErrorsFound = True
                        if lNumericFieldBlanks[4]:
                            ShowWarningError(state, "{}{}=\"{}\", {} specifies {}, but that field is blank. Zero ventilation will result.".format(RoutineName, cCurrentModuleObject, thisVentilation.Name, cAlphaFieldNames[4], cNumericFieldNames[4]))
                    case _:
                        if Item1 == 1:
                            ShowSevereError(state, "{}{}=\"{}\", invalid calculation method={}".format(RoutineName, cCurrentModuleObject, cAlphaArgs[1], cAlphaArgs[4]))
                            ErrorsFound = True
                if cAlphaArgs[5].empty():
                    thisVentilation.FanType = DataHeatBalance.VentilationType.Natural
                else:
                    thisVentilation.FanType = DataHeatBalance.VentilationType(getEnumValue(ventilationTypeNamesUC, cAlphaArgs[5]))
                    if thisVentilation.FanType == DataHeatBalance.VentilationType.Invalid:
                        ShowSevereError(state, "{}{}=\"{}\". invalid {}" + "=\"{}\".".format(RoutineName, cCurrentModuleObject, thisVentilation.Name, cAlphaFieldNames[5], cAlphaArgs[5]))
                        ErrorsFound = True
                thisVentilation.FanPressure = rNumericArgs[5]
                if thisVentilation.FanPressure < 0.0:
                    if Item1 == 1:
                        ShowSevereError(state, "{}{}=\"{}\", {} must be >=0".format(RoutineName, cCurrentModuleObject, thisVentilation.Name, cNumericFieldNames[5]))
                        ErrorsFound = True
                thisVentilation.FanEfficiency = rNumericArgs[6]
                if (thisVentilation.FanEfficiency <= 0.0) or (thisVentilation.FanEfficiency > 1.0):
                    if Item1 == 1:
                        ShowSevereError(state, "{}{}=\"{}\",{} must be in range >0 and <= 1".format(RoutineName, cCurrentModuleObject, thisVentilation.Name, cNumericFieldNames[6]))
                        ErrorsFound = True
                if thisVentilation.FanType == DataHeatBalance.VentilationType.Natural:
                    thisVentilation.FanPressure = 0.0
                    thisVentilation.FanEfficiency = 1.0
                thisVentilation.ConstantTermCoef = rNumericArgs[7] if not lNumericFieldBlanks[7] else 1.0
                thisVentilation.TemperatureTermCoef = rNumericArgs[8] if not lNumericFieldBlanks[8] else 0.0
                thisVentilation.VelocityTermCoef = rNumericArgs[9] if not lNumericFieldBlanks[9] else 0.0
                thisVentilation.VelocitySQTermCoef = rNumericArgs[10] if not lNumericFieldBlanks[10] else 0.0
                if thisVentilation.ConstantTermCoef == 0.0 and thisVentilation.TemperatureTermCoef == 0.0 and thisVentilation.VelocityTermCoef == 0.0 and thisVentilation.VelocitySQTermCoef == 0.0:
                    if Item1 == 1:
                        ShowWarningError(state, "{}{}=\"{}\", in {}" + "=\"{}\".".format(RoutineName, cCurrentModuleObject, cAlphaArgs[1], cAlphaFieldNames[2], cAlphaArgs[2]))
                        ShowContinueError(state, "Ventilation Coefficients are all zero.  No Ventilation will be reported.")
                if not lNumericFieldBlanks[11]:
                    thisVentilation.MinIndoorTemperature = rNumericArgs[11]
                else:
                    thisVentilation.MinIndoorTemperature = -VentilTempLimit
                if (thisVentilation.MinIndoorTemperature < -VentilTempLimit) or (thisVentilation.MinIndoorTemperature > VentilTempLimit):
                    if Item1 == 1:
                        ShowSevereError(state, "{}{}=\"{}\" must have {} between -100C and 100C.".format(RoutineName, cCurrentModuleObject, cAlphaArgs[1], cNumericFieldNames[11]))
                        ShowContinueError(state, "...value entered=[{:.2f}].".format(rNumericArgs[11]))
                        ErrorsFound = True
                if not lAlphaFieldBlanks[6]:
                    thisVentilation.minIndoorTempSched = Sched.GetSchedule(state, cAlphaArgs[6])
                if Item1 == 1:
                    if lAlphaFieldBlanks[6]:
                        if lNumericFieldBlanks[11]:

                    elif thisVentilation.minIndoorTempSched == None:
                        ShowWarningItemNotFound(state, eoh, cAlphaFieldNames[6], cAlphaArgs[6], "The default value will be used ({:.2f})".format(thisVentilation.MinIndoorTemperature))
                    elif not thisVentilation.minIndoorTempSched.checkMinMaxVals(state, Clusive.In, -VentilTempLimit, Clusive.In, VentilTempLimit):
                        Sched.ShowSevereBadMinMax(state, eoh, cAlphaFieldNames[6], cAlphaArgs[6], Clusive.In, -VentilTempLimit, Clusive.In, VentilTempLimit)
                        ErrorsFound = True
                    elif not lNumericFieldBlanks[11]:
                        ShowWarningCustom(state, eoh, "Both {} and {} provided, {} will be used.".format(cAlphaFieldNames[6], cAlphaFieldNames[11], cAlphaFieldNames[6]))
                thisVentilation.MaxIndoorTemperature = rNumericArgs[12] if not lNumericFieldBlanks[12] else VentilTempLimit
                if (thisVentilation.MaxIndoorTemperature < -VentilTempLimit) or (thisVentilation.MaxIndoorTemperature > VentilTempLimit):
                    if Item1 == 1:
                        ShowSevereError(state, "{}{} = {} must have a maximum indoor temperature between -100C and 100C".format(RoutineName, cCurrentModuleObject, cAlphaArgs[1]))
                        ErrorsFound = True
                if not lAlphaFieldBlanks[7]:
                    thisVentilation.maxIndoorTempSched = Sched.GetSchedule(state, cAlphaArgs[7])
                if Item1 == 1:
                    if lAlphaFieldBlanks[7]:
                        if lNumericFieldBlanks[12]:

                    elif thisVentilation.maxIndoorTempSched == None:
                        ShowWarningItemNotFound(state, eoh, cAlphaFieldNames[7], cAlphaArgs[7], "The default value will be used ({:.2f})".format(thisVentilation.MaxIndoorTemperature))
                    elif not thisVentilation.maxIndoorTempSched.checkMinMaxVals(state, Clusive.In, -VentilTempLimit, Clusive.In, VentilTempLimit):
                        Sched.ShowSevereBadMinMax(state, eoh, cAlphaFieldNames[7], cAlphaArgs[7], Clusive.In, -VentilTempLimit, Clusive.In, VentilTempLimit)
                        ErrorsFound = True
                    elif not lNumericFieldBlanks[12]:
                        ShowWarningCustom(state, eoh, "Both {} and {} provided, {} will be used.".format(cAlphaFieldNames[7], cAlphaFieldNames[12], cAlphaFieldNames[7]))
                thisVentilation.DelTemperature = rNumericArgs[13] if not lNumericFieldBlanks[13] else -VentilTempLimit
                if not lAlphaFieldBlanks[8]:
                    thisVentilation.deltaTempSched = Sched.GetSchedule(state, cAlphaArgs[8])
                if Item1 == 1:
                    if lAlphaFieldBlanks[8]:
                        if lNumericFieldBlanks[13]:

                    elif thisVentilation.deltaTempSched == None:
                        ShowWarningItemNotFound(state, eoh, cAlphaFieldNames[8], cAlphaArgs[8], "The default value will be used ({:.2f})".format(thisVentilation.DelTemperature))
                    elif not thisVentilation.deltaTempSched.checkMinVal(state, Clusive.In, -VentilTempLimit):
                        Sched.ShowSevereBadMin(state, eoh, cAlphaFieldNames[8], cAlphaArgs[8], Clusive.In, -100)
                        ErrorsFound = True
                    elif not lNumericFieldBlanks[13]:
                        ShowWarningCustom(state, eoh, "Both {} and {} provided, {} will be used.".format(cAlphaFieldNames[8], cAlphaFieldNames[13], cAlphaFieldNames[8]))
                thisVentilation.MinOutdoorTemperature = rNumericArgs[14] if not lNumericFieldBlanks[14] else -VentilTempLimit
                if (thisVentilation.MinOutdoorTemperature < -VentilTempLimit) or (thisVentilation.MinOutdoorTemperature > VentilTempLimit):
                    if Item1 == 1:
                        ShowSevereError(state, "{}{} statement = {} must have {} between -100C and 100C".format(RoutineName, cCurrentModuleObject, cAlphaArgs[1], cNumericFieldNames[14]))
                        ErrorsFound = True
                if not lAlphaFieldBlanks[9]:
                    thisVentilation.minOutdoorTempSched = Sched.GetSchedule(state, cAlphaArgs[9])
                if Item1 == 1:
                    if lAlphaFieldBlanks[9]:
                        if lNumericFieldBlanks[14]:

                    elif thisVentilation.minOutdoorTempSched == None:
                        ShowWarningItemNotFound(state, eoh, cAlphaFieldNames[9], cAlphaArgs[9], "The default value will be used ({:.2f})".format(thisVentilation.MinOutdoorTemperature))
                    elif not thisVentilation.minOutdoorTempSched.checkMinMaxVals(state, Clusive.In, -VentilTempLimit, Clusive.In, VentilTempLimit):
                        Sched.ShowSevereBadMinMax(state, eoh, cAlphaFieldNames[9], cAlphaArgs[9], Clusive.In, -VentilTempLimit, Clusive.In, VentilTempLimit)
                        ErrorsFound = True
                    elif not lNumericFieldBlanks[14]:
                        ShowWarningCustom(state, eoh, "Both {} and {} provided, {} will be used.".format(cAlphaFieldNames[9], cNumericFieldNames[14], cAlphaFieldNames[9]))
                thisVentilation.MaxOutdoorTemperature = rNumericArgs[15] if not lNumericFieldBlanks[15] else VentilTempLimit
                if Item1 == 1:
                    if (thisVentilation.MaxOutdoorTemperature < -VentilTempLimit) or (thisVentilation.MaxOutdoorTemperature > Ventil