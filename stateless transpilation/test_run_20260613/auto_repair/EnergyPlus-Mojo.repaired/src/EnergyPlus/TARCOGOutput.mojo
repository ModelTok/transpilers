from python import datetime
from python import pathlib
from math import *
from Data.BaseData import BaseGlobalStruct, EnergyPlusData
from Data.EnergyPlusData import *  # might need specific
from FileSystem import fs  # alias for pathlib? or use string
from IOFiles import InputOutputFile
from TARCOGGassesParams import Stdrd, TARCOGGassesParams
from TARCOGParams import TARCOGLayerType, TARCOGThermalModel, DeflectionCalculation, TARCOGParams
from TARCOGCommon import *

# from ObjexxFCL import Array1D, Array2A, Array1D_int, Array1D_string  # would need to be defined elsewhere
# Instead, we approximate using Python lists with 1-based indexing wrapper? We'll use plain lists and adapt indices.
# To keep faithful, we'll define helper functions to mimic ObjexxFCL behavior.

struct Array1D[T: AnyType](CollectionElement):
    var data: PythonObject  # wrapped Python list
    def __init__(inout self, *args: T):
        self.data = list(args)
    def __getitem__(self, idx: Int) -> T:
        return self.data[idx - 1]  # 1-based to 0-based
    def __setitem__(inout self, idx: Int, val: T):
        self.data[idx - 1] = val
    def dim(inout self, size: Int):  # resize to size, initialize with zeros? Not used functionally
        self.data = [0.0] * size if T == Float64 else [0] * size
    def good(self) -> Bool:  # placeholder
        return True
    def close(self): pass

struct Array2A[T: AnyType](CollectionElement):
    var data: PythonObject  # list of lists
    def __init__(inout self, *args: T):
        self.data = list(args)  # not correct, but placeholder
    def __getitem__(self, idx1: Int, idx2: Int) -> T:
        return self.data[idx1 - 1][idx2 - 1]
    def __setitem__(inout self, idx1: Int, idx2: Int, val: T):
        self.data[idx1 - 1][idx2 - 1] = val
    def dim(inout self, n1: Int, n2: Int):  # resize 2D
        self.data = [[0.0 for _ in range(n2)] for _ in range(n1)] if T == Float64 else [[0 for _ in range(n2)] for _ in range(n1)]
    def good(self) -> Bool:
        return True
    def close(self): pass

# Constants from the original (some are used)
alias maxlay = 10  # example, should be defined in TARCOGParams
alias maxlay1 = 11
alias maxlay2 = 20
alias maxlay3 = 30
alias maxgas = 10
alias MaxGap = 10
alias Constant = struct:
    alias Kelvin = 273.15

# Macro EP_SIZE_CHECK: just a stub, we ignore
def EP_SIZE_CHECK(arr: PythonObject, expected: Int): pass

struct Files:
    var DBGD: String  # Debug directory (path as string)
    var WriteDebugOutput: Bool = False
    var WINCogFilePath: String = "test.w7"
    var WINCogFile: InputOutputFile
    var TarcogIterationsFilePath: String = "TarcogIterations.dbg"
    var TarcogIterationsFile: InputOutputFile
    var IterationCSVFilePath: String = "IterationResults.csv"
    var IterationCSVFile: InputOutputFile
    var DebugOutputFilePath: String = "Tarcog.dbg"
    var DebugOutputFile: InputOutputFile

    def __init__(inout self):
        self.WINCogFile = InputOutputFile(self.WINCogFilePath)
        self.TarcogIterationsFile = InputOutputFile(self.TarcogIterationsFilePath)
        self.IterationCSVFile = InputOutputFile(self.IterationCSVFilePath)
        self.DebugOutputFile = InputOutputFile(self.DebugOutputFilePath)

