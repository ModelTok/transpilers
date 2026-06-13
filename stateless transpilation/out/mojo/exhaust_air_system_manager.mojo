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

from math import fabs


alias Real64 = Float64


@register_passable
struct FlowControlType:
    var value: Int32

    @staticmethod
    fn Invalid() -> FlowControlType:
        return FlowControlType(-1)

    @staticmethod
    fn Scheduled() -> FlowControlType:
        return FlowControlType(0)

    @staticmethod
    fn FollowSupply() -> FlowControlType:
        return FlowControlType(1)

    @staticmethod
    fn Num() -> FlowControlType:
        return FlowControlType(2)


struct ExhaustAir:
    var Name: String
    var availSched: AnyType
    var ZoneMixerName: String
    var ZoneMixerIndex: Int32
    var centralFanType: AnyType
    var CentralFanName: String
    var CentralFanIndex: Int32
    var SizingFlag: Bool
    var centralFan_MassFlowRate: Real64
    var centralFan_VolumeFlowRate_Std: Real64
    var centralFan_VolumeFlowRate_Cur: Real64
    var centralFan_Power: Real64
    var centralFan_Energy: Real64
    var exhTotalHVACReliefHeatLoss: Real64

    fn __init__(inout self):
        self.Name = ""
        self.availSched = AnyType()
        self.ZoneMixerName = ""
        self.ZoneMixerIndex = 0
        self.centralFanType = AnyType()
        self.CentralFanName = ""
        self.CentralFanIndex = 0
        self.SizingFlag = True
        self.centralFan_MassFlowRate = 0.0
        self.centralFan_VolumeFlowRate_Std = 0.0
        self.centralFan_VolumeFlowRate_Cur = 0.0
        self.centralFan_Power = 0.0
        self.centralFan_Energy = 0.0
        self.exhTotalHVACReliefHeatLoss = 0.0


struct ZoneExhaustControl:
    var Name: String
    var availSched: AnyType
    var ZoneName: String
    var ZoneNum: Int32
    var ControlledZoneNum: Int32
    var InletNodeNum: Int32
    var OutletNodeNum: Int32
    var DesignExhaustFlowRate: Real64
    var FlowControlOption: FlowControlType
    var exhaustFlowFractionSched: AnyType
    var SupplyNodeOrNodelistName: String
    var SupplyNodeOrNodelistNum: Int32
    var minZoneTempLimitSched: AnyType
    var minExhFlowFracSched: AnyType
    var balancedExhFracSched: AnyType
    var BalancedFlow: Real64
    var UnbalancedFlow: Real64
    var SuppNodeNums: DynamicVector[Int32]

    fn __init__(inout self):
        self.Name = ""
        self.availSched = AnyType()
        self.ZoneName = ""
        self.ZoneNum = 0
        self.ControlledZoneNum = 0
        self.InletNodeNum = 0
        self.OutletNodeNum = 0
        self.DesignExhaustFlowRate = 0.0
        self.FlowControlOption = FlowControlType.Scheduled()
        self.exhaustFlowFractionSched = AnyType()
        self.SupplyNodeOrNodelistName = ""
        self.SupplyNodeOrNodelistNum = 0
        self.minZoneTempLimitSched = AnyType()
        self.minExhFlowFracSched = AnyType()
        self.balancedExhFracSched = AnyType()
        self.BalancedFlow = 0.0
        self.UnbalancedFlow = 0.0
        self.SuppNodeNums = DynamicVector[Int32]()


struct ExhaustAirSystemMgr:
    var GetInputFlag: Bool
    var mixerIndexMap: DynamicVector[Tuple[Int32, Int32]]
    var mappingDone: Bool

    fn __init__(inout self):
        self.GetInputFlag = True
        self.mixerIndexMap = DynamicVector[Tuple[Int32, Int32]]()
        self.mappingDone = False


struct ExhaustControlSystemMgr:
    var GetInputFlag: Bool

    fn __init__(inout self):
        self.GetInputFlag = True


fn SimExhaustAirSystem(inout state: AnyType, FirstHVACIteration: Bool) -> None:
    if state.dataExhAirSystemMrg.GetInputFlag:
        GetExhaustAirSystemInput(inout state)
        state.dataExhAirSystemMrg.GetInputFlag = False

    for ExhaustAirSystemNum in range(1, state.dataZoneEquip.NumExhaustAirSystems + 1):
        CalcExhaustAirSystem(inout state, ExhaustAirSystemNum, FirstHVACIteration)

    UpdateZoneExhaustControl(inout state)


