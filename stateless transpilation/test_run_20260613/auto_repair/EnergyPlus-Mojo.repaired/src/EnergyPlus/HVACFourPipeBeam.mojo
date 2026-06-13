from AirTerminalUnit import AirTerminalUnit
from Autosizing.Base import BaseSizer
from BranchNodeConnections import TestCompSet
from CurveManager import Curve
from Data.EnergyPlusData import EnergyPlusData
from DataContaminantBalance import Contaminant
from DataDefineEquip import AirDistUnit
from DataEnvironment import Envrn
from DataGlobals import BeginEnvrnFlag
from DataHVACGlobals import TimeStepSysSec
from DataIPShortCuts import IPShortCuts
from DataLoopNode import LoopNode
from DataSizing import AutoSize, FinalSysSizing, FinalZoneSizing, PlantSizData, TermUnitFinalZoneSizing
from DataSizing import DataSizing
from DataZoneEnergyDemands import ZoneSysEnergyDemand
from DataZoneEquipment import ZoneEquipConfig
from DataZoneEquipment import CheckZoneEquipmentList
from DataPlant import PlantLocation, LoopSideLocation, PlantEquipmentType
from FluidProperties import Glycol
from General import SolveRoot
from GeneralRoutines import CheckZoneSizing
from GlobalNames import VerifyUniqueADUName
from InputProcessing.InputProcessor import InputProcessor
from NodeInputManager import GetOnlySingleNode
from NodeInputManager import ObjectIsNotParent, ObjectIsParent
from OutputProcessor import OutputProcessor
from OutputProcessor import OutputProcessor
from OutputReportPredefined import PreDefTableEntry
from PlantUtilities import InitComponentNodes, ScanPlantLoopsForObject, SetComponentFlowRate, SafeCopyPlantNode, MyPlantSizingIndex, RegisterPlantCompDesignFlow
from Psychrometrics import PsyCpAirFnW
from ScheduleManager import Schedule
from ScheduleManager import Sched
from UtilityRoutines import ShowSevereError, ShowSevereItemNotFound, ShowContinueError, ShowWarningError, ShowFatalError, ShowRecurringWarningErrorAtEnd
from UtilityRoutines import ErrorObjectHeader
from Constant import Units, eResource
from HVAC import VerySmallMassFlow, SmallLoad
from Array1 import Array1D
from Array.functions import allocated
from Fmath import max, min
from math import sqrt
from format import format
from memory import shared_ptr
from string import String
from tuple import Tuple

