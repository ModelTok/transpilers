// EnergyPlus, Copyright (c) 1996-present, The Board of Trustees of the University of Illinois,
// The Regents of the University of California, through Lawrence Berkeley National Laboratory
// (subject to receipt of any required approvals from the U.S. Dept. of Energy), Oak Ridge
// National Laboratory, managed by UT-Battelle, Alliance for Energy Innovation, LLC, and other
// contributors. All rights reserved.
//
// NOTICE: This Software was developed under funding from the U.S. Department of Energy and the
// U.S. Government consequently retains certain rights. As such, the U.S. Government has been
// granted for itself and others acting on its behalf a paid-up, nonexclusive, irrevocable,
// worldwide license in the Software to reproduce, distribute copies to the public, prepare
// derivative works, and perform publicly and display publicly, and to permit others to do so.
//
// Redistribution and use in source and binary forms, with or without modification, are permitted
// provided that the following conditions are met:
//
// (1) Redistributions of source code must retain the above copyright notice, this list of
//     conditions and the following disclaimer.
//
// (2) Redistributions in binary form must reproduce the above copyright notice, this list of
//     conditions and the following disclaimer in the documentation and/or other materials
//     provided with the distribution.
//
// (3) Neither the name of the University of California, Lawrence Berkeley National Laboratory,
//     the University of Illinois, U.S. Dept. of Energy nor the names of its contributors may be
//     used to endorse or promote products derived from this software without specific prior
//     written permission.
//
// (4) Use of EnergyPlus(TM) Name. If Licensee (i) distributes the software in stand-alone form
//     without changes from the version obtained under this License, or (ii) Licensee makes a
//     reference solely to the software portion of its product, Licensee must refer to the
//     software as "EnergyPlus version X" software, where "X" is the version number Licensee
//     obtained under this License and may not use a different name for the software. Except as
//     specifically required in this Section (4), Licensee shall not use in a company name, a
//     product name, in advertising, publicity, or other promotional activities any name, trade
//     name, trademark, logo, or other designation of "EnergyPlus", "E+", "e+" or confusingly
//     similar designation, without the U.S. Department of Energy's prior written consent.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
// IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
// AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
// CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
// OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

from .Data.BaseData import BaseGlobalStruct, EnergyPlusData
from DataHVACGlobals import HVAC, SmallMassFlow, TimeStepSysSec, OnOffFanPartLoadFraction
from DataEnvironment import StdRhoAir, OutBaroPress, OutEnthalpy
from DataHeatBalance import Zone
from .DataIPShortCuts import ErrorObjectHeader
from .DataLoopNode import Node, SetUpCompSets, GetOnlySingleNode, GetNodeNums, ConnectionObjectType, ConnectionType, FluidType, CompFluidStream, ObjectIsParent, ObjectIsNotParent
from DataSizing import AutoSize, FinalZoneSizing
from DataZoneEquipment import ZoneEquipConfig, ExhaustAirSystem, ZoneExhaustControlSystem, NumExhaustAirSystems, NumZoneExhaustControls
from Fans import FanType, fanTypeNames, fanTypeNamesUC, GetFanIndex, FanComponent
from GeneralRoutines import ValidateComponent
from .InputProcessing.InputProcessor import InputProcessor
from MixerComponent import MixerCond, GetZoneMixerIndex, InitAirMixer, SimAirMixer
from NodeInputManager import NodeInputManager
from Psychrometrics import PsyRhoAirFnPbTdbW
from ScheduleManager import Schedule, GetSchedule, GetScheduleAlwaysOn
from UtilityRoutines import makeUPPER, FindItemInList
from ZoneTempPredictorCorrector import zoneHeatBalance
from .Autosizing.Base import BaseSizer
from BranchNodeConnections import BranchNodeConnections
from .DataContaminantBalance import Contaminant
from .AirflowNetwork.src.Solver import AirflowNetworkFanActivated, distribution_simulated
from OutputProcessor import SetupOutputVariable, TimeStepType, StoreType
from .Constant import Units

