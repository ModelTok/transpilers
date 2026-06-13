from collections import InlineArray
from math import sqrt, floor, ceil

alias Real64 = Float64
alias INVALID = -1
alias KELVIN = 273.15

@value
struct AmbientTempIndicator:
    var value: Int32
    
    fn __eq__(self, other: AmbientTempIndicator) -> Bool:
        return self.value == other.value
    
    fn __ne__(self, other: AmbientTempIndicator) -> Bool:
        return self.value != other.value
    
    @staticmethod
    fn Invalid() -> AmbientTempIndicator:
        return AmbientTempIndicator(-1)
    
    @staticmethod
    fn Schedule() -> AmbientTempIndicator:
        return AmbientTempIndicator(0)
    
    @staticmethod
    fn TempZone() -> AmbientTempIndicator:
        return AmbientTempIndicator(1)
    
    @staticmethod
    fn OutsideAir() -> AmbientTempIndicator:
        return AmbientTempIndicator(2)
    
    @staticmethod
    fn ZoneAndOA() -> AmbientTempIndicator:
        return AmbientTempIndicator(3)

@value
struct InterpolationMethod:
    var value: Int32
    
    @staticmethod
    fn Linear() -> InterpolationMethod:
        return InterpolationMethod(0)
    
    @staticmethod
    fn Cubic() -> InterpolationMethod:
        return InterpolationMethod(1)

@value
struct FlowMode:
    var value: Int32
    
    @staticmethod
    fn Invalid() -> FlowMode:
        return FlowMode(-1)
    
    @staticmethod
    fn Constant() -> FlowMode:
        return FlowMode(0)
    
    @staticmethod
    fn NotModulated() -> FlowMode:
        return FlowMode(1)
    
    @staticmethod
    fn LeavingSetpointModulated() -> FlowMode:
        return FlowMode(2)

@value
struct CondenserType:
    var value: Int32
    
    @staticmethod
    fn WaterCooled() -> CondenserType:
        return CondenserType(0)
    
    @staticmethod
    fn AirCooled() -> CondenserType:
        return CondenserType(1)

@value
struct LoopSideLocation:
    var value: Int32
    
    @staticmethod
    fn Invalid() -> LoopSideLocation:
        return LoopSideLocation(-1)
    
    @staticmethod
    fn Supply() -> LoopSideLocation:
        return LoopSideLocation(0)
    
    @staticmethod
    fn Demand() -> LoopSideLocation:
        return LoopSideLocation(1)

@value
struct OpScheme:
    var value: Int32
    
    @staticmethod
    fn Invalid() -> OpScheme:
        return OpScheme(-1)
    
    @staticmethod
    fn CompSetPtBased() -> OpScheme:
        return OpScheme(0)

@value
struct LoopDemandCalcScheme:
    var value: Int32
    
    @staticmethod
    fn SingleSetPoint() -> LoopDemandCalcScheme:
        return LoopDemandCalcScheme(0)
    
    @staticmethod
    fn DualSetPointDeadBand() -> LoopDemandCalcScheme:
        return LoopDemandCalcScheme(1)

@value
struct FlowLock:
    var value: Int32
    
    @staticmethod
    fn Unlocked() -> FlowLock:
        return FlowLock(0)
    
    @staticmethod
    fn Locked() -> FlowLock:
        return FlowLock(1)

@value
struct CriteriaType:
    var value: Int32
    
    @staticmethod
    fn MassFlowRate() -> CriteriaType:
        return CriteriaType(0)

struct Node:
    var Temp: Real64
    var MassFlowRate: Real64
    var TempSetPoint: Real64
    var TempSetPointHi: Real64
    
    fn __init__() -> Self:
        return Node(
            Temp=0.0,
            MassFlowRate=0.0,
            TempSetPoint=-999999.0,
            TempSetPointHi=-999999.0
        )

struct Glycol:
    fn get_density(inout self, state: UnsafePointer[Byte], temp: Real64, routine_name: StringRef) -> Real64:
        return 1000.0
    
    fn get_specific_heat(inout self, state: UnsafePointer[Byte], temp: Real64, routine_name: StringRef) -> Real64:
        return 4186.0

struct LoopData:
    var PlantSizNum: Int32
    var glycol: Glycol
    var LoopDemandCalcScheme: Int32
    var TempSetPointNodeNum: Int32

struct PlantSide:
    var FlowLock: FlowLock

