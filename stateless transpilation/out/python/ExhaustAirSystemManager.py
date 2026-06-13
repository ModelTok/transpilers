# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state parameter carrying all domain data
# - HVAC.FanType: enum with values Invalid, SystemModel, ComponentModel
# - Sched.Schedule: schedule object with getCurrentVal() method
# - Node module: functions like GetOnlySingleNode, GetNodeNums, ConnectionObjectType, FluidType, ConnectionType, CompFluidStream
# - MixerComponent: InitAirMixer, SimAirMixer, GetZoneMixerIndex functions
# - Fans module: GetFanIndex function, fan object with properties
# - DataSizing module: AutoSize constant, FinalZoneSizing data
# - Psychrometrics module: PsyRhoAirFnPbTdbW function
# - InputProcessor: epJSON interface, field getter methods
# - DataContaminantBalance: Contaminant object with CO2Simulation, GenericContamSimulation flags
# - Utility functions: makeUPPER, FindItemInList
# - Output functions: SetupOutputVariable, ShowSevereError, ShowContinueError, ShowFatalError, etc.
# - BaseSizer.reportSizerOutput

from enum import Enum
from typing import Dict, List, Optional
from dataclasses import dataclass, field


class FlowControlType(Enum):
    INVALID = -1
    SCHEDULED = 0
    FOLLOW_SUPPLY = 1
    NUM = 2


@dataclass
class ExhaustAir:
    Name: str = ""
    availSched: Optional[object] = None
    ZoneMixerName: str = ""
    ZoneMixerIndex: int = 0
    centralFanType: object = None
    CentralFanName: str = ""
    CentralFanIndex: int = 0
    SizingFlag: bool = True
    centralFan_MassFlowRate: float = 0.0
    centralFan_VolumeFlowRate_Std: float = 0.0
    centralFan_VolumeFlowRate_Cur: float = 0.0
    centralFan_Power: float = 0.0
    centralFan_Energy: float = 0.0
    exhTotalHVACReliefHeatLoss: float = 0.0


@dataclass
class ZoneExhaustControl:
    Name: str = ""
    availSched: Optional[object] = None
    ZoneName: str = ""
    ZoneNum: int = 0
    ControlledZoneNum: int = 0
    InletNodeNum: int = 0
    OutletNodeNum: int = 0
    DesignExhaustFlowRate: float = 0.0
    FlowControlOption: FlowControlType = FlowControlType.SCHEDULED
    exhaustFlowFractionSched: Optional[object] = None
    SupplyNodeOrNodelistName: str = ""
    SupplyNodeOrNodelistNum: int = 0
    minZoneTempLimitSched: Optional[object] = None
    minExhFlowFracSched: Optional[object] = None
    balancedExhFracSched: Optional[object] = None
    BalancedFlow: float = 0.0
    UnbalancedFlow: float = 0.0
    SuppNodeNums: List[int] = field(default_factory=list)


@dataclass
class ExhaustAirSystemMgr:
    GetInputFlag: bool = True
    mixerIndexMap: Dict[int, int] = field(default_factory=dict)
    mappingDone: bool = False


@dataclass
class ExhaustControlSystemMgr:
    GetInputFlag: bool = True


FLOW_CONTROL_TYPE_NAMES_UC = ["SCHEDULED", "FOLLOWSUPPLY"]


def SimExhaustAirSystem(state: object, FirstHVACIteration: bool) -> None:
    if state.dataExhAirSystemMrg.GetInputFlag:
        GetExhaustAirSystemInput(state)
        state.dataExhAirSystemMrg.GetInputFlag = False

    for ExhaustAirSystemNum in range(1, state.dataZoneEquip.NumExhaustAirSystems + 1):
        CalcExhaustAirSystem(state, ExhaustAirSystemNum, FirstHVACIteration)

    UpdateZoneExhaustControl(state)