# WriteInputArguments using 0-based indexing
def WriteInputArguments(
    inout state: EnergyPlusData,
    inout InArgumentsFile: InputOutputFile,
    DBGD: String,
    tout: Float64,
    tind: Float64,
    trmin: Float64,
    wso: Float64,
    iwd: Int,
    wsi: Float64,
    dir: Float64,
    outir: Float64,
    isky: Int,
    tsky: Float64,
    esky: Float64,
    fclr: Float64,
    VacuumPressure: Float64,
    VacuumMaxGapThickness: Float64,
    ibc: Array1D[Int],
    hout: Float64,
    hin: Float64,
    standard: Stdrd,
    ThermalMod: TARCOGThermalModel,
    SDScalar: Float64,
    height: Float64,
    heightt: Float64,
    width: Float64,
    tilt: Float64,
    totsol: Float64,
    nlayer: Int,
    LayerType: Array1D[TARCOGLayerType],
    thick: Array1D[Float64],
    scon: Array1D[Float64],
    asol: Array1D[Float64],
    tir: Array1D[Float64],
    emis: Array1D[Float64],
    Atop: Array1D[Float64],
    Abot: Array1D[Float64],
    Al: Array1D[Float64],
    Ar: Array1D[Float64],
    Ah: Array1D[Float64],
    SlatThick: Array1D[Float64],
    SlatWidth: Array1D[Float64],
    SlatAngle: Array1D[Float64],
    SlatCond: Array1D[Float64],
    SlatSpacing: Array1D[Float64],
    SlatCurve: Array1D[Float64],
    nslice: Array1D[Int],
    LaminateA: Array1D[Float64],
    LaminateB: Array1D[Float64],
    sumsol: Array1D[Float64],
    gap: Array1D[Float64],
    vvent: Array1D[Float64],
    tvent: Array1D[Float64],
    presure: Array1D[Float64],
    nmix: Array1D[Int],
    iprop: Array2A[Int],
    frct: Array2A[Float64],
    xgcon: Array2A[Float64],
    xgvis: Array2A[Float64],
    xgcp: Array2A[Float64],
    xwght: Array1D[Float64]):
    EP_SIZE_CHECK(ibc, 2)
    EP_SIZE_CHECK(LayerType, maxlay)
    EP_SIZE_CHECK(thick, maxlay)
    EP_SIZE_CHECK(scon, maxlay)
    EP_SIZE_CHECK(asol, maxlay)
    EP_SIZE_CHECK(tir, maxlay2)
    EP_SIZE_CHECK(emis, maxlay2)
    EP_SIZE_CHECK(Atop, maxlay)
    EP_SIZE_CHECK(Abot, maxlay)
    EP_SIZE_CHECK(Al, maxlay)
    EP_SIZE_CHECK(Ar, maxlay)
    EP_SIZE_CHECK(Ah, maxlay)
    EP_SIZE_CHECK(SlatThick, maxlay)
    EP_SIZE_CHECK(SlatWidth, maxlay)
    EP_SIZE_CHECK(SlatAngle, maxlay)
    EP_SIZE_CHECK(SlatCond, maxlay)
    EP_SIZE_CHECK(SlatSpacing, maxlay)
    EP_SIZE_CHECK(SlatCurve, maxlay)
    EP_SIZE_CHECK(nslice, maxlay)
    EP_SIZE_CHECK(LaminateA, maxlay)
    EP_SIZE_CHECK(LaminateB, maxlay)
    EP_SIZE_CHECK(sumsol, maxlay)
    EP_SIZE_CHECK(gap, maxlay)
    EP_SIZE_CHECK(vvent, maxlay1)
    EP_SIZE_CHECK(tvent, maxlay1)
    EP_SIZE_CHECK(presure, maxlay1)
    EP_SIZE_CHECK(nmix, maxlay1)
    iprop.dim(maxgas, maxlay1)
    frct.dim(maxgas, maxlay1)
    xgcon.dim(3, maxgas)
    xgvis.dim(3, maxgas)
    xgcp.dim(3, maxgas)
    EP_SIZE_CHECK(xwght, maxgas)
    var DATE_TIME: Array1D[Int] = Array1D[Int]()
    # date_and_time replacement: get now
    var now = datetime.datetime.now()
    DATE_TIME[1] = now.year
    DATE_TIME[2] = now.month
    DATE_TIME[3] = now.day
    DATE_TIME[5] = now.hour
    DATE_TIME[6] = now.minute
    DATE_TIME[7] = now.second
    var real_CLOCK: Array1D[String] = Array1D[String]()  # not used elsewhere
    var i: Int
    var j: Int
    alias Format_1000 = "TARCOG input arguments:\n"
    alias Format_1001 = "TARCOG debug output, {:4}-{:02}-{:02}, {:02}:{:02}:{:02}\n"
    alias Format_1002 = "     WindowID:{:8}  - Not specified\n"
    alias Format_1003 = "     WindowID:{:8} \n"
    alias Format_1006 = "     IGUID:   {:8}  - Not specified\n"
    alias Format_1007 = "     IGUID:   {:8} \n"
    alias Format_1005 = "Simulation parameters:\n"
    alias Format_1010 = "  Tout       =  {:10.6F} K ( {:7.3F} deg C) - Outdoor temperature\n"
    alias Format_1015 = "  Tint       =  {:10.6F} K ( {:7.3F} deg C) - Indoor temperature\n"
    alias Format_1020 = "  Trmin      =  {:10.6F} K ( {:7.3F} deg C) - Indoor mean radiant temp.\n"
    alias Format_1030 = "  wso        =  {:7.3F}    - Outdoor wind speed [m/s]\n"
    alias Format_1032 = "  iwd        =    0        - Wind direction - windward\n"
    alias Format_1033 = "  iwd        =    1        - Wind direction - leeward\n"
    alias Format_1035 = "  wsi        =  {:7.3F}    - Indoor forced air speed [m/s]\n"
    alias Format_1040 = "  dir        = {:8.3F}    - Direct solar radiation [W/m^2]\n"
    alias Format_1041 = "  outir       = {:8.3F}    - IR radiation [W/m^2]\n"
    alias Format_1045 = "  isky       =  {:3}        - Flag for handling tsky, esky\n"
    alias Format_1050 = "  tsky           =  {:10.6F} K ( {:7.3F} deg C) - Night sky temperature\n"
    alias Format_1055 = "  esky           =  {:7.3F}    - Effective night sky emmitance\n"
    alias Format_1060 = "  fclr           =  {:7.3F}    - Fraction of sky that is clear\n"
    alias Format_1061 = "  VacuumPressure =  {:7.3F}    - maximum allowed gas pressure to be considered as vacuum\n"
    alias Format_1062 = "  VacuumMaxGapThickness =  {:7.3F}    - maximum allowed vacuum gap thickness with support pillar\n"
    alias Format_1063 = "  ibc(1)         =  {:3}        - Outdoor BC switch\n"
    alias Format_1065 = "  hout           =  {:9.5F}  - Outdoor film coeff. [W/m^2-K]\n"
    alias Format_1066 = "  ibc(2)         =  {:3}        - Indoor BC switch\n"
    alias Format_1068 = "  hin            =  {:9.5F}  - Indoor film coeff. [W/m^2-K]\n"
    alias Format_1070 = "  standard   =  {:3}        - ISO 15099 calc. standard\n"
    alias Format_1071 = "  standard   =  {:3}        - EN 673/ISO 10292 Declared calc. standard\n"
    alias Format_1072 = "  standard   =  {:3}        - EN 673/ISO 10292 Design calc. standard\n"
    alias Format_10731 = "  ThermalMod =  {:3}        - ISO15099 thermal model\n"
    alias Format_10732 = "  ThermalMod =  {:3}        - Scaled Cavity Width (SCW) thermal model\n"
    alias Format_10733 = "  ThermalMod =  {:3}        - Convective Scalar Model (CSM) thermal model\n"
    alias Format_10740 = "  SDScalar =  {:7.5F}      - Factor of Venetian SD layer contribution to convection\n\n (only if " \
                        "ThermalModel = 2, otherwise ignored)\n"
    alias Format_1075 = "IGU parameters:\n"
    alias Format_1076 = "  height     =  {:10.6F} - IGU cavity height [m]\n"
    alias Format_1077 = "  heightt    =  {:10.6F} - Total window height [m]\n"
    alias Format_1078 = "  width      =  {:10.6F} - Window width [m]\n"
    alias Format_1079 = "  tilt       =  {:7.3F}    - Window tilt [deg]\n"
    alias Format_1080 = "  totsol     =  {:10.6F} - Total solar transmittance of IGU\n"
    alias Format_1081 = "  nlayer     =  {:3}        - Number of glazing layers\n"
    alias Format_1089 = "IGU layers list:\n"
    alias Format_10802 = " Layer{:3} : {:1}              - Specular layer - Monolyhtic Glass\n"
    alias Format_10803 = " Layer{:3} : {:1}              - Laminated Glass\n"
    alias Format_10804 = " Layer{:3} : {:1}              - Horizontal Venetian Blind\n"
    alias Format_10805 = " Layer{:3} : {:1}              - Woven Shade\n"
    alias Format_10806 = " Layer{:3} : {:1}              - Diffuse Shade\n"
    alias Format_10809 = " Layer{:3} : {:1}              - UNKNOWN TYPE!\n"
    alias Format_10810 = " Layer{:3} : {:1}              - Vertical Venetian Blind\n"
    alias Format_1085 = "    nslice     = {:3}          - Number of slices\n"
    alias Format_1090 = "    thick   = {:10.6F}   - Thickness [m]\n"
    alias Format_1091 = "    scon    = {:10.6F}   - Thermal conductivity [W/m-K]\n"
    alias Format_1092 = "    asol    = {:12.8F} - Absorbed solar energy [W/m^2]\n"
    alias Format_1093 = "    tir     = {:12.8F} - IR transmittance\n"
    alias Format_1094 = "    emis1   = {:10.6F}   - IR outdoor emissivity\n"
    alias Format_1095 = "    emis2   = {:10.6F}   - IR indoor emissivity\n"
    alias Format_1100 = "    Atop    = {:10.6F}   - Top opening area [m^2]\n"
    alias Format_1101 = "    Abot    = {:10.6F}   - Bottom opening area [m^2]\n"
    alias Format_1102 = "    Al      = {:10.6F}   - Left opening area [m^2]\n"
    alias Format_1103 = "    Ar      = {:10.6F}   - Right opening area [m^2]\n"
    alias Format_1105 = "    Ah      = {:10.6F}   - Total area of holes [m^2]\n"
    alias Format_11051 = "    SlatThick   = {:10.6F}   - Slat thickness [m]\n"
    alias Format_11052 = "    SlatWidth   = {:10.6F}   - Slat width [m]\n"
    alias Format_11053 = "    SlatAngle   = {:10.6F}   - Slat tilt angle [deg]\n"
    alias Format_11054 = "    SlatCond    = {:10.6F}   - Conductivity of the slat material [W/m.K]\n"
    alias Format_11055 = "    SlatSpacing = {:10.6F}   - Distance between slats [m]\n"
    alias Format_11056 = "    SlatCurve   = {:10.6F}   - Curvature radius of the slat [m]\n"
    alias Format_1110 = "IGU Gaps:\n"
    alias Format_1111 = " Gap {:2}:\n"
    alias Format_11110 = " Outdoor space:\n"
    alias Format_11111 = " Indoor space:\n"
    alias Format_1112 = "    gap        = {:12.5F} - Gap width [m]\n"
    alias Format_1113 = "    presure    = {:12.5F} - Gas pressure [N/m^2]\n"
    alias Format_1114 = "    nmix       = {:6}       - Num. of gasses in a gas mix\n"
    alias Format_1115 = "      Gas {:1}:     {}     {:6.2F} %\n"
    alias Format_1120 = "    vvent      = {:12.5F} - Forced ventilation speed [m/s]\n"
    alias Format_1121 = "    tvent      = {:12.5F} - Temperature in connected gap [K]\n"
    alias Format_1130 = "      Gas mix coefficients - gas {:1}, {:6.2F} %\n"
    alias Format_1131 = "        gcon   = {:11.6F}, {:11.6F}, {:11.6F} - Conductivity\n"
    alias Format_1132 = "        gvis   = {:11.6F}, {:11.6F}, {:11.6F} - Dynamic viscosity\n"
    alias Format_1133 = "        gcp    = {:11.6F}, {:11.6F}, {:11.6F} - Spec.heat @ const.P\n"
    alias Format_1134 = "        wght   = {:11.6F}                           - Molecular weight\n"
    alias Format_1198 = "=====  =====  =====  =====  =====  =====  =====  =====  =====  =====  =====\n"

    if not InArgumentsFile.good():
        return
    # date_and_time already done
    print(InArgumentsFile, "\n")
    print(InArgumentsFile, Format_1001, DATE_TIME[1], DATE_TIME[2], DATE_TIME[3], DATE_TIME[5], DATE_TIME[6], DATE_TIME[7])
    print(InArgumentsFile, "\n")
    if state.dataTARCOGOutputs.winID == -1:
        print(InArgumentsFile, Format_1002, state.dataTARCOGOutputs.winID)
    else:
        print(InArgumentsFile, Format_1003, state.dataTARCOGOutputs.winID)
    if state.dataTARCOGOutputs.iguID == -1:
        print(InArgumentsFile, Format_1006, state.dataTARCOGOutputs.iguID)
    else:
        print(InArgumentsFile, Format_1007, state.dataTARCOGOutputs.iguID)
    print(InArgumentsFile, "     Debug dir:     {}\n", DBGD)
    print(InArgumentsFile, "\n")
    print(InArgumentsFile, Format_1000)
    print(InArgumentsFile, "\n")
    print(InArgumentsFile, Format_1005)
    print(InArgumentsFile, Format_1010, tout, tout - Constant.Kelvin)
    print(InArgumentsFile, Format_1015, tind, tind - Constant.Kelvin)
    print(InArgumentsFile, Format_1020, trmin, trmin - Constant.Kelvin)
    print(InArgumentsFile, Format_1030, wso)
    if iwd == 0:
        print(InArgumentsFile, Format_1032)  # windward
    if iwd == 1:
        print(InArgumentsFile, Format_1033)  # leeward
    print(InArgumentsFile, Format_1035, wsi)
    print(InArgumentsFile, Format_1040, dir)
    print(InArgumentsFile, Format_1041, outir)
    print(InArgumentsFile, Format_1045, isky)
    print(InArgumentsFile, Format_1050, tsky, tsky - Constant.Kelvin)
    print(InArgumentsFile, Format_1055, esky)
    print(InArgumentsFile, Format_1060, fclr)
    print(InArgumentsFile, Format_1061, VacuumPressure)
    print(InArgumentsFile, Format_1062, VacuumMaxGapThickness)
    print(InArgumentsFile, Format_1063, ibc[1])
    print(InArgumentsFile, Format_1065, hout)
    print(InArgumentsFile, Format_1066, ibc[2])
    print(InArgumentsFile, Format_1068, hin)
    if standard == Stdrd.ISO15099:
        print(InArgumentsFile, Format_1070, standard)
    if standard == Stdrd.EN673:
        print(InArgumentsFile, Format_1071, standard)
    if standard == Stdrd.EN673Design:
        print(InArgumentsFile, Format_1072, standard)
    if ThermalMod == TARCOGThermalModel.ISO15099:
        print(InArgumentsFile, Format_10731, ThermalMod)
        print(InArgumentsFile, Format_10740, SDScalar)
    if ThermalMod == TARCOGThermalModel.SCW:
        print(InArgumentsFile, Format_10732, ThermalMod)
        print(InArgumentsFile, Format_10740, SDScalar)
    if ThermalMod == TARCOGThermalModel.CSM:
        print(InArgumentsFile, Format_10733, ThermalMod)
        print(InArgumentsFile, Format_10740, SDScalar)
    print(InArgumentsFile, "\n")
    print(InArgumentsFile, Format_1075)
    print(InArgumentsFile, Format_1076, height)
    print(InArgumentsFile, Format_1077, heightt)
    print(InArgumentsFile, Format_1078, width)
    print(InArgumentsFile, Format_1079, tilt)
    print(InArgumentsFile, Format_1080, totsol)
    print(InArgumentsFile, Format_1081, nlayer)
    print(InArgumentsFile, "\n")
    print(InArgumentsFile, Format_1089)
    i = 1
    while i <= nlayer:
        match LayerType[i]:
            case TARCOGLayerType.DIFFSHADE:
                print(InArgumentsFile, Format_10806, i, LayerType[i])
            case TARCOGLayerType.WOVSHADE:
                print(InArgumentsFile, Format_10805, i, LayerType[i])
            case TARCOGLayerType.VENETBLIND_HORIZ:
                print(InArgumentsFile, Format_10804, i, LayerType[i])
            case TARCOGLayerType.VENETBLIND_VERT:
                print(InArgumentsFile, Format_10810, i, LayerType[i])
            case TARCOGLayerType.SPECULAR:
                if nslice[i] <= 1:
                    print(InArgumentsFile, Format_10802, i, LayerType[i])  # Monolithic glass
                else:
                    print(InArgumentsFile, Format_10803, i, LayerType[i])  # Laminated layer
            case _:
                print(InArgumentsFile, Format_10809, i, LayerType[i])
        print(InArgumentsFile, Format_1090, thick[i])
        print(InArgumentsFile, Format_1091, scon[i])
        print(InArgumentsFile, Format_1092, asol[i])
        print(InArgumentsFile, Format_1093, tir[2*i - 1])
        print(InArgumentsFile, Format_1094, emis[2*i - 1])
        print(InArgumentsFile, Format_1095, emis[2*i])
        if LayerType[i] == TARCOGLayerType.VENETBLIND_HORIZ or LayerType[i] == TARCOGLayerType.VENETBLIND_VERT:
            print(InArgumentsFile, Format_1100, Atop[i])
            print(InArgumentsFile, Format_1101, Abot[i])
            print(InArgumentsFile, Format_1102, Al[i])
            print(InArgumentsFile, Format_1103, Ar[i])
            print(InArgumentsFile, Format_1105, Ah[i])
            print(InArgumentsFile, Format_11051, SlatThick[i])
            print(InArgumentsFile, Format_11052, SlatWidth[i])
            print(InArgumentsFile, Format_11053, SlatAngle[i])
            print(InArgumentsFile, Format_11054, SlatCond[i])
            print(InArgumentsFile, Format_11055, SlatSpacing[i])
            print(InArgumentsFile, Format_11056, SlatCurve[i])
        if nslice[i] > 1:
            print(InArgumentsFile, Format_1085, nslice[i])
            print(InArgumentsFile, Format_1085, LaminateA[i])
            print(InArgumentsFile, Format_1085, LaminateB[i])
            print(InArgumentsFile, Format_1085, sumsol[i])
        i += 1
    print(InArgumentsFile, "\n")
    print(InArgumentsFile, Format_1110)
    i = 1
    while i <= nlayer + 1:
        if i > 1 and i <= nlayer:
            print(InArgumentsFile, Format_1111, i - 1)
        if i == 1:
            print(InArgumentsFile, Format_11110)
        if i == nlayer + 1:
            print(InArgumentsFile, Format_11111)
        if i > 1 and i <= nlayer:
            print(InArgumentsFile, Format_1112, gap[i - 1])
        print(InArgumentsFile, Format_1113, presure[i])
        if i > 1 and i <= nlayer:
            print(InArgumentsFile, Format_1120, vvent[i])
        if i > 1 and i <= nlayer:
            print(InArgumentsFile, Format_1121, tvent[i])
        print(InArgumentsFile, Format_1114, nmix[i])
        j = 1
        while j <= nmix[i]:
            print(InArgumentsFile, Format_1115, iprop[j, i], ' ', 100 * frct[j, i])
            print(InArgumentsFile, Format_1130, iprop[j, i], 100 * frct[j, i])
            print(InArgumentsFile, Format_1131, xgcon[1, iprop[j, i]], xgcon[2, iprop[j, i]], xgcon[3, iprop[j, i]])
            print(InArgumentsFile, Format_1132, xgvis[1, iprop[j, i]], xgvis[2, iprop[j, i]], xgvis[3, iprop[j, i]])
            print(InArgumentsFile, Format_1133, xgcp[1, iprop[j, i]], xgcp[2, iprop[j, i]], xgcp[3, iprop[j, i]])
            print(InArgumentsFile, Format_1134, xwght[iprop[j, i]])
            j += 1
        i += 1
    print(InArgumentsFile, "\n")
    print(InArgumentsFile, Format_1198)

