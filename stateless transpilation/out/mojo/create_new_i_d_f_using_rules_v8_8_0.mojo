# EXTERNAL DEPS (to wire in glue):
# Source: DataStringGlobals, DataVCompareGlobals, InputProcessor, VCompareGlobalRoutines, General, DataGlobals
# Requires state struct implementing entire module variable interface (see Python port for schema)

struct SetVersionState:
    var VerString: String
    var VersionNum: Float64
    var sVersionNum: String
    var IDDFileNameWithPath: String
    var NewIDDFileNameWithPath: String
    var RepVarFileNameWithPath: String

fn SetThisVersionVariables(inout state: SetVersionState, ProgramPath: String):
    """Set version variables for conversion 8.7 => 8.8"""
    state.VerString = String('Conversion 8.7 => 8.8')
    state.VersionNum = 8.8
    state.sVersionNum = String('8.8')
    let program_path_trimmed = ProgramPath.rstrip()
    state.IDDFileNameWithPath = program_path_trimmed + 'V8-7-0-Energy+.idd'
    state.NewIDDFileNameWithPath = program_path_trimmed + 'V8-8-0-Energy+.idd'
    state.RepVarFileNameWithPath = program_path_trimmed + 'Report Variables 8-7-0 to 8-8-0.csv'

fn CreateNewIDFUsingRules(
    inout EndOfFile: Bool,
    DiffOnly: Bool,
    InLfn: Int,
    AskForInput: Bool,
    InputFileName: String,
    ArgFile: Bool,
    ArgIDFExtension: String,
    inout state: CreateNewIDFUsingRulesState
) -> Bool:
    """
    Create new IDF files based on transition rules.
    
    Args:
        EndOfFile: (INOUT) end of file flag
        DiffOnly: (IN) diff only flag
        InLfn: (IN) input logical file number
        AskForInput: (IN) ask for input flag
        InputFileName: (IN) input file name
        ArgFile: (IN) argument file flag
        ArgIDFExtension: (IN) argument IDF extension
        state: shared state struct containing all module variables
    """
    
    var FirstTime: Bool = True
    
    while True:
        var StillWorking: Bool = True
        var ArgFileBeingDone: Bool = False
        var LatestVersion: Bool = False
        var NoVersion: Bool = True
        var LocalFileExtension: String = ArgIDFExtension
        EndOfFile = False
        var IOS: Int = 0
        
        while StillWorking:
            var ExitBecauseBadFile: Bool = False
            
            while not EndOfFile:
                if AskForInput:
                    print("Enter input file name, with path")
                    state.FullFileName = input()
                else:
                    if not ArgFile:
                        try:
                            state.FullFileName = state.read_input_line(InLfn)
                            IOS = 0
                        except:
                            state.FullFileName = state.blank
                            IOS = 1
                    elif not ArgFileBeingDone:
                        state.FullFileName = InputFileName
                        IOS = 0
                        ArgFileBeingDone = True
                    else:
                        state.FullFileName = state.blank
                        IOS = 1
                
                if state.FullFileName.count() > 0 and state.FullFileName[0] == '!':
                    state.FullFileName = state.blank
                    continue
                
                if IOS != 0:
                    state.FullFileName = state.blank
                
                state.FullFileName = state.FullFileName.lstrip()
                
                if state.FullFileName != state.blank:
                    state.DisplayString('Processing IDF -- ' + state.FullFileName)
                    state.write_audit('Processing IDF -- ' + state.FullFileName)
                    
                    var DotPos: Int = state.FullFileName.rfind('.')
                    if DotPos != -1:
                        state.FileNamePath = state.FullFileName[:DotPos]
                        LocalFileExtension = state.MakeLowerCase(state.FullFileName[DotPos+1:])
                    else:
                        state.FileNamePath = state.FullFileName
                        print(' assuming file extension of .idf')
                        state.write_audit(' ..assuming file extension of .idf')
                        state.FullFileName = state.FullFileName.rstrip() + '.idf'
                        LocalFileExtension = 'idf'
                    
                    var DifLfn: Int = state.GetNewUnitNumber()
                    
                    var FileOK: Bool = False
                    try:
                        _ = open(state.FullFileName, 'r')
                        FileOK = True
                    except:
                        FileOK = False
                    
                    if not FileOK:
                        print('File not found=' + state.FullFileName)
                        state.write_audit('File not found=' + state.FullFileName)
                        EndOfFile = True
                        ExitBecauseBadFile = True
                        break
                    
                    if LocalFileExtension == 'idf' or LocalFileExtension == 'imf':
                        var checkrvi: Bool = False
                        var ConnComp: Bool = False
                        var ConnCompCtrl: Bool = False
                        
                        var out_filename: String
                        if DiffOnly:
                            out_filename = state.FileNamePath + '.' + LocalFileExtension + 'dif'
                        else:
                            out_filename = state.FileNamePath + '.' + LocalFileExtension + 'new'
                        
                        var DifLfn_file = open(out_filename, 'w')
                        
                        if LocalFileExtension == 'imf':
                            state.ShowWarningError('Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.', state.Auditf)
                            state.ProcessingIMFFile = True
                        else:
                            state.ProcessingIMFFile = False
                        
                        state.ProcessInput(state.IDDFileNameWithPath, state.NewIDDFileNameWithPath, state.FullFileName)
                        
                        if state.FatalError:
                            ExitBecauseBadFile = True
                            break
                        
                        state.allocate_arrays()
                        
                        NoVersion = True
                        for Num in range(state.NumIDFRecords):
                            if state.MakeUPPERCase(state.IDFRecords[Num]['Name']) != 'VERSION':
                                continue
                            NoVersion = False
                            break
                        
                        var ScheduleTypeLimitsAnyNumber: Bool = False
                        for Num in range(state.NumIDFRecords):
                            if not state.SameString(state.IDFRecords[Num]['Name'], 'ScheduleTypeLimits'):
                                continue
                            if not state.SameString(state.IDFRecords[Num]['Alphas'][0], 'Any Number'):
                                continue
                            ScheduleTypeLimitsAnyNumber = True
                            break
                        
                        for Num in range(state.NumIDFRecords):
                            if state.DeleteThisRecord[Num]:
                                DifLfn_file.write('! Deleting: ' + state.IDFRecords[Num]['Name'].strip() + '="' + state.IDFRecords[Num]['Alphas'][0].strip() + '".\n')
                        
                        for Num in range(state.NumIDFRecords):
                            if state.DeleteThisRecord[Num]:
                                continue
                            
                            for xcount in range(state.IDFRecords[Num]['CommtS'], state.IDFRecords[Num]['CommtE']+1):
                                DifLfn_file.write(state.Comments[xcount] + '\n')
                                if xcount == state.IDFRecords[Num]['CommtE']:
                                    DifLfn_file.write('\n')
                            
                            if NoVersion and Num == 0:
                                var NwNumArgs: Int
                                var NwAorN: List[Bool]
                                var NwReqFld: List[Bool]
                                var NwObjMinFlds: Int
                                var NwFldNames: List[String]
                                var NwFldDefaults: List[String]
                                var NwFldUnits: List[String]
                                NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                    state.GetNewObjectDefInIDD('VERSION')
                                state.OutArgs[0] = state.sVersionNum
                                var CurArgs: Int = 1
                                state.WriteOutIDFLinesAsComments(DifLfn_file, 'Version', CurArgs, state.OutArgs, NwFldNames, NwFldUnits)
                            
                            var ObjectName: String = state.IDFRecords[Num]['Name']
                            
                            var obj_upper = state.MakeUPPERCase(state.IDFRecords[Num]['Name']).strip()
                            if obj_upper in ['PROGRAMCONTROL', 'SKY RADIANCE DISTRIBUTION', 
                                            'AIRFLOW MODEL', 'GENERATOR:FC:BATTERY DATA',
                                            'AIRFLOWNETWORK:MULTIZONE:SITEWINDCONDITIONS']:
                                continue
                            
                            if obj_upper == 'WATER HEATER:SIMPLE':
                                DifLfn_file.write('! ** The WATER HEATER:SIMPLE object has been deleted\n')
                                state.writePreprocessorObject(DifLfn_file, state.ProgNameConversion, 'Warning', 
                                                            'The WATER HEATER:SIMPLE object has been deleted')
                                continue
                            
                            if state.FindItemInList(ObjectName, state.ObjectDef, state.NumObjectDefs) != -1:
                                var NumArgs: Int
                                var AorN: List[Bool]
                                var ReqFld: List[Bool]
                                var ObjMinFlds: Int
                                var FldNames: List[String]
                                var FldDefaults: List[String]
                                var FldUnits: List[String]
                                NumArgs, AorN, ReqFld, ObjMinFlds, FldNames, FldDefaults, FldUnits = \
                                    state.GetObjectDefInIDD(ObjectName)
                                var NumAlphas: Int = state.IDFRecords[Num]['NumAlphas']
                                var NumNumbers: Int = state.IDFRecords[Num]['NumNumbers']
                                
                                for i in range(NumAlphas):
                                    state.Alphas[i] = state.IDFRecords[Num]['Alphas'][i]
                                for i in range(NumNumbers):
                                    state.Numbers[i] = state.IDFRecords[Num]['Numbers'][i]
                                
                                CurArgs = NumAlphas + NumNumbers
                                for i in range(len(state.InArgs)):
                                    state.InArgs[i] = state.blank
                                for i in range(len(state.OutArgs)):
                                    state.OutArgs[i] = state.blank
                                
                                var NA: Int = 0
                                var NN: Int = 0
                                for Arg in range(CurArgs):
                                    if AorN[Arg]:
                                        state.InArgs[Arg] = state.Alphas[NA]
                                        NA += 1
                                    else:
                                        state.InArgs[Arg] = state.Numbers[NN]
                                        NN += 1
                            else:
                                state.write_audit('Object="' + ObjectName.strip() + '" does not seem to be on the "old" IDD.')
                                state.write_audit('... will be listed as comments (no field names) on the new output file.')
                                state.write_audit('... Alpha fields will be listed first, then numerics.')
                                
                                NumAlphas = state.IDFRecords[Num]['NumAlphas']
                                NumNumbers = state.IDFRecords[Num]['NumNumbers']
                                
                                for i in range(NumAlphas):
                                    state.Alphas[i] = state.IDFRecords[Num]['Alphas'][i]
                                for i in range(NumNumbers):
                                    state.Numbers[i] = state.IDFRecords[Num]['Numbers'][i]
                                
                                for Arg in range(NumAlphas):
                                    state.OutArgs[Arg] = state.Alphas[Arg]
                                
                                NN = NumAlphas
                                for Arg in range(NumNumbers):
                                    state.OutArgs[NN] = state.Numbers[Arg]
                                    NN += 1
                                
                                CurArgs = NumAlphas + NumNumbers
                                for i in range(len(state.NwFldNames)):
                                    state.NwFldNames[i] = state.blank
                                for i in range(len(state.NwFldUnits)):
                                    state.NwFldUnits[i] = state.blank
                                
                                state.WriteOutIDFLinesAsComments(DifLfn_file, ObjectName, CurArgs, state.OutArgs, state.NwFldNames, state.NwFldUnits)
                                continue
                            
                            var NoDiff: Bool = True
                            var DiffMinFields: Bool = False
                            var Written: Bool = False
                            
                            if state.FindItemInList(state.MakeUPPERCase(ObjectName), state.NotInNew, len(state.NotInNew)) == -1:
                                NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                    state.GetNewObjectDefInIDD(ObjectName)
                                
                                if ObjMinFlds != NwObjMinFlds:
                                    DiffMinFields = True
                                else:
                                    DiffMinFields = False
                            
                            if not state.MakingPretty:
                                obj_upper = state.MakeUPPERCase(state.IDFRecords[Num]['Name']).strip()
                                
                                if obj_upper == 'VERSION':
                                    if state.InArgs[0][:3] == state.sVersionNum and ArgFile:
                                        state.ShowWarningError('File is already at latest version.  No new diff file made.', state.Auditf)
                                        DifLfn_file.close()
                                        try:
                                            import os
                                            os.remove(out_filename)
                                        except:
                                            pass
                                        LatestVersion = True
                                        break
                                    
                                    NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                        state.GetNewObjectDefInIDD(ObjectName)
                                    state.OutArgs[0] = state.sVersionNum
                                    NoDiff = False
                                
                                elif obj_upper == 'OUTPUT:SURFACES:LIST':
                                    ObjectName = 'Output:Surfaces:List'
                                    NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                        state.GetNewObjectDefInIDD(ObjectName)
                                    NoDiff = False
                                    for i in range(CurArgs):
                                        state.OutArgs[i] = state.InArgs[i]
                                    if state.SameString(state.InArgs[0], 'DecayCurvesfromZoneComponentLoads'):
                                        state.OutArgs[0] = 'DecayCurvesFromComponentLoadsSummary'
                                
                                elif obj_upper == 'TABLE:TWOINDEPENDENTVARIABLES':
                                    ObjectName = 'Table:TwoIndependentVariables'
                                    NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                        state.GetNewObjectDefInIDD(ObjectName)
                                    NoDiff = False
                                    for i in range(13):
                                        state.OutArgs[i] = state.InArgs[i]
                                    state.OutArgs[13] = ''
                                    for i in range(CurArgs - 13):
                                        state.OutArgs[14 + i] = state.InArgs[13 + i]
                                    CurArgs = CurArgs + 1
                                
                                elif obj_upper == 'BUILDINGSURFACE:DETAILED':
                                    NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                        state.GetNewObjectDefInIDD(ObjectName)
                                    NoDiff = False
                                    if state.SameString(state.InArgs[4], 'Foundation') and state.SameString(state.InArgs[1], 'Floor'):
                                        var NumPerimObjs: Int = state.GetNumObjectsFound('SURFACEPROPERTY:EXPOSEDFOUNDATIONPERIMETER')
                                        var PerimNum: Int = 0
                                        for xcount in range(NumPerimObjs):
                                            var Alphas: List[String]
                                            var NumAlphas_temp: Int
                                            var Numbers: List[Float64]
                                            var NumNumbers_temp: Int
                                            var Status: Int
                                            Alphas, NumAlphas_temp, Numbers, NumNumbers_temp, Status = \
                                                state.GetObjectItem('SURFACEPROPERTY:EXPOSEDFOUNDATIONPERIMETER', xcount)
                                            if state.SameString(Alphas[0].strip(), state.InArgs[0].strip()):
                                                PerimNum = xcount
                                                break
                                        
                                        if PerimNum == 0:
                                            var PArgs: Int = (CurArgs - 10) // 3 + 4
                                            var PNumArgs: Int
                                            var PAorN: List[Bool]
                                            var NwReqFld_temp: List[Bool]
                                            var PObjMinFlds: Int
                                            var PFldNames: List[String]
                                            var PFldDefaults: List[String]
                                            var PFldUnits: List[String]
                                            PNumArgs, PAorN, NwReqFld_temp, PObjMinFlds, PFldNames, PFldDefaults, PFldUnits = \
                                                state.GetNewObjectDefInIDD('SURFACEPROPERTY:EXPOSEDFOUNDATIONPERIMETER')
                                            var POutArgs: List[String] = List[String](capacity=PArgs + 1)
                                            for i in range(PArgs + 1):
                                                POutArgs.append(state.blank)
                                            POutArgs[0] = state.InArgs[0]
                                            POutArgs[1] = 'BySegment'
                                            POutArgs[2] = ''
                                            POutArgs[3] = ''
                                            for xcount in range((CurArgs - 10) // 3):
                                                POutArgs[4 + xcount] = 'Yes'
                                            
                                            state.WriteOutIDFLines(DifLfn_file, 'SurfaceProperty:ExposedFoundationPerimeter', PArgs, POutArgs, PFldNames, PFldUnits)
                                            state.ShowWarningError('Foundation floors now require a SurfaceProperty:ExposedFoundationPerimeter object. One was added with each segment of the floor surface exposed. Please check your inputs to make sure this reflects your foundation.')
                                    
                                    for i in range(CurArgs):
                                        state.OutArgs[i] = state.InArgs[i]
                                
                                elif obj_upper == 'FLOOR:DETAILED':
                                    NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                        state.GetNewObjectDefInIDD(ObjectName)
                                    NoDiff = False
                                    if state.SameString(state.InArgs[3], 'Foundation'):
                                        PerimNum = state.GetObjectItemNum('SURFACEPROPERTY:EXPOSEDFOUNDATIONPERIMETER', state.InArgs[0])
                                        if PerimNum == 0:
                                            PArgs = (CurArgs - 9) // 3 + 4
                                            PNumArgs, PAorN, NwReqFld_temp, PObjMinFlds, PFldNames, PFldDefaults, PFldUnits = \
                                                state.GetNewObjectDefInIDD('SURFACEPROPERTY:EXPOSEDFOUNDATIONPERIMETER')
                                            POutArgs = List[String](capacity=PArgs + 1)
                                            for i in range(PArgs + 1):
                                                POutArgs.append(state.blank)
                                            POutArgs[0] = state.InArgs[0]
                                            POutArgs[1] = 'BySegment'
                                            POutArgs[2] = ''
                                            POutArgs[3] = ''
                                            for xcount in range((CurArgs - 9) // 3):
                                                POutArgs[4 + xcount] = 'Yes'
                                            
                                            state.WriteOutIDFLines(DifLfn_file, 'SurfaceProperty:ExposedFoundationPerimeter', PArgs, POutArgs, PFldNames, PFldUnits)
                                            state.ShowWarningError('Foundation floors now require a SurfaceProperty:ExposedFoundationPerimeter object. One was added with each segment of the floor surface exposed. Please check your inputs to make sure this reflects your foundation.')
                                    
                                    for i in range(CurArgs):
                                        state.OutArgs[i] = state.InArgs[i]
                                
                                elif obj_upper == 'SURFACEPROPERTY:EXPOSEDFOUNDATIONPERIMETER':
                                    NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                        state.GetNewObjectDefInIDD(ObjectName)
                                    NoDiff = False
                                    state.OutArgs[0] = state.InArgs[0]
                                    state.OutArgs[1] = 'BySegment'
                                    for i in range(CurArgs):
                                        state.OutArgs[2 + i] = state.InArgs[1 + i]
                                    CurArgs = CurArgs + 1
                                
                                elif obj_upper == 'FOUNDATION:KIVA:SETTINGS':
                                    NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                        state.GetNewObjectDefInIDD(ObjectName)
                                    NoDiff = False
                                    for i in range(CurArgs):
                                        state.OutArgs[i] = state.InArgs[i]
                                    if state.SameString(state.InArgs[7], 'Autocalculate'):
                                        state.OutArgs[7] = 'Autoselect'
                                
                                elif obj_upper == 'UNITARYSYSTEMPERFORMANCE:MULTISPEED':
                                    NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                        state.GetNewObjectDefInIDD(ObjectName)
                                    NoDiff = False
                                    for i in range(4):
                                        state.OutArgs[i] = state.InArgs[i]
                                    state.OutArgs[4] = ''
                                    for i in range(CurArgs - 4):
                                        state.OutArgs[5 + i] = state.InArgs[4 + i]
                                    CurArgs = CurArgs + 1
                                
                                elif obj_upper == 'COIL:COOLING:DX:SINGLESPEED':
                                    NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                        state.GetNewObjectDefInIDD(ObjectName)
                                    NoDiff = False
                                    for i in range(14):
                                        state.OutArgs[i] = state.InArgs[i]
                                    state.OutArgs[14] = ''
                                    for i in range(CurArgs - 14):
                                        state.OutArgs[15 + i] = state.InArgs[14 + i]
                                    CurArgs = CurArgs + 1
                                
                                elif obj_upper == 'COIL:COOLING:DX:TWOSPEED':
                                    NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                        state.GetNewObjectDefInIDD(ObjectName)
                                    NoDiff = False
                                    for i in range(22):
                                        state.OutArgs[i] = state.InArgs[i]
                                    state.OutArgs[22] = ''
                                    for i in range(CurArgs - 22):
                                        state.OutArgs[23 + i] = state.InArgs[22 + i]
                                    CurArgs = CurArgs + 1
                                
                                elif obj_upper == 'COIL:COOLING:DX:MULTISPEED':
                                    NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                        state.GetNewObjectDefInIDD(ObjectName)
                                    NoDiff = False
                                    for i in range(6):
                                        state.OutArgs[i] = state.InArgs[i]
                                    state.OutArgs[6] = ''
                                    for i in range(CurArgs - 6):
                                        state.OutArgs[7 + i] = state.InArgs[6 + i]
                                    CurArgs = CurArgs + 1
                                
                                elif obj_upper == 'COIL:COOLING:DX:VARIABLESPEED':
                                    NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                        state.GetNewObjectDefInIDD(ObjectName)
                                    NoDiff = False
                                    for i in range(15):
                                        state.OutArgs[i] = state.InArgs[i]
                                    state.OutArgs[15] = ''
                                    for i in range(CurArgs - 15):
                                        state.OutArgs[16 + i] = state.InArgs[15 + i]
                                    CurArgs = CurArgs + 1
                                
                                elif obj_upper == 'COIL:COOLING:DX:TWOSTAGEWITHHUMIDITYCONTROLMODE':
                                    NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                        state.GetNewObjectDefInIDD(ObjectName)
                                    NoDiff = False
                                    for i in range(18):
                                        state.OutArgs[i] = state.InArgs[i]
                                    state.OutArgs[18] = ''
                                    for i in range(CurArgs - 18):
                                        state.OutArgs[19 + i] = state.InArgs[18 + i]
                                    CurArgs = CurArgs + 1
                                
                                elif obj_upper == 'ZONEHVAC:PACKAGEDTERMINALHEATPUMP':
                                    NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                        state.GetNewObjectDefInIDD(ObjectName)
                                    NoDiff = False
                                    for i in range(17):
                                        state.OutArgs[i] = state.InArgs[i]
                                    for i in range(CurArgs - 19):
                                        state.OutArgs[17 + i] = state.InArgs[18 + i]
                                    CurArgs = CurArgs - 1
                                
                                elif obj_upper == 'ZONEHVAC:IDEALLOADSAIRSYSTEM':
                                    NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                        state.GetNewObjectDefInIDD(ObjectName)
                                    NoDiff = False
                                    for i in range(4):
                                        state.OutArgs[i] = state.InArgs[i]
                                    state.OutArgs[4] = ''
                                    for i in range(CurArgs - 4):
                                        state.OutArgs[5 + i] = state.InArgs[4 + i]
                                    CurArgs = CurArgs + 1
                                
                                elif obj_upper == 'ZONECONTROL:CONTAMINANTCONTROLLER':
                                    NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                        state.GetNewObjectDefInIDD(ObjectName)
                                    if CurArgs > 4:
                                        NoDiff = False
                                        for i in range(5):
                                            state.OutArgs[i] = state.InArgs[i]
                                        state.OutArgs[5] = ''
                                        for i in range(CurArgs - 5):
                                            state.OutArgs[6 + i] = state.InArgs[5 + i]
                                        CurArgs = CurArgs + 1
                                    else:
                                        NoDiff = True
                                        for i in range(CurArgs):
                                            state.OutArgs[i] = state.InArgs[i]
                                
                                elif obj_upper == 'AVAILABILITYMANAGER:NIGHTCYCLE':
                                    NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                        state.GetNewObjectDefInIDD(ObjectName)
                                    NoDiff = False
                                    for i in range(5):
                                        state.OutArgs[i] = state.InArgs[i]
                                    state.OutArgs[5] = 'FixedRunTime'
                                    for i in range(CurArgs - 5):
                                        state.OutArgs[6 + i] = state.InArgs[5 + i]
                                    CurArgs = CurArgs + 1
                                
                                elif obj_upper == 'OUTPUT:VARIABLE':
                                    NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                        state.GetNewObjectDefInIDD(ObjectName)
                                    for i in range(CurArgs):
                                        state.OutArgs[i] = state.InArgs[i]
                                    NoDiff = True
                                    if state.OutArgs[0] == state.blank:
                                        state.OutArgs[0] = '*'
                                        NoDiff = False
                                    
                                    var DelThis: Bool = False
                                    DelThis, checkrvi, NoDiff, Written = state.ScanOutputVariablesForReplacement(
                                        2, DelThis, checkrvi, NoDiff, ObjectName, DifLfn_file, True, False, False, CurArgs, Written, False)
                                    if DelThis:
                                        continue
                                
                                elif obj_upper in ['OUTPUT:METER', 'OUTPUT:METER:METERFILEONLY', 'OUTPUT:METER:CUMULATIVE', 'OUTPUT:METER:CUMULATIVE:METERFILEONLY']:
                                    NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                        state.GetNewObjectDefInIDD(ObjectName)
                                    for i in range(CurArgs):
                                        state.OutArgs[i] = state.InArgs[i]
                                    NoDiff = True
                                    DelThis = False
                                    DelThis, checkrvi, NoDiff, Written = state.ScanOutputVariablesForReplacement(
                                        1, DelThis, checkrvi, NoDiff, ObjectName, DifLfn_file, False, True, False, CurArgs, Written, False)
                                    if DelThis:
                                        continue
                                
                                elif obj_upper == 'OUTPUT:TABLE:TIMEBINS':
                                    NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                        state.GetNewObjectDefInIDD(ObjectName)
                                    for i in range(CurArgs):
                                        state.OutArgs[i] = state.InArgs[i]
                                    NoDiff = True
                                    if state.OutArgs[0] == state.blank:
                                        state.OutArgs[0] = '*'
                                        NoDiff = False
                                    DelThis = False
                                    DelThis, checkrvi, NoDiff, Written = state.ScanOutputVariablesForReplacement(
                                        2, DelThis, checkrvi, NoDiff, ObjectName, DifLfn_file, False, False, True, CurArgs, Written, False)
                                    if DelThis:
                                        continue
                                
                                elif obj_upper in ['EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITIMPORT:FROM:VARIABLE', 'EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITEXPORT:FROM:VARIABLE']:
                                    NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                        state.GetNewObjectDefInIDD(ObjectName)
                                    for i in range(CurArgs):
                                        state.OutArgs[i] = state.InArgs[i]
                                    NoDiff = True
                                    if state.OutArgs[0] == state.blank:
                                        state.OutArgs[0] = '*'
                                        NoDiff = False
                                    DelThis = False
                                    DelThis, checkrvi, NoDiff, Written = state.ScanOutputVariablesForReplacement(
                                        2, DelThis, checkrvi, NoDiff, ObjectName, DifLfn_file, False, False, False, CurArgs, Written, False)
                                    if DelThis:
                                        continue
                                
                                elif obj_upper == 'ENERGYMANAGEMENTSYSTEM:SENSOR':
                                    NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                        state.GetNewObjectDefInIDD(ObjectName)
                                    for i in range(CurArgs):
                                        state.OutArgs[i] = state.InArgs[i]
                                    NoDiff = True
                                    DelThis = False
                                    DelThis, checkrvi, NoDiff, Written = state.ScanOutputVariablesForReplacement(
                                        3, DelThis, checkrvi, NoDiff, ObjectName, DifLfn_file, False, False, False, CurArgs, Written, True)
                                    if DelThis:
                                        continue
                                
                                elif obj_upper == 'OUTPUT:TABLE:MONTHLY':
                                    NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                        state.GetNewObjectDefInIDD(ObjectName)
                                    NoDiff = True
                                    for i in range(CurArgs):
                                        state.OutArgs[i] = state.InArgs[i]
                                    
                                    var CurVar: Int = 3
                                    Var = 3
                                    while Var < CurArgs:
                                        var UCRepVarName: String = state.MakeUPPERCase(state.InArgs[Var])
                                        state.OutArgs[CurVar] = state.InArgs[Var]
                                        state.OutArgs[CurVar+1] = state.InArgs[Var+1]
                                        
                                        var pos: Int = UCRepVarName.find('[')
                                        if pos > 0:
                                            UCRepVarName = UCRepVarName[:pos]
                                            state.OutArgs[CurVar] = state.InArgs[Var][:pos]
                                            state.OutArgs[CurVar+1] = state.InArgs[Var+1]
                                        
                                        DelThis = False
                                        for Arg in range(state.NumRepVarNames):
                                            var UCCompRepVarName: String = state.MakeUPPERCase(state.OldRepVarName[Arg])
                                            var WildMatch: Bool = False
                                            if UCCompRepVarName[-1:] == '*':
                                                WildMatch = True
                                                UCCompRepVarName = UCCompRepVarName[:-1] + ' '
                                                pos = state.InArgs[Var].upper().find(UCCompRepVarName.strip())
                                            else:
                                                WildMatch = False
                                                pos = 0
                                                if UCRepVarName == UCCompRepVarName:
                                                    pos = 1
                                            
                                            if pos > 0 and pos != 1:
                                                Var += 2
                                                continue
                                            
                                            if pos > 0:
                                                if state.NewRepVarName[Arg] != '<DELETE>':
                                                    if not WildMatch:
                                                        state.OutArgs[CurVar] = state.NewRepVarName[Arg]
                                                    else:
                                                        state.OutArgs[CurVar] = state.NewRepVarName[Arg].rstrip() + state.OutArgs[CurVar][len(UCCompRepVarName.rstrip()):]
                                                    
                                                    if state.NewRepVarCaution[Arg] != state.blank and not state.SameString(state.NewRepVarCaution[Arg][:6], 'Forkeq'):
                                                        if not state.OTMVarCaution[Arg]:
                                                            state.writePreprocessorObject(DifLfn_file, state.ProgNameConversion, 'Warning',
                                                                'Output Table Monthly (old)="' + state.OldRepVarName[Arg].rstrip() + 
                                                                '" conversion to Output Table Monthly (new)="' + 
                                                                state.NewRepVarName[Arg].rstrip() + 
                                                                '" has the following caution "' + state.NewRepVarCaution[Arg].rstrip() + '".')
                                                            DifLfn_file.write('\n')
                                                            state.OTMVarCaution[Arg] = True
                                                    
                                                    state.OutArgs[CurVar+1] = state.InArgs[Var+1]
                                                    NoDiff = False
                                                else:
                                                    DelThis = True
                                                
                                                break
                                        
                                        if not DelThis:
                                            CurVar += 2
                                        
                                        Var += 2
                                    
                                    CurArgs = CurVar - 1
                                
                                else:
                                    if state.FindItemInList(ObjectName, state.NotInNew, len(state.NotInNew)) != -1:
                                        state.write_audit('Object="' + ObjectName.rstrip() + '" is not in the "new" IDD.')
                                        state.write_audit('... will be listed as comments on the new output file.')
                                        state.WriteOutIDFLinesAsComments(DifLfn_file, ObjectName, CurArgs, state.InArgs, state.FldNames, state.FldUnits)
                                        Written = True
                                    else:
                                        NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                            state.GetNewObjectDefInIDD(ObjectName)
                                        for i in range(CurArgs):
                                            state.OutArgs[i] = state.InArgs[i]
                                        NoDiff = True
                            
                            else:
                                NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                    state.GetNewObjectDefInIDD(state.IDFRecords[Num]['Name'])
                                for i in range(CurArgs):
                                    state.OutArgs[i] = state.InArgs[i]
                            
                            if DiffMinFields and NoDiff:
                                NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                    state.GetNewObjectDefInIDD(ObjectName)
                                for i in range(CurArgs):
                                    state.OutArgs[i] = state.InArgs[i]
                                NoDiff = False
                                for Arg in range(CurArgs, NwObjMinFlds):
                                    state.OutArgs[Arg] = NwFldDefaults[Arg]
                                CurArgs = max(NwObjMinFlds, CurArgs)
                            
                            if NoDiff and DiffOnly:
                                continue
                            
                            if not Written:
                                state.CheckSpecialObjects(DifLfn_file, ObjectName, CurArgs, state.OutArgs, NwFldNames, NwFldUnits)
                                Written = state.CheckSpecialObjectsWritten
                            
                            if not Written:
                                state.WriteOutIDFLines(DifLfn_file, ObjectName, CurArgs, state.OutArgs, NwFldNames, NwFldUnits)
                        
                        if state.IDFRecords[state.NumIDFRecords-1]['CommtE'] != state.CurComment:
                            for xcount in range(state.IDFRecords[state.NumIDFRecords-1]['CommtE']+1, state.CurComment+1):
                                DifLfn_file.write(state.Comments[xcount] + '\n')
                                if xcount == state.IDFRecords[state.NumIDFRecords-1]['CommtE']:
                                    DifLfn_file.write('\n')
                        
                        if state.GetNumSectionsFound('Report Variable Dictionary') > 0:
                            ObjectName = 'Output:VariableDictionary'
                            NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                state.GetNewObjectDefInIDD(ObjectName)
                            NoDiff = False
                            state.OutArgs[0] = 'Regular'
                            CurArgs = 1
                            state.WriteOutIDFLines(DifLfn_file, ObjectName, CurArgs, state.OutArgs, NwFldNames, NwFldUnits)
                        
                        try:
                            import os
                            var FileExist: Bool = os.path.exists(state.FileNamePath + '.rvi')
                        except:
                            FileExist = False
                        
                        DifLfn_file.close()
                        state.ProcessRviMviFiles(state.FileNamePath, 'rvi')
                        state.ProcessRviMviFiles(state.FileNamePath, 'mvi')
                        state.CloseOut()
                    
                    else:
                        state.ProcessRviMviFiles(state.FileNamePath, 'rvi')
                        state.ProcessRviMviFiles(state.FileNamePath, 'mvi')
                
                else:
                    EndOfFile = True
                
                state.CreateNewName('Reallocate', '', ' ')
            
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
            state.copyfile(state.FileNamePath + '.' + ArgIDFExtension, state.FileNamePath + '.' + ArgIDFExtension + 'old', ErrFlag)
            state.copyfile(state.FileNamePath + '.' + ArgIDFExtension + 'new', state.FileNamePath + '.' + ArgIDFExtension, ErrFlag)
            
            try:
                import os
                FileExist = os.path.exists(state.FileNamePath + '.rvi')
            except:
                FileExist = False
            
            if FileExist:
                state.copyfile(state.FileNamePath + '.rvi', state.FileNamePath + '.rviold', ErrFlag)
            
            try:
                import os
                FileExist = os.path.exists(state.FileNamePath + '.rvinew')
            except:
                FileExist = False
            
            if FileExist:
                state.copyfile(state.FileNamePath + '.rvinew', state.FileNamePath + '.rvi', ErrFlag)
            
            try:
                import os
                FileExist = os.path.exists(state.FileNamePath + '.mvi')
            except:
                FileExist = False
            
            if FileExist:
                state.copyfile(state.FileNamePath + '.mvi', state.FileNamePath + '.mviold', ErrFlag)
            
            try:
                import os
                FileExist = os.path.exists(state.FileNamePath + '.mvinew')
            except:
                FileExist = False
            
            if FileExist:
                state.copyfile(state.FileNamePath + '.mvinew', state.FileNamePath + '.mvi', ErrFlag)
        
        break
    
    return EndOfFile
