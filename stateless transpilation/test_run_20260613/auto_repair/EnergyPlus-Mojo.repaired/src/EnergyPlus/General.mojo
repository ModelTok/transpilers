from math import abs, exp
from ObjexxFCL import index, strip, not_blank, nint, sign, mod, len, present
from ObjexxFCL import Optional_int, Optional_string_const, Optional_string
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataEnvironment import *
from EnergyPlus.DataHVACGlobals import *
from EnergyPlus.DataIPShortCuts import *
from EnergyPlus.DataRuntimeLanguage import *
from EnergyPlus.DataSurfaces import *
from EnergyPlus.HVACSystemRootFindingAlgorithm import RootAlgo
from EnergyPlus.InputProcessing.InputProcessor import InputProcessor
from EnergyPlus.UtilityRoutines import ShowSevereError, ShowContinueError, ShowWarningError
from EnergyPlus.WeatherManager import Weather, DateType, ReportPeriodData, computeJulianDate

const BlankString: String = ""
SMALL: Real64 = 1.e-10
FracToMin: Real64 = 60.0
toleranceTime: Real64 = 0.0001
SMALL_DIV: Real64 = 1.E-10
small_iter: Real64 = 1.e-9
Perturb_iter: Real64 = 0.1
DecMon: Int = 100 * 100 * 100
DecDay: Int = 100 * 100
DecHr: Int = 100
MinToSec: Int = 60
HourToSec: Int = 60 * 60

enum ReportType: Int {
    Invalid = -1
    DXF
    DXFWireFrame
    VRML
    Num
}

let ReportTypeNamesUC: StaticArray[String, ReportType.Num] = ["DXF", "DXF:WIREFRAME", "VRML"]

enum AvailRpt: Int {
    Invalid = -1
    None
    NotByUniqueKeyNames
    Verbose
    Num
}

let AvailRptNamesUC: StaticArray[String, AvailRpt.Num] = ["NONE", "NOTBYUNIQUEKEYNAMES", "VERBOSE"]

enum ERLdebugOutputLevel: Int {
    Invalid = -1
    None
    ErrorsOnly
    Verbose
    Num
}

let ERLdebugOutputLevelNamesUC: StaticArray[String, ERLdebugOutputLevel.Num] = ["NONE", "ERRORSONLY", "VERBOSE"]

enum ReportName: Int {
    Invalid = -1
    Constructions
    Viewfactorinfo
    Variabledictionary
    Surfaces
    Energymanagementsystem
    Num
}

let ReportNamesUC: StaticArray[String, ReportName.Num] = [
    "CONSTRUCTIONS", "VIEWFACTORINFO", "VARIABLEDICTIONARY", "SURFACES", "ENERGYMANAGEMENTSYSTEM"
]

enum RptKey: Int {
    Invalid = -1
    Costinfo
    DXF
    DXFwireframe
    VRML
    Vertices
    Details
    DetailsWithVertices
    Lines
    Num
}

let RptKeyNamesUC: StaticArray[String, RptKey.Num] = [
    "COSTINFO", "DXF", "DXF:WIREFRAME", "VRML", "VERTICES", "DETAILS", "DETAILSWITHVERTICES", "LINES"
]

namespace General {
    SOLVEROOT_ERROR_INIT: Int = -2
    SOLVEROOT_ERROR_ITER: Int = -1

    struct SolveRootStats:
        var algo: RootAlgo = RootAlgo.RegulaFalsi
        var counts: Int = 0
        var algoCounts: StaticArray[Int, RootAlgo.Num] = StaticArray[Int, RootAlgo.Num](0)
        var algoIters: StaticArray[Int, RootAlgo.Num] = StaticArray[Int, RootAlgo.Num](0)
    end

    def SolveRoot(
        state: EnergyPlusData,
        Eps: Real64,
        MaxIte: Int,
        Flag: inout Int,
        XRes: inout Real64,
        f: fn(Real64) -> Real64,
        X_0: Real64,
        X_1: Real64
    ):
        X0: Real64 = X_0
        X1: Real64 = X_1
        XTemp: Real64 = X0
        NIte: Int = 0
        AltIte: Int = 0
        Y0: Real64 = f(X0)
        Y1: Real64 = f(X1)
        if Y0 * Y1 > 0:
            Flag = SOLVEROOT_ERROR_INIT
            XRes = X0
            return
        XRes = XTemp
        while True:
            DY: Real64 = Y0 - Y1
            if abs(DY) < SMALL:
                DY = SMALL
            if abs(X1 - X0) < SMALL:
                break
            switch state.dataRootFinder.rootAlgo:
                case RootAlgo.RegulaFalsi:
                    XTemp = (Y0 * X1 - Y1 * X0) / DY
                    break
                case RootAlgo.Bisection:
                    XTemp = (X1 + X0) / 2.0
                    break
                case RootAlgo.RegulaFalsiThenBisection:
                    if NIte > state.dataRootFinder.NumOfIter:
                        XTemp = (X1 + X0) / 2.0
                    else:
                        XTemp = (Y0 * X1 - Y1 * X0) / DY
                    break
                case RootAlgo.BisectionThenRegulaFalsi:
                    if NIte <= state.dataRootFinder.NumOfIter:
                        XTemp = (X1 + X0) / 2.0
                    else:
                        XTemp = (Y0 * X1 - Y1 * X0) / DY
                    break
                case RootAlgo.Alternation:
                    if AltIte > state.dataRootFinder.NumOfIter:
                        XTemp = (X1 + X0) / 2.0
                        if AltIte >= 2 * state.dataRootFinder.NumOfIter:
                            AltIte = 0
                    else:
                        XTemp = (Y0 * X1 - Y1 * X0) / DY
                    break
                case RootAlgo.ShortBisectionThenRegulaFalsi:
                    if NIte < 3:
                        XTemp = (X1 + X0) / 2.0
                    else:
                        XTemp = (Y0 * X1 - Y1 * X0) / DY
                    break
                case _:
                    XTemp = (Y0 * X1 - Y1 * X0) / DY
                    break
            YTemp: Real64 = f(XTemp)
            NIte += 1
            AltIte += 1
            if abs(YTemp) < Eps:
                Flag = NIte
                XRes = XTemp
                return
            # if NIte > 20:
            #     assert False
            #     Flag = NIte
            #     XRes = XTemp
            #     return
            if NIte > MaxIte:
                break
            if Y0 < 0.0:
                if YTemp < 0.0:
                    X0 = XTemp
                    Y0 = YTemp
                else:
                    X1 = XTemp
                    Y1 = YTemp
            else:
                if YTemp < 0.0:
                    X1 = XTemp
                    Y1 = YTemp
                else:
                    X0 = XTemp
                    Y0 = YTemp
        Flag = SOLVEROOT_ERROR_ITER
        XRes = XTemp

