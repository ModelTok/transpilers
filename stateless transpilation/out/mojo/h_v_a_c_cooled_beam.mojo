from math import pow as math_pow, pi, fabs
from sys.info import os_is_windows


struct CooledBeamType:
    alias Invalid = -1
    alias Passive = 0
    alias Active = 1
    alias Num = 2


alias NOM_MASS_FLOW_PER_BEAM = 0.07
alias MIN_WATER_VEL = 0.2
alias COEFF2 = 10000.0


struct PlantLocation:
    var loopNum: Int
    var loop: UnsafePointer[AnyType]


struct CoolBeamData:
    var Name: String
    var UnitType: String
    var UnitType_Num: Int
    var CBTypeString: String
    var CBType: Int
    var availSched: UnsafePointer[AnyType]
    var MaxAirVolFlow: Float64
    var MaxAirMassFlow: Float64
    var MaxCoolWaterVolFlow: Float64
    var MaxCoolWaterMassFlow: Float64
    var AirInNode: Int
    var AirOutNode: Int
    var CWInNode: Int
    var CWOutNode: Int
    var ADUNum: Int
    var NumBeams: Float64
    var BeamLength: Float64
    var DesInletWaterTemp: Float64
    var DesOutletWaterTemp: Float64
    var CoilArea: Float64
    var a: Float64
    var n1: Float64
    var n2: Float64
    var n3: Float64
    var a0: Float64
    var K1: Float64
    var n: Float64
    var Kin: Float64
    var InDiam: Float64
    var TWIn: Float64
    var TWOut: Float64
    var EnthWaterOut: Float64
    var BeamFlow: Float64
    var CoolWaterMassFlow: Float64
    var BeamCoolingEnergy: Float64
    var BeamCoolingRate: Float64
    var SupAirCoolingEnergy: Float64
    var SupAirCoolingRate: Float64
    var SupAirHeatingEnergy: Float64
    var SupAirHeatingRate: Float64
    var CWPlantLoc: PlantLocation
    var CBLoadReSimIndex: Int
    var CBMassFlowReSimIndex: Int
    var CBWaterOutletTempReSimIndex: Int
    var CtrlZoneNum: Int
    var ctrlZoneInNodeIndex: Int
    var AirLoopNum: Int
    var OutdoorAirFlowRate: Float64
    var MyEnvrnFlag: Bool
    var MySizeFlag: Bool
    var PlantLoopScanFlag: Bool

    fn __init__(inout self):
        self.Name = ""
        self.UnitType = ""
        self.UnitType_Num = 0
        self.CBTypeString = ""
        self.CBType = CooledBeamType.Invalid
        self.availSched = UnsafePointer[AnyType]()
        self.MaxAirVolFlow = 0.0
        self.MaxAirMassFlow = 0.0
        self.MaxCoolWaterVolFlow = 0.0
        self.MaxCoolWaterMassFlow = 0.0
        self.AirInNode = 0
        self.AirOutNode = 0
        self.CWInNode = 0
        self.CWOutNode = 0
        self.ADUNum = 0
        self.NumBeams = 0.0
        self.BeamLength = 0.0
        self.DesInletWaterTemp = 0.0
        self.DesOutletWaterTemp = 0.0
        self.CoilArea = 0.0
        self.a = 0.0
        self.n1 = 0.0
        self.n2 = 0.0
        self.n3 = 0.0
        self.a0 = 0.0
        self.K1 = 0.0
        self.n = 0.0
        self.Kin = 0.0
        self.InDiam = 0.0
        self.TWIn = 0.0
        self.TWOut = 0.0
        self.EnthWaterOut = 0.0
        self.BeamFlow = 0.0
        self.CoolWaterMassFlow = 0.0
        self.BeamCoolingEnergy = 0.0
        self.BeamCoolingRate = 0.0
        self.SupAirCoolingEnergy = 0.0
        self.SupAirCoolingRate = 0.0
        self.SupAirHeatingEnergy = 0.0
        self.SupAirHeatingRate = 0.0
        self.CWPlantLoc = PlantLocation(0, UnsafePointer[AnyType]())
        self.CBLoadReSimIndex = 0
        self.CBMassFlowReSimIndex = 0
        self.CBWaterOutletTempReSimIndex = 0
        self.CtrlZoneNum = 0
        self.ctrlZoneInNodeIndex = 0
        self.AirLoopNum = 0
        self.OutdoorAirFlowRate = 0.0
        self.MyEnvrnFlag = True
        self.MySizeFlag = True
        self.PlantLoopScanFlag = True

    fn CalcOutdoorAirVolumeFlowRate(inout self, state: UnsafePointer[AnyType]):
        if self.AirLoopNum > 0:
            self.OutdoorAirFlowRate = 0.0
        else:
            self.OutdoorAirFlowRate = 0.0

    fn reportTerminalUnit(inout self, state: UnsafePointer[AnyType]):
        pass


struct HVACCooledBeamData:
    var CheckEquipName: DynamicVector[Bool]
    var NumCB: Int
    var CoolBeam: DynamicVector[CoolBeamData]
    var GetInputFlag: Bool
    var ZoneEquipmentListChecked: Bool

    fn __init__(inout self):
        self.CheckEquipName = DynamicVector[Bool]()
        self.NumCB = 0
        self.CoolBeam = DynamicVector[CoolBeamData]()
        self.GetInputFlag = True
        self.ZoneEquipmentListChecked = False

    fn init_constant_state(inout self, state: UnsafePointer[AnyType]):
        pass

    fn init_state(inout self, state: UnsafePointer[AnyType]):
        pass

    fn clear_state(inout self):
        self.CheckEquipName.clear()
        self.NumCB = 0
        self.CoolBeam.clear()
        self.GetInputFlag = True
        self.ZoneEquipmentListChecked = False


fn SimCoolBeam(
    state: UnsafePointer[AnyType],
    CompName: StringRef,
    FirstHVACIteration: Bool,
    ZoneNum: Int,
    ZoneNodeNum: Int,
    inout CompIndex: Int,
) -> (Int, Float64):
    var NonAirSysOutput: Float64 = 0.0
    var CBNum: Int = 0

    return CompIndex, NonAirSysOutput


fn GetCoolBeams(state: UnsafePointer[AnyType]):
    pass


fn InitCoolBeam(state: UnsafePointer[AnyType], CBNum: Int, FirstHVACIteration: Bool):
    pass


fn SizeCoolBeam(state: UnsafePointer[AnyType], CBNum: Int):
    pass


fn ControlCoolBeam(
    state: UnsafePointer[AnyType],
    CBNum: Int,
    ZoneNum: Int,
    ZoneNodeNum: Int,
    FirstHVACIteration: Bool,
) -> Float64:
    var NonAirSysOutput: Float64 = 0.0
    return NonAirSysOutput


fn CalcCoolBeam(
    state: UnsafePointer[AnyType], CBNum: Int, ZoneNode: Int, CWFlow: Float64
) -> (Float64, Float64):
    var LoadMet: Float64 = 0.0
    var TWOut: Float64 = 0.0
    return LoadMet, TWOut


fn UpdateCoolBeam(state: UnsafePointer[AnyType], CBNum: Int):
    pass


fn ReportCoolBeam(state: UnsafePointer[AnyType], CBNum: Int):
    pass
