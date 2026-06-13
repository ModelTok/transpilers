# WindTurbine.mojo - Faithful 1:1 translation from C++

import "Sched" as Sched
import "Util"
import "InputProcessor"
import "OutputProcessor"
import "Psychrometrics"
import "DataEnvironment"
from Psychrometrics import PsyRhoAirFnPbTdbW, PsyWFnTdbTwbPb
from DataEnvironment import OutBaroPressAt, OutDryBulbTempAt, OutWetBulbTempAt, WindSpeedAt
from Constant import Units, eResource, Group, EndUseCat, Pi, DegToRad
from FileSystem import fileExists
from ScheduleManager import GetSchedule, GetScheduleAlwaysOn
from General import pow_2, pow_3, ProcessNumber, FindItemInList
from UtilityRoutines import ShowFatalError, ShowSevereError, ShowWarningError, ShowContinueError, ShowSevereItemNotFound
import "EnergyPlus"  # for format function
from ObjexxFCL import sum

@value
enum RotorType: Int32:
    Invalid = -1
    HorizontalAxis
    VerticalAxis
    Num

@value
enum ControlType: Int32:
    Invalid = -1
    FixedSpeedFixedPitch
    FixedSpeedVariablePitch
    VariableSpeedFixedPitch
    VariableSpeedVariablePitch
    Num

@value
struct WindTurbineParams:
    var Name: String
    var rotorType: RotorType = RotorType.Invalid
    var controlType: ControlType = ControlType.Invalid
    var availSched: Sched.Schedule? = None
    var NumOfBlade: Int = 0
    var RatedRotorSpeed: Float64 = 0.0
    var RotorDiameter: Float64 = 0.0
    var RotorHeight: Float64 = 0.0
    var RatedPower: Float64 = 0.0
    var RatedWindSpeed: Float64 = 0.0
    var CutInSpeed: Float64 = 0.0
    var CutOutSpeed: Float64 = 0.0
    var SysEfficiency: Float64 = 0.0
    var MaxTipSpeedRatio: Float64 = 0.0
    var MaxPowerCoeff: Float64 = 0.0
    var LocalAnnualAvgWS: Float64 = 0.0
    var AnnualTMYWS: Float64 = 0.0
    var HeightForLocalWS: Float64 = 0.0
    var ChordArea: Float64 = 0.0
    var DragCoeff: Float64 = 0.0
    var LiftCoeff: Float64 = 0.0
    var PowerCoeffs: List[Float64] = List[Float64](repeating=0.0, count=6)
    var TotPower: Float64 = 0.0
    var Power: Float64 = 0.0
    var TotEnergy: Float64 = 0.0
    var Energy: Float64 = 0.0
    var LocalWindSpeed: Float64 = 0.0
    var LocalAirDensity: Float64 = 0.0
    var PowerCoeff: Float64 = 0.0
    var ChordalVel: Float64 = 0.0
    var NormalVel: Float64 = 0.0
    var RelFlowVel: Float64 = 0.0
    var TipSpeedRatio: Float64 = 0.0
    var WSFactor: Float64 = 0.0
    var AngOfAttack: Float64 = 0.0
    var IntRelFlowVel: Float64 = 0.0
    var TanForce: Float64 = 0.0
    var NorForce: Float64 = 0.0
    var TotTorque: Float64 = 0.0
    var AzimuthAng: Float64 = 0.0

alias ControlNamesUC: List[String] = List[String](
    "FIXEDSPEEDFIXEDPITCH",
    "FIXEDSPEEDVARIABLEPITCH",
    "VARIABLESPEEDFIXEDPITCH",
    "VARIABLESPEEDVARIABLEPITCH",
)

alias RotorNamesUC: List[String] = List[String](
    "HORIZONTALAXISWINDTURBINE",
    "VERTICALAXISWINDTURBINE",
)

def SimWindTurbine(
    inout state: EnergyPlusData,
    generatorType: GeneratorType,
    generatorName: String,
    inout generatorIndex: Int,
    runFlag: Bool,
    wtLoad: Float64
):
    var windTurbineNum: Int
    if state.dataWindTurbine.GetInputFlag:
        GetWindTurbineInput(state)
        state.dataWindTurbine.GetInputFlag = False
    if generatorIndex == 0:
        windTurbineNum = Util.FindItemInList(generatorName, state.dataWindTurbine.WindTurbineSys)
        if windTurbineNum == 0:
            ShowFatalError(
                state,
                "SimWindTurbine: Specified Generator not one of Valid Wind Turbine Generators {}".format(generatorName)
            )
        generatorIndex = windTurbineNum
    else:
        windTurbineNum = generatorIndex
        var numWindTurbines: Int = len(state.dataWindTurbine.WindTurbineSys)
        if windTurbineNum > numWindTurbines or windTurbineNum < 1:
            ShowFatalError(
                state,
                "SimWindTurbine: Invalid GeneratorIndex passed={}, Number of Wind Turbine Generators={}, Generator name={}".format(
                    windTurbineNum, numWindTurbines, generatorName
                )
            )
        if generatorName != state.dataWindTurbine.WindTurbineSys[windTurbineNum - 1].Name:
            ShowFatalError(
                state,
                "SimWindTurbine: Invalid GeneratorIndex passed={}, Generator name={}, stored Generator Name for that index={}".format(
                    windTurbineNum, generatorName, state.dataWindTurbine.WindTurbineSys[windTurbineNum - 1].Name
                )
            )
    InitWindTurbine(state, windTurbineNum)
    CalcWindTurbine(state, windTurbineNum, runFlag)
    ReportWindTurbine(state, windTurbineNum)