    def SolveRoot2(
        state: EnergyPlusData,
        Eps: Real64,
        maxIters: Int,
        SolFlag: inout Int,
        f: fn(Real64) -> Real64,
        X_0: Real64,
        X_1: Real64,
        config: inout SolveRootStats
    ) -> Real64:
        XRes: Real64
        algoTemp: RootAlgo = state.dataRootFinder.rootAlgo
        state.dataRootFinder.rootAlgo = config.algo
        SolveRoot(state, Eps, maxIters, SolFlag, XRes, f, X_0, X_1)
        state.dataRootFinder.rootAlgo = algoTemp
        if SolFlag > 0:
            config.counts += 1
            config.algoCounts[Int(config.algo)] += 1
            config.algoIters[Int(config.algo)] += SolFlag
            const TRIALS_PER_COUNT: Int = 5
            if config.counts < TRIALS_PER_COUNT * Int(RootAlgo.Num):
                config.algo = RootAlgo(Int(config.algo) + 1)
                if config.algo == RootAlgo.Num:
                    config.algo = RootAlgo.RegulaFalsi
            elif config.counts == TRIALS_PER_COUNT * Int(RootAlgo.Num):
                var minIters: Int = maxIters * TRIALS_PER_COUNT
                config.algo = RootAlgo.Invalid
                for i in range(Int(RootAlgo.Num)):
                    if config.algoIters[i] < minIters:
                        config.algo = RootAlgo(i)
                        minIters = config.algoIters[i]
            else:

        return XRes

    def MovingAvg(DataIn: inout List[Real64], NumItemsInAvg: Int):
        if NumItemsInAvg <= 1:
            return
        TempData: List[Real64] = List[Real64](2 * len(DataIn))
        for i in range(len(DataIn)):
            TempData[i] = TempData[len(DataIn) + i] = DataIn[i]
            DataIn[i] = 0.0
        for i in range(len(DataIn)):
            for j in range(NumItemsInAvg):
                DataIn[i] += TempData[len(DataIn) - NumItemsInAvg + i + j]
            DataIn[i] /= NumItemsInAvg

    def ProcessDateString(
        state: EnergyPlusData,
        String: String,
        PMonth: inout Int,
        PDay: inout Int,
        PWeekDay: inout Int,
        DateType: inout Weather.DateType,
        ErrorsFound: inout Bool,
        PYear: Optional[Int] = None
    ):
        errFlag: Bool
        FstNum: Int = Int(Util.ProcessNumber(String, errFlag))
        DateType = Weather.DateType.Invalid
        if not errFlag:
            if FstNum == 0:
                PMonth = 0
                PDay = 0
                DateType = Weather.DateType.MonthDay
            elif FstNum < 0 or FstNum > 366:
                ShowSevereError(state, f"Invalid Julian date Entered={String}")
                ErrorsFound = True
            else:
                InvOrdinalDay(FstNum, PMonth, PDay, 0)
                DateType = Weather.DateType.LastDayInMonth
        else:
            NumTokens: Int
            TokenDay: Int
            TokenMonth: Int
            TokenWeekday: Int
            if PYear is None:
                DetermineDateTokens(state, String, NumTokens, TokenDay, TokenMonth, TokenWeekday, DateType, ErrorsFound)
            else:
                TokenYear: Int
                DetermineDateTokens(state, String, NumTokens, TokenDay, TokenMonth, TokenWeekday, DateType, ErrorsFound, TokenYear)
                PYear = Some(TokenYear)
            if DateType == Weather.DateType.MonthDay:
                PDay = TokenDay
                PMonth = TokenMonth
            elif DateType == Weather.DateType.NthDayInMonth or DateType == Weather.DateType.LastDayInMonth:
                PDay = TokenDay
                PMonth = TokenMonth
                PWeekDay = TokenWeekday

