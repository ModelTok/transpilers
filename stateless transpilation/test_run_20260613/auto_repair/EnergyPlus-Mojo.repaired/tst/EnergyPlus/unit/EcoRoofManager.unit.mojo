from gtest import Test, TestFixture, EXPECT_NEAR, EXPECT_TRUE, EXPECT_FALSE, EXPECT_EQ, ASSERT_TRUE, ASSERT_EQ, EXPECT_THROW
from Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.Construction import *
from EnergyPlus.Data.EnergyPlusData import *
from EnergyPlus.DataEnvironment import *
from EnergyPlus.DataErrorTracking import *
from EnergyPlus.DataHVACGlobals import *
from EnergyPlus.DataHeatBalance import *
from EnergyPlus.DataWater import *
from EnergyPlus.EcoRoofManager import *
from EnergyPlus.HeatBalanceManager import *
from EnergyPlus.Material import *
from EnergyPlus.ScheduleManager import *
from EnergyPlus.SolarShading import *
from EnergyPlus.WaterManager import *
from EnergyPlus.WeatherManager import *
from EnergyPlus.DataStringGlobals import *
from EnergyPlus.DataSurfaces import *
from EnergyPlus.DataGlobalConstants import FatalError

def test_EcoRoof_CalculateEcoRoofSolarTest():
    with TestFixture(EnergyPlusFixture) as test:
        var state = test.state
        state.init_state(state[])
        var resultRS: Real64
        var resultf1: Real64
        var expectedRS: Real64
        var expectedf1: Real64
        var SurfNum: int = 1
        state.dataSolarShading.SurfAnisoSkyMult.allocate(SurfNum)
        state.dataEnvrn.SOLCOS[3] = -1.0
        state.dataEnvrn.BeamSolarRad = 321.0
        state.dataSolarShading.SurfAnisoSkyMult[SurfNum] = 0.5
        state.dataEnvrn.DifSolarRad = 124.0
        expectedRS = 62.0
        expectedf1 = 3.9956
        CalculateEcoRoofSolar(state[], resultRS, resultf1, SurfNum)
        EXPECT_NEAR(resultRS, expectedRS, 0.001)
        EXPECT_NEAR(resultf1, expectedf1, 0.001)
        state.dataEnvrn.SOLCOS[3] = 0.7
        state.dataEnvrn.BeamSolarRad = 400.0
        state.dataSolarShading.SurfAnisoSkyMult[SurfNum] = 0.6
        state.dataEnvrn.DifSolarRad = 100.0
        expectedRS = 340.0
        expectedf1 = 1.4004
        CalculateEcoRoofSolar(state[], resultRS, resultf1, SurfNum)
        EXPECT_NEAR(resultRS, expectedRS, 0.001)
        EXPECT_NEAR(resultf1, expectedf1, 0.001)
        state.dataEnvrn.SOLCOS[3] = 1.0
        state.dataEnvrn.BeamSolarRad = 1500.0
        state.dataSolarShading.SurfAnisoSkyMult[SurfNum] = 0.0
        state.dataEnvrn.DifSolarRad = 0.0
        expectedRS = 1500.0
        expectedf1 = 1.0
        CalculateEcoRoofSolar(state[], resultRS, resultf1, SurfNum)
        EXPECT_NEAR(resultRS, expectedRS, 0.001)
        EXPECT_NEAR(resultf1, expectedf1, 0.001)

