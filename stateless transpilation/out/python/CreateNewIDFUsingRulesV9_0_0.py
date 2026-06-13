# EXTERNAL DEPS (to wire in glue):
# - InputProcessor (GetObjectItem, GetNewObjectDefInIDD, GetNumObjectsFound, ProcessInput, GetNewUnitNumber, FindItemInList, GetYearFromStartDayString, IsYearNumberALeapYear, GetLeapYearFromStartDayString, FindYearForWeekDay, ScanOutputVariablesForReplacement, ProcessNumber, GetObjectDefInIDD, ProcessRviMviFiles, CloseOut, CreateNewName, CheckSpecialObjects, copyfile)
# - DataVCompareGlobals (IDFRecords, Comments, ProcessingIMFFile, FatalError, FullFileName, FileNamePath, Blank, MaxNameLength, MaxAlphaArgsFound, MaxNumericArgsFound, MaxTotalArgs, NumIDFRecords, Alphas, Numbers, InArgs, TempArgs, AorN, ReqFld, FldNames, FldDefaults, FldUnits, NwAorN, NwReqFld, NwFldNames, NwFldDefaults, NwFldUnits, OutArgs, MatchArg, NumAlphas, NumNumbers, ObjMinFlds, NwNumArgs, NotInNew, OldRepVarName, NewRepVarName, NewRepVarCaution, NumRepVarNames, OTMVarCaution, CMtrVarCaution, CMtrDVarCaution, MakingPretty, ObjectDef, NumObjectDefs)
# - VCompareGlobalRoutines (DisplayString, WriteOutIDFLines, WriteOutIDFLinesAsComments, writePreprocessorObject)
# - DataStringGlobals (ProgramPath, ProgNameConversion)
# - General (MakeUPPERCase, SameString, MakeLowerCase, RoundSigDigits)
# - DataGlobals (ShowMessage, ShowContinueError, ShowFatalError, ShowSevereError, ShowWarningError, Auditf)

from typing import List, Tuple, Optional, Protocol
from dataclasses import dataclass, field

@dataclass
class FenestrationSurf:
    FenSurfName: str = ''
    FenBaseSurfName: str = ''
    FenZoneName: str = ''
    FenShadeControlName: str = ''

@dataclass
class ShadeControl:
    OldShadeControlName: str = ''
    NumZones: int = 0
    ShadeControlZoneName: List[str] = field(default_factory=list)
    SequenceNum: List[int] = field(default_factory=list)

@dataclass
class FieldFlagAndValue:
    wasSet: bool = False
    originalValue: str = ''

_FirstTime = True

def SetThisVersionVariables(deps):
    deps.VerString = 'Conversion 8.9 => 9.0'
    deps.VersionNum = 9.0
    deps.sVersionNum = '9.0'
    deps.IDDFileNameWithPath = deps.ProgramPath.rstrip() + 'V8-9-0-Energy+.idd'
    deps.NewIDDFileNameWithPath = deps.ProgramPath.rstrip() + 'V9-0-0-Energy+.idd'
    deps.RepVarFileNameWithPath = deps.ProgramPath.rstrip() + 'Report Variables 8-9-0 to 9-0-0.csv'

