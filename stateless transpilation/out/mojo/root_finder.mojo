from enum import Enum
from math import fabs

@value
struct Slope:
    alias Increasing = 1
    alias Decreasing = 2

@value
struct RootFinderMethod:
    alias None_ = 0
    alias Bisection = 1
    alias FalsePosition = 2
    alias Secant = 3
    alias Brent = 4
    alias Bracket = 5

@value
struct RootFinderStatus:
    alias None_ = 0
    alias OK = 1
    alias OKMin = 2
    alias OKMax = 3
    alias OKRoundOff = 4
    alias WarningSingular = 5
    alias WarningNonMonotonic = 6
    alias ErrorRange = 7
    alias ErrorBracket = 8
    alias ErrorSlope = 9
    alias ErrorSingular = 10

@value
struct PointType:
    var X: Float64
    var Y: Float64
    var DefinedFlag: Bool

    fn __init__() -> Self:
        return Self{X: 0.0, Y: 0.0, DefinedFlag: False}

@value
struct Controls:
    var SlopeType: Int
    var MethodType: Int
    var TolX: Float64
    var ATolX: Float64
    var ATolY: Float64

    fn __init__() -> Self:
        return Self{
            SlopeType: Slope.Increasing,
            MethodType: RootFinderMethod.None_,
            TolX: 0.0,
            ATolX: 0.0,
            ATolY: 0.0
        }

@value
struct RootFinderDataType:
    var MinPoint: PointType
    var MaxPoint: PointType
    var LowerPoint: PointType
    var UpperPoint: PointType
    var CurrentPoint: PointType
    var History: InlineArray[PointType, 3]
    var NumHistory: Int
    var Controls: Controls
    var Increment: PointType
    var XCandidate: Float64
    var StatusFlag: Int
    var CurrentMethodType: Int
    var ConvergenceRate: Float64

    fn __init__() -> Self:
        var history = InlineArray[PointType, 3](fill=PointType())
        return Self{
            MinPoint: PointType(),
            MaxPoint: PointType(),
            LowerPoint: PointType(),
            UpperPoint: PointType(),
            CurrentPoint: PointType(),
            History: history,
            NumHistory: 0,
            Controls: Controls(),
            Increment: PointType(),
            XCandidate: 0.0,
            StatusFlag: RootFinderStatus.None_,
            CurrentMethodType: RootFinderMethod.None_,
            ConvergenceRate: -1.0
        }

struct InputOutputFile:
    pass

struct EnergyPlusData:
    pass

fn show_severe_error(state: EnergyPlusData, msg: StringLiteral) -> None:
    print(f"SEVERE: {msg}")

fn show_continue_error(state: EnergyPlusData, msg: StringLiteral) -> None:
    print(f"  {msg}")

fn show_fatal_error(state: EnergyPlusData, msg: StringLiteral) -> None:
    print(f"FATAL: {msg}")

fn setup_root_finder(
    state: EnergyPlusData,
    inout root_finder_data: RootFinderDataType,
    slope_type: Int,
    method_type: Int,
    tol_x: Float64,
    atol_x: Float64,
    atol_y: Float64
) -> None:
    if slope_type != Slope.Increasing and slope_type != Slope.Decreasing:
        show_severe_error(state, "SetupRootFinder: Invalid function slope specification. Valid choices are:")
        show_continue_error(state, "SetupRootFinder: Slope::Increasing=1")
        show_continue_error(state, "SetupRootFinder: Slope::Decreasing=2")
        show_fatal_error(state, "SetupRootFinder: Preceding error causes program termination.")
    root_finder_data.Controls.SlopeType = slope_type

    if (method_type != RootFinderMethod.Bisection and method_type != RootFinderMethod.FalsePosition and
        method_type != RootFinderMethod.Secant and method_type != RootFinderMethod.Brent):
        show_severe_error(state, "SetupRootFinder: Invalid solution method specification. Valid choices are:")
        show_continue_error(state, "SetupRootFinder: iMethodBisection=1")
        show_continue_error(state, "SetupRootFinder: iMethodFalsePosition=2")
        show_continue_error(state, "SetupRootFinder: iMethodSecant=3")
        show_continue_error(state, "SetupRootFinder: iMethodBrent=4")
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

    reset_root_finder(inout root_finder_data, 0.0, 0.0)

