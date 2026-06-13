from Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.CoolTower import ManageCoolTower
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataEnvironment import DataEnvironment
from EnergyPlus.DataHeatBalFanSys import DataHeatBalFanSys
from EnergyPlus.DataHeatBalance import DataHeatBalance
from EnergyPlus.Psychrometrics import PsyWFnTdbTwbPb, PsyRhoAirFnPbTdbW
from EnergyPlus.ZoneTempPredictorCorrector import ZoneTempPredictorCorrector

def test_ExerciseCoolTower():
    var idf_objects: String = delimited_string(
        [
            "ScheduleTypeLimits, Any Number;",
            "Schedule:Compact, Cooltower Operation, Any Number, Through: 12/31, For: AllDays, Until: 24:00, 1.0;",
            "ZoneCoolTower:Shower,",
            "    CoolTower 1,             !- Name",
            "    ,     !- Availability Schedule Name",
            "    Zone 1,                  !- Zone Name",
            "    ,                        !- Water Supply Storage Tank Name",
            "    WindDrivenFlow,          !- Flow Control Type",
            "    Cooltower Operation,     !- Pump Flow Rate Schedule Name",
            "    0.0005,                  !- Maximum Water Flow Rate {m3/s}",
            "    5.0,                     !- Effective Tower Height {m}",
            "    0.5,                     !- Airflow Outlet Area {m2}",
            "    10.0,                    !- Maximum Air Flow Rate {m3/s}",
            "    18.0,                    !- Minimum Indoor Temperature {C}",
            "    0.05,                    !- Fraction of Water Loss",
            "    0.05,                    !- Fraction of Flow Schedule",
            "    200.0;                   !- Rated Power Consumption {W}",
        ]
    )
    assert_true(process_idf(idf_objects, false))
    state.init_state(state)
    state.dataHeatBal.Zone.allocate(1)
    state.dataHeatBal.Zone[0].Name = "ZONE 1"
    state.dataZoneTempPredictorCorrector.zoneHeatBalance.allocate(1)
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].MAT = 20.0
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].ZT = 1.0
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].MCPC = 1
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].MCPTC = 1
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].CTMFL = 1
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].airHumRat = 1
    state.dataEnvrn.OutDryBulbTemp = 35.0
    state.dataEnvrn.OutWetBulbTemp = 26.0
    state.dataEnvrn.OutBaroPress = 101325.0
    state.dataEnvrn.OutHumRat = PsyWFnTdbTwbPb(
        state, state.dataEnvrn.OutDryBulbTemp, state.dataEnvrn.OutWetBulbTemp, state.dataEnvrn.OutBaroPress
    )
    state.dataEnvrn.StdRhoAir = PsyRhoAirFnPbTdbW(
        state, state.dataEnvrn.OutBaroPress, state.dataEnvrn.OutDryBulbTemp, state.dataEnvrn.OutHumRat
    )
    state.dataEnvrn.WindSpeed = 20.0
    ManageCoolTower(state)