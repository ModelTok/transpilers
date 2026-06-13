# Copyright (c) 1996-present, The Board of Trustees of the University of Illinois,
# The Regents of the University of California, through Lawrence Berkeley National Laboratory
# (subject to receipt of any required approvals from the U.S. Dept. of Energy), Oak Ridge
# National Laboratory, managed by UT-Battelle, Alliance for Energy Innovation, LLC, and other
# contributors. All rights reserved.

from memory import UnsafePointer
from collections import Dict, List
from math import max as math_max
import math

# ============================================================================
# TYPE STUBS (external dependencies)
# ============================================================================

trait Schedule:
    fn getCurrentVal(self) -> Float64:
        ...

trait RefrigProps:
    fn getDensity(self, state: UnsafePointer[EnergyPlusData], temp: Float64, routine: StringLiteral) -> Float64:
        ...
    fn getSpecificHeat(self, state: UnsafePointer[EnergyPlusData], temp: Float64, routine: StringLiteral) -> Float64:
        ...
    fn getSatDensity(self, state: UnsafePointer[EnergyPlusData], temp: Float64, quality: Float64, routine: StringLiteral) -> Float64:
        ...
    fn getSatEnthalpy(self, state: UnsafePointer[EnergyPlusData], temp: Float64, quality: Float64, routine: StringLiteral) -> Float64:
        ...

trait Fan:
    var outletNodeNum: Int32
    var maxAirFlowRate: Float64
    var totalPower: Float64
    var availSched: UnsafePointer[Schedule]
    fn simulate(self, state: UnsafePointer[EnergyPlusData], first_hvac_iter: Bool, foo: UnsafePointer[Int8], bar: UnsafePointer[Int8]):
        ...

trait PlantComponent:
    var NodeNumOut: Int32

trait PlantLoop:
    var glycol: UnsafePointer[RefrigProps]

trait PlantLocation:
    var loopNum: Int32
    var loop: UnsafePointer[PlantLoop]
    fn getPlantComponent(self, state: UnsafePointer[EnergyPlusData]) -> UnsafePointer[PlantComponent]:
        ...

trait Node:
    var Temp: Float64
    var Press: Float64
    var HumRat: Float64
    var Enthalpy: Float64
    var MassFlowRate: Float64
    var MassFlowRateMax: Float64
    var MassFlowRateMin: Float64
    var MassFlowRateMaxAvail: Float64
    var MassFlowRateMinAvail: Float64

trait ZoneEqSizing:
    var AirVolFlow: Float64
    var SystemAirFlow: Bool
    var DesHeatingLoad: Float64
    var HeatingCapacity: Bool
    var MaxHWVolFlow: Float64

trait ZoneSysEnergyDemand:
    var RemainingOutputReqToHeatSP: Float64

trait ZoneEquipConfig:
    var IsControlled: Bool
    var NumExhaustNodes: Int32
    var ExhaustNode: List[Int32]
    var NumInletNodes: Int32
    var InletNode: List[Int32]

trait Zone:
    var FloorArea: Float64

trait FinalZoneSizing:
    var DesHeatLoad: Float64
    var DesHeatVolFlow: Float64

trait PlantSizData:
    var DeltaT: Float64
    var ExitTemp: Float64

trait ZoneHVACSizing:
    var HeatingSAFMethod: Int32
    var MaxHeatAirVolFlow: Float64
    var HeatingCapMethod: Int32
    var ScaledHeatingCapacity: Float64

trait EnergyPlusData:
    var dataUnitHeaters: UnsafePointer[Int8]
    var dataSize: UnsafePointer[Int8]
    var dataLoopNodes: UnsafePointer[Int8]
    var dataFans: UnsafePointer[Int8]
    var dataInputProcessing: UnsafePointer[Int8]
    var dataAvail: UnsafePointer[Int8]
    var dataPlnt: UnsafePointer[Int8]
    var dataGlobal: UnsafePointer[Int8]
    var dataEnvrn: UnsafePointer[Int8]
    var dataZoneEquip: UnsafePointer[Int8]
    var dataZoneEnergyDemand: UnsafePointer[Int8]
    var dataHVACGlobal: UnsafePointer[Int8]
    var dataHeatBal: UnsafePointer[Int8]
    var dataWaterCoils: UnsafePointer[Int8]