def GetExhaustAirSystemInput(state: object) -> None:
    if not state.dataExhAirSystemMrg.GetInputFlag:
        return

    ErrorsFound = False
    RoutineName = "GetExhaustAirSystemInput: "
    routineName = "GetExhaustAirSystemInput"
    cCurrentModuleObject = "AirLoopHVAC:ExhaustSystem"

    ip = state.dataInputProcessing.inputProcessor
    instances = ip.epJSON.get(cCurrentModuleObject)
    
    if instances is not None:
        objectSchemaProps = ip.getObjectSchemaProps(state, cCurrentModuleObject)
        numExhaustSystems = len(instances)
        exhSysNum = 0

        if numExhaustSystems > 0:
            state.dataZoneEquip.ExhaustAirSystem = [ExhaustAir() for _ in range(numExhaustSystems)]

        for instance_key, objectFields in instances.items():
            exhSysNum += 1
            thisExhSys = state.dataZoneEquip.ExhaustAirSystem[exhSysNum - 1]
            thisExhSys.Name = instance_key.upper()
            ip.markObjectAsUsed(cCurrentModuleObject, instance_key)

            zoneMixerName = ip.getAlphaFieldValue(objectFields, objectSchemaProps, "zone_mixer_name")
            zoneMixerIndex = 0
            zoneMixerErrFound = False
            MixerComponent.GetZoneMixerIndex(state, zoneMixerName, zoneMixerIndex, zoneMixerErrFound, thisExhSys.Name)

            if not zoneMixerErrFound:
                MixerComponent.InitAirMixer(state, zoneMixerIndex)
                IsNotOK = False
                ValidateComponent(state, "AirLoopHVAC:ZoneMixer", zoneMixerName, IsNotOK, "AirLoopHVAC:ExhaustSystem")
                if IsNotOK:
                    ShowSevereError(state, f"{RoutineName}{cCurrentModuleObject}={thisExhSys.Name}")
                    ShowContinueError(state, f"ZoneMixer Name ={zoneMixerName} mismatch or not found.")
                    ErrorsFound = True
            else:
                ShowSevereError(state, f"{RoutineName}{cCurrentModuleObject}={thisExhSys.Name}")
                ShowContinueError(state, f"Zone Mixer Name ={zoneMixerName} not found.")
                ErrorsFound = True

            thisExhSys.ZoneMixerName = zoneMixerName
            thisExhSys.ZoneMixerIndex = zoneMixerIndex

            fanTypeStr = ip.getAlphaFieldValue(objectFields, objectSchemaProps, "fan_object_type").upper()
            thisExhSys.centralFanType = getEnumValue(HVAC.fanTypeNamesUC, fanTypeStr)
            
            if thisExhSys.centralFanType != HVAC.FanType.SystemModel and thisExhSys.centralFanType != HVAC.FanType.ComponentModel:
                ShowSevereError(state, f"{RoutineName}{cCurrentModuleObject}={thisExhSys.Name}")
                ShowContinueError(state, f"Fan Type ={HVAC.fanTypeNames[int(thisExhSys.centralFanType)]} is not supported.")
                ShowContinueError(state, "It needs to be either a Fan:SystemModel or a Fan:ComponentModel type.")
                ErrorsFound = True

            centralFanName = ip.getAlphaFieldValue(objectFields, objectSchemaProps, "fan_name")
            eoh = ErrorObjectHeader(routineName, cCurrentModuleObject, thisExhSys.Name)
            centralFanIndex = Fans.GetFanIndex(state, centralFanName)
            
            if centralFanIndex == 0:
                ShowSevereItemNotFound(state, eoh, "fan_name", centralFanName)
                ErrorsFound = True
            else:
                fan = state.dataFans.fans[centralFanIndex - 1]
                thisExhSys.availSched = fan.availSched

                Node.SetUpCompSets(state,
                                   cCurrentModuleObject,
                                   thisExhSys.Name,
                                   HVAC.fanTypeNames[int(thisExhSys.centralFanType)],
                                   centralFanName,
                                   state.dataLoopNodes.NodeID(fan.inletNodeNum),
                                   state.dataLoopNodes.NodeID(fan.outletNodeNum))

                SetupOutputVariable(state,
                                    "Central Exhaust Fan Mass Flow Rate",
                                    "kg/s",
                                    thisExhSys, "centralFan_MassFlowRate",
                                    "System", "Average", thisExhSys.Name)

                SetupOutputVariable(state,
                                    "Central Exhaust Fan Volumetric Flow Rate Standard",
                                    "m3/s",
                                    thisExhSys, "centralFan_VolumeFlowRate_Std",
                                    "System", "Average", thisExhSys.Name)

                SetupOutputVariable(state,
                                    "Central Exhaust Fan Volumetric Flow Rate Current",
                                    "m3/s",
                                    thisExhSys, "centralFan_VolumeFlowRate_Cur",
                                    "System", "Average", thisExhSys.Name)

                SetupOutputVariable(state,
                                    "Central Exhaust Fan Power",
                                    "W",
                                    thisExhSys, "centralFan_Power",
                                    "System", "Average", thisExhSys.Name)

                SetupOutputVariable(state,
                                    "Central Exhaust Fan Energy",
                                    "J",
                                    thisExhSys, "centralFan_Energy",
                                    "System", "Sum", thisExhSys.Name)

            thisExhSys.CentralFanName = centralFanName
            thisExhSys.CentralFanIndex = centralFanIndex

            if thisExhSys.SizingFlag:
                SizeExhaustSystem(state, exhSysNum)

        state.dataZoneEquip.NumExhaustAirSystems = numExhaustSystems

    if ErrorsFound:
        ShowFatalError(state, "Errors found getting AirLoopHVAC:ExhaustSystem.  Preceding condition(s) causes termination.")


