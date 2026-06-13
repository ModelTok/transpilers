from Pointer import Pointer
from LayerInterfaces import CLayerGeometry, CLayerHeatFlow, CState
from memory import shared_ptr, make_shared
from FenestrationCommon import Side

class CBaseLayer(CLayerGeometry, CLayerHeatFlow):
    var m_PreviousLayer: Pointer[shared_ptr[CBaseLayer]]
    var m_NextLayer: Pointer[shared_ptr[CBaseLayer]]

    def __init__(inout self):
        CState.__init__(self)
        CLayerGeometry.__init__(self)
        CLayerHeatFlow.__init__(self)
        self.m_PreviousLayer = Pointer[shared_ptr[CBaseLayer]].address_of(make_shared[CBaseLayer]().__ptr__())
        self.m_NextLayer = Pointer[shared_ptr[CBaseLayer]].address_of(make_shared[CBaseLayer]().__ptr__())

    def getPreviousLayer(self) -> shared_ptr[CBaseLayer]:
        return self.m_PreviousLayer[]

    def getNextLayer(self) -> shared_ptr[CBaseLayer]:
        return self.m_NextLayer[]

    def connectToBackSide(inout self, t_Layer: shared_ptr[CBaseLayer]):
        self.m_NextLayer[] = t_Layer
        t_Layer.m_PreviousLayer[] = self.shared_from_this()

    def tearDownConnections(inout self):
        self.m_PreviousLayer[] = shared_ptr[CBaseLayer]()
        self.m_NextLayer[] = shared_ptr[CBaseLayer]()

    def getThickness(self) -> Float64:
        return 0.0

    def isPermeable(self) -> Bool:
        return False

    def calculateRadiationFlow(inout self):

    def calculateConvectionOrConductionFlow(inout self):
        ...

    def clone(self) -> shared_ptr[CBaseLayer]:
        ...