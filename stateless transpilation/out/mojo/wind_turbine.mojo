from math import sin, cos, sqrt, exp, atan, pi, pow
from collections import InlineArray

alias TabChr = "\t"
alias MaxTheta = 90.0
alias MaxDegree = 360.0
alias SecInMin = 60.0
alias SysEffDefault = 0.835
alias MaxTSR = 12.0
alias DefaultPC = 0.25
alias MaxPowerCoeff = 0.59
alias DefaultH = 50.0


@value
struct RotorType:
    alias Invalid = -1
    alias HorizontalAxis = 0
    alias VerticalAxis = 1
    alias Num = 2


@value
struct ControlType:
    alias Invalid = -1
    alias FixedSpeedFixedPitch = 0
    alias FixedSpeedVariablePitch = 1
    alias VariableSpeedFixedPitch = 2
    alias VariableSpeedVariablePitch = 3
    alias Num = 4


@dataclass
struct WindTurbineParams:
    var Name: String
    var rotorType: Int
    var controlType: Int
    var availSched: UnsafePointer[Object]
    var NumOfBlade: Int
    var RatedRotorSpeed: Float64
    var RotorDiameter: Float64
    var RotorHeight: Float64
    var RatedPower: Float64
    var RatedWindSpeed: Float64
    var CutInSpeed: Float64
    var CutOutSpeed: Float64
    var SysEfficiency: Float64
    var MaxTipSpeedRatio: Float64
    var MaxPowerCoeff: Float64
    var LocalAnnualAvgWS: Float64
    var AnnualTMYWS: Float64
    var HeightForLocalWS: Float64
    var ChordArea: Float64
    var DragCoeff: Float64
    var LiftCoeff: Float64
    var PowerCoeffs: InlineArray[Float64, 6]
    var TotPower: Float64
    var Power: Float64
    var TotEnergy: Float64
    var Energy: Float64
    var LocalWindSpeed: Float64
    var LocalAirDensity: Float64
    var PowerCoeff: Float64
    var ChordalVel: Float64
    var NormalVel: Float64
    var RelFlowVel: Float64
    var TipSpeedRatio: Float64
    var WSFactor: Float64
    var AngOfAttack: Float64
    var IntRelFlowVel: Float64
    var TanForce: Float64
    var NorForce: Float64
    var TotTorque: Float64
    var AzimuthAng: Float64

    fn __init__(inout self):
        self.Name = String()
        self.rotorType = RotorType.Invalid
        self.controlType = ControlType.Invalid
        self.availSched = UnsafePointer[Object]()
        self.NumOfBlade = 0
        self.RatedRotorSpeed = 0.0
        self.RotorDiameter = 0.0
        self.RotorHeight = 0.0
        self.RatedPower = 0.0
        self.RatedWindSpeed = 0.0
        self.CutInSpeed = 0.0
        self.CutOutSpeed = 0.0
        self.SysEfficiency = 0.0
        self.MaxTipSpeedRatio = 0.0
        self.MaxPowerCoeff = 0.0
        self.LocalAnnualAvgWS = 0.0
        self.AnnualTMYWS = 0.0
        self.HeightForLocalWS = 0.0
        self.ChordArea = 0.0
        self.DragCoeff = 0.0
        self.LiftCoeff = 0.0
        self.PowerCoeffs = InlineArray[Float64, 6](0.0)
        self.TotPower = 0.0
        self.Power = 0.0
        self.TotEnergy = 0.0
        self.Energy = 0.0
        self.LocalWindSpeed = 0.0
        self.LocalAirDensity = 0.0
        self.PowerCoeff = 0.0
        self.ChordalVel = 0.0
        self.NormalVel = 0.0
        self.RelFlowVel = 0.0
        self.TipSpeedRatio = 0.0
        self.WSFactor = 0.0
        self.AngOfAttack = 0.0
        self.IntRelFlowVel = 0.0
        self.TanForce = 0.0
        self.NorForce = 0.0
        self.TotTorque = 0.0
        self.AzimuthAng = 0.0


@dataclass
struct WindTurbineData:
    var GetInputFlag: Bool
    var MyOneTimeFlag: Bool
    var WindTurbineSys: List[WindTurbineParams]

    fn __init__(inout self):
        self.GetInputFlag = True
        self.MyOneTimeFlag = True
        self.WindTurbineSys = List[WindTurbineParams]()

    fn init_constant_state(inout self, state: UnsafePointer[Object]) -> None:
        pass

    fn init_state(inout self, state: UnsafePointer[Object]) -> None:
        pass

    fn clear_state(inout self) -> None:
        self.GetInputFlag = True
        self.MyOneTimeFlag = True
        self.WindTurbineSys = List[WindTurbineParams]()


@value
struct ControlNamesUC:
    @staticmethod
    fn get() -> InlineArray[StringLiteral, 4]:
        var names = InlineArray[StringLiteral, 4]()
        names[0] = "FIXEDSPEEDFIXEDPITCH"
        names[1] = "FIXEDSPEEDVARIABLEPITCH"
        names[2] = "VARIABLESPEEDFIXEDPITCH"
        names[3] = "VARIABLESPEEDVARIABLEPITCH"
        return names


@value
struct RotorNamesUC:
    @staticmethod
    fn get() -> InlineArray[StringLiteral, 2]:
        var names = InlineArray[StringLiteral, 2]()
        names[0] = "HORIZONTALAXISWINDTURBINE"
        names[1] = "VERTICALAXISWINDTURBINE"
        return names