# WriteModifiedArguments – similar translation
def WriteModifiedArguments(
    inout InArgumentsFile: InputOutputFile,
    DBGD: String,
    esky: Float64,
    trmout: Float64,
    trmin: Float64,
    ebsky: Float64,
    ebroom: Float64,
    Gout: Float64,
    Gin: Float64,
    nlayer: Int,
    LayerType: Array1D[TARCOGLayerType],
    nmix: Array1D[Int],
    frct: Array2A[Float64],
    thick: Array1D[Float64],
    scon: Array1D[Float64],
    gap: Array1D[Float64],
    xgcon: Array2A[Float64],
    xgvis: Array2A[Float64],
    xgcp: Array2A[Float64],
    xwght: Array1D[Float64]):
    EP_SIZE_CHECK(LayerType, maxlay)
    EP_SIZE_CHECK(nmix, maxlay1)
    frct.dim(maxgas, maxlay1)
    EP_SIZE_CHECK(thick, maxlay)
    EP_SIZE_CHECK(scon, maxlay)
    EP_SIZE_CHECK(gap, MaxGap)
    xgcon.dim(3, maxgas)
    xgvis.dim(3, maxgas)
    xgcp.dim(3, maxgas)
    EP_SIZE_CHECK(xwght, maxgas)
    var i: Int
    var j: Int
    alias Format_1014 = "Adjusted input arguments:\n"
    alias Format_1013 = " Gass coefficients:\n"
    alias Format_1016 = "  Trmout     =  {:10.6F} K ( {:7.3F} deg C) - Outdoor mean radiant temp.\n"
    alias Format_1017 = "  Gout       =  {:10.6F} \n"
    alias Format_1018 = "  Gin        =  {:10.6F} \n"
    alias Format_1019 = "  Ebsky      =  {:10.6F} \n"
    alias Format_10191 = "  Ebroom     =  {:10.6F} \n"
    alias Format_1020 = "  Trmin      =  {:10.6F} K ( {:7.3F} deg C) - Indoor mean radiant temp.\n"
    alias Format_1055 = "  esky       =  {:7.3F}    - Effective night sky emmitance\n"
    alias Format_1084 = " Layer{:3} : {:1}              - Venetian Blind\n"
    alias Format_1090 = "    thick   = {:10.6F}   - Thickness [m]\n"
    alias Format_1091 = "    scon    = {:10.6F}   - Thermal conductivity [W/m-K]\n"
    alias Format_1130 = "      Gas mix coefficients - gas {:1}, {:6.2F} %\n"
    alias Format_1131 = "        gcon   = {:11.6F}, {:11.6F}, {:11.6F} - Conductivity\n"
    alias Format_1132 = "        gvis   = {:11.6F}, {:11.6F}, {:11.6F} - Dynamic viscosity\n"
    alias Format_1133 = "        gcp    = {:11.6F}, {:11.6F}, {:11.6F} - Spec.heat @ const.P\n"
    alias Format_1134 = "        wght   = {:11.6F}                           - Molecular weight\n"
    alias Format_1111 = " Gap {:2}:\n"
    alias Format_1112 = " Gap width: {:11.8F}\n"
    alias Format_11110 = " Outdoor space:\n"
    alias Format_11111 = " Indoor space:\n"
    alias Format_1198 = "=====  =====  =====  =====  =====  =====  =====  =====  =====  =====  =====\n"
    print(InArgumentsFile, "\n")
    print(InArgumentsFile, Format_1014)
    print(InArgumentsFile, "\n")
    print(InArgumentsFile, Format_1055, esky)
    print(InArgumentsFile, Format_1016, trmout, trmout - Constant.Kelvin)
    print(InArgumentsFile, Format_1020, trmin, trmin - Constant.Kelvin)
    print(InArgumentsFile, Format_1019, ebsky)
    print(InArgumentsFile, Format_10191, ebroom)
    print(InArgumentsFile, Format_1017, Gout)
    print(InArgumentsFile, Format_1018, Gin)
    print(InArgumentsFile, "\n")
    i = 1
    while i <= nlayer:
        if (LayerType[i] == TARCOGLayerType.VENETBLIND_HORIZ) or (LayerType[i] == TARCOGLayerType.VENETBLIND_VERT):
            print(InArgumentsFile, Format_1084, i, LayerType[i])
            print(InArgumentsFile, Format_1090, thick[i])
            print(InArgumentsFile, Format_1091, scon[i])
        i += 1
    print(InArgumentsFile, "\n")
    print(InArgumentsFile, Format_1013)
    i = 1
    while i <= nlayer + 1:
        if i > 1 and i <= nlayer:
            print(InArgumentsFile, Format_1111, i - 1)
            print(InArgumentsFile, Format_1112, gap[i - 1])
        if i == 1:
            print(InArgumentsFile, Format_11110)
        if i == nlayer + 1:
            print(InArgumentsFile, Format_11111)
        j = 1
        while j <= nmix[i]:
            print(InArgumentsFile, Format_1130, j, 100 * frct[j, i])
            print(InArgumentsFile, Format_1131, xgcon[1, j], xgcon[2, j], xgcon[3, j])
            print(InArgumentsFile, Format_1132, xgvis[1, j], xgvis[2, j], xgvis[3, j])
            print(InArgumentsFile, Format_1133, xgcp[1, j], xgcp[2, j], xgcp[3, j])
            print(InArgumentsFile, Format_1134, xwght[j])
            j += 1
        i += 1
    print(InArgumentsFile, "\n")
    print(InArgumentsFile, Format_1198)

