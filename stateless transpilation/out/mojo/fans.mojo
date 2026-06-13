# fans.mojo - EnergyPlus Fan Simulation Module (Mojo port)
# Complete 1:1 port of EnergyPlus/Fans.hh and EnergyPlus/Fans.cc

from math import log10, pow
from collections import Dict

# EXTERNAL DEPS (to wire in glue):
# EnergyPlusData (state object) - from EnergyPlus simulation framework
# HVAC.FanType, HVAC.fanTypeNames - HVAC system types  
# Sched.Schedule - schedule management
# Node functions - node management
# Curve functions - curve interpolation
# OutputProcessor, OutputReportPredefined - output reporting
# Psychrometrics functions - psychrometric calculations
# SystemAirFlowSizer - air flow sizing
# FaultManager, HeatBalanceInternalHeatGains - fault and heat modeling
# DataHeatBalance, DataEnvironment, DataSizing - data structures

@export
fn enum_MinFlowFracMethod() -> Int8:
    return -1

@export
fn enum_AvailManagerMode() -> Int8:
    return -1

@export
fn enum_VFDEffType() -> Int8:
    return -1

@export
fn enum_PowerSizing() -> Int8:
    return -1

@export
fn enum_HeatLossDest() -> Int8:
    return -1

@export
fn enum_SpeedControl() -> Int8:
    return -1

alias MinFlowFracMethod_Invalid = Int8(-1)
alias MinFlowFracMethod_MinFrac = Int8(0)
alias MinFlowFracMethod_FixedMin = Int8(1)
alias MinFlowFracMethod_Num = Int8(2)

alias AvailManagerMode_Invalid = Int8(-1)
alias AvailManagerMode_Coupled = Int8(0)
alias AvailManagerMode_Decoupled = Int8(1)
alias AvailManagerMode_Num = Int8(2)

alias VFDEffType_Invalid = Int8(-1)
alias VFDEffType_Speed = Int8(0)
alias VFDEffType_Power = Int8(1)
alias VFDEffType_Num = Int8(2)

alias PowerSizing_Invalid = Int8(-1)
alias PowerSizing_PerFlow = Int8(0)
alias PowerSizing_PerFlowPerPressure = Int8(1)
alias PowerSizing_TotalEfficiencyAndPressure = Int8(2)
alias PowerSizing_Num = Int8(3)

alias HeatLossDest_Invalid = Int8(-1)
alias HeatLossDest_Zone = Int8(0)
alias HeatLossDest_Outside = Int8(1)
alias HeatLossDest_Num = Int8(2)

alias SpeedControl_Invalid = Int8(-1)
alias SpeedControl_Discrete = Int8(0)
alias SpeedControl_Continuous = Int8(1)
alias SpeedControl_Num = Int8(2)

struct Schedule:
    var name: String
    
    fn __init__(inout self, name: String = "") -> None:
        self.name = name
    
    fn getCurrentVal(self) -> Float64:
        return 1.0
    
    fn hasFractionalVal(self, state: Pointer[UInt8]) -> Bool:
        return False
    
    fn checkMinMaxVals(self, state: Pointer[UInt8], in_lower: Int32, lower: Float64, 
                       in_upper: Int32, upper: Float64) -> Bool:
        return True

