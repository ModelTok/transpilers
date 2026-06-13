from ...Fixtures.EnergyPlusFixture import EnergyPlusFixture, delimited_string, process_idf, compare_err_stream
from EnergyPlusData import EnergyPlusData
from DataEnvironment import DataEnvironment
from DataGlobalConstants import Constant
from DataHVACGlobals import HVAC
from DataLoopNode import DataLoopNode
from HeatingCoils import HeatingCoils
from Psychrometrics import Psychrometrics
from ScheduleManager import Sched

var state: EnergyPlusData = EnergyPlusData()

def HeatingCoils_FuelTypeInput():
    var idf_objects: String = delimited_string([
        "Coil:Heating:Fuel,",
        "  Furnace Coil,            !- Name",
        "  ,    !- Availability Schedule Name",
        "  OtherFuel1,              !- FuelType",
        "  0.8,                     !- Gas Burner Efficiency",
        "  20000,                   !- Nominal Capacity {W}",
        "  Heating Coil Air Inlet Node,  !- Air Inlet Node Name",
        "  Air Loop Outlet Node;    !- Air Outlet Node Name",
    ])
    assert_true(process_idf(idf_objects))
    state.init_state(state)
    assert_no_throw(HeatingCoils.GetHeatingCoilInput(state))
    assert(state.dataHeatingCoils.HeatingCoil[0].FuelType == Constant.eFuel.OtherFuel1)

def HeatingCoils_FuelTypeInputError():
    var idf_objects: String = delimited_string([
        "Coil:Heating:Fuel,",
        "  Furnace Coil,            !- Name",
        "  ,    !- Availability Schedule Name",
        "  Electricity,              !- FuelType",
        "  0.8,                     !- Gas Burner Efficiency",
        "  20000,                   !- Nominal Capacity {W}",
        "  Heating Coil Air Inlet Node,  !- Air Inlet Node Name",
        "  Air Loop Outlet Node;    !- Air Outlet Node Name",
    ])
    assert_false(process_idf(idf_objects, false))
    state.init_state(state)
    assert_throw(HeatingCoils.GetHeatingCoilInput(state), RuntimeError)
    var error_string: String = delimited_string([
        "   ** Severe  ** <root>[Coil:Heating:Fuel][Furnace Coil][fuel_type] - \"Electricity\" - Failed to match against any enum values.",
        "   ** Severe  ** GetHeatingCoilInput: Coil:Heating:Fuel: Invalid Fuel Type entered =ELECTRICITY for Name=FURNACE COIL",
        "   **  Fatal  ** GetHeatingCoilInput: Errors found in input.  Program terminates.",
        "   ...Summary of Errors that led to program termination:",
        "   ..... Reference severe error count=2",
        "   ..... Last severe error=GetHeatingCoilInput: Coil:Heating:Fuel: Invalid Fuel Type entered =ELECTRICITY for Name=FURNACE COIL",
    ])
    assert_true(compare_err_stream(error_string, true))

def HeatingCoils_FuelTypeCoal():
    var idf_objects: String = delimited_string([
        "Coil:Heating:Fuel,",
        "  Furnace Coil,            !- Name",
        "  ,    !- Availability Schedule Name",
        "  Coal,                 !- FuelType",
        "  0.8,                     !- Gas Burner Efficiency",
        "  20000,                   !- Nominal Capacity {W}",
        "  Heating Coil Air Inlet Node,  !- Air Inlet Node Name",
        "  Air Loop Outlet Node;    !- Air Outlet Node Name",
    ])
    assert_true(process_idf(idf_objects))
    state.init_state(state)
    assert_no_throw(HeatingCoils.GetHeatingCoilInput(state))
    assert(state.dataHeatingCoils.HeatingCoil[0].FuelType == Constant.eFuel.Coal)

def HeatingCoils_FuelTypePropaneGas():
    var idf_objects: String = delimited_string([
        "Coil:Heating:Fuel,",
        "  Furnace Coil,            !- Name",
        "  ,    !- Availability Schedule Name",
        "  Propane,                 !- FuelType",
        "  0.8,                     !- Gas Burner Efficiency",
        "  20000,                   !- Nominal Capacity {W}",
        "  Heating Coil Air Inlet Node,  !- Air Inlet Node Name",
        "  Air Loop Outlet Node;    !- Air Outlet Node Name",
    ])
    assert_true(process_idf(idf_objects))
    state.init_state(state)
    assert_no_throw(HeatingCoils.GetHeatingCoilInput(state))
    assert(state.dataHeatingCoils.HeatingCoil[0].FuelType == Constant.eFuel.Propane)

