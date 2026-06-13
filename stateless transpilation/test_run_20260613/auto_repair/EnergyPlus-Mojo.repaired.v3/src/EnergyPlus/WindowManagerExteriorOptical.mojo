# Mojo translation of WindowManagerExteriorOptical.cc
# Header context included directly

from WindowManagerExteriorData import *
from WindowManagerExteriorOptical import *  # self-reference, needed for classes
from Material import *
from Construction import *
from .Data.EnergyPlusData import *
from DataEnvironment import *
from DataHeatBalance import *
from DataSurfaces import *
from WindowManager import *
from WCESingleLayerOptics import *
from WCEMultiLayerOptics import *
from cassert import assert

alias FenestrationCommon = FenestrationCommon
alias SpectralAveraging = SpectralAveraging
alias SingleLayerOptics = SingleLayerOptics
alias DataEnvironment = DataEnvironment
alias DataSurfaces = DataSurfaces
alias DataHeatBalance = DataHeatBalance

namespace EnergyPlus:
    namespace Window:
        # Function implementations from body
        def getBSDFLayer(
            state: EnergyPlusData,
            t_Material: Pointer[Material.MaterialBase],
            t_Range: FenestrationCommon.WavelengthRange
        ) -> Pointer[SingleLayerOptics.CBSDFLayer]:
            var aFactory: Pointer[CWCELayerFactory] = None
            if t_Material.group == Material.Group.Glass:
                aFactory = Pointer[CWCESpecularLayerFactory].alloc(t_Material, t_Range)
            elif t_Material.group == Material.Group.Blind:
                aFactory = Pointer[CWCEVenetianBlindLayerFactory].alloc(t_Material, t_Range)
            elif t_Material.group == Material.Group.Screen:
                aFactory = Pointer[CWCEScreenLayerFactory].alloc(t_Material, t_Range)
            elif t_Material.group == Material.Group.Shade:
                aFactory = Pointer[CWCEDiffuseShadeLayerFactory].alloc(t_Material, t_Range)
            return aFactory.getBSDFLayer(state)

        def getScatteringLayer(
            state: EnergyPlusData,
            t_Material: Pointer[Material.MaterialBase],
            t_Range: FenestrationCommon.WavelengthRange
        ) -> SingleLayerOptics.CScatteringLayer:
            var aFactory: Pointer[CWCELayerFactory] = None
            if t_Material.group == Material.Group.Glass or t_Material.group == Material.Group.GlassSimple:
                aFactory = Pointer[CWCESpecularLayerFactory].alloc(t_Material, t_Range)
            elif t_Material.group == Material.Group.Blind:
                aFactory = Pointer[CWCEVenetianBlindLayerFactory].alloc(t_Material, t_Range)
            elif t_Material.group == Material.Group.Screen:
                aFactory = Pointer[CWCEScreenLayerFactory].alloc(t_Material, t_Range)
            elif t_Material.group == Material.Group.Shade:
                aFactory = Pointer[CWCEDiffuseShadeLayerFactory].alloc(t_Material, t_Range)
            return aFactory.getLayer(state)

        def InitWCE_SimplifiedOpticalData(state: EnergyPlusData):
            var s_mat = state.dataMaterial
            if s_mat.NumBlinds > 0:
                CalcWindowBlindProperties(state)
            if s_mat.NumScreens > 0:
                CalcWindowScreenProperties(state)
            var aWinConstSimp = CWindowConstructionsSimplified.instance(state)
            for ConstrNum in range(1, state.dataHeatBal.TotConstructs + 1):
                var construction = state.dataConstruction.Construct[ConstrNum]
                if construction.isGlazingConstruction(state):
                    for LayNum in range(1, construction.TotLayers + 1):
                        var mat = s_mat.materials[construction.LayerPoint[LayNum]]
                        if mat.group != Material.Group.Gas and mat.group != Material.Group.GasMixture and mat.group != Material.Group.ComplexWindowGap and mat.group != Material.Group.ComplexShade:
                            construction.TransDiff = 0.1
                            var aRange: FenestrationCommon.WavelengthRange = FenestrationCommon.WavelengthRange.Solar
                            var aSolarLayer = getScatteringLayer(state, mat, aRange)
                            aWinConstSimp.pushLayer(aRange, ConstrNum, aSolarLayer)
                            aRange = FenestrationCommon.WavelengthRange.Visible
                            var aVisibleLayer = getScatteringLayer(state, mat, aRange)
                            aWinConstSimp.pushLayer(aRange, ConstrNum, aVisibleLayer)
            for SurfNum in range(1, state.dataSurface.TotSurfaces + 1):
                var surf = state.dataSurface.Surface[SurfNum]
                var surfShade = state.dataSurface.surfShades[SurfNum]
                if not surf.HeatTransSurf:
                    continue
                if not state.dataConstruction.Construct[surf.Construction].TypeIsWindow:
                    continue
                if state.dataSurface.SurfWinWindowModelType[SurfNum] == WindowModel.BSDF:
                    continue
                if state.dataConstruction.Construct[surf.Construction].WindowTypeEQL:
                    continue
                if surf.activeShadedConstruction == 0:
                    continue
                var constrSh = state.dataConstruction.Construct[surf.activeShadedConstruction]
                var TotLay = constrSh.TotLayers
                var mat = s_mat.materials[constrSh.LayerPoint[TotLay]]
                if mat.group == Material.Group.Shade:
                    var matShade = mat as Pointer[Material.MaterialShade]
                    var EpsGlIR = s_mat.materials[constrSh.LayerPoint[TotLay - 1]].AbsorpThermalBack
                    var RhoGlIR = 1.0 - EpsGlIR
                    var TauShIR = matShade.TransThermal
                    var EpsShIR = matShade.AbsorpThermal
                    var RhoShIR = max(0.0, 1.0 - TauShIR - EpsShIR)
                    surfShade.effShadeEmi = EpsShIR * (1.0 + RhoGlIR * TauShIR / (1.0 - RhoGlIR * RhoShIR))
                    surfShade.effGlassEmi = EpsGlIR * TauShIR / (1.0 - RhoGlIR * RhoShIR)
                elif mat.group == Material.Group.Blind:
                    var EpsGlIR = s_mat.materials[constrSh.LayerPoint[TotLay - 1]].AbsorpThermalBack
                    var RhoGlIR = 1.0 - EpsGlIR
                    var matBlind = mat as Pointer[Material.MaterialBlind]
                    for iSlatAng in range(Material.MaxSlatAngs):
                        var btar = matBlind.TARs[iSlatAng]
                        var TauShIR = btar.IR.Ft.Tra
                        var EpsShIR = btar.IR.Ft.Emi
                        var RhoShIR = max(0.0, 1.0 - TauShIR - EpsShIR)
                        constrSh.effShadeBlindEmi[iSlatAng] = EpsShIR * (1.0 + RhoGlIR * TauShIR / (1.0 - RhoGlIR * RhoShIR))
                        constrSh.effGlassEmi[iSlatAng] = EpsGlIR * TauShIR / (1.0 - RhoGlIR * RhoShIR)
            # End of surface loop

        def GetSolarTransDirectHemispherical(state: EnergyPlusData, ConstrNum: Int) -> Float64:
            var aWinConstSimp = CWindowConstructionsSimplified.instance(state).getEquivalentLayer(state, FenestrationCommon.WavelengthRange.Solar, ConstrNum)
            return aWinConstSimp.getPropertySimple(0.3, 2.5, FenestrationCommon.PropertySimple.T, FenestrationCommon.Side.Front, FenestrationCommon.Scattering.DirectHemispherical)

        def GetVisibleTransDirectHemispherical(state: EnergyPlusData, ConstrNum: Int) -> Float64:
            var aWinConstSimp = CWindowConstructionsSimplified.instance(state).getEquivalentLayer(state, FenestrationCommon.WavelengthRange.Visible, ConstrNum)
            return aWinConstSimp.getPropertySimple(0.38, 0.78, FenestrationCommon.PropertySimple.T, FenestrationCommon.Side.Front, FenestrationCommon.Scattering.DirectHemispherical)

        # Class CWCEMaterialFactory
        trait CWCEMaterialFactory:
            def init(self, state: EnergyPlusData) -> None
            def getMaterial(self, state: EnergyPlusData) -> Pointer[SingleLayerOptics.CMaterial]:
                if not self.m_Initialized:
                    self.init(state)
                    self.m_Initialized = True
                return self.m_Material

            var m_Material: Pointer[SingleLayerOptics.CMaterial]
            var m_MaterialProperties: Pointer[Material.MaterialBase]
            var m_Range: FenestrationCommon.WavelengthRange
            var m_Initialized: Bool

        # CWCESpecularMaterialsFactory
        struct CWCESpecularMaterialsFactory(CWCEMaterialFactory):
            def __init__(self, t_Material: Pointer[Material.MaterialBase], t_Range: FenestrationCommon.WavelengthRange):
                self.m_MaterialProperties = t_Material
                self.m_Range = t_Range
                self.m_Initialized = False
                self.m_Material = None

            def init(self, state: EnergyPlusData) -> None:
                var matGlass = self.m_MaterialProperties as Pointer[Material.MaterialGlass]
                assert(matGlass != None)
                if matGlass.GlassSpectralDataPtr > 0:
                    var aSolarSpectrum = CWCESpecturmProperties.getDefaultSolarRadiationSpectrum(state)
                    var aSampleData: Pointer[CSpectralSampleData] = None
                    aSampleData = CWCESpecturmProperties.getSpectralSample(state, matGlass.GlassSpectralDataPtr)
                    var aSample = Pointer[CSpectralSample].alloc(aSampleData, aSolarSpectrum)
                    var aType: FenestrationCommon.MaterialType = MaterialType.Monolithic
                    var aRange = CWavelengthRange(self.m_Range)
                    var lowLambda = aRange.minLambda()
                    var highLambda = aRange.maxLambda()
                    if self.m_Range == FenestrationCommon.WavelengthRange.Visible and matGlass.GlassSpectralDataPtr != 0:
                        var aPhotopicResponse = CWCESpecturmProperties.getDefaultVisiblePhotopicResponse(state)
                        aSample.setDetectorData(aPhotopicResponse)
                    var thickness = matGlass.Thickness
                    self.m_Material = Pointer[CMaterialSample].alloc(aSample, thickness, aType, lowLambda, highLambda)
                else:
                    if self.m_Range == FenestrationCommon.WavelengthRange.Solar:
                        self.m_Material = Pointer[CMaterialSingleBand].alloc(matGlass.Trans, matGlass.Trans, matGlass.ReflectSolBeamFront, matGlass.ReflectSolBeamBack, self.m_Range)
                    if self.m_Range == FenestrationCommon.WavelengthRange.Visible:
                        self.m_Material = Pointer[CMaterialSingleBand].alloc(matGlass.TransVis, matGlass.TransVis, matGlass.ReflectVisBeamFront, matGlass.ReflectVisBeamBack, self.m_Range)

        # CWCEMaterialDualBandFactory
        trait CWCEMaterialDualBandFactory(CWCEMaterialFactory):
            def createVisibleRangeMaterial(self, state: EnergyPlusData) -> Pointer[SingleLayerOptics.CMaterialSingleBand]
            def createSolarRangeMaterial(self, state: EnergyPlusData) -> Pointer[SingleLayerOptics.CMaterialSingleBand]

            def init(self, state: EnergyPlusData) -> None:
                if self.m_Range == FenestrationCommon.WavelengthRange.Visible:
                    self.m_Material = self.createVisibleRangeMaterial(state)
                else:
                    var aVisibleRangeMaterial = self.createVisibleRangeMaterial(state)
                    var aSolarRangeMaterial = self.createSolarRangeMaterial(state)
                    var ratio: Float64 = 0.49
                    self.m_Material = Pointer[CMaterialDualBand].alloc(aVisibleRangeMaterial, aSolarRangeMaterial, ratio)

        # CWCEVenetianBlindMaterialsFactory
        struct CWCEVenetianBlindMaterialsFactory(CWCEMaterialDualBandFactory):
            def __init__(self, t_Material: Pointer[Material.MaterialBase], t_Range: FenestrationCommon.WavelengthRange):
                self.m_MaterialProperties = t_Material
                self.m_Range = t_Range
                self.m_Initialized = False
                self.m_Material = None

            def createVisibleRangeMaterial(self, state: EnergyPlusData) -> Pointer[SingleLayerOptics.CMaterialSingleBand]:
                var matBlind = self.m_MaterialProperties as Pointer[Material.MaterialBlind]
                assert(matBlind != None)
                var aRange = CWavelengthRange(FenestrationCommon.WavelengthRange.Visible)
                var lowLambda = aRange.minLambda()
                var highLambda = aRange.maxLambda()
                var Tf = matBlind.slatTAR.Vis.Ft.Df.Tra
                var Tb = matBlind.slatTAR.Vis.Ft.Df.Tra
                var Rf = matBlind.slatTAR.Vis.Ft.Df.Ref
                var Rb = matBlind.slatTAR.Vis.Bk.Df.Ref
                return Pointer[CMaterialSingleBand].alloc(Tf, Tb, Rf, Rb, lowLambda, highLambda)

            def createSolarRangeMaterial(self, state: EnergyPlusData) -> Pointer[SingleLayerOptics.CMaterialSingleBand]:
                var matBlind = self.m_MaterialProperties as Pointer[Material.MaterialBlind]
                assert(matBlind != None)
                var aRange = CWavelengthRange(FenestrationCommon.WavelengthRange.Solar)
                var lowLambda = aRange.minLambda()
                var highLambda = aRange.maxLambda()
                var Tf = matBlind.slatTAR.Sol.Ft.Df.Tra
                var Tb = matBlind.slatTAR.Sol.Ft.Df.Tra
                var Rf = matBlind.slatTAR.Sol.Ft.Df.Ref
                var Rb = matBlind.slatTAR.Sol.Bk.Df.Ref
                return Pointer[CMaterialSingleBand].alloc(Tf, Tb, Rf, Rb, lowLambda, highLambda)

        # CWCEScreenMaterialsFactory
        struct CWCEScreenMaterialsFactory(CWCEMaterialDualBandFactory):
            def __init__(self, t_Material: Pointer[Material.MaterialBase], t_Range: FenestrationCommon.WavelengthRange):
                self.m_MaterialProperties = t_Material
                self.m_Range = t_Range
                self.m_Initialized = False
                self.m_Material = None

            def createVisibleRangeMaterial(self, state: EnergyPlusData) -> Pointer[SingleLayerOptics.CMaterialSingleBand]:
                var matShade = self.m_MaterialProperties as Pointer[Material.MaterialShade]
                assert(matShade != None)
                var aRange = CWavelengthRange(FenestrationCommon.WavelengthRange.Visible)
                var lowLambda = aRange.minLambda()
                var highLambda = aRange.maxLambda()
                var Tf: Float64 = 0.0
                var Tb: Float64 = 0.0
                var Rf = matShade.ReflectShadeVis
                var Rb = matShade.ReflectShadeVis
                return Pointer[CMaterialSingleBand].alloc(Tf, Tb, Rf, Rb, lowLambda, highLambda)

            def createSolarRangeMaterial(self, state: EnergyPlusData) -> Pointer[SingleLayerOptics.CMaterialSingleBand]:
                var matShade = self.m_MaterialProperties as Pointer[Material.MaterialShade]
                assert(matShade != None)
                var aRange = CWavelengthRange(FenestrationCommon.WavelengthRange.Solar)
                var lowLambda = aRange.minLambda()
                var highLambda = aRange.maxLambda()
                var Tf: Float64 = 0.0
                var Tb: Float64 = 0.0
                var Rf = matShade.ReflectShade
                var Rb = matShade.ReflectShade
                return Pointer[CMaterialSingleBand].alloc(Tf, Tb, Rf, Rb, lowLambda, highLambda)

        # CWCEDiffuseShadeMaterialsFactory
        struct CWCEDiffuseShadeMaterialsFactory(CWCEMaterialDualBandFactory):
            def __init__(self, t_Material: Pointer[Material.MaterialBase], t_Range: FenestrationCommon.WavelengthRange):
                self.m_MaterialProperties = t_Material
                self.m_Range = t_Range
                self.m_Initialized = False
                self.m_Material = None

            def createVisibleRangeMaterial(self, state: EnergyPlusData) -> Pointer[SingleLayerOptics.CMaterialSingleBand]:
                var matShade = self.m_MaterialProperties as Pointer[Material.MaterialShade]
                assert(matShade != None)
                var aRange = CWavelengthRange(FenestrationCommon.WavelengthRange.Visible)
                var lowLambda = aRange.minLambda()
                var highLambda = aRange.maxLambda()
                var Tf = matShade.TransVis
                var Tb = matShade.TransVis
                var Rf = matShade.ReflectShadeVis
                var Rb = matShade.ReflectShadeVis
                return Pointer[CMaterialSingleBand].alloc(Tf, Tb, Rf, Rb, lowLambda, highLambda)

            def createSolarRangeMaterial(self, state: EnergyPlusData) -> Pointer[SingleLayerOptics.CMaterialSingleBand]:
                var matShade = self.m_MaterialProperties as Pointer[Material.MaterialShade]
                assert(matShade != None)
                var aRange = CWavelengthRange(FenestrationCommon.WavelengthRange.Solar)
                var lowLambda = aRange.minLambda()
                var highLambda = aRange.maxLambda()
                var Tf = matShade.Trans
                var Tb = matShade.Trans
                var Rf = matShade.ReflectShade
                var Rb = matShade.ReflectShade
                return Pointer[CMaterialSingleBand].alloc(Tf, Tb, Rf, Rb, lowLambda, highLambda)

        # IWCECellDescriptionFactory
        trait IWCECellDescriptionFactory:
            def getCellDescription(self, state: EnergyPlusData) -> Pointer[SingleLayerOptics.ICellDescription]

            var m_Material: Pointer[Material.MaterialBase]

        # CWCESpecularCellFactory
        struct CWCESpecularCellFactory(IWCECellDescriptionFactory):
            def __init__(self, t_Material: Pointer[Material.MaterialBase]):
                self.m_Material = t_Material

            def getCellDescription(self, state: EnergyPlusData) -> Pointer[SingleLayerOptics.ICellDescription]:
                return Pointer[CSpecularCellDescription].alloc()

        # CWCEVenetianBlindCellFactory
        struct CWCEVenetianBlindCellFactory(IWCECellDescriptionFactory):
            def __init__(self, t_Material: Pointer[Material.MaterialBase]):
                self.m_Material = t_Material

            def getCellDescription(self, state: EnergyPlusData) -> Pointer[SingleLayerOptics.ICellDescription]:
                var matBlind = self.m_Material as Pointer[Material.MaterialBlind]
                assert(matBlind != None)
                var slatWidth = matBlind.SlatWidth
                var slatSpacing = matBlind.SlatSeparation
                var slatTiltAngle = 90.0 - matBlind.SlatAngle
                var curvatureRadius: Float64 = 0.0
                var numOfSlatSegments: Int = 5
                return Pointer[CVenetianCellDescription].alloc(slatWidth, slatSpacing, slatTiltAngle, curvatureRadius, numOfSlatSegments)

        # CWCEScreenCellFactory
        struct CWCEScreenCellFactory(IWCECellDescriptionFactory):
            def __init__(self, t_Material: Pointer[Material.MaterialBase]):
                self.m_Material = t_Material

            def getCellDescription(self, state: EnergyPlusData) -> Pointer[SingleLayerOptics.ICellDescription]:
                var diameter = self.m_Material.Thickness
                var ratio = 1.0 - sqrt((self.m_Material as Pointer[Material.MaterialScreen]).Trans)
                var spacing = diameter / ratio
                return Pointer[CWovenCellDescription].alloc(diameter, spacing)

        # CWCEDiffuseShadeCellFactory
        struct CWCEDiffuseShadeCellFactory(IWCECellDescriptionFactory):
            def __init__(self, t_Material: Pointer[Material.MaterialBase]):
                self.m_Material = t_Material

            def getCellDescription(self, state: EnergyPlusData) -> Pointer[SingleLayerOptics.ICellDescription]:
                return Pointer[CFlatCellDescription].alloc()

        # CWCELayerFactory
        trait CWCELayerFactory:
            def createMaterialFactory(self) -> None
            def init(self, state: EnergyPlusData) -> Tuple[Pointer[SingleLayerOptics.CMaterial], Pointer[SingleLayerOptics.ICellDescription]]:
                self.createMaterialFactory()
                var aMaterial = self.m_MaterialFactory.getMaterial(state)
                assert(aMaterial != None)
                var aCellDescription = self.getCellDescription(state)
                assert(aCellDescription != None)
                return (aMaterial, aCellDescription)

            def getBSDFLayer(self, state: EnergyPlusData) -> Pointer[SingleLayerOptics.CBSDFLayer]:
                if not self.m_BSDFInitialized:
                    var res = self.init(state)
                    var aBSDF = CBSDFHemisphere.create(BSDFBasis.Full)
                    var aMaker = CBSDFLayerMaker(res.left, aBSDF, res.right)
                    self.m_BSDFLayer = aMaker.getLayer()
                    self.m_BSDFInitialized = True
                return self.m_BSDFLayer

            def getLayer(self, state: EnergyPlusData) -> SingleLayerOptics.CScatteringLayer:
                if not self.m_SimpleInitialized:
                    var res = self.init(state)
                    self.m_ScatteringLayer = CScatteringLayer(res.left, res.right)
                    self.m_SimpleInitialized = True
                return self.m_ScatteringLayer

            def getCellDescription(self, state: EnergyPlusData) -> Pointer[SingleLayerOptics.ICellDescription]:
                return self.m_CellFactory.getCellDescription(state)

            var m_Material: Pointer[Material.MaterialBase]
            var m_Range: FenestrationCommon.WavelengthRange
            var m_BSDFInitialized: Bool
            var m_SimpleInitialized: Bool
            var m_MaterialFactory: Pointer[CWCEMaterialFactory]
            var m_CellFactory: Pointer[IWCECellDescriptionFactory]
            var m_BSDFLayer: Pointer[SingleLayerOptics.CBSDFLayer]
            var m_ScatteringLayer: SingleLayerOptics.CScatteringLayer

        # CWCESpecularLayerFactory
        struct CWCESpecularLayerFactory(CWCELayerFactory):
            def __init__(self, t_Material: Pointer[Material.MaterialBase], t_Range: FenestrationCommon.WavelengthRange):
                self.m_Material = t_Material
                self.m_Range = t_Range
                self.m_BSDFInitialized = False
                self.m_SimpleInitialized = False
                self.m_MaterialFactory = None
                self.m_CellFactory = Pointer[CWCESpecularCellFactory].alloc(t_Material)

            def createMaterialFactory(self) -> None:
                self.m_MaterialFactory = Pointer[CWCESpecularMaterialsFactory].alloc(self.m_Material, self.m_Range)

        # CWCEVenetianBlindLayerFactory
        struct CWCEVenetianBlindLayerFactory(CWCELayerFactory):
            def __init__(self, t_Material: Pointer[Material.MaterialBase], t_Range: FenestrationCommon.WavelengthRange):
                self.m_Material = t_Material
                self.m_Range = t_Range
                self.m_BSDFInitialized = False
                self.m_SimpleInitialized = False
                self.m_MaterialFactory = None
                self.m_CellFactory = Pointer[CWCEVenetianBlindCellFactory].alloc(t_Material)

            def createMaterialFactory(self) -> None:
                self.m_MaterialFactory = Pointer[CWCEVenetianBlindMaterialsFactory].alloc(self.m_Material, self.m_Range)

        # CWCEScreenLayerFactory
        struct CWCEScreenLayerFactory(CWCELayerFactory):
            def __init__(self, t_Material: Pointer[Material.MaterialBase], t_Range: FenestrationCommon.WavelengthRange):
                self.m_Material = t_Material
                self.m_Range = t_Range
                self.m_BSDFInitialized = False
                self.m_SimpleInitialized = False
                self.m_MaterialFactory = None
                self.m_CellFactory = Pointer[CWCEScreenCellFactory].alloc(t_Material)

            def createMaterialFactory(self) -> None:
                self.m_MaterialFactory = Pointer[CWCEScreenMaterialsFactory].alloc(self.m_Material, self.m_Range)

        # CWCEDiffuseShadeLayerFactory
        struct CWCEDiffuseShadeLayerFactory(CWCELayerFactory):
            def __init__(self, t_Material: Pointer[Material.MaterialBase], t_Range: FenestrationCommon.WavelengthRange):
                self.m_Material = t_Material
                self.m_Range = t_Range
                self.m_BSDFInitialized = False
                self.m_SimpleInitialized = False
                self.m_MaterialFactory = None
                self.m_CellFactory = Pointer[CWCEDiffuseShadeCellFactory].alloc(t_Material)

            def createMaterialFactory(self) -> None:
                self.m_MaterialFactory = Pointer[CWCEDiffuseShadeMaterialsFactory].alloc(self.m_Material, self.m_Range)