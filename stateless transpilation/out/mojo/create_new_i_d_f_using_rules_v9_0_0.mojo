from dataclasses import dataclass
from collections import List

@value
struct FenestrationSurf:
    var FenSurfName: String = ''
    var FenBaseSurfName: String = ''
    var FenZoneName: String = ''
    var FenShadeControlName: String = ''

@value
struct ShadeControl:
    var OldShadeControlName: String = ''
    var NumZones: Int = 0
    var ShadeControlZoneName: List[String] = List[String]()
    var SequenceNum: List[Int] = List[Int]()

@value
struct FieldFlagAndValue:
    var wasSet: Bool = False
    var originalValue: String = ''

var _FirstTime: Bool = True

fn SetThisVersionVariables(deps) -> None:
    deps.VerString = 'Conversion 8.9 => 9.0'
    deps.VersionNum = 9.0
    deps.sVersionNum = '9.0'
    deps.IDDFileNameWithPath = deps.ProgramPath.rstrip() + 'V8-9-0-Energy+.idd'
    deps.NewIDDFileNameWithPath = deps.ProgramPath.rstrip() + 'V9-0-0-Energy+.idd'
    deps.RepVarFileNameWithPath = deps.ProgramPath.rstrip() + 'Report Variables 8-9-0 to 9-0-0.csv'

