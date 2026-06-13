from testing import assert_equal, test
from .Fixtures.EnergyPlusFixture import EnergyPlusFixture
from CurveManager import AddCurve, CurveType
from DataHeatBalFanSys import SetptType
from EnergyPlus.DataHeatBalance import Zone
from EnergyPlus.DataHeatBalFanSys import ZoneHeatBalanceFanSys  # assumed type for zoneHBBal? Actually we need zoneHeatBalance type
from EnergyPlus.DataZoneTempPredictorCorrector import ZoneHeatBalance  # from DataZoneTempPredictorCorrector
from EnergyPlus.DataHeatBalance import ZoneIntGain  # from DataHeatBalance

@test
def AirflowNetwork_AdvancedTest_Test1():
    var fixture = EnergyPlusFixture()
    var state = fixture.state

    var AirflowNetworkNumOfOccuVentCtrls: Int
    var TimeOpenElapsed: Float64
    var TimeCloseElapsed: Float64
    var OpenStatus: Int
    var OpenProbStatus: Int
    var CloseProbStatus: Int
    AirflowNetworkNumOfOccuVentCtrls = 1
    state.afn.OccupantVentilationControl = List[OccupantVentilationControl](AirflowNetworkNumOfOccuVentCtrls)
    state.afn.OccupantVentilationControl[0].MinOpeningTime = 4
    state.afn.OccupantVentilationControl[0].MinClosingTime = 4
    state.afn.OccupantVentilationControl[0].MinTimeControlOnly = true
    TimeOpenElapsed = 3.0
    TimeCloseElapsed = 0.0
    state.afn.OccupantVentilationControl[0].calc(state, 1, TimeOpenElapsed, TimeCloseElapsed, OpenStatus, OpenProbStatus, CloseProbStatus)
    assert_equal(1, OpenStatus)
    TimeOpenElapsed = 5.0
    state.afn.OccupantVentilationControl[0].calc(state, 1, TimeOpenElapsed, TimeCloseElapsed, OpenStatus, OpenProbStatus, CloseProbStatus)
    assert_equal(0, OpenStatus)
    TimeOpenElapsed = 0.0
    TimeCloseElapsed = 3.0
    state.afn.OccupantVentilationControl[0].calc(state, 1, TimeOpenElapsed, TimeCloseElapsed, OpenStatus, OpenProbStatus, CloseProbStatus)
    assert_equal(2, OpenStatus)
    TimeOpenElapsed = 0.0
    TimeCloseElapsed = 5.0
    state.afn.OccupantVentilationControl[0].calc(state, 1, TimeOpenElapsed, TimeCloseElapsed, OpenStatus, OpenProbStatus, CloseProbStatus)
    assert_equal(0, OpenStatus)
    state.dataEnvrn.OutDryBulbTemp = 15.0
    state.dataHeatBal.Zone = [Zone()]
    state.dataZoneTempPredictorCorrector.zoneHeatBalance = [ZoneHeatBalance()]
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].MAT = 22.0
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].MRT = 22.0
    state.dataHeatBalFanSys.TempControlType = [SetptType](1)  # allocate list of one SetptType
    state.dataHeatBalFanSys.TempControlType[0] = SetptType.Uncontrolled
    state.dataHeatBalFanSys.zoneTstatSetpts = [ZoneTstatSetpts]()  # assuming type, allocate one element later? The original uses allocate(1) then assigns setptLo/Hi
    # Actually original: state->dataHeatBalFanSys->zoneTstatSetpts.allocate(1); later assigns. We'll allocate here:
    state.dataHeatBalFanSys.zoneTstatSetpts = [ZoneTstatSetpts()]
    TimeOpenElapsed = 5.0
    TimeCloseElapsed = 0.0
    state.afn.OccupantVentilationControl[0].MinTimeControlOnly = false
    state.afn.OccupantVentilationControl[0].ComfortBouPoint = 10.0
    state.afn.OccupantVentilationControl[0].ComfortLowTempCurveNum = 1
    state.afn.OccupantVentilationControl[0].ComfortHighTempCurveNum = 2
    var curve1 = AddCurve(state, "Curve1")
    curve1.curveType = CurveType.Quadratic
    curve1.coeff[0] = 21.2
    curve1.coeff[1] = 0.09
    curve1.coeff[2] = 0.0
    curve1.coeff[3] = 0.0
    curve1.coeff[4] = 0.0
    curve1.coeff[5] = 0.0
    curve1.inputLimits[0].min = -50.0
    curve1.inputLimits[0].max = 10.0
    curve1.inputLimits[1].min = 0.0
    curve1.inputLimits[1].max = 2.0
    var curve2 = AddCurve(state, "Curve2")
    curve2.curveType = CurveType.Quadratic
    curve2.coeff[0] = 18.8
    curve2.coeff[1] = 0.33
    curve2.coeff[2] = 0.0
    curve2.coeff[3] = 0.0
    curve2.coeff[4] = 0.0
    curve2.coeff[5] = 0.0
    curve2.inputLimits[0].min = 10.0
    curve2.inputLimits[0].max = 50.0
    curve2.inputLimits[1].min = 0.0
    curve2.inputLimits[1].max = 2.0
    state.afn.OccupantVentilationControl[0].calc(state, 1, TimeOpenElapsed, TimeCloseElapsed, OpenStatus, OpenProbStatus, CloseProbStatus)
    assert_equal(0, OpenProbStatus)
    assert_equal(1, CloseProbStatus)
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].MAT = 26.0
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].MRT = 26.0
    state.afn.OccupantVentilationControl[0].calc(state, 1, TimeOpenElapsed, TimeCloseElapsed, OpenStatus, OpenProbStatus, CloseProbStatus)
    assert_equal(2, OpenProbStatus)
    assert_equal(0, CloseProbStatus)
    TimeOpenElapsed = 0.0
    TimeCloseElapsed = 5.0
    state.dataHeatBal.ZoneIntGain = [ZoneIntGain()]
    state.dataHeatBal.ZoneIntGain[0].NOFOCC = 0.5
    state.afn.OccupantVentilationControl[0].calc(state, 1, TimeOpenElapsed, TimeCloseElapsed, OpenStatus, OpenProbStatus, CloseProbStatus)
    assert_equal(1, OpenProbStatus)
    assert_equal(0, CloseProbStatus)
    state.dataHeatBalFanSys.TempControlType[0] = SetptType.DualHeatCool
    state.dataHeatBalFanSys.zoneTstatSetpts[0].setptLo = 22.0
    state.dataHeatBalFanSys.zoneTstatSetpts[0].setptHi = 28.0
    state.afn.OccupantVentilationControl[0].calc(state, 1, TimeOpenElapsed, TimeCloseElapsed, OpenStatus, OpenProbStatus, CloseProbStatus)
    assert_equal(1, OpenProbStatus)
    assert_equal(0, CloseProbStatus)