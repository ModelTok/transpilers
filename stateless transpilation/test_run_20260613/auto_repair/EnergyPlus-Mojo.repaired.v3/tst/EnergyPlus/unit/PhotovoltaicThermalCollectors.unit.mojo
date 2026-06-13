from gtest import *
from .Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.Data.EnergyPlusData import *
from EnergyPlus.DataEnvironment import *
from EnergyPlus.DataGlobalConstants import Constant
from EnergyPlus.DataHeatBalSurface import *
from EnergyPlus.DataLoopNode import *
from EnergyPlus.DataPhotovoltaics import *
from EnergyPlus.HeatBalanceManager import HeatBalanceManager
from EnergyPlus.HeatBalanceSurfaceManager import HeatBalanceSurfaceManager
from EnergyPlus.PhotovoltaicThermalCollectors import PhotovoltaicThermalCollectors
from EnergyPlus.Photovoltaics import Photovoltaics
from EnergyPlus.SolarShading import SolarShading
from EnergyPlus.SurfaceGeometry import *
from EnergyPlus.UtilityRoutines import Util

def test_BIPVT_calc_k_taoalpha():
    var state = EnergyPlusFixture()
    state.init_state(state)
    var thisBIPVT = PhotovoltaicThermalCollectors.PVTCollectorStruct()
    var theta: Float64 = 0.0  # lower value
    var glass_thickness: Float64 = 0.001
    var refrac_index_glass: Float64 = 1.0
    var k_glass: Float64 = 1.0
    var k_taoalpha: Float64 = 0.0
    k_taoalpha = thisBIPVT.calc_k_taoalpha(theta, glass_thickness, refrac_index_glass, k_glass)
    EXPECT_EQ(k_taoalpha, 1.0)
    theta = Constant.Pi  # higher value
    k_taoalpha = thisBIPVT.calc_k_taoalpha(theta, glass_thickness, refrac_index_glass, k_glass)
    EXPECT_EQ(k_taoalpha, 0.0)
    theta = Constant.Pi / 2.0  # mid-range value
    k_taoalpha = thisBIPVT.calc_k_taoalpha(theta, glass_thickness, refrac_index_glass, k_glass)
    EXPECT_EQ(k_taoalpha, 0.0)
    theta = Constant.Pi / 4.0  # mid-range value
    refrac_index_glass = 2.0  # higher value
    k_taoalpha = thisBIPVT.calc_k_taoalpha(theta, glass_thickness, refrac_index_glass, k_glass)
    EXPECT_NEAR(k_taoalpha, 0.986, 0.001)
    k_glass = 10.0  # higher value
    k_taoalpha = thisBIPVT.calc_k_taoalpha(theta, glass_thickness, refrac_index_glass, k_glass)
    EXPECT_NEAR(k_taoalpha, 0.986, 0.001)
    k_glass = 32.0  # higher value
    theta = 0.0
    glass_thickness = 0.006
    refrac_index_glass = 1.52
    k_taoalpha = thisBIPVT.calc_k_taoalpha(theta, glass_thickness, refrac_index_glass, k_glass)
    EXPECT_EQ(k_taoalpha, 1.0)
    k_glass = 32.0  # higher value
    theta = Constant.Pi / 4.0
    glass_thickness = 0.006
    refrac_index_glass = 1.52
    k_taoalpha = thisBIPVT.calc_k_taoalpha(theta, glass_thickness, refrac_index_glass, k_glass)
    EXPECT_NEAR(k_taoalpha, 0.965, 0.001)

