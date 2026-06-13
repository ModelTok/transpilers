# EXTERNAL DEPS (to wire in glue):
# - CBSDFPhiAngles: from BSDFPhiAngles module, constructor(Int), phiAngles() -> List[Float64]


struct CPhiLimits:
    var m_PhiLimits: List[Float64]
    
    fn __init__(inout self, t_NumOfPhis: Int) raises:
        if t_NumOfPhis == 0:
            raise Error(
                "Number of phi angles for BSDF definition must be greater than zero."
            )
        
        var aPhiAngles = CBSDFPhiAngles(t_NumOfPhis)
        self.m_PhiLimits = List[Float64]()
        self._createLimits(aPhiAngles.phiAngles())
    
    fn getPhiLimits(self) -> List[Float64]:
        return self.m_PhiLimits
    
    fn _createLimits(inout self, t_PhiAngles: List[Float64]):
        var deltaPhi = 360.0 / Float64(len(t_PhiAngles))
        var currentLimit = -deltaPhi / 2.0
        if len(t_PhiAngles) == 1:
            currentLimit = 0.0
        
        for i in range(len(t_PhiAngles) + 1):
            self.m_PhiLimits.append(currentLimit)
            currentLimit = currentLimit + deltaPhi