fn sim_wind_turbine(
    state: UnsafePointer[Object],
    generator_type: Int,
    generator_name: String,
    inout generator_index: Int,
    run_flag: Bool,
    wt_load: Float64,
) -> None:
    if state[].dataWindTurbine.GetInputFlag:
        get_wind_turbine_input(state)
        state[].dataWindTurbine.GetInputFlag = False

    var wind_turbine_num: Int
    if generator_index == 0:
        wind_turbine_num = state[].dataUtility.FindItemInList(
            generator_name, state[].dataWindTurbine.WindTurbineSys
        )
        if wind_turbine_num == 0:
            state[].dataUtility.ShowFatalError(
                state,
                String("SimWindTurbine: Specified Generator not one of Valid Wind Turbine Generators ")
                + generator_name,
            )
        generator_index = wind_turbine_num
    else:
        wind_turbine_num = generator_index
        var num_wind_turbines = len(state[].dataWindTurbine.WindTurbineSys)
        if wind_turbine_num > num_wind_turbines or wind_turbine_num < 1:
            state[].dataUtility.ShowFatalError(
                state,
                String("SimWindTurbine: Invalid GeneratorIndex passed=")
                + String(wind_turbine_num)
                + String(", Number of Wind Turbine Generators=")
                + String(num_wind_turbines)
                + String(", Generator name=")
                + generator_name,
            )
        if generator_name != state[].dataWindTurbine.WindTurbineSys[wind_turbine_num - 1].Name:
            state[].dataUtility.ShowFatalError(
                state,
                String("SimMWindTurbine: Invalid GeneratorIndex passed=")
                + String(wind_turbine_num)
                + String(", Generator name=")
                + generator_name
                + String(", stored Generator Name for that index=")
                + state[].dataWindTurbine.WindTurbineSys[wind_turbine_num - 1].Name,
            )

    init_wind_turbine(state, wind_turbine_num)
    calc_wind_turbine(state, wind_turbine_num, run_flag)
    report_wind_turbine(state, wind_turbine_num)


fn get_wt_generator_results(
    state: UnsafePointer[Object],
    generator_type: Int,
    generator_index: Int,
    inout generator_power: Float64,
    inout generator_energy: Float64,
    inout thermal_power: Float64,
    inout thermal_energy: Float64,
) -> None:
    generator_power = state[].dataWindTurbine.WindTurbineSys[generator_index - 1].Power
    generator_energy = state[].dataWindTurbine.WindTurbineSys[generator_index - 1].Energy
    thermal_power = 0.0
    thermal_energy = 0.0


