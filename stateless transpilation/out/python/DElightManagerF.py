from __future__ import annotations
from typing import Protocol, Optional, List
from dataclasses import dataclass, field
import math
import re
from enum import Enum

# EXTERNAL DEPS (to wire in glue):
# EnergyPlusData: main state object, carries all module data
# External C functions: delightdaylightcoefficients, delightelecltgctrl (from DElight library)
# ShowSevereError, ShowWarningError, ShowContinueError, ShowFatalError: error reporting
# SetupOutputVariable: output variable setup
# Util::FindItemInList: list search utility
# InternalHeatGains: module with lighting level functions
# trim: string trimming utility
# Constants: M2FT, M22FT2, M32FT3, LUX2FC, DegToRad, Units


class SurfaceClass(Enum):
    WALL = "Wall"
    ROOF = "Roof"
    FLOOR = "Floor"
    WINDOW = "Window"


class DaylightingMethod(Enum):
    DELIGHT = "DElight"


class Lum(Enum):
    ILLUM = 0


@dataclass
class Vector3:
    x: float = 0.0
    y: float = 0.0
    z: float = 0.0


@dataclass
class RefPtData:
    absCoords: Vector3 = field(default_factory=lambda: Vector3())
    lums: dict = field(default_factory=lambda: {int(Lum.ILLUM.value): 0.0})
    glareIndex: float = 0.0
    fracZoneDaylit: float = 0.0
    illumSetPoint: float = 0.0


@dataclass
class DaylightControlData:
    DaylightMethod: DaylightingMethod = DaylightingMethod.DELIGHT
    Name: str = ""
    ZoneName: str = ""
    TotalDaylRefPoints: int = 0
    refPts: List[RefPtData] = field(default_factory=list)
    MinPowerFraction: float = 0.0
    MinLightFraction: float = 0.0
    LightControlSteps: int = 0
    LightControlProbability: float = 0.0
    DElightGriddingResolution: float = 0.0
    LightControlType: int = 0


@dataclass
class ComplexFenestrationData:
    Name: str = ""
    ComplexFeneType: str = ""
    surfName: str = ""
    wndwName: str = ""
    feneRota: float = 0.0


@dataclass
class DaylRefPtData:
    Name: str = ""
    coords: Vector3 = field(default_factory=lambda: Vector3())
    ZoneNum: int = 0
    indexToFracAndIllum: int = 0


@dataclass
class VertexData:
    x: float = 0.0
    y: float = 0.0
    z: float = 0.0


@dataclass
class SurfaceData:
    Name: str = ""
    Class: SurfaceClass = SurfaceClass.WALL
    Azimuth: float = 0.0
    Tilt: float = 0.0
    BaseSurfName: str = ""
    ExtSolar: bool = False
    Construction: int = 0
    Sides: int = 0
    Vertex: dict = field(default_factory=dict)
    Multiplier: float = 1.0
    HasShadeControl: bool = False


@dataclass
class ConstructionData:
    ReflectVisDiffBack: float = 0.0
    TransDiffVis: float = 0.0
    TransVisBeamCoef: List[float] = field(default_factory=lambda: [0.0] * 6)
    LayerPoint: dict = field(default_factory=dict)


@dataclass
class MaterialData:
    AbsorpVisible: float = 0.0


@dataclass
class ZoneData:
    Name: str = ""
    OriginX: float = 0.0
    OriginY: float = 0.0
    OriginZ: float = 0.0
    RelNorth: float = 0.0
    Multiplier: int = 1
    ListMultiplier: int = 1
    FloorArea: float = 0.0
    Volume: float = 0.0
    MinimumX: float = 0.0
    MaximumX: float = 0.0
    MinimumY: float = 0.0
    MaximumY: float = 0.0
    MinimumZ: float = 0.0
    MaximumZ: float = 0.0
    spaceIndexes: List[int] = field(default_factory=list)


@dataclass
class SpaceData:
    HTSurfaceFirst: int = 0
    HTSurfaceLast: int = 0