fn reset_root_finder(inout root_finder_data: RootFinderDataType, x_min: Float64, x_max: Float64) -> None:
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
    for i in range(3):
        root_finder_data.History[i].X = 0.0
        root_finder_data.History[i].Y = 0.0
        root_finder_data.History[i].DefinedFlag = False

    root_finder_data.Increment.X = 0.0
    root_finder_data.Increment.Y = 0.0
    root_finder_data.Increment.DefinedFlag = False

    root_finder_data.XCandidate = 0.0

    root_finder_data.StatusFlag = RootFinderStatus.None_
    root_finder_data.CurrentMethodType = RootFinderMethod.None_
    root_finder_data.ConvergenceRate = -1.0

fn initialize_root_finder(
    state: EnergyPlusData,
    inout root_finder_data: RootFinderDataType,
    x_min: Float64,
    x_max: Float64
) -> None:
    var x_min_reset = x_min
    if x_min > x_max:
        if x_max == 0.0:
            x_min_reset = x_max
        else:
            show_fatal_error(state, "InitializeRootFinder: Invalid min/max bounds")

    var saved_x_candidate = root_finder_data.XCandidate
    reset_root_finder(inout root_finder_data, x_min_reset, x_max)
    root_finder_data.XCandidate = min(root_finder_data.MaxPoint.X, max(saved_x_candidate, root_finder_data.MinPoint.X))

fn iterate_root_finder(
    state: EnergyPlusData,
    inout root_finder_data: RootFinderDataType,
    x: Float64,
    y: Float64,
    inout is_done_flag: Bool
) -> None:
    root_finder_data.StatusFlag = RootFinderStatus.None_

    if not check_min_max_range(root_finder_data, x):
        root_finder_data.StatusFlag = RootFinderStatus.ErrorRange
        is_done_flag = True
        return

    update_min_max(inout root_finder_data, x, y)

    if root_finder_data.MinPoint.DefinedFlag and root_finder_data.MaxPoint.DefinedFlag:
        if root_finder_data.MinPoint.X == root_finder_data.MaxPoint.X:
            root_finder_data.StatusFlag = RootFinderStatus.OKMin
            root_finder_data.XCandidate = root_finder_data.MinPoint.X
            is_done_flag = True
            return

        if check_min_constraint(state, root_finder_data):
            root_finder_data.StatusFlag = RootFinderStatus.OKMin
            root_finder_data.XCandidate = root_finder_data.MinPoint.X
            is_done_flag = True
            return

        if not check_non_singularity(root_finder_data):
            root_finder_data.StatusFlag = RootFinderStatus.ErrorSingular
            is_done_flag = True
            return

        if not check_slope(state, root_finder_data):
            root_finder_data.StatusFlag = RootFinderStatus.ErrorSlope
            is_done_flag = True
            return

    if root_finder_data.MinPoint.DefinedFlag:
        if check_min_constraint(state, root_finder_data):
            root_finder_data.StatusFlag = RootFinderStatus.OKMin
            root_finder_data.XCandidate = root_finder_data.MinPoint.X
            is_done_flag = True
            return

    if root_finder_data.MaxPoint.DefinedFlag:
        if check_max_constraint(state, root_finder_data):
            root_finder_data.StatusFlag = RootFinderStatus.OKMax
            root_finder_data.XCandidate = root_finder_data.MaxPoint.X
            is_done_flag = True
            return

    if check_root_finder_convergence(root_finder_data, y):
        root_finder_data.StatusFlag = RootFinderStatus.OK
        root_finder_data.XCandidate = x
        update_root_finder(state, inout root_finder_data, x, y)
        is_done_flag = True
        return

    if check_bracket_round_off(root_finder_data):
        root_finder_data.StatusFlag = RootFinderStatus.OKRoundOff
        is_done_flag = True
        return

    if not check_lower_upper_bracket(root_finder_data, x):
        root_finder_data.StatusFlag = RootFinderStatus.ErrorBracket
        is_done_flag = True
        return

    update_root_finder(state, inout root_finder_data, x, y)
    advance_root_finder(state, inout root_finder_data)
    is_done_flag = False

