/* Copyright 1992-2009	Regents of University of California
 *						Lawrence Berkeley National Laboratory
 *
 *  Authors: R.J. Hitchcock and W.L. Carroll
 *           Building Technologies Department
 *           Lawrence Berkeley National Laboratory
 */
/*
NOTICE: The Government is granted for itself and others acting on its behalf
a paid-up, nonexclusive, irrevocable worldwide license in this data to reproduce,
prepare derivative works, and perform publicly and display publicly.
Beginning five (5) years after (date permission to assert copyright was obtained),
subject to two possible five year renewals, the Government is granted for itself
and others acting on its behalf a paid-up, nonexclusive, irrevocable worldwide
license in this data to reproduce, prepare derivative works, distribute copies to
the public, perform publicly and display publicly, and to permit others to do so.
NEITHER THE UNITED STATES NOR THE UNITED STATES DEPARTMENT OF ENERGY, NOR ANY OF
THEIR EMPLOYEES, MAKES ANY WARRANTY, EXPRESS OR IMPLIED, OR ASSUMES ANY LEGAL
LIABILITY OR RESPONSIBILITY FOR THE ACCURACY, COMPLETENESS, OR USEFULNESS OF ANY
INFORMATION, APPARATUS, PRODUCT, OR PROCESS DISCLOSED, OR REPRESENTS THAT ITS USE
WOULD NOT INFRINGE PRIVATELY OWNED RIGHTS.
*/
from BGL import *
from helpers import *
from hemisphiral import *
from btdf import *
from DElightManagerC import *
from DEF import *
from math import *
from sys import *
from io import *
from string import *
from vector import *
from map import *
from algorithm import *
from limits import *
from cstring import *
from stdlib import *
from fstream import *
from sstream import *
from iostream import *
from iomanip import *

alias Double = Float64
alias Int = Int32

var INFINITY: Float64 = Float64(1.0 / 0.0)
var NaN_QUIET: Float64 = Float64(0.0 / 0.0)
var NaN_SIGNAL: Float64 = Float64(0.0 / 0.0)
var MAXPointTol: Float64 = 0.0

def DegToRad(angle: Double) -> Double:
    return angle * PI / 180.0

def RadToDeg(angle: Double) -> Double:
    return angle * 180.0 / PI

def AnglesToDir3D(phi: Double, theta: Double) -> BGL.vector3:
    return BGL.vector3(sin(theta) * cos(phi), sin(theta) * sin(phi), cos(theta))

def Dir3DToAngles(vDir: BGL.vector3) -> vector[Double]:
    var RotAng = vector[Double](2)
    BGL.normalize(vDir)
    if vDir[2] >= 1.0:
        RotAng[1] = 0.0
    elif vDir[2] <= -1.0:
        RotAng[1] = PI
    else:
        RotAng[1] = acos(vDir[2])
        RotAng[0] = atan2(vDir[1], vDir[0])
    return RotAng

