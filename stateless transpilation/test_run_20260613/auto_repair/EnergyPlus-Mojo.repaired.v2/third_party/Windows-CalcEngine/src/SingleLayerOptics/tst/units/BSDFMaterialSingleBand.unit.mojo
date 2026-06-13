# Translation of "BSDFMaterialSingleBand.unit.cpp" to Mojo
from memory import make_shared
from WCESpectralAveraging import *
from WCESingleLayerOptics import *
from WCECommon import *

@value
class TestBSDFMaterialSingleBand:
    var m_Hemisphere: CBSDFHemisphere
    var m_Material: CMaterialSingleBandBSDF  # using value instead of shared_ptr
    var m_Tf: List[List[Float64]]
    var m_Tb: List[List[Float64]]
    var m_Rf: List[List[Float64]]
    var m_Rb: List[List[Float64]]

    def loadTf(self) -> List[List[Float64]]:
        var data: List[List[Float64]] = List(
            List(2.033760, 0.022174, 0.022174, 0.022174, 0.022174, 0.022174, 0.022174),
            List(0.022223, 0.022223, 0.022223, 0.022223, 0.022223, 0.022223, 0.022223),
            List(0.022223, 0.022223, 0.022223, 0.022223, 0.022223, 0.022223, 0.022223),
            List(0.022461, 0.022461, 0.022461, 0.022461, 0.022461, 0.022461, 0.022461),
            List(0.022461, 0.022461, 0.022461, 0.022461, 0.022461, 0.022461, 0.022461),
            List(0.023551, 0.023551, 0.023551, 0.023551, 0.023551, 0.023551, 0.023551),
            List(0.023551, 0.023551, 0.023551, 0.023551, 0.023551, 0.023551, 0.023551)
        )
        return data

    def loadRf(self) -> List[List[Float64]]:
        var data: List[List[Float64]] = List(
            List(0.148154, 0.148805, 0.148805, 0.148805, 0.148805, 0.148805, 0.148805),
            List(0.150762, 0.150762, 0.150762, 0.150762, 0.150762, 0.150762, 0.150762),
            List(0.150762, 0.150762, 0.150762, 0.150762, 0.150762, 0.150762, 0.150762),
            List(0.154041, 0.154041, 0.154041, 0.154041, 0.154041, 0.154041, 0.154041),
            List(0.154041, 0.154041, 0.154041, 0.154041, 0.154041, 0.154041, 0.154041),
            List(0.158675, 0.158675, 0.158675, 0.158675, 0.158675, 0.158675, 0.158675),
            List(0.158675, 0.158675, 0.158675, 0.158675, 0.158675, 0.158675, 0.158675)
        )
        return data

    def __init__(inout self):
        self.m_Hemisphere = CBSDFHemisphere.create(BSDFBasis.Small)
        self.m_Tf = self.loadTf()
        self.m_Tb = self.m_Tf
        self.m_Rf = self.loadRf()
        self.m_Rb = self.m_Rf
        self.m_Material = CMaterialSingleBandBSDF(
            self.m_Tf, self.m_Tb, self.m_Rf, self.m_Rb,
            self.m_Hemisphere, FenestrationCommon.WavelengthRange.Solar
        )

def test_properties():
    print("Begin Test: Properties for a single band BSDF material.")
    var test = TestBSDFMaterialSingleBand()
    var incomingDirections = test.m_Hemisphere.getDirections(BSDFDirection.Incoming)
    var outgoingDirections = test.m_Hemisphere.getDirections(BSDFDirection.Outgoing)
    var outgoingLambdas = test.m_Hemisphere.getDirections(BSDFDirection.Outgoing).lambdaVector()
    assert(test.m_Material.getBSDFMatrix(Property.T, Side.Front) == test.m_Tf), "Matrix mismatch"
    assert(test.m_Material.getProperty(Property.T, Side.Front) == test.m_Tf[0][0] * outgoingLambdas[0]), "Property mismatch"
    var incomingTheta: Float64 = 37.0
    var incomingPhi: Float64 = 76.0
    var outgoingTheta: Float64 = 62.0
    var outgoingPhi: Float64 = 23.0
    var incomingDirection = CBeamDirection(incomingTheta, incomingPhi)
    var outgoingDirection = CBeamDirection(outgoingTheta, outgoingPhi)
    var incomingIdx = incomingDirections.getNearestBeamIndex(incomingDirection.theta(), incomingDirection.phi())
    var outgoingIdx = outgoingDirections.getNearestBeamIndex(outgoingDirection.theta(), outgoingDirection.phi())
    assert(
        test.m_Material.getProperty(Property.T, Side.Front, incomingDirection, outgoingDirection)
        == test.m_Tf[outgoingIdx][incomingIdx] * outgoingLambdas[outgoingIdx]
    ), "Directional property mismatch"
    var tfHem: Float64 = 0.0
    var rfHem: Float64 = 0.0
    for oIdx in range(outgoingDirections.size()):
        tfHem += test.m_Tf[oIdx][incomingIdx] * outgoingLambdas[oIdx]
        rfHem += test.m_Rf[oIdx][incomingIdx] * outgoingLambdas[oIdx]
    assert(
        test.m_Material.getProperty(Property.Abs, Side.Front, incomingDirection, outgoingDirection)
        == 1.0 - tfHem - rfHem
    ), "Absorptance mismatch"
    var propValue = test.m_Material.getProperty(Property.T, Side.Front, incomingDirection, outgoingDirection)
    var expectedBandProperties: List[Float64] = List(propValue, propValue)
    assert(
        test.m_Material.getBandProperties(Property.T, Side.Front, incomingDirection, outgoingDirection)
        == expectedBandProperties
    ), "Band properties mismatch"
<<<FILE>>>