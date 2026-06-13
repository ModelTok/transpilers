from .Fixtures.EnergyPlusFixture import process_idf, EnergyPlusData, state
from EnergyPlus.Material import Material, GetMaterialData, GetMaterialNum
from EnergyPlus.Construction import ConstructionProps
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataEnvironment import DataEnvironment
from EnergyPlus.DataGlobals import DataGlobals
from EnergyPlus.DataHeatBalSurface import DataHeatBalSurface
from EnergyPlus.DataMoistureBalance import DataMoistureBalance
from EnergyPlus.DataMoistureBalanceEMPD import DataMoistureBalanceEMPD
from EnergyPlus.DataSurfaces import DataSurfaces, SurfaceData
from EnergyPlus.HeatBalanceManager import HeatBalanceManager
from EnergyPlus.IOFiles import IOFiles
from EnergyPlus.MoistureBalanceEMPDManager import MoistureBalanceEMPDManager, MaterialEMPD
from EnergyPlus.Psychrometrics import PsyRhFnTdbRhov
from EnergyPlus.ZoneTempPredictorCorrector import ZoneTempPredictorCorrector

from testing import assert_equal, assert_almost_equal, assert_true, assert_false

def delimited_string(parts: List[String]) -> String:
    """

    """
    return "\n".join(parts) + "\n"

def test_CheckEMPDCalc():
    var idf_objects: String = delimited_string([
        "Material,",
        "Concrete,                !- Name",
        "Rough,                   !- Roughness",
        "0.152,                   !- Thickness {m}",
        "0.3,                     !- Conductivity {W/m-K}",
        "1000,                    !- Density {kg/m3}",
        "950,                     !- Specific Heat {J/kg-K}",
        "0.900000,                !- Thermal Absorptance",
        "0.600000,                !- Solar Absorptance",
        "0.600000;                !- Visible Absorptance",
        "MaterialProperty:MoisturePenetrationDepth:Settings,",
        "Concrete,                !- Name",
        "6.554,                     !- Water Vapor Diffusion Resistance Factor {dimensionless} (mu)",
        "0.0661,                   !- Moisture Equation Coefficient a {dimensionless} (MoistACoeff)",
        "1,                       !- Moisture Equation Coefficient b {dimensionless} (MoistBCoeff)",
        "0,                       !- Moisture Equation Coefficient c {dimensionless} (MoistCCoeff)",
        "1,                       !- Moisture Equation Coefficient d {dimensionless} (MoistDCoeff)",
        "0.006701,                    !- Surface-layer penetration depth {m} (dEMPD)",
        "0.013402,                    !- Deep-layer penetration depth {m} (dEPMDdeep)",
        "0,                       !- Coating layer permeability {m} (CoatingThickness)",
        "1;                       !- Coating layer water vapor diffusion resistance factor {dimensionless} (muCoating)"
    ])
    assert_true(process_idf(idf_objects))
    var errors_found: Bool = False
    Material.GetMaterialData(state, errors_found)
    assert_false(errors_found, "Errors in GetMaterialData")
    state.dataSurface.TotSurfaces = 1
    state.dataSurface.Surface.allocate(state.dataSurface.TotSurfaces)
    var surface: SurfaceData = state.dataSurface.Surface[0]
    surface.Name = "Surface1"
    surface.Area = 1.0
    surface.HeatTransSurf = True
    surface.Zone = 1
    state.dataMstBal.RhoVaporAirIn.allocate(1)
    state.dataMstBal.HMassConvInFD.allocate(1)
    state.dataZoneTempPredictorCorrector.zoneHeatBalance.allocate(1)
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].MAT = 20.0
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].airHumRat = 0.0061285406810457849
    surface.Construction = 1
    state.dataConstruction.Construct.allocate(1)
    var construction: ConstructionProps = state.dataConstruction.Construct[0]
    construction.TotLayers = 1
    construction.LayerPoint[construction.TotLayers - 1] = Material.GetMaterialNum(state, "CONCRETE")
    MoistureBalanceEMPDManager.InitMoistureBalanceEMPD(state)
    state.dataGlobal.TimeStepZone = 0.25
    state.dataEnvrn.OutBaroPress = 101325.0
    state.dataMstBalEMPD.RVSurface[0] = 0.007077173214149593
    state.dataMstBalEMPD.RVSurfaceOld[0] = state.dataMstBalEMPD.RVSurface[0]
    state.dataMstBal.HMassConvInFD[0] = 0.0016826898264131584
    state.dataMstBal.RhoVaporAirIn[0] = 0.0073097913062508896
    state.dataMstBalEMPD.RVSurfLayer[0] = 0.007038850125652322
    state.dataMstBalEMPD.RVDeepLayer[0] = 0.0051334905162138695
    state.dataMstBalEMPD.RVdeepOld[0] = 0.0051334905162138695
    state.dataMstBalEMPD.RVSurfLayerOld[0] = 0.007038850125652322
    var Tsat: Float64 = 0.0
    MoistureBalanceEMPDManager.CalcMoistureBalanceEMPD(state, 1, 19.907302679986064, 19.901185713164697, Tsat)
    var report_vars = state.dataMoistureBalEMPD.EMPDReportVars[0]
    assert_equal(6.3445188238394508, Tsat)
    assert_equal(0.0071762141417078054, state.dataMstBalEMPD.RVSurface[0])
    assert_equal(0.00000076900234067835945, report_vars.mass_flux_deep)
    assert_equal(-0.00000019077843350248091, report_vars.mass_flux_zone)
    assert_equal(0.0070186500259181136, state.dataMstBalEMPD.RVSurfLayer[0])
    assert_equal(0.0051469229632164605, state.dataMstBalEMPD.RVDeepLayer[0])
    assert_equal(-0.47694608375620229, state.dataMstBalEMPD.HeatFluxLatent[0])

