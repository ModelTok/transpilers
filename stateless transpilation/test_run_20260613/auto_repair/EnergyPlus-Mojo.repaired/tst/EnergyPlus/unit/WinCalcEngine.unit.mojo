from Fixtures.EnergyPlusFixture import EnergyPlusFixture, Test
from Windows-CalcEngine.src.Common.src.FenestrationCommon import FenestrationCommon
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataIPShortCuts import DataIPShortCuts
from EnergyPlus.HeatBalanceManager import HeatBalanceManager
from EnergyPlus.Material import Material
from EnergyPlus.WindowManager import Window
from EnergyPlus.WindowManagerExteriorData import WindowManagerExteriorData
from WCEMultiLayerOptics import WCEMultiLayerOptics

def WCEClear():
    state.dataIPShortCut.lAlphaFieldBlanks = True
    var ErrorsFound: Bool = False
    let idf_objects: String = delimited_string(
        ["WindowsCalculationEngine,",
         "ExternalWindowsModel;",
         "WindowMaterial:Glazing,",
         "Glass_102_LayerAvg,      !- Name",
         "SpectralAverage,         !- Optical Data Type",
         ",                        !- Window Glass Spectral Data Set Name",
         "0.003048,                !- Thickness {m}",
         "0.833848,                !- Solar Transmittance at Normal Incidence",
         "7.476376e-002,           !- Front Side Solar Reflectance at Normal Incidence",
         "7.485449e-002,           !- Back Side Solar Reflectance at Normal Incidence",
         "0.899260,                !- Visible Transmittance at Normal Incidence",
         "0.082563,                !- Front Side Visible Reflectance at Normal Incidence",
         "0.082564,                !- Back Side Visible Reflectance at Normal Incidence",
         "0.000000,                !- Infrared Transmittance at Normal Incidence",
         "0.840000,                !- Front Side Infrared Hemispherical Emissivity",
         "0.840000,                !- Back Side Infrared Hemispherical Emissivity",
         "1.000000;                !- Conductivity {W/m-K}",
         "CONSTRUCTION,",
         "GlzSys_1,                !- Name",
         "Glass_102_LayerAvg;      !- Outside Layer"])
    assert(process_idf(idf_objects))
    Material.GetMaterialData(state, ErrorsFound)
    HeatBalanceManager.GetConstructData(state, ErrorsFound)
    Window.initWindowModel(state)
    Window.InitWindowOpticalCalculations(state)
    HeatBalanceManager.InitHeatBalance(state)
    var aWinConstSimp = Window.CWindowConstructionsSimplified.instance(state)
    var solarLayer = aWinConstSimp.getEquivalentLayer(state, FenestrationCommon.WavelengthRange.Solar, 1)
    alias minLambda: Float64 = 0.3
    alias maxLambda: Float64 = 2.5
    let Tfront = solarLayer.getPropertySimple(
        minLambda, maxLambda, FenestrationCommon.PropertySimple.T, FenestrationCommon.Side.Front, FenestrationCommon.Scattering.DirectDirect)
    assert(abs(Tfront - 0.833848) < 1e-6)
    let Rfront = solarLayer.getPropertySimple(
        minLambda, maxLambda, FenestrationCommon.PropertySimple.R, FenestrationCommon.Side.Front, FenestrationCommon.Scattering.DirectDirect)
    assert(abs(Rfront - 0.074764) < 1e-6)
    let Tback = solarLayer.getPropertySimple(
        minLambda, maxLambda, FenestrationCommon.PropertySimple.T, FenestrationCommon.Side.Back, FenestrationCommon.Scattering.DirectDirect)
    assert(abs(Tback - 0.833848) < 1e-6)
    let Rback = solarLayer.getPropertySimple(
        minLambda, maxLambda, FenestrationCommon.PropertySimple.R, FenestrationCommon.Side.Back, FenestrationCommon.Scattering.DirectDirect)
    assert(abs(Rback - 0.074854) < 1e-6)

