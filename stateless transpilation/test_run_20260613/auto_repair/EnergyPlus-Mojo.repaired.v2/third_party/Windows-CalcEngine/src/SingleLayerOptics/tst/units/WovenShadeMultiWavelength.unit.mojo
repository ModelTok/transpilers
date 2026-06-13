from WCESingleLayerOptics import CBSDFLayer, CBSDFHemisphere, CBSDFLayerMaker, Material, CBSDFIntegrator, BSDFBasis, Side, PropertySimple
from WCECommon import SpectralAveraging

@value
struct TestWovenShadeMultiWavelength:
    var m_Layer: CBSDFLayer
    
    def __init__(inout self):
        self.m_Layer = CBSDFLayer()
    
    def SetUp(inout self):
        let Tsol = 0.1
        let Rfsol = 0.7
        let Rbsol = 0.7
        let Tvis = 0.2
        let Rfvis = 0.6
        let Rbvis = 0.6
        let aMaterial = Material.dualBandMaterial(Tsol, Tsol, Rfsol, Rbsol, Tvis, Tvis, Rfvis, Rbvis)
        let diameter = 6.35
        let spacing = 19.05
        let aBSDF = CBSDFHemisphere.create(BSDFBasis.Quarter)
        self.m_Layer = CBSDFLayerMaker.getWovenLayer(aMaterial, aBSDF, diameter, spacing)
    
    def getLayer(self) -> CBSDFLayer:
        return self.m_Layer

