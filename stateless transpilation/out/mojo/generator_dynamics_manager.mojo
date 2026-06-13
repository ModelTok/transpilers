from math import fabs, max, min
import sys


# EXTERNAL DEPS (to wire in glue):
# - OperatingMode (enum: Off=0, Standby=1, WarmUp=2, Normal=3, CoolDown=4, Invalid=-1)
# - EnergyPlusData (state container with dataCHPElectGen, dataGenerator, dataHVACGlobal,
#   dataLoopNodes, dataGlobal)
# - Constant.rSecsInHour, Constant.rHoursInDay (f64 constants)
# - MicroCHPData struct with Name, A42Model, availSched, PlantInletNodeID, PlantOutletNodeID,
#   DynamicsControlID, A42Model fields
# - GeneratorDynamicsData struct with Name, PelMin, PelMax, UpTranLimit, DownTranLimit,
#   UpTranLimitFuel, DownTranLimitFuel, WarmUpByTimeDelay, WarmUpByEngineTemp,
#   MandatoryFullCoolDown, WarmRestartOkay, WarmUpDelay, CoolDownDelay, PcoolDown, Pstandby,
#   MCeng, MCcw, kf, TnomEngOp, kp, availSched, StartUpTimeDelay, ElectEffNom, ThermEffNom,
#   QdotHXMax, QdotHXMin, QdotHXOpt, LastOpMode, FractionalDayofLastStartUp,
#   FractionalDayofLastShutDown, PelLastTimeStep, FuelMdotLastTimestep, CurrentOpMode
# - NodeData struct with Temp, MassFlowRate
# - CWPlantLocData struct with loopNum
# - ScheduleCallable with getCurrentVal() -> f64
# - WaterFlowCurve with value(state, f64, f64) -> f64
# - PlantUtilities.SetComponentFlowRate(state, f64, i32, i32, loc) -> None


struct OperatingMode:
    var value: i32

    fn __init__(inout self, val: i32):
        self.value = val

    fn __eq__(self, other: OperatingMode) -> Bool:
        return self.value == other.value

    fn __ne__(self, other: OperatingMode) -> Bool:
        return self.value != other.value

    @staticmethod
    fn Off() -> OperatingMode:
        return OperatingMode(0)

    @staticmethod
    fn Standby() -> OperatingMode:
        return OperatingMode(1)

    @staticmethod
    fn WarmUp() -> OperatingMode:
        return OperatingMode(2)

    @staticmethod
    fn Normal() -> OperatingMode:
        return OperatingMode(3)

    @staticmethod
    fn CoolDown() -> OperatingMode:
        return OperatingMode(4)

    @staticmethod
    fn Invalid() -> OperatingMode:
        return OperatingMode(-1)


struct A42ModelData:
    var MinElecPower: f64
    var MaxElecPower: f64
    var DeltaPelMax: f64
    var DeltaFuelMdotMax: f64
    var WarmUpByTimeDelay: Bool
    var WarmUpByEngineTemp: Bool
    var MandatoryFullCoolDown: Bool
    var WarmRestartOkay: Bool
    var WarmUpDelay: f64
    var CoolDownDelay: f64
    var PcoolDown: f64
    var Pstandby: f64
    var MCeng: f64
    var MCcw: f64
    var kf: f64
    var TnomEngOp: f64
    var kp: f64
    var ElecEff: f64
    var ThermEff: f64
    var InternalFlowControl: Bool
    var MinWaterMdot: f64
    var Teng: f64
    var TengLast: f64
    var OffModeTime: f64
    var StandyByModeTime: f64
    var WarmUpModeTime: f64
    var NormalModeTime: f64
    var CoolDownModeTime: f64

    fn __init__(inout self):
        self.MinElecPower = 0.0
        self.MaxElecPower = 0.0
        self.DeltaPelMax = 0.0
        self.DeltaFuelMdotMax = 0.0
        self.WarmUpByTimeDelay = False
        self.WarmUpByEngineTemp = False
        self.MandatoryFullCoolDown = False
        self.WarmRestartOkay = False
        self.WarmUpDelay = 0.0
        self.CoolDownDelay = 0.0
        self.PcoolDown = 0.0
        self.Pstandby = 0.0
        self.MCeng = 0.0
        self.MCcw = 0.0
        self.kf = 0.0
        self.TnomEngOp = 0.0
        self.kp = 0.0
        self.ElecEff = 0.0
        self.ThermEff = 0.0
        self.InternalFlowControl = False
        self.MinWaterMdot = 0.0
        self.Teng = 0.0
        self.TengLast = 0.0
        self.OffModeTime = 0.0
        self.StandyByModeTime = 0.0
        self.WarmUpModeTime = 0.0
        self.NormalModeTime = 0.0
        self.CoolDownModeTime = 0.0