def CalcExhaustAirSystem(state: object, ExhaustAirSystemNum: int, FirstHVACIteration: bool) -> None:
    thisExhSys = state.dataZoneEquip.ExhaustAirSystem[ExhaustAirSystemNum - 1]
    RoutineName = "CalExhaustAirSystem: "
    cCurrentModuleObject = "AirloopHVAC:ExhaustSystem"
    ErrorsFound = False

    if not (state.afn.AirflowNetworkFanActivated and state.afn.distribution_simulated):
        MixerComponent.SimAirMixer(state, thisExhSys.ZoneMixerName, thisExhSys.ZoneMixerIndex)
    else:
        ShowSevereError(state, f"{RoutineName}{cCurrentModuleObject}={thisExhSys.Name}")
        ShowContinueError(state, "AirloopHVAC:ExhaustSystem currently does not work with AirflowNetwork.")
        ErrorsFound = True

    if ErrorsFound:
        ShowFatalError(state, "Errors found conducting CalcExhasutAirSystem(). Preceding condition(s) causes termination.")

    mixerFlow_Prior = 0.0
    outletNode_index = state.dataMixerComponent.MixerCond[thisExhSys.ZoneMixerIndex - 1].OutletNode
    mixerFlow_Prior = state.dataLoopNodes.Node[outletNode_index - 1].MassFlowRate

    outletNode_Num = 0
    RhoAirCurrent = state.dataEnvrn.StdRhoAir

    if thisExhSys.centralFanType == HVAC.FanType.SystemModel:
        state.dataHVACGlobal.OnOffFanPartLoadFraction = 1.0
        state.dataFans.fans[thisExhSys.CentralFanIndex - 1].simulate(state, False)

        outletNode_Num = state.dataFans.fans[thisExhSys.CentralFanIndex - 1].outletNodeNum

        thisExhSys.centralFan_MassFlowRate = state.dataLoopNodes.Node[outletNode_Num - 1].MassFlowRate
        thisExhSys.centralFan_VolumeFlowRate_Std = state.dataLoopNodes.Node[outletNode_Num - 1].MassFlowRate / state.dataEnvrn.StdRhoAir

        RhoAirCurrent = Psychrometrics.PsyRhoAirFnPbTdbW(state,
                                                         state.dataEnvrn.OutBaroPress,
                                                         state.dataLoopNodes.Node[outletNode_Num - 1].Temp,
                                                         state.dataLoopNodes.Node[outletNode_Num - 1].HumRat)
        if RhoAirCurrent <= 0.0:
            RhoAirCurrent = state.dataEnvrn.StdRhoAir
        thisExhSys.centralFan_VolumeFlowRate_Cur = state.dataLoopNodes.Node[outletNode_Num - 1].MassFlowRate / RhoAirCurrent

        thisExhSys.centralFan_Power = state.dataFans.fans[thisExhSys.CentralFanIndex - 1].totalPower
        thisExhSys.centralFan_Energy = thisExhSys.centralFan_Power * state.dataHVACGlobal.TimeStepSysSec

    elif thisExhSys.centralFanType == HVAC.FanType.ComponentModel:
        fan = state.dataFans.fans[thisExhSys.CentralFanIndex - 1]
        fan.simulate(state, FirstHVACIteration)

        outletNode_Num = fan.outletNodeNum
        thisExhSys.centralFan_MassFlowRate = fan.outletAirMassFlowRate
        thisExhSys.centralFan_VolumeFlowRate_Std = fan.outletAirMassFlowRate / state.dataEnvrn.StdRhoAir

        RhoAirCurrent = Psychrometrics.PsyRhoAirFnPbTdbW(state,
                                                         state.dataEnvrn.OutBaroPress,
                                                         state.dataLoopNodes.Node[outletNode_Num - 1].Temp,
                                                         state.dataLoopNodes.Node[outletNode_Num - 1].HumRat)
        if RhoAirCurrent <= 0.0:
            RhoAirCurrent = state.dataEnvrn.StdRhoAir
        thisExhSys.centralFan_VolumeFlowRate_Cur = fan.outletAirMassFlowRate / RhoAirCurrent

        thisExhSys.centralFan_Power = fan.totalPower * 1000.0
        thisExhSys.centralFan_Energy = fan.totalEnergy * 1000.0

    thisExhSys.exhTotalHVACReliefHeatLoss = state.dataLoopNodes.Node[outletNode_Num - 1].MassFlowRate * \
                                            (state.dataLoopNodes.Node[outletNode_Num - 1].Enthalpy - state.dataEnvrn.OutEnthalpy)

    mixerFlow_Posterior = 0.0
    mixerFlow_Posterior = state.dataLoopNodes.Node[outletNode_index - 1].MassFlowRate

    if (abs(mixerFlow_Prior - mixerFlow_Posterior) > HVAC.SmallMassFlow):
        flowRatio = mixerFlow_Posterior / mixerFlow_Prior
        if flowRatio > 1.0:
            ShowWarningError(state, f"{RoutineName}{cCurrentModuleObject}={thisExhSys.Name}")
            ShowContinueError(state, "Requested flow rate is lower than the exhasut fan flow rate.")
            ShowContinueError(state, "Will scale up the requested flow rate to meet fan flow rate.")

        zoneMixerIndex = thisExhSys.ZoneMixerIndex
        for i in range(1, state.dataMixerComponent.MixerCond[zoneMixerIndex - 1].NumInletNodes + 1):
            exhLegIndex = state.dataExhAirSystemMrg.mixerIndexMap[state.dataMixerComponent.MixerCond[zoneMixerIndex - 1].InletNode[i - 1]]
            CalcZoneHVACExhaustControl(state, exhLegIndex, flowRatio)

        MixerComponent.SimAirMixer(state, thisExhSys.ZoneMixerName, thisExhSys.ZoneMixerIndex)


