from .Fixtures.EnergyPlusFixture import EnergyPlusFixture
from AirflowNetwork.Solver import *
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataEnvironment import *
from EnergyPlus.DataHVACGlobals import *
from EnergyPlus.DataHeatBalFanSys import *
from EnergyPlus.DataHeatBalSurface import *
from EnergyPlus.DataHeatBalance import *
from EnergyPlus.DataLoopNode import *
from EnergyPlus.DataSizing import *
from EnergyPlus.DataZoneControls import *
from EnergyPlus.DataZoneEnergyDemands import *
from EnergyPlus.DataZoneEquipment import *
from EnergyPlus.HeatBalanceManager import *
from EnergyPlus.HybridModel import *
from EnergyPlus.ScheduleManager import Sched
from EnergyPlus.SimulationManager import *
from EnergyPlus.WeatherManager import *
from EnergyPlus.ZoneContaminantPredictorCorrector import PredictZoneContaminants, CorrectZoneContaminants
from EnergyPlus.ZonePlenum import *
from EnergyPlus.ZoneTempPredictorCorrector import *
from EnergyPlus.DataSurfaces import *
from EnergyPlus.DataEnvironment import *
from EnergyPlus.Psychrometrics import *
from SimulationManager import *
from EnergyPlus.ZoneContaminantPredictorCorrector import *

from gtest import *

struct TestZoneContaminantPredictorCorrector(EnergyPlusFixture):