struct MicroCHPData:
    var Name: String
    var A42Model: A42ModelData
    var availSched: Optional[ScheduleCallableStub]
    var PlantInletNodeID: i32
    var PlantOutletNodeID: i32
    var DynamicsControlID: i32
    var CWPlantLoc: CWPlantLocData

    fn __init__(inout self):
        self.Name = ""
        self.A42Model = A42ModelData()
        self.availSched = None
        self.PlantInletNodeID = 0
        self.PlantOutletNodeID = 0
        self.DynamicsControlID = 0
        self.CWPlantLoc = CWPlantLocData()


struct ScheduleCallableStub:
    fn getCurrentVal(self) -> f64:
        return 1.0


struct GeneratorDynamicsData:
    var Name: String
    var PelMin: f64
    var PelMax: f64
    var UpTranLimit: f64
    var DownTranLimit: f64
    var UpTranLimitFuel: f64
    var DownTranLimitFuel: f64
    var WarmUpByTimeDelay: Bool
    var WarmUpByEngineTemp: Bool
    var MandatoryFullCoolDown: Bool
    var WarmRestartOkay: Bool
    var WarmUpDelay: f64
    var CoolDownDelay: f64
    var PcoolDown: f64
    var Pstandby: f64
    var MCeng: f64
    var MCcw: f64
    var kf: f64
    var TnomEngOp: f64
    var kp: f64
    var availSched: Optional[ScheduleCallableStub]
    var StartUpTimeDelay: f64
    var ElectEffNom: f64
    var ThermEffNom: f64
    var QdotHXMax: f64
    var QdotHXMin: f64
    var QdotHXOpt: f64
    var LastOpMode: OperatingMode
    var FractionalDayofLastStartUp: f64
    var FractionalDayofLastShutDown: f64
    var PelLastTimeStep: f64
    var FuelMdotLastTimestep: f64
    var CurrentOpMode: OperatingMode

    fn __init__(inout self):
        self.Name = ""
        self.PelMin = 0.0
        self.PelMax = 0.0
        self.UpTranLimit = 0.0
        self.DownTranLimit = 0.0
        self.UpTranLimitFuel = 0.0
        self.DownTranLimitFuel = 0.0
        self.WarmUpByTimeDelay = False
        self.WarmUpByEngineTemp = False
        self.MandatoryFullCoolDown = False
        self.WarmRestartOkay = False
        self.WarmUpDelay = 0.0
        self.CoolDownDelay = 0.0
        self.PcoolDown = 0.0
        self.Pstandby = 0.0
        self.MCeng = 0.0
        self.MCcw = 0.0
        self.kf = 0.0
        self.TnomEngOp = 0.0
        self.kp = 0.0
        self.availSched = None
        self.StartUpTimeDelay = 0.0
        self.ElectEffNom = 0.0
        self.ThermEffNom = 0.0
        self.QdotHXMax = 0.0
        self.QdotHXMin = 0.0
        self.QdotHXOpt = 0.0
        self.LastOpMode = OperatingMode.Off()
        self.FractionalDayofLastStartUp = 0.0
        self.FractionalDayofLastShutDown = 0.0
        self.PelLastTimeStep = 0.0
        self.FuelMdotLastTimestep = 0.0
        self.CurrentOpMode = OperatingMode.Off()


struct NodeData:
    var Temp: f64
    var MassFlowRate: f64

    fn __init__(inout self):
        self.Temp = 0.0
        self.MassFlowRate = 0.0


struct CWPlantLocData:
    var loopNum: i32

    fn __init__(inout self):
        self.loopNum = 0


struct DataCHPElectGenStub:
    var NumMicroCHPs: i32

    fn __init__(inout self):
        self.NumMicroCHPs = 0


struct DataGeneratorStub:
    var InternalFlowControl: Bool
    var InletCWnode: i32
    var TcwIn: f64
    var TrialMdotcw: f64
    var LimitMinMdotcw: f64

    fn __init__(inout self):
        self.InternalFlowControl = False
        self.InletCWnode = 0
        self.TcwIn = 0.0
        self.TrialMdotcw = 0.0
        self.LimitMinMdotcw = 0.0


struct DataHVACGlobalsStub:
    var SysTimeElapsed: f64
    var TimeStepSys: f64
    var TimeStepSysSec: f64

    fn __init__(inout self):
        self.SysTimeElapsed = 0.0
        self.TimeStepSys = 0.0
        self.TimeStepSysSec = 0.0


struct DataLoopNodesStub:
    pass


struct DataGlobalStub:
    var DayOfSim: i32
    var CurrentTime: f64

    fn __init__(inout self):
        self.DayOfSim = 1
        self.CurrentTime = 0.0


