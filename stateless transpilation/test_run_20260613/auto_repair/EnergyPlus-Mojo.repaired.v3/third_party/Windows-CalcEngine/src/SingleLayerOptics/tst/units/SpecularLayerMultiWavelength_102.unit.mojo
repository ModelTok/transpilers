from memory import shared_ptr
from gtest import *  # Assuming gtest equivalents, else we use built-in asserts
from WCESpectralAveraging import *
from WCESingleLayerOptics import *
from WCECommon import *

# Using namespace equivalents: import all names from modules, or we can use qualified access.
# Since the original uses `using namespace SingleLayerOptics;` etc., we'll import all public names.
# For brevity, we assume the modules export everything.

struct TestSpecularLayerMultiWavelength_102:
    var m_Layer: shared_ptr[CBSDFLayer]  # Using Mojo's shared_ptr (hypothetical)

    def SetUp(inout self):
        var aMeasurements = CSpectralSampleData.create([
            (0.300, 0.0020, 0.0470, 0.0480),
            (0.305, 0.0030, 0.0470, 0.0480),
            (0.310, 0.0090, 0.0470, 0.0480),
            (0.315, 0.0350, 0.0470, 0.0480),
            (0.320, 0.1000, 0.0470, 0.0480)
        ])
        var thickness = 3.048e-3  # [m]
        var aType: MaterialType = MaterialType.Monolithic
        var minLambda = 0.3
        var maxLambda = 2.5
        var aMaterial = Material.nBandMaterial(aMeasurements, thickness, aType, minLambda, maxLambda)
        var aBSDF = CBSDFHemisphere.create(BSDFBasis.Quarter)
        self.m_Layer = CBSDFLayerMaker.getSpecularLayer(aMaterial, aBSDF)

    def getLayer(self) -> shared_ptr[CBSDFLayer]:
        return self.m_Layer

