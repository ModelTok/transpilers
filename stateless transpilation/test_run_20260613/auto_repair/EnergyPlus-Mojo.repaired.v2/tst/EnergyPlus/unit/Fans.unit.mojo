from .Fixtures.EnergyPlusFixture import EnergyPlusFixture, compare_eio_stream
from ......EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from ......EnergyPlus.DataEnvironment import DataEnvironment
from ......EnergyPlus.DataHVACGlobals import DataHVACGlobals
from ......EnergyPlus.DataSizing import AutoSize, DataSizing
from ......EnergyPlus.Fans import FanComponent, HVAC, FanType
from ......EnergyPlus.Sched import GetScheduleAlwaysOff

alias Real64 = Float64
alias auto * = ptr  # not needed, we use direct objects

def test_Fans_FanSizing() raises:
    var fixture = EnergyPlusFixture()
    var state = fixture.state

    state.dataSize.CurZoneEqNum = 0
    state.dataSize.CurSysNum = 0
    state.dataSize.CurOASysNum = 0
    var fan1 = FanComponent()
    fan1.Name = "Test Fan"
    fan1.type = HVAC.FanType.OnOff
    fan1.maxAirFlowRate = AutoSize
    fan1.deltaPress = 500.0
    fan1.totalEff = 0.4
    fan1.sizingPrefix = "Maximum Flow Rate"
    state.dataFans.fans.append(fan1)
    state.dataFans.fanMap.insert_or_assign(fan1.Name, state.dataFans.fans.len)
    state.dataEnvrn.StdRhoAir = 1.2
    state.dataSize.CurZoneEqNum = 0
    state.dataSize.CurSysNum = 0
    state.dataSize.CurOASysNum = 0
    state.dataSize.DataNonZoneNonAirloopValue = 1.00635
    fan1.set_size(state)
    expect_equal(1.00635, fan1.maxAirFlowRate)
    state.dataSize.DataNonZoneNonAirloopValue = 0.0
    expect_near(1.0352, fan1.designPointFEI, 0.0001)
    var eiooutput = String(
        "! <Component Sizing Information>, Component Type, Component Name, Input Field Description, Value\n"
        " Component Sizing Information, Fan:OnOff, Test Fan, Design Size Maximum Flow Rate [m3/s], 1.00635\n"
        " Component Sizing Information, Fan:OnOff, Test Fan, Design Electric Power Consumption [W], 1257.94\n"
    )
    expect_true(compare_eio_stream(eiooutput, true))

def test_Fans_ConstantVolume_EMSPressureRiseResetTest() raises:
    var fixture = EnergyPlusFixture()
    var state = fixture.state

    state.init_state(state)
    state.dataEnvrn.StdRhoAir = 1.0
    var fan1 = FanComponent()
    fan1.Name = "Test Fan"
    fan1.type = HVAC.FanType.Constant
    fan1.sizingPrefix = "Fan Total Efficiency"
    fan1.maxAirFlowRate = AutoSize
    fan1.deltaPress = 300.0
    fan1.totalEff = 1.0
    fan1.motorEff = 0.8
    fan1.motorInAirFrac = 1.0
    fan1.availSched = GetScheduleAlwaysOff(state)
    fan1.maxAirFlowRate = 1.0
    fan1.minAirMassFlowRate = 0.0
    fan1.maxAirMassFlowRate = fan1.maxAirFlowRate
    fan1.inletAirMassFlowRate = fan1.maxAirMassFlowRate
    fan1.rhoAirStdInit = state.dataEnvrn.StdRhoAir
    fan1.EMSPressureOverrideOn = false
    fan1.EMSPressureValue = 0.0
    state.dataHVACGlobal.TurnFansOn = true
    state.dataHVACGlobal.TurnFansOff = false
    fan1.simulateConstant(state)
    var Result_FanPower: Real64 = max(0.0, fan1.maxAirMassFlowRate * fan1.deltaPress / (fan1.totalEff * fan1.rhoAirStdInit))
    expect_equal(Result_FanPower, fan1.totalPower)
    fan1.EMSPressureOverrideOn = true
    fan1.EMSPressureValue = -300.0
    fan1.simulateConstant(state)
    var Result2_FanPower: Real64 = max(0.0, fan1.maxAirMassFlowRate * fan1.EMSPressureValue / (fan1.totalEff * fan1.rhoAirStdInit))
    expect_equal(Result2_FanPower, fan1.totalPower)

