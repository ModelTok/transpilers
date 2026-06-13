from ...Fixtures.EnergyPlusFixture import EnergyPlusFixture, delimited_string, process_idf, compare_err_stream
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataSystemVariables import *
from EnergyPlus.GroundHeatExchangers.State import GetGroundHeatExchangerInput, GetResponseFactor
from gtest import *  # Placeholder for gtest-like macros; use asserts instead

def GroundHeatExchangerTest_GetResponseFactor():
    var idf_objects: String = delimited_string(
        List[String](
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
            "GroundHeatExchanger:ResponseFactors,",
            "GHE-1 Response Factors,      !- Name",
            "GHE-1 Props,                 !- GHE:Vertical:Properties Object Name",
            "120,                         !- Number of Boreholes",
            "0.0005,                      !- G-Function Reference Ratio {dimensionless}",
            "-15.2996,                    !- g-Function Ln(T/Ts) Value 1",
            "-0.348322,                   !- g-Function g Value 1",
            "-14.201,                     !- g-Function Ln(T/Ts) Value 2",
            "0.022208,                    !- g-Function g Value 2",
            "-13.2202,                    !- g-Function Ln(T/Ts) Value 3",
            "0.412345;                    !- g-Function g Value 3",
        )
    )
    assert process_idf(idf_objects), "ASSERT_TRUE: process_idf"
    state[].init_state(state[])
    GetGroundHeatExchangerInput(state[])
    alias goodObjName: StringLiteral = "GHE-1 RESPONSE FACTORS"
    var foundObject = GetResponseFactor(state[], String(goodObjName))
    assert foundObject.name == goodObjName, "ASSERT_EQ: name"
    try:
        GetResponseFactor(state[], "BAD NAME")
        assert False, "Expected runtime_error not thrown"
    except e:
        assert isinstance(e, RuntimeError), "ASSERT_THROW: runtime_error"
    var errorString: String = delimited_string(
        List[String](
            "   ** Severe  ** Object=GroundHeatExchanger:ResponseFactors, Name=BAD NAME - not found.",
            "   **  Fatal  ** Preceding errors cause program termination",
            "   ...Summary of Errors that led to program termination:",
            "   ..... Reference severe error count=1",
            "   ..... Last severe error=Object=GroundHeatExchanger:ResponseFactors, Name=BAD NAME - not found.",
        )
    )
    assert compare_err_stream(errorString, True), "EXPECT_TRUE: compare_err_stream"