def GetZoneExhaustControlInput(state: object) -> None:
    ErrorsFound = False
    RoutineName = "GetZoneExhaustControlInput: "
    routineName = "GetZoneExhaustControlInput"
    cCurrentModuleObject = "ZoneHVAC:ExhaustControl"

    ip = state.dataInputProcessing.inputProcessor
    instances = ip.epJSON.get(cCurrentModuleObject)

    if instances is not None:
        objectSchemaProps = ip.getObjectSchemaProps(state, cCurrentModuleObject)
        numZoneExhaustControls = len(instances)
        exhCtrlNum = 0

        if numZoneExhaustControls > 0:
            state.dataZoneEquip.ZoneExhaustControlSystem = [ZoneExhaustControl() for _ in range(numZoneExhaustControls)]

        for instance_key, objectFields in instances.items():
            exhCtrlNum += 1
            thisExhCtrl = state.dataZoneEquip.ZoneExhaustControlSystem[exhCtrlNum - 1]
            eoh = ErrorObjectHeader(routineName, cCurrentModuleObject, instance_key)

            thisExhCtrl.Name = instance_key.upper()
            ip.markObjectAsUsed(cCurrentModuleObject, instance_key)

            availSchName = ip.getAlphaFieldValue(objectFields, objectSchemaProps, "availability_schedule_name")
            if not availSchName:
                thisExhCtrl.availSched = Sched.GetScheduleAlwaysOn(state)
            else:
                thisExhCtrl.availSched = Sched.GetSchedule(state, availSchName)
                if thisExhCtrl.availSched is None:
                    thisExhCtrl.availSched = Sched.GetScheduleAlwaysOn(state)
                    ShowWarningItemNotFound(state, eoh, "Availability Schedule Name", availSchName, "Availability Schedule is reset to Always ON.")

            zoneName = ip.getAlphaFieldValue(objectFields, objectSchemaProps, "zone_name")
            thisExhCtrl.ZoneName = zoneName
            zoneNum = FindItemInList(zoneName, state.dataHeatBal.Zone)
            thisExhCtrl.ZoneNum = zoneNum
            thisExhCtrl.ControlledZoneNum = FindItemInList(zoneName, state.dataHeatBal.Zone)

            inletNodeName = ip.getAlphaFieldValue(objectFields, objectSchemaProps, "inlet_node_name")
            inletNodeNum = Node.GetOnlySingleNode(state,
                                                  inletNodeName,
                                                  ErrorsFound,
                                                  Node.ConnectionObjectType.ZoneHVACExhaustControl,
                                                  thisExhCtrl.Name,
                                                  Node.FluidType.Air,
                                                  Node.ConnectionType.Inlet,
                                                  Node.CompFluidStream.Primary,
                                                  Node.ObjectIsParent)
            thisExhCtrl.InletNodeNum = inletNodeNum

            outletNodeName = ip.getAlphaFieldValue(objectFields, objectSchemaProps, "outlet_node_name")
            outletNodeNum = Node.GetOnlySingleNode(state,
                                                   outletNodeName,
                                                   ErrorsFound,
                                                   Node.ConnectionObjectType.ZoneHVACExhaustControl,
                                                   thisExhCtrl.Name,
                                                   Node.FluidType.Air,
                                                   Node.ConnectionType.Outlet,
                                                   Node.CompFluidStream.Primary,
                                                   Node.ObjectIsParent)
            thisExhCtrl.OutletNodeNum = outletNodeNum

            if not state.dataExhAirSystemMrg.mappingDone:
                state.dataExhAirSystemMrg.mixerIndexMap[outletNodeNum] = exhCtrlNum

            designExhaustFlowRate = ip.getRealFieldValue(objectFields, objectSchemaProps, "design_exhaust_flow_rate")
            thisExhCtrl.DesignExhaustFlowRate = designExhaustFlowRate

            flowControlTypeName = ip.getAlphaFieldValue(objectFields, objectSchemaProps, "flow_control_type").upper()
            thisExhCtrl.FlowControlOption = FlowControlType[getEnumValue(FLOW_CONTROL_TYPE_NAMES_UC, flowControlTypeName)]

            exhaustFlowFractionSchedName = ip.getAlphaFieldValue(objectFields, objectSchemaProps, "exhaust_flow_fraction_schedule_name")
            if not exhaustFlowFractionSchedName:
                thisExhCtrl.exhaustFlowFractionSched = Sched.GetScheduleAlwaysOn(state)
            else:
                thisExhCtrl.exhaustFlowFractionSched = Sched.GetSchedule(state, exhaustFlowFractionSchedName)
                if thisExhCtrl.exhaustFlowFractionSched is None:
                    ShowSevereItemNotFound(state, eoh, "Exhaust Flow Fraction Schedule Name", exhaustFlowFractionSchedName)

            thisExhCtrl.SupplyNodeOrNodelistName = ip.getAlphaFieldValue(objectFields, objectSchemaProps, "supply_node_or_nodelist_name")

            NodeListError = False
            NumParams = 0
            NumNodes = 0

            ip.getObjectDefMaxArgs(state, "NodeList", NumParams, NumAlphas, NumNums)
            thisExhCtrl.SuppNodeNums = [0] * NumParams
            Node.GetNodeNums(state,
                             thisExhCtrl.SupplyNodeOrNodelistName,
                             NumNodes,
                             thisExhCtrl.SuppNodeNums,
                             NodeListError,
                             Node.FluidType.Air,
                             Node.ConnectionObjectType.ZoneHVACExhaustControl,
                             thisExhCtrl.Name,
                             Node.ConnectionType.Sensor,
                             Node.CompFluidStream.Primary,
                             Node.ObjectIsNotParent)

            if thisExhCtrl.FlowControlOption == FlowControlType.FOLLOW_SUPPLY:
                nodeNotFound = False
                for i in range(1, len(thisExhCtrl.SuppNodeNums) + 1):
                    CheckForSupplyNode(state, exhCtrlNum, nodeNotFound)
                    if nodeNotFound:
                        ShowSevereError(state, f"{RoutineName}{cCurrentModuleObject}={thisExhCtrl.Name}")
                        ShowContinueError(state, f"Node or NodeList Name ={thisExhCtrl.SupplyNodeOrNodelistName}. Must all be supply nodes.")
                        ErrorsFound = True

            if thisExhCtrl.DesignExhaustFlowRate == DataSizing.AutoSize:
                SizeExhaustControlFlow(state, exhCtrlNum, thisExhCtrl.SuppNodeNums)

            minZoneTempLimitSchedName = ip.getAlphaFieldValue(objectFields, objectSchemaProps, "minimum_zone_temperature_limit_schedule_name")
            if minZoneTempLimitSchedName:
                thisExhCtrl.minZoneTempLimitSched = Sched.GetSchedule(state, minZoneTempLimitSchedName)
                if thisExhCtrl.minZoneTempLimitSched is None:
                    ShowSevereItemNotFound(state, eoh, "Minimum Zone Temperature Limit Schedule Name", minZoneTempLimitSchedName)

            minExhFlowFracSchedName = ip.getAlphaFieldValue(objectFields, objectSchemaProps, "minimum_exhaust_flow_fraction_schedule_name")
            if minExhFlowFracSchedName:
                thisExhCtrl.minExhFlowFracSched = Sched.GetSchedule(state, minExhFlowFracSchedName)
                if thisExhCtrl.minExhFlowFracSched is None:
                    ShowSevereItemNotFound(state, eoh, "Minimum Exhaust Flow Fraction Schedule Name", minExhFlowFracSchedName)

            balancedExhFracSchedName = ip.getAlphaFieldValue(objectFields, objectSchemaProps, "balanced_exhaust_fraction_schedule_name")
            if balancedExhFracSchedName:
                thisExhCtrl.balancedExhFracSched = Sched.GetSchedule(state, balancedExhFracSchedName)
                if thisExhCtrl.balancedExhFracSched is None:
                    ShowSevereItemNotFound(state, eoh, "Balanced Exhaust Fraction Schedule Name", balancedExhFracSchedName)

        state.dataZoneEquip.NumZoneExhaustControls = numZoneExhaustControls
        state.dataExhAirSystemMrg.mappingDone = True

    if ErrorsFound:
        ShowFatalError(state, "Errors found getting ZoneHVAC:ExhaustControl.  Preceding condition(s) causes termination.")


