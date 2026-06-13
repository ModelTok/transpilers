// Original C++ file: src/EnergyPlus/RootFinder.cc
// This is a 1:1 faithful translation to Mojo, no refactoring.

from DataRootFinder import PointType, RootFinderDataType, Slope, RootFinderMethod, RootFinderStatus
from .Data.EnergyPlusData import EnergyPlusData
from DataPrecisionGlobals import constant_zero
from UtilityRoutines import ShowSevereError, ShowContinueError, ShowFatalError
from IOFiles import InputOutputFile
from math import abs as math_abs

def SetupRootFinder(
    state: EnergyPlusData,
    RootFinderData: RootFinderDataType,                # Data used by root finding algorithm
    SlopeType: Slope,                                  # Either Slope::Increasing or Slope::Decreasing
    MethodType: RootFinderMethod,                      # Any of the iMethod<name> code but iMethodNone
    TolX: Real64,                                      # Relative tolerance for X variables
    ATolX: Real64,                                     # Absolute tolerance for X variables
    ATolY: Real64                                      # Absolute tolerance for Y variables
):
    if SlopeType != Slope.Increasing and SlopeType != Slope.Decreasing:
        ShowSevereError(state, "SetupRootFinder: Invalid function slope specification. Valid choices are:")
        ShowContinueError(state, f"SetupRootFinder: Slope::Increasing={int(Slope.Increasing)}")
        ShowContinueError(state, f"SetupRootFinder: Slope::Decreasing={int(Slope.Decreasing)}")
        ShowFatalError(state, "SetupRootFinder: Preceding error causes program termination.")

    RootFinderData.Controls.SlopeType = SlopeType

    if (MethodType != RootFinderMethod.Bisection and
        MethodType != RootFinderMethod.FalsePosition and
        MethodType != RootFinderMethod.Secant and
        MethodType != RootFinderMethod.Brent):
        ShowSevereError(state, "SetupRootFinder: Invalid solution method specification. Valid choices are:")
        ShowContinueError(state, f"SetupRootFinder: iMethodBisection={int(RootFinderMethod.Bisection)}")
        ShowContinueError(state, f"SetupRootFinder: iMethodFalsePosition={int(RootFinderMethod.FalsePosition)}")
        ShowContinueError(state, f"SetupRootFinder: iMethodSecant={int(RootFinderMethod.Secant)}")
        ShowContinueError(state, f"SetupRootFinder: iMethodBrent={int(RootFinderMethod.Brent)}")
        ShowFatalError(state, "SetupRootFinder: Preceding error causes program termination.")

    RootFinderData.Controls.MethodType = MethodType

    if TolX < 0.0:
        ShowFatalError(state, "SetupRootFinder: Invalid tolerance specification for X variables. TolX >= 0")
    RootFinderData.Controls.TolX = TolX

    if ATolX < 0.0:
        ShowFatalError(state, "SetupRootFinder: Invalid absolute tolerance specification for X variables. ATolX >= 0")
    RootFinderData.Controls.ATolX = ATolX

    if ATolY < 0.0:
        ShowFatalError(state, "SetupRootFinder: Invalid absolute tolerance specification for Y variables. ATolY >= 0")
    RootFinderData.Controls.ATolY = ATolY

    ResetRootFinder(RootFinderData, constant_zero, constant_zero)


def ResetRootFinder(
    RootFinderData: RootFinderDataType, # Data used by root finding algorithm
    XMin: Real64,                       # Minimum X value allowed
    XMax: Real64                        # Maximum X value allowed
):
    RootFinderData.MinPoint.X = XMin
    RootFinderData.MinPoint.Y = 0.0
    RootFinderData.MinPoint.DefinedFlag = False
    RootFinderData.MaxPoint.X = XMax
    RootFinderData.MaxPoint.Y = 0.0
    RootFinderData.MaxPoint.DefinedFlag = False
    RootFinderData.LowerPoint.X = 0.0
    RootFinderData.LowerPoint.Y = 0.0
    RootFinderData.LowerPoint.DefinedFlag = False
    RootFinderData.UpperPoint.X = 0.0
    RootFinderData.UpperPoint.Y = 0.0
    RootFinderData.UpperPoint.DefinedFlag = False
    RootFinderData.CurrentPoint.X = 0.0
    RootFinderData.CurrentPoint.Y = 0.0
    RootFinderData.CurrentPoint.DefinedFlag = False
    RootFinderData.NumHistory = 0
    for i in range(len(RootFinderData.History)):
        var e = RootFinderData.History[i]
        e.X = e.Y = 0.0
        e.DefinedFlag = False
    RootFinderData.Increment.X = 0.0
    RootFinderData.Increment.Y = 0.0
    RootFinderData.Increment.DefinedFlag = False
    RootFinderData.XCandidate = 0.0
    RootFinderData.StatusFlag = RootFinderStatus.None
    RootFinderData.CurrentMethodType = RootFinderMethod.None
    RootFinderData.ConvergenceRate = -1.0


