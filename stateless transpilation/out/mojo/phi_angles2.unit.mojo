# EXTERNAL DEPS (to wire in glue):
# - CBSDFPhiAngles: from WCESingleLayerOptics

from WCESingleLayerOptics import CBSDFPhiAngles


struct TestPhisAngles2:
    m_basis_ring: CBSDFPhiAngles

    fn __init__(inout self):
        self.m_basis_ring = CBSDFPhiAngles(12)

    fn get_ring(self) -> CBSDFPhiAngles:
        return self.m_basis_ring

    fn test_bsdf_ring_creation(self):
        let a_ring = self.get_ring()
        let results = a_ring.phiAngles()

        var correct_results = List[Float64]()
        correct_results.append(0)
        correct_results.append(30)
        correct_results.append(60)
        correct_results.append(90)
        correct_results.append(120)
        correct_results.append(150)
        correct_results.append(180)
        correct_results.append(210)
        correct_results.append(240)
        correct_results.append(270)
        correct_results.append(300)
        correct_results.append(330)

        assert len(results) == len(correct_results)

        for i in range(len(results)):
            let diff = abs(results[i] - correct_results[i])
            assert diff < 1e-6


fn main():
    var test = TestPhisAngles2()
    test.test_bsdf_ring_creation()