def SimZoneHVACExhaustControls(state: object) -> None:
    if state.dataExhCtrlSystemMrg.GetInputFlag:
        GetZoneExhaustControlInput(state)
        state.dataExhCtrlSystemMrg.GetInputFlag = False

    for ExhaustControlNum in range(1, state.dataZoneEquip.NumZoneExhaustControls + 1):
        CalcZoneHVACExhaustControl(state, ExhaustControlNum)


def CalcZoneHVACExhaustControl(state: object, ZoneHVACExhaustControlNum: int, FlowRatio: float = -1.0) -> None:
    thisExhCtrl = state.dataZoneEquip.ZoneExhaustControlSystem[ZoneHVACExhaustControlNum - 1]

    InletNode = thisExhCtrl.InletNodeNum
    OutletNode = thisExhCtrl.OutletNodeNum
    thisExhInlet = state.dataLoopNodes.Node[InletNode - 1]
    thisExhOutlet = state.dataLoopNodes.Node[OutletNode - 1]
    MassFlow = 0.0
    Tin = state.dataZoneTempPredictorCorrector.zoneHeatBalance[thisExhCtrl.ZoneNum - 1].ZT
    thisExhCtrlAvailScheVal = thisExhCtrl.availSched.getCurrentVal()

    if FlowRatio >= 0.0:
        thisExhCtrl.BalancedFlow *= FlowRatio
        thisExhCtrl.UnbalancedFlow *= FlowRatio
        thisExhInlet.MassFlowRate *= FlowRatio
    else:
        if thisExhCtrlAvailScheVal <= 0.0:
            MassFlow = 0.0
            thisExhInlet.MassFlowRate = 0.0
        else:
            pass

        DesignFlowRate = thisExhCtrl.DesignExhaustFlowRate
        FlowFrac = 1.0
        if thisExhCtrl.exhaustFlowFractionSched is not None:
            FlowFrac = thisExhCtrl.exhaustFlowFractionSched.getCurrentVal()
            if FlowFrac < 0.0:
                ShowWarningError(state, f"Exhaust Flow Fraction Schedule value is negative for Zone Exhaust Control Named: {thisExhCtrl.Name};")
                ShowContinueError(state, "Reset value to zero and continue the simulation.")
                FlowFrac = 0.0

        MinFlowFrac = 0.0
        if thisExhCtrl.minExhFlowFracSched is not None:
            MinFlowFrac = thisExhCtrl.minExhFlowFracSched.getCurrentVal()
            if MinFlowFrac < 0.0:
                ShowWarningError(state, f"Minimum Exhaust Flow Fraction Schedule value is negative for Zone Exhaust Control Named: {thisExhCtrl.Name};")
                ShowContinueError(state, "Reset value to zero and continue the simulation.")
                MinFlowFrac = 0.0

        if FlowFrac < MinFlowFrac:
            FlowFrac = MinFlowFrac

        if thisExhCtrlAvailScheVal > 0.0:
            if thisExhCtrl.minZoneTempLimitSched is not None:
                if Tin >= thisExhCtrl.minZoneTempLimitSched.getCurrentVal():
                    pass
                else:
                    FlowFrac = MinFlowFrac
            else:
                pass
        else:
            FlowFrac = 0.0

        if thisExhCtrl.FlowControlOption == FlowControlType.FOLLOW_SUPPLY:
            supplyFlowRate = 0.0
            numOfSuppNodes = len(thisExhCtrl.SuppNodeNums)
            for i in range(1, numOfSuppNodes + 1):
                supplyFlowRate += state.dataLoopNodes.Node[thisExhCtrl.SuppNodeNums[i - 1] - 1].MassFlowRate
            MassFlow = supplyFlowRate * FlowFrac
        else:
            MassFlow = DesignFlowRate * FlowFrac

        if thisExhCtrl.balancedExhFracSched is not None:
            thisExhCtrl.BalancedFlow = MassFlow * thisExhCtrl.balancedExhFracSched.getCurrentVal()
            thisExhCtrl.UnbalancedFlow = MassFlow - thisExhCtrl.BalancedFlow
        else:
            thisExhCtrl.BalancedFlow = 0.0
            thisExhCtrl.UnbalancedFlow = MassFlow

        thisExhInlet.MassFlowRate = MassFlow

    thisExhOutlet.MassFlowRate = thisExhInlet.MassFlowRate
    thisExhOutlet.Temp = thisExhInlet.Temp
    thisExhOutlet.HumRat = thisExhInlet.HumRat
    thisExhOutlet.Enthalpy = thisExhInlet.Enthalpy
    thisExhOutlet.Quality = thisExhInlet.Quality
    thisExhOutlet.Press = thisExhInlet.Press
    thisExhOutlet.MassFlowRateMax = thisExhInlet.MassFlowRateMax
    thisExhOutlet.MassFlowRateMaxAvail = thisExhInlet.MassFlowRateMaxAvail
    thisExhOutlet.MassFlowRateMinAvail = thisExhInlet.MassFlowRateMinAvail

    if state.dataContaminantBalance.Contaminant.CO2Simulation:
        thisExhOutlet.CO2 = thisExhInlet.CO2

    if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
        thisExhOutlet.GenContam = thisExhInlet.GenContam