# ============================================================================
# DATA STRUCTURES
# ============================================================================

@value
struct UnitHeaterData:
    var Name: String
    var availSched: UnsafePointer[Schedule]
    var AirInNode: Int32
    var AirOutNode: Int32
    var fanType: Int32
    var FanName: String
    var Fan_Index: Int32
    var fanOpModeSched: UnsafePointer[Schedule]
    var fanAvailSched: UnsafePointer[Schedule]
    var ControlCompTypeNum: Int32
    var CompErrIndex: Int32
    var MaxAirVolFlow: Float64
    var MaxAirMassFlow: Float64
    var FanOperatesDuringNoHeating: String
    var FanOutletNode: Int32
    var fanOp: Int32
    var heatCoilType: Int32
    var HCoilTypeCh: String
    var HCoilName: String
    var HCoil_Index: Int32
    var HeatingCoilType: Int32
    var HCoil_fluid: UnsafePointer[RefrigProps]
    var MaxVolHotWaterFlow: Float64
    var MaxVolHotSteamFlow: Float64
    var MaxHotWaterFlow: Float64
    var MaxHotSteamFlow: Float64
    var MinVolHotWaterFlow: Float64
    var MinVolHotSteamFlow: Float64
    var MinHotWaterFlow: Float64
    var MinHotSteamFlow: Float64
    var HotControlNode: Int32
    var HotControlOffset: Float64
    var HotCoilOutNodeNum: Int32
    var HWplantLoc: UnsafePointer[PlantLocation]
    var PartLoadFrac: Float64
    var HeatPower: Float64
    var HeatEnergy: Float64
    var ElecPower: Float64
    var ElecEnergy: Float64
    var AvailManagerListName: String
    var availStatus: Int32
    var FanOffNoHeating: Bool
    var FanPartLoadRatio: Float64
    var ZonePtr: Int32
    var HVACSizingIndex: Int32
    var FirstPass: Bool
    var solveRootStats: Int32

    fn __init__() -> Self:
        return UnitHeaterData(
            Name: "",
            availSched: UnsafePointer[Schedule](),
            AirInNode: 0,
            AirOutNode: 0,
            fanType: 0,
            FanName: "",
            Fan_Index: 0,
            fanOpModeSched: UnsafePointer[Schedule](),
            fanAvailSched: UnsafePointer[Schedule](),
            ControlCompTypeNum: 0,
            CompErrIndex: 0,
            MaxAirVolFlow: 0.0,
            MaxAirMassFlow: 0.0,
            FanOperatesDuringNoHeating: "",
            FanOutletNode: 0,
            fanOp: 0,
            heatCoilType: 0,
            HCoilTypeCh: "",
            HCoilName: "",
            HCoil_Index: 0,
            HeatingCoilType: 0,
            HCoil_fluid: UnsafePointer[RefrigProps](),
            MaxVolHotWaterFlow: 0.0,
            MaxVolHotSteamFlow: 0.0,
            MaxHotWaterFlow: 0.0,
            MaxHotSteamFlow: 0.0,
            MinVolHotWaterFlow: 0.0,
            MinVolHotSteamFlow: 0.0,
            MinHotWaterFlow: 0.0,
            MinHotSteamFlow: 0.0,
            HotControlNode: 0,
            HotControlOffset: 0.0,
            HotCoilOutNodeNum: 0,
            HWplantLoc: UnsafePointer[PlantLocation](),
            PartLoadFrac: 0.0,
            HeatPower: 0.0,
            HeatEnergy: 0.0,
            ElecPower: 0.0,
            ElecEnergy: 0.0,
            AvailManagerListName: "",
            availStatus: 0,
            FanOffNoHeating: False,
            FanPartLoadRatio: 0.0,
            ZonePtr: 0,
            HVACSizingIndex: 0,
            FirstPass: True,
            solveRootStats: 0
        )

@value
struct UnitHeatNumericFieldData:
    var FieldNames: List[String]

    fn __init__() -> Self:
        return UnitHeatNumericFieldData(FieldNames: List[String]())

