from builtin import InlineArray

alias MANAGER_NAMES_UC = InlineArray[StringRef, 5](
    "DEMANDMANAGER:EXTERIORLIGHTS",
    "DEMANDMANAGER:LIGHTS",
    "DEMANDMANAGER:ELECTRICEQUIPMENT",
    "DEMANDMANAGER:THERMOSTATS",
    "DEMANDMANAGER:VENTILATION"
)

alias MANAGE_PRIORITY_NAMES_UC = InlineArray[StringRef, 3](
    "SEQUENTIAL", "OPTIMAL", "ALL"
)

alias MANAGER_LIMIT_NAMES_UC = InlineArray[StringRef, 4](
    "OFF", "FIXED", "VARIABLE", "REDUCTIONRATIO"
)

alias MANAGER_LIMIT_VENT_NAMES_UC = InlineArray[StringRef, 4](
    "OFF", "FIXEDRATE", "VARIABLE", "REDUCTIONRATIO"
)

alias MANAGER_SELECTION_NAMES_UC = InlineArray[StringRef, 3](
    "ALL", "ROTATEMANY", "ROTATEONE"
)

struct ManagerType:
    var Invalid: Int = -1
    var ExtLights: Int = 0
    var Lights: Int = 1
    var ElecEquip: Int = 2
    var Thermostats: Int = 3
    var Ventilation: Int = 4
    var Num: Int = 5

struct ManagePriorityType:
    var Invalid: Int = -1
    var Sequential: Int = 0
    var Optimal: Int = 1
    var All: Int = 2
    var Num: Int = 3

struct ManagerLimit:
    var Invalid: Int = -1
    var Off: Int = 0
    var Fixed: Int = 1
    var Variable: Int = 2
    var ReductionRatio: Int = 3
    var Num: Int = 4

struct ManagerSelection:
    var Invalid: Int = -1
    var All: Int = 0
    var Many: Int = 1
    var One: Int = 2
    var Num: Int = 3

struct DemandAction:
    var Invalid: Int = -1
    var CheckCanReduce: Int = 0
    var SetLimit: Int = 1
    var ClearLimit: Int = 2
    var Num: Int = 3

struct DemandManagerListData:
    var Name: String
    var Meter: Int
    var limitSched: UnsafePointer[AnyType]
    var SafetyFraction: Float64
    var billingSched: UnsafePointer[AnyType]
    var BillingPeriod: Float64
    var peakSched: UnsafePointer[AnyType]
    var AveragingWindow: Int
    var History: DynamicVector[Float64]
    var ManagerPriority: Int
    var NumOfManager: Int
    var Manager: DynamicVector[Int]
    var MeterDemand: Float64
    var AverageDemand: Float64
    var PeakDemand: Float64
    var ScheduledLimit: Float64
    var DemandLimit: Float64
    var AvoidedDemand: Float64
    var OverLimit: Float64
    var OverLimitDuration: Float64
    
    fn __init__(inout self) -> None:
        self.Name = String()
        self.Meter = 0
        self.limitSched = UnsafePointer[AnyType]()
        self.SafetyFraction = 1.0
        self.billingSched = UnsafePointer[AnyType]()
        self.BillingPeriod = 0.0
        self.peakSched = UnsafePointer[AnyType]()
        self.AveragingWindow = 1
        self.History = DynamicVector[Float64]()
        self.ManagerPriority = -1
        self.NumOfManager = 0
        self.Manager = DynamicVector[Int]()
        self.MeterDemand = 0.0
        self.AverageDemand = 0.0
        self.PeakDemand = 0.0
        self.ScheduledLimit = 0.0
        self.DemandLimit = 0.0
        self.AvoidedDemand = 0.0
        self.OverLimit = 0.0
        self.OverLimitDuration = 0.0

struct DemandManagerData:
    var Name: String
    var Type: Int
    var DemandManagerList: Int
    var CanReduceDemand: Bool
    var availSched: UnsafePointer[AnyType]
    var Available: Bool
    var Activate: Bool
    var Active: Bool
    var LimitControl: Int
    var SelectionControl: Int
    var LimitDuration: Int
    var ElapsedTime: Int
    var RotationDuration: Int
    var ElapsedRotationTime: Int
    var RotatedLoadNum: Int
    var LowerLimit: Float64
    var UpperLimit: Float64
    var NumOfLoads: Int
    var Load: DynamicVector[Int]
    var FixedRate: Float64
    var ReductionRatio: Float64
    
    fn __init__(inout self) -> None:
        self.Name = String()
        self.Type = -1
        self.DemandManagerList = 0
        self.CanReduceDemand = False
        self.availSched = UnsafePointer[AnyType]()
        self.Available = False
        self.Activate = False
        self.Active = False
        self.LimitControl = -1
        self.SelectionControl = -1
        self.LimitDuration = 0
        self.ElapsedTime = 0
        self.RotationDuration = 0
        self.ElapsedRotationTime = 0
        self.RotatedLoadNum = 0
        self.LowerLimit = 0.0
        self.UpperLimit = 0.0
        self.NumOfLoads = 0
        self.Load = DynamicVector[Int]()
        self.FixedRate = 0.0
        self.ReductionRatio = 0.0

@export
fn ManageDemand(state: UnsafePointer[AnyType]) -> None:
    pass

@export
fn SimulateDemandManagerList(
    state: UnsafePointer[AnyType],
    ListNum: Int,
    ResimExt: UnsafePointer[Bool],
    ResimHB: UnsafePointer[Bool],
    ResimHVAC: UnsafePointer[Bool]
) -> None:
    pass

@export
fn GetDemandManagerListInput(state: UnsafePointer[AnyType]) -> None:
    pass

@export
fn GetDemandManagerInput(state: UnsafePointer[AnyType]) -> None:
    pass

@export
fn SurveyDemandManagers(state: UnsafePointer[AnyType]) -> None:
    pass

@export
fn ActivateDemandManagers(state: UnsafePointer[AnyType]) -> None:
    pass

@export
fn UpdateDemandManagers(state: UnsafePointer[AnyType]) -> None:
    pass

@export
fn ReportDemandManagerList(state: UnsafePointer[AnyType], ListNum: Int) -> None:
    pass

@export
fn LoadInterface(
    state: UnsafePointer[AnyType],
    Action: Int,
    MgrNum: Int,
    LoadPtr: Int,
    CanReduceDemand: UnsafePointer[Bool]
) -> None:
    pass

@export
fn InitDemandManagers(state: UnsafePointer[AnyType]) -> None:
    pass
