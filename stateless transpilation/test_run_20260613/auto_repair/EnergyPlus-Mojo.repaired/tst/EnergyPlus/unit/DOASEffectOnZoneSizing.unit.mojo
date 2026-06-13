# Faithful 1:1 translation of DOASEffectOnZoneSizing.unit.cc to Mojo
# No refactoring; test macros replaced with simple assert helpers.

from Fixtures.EnergyPlusFixture import EnergyPlusFixture
from AirflowNetwork.Solver import *
from EnergyPlus.Data.EnergyPlusData import *
from EnergyPlus.DataEnvironment import *
from EnergyPlus.DataHeatBalFanSys import *
from EnergyPlus.DataHeatBalance import *
from EnergyPlus.DataLoopNode import *
from EnergyPlus.DataSizing import *
from EnergyPlus.DataStringGlobals import *
from EnergyPlus.DataZoneEnergyDemands import *
from EnergyPlus.DataZoneEquipment import *
from EnergyPlus.HeatBalanceManager import *
from EnergyPlus.IOFiles import *
from EnergyPlus.ZoneEquipmentManager import *
from EnergyPlus.ZoneTempPredictorCorrector import *

# Test assertion helpers (equivalent to EXPECT_DOUBLE_EQ and EXPECT_NEAR)
def EXPECT_DOUBLE_EQ(expected: Float64, actual: Float64):
    if abs(expected - actual) > 1e-12:
        print("EXPECT_DOUBLE_EQ failed: expected", expected, "got", actual)
        abort()

def EXPECT_NEAR(expected: Float64, actual: Float64, tolerance: Float64):
    if abs(expected - actual) > tolerance:
        print("EXPECT_NEAR failed: expected", expected, "got", actual, "tolerance", tolerance)
        abort()

# Test1: DOASEffectOnZoneSizing_CalcDOASSupCondsForSizing
def DOASEffectOnZoneSizing_CalcDOASSupCondsForSizing():
    var state_ptr = EnergyPlusFixture()
    state_ptr.init_state(state_ptr[])
    var OutDB: Float64
    var OutHR: Float64
    var DOASLowTemp: Float64
    var DOASHighTemp: Float64
    var DOASSupTemp: Float64
    var DOASSupHR: Float64
    var DOASControl: DataSizing.DOASControl = DataSizing.DOASControl.NeutralSup
    DOASLowTemp = 21.1
    DOASHighTemp = 23.9
    OutDB = 10.0
    OutHR = 0.005
    CalcDOASSupCondsForSizing(state_ptr[], OutDB, OutHR, DOASControl, DOASLowTemp, DOASHighTemp, 0.016, 0.0143, DOASSupTemp, DOASSupHR)
    EXPECT_DOUBLE_EQ(21.1, DOASSupTemp)
    EXPECT_DOUBLE_EQ(0.005, DOASSupHR)
    OutDB = 35.6
    OutHR = 0.0185
    CalcDOASSupCondsForSizing(state_ptr[], OutDB, OutHR, DOASControl, DOASLowTemp, DOASHighTemp, 0.016, 0.0143, DOASSupTemp, DOASSupHR)
    EXPECT_DOUBLE_EQ(23.9, DOASSupTemp)
    EXPECT_DOUBLE_EQ(0.016, DOASSupHR)
    OutDB = 22.3
    OutHR = 0.0085
    CalcDOASSupCondsForSizing(state_ptr[], OutDB, OutHR, DOASControl, DOASLowTemp, DOASHighTemp, 0.016, 0.0143, DOASSupTemp, DOASSupHR)
    EXPECT_DOUBLE_EQ(22.3, DOASSupTemp)
    EXPECT_DOUBLE_EQ(0.0085, DOASSupHR)
    DOASControl = DataSizing.DOASControl.NeutralDehumSup
    DOASLowTemp = 14.4
    DOASHighTemp = 22.2
    OutDB = 11
    OutHR = 0.004
    CalcDOASSupCondsForSizing(state_ptr[], OutDB, OutHR, DOASControl, DOASLowTemp, DOASHighTemp, 0.0153, 0.0092, DOASSupTemp, DOASSupHR)
    EXPECT_DOUBLE_EQ(22.2, DOASSupTemp)
    EXPECT_DOUBLE_EQ(0.004, DOASSupHR)
    OutDB = 35.6
    OutHR = 0.0185
    CalcDOASSupCondsForSizing(state_ptr[], OutDB, OutHR, DOASControl, DOASLowTemp, DOASHighTemp, 0.0153, 0.0092, DOASSupTemp, DOASSupHR)
    EXPECT_DOUBLE_EQ(22.2, DOASSupTemp)
    EXPECT_DOUBLE_EQ(0.0092, DOASSupHR)
    DOASControl = DataSizing.DOASControl.CoolSup
    DOASLowTemp = 12.2
    DOASHighTemp = 14.4
    OutDB = 11
    OutHR = 0.005
    CalcDOASSupCondsForSizing(state_ptr[], OutDB, OutHR, DOASControl, DOASLowTemp, DOASHighTemp, 0.0092, 0.008, DOASSupTemp, DOASSupHR)
    EXPECT_DOUBLE_EQ(14.4, DOASSupTemp)
    EXPECT_DOUBLE_EQ(0.005, DOASSupHR)
    OutDB = 35.6
    OutHR = 0.0185
    CalcDOASSupCondsForSizing(state_ptr[], OutDB, OutHR, DOASControl, DOASLowTemp, DOASHighTemp, 0.0092, 0.008, DOASSupTemp, DOASSupHR)
    EXPECT_DOUBLE_EQ(12.2, DOASSupTemp)
    EXPECT_DOUBLE_EQ(0.008, DOASSupHR)