module EnergyPlus:

    module ExhaustAirSystemManager:

        struct ExhaustAir:
            var Name: String
            var availSched: Schedule = None
            var ZoneMixerName: String
            var ZoneMixerIndex: Int = 0
            var centralFanType: HVAC.FanType = HVAC.FanType.Invalid
            var CentralFanName: String
            var CentralFanIndex: Int = 0
            var SizingFlag: Bool = True
            var centralFan_MassFlowRate: Float64 = 0.0
            var centralFan_VolumeFlowRate_Std: Float64 = 0.0
            var centralFan_VolumeFlowRate_Cur: Float64 = 0.0
            var centralFan_Power: Float64 = 0.0
            var centralFan_Energy: Float64 = 0.0
            var exhTotalHVACReliefHeatLoss: Float64 = 0.0

        struct ZoneExhaustControl:
            enum FlowControlType:
                Invalid = -1
                Scheduled = 0
                FollowSupply = 1
                Num = 2

            var Name: String
            var availSched: Schedule = None
            var ZoneName: String
            var ZoneNum: Int = 0
            var ControlledZoneNum: Int = 0
            var InletNodeNum: Int = 0
            var OutletNodeNum: Int = 0
            var DesignExhaustFlowRate: Float64 = 0.0
            var FlowControlOption: FlowControlType = FlowControlType.Scheduled
            var exhaustFlowFractionSched: Schedule = None
            var SupplyNodeOrNodelistName: String
            var SupplyNodeOrNodelistNum: Int = 0
            var minZoneTempLimitSched: Schedule = None
            var minExhFlowFracSched: Schedule = None
            var balancedExhFracSched: Schedule = None
            var BalancedFlow: Float64 = 0.0
            var UnbalancedFlow: Float64 = 0.0
            var SuppNodeNums: List[Int] = List[Int]()

        # static array for flowControlTypeNamesUC
        var flowControlTypeNamesUC: List[String] = List[String]("SCHEDULED", "FOLLOWSUPPLY")

        def SimExhaustAirSystem(state: EnergyPlusData, FirstHVACIteration: Bool):
            if state.dataExhAirSystemMrg.GetInputFlag:
                GetExhaustAirSystemInput(state)
                state.dataExhAirSystemMrg.GetInputFlag = False

            for ExhaustAirSystemNum in range(1, state.dataZoneEquip.NumExhaustAirSystems + 1):
                CalcExhaustAirSystem(state, ExhaustAirSystemNum, FirstHVACIteration)

            UpdateZoneExhaustControl(state)

        def GetExhaustAirSystemInput(state: EnergyPlusData):
            if not state.dataExhAirSystemMrg.GetInputFlag:
                return

            var ErrorsFound: Bool = False

            var RoutineName: StringLiteral = "GetExhaustAirSystemInput: "
            var routineName: StringLiteral = "GetExhaustAirSystemInput"
            var cCurrentModuleObject: String = "AirLoopHVAC:ExhaustSystem"

            var ip: InputProcessor = state.dataInputProcessing.inputProcessor
            var instances = ip.epJSON.find(cCurrentModuleObject)
            if instances != ip.epJSON.end():
                var objectSchemaProps = ip.getObjectSchemaProps(state, cCurrentModuleObject)
                var instancesValue = instances.value()
                var numExhaustSystems: Int = instancesValue.size()
                var exhSysNum: Int = 0

                if numExhaustSystems > 0:
                    state.dataZoneEquip.ExhaustAirSystem = List[ExhaustAir](numExhaustSystems)

                for instance in instancesValue:
                    exhSysNum += 1
                    var objectFields = instance.value()
                    var thisExhSys = state.dataZoneEquip.ExhaustAirSystem[exhSysNum - 1]
                    thisExhSys.Name = makeUPPER(instance.key())
                    ip.markObjectAsUsed(cCurrentModuleObject, instance.key())

                    var zoneMixerName: String = ip.getAlphaFieldValue(objectFields, objectSchemaProps, "zone_mixer_name")
                    var zoneMixerIndex: Int = 0
                    var zoneMixerErrFound: Bool = False
                    GetZoneMixerIndex(state, zoneMixerName, zoneMixerIndex, zoneMixerErrFound, thisExhSys.Name)

                    if not zoneMixerErrFound:
                        InitAirMixer(state, zoneMixerIndex)

                        var IsNotOK: Bool = False
                        ValidateComponent(state, "AirLoopHVAC:ZoneMixer", zoneMixerName, IsNotOK, "AirLoopHVAC:ExhaustSystem")
                        if IsNotOK:
                            ShowSevereError(state, "{}={}={}".format(RoutineName, cCurrentModuleObject, thisExhSys.Name))
                            ShowContinueError(state, "ZoneMixer Name ={} mismatch or not found.".format(zoneMixerName))
                            ErrorsFound = True
                        else:

                    else:
                        ShowSevereError(state, "{}={}={}".format(RoutineName, cCurrentModuleObject, thisExhSys.Name))
                        ShowContinueError(state, "Zone Mixer Name ={} not found.".format(zoneMixerName))
                        ErrorsFound = True

                    thisExhSys.ZoneMixerName = zoneMixerName
                    thisExhSys.ZoneMixerIndex = zoneMixerIndex

                    thisExhSys.centralFanType = static_cast[HVAC.FanType](
                        getEnumValue(HVAC.fanTypeNamesUC, makeUPPER(ip.getAlphaFieldValue(objectFields, objectSchemaProps, "fan_object_type")))
                    )
                    if thisExhSys.centralFanType != HVAC.FanType.SystemModel and thisExhSys.centralFanType != HVAC.FanType.ComponentModel:
                        ShowSevereError(state, "{}={}={}".format(RoutineName, cCurrentModuleObject, thisExhSys.Name))
                        ShowContinueError(state, "Fan Type ={} is not supported.".format(HVAC.fanTypeNames[int(thisExhSys.centralFanType)]))
                        ShowContinueError(state, "It needs to be either a Fan:SystemModel or a Fan:ComponentModel type.")
                        ErrorsFound = True

                    var centralFanName: String = ip.getAlphaFieldValue(objectFields, objectSchemaProps, "fan_name")

                    var eoh: ErrorObjectHeader = ErrorObjectHeader(routineName, cCurrentModuleObject, thisExhSys.Name)
                    var centralFanIndex: Int = GetFanIndex(state, centralFanName)
                    if centralFanIndex == 0:
                        ShowSevereItemNotFound(state, eoh, "fan_name", centralFanName)
                        ErrorsFound = True
                    else:
                        var fan = state.dataFans.fans[centralFanIndex - 1]

                        thisExhSys.availSched = fan.availSched

                        SetUpCompSets(state,
                            cCurrentModuleObject,
                            thisExhSys.Name,
                            HVAC.fanTypeNames[int(thisExhSys.centralFanType)],
                            centralFanName,
                            state.dataLoopNodes.NodeID[fan.inletNodeNum - 1],
                            state.dataLoopNodes.NodeID[fan.outletNodeNum - 1])

                        SetupOutputVariable(state,
                            "Central Exhaust Fan Mass Flow Rate",
                            Units.kg_s,
                            thisExhSys.centralFan_MassFlowRate,
                            TimeStepType.System,
                            StoreType.Average,
                            thisExhSys.Name)

                        SetupOutputVariable(state,
                            "Central Exhaust Fan Volumetric Flow Rate Standard",
                            Units.m3_s,
                            thisExhSys.centralFan_VolumeFlowRate_Std,
                            TimeStepType.System,
                            StoreType.Average,
                            thisExhSys.Name)

                        SetupOutputVariable(state,
                            "Central Exhaust Fan Volumetric Flow Rate Current",
                            Units.m3_s,
                            thisExhSys.centralFan_VolumeFlowRate_Cur,
                            TimeStepType.System,
                            StoreType.Average,
                            thisExhSys.Name)

                        SetupOutputVariable(state,
                            "Central Exhaust Fan Power",
                            Units.W,
                            thisExhSys.centralFan_Power,
                            TimeStepType.System,
                            StoreType.Average,
                            thisExhSys.Name)

                        SetupOutputVariable(state,
                            "Central Exhaust Fan Energy",
                            Units.J,
                            thisExhSys.centralFan_Energy,
                            TimeStepType.System,
                            StoreType.Sum,
                            thisExhSys.Name)

                    thisExhSys.CentralFanName = centralFanName
                    thisExhSys.CentralFanIndex = centralFanIndex

                    if thisExhSys.SizingFlag:
                        SizeExhaustSystem(state, exhSysNum)

                state.dataZoneEquip.NumExhaustAirSystems = numExhaustSystems
            else:

            if ErrorsFound:
                ShowFatalError(state, "Errors found getting AirLoopHVAC:ExhaustSystem.  Preceding condition(s) causes termination.")

        def CalcExhaustAirSystem(state: EnergyPlusData, ExhaustAirSystemNum: Int, FirstHVACIteration: Bool):
            var thisExhSys = state.dataZoneEquip.ExhaustAirSystem[ExhaustAirSystemNum - 1]
            var RoutineName: StringLiteral = "CalExhaustAirSystem: "
            var cCurrentModuleObject: StringLiteral = "AirloopHVAC:ExhaustSystem"
            var ErrorsFound: Bool = False
            if not (state.afn.AirflowNetworkFanActivated and state.afn.distribution_simulated):
                SimAirMixer(state, thisExhSys.ZoneMixerName, thisExhSys.ZoneMixerIndex)
            else:
                ShowSevereError(state, "{}={}={}".format(RoutineName, cCurrentModuleObject, thisExhSys.Name))
                ShowContinueError(state, "AirloopHVAC:ExhaustSystem currently does not work with AirflowNetwork.")
                ErrorsFound = True

            if ErrorsFound:
                ShowFatalError(state, "Errors found conducting CalcExhasutAirSystem(). Preceding condition(s) causes termination.")

            var mixerFlow_Prior: Float64 = 0.0
            var outletNode_index: Int = state.dataMixerComponent.MixerCond[thisExhSys.ZoneMixerIndex - 1].OutletNode
            mixerFlow_Prior = state.dataLoopNodes.Node[outletNode_index - 1].MassFlowRate
            if mixerFlow_Prior == 0.0:

            var outletNode_Num: Int = 0
            var RhoAirCurrent: Float64 = state.dataEnvrn.StdRhoAir

            if thisExhSys.centralFanType == HVAC.FanType.SystemModel:
                state.dataHVACGlobal.OnOffFanPartLoadFraction = 1.0
                state.dataFans.fans[thisExhSys.CentralFanIndex - 1].simulate(state, False, _, _)

                outletNode_Num = state.dataFans.fans[thisExhSys.CentralFanIndex - 1].outletNodeNum

                thisExhSys.centralFan_MassFlowRate = state.dataLoopNodes.Node[outletNode_Num - 1].MassFlowRate

                thisExhSys.centralFan_VolumeFlowRate_Std = state.dataLoopNodes.Node[outletNode_Num - 1].MassFlowRate / state.dataEnvrn.StdRhoAir

                RhoAirCurrent = PsyRhoAirFnPbTdbW(state,
                    state.dataEnvrn.OutBaroPress,
                    state.dataLoopNodes.Node[outletNode_Num - 1].Temp,
                    state.dataLoopNodes.Node[outletNode_Num - 1].HumRat)
                if RhoAirCurrent <= 0.0:
                    RhoAirCurrent = state.dataEnvrn.StdRhoAir
                thisExhSys.centralFan_VolumeFlowRate_Cur = state.dataLoopNodes.Node[outletNode_Num - 1].MassFlowRate / RhoAirCurrent

                thisExhSys.centralFan_Power = state.dataFans.fans[thisExhSys.CentralFanIndex - 1].totalPower

                thisExhSys.centralFan_Energy = thisExhSys.centralFan_Power * state.dataHVACGlobal.TimeStepSysSec

            elif thisExhSys.centralFanType == HVAC.FanType.ComponentModel:
                var fan = state.dataFans.fans[thisExhSys.CentralFanIndex - 1]
                fan.simulate(state, FirstHVACIteration)

                outletNode_Num = fan.outletNodeNum

                thisExhSys.centralFan_MassFlowRate = fan.outletAirMassFlowRate

                thisExhSys.centralFan_VolumeFlowRate_Std = fan.outletAirMassFlowRate / state.dataEnvrn.StdRhoAir

                RhoAirCurrent = PsyRhoAirFnPbTdbW(state,
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

            var mixerFlow_Posterior: Float64 = 0.0
            mixerFlow_Posterior = state.dataLoopNodes.Node[outletNode_index - 1].MassFlowRate
            if mixerFlow_Posterior < HVAC.SmallMassFlow:

            if mixerFlow_Prior < HVAC.SmallMassFlow:

            if (mixerFlow_Prior - mixerFlow_Posterior > HVAC.SmallMassFlow) or (mixerFlow_Prior - mixerFlow_Posterior < -HVAC.SmallMassFlow):
                var flowRatio: Float64 = mixerFlow_Posterior / mixerFlow_Prior
                if flowRatio > 1.0:
                    ShowWarningError(state, "{}={}={}".format(RoutineName, cCurrentModuleObject, thisExhSys.Name))
                    ShowContinueError(state, "Requested flow rate is lower than the exhasut fan flow rate.")
                    ShowContinueError(state, "Will scale up the requested flow rate to meet fan flow rate.")

                var zoneMixerIndex: Int = thisExhSys.ZoneMixerIndex
                for i in range(1, state.dataMixerComponent.MixerCond[zoneMixerIndex - 1].NumInletNodes + 1):
                    var exhLegIndex: Int = state.dataExhAirSystemMrg.mixerIndexMap[state.dataMixerComponent.MixerCond[zoneMixerIndex - 1].InletNode[i - 1]]
                    CalcZoneHVACExhaustControl(state, exhLegIndex, flowRatio)

                SimAirMixer(state, thisExhSys.ZoneMixerName, thisExhSys.ZoneMixerIndex)

        def GetZoneExhaustControlInput(state: EnergyPlusData):
            var ErrorsFound: Bool = False

            var RoutineName: StringLiteral = "GetZoneExhaustControlInput: "
            var routineName: StringLiteral = "GetZoneExhaustControlInput"

            var cCurrentModuleObject: String = "ZoneHVAC:ExhaustControl"
            var ip: InputProcessor = state.dataInputProcessing.inputProcessor
            var instances = ip.epJSON.find(cCurrentModuleObject)
            if instances != ip.epJSON.end():
                var objectSchemaProps = ip.getObjectSchemaProps(state, cCurrentModuleObject)
                var instancesValue = instances.value()
                var numZoneExhaustControls: Int = instancesValue.size()
                var exhCtrlNum: Int = 0
                var NumAlphas: Int
                var NumNums: Int

                if numZoneExhaustControls > 0:
                    state.dataZoneEquip.ZoneExhaustControlSystem = List[ZoneExhaustControl](numZoneExhaustControls)

                for instance in instancesValue:
                    exhCtrlNum += 1
                    var objectFields = instance.value()
                    var thisExhCtrl = state.dataZoneEquip.ZoneExhaustControlSystem[exhCtrlNum - 1]

                    var eoh: ErrorObjectHeader = ErrorObjectHeader(routineName, cCurrentModuleObject, instance.key())

                    thisExhCtrl.Name = makeUPPER(instance.key())
                    ip.markObjectAsUsed(cCurrentModuleObject, instance.key())

                    var availSchName: String = ip.getAlphaFieldValue(objectFields, objectSchemaProps, "availability_schedule_name")
                    if availSchName.empty():
                        thisExhCtrl.availSched = GetScheduleAlwaysOn(state)
                    elif (thisExhCtrl.availSched = GetSchedule(state, availSchName)) == None:
                        thisExhCtrl.availSched = GetScheduleAlwaysOn(state)
                        ShowWarningItemNotFound(state, eoh, "Availability Schedule Name", availSchName, "Availability Schedule is reset to Always ON.")

                    var zoneName: String = ip.getAlphaFieldValue(objectFields, objectSchemaProps, "zone_name")
                    thisExhCtrl.ZoneName = zoneName
                    var zoneNum: Int = FindItemInList(zoneName, state.dataHeatBal.Zone)
                    thisExhCtrl.ZoneNum = zoneNum

                    thisExhCtrl.ControlledZoneNum = FindItemInList(zoneName, state.dataHeatBal.Zone)

                    var inletNodeName: String = ip.getAlphaFieldValue(objectFields, objectSchemaProps, "inlet_node_name")
                    var inletNodeNum: Int = GetOnlySingleNode(state,
                        inletNodeName,
                        ErrorsFound,
                        ConnectionObjectType.ZoneHVACExhaustControl,
                        thisExhCtrl.Name,
                        FluidType.Air,
                        ConnectionType.Inlet,
                        CompFluidStream.Primary,
                        ObjectIsParent)
                    thisExhCtrl.InletNodeNum = inletNodeNum

                    var outletNodeName: String = ip.getAlphaFieldValue(objectFields, objectSchemaProps, "outlet_node_name")

                    var outletNodeNum: Int = GetOnlySingleNode(state,
                        outletNodeName,
                        ErrorsFound,
                        ConnectionObjectType.ZoneHVACExhaustControl,
                        thisExhCtrl.Name,
                        FluidType.Air,
                        ConnectionType.Outlet,
                        CompFluidStream.Primary,
                        ObjectIsParent)
                    thisExhCtrl.OutletNodeNum = outletNodeNum

                    if not state.dataExhAirSystemMrg.mappingDone:
                        state.dataExhAirSystemMrg.mixerIndexMap[outletNodeNum] = exhCtrlNum

                    var designExhaustFlowRate: Float64 = ip.getRealFieldValue(objectFields, objectSchemaProps, "design_exhaust_flow_rate")
                    thisExhCtrl.DesignExhaustFlowRate = designExhaustFlowRate

                    var flowControlTypeName: String = makeUPPER(ip.getAlphaFieldValue(objectFields, objectSchemaProps, "flow_control_type"))
                    thisExhCtrl.FlowControlOption = static_cast[ZoneExhaustControl.FlowControlType](
                        getEnumValue(flowControlTypeNamesUC, flowControlTypeName))

                    var exhaustFlowFractionSchedName: String = ip.getAlphaFieldValue(objectFields, objectSchemaProps, "exhaust_flow_fraction_schedule_name")

                    if exhaustFlowFractionSchedName.empty():
                        thisExhCtrl.exhaustFlowFractionSched = GetScheduleAlwaysOn(state)
                    elif (thisExhCtrl.exhaustFlowFractionSched = GetSchedule(state, exhaustFlowFractionSchedName)) == None:
                        ShowSevereItemNotFound(state, eoh, "Exhaust Flow Fraction Schedule Name", exhaustFlowFractionSchedName)

                    thisExhCtrl.SupplyNodeOrNodelistName = ip.getAlphaFieldValue(objectFields, objectSchemaProps, "supply_node_or_nodelist_name")

                    var NodeListError: Bool = False
                    var NumParams: Int = 0
                    var NumNodes: Int = 0

                    ip.getObjectDefMaxArgs(state, "NodeList", NumParams, NumAlphas, NumNums)
                    thisExhCtrl.SuppNodeNums = List[Int](len=NumParams, fill=0)
                    GetNodeNums(state,
                        thisExhCtrl.SupplyNodeOrNodelistName,
                        NumNodes,
                        thisExhCtrl.SuppNodeNums,
                        NodeListError,
                        FluidType.Air,
                        ConnectionObjectType.ZoneHVACExhaustControl,
                        thisExhCtrl.Name,
                        ConnectionType.Sensor,
                        CompFluidStream.Primary,
                        ObjectIsNotParent)

                    if thisExhCtrl.FlowControlOption == ZoneExhaustControl.FlowControlType.FollowSupply:
                        var nodeNotFound: Bool = False
                        for i in range(1, thisExhCtrl.SuppNodeNums.size() + 1):
                            CheckForSupplyNode(state, exhCtrlNum, nodeNotFound)
                            if nodeNotFound:
                                ShowSevereError(state, "{}={}={}".format(RoutineName, cCurrentModuleObject, thisExhCtrl.Name))
                                ShowContinueError(state, "Node or NodeList Name ={}. Must all be supply nodes.".format(thisExhCtrl.SupplyNodeOrNodelistName))
                                ErrorsFound = True

                    if thisExhCtrl.DesignExhaustFlowRate == AutoSize:
                        SizeExhaustControlFlow(state, exhCtrlNum, thisExhCtrl.SuppNodeNums)

                    var minZoneTempLimitSchedName: String = ip.getAlphaFieldValue(objectFields, objectSchemaProps, "minimum_zone_temperature_limit_schedule_name")
                    if minZoneTempLimitSchedName.empty():

                    elif (thisExhCtrl.minZoneTempLimitSched = GetSchedule(state, minZoneTempLimitSchedName)) == None:
                        ShowSevereItemNotFound(state, eoh, "Minimum Zone Temperature Limit Schedule Name", minZoneTempLimitSchedName)

                    var minExhFlowFracSchedName: String = ip.getAlphaFieldValue(objectFields, objectSchemaProps, "minimum_exhaust_flow_fraction_schedule_name")
                    if minExhFlowFracSchedName.empty():

                    elif (thisExhCtrl.minExhFlowFracSched = GetSchedule(state, minExhFlowFracSchedName)) == None:
                        ShowSevereItemNotFound(state, eoh, "Minimum Exhaust Flow Fraction Schedule Name", minExhFlowFracSchedName)

                    var balancedExhFracSchedName: String = ip.getAlphaFieldValue(objectFields, objectSchemaProps, "balanced_exhaust_fraction_schedule_name")
                    if balancedExhFracSchedName.empty():

                    elif (thisExhCtrl.balancedExhFracSched = GetSchedule(state, balancedExhFracSchedName)) == None:
                        ShowSevereItemNotFound(state, eoh, "Balanced Exhaust Fraction Schedule Name", balancedExhFracSchedName)

                state.dataZoneEquip.NumZoneExhaustControls = numZoneExhaustControls

                state.dataExhAirSystemMrg.mappingDone = True

            if ErrorsFound:
                ShowFatalError(state, "Errors found getting ZoneHVAC:ExhaustControl.  Preceding condition(s) causes termination.")

        def SimZoneHVACExhaustControls(state: EnergyPlusData):
            if state.dataExhCtrlSystemMrg.GetInputFlag:
                GetZoneExhaustControlInput(state)
                state.dataExhCtrlSystemMrg.GetInputFlag = False

            for ExhaustControlNum in range(1, state.dataZoneEquip.NumZoneExhaustControls + 1):
                CalcZoneHVACExhaustControl(state, ExhaustControlNum)

        def CalcZoneHVACExhaustControl(state: EnergyPlusData, ZoneHVACExhaustControlNum: Int, FlowRatio: Float64 = -1.0):
            var thisExhCtrl = state.dataZoneEquip.ZoneExhaustControlSystem[ZoneHVACExhaustControlNum - 1]

            var InletNode: Int = thisExhCtrl.InletNodeNum
            var OutletNode: Int = thisExhCtrl.OutletNodeNum
            var thisExhInlet = state.dataLoopNodes.Node[InletNode - 1]
            var thisExhOutlet = state.dataLoopNodes.Node[OutletNode - 1]
            var MassFlow: Float64
            var Tin: Float64 = state.dataZoneTempPredictorCorrector.zoneHeatBalance[thisExhCtrl.ZoneNum - 1].ZT
            var thisExhCtrlAvailScheVal: Float64 = thisExhCtrl.availSched.getCurrentVal()

            if FlowRatio >= 0.0:
                thisExhCtrl.BalancedFlow *= FlowRatio
                thisExhCtrl.UnbalancedFlow *= FlowRatio

                thisExhInlet.MassFlowRate *= FlowRatio
            else:
                if thisExhCtrlAvailScheVal <= 0.0:
                    MassFlow = 0.0
                    thisExhInlet.MassFlowRate = 0.0
                else:

                var DesignFlowRate: Float64 = thisExhCtrl.DesignExhaustFlowRate
                var FlowFrac: Float64 = 1.0
                if thisExhCtrl.exhaustFlowFractionSched != None:
                    FlowFrac = thisExhCtrl.exhaustFlowFractionSched.getCurrentVal()
                    if FlowFrac < 0.0:
                        ShowWarningError(state, "Exhaust Flow Fraction Schedule value is negative for Zone Exhaust Control Named: {};".format(thisExhCtrl.Name))
                        ShowContinueError(state, "Reset value to zero and continue the simulation.")
                        FlowFrac = 0.0

                var MinFlowFrac: Float64 = 0.0
                if thisExhCtrl.minExhFlowFracSched != None:
                    MinFlowFrac = thisExhCtrl.minExhFlowFracSched.getCurrentVal()
                    if MinFlowFrac < 0.0:
                        ShowWarningError(state, "Minimum Exhaust Flow Fraction Schedule value is negative for Zone Exhaust Control Named: {};".format(thisExhCtrl.Name))
                        ShowContinueError(state, "Reset value to zero and continue the simulation.")
                        MinFlowFrac = 0.0

                if FlowFrac < MinFlowFrac:
                    FlowFrac = MinFlowFrac

                if thisExhCtrlAvailScheVal > 0.0:
                    if thisExhCtrl.minZoneTempLimitSched != None:
                        if Tin >= thisExhCtrl.minZoneTempLimitSched.getCurrentVal():

                        else:
                            FlowFrac = MinFlowFrac
                    else:

                else:
                    FlowFrac = 0.0

                if thisExhCtrl.FlowControlOption == ZoneExhaustControl.FlowControlType.FollowSupply:
                    var supplyFlowRate: Float64 = 0.0
                    var numOfSuppNodes: Int = thisExhCtrl.SuppNodeNums.size()
                    for i in range(1, numOfSuppNodes + 1):
                        supplyFlowRate += state.dataLoopNodes.Node[thisExhCtrl.SuppNodeNums[i - 1] - 1].MassFlowRate
                    MassFlow = supplyFlowRate * FlowFrac
                else:
                    MassFlow = DesignFlowRate * FlowFrac

                if thisExhCtrl.balancedExhFracSched != None:
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

        def SizeExhaustSystem(state: EnergyPlusData, exhSysNum: Int):
            var thisExhSys = state.dataZoneEquip.ExhaustAirSystem[exhSysNum - 1]

            if not thisExhSys.SizingFlag:
                return

            var outletFlowMaxAvail: Float64 = 0.0
            for i in range(1, state.dataMixerComponent.MixerCond[thisExhSys.ZoneMixerIndex - 1].NumInletNodes + 1):
                var inletNode_index: Int = state.dataMixerComponent.MixerCond[thisExhSys.ZoneMixerIndex - 1].InletNode[i - 1]
                outletFlowMaxAvail += state.dataLoopNodes.Node[inletNode_index - 1].MassFlowRateMaxAvail

            var outletNode_index: Int = state.dataMixerComponent.MixerCond[thisExhSys.ZoneMixerIndex - 1].OutletNode
            state.dataLoopNodes.Node[outletNode_index - 1].MassFlowRateMaxAvail = outletFlowMaxAvail

            var fan = state.dataFans.fans[thisExhSys.CentralFanIndex - 1]

            if thisExhSys.centralFanType == HVAC.FanType.SystemModel:
                if fan.maxAirFlowRate == AutoSize:
                    fan.maxAirFlowRate = outletFlowMaxAvail / state.dataEnvrn.StdRhoAir
                BaseSizer.reportSizerOutput(state, "FAN:SYSTEMMODEL", fan.Name, "Design Fan Airflow [m3/s]", fan.maxAirFlowRate)
            elif thisExhSys.centralFanType == HVAC.FanType.ComponentModel:
                if fan.maxAirMassFlowRate == AutoSize:
                    fan.maxAirMassFlowRate = outletFlowMaxAvail * (fan as FanComponent).sizingFactor
                BaseSizer.reportSizerOutput(state,
                    HVAC.fanTypeNames[int(fan.type)],
                    fan.Name,
                    "Design Fan Airflow [m3/s]",
                    fan.maxAirMassFlowRate / state.dataEnvrn.StdRhoAir)
            else:

            thisExhSys.SizingFlag = False

        def SizeExhaustControlFlow(state: EnergyPlusData, zoneExhCtrlNum: Int, NodeNums: List[Int]):
            var thisExhCtrl = state.dataZoneEquip.ZoneExhaustControlSystem[zoneExhCtrlNum - 1]

            var designFlow: Float64 = 0.0

            if thisExhCtrl.FlowControlOption == ZoneExhaustControl.FlowControlType.FollowSupply:
                for i in range(1, NodeNums.size() + 1):
                    designFlow += state.dataLoopNodes.Node[NodeNums[i - 1] - 1].MassFlowRateMax
            else:
                designFlow = state.dataSize.FinalZoneSizing[thisExhCtrl.ZoneNum - 1].MinOA

            thisExhCtrl.DesignExhaustFlowRate = designFlow

        def UpdateZoneExhaustControl(state: EnergyPlusData):
            for i in range(1, state.dataZoneEquip.NumZoneExhaustControls + 1):
                var controlledZoneNum: Int = state.dataZoneEquip.ZoneExhaustControlSystem[i - 1].ControlledZoneNum
                state.dataZoneEquip.ZoneEquipConfig[controlledZoneNum - 1].ZoneExh += \
                    state.dataZoneEquip.ZoneExhaustControlSystem[i - 1].BalancedFlow + state.dataZoneEquip.ZoneExhaustControlSystem[i - 1].UnbalancedFlow
                state.dataZoneEquip.ZoneEquipConfig[controlledZoneNum - 1].ZoneExhBalanced += state.dataZoneEquip.ZoneExhaustControlSystem[i - 1].BalancedFlow

        def CheckForSupplyNode(state: EnergyPlusData, ExhCtrlNum: Int, NodeNotFound: Bool):
            var thisExhCtrl = state.dataZoneEquip.ZoneExhaustControlSystem[ExhCtrlNum - 1]

            var RoutineName: StringLiteral = "GetExhaustControlInput: "
            var CurrentModuleObject: StringLiteral = "ZoneHVAC:ExhaustControl"

            var ZoneNodeNotFound: Bool = True
            var ErrorsFound: Bool = False
            for i in range(1, thisExhCtrl.SuppNodeNums.size() + 1):
                var supplyNodeNum: Int = thisExhCtrl.SuppNodeNums[i - 1]
                for NodeNum in range(1, state.dataZoneEquip.ZoneEquipConfig[thisExhCtrl.ZoneNum - 1].NumInletNodes + 1):
                    if supplyNodeNum == state.dataZoneEquip.ZoneEquipConfig[thisExhCtrl.ZoneNum - 1].InletNode[NodeNum - 1]:
                        ZoneNodeNotFound = False
                        break
                if ZoneNodeNotFound:
                    ShowSevereError(state, "{}={}={}".format(RoutineName, CurrentModuleObject, thisExhCtrl.Name))
                    ShowContinueError(state,
                        "Supply or supply list = \"{}\" contains at least one node that is not a zone inlet node for Zone Name = \"{}\"".format(
                            thisExhCtrl.SupplyNodeOrNodelistName, thisExhCtrl.ZoneName))
                    ShowContinueError(state, "..Nodes in the supply node or nodelist must be a zone inlet node.")
                    ErrorsFound = True

            NodeNotFound = ErrorsFound

        def ExhaustSystemHasMixer(state: EnergyPlusData, CompName: StringLiteral) -> Bool:
            if state.dataExhAirSystemMrg.GetInputFlag:
                GetExhaustAirSystemInput(state)
                state.dataExhAirSystemMrg.GetInputFlag = False

            return (FindItemInList(CompName, state.dataZoneEquip.ExhaustAirSystem, ExhaustAir.ZoneMixerName) > 0)

    struct ExhaustAirSystemMgr(BaseGlobalStruct):
        var GetInputFlag: Bool = True
        var mixerIndexMap: Dict[Int, Int] = Dict[Int, Int]()
        var mappingDone: Bool = False

        def init_constant_state(state: EnergyPlusData):

        def init_state(state: EnergyPlusData):

        def clear_state():
            self = ExhaustAirSystemMgr()

    struct ExhaustControlSystemMgr(BaseGlobalStruct):
        var GetInputFlag: Bool = True

        def init_constant_state(state: EnergyPlusData):

        def init_state(state: EnergyPlusData):

        def clear_state():
            self = ExhaustControlSystemMgr()