//! RoomAirModelAirflowNetwork.mojo – faithful 1:1 translation of RoomAirModelAirflowNetwork.cc

from BaseData import BaseGlobalStruct
from  import EnergyPlusData

from .AirflowNetwork.src.Solver import AirflowNetworkLinkageData, AirflowNetworkNodeSimu, AirflowNetworkLinkSimu
from BaseboardElectric import SimElectricBaseboard
from BaseboardRadiator import SimBaseboard
from .Data.EnergyPlusData import EnergyPlusData
from DataDefineEquip import AirDistUnit
from DataEnvironment import OutBaroPress
from DataHVACGlobals import TimeStepSysSec
from DataHeatBalSurface import SurfHConvInt, SurfTempInTmp
from DataHeatBalance import SolutionAlgo, SurfWinShadingFlag, ZoneZoneVolCapMultpSens, ZoneVolCapMultpMoist, spaceIndexes, HTSurfaceFirst, HTSurfaceLast
from DataLoopNodes import Node, NodeID, NumOfNodes
from DataMoistureBalance import HMassConvInFD, RhoVaporSurfIn, RhoVaporAirIn
from DataMoistureBalanceEMPD import RVSurface
from DataRoomAirModel import AFNZoneInfo, Node, HVAC
from DataSurfaces import SurfaceClass, Surface, SurfTAirRef, RefAirTemp, SurfWinDividerArea, SurfWinDividerHeatGain, SurfWinConvHeatFlowNatural, SurfWinAirflowThisTS, SurfWinConvHeatGainToZoneAir, SurfWinRetHeatGainToZoneAir, SurfWinHeatGain, SurfWinHeatGainRep, SurfWinHeatGainRepEnergy, SurfWinHeatLossRep, SurfWinHeatLossRepEnergy, SurfWinHeatTransferRepEnergy, SurfWinFrameArea, SurfWinProjCorrFrIn, SurfWinFrameTempIn, SurfWinProjCorrDivIn, SurfWinDividerTempIn
from DataZoneEquipment import ZoneEquipType, ZoneEquipConfig, ZoneEquipList, NumInletNodes, NumReturnNodes, ReturnNodeInletNum, ReturnNode
from ElectricBaseboardRadiator import SimElecBaseboard
from General import UtilityRoutines, SameString
from GlobalNames import GlobalNames
from HWBaseboardRadiator import SimHWBaseboard
from HeatBalanceHAMTManager import UpdateHeatBalHAMT
from HighTempRadiantSystem import SimHighTempRadiantSystem
from .InputProcessing.InputProcessor import InputProcessor, getNumObjectsFound
from InternalHeatGains import SumInternalConvectionGainsByIndices, SumInternalLatentGainsByIndices, SumInternalLatentGainsByTypes, SumReturnAirConvectionGainsByIndices, SumReturnAirConvectionGainsByTypes
from MoistureBalanceEMPDManager import UpdateMoistureBalanceEMPD
from OutputProcessor import SetupOutputVariable, OutputProcessor, TimeStepType, StoreType
from PoweredInductionUnits import PIU
from Psychrometrics import PsyCpAirFnW, PsyRhoAirFnPbTdbW, PsyHgAirFnWTdb, PsyRhFnTdbWPb, PsyRhFnTdbRhov, PsyRhFnTdbRhovLBnd0C, PsyRhoAirFnPbTdbW, PsyWFnTdbRhPb
from RefrigeratedCase import SimAirChillerSet
from SteamBaseboardRadiator import SimSteamBaseboard
from UtilityRoutines import ShowSevereError, ShowContinueError, ShowFatalError
from ZoneAirLoopEquipmentManager import GetZoneAirLoopEquipment, GetAirDistUnitsFlag
from ZoneDehumidifier import SimZoneDehumidifier
from ZonePlenum import ZoneRetPlenCond, ZoneSupPlenCond, NumZoneReturnPlenums, NumZoneSupplyPlenums
from ZoneTempPredictorCorrector import zoneHeatBalance, MAT

from builtin import DynamicVector, SIMD, String, format, max, min, abs, exp
from math import pow