def CreateNewIDFUsingRules(deps, EndOfFile, DiffOnly, InLfn, AskForInput, InputFileName, ArgFile, ArgIDFExtension):
    global _FirstTime
    
    if _FirstTime:
        _FirstTime = False
    
    StillWorking = True
    ArgFileBeingDone = False
    LatestVersion = False
    NoVersion = True
    LocalFileExtension = ArgIDFExtension
    EndOfFile = False
    IOS = 0
    
    FenSurf = []
    ShadeControls = []
    TotWinObjs = 0
    TotObjsWithShadeCtrl = 0
    TotBaseSurfObjs = 0
    TotOldShadeControls = 0
    
    while StillWorking:
        ExitBecauseBadFile = False
        
        while not EndOfFile:
            if AskForInput:
                print('Enter input file name, with path')
                print('-->', end=' ')
                FullFileName = input()
            else:
                if not ArgFile:
                    try:
                        FullFileName = deps.read_input_line(InLfn)
                        IOS = 0
                    except:
                        FullFileName = ''
                        IOS = 1
                elif not ArgFileBeingDone:
                    FullFileName = InputFileName
                    IOS = 0
                    ArgFileBeingDone = True
                else:
                    FullFileName = ''
                    IOS = 1
                
                if FullFileName.startswith('!'):
                    FullFileName = ''
                    continue
            
            UnitsArg = ''
            if IOS != 0:
                FullFileName = ''
            FullFileName = FullFileName.lstrip()
            
            if FullFileName != '':
                deps.DisplayString('Processing IDF -- ' + FullFileName)
                deps.WriteAuditf(' Processing IDF -- ' + FullFileName)
                
                DotPos = FullFileName.rfind('.')
                if DotPos != -1:
                    FileNamePath = FullFileName[:DotPos]
                    LocalFileExtension = FullFileName[DotPos+1:].lower()
                else:
                    FileNamePath = FullFileName
                    print(' assuming file extension of .idf')
                    deps.WriteAuditf(' ..assuming file extension of .idf')
                    FullFileName = FullFileName.rstrip() + '.idf'
                    LocalFileExtension = 'idf'
                
                DifLfn = deps.GetNewUnitNumber()
                
                try:
                    with open(FullFileName, 'r') as f:
                        FileOK = True
                except:
                    FileOK = False
                
                if not FileOK:
                    print('File not found=' + FullFileName)
                    deps.WriteAuditf('File not found=' + FullFileName)
                    EndOfFile = True
                    ExitBecauseBadFile = True
                    break
                
                if LocalFileExtension in ['idf', 'imf']:
                    checkrvi = False
                    ConnComp = False
                    ConnCompCtrl = False
                    
                    if DiffOnly:
                        output_filename = FileNamePath + '.' + LocalFileExtension + 'dif'
                    else:
                        output_filename = FileNamePath + '.' + LocalFileExtension + 'new'
                    
                    if LocalFileExtension == 'imf':
                        deps.ShowWarningError('Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.', deps.Auditf)
                        deps.ProcessingIMFFile = True
                    else:
                        deps.ProcessingIMFFile = False
                    
                    deps.ProcessInput(deps.IDDFileNameWithPath, deps.NewIDDFileNameWithPath, FullFileName)
                    
                    if deps.FatalError:
                        ExitBecauseBadFile = True
                        break
                    
                    DeleteThisRecord = [False] * deps.NumIDFRecords
                    
                    NoVersion = True
                    for Num in range(deps.NumIDFRecords):
                        if deps.MakeUPPERCase(deps.IDFRecords[Num]['Name']) != 'VERSION':
                            continue
                        NoVersion = False
                        break
                    
                    ScheduleTypeLimitsAnyNumber = False
                    for Num in range(deps.NumIDFRecords):
                        if not deps.SameString(deps.IDFRecords[Num]['Name'], 'ScheduleTypeLimits'):
                            continue
                        if not deps.SameString(deps.IDFRecords[Num]['Alphas'][0], 'Any Number'):
                            continue
                        ScheduleTypeLimitsAnyNumber = True
                        break
                    
                    for Num in range(deps.NumIDFRecords):
                        if DeleteThisRecord[Num]:
                            deps.WriteDifLfn(DifLfn, '! Deleting: ' + deps.IDFRecords[Num]['Name'] + '="' + deps.IDFRecords[Num]['Alphas'][0] + '".')
                    
                    TotWinObjs = (deps.GetNumObjectsFound('FENESTRATIONSURFACE:DETAILED') + 
                                 deps.GetNumObjectsFound('WINDOW') + 
                                 deps.GetNumObjectsFound('GLAZEDDOOR'))
                    TotBaseSurfObjs = (deps.GetNumObjectsFound('BUILDINGSURFACE:DETAILED') + 
                                      deps.GetNumObjectsFound('WALL:DETAILED') + 
                                      deps.GetNumObjectsFound('ROOFCEILING:DETAILED') + 
                                      deps.GetNumObjectsFound('FLOOR:DETAILED'))
                    TotBaseSurfObjs += (deps.GetNumObjectsFound('WALL:EXTERIOR') + 
                                       deps.GetNumObjectsFound('WALL:ADIABATIC') + 
                                       deps.GetNumObjectsFound('WALL:UNDERGROUND') + 
                                       deps.GetNumObjectsFound('WALL:INTERZONE'))
                    TotBaseSurfObjs += (deps.GetNumObjectsFound('ROOF') + 
                                       deps.GetNumObjectsFound('CEILING:ADIABATIC') + 
                                       deps.GetNumObjectsFound('CEILING:INTERZONE'))
                    TotBaseSurfObjs += (deps.GetNumObjectsFound('FLOOR:GROUNDCONTACT') + 
                                       deps.GetNumObjectsFound('FLOOR:ADIABATIC') + 
                                       deps.GetNumObjectsFound('FLOOR:INTERZONE'))
                    FenSurf = [FenestrationSurf() for _ in range(TotWinObjs)]
                    
                    TotObjsWithShadeCtrl = 0
                    deps.DisplayString('Processing IDF -- WindowShadingControl preprocessing . . .')
                    
                    for surfNum in range(deps.GetNumObjectsFound('FENESTRATIONSURFACE:DETAILED')):
                        Alphas, NumAlphas, Numbers, NumNumbers, Status = deps.GetObjectItem('FENESTRATIONSURFACE:DETAILED', surfNum)
                        if Alphas[5] != '':
                            FenSurf[TotObjsWithShadeCtrl].FenSurfName = Alphas[0]
                            FenSurf[TotObjsWithShadeCtrl].FenBaseSurfName = Alphas[3]
                            FenSurf[TotObjsWithShadeCtrl].FenShadeControlName = Alphas[5]
                            TotObjsWithShadeCtrl += 1
                    
                    for surfNum in range(deps.GetNumObjectsFound('WINDOW')):
                        Alphas, NumAlphas, Numbers, NumNumbers, Status = deps.GetObjectItem('WINDOW', surfNum)
                        if Alphas[3] != '':
                            FenSurf[TotObjsWithShadeCtrl].FenSurfName = Alphas[0]
                            FenSurf[TotObjsWithShadeCtrl].FenBaseSurfName = Alphas[2]
                            FenSurf[TotObjsWithShadeCtrl].FenShadeControlName = Alphas[3]
                            TotObjsWithShadeCtrl += 1
                    
                    for surfNum in range(deps.GetNumObjectsFound('GLAZEDDOOR')):
                        Alphas, NumAlphas, Numbers, NumNumbers, Status = deps.GetObjectItem('GLAZEDDOOR', surfNum)
                        if Alphas[3] != '':
                            FenSurf[TotObjsWithShadeCtrl].FenSurfName = Alphas[0]
                            FenSurf[TotObjsWithShadeCtrl].FenBaseSurfName = Alphas[2]
                            FenSurf[TotObjsWithShadeCtrl].FenShadeControlName = Alphas[3]
                            TotObjsWithShadeCtrl += 1
                    
                    _process_base_surfaces(deps, FenSurf, TotObjsWithShadeCtrl)
                    
                    TotOldShadeControls = deps.GetNumObjectsFound('WINDOWPROPERTY:SHADINGCONTROL')
                    NumZones = deps.GetNumObjectsFound('ZONE')
                    ShadeControls = [ShadeControl() for _ in range(TotOldShadeControls)]
                    
                    for shadeCtrlNum in range(TotOldShadeControls):
                        ShadeControls[shadeCtrlNum].ShadeControlZoneName = [''] * NumZones
                        ShadeControls[shadeCtrlNum].SequenceNum = [0] * NumZones
                        Alphas, NumAlphas, Numbers, NumNumbers, Status = deps.GetObjectItem('WINDOWPROPERTY:SHADINGCONTROL', shadeCtrlNum)
                        ShadeControls[shadeCtrlNum].OldShadeControlName = Alphas[0]
                        ShadeControls[shadeCtrlNum].NumZones = 0
                        
                        for surfNum in range(TotObjsWithShadeCtrl):
                            zoneFound = False
                            if not deps.SameString(FenSurf[surfNum].FenShadeControlName, ShadeControls[shadeCtrlNum].OldShadeControlName):
                                continue
                            
                            for newZoneNum in range(ShadeControls[shadeCtrlNum].NumZones):
                                if not deps.SameString(FenSurf[surfNum].FenZoneName, ShadeControls[shadeCtrlNum].ShadeControlZoneName[newZoneNum]):
                                    continue
                                zoneFound = True
                                break
                            
                            if zoneFound:
                                continue
                            
                            ShadeControls[shadeCtrlNum].ShadeControlZoneName[ShadeControls[shadeCtrlNum].NumZones] = FenSurf[surfNum].FenZoneName
                            ShadeControls[shadeCtrlNum].NumZones += 1
                    
                    for zoneNum in range(NumZones):
                        seqCount = 0
                        Alphas, NumAlphas, Numbers, NumNumbers, Status = deps.GetObjectItem('ZONE', zoneNum)
                        
                        for shadeCtrlNum in range(TotOldShadeControls):
                            for newZoneNum in range(ShadeControls[shadeCtrlNum].NumZones):
                                if deps.SameString(Alphas[0], ShadeControls[shadeCtrlNum].ShadeControlZoneName[newZoneNum]):
                                    seqCount += 1
                                    ShadeControls[shadeCtrlNum].SequenceNum[newZoneNum] = seqCount
                    
                    deps.DisplayString('Processing IDF -- WindowShadingControl preprocessing complete.')
                    
                    deps.DisplayString('Processing IDF -- Processing idf objects . . .')
                    
                    for Num in range(deps.NumIDFRecords):
                        if DeleteThisRecord[Num]:
                            continue
                        
                        _process_record(deps, Num, DifLfn, DiffOnly, LocalFileExtension, NoVersion, 
                                      ScheduleTypeLimitsAnyNumber, checkrvi, FenSurf, TotObjsWithShadeCtrl,
                                      ShadeControls, TotOldShadeControls, NumZones, DeleteThisRecord)
                    
                    deps.DisplayString('Processing IDF -- Processing idf objects complete.')
                    
                    if deps.GetNumSectionsFound('Report Variable Dictionary') > 0:
                        ObjectName = 'Output:VariableDictionary'
                        deps.WriteOutIDFLines(DifLfn, ObjectName, ['Regular'], {})
                    
                    try:
                        import os
                        FileExist = os.path.exists(FileNamePath + '.rvi')
                    except:
                        FileExist = False
                    
                    try:
                        with open(output_filename, 'w') as f:
                            pass
                    except:
                        pass
                    
                    deps.ProcessRviMviFiles(FileNamePath, 'rvi')
                    deps.ProcessRviMviFiles(FileNamePath, 'mvi')
                    deps.CloseOut()
                else:
                    deps.ProcessRviMviFiles(FileNamePath, 'rvi')
                    deps.ProcessRviMviFiles(FileNamePath, 'mvi')
            else:
                EndOfFile = True
            
            deps.CreateNewName('Reallocate', '')
        
        if not ExitBecauseBadFile:
            StillWorking = False
            break
        else:
            if not ArgFileBeingDone:
                EndOfFile = False
            else:
                EndOfFile = True
                StillWorking = False
    
    if ArgFileBeingDone and not LatestVersion and not ExitBecauseBadFile:
        ErrFlag = False
        deps.copyfile(FileNamePath + '.' + ArgIDFExtension, FileNamePath + '.' + ArgIDFExtension + 'old', ErrFlag)
        deps.copyfile(FileNamePath + '.' + ArgIDFExtension + 'new', FileNamePath + '.' + ArgIDFExtension, ErrFlag)
        
        try:
            import os
            FileExist = os.path.exists(FileNamePath + '.rvi')
        except:
            FileExist = False
        
        if FileExist:
            deps.copyfile(FileNamePath + '.rvi', FileNamePath + '.rviold', ErrFlag)
        
        try:
            import os
            FileExist = os.path.exists(FileNamePath + '.rvinew')
        except:
            FileExist = False
        
        if FileExist:
            deps.copyfile(FileNamePath + '.rvinew', FileNamePath + '.rvi', ErrFlag)
        
        try:
            import os
            FileExist = os.path.exists(FileNamePath + '.mvi')
        except:
            FileExist = False
        
        if FileExist:
            deps.copyfile(FileNamePath + '.mvi', FileNamePath + '.mviold', ErrFlag)
        
        try:
            import os
            FileExist = os.path.exists(FileNamePath + '.mvinew')
        except:
            FileExist = False
        
        if FileExist:
            deps.copyfile(FileNamePath + '.mvinew', FileNamePath + '.mvi', ErrFlag)

