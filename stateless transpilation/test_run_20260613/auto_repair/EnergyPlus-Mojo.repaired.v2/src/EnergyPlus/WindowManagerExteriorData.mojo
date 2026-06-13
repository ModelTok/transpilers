from DataSurfaces import *
from DataHeatBalance import *
from WindowComplexManager import *
from SingleLayerOptics import *
from FenestrationCommon import *
from SpectralAveraging import *
from MultiLayerOptics import *
from Material import MaterialGlass
from DataVectorTypes import Vector
from Constant import Constant
from UtilityRoutines import ShowFatalError
from WindowManager import W6CoordsFromWorldVect, RayIdentificationType
from DataBSDFWindow import *
from DataGlobal import *
from DataWindowManager import *
from DataMaterial import *
from WCEMultiLayerOptics import *
from .Data.EnergyPlusData import EnergyPlusData
from WindowManagerExteriorData import WindowManagerExteriorData, CWindowConstructionsSimplified, CWCESpecturmProperties
from memory import Pointer
from math import pi
from utils import Real64, Int

def isSurfaceHit(state: EnergyPlusData, t_SurfNum: Int, t_Ray: Vector) -> Bool:
    var DotProd: Real64 = dot(t_Ray, state.dataSurface.Surface(t_SurfNum).NewellSurfaceNormalVector)
    return (DotProd > 0)

def getWCECoordinates(state: EnergyPlusData, t_SurfNum: Int, t_Ray: Vector, t_Direction: BSDFDirection) -> Tuple[Real64, Real64]:
    var Theta: Real64 = 0
    var Phi: Real64 = 0
    var Gamma: Real64 = Constant.DegToRad * state.dataSurface.Surface(t_SurfNum).Tilt
    var Alpha: Real64 = Constant.DegToRad * state.dataSurface.Surface(t_SurfNum).Azimuth
    var RadType: RayIdentificationType = RayIdentificationType.Front_Incident
    if t_Direction == BSDFDirection.Outgoing:
        RadType = RayIdentificationType.Back_Incident
    W6CoordsFromWorldVect(state, t_Ray, RadType, Gamma, Alpha, Theta, Phi)
    Theta = 180 / Constant.Pi * Theta
    Phi = 180 / Constant.Pi * Phi
    return (Theta, Phi)

def getSunWCEAngles(state: EnergyPlusData, t_SurfNum: Int, t_Direction: BSDFDirection) -> Tuple[Real64, Real64]:
    return getWCECoordinates(
        state, t_SurfNum, state.dataBSDFWindow.SUNCOSTS[state.dataGlobal.TimeStep][state.dataGlobal.HourOfDay], t_Direction
    )

def getDefaultSolarRadiationSpectrum(state: EnergyPlusData) -> CSeries:
    var solarRadiation: CSeries = CSeries()
    for i in range(1, nume + 1):
        solarRadiation.addProperty(state.dataWindowManager.wle[i - 1], state.dataWindowManager.e[i - 1])
    return solarRadiation

def getDefaultVisiblePhotopicResponse(state: EnergyPlusData) -> CSeries:
    var visibleResponse: CSeries = CSeries()
    for i in range(1, numt3 + 1):
        visibleResponse.addProperty(state.dataWindowManager.wlt3[i - 1], state.dataWindowManager.y30[i - 1])
    return visibleResponse

def getSpectralSample(state: EnergyPlusData, t_SampleDataPtr: Int) -> Pointer[CSpectralSampleData]:
    var s_mat = state.dataMaterial
    assert(t_SampleDataPtr != 0)
    var aSampleData: Pointer[CSpectralSampleData] = Pointer[CSpectralSampleData].alloc(1)
    aSampleData[0] = CSpectralSampleData()
    var spectralData = s_mat.SpectralData(t_SampleDataPtr)
    var numOfWl: Int = spectralData.NumOfWavelengths
    for i in range(1, numOfWl + 1):
        var wl: Real64 = spectralData.WaveLength(i)
        var T: Real64 = spectralData.Trans(i)
        var Rf: Real64 = spectralData.ReflFront(i)
        var Rb: Real64 = spectralData.ReflBack(i)
        aSampleData[0].addRecord(wl, T, Rf, Rb)
    return aSampleData