def TestSpecular1():
    print("Begin Test: Specular layer - BSDF.")
    var fixture = TestSpecularLayerMultiWavelength_102()
    fixture.SetUp()
    var aLayer = fixture.getLayer()
    var aResults = aLayer.getWavelengthResults()  # returns shared_ptr to vector of shared_ptr
    var correctSize: size_t = 5
    assert correctSize == aResults.size()  # since aResults is a shared_ptr, we need to dereference: (*aResults).size()
    # Actually, in Mojo we assume aResults is a shared_ptr to a vector, so we use aResults[].size() or aResults.value().size().
    # For simplicity, we treat aResults as the vector directly.
    # We'll adjust: var aResultsVec = aResults; but original uses (*aResults)[0]
    var resVec = aResults  # assume it's a vector

    var aT = resVec[0].getMatrix(Side.Front, PropertySimple.T)
    var correctResults: List[Float64] = List[Float64](
        0.026014, 0.024743, 0.024743, 0.024743, 0.024743, 0.024743, 0.024743, 0.024743, 0.024743,
        0.015794, 0.015794, 0.015794, 0.015794, 0.015794, 0.015794, 0.015794, 0.015794, 0.015794,
        0.015794, 0.015794, 0.015794, 0.008638, 0.008638, 0.008638, 0.008638, 0.008638, 0.008638,
        0.008638, 0.008638, 0.008638, 0.008638, 0.008638, 0.008638, 0.002528, 0.002528, 0.002528,
        0.002528, 0.002528, 0.002528, 0.002528, 0.002528
    )
    assert correctResults.size == aT.size()
    for i in range(aT.size()):
        assert Math.abs(correctResults[i] - aT[i, i]) < 1e-5

    var aRf = resVec[0].getMatrix(Side.Front, PropertySimple.R)
    correctResults = List[Float64](
        0.61134, 0.661508, 0.661508, 0.661508, 0.661508, 0.661508, 0.661508, 0.661508, 0.661508,
        0.659003, 0.659003, 0.659003, 0.659003, 0.659003, 0.659003, 0.659003, 0.659003, 0.659003,
        0.659003, 0.659003, 0.659003, 0.974838, 0.974838, 0.974838, 0.974838, 0.974838, 0.974838,
        0.974838, 0.974838, 0.974838, 0.974838, 0.974838, 0.974838, 3.654452, 3.654452, 3.654452,
        3.654452, 3.654452, 3.654452, 3.654452, 3.654452
    )
    assert correctResults.size == aRf.size()
    for i in range(aRf.size()):
        assert Math.abs(correctResults[i] - aRf[i, i]) < 1e-5

    aT = resVec[1].getMatrix(Side.Front, PropertySimple.T)
    correctResults = List[Float64](
        0.039022, 0.037422, 0.037422, 0.037422, 0.037422, 0.037422, 0.037422,
        0.037422, 0.037422, 0.024475, 0.024475, 0.024475, 0.024475, 0.024475,
        0.024475, 0.024475, 0.024475, 0.024475, 0.024475, 0.024475, 0.024475,
        0.01389, 0.01389, 0.01389, 0.01389, 0.01389, 0.01389, 0.01389,
        0.01389, 0.01389, 0.01389, 0.01389, 0.01389, 0.004252, 0.004252,
        0.004252, 0.004252, 0.004252, 0.004252, 0.004252, 0.004252
    )
    assert correctResults.size == aT.size()
    for i in range(aT.size()):
        assert Math.abs(correctResults[i] - aT[i, i]) < 1e-5

    aRf = resVec[1].getMatrix(Side.Front, PropertySimple.R)
    correctResults = List[Float64](
        0.61134, 0.661507, 0.661507, 0.661507, 0.661507, 0.661507, 0.661507,
        0.661507, 0.661507, 0.659001, 0.659001, 0.659001, 0.659001, 0.659001,
        0.659001, 0.659001, 0.659001, 0.659001, 0.659001, 0.659001, 0.659001,
        0.974835, 0.974835, 0.974835, 0.974835, 0.974835, 0.974835, 0.974835,
        0.974835, 0.974835, 0.974835, 0.974835, 0.974835, 3.654449, 3.654449,
        3.654449, 3.654449, 3.654449, 3.654449, 3.654449, 3.654449
    )
    assert correctResults.size == aRf.size()
    for i in range(aRf.size()):
        assert Math.abs(correctResults[i] - aRf[i, i]) < 1e-5

    aT = resVec[2].getMatrix(Side.Front, PropertySimple.T)
    correctResults = List[Float64](
        0.117065, 0.114808, 0.114808, 0.114808, 0.114808, 0.114808, 0.114808,
        0.114808, 0.114808, 0.080195, 0.080195, 0.080195, 0.080195, 0.080195,
        0.080195, 0.080195, 0.080195, 0.080195, 0.080195, 0.080195, 0.080195,
        0.050298, 0.050298, 0.050298, 0.050298, 0.050298, 0.050298, 0.050298,
        0.050298, 0.050298, 0.050298, 0.050298, 0.050298, 0.017391, 0.017391,
        0.017391, 0.017391, 0.017391, 0.017391, 0.017391, 0.017391
    )
    assert correctResults.size == aT.size()
    for i in range(aT.size()):
        assert Math.abs(correctResults[i] - aT[i, i]) < 1e-5

    aRf = resVec[2].getMatrix(Side.Front, PropertySimple.R)
    correctResults = List[Float64](
        0.61134, 0.661498, 0.661498, 0.661498, 0.661498, 0.661498, 0.661498,
        0.661498, 0.661498, 0.658976, 0.658976, 0.658976, 0.658976, 0.658976,
        0.658976, 0.658976, 0.658976, 0.658976, 0.658976, 0.658976, 0.658976,
        0.974793, 0.974793, 0.974793, 0.974793, 0.974793, 0.974793, 0.974793,
        0.974793, 0.974793, 0.974793, 0.974793, 0.974793, 3.654404, 3.654404,
        3.654404, 3.654404, 3.654404, 3.654404, 3.654404, 3.654404
    )
    assert correctResults.size == aRf.size()
    for i in range(aRf.size()):
        assert Math.abs(correctResults[i] - aRf[i, i]) < 1e-5

    aT = resVec[3].getMatrix(Side.Front, PropertySimple.T)
    correctResults = List[Float64](
        0.455253, 0.458994, 0.458994, 0.458994, 0.458994, 0.458994, 0.458994,
        0.458994, 0.458994, 0.347745, 0.347745, 0.347745, 0.347745, 0.347745,
        0.347745, 0.347745, 0.347745, 0.347745, 0.347745, 0.347745, 0.347745,
        0.246756, 0.246756, 0.246756, 0.246756, 0.246756, 0.246756, 0.246756,
        0.246756, 0.246756, 0.246756, 0.246756, 0.246756, 0.09914, 0.09914,
        0.09914, 0.09914, 0.09914, 0.09914, 0.09914, 0.09914
    )
    assert correctResults.size == aT.size()
    for i in range(aT.size()):
        assert Math.abs(correctResults[i] - aT[i, i]) < 1e-5

    aRf = resVec[3].getMatrix(Side.Front, PropertySimple.R)
    correctResults = List[Float64](
        0.61134, 0.661398, 0.661398, 0.661398, 0.661398, 0.661398, 0.661398,
        0.661398, 0.661398, 0.658665, 0.658665, 0.658665, 0.658665, 0.658665,
        0.658665, 0.658665, 0.658665, 0.658665, 0.658665, 0.658665, 0.658665,
        0.974245, 0.974245, 0.974245, 0.974245, 0.974245, 0.974245, 0.974245,
        0.974245, 0.974245, 0.974245, 0.974245, 0.974245, 3.653868, 3.653868,
        3.653868, 3.653868, 3.653868, 3.653868, 3.653868, 3.653868
    )
    assert correctResults.size == aRf.size()
    for i in range(aRf.size()):
        assert Math.abs(correctResults[i] - aRf[i, i]) < 1e-5

    aT = resVec[4].getMatrix(Side.Front, PropertySimple.T)
    correctResults = List[Float64](
        1.300724, 1.339503, 1.339503, 1.339503, 1.339503, 1.339503, 1.339503,
        1.339503, 1.339503, 1.080006, 1.080006, 1.080006, 1.080006, 1.080006,
        1.080006, 1.080006, 1.080006, 1.080006, 1.080006, 1.080006, 1.080006,
        0.842257, 0.842257, 0.842257, 0.842257, 0.842257, 0.842257, 0.842257,
        0.842257, 0.842257, 0.842257, 0.842257, 0.842257, 0.379491, 0.379491,
        0.379491, 0.379491, 0.379491, 0.379491, 0.379491, 0.379491
    )
    assert correctResults.size == aT.size()
    for i in range(aT.size()):
        assert Math.abs(correctResults[i] - aT[i, i]) < 1e-5

    aRf = resVec[4].getMatrix(Side.Front, PropertySimple.R)
    correctResults = List[Float64](
        0.61134, 0.660889, 0.660889, 0.660889, 0.660889, 0.660889, 0.660889,
        0.660889, 0.660889, 0.657004, 0.657004, 0.657004, 0.657004, 0.657004,
        0.657004, 0.657004, 0.657004, 0.657004, 0.657004, 0.657004, 0.657004,
        0.971223, 0.971223, 0.971223, 0.971223, 0.971223, 0.971223, 0.971223,
        0.971223, 0.971223, 0.971223, 0.971223, 0.971223, 3.65192, 3.65192,
        3.65192, 3.65192, 3.65192, 3.65192, 3.65192, 3.65192
    )
    assert correctResults.size == aRf.size()
    for i in range(aRf.size()):
        assert Math.abs(correctResults[i] - aRf[i, i]) < 1e-5

    print("Test passed.")

# In Mojo, we can call TestSpecular1() as the main entry.
def main():
    TestSpecular1()