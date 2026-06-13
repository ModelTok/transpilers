# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData (from Data.EnergyPlusData): state object containing dataGeneral
# - DataRootFinder.PointType, RootFinderDataType, Slope, RootFinderMethod, RootFinderStatus
# - InputOutputFile: file handle type
# - ShowSevereError, ShowContinueError, ShowFatalError (from UtilityRoutines)
# - EnergyPlus.format: formatting function
# - DataPrecisionGlobals.constant_zero: float constant

from enum import Enum
from dataclasses import dataclass, field
from typing import Protocol, List
import math

class Slope(Enum):
    Increasing = 1
    Decreasing = 2

class RootFinderMethod(Enum):
    None_ = 0
    Bisection = 1
    FalsePosition = 2
    Secant = 3
    Brent = 4
    Bracket = 5

class RootFinderStatus(Enum):
    None_ = 0
    OK = 1
    OKMin = 2
    OKMax = 3
    OKRoundOff = 4
    WarningSingular = 5
    WarningNonMonotonic = 6
    ErrorRange = 7
    ErrorBracket = 8
    ErrorSlope = 9
    ErrorSingular = 10

@dataclass
class PointType:
    X: float = 0.0
    Y: float = 0.0
    DefinedFlag: bool = False

@dataclass
class Controls:
    SlopeType: Slope = Slope.Increasing
    MethodType: RootFinderMethod = RootFinderMethod.None_
    TolX: float = 0.0
    ATolX: float = 0.0
    ATolY: float = 0.0

@dataclass
class RootFinderDataType:
    MinPoint: PointType = field(default_factory=PointType)
    MaxPoint: PointType = field(default_factory=PointType)
    LowerPoint: PointType = field(default_factory=PointType)
    UpperPoint: PointType = field(default_factory=PointType)
    CurrentPoint: PointType = field(default_factory=PointType)
    History: List[PointType] = field(default_factory=lambda: [PointType() for _ in range(3)])
    NumHistory: int = 0
    Controls: Controls = field(default_factory=Controls)
    Increment: PointType = field(default_factory=PointType)
    XCandidate: float = 0.0
    StatusFlag: RootFinderStatus = RootFinderStatus.None_
    CurrentMethodType: RootFinderMethod = RootFinderMethod.None_
    ConvergenceRate: float = -1.0

class InputOutputFile(Protocol):
    def write(self, text: str) -> None: ...

class EnergyPlusData(Protocol):
    dataGeneral: object

def setup_root_finder(state: EnergyPlusData,
                      root_finder_data: RootFinderDataType,
                      slope_type: Slope,
                      method_type: RootFinderMethod,
                      tol_x: float,
                      atol_x: float,
                      atol_y: float) -> None:
    if slope_type != Slope.Increasing and slope_type != Slope.Decreasing:
        show_severe_error(state, "SetupRootFinder: Invalid function slope specification. Valid choices are:")
        show_continue_error(state, f"SetupRootFinder: Slope::Increasing={Slope.Increasing}")
        show_continue_error(state, f"SetupRootFinder: Slope::Decreasing={Slope.Decreasing}")
        show_fatal_error(state, "SetupRootFinder: Preceding error causes program termination.")
    root_finder_data.Controls.SlopeType = slope_type

    if (method_type != RootFinderMethod.Bisection and method_type != RootFinderMethod.FalsePosition and
        method_type != RootFinderMethod.Secant and method_type != RootFinderMethod.Brent):
        show_severe_error(state, "SetupRootFinder: Invalid solution method specification. Valid choices are:")
        show_continue_error(state, f"SetupRootFinder: iMethodBisection={RootFinderMethod.Bisection}")
        show_continue_error(state, f"SetupRootFinder: iMethodFalsePosition={RootFinderMethod.FalsePosition}")
        show_continue_error(state, f"SetupRootFinder: iMethodSecant={RootFinderMethod.Secant}")
        show_continue_error(state, f"SetupRootFinder: iMethodBrent={RootFinderMethod.Brent}")
        show_fatal_error(state, "SetupRootFinder: Preceding error causes program termination.")
    root_finder_data.Controls.MethodType = method_type

    if tol_x < 0.0:
        show_fatal_error(state, "SetupRootFinder: Invalid tolerance specification for X variables. TolX >= 0")
    root_finder_data.Controls.TolX = tol_x

    if atol_x < 0.0:
        show_fatal_error(state, "SetupRootFinder: Invalid absolute tolerance specification for X variables. ATolX >= 0")
    root_finder_data.Controls.ATolX = atol_x

    if atol_y < 0.0:
        show_fatal_error(state, "SetupRootFinder: Invalid absolute tolerance specification for Y variables. ATolY >= 0")
    root_finder_data.Controls.ATolY = atol_y

    reset_root_finder(root_finder_data, 0.0, 0.0)

