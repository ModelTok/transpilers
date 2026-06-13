from testing import *
from .Fixtures.EnergyPlusFixture import EnergyPlusFixture
from AirflowNetwork.Solver import *
from EnergyPlus.CrossVentMgr import *
from EnergyPlus.Data.EnergyPlusData import *
from EnergyPlus.DataDefineEquip import *
from EnergyPlus.DataEnvironment import *
from EnergyPlus.DataHVACGlobals import *
from EnergyPlus.DataHeatBalFanSys import *
from EnergyPlus.DataHeatBalSurface import *
from EnergyPlus.DataHeatBalance import *
from EnergyPlus.DataLoopNode import *
from EnergyPlus.DataMoistureBalance import *
from EnergyPlus.DataMoistureBalanceEMPD import *
from EnergyPlus.DataRoomAirModel import *
from EnergyPlus.DataSizing import *
from EnergyPlus.DataSurfaces import *
from EnergyPlus.DataZoneEquipment import *
from EnergyPlus.DisplacementVentMgr import *
from EnergyPlus.FanCoilUnits import *
from EnergyPlus.Fans import *
from EnergyPlus.General import *
from EnergyPlus.HVACStandAloneERV import *
from EnergyPlus.HVACVariableRefrigerantFlow import *
from EnergyPlus.HeatBalanceManager import *
from EnergyPlus.HybridUnitaryAirConditioners import *
from EnergyPlus.InputProcessing.InputProcessor import *
from EnergyPlus.InternalHeatGains import *
from EnergyPlus.Material import *
from EnergyPlus.MixedAir import *
from EnergyPlus.MundtSimMgr import *
from EnergyPlus.OutdoorAirUnit import *
from EnergyPlus.OutputProcessor import *
from EnergyPlus.Psychrometrics import *
from EnergyPlus.PurchasedAirManager import *
from EnergyPlus.RoomAirModelAirflowNetwork import *
from EnergyPlus.RoomAirModelManager import *
from EnergyPlus.RoomAirModelUserTempPattern import *
from EnergyPlus.ScheduleManager import *
from EnergyPlus.SurfaceGeometry import *
from EnergyPlus.UFADManager import *
from EnergyPlus.UnitHeater import *
from EnergyPlus.UnitVentilator import *
from EnergyPlus.UtilityRoutines import *
from EnergyPlus.VentilatedSlab import *
from EnergyPlus.WaterThermalTanks import *
from EnergyPlus.WindowAC import *
from EnergyPlus.ZoneAirLoopEquipmentManager import *
from EnergyPlus.ZoneDehumidifier import *
from EnergyPlus.ZoneEquipmentManager import *
from EnergyPlus.ZoneTempPredictorCorrector import *