def GetWTGeneratorResults(
    inout state: EnergyPlusData,
    generatorType: GeneratorType,
    generatorIndex: Int,
    inout generatorPower: Float64,
    inout generatorEnergy: Float64,
    inout thermalPower: Float64,
    inout thermalEnergy: Float64
):
    generatorPower = state.dataWindTurbine.WindTurbineSys[generatorIndex - 1].Power
    generatorEnergy = state.dataWindTurbine.WindTurbineSys[generatorIndex - 1].Energy
    thermalPower = 0.0
    thermalEnergy = 0.0

def GetWindTurbineInput(inout state: EnergyPlusData):
    var routineName: String = "GetWindTurbineInput"
    var currentModuleObject: String = "Generator:WindTurbine"
    var sysEffDefault: Float64 = 0.835
    var maxTSR: Float64 = 12.0
    var defaultPC: Float64 = 0.25
    var maxPowerCoeff: Float64 = 0.59
    var defaultH: Float64 = 50.0
    var errorsFound: Bool = False
    var windTurbineNum: Int
    var numAlphas: Int
    var numNumbers: Int
    var numArgs: Int
    var ioStat: Int
    var cAlphaArgs: List[String]
    var cAlphaFields: List[String]
    var cNumericFields: List[String]
    var rNumericArgs: List[Float64]
    var lAlphaBlanks: List[Bool]
    var lNumericBlanks: List[Bool]

    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, currentModuleObject, numArgs, numAlphas, numNumbers)
    cAlphaArgs = List[String](capacity=numAlphas)
    cAlphaFields = List[String](capacity=numAlphas)
    cNumericFields = List[String](capacity=numNumbers)
    rNumericArgs = List[Float64](repeating=0.0, count=numNumbers)
    lAlphaBlanks = List[Bool](repeating=True, count=numAlphas)
    lNumericBlanks = List[Bool](repeating=True, count=numNumbers)

    var numWindTurbines: Int = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, currentModuleObject)
    state.dataWindTurbine.WindTurbineSys = List[WindTurbineParams](capacity=numWindTurbines)
    for windTurbineNum in range(1, numWindTurbines + 1):
        state.dataInputProcessing.inputProcessor.getObjectItem(
            state,
            currentModuleObject,
            windTurbineNum,
            state.dataIPShortCut.cAlphaArgs,
            numAlphas,
            state.dataIPShortCut.rNumericArgs,
            numNumbers,
            ioStat,
            lNumericBlanks,
            lAlphaBlanks,
            cAlphaFields,
            cNumericFields
        )
        var eoh: ErrorObjectHeader = ErrorObjectHeader(routineName, currentModuleObject, state.dataIPShortCut.cAlphaArgs[0])
        var windTurbine: WindTurbineParams = state.dataWindTurbine.WindTurbineSys[windTurbineNum - 1]
        windTurbine.Name = state.dataIPShortCut.cAlphaArgs[0]  # Name of wind turbine
        if lAlphaBlanks[1]:
            windTurbine.availSched = Sched.GetScheduleAlwaysOn(state)
        elif (windTurbine.availSched = Sched.GetSchedule(state, state.dataIPShortCut.cAlphaArgs[1])) is None:
            ShowSevereItemNotFound(state, eoh, cAlphaFields[1], state.dataIPShortCut.cAlphaArgs[1])
            errorsFound = True
        windTurbine.rotorType = RotorType(getEnumValue(RotorNamesUC, Util.makeUPPER(state.dataIPShortCut.cAlphaArgs[2])))
        if windTurbine.rotorType == RotorType.Invalid:
            if len(state.dataIPShortCut.cAlphaArgs[2]) == 0:
                windTurbine.rotorType = RotorType.HorizontalAxis
            else:
                ShowSevereError(
                    state,
                    "{}=\"{}\" invalid {}=\"{}\".".format(
                        currentModuleObject, state.dataIPShortCut.cAlphaArgs[0], cAlphaFields[2], state.dataIPShortCut.cAlphaArgs[2]
                    )
                )
                errorsFound = True
        windTurbine.controlType = ControlType(getEnumValue(ControlNamesUC, Util.makeUPPER(state.dataIPShortCut.cAlphaArgs[3])))
        if windTurbine.controlType == ControlType.Invalid:
            if len(state.dataIPShortCut.cAlphaArgs[3]) == 0:
                windTurbine.controlType = ControlType.VariableSpeedVariablePitch
            else:
                ShowSevereError(
                    state,
                    "{}=\"{}\" invalid {}=\"{}\".".format(
                        currentModuleObject, state.dataIPShortCut.cAlphaArgs[0], cAlphaFields[3], state.dataIPShortCut.cAlphaArgs[3]
                    )
                )
                errorsFound = True
        windTurbine.RatedRotorSpeed = state.dataIPShortCut.rNumericArgs[0]  # Maximum rotor speed in rpm
        if windTurbine.RatedRotorSpeed <= 0.0:
            if lNumericBlanks[0]:
                ShowSevereError(
                    state,
                    "{}=\"{}\" invalid {} is required but input is blank.".format(
                        currentModuleObject, state.dataIPShortCut.cAlphaArgs[0], cNumericFields[0]
                    )
                )
            else:
                ShowSevereError(
                    state,
                    "{}=\"{}\" invalid {}=[{:.2f}] must be greater than zero.".format(
                        currentModuleObject, state.dataIPShortCut.cAlphaArgs[0], cNumericFields[0], rNumericArgs[0]
                    )
                )
            errorsFound = True
        windTurbine.RotorDiameter = state.dataIPShortCut.rNumericArgs[1]  # Rotor diameter in m
        if windTurbine.RotorDiameter <= 0.0:
            if lNumericBlanks[1]:
                ShowSevereError(
                    state,
                    "{}=\"{}\" invalid {} is required but input is blank.".format(
                        currentModuleObject, state.dataIPShortCut.cAlphaArgs[0], cNumericFields[1]
                    )
                )
            else:
                ShowSevereError(
                    state,
                    "{}=\"{}\" invalid {}=[{:.1f}] must be greater than zero.".format(
                        currentModuleObject, state.dataIPShortCut.cAlphaArgs[0], cNumericFields[1], rNumericArgs[1]
                    )
                )
            errorsFound = True
        windTurbine.RotorHeight = state.dataIPShortCut.rNumericArgs[2]  # Overall height of the rotor
        if windTurbine.RotorHeight <= 0.0:
            if lNumericBlanks[2]:
                ShowSevereError(
                    state,
                    "{}=\"{}\" invalid {} is required but input is blank.".format(
                        currentModuleObject, state.dataIPShortCut.cAlphaArgs[0], cNumericFields[2]
                    )
                )
            else:
                ShowSevereError(
                    state,
                    "{}=\"{}\" invalid {}=[{:.1f}] must be greater than zero.".format(
                        currentModuleObject, state.dataIPShortCut.cAlphaArgs[0], cNumericFields[2], rNumericArgs[2]
                    )
                )
            errorsFound = True
        windTurbine.NumOfBlade = Int(state.dataIPShortCut.rNumericArgs[3])  # Total number of blade
        if windTurbine.NumOfBlade == 0:
            ShowSevereError(
                state,
                "{}=\"{}\" invalid {}=[{:.0f}] must be greater than zero.".format(
                    currentModuleObject, state.dataIPShortCut.cAlphaArgs[0], cNumericFields[3], rNumericArgs[3]
                )
            )
            errorsFound = True
        windTurbine.RatedPower = state.dataIPShortCut.rNumericArgs[4]  # Rated average power
        if windTurbine.RatedPower == 0.0:
            if lNumericBlanks[4]:
                ShowSevereError(
                    state,
                    "{}=\"{}\" invalid {} is required but input is blank.".format(
                        currentModuleObject, state.dataIPShortCut.cAlphaArgs[0], cNumericFields[4]
                    )
                )
            else:
                ShowSevereError(
                    state,
                    "{}=\"{}\" invalid {}=[{:.2f}] must be greater than zero.".format(
                        currentModuleObject, state.dataIPShortCut.cAlphaArgs[0], cNumericFields[4], rNumericArgs[4]
                    )
                )
            errorsFound = True
        windTurbine.RatedWindSpeed = state.dataIPShortCut.rNumericArgs[5]  # Rated wind speed
        if windTurbine.RatedWindSpeed == 0.0:
            if lNumericBlanks[5]:
                ShowSevereError(
                    state,
                    "{}=\"{}\" invalid {} is required but input is blank.".format(
                        currentModuleObject, state.dataIPShortCut.cAlphaArgs[0], cNumericFields[5]
                    )
                )
            else:
                ShowSevereError(
                    state,
                    "{}=\"{}\" invalid {}=[{:.2f}] must be greater than zero.".format(
                        currentModuleObject, state.dataIPShortCut.cAlphaArgs[0], cNumericFields[5], rNumericArgs[5]
                    )
                )
            errorsFound = True
        windTurbine.CutInSpeed = state.dataIPShortCut.rNumericArgs[6]  # Minimum wind speed for system operation
        if windTurbine.CutInSpeed == 0.0:
            if lNumericBlanks[6]:
                ShowSevereError(
                    state,
                    "{}=\"{}\" invalid {} is required but input is blank.".format(
                        currentModuleObject, state.dataIPShortCut.cAlphaArgs[0], cNumericFields[6]
                    )
                )
            else:
                ShowSevereError(
                    state,
                    "{}=\"{}\" invalid {}=[{:.2f}] must be greater than zero.".format(
                        currentModuleObject, state.dataIPShortCut.cAlphaArgs[0], cNumericFields[6], rNumericArgs[6]
                    )
                )
            errorsFound = True
        windTurbine.CutOutSpeed = state.dataIPShortCut.rNumericArgs[7]  # Minimum wind speed for system operation
        if windTurbine.CutOutSpeed == 0.0:
            if lNumericBlanks[7]:
                ShowSevereError(
                    state,
                    "{}=\"{}\" invalid {} is required but input is blank.".format(
                        currentModuleObject, state.dataIPShortCut.cAlphaArgs[0], cNumericFields[7]
                    )
                )
            elif windTurbine.CutOutSpeed <= windTurbine.RatedWindSpeed:
                ShowSevereError(
                    state,
                    "{}=\"{}\" invalid {}=[{:.2f}] must be greater than {}=[{:.2f}].".format(
                        currentModuleObject, state.dataIPShortCut.cAlphaArgs[0], cNumericFields[7], rNumericArgs[7],
                        cNumericFields[5], rNumericArgs[5]
                    )
                )
            else:
                ShowSevereError(
                    state,
                    "{}=\"{}\" invalid {}=[{:.2f}] must be greater than zero".format(
                        currentModuleObject, state.dataIPShortCut.cAlphaArgs[0], cNumericFields[7], rNumericArgs[7]
                    )
                )
            errorsFound = True
        windTurbine.SysEfficiency = state.dataIPShortCut.rNumericArgs[8]  # Overall wind turbine system efficiency
        if lNumericBlanks[8] or windTurbine.SysEfficiency == 0.0 or windTurbine.SysEfficiency > 1.0:
            windTurbine.SysEfficiency = sysEffDefault
            ShowWarningError(
                state,
                "{}=\"{}\" invalid {}=[{:.2f}].".format(
                    currentModuleObject, state.dataIPShortCut.cAlphaArgs[0], cNumericFields[8], state.dataIPShortCut.rNumericArgs[8]
                )
            )
            ShowContinueError(state, "...The default value of {:.3f} was assumed. for {}".format(sysEffDefault, cNumericFields[8]))
        windTurbine.MaxTipSpeedRatio = state.dataIPShortCut.rNumericArgs[9]  # Maximum tip speed ratio
        if windTurbine.MaxTipSpeedRatio == 0.0:
            if lNumericBlanks[9]:
                ShowSevereError(
                    state,
                    "{}=\"{}\" invalid {} is required but input is blank.".format(
                        currentModuleObject, state.dataIPShortCut.cAlphaArgs[0], cNumericFields[9]
                    )
                )
            else:
                ShowSevereError(
                    state,
                    "{}=\"{}\" invalid {}=[{:.2f}] must be greater than zero.".format(
                        currentModuleObject, state.dataIPShortCut.cAlphaArgs[0], cNumericFields[9], rNumericArgs[9]
                    )
                )
            errorsFound = True
        if windTurbine.SysEfficiency > maxTSR:
            windTurbine.SysEfficiency = maxTSR
            ShowWarningError(
                state,
                "{}=\"{}\" invalid {}=[{:.2f}].".format(
                    currentModuleObject, state.dataIPShortCut.cAlphaArgs[0], cNumericFields[9], state.dataIPShortCut.rNumericArgs[9]
                )
            )
            ShowContinueError(state, "...The default value of {:.1f} was assumed. for {}".format(maxTSR, cNumericFields[9]))
        windTurbine.MaxPowerCoeff = state.dataIPShortCut.rNumericArgs[10]  # Maximum power coefficient
        if windTurbine.rotorType == RotorType.HorizontalAxis and windTurbine.MaxPowerCoeff == 0.0:
            if lNumericBlanks[10]:
                ShowSevereError(
                    state,
                    "{}=\"{}\" invalid {} is required but input is blank.".format(
                        currentModuleObject, state.dataIPShortCut.cAlphaArgs[0], cNumericFields[10]
                    )
                )
            else:
                ShowSevereError(
                    state,
                    "{}=\"{}\" invalid {}=[{:.2f}] must be greater than zero.".format(
                        currentModuleObject, state.dataIPShortCut.cAlphaArgs[0], cNumericFields[10], rNumericArgs[10]
                    )
                )
            errorsFound = True
        if windTurbine.MaxPowerCoeff > maxPowerCoeff:
            windTurbine.MaxPowerCoeff = defaultPC
            ShowWarningError(
                state,
                "{}=\"{}\" invalid {}=[{:.2f}].".format(
                    currentModuleObject, state.dataIPShortCut.cAlphaArgs[0], cNumericFields[10], state.dataIPShortCut.rNumericArgs[10]
                )
            )
            ShowContinueError(state, "...The default value of {:.2f} will be used. for {}".format(defaultPC, cNumericFields[10]))
        windTurbine.LocalAnnualAvgWS = state.dataIPShortCut.rNumericArgs[11]  # Local wind speed annually averaged
        if windTurbine.LocalAnnualAvgWS == 0.0:
            if lNumericBlanks[11]:
                ShowWarningError(
                    state,
                    "{}=\"{}\" invalid {} is necessary for accurate prediction but input is blank.".format(
                        currentModuleObject, state.dataIPShortCut.cAlphaArgs[0], cNumericFields[11]
                    )
                )
            else:
                ShowSevereError(
                    state,
                    "{}=\"{}\" invalid {}=[{:.2f}] must be greater than zero.".format(
                        currentModuleObject, state.dataIPShortCut.cAlphaArgs[0], cNumericFields[11], rNumericArgs[11]
                    )
                )
                errorsFound = True
        windTurbine.HeightForLocalWS = state.dataIPShortCut.rNumericArgs[12]  # Height of local meteorological station
        if windTurbine.HeightForLocalWS == 0.0:
            if windTurbine.LocalAnnualAvgWS == 0.0:
                windTurbine.HeightForLocalWS = 0.0
            else:
                windTurbine.HeightForLocalWS = defaultH
                if lNumericBlanks[12]:
                    ShowWarningError(
                        state,
                        "{}=\"{}\" invalid {} is necessary for accurate prediction but input is blank.".format(
                            currentModuleObject, state.dataIPShortCut.cAlphaArgs[0], cNumericFields[12]
                        )
                    )
                    ShowContinueError(state, "...The default value of {:.2f} will be used. for {}".format(defaultH, cNumericFields[12]))
                else:
                    ShowSevereError(
                        state,
                        "{}=\"{}\" invalid {}=[{:.2f}] must be greater than zero.".format(
                            currentModuleObject, state.dataIPShortCut.cAlphaArgs[0], cNumericFields[12], rNumericArgs[12]
                        )
                    )
                    errorsFound = True
        windTurbine.ChordArea = state.dataIPShortCut.rNumericArgs[13]  # Chord area of a single blade for VAWTs
        if windTurbine.rotorType == RotorType.VerticalAxis and windTurbine.ChordArea == 0.0:
            if lNumericBlanks[13]:
                ShowSevereError(
                    state,
                    "{}=\"{}\" invalid {} is required but input is blank.".format(
                        currentModuleObject, state.dataIPShortCut.cAlphaArgs[0], cNumericFields[13]
                    )
                )
            else:
                ShowSevereError(
                    state,
                    "{}=\"{}\" invalid {}=[{:.2f}] must be greater than zero.".format(
                        currentModuleObject, state.dataIPShortCut.cAlphaArgs[0], cNumericFields[13], rNumericArgs[13]
                    )
                )
            errorsFound = True
        windTurbine.DragCoeff = state.dataIPShortCut.rNumericArgs[14]  # Blade drag coefficient
        if windTurbine.rotorType == RotorType.VerticalAxis and windTurbine.DragCoeff == 0.0:
            if lNumericBlanks[14]:
                ShowSevereError(
                    state,
                    "{}=\"{}\" invalid {} is required but input is blank.".format(
                        currentModuleObject, state.dataIPShortCut.cAlphaArgs[0], cNumericFields[14]
                    )
                )
            else:
                ShowSevereError(
                    state,
                    "{}=\"{}\" invalid {}=[{:.2f}] must be greater than zero.".format(
                        currentModuleObject, state.dataIPShortCut.cAlphaArgs[0], cNumericFields[14], rNumericArgs[14]
                    )
                )
            errorsFound = True
        windTurbine.LiftCoeff = state.dataIPShortCut.rNumericArgs[15]  # Blade lift coefficient
        if windTurbine.rotorType == RotorType.VerticalAxis and windTurbine.LiftCoeff == 0.0:
            if lNumericBlanks[15]:
                ShowSevereError(
                    state,
                    "{}=\"{}\" invalid {} is required but input is blank.".format(
                        currentModuleObject, state.dataIPShortCut.cAlphaArgs[0], cNumericFields[15]
                    )
                )
            else:
                ShowSevereError(
                    state,
                    "{}=\"{}\" invalid {}=[{:.2f}] must be greater than zero.".format(
                        currentModuleObject, state.dataIPShortCut.cAlphaArgs[0], cNumericFields[15], rNumericArgs[15]
                    )
                )
            errorsFound = True
        # C1-C6: 0-based indices 16..21 in rNumericArgs
        windTurbine.PowerCoeffs[0] = state.dataIPShortCut.rNumericArgs[16]  # Empirical power coefficient C1
        if lNumericBlanks[16]:
            windTurbine.PowerCoeffs[0] = 0.0
        windTurbine.PowerCoeffs[1] = state.dataIPShortCut.rNumericArgs[17]  # Empirical power coefficient C2
        if lNumericBlanks[17]:
            windTurbine.PowerCoeffs[1] = 0.0
        windTurbine.PowerCoeffs[2] = state.dataIPShortCut.rNumericArgs[18]  # Empirical power coefficient C3
        if lNumericBlanks[18]:
            windTurbine.PowerCoeffs[2] = 0.0
        windTurbine.PowerCoeffs[3] = state.dataIPShortCut.rNumericArgs[19]  # Empirical power coefficient C4
        if lNumericBlanks[19]:
            windTurbine.PowerCoeffs[3] = 0.0
        windTurbine.PowerCoeffs[4] = state.dataIPShortCut.rNumericArgs[20]  # Empirical power coefficient C5
        if lNumericBlanks[20]:
            windTurbine.PowerCoeffs[4] = 0.0
        windTurbine.PowerCoeffs[5] = state.dataIPShortCut.rNumericArgs[21]  # Empirical power coefficient C6
        if lNumericBlanks[21]:
            windTurbine.PowerCoeffs[5] = 0.0

    # Deallocate temporary arrays not needed in Mojo (GC)
    if errorsFound:
        ShowFatalError(state, "{} errors occurred in input.  Program terminates.".format(currentModuleObject))

    for windTurbineNum in range(1, numWindTurbines + 1):
        var windTurbine: WindTurbineParams = state.dataWindTurbine.WindTurbineSys[windTurbineNum - 1]
        SetupOutputVariable(
            state,
            "Generator Produced AC Electricity Rate",
            Units.W,
            windTurbine.Power,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            windTurbine.Name
        )
        SetupOutputVariable(
            state,
            "Generator Produced AC Electricity Energy",
            Units.J,
            windTurbine.Energy,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Sum,
            windTurbine.Name,
            eResource.ElectricityProduced,
            OutputProcessor.Group.Plant,
            OutputProcessor.EndUseCat.WindTurbine
        )
        SetupOutputVariable(
            state,
            "Generator Turbine Local Wind Speed",
            Units.m_s,
            windTurbine.LocalWindSpeed,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            windTurbine.Name
        )
        SetupOutputVariable(
            state,
            "Generator Turbine Local Air Density",
            Units.kg_m3,
            windTurbine.LocalAirDensity,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            windTurbine.Name
        )
        SetupOutputVariable(
            state,
            "Generator Turbine Tip Speed Ratio",
            Units.None,
            windTurbine.TipSpeedRatio,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            windTurbine.Name
        )
        if windTurbine.rotorType == RotorType.HorizontalAxis:
            SetupOutputVariable(
                state,
                "Generator Turbine Power Coefficient",
                Units.None,
                windTurbine.PowerCoeff,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                windTurbine.Name
            )
        elif windTurbine.rotorType == RotorType.VerticalAxis:
            SetupOutputVariable(
                state,
                "Generator Turbine Chordal Component Velocity",
                Units.m_s,
                windTurbine.ChordalVel,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                windTurbine.Name
            )
            SetupOutputVariable(
                state,
                "Generator Turbine Normal Component Velocity",
                Units.m_s,
                windTurbine.NormalVel,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                windTurbine.Name
            )
            SetupOutputVariable(
                state,
                "Generator Turbine Relative Flow Velocity",
                Units.m_s,
                windTurbine.RelFlowVel,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                windTurbine.Name
            )
            SetupOutputVariable(
                state,
                "Generator Turbine Attack Angle",
                Units.deg,
                windTurbine.AngOfAttack,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                windTurbine.Name
            )

