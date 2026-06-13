from dataclasses import dataclass
from enum import Enum
from typing import Protocol, Optional
from abc import ABC, abstractmethod


# EXTERNAL DEPS (to wire in glue):
# - OperatingMode (enum from DataGenerators)
# - EnergyPlusData (state container with dataCHPElectGen, dataGenerator, dataHVACGlobal, 
#   dataLoopNodes, dataCHPElectGen, dataGlobal, dataCHPElectGen)
# - Constant.rSecsInHour, Constant.rHoursInDay (float constants)
# - MicroCHP struct with fields: Name, A42Model, availSched, PlantInletNodeID, PlantOutletNodeID, 
#   DynamicsControlID, A42Model fields
# - GeneratorDynamics struct with fields: Name, PelMin, PelMax, UpTranLimit, DownTranLimit,
#   UpTranLimitFuel, DownTranLimitFuel, WarmUpByTimeDelay, WarmUpByEngineTemp, 
#   MandatoryFullCoolDown, WarmRestartOkay, WarmUpDelay, CoolDownDelay, PcoolDown, Pstandby,
#   MCeng, MCcw, kf, TnomEngOp, kp, availSched, StartUpTimeDelay, ElectEffNom, ThermEffNom,
#   QdotHXMax, QdotHXMin, QdotHXOpt, LastOpMode, FractionalDayofLastStartUp,
#   FractionalDayofLastShutDown, PelLastTimeStep, FuelMdotLastTimestep, CurrentOpMode
# - Node struct with fields: Temp, MassFlowRate
# - WaterFlowCurve with value(state, Pnetss, TcwIn) method
# - CWPlantLoc struct with loopNum field
# - ScheduleManager callable (.getCurrentVal())
# - PlantUtilities.SetComponentFlowRate(state, mdot, inlet, outlet, loc)


class OperatingMode(Enum):
    Off = 0
    Standby = 1
    WarmUp = 2
    Normal = 3
    CoolDown = 4
    Invalid = -1


class ScheduleCallable(Protocol):
    def getCurrentVal(self) -> float:
        ...


class WaterFlowCurve(Protocol):
    def value(self, state, pnetss: float, tcw_in: float) -> float:
        ...


@dataclass
class A42ModelData:
    MinElecPower: float = 0.0
    MaxElecPower: float = 0.0
    DeltaPelMax: float = 0.0
    DeltaFuelMdotMax: float = 0.0
    WarmUpByTimeDelay: bool = False
    WarmUpByEngineTemp: bool = False
    MandatoryFullCoolDown: bool = False
    WarmRestartOkay: bool = False
    WarmUpDelay: float = 0.0
    CoolDownDelay: float = 0.0
    PcoolDown: float = 0.0
    Pstandby: float = 0.0
    MCeng: float = 0.0
    MCcw: float = 0.0
    kf: float = 0.0
    TnomEngOp: float = 0.0
    kp: float = 0.0
    ElecEff: float = 0.0
    ThermEff: float = 0.0
    InternalFlowControl: bool = False
    MinWaterMdot: float = 0.0
    Teng: float = 0.0
    TengLast: float = 0.0
    OffModeTime: float = 0.0
    StandyByModeTime: float = 0.0
    WarmUpModeTime: float = 0.0
    NormalModeTime: float = 0.0
    CoolDownModeTime: float = 0.0
    WaterFlowCurve: Optional[WaterFlowCurve] = None


@dataclass
class MicroCHPData:
    Name: str = ""
    A42Model: A42ModelData = None
    availSched: Optional[ScheduleCallable] = None
    PlantInletNodeID: int = 0
    PlantOutletNodeID: int = 0
    DynamicsControlID: int = 0

    def __post_init__(self):
        if self.A42Model is None:
            self.A42Model = A42ModelData()