struct PlantComponent:
    var FlowCtrl: Int32
    var FlowPriority: Int32
    var CurOpSchemeType: OpScheme

struct PlantLocation:
    var loop_num: Int32
    var loop_side_num: LoopSideLocation
    var branch_num: Int32
    var comp_num: Int32
    var loop: UnsafePointer[LoopData]
    var side: UnsafePointer[PlantSide]
    var comp: UnsafePointer[PlantComponent]
    
    fn __init__() -> Self:
        return PlantLocation(
            loop_num=0,
            loop_side_num=LoopSideLocation.Invalid(),
            branch_num=0,
            comp_num=0,
            loop=UnsafePointer[LoopData](),
            side=UnsafePointer[PlantSide](),
            comp=UnsafePointer[PlantComponent]()
        )

struct Schedule:
    fn get_current_val(inout self) -> Real64:
        return 0.0

struct PerformanceMapResult:
    var net_evaporator_capacity: Real64
    var input_power: Real64
    var net_condenser_capacity: Real64
    var oil_cooler_heat: Real64
    var auxiliary_heat: Real64

struct PerformanceMap:
    fn calculate_performance(inout self, evap_flow: Real64, evap_temp: Real64, cond_flow: Real64, 
                            cond_temp: Real64, seq_num: Real64, interp_method: InterpolationMethod) -> PerformanceMapResult:
        return PerformanceMapResult(
            net_evaporator_capacity=0.0,
            input_power=0.0,
            net_condenser_capacity=0.0,
            oil_cooler_heat=0.0,
            auxiliary_heat=0.0
        )
    
    fn get_logger(inout self) -> UnsafePointer[Byte]:
        return UnsafePointer[Byte]()

struct GridVariables:
    var compressor_sequence_number: DynamicVector[Real64]

struct RS0001Performance:
    var performance_map_cooling: PerformanceMap
    var performance_map_standby: PerformanceMap
    var cycling_degradation_coefficient: Real64
    var grid_variables: GridVariables

struct RS0001:
    var performance: RS0001Performance

struct ElectricEIRChillerSpecs:
    var Name: String
    var ObjectType: String
    var RefCap: Real64
    var RefCapWasAutoSized: Bool
    var RefCOP: Real64
    var EvapInletNodeNum: Int32
    var EvapOutletNodeNum: Int32
    var EvapVolFlowRate: Real64
    var EvapVolFlowRateWasAutoSized: Bool
    var CondInletNodeNum: Int32
    var CondOutletNodeNum: Int32
    var CondVolFlowRate: Real64
    var CondVolFlowRateWasAutoSized: Bool
    var FlowMode: FlowMode
    var CondenserType: CondenserType
    var SizFac: Real64
    var CWPlantLoc: PlantLocation
    var CDPlantLoc: PlantLocation
    var MyEnvrnFlag: Bool
    var ModulatedFlowSetToLoop: Bool
    var ModulatedFlowErrDone: Bool
    var ChillerPartLoadRatio: Real64
    var ChillerCyclingRatio: Real64
    var ChillerFalseLoadRate: Real64
    var ChillerFalseLoad: Real64
    var PossibleSubcooling: Bool
    var EvapMassFlowRateMax: Real64
    var EvapMassFlowRate: Real64
    var CondMassFlowRateMax: Real64
    var CondMassFlowRate: Real64
    var CondMassFlowIndex: Int32
    var EquipFlowCtrl: Int32
    var Power: Real64
    var QEvaporator: Real64
    var QCondenser: Real64
    var Energy: Real64
    var EvapEnergy: Real64
    var CondEnergy: Real64
    var EvapInletTemp: Real64
    var EvapOutletTemp: Real64
    var CondInletTemp: Real64
    var CondOutletTemp: Real64
    var ActualCOP: Real64
    var ChillerCondAvgTemp: Real64
    var MinPartLoadRat: Real64
    var TempRefCondIn: Real64
    var TempRefEvapOut: Real64
    var CompPowerToCondenserFrac: Real64
    var DeltaTErrCount: Int32
    var DeltaTErrCountIndex: Int32
    var ChillerCapFTError: Int32
    
    fn __init__() -> Self:
        return ElectricEIRChillerSpecs(
            Name="",
            ObjectType="Chiller:Electric:ASHRAE205",
            RefCap=0.0,
            RefCapWasAutoSized=False,
            RefCOP=3.0,
            EvapInletNodeNum=0,
            EvapOutletNodeNum=0,
            EvapVolFlowRate=0.0,
            EvapVolFlowRateWasAutoSized=False,
            CondInletNodeNum=0,
            CondOutletNodeNum=0,
            CondVolFlowRate=0.0,
            CondVolFlowRateWasAutoSized=False,
            FlowMode=FlowMode.NotModulated(),
            CondenserType=CondenserType.WaterCooled(),
            SizFac=1.0,
            CWPlantLoc=PlantLocation(),
            CDPlantLoc=PlantLocation(),
            MyEnvrnFlag=True,
            ModulatedFlowSetToLoop=False,
            ModulatedFlowErrDone=False,
            ChillerPartLoadRatio=0.0,
            ChillerCyclingRatio=1.0,
            ChillerFalseLoadRate=0.0,
            ChillerFalseLoad=0.0,
            PossibleSubcooling=False,
            EvapMassFlowRateMax=0.0,
            EvapMassFlowRate=0.0,
            CondMassFlowRateMax=0.0,
            CondMassFlowRate=0.0,
            CondMassFlowIndex=0,
            EquipFlowCtrl=0,
            Power=0.0,
            QEvaporator=0.0,
            QCondenser=0.0,
            Energy=0.0,
            EvapEnergy=0.0,
            CondEnergy=0.0,
            EvapInletTemp=0.0,
            EvapOutletTemp=0.0,
            CondInletTemp=0.0,
            CondOutletTemp=0.0,
            ActualCOP=0.0,
            ChillerCondAvgTemp=0.0,
            MinPartLoadRat=0.0,
            TempRefCondIn=29.44,
            TempRefEvapOut=6.67,
            CompPowerToCondenserFrac=0.0,
            DeltaTErrCount=0,
            DeltaTErrCountIndex=0,
            ChillerCapFTError=0
        )