def InitializeRootFinder(
    state: EnergyPlusData,
    RootFinderData: RootFinderDataType, # Data used by root finding algorithm
    XMin: Real64,                       # Minimum X value allowed
    XMax: Real64                        # Maximum X value allowed
):
    var SavedXCandidate: Real64
    var XMinReset: Real64
    XMinReset = XMin
    if XMin > XMax:
        if XMax == 0.0:
            XMinReset = XMax
        else:
            ShowFatalError(state,
                           f"InitializeRootFinder: Invalid min/max bounds XMin={XMin:.6f} must be smaller than XMax={XMax:.6f}")
    SavedXCandidate = RootFinderData.XCandidate
    ResetRootFinder(RootFinderData, XMinReset, XMax)
    RootFinderData.XCandidate = min(RootFinderData.MaxPoint.X, max(SavedXCandidate, RootFinderData.MinPoint.X))


def IterateRootFinder(
    state: EnergyPlusData,
    RootFinderData: RootFinderDataType, # Data used by root finding algorithm
    X: Real64,                          # X value of current iterate
    Y: Real64,                          # Y value of current iterate
    inout IsDoneFlag: Bool              # If TRUE indicates that the iteration should be stopped
):
    RootFinderData.StatusFlag = RootFinderStatus.None
    if not CheckMinMaxRange(RootFinderData, X):
        RootFinderData.StatusFlag = RootFinderStatus.ErrorRange
        IsDoneFlag = True
        return
    UpdateMinMax(RootFinderData, X, Y)
    if RootFinderData.MinPoint.DefinedFlag and RootFinderData.MaxPoint.DefinedFlag:
        if RootFinderData.MinPoint.X == RootFinderData.MaxPoint.X:
            RootFinderData.StatusFlag = RootFinderStatus.OKMin
            RootFinderData.XCandidate = RootFinderData.MinPoint.X
            IsDoneFlag = True
            return
        if CheckMinConstraint(state, RootFinderData):
            RootFinderData.StatusFlag = RootFinderStatus.OKMin
            RootFinderData.XCandidate = RootFinderData.MinPoint.X
            IsDoneFlag = True
            return
        if not CheckNonSingularity(RootFinderData):
            RootFinderData.StatusFlag = RootFinderStatus.ErrorSingular
            IsDoneFlag = True
            return
        if not CheckSlope(state, RootFinderData):
            RootFinderData.StatusFlag = RootFinderStatus.ErrorSlope
            IsDoneFlag = True
            return
    if RootFinderData.MinPoint.DefinedFlag:
        if CheckMinConstraint(state, RootFinderData):
            RootFinderData.StatusFlag = RootFinderStatus.OKMin
            RootFinderData.XCandidate = RootFinderData.MinPoint.X
            IsDoneFlag = True
            return
    if RootFinderData.MaxPoint.DefinedFlag:
        if CheckMaxConstraint(state, RootFinderData):
            RootFinderData.StatusFlag = RootFinderStatus.OKMax
            RootFinderData.XCandidate = RootFinderData.MaxPoint.X
            IsDoneFlag = True
            return
    if CheckRootFinderConvergence(RootFinderData, Y):
        RootFinderData.StatusFlag = RootFinderStatus.OK
        RootFinderData.XCandidate = X
        UpdateRootFinder(state, RootFinderData, X, Y)
        IsDoneFlag = True
        return
    if CheckBracketRoundOff(RootFinderData):
        RootFinderData.StatusFlag = RootFinderStatus.OKRoundOff
        IsDoneFlag = True
        return
    if not CheckLowerUpperBracket(RootFinderData, X):
        RootFinderData.StatusFlag = RootFinderStatus.ErrorBracket
        IsDoneFlag = True
        return
    UpdateRootFinder(state, RootFinderData, X, Y)
    AdvanceRootFinder(state, RootFinderData)
    IsDoneFlag = False