def test_ZoneContaminantPredictorCorrector_AddMDotOATest(reg: TestZoneContaminantPredictorCorrector):
    state.init_state(state)
    state.dataHVACGlobal.ShortenTimeStepSys = False
    state.dataHVACGlobal.UseZoneTimeStepHistory = False
    state.dataZoneTempPredictorCorrector.zoneHeatBalance.allocate(1)
    state.dataGlobal.NumOfZones = 1
    state.dataContaminantBalance.Contaminant.CO2Simulation = True
    state.dataContaminantBalance.Contaminant.GenericContamSimulation = True
    state.dataContaminantBalance.AZ.allocate(1)
    state.dataContaminantBalance.BZ.allocate(1)
    state.dataContaminantBalance.CZ.allocate(1)
    state.dataContaminantBalance.AZGC.allocate(1)
    state.dataContaminantBalance.BZGC.allocate(1)
    state.dataContaminantBalance.CZGC.allocate(1)
    state.dataContaminantBalance.CO2ZoneTimeMinus1Temp.allocate(1)
    state.dataContaminantBalance.CO2ZoneTimeMinus2Temp.allocate(1)
    state.dataContaminantBalance.CO2ZoneTimeMinus3Temp.allocate(1)
    state.dataContaminantBalance.DSCO2ZoneTimeMinus1.allocate(1)
    state.dataContaminantBalance.DSCO2ZoneTimeMinus2.allocate(1)
    state.dataContaminantBalance.DSCO2ZoneTimeMinus3.allocate(1)
    state.dataContaminantBalance.GCZoneTimeMinus1Temp.allocate(1)
    state.dataContaminantBalance.GCZoneTimeMinus2Temp.allocate(1)
    state.dataContaminantBalance.GCZoneTimeMinus3Temp.allocate(1)
    state.dataContaminantBalance.DSGCZoneTimeMinus1.allocate(1)
    state.dataContaminantBalance.DSGCZoneTimeMinus2.allocate(1)
    state.dataContaminantBalance.DSGCZoneTimeMinus3.allocate(1)
    state.dataContaminantBalance.MixingMassFlowCO2.allocate(1)
    state.dataContaminantBalance.MixingMassFlowGC.allocate(1)
    state.dataContaminantBalance.ZoneAirCO2Temp.allocate(1)
    state.dataContaminantBalance.ZoneCO21.allocate(1)
    state.dataContaminantBalance.ZoneAirCO2.allocate(1)
    state.dataContaminantBalance.ZoneAirGCTemp.allocate(1)
    state.dataContaminantBalance.ZoneGC1.allocate(1)
    state.dataContaminantBalance.ZoneAirGC.allocate(1)
    state.dataContaminantBalance.ZoneCO2SetPoint.allocate(1)
    state.dataContaminantBalance.CO2PredictedRate.allocate(1)
    state.dataContaminantBalance.GCPredictedRate.allocate(1)
    state.dataContaminantBalance.ContaminantControlledZone.allocate(1)
    state.dataContaminantBalance.ZoneGCSetPoint.allocate(1)
    state.dataContaminantBalance.ZoneAirDensityCO.allocate(1)
    state.dataContaminantBalance.ZoneCO2Gain.allocate(1)
    state.dataContaminantBalance.ZoneCO2GainExceptPeople.allocate(1)
    state.dataContaminantBalance.ZoneGCGain.allocate(1)
    state.dataContaminantBalance.ZoneCO2Gain[0] = 0.0001
    state.dataContaminantBalance.ZoneCO2GainExceptPeople = 0.0001
    state.dataContaminantBalance.ZoneGCGain[0] = 0.0000001
    state.dataContaminantBalance.MixingMassFlowCO2[0] = 0.0
    state.dataContaminantBalance.MixingMassFlowGC[0] = 0.0
    state.dataContaminantBalance.DSCO2ZoneTimeMinus1[0] = 200.0
    state.dataContaminantBalance.DSCO2ZoneTimeMinus2[0] = 200.0
    state.dataContaminantBalance.DSCO2ZoneTimeMinus3[0] = 200.0
    state.dataContaminantBalance.OutdoorCO2 = 400.0
    state.dataContaminantBalance.OutdoorGC = 0.001
    state.dataContaminantBalance.ZoneCO21[0] = state.dataContaminantBalance.OutdoorCO2
    state.dataContaminantBalance.ZoneGC1[0] = state.dataContaminantBalance.OutdoorGC
    state.dataContaminantBalance.ZoneCO2SetPoint[0] = 450.0
    state.dataContaminantBalance.ZoneAirCO2[0] = state.dataContaminantBalance.ZoneCO21[0]
    state.dataContaminantBalance.ZoneAirGC[0] = state.dataContaminantBalance.ZoneGC1[0]
    var PriorTimeStep: Float64
    state.dataHVACGlobal.TimeStepSys = 15.0 / 60.0
    state.dataHVACGlobal.TimeStepSysSec = state.dataHVACGlobal.TimeStepSys * Constant.rSecsInHour
    PriorTimeStep = state.dataHVACGlobal.TimeStepSys
    state.dataZoneEquip.ZoneEquipConfig.allocate(1)
    state.dataZoneEquip.ZoneEquipConfig[0].ZoneName = "Zone 1"
    state.dataZoneEquip.ZoneEquipConfig[0].NumInletNodes = 2
    state.dataZoneEquip.ZoneEquipConfig[0].InletNode.allocate(2)
    state.dataZoneEquip.ZoneEquipConfig[0].InletNode[0] = 1
    state.dataZoneEquip.ZoneEquipConfig[0].InletNode[1] = 2
    state.dataZoneEquip.ZoneEquipConfig[0].NumExhaustNodes = 1
    state.dataZoneEquip.ZoneEquipConfig[0].ExhaustNode.allocate(1)
    state.dataZoneEquip.ZoneEquipConfig[0].ExhaustNode[0] = 3
    state.dataZoneEquip.ZoneEquipConfig[0].NumReturnNodes = 1
    state.dataZoneEquip.ZoneEquipConfig[0].ReturnNode.allocate(1)
    state.dataZoneEquip.ZoneEquipConfig[0].ReturnNode[0] = 4
    state.dataZoneEquip.ZoneEquipConfig[0].FixedReturnFlow.allocate(1)
    state.dataLoopNodes.Node.allocate(5)
    state.dataHeatBal.Zone.allocate(1)
    state.dataHeatBal.Zone[0].Name = state.dataZoneEquip.ZoneEquipConfig[0].ZoneName
    state.dataSize.ZoneEqSizing.allocate(1)
    state.dataSize.CurZoneEqNum = 1
    state.dataHeatBal.Zone[0].Multiplier = 1.0
    state.dataHeatBal.Zone[0].Volume = 1000.0
    state.dataHeatBal.Zone[0].SystemZoneNodeNumber = 5
    state.dataHeatBal.Zone[0].ZoneVolCapMultpMoist = 1.0
    state.dataEnvrn.OutBaroPress = 101325.0
    state.dataZonePlenum.NumZoneReturnPlenums = 0
    state.dataZonePlenum.NumZoneSupplyPlenums = 0
    state.dataZoneTempPredictorCorrector.zoneHeatBalance.allocate(1)
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].MDotOA = 0.001
    state.dataHeatBal.ZoneAirSolutionAlgo = DataHeatBalance.SolutionAlgo.EulerMethod
    state.dataLoopNodes.Node[0].MassFlowRate = 0.01
    state.dataLoopNodes.Node[0].HumRat = 0.008
    state.dataLoopNodes.Node[1].MassFlowRate = 0.02
    state.dataLoopNodes.Node[1].HumRat = 0.008
    state.dataZoneEquip.ZoneEquipConfig[0].ZoneExhBalanced = 0.0
    state.dataLoopNodes.Node[2].MassFlowRate = 0.00
    state.dataZoneEquip.ZoneEquipConfig[0].ZoneExh = state.dataLoopNodes.Node[2].MassFlowRate
    state.dataLoopNodes.Node[2].HumRat = 0.008
    state.dataLoopNodes.Node[3].MassFlowRate = 0.03
    state.dataLoopNodes.Node[3].HumRat = 0.000
    state.dataLoopNodes.Node[4].HumRat = 0.000
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].airHumRat = 0.008
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].ZT = 24.0
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].MixingMassFlowZone = 0.0
    state.dataContaminantBalance.CO2PredictedRate.allocate(1)
    state.dataContaminantBalance.ZoneSysContDemand.allocate(1)
    state.dataContaminantBalance.ContaminantControlledZone.allocate(1)
    state.dataContaminantBalance.ContaminantControlledZone[0].availSched = Sched.GetScheduleAlwaysOn(state)
    state.dataContaminantBalance.ContaminantControlledZone[0].genericContamAvailSched = Sched.GetScheduleAlwaysOn(state)
    state.dataContaminantBalance.ContaminantControlledZone[0].ActualZoneNum = 1
    state.dataContaminantBalance.ContaminantControlledZone[0].NumOfZones = 1
    state.dataContaminantBalance.ZoneGCSetPoint[0] = 0.0025
    PredictZoneContaminants(state, state.dataHVACGlobal.ShortenTimeStepSys, state.dataHVACGlobal.UseZoneTimeStepHistory, PriorTimeStep)
    EXPECT_NEAR(1.041692180, state.dataContaminantBalance.CO2PredictedRate[0], 0.00001)
    EXPECT_NEAR(76.89754831, state.dataContaminantBalance.GCPredictedRate[0], 0.00001)
    CorrectZoneContaminants(state, state.dataHVACGlobal.UseZoneTimeStepHistory)
    EXPECT_NEAR(489.931000, state.dataLoopNodes.Node[4].CO2, 0.00001)
    EXPECT_NEAR(0.09093100, state.dataLoopNodes.Node[4].GenContam, 0.00001)

