from DataWater import (
    ControlSupplyType,
    TankThermalMode,
    AmbientTempType,
    RainLossFactor,
    GroundWaterTable,
    IrrigationMode,
    RainfallMode,
    Overflow,
)
from DataEnvironment import OutWetBulbTempAt
from DataEnvironment import GroundTemp as GroundTempData
from DataEnvironment import GroundTempType
from DataGlobal import Constant
from InputProcessor import InputProcessor
from OutputProcessor import SetupOutputVariable, OutputProcessor
from OutputReportPredefined import PreDefTableEntry
from ScheduleManager import Sched
from UtilityRoutines import (
    ShowFatalError,
    ShowSevereError,
    ShowWarningError,
    ShowContinueError,
    ShowSevereEmptyField,
    ShowSevereInvalidKey,
    ShowSevereItemNotFound,
    ShowWarningBadMax,
    ShowSevereBadMin,
    ShowSevereBadMinMax,
    FindItemInList,
    SameString,
    is_blank,
    getEnumValue,
    format,
    ErrorObjectHeader,
)
from DataSurfaces import Surface as SurfaceType
from DataHeatBalance import Zone as ZoneType
from DataWater import DataWaterData
from DataGlobal import EnergyPlusData
from EcoRoofManager import EcoRoofManagerData
from BaseGlobal import BaseGlobalStruct
from utils import (
    Array1D_string,
    Array1D_bool,
    Array1D_float64,
    allocated,
    dimension,
    sum,
    max,
    min,
    Clusive,
)

# Include the WaterManagerData struct from header
struct WaterManagerData(BaseGlobalStruct):
    var MyOneTimeFlag: Bool
    var GetInputFlag: Bool
    var MyEnvrnFlag: Bool
    var MyWarmupFlag: Bool
    var MyTankDemandCheckFlag: Bool
    var overflowTwater: Float64

    def __init__(inout self):
        self.MyOneTimeFlag = True
        self.GetInputFlag = True
        self.MyEnvrnFlag = True
        self.MyWarmupFlag = False
        self.MyTankDemandCheckFlag = True
        self.overflowTwater = 0.0

    def init_constant_state(inout self, state: EnergyPlusData):

    def init_state(inout self, state: EnergyPlusData):

    def clear_state(inout self):
        self.MyOneTimeFlag = True
        self.GetInputFlag = True
        self.MyEnvrnFlag = True
        self.MyWarmupFlag = False
        self.MyTankDemandCheckFlag = True
        self.overflowTwater = 0.0

# Start WaterManager namespace as module-level functions and constants
let controlSupplyTypeNamesUC: List[String] = [
    "NONE",
    "MAINS",
    "GROUNDWATERWELL",
    "GROUNDWATERWELLMAINSBACKUP",
    "OTHERTANK",
    "OTHERTANKMAINSBACKUP",
]

let tankThermalModeNamesUC: List[String] = [
    "SCHEDULEDTEMPERATURE",
    "THERMALMODEL",
]

let ambientTempTypeNamesUC: List[String] = [
    "SCHEDULE",
    "ZONE",
    "OUTDOORS",
]

let rainLossFactorNamesUC: List[String] = [
    "CONSTANT",
    "SCHEDULED",
]

let groundWaterTableNamesUC: List[String] = [
    "CONSTANT",
    "SCHEDULED",
]

let irrigationModeNamesUC: List[String] = [
    "SCHEDULE",
    "SMARTSCHEDULE",
]

def ManageWater(state: EnergyPlusData):
    var RainColNum: Int = 0
    var TankNum: Int = 0
    var WellNum: Int = 0

    if state.dataWaterManager.GetInputFlag:
        GetWaterManagerInput(state)
        state.dataWaterManager.GetInputFlag = False

    if not state.dataWaterData.AnyWaterSystemsInModel:
        return

    for TankNum in range(1, state.dataWaterData.NumWaterStorageTanks + 1):
        CalcWaterStorageTank(state, TankNum)
    for RainColNum in range(1, state.dataWaterData.NumRainCollectors + 1):
        CalcRainCollector(state, RainColNum)
    for WellNum in range(1, state.dataWaterData.NumGroundWaterWells + 1):
        CalcGroundwaterWell(state, WellNum)
    for TankNum in range(1, state.dataWaterData.NumWaterStorageTanks + 1):
        CalcWaterStorageTank(state, TankNum)

def ManageWaterInits(state: EnergyPlusData):
    if not state.dataWaterData.AnyWaterSystemsInModel:
        return
    UpdateWaterManager(state)
    UpdateIrrigation(state)

