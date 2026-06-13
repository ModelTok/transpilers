from memory import Arc

struct CBSDFPhiAngles:
    var m_PhiAngles: Arc[List[Float64]]

    def __init__(inout self, t_NumOfPhis: Int):
        self.m_PhiAngles = Arc(List[Float64]())
        self.createPhis(t_NumOfPhis)

    def phiAngles(self) -> Arc[List[Float64]]:
        return self.m_PhiAngles

    def createPhis(inout self, t_NumOfPhis: Int):
        let phiDelta: Float64 = 360.0 / t_NumOfPhis
        for i in range(t_NumOfPhis):
            self.m_PhiAngles[].append(i * phiDelta)