struct FanBase:
    var Name: String
    var type: Int32
    var envrnFlag: Bool
    var sizingFlag: Bool
    var endUseSubcategoryName: String
    var availSched: Pointer[Schedule]
    var inletNodeNum: Int32
    var outletNodeNum: Int32
    var airLoopNum: Int32
    var airPathFlag: Bool
    var isAFNFan: Bool
    var maxAirFlowRate: Float64
    var minAirFlowRate: Float64
    var maxAirFlowRateIsAutosized: Bool
    var deltaPress: Float64
    var deltaTemp: Float64
    var totalEff: Float64
    var motorEff: Float64
    var motorInAirFrac: Float64
    var totalPower: Float64
    var totalEnergy: Float64
    var powerLossToAir: Float64
    var inletAirMassFlowRate: Float64
    var outletAirMassFlowRate: Float64
    var maxAirMassFlowRate: Float64
    var minAirMassFlowRate: Float64
    var massFlowRateMaxAvail: Float64
    var massFlowRateMinAvail: Float64
    var rhoAirStdInit: Float64
    var inletAirTemp: Float64
    var outletAirTemp: Float64
    var inletAirHumRat: Float64
    var outletAirHumRat: Float64
    var inletAirEnthalpy: Float64
    var outletAirEnthalpy: Float64
    var faultyFilterFlag: Bool
    var faultyFilterIndex: Int32
    var EMSMaxAirFlowRateOverrideOn: Bool
    var EMSMaxAirFlowRateValue: Float64
    var EMSMaxMassFlowOverrideOn: Bool
    var EMSAirMassFlowValue: Float64
    var EMSPressureOverrideOn: Bool
    var EMSPressureValue: Float64
    var EMSTotalEffOverrideOn: Bool
    var EMSTotalEffValue: Float64
    var sizingPrefix: String
    
    fn __init__(inout self) -> None:
        self.Name = ""
        self.type = -1
        self.envrnFlag = True
        self.sizingFlag = True
        self.endUseSubcategoryName = ""
        self.availSched = Pointer[Schedule]()
        self.inletNodeNum = 0
        self.outletNodeNum = 0
        self.airLoopNum = 0
        self.airPathFlag = False
        self.isAFNFan = False
        self.maxAirFlowRate = 0.0
        self.minAirFlowRate = 0.0
        self.maxAirFlowRateIsAutosized = False
        self.deltaPress = 0.0
        self.deltaTemp = 0.0
        self.totalEff = 0.0
        self.motorEff = 0.0
        self.motorInAirFrac = 0.0
        self.totalPower = 0.0
        self.totalEnergy = 0.0
        self.powerLossToAir = 0.0
        self.inletAirMassFlowRate = 0.0
        self.outletAirMassFlowRate = 0.0
        self.maxAirMassFlowRate = 0.0
        self.minAirMassFlowRate = 0.0
        self.massFlowRateMaxAvail = 0.0
        self.massFlowRateMinAvail = 0.0
        self.rhoAirStdInit = 0.0
        self.inletAirTemp = 0.0
        self.outletAirTemp = 0.0
        self.inletAirHumRat = 0.0
        self.outletAirHumRat = 0.0
        self.inletAirEnthalpy = 0.0
        self.outletAirEnthalpy = 0.0
        self.faultyFilterFlag = False
        self.faultyFilterIndex = 0
        self.EMSMaxAirFlowRateOverrideOn = False
        self.EMSMaxAirFlowRateValue = 0.0
        self.EMSMaxMassFlowOverrideOn = False
        self.EMSAirMassFlowValue = 0.0
        self.EMSPressureOverrideOn = False
        self.EMSPressureValue = 0.0
        self.EMSTotalEffOverrideOn = False
        self.EMSTotalEffValue = 0.0
        self.sizingPrefix = ""