@value
struct LumParam:
    var object: String
    var source: String
    var filename: String
    var type: String
    var BFlux0: Double
    var dispersion: Double
    var phi0: Double
    var theta0: Double
    var Dir0: BGL.vector3
    var GndRefl: Double
    var btdftype: String
    var btdfHSResIn: Int
    var btdfHSResOut: Int
    var visTransNormal: Double
    var visTransExponent: Double
    var EPlusType: String
    var EPlusCoef: StaticTuple[Double, 6]
    var LightShelfReflectance: Double
    var dSunAltRadians: Double
    var dSunAzmRadians: Double
    var dZenithLum: Double
    var dMonthlyExtraTerrIllum: Double
    var dTurbidityFactor: Double
    var dBldgMonthlyAtmosMois: Double
    var dBldgMonthlyAtmosTurb: Double
    var dBldgAltitude: Double
    var BadName: String

    def __init__(inout self):
        self.object = ""
        self.source = ""
        self.filename = ""
        self.type = ""
        self.BFlux0 = 0.0
        self.dispersion = 0.0
        self.phi0 = 0.0
        self.theta0 = 0.0
        self.Dir0 = BGL.vector3(0.0, 0.0, 0.0)
        self.GndRefl = 0.0
        self.btdftype = ""
        self.btdfHSResIn = BTDF_HSRES_IN
        self.btdfHSResOut = BTDF_HSRES_OUT
        self.visTransNormal = 0.0
        self.visTransExponent = 0.0
        self.EPlusType = ""
        self.EPlusCoef = StaticTuple[Double, 6](0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
        self.LightShelfReflectance = 0.0
        self.dSunAltRadians = 0.0
        self.dSunAzmRadians = 0.0
        self.dZenithLum = 0.0
        self.dMonthlyExtraTerrIllum = 0.0
        self.dTurbidityFactor = 0.0
        self.dBldgMonthlyAtmosMois = 0.0
        self.dBldgMonthlyAtmosTurb = 0.0
        self.dBldgAltitude = 0.0
        self.BadName = ""

    def __del__(owned self):

    def Dump(inout self):
        print("object: " + self.object)
        print("source: " + self.source)
        print("filename: " + self.filename)
        print("type: " + self.type)
        print("BFlux0: " + str(self.BFlux0))
        print("phi0: " + str(self.phi0))
        print("theta0: " + str(self.theta0))
        print("Dir0: " + str(self.Dir0))
        print("dispersion: " + str(self.dispersion))
        print("GndRefl: " + str(self.GndRefl))
        print("BadName: " + self.BadName)
        print("btdftype: " + self.btdftype)
        print("btdfHSResIn: " + str(self.btdfHSResIn))
        print("btdfHSResOut: " + str(self.btdfHSResOut))
        print("visTransNormal: " + str(self.visTransNormal))
        print("visTransExponent: " + str(self.visTransExponent))
        print("EPlusType: " + self.EPlusType)
        print("EPlusCoef: ", end="")
        for ii in range(6):
            print(str(self.EPlusCoef[ii]) + " ", end="")
        print()
        print("LightShelfReflectance: " + str(self.LightShelfReflectance))
        print("dSunAltRadians: " + str(self.dSunAltRadians))
        print("dSunAzmRadians: " + str(self.dSunAzmRadians))
        print("dZenithLum: " + str(self.dZenithLum))

def IsValidTypeName(nametype: String, inname: String) -> Bool:
    if nametype == "OBJECT":
        if inname == "SKY":
            return True
        elif inname == "BTDF":
            return True
        elif inname == "LUMMAP":
            return True
        elif inname == "WINDOW":
            return True
        else:
            return False
    elif nametype == "SOURCE":
        if inname == "FILE":
            return True
        elif inname == "GEN":
            return True
        else:
            return False
    elif nametype == "GENTYPE":
        if inname == "SUPERLAMBERTIAN":
            return True
        elif inname == "GAUSS":
            return True
        elif inname == "SIMPLEBEAM":
            return True
        elif inname == "CONST":
            return True
        elif inname == "CIEOVERCASTSKY":
            return True
        elif inname == "CIECLEARSKY":
            return True
        elif inname == "CIECLEARSUN":
            return True
        elif inname == "SINGLEPANE":
            return True
        elif inname == "EPLUS":
            return True
        elif inname == "WINDOW":
            return True
        elif inname == "LIGHTSHELF":
            return True
        else:
            return False
    else:
        return False

def GenDirLum(lp: LumParam, Direction: BGL.vector3) -> Double:
    var fptr: fn(LumParam, BGL.vector3) -> Double
    if lp.type == "SUPERLAMBERTIAN":
        fptr = SuperLambertianLum
    elif lp.type == "GAUSS":
        fptr = GaussLum
    elif lp.type == "SIMPLEBEAM":
        fptr = SimpleBeamLum
    elif lp.type == "CONST":
        fptr = ConstLum
    elif lp.type == "CIEOVERCASTSKY":
        fptr = CIEOvercastSkyLum
    elif lp.type == "CIECLEARSKY":
        fptr = CIEClearSkyLum
    elif lp.type == "CIECLEARSUN":
        fptr = CIEClearSunLum
    else:
        return -1.0
    return fptr(lp, Direction)

def GenLuminanceMap(lp: LumParam) -> HemiSphiral:
    var zMin: Int = -1
    var hs0 = HemiSphiral(zMin, lp.btdfHSResOut)
    var fptr: fn(LumParam, BGL.vector3) -> Double
    if lp.type == "SUPERLAMBERTIAN":
        fptr = SuperLambertianLum
    elif lp.type == "GAUSS":
        fptr = GaussLum
    elif lp.type == "SIMPLEBEAM":
        fptr = SimpleBeamLum
    elif lp.type == "CONST":
        fptr = ConstLum
    elif lp.type == "CIEOVERCASTSKY":
        fptr = CIEOvercastSkyLum
    elif lp.type == "CIECLEARSKY":
        fptr = CIEClearSkyLum
    elif lp.type == "CIECLEARSUN":
        fptr = CIEClearSunLum
    else:
        hs0.resize(0)
        return hs0
    for ii in range(lp.btdfHSResOut):
        hs0.valList[ii] = fptr(lp, hs0.dir(ii))
        if lp.type == "CIECLEARSUN":
            hs0.valList[ii] /= hs0.omega
    return hs0

def ConstLum(lp: LumParam, Direction: BGL.vector3) -> Double:
    _ = Direction
    return lp.BFlux0

def CosThetaLum(lp: LumParam) -> Double:
    return lp.BFlux0

def SimpleBeamLum(lp: LumParam, Direction: BGL.vector3) -> Double:
    var CosConeAngle: Double = cos(lp.dispersion * PI / 180.0)
    if BGL.dot(lp.Dir0, Direction) < CosConeAngle:
        return 0.0
    var BFlux1: Double = lp.BFlux0
    var ConeSolidAngle: Double = 2.0 * PI * (1.0 - CosConeAngle)
    var FluxRatio: Double = BFlux1 / ConeSolidAngle
    return FluxRatio

def SuperLambertianLum(lp: LumParam, Direction: BGL.vector3) -> Double:
    if lp.dispersion <= 0.0:
        return 0.0
    var ConeAngle: Double = DegToRad(lp.dispersion)
    var Dot: Double = max(0.0, BGL.dot(lp.Dir0, Direction))
    var Power: Double = PI / ConeAngle - 1.0
    var SLbrt: Double = lp.BFlux0 * pow(Dot, Power)
    return SLbrt

def GaussLum(lp: LumParam, Direction: BGL.vector3) -> Double:
    lp.dispersion /= 100.0
    var Dot: Double = max(min(BGL.dot(lp.Dir0, Direction), 1.0), -1.0)
    var theta: Double = acos(Dot)
    var x: Double
    if fabs(1.0 - theta / PI) <= 1.0e-10:
        x = theta / 1.0e-20
    else:
        x = theta / (1.0 - theta / PI)
    var sigmasq: Double = lp.dispersion * lp.dispersion
    var exponent: Double = (x * x) / (2.0 * sigmasq)
    if exponent > 50.0:
        return 0.0
    var Gbrt: Double = lp.BFlux0 * exp(-exponent)
    return Gbrt

def CIEOvercastSkyLum(lp: LumParam, Direction: BGL.vector3) -> Double:
    var dSunAlt: Double = lp.dSunAltRadians
    var dSinSunAlt: Double = sin(dSunAlt)
    var dSinSkyAlt: Double = Direction[2]
    var CIEOvercastSkyLuminance: Double = 92.9 * (0.123 + 8.6 * dSinSunAlt) * (0.33333 + 0.66667 * dSinSkyAlt)
    return CIEOvercastSkyLuminance

def CIEClearSkyLum(lp: LumParam, Direction: BGL.vector3) -> Double:
    var dSunAlt: Double = lp.dSunAltRadians
    var dSinSunAlt: Double = sin(dSunAlt)
    var dSinSkyAlt: Double = Direction[2]
    var dSkyAlt: Double = asin(dSinSkyAlt)
    var dSkyAzm: Double
    if (Direction[0] == 0.0) and (Direction[1] == 0.0):
        dSkyAzm = 0.0
    else:
        dSkyAzm = atan2(Direction[1], Direction[0])
    var cangle: Double = dSinSkyAlt * dSinSunAlt + cos(dSkyAlt) * cos(dSunAlt) * cos(dSkyAzm - lp.dSunAzmRadians)
    cangle = max(-1.0, min(cangle, 1.0))
    var angle: Double = acos(cangle)
    var z1: Double = 0.91 + 10.0 * exp(-3.0 * angle) + 0.45 * cangle * cangle
    var z2: Double = 1.0 - exp(-0.32 / dSinSkyAlt)
    var z3: Double = 0.27385 * (0.91 + 10.0 * exp(-3.0 * (1.5708 - dSunAlt)) + 0.45 * dSinSunAlt * dSinSunAlt)
    var CIEClearSkyLuminance: Double = 92.9 * lp.dZenithLum * z1 * z2 / z3
    return max(0.0, CIEClearSkyLuminance)

def CIEClearTurbidSkyLum(lp: LumParam, Direction: BGL.vector3) -> Double:
    var dSunAlt: Double = lp.dSunAltRadians
    var dSinSunAlt: Double = sin(dSunAlt)
    var dSinSkyAlt: Double = Direction[2]
    var dSkyAlt: Double = asin(dSinSkyAlt)
    var dSkyAzm: Double
    if (Direction[0] == 0.0) and (Direction[1] == 0.0):
        dSkyAzm = 0.0
    else:
        dSkyAzm = atan2(Direction[1], Direction[0])
    var cangle: Double = dSinSkyAlt * dSinSunAlt + cos(dSkyAlt) * cos(dSunAlt) * cos(dSkyAzm - lp.dSunAzmRadians)
    cangle = max(-1.0, min(cangle, 1.0))
    var angle: Double = acos(cangle)
    var z1: Double = 0.856 + 16.0 * exp(-3.0 * angle) + 0.3 * cangle * cangle
    var z2: Double = 1.0 - exp(-0.32 / dSinSkyAlt)
    var z3: Double = 0.27385 * (0.856 + 16.0 * exp(-3.0 * (1.5708 - dSunAlt)) + 0.3 * dSinSunAlt * dSinSunAlt)
    var CIEClearTurbidSkyLuminance: Double = 92.9 * lp.dZenithLum * z1 * z2 / z3
    return max(0.0, CIEClearTurbidSkyLuminance)

def CIEIntermediateSkyLum(lp: LumParam, Direction: BGL.vector3) -> Double:
    var dSunAlt: Double = lp.dSunAltRadians
    var dSinSunAlt: Double = sin(dSunAlt)
    var dSinSkyAlt: Double = Direction[2]
    var dSkyAlt: Double = asin(dSinSkyAlt)
    var dSkyAzm: Double
    if (Direction[0] == 0.0) and (Direction[1] == 0.0):
        dSkyAzm = 0.0
    else:
        dSkyAzm = atan2(Direction[1], Direction[0])
    var cangle: Double = dSinSkyAlt * dSinSunAlt + cos(dSkyAlt) * cos(dSunAlt) * cos(dSkyAzm - lp.dSunAzmRadians)
    cangle = max(-1.0, min(cangle, 1.0))
    var angle: Double = acos(cangle)
    var z1: Double = (1.35 * (sin(3.59 * dSkyAlt - 0.009) + 2.31) * sin(2.6 * dSunAlt + 0.316) + dSkyAlt + 4.799) / 2.326
    var z2: Double = exp(-angle * 0.563 * ((dSunAlt - 0.008) * (dSkyAlt + 1.059) + 0.812))
    var z3: Double = 0.99224 * sin(2.6 * dSunAlt + 0.316) + 2.73852
    var z4: Double = exp(-(1.5708 - dSunAlt) * 0.563 * ((dSunAlt - 0.008) * 2.6298 + 0.812))
    var CIEIntermediateSkyLuminance: Double = 92.9 * lp.dZenithLum * z1 * z2 / (z3 * z4)
    return max(0.0, CIEIntermediateSkyLuminance)

def CIEClearSunLum(lp: LumParam, Direction: BGL.vector3) -> Double:
    var dDirectionAlt: Double = asin(Direction[2])
    var dDirectionAzm: Double
    if (Direction[0] == 0.0) and (Direction[1] == 0.0):
        dDirectionAzm = 0.0
    else:
        dDirectionAzm = atan2(Direction[1], Direction[0])
    if (dDirectionAlt >= (lp.dSunAltRadians + 7.0 * 0.009291)) or (dDirectionAlt <= (lp.dSunAltRadians - 7.0 * 0.009291)):
        return 0.0
    if (dDirectionAzm >= (lp.dSunAzmRadians + 5.0 * 0.009291)) or (dDirectionAzm <= (lp.dSunAzmRadians - 5.0 * 0.009291)):
        return 0.0
    var lop: Double
    var powlop: Double
    var am: Double
    var c1: Double
    var c2: Double
    var c3: Double
    var s1: Double
    var s2: Double
    var s3: Double
    var abars: Double
    var bc: Double
    var efflum: Double
    var dSunAlt: Double = lp.dSunAltRadians
    var dSinSunAlt: Double = sin(dSunAlt)
    var dSunAltDegrees: Double = RadToDeg(dSunAlt)
    lop = dSunAltDegrees + 3.885
    if lop < 0.0:
        return 0.0
    else:
        powlop = pow(lop, 1.253)
    am = (1.0 - 0.1 * lp.dBldgAltitude / 3281.0) / (dSinSunAlt + 0.15 / powlop)
    c1 = 2.1099 * cos(dSunAlt)
    c2 = 0.6322 * cos(2.0 * dSunAlt)
    c3 = 0.0252 * cos(3.0 * dSunAlt)
    s1 = 1.0022 * dSinSunAlt
    s2 = 1.0077 * sin(2.0 * dSunAlt)
    s3 = 0.2606 * sin(3.0 * dSunAlt)
    abars = 1.4899 - c1 + c2 + c3 - s1 + s2 - s3
    bc = min(0.2, lp.dBldgMonthlyAtmosTurb)
    efflum = (99.4 + 4.7 * (lp.dBldgMonthlyAtmosMois * 2.54) - 52.4 * bc) * (1.0 - exp((24.0 * bc - 8.0) * dSunAlt))
    var CIEClearSunLuminance: Double = efflum * (lp.dMonthlyExtraTerrIllum / 93.73) * exp(-am * lp.dTurbidityFactor * abars)
    return CIEClearSunLuminance

def GenSky(lp: LumParam) -> HemiSphiral:
    var sky0 = HemiSphiral(lp.btdfHSResOut)
    if lp.source == "GEN":
        if lp.type == "CIECLEARSUN":
            var sky1: HemiSphiral
            sky1 = GenLuminanceMap(lp)
            var lp_mut = lp
            lp_mut.type = "GAUSS"
            lp_mut.dispersion = 3.25
            lp_mut.phi0 = lp.dSunAzmRadians
            lp_mut.theta0 = PI / 2.0 - lp.dSunAltRadians
            lp_mut.Dir0 = AnglesToDir3D(lp_mut.phi0, lp_mut.theta0)
            if sky0.omega == 0.0:
                writewndo("GenSky: Divide by Zero trapped.\n", "e")
            lp_mut.BFlux0 = sky1.TotIllum() / (sky0.omega)
            sky0 = GenLuminanceMap(lp_mut)
        else:
            sky0 = GenLuminanceMap(lp)
        var skyTotH: Double = sky0.TotHorizIllum()
        for ii in range(sky0.size() // 2 + 1, sky0.size()):
            sky0.valList[ii] = lp.GndRefl * skyTotH * -sky0.costheta(ii)
    elif lp.source == "FILE":
        var infile = ifstream(lp.filename)
        if infile:
            sky0.load(infile)
    return sky0

def GenBTDF(inout lp: LumParam) -> btdfHS:
    var lptmp = lp
    lptmp.type = "GAUSS"
    lptmp.BFlux0 = 1.00
    var dirwind: BGL.vector3
    var dirLS: BGL.vector3
    var lmTrans = HemiSphiral(lp.btdfHSResOut)
    var lmRefl = HemiSphiral(lp.btdfHSResOut)
    var lmTot = HemiSphiral(lp.btdfHSResOut)
    var tau: Double
    var pbtdf0 = btdfHS(lp.btdfHSResIn, lp.btdfHSResOut)
    for ii in range(lp.btdfHSResIn):
        dirwind = pbtdf0.inDir(ii)
        if dirwind[2] < 0.0:
            break
        dirwind = dirwind * BGL.vector3(-1.0, -1.0, -1.0)
        dirwind = dirwind * BGL.vector3(-1.0, +1.0, -1.0)
        tau = lptmp.visTransNormal * pow(dirwind[2], lptmp.visTransExponent)
        pbtdf0.HSin[ii] = tau
        if lptmp.btdftype == "WINDOW":
            lptmp.Dir0 = BGL.norm(dirwind)
            lmTrans = GenLuminanceMap(lptmp)
            pbtdf0.HSoutList[ii] = (lmTrans * tau) / lmTrans.TotHorizIllum()
        elif lptmp.btdftype == "LIGHTSHELF":
            lptmp.Dir0 = BGL.norm(dirwind)
            lmTrans = GenLuminanceMap(lptmp)
            dirLS = dirwind
            if dirwind[1] < 0.0:
                dirLS = dirwind * BGL.vector3(+1.0, -1.0, +1.0)
            lptmp.Dir0 = BGL.norm(dirLS)
            lmRefl = GenLuminanceMap(lptmp)
            lmTot = lmTrans * (1.0 - lptmp.LightShelfReflectance) + lmRefl * lptmp.LightShelfReflectance
            pbtdf0.HSoutList[ii] = (lmTot * tau) / lmTot.TotHorizIllum()
    return pbtdf0

def SkyBTDFIntegration(inout sky0: HemiSphiral, inout pbtdf0: btdf, ics: BGL.RHCoordSys3) -> HemiSphiral:
    var LumMap = HemiSphiral(pbtdf0.HSoutList[0].size())
    var lm = HemiSphiral(pbtdf0.HSoutList[0].size())
    var Trgz0 = Tregenza()
    var ii: Int
    var jj: Int
    var skyLum: Double
    var skyLumTot: Double = 0.0
    var dir: BGL.vector3
    var dirsky: BGL.vector3
    for ii in range(pbtdf0.size()):
        dir = pbtdf0.inDir(ii)
        if dir[2] < 0.0:
            break
        dirsky = BGL.dirLCStoWCS(dir, ics.RotateY())
        skyLum = sky0.interp(dirsky) * pbtdf0.inDirOmega(ii) * dir[2]
        for jj in range(pbtdf0.HSoutList[0].size()):
            if pbtdf0.outDir(jj)[2] < 0.0:
                break
            lm[jj] = pbtdf0.qexact(ii, jj) * skyLum
        LumMap += lm
        skyLumTot += skyLum
    return LumMap

def POLYF_WLC(dCosI: Double, EPCoef: StaticTuple[Double, 6]) -> Double:
    var transmittance: Double
    if dCosI < 0.0 or dCosI > 1.0:
        transmittance = 0.0
    else:
        transmittance = dCosI * (EPCoef[0] + dCosI * (EPCoef[1] + dCosI * (EPCoef[2] + dCosI * (EPCoef[3] + dCosI * (EPCoef[4] + dCosI * EPCoef[5])))))
    return transmittance

def GenWindowMap(inout lp: LumParam, inout sky0: HemiSphiral, ics: BGL.RHCoordSys3) -> HemiSphiral:
    var LumMap = HemiSphiral(lp.btdfHSResOut)
    var tau: Double
    var ii: Int
    var dir: BGL.vector3
    var iimax: Int = lp.btdfHSResOut
    var z: Double
    for ii in range(iimax):
        z = LumMap.costheta(ii)
        if z < 0.0:
            break
        dir = LumMap.dir(ii)
        dir = dir * BGL.vector3(-1.0, -1.0, -1.0)
        dir = BGL.dirLCStoWCS(dir, ics)
        if lp.type == "SINGLEPANE":
            tau = lp.visTransNormal * pow(z, lp.visTransExponent)
        elif lp.type == "EPLUS":
            tau = POLYF_WLC(z, lp.EPlusCoef)
        LumMap[ii] = sky0.interp(dir) * tau
    return LumMap

def SecretDecoderRing(inout lp: LumParam, InStr: String) -> Bool:
    var ii: Int
    var InStrList = vParseList(InStr)
    if InStrList.size() >= 1:
        if IsValidTypeName("OBJECT", InStrList[0]):
            lp.object = InStrList[0]
        else:
            lp.BadName = InStrList[0]
            return False
    if InStrList.size() >= 2:
        if IsValidTypeName("SOURCE", InStrList[1]):
            lp.source = InStrList[1]
        else:
            lp.BadName = InStrList[1]
            return False
    var oldsize: Int = InStrList.size()
    for ii in range(2, InStrList.size()):
        InStrList[ii - 2] = InStrList[ii]
    InStrList.resize(oldsize - 2)
    if lp.source == "FILE":
        if InStrList.size() >= 1:
            lp.filename = InStrList[0]
        else:
            lp.BadName = "missing FILENAME"
            return False
    if (lp.object == "BTDF") and (lp.source == "GEN"):
        if IsValidTypeName("GENTYPE", InStrList[0]):
            lp.btdftype = InStrList[0]
        else:
            lp.BadName = InStrList[0]
            return False
        if lp.btdftype == "WINDOW":
            if InStrList.size() < 3:
                lp.BadName = "missing BTDF:WINDOW Parameters"
                return False
            lp.visTransNormal = atof(InStrList[1])
            lp.dispersion = atof(InStrList[2])
            if InStrList.size() >= 4:
                lp.visTransExponent = atof(InStrList[3])
            else:
                lp.visTransExponent = 2.00
        elif lp.btdftype == "LIGHTSHELF":
            if InStrList.size() < 3:
                lp.BadName = "missing BTDF:LIGHTSHELF Parameters"
                return False
            lp.visTransNormal = atof(InStrList[1])
            lp.dispersion = atof(InStrList[2])
            if InStrList.size() >= 4:
                lp.LightShelfReflectance = atof(InStrList[3])
            else:
                lp.LightShelfReflectance = 1.00
            if InStrList.size() >= 5:
                lp.visTransExponent = atof(InStrList[4])
            else:
                lp.visTransExponent = 2.00
        return True
    if (lp.object == "WINDOW") and (lp.source == "GEN"):
        if IsValidTypeName("GENTYPE", InStrList[0]):
            lp.type = InStrList[0]
        else:
            lp.BadName = InStrList[0]
            return False
        if lp.type == "SINGLEPANE":
            if InStrList.size() >= 3:
                lp.visTransNormal = atof(InStrList[1])
                lp.visTransExponent = atof(InStrList[2])
            else:
                lp.BadName = "missing WINDOW Parameters"
                return False
        elif lp.type == "EPLUS":
            if InStrList.size() >= 8:
                lp.EPlusType = InStrList[1]
                lp.EPlusCoef[0] = atof(InStrList[2])
                lp.EPlusCoef[1] = atof(InStrList[3])
                lp.EPlusCoef[2] = atof(InStrList[4])
                lp.EPlusCoef[3] = atof(InStrList[5])
                lp.EPlusCoef[4] = atof(InStrList[6])
                lp.EPlusCoef[5] = atof(InStrList[7])
            else:
                lp.BadName = "missing WINDOW Parameters"
                return False
        return True
    if lp.source == "GEN":
        if InStrList.size() >= 5:
            if IsValidTypeName("GENTYPE", InStrList[0]):
                lp.type = InStrList[0]
            else:
                lp.BadName = InStrList[0]
                return False
            if lp.type == "CIECLEARSKY":
                lp.dSunAltRadians = DegToRad(atof(InStrList[1]))
                lp.dSunAzmRadians = DegToRad(atof(InStrList[2]))
                lp.dZenithLum = atof(InStrList[3])
                lp.GndRefl = atof(InStrList[4])
            elif lp.type == "CIECLEARSUN":
                lp.dSunAltRadians = DegToRad(atof(InStrList[1]))
                lp.dSunAzmRadians = DegToRad(atof(InStrList[2]))
                lp.dMonthlyExtraTerrIllum = atof(InStrList[3])
                lp.dTurbidityFactor = atof(InStrList[4])
                lp.dBldgMonthlyAtmosMois = atof(InStrList[5])
                lp.dBldgMonthlyAtmosTurb = atof(InStrList[6])
                lp.dBldgAltitude = atof(InStrList[7])
                lp.GndRefl = atof(InStrList[8])
            else:
                lp.phi0 = atof(InStrList[1])
                lp.theta0 = atof(InStrList[2])
                lp.Dir0 = AnglesToDir3D(DegToRad(lp.phi0), DegToRad(lp.theta0))
                lp.dispersion = atof(InStrList[3])
                lp.BFlux0 = atof(InStrList[4])
        elif InStrList.size() >= 3:
            if IsValidTypeName("GENTYPE", InStrList[0]):
                lp.type = InStrList[0]
            else:
                lp.BadName = InStrList[0]
                return False
            lp.dSunAltRadians = DegToRad(atof(InStrList[1]))
        else:
            lp.BadName = "missing Gen Parameters"
            return False
        if lp.object == "SKY":
            if (InStrList.size() >= 6) and (lp.type != "CIECLEARSUN") and (lp.type != "CIECLEARSKY"):
                lp.GndRefl = atof(InStrList[5])
            elif InStrList.size() >= 3:
                if lp.type == "CIEOVERCASTSKY":
                    lp.GndRefl = atof(InStrList[2])
            else:
                lp.BadName = "missing SKY GndRefl"
                return False
        elif lp.object == "BTDF":
            if InStrList.size() >= 6:
                if IsValidTypeName("BTDFTYPE", InStrList[5]):
                    lp.btdftype = InStrList[5]
                else:
                    lp.BadName = InStrList[5]
                    return False
            else:
                lp.BadName = "missing BTDF typename"
                return False
    return True

def charInList(c0: UInt8, delimList: String) -> Bool:
    for ic in range(delimList.size()):
        if c0 == delimList[ic]:
            return True
    return False

def vParseList(InStr: String, delimList: String = "^") -> vector[String]:
    var strTmp: String
    var strList = vector[String]()
    for ii in range(InStr.size()):
        if charInList(InStr[ii], delimList):
            strList.push_back(strTmp)
            strTmp = ""
            continue
        strTmp += InStr[ii]
    strList.push_back(strTmp)
    return strList

@value
struct FILE_FLG:
    var zero: Bool
    var out: Bool
    var log: Bool
    var dbg: Bool
    var err: Bool
    var warn: Bool

    def __init__(inout self):
        self.zero = False
        self.out = False
        self.log = False
        self.dbg = False
        self.err = False
        self.warn = False

    def __init__(inout self, sfpflg: String):
        self.zero = False
        self.out = False
        self.log = False
        self.dbg = False
        self.err = False
        self.warn = False
        if sfpflg.size() == 0:
            self.out = True
        else:
            for isfp in range(sfpflg.size()):
                if sfpflg[isfp] == '0':
                    self.zero = True
                elif sfpflg[isfp] == 'o':
                    self.out = True
                elif sfpflg[isfp] == 'l':
                    self.log = True
                elif sfpflg[isfp] == 'd':
                    self.dbg = True
                elif sfpflg[isfp] == 'e':
                    self.err = True
                elif sfpflg[isfp] == 'w':
                    self.warn = True

@value
struct RADdata:
    var ndim: Int
    var beg1: Double
    var end1: Double
    var n1: Int
    var beg2: Double
    var end2: Double
    var n2: Int
    var DataArray: vector[vector[Double]]

    def load(inout self, filename: String) -> Int:
        var osstream = OStringStream()
        var infile = ifstream(filename)
        if not infile:
            osstream << "Error: RADdata::load: Can't open infile: \"" << filename << "\"\n"
            writewndo(osstream.str(), "e")
            return 0
        infile >> self.ndim
        if self.ndim != 2:
            osstream << "Error: RADdata::load: ndim != 2: " << self.ndim << "\n"
            writewndo(osstream.str(), "e")
            return 0
        infile >> self.beg1 >> self.end1 >> self.n1
        infile >> self.beg2 >> self.end2 >> self.n2
        self.DataArray.resize(self.n1)
        var ndata: Int = 0
        for iin1 in range(self.n1):
            self.DataArray[iin1].resize(self.n2)
            for iin2 in range(self.n2):
                infile >> self.DataArray[iin1][iin2]
                ndata += 1
        infile.clear()
        infile.close()
        return ndata

    def summary(inout self, inout outfile: OStream):
        outfile << self.ndim << "\n"
        outfile << self.beg1 << " " << self.end1 << " " << self.n1 << "\n"
        outfile << self.beg2 << " " << self.end2 << " " << self.n2 << "\n"

    def dump(inout self, inout outfile: OStream):
        self.summary(outfile)
        for iin1 in range(self.n1):
            for iin2 in range(self.n2):
                outfile << self.DataArray[iin1][iin2] << " "
            outfile << "\n"

    def convertToHS(inout self) -> HemiSphiral:
        var Nsize: Int = 1 * self.n1 * self.n2
        var hs0 = HemiSphiral(Nsize)
        hs0.summary()
        var nnin: Int
        var nd = vector[nearestdata]()
        var nninsizeMax: Int = 0
        var nninsizeMin: Int = 0
        var nninsizeDist = vector[Int](25, 0)
        var qdataMax: Double = 0.0
        var qdataMin: Double = 0.0
        var qdataSum: Double = 0.0
        var inwgt = vector[Double]()
        var indxCount = vector[Int](Nsize, 0)
        var indxCountDist = vector[Int](100, 0)
        var zCount: Int = 0
        var phiRAD: Double
        var thetaRAD: Double
        var qdata: Double
        var phiSPH: Double
        var thetaSPH: Double
        var deltathetaRAD: Double = self.end1 / (self.n1 - 1.0)
        var deltaphiRAD: Double = self.end2 / (self.n2 - 1.0)
        var dir: BGL.vector3
        var iread: Int = 0
        var limit1: Int = self.n1 - 1
        var limit2: Int = self.n2 - 1
        for iin1 in range(limit1 + 1):
            if iin1 == limit1:
                limit2 = 1
            for iin2 in range(limit2):
                qdata = self.DataArray[iin1][iin2]
                qdataSum += qdata
                iread += 1
                thetaRAD = self.beg1 + deltathetaRAD * iin1
                thetaSPH = 90.0 - thetaRAD
                phiRAD = self.beg2 + deltaphiRAD * iin2
                phiSPH = -(phiRAD + 90.0)
                dir = AnglesToDir3D(DegToRad(phiSPH), DegToRad(thetaSPH))
                if arcdist(dir, BGL.vector3(0.0, 0.0, 1.0)) < 0.90 * hs0.DA:
                    zCount += 1
                nnin = hs0.nearestc(0.90 * hs0.DA, dir, nd)
                if iread == 1:
                    nninsizeMax = nnin
                    nninsizeMin = nnin
                    qdataMax = qdata
                    qdataMin = qdata
                else:
                    nninsizeMax = max(nninsizeMax, nnin)
                    nninsizeMin = min(nninsizeMin, nnin)
                    qdataMax = max(qdataMax, qdata)
                    qdataMin = min(qdataMin, qdata)
                nninsizeDist[nnin] += 1
                hs0.valList[nd[0].indx] += qdata
                indxCount[nd[0].indx] += 1
        for ii in range(Nsize):
            if indxCount[ii]:
                hs0.valList[ii] /= indxCount[ii]
        return hs0

@value
struct IESNAdata:
    var headerlineList: vector[String]
    var LampToLumGeom: Int
    var nPairs: Int
    var angleList: vector[Double]
    var MultFacList: vector[Double]
    var nLamps: Int
    var LampLumens: Double
    var CandelaMult: Double
    var nTheta: Int
    var nPhi: Int
    var PhotometricType: Int
    var units: Int
    var LumDimWidth: Double
    var LumDimLength: Double
    var LumDimHeight: Double
    var BallastFactor: Double
    var BallastLampPhotoFactor: Double
    var InputWatts: Double
    var theta: vector[Double]
    var phi: vector[Double]
    var DataArray: vector[vector[Double]]

    def load(inout self, filename: String) -> Int:
        var osstream = OStringStream()
        var infile = ifstream(filename)
        if not infile:
            osstream << "Error: Can't open infile: \"" << filename << "\"\n"
            writewndo(osstream.str(), "e")
            return 0
        var inlinestr: String
        var argList: vector[String]
        while True:
            getline(infile, inlinestr)
            self.headerlineList.push_back(inlinestr)
            argList = vParseList(inlinestr, "=")
            if argList.size() == 0:
                continue
            if argList[0] == "TILT":
                if argList[1] == "INCLUDE":
                    infile >> self.LampToLumGeom
                    infile >> self.nPairs
                    self.angleList.resize(self.nPairs)
                    for iang in range(self.nPairs):
                        infile >> self.angleList[iang]
                    self.MultFacList.resize(self.nPairs)
                    for imf in range(self.nPairs):
                        infile >> self.MultFacList[imf]
                elif argList[1] == "NONE":
                    break
                else:
                    break
        infile >> self.nLamps >> self.LampLumens >> self.CandelaMult
        infile >> self.nTheta >> self.nPhi
        infile >> self.PhotometricType >> self.units
        infile >> self.LumDimWidth >> self.LumDimLength >> self.LumDimHeight
        infile >> self.BallastFactor >> self.BallastLampPhotoFactor >> self.InputWatts
        self.theta.resize(self.nTheta)
        for iitheta in range(self.nTheta):
            infile >> self.theta[iitheta]
        self.phi.resize(self.nPhi)
        for iiphi in range(self.nPhi):
            infile >> self.phi[iiphi]
        self.DataArray.resize(self.nTheta)
        for iitheta in range(self.nTheta):
            self.DataArray[iitheta].resize(self.nPhi)
        var ndata: Int = 0
        for iiphi in range(self.nPhi):
            for iitheta in range(self.nTheta):
                infile >> self.DataArray[iitheta][iiphi]
                ndata += 1
        infile.clear()
        infile.close()
        return ndata

    def summary(inout self, inout outfile: OStream):
        for iihdr in range(self.headerlineList.size()):
            outfile << self.headerlineList[iihdr] << "\n"
        outfile << self.nLamps << " " << self.LampLumens << " " << self.CandelaMult << " "
        outfile << self.nTheta << " " << self.nPhi << " "
        outfile << self.PhotometricType << " " << self.units << " "
        outfile << self.LumDimWidth << " " << self.LumDimLength << " " << self.LumDimHeight << "\n"
        outfile << self.BallastFactor << " " << self.BallastLampPhotoFactor << " " << self.InputWatts << "\n"
        for iitheta in range(self.nTheta):
            outfile << self.theta[iitheta] << " "
        outfile << "\n"
        for iiphi in range(self.nPhi):
            outfile << self.phi[iiphi] << " "
        outfile << "\n"

    def dump(inout self, inout outfile: OStream):
        self.summary(outfile)
        for iin1 in range(self.nPhi):
            for iin2 in range(self.nTheta):
                outfile << self.DataArray[iin2][iin1] << " "
            outfile << "\n"

    def convertToHS(inout self) -> HemiSphiral:
        var Nsize: Int = 1 * self.nTheta * self.nPhi
        var hs0 = HemiSphiral(Nsize)
        hs0.summary()
        var nnin: Int
        var nd = vector[nearestdata]()
        var nninsizeMax: Int = 0
        var nninsizeMin: Int = 0
        var nninsizeDist = vector[Int](25, 0)
        var qdataMax: Double = 0.0
        var qdataMin: Double = 0.0
        var qdataSum: Double = 0.0
        var inwgt = vector[Double]()
        var indxCount = vector[Int](Nsize, 0)
        var indxCountDist = vector[Int](100, 0)
        var zCount: Int = 0
        var qdata: Double
        var dir: BGL.vector3
        var iread: Int = 0
        for iin1 in range(self.nTheta):
            for iin2 in range(self.nPhi - 1):
                if iin1 == 0 and iin2 > 0:
                    break
                qdata = self.DataArray[iin1][iin2]
                qdataSum += qdata
                iread += 1
                dir = AnglesToDir3D(DegToRad(self.phi[iin2]), DegToRad(self.theta[iin1]))
                if arcdist(dir, BGL.vector3(0.0, 0.0, 1.0)) < 0.90 * hs0.DA:
                    zCount += 1
                nnin = hs0.nearestc(0.90 * hs0.DA, dir, nd)
                if iread == 1:
                    nninsizeMax = nnin
                    nninsizeMin = nnin
                    qdataMax = qdata
                    qdataMin = qdata
                else:
                    nninsizeMax = max(nninsizeMax, nnin)
                    nninsizeMin = min(nninsizeMin, nnin)
                    qdataMax = max(qdataMax, qdata)
                    qdataMin = min(qdataMin, qdata)
                nninsizeDist[nnin] += 1
                hs0.valList[nd[0].indx] += qdata
                indxCount[nd[0].indx] += 1
        for ii in range(Nsize):
            if indxCount[ii]:
                hs0.valList[ii] /= indxCount[ii]
        return hs0