struct EnergyPlusData:
    var dataCHPElectGen: DataCHPElectGenStub
    var dataGenerator: DataGeneratorStub
    var dataHVACGlobal: DataHVACGlobalsStub
    var dataLoopNodes: DataLoopNodesStub
    var dataGlobal: DataGlobalStub

    fn __init__(inout self):
        self.dataCHPElectGen = DataCHPElectGenStub()
        self.dataGenerator = DataGeneratorStub()
        self.dataHVACGlobal = DataHVACGlobalsStub()
        self.dataLoopNodes = DataLoopNodesStub()
        self.dataGlobal = DataGlobalStub()


struct Constant:
    @staticmethod
    fn rSecsInHour() -> f64:
        return 3600.0

    @staticmethod
    fn rHoursInDay() -> f64:
        return 24.0


struct PlantUtilities:
    @staticmethod
    fn SetComponentFlowRate(inout state: EnergyPlusData, mdot: f64, inlet_node: i32,
                            outlet_node: i32, loc: CWPlantLocData) -> None:
        pass


@export
fn SetupGeneratorControlStateManager(inout state: EnergyPlusData, gen_num: i32) -> None:
    var num_gens_w_dynamics: i32 = state.dataCHPElectGen.NumMicroCHPs

    var this_gen: GeneratorDynamicsData = GeneratorDynamicsData()
    var this_micro_chp: MicroCHPData = MicroCHPData()

    this_gen.Name = this_micro_chp.Name
    this_gen.PelMin = this_micro_chp.A42Model.MinElecPower
    this_gen.PelMax = this_micro_chp.A42Model.MaxElecPower
    this_gen.UpTranLimit = this_micro_chp.A42Model.DeltaPelMax
    this_gen.DownTranLimit = this_micro_chp.A42Model.DeltaPelMax
    this_gen.UpTranLimitFuel = this_micro_chp.A42Model.DeltaFuelMdotMax
    this_gen.DownTranLimitFuel = this_micro_chp.A42Model.DeltaFuelMdotMax
    this_gen.WarmUpByTimeDelay = this_micro_chp.A42Model.WarmUpByTimeDelay
    this_gen.WarmUpByEngineTemp = this_micro_chp.A42Model.WarmUpByEngineTemp
    this_gen.MandatoryFullCoolDown = this_micro_chp.A42Model.MandatoryFullCoolDown
    this_gen.WarmRestartOkay = this_micro_chp.A42Model.WarmRestartOkay
    this_gen.WarmUpDelay = this_micro_chp.A42Model.WarmUpDelay
    this_gen.CoolDownDelay = this_micro_chp.A42Model.CoolDownDelay / Constant.rSecsInHour()
    this_gen.PcoolDown = this_micro_chp.A42Model.PcoolDown
    this_gen.Pstandby = this_micro_chp.A42Model.Pstandby
    this_gen.MCeng = this_micro_chp.A42Model.MCeng
    this_gen.MCcw = this_micro_chp.A42Model.MCcw
    this_gen.kf = this_micro_chp.A42Model.kf
    this_gen.TnomEngOp = this_micro_chp.A42Model.TnomEngOp
    this_gen.kp = this_micro_chp.A42Model.kp
    this_gen.availSched = this_micro_chp.availSched
    this_gen.StartUpTimeDelay = this_micro_chp.A42Model.WarmUpDelay / Constant.rSecsInHour()

    this_gen.ElectEffNom = this_micro_chp.A42Model.ElecEff
    this_gen.ThermEffNom = this_micro_chp.A42Model.ThermEff
    this_gen.QdotHXMax = (this_micro_chp.A42Model.ThermEff * this_micro_chp.A42Model.MaxElecPower /
                          this_micro_chp.A42Model.ElecEff)
    this_gen.QdotHXMin = (this_micro_chp.A42Model.ThermEff * this_micro_chp.A42Model.MinElecPower /
                          this_micro_chp.A42Model.ElecEff)
    this_gen.QdotHXOpt = this_gen.QdotHXMax
    this_micro_chp.DynamicsControlID = gen_num