def SizeExhaustSystem(state: object, exhSysNum: int) -> None:
    thisExhSys = state.dataZoneEquip.ExhaustAirSystem[exhSysNum - 1]

    if not thisExhSys.SizingFlag:
        return

    outletFlowMaxAvail = 0.0
    for i in range(1, state.dataMixerComponent.MixerCond[thisExhSys.ZoneMixerIndex - 1].NumInletNodes + 1):
        inletNode_index = state.dataMixerComponent.MixerCond[thisExhSys.ZoneMixerIndex - 1].InletNode[i - 1]
        outletFlowMaxAvail += state.dataLoopNodes.Node[inletNode_index - 1].MassFlowRateMaxAvail

    outletNode_index = state.dataMixerComponent.MixerCond[thisExhSys.ZoneMixerIndex - 1].OutletNode
    state.dataLoopNodes.Node[outletNode_index - 1].MassFlowRateMaxAvail = outletFlowMaxAvail

    fan = state.dataFans.fans[thisExhSys.CentralFanIndex - 1]
    if thisExhSys.centralFanType == HVAC.FanType.SystemModel:
        if fan.maxAirFlowRate == DataSizing.AutoSize:
            fan.maxAirFlowRate = outletFlowMaxAvail / state.dataEnvrn.StdRhoAir
        BaseSizer.reportSizerOutput(state, "FAN:SYSTEMMODEL", fan.Name, "Design Fan Airflow [m3/s]", fan.maxAirFlowRate)
    elif thisExhSys.centralFanType == HVAC.FanType.ComponentModel:
        if fan.maxAirMassFlowRate == DataSizing.AutoSize:
            fan.maxAirMassFlowRate = outletFlowMaxAvail * fan.sizingFactor
        BaseSizer.reportSizerOutput(state,
                                    HVAC.fanTypeNames[int(fan.type)],
                                    fan.Name,
                                    "Design Fan Airflow [m3/s]",
                                    fan.maxAirMassFlowRate / state.dataEnvrn.StdRhoAir)

    thisExhSys.SizingFlag = False