struct ASHRAE205ChillerSpecs(ElectricEIRChillerSpecs):
    var Representation: UnsafePointer[RS0001]
    var InterpolationType: InterpolationMethod
    var MinSequenceNumber: Real64
    var MaxSequenceNumber: Real64
    var OilCoolerInletNode: Int32
    var OilCoolerOutletNode: Int32
    var OilCoolerVolFlowRate: Real64
    var OilCoolerMassFlowRate: Real64
    var OCPlantLoc: PlantLocation
    var AuxiliaryHeatInletNode: Int32
    var AuxiliaryHeatOutletNode: Int32
    var AuxiliaryVolFlowRate: Real64
    var AuxiliaryMassFlowRate: Real64
    var AHPlantLoc: PlantLocation
    var QOilCooler: Real64
    var QAuxiliary: Real64
    var OilCoolerEnergy: Real64
    var AuxiliaryEnergy: Real64
    var AmbientTempType: AmbientTempIndicator
    var ambientTempSched: UnsafePointer[Schedule]
    var AmbientTempZone: Int32
    var AmbientTempOutsideAirNode: Int32
    var AmbientTemp: Real64
    var AmbientZoneGain: Real64
    var AmbientZoneGainEnergy: Real64
    var EndUseSubcategory: String
    
    fn __init__() -> Self:
        var base = ElectricEIRChillerSpecs()
        return ASHRAE205ChillerSpecs(
            Name=base.Name,
            ObjectType=base.ObjectType,
            RefCap=base.RefCap,
            RefCapWasAutoSized=base.RefCapWasAutoSized,
            RefCOP=base.RefCOP,
            EvapInletNodeNum=base.EvapInletNodeNum,
            EvapOutletNodeNum=base.EvapOutletNodeNum,
            EvapVolFlowRate=base.EvapVolFlowRate,
            EvapVolFlowRateWasAutoSized=base.EvapVolFlowRateWasAutoSized,
            CondInletNodeNum=base.CondInletNodeNum,
            CondOutletNodeNum=base.CondOutletNodeNum,
            CondVolFlowRate=base.CondVolFlowRate,
            CondVolFlowRateWasAutoSized=base.CondVolFlowRateWasAutoSized,
            FlowMode=base.FlowMode,
            CondenserType=base.CondenserType,
            SizFac=base.SizFac,
            CWPlantLoc=base.CWPlantLoc,
            CDPlantLoc=base.CDPlantLoc,
            MyEnvrnFlag=base.MyEnvrnFlag,
            ModulatedFlowSetToLoop=base.ModulatedFlowSetToLoop,
            ModulatedFlowErrDone=base.ModulatedFlowErrDone,
            ChillerPartLoadRatio=base.ChillerPartLoadRatio,
            ChillerCyclingRatio=base.ChillerCyclingRatio,
            ChillerFalseLoadRate=base.ChillerFalseLoadRate,
            ChillerFalseLoad=base.ChillerFalseLoad,
            PossibleSubcooling=base.PossibleSubcooling,
            EvapMassFlowRateMax=base.EvapMassFlowRateMax,
            EvapMassFlowRate=base.EvapMassFlowRate,
            CondMassFlowRateMax=base.CondMassFlowRateMax,
            CondMassFlowRate=base.CondMassFlowRate,
            CondMassFlowIndex=base.CondMassFlowIndex,
            EquipFlowCtrl=base.EquipFlowCtrl,
            Power=base.Power,
            QEvaporator=base.QEvaporator,
            QCondenser=base.QCondenser,
            Energy=base.Energy,
            EvapEnergy=base.EvapEnergy,
            CondEnergy=base.CondEnergy,
            EvapInletTemp=base.EvapInletTemp,
            EvapOutletTemp=base.EvapOutletTemp,
            CondInletTemp=base.CondInletTemp,
            CondOutletTemp=base.CondOutletTemp,
            ActualCOP=base.ActualCOP,
            ChillerCondAvgTemp=base.ChillerCondAvgTemp,
            MinPartLoadRat=base.MinPartLoadRat,
            TempRefCondIn=base.TempRefCondIn,
            TempRefEvapOut=base.TempRefEvapOut,
            CompPowerToCondenserFrac=base.CompPowerToCondenserFrac,
            DeltaTErrCount=base.DeltaTErrCount,
            DeltaTErrCountIndex=base.DeltaTErrCountIndex,
            ChillerCapFTError=base.ChillerCapFTError,
            Representation=UnsafePointer[RS0001](),
            InterpolationType=InterpolationMethod.Linear(),
            MinSequenceNumber=1.0,
            MaxSequenceNumber=1.0,
            OilCoolerInletNode=0,
            OilCoolerOutletNode=0,
            OilCoolerVolFlowRate=0.0,
            OilCoolerMassFlowRate=0.0,
            OCPlantLoc=PlantLocation(),
            AuxiliaryHeatInletNode=0,
            AuxiliaryHeatOutletNode=0,
            AuxiliaryVolFlowRate=0.0,
            AuxiliaryMassFlowRate=0.0,
            AHPlantLoc=PlantLocation(),
            QOilCooler=0.0,
            QAuxiliary=0.0,
            OilCoolerEnergy=0.0,
            AuxiliaryEnergy=0.0,
            AmbientTempType=AmbientTempIndicator.Invalid(),
            ambientTempSched=UnsafePointer[Schedule](),
            AmbientTempZone=0,
            AmbientTempOutsideAirNode=0,
            AmbientTemp=0.0,
            AmbientZoneGain=0.0,
            AmbientZoneGainEnergy=0.0,
            EndUseSubcategory="General"
        )