    def DetermineDateTokens(
        state: EnergyPlusData,
        String: String,
        NumTokens: inout Int,
        TokenDay: inout Int,
        TokenMonth: inout Int,
        TokenWeekday: inout Int,
        DateType: inout Weather.DateType,
        ErrorsFound: inout Bool,
        TokenYear: inout Int? = None
    ):
        const NumSingleChars: Int = 3
        const SingleChars: StaticArray[String, NumSingleChars] = ["/", ":", "-"]
        const NumDoubleChars: Int = 6
        const DoubleChars: StaticArray[String, NumDoubleChars] = ["ST ", "ND ", "RD ", "TH ", "OF ", "IN "]
        const Months: StaticArray[String, 12] = [
            "JAN", "FEB", "MAR", "APR", "MAY", "JUN",
            "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"
        ]
        const Weekdays: StaticArray[String, 7] = [
            "SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"
        ]
        CurrentString: String = String
        Fields: List[String] = List[String](3)
        InternalError: Bool = False
        WkDayInMonth: Bool = False
        NumTokens = 0
        TokenDay = 0
        TokenMonth = 0
        TokenWeekday = 0
        DateType = Weather.DateType.Invalid
        if TokenYear is not None:
            TokenYear = 0
        for Loop in range(NumSingleChars):
            Pos: Int = index(CurrentString, SingleChars[Loop])
            while Pos != -1:
                CurrentString = replace(CurrentString, Pos, 1, " ")
                Pos = index(CurrentString, SingleChars[Loop])
        for Loop in range(NumDoubleChars):
            Pos: Int = index(CurrentString, DoubleChars[Loop])
            while Pos != -1:
                CurrentString = replace(CurrentString, Pos, 2, "  ")
                Pos = index(CurrentString, DoubleChars[Loop])
                WkDayInMonth = True
        strip(CurrentString)
        if CurrentString == BlankString:
            ShowSevereError(state, f"Invalid date field={String}")
            ErrorsFound = True
        else:
            Loop: Int = 0
            errFlag: Bool
            NumField1: Int
            NumField2: Int
            NumField3: Int
            while Loop < 3:
                if CurrentString == BlankString:
                    break
                Pos: Int = index(CurrentString, " ")
                Loop += 1
                if Pos == -1:
                    Pos = len(CurrentString)
                Fields[Loop - 1] = CurrentString[0:Pos]
                CurrentString = CurrentString[Pos:]
                strip(CurrentString)
            if not_blank(CurrentString):
                ShowSevereError(state, f"Invalid date field={String}")
                ErrorsFound = True
            elif Loop == 2:
                InternalError = False
                NumField1 = Int(Util.ProcessNumber(Fields[0], errFlag))
                if errFlag:
                    NumField2 = Int(Util.ProcessNumber(Fields[1], errFlag))
                    if errFlag:
                        ShowSevereError(state, f"Invalid date field={String}")
                        InternalError = True
                    else:
                        TokenDay = NumField2
                    TokenMonth = Util.FindItemInList(Fields[0][0:3], Months)
                    ValidateMonthDay(state, String, TokenDay, TokenMonth, InternalError)
                    if not InternalError:
                        DateType = Weather.DateType.MonthDay
                    else:
                        ErrorsFound = True
                else:
                    NumField2 = Int(Util.ProcessNumber(Fields[1], errFlag))
                    if not errFlag:
                        TokenMonth = NumField1
                        TokenDay = NumField2
                        ValidateMonthDay(state, String, TokenDay, TokenMonth, InternalError)
                        if not InternalError:
                            DateType = Weather.DateType.MonthDay
                        else:
                            ErrorsFound = True
                    else:
                        TokenDay = NumField1
                        TokenMonth = Util.FindItemInList(Fields[1][0:3], Months)
                        ValidateMonthDay(state, String, TokenDay, TokenMonth, InternalError)
                        if not InternalError:
                            DateType = Weather.DateType.MonthDay
                            NumTokens = 2
                        else:
                            ErrorsFound = True
            elif Loop == 3:
                if WkDayInMonth:
                    NumField1 = Int(Util.ProcessNumber(Fields[0], errFlag))
                    if not errFlag:
                        TokenDay = NumField1
                        TokenWeekday = Util.FindItemInList(Fields[1][0:3], Weekdays)
                        if TokenWeekday == 0:
                            TokenMonth = Util.FindItemInList(Fields[1][0:3], Months)
                            TokenWeekday = Util.FindItemInList(Fields[2][0:3], Weekdays)
                            if TokenMonth == 0 or TokenWeekday == 0:
                                InternalError = True
                        else:
                            TokenMonth = Util.FindItemInList(Fields[2][0:3], Months)
                            if TokenMonth == 0:
                                InternalError = True
                        DateType = Weather.DateType.NthDayInMonth
                        NumTokens = 3
                        if TokenDay < 0 or TokenDay > 5:
                            InternalError = True
                    else:
                        if Fields[0] == "LA":
                            DateType = Weather.DateType.LastDayInMonth
                            NumTokens = 3
                            TokenWeekday = Util.FindItemInList(Fields[1][0:3], Weekdays)
                            if TokenWeekday == 0:
                                TokenMonth = Util.FindItemInList(Fields[1][0:3], Months)
                                TokenWeekday = Util.FindItemInList(Fields[2][0:3], Weekdays)
                                if TokenMonth == 0 or TokenWeekday == 0:
                                    InternalError = True
                            else:
                                TokenMonth = Util.FindItemInList(Fields[2][0:3], Months)
                                if TokenMonth == 0:
                                    InternalError = True
                        else:
                            ShowSevereError(state, f"First date field not numeric, field={String}")
                else:
                    NumField1 = Int(Util.ProcessNumber(Fields[0], errFlag))
                    NumField2 = Int(Util.ProcessNumber(Fields[1], errFlag))
                    NumField3 = Int(Util.ProcessNumber(Fields[2], errFlag))
                    DateType = Weather.DateType.MonthDay
                    if NumField1 > 100:
                        if TokenYear is not None:
                            TokenYear = NumField1
                        TokenMonth = NumField2
                        TokenDay = NumField3
                    elif NumField3 > 100:
                        if TokenYear is not None:
                            TokenYear = NumField3
                        TokenMonth = NumField1
                        TokenDay = NumField2
            else:
                ShowSevereError(state, f"Invalid date field={String}")
                ErrorsFound = True
        if InternalError:
            DateType = Weather.DateType.Invalid
            ErrorsFound = True

    def ValidateMonthDay(
        state: EnergyPlusData,
        String: String,
        Day: Int,
        Month: Int,
        ErrorsFound: inout Bool
    ):
        const EndMonthDay: StaticArray[Int, 12] = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
        InternalError: Bool = False
        if Month < 1 or Month > 12:
            InternalError = True
        if not InternalError:
            if Day < 1 or Day > EndMonthDay[Month - 1]:
                InternalError = True
        if InternalError:
            ShowSevereError(state, f"Invalid Month Day date format={String}")
            ErrorsFound = True
        else:
            ErrorsFound = False