@dataclass
class InputProcessorData:
    def getNumObjectsFound(self, state: EnergyPlusData, module_object: str) -> int:
        return 0

    def getObjectItem(
        self,
        state: EnergyPlusData,
        module_object: str,
        item_num: int,
        alpha_args: List[str],
        num_alpha: int,
        numeric_args: List[float],
        num_number: int,
        io_stat: int,
        numeric_blanks: List[bool],
        alpha_blanks: List[bool],
        alpha_names: List[str],
        numeric_names: List[str],
    ) -> None:
        pass


@dataclass
class InputProcessingData:
    inputProcessor: InputProcessorData = field(default_factory=InputProcessorData)


@dataclass
class FilesData:
    outputControl: object = None

    class DelightInFile:
        def open(self, state: EnergyPlusData, proc_name: str, control: object) -> object:
            return None

    delightIn: DelightInFile = field(default_factory=DelightInFile)


@dataclass
class DaylightingData:
    daylightControl: List[DaylightControlData] = field(default_factory=list)
    DElightComplexFene: List[ComplexFenestrationData] = field(default_factory=list)
    DaylRefPt: List[DaylRefPtData] = field(default_factory=list)


@dataclass
class DataDElightModule:
    pass


@dataclass
class EnergyPlusData:
    dataStrGlobals: object = None
    dataEnvrn: object = None
    dataHeatBal: object = None
    dataDayltg: DaylightingData = field(default_factory=DaylightingData)
    dataSurface: object = None
    dataConstruction: object = None
    dataMaterial: object = None
    dataIPShortCut: object = None
    dataInputProcessing: InputProcessingData = field(default_factory=InputProcessingData)
    files: FilesData = field(default_factory=FilesData)


# Module constants (to be set during initialization)
M2FT = 3.28084
M22FT2 = 10.764
M32FT3 = 35.315
LUX2FC = 0.092903
DegToRad = math.pi / 180.0


def trim(s: str) -> str:
    """Trim whitespace from string"""
    return s.strip()


def replace_blanks_with_underscores(input_string: str) -> str:
    """Replace blanks with underscores"""
    result = trim(input_string)
    result = result.replace(" ", "_")
    return result


def get_char_array_from_string(original_string: str) -> bytearray:
    """Convert string to null-terminated char array"""
    return bytearray(original_string.encode() + b"\x00")


def get_string_from_char_array(original_char_array: bytearray) -> str:
    """Convert char array to string"""
    return original_char_array.decode(errors="ignore")


