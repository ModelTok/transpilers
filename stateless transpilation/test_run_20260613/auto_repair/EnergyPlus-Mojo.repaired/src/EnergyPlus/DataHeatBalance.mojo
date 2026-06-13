from cmath import *
from format import *  # Not needed in Mojo, but kept for verbatim
from ObjexxFCL.Array.functions import *
from ObjexxFCL.Fmath import *
from EnergyPlus.Construction import *
from EnergyPlus.Data.EnergyPlusData import *
from EnergyPlus.DataEnvironment import *
from EnergyPlus.DataHeatBalSurface import *
from EnergyPlus.DataHeatBalance import *  # For types defined in header
from EnergyPlus.DataSurfaces import *
from EnergyPlus.DaylightingManager import *
from EnergyPlus.Material import *
from EnergyPlus.OutputProcessor import *
from EnergyPlus.UtilityRoutines import *
from DataVectorTypes import *
from DataBSDFWindow import BSDFLayerAbsorpStruct, BSDFWindowInputStruct

namespace EnergyPlus.DataHeatBalance:

    impl SpaceData:
        def sumHATsurf(self, state: EnergyPlusData) -> Real64:
            var sumHATsurf: Real64 = 0.0
            for surfNum in range(self.HTSurfaceFirst, self.HTSurfaceLast + 1):
                var Area: Real64 = state.dataSurface.Surface[surfNum - 1].Area
                if state.dataSurface.Surface[surfNum - 1].Class == DataSurfaces.SurfaceClass.Window:
                    if state.dataSurface.SurfWinDividerArea[surfNum - 1] > 0.0:
                        if ANY_INTERIOR_SHADE_BLIND(state.dataSurface.SurfWinShadingFlag[surfNum - 1]):
                            Area += state.dataSurface.SurfWinDividerArea[surfNum - 1]
                        else:
                            sumHATsurf += state.dataHeatBalSurf.SurfHConvInt[surfNum - 1] * state.dataSurface.SurfWinDividerArea[surfNum - 1] * \
                                          (1.0 + 2.0 * state.dataSurface.SurfWinProjCorrDivIn[surfNum - 1]) * state.dataSurface.SurfWinDividerTempIn[surfNum - 1]
                    if state.dataSurface.SurfWinFrameArea[surfNum - 1] > 0.0:
                        sumHATsurf += state.dataHeatBalSurf.SurfHConvInt[surfNum - 1] * state.dataSurface.SurfWinFrameArea[surfNum - 1] * \
                                      (1.0 + state.dataSurface.SurfWinProjCorrFrIn[surfNum - 1]) * state.dataSurface.SurfWinFrameTempIn[surfNum - 1]
                sumHATsurf += state.dataHeatBalSurf.SurfHConvInt[surfNum - 1] * Area * state.dataHeatBalSurf.SurfTempInTmp[surfNum - 1]
            return sumHATsurf

    impl ZoneData:
        def sumHATsurf(self, state: EnergyPlusData) -> Real64:
            var sumHATsurf: Real64 = 0.0
            for spaceNum in self.spaceIndexes:
                sumHATsurf += state.dataHeatBal.space[spaceNum - 1].sumHATsurf(state)
            return sumHATsurf

        def SetOutBulbTempAt(self, state: EnergyPlusData):
            if state.dataEnvrn.SiteTempGradient == 0.0:
                self.OutDryBulbTemp = state.dataEnvrn.OutDryBulbTemp
                self.OutWetBulbTemp = state.dataEnvrn.OutWetBulbTemp
            else:
                var BaseDryTemp: Real64 = state.dataEnvrn.OutDryBulbTemp + state.dataEnvrn.WeatherFileTempModCoeff
                var BaseWetTemp: Real64 = state.dataEnvrn.OutWetBulbTemp + state.dataEnvrn.WeatherFileTempModCoeff
                var Z: Real64 = self.Centroid.z
                if Z <= 0.0:
                    self.OutDryBulbTemp = BaseDryTemp
                    self.OutWetBulbTemp = BaseWetTemp
                else:
                    self.OutDryBulbTemp = BaseDryTemp - state.dataEnvrn.SiteTempGradient * DataEnvironment.EarthRadius * Z / (DataEnvironment.EarthRadius + Z)
                    self.OutWetBulbTemp = BaseWetTemp - state.dataEnvrn.SiteTempGradient * DataEnvironment.EarthRadius * Z / (DataEnvironment.EarthRadius + Z)

        def SetWindSpeedAt(self, state: EnergyPlusData, fac: Real64):
            if state.dataEnvrn.SiteWindExp == 0.0:
                self.WindSpeed = state.dataEnvrn.WindSpeed
            else:
                var Z: Real64 = self.Centroid.z
                if Z <= 0.0:
                    self.WindSpeed = 0.0
                else:
                    self.WindSpeed = fac * pow(Z, state.dataEnvrn.SiteWindExp)

        def SetWindDirAt(self, fac: Real64):
            self.WindDir = fac

    impl AirReportVars:
        def setUpOutputVars(self, state: EnergyPlusData, prefix: String, name: String):
            SetupOutputVariable(state,
                                "{} Mean Air Temperature".format(prefix),
                                Constant.Units.C,
                                self.MeanAirTemp,
                                OutputProcessor.TimeStepType.Zone,
                                OutputProcessor.StoreType.Average,
                                name)
            SetupOutputVariable(state,
                                "{} Wetbulb Globe Temperature".format(prefix),
                                Constant.Units.C,
                                self.WetbulbGlobeTemp,
                                OutputProcessor.TimeStepType.Zone,
                                OutputProcessor.StoreType.Average,
                                name)
            SetupOutputVariable(state,
                                "{} Operative Temperature".format(prefix),
                                Constant.Units.C,
                                self.OperativeTemp,
                                OutputProcessor.TimeStepType.Zone,
                                OutputProcessor.StoreType.Average,
                                name)
            SetupOutputVariable(state,
                                "{} Mean Air Dewpoint Temperature".format(prefix),
                                Constant.Units.C,
                                self.MeanAirDewPointTemp,
                                OutputProcessor.TimeStepType.Zone,
                                OutputProcessor.StoreType.Average,
                                name)
            SetupOutputVariable(state,
                                "{} Mean Air Humidity Ratio".format(prefix),
                                Constant.Units.kgWater_kgDryAir,
                                self.MeanAirHumRat,
                                OutputProcessor.TimeStepType.Zone,
                                OutputProcessor.StoreType.Average,
                                name)
            SetupOutputVariable(state,
                                "{} Air Heat Balance Internal Convective Heat Gain Rate".format(prefix),
                                Constant.Units.W,
                                self.SumIntGains,
                                OutputProcessor.TimeStepType.System,
                                OutputProcessor.StoreType.Average,
                                name)
            SetupOutputVariable(state,
                                "{} Air Heat Balance Surface Convection Rate".format(prefix),
                                Constant.Units.W,
                                self.SumHADTsurfs,
                                OutputProcessor.TimeStepType.System,
                                OutputProcessor.StoreType.Average,
                                name)
            SetupOutputVariable(state,
                                "{} Air Heat Balance Interzone Air Transfer Rate".format(prefix),
                                Constant.Units.W,
                                self.SumMCpDTzones,
                                OutputProcessor.TimeStepType.System,
                                OutputProcessor.StoreType.Average,
                                name)
            SetupOutputVariable(state,
                                "{} Air Heat Balance Outdoor Air Transfer Rate".format(prefix),
                                Constant.Units.W,
                                self.SumMCpDtInfil,
                                OutputProcessor.TimeStepType.System,
                                OutputProcessor.StoreType.Average,
                                name)
            SetupOutputVariable(state,
                                "{} Air Heat Balance System Air Transfer Rate".format(prefix),
                                Constant.Units.W,
                                self.SumMCpDTsystem,
                                OutputProcessor.TimeStepType.System,
                                OutputProcessor.StoreType.Average,
                                name)
            SetupOutputVariable(state,
                                "{} Air Heat Balance System Convective Heat Gain Rate".format(prefix),
                                Constant.Units.W,
                                self.SumNonAirSystem,
                                OutputProcessor.TimeStepType.System,
                                OutputProcessor.StoreType.Average,
                                name)
            SetupOutputVariable(state,
                                "{} Air Heat Balance Air Energy Storage Rate".format(prefix),
                                Constant.Units.W,
                                self.CzdTdt,
                                OutputProcessor.TimeStepType.System,
                                OutputProcessor.StoreType.Average,
                                name)
            if state.dataGlobal.DisplayAdvancedReportVariables:
                SetupOutputVariable(state,
                                    "{} Air Heat Balance Deviation Rate".format(prefix),
                                    Constant.Units.W,
                                    self.imBalance,
                                    OutputProcessor.TimeStepType.System,
                                    OutputProcessor.StoreType.Average,
                                    name)

    def SetZoneOutBulbTempAt(state: EnergyPlusData):
        for zone in state.dataHeatBal.Zone:
            zone.SetOutBulbTempAt(state)

    def CheckZoneOutBulbTempAt(state: EnergyPlusData):
        using DataEnvironment.SetOutBulbTempAt_error
        var minBulb: Real64 = 0.0
        for zone in state.dataHeatBal.Zone:
            minBulb = min(minBulb, zone.OutDryBulbTemp, zone.OutWetBulbTemp)
            if minBulb < -100.0:
                SetOutBulbTempAt_error(state, "Zone", zone.Centroid.z, zone.Name)

    def SetZoneWindSpeedAt(state: EnergyPlusData):
        var fac: Real64 = state.dataEnvrn.WindSpeed * state.dataEnvrn.WeatherFileWindModCoeff * \
                          pow(state.dataEnvrn.SiteWindBLHeight, -state.dataEnvrn.SiteWindExp)
        for zone in state.dataHeatBal.Zone:
            zone.SetWindSpeedAt(state, fac)

    def SetZoneWindDirAt(state: EnergyPlusData):
        var fac: Real64 = state.dataEnvrn.WindDir
        for zone in state.dataHeatBal.Zone:
            zone.SetWindDirAt(fac)

    def CheckAndSetConstructionProperties(state: EnergyPlusData,
                                         ConstrNum: Int,  # Construction number to be set/checked
                                         ErrorsFound: Bool  # error flag that is set when certain errors have occurred
    ):
        var s_mat = state.dataMaterial
        var thisConstruct = state.dataConstruction.Construct[ConstrNum - 1]
        var TotLayers: Int = thisConstruct.TotLayers
        if TotLayers == 0:
            return
        var InsideLayer: Int = TotLayers
        if thisConstruct.LayerPoint[InsideLayer - 1] <= 0:
            return
        thisConstruct.DayltPropPtr = 0
        var InsideMaterNum: Int = thisConstruct.LayerPoint[InsideLayer - 1]
        if InsideMaterNum != 0:
            var mat = s_mat.materials[InsideMaterNum - 1]
            thisConstruct.InsideAbsorpVis = mat.AbsorpVisible
            thisConstruct.InsideAbsorpSolar = mat.AbsorpSolar
            thisConstruct.ReflectVisDiffBack = 1.0 - mat.AbsorpVisible
        var OutsideMaterNum: Int = thisConstruct.LayerPoint[0]
        if OutsideMaterNum != 0:
            var mat = s_mat.materials[OutsideMaterNum - 1]
            thisConstruct.OutsideAbsorpVis = mat.AbsorpVisible
            thisConstruct.OutsideAbsorpSolar = mat.AbsorpSolar
        thisConstruct.TotSolidLayers = 0
        thisConstruct.TotGlassLayers = 0
        thisConstruct.AbsDiffShade = 0.0
        thisConstruct.TypeIsWindow = False
        for Layer in range(1, TotLayers + 1):
            var MaterNum: Int = thisConstruct.LayerPoint[Layer - 1]
            if MaterNum == 0:
                continue
            var mat = s_mat.materials[MaterNum - 1]
            thisConstruct.TypeIsWindow = (
                mat.group == Material.Group.Glass or mat.group == Material.Group.Gas or mat.group == Material.Group.GasMixture or
                mat.group == Material.Group.Shade or mat.group == Material.Group.Blind or mat.group == Material.Group.Screen or
                mat.group == Material.Group.GlassSimple or mat.group == Material.Group.ComplexShade or
                mat.group == Material.Group.ComplexWindowGap or mat.group == Material.Group.GlassEQL or mat.group == Material.Group.ShadeEQL or
                mat.group == Material.Group.DrapeEQL or mat.group == Material.Group.ScreenEQL or mat.group == Material.Group.BlindEQL or
                mat.group == Material.Group.WindowGapEQL)
            var TypeIsNotWindow: Bool = (
                mat.group == Material.Group.Invalid or mat.group == Material.Group.AirGap or mat.group == Material.Group.Regular or
                mat.group == Material.Group.EcoRoof or mat.group == Material.Group.IRTransparent)
            if not thisConstruct.TypeIsWindow and not TypeIsNotWindow:
                assert(False)
        if InsideMaterNum == 0:
            return
        var matInside = s_mat.materials[InsideMaterNum - 1]
        if OutsideMaterNum == 0:
            return
        var matOutside = s_mat.materials[OutsideMaterNum - 1]
        if thisConstruct.TypeIsWindow:
            var WrongMaterialsMix: Bool = False
            thisConstruct.NumCTFTerms = 0
            thisConstruct.NumHistories = 0
            for Layer in range(1, TotLayers + 1):
                var MaterNum: Int = thisConstruct.LayerPoint[Layer - 1]
                if MaterNum == 0:
                    continue
                var mat = s_mat.materials[MaterNum - 1]
                WrongMaterialsMix = not (
                    (mat.group == Material.Group.Glass) or (mat.group == Material.Group.Gas) or (mat.group == Material.Group.GasMixture) or
                    (mat.group == Material.Group.Shade) or (mat.group == Material.Group.Blind) or (mat.group == Material.Group.Screen) or
                    (mat.group == Material.Group.GlassSimple) or (mat.group == Material.Group.ComplexShade) or
                    (mat.group == Material.Group.ComplexWindowGap) or (mat.group == Material.Group.GlassEQL) or
                    (mat.group == Material.Group.ShadeEQL) or (mat.group == Material.Group.DrapeEQL) or
                    (mat.group == Material.Group.ScreenEQL) or (mat.group == Material.Group.BlindEQL) or
                    (mat.group == Material.Group.WindowGapEQL))
            if WrongMaterialsMix:
                ShowSevereError(state,
                                "Error: Window construction={} has materials other than glass, gas, shade, screen, blind, complex shading, complex gap, or simple system.".format(thisConstruct.Name))
                ErrorsFound = True
            elif (TotLayers > 8) and (not thisConstruct.WindowTypeBSDF) and (not thisConstruct.WindowTypeEQL):
                ShowSevereError(state,
                                "CheckAndSetConstructionProperties: Window construction={} has too many layers (max of 8 allowed -- 4 glass + 3 gap + 1 shading device).".format(thisConstruct.Name))
                ErrorsFound = True
            elif TotLayers == 1:
                var mat = s_mat.materials[thisConstruct.LayerPoint[0] - 1]
                var matGroup: Material.Group = mat.group
                if (matGroup == Material.Group.Shade) or (matGroup == Material.Group.Gas) or (matGroup == Material.Group.GasMixture) or \
                   (matGroup == Material.Group.Blind) or (matGroup == Material.Group.Screen) or (matGroup == Material.Group.ComplexShade) or \
                   (matGroup == Material.Group.ComplexWindowGap):
                    ShowSevereError(state,
                                    "CheckAndSetConstructionProperties: The single-layer window construction={} has a gas, complex gap, shade, complex shade, screen or blind material; it should be glass of simple glazing system.".format(thisConstruct.Name))
                    ErrorsFound = True
            var WrongWindowLayering: Bool = False
            var TotGlassLayers: Int = 0
            var TotShadeLayers: Int = 0
            var TotGasLayers: Int = 0
            for Layer in range(1, TotLayers + 1):
                var MaterNum: Int = thisConstruct.LayerPoint[Layer - 1]
                if MaterNum == 0:
                    continue
                var mat = s_mat.materials[MaterNum - 1]
                if mat.group == Material.Group.Glass:
                    TotGlassLayers += 1
                if mat.group == Material.Group.GlassSimple:
                    TotGlassLayers += 1
                if mat.group == Material.Group.Shade or mat.group == Material.Group.Blind or mat.group == Material.Group.Screen or \
                   mat.group == Material.Group.ComplexShade:
                    TotShadeLayers += 1
                if mat.group == Material.Group.Gas or mat.group == Material.Group.GasMixture or mat.group == Material.Group.ComplexWindowGap:
                    TotGasLayers += 1
                if Layer < TotLayers:
                    var MaterNumNext: Int = thisConstruct.LayerPoint[Layer]  # Layer+1 -> index Layer (0-based)
                    if MaterNumNext == 0:
                        continue
                    if mat.group == s_mat.materials[MaterNumNext - 1].group:
                        WrongWindowLayering = True
            if thisConstruct.WindowTypeBSDF:
                thisConstruct.TotGlassLayers = TotGlassLayers
                thisConstruct.TotSolidLayers = TotGlassLayers + TotShadeLayers
                thisConstruct.InsideAbsorpThermal = matInside.AbsorpThermalBack
                thisConstruct.OutsideAbsorpThermal = matOutside.AbsorpThermalFront
                return
            if thisConstruct.WindowTypeEQL:
                thisConstruct.InsideAbsorpThermal = matInside.AbsorpThermalBack
                thisConstruct.OutsideAbsorpThermal = matOutside.AbsorpThermalFront
                return
            if matOutside.group == Material.Group.Gas or matOutside.group == Material.Group.GasMixture or \
               matInside.group == Material.Group.Gas or matInside.group == Material.Group.GasMixture:
                WrongWindowLayering = True
            if TotShadeLayers > 1:
                WrongWindowLayering = True
            for Layer in range(1, TotLayers + 1):
                var MatNum: Int = thisConstruct.LayerPoint[Layer - 1]
                if MatNum == 0:
                    continue
                var mat = s_mat.materials[MatNum - 1]
                if mat.group != Material.Group.Glass:
                    continue
                var matGlass = mat as Material.MaterialGlass
                assert(matGlass != None)
                if matGlass.SolarDiffusing and TotShadeLayers > 0:
                    ErrorsFound = True
                    ShowSevereError(state, "CheckAndSetConstructionProperties: Window construction={}".format(thisConstruct.Name))
                    ShowContinueError(state, "has diffusing glass={} and a shade, screen or blind layer.".format(matGlass.Name))
                    break
            if TotGlassLayers > 1:
                var GlassLayNum: Int = 0
                for Layer in range(1, TotLayers + 1):
                    var MatNum: Int = thisConstruct.LayerPoint[Layer - 1]
                    if MatNum == 0:
                        continue
                    var mat = s_mat.materials[MatNum - 1]
                    if mat.group != Material.Group.Glass:
                        continue
                    var matGlass = mat as Material.MaterialGlass
                    assert(matGlass != None)
                    GlassLayNum += 1
                    if GlassLayNum < TotGlassLayers and matGlass.SolarDiffusing:
                        ErrorsFound = True
                        ShowSevereError(state, "CheckAndSetConstructionProperties: Window construction={}".format(thisConstruct.Name))
                        ShowContinueError(state, "has diffusing glass={} that is not the innermost glass layer.".format(matGlass.Name))
            if TotShadeLayers == 1 and matInside.group == Material.Group.Screen and TotLayers != 1:
                WrongWindowLayering = True
            if TotShadeLayers == 1 and matOutside.group != Material.Group.Shade and matOutside.group != Material.Group.Blind and \
               matOutside.group != Material.Group.Screen and matInside.group != Material.Group.Shade and \
               matInside.group != Material.Group.Blind and matInside.group != Material.Group.ComplexShade and not WrongWindowLayering:
                if TotGlassLayers >= 4:
                    WrongWindowLayering = True
                elif TotGlassLayers == 2 or TotGlassLayers == 3:
                    var ValidBGShadeBlindConst: Bool = False
                    if TotGlassLayers == 2:
                        if TotLayers != 5:
                            WrongWindowLayering = True
                        else:
                            if matOutside.group == Material.Group.Glass and \
                               (s_mat.materials[thisConstruct.LayerPoint[1] - 1].group == Material.Group.Gas or \
                                s_mat.materials[thisConstruct.LayerPoint[1] - 1].group == Material.Group.GasMixture) and \
                               ((s_mat.materials[thisConstruct.LayerPoint[2] - 1].group == Material.Group.Shade or \
                                 s_mat.materials[thisConstruct.LayerPoint[2] - 1].group == Material.Group.Blind) and \
                                s_mat.materials[thisConstruct.LayerPoint[2] - 1].group != Material.Group.Screen) and \
                               (s_mat.materials[thisConstruct.LayerPoint[3] - 1].group == Material.Group.Gas or \
                                s_mat.materials[thisConstruct.LayerPoint[3] - 1].group == Material.Group.GasMixture) and \
                               s_mat.materials[thisConstruct.LayerPoint[4] - 1].group == Material.Group.Glass:
                                ValidBGShadeBlindConst = True
                    else:  # TotGlassLayers = 3
                        if TotLayers != 7:
                            WrongWindowLayering = True
                        else:
                            if matOutside.group == Material.Group.Glass and \
                               (s_mat.materials[thisConstruct.LayerPoint[1] - 1].group == Material.Group.Gas or \
                                s_mat.materials[thisConstruct.LayerPoint[1] - 1].group == Material.Group.GasMixture) and \
                               s_mat.materials[thisConstruct.LayerPoint[2] - 1].group == Material.Group.Glass and \
                               (s_mat.materials[thisConstruct.LayerPoint[3] - 1].group == Material.Group.Gas or \
                                s_mat.materials[thisConstruct.LayerPoint[3] - 1].group == Material.Group.GasMixture) and \
                               ((s_mat.materials[thisConstruct.LayerPoint[4] - 1].group == Material.Group.Shade or \
                                 s_mat.materials[thisConstruct.LayerPoint[4] - 1].group == Material.Group.Blind) and \
                                s_mat.materials[thisConstruct.LayerPoint[4] - 1].group != Material.Group.Screen) and \
                               (s_mat.materials[thisConstruct.LayerPoint[5] - 1].group == Material.Group.Gas or \
                                s_mat.materials[thisConstruct.LayerPoint[5] - 1].group == Material.Group.GasMixture) and \
                               s_mat.materials[thisConstruct.LayerPoint[6] - 1].group == Material.Group.Glass:
                                ValidBGShadeBlindConst = True
                    if not ValidBGShadeBlindConst:
                        WrongWindowLayering = True
                    if not WrongWindowLayering:
                        var LayNumSh: Int = 2 * TotGlassLayers - 1
                        var MatSh: Int = thisConstruct.LayerPoint[LayNumSh - 1]
                        var matSh = s_mat.materials[MatSh - 1]
                        if matSh.group != Material.Group.Shade and matSh.group != Material.Group.Blind:
                            WrongWindowLayering = True
                        if TotLayers != 2 * TotGlassLayers + 1:
                            WrongWindowLayering = True
                        if not WrongWindowLayering:
                            var MatGapL: Int = thisConstruct.LayerPoint[LayNumSh - 2]  # LayNumSh-1 -> index LayNumSh-2
                            var MatGapR: Int = thisConstruct.LayerPoint[LayNumSh]      # LayNumSh+1 -> index LayNumSh
                            var matGapL = s_mat.materials[MatGapL - 1] as Material.MaterialGasMix
                            var matGapR = s_mat.materials[MatGapR - 1] as Material.MaterialGasMix
                            for IGas in range(Material.maxMixGases):
                                if (matGapL.gases[IGas].type != matGapR.gases[IGas].type) or (matGapL.gasFracts[IGas] != matGapR.gasFracts[IGas]):
                                    WrongWindowLayering = True
                            if abs(matGapL.Thickness - matGapR.Thickness) > 0.0005:
                                WrongWindowLayering = True
                            if matSh.group == Material.Group.Blind:
                                var matBlind = matSh as Material.MaterialBlind
                                assert(matBlind != None)
                                if (matGapL.Thickness + matGapR.Thickness) < matBlind.SlatWidth:
                                    ErrorsFound = True
                                    ShowSevereError(state,
                                                    "CheckAndSetConstructionProperties: For window construction {}".format(thisConstruct.Name))
                                    ShowContinueError(state, "the slat width of the between-glass blind is greater than")
                                    ShowContinueError(state, "the sum of the widths of the gas layers adjacent to the blind.")
            if s_mat.materials[thisConstruct.LayerPoint[0] - 1].group == Material.Group.GlassSimple:
                if TotLayers > 1:
                    for Layer in range(1, TotLayers + 1):
                        var MaterNum: Int = thisConstruct.LayerPoint[Layer - 1]
                        if MaterNum == 0:
                            continue
                        var mat = s_mat.materials[MaterNum - 1]
                        if mat.group == Material.Group.Glass:
                            ErrorsFound = True
                            ShowSevereError(state,
                                            "CheckAndSetConstructionProperties: Error in window construction {}--".format(thisConstruct.Name))
                            ShowContinueError(state, "For simple window constructions, no other glazing layers are allowed.")
                        if mat.group == Material.Group.Gas:
                            ErrorsFound = True
                            ShowSevereError(state,
                                            "CheckAndSetConstructionProperties: Error in window construction {}--".format(thisConstruct.Name))
                            ShowContinueError(state, "For simple window constructions, no other gas layers are allowed.")
            if WrongWindowLayering:
                ShowSevereError(state, "CheckAndSetConstructionProperties: Error in window construction {}--".format(thisConstruct.Name))
                ShowContinueError(state, "  For multi-layer window constructions the following rules apply:")
                ShowContinueError(state, "    --The first and last layer must be a solid layer (glass or shade/screen/blind),")
                ShowContinueError(state, "    --Adjacent glass layers must be separated by one and only one gas layer,")
                ShowContinueError(state, "    --Adjacent layers must not be of the same type,")
                ShowContinueError(state, "    --Only one shade/screen/blind layer is allowed,")
                ShowContinueError(state, "    --An exterior shade/screen/blind must be the first layer,")
                ShowContinueError(state, "    --An interior shade/blind must be the last layer,")
                ShowContinueError(state, "    --An interior screen is not allowed,")
                ShowContinueError(state, "    --For an exterior shade/screen/blind or interior shade/blind, there should not be a gas layer")
                ShowContinueError(state, "    ----between the shade/screen/blind and adjacent glass,")
                ShowContinueError(state, "    --A between-glass screen is not allowed,")
                ShowContinueError(state, "    --A between-glass shade/blind is allowed only for double and triple glazing,")
                ShowContinueError(state, "    --A between-glass shade/blind must have adjacent gas layers of the same type and width,")
                ShowContinueError(state, "    --For triple glazing the between-glass shade/blind must be between the two inner glass layers,")
                ShowContinueError(state, "    --The slat width of a between-glass blind must be less than the sum of the widths")
                ShowContinueError(state, "    ----of the gas layers adjacent to the blind.")
                ErrorsFound = True
            thisConstruct.TotGlassLayers = TotGlassLayers
            thisConstruct.TotSolidLayers = TotGlassLayers + TotShadeLayers
            if matInside.group == Material.Group.Shade or matInside.group == Material.Group.Blind:
                InsideLayer -= 1
            if InsideLayer > 0:
                InsideMaterNum = thisConstruct.LayerPoint[InsideLayer - 1]
                thisConstruct.InsideAbsorpThermal = matInside.AbsorpThermalBack
            if InsideMaterNum != 0:
                var thisInsideMaterial = s_mat.materials[InsideMaterNum - 1]
                thisConstruct.InsideAbsorpVis = thisInsideMaterial.AbsorpVisible
                thisConstruct.InsideAbsorpSolar = thisInsideMaterial.AbsorpSolar
            if (matOutside.group == Material.Group.Glass) or (matOutside.group == Material.Group.GlassSimple):
                thisConstruct.OutsideAbsorpThermal = matOutside.AbsorpThermalFront
            else:
                thisConstruct.OutsideAbsorpThermal = matOutside.AbsorpThermal
        else:  # Opaque surface
            thisConstruct.InsideAbsorpThermal = matInside.AbsorpThermal
            thisConstruct.OutsideAbsorpThermal = matOutside.AbsorpThermal
        thisConstruct.OutsideRoughness = matOutside.Roughness
        if matOutside.group == Material.Group.AirGap:
            ShowSevereError(state, "CheckAndSetConstructionProperties: Outside Layer is Air for construction {}".format(thisConstruct.Name))
            ShowContinueError(state, "  Error in material {}".format(matOutside.Name))
            ErrorsFound = True
        if InsideLayer > 0:
            if matInside.group == Material.Group.AirGap:
                ShowSevereError(state, "CheckAndSetConstructionProperties: Inside Layer is Air for construction {}".format(thisConstruct.Name))
                ShowContinueError(state, "  Error in material {}".format(matInside.Name))
                ErrorsFound = True
        if matOutside.group == Material.Group.EcoRoof:
            thisConstruct.TypeIsEcoRoof = True
            for Layer in range(2, TotLayers + 1):
                if s_mat.materials[thisConstruct.LayerPoint[Layer - 1] - 1].group == Material.Group.EcoRoof:
                    ShowSevereError(state,
                                    "CheckAndSetConstructionProperties: Interior Layer is EcoRoof for construction {}".format(thisConstruct.Name))
                    ShowContinueError(state, "  Error in material {}".format(s_mat.materials[thisConstruct.LayerPoint[Layer - 1] - 1].Name))
                    ErrorsFound = True
        if matOutside.group == Material.Group.IRTransparent:
            thisConstruct.TypeIsIRT = True
            if thisConstruct.TotLayers != 1:
                ShowSevereError(state,
                                "CheckAndSetConstructionProperties: Infrared Transparent (IRT) Construction is limited to 1 layer {}".format(thisConstruct.Name))
                ShowContinueError(state, "  Too many layers in referenced construction.")
                ErrorsFound = True

    def AssignReverseConstructionNumber(state: EnergyPlusData,
                                       ConstrNum: Int,  # Existing Construction number of first surface
                                       ErrorsFound: Bool
    ) -> Int:
        var NewConstrNum: Int
        if ConstrNum == 0:
            NewConstrNum = 0
            return NewConstrNum
        var thisConstruct = state.dataConstruction.Construct[ConstrNum - 1]
        thisConstruct.IsUsed = True
        var nLayer: Int = 0
        state.dataConstruction.LayerPoint = 0  # This is an array, need to set all to 0? In C++ it's an array, we'll assume it's a list.
        for Loop in range(thisConstruct.TotLayers, 0, -1):
            nLayer += 1
            state.dataConstruction.LayerPoint[nLayer - 1] = thisConstruct.LayerPoint[Loop - 1]
        NewConstrNum = 0
        for Loop in range(1, state.dataHeatBal.TotConstructs + 1):
            var Found: Bool = True
            for nLayer in range(1, Construction.MaxLayersInConstruct + 1):
                if state.dataConstruction.Construct[Loop - 1].LayerPoint[nLayer - 1] != state.dataConstruction.LayerPoint[nLayer - 1]:
                    Found = False
                    break
            if Found:
                NewConstrNum = Loop
                state.dataConstruction.Construct[Loop - 1].IsUsed = True
                break
        if NewConstrNum == 0:
            state.dataHeatBal.TotConstructs += 1
            state.dataConstruction.Construct.redimension(state.dataHeatBal.TotConstructs)
            state.dataHeatBal.NominalRforNominalUCalculation.redimension(state.dataHeatBal.TotConstructs)
            state.dataHeatBal.NominalRforNominalUCalculation[state.dataHeatBal.TotConstructs - 1] = 0.0
            state.dataHeatBal.NominalU.redimension(state.dataHeatBal.TotConstructs)
            state.dataHeatBal.NominalU[state.dataHeatBal.TotConstructs - 1] = 0.0
            state.dataHeatBal.NominalUBeforeAdjusted.redimension(state.dataHeatBal.TotConstructs)
            state.dataHeatBal.NominalUBeforeAdjusted[state.dataHeatBal.TotConstructs - 1] = 0.0
            state.dataHeatBal.CoeffAdjRatio.redimension(state.dataHeatBal.TotConstructs)
            state.dataHeatBal.CoeffAdjRatio[state.dataHeatBal.TotConstructs - 1] = 1.0
            NewConstrNum = state.dataHeatBal.TotConstructs
            state.dataConstruction.Construct[NewConstrNum - 1].IsUsed = True
            state.dataConstruction.Construct[state.dataHeatBal.TotConstructs - 1] = state.dataConstruction.Construct[ConstrNum - 1]
            state.dataConstruction.Construct[state.dataHeatBal.TotConstructs - 1].Name = "iz-" + state.dataConstruction.Construct[ConstrNum - 1].Name
            state.dataConstruction.Construct[state.dataHeatBal.TotConstructs - 1].TotLayers = state.dataConstruction.Construct[ConstrNum - 1].TotLayers
            var s_mat = state.dataMaterial
            for nLayer in range(1, Construction.MaxLayersInConstruct + 1):
                state.dataConstruction.Construct[state.dataHeatBal.TotConstructs - 1].LayerPoint[nLayer - 1] = state.dataConstruction.LayerPoint[nLayer - 1]
                if state.dataConstruction.LayerPoint[nLayer - 1] != 0:
                    state.dataHeatBal.NominalRforNominalUCalculation[state.dataHeatBal.TotConstructs - 1] += \
                        s_mat.materials[state.dataConstruction.LayerPoint[nLayer - 1] - 1].NominalR
            if state.dataHeatBal.NominalRforNominalUCalculation[state.dataHeatBal.TotConstructs - 1] != 0.0:
                state.dataHeatBal.NominalU[state.dataHeatBal.TotConstructs - 1] = \
                    1.0 / state.dataHeatBal.NominalRforNominalUCalculation[state.dataHeatBal.TotConstructs - 1]
            CheckAndSetConstructionProperties(state, state.dataHeatBal.TotConstructs, ErrorsFound)
        return NewConstrNum

    def ComputeNominalUwithConvCoeffs(state: EnergyPlusData,
                                     numSurf: Int,  # index for Surface array.
                                     isValid: Bool  # returns true if result is valid
    ) -> Real64:
        var NominalUwithConvCoeffs: Real64
        var filmCoefs: StaticArray[Real64, DataSurfaces.SurfaceClass.Num] = [
            0.0,       # None
            0.1197548, # Wall
            0.1620212, # Floor
            0.1074271, # Roof
            0.0,       # IntMass
            0.0,       # Detached_B
            0.0,       # Detached_F
            0.1197548, # Window
            0.1197548, # GlassDoor
            0.1197548, # Door
            0.0,       # Shading
            0.0,       # Overhang
            0.0,       # Fin
            0.0,       # TDD_Dome
            0.0        # TDD_Diffuser
        ]
        var insideFilm: Real64
        var outsideFilm: Real64
        isValid = True
        var thisSurface = state.dataSurface.Surface[numSurf - 1]
        if thisSurface.ExtBoundCond == DataSurfaces.ExternalEnvironment:
            outsideFilm = 0.0299387
        elif thisSurface.ExtBoundCond == DataSurfaces.OtherSideCoefCalcExt:
            outsideFilm = state.dataSurface.OSC[thisSurface.OSCPtr - 1].SurfFilmCoef
        elif thisSurface.ExtBoundCond == DataSurfaces.Ground or \
             thisSurface.ExtBoundCond == DataSurfaces.OtherSideCoefNoCalcExt or \
             thisSurface.ExtBoundCond == DataSurfaces.OtherSideCondModeledExt or \
             thisSurface.ExtBoundCond == DataSurfaces.GroundFCfactorMethod or \
             thisSurface.ExtBoundCond == DataSurfaces.KivaFoundation:
            outsideFilm = 0.0
        else:
            outsideFilm = filmCoefs[state.dataSurface.Surface[thisSurface.ExtBoundCond - 1].Class]
        if state.dataHeatBal.NominalU[thisSurface.Construction - 1] > 0.0:
            insideFilm = filmCoefs[thisSurface.Class]
            if insideFilm == 0.0:
                outsideFilm = 0.0
            NominalUwithConvCoeffs = 1.0 / (insideFilm + (1.0 / state.dataHeatBal.NominalU[state.dataSurface.Surface[numSurf - 1].Construction - 1]) + outsideFilm)
        else:
            isValid = False
            NominalUwithConvCoeffs = state.dataHeatBal.NominalU[state.dataSurface.Surface[numSurf - 1].Construction - 1]
        return NominalUwithConvCoeffs

    def SetFlagForWindowConstructionWithShadeOrBlindLayer(state: EnergyPlusData):
        using DataSurfaces.ExternalEnvironment
        var loopSurfNum: Int = 0
        var ConstrNum: Int = 0
        var NumLayers: Int = 0
        var Layer: Int = 0
        var MaterNum: Int = 0
        var s_mat = state.dataMaterial
        for loopSurfNum in range(1, state.dataSurface.TotSurfaces + 1):
            if state.dataSurface.Surface[loopSurfNum - 1].Class != DataSurfaces.SurfaceClass.Window:
                continue
            if state.dataSurface.Surface[loopSurfNum - 1].ExtBoundCond != ExternalEnvironment:
                continue
            if not state.dataSurface.Surface[loopSurfNum - 1].HasShadeControl:
                continue
            if state.dataSurface.Surface[loopSurfNum - 1].activeShadedConstruction == 0:
                continue
            ConstrNum = state.dataSurface.Surface[loopSurfNum - 1].activeShadedConstruction
            var thisConstruct = state.dataConstruction.Construct[ConstrNum - 1]
            if thisConstruct.TypeIsWindow:
                NumLayers = thisConstruct.TotLayers
                for Layer in range(1, NumLayers + 1):
                    MaterNum = thisConstruct.LayerPoint[Layer - 1]
                    if MaterNum == 0:
                        continue
                    var mat = s_mat.materials[MaterNum - 1]
                    if mat.group == Material.Group.Shade or mat.group == Material.Group.Blind:
                        state.dataSurface.SurfWinHasShadeOrBlindLayer[loopSurfNum - 1] = True

    def AllocateIntGains(state: EnergyPlusData):
        state.dataHeatBal.ZoneIntGain.allocate(state.dataGlobal.NumOfZones)
        state.dataHeatBal.spaceIntGain.allocate(state.dataGlobal.numSpaces)
        state.dataHeatBal.spaceIntGainDevices.allocate(state.dataGlobal.numSpaces)
        state.dataDayltg.spacePowerReductionFactor.dimension(state.dataGlobal.numSpaces, 1.0)