def reset_root_finder(root_finder_data: RootFinderDataType,
                      x_min: float,
                      x_max: float) -> None:
    root_finder_data.MinPoint.X = x_min
    root_finder_data.MinPoint.Y = 0.0
    root_finder_data.MinPoint.DefinedFlag = False

    root_finder_data.MaxPoint.X = x_max
    root_finder_data.MaxPoint.Y = 0.0
    root_finder_data.MaxPoint.DefinedFlag = False

    root_finder_data.LowerPoint.X = 0.0
    root_finder_data.LowerPoint.Y = 0.0
    root_finder_data.LowerPoint.DefinedFlag = False

    root_finder_data.UpperPoint.X = 0.0
    root_finder_data.UpperPoint.Y = 0.0
    root_finder_data.UpperPoint.DefinedFlag = False

    root_finder_data.CurrentPoint.X = 0.0
    root_finder_data.CurrentPoint.Y = 0.0
    root_finder_data.CurrentPoint.DefinedFlag = False

    root_finder_data.NumHistory = 0
    for e in root_finder_data.History:
        e.X = 0.0
        e.Y = 0.0
        e.DefinedFlag = False

    root_finder_data.Increment.X = 0.0
    root_finder_data.Increment.Y = 0.0
    root_finder_data.Increment.DefinedFlag = False

    root_finder_data.XCandidate = 0.0

    root_finder_data.StatusFlag = RootFinderStatus.None_
    root_finder_data.CurrentMethodType = RootFinderMethod.None_
    root_finder_data.ConvergenceRate = -1.0

def initialize_root_finder(state: EnergyPlusData,
                           root_finder_data: RootFinderDataType,
                           x_min: float,
                           x_max: float) -> None:
    x_min_reset = x_min
    if x_min > x_max:
        if x_max == 0.0:
            x_min_reset = x_max
        else:
            show_fatal_error(state, f"InitializeRootFinder: Invalid min/max bounds XMin={x_min:.6f} must be smaller than XMax={x_max:.6f}")

    saved_x_candidate = root_finder_data.XCandidate
    reset_root_finder(root_finder_data, x_min_reset, x_max)
    root_finder_data.XCandidate = min(root_finder_data.MaxPoint.X, max(saved_x_candidate, root_finder_data.MinPoint.X))

def iterate_root_finder(state: EnergyPlusData,
                        root_finder_data: RootFinderDataType,
                        x: float,
                        y: float,
                        is_done_flag: list) -> None:
    root_finder_data.StatusFlag = RootFinderStatus.None_

    if not check_min_max_range(root_finder_data, x):
        root_finder_data.StatusFlag = RootFinderStatus.ErrorRange
        is_done_flag[0] = True
        return

    update_min_max(root_finder_data, x, y)

    if root_finder_data.MinPoint.DefinedFlag and root_finder_data.MaxPoint.DefinedFlag:
        if root_finder_data.MinPoint.X == root_finder_data.MaxPoint.X:
            root_finder_data.StatusFlag = RootFinderStatus.OKMin
            root_finder_data.XCandidate = root_finder_data.MinPoint.X
            is_done_flag[0] = True
            return

        if check_min_constraint(state, root_finder_data):
            root_finder_data.StatusFlag = RootFinderStatus.OKMin
            root_finder_data.XCandidate = root_finder_data.MinPoint.X
            is_done_flag[0] = True
            return

        if not check_non_singularity(root_finder_data):
            root_finder_data.StatusFlag = RootFinderStatus.ErrorSingular
            is_done_flag[0] = True
            return

        if not check_slope(state, root_finder_data):
            root_finder_data.StatusFlag = RootFinderStatus.ErrorSlope
            is_done_flag[0] = True
            return

    if root_finder_data.MinPoint.DefinedFlag:
        if check_min_constraint(state, root_finder_data):
            root_finder_data.StatusFlag = RootFinderStatus.OKMin
            root_finder_data.XCandidate = root_finder_data.MinPoint.X
            is_done_flag[0] = True
            return

    if root_finder_data.MaxPoint.DefinedFlag:
        if check_max_constraint(state, root_finder_data):
            root_finder_data.StatusFlag = RootFinderStatus.OKMax
            root_finder_data.XCandidate = root_finder_data.MaxPoint.X
            is_done_flag[0] = True
            return

    if check_root_finder_convergence(root_finder_data, y):
        root_finder_data.StatusFlag = RootFinderStatus.OK
        root_finder_data.XCandidate = x
        update_root_finder(state, root_finder_data, x, y)
        is_done_flag[0] = True
        return

    if check_bracket_round_off(root_finder_data):
        root_finder_data.StatusFlag = RootFinderStatus.OKRoundOff
        is_done_flag[0] = True
        return

    if not check_lower_upper_bracket(root_finder_data, x):
        root_finder_data.StatusFlag = RootFinderStatus.ErrorBracket
        is_done_flag[0] = True
        return

    update_root_finder(state, root_finder_data, x, y)
    advance_root_finder(state, root_finder_data)
    is_done_flag[0] = False

