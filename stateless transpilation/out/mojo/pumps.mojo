from collections import InlineArray
from math import sqrt, ceil
from dataclasses import dataclass


struct PumpControlType:
    alias Invalid = -1
    alias Continuous = 0
    alias Intermittent = 1
    alias Num = 2


struct ControlTypeVFD:
    alias Invalid = -1
    alias VFDManual = 0
    alias VFDAutomatic = 1
    alias Num = 2


struct PumpBankControlSeq:
    alias Invalid = -1
    alias OptimalScheme = 0
    alias SequentialScheme = 1
    alias UserDefined = 2
    alias Num = 3


struct PumpType:
    alias Invalid = -1
    alias VarSpeed = 0
    alias ConSpeed = 1
    alias Cond = 2
    alias Bank_VarSpeed = 3
    alias Bank_ConSpeed = 4
    alias Num = 5


struct PowerSizingMethod:
    alias Invalid = -1
    alias SizePowerPerFlow = 0
    alias SizePowerPerFlowPerPressure = 1
    alias Num = 2


fn get_pump_type_idf_names() -> InlineArray[String, 5]:
    var names = InlineArray[String, 5](fill="")
    names[0] = "Pump:VariableSpeed"
    names[1] = "Pump:ConstantSpeed"
    names[2] = "Pump:VariableSpeed:Condensate"
    names[3] = "HeaderedPumps:VariableSpeed"
    names[4] = "HeaderedPumps:ConstantSpeed"
    return names


struct PumpVFDControlData:
    var Name: String
    var manualRPMSched: UnsafePointer[NoneType]
    var lowerPsetSched: UnsafePointer[NoneType]
    var upperPsetSched: UnsafePointer[NoneType]
    var minRPMSched: UnsafePointer[NoneType]
    var maxRPMSched: UnsafePointer[NoneType]
    var VFDControlType: Int
    var MaxRPM: Float64
    var MinRPM: Float64
    var PumpActualRPM: Float64

    fn __init__(inout self):
        self.Name = ""
        self.manualRPMSched = UnsafePointer[NoneType]()
        self.lowerPsetSched = UnsafePointer[NoneType]()
        self.upperPsetSched = UnsafePointer[NoneType]()
        self.minRPMSched = UnsafePointer[NoneType]()
        self.maxRPMSched = UnsafePointer[NoneType]()
        self.VFDControlType = ControlTypeVFD.Invalid
        self.MaxRPM = 0.0
        self.MinRPM = 0.0
        self.PumpActualRPM = 0.0