@dataclass
class GeneratorDynamicsData:
    Name: str = ""
    PelMin: float = 0.0
    PelMax: float = 0.0
    UpTranLimit: float = 0.0
    DownTranLimit: float = 0.0
    UpTranLimitFuel: float = 0.0
    DownTranLimitFuel: float = 0.0
    WarmUpByTimeDelay: bool = False
    WarmUpByEngineTemp: bool = False
    MandatoryFullCoolDown: bool = False
    WarmRestartOkay: bool = False
    WarmUpDelay: float = 0.0
    CoolDownDelay: float = 0.0
    PcoolDown: float = 0.0
    Pstandby: float = 0.0
    MCeng: float = 0.0
    MCcw: float = 0.0
    kf: float = 0.0
    TnomEngOp: float = 0.0
    kp: float = 0.0
    availSched: Optional[ScheduleCallable] = None
    StartUpTimeDelay: float = 0.0
    ElectEffNom: float = 0.0
    ThermEffNom: float = 0.0
    QdotHXMax: float = 0.0
    QdotHXMin: float = 0.0
    QdotHXOpt: float = 0.0
    LastOpMode: OperatingMode = OperatingMode.Off
    FractionalDayofLastStartUp: float = 0.0
    FractionalDayofLastShutDown: float = 0.0
    PelLastTimeStep: float = 0.0
    FuelMdotLastTimestep: float = 0.0
    CurrentOpMode: OperatingMode = OperatingMode.Off


@dataclass
class NodeData:
    Temp: float = 0.0
    MassFlowRate: float = 0.0


@dataclass
class CWPlantLocData:
    loopNum: int = 0


@dataclass
class DataGeneratorsStub:
    pass


@dataclass
class DataCHPElectGenStub:
    NumMicroCHPs: int = 0
    MicroCHP: list = None

    def __post_init__(self):
        if self.MicroCHP is None:
            self.MicroCHP = []


@dataclass
class DataGeneratorStub:
    GeneratorDynamics: list = None
    InternalFlowControl: bool = False
    InletCWnode: int = 0
    TcwIn: float = 0.0
    TrialMdotcw: float = 0.0
    LimitMinMdotcw: float = 0.0

    def __post_init__(self):
        if self.GeneratorDynamics is None:
            self.GeneratorDynamics = []


@dataclass
class DataHVACGlobalsStub:
    SysTimeElapsed: float = 0.0
    TimeStepSys: float = 0.0
    TimeStepSysSec: float = 0.0


@dataclass
class DataLoopNodesStub:
    Node: list = None

    def __post_init__(self):
        if self.Node is None:
            self.Node = []


@dataclass
class DataGlobalStub:
    DayOfSim: int = 1
    CurrentTime: float = 0.0


@dataclass
class EnergyPlusData:
    dataCHPElectGen: DataCHPElectGenStub = None
    dataGenerator: DataGeneratorStub = None
    dataHVACGlobal: DataHVACGlobalsStub = None
    dataLoopNodes: DataLoopNodesStub = None
    dataGlobal: DataGlobalStub = None

    def __post_init__(self):
        if self.dataCHPElectGen is None:
            self.dataCHPElectGen = DataCHPElectGenStub()
        if self.dataGenerator is None:
            self.dataGenerator = DataGeneratorStub()
        if self.dataHVACGlobal is None:
            self.dataHVACGlobal = DataHVACGlobalsStub()
        if self.dataLoopNodes is None:
            self.dataLoopNodes = DataLoopNodesStub()
        if self.dataGlobal is None:
            self.dataGlobal = DataGlobalStub()


class Constant:
    rSecsInHour = 3600.0
    rHoursInDay = 24.0


class PlantUtilities:
    @staticmethod
    def SetComponentFlowRate(state: EnergyPlusData, mdot: float, inlet_node: int, 
                             outlet_node: int, loc) -> None:
        pass


