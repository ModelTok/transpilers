from testing import assert_equal, assert_almost_equal, @test
from ............EnergyPlus.PhaseChangeModeling.HysteresisModel import Material

type Real64 = Float64

struct GetSpecHeatArgs:
    var previousTemperature: Real64
    var updatedTemperature: Real64
    var temperatureReverse: Real64
    var previousPhaseChangeState: Material.Phase
    var expectedUpdatedPhaseChangeState: Material.Phase
    var expectedSpecificHeat: Real64

    def __init__(
        inout self,
        _previousTemperature: Real64,
        _updatedTemperature: Real64,
        _temperatureReverse: Real64,
        _previousPhaseChangeState: Material.Phase,
        _expectedUpdatedPhaseChangeState: Material.Phase,
        _expectedSpecificHeat: Real64,
    ):
        self.previousTemperature = _previousTemperature
        self.updatedTemperature = _updatedTemperature
        self.temperatureReverse = _temperatureReverse
        self.previousPhaseChangeState = _previousPhaseChangeState
        self.expectedUpdatedPhaseChangeState = _expectedUpdatedPhaseChangeState
        self.expectedSpecificHeat = _expectedSpecificHeat

struct HysteresisTest:
    var ModelA: Material.MaterialPhaseChange

    def __init__(inout self):
        self.ModelA = Material.MaterialPhaseChange()

    def SetUp(inout self):
        self.ModelA.Name = "PCM Name"
        self.ModelA.totalLatentHeat = 25000.0       # J/kg ?
        self.ModelA.specificHeatLiquid = 25000.0    # J/kgK
        self.ModelA.deltaTempMeltingHigh = 1.0      # deltaC
        self.ModelA.peakTempMelting = 20.0          # degC
        self.ModelA.deltaTempMeltingLow = 1.0       # deltaC
        self.ModelA.specificHeatSolid = 20000.0     # J/kgK
        self.ModelA.deltaTempFreezingHigh = 1.0     # deltaC
        self.ModelA.peakTempFreezing = 23.0         # degC
        self.ModelA.deltaTempFreezingLow = 1.0      # deltaC
        self.ModelA.specHeatTransition = (self.ModelA.specificHeatSolid + self.ModelA.specificHeatLiquid) / 2.0
        self.ModelA.CpOld = self.ModelA.specificHeatSolid
        self.ModelA.fullySolidThermalConductivity = 1.0
        self.ModelA.fullyLiquidThermalConductivity = 2.0
        self.ModelA.fullySolidDensity = 3.0
        self.ModelA.fullyLiquidDensity = 4.0

    def TearDown(inout self):