def SizeExhaustControlFlow(state: object, zoneExhCtrlNum: int, NodeNums: List[int]) -> None:
    thisExhCtrl = state.dataZoneEquip.ZoneExhaustControlSystem[zoneExhCtrlNum - 1]

    designFlow = 0.0

    if thisExhCtrl.FlowControlOption == FlowControlType.FOLLOW_SUPPLY:
        for i in range(1, len(NodeNums) + 1):
            designFlow += state.dataLoopNodes.Node[NodeNums[i - 1] - 1].MassFlowRateMax
    else:
        designFlow = state.dataSize.FinalZoneSizing[thisExhCtrl.ZoneNum - 1].MinOA

    thisExhCtrl.DesignExhaustFlowRate = designFlow


def UpdateZoneExhaustControl(state: object) -> None:
    for i in range(1, state.dataZoneEquip.NumZoneExhaustControls + 1):
        controlledZoneNum = state.dataZoneEquip.ZoneExhaustControlSystem[i - 1].ControlledZoneNum
        state.dataZoneEquip.ZoneEquipConfig[controlledZoneNum - 1].ZoneExh += \
            state.dataZoneEquip.ZoneExhaustControlSystem[i - 1].BalancedFlow + \
            state.dataZoneEquip.ZoneExhaustControlSystem[i - 1].UnbalancedFlow
        state.dataZoneEquip.ZoneEquipConfig[controlledZoneNum - 1].ZoneExhBalanced += \
            state.dataZoneEquip.ZoneExhaustControlSystem[i - 1].BalancedFlow


def CheckForSupplyNode(state: object, ExhCtrlNum: int, NodeNotFound: bool) -> None:
    thisExhCtrl = state.dataZoneEquip.ZoneExhaustControlSystem[ExhCtrlNum - 1]

    RoutineName = "GetExhaustControlInput: "
    CurrentModuleObject = "ZoneHVAC:ExhaustControl"

    ZoneNodeNotFound = True
    ErrorsFound = False
    for i in range(1, len(thisExhCtrl.SuppNodeNums) + 1):
        supplyNodeNum = thisExhCtrl.SuppNodeNums[i - 1]
        for NodeNum in range(1, state.dataZoneEquip.ZoneEquipConfig[thisExhCtrl.ZoneNum - 1].NumInletNodes + 1):
            if supplyNodeNum == state.dataZoneEquip.ZoneEquipConfig[thisExhCtrl.ZoneNum - 1].InletNode[NodeNum - 1]:
                ZoneNodeNotFound = False
                break
        if ZoneNodeNotFound:
            ShowSevereError(state, f"{RoutineName}{CurrentModuleObject}={thisExhCtrl.Name}")
            ShowContinueError(state,
                             f"Supply or supply list = \"{thisExhCtrl.SupplyNodeOrNodelistName}\" contains at least one node that is not a zone inlet node for Zone Name = \"{thisExhCtrl.ZoneName}\"")
            ShowContinueError(state, "..Nodes in the supply node or nodelist must be a zone inlet node.")
            ErrorsFound = True

    NodeNotFound = ErrorsFound