def SetupGeneratorControlStateManager(state: EnergyPlusData, gen_num: int) -> None:
    num_gens_w_dynamics = state.dataCHPElectGen.NumMicroCHPs

    if not state.dataGenerator.GeneratorDynamics:
        state.dataGenerator.GeneratorDynamics = [GeneratorDynamicsData() for _ in range(num_gens_w_dynamics)]

    this_gen = state.dataGenerator.GeneratorDynamics[gen_num - 1]
    this_micro_chp = state.dataCHPElectGen.MicroCHP[gen_num - 1]
    
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
    this_gen.CoolDownDelay = this_micro_chp.A42Model.CoolDownDelay / Constant.rSecsInHour
    this_gen.PcoolDown = this_micro_chp.A42Model.PcoolDown
    this_gen.Pstandby = this_micro_chp.A42Model.Pstandby
    this_gen.MCeng = this_micro_chp.A42Model.MCeng
    this_gen.MCcw = this_micro_chp.A42Model.MCcw
    this_gen.kf = this_micro_chp.A42Model.kf
    this_gen.TnomEngOp = this_micro_chp.A42Model.TnomEngOp
    this_gen.kp = this_micro_chp.A42Model.kp
    this_gen.availSched = this_micro_chp.availSched
    this_gen.StartUpTimeDelay = this_micro_chp.A42Model.WarmUpDelay / Constant.rSecsInHour

    this_gen.ElectEffNom = this_micro_chp.A42Model.ElecEff
    this_gen.ThermEffNom = this_micro_chp.A42Model.ThermEff
    this_gen.QdotHXMax = (this_micro_chp.A42Model.ThermEff * this_micro_chp.A42Model.MaxElecPower / 
                          this_micro_chp.A42Model.ElecEff)
    this_gen.QdotHXMin = (this_micro_chp.A42Model.ThermEff * this_micro_chp.A42Model.MinElecPower / 
                          this_micro_chp.A42Model.ElecEff)
    this_gen.QdotHXOpt = this_gen.QdotHXMax
    this_micro_chp.DynamicsControlID = gen_num