def getSpectralSampleFromMaterial(t_MaterialProperties: MaterialGlass) -> Pointer[CSpectralSampleData]:
    var Tsol: Real64 = t_MaterialProperties.Trans
    var Rfsol: Real64 = t_MaterialProperties.ReflectSolBeamFront
    var Rbsol: Real64 = t_MaterialProperties.ReflectSolBeamBack
    var aSolMat: Pointer[CMaterial] = Pointer[CMaterial].alloc(1)
    aSolMat[0] = CMaterialSingleBand(Tsol, Tsol, Rfsol, Rbsol, 0.3, 2.5)
    var Tvis: Real64 = t_MaterialProperties.TransVis
    var Rfvis: Real64 = t_MaterialProperties.ReflectVisBeamFront
    var Rbvis: Real64 = t_MaterialProperties.ReflectVisBeamBack
    var aVisMat: Pointer[CMaterial] = Pointer[CMaterial].alloc(1)
    aVisMat[0] = CMaterialSingleBand(Tvis, Tvis, Rfvis, Rfvis, 0.38, 0.78)
    var aMat: CMaterialDualBand = CMaterialDualBand(aVisMat[0], aSolMat[0], 0.49)
    var aWl: List[Real64] = aMat.getBandWavelengths()
    var aTf: List[Real64] = aMat.getBandProperties(Property.T, Side.Front)
    var aRf: List[Real64] = aMat.getBandProperties(Property.R, Side.Front)
    var aRb: List[Real64] = aMat.getBandProperties(Property.R, Side.Back)
    var aSampleData: Pointer[CSpectralSampleData] = Pointer[CSpectralSampleData].alloc(1)
    aSampleData[0] = CSpectralSampleData()
    for i in range(len(aWl)):
        aSampleData[0].addRecord(aWl[i], aTf[i], aRf[i], aRb[i])
    return aSampleData

def instance(state: EnergyPlusData) -> Pointer[CWindowConstructionsSimplified]:
    if state.dataWindowManagerExterior.p_inst == None:
        state.dataWindowManagerExterior.p_inst = Pointer[CWindowConstructionsSimplified].alloc(1)
        state.dataWindowManagerExterior.p_inst[0] = CWindowConstructionsSimplified()
    return state.dataWindowManagerExterior.p_inst

def CWindowConstructionsSimplified_init() -> CWindowConstructionsSimplified:
    var self: CWindowConstructionsSimplified
    self.m_Layers = Dict[WavelengthRange, Dict[Int, List[SingleLayerOptics.CScatteringLayer]]]()
    self.m_Layers[WavelengthRange.Solar] = Dict[Int, List[SingleLayerOptics.CScatteringLayer]]()
    self.m_Layers[WavelengthRange.Visible] = Dict[Int, List[SingleLayerOptics.CScatteringLayer]]()
    self.m_Equivalent = Dict[Tuple[WavelengthRange, Int], Pointer[MultiLayerOptics.CMultiLayerScattered]]()
    return self

def pushLayer(inout self: CWindowConstructionsSimplified, t_Range: WavelengthRange, t_ConstrNum: Int, t_Layer: SingleLayerOptics.CScatteringLayer):
    var aMap: Dict[Int, List[SingleLayerOptics.CScatteringLayer]] = self.m_Layers[t_Range]
    if t_ConstrNum not in aMap:
        aMap[t_ConstrNum] = List[SingleLayerOptics.CScatteringLayer]()
    aMap[t_ConstrNum].append(t_Layer)

def getEquivalentLayer(inout self: CWindowConstructionsSimplified, state: EnergyPlusData, t_Range: WavelengthRange, t_ConstrNum: Int) -> Pointer[MultiLayerOptics.CMultiLayerScattered]:
    var key: Tuple[WavelengthRange, Int] = (t_Range, t_ConstrNum)
    if key not in self.m_Equivalent:
        var iguLayers: List[SingleLayerOptics.CScatteringLayer] = getLayers(self, state, t_Range, t_ConstrNum)
        var aEqLayer: Pointer[MultiLayerOptics.CMultiLayerScattered] = Pointer[MultiLayerOptics.CMultiLayerScattered].alloc(1)
        aEqLayer[0] = MultiLayerOptics.CMultiLayerScattered(iguLayers[0])
        for i in range(1, len(iguLayers)):
            aEqLayer[0].addLayer(iguLayers[i])
        var aSolarSpectrum: CSeries = getDefaultSolarRadiationSpectrum(state)
        aEqLayer[0].setSourceData(aSolarSpectrum)
        self.m_Equivalent[key] = aEqLayer
    return self.m_Equivalent[key]

def clearState():

def getLayers(self: CWindowConstructionsSimplified, state: EnergyPlusData, t_Range: WavelengthRange, t_ConstrNum: Int) -> List[SingleLayerOptics.CScatteringLayer]:
    var aMap: Dict[Int, List[SingleLayerOptics.CScatteringLayer]] = self.m_Layers[t_Range]
    if t_ConstrNum not in aMap:
        ShowFatalError(state, "Incorrect construction selection.")
    return aMap[t_ConstrNum]