    def OrdinalDay(Month: Int, Day: Int, LeapYearValue: Int) -> Int:
        const EndDayofMonth: StaticArray[Int, 12] = [31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365]
        if Month == 1:
            return Day
        if Month == 2:
            return Day + EndDayofMonth[0]
        if Month >= 3 and Month <= 12:
            return Day + EndDayofMonth[Month - 2] + LeapYearValue
        return 0

    def InvOrdinalDay(Number: Int, PMonth: inout Int, PDay: inout Int, LeapYr: Int):
        const EndOfMonth: StaticArray[Int, 13] = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365]
        WMonth: Int
        LeapAddPrev: Int
        LeapAddCur: Int
        if Number < 0 or Number > 366:
            return
        for WMonth in range(1, 13):
            if WMonth == 1:
                LeapAddPrev = 0
                LeapAddCur = 0
            elif WMonth == 2:
                LeapAddPrev = 0
                LeapAddCur = LeapYr
            else:
                LeapAddPrev = LeapYr
                LeapAddCur = LeapYr
            if Number > (EndOfMonth[WMonth - 1] + LeapAddPrev) and Number <= (EndOfMonth[WMonth] + LeapAddCur):
                break
        PMonth = WMonth
        PDay = Number - (EndOfMonth[WMonth - 1] + LeapAddCur)

    def BetweenDateHoursLeftInclusive(
        TestDate: Int, TestHour: Int, StartDate: Int, StartHour: Int, EndDate: Int, EndHour: Int
    ) -> Bool:
        TestRatioOfDay: Real64 = TestHour / 24.0
        StartRatioOfDay: Real64 = StartHour / 24.0
        EndRatioOfDay: Real64 = EndHour / 24.0
        if StartDate + StartRatioOfDay <= EndDate + EndRatioOfDay:
            return (StartDate + StartRatioOfDay <= TestDate + TestRatioOfDay) and (TestDate + TestRatioOfDay <= EndDate + EndRatioOfDay)
        return (EndDate + EndRatioOfDay <= TestDate + TestRatioOfDay) and (TestDate + TestRatioOfDay <= StartDate + StartRatioOfDay)

    def BetweenDates(TestDate: Int, StartDate: Int, EndDate: Int) -> Bool:
        var BetweenDates: Bool = False
        if StartDate <= EndDate:
            if TestDate >= StartDate and TestDate <= EndDate:
                BetweenDates = True
        else:
            if TestDate <= EndDate or TestDate >= StartDate:
                BetweenDates = True
        return BetweenDates

    def CreateSysTimeIntervalString(state: EnergyPlusData) -> String:
        SysTimeElapsed: Real64 = state.dataHVACGlobal.SysTimeElapsed
        TimeStepSys: Real64 = state.dataHVACGlobal.TimeStepSys
        ActualTimeS: Real64
        ActualTimeE: Real64
        if SysTimeElapsed == 0.0:
            ActualTimeE = state.dataGlobal.CurrentTime
            ActualTimeS = ActualTimeE - state.dataGlobal.TimeStepZone
        elif abs(state.dataGlobal.TimeStepZone - SysTimeElapsed) <= toleranceTime:
            ActualTimeE = state.dataGlobal.CurrentTime
            ActualTimeS = ActualTimeE - TimeStepSys
        else:
            ActualTimeS = state.dataGlobal.CurrentTime - state.dataGlobal.TimeStepZone + SysTimeElapsed
            ActualTimeE = ActualTimeS + TimeStepSys
        ActualTimeHrS: Int = Int(ActualTimeS)
        ActualTimeMinS: Int = nint((ActualTimeS - ActualTimeHrS) * FracToMin)
        if ActualTimeMinS == 60:
            ActualTimeHrS += 1
            ActualTimeMinS = 0
        TimeStmpS: String = f"{ActualTimeHrS:02d}:{ActualTimeMinS:02d}"
        minutes: Real64 = ((ActualTimeE - Int(ActualTimeE)) * FracToMin)
        TimeStmpE: String = f"{Int(ActualTimeE):02d}:{minutes:2.0F}"
        if TimeStmpE[3] == " ":
            TimeStmpE[3] = "0"
        return TimeStmpS + " - " + TimeStmpE

    def nthDayOfWeekOfMonth(
        state: EnergyPlusData,
        dayOfWeek: Int,
        nthTime: Int,
        monthNumber: Int
    ) -> Int:
        firstDayOfMonth: Int = OrdinalDay(monthNumber, 1, Int(state.dataEnvrn.CurrentYearIsLeapYear))
        dayOfWeekForFirstDay: Int = (state.dataEnvrn.RunPeriodStartDayOfWeek + firstDayOfMonth - 1) % 7
        if dayOfWeek >= dayOfWeekForFirstDay:
            return firstDayOfMonth + (dayOfWeek - dayOfWeekForFirstDay) + 7 * (nthTime - 1)
        return firstDayOfMonth + ((dayOfWeek + 7) - dayOfWeekForFirstDay) + 7 * (nthTime - 1)

    def SafeDivide(a: Real64, b: Real64) -> Real64:
        if abs(b) >= SMALL_DIV:
            return a / b
        return a / sign(SMALL_DIV, b)

    def Iterate(
        ResultX: inout Real64,
        Tol: Real64,
        X0: Real64,
        Y0: Real64,
        X1: inout Real64,
        Y1: inout Real64,
        Iter: Int,
        Cnvg: inout Int
    ):
        if Iter != 1:
            if abs(X0 - X1) < Tol or Y0 == 0.0:
                ResultX = X0
                Cnvg = 1
                return
        Cnvg = 0
        if Iter == 1:
            if abs(X0) > small_iter:
                ResultX = X0 * (1.0 + Perturb_iter)
            else:
                ResultX = Perturb_iter
        else:
            DY: Real64 = Y0 - Y1
            if abs(DY) < small_iter:
                DY = small_iter
            ResultX = (Y0 * X1 - Y1 * X0) / DY
        X1 = X0
        Y1 = Y0

    def FindNumberInList(WhichNumber: Int, ListOfItems: List[Int], NumItems: Int) -> Int:
        # ListOfItems.dim(_)  // ignored in Mojo, already sized
        for Count in range(NumItems):
            if WhichNumber == ListOfItems[Count]:
                return Count + 1  # Mojo is 0-based, but C++ returns 1-based index
        return 0

    def DecodeMonDayHrMin(
        Item: Int,
        Month: inout Int,
        Day: inout Int,
        Hour: inout Int,
        Minute: inout Int
    ):
        TmpItem: Int = Item
        Month = TmpItem / DecMon
        TmpItem = (TmpItem - Month * DecMon)
        Day = TmpItem / DecDay
        TmpItem -= Day * DecDay
        Hour = TmpItem / DecHr
        Minute = mod(TmpItem, DecHr)

    def EncodeMonDayHrMin(
        Item: inout Int,
        Month: Int,
        Day: Int,
        Hour: Int,
        Minute: Int
    ):
        Item = ((Month * 100 + Day) * 100 + Hour) * 100 + Minute

    def CreateTimeString(Time: Real64) -> String:
        Hours: Int
        Minutes: Int
        Seconds: Real64
        ParseTime(Time, Hours, Minutes, Seconds)
        return f"{Hours:02d}:{Minutes:02d}:{Seconds:04.1f}"

    def ParseTime(
        Time: Real64,
        Hours: inout Int,
        Minutes: inout Int,
        Seconds: inout Real64
    ):
        Hours = Int(Time) / HourToSec
        Remainder: Real64 = (Time - Hours * HourToSec)
        Minutes = Int(Remainder) / MinToSec
        Remainder -= Minutes * MinToSec
        Seconds = Remainder

    def ScanForReports(
        state: EnergyPlusData,
        reportName: String,
        DoReport: inout Bool,
        ReportKey: Optional[String] = None,
        Option1: inout Optional[String] = None,
        Option2: inout Optional[String] = None
    ):
        if state.dataGeneral.GetReportInput:
            NumNames: Int
            NumNumbers: Int
            IOStat: Int
            RepNum: Int
            cCurrentModuleObject: String = state.dataIPShortCut.cCurrentModuleObject
            cCurrentModuleObject = "Output:Surfaces:List"
            NumReports: Int = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, cCurrentModuleObject)
            const EMPTY: Int = 0
            const LINES: Int = 1
            const VERTICES: Int = 2
            const DETAILS: Int = 3
            const DETAILSWITHVERTICES: Int = 4
            const COSTINFO: Int = 5
            const VIEWFACTORINFO: Int = 6
            const DECAYCURVESFROMCOMPONENTLOADSSUMMARY: Int = 7
            localMap: Dict[String, Int] = {
                "": EMPTY,
                "LINES": LINES,
                "VERTICES": VERTICES,
                "DETAILS": DETAILS,
                "DETAILED": DETAILS,
                "DETAIL": DETAILS,
                "DETAILSWITHVERTICES": DETAILSWITHVERTICES,
                "DETAILVERTICES": DETAILSWITHVERTICES,
                "COSTINFO": COSTINFO,
                "VIEWFACTORINFO": VIEWFACTORINFO,
                "DECAYCURVESFROMCOMPONENTLOADSSUMMARY": DECAYCURVESFROMCOMPONENTLOADSSUMMARY
            }
            for RepNum in range(1, NumReports + 1):
                state.dataInputProcessing.inputProcessor.getObjectItem(
                    state,
                    cCurrentModuleObject,
                    RepNum,
                    state.dataIPShortCut.cAlphaArgs,
                    NumNames,
                    state.dataIPShortCut.rNumericArgs,
                    NumNumbers,
                    IOStat,
                    state.dataIPShortCut.lNumericFieldBlanks,
                    state.dataIPShortCut.lAlphaFieldBlanks,
                    state.dataIPShortCut.cAlphaFieldNames,
                    state.dataIPShortCut.cNumericFieldNames
                )
                try:
                    value: Int = localMap[state.dataIPShortCut.cAlphaArgs[0]]
                    switch value:
                        case LINES:
                            state.dataGeneral.LineRpt = True
                            state.dataGeneral.LineRptOption1 = state.dataIPShortCut.cAlphaArgs[1]
                            break
                        case VERTICES:
                            state.dataGeneral.SurfVert = True
                            break
                        case DETAILS:
                            state.dataGeneral.SurfDet = True
                            break
                        case DETAILSWITHVERTICES:
                            state.dataGeneral.SurfDetWVert = True
                            break
                        case COSTINFO:
                            state.dataGeneral.CostInfo = True
                            break
                        case VIEWFACTORINFO:
                            state.dataGeneral.ViewFactorInfo = True
                            state.dataGeneral.ViewRptOption1 = state.dataIPShortCut.cAlphaArgs[1]
                            break
                        case DECAYCURVESFROMCOMPONENTLOADSSUMMARY:
                            state.dataGlobal.ShowDecayCurvesInEIO = True
                            break
                        case _:
                            ShowWarningError(
                                state,
                                f"{cCurrentModuleObject}: No {state.dataIPShortCut.cAlphaFieldNames[0]} supplied."
                            )
                            ShowContinueError(
                                state,
                                " Legal values are: \"Lines\", \"Vertices\", \"Details\", \"DetailsWithVertices\", \"CostInfo\", \"ViewFactorIinfo\"."
                            )
                            break
                except e:
                    ShowWarningError(
                        state,
                        f"{cCurrentModuleObject}: Invalid {state.dataIPShortCut.cAlphaFieldNames[0]}=\"{state.dataIPShortCut.cAlphaArgs[0]}\" supplied."
                    )
                    ShowContinueError(
                        state,
                        " Legal values are: \"Lines\", \"Vertices\", \"Details\", \"DetailsWithVertices\", \"CostInfo\", \"ViewFactorIinfo\"."
                    )
            cCurrentModuleObject = "Output:Surfaces:Drawing"
            NumReports = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, cCurrentModuleObject)
            for RepNum in range(1, NumReports + 1):
                state.dataInputProcessing.inputProcessor.getObjectItem(
                    state,
                    cCurrentModuleObject,
                    RepNum,
                    state.dataIPShortCut.cAlphaArgs,
                    NumNames,
                    state.dataIPShortCut.rNumericArgs,
                    NumNumbers,
                    IOStat,
                    state.dataIPShortCut.lNumericFieldBlanks,
                    state.dataIPShortCut.lAlphaFieldBlanks,
                    state.dataIPShortCut.cAlphaFieldNames,
                    state.dataIPShortCut.cNumericFieldNames
                )
                checkReportType: ReportType = ReportType(
                    getEnumValue(ReportTypeNamesUC, Util.makeUPPER(state.dataIPShortCut.cAlphaArgs[0]))
                )
                switch checkReportType:
                    case ReportType.DXF:
                        state.dataGeneral.DXFReport = True
                        state.dataGeneral.DXFOption1 = state.dataIPShortCut.cAlphaArgs[1]
                        state.dataGeneral.DXFOption2 = state.dataIPShortCut.cAlphaArgs[2]
                        break
                    case ReportType.DXFWireFrame:
                        state.dataGeneral.DXFWFReport = True
                        state.dataGeneral.DXFWFOption1 = state.dataIPShortCut.cAlphaArgs[1]
                        state.dataGeneral.DXFWFOption2 = state.dataIPShortCut.cAlphaArgs[2]
                        break
                    case ReportType.VRML:
                        state.dataGeneral.VRMLReport = True
                        state.dataGeneral.VRMLOption1 = state.dataIPShortCut.cAlphaArgs[1]
                        state.dataGeneral.VRMLOption2 = state.dataIPShortCut.cAlphaArgs[2]
                        break
                    case _:
                        break
            RepNum = state.dataInputProcessing.inputProcessor.getNumSectionsFound("Report Variable Dictionary")
            if RepNum > 0:
                state.dataGeneral.VarDict = True
                state.dataGeneral.VarDictOption1 = "REGULAR"
                state.dataGeneral.VarDictOption2 = ""
            cCurrentModuleObject = "Output:VariableDictionary"
            NumReports = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, cCurrentModuleObject)
            for RepNum in range(1, NumReports + 1):
                state.dataInputProcessing.inputProcessor.getObjectItem(
                    state,
                    cCurrentModuleObject,
                    RepNum,
                    state.dataIPShortCut.cAlphaArgs,
                    NumNames,
                    state.dataIPShortCut.rNumericArgs,
                    NumNumbers,
                    IOStat,
                    state.dataIPShortCut.lNumericFieldBlanks,
                    state.dataIPShortCut.lAlphaFieldBlanks,
                    state.dataIPShortCut.cAlphaFieldNames,
                    state.dataIPShortCut.cNumericFieldNames
                )
                state.dataGeneral.VarDict = True
                state.dataGeneral.VarDictOption1 = state.dataIPShortCut.cAlphaArgs[0]
                state.dataGeneral.VarDictOption2 = state.dataIPShortCut.cAlphaArgs[1]
            cCurrentModuleObject = "Output:Constructions"
            NumReports = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, cCurrentModuleObject)
            for RepNum in range(1, NumReports + 1):
                state.dataInputProcessing.inputProcessor.getObjectItem(
                    state,
                    cCurrentModuleObject,
                    RepNum,
                    state.dataIPShortCut.cAlphaArgs,
                    NumNames,
                    state.dataIPShortCut.rNumericArgs,
                    NumNumbers,
                    IOStat,
                    state.dataIPShortCut.lNumericFieldBlanks,
                    state.dataIPShortCut.lAlphaFieldBlanks,
                    state.dataIPShortCut.cAlphaFieldNames,
                    state.dataIPShortCut.cNumericFieldNames
                )
                if Util.SameString(state.dataIPShortCut.cAlphaArgs[0], "CONSTRUCTIONS"):
                    state.dataGeneral.Constructions = True
                elif Util.SameString(state.dataIPShortCut.cAlphaArgs[0], "MATERIALS"):
                    state.dataGeneral.Materials = True
                if NumNames > 1:
                    if Util.SameString(state.dataIPShortCut.cAlphaArgs[1], "CONSTRUCTIONS"):
                        state.dataGeneral.Constructions = True
                    elif Util.SameString(state.dataIPShortCut.cAlphaArgs[1], "MATERIALS"):
                        state.dataGeneral.Materials = True
            cCurrentModuleObject = "Output:EnergyManagementSystem"
            NumReports = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, cCurrentModuleObject)
            for RepNum in range(1, NumReports + 1):
                state.dataInputProcessing.inputProcessor.getObjectItem(
                    state,
                    cCurrentModuleObject,
                    RepNum,
                    state.dataIPShortCut.cAlphaArgs,
                    NumNames,
                    state.dataIPShortCut.rNumericArgs,
                    NumNumbers,
                    IOStat,
                    state.dataIPShortCut.lNumericFieldBlanks,
                    state.dataIPShortCut.lAlphaFieldBlanks,
                    state.dataIPShortCut.cAlphaFieldNames,
                    state.dataIPShortCut.cNumericFieldNames
                )
                state.dataGeneral.EMSoutput = True
                CheckAvailRpt: AvailRpt = AvailRpt(
                    getEnumValue(AvailRptNamesUC, Util.makeUPPER(state.dataIPShortCut.cAlphaArgs[0]))
                )
                state.dataRuntimeLang.OutputEMSActuatorAvailSmall = (CheckAvailRpt == AvailRpt.NotByUniqueKeyNames)
                state.dataRuntimeLang.OutputEMSActuatorAvailFull = (CheckAvailRpt == AvailRpt.Verbose)
                CheckAvailRpt = AvailRpt(
                    getEnumValue(AvailRptNamesUC, Util.makeUPPER(state.dataIPShortCut.cAlphaArgs[1]))
                )
                state.dataRuntimeLang.OutputEMSInternalVarsSmall = (CheckAvailRpt == AvailRpt.NotByUniqueKeyNames)
                state.dataRuntimeLang.OutputEMSInternalVarsFull = (CheckAvailRpt == AvailRpt.Verbose)
                CheckERLlevel: ERLdebugOutputLevel = ERLdebugOutputLevel(
                    getEnumValue(ERLdebugOutputLevelNamesUC, Util.makeUPPER(state.dataIPShortCut.cAlphaArgs[2]))
                )
                state.dataRuntimeLang.OutputEMSErrors = (
                    CheckERLlevel == ERLdebugOutputLevel.ErrorsOnly or CheckERLlevel == ERLdebugOutputLevel.Verbose
                )
                state.dataRuntimeLang.OutputFullEMSTrace = (CheckERLlevel == ERLdebugOutputLevel.Verbose)
            state.dataGeneral.GetReportInput = False
        DoReport = False
        rptName: ReportName = ReportName(
            getEnumValue(ReportNamesUC, Util.makeUPPER(Util.makeUPPER(reportName)))
        )
        switch rptName:
            case ReportName.Constructions:
                if ReportKey is not None:
                    if Util.SameString(ReportKey[], "Constructions"):
                        DoReport = state.dataGeneral.Constructions
                    if Util.SameString(ReportKey[], "Materials"):
                        DoReport = state.dataGeneral.Materials
                break
            case ReportName.Viewfactorinfo:
                DoReport = state.dataGeneral.ViewFactorInfo
                if Option1 is not None:
                    Option1 = Some(state.dataGeneral.ViewRptOption1)
                break
            case ReportName.Variabledictionary:
                DoReport = state.dataGeneral.VarDict
                if Option1 is not None:
                    Option1 = Some(state.dataGeneral.VarDictOption1)
                if Option2 is not None:
                    Option2 = Some(state.dataGeneral.VarDictOption2)
                break
            case ReportName.Surfaces:
                rptKey: RptKey = RptKey(
                    getEnumValue(RptKeyNamesUC, Util.makeUPPER(ReportKey[]))
                )
                switch rptKey:
                    case RptKey.Costinfo:
                        DoReport = state.dataGeneral.CostInfo
                        break
                    case RptKey.DXF:
                        DoReport = state.dataGeneral.DXFReport
                        if Option1 is not None:
                            Option1 = Some(state.dataGeneral.DXFOption1)
                        if Option2 is not None:
                            Option2 = Some(state.dataGeneral.DXFOption2)
                        break
                    case RptKey.DXFwireframe:
                        DoReport = state.dataGeneral.DXFWFReport
                        if Option1 is not None:
                            Option1 = Some(state.dataGeneral.DXFWFOption1)
                        if Option2 is not None:
                            Option2 = Some(state.dataGeneral.DXFWFOption2)
                        break
                    case RptKey.VRML:
                        DoReport = state.dataGeneral.VRMLReport
                        if Option1 is not None:
                            Option1 = Some(state.dataGeneral.VRMLOption1)
                        if Option2 is not None:
                            Option2 = Some(state.dataGeneral.VRMLOption2)
                        break
                    case RptKey.Vertices:
                        DoReport = state.dataGeneral.SurfVert
                        break
                    case RptKey.Details:
                        DoReport = state.dataGeneral.SurfDet
                        break
                    case RptKey.DetailsWithVertices:
                        DoReport = state.dataGeneral.SurfDetWVert
                        break
                    case RptKey.Lines:
                        DoReport = state.dataGeneral.LineRpt
                        if Option1 is not None:
                            Option1 = Some(state.dataGeneral.LineRptOption1)
                        break
                    case _:
                        break
                break
            case ReportName.Energymanagementsystem:
                DoReport = state.dataGeneral.EMSoutput
                break
            case _:
                break

    def CheckCreatedZoneItemName(
        state: EnergyPlusData,
        calledFrom: String,
        CurrentObject: String,
        ZoneName: String,
        MaxZoneNameLength: Int,
        ItemName: String,
        ItemNames: List[String],
        NumItems: Int,
        ResultName: inout String,
        errFlag: inout Bool
    ):
        errFlag = False
        ItemNameLength: Int = len(ItemName)
        ItemLength: Int = len(ZoneName) + ItemNameLength
        ResultName = ZoneName + " " + ItemName
        TooLong: Bool = False
        if ItemLength > Constant.MaxNameLength:
            ShowWarningError(state, f"{calledFrom}{CurrentObject} Combination of ZoneList and Object Name generate a name too long.")
            ShowContinueError(state, f"Object Name=\"{ItemName}\".")
            ShowContinueError(state, f"ZoneList/Zone Name=\"{ZoneName}\".")
            ShowContinueError(
                state,
                f"Item length=[{ItemLength}] > Maximum Length=[{Constant.MaxNameLength}]. You may need to shorten the names."
            )
            ShowContinueError(
                state,
                f"Shortening the Object Name by [{MaxZoneNameLength + 1 + ItemNameLength - Constant.MaxNameLength}] characters will assure uniqueness for this ZoneList."
            )
            ShowContinueError(state, f"name that will be used (may be needed in reporting)=\"{ResultName}\".")
            TooLong = True
        FoundItem: Int = Util.FindItemInList(ResultName, ItemNames, NumItems)
        if FoundItem != 0:
            ShowSevereError(state, f"{calledFrom}{CurrentObject}=\"{ItemName}\", Duplicate Generated name encountered.")
            ShowContinueError(
                state,
                f"name=\"{ResultName}\" has already been generated or entered as {CurrentObject} item=[{FoundItem}]."
            )
            if TooLong:
                ShowContinueError(state, "Duplicate name likely caused by the previous \"too long\" warning.")
            ResultName = "xxxxxxx"
            errFlag = True

    def isReportPeriodBeginning(state: EnergyPlusData, periodIdx: Int) -> Bool:
        currentDate: Int
        reportStartDate: Int = state.dataWeather.ReportPeriodInput[periodIdx].startJulianDate
        reportStartHour: Int = state.dataWeather.ReportPeriodInput[periodIdx].startHour
        if state.dataWeather.ReportPeriodInput[periodIdx].startYear > 0:
            currentDate = Weather.computeJulianDate(state.dataEnvrn.Year, state.dataEnvrn.Month, state.dataEnvrn.DayOfMonth)
        else:
            currentDate = Weather.computeJulianDate(0, state.dataEnvrn.Month, state.dataEnvrn.DayOfMonth)
        return (currentDate == reportStartDate) and (state.dataGlobal.HourOfDay == reportStartHour)

    def findReportPeriodIdx(
        state: EnergyPlusData,
        ReportPeriodInputData: List[Weather.ReportPeriodData],
        nReportPeriods: Int,
        inReportPeriodFlags: inout List[Bool]
    ):
        currentDate: Int
        for i in range(nReportPeriods):
            reportStartDate: Int = ReportPeriodInputData[i].startJulianDate
            reportStartHour: Int = ReportPeriodInputData[i].startHour
            reportEndDate: Int = ReportPeriodInputData[i].endJulianDate
            reportEndHour: Int = ReportPeriodInputData[i].endHour
            if ReportPeriodInputData[i].startYear > 0:
                currentDate = Weather.computeJulianDate(state.dataEnvrn.Year, state.dataEnvrn.Month, state.dataEnvrn.DayOfMonth)
            else:
                currentDate = Weather.computeJulianDate(0, state.dataEnvrn.Month, state.dataEnvrn.DayOfMonth)
            if General.BetweenDateHoursLeftInclusive(
                currentDate, state.dataGlobal.HourOfDay, reportStartDate, reportStartHour, reportEndDate, reportEndHour
            ):
                inReportPeriodFlags[i] = True

    def rotAzmDiffDeg(AzmA: Real64, AzmB: Real64) -> Real64:
        diff: Real64 = AzmB - AzmA
        if diff > 180.0:
            diff = 360.0 - diff
        elif diff < -180.0:
            diff = 360.0 + diff
        return abs(diff)
} # namespace General