def WCEVenetian():
    state.dataIPShortCut.lAlphaFieldBlanks = True
    var ErrorsFound: Bool = False
    let idf_objects: String = delimited_string(
        ["WindowsCalculationEngine,",
         "ExternalWindowsModel;",
         "WindowMaterial:Glazing,",
         "Glass_102_LayerAvg,      !- Name",
         "SpectralAverage,         !- Optical Data Type",
         ",                        !- Window Glass Spectral Data Set Name",
         "0.003048,                !- Thickness {m}",
         "0.833848,                !- Solar Transmittance at Normal Incidence",
         "7.476376e-002,           !- Front Side Solar Reflectance at Normal Incidence",
         "7.485449e-002,           !- Back Side Solar Reflectance at Normal Incidence",
         "0.899260,                !- Visible Transmittance at Normal Incidence",
         "0.082563,                !- Front Side Visible Reflectance at Normal Incidence",
         "0.082564,                !- Back Side Visible Reflectance at Normal Incidence",
         "0.000000,                !- Infrared Transmittance at Normal Incidence",
         "0.840000,                !- Front Side Infrared Hemispherical Emissivity",
         "0.840000,                !- Back Side Infrared Hemispherical Emissivity",
         "1.000000;                !- Conductivity {W/m-K}",
         "CONSTRUCTION,",
         "GlzSys_1_withShade,      !- Name",
         "Glass_102_LayerAvg,      !- Outside Layer",
         "VenBlind_ShdDvc_25;      !- Layer 2",
         "CONSTRUCTION,",
         "GlzSys_1,                !- Name",
         "Glass_102_LayerAvg;      !- Outside Layer",
         "WindowMaterial:Blind,",
         "VenBlind_ShdDvc_25,      !- Name",
         "HORIZONTAL,              !- Slat Orientation",
         "0.016,                   !- Slat Width {m}",
         "0.012,                   !- Slat Separation {m}",
         "0.0006,                  !- Slat Thickness {m}",
         "135,                     !- Slat Angle {deg}",
         "160,                     !- Slat Conductivity {W/m-K}",
         ",                        !- Slat Beam Solar Transmittance",
         "0.7,                     !- Front Side Slat Beam Solar Reflectance",
         "0.7,                     !- Back Side Slat Beam Solar Reflectance",
         "0,                       !- Slat Diffuse Solar Transmittance",
         "0.7,                     !- Front Side Slat Diffuse Solar Reflectance",
         "0.7,                     !- Back Side Slat Diffuse Solar Reflectance",
         "0,                       !- Slat Beam Visible Transmittance",
         "0.7,                     !- Front Side Slat Beam Visible Reflectance",
         "0.7,                     !- Back Side Slat Beam Visible Reflectance",
         "0,                       !- Slat Diffuse Visible Transmittance",
         "0.7,                     !- Front Side Slat Diffuse Visible Reflectance",
         "0.7,                     !- Back Side Slat Diffuse Visible Reflectance",
         "0,                       !- Slat Infrared Hemispherical Transmittance",
         "0.9,                     !- Front Side Slat Infrared Hemispherical Emissivity",
         "0.9,                     !- Back Side Slat Infrared Hemispherical Emissivity",
         "0.0127,                  !- Blind to Glass Distance {m}",
         "0.0,                     !- Blind Top Opening Multiplier",
         "0.0,                     !- Blind Bottom Opening Multiplier",
         "0.0,                     !- Blind Left Side Opening Multiplier",
         "0.0,                     !- Blind Right Side Opening Multiplier",
         "0,                       !- Minimum Slat Angle {deg}",
         "0;                       !- Maximum Slat Angle {deg}"])
    assert(process_idf(idf_objects))
    Material.GetMaterialData(state, ErrorsFound)
    HeatBalanceManager.GetConstructData(state, ErrorsFound)
    Window.initWindowModel(state)
    Window.InitWindowOpticalCalculations(state)
    HeatBalanceManager.InitHeatBalance(state)
    var aWinConstSimp = Window.CWindowConstructionsSimplified.instance(state)
    var solarLayer = aWinConstSimp.getEquivalentLayer(state, FenestrationCommon.WavelengthRange.Solar, 1)
    alias minLambda: Float64 = 0.3
    alias maxLambda: Float64 = 2.5
    let Tfront = solarLayer.getPropertySimple(
        minLambda, maxLambda, FenestrationCommon.PropertySimple.T, FenestrationCommon.Side.Front, FenestrationCommon.Scattering.DirectDirect)
    assert(abs(Tfront - 0.833829) < 1e-6)
    let Rfront = solarLayer.getPropertySimple(
        minLambda, maxLambda, FenestrationCommon.PropertySimple.R, FenestrationCommon.Side.Front, FenestrationCommon.Scattering.DirectDirect)
    assert(abs(Rfront - 0.074764) < 1e-6)
    let Tback = solarLayer.getPropertySimple(
        minLambda, maxLambda, FenestrationCommon.PropertySimple.T, FenestrationCommon.Side.Back, FenestrationCommon.Scattering.DirectDirect)
    assert(abs(Tback - 0.833848) < 1e-6)
    let Rback = solarLayer.getPropertySimple(
        minLambda, maxLambda, FenestrationCommon.PropertySimple.R, FenestrationCommon.Side.Back, FenestrationCommon.Scattering.DirectDirect)
    assert(abs(Rback - 0.074853) < 1e-6)

