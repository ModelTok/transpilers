// EnergyPlus, Copyright (c) 1996-present, The Board of Trustees of the University of Illinois,
// The Regents of the University of California, through Lawrence Berkeley National Laboratory
// (subject to receipt of any required approvals from the U.S. Dept. of Energy), Oak Ridge
// National Laboratory, managed by UT-Battelle, Alliance for Energy Innovation, LLC, and other
// contributors. All rights reserved.
//
// NOTICE: This Software was developed under funding from the U.S. Department of Energy and the
// U.S. Government consequently retains certain rights. As such, the U.S. Government has been
// granted for itself and others acting on its behalf a paid-up, nonexclusive, irrevocable,
// worldwide license in the Software to reproduce, distribute copies to the public, prepare
// derivative works, and perform publicly and display publicly, and to permit others to do so.
//
// Redistribution and use in source and binary forms, with or without modification, are permitted
// provided that the following conditions are met:
//
// (1) Redistributions of source code must retain the above copyright notice, this list of
//     conditions and the following disclaimer.
//
// (2) Redistributions in binary form must reproduce the above copyright notice, this list of
//     conditions and the following disclaimer in the documentation and/or other materials
//     provided with the distribution.
//
// (3) Neither the name of the University of California, Lawrence Berkeley National Laboratory,
//     the University of Illinois, U.S. Dept. of Energy nor the names of its contributors may be
//     used to endorse or promote products derived from this software without specific prior
//     written permission.
//
// (4) Use of EnergyPlus(TM) Name. If Licensee (i) distributes the software in stand-alone form
//     without changes from the version obtained under this License, or (ii) Licensee makes a
//     reference solely to the software portion of its product, Licensee must refer to the
//     software as "EnergyPlus version X" software, where "X" is the version number Licensee
//     obtained under this License and may not use a different name for the software. Except as
//     specifically required in this Section (4), Licensee shall not use in a company name, a
//     product name, in advertising, publicity, or other promotional activities any name, trade
//     name, trademark, logo, or other designation of "EnergyPlus", "E+", "e+" or confusingly
//     similar designation, without the U.S. Department of Energy's prior written consent.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
// IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
// AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
// CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
// OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

from ObjexxFCL.Array1D import Array1D, Array1D_string, Array1D_int
from ObjexxFCL.Array2D import Array2D
from ObjexxFCL.Vector2 import Vector2
from ObjexxFCL.Vector4 import Vector4
from ObjexxFCL.Vector3 import Vector3
from DataVectorTypes import Vector
from DataBSDFWindow import BSDFWindowDescript
from DataWindowEquivalentLayer import Orientation as WinEqOrientation
from Material import Material, BlindTraAbsRef, VariableAbsCtrlSignal, Group
from ScheduleManager import Schedule as Sched, SchedNum_Invalid
from Shape import ShapeCat
from ConvectionConstants import Convect
from DataGlobals import Constant, EarthRadius, StefanBoltzmann, iHoursInDay, SmallDistance, Kelvin
from DataHeatBalance import DataHeatBalance
from DataEnvironment import DataEnvironment, SetOutBulbTempAt_error
from DataHeatBalSurface import DataHeatBalSurface
from DataLoopNode import DataLoopNodes as DataLoopNode
from DataZoneEquipment import DataZoneEquipment as DataZoneEquip
from Psychrometrics import PsyCpAirFnW, PsyRhoFnTdbW # not used directly but import for completeness
from Construction import ConstructionData as DataConstruction
from UtilityRoutines import ShowFatalError, ShowWarningError
from WindowManager import Window as WindowNS
from ZoneTempPredictorCorrector import ZoneTempPredictorCorrectorData as ZoneTPC
from Data.EnergyPlusData import EnergyPlusData as EPlusData   # maybe not needed?
from Data.EnergyPlusData import EnergyPlusData   # The actual struct
from BaseGlobal import BaseGlobalStruct