@value
struct UnitHeatersData:
    var cMO_UnitHeater: String
    var HCoilOn: Bool
    var NumOfUnitHeats: Int32
    var QZnReq: Float64
    var MySizeFlag: List[Bool]
    var CheckEquipName: List[Bool]
    var InitUnitHeaterOneTimeFlag: Bool
    var GetUnitHeaterInputFlag: Bool
    var ZoneEquipmentListChecked: Bool
    var SetMassFlowRateToZero: Bool
    var UnitHeat: List[UnitHeaterData]
    var UnitHeatNumericFields: List[UnitHeatNumericFieldData]
    var MyEnvrnFlag: List[Bool]
    var MyPlantScanFlag: List[Bool]
    var MyZoneEqFlag: List[Bool]

    fn __init__() -> Self:
        return UnitHeatersData(
            cMO_UnitHeater: "ZoneHVAC:UnitHeater",
            HCoilOn: False,
            NumOfUnitHeats: 0,
            QZnReq: 0.0,
            MySizeFlag: List[Bool](),
            CheckEquipName: List[Bool](),
            InitUnitHeaterOneTimeFlag: True,
            GetUnitHeaterInputFlag: True,
            ZoneEquipmentListChecked: False,
            SetMassFlowRateToZero: False,
            UnitHeat: List[UnitHeaterData](),
            UnitHeatNumericFields: List[UnitHeatNumericFieldData](),
            MyEnvrnFlag: List[Bool](),
            MyPlantScanFlag: List[Bool](),
            MyZoneEqFlag: List[Bool]()
        )

    fn init_constant_state(self, inout state: EnergyPlusData):
        pass

    fn init_state(self, inout state: EnergyPlusData):
        pass

    fn clear_state(inout self):
        self.HCoilOn = False
        self.NumOfUnitHeats = 0
        self.QZnReq = 0.0
        self.MySizeFlag.clear()
        self.CheckEquipName.clear()
        self.UnitHeat.clear()
        self.UnitHeatNumericFields.clear()
        self.InitUnitHeaterOneTimeFlag = True
        self.GetUnitHeaterInputFlag = True
        self.ZoneEquipmentListChecked = False
        self.SetMassFlowRateToZero = False
        self.MyEnvrnFlag.clear()
        self.MyPlantScanFlag.clear()
        self.MyZoneEqFlag.clear()

# ============================================================================
# EXTERNAL STUBS (signatures only, to be linked)
# ============================================================================

fn Util_FindItemInList(name: StringLiteral, items: List[AnyType]) -> Int32:
    pass

fn Util_makeUPPER(s: StringLiteral) -> String:
    pass

fn Util_SameString(s1: StringLiteral, s2: StringLiteral) -> Bool:
    pass

fn Fans_GetFanIndex(state: UnsafePointer[EnergyPlusData], name: StringLiteral) -> Int32:
    pass

fn WaterCoils_GetCoilWaterInletNode(state: UnsafePointer[EnergyPlusData], coil_type: StringLiteral, coil_name: StringLiteral, inout err_flag: Bool) -> Int32:
    pass

fn WaterCoils_GetCoilWaterOutletNode(state: UnsafePointer[EnergyPlusData], coil_type: StringLiteral, coil_name: StringLiteral, inout err_flag: Bool) -> Int32:
    pass

fn WaterCoils_GetWaterCoilIndex(state: UnsafePointer[EnergyPlusData], coil_type: StringLiteral, coil_name: StringLiteral, inout err_flag: Bool) -> Int32:
    pass

fn WaterCoils_SetCoilDesFlow(state: UnsafePointer[EnergyPlusData], coil_type: StringLiteral, coil_name: StringLiteral, flow: Float64, inout err_flag: Bool):
    pass

fn WaterCoils_SimulateWaterCoilComponents(state: UnsafePointer[EnergyPlusData], name: StringLiteral, first_hvac: Bool, index: Int32, q_coil_req: Float64 = 0.0, fan_op: Int32 = 0, plr: Float64 = 1.0):
    pass

fn SteamCoils_GetSteamCoilIndex(state: UnsafePointer[EnergyPlusData], coil_type: StringLiteral, coil_name: StringLiteral, inout err_flag: Bool) -> Int32:
    pass