def test_ZoneContaminantPredictorCorrector_CorrectZoneContaminantsTest(reg: TestZoneContaminantPredictorCorrector):
    state.init_state(state)
    state.dataHVACGlobal.ShortenTimeStepSys = False
    state.dataHVACGlobal.UseZoneTimeStepHistory = False
    state.dataZoneTempPredictorCorrector.zoneHeatBalance.allocate(1)
    state.dataGlobal.NumOfZones = 1
    state.dataContaminantBalance.Contaminant.CO2Simulation = True
    state.dataContaminantBalance.Contaminant.GenericContamSimulation = True
    state.dataContaminantBalance.AZ.allocate(1)
    state.dataContaminantBalance.BZ.allocate(1)
    state.dataContaminantBalance.CZ.allocate(1)
    state.dataContaminantBalance.AZGC.allocate(1)
    state.dataContaminantBalance.BZGC.allocate(1)
    state.dataContaminantBalance.CZGC.allocate(1)
    state.dataContaminantBalance.CO2ZoneTimeMinus1Temp.allocate(1)
    state.dataContaminantBalance.CO2ZoneTimeMinus2Temp.allocate(1)
    state.dataContaminantBalance.CO2ZoneTimeMinus3Temp.allocate(1)
    state.dataContaminantBalance.DSCO2ZoneTimeMinus1.allocate(1)
    state.dataContaminantBalance.DSCO2ZoneTimeMinus2.allocate(1)
    state.dataContaminantBalance.DSCO2ZoneTimeMinus3.allocate(1)
    state.dataContaminantBalance.GCZoneTimeMinus1Temp.allocate(1)
    state.dataContaminantBalance.GCZoneTimeMinus2Temp.allocate(1)
    state.dataContaminantBalance.GCZoneTimeMinus3Temp.allocate(1)
    state.dataContaminantBalance.DSGCZoneTimeMinus1.allocate(1)
    state.dataContaminantBalance.DSGCZoneTimeMinus2.allocate(1)
    state.dataContaminantBalance.DSGCZoneTimeMinus3.allocate(1)
    state.dataContaminantBalance.MixingMassFlowCO2.allocate(1)
    state.dataContaminantBalance.MixingMassFlowGC.allocate(1)
    state.dataContaminantBalance.ZoneAirCO2Temp.allocate(1)
    state.dataContaminantBalance.ZoneCO21.allocate(1)
    state.dataContaminantBalance.ZoneAirCO2.allocate(1)
    state.dataContaminantBalance.ZoneAirGCTemp.allocate(1)
    state.dataContaminantBalance.ZoneGC1.allocate(1)
    state.dataContaminantBalance.ZoneAirGC.allocate(1)
    state.dataContaminantBalance.ZoneAirDensityCO.allocate(1)
    state.dataContaminantBalance.ZoneCO2Gain.allocate(1)
    state.dataContaminantBalance.ZoneCO2GainExceptPeople.allocate(1)
    state.dataContaminantBalance.ZoneGCGain.allocate(1)
    state.dataContaminantBalance.ZoneCO2Gain[0] = 0.0001
    state.dataContaminantBalance.ZoneCO2GainExceptPeople[0] = 0.0001
    state.dataContaminantBalance.ZoneGCGain[0] = 0.0001
    state.dataContaminantBalance.MixingMassFlowCO2[0] = 0.0
    state.dataContaminantBalance.MixingMassFlowGC[0] = 0.0
    state.dataContaminantBalance.DSCO2ZoneTimeMinus1[0] = 200.0
    state.dataContaminantBalance.DSCO2ZoneTimeMinus2[0] = 200.0
    state.dataContaminantBalance.DSCO2ZoneTimeMinus3[0] = 200.0
    state.dataContaminantBalance.OutdoorCO2 = 400.0
    state.dataContaminantBalance.OutdoorGC = 0.001
    state.dataContaminantBalance.ZoneCO21[0] = state.dataContaminantBalance.OutdoorCO2
    state.dataContaminantBalance.ZoneGC1[0] = state.dataContaminantBalance.OutdoorGC
    state.dataHVACGlobal.TimeStepSys = 15.0 / 60.0
    state.dataHVACGlobal.TimeStepSysSec = state.dataHVACGlobal.TimeStepSys * Constant.rSecsInHour
    state.dataZoneEquip.ZoneEquipConfig.allocate(1)
    state.dataZoneEquip.ZoneEquipConfig[0].ZoneName = "Zone 1"
    state.dataZoneEquip.ZoneEquipConfig[0].NumInletNodes = 2
    state.dataZoneEquip.ZoneEquipConfig[0].InletNode.allocate(2)
    state.dataZoneEquip.ZoneEquipConfig[0].InletNode[0] = 1
    state.dataZoneEquip.ZoneEquipConfig[0].InletNode[1] = 2
    state.dataZoneEquip.ZoneEquipConfig[0].NumExhaustNodes = 1
    state.dataZoneEquip.ZoneEquipConfig[0].ExhaustNode.allocate(1)
    state.dataZoneEquip.ZoneEquipConfig[0].ExhaustNode[0] = 3
    state.dataZoneEquip.ZoneEquipConfig[0].NumReturnNodes = 1
    state.dataZoneEquip.ZoneEquipConfig[0].ReturnNode.allocate(1)
    state.dataZoneEquip.ZoneEquipConfig[0].ReturnNode[0] = 4
    state.dataZoneEquip.ZoneEquipConfig[0].FixedReturnFlow.allocate(1)
    state.dataLoopNodes.Node.allocate(5)
    state.dataHeatBal.Zone.allocate(1)
    state.dataHeatBal.Zone[0].Name = state.dataZoneEquip.ZoneEquipConfig[0].ZoneName
    state.dataSize.ZoneEqSizing.allocate(1)
    state.dataSize.CurZoneEqNum = 1
    state.dataHeatBal.Zone[0].Multiplier = 1.0
    state.dataHeatBal.Zone[0].Volume = 1000.0
    state.dataHeatBal.Zone[0].SystemZoneNodeNumber = 5
    state.dataHeatBal.Zone[0].ZoneVolCapMultpMoist = 1.0
    state.dataEnvrn.OutBaroPress = 101325.0
    state.dataZonePlenum.NumZoneReturnPlenums = 0
    state.dataZonePlenum.NumZoneSupplyPlenums = 0
    state.dataZoneTempPredictorCorrector.zoneHeatBalance.allocate(1)
    state.dataHeatBal.ZoneAirSolutionAlgo = DataHeatBalance.SolutionAlgo.EulerMethod
    state.dataLoopNodes.Node[0].MassFlowRate = 0.01
    state.dataLoopNodes.Node[0].HumRat = 0.008
    state.dataLoopNodes.Node[1].MassFlowRate = 0.02
    state.dataLoopNodes.Node[1].HumRat = 0.008
    state.dataZoneEquip.ZoneEquipConfig[0].ZoneExhBalanced = 0.0
    state.dataLoopNodes.Node[2].MassFlowRate = 0.00
    state.dataZoneEquip.ZoneEquipConfig[0].ZoneExh = state.dataLoopNodes.Node[2].MassFlowRate
    state.dataLoopNodes.Node[2].HumRat = 0.008
    state.dataLoopNodes.Node[3].MassFlowRate = 0.03
    state.dataLoopNodes.Node[3].HumRat = 0.000
    state.dataLoopNodes.Node[4].HumRat = 0.000
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].airHumRat = 0.008
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].ZT = 24.0
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].MixingMassFlowZone = 0.0
    CorrectZoneContaminants(state, state.dataHVACGlobal.UseZoneTimeStepHistory)
    EXPECT_NEAR(490.0, state.dataLoopNodes.Node[4].CO2, 0.00001)
    EXPECT_NEAR(90.000999, state.dataLoopNodes.Node[4].GenContam, 0.00001)