def test_EMPDAutocalcDepth():
    var idf_objects: String = delimited_string([
        "Material,",
        "Concrete,                !- Name",
        "Rough,                   !- Roughness",
        "0.152,                   !- Thickness {m}",
        "0.3,                     !- Conductivity {W/m-K}",
        "850,                     !- Density {kg/m3}",
        "950,                     !- Specific Heat {J/kg-K}",
        "0.900000,                !- Thermal Absorptance",
        "0.600000,                !- Solar Absorptance",
        "0.600000;                !- Visible Absorptance",
        "MaterialProperty:MoisturePenetrationDepth:Settings,",
        "Concrete,                !- Name",
        "8,                     !- Water Vapor Diffusion Resistance Factor {dimensionless} (mu)",
        "0.012,                   !- Moisture Equation Coefficient a {dimensionless} (MoistACoeff)",
        "1,                       !- Moisture Equation Coefficient b {dimensionless} (MoistBCoeff)",
        "0,                       !- Moisture Equation Coefficient c {dimensionless} (MoistCCoeff)",
        "1,                       !- Moisture Equation Coefficient d {dimensionless} (MoistDCoeff)",
        ",                    !- Surface-layer penetration depth {m} (dEMPD)",
        "autocalculate,                    !- Deep-layer penetration depth {m} (dEPMDdeep)",
        "0,                       !- Coating layer permeability {m} (CoatingThickness)",
        "1;                       !- Coating layer water vapor diffusion resistance factor {dimensionless} (muCoating)"
    ])
    assert_true(process_idf(idf_objects))
    var errors_found: Bool = False
    Material.GetMaterialData(state, errors_found)
    assert_false(errors_found, "Errors in GetMaterialData")
    MoistureBalanceEMPDManager.GetMoistureBalanceEMPDInput(state)
    var matEMPD: MaterialEMPD = state.dataMaterial.materials[0] as MaterialEMPD
    assert_approx_equal(matEMPD.surfaceDepth, 0.014143, 0.000001)
    assert_approx_equal(matEMPD.deepDepth, 0.064810, 0.000001)