@test
def StraightUpCurve():
    var fixture = HysteresisTest()
    fixture.SetUp()
    var args_list = List[GetSpecHeatArgs]()
    args_list.append(GetSpecHeatArgs(14.0, 14.5, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20000.417543))
    args_list.append(GetSpecHeatArgs(14.5, 15.0, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20001.134998))
    args_list.append(GetSpecHeatArgs(15.0, 15.5, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20003.085245))
    args_list.append(GetSpecHeatArgs(15.5, 16.0, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20008.386566))
    args_list.append(GetSpecHeatArgs(16.0, 16.5, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20022.797049))
    args_list.append(GetSpecHeatArgs(16.5, 17.0, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20061.968804))
    args_list.append(GetSpecHeatArgs(17.0, 17.5, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20168.448675))
    args_list.append(GetSpecHeatArgs(17.5, 18.0, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20457.890972))
    args_list.append(GetSpecHeatArgs(18.0, 18.5, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 21244.676709))
    args_list.append(GetSpecHeatArgs(18.5, 19.0, -999.000000, Material.Phase.Crystallized, Material.Phase.Melting, 23383.382081))
    args_list.append(GetSpecHeatArgs(19.0, 19.5, -999.000000, Material.Phase.Melting, Material.Phase.Melting, 29196.986029))
    args_list.append(GetSpecHeatArgs(19.5, 20.0, -999.000000, Material.Phase.Melting, Material.Phase.Melting, 35803.013971))
    args_list.append(GetSpecHeatArgs(20.0, 20.5, -999.000000, Material.Phase.Melting, Material.Phase.Melting, 34196.986029))
    args_list.append(GetSpecHeatArgs(20.5, 21.0, -999.000000, Material.Phase.Melting, Material.Phase.Melting, 28383.382081))
    args_list.append(GetSpecHeatArgs(21.0, 21.5, -999.000000, Material.Phase.Melting, Material.Phase.Liquid, 26244.676709))
    args_list.append(GetSpecHeatArgs(21.5, 22.0, -999.000000, Material.Phase.Liquid, Material.Phase.Liquid, 25457.890972))
    args_list.append(GetSpecHeatArgs(22.0, 22.5, -999.000000, Material.Phase.Liquid, Material.Phase.Liquid, 25168.448675))
    args_list.append(GetSpecHeatArgs(22.5, 23.0, -999.000000, Material.Phase.Liquid, Material.Phase.Liquid, 25061.968804))
    args_list.append(GetSpecHeatArgs(23.0, 23.5, -999.000000, Material.Phase.Liquid, Material.Phase.Liquid, 25022.797049))
    args_list.append(GetSpecHeatArgs(23.5, 24.0, -999.000000, Material.Phase.Liquid, Material.Phase.Liquid, 25008.386566))
    args_list.append(GetSpecHeatArgs(24.0, 24.5, -999.000000, Material.Phase.Liquid, Material.Phase.Liquid, 25003.085245))
    args_list.append(GetSpecHeatArgs(24.5, 25.0, -999.000000, Material.Phase.Liquid, Material.Phase.Liquid, 25001.134998))
    args_list.append(GetSpecHeatArgs(25.0, 25.5, -999.000000, Material.Phase.Liquid, Material.Phase.Liquid, 25000.417543))
    args_list.append(GetSpecHeatArgs(25.5, 26.0, -999.000000, Material.Phase.Liquid, Material.Phase.Liquid, 25000.153605))
    args_list.append(GetSpecHeatArgs(26.0, 26.5, -999.000000, Material.Phase.Liquid, Material.Phase.Liquid, 25000.056508))
    for cp_call in args_list:
        var calculated_pcm_state = Material.Phase.Invalid
        var calculated_cp = fixture.ModelA.getCurrentSpecificHeat(
            cp_call.previousTemperature,
            cp_call.updatedTemperature,
            cp_call.temperatureReverse,
            cp_call.previousPhaseChangeState,
            calculated_pcm_state,
        )
        assert_equal(cp_call.expectedUpdatedPhaseChangeState, calculated_pcm_state)
        assert_almost_equal(calculated_cp, cp_call.expectedSpecificHeat, 1.0)
    fixture.TearDown()