def GetWaterManagerInput(state: EnergyPlusData):
    let routineName: String = "GetWaterManagerInput"
    var cAlphaFieldNames: List[String] = []
    var cNumericFieldNames: List[String] = []
    var lNumericFieldBlanks: List[Bool] = []
    var lAlphaFieldBlanks: List[Bool] = []
    var cAlphaArgs: List[String] = []
    var rNumericArgs: List[Float64] = []

    if (
        state.dataWaterManager.MyOneTimeFlag
        and not state.dataWaterData.WaterSystemGetInputCalled
    ):
        var Item: Int = 0
        var NumAlphas: Int = 0
        var NumNumbers: Int = 0
        var IOStatus: Int = 0
        var ErrorsFound: Bool = False
        var MaxNumAlphas: Int = 0
        var MaxNumNumbers: Int = 0
        var TotalArgs: Int = 0
        var NumIrrigation: Int = 0

        state.dataWaterData.RainFall.ModeID = 0  # RainfallMode::None

        var cCurrentModuleObject: String = "WaterUse:Storage"
        state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(
            state, cCurrentModuleObject, TotalArgs, NumAlphas, NumNumbers
        )
        MaxNumNumbers = NumNumbers
        MaxNumAlphas = NumAlphas

        cCurrentModuleObject = "WaterUse:RainCollector"
        state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(
            state, cCurrentModuleObject, TotalArgs, NumAlphas, NumNumbers
        )
        MaxNumNumbers = max(MaxNumNumbers, NumNumbers)
        MaxNumAlphas = max(MaxNumAlphas, NumAlphas)

        cCurrentModuleObject = "WaterUse:Well"
        state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(
            state, cCurrentModuleObject, TotalArgs, NumAlphas, NumNumbers
        )
        MaxNumNumbers = max(MaxNumNumbers, NumNumbers)
        MaxNumAlphas = max(MaxNumAlphas, NumAlphas)

        cCurrentModuleObject = "Site:Precipitation"
        state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(
            state, cCurrentModuleObject, TotalArgs, NumAlphas, NumNumbers
        )
        MaxNumNumbers = max(MaxNumNumbers, NumNumbers)
        MaxNumAlphas = max(MaxNumAlphas, NumAlphas)

        cCurrentModuleObject = "RoofIrrigation"
        state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(
            state, cCurrentModuleObject, TotalArgs, NumAlphas, NumNumbers
        )
        MaxNumNumbers = max(MaxNumNumbers, NumNumbers)
        MaxNumAlphas = max(MaxNumAlphas, NumAlphas)

        cAlphaFieldNames = [""] * MaxNumAlphas
        cAlphaArgs = [""] * MaxNumAlphas
        lAlphaFieldBlanks = [False] * MaxNumAlphas
        cNumericFieldNames = [""] * MaxNumNumbers
        rNumericArgs = [0.0] * MaxNumNumbers
        lNumericFieldBlanks = [False] * MaxNumNumbers

        state.dataWaterManager.MyOneTimeFlag = False

        cCurrentModuleObject = "WaterUse:Storage"
        state.dataWaterData.NumWaterStorageTanks = (
            state.dataInputProcessing.inputProcessor.getNumObjectsFound(
                state, cCurrentModuleObject
            )
        )
        if state.dataWaterData.NumWaterStorageTanks > 0:
            state.dataWaterData.AnyWaterSystemsInModel = True
            if not allocated(state.dataWaterData.WaterStorage):
                state.dataWaterData.WaterStorage = [None] * state.dataWaterData.NumWaterStorageTanks
                # Need to initialize each tank? The C++ allocates using allocate(N) but doesn't construct elements immediately? Actually allocate calls default constructor. We'll assume later assignments set fields.
                for i in range(state.dataWaterData.NumWaterStorageTanks):
                    state.dataWaterData.WaterStorage[i] = WaterStorageTank()  # need to define

            for Item in range(1, state.dataWaterData.NumWaterStorageTanks + 1):
                state.dataInputProcessing.inputProcessor.getObjectItem(
                    state,
                    cCurrentModuleObject,
                    Item,
                    cAlphaArgs,
                    NumAlphas,
                    rNumericArgs,
                    NumNumbers,
                    IOStatus,
                    _,
                    _,
                    cAlphaFieldNames,
                    cNumericFieldNames,
                )
                let eoh: ErrorObjectHeader = ErrorObjectHeader(
                    routineName, cCurrentModuleObject, cAlphaArgs[0]
                )
                state.dataWaterData.AnyWaterSystemsInModel = True
                state.dataWaterData.WaterStorage[Item - 1].Name = cAlphaArgs[0]
                state.dataWaterData.WaterStorage[Item - 1].QualitySubCategoryName = (
                    cAlphaArgs[1]
                )
                state.dataWaterData.WaterStorage[Item - 1].MaxCapacity = rNumericArgs[0]
                if state.dataWaterData.WaterStorage[Item - 1].MaxCapacity == 0.0:
                    state.dataWaterData.WaterStorage[Item - 1].MaxCapacity = (
                        Constant.BigNumber
                    )
                state.dataWaterData.WaterStorage[Item - 1].InitialVolume = rNumericArgs[1]
                state.dataWaterData.WaterStorage[Item - 1].MaxInFlowRate = rNumericArgs[2]
                if state.dataWaterData.WaterStorage[Item - 1].MaxInFlowRate == 0.0:
                    state.dataWaterData.WaterStorage[Item - 1].MaxInFlowRate = (
                        Constant.BigNumber
                    )
                state.dataWaterData.WaterStorage[Item - 1].MaxOutFlowRate = rNumericArgs[3]
                if state.dataWaterData.WaterStorage[Item - 1].MaxOutFlowRate == 0.0:
                    state.dataWaterData.WaterStorage[Item - 1].MaxOutFlowRate = (
                        Constant.BigNumber
                    )
                state.dataWaterData.WaterStorage[Item - 1].OverflowTankName = cAlphaArgs[2]
                if lAlphaFieldBlanks[3]:
                    ShowSevereEmptyField(state, eoh, cAlphaFieldNames[3])
                    ErrorsFound = True
                else:
                    state.dataWaterData.WaterStorage[Item - 1].ControlSupply = (
                        getEnumValue(controlSupplyTypeNamesUC, cAlphaArgs[3])
                    )
                    if state.dataWaterData.WaterStorage[Item - 1].ControlSupply == -1:
                        ShowSevereInvalidKey(
                            state, eoh, cAlphaFieldNames[3], cAlphaArgs[3]
                        )
                        ErrorsFound = True
                    else:
                        state.dataWaterData.WaterStorage[Item - 1].ControlSupply = (
                            ControlSupplyType(state.dataWaterData.WaterStorage[Item - 1].ControlSupply)  # maybe cast
                        )
                state.dataWaterData.WaterStorage[Item - 1].ValveOnCapacity = rNumericArgs[4]
                state.dataWaterData.WaterStorage[Item - 1].ValveOffCapacity = rNumericArgs[5]
                if (
                    state.dataWaterData.WaterStorage[Item - 1].ControlSupply
                    != ControlSupplyType.NoControlLevel
                ):
                    if (
                        state.dataWaterData.WaterStorage[Item - 1].ValveOffCapacity
                        < state.dataWaterData.WaterStorage[Item - 1].ValveOnCapacity
                    ):
                        ShowSevereError(
                            state,
                            format(
                                "Invalid {} and/or {}",
                                cNumericFieldNames[4],
                                cNumericFieldNames[5],
                            ),
                        )
                        ShowContinueError(
                            state,
                            format(
                                "Entered in {}={}",
                                cCurrentModuleObject,
                                cAlphaArgs[0],
                            ),
                        )
                        ShowContinueError(
                            state,
                            format(
                                "{} must be greater than {}",
                                cNumericFieldNames[5],
                                cNumericFieldNames[4],
                            ),
                        )
                        ShowContinueError(
                            state,
                            format(
                                "Check value for {} = {:.5R}",
                                cNumericFieldNames[4],
                                state.dataWaterData.WaterStorage[Item - 1].ValveOnCapacity,
                            ),
                        )
                        ShowContinueError(
                            state,
                            format(
                                "which must be lower than {} = {:.5R}",
                                cNumericFieldNames[5],
                                state.dataWaterData.WaterStorage[Item - 1].ValveOffCapacity,
                            ),
                        )
                        ErrorsFound = True

                state.dataWaterData.WaterStorage[Item - 1].BackupMainsCapacity = rNumericArgs[6]
                if state.dataWaterData.WaterStorage[Item - 1].BackupMainsCapacity > 0.0:
                    if (
                        state.dataWaterData.WaterStorage[Item - 1].ControlSupply
                        == ControlSupplyType.WellFloatValve
                    ):
                        state.dataWaterData.WaterStorage[Item - 1].ControlSupply = (
                            ControlSupplyType.WellFloatMainsBackup
                        )
                    if (
                        state.dataWaterData.WaterStorage[Item - 1].ControlSupply
                        == ControlSupplyType.OtherTankFloatValve
                    ):
                        state.dataWaterData.WaterStorage[Item - 1].ControlSupply = (
                            ControlSupplyType.TankMainsBackup
                        )

                state.dataWaterData.WaterStorage[Item - 1].SupplyTankName = cAlphaArgs[4]
                if lAlphaFieldBlanks[5]:
                    ShowSevereEmptyField(state, eoh, cAlphaFieldNames[5])
                    ErrorsFound = True
                else:
                    state.dataWaterData.WaterStorage[Item - 1].ThermalMode = (
                        getEnumValue(tankThermalModeNamesUC, cAlphaArgs[5])
                    )
                    if state.dataWaterData.WaterStorage[Item - 1].ThermalMode == -1:
                        ShowSevereItemNotFound(
                            state, eoh, cAlphaFieldNames[5], cAlphaArgs[5]
                        )
                        ErrorsFound = True
                    else:
                        state.dataWaterData.WaterStorage[Item - 1].ThermalMode = (
                            TankThermalMode(state.dataWaterData.WaterStorage[Item - 1].ThermalMode)
                        )

                if (
                    state.dataWaterData.WaterStorage[Item - 1].ThermalMode
                    == TankThermalMode.Scheduled
                ):
                    if lAlphaFieldBlanks[6]:
                        ShowSevereEmptyField(state, eoh, cAlphaFieldNames[6])
                        ErrorsFound = True
                    else:
                        state.dataWaterData.WaterStorage[Item - 1].tempSched = (
                            Sched.GetSchedule(state, cAlphaArgs[6])
                        )
                        if state.dataWaterData.WaterStorage[Item - 1].tempSched is None:
                            ShowSevereItemNotFound(
                                state, eoh, cAlphaFieldNames[6], cAlphaArgs[6]
                            )
                            ErrorsFound = True
                        elif not state.dataWaterData.WaterStorage[Item - 1].tempSched.checkMinMaxVals(
                            state, Clusive.In, 0.0, Clusive.In, 100.0
                        ):
                            Sched.ShowSevereBadMinMax(
                                state,
                                eoh,
                                cAlphaFieldNames[6],
                                cAlphaArgs[6],
                                Clusive.In,
                                0.0,
                                Clusive.In,
                                100.0,
                            )
                            ErrorsFound = True

                if (
                    state.dataWaterData.WaterStorage[Item - 1].ThermalMode
                    == TankThermalMode.ZoneCoupled
                ):
                    if lAlphaFieldBlanks[7]:
                        ShowSevereEmptyField(state, eoh, cAlphaFieldNames[7])
                        ErrorsFound = True
                    else:
                        state.dataWaterData.WaterStorage[Item - 1].AmbientTempIndicator = (
                            getEnumValue(ambientTempTypeNamesUC, cAlphaArgs[7])
                        )
                        if state.dataWaterData.WaterStorage[Item - 1].AmbientTempIndicator == -1:
                            ShowSevereInvalidKey(
                                state, eoh, cAlphaFieldNames[7], cAlphaArgs[7]
                            )
                            ErrorsFound = True
                        else:
                            state.dataWaterData.WaterStorage[Item - 1].AmbientTempIndicator = (
                                AmbientTempType(state.dataWaterData.WaterStorage[Item - 1].AmbientTempIndicator)
                            )
                    if (
                        state.dataWaterData.WaterStorage[Item - 1].AmbientTempIndicator
                        == AmbientTempType.Schedule
                    ):
                        if lAlphaFieldBlanks[8]:
                            ShowSevereEmptyField(state, eoh, cAlphaFieldNames[8])
                            ErrorsFound = True
                        else:
                            state.dataWaterData.WaterStorage[Item - 1].ambientTempSched = (
                                Sched.GetSchedule(state, cAlphaArgs[8])
                            )
                            if (
                                state.dataWaterData.WaterStorage[Item - 1].ambientTempSched
                                is None
                            ):
                                ShowSevereItemNotFound(
                                    state, eoh, cAlphaFieldNames[8], cAlphaArgs[8]
                                )
                                ErrorsFound = True

                    state.dataWaterData.WaterStorage[Item - 1].ZoneID = FindItemInList(
                        cAlphaArgs[9], state.dataHeatBal.Zone
                    )
                    if (
                        state.dataWaterData.WaterStorage[Item - 1].ZoneID == 0
                        and state.dataWaterData.WaterStorage[Item - 1].AmbientTempIndicator
                        == AmbientTempType.Zone
                    ):
                        ShowSevereError(
                            state,
                            format(
                                "Invalid {}={}",
                                cAlphaFieldNames[9],
                                cAlphaArgs[9],
                            ),
                        )
                        ShowContinueError(
                            state,
                            format(
                                "Entered in {}={}",
                                cCurrentModuleObject,
                                cAlphaArgs[0],
                            ),
                        )
                        ErrorsFound = True

                    state.dataWaterData.WaterStorage[Item - 1].SurfArea = rNumericArgs[7]
                    state.dataWaterData.WaterStorage[Item - 1].UValue = rNumericArgs[8]
                    state.dataWaterData.WaterStorage[Item - 1].SurfMaterialName = cAlphaArgs[10]

        cCurrentModuleObject = "WaterUse:RainCollector"
        state.dataWaterData.NumRainCollectors = (
            state.dataInputProcessing.inputProcessor.getNumObjectsFound(
                state, cCurrentModuleObject
            )
        )
        if state.dataWaterData.NumRainCollectors > 0:
            if not allocated(state.dataWaterData.RainCollector):
                state.dataWaterData.RainCollector = [None] * state.dataWaterData.NumRainCollectors
                for i in range(state.dataWaterData.NumRainCollectors):
                    state.dataWaterData.RainCollector[i] = RainCollectorData()
            state.dataWaterData.AnyWaterSystemsInModel = True
            if state.dataWaterData.RainFall.ModeID == 0:
                state.dataWaterData.RainFall.ModeID = RainfallMode.EPWPrecipitation

            for Item in range(1, state.dataWaterData.NumRainCollectors + 1):
                state.dataInputProcessing.inputProcessor.getObjectItem(
                    state,
                    cCurrentModuleObject,
                    Item,
                    cAlphaArgs,
                    NumAlphas,
                    rNumericArgs,
                    NumNumbers,
                    IOStatus,
                    _,
                    _,
                    cAlphaFieldNames,
                    cNumericFieldNames,
                )
                let eoh: ErrorObjectHeader = ErrorObjectHeader(
                    routineName, cCurrentModuleObject, cAlphaArgs[0]
                )
                state.dataWaterData.RainCollector[Item - 1].Name = cAlphaArgs[0]
                state.dataWaterData.RainCollector[Item - 1].StorageTankName = cAlphaArgs[1]
                state.dataWaterData.RainCollector[Item - 1].StorageTankID = FindItemInList(
                    cAlphaArgs[1], state.dataWaterData.WaterStorage
                )
                if state.dataWaterData.RainCollector[Item - 1].StorageTankID == 0:
                    ShowSevereError(
                        state,
                        format(
                            "Invalid {}={}",
                            cAlphaFieldNames[1],
                            cAlphaArgs[1],
                        ),
                    )
                    ShowContinueError(
                        state,
                        format(
                            "Entered in {}={}",
                            cCurrentModuleObject,
                            cAlphaArgs[0],
                        ),
                    )
                    ErrorsFound = True

                if lAlphaFieldBlanks[2]:
                    ShowSevereEmptyField(state, eoh, cAlphaFieldNames[2])
                    ErrorsFound = True
                else:
                    state.dataWaterData.RainCollector[Item - 1].LossFactorMode = (
                        getEnumValue(rainLossFactorNamesUC, cAlphaArgs[2])
                    )
                    if state.dataWaterData.RainCollector[Item - 1].LossFactorMode == -1:
                        ShowSevereInvalidKey(
                            state, eoh, cAlphaFieldNames[2], cAlphaArgs[2]
                        )
                        ErrorsFound = True
                    else:
                        state.dataWaterData.RainCollector[Item - 1].LossFactorMode = (
                            RainLossFactor(state.dataWaterData.RainCollector[Item - 1].LossFactorMode)
                        )

                state.dataWaterData.RainCollector[Item - 1].LossFactor = rNumericArgs[0]
                if state.dataWaterData.RainCollector[Item - 1].LossFactor > 1.0:
                    ShowWarningError(
                        state,
                        format(
                            "Invalid {}={:.2R}",
                            cNumericFieldNames[0],
                            rNumericArgs[0],
                        ),
                    )
                    ShowContinueError(
                        state,
                        format(
                            "Entered in {}={}",
                            cCurrentModuleObject,
                            cAlphaArgs[0],
                        ),
                    )
                    ShowContinueError(
                        state,
                        "found rain water collection loss factor greater than 1.0, simulation continues",
                    )
                if state.dataWaterData.RainCollector[Item - 1].LossFactor < 0.0:
                    ShowSevereError(
                        state,
                        format(
                            "Invalid {}={:.2R}",
                            cNumericFieldNames[0],
                            rNumericArgs[0],
                        ),
                    )
                    ShowContinueError(
                        state,
                        format(
                            "Entered in {}={}",
                            cCurrentModuleObject,
                            cAlphaArgs[0],
                        ),
                    )
                    ShowContinueError(
                        state,
                        "found rain water collection loss factor less than 0.0",
                    )
                    ErrorsFound = True

                if (
                    state.dataWaterData.RainCollector[Item - 1].LossFactorMode
                    == RainLossFactor.Scheduled
                ):
                    if lAlphaFieldBlanks[3]:
                        ShowSevereEmptyField(state, eoh, cAlphaFieldNames[3])
                        ErrorsFound = True
                    else:
                        state.dataWaterData.RainCollector[Item - 1].lossFactorSched = (
                            Sched.GetSchedule(state, cAlphaArgs[3])
                        )
                        if (
                            state.dataWaterData.RainCollector[Item - 1].lossFactorSched
                            is None
                        ):
                            ShowSevereItemNotFound(
                                state, eoh, cAlphaFieldNames[3], cAlphaArgs[3]
                            )
                            ErrorsFound = True
                        elif not state.dataWaterData.RainCollector[
                            Item - 1
                        ].lossFactorSched.checkMinVal(state, Clusive.In, 0.0):
                            Sched.ShowSevereBadMin(
                                state,
                                eoh,
                                cAlphaFieldNames[3],
                                cAlphaArgs[3],
                                Clusive.In,
                                0.0,
                            )
                            ErrorsFound = True
                        elif not state.dataWaterData.RainCollector[
                            Item - 1
                        ].lossFactorSched.checkMaxVal(state, Clusive.In, 1.0):
                            Sched.ShowWarningBadMax(
                                state,
                                eoh,
                                cAlphaFieldNames[3],
                                cAlphaArgs[3],
                                Clusive.In,
                                1.0,
                                "",
                            )

                state.dataWaterData.RainCollector[Item - 1].MaxCollectRate = rNumericArgs[1]
                if state.dataWaterData.RainCollector[Item - 1].MaxCollectRate == 0.0:
                    state.dataWaterData.RainCollector[Item - 1].MaxCollectRate = 100000000000.0

                let alphaOffset: Int = 4
                state.dataWaterData.RainCollector[Item - 1].NumCollectSurfs = (
                    NumAlphas - alphaOffset
                )
                state.dataWaterData.RainCollector[Item - 1].SurfName = [""] * state.dataWaterData.RainCollector[Item - 1].NumCollectSurfs
                state.dataWaterData.RainCollector[Item - 1].SurfID = [0] * state.dataWaterData.RainCollector[Item - 1].NumCollectSurfs

                for SurfNum in range(1, state.dataWaterData.RainCollector[Item - 1].NumCollectSurfs + 1):
                    state.dataWaterData.RainCollector[Item - 1].SurfName[SurfNum - 1] = (
                        cAlphaArgs[SurfNum + alphaOffset - 1]
                    )
                    state.dataWaterData.RainCollector[Item - 1].SurfID[SurfNum - 1] = (
                        FindItemInList(
                            cAlphaArgs[SurfNum + alphaOffset - 1],
                            state.dataSurface.Surface,
                        )
                    )
                    if (
                        state.dataWaterData.RainCollector[Item - 1].SurfID[SurfNum - 1]
                        == 0
                    ):
                        ShowSevereError(
                            state,
                            format(
                                "Invalid {}={}",
                                cAlphaFieldNames[SurfNum + alphaOffset - 1],
                                cAlphaArgs[SurfNum + alphaOffset - 1],
                            ),
                        )
                        ShowContinueError(
                            state,
                            format(
                                "Entered in {}={}",
                                cCurrentModuleObject,
                                cAlphaArgs[0],
                            ),
                        )
                        ErrorsFound = True

                var tmpArea: Float64 = 0.0
                var tmpNumerator: Float64 = 0.0
                var tmpDenominator: Float64 = 0.0
                for SurfNum in range(1, state.dataWaterData.RainCollector[Item - 1].NumCollectSurfs + 1):
                    let ThisSurf: Int = (
                        state.dataWaterData.RainCollector[Item - 1].SurfID[SurfNum - 1]
                    )
                    tmpArea += (
                        state.dataSurface.Surface[ThisSurf - 1].GrossArea
                        * state.dataSurface.Surface[ThisSurf - 1].CosTilt
                    )
                    tmpNumerator += (
                        state.dataSurface.Surface[ThisSurf - 1].Centroid.z
                        * state.dataSurface.Surface[ThisSurf - 1].GrossArea
                    )
                    tmpDenominator += state.dataSurface.Surface[ThisSurf - 1].GrossArea

                state.dataWaterData.RainCollector[Item - 1].HorizArea = tmpArea
                state.dataWaterData.RainCollector[Item - 1].MeanHeight = (
                    tmpNumerator / tmpDenominator
                )

                InternalSetupTankSupplyComponent(
                    state,
                    state.dataWaterData.RainCollector[Item - 1].Name,
                    cCurrentModuleObject,
                    state.dataWaterData.RainCollector[Item - 1].StorageTankName,
                    ErrorsFound,
                    state.dataWaterData.RainCollector[Item - 1].StorageTankID,
                    state.dataWaterData.RainCollector[Item - 1].StorageTankSupplyARRID,
                )

        cCurrentModuleObject = "WaterUse:Well"
        state.dataWaterData.NumGroundWaterWells = (
            state.dataInputProcessing.inputProcessor.getNumObjectsFound(
                state, cCurrentModuleObject
            )
        )
        if state.dataWaterData.NumGroundWaterWells > 0:
            state.dataWaterData.AnyWaterSystemsInModel = True
            state.dataWaterData.GroundwaterWell = [None] * state.dataWaterData.NumGroundWaterWells
            for i in range(state.dataWaterData.NumGroundWaterWells):
                state.dataWaterData.GroundwaterWell[i] = GroundwaterWellData()
            for Item in range(1, state.dataWaterData.NumGroundWaterWells + 1):
                state.dataInputProcessing.inputProcessor.getObjectItem(
                    state,
                    cCurrentModuleObject,
                    Item,
                    cAlphaArgs,
                    NumAlphas,
                    rNumericArgs,
                    NumNumbers,
                    IOStatus,
                    _,
                    lAlphaFieldBlanks,
                    cAlphaFieldNames,
                    cNumericFieldNames,
                )
                let eoh: ErrorObjectHeader = ErrorObjectHeader(
                    routineName, cCurrentModuleObject, cAlphaArgs[0]
                )
                state.dataWaterData.GroundwaterWell[Item - 1].Name = cAlphaArgs[0]
                state.dataWaterData.GroundwaterWell[Item - 1].StorageTankName = cAlphaArgs[1]
                InternalSetupTankSupplyComponent(
                    state,
                    state.dataWaterData.GroundwaterWell[Item - 1].Name,
                    cCurrentModuleObject,
                    state.dataWaterData.GroundwaterWell[Item - 1].StorageTankName,
                    ErrorsFound,
                    state.dataWaterData.GroundwaterWell[Item - 1].StorageTankID,
                    state.dataWaterData.GroundwaterWell[Item - 1].StorageTankSupplyARRID,
                )
                if allocated(state.dataWaterData.WaterStorage):
                    state.dataWaterData.WaterStorage[
                        state.dataWaterData.GroundwaterWell[Item - 1].StorageTankID - 1
                    ].GroundWellID = Item

                state.dataWaterData.GroundwaterWell[Item - 1].PumpDepth = rNumericArgs[0]
                state.dataWaterData.GroundwaterWell[Item - 1].PumpNomVolFlowRate = rNumericArgs[1]
                state.dataWaterData.GroundwaterWell[Item - 1].PumpNomHead = rNumericArgs[2]
                state.dataWaterData.GroundwaterWell[Item - 1].PumpNomPowerUse = rNumericArgs[3]
                state.dataWaterData.GroundwaterWell[Item - 1].PumpEfficiency = rNumericArgs[4]
                state.dataWaterData.GroundwaterWell[Item - 1].WellRecoveryRate = rNumericArgs[5]
                state.dataWaterData.GroundwaterWell[Item - 1].NomWellStorageVol = rNumericArgs[6]

                if lAlphaFieldBlanks[2]:

                else:
                    state.dataWaterData.GroundwaterWell[Item - 1].GroundwaterTableMode = (
                        getEnumValue(groundWaterTableNamesUC, cAlphaArgs[2])
                    )
                    if state.dataWaterData.GroundwaterWell[Item - 1].GroundwaterTableMode == -1:
                        ShowSevereInvalidKey(
                            state, eoh, cAlphaFieldNames[2], cAlphaArgs[2]
                        )
                        ErrorsFound = True
                    else:
                        state.dataWaterData.GroundwaterWell[Item - 1].GroundwaterTableMode = (
                            GroundWaterTable(state.dataWaterData.GroundwaterWell[Item - 1].GroundwaterTableMode)
                        )

                state.dataWaterData.GroundwaterWell[Item - 1].WaterTableDepth = rNumericArgs[7]

                if (
                    state.dataWaterData.GroundwaterWell[Item - 1].GroundwaterTableMode
                    == GroundWaterTable.Scheduled
                ):
                    if lAlphaFieldBlanks[3]:
                        ShowSevereEmptyField(state, eoh, cAlphaFieldNames[3])
                        ErrorsFound = True
                    else:
                        state.dataWaterData.GroundwaterWell[Item - 1].waterTableDepthSched = (
                            Sched.GetSchedule(state, cAlphaArgs[3])
                        )
                        if (
                            state.dataWaterData.GroundwaterWell[Item - 1].waterTableDepthSched
                            is None
                        ):
                            ShowSevereItemNotFound(
                                state, eoh, cAlphaFieldNames[3], cAlphaArgs[3]
                            )
                            ErrorsFound = True

        cCurrentModuleObject = "WaterUse:Storage"
        if state.dataWaterData.NumWaterStorageTanks > 0:
            for Item in range(1, state.dataWaterData.NumWaterStorageTanks + 1):
                if (
                    state.dataWaterData.WaterStorage[Item - 1].ControlSupply
                    == ControlSupplyType.WellFloatValve
                    or state.dataWaterData.WaterStorage[Item - 1].ControlSupply
                    == ControlSupplyType.WellFloatMainsBackup
                ):
                    if state.dataWaterData.WaterStorage[Item - 1].GroundWellID == 0:
                        ShowSevereError(
                            state,
                            format(
                                "{}= \"{}\" does not have a WaterUse:Well (groundwater well) that names it.",
                                cCurrentModuleObject,
                                state.dataWaterData.WaterStorage[Item - 1].Name,
                            ),
                        )
                        ErrorsFound = True

                if (
                    state.dataWaterData.WaterStorage[Item - 1].ControlSupply
                    == ControlSupplyType.OtherTankFloatValve
                    or state.dataWaterData.WaterStorage[Item - 1].ControlSupply
                    == ControlSupplyType.TankMainsBackup
                ):
                    var Dummy: Int = 0
                    state.dataWaterData.WaterStorage[Item - 1].SupplyTankID = (
                        FindItemInList(
                            state.dataWaterData.WaterStorage[Item - 1].SupplyTankName,
                            state.dataWaterData.WaterStorage,
                        )
                    )
                    if state.dataWaterData.WaterStorage[Item - 1].SupplyTankID == 0:
                        ShowSevereError(
                            state,
                            format(
                                "Other tank called {} not found for {} Named {}",
                                state.dataWaterData.WaterStorage[Item - 1].SupplyTankName,
                                cCurrentModuleObject,
                                state.dataWaterData.WaterStorage[Item - 1].Name,
                            ),
                        )
                        ErrorsFound = True

                    InternalSetupTankDemandComponent(
                        state,
                        state.dataWaterData.WaterStorage[Item - 1].Name,
                        cCurrentModuleObject,
                        state.dataWaterData.WaterStorage[Item - 1].SupplyTankName,
                        ErrorsFound,
                        state.dataWaterData.WaterStorage[Item - 1].SupplyTankID,
                        state.dataWaterData.WaterStorage[Item - 1].SupplyTankDemandARRID,
                    )
                    InternalSetupTankSupplyComponent(
                        state,
                        state.dataWaterData.WaterStorage[Item - 1].SupplyTankName,
                        cCurrentModuleObject,
                        state.dataWaterData.WaterStorage[Item - 1].Name,
                        ErrorsFound,
                        Dummy,
                        Dummy,
                    )

                state.dataWaterData.WaterStorage[Item - 1].OverflowTankID = FindItemInList(
                    state.dataWaterData.WaterStorage[Item - 1].OverflowTankName,
                    state.dataWaterData.WaterStorage,
                )
                if state.dataWaterData.WaterStorage[Item - 1].OverflowTankID == 0:
                    if is_blank(
                        state.dataWaterData.WaterStorage[Item - 1].OverflowTankName
                    ):
                        state.dataWaterData.WaterStorage[Item - 1].OverflowMode = (
                            Overflow.Discarded
                        )
                    else:
                        ShowSevereError(
                            state,
                            format(
                                "Overflow tank name of {} not found for {} Named {}",
                                state.dataWaterData.WaterStorage[Item - 1].OverflowTankName,
                                cCurrentModuleObject,
                                state.dataWaterData.WaterStorage[Item - 1].Name,
                            ),
                        )
                        ErrorsFound = True
                else:
                    state.dataWaterData.WaterStorage[Item - 1].OverflowMode = (
                        Overflow.ToTank
                    )

                if (
                    state.dataWaterData.WaterStorage[Item - 1].OverflowMode
                    == Overflow.ToTank
                ):
                    InternalSetupTankSupplyComponent(
                        state,
                        state.dataWaterData.WaterStorage[Item - 1].Name,
                        cCurrentModuleObject,
                        state.dataWaterData.WaterStorage[Item - 1].OverflowTankName,
                        ErrorsFound,
                        state.dataWaterData.WaterStorage[Item - 1].OverflowTankID,
                        state.dataWaterData.WaterStorage[Item - 1].OverflowTankSupplyARRID,
                    )

        cCurrentModuleObject = "Site:Precipitation"
        state.dataWaterData.NumSiteRainFall = (
            state.dataInputProcessing.inputProcessor.getNumObjectsFound(
                state, cCurrentModuleObject
            )
        )
        if state.dataWaterData.NumSiteRainFall > 1:
            ShowSevereError(
                state,
                format("Only one {} object is allowed", cCurrentModuleObject),
            )
            ErrorsFound = True

        if state.dataWaterData.NumSiteRainFall == 1:
            state.dataWaterData.AnyWaterSystemsInModel = True
            state.dataInputProcessing.inputProcessor.getObjectItem(
                state,
                cCurrentModuleObject,
                1,
                cAlphaArgs,
                NumAlphas,
                rNumericArgs,
                NumNumbers,
                IOStatus,
            )
            let eoh: ErrorObjectHeader = ErrorObjectHeader(
                routineName, cCurrentModuleObject, cAlphaArgs[0]
            )
            if SameString(cAlphaArgs[0], "ScheduleAndDesignLevel"):
                state.dataWaterData.RainFall.ModeID = RainfallMode.RainSchedDesign
            else:
                ShowSevereError(
                    state,
                    format(
                        "Precipitation Model Type of {} is incorrect.",
                        cCurrentModuleObject,
                    ),
                )
                ShowContinueError(
                    state, "Only available option is ScheduleAndDesignLevel."
                )
                ErrorsFound = True

            if state.dataWaterData.RainFall.ModeID == RainfallMode.RainSchedDesign:
                if lAlphaFieldBlanks[1]:
                    ShowSevereEmptyField(state, eoh, cAlphaFieldNames[1])
                    ErrorsFound = True
                else:
                    state.dataWaterData.RainFall.rainSched = Sched.GetSchedule(
                        state, cAlphaArgs[1]
                    )
                    if state.dataWaterData.RainFall.rainSched is None:
                        ShowSevereItemNotFound(
                            state, eoh, cAlphaFieldNames[1], cAlphaArgs[1]
                        )
                        ErrorsFound = True
                    elif not state.dataWaterData.RainFall.rainSched.checkMinVal(
                        state, Clusive.In, 0.0
                    ):
                        Sched.ShowSevereBadMin(
                            state,
                            eoh,
                            cAlphaFieldNames[1],
                            cAlphaArgs[1],
                            Clusive.In,
                            0.0,
                        )
                        ErrorsFound = True

            state.dataWaterData.RainFall.DesignAnnualRain = rNumericArgs[0]
            state.dataWaterData.RainFall.NomAnnualRain = rNumericArgs[1]

        cCurrentModuleObject = "RoofIrrigation"
        NumIrrigation = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
            state, cCurrentModuleObject
        )
        if NumIrrigation > 1:
            ShowSevereError(
                state,
                format("Only one {} object is allowed", cCurrentModuleObject),
            )
            ErrorsFound = True

        if NumIrrigation == 1:
            state.dataWaterData.AnyIrrigationInModel = True
            state.dataInputProcessing.inputProcessor.getObjectItem(
                state,
                cCurrentModuleObject,
                1,
                cAlphaArgs,
                NumAlphas,
                rNumericArgs,
                NumNumbers,
                IOStatus,
            )
            let eoh: ErrorObjectHeader = ErrorObjectHeader(
                routineName, cCurrentModuleObject, cAlphaArgs[0]
            )
            if lAlphaFieldBlanks[0]:
                ShowSevereEmptyField(state, eoh, cAlphaFieldNames[0])
                ErrorsFound = True
            else:
                state.dataWaterData.Irrigation.ModeID = getEnumValue(
                    irrigationModeNamesUC, cAlphaArgs[0]
                )
                if state.dataWaterData.Irrigation.ModeID == -1:
                    ShowSevereInvalidKey(
                        state, eoh, cAlphaFieldNames[0], cAlphaArgs[0]
                    )
                    ErrorsFound = True
                else:
                    state.dataWaterData.Irrigation.ModeID = IrrigationMode(state.dataWaterData.Irrigation.ModeID)

            if state.dataWaterData.RainFall.ModeID == 0:
                state.dataWaterData.RainFall.ModeID = RainfallMode.EPWPrecipitation

            if (
                state.dataWaterData.Irrigation.ModeID == IrrigationMode.SchedDesign
                or state.dataWaterData.Irrigation.ModeID
                == IrrigationMode.SmartSched
            ):
                if lAlphaFieldBlanks[1]:
                    ShowSevereEmptyField(state, eoh, cAlphaFieldNames[1])
                    ErrorsFound = True
                else:
                    state.dataWaterData.Irrigation.irrSched = Sched.GetSchedule(
                        state, cAlphaArgs[1]
                    )
                    if state.dataWaterData.Irrigation.irrSched is None:
                        ShowSevereItemNotFound(
                            state, eoh, cAlphaFieldNames[1], cAlphaArgs[1]
                        )
                        ErrorsFound = True
                    elif not state.dataWaterData.Irrigation.irrSched.checkMinVal(
                        state, Clusive.In, 0.0
                    ):
                        Sched.ShowSevereBadMin(
                            state,
                            eoh,
                            cAlphaFieldNames[1],
                            cAlphaArgs[1],
                            Clusive.In,
                            0.0,
                        )
                        ErrorsFound = True

            state.dataWaterData.Irrigation.IrrigationThreshold = 0.4
            if (
                state.dataWaterData.Irrigation.ModeID == IrrigationMode.SmartSched
                and NumNumbers > 0
            ):
                if rNumericArgs[0] > 100.0 or rNumericArgs[0] < 0.0:
                    ShowSevereError(
                        state,
                        format(
                            "Irrigation threshold for {} object has values > 100 or < 0.",
                            cCurrentModuleObject,
                        ),
                    )
                    ErrorsFound = True
                else:
                    state.dataWaterData.Irrigation.IrrigationThreshold = (
                        rNumericArgs[0] / 100.0
                    )

        if state.dataWaterData.RainFall.ModeID == RainfallMode.EPWPrecipitation:
            ShowWarningError(
                state,
                "Precipitation depth from the weather file will be used. Please make sure this .epw field has valid data. Site:Precipitation may be used to override the weather file data.",
            )

        state.dataWaterData.AnyWaterSystemsInModel = True
        state.dataWaterData.WaterSystemGetInputCalled = True
        state.dataWaterManager.MyOneTimeFlag = False

        cAlphaFieldNames = []
        cAlphaArgs = []
        lAlphaFieldBlanks = []
        cNumericFieldNames = []
        rNumericArgs = []
        lNumericFieldBlanks = []

        if ErrorsFound:
            ShowFatalError(
                state, "Errors found in processing input for water manager objects"
            )

        for Item in range(1, state.dataWaterData.NumWaterStorageTanks + 1):
            SetupOutputVariable(
                state,
                "Water System Storage Tank Volume",
                Constant.Units.m3,
                state.dataWaterData.WaterStorage[Item - 1].ThisTimeStepVolume,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                state.dataWaterData.WaterStorage[Item - 1].Name,
            )
            SetupOutputVariable(
                state,
                "Water System Storage Tank Net Volume Flow Rate",
                Constant.Units.m3_s,
                state.dataWaterData.WaterStorage[Item - 1].NetVdot,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                state.dataWaterData.WaterStorage[Item - 1].Name,
            )
            SetupOutputVariable(
                state,
                "Water System Storage Tank Inlet Volume Flow Rate",
                Constant.Units.m3_s,
                state.dataWaterData.WaterStorage[Item - 1].VdotToTank,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                state.dataWaterData.WaterStorage[Item - 1].Name,
            )
            SetupOutputVariable(
                state,
                "Water System Storage Tank Outlet Volume Flow Rate",
                Constant.Units.m3_s,
                state.dataWaterData.WaterStorage[Item - 1].VdotFromTank,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                state.dataWaterData.WaterStorage[Item - 1].Name,
            )
            SetupOutputVariable(
                state,
                "Water System Storage Tank Mains Water Volume",
                Constant.Units.m3,
                state.dataWaterData.WaterStorage[Item - 1].MainsDrawVol,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Sum,
                state.dataWaterData.WaterStorage[Item - 1].Name,
                Constant.eResource.MainsWater,
                OutputProcessor.Group.HVAC,
                OutputProcessor.EndUseCat.WaterSystem,
                state.dataWaterData.WaterStorage[Item - 1].QualitySubCategoryName,
            )
            SetupOutputVariable(
                state,
                "Water System Storage Tank Mains Water Volume Flow Rate",
                Constant.Units.m3_s,
                state.dataWaterData.WaterStorage[Item - 1].MainsDrawVdot,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                state.dataWaterData.WaterStorage[Item - 1].Name,
            )
            SetupOutputVariable(
                state,
                "Water System Storage Tank Water Temperature",
                Constant.Units.C,
                state.dataWaterData.WaterStorage[Item - 1].Twater,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                state.dataWaterData.WaterStorage[Item - 1].Name,
            )
            SetupOutputVariable(
                state,
                "Water System Storage Tank Overflow Volume Flow Rate",
                Constant.Units.m3_s,
                state.dataWaterData.WaterStorage[Item - 1].VdotOverflow,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                state.dataWaterData.WaterStorage[Item - 1].Name,
            )
            if (
                state.dataWaterData.WaterStorage[Item - 1].OverflowMode
                == Overflow.Discarded
            ):
                SetupOutputVariable(
                    state,
                    "Water System Storage Tank Overflow Water Volume",
                    Constant.Units.m3,
                    state.dataWaterData.WaterStorage[Item - 1].VolOverflow,
                    OutputProcessor.TimeStepType.System,
                    OutputProcessor.StoreType.Sum,
                    state.dataWaterData.WaterStorage[Item - 1].Name,
                )
            else:
                SetupOutputVariable(
                    state,
                    "Water System Storage Tank Overflow Water Volume",
                    Constant.Units.m3,
                    state.dataWaterData.WaterStorage[Item - 1].VolOverflow,
                    OutputProcessor.TimeStepType.System,
                    OutputProcessor.StoreType.Sum,
                    state.dataWaterData.WaterStorage[Item - 1].Name,
                )
            SetupOutputVariable(
                state,
                "Water System Storage Tank Overflow Temperature",
                Constant.Units.C,
                state.dataWaterData.WaterStorage[Item - 1].TwaterOverflow,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                state.dataWaterData.WaterStorage[Item - 1].Name,
            )

        if NumIrrigation == 1:
            SetupOutputVariable(
                state,
                "Water System Roof Irrigation Scheduled Depth",
                Constant.Units.m,
                state.dataWaterData.Irrigation.ScheduledAmount,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Sum,
                "RoofIrrigation",
            )
            SetupOutputVariable(
                state,
                "Water System Roof Irrigation Actual Depth",
                Constant.Units.m,
                state.dataWaterData.Irrigation.ActualAmount,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Sum,
                "RoofIrrigation",
            )

        for Item in range(1, state.dataWaterData.NumRainCollectors + 1):
            SetupOutputVariable(
                state,
                "Water System Rainwater Collector Volume Flow Rate",
                Constant.Units.m3_s,
                state.dataWaterData.RainCollector[Item - 1].VdotAvail,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                state.dataWaterData.RainCollector[Item - 1].Name,
            )
            SetupOutputVariable(
                state,
                "Water System Rainwater Collector Volume",
                Constant.Units.m3,
                state.dataWaterData.RainCollector[Item - 1].VolCollected,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Sum,
                state.dataWaterData.RainCollector[Item - 1].Name,
                Constant.eResource.OnSiteWater,
                OutputProcessor.Group.HVAC,
                OutputProcessor.EndUseCat.RainWater,
            )

        for Item in range(1, state.dataWaterData.NumGroundWaterWells + 1):
            SetupOutputVariable(
                state,
                "Water System Groundwater Well Requested Volume Flow Rate",
                Constant.Units.m3_s,
                state.dataWaterData.GroundwaterWell[Item - 1].VdotRequest,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                state.dataWaterData.GroundwaterWell[Item - 1].Name,
            )
            SetupOutputVariable(
                state,
                "Water System Groundwater Well Volume Flow Rate",
                Constant.Units.m3_s,
                state.dataWaterData.GroundwaterWell[Item - 1].VdotDelivered,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                state.dataWaterData.GroundwaterWell[Item - 1].Name,
            )
            SetupOutputVariable(
                state,
                "Water System Groundwater Well Volume",
                Constant.Units.m3,
                state.dataWaterData.GroundwaterWell[Item - 1].VolDelivered,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Sum,
                state.dataWaterData.GroundwaterWell[Item - 1].Name,
                Constant.eResource.OnSiteWater,
                OutputProcessor.Group.HVAC,
                OutputProcessor.EndUseCat.WellWater,
            )
            SetupOutputVariable(
                state,
                "Water System Groundwater Well Pump Electricity Rate",
                Constant.Units.W,
                state.dataWaterData.GroundwaterWell[Item - 1].PumpPower,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                state.dataWaterData.GroundwaterWell[Item - 1].Name,
            )
            SetupOutputVariable(
                state,
                "Water System Groundwater Well Pump Electricity Energy",
                Constant.Units.J,
                state.dataWaterData.GroundwaterWell[Item - 1].PumpEnergy,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Sum,
                state.dataWaterData.GroundwaterWell[Item - 1].Name,
                Constant.eResource.Electricity,
                OutputProcessor.Group.HVAC,
                OutputProcessor.EndUseCat.WaterSystem,
            )

