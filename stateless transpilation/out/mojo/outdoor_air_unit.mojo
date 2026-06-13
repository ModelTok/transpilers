from memory import UnsafePointer
from builtin import default_constructor


@value
struct CompType:
    alias Invalid = -1
    alias WaterCoil_Cooling = 0
    alias WaterCoil_SimpleHeat = 1
    alias SteamCoil_AirHeat = 2
    alias Coil_ElectricHeat = 3
    alias WaterCoil_DetailedCool = 4
    alias WaterCoil_CoolingHXAsst = 5
    alias Coil_GasHeat = 6
    alias DXSystem = 7
    alias HeatXchngrFP = 8
    alias HeatXchngrSL = 9
    alias Desiccant = 10
    alias DXHeatPumpSystem = 11
    alias UnitarySystemModel = 12
    alias Num = 13


fn get_comp_type_names() -> InlineArray[StringLiteral, 13]:
    return InlineArray[StringLiteral, 13](
        "Coil:Cooling:Water",
        "Coil:Heating:Water",
        "Coil:Heating:Steam",
        "Coil:Heating:Electric",
        "Coil:Cooling:Water:DetailedGeometry",
        "CoilSystem:Cooling:Water:HeatExchangerAssisted",
        "Coil:Heating:Fuel",
        "CoilSystem:Cooling:DX",
        "HeatExchanger:AirToAir:FlatPlate",
        "HeatExchanger:AirToAir:SensibleAndLatent",
        "Dehumidifier:Desiccant:NoFans",
        "CoilSystem:Heating:DX",
        "AirLoopHVAC:UnitarySystem"
    )


fn get_comp_type_names_uc() -> InlineArray[StringLiteral, 13]:
    return InlineArray[StringLiteral, 13](
        "COIL:COOLING:WATER",
        "COIL:HEATING:WATER",
        "COIL:HEATING:STEAM",
        "COIL:HEATING:ELECTRIC",
        "COIL:COOLING:WATER:DETAILEDGEOMETRY",
        "COILSYSTEM:COOLING:WATER:HEATEXCHANGERASSISTED",
        "COIL:HEATING:FUEL",
        "COILSYSTEM:COOLING:DX",
        "HEATEXCHANGER:AIRTOAIR:FLATPLATE",
        "HEATEXCHANGER:AIRTOAIR:SENSIBLEANDLATENT",
        "DEHUMIDIFIER:DESICCANT:NOFANS",
        "COILSYSTEM:HEATING:DX",
        "AIRLOOPHVAC:UNITARYSYSTEM"
    )


@value
struct OAUnitCtrlType:
    alias Invalid = -1
    alias Neutral = 0
    alias Unconditioned = 1
    alias Temperature = 2
    alias Num = 3


@value
struct Operation:
    alias Invalid = -1
    alias HeatingMode = 0
    alias CoolingMode = 1
    alias NeutralMode = 2
    alias Num = 3


struct OAEquipList:
    var ComponentName: String
    var Type: Int32
    var ComponentIndex: Int32
    var compPointer: UnsafePointer[UInt8]
    var CoilAirInletNode: Int32
    var CoilAirOutletNode: Int32
    var CoilWaterInletNode: Int32
    var CoilWaterOutletNode: Int32
    var CoilType: Int32
    var plantLoc: UnsafePointer[UInt8]
    var FluidIndex: Int32
    var MaxVolWaterFlow: Float64
    var MaxWaterMassFlow: Float64
    var MinVolWaterFlow: Float64
    var MinWaterMassFlow: Float64
    var FirstPass: Bool

    fn __init__(inout self):
        self.ComponentName = String()
        self.Type = CompType.Invalid
        self.ComponentIndex = 0
        self.compPointer = UnsafePointer[UInt8]()
        self.CoilAirInletNode = 0
        self.CoilAirOutletNode = 0
        self.CoilWaterInletNode = 0
        self.CoilWaterOutletNode = 0
        self.CoilType = 0
        self.plantLoc = UnsafePointer[UInt8]()
        self.FluidIndex = 0
        self.MaxVolWaterFlow = 0.0
        self.MaxWaterMassFlow = 0.0
        self.MinVolWaterFlow = 0.0
        self.MinWaterMassFlow = 0.0
        self.FirstPass = True


