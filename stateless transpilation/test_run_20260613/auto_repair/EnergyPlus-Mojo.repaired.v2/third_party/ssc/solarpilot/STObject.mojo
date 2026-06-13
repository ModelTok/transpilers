from STObject import ST_OpticalProperties, ST_OpticalPropertySet, ST_Element, ST_Sun, ST_RayData, ST_IntersectionData, ST_Stage, ST_System
from SolarField import SolarField, Hvector, Vect, var_map, htemp_map, var_heliostat, var_receiver, var_ambient
from Heliostat import Heliostat, Reflector, matrix_t, sp_point, PointVect
from Receiver import Receiver
from definitions import *
from stapi import *
from mtrand import *
from Toolbox import Toolbox
from spexception import spexception
from math import sqrt, atan2, asin, cos, sin, acos, pow, exp, log, fabs
from memory import memcpy
from os import FILE
from vector import DynamicVector
from string import String
from utils import unordered_map

@value
struct ST_OpticalProperties:
    var DistributionType: UInt8
    var OpticSurfNumber: Int
    var ApertureStopOrGratingType: Int
    var DiffractionOrder: Int
    var Reflectivity: Float64
    var Transmissivity: Float64
    var RMSSlopeError: Float64
    var RMSSpecError: Float64
    var Grating: StaticFloat64[4]

    def __init__(inout self):
        for i in range(4):
            self.Grating[i] = 0.0
        self.OpticSurfNumber = 1
        self.ApertureStopOrGratingType = 0
        self.DiffractionOrder = 0
        self.Reflectivity = 0.0
        self.Transmissivity = 0.0
        self.RMSSlopeError = 0.0
        self.RMSSpecError = 0.0
        self.DistributionType = 'g'.ord()

    def __copyinit__(inout self, other: ST_OpticalProperties):
        self.DistributionType = other.DistributionType
        self.OpticSurfNumber = other.OpticSurfNumber
        self.ApertureStopOrGratingType = other.ApertureStopOrGratingType
        self.DiffractionOrder = other.DiffractionOrder
        self.Reflectivity = other.Reflectivity
        self.Transmissivity = other.Transmissivity
        self.RMSSlopeError = other.RMSSlopeError
        self.RMSSpecError = other.RMSSpecError
        for i in range(4):
            self.Grating[i] = other.Grating[i]

    def Write(inout self, fdat: FILE):
        if not fdat:
            return
        fdat.printf(
            "OPTICAL\t%c\t"
            "%d\t%d\t%d\t"
            "%lg\t%lg\t%lg\t%lg\t"
            "%lg\t%lg\t"
            "%lg\t%lg\t%lg\t%lg\n",
            self.DistributionType,
            self.ApertureStopOrGratingType, self.OpticSurfNumber, self.DiffractionOrder,
            self.Reflectivity, self.Transmissivity, self.RMSSlopeError, self.RMSSpecError,
            0.0, 0.0,
            self.Grating[0], self.Grating[1], self.Grating[2], self.Grating[3]
        )

@value
struct ST_OpticalPropertySet:
    var Name: String
    var Front: ST_OpticalProperties
    var Back: ST_OpticalProperties

    def __init__(inout self):
        self.Name = String("")
        self.Front = ST_OpticalProperties()
        self.Back = ST_OpticalProperties()

    def Write(inout self, fdat: FILE):
        if not fdat:
            return
        fdat.printf("OPTICAL PAIR\t%s\n", self.Name)
        self.Front.Write(fdat)
        self.Back.Write(fdat)