fn SteamCoils_GetCoilSteamInletNode(state: UnsafePointer[EnergyPlusData], index: Int32, name: StringLiteral, inout err_flag: Bool) -> Int32:
    pass

fn SteamCoils_SimulateSteamCoilComponents(state: UnsafePointer[EnergyPlusData], name: StringLiteral, first_hvac: Bool, index: Int32, q_coil_req: Float64 = 0.0, foo: UnsafePointer[Int8] = UnsafePointer[Int8](), fan_op: Int32 = 0, plr: Float64 = 1.0):
    pass

fn HeatingCoils_SimulateHeatingCoilComponents(state: UnsafePointer[EnergyPlusData], name: StringLiteral, first_hvac: Bool, q_coil_req: Float64, index: Int32, foo: UnsafePointer[Int8] = UnsafePointer[Int8](), bar: UnsafePointer[Int8] = UnsafePointer[Int8](), fan_op: Int32 = 0, plr: Float64 = 1.0):
    pass

fn PlantUtilities_ScanPlantLoopsForObject(state: UnsafePointer[EnergyPlusData], name: StringLiteral, coil_type: Int32, inout loc: PlantLocation, inout err_flag: Bool, args: UnsafePointer[Int8]):
    pass

fn PlantUtilities_InitComponentNodes(state: UnsafePointer[EnergyPlusData], min_flow: Float64, max_flow: Float64, inlet: Int32, outlet: Int32):
    pass

fn PlantUtilities_SetComponentFlowRate(state: UnsafePointer[EnergyPlusData], mdot: Float64, inlet: Int32, outlet: Int32, inout loc: PlantLocation):
    pass

fn PlantUtilities_MyPlantSizingIndex(state: UnsafePointer[EnergyPlusData], coil_type: StringLiteral, name: StringLiteral, inlet: Int32, outlet: Int32, inout err_flag: Bool) -> Int32:
    pass

fn Psychrometrics_PsyHFnTdbW(tdb: Float64, w: Float64) -> Float64:
    pass

fn Psychrometrics_PsyCpAirFnW(w: Float64) -> Float64:
    pass

fn Psychrometrics_CPHW(temp: Float64) -> Float64:
    pass

fn Fluid_GetSteam(state: UnsafePointer[EnergyPlusData]) -> UnsafePointer[RefrigProps]:
    pass

fn General_SolveRoot2(state: UnsafePointer[EnergyPlusData], tol: Float64, max_iter: Int32, inout sol_flag: Int32, f: fn(Float64) -> Float64, x_min: Float64, x_max: Float64, inout stats: Int32) -> Float64:
    pass

fn ShowFatalError(state: UnsafePointer[EnergyPlusData], msg: StringLiteral):
    pass

fn ShowSevereError(state: UnsafePointer[EnergyPlusData], msg: StringLiteral):
    pass

fn ShowContinueError(state: UnsafePointer[EnergyPlusData], msg: StringLiteral):
    pass

fn ShowWarningError(state: UnsafePointer[EnergyPlusData], msg: StringLiteral):
    pass

fn ShowMessage(state: UnsafePointer[EnergyPlusData], msg: StringLiteral):
    pass

fn ValidateComponent(state: UnsafePointer[EnergyPlusData], coil_type: StringLiteral, coil_name: StringLiteral, inout err_flag: Bool, context: StringLiteral):
    pass

fn Node_GetOnlySingleNode(state: UnsafePointer[EnergyPlusData], name: StringLiteral, inout err_flag: Bool, obj_type: Int32, parent_name: StringLiteral, fluid_type: Int32, conn_type: Int32, comp_stream: Int32, obj_is_parent: Int32) -> Int32:
    pass

fn Node_SetUpCompSets(state: UnsafePointer[EnergyPlusData], parent: StringLiteral, parent_name: StringLiteral, comp_type: StringLiteral, comp_name: StringLiteral, inlet_name: StringLiteral, outlet_name: StringLiteral):
    pass

fn ControlCompOutput(state: UnsafePointer[EnergyPlusData], name: StringLiteral, obj_type: StringLiteral, index: Int32, first_hvac: Bool, q_req: Float64, control_node: Int32, max_flow: Float64, min_flow: Float64, offset: Float64, comp_type: Int32, inout err_index: Int32, args: UnsafePointer[Int8], inout loc: PlantLocation):
    pass

