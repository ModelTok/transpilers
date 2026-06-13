# Mojo translation of src/EnergyPlus/HVACStandAloneERV.cc

from math import fabs, abs
from memory import UnsafePointer
from sys import int
from typing import StringRef, Bool, Float64, Int

from ObjexxFCL.Array import Array1D_bool, Array1D_string, Array1D_Float64, Array1D_Real64, dimension, allocate, deallocate
from ObjexxFCL.Fmath import min, max
from ObjexxFCL.Array.functions import allocated
from .Data.EnergyPlusData import EnergyPlusData
from .Data.EnergyPlusData import state as state_type
from .DataGlobals import DataGlobals
from .EnergyPlus import *
from .Autosizing.SystemAirFlowSizing import SystemAirFlowSizer
from BranchNodeConnections import *
from CurveManager import Curve
from DataEnvironment import *
from DataHVACGlobals import *
from DataHeatBalance import *
from .DataLoopNode import *
from DataSizing import *
from .DataZoneControls import *
from DataZoneEquipment import *
from Fans import *
from General import *
from GeneralRoutines import *
from GlobalNames import *
from HeatRecovery import *
from .InputProcessing.InputProcessor import InputProcessor
from MixedAir import *
from NodeInputManager import *
from OutAirNodeManager import OutAirNodeManager
from OutputProcessor import *
from OutputReportPredefined import OutputReportPredefined
from ScheduleManager import Sched
from UtilityRoutines import Util, ShowFatalError, ShowSevereError, ShowContinueError, ShowWarningError, ShowContinueErrorTimeStamp, ShowMessage

from .HVACStandAloneERV.hh import StandAloneERVData, HVACStandAloneERVData
from .HVACStandAloneERV.hh import SimStandAloneERV, GetStandAloneERV, InitStandAloneERV, SizeStandAloneERV, CalcStandAloneERV, ReportStandAloneERV
from .HVACStandAloneERV.hh import GetSupplyAirFlowRate, GetStandAloneERVOutAirNode, GetStandAloneERVZoneInletAirNode, GetStandAloneERVReturnAirNode, GetStandAloneERVNodeNumber, getEqIndex

def SimStandAloneERV(
    state: EnergyPlusData,
    CompName: StringRef,
    ZoneNum: Int,
    FirstHVACIteration: Bool,
    SensLoadMet: Float64,
    LatLoadMet: Float64,
    CompIndex: Int
):
    var StandAloneERVNum: Int
    if state.dataHVACStandAloneERV.GetERVInputFlag:
        GetStandAloneERV(state)
        state.dataHVACStandAloneERV.GetERVInputFlag = False
    if CompIndex == 0:
        StandAloneERVNum = Util.FindItem(CompName, state.dataHVACStandAloneERV.StandAloneERV)
        if StandAloneERVNum == 0:
            ShowFatalError(state, String("SimStandAloneERV: Unit not found={}").format(CompName))
        CompIndex = StandAloneERVNum
    else:
        StandAloneERVNum = CompIndex
        if StandAloneERVNum > state.dataHVACStandAloneERV.NumStandAloneERVs or StandAloneERVNum < 1:
            ShowFatalError(state, String("SimStandAloneERV:  Invalid CompIndex passed={}, Number of Units={}, Entered Unit name={}").format(StandAloneERVNum, state.dataHVACStandAloneERV.NumStandAloneERVs, CompName))
        if state.dataHVACStandAloneERV.CheckEquipName[StandAloneERVNum]:
            if CompName != state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].Name:
                ShowFatalError(state, String("SimStandAloneERV: Invalid CompIndex passed={}, Unit name={}, stored Unit Name for that index={}").format(StandAloneERVNum, CompName, state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].Name))
            state.dataHVACStandAloneERV.CheckEquipName[StandAloneERVNum] = False
    InitStandAloneERV(state, StandAloneERVNum, ZoneNum, FirstHVACIteration)
    CalcStandAloneERV(state, StandAloneERVNum, FirstHVACIteration, SensLoadMet, LatLoadMet)
    ReportStandAloneERV(state, StandAloneERVNum)

