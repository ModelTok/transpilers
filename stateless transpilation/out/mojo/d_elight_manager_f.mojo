from collections import InlineArray
from math import cos, sin, sqrt, pi

# EXTERNAL DEPS (to wire in glue):
# EnergyPlusData: main state object, carries all module data
# External C functions: delightdaylightcoefficients, delightelecltgctrl (from DElight library)
# ShowSevereError, ShowWarningError, ShowContinueError, ShowFatalError: error reporting
# SetupOutputVariable: output variable setup
# Util::FindItemInList: list search utility
# InternalHeatGains: module with lighting level functions
# trim: string trimming utility
# Constants: M2FT, M22FT2, M32FT3, LUX2FC, DegToRad, Units

alias Real64 = Float64
alias DegToRad = pi / 180.0
alias M2FT = 3.28084
alias M22FT2 = 10.764
alias M32FT3 = 35.315
alias LUX2FC = 0.092903


struct Vector3:
    var x: Real64
    var y: Real64
    var z: Real64

    fn __init__() -> Self:
        return Self{x: 0.0, y: 0.0, z: 0.0}

    fn __init__(x: Real64, y: Real64, z: Real64) -> Self:
        return Self{x: x, y: y, z: z}


struct RefPtData:
    var absCoords: Vector3
    var lums: InlineArray[Real64, 1]
    var glareIndex: Real64
    var fracZoneDaylit: Real64
    var illumSetPoint: Real64

    fn __init__() -> Self:
        var lums_arr = InlineArray[Real64, 1](fill=0.0)
        return Self{
            absCoords: Vector3(),
            lums: lums_arr,
            glareIndex: 0.0,
            fracZoneDaylit: 0.0,
            illumSetPoint: 0.0,
        }


struct DaylightControlData:
    var daylightMethod: Int32
    var name: String
    var zoneName: String
    var totalDaylRefPoints: Int32
    var minPowerFraction: Real64
    var minLightFraction: Real64
    var lightControlSteps: Int32
    var lightControlProbability: Real64
    var dElightGriddingResolution: Real64
    var lightControlType: Int32

    fn __init__() -> Self:
        return Self{
            daylightMethod: 0,
            name: "",
            zoneName: "",
            totalDaylRefPoints: 0,
            minPowerFraction: 0.0,
            minLightFraction: 0.0,
            lightControlSteps: 0,
            lightControlProbability: 0.0,
            dElightGriddingResolution: 0.0,
            lightControlType: 0,
        }


struct ComplexFenestrationData:
    var name: String
    var complexFeneType: String
    var surfName: String
    var wndwName: String
    var feneRota: Real64

    fn __init__() -> Self:
        return Self{name: "", complexFeneType: "", surfName: "", wndwName: "", feneRota: 0.0}


struct DaylRefPtData:
    var name: String
    var x: Real64
    var y: Real64
    var z: Real64
    var zoneNum: Int32
    var indexToFracAndIllum: Int32

    fn __init__() -> Self:
        return Self{
            name: "",
            x: 0.0,
            y: 0.0,
            z: 0.0,
            zoneNum: 0,
            indexToFracAndIllum: 0,
        }


struct VertexData:
    var x: Real64
    var y: Real64
    var z: Real64

    fn __init__() -> Self:
        return Self{x: 0.0, y: 0.0, z: 0.0}

    fn __init__(x: Real64, y: Real64, z: Real64) -> Self:
        return Self{x: x, y: y, z: z}


@value
struct SurfaceData:
    var name: String
    var surfaceClass: Int32
    var azimuth: Real64
    var tilt: Real64
    var baseSurfName: String
    var extSolar: Bool
    var construction: Int32
    var sides: Int32
    var multiplier: Real64
    var hasShadeControl: Bool

    fn __init__() -> Self:
        return Self{
            name: "",
            surfaceClass: 0,
            azimuth: 0.0,
            tilt: 0.0,
            baseSurfName: "",
            extSolar: False,
            construction: 0,
            sides: 0,
            multiplier: 1.0,
            hasShadeControl: False,
        }


@value
struct ConstructionData:
    var reflectVisDiffBack: Real64
    var transDiffVis: Real64
    var transVisBeamCoef: InlineArray[Real64, 6]

    fn __init__() -> Self:
        return Self{
            reflectVisDiffBack: 0.0,
            transDiffVis: 0.0,
            transVisBeamCoef: InlineArray[Real64, 6](fill=0.0),
        }


@value
struct MaterialData:
    var absorpVisible: Real64

    fn __init__() -> Self:
        return Self{absorpVisible: 0.0}


@value
struct ZoneData:
    var name: String
    var originX: Real64
    var originY: Real64
    var originZ: Real64
    var relNorth: Real64
    var multiplier: Int32
    var listMultiplier: Int32
    var floorArea: Real64
    var volume: Real64
    var minimumX: Real64
    var maximumX: Real64
    var minimumY: Real64
    var maximumY: Real64
    var minimumZ: Real64
    var maximumZ: Real64

    fn __init__() -> Self:
        return Self{
            name: "",
            originX: 0.0,
            originY: 0.0,
            originZ: 0.0,
            relNorth: 0.0,
            multiplier: 1,
            listMultiplier: 1,
            floorArea: 0.0,
            volume: 0.0,
            minimumX: 0.0,
            maximumX: 0.0,
            minimumY: 0.0,
            maximumY: 0.0,
            minimumZ: 0.0,
            maximumZ: 0.0,
        }


@value
struct SpaceData:
    var htSurfaceFirst: Int32
    var htSurfaceLast: Int32

    fn __init__() -> Self:
        return Self{htSurfaceFirst: 0, htSurfaceLast: 0}