fn SetupOutputVariable(state: UnsafePointer[EnergyPlusData], name: StringLiteral, units: Int32, inout var_ref: Float64, time_step: Int32, store_type: Int32, obj_name: StringLiteral):
    pass

fn DataZoneEquipment_CheckZoneEquipmentList(state: UnsafePointer[EnergyPlusData], obj_type: StringLiteral, name: StringLiteral) -> Bool:
    pass

fn DataSizing_resetHVACSizingGlobals(state: UnsafePointer[EnergyPlusData], zone_eq_num: Int32, zero: Int32, flag: Bool):
    pass

fn DataSizing_CheckZoneSizing(state: UnsafePointer[EnergyPlusData], obj_type: StringLiteral, name: StringLiteral):
    pass

fn BaseSizer_reportSizerOutput(state: UnsafePointer[EnergyPlusData], obj_type: StringLiteral, obj_name: StringLiteral, desc1: StringLiteral, val1: Float64, desc2: StringLiteral = "", val2: Float64 = 0.0):
    pass

fn ReportCoilSelection_setCoilSupplyFanInfo(state: UnsafePointer[EnergyPlusData], index: Int32, fan_name: StringLiteral, fan_type: Int32, fan_index: Int32):
    pass

fn ReportCoilSelection_getReportIndex(state: UnsafePointer[EnergyPlusData], coil_name: StringLiteral, coil_type: Int32) -> Int32:
    pass

# ============================================================================
# MAIN FUNCTIONS
# ============================================================================

fn SimUnitHeater(state: UnsafePointer[EnergyPlusData], comp_name: StringLiteral, zone_num: Int32, first_hvac_iteration: Bool, inout power_met: Float64, inout lat_output_provided: Float64, inout comp_index: Int32):
    var unit_heat_data = state[].dataUnitHeaters
    if unit_heat_data.GetUnitHeaterInputFlag:
        GetUnitHeaterInput(state)
        unit_heat_data.GetUnitHeaterInputFlag = False
    
    var unit_heat_num: Int32
    if comp_index == 0:
        unit_heat_num = Util_FindItemInList(comp_name, unit_heat_data.UnitHeat)
        if unit_heat_num == 0:
            ShowFatalError(state, "SimUnitHeater: Unit not found={}")
        comp_index = unit_heat_num
    else:
        unit_heat_num = comp_index
        if unit_heat_num > unit_heat_data.NumOfUnitHeats or unit_heat_num < 1:
            ShowFatalError(state, "SimUnitHeater: Invalid CompIndex passed")
        if unit_heat_data.CheckEquipName[unit_heat_num - 1]:
            if comp_name != unit_heat_data.UnitHeat[unit_heat_num - 1].Name:
                ShowFatalError(state, "SimUnitHeater: Invalid CompIndex passed, Unit name mismatch")
            unit_heat_data.CheckEquipName[unit_heat_num - 1] = False
    
    state[].dataSize.ZoneEqUnitHeater = True
    InitUnitHeater(state, unit_heat_num, zone_num, first_hvac_iteration)
    state[].dataSize.ZoneHeatingOnlyFan = True
    CalcUnitHeater(state, unit_heat_num, zone_num, first_hvac_iteration, &power_met, &lat_output_provided)
    state[].dataSize.ZoneHeatingOnlyFan = False
    ReportUnitHeater(state, unit_heat_num)
    state[].dataSize.ZoneEqUnitHeater = False

fn GetUnitHeaterInput(state: UnsafePointer[EnergyPlusData]):
    var routine_name = "GetUnitHeaterInput"
    var current_module_object = "ZoneHVAC:UnitHeater"
    
    var unit_heat_data = state[].dataUnitHeaters
    unit_heat_data.NumOfUnitHeats = state[].dataInputProcessing.inputProcessor.getNumObjectsFound(state, current_module_object)
    
    if unit_heat_data.NumOfUnitHeats > 0:
        for i in range(unit_heat_data.NumOfUnitHeats):
            unit_heat_data.UnitHeat.append(UnitHeaterData())
            unit_heat_data.CheckEquipName.append(True)
            unit_heat_data.UnitHeatNumericFields.append(UnitHeatNumericFieldData())