def GetStandAloneERV(state: EnergyPlusData):
    var routineName: StringRef = "GetStandAloneERV"
    var Alphas: Array1D_string
    var Numbers: Array1D_Float64
    var cAlphaFields: Array1D_string
    var cNumericFields: Array1D_string
    var lAlphaBlanks: Array1D_bool
    var lNumericBlanks: Array1D_bool
    var NumArg: Int
    var NumAlphas: Int
    var NumNumbers: Int
    var IOStatus: Int
    var ErrorsFound: Bool = False
    var NumERVCtrlrs: Int
    var ERVControllerNum: Int
    var AirFlowRate: Float64
    var NodeNumber: Int
    var HStatZoneNum: Int
    var NumHstatZone: Int
    var HXSupAirFlowRate: Float64
    var ZoneInletCZN: Int
    var ZoneExhaustCZN: Int
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, "ZoneHVAC:EnergyRecoveryVentilator", NumArg, NumAlphas, NumNumbers)
    var MaxAlphas: Int = NumAlphas
    var MaxNumbers: Int = NumNumbers
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, "ZoneHVAC:EnergyRecoveryVentilator:Controller", NumArg, NumAlphas, NumNumbers)
    MaxAlphas = max(MaxAlphas, NumAlphas)
    MaxNumbers = max(MaxNumbers, NumNumbers)
    Alphas.allocate(MaxAlphas)
    Numbers.dimension(MaxNumbers, 0.0)
    cAlphaFields.allocate(MaxAlphas)
    cNumericFields.allocate(MaxNumbers)
    lNumericBlanks.dimension(MaxNumbers, False)
    lAlphaBlanks.dimension(MaxAlphas, False)
    state.dataHVACStandAloneERV.GetERVInputFlag = False
    var CurrentModuleObject: StringRef = "ZoneHVAC:EnergyRecoveryVentilator"
    state.dataHVACStandAloneERV.NumStandAloneERVs = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, CurrentModuleObject)
    state.dataHVACStandAloneERV.StandAloneERV.allocate(state.dataHVACStandAloneERV.NumStandAloneERVs)
    state.dataHVACStandAloneERV.HeatExchangerUniqueNames.reserve(static_cast[UInt](state.dataHVACStandAloneERV.NumStandAloneERVs))
    state.dataHVACStandAloneERV.SupplyAirFanUniqueNames.reserve(static_cast[UInt](state.dataHVACStandAloneERV.NumStandAloneERVs))
    state.dataHVACStandAloneERV.ExhaustAirFanUniqueNames.reserve(static_cast[UInt](state.dataHVACStandAloneERV.NumStandAloneERVs))
    state.dataHVACStandAloneERV.ControllerUniqueNames.reserve(static_cast[UInt](state.dataHVACStandAloneERV.NumStandAloneERVs))
    state.dataHVACStandAloneERV.CheckEquipName.dimension(state.dataHVACStandAloneERV.NumStandAloneERVs, True)
    for StandAloneERVIndex in range(1, state.dataHVACStandAloneERV.NumStandAloneERVs + 1):
        var standAloneERV = state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVIndex]
        state.dataInputProcessing.inputProcessor.getObjectItem(state, CurrentModuleObject, StandAloneERVIndex, Alphas, NumAlphas, Numbers, NumNumbers, IOStatus, lNumericBlanks, lAlphaBlanks, cAlphaFields, cNumericFields)
        standAloneERV.Name = Alphas[1]
        standAloneERV.UnitType = CurrentModuleObject
        var eoh: ErrorObjectHeader = ErrorObjectHeader(routineName, CurrentModuleObject, standAloneERV.Name)
        if lAlphaBlanks[2]:
            standAloneERV.availSched = Sched.GetScheduleAlwaysOn(state)
        elif (standAloneERV.availSched = Sched.GetSchedule(state, Alphas[2])) == None:
            ShowSevereItemNotFound(state, eoh, cAlphaFields[2], Alphas[2])
            ErrorsFound = True
        GlobalNames.IntraObjUniquenessCheck(state, Alphas[3], CurrentModuleObject, cAlphaFields[3], state.dataHVACStandAloneERV.HeatExchangerUniqueNames, ErrorsFound)
        standAloneERV.HeatExchangerName = Alphas[3]
        var errFlag: Bool = False
        standAloneERV.hxType = HeatRecovery.GetHeatExchangerObjectTypeNum(state, standAloneERV.HeatExchangerName, standAloneERV.HeatExchangerIndex, errFlag)
        if errFlag:
            ShowContinueError(state, String("... occurs in {} \"{}\"").format(CurrentModuleObject, standAloneERV.Name))
            ErrorsFound = True
        errFlag = False
        HXSupAirFlowRate = HeatRecovery.GetSupplyAirFlowRate(state, standAloneERV.HeatExchangerName, errFlag)
        if errFlag:
            ShowContinueError(state, String("... occurs in {} \"{}\"").format(CurrentModuleObject, standAloneERV.Name))
            ErrorsFound = True
        standAloneERV.DesignHXVolFlowRate = HXSupAirFlowRate
        standAloneERV.SupplyAirFanName = Alphas[4]
        GlobalNames.IntraObjUniquenessCheck(state, Alphas[4], CurrentModuleObject, cAlphaFields[4], state.dataHVACStandAloneERV.SupplyAirFanUniqueNames, ErrorsFound)
        if (standAloneERV.SupplyAirFanIndex = Fans.GetFanIndex(state, standAloneERV.SupplyAirFanName)) == 0:
            ShowSevereItemNotFound(state, eoh, cAlphaFields[4], standAloneERV.SupplyAirFanName)
            ErrorsFound = True
        else:
            var fan = state.dataFans.fans[standAloneERV.SupplyAirFanIndex]
            standAloneERV.supplyAirFanType = fan.type
            standAloneERV.supplyAirFanSched = fan.availSched
            standAloneERV.DesignSAFanVolFlowRate = fan.maxAirFlowRate
            standAloneERV.SupplyAirOutletNode = fan.outletNodeNum
        standAloneERV.ExhaustAirFanName = Alphas[5]
        GlobalNames.IntraObjUniquenessCheck(state, Alphas[5], CurrentModuleObject, cAlphaFields[5], state.dataHVACStandAloneERV.ExhaustAirFanUniqueNames, ErrorsFound)
        if (standAloneERV.ExhaustAirFanIndex = Fans.GetFanIndex(state, standAloneERV.ExhaustAirFanName)) == 0:
            ShowSevereItemNotFound(state, eoh, cAlphaFields[5], standAloneERV.ExhaustAirFanName)
            ErrorsFound = True
        else:
            var fan = state.dataFans.fans[standAloneERV.ExhaustAirFanIndex]
            standAloneERV.exhaustAirFanType = fan.type
            standAloneERV.exhaustAirFanSched = fan.availSched
            standAloneERV.DesignEAFanVolFlowRate = fan.maxAirFlowRate
            standAloneERV.ExhaustAirOutletNode = fan.outletNodeNum
        errFlag = False
        standAloneERV.SupplyAirInletNode = HeatRecovery.GetSupplyInletNode(state, standAloneERV.HeatExchangerName, errFlag)
        standAloneERV.ExhaustAirInletNode = HeatRecovery.GetSecondaryInletNode(state, standAloneERV.HeatExchangerName, errFlag)
        if errFlag:
            ShowContinueError(state, String("... occurs in {} ={}").format(CurrentModuleObject, standAloneERV.Name))
            ErrorsFound = True
        standAloneERV.SupplyAirInletNode = GetOnlySingleNode(state, state.dataLoopNodes.NodeID[standAloneERV.SupplyAirInletNode], ErrorsFound, Node.ConnectionObjectType.ZoneHVACEnergyRecoveryVentilator, Alphas[1], Node.FluidType.Air, Node.ConnectionType.Inlet, Node.CompFluidStream.Primary, Node.ObjectIsParent)
        standAloneERV.SupplyAirOutletNode = GetOnlySingleNode(state, state.dataLoopNodes.NodeID[standAloneERV.SupplyAirOutletNode], ErrorsFound, Node.ConnectionObjectType.ZoneHVACEnergyRecoveryVentilator, Alphas[1], Node.FluidType.Air, Node.ConnectionType.Outlet, Node.CompFluidStream.Primary, Node.ObjectIsParent)
        standAloneERV.ExhaustAirInletNode = GetOnlySingleNode(state, state.dataLoopNodes.NodeID[standAloneERV.ExhaustAirInletNode], ErrorsFound, Node.ConnectionObjectType.ZoneHVACEnergyRecoveryVentilator, Alphas[1], Node.FluidType.Air, Node.ConnectionType.Inlet, Node.CompFluidStream.Secondary, Node.ObjectIsParent)
        standAloneERV.ExhaustAirOutletNode = GetOnlySingleNode(state, state.dataLoopNodes.NodeID[standAloneERV.ExhaustAirOutletNode], ErrorsFound, Node.ConnectionObjectType.ZoneHVACEnergyRecoveryVentilator, Alphas[1], Node.FluidType.Air, Node.ConnectionType.ReliefAir, Node.CompFluidStream.Secondary, Node.ObjectIsParent)
        if not OutAirNodeManager.CheckOutAirNodeNumber(state, standAloneERV.SupplyAirInletNode):
            ShowSevereError(state, String("For {} \"{}\"").format(CurrentModuleObject, standAloneERV.Name))
            ShowContinueError(state, String(" Node name of supply air inlet node not valid Outdoor Air Node = {}").format(state.dataLoopNodes.NodeID[standAloneERV.SupplyAirInletNode]))
            ShowContinueError(state, "...does not appear in an OutdoorAir:NodeList or as an OutdoorAir:Node.")
            ErrorsFound = True
        var ZoneInletNodeFound: Bool = False
        var ZoneExhaustNodeFound: Bool = False
        for ControlledZoneNum in range(1, state.dataGlobal.NumOfZones + 1):
            if not ZoneInletNodeFound:
                for NodeNumber in range(1, state.dataZoneEquip.ZoneEquipConfig[ControlledZoneNum].NumInletNodes + 1):
                    if state.dataZoneEquip.ZoneEquipConfig[ControlledZoneNum].InletNode[NodeNumber] == standAloneERV.SupplyAirOutletNode:
                        ZoneInletNodeFound = True
                        ZoneInletCZN = ControlledZoneNum
                        break
            if not ZoneExhaustNodeFound:
                for NodeNumber in range(1, state.dataZoneEquip.ZoneEquipConfig[ControlledZoneNum].NumExhaustNodes + 1):
                    if state.dataZoneEquip.ZoneEquipConfig[ControlledZoneNum].ExhaustNode[NodeNumber] == standAloneERV.ExhaustAirInletNode:
                        ZoneExhaustNodeFound = True
                        ZoneExhaustCZN = ControlledZoneNum
                        break
        if not ZoneInletNodeFound:
            ShowSevereError(state, String("For {} \"{}\"").format(CurrentModuleObject, standAloneERV.Name))
            ShowContinueError(state, "... Node name of supply air outlet node does not appear in a ZoneHVAC:EquipmentConnections object.")
            ShowContinueError(state, String("... Supply air outlet node = {}").format(state.dataLoopNodes.NodeID[standAloneERV.SupplyAirOutletNode]))
            ErrorsFound = True
        if not ZoneExhaustNodeFound:
            ShowSevereError(state, String("For {} \"{}\"").format(CurrentModuleObject, standAloneERV.Name))
            ShowContinueError(state, "... Node name of exhaust air inlet node does not appear in a ZoneHVAC:EquipmentConnections object.")
            ShowContinueError(state, String("... Exhaust air inlet node = {}").format(state.dataLoopNodes.NodeID[standAloneERV.ExhaustAirInletNode]))
            ErrorsFound = True
        if ZoneInletNodeFound and ZoneExhaustNodeFound:
            if ZoneInletCZN != ZoneExhaustCZN:
                ShowSevereError(state, String("For {} \"{}\"").format(CurrentModuleObject, standAloneERV.Name))
                ShowContinueError(state, "... Node name of supply air outlet node and exhasut air inlet node must appear in the same ZoneHVAC:EquipmentConnections object.")
                ShowContinueError(state, String("... Supply air outlet node = {}").format(state.dataLoopNodes.NodeID[standAloneERV.SupplyAirOutletNode]))
                ShowContinueError(state, String("... ZoneHVAC:EquipmentConnections Zone Name = {}").format(state.dataZoneEquip.ZoneEquipConfig[ZoneInletCZN].ZoneName))
                ShowContinueError(state, String("... Exhaust air inlet node = {}").format(state.dataLoopNodes.NodeID[standAloneERV.ExhaustAirInletNode]))
                ShowContinueError(state, String("... ZoneHVAC:EquipmentConnections Zone Name = {}").format(state.dataZoneEquip.ZoneEquipConfig[ZoneExhaustCZN].ZoneName))
                ErrorsFound = True
        standAloneERV.ControllerName = Alphas[6]
        if lAlphaBlanks[6]:
            standAloneERV.ControllerName = "xxxxx"
            standAloneERV.ControllerNameDefined = False
        else:
            GlobalNames.IntraObjUniquenessCheck(state, Alphas[6], CurrentModuleObject, cAlphaFields[6], state.dataHVACStandAloneERV.ControllerUniqueNames, ErrorsFound)
            standAloneERV.ControllerNameDefined = True
            if ErrorsFound:
                standAloneERV.ControllerNameDefined = False
            if state.dataInputProcessing.inputProcessor.getObjectItemNum(state, "ZoneHVAC:EnergyRecoveryVentilator:Controller", standAloneERV.ControllerName) <= 0:
                ShowSevereError(state, String("{} controller type ZoneHVAC:EnergyRecoveryVentilator:Controller not found = {}").format(CurrentModuleObject, Alphas[6]))
                ErrorsFound = True
                standAloneERV.ControllerNameDefined = False
            else:
                state.dataHeatRecovery.ExchCond[standAloneERV.HeatExchangerIndex].hasZoneERVController = True
                OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchAirHROAControllerName, standAloneERV.HeatExchangerName, standAloneERV.ControllerName)
        if not lAlphaBlanks[7]:
            standAloneERV.AvailManagerListName = Alphas[7]
        standAloneERV.SupplyAirVolFlow = Numbers[1]
        standAloneERV.ExhaustAirVolFlow = Numbers[2]
        standAloneERV.AirVolFlowPerFloorArea = Numbers[3]
        standAloneERV.AirVolFlowPerOccupant = Numbers[4]
        if standAloneERV.SupplyAirVolFlow == DataSizing.AutoSize and standAloneERV.DesignSAFanVolFlowRate != DataSizing.AutoSize:
            ShowSevereError(state, String("{} \"{}\"").format(CurrentModuleObject, standAloneERV.Name))
            ShowContinueError(state, String("... When autosizing ERV, supply air fan = {} \"{}\" must also be autosized.").format(HVAC.fanTypeNames[int(standAloneERV.supplyAirFanType)], standAloneERV.SupplyAirFanName))
        if standAloneERV.ExhaustAirVolFlow == DataSizing.AutoSize and standAloneERV.DesignEAFanVolFlowRate != DataSizing.AutoSize:
            ShowSevereError(state, String("{} \"{}\"").format(CurrentModuleObject, standAloneERV.Name))
            ShowContinueError(state, String("... When autosizing ERV, exhaust air fan = {} \"{}\" must also be autosized.").format(HVAC.fanTypeNames[int(standAloneERV.exhaustAirFanType)], standAloneERV.ExhaustAirFanName))
        if standAloneERV.SupplyAirVolFlow == DataSizing.AutoSize and HXSupAirFlowRate != DataSizing.AutoSize:
            ShowSevereError(state, String("{} \"{}\"").format(CurrentModuleObject, standAloneERV.Name))
            ShowContinueError(state, String("... When autosizing ERV {}, nominal supply air flow rate for heat exchanger with name = {} must also be autosized.").format(cNumericFields[1], standAloneERV.HeatExchangerName))
        if standAloneERV.ExhaustAirVolFlow == DataSizing.AutoSize and HXSupAirFlowRate != DataSizing.AutoSize:
            ShowSevereError(state, String("{} \"{}\"").format(CurrentModuleObject, standAloneERV.Name))
            ShowContinueError(state, String("... When autosizing ERV {}, nominal supply air flow rate for heat exchanger with name = {} must also be autosized.").format(cNumericFields[2], standAloneERV.HeatExchangerName))
        if standAloneERV.DesignSAFanVolFlowRate != DataSizing.AutoSize and standAloneERV.SupplyAirVolFlow != DataSizing.AutoSize:
            if standAloneERV.SupplyAirVolFlow > standAloneERV.DesignSAFanVolFlowRate:
                ShowWarningError(state, String("{} = {} has a {} > Max Volume Flow Rate defined in the associated fan object, should be <=").format(CurrentModuleObject, standAloneERV.Name, cNumericFields[1]))
                ShowContinueError(state, String("... Entered value={:.2f}... Fan [{} \"{}\"] Max Value = {:.2f}").format(standAloneERV.SupplyAirVolFlow, HVAC.fanTypeNames[int(standAloneERV.supplyAirFanType)], standAloneERV.SupplyAirFanName, standAloneERV.DesignSAFanVolFlowRate))
                ShowContinueError(state, String(" The ERV {} is reset to the supply air fan flow rate and the simulation continues.").format(cNumericFields[1]))
                standAloneERV.SupplyAirVolFlow = standAloneERV.DesignSAFanVolFlowRate
        if standAloneERV.SupplyAirVolFlow != DataSizing.AutoSize:
            if standAloneERV.SupplyAirVolFlow <= 0.0:
                ShowSevereError(state, String("{} = {} has a {} <= 0.0, it must be >0.0").format(CurrentModuleObject, standAloneERV.Name, cNumericFields[1]))
                ShowContinueError(state, String("... Entered value={:.2f}").format(standAloneERV.SupplyAirVolFlow))
                ErrorsFound = True
        else:
            if standAloneERV.AirVolFlowPerFloorArea == 0.0 and standAloneERV.AirVolFlowPerOccupant == 0.0:
                ShowSevereError(state, String("{} \"{}\"").format(CurrentModuleObject, standAloneERV.Name))
                ShowContinueError(state, String("... Autosizing {} requires at least one input for {} or {}.").format(cNumericFields[1], cNumericFields[3], cNumericFields[4]))
                ErrorsFound = True
            if standAloneERV.ExhaustAirVolFlow != DataSizing.AutoSize:
                ShowSevereError(state, String("{} \"{}\"").format(CurrentModuleObject, standAloneERV.Name))
                ShowContinueError(state, String("... When autosizing, {} and {} must both be autosized.").format(cNumericFields[1], cNumericFields[2]))
                ErrorsFound = True
        if standAloneERV.DesignEAFanVolFlowRate != DataSizing.AutoSize and standAloneERV.ExhaustAirVolFlow != DataSizing.AutoSize:
            if standAloneERV.ExhaustAirVolFlow > standAloneERV.DesignEAFanVolFlowRate:
                ShowWarningError(state, String("{} = {} has an {} > Max Volume Flow Rate defined in the associated fan object, should be <=").format(CurrentModuleObject, standAloneERV.Name, cNumericFields[2]))
                ShowContinueError(state, String("... Entered value={:.2f}... Fan [{}:{}] Max Value = {:.2f}").format(standAloneERV.ExhaustAirVolFlow, HVAC.fanTypeNames[int(standAloneERV.exhaustAirFanType)], standAloneERV.ExhaustAirFanName, standAloneERV.DesignEAFanVolFlowRate))
                ShowContinueError(state, String(" The ERV {} is reset to the exhaust air fan flow rate and the simulation continues.").format(cNumericFields[2]))
                standAloneERV.ExhaustAirVolFlow = standAloneERV.DesignEAFanVolFlowRate
        if standAloneERV.ExhaustAirVolFlow != DataSizing.AutoSize:
            if standAloneERV.ExhaustAirVolFlow <= 0.0:
                ShowSevereError(state, String("{} = {} has an {} <= 0.0, it must be >0.0").format(CurrentModuleObject, standAloneERV.Name, cNumericFields[2]))
                ShowContinueError(state, String("... Entered value={:.2f}").format(standAloneERV.ExhaustAirVolFlow))
                ErrorsFound = True
        else:
            if standAloneERV.AirVolFlowPerFloorArea == 0.0 and standAloneERV.AirVolFlowPerOccupant == 0.0:
                ShowSevereError(state, String("{} \"{}\"").format(CurrentModuleObject, standAloneERV.Name))
                ShowContinueError(state, String("... Autosizing {} requires at least one input for {} or {}.").format(cNumericFields[2], cNumericFields[3], cNumericFields[4]))
                ErrorsFound = True
            if standAloneERV.SupplyAirVolFlow != DataSizing.AutoSize:
                ShowSevereError(state, String("{} \"{}\"").format(CurrentModuleObject, standAloneERV.Name))
                ShowContinueError(state, String("... When autosizing, {} and {} must both be autosized.").format(cNumericFields[1], cNumericFields[2]))
                ErrorsFound = True
        var CompSetSupplyFanInlet: StringRef = "UNDEFINED"
        var CompSetSupplyFanOutlet: StringRef = state.dataLoopNodes.NodeID[standAloneERV.SupplyAirOutletNode]
        var CompSetExhaustFanInlet: StringRef = "UNDEFINED"
        var CompSetExhaustFanOutlet: StringRef = state.dataLoopNodes.NodeID[standAloneERV.ExhaustAirOutletNode]
        Node.SetUpCompSets(state, standAloneERV.UnitType, standAloneERV.Name, "UNDEFINED", standAloneERV.HeatExchangerName, "UNDEFINED", "UNDEFINED")
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchAirHRZoneHVACName, standAloneERV.HeatExchangerName, standAloneERV.Name)
        Node.SetUpCompSets(state, standAloneERV.UnitType, standAloneERV.Name, "UNDEFINED", standAloneERV.SupplyAirFanName, CompSetSupplyFanInlet, CompSetSupplyFanOutlet)
        Node.SetUpCompSets(state, standAloneERV.UnitType, standAloneERV.Name, "UNDEFINED", standAloneERV.ExhaustAirFanName, CompSetExhaustFanInlet, CompSetExhaustFanOutlet)
        if state.dataInputProcessing.inputProcessor.getObjectItemNum(state, "HeatExchanger:AirToAir:SensibleAndLatent", standAloneERV.HeatExchangerName) <= 0:
            ShowSevereError(state, String("{} heat exchanger type HeatExchanger:AirToAir:SensibleAndLatent not found = {}").format(CurrentModuleObject, standAloneERV.HeatExchangerName))
            ErrorsFound = True
        if standAloneERV.supplyAirFanType != HVAC.FanType.SystemModel:
            if state.dataInputProcessing.inputProcessor.getObjectItemNum(state, "Fan:OnOff", standAloneERV.SupplyAirFanName) <= 0:
                ShowSevereError(state, String("{} supply fan type Fan:OnOff not found = {}").format(CurrentModuleObject, standAloneERV.SupplyAirFanName))
                ErrorsFound = True
        else:
            if state.dataInputProcessing.inputProcessor.getObjectItemNum(state, "Fan:SystemModel", standAloneERV.SupplyAirFanName) <= 0:
                ShowSevereError(state, String("{} supply fan type Fan:SystemModel not found = {}").format(CurrentModuleObject, standAloneERV.SupplyAirFanName))
                ErrorsFound = True
        if standAloneERV.exhaustAirFanType != HVAC.FanType.SystemModel:
            if state.dataInputProcessing.inputProcessor.getObjectItemNum(state, "Fan:OnOff", standAloneERV.ExhaustAirFanName) <= 0:
                ShowSevereError(state, String("{} exhaust fan type Fan:OnOff not found = {}").format(CurrentModuleObject, standAloneERV.ExhaustAirFanName))
                ErrorsFound = True
        else:
            if state.dataInputProcessing.inputProcessor.getObjectItemNum(state, "Fan:SystemModel", standAloneERV.ExhaustAirFanName) <= 0:
                ShowSevereError(state, String("{} exhaust fan type Fan:SystemModel not found = {}").format(CurrentModuleObject, standAloneERV.ExhaustAirFanName))
                ErrorsFound = True
    var OutAirNum: Int = 0
    CurrentModuleObject = "ZoneHVAC:EnergyRecoveryVentilator:Controller"
    NumERVCtrlrs = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, CurrentModuleObject)
    for ERVControllerNum in range(1, NumERVCtrlrs + 1):
        state.dataInputProcessing.inputProcessor.getObjectItem(state, CurrentModuleObject, ERVControllerNum, Alphas, NumAlphas, Numbers, NumNumbers, IOStatus, lNumericBlanks, lAlphaBlanks, cAlphaFields, cNumericFields)
        MixedAir.CheckOAControllerName(state, Alphas[1], CurrentModuleObject, cAlphaFields[1], ErrorsFound)
        OutAirNum += 1
        var thisOAController = state.dataMixedAir.OAController[OutAirNum]
        thisOAController.Name = Alphas[1]
        thisOAController.ControllerType = MixedAir.MixedAirControllerType.ControllerStandAloneERV
        var WhichERV: Int = Util.FindItemInList(Alphas[1], state.dataHVACStandAloneERV.StandAloneERV, StandAloneERVData.ControllerName)
        if WhichERV != 0:
            AirFlowRate = state.dataHVACStandAloneERV.StandAloneERV[WhichERV].SupplyAirVolFlow
            state.dataHVACStandAloneERV.StandAloneERV[WhichERV].ControllerIndex = OutAirNum
        else:
            ShowSevereError(state, String("GetERVController: Could not find ZoneHVAC:EnergyRecoveryVentilator with {} = \"{}\"").format(cAlphaFields[1], Alphas[1]))
            ErrorsFound = True
            AirFlowRate = -1000.0
        thisOAController.MaxOA = AirFlowRate
        thisOAController.MinOA = AirFlowRate
        if lNumericBlanks[1]:
            thisOAController.TempLim = HVAC.BlankNumeric
        else:
            thisOAController.TempLim = Numbers[1]
        if lNumericBlanks[2]:
            thisOAController.TempLowLim = HVAC.BlankNumeric
        else:
            thisOAController.TempLowLim = Numbers[2]
        if lNumericBlanks[3]:
            thisOAController.EnthLim = HVAC.BlankNumeric
        else:
            thisOAController.EnthLim = Numbers[3]
        if lNumericBlanks[4]:
            thisOAController.DPTempLim = HVAC.BlankNumeric
        else:
            thisOAController.DPTempLim = Numbers[4]
        if WhichERV != 0:
            NodeNumber = state.dataHVACStandAloneERV.StandAloneERV[WhichERV].SupplyAirInletNode
        else:
            NodeNumber = 0
        thisOAController.OANode = NodeNumber
        thisOAController.InletNode = NodeNumber
        if WhichERV != 0:
            NodeNumber = state.dataHVACStandAloneERV.StandAloneERV[WhichERV].ExhaustAirInletNode
        else:
            NodeNumber = 0
        thisOAController.RetNode = NodeNumber
        if not lAlphaBlanks[2]:
            thisOAController.EnthalpyCurvePtr = Curve.GetCurveIndex(state, Alphas[2])
            if Curve.GetCurveIndex(state, Alphas[2]) == 0:
                ShowSevereError(state, String("{} \"{}\"").format(CurrentModuleObject, Alphas[1]))
                ShowContinueError(state, String("...{} not found:{}").format(cAlphaFields[2], Alphas[2]))
                ErrorsFound = True
            else:
                ErrorsFound |= Curve.CheckCurveDims(state, thisOAController.EnthalpyCurvePtr, {1}, "GetStandAloneERV: ", CurrentModuleObject, thisOAController.Name, cAlphaFields[2])
        if Alphas[3] == "EXHAUSTAIRTEMPERATURELIMIT" and Alphas[4] == "EXHAUSTAIRENTHALPYLIMIT":
            thisOAController.Econo = MixedAir.EconoOp.DifferentialDryBulbAndEnthalpy
        elif Alphas[3] == "EXHAUSTAIRTEMPERATURELIMIT" and Alphas[4] == "NOEXHAUSTAIRENTHALPYLIMIT":
            thisOAController.Econo = MixedAir.EconoOp.DifferentialDryBulb
        elif Alphas[3] == "NOEXHAUSTAIRTEMPERATURELIMIT" and Alphas[4] == "EXHAUSTAIRENTHALPYLIMIT":
            thisOAController.Econo = MixedAir.EconoOp.DifferentialEnthalpy
        elif Alphas[3] == "NOEXHAUSTAIRTEMPERATURELIMIT" and Alphas[4] == "NOEXHAUSTAIRENTHALPYLIMIT":
            if (not lNumericBlanks[1]) or (not lNumericBlanks[3]) or (not lNumericBlanks[4]) or (not lAlphaBlanks[2]):
                thisOAController.Econo = MixedAir.EconoOp.FixedDryBulb
        elif (not lAlphaBlanks[3]) and (not lAlphaBlanks[4]):
            if (lNumericBlanks[1]) and (lNumericBlanks[3]) and (lNumericBlanks[4]) and lAlphaBlanks[2]:
                ShowWarningError(state, String("{} \"{}\"").format(CurrentModuleObject, Alphas[1]))
                ShowContinueError(state, String("... Invalid {}{} = {}{}").format(cAlphaFields[3], cAlphaFields[4], Alphas[3], Alphas[4]))
                ShowContinueError(state, "... Assumed NO EXHAUST AIR TEMP LIMIT and NO EXHAUST AIR ENTHALPY LIMIT.")
                thisOAController.Econo = MixedAir.EconoOp.NoEconomizer
            else:
                thisOAController.Econo = MixedAir.EconoOp.FixedDryBulb
        elif (lAlphaBlanks[3]) and (not lAlphaBlanks[4]):
            if (lNumericBlanks[1]) and (lNumericBlanks[3]) and (lNumericBlanks[4]) and lAlphaBlanks[2]:
                ShowWarningError(state, String("{} \"{}\"").format(CurrentModuleObject, Alphas[1]))
                ShowContinueError(state, String("... Invalid {} = {}").format(cAlphaFields[4], Alphas[4]))
                ShowContinueError(state, "... Assumed  NO EXHAUST AIR ENTHALPY LIMIT.")
                thisOAController.Econo = MixedAir.EconoOp.NoEconomizer
            else:
                thisOAController.Econo = MixedAir.EconoOp.FixedDryBulb
        elif (not lAlphaBlanks[3]) and (lAlphaBlanks[4]):
            if (lNumericBlanks[1]) and (lNumericBlanks[3]) and (lNumericBlanks[4]) and lAlphaBlanks[2]:
                ShowWarningError(state, String("{} \"{}\"").format(CurrentModuleObject, Alphas[1]))
                ShowContinueError(state, String("... Invalid {} = {}").format(cAlphaFields[3], Alphas[3]))
                ShowContinueError(state, "... Assumed NO EXHAUST AIR TEMP LIMIT ")
                thisOAController.Econo = MixedAir.EconoOp.NoEconomizer
            else:
                thisOAController.Econo = MixedAir.EconoOp.FixedDryBulb
        else:
            thisOAController.Econo = MixedAir.EconoOp.NoEconomizer
        thisOAController.FixedMin = False
        thisOAController.EconBypass = True
        var HighRHOARatio: Float64 = 1.0
        if Util.SameString(Alphas[6], "Yes"):
            HStatZoneNum = Util.FindItemInList(Alphas[7], state.dataHeatBal.Zone)
            thisOAController.HumidistatZoneNum = HStatZoneNum
            if HStatZoneNum > 0:
                var ZoneNodeFound: Bool = False
                if state.dataZoneEquip.ZoneEquipConfig[HStatZoneNum].IsControlled:
                    thisOAController.NodeNumofHumidistatZone = state.dataZoneEquip.ZoneEquipConfig[HStatZoneNum].ZoneNode
                    ZoneNodeFound = True
                if not ZoneNodeFound:
                    ShowSevereError(state, String("{} \"{}\"").format(CurrentModuleObject, Alphas[1]))
                    ShowContinueError(state, "... Did not find Air Node (Zone with Humidistat)")
                    ShowContinueError(state, String("... Specified {} = {}").format(cAlphaFields[7], Alphas[7]))
                    ShowContinueError(state, "... A ZoneHVAC:EquipmentConnections object must be specified for this zone.")
                    ErrorsFound = True
                else:
                    var HStatFound: Bool = False
                    for NumHstatZone in range(1, state.dataZoneCtrls.NumHumidityControlZones + 1):
                        if state.dataZoneCtrls.HumidityControlZone[NumHstatZone].ActualZoneNum != HStatZoneNum:
                            continue
                        HStatFound = True
                        break
                    if not HStatFound:
                        ShowSevereError(state, String("{} \"{}\"").format(CurrentModuleObject, Alphas[1]))
                        ShowContinueError(state, "... Did not find zone humidistat")
                        ShowContinueError(state, "... A ZoneControl:Humidistat object must be specified for this zone.")
                        ErrorsFound = True
            else:
                ShowSevereError(state, String("{} \"{}\"").format(CurrentModuleObject, Alphas[1]))
                ShowContinueError(state, "... Did not find Air Node (Zone with Humidistat)")
                ShowContinueError(state, "... A ZoneHVAC:EquipmentConnections object must be specified for this zone.")
                ErrorsFound = True
            if Numbers[5] <= 0.0 and NumNumbers > 4:
                ShowWarningError(state, String("{} \"{}\"").format(CurrentModuleObject, Alphas[1]))
                ShowContinueError(state, String("... {} must be greater than 0.").format(cNumericFields[5]))
                ShowContinueError(state, String("... {} is reset to 1 and the simulation continues.").format(cNumericFields[5]))
                HighRHOARatio = 1.0
            elif NumNumbers > 4:
                HighRHOARatio = Numbers[5]
            else:
                HighRHOARatio = 1.0
            if Util.SameString(Alphas[8], "Yes"):
                thisOAController.ModifyDuringHighOAMoisture = False
            else:
                thisOAController.ModifyDuringHighOAMoisture = True
        elif not Util.SameString(Alphas[6], "No") and NumAlphas > 4 and (not lAlphaBlanks[5]):
            ShowWarningError(state, String("{} \"{}\"").format(CurrentModuleObject, Alphas[1]))
            ShowContinueError(state, String("... Invalid {} = {}").format(cAlphaFields[6], Alphas[6]))
            ShowContinueError(state, String("... {} is assumed to be \"No\" and the simulation continues.").format(cAlphaFields[6]))
        thisOAController.HighRHOAFlowRatio = HighRHOARatio
        if WhichERV != 0:
            state.dataHVACStandAloneERV.StandAloneERV[WhichERV].HighRHOAFlowRatio = HighRHOARatio
        thisOAController.economizerOASched = Sched.GetSchedule(state, Alphas[5])
        if WhichERV != 0:
            state.dataHVACStandAloneERV.StandAloneERV[WhichERV].economizerOASched = Sched.GetSchedule(state, Alphas[5])
            if HighRHOARatio > 1.0 and state.dataHVACStandAloneERV.StandAloneERV[WhichERV].SupplyAirVolFlow != DataSizing.AutoSize and state.dataHVACStandAloneERV.StandAloneERV[WhichERV].DesignSAFanVolFlowRate != DataSizing.AutoSize:
                if state.dataHVACStandAloneERV.StandAloneERV[WhichERV].SupplyAirVolFlow * HighRHOARatio > state.dataHVACStandAloneERV.StandAloneERV[WhichERV].DesignSAFanVolFlowRate:
                    ShowWarningError(state, String("{} \"{}\"").format(CurrentModuleObject, Alphas[1]))
                    ShowContinueError(state, String("... A {} was entered as {:.4f}").format(cNumericFields[5], HighRHOARatio))
                    ShowContinueError(state, "... This flow ratio results in a Supply Air Volume Flow Rate through the ERV which is greater than the Max Volume specified in the supply air fan object.")
                    ShowContinueError(state, String("... Associated fan object = {} \"{}\"").format(HVAC.fanTypeNames[int(state.dataHVACStandAloneERV.StandAloneERV[WhichERV].supplyAirFanType)], state.dataHVACStandAloneERV.StandAloneERV[WhichERV].SupplyAirFanName))
                    ShowContinueError(state, String("... Modified value                   = {:.2f}").format(state.dataHVACStandAloneERV.StandAloneERV[WhichERV].SupplyAirVolFlow * HighRHOARatio))
                    ShowContinueError(state, String(" ... Supply Fan Max Volume Flow Rate = {:.2f}").format(state.dataHVACStandAloneERV.StandAloneERV[WhichERV].DesignSAFanVolFlowRate))
                    ShowContinueError(state, "... The ERV supply air fan will limit the air flow through the ERV and the simulation continues.")
            if HighRHOARatio > 1.0 and state.dataHVACStandAloneERV.StandAloneERV[WhichERV].ExhaustAirVolFlow != DataSizing.AutoSize and state.dataHVACStandAloneERV.StandAloneERV[WhichERV].DesignEAFanVolFlowRate != DataSizing.AutoSize:
                if state.dataHVACStandAloneERV.StandAloneERV[WhichERV].ExhaustAirVolFlow * HighRHOARatio > state.dataHVACStandAloneERV.StandAloneERV[WhichERV].DesignEAFanVolFlowRate:
                    ShowWarningError(state, String("ZoneHVAC:EnergyRecoveryVentilator:Controller \"{}\"").format(Alphas[1]))
                    ShowContinueError(state, String("... A {} was entered as {:.4f}").format(cNumericFields[5], HighRHOARatio))
                    ShowContinueError(state, "... This flow ratio results in an Exhaust Air Volume Flow Rate through the ERV which is greater than the Max Volume specified in the exhaust air fan object.")
                    ShowContinueError(state, String("... Associated fan object = {} \"{}\"").format(HVAC.fanTypeNames[int(state.dataHVACStandAloneERV.StandAloneERV[WhichERV].exhaustAirFanType)], state.dataHVACStandAloneERV.StandAloneERV[WhichERV].ExhaustAirFanName))
                    ShowContinueError(state, String("... Modified value                    = {:.2f}").format(state.dataHVACStandAloneERV.StandAloneERV[WhichERV].ExhaustAirVolFlow * HighRHOARatio))
                    ShowContinueError(state, String(" ... Exhaust Fan Max Volume Flow Rate = {:.2f}").format(state.dataHVACStandAloneERV.StandAloneERV[WhichERV].DesignEAFanVolFlowRate))
                    ShowContinueError(state, "... The ERV exhaust air fan will limit the air flow through the ERV and the simulation continues.")
    if ErrorsFound:
        ShowFatalError(state, "Errors found in getting ZoneHVAC:EnergyRecoveryVentilator input.")
    for StandAloneERVIndex in range(1, state.dataHVACStandAloneERV.NumStandAloneERVs + 1):
        var standAloneERV = state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVIndex]
        SetupOutputVariable(state, "Zone Ventilator Sensible Cooling Rate", Constant.Units.W, standAloneERV.SensCoolingRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, standAloneERV.Name)
        SetupOutputVariable(state, "Zone Ventilator Sensible Cooling Energy", Constant.Units.J, standAloneERV.SensCoolingEnergy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, standAloneERV.Name)
        SetupOutputVariable(state, "Zone Ventilator Latent Cooling Rate", Constant.Units.W, standAloneERV.LatCoolingRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, standAloneERV.Name)
        SetupOutputVariable(state, "Zone Ventilator Latent Cooling Energy", Constant.Units.J, standAloneERV.LatCoolingEnergy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, standAloneERV.Name)
        SetupOutputVariable(state, "Zone Ventilator Total Cooling Rate", Constant.Units.W, standAloneERV.TotCoolingRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, standAloneERV.Name)
        SetupOutputVariable(state, "Zone Ventilator Total Cooling Energy", Constant.Units.J, standAloneERV.TotCoolingEnergy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, standAloneERV.Name)
        SetupOutputVariable(state, "Zone Ventilator Sensible Heating Rate", Constant.Units.W, standAloneERV.SensHeatingRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, standAloneERV.Name)
        SetupOutputVariable(state, "Zone Ventilator Sensible Heating Energy", Constant.Units.J, standAloneERV.SensHeatingEnergy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, standAloneERV.Name)
        SetupOutputVariable(state, "Zone Ventilator Latent Heating Rate", Constant.Units.W, standAloneERV.LatHeatingRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, standAloneERV.Name)
        SetupOutputVariable(state, "Zone Ventilator Latent Heating Energy", Constant.Units.J, standAloneERV.LatHeatingEnergy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, standAloneERV.Name)
        SetupOutputVariable(state, "Zone Ventilator Total Heating Rate", Constant.Units.W, standAloneERV.TotHeatingRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, standAloneERV.Name)
        SetupOutputVariable(state, "Zone Ventilator Total Heating Energy", Constant.Units.J, standAloneERV.TotHeatingEnergy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, standAloneERV.Name)
        SetupOutputVariable(state, "Zone Ventilator Electricity Rate", Constant.Units.W, standAloneERV.ElecUseRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, standAloneERV.Name)
        SetupOutputVariable(state, "Zone Ventilator Electricity Energy", Constant.Units.J, standAloneERV.ElecUseEnergy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, standAloneERV.Name)
        SetupOutputVariable(state, "Zone Ventilator Supply Fan Availability Status", Constant.Units.None, standAloneERV.availStatus, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, standAloneERV.Name)
    Alphas.deallocate()
    Numbers.deallocate()
    cAlphaFields.deallocate()
    cNumericFields.deallocate()
    lNumericBlanks.deallocate()
    lAlphaBlanks.deallocate()

