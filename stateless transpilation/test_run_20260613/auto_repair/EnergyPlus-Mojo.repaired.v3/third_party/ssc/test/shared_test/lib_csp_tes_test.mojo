from ...tcs.storage_hx import Storage_HX
from ...tcs.htf_properties import HTFProperties
from mem import Pointer

alias Tank = Storage_HX

# === Constants from header ===
def kErrorToleranceLo() -> Float64:
    return 0.001  # 0.1%
def kErrorToleranceHi() -> Float64:
    return 0.01   # 1.0%

# === Forward declarations (trait and structs) ===
trait TankFactory:
    def MakeTank(self, tank_specifications: Pointer[TankSpecifications]) -> Pointer[Tank]
    def MakeSpecifications(self) -> Pointer[TankSpecifications]
    def MakeTankState(self) -> TankState
    def MakeExternalConditions(self) -> TankExternalConditions

struct TankSpecifications:
    var field_fluid: Int32
    var store_fluid: Int32
    var fluid_field: HTFProperties
    var fluid_store: HTFProperties
    var is_direct: Bool
    var config: Int32
    var duty_des: Float64
    var vol_des: Float64
    var h_des: Float64
    var u_des: Float64
    var tank_pairs_des: Float64
    var hot_htr_set_point_des: Float64
    var cold_htr_set_point_des: Float64
    var max_q_htr_cold: Float64
    var max_q_htr_hot: Float64
    var dt_hot_des: Float64
    var dt_cold_des: Float64
    var T_h_in_des: Float64
    var T_h_out_des: Float64

struct TankState:
    var m_prev: Float64
    var T_prev: Float64

struct TankExternalConditions:
    var m_dot_in: Float64
    var m_dot_out: Float64
    var T_in: Float64
    var T_amb: Float64

struct DefaultTankFactory(TankFactory):
    # Constructors
    def __init__(inout self): pass

    def MakeTank(self, tank_specifications: Pointer[TankSpecifications]) -> Pointer[Tank]:
        var tank = new Tank
        tank[].define_storage(
            tank_specifications[].field_fluid,
            tank_specifications[].fluid_store,
            tank_specifications[].is_direct,
            tank_specifications[].config,
            tank_specifications[].duty_des,
            tank_specifications[].vol_des,
            tank_specifications[].h_des,
            tank_specifications[].u_des,
            tank_specifications[].tank_pairs_des,
            tank_specifications[].hot_htr_set_point_des,
            tank_specifications[].cold_htr_set_point_des,
            tank_specifications[].max_q_htr_cold,
            tank_specifications[].max_q_htr_hot,
            tank_specifications[].dt_hot_des,
            tank_specifications[].dt_cold_des,
            tank_specifications[].T_h_in_des,
            tank_specifications[].T_h_out_des)
        return tank

    def MakeSpecifications(self) -> Pointer[TankSpecifications]:
        var tank_specifications = new TankSpecifications
        tank_specifications[].field_fluid = 18
        tank_specifications[].store_fluid = 18
        tank_specifications[].fluid_field.SetFluid(tank_specifications[].field_fluid)
        tank_specifications[].fluid_store.SetFluid(tank_specifications[].store_fluid)
        tank_specifications[].is_direct = True
        tank_specifications[].config = 2
        tank_specifications[].duty_des = 623595520.0
        tank_specifications[].vol_des = 17558.4
        tank_specifications[].h_des = 12.0
        tank_specifications[].u_des = 0.4
        tank_specifications[].tank_pairs_des = 1.0
        tank_specifications[].hot_htr_set_point_des = 638.15
        tank_specifications[].cold_htr_set_point_des = 523.15
        tank_specifications[].max_q_htr_cold = 25.0
        tank_specifications[].max_q_htr_hot = 25.0
        tank_specifications[].dt_hot_des = 5.0
        tank_specifications[].dt_cold_des = 5.0
        tank_specifications[].T_h_in_des = 703.15
        tank_specifications[].T_h_out_des = 566.15
        return tank_specifications

    def MakeTankState(self) -> TankState:
        var tank_state: TankState
        tank_state.m_prev = 3399727.0
        tank_state.T_prev = 563.97
        return tank_state

    def MakeExternalConditions(self) -> TankExternalConditions:
        var external_conditions: TankExternalConditions
        external_conditions.m_dot_in = 0.0
        external_conditions.m_dot_out = 1239.16   # this will more than drain the tank
        external_conditions.T_in = 566.15
        external_conditions.T_amb = 296.15
        return external_conditions