@value
struct ST_Element:
    var Enabled: Bool
    var Origin: StaticFloat64[3]
    var AimPoint: StaticFloat64[3]
    var ZRot: Float64
    var Euler: StaticFloat64[3]
    var RRefToLoc: StaticFloat64[3][3]
    var RLocToRef: StaticFloat64[3][3]
    var ShapeIndex: UInt8
    var Ap_A: Float64
    var Ap_B: Float64
    var Ap_C: Float64
    var Ap_D: Float64
    var Ap_E: Float64
    var Ap_F: Float64
    var Ap_G: Float64
    var Ap_H: Float64
    var ApertureArea: Float64
    var ZAperture: Float64
    var SurfaceIndex: UInt8
    var Su_A: Float64
    var Su_B: Float64
    var Su_C: Float64
    var Su_D: Float64
    var Su_E: Float64
    var Su_F: Float64
    var Su_G: Float64
    var Su_H: Float64
    var InteractionType: Int
    var Optics: ST_OpticalPropertySet
    var OpticName: String
    var Comment: String

    def __init__(inout self):
        self.Enabled = True
        self.ZRot = 0.0
        self.ShapeIndex = ' '.ord()
        self.Ap_A = 0.0
        self.Ap_B = 0.0
        self.Ap_C = 0.0
        self.Ap_D = 0.0
        self.Ap_E = 0.0
        self.Ap_F = 0.0
        self.Ap_G = 0.0
        self.Ap_H = 0.0
        self.Su_A = 0.0
        self.Su_B = 0.0
        self.Su_C = 0.0
        self.Su_D = 0.0
        self.Su_E = 0.0
        self.Su_F = 0.0
        self.Su_G = 0.0
        self.Su_H = 0.0
        self.ApertureArea = 0.0
        self.SurfaceIndex = ' '.ord()
        self.Comment = String("")
        self.InteractionType = 0
        self.ZAperture = 0.0
        self.Optics = ST_OpticalPropertySet()
        for i in range(3):
            self.Origin[i] = 0.0
            self.AimPoint[i] = 0.0
            self.Euler[i] = 0.0
        for i in range(3):
            for j in range(3):
                self.RRefToLoc[i][j] = 0.0
                self.RLocToRef[i][j] = 0.0

    def Write(inout self, fdat: FILE):
        if not fdat:
            return
        fdat.printf(
            "%d\t"
            "%lg\t%lg\t%lg\t"
            "%lg\t%lg\t%lg\t"
            "%lg\t"
            "%c\t"
            "%lg\t%lg\t%lg\t%lg\t%lg\t%lg\t%lg\t%lg\t"
            "%c\t"
            "%lg\t%lg\t%lg\t%lg\t%lg\t%lg\t%lg\t%lg\t"
            "%s\t"
            "%s\t%d\t"
            "%s\n",
            1 if self.Enabled else 0,
            self.Origin[0], self.Origin[1], self.Origin[2],
            self.AimPoint[0], self.AimPoint[1], self.AimPoint[2],
            self.ZRot,
            self.ShapeIndex,
            self.Ap_A, self.Ap_B, self.Ap_C, self.Ap_D, self.Ap_E, self.Ap_F, self.Ap_G, self.Ap_H,
            self.SurfaceIndex,
            self.Su_A, self.Su_B, self.Su_C, self.Su_D, self.Su_E, self.Su_F, self.Su_G, self.Su_H,
            "",
            self.OpticName, self.InteractionType,
            self.Comment
        )

    def UpdateRotationMatrix(inout self):
        var Alpha: Float64
        var Beta: Float64
        var Gamma: Float64
        var CosAlpha: Float64
        var CosBeta: Float64
        var CosGamma: Float64
        var SinAlpha: Float64
        var SinBeta: Float64
        var SinGamma: Float64
        var dx: Float64 = self.AimPoint[0] - self.Origin[0]
        var dy: Float64 = self.AimPoint[1] - self.Origin[1]
        var dz: Float64 = self.AimPoint[2] - self.Origin[2]
        var dtot: Float64 = sqrt(dx*dx + dy*dy + dz*dz)
        dx /= dtot
        dy /= dtot
        dz /= dtot
        self.Euler[0] = atan2(dx, dz)
        self.Euler[1] = asin(dy)
        self.Euler[2] = self.ZRot * (acos(-1.0) / 180.0)
        Alpha = self.Euler[0]
        Beta = self.Euler[1]
        Gamma = self.Euler[2]
        CosAlpha = cos(Alpha)
        CosBeta = cos(Beta)
        CosGamma = cos(Gamma)
        SinAlpha = sin(Alpha)
        SinBeta = sin(Beta)
        SinGamma = sin(Gamma)
        self.RRefToLoc[0][0] = CosAlpha*CosGamma + SinAlpha*SinBeta*SinGamma
        self.RRefToLoc[0][1] = -CosBeta*SinGamma
        self.RRefToLoc[0][2] = -SinAlpha*CosGamma + CosAlpha*SinBeta*SinGamma
        self.RRefToLoc[1][0] = CosAlpha*SinGamma - SinAlpha*SinBeta*CosGamma
        self.RRefToLoc[1][1] = CosBeta*CosGamma
        self.RRefToLoc[1][2] = -SinAlpha*SinGamma - CosAlpha*SinBeta*CosGamma
        self.RRefToLoc[2][0] = SinAlpha*CosBeta
        self.RRefToLoc[2][1] = SinBeta
        self.RRefToLoc[2][2] = CosAlpha*CosBeta
        st_matrix_transpose(self.RRefToLoc, self.RLocToRef)

@value
struct ST_Sun:
    var ShapeIndex: UInt8
    var Sigma: Float64
    var SunShapeAngle: DynamicVector[Float64]
    var SunShapeIntensity: DynamicVector[Float64]
    var Origin: StaticFloat64[3]

    def __init__(inout self):
        self.Reset()

    def Reset(inout self):
        self.ShapeIndex = ' '.ord()
        self.Sigma = 0.0
        self.SunShapeAngle = DynamicVector[Float64]()
        self.SunShapeIntensity = DynamicVector[Float64]()
        for i in range(3):
            self.Origin[i] = 0.0

    def Write(inout self, fdat: FILE):
        if not fdat:
            return
        fdat.printf("SUN\tPTSRC\t%d\tSHAPE\t%c\tSIGMA\t%lg\tHALFWIDTH\t%lg\n", 0, self.ShapeIndex, self.Sigma, self.Sigma)
        fdat.printf("XYZ\t%lg\t%lg\t%lg\tUSELDH\t%d\tLDH\t%lg\t%lg\t%lg\n", self.Origin[0], self.Origin[1], self.Origin[2], 0, 0.0, 0.0, 0.0)
        if self.ShapeIndex == 'd'.ord():
            var np: Int = self.SunShapeAngle.size
            fdat.printf("USER SHAPE DATA\t%d\n", np)
            for i in range(np):
                fdat.printf("%lg\t%lg\n", self.SunShapeAngle[i], self.SunShapeIntensity[i])
        else:
            fdat.printf("USER SHAPE DATA\t%d\n", 0)