def test_EMPDRe_Coating():
    var idf_objects: String = delimited_string([
        "Material,",
        "Concrete,                !- Name",
        "Rough,                   !- Roughness",
        "0.152,                   !- Thickness {m}",
        "0.3,                     !- Conductivity {W/m-K}",
        "1000,                    !- Density {kg/m3}",
        "950,                     !- Specific Heat {J/kg-K}",
        "0.900000,                !- Thermal Absorptance",
        "0.600000,                !- Solar Absorptance",
        "0.600000;                !- Visible Absorptance",
        "MaterialProperty:MoisturePenetrationDepth:Settings,",
        "Concrete,                !- Name",
        "6.554,                     !- Water Vapor Diffusion Resistance Factor {dimensionless} (mu)",
        "0.0661,                   !- Moisture Equation Coefficient a {dimensionless} (MoistACoeff)",
        "1,                       !- Moisture Equation Coefficient b {dimensionless} (MoistBCoeff)",
        "0,                       !- Moisture Equation Coefficient c {dimensionless} (MoistCCoeff)",
        "1,                       !- Moisture Equation Coefficient d {dimensionless} (MoistDCoeff)",
        "0.006701,                    !- Surface-layer penetration depth {m} (dEMPD)",
        "0.013402,                    !- Deep-layer penetration depth {m} (dEPMDdeep)",
        "0.002,                       !- Coating layer permeability {m} (CoatingThickness)",
        "1;                       !- Coating layer water vapor diffusion resistance factor {dimensionless} (muCoating)"
    ])
    assert_true(process_idf(idf_objects))
    var errors_found: Bool = False
    Material.GetMaterialData(state, errors_found)
    assert_false(errors_found, "Errors in GetMaterialData")
    state.dataSurface.TotSurfaces = 1
    state.dataSurface.Surface.allocate(state.dataSurface.TotSurfaces)
    var surface: SurfaceData = state.dataSurface.Surface[0]
    surface.Name = "Surface1"
    surface.Area = 1.0
    surface.HeatTransSurf = True
    surface.Zone = 1
    state.dataMstBal.RhoVaporAirIn.allocate(1)
    state.dataMstBal.HMassConvInFD.allocate(1)
    state.dataZoneTempPredictorCorrector.zoneHeatBalance.allocate(1)
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].MAT = 20.0
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].airHumRat = 0.0061285406810457849
    surface.Construction = 1
    state.dataConstruction.Construct.allocate(1)
    var construction: ConstructionProps = state.dataConstruction.Construct[0]
    construction.TotLayers = 1
    construction.LayerPoint[construction.TotLayers - 1] = Material.GetMaterialNum(state, "CONCRETE")
    MoistureBalanceEMPDManager.InitMoistureBalanceEMPD(state)
    state.dataGlobal.TimeStepZone = 0.25
    state.dataEnvrn.OutBaroPress = 101325.0
    state.dataMstBalEMPD.RVSurface[0] = 0.007077173214149593
    state.dataMstBalEMPD.RVSurfaceOld[0] = state.dataMstBalEMPD.RVSurface[0]
    state.dataMstBal.HMassConvInFD[0] = 0.0016826898264131584
    state.dataMstBal.RhoVaporAirIn[0] = 0.0073097913062508896
    state.dataMstBalEMPD.RVSurfLayer[0] = 0.007038850125652322
    state.dataMstBalEMPD.RVDeepLayer[0] = 0.0051334905162138695
    state.dataMstBalEMPD.RVdeepOld[0] = 0.0051334905162138695
    state.dataMstBalEMPD.RVSurfLayerOld[0] = 0.007038850125652322
    var Tsat: Float64 = 0.0
    MoistureBalanceEMPDManager.CalcMoistureBalanceEMPD(state, 1, 19.907302679986064, 19.901185713164697, Tsat)
    var report_vars = state.dataMoistureBalEMPD.EMPDReportVars[0]
    assert_equal(6.3445188238394508, Tsat)
    assert_equal(0.0071815819413115663, state.dataMstBalEMPD.RVSurface[0])
    assert_equal(0.00000076900234067835945, report_vars.mass_flux_deep)
    assert_equal(-1.8118197009111738e-07, report_vars.mass_flux_zone)
    assert_equal(0.0070183147759991828, state.dataMstBalEMPD.RVSurfLayer[0])
    assert_equal(0.0051469229632164605, state.dataMstBalEMPD.RVDeepLayer[0])
    assert_equal(-0.45295492522779346, state.dataMstBalEMPD.HeatFluxLatent[0])