struct ChillerElectricASHRAE205Data:
    var getInputFlag: Bool
    var Electric205Chiller: DynamicVector[ASHRAE205ChillerSpecs]
    
    fn __init__() -> Self:
        return ChillerElectricASHRAE205Data(
            getInputFlag=True,
            Electric205Chiller=DynamicVector[ASHRAE205ChillerSpecs]()
        )

fn get_chiller_ashrae205_input(state: UnsafePointer[Byte]) -> None:
    pass

fn one_time_init_new(inout self: ASHRAE205ChillerSpecs, state: UnsafePointer[Byte]) -> None:
    if self.FlowMode.value == FlowMode.Constant().value:
        pass
    elif self.FlowMode.value == FlowMode.LeavingSetpointModulated().value:
        self.ModulatedFlowSetToLoop = True

fn initialize(inout self: ASHRAE205ChillerSpecs, state: UnsafePointer[Byte], run_flag: Bool, my_load: Real64) -> None:
    self.EquipFlowCtrl = 0
    
    if self.MyEnvrnFlag:
        var rho: Real64 = 1000.0
        self.EvapMassFlowRateMax = rho * self.EvapVolFlowRate
        
        if self.CondenserType.value == CondenserType.WaterCooled().value:
            rho = 1000.0
            self.CondMassFlowRateMax = rho * self.CondVolFlowRate
        
        if self.OilCoolerInletNode != 0:
            var rho_oil_cooler: Real64 = 1000.0
            self.OilCoolerMassFlowRate = rho_oil_cooler * self.OilCoolerVolFlowRate
        
        if self.AuxiliaryHeatInletNode != 0:
            var rho_aux: Real64 = 1000.0
            self.AuxiliaryMassFlowRate = rho_aux * self.AuxiliaryVolFlowRate
    
    self.MyEnvrnFlag = False