# Test2: DOASEffectOnZoneSizing_SizeZoneEquipment
def DOASEffectOnZoneSizing_SizeZoneEquipment():
    var state_ptr = EnergyPlusFixture()
    state_ptr.init_state(state_ptr[])
    state_ptr.dataLoopNodes.Node.allocate(10)
    state_ptr.dataSize.ZoneEqSizing.allocate(2)
    state_ptr.dataHeatBal.Zone.allocate(2)
    state_ptr.dataSize.CalcZoneSizing.allocate(1, 2)
    state_ptr.dataSize.CalcFinalZoneSizing.allocate(2)
    state_ptr.dataZoneTempPredictorCorrector.zoneHeatBalance.allocate(2)
    state_ptr.dataZoneEquip.ZoneEquipConfig.allocate(2)
    state_ptr.dataHeatBalFanSys.TempControlType.allocate(2)
    state_ptr.dataHeatBalFanSys.zoneTstatSetpts.allocate(2)
    state_ptr.dataZoneEnergyDemand.ZoneSysEnergyDemand.allocate(2)
    state_ptr.dataZoneEnergyDemand.ZoneSysMoistureDemand.allocate(2)
    state_ptr.dataZoneEnergyDemand.DeadBandOrSetback.allocate(2)
    state_ptr.dataZoneEnergyDemand.CurDeadBandOrSetback.allocate(2)
    state_ptr.dataZoneEquip.ZoneEquipConfig(1).InletNode.allocate(2)
    state_ptr.dataZoneEquip.ZoneEquipConfig(2).InletNode.allocate(2)
    state_ptr.dataZoneEquip.ZoneEquipConfig(1).ExhaustNode.allocate(1)
    state_ptr.dataZoneEquip.ZoneEquipConfig(2).ExhaustNode.allocate(1)
    state_ptr.dataZoneEquip.ZoneEquipConfig(1).returnFlowFracSched = Sched.GetScheduleAlwaysOff(state_ptr[])
    state_ptr.dataZoneEquip.ZoneEquipConfig(2).returnFlowFracSched = Sched.GetScheduleAlwaysOff(state_ptr[])
    state_ptr.dataHeatBalFanSys.ZoneMassBalanceFlag.allocate(2)
    state_ptr.dataGlobal.NumOfZones = 2
    state_ptr.dataHeatBal.MassConservation.allocate(state_ptr.dataGlobal.NumOfZones)
    HeatBalanceManager.AllocateHeatBalArrays(state_ptr[])
    state_ptr.afn.AirflowNetworkNumOfExhFan = 0
    state_ptr.dataHeatBalFanSys.TempControlType(1) = HVAC.SetptType.DualHeatCool
    state_ptr.dataHeatBalFanSys.TempControlType(2) = HVAC.SetptType.DualHeatCool
    state_ptr.dataHeatBalFanSys.zoneTstatSetpts(1).setpt = 0.0
    state_ptr.dataHeatBalFanSys.zoneTstatSetpts(2).setpt = 0.0
    state_ptr.dataHeatBalFanSys.zoneTstatSetpts(1).setptLo = 22.
    state_ptr.dataHeatBalFanSys.zoneTstatSetpts(2).setptLo = 22.
    state_ptr.dataHeatBalFanSys.zoneTstatSetpts(1).setptHi = 24.
    state_ptr.dataHeatBalFanSys.zoneTstatSetpts(2).setptHi = 24.
    state_ptr.dataSize.CurOverallSimDay = 1
    state_ptr.dataZoneEquip.ZoneEquipConfig(1).IsControlled = true
    state_ptr.dataZoneEquip.ZoneEquipConfig(2).IsControlled = true
    state_ptr.dataSize.CalcZoneSizing(1, 1).ZoneNum = 1
    state_ptr.dataSize.CalcZoneSizing(1, 2).ZoneNum = 2
    state_ptr.dataSize.CalcZoneSizing(1, 1).AccountForDOAS = true
    state_ptr.dataSize.CalcZoneSizing(1, 2).AccountForDOAS = true
    state_ptr.dataSize.CurOverallSimDay = 1
    state_ptr.dataZoneEnergyDemand.ZoneSysEnergyDemand(2).TotalOutputRequired = -2600
    state_ptr.dataZoneEnergyDemand.ZoneSysEnergyDemand(2).OutputRequiredToHeatingSP = -21100
    state_ptr.dataZoneEnergyDemand.ZoneSysEnergyDemand(2).OutputRequiredToCoolingSP = -2600
    state_ptr.dataZoneEnergyDemand.ZoneSysEnergyDemand(1).TotalOutputRequired = 3600
    state_ptr.dataZoneEnergyDemand.ZoneSysEnergyDemand(1).OutputRequiredToHeatingSP = 3600
    state_ptr.dataZoneEnergyDemand.ZoneSysEnergyDemand(1).OutputRequiredToCoolingSP = 22000.
    state_ptr.dataZoneEnergyDemand.ZoneSysMoistureDemand(1).TotalOutputRequired = 0.0
    state_ptr.dataZoneEnergyDemand.ZoneSysMoistureDemand(1).OutputRequiredToHumidifyingSP = 0.0
    state_ptr.dataZoneEnergyDemand.ZoneSysMoistureDemand(1).OutputRequiredToDehumidifyingSP = 0.0
    state_ptr.dataZoneEnergyDemand.ZoneSysMoistureDemand(2).TotalOutputRequired = 0.0
    state_ptr.dataZoneEnergyDemand.ZoneSysMoistureDemand(2).OutputRequiredToHumidifyingSP = 0.0
    state_ptr.dataZoneEnergyDemand.ZoneSysMoistureDemand(2).OutputRequiredToDehumidifyingSP = 0.0
    state_ptr.dataZoneEnergyDemand.DeadBandOrSetback(1) = false
    state_ptr.dataZoneEnergyDemand.DeadBandOrSetback(2) = false
    state_ptr.dataZoneEnergyDemand.CurDeadBandOrSetback(1) = false
    state_ptr.dataZoneEnergyDemand.CurDeadBandOrSetback(2) = false
    state_ptr.dataZoneEquip.ZoneEquipConfig(1).ZoneNode = 4
    state_ptr.dataZoneEquip.ZoneEquipConfig(2).ZoneNode = 9
    state_ptr.dataHeatBal.Zone(1).SystemZoneNodeNumber = 4
    state_ptr.dataHeatBal.Zone(2).SystemZoneNodeNumber = 9
    state_ptr.dataZoneEquip.ZoneEquipConfig(1).NumInletNodes = 2
    state_ptr.dataZoneEquip.ZoneEquipConfig(2).NumInletNodes = 2
    state_ptr.dataZoneEquip.ZoneEquipConfig(1).NumExhaustNodes = 1
    state_ptr.dataZoneEquip.ZoneEquipConfig(2).NumExhaustNodes = 1
    state_ptr.dataZoneEquip.ZoneEquipConfig(1).InletNode(1) = 1
    state_ptr.dataZoneEquip.ZoneEquipConfig(1).InletNode(2) = 2
    state_ptr.dataZoneEquip.ZoneEquipConfig(2).InletNode(1) = 6
    state_ptr.dataZoneEquip.ZoneEquipConfig(2).InletNode(2) = 7
    state_ptr.dataZoneEquip.ZoneEquipConfig(1).ExhaustNode(1) = 3
    state_ptr.dataZoneEquip.ZoneEquipConfig(2).ExhaustNode(1) = 8
    state_ptr.dataZoneEquip.ZoneEquipConfig(1).NumReturnNodes = 0
    state_ptr.dataZoneEquip.ZoneEquipConfig(2).NumReturnNodes = 0
    state_ptr.dataSize.CalcZoneSizing(state_ptr.dataSize.CurOverallSimDay, 1).DOASHighSetpoint = 14.4
    state_ptr.dataSize.CalcZoneSizing(state_ptr.dataSize.CurOverallSimDay, 1).DOASLowSetpoint = 12.2
    state_ptr.dataSize.CalcZoneSizing(state_ptr.dataSize.CurOverallSimDay, 2).DOASHighSetpoint = 14.4
    state_ptr.dataSize.CalcZoneSizing(state_ptr.dataSize.CurOverallSimDay, 2).DOASLowSetpoint = 12.2
    state_ptr.dataEnvrn.StdBaroPress = 101325.
    state_ptr.dataEnvrn.StdRhoAir = 1.0
    state_ptr.dataSize.CalcFinalZoneSizing(1).MinOA = 0.1
    state_ptr.dataSize.CalcFinalZoneSizing(2).MinOA = 0.11
    state_ptr.dataSize.CalcZoneSizing(state_ptr.dataSize.CurOverallSimDay, 1).DOASControlStrategy = DataSizing.DOASControl.CoolSup
    state_ptr.dataSize.CalcZoneSizing(state_ptr.dataSize.CurOverallSimDay, 2).DOASControlStrategy = DataSizing.DOASControl.CoolSup
    state_ptr.dataEnvrn.OutDryBulbTemp = 28.
    state_ptr.dataEnvrn.OutHumRat = 0.017
    state_ptr.dataLoopNodes.Node(4).Temp = 22
    state_ptr.dataLoopNodes.Node(4).HumRat = 0.008
    state_ptr.dataLoopNodes.Node(9).Temp = 22.5
    state_ptr.dataLoopNodes.Node(9).HumRat = 0.0085
    state_ptr.dataSize.CalcZoneSizing(state_ptr.dataSize.CurOverallSimDay, 1).ZnCoolDgnSAMethod = 1
    state_ptr.dataSize.CalcZoneSizing(state_ptr.dataSize.CurOverallSimDay, 2).ZnCoolDgnSAMethod = 2
    state_ptr.dataSize.CalcZoneSizing(state_ptr.dataSize.CurOverallSimDay, 1).ZnHeatDgnSAMethod = 1
    state_ptr.dataSize.CalcZoneSizing(state_ptr.dataSize.CurOverallSimDay, 2).ZnHeatDgnSAMethod = 2
    state_ptr.dataSize.CalcZoneSizing(state_ptr.dataSize.CurOverallSimDay, 1).CoolDesTemp = 12.5
    state_ptr.dataSize.CalcZoneSizing(state_ptr.dataSize.CurOverallSimDay, 2).CoolDesTemp = 12.5
    state_ptr.dataSize.CalcZoneSizing(state_ptr.dataSize.CurOverallSimDay, 1).CoolDesTempDiff = 11.11
    state_ptr.dataSize.CalcZoneSizing(state_ptr.dataSize.CurOverallSimDay, 2).CoolDesTempDiff = 11.11
    state_ptr.dataSize.CalcZoneSizing(state_ptr.dataSize.CurOverallSimDay, 1).CoolDesHumRat = 0.008
    state_ptr.dataSize.CalcZoneSizing(state_ptr.dataSize.CurOverallSimDay, 2).CoolDesHumRat = 0.008
    state_ptr.dataSize.CalcZoneSizing(state_ptr.dataSize.CurOverallSimDay, 1).HeatDesHumRat = 0.008
    state_ptr.dataSize.CalcZoneSizing(state_ptr.dataSize.CurOverallSimDay, 2).HeatDesHumRat = 0.008
    state_ptr.dataSize.CalcZoneSizing(state_ptr.dataSize.CurOverallSimDay, 1).HeatDesTemp = 50.0
    state_ptr.dataSize.CalcZoneSizing(state_ptr.dataSize.CurOverallSimDay, 2).HeatDesTemp = 50.0
    state_ptr.dataSize.CalcZoneSizing(state_ptr.dataSize.CurOverallSimDay, 1).HeatDesTempDiff = 30.0
    state_ptr.dataSize.CalcZoneSizing(state_ptr.dataSize.CurOverallSimDay, 2).HeatDesTempDiff = 30.0
    state_ptr.dataSize.CalcZoneSizing(state_ptr.dataSize.CurOverallSimDay, 1).SupplyAirAdjustFactor = 1.0
    state_ptr.dataSize.CalcZoneSizing(state_ptr.dataSize.CurOverallSimDay, 2).SupplyAirAdjustFactor = 1.0
    state_ptr.dataHeatBal.ZoneAirMassFlow.EnforceZoneMassBalance = false
    state_ptr.dataHeatBalFanSys.ZoneMassBalanceFlag(1) = false
    state_ptr.dataHeatBalFanSys.ZoneMassBalanceFlag(2) = false
    state_ptr.dataLoopNodes.Node(1).MassFlowRateMin = 0.0
    state_ptr.dataLoopNodes.Node(1).MassFlowRateMinAvail = 0.0
    state_ptr.dataLoopNodes.Node(1).MassFlowRateMaxAvail = 0.0
    state_ptr.dataLoopNodes.Node(1).MassFlowRateMax = 0.0
    state_ptr.dataLoopNodes.Node(2).MassFlowRateMin = 0.0
    state_ptr.dataLoopNodes.Node(2).MassFlowRateMinAvail = 0.0
    state_ptr.dataLoopNodes.Node(2).MassFlowRateMaxAvail = 0.0
    state_ptr.dataLoopNodes.Node(2).MassFlowRateMax = 0.0
    state_ptr.dataLoopNodes.Node(3).MassFlowRateMin = 0.0
    state_ptr.dataLoopNodes.Node(3).MassFlowRateMinAvail = 0.0
    state_ptr.dataLoopNodes.Node(3).MassFlowRateMaxAvail = 0.0
    state_ptr.dataLoopNodes.Node(3).MassFlowRateMax = 0.0
    state_ptr.dataLoopNodes.Node(6).MassFlowRateMin = 0.0
    state_ptr.dataLoopNodes.Node(6).MassFlowRateMinAvail = 0.0
    state_ptr.dataLoopNodes.Node(6).MassFlowRateMaxAvail = 0.0
    state_ptr.dataLoopNodes.Node(6).MassFlowRateMax = 0.0
    state_ptr.dataLoopNodes.Node(7).MassFlowRateMin = 0.0
    state_ptr.dataLoopNodes.Node(7).MassFlowRateMinAvail = 0.0
    state_ptr.dataLoopNodes.Node(7).MassFlowRateMaxAvail = 0.0
    state_ptr.dataLoopNodes.Node(7).MassFlowRateMax = 0.0
    state_ptr.dataLoopNodes.Node(8).MassFlowRateMin = 0.0
    state_ptr.dataLoopNodes.Node(8).MassFlowRateMinAvail = 0.0
    state_ptr.dataLoopNodes.Node(8).MassFlowRateMaxAvail = 0.0
    state_ptr.dataLoopNodes.Node(8).MassFlowRateMax = 0.0
    state_ptr.dataZoneEquip.ZoneEquipConfig(1).ZoneExh = 0.0
    state_ptr.dataZoneEquip.ZoneEquipConfig(1).ZoneExhBalanced = 0.0
    state_ptr.dataZoneEquip.ZoneEquipConfig(1).PlenumMassFlow = 0.0
    state_ptr.dataZoneEquip.ZoneEquipConfig(2).ZoneExh = 0.0
    state_ptr.dataZoneEquip.ZoneEquipConfig(2).ZoneExhBalanced = 0.0
    state_ptr.dataZoneEquip.ZoneEquipConfig(2).PlenumMassFlow = 0.0
    state_ptr.dataHeatBal.MassConservation(1).MixingMassFlowRate = 0.0
    state_ptr.dataHeatBal.MassConservation(2).MixingMassFlowRate = 0.0
    state_ptr.dataHeatBal.Zone(1).Multiplier = 1.0
    state_ptr.dataHeatBal.Zone(2).Multiplier = 1.0
    state_ptr.dataHeatBal.Zone(1).ListMultiplier = 1
    state_ptr.dataHeatBal.Zone(2).ListMultiplier = 1
    state_ptr.dataZoneEquipmentManager.SizeZoneEquipmentOneTimeFlag = false
    SizeZoneEquipment(state_ptr[])
    EXPECT_DOUBLE_EQ(12.2, state_ptr.dataSize.CalcZoneSizing(1, 1).DOASSupTemp)
    EXPECT_NEAR(0.00795195, state_ptr.dataSize.CalcZoneSizing(1, 1).DOASSupHumRat, 0.00000001)
    EXPECT_DOUBLE_EQ(0.1, state_ptr.dataSize.CalcZoneSizing(1, 1).DOASSupMassFlow)
    EXPECT_NEAR(-999.229, state_ptr.dataSize.CalcZoneSizing(1, 1).DOASHeatAdd, 0.001)
    EXPECT_DOUBLE_EQ(0.0, state_ptr.dataSize.CalcZoneSizing(1, 1).DOASHeatLoad)
    EXPECT_NEAR(-999.229, state_ptr.dataSize.CalcZoneSizing(1, 1).DOASCoolLoad, 0.001)
    EXPECT_NEAR(-1011.442, state_ptr.dataSize.CalcZoneSizing(1, 1).DOASTotCoolLoad, 0.001)
    EXPECT_NEAR(4599.229, state_ptr.dataSize.CalcZoneSizing(1, 1).HeatLoad, 0.001)
    EXPECT_NEAR(0.161083, state_ptr.dataSize.CalcZoneSizing(1, 1).HeatMassFlow, 0.00001)
    EXPECT_DOUBLE_EQ(0.0, state_ptr.dataSize.CalcZoneSizing(1, 1).CoolLoad)
    EXPECT_DOUBLE_EQ(0.0, state_ptr.dataSize.CalcZoneSizing(1, 1).CoolMassFlow)
    EXPECT_DOUBLE_EQ(12.2, state_ptr.dataSize.CalcZoneSizing(1, 2).DOASSupTemp)
    EXPECT_NEAR(0.00795195, state_ptr.dataSize.CalcZoneSizing(1, 2).DOASSupHumRat, 0.00000001)
    EXPECT_DOUBLE_EQ(0.11, state_ptr.dataSize.CalcZoneSizing(1, 2).DOASSupMassFlow)
    EXPECT_NEAR(-1155.232, state_ptr.dataSize.CalcZoneSizing(1, 2).DOASHeatAdd, 0.001)
    EXPECT_DOUBLE_EQ(0.0, state_ptr.dataSize.CalcZoneSizing(1, 2).DOASHeatLoad)
    EXPECT_NEAR(-1155.232, state_ptr.dataSize.CalcZoneSizing(1, 2).DOASCoolLoad, 0.001)
    EXPECT_NEAR(-1308.522, state_ptr.dataSize.CalcZoneSizing(1, 2).DOASTotCoolLoad, 0.001)
    EXPECT_DOUBLE_EQ(0.0, state_ptr.dataSize.CalcZoneSizing(1, 2).HeatLoad)
    EXPECT_DOUBLE_EQ(0.0, state_ptr.dataSize.CalcZoneSizing(1, 2).HeatMassFlow)
    EXPECT_NEAR(1444.767, state_ptr.dataSize.CalcZoneSizing(1, 2).CoolLoad, 0.001)
    EXPECT_NEAR(0.127528, state_ptr.dataSize.CalcZoneSizing(1, 2).CoolMassFlow, 0.000001)