@value
struct ST_RayData:
    var m_blockList: DynamicVector[Pointer[block_t]]
    var m_dataCount: UInt32
    var m_dataCapacity: UInt32

    @value
    struct ray_t:
        var pos: StaticFloat64[3]
        var cos: StaticFloat64[3]
        var element: Int
        var stage: Int
        var raynum: UInt32

    @value
    struct block_t:
        var data: StaticArray[ray_t, 16384]
        var count: UInt32

    def __init__(inout self):
        self.m_dataCount = 0
        self.m_dataCapacity = 0
        self.m_blockList = DynamicVector[Pointer[block_t]]()

    def __del__(owned self):
        self.Clear()

    def Append(inout self, pos: StaticFloat64[3], cos: StaticFloat64[3], element: Int, stage: Int, raynum: UInt32) -> Pointer[ray_t]:
        if self.m_dataCount == self.m_dataCapacity:
            var b: Pointer[block_t] = Pointer[block_t].alloc(1)
            b[].count = 0
            self.m_blockList.push_back(b)
            self.m_dataCapacity += 16384
        var r: Pointer[ray_t] = self.Index(self.m_dataCount, True)
        if r:
            memcpy(r[].pos.unsafe_ptr(), pos.unsafe_ptr(), sizeof[Float64]() * 3)
            memcpy(r[].cos.unsafe_ptr(), cos.unsafe_ptr(), sizeof[Float64]() * 3)
            r[].element = element
            r[].stage = stage
            r[].raynum = raynum
            self.m_dataCount += 1
            return r
        else:
            return Pointer[ray_t]()

    def Overwrite(inout self, idx: UInt32, pos: StaticFloat64[3], cos: StaticFloat64[3], element: Int, stage: Int, raynum: UInt32) -> Bool:
        var r: Pointer[ray_t] = self.Index(idx, True)
        if r:
            memcpy(r[].pos.unsafe_ptr(), pos.unsafe_ptr(), sizeof[Float64]() * 3)
            memcpy(r[].cos.unsafe_ptr(), cos.unsafe_ptr(), sizeof[Float64]() * 3)
            r[].element = element
            r[].stage = stage
            r[].raynum = raynum
            return True
        else:
            return False

    def Query(inout self, idx: UInt32, pos: Pointer[Float64], cos: Pointer[Float64], element: Pointer[Int], stage: Pointer[Int], raynum: Pointer[UInt32]) -> Bool:
        var r: Pointer[ray_t] = self.Index(idx, False)
        if r:
            if pos:
                memcpy(pos, r[].pos.unsafe_ptr(), sizeof[Float64]() * 3)
            if cos:
                memcpy(cos, r[].cos.unsafe_ptr(), sizeof[Float64]() * 3)
            if element:
                element[] = r[].element
            if stage:
                stage[] = r[].stage
            if raynum:
                raynum[] = r[].raynum
            return True
        else:
            return False

    def Merge(inout self, inout src: ST_RayData):
        var list: DynamicVector[Pointer[block_t]] = DynamicVector[Pointer[block_t]]()
        var partial_blocks: DynamicVector[Pointer[block_t]] = DynamicVector[Pointer[block_t]]()
        list.reserve(self.m_blockList.size + src.m_blockList.size)
        for i in range(self.m_blockList.size):
            if self.m_blockList[i][].count == 16384:
                list.push_back(self.m_blockList[i])
            else:
                partial_blocks.push_back(self.m_blockList[i])
        for i in range(src.m_blockList.size):
            if src.m_blockList[i][].count == 16384:
                list.push_back(src.m_blockList[i])
            else:
                partial_blocks.push_back(src.m_blockList[i])
        src.m_blockList.clear()
        src.m_dataCount = 0
        src.m_dataCapacity = 0
        self.m_blockList = list
        self.m_dataCapacity = self.m_blockList.size * 16384
        self.m_dataCount = self.m_dataCapacity
        for i in range(partial_blocks.size):
            var b: Pointer[block_t] = partial_blocks[i]
            for j in range(b[].count):
                var r: ray_t = b[].data[j]
                self.Append(r.pos, r.cos, r.element, r.stage, r.raynum)
            del b
        partial_blocks.clear()

    def Clear(inout self):
        for i in range(self.m_blockList.size):
            del self.m_blockList[i]
        self.m_blockList.clear()
        self.m_dataCount = 0
        self.m_dataCapacity = 0

    def Count(inout self) -> UInt32:
        return self.m_dataCount

    def Index(inout self, i: UInt32, write_access: Bool) -> Pointer[ray_t]:
        if i >= self.m_dataCapacity:
            return Pointer[ray_t]()
        var block_num: UInt32 = i / 16384
        var block_idx: UInt32 = i % 16384
        if block_num >= self.m_blockList.size or block_idx >= 16384:
            return Pointer[ray_t]()
        var b: Pointer[block_t] = self.m_blockList[block_num]
        if write_access and block_idx >= b[].count:
            b[].count = block_idx + 1
        if not write_access and block_idx >= b[].count:
            return Pointer[ray_t]()
        return b[].data.unsafe_ptr() + block_idx

    def Print(inout self):
        printf("[ blocks: %d count: %u capacity: %u ]\n",
            self.m_blockList.size,
            self.m_dataCount,
            self.m_dataCapacity)
        var n: UInt32 = self.Count()
        for i in range(n):
            var pos: StaticFloat64[3]
            var cos: StaticFloat64[3]
            var elm: Int
            var stage: Int
            var ray: UInt32
            if self.Query(i, pos.unsafe_ptr(), cos.unsafe_ptr(), elm.unsafe_ptr(), stage.unsafe_ptr(), ray.unsafe_ptr()):
                printf("   [%u] = { [%lg,%lg,%lg][%lg,%lg,%lg] %d %d %u }\n", i,
                    pos[0], pos[1], pos[2],
                    cos[0], cos[1], cos[2],
                    elm, stage, ray)
        printf("\n")