def test_ZoneContaminantPredictorCorrector_MultiZoneCO2ControlTest(reg: TestZoneContaminantPredictorCorrector):
    state.init_state(state)
    state.dataHVACGlobal.ShortenTimeStepSys = False
    state.dataHVACGlobal.UseZoneTimeStepHistory = False
    state.dataZoneTempPredictorCorrector.zoneHeatBalance.allocate(3)
    state.dataGlobal.NumOfZones = 3
    state.dataContaminantBalance.Contaminant.CO2Simulation = True
    state.dataContaminantBalance.AZ.allocate(3)
    state.dataContaminantBalance.BZ.allocate(3)
    state.dataContaminantBalance.CZ.allocate(3)
    state.dataContaminantBalance.CO2ZoneTimeMinus1Temp.allocate(3)
    state.dataContaminantBalance.CO2ZoneTimeMinus2Temp.allocate(3)
    state.dataContaminantBalance.CO2ZoneTimeMinus3Temp.allocate(3)
    state.dataContaminantBalance.DSCO2ZoneTimeMinus1.allocate(3)
    state.dataContaminantBalance.DSCO2ZoneTimeMinus2.allocate(3)
    state.dataContaminantBalance.DSCO2ZoneTimeMinus3.allocate(3)
    state.dataContaminantBalance.GCZoneTimeMinus1Temp.allocate(3)
    state.dataContaminantBalance.GCZoneTimeMinus2Temp.allocate(3)
    state.dataContaminantBalance.GCZoneTimeMinus3Temp.allocate(3)
    state.dataContaminantBalance.DSGCZoneTimeMinus1.allocate(3)
    state.dataContaminantBalance.DSGCZoneTimeMinus2.allocate(3)
    state.dataContaminantBalance.DSGCZoneTimeMinus3.allocate(3)
    state.dataContaminantBalance.MixingMassFlowCO2.allocate(3)
    state.dataContaminantBalance.MixingMassFlowGC.allocate(3)
    state.dataContaminantBalance.ZoneAirCO2Temp.allocate(3)
    state.dataContaminantBalance.ZoneCO21.allocate(3)
    state.dataContaminantBalance.ZoneAirCO2.allocate(3)
    state.dataContaminantBalance.ZoneAirGCTemp.allocate(3)
    state.dataContaminantBalance.ZoneCO2SetPoint.allocate(3)
    state.dataContaminantBalance.CO2PredictedRate.allocate(3)
    state.dataContaminantBalance.ZoneAirDensityCO.allocate(3)
    state.dataContaminantBalance.ZoneCO2Gain.allocate(3)
    state.dataContaminantBalance.ZoneGCGain.allocate(3)
    state.dataContaminantBalance.ZoneCO2Gain[0] = 0.0001
    state.dataContaminantBalance.ZoneCO2Gain[1] = 0.0002
    state.dataContaminantBalance.ZoneCO2Gain[2] = 0.0003
    state.dataContaminantBalance.MixingMassFlowCO2[0] = 0.0
    state.dataContaminantBalance.MixingMassFlowCO2[1] = 0.0
    state.dataContaminantBalance.MixingMassFlowCO2[2] = 0.0
    state.dataContaminantBalance.DSCO2ZoneTimeMinus1[0] = 200.0
    state.dataContaminantBalance.DSCO2ZoneTimeMinus2[0] = 200.0
    state.dataContaminantBalance.DSCO2ZoneTimeMinus3[0] = 200.0
    state.dataContaminantBalance.DSCO2ZoneTimeMinus1[1] = 200.0
    state.dataContaminantBalance.DSCO2ZoneTimeMinus2[1] = 200.0
    state.dataContaminantBalance.DSCO2ZoneTimeMinus3[1] = 200.0
    state.dataContaminantBalance.DSCO2ZoneTimeMinus1[2] = 200.0
    state.dataContaminantBalance.DSCO2ZoneTimeMinus2[2] = 200.0
    state.dataContaminantBalance.DSCO2ZoneTimeMinus3[2] = 200.0
    state.dataContaminantBalance.OutdoorCO2 = 400.0
    state.dataContaminantBalance.ZoneCO21[0] = state.dataContaminantBalance.OutdoorCO2
    state.dataContaminantBalance.ZoneCO21[1] = state.dataContaminantBalance.OutdoorCO2
    state.dataContaminantBalance.ZoneCO21[2] = state.dataContaminantBalance.OutdoorCO2
    state.dataContaminantBalance.ZoneCO2SetPoint[0] = 450.0
    state.dataContaminantBalance.ZoneCO2SetPoint[1] = 500.0
    state.dataContaminantBalance.ZoneCO2SetPoint[2] = 550.0
    state.dataContaminantBalance.ZoneAirCO2[0] = state.dataContaminantBalance.ZoneCO21[0]
    state.dataContaminantBalance.ZoneAirCO2[1] = state.dataContaminantBalance.ZoneCO21[1]
    state.dataContaminantBalance.ZoneAirCO2[2] = state.dataContaminantBalance.ZoneCO21[2]
    var PriorTimeStep: Float64
    state.dataHVACGlobal.TimeStepSys = 15.0 / 60.0
    state.dataHVACGlobal.TimeStepSysSec = state.dataHVACGlobal.TimeStepSys * Constant.rSecsInHour
    PriorTimeStep = state.dataHVACGlobal.TimeStepSys
    state.dataZoneEquip.ZoneEquipConfig.allocate(3)
    state.dataZoneEquip.ZoneEquipConfig[0].ZoneName = "Zone 1"
    state.dataZoneEquip.ZoneEquipConfig[0].NumInletNodes = 2
    state.dataZoneEquip.ZoneEquipConfig[0].InletNode.allocate(2)
    state.dataZoneEquip.ZoneEquipConfig[0].InletNode[0] = 1
    state.dataZoneEquip.ZoneEquipConfig[0].InletNode[1] = 2
    state.dataZoneEquip.ZoneEquipConfig[0].NumExhaustNodes = 1
    state.dataZoneEquip.ZoneEquipConfig[0].ExhaustNode.allocate(1)
    state.dataZoneEquip.ZoneEquipConfig[0].ExhaustNode[0] = 3
    state.dataZoneEquip.ZoneEquipConfig[0].NumReturnNodes = 1
    state.dataZoneEquip.ZoneEquipConfig[0].ReturnNode.allocate(1)
    state.dataZoneEquip.ZoneEquipConfig[0].ReturnNode[0] = 4
    state.dataZoneEquip.ZoneEquipConfig[0].FixedReturnFlow.allocate(1)
    state.dataZoneEquip.ZoneEquipConfig[1].ZoneName = "Zone 2"
    state.dataZoneEquip.ZoneEquipConfig[1].NumInletNodes = 1
    state.dataZoneEquip.ZoneEquipConfig[1].InletNode.allocate(1)
    state.dataZoneEquip.ZoneEquipConfig[1].InletNode[0] = 6
    state.dataZoneEquip.ZoneEquipConfig[1].NumExhaustNodes = 0
    state.dataZoneEquip.ZoneEquipConfig[1].NumReturnNodes = 1
    state.dataZoneEquip.ZoneEquipConfig[1].ReturnNode.allocate(1)
    state.dataZoneEquip.ZoneEquipConfig[1].ReturnNode[0] = 7
    state.dataZoneEquip.ZoneEquipConfig[1].FixedReturnFlow.allocate(1)
    state.dataZoneEquip.ZoneEquipConfig[2].ZoneName = "Zone 3"
    state.dataZoneEquip.ZoneEquipConfig[2].NumInletNodes = 1
    state.dataZoneEquip.ZoneEquipConfig[2].InletNode.allocate(1)
    state.dataZoneEquip.ZoneEquipConfig[2].InletNode[0] = 8
    state.dataZoneEquip.ZoneEquipConfig[2].NumExhaustNodes = 0
    state.dataZoneEquip.ZoneEquipConfig[2].NumReturnNodes = 1
    state.dataZoneEquip.ZoneEquipConfig[2].ReturnNode.allocate(1)
    state.dataZoneEquip.ZoneEquipConfig[2].ReturnNode[0] = 9
    state.dataZoneEquip.ZoneEquipConfig[2].FixedReturnFlow.allocate(1)
    state.dataLoopNodes.Node.allocate(10)
    state.dataHeatBal.Zone.allocate(3)
    state.dataHeatBal.Zone[0].Name = state.dataZoneEquip.ZoneEquipConfig[0].ZoneName
    state.dataSize.ZoneEqSizing.allocate(3)
    state.dataSize.CurZoneEqNum = 1
    state.dataHeatBal.Zone[0].Multiplier = 1.0
    state.dataHeatBal.Zone[0].Volume = 1000.0
    state.dataHeatBal.Zone[0].SystemZoneNodeNumber = 5
    state.dataHeatBal.Zone[0].ZoneVolCapMultpMoist = 1.0
    state.dataHeatBal.Zone[1].Name = state.dataZoneEquip.ZoneEquipConfig[1].ZoneName
    state.dataHeatBal.Zone[1].Multiplier = 1.0
    state.dataHeatBal.Zone[1].Volume = 1000.0
    state.dataHeatBal.Zone[1].SystemZoneNodeNumber = 5
    state.dataHeatBal.Zone[1].ZoneVolCapMultpMoist = 1.0
    state.dataHeatBal.Zone[2].Name = state.dataZoneEquip.ZoneEquipConfig[2].ZoneName
    state.dataHeatBal.Zone[2].Multiplier = 1.0
    state.dataHeatBal.Zone[2].Volume = 1000.0
    state.dataHeatBal.Zone[2].SystemZoneNodeNumber = 5
    state.dataHeatBal.Zone[2].ZoneVolCapMultpMoist = 1.0
    state.dataEnvrn.OutBaroPress = 101325.0
    state.dataZonePlenum.NumZoneReturnPlenums = 0
    state.dataZonePlenum.NumZoneSupplyPlenums = 0
    state.dataZoneTempPredictorCorrector.zoneHeatBalance.allocate(3)
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].MDotOA = 0.001
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[1].MDotOA = 0.001
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[2].MDotOA = 0.001
    state.dataHeatBal.ZoneAirSolutionAlgo = DataHeatBalance.SolutionAlgo.EulerMethod
    state.dataLoopNodes.Node[0].MassFlowRate = 0.01
    state.dataLoopNodes.Node[0].HumRat = 0.008
    state.dataLoopNodes.Node[1].MassFlowRate = 0.02
    state.dataLoopNodes.Node[1].HumRat = 0.008
    state.dataZoneEquip.ZoneEquipConfig[0].ZoneExhBalanced = 0.0
    state.dataLoopNodes.Node[2].MassFlowRate = 0.00
    state.dataZoneEquip.ZoneEquipConfig[0].ZoneExh = state.dataLoopNodes.Node[2].MassFlowRate
    state.dataLoopNodes.Node[2].HumRat = 0.008
    state.dataLoopNodes.Node[3].MassFlowRate = 0.03
    state.dataLoopNodes.Node[3].HumRat = 0.000
    state.dataLoopNodes.Node[4].HumRat = 0.000
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].airHumRat = 0.008
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].ZT = 24.0
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[1].airHumRat = 0.008
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[1].ZT = 23.5
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[2].airHumRat = 0.008
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[2].ZT = 24.5
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].MixingMassFlowZone = 0.0
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[1].MixingMassFlowZone = 0.0
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[2].MixingMassFlowZone = 0.0
    state.dataLoopNodes.Node[5].MassFlowRate = 0.01
    state.dataLoopNodes.Node[6].MassFlowRate = 0.01
    state.dataLoopNodes.Node[7].MassFlowRate = 0.01
    state.dataLoopNodes.Node[8].MassFlowRate = 0.01
    state.dataContaminantBalance.CO2PredictedRate.allocate(3)
    state.dataContaminantBalance.ZoneSysContDemand.allocate(3)
    state.dataContaminantBalance.ContaminantControlledZone.allocate(3)
    state.dataContaminantBalance.ContaminantControlledZone[0].availSched = Sched.GetScheduleAlwaysOn(state)
    state.dataContaminantBalance.ContaminantControlledZone[0].genericContamAvailSched = Sched.GetScheduleAlwaysOn(state)
    state.dataContaminantBalance.ContaminantControlledZone[0].ActualZoneNum = 1
    state.dataContaminantBalance.ContaminantControlledZone[0].NumOfZones = 1
    state.dataContaminantBalance.ContaminantControlledZone[1].availSched = Sched.GetScheduleAlwaysOn(state)
    state.dataContaminantBalance.ContaminantControlledZone[1].genericContamAvailSched = Sched.GetScheduleAlwaysOn(state)
    state.dataContaminantBalance.ContaminantControlledZone[1].ActualZoneNum = 2
    state.dataContaminantBalance.ContaminantControlledZone[1].NumOfZones = 1
    state.dataContaminantBalance.ContaminantControlledZone[2].availSched = Sched.GetScheduleAlwaysOn(state)
    state.dataContaminantBalance.ContaminantControlledZone[2].genericContamAvailSched = Sched.GetScheduleAlwaysOn(state)
    state.dataContaminantBalance.ContaminantControlledZone[2].ActualZoneNum = 3
    state.dataContaminantBalance.ContaminantControlledZone[2].NumOfZones = 1
    PredictZoneContaminants(state, state.dataHVACGlobal.ShortenTimeStepSys, state.dataHVACGlobal.UseZoneTimeStepHistory, PriorTimeStep)
    EXPECT_NEAR(1.0416921806, state.dataContaminantBalance.CO2PredictedRate[0], 0.00001)
    EXPECT_NEAR(1.0434496257, state.dataContaminantBalance.CO2PredictedRate[1], 0.00001)
    EXPECT_NEAR(1.0399406399, state.dataContaminantBalance.CO2PredictedRate[2], 0.00001)

