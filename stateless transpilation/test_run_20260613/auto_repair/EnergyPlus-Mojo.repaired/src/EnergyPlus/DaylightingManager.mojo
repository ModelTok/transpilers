from DataBSDFWindow import *
from DataDaylighting import *
from DataSurfaces import *
from EnergyPlus import *
from Vector3 import Vector3
from Array1D import Array1D
from Array2D import Array2D
from math import *
from algorithm import *
from cassert import *
from cmath import *
from format import *
from string import *
from Array.functions import *
from Fmath import *
from member.functions import *
from random import *
from string.functions import *
from DElightManagerF import *
from Data.EnergyPlusData import EnergyPlusData
from DataBSDFWindow import *
from DataDElight import *
from DataDaylightingDevices import *
from DataEnvironment import *
from DataErrorTracking import *
from DataHeatBalance import *
from DataIPShortCuts import *
from DataPrecisionGlobals import *
from DataStringGlobals import *
from DataSurfaces import *
from DataSystemVariables import *
from DataViewFactorInformation import *
from DaylightingDevices import *
from DaylightingManager import *
from DisplayRoutines import *
from FileSystem import *
from General import *
from HeatBalanceManager import *
from InputProcessing.InputProcessor import *
from InternalHeatGains import *
from OutputProcessor import *
from OutputReportPredefined import *
from PierceSurface import *
from SQLiteProcedures import *
from ScheduleManager import *
from SolarReflectionManager import *
from SolarShading import *
from SurfaceOctree import *
from UtilityRoutines import *
from WindowComplexManager import *
from WindowManager import *
namespace EnergyPlus:
    namespace Dayltg:
        const octreeCrossover: Int = 100
        const NTH: Int = 18
        const NPH: Int = 8
        const NPHMAX: Int = 10
        const NTHMAX: Int = 16
        struct SunAngles:
            var phi: Float64 = 0.0
            var sinPhi: Float64 = 0.0
            var cosPhi: Float64 = 0.0
            var theta: Float64 = 0.0
        def DayltgAveInteriorReflectance(state: EnergyPlusData, enclNum: Int):

        def CalcDayltgCoefficients(state: EnergyPlusData):

        def CalcDayltgCoeffsRefMapPoints(state: EnergyPlusData):

        def CalcDayltgCoeffsRefPoints(state: EnergyPlusData, daylightCtrlNum: Int):

        def CalcDayltgCoeffsMapPoints(state: EnergyPlusData, mapNum: Int):

        def FigureDayltgCoeffsAtPointsSetupForWindow(
            state: EnergyPlusData,
            daylightCtrlNum: Int,
            iRefPoint: Int,
            loopwin: Int,
            CalledFrom: CalledFor,
            RREF: Vector3[Float64],
            VIEWVC: Vector3[Float64],
            IWin: Int,
            IWin2: Int,
            NWX: Int,
            NWY: Int,
            W2: Vector3[Float64],
            W3: Vector3[Float64],
            W21: Vector3[Float64],
            W23: Vector3[Float64],
            LSHCAL: Int,
            InShelfSurf: Int,
            ICtrl: Int,
            ShType: WinShadingType,
            BlNum: Int,
            WNORM2: Vector3[Float64],
            extWinType: ExtWinType,
            IConst: Int,
            RREF2: Vector3[Float64],
            DWX: Float64,
            DWY: Float64,
            DAXY: Float64,
            U2: Vector3[Float64],
            U23: Vector3[Float64],
            U21: Vector3[Float64],
            VIEWVC2: Vector3[Float64],
            is_Rectangle: Bool,
            is_Triangle: Bool,
            MapNum: Int = 0):

        def FigureDayltgCoeffsAtPointsForWindowElements(...):

        def InitializeCFSDaylighting(...):

        def InitializeCFSStateData(...):

        def AllocateForCFSRefPointsState(...):

        def AllocateForCFSRefPointsGeometry(...):

        def CFSRefPointSolidAngle(...):

        def CFSRefPointPosFactor(...):

        def CalcObstrMultiplier(state: EnergyPlusData, GroundHitPt: Vector3[Float64], AltSteps: Int, AzimSteps: Int) -> Float64:
            return 0.0
        def FigureDayltgCoeffsAtPointsForSunPosition(...):

        def FigureRefPointDayltgFactorsToAddIllums(...):

        def FigureMapPointDayltgFactorsToAddIllums(...):

        def GetDaylightingParametersInput(state: EnergyPlusData):

        def GetInputIlluminanceMap(state: EnergyPlusData, ErrorsFound: Bool):

        def GetDaylightingControls(state: EnergyPlusData, ErrorsFound: Bool):

        def GeometryTransformForDaylighting(state: EnergyPlusData):

        def GetInputDayliteRefPt(state: EnergyPlusData, ErrorsFound: Bool):

        def doesDayLightingUseDElight(state: EnergyPlusData) -> Bool:
            return False
        def CheckTDDsAndLightShelvesInDaylitZones(state: EnergyPlusData):

        def AssociateWindowShadingControlWithDaylighting(state: EnergyPlusData):

        def GetLightWellData(state: EnergyPlusData, ErrorsFound: Bool):

        def findWinShadingStatus(state: EnergyPlusData, IWin: Int) -> WinCover:
            return WinCover.Bare
        def DayltgGlare(state: EnergyPlusData, IL: Int, BLUM: Float64, daylightCtrlNum: Int) -> Float64:
            return 0.0
        def DayltgGlareWithIntWins(state: EnergyPlusData, daylightCtrlNum: Int):

        def DayltgExtHorizIllum(state: EnergyPlusData, HI: Illums):

        def DayltgHitObstruction(state: EnergyPlusData, IHOUR: Int, IWin: Int, R1: Vector3[Float64], RN: Vector3[Float64]) -> Float64:
            return 1.0
        def DayltgHitInteriorObstruction(state: EnergyPlusData, IWin: Int, R1: Vector3[Float64], R2: Vector3[Float64]) -> Bool:
            return False
        def DayltgHitBetWinObstruction(state: EnergyPlusData, IWin1: Int, IWin2: Int, R1: Vector3[Float64], R2: Vector3[Float64]) -> Bool:
            return False
        def initDaylighting(state: EnergyPlusData, initSurfaceHeatBalancefirstTime: Bool):

        def manageDaylighting(state: EnergyPlusData):

        def DayltgInteriorIllum(state: EnergyPlusData, daylightCtrlNum: Int):

        def DayltgInteriorTDDIllum(state: EnergyPlusData):

        def DayltgElecLightingControl(state: EnergyPlusData):

        def DayltgGlarePositionFactor(X: Float64, Y: Float64) -> Float64:
            return 0.0
        def DayltgInterReflectedIllum(state: EnergyPlusData, ISunPos: Int, IHR: Int, enclNum: Int, IWin: Int):

        def ComplexFenestrationLuminances(...):

        def DayltgInterReflectedIllumComplexFenestration(...):

        def DayltgDirectIllumComplexFenestration(...):

        def DayltgDirectSunDiskComplexFenestration(...):

        def DayltgSkyLuminance(state: EnergyPlusData, sky: SkyType, THSKY: Float64, PHSKY: Float64) -> Float64:
            return 0.0
        def ProfileAngle(state: EnergyPlusData, SurfNum: Int, CosDirSun: Vector3[Float64], HorOrVert: Orientation) -> Float64:
            return 0.0
        def DayltgClosestObstruction(state: EnergyPlusData, RecPt: Vector3[Float64], RayVec: Vector3[Float64],
            NearestHitSurfNum: Int, NearestHitPt: Vector3[Float64]):

        def DayltgSurfaceLumFromSun(state: EnergyPlusData, IHR: Int, Ray: Vector3[Float64], ReflSurfNum: Int,
            ReflHitPt: Vector3[Float64]) -> Float64:
            return 0.0
        def DayltgInteriorMapIllum(state: EnergyPlusData):

        def ReportIllumMap(state: EnergyPlusData, MapNum: Int):

        def CloseReportIllumMaps(state: EnergyPlusData):

        def CloseDFSFile(state: EnergyPlusData):

        def DayltgSetupAdjZoneListsAndPointers(state: EnergyPlusData):

        def CreateShadeDeploymentOrder(state: EnergyPlusData, enclNum: Int):

        def MapShadeDeploymentOrderToLoopNumber(state: EnergyPlusData, enclNum: Int):

        def DayltgInterReflIllFrIntWins(state: EnergyPlusData, enclNum: Int):

        def CalcMinIntWinSolidAngs(state: EnergyPlusData):

        def CheckForGeometricTransform(state: EnergyPlusData, doTransform: Bool, OldAspectRatio: Float64, NewAspectRatio: Float64):

        def WriteDaylightMapTitle(state: EnergyPlusData, mapNum: Int, mapFile: InputOutputFile, mapName: String,
            environmentName: String, ZoneNum: Int, refPts: String, zcoord: Float64):

        struct DaylightingData:
            var maxControlRefPoints: Int = 0
            var maxShadeDeployOrderExtWins: Int = 0
            var maxDayltgExtWins: Int = 0
            var maxEnclSubSurfaces: Int = 0
            var mapResultsToReport: Bool = False
            var mapResultsReported: Bool = False
            var MapColSep: Char = ' '
            var DFSReportSizingDays: Bool = False
            var DFSReportAllShadowCalculationDays: Bool = False