def InitStandAloneERV(state: EnergyPlusData, StandAloneERVNum: Int, ZoneNum: Int, FirstHVACIteration: Bool):
    if state.dataHVACStandAloneERV.MyOneTimeFlag:
        state.dataHVACStandAloneERV.MyEnvrnFlag.allocate(state.dataHVACStandAloneERV.NumStandAloneERVs)
        state.dataHVACStandAloneERV.MySizeFlag_InitStandAloneERV.allocate(state.dataHVACStandAloneERV.NumStandAloneERVs)
        state.dataHVACStandAloneERV.MyZoneEqFlag.allocate(state.dataHVACStandAloneERV.NumStandAloneERVs)
        state.dataHVACStandAloneERV.MyEnvrnFlag = True
        state.dataHVACStandAloneERV.MySizeFlag_InitStandAloneERV = True
        state.dataHVACStandAloneERV.MyZoneEqFlag = True
        state.dataHVACStandAloneERV.MyOneTimeFlag = False
    if allocated(state.dataAvail.ZoneComp):
        var availMgr = state.dataAvail.ZoneComp[DataZoneEquipment.ZoneEquipType.EnergyRecoveryVentilator].ZoneCompAvailMgrs[StandAloneERVNum]
        if state.dataHVACStandAloneERV.MyZoneEqFlag[StandAloneERVNum]:
            availMgr.AvailManagerListName = state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].AvailManagerListName
            availMgr.ZoneNum = ZoneNum
            state.dataHVACStandAloneERV.MyZoneEqFlag[StandAloneERVNum] = False
        state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].availStatus = availMgr.availStatus
    if not state.dataHVACStandAloneERV.ZoneEquipmentListChecked and state.dataZoneEquip.ZoneEquipInputsFilled:
        state.dataHVACStandAloneERV.ZoneEquipmentListChecked = True
        for Loop in range(1, state.dataHVACStandAloneERV.NumStandAloneERVs + 1):
            if DataZoneEquipment.CheckZoneEquipmentList(state, state.dataHVACStandAloneERV.StandAloneERV[Loop].UnitType, state.dataHVACStandAloneERV.StandAloneERV[Loop].Name):
                continue
            ShowSevereError(state, String("InitStandAloneERV: Unit=[{},{}] is not on any ZoneHVAC:EquipmentList.  It will not be simulated.").format(state.dataHVACStandAloneERV.StandAloneERV[Loop].UnitType, state.dataHVACStandAloneERV.StandAloneERV[Loop].Name))
    if not state.dataGlobal.SysSizingCalc and state.dataHVACStandAloneERV.MySizeFlag_InitStandAloneERV[StandAloneERVNum]:
        SizeStandAloneERV(state, StandAloneERVNum)
        state.dataHVACStandAloneERV.MySizeFlag_InitStandAloneERV[StandAloneERVNum] = False
    if state.dataGlobal.BeginEnvrnFlag and state.dataHVACStandAloneERV.MyEnvrnFlag[StandAloneERVNum]:
        var SupInNode: Int = state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].SupplyAirInletNode
        var ExhInNode: Int = state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].ExhaustAirInletNode
        state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].MaxSupAirMassFlow = state.dataEnvrn.StdRhoAir * state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].SupplyAirVolFlow
        state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].MaxExhAirMassFlow = state.dataEnvrn.StdRhoAir * state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].ExhaustAirVolFlow
        state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].DesignSAFanMassFlowRate = state.dataEnvrn.StdRhoAir * state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].DesignSAFanVolFlowRate
        state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].DesignEAFanMassFlowRate = state.dataEnvrn.StdRhoAir * state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].DesignEAFanVolFlowRate
        var supInNode = state.dataLoopNodes.Node[SupInNode]
        var exhInNode = state.dataLoopNodes.Node[ExhInNode]
        supInNode.MassFlowRateMax = state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].MaxSupAirMassFlow
        supInNode.MassFlowRateMin = 0.0
        exhInNode.MassFlowRateMax = state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].MaxExhAirMassFlow
        exhInNode.MassFlowRateMin = 0.0
        state.dataHVACStandAloneERV.MyEnvrnFlag[StandAloneERVNum] = False
        if state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].ControllerNameDefined:
            MixedAir.SimOAController(state, state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].ControllerName, state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].ControllerIndex, FirstHVACIteration, 0)
    if not state.dataGlobal.BeginEnvrnFlag:
        state.dataHVACStandAloneERV.MyEnvrnFlag[StandAloneERVNum] = True
    state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].ElecUseRate = 0.0
    state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].SensCoolingRate = 0.0
    state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].LatCoolingRate = 0.0
    state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].TotCoolingRate = 0.0
    state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].SensHeatingRate = 0.0
    state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].LatHeatingRate = 0.0
    state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].TotHeatingRate = 0.0
    var SupInNode: Int = state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].SupplyAirInletNode
    var ExhInNode: Int = state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].ExhaustAirInletNode
    var supInNode = state.dataLoopNodes.Node[SupInNode]
    var exhInNode = state.dataLoopNodes.Node[ExhInNode]
    if state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].availSched.getCurrentVal() > 0.0:
        if state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].ControllerNameDefined:
            supInNode.MassFlowRate = state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].MaxSupAirMassFlow
            MixedAir.SimOAController(state, state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].ControllerName, state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].ControllerIndex, FirstHVACIteration, 0)
        if state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].supplyAirFanSched.getCurrentVal() > 0 or (state.dataHVACGlobal.TurnFansOn and not state.dataHVACGlobal.TurnFansOff):
            if state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].ControllerNameDefined:
                if state.dataMixedAir.OAController[state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].ControllerIndex].HighHumCtrlActive:
                    supInNode.MassFlowRate = min(state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].DesignSAFanMassFlowRate, state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].MaxSupAirMassFlow * state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].HighRHOAFlowRatio)
                else:
                    supInNode.MassFlowRate = min(state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].DesignSAFanMassFlowRate, state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].MaxSupAirMassFlow)
            else:
                supInNode.MassFlowRate = min(state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].DesignSAFanMassFlowRate, state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].MaxSupAirMassFlow)
        else:
            supInNode.MassFlowRate = 0.0
        supInNode.MassFlowRateMaxAvail = supInNode.MassFlowRate
        supInNode.MassFlowRateMinAvail = supInNode.MassFlowRate
        if state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].exhaustAirFanSched.getCurrentVal() > 0:
            if state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].ControllerNameDefined:
                if state.dataMixedAir.OAController[state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].ControllerIndex].HighHumCtrlActive:
                    exhInNode.MassFlowRate = min(state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].DesignEAFanMassFlowRate, state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].MaxExhAirMassFlow * state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].HighRHOAFlowRatio)
                else:
                    exhInNode.MassFlowRate = min(state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].DesignEAFanMassFlowRate, state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].MaxExhAirMassFlow)
            else:
                exhInNode.MassFlowRate = min(state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].DesignEAFanMassFlowRate, state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].MaxExhAirMassFlow)
        else:
            exhInNode.MassFlowRate = 0.0
        exhInNode.MassFlowRateMaxAvail = exhInNode.MassFlowRate
        exhInNode.MassFlowRateMinAvail = exhInNode.MassFlowRate
    else:
        supInNode.MassFlowRate = 0.0
        supInNode.MassFlowRateMaxAvail = 0.0
        supInNode.MassFlowRateMinAvail = 0.0
        exhInNode.MassFlowRate = 0.0
        exhInNode.MassFlowRateMaxAvail = 0.0
        exhInNode.MassFlowRateMinAvail = 0.0

