from cassert import assert
from cmath import sqrt, pow
from format import format
from Array.functions import *
from Autosizing.Base import *
from BranchNodeConnections import *
from CurveManager import *
from Data.EnergyPlusData import *
from DataBranchAirLoopPlant import *
from DataHVACGlobals import *
from DataHeatBalance import *
from DataIPShortCuts import *
from DataLoopNode import *
from DataSizing import *
from EMSManager import *
from FluidProperties import *
from General import *
from GlobalNames import *
from HeatBalanceInternalHeatGains import *
from InputProcessing.InputProcessor import *
from NodeInputManager import *
from OutputProcessor import *
from OutputReportPredefined import *
from Plant.DataPlant import *
from PlantPressureSystem import *
from PlantUtilities import *
from Pumps import *
from ScheduleManager import *
from UtilityRoutines import *

namespace EnergyPlus::Pumps:

    using HVAC.SmallWaterVolFlow
    using Node.ObjectIsNotParent

    static var pumpTypeIDFNames: StaticArray[StringRef, static_cast[int](PumpType.Num)] = StaticArray[StringRef, static_cast[int](PumpType.Num)](
        "Pump:VariableSpeed", "Pump:ConstantSpeed", "Pump:VariableSpeed:Condensate", "HeaderedPumps:VariableSpeed", "HeaderedPumps:ConstantSpeed"
    )

    def SimPumps(
        inout state: EnergyPlusData,
        PumpName: StringRef, # Name of pump to be managed
        LoopNum: Int, # Plant loop number
        FlowRequest: Float64, # requested flow from adjacent demand side
        inout PumpRunning: Bool, # .TRUE. if the loop pump is actually operating
        inout PumpIndex: Int,
        inout PumpHeat: Float64
    ):
        var PumpNum: Int # Pump index within PumpEquip derived type
        if state.dataPumps.GetInputFlag:
            GetPumpInput(state)
            state.dataPumps.GetInputFlag = False
        if state.dataPumps.NumPumps == 0:
            PumpHeat = 0.0
            return
        if PumpIndex == 0:
            PumpNum = Util.FindItemInList(PumpName, state.dataPumps.PumpEquip) # Determine which pump to simulate
            if PumpNum == 0:
                ShowFatalError(state, format("ManagePumps: Pump requested not found ={}", PumpName)) # Catch any bad names before crashing
            PumpIndex = PumpNum
        else:
            PumpNum = PumpIndex
            if state.dataPumps.PumpEquip[PumpNum].CheckEquipName:
                if PumpNum > state.dataPumps.NumPumps or PumpNum < 1:
                    ShowFatalError(
                        state,
                        format(
                            "ManagePumps: Invalid PumpIndex passed={}, Number of Pumps={}, Pump name={}", PumpNum, state.dataPumps.NumPumps, PumpName
                        )
                    )
                if PumpName != state.dataPumps.PumpEquip[PumpNum].Name:
                    ShowFatalError(state,
                        format("ManagePumps: Invalid PumpIndex passed={}, Pump name={}, stored Pump Name for that index={}",
                            PumpNum,
                            PumpName,
                            state.dataPumps.PumpEquip[PumpNum].Name
                        )
                    )
                state.dataPumps.PumpEquip[PumpNum].CheckEquipName = False
        InitializePumps(state, PumpNum)
        if state.dataPlnt.PlantLoop[LoopNum].LoopSide[state.dataPumps.PumpEquip[PumpNum].plantLoc.loopSideNum].FlowLock == DataPlant.FlowLock.PumpQuery:
            SetupPumpMinMaxFlows(state, LoopNum, PumpNum)
            return
        CalcPumps(state, PumpNum, FlowRequest, PumpRunning)
        ReportPumps(state, PumpNum)
        PumpHeat = state.dataPumps.PumpHeattoFluid

    def GetPumpInput(inout state: EnergyPlusData):
        using Curve.GetCurveIndex
        using Curve.GetCurveMinMaxValues
        using DataSizing.AutoSize
        using Node.GetOnlySingleNode
        using Node.TestCompSet
        var StartTemp: Float64 = 100.0 # Standard Temperature across code to calculated Steam density
        static var RoutineName: StringRef = "GetPumpInput: "
        static var routineName: StringRef = "GetPumpInput"
        static var pumpCtrlTypeNamesUC: StaticArray[StringRef, static_cast[int](PumpControlType.Num)] = StaticArray[StringRef, static_cast[int](PumpControlType.Num)]("CONTINUOUS", "INTERMITTENT")
        static var controlTypeVFDNamesUC: StaticArray[StringRef, static_cast[int](ControlTypeVFD.Num)] = StaticArray[StringRef, static_cast[int](ControlTypeVFD.Num)]("MANUALCONTROL", "PRESSURESETPOINTCONTROL")
        static var powerSizingMethodNamesUC: StaticArray[StringRef, static_cast[int](PowerSizingMethod.Num)] = StaticArray[StringRef, static_cast[int](PowerSizingMethod.Num)]("POWERPERFLOW", "POWERPERFLOWPERPRESSURE")
        var PumpNum: Int
        var NumAlphas: Int # Number of elements in the alpha array
        var NumNums: Int # Number of elements in the numeric array
        var IOStat: Int # IO Status when calling get input subroutine
        var ErrorsFound: Bool
        var TempCurveIndex: Int
        var NumVarSpeedPumps: Int = 0
        var NumConstSpeedPumps: Int = 0
        var NumCondensatePumps: Int = 0
        var NumPumpBankSimpleVar: Int = 0
        var NumPumpBankSimpleConst: Int = 0
        var SteamDensity: Float64
        var TempWaterDensity: Float64
        var minToMaxRatioMax: Float64 = 0.99
        ErrorsFound = False
        NumVarSpeedPumps = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, pumpTypeIDFNames[static_cast[int](PumpType.VarSpeed)])
        NumConstSpeedPumps = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, pumpTypeIDFNames[static_cast[int](PumpType.ConSpeed)])
        NumCondensatePumps = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, pumpTypeIDFNames[static_cast[int](PumpType.Cond)])
        NumPumpBankSimpleVar = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, pumpTypeIDFNames[static_cast[int](PumpType.Bank_VarSpeed)])
        NumPumpBankSimpleConst = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, pumpTypeIDFNames[static_cast[int](PumpType.Bank_ConSpeed)])
        state.dataPumps.NumPumps = NumVarSpeedPumps + NumConstSpeedPumps + NumCondensatePumps + NumPumpBankSimpleVar + NumPumpBankSimpleConst
        if state.dataPumps.NumPumps <= 0:
            ShowWarningError(state, "No Pumping Equipment Found")
            return
        state.dataPumps.PumpEquip.allocate(state.dataPumps.NumPumps)
        state.dataPumps.PumpUniqueNames.reserve(static_cast[UInt](state.dataPumps.NumPumps))
        state.dataPumps.PumpEquipReport.allocate(state.dataPumps.NumPumps)
        var cCurrentModuleObject: StringRef = state.dataIPShortCut.cCurrentModuleObject
        cCurrentModuleObject = pumpTypeIDFNames[static_cast[int](PumpType.VarSpeed)]
        var thisInput: DataIPShortCut = state.dataIPShortCut
        for PumpNum in range(1, NumVarSpeedPumps + 1):
            var thisPump: PumpSpecs = state.dataPumps.PumpEquip[PumpNum]
            state.dataInputProcessing.inputProcessor.getObjectItem(state,
                cCurrentModuleObject,
                PumpNum,
                thisInput.cAlphaArgs,
                NumAlphas,
                thisInput.rNumericArgs,
                NumNums,
                IOStat,
                thisInput.lNumericFieldBlanks,
                thisInput.lAlphaFieldBlanks,
                thisInput.cAlphaFieldNames,
                thisInput.cNumericFieldNames
            )
            var eoh: ErrorObjectHeader = ErrorObjectHeader(routineName, cCurrentModuleObject, thisInput.cAlphaArgs[1])
            GlobalNames.VerifyUniqueInterObjectName(
                state, state.dataPumps.PumpUniqueNames, thisInput.cAlphaArgs[1], cCurrentModuleObject, thisInput.cAlphaFieldNames[1], ErrorsFound
            )
            thisPump.Name = thisInput.cAlphaArgs[1]
            thisPump.pumpType = PumpType.VarSpeed #'Pump:VariableSpeed'
            thisPump.TypeOf_Num = DataPlant.PlantEquipmentType.PumpVariableSpeed
            thisPump.InletNodeNum = GetOnlySingleNode(state,
                thisInput.cAlphaArgs[2],
                ErrorsFound,
                Node.ConnectionObjectType.PumpVariableSpeed,
                thisPump.Name,
                Node.FluidType.Water,
                Node.ConnectionType.Inlet,
                Node.CompFluidStream.Primary,
                ObjectIsNotParent
            )
            thisPump.OutletNodeNum = GetOnlySingleNode(state,
                thisInput.cAlphaArgs[3],
                ErrorsFound,
                Node.ConnectionObjectType.PumpVariableSpeed,
                thisPump.Name,
                Node.FluidType.Water,
                Node.ConnectionType.Outlet,
                Node.CompFluidStream.Primary,
                ObjectIsNotParent
            )
            TestCompSet(state, cCurrentModuleObject, thisPump.Name, thisInput.cAlphaArgs[2], thisInput.cAlphaArgs[3], "Water Nodes")
            thisPump.PumpControl = static_cast[PumpControlType](getEnumValue(pumpCtrlTypeNamesUC, Util.makeUPPER(state.dataIPShortCut.cAlphaArgs[4])))
            if thisPump.PumpControl == PumpControlType.Invalid:
                ShowWarningError(
                    state, format("{}{}=\"{}\", Invalid {}", RoutineName, cCurrentModuleObject, thisPump.Name, thisInput.cAlphaFieldNames[4])
                )
                ShowContinueError(state,
                    format("Entered Value=[{}]. {} has been set to Continuous for this pump.",
                        thisInput.cAlphaArgs[4],
                        thisInput.cAlphaFieldNames[4]
                    )
                )
                thisPump.PumpControl = PumpControlType.Continuous
            if thisInput.cAlphaArgs[5].empty():
                thisPump.flowRateSched = None
            elif (thisPump.flowRateSched = Sched.GetSchedule(state, thisInput.cAlphaArgs[5])) == None:
                ShowWarningItemNotFound(state, eoh, thisInput.cAlphaFieldNames[5], thisInput.cAlphaArgs[5], "")
            thisPump.NomVolFlowRate = thisInput.rNumericArgs[1]
            if thisPump.NomVolFlowRate == AutoSize:
                thisPump.NomVolFlowRateWasAutoSized = True
            thisPump.NomPumpHead = thisInput.rNumericArgs[2]
            thisPump.NomPowerUse = thisInput.rNumericArgs[3]
            if thisPump.NomPowerUse == AutoSize:
                thisPump.NomPowerUseWasAutoSized = True
            thisPump.MotorEffic = thisInput.rNumericArgs[4]
            thisPump.FracMotorLossToFluid = thisInput.rNumericArgs[5]
            thisPump.PartLoadCoef[0] = thisInput.rNumericArgs[6]
            thisPump.PartLoadCoef[1] = thisInput.rNumericArgs[7]
            thisPump.PartLoadCoef[2] = thisInput.rNumericArgs[8]
            thisPump.PartLoadCoef[3] = thisInput.rNumericArgs[9]
            thisPump.MinVolFlowRate = thisInput.rNumericArgs[10]
            if thisPump.MinVolFlowRate == AutoSize:
                thisPump.minVolFlowRateWasAutosized = True
            elif not thisPump.NomVolFlowRateWasAutoSized and (thisPump.MinVolFlowRate > (minToMaxRatioMax * thisPump.NomVolFlowRate)):
                ShowWarningError(
                    state, format("{}{}=\"{}\", Invalid '{}'", RoutineName, cCurrentModuleObject, thisPump.Name, thisInput.cNumericFieldNames[10])
                )
                ShowContinueError(state,
                    format("Entered Value=[{:.5f}] is above or too close (equal) to the {}=[{:.5f}].",
                        thisPump.MinVolFlowRate,
                        thisInput.cNumericFieldNames[1],
                        thisPump.NomVolFlowRate
                    )
                )
                ShowContinueError(state,
                    format("Resetting value of '{}' to the value of 99% of '{}'.",
                        thisInput.cNumericFieldNames[10],
                        thisInput.cNumericFieldNames[1]
                    )
                )
                thisPump.MinVolFlowRate = minToMaxRatioMax * thisPump.NomVolFlowRate
            if thisInput.cAlphaArgs[6].empty():
                thisPump.PressureCurve_Index = -1
            else:
                TempCurveIndex = GetCurveIndex(state, thisInput.cAlphaArgs[6])
                if TempCurveIndex == 0:
                    thisPump.PressureCurve_Index = -1
                else:
                    ErrorsFound |= Curve.CheckCurveDims(state,
                        TempCurveIndex, # Curve index
                        {1}, # Valid dimensions
                        RoutineName, # Routine name
                        cCurrentModuleObject, # Object Type
                        thisPump.Name, # Object Name
                        thisInput.cAlphaFieldNames[6] # Field Name
                    )
                    if not ErrorsFound:
                        thisPump.PressureCurve_Index = TempCurveIndex
                        GetCurveMinMaxValues(state, TempCurveIndex, thisPump.MinPhiValue, thisPump.MaxPhiValue)
            thisPump.ImpellerDiameter = thisInput.rNumericArgs[11]
            if thisInput.lAlphaFieldBlanks[7]:
                thisPump.HasVFD = False
            else:
                thisPump.HasVFD = True
                thisPump.VFD.VFDControlType = static_cast[ControlTypeVFD](getEnumValue(controlTypeVFDNamesUC, Util.makeUPPER(state.dataIPShortCut.cAlphaArgs[7])))
                switch thisPump.VFD.VFDControlType:
                    case ControlTypeVFD.VFDManual:
                        if (thisPump.VFD.manualRPMSched = Sched.GetSchedule(state, thisInput.cAlphaArgs[8])) == None:
                            ShowSevereItemNotFound(state, eoh, thisInput.cAlphaFieldNames[8], thisInput.cAlphaArgs[8])
                            ErrorsFound = True
                        elif not thisPump.VFD.manualRPMSched.checkMinVal(state, Clusive.Ex, 0.0):
                            Sched.ShowSevereBadMin(state, eoh, thisInput.cAlphaFieldNames[8], thisInput.cAlphaArgs[8], Clusive.Ex, 0.0)
                            ErrorsFound = True
                    case ControlTypeVFD.VFDAutomatic:
                        if thisInput.lAlphaFieldBlanks[9]:
                            ShowSevereEmptyField(state, eoh, thisInput.cAlphaFieldNames[9])
                            ErrorsFound = True
                        elif (thisPump.VFD.lowerPsetSched = Sched.GetSchedule(state, thisInput.cAlphaArgs[9])) == None:
                            ShowSevereItemNotFound(state, eoh, thisInput.cAlphaFieldNames[9], thisInput.cAlphaArgs[9])
                            ErrorsFound = True
                        if thisInput.lAlphaFieldBlanks[10]:
                            ShowSevereEmptyField(state, eoh, thisInput.cAlphaFieldNames[10])
                            ErrorsFound = True
                        elif (thisPump.VFD.upperPsetSched = Sched.GetSchedule(state, thisInput.cAlphaArgs[10])) == None:
                            ShowSevereItemNotFound(state, eoh, thisInput.cAlphaFieldNames[10], thisInput.cAlphaArgs[10])
                            ErrorsFound = True
                        if thisInput.lAlphaFieldBlanks[11]:
                            ShowSevereEmptyField(state, eoh, thisInput.cAlphaFieldNames[11])
                            ErrorsFound = True
                        elif (thisPump.VFD.minRPMSched = Sched.GetSchedule(state, thisInput.cAlphaArgs[11])) == None:
                            ShowSevereItemNotFound(state, eoh, thisInput.cAlphaFieldNames[11], thisInput.cAlphaArgs[11])
                            ErrorsFound = True
                        elif not thisPump.VFD.minRPMSched.checkMinVal(state, Clusive.Ex, 0.0):
                            Sched.ShowSevereBadMin(state, eoh, thisInput.cAlphaFieldNames[11], thisInput.cAlphaArgs[11], Clusive.Ex, 0.0)
                            ErrorsFound = True
                        if thisInput.lAlphaFieldBlanks[12]:
                            ShowSevereEmptyField(state, eoh, thisInput.cAlphaFieldNames[12])
                            ErrorsFound = True
                        elif (thisPump.VFD.maxRPMSched = Sched.GetSchedule(state, thisInput.cAlphaArgs[12])) == None:
                            ShowSevereItemNotFound(state, eoh, thisInput.cAlphaFieldNames[12], thisInput.cAlphaArgs[12])
                            ErrorsFound = True
                        elif not thisPump.VFD.maxRPMSched.checkMinVal(state, Clusive.Ex, 0.0):
                            Sched.ShowSevereBadMin(state, eoh, thisInput.cAlphaFieldNames[12], thisInput.cAlphaArgs[12], Clusive.Ex, 0.0)
                            ErrorsFound = True
                    case _:
                        ShowSevereError(state,
                            format("{}{}=\"{}\", VFD Control type entered is invalid.  Use one of the key choice entries.",
                                RoutineName,
                                cCurrentModuleObject,
                                thisPump.Name
                            )
                        )
                        ErrorsFound = True
            if not thisInput.lAlphaFieldBlanks[13]: # zone named for pump skin losses
                thisPump.ZoneNum = Util.FindItemInList(thisInput.cAlphaArgs[13], state.dataHeatBal.Zone)
                if thisPump.ZoneNum > 0:
                    thisPump.HeatLossesToZone = True
                    if not thisInput.lNumericFieldBlanks[12]:
                        thisPump.SkinLossRadFraction = thisInput.rNumericArgs[12]
                else:
                    ShowSevereError(state,
                        format("{}=\"{}\" invalid {}=\"{}\" not found.",
                            cCurrentModuleObject,
                            thisPump.Name,
                            thisInput.cAlphaFieldNames[13],
                            thisInput.cAlphaArgs[13]
                        )
                    )
                    ErrorsFound = True
            if not thisInput.lAlphaFieldBlanks[14]:
                thisPump.powerSizingMethod = static_cast[PowerSizingMethod](getEnumValue(powerSizingMethodNamesUC, Util.makeUPPER(state.dataIPShortCut.cAlphaArgs[14])))
                if thisPump.powerSizingMethod == PowerSizingMethod.Invalid:
                    ShowSevereError(state,
                        format("{}{}=\"{}\", sizing method type entered is invalid.  Use one of the key choice entries.",
                            RoutineName,
                            cCurrentModuleObject,
                            thisPump.Name
                        )
                    )
                    ErrorsFound = True
            if not thisInput.lNumericFieldBlanks[13]:
                thisPump.powerPerFlowScalingFactor = thisInput.rNumericArgs[13]
            if not thisInput.lNumericFieldBlanks[14]:
                thisPump.powerPerFlowPerPressureScalingFactor = thisInput.rNumericArgs[14]
            if not thisInput.lNumericFieldBlanks[15]:
                thisPump.MinVolFlowRateFrac = thisInput.rNumericArgs[15]
            if NumAlphas > 14:
                thisPump.EndUseSubcategoryName = thisInput.cAlphaArgs[15]
            else:
                thisPump.EndUseSubcategoryName = "General"
            thisPump.Energy = 0.0
            thisPump.Power = 0.0
        cCurrentModuleObject = pumpTypeIDFNames[static_cast[int](PumpType.ConSpeed)]
        for NumConstPump in range(1, NumConstSpeedPumps + 1):
            PumpNum = NumVarSpeedPumps + NumConstPump
            var thisPump: PumpSpecs = state.dataPumps.PumpEquip[PumpNum]
            state.dataInputProcessing.inputProcessor.getObjectItem(state,
                cCurrentModuleObject,
                NumConstPump,
                thisInput.cAlphaArgs,
                NumAlphas,
                thisInput.rNumericArgs,
                NumNums,
                IOStat,
                thisInput.lNumericFieldBlanks,
                thisInput.lAlphaFieldBlanks,
                thisInput.cAlphaFieldNames,
                thisInput.cNumericFieldNames
            )
            var eoh: ErrorObjectHeader = ErrorObjectHeader(routineName, cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs[1])
            GlobalNames.VerifyUniqueInterObjectName(
                state, state.dataPumps.PumpUniqueNames, thisInput.cAlphaArgs[1], cCurrentModuleObject, thisInput.cAlphaFieldNames[1], ErrorsFound
            )
            thisPump.Name = thisInput.cAlphaArgs[1]
            thisPump.pumpType = PumpType.ConSpeed #'Pump:ConstantSpeed'
            thisPump.TypeOf_Num = DataPlant.PlantEquipmentType.PumpConstantSpeed
            thisPump.InletNodeNum = GetOnlySingleNode(state,
                thisInput.cAlphaArgs[2],
                ErrorsFound,
                Node.ConnectionObjectType.PumpConstantSpeed,
                thisPump.Name,
                Node.FluidType.Water,
                Node.ConnectionType.Inlet,
                Node.CompFluidStream.Primary,
                ObjectIsNotParent
            )
            thisPump.OutletNodeNum = GetOnlySingleNode(state,
                thisInput.cAlphaArgs[3],
                ErrorsFound,
                Node.ConnectionObjectType.PumpConstantSpeed,
                thisPump.Name,
                Node.FluidType.Water,
                Node.ConnectionType.Outlet,
                Node.CompFluidStream.Primary,
                ObjectIsNotParent
            )
            TestCompSet(state, cCurrentModuleObject, thisPump.Name, thisInput.cAlphaArgs[2], thisInput.cAlphaArgs[3], "Water Nodes")
            thisPump.NomVolFlowRate = thisInput.rNumericArgs[1]
            if thisPump.NomVolFlowRate == AutoSize:
                thisPump.NomVolFlowRateWasAutoSized = True
            thisPump.NomPumpHead = thisInput.rNumericArgs[2]
            thisPump.NomPowerUse = thisInput.rNumericArgs[3]
            if thisPump.NomPowerUse == AutoSize:
                thisPump.NomPowerUseWasAutoSized = True
            thisPump.MotorEffic = thisInput.rNumericArgs[4]
            thisPump.FracMotorLossToFluid = thisInput.rNumericArgs[5]
            thisPump.PartLoadCoef[0] = 1.0
            thisPump.PartLoadCoef[1] = 0.0
            thisPump.PartLoadCoef[2] = 0.0
            thisPump.PartLoadCoef[3] = 0.0
            thisPump.MinVolFlowRate = 0.0
            thisPump.Energy = 0.0
            thisPump.Power = 0.0
            thisPump.PumpControl = static_cast[PumpControlType](getEnumValue(pumpCtrlTypeNamesUC, Util.makeUPPER(state.dataIPShortCut.cAlphaArgs[4])))
            if thisPump.PumpControl == PumpControlType.Invalid:
                ShowWarningError(
                    state, format("{}{}=\"{}\", Invalid {}", RoutineName, cCurrentModuleObject, thisPump.Name, thisInput.cAlphaFieldNames[4])
                )
                ShowContinueError(state,
                    format("Entered Value=[{}]. {} has been set to Continuous for this pump.",
                        thisInput.cAlphaArgs[4],
                        thisInput.cAlphaFieldNames[4]
                    )
                )
                thisPump.PumpControl = PumpControlType.Continuous
            if thisInput.lAlphaFieldBlanks[5]:
                thisPump.flowRateSched = None
            elif (thisPump.flowRateSched = Sched.GetSchedule(state, thisInput.cAlphaArgs[5])) == None:
                ShowWarningItemNotFound(state, eoh, thisInput.cAlphaFieldNames[5], thisInput.cAlphaArgs[5], "")
            if thisInput.cAlphaArgs[6].empty():
                thisPump.PressureCurve_Index = -1
            else:
                TempCurveIndex = GetCurveIndex(state, thisInput.cAlphaArgs[6])
                if TempCurveIndex == 0:
                    thisPump.PressureCurve_Index = -1
                else:
                    ErrorsFound |= Curve.CheckCurveDims(state,
                        TempCurveIndex, # Curve index
                        {1}, # Valid dimensions
                        RoutineName, # Routine name
                        cCurrentModuleObject, # Object Type
                        thisPump.Name, # Object Name
                        thisInput.cAlphaFieldNames[6] # Field Name
                    )
                    if not ErrorsFound:
                        thisPump.PressureCurve_Index = TempCurveIndex
                        GetCurveMinMaxValues(state, TempCurveIndex, thisPump.MinPhiValue, thisPump.MaxPhiValue)
            thisPump.ImpellerDiameter = thisInput.rNumericArgs[6]
            thisPump.RotSpeed_RPM = thisInput.rNumericArgs[7] # retrieve the input rotational speed, in revs/min
            thisPump.RotSpeed = thisPump.RotSpeed_RPM / 60.0 # convert input[rpm] to calculation units[rps]
            if not thisInput.lAlphaFieldBlanks[7]: # zone named for pump skin losses
                thisPump.ZoneNum = Util.FindItemInList(thisInput.cAlphaArgs[7], state.dataHeatBal.Zone)
                if thisPump.ZoneNum > 0:
                    thisPump.HeatLossesToZone = True
                    if not thisInput.lNumericFieldBlanks[8]:
                        thisPump.SkinLossRadFraction = thisInput.rNumericArgs[8]
                else:
                    ShowSevereError(state,
                        format("{}=\"{}\" invalid {}=\"{}\" not found.",
                            cCurrentModuleObject,
                            thisPump.Name,
                            thisInput.cAlphaFieldNames[7],
                            thisInput.cAlphaArgs[7]
                        )
                    )
                    ErrorsFound = True
            if not thisInput.lAlphaFieldBlanks[8]:
                thisPump.powerSizingMethod = static_cast[PowerSizingMethod](getEnumValue(powerSizingMethodNamesUC, Util.makeUPPER(state.dataIPShortCut.cAlphaArgs[8])))
                if thisPump.powerSizingMethod == PowerSizingMethod.Invalid:
                    ShowSevereError(state,
                        format("{}{}=\"{}\", sizing method type entered is invalid.  Use one of the key choice entries.",
                            RoutineName,
                            cCurrentModuleObject,
                            thisPump.Name
                        )
                    )
                    ErrorsFound = True
            if not thisInput.lNumericFieldBlanks[9]:
                thisPump.powerPerFlowScalingFactor = thisInput.rNumericArgs[9]
            if not thisInput.lNumericFieldBlanks[10]:
                thisPump.powerPerFlowPerPressureScalingFactor = thisInput.rNumericArgs[10]
            if NumAlphas > 8:
                thisPump.EndUseSubcategoryName = thisInput.cAlphaArgs[9]
            else:
                thisPump.EndUseSubcategoryName = "General"
        cCurrentModuleObject = pumpTypeIDFNames[static_cast[int](PumpType.Cond)]
        for NumCondPump in range(1, NumCondensatePumps + 1):
            PumpNum = NumCondPump + NumVarSpeedPumps + NumConstSpeedPumps
            var thisPump: PumpSpecs = state.dataPumps.PumpEquip[PumpNum]
            state.dataInputProcessing.inputProcessor.getObjectItem(state,
                cCurrentModuleObject,
                NumCondPump,
                thisInput.cAlphaArgs,
                NumAlphas,
                thisInput.rNumericArgs,
                NumNums,
                IOStat,
                thisInput.lNumericFieldBlanks,
                thisInput.lAlphaFieldBlanks,
                thisInput.cAlphaFieldNames,
                thisInput.cNumericFieldNames
            )
            var eoh: ErrorObjectHeader = ErrorObjectHeader(routineName, cCurrentModuleObject, thisInput.cAlphaArgs[1])
            GlobalNames.VerifyUniqueInterObjectName(
                state, state.dataPumps.PumpUniqueNames, thisInput.cAlphaArgs[1], cCurrentModuleObject, thisInput.cAlphaFieldNames[1], ErrorsFound
            )
            thisPump.Name = thisInput.cAlphaArgs[1]
            thisPump.pumpType = PumpType.Cond #'Pump:VariableSpeed:Condensate'
            thisPump.TypeOf_Num = DataPlant.PlantEquipmentType.PumpCondensate
            thisPump.InletNodeNum = GetOnlySingleNode(state,
                thisInput.cAlphaArgs[2],
                ErrorsFound,
                Node.ConnectionObjectType.PumpVariableSpeedCondensate,
                thisPump.Name,
                Node.FluidType.Steam,
                Node.ConnectionType.Inlet,
                Node.CompFluidStream.Primary,
                ObjectIsNotParent
            )
            thisPump.OutletNodeNum = GetOnlySingleNode(state,
                thisInput.cAlphaArgs[3],
                ErrorsFound,
                Node.ConnectionObjectType.PumpVariableSpeedCondensate,
                thisPump.Name,
                Node.FluidType.Steam,
                Node.ConnectionType.Outlet,
                Node.CompFluidStream.Primary,
                ObjectIsNotParent
            )
            TestCompSet(state, cCurrentModuleObject, thisPump.Name, thisInput.cAlphaArgs[2], thisInput.cAlphaArgs[3], "Water Nodes")
            thisPump.PumpControl = PumpControlType.Intermittent
            if thisInput.cAlphaArgs[4].empty():
                thisPump.flowRateSched = None
            elif (thisPump.flowRateSched = Sched.GetSchedule(state, thisInput.cAlphaArgs[4])) == None:
                ShowWarningItemNotFound(state, eoh, thisInput.cAlphaFieldNames[4], thisInput.cAlphaArgs[4])
            thisPump.NomSteamVolFlowRate = thisInput.rNumericArgs[1]
            if thisPump.NomSteamVolFlowRate == AutoSize:
                thisPump.NomSteamVolFlowRateWasAutoSized = True
            thisPump.NomPumpHead = thisInput.rNumericArgs[2]
            thisPump.NomPowerUse = thisInput.rNumericArgs[3]
            if thisPump.NomPowerUse == AutoSize:
                thisPump.NomPowerUseWasAutoSized = True
            thisPump.MotorEffic = thisInput.rNumericArgs[4]
            thisPump.FracMotorLossToFluid = thisInput.rNumericArgs[5]
            thisPump.PartLoadCoef[0] = thisInput.rNumericArgs[6]
            thisPump.PartLoadCoef[1] = thisInput.rNumericArgs[7]
            thisPump.PartLoadCoef[2] = thisInput.rNumericArgs[8]
            thisPump.PartLoadCoef[3] = thisInput.rNumericArgs[9]
            if not thisInput.lAlphaFieldBlanks[5]: # zone named for pump skin losses
                thisPump.ZoneNum = Util.FindItemInList(thisInput.cAlphaArgs[5], state.dataHeatBal.Zone)
                if thisPump.ZoneNum > 0:
                    thisPump.HeatLossesToZone = True
                    if not thisInput.lNumericFieldBlanks[10]:
                        thisPump.SkinLossRadFraction = thisInput.rNumericArgs[10]
                else:
                    ShowSevereError(state,
                        format("{}=\"{}\" invalid {}=\"{}\" not found.",
                            cCurrentModuleObject,
                            thisPump.Name,
                            thisInput.cAlphaFieldNames[5],
                            thisInput.cAlphaArgs[5]
                        )
                    )
                    ErrorsFound = True
            thisPump.MinVolFlowRate = 0.0
            thisPump.Energy = 0.0
            thisPump.Power = 0.0
            if thisPump.NomSteamVolFlowRateWasAutoSized:
                thisPump.NomVolFlowRate = AutoSize
                thisPump.NomVolFlowRateWasAutoSized = True
            else:
                SteamDensity = Fluid.GetSteam(state).getSatDensity(state, StartTemp, 1.0, routineName)
                TempWaterDensity = Fluid.GetWater(state).getDensity(state, Constant.InitConvTemp, routineName)
                thisPump.NomVolFlowRate = (thisPump.NomSteamVolFlowRate * SteamDensity) / TempWaterDensity
            if not thisInput.lAlphaFieldBlanks[6]:
                thisPump.powerSizingMethod = static_cast[PowerSizingMethod](getEnumValue(powerSizingMethodNamesUC, Util.makeUPPER(state.dataIPShortCut.cAlphaArgs[6])))
                if thisPump.powerSizingMethod == PowerSizingMethod.Invalid:
                    ShowSevereError(state,
                        format("{}{}=\"{}\", sizing method type entered is invalid.  Use one of the key choice entries.",
                            RoutineName,
                            cCurrentModuleObject,
                            thisPump.Name
                        )
                    )
                    ErrorsFound = True
            if not thisInput.lNumericFieldBlanks[11]:
                thisPump.powerPerFlowScalingFactor = thisInput.rNumericArgs[11]
            if not thisInput.lNumericFieldBlanks[12]:
                thisPump.powerPerFlowPerPressureScalingFactor = thisInput.rNumericArgs[12]
            if NumAlphas > 6:
                thisPump.EndUseSubcategoryName = thisInput.cAlphaArgs[7]
            else:
                thisPump.EndUseSubcategoryName = "General"
        cCurrentModuleObject = pumpTypeIDFNames[static_cast[int](PumpType.Bank_VarSpeed)]
        for NumVarPumpBankSimple in range(1, NumPumpBankSimpleVar + 1):
            PumpNum = NumVarPumpBankSimple + NumVarSpeedPumps + NumConstSpeedPumps + NumCondensatePumps
            var thisPump: PumpSpecs = state.dataPumps.PumpEquip[PumpNum]
            state.dataInputProcessing.inputProcessor.getObjectItem(state,
                cCurrentModuleObject,
                NumVarPumpBankSimple,
                thisInput.cAlphaArgs,
                NumAlphas,
                thisInput.rNumericArgs,
                NumNums,
                IOStat,
                thisInput.lNumericFieldBlanks,
                thisInput.lAlphaFieldBlanks,
                thisInput.cAlphaFieldNames,
                thisInput.cNumericFieldNames
            )
            var eoh: ErrorObjectHeader = ErrorObjectHeader(routineName, cCurrentModuleObject, thisInput.cAlphaArgs[1])
            GlobalNames.VerifyUniqueInterObjectName(
                state, state.dataPumps.PumpUniqueNames, thisInput.cAlphaArgs[1], cCurrentModuleObject, thisInput.cAlphaFieldNames[1], ErrorsFound
            )
            thisPump.Name = thisInput.cAlphaArgs[1]
            thisPump.pumpType = PumpType.Bank_VarSpeed #'HeaderedPumps:VariableSpeed'
            thisPump.TypeOf_Num = DataPlant.PlantEquipmentType.PumpBankVariableSpeed
            thisPump.InletNodeNum = GetOnlySingleNode(state,
                thisInput.cAlphaArgs[2],
                ErrorsFound,
                Node.ConnectionObjectType.HeaderedPumpsVariableSpeed,
                thisPump.Name,
                Node.FluidType.Water,
                Node.ConnectionType.Inlet,
                Node.CompFluidStream.Primary,
                ObjectIsNotParent
            )
            thisPump.OutletNodeNum = GetOnlySingleNode(state,
                thisInput.cAlphaArgs[3],
                ErrorsFound,
                Node.ConnectionObjectType.HeaderedPumpsVariableSpeed,
                thisPump.Name,
                Node.FluidType.Water,
                Node.ConnectionType.Outlet,
                Node.CompFluidStream.Primary,
                ObjectIsNotParent
            )
            TestCompSet(state, cCurrentModuleObject, thisPump.Name, thisInput.cAlphaArgs[2], thisInput.cAlphaArgs[3], "Water Nodes")
            if Util.SameString(thisInput.cAlphaArgs[4], "Optimal"):
                thisPump.SequencingScheme = PumpBankControlSeq.OptimalScheme
            elif Util.SameString(thisInput.cAlphaArgs[4], "Sequential"):
                thisPump.SequencingScheme = PumpBankControlSeq.SequentialScheme
            elif Util.SameString(thisInput.cAlphaArgs[4], "SupplyEquipmentAssigned"):
                thisPump.SequencingScheme = PumpBankControlSeq.UserDefined
            else:
                ShowWarningError(
                    state, format("{}{}=\"{}\", Invalid {}", RoutineName, cCurrentModuleObject, thisPump.Name, thisInput.cAlphaFieldNames[4])
                )
                ShowContinueError(state,
                    format("Entered Value=[{}]. {} has been set to Sequential for this pump.",
                        thisInput.cAlphaArgs[4],
                        thisInput.cAlphaFieldNames[4]
                    )
                )
                thisPump.SequencingScheme = PumpBankControlSeq.SequentialScheme
            thisPump.PumpControl = static_cast[PumpControlType](getEnumValue(pumpCtrlTypeNamesUC, Util.makeUPPER(state.dataIPShortCut.cAlphaArgs[5])))
            if thisPump.PumpControl == PumpControlType.Invalid:
                ShowWarningError(
                    state, format("{}{}=\"{}\", Invalid {}", RoutineName, cCurrentModuleObject, thisPump.Name, thisInput.cAlphaFieldNames[5])
                )
                ShowContinueError(state,
                    format("Entered Value=[{}]. {} has been set to Continuous for this pump.",
                        thisInput.cAlphaArgs[5],
                        thisInput.cAlphaFieldNames[5]
                    )
                )
                thisPump.PumpControl = PumpControlType.Continuous
            if thisInput.cAlphaArgs[6].empty(): # Initialized to zero, don't get a schedule for an empty
                thisPump.flowRateSched = None
            elif (thisPump.flowRateSched = Sched.GetSchedule(state, thisInput.cAlphaArgs[6])) == None:
                ShowWarningItemNotFound(state, eoh, thisInput.cAlphaFieldNames[6], thisInput.cAlphaArgs[6])
            thisPump.NomVolFlowRate = thisInput.rNumericArgs[1]
            if thisPump.NomVolFlowRate == AutoSize:
                thisPump.NomVolFlowRateWasAutoSized = True
            thisPump.NumPumpsInBank = thisInput.rNumericArgs[2]
            thisPump.NomPumpHead = thisInput.rNumericArgs[3]
            thisPump.NomPowerUse = thisInput.rNumericArgs[4]
            if thisPump.NomPowerUse == AutoSize:
                thisPump.NomPowerUseWasAutoSized = True
            thisPump.MotorEffic = thisInput.rNumericArgs[5]
            thisPump.FracMotorLossToFluid = thisInput.rNumericArgs[6]
            thisPump.PartLoadCoef[0] = thisInput.rNumericArgs[7]
            thisPump.PartLoadCoef[1] = thisInput.rNumericArgs[8]
            thisPump.PartLoadCoef[2] = thisInput.rNumericArgs[9]
            thisPump.PartLoadCoef[3] = thisInput.rNumericArgs[10]
            thisPump.MinVolFlowRateFrac = thisInput.rNumericArgs[11]
            thisPump.MinVolFlowRate = thisPump.NomVolFlowRate * thisPump.MinVolFlowRateFrac
            if not thisInput.lAlphaFieldBlanks[7]: # zone named for pump skin losses
                thisPump.ZoneNum = Util.FindItemInList(thisInput.cAlphaArgs[7], state.dataHeatBal.Zone)
                if thisPump.ZoneNum > 0:
                    thisPump.HeatLossesToZone = True
                    if not thisInput.lNumericFieldBlanks[12]:
                        thisPump.SkinLossRadFraction = thisInput.rNumericArgs[12]
                else:
                    ShowSevereError(state,
                        format("{}=\"{}\" invalid {}=\"{}\" not found.",
                            cCurrentModuleObject,
                            thisPump.Name,
                            thisInput.cAlphaFieldNames[7],
                            thisInput.cAlphaArgs[7]
                        )
                    )
                    ErrorsFound = True
            if not thisInput.lAlphaFieldBlanks[8]:
                thisPump.powerSizingMethod = static_cast[PowerSizingMethod](getEnumValue(powerSizingMethodNamesUC, Util.makeUPPER(state.dataIPShortCut.cAlphaArgs[8])))
                if thisPump.powerSizingMethod == PowerSizingMethod.Invalid:
                    ShowSevereError(state,
                        format("{}{}=\"{}\", sizing method type entered is invalid.  Use one of the key choice entries.",
                            RoutineName,
                            cCurrentModuleObject,
                            thisPump.Name
                        )
                    )
                    ErrorsFound = True
            if not thisInput.lNumericFieldBlanks[13]:
                thisPump.powerPerFlowScalingFactor = thisInput.rNumericArgs[13]
            if not thisInput.lNumericFieldBlanks[14]:
                thisPump.powerPerFlowPerPressureScalingFactor = thisInput.rNumericArgs[14]
            if NumAlphas > 8:
                thisPump.EndUseSubcategoryName = thisInput.cAlphaArgs[9]
            else:
                thisPump.EndUseSubcategoryName = "General"
            thisPump.Energy = 0.0
            thisPump.Power = 0.0
        cCurrentModuleObject = pumpTypeIDFNames[static_cast[int](PumpType.Bank_ConSpeed)]
        for NumConstPumpBankSimple in range(1, NumPumpBankSimpleConst + 1):
            PumpNum = NumConstPumpBankSimple + NumVarSpeedPumps + NumConstSpeedPumps + NumCondensatePumps + NumPumpBankSimpleVar
            var thisPump: PumpSpecs = state.dataPumps.PumpEquip[PumpNum]
            state.dataInputProcessing.inputProcessor.getObjectItem(state,
                cCurrentModuleObject,
                NumConstPumpBankSimple,
                thisInput.cAlphaArgs,
                NumAlphas,
                thisInput.rNumericArgs,
                NumNums,
                IOStat,
                thisInput.lNumericFieldBlanks,
                thisInput.lAlphaFieldBlanks,
                thisInput.cAlphaFieldNames,
                thisInput.cNumericFieldNames
            )
            var eoh: ErrorObjectHeader = ErrorObjectHeader(routineName, cCurrentModuleObject, thisInput.cAlphaArgs[1])
            GlobalNames.VerifyUniqueInterObjectName(
                state, state.dataPumps.PumpUniqueNames, thisInput.cAlphaArgs[1], cCurrentModuleObject, thisInput.cAlphaFieldNames[1], ErrorsFound
            )
            thisPump.Name = thisInput.cAlphaArgs[1]
            thisPump.pumpType = PumpType.Bank_ConSpeed #'HeaderedPumps:ConstantSpeed'
            thisPump.TypeOf_Num = DataPlant.PlantEquipmentType.PumpBankConstantSpeed
            thisPump.InletNodeNum = GetOnlySingleNode(state,
                thisInput.cAlphaArgs[2],
                ErrorsFound,
                Node.ConnectionObjectType.HeaderedPumpsConstantSpeed,
                thisPump.Name,
                Node.FluidType.Water,
                Node.ConnectionType.Inlet,
                Node.CompFluidStream.Primary,
                ObjectIsNotParent
            )
            thisPump.OutletNodeNum = GetOnlySingleNode(state,
                thisInput.cAlphaArgs[3],
                ErrorsFound,
                Node.ConnectionObjectType.HeaderedPumpsConstantSpeed,
                thisPump.Name,
                Node.FluidType.Water,
                Node.ConnectionType.Outlet,
                Node.CompFluidStream.Primary,
                ObjectIsNotParent
            )
            TestCompSet(state, cCurrentModuleObject, thisPump.Name, thisInput.cAlphaArgs[2], thisInput.cAlphaArgs[3], "Water Nodes")
            if Util.SameString(thisInput.cAlphaArgs[4], "Optimal"):
                thisPump.SequencingScheme = PumpBankControlSeq.OptimalScheme
            elif Util.SameString(thisInput.cAlphaArgs[4], "Sequential"):
                thisPump.SequencingScheme = PumpBankControlSeq.SequentialScheme
            else:
                ShowWarningError(
                    state, format("{}{}=\"{}\", Invalid {}", RoutineName, cCurrentModuleObject, thisPump.Name, thisInput.cAlphaFieldNames[4])
                )
                ShowContinueError(state,
                    format("Entered Value=[{}]. {} has been set to Sequential for this pump.",
                        thisInput.cAlphaArgs[4],
                        thisInput.cAlphaFieldNames[4]
                    )
                )
                thisPump.SequencingScheme = PumpBankControlSeq.SequentialScheme
            thisPump.PumpControl = static_cast[PumpControlType](getEnumValue(pumpCtrlTypeNamesUC, Util.makeUPPER(state.dataIPShortCut.cAlphaArgs[5])))
            if thisPump.PumpControl == PumpControlType.Invalid:
                ShowWarningError(
                    state, format("{}{}=\"{}\", Invalid {}", RoutineName, cCurrentModuleObject, thisPump.Name, thisInput.cAlphaFieldNames[5])
                )
                ShowContinueError(state,
                    format("Entered Value=[{}]. {} has been set to Continuous for this pump.",
                        thisInput.cAlphaArgs[5],
                        thisInput.cAlphaFieldNames[5]
                    )
                )
                thisPump.PumpControl = PumpControlType.Continuous
            if thisInput.lAlphaFieldBlanks[6]:
                thisPump.flowRateSched = None
            elif (thisPump.flowRateSched = Sched.GetSchedule(state, thisInput.cAlphaArgs[6])) == None:
                ShowWarningItemNotFound(state, eoh, thisInput.cAlphaFieldNames[6], thisInput.cAlphaArgs[6], "")
            thisPump.NomVolFlowRate = thisInput.rNumericArgs[1]
            if thisPump.NomVolFlowRate == AutoSize:
                thisPump.NomVolFlowRateWasAutoSized = True
            thisPump.NumPumpsInBank = thisInput.rNumericArgs[2]
            thisPump.NomPumpHead = thisInput.rNumericArgs[3]
            thisPump.NomPowerUse = thisInput.rNumericArgs[4]
            if thisPump.NomPowerUse == AutoSize:
                thisPump.NomPowerUseWasAutoSized = True
            thisPump.MotorEffic = thisInput.rNumericArgs[5]
            thisPump.FracMotorLossToFluid = thisInput.rNumericArgs[6]
            thisPump.PartLoadCoef[0] = 1.0
            thisPump.PartLoadCoef[1] = 0.0
            thisPump.PartLoadCoef[2] = 0.0
            thisPump.PartLoadCoef[3] = 0.0
            if not thisInput.lAlphaFieldBlanks[7]: # zone named for pump skin losses
                thisPump.ZoneNum = Util.FindItemInList(thisInput.cAlphaArgs[7], state.dataHeatBal.Zone)
                if thisPump.ZoneNum > 0:
                    thisPump.HeatLossesToZone = True
                    if not thisInput.lNumericFieldBlanks[7]:
                        thisPump.SkinLossRadFraction = thisInput.rNumericArgs[7]
                else:
                    ShowSevereError(state,
                        format("{}=\"{}\" invalid {}=\"{}\" not found.",
                            cCurrentModuleObject,
                            thisPump.Name,
                            thisInput.cAlphaFieldNames[7],
                            thisInput.cAlphaArgs[7]
                        )
                    )
                    ErrorsFound = True
            if not thisInput.lAlphaFieldBlanks[8]:
                thisPump.powerSizingMethod = static_cast[PowerSizingMethod](getEnumValue(powerSizingMethodNamesUC, Util.makeUPPER(state.dataIPShortCut.cAlphaArgs[8])))
                if thisPump.powerSizingMethod == PowerSizingMethod.Invalid:
                    ShowSevereError(state,
                        format("{}{}=\"{}\", sizing method type entered is invalid.  Use one of the key choice entries.",
                            RoutineName,
                            cCurrentModuleObject,
                            thisPump.Name
                        )
                    )
                    ErrorsFound = True
            if not thisInput.lNumericFieldBlanks[8]:
                thisPump.powerPerFlowScalingFactor = thisInput.rNumericArgs[8]
            if not thisInput.lNumericFieldBlanks[9]:
                thisPump.powerPerFlowPerPressureScalingFactor = thisInput.rNumericArgs[9]
            if NumAlphas > 8:
                thisPump.EndUseSubcategoryName = thisInput.cAlphaArgs[9]
            else:
                thisPump.EndUseSubcategoryName = "General"
            thisPump.MinVolFlowRate = 0.0
            thisPump.Energy = 0.0
            thisPump.Power = 0.0
        if ErrorsFound:
            ShowFatalError(state, "Errors found in getting Pump input")
        for PumpNum in range(1, state.dataPumps.NumPumps + 1): # CurrentModuleObject='Pumps'
            var thisPump: PumpSpecs = state.dataPumps.PumpEquip[PumpNum]
            var thisPumpRep: ReportVars = state.dataPumps.PumpEquipReport[PumpNum]
            switch thisPump.pumpType:
                case PumpType.VarSpeed:
                case PumpType.ConSpeed:
                case PumpType.Cond:
                    SetupOutputVariable(state,
                        "Pump Electricity Energy",
                        Constant.Units.J,
                        thisPump.Energy,
                        OutputProcessor.TimeStepType.System,
                        OutputProcessor.StoreType.Sum,
                        thisPump.Name,
                        Constant.eResource.Electricity,
                        OutputProcessor.Group.Plant,
                        OutputProcessor.EndUseCat.Pumps,
                        thisPump.EndUseSubcategoryName
                    )
                    SetupOutputVariable(state,
                        "Pump Electricity Rate",
                        Constant.Units.W,
                        thisPump.Power,
                        OutputProcessor.TimeStepType.System,
                        OutputProcessor.StoreType.Average,
                        thisPump.Name
                    )
                    SetupOutputVariable(state,
                        "Pump Shaft Power",
                        Constant.Units.W,
                        thisPumpRep.ShaftPower,
                        OutputProcessor.TimeStepType.System,
                        OutputProcessor.StoreType.Average,
                        thisPump.Name
                    )
                    SetupOutputVariable(state,
                        "Pump Fluid Heat Gain Rate",
                        Constant.Units.W,
                        thisPumpRep.PumpHeattoFluid,
                        OutputProcessor.TimeStepType.System,
                        OutputProcessor.StoreType.Average,
                        thisPump.Name
                    )
                    SetupOutputVariable(state,
                        "Pump Fluid Heat Gain Energy",
                        Constant.Units.J,
                        thisPumpRep.PumpHeattoFluidEnergy,
                        OutputProcessor.TimeStepType.System,
                        OutputProcessor.StoreType.Sum,
                        thisPump.Name
                    )
                    SetupOutputVariable(state,
                        "Pump Outlet Temperature",
                        Constant.Units.C,
                        thisPumpRep.OutletTemp,
                        OutputProcessor.TimeStepType.System,
                        OutputProcessor.StoreType.Average,
                        thisPump.Name
                    )
                    SetupOutputVariable(state,
                        "Pump Mass Flow Rate",
                        Constant.Units.kg_s,
                        thisPumpRep.PumpMassFlowRate,
                        OutputProcessor.TimeStepType.System,
                        OutputProcessor.StoreType.Average,
                        thisPump.Name
                    )
                case PumpType.Bank_VarSpeed:
                case PumpType.Bank_ConSpeed: # CurrentModuleObject='HeaderedPumps'
                    SetupOutputVariable(state,
                        "Pump Electricity Energy",
                        Constant.Units.J,
                        thisPump.Energy,
                        OutputProcessor.TimeStepType.System,
                        OutputProcessor.StoreType.Sum,
                        thisPump.Name,
                        Constant.eResource.Electricity,
                        OutputProcessor.Group.Plant,
                        OutputProcessor.EndUseCat.Pumps,
                        thisPump.EndUseSubcategoryName
                    )
                    SetupOutputVariable(state,
                        "Pump Electricity Rate",
                        Constant.Units.W,
                        thisPump.Power,
                        OutputProcessor.TimeStepType.System,
                        OutputProcessor.StoreType.Average,
                        thisPump.Name
                    )
                    SetupOutputVariable(state,
                        "Pump Shaft Power",
                        Constant.Units.W,
                        thisPumpRep.ShaftPower,
                        OutputProcessor.TimeStepType.System,
                        OutputProcessor.StoreType.Average,
                        thisPump.Name
                    )
                    SetupOutputVariable(state,
                        "Pump Fluid Heat Gain Rate",
                        Constant.Units.W,
                        thisPumpRep.PumpHeattoFluid,
                        OutputProcessor.TimeStepType.System,
                        OutputProcessor.StoreType.Average,
                        thisPump.Name
                    )
                    SetupOutputVariable(state,
                        "Pump Fluid Heat Gain Energy",
                        Constant.Units.J,
                        thisPumpRep.PumpHeattoFluidEnergy,
                        OutputProcessor.TimeStepType.System,
                        OutputProcessor.StoreType.Sum,
                        thisPump.Name
                    )
                    SetupOutputVariable(state,
                        "Pump Outlet Temperature",
                        Constant.Units.C,
                        thisPumpRep.OutletTemp,
                        OutputProcessor.TimeStepType.System,
                        OutputProcessor.StoreType.Average,
                        thisPump.Name
                    )
                    SetupOutputVariable(state,
                        "Pump Mass Flow Rate",
                        Constant.Units.kg_s,
                        thisPumpRep.PumpMassFlowRate,
                        OutputProcessor.TimeStepType.System,
                        OutputProcessor.StoreType.Average,
                        thisPump.Name
                    )
                    SetupOutputVariable(state,
                        "Pump Operating Pumps Count",
                        Constant.Units.None,
                        thisPumpRep.NumPumpsOperating,
                        OutputProcessor.TimeStepType.System,
                        OutputProcessor.StoreType.Average,
                        thisPump.Name
                    )
                case _:
                    assert(False)
            if state.dataGlobal.AnyEnergyManagementSystemInModel:
                SetupEMSInternalVariable(state, "Pump Maximum Mass Flow Rate", thisPump.Name, "[kg/s]", thisPump.MassFlowRateMax)
                SetupEMSActuator(
                    state, "Pump", thisPump.Name, "Pump Mass Flow Rate", "[kg/s]", thisPump.EMSMassFlowOverrideOn, thisPump.EMSMassFlowValue
                )
                SetupEMSActuator(
                    state, "Pump", thisPump.Name, "Pump Pressure Rise", "[Pa]", thisPump.EMSPressureOverrideOn, thisPump.EMSPressureOverrideValue
                )
            if thisPump.HeatLossesToZone:
                SetupOutputVariable(state,
                    "Pump Zone Total Heating Rate",
                    Constant.Units.W,
                    thisPumpRep.ZoneTotalGainRate,
                    OutputProcessor.TimeStepType.System,
                    OutputProcessor.StoreType.Average,
                    thisPump.Name
                )
                SetupOutputVariable(state,
                    "Pump Zone Total Heating Energy",
                    Constant.Units.J,
                    thisPumpRep.ZoneTotalGainEnergy,
                    OutputProcessor.TimeStepType.System,
                    OutputProcessor.StoreType.Sum,
                    thisPump.Name
                )
                SetupOutputVariable(state,
                    "Pump Zone Convective Heating Rate",
                    Constant.Units.W,
                    thisPumpRep.ZoneConvGainRate,
                    OutputProcessor.TimeStepType.System,
                    OutputProcessor.StoreType.Average,
                    thisPump.Name
                )
                SetupOutputVariable(state,
                    "Pump Zone Radiative Heating Rate",
                    Constant.Units.W,
                    thisPumpRep.ZoneRadGainRate,
                    OutputProcessor.TimeStepType.System,
                    OutputProcessor.StoreType.Average,
                    thisPump.Name
                )
                switch thisPump.pumpType:
                    case PumpType.VarSpeed:
                        SetupZoneInternalGain(state,
                            thisPump.ZoneNum,
                            thisPump.Name,
                            DataHeatBalance.IntGainType.Pump_VarSpeed,
                            &thisPumpRep.ZoneConvGainRate,
                            None,
                            &thisPumpRep.ZoneRadGainRate
                        )
                    case PumpType.ConSpeed:
                        SetupZoneInternalGain(state,
                            thisPump.ZoneNum,
                            thisPump.Name,
                            DataHeatBalance.IntGainType.Pump_ConSpeed,
                            &thisPumpRep.ZoneConvGainRate,
                            None,
                            &thisPumpRep.ZoneRadGainRate
                        )
                    case PumpType.Cond:
                        SetupZoneInternalGain(state,
                            thisPump.ZoneNum,
                            thisPump.Name,
                            DataHeatBalance.IntGainType.Pump_Cond,
                            &thisPumpRep.ZoneConvGainRate,
                            None,
                            &thisPumpRep.ZoneRadGainRate
                        )
                    case PumpType.Bank_VarSpeed:
                        SetupZoneInternalGain(state,
                            thisPump.ZoneNum,
                            thisPump.Name,
                            DataHeatBalance.IntGainType.PumpBank_VarSpeed,
                            &thisPumpRep.ZoneConvGainRate,
                            None,
                            &thisPumpRep.ZoneRadGainRate
                        )
                    case PumpType.Bank_ConSpeed:
                        SetupZoneInternalGain(state,
                            thisPump.ZoneNum,
                            thisPump.Name,
                            DataHeatBalance.IntGainType.PumpBank_ConSpeed,
                            &thisPumpRep.ZoneConvGainRate,
                            None,
                            &thisPumpRep.ZoneRadGainRate
                        )
                    case _:
                        break

    def InitializePumps(inout state: EnergyPlusData, PumpNum: Int):
        using PlantUtilities.InitComponentNodes
        using PlantUtilities.ScanPlantLoopsForObject
        var StartTemp: Float64 = 100.0 # Standard Temperature across code to calculated Steam density
        var ZeroPowerTol: Float64 = 0.0000001
        static var RoutineName: StringRef = "PlantPumps::InitializePumps "
        var TotalEffic: Float64
        var SteamDensity: Float64 # Density of working fluid
        var TempWaterDensity: Float64
        var mdotMax: Float64 # local fluid mass flow rate maximum
        var mdotMin: Float64 # local fluid mass flow rate minimum
        var thisPump: PumpSpecs = state.dataPumps.PumpEquip[PumpNum]
        var InletNode: Int = thisPump.InletNodeNum
        var OutletNode: Int = thisPump.OutletNodeNum
        if thisPump.PumpOneTimeFlag:
            var errFlag: Bool = False
            ScanPlantLoopsForObject(state, thisPump.Name, thisPump.TypeOf_Num, thisPump.plantLoc, errFlag, _, _, _, _, _)
            if thisPump.plantLoc.loopNum > 0 and thisPump.plantLoc.loopSideNum != DataPlant.LoopSideLocation.Invalid and thisPump.plantLoc.branchNum > 0 and thisPump.plantLoc.compNum > 0:
                if thisPump.plantLoc.comp.NodeNumIn != InletNode or thisPump.plantLoc.comp.NodeNumOut != OutletNode:
                    ShowSevereError(state,
                        format("InitializePumps: {}=\"{}\", non-matching nodes.",
                            pumpTypeIDFNames[static_cast[int](thisPump.pumpType)],
                            thisPump.Name
                        )
                    )
                    ShowContinueError(state, format("...in Branch={}, Component referenced with:", thisPump.plantLoc.branch.Name))
                    ShowContinueError(state, format("...Inlet Node={}", state.dataLoopNodes.NodeID[thisPump.plantLoc.comp.NodeNumIn]))
                    ShowContinueError(state, format("...Outlet Node={}", state.dataLoopNodes.NodeID[thisPump.plantLoc.comp.NodeNumOut]))
                    ShowContinueError(state, format("...Pump Inlet Node={}", state.dataLoopNodes.NodeID[InletNode]))
                    ShowContinueError(state, format("...Pump Outlet Node={}", state.dataLoopNodes.NodeID[OutletNode]))
                    errFlag = True
            else: # CR9292
                ShowSevereError(
                    state,
                    format("InitializePumps: {}=\"{}\", component missing.", pumpTypeIDFNames[static_cast[int](thisPump.pumpType)], thisPump.Name)
                )
                errFlag = True # should have received warning/severe earlier, will reiterate
            if errFlag:
                ShowFatalError(state, "InitializePumps: Program terminated due to previous condition(s).")
            DataPlant.CompData.getPlantComponent(state, thisPump.plantLoc).CompNum = PumpNum
            SizePump(state, PumpNum)
            if thisPump.NomPowerUse > ZeroPowerTol and thisPump.MotorEffic > ZeroPowerTol:
                TotalEffic = thisPump.NomVolFlowRate * thisPump.NomPumpHead / thisPump.NomPowerUse
                thisPump.PumpEffic = TotalEffic / thisPump.MotorEffic
                if thisPump.PumpEffic < 0.50:
                    ShowWarningError(state,
                        format("Check input. Calculated Pump Efficiency={:.2f}% which is less than 50%, for pump={}",
                            thisPump.PumpEffic * 100.0,
                            thisPump.Name
                        )
                    )
                    ShowContinueError(state,
                        format("Calculated Pump_Efficiency % =Total_Efficiency % [{:.1f}] / Motor_Efficiency % [{:.1f}]",
                            TotalEffic * 100.0,
                            thisPump.MotorEffic * 100.0
                        )
                    )
                    ShowContinueError(
                        state,
                        format("Total_Efficiency % =(Rated_Volume_Flow_Rate [{:.3E}] * Rated_Pump_Head [{:.1f}] / Rated_Power_Use [{:.1f}]) * 100.",
                            thisPump.NomVolFlowRate,
                            thisPump.NomPumpHead,
                            thisPump.NomPowerUse
                        )
                    )
                elif (thisPump.PumpEffic > 0.95) and (thisPump.PumpEffic <= 1.0):
                    ShowWarningError(state,
                        format("Check input.  Calculated Pump Efficiency={:.2f}% is approaching 100%, for pump={}",
                            thisPump.PumpEffic * 100.0,
                            thisPump.Name
                        )
                    )
                    ShowContinueError(state,
                        format("Calculated Pump_Efficiency % =Total_Efficiency % [{:.1f}] / Motor_Efficiency % [{:.1f}]",
                            TotalEffic * 100.0,
                            thisPump.MotorEffic * 100.0
                        )
                    )
                    ShowContinueError(
                        state,
                        format("Total_Efficiency % =(Rated_Volume_Flow_Rate [{:.3E}] * Rated_Pump_Head [{:.1f}] / Rated_Power_Use [{:.1f}]) * 100.",
                            thisPump.NomVolFlowRate,
                            thisPump.NomPumpHead,
                            thisPump.NomPowerUse
                        )
                    )
                elif thisPump.PumpEffic > 1.0:
                    ShowSevereError(state,
                        format("Check input.  Calculated Pump Efficiency={:.3f}% which is bigger than 100%, for pump={}",
                            thisPump.PumpEffic * 100.0,
                            thisPump.Name
                        )
                    )
                    ShowContinueError(state,
                        format("Calculated Pump_Efficiency % =Total_Efficiency % [{:.1f}] / Motor_Efficiency % [{:.1f}]",
                            TotalEffic * 100.0,
                            thisPump.MotorEffic * 100.0
                        )
                    )
                    ShowContinueError(
                        state,
                        format("Total_Efficiency % =(Rated_Volume_Flow_Rate [{:.3E}] * Rated_Pump_Head [{:.1f}] / Rated_Power_Use [{:.1f}]) * 100.",
                            thisPump.NomVolFlowRate,
                            thisPump.NomPumpHead,
                            thisPump.NomPowerUse
                        )
                    )
                    ShowFatalError(state, "Errors found in Pump input")
            else:
                ShowWarningError(state, format("Check input. Pump nominal power or motor efficiency is set to 0, for pump={}", thisPump.Name))
            if thisPump.NomVolFlowRate <= SmallWaterVolFlow:
                ShowWarningError(state, format("Check input. Pump nominal flow rate is set or calculated = 0, for pump={}", thisPump.Name))
            if thisPump.PumpControl == PumpControlType.Continuous:
                DataPlant.CompData.getPlantComponent(state, thisPump.plantLoc).FlowPriority = DataPlant.LoopFlowStatus.NeedyAndTurnsLoopOn
            thisPump.PumpOneTimeFlag = False
        if state.dataGlobal.RedoSizesHVACSimulation and not state.dataPlnt.PlantReSizingCompleted:
            SizePump(state, PumpNum)
        if thisPump.PumpInitFlag and state.dataGlobal.BeginEnvrnFlag:
            if thisPump.pumpType == PumpType.Cond:
                TempWaterDensity = Fluid.GetWater(state).getDensity(state, Constant.InitConvTemp, RoutineName)
                SteamDensity = Fluid.GetSteam(state).getSatDensity(state, StartTemp, 1.0, RoutineName)
                thisPump.NomVolFlowRate = (thisPump.NomSteamVolFlowRate * SteamDensity) / TempWaterDensity
                mdotMax = thisPump.NomSteamVolFlowRate * SteamDensity
                mdotMin = 0.0
                InitComponentNodes(state, mdotMin, mdotMax, InletNode, OutletNode)
                thisPump.MassFlowRateMax = mdotMax
                thisPump.MassFlowRateMin = thisPump.MinVolFlowRate * SteamDensity
            else:
                TempWaterDensity = thisPump.plantLoc.loop.glycol.getDensity(state, Constant.InitConvTemp, RoutineName)
                mdotMax = thisPump.NomVolFlowRate * TempWaterDensity
                mdotMin = 0.0
                InitComponentNodes(state, mdotMin, mdotMax, InletNode, OutletNode)
                thisPump.MassFlowRateMax = mdotMax
                thisPump.MassFlowRateMin = thisPump.MinVolFlowRate * TempWaterDensity
            thisPump.Energy = 0.0
            thisPump.Power = 0.0
            new (state.dataPumps.PumpEquipReport[PumpNum]) ReportVars()
            thisPump.PumpInitFlag = False
        if not state.dataGlobal.BeginEnvrnFlag:
            thisPump.PumpInitFlag = True
        var daPumps: PumpsData = state.dataPumps
        daPumps.PumpMassFlowRate = 0.0
        daPumps.PumpHeattoFluid = 0.0
        daPumps.Power = 0.0
        daPumps.ShaftPower = 0.0

    def SetupPumpMinMaxFlows(inout state: EnergyPlusData, LoopNum: Int, PumpNum: Int):
        using PlantPressureSystem.ResolveLoopFlowVsPressure
        using PlantUtilities.BoundValueToWithinTwoValues
        var InletNode: Int # pump inlet node number
        var OutletNode: Int # pump outlet node number
        var InletNodeMax: Float64
        var InletNodeMin: Float64
        var PumpMassFlowRateMax: Float64 # max allowable flow rate at the pump
        var PumpMassFlowRateMin: Float64 # min allowable flow rate at the pump
        var PumpSchedFraction: Float64
        var PumpOverridableMaxLimit: Float64
        var PumpMassFlowRateMinLimit: Float64
        var PumpSchedRPM: Float64 # Pump RPM Optional Input
        var thisPump: PumpSpecs = state.dataPumps.PumpEquip[PumpNum]
        InletNode = thisPump.InletNodeNum
        OutletNode = thisPump.OutletNodeNum
        var thisInNode: NodeData = state.dataLoopNodes.Node[InletNode]
        var thisOutNode: NodeData = state.dataLoopNodes.Node[OutletNode]
        InletNodeMax = thisInNode.MassFlowRateMaxAvail
        InletNodeMin = thisInNode.MassFlowRateMinAvail
        PumpSchedFraction = (thisPump.flowRateSched != None) ? std.clamp(thisPump.flowRateSched.getCurrentVal(), 0.0, 1.0) : 1.0
        PumpOverridableMaxLimit = thisPump.MassFlowRateMax
        if thisPump.LoopSolverOverwriteFlag:
            PumpMassFlowRateMinLimit = 0.0
        else:
            PumpMassFlowRateMinLimit = thisPump.MassFlowRateMin
        PumpMassFlowRateMin = max(InletNodeMin, PumpMassFlowRateMinLimit)
        PumpMassFlowRateMax = min(InletNodeMax, PumpOverridableMaxLimit * PumpSchedFraction)
        if PumpMassFlowRateMin > PumpMassFlowRateMax: # the demand side wants to operate outside of the pump range
            PumpMassFlowRateMin = 0.0
            PumpMassFlowRateMax = 0.0
        switch thisPump.pumpType:
            case PumpType.VarSpeed:
                if thisPump.HasVFD:
                    switch thisPump.VFD.VFDControlType:
                        case ControlTypeVFD.VFDManual:
                            PumpSchedRPM = thisPump.VFD.manualRPMSched.getCurrentVal()
                            thisPump.RotSpeed = PumpSchedRPM / 60.0
                            if thisPump.plantLoc.loop.UsePressureForPumpCalcs and thisPump.plantLoc.loop.PressureSimType == DataPlant.PressSimType.FlowCorrection and thisPump.plantLoc.loop.PressureDrop > 0.0:
                                state.dataPumps.PumpMassFlowRate = ResolveLoopFlowVsPressure(state,
                                    thisPump.plantLoc.loopNum,
                                    state.dataLoopNodes.Node[thisPump.InletNodeNum].MassFlowRate,
                                    thisPump.PressureCurve_Index,
                                    thisPump.RotSpeed,
                                    thisPump.ImpellerDiameter,
                                    thisPump.MinPhiValue,
                                    thisPump.MaxPhiValue
                                )
                                PumpMassFlowRateMax = state.dataPumps.Pump