class RoomAirflowNetworkTest(EnergyPlusFixture):
    def SetUp(self) raises:
        EnergyPlusFixture.SetUp(self)
        state.dataSize.CurZoneEqNum = 0
        state.dataSize.CurSysNum = 0
        state.dataSize.CurOASysNum = 0
        state.dataGlobal.NumOfZones = 1
        state.dataGlobal.numSpaces = 1
        state.dataLoopNodes.NumOfNodes = 5
        state.dataGlobal.BeginEnvrnFlag = True
        NumOfSurfaces = 2
        state.dataRoomAir.AFNZoneInfo.allocate(state.dataGlobal.NumOfZones)
        state.dataHeatBal.Zone.allocate(state.dataGlobal.NumOfZones)
        state.dataHeatBal.space.allocate(state.dataGlobal.numSpaces)
        state.dataZoneEquip.ZoneEquipConfig.allocate(state.dataGlobal.NumOfZones)
        state.dataZoneEquip.ZoneEquipList.allocate(state.dataGlobal.NumOfZones)
        state.dataHeatBal.ZoneIntGain.allocate(state.dataGlobal.NumOfZones)
        state.dataHeatBal.spaceIntGainDevices.allocate(state.dataGlobal.numSpaces)
        state.dataLoopNodes.NodeID.allocate(state.dataLoopNodes.NumOfNodes)
        state.dataLoopNodes.Node.allocate(state.dataLoopNodes.NumOfNodes)
        state.dataSurface.Surface.allocate(NumOfSurfaces)
        state.dataSurface.SurfTAirRef.allocate(NumOfSurfaces)
        state.dataHeatBalSurf.SurfHConvInt.allocate(NumOfSurfaces)
        state.dataHeatBalSurf.SurfTempInTmp.allocate(NumOfSurfaces)
        state.dataMstBalEMPD.RVSurface.allocate(NumOfSurfaces)
        state.dataMstBalEMPD.RVSurfaceOld.allocate(NumOfSurfaces)
        state.dataMstBalEMPD.RVDeepLayer.allocate(NumOfSurfaces)
        state.dataMstBalEMPD.RVdeepOld.allocate(NumOfSurfaces)
        state.dataMstBalEMPD.RVSurfLayerOld.allocate(NumOfSurfaces)
        state.dataMstBalEMPD.RVSurfLayer.allocate(NumOfSurfaces)
        state.dataMstBal.RhoVaporSurfIn.allocate(NumOfSurfaces)
        state.dataMstBal.RhoVaporAirIn.allocate(NumOfSurfaces)
        state.dataMstBal.HMassConvInFD.allocate(NumOfSurfaces)
        state.dataZoneTempPredictorCorrector.zoneHeatBalance.allocate(state.dataGlobal.NumOfZones)
        state.afn.AirflowNetworkLinkageData.allocate(5)
        state.afn.AirflowNetworkNodeSimu.allocate(6)
        state.afn.AirflowNetworkLinkSimu.allocate(5)

    def TearDown(self) raises:
        EnergyPlusFixture.TearDown(self)

    # TEST_F(RoomAirflowNetworkTest, RAFNTest)
    @test
    def RAFNTest(self) raises:
        NumOfAirNodes = 2
        ZoneNum = 1
        RoomAirNode = 0  # placeholder, will be set later
        state.dataHVACGlobal.TimeStepSys = 15.0 / 60.0
        state.dataHVACGlobal.TimeStepSysSec = state.dataHVACGlobal.TimeStepSys * Constant.rSecsInHour
        state.dataEnvrn.OutBaroPress = 101325.0
        state.dataHeatBal.Zone[ZoneNum - 1].ZoneVolCapMultpSens = 1
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].IsUsed = True
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].ActualZoneID = ZoneNum
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].NumOfAirNodes = NumOfAirNodes
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node.allocate(NumOfAirNodes)
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].ControlAirNodeID = 1
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[0].ZoneVolumeFraction = 0.2
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[1].ZoneVolumeFraction = 0.8
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[0].HVAC.allocate(1)
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[1].HVAC.allocate(1)
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[0].NumHVACs = 1
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[1].NumHVACs = 1
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[0].HVAC[0].SupplyFraction = 0.4
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[1].HVAC[0].SupplyFraction = 0.6
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[0].HVAC[0].ReturnFraction = 0.4
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[1].HVAC[0].ReturnFraction = 0.6
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[0].HVAC[0].Name = "ZoneHVAC"
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[1].HVAC[0].Name = "ZoneHVAC"
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[0].HVAC[0].SupplyNodeName = "Supply"
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[1].HVAC[0].SupplyNodeName = "Supply"
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[0].HVAC[0].ReturnNodeName = "Return"
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[1].HVAC[0].ReturnNodeName = "Return"
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[0].HVAC[0].Name = "ZoneHVAC"
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[1].HVAC[0].Name = "ZoneHVAC"
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[0].IntGainsDeviceIndices.allocate(1)
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[1].IntGainsDeviceIndices.allocate(1)
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[0].intGainsDeviceSpaces.allocate(1)
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[1].intGainsDeviceSpaces.allocate(1)
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[0].NumIntGains = 1
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[1].NumIntGains = 1
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[0].IntGainsDeviceIndices[0] = 1
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[1].IntGainsDeviceIndices[0] = 1
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[0].intGainsDeviceSpaces[0] = 1
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[1].intGainsDeviceSpaces[0] = 1
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[0].IntGainsFractions.allocate(1)
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[1].IntGainsFractions.allocate(1)
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[0].IntGainsFractions[0] = 0.4
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[1].IntGainsFractions[0] = 0.6
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[0].HasIntGainsAssigned = True
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[1].HasIntGainsAssigned = True
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[0].HasSurfacesAssigned = True
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[1].HasSurfacesAssigned = True
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[0].HasHVACAssigned = True
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[1].HasHVACAssigned = True
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[0].SurfMask.allocate(2)
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[1].SurfMask.allocate(2)
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[0].SurfMask[0] = True
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[0].SurfMask[1] = False
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[1].SurfMask[0] = False
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[1].SurfMask[1] = True
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[0].NumOfAirflowLinks = 3
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[0].Link.allocate(3)
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[0].Link[0].AFNSimuID = 1
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[0].Link[1].AFNSimuID = 2
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[0].Link[2].AFNSimuID = 3
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[0].AFNNodeID = 1
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[1].NumOfAirflowLinks = 3
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[1].Link.allocate(3)
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[1].Link[0].AFNSimuID = 3
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[1].Link[1].AFNSimuID = 4
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[1].Link[2].AFNSimuID = 5
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[1].AFNNodeID = 2
        state.afn.AirflowNetworkLinkageData[0].NodeNums[0] = 1
        state.afn.AirflowNetworkLinkageData[1].NodeNums[0] = 1
        state.afn.AirflowNetworkLinkageData[2].NodeNums[0] = 1
        state.afn.AirflowNetworkLinkageData[0].NodeNums[1] = 3
        state.afn.AirflowNetworkLinkageData[1].NodeNums[1] = 4
        state.afn.AirflowNetworkLinkageData[2].NodeNums[1] = 2
        state.afn.AirflowNetworkLinkageData[3].NodeNums[0] = 2
        state.afn.AirflowNetworkLinkageData[4].NodeNums[0] = 2
        state.afn.AirflowNetworkLinkageData[3].NodeNums[1] = 5
        state.afn.AirflowNetworkLinkageData[4].NodeNums[1] = 6
        state.afn.AirflowNetworkNodeSimu[0].TZ = 25.0
        state.afn.AirflowNetworkNodeSimu[0].WZ = 0.001
        state.afn.AirflowNetworkNodeSimu[1].TZ = 20.0
        state.afn.AirflowNetworkNodeSimu[1].WZ = 0.002
        state.afn.AirflowNetworkNodeSimu[2].TZ = 30.0
        state.afn.AirflowNetworkNodeSimu[2].WZ = 0.001
        state.afn.AirflowNetworkNodeSimu[3].TZ = 22.0
        state.afn.AirflowNetworkNodeSimu[3].WZ = 0.001
        state.afn.AirflowNetworkNodeSimu[4].TZ = 27.0
        state.afn.AirflowNetworkNodeSimu[4].WZ = 0.0015
        state.afn.AirflowNetworkNodeSimu[5].TZ = 20.0
        state.afn.AirflowNetworkNodeSimu[5].WZ = 0.002
        state.afn.AirflowNetworkLinkSimu[0].FLOW = 0.0
        state.afn.AirflowNetworkLinkSimu[0].FLOW2 = 0.01
        state.afn.AirflowNetworkLinkSimu[1].FLOW = 0.0
        state.afn.AirflowNetworkLinkSimu[1].FLOW2 = 0.02
        state.afn.AirflowNetworkLinkSimu[2].FLOW = 0.01
        state.afn.AirflowNetworkLinkSimu[2].FLOW2 = 0.0
        state.afn.AirflowNetworkLinkSimu[3].FLOW = 0.0
        state.afn.AirflowNetworkLinkSimu[3].FLOW2 = 0.01
        state.afn.AirflowNetworkLinkSimu[4].FLOW = 0.01
        state.afn.AirflowNetworkLinkSimu[4].FLOW2 = 0.0
        state.dataZoneEquip.ZoneEquipList[ZoneNum - 1].NumOfEquipTypes = 1
        state.dataZoneEquip.ZoneEquipList[ZoneNum - 1].EquipName.allocate(1)
        state.dataZoneEquip.ZoneEquipList[ZoneNum - 1].EquipName[0] = "ZoneHVAC"
        state.dataZoneEquip.ZoneEquipList[ZoneNum - 1].EquipType.allocate(1)
        state.dataZoneEquip.ZoneEquipList[ZoneNum - 1].EquipType[0] = DataZoneEquipment.ZoneEquipType.PackagedTerminalHeatPump
        state.dataZoneEquip.ZoneEquipConfig[ZoneNum - 1].NumInletNodes = 1
        state.dataZoneEquip.ZoneEquipConfig[ZoneNum - 1].InletNode.allocate(1)
        state.dataZoneEquip.ZoneEquipConfig[ZoneNum - 1].InletNode[0] = 1
        state.dataLoopNodes.NodeID.allocate(state.dataLoopNodes.NumOfNodes)
        state.dataLoopNodes.Node.allocate(state.dataLoopNodes.NumOfNodes)
        state.dataZoneEquip.ZoneEquipConfig[ZoneNum - 1].NumReturnNodes = 1
        state.dataZoneEquip.ZoneEquipConfig[ZoneNum - 1].ReturnNode.allocate(1)
        state.dataZoneEquip.ZoneEquipConfig[ZoneNum - 1].ReturnNode[0] = 2
        state.dataZoneEquip.ZoneEquipConfig[0].FixedReturnFlow.allocate(1)
        state.dataHeatBal.Zone[ZoneNum - 1].Volume = 100
        state.dataHeatBal.Zone[ZoneNum - 1].IsControlled = True
        state.dataHeatBal.space.allocate(ZoneNum)
        state.dataHeatBal.space[ZoneNum - 1].HTSurfaceFirst = 1
        state.dataHeatBal.space[ZoneNum - 1].HTSurfaceLast = 2
        state.dataHeatBal.Zone[ZoneNum - 1].ZoneVolCapMultpMoist = 0
        state.dataHeatBal.Zone[ZoneNum - 1].spaceIndexes.emplace_back(1)
        state.dataHeatBal.spaceIntGainDevices[ZoneNum - 1].numberOfDevices = 1
        state.dataHeatBal.spaceIntGainDevices[ZoneNum - 1].device.allocate(state.dataHeatBal.spaceIntGainDevices[0].numberOfDevices)
        state.dataHeatBal.spaceIntGainDevices[ZoneNum - 1].device[0].CompObjectName = "PEOPLE"
        state.dataHeatBal.spaceIntGainDevices[ZoneNum - 1].device[0].CompType = DataHeatBalance.IntGainType.People
        state.dataHeatBal.spaceIntGainDevices[ZoneNum - 1].device[0].ConvectGainRate = 300.0
        state.dataHeatBal.spaceIntGainDevices[ZoneNum - 1].device[0].LatentGainRate = 200.0
        state.dataSurface.Surface[0].HeatTransSurf = True
        state.dataSurface.Surface[1].HeatTransSurf = True
        state.dataSurface.Surface[0].Area = 1.0
        state.dataSurface.Surface[1].Area = 2.0
        state.dataSurface.Surface[0].HeatTransferAlgorithm = HeatTransferModel.EMPD
        state.dataSurface.Surface[1].HeatTransferAlgorithm = HeatTransferModel.EMPD
        state.dataSurface.SurfTAirRef = 0
        state.dataMstBalEMPD.RVSurface[0] = 0.0011
        state.dataMstBalEMPD.RVSurface[1] = 0.0012
        state.dataLoopNodes.NodeID[0] = "Supply"
        state.dataLoopNodes.NodeID[1] = "Return"
        state.dataLoopNodes.Node[0].Temp = 20.0
        state.dataLoopNodes.Node[0].HumRat = 0.001
        state.dataLoopNodes.Node[0].MassFlowRate = 0.01
        var thisZoneHB = state.dataZoneTempPredictorCorrector.zoneHeatBalance[ZoneNum - 1]
        thisZoneHB.MAT = 20.0
        thisZoneHB.airHumRat = 0.001
        state.dataHeatBalSurf.SurfHConvInt[0] = 1.0
        state.dataHeatBalSurf.SurfHConvInt[1] = 1.0
        state.dataHeatBalSurf.SurfTempInTmp[0] = 25.0
        state.dataHeatBalSurf.SurfTempInTmp[1] = 30.0
        state.dataMstBal.RhoVaporAirIn[0] = PsyRhovFnTdbWPb(thisZoneHB.MAT, thisZoneHB.airHumRat, state.dataEnvrn.OutBaroPress)
        state.dataMstBal.RhoVaporAirIn[1] = PsyRhovFnTdbWPb(thisZoneHB.MAT, thisZoneHB.airHumRat, state.dataEnvrn.OutBaroPress)
        state.dataMstBal.HMassConvInFD[0] = (
            state.dataHeatBalSurf.SurfHConvInt[0] /
            ((PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress, thisZoneHB.MAT, thisZoneHB.airHumRat) + state.dataMstBal.RhoVaporAirIn[0]) *
             PsyCpAirFnW(thisZoneHB.airHumRat))
        )
        state.dataMstBal.HMassConvInFD[1] = (
            state.dataHeatBalSurf.SurfHConvInt[1] /
            ((PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress, thisZoneHB.MAT, thisZoneHB.airHumRat) + state.dataMstBal.RhoVaporAirIn[1]) *
             PsyCpAirFnW(thisZoneHB.airHumRat))
        )
        RoomAirNode = 1
        InitRoomAirModelAFN(state, ZoneNum, RoomAirNode)
        expect_near(120.0, state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[RoomAirNode - 1].SumIntSensibleGain, 0.00001)
        expect_near(80.0, state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[RoomAirNode - 1].SumIntLatentGain, 0.00001)
        expect_near(1.0, state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[RoomAirNode - 1].SumHA, 0.00001)
        expect_near(25.0, state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[RoomAirNode - 1].SumHATsurf, 0.00001)
        expect_near(0.0, state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[RoomAirNode - 1].SumHATref, 0.00001)
        expect_near(4.0268, state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[RoomAirNode - 1].SumSysMCp, 0.0001)
        expect_near(80.536, state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[RoomAirNode - 1].SumSysMCpT, 0.001)
        expect_near(0.004, state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[RoomAirNode - 1].SumSysM, 0.00001)
        expect_near(4.0e-6, state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[RoomAirNode - 1].SumSysMW, 0.00001)
        expect_near(30.200968, state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[RoomAirNode - 1].SumLinkMCp, 0.0001)
        expect_near(744.95722, state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[RoomAirNode - 1].SumLinkMCpT, 0.001)
        expect_near(0.03, state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[RoomAirNode - 1].SumLinkM, 0.00001)
        expect_near(3.0e-5, state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[RoomAirNode - 1].SumLinkMW, 0.00001)
        expect_near(-8.431365e-8, state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[RoomAirNode - 1].SumHmAW, 0.0000001)
        expect_near(0.0009756833, state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[RoomAirNode - 1].SumHmARa, 0.0000001)
        expect_near(9.0784549e-7, state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[RoomAirNode - 1].SumHmARaW, 0.0000001)
        CalcRoomAirModelAFN(state, ZoneNum, RoomAirNode)
        expect_near(24.907085, state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[RoomAirNode - 1].AirTemp, 0.00001)
        expect_near(0.00189601, state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[RoomAirNode - 1].HumRat, 0.00001)
        expect_near(9.770445, state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[RoomAirNode - 1].RelHumidity, 0.00001)
        RoomAirNode = 2
        InitRoomAirModelAFN(state, ZoneNum, RoomAirNode)
        expect_near(180.0, state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[RoomAirNode - 1].SumIntSensibleGain, 0.00001)
        expect_near(120.0, state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[RoomAirNode - 1].SumIntLatentGain, 0.00001)
        expect_near(2.0, state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[RoomAirNode - 1].SumHA, 0.00001)
        expect_near(60.0, state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[RoomAirNode - 1].SumHATsurf, 0.00001)
        expect_near(0.0, state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[RoomAirNode - 1].SumHATref, 0.00001)
        expect_near(6.04019, state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[RoomAirNode - 1].SumSysMCp, 0.0001)
        expect_near(120.803874, state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[RoomAirNode - 1].SumSysMCpT, 0.00001)
        expect_near(0.006, state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[RoomAirNode - 1].SumSysM, 0.00001)
        expect_near(6.0e-6, state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[RoomAirNode - 1].SumSysMW, 0.00001)
        expect_near(20.14327, state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[RoomAirNode - 1].SumLinkMCp, 0.0001)
        expect_near(523.73441, state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[RoomAirNode - 1].SumLinkMCpT, 0.001)
        expect_near(0.02, state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[RoomAirNode - 1].SumLinkM, 0.00001)
        expect_near(2.5e-5, state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[RoomAirNode - 1].SumLinkMW, 0.00001)
        expect_near(-3.5644894e-9, state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[RoomAirNode - 1].SumHmAW, 0.0000001)
        expect_near(0.0019191284, state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[RoomAirNode - 1].SumHmARa, 0.0000001)
        expect_near(1.98975381e-6, state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[RoomAirNode - 1].SumHmARaW, 0.0000001)
        CalcRoomAirModelAFN(state, ZoneNum, RoomAirNode)
        expect_near(24.057841, state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[RoomAirNode - 1].AirTemp, 0.00001)
        expect_near(0.0028697086, state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[RoomAirNode - 1].HumRat, 0.00001)
        expect_near(15.53486185, state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[RoomAirNode - 1].RelHumidity, 0.00001)
        UpdateRoomAirModelAFN(state, ZoneNum)
        expect_near(24.397538, state.dataLoopNodes.Node[1].Temp, 0.00001)
        expect_near(0.0024802305, state.dataLoopNodes.Node[1].HumRat, 0.000001)
        var idf_objects = delimited_string({
            "Zone,NORTH_ZONE;",
            "ZoneHVAC:AirDistributionUnit,",
            "     NORTH_ZONE PTAC ADU,        !-Name ",
            "     NORTH_ZONE PTAC Supply Inlet,  !- Air Distribution Unit Outlet Node Name",
            "     AirTerminal:SingleDuct:ConstantVolume:NoReheat,  !- Air Terminal Object Type",
            "    NORTH_ZONE PTAC,         !- Air Terminal Name",
            "    ,                        !- Nominal Upstream Leakage Fraction",
            "    ,                        !- Constant Downstream Leakage Fraction",
            "    ;                        !- Design Specification Air Terminal Sizing Object Name",
        })
        expect_true(process_idf(idf_objects))
        state.afn.get_input()
        state.dataZoneEquip.ZoneEquipList[ZoneNum - 1].EquipType[0] = DataZoneEquipment.ZoneEquipType.AirDistributionUnit
        state.dataRoomAirflowNetModel.OneTimeFlagConf = True
        state.dataZoneAirLoopEquipmentManager.GetAirDistUnitsFlag = False
        state.dataDefineEquipment.AirDistUnit.allocate(1)
        state.dataZoneEquip.ZoneEquipList[ZoneNum - 1].EquipName[0] = "ADU"
        state.dataDefineEquipment.AirDistUnit[0].Name = "ADU"
        state.dataDefineEquipment.AirDistUnit[0].EquipName.allocate(1)
        state.dataDefineEquipment.AirDistUnit[0].EquipName[0] = "AirTerminal"
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[0].HVAC[0].Name = "AirTerminal"
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[0].HVAC[0].SupplyFraction = 0.4
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[0].HVAC[0].ReturnFraction = 0.4
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[1].HVAC[0].Name = "AirTerminal"
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[1].HVAC[0].SupplyFraction = 0.6
        state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[1].HVAC[0].ReturnFraction = 0.6
        InitRoomAirModelAFN(state, ZoneNum, RoomAirNode)
        expect_near(1.1824296, state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[RoomAirNode - 1].RhoAir, 0.00001)
        expect_near(1010.1746, state.dataRoomAir.AFNZoneInfo[ZoneNum - 1].Node[RoomAirNode - 1].CpAir, 0.001)
        state.dataRoomAirflowNetModel.OneTimeFlagConf = False

    # TEST_F(EnergyPlusFixture, RoomAirInternalGains_InternalHeatGains_Check)
    @test
    def RoomAirInternalGains_InternalHeatGains_Check(self) raises:
        var ErrorsFound = False
        var idf_objects = delimited_string({
            "Zone,living_unit1;",
            "BuildingSurface:Detailed,",
            "    unit1,           !- Name",
            "    Wall,                    !- Surface Type",
            "    PARTITION,               !- Construction Name",
            "    living_unit1,               !- Zone Name",
            "    ,                        !- Space Name",
            "    Outdoors,                !- Outside Boundary Condition",
            "    ,                        !- Outside Boundary Condition Object",
            "    SunExposed,              !- Sun Exposure",
            "    WindExposed,             !- Wind Exposure",
            "    0.5000000,               !- View Factor to Ground",
            "    4,                       !- Number of Vertices",
            "    0,0,3.048000,  !- X,Y,Z ==> Vertex 1 {m}",
            "    0,0,0,  !- X,Y,Z ==> Vertex 2 {m}",
            "    6.096000,0,0,  !- X,Y,Z ==> Vertex 3 {m}",
            "    6.096000,0,3.048000;  !- X,Y,Z ==> Vertex 4 {m}",
            "Construction,",
            "    PARTITION,             !- Name",
            "    GYP BOARD;  !- Outside Layer",
            "Material,",
            "    GYP BOARD,  !- Name",
            "    Smooth,                  !- Roughness",
            "    1.9050000E-02,           !- Thickness {m}",
            "    0.7264224,               !- Conductivity {W/m-K}",
            "    1601.846,                !- Density {kg/m3}",
            "    836.8000,                !- Specific Heat {J/kg-K}",
            "    0.9000000,               !- Thermal Absorptance",
            "    0.9200000,               !- Solar Absorptance",
            "    0.9200000;               !- Visible Absorptance",
            "Schedule:Constant,sch_act,,120.0;",
            "Schedule:Constant,sch,,1.0;",
            "People,",
            "  people_unit1,            !- Name",
            "  living_unit1,            !- Zone or ZoneList Name",
            "  sch,           !- Number of People Schedule Name",
            "  People,                  !- Number of People Calculation Method",
            "  3,                       !- Number of People",
            "  ,                        !- People per Zone Floor Area {person / m2}",
            "  ,                        !- Zone Floor Area per Person {m2 / person}",
            "  0,                       !- Fraction Radiant",
            " autocalculate,           !- Sensible Heat Fraction",
            " sch_act,            !- Activity Level Schedule Name",
            " ;                        !- Carbon Dioxide Generation Rate {m3 / s - W}",
            "Lights,",
            "  Living Hardwired Lighting1,  !- Name",
            "  living_unit1,            !- Zone or ZoneList Name",
            "  sch,  !- Schedule Name",
            "  LightingLevel,           !- Design Level Calculation Method",
            "  1000,                    !- Lighting Level {W}",
            "  ,                        !- Watts per Zone Floor Area {W / m2}",
            "  ,                        !- Watts per Person {W / person}",
            "  0,                       !- Return Air Fraction",
            "  0.6,                     !- Fraction Radiant",
            "  0.2,                     !- Fraction Visible",
            "  0;                       !- Fraction Replaceable",
            " ElectricEquipment,",
            "  Electric Equipment 1,  !- Name",
            "  living_unit1,               !- Zone or ZoneList Name",
            "  sch,               !- Schedule Name",
            "  EquipmentLevel,          !- Design Level Calculation Method",
            "  150.0,                   !- Design Level {W}",
            "  ,                        !- Watts per Zone Floor Area {W/m2}",
            "  ,                        !- Watts per Person {W/person}",
            "  0.0000,                  !- Fraction Latent",
            "  0.5000,                  !- Fraction Radiant",
            "  0.0000;                  !- Fraction Lost",
            "RoomAirModelType,",
            " RoomAirWithAirflowNetwork,  !- Name",
            " living_unit1,            !- Zone Name",
            " AirflowNetwork,          !- Room - Air Modeling Type",
            " DIRECT;                  !- Air Temperature Coupling Strategy",
            "RoomAir:Node:AirflowNetwork,",
            " Node1,                   !- Name",
            " living_unit1,            !- Zone Name",
            " 1,                    !- Fraction of Zone Air Volume",
            " unit1_List,   !- RoomAir : Node : AirflowNetwork : AdjacentSurfaceList Name",
            " Node1_Gain,              !- RoomAir : Node : AirflowNetwork : InternalGains Name",
            " Node1_HVAC;              !- RoomAir:Node:AirflowNetwork:HVACEquipment Name",
            "RoomAir:Node:AirflowNetwork:AdjacentSurfaceList,",
            " unit1_List,   !- Name",
            " unit1;        !- Surface 1 Name",
            "RoomAir:Node:AirflowNetwork:InternalGains,",
            " Node1_Gain,              !- Name",
            " People,                  !- Internal Gain Object 1 Type",
            " living_unit1 People,     !- Internal Gain Object 1 Name",
            " 1,                    !- Fraction of Gains to Node 1",
            " Lights,                  !- Internal Gain Object 2 Type",
            " living_unit1 Lights,     !- Internal Gain Object 2 Name",
            " 1,                    !- Fraction of Gains to Node 2",
            " ElectricEquipment,       !- Internal Gain Object 3 Type",
            " living_unit1 Equip,      !- Internal Gain Object 3 Name",
            " 1;                    !- Fraction of Gains to Node 3",
            "RoomAirSettings:AirflowNetwork,",
            "  living_unit1,            !- Name",
            "  living_unit1,            !- Zone Name",
            "  Node1,            !- Control Point AFN : Node Name",
            "  Node1;                   !- RoomAirflowNetwork : Node Name 1",
        })
        expect_true(process_idf(idf_objects))
        expect_false(has_err_output())
        state.dataGlobal.TimeStepsInHour = 1
        state.dataGlobal.MinutesInTimeStep = 60
        state.init_state(state)
        ErrorsFound = False
        HeatBalanceManager.GetZoneData(state, ErrorsFound)
        expect_false(ErrorsFound)
        ZoneEquipmentManager.GetZoneEquipment(state)
        ErrorsFound = False
        Material.GetMaterialData(state, ErrorsFound)
        expect_false(ErrorsFound)
        ErrorsFound = False
        HeatBalanceManager.GetConstructData(state, ErrorsFound)
        expect_false(ErrorsFound)
        ErrorsFound = False
        state.dataSurfaceGeometry.CosZoneRelNorth.allocate(1)
        state.dataSurfaceGeometry.SinZoneRelNorth.allocate(1)
        state.dataSurfaceGeometry.CosZoneRelNorth[0] = cos(-state.dataHeatBal.Zone[0].RelNorth * Constant.DegToRad)
        state.dataSurfaceGeometry.SinZoneRelNorth[0] = sin(-state.dataHeatBal.Zone[0].RelNorth * Constant.DegToRad)
        state.dataSurfaceGeometry.CosBldgRelNorth = 1.0
        state.dataSurfaceGeometry.SinBldgRelNorth = 0.0
        SurfaceGeometry.GetSurfaceData(state, ErrorsFound)
        expect_false(ErrorsFound)
        HeatBalanceManager.AllocateHeatBalArrays(state)
        InternalHeatGains.GetInternalHeatGainsInput(state)
        ErrorsFound = False
        state.dataRoomAir.AirModel.allocate(1)
        state.dataRoomAir.AirModel[0].AirModel = RoomAir.RoomAirModel.AirflowNetwork
        RoomAir.GetRoomAirflowNetworkData(state, ErrorsFound)
        expect_true(ErrorsFound)
        var error_string = delimited_string({
            "   ** Warning ** ProcessScheduleInput: Schedule:Constant = SCH_ACT",
            "   **   ~~~   ** Schedule Type Limits Name is empty.",
            "   **   ~~~   ** Schedule will not be validated.",
            "   ** Warning ** ProcessScheduleInput: Schedule:Constant = SCH",
            "   **   ~~~   ** Schedule Type Limits Name is empty.",
            "   **   ~~~   ** Schedule will not be validated.",
            "   ** Severe  ** GetRoomAirflowNetworkData: Invalid Internal Gain Object Name = LIVING_UNIT1 PEOPLE",
            "   **   ~~~   ** Entered in RoomAir:Node:AirflowNetwork:InternalGains = NODE1_GAIN",
            "   **   ~~~   ** Internal gain did not match correctly",
            "   ** Severe  ** GetRoomAirflowNetworkData: Invalid Internal Gain Object Name = LIVING_UNIT1 LIGHTS",
            "   **   ~~~   ** Entered in RoomAir:Node:AirflowNetwork:InternalGains = NODE1_GAIN",
            "   **   ~~~   ** Internal gain did not match correctly",
            "   ** Severe  ** GetRoomAirflowNetworkData: Invalid Internal Gain Object Name = LIVING_UNIT1 EQUIP",
            "   **   ~~~   ** Entered in RoomAir:Node:AirflowNetwork:InternalGains = NODE1_GAIN",
            "   **   ~~~   ** Internal gain did not match correctly"
        })
        expect_true(compare_err_stream(error_string, True))

    # TEST_F(EnergyPlusFixture, RoomAirflowNetwork_CheckEquipName_Test)
    @test
    def RoomAirflowNetwork_CheckEquipName_Test(self) raises:
        var check = False
        var EquipName = "ZoneEquip"
        var SupplyNodeName = ""
        var ReturnNodeName = ""
        var EquipIndex = 1
        var zoneEquipType: DataZoneEquipment.ZoneEquipType
        state.dataLoopNodes.NodeID.allocate(2)
        state.dataLoopNodes.Node.allocate(2)
        state.dataLoopNodes.NodeID[0] = "SupplyNode"
        state.dataLoopNodes.NodeID[1] = "ReturnNode"
        state.dataHVACVarRefFlow.GetVRFInputFlag = False
        state.dataHVACVarRefFlow.VRFTU.allocate(1)
        state.dataHVACVarRefFlow.VRFTU[0].VRFTUOutletNodeNum = 1
        zoneEquipType = DataZoneEquipment.ZoneEquipType.VariableRefrigerantFlowTerminal
        state.dataHVACVarRefFlow.NumVRFTU = 1
        state.dataHVACVarRefFlow.VRFTU[0].Name = EquipName
        check = CheckEquipName(state, EquipName, SupplyNodeName, ReturnNodeName, zoneEquipType)
        expect_true(check)
        expect_eq("SupplyNode", SupplyNodeName)
        state.dataLoopNodes.NodeID[0] = "SupplyNode1"
        state.dataLoopNodes.NodeID[1] = "ReturnNode1"
        zoneEquipType = DataZoneEquipment.ZoneEquipType.EnergyRecoveryVentilator
        state.dataHVACStandAloneERV.GetERVInputFlag = False
        state.dataHVACStandAloneERV.StandAloneERV.allocate(1)
        state.dataHVACStandAloneERV.NumStandAloneERVs = 1
        state.dataHVACStandAloneERV.StandAloneERV[0].SupplyAirInletNode = 1
        state.dataHVACStandAloneERV.StandAloneERV[0].Name = EquipName
        check = CheckEquipName(state, EquipName, SupplyNodeName, ReturnNodeName, zoneEquipType)
        expect_true(check)
        expect_eq("SupplyNode1", SupplyNodeName)
        state.dataLoopNodes.NodeID[0] = "SupplyNode2"
        state.dataLoopNodes.NodeID[1] = "ReturnNode2"
        zoneEquipType = DataZoneEquipment.ZoneEquipType.FourPipeFanCoil
        state.dataFanCoilUnits.FanCoil.allocate(1)
        state.dataFanCoilUnits.FanCoil[EquipIndex - 1].AirOutNode = 1
        state.dataFanCoilUnits.FanCoil[EquipIndex - 1].AirInNode = 2
        state.dataFanCoilUnits.NumFanCoils = 1
        state.dataFanCoilUnits.GetFanCoilInputFlag = False
        state.dataFanCoilUnits.FanCoil[EquipIndex - 1].Name = EquipName
        check = CheckEquipName(state, EquipName, SupplyNodeName, ReturnNodeName, zoneEquipType)
        expect_true(check)
        expect_eq("SupplyNode2", SupplyNodeName)
        expect_eq("ReturnNode2", ReturnNodeName)
        state.dataLoopNodes.NodeID[0] = "SupplyNode3"
        state.dataLoopNodes.NodeID[1] = "ReturnNode3"
        zoneEquipType = DataZoneEquipment.ZoneEquipType.OutdoorAirUnit
        state.dataOutdoorAirUnit.OutAirUnit.allocate(1)
        state.dataOutdoorAirUnit.OutAirUnit[EquipIndex - 1].AirOutletNode = 1
        state.dataOutdoorAirUnit.OutAirUnit[EquipIndex - 1].AirInletNode = 2
        state.dataOutdoorAirUnit.NumOfOAUnits = 1
        state.dataOutdoorAirUnit.GetOutdoorAirUnitInputFlag = False
        state.dataOutdoorAirUnit.OutAirUnit[EquipIndex - 1].Name = EquipName
        check = CheckEquipName(state, EquipName, SupplyNodeName, ReturnNodeName, zoneEquipType)
        expect_true(check)
        expect_eq("SupplyNode3", SupplyNodeName)
        expect_eq("ReturnNode3", ReturnNodeName)
        state.dataLoopNodes.NodeID[0] = "SupplyNode4"
        state.dataLoopNodes.NodeID[1] = "ReturnNode4"
        zoneEquipType = DataZoneEquipment.ZoneEquipType.PackagedTerminalAirConditioner
        var thisUnit = UnitarySystems.UnitarySys()
        state.dataUnitarySystems.unitarySys.append(thisUnit)
        state.dataUnitarySystems.getInputOnceFlag = False
        state.dataUnitarySystems.unitarySys[EquipIndex - 1].Name = EquipName
        state.dataUnitarySystems.numUnitarySystems = 1
        state.dataUnitarySystems.unitarySys[EquipIndex - 1].AirOutNode = 1
        state.dataUnitarySystems.unitarySys[EquipIndex - 1].AirInNode = 2
        check = CheckEquipName(state, EquipName, SupplyNodeName, ReturnNodeName, zoneEquipType)
        expect_true(check)
        expect_eq("SupplyNode4", SupplyNodeName)
        expect_eq("ReturnNode4", ReturnNodeName)
        state.dataLoopNodes.NodeID[0] = "SupplyNode5"
        state.dataLoopNodes.NodeID[1] = "ReturnNode5"
        zoneEquipType = DataZoneEquipment.ZoneEquipType.PackagedTerminalHeatPump
        state.dataUnitarySystems.getInputOnceFlag = False
        state.dataUnitarySystems.unitarySys[EquipIndex - 1].Name = EquipName
        state.dataUnitarySystems.numUnitarySystems = 1
        state.dataUnitarySystems.unitarySys[EquipIndex - 1].AirOutNode = 1
        state.dataUnitarySystems.unitarySys[EquipIndex - 1].AirInNode = 2
        check = CheckEquipName(state, EquipName, SupplyNodeName, ReturnNodeName, zoneEquipType)
        expect_true(check)
        expect_eq("SupplyNode5", SupplyNodeName)
        expect_eq("ReturnNode5", ReturnNodeName)
        state.dataLoopNodes.NodeID[0] = "SupplyNode6"
        state.dataLoopNodes.NodeID[1] = "ReturnNode6"
        zoneEquipType = DataZoneEquipment.ZoneEquipType.PackagedTerminalHeatPumpWaterToAir
        state.dataUnitarySystems.getInputOnceFlag = False
        state.dataUnitarySystems.unitarySys[EquipIndex - 1].Name = EquipName
        state.dataUnitarySystems.numUnitarySystems = 1
        state.dataUnitarySystems.unitarySys[EquipIndex - 1].AirOutNode = 1
        state.dataUnitarySystems.unitarySys[EquipIndex - 1].AirInNode = 2
        check = CheckEquipName(state, EquipName, SupplyNodeName, ReturnNodeName, zoneEquipType)
        expect_true(check)
        expect_eq("SupplyNode6", SupplyNodeName)
        expect_eq("ReturnNode6", ReturnNodeName)
        state.dataLoopNodes.NodeID[0] = "SupplyNode7"
        state.dataLoopNodes.NodeID[1] = "ReturnNode7"
        zoneEquipType = DataZoneEquipment.ZoneEquipType.UnitHeater
        state.dataUnitHeaters.UnitHeat.allocate(1)
        state.dataUnitHeaters.UnitHeat[EquipIndex - 1].AirOutNode = 1
        state.dataUnitHeaters.UnitHeat[EquipIndex - 1].AirInNode = 2
        state.dataUnitHeaters.NumOfUnitHeats = 1
        state.dataUnitHeaters.GetUnitHeaterInputFlag = False
        state.dataUnitHeaters.UnitHeat[EquipIndex - 1].Name = EquipName
        check = CheckEquipName(state, EquipName, SupplyNodeName, ReturnNodeName, zoneEquipType)
        expect_true(check)
        expect_eq("SupplyNode7", SupplyNodeName)
        expect_eq("ReturnNode7", ReturnNodeName)
        state.dataLoopNodes.NodeID[0] = "SupplyNode8"
        state.dataLoopNodes.NodeID[1] = "ReturnNode8"
        zoneEquipType = DataZoneEquipment.ZoneEquipType.UnitVentilator
        state.dataUnitVentilators.UnitVent.allocate(1)
        state.dataUnitVentilators.UnitVent[EquipIndex - 1].AirOutNode = 1
        state.dataUnitVentilators.UnitVent[EquipIndex - 1].AirInNode = 2
        state.dataUnitVentilators.NumOfUnitVents = 1
        state.dataUnitVentilators.UnitVent[EquipIndex - 1].Name = EquipName
        state.dataUnitVentilators.GetUnitVentilatorInputFlag = False
        check = CheckEquipName(state, EquipName, SupplyNodeName, ReturnNodeName, zoneEquipType)
        expect_true(check)
        expect_eq("SupplyNode8", SupplyNodeName)
        expect_eq("ReturnNode8", ReturnNodeName)
        state.dataLoopNodes.NodeID[0] = "SupplyNode9"
        state.dataLoopNodes.NodeID[1] = "ReturnNode9"
        zoneEquipType = DataZoneEquipment.ZoneEquipType.VentilatedSlab
        state.dataVentilatedSlab.VentSlab.allocate(1)
        state.dataVentilatedSlab.VentSlab[EquipIndex - 1].ZoneAirInNode = 1
        state.dataVentilatedSlab.VentSlab[EquipIndex - 1].ReturnAirNode = 2
        state.dataVentilatedSlab.NumOfVentSlabs = 1
        state.dataVentilatedSlab.GetInputFlag = False
        state.dataVentilatedSlab.VentSlab[EquipIndex - 1].Name = EquipName
        check = CheckEquipName(state, EquipName, SupplyNodeName, ReturnNodeName, zoneEquipType)
        expect_true(check)
        expect_eq("SupplyNode9", SupplyNodeName)
        expect_eq("ReturnNode9", ReturnNodeName)
        state.dataLoopNodes.NodeID[0] = "SupplyNode10"
        state.dataLoopNodes.NodeID[1] = "ReturnNode10"
        zoneEquipType = DataZoneEquipment.ZoneEquipType.WindowAirConditioner
        state.dataWindowAC.WindAC.allocate(1)
        state.dataWindowAC.WindAC[EquipIndex - 1].AirOutNode = 1
        state.dataWindowAC.WindAC[EquipIndex - 1].AirInNode = 2
        state.dataWindowAC.WindAC[EquipIndex - 1].OAMixIndex = 1
        state.dataWindowAC.NumWindAC = 1
        state.dataWindowAC.GetWindowACInputFlag = False
        state.dataMixedAir.NumOAMixers = 1
        state.dataMixedAir.OAMixer.allocate(1)
        state.dataMixedAir.OAMixer[0].RetNode = 2
        state.dataWindowAC.WindAC[EquipIndex - 1].Name = EquipName
        state.dataMixedAir.GetOAMixerInputFlag = False
        check = CheckEquipName(state, EquipName, SupplyNodeName, ReturnNodeName, zoneEquipType)
        expect_true(check)
        expect_eq("SupplyNode10", SupplyNodeName)
        expect_eq("ReturnNode10", ReturnNodeName)
        state.dataLoopNodes.NodeID[0] = "SupplyNode11"
        state.dataLoopNodes.NodeID[1] = "ReturnNode11"
        zoneEquipType = DataZoneEquipment.ZoneEquipType.DehumidifierDX
        state.dataZoneDehumidifier.ZoneDehumid.allocate(1)
        state.dataZoneDehumidifier.ZoneDehumid[EquipIndex - 1].AirOutletNodeNum = 1
        state.dataZoneDehumidifier.ZoneDehumid[EquipIndex - 1].AirInletNodeNum = 2
        state.dataZoneDehumidifier.ZoneDehumid[EquipIndex - 1].Name = EquipName
        state.dataZoneDehumidifier.GetInputFlag = False
        check = CheckEquipName(state, EquipName, SupplyNodeName, ReturnNodeName, zoneEquipType)
        expect_true(check)
        expect_eq("SupplyNode11", SupplyNodeName)
        expect_eq("ReturnNode11", ReturnNodeName)
        state.dataLoopNodes.NodeID[0] = "SupplyNode12"
        state.dataLoopNodes.NodeID[1] = "ReturnNode12"
        zoneEquipType = DataZoneEquipment.ZoneEquipType.PurchasedAir
        state.dataPurchasedAirMgr.PurchAir.allocate(1)
        state.dataPurchasedAirMgr.PurchAir[EquipIndex - 1].ZoneSupplyAirNodeNum = 1
        state.dataPurchasedAirMgr.PurchAir[EquipIndex - 1].ZoneExhaustAirNodeNum = 2
        state.dataPurchasedAirMgr.NumPurchAir = 1
        state.dataPurchasedAirMgr.PurchAir[EquipIndex - 1].Name = EquipName
        state.dataPurchasedAirMgr.GetPurchAirInputFlag = False
        check = CheckEquipName(state, EquipName, SupplyNodeName, ReturnNodeName, zoneEquipType)
        expect_true(check)
        expect_eq("SupplyNode12", SupplyNodeName)
        expect_eq("ReturnNode12", ReturnNodeName)
        state.dataLoopNodes.NodeID[0] = "SupplyNode13"
        state.dataLoopNodes.NodeID[1] = "ReturnNode13"
        zoneEquipType = DataZoneEquipment.ZoneEquipType.PurchasedAir
        state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner.allocate(1)
        state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[EquipIndex - 1].OutletNode = 1
        state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[EquipIndex - 1].InletNode = 2
        state.dataHybridUnitaryAC.NumZoneHybridEvap = 1
        state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[EquipIndex - 1].Name = EquipName
        state.dataHybridUnitaryAC.GetInputZoneHybridEvap = False
        check = CheckEquipName(state, EquipName, SupplyNodeName, ReturnNodeName, zoneEquipType)
        expect_true(check)
        expect_eq("SupplyNode13", SupplyNodeName)
        expect_eq("ReturnNode13", ReturnNodeName)
        state.dataLoopNodes.NodeID[0] = "SupplyNode14"
        state.dataLoopNodes.NodeID[1] = "ReturnNode14"
        zoneEquipType = DataZoneEquipment.ZoneEquipType.PurchasedAir
        state.dataWaterThermalTanks.HPWaterHeater.allocate(1)
        state.dataWaterThermalTanks.HPWaterHeater[EquipIndex - 1].HeatPumpAirOutletNode = 1
        state.dataWaterThermalTanks.HPWaterHeater[EquipIndex - 1].HeatPumpAirInletNode = 2
        state.dataWaterThermalTanks.numHeatPumpWaterHeater = 1
        state.dataWaterThermalTanks.HPWaterHeater[EquipIndex - 1].Name = EquipName
        state.dataWaterThermalTanks.getWaterThermalTankInputFlag = False
        check = CheckEquipName(state, EquipName, SupplyNodeName, ReturnNodeName, zoneEquipType)
        expect_true(check)
        expect_eq("SupplyNode14", SupplyNodeName)
        expect_eq("ReturnNode14", ReturnNodeName)
<<<FILE>>>