def ManageGeneratorControlState(state: EnergyPlusData,
                                generator_num: int,
                                run_flag_elect_center: bool,
                                run_flag_plant: bool,
                                elec_load_request: float,
                                thermal_load_request: float) -> tuple:
    sys_time_elapsed = state.dataHVACGlobal.SysTimeElapsed
    time_step_sys = state.dataHVACGlobal.TimeStepSys
    time_step_sys_sec = state.dataHVACGlobal.TimeStepSysSec

    plr_for_subtimestep_start_up = 1.0
    plr_for_subtimestep_shut_down = 0.0
    plr_start_up = False
    plr_shut_down = False
    state.dataGenerator.InternalFlowControl = False

    dyna_cntrl_num = state.dataCHPElectGen.MicroCHP[generator_num - 1].DynamicsControlID
    state.dataGenerator.InletCWnode = state.dataCHPElectGen.MicroCHP[generator_num - 1].PlantInletNodeID
    state.dataGenerator.TcwIn = state.dataLoopNodes.Node[state.dataCHPElectGen.MicroCHP[generator_num - 1].PlantInletNodeID - 1].Temp
    
    if state.dataCHPElectGen.MicroCHP[generator_num - 1].A42Model.InternalFlowControl:
        state.dataGenerator.InternalFlowControl = True
    
    state.dataGenerator.LimitMinMdotcw = state.dataCHPElectGen.MicroCHP[generator_num - 1].A42Model.MinWaterMdot

    this_gen = state.dataGenerator.GeneratorDynamics[dyna_cntrl_num - 1]
    pel_input = elec_load_request
    elect_load_for_thermal_request = 0.0
    
    if (thermal_load_request > 0.0) and run_flag_plant:
        elect_load_for_thermal_request = this_gen.ThermEffNom * thermal_load_request / this_gen.ElectEffNom
        pel_input = max(pel_input, elect_load_for_thermal_request)

    if run_flag_elect_center or run_flag_plant:
        run_flag = True
    else:
        run_flag = False

    sched_val = this_gen.availSched.getCurrentVal() if this_gen.availSched else 1.0
    pel = pel_input

    if state.dataGenerator.InternalFlowControl and (sched_val > 0.0):
        state.dataGenerator.TrialMdotcw = FuncDetermineCWMdotForInternalFlowControl(
            state, generator_num, pel, state.dataGenerator.TcwIn)
    else:
        state.dataGenerator.TrialMdotcw = state.dataLoopNodes.Node[state.dataGenerator.InletCWnode - 1].MassFlowRate

    new_op_mode = OperatingMode.Invalid

    if this_gen.LastOpMode in (OperatingMode.Off, OperatingMode.Standby):
        if sched_val == 0.0:
            new_op_mode = OperatingMode.Off
        elif ((sched_val != 0.0) and (not run_flag)) or (state.dataGenerator.TrialMdotcw < state.dataGenerator.LimitMinMdotcw):
            new_op_mode = OperatingMode.Standby
        elif (sched_val != 0.0) and run_flag:
            if this_gen.WarmUpByTimeDelay:
                if this_gen.StartUpTimeDelay == 0.0:
                    new_op_mode = OperatingMode.Normal
                elif this_gen.StartUpTimeDelay >= time_step_sys:
                    new_op_mode = OperatingMode.WarmUp
                    this_gen.FractionalDayofLastStartUp = (
                        float(state.dataGlobal.DayOfSim) +
                        (int(state.dataGlobal.CurrentTime) +
                         (sys_time_elapsed + (state.dataGlobal.CurrentTime - int(state.dataGlobal.CurrentTime) - time_step_sys))) /
                        Constant.rHoursInDay)
                else:
                    new_op_mode = OperatingMode.Normal
                    plr_start_up = True
                    plr_for_subtimestep_start_up = (time_step_sys - this_gen.StartUpTimeDelay) / time_step_sys
            
            if this_gen.WarmUpByEngineTemp:
                if state.dataCHPElectGen.MicroCHP[generator_num - 1].A42Model.Teng >= this_gen.TnomEngOp:
                    this_micro_chp = state.dataCHPElectGen.MicroCHP[generator_num - 1]
                    new_op_mode = OperatingMode.Normal
                    plr_start_up = True
                    if (this_micro_chp.A42Model.Teng - this_micro_chp.A42Model.TengLast) > 0.0:
                        plr_for_subtimestep_start_up = (
                            (this_micro_chp.A42Model.Teng - this_gen.TnomEngOp) /
                            (this_micro_chp.A42Model.Teng - this_micro_chp.A42Model.TengLast))
                    else:
                        plr_for_subtimestep_start_up = 1.0
                else:
                    new_op_mode = OperatingMode.WarmUp

    elif this_gen.LastOpMode == OperatingMode.WarmUp:
        if sched_val == 0.0:
            if this_gen.CoolDownDelay == 0.0:
                new_op_mode = OperatingMode.Off
            else:
                if this_gen.CoolDownDelay > time_step_sys:
                    new_op_mode = OperatingMode.CoolDown
                    this_gen.FractionalDayofLastShutDown = (
                        float(state.dataGlobal.DayOfSim) +
                        (int(state.dataGlobal.CurrentTime) +
                         (sys_time_elapsed + (state.dataGlobal.CurrentTime - int(state.dataGlobal.CurrentTime)))) /
                        Constant.rHoursInDay)
                else:
                    new_op_mode = OperatingMode.Off
        elif ((sched_val != 0.0) and (not run_flag)) or (state.dataGenerator.TrialMdotcw < state.dataGenerator.LimitMinMdotcw):
            if this_gen.CoolDownDelay == 0.0:
                new_op_mode = OperatingMode.Standby
            else:
                if this_gen.CoolDownDelay > time_step_sys:
                    new_op_mode = OperatingMode.CoolDown
                    this_gen.FractionalDayofLastShutDown = (
                        float(state.dataGlobal.DayOfSim) +
                        (int(state.dataGlobal.CurrentTime) +
                         (sys_time_elapsed + (state.dataGlobal.CurrentTime - int(state.dataGlobal.CurrentTime)))) /
                        Constant.rHoursInDay)
                else:
                    new_op_mode = OperatingMode.Standby
        elif (sched_val != 0.0) and run_flag:
            if this_gen.WarmUpByTimeDelay:
                current_fractional_day = (
                    float(state.dataGlobal.DayOfSim) +
                    (int(state.dataGlobal.CurrentTime) +
                     (sys_time_elapsed + (state.dataGlobal.CurrentTime - int(state.dataGlobal.CurrentTime)))) /
                    Constant.rHoursInDay)
                ending_fractional_day = this_gen.FractionalDayofLastStartUp + this_gen.StartUpTimeDelay / Constant.rHoursInDay
                if (abs(current_fractional_day - ending_fractional_day) < 0.000001) or (current_fractional_day > ending_fractional_day):
                    new_op_mode = OperatingMode.Normal
                    plr_start_up = True
                    last_system_time_step_fractional_day = current_fractional_day - (time_step_sys / Constant.rHoursInDay)
                    plr_for_subtimestep_start_up = (
                        (current_fractional_day - ending_fractional_day) /
                        (current_fractional_day - last_system_time_step_fractional_day))
                else:
                    new_op_mode = OperatingMode.WarmUp
            elif this_gen.WarmUpByEngineTemp:
                if state.dataCHPElectGen.MicroCHP[generator_num - 1].A42Model.TengLast >= this_gen.TnomEngOp:
                    this_micro_chp = state.dataCHPElectGen.MicroCHP[generator_num - 1]
                    new_op_mode = OperatingMode.Normal
                    plr_start_up = True
                    if (this_micro_chp.A42Model.Teng - this_micro_chp.A42Model.TengLast) > 0.0:
                        plr_for_subtimestep_start_up = (
                            (this_micro_chp.A42Model.Teng - this_gen.TnomEngOp) /
                            (this_micro_chp.A42Model.Teng - this_micro_chp.A42Model.TengLast))
                    else:
                        plr_for_subtimestep_start_up = 1.0
                else:
                    new_op_mode = OperatingMode.WarmUp

    elif this_gen.LastOpMode == OperatingMode.Normal:
        if ((sched_val == 0.0) or (not run_flag)) or (state.dataGenerator.TrialMdotcw < state.dataGenerator.LimitMinMdotcw):
            if this_gen.CoolDownDelay == 0.0:
                if sched_val != 0.0:
                    new_op_mode = OperatingMode.Standby
                else:
                    new_op_mode = OperatingMode.Off
            elif this_gen.CoolDownDelay >= time_step_sys:
                new_op_mode = OperatingMode.CoolDown
                this_gen.FractionalDayofLastShutDown = (
                    float(state.dataGlobal.DayOfSim) +
                    (int(state.dataGlobal.CurrentTime) +
                     (sys_time_elapsed + (state.dataGlobal.CurrentTime - int(state.dataGlobal.CurrentTime)))) /
                    Constant.rHoursInDay)
            else:
                if sched_val != 0.0:
                    new_op_mode = OperatingMode.Standby
                else:
                    new_op_mode = OperatingMode.Off
                plr_shut_down = True
                plr_for_subtimestep_shut_down = this_gen.CoolDownDelay / time_step_sys
                this_gen.FractionalDayofLastShutDown = (
                    float(state.dataGlobal.DayOfSim) +
                    (int(state.dataGlobal.CurrentTime) +
                     (sys_time_elapsed + (state.dataGlobal.CurrentTime - int(state.dataGlobal.CurrentTime)))) /
                    Constant.rHoursInDay)
        else:
            new_op_mode = OperatingMode.Normal

    elif this_gen.LastOpMode == OperatingMode.CoolDown:
        if sched_val == 0.0:
            if this_gen.CoolDownDelay > 0.0:
                current_fractional_day = (
                    float(state.dataGlobal.DayOfSim) +
                    (int(state.dataGlobal.CurrentTime) +
                     (sys_time_elapsed + (state.dataGlobal.CurrentTime - int(state.dataGlobal.CurrentTime)))) /
                    Constant.rHoursInDay)
                ending_fractional_day = (
                    this_gen.FractionalDayofLastShutDown + this_gen.CoolDownDelay / Constant.rHoursInDay -
                    (time_step_sys / Constant.rHoursInDay))
                if (abs(current_fractional_day - ending_fractional_day) < 0.000001) or (current_fractional_day > ending_fractional_day):
                    new_op_mode = OperatingMode.Off
                    plr_shut_down = True
                    last_system_time_step_fractional_day = current_fractional_day - (time_step_sys / Constant.rHoursInDay)
                    plr_for_subtimestep_shut_down = (ending_fractional_day - last_system_time_step_fractional_day) * Constant.rHoursInDay / time_step_sys
                else:
                    new_op_mode = OperatingMode.CoolDown
            else:
                new_op_mode = OperatingMode.Off
        elif ((sched_val != 0.0) and (not run_flag)) or (state.dataGenerator.TrialMdotcw < state.dataGenerator.LimitMinMdotcw):
            if this_gen.CoolDownDelay > 0.0:
                current_fractional_day = (
                    float(state.dataGlobal.DayOfSim) +
                    (int(state.dataGlobal.CurrentTime) +
                     (sys_time_elapsed + (state.dataGlobal.CurrentTime - int(state.dataGlobal.CurrentTime)))) /
                    Constant.rHoursInDay)
                ending_fractional_day = (
                    this_gen.FractionalDayofLastShutDown + this_gen.CoolDownDelay / Constant.rHoursInDay -
                    (time_step_sys / Constant.rHoursInDay))
                if (abs(current_fractional_day - ending_fractional_day) < 0.000001) or (current_fractional_day > ending_fractional_day):
                    new_op_mode = OperatingMode.Standby
                    plr_shut_down = True
                    last_system_time_step_fractional_day = current_fractional_day - (time_step_sys / Constant.rHoursInDay)
                    plr_for_subtimestep_shut_down = (ending_fractional_day - last_system_time_step_fractional_day) * Constant.rHoursInDay / time_step_sys
                else:
                    new_op_mode = OperatingMode.CoolDown
            else:
                new_op_mode = OperatingMode.Standby
        elif (sched_val != 0.0) and run_flag:
            if this_gen.MandatoryFullCoolDown:
                if this_gen.CoolDownDelay > 0.0:
                    current_fractional_day = (
                        float(state.dataGlobal.DayOfSim) +
                        (int(state.dataGlobal.CurrentTime) +
                         (sys_time_elapsed + (state.dataGlobal.CurrentTime - int(state.dataGlobal.CurrentTime)))) /
                        Constant.rHoursInDay)
                    ending_fractional_day = (
                        this_gen.FractionalDayofLastShutDown + this_gen.CoolDownDelay / Constant.rHoursInDay -
                        (time_step_sys / Constant.rHoursInDay))
                    if (abs(current_fractional_day - ending_fractional_day) < 0.000001) or (current_fractional_day < ending_fractional_day):
                        new_op_mode = OperatingMode.CoolDown
                    else:
                        plr_shut_down = True
                        last_system_time_step_fractional_day = current_fractional_day - (time_step_sys / Constant.rHoursInDay)
                        plr_for_subtimestep_shut_down = (ending_fractional_day - last_system_time_step_fractional_day) * Constant.rHoursInDay / time_step_sys
                        if this_gen.StartUpTimeDelay == 0.0:
                            new_op_mode = OperatingMode.Normal
                            plr_start_up = True
                            plr_for_subtimestep_start_up = (
                                (current_fractional_day - ending_fractional_day) /
                                (current_fractional_day - last_system_time_step_fractional_day))
                        elif this_gen.StartUpTimeDelay > 0.0:
                            if (current_fractional_day - ending_fractional_day) > this_gen.StartUpTimeDelay:
                                new_op_mode = OperatingMode.Normal
                                plr_start_up = True
                                plr_for_subtimestep_start_up = (
                                    (current_fractional_day - ending_fractional_day) /
                                    (current_fractional_day - last_system_time_step_fractional_day))
                            else:
                                new_op_mode = OperatingMode.WarmUp
                                this_gen.FractionalDayofLastStartUp = (
                                    float(state.dataGlobal.DayOfSim) +
                                    (int(state.dataGlobal.CurrentTime) +
                                     (sys_time_elapsed + (state.dataGlobal.CurrentTime - int(state.dataGlobal.CurrentTime) - time_step_sys))) /
                                    Constant.rHoursInDay)
                else:
                    new_op_mode = OperatingMode.Standby
            else:
                if this_gen.WarmUpByTimeDelay:
                    if this_gen.StartUpTimeDelay == 0.0:
                        new_op_mode = OperatingMode.Normal
                    elif this_gen.StartUpTimeDelay > 0.0:
                        current_fractional_day = (
                            float(state.dataGlobal.DayOfSim) +
                            (int(state.dataGlobal.CurrentTime) +
                             (sys_time_elapsed + (state.dataGlobal.CurrentTime - int(state.dataGlobal.CurrentTime)))) /
                            Constant.rHoursInDay)
                        ending_fractional_day = this_gen.FractionalDayofLastShutDown + this_gen.CoolDownDelay / Constant.rHoursInDay
                        if (abs(current_fractional_day - ending_fractional_day) < 0.000001) or (current_fractional_day > ending_fractional_day):
                            new_op_mode = OperatingMode.Normal
                            plr_start_up = True
                            last_system_time_step_fractional_day = current_fractional_day - (time_step_sys / Constant.rHoursInDay)
                            plr_for_subtimestep_start_up = (
                                (current_fractional_day - ending_fractional_day) /
                                (current_fractional_day - last_system_time_step_fractional_day))
                        else:
                            new_op_mode = OperatingMode.WarmUp
                            this_gen.FractionalDayofLastStartUp = (
                                float(state.dataGlobal.DayOfSim) +
                                (int(state.dataGlobal.CurrentTime) +
                                 (sys_time_elapsed + (state.dataGlobal.CurrentTime - int(state.dataGlobal.CurrentTime) - time_step_sys))) /
                                Constant.rHoursInDay)

    if plr_for_subtimestep_start_up < 0.0:
        plr_for_subtimestep_start_up = 0.0
    if plr_for_subtimestep_start_up > 1.0:
        plr_for_subtimestep_start_up = 1.0

    if plr_for_subtimestep_shut_down < 0.0:
        plr_for_subtimestep_shut_down = 0.0
    if plr_for_subtimestep_shut_down > 1.0:
        plr_for_subtimestep_shut_down = 1.0

    if new_op_mode == OperatingMode.WarmUp:
        pel = pel_input * plr_for_subtimestep_start_up

    if new_op_mode == OperatingMode.Normal:
        pel *= plr_for_subtimestep_start_up
        if pel > this_gen.PelLastTimeStep:
            max_pel = this_gen.PelLastTimeStep + this_gen.UpTranLimit * time_step_sys_sec
            if max_pel < pel:
                pel = max_pel
        elif pel < this_gen.PelLastTimeStep:
            min_pel = this_gen.PelLastTimeStep - this_gen.DownTranLimit * time_step_sys_sec
            if pel < min_pel:
                pel = min_pel

    if new_op_mode == OperatingMode.CoolDown:
        pel = 0.0
    
    if new_op_mode == OperatingMode.Off:
        pel = 0.0
    
    if new_op_mode == OperatingMode.Standby:
        pel = 0.0

    if pel < this_gen.PelMin:
        pel = this_gen.PelMin
    if pel > this_gen.PelMax:
        pel = this_gen.PelMax

    this_micro_chp = state.dataCHPElectGen.MicroCHP[generator_num - 1]
    this_micro_chp.A42Model.OffModeTime = 0.0
    this_micro_chp.A42Model.StandyByModeTime = 0.0
    this_micro_chp.A42Model.WarmUpModeTime = 0.0
    this_micro_chp.A42Model.NormalModeTime = 0.0
    this_micro_chp.A42Model.CoolDownModeTime = 0.0

    if new_op_mode == OperatingMode.Off:
        if plr_for_subtimestep_shut_down == 0.0:
            this_micro_chp.A42Model.OffModeTime = time_step_sys_sec
        elif (plr_for_subtimestep_shut_down > 0.0) and (plr_for_subtimestep_shut_down < 1.0):
            this_micro_chp.A42Model.CoolDownModeTime = time_step_sys_sec * plr_for_subtimestep_shut_down
            this_micro_chp.A42Model.OffModeTime = time_step_sys_sec * (1.0 - plr_for_subtimestep_shut_down)
        else:
            this_micro_chp.A42Model.OffModeTime = time_step_sys_sec
    elif new_op_mode == OperatingMode.Standby:
        if plr_for_subtimestep_shut_down == 0.0:
            this_micro_chp.A42Model.StandyByModeTime = time_step_sys_sec
        elif (plr_for_subtimestep_shut_down > 0.0) and (plr_for_subtimestep_shut_down < 1.0):
            this_micro_chp.A42Model.CoolDownModeTime = time_step_sys_sec * plr_for_subtimestep_shut_down
            this_micro_chp.A42Model.StandyByModeTime = time_step_sys_sec * (1.0 - plr_for_subtimestep_shut_down)
        else:
            this_micro_chp.A42Model.StandyByModeTime = time_step_sys_sec
    elif new_op_mode == OperatingMode.WarmUp:
        if plr_for_subtimestep_shut_down == 0.0:
            this_micro_chp.A42Model.WarmUpModeTime = time_step_sys_sec
        elif (plr_for_subtimestep_shut_down > 0.0) and (plr_for_subtimestep_shut_down < 1.0):
            this_micro_chp.A42Model.CoolDownModeTime = time_step_sys_sec * plr_for_subtimestep_shut_down
            this_micro_chp.A42Model.WarmUpModeTime = time_step_sys_sec * (1.0 - plr_for_subtimestep_shut_down)
        else:
            this_micro_chp.A42Model.WarmUpModeTime = time_step_sys_sec
    elif new_op_mode == OperatingMode.Normal:
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
    elif new_op_mode == OperatingMode.CoolDown:
        this_micro_chp.A42Model.CoolDownModeTime = time_step_sys_sec

    this_gen.CurrentOpMode = new_op_mode

    return (pel, new_op_mode, plr_for_subtimestep_start_up, plr_for_subtimestep_shut_down)