fn _handle_off_standby_mode(inout state: EnergyPlusData, inout this_gen: GeneratorDynamicsData,
                             inout new_op_mode: OperatingMode, inout plr_for_subtimestep_start_up: f64,
                             sched_val: f64, run_flag: Bool, generator_num: i32, time_step_sys: f64,
                             sys_time_elapsed: f64) -> None:
    if sched_val == 0.0:
        new_op_mode = OperatingMode.Off()
    elif ((sched_val != 0.0) and (not run_flag)) or (state.dataGenerator.TrialMdotcw < state.dataGenerator.LimitMinMdotcw):
        new_op_mode = OperatingMode.Standby()
    elif (sched_val != 0.0) and run_flag:
        if this_gen.WarmUpByTimeDelay:
            if this_gen.StartUpTimeDelay == 0.0:
                new_op_mode = OperatingMode.Normal()
            elif this_gen.StartUpTimeDelay >= time_step_sys:
                new_op_mode = OperatingMode.WarmUp()
                this_gen.FractionalDayofLastStartUp = (
                    f64(state.dataGlobal.DayOfSim) +
                    (f64(i32(state.dataGlobal.CurrentTime)) +
                     (sys_time_elapsed + (state.dataGlobal.CurrentTime - f64(i32(state.dataGlobal.CurrentTime)) - time_step_sys))) /
                    Constant.rHoursInDay())
            else:
                new_op_mode = OperatingMode.Normal()
                plr_for_subtimestep_start_up = (time_step_sys - this_gen.StartUpTimeDelay) / time_step_sys

        if this_gen.WarmUpByEngineTemp:
            var this_micro_chp: MicroCHPData = MicroCHPData()
            if this_micro_chp.A42Model.Teng >= this_gen.TnomEngOp:
                new_op_mode = OperatingMode.Normal()
                if (this_micro_chp.A42Model.Teng - this_micro_chp.A42Model.TengLast) > 0.0:
                    plr_for_subtimestep_start_up = (
                        (this_micro_chp.A42Model.Teng - this_gen.TnomEngOp) /
                        (this_micro_chp.A42Model.Teng - this_micro_chp.A42Model.TengLast))
                else:
                    plr_for_subtimestep_start_up = 1.0
            else:
                new_op_mode = OperatingMode.WarmUp()