@value
struct ST_IntersectionData:
    var hitx: Pointer[Float64]
    var hity: Pointer[Float64]
    var hitz: Pointer[Float64]
    var cosx: Pointer[Float64]
    var cosy: Pointer[Float64]
    var cosz: Pointer[Float64]
    var emap: Pointer[Int]
    var smap: Pointer[Int]
    var rnum: Pointer[Int]
    var nint: Int
    var nsunrays: Int
    var q_ray: Float64
    var bounds: StaticFloat64[5]

    def __init__(inout self):
        self.hitx = Pointer[Float64]()
        self.hity = Pointer[Float64]()
        self.hitz = Pointer[Float64]()
        self.cosx = Pointer[Float64]()
        self.cosy = Pointer[Float64]()
        self.cosz = Pointer[Float64]()
        self.emap = Pointer[Int]()
        self.smap = Pointer[Int]()
        self.rnum = Pointer[Int]()
        self.nint = 0
        self.nsunrays = 0
        self.q_ray = 0.0
        for i in range(5):
            self.bounds[i] = 0.0

    def __del__(owned self):
        self.DeallocateArrays()

    def AllocateArrays(inout self, size: Int):
        try:
            self.hitx = Pointer[Float64].alloc(size)
            self.hity = Pointer[Float64].alloc(size)
            self.hitz = Pointer[Float64].alloc(size)
            self.cosx = Pointer[Float64].alloc(size)
            self.cosy = Pointer[Float64].alloc(size)
            self.cosz = Pointer[Float64].alloc(size)
            self.emap = Pointer[Int].alloc(size)
            self.smap = Pointer[Int].alloc(size)
            self.rnum = Pointer[Int].alloc(size)
            self.nint = size
        except:
            raise spexception("Memory allocation error encountered when sizing arrays for SolTrace intersection data. Contact support.")

    def DeallocateArrays(inout self):
        try:
            if self.hitx:
                del self.hitx
            if self.hity:
                del self.hity
            if self.hitz:
                del self.hitz
            if self.cosx:
                del self.cosx
            if self.cosy:
                del self.cosy
            if self.cosz:
                del self.cosz
            if self.emap:
                del self.emap
            if self.smap:
                del self.smap
            if self.rnum:
                del self.rnum
        except:
            raise spexception("Memory deallocation error encountered when destroying arrays for SolTrace intersection data. Contact support.")

@value
struct ST_Stage:
    var MultiHitsPerRay: Bool
    var Virtual: Bool
    var TraceThrough: Bool
    var Origin: StaticFloat64[3]
    var AimPoint: StaticFloat64[3]
    var ZRot: Float64
    var ElementList: DynamicVector[ST_Element]
    var Euler: StaticFloat64[3]
    var RRefToLoc: StaticFloat64[3][3]
    var RLocToRef: StaticFloat64[3][3]
    var Name: String

    def __init__(inout self):
        for i in range(3):
            self.Origin[i] = 0.0
            self.AimPoint[i] = 0.0
            self.Euler[i] = 0.0
        for i in range(3):
            for j in range(3):
                self.RRefToLoc[i][j] = 0.0
                self.RLocToRef[i][j] = 0.0
        self.ZRot = 0.0
        self.MultiHitsPerRay = True
        self.Virtual = False
        self.TraceThrough = False
        self.Name = String("")
        self.ElementList = DynamicVector[ST_Element]()

    def __del__(owned self):
        self.ElementList.clear()

    def Write(inout self, fdat: FILE):
        if not fdat:
            return
        fdat.printf(
            "STAGE\tXYZ\t%lg\t%lg\t%lg\tAIM\t%lg\t%lg\t%lg\tZROT\t%lg\tVIRTUAL\t%d\t"
            "MULTIHIT\t%d\tELEMENTS\t%d\tTRACETHROUGH\t%d\n",
            self.Origin[0], self.Origin[1], self.Origin[2],
            self.AimPoint[0], self.AimPoint[1], self.AimPoint[2],
            self.ZRot,
            1 if self.Virtual else 0,
            1 if self.MultiHitsPerRay else 0,
            self.ElementList.size,
            1 if self.TraceThrough else 0)
        fdat.printf("%s\n", self.Name)
        for i in range(self.ElementList.size):
            self.ElementList[i].Write(fdat)