def CheckInternalConsistency(
    state: EnergyPlusData,
    RootFinderData: RootFinderDataType # Data used by root finding algorithm
) -> RootFinderStatus:
    var CheckInternalConsistency_result: RootFinderStatus
    CheckInternalConsistency_result = RootFinderStatus.None
    if RootFinderData.LowerPoint.DefinedFlag and RootFinderData.UpperPoint.DefinedFlag:
        if RootFinderData.LowerPoint.X > RootFinderData.UpperPoint.X:
            CheckInternalConsistency_result = RootFinderStatus.ErrorRange
            return CheckInternalConsistency_result
        match RootFinderData.Controls.SlopeType:
            case Slope.Increasing:
                if RootFinderData.LowerPoint.Y > RootFinderData.UpperPoint.Y:
                    CheckInternalConsistency_result = RootFinderStatus.WarningNonMonotonic
                    return CheckInternalConsistency_result
            case Slope.Decreasing:
                if RootFinderData.LowerPoint.Y < RootFinderData.UpperPoint.Y:
                    CheckInternalConsistency_result = RootFinderStatus.WarningNonMonotonic
                    return CheckInternalConsistency_result
            case _:
                ShowSevereError(state, "CheckInternalConsistency: Invalid function slope specification. Valid choices are:")
                ShowContinueError(state, f"CheckInternalConsistency: Slope::Increasing={int(Slope.Increasing)}")
                ShowContinueError(state, f"CheckInternalConsistency: Slope::Decreasing={int(Slope.Decreasing)}")
                ShowFatalError(state, "CheckInternalConsistency: Preceding error causes program termination.")
        if RootFinderData.UpperPoint.X > RootFinderData.LowerPoint.X:
            if RootFinderData.UpperPoint.Y == RootFinderData.LowerPoint.Y:
                CheckInternalConsistency_result = RootFinderStatus.ErrorSingular
                return CheckInternalConsistency_result
    if RootFinderData.MinPoint.DefinedFlag:
        match RootFinderData.Controls.SlopeType:
            case Slope.Increasing:
                if RootFinderData.MinPoint.Y >= 0.0:
                    CheckInternalConsistency_result = RootFinderStatus.OKMin
                    return CheckInternalConsistency_result
            case Slope.Decreasing:
                if RootFinderData.MinPoint.Y <= 0.0:
                    CheckInternalConsistency_result = RootFinderStatus.OKMin
                    return CheckInternalConsistency_result
            case _:
                ShowSevereError(state, "CheckInternalConsistency: Invalid function slope specification. Valid choices are:")
                ShowContinueError(state, f"CheckInternalConsistency: Slope::Increasing={int(Slope.Increasing)}")
                ShowContinueError(state, f"CheckInternalConsistency: Slope::Decreasing={int(Slope.Decreasing)}")
                ShowFatalError(state, "CheckInternalConsistency: Preceding error causes program termination.")
    if RootFinderData.MaxPoint.DefinedFlag:
        match RootFinderData.Controls.SlopeType:
            case Slope.Increasing:
                if RootFinderData.MaxPoint.Y <= 0.0:
                    CheckInternalConsistency_result = RootFinderStatus.OKMax
                    return CheckInternalConsistency_result
            case Slope.Decreasing:
                if RootFinderData.MaxPoint.Y >= 0.0:
                    CheckInternalConsistency_result = RootFinderStatus.OKMax
                    return CheckInternalConsistency_result
            case _:
                ShowSevereError(state, "CheckInternalConsistency: Invalid function slope specification. Valid choices are:")
                ShowContinueError(state, f"CheckInternalConsistency: Slope::Increasing={int(Slope.Increasing)}")
                ShowContinueError(state, f"CheckInternalConsistency: Slope::Decreasing={int(Slope.Decreasing)}")
                ShowFatalError(state, "CheckInternalConsistency: Preceding error causes program termination.")
    return CheckInternalConsistency_result


def CheckRootFinderCandidate(
    RootFinderData: RootFinderDataType, # Data used by root finding algorithm
    X: Real64                           # X value for current iterate
) -> Bool:
    var CheckRootFinderCandidate_result: Bool
    if CheckMinMaxRange(RootFinderData, X) and CheckLowerUpperBracket(RootFinderData, X):
        CheckRootFinderCandidate_result = True
    else:
        CheckRootFinderCandidate_result = False
    return CheckRootFinderCandidate_result


def CheckMinMaxRange(
    RootFinderData: RootFinderDataType, # Data used by root finding algorithm
    X: Real64                           # X value for current iterate
) -> Bool:
    var CheckMinMaxRange_result: Bool
    if RootFinderData.MinPoint.DefinedFlag:
        if X < RootFinderData.MinPoint.X:
            CheckMinMaxRange_result = False
            return CheckMinMaxRange_result
    if RootFinderData.MaxPoint.DefinedFlag:
        if X > RootFinderData.MaxPoint.X:
            CheckMinMaxRange_result = False
            return CheckMinMaxRange_result
    CheckMinMaxRange_result = True
    return CheckMinMaxRange_result


def CheckLowerUpperBracket(
    RootFinderData: RootFinderDataType, # Data used by root finding algorithm
    X: Real64                           # X value for current iterate
) -> Bool:
    var CheckLowerUpperBracket_result: Bool
    if RootFinderData.LowerPoint.DefinedFlag:
        if X < RootFinderData.LowerPoint.X:
            CheckLowerUpperBracket_result = False
            return CheckLowerUpperBracket_result
    if RootFinderData.UpperPoint.DefinedFlag:
        if X > RootFinderData.UpperPoint.X:
            CheckLowerUpperBracket_result = False
            return CheckLowerUpperBracket_result
    CheckLowerUpperBracket_result = True
    return CheckLowerUpperBracket_result


def CheckSlope(
    state: EnergyPlusData,
    RootFinderData: RootFinderDataType # Data used by root finding algorithm
) -> Bool:
    var CheckSlope_result: Bool
    match RootFinderData.Controls.SlopeType:
        case Slope.Increasing:
            if RootFinderData.MinPoint.Y < RootFinderData.MaxPoint.Y:
                CheckSlope_result = True
                return CheckSlope_result
        case Slope.Decreasing:
            if RootFinderData.MinPoint.Y > RootFinderData.MaxPoint.Y:
                CheckSlope_result = True
                return CheckSlope_result
        case _:
            ShowSevereError(state, "CheckSlope: Invalid function slope specification. Valid choices are:")
            ShowContinueError(state, f"CheckSlope: Slope::Increasing={int(Slope.Increasing)}")
            ShowContinueError(state, f"CheckSlope: Slope::Decreasing={int(Slope.Decreasing)}")
            ShowFatalError(state, "CheckSlope: Preceding error causes program termination.")
    CheckSlope_result = False
    return CheckSlope_result