def test_EcoRoofManager_UpdateSoilProps():
    with TestFixture(EnergyPlusFixture) as test:
        var state = test.state
        var idf_objects: String = delimited_string([
            "Construction,",
            "ASHRAE 90.1-2004_Sec 5.5-2_Roof,  !- Name",
            "BaseEco,                 !- Outside Layer",
            "ASHRAE 90.1-2004_Sec 5.5-2_Roof Insulation_1,  !- Layer 2",
            "ASHRAE 90.1-2004_Sec 5.5-2_MAT-METAL;  !- Layer 3",
            "Material:RoofVegetation,",
            "BaseEco,                 !- Name",
            "0.5,                     !- Height of Plants {m}",
            "5,                       !- Leaf Area Index {dimensionless}",
            "0.2,                     !- Leaf Reflectivity {dimensionless}",
            "0.95,                    !- Leaf Emissivity",
            "180,                     !- Minimum Stomatal Resistance {s/m}",
            "EcoRoofSoil,             !- Soil Layer Name",
            "MediumSmooth,            !- Roughness",
            "0.18,                    !- Thickness {m}",
            "0.4,                     !- Conductivity of Dry Soil {W/m-K}",
            "641,                     !- Density of Dry Soil {kg/m3}",
            "1100,                    !- Specific Heat of Dry Soil {J/kg-K}",
            "0.95,                    !- Thermal Absorptance",
            "0.8,                     !- Solar Absorptance",
            "0.7,                     !- Visible Absorptance",
            "0.4,                     !- Saturation Volumetric Moisture Content of the Soil Layer",
            "0.01,                    !- Residual Volumetric Moisture Content of the Soil Layer",
            "0.2,                     !- Initial Volumetric Moisture Content of the Soil Layer",
            "Advanced;                !- Moisture Diffusion Calculation Method",
            "Material,",
            "ASHRAE 90.1-2004_Sec 5.5-2_Roof Insulation_1,  !- Name",
            "MediumRough,             !- Roughness",
            "0.1250,                  !- Thickness {m}",
            "0.0490,                  !- Conductivity {W/m-K}",
            "265.0000,                !- Density {kg/m3}",
            "836.8000,                !- Specific Heat {J/kg-K}",
            "0.9000,                  !- Thermal Absorptance",
            "0.7000,                  !- Solar Absorptance",
            "0.7000;                  !- Visible Absorptance",
            "Material,",
            "ASHRAE 90.1-2004_Sec 5.5-2_MAT-METAL,  !- Name",
            "MediumSmooth,            !- Roughness",
            "0.0015,                  !- Thickness {m}",
            "45.0060,                 !- Conductivity {W/m-K}",
            "7680.0000,               !- Density {kg/m3}",
            "418.4000,                !- Specific Heat {J/kg-K}",
            "0.9000,                  !- Thermal Absorptance",
            "0.7000,                  !- Solar Absorptance",
            "0.3000;                  !- Visible Absorptance",
            "RoofIrrigation,",
            "SmartSchedule,           !- Irrigation Model Type",
            "IRRIGATIONSCHD,          !- Irrigation Rate Schedule Name",
            "100;                     !- Irrigation Maximum Saturation Threshold",
            "Schedule:Compact,",
            "IRRIGATIONSCHD,          !- Name",
            "Any Number,              !- Schedule Type Limits Name",
            "Through: 12/31,          !- Field 1",
            "For: Alldays,            !- Field 2",
            "Until: 07:00,0.001,      !- Field 3",
            "Until: 09:00,0.002,      !- Field 4",
            "Until: 24:00,0.003;      !- Field 5",
        ])
        ASSERT_TRUE(process_idf(idf_objects))
        state.init_state(state[])
        var ErrorsFound: Bool = False
        Material.GetMaterialData(state[], ErrorsFound)
        EXPECT_FALSE(ErrorsFound)
        HeatBalanceManager.GetConstructData(state[], ErrorsFound)
        EXPECT_FALSE(ErrorsFound)
        var Moisture: Real64 = 0.2
        var MeanRootMoisture: Real64 = 0.2
        var Alphag: Real64 = 0.2
        var MoistureMax: Real64 = 0.4
        var MoistureResidual: Real64 = 0.01
        var SoilThickness: Real64 = 0.18
        var Vfluxf: Real64 = 0.0
        var Vfluxg: Real64 = 0.0
        var ConstrNum: int = 1
        var unit: int = 0
        var Tg: Real64 = 10
        var Tf: Real64 = 10
        var Qsoil: Real64 = 0
        WaterManager.GetWaterManagerInput(state[])
        state.dataGlobal.TimeStepZoneSec = 900
        state.dataEnvrn.Year = 2000
        state.dataEnvrn.EndYear = 2000
        state.dataEnvrn.Month = 1
        state.dataGlobal.TimeStep = 2
        state.dataWaterData.RainFall.ModeID = DataWater.RainfallMode.None
        state.dataEnvrn.LiquidPrecipitation = 0.005
        WaterManager.UpdatePrecipitation(state[])
        ASSERT_EQ(state.dataEcoRoofMgr.CurrentPrecipitation, 0.005)
        EcoRoofManager.UpdateSoilProps(
            state[], Moisture, MeanRootMoisture, MoistureMax, MoistureResidual, SoilThickness, Vfluxf, Vfluxg, ConstrNum, Alphag, unit, Tg, Tf, Qsoil)
        ASSERT_EQ(state.dataWaterData.Irrigation.ActualAmount, state.dataEcoRoofMgr.CurrentIrrigation)