struct PumpSpecs:
    var Name: String
    var pumpType: Int
    var TypeOf_Num: UnsafePointer[NoneType]
    var plantLoc: UnsafePointer[NoneType]
    var PumpControl: Int
    var flowRateSched: UnsafePointer[NoneType]
    var InletNodeNum: Int
    var OutletNodeNum: Int
    var SequencingScheme: Int
    var NumPumpsInBank: Int
    var PowerErrIndex1: Int
    var PowerErrIndex2: Int
    var MinVolFlowRateFrac: Float64
    var NomVolFlowRate: Float64
    var NomVolFlowRateWasAutoSized: Bool
    var MassFlowRateMax: Float64
    var EMSMassFlowOverrideOn: Bool
    var EMSMassFlowValue: Float64
    var NomSteamVolFlowRate: Float64
    var NomSteamVolFlowRateWasAutoSized: Bool
    var MinVolFlowRate: Float64
    var minVolFlowRateWasAutosized: Bool
    var MassFlowRateMin: Float64
    var NomPumpHead: Float64
    var EMSPressureOverrideOn: Bool
    var EMSPressureOverrideValue: Float64
    var NomPowerUse: Float64
    var NomPowerUseWasAutoSized: Bool
    var powerSizingMethod: Int
    var powerPerFlowScalingFactor: Float64
    var powerPerFlowPerPressureScalingFactor: Float64
    var MotorEffic: Float64
    var PumpEffic: Float64
    var FracMotorLossToFluid: Float64
    var Energy: Float64
    var Power: Float64
    var PartLoadCoef: InlineArray[Float64, 4]
    var PressureCurve_Index: Int
    var PumpMassFlowRateMaxRPM: Float64
    var PumpMassFlowRateMinRPM: Float64
    var MinPhiValue: Float64
    var MaxPhiValue: Float64
    var ImpellerDiameter: Float64
    var RotSpeed_RPM: Float64
    var RotSpeed: Float64
    var PumpInitFlag: Bool
    var PumpOneTimeFlag: Bool
    var CheckEquipName: Bool
    var HasVFD: Bool
    var VFD: PumpVFDControlData
    var OneTimePressureWarning: Bool
    var HeatLossesToZone: Bool
    var ZoneNum: Int
    var SkinLossRadFraction: Float64
    var LoopSolverOverwriteFlag: Bool
    var EndUseSubcategoryName: String

    fn __init__(inout self):
        self.Name = ""
        self.pumpType = PumpType.Invalid
        self.TypeOf_Num = UnsafePointer[NoneType]()
        self.plantLoc = UnsafePointer[NoneType]()
        self.PumpControl = PumpControlType.Invalid
        self.flowRateSched = UnsafePointer[NoneType]()
        self.InletNodeNum = 0
        self.OutletNodeNum = 0
        self.SequencingScheme = PumpBankControlSeq.Invalid
        self.NumPumpsInBank = 0
        self.PowerErrIndex1 = 0
        self.PowerErrIndex2 = 0
        self.MinVolFlowRateFrac = 0.0
        self.NomVolFlowRate = 0.0
        self.NomVolFlowRateWasAutoSized = False
        self.MassFlowRateMax = 0.0
        self.EMSMassFlowOverrideOn = False
        self.EMSMassFlowValue = 0.0
        self.NomSteamVolFlowRate = 0.0
        self.NomSteamVolFlowRateWasAutoSized = False
        self.MinVolFlowRate = 0.0
        self.minVolFlowRateWasAutosized = False
        self.MassFlowRateMin = 0.0
        self.NomPumpHead = 0.0
        self.EMSPressureOverrideOn = False
        self.EMSPressureOverrideValue = 0.0
        self.NomPowerUse = 0.0
        self.NomPowerUseWasAutoSized = False
        self.powerSizingMethod = PowerSizingMethod.SizePowerPerFlowPerPressure
        self.powerPerFlowScalingFactor = 348701.1
        self.powerPerFlowPerPressureScalingFactor = 1.0 / 0.78
        self.MotorEffic = 0.0
        self.PumpEffic = 0.0
        self.FracMotorLossToFluid = 0.0
        self.Energy = 0.0
        self.Power = 0.0
        self.PartLoadCoef = InlineArray[Float64, 4](fill=0.0)
        self.PressureCurve_Index = 0
        self.PumpMassFlowRateMaxRPM = 0.0
        self.PumpMassFlowRateMinRPM = 0.0
        self.MinPhiValue = 0.0
        self.MaxPhiValue = 0.0
        self.ImpellerDiameter = 0.0
        self.RotSpeed_RPM = 0.0
        self.RotSpeed = 0.0
        self.PumpInitFlag = True
        self.PumpOneTimeFlag = True
        self.CheckEquipName = True
        self.HasVFD = False
        self.VFD = PumpVFDControlData()
        self.OneTimePressureWarning = True
        self.HeatLossesToZone = False
        self.ZoneNum = 0
        self.SkinLossRadFraction = 0.0
        self.LoopSolverOverwriteFlag = False
        self.EndUseSubcategoryName = ""