def CheckNonSingularity(
    RootFinderData: RootFinderDataType # Data used by root finding algorithm
) -> Bool:
    # Real64 SafetyFactor(0.1);
    let SafetyFactor: Real64 = 0.1
    var CheckNonSingularity_result: Bool
    var DeltaY: Real64  # Difference between min and max Y-values
    var ATolY: Real64   # Absolute tolerance used to detected equal min and max Y-values
    DeltaY = math_abs(RootFinderData.MinPoint.Y - RootFinderData.MaxPoint.Y)
    ATolY = SafetyFactor * RootFinderData.Controls.ATolY
    if math_abs(DeltaY) <= ATolY:
        CheckNonSingularity_result = False
    else:
        CheckNonSingularity_result = True
    return CheckNonSingularity_result


def CheckMinConstraint(
    state: EnergyPlusData,
    RootFinderData: RootFinderDataType # Data used by root finding algorithm
) -> Bool:
    var CheckMinConstraint_result: Bool
    match RootFinderData.Controls.SlopeType:
        case Slope.Increasing:
            if RootFinderData.MinPoint.Y >= 0.0:
                CheckMinConstraint_result = True
                return CheckMinConstraint_result
        case Slope.Decreasing:
            if RootFinderData.MinPoint.Y <= 0.0:
                CheckMinConstraint_result = True
                return CheckMinConstraint_result
        case _:
            ShowSevereError(state, "CheckMinConstraint: Invalid function slope specification. Valid choices are:")
            ShowContinueError(state, f"CheckMinConstraint: Slope::Increasing={int(Slope.Increasing)}")
            ShowContinueError(state, f"CheckMinConstraint: Slope::Decreasing={int(Slope.Decreasing)}")
            ShowFatalError(state, "CheckMinConstraint: Preceding error causes program termination.")
    CheckMinConstraint_result = False
    return CheckMinConstraint_result


def CheckMaxConstraint(
    state: EnergyPlusData,
    RootFinderData: RootFinderDataType # Data used by root finding algorithm
) -> Bool:
    var CheckMaxConstraint_result: Bool
    match RootFinderData.Controls.SlopeType:
        case Slope.Increasing:
            if RootFinderData.MaxPoint.Y <= 0.0:
                CheckMaxConstraint_result = True
                return CheckMaxConstraint_result
        case Slope.Decreasing:
            if RootFinderData.MaxPoint.Y >= 0.0:
                CheckMaxConstraint_result = True
                return CheckMaxConstraint_result
        case _:
            ShowSevereError(state, "CheckMaxConstraint: Invalid function slope specification. Valid choices are:")
            ShowContinueError(state, f"CheckMaxConstraint: Slope::Increasing={int(Slope.Increasing)}")
            ShowContinueError(state, f"CheckMaxConstraint: Slope::Decreasing={int(Slope.Decreasing)}")
            ShowFatalError(state, "CheckMaxConstraint: Preceding error causes program termination.")
    CheckMaxConstraint_result = False
    return CheckMaxConstraint_result


def CheckRootFinderConvergence(
    RootFinderData: RootFinderDataType, # Data used by root finding algorithm
    Y: Real64                           # Y value for current iterate
) -> Bool:
    var CheckRootFinderConvergence_result: Bool
    if math_abs(Y) <= RootFinderData.Controls.ATolY:
        CheckRootFinderConvergence_result = True
        return CheckRootFinderConvergence_result
    CheckRootFinderConvergence_result = False
    return CheckRootFinderConvergence_result


def CheckBracketRoundOff(
    RootFinderData: RootFinderDataType # Data used by root finding algorithm
) -> Bool:
    var CheckBracketRoundOff_result: Bool
    var DeltaUL: Real64  # Distance between lower and upper points
    var TypUL: Real64    # Typical value for values lying within lower/upper interval
    var TolUL: Real64    # Tolerance to satisfy for lower-upper distance
    if RootFinderData.LowerPoint.DefinedFlag and RootFinderData.UpperPoint.DefinedFlag:
        DeltaUL = RootFinderData.UpperPoint.X - RootFinderData.LowerPoint.X
        TypUL = (math_abs(RootFinderData.UpperPoint.X) + math_abs(RootFinderData.LowerPoint.X)) / 2.0
        TolUL = RootFinderData.Controls.TolX * math_abs(TypUL) + RootFinderData.Controls.ATolX
        if math_abs(DeltaUL) <= 0.5 * math_abs(TolUL):
            CheckBracketRoundOff_result = True
            return CheckBracketRoundOff_result
    CheckBracketRoundOff_result = False
    return CheckBracketRoundOff_result


def UpdateMinMax(
    RootFinderData: RootFinderDataType, # Data used by root finding algorithm
    X: Real64,                          # X value for current iterate
    Y: Real64                           # Y value for current iterate, F(X)=Y
):
    if X == RootFinderData.MinPoint.X:
        RootFinderData.MinPoint.Y = Y
        RootFinderData.MinPoint.DefinedFlag = True
    if X == RootFinderData.MaxPoint.X:
        RootFinderData.MaxPoint.Y = Y
        RootFinderData.MaxPoint.DefinedFlag = True


