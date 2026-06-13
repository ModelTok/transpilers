from gtest import Test, TestFixture, EXPECT_TRUE, EXPECT_FALSE, EXPECT_NEAR, ASSERT_TRUE
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.FluidProperties import Fluid
from math import *
from .Fixtures.EnergyPlusFixture import EnergyPlusFixture, delimited_string, process_idf, has_err_output, compare_err_stream_substring
from Array1D import Array1D
from Array2D import Array2D

@fixture
class EnergyPlusFixture:

@TestFixture
class FluidProperties_GetDensityGlycol(EnergyPlusFixture):
    def TestBody(self):
        var idf_objects: String = delimited_string([
            "FluidProperties:GlycolConcentration,",
            "  GLHXFluid,       !- Name",
            "  PropyleneGlycol, !- Glycol Type",
            "  ,                !- User Defined Glycol Name",
            "  0.3;             !- Glycol Concentration",
            " "
        ])
        ASSERT_TRUE(process_idf(idf_objects))
        EXPECT_FALSE(has_err_output())
        state.init_state(state)
        var fluid = Fluid.GetGlycol(state, "GLHXFLUID")
        EXPECT_NEAR(1037.89, fluid.getDensity(state, -35.0, "UnitTest"), 0.01)
        EXPECT_NEAR(1037.89, fluid.getDensity(state, -15.0, "UnitTest"), 0.01)
        EXPECT_NEAR(1034.46, fluid.getDensity(state, 5.0, "UnitTest"), 0.01)
        EXPECT_NEAR(1030.51, fluid.getDensity(state, 15.0, "UnitTest"), 0.01)
        EXPECT_NEAR(1026.06, fluid.getDensity(state, 25.0, "UnitTest"), 0.01)
        EXPECT_NEAR(1021.09, fluid.getDensity(state, 35.0, "UnitTest"), 0.01)
        EXPECT_NEAR(1015.62, fluid.getDensity(state, 45.0, "UnitTest"), 0.01)
        EXPECT_NEAR(1003.13, fluid.getDensity(state, 65.0, "UnitTest"), 0.01)
        EXPECT_NEAR(988.60, fluid.getDensity(state, 85.0, "UnitTest"), 0.01)
        EXPECT_NEAR(972.03, fluid.getDensity(state, 105.0, "UnitTest"), 0.01)
        EXPECT_NEAR(953.41, fluid.getDensity(state, 125.0, "UnitTest"), 0.01)

@TestFixture
class FluidProperties_GetSpecificHeatGlycol(EnergyPlusFixture):
    def TestBody(self):
        var idf_objects: String = delimited_string([
            "FluidProperties:GlycolConcentration,",
            "  GLHXFluid,       !- Name",
            "  PropyleneGlycol, !- Glycol Type",
            "  ,                !- User Defined Glycol Name",
            "  0.3;             !- Glycol Concentration",
            " "
        ])
        ASSERT_TRUE(process_idf(idf_objects))
        EXPECT_FALSE(has_err_output())
        state.init_state(state)
        var fluid = Fluid.GetGlycol(state, "GLHXFLUID")
        EXPECT_NEAR(3779, fluid.getSpecificHeat(state, -35.0, "UnitTest"), 0.01)
        EXPECT_NEAR(3779, fluid.getSpecificHeat(state, -15.0, "UnitTest"), 0.01)
        EXPECT_NEAR(3807, fluid.getSpecificHeat(state, 5.0, "UnitTest"), 0.01)
        EXPECT_NEAR(3834, fluid.getSpecificHeat(state, 15.0, "UnitTest"), 0.01)
        EXPECT_NEAR(3862, fluid.getSpecificHeat(state, 25.0, "UnitTest"), 0.01)
        EXPECT_NEAR(3889, fluid.getSpecificHeat(state, 35.0, "UnitTest"), 0.01)
        EXPECT_NEAR(3917, fluid.getSpecificHeat(state, 45.0, "UnitTest"), 0.01)
        EXPECT_NEAR(3972, fluid.getSpecificHeat(state, 65.0, "UnitTest"), 0.01)
        EXPECT_NEAR(4027, fluid.getSpecificHeat(state, 85.0, "UnitTest"), 0.01)
        EXPECT_NEAR(4082, fluid.getSpecificHeat(state, 105.0, "UnitTest"), 0.01)
        EXPECT_NEAR(4137, fluid.getSpecificHeat(state, 125.0, "UnitTest"), 0.01)

@TestFixture
class FluidProperties_GetViscosityGlycolOutOfRangeWarnings(EnergyPlusFixture):
    def TestBody(self):
        var idf_objects: String = delimited_string([
            "FluidProperties:GlycolConcentration,",
            "  GLHXFluid,       !- Name",
            "  PropyleneGlycol, !- Glycol Type",
            "  ,                !- User Defined Glycol Name",
            "  0.3;             !- Glycol Concentration",
            " "
        ])
        ASSERT_TRUE(process_idf(idf_objects))
        EXPECT_FALSE(has_err_output())
        state.init_state(state)
        var fluid = Fluid.GetGlycol(state, "GLHXFLUID")
        fluid.getViscosity(state, -100.0, "UnitTest")
        EXPECT_TRUE(compare_err_stream_substring("Temperature is out of range (too low) for fluid [GLHXFLUID] viscosity **", True))
        fluid.getViscosity(state, 200.0, "UnitTest")
        EXPECT_TRUE(compare_err_stream_substring("Temperature is out of range (too high) for fluid [GLHXFLUID] viscosity **", True))

@TestFixture
class FluidProperties_InterpValuesForGlycolConc(EnergyPlusFixture):
    def TestBody(self):
        var NumCon: Int = 1
        var NumTemp: Int = 5
        var ConData = Array1D[Float64](1)
        ConData[0] = 1.0
        var PropData = Array2D[Float64]()
        PropData.allocate(NumCon, NumTemp)
        for i in range(1, NumCon + 1):
            for j in range(1, NumTemp + 1):
                PropData[i - 1, j - 1] = 1030.0 - 10.0 * j
        var ActCon: Float64 = 1.0
        var Result = Array1D[Float64]()
        Result.allocate(NumTemp)
        Fluid.InterpValuesForGlycolConc(state,
                                        NumCon,
                                        NumTemp,
                                        ConData,
                                        PropData,
                                        ActCon,
                                        Result)
        EXPECT_NEAR(1020.0, Result[0], 1e-6)
        EXPECT_NEAR(1010.0, Result[1], 1e-6)
        EXPECT_NEAR(1000.0, Result[2], 1e-6)
        EXPECT_NEAR(990.0, Result[3], 1e-6)
        EXPECT_NEAR(980.0, Result[4], 1e-6)