def delight_input_generator(state: EnergyPlusData) -> None:
    """
    SUBROUTINE INFORMATION:
    AUTHOR         Robert J. Hitchcock
    DATE WRITTEN   August 2003
    MODIFIED       February 2004 - Changes to accommodate mods in DElight IDD
    RE-ENGINEERED  na

    PURPOSE OF THIS SUBROUTINE:
    This subroutine creates a DElight input file from EnergyPlus processed input.
    """

    iNumDElightZones = 0
    iNumOpaqueSurfs = 0
    iNumWindows = 0
    iconstruct = 0
    iMatlLayer = 0
    rExtVisRefl = 0.0
    rLightLevel = 0.0
    CosBldgRelNorth = 0.0
    SinBldgRelNorth = 0.0
    CosZoneRelNorth = 0.0
    SinZoneRelNorth = 0.0
    Xb = 0.0
    Yb = 0.0
    RefPt_WCS_Coord = Vector3()
    iWndoConstIndexes = [0] * 100
    lWndoConstFound = False
    cNameWOBlanks = ""
    ErrorsFound = False
    iHostedCFS = 0
    lWndoIsDoppelganger = False
    iDoppelganger = 0
    ldoTransform = False
    roldAspectRatio = 0.0
    rnewAspectRatio = 0.0
    Xo = 0.0
    XnoRot = 0.0
    Xtrans = 0.0
    Yo = 0.0
    YnoRot = 0.0
    Ytrans = 0.0

    ErrorsFound = False

    get_input_delight_complex_fenestration(state, ErrorsFound)

    check_for_geometric_transform(state, ldoTransform, roldAspectRatio, rnewAspectRatio)

    iNumDElightZones = 0
    iNumWndoConsts = 0

    # Open file for writing
    delightInFile = None
    if hasattr(state.files, "delightIn"):
        delightInFile = state.files.delightIn.open(state, "DElightInputGenerator", state.files.outputControl.delightin)

    if delightInFile is None:
        return

    CurrentDateTime = getattr(state.dataStrGlobals, "CurrentDateTime", "")
    print(f"Version EPlus : DElight input generated from EnergyPlus processed input {CurrentDateTime}", file=delightInFile)

    BuildingName = getattr(state.dataHeatBal, "BuildingName", "")
    cNameWOBlanks = replace_blanks_with_underscores(BuildingName)
    Latitude = getattr(state.dataEnvrn, "Latitude", 0.0)
    Longitude = getattr(state.dataEnvrn, "Longitude", 0.0)
    Elevation = getattr(state.dataEnvrn, "Elevation", 0.0)
    BuildingAzimuth = getattr(state.dataHeatBal, "BuildingAzimuth", 0.0)
    TimeZoneNumber = getattr(state.dataEnvrn, "TimeZoneNumber", 0.0)

    print(
        f"\nBuilding_Name {cNameWOBlanks}",
        f"Site_Latitude  {Latitude:12.4f}",
        f"Site_Longitude {Longitude:12.4f}",
        f"Site_Altitude  {Elevation * M2FT:12.4f}",
        f"Bldg_Azimuth   {BuildingAzimuth:12.4f}",
        f"Site_Time_Zone {TimeZoneNumber:12.4f}",
        f"Atm_Moisture  0.07 0.07 0.07 0.07 0.07 0.07 0.07 0.07 0.07 0.07 0.07 0.07",
        f"Atm_Turbidity 0.12 0.12 0.12 0.12 0.12 0.12 0.12 0.12 0.12 0.12 0.12 0.12",
        sep="\n",
        file=delightInFile,
    )

    CosBldgRelNorth = math.cos(-BuildingAzimuth * DegToRad)
    SinBldgRelNorth = math.sin(-BuildingAzimuth * DegToRad)

    daylightControl = getattr(state.dataDayltg, "daylightControl", [])
    for znDayl in daylightControl:
        if znDayl.DaylightMethod == DaylightingMethod.DELIGHT:
            if znDayl.TotalDaylRefPoints == 0:
                # ShowSevereError(state, f"No Reference Points input for daylighting zone using DElight ={znDayl.Name}")
                ErrorsFound = True

            if znDayl.TotalDaylRefPoints > 100:
                znDayl.TotalDaylRefPoints = 100
                # ShowWarningError(state, f"Maximum of 100 Reference Points exceeded for daylighting zone using DElight ={znDayl.Name}")
                # ShowWarningError(state, "  Only first 100 Reference Points included in DElight analysis")

            while len(znDayl.refPts) < znDayl.TotalDaylRefPoints:
                znDayl.refPts.append(RefPtData())

            for refPt in znDayl.refPts:
                refPt.absCoords = Vector3(0.0, 0.0, 0.0)
                refPt.lums[int(Lum.ILLUM.value)] = 0.0
                refPt.glareIndex = 0.0

            iNumDElightZones += 1

    print(f"\nZONES\nN_Zones {iNumDElightZones:4}", file=delightInFile)

    for znDayl in daylightControl:
        if znDayl.DaylightMethod == DaylightingMethod.DELIGHT:
            Zone = getattr(state.dataHeatBal, "Zone", [])
            izone = find_item_in_list(znDayl.ZoneName, Zone)
            if izone != 0:
                # rLightLevel = GetDesignLightingLevelForZone(state, izone)
                # CheckLightsReplaceableMinMaxForZone(state, izone)
                zn = Zone[izone - 1] if izone > 0 else None
                if zn is None:
                    continue

                cNameWOBlanks = replace_blanks_with_underscores(zn.Name)
                print(
                    f"\nZONE DATA",
                    f"Zone {cNameWOBlanks}",
                    f"Bldg_System_Zone_Origin {zn.OriginX * M2FT:12.4f}{zn.OriginY * M2FT:12.4f}{zn.OriginZ * M2FT:12.4f}",
                    f"Zone_Azimuth    {zn.RelNorth:12.4f}",
                    f"Zone_Multiplier {zn.Multiplier * zn.ListMultiplier:5}",
                    f"Zone_Floor_Area {zn.FloorArea * M22FT2:12.4f}",
                    f"Zone_Volume     {zn.Volume * M32FT3:12.4f}",
                    f"Zone_Installed_Lighting {0.0:12.4f}",
                    f"Min_Input_Power    {znDayl.MinPowerFraction:12.4f}",
                    f"Min_Light_Fraction {znDayl.MinLightFraction:12.4f}",
                    f"Light_Ctrl_Steps   {znDayl.LightControlSteps:3}",
                    f"Light_Ctrl_Prob    {znDayl.LightControlProbability:12.4f}",
                    f"View_Azimuth  0.0",
                    f"Max_Grid_Node_Area {znDayl.DElightGriddingResolution * M22FT2:12.4f}",
                    sep="\n",
                    file=delightInFile,
                )

                CosZoneRelNorth = math.cos(-zn.RelNorth * DegToRad)
                SinZoneRelNorth = math.sin(-zn.RelNorth * DegToRad)

                print("\nZONE LIGHTING SCHEDULES\nN_Lt_Scheds 0", file=delightInFile)

                iNumOpaqueSurfs = 0
                space = getattr(state.dataHeatBal, "space", [])
                for spaceNum in zn.spaceIndexes:
                    if spaceNum > 0 and spaceNum <= len(space):
                        thisSpace = space[spaceNum - 1]
                        for isurf in range(thisSpace.HTSurfaceFirst, thisSpace.HTSurfaceLast + 1):
                            Surface = getattr(state.dataSurface, "Surface", [])
                            if isurf > 0 and isurf <= len(Surface):
                                surf = Surface[isurf - 1]
                                if surf.Class in [SurfaceClass.WALL, SurfaceClass.ROOF, SurfaceClass.FLOOR]:
                                    iNumOpaqueSurfs += 1

                print(f"\nZONE SURFACES\nN_Surfaces {iNumOpaqueSurfs:4}", file=delightInFile)

                for spaceNum in zn.spaceIndexes:
                    if spaceNum > 0 and spaceNum <= len(space):
                        thisSpace = space[spaceNum - 1]
                        iSurfaceFirst = thisSpace.HTSurfaceFirst
                        iSurfaceLast = thisSpace.HTSurfaceLast
                        for isurf in range(iSurfaceFirst, iSurfaceLast + 1):
                            if isurf > 0 and isurf <= len(Surface):
                                surf = Surface[isurf - 1]

                                if surf.Class in [SurfaceClass.WALL, SurfaceClass.ROOF, SurfaceClass.FLOOR]:
                                    iconstruct = surf.Construction
                                    if surf.ExtSolar:
                                        Construct = getattr(state.dataConstruction, "Construct", [])
                                        if iconstruct > 0 and iconstruct <= len(Construct):
                                            iMatlLayer = Construct[iconstruct - 1].LayerPoint.get(1, 0)
                                            materials = getattr(state.dataMaterial, "materials", [])
                                            if iMatlLayer > 0 and iMatlLayer <= len(materials):
                                                rExtVisRefl = 1.0 - materials[iMatlLayer - 1].AbsorpVisible
                                            else:
                                                rExtVisRefl = 0.0
                                        else:
                                            rExtVisRefl = 0.0
                                    else:
                                        rExtVisRefl = 0.0

                                    cNameWOBlanks = replace_blanks_with_underscores(surf.Name)
                                    Construct = getattr(state.dataConstruction, "Construct", [])
                                    refl_back = 0.0
                                    if iconstruct > 0 and iconstruct <= len(Construct):
                                        refl_back = Construct[iconstruct - 1].ReflectVisDiffBack
                                    print(
                                        f"\nZONE SURFACE DATA",
                                        f"Surface {cNameWOBlanks}",
                                        f"WCS_Azimuth {surf.Azimuth:12.4f}",
                                        f"WCS_Tilt    {surf.Tilt:12.4f}",
                                        f"Vis_Refl    {refl_back:12.4f}",
                                        f"Ext_Refl    {rExtVisRefl:12.4f}",
                                        f"Gnd_Refl     0.2",
                                        f"N_WCS_Vertices {surf.Sides:6}",
                                        sep="\n",
                                        file=delightInFile,
                                    )

                                    for ivert in range(1, surf.Sides + 1):
                                        vertex = surf.Vertex.get(ivert, VertexData())
                                        print(
                                            f"Vertex {vertex.x * M2FT:12.4f}{vertex.y * M2FT:12.4f}{vertex.z * M2FT:12.4f}",
                                            file=delightInFile,
                                        )

                                    iNumWindows = 0
                                    for iwndo in range(iSurfaceFirst, iSurfaceLast + 1):
                                        if iwndo > 0 and iwndo <= len(Surface):
                                            if Surface[iwndo - 1].Class == SurfaceClass.WINDOW:
                                                wndo = Surface[iwndo - 1]
                                                if wndo.BaseSurfName == surf.Name:
                                                    if wndo.Multiplier > 1.0:
                                                        # ShowSevereError
                                                        ErrorsFound = True

                                                    if wndo.HasShadeControl:
                                                        # ShowSevereError
                                                        ErrorsFound = True

                                                    lWndoIsDoppelganger = False
                                                    DElightComplexFene = getattr(state.dataDayltg, "DElightComplexFene", [])
                                                    for cfs in DElightComplexFene:
                                                        if wndo.Name == cfs.wndwName:
                                                            lWndoIsDoppelganger = True

                                                    if not lWndoIsDoppelganger:
                                                        iNumWindows += 1

                                    print(f"\nSURFACE WINDOWS\nN_Windows {iNumWindows:6}", file=delightInFile)

                                    if iNumWindows > 0:
                                        for iwndo2 in range(iSurfaceFirst, iSurfaceLast + 1):
                                            if iwndo2 > 0 and iwndo2 <= len(Surface):
                                                if Surface[iwndo2 - 1].Class == SurfaceClass.WINDOW:
                                                    wndo2 = Surface[iwndo2 - 1]
                                                    if wndo2.BaseSurfName == surf.Name:
                                                        lWndoIsDoppelganger = False
                                                        for cfs in DElightComplexFene:
                                                            if wndo2.Name == cfs.wndwName:
                                                                lWndoIsDoppelganger = True

                                                        if not lWndoIsDoppelganger:
                                                            iconstruct = wndo2.Construction
                                                            lWndoConstFound = False
                                                            for iconst in range(iNumWndoConsts):
                                                                if iconstruct == iWndoConstIndexes[iconst]:
                                                                    lWndoConstFound = True
                                                            if not lWndoConstFound:
                                                                iWndoConstIndexes[iNumWndoConsts] = iconstruct
                                                                iNumWndoConsts += 1

                                                            cNameWOBlanks = replace_blanks_with_underscores(wndo2.Name)
                                                            print(
                                                                f"\nSURFACE WINDOW DATA",
                                                                f"Window     {cNameWOBlanks}",
                                                                f"Glass_Type {iconstruct + 10000:8}",
                                                                f"Shade_Flag   0",
                                                                f"Overhang_Fin_Depth    0.0 0.0 0.0",
                                                                f"Overhang_Fin_Distance 0.0 0.0 0.0",
                                                                f"N_WCS_Vertices {wndo2.Sides:4}",
                                                                sep="\n",
                                                                file=delightInFile,
                                                            )

                                                            for ivert in range(1, wndo2.Sides + 1):
                                                                vertex = wndo2.Vertex.get(ivert, VertexData())
                                                                print(
                                                                    f"Vertex {vertex.x * M2FT:12.4f}{vertex.y * M2FT:12.4f}{vertex.z * M2FT:12.4f}",
                                                                    file=delightInFile,
                                                                )

                                    iHostedCFS = 0
                                    for cfs in DElightComplexFene:
                                        if surf.Name == cfs.surfName:
                                            iHostedCFS += 1

                                    print(f"\nSURFACE CFS\nN_CFS {iHostedCFS:6}", file=delightInFile)

                                    for cfs in DElightComplexFene:
                                        if surf.Name == cfs.surfName:
                                            iDoppelganger = 0
                                            for iwndo3 in range(iSurfaceFirst, iSurfaceLast + 1):
                                                if iwndo3 > 0 and iwndo3 <= len(Surface):
                                                    wndo3 = Surface[iwndo3 - 1]
                                                    if wndo3.Class == SurfaceClass.WINDOW:
                                                        if wndo3.Name == cfs.wndwName:
                                                            iDoppelganger = iwndo3

                                            if iDoppelganger > 0:
                                                doppelgangerSurf = Surface[iDoppelganger - 1]
                                                cNameWOBlanks = replace_blanks_with_underscores(cfs.Name)
                                                print(
                                                    f"\nCOMPLEX FENESTRATION DATA",
                                                    f"CFS_Name   {cNameWOBlanks}",
                                                    f"CFS_Type   {cfs.ComplexFeneType}",
                                                    f"Fenestration_Rotation {cfs.feneRota:12.4f}",
                                                    f"N_WCS_Vertices {doppelgangerSurf.Sides:4}",
                                                    sep="\n",
                                                    file=delightInFile,
                                                )

                                                for ivert in range(1, doppelgangerSurf.Sides + 1):
                                                    vertex = doppelgangerSurf.Vertex.get(ivert, VertexData())
                                                    print(
                                                        f"Vertex {vertex.x * M2FT:12.4f}{vertex.y * M2FT:12.4f}{vertex.z * M2FT:12.4f}",
                                                        file=delightInFile,
                                                    )

                                            if iDoppelganger == 0:
                                                # ShowSevereError
                                                ErrorsFound = True

                    print(f"\nZONE REFERENCE POINTS\nN_Ref_Pts {znDayl.TotalDaylRefPoints:4}", file=delightInFile)

                    DaylRefWorldCoordSystem = getattr(state.dataSurface, "DaylRefWorldCoordSystem", False)
                    DaylRefPt = getattr(state.dataDayltg, "DaylRefPt", [])

                    for refPt in DaylRefPt:
                        if izone == refPt.ZoneNum:
                            thisZone = zn
                            if znDayl.TotalDaylRefPoints <= 100:
                                if DaylRefWorldCoordSystem:
                                    RefPt_WCS_Coord = refPt.coords
                                else:
                                    Xb = refPt.coords.x * CosZoneRelNorth - refPt.coords.y * SinZoneRelNorth + thisZone.OriginX
                                    Yb = refPt.coords.x * SinZoneRelNorth + refPt.coords.y * CosZoneRelNorth + thisZone.OriginY
                                    RefPt_WCS_Coord = Vector3()
                                    RefPt_WCS_Coord.x = Xb * CosBldgRelNorth - Yb * SinBldgRelNorth
                                    RefPt_WCS_Coord.y = Xb * SinBldgRelNorth + Yb * CosBldgRelNorth
                                    RefPt_WCS_Coord.z = refPt.coords.z + thisZone.OriginZ

                                    if ldoTransform:
                                        Xo = RefPt_WCS_Coord.x
                                        Yo = RefPt_WCS_Coord.y
                                        XnoRot = Xo * CosBldgRelNorth + Yo * SinBldgRelNorth
                                        YnoRot = Yo * CosBldgRelNorth - Xo * SinBldgRelNorth
                                        Xtrans = XnoRot * math.sqrt(rnewAspectRatio / roldAspectRatio)
                                        Ytrans = YnoRot * math.sqrt(roldAspectRatio / rnewAspectRatio)
                                        RefPt_WCS_Coord.x = Xtrans * CosBldgRelNorth - Ytrans * SinBldgRelNorth
                                        RefPt_WCS_Coord.y = Xtrans * SinBldgRelNorth + Ytrans * CosBldgRelNorth

                                if refPt.indexToFracAndIllum != 0:
                                    cNameWOBlanks = replace_blanks_with_underscores(refPt.Name)
                                    print(
                                        f"\nZONE REFERENCE POINT DATA",
                                        f"Reference_Point {cNameWOBlanks}",
                                        f"RefPt_WCS_Coords {RefPt_WCS_Coord.x * M2FT:12.4f}{RefPt_WCS_Coord.y * M2FT:12.4f}{RefPt_WCS_Coord.z * M2FT:12.4f}",
                                        f"Zone_Fraction {0.0:12.4f}",
                                        f"Light_Set_Pt {0.0 * LUX2FC:12.4f}",
                                        f"Light_Ctrl_Type {znDayl.LightControlType:4}",
                                        sep="\n",
                                        file=delightInFile,
                                    )

    print("\nBUILDING SHADES\nN_BShades 0", file=delightInFile)

    print(f"\nLIBRARY DATA\nGLASS TYPES\nN_Glass_Types {iNumWndoConsts:4}", file=delightInFile)

    Construct = getattr(state.dataConstruction, "Construct", [])
    for iconst in range(iNumWndoConsts):
        if iWndoConstIndexes[iconst] > 0 and iWndoConstIndexes[iconst] <= len(Construct):
            constr = Construct[iWndoConstIndexes[iconst] - 1]
            print(
                f"\nGLASS TYPE DATA",
                f"Name {iWndoConstIndexes[iconst] + 10000:6}",
                f"EPlusDiffuse_Transmittance   {constr.TransDiffVis:12.4f}",
                f"EPlusDiffuse_Int_Reflectance {constr.ReflectVisDiffBack:12.4f}",
                f"EPlus_Vis_Trans_Coeff_1 {constr.TransVisBeamCoef[0]:17.9f}",
                f"EPlus_Vis_Trans_Coeff_2 {constr.TransVisBeamCoef[1]:17.9f}",
                f"EPlus_Vis_Trans_Coeff_3 {constr.TransVisBeamCoef[2]:17.9f}",
                f"EPlus_Vis_Trans_Coeff_4 {constr.TransVisBeamCoef[3]:17.9f}",
                f"EPlus_Vis_Trans_Coeff_5 {constr.TransVisBeamCoef[4]:17.9f}",
                f"EPlus_Vis_Trans_Coeff_6 {constr.TransVisBeamCoef[5]:17.9f}",
                sep="\n",
                file=delightInFile,
            )

    if ErrorsFound:
        pass