def UpdateBracket(
    state: EnergyPlusData,
    RootFinderData: RootFinderDataType, # Data used by root finding algorithm
    X: Real64,                          # X value for current iterate
    Y: Real64                           # Y value for current iterate, F(X)=Y
):
    match RootFinderData.Controls.SlopeType:
        case Slope.Increasing:
            if Y <= 0.0:
                if not RootFinderData.LowerPoint.DefinedFlag:
                    RootFinderData.LowerPoint.DefinedFlag = True
                    RootFinderData.LowerPoint.X = X
                    RootFinderData.LowerPoint.Y = Y
                else:
                    if X >= RootFinderData.LowerPoint.X:
                        if Y == RootFinderData.LowerPoint.Y:
                            RootFinderData.StatusFlag = RootFinderStatus.WarningSingular
                        elif Y < RootFinderData.LowerPoint.Y:
                            RootFinderData.StatusFlag = RootFinderStatus.WarningNonMonotonic
                        RootFinderData.LowerPoint.X = X
                        RootFinderData.LowerPoint.Y = Y
                    else:
                        ShowSevereError(state, "UpdateBracket: Current iterate is smaller than the lower bracket.")
                        ShowContinueError(state, f"UpdateBracket: X={X:.15f}, Y={Y:.15f}")
                        ShowContinueError(state, f"UpdateBracket: XLower={RootFinderData.LowerPoint.X:.15f}, YLower={RootFinderData.LowerPoint.Y:.15f}")
                        ShowFatalError(state, "UpdateBracket: Preceding error causes program termination.")
            else:
                if not RootFinderData.UpperPoint.DefinedFlag:
                    RootFinderData.UpperPoint.DefinedFlag = True
                    RootFinderData.UpperPoint.X = X
                    RootFinderData.UpperPoint.Y = Y
                else:
                    if X <= RootFinderData.UpperPoint.X:
                        if Y == RootFinderData.UpperPoint.Y:
                            RootFinderData.StatusFlag = RootFinderStatus.WarningSingular
                        elif Y > RootFinderData.UpperPoint.Y:
                            RootFinderData.StatusFlag = RootFinderStatus.WarningNonMonotonic
                        RootFinderData.UpperPoint.X = X
                        RootFinderData.UpperPoint.Y = Y
                    else:
                        ShowSevereError(state, "UpdateBracket: Current iterate is greater than the upper bracket.")
                        ShowContinueError(state, f"UpdateBracket: X={X:.15f}, Y={Y:.15f}")
                        ShowContinueError(state, f"UpdateBracket: XUpper={RootFinderData.UpperPoint.X:.15f}, YUpper={RootFinderData.UpperPoint.Y:.15f}")
                        ShowFatalError(state, "UpdateBracket: Preceding error causes program termination.")
        case Slope.Decreasing:
            if Y >= 0.0:
                if not RootFinderData.LowerPoint.DefinedFlag:
                    RootFinderData.LowerPoint.DefinedFlag = True
                    RootFinderData.LowerPoint.X = X
                    RootFinderData.LowerPoint.Y = Y
                else:
                    if X >= RootFinderData.LowerPoint.X:
                        if Y == RootFinderData.LowerPoint.Y:
                            RootFinderData.StatusFlag = RootFinderStatus.WarningSingular
                        elif Y > RootFinderData.LowerPoint.Y:
                            RootFinderData.StatusFlag = RootFinderStatus.WarningNonMonotonic
                        RootFinderData.LowerPoint.X = X
                        RootFinderData.LowerPoint.Y = Y
                    else:
                        ShowSevereError(state, "UpdateBracket: Current iterate is smaller than the lower bracket.")
                        ShowContinueError(state, f"UpdateBracket: X={X:.15f}, Y={Y:.15f}")
                        ShowContinueError(state, f"UpdateBracket: XLower={RootFinderData.LowerPoint.X:.15f}, YLower={RootFinderData.LowerPoint.Y:.15f}")
                        ShowFatalError(state, "UpdateBracket: Preceding error causes program termination.")
            else:
                if not RootFinderData.UpperPoint.DefinedFlag:
                    RootFinderData.UpperPoint.DefinedFlag = True
                    RootFinderData.UpperPoint.X = X
                    RootFinderData.UpperPoint.Y = Y
                else:
                    if X <= RootFinderData.UpperPoint.X:
                        if Y == RootFinderData.UpperPoint.Y:
                            RootFinderData.StatusFlag = RootFinderStatus.WarningSingular
                        elif Y < RootFinderData.UpperPoint.Y:
                            RootFinderData.StatusFlag = RootFinderStatus.WarningNonMonotonic
                        RootFinderData.UpperPoint.X = X
                        RootFinderData.UpperPoint.Y = Y
                    else:
                        ShowSevereError(state, "UpdateBracket: Current iterate is greater than the upper bracket.")
                        ShowContinueError(state, f"UpdateBracket: X={X:.15f}, Y={Y:.15f}")
                        ShowContinueError(state, f"UpdateBracket: XUpper={RootFinderData.UpperPoint.X:.15f}, YUpper={RootFinderData.UpperPoint.Y:.15f}")
                        ShowFatalError(state, "UpdateBracket: Preceding error causes program termination.")
        case _:
            ShowSevereError(state, "UpdateBracket: Invalid function slope specification. Valid choices are:")
            ShowContinueError(state, f"UpdateBracket: Slope::Increasing={int(Slope.Increasing)}")
            ShowContinueError(state, f"UpdateBracket: Slope::Decreasing={int(Slope.Decreasing)}")
            ShowFatalError(state, "UpdateBracket: Preceding error causes program termination.")