fn CreateNewIDFUsingRules(
    deps,
    inout EndOfFile: Bool,
    DiffOnly: Bool,
    InLfn: Int,
    AskForInput: Bool,
    InputFileName: String,
    ArgFile: Bool,
    ArgIDFExtension: String
) -> None:
    global _FirstTime
    
    if _FirstTime:
        _FirstTime = False
    
    var StillWorking: Bool = True
    var ArgFileBeingDone: Bool = False
    var LatestVersion: Bool = False
    var NoVersion: Bool = True
    var LocalFileExtension: String = ArgIDFExtension
    EndOfFile = False
    var IOS: Int = 0
    
    var FenSurf: List[FenestrationSurf] = List[FenestrationSurf]()
    var ShadeControls: List[ShadeControl] = List[ShadeControl]()
    var TotWinObjs: Int = 0
    var TotObjsWithShadeCtrl: Int = 0
    var TotBaseSurfObjs: Int = 0
    var TotOldShadeControls: Int = 0
    
    while StillWorking:
        var ExitBecauseBadFile: Bool = False
        
        while not EndOfFile:
            var FullFileName: String = ""
            
            if AskForInput:
                print('Enter input file name, with path')
                print('-->', terminator: ' ')
                FullFileName = input()
            else:
                if not ArgFile:
                    try:
                        FullFileName = deps.read_input_line(InLfn)
                        IOS = 0
                    except:
                        FullFileName = ""
                        IOS = 1
                elif not ArgFileBeingDone:
                    FullFileName = InputFileName
                    IOS = 0
                    ArgFileBeingDone = True
                else:
                    FullFileName = ""
                    IOS = 1
                
                if len(FullFileName) > 0 and FullFileName[0] == '!':
                    FullFileName = ""
                    continue
            
            var UnitsArg: String = ""
            if IOS != 0:
                FullFileName = ""
            FullFileName = FullFileName.lstrip()
            
            if len(FullFileName) > 0:
                deps.DisplayString('Processing IDF -- ' + FullFileName)
                deps.WriteAuditf(' Processing IDF -- ' + FullFileName)
                
                var DotPos: Int = FullFileName.rfind('.')
                var FileNamePath: String = ""
                
                if DotPos != -1:
                    FileNamePath = FullFileName[:DotPos]
                    LocalFileExtension = FullFileName[DotPos+1:].lower()
                else:
                    FileNamePath = FullFileName
                    print(' assuming file extension of .idf')
                    deps.WriteAuditf(' ..assuming file extension of .idf')
                    FullFileName = FullFileName.rstrip() + '.idf'
                    LocalFileExtension = 'idf'
                
                var DifLfn: Int = deps.GetNewUnitNumber()
                
                var FileOK: Bool = False
                try:
                    var f = open(FullFileName, 'r')
                    _ = f.read()
                    f.close()
                    FileOK = True
                except:
                    FileOK = False
                
                if not FileOK:
                    print('File not found=' + FullFileName)
                    deps.WriteAuditf('File not found=' + FullFileName)
                    EndOfFile = True
                    ExitBecauseBadFile = True
                    break
                
                if LocalFileExtension == 'idf' or LocalFileExtension == 'imf':
                    var checkrvi: Bool = False
                    var ConnComp: Bool = False
                    var ConnCompCtrl: Bool = False
                    
                    var output_filename: String = ""
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
                    
                    var DeleteThisRecord: List[Bool] = List[Bool]()
                    for _ in range(deps.NumIDFRecords):
                        DeleteThisRecord.append(False)
                    
                    NoVersion = True
                    for Num in range(deps.NumIDFRecords):
                        if deps.MakeUPPERCase(deps.IDFRecords[Num]['Name']) != 'VERSION':
                            continue
                        NoVersion = False
                        break
                    
                    var ScheduleTypeLimitsAnyNumber: Bool = False
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
                    FenSurf = List[FenestrationSurf]()
                    for _ in range(TotWinObjs):
                        FenSurf.append(FenestrationSurf())
                    
                    TotObjsWithShadeCtrl = 0
                    deps.DisplayString('Processing IDF -- WindowShadingControl preprocessing . . .')
                    
                    for surfNum in range(deps.GetNumObjectsFound('FENESTRATIONSURFACE:DETAILED')):
                        var Alphas: List[String]
                        var NumAlphas: Int
                        var Numbers: List[Float]
                        var NumNumbers: Int
                        var Status: Int
                        Alphas, NumAlphas, Numbers, NumNumbers, Status = deps.GetObjectItem('FENESTRATIONSURFACE:DETAILED', surfNum)
                        if len(Alphas) > 5 and Alphas[5] != '':
                            FenSurf[TotObjsWithShadeCtrl].FenSurfName = Alphas[0]
                            FenSurf[TotObjsWithShadeCtrl].FenBaseSurfName = Alphas[3]
                            FenSurf[TotObjsWithShadeCtrl].FenShadeControlName = Alphas[5]
                            TotObjsWithShadeCtrl += 1
                    
                    for surfNum in range(deps.GetNumObjectsFound('WINDOW')):
                        Alphas, NumAlphas, Numbers, NumNumbers, Status = deps.GetObjectItem('WINDOW', surfNum)
                        if len(Alphas) > 3 and Alphas[3] != '':
                            FenSurf[TotObjsWithShadeCtrl].FenSurfName = Alphas[0]
                            FenSurf[TotObjsWithShadeCtrl].FenBaseSurfName = Alphas[2]
                            FenSurf[TotObjsWithShadeCtrl].FenShadeControlName = Alphas[3]
                            TotObjsWithShadeCtrl += 1
                    
                    for surfNum in range(deps.GetNumObjectsFound('GLAZEDDOOR')):
                        Alphas, NumAlphas, Numbers, NumNumbers, Status = deps.GetObjectItem('GLAZEDDOOR', surfNum)
                        if len(Alphas) > 3 and Alphas[3] != '':
                            FenSurf[TotObjsWithShadeCtrl].FenSurfName = Alphas[0]
                            FenSurf[TotObjsWithShadeCtrl].FenBaseSurfName = Alphas[2]
                            FenSurf[TotObjsWithShadeCtrl].FenShadeControlName = Alphas[3]
                            TotObjsWithShadeCtrl += 1
                    
                    _process_base_surfaces(deps, FenSurf, TotObjsWithShadeCtrl)
                    
                    TotOldShadeControls = deps.GetNumObjectsFound('WINDOWPROPERTY:SHADINGCONTROL')
                    var NumZones: Int = deps.GetNumObjectsFound('ZONE')
                    ShadeControls = List[ShadeControl]()
                    
                    for shadeCtrlNum in range(TotOldShadeControls):
                        var sc: ShadeControl = ShadeControl()
                        sc.ShadeControlZoneName = List[String]()
                        sc.SequenceNum = List[Int]()
                        for _ in range(NumZones):
                            sc.ShadeControlZoneName.append('')
                            sc.SequenceNum.append(0)
                        
                        var Alphas: List[String]
                        var NumAlphas: Int
                        var Numbers: List[Float]
                        var NumNumbers: Int
                        var Status: Int
                        Alphas, NumAlphas, Numbers, NumNumbers, Status = deps.GetObjectItem('WINDOWPROPERTY:SHADINGCONTROL', shadeCtrlNum)
                        sc.OldShadeControlName = Alphas[0]
                        sc.NumZones = 0
                        
                        for surfNum in range(TotObjsWithShadeCtrl):
                            var zoneFound: Bool = False
                            if not deps.SameString(FenSurf[surfNum].FenShadeControlName, sc.OldShadeControlName):
                                continue
                            
                            for newZoneNum in range(sc.NumZones):
                                if not deps.SameString(FenSurf[surfNum].FenZoneName, sc.ShadeControlZoneName[newZoneNum]):
                                    continue
                                zoneFound = True
                                break
                            
                            if zoneFound:
                                continue
                            
                            sc.ShadeControlZoneName[sc.NumZones] = FenSurf[surfNum].FenZoneName
                            sc.NumZones += 1
                        
                        ShadeControls.append(sc)
                    
                    for zoneNum in range(NumZones):
                        var seqCount: Int = 0
                        var Alphas: List[String]
                        var NumAlphas: Int
                        var Numbers: List[Float]
                        var NumNumbers: Int
                        var Status: Int
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
                        var ObjectName: String = 'Output:VariableDictionary'
                        deps.WriteOutIDFLines(DifLfn, ObjectName, ['Regular'], {})
                    
                    var FileExist: Bool = False
                    try:
                        var f = open(FileNamePath + '.rvi', 'r')
                        f.close()
                        FileExist = True
                    except:
                        FileExist = False
                    
                    try:
                        var f = open(output_filename, 'w')
                        f.close()
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
        var ErrFlag: Bool = False
        deps.copyfile(FileNamePath + '.' + ArgIDFExtension, FileNamePath + '.' + ArgIDFExtension + 'old', ErrFlag)
        deps.copyfile(FileNamePath + '.' + ArgIDFExtension + 'new', FileNamePath + '.' + ArgIDFExtension, ErrFlag)
        
        var FileExist: Bool = False
        try:
            var f = open(FileNamePath + '.rvi', 'r')
            f.close()
            FileExist = True
        except:
            FileExist = False
        
        if FileExist:
            deps.copyfile(FileNamePath + '.rvi', FileNamePath + '.rviold', ErrFlag)
        
        FileExist = False
        try:
            var f = open(FileNamePath + '.rvinew', 'r')
            f.close()
            FileExist = True
        except:
            FileExist = False
        
        if FileExist:
            deps.copyfile(FileNamePath + '.rvinew', FileNamePath + '.rvi', ErrFlag)
        
        FileExist = False
        try:
            var f = open(FileNamePath + '.mvi', 'r')
            f.close()
            FileExist = True
        except:
            FileExist = False
        
        if FileExist:
            deps.copyfile(FileNamePath + '.mvi', FileNamePath + '.mviold', ErrFlag)
        
        FileExist = False
        try:
            var f = open(FileNamePath + '.mvinew', 'r')
            f.close()
            FileExist = True
        except:
            FileExist = False
        
        if FileExist:
            deps.copyfile(FileNamePath + '.mvinew', FileNamePath + '.mvi', ErrFlag)