def check_internal_consistency(state: EnergyPlusData,
                               root_finder_data: RootFinderDataType) -> RootFinderStatus:
    status = RootFinderStatus.None_

    if root_finder_data.LowerPoint.DefinedFlag and root_finder_data.UpperPoint.DefinedFlag:
        if root_finder_data.LowerPoint.X > root_finder_data.UpperPoint.X:
            return RootFinderStatus.ErrorRange

        if root_finder_data.Controls.SlopeType == Slope.Increasing:
            if root_finder_data.LowerPoint.Y > root_finder_data.UpperPoint.Y:
                return RootFinderStatus.WarningNonMonotonic
        elif root_finder_data.Controls.SlopeType == Slope.Decreasing:
            if root_finder_data.LowerPoint.Y < root_finder_data.UpperPoint.Y:
                return RootFinderStatus.WarningNonMonotonic
        else:
            show_severe_error(state, "CheckInternalConsistency: Invalid function slope specification. Valid choices are:")
            show_continue_error(state, f"CheckInternalConsistency: Slope::Increasing={Slope.Increasing}")
            show_continue_error(state, f"CheckInternalConsistency: Slope::Decreasing={Slope.Decreasing}")
            show_fatal_error(state, "CheckInternalConsistency: Preceding error causes program termination.")

        if root_finder_data.UpperPoint.X > root_finder_data.LowerPoint.X:
            if root_finder_data.UpperPoint.Y == root_finder_data.LowerPoint.Y:
                return RootFinderStatus.ErrorSingular

    if root_finder_data.MinPoint.DefinedFlag:
        if root_finder_data.Controls.SlopeType == Slope.Increasing:
            if root_finder_data.MinPoint.Y >= 0.0:
                return RootFinderStatus.OKMin
        elif root_finder_data.Controls.SlopeType == Slope.Decreasing:
            if root_finder_data.MinPoint.Y <= 0.0:
                return RootFinderStatus.OKMin
        else:
            show_severe_error(state, "CheckInternalConsistency: Invalid function slope specification. Valid choices are:")
            show_continue_error(state, f"CheckInternalConsistency: Slope::Increasing={Slope.Increasing}")
            show_continue_error(state, f"CheckInternalConsistency: Slope::Decreasing={Slope.Decreasing}")
            show_fatal_error(state, "CheckInternalConsistency: Preceding error causes program termination.")

    if root_finder_data.MaxPoint.DefinedFlag:
        if root_finder_data.Controls.SlopeType == Slope.Increasing:
            if root_finder_data.MaxPoint.Y <= 0.0:
                return RootFinderStatus.OKMax
        elif root_finder_data.Controls.SlopeType == Slope.Decreasing:
            if root_finder_data.MaxPoint.Y >= 0.0:
                return RootFinderStatus.OKMax
        else:
            show_severe_error(state, "CheckInternalConsistency: Invalid function slope specification. Valid choices are:")
            show_continue_error(state, f"CheckInternalConsistency: Slope::Increasing={Slope.Increasing}")
            show_continue_error(state, f"CheckInternalConsistency: Slope::Decreasing={Slope.Decreasing}")
            show_fatal_error(state, "CheckInternalConsistency: Preceding error causes program termination.")

    return status

def check_root_finder_candidate(root_finder_data: RootFinderDataType,
                                x: float) -> bool:
    return check_min_max_range(root_finder_data, x) and check_lower_upper_bracket(root_finder_data, x)

def check_min_max_range(root_finder_data: RootFinderDataType,
                        x: float) -> bool:
    if root_finder_data.MinPoint.DefinedFlag:
        if x < root_finder_data.MinPoint.X:
            return False

    if root_finder_data.MaxPoint.DefinedFlag:
        if x > root_finder_data.MaxPoint.X:
            return False

    return True

def check_lower_upper_bracket(root_finder_data: RootFinderDataType,
                              x: float) -> bool:
    if root_finder_data.LowerPoint.DefinedFlag:
        if x < root_finder_data.LowerPoint.X:
            return False

    if root_finder_data.UpperPoint.DefinedFlag:
        if x > root_finder_data.UpperPoint.X:
            return False

    return True