fn get_wind_turbine_input(state: UnsafePointer[Object]) -> None:
    var routine_name = String("GetWindTurbineInput")
    var current_module_object = String("Generator:WindTurbine")

    var errors_found = False
    var num_wind_turbines = state[].dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, current_module_object
    )

    state[].dataWindTurbine.WindTurbineSys = List[WindTurbineParams]()
    for _ in range(num_wind_turbines):
        state[].dataWindTurbine.WindTurbineSys.append(WindTurbineParams())

    for wind_turbine_num in range(num_wind_turbines):
        var c_alpha_args = List[String]()
        var c_alpha_fields = List[String]()
        var c_numeric_fields = List[String]()
        var r_numeric_args = List[Float64]()
        var l_alpha_blanks = List[Bool]()
        var l_numeric_blanks = List[Bool]()

        state[].dataInputProcessing.inputProcessor.getObjectItem(
            state,
            current_module_object,
            wind_turbine_num + 1,
            c_alpha_args,
            c_alpha_fields,
            r_numeric_args,
            c_numeric_fields,
            l_numeric_blanks,
            l_alpha_blanks,
        )

        var wind_turbine = UnsafePointer[WindTurbineParams](
            __mlir_op.`llvm.addressof`(
                state[].dataWindTurbine.WindTurbineSys[wind_turbine_num]
            )
        )

        wind_turbine[].Name = state[].dataIPShortCut.cAlphaArgs[0]

        if l_alpha_blanks[1]:
            wind_turbine[].availSched = state[].dataScheduleMgr.GetScheduleAlwaysOn(state)
        else:
            wind_turbine[].availSched = state[].dataScheduleMgr.GetSchedule(
                state, state[].dataIPShortCut.cAlphaArgs[1]
            )
            if wind_turbine[].availSched == UnsafePointer[Object]():
                state[].dataUtility.ShowSevereItemNotFound(
                    state,
                    routine_name,
                    current_module_object,
                    c_alpha_fields[1],
                    state[].dataIPShortCut.cAlphaArgs[1],
                )
                errors_found = True

        var rotor_type_val = state[].dataInputProcessing.getEnumValue(
            RotorNamesUC.get(), state[].dataUtility.makeUPPER(state[].dataIPShortCut.cAlphaArgs[2])
        )
        if rotor_type_val == -1:
            if state[].dataIPShortCut.cAlphaArgs[2] == "":
                wind_turbine[].rotorType = RotorType.HorizontalAxis
            else:
                state[].dataUtility.ShowSevereError(
                    state,
                    String(current_module_object)
                    + String('="')
                    + state[].dataIPShortCut.cAlphaArgs[0]
                    + String('" invalid ')
                    + c_alpha_fields[2]
                    + String('="')
                    + state[].dataIPShortCut.cAlphaArgs[2]
                    + String('".'),
                )
                errors_found = True
        else:
            wind_turbine[].rotorType = rotor_type_val

        var control_type_val = state[].dataInputProcessing.getEnumValue(
            ControlNamesUC.get(), state[].dataUtility.makeUPPER(state[].dataIPShortCut.cAlphaArgs[3])
        )
        if control_type_val == -1:
            if state[].dataIPShortCut.cAlphaArgs[3] == "":
                wind_turbine[].controlType = ControlType.VariableSpeedVariablePitch
            else:
                state[].dataUtility.ShowSevereError(
                    state,
                    String(current_module_object)
                    + String('="')
                    + state[].dataIPShortCut.cAlphaArgs[0]
                    + String('" invalid ')
                    + c_alpha_fields[3]
                    + String('="')
                    + state[].dataIPShortCut.cAlphaArgs[3]
                    + String('".'),
                )
                errors_found = True
        else:
            wind_turbine[].controlType = control_type_val

        wind_turbine[].RatedRotorSpeed = state[].dataIPShortCut.rNumericArgs[0]
        if wind_turbine[].RatedRotorSpeed <= 0.0:
            if l_numeric_blanks[0]:
                state[].dataUtility.ShowSevereError(
                    state,
                    String(current_module_object)
                    + String('="')
                    + state[].dataIPShortCut.cAlphaArgs[0]
                    + String('" invalid ')
                    + c_numeric_fields[0]
                    + String(" is required but input is blank."),
                )
            else:
                state[].dataUtility.ShowSevereError(
                    state,
                    String(current_module_object)
                    + String('="')
                    + state[].dataIPShortCut.cAlphaArgs[0]
                    + String('" invalid ')
                    + c_numeric_fields[0]
                    + String("=[")
                    + String(state[].dataIPShortCut.rNumericArgs[0])
                    + String("] must be greater than zero."),
                )
            errors_found = True

        wind_turbine[].RotorDiameter = state[].dataIPShortCut.rNumericArgs[1]
        if wind_turbine[].RotorDiameter <= 0.0:
            if l_numeric_blanks[1]:
                state[].dataUtility.ShowSevereError(
                    state,
                    String(current_module_object)
                    + String('="')
                    + state[].dataIPShortCut.cAlphaArgs[0]
                    + String('" invalid ')
                    + c_numeric_fields[1]
                    + String(" is required but input is blank."),
                )
            else:
                state[].dataUtility.ShowSevereError(
                    state,
                    String(current_module_object)
                    + String('="')
                    + state[].dataIPShortCut.cAlphaArgs[0]
                    + String('" invalid ')
                    + c_numeric_fields[1]
                    + String("=[")
                    + String(state[].dataIPShortCut.rNumericArgs[1])
                    + String("] must be greater than zero."),
                )
            errors_found = True

        wind_turbine[].RotorHeight = state[].dataIPShortCut.rNumericArgs[2]
        if wind_turbine[].RotorHeight <= 0.0:
            if l_numeric_blanks[2]:
                state[].dataUtility.ShowSevereError(
                    state,
                    String(current_module_object)
                    + String('="')
                    + state[].dataIPShortCut.cAlphaArgs[0]
                    + String('" invalid ')
                    + c_numeric_fields[2]
                    + String(" is required but input is blank."),
                )
            else:
                state[].dataUtility.ShowSevereError(
                    state,
                    String(current_module_object)
                    + String('="')
                    + state[].dataIPShortCut.cAlphaArgs[0]
                    + String('" invalid ')
                    + c_numeric_fields[2]
                    + String("=[")
                    + String(state[].dataIPShortCut.rNumericArgs[2])
                    + String("] must be greater than zero."),
                )
            errors_found = True

        wind_turbine[].NumOfBlade = Int(state[].dataIPShortCut.rNumericArgs[3])
        if wind_turbine[].NumOfBlade == 0:
            state[].dataUtility.ShowSevereError(
                state,
                String(current_module_object)
                + String('="')
                + state[].dataIPShortCut.cAlphaArgs[0]
                + String('" invalid ')
                + c_numeric_fields[3]
                + String("=[")
                + String(state[].dataIPShortCut.rNumericArgs[3])
                + String("] must be greater than zero."),
            )
            errors_found = True

        wind_turbine[].RatedPower = state[].dataIPShortCut.rNumericArgs[4]
        if wind_turbine[].RatedPower == 0.0:
            if l_numeric_blanks[4]:
                state[].dataUtility.ShowSevereError(
                    state,
                    String(current_module_object)
                    + String('="')
                    + state[].dataIPShortCut.cAlphaArgs[0]
                    + String('" invalid ')
                    + c_numeric_fields[4]
                    + String(" is required but input is blank."),
                )
            else:
                state[].dataUtility.ShowSevereError(
                    state,
                    String(current_module_object)
                    + String('="')
                    + state[].dataIPShortCut.cAlphaArgs[0]
                    + String('" invalid ')
                    + c_numeric_fields[4]
                    + String("=[")
                    + String(state[].dataIPShortCut.rNumericArgs[4])
                    + String("] must be greater than zero."),
                )
            errors_found = True

        wind_turbine[].RatedWindSpeed = state[].dataIPShortCut.rNumericArgs[5]
        if wind_turbine[].RatedWindSpeed == 0.0:
            if l_numeric_blanks[5]:
                state[].dataUtility.ShowSevereError(
                    state,
                    String(current_module_object)
                    + String('="')
                    + state[].dataIPShortCut.cAlphaArgs[0]
                    + String('" invalid ')
                    + c_numeric_fields[5]
                    + String(" is required but input is blank."),
                )
            else:
                state[].dataUtility.ShowSevereError(
                    state,
                    String(current_module_object)
                    + String('="')
                    + state[].dataIPShortCut.cAlphaArgs[0]
                    + String('" invalid ')
                    + c_numeric_fields[5]
                    + String("=[")
                    + String(state[].dataIPShortCut.rNumericArgs[5])
                    + String("] must be greater than zero."),
                )
            errors_found = True

        wind_turbine[].CutInSpeed = state[].dataIPShortCut.rNumericArgs[6]
        if wind_turbine[].CutInSpeed == 0.0:
            if l_numeric_blanks[6]:
                state[].dataUtility.ShowSevereError(
                    state,
                    String(current_module_object)
                    + String('="')
                    + state[].dataIPShortCut.cAlphaArgs[0]
                    + String('" invalid ')
                    + c_numeric_fields[6]
                    + String(" is required but input is blank."),
                )
            else:
                state[].dataUtility.ShowSevereError(
                    state,
                    String(current_module_object)
                    + String('="')
                    + state[].dataIPShortCut.cAlphaArgs[0]
                    + String('" invalid ')
                    + c_numeric_fields[6]
                    + String("=[")
                    + String(state[].dataIPShortCut.rNumericArgs[6])
                    + String("] must be greater than zero."),
                )
            errors_found = True

        wind_turbine[].CutOutSpeed = state[].dataIPShortCut.rNumericArgs[7]
        if wind_turbine[].CutOutSpeed == 0.0:
            if l_numeric_blanks[7]:
                state[].dataUtility.ShowSevereError(
                    state,
                    String(current_module_object)
                    + String('="')
                    + state[].dataIPShortCut.cAlphaArgs[0]
                    + String('" invalid ')
                    + c_numeric_fields[7]
                    + String(" is required but input is blank."),
                )
            else:
                state[].dataUtility.ShowSevereError(
                    state,
                    String(current_module_object)
                    + String('="')
                    + state[].dataIPShortCut.cAlphaArgs[0]
                    + String('" invalid ')
                    + c_numeric_fields[7]
                    + String("=[")
                    + String(state[].dataIPShortCut.rNumericArgs[7])
                    + String("] must be greater than zero"),
                )
            errors_found = True

        wind_turbine[].SysEfficiency = state[].dataIPShortCut.rNumericArgs[8]
        if (
            l_numeric_blanks[8]
            or wind_turbine[].SysEfficiency == 0.0
            or wind_turbine[].SysEfficiency > 1.0
        ):
            wind_turbine[].SysEfficiency = SysEffDefault
            state[].dataUtility.ShowWarningError(
                state,
                String(current_module_object)
                + String('="')
                + state[].dataIPShortCut.cAlphaArgs[0]
                + String('" invalid ')
                + c_numeric_fields[8]
                + String("=[")
                + String(state[].dataIPShortCut.rNumericArgs[8])
                + String("]."),
            )
            state[].dataUtility.ShowContinueError(
                state,
                String("...The default value of ")
                + String(SysEffDefault)
                + String(" was assumed. for ")
                + c_numeric_fields[8],
            )

        wind_turbine[].MaxTipSpeedRatio = state[].dataIPShortCut.rNumericArgs[9]
        if wind_turbine[].MaxTipSpeedRatio == 0.0:
            if l_numeric_blanks[9]:
                state[].dataUtility.ShowSevereError(
                    state,
                    String(current_module_object)
                    + String('="')
                    + state[].dataIPShortCut.cAlphaArgs[0]
                    + String('" invalid ')
                    + c_numeric_fields[9]
                    + String(" is required but input is blank."),
                )
            else:
                state[].dataUtility.ShowSevereError(
                    state,
                    String(current_module_object)
                    + String('="')
                    + state[].dataIPShortCut.cAlphaArgs[0]
                    + String('" invalid ')
                    + c_numeric_fields[9]
                    + String("=[")
                    + String(state[].dataIPShortCut.rNumericArgs[9])
                    + String("] must be greater than zero."),
                )
            errors_found = True
        if wind_turbine[].SysEfficiency > MaxTSR:
            wind_turbine[].SysEfficiency = MaxTSR
            state[].dataUtility.ShowWarningError(
                state,
                String(current_module_object)
                + String('="')
                + state[].dataIPShortCut.cAlphaArgs[0]
                + String('" invalid ')
                + c_numeric_fields[9]
                + String("=[")
                + String(state[].dataIPShortCut.rNumericArgs[9])
                + String("]."),
            )
            state[].dataUtility.ShowContinueError(
                state,
                String("...The default value of ")
                + String(MaxTSR)
                + String(" was assumed. for ")
                + c_numeric_fields[9],
            )

        wind_turbine[].MaxPowerCoeff = state[].dataIPShortCut.rNumericArgs[10]
        if wind_turbine[].rotorType == RotorType.HorizontalAxis and wind_turbine[].MaxPowerCoeff == 0.0:
            if l_numeric_blanks[10]:
                state[].dataUtility.ShowSevereError(
                    state,
                    String(current_module_object)
                    + String('="')
                    + state[].dataIPShortCut.cAlphaArgs[0]
                    + String('" invalid ')
                    + c_numeric_fields[10]
                    + String(" is required but input is blank."),
                )
            else:
                state[].dataUtility.ShowSevereError(
                    state,
                    String(current_module_object)
                    + String('="')
                    + state[].dataIPShortCut.cAlphaArgs[0]
                    + String('" invalid ')
                    + c_numeric_fields[10]
                    + String("=[")
                    + String(state[].dataIPShortCut.rNumericArgs[10])
                    + String("] must be greater than zero."),
                )
            errors_found = True
        if wind_turbine[].MaxPowerCoeff > MaxPowerCoeff:
            wind_turbine[].MaxPowerCoeff = DefaultPC
            state[].dataUtility.ShowWarningError(
                state,
                String(current_module_object)
                + String('="')
                + state[].dataIPShortCut.cAlphaArgs[0]
                + String('" invalid ')
                + c_numeric_fields[10]
                + String("=[")
                + String(state[].dataIPShortCut.rNumericArgs[10])
                + String("]."),
            )
            state[].dataUtility.ShowContinueError(
                state,
                String("...The default value of ")
                + String(DefaultPC)
                + String(" will be used. for ")
                + c_numeric_fields[10],
            )

        wind_turbine[].LocalAnnualAvgWS = state[].dataIPShortCut.rNumericArgs[11]
        if wind_turbine[].LocalAnnualAvgWS == 0.0:
            if l_numeric_blanks[11]:
                state[].dataUtility.ShowWarningError(
                    state,
                    String(current_module_object)
                    + String('="')
                    + state[].dataIPShortCut.cAlphaArgs[0]
                    + String('" invalid ')
                    + c_numeric_fields[11]
                    + String(" is necessary for accurate prediction but input is blank."),
                )
            else:
                state[].dataUtility.ShowSevereError(
                    state,
                    String(current_module_object)
                    + String('="')
                    + state[].dataIPShortCut.cAlphaArgs[0]
                    + String('" invalid ')
                    + c_numeric_fields[11]
                    + String("=[")
                    + String(state[].dataIPShortCut.rNumericArgs[11])
                    + String("] must be greater than zero."),
                )
                errors_found = True

        wind_turbine[].HeightForLocalWS = state[].dataIPShortCut.rNumericArgs[12]
        if wind_turbine[].HeightForLocalWS == 0.0:
            if wind_turbine[].LocalAnnualAvgWS == 0.0:
                wind_turbine[].HeightForLocalWS = 0.0
            else:
                wind_turbine[].HeightForLocalWS = DefaultH
                if l_numeric_blanks[12]:
                    state[].dataUtility.ShowWarningError(
                        state,
                        String(current_module_object)
                        + String('="')
                        + state[].dataIPShortCut.cAlphaArgs[0]
                        + String('" invalid ')
                        + c_numeric_fields[12]
                        + String(" is necessary for accurate prediction but input is blank."),
                    )
                    state[].dataUtility.ShowContinueError(
                        state,
                        String("...The default value of ")
                        + String(DefaultH)
                        + String(" will be used. for ")
                        + c_numeric_fields[12],
                    )
                else:
                    state[].dataUtility.ShowSevereError(
                        state,
                        String(current_module_object)
                        + String('="')
                        + state[].dataIPShortCut.cAlphaArgs[0]
                        + String('" invalid ')
                        + c_numeric_fields[12]
                        + String("=[")
                        + String(state[].dataIPShortCut.rNumericArgs[12])
                        + String("] must be greater than zero."),
                    )
                    errors_found = True

        wind_turbine[].ChordArea = state[].dataIPShortCut.rNumericArgs[13]
        if wind_turbine[].rotorType == RotorType.VerticalAxis and wind_turbine[].ChordArea == 0.0:
            if l_numeric_blanks[13]:
                state[].dataUtility.ShowSevereError(
                    state,
                    String(current_module_object)
                    + String('="')
                    + state[].dataIPShortCut.cAlphaArgs[0]
                    + String('" invalid ')
                    + c_numeric_fields[13]
                    + String(" is required but input is blank."),
                )
            else:
                state[].dataUtility.ShowSevereError(
                    state,
                    String(current_module_object)
                    + String('="')
                    + state[].dataIPShortCut.cAlphaArgs[0]
                    + String('" invalid ')
                    + c_numeric_fields[13]
                    + String("=[")
                    + String(state[].dataIPShortCut.rNumericArgs[13])
                    + String("] must be greater than zero."),
                )
            errors_found = True

        wind_turbine[].DragCoeff = state[].dataIPShortCut.rNumericArgs[14]
        if wind_turbine[].rotorType == RotorType.VerticalAxis and wind_turbine[].DragCoeff == 0.0:
            if l_numeric_blanks[14]:
                state[].dataUtility.ShowSevereError(
                    state,
                    String(current_module_object)
                    + String('="')
                    + state[].dataIPShortCut.cAlphaArgs[0]
                    + String('" invalid ')
                    + c_numeric_fields[14]
                    + String(" is required but input is blank."),
                )
            else:
                state[].dataUtility.ShowSevereError(
                    state,
                    String(current_module_object)
                    + String('="')
                    + state[].dataIPShortCut.cAlphaArgs[0]
                    + String('" invalid ')
                    + c_numeric_fields[14]
                    + String("=[")
                    + String(state[].dataIPShortCut.rNumericArgs[14])
                    + String("] must be greater than zero."),
                )
            errors_found = True

        wind_turbine[].LiftCoeff = state[].dataIPShortCut.rNumericArgs[15]
        if wind_turbine[].rotorType == RotorType.VerticalAxis and wind_turbine[].LiftCoeff == 0.0:
            if l_numeric_blanks[15]:
                state[].dataUtility.ShowSevereError(
                    state,
                    String(current_module_object)
                    + String('="')
                    + state[].dataIPShortCut.cAlphaArgs[0]
                    + String('" invalid ')
                    + c_numeric_fields[15]
                    + String(" is required but input is blank."),
                )
            else:
                state[].dataUtility.ShowSevereError(
                    state,
                    String(current_module_object)
                    + String('="')
                    + state[].dataIPShortCut.cAlphaArgs[0]
                    + String('" invalid ')
                    + c_numeric_fields[15]
                    + String("=[")
                    + String(state[].dataIPShortCut.rNumericArgs[15])
                    + String("] must be greater than zero."),
                )
            errors_found = True

        wind_turbine[].PowerCoeffs[0] = state[].dataIPShortCut.rNumericArgs[16]
        if l_numeric_blanks[16]:
            wind_turbine[].PowerCoeffs[0] = 0.0
        wind_turbine[].PowerCoeffs[1] = state[].dataIPShortCut.rNumericArgs[17]
        if l_numeric_blanks[17]:
            wind_turbine[].PowerCoeffs[1] = 0.0
        wind_turbine[].PowerCoeffs[2] = state[].dataIPShortCut.rNumericArgs[18]
        if l_numeric_blanks[18]:
            wind_turbine[].PowerCoeffs[2] = 0.0
        wind_turbine[].PowerCoeffs[3] = state[].dataIPShortCut.rNumericArgs[19]
        if l_numeric_blanks[19]:
            wind_turbine[].PowerCoeffs[3] = 0.0
        wind_turbine[].PowerCoeffs[4] = state[].dataIPShortCut.rNumericArgs[20]
        if l_numeric_blanks[20]:
            wind_turbine[].PowerCoeffs[4] = 0.0
        wind_turbine[].PowerCoeffs[5] = state[].dataIPShortCut.rNumericArgs[21]
        if l_numeric_blanks[21]:
            wind_turbine[].PowerCoeffs[5] = 0.0

    if errors_found:
        state[].dataUtility.ShowFatalError(
            state,
            String(current_module_object) + String(" errors occurred in input.  Program terminates."),
        )

    for wind_turbine_num in range(num_wind_turbines):
        var wind_turbine = UnsafePointer[WindTurbineParams](
            __mlir_op.`llvm.addressof`(
                state[].dataWindTurbine.WindTurbineSys[wind_turbine_num]
            )
        )
        state[].dataOutputProcessor.SetupOutputVariable(
            state,
            String("Generator Produced AC Electricity Rate"),
            state[].dataConstant.Units.W,
            wind_turbine[].Power,
            state[].dataOutputProcessor.TimeStepType.System,
            state[].dataOutputProcessor.StoreType.Average,
            wind_turbine[].Name,
        )
        state[].dataOutputProcessor.SetupOutputVariable(
            state,
            String("Generator Produced AC Electricity Energy"),
            state[].dataConstant.Units.J,
            wind_turbine[].Energy,
            state[].dataOutputProcessor.TimeStepType.System,
            state[].dataOutputProcessor.StoreType.Sum,
            wind_turbine[].Name,
            state[].dataConstant.eResource.ElectricityProduced,
            state[].dataOutputProcessor.Group.Plant,
            state[].dataOutputProcessor.EndUseCat.WindTurbine,
        )
        state[].dataOutputProcessor.SetupOutputVariable(
            state,
            String("Generator Turbine Local Wind Speed"),
            state[].dataConstant.Units.m_s,
            wind_turbine[].LocalWindSpeed,
            state[].dataOutputProcessor.TimeStepType.System,
            state[].dataOutputProcessor.StoreType.Average,
            wind_turbine[].Name,
        )
        state[].dataOutputProcessor.SetupOutputVariable(
            state,
            String("Generator Turbine Local Air Density"),
            state[].dataConstant.Units.kg_m3,
            wind_turbine[].LocalAirDensity,
            state[].dataOutputProcessor.TimeStepType.System,
            state[].dataOutputProcessor.StoreType.Average,
            wind_turbine[].Name,
        )
        state[].dataOutputProcessor.SetupOutputVariable(
            state,
            String("Generator Turbine Tip Speed Ratio"),
            state[].dataConstant.Units.None,
            wind_turbine[].TipSpeedRatio,
            state[].dataOutputProcessor.TimeStepType.System,
            state[].dataOutputProcessor.StoreType.Average,
            wind_turbine[].Name,
        )
        if wind_turbine[].rotorType == RotorType.HorizontalAxis:
            state[].dataOutputProcessor.SetupOutputVariable(
                state,
                String("Generator Turbine Power Coefficient"),
                state[].dataConstant.Units.None,
                wind_turbine[].PowerCoeff,
                state[].dataOutputProcessor.TimeStepType.System,
                state[].dataOutputProcessor.StoreType.Average,
                wind_turbine[].Name,
            )
        elif wind_turbine[].rotorType == RotorType.VerticalAxis:
            state[].dataOutputProcessor.SetupOutputVariable(
                state,
                String("Generator Turbine Chordal Component Velocity"),
                state[].dataConstant.Units.m_s,
                wind_turbine[].ChordalVel,
                state[].dataOutputProcessor.TimeStepType.System,
                state[].dataOutputProcessor.StoreType.Average,
                wind_turbine[].Name,
            )
            state[].dataOutputProcessor.SetupOutputVariable(
                state,
                String("Generator Turbine Normal Component Velocity"),
                state[].dataConstant.Units.m_s,
                wind_turbine[].NormalVel,
                state[].dataOutputProcessor.TimeStepType.System,
                state[].dataOutputProcessor.StoreType.Average,
                wind_turbine[].Name,
            )
            state[].dataOutputProcessor.SetupOutputVariable(
                state,
                String("Generator Turbine Relative Flow Velocity"),
                state[].dataConstant.Units.m_s,
                wind_turbine[].RelFlowVel,
                state[].dataOutputProcessor.TimeStepType.System,
                state[].dataOutputProcessor.StoreType.Average,
                wind_turbine[].Name,
            )
            state[].dataOutputProcessor.SetupOutputVariable(
                state,
                String("Generator Turbine Attack Angle"),
                state[].dataConstant.Units.deg,
                wind_turbine[].AngOfAttack,
                state[].dataOutputProcessor.TimeStepType.System,
                state[].dataOutputProcessor.StoreType.Average,
                wind_turbine[].Name,
            )