def test_Fans_OnOff_EMSPressureRiseResetTest() raises:
    var fixture = EnergyPlusFixture()
    var state = fixture.state

    state.init_state(state)
    state.dataEnvrn.StdRhoAir = 1.0
    var fan1 = FanComponent()
    fan1.Name = "Test Fan"
    fan1.type = HVAC.FanType.OnOff
    fan1.sizingPrefix = "Fan Total Efficiency"
    fan1.maxAirFlowRate = AutoSize
    fan1.deltaPress = 300.0
    fan1.totalEff = 1.0
    fan1.motorEff = 0.8
    fan1.motorInAirFrac = 1.0
    fan1.availSched = GetScheduleAlwaysOff(state)
    fan1.maxAirFlowRate = 1.0
    fan1.minAirMassFlowRate = 0.0
    fan1.maxAirMassFlowRate = fan1.maxAirFlowRate
    fan1.inletAirMassFlowRate = fan1.maxAirMassFlowRate
    fan1.rhoAirStdInit = state.dataEnvrn.StdRhoAir
    fan1.EMSPressureOverrideOn = false
    fan1.EMSPressureValue = 0.0
    state.dataFans.fans.append(fan1)
    state.dataFans.fanMap.insert_or_assign(fan1.Name, state.dataFans.fans.len)
    state.dataHVACGlobal.TurnFansOn = true
    state.dataHVACGlobal.TurnFansOff = false
    fan1.simulateOnOff(state)
    var Result_FanPower: Real64 = max(0.0, fan1.maxAirMassFlowRate * fan1.deltaPress / (fan1.totalEff * fan1.rhoAirStdInit))
    expect_equal(Result_FanPower, fan1.totalPower)
    fan1.EMSPressureOverrideOn = true
    fan1.EMSPressureValue = -300.0
    fan1.simulateOnOff(state)
    var Result2_FanPower: Real64 = max(0.0, fan1.maxAirMassFlowRate * fan1.EMSPressureValue / (fan1.totalEff * fan1.rhoAirStdInit))
    expect_equal(Result2_FanPower, fan1.totalPower)

def test_Fans_VariableVolume_EMSPressureRiseResetTest() raises:
    var fixture = EnergyPlusFixture()
    var state = fixture.state

    state.init_state(state)
    state.dataEnvrn.StdRhoAir = 1.0
    var fan1 = FanComponent()
    fan1.Name = "Test Fan"
    fan1.type = HVAC.FanType.VAV
    fan1.sizingPrefix = "Fan Total Efficiency"
    fan1.maxAirFlowRate = AutoSize
    fan1.deltaPress = 300.0
    fan1.totalEff = 1.0
    fan1.motorEff = 0.8
    fan1.motorInAirFrac = 1.0
    fan1.availSched = GetScheduleAlwaysOff(state)
    fan1.maxAirFlowRate = 1.0
    fan1.minAirMassFlowRate = 0.0
    fan1.maxAirMassFlowRate = fan1.maxAirFlowRate
    fan1.inletAirMassFlowRate = fan1.maxAirMassFlowRate
    fan1.rhoAirStdInit = state.dataEnvrn.StdRhoAir
    fan1.coeffs[0] = 0.06990146
    fan1.coeffs[1] = 1.39500612
    fan1.coeffs[2] = -3.35487336
    fan1.coeffs[3] = 2.89232315
    fan1.coeffs[4] = 0.000
    fan1.EMSPressureOverrideOn = false
    fan1.EMSPressureValue = 0.0
    state.dataFans.fans.append(fan1)
    state.dataFans.fanMap.insert_or_assign(fan1.Name, state.dataFans.fans.len)
    state.dataHVACGlobal.TurnFansOn = true
    state.dataHVACGlobal.TurnFansOff = false
    fan1.simulateVAV(state)
    var FlowRatio: Real64 = 1.0
    var PartLoadFrac: Real64 = (
        fan1.coeffs[0] + fan1.coeffs[1] * FlowRatio + fan1.coeffs[2] * FlowRatio * FlowRatio + fan1.coeffs[3] * FlowRatio * FlowRatio * FlowRatio
    )
    var Result_FanPower: Real64 = max(0.0, PartLoadFrac * fan1.maxAirMassFlowRate * fan1.deltaPress / (fan1.totalEff * fan1.rhoAirStdInit))
    expect_equal(Result_FanPower, fan1.totalPower)
    fan1.EMSPressureOverrideOn = true
    fan1.EMSPressureValue = -300.0
    fan1.simulateVAV(state)
    var Result2_FanPower: Real64 = max(0.0, PartLoadFrac * fan1.maxAirMassFlowRate * fan1.EMSPressureValue / (fan1.totalEff * fan1.rhoAirStdInit))
    expect_equal(Result2_FanPower, fan1.totalPower)

# Helper expectation functions to match C++ style
def expect_equal(lhs: Float64, rhs: Float64):
    assert_almost_equal(lhs, rhs)

def expect_near(lhs: Float64, rhs: Float64, eps: Float64):
    assert_almost_equal(lhs, rhs, abs=eps)

def expect_true(cond: Bool):
    assert cond