def check_slope(state: EnergyPlusData,
                root_finder_data: RootFinderDataType) -> bool:
    if root_finder_data.Controls.SlopeType == Slope.Increasing:
        if root_finder_data.MinPoint.Y < root_finder_data.MaxPoint.Y:
            return True
    elif root_finder_data.Controls.SlopeType == Slope.Decreasing:
        if root_finder_data.MinPoint.Y > root_finder_data.MaxPoint.Y:
            return True
    else:
        show_severe_error(state, "CheckSlope: Invalid function slope specification. Valid choices are:")
        show_continue_error(state, f"CheckSlope: Slope::Increasing={Slope.Increasing}")
        show_continue_error(state, f"CheckSlope: Slope::Decreasing={Slope.Decreasing}")
        show_fatal_error(state, "CheckSlope: Preceding error causes program termination.")

    return False

def check_non_singularity(root_finder_data: RootFinderDataType) -> bool:
    SafetyFactor = 0.1
    DeltaY = abs(root_finder_data.MinPoint.Y - root_finder_data.MaxPoint.Y)
    ATolY = SafetyFactor * root_finder_data.Controls.ATolY

    if abs(DeltaY) <= ATolY:
        return False
    else:
        return True

def check_min_constraint(state: EnergyPlusData,
                         root_finder_data: RootFinderDataType) -> bool:
    if root_finder_data.Controls.SlopeType == Slope.Increasing:
        if root_finder_data.MinPoint.Y >= 0.0:
            return True
    elif root_finder_data.Controls.SlopeType == Slope.Decreasing:
        if root_finder_data.MinPoint.Y <= 0.0:
            return True
    else:
        show_severe_error(state, "CheckMinConstraint: Invalid function slope specification. Valid choices are:")
        show_continue_error(state, f"CheckMinConstraint: Slope::Increasing={Slope.Increasing}")
        show_continue_error(state, f"CheckMinConstraint: Slope::Decreasing={Slope.Decreasing}")
        show_fatal_error(state, "CheckMinConstraint: Preceding error causes program termination.")

    return False

def check_max_constraint(state: EnergyPlusData,
                         root_finder_data: RootFinderDataType) -> bool:
    if root_finder_data.Controls.SlopeType == Slope.Increasing:
        if root_finder_data.MaxPoint.Y <= 0.0:
            return True
    elif root_finder_data.Controls.SlopeType == Slope.Decreasing:
        if root_finder_data.MaxPoint.Y >= 0.0:
            return True
    else:
        show_severe_error(state, "CheckMaxConstraint: Invalid function slope specification. Valid choices are:")
        show_continue_error(state, f"CheckMaxConstraint: Slope::Increasing={Slope.Increasing}")
        show_continue_error(state, f"CheckMaxConstraint: Slope::Decreasing={Slope.Decreasing}")
        show_fatal_error(state, "CheckMaxConstraint: Preceding error causes program termination.")

    return False

def check_root_finder_convergence(root_finder_data: RootFinderDataType,
                                  y: float) -> bool:
    if abs(y) <= root_finder_data.Controls.ATolY:
        return True

    return False

def check_bracket_round_off(root_finder_data: RootFinderDataType) -> bool:
    if root_finder_data.LowerPoint.DefinedFlag and root_finder_data.UpperPoint.DefinedFlag:
        DeltaUL = root_finder_data.UpperPoint.X - root_finder_data.LowerPoint.X
        TypUL = (abs(root_finder_data.UpperPoint.X) + abs(root_finder_data.LowerPoint.X)) / 2.0
        TolUL = root_finder_data.Controls.TolX * abs(TypUL) + root_finder_data.Controls.ATolX

        if abs(DeltaUL) <= 0.5 * abs(TolUL):
            return True

    return False

def update_min_max(root_finder_data: RootFinderDataType,
                   x: float,
                   y: float) -> None:
    if x == root_finder_data.MinPoint.X:
        root_finder_data.MinPoint.Y = y
        root_finder_data.MinPoint.DefinedFlag = True

    if x == root_finder_data.MaxPoint.X:
        root_finder_data.MaxPoint.Y = y
        root_finder_data.MaxPoint.DefinedFlag = True