fn check_internal_consistency(state: EnergyPlusData, root_finder_data: RootFinderDataType) -> Int:
    var status = RootFinderStatus.None_

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
            show_severe_error(state, "CheckInternalConsistency: Invalid function slope specification.")
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
            show_severe_error(state, "CheckInternalConsistency: Invalid function slope specification.")
            show_fatal_error(state, "CheckInternalConsistency: Preceding error causes program termination.")

    if root_finder_data.MaxPoint.DefinedFlag:
        if root_finder_data.Controls.SlopeType == Slope.Increasing:
            if root_finder_data.MaxPoint.Y <= 0.0:
                return RootFinderStatus.OKMax
        elif root_finder_data.Controls.SlopeType == Slope.Decreasing:
            if root_finder_data.MaxPoint.Y >= 0.0:
                return RootFinderStatus.OKMax
        else:
            show_severe_error(state, "CheckInternalConsistency: Invalid function slope specification.")
            show_fatal_error(state, "CheckInternalConsistency: Preceding error causes program termination.")

    return status

fn check_root_finder_candidate(root_finder_data: RootFinderDataType, x: Float64) -> Bool:
    return check_min_max_range(root_finder_data, x) and check_lower_upper_bracket(root_finder_data, x)

fn check_min_max_range(root_finder_data: RootFinderDataType, x: Float64) -> Bool:
    if root_finder_data.MinPoint.DefinedFlag:
        if x < root_finder_data.MinPoint.X:
            return False

    if root_finder_data.MaxPoint.DefinedFlag:
        if x > root_finder_data.MaxPoint.X:
            return False

    return True

fn check_lower_upper_bracket(root_finder_data: RootFinderDataType, x: Float64) -> Bool:
    if root_finder_data.LowerPoint.DefinedFlag:
        if x < root_finder_data.LowerPoint.X:
            return False

    if root_finder_data.UpperPoint.DefinedFlag:
        if x > root_finder_data.UpperPoint.X:
            return False

    return True

fn check_slope(state: EnergyPlusData, root_finder_data: RootFinderDataType) -> Bool:
    if root_finder_data.Controls.SlopeType == Slope.Increasing:
        if root_finder_data.MinPoint.Y < root_finder_data.MaxPoint.Y:
            return True
    elif root_finder_data.Controls.SlopeType == Slope.Decreasing:
        if root_finder_data.MinPoint.Y > root_finder_data.MaxPoint.Y:
            return True
    else:
        show_severe_error(state, "CheckSlope: Invalid function slope specification.")
        show_fatal_error(state, "CheckSlope: Preceding error causes program termination.")

    return False

fn check_non_singularity(root_finder_data: RootFinderDataType) -> Bool:
    let SafetyFactor = 0.1
    let DeltaY = fabs(root_finder_data.MinPoint.Y - root_finder_data.MaxPoint.Y)
    let ATolY = SafetyFactor * root_finder_data.Controls.ATolY

    if fabs(DeltaY) <= ATolY:
        return False
    else:
        return True

fn check_min_constraint(state: EnergyPlusData, root_finder_data: RootFinderDataType) -> Bool:
    if root_finder_data.Controls.SlopeType == Slope.Increasing:
        if root_finder_data.MinPoint.Y >= 0.0:
            return True
    elif root_finder_data.Controls.SlopeType == Slope.Decreasing:
        if root_finder_data.MinPoint.Y <= 0.0:
            return True
    else:
        show_severe_error(state, "CheckMinConstraint: Invalid function slope specification.")
        show_fatal_error(state, "CheckMinConstraint: Preceding error causes program termination.")

    return False