struct OAUnitData:
    var Name: String
    var availSched: UnsafePointer[UInt8]
    var ZoneName: String
    var ZonePtr: Int32
    var ZoneNodeNum: Int32
    var UnitControlType: String
    var controlType: Int32
    var AirInletNode: Int32
    var AirOutletNode: Int32
    var SFanName: String
    var SFan_Index: Int32
    var supFanType: Int32
    var supFanAvailSched: UnsafePointer[UInt8]
    var supFanPlace: Int32
    var FanCorTemp: Float64
    var FanEffect: Bool
    var SFanOutletNode: Int32
    var ExtFanName: String
    var ExtFan_Index: Int32
    var extFanType: Int32
    var extFanAvailSched: UnsafePointer[UInt8]
    var ExtFan: Bool
    var outAirSched: UnsafePointer[UInt8]
    var OutsideAirNode: Int32
    var OutAirVolFlow: Float64
    var OutAirMassFlow: Float64
    var ExtAirVolFlow: Float64
    var ExtAirMassFlow: Float64
    var extAirSched: UnsafePointer[UInt8]
    var SMaxAirMassFlow: Float64
    var EMaxAirMassFlow: Float64
    var SFanMaxAirVolFlow: Float64
    var EFanMaxAirVolFlow: Float64
    var hiCtrlTempSched: UnsafePointer[UInt8]
    var loCtrlTempSched: UnsafePointer[UInt8]
    var OperatingMode: Int32
    var ControlCompTypeNum: Int32
    var CompErrIndex: Int32
    var AirMassFlow: Float64
    var FlowError: Bool
    var NumComponents: Int32
    var ComponentListName: String
    var CompOutSetTemp: Float64
    var availStatus: Int32
    var AvailManagerListName: String
    var OAEquip: UnsafePointer[OAEquipList]
    var OAEquipSize: Int32
    var TotCoolingRate: Float64
    var TotCoolingEnergy: Float64
    var SensCoolingRate: Float64
    var SensCoolingEnergy: Float64
    var LatCoolingRate: Float64
    var LatCoolingEnergy: Float64
    var ElecFanRate: Float64
    var ElecFanEnergy: Float64
    var SensHeatingEnergy: Float64
    var SensHeatingRate: Float64
    var LatHeatingEnergy: Float64
    var LatHeatingRate: Float64
    var TotHeatingEnergy: Float64
    var TotHeatingRate: Float64
    var FirstPass: Bool

    fn __init__(inout self):
        self.Name = String()
        self.availSched = UnsafePointer[UInt8]()
        self.ZoneName = String()
        self.ZonePtr = 0
        self.ZoneNodeNum = 0
        self.UnitControlType = String()
        self.controlType = OAUnitCtrlType.Invalid
        self.AirInletNode = 0
        self.AirOutletNode = 0
        self.SFanName = String()
        self.SFan_Index = 0
        self.supFanType = -1
        self.supFanAvailSched = UnsafePointer[UInt8]()
        self.supFanPlace = -1
        self.FanCorTemp = 0.0
        self.FanEffect = False
        self.SFanOutletNode = 0
        self.ExtFanName = String()
        self.ExtFan_Index = 0
        self.extFanType = -1
        self.extFanAvailSched = UnsafePointer[UInt8]()
        self.ExtFan = False
        self.outAirSched = UnsafePointer[UInt8]()
        self.OutsideAirNode = 0
        self.OutAirVolFlow = 0.0
        self.OutAirMassFlow = 0.0
        self.ExtAirVolFlow = 0.0
        self.ExtAirMassFlow = 0.0
        self.extAirSched = UnsafePointer[UInt8]()
        self.SMaxAirMassFlow = 0.0
        self.EMaxAirMassFlow = 0.0
        self.SFanMaxAirVolFlow = 0.0
        self.EFanMaxAirVolFlow = 0.0
        self.hiCtrlTempSched = UnsafePointer[UInt8]()
        self.loCtrlTempSched = UnsafePointer[UInt8]()
        self.OperatingMode = Operation.Invalid
        self.ControlCompTypeNum = 0
        self.CompErrIndex = 0
        self.AirMassFlow = 0.0
        self.FlowError = False
        self.NumComponents = 0
        self.ComponentListName = String()
        self.CompOutSetTemp = 0.0
        self.availStatus = 0
        self.AvailManagerListName = String()
        self.OAEquip = UnsafePointer[OAEquipList]()
        self.OAEquipSize = 0
        self.TotCoolingRate = 0.0
        self.TotCoolingEnergy = 0.0
        self.SensCoolingRate = 0.0
        self.SensCoolingEnergy = 0.0
        self.LatCoolingRate = 0.0
        self.LatCoolingEnergy = 0.0
        self.ElecFanRate = 0.0
        self.ElecFanEnergy = 0.0
        self.SensHeatingEnergy = 0.0
        self.SensHeatingRate = 0.0
        self.LatHeatingEnergy = 0.0
        self.LatHeatingRate = 0.0
        self.TotHeatingEnergy = 0.0
        self.TotHeatingRate = 0.0
        self.FirstPass = True


