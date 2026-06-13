from algorithm import *
from cmath import *
from fstream import *
from ostream import *
from ObjexxFCL.Array1D import Array1D
from ObjexxFCL.string.functions import *
from DElight.DElightManagerC import *
from Construction import *
from DElightManagerF import *
from .Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataDElight import *
from DataEnvironment import *
from EnergyPlus.DataGlobals import *
from DataHeatBalance import *
from EnergyPlus.DataIPShortCuts import *
from EnergyPlus.DataStringGlobals import *
from DataSurfaces import *
from DaylightingManager import *
from General import *
from .InputProcessing.InputProcessor import *
from InternalHeatGains import *
from Material import *
from OutputProcessor import *
from UtilityRoutines import *
def DElightInputGenerator(state: EnergyPlusData):
    var iNumDElightZones: Int
    var iNumOpaqueSurfs: Int
    var iNumWindows: Int
    var iconstruct: Int
    var iMatlLayer: Int
    var rExtVisRefl: Float64
    var rLightLevel: Float64
    var CosBldgRelNorth: Float64
    var SinBldgRelNorth: Float64
    var CosZoneRelNorth: Float64
    var SinZoneRelNorth: Float64
    var Xb: Float64
    var Yb: Float64
    var RefPt_WCS_Coord: Vector3[Float64]
    var iWndoConstIndexes: Array1D[Int](100)
    var lWndoConstFound: Bool
    var cNameWOBlanks: String
    var ErrorsFound: Bool
    var iHostedCFS: Int
    var lWndoIsDoppelganger: Bool
    var iDoppelganger: Int
    var ldoTransform: Bool
    var roldAspectRatio: Float64
    var rnewAspectRatio: Float64
    var Xo: Float64
    var XnoRot: Float64
    var Xtrans: Float64
    var Yo: Float64
    var YnoRot: Float64
    var Ytrans: Float64
    var Format_901: StringLiteral = "Version EPlus : DElight input generated from EnergyPlus processed input {}\n"
    var Format_902: StringLiteral = "\nBuilding_Name {}\nSite_Latitude  {:12.4F}\nSite_Longitude {:12.4F}\nSite_Altitude  {:12.4F}\nBldg_Azimuth   {:12.4F}\nSite_Time_Zone {:12.4F}\nAtm_Moisture  0.07 0.07 0.07 0.07 0.07 0.07 0.07 0.07 0.07 0.07 0.07 0.07\nAtm_Turbidity 0.12 0.12 0.12 0.12 0.12 0.12 0.12 0.12 0.12 0.12 0.12 0.12\n"
    var Format_903: StringLiteral = "\nZONES\nN_Zones {:4}\n"
    var Format_904: StringLiteral = "\nZONE DATA\nZone {}\nBldgSystem_Zone_Origin {:12.4F}{:12.4F}{:12.4F}\nZone_Azimuth    {:12.4F}\nZone_Multiplier {:5}\nZone_Floor_Area {:12.4F}\nZone_Volume     {:12.4F}\nZone_Installed_Lighting {:12.4F}\nMin_Input_Power    {:12.4F}\nMin_Light_Fraction {:12.4F}\nLight_Ctrl_Steps   {:3}\nLight_Ctrl_Prob    {:12.4F}\nView_Azimuth  0.0\nMax_Grid_Node_Area {:12.4F}\n"
    var Format_905: StringLiteral = "\nZONE LIGHTING SCHEDULES\nN_Lt_Scheds 0\n"
    var Format_906: StringLiteral = "\nZONE SURFACES\nN_Surfaces {:4}\n"
    var Format_907: StringLiteral = "\nZONE SURFACE DATA\nSurface {}\nWCS_Azimuth {:12.4F}\nWCS_Tilt    {:12.4F}\nVis_Refl    {:12.4F}\nExt_Refl    {:12.4F}\nGnd_Refl     0.2\nN_WCS_Vertices {:6}\n"
    var Format_908: StringLiteral = "Vertex {:12.4F}{:12.4F}{:12.4F}\n"
    var Format_909: StringLiteral = "\nSURFACE WINDOWS\nN_Windows {:6}\n"
    var Format_910: StringLiteral = "\nSURFACE WINDOW DATA\nWindow     {}\nGlass_Type {:8}\nShade_Flag   0\nOverhang_Fin_Depth    0.0 0.0 0.0\nOverhang_Fin_Distance 0.0 0.0 0.0\nN_WCS_Vertices {:4}\n"
    var Format_911: StringLiteral = "\nSURFACE CFS\nN_CFS {:6}\n"
    var Format_915: StringLiteral = "\nCOMPLEX FENESTRATION DATA\nCFS_Name   {}\nCFS_Type   {}\nFenestration_Rotation {:12.4F}\nN_WCS_Vertices {:4}\n"
    var Format_912: StringLiteral = "\nZONE REFERENCE POINTS\nN_Ref_Pts {:4}\n"
    var Format_913: StringLiteral = "\nZONE REFERENCE POINT DATA\nReference_Point {}\nRefPt_WCS_Coords {:12.4F}{:12.4F}{:12.4F}\nZone_Fraction {:12.4F}\nLight_Set_Pt {:12.4F}\nLight_Ctrl_Type {:4}\n"
    var Format_914: StringLiteral = "\nBUILDING SHADES\nN_BShades 0\n"
    var Format_920: StringLiteral = "\nLIBRARY DATA\nGLASS TYPES\nN_Glass_Types {:4}\n"
    var Format_921: StringLiteral = "\nGLASS TYPE DATA\nName {:6}\nEPlusDiffuse_Transmittance   {:12.4F}\nEPlusDiffuse_Int_Reflectance {:12.4F}\nEPlus_Vis_Trans_Coeff_1 {:17.9F}\nEPlus_Vis_Trans_Coeff_2 {:17.9F}\nEPlus_Vis_Trans_Coeff_3 {:17.9F}\nEPlus_Vis_Trans_Coeff_4 {:17.9F}\nEPlus_Vis_Trans_Coeff_5 {:17.9F}\nEPlus_Vis_Trans_Coeff_6 {:17.9F}\n"
    ErrorsFound = False
    GetInputDElightComplexFenestration(state, ErrorsFound)
    CheckForGeometricTransform(state, ldoTransform, roldAspectRatio, rnewAspectRatio)
    iNumDElightZones = 0
    var iNumWndoConsts: Int = 0
    var delightInFile = state.files.delightIn.open(state, "DElightInputGenerator", state.files.outputControl.delightin)
    print(delightInFile, Format_901, state.dataStrGlobals.CurrentDateTime)
    cNameWOBlanks = ReplaceBlanksWithUnderscores(state.dataHeatBal.BuildingName)
    print(delightInFile, Format_902, cNameWOBlanks, state.dataEnvrn.Latitude, state.dataEnvrn.Longitude, state.dataEnvrn.Elevation * M2FT, state.dataHeatBal.BuildingAzimuth, state.dataEnvrn.TimeZoneNumber)
    CosBldgRelNorth = cos(-state.dataHeatBal.BuildingAzimuth * Constant.DegToRad)
    SinBldgRelNorth = sin(-state.dataHeatBal.BuildingAzimuth * Constant.DegToRad)
    for znDayl in state.dataDayltg.daylightControl:
        if znDayl.DaylightMethod == Dayltg.DaylightingMethod.DElight:
            if znDayl.TotalDaylRefPoints == 0:
                ShowSevereError(state, "No Reference Points input for daylighting zone using DElight =" + znDayl.Name)
                ErrorsFound = True
            if znDayl.TotalDaylRefPoints > 100:
                znDayl.TotalDaylRefPoints = 100
                ShowWarningError(state, "Maximum of 100 Reference Points exceeded for daylighting zone using DElight =" + znDayl.Name)
                ShowWarningError(state, "  Only first 100 Reference Points included in DElight analysis")
            assert(znDayl.refPts.size() == znDayl.TotalDaylRefPoints)
            for refPt in znDayl.refPts:
                refPt.absCoords = {0.0, 0.0, 0.0}
                refPt.lums[Int(Lum.Illum)] = 0.0
                refPt.glareIndex = 0.0
            iNumDElightZones += 1
    print(delightInFile, Format_903, iNumDElightZones)
    for znDayl in state.dataDayltg.daylightControl:
        if znDayl.DaylightMethod == Dayltg.DaylightingMethod.DElight:
            var izone: Int = Util.FindItemInList(znDayl.ZoneName, state.dataHeatBal.Zone)
            if izone != 0:
                rLightLevel = GetDesignLightingLevelForZone(state, izone)
                CheckLightsReplaceableMinMaxForZone(state, izone)
                var zn = state.dataHeatBal.Zone(izone)
                cNameWOBlanks = ReplaceBlanksWithUnderscores(zn.Name)
                print(delightInFile, Format_904, cNameWOBlanks, zn.OriginX * M2FT, zn.OriginY * M2FT, zn.OriginZ * M2FT, zn.RelNorth, zn.Multiplier * zn.ListMultiplier, zn.FloorArea * M22FT2, zn.Volume * M32FT3, rLightLevel / (zn.FloorArea * M22FT2 + 0.00001), znDayl.MinPowerFraction, znDayl.MinLightFraction, znDayl.LightControlSteps, znDayl.LightControlProbability, znDayl.DElightGriddingResolution * M22FT2)
                CosZoneRelNorth = cos(-zn.RelNorth * Constant.DegToRad)
                SinZoneRelNorth = sin(-zn.RelNorth * Constant.DegToRad)
                print(delightInFile, Format_905)
                iNumOpaqueSurfs = 0
                for spaceNum in zn.spaceIndexes:
                    var thisSpace = state.dataHeatBal.space(spaceNum)
                    for isurf in range(thisSpace.HTSurfaceFirst, thisSpace.HTSurfaceLast + 1):
                        var surf = state.dataSurface.Surface(isurf)
                        if surf.Class == SurfaceClass.Wall:
                            iNumOpaqueSurfs += 1
                        if surf.Class == SurfaceClass.Roof:
                            iNumOpaqueSurfs += 1
                        if surf.Class == SurfaceClass.Floor:
                            iNumOpaqueSurfs += 1
                print(delightInFile, Format_906, iNumOpaqueSurfs)
                for spaceNum in zn.spaceIndexes:
                    var thisSpace = state.dataHeatBal.space(spaceNum)
                    var iSurfaceFirst: Int = thisSpace.HTSurfaceFirst
                    var iSurfaceLast: Int = thisSpace.HTSurfaceLast
                    for isurf in range(iSurfaceFirst, iSurfaceLast + 1):
                        var surf = state.dataSurface.Surface(isurf)
                        if (surf.Class == SurfaceClass.Wall) or (surf.Class == SurfaceClass.Roof) or (surf.Class == SurfaceClass.Floor):
                            iconstruct = surf.Construction
                            if surf.ExtSolar:
                                iMatlLayer = state.dataConstruction.Construct(iconstruct).LayerPoint(1)
                                rExtVisRefl = 1.0 - state.dataMaterial.materials(iMatlLayer).AbsorpVisible
                            else:
                                rExtVisRefl = 0.0
                            cNameWOBlanks = ReplaceBlanksWithUnderscores(surf.Name)
                            print(delightInFile, Format_907, cNameWOBlanks, surf.Azimuth, surf.Tilt, state.dataConstruction.Construct(iconstruct).ReflectVisDiffBack, rExtVisRefl, surf.Sides)
                            for ivert in range(1, surf.Sides + 1):
                                print(delightInFile, Format_908, surf.Vertex(ivert).x * M2FT, surf.Vertex(ivert).y * M2FT, surf.Vertex(ivert).z * M2FT)
                            iNumWindows = 0
                            for iwndo in range(iSurfaceFirst, iSurfaceLast + 1):
                                if state.dataSurface.Surface(iwndo).Class == SurfaceClass.Window:
                                    var wndo = state.dataSurface.Surface(iwndo)
                                    if wndo.BaseSurfName == surf.Name:
                                        if wndo.Multiplier > 1.0:
                                            ShowSevereError(state, "Multiplier > 1.0 for window " + wndo.Name + " not allowed since it is in a zone with DElight daylighting.")
                                            ErrorsFound = True
                                        if wndo.HasShadeControl:
                                            ShowSevereError(state, "Shading Device on window " + wndo.Name + " dynamic control is not supported in a zone with DElight daylighting.")
                                            ErrorsFound = True
                                        lWndoIsDoppelganger = False
                                        for cfs in state.dataDayltg.DElightComplexFene:
                                            if wndo.Name == cfs.wndwName:
                                                lWndoIsDoppelganger = True
                                        if not lWndoIsDoppelganger:
                                            iNumWindows += 1
                            print(delightInFile, Format_909, iNumWindows)
                            if iNumWindows > 0:
                                for iwndo2 in range(iSurfaceFirst, iSurfaceLast + 1):
                                    if state.dataSurface.Surface(iwndo2).Class == SurfaceClass.Window:
                                        var wndo2 = state.dataSurface.Surface(iwndo2)
                                        if wndo2.BaseSurfName == surf.Name:
                                            lWndoIsDoppelganger = False
                                            for cfs in state.dataDayltg.DElightComplexFene:
                                                if wndo2.Name == cfs.wndwName:
                                                    lWndoIsDoppelganger = True
                                            if not lWndoIsDoppelganger:
                                                iconstruct = wndo2.Construction
                                                lWndoConstFound = False
                                                for iconst in range(1, iNumWndoConsts + 1):
                                                    if iconstruct == iWndoConstIndexes(iconst):
                                                        lWndoConstFound = True
                                                if not lWndoConstFound:
                                                    iNumWndoConsts += 1
                                                    iWndoConstIndexes(iNumWndoConsts) = iconstruct
                                                cNameWOBlanks = ReplaceBlanksWithUnderscores(wndo2.Name)
                                                print(delightInFile, Format_910, cNameWOBlanks, iconstruct + 10000, wndo2.Sides)
                                                for ivert in range(1, wndo2.Sides + 1):
                                                    print(delightInFile, Format_908, wndo2.Vertex(ivert).x * M2FT, wndo2.Vertex(ivert).y * M2FT, wndo2.Vertex(ivert).z * M2FT)
                            iHostedCFS = 0
                            for cfs in state.dataDayltg.DElightComplexFene:
                                if surf.Name == cfs.surfName:
                                    iHostedCFS += 1
                            print(delightInFile, Format_911, iHostedCFS)
                            for cfs in state.dataDayltg.DElightComplexFene:
                                if surf.Name == cfs.surfName:
                                    iDoppelganger = 0
                                    for iwndo3 in range(iSurfaceFirst, iSurfaceLast + 1):
                                        var wndo3 = state.dataSurface.Surface(iwndo3)
                                        if wndo3.Class == SurfaceClass.Window:
                                            if wndo3.Name == cfs.wndwName:
                                                iDoppelganger = iwndo3
                                    if iDoppelganger > 0:
                                        var doppelgangerSurf = state.dataSurface.Surface(iDoppelganger)
                                        cNameWOBlanks = ReplaceBlanksWithUnderscores(cfs.Name)
                                        print(delightInFile, Format_915, cNameWOBlanks, cfs.ComplexFeneType, cfs.feneRota, doppelgangerSurf.Sides)
                                        for ivert in range(1, doppelgangerSurf.Sides + 1):
                                            print(delightInFile, Format_908, doppelgangerSurf.Vertex(ivert).x * M2FT, doppelgangerSurf.Vertex(ivert).y * M2FT, doppelgangerSurf.Vertex(ivert).z * M2FT)
                                    if iDoppelganger == 0:
                                        ShowSevereError(state, "No Doppelganger Window Surface found for Complex Fenestration =" + cfs.Name)
                                        ErrorsFound = True
                print(delightInFile, Format_912, znDayl.TotalDaylRefPoints)
                for refPt in state.dataDayltg.DaylRefPt:
                    if izone == refPt.ZoneNum:
                        var thisZone = state.dataHeatBal.Zone(izone)
                        if znDayl.TotalDaylRefPoints <= 100:
                            if state.dataSurface.DaylRefWorldCoordSystem:
                                RefPt_WCS_Coord = refPt.coords
                            else:
                                Xb = refPt.coords.x * CosZoneRelNorth - refPt.coords.y * SinZoneRelNorth + thisZone.OriginX
                                Yb = refPt.coords.x * SinZoneRelNorth + refPt.coords.y * CosZoneRelNorth + thisZone.OriginY
                                RefPt_WCS_Coord.x = Xb * CosBldgRelNorth - Yb * SinBldgRelNorth
                                RefPt_WCS_Coord.y = Xb * SinBldgRelNorth + Yb * CosBldgRelNorth
                                RefPt_WCS_Coord.z = refPt.coords.z + thisZone.OriginZ
                                if ldoTransform:
                                    Xo = RefPt_WCS_Coord.x
                                    Yo = RefPt_WCS_Coord.y
                                    XnoRot = Xo * CosBldgRelNorth + Yo * SinBldgRelNorth
                                    YnoRot = Yo * CosBldgRelNorth - Xo * SinBldgRelNorth
                                    Xtrans = XnoRot * sqrt(rnewAspectRatio / roldAspectRatio)
                                    Ytrans = YnoRot * sqrt(roldAspectRatio / rnewAspectRatio)
                                    RefPt_WCS_Coord.x = Xtrans * CosBldgRelNorth - Ytrans * SinBldgRelNorth
                                    RefPt_WCS_Coord.y = Xtrans * SinBldgRelNorth + Ytrans * CosBldgRelNorth
                            znDayl.refPts(refPt.indexToFracAndIllum).absCoords = RefPt_WCS_Coord
                            if RefPt_WCS_Coord.x < thisZone.MinimumX or RefPt_WCS_Coord.x > thisZone.MaximumX:
                                ShowSevereError(state, "DElightInputGenerator:Reference point X Value outside Zone Min/Max X, Zone=" + zn.Name)
                                ShowContinueError(state, "...X Reference Point= {:.2f}, Zone Minimum X= {:.2f}, Zone Maximum X= {:.2f}".format(thisZone.MinimumX, RefPt_WCS_Coord.x, thisZone.MaximumX))
                                ErrorsFound = True
                            if RefPt_WCS_Coord.y < thisZone.MinimumY or RefPt_WCS_Coord.y > thisZone.MaximumY:
                                ShowSevereError(state, "DElightInputGenerator:Reference point Y Value outside Zone Min/Max Y, Zone=" + zn.Name)
                                ShowContinueError(state, "...Y Reference Point= {:.2f}, Zone Minimum Y= {:.2f}, Zone Maximum Y= {:.2f}".format(thisZone.MinimumY, RefPt_WCS_Coord.y, thisZone.MaximumY))
                                ErrorsFound = True
                            if RefPt_WCS_Coord.z < state.dataHeatBal.Zone(izone).MinimumZ or RefPt_WCS_Coord.z > thisZone.MaximumZ:
                                ShowSevereError(state, "DElightInputGenerator:Reference point Z Value outside Zone Min/Max Z, Zone=" + thisZone.Name)
                                ShowContinueError(state, "...Z Reference Point= {:.2f}, Zone Minimum Z= {:.2f}, Zone Maximum Z= {:.2f}".format(thisZone.MinimumZ, RefPt_WCS_Coord.z, thisZone.MaximumZ))
                                ErrorsFound = True
                            cNameWOBlanks = ReplaceBlanksWithUnderscores(refPt.Name)
                            if refPt.indexToFracAndIllum != 0:
                                print(delightInFile, Format_913, cNameWOBlanks, RefPt_WCS_Coord.x * M2FT, RefPt_WCS_Coord.y * M2FT, RefPt_WCS_Coord.z * M2FT, znDayl.refPts(refPt.indexToFracAndIllum).fracZoneDaylit, znDayl.refPts(refPt.indexToFracAndIllum).illumSetPoint * LUX2FC, znDayl.LightControlType)
                                SetupOutputVariable(state, "Daylighting Reference Point Illuminance", Constant.Units.lux, znDayl.refPts(refPt.indexToFracAndIllum).lums[Int(Lum.Illum)], OutputProcessor.TimeStepType.Zone, OutputProcessor.StoreType.Average, refPt.Name)
                            else:
                                print(delightInFile, Format_913, cNameWOBlanks, RefPt_WCS_Coord.x * M2FT, RefPt_WCS_Coord.y * M2FT, RefPt_WCS_Coord.z * M2FT, 0.0, 0.0 * LUX2FC, znDayl.LightControlType)
    print(delightInFile, Format_914)
    print(delightInFile, Format_920, iNumWndoConsts)
    for iconst in range(1, iNumWndoConsts + 1):
        print(delightInFile, Format_921, iWndoConstIndexes(iconst) + 10000, state.dataConstruction.Construct(iWndoConstIndexes(iconst)).TransDiffVis, state.dataConstruction.Construct(iWndoConstIndexes(iconst)).ReflectVisDiffBack, state.dataConstruction.Construct(iWndoConstIndexes(iconst)).TransVisBeamCoef[0], state.dataConstruction.Construct(iWndoConstIndexes(iconst)).TransVisBeamCoef[1], state.dataConstruction.Construct(iWndoConstIndexes(iconst)).TransVisBeamCoef[2], state.dataConstruction.Construct(iWndoConstIndexes(iconst)).TransVisBeamCoef[3], state.dataConstruction.Construct(iWndoConstIndexes(iconst)).TransVisBeamCoef[4], state.dataConstruction.Construct(iWndoConstIndexes(iconst)).TransVisBeamCoef[5])
    if ErrorsFound:
        ShowFatalError(state, "Problems with Daylighting:DElight input, see previous error messages")
