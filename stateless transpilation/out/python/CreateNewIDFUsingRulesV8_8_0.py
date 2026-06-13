def SetThisVersionVariables(state):
    """Set version variables for conversion 8.7 => 8.8"""
    state.VerString = 'Conversion 8.7 => 8.8'
    state.VersionNum = 8.8
    state.sVersionNum = '8.8'
    state.IDDFileNameWithPath = state.ProgramPath.rstrip() + 'V8-7-0-Energy+.idd'
    state.NewIDDFileNameWithPath = state.ProgramPath.rstrip() + 'V8-8-0-Energy+.idd'
    state.RepVarFileNameWithPath = state.ProgramPath.rstrip() + 'Report Variables 8-7-0 to 8-8-0.csv'


def CreateNewIDFUsingRules(EndOfFile, DiffOnly, InLfn, AskForInput, InputFileName, ArgFile, ArgIDFExtension, state):
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
        state: shared state object containing all module variables
    """
    
    FirstTime = True
    
    while True:
        StillWorking = True
        ArgFileBeingDone = False
        LatestVersion = False
        NoVersion = True
        LocalFileExtension = ArgIDFExtension
        EndOfFile = False
        IOS = 0
        
        while StillWorking:
            ExitBecauseBadFile = False
            
            while not EndOfFile:
                if AskForInput:
                    state.FullFileName = input('Enter input file name, with path\n--> ')
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
                
                if state.FullFileName and state.FullFileName[0] == '!':
                    state.FullFileName = state.blank
                    continue
                
                if IOS != 0:
                    state.FullFileName = state.blank
                
                state.FullFileName = state.FullFileName.lstrip()
                
                if state.FullFileName != state.blank:
                    state.DisplayString('Processing IDF -- ' + state.FullFileName)
                    state.write_audit('Processing IDF -- ' + state.FullFileName)
                    
                    DotPos = state.FullFileName.rfind('.')
                    if DotPos != -1:
                        state.FileNamePath = state.FullFileName[:DotPos]
                        LocalFileExtension = state.MakeLowerCase(state.FullFileName[DotPos+1:])
                    else:
                        state.FileNamePath = state.FullFileName
                        print(' assuming file extension of .idf')
                        state.write_audit(' ..assuming file extension of .idf')
                        state.FullFileName = state.FullFileName.rstrip() + '.idf'
                        LocalFileExtension = 'idf'
                    
                    DifLfn = state.GetNewUnitNumber()
                    
                    try:
                        with open(state.FullFileName, 'r') as f:
                            FileOK = True
                    except:
                        FileOK = False
                    
                    if not FileOK:
                        print('File not found=' + state.FullFileName)
                        state.write_audit('File not found=' + state.FullFileName)
                        EndOfFile = True
                        ExitBecauseBadFile = True
                        break
                    
                    if LocalFileExtension in ['idf', 'imf']:
                        checkrvi = False
                        ConnComp = False
                        ConnCompCtrl = False
                        
                        if DiffOnly:
                            out_filename = state.FileNamePath + '.' + LocalFileExtension + 'dif'
                        else:
                            out_filename = state.FileNamePath + '.' + LocalFileExtension + 'new'
                        
                        DifLfn = open(out_filename, 'w')
                        
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
                        
                        ScheduleTypeLimitsAnyNumber = False
                        for Num in range(state.NumIDFRecords):
                            if not state.SameString(state.IDFRecords[Num]['Name'], 'ScheduleTypeLimits'):
                                continue
                            if not state.SameString(state.IDFRecords[Num]['Alphas'][0], 'Any Number'):
                                continue
                            ScheduleTypeLimitsAnyNumber = True
                            break
                        
                        for Num in range(state.NumIDFRecords):
                            if state.DeleteThisRecord[Num]:
                                DifLfn.write('! Deleting: ' + state.IDFRecords[Num]['Name'].strip() + '="' + state.IDFRecords[Num]['Alphas'][0].strip() + '".\n')
                        
                        for Num in range(state.NumIDFRecords):
                            if state.DeleteThisRecord[Num]:
                                continue
                            
                            for xcount in range(state.IDFRecords[Num]['CommtS'], state.IDFRecords[Num]['CommtE']+1):
                                DifLfn.write(state.Comments[xcount] + '\n')
                                if xcount == state.IDFRecords[Num]['CommtE']:
                                    DifLfn.write('\n')
                            
                            if NoVersion and Num == 0:
                                NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                    state.GetNewObjectDefInIDD('VERSION')
                                state.OutArgs[0] = state.sVersionNum
                                CurArgs = 1
                                state.WriteOutIDFLinesAsComments(DifLfn, 'Version', CurArgs, state.OutArgs, NwFldNames, NwFldUnits)
                            
                            ObjectName = state.IDFRecords[Num]['Name']
                            
                            if state.MakeUPPERCase(state.IDFRecords[Num]['Name']).strip() in ['PROGRAMCONTROL', 'SKY RADIANCE DISTRIBUTION', 
                                                                                                 'AIRFLOW MODEL', 'GENERATOR:FC:BATTERY DATA',
                                                                                                 'AIRFLOWNETWORK:MULTIZONE:SITEWINDCONDITIONS']:
                                continue
                            
                            if state.MakeUPPERCase(state.IDFRecords[Num]['Name']).strip() == 'WATER HEATER:SIMPLE':
                                DifLfn.write('! ** The WATER HEATER:SIMPLE object has been deleted\n')
                                state.writePreprocessorObject(DifLfn, state.ProgNameConversion, 'Warning', 
                                                             'The WATER HEATER:SIMPLE object has been deleted')
                                continue
                            
                            if state.FindItemInList(ObjectName, state.ObjectDef, state.NumObjectDefs) != -1:
                                NumArgs, AorN, ReqFld, ObjMinFlds, FldNames, FldDefaults, FldUnits = \
                                    state.GetObjectDefInIDD(ObjectName)
                                NumAlphas = state.IDFRecords[Num]['NumAlphas']
                                NumNumbers = state.IDFRecords[Num]['NumNumbers']
                                
                                state.Alphas[:NumAlphas] = state.IDFRecords[Num]['Alphas'][:NumAlphas]
                                state.Numbers[:NumNumbers] = state.IDFRecords[Num]['Numbers'][:NumNumbers]
                                
                                CurArgs = NumAlphas + NumNumbers
                                state.InArgs = [state.blank] * len(state.InArgs)
                                state.OutArgs = [state.blank] * len(state.OutArgs)
                                
                                NA = 0
                                NN = 0
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
                                
                                state.Alphas[:NumAlphas] = state.IDFRecords[Num]['Alphas'][:NumAlphas]
                                state.Numbers[:NumNumbers] = state.IDFRecords[Num]['Numbers'][:NumNumbers]
                                
                                for Arg in range(NumAlphas):
                                    state.OutArgs[Arg] = state.Alphas[Arg]
                                
                                NN = NumAlphas
                                for Arg in range(NumNumbers):
                                    state.OutArgs[NN] = state.Numbers[Arg]
                                    NN += 1
                                
                                CurArgs = NumAlphas + NumNumbers
                                state.NwFldNames = [state.blank] * len(state.NwFldNames)
                                state.NwFldUnits = [state.blank] * len(state.NwFldUnits)
                                
                                state.WriteOutIDFLinesAsComments(DifLfn, ObjectName, CurArgs, state.OutArgs, state.NwFldNames, state.NwFldUnits)
                                continue
                            
                            NoDiff = True
                            DiffMinFields = False
                            Written = False
                            
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
                                        DifLfn.close()
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
                                    state.OutArgs = state.InArgs.copy()
                                    if state.SameString(state.InArgs[0], 'DecayCurvesfromZoneComponentLoads'):
                                        state.OutArgs[0] = 'DecayCurvesFromComponentLoadsSummary'
                                
                                elif obj_upper == 'TABLE:TWOINDEPENDENTVARIABLES':
                                    ObjectName = 'Table:TwoIndependentVariables'
                                    NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                        state.GetNewObjectDefInIDD(ObjectName)
                                    NoDiff = False
                                    state.OutArgs[0:13] = state.InArgs[0:13]
                                    state.OutArgs[13] = ''
                                    state.OutArgs[14:CurArgs+1] = state.InArgs[13:CurArgs]
                                    CurArgs = CurArgs + 1
                                
                                elif obj_upper == 'BUILDINGSURFACE:DETAILED':
                                    NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                        state.GetNewObjectDefInIDD(ObjectName)
                                    NoDiff = False
                                    if state.SameString(state.InArgs[4], 'Foundation') and state.SameString(state.InArgs[1], 'Floor'):
                                        NumPerimObjs = state.GetNumObjectsFound('SURFACEPROPERTY:EXPOSEDFOUNDATIONPERIMETER')
                                        PerimNum = 0
                                        for xcount in range(NumPerimObjs):
                                            Alphas, NumAlphas, Numbers, NumNumbers, Status = \
                                                state.GetObjectItem('SURFACEPROPERTY:EXPOSEDFOUNDATIONPERIMETER', xcount)
                                            if state.SameString(Alphas[0].strip(), state.InArgs[0].strip()):
                                                PerimNum = xcount
                                                break
                                        
                                        if PerimNum == 0:
                                            PArgs = (CurArgs - 10) // 3 + 4
                                            PNumArgs, PAorN, NwReqFld, PObjMinFlds, PFldNames, PFldDefaults, PFldUnits = \
                                                state.GetNewObjectDefInIDD('SURFACEPROPERTY:EXPOSEDFOUNDATIONPERIMETER')
                                            POutArgs = [state.blank] * (PArgs + 1)
                                            POutArgs[0] = state.InArgs[0]
                                            POutArgs[1] = 'BySegment'
                                            POutArgs[2] = ''
                                            POutArgs[3] = ''
                                            for xcount in range((CurArgs - 10) // 3):
                                                POutArgs[4 + xcount] = 'Yes'
                                            
                                            state.WriteOutIDFLines(DifLfn, 'SurfaceProperty:ExposedFoundationPerimeter', PArgs, POutArgs, PFldNames, PFldUnits)
                                            state.ShowWarningError('Foundation floors now require a SurfaceProperty:ExposedFoundationPerimeter object. One was added with each segment of the floor surface exposed. Please check your inputs to make sure this reflects your foundation.')
                                    
                                    state.OutArgs = state.InArgs.copy()
                                
                                elif obj_upper == 'FLOOR:DETAILED':
                                    NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                        state.GetNewObjectDefInIDD(ObjectName)
                                    NoDiff = False
                                    if state.SameString(state.InArgs[3], 'Foundation'):
                                        PerimNum = state.GetObjectItemNum('SURFACEPROPERTY:EXPOSEDFOUNDATIONPERIMETER', state.InArgs[0])
                                        if PerimNum == 0:
                                            PArgs = (CurArgs - 9) // 3 + 4
                                            PNumArgs, PAorN, NwReqFld, PObjMinFlds, PFldNames, PFldDefaults, PFldUnits = \
                                                state.GetNewObjectDefInIDD('SURFACEPROPERTY:EXPOSEDFOUNDATIONPERIMETER')
                                            POutArgs = [state.blank] * (PArgs + 1)
                                            POutArgs[0] = state.InArgs[0]
                                            POutArgs[1] = 'BySegment'
                                            POutArgs[2] = ''
                                            POutArgs[3] = ''
                                            for xcount in range((CurArgs - 9) // 3):
                                                POutArgs[4 + xcount] = 'Yes'
                                            
                                            state.WriteOutIDFLines(DifLfn, 'SurfaceProperty:ExposedFoundationPerimeter', PArgs, POutArgs, PFldNames, PFldUnits)
                                            state.ShowWarningError('Foundation floors now require a SurfaceProperty:ExposedFoundationPerimeter object. One was added with each segment of the floor surface exposed. Please check your inputs to make sure this reflects your foundation.')
                                    
                                    state.OutArgs = state.InArgs.copy()
                                
                                elif obj_upper == 'SURFACEPROPERTY:EXPOSEDFOUNDATIONPERIMETER':
                                    NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                        state.GetNewObjectDefInIDD(ObjectName)
                                    NoDiff = False
                                    state.OutArgs[0] = state.InArgs[0]
                                    state.OutArgs[1] = 'BySegment'
                                    state.OutArgs[2:CurArgs+1] = state.InArgs[1:CurArgs]
                                    CurArgs = CurArgs + 1
                                
                                elif obj_upper == 'FOUNDATION:KIVA:SETTINGS':
                                    NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                        state.GetNewObjectDefInIDD(ObjectName)
                                    NoDiff = False
                                    state.OutArgs = state.InArgs.copy()
                                    if state.SameString(state.InArgs[7], 'Autocalculate'):
                                        state.OutArgs[7] = 'Autoselect'
                                
                                elif obj_upper == 'UNITARYSYSTEMPERFORMANCE:MULTISPEED':
                                    NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                        state.GetNewObjectDefInIDD(ObjectName)
                                    NoDiff = False
                                    state.OutArgs[0:4] = state.InArgs[0:4]
                                    state.OutArgs[4] = ''
                                    state.OutArgs[5:CurArgs+1] = state.InArgs[4:CurArgs]
                                    CurArgs = CurArgs + 1
                                
                                elif obj_upper == 'COIL:COOLING:DX:SINGLESPEED':
                                    NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                        state.GetNewObjectDefInIDD(ObjectName)
                                    NoDiff = False
                                    state.OutArgs[0:14] = state.InArgs[0:14]
                                    state.OutArgs[14] = ''
                                    state.OutArgs[15:CurArgs+1] = state.InArgs[14:CurArgs]
                                    CurArgs = CurArgs + 1
                                
                                elif obj_upper == 'COIL:COOLING:DX:TWOSPEED':
                                    NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                        state.GetNewObjectDefInIDD(ObjectName)
                                    NoDiff = False
                                    state.OutArgs[0:22] = state.InArgs[0:22]
                                    state.OutArgs[22] = ''
                                    state.OutArgs[23:CurArgs+1] = state.InArgs[22:CurArgs]
                                    CurArgs = CurArgs + 1
                                
                                elif obj_upper == 'COIL:COOLING:DX:MULTISPEED':
                                    NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                        state.GetNewObjectDefInIDD(ObjectName)
                                    NoDiff = False
                                    state.OutArgs[0:6] = state.InArgs[0:6]
                                    state.OutArgs[6] = ''
                                    state.OutArgs[7:CurArgs+1] = state.InArgs[6:CurArgs]
                                    CurArgs = CurArgs + 1
                                
                                elif obj_upper == 'COIL:COOLING:DX:VARIABLESPEED':
                                    NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                        state.GetNewObjectDefInIDD(ObjectName)
                                    NoDiff = False
                                    state.OutArgs[0:15] = state.InArgs[0:15]
                                    state.OutArgs[15] = ''
                                    state.OutArgs[16:CurArgs+1] = state.InArgs[15:CurArgs]
                                    CurArgs = CurArgs + 1
                                
                                elif obj_upper == 'COIL:COOLING:DX:TWOSTAGEWITHHUMIDITYCONTROLMODE':
                                    NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                        state.GetNewObjectDefInIDD(ObjectName)
                                    NoDiff = False
                                    state.OutArgs[0:18] = state.InArgs[0:18]
                                    state.OutArgs[18] = ''
                                    state.OutArgs[19:CurArgs+1] = state.InArgs[18:CurArgs]
                                    CurArgs = CurArgs + 1
                                
                                elif obj_upper == 'ZONEHVAC:PACKAGEDTERMINALHEATPUMP':
                                    NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                        state.GetNewObjectDefInIDD(ObjectName)
                                    NoDiff = False
                                    state.OutArgs[0:17] = state.InArgs[0:17]
                                    state.OutArgs[17:CurArgs-1] = state.InArgs[18:CurArgs]
                                    CurArgs = CurArgs - 1
                                
                                elif obj_upper == 'ZONEHVAC:IDEALLOADSAIRSYSTEM':
                                    NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                        state.GetNewObjectDefInIDD(ObjectName)
                                    NoDiff = False
                                    state.OutArgs[0:4] = state.InArgs[0:4]
                                    state.OutArgs[4] = ''
                                    state.OutArgs[5:CurArgs+1] = state.InArgs[4:CurArgs]
                                    CurArgs = CurArgs + 1
                                
                                elif obj_upper == 'ZONECONTROL:CONTAMINANTCONTROLLER':
                                    NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                        state.GetNewObjectDefInIDD(ObjectName)
                                    if CurArgs > 4:
                                        NoDiff = False
                                        state.OutArgs[0:5] = state.InArgs[0:5]
                                        state.OutArgs[5] = ''
                                        state.OutArgs[6:CurArgs+1] = state.InArgs[5:CurArgs]
                                        CurArgs = CurArgs + 1
                                    else:
                                        NoDiff = True
                                        state.OutArgs = state.InArgs.copy()
                                
                                elif obj_upper == 'AVAILABILITYMANAGER:NIGHTCYCLE':
                                    NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                        state.GetNewObjectDefInIDD(ObjectName)
                                    NoDiff = False
                                    state.OutArgs[0:5] = state.InArgs[0:5]
                                    state.OutArgs[5] = 'FixedRunTime'
                                    state.OutArgs[6:CurArgs+1] = state.InArgs[5:CurArgs]
                                    CurArgs = CurArgs + 1
                                
                                elif obj_upper == 'OUTPUT:VARIABLE':
                                    NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                        state.GetNewObjectDefInIDD(ObjectName)
                                    state.OutArgs[0:CurArgs] = state.InArgs[0:CurArgs]
                                    NoDiff = True
                                    if state.OutArgs[0] == state.blank:
                                        state.OutArgs[0] = '*'
                                        NoDiff = False
                                    
                                    DelThis, checkrvi, NoDiff, Written = state.ScanOutputVariablesForReplacement(
                                        2, DelThis, checkrvi, NoDiff, ObjectName, DifLfn, True, False, False, CurArgs, Written, False)
                                    if DelThis:
                                        continue
                                
                                elif obj_upper in ['OUTPUT:METER', 'OUTPUT:METER:METERFILEONLY', 'OUTPUT:METER:CUMULATIVE', 'OUTPUT:METER:CUMULATIVE:METERFILEONLY']:
                                    NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                        state.GetNewObjectDefInIDD(ObjectName)
                                    state.OutArgs[0:CurArgs] = state.InArgs[0:CurArgs]
                                    NoDiff = True
                                    DelThis, checkrvi, NoDiff, Written = state.ScanOutputVariablesForReplacement(
                                        1, DelThis, checkrvi, NoDiff, ObjectName, DifLfn, False, True, False, CurArgs, Written, False)
                                    if DelThis:
                                        continue
                                
                                elif obj_upper == 'OUTPUT:TABLE:TIMEBINS':
                                    NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                        state.GetNewObjectDefInIDD(ObjectName)
                                    state.OutArgs[0:CurArgs] = state.InArgs[0:CurArgs]
                                    NoDiff = True
                                    if state.OutArgs[0] == state.blank:
                                        state.OutArgs[0] = '*'
                                        NoDiff = False
                                    DelThis, checkrvi, NoDiff, Written = state.ScanOutputVariablesForReplacement(
                                        2, DelThis, checkrvi, NoDiff, ObjectName, DifLfn, False, False, True, CurArgs, Written, False)
                                    if DelThis:
                                        continue
                                
                                elif obj_upper in ['EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITIMPORT:FROM:VARIABLE', 'EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITEXPORT:FROM:VARIABLE']:
                                    NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                        state.GetNewObjectDefInIDD(ObjectName)
                                    state.OutArgs[0:CurArgs] = state.InArgs[0:CurArgs]
                                    NoDiff = True
                                    if state.OutArgs[0] == state.blank:
                                        state.OutArgs[0] = '*'
                                        NoDiff = False
                                    DelThis, checkrvi, NoDiff, Written = state.ScanOutputVariablesForReplacement(
                                        2, DelThis, checkrvi, NoDiff, ObjectName, DifLfn, False, False, False, CurArgs, Written, False)
                                    if DelThis:
                                        continue
                                
                                elif obj_upper == 'ENERGYMANAGEMENTSYSTEM:SENSOR':
                                    NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                        state.GetNewObjectDefInIDD(ObjectName)
                                    state.OutArgs[0:CurArgs] = state.InArgs[0:CurArgs]
                                    NoDiff = True
                                    DelThis, checkrvi, NoDiff, Written = state.ScanOutputVariablesForReplacement(
                                        3, DelThis, checkrvi, NoDiff, ObjectName, DifLfn, False, False, False, CurArgs, Written, True)
                                    if DelThis:
                                        continue
                                
                                elif obj_upper == 'OUTPUT:TABLE:MONTHLY':
                                    NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                        state.GetNewObjectDefInIDD(ObjectName)
                                    NoDiff = True
                                    state.OutArgs[0:CurArgs] = state.InArgs[0:CurArgs]
                                    
                                    CurVar = 3
                                    Var = 3
                                    while Var < CurArgs:
                                        UCRepVarName = state.MakeUPPERCase(state.InArgs[Var])
                                        state.OutArgs[CurVar] = state.InArgs[Var]
                                        state.OutArgs[CurVar+1] = state.InArgs[Var+1]
                                        
                                        pos = UCRepVarName.find('[')
                                        if pos > 0:
                                            UCRepVarName = UCRepVarName[:pos]
                                            state.OutArgs[CurVar] = state.InArgs[Var][:pos]
                                            state.OutArgs[CurVar+1] = state.InArgs[Var+1]
                                        
                                        DelThis = False
                                        for Arg in range(state.NumRepVarNames):
                                            UCCompRepVarName = state.MakeUPPERCase(state.OldRepVarName[Arg])
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
                                                        state.OutArgs[CurVar] = state.NewRepVarName[Arg].strip() + state.OutArgs[CurVar][len(UCCompRepVarName.strip()):]
                                                    
                                                    if state.NewRepVarCaution[Arg] != state.blank and not state.SameString(state.NewRepVarCaution[Arg][:6], 'Forkeq'):
                                                        if not state.OTMVarCaution[Arg]:
                                                            state.writePreprocessorObject(DifLfn, state.ProgNameConversion, 'Warning',
                                                                'Output Table Monthly (old)="' + state.OldRepVarName[Arg].strip() + 
                                                                '" conversion to Output Table Monthly (new)="' + 
                                                                state.NewRepVarName[Arg].strip() + 
                                                                '" has the following caution "' + state.NewRepVarCaution[Arg].strip() + '".')
                                                            DifLfn.write('\n')
                                                            state.OTMVarCaution[Arg] = True
                                                    
                                                    state.OutArgs[CurVar+1] = state.InArgs[Var+1]
                                                    NoDiff = False
                                                else:
                                                    DelThis = True
                                                
                                                if Arg + 1 < state.NumRepVarNames and state.OldRepVarName[Arg] == state.OldRepVarName[Arg+1]:
                                                    if not state.SameString(state.NewRepVarCaution[Arg][:6], 'Forkeq'):
                                                        CurVar += 2
                                                        if not WildMatch:
                                                            state.OutArgs[CurVar] = state.NewRepVarName[Arg+1]
                                                        else:
                                                            state.OutArgs[CurVar] = state.NewRepVarName[Arg+1].strip() + state.OutArgs[CurVar][len(UCCompRepVarName.strip()):]
                                                        
                                                        if state.NewRepVarCaution[Arg+1] != state.blank:
                                                            if not state.OTMVarCaution[Arg+1]:
                                                                state.writePreprocessorObject(DifLfn, state.ProgNameConversion, 'Warning',
                                                                    'Output Table Monthly (old)="' + state.OldRepVarName[Arg].strip() + 
                                                                    '" conversion to Output Table Monthly (new)="' + 
                                                                    state.NewRepVarName[Arg+1].strip() + 
                                                                    '" has the following caution "' + state.NewRepVarCaution[Arg+1].strip() + '".')
                                                                DifLfn.write('\n')
                                                                state.OTMVarCaution[Arg+1] = True
                                                        
                                                        state.OutArgs[CurVar+1] = state.InArgs[Var+1]
                                                        NoDiff = False
                                                
                                                if Arg + 2 < state.NumRepVarNames and state.OldRepVarName[Arg] == state.OldRepVarName[Arg+2]:
                                                    CurVar += 2
                                                    if not WildMatch:
                                                        state.OutArgs[CurVar] = state.NewRepVarName[Arg+2]
                                                    else:
                                                        state.OutArgs[CurVar] = state.NewRepVarName[Arg+2].strip() + state.OutArgs[CurVar][len(UCCompRepVarName.strip()):]
                                                    
                                                    if state.NewRepVarCaution[Arg+2] != state.blank:
                                                        if not state.OTMVarCaution[Arg+2]:
                                                            state.writePreprocessorObject(DifLfn, state.ProgNameConversion, 'Warning',
                                                                'Output Table Monthly (old)="' + state.OldRepVarName[Arg].strip() + 
                                                                '" conversion to Output Table Monthly (new)="' + 
                                                                state.NewRepVarName[Arg+2].strip() + 
                                                                '" has the following caution "' + state.NewRepVarCaution[Arg+2].strip() + '".')
                                                                DifLfn.write('\n')
                                                                state.OTMVarCaution[Arg+2] = True
                                                    
                                                    state.OutArgs[CurVar+1] = state.InArgs[Var+1]
                                                    NoDiff = False
                                                
                                                break
                                        
                                        if not DelThis:
                                            CurVar += 2
                                        
                                        Var += 2
                                    
                                    CurArgs = CurVar - 1
                                
                                elif obj_upper == 'METER:CUSTOM' or obj_upper == 'METER:CUSTOMDECREMENT':
                                    NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                        state.GetNewObjectDefInIDD(ObjectName)
                                    state.OutArgs[0:CurArgs] = state.InArgs[0:CurArgs]
                                    NoDiff = True
                                    
                                    StartVar = 4
                                    CurVar = StartVar
                                    Var = StartVar
                                    CautionArray = state.CMtrVarCaution if obj_upper == 'METER:CUSTOM' else state.CMtrDVarCaution
                                    
                                    while Var < CurArgs:
                                        UCRepVarName = state.MakeUPPERCase(state.InArgs[Var])
                                        state.OutArgs[CurVar] = state.InArgs[Var]
                                        state.OutArgs[CurVar+1] = state.InArgs[Var+1]
                                        
                                        pos = UCRepVarName.find('[')
                                        if pos > 0:
                                            UCRepVarName = UCRepVarName[:pos]
                                            state.OutArgs[CurVar] = state.InArgs[Var][:pos]
                                            state.OutArgs[CurVar+1] = state.InArgs[Var+1]
                                        
                                        DelThis = False
                                        for Arg in range(state.NumRepVarNames):
                                            UCCompRepVarName = state.MakeUPPERCase(state.OldRepVarName[Arg])
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
                                                        state.OutArgs[CurVar] = state.NewRepVarName[Arg].strip() + state.OutArgs[CurVar][len(UCCompRepVarName.strip()):]
                                                    
                                                    if state.NewRepVarCaution[Arg] != state.blank and not state.SameString(state.NewRepVarCaution[Arg][:6], 'Forkeq'):
                                                        if not CautionArray[Arg]:
                                                            MeterType = 'Custom Meter' if obj_upper == 'METER:CUSTOM' else 'Custom Decrement Meter'
                                                            state.writePreprocessorObject(DifLfn, state.ProgNameConversion, 'Warning',
                                                                MeterType + ' (old)="' + state.OldRepVarName[Arg].strip() + 
                                                                '" conversion to ' + MeterType + ' (new)="' + 
                                                                state.NewRepVarName[Arg].strip() + 
                                                                '" has the following caution "' + state.NewRepVarCaution[Arg].strip() + '".')
                                                            DifLfn.write('\n')
                                                            CautionArray[Arg] = True
                                                    
                                                    state.OutArgs[CurVar+1] = state.InArgs[Var+1]
                                                    NoDiff = False
                                                else:
                                                    DelThis = True
                                                
                                                if Arg + 1 < state.NumRepVarNames and state.OldRepVarName[Arg] == state.OldRepVarName[Arg+1]:
                                                    if not state.SameString(state.NewRepVarCaution[Arg][:6], 'Forkeq'):
                                                        CurVar += 2
                                                        if not WildMatch:
                                                            state.OutArgs[CurVar] = state.NewRepVarName[Arg+1]
                                                        else:
                                                            state.OutArgs[CurVar] = state.NewRepVarName[Arg+1].strip() + state.OutArgs[CurVar][len(UCCompRepVarName.strip()):]
                                                        
                                                        if state.NewRepVarCaution[Arg+1] != state.blank and not state.SameString(state.NewRepVarCaution[Arg+1][:6], 'Forkeq'):
                                                            if not CautionArray[Arg+1]:
                                                                MeterType = 'Custom Meter' if obj_upper == 'METER:CUSTOM' else 'Custom Decrement Meter'
                                                                state.writePreprocessorObject(DifLfn, state.ProgNameConversion, 'Warning',
                                                                    MeterType + ' (old)="' + state.OldRepVarName[Arg].strip() + 
                                                                    '" conversion to ' + MeterType + ' (new)="' + 
                                                                    state.NewRepVarName[Arg+1].strip() + 
                                                                    '" has the following caution "' + state.NewRepVarCaution[Arg+1].strip() + '".')
                                                                DifLfn.write('\n')
                                                                CautionArray[Arg+1] = True
                                                        
                                                        state.OutArgs[CurVar+1] = state.InArgs[Var+1]
                                                        NoDiff = False
                                                
                                                if Arg + 2 < state.NumRepVarNames and state.OldRepVarName[Arg] == state.OldRepVarName[Arg+2]:
                                                    CurVar += 2
                                                    if not WildMatch:
                                                        state.OutArgs[CurVar] = state.NewRepVarName[Arg+2]
                                                    else:
                                                        state.OutArgs[CurVar] = state.NewRepVarName[Arg+2].strip() + state.OutArgs[CurVar][len(UCCompRepVarName.strip()):]
                                                    
                                                    if state.NewRepVarCaution[Arg+2] != state.blank:
                                                        if not CautionArray[Arg+2]:
                                                            MeterType = 'Custom Meter' if obj_upper == 'METER:CUSTOM' else 'Custom Decrement Meter'
                                                            state.writePreprocessorObject(DifLfn, state.ProgNameConversion, 'Warning',
                                                                MeterType + ' (old)="' + state.OldRepVarName[Arg].strip() + 
                                                                '" conversion to ' + MeterType + ' (new)="' + 
                                                                state.NewRepVarName[Arg+2].strip() + 
                                                                '" has the following caution "' + state.NewRepVarCaution[Arg+2].strip() + '".')
                                                            DifLfn.write('\n')
                                                            CautionArray[Arg+2] = True
                                                    
                                                    state.OutArgs[CurVar+1] = state.InArgs[Var+1]
                                                    NoDiff = False
                                                
                                                break
                                        
                                        if not DelThis:
                                            CurVar += 2
                                        
                                        Var += 2
                                    
                                    CurArgs = CurVar
                                    Arg = CurVar - 1
                                    while Arg >= 0:
                                        if state.OutArgs[Arg] == state.blank:
                                            CurArgs -= 1
                                        else:
                                            break
                                        Arg -= 1
                                
                                elif obj_upper == 'WINDOWMATERIAL:BLIND:EQUIVALENTLAYER':
                                    ObjectName = 'WindowMaterial:Blind:EquivalentLayer'
                                    NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                        state.GetNewObjectDefInIDD(ObjectName)
                                    state.OutArgs[0:CurArgs] = state.InArgs[0:CurArgs]
                                    NoDiff = True
                                    SaveNumber = state.ProcessNumber(state.OutArgs[5])
                                    if SaveNumber is None:
                                        state.ShowSevereError('Invalid Number, WINDOWMATERIAL:BLIND:EQUIVALENTLAYER field 6, Name=' + state.OutArgs[0].strip(), state.Auditf)
                                        DifLfn.write('  ! Invalid Number, field 6 {' + NwFldNames[5].strip() + '} value=' + state.OutArgs[5].strip() + '\n')
                                    else:
                                        if SaveNumber >= 90:
                                            SaveNumber = 90.0 - SaveNumber
                                            state.OutArgs[5] = state.TrimTrailZeros(SaveNumber)
                                
                                else:
                                    if state.FindItemInList(ObjectName, state.NotInNew, len(state.NotInNew)) != -1:
                                        state.write_audit('Object="' + ObjectName.strip() + '" is not in the "new" IDD.')
                                        state.write_audit('... will be listed as comments on the new output file.')
                                        state.WriteOutIDFLinesAsComments(DifLfn, ObjectName, CurArgs, state.InArgs, state.FldNames, state.FldUnits)
                                        Written = True
                                    else:
                                        NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                            state.GetNewObjectDefInIDD(ObjectName)
                                        state.OutArgs[0:CurArgs] = state.InArgs[0:CurArgs]
                                        NoDiff = True
                            
                            else:
                                NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                    state.GetNewObjectDefInIDD(state.IDFRecords[Num]['Name'])
                                state.OutArgs[0:CurArgs] = state.InArgs[0:CurArgs]
                            
                            if DiffMinFields and NoDiff:
                                NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                    state.GetNewObjectDefInIDD(ObjectName)
                                state.OutArgs[0:CurArgs] = state.InArgs[0:CurArgs]
                                NoDiff = False
                                for Arg in range(CurArgs, NwObjMinFlds):
                                    state.OutArgs[Arg] = NwFldDefaults[Arg]
                                CurArgs = max(NwObjMinFlds, CurArgs)
                            
                            if NoDiff and DiffOnly:
                                continue
                            
                            if not Written:
                                state.CheckSpecialObjects(DifLfn, ObjectName, CurArgs, state.OutArgs, NwFldNames, NwFldUnits)
                                Written = state.CheckSpecialObjectsWritten
                            
                            if not Written:
                                state.WriteOutIDFLines(DifLfn, ObjectName, CurArgs, state.OutArgs, NwFldNames, NwFldUnits)
                        
                        if state.IDFRecords[state.NumIDFRecords-1]['CommtE'] != state.CurComment:
                            for xcount in range(state.IDFRecords[state.NumIDFRecords-1]['CommtE']+1, state.CurComment+1):
                                DifLfn.write(state.Comments[xcount] + '\n')
                                if xcount == state.IDFRecords[state.NumIDFRecords-1]['CommtE']:
                                    DifLfn.write('\n')
                        
                        if state.GetNumSectionsFound('Report Variable Dictionary') > 0:
                            ObjectName = 'Output:VariableDictionary'
                            NwNumArgs, NwAorN, NwReqFld, NwObjMinFlds, NwFldNames, NwFldDefaults, NwFldUnits = \
                                state.GetNewObjectDefInIDD(ObjectName)
                            NoDiff = False
                            state.OutArgs[0] = 'Regular'
                            CurArgs = 1
                            state.WriteOutIDFLines(DifLfn, ObjectName, CurArgs, state.OutArgs, NwFldNames, NwFldUnits)
                        
                        try:
                            import os
                            FileExist = os.path.exists(state.FileNamePath + '.rvi')
                        except:
                            FileExist = False
                        
                        DifLfn.close()
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
            ErrFlag = False
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