@test
def StraightDownCurve():
    var fixture = HysteresisTest()
    fixture.SetUp()
    var args_list = List[GetSpecHeatArgs]()
    args_list.append(GetSpecHeatArgs(30.0, 29.5, -999.000000, Material.Phase.Liquid, Material.Phase.Liquid, 25000.056508))
    args_list.append(GetSpecHeatArgs(29.5, 29.0, -999.000000, Material.Phase.Liquid, Material.Phase.Liquid, 25000.153605))
    args_list.append(GetSpecHeatArgs(29.0, 28.5, -999.000000, Material.Phase.Liquid, Material.Phase.Liquid, 25000.417543))
    args_list.append(GetSpecHeatArgs(28.5, 28.0, -999.000000, Material.Phase.Liquid, Material.Phase.Liquid, 25001.134998))
    args_list.append(GetSpecHeatArgs(28.0, 27.5, -999.000000, Material.Phase.Liquid, Material.Phase.Liquid, 25003.085245))
    args_list.append(GetSpecHeatArgs(27.5, 27.0, -999.000000, Material.Phase.Liquid, Material.Phase.Liquid, 25008.386566))
    args_list.append(GetSpecHeatArgs(27.0, 26.5, -999.000000, Material.Phase.Liquid, Material.Phase.Liquid, 25022.797049))
    args_list.append(GetSpecHeatArgs(26.5, 26.0, -999.000000, Material.Phase.Liquid, Material.Phase.Liquid, 25061.968804))
    args_list.append(GetSpecHeatArgs(26.0, 25.5, -999.000000, Material.Phase.Liquid, Material.Phase.Liquid, 25168.448675))
    args_list.append(GetSpecHeatArgs(25.5, 25.0, -999.000000, Material.Phase.Liquid, Material.Phase.Liquid, 25457.890972))
    args_list.append(GetSpecHeatArgs(25.0, 24.5, -999.000000, Material.Phase.Liquid, Material.Phase.Liquid, 26244.676709))
    args_list.append(GetSpecHeatArgs(24.5, 24.0, -999.000000, Material.Phase.Liquid, Material.Phase.Freezing, 28383.382081))
    args_list.append(GetSpecHeatArgs(24.0, 23.5, -999.000000, Material.Phase.Freezing, Material.Phase.Freezing, 34196.986029))
    args_list.append(GetSpecHeatArgs(23.5, 23.0, -999.000000, Material.Phase.Freezing, Material.Phase.Freezing, 40803.013971))
    args_list.append(GetSpecHeatArgs(23.0, 22.5, -999.000000, Material.Phase.Freezing, Material.Phase.Freezing, 29196.986029))
    args_list.append(GetSpecHeatArgs(22.5, 22.0, -999.000000, Material.Phase.Freezing, Material.Phase.Freezing, 23383.382081))
    args_list.append(GetSpecHeatArgs(22.0, 21.5, -999.000000, Material.Phase.Freezing, Material.Phase.Crystallized, 21244.676709))
    args_list.append(GetSpecHeatArgs(21.5, 21.0, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20457.890972))
    args_list.append(GetSpecHeatArgs(21.0, 20.5, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20168.448675))
    args_list.append(GetSpecHeatArgs(20.5, 20.0, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20061.968804))
    args_list.append(GetSpecHeatArgs(20.0, 19.5, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20022.797049))
    args_list.append(GetSpecHeatArgs(19.5, 19.0, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20008.386566))
    args_list.append(GetSpecHeatArgs(19.0, 18.5, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20003.085245))
    args_list.append(GetSpecHeatArgs(18.5, 18.0, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20001.134998))
    args_list.append(GetSpecHeatArgs(18.0, 17.5, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20000.417543))
    args_list.append(GetSpecHeatArgs(17.5, 17.0, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20000.153605))
    args_list.append(GetSpecHeatArgs(17.0, 16.5, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20000.056508))
    args_list.append(GetSpecHeatArgs(16.5, 16.0, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20000.020788))
    args_list.append(GetSpecHeatArgs(16.0, 15.5, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20000.007648))
    args_list.append(GetSpecHeatArgs(15.5, 15.0, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20000.002813))
    args_list.append(GetSpecHeatArgs(15.0, 14.5, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20000.001035))
    for cp_call in args_list:
        var calculated_pcm_state = Material.Phase.Invalid
        var calculated_cp = fixture.ModelA.getCurrentSpecificHeat(
            cp_call.previousTemperature,
            cp_call.updatedTemperature,
            cp_call.temperatureReverse,
            cp_call.previousPhaseChangeState,
            calculated_pcm_state,
        )
        assert_equal(cp_call.expectedUpdatedPhaseChangeState, calculated_pcm_state)
        assert_almost_equal(calculated_cp, cp_call.expectedSpecificHeat, 1.0)
    fixture.TearDown()