def UpdateHistory(
    RootFinderData: RootFinderDataType, # Data used by root finding algorithm
    X: Real64,                          # X value for current iterate
    Y: Real64                           # Y value for current iterate, F(X)=Y
):
    var NumHistory: Int
    for i in range(len(RootFinderData.History)):
        var e = RootFinderData.History[i]
        e.X = e.Y = 0.0
        e.DefinedFlag = False
    NumHistory = 0
    if RootFinderData.LowerPoint.DefinedFlag:
        NumHistory += 1
        RootFinderData.History[NumHistory - 1].DefinedFlag = RootFinderData.LowerPoint.DefinedFlag
        RootFinderData.History[NumHistory - 1].X = RootFinderData.LowerPoint.X
        RootFinderData.History[NumHistory - 1].Y = RootFinderData.LowerPoint.Y
    if RootFinderData.UpperPoint.DefinedFlag:
        NumHistory += 1
        RootFinderData.History[NumHistory - 1].DefinedFlag = RootFinderData.UpperPoint.DefinedFlag
        RootFinderData.History[NumHistory - 1].X = RootFinderData.UpperPoint.X
        RootFinderData.History[NumHistory - 1].Y = RootFinderData.UpperPoint.Y
    NumHistory += 1
    RootFinderData.History[NumHistory - 1].DefinedFlag = True
    RootFinderData.History[NumHistory - 1].X = X
    RootFinderData.History[NumHistory - 1].Y = Y
    RootFinderData.NumHistory = NumHistory
    SortHistory(NumHistory, RootFinderData.History)


def UpdateRootFinder(
    state: EnergyPlusData,
    RootFinderData: RootFinderDataType, # Data used by root finding algorithm
    X: Real64,                          # X value for current iterate
    Y: Real64                           # Y value for current iterate, F(X)=Y
):
    UpdateHistory(RootFinderData, X, Y)
    UpdateBracket(state, RootFinderData, X, Y)
    if RootFinderData.CurrentPoint.DefinedFlag:
        RootFinderData.Increment.DefinedFlag = True
        RootFinderData.Increment.X = X - RootFinderData.CurrentPoint.X
        RootFinderData.Increment.Y = Y - RootFinderData.CurrentPoint.Y
        if math_abs(RootFinderData.CurrentPoint.Y) > 0.0:
            RootFinderData.ConvergenceRate = math_abs(Y) / math_abs(RootFinderData.CurrentPoint.Y)
        else:
            RootFinderData.ConvergenceRate = -1.0
    RootFinderData.CurrentPoint.DefinedFlag = True
    RootFinderData.CurrentPoint.X = X
    RootFinderData.CurrentPoint.Y = Y


def SortHistory(
    N: Int,                       # Number of points to sort in history array
    inout History: List[PointType] # Array of PointType variables. At least N of them
):
    var I: Int
    var J: Int
    var XTemp: Real64
    var YTemp: Real64
    if N <= 1:
        return
    for I in range(0, N - 1):  # 0-based: I from 0 to N-2
        for J in range(I + 1, N):  # J from I+1 to N-1
            if History[J].DefinedFlag:
                if math_abs(History[J].Y) < math_abs(History[I].Y):
                    XTemp = History[I].X
                    YTemp = History[I].Y
                    History[I].X = History[J].X
                    History[I].Y = History[J].Y
                    History[J].X = XTemp
                    History[J].Y = YTemp


def AdvanceRootFinder(
    state: EnergyPlusData,
    RootFinderData: RootFinderDataType # Data used by root finding algorithm
):
    # auto &XNext = state.dataGeneral->XNext;
    var XNext = state.dataGeneral.XNext  # Use direct field access
    if not RootFinderData.LowerPoint.DefinedFlag:
        RootFinderData.CurrentMethodType = RootFinderMethod.Bracket
        if BracketRoot(RootFinderData, XNext):
            RootFinderData.XCandidate = XNext
        else:
            if not RootFinderData.MinPoint.DefinedFlag:
                RootFinderData.XCandidate = RootFinderData.MinPoint.X
            else:
                ShowFatalError(state, "AdvanceRootFinder: Cannot find lower bracket.")
    elif not RootFinderData.UpperPoint.DefinedFlag:
        RootFinderData.CurrentMethodType = RootFinderMethod.Bracket
        if BracketRoot(RootFinderData, XNext):
            RootFinderData.XCandidate = XNext
        else:
            if not RootFinderData.MaxPoint.DefinedFlag:
                RootFinderData.XCandidate = RootFinderData.MaxPoint.X
            else:
                ShowFatalError(state, "AdvanceRootFinder: Cannot find upper bracket.")
    else:
        match RootFinderData.StatusFlag:
            case RootFinderStatus.OKRoundOff:
                RootFinderData.XCandidate = BisectionMethod(RootFinderData)
            case RootFinderStatus.WarningSingular:
                RootFinderData.XCandidate = FalsePositionMethod(RootFinderData)
            case RootFinderStatus.WarningNonMonotonic:
                RootFinderData.XCandidate = FalsePositionMethod(RootFinderData)
            case _:
                match RootFinderData.Controls.MethodType:
                    case RootFinderMethod.Bisection:
                        RootFinderData.XCandidate = BisectionMethod(RootFinderData)
                    case RootFinderMethod.FalsePosition:
                        RootFinderData.XCandidate = FalsePositionMethod(RootFinderData)
                    case RootFinderMethod.Secant:
                        RootFinderData.XCandidate = SecantMethod(RootFinderData)
                    case RootFinderMethod.Brent:
                        RootFinderData.XCandidate = BrentMethod(RootFinderData)
                    case _:
                        ShowSevereError(state, "AdvanceRootFinder: Invalid solution method specification. Valid choices are:")
                        ShowContinueError(state, f"AdvanceRootFinder: iMethodBisection={int(RootFinderMethod.Bisection)}")
                        ShowContinueError(state, f"AdvanceRootFinder: iMethodFalsePosition={int(RootFinderMethod.FalsePosition)}")
                        ShowContinueError(state, f"AdvanceRootFinder: iMethodSecant={int(RootFinderMethod.Secant)}")
                        ShowContinueError(state, f"AdvanceRootFinder: iMethodBrent={int(RootFinderMethod.Brent)}")
                        ShowFatalError(state, "AdvanceRootFinder: Preceding error causes program termination.")