def InitWindTurbine(inout state: EnergyPlusData, windTurbineNum: Int):
    var tabChr: Int8 = '\t'  # Tab character
    var monthWS: List[Float64] = List[Float64](repeating=0.0, count=12)
    if state.dataWindTurbine.MyOneTimeFlag:
        var annualTMYWS: Float64 = 0.0
        if fileExists(state.files.inStatFilePath.filePath):
            var statFile = state.files.inStatFilePath.open(state, "InitWindTurbine")
            var wsStatFound: Bool = False
            while not statFile.eof():
                var lineIn: String = statFile.readLine()
                var lnPtr: Int = lineIn.find("Wind Speed")
                if lnPtr == -1:
                    continue
                while not statFile.eof():
                    lineIn = statFile.readLine()
                    lnPtr = lineIn.find("Daily Avg")
                    if lnPtr == -1:
                        continue
                    lineIn = lineIn[lnPtr + 10:]
                    for i in range(12):
                        monthWS[i] = 0.0
                    wsStatFound = True
                    var warningShown: Bool = False
                    for mon in range(12):
                        lnPtr = lineIn.find(tabChr)
                        if lnPtr != 1:
                            if (lnPtr == -1) or (len(lineIn[0:lnPtr].strip()) != 0):
                                if lnPtr != -1:
                                    var error: Bool = False
                                    monthWS[mon] = Util.ProcessNumber(lineIn[0:lnPtr], error)
                                    if error:

                                    lineIn = lineIn[lnPtr + 1:]
                            else:
                                if not warningShown:
                                    ShowWarningError(
                                        state,
                                        "InitWindTurbine: read from {} file shows <365 days in weather file. Annual average wind speed used will be inaccurate.".format(
                                            state.files.inStatFilePath.filePath
                                        )
                                    )
                                    lineIn = lineIn[lnPtr + 1:]
                                    warningShown = True
                        else:
                            if not warningShown:
                                ShowWarningError(
                                    state,
                                    "InitWindTurbine: read from {} file shows <365 days in weather file. Annual average wind speed used will be inaccurate.".format(
                                        state.files.inStatFilePath.filePath
                                    )
                                )
                                lineIn = lineIn[lnPtr + 1:]
                                warningShown = True
                    break
                if wsStatFound:
                    break
            if wsStatFound:
                annualTMYWS = sum(monthWS) / 12.0
            else:
                ShowWarningError(
                    state,
                    "InitWindTurbine: stat file did not include Wind Speed statistics. TMY Wind Speed adjusted at the height is used."
                )
        else:
            ShowWarningError(state, "InitWindTurbine: stat file missing. TMY Wind Speed adjusted at the height is used.")
        for wt in state.dataWindTurbine.WindTurbineSys:
            wt.AnnualTMYWS = annualTMYWS
        state.dataWindTurbine.MyOneTimeFlag = False

    var windTurbine: WindTurbineParams = state.dataWindTurbine.WindTurbineSys[windTurbineNum - 1]
    if windTurbine.AnnualTMYWS > 0.0 and windTurbine.WSFactor == 0.0 and windTurbine.LocalAnnualAvgWS > 0:
        var localTMYWS: Float64 = windTurbine.AnnualTMYWS * state.dataEnvrn.WeatherFileWindModCoeff * \
            (windTurbine.HeightForLocalWS / state.dataEnvrn.SiteWindBLHeight) ** state.dataEnvrn.SiteWindExp
        windTurbine.WSFactor = localTMYWS / windTurbine.LocalAnnualAvgWS
    if windTurbine.WSFactor == 0.0:
        windTurbine.WSFactor = 1.0
    windTurbine.Power = 0.0
    windTurbine.TotPower = 0.0
    windTurbine.PowerCoeff = 0.0
    windTurbine.TipSpeedRatio = 0.0
    windTurbine.ChordalVel = 0.0
    windTurbine.NormalVel = 0.0
    windTurbine.RelFlowVel = 0.0
    windTurbine.AngOfAttack = 0.0
    windTurbine.TanForce = 0.0
    windTurbine.NorForce = 0.0
    windTurbine.TotTorque = 0.0