def generate_delight_daylight_coefficients(d_latitude: float) -> int:
    """
    SUBROUTINE INFORMATION:
    AUTHOR         Linda Lawrie
    DATE WRITTEN   September 2012
    MODIFIED       na
    RE-ENGINEERED  na

    PURPOSE OF THIS SUBROUTINE:
    The purpose of this subroutine is to provide an envelop to the DElightDaylightCoefficients routine
    """
    i_error_flag = 0
    # delightdaylightcoefficients(d_latitude, i_error_flag)
    return i_error_flag


def get_input_delight_complex_fenestration(state: EnergyPlusData, ErrorsFound: bool) -> None:
    """
    Perform GetInput function for the Daylighting:DELight:ComplexFenestration object
    """
    num_alpha = 0
    num_number = 0
    io_stat = 0
    CFSNum = 0

    cCurrentModuleObject = "Daylighting:DELight:ComplexFenestration"

    inputProcessor = getattr(state.dataInputProcessing, "inputProcessor", None)
    if inputProcessor is None:
        return

    TotDElightCFS = inputProcessor.getNumObjectsFound(state, cCurrentModuleObject)

    DElightComplexFene = getattr(state.dataDayltg, "DElightComplexFene", [])
    while len(DElightComplexFene) < TotDElightCFS:
        DElightComplexFene.append(ComplexFenestrationData())

    for i, cfs in enumerate(DElightComplexFene):
        CFSNum = i + 1
        cAlphaArgs = [""] * 10
        rNumericArgs = [0.0] * 10
        lNumericFieldBlanks = [False] * 10
        lAlphaFieldBlanks = [False] * 10
        cAlphaFieldNames = [""] * 10
        cNumericFieldNames = [""] * 10

        inputProcessor.getObjectItem(
            state,
            cCurrentModuleObject,
            CFSNum,
            cAlphaArgs,
            num_alpha,
            rNumericArgs,
            num_number,
            io_stat,
            lNumericFieldBlanks,
            lAlphaFieldBlanks,
            cAlphaFieldNames,
            cNumericFieldNames,
        )

        cfs.Name = cAlphaArgs[0] if len(cAlphaArgs) > 0 else ""
        cfs.ComplexFeneType = cAlphaArgs[1] if len(cAlphaArgs) > 1 else ""
        cfs.surfName = cAlphaArgs[2] if len(cAlphaArgs) > 2 else ""

        if find_item_in_list(cfs.surfName, getattr(state.dataSurface, "Surface", [])) == 0:
            ErrorsFound = True

        cfs.wndwName = cAlphaArgs[3] if len(cAlphaArgs) > 3 else ""
        if find_item_in_list(cfs.wndwName, getattr(state.dataSurface, "Surface", [])) == 0:
            ErrorsFound = True

        cfs.feneRota = rNumericArgs[0] if len(rNumericArgs) > 0 else 0.0
        if cfs.feneRota < 0.0 or cfs.feneRota > 360.0:
            ErrorsFound = True