def BracketRoot(
    RootFinderData: RootFinderDataType, # Data used by root finding algorithm
    inout XNext: Real64                 # Next value
) -> Bool:
    var BracketRoot_result: Bool
    if RootFinderData.NumHistory != 2:
        BracketRoot_result = False
        return BracketRoot_result
    if (RootFinderData.StatusFlag == RootFinderStatus.WarningSingular or
        RootFinderData.StatusFlag == RootFinderStatus.WarningNonMonotonic):
        BracketRoot_result = False
        return BracketRoot_result
    if SecantFormula(RootFinderData, XNext):
        if CheckRootFinderCandidate(RootFinderData, XNext):
            BracketRoot_result = True
            return BracketRoot_result
    BracketRoot_result = False
    return BracketRoot_result


def BisectionMethod(
    RootFinderData: RootFinderDataType # Data used by root finding algorithm
) -> Real64:
    var BisectionMethod_result: Real64
    RootFinderData.CurrentMethodType = RootFinderMethod.Bisection
    BisectionMethod_result = (RootFinderData.LowerPoint.X + RootFinderData.UpperPoint.X) / 2.0
    return BisectionMethod_result


def FalsePositionMethod(
    RootFinderData: RootFinderDataType # Data used by root finding algorithm
) -> Real64:
    var FalsePositionMethod_result: Real64
    var XCandidate: Real64
    var Num: Real64
    var Den: Real64
    Num = RootFinderData.UpperPoint.X - RootFinderData.LowerPoint.X
    Den = RootFinderData.UpperPoint.Y - RootFinderData.LowerPoint.Y
    if Den != 0.0:
        RootFinderData.CurrentMethodType = RootFinderMethod.FalsePosition
        XCandidate = RootFinderData.LowerPoint.X - RootFinderData.LowerPoint.Y * Num / Den
        if not CheckRootFinderCandidate(RootFinderData, XCandidate):
            XCandidate = BisectionMethod(RootFinderData)
    else:
        XCandidate = BisectionMethod(RootFinderData)
    FalsePositionMethod_result = XCandidate
    return FalsePositionMethod_result


def SecantMethod(
    RootFinderData: RootFinderDataType # Data used by root finding algorithm
) -> Real64:
    var SecantMethod_result: Real64
    var XCandidate: Real64
    if SecantFormula(RootFinderData, XCandidate):
        RootFinderData.CurrentMethodType = RootFinderMethod.Secant
        if not CheckRootFinderCandidate(RootFinderData, XCandidate):
            XCandidate = FalsePositionMethod(RootFinderData)
    else:
        XCandidate = FalsePositionMethod(RootFinderData)
    SecantMethod_result = XCandidate
    return SecantMethod_result


def SecantFormula(
    RootFinderData: RootFinderDataType, # Data used by root finding algorithm
    inout XNext: Real64                 # Result from Secant formula if possible to compute
) -> Bool:
    var SecantFormula_result: Bool
    var Num: Real64
    var Den: Real64
    Num = RootFinderData.Increment.X
    Den = RootFinderData.Increment.Y
    if Den != 0.0 and Num != 0.0:
        XNext = RootFinderData.CurrentPoint.X - RootFinderData.CurrentPoint.Y * Num / Den
        SecantFormula_result = True
    else:
        SecantFormula_result = False
    return SecantFormula_result


