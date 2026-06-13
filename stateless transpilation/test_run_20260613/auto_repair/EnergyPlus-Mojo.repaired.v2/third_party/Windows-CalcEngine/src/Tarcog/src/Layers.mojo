from ..IGUGapLayer import CIGUGapLayer
from ..IGUSolidLayer import CIGUSolidLayer
from ..IGUSolidDeflection import CIGUSolidLayerDeflection
from ..BaseShade import CIGUShadeLayer
from ..Surface import CSurface
from ..SupportPillar import CCircularPillar
from ..EffectiveOpenness import EffectiveLayers
from ..TarcogConstants import MaterialConstants, DeflectionConstants
from ...WCEGases import Gases
from memory import Arc

struct Layers:
    @staticmethod
    def solid(thickness: Float64,
             conductivity: Float64,
             frontEmissivity: Float64 = 0.84,
             frontIRTransmittance: Float64 = 0.0,
             backEmissivity: Float64 = 0.84,
             backIRTransmittance: Float64 = 0.0) -> Arc[CIGUSolidLayer]:
        return Arc(
            CIGUSolidLayer(
                thickness,
                conductivity,
                Arc(CSurface(frontEmissivity, frontIRTransmittance)),
                Arc(CSurface(backEmissivity, backIRTransmittance)),
            )
        )

    @staticmethod
    def updateMaterialData(
        layer: Arc[CIGUSolidLayer],
        density: Float64 = MaterialConstants.GLASSDENSITY,
        youngsModulus: Float64 = DeflectionConstants.YOUNGSMODULUS,
    ) -> Arc[CIGUSolidLayer]:
        if layer as CIGUShadeLayer:
            return layer
        else:
            var poissonRatio: Float64 = 0.22
            return Arc(CIGUSolidLayerDeflection(layer[], youngsModulus, poissonRatio, density))

    @staticmethod
    def shading(thickness: Float64,
               conductivity: Float64,
               effectiveOpenness: EffectiveLayers.EffectiveOpenness =
                   EffectiveLayers.EffectiveOpenness(0, 0, 0, 0, 0, 0),
               frontEmissivity: Float64 = 0.84,
               frontTransmittance: Float64 = 0.0,
               backEmissivity: Float64 = 0.84,
               backTransmittance: Float64 = 0.0) -> Arc[CIGUSolidLayer]:
        if effectiveOpenness.isClosed():
            return solid(thickness, conductivity, frontEmissivity, frontTransmittance, backEmissivity, backTransmittance)
        return Arc(
            CIGUShadeLayer(
                thickness,
                conductivity,
                Arc(CShadeOpenings(
                    effectiveOpenness.Atop,
                    effectiveOpenness.Abot,
                    effectiveOpenness.Al,
                    effectiveOpenness.Ar,
                    effectiveOpenness.Ah,
                    effectiveOpenness.FrontPorosity,
                )),
                Arc(CSurface(frontEmissivity, frontTransmittance)),
                Arc(CSurface(backEmissivity, backTransmittance)),
            )
        )

    @staticmethod
    def gap(thickness: Float64, pressure: Float64 = 101325) -> Arc[CIGUGapLayer]:
        return Arc(CIGUGapLayer(thickness, pressure))

    @staticmethod
    def gap(thickness: Float64, gas: Gases.CGas, pressure: Float64 = 101325) -> Arc[CIGUGapLayer]:
        return Arc(CIGUGapLayer(thickness, pressure, gas))

    @staticmethod
    def addCircularPillar(
        gap: Arc[CIGUGapLayer],
        conductivity: Float64,
        spacing: Float64,
        radius: Float64,
    ) -> Arc[CIGUGapLayer]:
        return Arc(CCircularPillar(gap[], conductivity, spacing, radius))