fn check_max_constraint(state: EnergyPlusData, root_finder_data: RootFinderDataType) -> Bool:
    if root_finder_data.Controls.SlopeType == Slope.Increasing:
        if root_finder_data.MaxPoint.Y <= 0.0:
            return True
    elif root_finder_data.Controls.SlopeType == Slope.Decreasing:
        if root_finder_data.MaxPoint.Y >= 0.0:
            return True
    else:
        show_severe_error(state, "CheckMaxConstraint: Invalid function slope specification.")
        show_fatal_error(state, "CheckMaxConstraint: Preceding error causes program termination.")

    return False

fn check_root_finder_convergence(root_finder_data: RootFinderDataType, y: Float64) -> Bool:
    if fabs(y) <= root_finder_data.Controls.ATolY:
        return True

    return False

fn check_bracket_round_off(root_finder_data: RootFinderDataType) -> Bool:
    if root_finder_data.LowerPoint.DefinedFlag and root_finder_data.UpperPoint.DefinedFlag:
        let DeltaUL = root_finder_data.UpperPoint.X - root_finder_data.LowerPoint.X
        let TypUL = (fabs(root_finder_data.UpperPoint.X) + fabs(root_finder_data.LowerPoint.X)) / 2.0
        let TolUL = root_finder_data.Controls.TolX * fabs(TypUL) + root_finder_data.Controls.ATolX

        if fabs(DeltaUL) <= 0.5 * fabs(TolUL):
            return True

    return False

fn update_min_max(inout root_finder_data: RootFinderDataType, x: Float64, y: Float64) -> None:
    if x == root_finder_data.MinPoint.X:
        root_finder_data.MinPoint.Y = y
        root_finder_data.MinPoint.DefinedFlag = True

    if x == root_finder_data.MaxPoint.X:
        root_finder_data.MaxPoint.Y = y
        root_finder_data.MaxPoint.DefinedFlag = True

fn update_bracket(state: EnergyPlusData, inout root_finder_data: RootFinderDataType, x: Float64, y: Float64) -> None:
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
                    show_fatal_error(state, "UpdateBracket: Preceding error causes program termination.")
    else:
        show_severe_error(state, "UpdateBracket: Invalid function slope specification.")
        show_fatal_error(state, "UpdateBracket: Preceding error causes program termination.")

fn update_history(inout root_finder_data: RootFinderDataType, x: Float64, y: Float64) -> None:
    for i in range(3):
        root_finder_data.History[i].X = 0.0
        root_finder_data.History[i].Y = 0.0
        root_finder_data.History[i].DefinedFlag = False

    var num_history = 0
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
    sort_history(num_history, inout root_finder_data.History)

fn update_root_finder(state: EnergyPlusData, inout root_finder_data: RootFinderDataType, x: Float64, y: Float64) -> None:
    update_history(inout root_finder_data, x, y)
    update_bracket(state, inout root_finder_data, x, y)

    if root_finder_data.CurrentPoint.DefinedFlag:
        root_finder_data.Increment.DefinedFlag = True
        root_finder_data.Increment.X = x - root_finder_data.CurrentPoint.X
        root_finder_data.Increment.Y = y - root_finder_data.CurrentPoint.Y

        if fabs(root_finder_data.CurrentPoint.Y) > 0.0:
            root_finder_data.ConvergenceRate = fabs(y) / fabs(root_finder_data.CurrentPoint.Y)
        else:
            root_finder_data.ConvergenceRate = -1.0

    root_finder_data.CurrentPoint.DefinedFlag = True
    root_finder_data.CurrentPoint.X = x
    root_finder_data.CurrentPoint.Y = y