def WCEShade():
    state.dataIPShortCut.lAlphaFieldBlanks = True
    var ErrorsFound: Bool = False
    let idf_objects: String = delimited_string(
        ["WindowsCalculationEngine,",
         "ExternalWindowsModel;",
         "WindowMaterial:Glazing,",
         "Glass_102_LayerAvg,      !- Name",
         "SpectralAverage,         !- Optical Data Type",
         ",                        !- Window Glass Spectral Data Set Name",
         "0.003048,                !- Thickness {m}",
         "0.833848,                !- Solar Transmittance at Normal Incidence",
         "7.476376e-002,           !- Front Side Solar Reflectance at Normal Incidence",
         "7.485449e-002,           !- Back Side Solar Reflectance at Normal Incidence",
         "0.899260,                !- Visible Transmittance at Normal Incidence",
         "0.082563,                !- Front Side Visible Reflectance at Normal Incidence",
         "0.082564,                !- Back Side Visible Reflectance at Normal Incidence",
         "0.000000,                !- Infrared Transmittance at Normal Incidence",
         "0.840000,                !- Front Side Infrared Hemispherical Emissivity",
         "0.840000,                !- Back Side Infrared Hemispherical Emissivity",
         "1.000000;                !- Conductivity {W/m-K}",
         "CONSTRUCTION,",
         "GlzSys_1_withShade,      !- Name",
         "Glass_102_LayerAvg,      !- Outside Layer",
         "Shade_1;                 !- Layer 2",
         "WindowMaterial:Shade,",
         "Shade_1, !- Name",
         "0.35, !- Solar Transmittance{ dimensionless }",
         "0.2, !- Solar Reflectance{ dimensionless }",
         "0.8, !- Visible Transmittance{ dimensionless }",
         "0.05, !- Visible Reflectance{ dimensionless }",
         "0.9, !- Infrared Hemispherical Emissivity{ dimensionless }",
         "0, !- Infrared Transmittance{ dimensionless }",
         "0.1, !- Thickness{ m }",
         "1, !- Conductivity{ W / m - K }",
         "0.016, !- Shade to Glass Distance{ m }",
         "0.0, !- Top Opening Multiplier",
         "0.0, !- Bottom Opening Multiplier",
         "0.0, !- Left - Side Opening Multiplier",
         "0.0, !- Right - Side Opening Multiplier",
         "0;                       !- Airflow Permeability{ dimensionless }"])
    assert(process_idf(idf_objects))
    Material.GetMaterialData(state, ErrorsFound)
    HeatBalanceManager.GetConstructData(state, ErrorsFound)
    Window.initWindowModel(state)
    Window.InitWindowOpticalCalculations(state)
    HeatBalanceManager.InitHeatBalance(state)
    var aWinConstSimp = Window.CWindowConstructionsSimplified.instance(state)
    var solarLayer = aWinConstSimp.getEquivalentLayer(state, FenestrationCommon.WavelengthRange.Solar, 1)
    alias minLambda: Float64 = 0.3
    alias maxLambda: Float64 = 2.5
    let Tfront_dir_dir = solarLayer.getPropertySimple(
        minLambda, maxLambda, FenestrationCommon.PropertySimple.T, FenestrationCommon.Side.Front, FenestrationCommon.Scattering.DirectDirect)
    assert(abs(Tfront_dir_dir - 0.0) < 1e-6)
    let Tfront_dif = solarLayer.getPropertySimple(
        minLambda, maxLambda, FenestrationCommon.PropertySimple.T, FenestrationCommon.Side.Front, FenestrationCommon.Scattering.DiffuseDiffuse)
    assert(abs(Tfront_dif - 0.296282) < 1e-6)
    let Rfront = solarLayer.getPropertySimple(
        minLambda, maxLambda, FenestrationCommon.PropertySimple.R, FenestrationCommon.Side.Front, FenestrationCommon.Scattering.DirectDirect)
    assert(abs(Rfront - 0.074764) < 1e-6)
    let Tback = solarLayer.getPropertySimple(
        minLambda, maxLambda, FenestrationCommon.PropertySimple.T, FenestrationCommon.Side.Back, FenestrationCommon.Scattering.DirectDirect)
    assert(abs(Tback - 0.0) < 1e-6)
    let Rback = solarLayer.getPropertySimple(
        minLambda, maxLambda, FenestrationCommon.PropertySimple.R, FenestrationCommon.Side.Back, FenestrationCommon.Scattering.DirectDirect)
    assert(abs(Rback - 0.0) < 1e-6)