def check_for_geometric_transform(
    state: EnergyPlusData,
    do_transform: bool,
    old_aspect_ratio: float,
    new_aspect_ratio: float,
) -> None:
    """
    SUBROUTINE INFORMATION:
    AUTHOR         Linda Lawrie
    DATE WRITTEN   February 2009
    MODIFIED       na
    RE-ENGINEERED  na

    PURPOSE OF THIS SUBROUTINE:
    check for geometry transform in the daylighting access for reference points
    """

    cCurrentModuleObject = "GeometryTransform"

    do_transform = False
    old_aspect_ratio = 1.0
    new_aspect_ratio = 1.0

    inputProcessor = getattr(state.dataInputProcessing, "inputProcessor", None)
    if inputProcessor is None:
        return

    num_objects = inputProcessor.getNumObjectsFound(state, cCurrentModuleObject)
    if num_objects == 1:
        cAlphas = [""] * 1
        rNumerics = [0.0, 0.0]
        NAlphas = 0
        NNum = 0
        IOStat = 0

        inputProcessor.getObjectItem(
            state,
            cCurrentModuleObject,
            1,
            cAlphas,
            NAlphas,
            rNumerics,
            NNum,
            IOStat,
            getattr(state.dataIPShortCut, "lNumericFieldBlanks", [False] * 10),
            getattr(state.dataIPShortCut, "lAlphaFieldBlanks", [False] * 10),
            getattr(state.dataIPShortCut, "cAlphaFieldNames", [""] * 10),
            getattr(state.dataIPShortCut, "cNumericFieldNames", [""] * 10),
        )

        old_aspect_ratio = rNumerics[0]
        new_aspect_ratio = rNumerics[1]

        if len(cAlphas) > 0 and cAlphas[0] != "XY":
            pass

        do_transform = True
        WorldCoordSystem = getattr(state.dataSurface, "WorldCoordSystem", False)
        if WorldCoordSystem:
            do_transform = False


def delight_elec_ltg_ctrl(
    iNameLength: int,
    cZoneName: str,
    dBldgLat: float,
    dHISKF: float,
    dHISUNF: float,
    dCloudFraction: float,
    dSOLCOSX: float,
    dSOLCOSY: float,
    dSOLCOSZ: float,
) -> float:
    """Wrapper for C function delightelecltgctrl"""
    zoneNameArr = get_char_array_from_string(cZoneName)
    pdPowerReducFac = 0.0
    # delightelecltgctrl(iNameLength, zoneNameArr, dBldgLat, dHISKF, dHISUNF, dCloudFraction, dSOLCOSX, dSOLCOSY, dSOLCOSZ, pdPowerReducFac)
    return pdPowerReducFac


def find_item_in_list(search_value: str, search_list: list) -> int:
    """Find item in list, return 1-based index or 0 if not found"""
    try:
        for i, item in enumerate(search_list):
            if isinstance(item, str) and item == search_value:
                return i + 1
            elif hasattr(item, "Name") and item.Name == search_value:
                return i + 1
    except:
        pass
    return 0