fn size(inout self: ASHRAE205ChillerSpecs, state: UnsafePointer[Byte]) -> None:
    var tmp_nom_cap: Real64 = 0.0
    var tmp_evap_vol_flow_rate: Real64 = self.EvapVolFlowRate
    var tmp_cond_vol_flow_rate: Real64 = self.CondVolFlowRate

fn set_output_variables(inout self: ASHRAE205ChillerSpecs, state: UnsafePointer[Byte]) -> None:
    pass

fn find_evaporator_mass_flow_rate(inout self: ASHRAE205ChillerSpecs, state: UnsafePointer[Byte], 
                                  inout load: Real64, cp: Real64) -> None:
    if self.CWPlantLoc.side == UnsafePointer[PlantSide]():
        self.EvapMassFlowRate = 0.0
        return
    
    self.PossibleSubcooling = True
    var evap_delta_temp: Real64 = 0.0
    
    if self.FlowMode.value == FlowMode.Constant().value or self.FlowMode.value == FlowMode.NotModulated().value:
        self.EvapMassFlowRate = self.EvapMassFlowRateMax
        if self.EvapMassFlowRate != 0.0:
            evap_delta_temp = abs(load) / self.EvapMassFlowRate / cp
        else:
            evap_delta_temp = 0.0
        self.EvapOutletTemp = 0.0 - evap_delta_temp
    elif self.FlowMode.value == FlowMode.LeavingSetpointModulated().value:
        evap_delta_temp = 0.0 - 0.0
        if evap_delta_temp != 0.0:
            self.EvapMassFlowRate = max(0.0, abs(load) / cp / evap_delta_temp)
            self.EvapMassFlowRate = min(self.EvapMassFlowRateMax, self.EvapMassFlowRate)
            self.EvapOutletTemp = 0.0
        else:
            self.EvapMassFlowRate = 0.0
            self.EvapOutletTemp = 0.0
            self.QEvaporator = 0.0
            self.ChillerPartLoadRatio = 0.0
    
    var rho: Real64 = 1000.0
    self.EvapVolFlowRate = self.EvapMassFlowRate / rho