struct ReportVars:
    var NumPumpsOperating: Int
    var PumpMassFlowRate: Float64
    var PumpHeattoFluid: Float64
    var PumpHeattoFluidEnergy: Float64
    var OutletTemp: Float64
    var ShaftPower: Float64
    var ZoneTotalGainRate: Float64
    var ZoneTotalGainEnergy: Float64
    var ZoneConvGainRate: Float64
    var ZoneRadGainRate: Float64

    fn __init__(inout self):
        self.NumPumpsOperating = 0
        self.PumpMassFlowRate = 0.0
        self.PumpHeattoFluid = 0.0
        self.PumpHeattoFluidEnergy = 0.0
        self.OutletTemp = 0.0
        self.ShaftPower = 0.0
        self.ZoneTotalGainRate = 0.0
        self.ZoneTotalGainEnergy = 0.0
        self.ZoneConvGainRate = 0.0
        self.ZoneRadGainRate = 0.0


struct PumpsData:
    var NumPumps: Int
    var NumPumpsRunning: Int
    var NumPumpsFullLoad: Int
    var GetInputFlag: Bool
    var PumpMassFlowRate: Float64
    var PumpHeattoFluid: Float64
    var Power: Float64
    var ShaftPower: Float64
    var PumpEquip: DynamicVector[PumpSpecs]
    var PumpEquipReport: DynamicVector[ReportVars]
    var PumpUniqueNames: DynamicVector[String]

    fn __init__(inout self):
        self.NumPumps = 0
        self.NumPumpsRunning = 0
        self.NumPumpsFullLoad = 0
        self.GetInputFlag = True
        self.PumpMassFlowRate = 0.0
        self.PumpHeattoFluid = 0.0
        self.Power = 0.0
        self.ShaftPower = 0.0
        self.PumpEquip = DynamicVector[PumpSpecs]()
        self.PumpEquipReport = DynamicVector[ReportVars]()
        self.PumpUniqueNames = DynamicVector[String]()

    fn clear_state(inout self):
        self.NumPumps = 0
        self.NumPumpsRunning = 0
        self.NumPumpsFullLoad = 0
        self.GetInputFlag = True
        self.PumpMassFlowRate = 0.0
        self.PumpHeattoFluid = 0.0
        self.Power = 0.0
        self.ShaftPower = 0.0
        self.PumpEquip.clear()
        self.PumpEquipReport.clear()
        self.PumpUniqueNames.clear()


@export
fn sim_pumps(
    state: UnsafePointer[NoneType],
    pump_name: String,
    loop_num: Int,
    flow_request: Float64,
) -> (Bool, Int, Float64):
    var pump_index: Int = 0
    var pump_running: Bool = False
    var pump_heat: Float64 = 0.0

    return (pump_running, pump_index, pump_heat)


fn get_pump_input(state: UnsafePointer[NoneType]) -> None:
    pass


fn initialize_pumps(state: UnsafePointer[NoneType], pump_num: Int) -> None:
    pass


fn setup_pump_min_max_flows(
    state: UnsafePointer[NoneType], loop_num: Int, pump_num: Int
) -> None:
    pass


fn calc_pumps(
    state: UnsafePointer[NoneType], pump_num: Int, flow_request: Float64
) -> None:
    pass


fn size_pump(state: UnsafePointer[NoneType], pump_num: Int) -> None:
    pass


fn report_pumps(state: UnsafePointer[NoneType], pump_num: Int) -> None:
    pass


fn pump_data_for_table(state: UnsafePointer[NoneType], num_pump: Int) -> None:
    pass


fn get_required_mass_flow_rate(
    state: UnsafePointer[NoneType],
    loop_num: Int,
    pump_num: Int,
    inlet_node_mass_flow_rate: Float64,
) -> (Float64, Float64, Float64):
    var actual_flow_rate: Float64 = 0.0
    var pump_min_mass_flow_rate_vfd_range: Float64 = 0.0
    var pump_max_mass_flow_rate_vfd_range: Float64 = 0.0

    return (actual_flow_rate, pump_min_mass_flow_rate_vfd_range, pump_max_mass_flow_rate_vfd_range)


alias MASS_FLOW_TOLERANCE = 0.001
alias SMALL_WATER_VOL_FLOW = 0.00001
alias INIT_CONV_TEMP = 20.0
alias AUTO_SIZE = -99999.0
alias AVAIL_STATUS_FORCE_OFF = 0
alias CONTROL_TYPE_SERIES_ACTIVE = 1