fn init_wind_turbine(state: UnsafePointer[Object], wind_turbine_num: Int) -> None:
    var month_ws = InlineArray[Float64, 12]()
    for i in range(12):
        month_ws[i] = 0.0

    if state[].dataWindTurbine.MyOneTimeFlag:
        var annual_tmy_ws = 0.0
        if state[].dataFileSystem.fileExists(state[].files.inStatFilePath):
            var stat_file = state[].files.inStatFilePath.open(state, String("InitWindTurbine"))
            var ws_stat_found = False
            while stat_file.good():
                var line_in = stat_file.readLine()
                var ln_ptr = line_in.data.find(String("Wind Speed"))
                if ln_ptr == -1:
                    continue
                while stat_file.good():
                    line_in = stat_file.readLine()
                    ln_ptr = line_in.data.find(String("Daily Avg"))
                    if ln_ptr == -1:
                        continue
                    line_in.data = line_in.data[ln_ptr + 10 :]
                    for i in range(12):
                        month_ws[i] = 0.0
                    ws_stat_found = True
                    var warning_shown = False
                    for mon in range(12):
                        ln_ptr = line_in.data.find(TabChr)
                        if ln_ptr != 0:
                            if ln_ptr != -1 or line_in.data[0:ln_ptr].strip() != "":
                                if ln_ptr != -1:
                                    var error = False
                                    month_ws[mon] = state[].dataUtility.ProcessNumber(
                                        line_in.data[0:ln_ptr], error
                                    )
                                    if error:
                                        pass
                                    line_in.data = line_in.data[ln_ptr + 1 :]
                            else:
                                if not warning_shown:
                                    state[].dataUtility.ShowWarningError(
                                        state,
                                        String("InitWindTurbine: read from ")
                                        + String(state[].files.inStatFilePath)
                                        + String(" file shows <365 days in weather file. ")
                                        + String("Annual average wind speed used will be inaccurate."),
                                    )
                                    line_in.data = line_in.data[ln_ptr + 1 :]
                                    warning_shown = True
                        else:
                            if not warning_shown:
                                state[].dataUtility.ShowWarningError(
                                    state,
                                    String("InitWindTurbine: read from ")
                                    + String(state[].files.inStatFilePath)
                                    + String(" file shows <365 days in weather file. ")
                                    + String("Annual average wind speed used will be inaccurate."),
                                )
                                line_in.data = line_in.data[ln_ptr + 1 :]
                                warning_shown = True
                    break
                if ws_stat_found:
                    break
            if ws_stat_found:
                var sum_val = 0.0
                for i in range(12):
                    sum_val += month_ws[i]
                annual_tmy_ws = sum_val / 12.0
            else:
                state[].dataUtility.ShowWarningError(
                    state,
                    String("InitWindTurbine: stat file did not include Wind Speed statistics. ")
                    + String("TMY Wind Speed adjusted at the height is used."),
                )
        else:
            state[].dataUtility.ShowWarningError(
                state,
                String("InitWindTurbine: stat file missing. TMY Wind Speed adjusted at the height is used."),
            )

        for i in range(len(state[].dataWindTurbine.WindTurbineSys)):
            state[].dataWindTurbine.WindTurbineSys[i].AnnualTMYWS = annual_tmy_ws

        state[].dataWindTurbine.MyOneTimeFlag = False

    var wind_turbine = UnsafePointer[WindTurbineParams](
        __mlir_op.`llvm.addressof`(
            state[].dataWindTurbine.WindTurbineSys[wind_turbine_num - 1]
        )
    )

    if (
        wind_turbine[].AnnualTMYWS > 0.0
        and wind_turbine[].WSFactor == 0.0
        and wind_turbine[].LocalAnnualAvgWS > 0
    ):
        var local_tmy_ws = (
            wind_turbine[].AnnualTMYWS
            * state[].dataEnvrn.WeatherFileWindModCoeff
            * pow(
                wind_turbine[].HeightForLocalWS / state[].dataEnvrn.SiteWindBLHeight,
                state[].dataEnvrn.SiteWindExp,
            )
        )
        wind_turbine[].WSFactor = local_tmy_ws / wind_turbine[].LocalAnnualAvgWS

    if wind_turbine[].WSFactor == 0.0:
        wind_turbine[].WSFactor = 1.0

    wind_turbine[].Power = 0.0
    wind_turbine[].TotPower = 0.0
    wind_turbine[].PowerCoeff = 0.0
    wind_turbine[].TipSpeedRatio = 0.0
    wind_turbine[].ChordalVel = 0.0
    wind_turbine[].NormalVel = 0.0
    wind_turbine[].RelFlowVel = 0.0
    wind_turbine[].AngOfAttack = 0.0
    wind_turbine[].TanForce = 0.0
    wind_turbine[].NorForce = 0.0
    wind_turbine[].TotTorque = 0.0


