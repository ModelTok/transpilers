from collections import List


struct CBSDFPhiAngles:
    var m_PhiAngles: List[Float64]
    
    fn __init__(inout self, t_NumOfPhis: Int) -> None:
        self.m_PhiAngles = List[Float64]()
        self._createPhis(t_NumOfPhis)
    
    fn phiAngles(self) -> List[Float64]:
        return self.m_PhiAngles
    
    fn _createPhis(inout self, t_NumOfPhis: Int) -> None:
        let phi_delta = 360.0 / Float64(t_NumOfPhis)
        for i in range(t_NumOfPhis):
            self.m_PhiAngles.append(Float64(i) * phi_delta)
