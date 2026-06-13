from tst.EnergyPlus.unit.Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.DataSystemVariables import *
from EnergyPlus.GroundHeatExchangers.Base import *
from EnergyPlus.GroundHeatExchangers.BoreholeArray import *
from testing import *

def GroundHeatExchangerTest_GetVertArray():
    let idf_objects: String = delimited_string(
        "GroundHeatExchanger:Vertical:Properties,",
        "    GHE-1 Props,        !- Name",
        "    1,                  !- Depth of Top of Borehole {m}",
        "    76.2,               !- Borehole Length {m}",
        "    0.288,              !- Borehole Diameter {m}",
        "    3.0,                !- Grout Thermal Conductivity {W/m-K}",
        "    1.0E+06,            !- Grout Thermal Heat Capacity {J/m3-K}",
        "    0.389,              !- Pipe Thermal Conductivity {W/m-K}",
        "    8E+05,              !- Pipe Thermal Heat Capacity {J/m3-K}",
        "    0.032,              !- Pipe Outer Diameter {m}",
        "    0.0016279,          !- Pipe Thickness {m}",
        "    0.1066667;          !- U-Tube Distance {m}",
        "GroundHeatExchanger:Vertical:Array,",
        "    GHE-Array,          !- Name",
        "    GHE-1 Props,        !- GHE Properties",
        "    2,                  !- Number of Boreholes in X Direction",
        "    2,                  !- Number of Boreholes in Y Direction",
        "    2;                  !- Borehole Spacing {m}",
        "GroundHeatExchanger:System,",
        "    Vertical GHE 1x4 Std,  !- Name",
        "    GHLE Inlet,         !- Inlet Node Name",
        "    GHLE Outlet,        !- Outlet Node Name",
        "    0.1,                !- Design Flow Rate {m3/s}",
        "    Site:GroundTemperature:Undisturbed:KusudaAchenbach,  !- Undisturbed Ground Temperature Model Type",
        "    KATemps,            !- Undisturbed Ground Temperature Model Name",
        "    1.0,                !- Ground Thermal Conductivity {W/m-K}",
        "    2.4957E+06,         !- Ground Thermal Heat Capacity {J/m3-K}",
        "    ,                   !- Response Factors Object Name",
        "    UHFCalc,            !- g-Function Calculation Method",
        "    ,                   !- GHE Vertical Sizing Object Type",
        "    ,                   !- GHE Vertical Sizing Object Name",
        "    GHE-Array;          !- GHE Array Object Name",
        "Site:GroundTemperature:Undisturbed:KusudaAchenbach,",
        "    KATemps,                 !- Name",
        "    1.8,                     !- Soil Thermal Conductivity {W/m-K}",
        "    920,                     !- Soil Density {kg/m3}",
        "    2200,                    !- Soil Specific Heat {J/kg-K}",
        "    15.5,                    !- Average Soil Surface Temperature {C}",
        "    3.2,                     !- Average Amplitude of Surface Temperature {deltaC}",
        "    8;                       !- Phase Shift of Minimum Surface Temperature {days}",
    )
    assert_true(process_idf(idf_objects))
    state.init_state(state)
    GetGroundHeatExchangerInput(state)
    let goodObjName: StringLiteral = "GHE-ARRAY"
    var foundObject = GLHEVertArray.GetVertArray(state, String(goodObjName))
    assert_equal(foundObject.name, goodObjName)
    assert_raises(lambda: GLHEVertArray.GetVertArray(state, "BAD NAME"), RuntimeError)
    let errorString: String = delimited_string(
        "   ** Severe  ** Object=GroundHeatExchanger:Vertical:Array, Name=BAD NAME - not found.",
        "   **  Fatal  ** Preceding errors cause program termination",
        "   ...Summary of Errors that led to program termination:",
        "   ..... Reference severe error count=1",
        "   ..... Last severe error=Object=GroundHeatExchanger:Vertical:Array, Name=BAD NAME - not found.",
    )
    assert_true(compare_err_stream(errorString, True))