def Interp(Lower: Real64, Upper: Real64, InterpFac: Real64) -> Real64:
    return Lower + InterpFac * (Upper - Lower)

struct InterpCoeffs:
    var x1: Real64
    var x2: Real64

def GetInterpCoeffs(X: Real64, X1: Real64, X2: Real64, c: inout InterpCoeffs):
    c.x1 = (X - X1) / (X2 - X1)
    c.x2 = (X2 - X) / (X2 - X1)

def Interp2(Fx1: Real64, Fx2: Real64, c: InterpCoeffs) -> Real64:
    return c.x1 * Fx1 + c.x2 * Fx2

struct BilinearInterpCoeffs:
    var denom: Real64
    var x1y1: Real64
    var x1y2: Real64
    var x2y1: Real64
    var x2y2: Real64

def GetBilinearInterpCoeffs(
    X: Real64, Y: Real64, X1: Real64, X2: Real64, Y1: Real64, Y2: Real64, coeffs: inout BilinearInterpCoeffs
):
    if X1 == X2 and Y1 == Y2:
        coeffs.denom = 1.0
        coeffs.x1y1 = 1.0
        coeffs.x1y2 = 0.0
        coeffs.x2y1 = 0.0
        coeffs.x2y2 = 0.0
    elif X1 == X2:
        coeffs.denom = (Y2 - Y1)
        coeffs.x1y1 = (Y2 - Y)
        coeffs.x1y2 = (Y - Y1)
        coeffs.x2y1 = 0.0
        coeffs.x2y2 = 0.0
    elif Y1 == Y2:
        coeffs.denom = (X2 - X1)
        coeffs.x1y1 = (X2 - X)
        coeffs.x2y1 = (X - X1)
        coeffs.x1y2 = 0.0
        coeffs.x2y2 = 0.0
    else:
        coeffs.denom = (X2 - X1) * (Y2 - Y1)
        coeffs.x1y1 = (X2 - X) * (Y2 - Y)
        coeffs.x2y1 = (X - X1) * (Y2 - Y)
        coeffs.x1y2 = (X2 - X) * (Y - Y1)
        coeffs.x2y2 = (X - X1) * (Y - Y1)