@test
def CompletelyThroughMeltingAndBackDown():
    var fixture = HysteresisTest()
    fixture.SetUp()
    var args_list = List[GetSpecHeatArgs]()
    args_list.append(GetSpecHeatArgs(14.0, 14.5, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20000.417543))
    args_list.append(GetSpecHeatArgs(14.5, 15.0, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20001.134998))
    args_list.append(GetSpecHeatArgs(15.0, 15.5, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20003.085245))
    args_list.append(GetSpecHeatArgs(15.5, 16.0, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20008.386566))
    args_list.append(GetSpecHeatArgs(16.0, 16.5, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20022.797049))
    args_list.append(GetSpecHeatArgs(16.5, 17.0, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20061.968804))
    args_list.append(GetSpecHeatArgs(17.0, 17.5, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20168.448675))
    args_list.append(GetSpecHeatArgs(17.5, 18.0, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20457.890972))
    args_list.append(GetSpecHeatArgs(18.0, 18.5, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 21244.676709))
    args_list.append(GetSpecHeatArgs(18.5, 19.0, -999.000000, Material.Phase.Crystallized, Material.Phase.Melting, 23383.382081))
    args_list.append(GetSpecHeatArgs(19.0, 19.5, -999.000000, Material.Phase.Melting, Material.Phase.Melting, 29196.986029))
    args_list.append(GetSpecHeatArgs(19.5, 20.0, -999.000000, Material.Phase.Melting, Material.Phase.Melting, 35803.013971))
    args_list.append(GetSpecHeatArgs(20.0, 20.5, -999.000000, Material.Phase.Melting, Material.Phase.Melting, 34196.986029))
    args_list.append(GetSpecHeatArgs(20.5, 21.0, -999.000000, Material.Phase.Melting, Material.Phase.Melting, 28383.382081))
    args_list.append(GetSpecHeatArgs(21.0, 21.5, -999.000000, Material.Phase.Melting, Material.Phase.Liquid, 26244.676709))
    args_list.append(GetSpecHeatArgs(21.5, 22.0, -999.000000, Material.Phase.Liquid, Material.Phase.Liquid, 25457.890972))
    args_list.append(GetSpecHeatArgs(22.0, 22.5, -999.000000, Material.Phase.Liquid, Material.Phase.Liquid, 25168.448675))
    args_list.append(GetSpecHeatArgs(22.5, 23.0, -999.000000, Material.Phase.Liquid, Material.Phase.Liquid, 25061.968804))
    args_list.append(GetSpecHeatArgs(23.0, 23.5, -999.000000, Material.Phase.Liquid, Material.Phase.Liquid, 25022.797049))
    args_list.append(GetSpecHeatArgs(23.5, 24.0, -999.000000, Material.Phase.Liquid, Material.Phase.Liquid, 25008.386566))
    args_list.append(GetSpecHeatArgs(24.0, 24.5, -999.000000, Material.Phase.Liquid, Material.Phase.Liquid, 25003.085245))
    args_list.append(GetSpecHeatArgs(24.5, 25.0, -999.000000, Material.Phase.Liquid, Material.Phase.Liquid, 25001.134998))
    args_list.append(GetSpecHeatArgs(25.0, 25.5, -999.000000, Material.Phase.Liquid, Material.Phase.Liquid, 25000.417543))
    args_list.append(GetSpecHeatArgs(25.5, 26.0, -999.000000, Material.Phase.Liquid, Material.Phase.Liquid, 25000.153605))
    args_list.append(GetSpecHeatArgs(26.0, 26.5, -999.000000, Material.Phase.Liquid, Material.Phase.Liquid, 25000.056508))
    args_list.append(GetSpecHeatArgs(26.5, 27.0, -999.000000, Material.Phase.Liquid, Material.Phase.Liquid, 25000.020788))
    args_list.append(GetSpecHeatArgs(27.0, 27.5, -999.000000, Material.Phase.Liquid, Material.Phase.Liquid, 25000.007648))
    args_list.append(GetSpecHeatArgs(27.5, 28.0, -999.000000, Material.Phase.Liquid, Material.Phase.Liquid, 25000.002813))
    args_list.append(GetSpecHeatArgs(28.0, 28.5, -999.000000, Material.Phase.Liquid, Material.Phase.Liquid, 25000.001035))
    args_list.append(GetSpecHeatArgs(28.5, 29.0, -999.000000, Material.Phase.Liquid, Material.Phase.Liquid, 25000.000381))
    args_list.append(GetSpecHeatArgs(29.0, 29.5, -999.000000, Material.Phase.Liquid, Material.Phase.Liquid, 25000.000140))
    args_list.append(GetSpecHeatArgs(29.5, 30.0, -999.000000, Material.Phase.Liquid, Material.Phase.Liquid, 25000.000052))
    args_list.append(GetSpecHeatArgs(30.0, 30.5, -999.000000, Material.Phase.Liquid, Material.Phase.Liquid, 25000.000019))
    args_list.append(GetSpecHeatArgs(30.5, 30.0, -999.000000, Material.Phase.Liquid, Material.Phase.Liquid, 25000.020788))
    args_list.append(GetSpecHeatArgs(30.0, 29.5, -999.000000, Material.Phase.Liquid, Material.Phase.Liquid, 25000.056508))
    args_list.append(GetSpecHeatArgs(29.5, 29.0, -999.000000, Material.Phase.Liquid, Material.Phase.Liquid, 25000.153605))
    args_list.append(GetSpecHeatArgs(29.0, 28.5, -999.000000, Material.Phase.Liquid, Material.Phase.Liquid, 25000.417543))
    args_list.append(GetSpecHeatArgs(28.5, 28.0, -999.000000, Material.Phase.Liquid, Material.Phase.Liquid, 25001.134998))
    args_list.append(GetSpecHeatArgs(28.0, 27.5, -999.000000, Material.Phase.Liquid, Material.Phase.Liquid, 25003.085245))
    args_list.append(GetSpecHeatArgs(27.5, 27.0, -999.000000, Material.Phase.Liquid, Material.Phase.Liquid, 25008.386566))
    args_list.append(GetSpecHeatArgs(27.0, 26.5, -999.000000, Material.Phase.Liquid, Material.Phase.Liquid, 25022.797049))
    args_list.append(GetSpecHeatArgs(26.5, 26.0, -999.000000, Material.Phase.Liquid, Material.Phase.Liquid, 25061.968804))
    args_list.append(GetSpecHeatArgs(26.0, 25.5, -999.000000, Material.Phase.Liquid, Material.Phase.Liquid, 25168.448675))
    args_list.append(GetSpecHeatArgs(25.5, 25.0, -999.000000, Material.Phase.Liquid, Material.Phase.Liquid, 25457.890972))
    args_list.append(GetSpecHeatArgs(25.0, 24.5, -999.000000, Material.Phase.Liquid, Material.Phase.Liquid, 26244.676709))
    args_list.append(GetSpecHeatArgs(24.5, 24.0, -999.000000, Material.Phase.Liquid, Material.Phase.Freezing, 28383.382081))
    args_list.append(GetSpecHeatArgs(24.0, 23.5, -999.000000, Material.Phase.Freezing, Material.Phase.Freezing, 34196.986029))
    args_list.append(GetSpecHeatArgs(23.5, 23.0, -999.000000, Material.Phase.Freezing, Material.Phase.Freezing, 40803.013971))
    args_list.append(GetSpecHeatArgs(23.0, 22.5, -999.000000, Material.Phase.Freezing, Material.Phase.Freezing, 29196.986029))
    args_list.append(GetSpecHeatArgs(22.5, 22.0, -999.000000, Material.Phase.Freezing, Material.Phase.Freezing, 23383.382081))
    args_list.append(GetSpecHeatArgs(22.0, 21.5, -999.000000, Material.Phase.Freezing, Material.Phase.Crystallized, 21244.676709))
    args_list.append(GetSpecHeatArgs(21.5, 21.0, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20457.890972))
    args_list.append(GetSpecHeatArgs(21.0, 20.5, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20168.448675))
    args_list.append(GetSpecHeatArgs(20.5, 20.0, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20061.968804))
    args_list.append(GetSpecHeatArgs(20.0, 19.5, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20022.797049))
    args_list.append(GetSpecHeatArgs(19.5, 19.0, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20008.386566))
    args_list.append(GetSpecHeatArgs(19.0, 18.5, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20003.085245))
    args_list.append(GetSpecHeatArgs(18.5, 18.0, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20001.134998))
    args_list.append(GetSpecHeatArgs(18.0, 17.5, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20000.417543))
    args_list.append(GetSpecHeatArgs(17.5, 17.0, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20000.153605))
    args_list.append(GetSpecHeatArgs(17.0, 16.5, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20000.056508))
    args_list.append(GetSpecHeatArgs(16.5, 16.0, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20000.020788))
    args_list.append(GetSpecHeatArgs(16.0, 15.5, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20000.007648))
    args_list.append(GetSpecHeatArgs(15.5, 15.0, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20000.002813))
    args_list.append(GetSpecHeatArgs(15.0, 14.5, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20000.001035))
    args_list.append(GetSpecHeatArgs(14.5, 14.0, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20000.000381))
    args_list.append(GetSpecHeatArgs(14.0, 13.5, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20000.000140))
    for cp_call in args_list:
        var calculated_pcm_state = Material.Phase.Invalid
        var calculated_cp = fixture.ModelA.getCurrentSpecificHeat(
            cp_call.previousTemperature,
            cp_call.updatedTemperature,
            cp_call.temperatureReverse,
            cp_call.previousPhaseChangeState,
            calculated_pcm_state,
        )
        assert_equal(cp_call.expectedUpdatedPhaseChangeState, calculated_pcm_state)
        assert_almost_equal(calculated_cp, cp_call.expectedSpecificHeat, 1.0)
    fixture.TearDown()