# Test3: TestAutoCalcDOASControlStrategy
def TestAutoCalcDOASControlStrategy():
    var state_ptr = EnergyPlusFixture()
    state_ptr.init_state(state_ptr[])
    state_ptr.dataSize.NumZoneSizingInput = 2
    state_ptr.dataSize.ZoneSizingInput.allocate(state_ptr.dataSize.NumZoneSizingInput)
    state_ptr.dataSize.ZoneSizingInput(1).AccountForDOAS = false
    state_ptr.dataSize.ZoneSizingInput(2).AccountForDOAS = true
    state_ptr.dataSize.ZoneSizingInput(2).DOASControlStrategy = DOASControl.NeutralSup
    state_ptr.dataSize.ZoneSizingInput(2).DOASLowSetpoint = AutoSize
    state_ptr.dataSize.ZoneSizingInput(2).DOASHighSetpoint = AutoSize
    AutoCalcDOASControlStrategy(state_ptr[])
    EXPECT_DOUBLE_EQ(21.1, state_ptr.dataSize.ZoneSizingInput(2).DOASLowSetpoint)
    EXPECT_DOUBLE_EQ(23.9, state_ptr.dataSize.ZoneSizingInput(2).DOASHighSetpoint)
    state_ptr.dataSize.ZoneSizingInput(2).DOASLowSetpoint = AutoSize
    state_ptr.dataSize.ZoneSizingInput(2).DOASHighSetpoint = 23.7
    AutoCalcDOASControlStrategy(state_ptr[])
    EXPECT_NEAR(20.9, state_ptr.dataSize.ZoneSizingInput(2).DOASLowSetpoint, 0.000001)
    EXPECT_DOUBLE_EQ(23.7, state_ptr.dataSize.ZoneSizingInput(2).DOASHighSetpoint)
    state_ptr.dataSize.ZoneSizingInput(2).DOASLowSetpoint = 21.2
    state_ptr.dataSize.ZoneSizingInput(2).DOASHighSetpoint = AutoSize
    AutoCalcDOASControlStrategy(state_ptr[])
    EXPECT_NEAR(24.0, state_ptr.dataSize.ZoneSizingInput(2).DOASHighSetpoint, 0.000001)
    EXPECT_DOUBLE_EQ(21.2, state_ptr.dataSize.ZoneSizingInput(2).DOASLowSetpoint)
    state_ptr.dataSize.ZoneSizingInput(2).DOASLowSetpoint = 21.5
    state_ptr.dataSize.ZoneSizingInput(2).DOASHighSetpoint = 22.6
    AutoCalcDOASControlStrategy(state_ptr[])
    EXPECT_DOUBLE_EQ(22.6, state_ptr.dataSize.ZoneSizingInput(2).DOASHighSetpoint)
    EXPECT_DOUBLE_EQ(21.5, state_ptr.dataSize.ZoneSizingInput(2).DOASLowSetpoint)
    state_ptr.dataSize.ZoneSizingInput(2).DOASControlStrategy = DataSizing.DOASControl.NeutralDehumSup
    state_ptr.dataSize.ZoneSizingInput(2).DOASLowSetpoint = AutoSize
    state_ptr.dataSize.ZoneSizingInput(2).DOASHighSetpoint = AutoSize
    AutoCalcDOASControlStrategy(state_ptr[])
    EXPECT_DOUBLE_EQ(14.4, state_ptr.dataSize.ZoneSizingInput(2).DOASLowSetpoint)
    EXPECT_DOUBLE_EQ(22.2, state_ptr.dataSize.ZoneSizingInput(2).DOASHighSetpoint)
    state_ptr.dataSize.ZoneSizingInput(2).DOASLowSetpoint = AutoSize
    state_ptr.dataSize.ZoneSizingInput(2).DOASHighSetpoint = 22.4
    AutoCalcDOASControlStrategy(state_ptr[])
    EXPECT_DOUBLE_EQ(14.4, state_ptr.dataSize.ZoneSizingInput(2).DOASLowSetpoint)
    EXPECT_DOUBLE_EQ(22.4, state_ptr.dataSize.ZoneSizingInput(2).DOASHighSetpoint)
    state_ptr.dataSize.ZoneSizingInput(2).DOASLowSetpoint = 13.8
    state_ptr.dataSize.ZoneSizingInput(2).DOASHighSetpoint = AutoSize
    AutoCalcDOASControlStrategy(state_ptr[])
    EXPECT_DOUBLE_EQ(22.2, state_ptr.dataSize.ZoneSizingInput(2).DOASHighSetpoint)
    EXPECT_DOUBLE_EQ(13.8, state_ptr.dataSize.ZoneSizingInput(2).DOASLowSetpoint)
    state_ptr.dataSize.ZoneSizingInput(2).DOASLowSetpoint = 13.9
    state_ptr.dataSize.ZoneSizingInput(2).DOASHighSetpoint = 22.6
    AutoCalcDOASControlStrategy(state_ptr[])
    EXPECT_DOUBLE_EQ(22.6, state_ptr.dataSize.ZoneSizingInput(2).DOASHighSetpoint)
    EXPECT_DOUBLE_EQ(13.9, state_ptr.dataSize.ZoneSizingInput(2).DOASLowSetpoint)
    state_ptr.dataSize.ZoneSizingInput(2).DOASControlStrategy = DataSizing.DOASControl.CoolSup
    state_ptr.dataSize.ZoneSizingInput(2).DOASLowSetpoint = AutoSize
    state_ptr.dataSize.ZoneSizingInput(2).DOASHighSetpoint = AutoSize
    AutoCalcDOASControlStrategy(state_ptr[])
    EXPECT_DOUBLE_EQ(12.2, state_ptr.dataSize.ZoneSizingInput(2).DOASLowSetpoint)
    EXPECT_DOUBLE_EQ(14.4, state_ptr.dataSize.ZoneSizingInput(2).DOASHighSetpoint)
    state_ptr.dataSize.ZoneSizingInput(2).DOASLowSetpoint = AutoSize
    state_ptr.dataSize.ZoneSizingInput(2).DOASHighSetpoint = 14.6
    AutoCalcDOASControlStrategy(state_ptr[])
    EXPECT_NEAR(12.4, state_ptr.dataSize.ZoneSizingInput(2).DOASLowSetpoint, 0.000001)
    EXPECT_DOUBLE_EQ(14.6, state_ptr.dataSize.ZoneSizingInput(2).DOASHighSetpoint)
    state_ptr.dataSize.ZoneSizingInput(2).DOASLowSetpoint = 12.3
    state_ptr.dataSize.ZoneSizingInput(2).DOASHighSetpoint = AutoSize
    AutoCalcDOASControlStrategy(state_ptr[])
    EXPECT_NEAR(14.5, state_ptr.dataSize.ZoneSizingInput(2).DOASHighSetpoint, 0.000001)
    EXPECT_DOUBLE_EQ(12.3, state_ptr.dataSize.ZoneSizingInput(2).DOASLowSetpoint)
    state_ptr.dataSize.ZoneSizingInput(2).DOASLowSetpoint = 12.6
    state_ptr.dataSize.ZoneSizingInput(2).DOASHighSetpoint = 13.8
    AutoCalcDOASControlStrategy(state_ptr[])
    EXPECT_DOUBLE_EQ(13.8, state_ptr.dataSize.ZoneSizingInput(2).DOASHighSetpoint)
    EXPECT_DOUBLE_EQ(12.6, state_ptr.dataSize.ZoneSizingInput(2).DOASLowSetpoint)
    state_ptr.dataSize.ZoneSizingInput.deallocate()