@value
struct ST_System:
    var Sun: ST_Sun
    var OpticsList: DynamicVector[ST_OpticalPropertySet]
    var StageList: DynamicVector[ST_Stage]
    var sim_raycount: Int
    var sim_raymax: Int
    var sim_errors_sunshape: Bool
    var sim_errors_optical: Bool
    var AllRayData: ST_RayData
    var SunRayCount: UInt32
    var IntData: ST_IntersectionData

    def __init__(inout self):
        self.Sun = ST_Sun()
        self.SunRayCount = 0
        self.sim_raycount = 1000
        self.sim_raymax = 100000
        self.sim_errors_sunshape = True
        self.sim_errors_optical = True
        self.OpticsList = DynamicVector[ST_OpticalPropertySet]()
        self.StageList = DynamicVector[ST_Stage]()
        self.AllRayData = ST_RayData()
        self.IntData = ST_IntersectionData()

    def __del__(owned self):
        self.StageList.clear()
        self.OpticsList.clear()

    def Write(inout self, fdat: FILE):
        if not fdat:
            return
        self.Sun.Write(fdat)
        fdat.printf("OPTICS LIST COUNT\t%d\n", self.OpticsList.size)
        for i in range(self.OpticsList.size):
            self.OpticsList[i].Write(fdat)
        fdat.printf("STAGE LIST COUNT\t%d\n", self.StageList.size)
        for i in range(self.StageList.size):
            self.StageList[i].Write(fdat)

    def ClearAll(inout self):
        self.OpticsList.clear()
        self.StageList.clear()

    def CreateSTSystem(inout self, inout SF: SolarField, inout helios: Hvector, inout sunvect: Vect) -> Bool:
        if self.StageList.size != 0:
            self.ClearAll()
        for i in range(2):
            self.StageList.push_back(ST_Stage())
        var V: var_map = SF.getVarMap()
        var sun_type: Int = V.amb.sun_type.mapval()
        var sigma: Float64 = V.amb.sun_rad_limit.val
        var shape: UInt8 = 'i'.ord()
        if sun_type == 2:
            shape = 'p'.ord()
        elif sun_type == 0:
            shape = 'g'.ord()
        elif sun_type == 4:
            shape = 'g'.ord()
        elif sun_type == 1:
            shape = 'd'.ord()
            var np: Int = 26
            var R: Float64 = 4.65e-3
            var dr: Float64 = R / Float64(np - 1)
            var angle: Pointer[Float64] = Pointer[Float64].alloc(np)
            var intens: Pointer[Float64] = Pointer[Float64].alloc(np)
            for i in range(np):
                angle[i] = dr * Float64(i)
                intens[i] = 1.0 - 0.5138 * pow(angle[i] / R, 4)
                angle[i] *= 1000.0
            intens[np - 1] = 0.0
            self.Sun.SunShapeIntensity = DynamicVector[Float64](np)
            self.Sun.SunShapeAngle = DynamicVector[Float64](np)
            for i in range(np):
                self.Sun.SunShapeIntensity[i] = intens[i]
                self.Sun.SunShapeAngle[i] = angle[i]
            del angle
            del intens
        elif sun_type == 5:
            shape = 'd'.ord()
            var kappa: Float64
            var gamma: Float64
            var theta: Float64
            var chi: Float64
            chi = V.amb.sun_csr.val
            kappa = 0.9 * log(13.5 * chi) * pow(chi, -0.3)
            gamma = 2.2 * log(0.52 * chi) * pow(chi, 0.43) - 0.1
            var np: Int = 50
            var angle: Pointer[Float64] = Pointer[Float64].alloc(np)
            var intens: Pointer[Float64] = Pointer[Float64].alloc(np)
            for i in range(np):
                theta = Float64(i) * 25.0 / Float64(np)
                angle[i] = theta
                if theta > 4.65:
                    intens[i] = exp(kappa) * pow(theta, gamma)
                else:
                    intens[i] = cos(0.326 * theta) / cos(0.308 * theta)
            self.Sun.SunShapeIntensity = DynamicVector[Float64](np)
            self.Sun.SunShapeAngle = DynamicVector[Float64](np)
            for i in range(np):
                self.Sun.SunShapeIntensity[i] = intens[i]
                self.Sun.SunShapeAngle[i] = angle[i]
            del angle
            del intens
        elif sun_type == 3:
            shape = 'd'.ord()
            var np: Int = V.amb.user_sun.val.nrows()
            var angle: Pointer[Float64] = Pointer[Float64].alloc(np)
            var intens: Pointer[Float64] = Pointer[Float64].alloc(np)
            for i in range(np):
                angle[i] = V.amb.user_sun.val.at(i, 0)
                intens[i] = V.amb.user_sun.val.at(i, 1)
            self.Sun.SunShapeIntensity = DynamicVector[Float64](np)
            self.Sun.SunShapeAngle = DynamicVector[Float64](np)
            for i in range(np):
                self.Sun.SunShapeIntensity[i] = intens[i]
                self.Sun.SunShapeAngle[i] = angle[i]
            del angle
            del intens
        else:
            return False
        self.Sun.ShapeIndex = shape
        self.Sun.Sigma = sigma
        self.Sun.Origin[0] = sunvect.i * 1.e4
        self.Sun.Origin[1] = sunvect.j * 1.e4
        self.Sun.Origin[2] = sunvect.k * 1.e4
        var nhtemp: Int
        if self.OpticsList.size > 0:
            return False
        else:
            nhtemp = SF.getHeliostatTemplates().size
            for i in range(nhtemp):
                self.OpticsList.push_back(ST_OpticalPropertySet())
        var optics_map: unordered_map[String, ST_OpticalPropertySet] = unordered_map[String, ST_OpticalPropertySet]()
        var ii: Int = 0
        var it: htemp_map.Iterator = SF.getHeliostatTemplates().begin()
        while it != SF.getHeliostatTemplates().end():
            var H: Heliostat = it[].second
            self.OpticsList[ii].Name = H.getHeliostatName()
            optics_map[self.OpticsList[ii].Name] = self.OpticsList[ii]
            var refl: Float64 = H.getTotalReflectivity()
            var Hv: var_heliostat = H.getVarMap()
            refl *= Hv.reflect_ratio.val
            var errang: StaticFloat64[2]
            var errsurf: StaticFloat64[2]
            var errrefl: StaticFloat64[2]
            errang[0] = Hv.err_azimuth.val
            errang[1] = Hv.err_elevation.val
            errsurf[0] = Hv.err_surface_x.val
            errsurf[1] = Hv.err_surface_y.val
            errrefl[0] = Hv.err_reflect_x.val
            errrefl[1] = Hv.err_reflect_y.val
            var errnorm: Float64 = sqrt(errang[0]*errang[0] + errang[1]*errang[1] + errsurf[0]*errsurf[0] + errsurf[1]*errsurf[1]) * 1000.0
            var errsurface: Float64 = sqrt(errrefl[0]*errrefl[0] + errrefl[1]*errrefl[1]) * 1000.0
            errnorm *= 1.0 / sqrt(2.0)
            errsurface *= 1.0 / sqrt(2.0)
            var st_err_type_val: Int = Hv.st_err_type.mapval()
            if st_err_type_val == var_heliostat.ST_ERR_TYPE.GAUSSIAN:
                self.OpticsList[ii].Front.DistributionType = 'g'.ord()
            elif st_err_type_val == var_heliostat.ST_ERR_TYPE.PILLBOX:
                self.OpticsList[ii].Front.DistributionType = 'p'.ord()
            else:
                self.OpticsList[ii].Front.DistributionType = 'g'.ord()
            self.OpticsList[ii].Front.OpticSurfNumber = 0
            self.OpticsList[ii].Front.ApertureStopOrGratingType = 0
            self.OpticsList[ii].Front.DiffractionOrder = 0
            self.OpticsList[ii].Front.Reflectivity = refl
            self.OpticsList[ii].Front.Transmissivity = 0.0
            for j in range(4):
                self.OpticsList[ii].Front.Grating[j] = 0.0
            self.OpticsList[ii].Front.RMSSlopeError = errnorm
            self.OpticsList[ii].Front.RMSSpecError = errsurface
            self.OpticsList[ii].Back.DistributionType = 'g'.ord()
            self.OpticsList[ii].Back.OpticSurfNumber = 0
            self.OpticsList[ii].Back.ApertureStopOrGratingType = 0
            self.OpticsList[ii].Back.DiffractionOrder = 0
            self.OpticsList[ii].Back.Reflectivity = 0.0
            self.OpticsList[ii].Back.Transmissivity = 0.0
            for j in range(4):
                self.OpticsList[ii].Back.Grating[j] = 0.0
            self.OpticsList[ii].Back.RMSSlopeError = 100.0
            self.OpticsList[ii].Back.RMSSpecError = 0.0
            ii += 1
            it.next()
        var h_stage: ST_Stage = self.StageList[0]
        h_stage.Origin[0] = 0.0
        h_stage.Origin[1] = 0.0
        h_stage.Origin[2] = 0.0
        h_stage.AimPoint[0] = 0.0
        h_stage.AimPoint[1] = 0.0
        h_stage.AimPoint[2] = 1.0
        h_stage.ZRot = 0.0
        h_stage.MultiHitsPerRay = True
        h_stage.Virtual = False
        h_stage.TraceThrough = False
        h_stage.Name = "Heliostat field"
        var nh: Int = helios.size
        if h_stage.ElementList.size != 0:
            return False
        try:
            var hv: var_heliostat = helios.front().getVarMap()
            h_stage.ElementList.reserve(nh * (1 if hv.is_faceted.val else 1))
        except:
            return False
        var Ahtot: Float64 = 0.0
        for i in range(nh):
            var H: Heliostat = helios[i]
            var Hv: var_heliostat = H.getVarMap()
            Ahtot += H.getArea()
            var panels: matrix_t[Reflector] = H.getPanels()
            var isdetail: Bool = Hv.is_faceted.val
            var ncantx: Int = panels.ncols() if isdetail else 1
            var ncantx_int: Int = ncantx
            var ncanty: Int = panels.nrows() if isdetail else 1
            var ncanty_int: Int = ncanty
            var npanels: Int = ncantx_int * ncanty_int
            var enabled: Bool = H.IsInLayout()
            var P: sp_point = H.getLocation()
            var V: Vect = H.getTrackVector()
            var zrot: Float64 = R2D * Toolbox.ZRotationTransform(V)
            var shape: UInt8 = 'c'.ord() if Hv.is_round.mapval() == var_heliostat.IS_ROUND.ROUND else 'r'.ord()
            var opticname: String = H.getHeliostatName()
            for j in range(ncantx_int):
                for k in range(ncanty_int):
                    h_stage.ElementList.push_back(ST_Element())
                    var element: ST_Element = h_stage.ElementList.back()
                    element.Enabled = enabled
                    if isdetail:
                        var F: PointVect = panels.at(k, j).getOrientation()
                        var Floc: sp_point = F.point()
                        var Faim: Vect = F.vect()
                        Toolbox.unitvect(Faim)
                        Toolbox.rotation(H.getZenithTrack(), 0, Floc)
                        Toolbox.rotation(H.getZenithTrack(), 0, Faim)
                        Toolbox.rotation(H.getAzimuthTrack(), 2, Floc)
                        Toolbox.rotation(H.getAzimuthTrack(), 2, Faim)
                        element.Origin[0] = P.x + Floc.x
                        element.Origin[1] = P.y + Floc.y
                        element.Origin[2] = P.z + Floc.z
                        element.AimPoint[0] = element.Origin[0] + Faim.i * 1000.0
                        element.AimPoint[1] = element.Origin[1] + Faim.j * 1000.0
                        element.AimPoint[2] = element.Origin[2] + Faim.k * 1000.0
                    else:
                        element.Origin[0] = P.x
                        element.Origin[1] = P.y
                        element.Origin[2] = P.z
                        element.AimPoint[0] = P.x + V.i * 1000.0
                        element.AimPoint[1] = P.y + V.j * 1000.0
                        element.AimPoint[2] = P.z + V.k * 1000.0
                    element.ZRot = zrot
                    element.ShapeIndex = shape
                    if Hv.is_round.mapval() == var_heliostat.IS_ROUND.ROUND:
                        element.Ap_A = Hv.width.val
                    else:
                        if isdetail:
                            element.Ap_A = panels.at(k, j).getWidth()
                            element.Ap_B = panels.at(k, j).getHeight()
                        else:
                            element.Ap_A = Hv.width.val
                            element.Ap_B = Hv.height.val
                    if Hv.focus_method.mapval() == var_heliostat.FOCUS_METHOD.FLAT:
                        element.SurfaceIndex = 'f'.ord()
                    else:
                        element.Su_A = 0.5 / H.getFocalX()
                        element.Su_B = 0.5 / H.getFocalY()
                        element.SurfaceIndex = 'p'.ord()
                    element.InteractionType = 2
                    element.OpticName = opticname
                    element.Optics = optics_map[opticname]
        var r_stage: ST_Stage = self.StageList[1]
        r_stage.Origin[0] = 0.0
        r_stage.Origin[1] = 0.0
        r_stage.Origin[2] = 0.0
        r_stage.AimPoint[0] = 0.0
        r_stage.AimPoint[1] = 0.0
        r_stage.AimPoint[2] = 1.0
        r_stage.ZRot = 0.0
        r_stage.Virtual = False
        r_stage.MultiHitsPerRay = True
        r_stage.TraceThrough = False
        r_stage.Name = "Receiver"
        var recs: DynamicVector[Receiver] = SF.getReceivers()
        var nrecs: Int = recs.size
        var rstage_map: unordered_map[Int, Receiver] = unordered_map[Int, Receiver]()
        if r_stage.ElementList.size > 0:
            return False
        for i in range(nrecs):
            r_stage.ElementList.push_back(ST_Element())
        for i in range(nrecs):
            var rec: Receiver = recs[i]
            var rv: var_receiver = rec.getVarMap()
            if not rec.isReceiverEnabled():
                continue
            rstage_map[i] = rec
            var recgeom: Int = rec.getGeometryType()
            self.OpticsList.push_back(ST_OpticalPropertySet())
            var copt: ST_OpticalPropertySet = self.OpticsList[self.OpticsList.size - 1]
            if recgeom == Receiver.REC_GEOM_TYPE.CYLINDRICAL_CLOSED:
                copt.Name = rv.rec_name.val
                copt.Front.DistributionType = 'g'.ord()
                copt.Front.OpticSurfNumber = 0
                copt.Front.ApertureStopOrGratingType = 0
                copt.Front.Reflectivity = 1.0 - rv.absorptance.val
                copt.Front.RMSSlopeError = 100.0
                copt.Front.RMSSpecError = 100.0
                copt.Back.DistributionType = 'g'.ord()
                copt.Back.OpticSurfNumber = 0
                copt.Back.ApertureStopOrGratingType = 0
                copt.Back.Reflectivity = 1.0 - rv.absorptance.val
                copt.Back.RMSSlopeError = 100.0
                copt.Back.RMSSpecError = 100.0
                var diam: Float64 = rv.rec_diameter.val
                var pos: sp_point
                var aim: Vect
                var element: ST_Element = r_stage.ElementList[i]
                element.Enabled = True
                pos.x = rv.rec_offset_x.val
                pos.y = rv.rec_offset_y.val - diam / 2.0
                pos.z = rv.optical_height.Val()
                element.Origin[0] = pos.x
                element.Origin[1] = pos.y
                element.Origin[2] = pos.z
                var az: Float64 = rv.rec_azimuth.val * D2R
                var el: Float64 = rv.rec_elevation.val * D2R
                aim.i = cos(el) * sin(az)
                aim.j = cos(el) * cos(az)
                aim.k = sin(el)
                element.AimPoint[0] = pos.x + aim.i * 1000.0
                element.AimPoint[1] = pos.y + aim.j * 1000.0
                element.AimPoint[2] = pos.z + aim.k * 1000.0
                element.ZRot = 0.0
                element.Ap_C = rv.rec_height.val
                element.ShapeIndex = 'l'.ord()
                element.SurfaceIndex = 't'.ord()
                element.Su_A = 2.0 / diam
                element.InteractionType = 2
                element.OpticName = rv.rec_name.val
                element.Optics = copt
                self.OpticsList.push_back(ST_OpticalPropertySet())
                copt = self.OpticsList.back()
                copt.Name = rv.rec_name.val + " spill"
                copt.Front.DistributionType = 'g'.ord()
                copt.Front.OpticSurfNumber = 0
                copt.Front.ApertureStopOrGratingType = 0
                copt.Front.Reflectivity = 0.0
                copt.Front.RMSSlopeError = 100.0
                copt.Front.RMSSpecError = 100.0
                copt.Back.DistributionType = 'g'.ord()
                copt.Back.OpticSurfNumber = 0
                copt.Back.ApertureStopOrGratingType = 0
                copt.Back.Reflectivity = 0.0
                copt.Back.RMSSlopeError = 100.0
                copt.Back.RMSSpecError = 100.0
                r_stage.ElementList.push_back(ST_Element())
                element = r_stage.ElementList.back()
                element.Enabled = True
                pos.x = rv.rec_offset_x.val
                pos.y = rv.rec_offset_y.val
                pos.z = rv.optical_height.Val() - rv.rec_height.val / 2.0
                element.Origin[0] = pos.x
                element.Origin[1] = pos.y
                element.Origin[2] = pos.z
                az = rv.rec_azimuth.val * D2R
                el = rv.rec_elevation.val * D2R
                aim.i = sin(el) * cos(az)
                aim.j = sin(el) * sin(az)
                aim.k = cos(el)
                element.AimPoint[0] = pos.x + aim.i * 1000.0
                element.AimPoint[1] = pos.y + aim.j * 1000.0
                element.AimPoint[2] = pos.z + aim.k * 1000.0
                element.ZRot = 0.0
                element.Ap_A = rv.rec_diameter.val
                element.ShapeIndex = 'c'.ord()
                element.SurfaceIndex = 'f'.ord()
                element.InteractionType = 2
                element.OpticName = rv.rec_name.val + " spill"
                element.Optics = copt
            elif recgeom == Receiver.REC_GEOM_TYPE.CYLINDRICAL_OPEN:

            elif recgeom == Receiver.REC_GEOM_TYPE.CYLINDRICAL_CAV:

            elif recgeom == Receiver.REC_GEOM_TYPE.PLANE_RECT:
                var width: Float64 = rv.rec_width.val
                var height: Float64 = rv.rec_height.val
                var is_ellipse: Bool = recgeom == 4
                if is_ellipse and fabs(width - height) > 1.e-4:
                    return False
                copt.Name = rv.rec_name.val
                copt.Front.DistributionType = 'g'.ord()
                copt.Front.OpticSurfNumber = 0
                copt.Front.ApertureStopOrGratingType = 0
                copt.Front.Reflectivity = 1.0 - rv.absorptance.val
                copt.Front.RMSSlopeError = PI / 4.0
                copt.Front.RMSSpecError = PI / 4.0
                copt.Back.DistributionType = 'g'.ord()
                copt.Back.OpticSurfNumber = 0
                copt.Back.ApertureStopOrGratingType = 0
                copt.Back.Reflectivity = 1.0 - rv.absorptance.val
                copt.Back.RMSSlopeError = PI / 4.0
                copt.Back.RMSSpecError = PI / 4.0
                var pos: sp_point
                var aim: Vect
                var element: ST_Element = r_stage.ElementList[i]
                element.Enabled = True
                pos.x = rv.rec_offset_x.val
                pos.y = rv.rec_offset_y.val
                pos.z = rv.optical_height.Val()
                element.Origin[0] = pos.x
                element.Origin[1] = pos.y
                element.Origin[2] = pos.z
                var az: Float64 = rv.rec_azimuth.val * D2R
                var el: Float64 = rv.rec_elevation.val * D2R
                aim.Set(cos(el)*sin(az), cos(el)*cos(az), sin(el))
                element.AimPoint[0] = pos.x + aim.i * 1000.0
                element.AimPoint[1] = pos.y + aim.j * 1000.0
                element.AimPoint[2] = pos.z + aim.k * 1000.0
                element.ZRot = R2D * Toolbox.ZRotationTransform(aim)
                element.Ap_A = width
                element.Ap_B = 0.0 if is_ellipse else height
                element.ShapeIndex = 'c'.ord() if is_ellipse else 'r'.ord()
                element.SurfaceIndex = 'f'.ord()
                element.InteractionType = 2
                element.OpticName = rv.rec_name.val
                element.Optics = copt
            elif recgeom == Receiver.REC_GEOM_TYPE.PLANE_ELLIPSE or recgeom == Receiver.REC_GEOM_TYPE.POLYGON_CLOSED or recgeom == Receiver.REC_GEOM_TYPE.POLYGON_OPEN or recgeom == Receiver.REC_GEOM_TYPE.POLYGON_CAV:
                raise spexception("Unsupported receiver type in SolTrace geometry generation algorithm.")
            else:
                raise spexception("Unsupported receiver type in SolTrace geometry generation algorithm.")
        var minrays: Int = V.flux.min_rays.val
        var maxrays: Int = V.flux.max_rays.val
        var seed: Int = V.flux.seed.val
        self.sim_errors_sunshape = V.flux.is_sunshape_err.val and (V.amb.sun_type.mapval() != var_ambient.SUN_TYPE.POINT_SUN)
        self.sim_errors_optical = V.flux.is_optical_err.val
        self.sim_raycount = minrays
        self.sim_raymax = maxrays
        return True

    @staticmethod
    def LoadIntoContext(System: ST_System, spcxt: st_context_t):
        st_sun(spcxt, 0, System.Sun.ShapeIndex, System.Sun.Sigma)
        if System.Sun.ShapeIndex == 'd'.ord():
            var np: Int = System.Sun.SunShapeAngle.size
            var angle: Pointer[Float64] = Pointer[Float64].alloc(np)
            var intens: Pointer[Float64] = Pointer[Float64].alloc(np)
            for i in range(np):
                angle[i] = System.Sun.SunShapeAngle[i]
                intens[i] = System.Sun.SunShapeIntensity[i]
            st_sun_userdata(spcxt, np, angle, intens)
            del angle
            del intens
        st_sun_xyz(spcxt, System.Sun.Origin[0], System.Sun.Origin[1], System.Sun.Origin[2])
        st_clear_optics(spcxt)
        for nopt in range(System.OpticsList.size):
            var idx: Int = st_add_optic(spcxt, System.OpticsList[nopt].Name)
            var f: ST_OpticalProperties = System.OpticsList[nopt].Front
            st_optic(spcxt, idx, 1, f.DistributionType,
                f.OpticSurfNumber, f.ApertureStopOrGratingType, f.DiffractionOrder,
                0.0, 0.0,
                f.Reflectivity, f.Transmissivity,
                f.Grating.unsafe_ptr(), f.RMSSlopeError, f.RMSSpecError, 0, 0, Pointer[Float64](), Pointer[Float64]())
            f = System.OpticsList[nopt].Back
            st_optic(spcxt, idx, 2, f.DistributionType,
                f.OpticSurfNumber, f.ApertureStopOrGratingType, f.DiffractionOrder,
                0.0, 0.0,
                f.Reflectivity, f.Transmissivity,
                f.Grating.unsafe_ptr(), f.RMSSlopeError, f.RMSSpecError, 0, 0, Pointer[Float64](), Pointer[Float64]())
        st_add_stages(spcxt, System.StageList.size)
        for ns in range(System.StageList.size):
            var stage: ST_Stage = System.StageList[ns]
            st_stage_xyz(spcxt, ns, stage.Origin[0], stage.Origin[1], stage.Origin[2])
            st_stage_aim(spcxt, ns, stage.AimPoint[0], stage.AimPoint[1], stage.AimPoint[2])
            st_stage_zrot(spcxt, ns, stage.ZRot)
            st_stage_flags(spcxt, ns, 1 if stage.Virtual else 0, 1 if stage.MultiHitsPerRay else 0, 1 if stage.TraceThrough else 0)
            st_clear_elements(spcxt, ns)
            st_add_elements(spcxt, ns, stage.ElementList.size)
            for idx in range(stage.ElementList.size):
                var e: ST_Element = stage.ElementList[idx]
                st_element_enabled(spcxt, ns, idx, 1 if e.Enabled else 0)
                st_element_xyz(spcxt, ns, idx, e.Origin[0], e.Origin[1], e.Origin[2])
                st_element_aim(spcxt, ns, idx, e.AimPoint[0], e.AimPoint[1], e.AimPoint[2])
                st_element_zrot(spcxt, ns, idx, e.ZRot)
                st_element_aperture(spcxt, ns, idx, e.ShapeIndex)
                var apar: StaticFloat64[8] = StaticFloat64[8](e.Ap_A, e.Ap_B, e.Ap_C, e.Ap_D, e.Ap_E, e.Ap_F, e.Ap_G, e.Ap_H)
                st_element_aperture_params(spcxt, ns, idx, apar.unsafe_ptr())
                st_element_surface(spcxt, ns, idx, e.SurfaceIndex)
                var spar: StaticFloat64[8] = StaticFloat64[8](e.Su_A, e.Su_B, e.Su_C, e.Su_D, e.Su_E, e.Su_F, e.Su_G, e.Su_H)
                st_element_surface_params(spcxt, ns, idx, spar.unsafe_ptr())
                st_element_interaction(spcxt, ns, idx, e.InteractionType)
                st_element_optic(spcxt, ns, idx, e.OpticName)
        st_sim_errors(spcxt, 1 if System.sim_errors_sunshape else 0, 1 if System.sim_errors_optical else 0)