# WriteOutputArguments – similar
def WriteOutputArguments(
    inout OutArgumentsFile: InputOutputFile,
    DBGD: String,
    nlayer: Int,
    tamb: Float64,
    q: Array1D[Float64],
    qv: Array1D[Float64],
    qcgas: Array1D[Float64],
    qrgas: Array1D[Float64],
    theta: Array1D[Float64],
    vfreevent: Array1D[Float64],
    vvent: Array1D[Float64],
    Keff: Array1D[Float64],
    ShadeGapKeffConv: Array1D[Float64],
    troom: Float64,
    ufactor: Float64,
    shgc: Float64,
    sc: Float64,
    hflux: Float64,
    shgct: Float64,
    hcin: Float64,
    hrin: Float64,
    hcout: Float64,
    hrout: Float64,
    Ra: Array1D[Float64],
    Nu: Array1D[Float64],
    LayerType: Array1D[TARCOGLayerType],
    Ebf: Array1D[Float64],
    Ebb: Array1D[Float64],
    Rf: Array1D[Float64],
    Rb: Array1D[Float64],
    ebsky: Float64,
    Gout: Float64,
    ebroom: Float64,
    Gin: Float64,
    ShadeEmisRatioIn: Float64,
    ShadeEmisRatioOut: Float64,
    ShadeHcRatioIn: Float64,
    ShadeHcRatioOut: Float64,
    HcUnshadedIn: Float64,
    HcUnshadedOut: Float64,
    hcgas: Array1D[Float64],
    hrgas: Array1D[Float64],
    AchievedErrorTolerance: Float64,
    NumOfIter: Int):
    EP_SIZE_CHECK(q, maxlay3)
    EP_SIZE_CHECK(qv, maxlay1)
    EP_SIZE_CHECK(qcgas, maxlay1)
    EP_SIZE_CHECK(qrgas, maxlay1)
    EP_SIZE_CHECK(theta, maxlay2)
    EP_SIZE_CHECK(vfreevent, maxlay1)
    EP_SIZE_CHECK(vvent, maxlay1)
    EP_SIZE_CHECK(Keff, maxlay)
    EP_SIZE_CHECK(ShadeGapKeffConv, MaxGap)
    EP_SIZE_CHECK(Ra, maxlay)
    EP_SIZE_CHECK(Nu, maxlay)
    EP_SIZE_CHECK(LayerType, maxlay)
    EP_SIZE_CHECK(Ebf, maxlay)
    EP_SIZE_CHECK(Ebb, maxlay)
    EP_SIZE_CHECK(Rf, maxlay)
    EP_SIZE_CHECK(Rb, maxlay)
    EP_SIZE_CHECK(hcgas, maxlay)
    EP_SIZE_CHECK(hrgas, maxlay)
    var DATE_TIME: Array1D[Int] = Array1D[Int]()
    var now = datetime.datetime.now()
    DATE_TIME[1] = now.year
    DATE_TIME[2] = now.month
    DATE_TIME[3] = now.day
    DATE_TIME[5] = now.hour
    DATE_TIME[6] = now.minute
    DATE_TIME[7] = now.second
    var real_CLOCK: Array1D[String] = Array1D[String]()
    var i: Int
    alias Format_2000 = "TARCOG calculation results - {:4}-{:02}-{:02}, {:02}:{:02}:{:02}\n"
    alias Format_2120 = "  Ufactor  = {:12.6F}\n"
    alias Format_2130 = "  SHGC     = {:12.6F}\n"
    alias Format_2131 = "  SHGC_OLD = {:12.6F}\n"
    alias Format_2132 = "  SC       = {:12.6F}\n"
    alias Format_2140 = "  hcin  = {:10.6F}   hrin  = {:10.6F}   hin  = {:10.6F}\n"
    alias Format_2150 = "  hcout = {:10.6F}   hrout = {:10.6F}   hout = {:10.6F}\n"
    alias Format_2155 = "  Ra({:1}) ={:15.6F}        Nu({:1}) ={:12.6F}\n"
    alias Format_2160 = "  hcgas({:1}) ={:15.6F}      hrgas({:1}) ={:24.6F}\n"
    alias Format_2170 = "  hflux    = {:12.6F}\n"
    alias Format_2105 = "                                            Tamb ={:11.6F} K ( {:7.3F} deg C)\n"
    alias Format_2110 = "  ----------------- ------------------   Theta{:2} ={:11.6F} K ( {:7.3F} deg C)\n"
    alias Format_2111 = "  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\ " \
                        "\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\   Theta{:2} ={:11.6F} K ( {:7.3F} " \
                        "deg C)\n"
    alias Format_2112 = "  +++++++++++++++++ ++++++++++++++++++   Theta{:2} ={:11.6F} K ( {:7.3F} deg C)\n"
    alias Format_2115 = "                                           Troom ={:11.6F} K ( {:7.3F} deg C)\n"
    alias Format_2180 = "           qout ={:12.5F}\n"
    alias Format_2190 = "  |     qpane{:2} ={:12.5F}        |\n"
    alias Format_2195 = "  |     qpane{:2} ={:12.5F}        |         keffc{:2} ={:11.6F}\n"
    alias Format_2199 = "  |      qlayer{:2} ={:12.5F}       |\n"
    alias Format_2210 = "            qin ={:11.6F}\n"
    alias Format_2300 = "            q{:2} ={:12.5F}\n"
    alias Format_2320 = "           qv{:2} ={:12.5F}\n"
    alias Format_2321 = "       airspd{:2} ={:12.5F}    keff{:2} ={:12.5F}\n"
    alias Format_2322 = "           qc{:2} ={:12.5F}      qr{:2} ={:12.5F}\n"
    alias Format_2330 = "  ShadeEmisRatioIn  ={:11.6F}        ShadeEmisRatioOut ={:11.6F}\n"
    alias Format_2331 = "  ShadeHcRatioIn    ={:11.6F}        ShadeHcRatioOut   ={:11.6F}\n"
    alias Format_2332 = "  HcUnshadedIn      ={:11.6F}        HcUnshadedOut     ={:11.6F}\n"
    alias Format_2350 = "Heat Flux Flow and Temperatures of Layer Surfaces:\n"
    alias Format_2351 = "Basic IGU properties:\n"
    alias Format_4205 = "  Ebsky ={:11.6F} [W/m2], Gout ={:11.6F} [W/m2]\n"
    alias Format_4215 = "  Ebroom ={:11.6F} [W/m2], Gin  ={:11.6F} [W/m2]\n"
    alias Format_4110 = "  Ef{:2} ={:11.6F} [W/m2], Rf{:2} ={:11.6F} [W/m2]\n"
    alias Format_4111 = "  ----------------- ------------------\n"
    alias Format_4112 = "  Ef{:2} ={:11.6F} [W/m2], Rf{:2} ={:11.6F} [W/m2]\n"
    alias Format_4113 = "  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\ " \
                        "\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\n"
    alias Format_4114 = "  Ef{:2} ={:11.6F} [W/m2], Rf{:2} ={:11.6F} [W/m2]\n"
    alias Format_4115 = "  +++++++++++++++++ ++++++++++++++++++\n"
    alias Format_4116 = "  Ef{:2} ={:11.6F} [W/m2], Rf{:2} ={:11.6F} [W/m2]\n"
    alias Format_4117 = "  ooooooooooooooooo oooooooooooooooooo\n"
    alias Format_4120 = "  Eb{:2} ={:11.6F} [W/m2], Rb{:2} ={:11.6F} [W/m2]\n"
    alias Format_4121 = "  ----------------- ------------------\n"
    alias Format_4122 = "  Eb{:2} ={:11.6F} [W/m2], Rb{:2} ={:11.6F} [W/m2]\n"
    alias Format_4123 = "  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\ " \
                        "\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\n"
    alias Format_4124 = "  Eb{:2} ={:11.6F} [W/m2], Rb{:2} ={:11.6F} [W/m2]\n"
    alias Format_4125 = "  +++++++++++++++++ ++++++++++++++++++\n"
    alias Format_4126 = "  Eb{:2} ={:11.6F} [W/m2], Rb{:2} ={:11.6F} [W/m2]\n"
    alias Format_4127 = "  ooooooooooooooooo oooooooooooooooooo\n"
    alias Format_4190 = "  |                     |\n"
    alias Format_4350 = "Energy balances on Layer Surfaces:\n"
    # date_and_time already assigned
    print(OutArgumentsFile, "\n")
    print(OutArgumentsFile, Format_2000, DATE_TIME[1], DATE_TIME[2], DATE_TIME[3], DATE_TIME[5], DATE_TIME[6], DATE_TIME[7])
    print(OutArgumentsFile, "\n")
    print(OutArgumentsFile, Format_2350)
    print(OutArgumentsFile, "\n")
    print(OutArgumentsFile, Format_2105, tamb, tamb - Constant.Kelvin)
    print(OutArgumentsFile, Format_2180, q[1])
    i = 1
    while i <= nlayer:
        match LayerType[i]:
            case TARCOGLayerType.SPECULAR:
                print(OutArgumentsFile, Format_2110, 2*i - 1, theta[2*i - 1], theta[2*i - 1] - Constant.Kelvin)
                print(OutArgumentsFile, Format_2190, i, q[2*i])
                print(OutArgumentsFile, Format_2110, 2*i, theta[2*i], theta[2*i] - Constant.Kelvin)
            case TARCOGLayerType.VENETBLIND_HORIZ | TARCOGLayerType.VENETBLIND_VERT:
                print(OutArgumentsFile, Format_2111, 2*i - 1, theta[2*i - 1], theta[2*i - 1] - Constant.Kelvin)
                print(OutArgumentsFile, Format_2195, i, q[2*i], i, ShadeGapKeffConv[i])
                print(OutArgumentsFile, Format_2111, 2*i, theta[2*i], theta[2*i] - Constant.Kelvin)
            case TARCOGLayerType.WOVSHADE:
                print(OutArgumentsFile, Format_2112, 2*i - 1, theta[2*i - 1], theta[2*i - 1] - Constant.Kelvin)
                print(OutArgumentsFile, Format_2195, i, q[2*i], i, ShadeGapKeffConv[i])
                print(OutArgumentsFile, Format_2112, 2*i, theta[2*i], theta[2*i] - Constant.Kelvin)
            case TARCOGLayerType.DIFFSHADE:
                print(OutArgumentsFile, Format_2110, 2*i - 1, theta[2*i - 1], theta[2*i - 1] - Constant.Kelvin)
                print(OutArgumentsFile, Format_2190, i, q[2*i])
                print(OutArgumentsFile, Format_2110, 2*i, theta[2*i], theta[2*i] - Constant.Kelvin)
            case _:
                print(OutArgumentsFile, Format_2110, 2*i - 1, theta[2*i - 1], theta[2*i - 1] - Constant.Kelvin)
                print(OutArgumentsFile, Format_2199, i, q[2*i])
                print(OutArgumentsFile, Format_2110, 2*i, theta[2*i], theta[2*i] - Constant.Kelvin)
        if i != nlayer:
            print(OutArgumentsFile, Format_2300, i, q[2*i + 1])
            print(OutArgumentsFile, Format_2320, i, qv[i + 1])
            if vvent[i + 1] == 0:
                print(OutArgumentsFile, Format_2321, i, vfreevent[i + 1], i, Keff[i])
            else:
                if i > 1:
                    print(OutArgumentsFile, Format_2321, i, vvent[i + 1], i, Keff[i - 1])
            print(OutArgumentsFile, Format_2322, i, qcgas[i + 1], i, qrgas[i + 1])
        else:
            print(OutArgumentsFile, Format_2210, q[2*i + 1])
        i += 1
    print(OutArgumentsFile, Format_2115, troom, troom - Constant.Kelvin)
    print(OutArgumentsFile, "\n")
    print(OutArgumentsFile, Format_4350)
    print(OutArgumentsFile, "\n")
    print(OutArgumentsFile, Format_4205, ebsky, Gout)
    print(OutArgumentsFile, "\n")
    i = 1
    while i <= nlayer:
        match LayerType[i]:
            case TARCOGLayerType.SPECULAR:
                print(OutArgumentsFile, Format_4110, i, Ebf[i], i, Rf[i])
                print(OutArgumentsFile, Format_4111)
                print(OutArgumentsFile, Format_4190)
                print(OutArgumentsFile, Format_4121)
                print(OutArgumentsFile, Format_4120, i, Ebb[i], i, Rb[i])
            case TARCOGLayerType.VENETBLIND_HORIZ | TARCOGLayerType.VENETBLIND_VERT:
                print(OutArgumentsFile, Format_4112, i, Ebf[i], i, Rf[i])
                print(OutArgumentsFile, Format_4113)
                print(OutArgumentsFile, Format_4190)
                print(OutArgumentsFile, Format_4123)
                print(OutArgumentsFile, Format_4122, i, Ebb[i], i, Rb[i])
            case TARCOGLayerType.WOVSHADE:
                print(OutArgumentsFile, Format_4114, i, Ebf[i], i, Rf[i])
                print(OutArgumentsFile, Format_4115)
                print(OutArgumentsFile, Format_4190)
                print(OutArgumentsFile, Format_4125)
                print(OutArgumentsFile, Format_4124, i, Ebb[i], i, Rb[i])
            case TARCOGLayerType.DIFFSHADE:
                print(OutArgumentsFile, Format_4116, i, Ebf[i], i, Rf[i])
                print(OutArgumentsFile, Format_4117)
                print(OutArgumentsFile, Format_4190)
                print(OutArgumentsFile, Format_4127)
                print(OutArgumentsFile, Format_4126, i, Ebb[i], i, Rb[i])
            case _:
                print(OutArgumentsFile, Format_4110, i, Ebf[i], i, Rf[i])
                print(OutArgumentsFile, Format_4111)
                print(OutArgumentsFile, Format_4190)
                print(OutArgumentsFile, Format_4121)
                print(OutArgumentsFile, Format_4120, i, Ebb[i], i, Rb[i])
        print(OutArgumentsFile, "\n")
        i += 1
    print(OutArgumentsFile, Format_4215, ebroom, Gin)
    print(OutArgumentsFile, "\n")
    print(OutArgumentsFile, Format_2351)
    print(OutArgumentsFile, "\n")
    print(OutArgumentsFile, Format_2120, ufactor)
    print(OutArgumentsFile, Format_2130, shgc)
    print(OutArgumentsFile, "\n")
    print(OutArgumentsFile, Format_2132, sc)
    print(OutArgumentsFile, Format_2170, hflux)
    print(OutArgumentsFile, "\n")
    print(OutArgumentsFile, Format_2131, shgct)
    print(OutArgumentsFile, "\n")
    print(OutArgumentsFile, Format_2140, hcin, hrin, hcin + hrin)
    print(OutArgumentsFile, Format_2150, hcout, hrout, hcout + hrout)
    print(OutArgumentsFile, "\n")
    i = 1
    while i <= nlayer - 1:
        print(OutArgumentsFile, Format_2155, i, Ra[i], i, Nu[i])
        i += 1
    print(OutArgumentsFile, "\n")
    print(OutArgumentsFile, Format_2330, ShadeEmisRatioIn, ShadeEmisRatioOut)
    print(OutArgumentsFile, Format_2331, ShadeHcRatioIn, ShadeHcRatioOut)
    print(OutArgumentsFile, Format_2332, HcUnshadedIn, HcUnshadedOut)
    print(OutArgumentsFile, "\n")
    i = 2
    while i <= nlayer:
        print(OutArgumentsFile, Format_2160, i, hcgas[i], i, hrgas[i])
        i += 1
    print(OutArgumentsFile, "\n")
    print(OutArgumentsFile, "  Error Tolerance = {:12.6E}\n", AchievedErrorTolerance)
    print(OutArgumentsFile, "\n")
    print(OutArgumentsFile, "  Number of Iterations = {}\n", NumOfIter)

