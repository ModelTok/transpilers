# EXTERNAL DEPS (to wire in glue):
# - CIGUGapLayer (from IGUGapLayer.mojo)
# - CBaseLayer (from BaseLayer.mojo)
# - CBaseIGULayer (from BaseIGULayer.mojo)
# - ConstantsData (from ConstantsData.mojo)

from math import pi, pow

struct CIGUGapLayer {
    layer: Any
}

fn calculateConvectionOrConductionFlow(self: CIGUGapLayer):
    pass

fn isCalculated(self: CIGUGapLayer) -> bool:
    pass

fn get_m_ConductiveConvectiveCoeff(self: CIGUGapLayer) -> float:
    pass

fn set_m_ConductiveConvectiveCoeff(self: CIGUGapLayer, value: float):
    pass

fn get_m_PreviousLayer(self: CIGUGapLayer) -> Any:
    pass

fn get_m_NextLayer(self: CIGUGapLayer) -> Any:
    pass

fn get_m_Thickness(self: CIGUGapLayer) -> float:
    pass

struct CSupportPillar {
    layer: CIGUGapLayer
    m_Conductivity: float
}

fn CSupportPillar_init(self: CSupportPillar, t_Layer: CIGUGapLayer, t_Conductivity: float):
    self.layer = t_Layer
    self.m_Conductivity = t_Conductivity

fn calculateConvectionOrConductionFlow(self: CSupportPillar):
    calculateConvectionOrConductionFlow(self.layer)
    if not isCalculated(self.layer):
        self.m_ConductiveConvectiveCoeff += self.conductivityOfPillarArray()

fn conductivityOfPillarArray(self: CSupportPillar) -> float:
    pass

struct CCircularPillar {
    layer: CSupportPillar
    m_Spacing: float
    m_Radius: float
}

fn CCircularPillar_init(self: CCircularPillar, t_Gap: CIGUGapLayer, t_Conductivity: float, t_Spacing: float, t_Radius: float):
    CSupportPillar_init(self.layer, t_Gap, t_Conductivity)
    self.m_Spacing = t_Spacing
    self.m_Radius = t_Radius

fn clone(self: CCircularPillar) -> CCircularPillar:
    return CCircularPillar(self.layer, self.m_Conductivity, self.m_Spacing, self.m_Radius)

fn conductivityOfPillarArray(self: CCircularPillar) -> float:
    from ConstantsData import WCE_PI

    cond1 = getConductivity(get_m_PreviousLayer(self.layer.layer))
    cond2 = getConductivity(get_m_NextLayer(self.layer.layer))
    aveCond = (cond1 + cond2) / 2

    cond = 2 * aveCond * self.m_Radius / (pow(self.m_Spacing, 2))
    cond *= 1 / (1 + 2 * get_m_Thickness(self.layer.layer) * aveCond / (self.m_Conductivity * WCE_PI * self.m_Radius))

    return cond
