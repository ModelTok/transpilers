from testing import assert_equal, assert_approx_equal, assert_true
from ......EnergyPlus.Construction import *
from ......EnergyPlus.Data.EnergyPlusData import *
from ......EnergyPlus.DataHeatBalance import *
from ......EnergyPlus.HeatBalanceManager import *
from ......tst.EnergyPlus.Fixtures.EnergyPlusFixture import *

def test_ConstructionInternalSource():
    let idf_objects: String = delimited_string(
        "	ConstructionProperty:InternalHeatSource,	",
        "	Radiant Source,          !- Name",
        "	Slab Floor with Radiant, !- Construction Name",
        "	4,                       !- Source Present After Layer Number",
        "	4,                       !- Temperature Calculation Requested After Layer Number",
        "	2,                       !- Dimensions for the CTF Calculation",
        "	0.3048,                  !- Tube Spacing {m}",
        "	0.0;                     !- Two-Dimensional Position of Interior Temperature Calculation Request",
        "	Construction,	",
        "	Slab Floor with Radiant, !- Name",
        "	CONCRETE - DRIED SAND AND GRAVEL 4 IN,  !- Outside Layer",
        "	INS - EXPANDED EXT POLYSTYRENE R12 2 IN,  !- Layer 2",
        "	GYP1,                    !- Layer 3",
        "	GYP2,                    !- Layer 4",
        "	FINISH FLOORING - TILE 1 / 16 IN;  !- Layer 5",
    )
    assert_true(process_idf(state, idf_objects))
    var errorsFound: Bool = False
    GetConstructData(state, errorsFound)
    assert_approx_equal(0.1524, state.dataConstruction.Construct[1].ThicknessPerpend, 0.0001)

def test_ConstructionInternalSourceEmptyField():
    let idf_objects: String = delimited_string(
        "	ConstructionProperty:InternalHeatSource,	",
        "	Radiant Source,          !- Name",
        "	Slab Floor with Radiant, !- Construction Name",
        "	4,                       !- Source Present After Layer Number",
        "	4,                       !- Temperature Calculation Requested After Layer Number",
        "	2,                       !- Dimensions for the CTF Calculation",
        "	0.3048,                  !- Tube Spacing {m}",
        "	;                        !- Two-Dimensional Temperature Calculation Position",
        "	Construction,	",
        "	Slab Floor with Radiant, !- Name",
        "	CONCRETE - DRIED SAND AND GRAVEL 4 IN,  !- Outside Layer",
        "	INS - EXPANDED EXT POLYSTYRENE R12 2 IN,  !- Layer 2",
        "	GYP1,                    !- Layer 3",
        "	GYP2,                    !- Layer 4",
        "	FINISH FLOORING - TILE 1 / 16 IN;  !- Layer 5",
        "	ConstructionProperty:InternalHeatSource,	",
        "	Radiant Source 2,          !- Name",
        "	Slab Floor with Radiant 2, !- Construction Name",
        "	4,                       !- Source Present After Layer Number",
        "	4,                       !- Temperature Calculation Requested After Layer Number",
        "	2,                       !- Dimensions for the CTF Calculation",
        "	0.3048,                  !- Tube Spacing {m}",
        "	0.2;                     !- Two-Dimensional Temperature Calculation Position",
        "	Construction,	",
        "	Slab Floor with Radiant 2, !- Name",
        "	CONCRETE - DRIED SAND AND GRAVEL 4 IN,  !- Outside Layer",
        "	INS - EXPANDED EXT POLYSTYRENE R12 2 IN,  !- Layer 2",
        "	GYP1,                    !- Layer 3",
        "	GYP2,                    !- Layer 4",
        "	FINISH FLOORING - TILE 1 / 16 IN;  !- Layer 5",
    )
    assert_true(process_idf(state, idf_objects))
    var errorsFound: Bool = False
    GetConstructData(state, errorsFound)
    assert_equal(state.dataConstruction.Construct[1].userTemperatureLocationPerpendicular, 0.0)
    assert_equal(state.dataConstruction.Construct[2].userTemperatureLocationPerpendicular, 0.2)