from EnergyPlus.DataGlobalConstants import Constant
from TestHelpers.CustomMatchers import EXPECT_ENUM_EQ, ASSERT_ENUM_EQ, EXPECT_ENUM_NE, ASSERT_ENUM_NE

def enums_ok():
    EXPECT_ENUM_EQ(Constant.eResource.NaturalGas, Constant.eResource.NaturalGas)
    ASSERT_ENUM_EQ(Constant.eResource.NaturalGas, Constant.eResource.NaturalGas)
    EXPECT_ENUM_NE(Constant.eResource.Electricity, Constant.eResource.NaturalGas)
    ASSERT_ENUM_NE(Constant.eResource.Electricity, Constant.eResource.NaturalGas)