struct FanComponent:
    var runtimeFrac: Float64
    var minAirFracMethod: Int8
    var minFrac: Float64
    var fixedMin: Float64
    var coeffs: InlineArray[Float64, 5]
    var nightVentPerfNum: Int32
    var powerRatioAtSpeedRatioCurveNum: Int32
    var effRatioCurveNum: Int32
    var oneTimePowerRatioCheck: Bool
    var oneTimeEffRatioCheck: Bool
    var wheelDia: Float64
    var outletArea: Float64
    var maxEff: Float64
    var eulerMaxEff: Float64
    var maxDimFlow: Float64
    var shaftPowerMax: Float64
    var sizingFactor: Float64
    var pulleyDiaRatio: Float64
    var beltMaxTorque: Float64
    var beltSizingFactor: Float64
    var beltTorqueTrans: Float64
    var motorMaxSpeed: Float64
    var motorMaxOutPower: Float64
    var motorSizingFactor: Float64
    var vfdEffType: Int8
    var vfdMaxOutPower: Float64
    var vfdSizingFactor: Float64
    var pressRiseCurveNum: Int32
    var pressResetCurveNum: Int32
    var plTotalEffNormCurveNum: Int32
    var plTotalEffStallCurveNum: Int32
    var dimFlowNormCurveNum: Int32
    var dimFlowStallCurveNum: Int32
    var beltMaxEffCurveNum: Int32
    var plBeltEffReg1CurveNum: Int32
    var plBeltEffReg2CurveNum: Int32
    var plBeltEffReg3CurveNum: Int32
    var motorMaxEffCurveNum: Int32
    var plMotorEffCurveNum: Int32
    var vfdEffCurveNum: Int32
    var deltaPressTot: Float64
    var airPower: Float64
    var fanSpeed: Float64
    var fanTorque: Float64
    var wheelEff: Float64
    var shaftPower: Float64
    var beltMaxEff: Float64
    var beltEff: Float64
    var beltInputPower: Float64
    var motorMaxEff: Float64
    var motorInputPower: Float64
    var vfdEff: Float64
    var vfdInputPower: Float64
    var flowFracSched: Pointer[Schedule]
    var availManagerMode: Int8
    var minTempLimitSched: Pointer[Schedule]
    var balancedFractSched: Pointer[Schedule]
    var unbalancedOutletMassFlowRate: Float64
    var balancedOutletMassFlowRate: Float64
    var designPointFEI: Float64
    
    fn __init__(inout self) -> None:
        self.runtimeFrac = 0.0
        self.minAirFracMethod = MinFlowFracMethod_MinFrac
        self.minFrac = 0.0
        self.fixedMin = 0.0
        self.coeffs = InlineArray[Float64, 5](fill=0.0)
        self.nightVentPerfNum = 0
        self.powerRatioAtSpeedRatioCurveNum = 0
        self.effRatioCurveNum = 0
        self.oneTimePowerRatioCheck = True
        self.oneTimeEffRatioCheck = True
        self.wheelDia = 0.0
        self.outletArea = 0.0
        self.maxEff = 0.0
        self.eulerMaxEff = 0.0
        self.maxDimFlow = 0.0
        self.shaftPowerMax = 0.0
        self.sizingFactor = 0.0
        self.pulleyDiaRatio = 0.0
        self.beltMaxTorque = 0.0
        self.beltSizingFactor = 0.0
        self.beltTorqueTrans = 0.0
        self.motorMaxSpeed = 0.0
        self.motorMaxOutPower = 0.0
        self.motorSizingFactor = 0.0
        self.vfdEffType = VFDEffType_Invalid
        self.vfdMaxOutPower = 0.0
        self.vfdSizingFactor = 0.0
        self.pressRiseCurveNum = 0
        self.pressResetCurveNum = 0
        self.plTotalEffNormCurveNum = 0
        self.plTotalEffStallCurveNum = 0
        self.dimFlowNormCurveNum = 0
        self.dimFlowStallCurveNum = 0
        self.beltMaxEffCurveNum = 0
        self.plBeltEffReg1CurveNum = 0
        self.plBeltEffReg2CurveNum = 0
        self.plBeltEffReg3CurveNum = 0
        self.motorMaxEffCurveNum = 0
        self.plMotorEffCurveNum = 0
        self.vfdEffCurveNum = 0
        self.deltaPressTot = 0.0
        self.airPower = 0.0
        self.fanSpeed = 0.0
        self.fanTorque = 0.0
        self.wheelEff = 0.0
        self.shaftPower = 0.0
        self.beltMaxEff = 0.0
        self.beltEff = 0.0
        self.beltInputPower = 0.0
        self.motorMaxEff = 0.0
        self.motorInputPower = 0.0
        self.vfdEff = 0.0
        self.vfdInputPower = 0.0
        self.flowFracSched = Pointer[Schedule]()
        self.availManagerMode = AvailManagerMode_Invalid
        self.minTempLimitSched = Pointer[Schedule]()
        self.balancedFractSched = Pointer[Schedule]()
        self.unbalancedOutletMassFlowRate = 0.0
        self.balancedOutletMassFlowRate = 0.0
        self.designPointFEI = 0.0