fn calc_wind_turbine(state: UnsafePointer[Object], wind_turbine_num: Int, run_flag: Bool) -> None:
    var wind_turbine = UnsafePointer[WindTurbineParams](
        __mlir_op.`llvm.addressof`(
            state[].dataWindTurbine.WindTurbineSys[wind_turbine_num - 1]
        )
    )

    var rotor_h = wind_turbine[].RotorHeight
    var rotor_d = wind_turbine[].RotorDiameter
    var rotor_speed = wind_turbine[].RatedRotorSpeed
    var local_temp = state[].dataEnvironment.OutDryBulbTempAt(state, rotor_h)
    var local_press = state[].dataEnvironment.OutBaroPressAt(state, rotor_h)
    var local_hum_rat = state[].dataPsychrometrics.PsyWFnTdbTwbPb(
        state,
        local_temp,
        state[].dataEnvironment.OutWetBulbTempAt(state, rotor_h),
        local_press,
    )
    var local_air_density = state[].dataPsychrometrics.PsyRhoAirFnPbTdbW(
        state, local_press, local_temp, local_hum_rat
    )
    var local_wind_speed = state[].dataEnvironment.WindSpeedAt(state, rotor_h)
    local_wind_speed /= wind_turbine[].WSFactor

    if (
        wind_turbine[].availSched.load().getCurrentVal() > 0
        and local_wind_speed > wind_turbine[].CutInSpeed
        and local_wind_speed < wind_turbine[].CutOutSpeed
    ):
        var period = 2.0 * pi
        var omega = (rotor_speed * period) / SecInMin
        var swept_area = (pi * rotor_d * rotor_d) / 4.0
        var tip_speed_ratio = (omega * (rotor_d / 2.0)) / local_wind_speed

        if tip_speed_ratio > wind_turbine[].MaxTipSpeedRatio:
            tip_speed_ratio = wind_turbine[].MaxTipSpeedRatio

        if wind_turbine[].rotorType == RotorType.HorizontalAxis:
            var max_power_coeff = wind_turbine[].MaxPowerCoeff
            var c1 = wind_turbine[].PowerCoeffs[0]
            var c2 = wind_turbine[].PowerCoeffs[1]
            var c3 = wind_turbine[].PowerCoeffs[2]
            var c4 = wind_turbine[].PowerCoeffs[3]
            var c5 = wind_turbine[].PowerCoeffs[4]
            var c6 = wind_turbine[].PowerCoeffs[5]

            var local_wind_speed_3 = local_wind_speed * local_wind_speed * local_wind_speed
            var wt_power: Float64
            var power_coeff: Float64

            if c1 > 0.0 and c2 > 0.0 and c3 > 0.0 and c4 >= 0.0 and c5 > 0.0 and c6 > 0.0:
                var tip_speed_ratio_at_i = tip_speed_ratio / (1.0 - (tip_speed_ratio * 0.035))
                power_coeff = (
                    c1 * ((c2 / tip_speed_ratio_at_i) - c5) * exp(-(c6 / tip_speed_ratio_at_i))
                )
                if power_coeff > max_power_coeff:
                    power_coeff = max_power_coeff
                wt_power = 0.5 * local_air_density * power_coeff * swept_area * local_wind_speed_3
            else:
                wt_power = (
                    0.5 * local_air_density * swept_area * local_wind_speed_3 * max_power_coeff
                )
                power_coeff = max_power_coeff

            if local_wind_speed >= wind_turbine[].RatedWindSpeed or wt_power > wind_turbine[].RatedPower:
                wt_power = wind_turbine[].RatedPower
                power_coeff = wt_power / (0.5 * local_air_density * swept_area * local_wind_speed_3)

            wind_turbine[].PowerCoeff = power_coeff
            wind_turbine[].Power = wt_power * wind_turbine[].SysEfficiency
            wind_turbine[].TotPower = wt_power

        elif wind_turbine[].rotorType == RotorType.VerticalAxis:
            var rotor_vel = omega * (rotor_d / 2.0)
            if tip_speed_ratio >= wind_turbine[].MaxTipSpeedRatio:
                rotor_vel = local_wind_speed * wind_turbine[].MaxTipSpeedRatio
                omega = rotor_vel / (rotor_d / 2.0)

            var azimuth_ang = MaxDegree / Float64(wind_turbine[].NumOfBlade)
            if azimuth_ang > MaxTheta:
                azimuth_ang -= MaxTheta
                if azimuth_ang == MaxTheta:
                    azimuth_ang = 0.0
            elif azimuth_ang == MaxTheta:
                azimuth_ang = 0.0

            var induced_vel = local_wind_speed * 2.0 / 3.0

            var sin_azimuth_ang = sin(azimuth_ang * pi / 180.0)
            var cos_azimuth_ang = cos(azimuth_ang * pi / 180.0)
            var chordal_vel = rotor_vel + induced_vel * cos_azimuth_ang
            var normal_vel = induced_vel * sin_azimuth_ang
            var rel_flow_vel = sqrt(chordal_vel * chordal_vel + normal_vel * normal_vel)

            var ang_of_attack = atan(
                (sin_azimuth_ang
                 / ((rotor_vel / local_wind_speed) / (induced_vel / local_wind_speed) + cos_azimuth_ang))
            )

            var sin_ang_of_attack = sin(ang_of_attack * pi / 180.0)
            var cos_ang_of_attack = cos(ang_of_attack * pi / 180.0)
            var tan_force_coeff = abs(
                wind_turbine[].LiftCoeff * sin_ang_of_attack
                - wind_turbine[].DragCoeff * cos_ang_of_attack
            )
            var nor_force_coeff = (
                wind_turbine[].LiftCoeff * cos_ang_of_attack
                + wind_turbine[].DragCoeff * sin_ang_of_attack
            )

            var rel_flow_vel_2 = rel_flow_vel * rel_flow_vel
            var density_fac = 0.5 * local_air_density * wind_turbine[].ChordArea * rel_flow_vel_2
            var tan_force = tan_force_coeff * density_fac
            var nor_force = nor_force_coeff * density_fac
            var constant = (1.0 / period) * (tan_force / rel_flow_vel_2)

            var int_rel_flow_vel = (
                rotor_vel * rotor_vel * period + induced_vel * induced_vel * period
            )

            var avg_tan_force = constant * int_rel_flow_vel
            var tot_torque = Float64(wind_turbine[].NumOfBlade) * avg_tan_force * (rotor_d / 2.0)
            var wt_power = tot_torque * omega

            if wt_power > wind_turbine[].RatedPower:
                wt_power = wind_turbine[].RatedPower

            wind_turbine[].ChordalVel = chordal_vel
            wind_turbine[].NormalVel = normal_vel
            wind_turbine[].RelFlowVel = rel_flow_vel
            wind_turbine[].TanForce = tan_force
            wind_turbine[].NorForce = nor_force
            wind_turbine[].TotTorque = tot_torque
            wind_turbine[].Power = wt_power * wind_turbine[].SysEfficiency
            wind_turbine[].TotPower = wt_power

        wind_turbine[].LocalWindSpeed = local_wind_speed
        wind_turbine[].LocalAirDensity = local_air_density
        wind_turbine[].TipSpeedRatio = tip_speed_ratio

    else:
        wind_turbine[].Power = 0.0
        wind_turbine[].TotPower = 0.0
        wind_turbine[].PowerCoeff = 0.0
        wind_turbine[].LocalWindSpeed = local_wind_speed
        wind_turbine[].LocalAirDensity = local_air_density
        wind_turbine[].TipSpeedRatio = 0.0
        wind_turbine[].ChordalVel = 0.0
        wind_turbine[].NormalVel = 0.0
        wind_turbine[].RelFlowVel = 0.0
        wind_turbine[].AngOfAttack = 0.0
        wind_turbine[].TanForce = 0.0
        wind_turbine[].NorForce = 0.0
        wind_turbine[].TotTorque = 0.0


fn report_wind_turbine(state: UnsafePointer[Object], wind_turbine_num: Int) -> None:
    var time_step_sys_sec = state[].dataHVACGlobal.TimeStepSysSec
    var wind_turbine = UnsafePointer[WindTurbineParams](
        __mlir_op.`llvm.addressof`(
            state[].dataWindTurbine.WindTurbineSys[wind_turbine_num - 1]
        )
    )
    wind_turbine[].Energy = wind_turbine[].Power * time_step_sys_sec