def GenerateDElightDaylightCoefficients(inout dLatitude: Float64, inout iErrorFlag: Int):
    delightdaylightcoefficients(dLatitude, iErrorFlag)
def GetInputDElightComplexFenestration(state: EnergyPlusData, inout ErrorsFound: Bool):
    var NumAlpha: Int
    var NumNumber: Int
    var IOStat: Int
    var CFSNum: Int = 0
    var cCurrentModuleObject: StringLiteral = "Daylighting:DELight:ComplexFenestration"
    var TotDElightCFS: Int = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, cCurrentModuleObject)
    state.dataDayltg.DElightComplexFene.allocate(TotDElightCFS)
    for cfs in state.dataDayltg.DElightComplexFene:
        state.dataInputProcessing.inputProcessor.getObjectItem(state, cCurrentModuleObject, CFSNum + 1, state.dataIPShortCut.cAlphaArgs, NumAlpha, state.dataIPShortCut.rNumericArgs, NumNumber, IOStat, state.dataIPShortCut.lNumericFieldBlanks, state.dataIPShortCut.lAlphaFieldBlanks, state.dataIPShortCut.cAlphaFieldNames, state.dataIPShortCut.cNumericFieldNames)
        CFSNum += 1
        cfs.Name = state.dataIPShortCut.cAlphaArgs(1)
        cfs.ComplexFeneType = state.dataIPShortCut.cAlphaArgs(2)
        cfs.surfName = state.dataIPShortCut.cAlphaArgs(3)
        if Util.FindItemInList(cfs.surfName, state.dataSurface.Surface) == 0:
            ShowSevereError(state, cCurrentModuleObject + ": " + cfs.Name + ", invalid " + state.dataIPShortCut.cAlphaFieldNames(3) + "=\"" + cfs.surfName + "\".")
            ErrorsFound = True
        cfs.wndwName = state.dataIPShortCut.cAlphaArgs(4)
        if Util.FindItemInList(cfs.surfName, state.dataSurface.Surface) == 0:
            ShowSevereError(state, cCurrentModuleObject + ": " + cfs.Name + ", invalid " + state.dataIPShortCut.cAlphaFieldNames(4) + "=\"" + cfs.wndwName + "\".")
            ErrorsFound = True
        cfs.feneRota = state.dataIPShortCut.rNumericArgs(1)
        if cfs.feneRota < 0.0 or cfs.feneRota > 360.0:
            ShowSevereError(state, cCurrentModuleObject + ": " + cfs.Name + ", invalid " + state.dataIPShortCut.cNumericFieldNames(1) + " outside of range 0 to 360.")
            ErrorsFound = True