def CalcWindTurbine(inout state: EnergyPlusData, windTurbineNum: Int, runFlag: Bool):
    # using declarations - keep as local aliases
    alias OutBaroPressAt = DataEnvironment.OutBaroPressAt
    alias OutDryBulbTempAt = DataEnvironment.OutDryBulbTempAt
    alias OutWetBulbTempAt = DataEnvironment.OutWetBulbTempAt
    alias PsyRhoAirFnPbTdbW = Psychrometrics.PsyRhoAirFnPbTdbW
    alias PsyWFnTdbTwbPb = Psychrometrics.PsyWFnTdbTwbPb
    var maxTheta: Float64 = 90.0
    var maxDegree: Float64 = 360.0
    var secInMin: Float64 = 60.0
    var localWindSpeed: Float64
    var rotorH: Float64
    var rotorD: Float64
    var localHumRat: Float64
    var localAirDensity: Float64
    var powerCoeff: Float64
    var sweptArea: Float64
    var wtPower: Float64 = 0.0
    var power: Float64
    var tipSpeedRatio: Float64
    var tipSpeedRatioAtI: Float64
    var azimuthAng: Float64
    var chordalVel: Float64
    var normalVel: Float64
    var angOfAttack: Float64
    var relFlowVel: Float64
    var tanForce: Float64
    var norForce: Float64
    var rotorVel: Float64
    var avgTanForce: Float64
    var constant: Float64
    var intRelFlowVel: Float64
    var totTorque: Float64
    var omega: Float64
    var tanForceCoeff: Float64
    var norForceCoeff: Float64
    var period: Float64
    var c1: Float64
    var c2: Float64
    var c3: Float64
    var c4: Float64
    var c5: Float64
    var c6: Float64
    var localTemp: Float64
    var localPress: Float64
    var inducedVel: Float64
    var maxPowerCoeff: Float64
    var rotorSpeed: Float64
    var windTurbine: WindTurbineParams = state.dataWindTurbine.WindTurbineSys[windTurbineNum - 1]
    rotorH = windTurbine.RotorHeight
    rotorD = windTurbine.RotorDiameter
    rotorSpeed = windTurbine.RatedRotorSpeed
    localTemp = OutDryBulbTempAt(state, rotorH)
    localPress = OutBaroPressAt(state, rotorH)
    localHumRat = PsyWFnTdbTwbPb(state, localTemp, OutWetBulbTempAt(state, rotorH), localPress)
    localAirDensity = PsyRhoAirFnPbTdbW(state, localPress, localTemp, localHumRat)
    localWindSpeed = DataEnvironment.WindSpeedAt(state, rotorH)
    localWindSpeed /= windTurbine.WSFactor
    if windTurbine.availSched.getCurrentVal() > 0 and localWindSpeed > windTurbine.CutInSpeed and localWindSpeed < windTurbine.CutOutSpeed:
        period = 2.0 * Pi
        omega = (rotorSpeed * period) / secInMin
        sweptArea = (Pi * pow_2(rotorD)) / 4
        tipSpeedRatio = (omega * (rotorD / 2.0)) / localWindSpeed
        if tipSpeedRatio > windTurbine.MaxTipSpeedRatio:
            tipSpeedRatio = windTurbine.MaxTipSpeedRatio
        if windTurbine.rotorType == RotorType.HorizontalAxis:
            # Horizontal axis wind turbine
            maxPowerCoeff = windTurbine.MaxPowerCoeff
            c1 = windTurbine.PowerCoeffs[0]
            c2 = windTurbine.PowerCoeffs[1]
            c3 = windTurbine.PowerCoeffs[2]
            c4 = windTurbine.PowerCoeffs[3]
            c5 = windTurbine.PowerCoeffs[4]
            c6 = windTurbine.PowerCoeffs[5]
            var localWindSpeed_3: Float64 = pow_3(localWindSpeed)
            if c1 > 0.0 and c2 > 0.0 and c3 > 0.0 and c4 >= 0.0 and c5 > 0.0 and c6 > 0.0:
                tipSpeedRatioAtI = tipSpeedRatio / (1.0 - (tipSpeedRatio * 0.035))
                powerCoeff = c1 * ((c2 / tipSpeedRatioAtI) - c5) * Math.exp(-(c6 / tipSpeedRatioAtI))
                if powerCoeff > maxPowerCoeff:
                    powerCoeff = maxPowerCoeff
                wtPower = 0.5 * localAirDensity * powerCoeff * sweptArea * localWindSpeed_3
            else:
                # Simple approximation
                wtPower = 0.5 * localAirDensity * sweptArea * localWindSpeed_3 * maxPowerCoeff
                powerCoeff = maxPowerCoeff
            if localWindSpeed >= windTurbine.RatedWindSpeed or wtPower > windTurbine.RatedPower:
                wtPower = windTurbine.RatedPower
                powerCoeff = wtPower / (0.5 * localAirDensity * sweptArea * localWindSpeed_3)
            windTurbine.PowerCoeff = powerCoeff
        elif windTurbine.rotorType == RotorType.VerticalAxis:
            # Vertical axis wind turbine
            rotorVel = omega * (rotorD / 2.0)
            if tipSpeedRatio >= windTurbine.MaxTipSpeedRatio:
                rotorVel = localWindSpeed * windTurbine.MaxTipSpeedRatio
                omega = rotorVel / (rotorD / 2.0)
            azimuthAng = maxDegree / Float64(windTurbine.NumOfBlade)
            if azimuthAng > maxTheta:
                azimuthAng -= maxTheta
                if azimuthAng == maxTheta:
                    azimuthAng = 0.0
            elif azimuthAng == maxTheta:
                azimuthAng = 0.0
            inducedVel = localWindSpeed * 2.0 / 3.0
            var sin_azimuthAng: Float64 = Math.sin(azimuthAng * DegToRad)
            var cos_azimuthAng: Float64 = Math.cos(azimuthAng * DegToRad)
            chordalVel = rotorVel + inducedVel * cos_azimuthAng
            normalVel = inducedVel * sin_azimuthAng
            relFlowVel = Math.sqrt(pow_2(chordalVel) + pow_2(normalVel))
            angOfAttack = Math.atan((sin_azimuthAng / ((rotorVel / localWindSpeed) / (inducedVel / localWindSpeed) + cos_azimuthAng)))
            var sin_angOfAttack: Float64 = Math.sin(angOfAttack * DegToRad)
            var cos_angOfAttack: Float64 = Math.cos(angOfAttack * DegToRad)
            tanForceCoeff = Math.abs(windTurbine.LiftCoeff * sin_angOfAttack - windTurbine.DragCoeff * cos_angOfAttack)
            norForceCoeff = windTurbine.LiftCoeff * cos_angOfAttack + windTurbine.DragCoeff * sin_angOfAttack
            var relFlowVel_2: Float64 = pow_2(relFlowVel)
            var density_fac: Float64 = 0.5 * localAirDensity * windTurbine.ChordArea * relFlowVel_2
            tanForce = tanForceCoeff * density_fac
            norForce = norForceCoeff * density_fac
            constant = (1.0 / period) * (tanForce / relFlowVel_2)
            intRelFlowVel = pow_2(rotorVel) * period + pow_2(inducedVel) * period
            avgTanForce = constant * intRelFlowVel
            totTorque = Float64(windTurbine.NumOfBlade) * avgTanForce * (rotorD / 2.0)
            wtPower = totTorque * omega
            if wtPower > windTurbine.RatedPower:
                wtPower = windTurbine.RatedPower
            windTurbine.ChordalVel = chordalVel
            windTurbine.NormalVel = normalVel
            windTurbine.RelFlowVel = relFlowVel
            windTurbine.TanForce = tanForce
            windTurbine.NorForce = norForce
            windTurbine.TotTorque = totTorque
        else:
            # default: assert false
            assert(False)
        if wtPower > windTurbine.RatedPower:
            wtPower = windTurbine.RatedPower
        power = wtPower * windTurbine.SysEfficiency
        windTurbine.Power = power
        windTurbine.TotPower = wtPower
        windTurbine.LocalWindSpeed = localWindSpeed
        windTurbine.LocalAirDensity = localAirDensity
        windTurbine.TipSpeedRatio = tipSpeedRatio
    else:
        # System is off
        windTurbine.Power = 0.0
        windTurbine.TotPower = 0.0
        windTurbine.PowerCoeff = 0.0
        windTurbine.LocalWindSpeed = localWindSpeed
        windTurbine.LocalAirDensity = localAirDensity
        windTurbine.TipSpeedRatio = 0.0
        windTurbine.ChordalVel = 0.0
        windTurbine.NormalVel = 0.0
        windTurbine.RelFlowVel = 0.0
        windTurbine.AngOfAttack = 0.0
        windTurbine.TanForce = 0.0
        windTurbine.NorForce = 0.0
        windTurbine.TotTorque = 0.0

def ReportWindTurbine(inout state: EnergyPlusData, windTurbineNum: Int):
    var timeStepSysSec: Float64 = state.dataHVACGlobal.TimeStepSysSec
    var windTurbine: WindTurbineParams = state.dataWindTurbine.WindTurbineSys[windTurbineNum - 1]
    windTurbine.Energy = windTurbine.Power * timeStepSysSec