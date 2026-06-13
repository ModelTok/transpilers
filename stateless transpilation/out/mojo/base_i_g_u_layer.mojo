// EXTERNAL DEPS (to wire in glue):
// - BaseLayer (from BaseLayer.mojo)
// - Surface (from Surface.mojo)
// - FenestrationCommon (from FenestrationCommon.mojo)

import BaseLayer
import Surface
import FenestrationCommon

struct CBaseIGULayer {
    var m_Thickness: Float64
}

fn CBaseIGULayer_init(this: &CBaseIGULayer, t_Thickness: Float64) {
    this.m_Thickness = t_Thickness
}

fn CBaseIGULayer_getThickness(this: &CBaseIGULayer) -> Float64 {
    return this.m_Thickness + this.getSurface(FenestrationCommon.Side.Front).getMeanDeflection() - this.getSurface(FenestrationCommon.Side.Back).getMeanDeflection()
}

fn CBaseIGULayer_getTemperature(this: &CBaseIGULayer, t_Position: FenestrationCommon.Side) -> Float64 {
    return this.getSurface(t_Position).getTemperature()
}

fn CBaseIGULayer_J(this: &CBaseIGULayer, t_Position: FenestrationCommon.Side) -> Float64 {
    return this.getSurface(t_Position).J()
}

fn CBaseIGULayer_getMaxDeflection(this: &CBaseIGULayer) -> Float64 {
    assert(this.getSurface(FenestrationCommon.Side.Front).getMaxDeflection() == this.getSurface(FenestrationCommon.Side.Back).getMaxDeflection())
    return this.getSurface(FenestrationCommon.Side.Front).getMaxDeflection()
}

fn CBaseIGULayer_getMeanDeflection(this: &CBaseIGULayer) -> Float64 {
    assert(this.getSurface(FenestrationCommon.Side.Front).getMeanDeflection() == this.getSurface(FenestrationCommon.Side.Back).getMeanDeflection())
    return this.getSurface(FenestrationCommon.Side.Front).getMeanDeflection()
}

fn CBaseIGULayer_getConductivity(this: &CBaseIGULayer) -> Float64 {
    return this.getConductionConvectionCoefficient() * this.m_Thickness
}

fn CBaseIGULayer_getEffectiveThermalConductivity(this: &CBaseIGULayer) -> Float64 {
    return fabs(this.getHeatFlow() * this.m_Thickness / (this.getSurface(FenestrationCommon.Side.Front).getTemperature() - this.getSurface(FenestrationCommon.Side.Back).getTemperature()))
}

fn CBaseIGULayer_layerTemperature(this: &CBaseIGULayer) -> Float64 {
    return (this.getTemperature(FenestrationCommon.Side.Front) + this.getTemperature(FenestrationCommon.Side.Back)) / 2
}

fn CBaseIGULayer_getConductionConvectionCoefficient(this: &CBaseIGULayer) -> Float64 {
    // Placeholder for actual implementation
    return 0.0
}

fn CBaseIGULayer_getHeatFlow(this: &CBaseIGULayer) -> Float64 {
    // Placeholder for actual implementation
    return 0.0
}