def update_bracket(state: EnergyPlusData,
                   root_finder_data: RootFinderDataType,
                   x: float,
                   y: float) -> None:
    if root_finder_data.Controls.SlopeType == Slope.Increasing:
        if y <= 0.0:
            if not root_finder_data.LowerPoint.DefinedFlag:
                root_finder_data.LowerPoint.DefinedFlag = True
                root_finder_data.LowerPoint.X = x
                root_finder_data.LowerPoint.Y = y
            else:
                if x >= root_finder_data.LowerPoint.X:
                    if y == root_finder_data.LowerPoint.Y:
                        root_finder_data.StatusFlag = RootFinderStatus.WarningSingular
                    elif y < root_finder_data.LowerPoint.Y:
                        root_finder_data.StatusFlag = RootFinderStatus.WarningNonMonotonic
                    root_finder_data.LowerPoint.X = x
                    root_finder_data.LowerPoint.Y = y
                else:
                    show_severe_error(state, "UpdateBracket: Current iterate is smaller than the lower bracket.")
                    show_continue_error(state, f"UpdateBracket: X={x:.15f}, Y={y:.15f}")
                    show_continue_error(state, f"UpdateBracket: XLower={root_finder_data.LowerPoint.X:.15f}, YLower={root_finder_data.LowerPoint.Y:.15f}")
                    show_fatal_error(state, "UpdateBracket: Preceding error causes program termination.")
        else:
            if not root_finder_data.UpperPoint.DefinedFlag:
                root_finder_data.UpperPoint.DefinedFlag = True
                root_finder_data.UpperPoint.X = x
                root_finder_data.UpperPoint.Y = y
            else:
                if x <= root_finder_data.UpperPoint.X:
                    if y == root_finder_data.UpperPoint.Y:
                        root_finder_data.StatusFlag = RootFinderStatus.WarningSingular
                    elif y > root_finder_data.UpperPoint.Y:
                        root_finder_data.StatusFlag = RootFinderStatus.WarningNonMonotonic
                    root_finder_data.UpperPoint.X = x
                    root_finder_data.UpperPoint.Y = y
                else:
                    show_severe_error(state, "UpdateBracket: Current iterate is greater than the upper bracket.")
                    show_continue_error(state, f"UpdateBracket: X={x:.15f}, Y={y:.15f}")
                    show_continue_error(state, f"UpdateBracket: XUpper={root_finder_data.UpperPoint.X:.15f}, YUpper={root_finder_data.UpperPoint.Y:.15f}")
                    show_fatal_error(state, "UpdateBracket: Preceding error causes program termination.")
    elif root_finder_data.Controls.SlopeType == Slope.Decreasing:
        if y >= 0.0:
            if not root_finder_data.LowerPoint.DefinedFlag:
                root_finder_data.LowerPoint.DefinedFlag = True
                root_finder_data.LowerPoint.X = x
                root_finder_data.LowerPoint.Y = y
            else:
                if x >= root_finder_data.LowerPoint.X:
                    if y == root_finder_data.LowerPoint.Y:
                        root_finder_data.StatusFlag = RootFinderStatus.WarningSingular
                    elif y > root_finder_data.LowerPoint.Y:
                        root_finder_data.StatusFlag = RootFinderStatus.WarningNonMonotonic
                    root_finder_data.LowerPoint.X = x
                    root_finder_data.LowerPoint.Y = y
                else:
                    show_severe_error(state, "UpdateBracket: Current iterate is smaller than the lower bracket.")
                    show_continue_error(state, f"UpdateBracket: X={x:.15f}, Y={y:.15f}")
                    show_continue_error(state, f"UpdateBracket: XLower={root_finder_data.LowerPoint.X:.15f}, YLower={root_finder_data.LowerPoint.Y:.15f}")
                    show_fatal_error(state, "UpdateBracket: Preceding error causes program termination.")
        else:
            if not root_finder_data.UpperPoint.DefinedFlag:
                root_finder_data.UpperPoint.DefinedFlag = True
                root_finder_data.UpperPoint.X = x
                root_finder_data.UpperPoint.Y = y
            else:
                if x <= root_finder_data.UpperPoint.X:
                    if y == root_finder_data.UpperPoint.Y:
                        root_finder_data.StatusFlag = RootFinderStatus.WarningSingular
                    elif y < root_finder_data.UpperPoint.Y:
                        root_finder_data.StatusFlag = RootFinderStatus.WarningNonMonotonic
                    root_finder_data.UpperPoint.X = x
                    root_finder_data.UpperPoint.Y = y
                else:
                    show_severe_error(state, "UpdateBracket: Current iterate is greater than the upper bracket.")
                    show_continue_error(state, f"UpdateBracket: X={x:.15f}, Y={y:.15f}")
                    show_continue_error(state, f"UpdateBracket: XUpper={root_finder_data.UpperPoint.X:.15f}, YUpper={root_finder_data.UpperPoint.Y:.15f}")
                    show_fatal_error(state, "UpdateBracket: Preceding error causes program termination.")
    else:
        show_severe_error(state, "UpdateBracket: Invalid function slope specification. Valid choices are:")
        show_continue_error(state, f"UpdateBracket: Slope::Increasing={Slope.Increasing}")
        show_continue_error(state, f"UpdateBracket: Slope::Decreasing={Slope.Decreasing}")
        show_fatal_error(state, "UpdateBracket: Preceding error causes program termination.")

