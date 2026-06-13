from memory import Pointer
from List import List
from ......WCESingleLayerOptics import CBSDFPhiAngles

struct TestPhisAngles2:
    var m_BasisRing: Pointer[CBSDFPhiAngles]

    def __init__(inout self):
        self.m_BasisRing = Pointer[CBSDFPhiAngles]()

    def SetUp(inout self):
        self.m_BasisRing = Pointer[CBSDFPhiAngles](CBSDFPhiAngles(12))

    def GetRing(self) -> Pointer[CBSDFPhiAngles]:
        return self.m_BasisRing

def TestBSDFRingCreation():
    SCOPED_TRACE: "Begin Test: Phi angles creation."
    print("Begin Test: Phi angles creation.")
    var fixture = TestPhisAngles2()
    fixture.SetUp()
    var aRing: Pointer[CBSDFPhiAngles] = fixture.GetRing()
    var results: List[Float64] = *((*aRing).phiAngles())
    var correctResults: List[Float64] = List[Float64](0, 30, 60, 90, 120, 150, 180, 210, 240, 270, 300, 330)
    assert results.size == correctResults.size
    for i in range(results.size):
        assert (results[i] - correctResults[i]).abs() < 1e-6

def main():
    TestBSDFRingCreation()