fn GetExhaustAirSystemInput(inout state: AnyType) -> None:
    if not state.dataExhAirSystemMrg.GetInputFlag:
        return

    var ErrorsFound: Bool = False
    let RoutineName: StringLiteral = "GetExhaustAirSystemInput: "
    let routineName: StringLiteral = "GetExhaustAirSystemInput"
    let cCurrentModuleObject: String = "AirLoopHVAC:ExhaustSystem"

    let ip = state.dataInputProcessing.inputProcessor
    let instances = ip.epJSON.get(cCurrentModuleObject)

    if instances is not None:
        let objectSchemaProps = ip.getObjectSchemaProps(inout state, cCurrentModuleObject)
        let numExhaustSystems: Int32 = instances.size()
        var exhSysNum: Int32 = 0

        if numExhaustSystems > 0:
            state.dataZoneEquip.ExhaustAirSystem = DynamicVector[ExhaustAir](capacity=numExhaustSystems)

        for instance_key in instances.keys():
            exhSysNum += 1
            let objectFields = instances[instance_key]
            var thisExhSys = state.dataZoneEquip.ExhaustAirSystem[exhSysNum - 1]
            thisExhSys.Name = makeUPPER(instance_key)
            ip.markObjectAsUsed(cCurrentModuleObject, instance_key)

            let zoneMixerName: String = ip.getAlphaFieldValue(objectFields, objectSchemaProps, "zone_mixer_name")
            var zoneMixerIndex: Int32 = 0
            var zoneMixerErrFound: Bool = False
            MixerComponent.GetZoneMixerIndex(inout state, zoneMixerName, inout zoneMixerIndex, inout zoneMixerErrFound, thisExhSys.Name)

            if not zoneMixerErrFound:
                MixerComponent.InitAirMixer(inout state, zoneMixerIndex)
                var IsNotOK: Bool = False
                ValidateComponent(inout state, "AirLoopHVAC:ZoneMixer", zoneMixerName, inout IsNotOK, "AirLoopHVAC:ExhaustSystem")
                if IsNotOK:
                    ShowSevereError(inout state, RoutineName + cCurrentModuleObject + "=" + thisExhSys.Name)
                    ShowContinueError(inout state, "ZoneMixer Name =" + zoneMixerName + " mismatch or not found.")
                    ErrorsFound = True
            else:
                ShowSevereError(inout state, RoutineName + cCurrentModuleObject + "=" + thisExhSys.Name)
                ShowContinueError(inout state, "Zone Mixer Name =" + zoneMixerName + " not found.")
                ErrorsFound = True

            thisExhSys.ZoneMixerName = zoneMixerName
            thisExhSys.ZoneMixerIndex = zoneMixerIndex

            let fanTypeStr: String = makeUPPER(ip.getAlphaFieldValue(objectFields, objectSchemaProps, "fan_object_type"))
            thisExhSys.centralFanType = getEnumValue(hvac_fanTypeNamesUC(), fanTypeStr)

            if thisExhSys.centralFanType != hvac_FanType_SystemModel() and thisExhSys.centralFanType != hvac_FanType_ComponentModel():
                ShowSevereError(inout state, RoutineName + cCurrentModuleObject + "=" + thisExhSys.Name)
                ShowContinueError(inout state, "Fan Type =" + hvac_fanTypeNames()[Int32(thisExhSys.centralFanType)] + " is not supported.")
                ShowContinueError(inout state, "It needs to be either a Fan:SystemModel or a Fan:ComponentModel type.")
                ErrorsFound = True

            let centralFanName: String = ip.getAlphaFieldValue(objectFields, objectSchemaProps, "fan_name")
            var eoh: ErrorObjectHeader = ErrorObjectHeader(routineName, cCurrentModuleObject, thisExhSys.Name)
            let centralFanIndex: Int32 = Fans.GetFanIndex(inout state, centralFanName)

            if centralFanIndex == 0:
                ShowSevereItemNotFound(inout state, eoh, "fan_name", centralFanName)
                ErrorsFound = True
            else:
                let fan = state.dataFans.fans[centralFanIndex - 1]
                thisExhSys.availSched = fan.availSched

                Node.SetUpCompSets(inout state,
                                   cCurrentModuleObject,
                                   thisExhSys.Name,
                                   hvac_fanTypeNames()[Int32(thisExhSys.centralFanType)],
                                   centralFanName,
                                   state.dataLoopNodes.NodeID(fan.inletNodeNum),
                                   state.dataLoopNodes.NodeID(fan.outletNodeNum))

                SetupOutputVariable(inout state,
                                    "Central Exhaust Fan Mass Flow Rate",
                                    "kg/s",
                                    thisExhSys, "centralFan_MassFlowRate",
                                    "System", "Average", thisExhSys.Name)

                SetupOutputVariable(inout state,
                                    "Central Exhaust Fan Volumetric Flow Rate Standard",
                                    "m3/s",
                                    thisExhSys, "centralFan_VolumeFlowRate_Std",
                                    "System", "Average", thisExhSys.Name)

                SetupOutputVariable(inout state,
                                    "Central Exhaust Fan Volumetric Flow Rate Current",
                                    "m3/s",
                                    thisExhSys, "centralFan_VolumeFlowRate_Cur",
                                    "System", "Average", thisExhSys.Name)

                SetupOutputVariable(inout state,
                                    "Central Exhaust Fan Power",
                                    "W",
                                    thisExhSys, "centralFan_Power",
                                    "System", "Average", thisExhSys.Name)

                SetupOutputVariable(inout state,
                                    "Central Exhaust Fan Energy",
                                    "J",
                                    thisExhSys, "centralFan_Energy",
                                    "System", "Sum", thisExhSys.Name)

            thisExhSys.CentralFanName = centralFanName
            thisExhSys.CentralFanIndex = centralFanIndex

            if thisExhSys.SizingFlag:
                SizeExhaustSystem(inout state, exhSysNum)

        state.dataZoneEquip.NumExhaustAirSystems = numExhaustSystems

    if ErrorsFound:
        ShowFatalError(inout state, "Errors found getting AirLoopHVAC:ExhaustSystem.  Preceding condition(s) causes termination.")