fn sort_history(n: Int, inout history: InlineArray[PointType, 3]) -> None:
    if n <= 1:
        return

    for i in range(n - 1):
        for j in range(i + 1, n):
            if history[j].DefinedFlag:
                if fabs(history[j].Y) < fabs(history[i].Y):
                    let x_temp = history[i].X
                    let y_temp = history[i].Y
                    history[i].X = history[j].X
                    history[i].Y = history[j].Y
                    history[j].X = x_temp
                    history[j].Y = y_temp

fn advance_root_finder(state: EnergyPlusData, inout root_finder_data: RootFinderDataType) -> None:
    if not root_finder_data.LowerPoint.DefinedFlag:
        root_finder_data.CurrentMethodType = RootFinderMethod.Bracket
        var x_next: Float64 = 0.0
        if bracket_root(root_finder_data, inout x_next):
            root_finder_data.XCandidate = x_next
        else:
            if root_finder_data.MinPoint.DefinedFlag:
                root_finder_data.XCandidate = root_finder_data.MinPoint.X
            else:
                show_fatal_error(state, "AdvanceRootFinder: Cannot find lower bracket.")

    elif not root_finder_data.UpperPoint.DefinedFlag:
        root_finder_data.CurrentMethodType = RootFinderMethod.Bracket
        var x_next: Float64 = 0.0
        if bracket_root(root_finder_data, inout x_next):
            root_finder_data.XCandidate = x_next
        else:
            if root_finder_data.MaxPoint.DefinedFlag:
                root_finder_data.XCandidate = root_finder_data.MaxPoint.X
            else:
                show_fatal_error(state, "AdvanceRootFinder: Cannot find upper bracket.")

    else:
        if root_finder_data.StatusFlag == RootFinderStatus.OKRoundOff:
            root_finder_data.XCandidate = bisection_method(inout root_finder_data)
        elif root_finder_data.StatusFlag == RootFinderStatus.WarningSingular or root_finder_data.StatusFlag == RootFinderStatus.WarningNonMonotonic:
            root_finder_data.XCandidate = false_position_method(inout root_finder_data)
        else:
            if root_finder_data.Controls.MethodType == RootFinderMethod.Bisection:
                root_finder_data.XCandidate = bisection_method(inout root_finder_data)
            elif root_finder_data.Controls.MethodType == RootFinderMethod.FalsePosition:
                root_finder_data.XCandidate = false_position_method(inout root_finder_data)
            elif root_finder_data.Controls.MethodType == RootFinderMethod.Secant:
                root_finder_data.XCandidate = secant_method(inout root_finder_data)
            elif root_finder_data.Controls.MethodType == RootFinderMethod.Brent:
                root_finder_data.XCandidate = brent_method(inout root_finder_data)
            else:
                show_severe_error(state, "AdvanceRootFinder: Invalid solution method specification.")
                show_fatal_error(state, "AdvanceRootFinder: Preceding error causes program termination.")

fn bracket_root(root_finder_data: RootFinderDataType, inout x_next: Float64) -> Bool:
    if root_finder_data.NumHistory != 2:
        return False

    if root_finder_data.StatusFlag == RootFinderStatus.WarningSingular or root_finder_data.StatusFlag == RootFinderStatus.WarningNonMonotonic:
        return False

    if secant_formula(root_finder_data, inout x_next):
        if check_root_finder_candidate(root_finder_data, x_next):
            return True

    return False

fn bisection_method(inout root_finder_data: RootFinderDataType) -> Float64:
    root_finder_data.CurrentMethodType = RootFinderMethod.Bisection
    return (root_finder_data.LowerPoint.X + root_finder_data.UpperPoint.X) / 2.0

fn false_position_method(inout root_finder_data: RootFinderDataType) -> Float64:
    let Num = root_finder_data.UpperPoint.X - root_finder_data.LowerPoint.X
    let Den = root_finder_data.UpperPoint.Y - root_finder_data.LowerPoint.Y

    var x_candidate: Float64
    if Den != 0.0:
        root_finder_data.CurrentMethodType = RootFinderMethod.FalsePosition
        x_candidate = root_finder_data.LowerPoint.X - root_finder_data.LowerPoint.Y * Num / Den

        if not check_root_finder_candidate(root_finder_data, x_candidate):
            x_candidate = bisection_method(inout root_finder_data)
    else:
        x_candidate = bisection_method(inout root_finder_data)

    return x_candidate