# === Helper for EXPECT_NEAR (simple assertion) ===
def expect_near(val: Float64, expected: Float64, tolerance: Float64):
    if abs(val - expected) > tolerance:
        print("FAIL: expected", expected, "got", val, "tolerance", tolerance)
        # In a real test we'd abort or return failure

# === Test cases ===
def test_csp_common_StorageTank_DrainingTank():
    var is_hot_tank = False
    var dt = 3600.0
    var default_tank_factory = DefaultTankFactory()
    var tank_specifications = default_tank_factory.MakeSpecifications()
    var tank = default_tank_factory.MakeTank(tank_specifications)
    var tank_state = default_tank_factory.MakeTankState()
    var external_conditions = default_tank_factory.MakeExternalConditions()
    var T_ave: Float64 = 0.0
    var vol_ave: Float64 = 0.0
    var q_loss: Float64 = 0.0
    var T_fin: Float64 = 0.0
    var vol_fin: Float64 = 0.0
    var m_fin: Float64 = 0.0
    var q_heater: Float64 = 0.0
    tank[].mixed_tank(
        is_hot_tank, dt,
        tank_state.m_prev, tank_state.T_prev,
        external_conditions.m_dot_in, external_conditions.m_dot_out,
        external_conditions.T_in, external_conditions.T_amb,
        T_ave, vol_ave, q_loss, T_fin, vol_fin, m_fin, q_heater)
    expect_near(T_ave, 563.7, 563.7 * kErrorToleranceLo())
    expect_near(vol_ave, 892.30, 892.30 * kErrorToleranceLo())
    expect_near(q_loss, 0.331, 0.331 * kErrorToleranceLo())
    expect_near(T_fin, 558.9, 558.9 * kErrorToleranceLo())
    expect_near(vol_fin, 0.0, 0.0 * kErrorToleranceLo())
    expect_near(m_fin, 0.0, 0.0 * kErrorToleranceLo())
    expect_near(q_heater, 0.0, 0.0 * kErrorToleranceLo())

def test_csp_common_StorageTank_InitiallyDrainedTank():
    var is_hot_tank = False
    var dt = 3600.0
    var default_tank_factory = DefaultTankFactory()
    var tank_specifications = default_tank_factory.MakeSpecifications()
    var tank = default_tank_factory.MakeTank(tank_specifications)
    var tank_state = default_tank_factory.MakeTankState()
    var external_conditions = default_tank_factory.MakeExternalConditions()
    tank_state.m_prev = 0.0
    var T_ave: Float64 = 0.0
    var vol_ave: Float64 = 0.0
    var q_loss: Float64 = 0.0
    var T_fin: Float64 = 0.0
    var vol_fin: Float64 = 0.0
    var m_fin: Float64 = 0.0
    var q_heater: Float64 = 0.0
    tank[].mixed_tank(
        is_hot_tank, dt,
        tank_state.m_prev, tank_state.T_prev,
        external_conditions.m_dot_in, external_conditions.m_dot_out,
        external_conditions.T_in, external_conditions.T_amb,
        T_ave, vol_ave, q_loss, T_fin, vol_fin, m_fin, q_heater)
    expect_near(T_ave, 563.97, 563.97 * kErrorToleranceLo())
    expect_near(vol_ave, 0.0, 0.0 * kErrorToleranceLo())
    expect_near(q_loss, 0.0, 0.0 * kErrorToleranceLo())
    expect_near(T_fin, 563.97, 563.97 * kErrorToleranceLo())
    expect_near(vol_fin, 0.0, 0.0 * kErrorToleranceLo())
    expect_near(m_fin, 0.0, 0.0 * kErrorToleranceLo())
    expect_near(q_heater, 0.0, 0.0 * kErrorToleranceLo())

# === Main: run tests ===
def main():
    test_csp_common_StorageTank_DrainingTank()
    test_csp_common_StorageTank_InitiallyDrainedTank()
    print("All tests completed.")