def UpdatePrecipitation(state: EnergyPlusData):
    var schedRate: Float64
    var ScaleFactor: Float64
    if state.dataWaterData.RainFall.ModeID == RainfallMode.RainSchedDesign:
        schedRate = state.dataWaterData.RainFall.rainSched.getCurrentVal()  # m/hr
        if state.dataWaterData.RainFall.NomAnnualRain > 0.0:
            ScaleFactor = (
                state.dataWaterData.RainFall.DesignAnnualRain
                / state.dataWaterData.RainFall.NomAnnualRain
            )
        else:
            ScaleFactor = 0.0
        state.dataWaterData.RainFall.CurrentRate = (
            schedRate * ScaleFactor / Constant.rSecsInHour
        )  # convert to m/s
    else:
        if state.dataEnvrn.LiquidPrecipitation > 0.0:
            state.dataWaterData.RainFall.CurrentRate = (
                state.dataEnvrn.LiquidPrecipitation / state.dataGlobal.TimeStepZoneSec
            )
        else:
            state.dataWaterData.RainFall.CurrentRate = 0.0
    state.dataWaterData.RainFall.CurrentAmount = (
        state.dataWaterData.RainFall.CurrentRate * state.dataGlobal.TimeStepZoneSec
    )
    state.dataEcoRoofMgr.CurrentPrecipitation = (
        state.dataWaterData.RainFall.CurrentAmount
    )  # units of m
    if state.dataWaterData.RainFall.ModeID == RainfallMode.RainSchedDesign:
        if (state.dataEnvrn.RunPeriodEnvironment) and (not state.dataGlobal.WarmupFlag):
            let month: Int = state.dataEnvrn.Month
            state.dataWaterData.RainFall.MonthlyTotalPrecInSitePrec[month - 1] += (
                state.dataWaterData.RainFall.CurrentAmount * 1000.0
            )

