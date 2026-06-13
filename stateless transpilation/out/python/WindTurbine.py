from enum import Enum
from typing import Optional, List, Protocol, Any
from dataclasses import dataclass, field
import math


class RotorType(Enum):
    Invalid = -1
    HorizontalAxis = 0
    VerticalAxis = 1
    Num = 2


class ControlType(Enum):
    Invalid = -1
    FixedSpeedFixedPitch = 0
    FixedSpeedVariablePitch = 1
    VariableSpeedFixedPitch = 2
    VariableSpeedVariablePitch = 3
    Num = 4


@dataclass
class WindTurbineParams:
    Name: str = ""
    rotorType: RotorType = RotorType.Invalid
    controlType: ControlType = ControlType.Invalid
    availSched: Optional[Any] = None
    NumOfBlade: int = 0
    RatedRotorSpeed: float = 0.0
    RotorDiameter: float = 0.0
    RotorHeight: float = 0.0
    RatedPower: float = 0.0
    RatedWindSpeed: float = 0.0
    CutInSpeed: float = 0.0
    CutOutSpeed: float = 0.0
    SysEfficiency: float = 0.0
    MaxTipSpeedRatio: float = 0.0
    MaxPowerCoeff: float = 0.0
    LocalAnnualAvgWS: float = 0.0
    AnnualTMYWS: float = 0.0
    HeightForLocalWS: float = 0.0
    ChordArea: float = 0.0
    DragCoeff: float = 0.0
    LiftCoeff: float = 0.0
    PowerCoeffs: List[float] = field(default_factory=lambda: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
    TotPower: float = 0.0
    Power: float = 0.0
    TotEnergy: float = 0.0
    Energy: float = 0.0
    LocalWindSpeed: float = 0.0
    LocalAirDensity: float = 0.0
    PowerCoeff: float = 0.0
    ChordalVel: float = 0.0
    NormalVel: float = 0.0
    RelFlowVel: float = 0.0
    TipSpeedRatio: float = 0.0
    WSFactor: float = 0.0
    AngOfAttack: float = 0.0
    IntRelFlowVel: float = 0.0
    TanForce: float = 0.0
    NorForce: float = 0.0
    TotTorque: float = 0.0
    AzimuthAng: float = 0.0


@dataclass
class WindTurbineData:
    GetInputFlag: bool = True
    MyOneTimeFlag: bool = True
    WindTurbineSys: List[WindTurbineParams] = field(default_factory=list)

    def init_constant_state(self, state: Any) -> None:
        pass

    def init_state(self, state: Any) -> None:
        pass

    def clear_state(self) -> None:
        self.GetInputFlag = True
        self.MyOneTimeFlag = True
        self.WindTurbineSys = []


CONTROL_NAMES_UC = [
    "FIXEDSPEEDFIXEDPITCH",
    "FIXEDSPEEDVARIABLEPITCH",
    "VARIABLESPEEDFIXEDPITCH",
    "VARIABLESPEEDVARIABLEPITCH",
]

ROTOR_NAMES_UC = [
    "HORIZONTALAXISWINDTURBINE",
    "VERTICALAXISWINDTURBINE",
]


def sim_wind_turbine(
    state: Any,
    generator_type: Any,
    generator_name: str,
    generator_index: List[int],
    run_flag: bool,
    wt_load: float,
) -> None:
    if state.dataWindTurbine.GetInputFlag:
        get_wind_turbine_input(state)
        state.dataWindTurbine.GetInputFlag = False

    if generator_index[0] == 0:
        wind_turbine_num = state.dataUtility.FindItemInList(
            generator_name, state.dataWindTurbine.WindTurbineSys
        )
        if wind_turbine_num == 0:
            state.dataUtility.ShowFatalError(
                state,
                f"SimWindTurbine: Specified Generator not one of Valid Wind Turbine Generators {generator_name}",
            )
        generator_index[0] = wind_turbine_num
    else:
        wind_turbine_num = generator_index[0]
        num_wind_turbines = len(state.dataWindTurbine.WindTurbineSys)
        if wind_turbine_num > num_wind_turbines or wind_turbine_num < 1:
            state.dataUtility.ShowFatalError(
                state,
                f"SimWindTurbine: Invalid GeneratorIndex passed={wind_turbine_num}, "
                f"Number of Wind Turbine Generators={num_wind_turbines}, Generator name={generator_name}",
            )
        if (
            generator_name
            != state.dataWindTurbine.WindTurbineSys[wind_turbine_num - 1].Name
        ):
            state.dataUtility.ShowFatalError(
                state,
                f"SimMWindTurbine: Invalid GeneratorIndex passed={wind_turbine_num}, "
                f"Generator name={generator_name}, "
                f"stored Generator Name for that index={state.dataWindTurbine.WindTurbineSys[wind_turbine_num - 1].Name}",
            )

    init_wind_turbine(state, wind_turbine_num)
    calc_wind_turbine(state, wind_turbine_num, run_flag)
    report_wind_turbine(state, wind_turbine_num)


def get_wt_generator_results(
    state: Any,
    generator_type: Any,
    generator_index: int,
    generator_power: List[float],
    generator_energy: List[float],
    thermal_power: List[float],
    thermal_energy: List[float],
) -> None:
    generator_power[0] = state.dataWindTurbine.WindTurbineSys[generator_index - 1].Power
    generator_energy[0] = state.dataWindTurbine.WindTurbineSys[generator_index - 1].Energy
    thermal_power[0] = 0.0
    thermal_energy[0] = 0.0


def get_wind_turbine_input(state: Any) -> None:
    routine_name = "GetWindTurbineInput"
    current_module_object = "Generator:WindTurbine"
    sys_eff_default = 0.835
    max_tsr = 12.0
    default_pc = 0.25
    max_power_coeff = 0.59
    default_h = 50.0

    errors_found = False

    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(
        state, current_module_object
    )
    num_args = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, current_module_object
    )
    num_wind_turbines = num_args

    state.dataWindTurbine.WindTurbineSys = [
        WindTurbineParams() for _ in range(num_wind_turbines)
    ]

    for wind_turbine_num in range(num_wind_turbines):
        c_alpha_args = []
        c_alpha_fields = []
        c_numeric_fields = []
        r_numeric_args = []
        l_alpha_blanks = []
        l_numeric_blanks = []

        state.dataInputProcessing.inputProcessor.getObjectItem(
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

        wind_turbine = state.dataWindTurbine.WindTurbineSys[wind_turbine_num]

        wind_turbine.Name = state.dataIPShortCut.cAlphaArgs[0]

        if l_alpha_blanks[1]:
            wind_turbine.availSched = state.dataScheduleMgr.GetScheduleAlwaysOn(state)
        else:
            wind_turbine.availSched = state.dataScheduleMgr.GetSchedule(
                state, state.dataIPShortCut.cAlphaArgs[1]
            )
            if wind_turbine.availSched is None:
                state.dataUtility.ShowSevereItemNotFound(
                    state, routine_name, current_module_object, c_alpha_fields[1], state.dataIPShortCut.cAlphaArgs[1]
                )
                errors_found = True

        rotor_type_val = state.dataInputProcessing.getEnumValue(
            ROTOR_NAMES_UC, state.dataUtility.makeUPPER(state.dataIPShortCut.cAlphaArgs[2])
        )
        if rotor_type_val == -1:
            if state.dataIPShortCut.cAlphaArgs[2] == "":
                wind_turbine.rotorType = RotorType.HorizontalAxis
            else:
                state.dataUtility.ShowSevereError(
                    state,
                    f'{current_module_object}="{state.dataIPShortCut.cAlphaArgs[0]}" '
                    f'invalid {c_alpha_fields[2]}="{state.dataIPShortCut.cAlphaArgs[2]}".',
                )
                errors_found = True
        else:
            wind_turbine.rotorType = RotorType(rotor_type_val)

        control_type_val = state.dataInputProcessing.getEnumValue(
            CONTROL_NAMES_UC, state.dataUtility.makeUPPER(state.dataIPShortCut.cAlphaArgs[3])
        )
        if control_type_val == -1:
            if state.dataIPShortCut.cAlphaArgs[3] == "":
                wind_turbine.controlType = ControlType.VariableSpeedVariablePitch
            else:
                state.dataUtility.ShowSevereError(
                    state,
                    f'{current_module_object}="{state.dataIPShortCut.cAlphaArgs[0]}" '
                    f'invalid {c_alpha_fields[3]}="{state.dataIPShortCut.cAlphaArgs[3]}".',
                )
                errors_found = True
        else:
            wind_turbine.controlType = ControlType(control_type_val)

        wind_turbine.RatedRotorSpeed = state.dataIPShortCut.rNumericArgs[0]
        if wind_turbine.RatedRotorSpeed <= 0.0:
            if l_numeric_blanks[0]:
                state.dataUtility.ShowSevereError(
                    state,
                    f'{current_module_object}="{state.dataIPShortCut.cAlphaArgs[0]}" '
                    f'invalid {c_numeric_fields[0]} is required but input is blank.',
                )
            else:
                state.dataUtility.ShowSevereError(
                    state,
                    f'{current_module_object}="{state.dataIPShortCut.cAlphaArgs[0]}" '
                    f'invalid {c_numeric_fields[0]}=[{state.dataIPShortCut.rNumericArgs[0]:.2f}] must be greater than zero.',
                )
            errors_found = True

        wind_turbine.RotorDiameter = state.dataIPShortCut.rNumericArgs[1]
        if wind_turbine.RotorDiameter <= 0.0:
            if l_numeric_blanks[1]:
                state.dataUtility.ShowSevereError(
                    state,
                    f'{current_module_object}="{state.dataIPShortCut.cAlphaArgs[0]}" '
                    f'invalid {c_numeric_fields[1]} is required but input is blank.',
                )
            else:
                state.dataUtility.ShowSevereError(
                    state,
                    f'{current_module_object}="{state.dataIPShortCut.cAlphaArgs[0]}" '
                    f'invalid {c_numeric_fields[1]}=[{state.dataIPShortCut.rNumericArgs[1]:.1f}] must be greater than zero.',
                )
            errors_found = True

        wind_turbine.RotorHeight = state.dataIPShortCut.rNumericArgs[2]
        if wind_turbine.RotorHeight <= 0.0:
            if l_numeric_blanks[2]:
                state.dataUtility.ShowSevereError(
                    state,
                    f'{current_module_object}="{state.dataIPShortCut.cAlphaArgs[0]}" '
                    f'invalid {c_numeric_fields[2]} is required but input is blank.',
                )
            else:
                state.dataUtility.ShowSevereError(
                    state,
                    f'{current_module_object}="{state.dataIPShortCut.cAlphaArgs[0]}" '
                    f'invalid {c_numeric_fields[2]}=[{state.dataIPShortCut.rNumericArgs[2]:.1f}] must be greater than zero.',
                )
            errors_found = True

        wind_turbine.NumOfBlade = int(state.dataIPShortCut.rNumericArgs[3])
        if wind_turbine.NumOfBlade == 0:
            state.dataUtility.ShowSevereError(
                state,
                f'{current_module_object}="{state.dataIPShortCut.cAlphaArgs[0]}" '
                f'invalid {c_numeric_fields[3]}=[{state.dataIPShortCut.rNumericArgs[3]:.0f}] must be greater than zero.',
            )
            errors_found = True

        wind_turbine.RatedPower = state.dataIPShortCut.rNumericArgs[4]
        if wind_turbine.RatedPower == 0.0:
            if l_numeric_blanks[4]:
                state.dataUtility.ShowSevereError(
                    state,
                    f'{current_module_object}="{state.dataIPShortCut.cAlphaArgs[0]}" '
                    f'invalid {c_numeric_fields[4]} is required but input is blank.',
                )
            else:
                state.dataUtility.ShowSevereError(
                    state,
                    f'{current_module_object}="{state.dataIPShortCut.cAlphaArgs[0]}" '
                    f'invalid {c_numeric_fields[4]}=[{state.dataIPShortCut.rNumericArgs[4]:.2f}] must be greater than zero.',
                )
            errors_found = True

        wind_turbine.RatedWindSpeed = state.dataIPShortCut.rNumericArgs[5]
        if wind_turbine.RatedWindSpeed == 0.0:
            if l_numeric_blanks[5]:
                state.dataUtility.ShowSevereError(
                    state,
                    f'{current_module_object}="{state.dataIPShortCut.cAlphaArgs[0]}" '
                    f'invalid {c_numeric_fields[5]} is required but input is blank.',
                )
            else:
                state.dataUtility.ShowSevereError(
                    state,
                    f'{current_module_object}="{state.dataIPShortCut.cAlphaArgs[0]}" '
                    f'invalid {c_numeric_fields[5]}=[{state.dataIPShortCut.rNumericArgs[5]:.2f}] must be greater than zero.',
                )
            errors_found = True

        wind_turbine.CutInSpeed = state.dataIPShortCut.rNumericArgs[6]
        if wind_turbine.CutInSpeed == 0.0:
            if l_numeric_blanks[6]:
                state.dataUtility.ShowSevereError(
                    state,
                    f'{current_module_object}="{state.dataIPShortCut.cAlphaArgs[0]}" '
                    f'invalid {c_numeric_fields[6]} is required but input is blank.',
                )
            else:
                state.dataUtility.ShowSevereError(
                    state,
                    f'{current_module_object}="{state.dataIPShortCut.cAlphaArgs[0]}" '
                    f'invalid {c_numeric_fields[6]}=[{state.dataIPShortCut.rNumericArgs[6]:.2f}] must be greater than zero.',
                )
            errors_found = True

        wind_turbine.CutOutSpeed = state.dataIPShortCut.rNumericArgs[7]
        if wind_turbine.CutOutSpeed == 0.0:
            if l_numeric_blanks[7]:
                state.dataUtility.ShowSevereError(
                    state,
                    f'{current_module_object}="{state.dataIPShortCut.cAlphaArgs[0]}" '
                    f'invalid {c_numeric_fields[7]} is required but input is blank.',
                )
            elif wind_turbine.CutOutSpeed <= wind_turbine.RatedWindSpeed:
                state.dataUtility.ShowSevereError(
                    state,
                    f'{current_module_object}="{state.dataIPShortCut.cAlphaArgs[0]}" '
                    f'invalid {c_numeric_fields[7]}=[{state.dataIPShortCut.rNumericArgs[7]:.2f}] '
                    f'must be greater than {c_numeric_fields[5]}=[{state.dataIPShortCut.rNumericArgs[5]:.2f}].',
                )
            else:
                state.dataUtility.ShowSevereError(
                    state,
                    f'{current_module_object}="{state.dataIPShortCut.cAlphaArgs[0]}" '
                    f'invalid {c_numeric_fields[7]}=[{state.dataIPShortCut.rNumericArgs[7]:.2f}] must be greater than zero',
                )
            errors_found = True

        wind_turbine.SysEfficiency = state.dataIPShortCut.rNumericArgs[8]
        if (
            l_numeric_blanks[8]
            or wind_turbine.SysEfficiency == 0.0
            or wind_turbine.SysEfficiency > 1.0
        ):
            wind_turbine.SysEfficiency = sys_eff_default
            state.dataUtility.ShowWarningError(
                state,
                f'{current_module_object}="{state.dataIPShortCut.cAlphaArgs[0]}" '
                f'invalid {c_numeric_fields[8]}=[{state.dataIPShortCut.rNumericArgs[8]:.2f}].',
            )
            state.dataUtility.ShowContinueError(
                state,
                f"...The default value of {sys_eff_default:.3f} was assumed. for {c_numeric_fields[8]}",
            )

        wind_turbine.MaxTipSpeedRatio = state.dataIPShortCut.rNumericArgs[9]
        if wind_turbine.MaxTipSpeedRatio == 0.0:
            if l_numeric_blanks[9]:
                state.dataUtility.ShowSevereError(
                    state,
                    f'{current_module_object}="{state.dataIPShortCut.cAlphaArgs[0]}" '
                    f'invalid {c_numeric_fields[9]} is required but input is blank.',
                )
            else:
                state.dataUtility.ShowSevereError(
                    state,
                    f'{current_module_object}="{state.dataIPShortCut.cAlphaArgs[0]}" '
                    f'invalid {c_numeric_fields[9]}=[{state.dataIPShortCut.rNumericArgs[9]:.2f}] must be greater than zero.',
                )
            errors_found = True
        if wind_turbine.SysEfficiency > max_tsr:
            wind_turbine.SysEfficiency = max_tsr
            state.dataUtility.ShowWarningError(
                state,
                f'{current_module_object}="{state.dataIPShortCut.cAlphaArgs[0]}" '
                f'invalid {c_numeric_fields[9]}=[{state.dataIPShortCut.rNumericArgs[9]:.2f}].',
            )
            state.dataUtility.ShowContinueError(
                state,
                f"...The default value of {max_tsr:.1f} was assumed. for {c_numeric_fields[9]}",
            )

        wind_turbine.MaxPowerCoeff = state.dataIPShortCut.rNumericArgs[10]
        if wind_turbine.rotorType == RotorType.HorizontalAxis and wind_turbine.MaxPowerCoeff == 0.0:
            if l_numeric_blanks[10]:
                state.dataUtility.ShowSevereError(
                    state,
                    f'{current_module_object}="{state.dataIPShortCut.cAlphaArgs[0]}" '
                    f'invalid {c_numeric_fields[10]} is required but input is blank.',
                )
            else:
                state.dataUtility.ShowSevereError(
                    state,
                    f'{current_module_object}="{state.dataIPShortCut.cAlphaArgs[0]}" '
                    f'invalid {c_numeric_fields[10]}=[{state.dataIPShortCut.rNumericArgs[10]:.2f}] must be greater than zero.',
                )
            errors_found = True
        if wind_turbine.MaxPowerCoeff > max_power_coeff:
            wind_turbine.MaxPowerCoeff = default_pc
            state.dataUtility.ShowWarningError(
                state,
                f'{current_module_object}="{state.dataIPShortCut.cAlphaArgs[0]}" '
                f'invalid {c_numeric_fields[10]}=[{state.dataIPShortCut.rNumericArgs[10]:.2f}].',
            )
            state.dataUtility.ShowContinueError(
                state,
                f"...The default value of {default_pc:.2f} will be used. for {c_numeric_fields[10]}",
            )

        wind_turbine.LocalAnnualAvgWS = state.dataIPShortCut.rNumericArgs[11]
        if wind_turbine.LocalAnnualAvgWS == 0.0:
            if l_numeric_blanks[11]:
                state.dataUtility.ShowWarningError(
                    state,
                    f'{current_module_object}="{state.dataIPShortCut.cAlphaArgs[0]}" '
                    f'invalid {c_numeric_fields[11]} is necessary for accurate prediction but input is blank.',
                )
            else:
                state.dataUtility.ShowSevereError(
                    state,
                    f'{current_module_object}="{state.dataIPShortCut.cAlphaArgs[0]}" '
                    f'invalid {c_numeric_fields[11]}=[{state.dataIPShortCut.rNumericArgs[11]:.2f}] must be greater than zero.',
                )
                errors_found = True

        wind_turbine.HeightForLocalWS = state.dataIPShortCut.rNumericArgs[12]
        if wind_turbine.HeightForLocalWS == 0.0:
            if wind_turbine.LocalAnnualAvgWS == 0.0:
                wind_turbine.HeightForLocalWS = 0.0
            else:
                wind_turbine.HeightForLocalWS = default_h
                if l_numeric_blanks[12]:
                    state.dataUtility.ShowWarningError(
                        state,
                        f'{current_module_object}="{state.dataIPShortCut.cAlphaArgs[0]}" '
                        f'invalid {c_numeric_fields[12]} is necessary for accurate prediction but input is blank.',
                    )
                    state.dataUtility.ShowContinueError(
                        state,
                        f"...The default value of {default_h:.2f} will be used. for {c_numeric_fields[12]}",
                    )
                else:
                    state.dataUtility.ShowSevereError(
                        state,
                        f'{current_module_object}="{state.dataIPShortCut.cAlphaArgs[0]}" '
                        f'invalid {c_numeric_fields[12]}=[{state.dataIPShortCut.rNumericArgs[12]:.2f}] must be greater than zero.',
                    )
                    errors_found = True

        wind_turbine.ChordArea = state.dataIPShortCut.rNumericArgs[13]
        if wind_turbine.rotorType == RotorType.VerticalAxis and wind_turbine.ChordArea == 0.0:
            if l_numeric_blanks[13]:
                state.dataUtility.ShowSevereError(
                    state,
                    f'{current_module_object}="{state.dataIPShortCut.cAlphaArgs[0]}" '
                    f'invalid {c_numeric_fields[13]} is required but input is blank.',
                )
            else:
                state.dataUtility.ShowSevereError(
                    state,
                    f'{current_module_object}="{state.dataIPShortCut.cAlphaArgs[0]}" '
                    f'invalid {c_numeric_fields[13]}=[{state.dataIPShortCut.rNumericArgs[13]:.2f}] must be greater than zero.',
                )
            errors_found = True

        wind_turbine.DragCoeff = state.dataIPShortCut.rNumericArgs[14]
        if wind_turbine.rotorType == RotorType.VerticalAxis and wind_turbine.DragCoeff == 0.0:
            if l_numeric_blanks[14]:
                state.dataUtility.ShowSevereError(
                    state,
                    f'{current_module_object}="{state.dataIPShortCut.cAlphaArgs[0]}" '
                    f'invalid {c_numeric_fields[14]} is required but input is blank.',
                )
            else:
                state.dataUtility.ShowSevereError(
                    state,
                    f'{current_module_object}="{state.dataIPShortCut.cAlphaArgs[0]}" '
                    f'invalid {c_numeric_fields[14]}=[{state.dataIPShortCut.rNumericArgs[14]:.2f}] must be greater than zero.',
                )
            errors_found = True

        wind_turbine.LiftCoeff = state.dataIPShortCut.rNumericArgs[15]
        if wind_turbine.rotorType == RotorType.VerticalAxis and wind_turbine.LiftCoeff == 0.0:
            if l_numeric_blanks[15]:
                state.dataUtility.ShowSevereError(
                    state,
                    f'{current_module_object}="{state.dataIPShortCut.cAlphaArgs[0]}" '
                    f'invalid {c_numeric_fields[15]} is required but input is blank.',
                )
            else:
                state.dataUtility.ShowSevereError(
                    state,
                    f'{current_module_object}="{state.dataIPShortCut.cAlphaArgs[0]}" '
                    f'invalid {c_numeric_fields[15]}=[{state.dataIPShortCut.rNumericArgs[15]:.2f}] must be greater than zero.',
                )
            errors_found = True

        wind_turbine.PowerCoeffs[0] = state.dataIPShortCut.rNumericArgs[16]
        if l_numeric_blanks[16]:
            wind_turbine.PowerCoeffs[0] = 0.0
        wind_turbine.PowerCoeffs[1] = state.dataIPShortCut.rNumericArgs[17]
        if l_numeric_blanks[17]:
            wind_turbine.PowerCoeffs[1] = 0.0
        wind_turbine.PowerCoeffs[2] = state.dataIPShortCut.rNumericArgs[18]
        if l_numeric_blanks[18]:
            wind_turbine.PowerCoeffs[2] = 0.0
        wind_turbine.PowerCoeffs[3] = state.dataIPShortCut.rNumericArgs[19]
        if l_numeric_blanks[19]:
            wind_turbine.PowerCoeffs[3] = 0.0
        wind_turbine.PowerCoeffs[4] = state.dataIPShortCut.rNumericArgs[20]
        if l_numeric_blanks[20]:
            wind_turbine.PowerCoeffs[4] = 0.0
        wind_turbine.PowerCoeffs[5] = state.dataIPShortCut.rNumericArgs[21]
        if l_numeric_blanks[21]:
            wind_turbine.PowerCoeffs[5] = 0.0

    if errors_found:
        state.dataUtility.ShowFatalError(
            state, f"{current_module_object} errors occurred in input.  Program terminates."
        )

    for wind_turbine_num in range(num_wind_turbines):
        wind_turbine = state.dataWindTurbine.WindTurbineSys[wind_turbine_num]
        state.dataOutputProcessor.SetupOutputVariable(
            state,
            "Generator Produced AC Electricity Rate",
            state.dataConstant.Units.W,
            wind_turbine.Power,
            state.dataOutputProcessor.TimeStepType.System,
            state.dataOutputProcessor.StoreType.Average,
            wind_turbine.Name,
        )
        state.dataOutputProcessor.SetupOutputVariable(
            state,
            "Generator Produced AC Electricity Energy",
            state.dataConstant.Units.J,
            wind_turbine.Energy,
            state.dataOutputProcessor.TimeStepType.System,
            state.dataOutputProcessor.StoreType.Sum,
            wind_turbine.Name,
            state.dataConstant.eResource.ElectricityProduced,
            state.dataOutputProcessor.Group.Plant,
            state.dataOutputProcessor.EndUseCat.WindTurbine,
        )
        state.dataOutputProcessor.SetupOutputVariable(
            state,
            "Generator Turbine Local Wind Speed",
            state.dataConstant.Units.m_s,
            wind_turbine.LocalWindSpeed,
            state.dataOutputProcessor.TimeStepType.System,
            state.dataOutputProcessor.StoreType.Average,
            wind_turbine.Name,
        )
        state.dataOutputProcessor.SetupOutputVariable(
            state,
            "Generator Turbine Local Air Density",
            state.dataConstant.Units.kg_m3,
            wind_turbine.LocalAirDensity,
            state.dataOutputProcessor.TimeStepType.System,
            state.dataOutputProcessor.StoreType.Average,
            wind_turbine.Name,
        )
        state.dataOutputProcessor.SetupOutputVariable(
            state,
            "Generator Turbine Tip Speed Ratio",
            state.dataConstant.Units.None,
            wind_turbine.TipSpeedRatio,
            state.dataOutputProcessor.TimeStepType.System,
            state.dataOutputProcessor.StoreType.Average,
            wind_turbine.Name,
        )
        if wind_turbine.rotorType == RotorType.HorizontalAxis:
            state.dataOutputProcessor.SetupOutputVariable(
                state,
                "Generator Turbine Power Coefficient",
                state.dataConstant.Units.None,
                wind_turbine.PowerCoeff,
                state.dataOutputProcessor.TimeStepType.System,
                state.dataOutputProcessor.StoreType.Average,
                wind_turbine.Name,
            )
        elif wind_turbine.rotorType == RotorType.VerticalAxis:
            state.dataOutputProcessor.SetupOutputVariable(
                state,
                "Generator Turbine Chordal Component Velocity",
                state.dataConstant.Units.m_s,
                wind_turbine.ChordalVel,
                state.dataOutputProcessor.TimeStepType.System,
                state.dataOutputProcessor.StoreType.Average,
                wind_turbine.Name,
            )
            state.dataOutputProcessor.SetupOutputVariable(
                state,
                "Generator Turbine Normal Component Velocity",
                state.dataConstant.Units.m_s,
                wind_turbine.NormalVel,
                state.dataOutputProcessor.TimeStepType.System,
                state.dataOutputProcessor.StoreType.Average,
                wind_turbine.Name,
            )
            state.dataOutputProcessor.SetupOutputVariable(
                state,
                "Generator Turbine Relative Flow Velocity",
                state.dataConstant.Units.m_s,
                wind_turbine.RelFlowVel,
                state.dataOutputProcessor.TimeStepType.System,
                state.dataOutputProcessor.StoreType.Average,
                wind_turbine.Name,
            )
            state.dataOutputProcessor.SetupOutputVariable(
                state,
                "Generator Turbine Attack Angle",
                state.dataConstant.Units.deg,
                wind_turbine.AngOfAttack,
                state.dataOutputProcessor.TimeStepType.System,
                state.dataOutputProcessor.StoreType.Average,
                wind_turbine.Name,
            )


def init_wind_turbine(state: Any, wind_turbine_num: int) -> None:
    tab_chr = "\t"
    month_ws = [0.0] * 12

    if state.dataWindTurbine.MyOneTimeFlag:
        annual_tmy_ws = 0.0
        if state.dataFileSystem.fileExists(state.files.inStatFilePath):
            stat_file = state.files.inStatFilePath.open(state, "InitWindTurbine")
            ws_stat_found = False
            while stat_file.good():
                line_in = stat_file.readLine()
                ln_ptr = line_in.data.find("Wind Speed")
                if ln_ptr == -1:
                    continue
                while stat_file.good():
                    line_in = stat_file.readLine()
                    ln_ptr = line_in.data.find("Daily Avg")
                    if ln_ptr == -1:
                        continue
                    line_in.data = line_in.data[ln_ptr + 10 :]
                    month_ws = [0.0] * 12
                    ws_stat_found = True
                    warning_shown = False
                    for mon in range(12):
                        ln_ptr = line_in.data.find(tab_chr)
                        if ln_ptr != 0:
                            if ln_ptr != -1 or line_in.data[:ln_ptr].strip() != "":
                                if ln_ptr != -1:
                                    error = False
                                    month_ws[mon] = state.dataUtility.ProcessNumber(
                                        line_in.data[:ln_ptr], error
                                    )
                                    if error:
                                        pass
                                    line_in.data = line_in.data[ln_ptr + 1 :]
                            else:
                                if not warning_shown:
                                    state.dataUtility.ShowWarningError(
                                        state,
                                        f"InitWindTurbine: read from {state.files.inStatFilePath} file shows <365 days in weather file. "
                                        f"Annual average wind speed used will be inaccurate.",
                                    )
                                    line_in.data = line_in.data[ln_ptr + 1 :]
                                    warning_shown = True
                        else:
                            if not warning_shown:
                                state.dataUtility.ShowWarningError(
                                    state,
                                    f"InitWindTurbine: read from {state.files.inStatFilePath} file shows <365 days in weather file. "
                                    f"Annual average wind speed used will be inaccurate.",
                                )
                                line_in.data = line_in.data[ln_ptr + 1 :]
                                warning_shown = True
                    break
                if ws_stat_found:
                    break
            if ws_stat_found:
                annual_tmy_ws = sum(month_ws) / 12.0
            else:
                state.dataUtility.ShowWarningError(
                    state,
                    "InitWindTurbine: stat file did not include Wind Speed statistics. TMY Wind Speed adjusted at the height is used.",
                )
        else:
            state.dataUtility.ShowWarningError(
                state, "InitWindTurbine: stat file missing. TMY Wind Speed adjusted at the height is used."
            )

        for wt in state.dataWindTurbine.WindTurbineSys:
            wt.AnnualTMYWS = annual_tmy_ws

        state.dataWindTurbine.MyOneTimeFlag = False

    wind_turbine = state.dataWindTurbine.WindTurbineSys[wind_turbine_num - 1]

    if (
        wind_turbine.AnnualTMYWS > 0.0
        and wind_turbine.WSFactor == 0.0
        and wind_turbine.LocalAnnualAvgWS > 0
    ):
        local_tmy_ws = (
            wind_turbine.AnnualTMYWS
            * state.dataEnvrn.WeatherFileWindModCoeff
            * pow(
                wind_turbine.HeightForLocalWS / state.dataEnvrn.SiteWindBLHeight,
                state.dataEnvrn.SiteWindExp,
            )
        )
        wind_turbine.WSFactor = local_tmy_ws / wind_turbine.LocalAnnualAvgWS

    if wind_turbine.WSFactor == 0.0:
        wind_turbine.WSFactor = 1.0

    wind_turbine.Power = 0.0
    wind_turbine.TotPower = 0.0
    wind_turbine.PowerCoeff = 0.0
    wind_turbine.TipSpeedRatio = 0.0
    wind_turbine.ChordalVel = 0.0
    wind_turbine.NormalVel = 0.0
    wind_turbine.RelFlowVel = 0.0
    wind_turbine.AngOfAttack = 0.0
    wind_turbine.TanForce = 0.0
    wind_turbine.NorForce = 0.0
    wind_turbine.TotTorque = 0.0


def calc_wind_turbine(state: Any, wind_turbine_num: int, run_flag: bool) -> None:
    max_theta = 90.0
    max_degree = 360.0
    sec_in_min = 60.0

    wind_turbine = state.dataWindTurbine.WindTurbineSys[wind_turbine_num - 1]

    rotor_h = wind_turbine.RotorHeight
    rotor_d = wind_turbine.RotorDiameter
    rotor_speed = wind_turbine.RatedRotorSpeed
    local_temp = state.dataEnvironment.OutDryBulbTempAt(state, rotor_h)
    local_press = state.dataEnvironment.OutBaroPressAt(state, rotor_h)
    local_hum_rat = state.dataPsychrometrics.PsyWFnTdbTwbPb(
        state, local_temp, state.dataEnvironment.OutWetBulbTempAt(state, rotor_h), local_press
    )
    local_air_density = state.dataPsychrometrics.PsyRhoAirFnPbTdbW(
        state, local_press, local_temp, local_hum_rat
    )
    local_wind_speed = state.dataEnvironment.WindSpeedAt(state, rotor_h)
    local_wind_speed /= wind_turbine.WSFactor

    if (
        wind_turbine.availSched.getCurrentVal() > 0
        and local_wind_speed > wind_turbine.CutInSpeed
        and local_wind_speed < wind_turbine.CutOutSpeed
    ):
        period = 2.0 * math.pi
        omega = (rotor_speed * period) / sec_in_min
        swept_area = (math.pi * rotor_d * rotor_d) / 4.0
        tip_speed_ratio = (omega * (rotor_d / 2.0)) / local_wind_speed

        if tip_speed_ratio > wind_turbine.MaxTipSpeedRatio:
            tip_speed_ratio = wind_turbine.MaxTipSpeedRatio

        if wind_turbine.rotorType == RotorType.HorizontalAxis:
            max_power_coeff = wind_turbine.MaxPowerCoeff
            c1 = wind_turbine.PowerCoeffs[0]
            c2 = wind_turbine.PowerCoeffs[1]
            c3 = wind_turbine.PowerCoeffs[2]
            c4 = wind_turbine.PowerCoeffs[3]
            c5 = wind_turbine.PowerCoeffs[4]
            c6 = wind_turbine.PowerCoeffs[5]

            local_wind_speed_3 = local_wind_speed ** 3

            if c1 > 0.0 and c2 > 0.0 and c3 > 0.0 and c4 >= 0.0 and c5 > 0.0 and c6 > 0.0:
                tip_speed_ratio_at_i = tip_speed_ratio / (1.0 - (tip_speed_ratio * 0.035))
                power_coeff = (
                    c1
                    * ((c2 / tip_speed_ratio_at_i) - c5)
                    * math.exp(-(c6 / tip_speed_ratio_at_i))
                )
                if power_coeff > max_power_coeff:
                    power_coeff = max_power_coeff
                wt_power = 0.5 * local_air_density * power_coeff * swept_area * local_wind_speed_3
            else:
                wt_power = (
                    0.5
                    * local_air_density
                    * swept_area
                    * local_wind_speed_3
                    * max_power_coeff
                )
                power_coeff = max_power_coeff

            if local_wind_speed >= wind_turbine.RatedWindSpeed or wt_power > wind_turbine.RatedPower:
                wt_power = wind_turbine.RatedPower
                power_coeff = wt_power / (
                    0.5 * local_air_density * swept_area * local_wind_speed_3
                )

            wind_turbine.PowerCoeff = power_coeff

        elif wind_turbine.rotorType == RotorType.VerticalAxis:
            rotor_vel = omega * (rotor_d / 2.0)
            if tip_speed_ratio >= wind_turbine.MaxTipSpeedRatio:
                rotor_vel = local_wind_speed * wind_turbine.MaxTipSpeedRatio
                omega = rotor_vel / (rotor_d / 2.0)

            azimuth_ang = max_degree / wind_turbine.NumOfBlade
            if azimuth_ang > max_theta:
                azimuth_ang -= max_theta
                if azimuth_ang == max_theta:
                    azimuth_ang = 0.0
            elif azimuth_ang == max_theta:
                azimuth_ang = 0.0

            induced_vel = local_wind_speed * 2.0 / 3.0

            sin_azimuth_ang = math.sin(azimuth_ang * math.pi / 180.0)
            cos_azimuth_ang = math.cos(azimuth_ang * math.pi / 180.0)
            chordal_vel = rotor_vel + induced_vel * cos_azimuth_ang
            normal_vel = induced_vel * sin_azimuth_ang
            rel_flow_vel = math.sqrt(chordal_vel * chordal_vel + normal_vel * normal_vel)

            ang_of_attack = math.atan(
                (sin_azimuth_ang
                 / ((rotor_vel / local_wind_speed) / (induced_vel / local_wind_speed) + cos_azimuth_ang))
            )

            sin_ang_of_attack = math.sin(ang_of_attack * math.pi / 180.0)
            cos_ang_of_attack = math.cos(ang_of_attack * math.pi / 180.0)
            tan_force_coeff = abs(
                wind_turbine.LiftCoeff * sin_ang_of_attack
                - wind_turbine.DragCoeff * cos_ang_of_attack
            )
            nor_force_coeff = (
                wind_turbine.LiftCoeff * cos_ang_of_attack
                + wind_turbine.DragCoeff * sin_ang_of_attack
            )

            rel_flow_vel_2 = rel_flow_vel * rel_flow_vel
            density_fac = 0.5 * local_air_density * wind_turbine.ChordArea * rel_flow_vel_2
            tan_force = tan_force_coeff * density_fac
            nor_force = nor_force_coeff * density_fac
            constant = (1.0 / period) * (tan_force / rel_flow_vel_2)

            int_rel_flow_vel = rotor_vel * rotor_vel * period + induced_vel * induced_vel * period

            avg_tan_force = constant * int_rel_flow_vel
            tot_torque = wind_turbine.NumOfBlade * avg_tan_force * (rotor_d / 2.0)
            wt_power = tot_torque * omega

            if wt_power > wind_turbine.RatedPower:
                wt_power = wind_turbine.RatedPower

            wind_turbine.ChordalVel = chordal_vel
            wind_turbine.NormalVel = normal_vel
            wind_turbine.RelFlowVel = rel_flow_vel
            wind_turbine.TanForce = tan_force
            wind_turbine.NorForce = nor_force
            wind_turbine.TotTorque = tot_torque

        if wt_power > wind_turbine.RatedPower:
            wt_power = wind_turbine.RatedPower

        power = wt_power * wind_turbine.SysEfficiency

        wind_turbine.Power = power
        wind_turbine.TotPower = wt_power
        wind_turbine.LocalWindSpeed = local_wind_speed
        wind_turbine.LocalAirDensity = local_air_density
        wind_turbine.TipSpeedRatio = tip_speed_ratio

    else:
        wind_turbine.Power = 0.0
        wind_turbine.TotPower = 0.0
        wind_turbine.PowerCoeff = 0.0
        wind_turbine.LocalWindSpeed = local_wind_speed
        wind_turbine.LocalAirDensity = local_air_density
        wind_turbine.TipSpeedRatio = 0.0
        wind_turbine.ChordalVel = 0.0
        wind_turbine.NormalVel = 0.0
        wind_turbine.RelFlowVel = 0.0
        wind_turbine.AngOfAttack = 0.0
        wind_turbine.TanForce = 0.0
        wind_turbine.NorForce = 0.0
        wind_turbine.TotTorque = 0.0


def report_wind_turbine(state: Any, wind_turbine_num: int) -> None:
    time_step_sys_sec = state.dataHVACGlobal.TimeStepSysSec
    wind_turbine = state.dataWindTurbine.WindTurbineSys[wind_turbine_num - 1]
    wind_turbine.Energy = wind_turbine.Power * time_step_sys_sec