def _process_base_surfaces(deps, FenSurf, TotObjsWithShadeCtrl):
    base_types = [
        'BUILDINGSURFACE:DETAILED', 'WALL:DETAILED', 'ROOFCEILING:DETAILED', 'FLOOR:DETAILED',
        'WALL:EXTERIOR', 'WALL:ADIABATIC', 'WALL:UNDERGROUND', 'WALL:INTERZONE',
        'ROOF', 'CEILING:ADIABATIC', 'CEILING:INTERZONE',
        'FLOOR:GROUNDCONTACT', 'FLOOR:ADIABATIC', 'FLOOR:INTERZONE'
    ]
    
    for base_type in base_types:
        for baseSurfNum in range(deps.GetNumObjectsFound(base_type)):
            Alphas, NumAlphas, Numbers, NumNumbers, Status = deps.GetObjectItem(base_type, baseSurfNum)
            zone_field = 3 if base_type == 'BUILDINGSURFACE:DETAILED' else 2
            
            for surfNum in range(TotObjsWithShadeCtrl):
                if deps.SameString(FenSurf[surfNum].FenBaseSurfName, Alphas[0]):
                    FenSurf[surfNum].FenZoneName = Alphas[zone_field]

def _process_record(deps, Num, DifLfn, DiffOnly, LocalFileExtension, NoVersion, 
                   ScheduleTypeLimitsAnyNumber, checkrvi, FenSurf, TotObjsWithShadeCtrl,
                   ShadeControls, TotOldShadeControls, NumZones, DeleteThisRecord):
    pass