def CheckForGeometricTransform(state: EnergyPlusData, inout doTransform: Bool, inout OldAspectRatio: Float64, inout NewAspectRatio: Float64):
    var CurrentModuleObject: StringLiteral = "GeometryTransform"
    var cAlphas: Array1D[String](1)
    var rNumerics: Array1D[Float64](2)
    doTransform = False
    OldAspectRatio = 1.0
    NewAspectRatio = 1.0
    if state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, CurrentModuleObject) == 1:
        var NAlphas: Int
        var NNum: Int
        var IOStat: Int
        state.dataInputProcessing.inputProcessor.getObjectItem(state, CurrentModuleObject, 1, cAlphas, NAlphas, rNumerics, NNum, IOStat, state.dataIPShortCut.lNumericFieldBlanks, state.dataIPShortCut.lAlphaFieldBlanks, state.dataIPShortCut.cAlphaFieldNames, state.dataIPShortCut.cNumericFieldNames)
        OldAspectRatio = rNumerics(1)
        NewAspectRatio = rNumerics(2)
        if cAlphas(1) != "XY":
            ShowWarningError(state, CurrentModuleObject + ": invalid " + state.dataIPShortCut.cAlphaFieldNames(1) + "=" + cAlphas(1) + "...ignored.")
        doTransform = True
        state.dataSurface.AspectTransform = True
    if state.dataSurface.WorldCoordSystem:
        doTransform = False
        state.dataSurface.AspectTransform = False
def ReplaceBlanksWithUnderscores(InputString: String) -> String:
    var ResultString: String = trimmed(InputString)
    ResultString = ResultString.replace(" ", "_")
    return ResultString
def DElightElecLtgCtrl(iNameLength: Int, cZoneName: String, dBldgLat: Float64, dHISKF: Float64, dHISUNF: Float64, dCloudFraction: Float64, dSOLCOSX: Float64, dSOLCOSY: Float64, dSOLCOSZ: Float64, inout pdPowerReducFac: Float64, inout piErrorFlag: Int):
    var zoneNameArr: List[Int8] = getCharArrayFromString(cZoneName)
    delightelecltgctrl(iNameLength, zoneNameArr.data(), dBldgLat, dHISKF, dHISUNF, dCloudFraction, dSOLCOSX, dSOLCOSY, dSOLCOSZ, pdPowerReducFac, piErrorFlag)
def getCharArrayFromString(originalString: String) -> List[Int8]:
    var returnVal: List[Int8] = List[Int8](originalString)
    returnVal.append(0)
    return returnVal
def getStringFromCharArray(originalCharArray: List[Int8]) -> String:
    return String(originalCharArray)