def ExhaustSystemHasMixer(state: object, CompName: str) -> bool:
    if state.dataExhAirSystemMrg.GetInputFlag:
        GetExhaustAirSystemInput(state)
        state.dataExhAirSystemMrg.GetInputFlag = False

    return FindItemInList(CompName, state.dataZoneEquip.ExhaustAirSystem, ZoneMixerName_attr="ZoneMixerName") > 0


def getEnumValue(names_list: List[str], target: str) -> int:
    for i, name in enumerate(names_list):
        if name == target:
            return i
    return -1


def FindItemInList(target: str, items: List, attr: str = None) -> int:
    for i, item in enumerate(items):
        if attr:
            if getattr(item, attr, "") == target:
                return i + 1
        else:
            if str(item) == target:
                return i + 1
    return 0


def ValidateComponent(state: object, CompType: str, CompName: str, IsNotOK: bool, ComponentContext: str) -> None:
    pass


def ShowSevereError(state: object, msg: str) -> None:
    pass


def ShowContinueError(state: object, msg: str) -> None:
    pass


def ShowFatalError(state: object, msg: str) -> None:
    pass


def ShowWarningError(state: object, msg: str) -> None:
    pass


def ShowSevereItemNotFound(state: object, eoh: object, field: str, value: str) -> None:
    pass


def ShowWarningItemNotFound(state: object, eoh: object, field: str, value: str, msg: str) -> None:
    pass


def SetupOutputVariable(state: object, name: str, units: str, obj: object, attr: str, timestep: str, storetype: str, varname: str) -> None:
    pass


class ErrorObjectHeader:
    def __init__(self, routine: str, module: str, name: str):
        self.routine = routine
        self.module = module
        self.name = name


# Stub modules
class HVAC:
    class FanType(Enum):
        Invalid = -1
        SystemModel = 0
        ComponentModel = 1

    fanTypeNames = ["Invalid", "SystemModel", "ComponentModel"]
    fanTypeNamesUC = ["INVALID", "SYSTEMMODEL", "COMPONENTMODEL"]
    SmallMassFlow = 1e-10


class Sched:
    @staticmethod
    def GetScheduleAlwaysOn(state: object):
        pass

    @staticmethod
    def GetSchedule(state: object, name: str):
        pass


class Node:
    class ConnectionObjectType:
        ZoneHVACExhaustControl = "ZoneHVAC:ExhaustControl"

    class FluidType:
        Air = "Air"

    class ConnectionType:
        Inlet = "Inlet"
        Outlet = "Outlet"
        Sensor = "Sensor"

    class CompFluidStream:
        Primary = 1

    class ObjectIsParent:
        pass

    class ObjectIsNotParent:
        pass

    @staticmethod
    def GetOnlySingleNode(state: object, name: str, errors_found: bool, conn_type: object,
                          comp_name: str, fluid_type: str, conn_dir: str, stream: int, obj_parent: object):
        pass

    @staticmethod
    def GetNodeNums(state: object, name: str, num_nodes: int, node_nums: List[int],
                    node_list_error: bool, fluid_type: str, conn_type: object, comp_name: str,
                    conn_dir: str, stream: int, obj_parent: object):
        pass

    @staticmethod
    def SetUpCompSets(state: object, module: str, name: str, fan_type: str, fan_name: str, inlet: str, outlet: str):
        pass


class MixerComponent:
    @staticmethod
    def GetZoneMixerIndex(state: object, name: str, index: int, err_found: bool, comp_name: str):
        pass

    @staticmethod
    def InitAirMixer(state: object, index: int):
        pass

    @staticmethod
    def SimAirMixer(state: object, name: str, index: int):
        pass


class Fans:
    @staticmethod
    def GetFanIndex(state: object, name: str):
        pass


class DataSizing:
    AutoSize = -99999


class Psychrometrics:
    @staticmethod
    def PsyRhoAirFnPbTdbW(state: object, pb: float, tdb: float, w: float):
        pass


class BaseSizer:
    @staticmethod
    def reportSizerOutput(state: object, type_str: str, name: str, field: str, value: float):
        pass