def ManageGeneratorFuelFlow(state: EnergyPlusData,
                            generator_num: int,
                            fuel_flow_request: float) -> tuple:
    time_step_sys_sec = state.dataHVACGlobal.TimeStepSysSec

    constrained_increasing_mdot = False
    constrained_decreasing_mdot = False
    mdot_fuel = fuel_flow_request

    dyna_cntrl_num = state.dataCHPElectGen.MicroCHP[generator_num - 1].DynamicsControlID
    this_gen = state.dataGenerator.GeneratorDynamics[dyna_cntrl_num - 1]

    if fuel_flow_request > this_gen.FuelMdotLastTimestep:
        max_mdot = this_gen.FuelMdotLastTimestep + this_gen.UpTranLimitFuel * time_step_sys_sec
        if max_mdot < fuel_flow_request:
            mdot_fuel = max_mdot
            constrained_increasing_mdot = True
    elif fuel_flow_request < this_gen.FuelMdotLastTimestep:
        min_mdot = this_gen.FuelMdotLastTimestep - this_gen.DownTranLimitFuel * time_step_sys_sec
        if fuel_flow_request < min_mdot:
            mdot_fuel = min_mdot
            constrained_decreasing_mdot = True

    return (mdot_fuel, constrained_increasing_mdot, constrained_decreasing_mdot)


def FuncDetermineCWMdotForInternalFlowControl(state: EnergyPlusData,
                                              generator_num: int,
                                              pnetss: float,
                                              tcw_in: float) -> float:
    this_micro_chp = state.dataCHPElectGen.MicroCHP[generator_num - 1]
    inlet_node = this_micro_chp.PlantInletNodeID
    outlet_node = this_micro_chp.PlantOutletNodeID

    mdot_cw = this_micro_chp.A42Model.WaterFlowCurve.value(state, pnetss, tcw_in) if this_micro_chp.A42Model.WaterFlowCurve else 0.0

    mdot_cw = max(0.0, mdot_cw)

    if this_micro_chp.CWPlantLoc.loopNum > 0:
        PlantUtilities.SetComponentFlowRate(state, mdot_cw, inlet_node, outlet_node, this_micro_chp.CWPlantLoc)

    return mdot_cw