module DataSurfaces:

    # Not sure this is the right module for this stuff, may move it later
    enum Compass4:
        Invalid = -1
        North
        East
        South
        West
        Num

    const compass4Names = StaticArray[String, Compass4.Num]("North", "East", "South", "West")

    const Compass4AzimuthLo = StaticArray[Float64, Compass4.Num](315.0, 45.0, 135.0, 225.0)
    const Compass4AzimuthHi = StaticArray[Float64, Compass4.Num](45.0, 135.0, 225.0, 315.0)

    def AzimuthToCompass4(azimuth: Float64) -> Compass4:
        # assert(azimuth >= 0.0 and azimuth < 360.0)
        for c4 in range(Compass4.Num):
            let lo = Compass4AzimuthLo[c4]
            let hi = Compass4AzimuthHi[c4]
            if lo > hi:
                if azimuth >= lo or azimuth < hi:
                    return Compass4(c4)
            else:
                if azimuth >= lo and azimuth < hi:
                    return Compass4(c4)
        # assert(false)
        return Compass4.Invalid

    enum Compass8:
        Invalid = -1
        North
        NorthEast
        East
        SouthEast
        South
        SouthWest
        West
        NorthWest
        Num

    const compass8Names = StaticArray[String, Compass8.Num](
        "North", "Northeast", "East", "Southeast", "South", "Southwest", "West", "Northwest")

    // There is a bug here, the azimuth that divides West from
    // NorthWest is 292.5 not 287.5.  Keeping it like this temporarily
    // to minimize diffs.
    const Compass8AzimuthLo = StaticArray[Float64, Compass8.Num](337.5, 22.5, 67.5, 112.5, 157.5, 202.5, 247.5, 292.5)
    const Compass8AzimuthHi = StaticArray[Float64, Compass8.Num](22.5, 67.5, 112.5, 157.5, 202.5, 247.5, 292.5, 337.5)

    def AzimuthToCompass8(azimuth: Float64) -> Compass8:
        # assert(azimuth >= 0.0 and azimuth < 360.0)
        for c8 in range(Compass8.Num):
            let lo = Compass8AzimuthLo[c8]
            let hi = Compass8AzimuthHi[c8]
            if lo > hi:
                if azimuth >= lo or azimuth < hi:
                    return Compass8(c8)
            else:
                if azimuth >= lo and azimuth < hi:
                    return Compass8(c8)
        # assert(false)
        return Compass8.Invalid

    // Parameters to indicate surface shape for use with the Surface
    // derived type (see below):
    enum SurfaceShape: Int32:
        Invalid = -1
        None
        Triangle
        Quadrilateral
        Rectangle
        RectangularDoorWindow
        RectangularOverhang
        RectangularLeftFin
        RectangularRightFin
        TriangularWindow
        TriangularDoor
        Polygonal
        Num

    enum SurfaceClass: Int32:
        Invalid = -1
        None
        Wall
        Floor
        Roof
        IntMass
        Detached_B
        Detached_F
        Window
        GlassDoor
        Door
        Shading
        Overhang
        Fin
        TDD_Dome
        TDD_Diffuser
        Num

    enum FWC: Int32:
        Invalid = -1
        Floor
        Wall
        Ceiling
        Num

    const iFWC_Floor = Int32(FWC.Floor)
    const iFWC_Wall = Int32(FWC.Wall)
    const iFWC_Ceiling = Int32(FWC.Ceiling)

    enum SurfaceFilter:
        Invalid = -1
        AllExteriorSurfaces
        AllExteriorWindows
        AllExteriorWalls
        AllExteriorRoofs
        AllExteriorFloors
        AllInteriorSurfaces
        AllInteriorWindows
        AllInteriorWalls
        AllInteriorRoofs
        AllInteriorCeilings
        AllInteriorFloors
        Num

    const SurfaceFilterNamesUC = StaticArray[String, SurfaceFilter.Num](
        "ALLEXTERIORSURFACES",
        "ALLEXTERIORWINDOWS",
        "ALLEXTERIORWALLS",
        "ALLEXTERIORROOFS",
        "ALLEXTERIORFLOORS",
        "ALLINTERIORSURFACES",
        "ALLINTERIORWINDOWS",
        "ALLINTERIORWALLS",
        "ALLINTERIORROOFS",
        "ALLINTERIORCEILINGS",
        "ALLINTERIORFLOORS")

    enum WinCover:
        Invalid = -1
        Bare
        Shaded
        Num

    const iWinCover_Bare = Int32(WinCover.Bare)
    const iWinCover_Shaded = Int32(WinCover.Shaded)

    enum WinShadingType:
        Invalid = -1
        NoShade
        ShadeOff
        IntShade
        SwitchableGlazing
        ExtShade
        ExtScreen
        IntBlind
        ExtBlind
        BGShade
        BGBlind
        IntShadeConditionallyOff
        GlassConditionallyLightened
        ExtShadeConditionallyOff
        IntBlindConditionallyOff
        ExtBlindConditionallyOff
        BGShadeConditionallyOff
        BGBlindConditionallyOff
        Num

    enum WindowShadingControlType:
        Invalid = -1
        AlwaysOn
        AlwaysOff
        OnIfScheduled
        HiSolar
        HiHorzSolar
        HiOutAirTemp
        HiZoneAirTemp
        HiZoneCooling
        HiGlare
        MeetDaylIlumSetp
        OnNightLoOutTemp_OffDay
        OnNightLoInTemp_OffDay
        OnNightIfHeating_OffDay
        OnNightLoOutTemp_OnDayCooling
        OnNightIfHeating_OnDayCooling
        OffNight_OnDay_HiSolarWindow
        OnNight_OnDay_HiSolarWindow
        OnHiOutTemp_HiSolarWindow
        OnHiOutTemp_HiHorzSolar
        OnHiZoneTemp_HiSolarWindow
        OnHiZoneTemp_HiHorzSolar
        HiSolar_HiLumin_OffMidNight
        HiSolar_HiLumin_OffSunset
        HiSolar_HiLumin_OffNextMorning
        Num

    enum RefAirTemp:
        Invalid = -1
        ZoneMeanAirTemp
        AdjacentAirTemp
        ZoneSupplyAirTemp
        Num

    const SurfTAirRefReportVals = StaticArray[Int32, DataSurfaces.RefAirTemp.Num](1, 2, 3)

    const ExternalEnvironment = 0
    const Ground = -1
    const OtherSideCoefNoCalcExt = -2
    const OtherSideCoefCalcExt = -3
    const OtherSideCondModeledExt = -4
    const GroundFCfactorMethod = -5
    const KivaFoundation = -6

    # extern Array1D_string const cExtBoundCondition;  // will be defined below

    const UpperLeftCorner = 1
    const LowerLeftCorner = 2
    const LowerRightCorner = 3
    const UpperRightCorner = 4

    const AltAngStepsForSolReflCalc = 10
    const AzimAngStepsForSolReflCalc = 9

    enum HeatTransferModel:
        Invalid = -1
        None
        CTF
        EMPD
        CondFD
        HAMT
        Window5
        ComplexFenestration
        TDD
        Kiva
        AirBoundaryNoHT
        Num

    const HeatTransAlgoStrs = StaticArray[String, DataSurfaces.HeatTransferModel.Num](
        "None",
        "CTF - ConductionTransferFunction",
        "EMPD - MoisturePenetrationDepthConductionTransferFunction",
        "CondFD - ConductionFiniteDifference",
        "HAMT - CombinedHeatAndMoistureFiniteElement",
        "Window5 Detailed Fenestration",
        "Window7 Complex Fenestration",
        "Tubular Daylighting Device",
        "KivaFoundation - TwoDimensionalFiniteDifference",
        "Air Boundary - No Heat Transfer")

    enum Lum:
        Invalid = -1
        Illum
        Back
        Source
        Num

    const iLum_Illum = Int32(Lum.Illum)
    const iLum_Back = Int32(Lum.Back)
    const iLum_Source = Int32(Lum.Source)

    def NOT_SHADED(ShadingFlag: WinShadingType) -> Bool:
        return (ShadingFlag == WinShadingType.NoShade or ShadingFlag == WinShadingType.ShadeOff)

    def IS_SHADED(ShadingFlag: WinShadingType) -> Bool:
        return !NOT_SHADED(ShadingFlag)

    def IS_SHADED_NO_GLARE_CTRL(ShadingFlag: WinShadingType) -> Bool:
        return (ShadingFlag == WinShadingType.IntShade or ShadingFlag == WinShadingType.SwitchableGlazing or
                ShadingFlag == WinShadingType.ExtShade or ShadingFlag == WinShadingType.ExtScreen or ShadingFlag == WinShadingType.IntBlind or
                ShadingFlag == WinShadingType.ExtBlind or ShadingFlag == WinShadingType.BGShade or ShadingFlag == WinShadingType.BGBlind)

    def ANY_SHADE(ShadingFlag: WinShadingType) -> Bool:
        return (ShadingFlag == WinShadingType.IntShade or ShadingFlag == WinShadingType.ExtShade or ShadingFlag == WinShadingType.BGShade)

    def ANY_SHADE_SCREEN(ShadingFlag: WinShadingType) -> Bool:
        return (ShadingFlag == WinShadingType.IntShade or ShadingFlag == WinShadingType.ExtShade or ShadingFlag == WinShadingType.BGShade or
                ShadingFlag == WinShadingType.ExtScreen)

    def ANY_BLIND(ShadingFlag: WinShadingType) -> Bool:
        return (ShadingFlag == WinShadingType.IntBlind or ShadingFlag == WinShadingType.ExtBlind or ShadingFlag == WinShadingType.BGBlind)

    def ANY_INTERIOR_SHADE_BLIND(ShadingFlag: WinShadingType) -> Bool:
        return (ShadingFlag == WinShadingType.IntShade or ShadingFlag == WinShadingType.IntBlind)

    def ANY_EXTERIOR_SHADE_BLIND_SCREEN(ShadingFlag: WinShadingType) -> Bool:
        return (ShadingFlag == WinShadingType.ExtShade or ShadingFlag == WinShadingType.ExtBlind or ShadingFlag == WinShadingType.ExtScreen)

    def ANY_BETWEENGLASS_SHADE_BLIND(ShadingFlag: WinShadingType) -> Bool:
        return (ShadingFlag == WinShadingType.BGShade or ShadingFlag == WinShadingType.BGBlind)

    enum SlatAngleControl:
        Invalid = -1
        Fixed
        Scheduled
        BlockBeamSolar
        Num

    enum WindowAirFlowSource:
        Invalid = -1
        Indoor
        Outdoor
        Num

    enum WindowAirFlowDestination:
        Invalid = -1
        Indoor
        Outdoor
        Return
        Num

    enum WindowAirFlowControlType:
        Invalid = -1
        MaxFlow
        AlwaysOff
        Schedule
        Num

    enum WindowModel:
        Invalid = -1
        Detailed
        BSDF
        EQL
        Num

    const nVerticesBig: UInt = 20

    struct Surface2DSlab:

        var xl: Float64
        var xu: Float64
        var yl: Float64
        var yu: Float64
        var edges: List[UInt]
        var edgesXY: List[Float64]

        def __init__(inout self, yl: Float64, yu: Float64):
            self.xl = 0.0
            self.xu = 0.0
            self.yl = yl
            self.yu = yu
            self.edges = List[UInt]()
            self.edgesXY = List[Float64]()

    struct Surface2D:

        var axis: Int32 = 0
        var vertices: List[Vector2[Float64]]
        var vl: Vector2[Float64] = Vector2[Float64](0.0, 0.0)
        var vu: Vector2[Float64] = Vector2[Float64](0.0, 0.0)
        var edges: List[Vector2[Float64]]
        var s1: Float64 = 0.0
        var s3: Float64 = 0.0
        var slabYs: List[Float64]
        var slabs: List[Surface2DSlab]

        def __init__(inout self):
            self.vertices = List[Vector2[Float64]]()
            self.edges = List[Vector2[Float64]]()
            self.slabYs = List[Float64]()
            self.slabs = List[Surface2DSlab]()

        def __init__(inout self, shapeCat: ShapeCat, axis: Int32, v: List[Vector2[Float64]], vl: Vector2[Float64], vu: Vector2[Float64]):
            self.axis = axis
            self.vertices = v
            self.vl = vl
            self.vu = vu
            let n = v.size
            # assert(n >= 3)
            # Compute signed area, reverse if negative
            var area: Float64 = 0.0
            for i in range(n):
                let vi = v[i]
                let wi = v[(i + 1) % n]
                area += (vi.x * wi.y) - (wi.x * vi.y)
            if area < 0.0:
                # reverse vertices except first
                # In Mojo we can't easily reverse in place with slice, but we can create a new list
                var reversedVertices = List[Vector2[Float64]]()
                reversedVertices.append(v[0])
                for i in range(n - 1, 0, -1):
                    reversedVertices.append(v[i])
                self.vertices = reversedVertices

            # edges
            self.edges = List[Vector2[Float64]]()
            self.edges.reserve(n)
            for i in range(n):
                let next = (i + 1) % n
                let e = v[next] - v[i]
                self.edges.append(e)

            if shapeCat == ShapeCat.Rectangular:
                # assert(n == 4)
                self.s1 = self.edges[0].magnitude_squared()
                self.s3 = self.edges[3].magnitude_squared()
            elif (shapeCat == ShapeCat.Nonconvex) or (n >= nVerticesBig):
                # assert(n >= 4)
                self.slabYs = List[Float64]()
                self.slabYs.reserve(n)
                for i in range(n):
                    self.slabYs.append(v[i].y)
                # sort
                self.slabYs.sort()
                # unique
                var uniqueYs = List[Float64]()
                for y in self.slabYs:
                    if uniqueYs.size == 0 or uniqueYs[-1] != y:
                        uniqueYs.append(y)
                self.slabYs = uniqueYs
                self.slabs = List[Surface2DSlab]()
                for iSlab in range(self.slabYs.size - 1):
                    var xl = Float64.MAX
                    var xu = -Float64.MAX
                    let yl = self.slabYs[iSlab]
                    let yu = self.slabYs[iSlab + 1]
                    self.slabs.push_back(Surface2DSlab(yl, yu))
                    var slab = self.slabs[-1]
                    var crossEdges = List[(Float64, Float64, UInt)]()
                    for i in range(n):
                        let vi = v[i]
                        let wi = v[(i + 1) % n]
                        if (vi.y <= yl and yu <= wi.y) or (yu <= vi.y and wi.y <= yl):
                            let e = self.edges[i]
                            # assert(e.y != 0.0)
                            let exy = e.x / e.y
                            let xb = vi.x + (yl - vi.y) * exy
                            let xt = vi.x + (yu - vi.y) * exy
                            xl = min(xl, min(xb, xt))
                            xu = max(xu, max(xb, xt))
                            crossEdges.push_back((xb, xt, i))
                    slab.xl = xl
                    slab.xu = xu
                    # assert(crossEdges.size >= 2)
                    # sort by (xb + xt)
                    crossEdges.sort(lambda e1, e2: (e1._0 + e1._1) < (e2._0 + e2._1))
                    # Debug checks skipped
                    for edge in crossEdges:
                        let iEdge = edge._2
                        slab.edges.push_back(iEdge)
                        let e = self.edges[iEdge]
                        # assert(e.y != 0.0)
                        slab.edgesXY.push_back(e.x / e.y if e.y != 0.0 else 0.0)
                    # assert(slab.edges.size % 2 == 0)
                    # assert(slab.edges.size == slab.edgesXY.size)
            # end if

        def bb_contains(self, v: Vector2[Float64]) -> Bool:
            return (self.vl.x <= v.x) and (v.x <= self.vu.x) and (self.vl.y <= v.y) and (v.y <= self.vu.y)

        def __eq__(self, other: Self) -> Bool:
            let v1 = self.vertices
            let v2 = other.vertices
            if v1.size != v2.size:
                return False
            for i in range(v1.size):
                if v1[i] != v2[i]:
                    return False
            return True

    struct SurfaceCalcHashKey:

        var Construction: Int32 = 0
        var Azimuth: Float64 = 0.0
        var Tilt: Float64 = 0.0
        var Height: Float64 = 0.0
        var Zone: Int32 = 0
        var EnclIndex: Int32 = 0
        var TAirRef: Int32 = 0
        var ExtZone: Int32 = 0
        var ExtCond: Int32 = 0
        var ExtEnclIndex: Int32 = 0
        var ExtSolar: Bool = False
        var ExtWind: Bool = False
        var ViewFactorGround: Float64 = 0.0
        var ViewFactorSky: Float64 = 0.0
        var ViewFactorSrdSurfs: Float64 = 0.0
        var HeatTransferAlgorithm: HeatTransferModel = HeatTransferModel.CTF
        var intConvModel: Convect.HcInt = Convect.HcInt.Invalid
        var intConvUserModelNum: Int32 = 0
        var extConvModel: Convect.HcExt = Convect.HcExt.Invalid
        var extConvUserModelNum: Int32 = 0
        var OSCPtr: Int32 = 0
        var OSCMPtr: Int32 = 0
        var FrameDivider: Int32 = 0
        var SurfWinStormWinConstr: Int32 = 0
        var MaterialMovInsulExt: Int32 = 0
        var MaterialMovInsulInt: Int32 = 0
        var movInsulExtSchedNum: Int32 = Sched.SchedNum_Invalid
        var movInsulIntSchedNum: Int32 = Sched.SchedNum_Invalid
        var externalShadingSchedNum: Int32 = Sched.SchedNum_Invalid
        var SurroundingSurfacesNum: Int32 = 0
        var LinkedOutAirNode: Int32 = 0
        var outsideHeatSourceTermSchedNum: Int32 = Sched.SchedNum_Invalid
        var insideHeatSourceTermSchedNum: Int32 = Sched.SchedNum_Invalid

        def hash_combine(self, current_hash: UInt, new_hash: UInt) -> UInt:
            return current_hash ^ (new_hash + 0x9e3779b9 + (current_hash << 6) + (current_hash >> 2))

        def get_hash_list(self) -> List[UInt]:
            var hashes = List[UInt]()
            hashes.push_back(UInt(self.Construction))
            hashes.push_back(UInt(self.Azimuth))
            hashes.push_back(UInt(self.Tilt))
            hashes.push_back(UInt(self.Height))
            hashes.push_back(UInt(self.Zone))
            hashes.push_back(UInt(self.EnclIndex))
            hashes.push_back(UInt(self.TAirRef))
            hashes.push_back(UInt(self.ExtZone))
            hashes.push_back(UInt(self.ExtCond))
            hashes.push_back(UInt(self.ExtEnclIndex))
            hashes.push_back(UInt(self.ExtSolar))
            hashes.push_back(UInt(self.ExtWind))
            hashes.push_back(UInt(self.ViewFactorGround))
            hashes.push_back(UInt(self.ViewFactorSky))
            hashes.push_back(UInt(self.HeatTransferAlgorithm))
            hashes.push_back(UInt(self.intConvModel))
            hashes.push_back(UInt(self.extConvModel))
            hashes.push_back(UInt(self.intConvUserModelNum))
            hashes.push_back(UInt(self.extConvUserModelNum))
            hashes.push_back(UInt(self.OSCPtr))
            hashes.push_back(UInt(self.OSCMPtr))
            hashes.push_back(UInt(self.FrameDivider))
            hashes.push_back(UInt(self.SurfWinStormWinConstr))
            hashes.push_back(UInt(self.MaterialMovInsulExt))
            hashes.push_back(UInt(self.MaterialMovInsulInt))
            hashes.push_back(UInt(self.movInsulExtSchedNum))
            hashes.push_back(UInt(self.movInsulIntSchedNum))
            hashes.push_back(UInt(self.externalShadingSchedNum))
            hashes.push_back(UInt(self.SurroundingSurfacesNum))
            hashes.push_back(UInt(self.LinkedOutAirNode))
            hashes.push_back(UInt(self.outsideHeatSourceTermSchedNum))
            hashes.push_back(UInt(self.insideHeatSourceTermSchedNum))
            return hashes

        def get_hash(self) -> UInt:
            let hash_list = self.get_hash_list()
            var combined_hash: UInt = 0
            for h in hash_list:
                combined_hash = self.hash_combine(combined_hash, h)
            return combined_hash

        def __eq__(self, other: Self) -> Bool:
            return (self.Construction == other.Construction and self.Azimuth == other.Azimuth and self.Tilt == other.Tilt and
                    self.Height == other.Height and self.Zone == other.Zone and self.EnclIndex == other.EnclIndex and
                    self.ExtZone == other.ExtZone and self.ExtCond == other.ExtCond and self.ExtEnclIndex == other.ExtEnclIndex and
                    self.ExtSolar == other.ExtSolar and self.ExtWind == other.ExtWind and
                    self.ViewFactorGround == other.ViewFactorGround and self.ViewFactorSky == other.ViewFactorSky and
                    self.HeatTransferAlgorithm == other.HeatTransferAlgorithm and self.intConvModel == other.intConvModel and
                    self.intConvUserModelNum == other.intConvUserModelNum and self.extConvUserModelNum == other.extConvUserModelNum and
                    self.extConvModel == other.extConvModel and self.OSCPtr == other.OSCPtr and self.OSCMPtr == other.OSCMPtr and
                    self.FrameDivider == other.FrameDivider and self.SurfWinStormWinConstr == other.SurfWinStormWinConstr and
                    self.MaterialMovInsulExt == other.MaterialMovInsulExt and self.MaterialMovInsulInt == other.MaterialMovInsulInt and
                    self.movInsulExtSchedNum == other.movInsulExtSchedNum and self.movInsulIntSchedNum == other.movInsulIntSchedNum and
                    self.externalShadingSchedNum == other.externalShadingSchedNum and
                    self.SurroundingSurfacesNum == other.SurroundingSurfacesNum and self.LinkedOutAirNode == other.LinkedOutAirNode and
                    self.outsideHeatSourceTermSchedNum == other.outsideHeatSourceTermSchedNum and
                    self.insideHeatSourceTermSchedNum == other.insideHeatSourceTermSchedNum)

    struct SurfaceCalcHasher:
        def __call__(self, key: SurfaceCalcHashKey) -> UInt:
            return key.get_hash()

    struct SurfaceData:

        var Name: String
        var Construction: Int32
        var RepresentativeCalcSurfNum: Int32
        var ConstituentSurfaceNums: List[Int32]
        var ConstructionStoredInputValue: Int32
        var Class: SurfaceClass
        var OriginalClass: SurfaceClass
        var Shape: SurfaceShape
        var Sides: Int32
        var Area: Float64
        var GrossArea: Float64
        var NetAreaShadowCalc: Float64
        var Perimeter: Float64
        var Azimuth: Float64
        var Height: Float64
        var Reveal: Float64
        var Tilt: Float64
        var Width: Float64
        var shapeCat: ShapeCat
        var plane: Vector4[Float64]
        var surface2d: Surface2D
        var NewVertex: Array1D[Vector]
        var Vertex: Array1D[Vector]
        var Centroid: Vector3[Float64]
        var lcsx: Vector3[Float64]
        var lcsy: Vector3[Float64]
        var lcsz: Vector3[Float64]
        var NewellAreaVector: Vector3[Float64]
        var NewellSurfaceNormalVector: Vector3[Float64]
        var OutNormVec: Vector3[Float64]
        var SinAzim: Float64
        var CosAzim: Float64
        var SinTilt: Float64
        var CosTilt: Float64
        var IsConvex: Bool
        var IsDegenerate: Bool
        var VerticesProcessed: Bool
        var XShift: Float64
        var YShift: Float64
        var HeatTransSurf: Bool
        var outsideHeatSourceTermSched: Sched.Schedule? = None
        var insideHeatSourceTermSched: Sched.Schedule? = None
        var HeatTransferAlgorithm: HeatTransferModel
        var BaseSurfName: String
        var BaseSurf: Int32
        var NumSubSurfaces: Int32
        var ZoneName: String
        var Zone: Int32
        var spaceNum: Int32
        var ExtBoundCondName: String
        var ExtBoundCond: Int32
        var ExtSolar: Bool
        var ExtWind: Bool
        var hasIncSolMultiplier: Bool
        var IncSolMultiplier: Float64
        var ViewFactorGround: Float64
        var ViewFactorSky: Float64
        var ViewFactorGroundIR: Float64
        var ViewFactorSkyIR: Float64
        var OSCPtr: Int32
        var OSCMPtr: Int32
        var MirroredSurf: Bool
        var IsShadowing: Bool
        var IsShadowPossibleObstruction: Bool
        var shadowSurfSched: Sched.Schedule? = None
        var IsTransparent: Bool
        var SchedMinValue: Float64
        var activeWindowShadingControl: Int32
        var windowShadingControlList: List[Int32]
        var HasShadeControl: Bool
        var activeShadedConstruction: Int32
        var activeShadedConstructionPrev: Int32
        var shadedConstructionList: List[Int32]
        var shadedStormWinConstructionList: List[Int32]
        var FrameDivider: Int32
        var Multiplier: Float64
        var RadEnclIndex: Int32 = 0
        var SolarEnclIndex: Int32
        var SolarEnclSurfIndex: Int32
        var IsAirBoundarySurf: Bool
        var convOrientation: Convect.SurfOrientation = Convect.SurfOrientation.Invalid
        var calcHashKey: SurfaceCalcHashKey
        var IsSurfPropertyGndSurfacesDefined: Bool
        var SurfPropertyGndSurfIndex: Int32
        var UseSurfPropertyGndSurfTemp: Bool
        var UseSurfPropertyGndSurfRefl: Bool
        var GndReflSolarRad: Float64
        var SurfHasSurroundingSurfProperty: Bool
        var SurfSchedExternalShadingFrac: Bool
        var SurfSurroundingSurfacesNum: Int32
        var surfExternalShadingSched: Sched.Schedule? = None
        var SurfLinkedOutAirNode: Int32
        var AE: Float64 = 0.0
        var enclAESum: Float64 = 0.0
        var SrdSurfTemp: Float64
        var ViewFactorSrdSurfs: Float64

        def __init__(inout self):
            self.Name = ""
            self.Construction = 0
            self.RepresentativeCalcSurfNum = -1
            self.ConstituentSurfaceNums = List[Int32]()
            self.ConstructionStoredInputValue = 0
            self.Class = SurfaceClass.None
            self.OriginalClass = SurfaceClass.None
            self.Shape = SurfaceShape.None
            self.Sides = 0
            self.Area = 0.0
            self.GrossArea = 0.0
            self.NetAreaShadowCalc = 0.0
            self.Perimeter = 0.0
            self.Azimuth = 0.0
            self.Height = 0.0
            self.Reveal = 0.0
            self.Tilt = 0.0
            self.Width = 0.0
            self.shapeCat = ShapeCat.Invalid
            self.plane = Vector4[Float64](0.0, 0.0, 0.0, 0.0)
            self.surface2d = Surface2D()
            self.NewVertex = Array1D[Vector]()
            self.Vertex = Array1D[Vector]()
            self.Centroid = Vector3[Float64](0.0, 0.0, 0.0)
            self.lcsx = Vector3[Float64](0.0, 0.0, 0.0)
            self.lcsy = Vector3[Float64](0.0, 0.0, 0.0)
            self.lcsz = Vector3[Float64](0.0, 0.0, 0.0)
            self.NewellAreaVector = Vector3[Float64](0.0, 0.0, 0.0)
            self.NewellSurfaceNormalVector = Vector3[Float64](0.0, 0.0, 0.0)
            self.OutNormVec = Vector3[Float64](0.0, 0.0, 0.0)
            self.SinAzim = 0.0
            self.CosAzim = 0.0
            self.SinTilt = 0.0
            self.CosTilt = 0.0
            self.IsConvex = True
            self.IsDegenerate = False
            self.VerticesProcessed = False
            self.XShift = 0.0
            self.YShift = 0.0
            self.HeatTransSurf = False
            self.HeatTransferAlgorithm = HeatTransferModel.Invalid
            self.BaseSurfName = ""
            self.BaseSurf = 0
            self.NumSubSurfaces = 0
            self.ZoneName = ""
            self.Zone = 0
            self.spaceNum = 0
            self.ExtBoundCondName = ""
            self.ExtBoundCond = 0
            self.ExtSolar = False
            self.ExtWind = False
            self.hasIncSolMultiplier = False
            self.IncSolMultiplier = 1.0
            self.ViewFactorGround = 0.0
            self.ViewFactorSky = 0.0
            self.ViewFactorGroundIR = 0.0
            self.ViewFactorSkyIR = 0.0
            self.OSCPtr = 0
            self.OSCMPtr = 0
            self.MirroredSurf = False
            self.IsShadowing = False
            self.IsShadowPossibleObstruction = False
            self.IsTransparent = False
            self.SchedMinValue = 0.0
            self.activeWindowShadingControl = 0
            self.HasShadeControl = False
            self.activeShadedConstruction = 0
            self.activeShadedConstructionPrev = 0
            self.FrameDivider = 0
            self.Multiplier = 1.0
            self.SolarEnclIndex = 0
            self.SolarEnclSurfIndex = 0
            self.IsAirBoundarySurf = False
            self.calcHashKey = SurfaceCalcHashKey()
            self.IsSurfPropertyGndSurfacesDefined = False
            self.SurfPropertyGndSurfIndex = 0
            self.UseSurfPropertyGndSurfTemp = False
            self.UseSurfPropertyGndSurfRefl = False
            self.GndReflSolarRad = 0.0
            self.SurfHasSurroundingSurfProperty = False
            self.SurfSchedExternalShadingFrac = False
            self.SurfSurroundingSurfacesNum = 0
            self.SurfLinkedOutAirNode = 0
            self.SrdSurfTemp = 0.0
            self.ViewFactorSrdSurfs = 0.0

        # Methods
        def set_computed_geometry(inout self):
            if self.Vertex.size() >= 3:
                self.shapeCat = self.computed_shapeCat()
                self.plane = self.computed_plane()
                self.surface2d = self.computed_surface2d()

        def getInsideAirTemperature(self, state: EnergyPlusData, t_SurfNum: Int32) -> Float64:
            # ... implementation similar to C++
            var RefAirTemp: Float64 = 0.0
            let thisSpaceHB = state.dataZoneTempPredictorCorrector.spaceHeatBalance(self.spaceNum - 1)  # 0-based
            let surfTAirRef = state.dataSurface.SurfTAirRef[t_SurfNum - 1]  # 0-based
            if surfTAirRef == RefAirTemp.ZoneMeanAirTemp:
                RefAirTemp = thisSpaceHB.MAT
            elif surfTAirRef == RefAirTemp.AdjacentAirTemp:
                RefAirTemp = state.dataHeatBal.SurfTempEffBulkAir[t_SurfNum - 1]
            elif surfTAirRef == RefAirTemp.ZoneSupplyAirTemp:
                if not state.dataHeatBal.Zone[self.Zone - 1].IsControlled:
                    ShowFatalError(state, "Zones must be controlled for Ceiling-Diffuser Convection model. No system serves zone " + state.dataHeatBal.Zone[self.Zone - 1].Name)
                var SumSysMCp: Float64 = 0.0
                var SumSysMCpT: Float64 = 0.0
                let inletNodes = state.dataZoneEquip.spaceEquipConfig[self.spaceNum - 1].InletNode if state.dataHeatBal.doSpaceHeatBalance else state.dataZoneEquip.ZoneEquipConfig[self.Zone - 1].InletNode
                for nodeNum in inletNodes:
                    let inNode = state.dataLoopNodes.Node[nodeNum - 1]
                    let CpAir = PsyCpAirFnW(thisSpaceHB.airHumRat)
                    SumSysMCp += inNode.MassFlowRate * CpAir
                    SumSysMCpT += inNode.MassFlowRate * CpAir * inNode.Temp
                if SumSysMCp > 0.0:
                    RefAirTemp = SumSysMCpT / SumSysMCp
                else:
                    RefAirTemp = thisSpaceHB.MAT
            else:
                RefAirTemp = thisSpaceHB.MAT
            return RefAirTemp

        def getOutsideAirTemperature(self, state: EnergyPlusData, t_SurfNum: Int32) -> Float64:
            var temperature: Float64 = 0.0
            if self.ExtBoundCond > 0:
                temperature = self.getInsideAirTemperature(state, t_SurfNum)
            else:
                if self.ExtWind:
                    if state.dataEnvrn.IsRain:
                        temperature = state.dataSurface.SurfOutWetBulbTemp[t_SurfNum - 1]
                    else:
                        temperature = state.dataSurface.SurfOutDryBulbTemp[t_SurfNum - 1]
                else:
                    temperature = state.dataSurface.SurfOutDryBulbTemp[t_SurfNum - 1]
            return temperature

        def getOutsideIR(self, state: EnergyPlusData, t_SurfNum: Int32) -> Float64:
            var value: Float64 = 0.0
            if self.ExtBoundCond > 0:
                value = state.dataSurface.SurfWinIRfromParentZone[self.ExtBoundCond - 1] + state.dataHeatBalSurf.SurfQdotRadHVACInPerArea[self.ExtBoundCond - 1]
            else:
                let tout = self.getOutsideAirTemperature(state, t_SurfNum) + Constant.Kelvin
                value = Constant.StefanBoltzmann * pow(tout, 4)
                value = self.ViewFactorSkyIR * (state.dataSurface.SurfAirSkyRadSplit[t_SurfNum - 1] * Constant.StefanBoltzmann * pow(state.dataEnvrn.SkyTempKelvin, 4) + (1.0 - state.dataSurface.SurfAirSkyRadSplit[t_SurfNum - 1]) * value) + self.ViewFactorGroundIR * value
            return value

        @staticmethod
        def getSWIncident(state: EnergyPlusData, t_SurfNum: Int32) -> Float64:
            return state.dataHeatBal.SurfQRadSWOutIncident[t_SurfNum - 1] + state.dataHeatBal.EnclSolQSWRad[state.dataSurface.Surface[t_SurfNum - 1].SolarEnclIndex - 1]

        def getTotLayers(self, state: EnergyPlusData) -> Int32:
            let construction = state.dataConstruction.Construct[self.Construction - 1]
            return construction.TotLayers

        def computed_shapeCat(self) -> ShapeCat:
            if self.Shape == SurfaceShape.Triangle:
                return ShapeCat.Triangular
            if self.Shape == SurfaceShape.TriangularWindow:
                return ShapeCat.Triangular
            if self.Shape == SurfaceShape.TriangularDoor:
                return ShapeCat.Triangular
            if self.Shape == SurfaceShape.Rectangle:
                return ShapeCat.Rectangular
            if self.Shape == SurfaceShape.RectangularDoorWindow:
                return ShapeCat.Rectangular
            if self.Shape == SurfaceShape.RectangularOverhang:
                return ShapeCat.Rectangular
            if self.Shape == SurfaceShape.RectangularLeftFin:
                return ShapeCat.Rectangular
            if self.Shape == SurfaceShape.RectangularRightFin:
                return ShapeCat.Rectangular
            if self.IsConvex:
                return ShapeCat.Convex
            else:
                return ShapeCat.Nonconvex

        def computed_plane(self) -> Vector4[Float64]:
            let n = self.Vertex.size()
            # assert(n >= 3)
            var center = Vector(0.0)
            var a: Float64 = 0.0
            var b: Float64 = 0.0
            var c: Float64 = 0.0
            var d: Float64 = 0.0
            for i in range(n):
                let v = self.Vertex[i]
                let w = self.Vertex[(i + 1) % n]
                a += (v.y - w.y) * (v.z + w.z)
                b += (v.z - w.z) * (v.x + w.x)
                c += (v.x - w.x) * (v.y + w.y)
                center += v
            d = -(center.dot(Vector(a, b, c)) / Float64(n))
            return Vector4[Float64](a, b, c, d)

        def computed_surface2d(self) -> Surface2D:
            let n = self.Vertex.size()
            # assert(n >= 3)
            # assert(self.plane == self.computed_plane())
            let a = abs(self.plane.x)
            let b = abs(self.plane.y)
            let c = abs(self.plane.z)
            var axis: Int32
            if a >= max(b, c):
                axis = 0
            elif b >= max(a, c):
                axis = 1
            else:
                axis = 2
            var v2d = List[Vector2[Float64]]()
            let v0 = self.Vertex[0]
            if axis == 0:
                var yl = v0.y
                var yu = v0.y
                var zl = v0.z
                var zu = v0.z
                for i in range(n):
                    let v = self.Vertex[i]
                    v2d.append(Vector2[Float64](v.y, v.z))
                    yl = min(yl, v.y)
                    yu = max(yu, v.y)
                    zl = min(zl, v.z)
                    zu = max(zu, v.z)
                return Surface2D(self.shapeCat, axis, v2d, Vector2[Float64](yl, zl), Vector2[Float64](yu, zu))
            elif axis == 1:
                var xl = v0.x
                var xu = v0.x
                var zl = v0.z
                var zu = v0.z
                for i in range(n):
                    let v = self.Vertex[i]
                    v2d.append(Vector2[Float64](v.x, v.z))
                    xl = min(xl, v.x)
                    xu = max(xu, v.x)
                    zl = min(zl, v.z)
                    zu = max(zu, v.z)
                return Surface2D(self.shapeCat, axis, v2d, Vector2[Float64](xl, zl), Vector2[Float64](xu, zu))
            else:  # axis == 2
                var xl = v0.x
                var xu = v0.x
                var yl = v0.y
                var yu = v0.y
                for i in range(n):
                    let v = self.Vertex[i]
                    v2d.append(Vector2[Float64](v.x, v.y))
                    xl = min(xl, v.x)
                    xu = max(xu, v.x)
                    yl = min(yl, v.y)
                    yu = max(yu, v.y)
                return Surface2D(self.shapeCat, axis, v2d, Vector2[Float64](xl, yl), Vector2[Float64](xu, yu))

        def get_average_height(self, state: EnergyPlusData) -> Float64:
            if abs(self.SinTilt) < Constant.SmallDistance:
                return 0.0
            let n = self.Vertex.size()
            # assert(n >= 3)
            let xRef = self.Vertex[0].x
            let yRef = self.Vertex[0].y
            let saz = self.SinAzim
            let caz = self.CosAzim
            var v2d = List[Vector2[Float64]]()
            for i in range(n):
                let v = self.Vertex[i]
                v2d.append(Vector2[Float64](-(v.x - xRef) * caz + (v.y - yRef) * saz, v.z))
            var minX = v2d[0].x
            var maxX = v2d[0].x
            for i in range(n):
                let vi = v2d[i]
                minX = min(minX, vi.x)
                maxX = max(maxX, vi.x)
            let totalWidth = maxX - minX
            if totalWidth == 0.0:
                ShowFatalError(state, "Calculated projected surface width is zero for surface=\"" + self.Name + "\"")
            var averageHeight: Float64 = 0.0
            for i in range(n):
                let v = v2d[i]
                let v2 = v2d[(i + 1) % n]
                averageHeight += 0.5 * (v.y + v2.y) * (v2.x - v.x) / totalWidth
            return abs(averageHeight) / self.SinTilt

        def make_hash_key(inout self, state: EnergyPlusData, SurfNum: Int32):
            let s_surf = state.dataSurface
            self.calcHashKey = SurfaceCalcHashKey()
            self.calcHashKey.Construction = self.Construction
            self.calcHashKey.Azimuth = round(self.Azimuth * 10.0) / 10.0
            self.calcHashKey.Tilt = round(self.Tilt * 10.0) / 10.0
            self.calcHashKey.Height = round(self.Height * 10.0) / 10.0
            self.calcHashKey.Zone = self.Zone
            self.calcHashKey.EnclIndex = self.SolarEnclIndex
            self.calcHashKey.TAirRef = s_surf.SurfTAirRef[SurfNum - 1]
            let extBoundCond = s_surf.Surface[SurfNum - 1].ExtBoundCond
            if extBoundCond > 0:
                self.calcHashKey.ExtZone = s_surf.Surface[extBoundCond - 1].Zone
                self.calcHashKey.ExtEnclIndex = s_surf.Surface[extBoundCond - 1].SolarEnclIndex
                self.calcHashKey.ExtCond = 1
            else:
                self.calcHashKey.ExtZone = 0
                self.calcHashKey.ExtEnclIndex = 0
                self.calcHashKey.ExtCond = extBoundCond
            self.calcHashKey.ExtSolar = self.ExtSolar
            self.calcHashKey.ExtWind = self.ExtWind
            self.calcHashKey.ViewFactorGround = round(self.ViewFactorGround * 10.0) / 10.0
            self.calcHashKey.ViewFactorSky = round(self.ViewFactorSky * 10.0) / 10.0
            self.calcHashKey.HeatTransferAlgorithm = self.HeatTransferAlgorithm
            self.calcHashKey.intConvModel = s_surf.surfIntConv[SurfNum - 1].model
            self.calcHashKey.extConvModel = s_surf.surfExtConv[SurfNum - 1].model
            self.calcHashKey.intConvUserModelNum = s_surf.surfIntConv[SurfNum - 1].userModelNum
            self.calcHashKey.extConvUserModelNum = s_surf.surfExtConv[SurfNum - 1].userModelNum
            self.calcHashKey.OSCPtr = self.OSCPtr
            self.calcHashKey.OSCMPtr = self.OSCMPtr
            self.calcHashKey.FrameDivider = self.FrameDivider
            self.calcHashKey.SurfWinStormWinConstr = s_surf.SurfWinStormWinConstr[SurfNum - 1]
            self.calcHashKey.MaterialMovInsulExt = s_surf.extMovInsuls[SurfNum - 1].matNum
            self.calcHashKey.MaterialMovInsulInt = s_surf.intMovInsuls[SurfNum - 1].matNum
            self.calcHashKey.movInsulExtSchedNum = s_surf.extMovInsuls[SurfNum - 1].sched.Num if s_surf.extMovInsuls[SurfNum - 1].sched else -1
            self.calcHashKey.movInsulIntSchedNum = s_surf.intMovInsuls[SurfNum - 1].sched.Num if s_surf.intMovInsuls[SurfNum - 1].sched else -1
            self.calcHashKey.externalShadingSchedNum = s_surf.Surface[SurfNum - 1].surfExternalShadingSched.Num if s_surf.Surface[SurfNum - 1].surfExternalShadingSched else -1
            self.calcHashKey.SurroundingSurfacesNum = s_surf.Surface[SurfNum - 1].SurfSurroundingSurfacesNum
            self.calcHashKey.LinkedOutAirNode = s_surf.Surface[SurfNum - 1].SurfLinkedOutAirNode
            self.calcHashKey.outsideHeatSourceTermSchedNum = self.outsideHeatSourceTermSched.Num if self.outsideHeatSourceTermSched else -1
            self.calcHashKey.insideHeatSourceTermSchedNum = self.insideHeatSourceTermSched.Num if self.insideHeatSourceTermSched else -1
            self.calcHashKey.ViewFactorSrdSurfs = s_surf.Surface[SurfNum - 1].ViewFactorSrdSurfs

        def set_representative_surface(inout self, state: EnergyPlusData, SurfNum: Int32):
            state.dataSurface.Surface[SurfNum - 1].make_hash_key(state, SurfNum)
            # representative map insertion
            let key = state.dataSurface.Surface[SurfNum - 1].calcHashKey
            let existing = state.dataSurface.RepresentativeSurfaceMap.get(key)
            if existing:
                state.dataSurface.Surface[SurfNum - 1].RepresentativeCalcSurfNum = existing
            else:
                state.dataSurface.RepresentativeSurfaceMap[key] = SurfNum
                state.dataSurface.Surface[SurfNum - 1].RepresentativeCalcSurfNum = SurfNum
            state.dataSurface.Surface[state.dataSurface.Surface[SurfNum - 1].RepresentativeCalcSurfNum - 1].ConstituentSurfaceNums.push_back(SurfNum)

    struct SurfaceWindowRefPt:
        var solidAng: Float64 = 0.0
        var solidAngWtd: Float64 = 0.0
        var lums: StaticArray[StaticArray[Float64, WinCover.Num], Lum.Num] = [[0.0, 0.0], [0.0, 0.0], [0.0, 0.0]]
        var illumFromWinRep: Float64 = 0.0
        var lumWinRep: Float64 = 0.0

    struct SurfaceWindowCalc:
        var refPts: Array1D[SurfaceWindowRefPt]
        var WinCenter: Vector3[Float64] = Vector3[Float64](0.0, 0.0, 0.0)
        var theta: Float64 = 0.0
        var phi: Float64 = 0.0
        var rhoCeilingWall: Float64 = 0.0
        var rhoFloorWall: Float64 = 0.0
        var fractionUpgoing: Float64 = 0.0
        var glazedFrac: Float64 = 1.0
        var centerGlassArea: Float64 = 0.0
        var edgeGlassCorrFac: Float64 = 1.0
        var screenNum: Int32 = 0
        var lightWellEff: Float64 = 1.0
        var thetaFace: StaticArray[Float64, 11] = [296.15, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        var OutProjSLFracMult: StaticArray[Float64, Constant.iHoursInDay + 1] = [1.0]
        var InOutProjSLFracMult: StaticArray[Float64, Constant.iHoursInDay + 1] = [1.0]
        var EnclAreaMinusThisSurf: StaticArray[Float64, FWC.Num] = [0.0, 0.0, 0.0]
        var EnclAreaReflProdMinusThisSurf: StaticArray[Float64, FWC.Num] = [0.0, 0.0, 0.0]
        var ComplexFen: BSDFWindowDescript
        var hasShade: Bool = False
        var hasBlind: Bool = False
        var hasScreen: Bool = False

    struct SurfaceShade:
        struct Blind:
            var matNum: Int32 = 0
            var movableSlats: Bool = False
            var slatAng: Float64 = 0.0
            var slatAngDeg: Float64 = 0.0
            var slatAngDegEMSon: Bool = False
            var slatAngDegEMSValue: Float64 = 0.0
            var slatBlockBeam: Bool = False
            var slatAngIdxLo: Int32 = -1
            var slatAngIdxHi: Int32 = -1
            var slatAngInterpFac: Float64 = 0.0
            var profAng: Float64 = 0.0
            var profAngIdxLo: Int32 = 0
            var profAngIdxHi: Int32 = 0
            var profAngInterpFac: Float64 = 0.0
            var bmBmTrans: Float64 = 0.0
            var airFlowPermeability: Float64 = 0.0
            var TAR: BlindTraAbsRef[Int32]  # array of size MaxProfAngs+1

        var blind: Blind = Blind()
        struct Glass:
            var epsIR: Float64 = 0.0
            var rhoIR: Float64 = 0.0
        var glass: Glass = Glass()
        var effShadeEmi: Float64 = 0.0
        var effGlassEmi: Float64 = 0.0

    struct SurfaceWindowFrameDiv:

    enum NfrcProductOptions: Int32:
        Invalid = -1
        CasementDouble
        CasementSingle
        DualAction
        Fixed
        Garage
        Greenhouse
        HingedEscape
        HorizontalSlider
        Jal
        Pivoted
        ProjectingSingle
        ProjectingDual
        DoorSidelite
        Skylight
        SlidingPatioDoor
        CurtainWall
        SpandrelPanel
        SideHingedDoor
        DoorTransom
        TropicalAwning
        TubularDaylightingDevice
        VerticalSlider
        Num

    enum NfrcVisionType: Int32:
        Invalid = -1
        Single
        DualVertical
        DualHorizontal
        Num

    enum FrameDividerType: Int32:
        Invalid = -1
        DividedLite
        Suspended
        Num

    enum MultiSurfaceControl:
        Invalid = -1
        Sequential
        Group
        Num

    struct FrameDividerProperties:
        var Name: String
        var FrameWidth: Float64
        var FrameProjectionOut: Float64
        var FrameProjectionIn: Float64
        var FrameConductance: Float64
        var FrameEdgeWidth: Float64
        var FrEdgeToCenterGlCondRatio: Float64
        var FrameSolAbsorp: Float64
        var FrameVisAbsorp: Float64
        var FrameEmis: Float64
        var DividerType: FrameDividerType
        var DividerWidth: Float64
        var HorDividers: Int32
        var VertDividers: Int32
        var DividerProjectionOut: Float64
        var DividerProjectionIn: Float64
        var DividerEdgeWidth: Float64
        var DividerConductance: Float64
        var DivEdgeToCenterGlCondRatio: Float64
        var DividerSolAbsorp: Float64
        var DividerVisAbsorp: Float64
        var DividerEmis: Float64
        var MullionOrientation: WinEqOrientation
        var NfrcProductType: NfrcProductOptions
        var OutsideRevealSolAbs: Float64
        var InsideSillDepth: Float64
        var InsideReveal: Float64
        var InsideSillSolAbs: Float64
        var InsideRevealSolAbs: Float64

        def __init__(inout self):
            self.Name = ""
            self.FrameWidth = 0.0
            self.FrameProjectionOut = 0.0
            self.FrameProjectionIn = 0.0
            self.FrameConductance = 0.0
            self.FrameEdgeWidth = 0.06355
            self.FrEdgeToCenterGlCondRatio = 1.0
            self.FrameSolAbsorp = 0.0
            self.FrameVisAbsorp = 0.0
            self.FrameEmis = 0.9
            self.DividerType = FrameDividerType.DividedLite
            self.DividerWidth = 0.0
            self.HorDividers = 0
            self.VertDividers = 0
            self.DividerProjectionOut = 0.0
            self.DividerProjectionIn = 0.0
            self.DividerEdgeWidth = 0.06355
            self.DividerConductance = 0.0
            self.DivEdgeToCenterGlCondRatio = 1.0
            self.DividerSolAbsorp = 0.0
            self.DividerVisAbsorp = 0.0
            self.DividerEmis = 0.9
            self.MullionOrientation = WinEqOrientation.Invalid
            self.NfrcProductType = NfrcProductOptions.CurtainWall
            self.OutsideRevealSolAbs = 0.0
            self.InsideSillDepth = 0.0
            self.InsideReveal = 0.0
            self.InsideSillSolAbs = 0.0
            self.InsideRevealSolAbs = 0.0

    struct StormWindowData:
        var BaseWindowNum: Int32
        var StormWinMaterialNum: Int32
        var StormWinDistance: Float64
        var DateOn: Int32
        var MonthOn: Int32
        var DayOfMonthOn: Int32
        var DateOff: Int32
        var MonthOff: Int32
        var DayOfMonthOff: Int32

        def __init__(inout self):
            self.BaseWindowNum = 0
            self.StormWinMaterialNum = 0
            self.StormWinDistance = 0.0
            self.DateOn = 0
            self.MonthOn = 0
            self.DayOfMonthOn = 0
            self.DateOff = 0
            self.MonthOff = 0
            self.DayOfMonthOff = 0

    struct WindowShadingControlData:
        var Name: String
        var ZoneIndex: Int32 = 0
        var SequenceNumber: Int32 = 0
        var ShadingType: WinShadingType = WinShadingType.NoShade
        var getInputShadedConstruction: Int32 = 0
        var ShadingDevice: Int32 = 0
        var shadingControlType: WindowShadingControlType = WindowShadingControlType.Invalid
        var sched: Sched.Schedule? = None
        var SetPoint: Float64 = 0.0
        var SetPoint2: Float64 = 0.0
        var ShadingControlIsScheduled: Bool = False
        var GlareControlIsActive: Bool = False
        var slatAngleSched: Sched.Schedule? = None
        var slatAngleControl: SlatAngleControl = SlatAngleControl.Invalid
        var DaylightingControlName: String
        var DaylightControlIndex: Int32 = 0
        var multiSurfaceControl: MultiSurfaceControl = MultiSurfaceControl.Invalid
        var FenestrationCount: Int32 = 0
        var FenestrationName: Array1D[String]
        var FenestrationIndex: Array1D[Int32]

    struct OSCData:
        var Name: String
        var ConstTemp: Float64
        var ConstTempCoef: Float64
        var ExtDryBulbCoef: Float64
        var GroundTempCoef: Float64
        var SurfFilmCoef: Float64
        var WindSpeedCoef: Float64
        var ZoneAirTempCoef: Float64
        var ConstTempScheduleName: String
        var constTempSched: Sched.Schedule? = None
        var SinusoidalConstTempCoef: Bool
        var SinusoidPeriod: Float64
        var TPreviousCoef: Float64
        var TOutsideSurfPast: Float64
        var MinTempLimit: Float64
        var MaxTempLimit: Float64
        var MinLimitPresent: Bool
        var MaxLimitPresent: Bool
        var OSCTempCalc: Float64

        def __init__(inout self):
            self.Name = ""
            self.ConstTemp = 0.0
            self.ConstTempCoef = 0.0
            self.ExtDryBulbCoef = 0.0
            self.GroundTempCoef = 0.0
            self.SurfFilmCoef = 0.0
            self.WindSpeedCoef = 0.0
            self.ZoneAirTempCoef = 0.0
            self.ConstTempScheduleName = ""
            self.SinusoidalConstTempCoef = False
            self.SinusoidPeriod = 0.0
            self.TPreviousCoef = 0.0
            self.TOutsideSurfPast = 0.0
            self.MinTempLimit = 0.0
            self.MaxTempLimit = 0.0
            self.MinLimitPresent = False
            self.MaxLimitPresent = False
            self.OSCTempCalc = 0.0

    struct OSCMData:
        var Name: String
        var Class: String
        var TConv: Float64
        var EMSOverrideOnTConv: Bool
        var EMSOverrideTConvValue: Float64
        var HConv: Float64
        var EMSOverrideOnHConv: Bool
        var EMSOverrideHConvValue: Float64
        var TRad: Float64
        var EMSOverrideOnTRad: Bool
        var EMSOverrideTRadValue: Float64
        var HRad: Float64
        var EMSOverrideOnHrad: Bool
        var EMSOverrideHradValue: Float64

        def __init__(inout self):
            self.Name = ""
            self.Class = ""
            self.TConv = 20.0
            self.EMSOverrideOnTConv = False
            self.EMSOverrideTConvValue = 0.0
            self.HConv = 4.0
            self.EMSOverrideOnHConv = False
            self.EMSOverrideHConvValue = 0.0
            self.TRad = 20.0
            self.EMSOverrideOnTRad = False
            self.EMSOverrideTRadValue = 0.0
            self.HRad = 4.0
            self.EMSOverrideOnHrad = False
            self.EMSOverrideHradValue = 0.0

    struct ConvectionCoefficient:
        var WhichSurface: Int32 = 0
        var SurfaceName: String
        var overrideType: Convect.OverrideType = Convect.OverrideType.Invalid
        var OverrideValue: Float64 = 0.0
        var sched: Sched.Schedule? = None
        var UserCurveIndex: Int32 = 0
        var HcIntModelEq: Convect.HcInt = Convect.HcInt.Invalid
        var HcExtModelEq: Convect.HcExt = Convect.HcExt.Invalid

    struct ShadingVertexData:
        var NVert: Int32 = 0
        var XV: Array1D[Float64]
        var YV: Array1D[Float64]
        var ZV: Array1D[Float64]

    struct SurfaceSolarIncident:
        var Name: String
        var SurfPtr: Int32 = 0
        var ConstrPtr: Int32 = 0
        var sched: Sched.Schedule? = None

    struct SurfaceIncidentSolarMultiplier:
        var Name: String
        var SurfaceIdx: Int32 = 0
        var Scaler: Float64 = 1.0
        var sched: Sched.Schedule? = None

    struct FenestrationSolarAbsorbed:
        var Name: String
        var SurfPtr: Int32
        var ConstrPtr: Int32
        var NumOfSched: Int32
        var scheds: Array1D[Sched.Schedule?]

        def __init__(inout self):
            self.Name = ""
            self.SurfPtr = 0
            self.ConstrPtr = 0
            self.NumOfSched = 0
            self.scheds = Array1D[Sched.Schedule?]()

    struct GroundSurfacesData:
        var Name: String
        var ViewFactor: Float64 = 0.0
        var tempSched: Sched.Schedule? = None
        var reflSched: Sched.Schedule? = None

    struct GroundSurfacesProperty:
        var Name: String
        var NumGndSurfs: Int32 = 0
        var GndSurfs: Array1D[GroundSurfacesData]
        var SurfsTempAvg: Float64 = 0.0
        var SurfsReflAvg: Float64 = 0.0
        var SurfsViewFactorSum: Float64 = 0.0
        var IsGroundViewFactorSet: Bool = False

    struct SurfaceLocalEnvironment:
        var Name: String
        var SurfPtr: Int32 = 0
        var sunlitFracSched: Sched.Schedule? = None
        var SurroundingSurfsPtr: Int32 = 0
        var OutdoorAirNodePtr: Int32 = 0
        var GroundSurfsPtr: Int32 = 0

    struct SurroundingSurfProperty:
        var Name: String
        var ViewFactor: Float64 = 0.0
        var tempSched: Sched.Schedule? = None

    struct SurroundingSurfacesProperty:
        var Name: String
        var SkyViewFactor: Float64 = 0.0
        var GroundViewFactor: Float64 = 0.0
        var SurfsViewFactorSum: Float64 = 0.0
        var skyTempSched: Sched.Schedule? = None
        var groundTempSched: Sched.Schedule? = None
        var TotSurroundingSurface: Int32 = 0
        var IsSkyViewFactorSet: Bool = False
        var IsGroundViewFactorSet: Bool = False
        var SurroundingSurfs: Array1D[SurroundingSurfProperty]

    struct IntMassObject:
        var Name: String
        var ZoneOrZoneListName: String
        var ZoneOrZoneListPtr: Int32
        var NumOfZones: Int32
        var Construction: Int32
        var GrossArea: Float64
        var ZoneListActive: Bool
        var spaceOrSpaceListName: String
        var spaceOrSpaceListPtr: Int32
        var numOfSpaces: Int32
        var spaceListActive: Bool

        def __init__(inout self):
            self.Name = ""
            self.ZoneOrZoneListName = ""
            self.ZoneOrZoneListPtr = 0
            self.NumOfZones = 0
            self.Construction = 0
            self.GrossArea = 0.0
            self.ZoneListActive = False
            self.spaceOrSpaceListName = ""
            self.spaceOrSpaceListPtr = 0
            self.numOfSpaces = 0
            self.spaceListActive = False

    struct SurfIntConv:
        var convClass: Convect.IntConvClass = Convect.IntConvClass.Invalid
        var convClassRpt: Int32 = Int32(Convect.IntConvClass.Invalid)
        var model: Convect.HcInt = Convect.HcInt.SetByZone
        var userModelNum: Int32 = 0
        var hcModelEq: Convect.HcInt = Convect.HcInt.Invalid
        var hcModelEqRpt: Int32 = Int32(Convect.HcInt.Invalid)
        var hcUserCurveNum: Int32 = 0
        var zoneWallHeight: Float64 = 0.0
        var zonePerimLength: Float64 = 0.0
        var zoneHorizHydrDiam: Float64 = 0.0
        var windowWallRatio: Float64 = 0.0
        var windowLocation: Convect.IntConvWinLoc = Convect.IntConvWinLoc.NotSet
        var getsRadiantHeat: Bool = False
        var hasActiveInIt: Bool = False

    struct SurfExtConv:
        var convClass: Convect.ExtConvClass = Convect.ExtConvClass.Invalid
        var convClassRpt: Int32 = Int32(Convect.ExtConvClass.Invalid)
        var model: Convect.HcExt = Convect.HcExt.SetByZone
        var userModelNum: Int32 = 0
        var hfModelEq: Convect.HcExt = Convect.HcExt.Invalid
        var hfModelEqRpt: Int32 = Int32(Convect.HcExt.Invalid)
        var hfUserCurveNum: Int32 = 0
        var hnModelEq: Convect.HcExt = Convect.HcExt.Invalid
        var hnModelEqRpt: Int32 = Int32(Convect.HcExt.Invalid)
        var hnUserCurveNum: Int32 = 0
        var faceArea: Float64 = 0.0
        var facePerimeter: Float64 = 0.0
        var faceHeight: Float64 = 0.0

    # External array: cExtBoundCondition defined at file scope
    # In C++ it's Array1D_string with index range -6..0
    # We'll simulate with a list and access via helper or just define as global list and adjust.
    var cExtBoundCondition: List[String] = List[String]("KivaFoundation", "FCGround", "OSCM", "OSC", "OSC", "Ground", "ExternalEnvironment")
    # index mapping: -6 -> 0, -5 ->1, -4->2, -3->3, -2->4, -1->5, 0->6

    def SetSurfaceOutBulbTempAt(state: EnergyPlusData):
        if state.dataEnvrn.SiteTempGradient == 0.0:
            for SurfNum in range(1, state.dataSurface.TotSurfaces + 1):
                state.dataSurface.SurfOutDryBulbTemp[SurfNum - 1] = state.dataEnvrn.OutDryBulbTemp
                state.dataSurface.SurfOutWetBulbTemp[SurfNum - 1] = state.dataEnvrn.OutWetBulbTemp
        else:
            let BaseDryTemp = state.dataEnvrn.OutDryBulbTemp + state.dataEnvrn.WeatherFileTempModCoeff
            let BaseWetTemp = state.dataEnvrn.OutWetBulbTemp + state.dataEnvrn.WeatherFileTempModCoeff
            for SurfNum in range(1, state.dataSurface.TotSurfaces + 1):
                let Z = state.dataSurface.Surface[SurfNum - 1].Centroid.z
                if Z <= 0.0:
                    state.dataSurface.SurfOutDryBulbTemp[SurfNum - 1] = BaseDryTemp
                    state.dataSurface.SurfOutWetBulbTemp[SurfNum - 1] = BaseWetTemp
                else:
                    let GradientDividend = state.dataEnvrn.SiteTempGradient * Constant.EarthRadius * Z
                    let GradientDivisor = Constant.EarthRadius + Z
                    state.dataSurface.SurfOutDryBulbTemp[SurfNum - 1] = BaseDryTemp - GradientDividend / GradientDivisor
                    state.dataSurface.SurfOutWetBulbTemp[SurfNum - 1] = BaseWetTemp - GradientDividend / GradientDivisor

    def CheckSurfaceOutBulbTempAt(state: EnergyPlusData):
        var minBulb: Float64 = 0.0
        for SurfNum in range(1, state.dataSurface.TotSurfaces + 1):
            minBulb = min(minBulb, state.dataSurface.SurfOutDryBulbTemp[SurfNum - 1], state.dataSurface.SurfOutWetBulbTemp[SurfNum - 1])
            if minBulb < -100.0:
                SetOutBulbTempAt_error(state, "Surface", state.dataSurface.Surface[SurfNum - 1].Centroid.z, state.dataSurface.Surface[SurfNum - 1].Name)

    def SetSurfaceWindSpeedAt(state: EnergyPlusData):
        let fac = state.dataEnvrn.WindSpeed * state.dataEnvrn.WeatherFileWindModCoeff * pow(state.dataEnvrn.SiteWindBLHeight, -state.dataEnvrn.SiteWindExp)
        if state.dataEnvrn.SiteWindExp == 0.0:
            for SurfNum in range(1, state.dataSurface.TotSurfaces + 1):
                state.dataSurface.SurfOutWindSpeed[SurfNum - 1] = state.dataEnvrn.WindSpeed
        else:
            for SurfNum in range(1, state.dataSurface.TotSurfaces + 1):
                if not state.dataSurface.Surface[SurfNum - 1].ExtWind:
                    continue
                let Z = state.dataSurface.Surface[SurfNum - 1].Centroid.z
                if Z <= 0.0:
                    state.dataSurface.SurfOutWindSpeed[SurfNum - 1] = 0.0
                else:
                    state.dataSurface.SurfOutWindSpeed[SurfNum - 1] = fac * pow(Z, state.dataEnvrn.SiteWindExp)

    def SetSurfaceWindDirAt(state: EnergyPlusData):
        for SurfNum in range(1, state.dataSurface.TotSurfaces + 1):
            state.dataSurface.SurfOutWindDir[SurfNum - 1] = state.dataEnvrn.WindDir

    def cSurfaceClass(ClassNo: SurfaceClass) -> String:
        var ClassName: String
        if ClassNo == SurfaceClass.Wall:
            ClassName = "Wall"
        elif ClassNo == SurfaceClass.Floor:
            ClassName = "Floor"
        elif ClassNo == SurfaceClass.Roof:
            ClassName = "Roof"
        elif ClassNo == SurfaceClass.Window:
            ClassName = "Window"
        elif ClassNo == SurfaceClass.GlassDoor:
            ClassName = "Glass Door"
        elif ClassNo == SurfaceClass.Door:
            ClassName = "Door"
        elif ClassNo == SurfaceClass.TDD_Dome:
            ClassName = "TubularDaylightDome"
        elif ClassNo == SurfaceClass.TDD_Diffuser:
            ClassName = "TubularDaylightDiffuser"
        elif ClassNo == SurfaceClass.IntMass:
            ClassName = "Internal Mass"
        elif ClassNo == SurfaceClass.Shading:
            ClassName = "Shading"
        elif ClassNo == SurfaceClass.Detached_B:
            ClassName = "Detached Shading:Building"
        elif ClassNo == SurfaceClass.Detached_F:
            ClassName = "Detached Shading:Fixed"
        else:
            ClassName = "Invalid/Unknown"
        return ClassName

    def AbsFrontSide(state: EnergyPlusData, SurfNum: Int32) -> Float64:
        let AbsorptanceFromExteriorFrontSide = (state.dataSurface.SurfWinExtBeamAbsByShade[SurfNum - 1] + state.dataSurface.SurfWinExtDiffAbsByShade[SurfNum - 1]) * state.dataSurface.SurfWinShadeAbsFacFace1[SurfNum - 1]
        let AbsorptanceFromInteriorFrontSide = (state.dataSurface.SurfWinIntBeamAbsByShade[SurfNum - 1] + state.dataSurface.SurfWinIntSWAbsByShade[SurfNum - 1]) * state.dataSurface.SurfWinShadeAbsFacFace2[SurfNum - 1]
        return AbsorptanceFromExteriorFrontSide + AbsorptanceFromInteriorFrontSide

    def AbsBackSide(state: EnergyPlusData, SurfNum: Int32) -> Float64:
        let AbsorptanceFromInteriorBackSide = (state.dataSurface.SurfWinIntBeamAbsByShade[SurfNum - 1] + state.dataSurface.SurfWinIntSWAbsByShade[SurfNum - 1]) * state.dataSurface.SurfWinShadeAbsFacFace1[SurfNum - 1]
        let AbsorptanceFromExteriorBackSide = (state.dataSurface.SurfWinExtBeamAbsByShade[SurfNum - 1] + state.dataSurface.SurfWinExtDiffAbsByShade[SurfNum - 1]) * state.dataSurface.SurfWinShadeAbsFacFace2[SurfNum - 1]
        return AbsorptanceFromExteriorBackSide + AbsorptanceFromInteriorBackSide

    def GetVariableAbsorptanceSurfaceList(state: EnergyPlusData):
        if not state.dataMaterial.AnyVariableAbsorptance:
            return
        for surfNum in state.dataSurface.AllHTSurfaceList:
            let thisSurface = state.dataSurface.Surface[surfNum - 1]
            let thisConstruct = state.dataConstruction.Construct[thisSurface.Construction - 1]
            if thisConstruct.TotLayers == 0:
                continue
            if thisConstruct.LayerPoint[0] == 0:  # 0-based, careful: LayerPoint is 1-based in C++, but we assume 0-based here
                continue
            let mat = state.dataMaterial.materials[thisConstruct.LayerPoint[0] - 1]  # 0-based
            if mat.group != Material.Group.Regular:
                continue
            if mat.absorpVarCtrlSignal != Material.VariableAbsCtrlSignal.Invalid:
                if thisSurface.ExtBoundCond != ExternalEnvironment:
                    ShowWarningError(state, "MaterialProperty:VariableAbsorptance defined on an interior surface, " + thisSurface.Name + ". This VariableAbsorptance property will be ignored here")
                else:
                    state.dataSurface.AllVaryAbsOpaqSurfaceList.push_back(surfNum)
        for ConstrNum in range(1, state.dataHeatBal.TotConstructs + 1):
            let thisConstruct = state.dataConstruction.Construct[ConstrNum - 1]
            for Layer in range(2, thisConstruct.TotLayers + 1):
                let mat = state.dataMaterial.materials[thisConstruct.LayerPoint[Layer - 1] - 1]
                if mat.group != Material.Group.Regular:
                    continue
                if mat.absorpVarCtrlSignal != Material.VariableAbsCtrlSignal.Invalid:
                    ShowWarningError(state, "MaterialProperty:VariableAbsorptance defined on a inside-layer materials, " + mat.Name + ". This VariableAbsorptance property will be ignored here")

    struct MovInsul:
        var present: Bool = False
        var presentPrevTS: Bool = False
        var H: Float64 = 0.0
        var matNum: Int32 = 0
        var sched: Sched.Schedule? = None

    # End of DataSurfaces module

# Global SurfacesData struct is defined outside the module in the original C++ but within namespace EnergyPlus. In Mojo, we'll define it at file scope within the same module? Actually the original DataSurfaces.hh has the struct SurfacesData inside namespace EnergyPlus, not inside DataSurfaces namespace. But the .cc file is inside EnergyPlus::DataSurfaces. The SurfacesData struct is defined in the header as global. To keep translation faithful, we should define it at the module level (outside the DataSurfaces module) but within the same file. However, the instruction says "faithful 1:1 translation" and the header shows struct SurfacesData : BaseGlobalStruct inside namespace EnergyPlus. We'll define it at file scope after the module.

struct SurfacesData(BaseGlobalStruct):
    var TotSurfaces: Int32 = 0
    var TotWindows: Int32 = 0
    var TotStormWin: Int32 = 0
    var TotWinShadingControl: Int32 = 0
    var TotUserIntConvModels: Int32 = 0
    var TotUserExtConvModels: Int32 = 0
    var TotOSC: Int32 = 0
    var TotOSCM: Int32 = 0
    var TotExtVentCav: Int32 = 0
    var TotSurfIncSolSSG: Int32 = 0
    var TotSurfIncSolMultiplier: Int32 = 0
    var TotFenLayAbsSSG: Int32 = 0
    var TotSurfLocalEnv: Int32 = 0
    var TotSurfPropGndSurfs: Int32 = 0
    var Corner: Int32 = 0
    var MaxVerticesPerSurface: Int32 = 4
    var BuildingShadingCount: Int32 = 0
    var FixedShadingCount: Int32 = 0
    var AttachedShadingCount: Int32 = 0
    var ShadingSurfaceFirst: Int32 = 0
    var ShadingSurfaceLast: Int32 = -1
    var AspectTransform: Bool = False
    var CalcSolRefl: Bool = False
    var CCW: Bool = False
    var WorldCoordSystem: Bool = False
    var DaylRefWorldCoordSystem: Bool = False
    var MaxRecPts: Int32 = 0
    var MaxReflRays: Int32 = 0
    var GroundLevelZ: Float64 = 0.0
    var AirflowWindows: Bool = False
    var ShadingTransmittanceVaries: Bool = False
    var UseRepresentativeSurfaceCalculations: Bool = False
    var AnyMovableInsulation: Bool = False
    var AnyMovableSlat: Bool = False
    var SurfAdjacentZone: Array1D[Int32]
    var X0: Array1D[Float64]
    var Y0: Array1D[Float64]
    var Z0: Array1D[Float64]
    var RepresentativeSurfaceMap: Dict[DataSurfaces.SurfaceCalcHashKey, Int32]
    var AllHTSurfaceList: List[Int32]
    var AllExtSolarSurfaceList: List[Int32]
    var AllExtSolAndShadingSurfaceList: List[Int32]
    var AllShadowPossObstrSurfaceList: List[Int32]
    var AllIZSurfaceList: List[Int32]
    var AllHTNonWindowSurfaceList: List[Int32]
    var AllHTWindowSurfaceList: List[Int32]
    var AllExtSolWindowSurfaceList: List[Int32]
    var AllExtSolWinWithFrameSurfaceList: List[Int32]
    var AllHTKivaSurfaceList: List[Int32]
    var AllSurfaceListReportOrder: List[Int32]
    var AllVaryAbsOpaqSurfaceList: List[Int32]
    var allInsideSourceSurfaceList: List[Int32]
    var allOutsideSourceSurfaceList: List[Int32]
    var allGetsRadiantHeatSurfaceList: List[Int32]
    var intMovInsulSurfNums: List[Int32]
    var extMovInsulSurfNums: List[Int32]
    var SurfaceFilterLists: StaticArray[List[Int32], DataSurfaces.SurfaceFilter.Num]
    var SurfOutDryBulbTemp: Array1D[Float64]
    var SurfOutWetBulbTemp: Array1D[Float64]
    var SurfOutWindSpeed: Array1D[Float64]
    var SurfOutWindDir: Array1D[Float64]
    var SurfGenericContam: Array1D[Float64]
    var SurfLowTempErrCount: Array1D[Int32]
    var SurfHighTempErrCount: Array1D[Int32]
    var SurfAirSkyRadSplit: Array1D[Float64]
    var SurfSunCosHourly: Array1D[Vector3[Float64]]
    var SurfSunlitArea: Array1D[Float64]
    var SurfSunlitFrac: Array1D[Float64]
    var SurfSkySolarInc: Array1D[Float64]
    var SurfGndSolarInc: Array1D[Float64]
    var SurfBmToBmReflFacObs: Array1D[Float64]
    var SurfBmToDiffReflFacObs: Array1D[Float64]
    var SurfBmToDiffReflFacGnd: Array1D[Float64]
    var SurfSkyDiffReflFacGnd: Array1D[Float64]
    var SurfOpaqAI: Array1D[Float64]
    var SurfOpaqAO: Array1D[Float64]
    var SurfPenumbraID: Array1D[Int32]
    var SurfReflFacBmToDiffSolObs: Array2D[Float64]
    var SurfReflFacBmToDiffSolGnd: Array2D[Float64]
    var SurfReflFacBmToBmSolObs: Array2D[Float64]
    var SurfReflFacSkySolObs: Array1D[Float64]
    var SurfReflFacSkySolGnd: Array1D[Float64]
    var SurfCosIncAveBmToBmSolObs: Array2D[Float64]
    var SurfShadowDiffuseSolRefl: Array1D[Float64]
    var SurfShadowDiffuseVisRefl: Array1D[Float64]
    var SurfShadowGlazingFrac: Array1D[Float64]
    var SurfShadowGlazingConstruct: Array1D[Int32]
    var SurfShadowRecSurfNum: Array1D[Int32]
    var SurfShadowDisabledZoneList: Array1D[List[Int32]]
    var SurfEMSConstructionOverrideON: Array1D[Bool]
    var SurfEMSConstructionOverrideValue: Array1D[Int32]
    var SurfEMSOverrideIntConvCoef: Array1D[Bool]
    var SurfEMSValueForIntConvCoef: Array1D[Float64]
    var SurfEMSOverrideExtConvCoef: Array1D[Bool]
    var SurfEMSValueForExtConvCoef: Array1D[Float64]
    var SurfOutDryBulbTempEMSOverrideOn: Array1D[Bool]
    var SurfOutDryBulbTempEMSOverrideValue: Array1D[Float64]
    var SurfOutWetBulbTempEMSOverrideOn: Array1D[Bool]
    var SurfOutWetBulbTempEMSOverrideValue: Array1D[Float64]
    var SurfWindSpeedEMSOverrideOn: Array1D[Bool]
    var SurfWindSpeedEMSOverrideValue: Array1D[Float64]
    var SurfViewFactorGroundEMSOverrideOn: Array1D[Bool]
    var SurfViewFactorGroundEMSOverrideValue: Array1D[Float64]
    var SurfWindDirEMSOverrideOn: Array1D[Bool]
    var SurfWindDirEMSOverrideValue: Array1D[Float64]
    var SurfDaylightingShelfInd: Array1D[Int32]
    var SurfExtEcoRoof: Array1D[Bool]
    var SurfExtCavityPresent: Array1D[Bool]
    var SurfExtCavNum: Array1D[Int32]
    var SurfIsPV: Array1D[Bool]
    var SurfIsICS: Array1D[Bool]
    var SurfIsPool: Array1D[Bool]
    var SurfICSPtr: Array1D[Int32]
    var SurfIsRadSurfOrVentSlabOrPool: Array1D[Bool]
    var SurfTAirRef: Array1D[Int32]
    var SurfTAirRefRpt: Array1D[Int32]
    var surfIntConv: Array1D[DataSurfaces.SurfIntConv]
    var surfExtConv: Array1D[DataSurfaces.SurfExtConv]
    var SurfWinInsideGlassCondensationFlag: Array1D[Int32]
    var SurfWinInsideFrameCondensationFlag: Array1D[Int32]
    var SurfWinInsideDividerCondensationFlag: Array1D[Int32]
    var SurfWinA: Array2D[Float64]
    var SurfWinADiffFront: Array2D[Float64]
    var SurfWinACFOverlap: Array2D[Float64]
    var SurfWinTransSolar: Array1D[Float64]
    var SurfWinBmSolar: Array1D[Float64]
    var SurfWinBmBmSolar: Array1D[Float64]
    var SurfWinBmDifSolar: Array1D[Float64]
    var SurfWinDifSolar: Array1D[Float64]
    var SurfWinHeatGain: Array1D[Float64]
    var SurfWinHeatGainRep: Array1D[Float64]
    var SurfWinHeatLossRep: Array1D[Float64]
    var SurfWinGainConvGlazToZoneRep: Array1D[Float64]
    var SurfWinGainIRGlazToZoneRep: Array1D[Float64]
    var SurfWinLossSWZoneToOutWinRep: Array1D[Float64]
    var SurfWinGainFrameDividerToZoneRep: Array1D[Float64]
    var SurfWinGainConvShadeToZoneRep: Array1D[Float64]
    var SurfWinGainIRShadeToZoneRep: Array1D[Float64]
    var SurfWinGapConvHtFlowRep: Array1D[Float64]
    var SurfWinShadingAbsorbedSolar: Array1D[Float64]
    var SurfWinSysSolTransmittance: Array1D[Float64]
    var SurfWinSysSolReflectance: Array1D[Float64]
    var SurfWinSysSolAbsorptance: Array1D[Float64]
    var SurfWinTransSolarEnergy: Array1D[Float64]
    var SurfWinBmSolarEnergy: Array1D[Float64]
    var SurfWinBmBmSolarEnergy: Array1D[Float64]
    var SurfWinBmDifSolarEnergy: Array1D[Float64]
    var SurfWinDifSolarEnergy: Array1D[Float64]
    var SurfWinHeatGainRepEnergy: Array1D[Float64]
    var SurfWinHeatLossRepEnergy: Array1D[Float64]
    var SurfWinShadingAbsorbedSolarEnergy: Array1D[Float64]
    var SurfWinGapConvHtFlowRepEnergy: Array1D[Float64]
    var SurfWinHeatTransferRepEnergy: Array1D[Float64]
    var SurfWinIRfromParentZone: Array1D[Float64]
    var SurfWinFrameQRadOutAbs: Array1D[Float64]
    var SurfWinFrameQRadInAbs: Array1D[Float64]
    var SurfWinDividerQRadOutAbs: Array1D[Float64]
    var SurfWinDividerQRadInAbs: Array1D[Float64]
    var SurfWinExtBeamAbsByShade: Array1D[Float64]
    var SurfWinExtDiffAbsByShade: Array1D[Float64]
    var SurfWinIntBeamAbsByShade: Array1D[Float64]
    var SurfWinIntSWAbsByShade: Array1D[Float64]
    var SurfWinInitialDifSolAbsByShade: Array1D[Float64]
    var SurfWinIntLWAbsByShade: Array1D[Float64]
    var SurfWinConvHeatFlowNatural: Array1D[Float64]
    var SurfWinConvHeatGainToZoneAir: Array1D[Float64]
    var SurfWinRetHeatGainToZoneAir: Array1D[Float64]
    var SurfWinDividerHeatGain: Array1D[Float64]
    var SurfWinBlTsolBmBm: Array1D[Float64]
    var SurfWinBlTsolBmDif: Array1D[Float64]
    var SurfWinBlTsolDifDif: Array1D[Float64]
    var SurfWinBlGlSysTsolBmBm: Array1D[Float64]
    var SurfWinBlGlSysTsolDifDif: Array1D[Float64]
    var SurfWinScTsolBmBm: Array1D[Float64]
    var SurfWinScTsolBmDif: Array1D[Float64]
    var SurfWinScTsolDifDif: Array1D[Float64]
    var SurfWinScGlSysTsolBmBm: Array1D[Float64]
    var SurfWinScGlSysTsolDifDif: Array1D[Float64]
    var SurfWinGlTsolBmBm: Array1D[Float64]
    var SurfWinGlTsolBmDif: Array1D[Float64]
    var SurfWinGlTsolDifDif: Array1D[Float64]
    var SurfWinBmSolTransThruIntWinRep: Array1D[Float64]
    var SurfWinBmSolAbsdOutsReveal: Array1D[Float64]
    var SurfWinBmSolRefldOutsRevealReport: Array1D[Float64]
    var SurfWinBmSolAbsdInsReveal: Array1D[Float64]
    var SurfWinBmSolRefldInsReveal: Array1D[Float64]
    var SurfWinBmSolRefldInsRevealReport: Array1D[Float64]
    var SurfWinOutsRevealDiffOntoGlazing: Array1D[Float64]
    var SurfWinInsRevealDiffOntoGlazing: Array1D[Float64]
    var SurfWinInsRevealDiffIntoZone: Array1D[Float64]
    var SurfWinOutsRevealDiffOntoFrame: Array1D[Float64]
    var SurfWinInsRevealDiffOntoFrame: Array1D[Float64]
    var SurfWinInsRevealDiffOntoGlazingReport: Array1D[Float64]
    var SurfWinInsRevealDiffIntoZoneReport: Array1D[Float64]
    var SurfWinInsRevealDiffOntoFrameReport: Array1D[Float64]
    var SurfWinBmSolAbsdInsRevealReport: Array1D[Float64]
    var SurfWinBmSolTransThruIntWinRepEnergy: Array1D[Float64]
    var SurfWinBmSolRefldOutsRevealRepEnergy: Array1D[Float64]
    var SurfWinBmSolRefldInsRevealRepEnergy: Array1D[Float64]
    var SurfWinProfileAngHor: Array1D[Float64]
    var SurfWinProfileAngVert: Array1D[Float64]
    var SurfWinShadingFlag: Array1D[DataSurfaces.WinShadingType]
    var SurfWinShadingFlagEMSOn: Array1D[Bool]
    var SurfWinShadingFlagEMSValue: Array1D[Int32]
    var SurfWinStormWinFlag: Array1D[Int32]
    var SurfWinStormWinFlagPrevDay: Array1D[Int32]
    var SurfWinFracTimeShadingDeviceOn: Array1D[Float64]
    var SurfWinExtIntShadePrevTS: Array1D[DataSurfaces.WinShadingType]
    var SurfWinHasShadeOrBlindLayer: Array1D[Bool]
    var SurfWinSurfDayLightInit: Array1D[Bool]
    var SurfWinDaylFacPoint: Array1D[Int32]
    var SurfWinVisTransSelected: Array1D[Float64]
    var SurfWinSwitchingFactor: Array1D[Float64]
    var SurfWinVisTransRatio: Array1D[Float64]
    var SurfWinFrameArea: Array1D[Float64]
    var SurfWinFrameConductance: Array1D[Float64]
    var SurfWinFrameSolAbsorp: Array1D[Float64]
    var SurfWinFrameVisAbsorp: Array1D[Float64]
    var SurfWinFrameEmis: Array1D[Float64]
    var SurfWinFrEdgeToCenterGlCondRatio: Array1D[Float64]
    var SurfWinFrameEdgeArea: Array1D[Float64]
    var SurfWinFrameTempIn: Array1D[Float64]
    var SurfWinFrameTempInOld: Array1D[Float64]
    var SurfWinFrameTempSurfOut: Array1D[Float64]
    var SurfWinProjCorrFrOut: Array1D[Float64]
    var SurfWinProjCorrFrIn: Array1D[Float64]
    var SurfWinDividerType: Array1D[DataSurfaces.FrameDividerType]
    var SurfWinDividerArea: Array1D[Float64]
    var SurfWinDividerConductance: Array1D[Float64]
    var SurfWinDividerSolAbsorp: Array1D[Float64]
    var SurfWinDividerVisAbsorp: Array1D[Float64]
    var SurfWinDividerEmis: Array1D[Float64]
    var SurfWinDivEdgeToCenterGlCondRatio: Array1D[Float64]
    var SurfWinDividerEdgeArea: Array1D[Float64]
    var SurfWinDividerTempIn: Array1D[Float64]
    var SurfWinDividerTempInOld: Array1D[Float64]
    var SurfWinDividerTempSurfOut: Array1D[Float64]
    var SurfWinProjCorrDivOut: Array1D[Float64]
    var SurfWinProjCorrDivIn: Array1D[Float64]
    var SurfWinShadeAbsFacFace1: Array1D[Float64]
    var SurfWinShadeAbsFacFace2: Array1D[Float64]
    var SurfWinConvCoeffWithShade: Array1D[Float64]
    var SurfWinOtherConvHeatGain: Array1D[Float64]
    var SurfWinEffInsSurfTemp: Array1D[Float64]
    var SurfWinTotGlazingThickness: Array1D[Float64]
    var SurfWinTanProfileAngHor: Array1D[Float64]
    var SurfWinTanProfileAngVert: Array1D[Float64]
    var SurfWinInsideSillDepth: Array1D[Float64]
    var SurfWinInsideReveal: Array1D[Float64]
    var SurfWinInsideSillSolAbs: Array1D[Float64]
    var SurfWinInsideRevealSolAbs: Array1D[Float64]
    var SurfWinOutsideRevealSolAbs: Array1D[Float64]
    var SurfWinAirflowSource: Array1D[DataSurfaces.WindowAirFlowSource]
    var SurfWinAirflowDestination: Array1D[DataSurfaces.WindowAirFlowDestination]
    var SurfWinAirflowReturnNodePtr: Array1D[Int32]
    var SurfWinMaxAirflow: Array1D[Float64]
    var SurfWinAirflowControlType: Array1D[DataSurfaces.WindowAirFlowControlType]
    var SurfWinAirflowHasSchedule: Array1D[Bool]
    var SurfWinAirflowScheds: Array1D[Sched.Schedule?]
    var SurfWinAirflowThisTS: Array1D[Float64]
    var SurfWinTAirflowGapOutlet: Array1D[Float64]
    var SurfWinWindowCalcIterationsRep: Array1D[Int32]
    var SurfWinVentingOpenFactorMultRep: Array1D[Float64]
    var SurfWinInsideTempForVentingRep: Array1D[Float64]
    var SurfWinVentingAvailabilityRep: Array1D[Float64]
    var SurfWinSkyGndSolarInc: Array1D[Float64]
    var SurfWinBmGndSolarInc: Array1D[Float64]
    var SurfWinSolarDiffusing: Array1D[Bool]
    var SurfWinFrameHeatGain: Array1D[Float64]
    var SurfWinFrameHeatLoss: Array1D[Float64]
    var SurfWinDividerHeatLoss: Array1D[Float64]
    var SurfWinTCLayerTemp: Array1D[Float64]
    var SurfWinSpecTemp: Array1D[Float64]
    var SurfWinWindowModelType: Array1D[DataSurfaces.WindowModel]
    var SurfWinTDDPipeNum: Array1D[Float64]
    var SurfWinStormWinConstr: Array1D[Int32]
    var SurfActiveConstruction: Array1D[Int32]
    var SurfWinActiveShadedConstruction: Array1D[Int32]
    var intMovInsuls: Array1D[DataSurfaces.MovInsul]
    var extMovInsuls: Array1D[DataSurfaces.MovInsul]
    var Surface: Array1D[DataSurfaces.SurfaceData]
    var SurfaceWindow: Array1D[DataSurfaces.SurfaceWindowCalc]
    var surfShades: Array1D[DataSurfaces.SurfaceShade]
    var FrameDivider: Array1D[DataSurfaces.FrameDividerProperties]
    var StormWindow: Array1D[DataSurfaces.StormWindowData]
    var WindowShadingControl: Array1D[DataSurfaces.WindowShadingControlData]
    var OSC: Array1D[DataSurfaces.OSCData]
    var OSCM: Array1D[DataSurfaces.OSCMData]
    var userIntConvModels: Array1D[DataSurfaces.ConvectionCoefficient]
    var userExtConvModels: Array1D[DataSurfaces.ConvectionCoefficient]
    var ShadeV: Array1D[DataSurfaces.ShadingVertexData]
    var SurfIncSolSSG: Array1D[DataSurfaces.SurfaceSolarIncident]
    var SurfIncSolMultiplier: Array1D[DataSurfaces.SurfaceIncidentSolarMultiplier]
    var FenLayAbsSSG: Array1D[DataSurfaces.FenestrationSolarAbsorbed]
    var SurfLocalEnvironment: Array1D[DataSurfaces.SurfaceLocalEnvironment]
    var SurroundingSurfsProperty: Array1D[DataSurfaces.SurroundingSurfacesProperty]
    var IntMassObjects: Array1D[DataSurfaces.IntMassObject]
    var GroundSurfsProperty: Array1D[DataSurfaces.GroundSurfacesProperty]

    def init_constant_state(inout self, state: EnergyPlusData):

    def init_state(inout self, state: EnergyPlusData):

    def clear_state(inout self):
        # In Mojo we can't call placement new, but we can reinitialize fields to default.
        # For simplicity, we'll just set default values. Since this is large, we'll assume it's handled elsewhere.
        # Here we just reset to zero/empty.
        self = Self()