fn InitUnitHeater(state: UnsafePointer[EnergyPlusData], unit_heat_num: Int32, zone_num: Int32, first_hvac_iteration: Bool):
    var routine_name = "InitUnitHeater"
    var unit_heat_data = state[].dataUnitHeaters
    
    if unit_heat_data.InitUnitHeaterOneTimeFlag:
        for i in range(unit_heat_data.NumOfUnitHeats):
            unit_heat_data.MyEnvrnFlag.append(True)
            unit_heat_data.MySizeFlag.append(True)
            unit_heat_data.MyPlantScanFlag.append(True)
            unit_heat_data.MyZoneEqFlag.append(True)
        unit_heat_data.InitUnitHeaterOneTimeFlag = False
    
    var unit_heat = unit_heat_data.UnitHeat[unit_heat_num - 1]
    var in_node = unit_heat.AirInNode
    var out_node = unit_heat.AirOutNode
    
    if unit_heat_data.MyPlantScanFlag[unit_heat_num - 1]:
        if unit_heat.HeatingCoilType in [1, 2]:
            var err_flag = False
            unit_heat_data.MyPlantScanFlag[unit_heat_num - 1] = False
    
    if not unit_heat_data.ZoneEquipmentListChecked and state[].dataZoneEquip.ZoneEquipInputsFilled:
        unit_heat_data.ZoneEquipmentListChecked = True
    
    if not state[].dataGlobal.SysSizingCalc and unit_heat_data.MySizeFlag[unit_heat_num - 1] and \
       not unit_heat_data.MyPlantScanFlag[unit_heat_num - 1]:
        SizeUnitHeater(state, unit_heat_num)
        unit_heat_data.MySizeFlag[unit_heat_num - 1] = False
    
    if state[].dataGlobal.BeginEnvrnFlag and unit_heat_data.MyEnvrnFlag[unit_heat_num - 1] and \
       not unit_heat_data.MyPlantScanFlag[unit_heat_num - 1]:
        var rho_air = state[].dataEnvrn.StdRhoAir
        unit_heat.MaxAirMassFlow = rho_air * unit_heat.MaxAirVolFlow
        unit_heat_data.MyEnvrnFlag[unit_heat_num - 1] = False
    
    if not state[].dataGlobal.BeginEnvrnFlag:
        unit_heat_data.MyEnvrnFlag[unit_heat_num - 1] = True
    
    unit_heat_data.QZnReq = state[].dataZoneEnergyDemand.ZoneSysEnergyDemand[zone_num - 1].RemainingOutputReqToHeatSP
    unit_heat_data.SetMassFlowRateToZero = False

fn SizeUnitHeater(state: UnsafePointer[EnergyPlusData], unit_heat_num: Int32):
    var routine_name = "SizeUnitHeater"
    var unit_heat_data = state[].dataUnitHeaters
    var unit_heat = unit_heat_data.UnitHeat[unit_heat_num - 1]
    
    state[].dataSize.DataZoneNumber = unit_heat.ZonePtr
    state[].dataSize.DataFanType = unit_heat.fanType
    state[].dataSize.DataFanIndex = unit_heat.Fan_Index
    state[].dataSize.DataFanPlacement = 1