def test_BIPVT_calculateBIPVTMaxHeatGain():
    var state = EnergyPlusFixture()
    var idf_objects = delimited_string([
        "  Zone,",
        "    ZN_1_FLR_1_SEC_1;               !- Name",
        "",
        "  SurfaceProperty:OtherSideConditionsModel,",
        "    OSCM_ZN_1_FLR_1_SEC_1, !- Name",
        "    GapConvectionRadiation; !- Type of Modeling",
        "",
        "  Construction,",
        "    ASHRAE 90.1-2004_Sec 5.5-3ab_IEAD_Roof,  !- Name",
        "    Roof Membrane,           !- Outside Layer",
        "    Roof Insulation,         !- Layer 2",
        "    Metal Decking;           !- Layer 3",
        "",
        "  Material,",
        "    Roof Membrane,           !- Name",
        "    VeryRough,               !- Roughness",
        "    0.0095,                  !- Thickness {m}",
        "    0.1600,                  !- Conductivity {W/m-K}",
        "    1121.2900,               !- Density {kg/m3}",
        "    1460.0000,               !- Specific Heat {J/kg-K}",
        "    0.9000,                  !- Thermal Absorptance",
        "    0.7000,                  !- Solar Absorptance",
        "    0.7000;                  !- Visible Absorptance",
        "",
        "  Material,",
        "    Roof Insulation,         !- Name",
        "    MediumRough,             !- Roughness",
        "    0.1250,                  !- Thickness {m}",
        "    0.0490,                  !- Conductivity {W/m-K}",
        "    265.0000,                !- Density {kg/m3}",
        "    836.8000,                !- Specific Heat {J/kg-K}",
        "    0.9000,                  !- Thermal Absorptance",
        "    0.7000,                  !- Solar Absorptance",
        "    0.7000;                  !- Visible Absorptance",
        "",
        "  Material,",
        "    Metal Decking,           !- Name",
        "    MediumSmooth,            !- Roughness",
        "    0.0015,                  !- Thickness {m}",
        "    45.0060,                 !- Conductivity {W/m-K}",
        "    7680.0000,               !- Density {kg/m3}",
        "    418.4000,                !- Specific Heat {J/kg-K}",
        "    0.9000,                  !- Thermal Absorptance",
        "    0.7000,                  !- Solar Absorptance",
        "    0.3000;                  !- Visible Absorptance",
        "",
        "  BuildingSurface:Detailed,",
        "    ZN_1_FLR_1_SEC_1_Ceiling,!- Name",
        "    ceiling,                 !- Surface Type",
        "    ASHRAE 90.1-2004_Sec 5.5-3ab_IEAD_Roof,  !- Construction Name",
        "    ZN_1_FLR_1_SEC_1,        !- Zone Name",
        "    ,                        !- Space Name",
        "    OtherSideConditionsModel,                !- Outside Boundary Condition",
        "    OSCM_ZN_1_FLR_1_SEC_1,                        !- Outside Boundary Condition Object",
        "    SunExposed,              !- Sun Exposure",
        "    WindExposed,             !- Wind Exposure",
        "    0.0000,                  !- View Factor to Ground",
        "    4,                       !- Number of Vertices",
        "    4.570,0.000,5.009,  !- X,Y,Z ==> Vertex 1 {m}",
        "    17.186,0.000,5.009,  !- X,Y,Z ==> Vertex 2 {m}",
        "    17.186,4.570,5.009,  !- X,Y,Z ==> Vertex 3 {m}",
        "    4.570,4.570,5.009;  !- X,Y,Z ==> Vertex 4 {m}",
        "  SolarCollector:FlatPlate:PhotovoltaicThermal,",
        "    PVT:ZN_1_FLR_1_SEC_1_Ceiling,  !- Name",
        "    ZN_1_FLR_1_SEC_1_Ceiling,!- Surface Name",
        "    ZN_1_FLR_1_SEC_1_CEILING_BIPVT,    !- Photovoltaic-Thermal Model Performance Name",
        "    PV:ZN_1_FLR_1_SEC_1_Ceiling,  !- Photovoltaic Name",
        "    Air,                     !- Thermal Working Fluid Type",
        "    ,                        !- Water Inlet Node Name",
        "    ,                        !- Water Outlet Node Name",
        "    ZN_1_FLR_1_SEC_1:Sys_OAInlet Node,  !- Air Inlet Node Name",
        "    PVT:ZN_1_FLR_1_SEC_1_Ceiling Outlet,  !- Air Outlet Node Name",
        "    Autosize;                !- Design Flow Rate {m3/s}",
        "                                                                                                                  ",
        "  SolarCollectorPerformance:PhotovoltaicThermal:BIPVT,",
        "    ZN_1_FLR_1_SEC_1_Ceiling_BIPVT, !- Name",
        "    OSCM_ZN_1_FLR_1_SEC_1,  !- Boundary Conditions Model Name",
        "    , !- Availability Schedule Name",
        "    0.1, !- Effective Plenum Gap Thickness Behind PV Modules",
        "    0.957, !- PV Cell Normal Transmittance-Absorptance Product",
        "    0.87, !- Backing Material Normal Transmittance-Absorptance Product",
        "    0.85, !- Cladding Normal Transmittance-Absorptance Product",
        "    0.85, !- Fraction of Collector Gross Area Covered by PV module",
        "    0.9, !- Fraction of PV cell area to PV module area",
        "    0.0044, !- PV Module Thermal Resistance - Top",
        "    0.0039, !- PV Module Thermal Resistance - Bottom",
        "    0.85, !- PV Module Longwave Emissivity",
        "    0.9, !- Backing Material Longwave Emissivity",
        "    0.002, !- Glass Thickness",
        "    1.526, !- Glass Refraction Index",
        "    4.0; !- Glass Extinction Coefficient",
        "  Generator:Photovoltaic,",
        "    PV:ZN_1_FLR_1_SEC_1_Ceiling,  !- Name",
        "    ZN_1_FLR_1_SEC_1_Ceiling,!- Surface Name",
        "    PhotovoltaicPerformance:EquivalentOne-Diode,  !- Photovoltaic Performance Object Type",
        "    SiemensSamplePVModule,  !- Module Performance Name",
        "    PhotovoltaicThermalSolarCollector,  !- Heat Transfer Integration Mode",
        "    17.0,                     !- Number of Series Strings in Parallel {dimensionless}",
        "    4.0;                     !- Number of Modules in Series {dimensionless}",
        "",
        "  PhotovoltaicPerformance:EquivalentOne-Diode,",
        "    SiemensSamplePVModule, !- Name",
        "    CrystallineSilicon, !- Cell Type",
        "    36, !- Number of Cells in Series [-]",
        "    1.0, !- Area Active [m2]",
        "    0.957, !- Transmittance Absorptance Product",
        "    1.12, !- Semiconductor Bandgap [eV]",
        "    1000000, !- Shunt Resistance [Ohms]",
        "    6.5, !- Short Circuit Current [A/K]",
        "    21.6, !- Open Circuit Voltage [V/K]",
        "    25, !- Reference Temperature [C]",
        "    1000, !- Reference Insolation [W/m2]",
        "    5.9, !- Module Current at Maximum Power [A]",
        "    17, !- Module Voltage at Maximum Power [V]",
        "    0.002, !- Temperature Coefficient of Short Circuit Current",
        "    -0.079, !- Temperature Coefficient of Open Circuit Voltage",
        "    20, !- Nominal Operating Cell Temperature Test Ambient Temperature [C]",
        "    45, !- Nominal Operating Cell Temperature Test Cell Temperature [C]",
        "    800, !- Nominal Operating Cell Temperature Test Insolation [W/m2]",
        "    30, !- Module Heat Loss Coefficient [W/m2.K]",
        "    50000; !- Total Heat Capacity [J/m2-K]",
    ])
    ASSERT_TRUE(process_idf(idf_objects))
    state.init_state(state)
    HeatBalanceManager.GetHeatBalanceInput(state)  # Gets materials, constructions, zones, surfaces, etc.
    HeatBalanceSurfaceManager.AllocateSurfaceHeatBalArrays(state)
    Photovoltaics.GetPVInput(state)
    PhotovoltaicThermalCollectors.GetPVTcollectorsInput(state)
    state.dataGlobal.BeginSimFlag = True
    state.dataGlobal.BeginEnvrnFlag = True
    SolarShading.InitSolarCalculations(state)
    var thisBIPVT = state.dataPhotovoltaicThermalCollector.PVT(0)  # 1-based -> 0-based
    var tempSetPoint: Float64 = 24.0
    thisBIPVT.OperatingMode = PhotovoltaicThermalCollectors.PVTMode.Heating  # this should be converted to an enum?
    var bypassFraction: Float64 = 0.0
    var potentialHeatGain: Float64 = 0.0
    var potentialOutletTemp: Float64 = 0.0
    var eff: Float64 = 0.0
    var tCollector: Float64 = 0.0
    var InletNode: Int = Util.FindItemInList("ZN_1_FLR_1_SEC_1:SYS_OAINLET NODE",
                                         state.dataLoopNodes.NodeID,
                                         state.dataLoopNodes.NumOfNodes)  # HVAC node associated with inlet of BIPVT
    state.dataLoopNodes.Node(InletNode).HumRat = 0.001  # inlet air humidity ratio (kgda/kg)
    state.dataEnvrn.OutHumRat = 0.001  # ambient humidity ratio (kg/kg)
    state.dataEnvrn.SkyTemp = 0.0  # sky temperature (DegC)
    state.dataEnvrn.WindSpeed = 5.0  # wind speed (m/s)
    state.dataEnvrn.WindDir = 0.0  # wind direction (deg)
    state.dataPhotovoltaic.PVarray(thisBIPVT.PVnum).TRNSYSPVcalc.ArrayEfficiency = 0.5
    state.dataHeatBal.SurfQRadSWOutIncidentGndDiffuse(thisBIPVT.SurfNum) = 0.0  # Exterior ground diffuse solar incident on surface (W/m2)
    state.dataHeatBal.SurfCosIncidenceAngle(thisBIPVT.SurfNum) = 0.5  # Cosine of beam solar incidence angle
    thisBIPVT.OperatingMode = PhotovoltaicThermalCollectors.PVTMode.Heating
    tempSetPoint = 24.0
    state.dataLoopNodes.Node(InletNode).Temp = 10.0  # inlet fluid temperature (DegC)
    state.dataEnvrn.OutDryBulbTemp = 10.0  # ambient temperature (DegC)
    state.dataHeatBalSurf.SurfTempOut(thisBIPVT.SurfNum) = 12.0  # temperature of bldg surface (DegC)
    thisBIPVT.MassFlowRate = 0.01  # fluid mass flow rate (kg/s)
    state.dataHeatBal.SurfQRadSWOutIncidentBeam(thisBIPVT.SurfNum) = 500.0  # Exterior beam solar incident on surface (W/m2)
    state.dataHeatBal.SurfQRadSWOutIncidentSkyDiffuse(thisBIPVT.SurfNum) = 100.0  # Exterior sky diffuse solar incident on surface (W/m2)
    state.dataHeatBal.SurfQRadSWOutIncident(thisBIPVT.SurfNum) = 568.7  # total incident solar radiation
    thisBIPVT.calculateBIPVTMaxHeatGain(state, tempSetPoint, bypassFraction, potentialHeatGain, potentialOutletTemp, eff, tCollector)
    EXPECT_NEAR(bypassFraction, 0.0, 0.001)
    EXPECT_NEAR(potentialHeatGain, 41.68, 0.01)
    EXPECT_NEAR(potentialOutletTemp, 14.14, 0.01)
    EXPECT_NEAR(eff, 0.0013, 0.0001)
    EXPECT_NEAR(tCollector, 21.57, 0.01)
    thisBIPVT.OperatingMode = PhotovoltaicThermalCollectors.PVTMode.Heating
    tempSetPoint = 24.0
    state.dataLoopNodes.Node(InletNode).Temp = 10.0
    state.dataEnvrn.OutDryBulbTemp = 10.0
    state.dataHeatBalSurf.SurfTempOut(thisBIPVT.SurfNum) = 12.0
    thisBIPVT.MassFlowRate = 0.01
    thisBIPVT.BIPVT.PVEffGapWidth = 0.2
    state.dataHeatBal.SurfQRadSWOutIncidentBeam(thisBIPVT.SurfNum) = 500.0
    state.dataHeatBal.SurfQRadSWOutIncidentSkyDiffuse(thisBIPVT.SurfNum) = 100.0
    state.dataHeatBal.SurfQRadSWOutIncident(thisBIPVT.SurfNum) = 568.7
    thisBIPVT.calculateBIPVTMaxHeatGain(state, tempSetPoint, bypassFraction, potentialHeatGain, potentialOutletTemp, eff, tCollector)
    EXPECT_NEAR(bypassFraction, 0.0, 0.001)
    EXPECT_NEAR(potentialHeatGain, 41.59, 0.01)
    EXPECT_NEAR(potentialOutletTemp, 14.13, 0.01)
    EXPECT_NEAR(eff, 0.0013, 0.001)
    EXPECT_NEAR(tCollector, 21.64, 0.01)
    thisBIPVT.OperatingMode = PhotovoltaicThermalCollectors.PVTMode.Heating
    tempSetPoint = 24.0
    state.dataLoopNodes.Node(InletNode).Temp = 10.0
    state.dataEnvrn.OutDryBulbTemp = 10.0
    state.dataHeatBalSurf.SurfTempOut(thisBIPVT.SurfNum) = 12.0
    thisBIPVT.MassFlowRate = 0.1
    thisBIPVT.BIPVT.PVEffGapWidth = 0.1
    state.dataHeatBal.SurfQRadSWOutIncidentBeam(thisBIPVT.SurfNum) = 500.0
    state.dataHeatBal.SurfQRadSWOutIncidentSkyDiffuse(thisBIPVT.SurfNum) = 100.0
    state.dataHeatBal.SurfQRadSWOutIncident(thisBIPVT.SurfNum) = 568.7
    thisBIPVT.calculateBIPVTMaxHeatGain(state, tempSetPoint, bypassFraction, potentialHeatGain, potentialOutletTemp, eff, tCollector)
    EXPECT_NEAR(bypassFraction, 0.0, 0.001)
    EXPECT_NEAR(potentialHeatGain, 524.64, 0.01)
    EXPECT_NEAR(potentialOutletTemp, 15.21, 0.01)
    EXPECT_NEAR(eff, 0.016, 0.001)
    EXPECT_NEAR(tCollector, 20.93, 0.01)
    thisBIPVT.OperatingMode = PhotovoltaicThermalCollectors.PVTMode.Heating
    tempSetPoint = 24.0
    state.dataLoopNodes.Node(InletNode).Temp = 23.0
    state.dataEnvrn.OutDryBulbTemp = 23.0
    state.dataHeatBalSurf.SurfTempOut(thisBIPVT.SurfNum) = 23.0
    thisBIPVT.MassFlowRate = 0.01
    state.dataHeatBal.SurfQRadSWOutIncidentBeam(thisBIPVT.SurfNum) = 500.0
    state.dataHeatBal.SurfQRadSWOutIncidentSkyDiffuse(thisBIPVT.SurfNum) = 100.0
    state.dataHeatBal.SurfQRadSWOutIncident(thisBIPVT.SurfNum) = 568.7
    thisBIPVT.calculateBIPVTMaxHeatGain(state, tempSetPoint, bypassFraction, potentialHeatGain, potentialOutletTemp, eff, tCollector)
    EXPECT_NEAR(bypassFraction, 0.430, 0.001)
    EXPECT_NEAR(potentialHeatGain, 9.27, 0.01)
    EXPECT_NEAR(potentialOutletTemp, 23.92, 0.01)
    EXPECT_NEAR(eff, 0.0003, 0.0001)
    EXPECT_NEAR(tCollector, 31.32, 0.01)
    thisBIPVT.OperatingMode = PhotovoltaicThermalCollectors.PVTMode.Heating
    tempSetPoint = 24.0
    state.dataLoopNodes.Node(InletNode).Temp = 25.0
    state.dataEnvrn.OutDryBulbTemp = 25.0
    state.dataHeatBalSurf.SurfTempOut(thisBIPVT.SurfNum) = 24.0
    thisBIPVT.MassFlowRate = 0.01
    state.dataHeatBal.SurfQRadSWOutIncidentBeam(thisBIPVT.SurfNum) = 500.0
    state.dataHeatBal.SurfQRadSWOutIncidentSkyDiffuse(thisBIPVT.SurfNum) = 100.0
    state.dataHeatBal.SurfQRadSWOutIncident(thisBIPVT.SurfNum) = 568.7
    thisBIPVT.calculateBIPVTMaxHeatGain(state, tempSetPoint, bypassFraction, potentialHeatGain, potentialOutletTemp, eff, tCollector)
    EXPECT_NEAR(bypassFraction, 1.0, 0.001)
    EXPECT_NEAR(potentialHeatGain, 0.0, 0.01)
    EXPECT_NEAR(potentialOutletTemp, 25.0, 0.01)
    EXPECT_NEAR(eff, 0.0, 0.0001)
    EXPECT_NEAR(tCollector, 32.73, 0.01)
    thisBIPVT.OperatingMode = PhotovoltaicThermalCollectors.PVTMode.Cooling
    tempSetPoint = 13.0
    state.dataLoopNodes.Node(InletNode).Temp = 30.0
    state.dataEnvrn.OutDryBulbTemp = 30.0
    state.dataHeatBalSurf.SurfTempOut(thisBIPVT.SurfNum) = 22.0
    thisBIPVT.MassFlowRate = 0.01
    state.dataHeatBal.SurfQRadSWOutIncidentBeam(thisBIPVT.SurfNum) = 500.0
    state.dataHeatBal.SurfQRadSWOutIncidentSkyDiffuse(thisBIPVT.SurfNum) = 100.0
    state.dataHeatBal.SurfQRadSWOutIncident(thisBIPVT.SurfNum) = 568.7
    thisBIPVT.calculateBIPVTMaxHeatGain(state, tempSetPoint, bypassFraction, potentialHeatGain, potentialOutletTemp, eff, tCollector)
    EXPECT_NEAR(bypassFraction, 0.0, 0.001)
    EXPECT_NEAR(potentialHeatGain, -52.01, 0.01)
    EXPECT_NEAR(potentialOutletTemp, 24.83, 0.01)
    EXPECT_NEAR(eff, 0.0, 0.0001)
    EXPECT_NEAR(tCollector, 34.95, 0.01)
    thisBIPVT.OperatingMode = PhotovoltaicThermalCollectors.PVTMode.Cooling
    tempSetPoint = 22.0
    state.dataLoopNodes.Node(InletNode).Temp = 25.0
    state.dataEnvrn.OutDryBulbTemp = 25.0
    state.dataHeatBalSurf.SurfTempOut(thisBIPVT.SurfNum) = 20.0
    thisBIPVT.MassFlowRate = 0.01
    state.dataHeatBal.SurfQRadSWOutIncidentBeam(thisBIPVT.SurfNum) = 0.0
    state.dataHeatBal.SurfQRadSWOutIncidentSkyDiffuse(thisBIPVT.SurfNum) = 0.0
    state.dataHeatBal.SurfQRadSWOutIncident(thisBIPVT.SurfNum) = 0.0
    thisBIPVT.calculateBIPVTMaxHeatGain(state, tempSetPoint, bypassFraction, potentialHeatGain, potentialOutletTemp, eff, tCollector)
    EXPECT_NEAR(bypassFraction, 0.414, 0.001)
    EXPECT_NEAR(potentialHeatGain, -30.20, 0.01)
    EXPECT_NEAR(potentialOutletTemp, 22.0, 0.01)
    EXPECT_NEAR(eff, 0.0, 0.0001)
    EXPECT_NEAR(tCollector, 19.33, 0.01)
    thisBIPVT.OperatingMode = PhotovoltaicThermalCollectors.PVTMode.Cooling
    tempSetPoint = 22.0
    state.dataLoopNodes.Node(InletNode).Temp = 25.0
    state.dataEnvrn.OutDryBulbTemp = 25.0
    state.dataHeatBalSurf.SurfTempOut(thisBIPVT.SurfNum) = 20.0
    thisBIPVT.MassFlowRate = 1.0
    state.dataHeatBal.SurfQRadSWOutIncidentBeam(thisBIPVT.SurfNum) = 0.0
    state.dataHeatBal.SurfQRadSWOutIncidentSkyDiffuse(thisBIPVT.SurfNum) = 0.0
    state.dataHeatBal.SurfQRadSWOutIncident(thisBIPVT.SurfNum) = 0.0
    thisBIPVT.calculateBIPVTMaxHeatGain(state, tempSetPoint, bypassFraction, potentialHeatGain, potentialOutletTemp, eff, tCollector)
    EXPECT_NEAR(bypassFraction, 0.248, 0.001)
    EXPECT_NEAR(potentialHeatGain, -3023.06, 0.01)
    EXPECT_NEAR(potentialOutletTemp, 22.0, 0.01)
    EXPECT_NEAR(eff, 0.0, 0.0001)
    EXPECT_NEAR(tCollector, 20.38, 0.01)
    thisBIPVT.OperatingMode = PhotovoltaicThermalCollectors.PVTMode.Cooling
    tempSetPoint = 22.0
    state.dataLoopNodes.Node(InletNode).Temp = 20.0
    state.dataEnvrn.OutDryBulbTemp = 20.0
    state.dataHeatBalSurf.SurfTempOut(thisBIPVT.SurfNum) = 18.0
    thisBIPVT.MassFlowRate = 0.01
    state.dataHeatBal.SurfQRadSWOutIncidentBeam(thisBIPVT.SurfNum) = 0.0
    state.dataHeatBal.SurfQRadSWOutIncidentSkyDiffuse(thisBIPVT.SurfNum) = 0.0
    state.dataHeatBal.SurfQRadSWOutIncident(thisBIPVT.SurfNum) = 0.0
    thisBIPVT.calculateBIPVTMaxHeatGain(state, tempSetPoint, bypassFraction, potentialHeatGain, potentialOutletTemp, eff, tCollector)
    EXPECT_NEAR(bypassFraction, 1.0, 0.001)
    EXPECT_NEAR(potentialHeatGain, 0.0, 0.01)
    EXPECT_NEAR(potentialOutletTemp, 20.0, 0.01)
    EXPECT_NEAR(eff, 0.0, 0.0001)
    EXPECT_NEAR(tCollector, 15.91, 0.01)
    thisBIPVT.OperatingMode = PhotovoltaicThermalCollectors.PVTMode.Heating
    tempSetPoint = 24.0
    state.dataLoopNodes.Node(InletNode).Temp = -20.0
    state.dataEnvrn.SkyTemp = -20.0
    state.dataEnvrn.OutDryBulbTemp = -20.0
    state.dataHeatBalSurf.SurfTempOut(thisBIPVT.SurfNum) = -18.0
    thisBIPVT.MassFlowRate = 1.0
    state.dataHeatBal.SurfQRadSWOutIncidentBeam(thisBIPVT.SurfNum) = 500.0
    state.dataHeatBal.SurfQRadSWOutIncidentSkyDiffuse(thisBIPVT.SurfNum) = 100.0
    state.dataHeatBal.SurfQRadSWOutIncident(thisBIPVT.SurfNum) = 568.7
    state.dataPhotovoltaic.PVarray(thisBIPVT.PVnum).TRNSYSPVcalc.ArrayEfficiency = 0.22
    thisBIPVT.calculateBIPVTMaxHeatGain(state, tempSetPoint, bypassFraction, potentialHeatGain, potentialOutletTemp, eff, tCollector)
    EXPECT_NEAR(bypassFraction, 0.0, 0.001)
    EXPECT_NEAR(potentialHeatGain, 6832.41, 0.01)
    EXPECT_NEAR(potentialOutletTemp, -13.21, 0.01)
    EXPECT_NEAR(eff, 0.2084, 0.0001)
    EXPECT_NEAR(tCollector, -5.61, 0.01)
    thisBIPVT.OperatingMode = PhotovoltaicThermalCollectors.PVTMode.Heating
    tempSetPoint = 24.0
    state.dataLoopNodes.Node(InletNode).Temp = 10.0  # inlet fluid temperature (DegC)
    state.dataEnvrn.OutDryBulbTemp = 10.0  # ambient temperature (DegC)
    state.dataHeatBalSurf.SurfTempOut(thisBIPVT.SurfNum) = 12.0  # temperature of bldg surface (DegC)
    thisBIPVT.MassFlowRate = 1.0  # fluid mass flow rate (kg/s)
    state.dataHeatBal.SurfQRadSWOutIncidentBeam(thisBIPVT.SurfNum) = 500.0  # Exterior beam solar incident on surface (W/m2)
    state.dataHeatBal.SurfQRadSWOutIncidentSkyDiffuse(thisBIPVT.SurfNum) = 100.0  # Exterior sky diffuse solar incident on surface (W/m2)
    state.dataHeatBal.SurfQRadSWOutIncident(thisBIPVT.SurfNum) = 568.7  # total incident solar radiation
    thisBIPVT.calculateBIPVTMaxHeatGain(state, tempSetPoint, bypassFraction, potentialHeatGain, potentialOutletTemp, eff, tCollector)
    EXPECT_NEAR(bypassFraction, 0.0, 0.001)
    EXPECT_NEAR(potentialHeatGain, 5145.21, 0.01)
    EXPECT_NEAR(potentialOutletTemp, 15.11, 0.01)
    EXPECT_NEAR(eff, 0.1569, 0.0001)
    EXPECT_NEAR(tCollector, 20.24, 0.01)