struct InputProcessorData:
    fn getNumObjectsFound(self, state: AnyType, moduleObject: String) -> Int32:
        return 0

    fn getObjectItem(
        self,
        state: AnyType,
        moduleObject: String,
        itemNum: Int32,
        alphaArgs: Pointer[String],
        numAlpha: Pointer[Int32],
        numericArgs: Pointer[Real64],
        numNumber: Pointer[Int32],
        ioStat: Pointer[Int32],
        numericBlanks: Pointer[Bool],
        alphaBlanks: Pointer[Bool],
        alphaNames: Pointer[String],
        numericNames: Pointer[String],
    ):
        pass


struct InputProcessingData:
    var inputProcessor: InputProcessorData

    fn __init__() -> Self:
        return Self{inputProcessor: InputProcessorData()}


struct FilesData:
    fn __init__() -> Self:
        return Self{}


struct DaylightingData:
    fn __init__() -> Self:
        return Self{}


@value
struct EnergyPlusData:
    pass


@always_inline
fn replace_blanks_with_underscores(input_string: String) -> String:
    var result = input_string
    var output = String()
    for c in result:
        if c == " ":
            output.append("_")
        else:
            output.append(c)
    return output


@always_inline
fn get_char_array_from_string(original_string: String) -> DynamicVector[UInt8]:
    var result = DynamicVector[UInt8]()
    for c in original_string.as_bytes():
        result.push_back(c)
    result.push_back(0)
    return result


@always_inline
fn get_string_from_char_array(original_char_array: DynamicVector[UInt8]) -> String:
    var result = String()
    for i in range(len(original_char_array) - 1):
        result.append(chr(int(original_char_array[i])))
    return result


@always_inline
fn find_item_in_list(search_value: String, search_list: AnyType) -> Int32:
    return 0


@always_inline
fn get_input_delight_complex_fenestration(state: AnyType, inout errors_found: Bool) -> None:
    pass


@always_inline
fn check_for_geometric_transform(
    state: AnyType, inout do_transform: Bool, inout old_aspect_ratio: Real64, inout new_aspect_ratio: Real64
) -> None:
    do_transform = False
    old_aspect_ratio = 1.0
    new_aspect_ratio = 1.0


fn delight_input_generator(state: AnyType) -> None:
    """
    SUBROUTINE INFORMATION:
    AUTHOR         Robert J. Hitchcock
    DATE WRITTEN   August 2003
    MODIFIED       February 2004 - Changes to accommodate mods in DElight IDD
    RE-ENGINEERED  na

    PURPOSE OF THIS SUBROUTINE:
    This subroutine creates a DElight input file from EnergyPlus processed input.
    """

    var iNumDElightZones: Int32 = 0
    var iNumOpaqueSurfs: Int32 = 0
    var iNumWindows: Int32 = 0
    var iconstruct: Int32 = 0
    var iMatlLayer: Int32 = 0
    var rExtVisRefl: Real64 = 0.0
    var rLightLevel: Real64 = 0.0
    var CosBldgRelNorth: Real64 = 0.0
    var SinBldgRelNorth: Real64 = 0.0
    var CosZoneRelNorth: Real64 = 0.0
    var SinZoneRelNorth: Real64 = 0.0
    var Xb: Real64 = 0.0
    var Yb: Real64 = 0.0
    var RefPt_WCS_Coord: Vector3 = Vector3()
    var iWndoConstIndexes: InlineArray[Int32, 100] = InlineArray[Int32, 100](fill=0)
    var lWndoConstFound: Bool = False
    var cNameWOBlanks: String = ""
    var ErrorsFound: Bool = False
    var iHostedCFS: Int32 = 0
    var lWndoIsDoppelganger: Bool = False
    var iDoppelganger: Int32 = 0
    var ldoTransform: Bool = False
    var roldAspectRatio: Real64 = 0.0
    var rnewAspectRatio: Real64 = 0.0
    var Xo: Real64 = 0.0
    var XnoRot: Real64 = 0.0
    var Xtrans: Real64 = 0.0
    var Yo: Real64 = 0.0
    var YnoRot: Real64 = 0.0
    var Ytrans: Real64 = 0.0

    ErrorsFound = False

    get_input_delight_complex_fenestration(state, ErrorsFound)

    check_for_geometric_transform(state, ldoTransform, roldAspectRatio, rnewAspectRatio)

    iNumDElightZones = 0
    var iNumWndoConsts: Int32 = 0

    if ErrorsFound:
        return


fn generate_delight_daylight_coefficients(d_latitude: Real64) -> Int32:
    """
    SUBROUTINE INFORMATION:
    AUTHOR         Linda Lawrie
    DATE WRITTEN   September 2012
    MODIFIED       na
    RE-ENGINEERED  na

    PURPOSE OF THIS SUBROUTINE:
    The purpose of this subroutine is to provide an envelop to the DElightDaylightCoefficients routine
    """
    var i_error_flag: Int32 = 0
    return i_error_flag


fn delight_elec_ltg_ctrl(
    iNameLength: Int32,
    cZoneName: String,
    dBldgLat: Real64,
    dHISKF: Real64,
    dHISUNF: Real64,
    dCloudFraction: Real64,
    dSOLCOSX: Real64,
    dSOLCOSY: Real64,
    dSOLCOSZ: Real64,
) -> Real64:
    """Wrapper for C function delightelecltgctrl"""
    var zoneNameArr = get_char_array_from_string(cZoneName)
    var pdPowerReducFac: Real64 = 0.0
    return pdPowerReducFac
