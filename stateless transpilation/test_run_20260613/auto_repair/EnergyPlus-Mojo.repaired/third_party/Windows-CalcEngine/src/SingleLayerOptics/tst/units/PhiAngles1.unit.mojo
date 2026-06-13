from memory import Arc
from WCESingleLayerOptics import CBSDFPhiAngles

struct TestPhisAngles1:
    var m_BasisRing: Arc[CBSDFPhiAngles]

    def SetUp(inout self):
        self.m_BasisRing = Arc(CBSDFPhiAngles(8))

    def GetRing(self) -> Arc[CBSDFPhiAngles]:
        return self.m_BasisRing

def TestBSDFRingCreation():
    print("Begin Test: Phi angles creation.")
    var aRing = TestPhisAngles1()
    aRing.SetUp()
    var results = aRing.GetRing().phiAngles()
    var correctResults = List[Float64](0, 45, 90, 135, 180, 225, 270, 315)
    assert results.size() == correctResults.size(), "Size mismatch"
    for i in range(results.size()):
        assert abs(results[i] - correctResults[i]) < 1e-6, "Value mismatch at index " + str(i)