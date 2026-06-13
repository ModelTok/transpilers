from .Fixtures.EnergyPlusFixture import EnergyPlusFixture, process_idf, state, delimited_string
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataLoopNode import DataLoopNode
from EnergyPlus.PCMThermalStorage import PCMStorageData, GetPCMStorageInput
from EnergyPlus.ScheduleManager import ScheduleManager
from EnergyPlus.Material import Material

using EnergyPlus
using EnergyPlus::PCMStorage

TEST_F(EnergyPlusFixture, PCMThermalTankUseEnergy)
{
    let idf_objects = delimited_string(
        {"Schedule:Constant, ALWAYS_ON,,1.0;",
         "Material,",
         "  PCM_Material,           !- Name",
         "  Smooth,                 !- Roughness",
         "  0.10,                   !- Thickness {m}",
         "  0.20,                   !- Conductivity {W/m-K}",
         "  800.0,                  !- Density {kg/m3}",
         "  1000.0,                 !- Specific Heat {J/kg-K}",
         "  0.90,                   !- Thermal Absorptance",
         "  0.70,                   !- Solar Absorptance",
         "  0.70;                   !- Visible Absorptance",
         "MaterialProperty:PhaseChangeHysteresis,",
         "  PCM_Material,            !- Name",
         "  60000,                   !- Latent Heat during the Entire Phase Change Process {J/kg}",
         "  0.5,                     !- Liquid State Thermal Conductivity {W/m-K}",
         "  800,                     !- Liquid State Density {kg/m3}",
         "  2000,                    !- Liquid State Specific Heat {J/kg-K}",
         "  2,                       !- High Temperature Difference of Melting Curve {deltaC}",
         "  50,                      !- Peak Melting Temperature {C}",
         "  2,                       !- Low Temperature Difference of Melting Curve {deltaC}",
         "  0.5,                     !- Solid State Thermal Conductivity {W/m-K}",
         "  800,                     !- Solid State Density {kg/m3}",
         "  2000,                    !- Solid State Specific Heat {J/kg-K}",
         "  2,                       !- High Temperature Difference of Freezing Curve {deltaC}",
         "  35,                      !- Peak Freezing Temperature {C}",
         "  2;                       !- Low Temperature Difference of Freezing Curve {deltaC}",
         "ThermalStorage:PCM,",
         "  PCM Tank,                !- Name",
         "  ALWAYS_ON,               !- Availability Schedule Name",
         "  MICROCHP SENERTECH Water Inlet Node,  !- Plant Side Inlet Node Name",
         "  MICROCHP SENERTECH Water Outlet Node, !- Plant Side Outlet Node Name",
         "  PCM Inlet Node,          !- Use Side Inlet Node Name",
         "  PCM Outlet Node,         !- Use Side Outlet Node Name",
         "  PCM_Material,            !- PCM Material Name",
         "  400,                     !- Tank Capacity {kg}",
         "  25,                      !- Heat Loss Rate {W}",
         "  autosize,                !- Use Side Design Flow Rate {m3/s}",
         "  autosize;                !- Plant Side Design Flow Rate {m3/s}"}
    )
    ASSERT_TRUE(process_idf(idf_objects))
    state.init_state(state)
    var ErrorsFound = false
    Material.GetMaterialData(state, ErrorsFound)
    EXPECT_FALSE(ErrorsFound)
    Material.GetHysteresisData(state, ErrorsFound)
    EXPECT_FALSE(ErrorsFound)
    PCMStorage.GetPCMStorageInput(state)
    let pcm = PCMStorageData.instance()
    EXPECT_EQ("PCM TANK", pcm.Name)
    EXPECT_DOUBLE_EQ(400.0, pcm.TankCapacity)
    EXPECT_DOUBLE_EQ(25.0, pcm.HeatLossRate)
    EXPECT_GT(pcm.PlantSideInletNode, 0)
    EXPECT_GT(pcm.PlantSideOutletNode, 0)
    EXPECT_GT(pcm.UseSideInletNode, 0)
    EXPECT_GT(pcm.UseSideOutletNode, 0)
    ASSERT_NE(pcm.PCMmat, None)
    EXPECT_GT(pcm.LatentHeat, 0.0)
    EXPECT_GT(pcm.MeltingTemp, 0.0)
    EXPECT_GT(pcm.FreezingTemp, 0.0)
    EXPECT_GT(pcm.SpecificHeat, 0.0)
}