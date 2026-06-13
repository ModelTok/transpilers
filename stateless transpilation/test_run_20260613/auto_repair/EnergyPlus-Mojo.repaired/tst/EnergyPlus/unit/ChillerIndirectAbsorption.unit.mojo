from gtest import Test, TestFixture, EXPECT_EQ, ASSERT_TRUE
from EnergyPlus.ChillerIndirectAbsorption import GetIndirectAbsorberInput
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.Data.ChillerIndirectAbsorption import IndirectAbsorberData
from EnergyPlus.Data.GlobalConstants import DoWeathSim

using EnergyPlus
using EnergyPlus::ChillerIndirectAbsorption

@fixture
class ChillerIndirectAbsorption_GetInput(EnergyPlusFixture):
    def TestBody(self):
        var idf_objects: String = delimited_string([
            "Chiller:Absorption:Indirect,",
            "  Big Chiller,             !- Name",
            "  10000,                   !- Nominal Capacity {W}",
            "  150,                     !- Nominal Pumping Power {W}",
            "  Big Chiller Inlet Node,  !- Chilled Water Inlet Node Name",
            "  Big Chiller Outlet Node, !- Chilled Water Outlet Node Name",
            "  Big Chiller Condenser Inlet Node,  !- Condenser Inlet Node Name",
            "  Big Chiller Condenser Outlet Node,  !- Condenser Outlet Node Name",
            "  0.15,                    !- Minimum Part Load Ratio",
            "  1.0,                     !- Maximum Part Load Ratio",
            "  0.65,                    !- Optimum Part Load Ratio",
            "  35.0,                    !- Design Condenser Inlet Temperature {C}",
            "  10.0,                    !- Condenser Inlet Temperature Lower Limit {C}",
            "  5.0,                     !- Chilled Water Outlet Temperature Lower Limit {C}",
            "  0.0011,                  !- Design Chilled Water Flow Rate {m3/s}",
            "  0.0011,                  !- Design Condenser Water Flow Rate {m3/s}",
            "  LeavingSetpointModulated,!- Chiller Flow Mode",
            "  SteamUseFPLR,            !- Generator Heat Input Function of Part Load Ratio Curve Name",
            "  PumpUseFPLR,             !- Pump Electric Input Function of Part Load Ratio Curve Name",
            "  AbsorberSteamInletNode,  !- Generator Inlet Node Name",
            "  AbsorberSteamOutletNode, !- Generator Outlet Node Name",
            "  CAPfCOND,                !- Capacity Correction Function of Condenser Temperature Curve Name",
            "  CAPfEVAP,                !- Capacity Correction Function of Chilled Water Temperature Curve Name",
            "  ,                        !- Capacity Correction Function of Generator Temperature Curve Name",
            "  SteamFCondTemp,          !- Generator Heat Input Correction Function of Condenser Temperature Curve Name",
            "  SteamFEvapTemp,          !- Generator Heat Input Correction Function of Chilled Water Temperature Curve Name",
            "  Steam,                   !- Generator Heat Source Type",
            "  autosize,                !- Design Generator Fluid Flow Rate {m3/s}",
            "  30.0,                    !- Temperature Lower Limit Generator Inlet {C}",
            "  2.0,                     !- Degree of Subcooling in Steam Generator {C}",
            "  12.0;                    !- Degree of Subcooling in Steam Condensate Loop {C}",
        ])
        ASSERT_TRUE(process_idf(idf_objects))
        state.dataGlobal.DoWeathSim = true
        GetIndirectAbsorberInput(state)
        EXPECT_EQ(state.dataChillerIndirectAbsorption.IndirectAbsorber.size(), 1)
        EXPECT_EQ(state.dataChillerIndirectAbsorption.IndirectAbsorber[0].Name, "BIG CHILLER")
        EXPECT_EQ(state.dataChillerIndirectAbsorption.IndirectAbsorber[0].NomCap, 10000.0)
        EXPECT_EQ(state.dataChillerIndirectAbsorption.IndirectAbsorber[0].NomPumpPower, 150.0)
        EXPECT_EQ(state.dataChillerIndirectAbsorption.IndirectAbsorber[0].MinPartLoadRat, 0.15)
        EXPECT_EQ(state.dataChillerIndirectAbsorption.IndirectAbsorber[0].MaxPartLoadRat, 1.00)
        EXPECT_EQ(state.dataChillerIndirectAbsorption.IndirectAbsorber[0].OptPartLoadRat, 0.65)
        EXPECT_EQ(state.dataChillerIndirectAbsorption.IndirectAbsorber[0].LoopSubcool, 12.0)