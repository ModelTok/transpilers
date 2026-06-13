from WCEMultiLayerOptics import *
from WCETarcog import *
from Construction import *
from .Data.EnergyPlusData import EnergyPlusData
from DataEnvironment import *
from DataHeatBalSurface import *
from DataHeatBalance import *
from DataSurfaces import *
from General import *
from Material import *
from UtilityRoutines import *
from WindowManager import *
from WindowManagerExteriorThermal import *
from Constants import Constant
from FenestrationCommon import FenestrationCommon
from Tarcog.ISO15099 import Tarcog
from Gases import Gases
from MultiLayerOptics import MultiLayerOptics
from memory import Arc

# using namespace DataEnvironment;
# using namespace DataSurfaces;
# using namespace DataHeatBalance;
# using namespace General;

namespace EnergyPlus:
    namespace Window:
        def CalcWindowHeatBalanceExternalRoutines(
            state: EnergyPlusData,
            SurfNum: Int,          # Surface number
            HextConvCoeff: Float64, # Outside air film conductance coefficient
            SurfInsideTemp: Float64, # Inside window surface temperature
            SurfOutsideTemp: Float64 # Outside surface temperature (C)
        ):
            var surf = state.dataSurface.Surface(SurfNum)
            var surfWin = state.dataSurface.SurfaceWindow(SurfNum)
            var ConstrNum = surf.Construction
            var construction = state.dataConstruction.Construct(ConstrNum)
            alias solutionTolerance: Float64 = 0.02
            var activeConstrNum = CWCEHeatTransferFactory.getActiveConstructionNumber(state, surf, SurfNum)
            var aFactory = CWCEHeatTransferFactory(state, surf, SurfNum, activeConstrNum) # (AUTO_OK)
            var aSystem = aFactory.getTarcogSystem(state, HextConvCoeff)                  # (AUTO_OK_SPTR)
            aSystem.setTolerance(solutionTolerance)
            var Guess = List[Float64]()
            var totSolidLayers = construction.TotSolidLayers
            if ANY_SHADE_SCREEN(state.dataSurface.SurfWinShadingFlag(SurfNum)) or ANY_BLIND(state.dataSurface.SurfWinShadingFlag(SurfNum)):
                totSolidLayers += 1
            for k in range(1, 2 * totSolidLayers + 1):
                Guess.append(state.dataSurface.SurfaceWindow(SurfNum).thetaFace[k])
            try:
                aSystem.setInitialGuess(Guess)
                aSystem.solve()
            except Error as ex:
                ShowSevereError(state, "Error in Windows Calculation Engine Exterior Module.")
                ShowContinueError(state, ex.what())
            var aLayers = aSystem.getSolidLayers() # (AUTO_OK_OBJ)
            var i = 1
            for aLayer in aLayers: # (AUTO_OK_SPTR)
                var aTemp: Float64 = 0
                for aSide in FenestrationCommon.EnumSide(): # (AUTO_OK) I don't understand what this construct is
                    aTemp = aLayer.getTemperature(aSide)
                    state.dataWindowManager.thetas[i - 1] = aTemp
                    if i == 1:
                        SurfOutsideTemp = aTemp - Constant.Kelvin
                    i += 1
                SurfInsideTemp = aTemp - Constant.Kelvin
                if ANY_INTERIOR_SHADE_BLIND(state.dataSurface.SurfWinShadingFlag(SurfNum)):
                    var surfShade = state.dataSurface.surfShades(SurfNum)
                    var EffShBlEmiss = surfShade.effShadeEmi
                    var EffGlEmiss = surfShade.effGlassEmi
                    if surfShade.blind.movableSlats:
                        surfShade.effShadeEmi = Interp(construction.effShadeBlindEmi[surfShade.blind.slatAngIdxLo],
                                                       construction.effShadeBlindEmi[surfShade.blind.slatAngIdxHi],
                                                       surfShade.blind.slatAngInterpFac)
                        surfShade.effGlassEmi = Interp(construction.effGlassEmi[surfShade.blind.slatAngIdxLo],
                                                       construction.effGlassEmi[surfShade.blind.slatAngIdxHi],
                                                       surfShade.blind.slatAngInterpFac)
                    state.dataSurface.SurfWinEffInsSurfTemp(SurfNum) = \
                        (EffShBlEmiss * SurfInsideTemp + EffGlEmiss * (state.dataWindowManager.thetas[2 * totSolidLayers - 3] - Constant.Kelvin)) / \
                        (EffShBlEmiss + EffGlEmiss)
            state.dataHeatBalSurf.SurfHConvInt(SurfNum) = aSystem.getHc(Tarcog.ISO15099.Environment.Indoor)
            if ANY_INTERIOR_SHADE_BLIND(state.dataSurface.SurfWinShadingFlag(SurfNum)) or aFactory.isInteriorShade():
                var surfShade = state.dataSurface.surfShades(SurfNum)
                var totLayers = aLayers.size()
                state.dataWindowManager.nglface = 2 * totLayers - 2
                state.dataWindowManager.nglfacep = state.dataWindowManager.nglface + 2
                var aShadeLayer = aLayers[totLayers - 1] # (AUTO_OK_SPTR)
                var aGlassLayer = aLayers[totLayers - 2] # (AUTO_OK_SPTR)
                var ShadeArea = state.dataSurface.Surface(SurfNum).Area + state.dataSurface.SurfWinDividerArea(SurfNum)
                var frontSurface = aShadeLayer.getSurface(FenestrationCommon.Side.Front) # (AUTO_OK_SPTR)
                var backSurface = aShadeLayer.getSurface(FenestrationCommon.Side.Back)   # (AUTO_OK_SPTR)
                var EpsShIR1 = frontSurface.getEmissivity()
                var EpsShIR2 = backSurface.getEmissivity()
                var TauShIR = frontSurface.getTransmittance()
                var RhoShIR1 = max(0.0, 1.0 - TauShIR - EpsShIR1)
                var RhoShIR2 = max(0.0, 1.0 - TauShIR - EpsShIR2)
                var glassEmiss = aGlassLayer.getSurface(FenestrationCommon.Side.Back).getEmissivity()
                var RhoGlIR2 = 1.0 - glassEmiss
                var ShGlReflFacIR = 1.0 - RhoGlIR2 * RhoShIR1
                var rmir = state.dataSurface.SurfWinIRfromParentZone(SurfNum) + state.dataHeatBalSurf.SurfQdotRadHVACInPerArea(SurfNum)
                var NetIRHeatGainShade = \
                    ShadeArea * EpsShIR2 * \
                        (Constant.StefanBoltzmann * pow(state.dataWindowManager.thetas[state.dataWindowManager.nglfacep - 1], 4) - rmir) + \
                    EpsShIR1 * (Constant.StefanBoltzmann * pow(state.dataWindowManager.thetas[state.dataWindowManager.nglfacep - 2], 4) - rmir) * \
                        RhoGlIR2 * TauShIR / ShGlReflFacIR
                var NetIRHeatGainGlass = \
                    ShadeArea * (glassEmiss * TauShIR / ShGlReflFacIR) * \
                    (Constant.StefanBoltzmann * pow(state.dataWindowManager.thetas[state.dataWindowManager.nglface - 1], 4) - rmir)
                var tind = surf.getInsideAirTemperature(state, SurfNum) + Constant.Kelvin
                var ConvHeatGainFrZoneSideOfShade = ShadeArea * state.dataHeatBalSurf.SurfHConvInt(SurfNum) * \
                                                   (state.dataWindowManager.thetas[state.dataWindowManager.nglfacep - 1] - tind)
                state.dataSurface.SurfWinHeatGain(SurfNum) = \
                    state.dataSurface.SurfWinTransSolar(SurfNum) + ConvHeatGainFrZoneSideOfShade + NetIRHeatGainGlass + NetIRHeatGainShade
                state.dataSurface.SurfWinGainIRGlazToZoneRep(SurfNum) = NetIRHeatGainGlass
                surfShade.effShadeEmi = EpsShIR1 * (1.0 + RhoGlIR2 * TauShIR / (1.0 - RhoGlIR2 * RhoShIR2))
                surfShade.effGlassEmi = glassEmiss * TauShIR / (1.0 - RhoGlIR2 * RhoShIR2)
                var glassTemperature = aGlassLayer.getSurface(FenestrationCommon.Side.Back).getTemperature()
                state.dataSurface.SurfWinEffInsSurfTemp(SurfNum) = \
                    (surfShade.effShadeEmi * SurfInsideTemp + surfShade.effGlassEmi * (glassTemperature - Constant.Kelvin)) / \
                    (surfShade.effShadeEmi + surfShade.effGlassEmi)
            else:
                var surfShade = state.dataSurface.surfShades(SurfNum)
                var totLayers = aLayers.size()
                var aGlassLayer = aLayers[totLayers - 1]                                  # (AUTO_OK_SPTR)
                var backSurface = aGlassLayer.getSurface(FenestrationCommon.Side.Back) # (AUTO_OK_SPTR)
                var h_cin = aSystem.getHc(Tarcog.ISO15099.Environment.Indoor)
                var ConvHeatGainFrZoneSideOfGlass = \
                    surf.Area * h_cin * (backSurface.getTemperature() - aSystem.getAirTemperature(Tarcog.ISO15099.Environment.Indoor))
                var rmir = state.dataSurface.SurfWinIRfromParentZone(SurfNum) + state.dataHeatBalSurf.SurfQdotRadHVACInPerArea(SurfNum)
                var NetIRHeatGainGlass = \
                    surf.Area * backSurface.getEmissivity() * (Constant.StefanBoltzmann * pow(backSurface.getTemperature(), 4) - rmir)
                state.dataSurface.SurfWinEffInsSurfTemp(SurfNum) = \
                    aLayers[totLayers - 1].getTemperature(FenestrationCommon.Side.Back) - Constant.Kelvin
                surfShade.effGlassEmi = aLayers[totLayers - 1].getSurface(FenestrationCommon.Side.Back).getEmissivity()
                state.dataSurface.SurfWinHeatGain(SurfNum) = \
                    state.dataSurface.SurfWinTransSolar(SurfNum) + ConvHeatGainFrZoneSideOfGlass + NetIRHeatGainGlass
                state.dataSurface.SurfWinGainConvGlazToZoneRep(SurfNum) = ConvHeatGainFrZoneSideOfGlass
                state.dataSurface.SurfWinGainIRGlazToZoneRep(SurfNum) = NetIRHeatGainGlass
            state.dataSurface.SurfWinLossSWZoneToOutWinRep(SurfNum) = \
                state.dataHeatBal.EnclSolQSWRad(state.dataSurface.Surface(SurfNum).SolarEnclIndex) * surf.Area * (1 - construction.ReflectSolDiffBack) + \
                state.dataHeatBalSurf.SurfWinInitialBeamSolInTrans(SurfNum)
            state.dataSurface.SurfWinHeatGain(SurfNum) -= \
                (state.dataSurface.SurfWinLossSWZoneToOutWinRep(SurfNum) + state.dataHeatBalSurf.SurfWinInitialDifSolInTrans(SurfNum) * surf.Area)
            for k in range(1, surf.getTotLayers(state) + 1):
                surfWin.thetaFace[2 * k - 1] = state.dataWindowManager.thetas[2 * k - 2]
                surfWin.thetaFace[2 * k] = state.dataWindowManager.thetas[2 * k - 1]
                state.dataHeatBal.SurfWinFenLaySurfTempFront(SurfNum, k) = state.dataWindowManager.thetas[2 * k - 2] - Constant.Kelvin
                state.dataHeatBal.SurfWinFenLaySurfTempBack(SurfNum, k) = state.dataWindowManager.thetas[2 * k - 1] - Constant.Kelvin

        def GetIGUUValueForNFRCReport(
            state: EnergyPlusData,
            surfNum: Int,
            constrNum: Int,
            windowWidth: Float64,
            windowHeight: Float64
        ) -> Float64:
            var tilt: Float64 = 90.0
            var surface = state.dataSurface.Surface(surfNum)
            var aFactory = CWCEHeatTransferFactory(state, surface, surfNum, constrNum) # (AUTO_OK)
            var winterGlassUnit = aFactory.getTarcogSystemForReporting(state, False, windowWidth, windowHeight, tilt) # (AUTO_OK_SPTR)
            return winterGlassUnit.getUValue()

        def GetSHGCValueForNFRCReporting(
            state: EnergyPlusData,
            surfNum: Int,
            constrNum: Int,
            windowWidth: Float64,
            windowHeight: Float64
        ) -> Float64:
            var tilt: Float64 = 90.0
            var surface = state.dataSurface.Surface(surfNum)
            var aFactory = CWCEHeatTransferFactory(state, surface, surfNum, constrNum) # (AUTO_OK)
            var summerGlassUnit = aFactory.getTarcogSystemForReporting(state, True, windowWidth, windowHeight, tilt) # (AUTO_OK_SPTR)
            return summerGlassUnit.getSHGC(state.dataConstruction.Construct(constrNum).SolTransNorm)

        def GetWindowAssemblyNfrcForReport(
            state: EnergyPlusData,
            surfNum: Int,
            constrNum: Int,
            windowWidth: Float64,
            windowHeight: Float64,
            vision: DataSurfaces.NfrcVisionType,
            uvalue: Float64,
            shgc: Float64,
            vt: Float64
        ):
            var surface = state.dataSurface.Surface(surfNum)
            var frameDivider = state.dataSurface.FrameDivider(surface.FrameDivider)
            var aFactory = CWCEHeatTransferFactory(state, surface, surfNum, constrNum) # (AUTO_OK)
            for isSummer in [False, True]:
                alias framehExtConvCoeff: Float64 = 30.0
                alias framehIntConvCoeff: Float64 = 8.0
                alias tilt: Float64 = 90.0
                var insulGlassUnit = aFactory.getTarcogSystemForReporting(state, isSummer, windowWidth, windowHeight, tilt) # (AUTO_OK_SPTR)
                var centerOfGlassUvalue = insulGlassUnit.getUValue()
                var winterGlassUnit = aFactory.getTarcogSystemForReporting(state, False, windowWidth, windowHeight, tilt) # (AUTO_OK_SPTR)
                var frameUvalue = aFactory.overallUfactorFromFilmsAndCond(frameDivider.FrameConductance, framehIntConvCoeff, framehExtConvCoeff)
                var frameEdgeUValue = winterGlassUnit.getUValue() * frameDivider.FrEdgeToCenterGlCondRatio # not sure about this
                var frameProjectedDimension = frameDivider.FrameWidth
                var frameWettedLength = frameProjectedDimension + frameDivider.FrameProjectionIn
                var frameAbsorptance = frameDivider.FrameSolAbsorp
                var frameData = Tarcog.ISO15099.FrameData(frameUvalue, frameEdgeUValue, frameProjectedDimension, frameWettedLength, frameAbsorptance)
                var dividerUvalue = \
                    aFactory.overallUfactorFromFilmsAndCond(frameDivider.DividerConductance, framehIntConvCoeff, framehExtConvCoeff)
                var dividerEdgeUValue = centerOfGlassUvalue * frameDivider.DivEdgeToCenterGlCondRatio # not sure about this
                var dividerProjectedDimension = frameDivider.DividerWidth
                var dividerWettedLength = dividerProjectedDimension + frameDivider.DividerProjectionIn
                var dividerAbsorptance = frameDivider.DividerSolAbsorp
                var numHorizDividers = frameDivider.HorDividers
                var numVertDividers = frameDivider.VertDividers
                var dividerData = Tarcog.ISO15099.FrameData(
                    dividerUvalue, dividerEdgeUValue, dividerProjectedDimension, dividerWettedLength, dividerAbsorptance)
                var tVis = state.dataConstruction.Construct(constrNum).VisTransNorm
                var tSol = state.dataConstruction.Construct(constrNum).SolTransNorm
                if vision == DataSurfaces.NfrcVisionType.Single:
                    var window = Tarcog.ISO15099.WindowSingleVision(windowWidth, windowHeight, tVis, tSol, insulGlassUnit)
                    window.setFrameTop(frameData)
                    window.setFrameBottom(frameData)
                    window.setFrameLeft(frameData)
                    window.setFrameRight(frameData)
                    window.setDividers(dividerData, numHorizDividers, numVertDividers)
                    if isSummer:
                        vt = window.vt()
                        shgc = window.shgc()
                    else:
                        uvalue = window.uValue()
                elif vision == DataSurfaces.NfrcVisionType.DualHorizontal:
                    var window = Tarcog.ISO15099.DualVisionHorizontal(windowWidth, windowHeight, tVis, tSol, insulGlassUnit, tVis, tSol, insulGlassUnit)
                    window.setFrameLeft(frameData)
                    window.setFrameRight(frameData)
                    window.setFrameBottomLeft(frameData)
                    window.setFrameBottomRight(frameData)
                    window.setFrameTopLeft(frameData)
                    window.setFrameTopRight(frameData)
                    window.setFrameMeetingRail(frameData)
                    window.setDividers(dividerData, numHorizDividers, numVertDividers)
                    if isSummer:
                        vt = window.vt()
                        shgc = window.shgc()
                    else:
                        uvalue = window.uValue()
                elif vision == DataSurfaces.NfrcVisionType.DualVertical:
                    var window = Tarcog.ISO15099.DualVisionVertical(windowWidth, windowHeight, tVis, tSol, insulGlassUnit, tVis, tSol, insulGlassUnit)
                    window.setFrameTop(frameData)
                    window.setFrameBottom(frameData)
                    window.setFrameTopLeft(frameData)
                    window.setFrameTopRight(frameData)
                    window.setFrameBottomLeft(frameData)
                    window.setFrameBottomRight(frameData)
                    window.setFrameMeetingRail(frameData)
                    window.setDividers(dividerData, numHorizDividers, numVertDividers)
                    if isSummer:
                        vt = window.vt()
                        shgc = window.shgc()
                    else:
                        uvalue = window.uValue()
                else:
                    var window = Tarcog.ISO15099.WindowSingleVision(windowWidth, windowHeight, tVis, tSol, insulGlassUnit)
                    window.setFrameTop(frameData)
                    window.setFrameBottom(frameData)
                    window.setFrameLeft(frameData)
                    window.setFrameRight(frameData)
                    window.setDividers(dividerData, numHorizDividers, numVertDividers)
                    if isSummer:
                        vt = window.vt()
                        shgc = window.shgc()
                    else:
                        uvalue = window.uValue()

        class CWCEHeatTransferFactory:
            var m_Surface: DataSurfaces.SurfaceData
            var m_Window: DataSurfaces.SurfaceWindowCalc
            var m_ShadePosition: ShadePosition
            var m_SurfNum: Int
            var m_SolidLayerIndex: Int
            var m_ConstructionNumber: Int
            var m_TotLay: Int
            var m_InteriorBSDFShade: Bool
            var m_ExteriorShade: Bool

            def __init__(self, state: EnergyPlusData, surface: SurfaceData, t_SurfNum: Int, t_ConstrNum: Int):
                self.m_Surface = surface
                self.m_Window = state.dataSurface.SurfaceWindow(t_SurfNum)
                self.m_ShadePosition = ShadePosition.NoShade
                self.m_SurfNum = t_SurfNum
                self.m_SolidLayerIndex = 0
                self.m_ConstructionNumber = t_ConstrNum
                self.m_TotLay = self.getNumOfLayers(state)
                self.m_InteriorBSDFShade = False
                self.m_ExteriorShade = False
                if not state.dataConstruction.Construct(self.m_ConstructionNumber).WindowTypeBSDF and \
                    state.dataSurface.SurfWinShadingFlag.size() >= static_cast[Int](self.m_SurfNum):
                    if ANY_SHADE_SCREEN(state.dataSurface.SurfWinShadingFlag(self.m_SurfNum)) or \
                        ANY_BLIND(state.dataSurface.SurfWinShadingFlag(self.m_SurfNum)):
                        self.m_ConstructionNumber = state.dataSurface.SurfWinActiveShadedConstruction(self.m_SurfNum)
                        self.m_TotLay = self.getNumOfLayers(state)
                var ShadeFlag = getShadeType(state, self.m_ConstructionNumber)
                if ANY_INTERIOR_SHADE_BLIND(ShadeFlag):
                    self.m_ShadePosition = ShadePosition.Interior
                elif ANY_EXTERIOR_SHADE_BLIND_SCREEN(ShadeFlag):
                    self.m_ShadePosition = ShadePosition.Exterior
                elif ANY_BETWEENGLASS_SHADE_BLIND(ShadeFlag):
                    self.m_ShadePosition = ShadePosition.Between

            def getTarcogSystem(self, state: EnergyPlusData, t_HextConvCoeff: Float64) -> Arc[Tarcog.ISO15099.CSingleSystem]:
                var Indoor = self.getIndoor(state)                    # (AUTO_OK_SPTR)
                var Outdoor = self.getOutdoor(state, t_HextConvCoeff) # (AUTO_OK_SPTR)
                var aIGU = self.getIGU()                              # (AUTO_OK_OBJ)
                for i in range(self.m_TotLay):
                    var aLayer = self.getIGULayer(state, i + 1) # (AUTO_OK_SPTR)
                    assert(aLayer is not None)
                    if self.m_ShadePosition == ShadePosition.Interior and i == self.m_TotLay - 1:
                        var aAirLayer = self.getShadeToGlassLayer(state, i + 1) # (AUTO_OK_SPTR)
                        aIGU.addLayer(aAirLayer)
                    aIGU.addLayer(aLayer)
                    if self.m_ShadePosition == ShadePosition.Exterior and i == 0:
                        var aAirLayer = self.getShadeToGlassLayer(state, i + 1) # (AUTO_OK_SPTR)
                        aIGU.addLayer(aAirLayer)
                return Arc(Tarcog.ISO15099.CSingleSystem(aIGU, Indoor, Outdoor))

            def getTarcogSystemForReporting(
                self, state: EnergyPlusData, useSummerConditions: Bool, width: Float64, height: Float64, tilt: Float64
            ) -> Arc[Tarcog.ISO15099.IIGUSystem]:
                var Indoor = self.getIndoorNfrc(useSummerConditions)   # (AUTO_OK_SPTR)
                var Outdoor = self.getOutdoorNfrc(useSummerConditions) # (AUTO_OK_SPTR)
                var aIGU = self.getIGU(width, height, tilt)            # (AUTO_OK_OBJ)
                self.m_SolidLayerIndex = 0
                for i in range(self.m_TotLay):
                    var aLayer = self.getIGULayer(state, i + 1) # (AUTO_OK_SPTR)
                    assert(aLayer is not None)
                    if self.m_ShadePosition == ShadePosition.Interior and i == self.m_TotLay - 1:
                        var aAirLayer = self.getShadeToGlassLayer(state, i + 1) # (AUTO_OK_SPTR)
                        aIGU.addLayer(aAirLayer)
                    aIGU.addLayer(aLayer)
                    if self.m_ShadePosition == ShadePosition.Exterior and i == 0:
                        var aAirLayer = self.getShadeToGlassLayer(state, i + 1) # (AUTO_OK_SPTR)
                        aIGU.addLayer(aAirLayer)
                return Arc(Tarcog.ISO15099.CSystem(aIGU, Indoor, Outdoor))

            def getLayerMaterial(self, state: EnergyPlusData, t_Index: Int) -> Material.MaterialBase:
                var ConstrNum = self.m_ConstructionNumber
                if not state.dataConstruction.Construct(ConstrNum).WindowTypeBSDF and \
                    state.dataSurface.SurfWinShadingFlag.size() >= static_cast[Int](self.m_SurfNum):
                    if ANY_SHADE_SCREEN(state.dataSurface.SurfWinShadingFlag(self.m_SurfNum)) or \
                        ANY_BLIND(state.dataSurface.SurfWinShadingFlag(self.m_SurfNum)):
                        ConstrNum = state.dataSurface.SurfWinActiveShadedConstruction(self.m_SurfNum)
                var construction = state.dataConstruction.Construct(ConstrNum)
                var LayPtr = construction.LayerPoint(t_Index)
                return state.dataMaterial.materials(LayPtr)

            def getIGULayer(self, state: EnergyPlusData, t_Index: Int) -> Arc[Tarcog.ISO15099.CBaseIGULayer]:
                var aLayer: Arc[Tarcog.ISO15099.CBaseIGULayer] = None
                var material = self.getLayerMaterial(state, t_Index)
                var matGroup = material.group
                if (matGroup == Material.Group.Glass) or (matGroup == Material.Group.GlassSimple) or \
                    (matGroup == Material.Group.Blind) or (matGroup == Material.Group.Shade) or \
                    (matGroup == Material.Group.Screen) or (matGroup == Material.Group.ComplexShade):
                    self.m_SolidLayerIndex += 1
                    aLayer = self.getSolidLayer(state, material, self.m_SolidLayerIndex)
                elif matGroup == Material.Group.Gas or matGroup == Material.Group.GasMixture:
                    aLayer = self.getGapLayer(material)
                elif matGroup == Material.Group.ComplexWindowGap:
                    aLayer = self.getComplexGapLayer(state, material)
                return aLayer

            def getNumOfLayers(self, state: EnergyPlusData) -> Int:
                return state.dataConstruction.Construct(self.m_ConstructionNumber).TotLayers

            def getSolidLayer(
                self, state: EnergyPlusData, mat: Material.MaterialBase, t_Index: Int
            ) -> Arc[Tarcog.ISO15099.CBaseIGULayer]:
                var emissFront: Float64 = 0.0
                var emissBack: Float64 = 0.0
                var transThermalFront: Float64 = 0.0
                var transThermalBack: Float64 = 0.0
                var thickness: Float64 = 0.0
                var conductivity: Float64 = 0.0
                var createOpenness: Bool = False
                var Atop: Float64 = 0.0
                var Abot: Float64 = 0.0
                var Aleft: Float64 = 0.0
                var Aright: Float64 = 0.0
                var Afront: Float64 = 0.0
                if mat.group == Material.Group.Glass or mat.group == Material.Group.GlassSimple:
                    var matGlass = mat as Material.MaterialGlass
                    assert(matGlass is not None)
                    emissFront = matGlass.AbsorpThermalFront
                    emissBack = matGlass.AbsorpThermalBack
                    transThermalFront = matGlass.TransThermal
                    transThermalBack = matGlass.TransThermal
                    thickness = matGlass.Thickness
                    conductivity = matGlass.Conductivity
                elif mat.group == Material.Group.Blind:
                    var matBlind = mat as Material.MaterialBlind
                    assert(matBlind is not None)
                    thickness = matBlind.SlatThickness
                    conductivity = matBlind.SlatConductivity
                    Atop = matBlind.topOpeningMult
                    Abot = matBlind.bottomOpeningMult
                    Aleft = matBlind.leftOpeningMult
                    Aright = matBlind.rightOpeningMult
                    var slatAng = matBlind.SlatAngle * Constant.DegToRad
                    var PermA = sin(slatAng) - matBlind.SlatThickness / matBlind.SlatSeparation
                    var PermB = \
                        1.0 - (abs(matBlind.SlatWidth * cos(slatAng)) + matBlind.SlatThickness * sin(slatAng)) / matBlind.SlatSeparation
                    Afront = min(1.0, max(0.0, PermA, PermB))
                    var iSlatLo: Int
                    var iSlatHi: Int
                    var interpFac: Float64
                    Material.GetSlatIndicesInterpFac(slatAng, iSlatLo, iSlatHi, interpFac)
                    emissFront = Interp(matBlind.TARs[iSlatLo].IR.Ft.Emi, matBlind.TARs[iSlatHi].IR.Ft.Emi, interpFac)
                    emissBack = Interp(matBlind.TARs[iSlatLo].IR.Bk.Emi, matBlind.TARs[iSlatHi].IR.Bk.Emi, interpFac)
                    transThermalFront = Interp(matBlind.TARs[iSlatLo].IR.Ft.Tra, matBlind.TARs[iSlatHi].IR.Ft.Tra, interpFac)
                    transThermalBack = Interp(matBlind.TARs[iSlatLo].IR.Bk.Tra, matBlind.TARs[iSlatHi].IR.Bk.Tra, interpFac)
                    if t_Index == 1:
                        self.m_ExteriorShade = True
                elif mat.group == Material.Group.Shade:
                    var matShade = mat as Material.MaterialShade
                    assert(matShade is not None)
                    emissFront = matShade.AbsorpThermal
                    emissBack = matShade.AbsorpThermal
                    transThermalFront = matShade.TransThermal
                    transThermalBack = matShade.TransThermal
                    thickness = matShade.Thickness
                    conductivity = matShade.Conductivity
                    Atop = matShade.topOpeningMult
                    Abot = matShade.bottomOpeningMult
                    Aleft = matShade.leftOpeningMult
                    Aright = matShade.rightOpeningMult
                    Afront = matShade.airFlowPermeability
                    if t_Index == 1:
                        self.m_ExteriorShade = True
                elif mat.group == Material.Group.Screen:
                    var matScreen = mat as Material.MaterialScreen
                    assert(matScreen is not None)
                    emissFront = matScreen.AbsorpThermal
                    emissBack = matScreen.AbsorpThermal
                    transThermalFront = matScreen.TransThermal
                    transThermalBack = matScreen.TransThermal
                    thickness = matScreen.Thickness
                    conductivity = matScreen.Conductivity
                    Atop = matScreen.topOpeningMult
                    Abot = matScreen.bottomOpeningMult
                    Aleft = matScreen.leftOpeningMult
                    Aright = matScreen.rightOpeningMult
                    Afront = matScreen.airFlowPermeability
                    if t_Index == 1:
                        self.m_ExteriorShade = True
                elif mat.group == Material.Group.ComplexShade:
                    var matShade = mat as Material.MaterialComplexShade
                    assert(matShade is not None)
                    thickness = matShade.Thickness
                    conductivity = matShade.Conductivity
                    emissFront = matShade.FrontEmissivity
                    emissBack = matShade.BackEmissivity
                    transThermalFront = matShade.TransThermal
                    transThermalBack = matShade.TransThermal
                    Afront = matShade.frontOpeningMult
                    Atop = matShade.topOpeningMult
                    Abot = matShade.bottomOpeningMult
                    Aleft = matShade.leftOpeningMult
                    Aright = matShade.rightOpeningMult
                    createOpenness = True
                    self.m_InteriorBSDFShade = ((2 * t_Index - 1) == self.m_TotLay)
                var frontSurface = Arc(Tarcog.ISO15099.CSurface(emissFront, transThermalFront))
                var backSurface = Arc(Tarcog.ISO15099.CSurface(emissBack, transThermalBack))
                var aSolidLayer = \
                    Arc(Tarcog.ISO15099.CIGUSolidLayer(thickness, conductivity, frontSurface, backSurface))
                if createOpenness:
                    var aOpenings = Arc(Tarcog.ISO15099.CShadeOpenings(Atop, Abot, Aleft, Aright, Afront, Afront)) # (AUTO_OK_SPTR)
                    aSolidLayer = Arc(Tarcog.ISO15099.CIGUShadeLayer(aSolidLayer, aOpenings))
                alias standardizedRadiationIntensity: Float64 = 783.0
                if state.dataWindowManager.inExtWindowModel.isExternalLibraryModel():
                    var surface = state.dataSurface.Surface(self.m_SurfNum)
                    var ConstrNum = getActiveConstructionNumber(state, surface, self.m_SurfNum)
                    var aLayer = \
                        CWindowConstructionsSimplified.instance(state).getEquivalentLayer(
                            state, FenestrationCommon.WavelengthRange.Solar, ConstrNum)
                    alias Theta: Float64 = 0.0
                    alias Phi: Float64 = 0.0
                    var absCoeff = \
                        aLayer.getAbsorptanceLayer(t_Index, FenestrationCommon.Side.Front, FenestrationCommon.ScatteringSimple.Diffuse, Theta, Phi)
                    aSolidLayer.setSolarAbsorptance(absCoeff, standardizedRadiationIntensity)
                else:
                    var absCoeff = state.dataConstruction.Construct(state.dataSurface.Surface(self.m_SurfNum).Construction).AbsDiff(t_Index)
                    aSolidLayer.setSolarAbsorptance(absCoeff, standardizedRadiationIntensity)
                return aSolidLayer

            def getGapLayer(self, material: Material.MaterialBase) -> Arc[Tarcog.ISO15099.CBaseIGULayer]:
                alias pres: Float64 = 1e5 # Old code uses this constant pressure
                var thickness = material.Thickness
                var aGas = self.getGas(material) # (AUTO_OK_OBJ)
                var aLayer = Arc(Tarcog.ISO15099.CIGUGapLayer(thickness, pres, aGas))
                return aLayer

            def getShadeToGlassLayer(self, state: EnergyPlusData, t_Index: Int) -> Arc[Tarcog.ISO15099.CBaseIGULayer]:
                alias pres: Float64 = 1e5 # Old code uses this constant pressure
                var aGas = getAir()        # (AUTO_OK_OBJ)
                var thickness: Float64 = 0.0
                var s_mat = state.dataMaterial
                var surfWin = state.dataSurface.SurfaceWindow(self.m_SurfNum)
                var surfShade = state.dataSurface.surfShades(self.m_SurfNum)
                var ShadeFlag = getShadeType(state, self.m_ConstructionNumber)
                if ShadeFlag == WinShadingType.IntBlind or ShadeFlag == WinShadingType.ExtBlind:
                    thickness = (s_mat.materials(surfShade.blind.matNum) as Material.MaterialBlind).toGlassDist
                elif ShadeFlag == WinShadingType.ExtScreen:
                    thickness = (s_mat.materials(surfWin.screenNum) as Material.MaterialScreen).toGlassDist
                elif ShadeFlag == WinShadingType.IntShade or ShadeFlag == WinShadingType.ExtShade:
                    var material = self.getLayerMaterial(state, t_Index) as Material.MaterialShade
                    assert(material is not None)
                    thickness = material.toGlassDist
                var aLayer = Arc(Tarcog.ISO15099.CIGUGapLayer(thickness, pres, aGas))
                return aLayer

            def getComplexGapLayer(self, state: EnergyPlusData, materialBase: Material.MaterialBase) -> Arc[Tarcog.ISO15099.CBaseIGULayer]:
                alias pres: Float64 = 1e5 # Old code uses this constant pressure
                var mat = materialBase as Material.MaterialComplexWindowGap
                assert(mat is not None)
                var thickness = mat.Thickness
                var aGas = self.getGas(mat) # (AUTO_OK_OBJ)
                return Arc(Tarcog.ISO15099.CIGUGapLayer(thickness, pres, aGas))

            def getGas(self, materialBase: Material.MaterialBase) -> Gases.CGas:
                var matGas = materialBase as Material.MaterialGasMix
                assert(matGas is not None)
                var numGases = matGas.numGases
                alias vacuumCoeff: Float64 = 1.4 # Load vacuum coefficient once it is implemented (Simon).
                var gasName = matGas.Name
                var aGas = Gases.CGas()
                for i in range(numGases):
                    var gas = matGas.gases[i]
                    var wght = gas.wght
                    var fract = matGas.gasFracts[i]
                    var aCon = Gases.CIntCoeff(gas.con.c0, gas.con.c1, gas.con.c2)
                    var aCp = Gases.CIntCoeff(gas.cp.c0, gas.cp.c1, gas.cp.c2)
                    var aVis = Gases.CIntCoeff(gas.vis.c0, gas.vis.c1, gas.vis.c2)
                    var aData = Gases.CGasData(gasName, wght, vacuumCoeff, aCp, aCon, aVis)
                    aGas.addGasItem(fract, aData)
                return aGas

            @staticmethod
            def getAir() -> Gases.CGas:
                return Gases.CGas()

            def getIndoor(self, state: EnergyPlusData) -> Arc[Tarcog.ISO15099.CEnvironment]:
                var tin = self.m_Surface.getInsideAirTemperature(state, self.m_SurfNum) + Constant.Kelvin
                var hcin = state.dataHeatBalSurf.SurfHConvInt(self.m_SurfNum)
                var IR = state.dataSurface.SurfWinIRfromParentZone(self.m_SurfNum) + state.dataHeatBalSurf.SurfQdotRadHVACInPerArea(self.m_SurfNum)
                var Indoor = \
                    Arc(Tarcog.ISO15099.CIndoorEnvironment(tin, state.dataEnvrn.OutBaroPress))
                Indoor.setHCoeffModel(Tarcog.ISO15099.BoundaryConditionsCoeffModel.CalculateH, hcin)
                Indoor.setEnvironmentIR(IR)
                return Indoor

            def getOutdoor(self, state: EnergyPlusData, t_Hext: Float64) -> Arc[Tarcog.ISO15099.CEnvironment]:
                var tout = self.m_Surface.getOutsideAirTemperature(state, self.m_SurfNum) + Constant.Kelvin
                var IR = self.m_Surface.getOutsideIR(state, self.m_SurfNum)
                var swRadiation = self.m_Surface.getSWIncident(state, self.m_SurfNum)
                var tSky = state.dataEnvrn.SkyTempKelvin
                var airSpeed: Float64 = 0.0
                if self.m_Surface.ExtWind:
                    airSpeed = state.dataSurface.SurfOutWindSpeed(self.m_SurfNum)
                var fclr = 1 - state.dataEnvrn.CloudFraction
                var airDirection = Tarcog.ISO15099.AirHorizontalDirection.Windward
                var Outdoor = Arc(Tarcog.ISO15099.COutdoorEnvironment(
                    tout, airSpeed, swRadiation, airDirection, tSky, Tarcog.ISO15099.SkyModel.AllSpecified, state.dataEnvrn.OutBaroPress, fclr))
                Outdoor.setHCoeffModel(Tarcog.ISO15099.BoundaryConditionsCoeffModel.HcPrescribed, t_Hext)
                Outdoor.setEnvironmentIR(IR)
                return Outdoor

            def getIGU(self) -> Tarcog.ISO15099.CIGU:
                return Tarcog.ISO15099.CIGU(self.m_Surface.Width, self.m_Surface.Height, self.m_Surface.Tilt)

            def getIGU(self, width: Float64, height: Float64, tilt: Float64) -> Tarcog.ISO15099.CIGU:
                return Tarcog.ISO15099.CIGU(width, height, tilt)

            @staticmethod
            def getActiveConstructionNumber(
                state: EnergyPlusData, surface: DataSurfaces.SurfaceData, t_SurfNum: Int
            ) -> Int:
                var result = surface.Construction
                var ShadeFlag = state.dataSurface.SurfWinShadingFlag(t_SurfNum)
                if ANY_SHADE_SCREEN(ShadeFlag) or ANY_BLIND(ShadeFlag):
                    result = state.dataSurface.SurfWinActiveShadedConstruction(t_SurfNum)
                return result

            def isInteriorShade(self) -> Bool:
                return self.m_InteriorBSDFShade

            def getOutdoorNfrc(self, useSummerConditions: Bool) -> Arc[Tarcog.ISO15099.CEnvironment]:
                var airTemperature = -18.0 + Constant.Kelvin # Kelvins
                var airSpeed = 5.5                            # meters per second
                var tSky = -18.0 + Constant.Kelvin           # Kelvins
                var solarRadiation = 0.                       # W/m2
                if useSummerConditions:
                    airTemperature = 32.0 + Constant.Kelvin
                    airSpeed = 2.75
                    tSky = 32.0 + Constant.Kelvin
                    solarRadiation = 783.
                var Outdoor = \
                    Tarcog.ISO15099.Environments.outdoor(airTemperature, airSpeed, solarRadiation, tSky, Tarcog.ISO15099.SkyModel.AllSpecified)
                Outdoor.setHCoeffModel(Tarcog.ISO15099.BoundaryConditionsCoeffModel.CalculateH)
                return Outdoor

            def getIndoorNfrc(self, useSummerConditions: Bool) -> Arc[Tarcog.ISO15099.CEnvironment]:
                var roomTemperature = 21. + Constant.Kelvin
                if useSummerConditions:
                    roomTemperature = 24. + Constant.Kelvin
                return Tarcog.ISO15099.Environments.indoor(roomTemperature)

            @staticmethod
            def getShadeType(state: EnergyPlusData, ConstrNum: Int) -> WinShadingType:
                var s_mat = state.dataMaterial
                var ShadeFlag = WinShadingType.NoShade
                var TotLay = state.dataConstruction.Construct(ConstrNum).TotLayers
                var TotGlassLay = state.dataConstruction.Construct(ConstrNum).TotGlassLayers
                var matOutNum = state.dataConstruction.Construct(ConstrNum).LayerPoint(1)
                var matInNum = state.dataConstruction.Construct(ConstrNum).LayerPoint(TotLay)
                var matOut = s_mat.materials(matOutNum)
                var matIn = s_mat.materials(matInNum)
                if matOut.group == Material.Group.Shade: # Exterior shade present
                    ShadeFlag = WinShadingType.ExtShade
                elif matOut.group == Material.Group.Screen: # Exterior screen present
                    ShadeFlag = WinShadingType.ExtScreen
                elif matOut.group == Material.Group.Blind: # Exterior blind present
                    ShadeFlag = WinShadingType.ExtBlind
                elif matIn.group == Material.Group.Shade: # Interior shade present
                    ShadeFlag = WinShadingType.IntShade
                elif matIn.group == Material.Group.Blind: # Interior blind present
                    ShadeFlag = WinShadingType.IntBlind
                elif TotGlassLay == 2:
                    var mat3 = s_mat.materials(state.dataConstruction.Construct(ConstrNum).LayerPoint(3))
                    if mat3.group == Material.Group.Shade:
                        ShadeFlag = WinShadingType.BGShade
                    elif mat3.group == Material.Group.Blind:
                        ShadeFlag = WinShadingType.BGBlind
                elif TotGlassLay == 3:
                    var mat5 = s_mat.materials(state.dataConstruction.Construct(ConstrNum).LayerPoint(5))
                    if mat5.group == Material.Group.Shade:
                        ShadeFlag = WinShadingType.BGShade
                    elif mat5.group == Material.Group.Blind:
                        ShadeFlag = WinShadingType.BGBlind
                return ShadeFlag

            @staticmethod
            def overallUfactorFromFilmsAndCond(conductance: Float64, insideFilm: Float64, outsideFilm: Float64) -> Float64:
                var rOverall: Float64 = 0.
                var uFactor: Float64 = 0.
                if insideFilm != 0 and outsideFilm != 0. and conductance != 0.:
                    rOverall = 1 / insideFilm + 1 / conductance + 1 / outsideFilm
                if rOverall != 0.:
                    uFactor = 1 / rOverall
                return uFactor