fn CalcExhaustAirSystem(inout state: AnyType, ExhaustAirSystemNum: Int32, FirstHVACIteration: Bool) -> None:
    var thisExhSys = state.dataZoneEquip.ExhaustAirSystem[ExhaustAirSystemNum - 1]
    let RoutineName: StringLiteral = "CalExhaustAirSystem: "
    let cCurrentModuleObject: StringLiteral = "AirloopHVAC:ExhaustSystem"
    var ErrorsFound: Bool = False

    if not (state.afn.AirflowNetworkFanActivated and state.afn.distribution_simulated):
        MixerComponent.SimAirMixer(inout state, thisExhSys.ZoneMixerName, thisExhSys.ZoneMixerIndex)
    else:
        ShowSevereError(inout state, RoutineName + cCurrentModuleObject + "=" + thisExhSys.Name)
        ShowContinueError(inout state, "AirloopHVAC:ExhaustSystem currently does not work with AirflowNetwork.")
        ErrorsFound = True

    if ErrorsFound:
        ShowFatalError(inout state, "Errors found conducting CalcExhasutAirSystem(). Preceding condition(s) causes termination.")

    var mixerFlow_Prior: Real64 = 0.0
    let outletNode_index: Int32 = state.dataMixerComponent.MixerCond[thisExhSys.ZoneMixerIndex - 1].OutletNode
    mixerFlow_Prior = state.dataLoopNodes.Node[outletNode_index - 1].MassFlowRate

    var outletNode_Num: Int32 = 0
    var RhoAirCurrent: Real64 = state.dataEnvrn.StdRhoAir

    if thisExhSys.centralFanType == hvac_FanType_SystemModel():
        state.dataHVACGlobal.OnOffFanPartLoadFraction = 1.0
        state.dataFans.fans[thisExhSys.CentralFanIndex - 1].simulate(inout state, False)

        outletNode_Num = state.dataFans.fans[thisExhSys.CentralFanIndex - 1].outletNodeNum

        thisExhSys.centralFan_MassFlowRate = state.dataLoopNodes.Node[outletNode_Num - 1].MassFlowRate
        thisExhSys.centralFan_VolumeFlowRate_Std = state.dataLoopNodes.Node[outletNode_Num - 1].MassFlowRate / state.dataEnvrn.StdRhoAir

        RhoAirCurrent = Psychrometrics.PsyRhoAirFnPbTdbW(inout state,
                                                         state.dataEnvrn.OutBaroPress,
                                                         state.dataLoopNodes.Node[outletNode_Num - 1].Temp,
                                                         state.dataLoopNodes.Node[outletNode_Num - 1].HumRat)
        if RhoAirCurrent <= 0.0:
            RhoAirCurrent = state.dataEnvrn.StdRhoAir
        thisExhSys.centralFan_VolumeFlowRate_Cur = state.dataLoopNodes.Node[outletNode_Num - 1].MassFlowRate / RhoAirCurrent

        thisExhSys.centralFan_Power = state.dataFans.fans[thisExhSys.CentralFanIndex - 1].totalPower
        thisExhSys.centralFan_Energy = thisExhSys.centralFan_Power * state.dataHVACGlobal.TimeStepSysSec

    elif thisExhSys.centralFanType == hvac_FanType_ComponentModel():
        let fan = state.dataFans.fans[thisExhSys.CentralFanIndex - 1]
        fan.simulate(inout state, FirstHVACIteration)

        outletNode_Num = fan.outletNodeNum
        thisExhSys.centralFan_MassFlowRate = fan.outletAirMassFlowRate
        thisExhSys.centralFan_VolumeFlowRate_Std = fan.outletAirMassFlowRate / state.dataEnvrn.StdRhoAir

        RhoAirCurrent = Psychrometrics.PsyRhoAirFnPbTdbW(inout state,
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

    var mixerFlow_Posterior: Real64 = 0.0
    mixerFlow_Posterior = state.dataLoopNodes.Node[outletNode_index - 1].MassFlowRate

    if fabs(mixerFlow_Prior - mixerFlow_Posterior) > hvac_SmallMassFlow():
        var flowRatio: Real64 = mixerFlow_Posterior / mixerFlow_Prior
        if flowRatio > 1.0:
            ShowWarningError(inout state, RoutineName + cCurrentModuleObject + "=" + thisExhSys.Name)
            ShowContinueError(inout state, "Requested flow rate is lower than the exhasut fan flow rate.")
            ShowContinueError(inout state, "Will scale up the requested flow rate to meet fan flow rate.")

        let zoneMixerIndex: Int32 = thisExhSys.ZoneMixerIndex
        for i in range(1, state.dataMixerComponent.MixerCond[zoneMixerIndex - 1].NumInletNodes + 1):
            let exhLegIndex: Int32 = state.dataExhAirSystemMrg.mixerIndexMap.get(state.dataMixerComponent.MixerCond[zoneMixerIndex - 1].InletNode[i - 1])
            CalcZoneHVACExhaustControl(inout state, exhLegIndex, flowRatio)

        MixerComponent.SimAirMixer(inout state, thisExhSys.ZoneMixerName, thisExhSys.ZoneMixerIndex)


fn GetZoneExhaustControlInput(inout state: AnyType) -> None:
    var ErrorsFound: Bool = False
    let RoutineName: StringLiteral = "GetZoneExhaustControlInput: "
    let routineName: StringLiteral = "GetZoneExhaustControlInput"
    let cCurrentModuleObject: String = "ZoneHVAC:ExhaustControl"

    let ip = state.dataInputProcessing.inputProcessor
    let instances = ip.epJSON.get(cCurrentModuleObject)

    if instances is not None:
        let objectSchemaProps = ip.getObjectSchemaProps(inout state, cCurrentModuleObject)
        let numZoneExhaustControls: Int32 = instances.size()
        var exhCtrlNum: Int32 = 0

        if numZoneExhaustControls > 0:
            state.dataZoneEquip.ZoneExhaustControlSystem = DynamicVector[ZoneExhaustControl](capacity=numZoneExhaustControls)

        for instance_key in instances.keys():
            exhCtrlNum += 1
            let objectFields = instances[instance_key]
            var thisExhCtrl = state.dataZoneEquip.ZoneExhaustControlSystem[exhCtrlNum - 1]
            var eoh: ErrorObjectHeader = ErrorObjectHeader(routineName, cCurrentModuleObject, instance_key)

            thisExhCtrl.Name = makeUPPER(instance_key)
            ip.markObjectAsUsed(cCurrentModuleObject, instance_key)

            let availSchName: String = ip.getAlphaFieldValue(objectFields, objectSchemaProps, "availability_schedule_name")
            if availSchName.size() == 0:
                thisExhCtrl.availSched = Sched.GetScheduleAlwaysOn(inout state)
            else:
                thisExhCtrl.availSched = Sched.GetSchedule(inout state, availSchName)
                if thisExhCtrl.availSched is None:
                    thisExhCtrl.availSched = Sched.GetScheduleAlwaysOn(inout state)
                    ShowWarningItemNotFound(inout state, eoh, "Availability Schedule Name", availSchName, "Availability Schedule is reset to Always ON.")

            let zoneName: String = ip.getAlphaFieldValue(objectFields, objectSchemaProps, "zone_name")
            thisExhCtrl.ZoneName = zoneName
            let zoneNum: Int32 = FindItemInList(zoneName, state.dataHeatBal.Zone)
            thisExhCtrl.ZoneNum = zoneNum
            thisExhCtrl.ControlledZoneNum = FindItemInList(zoneName, state.dataHeatBal.Zone)

            let inletNodeName: String = ip.getAlphaFieldValue(objectFields, objectSchemaProps, "inlet_node_name")
            let inletNodeNum: Int32 = Node.GetOnlySingleNode(inout state,
                                                             inletNodeName,
                                                             ErrorsFound,
                                                             Node.ConnectionObjectType.ZoneHVACExhaustControl(),
                                                             thisExhCtrl.Name,
                                                             Node.FluidType.Air(),
                                                             Node.ConnectionType.Inlet(),
                                                             Node.CompFluidStream.Primary(),
                                                             Node.ObjectIsParent())
            thisExhCtrl.InletNodeNum = inletNodeNum

            let outletNodeName: String = ip.getAlphaFieldValue(objectFields, objectSchemaProps, "outlet_node_name")
            let outletNodeNum: Int32 = Node.GetOnlySingleNode(inout state,
                                                              outletNodeName,
                                                              ErrorsFound,
                                                              Node.ConnectionObjectType.ZoneHVACExhaustControl(),
                                                              thisExhCtrl.Name,
                                                              Node.FluidType.Air(),
                                                              Node.ConnectionType.Outlet(),
                                                              Node.CompFluidStream.Primary(),
                                                              Node.ObjectIsParent())
            thisExhCtrl.OutletNodeNum = outletNodeNum

            if not state.dataExhAirSystemMrg.mappingDone:
                state.dataExhAirSystemMrg.mixerIndexMap.push_back((outletNodeNum, exhCtrlNum))

            let designExhaustFlowRate: Real64 = ip.getRealFieldValue(objectFields, objectSchemaProps, "design_exhaust_flow_rate")
            thisExhCtrl.DesignExhaustFlowRate = designExhaustFlowRate

            let flowControlTypeName: String = makeUPPER(ip.getAlphaFieldValue(objectFields, objectSchemaProps, "flow_control_type"))
            let flowControlEnumVal: Int32 = getEnumValue(FLOW_CONTROL_TYPE_NAMES_UC(), flowControlTypeName)
            if flowControlEnumVal == 0:
                thisExhCtrl.FlowControlOption = FlowControlType.Scheduled()
            elif flowControlEnumVal == 1:
                thisExhCtrl.FlowControlOption = FlowControlType.FollowSupply()

            let exhaustFlowFractionSchedName: String = ip.getAlphaFieldValue(objectFields, objectSchemaProps, "exhaust_flow_fraction_schedule_name")
            if exhaustFlowFractionSchedName.size() == 0:
                thisExhCtrl.exhaustFlowFractionSched = Sched.GetScheduleAlwaysOn(inout state)
            else:
                thisExhCtrl.exhaustFlowFractionSched = Sched.GetSchedule(inout state, exhaustFlowFractionSchedName)
                if thisExhCtrl.exhaustFlowFractionSched is None:
                    ShowSevereItemNotFound(inout state, eoh, "Exhaust Flow Fraction Schedule Name", exhaustFlowFractionSchedName)

            thisExhCtrl.SupplyNodeOrNodelistName = ip.getAlphaFieldValue(objectFields, objectSchemaProps, "supply_node_or_nodelist_name")

            var NodeListError: Bool = False
            var NumParams: Int32 = 0
            var NumNodes: Int32 = 0
            var NumAlphas: Int32 = 0
            var NumNums: Int32 = 0

            ip.getObjectDefMaxArgs(inout state, "NodeList", NumParams, NumAlphas, NumNums)
            thisExhCtrl.SuppNodeNums = DynamicVector[Int32](capacity=NumParams)
            Node.GetNodeNums(inout state,
                             thisExhCtrl.SupplyNodeOrNodelistName,
                             NumNodes,
                             thisExhCtrl.SuppNodeNums,
                             NodeListError,
                             Node.FluidType.Air(),
                             Node.ConnectionObjectType.ZoneHVACExhaustControl(),
                             thisExhCtrl.Name,
                             Node.ConnectionType.Sensor(),
                             Node.CompFluidStream.Primary(),
                             Node.ObjectIsNotParent())

            if thisExhCtrl.FlowControlOption.value == FlowControlType.FollowSupply().value:
                var nodeNotFound: Bool = False
                for i in range(1, thisExhCtrl.SuppNodeNums.size() + 1):
                    CheckForSupplyNode(inout state, exhCtrlNum, inout nodeNotFound)
                    if nodeNotFound:
                        ShowSevereError(inout state, RoutineName + cCurrentModuleObject + "=" + thisExhCtrl.Name)
                        ShowContinueError(inout state, "Node or NodeList Name =" + thisExhCtrl.SupplyNodeOrNodelistName + ". Must all be supply nodes.")
                        ErrorsFound = True

            if thisExhCtrl.DesignExhaustFlowRate == DataSizing.AutoSize():
                SizeExhaustControlFlow(inout state, exhCtrlNum, thisExhCtrl.SuppNodeNums)

            let minZoneTempLimitSchedName: String = ip.getAlphaFieldValue(objectFields, objectSchemaProps, "minimum_zone_temperature_limit_schedule_name")
            if minZoneTempLimitSchedName.size() > 0:
                thisExhCtrl.minZoneTempLimitSched = Sched.GetSchedule(inout state, minZoneTempLimitSchedName)
                if thisExhCtrl.minZoneTempLimitSched is None:
                    ShowSevereItemNotFound(inout state, eoh, "Minimum Zone Temperature Limit Schedule Name", minZoneTempLimitSchedName)

            let minExhFlowFracSchedName: String = ip.getAlphaFieldValue(objectFields, objectSchemaProps, "minimum_exhaust_flow_fraction_schedule_name")
            if minExhFlowFracSchedName.size() > 0:
                thisExhCtrl.minExhFlowFracSched = Sched.GetSchedule(inout state, minExhFlowFracSchedName)
                if thisExhCtrl.minExhFlowFracSched is None:
                    ShowSevereItemNotFound(inout state, eoh, "Minimum Exhaust Flow Fraction Schedule Name", minExhFlowFracSchedName)

            let balancedExhFracSchedName: String = ip.getAlphaFieldValue(objectFields, objectSchemaProps, "balanced_exhaust_fraction_schedule_name")
            if balancedExhFracSchedName.size() > 0:
                thisExhCtrl.balancedExhFracSched = Sched.GetSchedule(inout state, balancedExhFracSchedName)
                if thisExhCtrl.balancedExhFracSched is None:
                    ShowSevereItemNotFound(inout state, eoh, "Balanced Exhaust Fraction Schedule Name", balancedExhFracSchedName)

        state.dataZoneEquip.NumZoneExhaustControls = numZoneExhaustControls
        state.dataExhAirSystemMrg.mappingDone = True

    if ErrorsFound:
        ShowFatalError(inout state, "Errors found getting ZoneHVAC:ExhaustControl.  Preceding condition(s) causes termination.")


fn SimZoneHVACExhaustControls(inout state: AnyType) -> None:
    if state.dataExhCtrlSystemMrg.GetInputFlag:
        GetZoneExhaustControlInput(inout state)
        state.dataExhCtrlSystemMrg.GetInputFlag = False

    for ExhaustControlNum in range(1, state.dataZoneEquip.NumZoneExhaustControls + 1):
        CalcZoneHVACExhaustControl(inout state, ExhaustControlNum)


fn CalcZoneHVACExhaustControl(inout state: AnyType, ZoneHVACExhaustControlNum: Int32, FlowRatio: Real64 = -1.0) -> None:
    var thisExhCtrl = state.dataZoneEquip.ZoneExhaustControlSystem[ZoneHVACExhaustControlNum - 1]

    let InletNode: Int32 = thisExhCtrl.InletNodeNum
    let OutletNode: Int32 = thisExhCtrl.OutletNodeNum
    var thisExhInlet = state.dataLoopNodes.Node[InletNode - 1]
    var thisExhOutlet = state.dataLoopNodes.Node[OutletNode - 1]
    var MassFlow: Real64 = 0.0
    let Tin: Real64 = state.dataZoneTempPredictorCorrector.zoneHeatBalance[thisExhCtrl.ZoneNum - 1].ZT
    let thisExhCtrlAvailScheVal: Real64 = thisExhCtrl.availSched.getCurrentVal()

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

        let DesignFlowRate: Real64 = thisExhCtrl.DesignExhaustFlowRate
        var FlowFrac: Real64 = 1.0
        if thisExhCtrl.exhaustFlowFractionSched is not None:
            FlowFrac = thisExhCtrl.exhaustFlowFractionSched.getCurrentVal()
            if FlowFrac < 0.0:
                ShowWarningError(inout state, "Exhaust Flow Fraction Schedule value is negative for Zone Exhaust Control Named: " + thisExhCtrl.Name + ";")
                ShowContinueError(inout state, "Reset value to zero and continue the simulation.")
                FlowFrac = 0.0

        var MinFlowFrac: Real64 = 0.0
        if thisExhCtrl.minExhFlowFracSched is not None:
            MinFlowFrac = thisExhCtrl.minExhFlowFracSched.getCurrentVal()
            if MinFlowFrac < 0.0:
                ShowWarningError(inout state, "Minimum Exhaust Flow Fraction Schedule value is negative for Zone Exhaust Control Named: " + thisExhCtrl.Name + ";")
                ShowContinueError(inout state, "Reset value to zero and continue the simulation.")
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

        if thisExhCtrl.FlowControlOption.value == FlowControlType.FollowSupply().value:
            var supplyFlowRate: Real64 = 0.0
            let numOfSuppNodes: Int32 = Int32(thisExhCtrl.SuppNodeNums.size())
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


fn SizeExhaustSystem(inout state: AnyType, exhSysNum: Int32) -> None:
    var thisExhSys = state.dataZoneEquip.ExhaustAirSystem[exhSysNum - 1]

    if not thisExhSys.SizingFlag:
        return

    var outletFlowMaxAvail: Real64 = 0.0
    for i in range(1, state.dataMixerComponent.MixerCond[thisExhSys.ZoneMixerIndex - 1].NumInletNodes + 1):
        let inletNode_index: Int32 = state.dataMixerComponent.MixerCond[thisExhSys.ZoneMixerIndex - 1].InletNode[i - 1]
        outletFlowMaxAvail += state.dataLoopNodes.Node[inletNode_index - 1].MassFlowRateMaxAvail

    let outletNode_index: Int32 = state.dataMixerComponent.MixerCond[thisExhSys.ZoneMixerIndex - 1].OutletNode
    state.dataLoopNodes.Node[outletNode_index - 1].MassFlowRateMaxAvail = outletFlowMaxAvail

    let fan = state.dataFans.fans[thisExhSys.CentralFanIndex - 1]
    if thisExhSys.centralFanType == hvac_FanType_SystemModel():
        if fan.maxAirFlowRate == DataSizing.AutoSize():
            fan.maxAirFlowRate = outletFlowMaxAvail / state.dataEnvrn.StdRhoAir
        BaseSizer.reportSizerOutput(inout state, "FAN:SYSTEMMODEL", fan.Name, "Design Fan Airflow [m3/s]", fan.maxAirFlowRate)
    elif thisExhSys.centralFanType == hvac_FanType_ComponentModel():
        if fan.maxAirMassFlowRate == DataSizing.AutoSize():
            fan.maxAirMassFlowRate = outletFlowMaxAvail * fan.sizingFactor
        BaseSizer.reportSizerOutput(inout state,
                                    hvac_fanTypeNames()[Int32(fan.type)],
                                    fan.Name,
                                    "Design Fan Airflow [m3/s]",
                                    fan.maxAirMassFlowRate / state.dataEnvrn.StdRhoAir)

    thisExhSys.SizingFlag = False


fn SizeExhaustControlFlow(inout state: AnyType, zoneExhCtrlNum: Int32, NodeNums: DynamicVector[Int32]) -> None:
    var thisExhCtrl = state.dataZoneEquip.ZoneExhaustControlSystem[zoneExhCtrlNum - 1]

    var designFlow: Real64 = 0.0

    if thisExhCtrl.FlowControlOption.value == FlowControlType.FollowSupply().value:
        for i in range(1, Int32(NodeNums.size()) + 1):
            designFlow += state.dataLoopNodes.Node[NodeNums[i - 1] - 1].MassFlowRateMax
    else:
        designFlow = state.dataSize.FinalZoneSizing[thisExhCtrl.ZoneNum - 1].MinOA

    thisExhCtrl.DesignExhaustFlowRate = designFlow


fn UpdateZoneExhaustControl(inout state: AnyType) -> None:
    for i in range(1, state.dataZoneEquip.NumZoneExhaustControls + 1):
        let controlledZoneNum: Int32 = state.dataZoneEquip.ZoneExhaustControlSystem[i - 1].ControlledZoneNum
        state.dataZoneEquip.ZoneEquipConfig[controlledZoneNum - 1].ZoneExh += \
            state.dataZoneEquip.ZoneExhaustControlSystem[i - 1].BalancedFlow + \
            state.dataZoneEquip.ZoneExhaustControlSystem[i - 1].UnbalancedFlow
        state.dataZoneEquip.ZoneEquipConfig[controlledZoneNum - 1].ZoneExhBalanced += \
            state.dataZoneEquip.ZoneExhaustControlSystem[i - 1].BalancedFlow


fn CheckForSupplyNode(inout state: AnyType, ExhCtrlNum: Int32, inout NodeNotFound: Bool) -> None:
    var thisExhCtrl = state.dataZoneEquip.ZoneExhaustControlSystem[ExhCtrlNum - 1]

    let RoutineName: StringLiteral = "GetExhaustControlInput: "
    let CurrentModuleObject: StringLiteral = "ZoneHVAC:ExhaustControl"

    var ZoneNodeNotFound: Bool = True
    var ErrorsFound: Bool = False
    for i in range(1, Int32(thisExhCtrl.SuppNodeNums.size()) + 1):
        let supplyNodeNum: Int32 = thisExhCtrl.SuppNodeNums[i - 1]
        for NodeNum in range(1, state.dataZoneEquip.ZoneEquipConfig[thisExhCtrl.ZoneNum - 1].NumInletNodes + 1):
            if supplyNodeNum == state.dataZoneEquip.ZoneEquipConfig[thisExhCtrl.ZoneNum - 1].InletNode[NodeNum - 1]:
                ZoneNodeNotFound = False
                break
        if ZoneNodeNotFound:
            ShowSevereError(inout state, RoutineName + CurrentModuleObject + "=" + thisExhCtrl.Name)
            ShowContinueError(inout state,
                             "Supply or supply list = \"" + thisExhCtrl.SupplyNodeOrNodelistName + "\" contains at least one node that is not a zone inlet node for Zone Name = \"" + thisExhCtrl.ZoneName + "\"")
            ShowContinueError(inout state, "..Nodes in the supply node or nodelist must be a zone inlet node.")
            ErrorsFound = True

    NodeNotFound = ErrorsFound


fn ExhaustSystemHasMixer(inout state: AnyType, CompName: String) -> Bool:
    if state.dataExhAirSystemMrg.GetInputFlag:
        GetExhaustAirSystemInput(inout state)
        state.dataExhAirSystemMrg.GetInputFlag = False

    return FindItemInList(CompName, state.dataZoneEquip.ExhaustAirSystem, "ZoneMixerName") > 0


fn getEnumValue(names_list: DynamicVector[String], target: String) -> Int32:
    for i in range(len(names_list)):
        if names_list[i] == target:
            return Int32(i)
    return -1


fn FindItemInList(target: String, items: DynamicVector[ExhaustAir], attr: StringLiteral = "") -> Int32:
    for i in range(len(items)):
        if attr == "ZoneMixerName":
            if items[i].ZoneMixerName == target:
                return Int32(i + 1)
    return 0


fn makeUPPER(s: String) -> String:
    return s.upper()


fn ValidateComponent(inout state: AnyType, CompType: String, CompName: String, inout IsNotOK: Bool, ComponentContext: String) -> None:
    pass


fn ShowSevereError(inout state: AnyType, msg: String) -> None:
    pass


fn ShowContinueError(inout state: AnyType, msg: String) -> None:
    pass


fn ShowFatalError(inout state: AnyType, msg: String) -> None:
    pass


fn ShowWarningError(inout state: AnyType, msg: String) -> None:
    pass


fn ShowSevereItemNotFound(inout state: AnyType, eoh: ErrorObjectHeader, field: String, value: String) -> None:
    pass


fn ShowWarningItemNotFound(inout state: AnyType, eoh: ErrorObjectHeader, field: String, value: String, msg: String) -> None:
    pass


fn SetupOutputVariable(inout state: AnyType, name: String, units: String, obj: AnyType, attr: String, timestep: String, storetype: String, varname: String) -> None:
    pass


struct ErrorObjectHeader:
    var routine: String
    var module: String
    var name: String

    fn __init__(inout self, routine: String, module: String, name: String):
        self.routine = routine
        self.module = module
        self.name = name


fn FLOW_CONTROL_TYPE_NAMES_UC() -> DynamicVector[String]:
    var result: DynamicVector[String] = DynamicVector[String]()
    result.push_back("SCHEDULED")
    result.push_back("FOLLOWSUPPLY")
    return result


fn hvac_FanType_SystemModel() -> AnyType:
    pass


fn hvac_FanType_ComponentModel() -> AnyType:
    pass


fn hvac_fanTypeNames() -> DynamicVector[String]:
    var result: DynamicVector[String] = DynamicVector[String]()
    return result


fn hvac_fanTypeNamesUC() -> DynamicVector[String]:
    var result: DynamicVector[String] = DynamicVector[String]()
    return result


fn hvac_SmallMassFlow() -> Real64:
    return 1e-10


struct Sched:
    @staticmethod
    fn GetScheduleAlwaysOn(inout state: AnyType) -> AnyType:
        pass

    @staticmethod
    fn GetSchedule(inout state: AnyType, name: String) -> AnyType:
        pass


struct Node:
    struct ConnectionObjectType:
        @staticmethod
        fn ZoneHVACExhaustControl() -> String:
            return "ZoneHVAC:ExhaustControl"

    struct FluidType:
        @staticmethod
        fn Air() -> String:
            return "Air"

    struct ConnectionType:
        @staticmethod
        fn Inlet() -> String:
            return "Inlet"

        @staticmethod
        fn Outlet() -> String:
            return "Outlet"

        @staticmethod
        fn Sensor() -> String:
            return "Sensor"

    struct CompFluidStream:
        @staticmethod
        fn Primary() -> Int32:
            return 1

    struct ObjectIsParent:
        pass

    struct ObjectIsNotParent:
        pass

    @staticmethod
    fn GetOnlySingleNode(inout state: AnyType, name: String, inout errors_found: Bool, conn_type: AnyType,
                         comp_name: String, fluid_type: String, conn_dir: String, stream: Int32, obj_parent: AnyType) -> Int32:
        return 0

    @staticmethod
    fn GetNodeNums(inout state: AnyType, name: String, inout num_nodes: Int32, inout node_nums: DynamicVector[Int32],
                   inout node_list_error: Bool, fluid_type: String, conn_type: AnyType, comp_name: String,
                   conn_dir: String, stream: Int32, obj_parent: AnyType) -> None:
        pass

    @staticmethod
    fn SetUpCompSets(inout state: AnyType, module: String, name: String, fan_type: String, fan_name: String, inlet: String, outlet: String) -> None:
        pass


struct MixerComponent:
    @staticmethod
    fn GetZoneMixerIndex(inout state: AnyType, name: String, inout index: Int32, inout err_found: Bool, comp_name: String) -> None:
        pass

    @staticmethod
    fn InitAirMixer(inout state: AnyType, index: Int32) -> None:
        pass

    @staticmethod
    fn SimAirMixer(inout state: AnyType, name: String, index: Int32) -> None:
        pass


struct Fans:
    @staticmethod
    fn GetFanIndex(inout state: AnyType, name: String) -> Int32:
        return 0


struct DataSizing:
    @staticmethod
    fn AutoSize() -> Real64:
        return -99999.0


struct Psychrometrics:
    @staticmethod
    fn PsyRhoAirFnPbTdbW(inout state: AnyType, pb: Real64, tdb: Real64, w: Real64) -> Real64:
        return 0.0


struct BaseSizer:
    @staticmethod
    fn reportSizerOutput(inout state: AnyType, type_str: String, name: String, field: String, value: Real64) -> None:
        pass