def BrentMethod(
    RootFinderData: RootFinderDataType # Data used by root finding algorithm
) -> Real64:
    var BrentMethod_result: Real64
    var XCandidate: Real64
    var A: Real64
    var FA: Real64
    var B: Real64
    var FB: Real64
    var C: Real64
    var FC: Real64
    var R: Real64
    var S: Real64
    var T: Real64
    var P: Real64
    var Q: Real64
    if RootFinderData.NumHistory == 3:
        A = RootFinderData.History[1].X   # 0-based index 1 corresponds to original index 2
        FA = RootFinderData.History[1].Y
        B = RootFinderData.History[0].X   # original index 1
        FB = RootFinderData.History[0].Y
        C = RootFinderData.History[2].X   # original index 3
        FC = RootFinderData.History[2].Y
        if FC == 0.0:
            BrentMethod_result = C
            return BrentMethod_result
        if FA == 0.0:
            BrentMethod_result = A
            return BrentMethod_result
        R = FB / FC
        S = FB / FA
        T = FA / FC
        P = S * (T * (R - T) * (C - B) - (1.0 - R) * (B - A))
        Q = (T - 1.0) * (R - 1.0) * (S - 1.0)
        if math_abs(P) <= 0.75 * math_abs(Q * RootFinderData.Increment.X):
            RootFinderData.CurrentMethodType = RootFinderMethod.Brent
            XCandidate = B + P / Q
            if not CheckRootFinderCandidate(RootFinderData, XCandidate):
                XCandidate = FalsePositionMethod(RootFinderData)
        else:
            XCandidate = BisectionMethod(RootFinderData)
    else:
        XCandidate = SecantMethod(RootFinderData)
    BrentMethod_result = XCandidate
    return BrentMethod_result


def WriteRootFinderTraceHeader(
    TraceFile: InputOutputFile # Unit for trace file
):
    TraceFile.print(
        "{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},",
        "Status",
        "Method",
        "CurrentPoint%X",
        "CurrentPoint%Y",
        "XCandidate",
        "ConvergenceRate",
        "MinPoint%X",
        "MinPoint%Y",
        "LowerPoint%X",
        "LowerPoint%Y",
        "UpperPoint%X",
        "UpperPoint%Y",
        "MaxPoint%X",
        "MaxPoint%Y",
        "History(1)%X",
        "History(1)%Y",
        "History(2)%X",
        "History(2)%Y",
        "History(3)%X",
        "History(3)%Y"
    )


def WriteRootFinderTrace(
    TraceFile: InputOutputFile,               # Unit for trace file
    RootFinderData: RootFinderDataType        # Data used by root finding algorithm
):
    TraceFile.print("{},{},", RootFinderData.StatusFlag, RootFinderData.CurrentMethodType)
    WritePoint(TraceFile, RootFinderData.CurrentPoint, False)
    TraceFile.print("{:20.10F},{:20.10F},", RootFinderData.XCandidate, RootFinderData.ConvergenceRate)
    WritePoint(TraceFile, RootFinderData.MinPoint, True)
    WritePoint(TraceFile, RootFinderData.LowerPoint, False)
    WritePoint(TraceFile, RootFinderData.UpperPoint, False)
    WritePoint(TraceFile, RootFinderData.MaxPoint, True)
    WritePoint(TraceFile, RootFinderData.History[0], False)   # 0-based index 1 -> 0
    WritePoint(TraceFile, RootFinderData.History[1], False)   # 0-based index 2 -> 1
    WritePoint(TraceFile, RootFinderData.History[2], False)   # 0-based index 3 -> 2


def WritePoint(
    TraceFile: InputOutputFile,  # Unit for trace file
    PointData: PointType,        # Point data structure
    ShowXValue: Bool
):
    if PointData.DefinedFlag:
        TraceFile.print("{:20.10F},{:20.10F},", PointData.X, PointData.Y)
    else:
        if ShowXValue:
            TraceFile.print("{:20.10F},,", PointData.X)
        else:
            TraceFile.print(",,")


def DebugRootFinder(
    DebugFile: InputOutputFile,               # File unit where to write debugging info
    RootFinderData: RootFinderDataType         # Data used by root finding algorithm
):
    DebugFile.print("Current = ")
    WritePoint(DebugFile, RootFinderData.CurrentPoint, True)
    DebugFile.print("\n")
    DebugFile.print("Min     = ")
    WritePoint(DebugFile, RootFinderData.MinPoint, True)
    DebugFile.print("\n")
    DebugFile.print("Lower   = ")
    WritePoint(DebugFile, RootFinderData.LowerPoint, False)
    DebugFile.print("\n")
    DebugFile.print("Upper   = ")
    WritePoint(DebugFile, RootFinderData.UpperPoint, False)
    DebugFile.print("\n")
    DebugFile.print("Max     = ")
    WritePoint(DebugFile, RootFinderData.MaxPoint, True)
    DebugFile.print("\n")


def WriteRootFinderStatus(
    File: InputOutputFile,                    # File unit where to write the status description
    RootFinderData: RootFinderDataType         # Data used by root finding algorithm
):
    match RootFinderData.StatusFlag:
        case RootFinderStatus.OK:
            File.print("Found unconstrained root")
        case RootFinderStatus.OKMin:
            File.print("Found min constrained root")
        case RootFinderStatus.OKMax:
            File.print("Found max constrained root")
        case RootFinderStatus.OKRoundOff:
            File.print("Detected round-off convergence in bracket")
        case RootFinderStatus.WarningSingular:
            File.print("Detected singularity warning")
        case RootFinderStatus.WarningNonMonotonic:
            File.print("Detected non-monotonicity warning")
        case RootFinderStatus.ErrorRange:
            File.print("Detected out-of-range error")
        case RootFinderStatus.ErrorBracket:
            File.print("Detected bracket error")
        case RootFinderStatus.ErrorSlope:
            File.print("Detected slope error")
        case RootFinderStatus.ErrorSingular:
            File.print("Detected singularity error")
        case _:
            File.print("Detected bad root finder status")