fn calculate(inout self: ASHRAE205ChillerSpecs, state: UnsafePointer[Byte], 
             inout my_load: Real64, run_flag: Bool) -> None:
    self.ChillerPartLoadRatio = 0.0
    self.ChillerCyclingRatio = 1.0
    self.ChillerFalseLoadRate = 0.0
    self.EvapMassFlowRate = 0.0
    self.CondMassFlowRate = 0.0
    self.Power = 0.0
    self.QCondenser = 0.0
    self.QEvaporator = 0.0
    self.QOilCooler = 0.0
    self.QAuxiliary = 0.0
    
    var cond_inlet_temp: Real64 = 0.0
    self.EvapOutletTemp = 0.0
    
    var standby_power: Real64 = 0.0
    
    if my_load >= 0.0 or not run_flag:
        self.Power = standby_power
        self.AmbientZoneGain = standby_power
        return
    
    if self.CondenserType.value == CondenserType.WaterCooled().value:
        self.CondMassFlowRate = self.CondMassFlowRateMax
        if self.CondMassFlowRate < 0.0001:
            my_load = 0.0
            self.Power = standby_power
            self.AmbientZoneGain = standby_power
            self.EvapMassFlowRate = 0.0
            return
    
    var evap_outlet_temp_setpoint: Real64 = 0.0
    
    self.EvapMassFlowRate = 0.0
    if self.EvapMassFlowRate == 0.0:
        my_load = 0.0
        return
    
    var cp_evap: Real64 = 4186.0
    find_evaporator_mass_flow_rate(self, state, my_load, cp_evap)
    
    var maximum_chiller_cap: Real64 = 0.0
    var minimum_chiller_cap: Real64 = 0.0
    
    self.ChillerPartLoadRatio = max(0.0, abs(my_load) / maximum_chiller_cap) if maximum_chiller_cap > 0.0 else 0.0
    self.MinPartLoadRat = minimum_chiller_cap / maximum_chiller_cap if maximum_chiller_cap > 0.0 else 0.0
    var part_load_seq_num: Real64 = 0.0
    
    if self.ChillerPartLoadRatio < self.MinPartLoadRat:
        self.ChillerCyclingRatio = self.ChillerPartLoadRatio / self.MinPartLoadRat
        part_load_seq_num = self.MinSequenceNumber
    elif self.ChillerPartLoadRatio < 1.0:
        part_load_seq_num = (self.MinSequenceNumber + self.MaxSequenceNumber) / 2.0
    else:
        self.QEvaporator = maximum_chiller_cap
        part_load_seq_num = self.MaxSequenceNumber
        find_evaporator_mass_flow_rate(self, state, self.QEvaporator, cp_evap)
    
    self.QEvaporator = 0.0 * self.ChillerCyclingRatio
    var evap_delta_temp: Real64 = self.QEvaporator / self.EvapMassFlowRate / cp_evap
    self.EvapOutletTemp = 0.0 - evap_delta_temp
    
    var cd: Real64 = 0.0
    var cycling_factor: Real64 = (1.0 - cd) + (cd * self.ChillerCyclingRatio)
    var runtime_factor: Real64 = self.ChillerCyclingRatio / cycling_factor
    self.Power = 0.0 * runtime_factor + ((1.0 - self.ChillerCyclingRatio) * standby_power)
    self.QCondenser = 0.0 * self.ChillerCyclingRatio
    self.QOilCooler = 0.0
    self.QAuxiliary = 0.0
    
    var q_externally_cooled: Real64 = 0.0
    if self.OilCoolerInletNode != 0:
        q_externally_cooled += self.QOilCooler
    if self.AuxiliaryHeatInletNode != 0:
        q_externally_cooled += self.QAuxiliary
    
    self.AmbientZoneGain = self.QEvaporator + self.Power - (self.QCondenser + q_externally_cooled)
    
    var cp_cond: Real64 = 4186.0
    self.CondOutletTemp = self.QCondenser / self.CondMassFlowRate / cp_cond + cond_inlet_temp

fn update(inout self: ASHRAE205ChillerSpecs, state: UnsafePointer[Byte], 
          my_load: Real64, run_flag: Bool) -> None:
    if my_load >= 0.0 or not run_flag:
        self.ChillerPartLoadRatio = 0.0
        self.ChillerCyclingRatio = 0.0
        self.ChillerFalseLoadRate = 0.0
        self.ChillerFalseLoad = 0.0
        self.QEvaporator = 0.0
        self.QCondenser = 0.0
        self.Energy = 0.0
        self.EvapEnergy = 0.0
        self.CondEnergy = 0.0
        self.QOilCooler = 0.0
        self.QAuxiliary = 0.0
        self.OilCoolerEnergy = 0.0
        self.AuxiliaryEnergy = 0.0
        self.ActualCOP = 0.0
    else:
        self.EvapEnergy = self.QEvaporator * 1.0
        self.CondEnergy = self.QCondenser * 1.0
        self.OilCoolerEnergy = self.QOilCooler * 1.0
        self.AuxiliaryEnergy = self.QAuxiliary * 1.0
        if self.Power != 0.0:
            self.ActualCOP = self.QEvaporator / self.Power
        else:
            self.ActualCOP = 0.0
    
    self.AmbientZoneGainEnergy = self.AmbientZoneGain * 1.0
    self.Energy = self.Power * 1.0

fn simulate(inout self: ASHRAE205ChillerSpecs, state: UnsafePointer[Byte], 
            called_from_location: PlantLocation, first_hvac_iteration: Bool, 
            inout cur_load: Real64, run_flag: Bool) -> None:
    if called_from_location.loop_num == self.CWPlantLoc.loop_num:
        initialize(self, state, run_flag, cur_load)
        calculate(self, state, cur_load, run_flag)
        update(self, state, cur_load, run_flag)

fn get_design_capacities(inout self: ASHRAE205ChillerSpecs, state: UnsafePointer[Byte], 
                        called_from_location: PlantLocation) -> Tuple[Real64, Real64, Real64]:
    if called_from_location.loop_num == self.CWPlantLoc.loop_num:
        var min_load: Real64 = 0.0
        var max_load: Real64 = self.RefCap
        var opt_load: Real64 = max_load
        return (min_load, max_load, opt_load)
    else:
        return (0.0, 0.0, 0.0)