struct OutdoorAirUnitData:
    var NumOfOAUnits: Int32
    var OAMassFlowRate: Float64
    var MyOneTimeErrorFlag: UnsafePointer[Bool]
    var GetOutdoorAirUnitInputFlag: Bool
    var MySizeFlag: UnsafePointer[Bool]
    var CheckEquipName: UnsafePointer[Bool]
    var OutAirUnit: UnsafePointer[OAUnitData]
    var OutAirUnitSize: Int32
    var MyOneTimeFlag: Bool
    var ZoneEquipmentListChecked: Bool
    var SupplyFanUniqueNames: UnsafePointer[UInt8]
    var ExhaustFanUniqueNames: UnsafePointer[UInt8]
    var ComponentListUniqueNames: UnsafePointer[UInt8]
    var MyEnvrnFlag: UnsafePointer[Bool]
    var MyPlantScanFlag: UnsafePointer[Bool]
    var MyZoneEqFlag: UnsafePointer[Bool]
    var HeatActive: Bool
    var CoolActive: Bool

    fn __init__(inout self):
        self.NumOfOAUnits = 0
        self.OAMassFlowRate = 0.0
        self.MyOneTimeErrorFlag = UnsafePointer[Bool]()
        self.GetOutdoorAirUnitInputFlag = True
        self.MySizeFlag = UnsafePointer[Bool]()
        self.CheckEquipName = UnsafePointer[Bool]()
        self.OutAirUnit = UnsafePointer[OAUnitData]()
        self.OutAirUnitSize = 0
        self.MyOneTimeFlag = True
        self.ZoneEquipmentListChecked = False
        self.SupplyFanUniqueNames = UnsafePointer[UInt8]()
        self.ExhaustFanUniqueNames = UnsafePointer[UInt8]()
        self.ComponentListUniqueNames = UnsafePointer[UInt8]()
        self.MyEnvrnFlag = UnsafePointer[Bool]()
        self.MyPlantScanFlag = UnsafePointer[Bool]()
        self.MyZoneEqFlag = UnsafePointer[Bool]()
        self.HeatActive = False
        self.CoolActive = False


alias ZONE_HVAC_OA_UNIT = "ZoneHVAC:OutdoorAirUnit"
alias ZONE_HVAC_EQ_LIST = "ZoneHVAC:OutdoorAirUnit:EquipmentList"


fn SimOutdoorAirUnit(state: UnsafePointer[UInt8],
                    CompName: StringLiteral,
                    ZoneNum: Int32,
                    FirstHVACIteration: Bool) -> Tuple[Int32, Float64, Float64]:
    var OAUnitNum = 0
    var PowerMet = 0.0
    var LatOutputProvided = 0.0
    
    return Tuple[Int32, Float64, Float64](OAUnitNum, PowerMet, LatOutputProvided)


fn GetOutdoorAirUnitInputs(state: UnsafePointer[UInt8]):
    pass


fn InitOutdoorAirUnit(state: UnsafePointer[UInt8],
                     OAUnitNum: Int32,
                     ZoneNum: Int32,
                     FirstHVACIteration: Bool):
    pass


fn SizeOutdoorAirUnit(state: UnsafePointer[UInt8], OAUnitNum: Int32):
    pass


fn CalcOutdoorAirUnit(state: UnsafePointer[UInt8],
                     OAUnitNum: Int32,
                     ZoneNum: Int32,
                     FirstHVACIteration: Bool) -> Tuple[Float64, Float64]:
    var PowerMet = 0.0
    var LatOutputProvided = 0.0
    
    return Tuple[Float64, Float64](PowerMet, LatOutputProvided)


fn SimZoneOutAirUnitComps(state: UnsafePointer[UInt8],
                         OAUnitNum: Int32,
                         FirstHVACIteration: Bool):
    pass


fn SimOutdoorAirEquipComps(state: UnsafePointer[UInt8],
                          OAUnitNum: Int32,
                          EquipType: StringLiteral,
                          EquipName: StringLiteral,
                          EquipNum: Int32,
                          CompTypeNum: Int32,
                          FirstHVACIteration: Bool,
                          CompIndex: Int32,
                          Sim: Bool):
    pass


fn CalcOAUnitCoilComps(state: UnsafePointer[UInt8],
                      CompNum: Int32,
                      FirstHVACIteration: Bool,
                      EquipIndex: Int32) -> Float64:
    return 0.0


fn ReportOutdoorAirUnit(state: UnsafePointer[UInt8], OAUnitNum: Int32):
    pass


fn GetOutdoorAirUnitOutAirNode(state: UnsafePointer[UInt8], OAUnitNum: Int32) -> Int32:
    return 0


fn GetOutdoorAirUnitZoneInletNode(state: UnsafePointer[UInt8], OAUnitNum: Int32) -> Int32:
    return 0


fn GetOutdoorAirUnitReturnAirNode(state: UnsafePointer[UInt8], OAUnitNum: Int32) -> Int32:
    return 0


fn getOutdoorAirUnitEqIndex(state: UnsafePointer[UInt8], EquipName: StringLiteral) -> Int32:
    return 0