def test_EcoRoofManager_initEcoRoofFirstTimeTest():
    with TestFixture(EnergyPlusFixture) as test:
        var state = test.state
        state.init_state(state[])
        var surfNum: int = 1
        var constrNum: int = 1
        var expectedAnswer: Real64
        var allowableTolerance: Real64 = 0.000001
        state.dataConstruction.Construct.allocate(constrNum)
        var mat = Material.MaterialEcoRoof()
        state.dataMaterial.materials.push_back(mat)
        state.dataSurface.Surface.allocate(surfNum)
        var thisConstruct = state.dataConstruction.Construct[constrNum]
        var thisEcoRoof = state.dataEcoRoofMgr
        thisConstruct.LayerPoint.allocate(1)
        thisConstruct.LayerPoint[1] = 1
        state.dataSurface.Surface[surfNum].HeatTransferAlgorithm = DataSurfaces.HeatTransferModel.CTF
        mat.LAI = 3.21
        mat.AbsorpSolar = 0.72
        thisEcoRoof.FirstEcoSurf = 0
        thisEcoRoof.EcoRoofbeginFlag = True
        initEcoRoofFirstTime(state[], surfNum, constrNum)
        expectedAnswer = 3.21
        EXPECT_NEAR(thisEcoRoof.LAI, expectedAnswer, allowableTolerance)
        expectedAnswer = 0.28
        EXPECT_NEAR(thisEcoRoof.Alphag, expectedAnswer, allowableTolerance)
        EXPECT_EQ(thisEcoRoof.FirstEcoSurf, surfNum)
        EXPECT_FALSE(thisEcoRoof.EcoRoofbeginFlag)

def test_EcoRoofManager_initEcoRoofTest():
    with TestFixture(EnergyPlusFixture) as test:
        var state = test.state
        state.init_state(state[])
        var surfNum: int = 1
        var constrNum: int = 1
        var expectedAnswer: Real64
        var allowableTolerance: Real64 = 0.000001
        state.dataConstruction.Construct.allocate(constrNum)
        var mat = Material.MaterialEcoRoof()
        state.dataMaterial.materials.push_back(mat)
        state.dataSurface.Surface.allocate(surfNum)
        var thisConstruct = state.dataConstruction.Construct[constrNum]
        var thisEcoRoof = state.dataEcoRoofMgr
        thisConstruct.LayerPoint.allocate(1)
        thisConstruct.LayerPoint[1] = 1
        state.dataGlobal.BeginEnvrnFlag = False
        state.dataGlobal.WarmupFlag = True
        thisEcoRoof.CalcEcoRoofMyEnvrnFlag = False
        mat.InitMoisture = 23.0
        mat.AbsorpSolar = 0.72
        thisEcoRoof.Moisture = 0.0
        thisEcoRoof.MeanRootMoisture = 0.0
        thisEcoRoof.Alphag = 0.0
        initEcoRoof(state[], surfNum, constrNum)
        expectedAnswer = 23.0
        EXPECT_NEAR(thisEcoRoof.Moisture, expectedAnswer, allowableTolerance)
        EXPECT_NEAR(thisEcoRoof.MeanRootMoisture, expectedAnswer, allowableTolerance)
        expectedAnswer = 0.28
        EXPECT_NEAR(thisEcoRoof.Alphag, expectedAnswer, allowableTolerance)
        EXPECT_TRUE(thisEcoRoof.CalcEcoRoofMyEnvrnFlag)
        state.dataGlobal.BeginEnvrnFlag = True
        state.dataGlobal.WarmupFlag = False
        thisEcoRoof.CalcEcoRoofMyEnvrnFlag = True
        thisEcoRoof.Tg = 0.0
        thisEcoRoof.Tf = 0.0
        expectedAnswer = 10.0
        initEcoRoof(state[], surfNum, constrNum)
        EXPECT_NEAR(thisEcoRoof.Tg, expectedAnswer, allowableTolerance)
        EXPECT_NEAR(thisEcoRoof.Tf, expectedAnswer, allowableTolerance)
        EXPECT_FALSE(thisEcoRoof.CalcEcoRoofMyEnvrnFlag)