struct HVACFourPipeBeam(AirTerminalUnit):
    var coolingAvailSched: Schedule = Schedule()
    var coolingAvailable: Bool = False
    var heatingAvailSched: Schedule = Schedule()
    var heatingAvailable: Bool = False
    var totBeamLength: Float64 = 0.0
    var totBeamLengthWasAutosized: Bool = False
    var vDotNormRatedPrimAir: Float64 = 0.0
    var mDotNormRatedPrimAir: Float64 = 0.0
    var beamCoolingPresent: Bool = False
    var vDotDesignCW: Float64 = 0.0
    var vDotDesignCWWasAutosized: Bool = False
    var mDotDesignCW: Float64 = 0.0
    var qDotNormRatedCooling: Float64 = 0.0
    var deltaTempRatedCooling: Float64 = 0.0
    var vDotNormRatedCW: Float64 = 0.0
    var mDotNormRatedCW: Float64 = 0.0
    var modCoolingQdotDeltaTFuncNum: Int = 0
    var modCoolingQdotAirFlowFuncNum: Int = 0
    var modCoolingQdotCWFlowFuncNum: Int = 0
    var mDotCW: Float64 = 0.0
    var cWTempIn: Float64 = 0.0
    var cWTempOut: Float64 = 0.0
    var cWTempOutErrorCount: Int = 0
    var cWInNodeNum: Int = 0
    var cWOutNodeNum: Int = 0
    var cWplantLoc: PlantLocation = PlantLocation(0, LoopSideLocation.Invalid, 0, 0)
    var beamHeatingPresent: Bool = False
    var vDotDesignHW: Float64 = 0.0
    var vDotDesignHWWasAutosized: Bool = False
    var mDotDesignHW: Float64 = 0.0
    var qDotNormRatedHeating: Float64 = 0.0
    var deltaTempRatedHeating: Float64 = 0.0
    var vDotNormRatedHW: Float64 = 0.0
    var mDotNormRatedHW: Float64 = 0.0
    var modHeatingQdotDeltaTFuncNum: Int = 0
    var modHeatingQdotAirFlowFuncNum: Int = 0
    var modHeatingQdotHWFlowFuncNum: Int = 0
    var mDotHW: Float64 = 0.0
    var hWTempIn: Float64 = 0.0
    var hWTempOut: Float64 = 0.0
    var hWTempOutErrorCount: Int = 0
    var hWInNodeNum: Int = 0
    var hWOutNodeNum: Int = 0
    var hWplantLoc: PlantLocation = PlantLocation(0, LoopSideLocation.Invalid, 0, 0)
    var beamCoolingEnergy: Float64 = 0.0
    var beamCoolingRate: Float64 = 0.0
    var beamHeatingEnergy: Float64 = 0.0
    var beamHeatingRate: Float64 = 0.0
    var supAirCoolingEnergy: Float64 = 0.0
    var supAirCoolingRate: Float64 = 0.0
    var supAirHeatingEnergy: Float64 = 0.0
    var supAirHeatingRate: Float64 = 0.0
    var primAirFlow: Float64 = 0.0
    var OutdoorAirFlowRate: Float64 = 0.0
    var myEnvrnFlag: Bool = True
    var mySizeFlag: Bool = True
    var plantLoopScanFlag: Bool = True
    var zoneEquipmentListChecked: Bool = False
    var tDBZoneAirTemp: Float64 = 0.0
    var tDBSystemAir: Float64 = 0.0
    var mDotSystemAir: Float64 = 0.0
    var cpZoneAir: Float64 = 0.0
    var cpSystemAir: Float64 = 0.0
    var qDotSystemAir: Float64 = 0.0
    var qDotBeamCoolingMax: Float64 = 0.0
    var qDotBeamHeatingMax: Float64 = 0.0
    var qDotTotalDelivered: Float64 = 0.0
    var qDotBeamCooling: Float64 = 0.0
    var qDotBeamHeating: Float64 = 0.0
    var qDotZoneReq: Float64 = 0.0
    var qDotBeamReq: Float64 = 0.0
    var qDotZoneToHeatSetPt: Float64 = 0.0
    var qDotZoneToCoolSetPt: Float64 = 0.0

    def __init__(inout self):

    def __del__(owned self):

    @staticmethod
    def fourPipeBeamFactory(inout state: EnergyPlusData, objectName: String) -> shared_ptr[AirTerminalUnit]:
        using Node.GetOnlySingleNode
        using Node.ObjectIsNotParent
        using Node.ObjectIsParent
        using Node.TestCompSet
        using Curve.GetCurveIndex
        var routineName: StaticString = "FourPipeBeamFactory "
        var beamIndex: Int
        var errFlag: Bool = False
        var ErrorsFound: Bool = False
        var found: Bool = False
        var airNodeFound: Bool = False
        var aDUIndex: Int
        var thisBeam: shared_ptr[HVACFourPipeBeam] = shared_ptr[HVACFourPipeBeam](HVACFourPipeBeam())
        var cCurrentModuleObject: String = state.dataIPShortCut.cCurrentModuleObject
        cCurrentModuleObject = "AirTerminal:SingleDuct:ConstantVolume:FourPipeBeam"
        beamIndex = state.dataInputProcessing.inputProcessor.getObjectItemNum(state, cCurrentModuleObject, objectName)
        if beamIndex > 0:
            var IOStatus: Int
            var NumAlphas: Int = 16
            var NumNumbers: Int = 11
            state.dataInputProcessing.inputProcessor.getObjectItem(state, cCurrentModuleObject, beamIndex, state.dataIPShortCut.cAlphaArgs, NumAlphas, state.dataIPShortCut.rNumericArgs, NumNumbers, IOStatus, state.dataIPShortCut.lNumericFieldBlanks, state.dataIPShortCut.lAlphaFieldBlanks, state.dataIPShortCut.cAlphaFieldNames, state.dataIPShortCut.cNumericFieldNames)
            found = True
        else:
            ErrorsFound = True
        var eoh: ErrorObjectHeader = ErrorObjectHeader(routineName, cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs[0])
        errFlag = False
        VerifyUniqueADUName(state, cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs[0], errFlag, cCurrentModuleObject + " Name")
        if errFlag:
            ErrorsFound = True
        thisBeam.name = state.dataIPShortCut.cAlphaArgs[0]
        thisBeam.unitType = cCurrentModuleObject
        if state.dataIPShortCut.lAlphaFieldBlanks[1]:
            thisBeam.airAvailSched = Sched.GetScheduleAlwaysOn(state)
        elif (thisBeam.airAvailSched = Sched.GetSchedule(state, state.dataIPShortCut.cAlphaArgs[1])) == None:
            ShowSevereItemNotFound(state, eoh, state.dataIPShortCut.cAlphaFieldNames[1], state.dataIPShortCut.cAlphaArgs[1])
            ErrorsFound = True
        if state.dataIPShortCut.lAlphaFieldBlanks[2]:
            thisBeam.coolingAvailSched = Sched.GetScheduleAlwaysOn(state)
        elif (thisBeam.coolingAvailSched = Sched.GetSchedule(state, state.dataIPShortCut.cAlphaArgs[2])) == None:
            ShowSevereItemNotFound(state, eoh, state.dataIPShortCut.cAlphaFieldNames[2], state.dataIPShortCut.cAlphaArgs[2])
            ErrorsFound = True
        if state.dataIPShortCut.lAlphaFieldBlanks[3]:
            thisBeam.heatingAvailSched = Sched.GetScheduleAlwaysOn(state)
        elif (thisBeam.heatingAvailSched = Sched.GetSchedule(state, state.dataIPShortCut.cAlphaArgs[3])) == None:
            ShowSevereItemNotFound(state, eoh, state.dataIPShortCut.cAlphaFieldNames[3], state.dataIPShortCut.cAlphaArgs[3])
            ErrorsFound = True
        thisBeam.airInNodeNum = GetOnlySingleNode(state, state.dataIPShortCut.cAlphaArgs[4], ErrorsFound, Node.ConnectionObjectType.AirTerminalSingleDuctConstantVolumeFourPipeBeam, state.dataIPShortCut.cAlphaArgs[0], Node.FluidType.Air, Node.ConnectionType.Inlet, Node.CompFluidStream.Primary, ObjectIsNotParent, state.dataIPShortCut.cAlphaFieldNames[4])
        thisBeam.airOutNodeNum = GetOnlySingleNode(state, state.dataIPShortCut.cAlphaArgs[5], ErrorsFound, Node.ConnectionObjectType.AirTerminalSingleDuctConstantVolumeFourPipeBeam, state.dataIPShortCut.cAlphaArgs[0], Node.FluidType.Air, Node.ConnectionType.Outlet, Node.CompFluidStream.Primary, ObjectIsNotParent, state.dataIPShortCut.cAlphaFieldNames[5])
        if state.dataIPShortCut.lAlphaFieldBlanks[6] and state.dataIPShortCut.lAlphaFieldBlanks[7]:
            thisBeam.beamCoolingPresent = False
        elif state.dataIPShortCut.lAlphaFieldBlanks[6] and not state.dataIPShortCut.lAlphaFieldBlanks[7]:
            thisBeam.beamCoolingPresent = False
            ShowWarningError(state, format("{}{}: missing {} for {}={}, simulation continues with no beam cooling", routineName, cCurrentModuleObject, state.dataIPShortCut.cAlphaFieldNames[6], state.dataIPShortCut.cAlphaFieldNames[0], state.dataIPShortCut.cAlphaArgs[0]))
        elif not state.dataIPShortCut.lAlphaFieldBlanks[6] and state.dataIPShortCut.lAlphaFieldBlanks[7]:
            thisBeam.beamCoolingPresent = False
            ShowWarningError(state, format("{}{}: missing {} for {}={}, simulation continues with no beam cooling", routineName, cCurrentModuleObject, state.dataIPShortCut.cAlphaFieldNames[7], state.dataIPShortCut.cAlphaFieldNames[0], state.dataIPShortCut.cAlphaArgs[0]))
        else:
            thisBeam.beamCoolingPresent = True
            thisBeam.cWInNodeNum = GetOnlySingleNode(state, state.dataIPShortCut.cAlphaArgs[6], ErrorsFound, Node.ConnectionObjectType.AirTerminalSingleDuctConstantVolumeFourPipeBeam, state.dataIPShortCut.cAlphaArgs[0], Node.FluidType.Water, Node.ConnectionType.Inlet, Node.CompFluidStream.Secondary, ObjectIsParent, state.dataIPShortCut.cAlphaFieldNames[6])
            thisBeam.cWOutNodeNum = GetOnlySingleNode(state, state.dataIPShortCut.cAlphaArgs[7], ErrorsFound, Node.ConnectionObjectType.AirTerminalSingleDuctConstantVolumeFourPipeBeam, state.dataIPShortCut.cAlphaArgs[0], Node.FluidType.Water, Node.ConnectionType.Outlet, Node.CompFluidStream.Secondary, ObjectIsParent, state.dataIPShortCut.cAlphaFieldNames[7])
        if state.dataIPShortCut.lAlphaFieldBlanks[8] and state.dataIPShortCut.lAlphaFieldBlanks[9]:
            thisBeam.beamHeatingPresent = False
        elif state.dataIPShortCut.lAlphaFieldBlanks[8] and not state.dataIPShortCut.lAlphaFieldBlanks[9]:
            thisBeam.beamHeatingPresent = False
            ShowWarningError(state, format("{}{}: missing {} for {}={}, simulation continues with no beam heating", routineName, cCurrentModuleObject, state.dataIPShortCut.cAlphaFieldNames[8], state.dataIPShortCut.cAlphaFieldNames[0], state.dataIPShortCut.cAlphaArgs[0]))
        elif not state.dataIPShortCut.lAlphaFieldBlanks[8] and state.dataIPShortCut.lAlphaFieldBlanks[9]:
            thisBeam.beamHeatingPresent = False
            ShowWarningError(state, format("{}{}: missing {} for {}={}, simulation continues with no beam heating", routineName, cCurrentModuleObject, state.dataIPShortCut.cAlphaFieldNames[9], state.dataIPShortCut.cAlphaFieldNames[0], state.dataIPShortCut.cAlphaArgs[0]))
        else:
            thisBeam.beamHeatingPresent = True
            thisBeam.hWInNodeNum = GetOnlySingleNode(state, state.dataIPShortCut.cAlphaArgs[8], ErrorsFound, Node.ConnectionObjectType.AirTerminalSingleDuctConstantVolumeFourPipeBeam, state.dataIPShortCut.cAlphaArgs[0], Node.FluidType.Water, Node.ConnectionType.Inlet, Node.CompFluidStream.Secondary, ObjectIsParent, state.dataIPShortCut.cAlphaFieldNames[8])
            thisBeam.hWOutNodeNum = GetOnlySingleNode(state, state.dataIPShortCut.cAlphaArgs[9], ErrorsFound, Node.ConnectionObjectType.AirTerminalSingleDuctConstantVolumeFourPipeBeam, state.dataIPShortCut.cAlphaArgs[0], Node.FluidType.Water, Node.ConnectionType.Outlet, Node.CompFluidStream.Secondary, ObjectIsParent, state.dataIPShortCut.cAlphaFieldNames[9])
        thisBeam.vDotDesignPrimAir = state.dataIPShortCut.rNumericArgs[0]
        if thisBeam.vDotDesignPrimAir == AutoSize:
            thisBeam.vDotDesignPrimAirWasAutosized = True
        thisBeam.vDotDesignCW = state.dataIPShortCut.rNumericArgs[1]
        if thisBeam.vDotDesignCW == AutoSize and thisBeam.beamCoolingPresent:
            thisBeam.vDotDesignCWWasAutosized = True
        thisBeam.vDotDesignHW = state.dataIPShortCut.rNumericArgs[2]
        if thisBeam.vDotDesignHW == AutoSize and thisBeam.beamHeatingPresent:
            thisBeam.vDotDesignHWWasAutosized = True
        thisBeam.totBeamLength = state.dataIPShortCut.rNumericArgs[3]
        if thisBeam.totBeamLength == AutoSize:
            thisBeam.totBeamLengthWasAutosized = True
        thisBeam.vDotNormRatedPrimAir = state.dataIPShortCut.rNumericArgs[4]
        thisBeam.qDotNormRatedCooling = state.dataIPShortCut.rNumericArgs[5]
        thisBeam.deltaTempRatedCooling = state.dataIPShortCut.rNumericArgs[6]
        thisBeam.vDotNormRatedCW = state.dataIPShortCut.rNumericArgs[7]
        thisBeam.modCoolingQdotDeltaTFuncNum = GetCurveIndex(state, state.dataIPShortCut.cAlphaArgs[10])
        if thisBeam.modCoolingQdotDeltaTFuncNum == 0 and thisBeam.beamCoolingPresent:
            ShowSevereError(state, format("{}{}=\"{}\"", routineName, cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs[0]))
            ShowContinueError(state, format("Invalid {}={}", state.dataIPShortCut.cAlphaFieldNames[10], state.dataIPShortCut.cAlphaArgs[10]))
            ErrorsFound = True
        thisBeam.modCoolingQdotAirFlowFuncNum = GetCurveIndex(state, state.dataIPShortCut.cAlphaArgs[11])
        if thisBeam.modCoolingQdotAirFlowFuncNum == 0 and thisBeam.beamCoolingPresent:
            ShowSevereError(state, format("{}{}=\"{}\"", routineName, cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs[0]))
            ShowContinueError(state, format("Invalid {}={}", state.dataIPShortCut.cAlphaFieldNames[11], state.dataIPShortCut.cAlphaArgs[11]))
            ErrorsFound = True
        thisBeam.modCoolingQdotCWFlowFuncNum = GetCurveIndex(state, state.dataIPShortCut.cAlphaArgs[12])
        if thisBeam.modCoolingQdotCWFlowFuncNum == 0 and thisBeam.beamCoolingPresent:
            ShowSevereError(state, format("{}{}=\"{}\"", routineName, cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs[0]))
            ShowContinueError(state, format("Invalid {}={}", state.dataIPShortCut.cAlphaFieldNames[12], state.dataIPShortCut.cAlphaArgs[12]))
            ErrorsFound = True
        thisBeam.qDotNormRatedHeating = state.dataIPShortCut.rNumericArgs[8]
        thisBeam.deltaTempRatedHeating = state.dataIPShortCut.rNumericArgs[9]
        thisBeam.vDotNormRatedHW = state.dataIPShortCut.rNumericArgs[10]
        thisBeam.modHeatingQdotDeltaTFuncNum = GetCurveIndex(state, state.dataIPShortCut.cAlphaArgs[13])
        if thisBeam.modHeatingQdotDeltaTFuncNum == 0 and thisBeam.beamHeatingPresent:
            ShowSevereError(state, format("{}{}=\"{}\"", routineName, cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs[0]))
            ShowContinueError(state, format("Invalid {}={}", state.dataIPShortCut.cAlphaFieldNames[13], state.dataIPShortCut.cAlphaArgs[13]))
            ErrorsFound = True
        thisBeam.modHeatingQdotAirFlowFuncNum = GetCurveIndex(state, state.dataIPShortCut.cAlphaArgs[14])
        if thisBeam.modHeatingQdotAirFlowFuncNum == 0 and thisBeam.beamHeatingPresent:
            ShowSevereError(state, format("{}{}=\"{}\"", routineName, cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs[0]))
            ShowContinueError(state, format("Invalid {}={}", state.dataIPShortCut.cAlphaFieldNames[14], state.dataIPShortCut.cAlphaArgs[14]))
            ErrorsFound = True
        thisBeam.modHeatingQdotHWFlowFuncNum = GetCurveIndex(state, state.dataIPShortCut.cAlphaArgs[15])
        if thisBeam.modHeatingQdotHWFlowFuncNum == 0 and thisBeam.beamHeatingPresent:
            ShowSevereError(state, format("{}{}=\"{}\"", routineName, cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs[0]))
            ShowContinueError(state, format("Invalid {}={}", state.dataIPShortCut.cAlphaFieldNames[15], state.dataIPShortCut.cAlphaArgs[15]))
            ErrorsFound = True
        TestCompSet(state, cCurrentModuleObject, thisBeam.name, state.dataLoopNodes.NodeID(thisBeam.airInNodeNum), state.dataLoopNodes.NodeID(thisBeam.airOutNodeNum), "Air Nodes")
        if thisBeam.beamCoolingPresent:
            TestCompSet(state, cCurrentModuleObject, thisBeam.name, state.dataLoopNodes.NodeID(thisBeam.cWInNodeNum), state.dataLoopNodes.NodeID(thisBeam.cWOutNodeNum), "Chilled Water Nodes")
        if thisBeam.beamHeatingPresent:
            TestCompSet(state, cCurrentModuleObject, thisBeam.name, state.dataLoopNodes.NodeID(thisBeam.hWInNodeNum), state.dataLoopNodes.NodeID(thisBeam.hWOutNodeNum), "Hot Water Nodes")
        if thisBeam.beamCoolingPresent:
            SetupOutputVariable(state, "Zone Air Terminal Beam Sensible Cooling Energy", Units.J, thisBeam.beamCoolingEnergy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, thisBeam.name, eResource.EnergyTransfer, OutputProcessor.Group.HVAC, OutputProcessor.EndUseCat.CoolingCoils)
            SetupOutputVariable(state, "Zone Air Terminal Beam Sensible Cooling Rate", Units.W, thisBeam.beamCoolingRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, thisBeam.name)
        if thisBeam.beamHeatingPresent:
            SetupOutputVariable(state, "Zone Air Terminal Beam Sensible Heating Energy", Units.J, thisBeam.beamHeatingEnergy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, thisBeam.name, eResource.EnergyTransfer, OutputProcessor.Group.HVAC, OutputProcessor.EndUseCat.HeatingCoils)
            SetupOutputVariable(state, "Zone Air Terminal Beam Sensible Heating Rate", Units.W, thisBeam.beamHeatingRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, thisBeam.name)
        SetupOutputVariable(state, "Zone Air Terminal Primary Air Sensible Cooling Energy", Units.J, thisBeam.supAirCoolingEnergy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, thisBeam.name)
        SetupOutputVariable(state, "Zone Air Terminal Primary Air Sensible Cooling Rate", Units.W, thisBeam.supAirCoolingRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, thisBeam.name)
        SetupOutputVariable(state, "Zone Air Terminal Primary Air Sensible Heating Energy", Units.J, thisBeam.supAirHeatingEnergy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, thisBeam.name)
        SetupOutputVariable(state, "Zone Air Terminal Primary Air Sensible Heating Rate", Units.W, thisBeam.supAirHeatingRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, thisBeam.name)
        SetupOutputVariable(state, "Zone Air Terminal Primary Air Flow Rate", Units.m3_s, thisBeam.primAirFlow, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, thisBeam.name)
        SetupOutputVariable(state, "Zone Air Terminal Outdoor Air Volume Flow Rate", Units.m3_s, thisBeam.OutdoorAirFlowRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, thisBeam.name)
        airNodeFound = False
        for aDUIndex in range(0, state.dataDefineEquipment.AirDistUnit.size()):
            if thisBeam.airOutNodeNum == state.dataDefineEquipment.AirDistUnit[aDUIndex].OutletNodeNum:
                thisBeam.aDUNum = aDUIndex + 1
                state.dataDefineEquipment.AirDistUnit[aDUIndex].InletNodeNum = thisBeam.airInNodeNum
        if thisBeam.aDUNum == 0:
            ShowSevereError(state, format("{}No matching Air Distribution Unit, for Unit = [{},{}].", routineName, cCurrentModuleObject, thisBeam.name))
            ShowContinueError(state, format("...should have outlet node={}", state.dataLoopNodes.NodeID(thisBeam.airOutNodeNum)))
            ErrorsFound = True
        else:
            for ctrlZone in range(1, state.dataGlobal.NumOfZones + 1):
                if not state.dataZoneEquip.ZoneEquipConfig[ctrlZone].IsControlled:
                    continue
                for supAirIn in range(1, state.dataZoneEquip.ZoneEquipConfig[ctrlZone].NumInletNodes + 1):
                    if thisBeam.airOutNodeNum == state.dataZoneEquip.ZoneEquipConfig[ctrlZone].InletNode[supAirIn]:
                        thisBeam.zoneIndex = ctrlZone
                        thisBeam.zoneNodeIndex = state.dataZoneEquip.ZoneEquipConfig[ctrlZone].ZoneNode
                        thisBeam.ctrlZoneInNodeIndex = supAirIn
                        state.dataZoneEquip.ZoneEquipConfig[ctrlZone].AirDistUnitCool[supAirIn].InNode = thisBeam.airInNodeNum
                        state.dataZoneEquip.ZoneEquipConfig[ctrlZone].AirDistUnitCool[supAirIn].OutNode = thisBeam.airOutNodeNum
                        state.dataDefineEquipment.AirDistUnit[thisBeam.aDUNum - 1].TermUnitSizingNum = state.dataZoneEquip.ZoneEquipConfig[ctrlZone].AirDistUnitCool[supAirIn].TermUnitSizingIndex
                        thisBeam.termUnitSizingNum = state.dataDefineEquipment.AirDistUnit[thisBeam.aDUNum - 1].TermUnitSizingNum
                        state.dataDefineEquipment.AirDistUnit[thisBeam.aDUNum - 1].ZoneEqNum = ctrlZone
                        if thisBeam.beamHeatingPresent:
                            state.dataZoneEquip.ZoneEquipConfig[ctrlZone].AirDistUnitHeat[supAirIn].InNode = thisBeam.airInNodeNum
                            state.dataZoneEquip.ZoneEquipConfig[ctrlZone].AirDistUnitHeat[supAirIn].OutNode = thisBeam.airOutNodeNum
                        airNodeFound = True
                        break
        if not airNodeFound:
            ShowSevereError(state, format("The outlet air node from the {} = {}", cCurrentModuleObject, thisBeam.name))
            ShowContinueError(state, format("did not have a matching Zone Equipment Inlet Node, Node ={}", state.dataIPShortCut.cAlphaArgs[4]))
            ErrorsFound = True
        if found and not ErrorsFound:
            state.dataFourPipeBeam.FourPipeBeams.append(thisBeam)
            return thisBeam
        ShowFatalError(state, format("{}Errors found in getting input. Preceding conditions cause termination.", routineName))
        return shared_ptr[AirTerminalUnit]()

    def getAirLoopNum(self) -> Int:
        return self.airLoopNum

    def getZoneIndex(self) -> Int:
        return self.zoneIndex

    def getPrimAirDesignVolFlow(self) -> Float64:
        return self.vDotDesignPrimAir

    def getTermUnitSizingIndex(self) -> Int:
        return self.termUnitSizingNum

    def simulate(inout self, inout state: EnergyPlusData, FirstHVACIteration: Bool, inout NonAirSysOutput: Float64):
        self.init(state, FirstHVACIteration)
        if not self.mySizeFlag:
            self.control(state, FirstHVACIteration, NonAirSysOutput)
            self.update(state)
            self.report(state)

    def init(inout self, inout state: EnergyPlusData, FirstHVACIteration: Bool):
        using DataZoneEquipment.CheckZoneEquipmentList
        using PlantUtilities.InitComponentNodes
        using PlantUtilities.ScanPlantLoopsForObject
        using PlantUtilities.SetComponentFlowRate
        var routineName: StaticString = "HVACFourPipeBeam::init"
        if self.plantLoopScanFlag and allocated(state.dataPlnt.PlantLoop):
            var errFlag: Bool = False
            if self.beamCoolingPresent:
                ScanPlantLoopsForObject(state, self.name, PlantEquipmentType.FourPipeBeamAirTerminal, self.cWplantLoc, errFlag, _, _, _, self.cWInNodeNum, _)
                if errFlag:
                    ShowFatalError(state, format("{} Program terminated for previous conditions.", routineName))
            if self.beamHeatingPresent:
                ScanPlantLoopsForObject(state, self.name, PlantEquipmentType.FourPipeBeamAirTerminal, self.hWplantLoc, errFlag, _, _, _, self.hWInNodeNum, _)
                if errFlag:
                    ShowFatalError(state, format("{} Program terminated for previous conditions.", routineName))
            self.plantLoopScanFlag = False
        if not self.zoneEquipmentListChecked and state.dataZoneEquip.ZoneEquipInputsFilled:
            if self.aDUNum != 0:
                if not CheckZoneEquipmentList(state, "ZONEHVAC:AIRDISTRIBUTIONUNIT", state.dataDefineEquipment.AirDistUnit[self.aDUNum - 1].Name):
                    ShowSevereError(state, format("{}: ADU=[Air Distribution Unit,{}] is not on any ZoneHVAC:EquipmentList.", routineName, state.dataDefineEquipment.AirDistUnit[self.aDUNum - 1].Name))
                    ShowContinueError(state, format("...Unit=[{},{}] will not be simulated.", self.unitType, self.name))
                self.zoneEquipmentListChecked = True
        if not state.dataGlobal.SysSizingCalc and self.mySizeFlag and not self.plantLoopScanFlag:
            self.airLoopNum = state.dataZoneEquip.ZoneEquipConfig[self.zoneIndex].InletNodeAirLoopNum[self.ctrlZoneInNodeIndex]
            state.dataDefineEquipment.AirDistUnit[self.aDUNum - 1].AirLoopNum = self.airLoopNum
            self.set_size(state)
            if self.beamCoolingPresent:
                InitComponentNodes(state, 0.0, self.mDotDesignCW, self.cWInNodeNum, self.cWOutNodeNum)
            if self.beamHeatingPresent:
                InitComponentNodes(state, 0.0, self.mDotDesignHW, self.hWInNodeNum, self.hWOutNodeNum)
            self.mySizeFlag = False
        if state.dataGlobal.BeginEnvrnFlag and self.myEnvrnFlag:
            state.dataLoopNodes.Node[self.airInNodeNum].MassFlowRateMax = self.mDotDesignPrimAir
            state.dataLoopNodes.Node[self.airOutNodeNum].MassFlowRateMax = self.mDotDesignPrimAir
            state.dataLoopNodes.Node[self.airInNodeNum].MassFlowRateMin = 0.0
            state.dataLoopNodes.Node[self.airOutNodeNum].MassFlowRateMin = 0.0
            if self.beamCoolingPresent:
                InitComponentNodes(state, 0.0, self.mDotDesignCW, self.cWInNodeNum, self.cWOutNodeNum)
            if self.beamHeatingPresent:
                InitComponentNodes(state, 0.0, self.mDotDesignHW, self.hWInNodeNum, self.hWOutNodeNum)
            if self.airLoopNum == 0:
                if self.zoneIndex > 0 and self.ctrlZoneInNodeIndex > 0:
                    self.airLoopNum = state.dataZoneEquip.ZoneEquipConfig[self.zoneIndex].InletNodeAirLoopNum[self.ctrlZoneInNodeIndex]
            self.myEnvrnFlag = False
        if not state.dataGlobal.BeginEnvrnFlag:
            self.myEnvrnFlag = True
        if FirstHVACIteration:
            self.airAvailable = (self.airAvailSched.getCurrentVal() > 0.0)
            self.coolingAvailable = (self.airAvailable and self.beamCoolingPresent and (self.coolingAvailSched.getCurrentVal() > 0.0))
            self.heatingAvailable = (self.airAvailable and self.beamHeatingPresent and (self.heatingAvailSched.getCurrentVal() > 0.0))
            if self.airAvailable and state.dataLoopNodes.Node[self.airInNodeNum].MassFlowRate > 0.0:
                state.dataLoopNodes.Node[self.airInNodeNum].MassFlowRate = self.mDotDesignPrimAir
            else:
                state.dataLoopNodes.Node[self.airInNodeNum].MassFlowRate = 0.0
            if self.airAvailable and state.dataLoopNodes.Node[self.airInNodeNum].MassFlowRateMaxAvail > 0.0:
                state.dataLoopNodes.Node[self.airInNodeNum].MassFlowRateMaxAvail = self.mDotDesignPrimAir
                state.dataLoopNodes.Node[self.airInNodeNum].MassFlowRateMinAvail = self.mDotDesignPrimAir
            else:
                state.dataLoopNodes.Node[self.airInNodeNum].MassFlowRateMaxAvail = 0.0
                state.dataLoopNodes.Node[self.airInNodeNum].MassFlowRateMinAvail = 0.0
        if self.beamCoolingPresent:
            self.cWTempIn = state.dataLoopNodes.Node[self.cWInNodeNum].Temp
            self.cWTempOut = self.cWTempIn
        if self.beamHeatingPresent:
            self.hWTempIn = state.dataLoopNodes.Node[self.hWInNodeNum].Temp
            self.hWTempOut = self.hWTempIn
        self.mDotSystemAir = state.dataLoopNodes.Node[self.airInNodeNum].MassFlowRateMaxAvail
        state.dataLoopNodes.Node[self.airInNodeNum].MassFlowRate = self.mDotSystemAir
        self.tDBZoneAirTemp = state.dataLoopNodes.Node[self.zoneNodeIndex].Temp
        self.tDBSystemAir = state.dataLoopNodes.Node[self.airInNodeNum].Temp
        self.cpZoneAir = PsyCpAirFnW(state.dataLoopNodes.Node[self.zoneNodeIndex].HumRat)
        self.cpSystemAir = PsyCpAirFnW(state.dataLoopNodes.Node[self.airInNodeNum].HumRat)
        self.qDotBeamCooling = 0.0
        self.qDotBeamHeating = 0.0
        self.supAirCoolingRate = 0.0
        self.supAirHeatingRate = 0.0
        self.beamCoolingRate = 0.0
        self.beamHeatingRate = 0.0
        self.primAirFlow = 0.0

    def set_size(inout self, inout state: EnergyPlusData):
        using PlantUtilities.MyPlantSizingIndex
        using PlantUtilities.RegisterPlantCompDesignFlow
        using Psychrometrics.PsyCpAirFnW
        var routineName: StaticString = "HVACFourPipeBeam::set_size "
        var ErrorsFound: Bool = False
        var rho: Float64
        var noHardSizeAnchorAvailable: Bool
        var cpAir: Float64 = 0.0
        var ErrTolerance: Float64 = 0.001
        var mDotAirSolutionHeating: Float64 = 0.0
        var mDotAirSolutionCooling: Float64 = 0.0
        var originalTermUnitSizeMaxVDot: Float64 = 0.0
        var originalTermUnitSizeCoolVDot: Float64 = 0.0
        var originalTermUnitSizeHeatVDot: Float64 = 0.0
        self.mDotNormRatedPrimAir = self.vDotNormRatedPrimAir * state.dataEnvrn.rhoAirSTP
        noHardSizeAnchorAvailable = False
        if state.dataSize.CurTermUnitSizingNum > 0:
            originalTermUnitSizeMaxVDot = max(state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].DesCoolVolFlow, state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].DesHeatVolFlow)
            originalTermUnitSizeCoolVDot = state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].DesCoolVolFlow
            originalTermUnitSizeHeatVDot = state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].DesHeatVolFlow
        if self.totBeamLengthWasAutosized and self.vDotDesignPrimAirWasAutosized and self.vDotDesignCWWasAutosized and self.vDotDesignHWWasAutosized:
            noHardSizeAnchorAvailable = True
        elif self.totBeamLengthWasAutosized and self.vDotDesignPrimAirWasAutosized and self.vDotDesignCWWasAutosized and not self.beamHeatingPresent:
            noHardSizeAnchorAvailable = True
        elif self.totBeamLengthWasAutosized and self.vDotDesignPrimAirWasAutosized and not self.beamCoolingPresent and self.vDotDesignHWWasAutosized:
            noHardSizeAnchorAvailable = True
        elif not self.totBeamLengthWasAutosized:
            if self.vDotDesignPrimAirWasAutosized:
                self.vDotDesignPrimAir = self.vDotNormRatedPrimAir * self.totBeamLength
            if self.vDotDesignCWWasAutosized:
                self.vDotDesignCW = self.vDotNormRatedCW * self.totBeamLength
            if self.vDotDesignHWWasAutosized:
                self.vDotDesignHW = self.vDotNormRatedHW * self.totBeamLength
        else:
            if not self.vDotDesignPrimAirWasAutosized:
                self.totBeamLength = self.vDotDesignPrimAir / self.vDotNormRatedPrimAir
                if self.vDotDesignCWWasAutosized:
                    self.vDotDesignCW = self.vDotNormRatedCW * self.totBeamLength
                if self.vDotDesignHWWasAutosized:
                    self.vDotDesignHW = self.vDotNormRatedHW * self.totBeamLength
            else:
                if self.beamCoolingPresent and not self.vDotDesignCWWasAutosized:
                    self.totBeamLength = self.vDotDesignCW / self.vDotNormRatedCW
                    self.vDotDesignPrimAir = self.vDotNormRatedPrimAir * self.totBeamLength
                    if self.vDotDesignHWWasAutosized:
                        self.vDotDesignHW = self.vDotNormRatedHW * self.totBeamLength
                elif self.beamHeatingPresent and not self.vDotDesignHWWasAutosized:
                    self.totBeamLength = self.vDotDesignHW / self.vDotNormRatedHW
                    self.vDotDesignPrimAir = self.vDotNormRatedPrimAir * self.totBeamLength
                    if self.vDotDesignCWWasAutosized:
                        self.vDotDesignCW = self.vDotNormRatedCW * self.totBeamLength
                else:

        if noHardSizeAnchorAvailable and (state.dataSize.CurZoneEqNum > 0) and (state.dataSize.CurTermUnitSizingNum > 0):
            CheckZoneSizing(state, self.unitType, self.name)
            var minFlow: Float64 = 0.0
            var maxFlowCool: Float64 = 0.0
            minFlow = min(state.dataEnvrn.StdRhoAir * originalTermUnitSizeMaxVDot, state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].MinOA * state.dataEnvrn.StdRhoAir)
            minFlow = max(0.0, minFlow)
            if self.beamCoolingPresent:
                cpAir = PsyCpAirFnW(state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].DesCoolCoilInHumRatTU)
                if (state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].ZoneTempAtCoolPeak - state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].DesCoolCoilInTempTU) > 2.0:
                    maxFlowCool = state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].DesCoolLoad / (cpAir * (state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].ZoneTempAtCoolPeak - state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].DesCoolCoilInTempTU))
                else:
                    maxFlowCool = state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].DesCoolLoad / (cpAir * 2.0)
                if minFlow * 3.0 >= maxFlowCool:
                    minFlow = maxFlowCool / 3.0
                var pltSizCoolNum: Int = MyPlantSizingIndex(state, "four pipe beam unit", self.name, self.cWInNodeNum, self.cWOutNodeNum, ErrorsFound)
                if pltSizCoolNum == 0:
                    ShowSevereError(state, "Autosizing of water flow requires a cooling loop Sizing:Plant object")
                    ShowContinueError(state, format("Occurs in {} Object={}", self.unitType, self.name))
                    ErrorsFound = True
                else:
                    self.cWTempIn = state.dataSize.PlantSizData[pltSizCoolNum].ExitTemp
                self.mDotHW = 0.0
                self.tDBZoneAirTemp = state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].ZoneTempAtCoolPeak
                self.tDBSystemAir = state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].DesCoolCoilInTempTU
                self.cpZoneAir = PsyCpAirFnW(state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].ZoneHumRatAtCoolPeak)
                self.cpSystemAir = PsyCpAirFnW(state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].DesCoolCoilInHumRatTU)
                self.qDotZoneReq = -1.0 * state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].DesCoolLoad
                self.qDotZoneToCoolSetPt = -1.0 * state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].DesCoolLoad
                self.airAvailable = True
                self.coolingAvailable = True
                self.heatingAvailable = False
                var f: fn(Float64) -> Float64 = fn(airFlow: Float64) -> Float64:
                    var routineName: StaticString = "Real64 HVACFourPipeBeam::residualSizing "
                    self.mDotSystemAir = airFlow
                    self.vDotDesignPrimAir = self.mDotSystemAir / state.dataEnvrn.StdRhoAir
                    self.totBeamLength = self.vDotDesignPrimAir / self.vDotNormRatedPrimAir
                    if self.vDotDesignCWWasAutosized:
                        self.vDotDesignCW = self.vDotNormRatedCW * self.totBeamLength
                        var rho: Float64 = self.cWplantLoc.loop.glycol.getDensity(state, Constant.CWInitConvTemp, routineName)
                        self.mDotNormRatedCW = self.vDotNormRatedCW * rho
                        self.mDotCW = self.vDotDesignCW * rho
                        if self.beamCoolingPresent:
                            InitComponentNodes(state, 0.0, self.mDotCW, self.cWInNodeNum, self.cWOutNodeNum)
                    if self.vDotDesignHWWasAutosized:
                        self.vDotDesignHW = self.vDotNormRatedHW * self.totBeamLength
                        var rho: Float64 = self.hWplantLoc.loop.glycol.getDensity(state, Constant.HWInitConvTemp, routineName)
                        self.mDotNormRatedHW = self.vDotNormRatedHW * rho
                        self.mDotHW = self.vDotDesignHW * rho
                        if self.beamHeatingPresent:
                            InitComponentNodes(state, 0.0, self.mDotHW, self.hWInNodeNum, self.hWOutNodeNum)
                    self.calc(state)
                    if self.qDotZoneReq != 0.0:
                        return ((self.qDotZoneReq - self.qDotTotalDelivered) / self.qDotZoneReq)
                    return 1.0
                var SolFlag: Int = 0
                SolveRoot(state, ErrTolerance, 50, SolFlag, mDotAirSolutionCooling, f, minFlow, maxFlowCool)
                if SolFlag == -1:
                    ShowWarningError(state, format("Cooling load sizing search failed in four pipe beam unit called {}", self.name))
                    ShowContinueError(state, "  Iteration limit exceeded in calculating size for design cooling load")
                elif SolFlag == -2:
                    ShowWarningError(state, format("Cooling load sizing search failed in four pipe beam unit called {}", self.name))
                    ShowContinueError(state, "  Bad size limits")
            if self.beamHeatingPresent:
                cpAir = PsyCpAirFnW(state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].DesHeatCoilInHumRatTU)
                var maxFlowHeat: Float64 = 0.0
                if (state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].DesHeatCoilInTempTU - state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].ZoneTempAtHeatPeak) > 2.0:
                    maxFlowHeat = state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].DesHeatLoad / (cpAir * (state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].DesHeatCoilInTempTU - state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].ZoneTempAtHeatPeak))
                else:
                    maxFlowHeat = state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].DesHeatLoad / (cpAir * 2.0)
                var pltSizHeatNum: Int = MyPlantSizingIndex(state, "four pipe beam unit", self.name, self.hWInNodeNum, self.hWOutNodeNum, ErrorsFound)
                if pltSizHeatNum == 0:
                    ShowSevereError(state, "Autosizing of water flow requires a heating loop Sizing:Plant object")
                    ShowContinueError(state, format("Occurs in {} Object={}", self.unitType, self.name))
                    ErrorsFound = True
                else:
                    self.hWTempIn = state.dataSize.PlantSizData[pltSizHeatNum].ExitTemp
                self.mDotCW = 0.0
                self.tDBZoneAirTemp = state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].ZoneTempAtHeatPeak
                self.tDBSystemAir = state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].DesHeatCoilInTempTU
                self.cpZoneAir = PsyCpAirFnW(state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].ZoneHumRatAtHeatPeak)
                self.cpSystemAir = PsyCpAirFnW(state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].DesHeatCoilInHumRatTU)
                self.qDotZoneReq = state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].DesHeatLoad
                self.qDotZoneToHeatSetPt = state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].DesHeatLoad
                self.airAvailable = True
                self.heatingAvailable = True
                self.coolingAvailable = False
                var f: fn(Float64) -> Float64 = fn(airFlow: Float64) -> Float64:
                    var routineName: StaticString = "Real64 HVACFourPipeBeam::residualSizing "
                    self.mDotSystemAir = airFlow
                    self.vDotDesignPrimAir = self.mDotSystemAir / state.dataEnvrn.StdRhoAir
                    self.totBeamLength = self.vDotDesignPrimAir / self.vDotNormRatedPrimAir
                    if self.vDotDesignCWWasAutosized:
                        self.vDotDesignCW = self.vDotNormRatedCW * self.totBeamLength
                        var rho: Float64 = self.cWplantLoc.loop.glycol.getDensity(state, Constant.CWInitConvTemp, routineName)
                        self.mDotNormRatedCW = self.vDotNormRatedCW * rho
                        self.mDotCW = self.vDotDesignCW * rho
                        if self.beamCoolingPresent:
                            InitComponentNodes(state, 0.0, self.mDotCW, self.cWInNodeNum, self.cWOutNodeNum)
                    if self.vDotDesignHWWasAutosized:
                        self.vDotDesignHW = self.vDotNormRatedHW * self.totBeamLength
                        var rho: Float64 = self.hWplantLoc.loop.glycol.getDensity(state, Constant.HWInitConvTemp, routineName)
                        self.mDotNormRatedHW = self.vDotNormRatedHW * rho
                        self.mDotHW = self.vDotDesignHW * rho
                        if self.beamHeatingPresent:
                            InitComponentNodes(state, 0.0, self.mDotHW, self.hWInNodeNum, self.hWOutNodeNum)
                    self.calc(state)
                    if self.qDotZoneReq != 0.0:
                        return ((self.qDotZoneReq - self.qDotTotalDelivered) / self.qDotZoneReq)
                    return 1.0
                var SolFlag: Int = 0
                SolveRoot(state, ErrTolerance, 50, SolFlag, mDotAirSolutionHeating, f, 0.0, maxFlowHeat)
                if SolFlag == -1:
                    ShowWarningError(state, format("Heating load sizing search failed in four pipe beam unit called {}", self.name))
                    ShowContinueError(state, "  Iteration limit exceeded in calculating size for design heating load")
                elif SolFlag == -2:
                    ShowWarningError(state, format("Heating load sizing search failed in four pipe beam unit called {}", self.name))
                    ShowContinueError(state, "  Bad size limits")
            self.mDotDesignPrimAir = max(mDotAirSolutionHeating, mDotAirSolutionCooling)
            self.mDotDesignPrimAir = max(self.mDotDesignPrimAir, state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].MinOA * state.dataEnvrn.StdRhoAir)
            self.vDotDesignPrimAir = self.mDotDesignPrimAir / state.dataEnvrn.StdRhoAir
            self.totBeamLength = self.vDotDesignPrimAir / self.vDotNormRatedPrimAir
            if self.vDotDesignCWWasAutosized:
                self.vDotDesignCW = self.vDotNormRatedCW * self.totBeamLength
            if self.vDotDesignHWWasAutosized:
                self.vDotDesignHW = self.vDotNormRatedHW * self.totBeamLength
        self.mDotDesignPrimAir = self.vDotDesignPrimAir * state.dataEnvrn.StdRhoAir
        if (originalTermUnitSizeMaxVDot > 0.0) and (originalTermUnitSizeMaxVDot != self.vDotDesignPrimAir) and (state.dataSize.CurZoneEqNum > 0):
            if (state.dataSize.SysSizingRunDone) and (self.airLoopNum > 0):
                state.dataSize.FinalSysSizing[self.airLoopNum].DesMainVolFlow += (self.vDotDesignPrimAir - originalTermUnitSizeMaxVDot)
                state.dataSize.FinalSysSizing[self.airLoopNum].DesCoolVolFlow += (self.vDotDesignPrimAir - originalTermUnitSizeCoolVDot)
                state.dataSize.FinalSysSizing[self.airLoopNum].DesHeatVolFlow += (self.vDotDesignPrimAir - originalTermUnitSizeHeatVDot)
                state.dataSize.FinalSysSizing[self.airLoopNum].MassFlowAtCoolPeak += (self.vDotDesignPrimAir - originalTermUnitSizeCoolVDot) * state.dataEnvrn.StdRhoAir
                BaseSizer.reportSizerOutput(state, self.unitType, self.name, "AirLoopHVAC Design Supply Air Flow Rate Adjustment [m3/s]", (self.vDotDesignPrimAir - originalTermUnitSizeMaxVDot))
            else:
                ShowSevereError(state, "Four pipe beam requires system sizing. Turn on system sizing.")
                ShowFatalError(state, "Program terminating due to previous errors")
        if self.beamCoolingPresent:
            rho = self.cWplantLoc.loop.glycol.getDensity(state, Constant.CWInitConvTemp, routineName)
            self.mDotNormRatedCW = self.vDotNormRatedCW * rho
            self.mDotDesignCW = self.vDotDesignCW * rho
            InitComponentNodes(state, 0.0, self.mDotDesignCW, self.cWInNodeNum, self.cWOutNodeNum)
        if self.beamHeatingPresent:
            rho = self.hWplantLoc.loop.glycol.getDensity(state, Constant.HWInitConvTemp, routineName)
            self.mDotNormRatedHW = self.vDotNormRatedHW * rho
            self.mDotDesignHW = self.vDotDesignHW * rho
            InitComponentNodes(state, 0.0, self.mDotDesignHW, self.hWInNodeNum, self.hWOutNodeNum)
        if self.vDotDesignPrimAirWasAutosized:
            BaseSizer.reportSizerOutput(state, self.unitType, self.name, "Supply Air Flow Rate [m3/s]", self.vDotDesignPrimAir)
        if self.vDotDesignCWWasAutosized:
            BaseSizer.reportSizerOutput(state, self.unitType, self.name, "Maximum Total Chilled Water Flow Rate [m3/s]", self.vDotDesignCW)
        if self.vDotDesignHWWasAutosized:
            BaseSizer.reportSizerOutput(state, self.unitType, self.name, "Maximum Total Hot Water Flow Rate [m3/s]", self.vDotDesignHW)
        if self.totBeamLengthWasAutosized:
            BaseSizer.reportSizerOutput(state, self.unitType, self.name, "Zone Total Beam Length [m]", self.totBeamLength)
        if self.vDotDesignCW > 0.0 and self.beamCoolingPresent:
            RegisterPlantCompDesignFlow(state, self.cWInNodeNum, self.vDotDesignCW)
            BaseSizer.calcCoilWaterFlowRates(state, self.name, self.unitType, self.vDotDesignCW, self.cWplantLoc.loopNum, state.dataSize.CurZoneEqNum, state.dataSize.CurSysNum, state.dataSize.CurOASysNum, state.dataSize.FinalZoneSizing, state.dataSize.FinalSysSizing)
        if self.vDotDesignHW > 0.0 and self.beamHeatingPresent:
            RegisterPlantCompDesignFlow(state, self.hWInNodeNum, self.vDotDesignHW)
            BaseSizer.calcCoilWaterFlowRates(state, self.name, self.unitType, self.vDotDesignHW, self.hWplantLoc.loopNum, state.dataSize.CurZoneEqNum, state.dataSize.CurSysNum, state.dataSize.CurOASysNum, state.dataSize.FinalZoneSizing, state.dataSize.FinalSysSizing)
        if ErrorsFound:
            ShowFatalError(state, "Preceding four pipe beam sizing errors cause program termination")

    def control(inout self, inout state: EnergyPlusData, FirstHVACIteration: Bool, inout NonAirSysOutput: Float64):
        using PlantUtilities.SetComponentFlowRate
        var SolFlag: Int
        var ErrTolerance: Float64
        NonAirSysOutput = 0.0
        if self.mDotSystemAir < VerySmallMassFlow or (not self.airAvailable and not self.coolingAvailable and not self.heatingAvailable):
            self.mDotHW = 0.0
            if self.beamHeatingPresent:
                SetComponentFlowRate(state, self.mDotHW, self.hWInNodeNum, self.hWOutNodeNum, self.hWplantLoc)
            self.hWTempOut = self.hWTempIn
            self.mDotCW = 0.0
            self.cWTempOut = self.cWTempIn
            if self.beamCoolingPresent:
                SetComponentFlowRate(state, self.mDotCW, self.cWInNodeNum, self.cWOutNodeNum, self.cWplantLoc)
            return
        if self.airAvailable and self.mDotSystemAir > VerySmallMassFlow and not self.coolingAvailable and not self.heatingAvailable:
            self.mDotHW = 0.0
            if self.beamHeatingPresent:
                SetComponentFlowRate(state, self.mDotHW, self.hWInNodeNum, self.hWOutNodeNum, self.hWplantLoc)
            self.hWTempOut = self.hWTempIn
            self.mDotCW = 0.0
            if self.beamCoolingPresent:
                SetComponentFlowRate(state, self.mDotCW, self.cWInNodeNum, self.cWOutNodeNum, self.cWplantLoc)
            self.cWTempOut = self.cWTempIn
            self.calc(state)
            return
        self.qDotZoneReq = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[self.zoneIndex].RemainingOutputRequired
        self.qDotZoneToHeatSetPt = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[self.zoneIndex].RemainingOutputReqToHeatSP
        self.qDotZoneToCoolSetPt = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[self.zoneIndex].RemainingOutputReqToCoolSP
        self.qDotSystemAir = self.mDotSystemAir * ((self.cpSystemAir * self.tDBSystemAir) - (self.cpZoneAir * self.tDBZoneAirTemp))
        self.qDotBeamReq = self.qDotZoneReq - self.qDotSystemAir
        if self.qDotBeamReq < -SmallLoad and self.coolingAvailable:
            self.mDotHW = 0.0
            if self.beamHeatingPresent:
                SetComponentFlowRate(state, self.mDotHW, self.hWInNodeNum, self.hWOutNodeNum, self.hWplantLoc)
            self.hWTempOut = self.hWTempIn
            self.mDotCW = self.mDotDesignCW
            self.calc(state)
            if self.qDotBeamCooling < (self.qDotBeamReq - SmallLoad):
                self.qDotBeamCoolingMax = self.qDotBeamCooling
                ErrTolerance = 0.01
                var f: fn(Float64) -> Float64 = fn(cWFlow: Float64) -> Float64:
                    self.mDotHW = 0.0
                    self.mDotCW = cWFlow
                    self.calc(state)
                    if self.qDotBeamCoolingMax != 0.0:
                        return (((self.qDotZoneToCoolSetPt - self.qDotSystemAir) - self.qDotBeamCooling) / self.qDotBeamCoolingMax)
                    return 1.0
                SolveRoot(state, ErrTolerance, 50, SolFlag, self.mDotCW, f, 0.0, self.mDotDesignCW)
                if SolFlag == -1:

                elif SolFlag == -2:

                self.calc(state)
                NonAirSysOutput = self.qDotBeamCooling
                return
            NonAirSysOutput = self.qDotBeamCooling
            return
        if self.qDotBeamReq > SmallLoad and self.heatingAvailable:
            self.mDotCW = 0.0
            if self.beamCoolingPresent:
                SetComponentFlowRate(state, self.mDotCW, self.cWInNodeNum, self.cWOutNodeNum, self.cWplantLoc)
            self.cWTempOut = self.cWTempIn
            self.mDotHW = self.mDotDesignHW
            self.calc(state)
            if self.qDotBeamHeating > (self.qDotBeamReq + SmallLoad):
                self.qDotBeamHeatingMax = self.qDotBeamHeating
                ErrTolerance = 0.01
                var f: fn(Float64) -> Float64 = fn(hWFlow: Float64) -> Float64:
                    self.mDotHW = hWFlow
                    self.mDotCW = 0.0
                    self.calc(state)
                    if self.qDotBeamHeatingMax != 0.0:
                        return (((self.qDotZoneToHeatSetPt - self.qDotSystemAir) - self.qDotBeamHeating) / self.qDotBeamHeatingMax)
                    return 1.0
                SolveRoot(state, ErrTolerance, 50, SolFlag, self.mDotHW, f, 0.0, self.mDotDesignHW)
                if SolFlag == -1:

                elif SolFlag == -2:

                self.calc(state)
                NonAirSysOutput = self.qDotBeamHeating
                return
            NonAirSysOutput = self.qDotBeamHeating
            return
        self.mDotHW = 0.0
        if self.beamHeatingPresent:
            SetComponentFlowRate(state, self.mDotHW, self.hWInNodeNum, self.hWOutNodeNum, self.hWplantLoc)
        self.hWTempOut = self.hWTempIn
        self.mDotCW = 0.0
        self.cWTempOut = self.cWTempIn
        if self.beamCoolingPresent:
            SetComponentFlowRate(state, self.mDotCW, self.cWInNodeNum, self.cWOutNodeNum, self.cWplantLoc)
        return

    def calc(inout self, inout state: EnergyPlusData):
        using PlantUtilities.SetComponentFlowRate
        var routineName: StaticString = "HVACFourPipeBeam::calc "
        var fModCoolCWMdot: Float64
        var fModCoolDeltaT: Float64
        var fModCoolAirMdot: Float64
        var fModHeatHWMdot: Float64
        var fModHeatDeltaT: Float64
        var fModHeatAirMdot: Float64
        var cp: Float64
        self.qDotBeamHeating = 0.0
        self.qDotBeamCooling = 0.0
        self.qDotSystemAir = self.mDotSystemAir * ((self.cpSystemAir * self.tDBSystemAir) - (self.cpZoneAir * self.tDBZoneAirTemp))
        if self.coolingAvailable and self.mDotCW > VerySmallMassFlow:
            SetComponentFlowRate(state, self.mDotCW, self.cWInNodeNum, self.cWOutNodeNum, self.cWplantLoc)
            fModCoolCWMdot = Curve.CurveValue(state, self.modCoolingQdotCWFlowFuncNum, ((self.mDotCW / self.totBeamLength) / self.mDotNormRatedCW))
            fModCoolDeltaT = Curve.CurveValue(state, self.modCoolingQdotDeltaTFuncNum, ((self.tDBZoneAirTemp - self.cWTempIn) / self.deltaTempRatedCooling))
            fModCoolAirMdot = Curve.CurveValue(state, self.modCoolingQdotAirFlowFuncNum, ((self.mDotSystemAir / self.totBeamLength) / self.mDotNormRatedPrimAir))
            self.qDotBeamCooling = -1.0 * self.qDotNormRatedCooling * fModCoolDeltaT * fModCoolAirMdot * fModCoolCWMdot * self.totBeamLength
            cp = self.cWplantLoc.loop.glycol.getSpecificHeat(state, self.cWTempIn, routineName)
            if self.mDotCW > 0.0:
                self.cWTempOut = self.cWTempIn - (self.qDotBeamCooling / (self.mDotCW * cp))
            else:
                self.cWTempOut = self.cWTempIn
            if self.cWTempOut > (max(self.tDBSystemAir, self.tDBZoneAirTemp) - 1.0):
                ShowRecurringWarningErrorAtEnd(state, String(routineName) + " four pipe beam name " + self.name + ", chilled water outlet temperature is too warm. Capacity was limited. check beam capacity input ", self.cWTempOutErrorCount, self.cWTempOut, self.cWTempOut)
                self.cWTempOut = (max(self.tDBSystemAir, self.tDBZoneAirTemp) - 1.0)
                self.qDotBeamCooling = self.mDotCW * cp * (self.cWTempIn - self.cWTempOut)
        else:
            self.mDotCW = 0.0
            if self.beamCoolingPresent:
                SetComponentFlowRate(state, self.mDotCW, self.cWInNodeNum, self.cWOutNodeNum, self.cWplantLoc)
            self.cWTempOut = self.cWTempIn
            self.qDotBeamCooling = 0.0
        if self.heatingAvailable and self.mDotHW > VerySmallMassFlow:
            SetComponentFlowRate(state, self.mDotHW, self.hWInNodeNum, self.hWOutNodeNum, self.hWplantLoc)
            fModHeatHWMdot = Curve.CurveValue(state, self.modHeatingQdotHWFlowFuncNum, ((self.mDotHW / self.totBeamLength) / self.mDotNormRatedHW))
            fModHeatDeltaT = Curve.CurveValue(state, self.modHeatingQdotDeltaTFuncNum, ((self.hWTempIn - self.tDBZoneAirTemp) / self.deltaTempRatedHeating))
            fModHeatAirMdot = Curve.CurveValue(state, self.modHeatingQdotAirFlowFuncNum, ((self.mDotSystemAir / self.totBeamLength) / self.mDotNormRatedPrimAir))
            self.qDotBeamHeating = self.qDotNormRatedHeating * fModHeatDeltaT * fModHeatAirMdot * fModHeatHWMdot * self.totBeamLength
            cp = self.hWplantLoc.loop.glycol.getSpecificHeat(state, self.hWTempIn, routineName)
            if self.mDotHW > 0.0:
                self.hWTempOut = self.hWTempIn - (self.qDotBeamHeating / (self.mDotHW * cp))
            else:
                self.hWTempOut = self.hWTempIn
            if self.hWTempOut < (min(self.tDBSystemAir, self.tDBZoneAirTemp) + 1.0):
                ShowRecurringWarningErrorAtEnd(state, String(routineName) + " four pipe beam name " + self.name + ", hot water outlet temperature is too cool. Capacity was limited. check beam capacity input ", self.hWTempOutErrorCount, self.hWTempOut, self.hWTempOut)
                self.hWTempOut = (min(self.tDBSystemAir, self.tDBZoneAirTemp) + 1.0)
                self.qDotBeamHeating = self.mDotHW * cp * (self.hWTempIn - self.hWTempOut)
        else:
            self.mDotHW = 0.0
            if self.beamHeatingPresent:
                SetComponentFlowRate(state, self.mDotHW, self.hWInNodeNum, self.hWOutNodeNum, self.hWplantLoc)
            self.hWTempOut = self.hWTempIn
            self.qDotBeamHeating = 0.0
        self.qDotTotalDelivered = self.qDotSystemAir + self.qDotBeamCooling + self.qDotBeamHeating

    def update(inout self, inout state: EnergyPlusData):
        var Node_fn = state.dataLoopNodes.Node
        using PlantUtilities.SafeCopyPlantNode
        Node_fn[self.airOutNodeNum].MassFlowRate = Node_fn[self.airInNodeNum].MassFlowRate
        Node_fn[self.airOutNodeNum].Temp = Node_fn[self.airInNodeNum].Temp
        Node_fn[self.airOutNodeNum].HumRat = Node_fn[self.airInNodeNum].HumRat
        Node_fn[self.airOutNodeNum].Enthalpy = Node_fn[self.airInNodeNum].Enthalpy
        Node_fn[self.airOutNodeNum].Quality = Node_fn[self.airInNodeNum].Quality
        Node_fn[self.airOutNodeNum].Press = Node_fn[self.airInNodeNum].Press
        Node_fn[self.airOutNodeNum].MassFlowRateMin = Node_fn[self.airInNodeNum].MassFlowRateMin
        Node_fn[self.airOutNodeNum].MassFlowRateMax = Node_fn[self.airInNodeNum].MassFlowRateMax
        Node_fn[self.airOutNodeNum].MassFlowRateMinAvail = Node_fn[self.airInNodeNum].MassFlowRateMinAvail
        Node_fn[self.airOutNodeNum].MassFlowRateMaxAvail = Node_fn[self.airInNodeNum].MassFlowRateMaxAvail
        if state.dataContaminantBalance.Contaminant.CO2Simulation:
            Node_fn[self.airOutNodeNum].CO2 = Node_fn[self.airInNodeNum].CO2
        if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
            Node_fn[self.airOutNodeNum].GenContam = Node_fn[self.airInNodeNum].GenContam
        if self.beamCoolingPresent:
            SafeCopyPlantNode(state, self.cWInNodeNum, self.cWOutNodeNum)
            Node_fn[self.cWOutNodeNum].Temp = self.cWTempOut
        if self.beamHeatingPresent:
            SafeCopyPlantNode(state, self.hWInNodeNum, self.hWOutNodeNum)
            Node_fn[self.hWOutNodeNum].Temp = self.hWTempOut

    def report(inout self, inout state: EnergyPlusData):
        var ReportingConstant: Float64
        ReportingConstant = state.dataHVACGlobal.TimeStepSysSec
        if self.beamCoolingPresent:
            self.beamCoolingRate = abs(self.qDotBeamCooling)
            self.beamCoolingEnergy = self.beamCoolingRate * ReportingConstant
        if self.beamHeatingPresent:
            self.beamHeatingRate = self.qDotBeamHeating
            self.beamHeatingEnergy = self.beamHeatingRate * ReportingConstant
        if self.qDotSystemAir <= 0.0:
            self.supAirCoolingRate = abs(self.qDotSystemAir)
            self.supAirHeatingRate = 0.0
        else:
            self.supAirHeatingRate = self.qDotSystemAir
            self.supAirCoolingRate = 0.0
        self.supAirCoolingEnergy = self.supAirCoolingRate * ReportingConstant
        self.supAirHeatingEnergy = self.supAirHeatingRate * ReportingConstant
        self.primAirFlow = self.mDotSystemAir / state.dataEnvrn.StdRhoAir
        self.CalcOutdoorAirVolumeFlowRate(state)

    def CalcOutdoorAirVolumeFlowRate(inout self, inout state: EnergyPlusData):
        if self.airLoopNum > 0:
            self.OutdoorAirFlowRate = (state.dataLoopNodes.Node[self.airOutNodeNum].MassFlowRate / state.dataEnvrn.StdRhoAir) * state.dataAirLoop.AirLoopFlow[self.airLoopNum].OAFrac
        else:
            self.OutdoorAirFlowRate = 0.0

    def reportTerminalUnit(inout self, inout state: EnergyPlusData):
        var orp = state.dataOutRptPredefined
        var adu = state.dataDefineEquipment.AirDistUnit[self.aDUNum - 1]
        if not state.dataSize.TermUnitFinalZoneSizing.empty():
            var sizing = state.dataSize.TermUnitFinalZoneSizing[adu.TermUnitSizingNum]
            PreDefTableEntry(state, orp.pdchAirTermMinFlow, adu.Name, sizing.DesCoolVolFlowMin)
            PreDefTableEntry(state, orp.pdchAirTermMinOutdoorFlow, adu.Name, sizing.MinOA)
            PreDefTableEntry(state, orp.pdchAirTermSupCoolingSP, adu.Name, sizing.CoolDesTemp)
            PreDefTableEntry(state, orp.pdchAirTermSupHeatingSP, adu.Name, sizing.HeatDesTemp)
            PreDefTableEntry(state, orp.pdchAirTermHeatingCap, adu.Name, sizing.DesHeatLoad)
            PreDefTableEntry(state, orp.pdchAirTermCoolingCap, adu.Name, sizing.DesCoolLoad)
        PreDefTableEntry(state, orp.pdchAirTermTypeInp, adu.Name, "AirTerminal:SingleDuct:ConstantVolume:FourPipeBeam")
        PreDefTableEntry(state, orp.pdchAirTermPrimFlow, adu.Name, self.vDotNormRatedPrimAir)
        PreDefTableEntry(state, orp.pdchAirTermSecdFlow, adu.Name, "n/a")
        PreDefTableEntry(state, orp.pdchAirTermMinFlowSch, adu.Name, "n/a")
        PreDefTableEntry(state, orp.pdchAirTermMaxFlowReh, adu.Name, "n/a")
        PreDefTableEntry(state, orp.pdchAirTermMinOAflowSch, adu.Name, "n/a")
        if self.beamHeatingPresent:
            PreDefTableEntry(state, orp.pdchAirTermHeatCoilType, adu.Name, "Included")
        else:
            PreDefTableEntry(state, orp.pdchAirTermHeatCoilType, adu.Name, "None")
        if self.beamCoolingPresent:
            PreDefTableEntry(state, orp.pdchAirTermCoolCoilType, adu.Name, "Included")
        else:
            PreDefTableEntry(state, orp.pdchAirTermCoolCoilType, adu.Name, "None")
        PreDefTableEntry(state, orp.pdchAirTermFanType, adu.Name, "n/a")
        PreDefTableEntry(state, orp.pdchAirTermFanName, adu.Name, "n/a")

struct FourPipeBeamData(BaseGlobalStruct):
    var FourPipeBeams: Array1D[shared_ptr[HVACFourPipeBeam]] = Array1D[shared_ptr[HVACFourPipeBeam]]()

    def init_constant_state(inout self, state: EnergyPlusData):

    def init_state(inout self, state: EnergyPlusData):

    def clear_state(inout self):
        self.FourPipeBeams.clear()