# WriteOutputEN673 – similar
def WriteOutputEN673(
    inout OutArgumentsFile: InputOutputFile,
    DBGD: String,
    nlayer: Int,
    ufactor: Float64,
    hout: Float64,
    hin: Float64,
    Ra: Array1D[Float64],
    Nu: Array1D[Float64],
    hg: Array1D[Float64],
    hr: Array1D[Float64],
    hs: Array1D[Float64],
    inout nperr: Int):
    EP_SIZE_CHECK(Ra, maxlay)
    EP_SIZE_CHECK(Nu, maxlay)
    EP_SIZE_CHECK(hg, maxlay)
    EP_SIZE_CHECK(hr, maxlay)
    EP_SIZE_CHECK(hs, maxlay)
    var DATE_TIME: Array1D[Int] = Array1D[Int]()
    var now = datetime.datetime.now()
    DATE_TIME[1] = now.year
    DATE_TIME[2] = now.month
    DATE_TIME[3] = now.day
    DATE_TIME[5] = now.hour
    DATE_TIME[6] = now.minute
    DATE_TIME[7] = now.second
    var real_CLOCK: Array1D[String] = Array1D[String]()
    var i: Int
    alias Format_2000 = "TARCOG calculation results - {:4}-{:02}-{:02}, {:02}:{:02}:{:02}\n"
    alias Format_2351 = "Basic IGU properties:\n"
    alias Format_2120 = "  Ufactor  = {:12.6F}\n"
    alias Format_2220 = "  he = {:8.4F},   hi = {:8.4F}\n"
    alias Format_2155 = "  Ra({:1}) ={:15.6F}        Nu({:1}) ={:12.6F}\n"
    alias Format_2230 = "  hg{:2} ={:15.6E}      hr{:2} ={:15.6E}      hs{:2} ={:15.6E}\n"
    # date_and_time already
    print(OutArgumentsFile, "\n")
    print(OutArgumentsFile, Format_2000, DATE_TIME[1], DATE_TIME[2], DATE_TIME[3], DATE_TIME[5], DATE_TIME[6], DATE_TIME[7])
    print(OutArgumentsFile, "\n")
    print(OutArgumentsFile, "\n")
    print(OutArgumentsFile, Format_2351)
    print(OutArgumentsFile, "\n")
    print(OutArgumentsFile, Format_2120, ufactor)
    print(OutArgumentsFile, "\n")
    print(OutArgumentsFile, Format_2220, hout, hin)
    print(OutArgumentsFile, "\n")
    i = 1
    while i <= nlayer - 1:
        print(OutArgumentsFile, Format_2155, i, Ra[i], i, Nu[i])
        i += 1
    print(OutArgumentsFile, "\n")
    i = 1
    while i <= nlayer - 1:
        print(OutArgumentsFile, Format_2230, i, hg[i], i, hr[i], i, hs[i])
        i += 1

