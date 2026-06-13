from WCECommon import CSeries, Property, Side, ConstantsData
from EquivalentLayerSingleComponent import CEquivalentLayerSingleComponent
from memory import shared_ptr, make_shared
from vector import DynamicVector
from map import Map
from string import String
from io import StringStream
from runtime_error import RuntimeError

@value
class CSurfaceSeries:
    var m_Properties: Map[Property, CSeries]

    def __init__(inout self, t_T: CSeries, t_R: CSeries):
        self.m_Properties = Map[Property, CSeries]()
        self.m_Properties[Property.T] = t_T
        self.m_Properties[Property.R] = t_R
        var size: Int = t_T.size()
        var aAbs: CSeries = CSeries()
        for i in range(size):
            var wl: Float64 = t_T[i].x()
            var t: Float64 = t_T[i].value()
            var r: Float64 = t_R[i].value()
            var value: Float64 = 1 - t - r
            if value > (1 + ConstantsData.floatErrorTolerance) or value < -ConstantsData.floatErrorTolerance:
                var err_msg: StringStream = StringStream()
                err_msg.print("Absorptance value for provided series is out of range.\n")
                err_msg.print("Wavelength: ")
                err_msg.print(wl)
                err_msg.print("\nTransmittance: ")
                err_msg.print(t)
                err_msg.print("\nReflectance: ")
                err_msg.print(r)
                raise RuntimeError(err_msg.str())
            aAbs.addProperty(wl, value)
        self.m_Properties[Property.Abs] = aAbs

    def getProperties(self, t_Property: Property) -> CSeries:
        return self.m_Properties[t_Property]

@value
class CLayerSeries:
    var m_Surfaces: Map[Side, shared_ptr[CSurfaceSeries]]

    def __init__(inout self, t_Tf: CSeries, t_Rf: CSeries, t_Tb: CSeries, t_Rb: CSeries):
        self.m_Surfaces = Map[Side, shared_ptr[CSurfaceSeries]]()
        self.m_Surfaces[Side.Front] = make_shared[CSurfaceSeries](t_Tf, t_Rf)
        self.m_Surfaces[Side.Back] = make_shared[CSurfaceSeries](t_Tb, t_Rb)

    def getProperties(self, t_Side: Side, t_Property: Property) -> CSeries:
        return self.m_Surfaces[t_Side].getProperties(t_Property)

@value
class CEquivalentLayerSingleComponentMW:
    var m_Layer: shared_ptr[CLayerSeries]
    var m_EqLayerBySeries: DynamicVector[shared_ptr[CEquivalentLayerSingleComponent]]

    def __init__(inout self, t_Tf: CSeries, t_Tb: CSeries, t_Rf: CSeries, t_Rb: CSeries):
        self.m_Layer = make_shared[CLayerSeries](t_Tf, t_Rf, t_Tb, t_Rb)
        self.m_EqLayerBySeries = DynamicVector[shared_ptr[CEquivalentLayerSingleComponent]]()
        var size: Int = t_Tf.size()
        for i in range(size):
            var aLayer: shared_ptr[CEquivalentLayerSingleComponent] = make_shared[CEquivalentLayerSingleComponent](
                t_Tf[i].value(), t_Rf[i].value(), t_Tb[i].value(), t_Rb[i].value())
            self.m_EqLayerBySeries.push_back(aLayer)

    def addLayer(inout self, t_Tf: CSeries, t_Tb: CSeries, t_Rf: CSeries, t_Rb: CSeries):
        var size: Int = t_Tf.size()
        for i in range(size):
            var aLayer: shared_ptr[CEquivalentLayerSingleComponent] = self.m_EqLayerBySeries[i]
            aLayer.addLayer(t_Tf[i].value(), t_Rf[i].value(), t_Tb[i].value(), t_Rb[i].value())
        var tTotf: CSeries = CSeries()
        var tTotb: CSeries = CSeries()
        var tRfTot: CSeries = CSeries()
        var tRbTot: CSeries = CSeries()
        for i in range(size):
            var wl: Float64 = t_Tf[i].x()
            var Tf: Float64 = self.m_EqLayerBySeries[i].getProperty(Property.T, Side.Front)
            tTotf.addProperty(wl, Tf)
            var Rf: Float64 = self.m_EqLayerBySeries[i].getProperty(Property.R, Side.Front)
            tRfTot.addProperty(wl, Rf)
            var Tb: Float64 = self.m_EqLayerBySeries[i].getProperty(Property.T, Side.Back)
            tTotb.addProperty(wl, Tb)
            var Rb: Float64 = self.m_EqLayerBySeries[i].getProperty(Property.R, Side.Back)
            tRbTot.addProperty(wl, Rb)
        self.m_Layer = make_shared[CLayerSeries](tTotf, tRfTot, tTotb, tRbTot)

    def getProperties(self, t_Property: Property, t_Side: Side) -> CSeries:
        return self.m_Layer.getProperties(t_Side, t_Property)