def update_history(root_finder_data: RootFinderDataType,
                   x: float,
                   y: float) -> None:
    for e in root_finder_data.History:
        e.X = 0.0
        e.Y = 0.0
        e.DefinedFlag = False

    num_history = 0
    if root_finder_data.LowerPoint.DefinedFlag:
        num_history += 1
        root_finder_data.History[num_history - 1].DefinedFlag = root_finder_data.LowerPoint.DefinedFlag
        root_finder_data.History[num_history - 1].X = root_finder_data.LowerPoint.X
        root_finder_data.History[num_history - 1].Y = root_finder_data.LowerPoint.Y
    if root_finder_data.UpperPoint.DefinedFlag:
        num_history += 1
        root_finder_data.History[num_history - 1].DefinedFlag = root_finder_data.UpperPoint.DefinedFlag
        root_finder_data.History[num_history - 1].X = root_finder_data.UpperPoint.X
        root_finder_data.History[num_history - 1].Y = root_finder_data.UpperPoint.Y
    num_history += 1
    root_finder_data.History[num_history - 1].DefinedFlag = True
    root_finder_data.History[num_history - 1].X = x
    root_finder_data.History[num_history - 1].Y = y

    root_finder_data.NumHistory = num_history
    sort_history(num_history, root_finder_data.History)

def update_root_finder(state: EnergyPlusData,
                       root_finder_data: RootFinderDataType,
                       x: float,
                       y: float) -> None:
    update_history(root_finder_data, x, y)
    update_bracket(state, root_finder_data, x, y)

    if root_finder_data.CurrentPoint.DefinedFlag:
        root_finder_data.Increment.DefinedFlag = True
        root_finder_data.Increment.X = x - root_finder_data.CurrentPoint.X
        root_finder_data.Increment.Y = y - root_finder_data.CurrentPoint.Y

        if abs(root_finder_data.CurrentPoint.Y) > 0.0:
            root_finder_data.ConvergenceRate = abs(y) / abs(root_finder_data.CurrentPoint.Y)
        else:
            root_finder_data.ConvergenceRate = -1.0

    root_finder_data.CurrentPoint.DefinedFlag = True
    root_finder_data.CurrentPoint.X = x
    root_finder_data.CurrentPoint.Y = y

def sort_history(n: int,
                 history: List[PointType]) -> None:
    if n <= 1:
        return

    for i in range(n - 1):
        for j in range(i + 1, n):
            if history[j].DefinedFlag:
                if abs(history[j].Y) < abs(history[i].Y):
                    history[i].X, history[j].X = history[j].X, history[i].X
                    history[i].Y, history[j].Y = history[j].Y, history[i].Y

def advance_root_finder(state: EnergyPlusData,
                        root_finder_data: RootFinderDataType) -> None:
    x_next = 0.0

    if not root_finder_data.LowerPoint.DefinedFlag:
        root_finder_data.CurrentMethodType = RootFinderMethod.Bracket
        if bracket_root(root_finder_data, [x_next]):
            root_finder_data.XCandidate = x_next
        else:
            if root_finder_data.MinPoint.DefinedFlag:
                root_finder_data.XCandidate = root_finder_data.MinPoint.X
            else:
                show_fatal_error(state, "AdvanceRootFinder: Cannot find lower bracket.")

    elif not root_finder_data.UpperPoint.DefinedFlag:
        root_finder_data.CurrentMethodType = RootFinderMethod.Bracket
        if bracket_root(root_finder_data, [x_next]):
            root_finder_data.XCandidate = x_next
        else:
            if root_finder_data.MaxPoint.DefinedFlag:
                root_finder_data.XCandidate = root_finder_data.MaxPoint.X
            else:
                show_fatal_error(state, "AdvanceRootFinder: Cannot find upper bracket.")

    else:
        if root_finder_data.StatusFlag == RootFinderStatus.OKRoundOff:
            root_finder_data.XCandidate = bisection_method(root_finder_data)
        elif root_finder_data.StatusFlag == RootFinderStatus.WarningSingular or root_finder_data.StatusFlag == RootFinderStatus.WarningNonMonotonic:
            root_finder_data.XCandidate = false_position_method(root_finder_data)
        else:
            if root_finder_data.Controls.MethodType == RootFinderMethod.Bisection:
                root_finder_data.XCandidate = bisection_method(root_finder_data)
            elif root_finder_data.Controls.MethodType == RootFinderMethod.FalsePosition:
                root_finder_data.XCandidate = false_position_method(root_finder_data)
            elif root_finder_data.Controls.MethodType == RootFinderMethod.Secant:
                root_finder_data.XCandidate = secant_method(root_finder_data)
            elif root_finder_data.Controls.MethodType == RootFinderMethod.Brent:
                root_finder_data.XCandidate = brent_method(root_finder_data)
            else:
                show_severe_error(state, "AdvanceRootFinder: Invalid solution method specification. Valid choices are:")
                show_continue_error(state, f"AdvanceRootFinder: iMethodBisection={RootFinderMethod.Bisection}")
                show_continue_error(state, f"AdvanceRootFinder: iMethodFalsePosition={RootFinderMethod.FalsePosition}")
                show_continue_error(state, f"AdvanceRootFinder: iMethodSecant={RootFinderMethod.Secant}")
                show_continue_error(state, f"AdvanceRootFinder: iMethodBrent={RootFinderMethod.Brent}")
                show_fatal_error(state, "AdvanceRootFinder: Preceding error causes program termination.")

