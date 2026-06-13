from ......WCESingleLayerOptics import CBSDFHemisphere, CBSDFDirections, BSDFBasis, BSDFDirection

@value
struct TestBSDFDirectionsClosestIndex:
    var m_BSDFHemisphere: CBSDFHemisphere

    def __init__(inout self):
        self.m_BSDFHemisphere = CBSDFHemisphere.create(BSDFBasis.Quarter)

    def GetDirections(self, t_Side: BSDFDirection) -> CBSDFDirections:
        return self.m_BSDFHemisphere.getDirections(t_Side)

@test
def TestClosestIndex1():
    var fixture = TestBSDFDirectionsClosestIndex()
    let aDirections = fixture.GetDirections(BSDFDirection.Incoming)
    var theta = 15.0
    var phi = 270.0
    let beamIndex = aDirections.getNearestBeamIndex(theta, phi)
    assert beamIndex == 7

@test
def TestClosestIndex2():
    var fixture = TestBSDFDirectionsClosestIndex()
    let aDirections = fixture.GetDirections(BSDFDirection.Incoming)
    var theta = 70.0
    var phi = 175.0
    var beamIndex = aDirections.getNearestBeamIndex(theta, phi)
    assert beamIndex == 37

@test
def TestClosestIndex3():
    var fixture = TestBSDFDirectionsClosestIndex()
    let aDirections = fixture.GetDirections(BSDFDirection.Incoming)
    var theta = 55.0
    var phi = 60.0
    var beamIndex = aDirections.getNearestBeamIndex(theta, phi)
    assert beamIndex == 23

@test
def TestClosestIndex4():
    var fixture = TestBSDFDirectionsClosestIndex()
    let aDirections = fixture.GetDirections(BSDFDirection.Incoming)
    var theta = 0.0
    var phi = 0.0
    var beamIndex = aDirections.getNearestBeamIndex(theta, phi)
    assert beamIndex == 0

@test
def TestClosestIndex5():
    var fixture = TestBSDFDirectionsClosestIndex()
    let aDirections = fixture.GetDirections(BSDFDirection.Incoming)
    var theta = 71.2163
    var phi = 349.744251
    var beamIndex = aDirections.getNearestBeamIndex(theta, phi)
    assert beamIndex == 33