def SizeStandAloneERV(state: EnergyPlusData, StandAloneERVNum: Int):
    var RoutineName: StringRef = "SizeStandAloneERV: "
    var IsAutoSize: Bool = False
    var SupplyAirVolFlowDes: Float64 = 0.0
    var DesignSAFanVolFlowRateDes: Float64 = 0.0
    var DesignSAFanVolFlowRateUser: Float64 = 0.0
    var ExhaustAirVolFlowDes: Float64 = 0.0
    var CompType: StringRef = "ZoneHVAC:EnergyRecoveryVentilator"
    var CompName: StringRef = state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].Name
    var PrintFlag: Bool = True
    var ErrorsFound: Bool = False
    var zoneEqSizing = state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum]
    if state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].SupplyAirVolFlow == DataSizing.AutoSize:
        IsAutoSize = True
    if state.dataSize.CurZoneEqNum > 0:
        var ZoneNum: Int = state.dataSize.CurZoneEqNum
        var ZoneMult: Float64 = state.dataHeatBal.Zone[ZoneNum].Multiplier * state.dataHeatBal.Zone[ZoneNum].ListMultiplier
        var FloorArea: Float64 = state.dataHeatBal.Zone[ZoneNum].FloorArea
        var NumberOfPeople: Float64 = 0.0
        var MaxPeopleSch: Float64 = 0.0
        for PeopleNum in range(1, state.dataHeatBal.TotPeople + 1):
            if ZoneNum != state.dataHeatBal.People[PeopleNum].ZonePtr:
                continue
            MaxPeopleSch = state.dataHeatBal.People[PeopleNum].sched.getMaxVal(state)
            NumberOfPeople = NumberOfPeople + (state.dataHeatBal.People[PeopleNum].NumberOfPeople * MaxPeopleSch)
        SupplyAirVolFlowDes = FloorArea * state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].AirVolFlowPerFloorArea + NumberOfPeople * state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].AirVolFlowPerOccupant
        SupplyAirVolFlowDes = ZoneMult * SupplyAirVolFlowDes
        if SupplyAirVolFlowDes < HVAC.SmallAirVolFlow:
            SupplyAirVolFlowDes = 0.0
        var TempSize: Float64 = state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].SupplyAirVolFlow
        if IsAutoSize:
            state.dataSize.DataConstantUsedForSizing = SupplyAirVolFlowDes
            state.dataSize.DataFractionUsedForSizing = 1.0
            TempSize = SupplyAirVolFlowDes
            if state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].ControllerNameDefined:
                state.dataMixedAir.OAController[state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].ControllerIndex].MaxOA = SupplyAirVolFlowDes * state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].HighRHOAFlowRatio
                state.dataMixedAir.OAController[state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].ControllerIndex].MinOA = SupplyAirVolFlowDes
        else:
            state.dataSize.DataConstantUsedForSizing = state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].SupplyAirVolFlow
            state.dataSize.DataFractionUsedForSizing = 1.0
        if TempSize > 0.0:
            var SizingString: StringRef = "Supply Air Flow Rate [m3/s]"
            var sizerSystemAirFlow: SystemAirFlowSizer = SystemAirFlowSizer()
            sizerSystemAirFlow.overrideSizingString(SizingString)
            sizerSystemAirFlow.initializeWithinEP(state, CompType, CompName, PrintFlag, RoutineName)
            TempSize = sizerSystemAirFlow.size(state, TempSize, ErrorsFound)
        state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].SupplyAirVolFlow = TempSize
    state.dataSize.DataFractionUsedForSizing = 1.0
    IsAutoSize = False
    if state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].ExhaustAirVolFlow == DataSizing.AutoSize:
        IsAutoSize = True
    if state.dataSize.CurZoneEqNum > 0:
        ExhaustAirVolFlowDes = SupplyAirVolFlowDes
        if ExhaustAirVolFlowDes < HVAC.SmallAirVolFlow:
            ExhaustAirVolFlowDes = 0.0
        if ExhaustAirVolFlowDes > state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].SupplyAirVolFlow:
            ExhaustAirVolFlowDes = state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].SupplyAirVolFlow
        var TempSize: Float64 = state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].ExhaustAirVolFlow
        if IsAutoSize:
            TempSize = ExhaustAirVolFlowDes
            state.dataSize.DataConstantUsedForSizing = ExhaustAirVolFlowDes
        else:
            state.dataSize.DataConstantUsedForSizing = state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].ExhaustAirVolFlow
        state.dataSize.DataFractionUsedForSizing = 1.0
        if TempSize > 0.0:
            var SizingString: StringRef = "Exhaust Air Flow Rate [m3/s]"
            var sizerSystemAirFlow: SystemAirFlowSizer = SystemAirFlowSizer()
            sizerSystemAirFlow.overrideSizingString(SizingString)
            sizerSystemAirFlow.initializeWithinEP(state, CompType, CompName, PrintFlag, RoutineName)
            TempSize = sizerSystemAirFlow.size(state, TempSize, ErrorsFound)
        state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].ExhaustAirVolFlow = TempSize
        state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].DesignEAFanVolFlowRate = TempSize * state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].HighRHOAFlowRatio
    zoneEqSizing.AirVolFlow = state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].SupplyAirVolFlow * state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].HighRHOAFlowRatio
    zoneEqSizing.OAVolFlow = state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].SupplyAirVolFlow
    zoneEqSizing.SystemAirFlow = True
    zoneEqSizing.DesignSizeFromParent = True
    IsAutoSize = False
    if state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].DesignSAFanVolFlowRate == DataSizing.AutoSize:
        IsAutoSize = True
    DesignSAFanVolFlowRateDes = state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].SupplyAirVolFlow * state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].HighRHOAFlowRatio
    if IsAutoSize:
        state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].DesignSAFanVolFlowRate = DesignSAFanVolFlowRateDes
    else:
        if state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].DesignSAFanVolFlowRate > 0.0 and DesignSAFanVolFlowRateDes > 0.0:
            DesignSAFanVolFlowRateUser = state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].DesignSAFanVolFlowRate
            if state.dataGlobal.DisplayExtraWarnings:
                if (fabs(DesignSAFanVolFlowRateDes - DesignSAFanVolFlowRateUser) / DesignSAFanVolFlowRateUser) > state.dataSize.AutoVsHardSizingThreshold:
                    ShowMessage(state, String("SizeStandAloneERV: Potential issue with equipment sizing for ZoneHVAC:EnergyRecoveryVentilator {} {}").format(HVAC.fanTypeNames[int(state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].supplyAirFanType)], state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].SupplyAirFanName))
                    ShowContinueError(state, String("User-Specified Supply Fan Maximum Flow Rate of {:#G} [m3/s]").format(DesignSAFanVolFlowRateUser))
                    ShowContinueError(state, String("differs from the ERV Supply Air Flow Rate of {:#G} [m3/s]").format(DesignSAFanVolFlowRateDes))
                    ShowContinueError(state, "This may, or may not, indicate mismatched component sizes.")
                    ShowContinueError(state, "Verify that the value entered is intended and is consistent with other components.")
    state.dataFans.fans[state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].SupplyAirFanIndex].simulate(state, True, _, _)
    state.dataFans.fans[state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].ExhaustAirFanIndex].simulate(state, True, _, _)
    zoneEqSizing.AirVolFlow = state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].SupplyAirVolFlow