def bracket_root(root_finder_data: RootFinderDataType,
                 x_next: list) -> bool:
    if root_finder_data.NumHistory != 2:
        return False

    if root_finder_data.StatusFlag == RootFinderStatus.WarningSingular or root_finder_data.StatusFlag == RootFinderStatus.WarningNonMonotonic:
        return False

    x_next_val = [0.0]
    if secant_formula(root_finder_data, x_next_val):
        if check_root_finder_candidate(root_finder_data, x_next_val[0]):
            x_next[0] = x_next_val[0]
            return True

    return False

def bisection_method(root_finder_data: RootFinderDataType) -> float:
    root_finder_data.CurrentMethodType = RootFinderMethod.Bisection
    return (root_finder_data.LowerPoint.X + root_finder_data.UpperPoint.X) / 2.0

def false_position_method(root_finder_data: RootFinderDataType) -> float:
    Num = root_finder_data.UpperPoint.X - root_finder_data.LowerPoint.X
    Den = root_finder_data.UpperPoint.Y - root_finder_data.LowerPoint.Y

    if Den != 0.0:
        root_finder_data.CurrentMethodType = RootFinderMethod.FalsePosition
        x_candidate = root_finder_data.LowerPoint.X - root_finder_data.LowerPoint.Y * Num / Den

        if not check_root_finder_candidate(root_finder_data, x_candidate):
            x_candidate = bisection_method(root_finder_data)
    else:
        x_candidate = bisection_method(root_finder_data)

    return x_candidate

def secant_method(root_finder_data: RootFinderDataType) -> float:
    x_next_val = [0.0]
    if secant_formula(root_finder_data, x_next_val):
        root_finder_data.CurrentMethodType = RootFinderMethod.Secant
        x_candidate = x_next_val[0]

        if not check_root_finder_candidate(root_finder_data, x_candidate):
            x_candidate = false_position_method(root_finder_data)
    else:
        x_candidate = false_position_method(root_finder_data)

    return x_candidate

def secant_formula(root_finder_data: RootFinderDataType,
                   x_next: list) -> bool:
    Num = root_finder_data.Increment.X
    Den = root_finder_data.Increment.Y

    if Den != 0.0 and Num != 0.0:
        x_next[0] = root_finder_data.CurrentPoint.X - root_finder_data.CurrentPoint.Y * Num / Den
        return True
    else:
        return False

def brent_method(root_finder_data: RootFinderDataType) -> float:
    if root_finder_data.NumHistory == 3:
        A = root_finder_data.History[1].X
        FA = root_finder_data.History[1].Y
        B = root_finder_data.History[0].X
        FB = root_finder_data.History[0].Y
        C = root_finder_data.History[2].X
        FC = root_finder_data.History[2].Y

        if FC == 0.0:
            return C
        if FA == 0.0:
            return A

        R = FB / FC
        S = FB / FA
        T = FA / FC

        P = S * (T * (R - T) * (C - B) - (1.0 - R) * (B - A))
        Q = (T - 1.0) * (R - 1.0) * (S - 1.0)

        if abs(P) <= 0.75 * abs(Q * root_finder_data.Increment.X):
            root_finder_data.CurrentMethodType = RootFinderMethod.Brent
            x_candidate = B + P / Q

            if not check_root_finder_candidate(root_finder_data, x_candidate):
                x_candidate = false_position_method(root_finder_data)
        else:
            x_candidate = bisection_method(root_finder_data)

    else:
        x_candidate = secant_method(root_finder_data)

    return x_candidate