# WriteTARCOGInputFile – similar, but with many parameters; we'll translate loops similarly
def WriteTARCOGInputFile(
    inout state: EnergyPlusData,
    inout files: Files,
    VerNum: String,
    tout: Float64,
    tind: Float64,
    trmin: Float64,
    wso: Float64,
    iwd: Int,
    wsi: Float64,
    dir: Float64,
    outir: Float64,
    isky: Int,
    tsky: Float64,
    esky: Float64,
    fclr: Float64,
    VacuumPressure: Float64,
    VacuumMaxGapThickness: Float64,
    CalcDeflection: DeflectionCalculation,
    Pa: Float64,
    Pini: Float64,
    Tini: Float64,
    ibc: Array1D[Int],
    hout: Float64,
    hin: Float64,
    standard: Stdrd,
    ThermalMod: TARCOGThermalModel,
    SDScalar: Float64,
    height: Float64,
    heightt: Float64,
    width: Float64,
    tilt: Float64,
    totsol: Float64,
    nlayer: Int,
    LayerType: Array1D[TARCOGLayerType],
    thick: Array1D[Float64],
    scon: Array1D[Float64],
    YoungsMod: Array1D[Float64],
    PoissonsRat: Array1D[Float64],
    asol: Array1D[Float64],
    tir: Array1D[Float64],
    emis: Array1D[Float64],
    Atop: Array1D[Float64],
    Abot: Array1D[Float64],
    Al: Array1D[Float64],
    Ar: Array1D[Float64],
    Ah: Array1D[Float64],
    SupportPillar: Array1D[Int],
    PillarSpacing: Array1D[Float64],
    PillarRadius: Array1D[Float64],
    SlatThick: Array1D[Float64],
    SlatWidth: Array1D[Float64],
    SlatAngle: Array1D[Float64],
    SlatCond: Array1D[Float64],
    SlatSpacing: Array1D[Float64],
    SlatCurve: Array1D[Float64],
    nslice: Array1D[Int],
    gap: Array1D[Float64],
    GapDef: Array1D[Float64],
    vvent: Array1D[Float64],
    tvent: Array1D[Float64],
    presure: Array1D[Float64],
    nmix: Array1D[Int],
    iprop: Array2A[Int],
    frct: Array2A[Float64],
    xgcon: Array2A[Float64],
    xgvis: Array2A[Float64],
    xgcp: Array2A[Float64],
    xwght: Array1D[Float64],
    gama: Array1D[Float64]):
    EP_SIZE_CHECK(ibc, 2)
    EP_SIZE_CHECK(LayerType, maxlay)
    EP_SIZE_CHECK(thick, maxlay)
    EP_SIZE_CHECK(scon, maxlay)
    EP_SIZE_CHECK(YoungsMod, maxlay)
    EP_SIZE_CHECK(PoissonsRat, maxlay)
    EP_SIZE_CHECK(asol, maxlay)
    EP_SIZE_CHECK(tir, maxlay2)
    EP_SIZE_CHECK(emis, maxlay2)
    EP_SIZE_CHECK(Atop, maxlay)
    EP_SIZE_CHECK(Abot, maxlay)
    EP_SIZE_CHECK(Al, maxlay)
    EP_SIZE_CHECK(Ar, maxlay)
    EP_SIZE_CHECK(Ah, maxlay)
    EP_SIZE_CHECK(SupportPillar, maxlay)
    EP_SIZE_CHECK(PillarSpacing, maxlay)
    EP_SIZE_CHECK(PillarRadius, maxlay)
    EP_SIZE_CHECK(SlatThick, maxlay)
    EP_SIZE_CHECK(SlatWidth, maxlay)
    EP_SIZE_CHECK(SlatAngle, maxlay)
    EP_SIZE_CHECK(SlatCond, maxlay)
    EP_SIZE_CHECK(SlatSpacing, maxlay)
    EP_SIZE_CHECK(SlatCurve, maxlay)
    EP_SIZE_CHECK(nslice, maxlay)
    EP_SIZE_CHECK(gap, maxlay)
    EP_SIZE_CHECK(GapDef, MaxGap)
    EP_SIZE_CHECK(vvent, maxlay1)
    EP_SIZE_CHECK(tvent, maxlay1)
    EP_SIZE_CHECK(presure, maxlay1)
    EP_SIZE_CHECK(nmix, maxlay1)
    iprop.dim(maxgas, maxlay1)
    frct.dim(maxgas, maxlay1)
    xgcon.dim(3, maxgas)
    xgvis.dim(3, maxgas)
    xgcp.dim(3, maxgas)
    EP_SIZE_CHECK(xwght, maxgas)
    EP_SIZE_CHECK(gama, maxgas)
    var i: Int
    var j: Int
    var NumOfProvGasses: Int
    var DATE_TIME: Array1D[Int] = Array1D[Int]()
    var now = datetime.datetime.now()
    DATE_TIME[1] = now.year
    DATE_TIME[2] = now.month
    DATE_TIME[3] = now.day
    DATE_TIME[5] = now.hour
    DATE_TIME[6] = now.minute
    DATE_TIME[7] = now.second
    var real_CLOCK: Array1D[String] = Array1D[String]()
    alias Format_111 = "*\n"
   