def test_CheckEMPDCalc_Slope():
    var idf_objects: String = delimited_string([
        "Material,",
        "WOOD,                    !- Name",
        "MediumSmooth,            !- Roughness",
        "1.9099999E-02,           !- Thickness {m}",
        "0.1150000,               !- Conductivity {W/m-K}",
        "513.0000,                !- Density {kg/m3}",
        "1381.000,                !- Specific Heat {J/kg-K}",
        "0.900000,                !- Thermal Absorptance",
        "0.780000,                !- Solar Absorptance",
        "0.780000;                !- Visible Absorptance",
        "MaterialProperty:MoisturePenetrationDepth:Settings,",
        "WOOD,                    !- Name",
        "150,                     !- Water Vapor Diffusion Resistance Factor {dimensionless} (mu)",
        "0.204,                   !- Moisture Equation Coefficient a {dimensionless} (MoistACoeff)",
        "2.32,                    !- Moisture Equation Coefficient b {dimensionless} (MoistBCoeff)",
        "0.43,                    !- Moisture Equation Coefficient c {dimensionless} (MoistCCoeff)",
        "72,                      !- Moisture Equation Coefficient d {dimensionless} (MoistDCoeff)",
        "0.0011,                  !- Surface-layer penetration depth {m} (dEMPD)",
        "0.004,                   !- Deep-layer penetration depth {m} (dEPMDdeep)",
        "0,                       !- Coating layer permeability {m} (CoatingThickness)",
        "0;                       !- Coating layer water vapor diffusion resistance factor {dimensionless} (muCoating)"
    ])
    assert_true(process_idf(idf_objects))
    var errors_found: Bool = False
    Material.GetMaterialData(state, errors_found)
    assert_false(errors_found, "Errors in GetMaterialData")
    var surfNum: Int = 1
    state.dataSurface.TotSurfaces = 1
    state.dataSurface.Surface.allocate(state.dataSurface.TotSurfaces)
    var surface: SurfaceData = state.dataSurface.Surface[surfNum - 1]
    surface.Name = "SurfaceWood"
    surface.Area = 1.0
    surface.HeatTransSurf = True
    var zoneNum: Int = 1
    surface.Zone = zoneNum
    state.dataMstBal.RhoVaporAirIn.allocate(surfNum)
    state.dataMstBal.HMassConvInFD.allocate(surfNum)
    state.dataZoneTempPredictorCorrector.zoneHeatBalance.allocate(zoneNum)
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[zoneNum - 1].MAT = 20.0
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[zoneNum - 1].airHumRat = 0.0061285406810457849
    var constNum: Int = 1
    surface.Construction = constNum
    state.dataConstruction.Construct.allocate(constNum)
    var construction: ConstructionProps = state.dataConstruction.Construct[constNum - 1]
    construction.TotLayers = constNum
    construction.LayerPoint[construction.TotLayers - 1] = Material.GetMaterialNum(state, "WOOD")
    MoistureBalanceEMPDManager.InitMoistureBalanceEMPD(state)
    state.dataGlobal.TimeStepZone = 0.25
    state.dataEnvrn.OutBaroPress = 101325.0
    state.dataMstBalEMPD.RVSurface[surfNum - 1] = 0.0070277983586713262
    state.dataMstBalEMPD.RVSurfaceOld[surfNum - 1] = state.dataMstBalEMPD.RVSurface[surfNum - 1]
    state.dataMstBal.HMassConvInFD[surfNum - 1] = 0.0016826898264131584
    state.dataMstBal.RhoVaporAirIn[surfNum - 1] = 0.0073097913062508896
    state.dataMstBalEMPD.RVSurfLayer[surfNum - 1] = 0.0070277983586713262
    state.dataMstBalEMPD.RVDeepLayer[surfNum - 1] = 0.0051402944814058216
    state.dataMstBalEMPD.RVdeepOld[surfNum - 1] = 0.0051402944814058216
    state.dataMstBalEMPD.RVSurfLayerOld[surfNum - 1] = 0.0070277983586713262
    var matEMPD: MaterialEMPD = state.dataMaterial.materials[0] as MaterialEMPD
    var Tsat: Float64 = 0.0
    state.dataHeatBalSurf.SurfTempIn.allocate(surfNum)
    state.dataHeatBalSurf.SurfTempIn[surfNum - 1] = 20.0
    var Taver: Float64 = state.dataHeatBalSurf.SurfTempIn[surfNum - 1]
    var RV_Deep_Old: Float64 = state.dataMstBalEMPD.RVdeepOld[surfNum - 1]
    var RVaver: Float64 = state.dataMstBalEMPD.RVSurfLayerOld[surfNum - 1]
    var RHaver: Float64 = RVaver * 461.52 * (Taver + 273.15) * exp(-23.7093 + 4111.0 / (Taver + 237.7))
    var dU_dRH: Float64 = matEMPD.moistACoeff * matEMPD.moistBCoeff * pow(RHaver, matEMPD.moistBCoeff - 1) + matEMPD.moistCCoeff * matEMPD.moistDCoeff * pow(RHaver, matEMPD.moistDCoeff - 1)
    var RH_deep_layer_old: Float64 = PsyRhFnTdbRhov(state, Taver, RV_Deep_Old)
    var RH_surf_layer_old: Float64 = PsyRhFnTdbRhov(state, Taver, RVaver)
    var mass_flux_surf_deep_max: Float64 = matEMPD.deepDepth * matEMPD.Density * dU_dRH * (RH_surf_layer_old - RH_deep_layer_old) / (state.dataGlobal.TimeStepZone * 3600.0)
    var hm_deep_layer: Float64 = 6.9551289450635225e-05
    var mass_flux_surf_deep_result: Float64 = hm_deep_layer * (RVaver - RV_Deep_Old)
    if abs(mass_flux_surf_deep_max) < abs(mass_flux_surf_deep_result):
        mass_flux_surf_deep_result = mass_flux_surf_deep_max
    MoistureBalanceEMPDManager.CalcMoistureBalanceEMPD(state, 1, Taver, Taver, Tsat)
    var report_vars = state.dataMoistureBalEMPD.EMPDReportVars[surfNum - 1]
    assert_equal(mass_flux_surf_deep_result, report_vars.mass_flux_deep)