fn CalcUnitHeater(state: UnsafePointer[EnergyPlusData], unit_heat_num: Int32, zone_num: Int32, first_hvac_iteration: Bool, inout power_met: Float64, inout lat_output_provided: Float64):
    var unit_heat_data = state[].dataUnitHeaters
    var unit_heat = unit_heat_data.UnitHeat[unit_heat_num - 1]
    var inlet_node = unit_heat.AirInNode
    var outlet_node = unit_heat.AirOutNode
    var control_node = unit_heat.HotControlNode
    var control_offset = unit_heat.HotControlOffset
    var fan_op = unit_heat.fanOp
    
    var q_unit_out: Float64 = 0.0
    var no_output: Float64 = 0.0
    var full_output: Float64 = 0.0
    var latent_output: Float64 = 0.0
    var max_water_flow: Float64 = 0.0
    var min_water_flow: Float64 = 0.0
    var part_load_frac: Float64 = 0.0
    
    if fan_op != 1:
        unit_heat_data.HCoilOn = False
        CalcUnitHeaterComponents(state, unit_heat_num, first_hvac_iteration, &q_unit_out)
    else:
        if unit_heat_data.QZnReq < 100.0 or state[].dataZoneEnergyDemand.CurDeadBandOrSetback[zone_num - 1]:
            part_load_frac = 0.0
            unit_heat_data.HCoilOn = False
            CalcUnitHeaterComponents(state, unit_heat_num, first_hvac_iteration, &q_unit_out, fan_op, part_load_frac)
        else:
            unit_heat_data.HCoilOn = True
            CalcUnitHeaterComponents(state, unit_heat_num, first_hvac_iteration, &q_unit_out, fan_op, part_load_frac)
    
    var spec_hum_out = state[].dataLoopNodes.Node[outlet_node].HumRat
    var spec_hum_in = state[].dataLoopNodes.Node[inlet_node].HumRat
    latent_output = state[].dataLoopNodes.Node[outlet_node].MassFlowRate * (spec_hum_out - spec_hum_in)
    
    unit_heat.HeatPower = math_max(0.0, q_unit_out)
    unit_heat.ElecPower = state[].dataFans.fans[unit_heat.Fan_Index - 1].totalPower
    
    power_met = q_unit_out
    lat_output_provided = latent_output

fn CalcUnitHeaterComponents(state: UnsafePointer[EnergyPlusData], unit_heat_num: Int32, first_hvac_iteration: Bool, inout load_met: Float64, fan_op: Int32 = 0, part_load_ratio: Float64 = 1.0):
    var unit_heat_data = state[].dataUnitHeaters
    var unit_heat = unit_heat_data.UnitHeat[unit_heat_num - 1]
    var inlet_node = unit_heat.AirInNode
    var outlet_node = unit_heat.AirOutNode
    
    if fan_op != 1:
        state[].dataFans.fans[unit_heat.Fan_Index - 1].simulate(state, first_hvac_iteration, UnsafePointer[Int8](), UnsafePointer[Int8]())
        if unit_heat.heatCoilType == 0:
            WaterCoils_SimulateWaterCoilComponents(state, unit_heat.HCoilName, first_hvac_iteration, unit_heat.HCoil_Index)
    else:
        state[].dataLoopNodes.Node[inlet_node].MassFlowRate = state[].dataLoopNodes.Node[inlet_node].MassFlowRateMax * part_load_ratio
        state[].dataFans.fans[unit_heat.Fan_Index - 1].simulate(state, first_hvac_iteration, UnsafePointer[Int8](), UnsafePointer[Int8]())
    
    load_met = 0.0

fn ReportUnitHeater(state: UnsafePointer[EnergyPlusData], unit_heat_num: Int32):
    var unit_heat_data = state[].dataUnitHeaters
    var unit_heat = unit_heat_data.UnitHeat[unit_heat_num - 1]
    var time_step_sys_sec = state[].dataHVACGlobal.TimeStepSysSec
    
    unit_heat.HeatEnergy = unit_heat.HeatPower * time_step_sys_sec
    unit_heat.ElecEnergy = unit_heat.ElecPower * time_step_sys_sec
    
    if unit_heat.FirstPass:
        if not state[].dataGlobal.SysSizingCalc:
            DataSizing_resetHVACSizingGlobals(state, state[].dataSize.CurZoneEqNum, 0, unit_heat.FirstPass)

fn getUnitHeaterIndex(state: UnsafePointer[EnergyPlusData], comp_name: StringLiteral) -> Int32:
    var unit_heat_data = state[].dataUnitHeaters
    if unit_heat_data.GetUnitHeaterInputFlag:
        GetUnitHeaterInput(state)
        unit_heat_data.GetUnitHeaterInputFlag = False
    
    for unit_heat_num in range(1, unit_heat_data.NumOfUnitHeats + 1):
        if Util_SameString(unit_heat_data.UnitHeat[unit_heat_num - 1].Name, comp_name):
            return unit_heat_num
    
    return 0