def UpdateIrrigation(state: EnergyPlusData):
    let TimeStepSys: Float64 = state.dataHVACGlobal.TimeStepSys
    var schedRate: Float64
    state.dataWaterData.Irrigation.ScheduledAmount = 0.0
    if state.dataWaterData.Irrigation.ModeID == IrrigationMode.SchedDesign:
        schedRate = state.dataWaterData.Irrigation.irrSched.getCurrentVal()  # m/hr
        state.dataWaterData.Irrigation.ScheduledAmount = (
            schedRate * TimeStepSys
        )  # convert to m/timestep
    elif state.dataWaterData.Irrigation.ModeID == IrrigationMode.SmartSched:
        schedRate = state.dataWaterData.Irrigation.irrSched.getCurrentVal()  # m/hr
        state.dataWaterData.Irrigation.ScheduledAmount = (
            schedRate * TimeStepSys
        )  # convert to m/timestep

def CalcWaterStorageTank(state: EnergyPlusData, TankNum: Int):
    let TimeStepSysSec: Float64 = state.dataHVACGlobal.TimeStepSysSec
    var OrigVdotDemandRequest: Float64 = 0.0
    var TotVdotDemandAvail: Float64 = 0.0
    var OrigVolDemandRequest: Float64 = 0.0
    var TotVolDemandAvail: Float64 = 0.0
    var OrigVdotSupplyAvail: Float64 = 0.0
    var TotVdotSupplyAvail: Float64 = 0.0
    var TotVolSupplyAvail: Float64 = 0.0
    var overflowVdot: Float64 = 0.0
    var overflowVol: Float64 = 0.0
    var NetVdotAdd: Float64 = 0.0
    var NetVolAdd: Float64 = 0.0
    var FillVolRequest: Float64 = 0.0
    var TotVolAllowed: Float64 = 0.0
    var underflowVdot: Float64 = 0.0
    var VolumePredict: Float64 = 0.0

    if state.dataGlobal.BeginTimeStepFlag:

    overflowVdot = 0.0
    if state.dataWaterData.WaterStorage[TankNum - 1].NumWaterSupplies > 0:
        OrigVdotSupplyAvail = sum(
            state.dataWaterData.WaterStorage[TankNum - 1].VdotAvailSupply
        )
    else:
        OrigVdotSupplyAvail = 0.0

    TotVdotSupplyAvail = OrigVdotSupplyAvail
    if (
        TotVdotSupplyAvail
        > state.dataWaterData.WaterStorage[TankNum - 1].MaxInFlowRate
    ):
        overflowVdot = (
            TotVdotSupplyAvail
            - state.dataWaterData.WaterStorage[TankNum - 1].MaxInFlowRate
        )
        state.dataWaterManager.overflowTwater = (
            sum(
                v * t
                for v, t in zip(
                    state.dataWaterData.WaterStorage[TankNum - 1].VdotAvailSupply,
                    state.dataWaterData.WaterStorage[TankNum - 1].TwaterSupply,
                )
            )
            / sum(state.dataWaterData.WaterStorage[TankNum - 1].VdotAvailSupply)
        )
        TotVdotSupplyAvail = state.dataWaterData.WaterStorage[TankNum - 1].MaxInFlowRate

    TotVolSupplyAvail = TotVdotSupplyAvail * TimeStepSysSec
    overflowVol = overflowVdot * TimeStepSysSec

    underflowVdot = 0.0
    if state.dataWaterData.WaterStorage[TankNum - 1].NumWaterDemands > 0:
        OrigVdotDemandRequest = sum(
            state.dataWaterData.WaterStorage[TankNum - 1].VdotRequestDemand
        )
    else:
        OrigVdotDemandRequest = 0.0

    OrigVolDemandRequest = OrigVdotDemandRequest * TimeStepSysSec
    TotVdotDemandAvail = OrigVdotDemandRequest
    if (
        TotVdotDemandAvail
        > state.dataWaterData.WaterStorage[TankNum - 1].MaxOutFlowRate
    ):
        underflowVdot = (
            OrigVdotDemandRequest
            - state.dataWaterData.WaterStorage[TankNum - 1].MaxOutFlowRate
        )
        TotVdotDemandAvail = state.dataWaterData.WaterStorage[TankNum - 1].MaxOutFlowRate

    TotVolDemandAvail = TotVdotDemandAvail * TimeStepSysSec

    NetVdotAdd = TotVdotSupplyAvail - TotVdotDemandAvail
    NetVolAdd = NetVdotAdd * TimeStepSysSec

    VolumePredict = (
        state.dataWaterData.WaterStorage[TankNum - 1].LastTimeStepVolume + NetVolAdd
    )

    TotVolAllowed = (
        state.dataWaterData.WaterStorage[TankNum - 1].MaxCapacity
        - state.dataWaterData.WaterStorage[TankNum - 1].LastTimeStepVolume
    )

    if VolumePredict > state.dataWaterData.WaterStorage[TankNum - 1].MaxCapacity:
        let OverFillVolume: Float64 = (
            VolumePredict - state.dataWaterData.WaterStorage[TankNum - 1].MaxCapacity
        )
        state.dataWaterManager.overflowTwater = (
            (
                state.dataWaterManager.overflowTwater * overflowVol
                + OverFillVolume * state.dataWaterData.WaterStorage[TankNum - 1].Twater
            )
            / (overflowVol + OverFillVolume)
        )
        overflowVol += OverFillVolume
        NetVolAdd -= OverFillVolume
        NetVdotAdd = NetVolAdd / TimeStepSysSec
        VolumePredict = state.dataWaterData.WaterStorage[TankNum - 1].MaxCapacity

    if VolumePredict < 0.0:
        var AvailVolume: Float64 = (
            state.dataWaterData.WaterStorage[TankNum - 1].LastTimeStepVolume
            + TotVolSupplyAvail
        )
        AvailVolume = max(0.0, AvailVolume)
        TotVolDemandAvail = AvailVolume
        TotVdotDemandAvail = AvailVolume / TimeStepSysSec
        underflowVdot = OrigVdotDemandRequest - TotVdotDemandAvail
        NetVdotAdd = TotVdotSupplyAvail - TotVdotDemandAvail
        NetVolAdd = NetVdotAdd * TimeStepSysSec
        VolumePredict = 0.0

    if TotVdotDemandAvail < OrigVdotDemandRequest:
        if OrigVdotDemandRequest > 0.0:
            state.dataWaterData.WaterStorage[TankNum - 1].VdotAvailDemand = [
                (TotVdotDemandAvail / OrigVdotDemandRequest) * v
                for v in state.dataWaterData.WaterStorage[TankNum - 1].VdotRequestDemand
            ]
        else:
            state.dataWaterData.WaterStorage[TankNum - 1].VdotAvailDemand = [0.0] * len(
                state.dataWaterData.WaterStorage[TankNum - 1].VdotRequestDemand
            )
    else:
        if state.dataWaterData.WaterStorage[TankNum - 1].NumWaterDemands > 0:
            state.dataWaterData.WaterStorage[TankNum - 1].VdotAvailDemand = (
                state.dataWaterData.WaterStorage[TankNum - 1].VdotRequestDemand[:]
            )

    FillVolRequest = 0.0
    if (VolumePredict < state.dataWaterData.WaterStorage[TankNum - 1].ValveOnCapacity) or state.dataWaterData.WaterStorage[TankNum - 1].LastTimeStepFilling:
        FillVolRequest = (
            state.dataWaterData.WaterStorage[TankNum - 1].ValveOffCapacity
            - VolumePredict
        )
        state.dataWaterData.WaterStorage[TankNum - 1].LastTimeStepFilling = True
        if (
            state.dataWaterData.WaterStorage[TankNum - 1].ControlSupply
            == ControlSupplyType.MainsFloatValve
        ):
            state.dataWaterData.WaterStorage[TankNum - 1].MainsDrawVdot = (
                FillVolRequest / TimeStepSysSec
            )
            NetVolAdd = FillVolRequest
        if (
            state.dataWaterData.WaterStorage[TankNum - 1].ControlSupply
            == ControlSupplyType.OtherTankFloatValve
            or state.dataWaterData.WaterStorage[TankNum - 1].ControlSupply
            == ControlSupplyType.TankMainsBackup
        ):
            state.dataWaterData.WaterStorage[
                state.dataWaterData.WaterStorage[TankNum - 1].SupplyTankID - 1
            ].VdotRequestDemand[
                state.dataWaterData.WaterStorage[TankNum - 1].SupplyTankDemandARRID - 1
            ] = (
                FillVolRequest / TimeStepSysSec
            )
        if (
            state.dataWaterData.WaterStorage[TankNum - 1].ControlSupply
            == ControlSupplyType.WellFloatValve
            or state.dataWaterData.WaterStorage[TankNum - 1].ControlSupply
            == ControlSupplyType.WellFloatMainsBackup
        ):
            state.dataWaterData.GroundwaterWell[
                state.dataWaterData.WaterStorage[TankNum - 1].GroundWellID - 1
            ].VdotRequest = (
                FillVolRequest / TimeStepSysSec
            )

    if VolumePredict < state.dataWaterData.WaterStorage[TankNum - 1].BackupMainsCapacity:
        if (
            state.dataWaterData.WaterStorage[TankNum - 1].ControlSupply
            == ControlSupplyType.WellFloatMainsBackup
            or state.dataWaterData.WaterStorage[TankNum - 1].ControlSupply
            == ControlSupplyType.TankMainsBackup
        ):
            FillVolRequest = (
                state.dataWaterData.WaterStorage[TankNum