module EnergyPlus:

    module RoomAir:

        using DataHeatBalSurface.SurfHConvInt
        using DataSurfaces.SurfaceClass
        using DataHeatBalance.SolutionAlgo

        def SimRoomAirModelAFN(inout state: EnergyPlusData, zoneNum: Int):
            var afnZoneInfo = state.dataRoomAir.AFNZoneInfo[zoneNum]
            for roomAirNodeNum in range(afnZoneInfo.NumOfAirNodes):
                InitRoomAirModelAFN(state, zoneNum, roomAirNodeNum + 1)   # 1-based to 0-based offset
                CalcRoomAirModelAFN(state, zoneNum, roomAirNodeNum + 1)
            UpdateRoomAirModelAFN(state, zoneNum)

        def LoadPredictionRoomAirModelAFN(inout state: EnergyPlusData, zoneNum: Int, roomAirNodeNum: Int):
            InitRoomAirModelAFN(state, zoneNum, roomAirNodeNum)

        def InitRoomAirModelAFN(inout state: EnergyPlusData, zoneNum: Int, roomAirNodeNum: Int):
            using InternalHeatGains.SumInternalLatentGainsByTypes
            using Psychrometrics.PsyCpAirFnW
            using Psychrometrics.PsyRhoAirFnPbTdbW

            var NodeFound: DynamicVector[Bool]
            var EquipFound: DynamicVector[Bool]
            var SupplyFrac: DynamicVector[Float64]
            var ReturnFrac: DynamicVector[Float64]

            if state.dataRoomAirflowNetModel.OneTimeFlag:   # then do one-time setup inits
                for iZone in range(1, state.dataGlobal.NumOfZones + 1):
                    var afnZoneInfo = state.dataRoomAir.AFNZoneInfo[iZone]
                    if not afnZoneInfo.IsUsed:
                        continue
                    for afnNodeIndex in range(afnZoneInfo.Node.size()):
                        var afnNode = afnZoneInfo.Node[afnNodeIndex]
                        afnNode.AirVolume = state.dataHeatBal.Zone[iZone].Volume * afnNode.ZoneVolumeFraction
                        SetupOutputVariable(
                            state,
                            "RoomAirflowNetwork Node NonAirSystemResponse",
                            Constant.Units.W,
                            afnNode.NonAirSystemResponse,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            afnNode.Name
                        )
                        SetupOutputVariable(
                            state,
                            "RoomAirflowNetwork Node SysDepZoneLoadsLagged",
                            Constant.Units.W,
                            afnNode.SysDepZoneLoadsLagged,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            afnNode.Name
                        )
                        SetupOutputVariable(
                            state,
                            "RoomAirflowNetwork Node SumIntSensibleGain",
                            Constant.Units.W,
                            afnNode.SumIntSensibleGain,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            afnNode.Name
                        )
                        SetupOutputVariable(
                            state,
                            "RoomAirflowNetwork Node SumIntLatentGain",
                            Constant.Units.W,
                            afnNode.SumIntLatentGain,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            afnNode.Name
                        )
                state.dataRoomAirflowNetModel.OneTimeFlag = false

            if state.dataRoomAirflowNetModel.OneTimeFlagConf:   # then do one-time setup inits
                if len(state.dataZoneEquip.ZoneEquipConfig) > 0 and len(state.dataZoneEquip.ZoneEquipList) > 0:
                    var MaxNodeNum: Int = 0
                    var MaxEquipNum: Int = 0
                    var ErrorsFound: Bool = false
                    for iZone in range(1, state.dataGlobal.NumOfZones + 1):
                        if not state.dataHeatBal.Zone[iZone].IsControlled:
                            continue
                        MaxEquipNum = max(MaxEquipNum, state.dataZoneEquip.ZoneEquipList[iZone].NumOfEquipTypes)
                        MaxNodeNum = max(MaxNodeNum, state.dataZoneEquip.ZoneEquipConfig[iZone].NumInletNodes)

                    if MaxNodeNum > 0:
                        NodeFound = DynamicVector[Bool](MaxNodeNum, False)
                    if MaxEquipNum > 0:
                        EquipFound = DynamicVector[Bool](MaxEquipNum, False)
                        SupplyFrac = DynamicVector[Float64](MaxEquipNum, 0.0)
                        ReturnFrac = DynamicVector[Float64](MaxEquipNum, 0.0)

                    for iZone in range(1, state.dataGlobal.NumOfZones + 1):
                        var zone = state.dataHeatBal.Zone[iZone]
                        if not zone.IsControlled:
                            continue
                        var afnZoneInfo = state.dataRoomAir.AFNZoneInfo[iZone]
                        if not afnZoneInfo.IsUsed:
                            continue
                        afnZoneInfo.ActualZoneID = iZone
                        for i in range(SupplyFrac.size()):
                            SupplyFrac[i] = 0.0
                        for i in range(ReturnFrac.size()):
                            ReturnFrac[i] = 0.0
                        for i in range(NodeFound.size()):
                            NodeFound[i] = False

                        var numAirDistUnits: Int = 0
                        var zoneEquipList = state.dataZoneEquip.ZoneEquipList[iZone]
                        var zoneEquipConfig = state.dataZoneEquip.ZoneEquipConfig[iZone]

                        for afnNodeIndex in range(afnZoneInfo.Node.size()):
                            var afnNode = afnZoneInfo.Node[afnNodeIndex]
                            for afnHVACIndex in range(afnNode.HVAC.size()):
                                var afnHVAC = afnNode.HVAC[afnHVACIndex]
                                for I in range(1, zoneEquipList.NumOfEquipTypes + 1):
                                    if zoneEquipList.EquipType[I] == DataZoneEquipment.ZoneEquipType.AirDistributionUnit:
                                        if numAirDistUnits == 0:
                                            numAirDistUnits = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "ZoneHVAC:AirDistributionUnit")
                                        if state.dataZoneAirLoopEquipmentManager.GetAirDistUnitsFlag:
                                            ZoneAirLoopEquipmentManager.GetZoneAirLoopEquipment(state)
                                            state.dataZoneAirLoopEquipmentManager.GetAirDistUnitsFlag = false
                                        for AirDistUnitNum in range(1, numAirDistUnits + 1):
                                            if zoneEquipList.EquipName[I] == state.dataDefineEquipment.AirDistUnit[AirDistUnitNum].Name:
                                                if afnHVAC.Name == state.dataDefineEquipment.AirDistUnit[AirDistUnitNum].EquipName[1]:
                                                    if afnHVAC.EquipConfigIndex == 0:
                                                        afnHVAC.EquipConfigIndex = I
                                                    EquipFound[I - 1] = True
                                                    SupplyFrac[I - 1] += afnHVAC.SupplyFraction
                                                    ReturnFrac[I - 1] += afnHVAC.ReturnFraction
                                    elif UtilityRoutines.SameString(zoneEquipList.EquipName[I], afnHVAC.Name):
                                        if afnHVAC.EquipConfigIndex == 0:
                                            afnHVAC.EquipConfigIndex = I
                                        EquipFound[I - 1] = True
                                        SupplyFrac[I - 1] += afnHVAC.SupplyFraction
                                        ReturnFrac[I - 1] += afnHVAC.ReturnFraction

                                for iNode in range(1, state.dataLoopNodes.NumOfNodes + 1):
                                    if UtilityRoutines.SameString(state.dataLoopNodes.NodeID[iNode], afnHVAC.SupplyNodeName):
                                        afnHVAC.SupNodeNum = iNode
                                        break

                                var inletNodeIndex: Int = 0
                                for iNode in range(1, zoneEquipConfig.NumInletNodes + 1):
                                    if zoneEquipConfig.InletNode[iNode] == afnHVAC.SupNodeNum:
                                        NodeFound[iNode - 1] = True
                                        inletNodeIndex = iNode
                                        break

                                if afnHVAC.SupNodeNum > 0 and afnHVAC.ReturnNodeName == "":
                                    for retNode in range(1, zoneEquipConfig.NumReturnNodes + 1):
                                        if (zoneEquipConfig.ReturnNodeInletNum[retNode] == inletNodeIndex) and (zoneEquipConfig.ReturnNode[retNode] > 0):
                                            afnHVAC.RetNodeNum = zoneEquipConfig.ReturnNode[retNode]
                                            break

                                if afnHVAC.RetNodeNum == 0:
                                    for iNode in range(1, state.dataLoopNodes.NumOfNodes + 1):
                                        if UtilityRoutines.SameString(state.dataLoopNodes.NodeID[iNode], afnHVAC.ReturnNodeName):
                                            afnHVAC.RetNodeNum = iNode
                                            break

                                SetupOutputVariable(
                                    state,
                                    "RoomAirflowNetwork Node HVAC Supply Fraction",
                                    Constant.Units.None,
                                    afnHVAC.SupplyFraction,
                                    OutputProcessor.TimeStepType.System,
                                    OutputProcessor.StoreType.Average,
                                    afnHVAC.Name
                                )
                                SetupOutputVariable(
                                    state,
                                    "RoomAirflowNetwork Node HVAC Return Fraction",
                                    Constant.Units.None,
                                    afnHVAC.ReturnFraction,
                                    OutputProcessor.TimeStepType.System,
                                    OutputProcessor.StoreType.Average,
                                    afnHVAC.Name
                                )

                        var ISum: Int = 0
                        for iNode in range(1, MaxNodeNum + 1):
                            if NodeFound[iNode - 1]:
                                ISum += 1

                        if ISum != zoneEquipConfig.NumInletNodes:
                            if ISum > zoneEquipConfig.NumInletNodes:
                                ShowSevereError(state, "GetRoomAirflowNetworkData: The number of equipment listed in RoomAirflowNetwork:Node:HVACEquipment objects")
                                ShowContinueError(state, String.format("is greater than the number of zone configuration inlet nodes in {}", zone.Name))
                                ShowContinueError(state, "Please check inputs of both objects.")
                                ErrorsFound = True
                            else:
                                ShowSevereError(state, "GetRoomAirflowNetworkData: The number of equipment listed in RoomAirflowNetwork:Node:HVACEquipment objects")
                                ShowContinueError(state, String.format("is less than the number of zone configuration inlet nodes in {}", zone.Name))
                                ShowContinueError(state, "Please check inputs of both objects.")
                                ErrorsFound = True

                        for I in range(1, zoneEquipList.NumOfEquipTypes + 1):
                            if not EquipFound[I - 1]:
                                ShowSevereError(state, "GetRoomAirflowNetworkData: The equipment listed in ZoneEquipList is not found in the lsit of RoomAir:Node:AirflowNetwork:HVACEquipment objects =")
                                ShowContinueError(state, String.format("{}. Please check inputs of both objects.", zoneEquipList.EquipName[I]))
                                ErrorsFound = True

                        for I in range(1, zoneEquipList.NumOfEquipTypes + 1):
                            if abs(SupplyFrac[I - 1] - 1.0) > 0.001:
                                ShowSevereError(state, "GetRoomAirflowNetworkData: Invalid, zone supply fractions do not sum to 1.0")
                                ShowContinueError(state, String.format("Entered in {} defined in RoomAir:Node:AirflowNetwork:HVACEquipment", zoneEquipList.EquipName[I]))
                                ShowContinueError(state, "The Fraction of supply fraction values across all the roomair nodes in a zone needs to sum to 1.0.")
                                ShowContinueError(state, String.format("The sum of fractions entered = {:.3f}", SupplyFrac[I - 1]))
                                ErrorsFound = True
                            if abs(ReturnFrac[I - 1] - 1.0) > 0.001:
                                ShowSevereError(state, "GetRoomAirflowNetworkData: Invalid, zone return fractions do not sum to 1.0")
                                ShowContinueError(state, String.format("Entered in {} defined in RoomAir:Node:AirflowNetwork:HVACEquipment", zoneEquipList.EquipName[I]))
                                ShowContinueError(state, "The Fraction of return fraction values across all the roomair nodes in a zone needs to sum to 1.0.")
                                ShowContinueError(state, String.format("The sum of fractions entered = {:.3f}", ReturnFrac[I - 1]))
                                ErrorsFound = True

                    state.dataRoomAirflowNetModel.OneTimeFlagConf = false
                    NodeFound = DynamicVector[Bool]()   # deallocate
                    if ErrorsFound:
                        ShowFatalError(state, "GetRoomAirflowNetworkData: Errors found getting air model input.  Program terminates.")
                # if allocated
            # if OneTimeFlagConf

            if state.dataGlobal.BeginEnvrnFlag and state.dataRoomAirflowNetModel.EnvrnFlag:
                for iZone in range(1, state.dataGlobal.NumOfZones + 1):
                    var afnZoneInfo = state.dataRoomAir.AFNZoneInfo[iZone]
                    if not afnZoneInfo.IsUsed:
                        continue
                    for afnNodeIndex in range(afnZoneInfo.Node.size()):
                        var afnNode = afnZoneInfo.Node[afnNodeIndex]
                        afnNode.AirTemp = 23.0
                        afnNode.AirTempX = SIMD[Float64]([23.0, 23.0, 23.0, 23.0])
                        afnNode.AirTempDSX = SIMD[Float64]([23.0, 23.0, 23.0, 23.0])
                        afnNode.AirTempT1 = 23.0
                        afnNode.AirTempTX = 23.0
                        afnNode.AirTempT2 = 23.0
                        afnNode.HumRat = 0.0
                        afnNode.HumRatX = SIMD[Float64]([0.0, 0.0, 0.0, 0.0])
                        afnNode.HumRatDSX = SIMD[Float64]([0.0, 0.0, 0.0, 0.0])
                        afnNode.HumRatT1 = 0.0
                        afnNode.HumRatTX = 0.0
                        afnNode.HumRatT2 = 0.0
                        afnNode.SysDepZoneLoadsLagged = 0.0
                        afnNode.SysDepZoneLoadsLaggedOld = 0.0
                state.dataRoomAirflowNetModel.EnvrnFlag = false

            if not state.dataGlobal.BeginEnvrnFlag:
                state.dataRoomAirflowNetModel.EnvrnFlag = True

            CalcNodeSums(state, zoneNum, roomAirNodeNum)
            SumNonAirSystemResponseForNode(state, zoneNum, roomAirNodeNum)

            var afnZoneInfo = state.dataRoomAir.AFNZoneInfo[zoneNum]
            var afnNode = afnZoneInfo.Node[roomAirNodeNum - 1]   # 1-based to 0-based
            if len(afnNode.SurfMask) > 0:
                CalcSurfaceMoistureSums(state, zoneNum, roomAirNodeNum, afnNode.SumHmAW, afnNode.SumHmARa, afnNode.SumHmARaW, afnNode.SurfMask)

            var SumLinkMCp: Float64 = 0.0
            var SumLinkMCpT: Float64 = 0.0
            var SumLinkM: Float64 = 0.0
            var SumLinkMW: Float64 = 0.0

            if afnNode.AFNNodeID > 0:
                for iLink in range(1, afnNode.NumOfAirflowLinks + 1):
                    var afnLink = afnNode.Link[iLink - 1]
                    var linkNum = afnLink.AFNSimuID
                    if state.afn.AirflowNetworkLinkageData[linkNum].NodeNums[0] == afnNode.AFNNodeID:   # incoming flow
                        var nodeInNum = state.afn.AirflowNetworkLinkageData[linkNum].NodeNums[1]
                        afnLink.TempIn = state.afn.AirflowNetworkNodeSimu[nodeInNum].TZ
                        afnLink.HumRatIn = state.afn.AirflowNetworkNodeSimu[nodeInNum].WZ
                        afnLink.MdotIn = state.afn.AirflowNetworkLinkSimu[linkNum].FLOW2
                    if state.afn.AirflowNetworkLinkageData[linkNum].NodeNums[1] == afnNode.AFNNodeID:   # outgoing flow
                        var nodeInNum = state.afn.AirflowNetworkLinkageData[linkNum].NodeNums[0]
                        afnLink.TempIn = state.afn.AirflowNetworkNodeSimu[nodeInNum].TZ
                        afnLink.HumRatIn = state.afn.AirflowNetworkNodeSimu[nodeInNum].WZ
                        afnLink.MdotIn = state.afn.AirflowNetworkLinkSimu[linkNum].FLOW

                for iLink in range(1, afnNode.NumOfAirflowLinks + 1):
                    var afnLink = afnNode.Link[iLink - 1]
                    var CpAir = PsyCpAirFnW(afnLink.HumRatIn)
                    SumLinkMCp += CpAir * afnLink.MdotIn
                    SumLinkMCpT += CpAir * afnLink.MdotIn * afnLink.TempIn
                    SumLinkM += afnLink.MdotIn
                    SumLinkMW += afnLink.MdotIn * afnLink.HumRatIn

            afnNode.SumLinkMCp = SumLinkMCp
            afnNode.SumLinkMCpT = SumLinkMCpT
            afnNode.SumLinkM = SumLinkM
            afnNode.SumLinkMW = SumLinkMW
            afnNode.SysDepZoneLoadsLagged = afnNode.SysDepZoneLoadsLaggedOld
            afnNode.RhoAir = PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress, afnNode.AirTemp, afnNode.HumRat, "InitRoomAirModelAirflowNetwork")
            afnNode.CpAir = PsyCpAirFnW(afnNode.HumRat)

        def CalcRoomAirModelAFN(inout state: EnergyPlusData, zoneNum: Int, roomAirNodeNum: Int):
            var TimeStepSysSec = state.dataHVACGlobal.TimeStepSysSec
            using Psychrometrics.PsyHgAirFnWTdb
            using Psychrometrics.PsyRhFnTdbWPb

            var NodeTempX: [Float64; 3]
            var NodeHumRatX: [Float64; 3]
            var AirTempT1: Float64
            var HumRatT1: Float64

            var afnZoneInfo = state.dataRoomAir.AFNZoneInfo[zoneNum]
            var afnNode = afnZoneInfo.Node[roomAirNodeNum - 1]

            if state.dataHVACGlobal.UseZoneTimeStepHistory:
                NodeTempX[0] = afnNode.AirTempX[0]
                NodeTempX[1] = afnNode.AirTempX[1]
                NodeTempX[2] = afnNode.AirTempX[2]
                NodeHumRatX[0] = afnNode.HumRatX[0]
                NodeHumRatX[1] = afnNode.HumRatX[1]
                NodeHumRatX[2] = afnNode.HumRatX[2]
            else:   # use down-stepped history
                NodeTempX[0] = afnNode.AirTempDSX[0]
                NodeTempX[1] = afnNode.AirTempDSX[1]
                NodeTempX[2] = afnNode.AirTempDSX[2]
                NodeHumRatX[0] = afnNode.HumRatDSX[0]
                NodeHumRatX[1] = afnNode.HumRatDSX[1]
                NodeHumRatX[2] = afnNode.HumRatDSX[2]

            if state.dataHeatBal.ZoneAirSolutionAlgo != DataHeatBalance.SolutionAlgo.ThirdOrder:
                AirTempT1 = afnNode.AirTempT1
                HumRatT1 = afnNode.HumRatT1

            var TempDepCoef = afnNode.SumHA + afnNode.SumLinkMCp + afnNode.SumSysMCp
            var TempIndCoef = afnNode.SumIntSensibleGain + afnNode.SumHATsurf - afnNode.SumHATref + afnNode.SumLinkMCpT + afnNode.SumSysMCpT + afnNode.NonAirSystemResponse + afnNode.SysDepZoneLoadsLagged
            var AirCap = afnNode.AirVolume * state.dataHeatBal.Zone[zoneNum].ZoneVolCapMultpSens * afnNode.RhoAir * afnNode.CpAir / TimeStepSysSec

            if state.dataHeatBal.ZoneAirSolutionAlgo == DataHeatBalance.SolutionAlgo.AnalyticalSolution:
                if TempDepCoef == 0.0:   # B=0
                    afnNode.AirTemp = AirTempT1 + TempIndCoef / AirCap
                else:
                    afnNode.AirTemp = (AirTempT1 - TempIndCoef / TempDepCoef) * exp(min(700.0, -TempDepCoef / AirCap)) + TempIndCoef / TempDepCoef
            elif state.dataHeatBal.ZoneAirSolutionAlgo == DataHeatBalance.SolutionAlgo.EulerMethod:
                afnNode.AirTemp = (AirCap * AirTempT1 + TempIndCoef) / (AirCap + TempDepCoef)
            else:
                afnNode.AirTemp = (TempIndCoef + AirCap * (3.0 * NodeTempX[0] - (3.0 / 2.0) * NodeTempX[1] + (1.0 / 3.0) * NodeTempX[2])) / ((11.0 / 6.0) * AirCap + TempDepCoef)

            var H2OHtOfVap = PsyHgAirFnWTdb(afnNode.HumRat, afnNode.AirTemp)
            var A = afnNode.SumLinkM + afnNode.SumHmARa + afnNode.SumSysM
            var B = (afnNode.SumIntLatentGain / H2OHtOfVap) + afnNode.SumSysMW + afnNode.SumLinkMW + afnNode.SumHmARaW
            var C = afnNode.RhoAir * afnNode.AirVolume * state.dataHeatBal.Zone[zoneNum].ZoneVolCapMultpMoist / TimeStepSysSec

            if state.dataHeatBal.ZoneAirSolutionAlgo == DataHeatBalance.SolutionAlgo.AnalyticalSolution:
                if A == 0.0:   # B=0
                    afnNode.HumRat = HumRatT1 + B / C
                else:
                    afnNode.HumRat = (HumRatT1 - B / A) * exp(min(700.0, -A / C)) + B / A
            elif state.dataHeatBal.ZoneAirSolutionAlgo == DataHeatBalance.SolutionAlgo.EulerMethod:
                afnNode.HumRat = (C * HumRatT1 + B) / (C + A)
            else:
                afnNode.HumRat = (B + C * (3.0 * NodeHumRatX[0] - (3.0 / 2.0) * NodeHumRatX[1] + (1.0 / 3.0) * NodeHumRatX[2])) / ((11.0 / 6.0) * C + A)

            afnNode.AirCap = AirCap
            afnNode.AirHumRat = C
            afnNode.RelHumidity = PsyRhFnTdbWPb(state, afnNode.AirTemp, afnNode.HumRat, state.dataEnvrn.OutBaroPress, "CalcRoomAirModelAirflowNetwork") * 100.0

        def UpdateRoomAirModelAFN(inout state: EnergyPlusData, zoneNum: Int):
            var afnZoneInfo = state.dataRoomAir.AFNZoneInfo[zoneNum]
            if not afnZoneInfo.IsUsed:
                return
            if not state.dataGlobal.ZoneSizingCalc:
                SumSystemDepResponseForNode(state, zoneNum)

            for I in range(1, state.dataZoneEquip.ZoneEquipList[zoneNum].NumOfEquipTypes + 1):
                var SumMass: Float64 = 0.0
                var SumMassT: Float64 = 0.0
                var SumMassW: Float64 = 0.0
                var RetNodeNum: Int = 0
                for afnNodeIndex in range(afnZoneInfo.Node.size()):
                    var afnNode = afnZoneInfo.Node[afnNodeIndex]
                    for afnHVACIndex in range(afnNode.HVAC.size()):
                        var afnHVAC = afnNode.HVAC[afnHVACIndex]
                        if afnHVAC.EquipConfigIndex == I and afnHVAC.SupNodeNum > 0 and afnHVAC.RetNodeNum > 0:
                            var NodeMass = state.dataLoopNodes.Node[afnHVAC.SupNodeNum].MassFlowRate * afnHVAC.ReturnFraction
                            SumMass += NodeMass
                            SumMassT += NodeMass * afnNode.AirTemp
                            SumMassW += NodeMass * afnNode.HumRat
                            RetNodeNum = afnHVAC.RetNodeNum
                if SumMass > 0.0:
                    state.dataLoopNodes.Node[RetNodeNum].Temp = SumMassT / SumMass
                    state.dataLoopNodes.Node[RetNodeNum].HumRat = SumMassW / SumMass

        def CalcNodeSums(inout state: EnergyPlusData, zoneNum: Int, roomAirNodeNum: Int):
            using InternalHeatGains.SumInternalConvectionGainsByIndices
            using InternalHeatGains.SumInternalLatentGainsByIndices
            using InternalHeatGains.SumReturnAirConvectionGainsByIndices
            using InternalHeatGains.SumReturnAirConvectionGainsByTypes
            using Psychrometrics.PsyCpAirFnW
            using Psychrometrics.PsyRhoAirFnPbTdbW

            var HA: Float64
            var Area: Float64
            var RefAirTemp: Float64
            var Found: Bool

            var SumIntGain: Float64 = 0.0
            var SumHA: Float64 = 0.0
            var SumHATsurf: Float64 = 0.0
            var SumHATref: Float64 = 0.0
            var SumSysMCp: Float64 = 0.0
            var SumSysMCpT: Float64 = 0.0
            var SumSysM: Float64 = 0.0
            var SumSysMW: Float64 = 0.0

            var zone = state.dataHeatBal.Zone[zoneNum]
            var afnZoneInfo = state.dataRoomAir.AFNZoneInfo[zoneNum]
            var afnNode = afnZoneInfo.Node[roomAirNodeNum - 1]

            afnNode.SumIntSensibleGain = SumInternalConvectionGainsByIndices(state, afnNode.NumIntGains, afnNode.intGainsDeviceSpaces, afnNode.IntGainsDeviceIndices, afnNode.IntGainsFractions)
            afnNode.SumIntLatentGain = SumInternalLatentGainsByIndices(state, afnNode.NumIntGains, afnNode.intGainsDeviceSpaces, afnNode.IntGainsDeviceIndices, afnNode.IntGainsFractions)

            if state.dataHeatBal.Zone[zoneNum].NoHeatToReturnAir:
                SumIntGain = SumReturnAirConvectionGainsByIndices(state, afnNode.NumIntGains, afnNode.intGainsDeviceSpaces, afnNode.IntGainsDeviceIndices, afnNode.IntGainsFractions)
                afnNode.SumIntSensibleGain += SumIntGain

            var zoneRetPlenumNum: Int = 0
            for iPlenum in range(1, state.dataZonePlenum.NumZoneReturnPlenums + 1):
                if state.dataZonePlenum.ZoneRetPlenCond[iPlenum].ActualZoneNum != zoneNum:
                    continue
                zoneRetPlenumNum = iPlenum
                break

            var zoneSupPlenumNum: Int = 0
            for iPlenum in range(1, state.dataZonePlenum.NumZoneSupplyPlenums + 1):
                if state.dataZonePlenum.ZoneSupPlenCond[iPlenum].ActualZoneNum != zoneNum:
                    continue
                zoneSupPlenumNum = iPlenum
                break

            var zoneHB = state.dataZoneTempPredictorCorrector.zoneHeatBalance[zoneNum]

            if zone.IsControlled:
                var zoneEquipConfig = state.dataZoneEquip.ZoneEquipConfig[zoneNum]
                for iNode in range(1, zoneEquipConfig.NumInletNodes + 1):
                    var inletNode = state.dataLoopNodes.Node[zoneEquipConfig.InletNode[iNode]]
                    for afnHVACIndex in range(afnNode.HVAC.size()):
                        var afnHVAC = afnNode.HVAC[afnHVACIndex]
                        if afnHVAC.SupNodeNum == zoneEquipConfig.InletNode[iNode]:
                            var MassFlowRate = inletNode.MassFlowRate * afnHVAC.SupplyFraction
                            var CpAir = PsyCpAirFnW(zoneHB.airHumRat)
                            SumSysMCp += MassFlowRate * CpAir
                            SumSysMCpT += MassFlowRate * CpAir * inletNode.Temp
                            SumSysM += MassFlowRate
                            SumSysMW += MassFlowRate * inletNode.HumRat
                    # EquipLoop
                # NodeNum
            elif zoneRetPlenumNum != 0:
                var zoneRetPlenum = state.dataZonePlenum.ZoneRetPlenCond[zoneRetPlenumNum]
                for iNode in range(1, zoneRetPlenum.NumInletNodes + 1):
                    var zoneRetPlenumNode = state.dataLoopNodes.Node[zoneRetPlenum.InletNode[iNode]]
                    var CpAir = PsyCpAirFnW(zoneHB.airHumRat)
                    SumSysMCp += zoneRetPlenumNode.MassFlowRate * CpAir
                    SumSysMCpT += zoneRetPlenumNode.MassFlowRate * CpAir * zoneRetPlenumNode.Temp
                # NodeNum
                for iADU in range(1, zoneRetPlenum.NumADUs + 1):
                    var ADUNum = zoneRetPlenum.ADUIndex[iADU]
                    var adu = state.dataDefineEquipment.AirDistUnit[ADUNum]
                    if adu.UpStreamLeak:
                        var CpAir = PsyCpAirFnW(zoneHB.airHumRat)
                        SumSysMCp += adu.MassFlowRateUpStrLk * CpAir
                        SumSysMCpT += adu.MassFlowRateUpStrLk * CpAir * state.dataLoopNodes.Node[adu.InletNodeNum].Temp
                    if adu.DownStreamLeak:
                        var CpAir = PsyCpAirFnW(zoneHB.airHumRat)
                        SumSysMCp += adu.MassFlowRateDnStrLk * CpAir
                        SumSysMCpT += adu.MassFlowRateDnStrLk * CpAir * state.dataLoopNodes.Node[adu.OutletNodeNum].Temp
                # ADUListIndex
            elif zoneSupPlenumNum != 0:
                var zoneSupPlenum = state.dataZonePlenum.ZoneSupPlenCond[zoneSupPlenumNum]
                var inletNode = state.dataLoopNodes.Node[zoneSupPlenum.InletNode]
                var CpAir = PsyCpAirFnW(zoneHB.airHumRat)
                SumSysMCp += inletNode.MassFlowRate * CpAir
                SumSysMCpT += inletNode.MassFlowRate * CpAir * inletNode.Temp

            if not zone.leakageParallelPIUNums.is_empty():
                var CpAir = PsyCpAirFnW(zoneHB.airHumRat)
                for piuNum in range(1, len(state.dataHeatBal.Zone[zoneNum].leakageParallelPIUNums) + 1):
                    const thisPIU = state.dataPowerInductionUnits.PIU[piuNum + 1]
                    if thisPIU.leakFlow > 0:
                        SumSysMCp += thisPIU.leakFlow * CpAir
                        SumSysMCpT += thisPIU.leakFlow * CpAir * state.dataLoopNodes.Node[thisPIU.PriAirInNode].Temp

            var ZoneMult = zone.Multiplier * zone.ListMultiplier
            SumSysMCp /= ZoneMult
            SumSysMCpT /= ZoneMult
            SumSysM /= ZoneMult
            SumSysMW /= ZoneMult

            if not afnNode.HasSurfacesAssigned:
                return

            var surfCount: Int = 0
            for spaceNum in state.dataHeatBal.Zone[zoneNum].spaceIndexes:
                var thisSpace = state.dataHeatBal.space[spaceNum]
                for SurfNum in range(thisSpace.HTSurfaceFirst, thisSpace.HTSurfaceLast + 1):
                    surfCount += 1
                    if afnZoneInfo.ControlAirNodeID == roomAirNodeNum:
                        Found = False
                        for Loop in range(1, afnZoneInfo.NumOfAirNodes + 1):
                            if Loop != roomAirNodeNum:
                                if afnZoneInfo.Node[Loop - 1].SurfMask[surfCount - 1]:
                                    Found = True
                                    break
                        if Found:
                            continue
                    else:
                        if not afnNode.SurfMask[surfCount - 1]:
                            continue

                    HA = 0.0
                    Area = state.dataSurface.Surface[SurfNum].Area   # For windows, this is the glazing area
                    if state.dataSurface.Surface[SurfNum].Class == DataSurfaces.SurfaceClass.Window:
                        if DataSurfaces.ANY_INTERIOR_SHADE_BLIND(state.dataSurface.SurfWinShadingFlag[SurfNum]):
                            Area += state.dataSurface.SurfWinDividerArea[SurfNum]
                            SumIntGain += state.dataSurface.SurfWinDividerHeatGain[SurfNum]
                        if DataSurfaces.ANY_INTERIOR_SHADE_BLIND(state.dataSurface.SurfWinShadingFlag[SurfNum]):
                            SumIntGain += state.dataSurface.SurfWinConvHeatFlowNatural[SurfNum]
                        if state.dataSurface.SurfWinAirflowThisTS[SurfNum] > 0.0:
                            SumIntGain += state.dataSurface.SurfWinConvHeatGainToZoneAir[SurfNum]
                            if zone.NoHeatToReturnAir:
                                SumIntGain += state.dataSurface.SurfWinRetHeatGainToZoneAir[SurfNum]
                                state.dataSurface.SurfWinHeatGain[SurfNum] += state.dataSurface.SurfWinRetHeatGainToZoneAir[SurfNum]
                                if state.dataSurface.SurfWinHeatGain[SurfNum] >= 0.0:
                                    state.dataSurface.SurfWinHeatGainRep[SurfNum] = state.dataSurface.SurfWinHeatGain[SurfNum]
                                    state.dataSurface.SurfWinHeatGainRepEnergy[SurfNum] = state.dataSurface.SurfWinHeatGainRep[SurfNum] * state.dataGlobal.TimeStepZone * Constant.rSecsInHour
                                else:
                                    state.dataSurface.SurfWinHeatLossRep[SurfNum] = -state.dataSurface.SurfWinHeatGain[SurfNum]
                                    state.dataSurface.SurfWinHeatLossRepEnergy[SurfNum] = state.dataSurface.SurfWinHeatLossRep[SurfNum] * state.dataGlobal.TimeStepZone * Constant.rSecsInHour
                                state.dataSurface.SurfWinHeatTransferRepEnergy[SurfNum] = state.dataSurface.SurfWinHeatGain[SurfNum] * state.dataGlobal.TimeStepZone * Constant.rSecsInHour
                        if state.dataSurface.SurfWinFrameArea[SurfNum] > 0.0:
                            SumHATsurf += state.dataHeatBalSurf.SurfHConvInt[SurfNum] * state.dataSurface.SurfWinFrameArea[SurfNum] * (1.0 + state.dataSurface.SurfWinProjCorrFrIn[SurfNum]) * state.dataSurface.SurfWinFrameTempIn[SurfNum]
                            HA += state.dataHeatBalSurf.SurfHConvInt[SurfNum] * state.dataSurface.SurfWinFrameArea[SurfNum] * (1.0 + state.dataSurface.SurfWinProjCorrFrIn[SurfNum])
                        if state.dataSurface.SurfWinDividerArea[SurfNum] > 0.0 and not DataSurfaces.ANY_INTERIOR_SHADE_BLIND(state.dataSurface.SurfWinShadingFlag[SurfNum]):
                            SumHATsurf += state.dataHeatBalSurf.SurfHConvInt[SurfNum] * state.dataSurface.SurfWinDividerArea[SurfNum] * (1.0 + 2.0 * state.dataSurface.SurfWinProjCorrDivIn[SurfNum]) * state.dataSurface.SurfWinDividerTempIn[SurfNum]
                            HA += state.dataHeatBalSurf.SurfHConvInt[SurfNum] * state.dataSurface.SurfWinDividerArea[SurfNum] * (1.0 + 2.0 * state.dataSurface.SurfWinProjCorrDivIn[SurfNum])
                    # End of check if window
                    HA += state.dataHeatBalSurf.SurfHConvInt[SurfNum] * Area
                    SumHATsurf += state.dataHeatBalSurf.SurfHConvInt[SurfNum] * Area * state.dataHeatBalSurf.SurfTempInTmp[SurfNum]

                    if state.dataSurface.SurfTAirRef[SurfNum] == DataSurfaces.RefAirTemp.ZoneMeanAirTemp:
                        RefAirTemp = zoneHB.MAT
                        SumHA += HA
                    elif state.dataSurface.SurfTAirRef[SurfNum] == DataSurfaces.RefAirTemp.AdjacentAirTemp:
                        RefAirTemp = state.dataHeatBal.SurfTempEffBulkAir[SurfNum]
                        SumHATref += HA * RefAirTemp
                    elif state.dataSurface.SurfTAirRef[SurfNum] == DataSurfaces.RefAirTemp.ZoneSupplyAirTemp:
                        if not zone.IsControlled:
                            ShowFatalError(state, String.format("Zones must be controlled for Ceiling-Diffuser Convection model. No system serves zone {}", zone.Name))
                            return
                        RefAirTemp = SumSysMCpT / SumSysMCp
                        SumHATref += HA * RefAirTemp
                    else:
                        RefAirTemp = zoneHB.MAT
                        SumHA += HA
                    # SurfNum

            afnNode.SumHA = SumHA
            afnNode.SumHATsurf = SumHATsurf
            afnNode.SumHATref = SumHATref
            afnNode.SumSysMCp = SumSysMCp
            afnNode.SumSysMCpT = SumSysMCpT
            afnNode.SumSysM = SumSysM
            afnNode.SumSysMW = SumSysMW

        def CalcSurfaceMoistureSums(
            inout state: EnergyPlusData,
            zoneNum: Int,
            roomAirNodeNum: Int,
            inout SumHmAW: Float64,
            inout SumHmARa: Float64,
            inout SumHmARaW: Float64,
            SurfMask: DynamicVector[Bool]
        ):
            using HeatBalanceHAMTManager.UpdateHeatBalHAMT
            using MoistureBalanceEMPDManager.UpdateMoistureBalanceEMPD
            using Psychrometrics.PsyRhFnTdbRhov
            using Psychrometrics.PsyRhFnTdbRhovLBnd0C
            using Psychrometrics.PsyRhoAirFnPbTdbW
            using Psychrometrics.PsyWFnTdbRhPb

            SumHmAW = 0.0
            SumHmARa = 0.0
            SumHmARaW = 0.0

            var afnZoneInfo = state.dataRoomAir.AFNZoneInfo[zoneNum]
            var surfCount: Int = 1
            for spaceNum in state.dataHeatBal.Zone[zoneNum].spaceIndexes:
                var thisSpace = state.dataHeatBal.space[spaceNum]
                for SurfNum in range(thisSpace.HTSurfaceFirst, thisSpace.HTSurfaceLast + 1):
                    var surf = state.dataSurface.Surface[SurfNum]
                    if surf.Class == SurfaceClass.Window:
                        continue
                    if afnZoneInfo.ControlAirNodeID == roomAirNodeNum:
                        var Found: Bool = False
                        for Loop in range(1, afnZoneInfo.NumOfAirNodes + 1):
                            if (Loop != roomAirNodeNum) and afnZoneInfo.Node[Loop - 1].SurfMask[surfCount - 1]:
                                Found = True
                                break
                        if Found:
                            continue
                    else:
                        if not afnZoneInfo.Node[roomAirNodeNum - 1].SurfMask[surfCount - 1]:
                            continue

                    var HMassConvInFD = state.dataMstBal.HMassConvInFD[SurfNum]
                    var RhoVaporSurfIn = state.dataMstBal.RhoVaporSurfIn[SurfNum]
                    var RhoVaporAirIn = state.dataMstBal.RhoVaporAirIn[SurfNum]

                    if surf.HeatTransferAlgorithm == DataSurfaces.HeatTransferModel.HAMT:
                        UpdateHeatBalHAMT(state, SurfNum)
                        SumHmAW += HMassConvInFD * surf.Area * (RhoVaporSurfIn - RhoVaporAirIn)
                        var RhoAirZone = PsyRhoAirFnPbTdbW(
                            state,
                            state.dataEnvrn.OutBaroPress,
                            state.dataZoneTempPredictorCorrector.zoneHeatBalance[surf.Zone].MAT,
                            PsyRhFnTdbRhov(state, state.dataZoneTempPredictorCorrector.zoneHeatBalance[state.dataSurface.Surface[SurfNum].Zone].MAT, RhoVaporAirIn, "RhoAirZone")
                        )
                        var Wsurf = PsyWFnTdbRhPb(state,
                            state.dataHeatBalSurf.SurfTempInTmp[SurfNum],
                            PsyRhFnTdbRhov(state, state.dataHeatBalSurf.SurfTempInTmp[SurfNum], RhoVaporSurfIn, "Wsurf"),
                            state.dataEnvrn.OutBaroPress
                        )
                        SumHmARa += HMassConvInFD * surf.Area * RhoAirZone
                        SumHmARaW += HMassConvInFD * surf.Area * RhoAirZone * Wsurf
                    elif surf.HeatTransferAlgorithm == DataSurfaces.HeatTransferModel.EMPD:
                        UpdateMoistureBalanceEMPD(state, SurfNum)
                        RhoVaporSurfIn = state.dataMstBalEMPD.RVSurface[SurfNum]
                        SumHmAW += HMassConvInFD * surf.Area * (RhoVaporSurfIn - RhoVaporAirIn)
                        SumHmARa += HMassConvInFD * surf.Area * PsyRhoAirFnPbTdbW(state,
                            state.dataEnvrn.OutBaroPress,
                            state.dataHeatBalSurf.SurfTempInTmp[SurfNum],
                            PsyWFnTdbRhPb(state,
                                state.dataHeatBalSurf.SurfTempInTmp[SurfNum],
                                PsyRhFnTdbRhovLBnd0C(state, state.dataHeatBalSurf.SurfTempInTmp[SurfNum], RhoVaporAirIn),
                                state.dataEnvrn.OutBaroPress
                            )
                        )
                        SumHmARaW += HMassConvInFD * surf.Area * RhoVaporSurfIn
                    surfCount += 1
                # for (SurfNum)
            # for (spaceNum)

        def SumNonAirSystemResponseForNode(inout state: EnergyPlusData, zoneNum: Int, roomAirNodeNum: Int):
            using BaseboardElectric.SimElectricBaseboard
            using BaseboardRadiator.SimBaseboard
            using ElectricBaseboardRadiator.SimElecBaseboard
            using HighTempRadiantSystem.SimHighTempRadiantSystem
            using HWBaseboardRadiator.SimHWBaseboard
            using RefrigeratedCase.SimAirChillerSet
            using SteamBaseboardRadiator.SimSteamBaseboard

            var SysOutputProvided: Float64
            var LatOutputProvided: Float64

            var afnZoneInfo = state.dataRoomAir.AFNZoneInfo[zoneNum]
            var afnNode = afnZoneInfo.Node[roomAirNodeNum - 1]
            afnNode.NonAirSystemResponse = 0.0

            if len(state.dataZoneEquip.ZoneEquipConfig) == 0:
                return

            for afnHVACIndex in range(afnNode.HVAC.size()):
                var afnHVAC = afnNode.HVAC[afnHVACIndex]
                switch afnHVAC.zoneEquipType:
                    case DataZoneEquipment.ZoneEquipType.BaseboardWater:
                        SimHWBaseboard(state, afnHVAC.Name, zoneNum, False, SysOutputProvided, afnHVAC.CompIndex)
                        afnNode.NonAirSystemResponse += afnHVAC.SupplyFraction * SysOutputProvided
                    case DataZoneEquipment.ZoneEquipType.BaseboardSteam:
                        SimSteamBaseboard(state, afnHVAC.Name, zoneNum, False, SysOutputProvided, afnHVAC.CompIndex)
                        afnNode.NonAirSystemResponse += afnHVAC.SupplyFraction * SysOutputProvided
                    case DataZoneEquipment.ZoneEquipType.BaseboardConvectiveWater:
                        SimBaseboard(state, afnHVAC.Name, zoneNum, False, SysOutputProvided, afnHVAC.CompIndex)
                        afnNode.NonAirSystemResponse += afnHVAC.SupplyFraction * SysOutputProvided
                    case DataZoneEquipment.ZoneEquipType.BaseboardConvectiveElectric:
                        SimElectricBaseboard(state, afnHVAC.Name, zoneNum, SysOutputProvided, afnHVAC.CompIndex)
                        afnNode.NonAirSystemResponse += afnHVAC.SupplyFraction * SysOutputProvided
                    case DataZoneEquipment.ZoneEquipType.RefrigerationChillerSet:
                        SimAirChillerSet(state, afnHVAC.Name, zoneNum, False, SysOutputProvided, LatOutputProvided, afnHVAC.CompIndex)
                        afnNode.NonAirSystemResponse += afnHVAC.SupplyFraction * SysOutputProvided
                    case DataZoneEquipment.ZoneEquipType.BaseboardElectric:
                        SimElecBaseboard(state, afnHVAC.Name, zoneNum, False, SysOutputProvided, afnHVAC.CompIndex)
                        afnNode.NonAirSystemResponse += afnHVAC.SupplyFraction * SysOutputProvided
                    case DataZoneEquipment.ZoneEquipType.HighTemperatureRadiant:
                        SimHighTempRadiantSystem(state, afnHVAC.Name, False, SysOutputProvided, afnHVAC.CompIndex)
                        afnNode.NonAirSystemResponse += afnHVAC.SupplyFraction * SysOutputProvided
                    case _:

                # switch

        def SumSystemDepResponseForNode(inout state: EnergyPlusData, zoneNum: Int):
            using ZoneDehumidifier.SimZoneDehumidifier

            var LatOutputProvided: Float64
            var afnZoneInfo = state.dataRoomAir.AFNZoneInfo[zoneNum]
            var SysOutputProvided: Float64 = 0.0

            for afnNodeIndex in range(afnZoneInfo.Node.size()):
                var afnNode = afnZoneInfo.Node[afnNodeIndex]
                afnNode.SysDepZoneLoadsLaggedOld = 0.0
                for afnHVACIndex in range(afnNode.HVAC.size()):
                    var afnHVAC = afnNode.HVAC[afnHVACIndex]
                    if afnHVAC.zoneEquipType == DataZoneEquipment.ZoneEquipType.DehumidifierDX:
                        if SysOutputProvided == 0.0:
                            SimZoneDehumidifier(state, afnHVAC.Name, zoneNum, False, SysOutputProvided, LatOutputProvided, afnHVAC.CompIndex)
                        if SysOutputProvided > 0.0:
                            break

            if SysOutputProvided > 0.0:
                for afnNodeIndex in range(afnZoneInfo.Node.size()):
                    var afnNode = afnZoneInfo.Node[afnNodeIndex]
                    for afnHVACIndex in range(afnNode.HVAC.size()):
                        var afnHVAC = afnNode.HVAC[afnHVACIndex]
                        if afnHVAC.zoneEquipType == DataZoneEquipment.ZoneEquipType.DehumidifierDX:
                            afnNode.SysDepZoneLoadsLaggedOld += afnHVAC.SupplyFraction * SysOutputProvided


struct RoomAirModelAirflowNetworkData(BaseGlobalStruct):
    var OneTimeFlag: Bool = True
    var OneTimeFlagConf: Bool = True
    var EnvrnFlag: Bool = True

    def init_constant_state(inout self, inout state: EnergyPlusData) -> None:

    def init_state(inout self, inout state: EnergyPlusData) -> None:

    def clear_state(inout self) -> None:
        self.OneTimeFlag = True
        self.OneTimeFlagConf = True
        self.EnvrnFlag = True