def HeatingCoils_OutletAirPropertiesTest():
    state.init_state(state)
    var CoilNum: Int = 1
    var OffMassFlowrate: Float64 = 0.2
    var OnMassFlowrate: Float64 = 0.6
    state.dataHeatingCoils.HeatingCoil.allocate(CoilNum)
    state.dataHeatingCoils.HeatingCoil[CoilNum - 1].InletAirTemp = 0.0
    state.dataHeatingCoils.HeatingCoil[CoilNum - 1].InletAirHumRat = 0.001
    state.dataHeatingCoils.HeatingCoil[CoilNum - 1].InletAirEnthalpy = Psychrometrics.PsyHFnTdbW(
        state.dataHeatingCoils.HeatingCoil[CoilNum - 1].InletAirTemp, state.dataHeatingCoils.HeatingCoil[CoilNum - 1].InletAirHumRat
    )
    state.dataEnvrn.OutBaroPress = 101325.0
    state.dataHeatingCoils.HeatingCoil[CoilNum - 1].availSched = Sched.GetScheduleAlwaysOn(state)
    state.dataHVACGlobal.MSHPMassFlowRateLow = OnMassFlowrate
    state.dataHeatingCoils.HeatingCoil[CoilNum - 1].MSNominalCapacity.allocate(1)
    state.dataHeatingCoils.HeatingCoil[CoilNum - 1].MSNominalCapacity[0] = 10000
    state.dataHeatingCoils.HeatingCoil[CoilNum - 1].MSEfficiency.allocate(1)
    state.dataHeatingCoils.HeatingCoil[CoilNum - 1].MSEfficiency[0] = 0.9
    state.dataHeatingCoils.HeatingCoil[CoilNum - 1].AirInletNodeNum = 1
    state.dataHeatingCoils.HeatingCoil[CoilNum - 1].AirOutletNodeNum = 2
    state.dataLoopNodes.Node.allocate(2)
    state.dataHeatingCoils.HeatingCoil[CoilNum - 1].MSParasiticElecLoad.allocate(1)
    state.dataHeatingCoils.HeatingCoil[CoilNum - 1].MSParasiticElecLoad[0] = 0.0
    state.dataHeatingCoils.HeatingCoil[CoilNum - 1].InletAirMassFlowRate = OffMassFlowrate
    HeatingCoils.CalcMultiStageGasHeatingCoil(state, CoilNum, 0.0, 0.0, 1, HVAC.FanOp.Continuous)
    var HeatLoad00: Float64 = state.dataHeatingCoils.HeatingCoil[CoilNum - 1].InletAirMassFlowRate * (
        Psychrometrics.PsyHFnTdbW(
            state.dataHeatingCoils.HeatingCoil[CoilNum - 1].OutletAirTemp,
            state.dataHeatingCoils.HeatingCoil[CoilNum - 1].OutletAirHumRat
        ) - state.dataHeatingCoils.HeatingCoil[CoilNum - 1].InletAirEnthalpy
    )
    assert_approx_equal(
        HeatLoad00, state.dataHeatingCoils.HeatingCoil[CoilNum - 1].HeatingCoilLoad, 0.0001
    )
    state.dataHeatingCoils.HeatingCoil[CoilNum - 1].InletAirMassFlowRate = 0.5 * OnMassFlowrate + (1.0 - 0.5) * OffMassFlowrate
    HeatingCoils.CalcMultiStageGasHeatingCoil(state, CoilNum, 0.0, 0.5, 1, HVAC.FanOp.Continuous)
    var HeatLoad05: Float64 = state.dataHeatingCoils.HeatingCoil[CoilNum - 1].InletAirMassFlowRate * (
        Psychrometrics.PsyHFnTdbW(
            state.dataHeatingCoils.HeatingCoil[CoilNum - 1].OutletAirTemp,
            state.dataHeatingCoils.HeatingCoil[CoilNum - 1].OutletAirHumRat
        ) - state.dataHeatingCoils.HeatingCoil[CoilNum - 1].InletAirEnthalpy
    )
    assert_approx_equal(
        HeatLoad05, state.dataHeatingCoils.HeatingCoil[CoilNum - 1].HeatingCoilLoad, 0.0001
    )
    state.dataHeatingCoils.HeatingCoil[CoilNum - 1].InletAirMassFlowRate = OnMassFlowrate
    HeatingCoils.CalcMultiStageGasHeatingCoil(state, CoilNum, 0.0, 1.0, 1, HVAC.FanOp.Continuous)
    var HeatLoad10: Float64 = state.dataHeatingCoils.HeatingCoil[CoilNum - 1].InletAirMassFlowRate * (
        Psychrometrics.PsyHFnTdbW(
            state.dataHeatingCoils.HeatingCoil[CoilNum - 1].OutletAirTemp,
            state.dataHeatingCoils.HeatingCoil[CoilNum - 1].OutletAirHumRat
        ) - state.dataHeatingCoils.HeatingCoil[CoilNum - 1].InletAirEnthalpy
    )
    assert_approx_equal(
        HeatLoad10, state.dataHeatingCoils.HeatingCoil[CoilNum - 1].HeatingCoilLoad, 0.0001
    )
    assert_approx_equal(
        HeatLoad05, 0.5 * state.dataHeatingCoils.HeatingCoil[CoilNum - 1].MSNominalCapacity[0], 0.0001
    )
<<<FILE>>>