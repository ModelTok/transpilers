from ......Fixtures.EnergyPlusFixture import EnergyPlusFixture, process_idf, init_state
from ...Data.EnergyPlusData import EnergyPlusData, GeneratorType
from ...DataEnvironment import DataEnvironment
from ...WindTurbine import SimWindTurbine, GetWindTurbineInput


def delimited_string(arr: List[String]) -> String:
    return "\n".join(arr)


def WindTurbineTest() raises:
    var idf_objects = delimited_string(
        List[String](
            "Generator:WindTurbine,",
            "    WT1,                     !- Name",
            "    ,               !- Availability Schedule Name",
            "    HorizontalAxisWindTurbine,  !- Rotor Type",
            "    FixedSpeedVariablePitch, !- Power Control",
            "    41,                      !- Rated Rotor Speed {rev/min}",
            "    19.2,                    !- Rotor Diameter {m}",
            "    30.5,                    !- Overall Height {m}",
            "    3,                       !- Number of Blades",
            "    55000,                   !- Rated Power {W}",
            "    11,                      !- Rated Wind Speed {m/s}",
            "    3.5,                     !- Cut In Wind Speed {m/s}",
            "    25,                      !- Cut Out Wind Speed {m/s}",
            "    0.835,                   !- Fraction system Efficiency",
            "    8,                       !- Maximum Tip Speed Ratio",
            "    0.5,                     !- Maximum Power Coefficient",
            "    6.4,                     !- Annual Local Average Wind Speed {m/s}",
            "    50,                      !- Height for Local Average Wind Speed {m}",
            "    ,                        !- Blade Chord Area {m2}",
            "    ,                        !- Blade Drag Coefficient",
            "    ,                        !- Blade Lift Coefficient",
            "    0.5176,                  !- Power Coefficient C1",
            "    116,                     !- Power Coefficient C2",
            "    0.4,                     !- Power Coefficient C3",
            "    0,                       !- Power Coefficient C4",
            "    5,                       !- Power Coefficient C5",
            "    21;                      !- Power Coefficient C6",
        )
    )
    assert process_idf(idf_objects)
    state.init_state(state)
    GetWindTurbineInput(state)
    var index = 0
    SimWindTurbine(state, GeneratorType.WindTurbine, "WT1", index, False, 0.0)
    var thisTurbine = state.dataWindTurbine.WindTurbineSys[0]
    assert thisTurbine.Name == "WT1"
    assert thisTurbine.Power == 0
    state.dataEnvrn.WindSpeed = 10
    SimWindTurbine(state, GeneratorType.WindTurbine, "WT1", index, False, 0.0)
    assert thisTurbine.Power > 0