fn secant_method(inout root_finder_data: RootFinderDataType) -> Float64:
    var x_candidate: Float64
    var x_next: Float64 = 0.0
    if secant_formula(root_finder_data, inout x_next):
        root_finder_data.CurrentMethodType = RootFinderMethod.Secant
        x_candidate = x_next

        if not check_root_finder_candidate(root_finder_data, x_candidate):
            x_candidate = false_position_method(inout root_finder_data)
    else:
        x_candidate = false_position_method(inout root_finder_data)

    return x_candidate

fn secant_formula(root_finder_data: RootFinderDataType, inout x_next: Float64) -> Bool:
    let Num = root_finder_data.Increment.X
    let Den = root_finder_data.Increment.Y

    if Den != 0.0 and Num != 0.0:
        x_next = root_finder_data.CurrentPoint.X - root_finder_data.CurrentPoint.Y * Num / Den
        return True
    else:
        return False

fn brent_method(inout root_finder_data: RootFinderDataType) -> Float64:
    if root_finder_data.NumHistory == 3:
        let A = root_finder_data.History[1].X
        let FA = root_finder_data.History[1].Y
        let B = root_finder_data.History[0].X
        let FB = root_finder_data.History[0].Y
        let C = root_finder_data.History[2].X
        let FC = root_finder_data.History[2].Y

        if FC == 0.0:
            return C
        if FA == 0.0:
            return A

        let R = FB / FC
        let S = FB / FA
        let T = FA / FC

        let P = S * (T * (R - T) * (C - B) - (1.0 - R) * (B - A))
        let Q = (T - 1.0) * (R - 1.0) * (S - 1.0)

        var x_candidate: Float64
        if fabs(P) <= 0.75 * fabs(Q * root_finder_data.Increment.X):
            root_finder_data.CurrentMethodType = RootFinderMethod.Brent
            x_candidate = B + P / Q

            if not check_root_finder_candidate(root_finder_data, x_candidate):
                x_candidate = false_position_method(inout root_finder_data)
        else:
            x_candidate = bisection_method(inout root_finder_data)

        return x_candidate
    else:
        return secant_method(inout root_finder_data)

fn write_root_finder_trace_header(inout trace_file: InputOutputFile) -> None:
    pass

fn write_root_finder_trace(inout trace_file: InputOutputFile, root_finder_data: RootFinderDataType) -> None:
    pass

fn write_point(inout trace_file: InputOutputFile, point_data: PointType, show_x_value: Bool) -> None:
    pass

fn debug_root_finder(inout debug_file: InputOutputFile, root_finder_data: RootFinderDataType) -> None:
    pass

fn write_root_finder_status(inout file: InputOutputFile, root_finder_data: RootFinderDataType) -> None:
    if root_finder_data.StatusFlag == RootFinderStatus.OK:
        pass
    elif root_finder_data.StatusFlag == RootFinderStatus.OKMin:
        pass
    elif root_finder_data.StatusFlag == RootFinderStatus.OKMax:
        pass
    elif root_finder_data.StatusFlag == RootFinderStatus.OKRoundOff:
        pass
    elif root_finder_data.StatusFlag == RootFinderStatus.WarningSingular:
        pass
    elif root_finder_data.StatusFlag == RootFinderStatus.WarningNonMonotonic:
        pass
    elif root_finder_data.StatusFlag == RootFinderStatus.ErrorRange:
        pass
    elif root_finder_data.StatusFlag == RootFinderStatus.ErrorBracket:
        pass
    elif root_finder_data.StatusFlag == RootFinderStatus.ErrorSlope:
        pass
    elif root_finder_data.StatusFlag == RootFinderStatus.ErrorSingular:
        pass