def CalcStandAloneERV(state: EnergyPlusData, StandAloneERVNum: Int, FirstHVACIteration: Bool, SensLoadMet: Float64, LatentMassLoadMet: Float64):
    var TotLoadMet: Float64
    var LatLoadMet: Float64
    var EconomizerFlag: Bool
    var HighHumCtrlFlag: Bool
    var SupInletNode: Int = state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].SupplyAirInletNode
    var SupOutletNode: Int = state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].SupplyAirOutletNode
    var ExhaustInletNode: Int = state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].ExhaustAirInletNode
    var HXUnitOn: Bool = True
    if state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].ControllerNameDefined:
        EconomizerFlag = state.dataMixedAir.OAController[state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].ControllerIndex].EconoActive
        HighHumCtrlFlag = state.dataMixedAir.OAController[state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].ControllerIndex].HighHumCtrlActive
    else:
        EconomizerFlag = False
        HighHumCtrlFlag = False
    HeatRecovery.SimHeatRecovery(state, state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].HeatExchangerName, FirstHVACIteration, state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].HeatExchangerIndex, HVAC.FanOp.Continuous, _, HXUnitOn, _, _, EconomizerFlag, HighHumCtrlFlag)
    state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].ElecUseRate = state.dataHVACGlobal.AirToAirHXElecPower
    state.dataFans.fans[state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].SupplyAirFanIndex].simulate(state, FirstHVACIteration, _, _)
    state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].ElecUseRate += state.dataFans.fans[state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].SupplyAirFanIndex].totalPower
    state.dataFans.fans[state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].ExhaustAirFanIndex].simulate(state, FirstHVACIteration, _, _)
    state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].ElecUseRate += state.dataFans.fans[state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].ExhaustAirFanIndex].totalPower
    var AirMassFlow: Float64 = state.dataLoopNodes.Node[SupOutletNode].MassFlowRate
    CalcZoneSensibleLatentOutput(AirMassFlow, state.dataLoopNodes.Node[SupOutletNode].Temp, state.dataLoopNodes.Node[SupOutletNode].HumRat, state.dataLoopNodes.Node[ExhaustInletNode].Temp, state.dataLoopNodes.Node[ExhaustInletNode].HumRat, SensLoadMet, LatLoadMet, TotLoadMet)
    LatentMassLoadMet = AirMassFlow * (state.dataLoopNodes.Node[SupOutletNode].HumRat - state.dataLoopNodes.Node[ExhaustInletNode].HumRat)
    if SensLoadMet < 0.0:
        state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].SensCoolingRate = fabs(SensLoadMet)
        state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].SensHeatingRate = 0.0
    else:
        state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].SensCoolingRate = 0.0
        state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].SensHeatingRate = SensLoadMet
    if TotLoadMet < 0.0:
        state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].TotCoolingRate = fabs(TotLoadMet)
        state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].TotHeatingRate = 0.0
    else:
        state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].TotCoolingRate = 0.0
        state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].TotHeatingRate = TotLoadMet
    if LatLoadMet < 0.0:
        state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].LatCoolingRate = fabs(LatLoadMet)
        state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].LatHeatingRate = 0.0
    else:
        state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].LatCoolingRate = 0.0
        state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].LatHeatingRate = LatLoadMet
    if state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].FlowError and not state.dataGlobal.WarmupFlag:
        var TotalExhaustMassFlow: Float64 = state.dataLoopNodes.Node[ExhaustInletNode].MassFlowRate
        var TotalSupplyMassFlow: Float64 = state.dataLoopNodes.Node[SupInletNode].MassFlowRate
        if TotalExhaustMassFlow > TotalSupplyMassFlow and not state.dataHeatBal.ZoneAirMassFlow.EnforceZoneMassBalance:
            ShowWarningError(state, String("For {} \"{}\" there is unbalanced exhaust air flow.").format(state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].UnitType, state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].Name))
            ShowContinueError(state, String("... The exhaust air mass flow rate = {:#G}").format(state.dataLoopNodes.Node[ExhaustInletNode].MassFlowRate))
            ShowContinueError(state, String("... The  supply air mass flow rate = {:#G}").format(state.dataLoopNodes.Node[SupInletNode].MassFlowRate))
            ShowContinueErrorTimeStamp(state, "")
            ShowContinueError(state, "... Unless there is balancing infiltration / ventilation air flow, this will result in")
            ShowContinueError(state, "... load due to induced outside air being neglected in the simulation.")
            state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].FlowError = False

def ReportStandAloneERV(state: EnergyPlusData, StandAloneERVNum: Int):
    var ReportingConstant: Float64 = state.dataHVACGlobal.TimeStepSysSec
    state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].ElecUseEnergy = state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].ElecUseRate * ReportingConstant
    state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].SensCoolingEnergy = state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].SensCoolingRate * ReportingConstant
    state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].LatCoolingEnergy = state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].LatCoolingRate * ReportingConstant
    state.dataHVACStandAloneERV.StandAloneERV[StandAloneERVNum].