@export
fn ManageGeneratorControlState(inout state: EnergyPlusData, generator_num: i32, run_flag_elect_center: Bool,
                               run_flag_plant: Bool, elec_load_request: f64, thermal_load_request: f64) -> (f64, OperatingMode, f64, f64):
    var sys_time_elapsed: f64 = state.dataHVACGlobal.SysTimeElapsed
    var time_step_sys: f64 = state.dataHVACGlobal.TimeStepSys
    var time_step_sys_sec: f64 = state.dataHVACGlobal.TimeStepSysSec

    var plr_for_subtimestep_start_up: f64 = 1.0
    var plr_for_subtimestep_shut_down: f64 = 0.0
    var plr_start_up: Bool = False
    var plr_shut_down: Bool = False
    state.dataGenerator.InternalFlowControl = False

    var dyna_cntrl_num: i32 = 0
    state.dataGenerator.InletCWnode = 0
    state.dataGenerator.TcwIn = 0.0

    if state.dataCHPElectGen.NumMicroCHPs > 0:
        var this_micro_chp: MicroCHPData = MicroCHPData()
        dyna_cntrl_num = this_micro_chp.DynamicsControlID
        state.dataGenerator.InletCWnode = this_micro_chp.PlantInletNodeID
        if this_micro_chp.A42Model.InternalFlowControl:
            state.dataGenerator.InternalFlowControl = True
        state.dataGenerator.LimitMinMdotcw = this_micro_chp.A42Model.MinWaterMdot

    var this_gen: GeneratorDynamicsData = GeneratorDynamicsData()
    var pel_input: f64 = elec_load_request
    var elect_load_for_thermal_request: f64 = 0.0

    if (thermal_load_request > 0.0) and run_flag_plant:
        elect_load_for_thermal_request = this_gen.ThermEffNom * thermal_load_request / this_gen.ElectEffNom
        pel_input = max(pel_input, elect_load_for_thermal_request)

    var run_flag: Bool = run_flag_elect_center or run_flag_plant

    var sched_val: f64 = 1.0
    var pel: f64 = pel_input

    if state.dataGenerator.InternalFlowControl and (sched_val > 0.0):
        state.dataGenerator.TrialMdotcw = FuncDetermineCWMdotForInternalFlowControl(
            inout state, generator_num, pel, state.dataGenerator.TcwIn)
    else:
        state.dataGenerator.TrialMdotcw = 0.0

    var new_op_mode: OperatingMode = OperatingMode.Invalid()

    if (this_gen.LastOpMode.value == OperatingMode.Off().value) or (this_gen.LastOpMode.value == OperatingMode.Standby().value):
        _handle_off_standby_mode(inout state, inout this_gen, inout new_op_mode, inout plr_for_subtimestep_start_up,
                                sched_val, run_flag, generator_num, time_step_sys, sys_time_elapsed)

    elif this_gen.LastOpMode.value == OperatingMode.WarmUp().value:
        if sched_val == 0.0:
            if this_gen.CoolDownDelay == 0.0:
                new_op_mode = OperatingMode.Off()
            else:
                if this_gen.CoolDownDelay > time_step_sys:
                    new_op_mode = OperatingMode.CoolDown()
                    this_gen.FractionalDayofLastShutDown = (
                        f64(state.dataGlobal.DayOfSim) +
                        (f64(i32(state.dataGlobal.CurrentTime)) +
                         (sys_time_elapsed + (state.dataGlobal.CurrentTime - f64(i32(state.dataGlobal.CurrentTime))))) /
                        Constant.rHoursInDay())
                else:
                    new_op_mode = OperatingMode.Off()

        elif ((sched_val != 0.0) and (not run_flag)) or (state.dataGenerator.TrialMdotcw < state.dataGenerator.LimitMinMdotcw):
            if this_gen.CoolDownDelay == 0.0:
                new_op_mode = OperatingMode.Standby()
            else:
                if this_gen.CoolDownDelay > time_step_sys:
                    new_op_mode = OperatingMode.CoolDown()
                    this_gen.FractionalDayofLastShutDown = (
                        f64(state.dataGlobal.DayOfSim) +
                        (f64(i32(state.dataGlobal.CurrentTime)) +
                         (sys_time_elapsed + (state.dataGlobal.CurrentTime - f64(i32(state.dataGlobal.CurrentTime))))) /
                        Constant.rHoursInDay())
                else:
                    new_op_mode = OperatingMode.Standby()

        elif (sched_val != 0.0) and run_flag:
            if this_gen.WarmUpByTimeDelay:
                var current_fractional_day: f64 = (
                    f64(state.dataGlobal.DayOfSim) +
                    (f64(i32(state.dataGlobal.CurrentTime)) +
                     (sys_time_elapsed + (state.dataGlobal.CurrentTime - f64(i32(state.dataGlobal.CurrentTime))))) /
                    Constant.rHoursInDay())
                var ending_fractional_day: f64 = this_gen.FractionalDayofLastStartUp + this_gen.StartUpTimeDelay / Constant.rHoursInDay()
                if (fabs(current_fractional_day - ending_fractional_day) < 0.000001) or (current_fractional_day > ending_fractional_day):
                    new_op_mode = OperatingMode.Normal()
                    plr_start_up = True
                    var last_system_time_step_fractional_day: f64 = current_fractional_day - (time_step_sys / Constant.rHoursInDay())
                    plr_for_subtimestep_start_up = (
                        (current_fractional_day - ending_fractional_day) /
                        (current_fractional_day - last_system_time_step_fractional_day))
                else:
                    new_op_mode = OperatingMode.WarmUp()

    elif this_gen.LastOpMode.value == OperatingMode.Normal().value:
        if ((sched_val == 0.0) or (not run_flag)) or (state.dataGenerator.TrialMdotcw < state.dataGenerator.LimitMinMdotcw):
            if this_gen.CoolDownDelay == 0.0:
                if sched_val != 0.0:
                    new_op_mode = OperatingMode.Standby()
                else:
                    new_op_mode = OperatingMode.Off()
            elif this_gen.CoolDownDelay >= time_step_sys:
                new_op_mode = OperatingMode.CoolDown()
                this_gen.FractionalDayofLastShutDown = (
                    f64(state.dataGlobal.DayOfSim) +
                    (f64(i32(state.dataGlobal.CurrentTime)) +
                     (sys_time_elapsed + (state.dataGlobal.CurrentTime - f64(i32(state.dataGlobal.CurrentTime))))) /
                    Constant.rHoursInDay())
            else:
                if sched_val != 0.0:
                    new_op_mode = OperatingMode.Standby()
                else:
                    new_op_mode = OperatingMode.Off()
                plr_shut_down = True
                plr_for_subtimestep_shut_down = this_gen.CoolDownDelay / time_step_sys
                this_gen.FractionalDayofLastShutDown = (
                    f64(state.dataGlobal.DayOfSim) +
                    (f64(i32(state.dataGlobal.CurrentTime)) +
                     (sys_time_elapsed + (state.dataGlobal.CurrentTime - f64(i32(state.dataGlobal.CurrentTime))))) /
                    Constant.rHoursInDay())
        else:
            new_op_mode = OperatingMode.Normal()

    elif this_gen.LastOpMode.value == OperatingMode.CoolDown().value:
        if sched_val == 0.0:
            if this_gen.CoolDownDelay > 0.0:
                var current_fractional_day: f64 = (
                    f64(state.dataGlobal.DayOfSim) +
                    (f64(i32(state.dataGlobal.CurrentTime)) +
                     (sys_time_elapsed + (state.dataGlobal.CurrentTime - f64(i32(state.dataGlobal.CurrentTime))))) /
                    Constant.rHoursInDay())
                var ending_fractional_day: f64 = (
                    this_gen.FractionalDayofLastShutDown + this_gen.CoolDownDelay / Constant.rHoursInDay() -
                    (time_step_sys / Constant.rHoursInDay()))
                if (fabs(current_fractional_day - ending_fractional_day) < 0.000001) or (current_fractional_day > ending_fractional_day):
                    new_op_mode = OperatingMode.Off()
                    plr_shut_down = True
                    var last_system_time_step_fractional_day: f64 = current_fractional_day - (time_step_sys / Constant.rHoursInDay())
                    plr_for_subtimestep_shut_down = (ending_fractional_day - last_system_time_step_fractional_day) * Constant.rHoursInDay() / time_step_sys
                else:
                    new_op_mode = OperatingMode.CoolDown()
            else:
                new_op_mode = OperatingMode.Off()

        elif ((sched_val != 0.0) and (not run_flag)) or (state.dataGenerator.TrialMdotcw < state.dataGenerator.LimitMinMdotcw):
            if this_gen.CoolDownDelay > 0.0:
                var current_fractional_day: f64 = (
                    f64(state.dataGlobal.DayOfSim) +
                    (f64(i32(state.dataGlobal.CurrentTime)) +
                     (sys_time_elapsed + (state.dataGlobal.CurrentTime - f64(i32(state.dataGlobal.CurrentTime))))) /
                    Constant.rHoursInDay())
                var ending_fractional_day: f64 = (
                    this_gen.FractionalDayofLastShutDown + this_gen.CoolDownDelay / Constant.rHoursInDay() -
                    (time_step_sys / Constant.rHoursInDay()))
                if (fabs(current_fractional_day - ending_fractional_day) < 0.000001) or (current_fractional_day > ending_fractional_day):
                    new_op_mode = OperatingMode.Standby()
                    plr_shut_down = True
                    var last_system_time_step_fractional_day: f64 = current_fractional_day - (time_step_sys / Constant.rHoursInDay())
                    plr_for_subtimestep_shut_down = (ending_fractional_day - last_system_time_step_fractional_day) * Constant.rHoursInDay() / time_step_sys
                else:
                    new_op_mode = OperatingMode.CoolDown()
            else:
                new_op_mode = OperatingMode.Standby()

        elif (sched_val != 0.0) and run_flag:
            if this_gen.MandatoryFullCoolDown:
                if this_gen.CoolDownDelay > 0.0:
                    var current_fractional_day: f64 = (
                        f64(state.dataGlobal.DayOfSim) +
                        (f64(i32(state.dataGlobal.CurrentTime)) +
                         (sys_time_elapsed + (state.dataGlobal.CurrentTime - f64(i32(state.dataGlobal.CurrentTime))))) /
                        Constant.rHoursInDay())
                    var ending_fractional_day: f64 = (
                        this_gen.FractionalDayofLastShutDown + this_gen.CoolDownDelay / Constant.rHoursInDay() -
                        (time_step_sys / Constant.rHoursInDay()))
                    if (fabs(current_fractional_day - ending_fractional_day) < 0.000001) or (current_fractional_day < ending_fractional_day):
                        new_op_mode = OperatingMode.CoolDown()
                    else:
                        plr_shut_down = True
                        var last_system_time_step_fractional_day: f64 = current_fractional_day - (time_step_sys / Constant.rHoursInDay())
                        plr_for_subtimestep_shut_down = (ending_fractional_day - last_system_time_step_fractional_day) * Constant.rHoursInDay() / time_step_sys
                        if this_gen.StartUpTimeDelay == 0.0:
                            new_op_mode = OperatingMode.Normal()
                            plr_start_up = True
                            plr_for_subtimestep_start_up = (
                                (current_fractional_day - ending_fractional_day) /
                                (current_fractional_day - last_system_time_step_fractional_day))
                        elif this_gen.StartUpTimeDelay > 0.0:
                            if (current_fractional_day - ending_fractional_day) > this_gen.StartUpTimeDelay:
                                new_op_mode = OperatingMode.Normal()
                                plr_start_up = True
                                plr_for_subtimestep_start_up = (
                                    (current_fractional_day - ending_fractional_day) /
                                    (current_fractional_day - last_system_time_step_fractional_day))
                            else:
                                new_op_mode = OperatingMode.WarmUp()
                                this_gen.FractionalDayofLastStartUp = (
                                    f64(state.dataGlobal.DayOfSim) +
                                    (f64(i32(state.dataGlobal.CurrentTime)) +
                                     (sys_time_elapsed + (state.dataGlobal.CurrentTime - f64(i32(state.dataGlobal.CurrentTime)) - time_step_sys))) /
                                    Constant.rHoursInDay())
                else:
                    new_op_mode = OperatingMode.Standby()
            else:
                if this_gen.WarmUpByTimeDelay:
                    if this_gen.StartUpTimeDelay == 0.0:
                        new_op_mode = OperatingMode.Normal()
                    elif this_gen.StartUpTimeDelay > 0.0:
                        var current_fractional_day: f64 = (
                            f64(state.dataGlobal.DayOfSim) +
                            (f64(i32(state.dataGlobal.CurrentTime)) +
                             (sys_time_elapsed + (state.dataGlobal.CurrentTime - f64(i32(state.dataGlobal.CurrentTime))))) /
                            Constant.rHoursInDay())
                        var ending_fractional_day: f64 = this_gen.FractionalDayofLastShutDown + this_gen.CoolDownDelay / Constant.rHoursInDay()
                        if (fabs(current_fractional_day - ending_fractional_day) < 0.000001) or (current_fractional_day > ending_fractional_day):
                            new_op_mode = OperatingMode.Normal()
                            plr_start_up = True
                            var last_system_time_step_fractional_day: f64 = current_fractional_day - (time_step_sys / Constant.rHoursInDay())
                            plr_for_subtimestep_start_up = (
                                (current_fractional_day - ending_fractional_day) /
                                (current_fractional_day - last_system_time_step_fractional_day))
                        else:
                            new_op_mode = OperatingMode.WarmUp()
                            this_gen.FractionalDayofLastStartUp = (
                                f64(state.dataGlobal.DayOfSim) +
                                (f64(i32(state.dataGlobal.CurrentTime)) +
                                 (sys_time_elapsed + (state.dataGlobal.CurrentTime - f64(i32(state.dataGlobal.CurrentTime)) - time_step_sys))) /
                                Constant.rHoursInDay())

    if plr_for_subtimestep_start_up < 0.0:
        plr_for_subtimestep_start_up = 0.0
    if plr_for_subtimestep_start_up > 1.0:
        plr_for_subtimestep_start_up = 1.0

    if plr_for_subtimestep_shut_down < 0.0:
        plr_for_subtimestep_shut_down = 0.0
    if plr_for_subtimestep_shut_down > 1.0:
        plr_for_subtimestep_shut_down = 1.0

    if new_op_mode.value == OperatingMode.WarmUp().value:
        pel = pel_input * plr_for_subtimestep_start_up

    if new_op_mode.value == OperatingMode.Normal().value:
        pel *= plr_for_subtimestep_start_up
        if pel > this_gen.PelLastTimeStep:
            var max_pel: f64 = this_gen.PelLastTimeStep + this_gen.UpTranLimit * time_step_sys_sec
            if max_pel < pel:
                pel = max_pel
        elif pel < this_gen.PelLastTimeStep:
            var min_pel: f64 = this_gen.PelLastTimeStep - this_gen.DownTranLimit * time_step_sys_sec
            if pel < min_pel:
                pel = min_pel

    if new_op_mode.value == OperatingMode.CoolDown().value:
        pel = 0.0

    if new_op_mode.value == OperatingMode.Off().value:
        pel = 0.0

    if new_op_mode.value == OperatingMode.Standby().value:
        pel = 0.0

    if pel < this_gen.PelMin:
        pel = this_gen.PelMin
    if pel > this_gen.PelMax:
        pel = this_gen.PelMax

    var this_micro_chp: MicroCHPData = MicroCHPData()
    this_micro_chp.A42Model.OffModeTime = 0.0
    this_micro_chp.A42Model.StandyByModeTime = 0.0
    this_micro_chp.A42Model.WarmUpModeTime = 0.0
    this_micro_chp.A42Model.NormalModeTime = 0.0
    this_micro_chp.A42Model.CoolDownModeTime = 0.0

    if new_op_mode.value == OperatingMode.Off().value:
        if plr_for_subtimestep_shut_down == 0.0:
            this_micro_chp.A42Model.OffModeTime = time_step_sys_sec
        elif (plr_for_subtimestep_shut_down > 0.0) and (plr_for_subtimestep_shut_down < 1.0):
            this_micro_chp.A42Model.CoolDownModeTime = time_step_sys_sec * plr_for_subtimestep_shut_down
            this_micro_chp.A42Model.OffModeTime = time_step_sys_sec * (1.0 - plr_for_subtimestep_shut_down)
        else:
            this_micro_chp.A42Model.OffModeTime = time_step_sys_sec

    elif new_op_mode.value == OperatingMode.Standby().value:
        if plr_for_subtimestep_shut_down == 0.0:
            this_micro_chp.A42Model.StandyByModeTime = time_step_sys_sec
        elif (plr_for_subtimestep_shut_down > 0.0) and (plr_for_subtimestep_shut_down < 1.0):
            this_micro_chp.A42Model.CoolDownModeTime = time_step_sys_sec * plr_for_subtimestep_shut_down
            this_micro_chp.A42Model.StandyByModeTime = time_step_sys_sec * (1.0 - plr_for_subtimestep_shut_down)
        else:
            this_micro_chp.A42Model.StandyByModeTime = time_step_sys_sec

    elif new_op_mode.value == OperatingMode.WarmUp().value:
        if plr_for_subtimestep_shut_down == 0.0:
            this_micro_chp.A42Model.WarmUpModeTime = time_step_sys_sec
        elif (plr_for_subtimestep_shut_down > 0.0) and (plr_for_subtimestep_shut_down < 1.0):
            this_micro_chp.A42Model.CoolDownModeTime = time_step_sys_sec * plr_for_subtimestep_shut_down
            this_micro_chp.A42Model.WarmUpModeTime = time_step_sys_sec * (1.0 - plr_for_subtimestep_shut_down)
        else:
            this_micro_chp.A42Model.WarmUpModeTime = time_step_sys_sec

    elif new_op_mode.value == OperatingMode.Normal().value:
        if plr_for_subtimestep_start_up == 0.0:
            this_micro_chp.A42Model.WarmUpModeTime = time_step_sys_sec
        elif (plr_for_subtimestep_start_up > 0.0) and (plr_for_subtimestep_start_up < 1.0):
            this_micro_chp.A42Model.WarmUpModeTime = time_step_sys_sec * (1.0 - plr_for_subtimestep_start_up)
            this_micro_chp.A42Model.NormalModeTime = time_step_sys_sec * plr_for_subtimestep_start_up
        else:
            if plr_for_subtimestep_shut_down == 0.0:
                this_micro_chp.A42Model.NormalModeTime = time_step_sys_sec
            elif (plr_for_subtimestep_shut_down > 0.0) and (plr_for_subtimestep_shut_down < 1.0):
                this_micro_chp.A42Model.CoolDownModeTime = time_step_sys_sec * plr_for_subtimestep_shut_down
                this_micro_chp.A42Model.NormalModeTime = time_step_sys_sec * (1.0 - plr_for_subtimestep_shut_down)
            else:
                this_micro_chp.A42Model.NormalModeTime = time_step_sys_sec

    elif new_op_mode.value == OperatingMode.CoolDown().value:
        this_micro_chp.A42Model.CoolDownModeTime = time_step_sys_sec

    this_gen.CurrentOpMode = new_op_mode

    return (pel, new_op_mode, plr_for_subtimestep_start_up, plr_for_subtimestep_shut_down)