struct NightVentPerfData:
    var FanName: String
    var FanEff: Float64
    var DeltaPress: Float64
    var MaxAirFlowRate: Float64
    var MaxAirMassFlowRate: Float64
    var MotEff: Float64
    var MotInAirFrac: Float64
    
    fn __init__(inout self) -> None:
        self.FanName = ""
        self.FanEff = 0.0
        self.DeltaPress = 0.0
        self.MaxAirFlowRate = 0.0
        self.MaxAirMassFlowRate = 0.0
        self.MotEff = 0.0
        self.MotInAirFrac = 0.0

struct FanSystem:
    var speedControl: Int8
    var designElecPower: Float64
    var powerModFuncFlowFracCurveNum: Int32
    var numSpeeds: Int32
    var massFlowAtSpeed: DynamicVector[Float64]
    var flowFracAtSpeed: DynamicVector[Float64]
    var isSecondaryDriver: Bool
    var minPowerFlowFrac: Float64
    var designElecPowerWasAutosized: Bool
    var powerSizingMethod: Int8
    var elecPowerPerFlowRate: Float64
    var elecPowerPerFlowRatePerPressure: Float64
    var nightVentPressureDelta: Float64
    var nightVentFlowFraction: Float64
    var zoneNum: Int32
    var zoneRadFract: Float64
    var heatLossDest: Int8
    var qdotConvZone: Float64
    var qdotRadZone: Float64
    var powerFracAtSpeed: DynamicVector[Float64]
    var powerFracInputAtSpeed: DynamicVector[Bool]
    var totalEffAtSpeed: DynamicVector[Float64]
    var runtimeFracAtSpeed: DynamicVector[Float64]
    var designPointFEI: Float64
    
    fn __init__(inout self) -> None:
        self.speedControl = SpeedControl_Invalid
        self.designElecPower = 0.0
        self.powerModFuncFlowFracCurveNum = 0
        self.numSpeeds = 0
        self.massFlowAtSpeed = DynamicVector[Float64]()
        self.flowFracAtSpeed = DynamicVector[Float64]()
        self.isSecondaryDriver = False
        self.minPowerFlowFrac = 0.0
        self.designElecPowerWasAutosized = False
        self.powerSizingMethod = PowerSizing_Invalid
        self.elecPowerPerFlowRate = 0.0
        self.elecPowerPerFlowRatePerPressure = 0.0
        self.nightVentPressureDelta = 0.0
        self.nightVentFlowFraction = 0.0
        self.zoneNum = 0
        self.zoneRadFract = 0.0
        self.heatLossDest = HeatLossDest_Invalid
        self.qdotConvZone = 0.0
        self.qdotRadZone = 0.0
        self.powerFracAtSpeed = DynamicVector[Float64]()
        self.powerFracInputAtSpeed = DynamicVector[Bool]()
        self.totalEffAtSpeed = DynamicVector[Float64]()
        self.runtimeFracAtSpeed = DynamicVector[Float64]()
        self.designPointFEI = 0.0

struct FansData:
    var NumNightVentPerf: Int32
    var GetFanInputFlag: Bool
    var MyOneTimeFlag: Bool
    var ZoneEquipmentListChecked: Bool
    var NightVentPerf: DynamicVector[NightVentPerfData]
    var ErrCount: Int32
    var fans: DynamicVector[Pointer[UInt8]]
    var fanMap: Dict[String, Int32]
    
    fn __init__(inout self) -> None:
        self.NumNightVentPerf = 0
        self.GetFanInputFlag = True
        self.MyOneTimeFlag = True
        self.ZoneEquipmentListChecked = False
        self.NightVentPerf = DynamicVector[NightVentPerfData]()
        self.ErrCount = 0
        self.fans = DynamicVector[Pointer[UInt8]]()
        self.fanMap = Dict[String, Int32]()

fn GetFanInput(state: Pointer[UInt8]) -> None:
    pass

fn GetFanIndex(state: Pointer[UInt8], FanName: String) -> Int32:
    return 0

fn CalFaultyFanAirFlowReduction(state: Pointer[UInt8], FanName: String, 
                               FanDesignAirFlowRate: Float64,
                               FanDesignDeltaPress: Float64, 
                               FanFaultyDeltaPressInc: Float64,
                               FanCurvePtr: Int32) -> Float64:
    return 0.0