@test
def IntoMeltingAndBackDown():
    var fixture = HysteresisTest()
    fixture.SetUp()
    var args_list = List[GetSpecHeatArgs]()
    args_list.append(GetSpecHeatArgs(14.0, 14.5, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20000.417543))
    args_list.append(GetSpecHeatArgs(14.5, 15.0, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20001.134998))
    args_list.append(GetSpecHeatArgs(15.0, 15.5, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20003.085245))
    args_list.append(GetSpecHeatArgs(15.5, 16.0, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20008.386566))
    args_list.append(GetSpecHeatArgs(16.0, 16.5, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20022.797049))
    args_list.append(GetSpecHeatArgs(16.5, 17.0, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20061.968804))
    args_list.append(GetSpecHeatArgs(17.0, 17.5, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20168.448675))
    args_list.append(GetSpecHeatArgs(17.5, 18.0, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20457.890972))
    args_list.append(GetSpecHeatArgs(18.0, 18.5, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 21244.676709))
    args_list.append(GetSpecHeatArgs(18.5, 19.0, -999.000000, Material.Phase.Crystallized, Material.Phase.Melting, 23383.382081))
    args_list.append(GetSpecHeatArgs(19.0, 19.5, -999.000000, Material.Phase.Melting, Material.Phase.Melting, 29196.986029))
    args_list.append(GetSpecHeatArgs(19.5, 20.0, -999.000000, Material.Phase.Melting, Material.Phase.Melting, 35803.013971))
    args_list.append(GetSpecHeatArgs(20.0, 20.5, -999.000000, Material.Phase.Melting, Material.Phase.Melting, 34196.986029))
    args_list.append(GetSpecHeatArgs(20.5, 20.0, -999.000000, Material.Phase.Melting, Material.Phase.Crystallized, 20061.968804))
    args_list.append(GetSpecHeatArgs(20.0, 19.5, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20022.797049))
    args_list.append(GetSpecHeatArgs(19.5, 19.0, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20008.386566))
    args_list.append(GetSpecHeatArgs(19.0, 18.5, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20003.085245))
    args_list.append(GetSpecHeatArgs(18.5, 18.0, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20001.134998))
    args_list.append(GetSpecHeatArgs(18.0, 17.5, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20000.417543))
    args_list.append(GetSpecHeatArgs(17.5, 17.0, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20000.153605))
    args_list.append(GetSpecHeatArgs(17.0, 16.5, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20000.056508))
    args_list.append(GetSpecHeatArgs(16.5, 16.0, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20000.020788))
    args_list.append(GetSpecHeatArgs(16.0, 15.5, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20000.007648))
    args_list.append(GetSpecHeatArgs(15.5, 15.0, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20000.002813))
    args_list.append(GetSpecHeatArgs(15.0, 14.5, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20000.001035))
    args_list.append(GetSpecHeatArgs(14.5, 14.0, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20000.000381))
    args_list.append(GetSpecHeatArgs(14.0, 13.5, -999.000000, Material.Phase.Crystallized, Material.Phase.Crystallized, 20000.000140))
    for cp_call in args_list:
        var calculated_pcm_state = Material.Phase.Invalid
        var calculated_cp = fixture.ModelA.getCurrentSpecificHeat(
            cp_call.previousTemperature,
            cp_call.updatedTemperature,
            cp_call.temperatureReverse,
            cp_call.previousPhaseChangeState,
            calculated_pcm_state,
        )
        assert_equal(cp_call.expectedUpdatedPhaseChangeState, calculated_pcm_state)
        assert_almost_equal(calculated_cp, cp_call.expectedSpecificHeat, 1.0)
    fixture.TearDown()

@test
def TestVariableConductivity():
    var fixture = HysteresisTest()
    fixture.SetUp()
    assert_almost_equal(fixture.ModelA.getConductivity(19.0), 1.0, 0.01)
    assert_almost_equal(fixture.ModelA.getConductivity(21.5), 1.5, 0.01)
    assert_almost_equal(fixture.ModelA.getConductivity(24.0), 2.0, 0.01)
    fixture.TearDown()

@test
def TestVariableDensity():
    var fixture = HysteresisTest()
    fixture.SetUp()
    assert_almost_equal(fixture.ModelA.getDensity(19.0), 3.0, 0.01)
    assert_almost_equal(fixture.ModelA.getDensity(21.5), 3.5, 0.01)
    assert_almost_equal(fixture.ModelA.getDensity(24.0), 4.0, 0.01)
    fixture.TearDown()