@export
fn ManageGeneratorFuelFlow(inout state: EnergyPlusData, generator_num: i32, fuel_flow_request: f64) -> (f64, Bool, Bool):
    var time_step_sys_sec: f64 = state.dataHVACGlobal.TimeStepSysSec

    var constrained_increasing_mdot: Bool = False
    var constrained_decreasing_mdot: Bool = False
    var mdot_fuel: f64 = fuel_flow_request

    var dyna_cntrl_num: i32 = 0
    var this_gen: GeneratorDynamicsData = GeneratorDynamicsData()

    if fuel_flow_request > this_gen.FuelMdotLastTimestep:
        var max_mdot: f64 = this_gen.FuelMdotLastTimestep + this_gen.UpTranLimitFuel * time_step_sys_sec
        if max_mdot < fuel_flow_request:
            mdot_fuel = max_mdot
            constrained_increasing_mdot = True
    elif fuel_flow_request < this_gen.FuelMdotLastTimestep:
        var min_mdot: f64 = this_gen.FuelMdotLastTimestep - this_gen.DownTranLimitFuel * time_step_sys_sec
        if fuel_flow_request < min_mdot:
            mdot_fuel = min_mdot
            constrained_decreasing_mdot = True

    return (mdot_fuel, constrained_increasing_mdot, constrained_decreasing_mdot)


@export
fn FuncDetermineCWMdotForInternalFlowControl(inout state: EnergyPlusData, generator_num: i32, pnetss: f64, tcw_in: f64) -> f64:
    var this_micro_chp: MicroCHPData = MicroCHPData()
    var inlet_node: i32 = this_micro_chp.PlantInletNodeID
    var outlet_node: i32 = this_micro_chp.PlantOutletNodeID

    var mdot_cw: f64 = 0.0

    mdot_cw = max(0.0, mdot_cw)

    if this_micro_chp.CWPlantLoc.loopNum > 0:
        PlantUtilities.SetComponentFlowRate(inout state, mdot_cw, inlet_node, outlet_node, this_micro_chp.CWPlantLoc)

    return mdot_cw