def write_root_finder_trace_header(trace_file: InputOutputFile) -> None:
    trace_file.write("Status,Method,CurrentPoint%X,CurrentPoint%Y,XCandidate,ConvergenceRate,MinPoint%X,MinPoint%Y,LowerPoint%X,LowerPoint%Y,UpperPoint%X,UpperPoint%Y,MaxPoint%X,MaxPoint%Y,History(1)%X,History(1)%Y,History(2)%X,History(2)%Y,History(3)%X,History(3)%Y,\n")

def write_root_finder_trace(trace_file: InputOutputFile,
                            root_finder_data: RootFinderDataType) -> None:
    trace_file.write(f"{root_finder_data.StatusFlag},{root_finder_data.CurrentMethodType},")
    write_point(trace_file, root_finder_data.CurrentPoint, False)
    trace_file.write(f"{root_finder_data.XCandidate:20.10f},{root_finder_data.ConvergenceRate:20.10f},")
    write_point(trace_file, root_finder_data.MinPoint, True)
    write_point(trace_file, root_finder_data.LowerPoint, False)
    write_point(trace_file, root_finder_data.UpperPoint, False)
    write_point(trace_file, root_finder_data.MaxPoint, True)
    write_point(trace_file, root_finder_data.History[0], False)
    write_point(trace_file, root_finder_data.History[1], False)
    write_point(trace_file, root_finder_data.History[2], False)

def write_point(trace_file: InputOutputFile,
                point_data: PointType,
                show_x_value: bool) -> None:
    if point_data.DefinedFlag:
        trace_file.write(f"{point_data.X:20.10f},{point_data.Y:20.10f},")
    else:
        if show_x_value:
            trace_file.write(f"{point_data.X:20.10f},,")
        else:
            trace_file.write(",,")

def debug_root_finder(debug_file: InputOutputFile,
                      root_finder_data: RootFinderDataType) -> None:
    debug_file.write("Current = ")
    write_point(debug_file, root_finder_data.CurrentPoint, True)
    debug_file.write("\n")

    debug_file.write("Min     = ")
    write_point(debug_file, root_finder_data.MinPoint, True)
    debug_file.write("\n")

    debug_file.write("Lower   = ")
    write_point(debug_file, root_finder_data.LowerPoint, False)
    debug_file.write("\n")

    debug_file.write("Upper   = ")
    write_point(debug_file, root_finder_data.UpperPoint, False)
    debug_file.write("\n")

    debug_file.write("Max     = ")
    write_point(debug_file, root_finder_data.MaxPoint, True)
    debug_file.write("\n")

def write_root_finder_status(file: InputOutputFile,
                             root_finder_data: RootFinderDataType) -> None:
    if root_finder_data.StatusFlag == RootFinderStatus.OK:
        file.write("Found unconstrained root\n")
    elif root_finder_data.StatusFlag == RootFinderStatus.OKMin:
        file.write("Found min constrained root\n")
    elif root_finder_data.StatusFlag == RootFinderStatus.OKMax:
        file.write("Found max constrained root\n")
    elif root_finder_data.StatusFlag == RootFinderStatus.OKRoundOff:
        file.write("Detected round-off convergence in bracket\n")
    elif root_finder_data.StatusFlag == RootFinderStatus.WarningSingular:
        file.write("Detected singularity warning\n")
    elif root_finder_data.StatusFlag == RootFinderStatus.WarningNonMonotonic:
        file.write("Detected non-monotonicity warning\n")
    elif root_finder_data.StatusFlag == RootFinderStatus.ErrorRange:
        file.write("Detected out-of-range error\n")
    elif root_finder_data.StatusFlag == RootFinderStatus.ErrorBracket:
        file.write("Detected bracket error\n")
    elif root_finder_data.StatusFlag == RootFinderStatus.ErrorSlope:
        file.write("Detected slope error\n")
    elif root_finder_data.StatusFlag == RootFinderStatus.ErrorSingular:
        file.write("Detected singularity error\n")
    else:
        file.write("Detected bad root finder status\n")

def show_severe_error(state: EnergyPlusData, msg: str) -> None:
    print(f"SEVERE: {msg}")

def show_continue_error(state: EnergyPlusData, msg: str) -> None:
    print(f"  {msg}")

def show_fatal_error(state: EnergyPlusData, msg: str) -> None:
    print(f"FATAL: {msg}")
    raise RuntimeError(msg)