def test_ZoneContaminantPredictorCorrector_MultiZoneGCControlTest(reg: TestZoneContaminantPredictorCorrector):
    state.init_state(state)
    state.dataHVACGlobal.ShortenTimeStepSys = False
    state.dataHVACGlobal.UseZoneTimeStepHistory = False
    state.dataZoneTempPredictorCorrector.zoneHeatBalance.allocate(3)
    state.dataGlobal.NumOfZones = 3
    state.dataContaminantBalance.Contaminant.CO2Simulation = False
    state.dataContaminantBalance.Contaminant.GenericContamSimulation = True
    state.dataContaminantBalance.AZGC.allocate(3)
    state.dataContaminantBalance.BZGC.allocate(3)
    state.dataContaminantBalance.CZGC.allocate(3)
    state.dataContaminantBalance.GCZoneTimeMinus1Temp.allocate(3)
    state.dataContaminantBalance.GCZoneTimeMinus2Temp.allocate(3)
    state.dataContaminantBalance.GCZoneTimeMinus3Temp.allocate(3)
    state.dataContaminantBalance.DSGCZoneTimeMinus1.allocate(3)
    state.dataContaminantBalance.DSGCZoneTimeMinus2.allocate(3)
    state.dataContaminantBalance.DSGCZoneTimeMinus3.allocate(3)
    state.dataContaminantBalance.MixingMassFlowGC.allocate(3)
    state.dataContaminantBalance.ZoneAirGCTemp.allocate(3)
    state.dataContaminantBalance.ZoneGC1.allocate(3)
    state.dataContaminantBalance.ZoneAirGC.allocate(3)
    state.dataContaminantBalance.ZoneGCSetPoint.allocate(3)
    state.dataContaminantBalance.GCPredictedRate.allocate(3)
    state.dataContaminantBalance.ZoneGCGain.allocate(3)
    state.dataContaminantBalance.ZoneGCGain[0] = 0.0001
    state.dataContaminantBalance.ZoneGCGain[1] = 0.0002
    state.dataContaminantBalance.ZoneGCGain[2] = 0.0003
    state.dataContaminantBalance.MixingMassFlowGC[0] = 0.0
    state.dataContaminantBalance.MixingMassFlowGC[1] = 0.0
    state.dataContaminantBalance.MixingMassFlowGC[2] = 0.0
    state.dataContaminantBalance.OutdoorGC = 10.0
    state.dataContaminantBalance.DSGCZoneTimeMinus1[0] = state.dataContaminantBalance.OutdoorGC
    state.dataContaminantBalance.DSGCZoneTimeMinus2[0] = state.dataContaminantBalance.OutdoorGC
    state.dataContaminantBalance.DSGCZoneTimeMinus3[0] = state.dataContaminantBalance.OutdoorGC
    state.dataContaminantBalance.DSGCZoneTimeMinus1[1] = state.dataContaminantBalance.OutdoorGC
    state.dataContaminantBalance.DSGCZoneTimeMinus2[1] = state.dataContaminantBalance.OutdoorGC
    state.dataContaminantBalance.DSGCZoneTimeMinus3[1] = state.dataContaminantBalance.OutdoorGC
    state.dataContaminantBalance.DSGCZoneTimeMinus1[2] = state.dataContaminantBalance.OutdoorGC
    state.dataContaminantBalance.DSGCZoneTimeMinus2[2] = state.dataContaminantBalance.OutdoorGC
    state.dataContaminantBalance.DSGCZoneTimeMinus3[2] = state.dataContaminantBalance.OutdoorGC
    state.dataContaminantBalance.ZoneGC1[0] = state.dataContaminantBalance.OutdoorCO2
    state.dataContaminantBalance.ZoneGC1[1] = state.dataContaminantBalance.OutdoorCO2
    state.dataContaminantBalance.ZoneGC1[2] = state.dataContaminantBalance.OutdoorCO2
    state.dataContaminantBalance.ZoneGCSetPoint[0] = 15.0
    state.dataContaminantBalance.ZoneGCSetPoint[1] = 20.0
    state.dataContaminantBalance.ZoneGCSetPoint[2] = 25.0
    state.dataContaminantBalance.ZoneAirGC[0] = state.dataContaminantBalance.ZoneGC1[0]
    state.dataContaminantBalance.ZoneAirGC[1] = state.dataContaminantBalance.ZoneGC1[1]
    state.dataContaminantBalance.ZoneAirGC[2] = state.dataContaminantBalance.ZoneGC1[2]
    var PriorTimeStep: Float64
    state.dataHVACGlobal.TimeStepSys = 15.0 / 60.0
    state.dataHVACGlobal.TimeStepSysSec = state.dataHVACGlobal.TimeStepSys * Constant.rSecsInHour
    PriorTimeStep = state.dataHVACGlobal.TimeStepSys
    state.dataZoneEquip.ZoneEquipConfig.allocate(3)
    state.dataZoneEquip.ZoneEquipConfig[0].ZoneName = "Zone 1"
    state.dataZoneEquip.ZoneEquipConfig[0].NumInletNodes = 2
    state.dataZoneEquip.ZoneEquipConfig[0].InletNode.allocate(2)
    state.dataZoneEquip.ZoneEquipConfig[0].InletNode[0] = 1
    state.dataZoneEquip.ZoneEquipConfig[0].InletNode[1] = 2
    state.dataZoneEquip.ZoneEquipConfig[0].NumExhaustNodes = 1
    state.dataZoneEquip.ZoneEquipConfig[0].ExhaustNode.allocate(1)
    state.dataZoneEquip.ZoneEquipConfig[0].ExhaustNode[0] = 3
    state.dataZoneEquip.ZoneEquipConfig[0].NumReturnNodes = 1
    state.dataZoneEquip.ZoneEquipConfig[0].ReturnNode.allocate(1)
    state.dataZoneEquip.ZoneEquipConfig[0].ReturnNode[0] = 4
    state.dataZoneEquip.ZoneEquipConfig[0].FixedReturnFlow.allocate(1)
    state.dataZoneEquip.ZoneEquipConfig[1].ZoneName = "Zone 2"
    state.dataZoneEquip.ZoneEquipConfig[1].NumInletNodes = 1
    state.dataZoneEquip.ZoneEquipConfig[1].InletNode.allocate(1)
    state.dataZoneEquip.ZoneEquipConfig[1].InletNode[0] = 6
    state.dataZoneEquip.ZoneEquipConfig[1].NumExhaustNodes = 0
    state.dataZoneEquip.ZoneEquipConfig[1].NumReturnNodes = 1
    state.dataZoneEquip.ZoneEquipConfig[1].ReturnNode.allocate(1)
    state.dataZoneEquip.ZoneEquipConfig[1].ReturnNode[0] = 7
    state.dataZoneEquip.ZoneEquipConfig[1].FixedReturnFlow.allocate(1)
    state.dataZoneEquip.ZoneEquipConfig[2].ZoneName = "Zone 3"
    state.dataZoneEquip.ZoneEquipConfig[2].NumInletNodes = 1
    state.dataZoneEquip.ZoneEquipConfig[2].InletNode.allocate(1)
    state.dataZoneEquip.ZoneEquipConfig[2].InletNode[0] = 8
    state.dataZoneEquip.ZoneEquipConfig[2].NumExhaustNodes = 0
    state.dataZoneEquip.ZoneEquipConfig[2].NumReturnNodes = 1
    state.dataZoneEquip.ZoneEquipConfig[2].ReturnNode.allocate(1)
    state.dataZoneEquip.ZoneEquipConfig[2].ReturnNode[0] = 9
    state.dataZoneEquip.ZoneEquipConfig[2].FixedReturnFlow.allocate(1)
    state.dataLoopNodes.Node.allocate(10)
    state.dataHeatBal.Zone.allocate(3)
    state.dataHeatBal.Zone[0].Name = state.dataZoneEquip.ZoneEquipConfig[0].ZoneName
    state.dataSize.ZoneEqSizing.allocate(3)
    state.dataSize.CurZoneEqNum = 1
    state.dataHeatBal.Zone[0].Multiplier = 1.0
    state.dataHeatBal.Zone[0].Volume = 1000.0
    state.dataHeatBal.Zone[0].SystemZoneNodeNumber = 5
    state.dataHeatBal.Zone[0].ZoneVolCapMultpMoist = 1.0
    state.dataHeatBal.Zone[1].Name = state.dataZoneEquip.ZoneEquipConfig[1].ZoneName
    state.dataHeatBal.Zone[1].Multiplier = 1.0
    state.dataHeatBal.Zone[1].Volume = 1000.0
    state.dataHeatBal.Zone[1].SystemZoneNodeNumber = 5
    state.dataHeatBal.Zone[1].ZoneVolCapMultpMoist = 1.0
    state.dataHeatBal.Zone[2].Name = state.dataZoneEquip.ZoneEquipConfig[2].ZoneName
    state.dataHeatBal.Zone[2].Multiplier = 1.0
    state.dataHeatBal.Zone[2].Volume = 1000.0
    state.dataHeatBal.Zone[2].SystemZoneNodeNumber = 5
    state.dataHeatBal.Zone[2].ZoneVolCapMultpMoist = 1.0
    state.dataEnvrn.OutBaroPress = 101325.0
    state.dataZonePlenum.NumZoneReturnPlenums = 0
    state.dataZonePlenum.NumZoneSupplyPlenums = 0
    state.dataZoneTempPredictorCorrector.zoneHeatBalance.allocate(3)
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].MDotOA = 0.001
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[1].MDotOA = 0.001
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[2].MDotOA = 0.001
    state.dataHeatBal.ZoneAirSolutionAlgo = DataHeatBalance.SolutionAlgo.EulerMethod
    state.dataLoopNodes.Node[0].MassFlowRate = 0.01
    state.dataLoopNodes.Node[0].HumRat = 0.008
    state.dataLoopNodes.Node[1].MassFlowRate = 0.02
    state.dataLoopNodes.Node[1].HumRat = 0.008
    state.dataZoneEquip.ZoneEquipConfig[0].ZoneExhBalanced = 0.0
    state.dataLoopNodes.Node[2].MassFlowRate = 0.00
    state.dataZoneEquip.ZoneEquipConfig[0].ZoneExh = state.dataLoopNodes.Node[2].MassFlowRate
    state.dataLoopNodes.Node[2].HumRat = 0.008
    state.dataLoopNodes.Node[3].MassFlowRate = 0.03
    state.dataLoopNodes.Node[3].HumRat = 0.000
    state.dataLoopNodes.Node[4].HumRat = 0.000
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].airHumRat = 0.008
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].ZT = 24.0
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[1].airHumRat = 0.008
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[1].ZT = 23.5
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[2].airHumRat = 0.008
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[2].ZT = 24.5
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].MixingMassFlowZone = 0.0
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[1].MixingMassFlowZone = 0.0
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[2].MixingMassFlowZone = 0.0
    state.dataLoopNodes.Node[5].MassFlowRate = 0.01
    state.dataLoopNodes.Node[6].MassFlowRate = 0.01
    state.dataLoopNodes.Node[7].MassFlowRate = 0.01
    state.dataLoopNodes.Node[8].MassFlowRate = 0.01
    state.dataContaminantBalance.GCPredictedRate.allocate(3)
    state.dataContaminantBalance.ZoneSysContDemand.allocate(3)
    state.dataContaminantBalance.ContaminantControlledZone.allocate(3)
    state.dataContaminantBalance.ContaminantControlledZone[0].availSched = Sched.GetScheduleAlwaysOn(state)
    state.dataContaminantBalance.ContaminantControlledZone[0].genericContamAvailSched = Sched.GetScheduleAlwaysOn(state)
    state.dataContaminantBalance.ContaminantControlledZone[0].ActualZoneNum = 1
    state.dataContaminantBalance.ContaminantControlledZone[0].NumOfZones = 1
    state.dataContaminantBalance.ContaminantControlledZone[1].availSched = Sched.GetScheduleAlwaysOn(state)
    state.dataContaminantBalance.ContaminantControlledZone[1].genericContamAvailSched = Sched.GetScheduleAlwaysOn(state)
    state.dataContaminantBalance.ContaminantControlledZone[1].ActualZoneNum = 2
    state.dataContaminantBalance.ContaminantControlledZone[1].NumOfZones = 1
    state.dataContaminantBalance.ContaminantControlledZone[2].availSched = Sched.GetScheduleAlwaysOn(state)
    state.dataContaminantBalance.ContaminantControlledZone[2].genericContamAvailSched = Sched.GetScheduleAlwaysOn(state)
    state.dataContaminantBalance.ContaminantControlledZone[2].ActualZoneNum = 3
    state.dataContaminantBalance.ContaminantControlledZone[2].NumOfZones = 1
    PredictZoneContaminants(state, state.dataHVACGlobal.ShortenTimeStepSys, state.dataHVACGlobal.UseZoneTimeStepHistory, PriorTimeStep)
    EXPECT_NEAR(19.549478386, state.dataContaminantBalance.GCPredictedRate[0], 0.00001)
    EXPECT_NEAR(20.887992514, state.dataContaminantBalance.GCPredictedRate[1], 0.00001)
    EXPECT_NEAR(21.251538064, state.dataContaminantBalance.GCPredictedRate[2], 0.00001)