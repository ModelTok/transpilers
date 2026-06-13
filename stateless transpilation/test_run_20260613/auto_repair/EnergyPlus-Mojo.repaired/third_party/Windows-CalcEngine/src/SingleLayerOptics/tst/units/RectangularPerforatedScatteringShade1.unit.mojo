from memory import pointer
from WCESingleLayerOptics import CScatteringLayer, CScatteringLayerIR, Material, PropertySimple, Scattering, Side
from WCECommon import *

class TestRectangularPerforatedScatteringShade1:
    @staticmethod
    def SetUp():

def TestProperties():
    SCOPED_TRACE("Begin Test: Rectangular perforated cell - properties.")
    const Tmat = 0.1
    const Rfmat = 0.4
    const Rbmat = 0.4
    const minLambda = 0.3
    const maxLambda = 2.5
    const aMaterial = Material.singleBandMaterial(Tmat, Tmat, Rfmat, Rbmat, minLambda, maxLambda)
    const x = 20.0          # mm
    const y = 25.0          # mm
    const thickness = 7.0   # mm
    const xHole = 5.0       # mm
    const yHole = 8.0       # mm
    var shade = CScatteringLayer.createPerforatedRectangularLayer(aMaterial, x, y, thickness, xHole, yHole)
    const tir = shade.getPropertySimple(minLambda, maxLambda, PropertySimple.T, Side.Front, Scattering.DiffuseDiffuse)
    EXPECT_NEAR(tir, 0.112482, 1e-6)
    const rir = shade.getPropertySimple(minLambda, maxLambda, PropertySimple.R, Side.Front, Scattering.DiffuseDiffuse)
    EXPECT_NEAR(rir, 0.394452, 1e-6)
    var irLayer = CScatteringLayerIR(shade)
    const emiss = irLayer.emissivity(Side.Front)
    EXPECT_NEAR(emiss, 0.493065, 1e-6)

def TestHighEmissivity():
    SCOPED_TRACE("Begin Test: Rectangular perforated cell - properties.")
    const Tmat = 0.1
    const Rfmat = 0.01
    const Rbmat = 0.01
    const minLambda = 0.3
    const maxLambda = 2.5
    const aMaterial = Material.singleBandMaterial(Tmat, Tmat, Rfmat, Rbmat, minLambda, maxLambda)
    const x = 20.0          # mm
    const y = 25.0          # mm
    const thickness = 7.0   # mm
    const xHole = 0.001       # mm
    const yHole = 0.001       # mm
    var shade = CScatteringLayer.createPerforatedRectangularLayer(aMaterial, x, y, thickness, xHole, yHole)
    const tir = shade.getPropertySimple(minLambda, maxLambda, PropertySimple.T, Side.Front, Scattering.DiffuseDiffuse)
    EXPECT_NEAR(tir, 0.1, 1e-6)
    const rir = shade.getPropertySimple(minLambda, maxLambda, PropertySimple.R, Side.Front, Scattering.DiffuseDiffuse)
    EXPECT_NEAR(rir, 0.01, 1e-6)
    var irLayer = CScatteringLayerIR(shade)
    const emiss = irLayer.emissivity(Side.Front)
    EXPECT_NEAR(emiss, 0.89, 1e-6)