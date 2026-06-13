from WCESpectralAveraging import *
from WCESingleLayerOptics import CBSDFHemisphere, CMaterialSingleBandBSDF, CMaterialDualBandBSDF, CBeamDirection, BSDFBasis, BSDFDirection
from WCECommon import FenestrationCommon, Property, Side, WavelengthRange

struct TestBSDFMaterialDualBand:
    var m_Hemisphere: CBSDFHemisphere = CBSDFHemisphere.create(BSDFBasis.Small)
    var m_MaterialVis: CMaterialSingleBandBSDF
    var m_MaterialSol: CMaterialSingleBandBSDF
    var m_Material: CMaterialDualBandBSDF
    var m_TfVis: List[List[Float64]]
    var m_TbVis: List[List[Float64]]
    var m_RfVis: List[List[Float64]]
    var m_RbVis: List[List[Float64]]
    var m_TfSol: List[List[Float64]]
    var m_TbSol: List[List[Float64]]
    var m_RfSol: List[List[Float64]]
    var m_RbSol: List[List[Float64]]

    def loadTfVis(self) -> List[List[Float64]]:
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

    def loadRfVis(self) -> List[List[Float64]]:
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

    def loadTfSol(self) -> List[List[Float64]]:
        return self.loadTfVis()

    def loadRfSol(self) -> List[List[Float64]]:
        return self.loadRfVis()

    def SetUp(self):
        self.m_TfVis = self.loadTfVis()
        self.m_TbVis = self.m_TfVis
        self.m_RfVis = self.loadRfVis()
        self.m_RbVis = self.m_RfVis
        self.m_MaterialVis = CMaterialSingleBandBSDF(
            self.m_TfVis, self.m_TbVis, self.m_RfVis, self.m_RbVis,
            self.m_Hemisphere, FenestrationCommon.WavelengthRange.Visible
        )
        self.m_TfSol = self.loadTfSol()
        self.m_TbSol = self.m_TfSol
        self.m_RfSol = self.loadRfSol()
        self.m_RbSol = self.m_RfSol
        self.m_MaterialSol = CMaterialSingleBandBSDF(
            self.m_TfSol, self.m_TbSol, self.m_RfSol, self.m_RbSol,
            self.m_Hemisphere, FenestrationCommon.WavelengthRange.Solar
        )
        self.m_Material = CMaterialDualBandBSDF(self.m_MaterialVis, self.m_MaterialSol)

def TestProperties():
    print("Begin Test: Properties for a single band BSDF material.")
    var testObj = TestBSDFMaterialDualBand()
    testObj.SetUp()
    var incomingDirections = testObj.m_Hemisphere.getDirections(BSDFDirection.Incoming)
    var outgoingDirections = testObj.m_Hemisphere.getDirections(BSDFDirection.Outgoing)
    var outgoingLambdas = testObj.m_Hemisphere.getDirections(BSDFDirection.Outgoing).lambdaVector()
    assert(testObj.m_Material.getProperty(Property.T, Side.Front) == testObj.m_MaterialSol.getProperty(Property.T, Side.Front))
    var incomingTheta: Float64 = 37
    var incomingPhi: Float64 = 76
    var outgoingTheta: Float64 = 62
    var outgoingPhi: Float64 = 23
    var incomingDirection = CBeamDirection(incomingTheta, incomingPhi)
    var outgoingDirection = CBeamDirection(outgoingTheta, outgoingPhi)
    assert(
        testObj.m_Material.getProperty(Property.T, Side.Front, incomingDirection, outgoingDirection)
        == testObj.m_MaterialSol.getProperty(Property.T, Side.Front, incomingDirection, outgoingDirection)
    )
    var bandProperties = testObj.m_Material.getBandProperties(Property.T, Side.Front, incomingDirection, outgoingDirection)
    var expectedBandProperties: List[Float64] = List(0, 0.012749736954558742, 0.012749736954558742, 0.012749736954558742, 0.012749736954558742)
    assert(bandProperties == expectedBandProperties)

def main():
    TestProperties()