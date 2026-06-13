from memory import owned
from FenestrationCommon import Side, Scattering, PropertySimple, Property
from SingleLayerOptics import CScatteringLayer, CScatteringSurface
from EquivalentLayerSingleComponent import CEquivalentLayerSingleComponent

struct SimpleResults:
    var T: Float64
    var R: Float64

    def __init__(inout self):
        self.T = 0.0
        self.R = 0.0

    def __init__(inout self, T: Float64, R: Float64):
        self.T = T
        self.R = R

class CEquivalentScatteringLayer:
    var m_Layer: CScatteringLayer
    var m_DiffuseLayer: owned[CEquivalentLayerSingleComponent]
    var m_BeamLayer: owned[CEquivalentLayerSingleComponent]

    def __init__(inout self,
                Tf_dir_dir: Float64,
                Rf_dir_dir: Float64,
                Tb_dir_dir: Float64,
                Rb_dir_dir: Float64,
                Tf_dir_dif: Float64,
                Rf_dir_dif: Float64,
                Tb_dir_dif: Float64,
                Rb_dir_dif: Float64,
                Tf_dif_dif: Float64,
                Rf_dif_dif: Float64,
                Tb_dif_dif: Float64,
                Rb_dif_dif: Float64):
        self.m_Layer = CScatteringLayer(
            CScatteringSurface(Tf_dir_dir, Rf_dir_dir, Tf_dir_dif, Rf_dir_dif, Tf_dif_dif, Rf_dif_dif),
            CScatteringSurface(Tb_dir_dir, Rb_dir_dir, Tb_dir_dif, Rb_dir_dif, Tb_dif_dif, Rb_dif_dif))
        self.m_DiffuseLayer = owned[CEquivalentLayerSingleComponent](
            Tf_dif_dif, Rf_dif_dif, Tb_dif_dif, Rb_dif_dif)
        self.m_BeamLayer = owned[CEquivalentLayerSingleComponent](
            Tf_dir_dir, Rf_dir_dir, Tb_dir_dir, Rb_dir_dir)

    def __init__(inout self, t_Layer: CScatteringLayer, t_Theta: Float64 = 0.0, t_Phi: Float64 = 0.0):
        self.m_Layer = CScatteringLayer(t_Layer)
        var Tf: Float64 = t_Layer.getPropertySimple(
            t_Layer.getMinLambda(), t_Layer.getMaxLambda(),
            PropertySimple.T, Side.Front, Scattering.DirectDirect, t_Theta, t_Phi)
        var Rf: Float64 = t_Layer.getPropertySimple(
            t_Layer.getMinLambda(), t_Layer.getMaxLambda(),
            PropertySimple.R, Side.Front, Scattering.DirectDirect, t_Theta, t_Phi)
        var Tb: Float64 = t_Layer.getPropertySimple(
            t_Layer.getMinLambda(), t_Layer.getMaxLambda(),
            PropertySimple.T, Side.Back, Scattering.DirectDirect, t_Theta, t_Phi)
        var Rb: Float64 = t_Layer.getPropertySimple(
            t_Layer.getMinLambda(), t_Layer.getMaxLambda(),
            PropertySimple.R, Side.Back, Scattering.DirectDirect, t_Theta, t_Phi)
        self.m_BeamLayer = owned[CEquivalentLayerSingleComponent](Tf, Rf, Tb, Rb)
        Tf = t_Layer.getPropertySimple(
            t_Layer.getMinLambda(), t_Layer.getMaxLambda(),
            PropertySimple.T, Side.Front, Scattering.DiffuseDiffuse, t_Theta, t_Phi)
        Rf = t_Layer.getPropertySimple(
            t_Layer.getMinLambda(), t_Layer.getMaxLambda(),
            PropertySimple.R, Side.Front, Scattering.DiffuseDiffuse, t_Theta, t_Phi)
        Tb = t_Layer.getPropertySimple(
            t_Layer.getMinLambda(), t_Layer.getMaxLambda(),
            PropertySimple.T, Side.Back, Scattering.DiffuseDiffuse, t_Theta, t_Phi)
        Rb = t_Layer.getPropertySimple(
            t_Layer.getMinLambda(), t_Layer.getMaxLambda(),
            PropertySimple.R, Side.Back, Scattering.DiffuseDiffuse, t_Theta, t_Phi)
        self.m_DiffuseLayer = owned[CEquivalentLayerSingleComponent](Tf, Rf, Tb, Rb)

    def addLayer(inout self,
                Tf_dir_dir: Float64,
                Rf_dir_dir: Float64,
                Tb_dir_dir: Float64,
                Rb_dir_dir: Float64,
                Tf_dir_dif: Float64,
                Rf_dir_dif: Float64,
                Tb_dir_dif: Float64,
                Rb_dir_dif: Float64,
                Tf_dif_dif: Float64,
                Rf_dif_dif: Float64,
                Tb_dif_dif: Float64,
                Rb_dif_dif: Float64,
                t_Side: Side = Side.Back):
        var aFrontSurface = CScatteringSurface(
            Tf_dir_dir, Rf_dir_dir, Tf_dir_dif, Rf_dir_dif, Tf_dif_dif, Rf_dif_dif)
        var aBackSurface = CScatteringSurface(
            Tb_dir_dir, Rb_dir_dir, Tb_dir_dif, Rb_dir_dif, Tb_dif_dif, Rb_dif_dif)
        var aLayer = CScatteringLayer(aFrontSurface, aBackSurface)
        self.addLayer(aLayer, t_Side)

    def addLayer(inout self,
                t_Layer: CScatteringLayer,
                t_Side: Side = Side.Back,
                t_Theta: Float64 = 0.0,
                t_Phi: Float64 = 0.0):
        self.addLayerComponents(t_Layer, t_Side, t_Theta, t_Phi)
        if t_Side == Side.Front:
            self.calcEquivalentProperties(t_Layer, self.m_Layer)
        elif t_Side == Side.Back:
            self.calcEquivalentProperties(self.m_Layer, t_Layer)
        else:
            assert(False, "Impossible side selection.")

    def getPropertySimple(inout self,
                         t_Property: PropertySimple,
                         t_Side: Side,
                         t_Scattering: Scattering,
                         t_Theta: Float64 = 0.0,
                         t_Phi: Float64 = 0.0) -> Float64:
        return self.m_Layer.getPropertySimple(
            self.m_Layer.getMinLambda(), self.m_Layer.getMaxLambda(),
            t_Property, t_Side, t_Scattering, t_Theta, t_Phi)

    def getLayer(self) -> CScatteringLayer:
        return self.m_Layer

    def calcEquivalentProperties(inout self, t_First: CScatteringLayer, t_Second: CScatteringLayer):
        var f1 = t_First.getSurface(Side.Front)
        var b1 = t_First.getSurface(Side.Back)
        var f2 = t_Second.getSurface(Side.Front)
        var b2 = t_Second.getSurface(Side.Back)
        var frontSide: SimpleResults = self.calcDirectDiffuseTransAndRefl(f1, b1, f2)
        var backSide: SimpleResults = self.calcDirectDiffuseTransAndRefl(b2, f2, b1)
        var Tf_dir_dif: Float64 = frontSide.T
        var Rf_dir_dif: Float64 = frontSide.R
        var Tb_dir_dif: Float64 = backSide.T
        var Rb_dir_dif: Float64 = backSide.R
        var Tf_dir_dir: Float64 = self.m_BeamLayer.getProperty(Property.T, Side.Front)
        var Rf_dir_dir: Float64 = self.m_BeamLayer.getProperty(Property.R, Side.Front)
        var Tb_dir_dir: Float64 = self.m_BeamLayer.getProperty(Property.T, Side.Back)
        var Rb_dir_dir: Float64 = self.m_BeamLayer.getProperty(Property.R, Side.Back)
        var Tf_dif_dif: Float64 = self.m_DiffuseLayer.getProperty(Property.T, Side.Front)
        var Rf_dif_dif: Float64 = self.m_DiffuseLayer.getProperty(Property.R, Side.Front)
        var Tb_dif_dif: Float64 = self.m_DiffuseLayer.getProperty(Property.T, Side.Back)
        var Rb_dif_dif: Float64 = self.m_DiffuseLayer.getProperty(Property.R, Side.Back)
        var aFrontSurface = CScatteringSurface(
            Tf_dir_dir, Rf_dir_dir, Tf_dir_dif, Rf_dir_dif, Tf_dif_dif, Rf_dif_dif)
        var aBackSurface = CScatteringSurface(
            Tb_dir_dir, Rb_dir_dir, Tb_dir_dif, Rb_dir_dif, Tb_dif_dif, Rb_dif_dif)
        self.m_Layer = CScatteringLayer(aFrontSurface, aBackSurface)

    @staticmethod
    def getInterreflectance(t_First: CScatteringSurface, t_Second: CScatteringSurface,
                           t_Scattering: Scattering) -> Float64:
        return 1.0 \
            - t_First.getPropertySimple(PropertySimple.R, t_Scattering) \
                * t_Second.getPropertySimple(PropertySimple.R, t_Scattering)

    def calcDirectDiffuseTransAndRefl(self,
                                     f1: CScatteringSurface,
                                     b1: CScatteringSurface,
                                     f2: CScatteringSurface) -> SimpleResults:
        var aResult = SimpleResults()
        var dirInterrefl: Float64 = self.getInterreflectance(b1, f2, Scattering.DirectDirect)
        var If1_dif_ray: Float64 = f1.getPropertySimple(PropertySimple.R, Scattering.DirectDiffuse)
        var Ib1_dif_ray: Float64 = f1.getPropertySimple(PropertySimple.T, Scattering.DirectDiffuse)
        var Incoming_f2_dir: Float64 = f1.getPropertySimple(PropertySimple.T, Scattering.DirectDirect) / dirInterrefl
        var Incoming_b1_dir: Float64 = Incoming_f2_dir * f2.getPropertySimple(PropertySimple.R, Scattering.DirectDirect)
        var If1_dif_inbm: Float64 = Incoming_b1_dir * b1.getPropertySimple(PropertySimple.T, Scattering.DirectDiffuse)
        var Ib1_dif_inbm: Float64 = Incoming_b1_dir * b1.getPropertySimple(PropertySimple.R, Scattering.DirectDiffuse)
        var If2_dif_inbm: Float64 = Incoming_f2_dir * f2.getPropertySimple(PropertySimple.R, Scattering.DirectDiffuse)
        var Ib2_dif_inbm: Float64 = Incoming_f2_dir * f2.getPropertySimple(PropertySimple.T, Scattering.DirectDiffuse)
        var I_b1_dif: Float64 = Ib1_dif_ray + Ib1_dif_inbm
        var I_f2_dif: Float64 = If2_dif_inbm
        var difInterrefl: Float64 = self.getInterreflectance(b1, f2, Scattering.DiffuseDiffuse)
        var I_fwd: Float64 = (I_b1_dif
            + I_f2_dif * b1.getPropertySimple(PropertySimple.R, Scattering.DiffuseDiffuse)) / difInterrefl
        var I_bck: Float64 = (I_b1_dif * f2.getPropertySimple(PropertySimple.R, Scattering.DiffuseDiffuse)
            + I_f2_dif) / difInterrefl
        var If1_dif_dif: Float64 = I_bck * b1.getPropertySimple(PropertySimple.T, Scattering.DiffuseDiffuse)
        var Ib2_dif_dif: Float64 = I_fwd * f2.getPropertySimple(PropertySimple.T, Scattering.DiffuseDiffuse)
        aResult.T = Ib2_dif_inbm + Ib2_dif_dif
        aResult.R = If1_dif_ray + If1_dif_inbm + If1_dif_dif
        return aResult

    def addLayerComponents(self,
                          t_Layer: CScatteringLayer,
                          t_Side: Side,
                          t_Theta: Float64 = 0.0,
                          t_Phi: Float64 = 0.0):
        var Tf: Float64 = t_Layer.getPropertySimple(
            t_Layer.getMinLambda(), t_Layer.getMaxLambda(),
            PropertySimple.T, Side.Front, Scattering.DirectDirect, t_Theta, t_Phi)
        var Rf: Float64 = t_Layer.getPropertySimple(
            t_Layer.getMinLambda(), t_Layer.getMaxLambda(),
            PropertySimple.R, Side.Front, Scattering.DirectDirect, t_Theta, t_Phi)
        var Tb: Float64 = t_Layer.getPropertySimple(
            t_Layer.getMinLambda(), t_Layer.getMaxLambda(),
            PropertySimple.T, Side.Back, Scattering.DirectDirect, t_Theta, t_Phi)
        var Rb: Float64 = t_Layer.getPropertySimple(
            t_Layer.getMinLambda(), t_Layer.getMaxLambda(),
            PropertySimple.R, Side.Back, Scattering.DirectDirect, t_Theta, t_Phi)
        self.m_BeamLayer.addLayer(Tf, Rf, Tb, Rb, t_Side)
        Tf = t_Layer.getPropertySimple(
            t_Layer.getMinLambda(), t_Layer.getMaxLambda(),
            PropertySimple.T, Side.Front, Scattering.DiffuseDiffuse, t_Theta, t_Phi)
        Rf = t_Layer.getPropertySimple(
            t_Layer.getMinLambda(), t_Layer.getMaxLambda(),
            PropertySimple.R, Side.Front, Scattering.DiffuseDiffuse, t_Theta, t_Phi)
        Tb = t_Layer.getPropertySimple(
            t_Layer.getMinLambda(), t_Layer.getMaxLambda(),
            PropertySimple.T, Side.Back, Scattering.DiffuseDiffuse, t_Theta, t_Phi)
        Rb = t_Layer.getPropertySimple(
            t_Layer.getMinLambda(), t_Layer.getMaxLambda(),
            PropertySimple.R, Side.Back, Scattering.DiffuseDiffuse, t_Theta, t_Phi)
        self.m_DiffuseLayer.addLayer(Tf, Rf, Tb, Rb, t_Side)