def BilinearInterp(
    Fx1y1: Real64, Fx1y2: Real64, Fx2y1: Real64, Fx2y2: Real64, coeffs: BilinearInterpCoeffs
) -> Real64:
    return (coeffs.x1y1 * Fx1y1 + coeffs.x2y1 * Fx2y1 + coeffs.x1y2 * Fx1y2 + coeffs.x2y2 * Fx2y2) / coeffs.denom

struct GeneralData(BaseGlobalStruct):
    var GetReportInput: Bool = True
    var SurfVert: Bool = False
    var SurfDet: Bool = False
    var SurfDetWVert: Bool = False
    var DXFReport: Bool = False
    var DXFWFReport: Bool = False
    var VRMLReport: Bool = False
    var CostInfo: Bool = False
    var ViewFactorInfo: Bool = False
    var Constructions: Bool = False
    var Materials: Bool = False
    var LineRpt: Bool = False
    var VarDict: Bool = False
    var EMSoutput: Bool = False
    var XNext: Real64 = 0.0
    var DXFOption1: String = ""
    var DXFOption2: String = ""
    var DXFWFOption1: String = ""
    var DXFWFOption2: String = ""
    var VRMLOption1: String = ""
    var VRMLOption2: String = ""
    var ViewRptOption1: String = ""
    var LineRptOption1: String = ""
    var VarDictOption1: String = ""
    var VarDictOption2: String = ""

    def init_constant_state(state: EnergyPlusData):

    def init_state(state: EnergyPlusData):

    def clear_state():
        # new (this) GeneralData() - in Mojo we can just reinitialize fields manually
        self = GeneralData()