fn _process_base_surfaces(deps, inout FenSurf: List[FenestrationSurf], TotObjsWithShadeCtrl: Int) -> None:
    var base_types: List[String] = List[String]()
    base_types.append('BUILDINGSURFACE:DETAILED')
    base_types.append('WALL:DETAILED')
    base_types.append('ROOFCEILING:DETAILED')
    base_types.append('FLOOR:DETAILED')
    base_types.append('WALL:EXTERIOR')
    base_types.append('WALL:ADIABATIC')
    base_types.append('WALL:UNDERGROUND')
    base_types.append('WALL:INTERZONE')
    base_types.append('ROOF')
    base_types.append('CEILING:ADIABATIC')
    base_types.append('CEILING:INTERZONE')
    base_types.append('FLOOR:GROUNDCONTACT')
    base_types.append('FLOOR:ADIABATIC')
    base_types.append('FLOOR:INTERZONE')
    
    for base_type in base_types:
        for baseSurfNum in range(deps.GetNumObjectsFound(base_type)):
            var Alphas: List[String]
            var NumAlphas: Int
            var Numbers: List[Float]
            var NumNumbers: Int
            var Status: Int
            Alphas, NumAlphas, Numbers, NumNumbers, Status = deps.GetObjectItem(base_type, baseSurfNum)
            var zone_field: Int = 3 if base_type == 'BUILDINGSURFACE:DETAILED' else 2
            
            for surfNum in range(TotObjsWithShadeCtrl):
                if deps.SameString(FenSurf[surfNum].FenBaseSurfName, Alphas[0]):
                    FenSurf[surfNum].FenZoneName = Alphas[zone_field]

fn _process_record(
    deps,
    Num: Int,
    DifLfn: Int,
    DiffOnly: Bool,
    LocalFileExtension: String,
    NoVersion: Bool,
    ScheduleTypeLimitsAnyNumber: Bool,
    checkrvi: Bool,
    FenSurf: List[FenestrationSurf],
    TotObjsWithShadeCtrl: Int,
    ShadeControls: List[ShadeControl],
    TotOldShadeControls: Int,
    NumZones: Int,
    DeleteThisRecord: List[Bool]
) -> None:
    pass