def TestWovenMultiWavelength():
    SCOPED_TRACE("Begin Test: Perforated layer (multi range) - BSDF.")
    let aLayer = TestWovenShadeMultiWavelength().getLayer()
    let aResults = aLayer.getWavelengthResults()
    let correctSize = 4
    assert len(aResults) == correctSize
    
    var correctResults: List[Float64]
    var aT = aResults[0].getMatrix(Side.Front, PropertySimple.T)
    var size = len(aT)
    correctResults = [5.780996, 6.070652, 6.069898, 6.054181, 6.069898, 6.070652, 6.069898,
                      6.054181, 6.069898, 5.094622, 5.119753, 4.995444, 4.78271,  4.995444,
                      5.119753, 5.094622, 5.119753, 4.995444, 4.78271,  4.995444, 5.119753,
                      3.750925, 3.93978,  3.350183, 1.31059,  3.350183, 3.93978,  3.750925,
                      3.93978,  3.350183, 1.31059,  3.350183, 3.93978,  0,        0,
                      0,        0,        0,        0,        0,        0]
    assert len(correctResults) == len(aT)
    for i in range(size):
        assert abs(correctResults[i] - aT[i][i]) < 1e-5
    
    var aRf = aResults[0].getMatrix(Side.Front, PropertySimple.R)
    correctResults = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    assert len(correctResults) == len(aRf)
    for i in range(size):
        assert abs(correctResults[i] - aRf[i][i]) < 1e-5
    
    aT = aResults[1].getMatrix(Side.Front, PropertySimple.T)
    size = len(aT)
    correctResults = [5.786856, 6.077092, 6.076345, 6.060622, 6.076345, 6.077092, 6.076345,
                      6.060622, 6.076345, 5.107699, 5.133175, 5.00896,  4.795816, 5.00896,
                      5.133175, 5.107699, 5.133175, 5.00896,  4.795816, 5.00896,  5.133175,
                      3.786973, 3.977869, 3.389612, 1.346872, 3.389612, 3.977869, 3.786973,
                      3.977869, 3.389612, 1.346872, 3.389612, 3.977869, 0.037705, 0.014065,
                      0.037705, 0.014065, 0.037705, 0.014065, 0.037705, 0.014065]
    assert len(correctResults) == len(aT)
    for i in range(size):
        assert abs(correctResults[i] - aT[i][i]) < 1e-5
    
    aRf = aResults[1].getMatrix(Side.Front, PropertySimple.R)
    correctResults = [0.13561,  0.137943, 0.137949, 0.138241, 0.137949, 0.137943, 0.137949,
                      0.138241, 0.137949, 0.141753, 0.140915, 0.143256, 0.147834, 0.143256,
                      0.140915, 0.141753, 0.140915, 0.143256, 0.147834, 0.143256, 0.140915,
                      0.145108, 0.139366, 0.149578, 0.192687, 0.149578, 0.139366, 0.145108,
                      0.139366, 0.149578, 0.192687, 0.149578, 0.139366, 0.216942, 0.240582,
                      0.216942, 0.240582, 0.216942, 0.240582, 0.216942, 0.240582]
    assert len(correctResults) == len(aRf)
    for i in range(size):
        assert abs(correctResults[i] - aRf[i][i]) < 1e-5
    
    aT = aResults[2].getMatrix(Side.Front, PropertySimple.T)
    size = len(aT)
    correctResults = [5.819182, 6.109986, 6.109241, 6.09359,  6.109241, 6.109986, 6.109241,
                      6.09359,  6.109241, 5.141467, 5.166734, 5.043095, 4.831082, 5.043095,
                      5.166734, 5.141467, 5.166734, 5.043095, 4.831082, 5.043095, 5.166734,
                      3.821344, 4.010806, 3.425052, 1.392962, 3.425052, 4.010806, 3.821344,
                      4.010806, 3.425052, 1.392962, 3.425052, 4.010806, 0.090127, 0.072878,
                      0.090127, 0.072878, 0.090127, 0.072878, 0.090127, 0.072878]
    assert len(correctResults) == len(aT)
    for i in range(size):
        assert abs(correctResults[i] - aT[i][i]) < 1e-5
    
    aRf = aResults[2].getMatrix(Side.Front, PropertySimple.R)
    correctResults = [0.103285, 0.105049, 0.105053, 0.105273, 0.105053, 0.105049, 0.105053,
                      0.105273, 0.105053, 0.107984, 0.107356, 0.109122, 0.112568, 0.109122,
                      0.107356, 0.107984, 0.107356, 0.109122, 0.112568, 0.109122, 0.107356,
                      0.110737, 0.10643,  0.114139, 0.146597, 0.114139, 0.10643,  0.110737,
                      0.10643,  0.114139, 0.146597, 0.114139, 0.10643,  0.16452,  0.181769,
                      0.16452,  0.181769, 0.16452,  0.181769, 0.16452,  0.181769]
    assert len(correctResults) == len(aRf)
    for i in range(size):
        assert abs(correctResults[i] - aRf[i][i]) < 1e-5
    
    aT = aResults[3].getMatrix(Side.Front, PropertySimple.T)
    size = len(aT)
    correctResults = [5.786856, 6.077092, 6.076345, 6.060622, 6.076345, 6.077092, 6.076345,
                      6.060622, 6.076345, 5.107699, 5.133175, 5.00896,  4.795816, 5.00896,
                      5.133175, 5.107699, 5.133175, 5.00896,  4.795816, 5.00896,  5.133175,
                      3.786973, 3.977869, 3.389612, 1.346872, 3.389612, 3.977869, 3.786973,
                      3.977869, 3.389612, 1.346872, 3.389612, 3.977869, 0.037705, 0.014065,
                      0.037705, 0.014065, 0.037705, 0.014065, 0.037705, 0.014065]
    assert len(correctResults) == len(aT)
    for i in range(size):
        assert abs(correctResults[i] - aT[i][i]) < 1e-5
    
    aRf = aResults[3].getMatrix(Side.Front, PropertySimple.R)
    correctResults = [0.13561,  0.137943, 0.137949, 0.138241, 0.137949, 0.137943, 0.137949,
                      0.138241, 0.137949, 0.141753, 0.140915, 0.143256, 0.147834, 0.143256,
                      0.140915, 0.141753, 0.140915, 0.143256, 0.147834, 0.143256, 0.140915,
                      0.145108, 0.139366, 0.149578, 0.192687, 0.149578, 0.139366, 0.145108,
                      0.139366, 0.149578, 0.192687, 0.149578, 0.139366, 0.216942, 0.240582,
                      0.216942, 0.240582, 0.216942, 0.240582, 0.216942, 0.240582]
    assert len(correctResults) == len(aRf)
    for i in range(size):
        assert abs(correctResults[i] - aRf[i][i]) < 1e-5

# Helper function to mimic SCOPED_TRACE (comment only)
def SCOPED_TRACE(msg: String):

# Call the test (if running as main, but we just define)