def test_EcoRoofManager_initEcoRoofFirstTimeErrorTest():
    with TestFixture(EnergyPlusFixture) as test:
        var state = test.state
        var idf_objects: String = delimited_string([
            "Version, " + DataStringGlobals.MatchVersion + ";",
        ])
        ASSERT_TRUE(process_idf(idf_objects))
        state.init_state(state[])
        var surfNum: int = 1
        var constrNum: int = 1
        state.dataConstruction.Construct.allocate(constrNum)
        var mat = Material.MaterialEcoRoof()
        state.dataMaterial.materials.push_back(mat)
        state.dataSurface.Surface.allocate(surfNum)
        var thisConstruct = state.dataConstruction.Construct[constrNum]
        var thisEcoRoof = state.dataEcoRoofMgr
        thisConstruct.LayerPoint.allocate(1)
        thisConstruct.LayerPoint[1] = 1
        state.dataSurface.Surface[surfNum].Name = "ZN6_S_SPACE_2:ROOF"
        state.dataSurface.Surface[surfNum].HeatTransferAlgorithm = DataSurfaces.HeatTransferModel.CTF
        thisEcoRoof.FirstEcoSurf = 0
        thisEcoRoof.EcoRoofbeginFlag = True
        initEcoRoofFirstTime(state[], surfNum, constrNum)
        state.dataSurface.Surface[surfNum].HeatTransferAlgorithm = DataSurfaces.HeatTransferModel.CondFD
        thisEcoRoof.FirstEcoSurf = 0
        thisEcoRoof.EcoRoofbeginFlag = True
        EXPECT_THROW(initEcoRoofFirstTime(state[], surfNum, constrNum), FatalError)
        var error_string: String = delimited_string([
            "   ** Severe  ** initEcoRoofFirstTime: EcoRoof simulation but HeatBalanceAlgorithm is not ConductionTransferFunction(CTF). EcoRoof model currently works only with CTF heat balance solution algorithm.",
            "   **   ~~~   ** Occurs for surface named ZN6_S_SPACE_2:ROOF",
            "   **   ~~~   ** Check input syntax for HeatBalanceAlgorithm, SurfaceProperty:HeatTransferAlgorithm,",
            "   **   ~~~   ** SurfaceProperty:HeatTransferAlgorithm:MultipleSurface, and SurfaceProperty:HeatTransferAlgorithm:SurfaceList ",
            "   **   ~~~   ** to verify that the solution method is set to CTF for the surface that is an EcoRoof.",
            "   **  Fatal  ** initEcoRoofFirstTime: Program terminates due to preceding conditions.",
            "   ...Summary of Errors that led to program termination:",
            "   ..... Reference severe error count=1",
            "   ..... Last severe error=initEcoRoofFirstTime: EcoRoof simulation but HeatBalanceAlgorithm is not ConductionTransferFunction(CTF). EcoRoof model currently works only with CTF heat balance solution algorithm.",
        ])
        EXPECT_TRUE(compare_err_stream(error_string, True))
        state.dataSurface.Surface[surfNum].HeatTransferAlgorithm = DataSurfaces.HeatTransferModel.HAMT
        thisEcoRoof.FirstEcoSurf = 0
        thisEcoRoof.EcoRoofbeginFlag = True
        state.dataErrTracking.TotalSevereErrors = 0
        EXPECT_THROW(initEcoRoofFirstTime(state[], surfNum, constrNum), FatalError)
        EXPECT_TRUE(compare_err_stream(error_string, True))
        state.dataSurface.Surface[surfNum].HeatTransferAlgorithm = DataSurfaces.HeatTransferModel.EMPD
        thisEcoRoof.FirstEcoSurf = 0
        thisEcoRoof.EcoRoofbeginFlag = True
        state.dataErrTracking.TotalSevereErrors = 0
        EXPECT_THROW(initEcoRoofFirstTime(state[], surfNum, constrNum), FatalError)
        EXPECT_TRUE(compare_err_stream(error_string, True))
        state.dataSurface.Surface[surfNum].HeatTransferAlgorithm = DataSurfaces.HeatTransferModel.Kiva
        thisEcoRoof.FirstEcoSurf = 0
        thisEcoRoof.EcoRoofbeginFlag = True
        state.dataErrTracking.TotalSevereErrors = 0
        EXPECT_THROW(initEcoRoofFirstTime(state[], surfNum, constrNum), FatalError)
        EXPECT_TRUE(compare_err_stream(error_string, True))