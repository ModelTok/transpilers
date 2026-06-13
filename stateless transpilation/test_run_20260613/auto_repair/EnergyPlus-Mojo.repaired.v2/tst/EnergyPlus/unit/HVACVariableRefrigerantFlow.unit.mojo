import unittest
from typing import List, Optional, Tuple, Dict
import math

# Import the necessary EnergyPlus modules (assumed to be available in Mojo)
# These would be custom modules that implement the equivalent C++ classes
from EnergyPlus import (
    EnergyPlusFixture,
    BranchInputManager,
    CurveManager,
    DXCoils,
    EnergyPlusData,
    DataAirLoop,
    DataAirSystems,
    DataEnvironment,
    DataErrorTracking,
    DataGlobalConstants,
    DataHVACGlobals,
    DataHeatBalFanSys,
    DataHeatBalance,
    DataLoopNode,
    DataSizing,
    DataZoneEnergyDemands,
    DataZoneEquipment,
    Fans,
    FluidProperties,
    GlobalNames,
    HVACVariableRefrigerantFlow,
    HeatBalanceManager,
    HeatingCoils,
    MixedAir,
    PlantDataPlant,
    PlantLocation,
    PlantManager,
    Psychrometrics,
    ReportCoilSelection,
    ScheduleManager,
    SimulationManager,
    SizingManager,
    SteamCoils,
    WaterCoils,
    ZoneTempPredictorCorrector,
    Constant,
    HVAC,
    StandardRatings,
    Avail,
    DataHeatBalance as DHB,
    DataSizing as DSizing,
    DataZoneEquipment as DZoneEquip,
    DataZoneEnergyDemands as DZEDemands,
    DXCoils as DXC,
    Fans as F,
    HeatBalanceManager as HBM,
    HVACVariableRefrigerantFlow as VRF,
    HeatingCoils as HC,
    GlobalNames as GN,
    PlantManager as PM,
    Psychrometrics as Psy,
    SimulationManager as SM,
    SizingManager as SzM,
    Curve,
    Sched,
    Fluid,
    DataPlant,
    DataLoopNode,
    DataAirLoop,
    DataHVACGlobals as HGlobals,
    DataHeatBalFanSys as HBFS,
    DataZoneEnergyDemands as DZED,
    DataZoneEquipment as DZE,
    DataHeatBalance as DH,
    DataSizing as DS,
    DataEnvironment as DE,
    DataPlant as DP,
    DataErrorTracking as DET,
    DataGlobalConstants as DGC,
    DataAirSystems as DAS,
    ReportCoilSelection as RCS,
    SteamCoils as SC,
    WaterCoils as WC,
)

# Helper functions (assumed to be defined in the imported modules)
# They are used in the tests
def delimited_string(lines: List[str]) -> str:
    return "\n".join(lines)

def process_idf(idf_string: str) -> bool:
    # Assume this function is imported from EnergyPlus
    return True

def has_err_output(expected: bool) -> bool:
    # Assume this function is imported
    return True

def compare_err_stream(expected: str, clear: bool) -> bool:
    return True

def compare_err_stream_substring(substring: str) -> bool:
    return True

# The test classes

class AirLoopFixture(EnergyPlusFixture):  # EnergyPlusFixture is a base class (like unittest.TestCase)
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.NumAirloops = 1
        self.NumZoneInletNodes = 1
        self.NumZoneExhaustNodes = 1
        self.ErrorsFound = False

    def setUp(self):
        # Call base fixture setUp first (assume it sets up state)
        super().setUp()
        # Initialize StdRhoAir and other environment variables
        self.state.dataEnvrn.StdRhoAir = Psy.PsyRhoAirFnPbTdbW(self.state, 101325.0, 20.0, 0.0)
        self.state.dataEnvrn.OutBaroPress = 101325.0
        self.state.dataSize.DesDayWeath.allocate(1)
        self.state.dataSize.DesDayWeath[0].Temp.allocate(1)
        self.state.dataSize.DesDayWeath[0].Temp[0] = 35.0
        self.state.dataGlobal.BeginEnvrnFlag = True
        self.state.dataEnvrn.OutDryBulbTemp = 35.0
        self.state.dataEnvrn.OutHumRat = 0.012
        self.state.dataEnvrn.OutWetBulbTemp = Psy.PsyTwbFnTdbWPb(
            self.state, self.state.dataEnvrn.OutDryBulbTemp, self.state.dataEnvrn.OutHumRat, DE.StdPressureSeaLevel
        )
        self.state.dataEnvrn.OutBaroPress = 101325  # sea level
        self.state.dataZoneEquip.ZoneEquipInputsFilled = True
        numZones = 5
        self.state.dataGlobal.NumOfZones = numZones
        numAirloops = 5
        self.state.dataLoopNodes.Node.allocate(50)
        self.state.dataLoopNodes.NodeID.allocate(50)
        self.state.dataHeatBalFanSys.TempControlType.allocate(numZones)
        self.state.dataHeatBalFanSys.TempControlType[0] = HVAC.SetptType.DualHeatCool
        self.state.dataHeatBal.Zone.allocate(numZones)
        self.state.dataZoneEquip.ZoneEquipConfig.allocate(numZones)
        self.state.dataZoneEquip.ZoneEquipList.allocate(numZones)
        self.state.dataZoneEquip.ZoneEquipAvail.dimension(numZones, Avail.Status.NoAction)
        self.state.dataZoneEquip.NumOfZoneEquipLists = numZones
        self.state.dataSize.FinalZoneSizing.allocate(numZones)
        self.state.dataSize.FinalSysSizing.allocate(numAirloops)
        self.state.dataSize.OASysEqSizing.allocate(numAirloops)
        self.state.dataSize.OASysEqSizing[0].SizingMethod.allocate(30)
        self.state.dataSize.ZoneEqSizing.allocate(numZones)
        self.state.dataSize.ZoneEqSizing[0].SizingMethod.allocate(30)
        self.state.dataSize.UnitarySysEqSizing.allocate(numZones)
        self.state.dataSize.UnitarySysEqSizing[0].SizingMethod.allocate(30)
        self.state.dataSize.ZoneHVACSizing.allocate(50)
        self.state.dataSize.ZoneHVACSizing[0].MaxCoolAirVolFlow = DSizing.AutoSize
        self.state.dataSize.ZoneHVACSizing[0].MaxHeatAirVolFlow = DSizing.AutoSize
        self.state.dataDXCoils.DXCoil.allocate(10)
        self.state.dataDXCoils.DXCoilOutletTemp.allocate(10)
        self.state.dataDXCoils.DXCoilOutletHumRat.allocate(10)
        self.state.dataDXCoils.DXCoilFullLoadOutAirTemp.allocate(10)
        self.state.dataDXCoils.DXCoilFullLoadOutAirHumRat.allocate(10)
        self.state.dataDXCoils.DXCoilPartLoadRatio.allocate(10)
        self.state.dataDXCoils.DXCoilFanOp.allocate(10)
        self.state.dataDXCoils.DXCoilTotalCooling.allocate(10)
        self.state.dataDXCoils.DXCoilCoolInletAirWBTemp.allocate(10)
        self.state.dataDXCoils.DXCoilTotalHeating.allocate(10)
        self.state.dataDXCoils.DXCoilHeatInletAirDBTemp.allocate(10)
        self.state.dataDXCoils.DXCoilHeatInletAirWBTemp.allocate(10)
        self.state.dataDXCoils.CheckEquipName.allocate(10)
        self.state.dataDXCoils.DXCoilNumericFields.allocate(10)
        self.state.dataHeatBal.HeatReclaimDXCoil.allocate(10)
        self.state.dataDXCoils.NumDXCoils = 10
        self.state.dataMixedAir.OAMixer.allocate(5)
        self.state.dataSize.NumSysSizInput = 1
        self.state.dataSize.SysSizInput.allocate(1)
        self.state.dataSize.SysSizInput[0].AirLoopNum = 1
        curve1 = Curve.AddCurve(self.state, "Curve1")
        curve1.curveType = CurveType.Linear
        curve1.numDims = 1
        curve1.coeff[0] = 1.0
        curve1.outputLimits.max = 1.0
        curve2 = Curve.AddCurve(self.state, "Curve2")
        curve2.curveType = CurveType.Linear
        curve2.numDims = 1
        curve2.coeff[0] = 1.0
        curve2.outputLimits.max = 1.0
        NumAirLoops = 1
        self.state.dataHVACGlobal.NumPrimaryAirSys = NumAirLoops
        self.state.dataAirSystemsData.PrimaryAirSystems.allocate(NumAirLoops)
        thisAirLoop = 1
        self.state.dataAirSystemsData.PrimaryAirSystems[thisAirLoop].Branch.allocate(1)
        self.state.dataAirLoop.AirLoopControlInfo.allocate(1)
        self.state.dataSize.SysSizPeakDDNum.allocate(1)
        self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand.allocate(numZones)
        self.state.dataZoneTempPredictorCorrector.zoneHeatBalance.allocate(numZones)
        self.state.dataSize.ZoneSizingRunDone = True
        self.state.dataSize.SysSizingRunDone = True
        zoneNum = 1
        zoneNode = 1
        zoneRetNode1 = 2
        zoneInletNode1 = 3
        zoneExhNode1 = 4
        self.state.dataSize.ZoneEqSizing[zoneNum].SizingMethod.allocate(25)
        self.state.dataSize.ZoneEqSizing[zoneNum].SizingMethod[HVAC.SystemAirflowSizing] = DSizing.SupplyAirFlowRate
        thisZoneEqConfig = self.state.dataZoneEquip.ZoneEquipConfig[zoneNum]
        thisZoneEqConfig.IsControlled = True
        thisZoneEqConfig.ZoneName = "ZONE1"
        thisZoneEqConfig.EquipListName = "ZONE1EQUIPMENT"
        thisZoneEqConfig.ZoneNode = zoneNode
        thisZoneEqConfig.NumReturnNodes = 1
        thisZoneEqConfig.ReturnNode.allocate(1)
        thisZoneEqConfig.ReturnNode[0] = zoneRetNode1
        thisZoneEqConfig.FixedReturnFlow.allocate(1)
        thisZoneEqConfig.NumInletNodes = self.NumZoneInletNodes
        thisZoneEqConfig.InletNode.allocate(self.NumZoneInletNodes)
        thisZoneEqConfig.AirDistUnitCool.allocate(self.NumZoneInletNodes)
        thisZoneEqConfig.AirDistUnitHeat.allocate(self.NumZoneInletNodes)
        thisZoneEqConfig.InletNode[0] = zoneInletNode1
        thisZoneEqConfig.NumExhaustNodes = self.NumZoneExhaustNodes
        thisZoneEqConfig.ExhaustNode.allocate(self.NumZoneExhaustNodes)
        thisZoneEqConfig.ExhaustNode[0] = zoneExhNode1
        thisZoneEqConfig.EquipListIndex = zoneNum
        thisZoneEqConfig.returnFlowFracSched = Sched.GetScheduleAlwaysOn(self.state)
        thisZone = self.state.dataHeatBal.Zone[zoneNum]
        thisZone.Name = "ZONE1"
        thisZone.IsControlled = True
        thisZone.SystemZoneNodeNumber = zoneNode
        thisZoneEqList = self.state.dataZoneEquip.ZoneEquipList[zoneNum]
        thisZoneEqList.Name = "ZONE1EQUIPMENT"
        maxEquipCount1 = 1
        thisZoneEqList.NumOfEquipTypes = maxEquipCount1
        thisZoneEqList.EquipTypeName.allocate(maxEquipCount1)
        thisZoneEqList.EquipType.allocate(maxEquipCount1)
        thisZoneEqList.EquipName.allocate(maxEquipCount1)
        thisZoneEqList.EquipIndex.allocate(maxEquipCount1)
        thisZoneEqList.EquipIndex = 1
        thisZoneEqList.EquipData.allocate(maxEquipCount1)
        thisZoneEqList.CoolingPriority.allocate(maxEquipCount1)
        thisZoneEqList.HeatingPriority.allocate(maxEquipCount1)
        thisZoneEqList.EquipTypeName[0] = "NOT A VRF TU"
        thisZoneEqList.EquipName[0] = "NO NAME"
        thisZoneEqList.CoolingPriority[0] = 1
        thisZoneEqList.HeatingPriority[0] = 1
        thisZoneEqList.EquipType[0] = DZoneEquip.ZoneEquipType.UnitarySystem
        finalZoneSizing = self.state.dataSize.FinalZoneSizing[zoneNum]
        finalZoneSizing.DesCoolVolFlow = 1.5
        finalZoneSizing.DesHeatVolFlow = 1.2
        finalZoneSizing.DesCoolCoilInTemp = 25.0
        finalZoneSizing.ZoneTempAtCoolPeak = 25.0
        finalZoneSizing.DesCoolCoilInHumRat = 0.009
        finalZoneSizing.ZoneHumRatAtCoolPeak = 0.009
        finalZoneSizing.CoolDesTemp = 15.0
        finalZoneSizing.CoolDesHumRat = 0.006
        finalZoneSizing.DesHeatCoilInTemp = 20.0
        finalZoneSizing.ZoneTempAtHeatPeak = 20.0
        finalZoneSizing.HeatDesTemp = 30.0
        finalZoneSizing.HeatDesHumRat = 0.007
        finalZoneSizing.DesHeatMassFlow = finalZoneSizing.DesHeatVolFlow * self.state.dataEnvrn.StdRhoAir
        finalZoneSizing.TimeStepNumAtCoolMax = 1
        finalZoneSizing.CoolDDNum = 1
        finalSysSizing = self.state.dataSize.FinalSysSizing[thisAirLoop]
        finalSysSizing.DesCoolVolFlow = 0.566337
        finalSysSizing.DesHeatVolFlow = 0.566337
        finalSysSizing.CoolSupTemp = 12.7
        finalSysSizing.CoolSupHumRat = 0.008
        finalSysSizing.HeatSupTemp = 35.0
        finalSysSizing.HeatSupHumRat = 0.006
        finalSysSizing.DesMainVolFlow = 0.566337
        finalSysSizing.OutTempAtCoolPeak = 35.0
        finalSysSizing.HeatOutTemp = 5.0
        finalSysSizing.HeatRetTemp = 21.0
        finalSysSizing.HeatMixTemp = 15.0
        finalSysSizing.MixTempAtCoolPeak = 26.0
        finalSysSizing.MixHumRatAtCoolPeak = 0.009
        self.state.dataAirSystemsData.PrimaryAirSystems[thisAirLoop].NumBranches = 1
        self.state.dataAirSystemsData.PrimaryAirSystems[thisAirLoop].NumInletBranches = 1
        self.state.dataAirSystemsData.PrimaryAirSystems[thisAirLoop].InletBranchNum[0] = 1
        self.state.dataAirSystemsData.PrimaryAirSystems[thisAirLoop].NumOutletBranches = 1
        self.state.dataAirSystemsData.PrimaryAirSystems[thisAirLoop].OutletBranchNum[0] = 1
        self.state.dataAirSystemsData.PrimaryAirSystems[thisAirLoop].Branch.allocate(1)
        self.state.dataAirSystemsData.PrimaryAirSystems[thisAirLoop].Branch[0].TotalComponents = 1
        self.state.dataAirSystemsData.PrimaryAirSystems[thisAirLoop].Branch[0].Comp.allocate(1)
        self.state.dataAirSystemsData.PrimaryAirSystems[thisAirLoop].Branch[0].Comp[0].Name = "VRFTU1"
        self.state.dataAirSystemsData.PrimaryAirSystems[thisAirLoop].Branch[0].Comp[0].TypeOf = "ZONEHVAC:TERMINALUNIT:VARIABLEREFRIGERANTFLOW"
        self.state.dataPlnt.TotNumLoops = 2
        self.state.dataPlnt.PlantLoop.allocate(self.state.dataPlnt.TotNumLoops)
        self.state.dataSize.PlantSizData.allocate(self.state.dataPlnt.TotNumLoops)
        self.state.dataSize.NumPltSizInput = 2
        for loopindex in range(1, self.state.dataPlnt.TotNumLoops + 1):
            loopside = self.state.dataPlnt.PlantLoop[loopindex].LoopSide[DP.LoopSideLocation.Demand]
            loopside.TotalBranches = 1
            loopside.Branch.allocate(1)
            loopsidebranch = loopside.Branch[0]
            loopsidebranch.TotalComponents = 2
            loopsidebranch.Comp.allocate(2)
        self.state.dataPlnt.PlantLoop[0].Name = "Hot Water Loop"
        self.state.dataPlnt.PlantLoop[0].FluidName = "WATER"
        self.state.dataPlnt.PlantLoop[0].glycol = Fluid.GetWater(self.state)
        self.state.dataPlnt.PlantLoop[1].Name = "Chilled Water Loop"
        self.state.dataPlnt.PlantLoop[1].FluidName = "WATER"
        self.state.dataPlnt.PlantLoop[1].glycol = Fluid.GetWater(self.state)
        self.state.dataSize.PlantSizData[0].PlantLoopName = "Hot Water Loop"
        self.state.dataSize.PlantSizData[0].ExitTemp = 80.0
        self.state.dataSize.PlantSizData[0].DeltaT = 10.0
        self.state.dataSize.PlantSizData[1].PlantLoopName = "Chilled Water Loop"
        self.state.dataSize.PlantSizData[1].ExitTemp = 6.0
        self.state.dataSize.PlantSizData[1].DeltaT = 5.0
        numVRFCond = 1
        self.state.dataHVACVarRefFlow.NumVRFCond = numVRFCond
        self.state.dataHVACVarRefFlow.VRF.allocate(numVRFCond)
        self.state.dataHVACVarRefFlow.CoolCombinationRatio.allocate(1)
        self.state.dataHVACVarRefFlow.HeatCombinationRatio.allocate(1)
        condNum = 1
        VRFCond = self.state.dataHVACVarRefFlow.VRF[condNum]
        condNodeNum = 1
        sched1 = Sched.AddScheduleConstant(self.state, "sch1")
        sched2 = Sched.AddScheduleConstant(self.state, "sch2")
        VRFCond.VRFSystemTypeNum = 1
        VRFCond.VRFAlgorithmType = AlgorithmType.SysCurve
        VRFCond.availSched = sched1
        VRFCond.CoolingCapacity = 10000.0
        VRFCond.CoolingCOP = 3.0
        VRFCond.CoolingCombinationRatio = 1.0
        VRFCond.HeatingCapacity = 10000.0
        VRFCond.HeatingCOP = 3.0
        VRFCond.CondenserNodeNum = condNodeNum
        VRFCond.ZoneTUListPtr = 1
        VRFCond.MaxOATCooling = 40.0
        VRFCond.MaxOATHeating = 30.0
        VRFCond.ThermostatPriority = ThermostatCtrlType.LoadPriority
        self.state.dataHVACVarRefFlow.MaxCoolingCapacity.allocate(1)
        self.state.dataHVACVarRefFlow.MaxCoolingCapacity[0] = 1.0E20
        self.state.dataHVACVarRefFlow.MaxHeatingCapacity.allocate(1)
        self.state.dataHVACVarRefFlow.MaxHeatingCapacity[0] = 1.0E20
        Sch1 = 1
        numTU = 1
        self.state.dataHVACVarRefFlow.VRFTUNumericFields.allocate(numTU)
        self.state.dataHVACVarRefFlow.VRFTUNumericFields[0].FieldNames.allocate(25)
        self.state.dataHVACVarRefFlow.VRFTUNumericFields[0].FieldNames = " "
        self.state.dataHVACVarRefFlow.NumVRFTU = numTU
        self.state.dataHVACVarRefFlow.VRFTU.allocate(numTU)
        self.state.dataHVACVarRefFlow.NumVRFTULists = numTU
        self.state.dataHVACVarRefFlow.TerminalUnitList.allocate(numTU)
        self.state.dataHVACVarRefFlow.CheckEquipName.allocate(numTU)
        self.state.dataHVACVarRefFlow.CheckEquipName = True
        thisTUList = 1
        terminalUnitList = self.state.dataHVACVarRefFlow.TerminalUnitList[thisTUList]
        terminalUnitList.NumTUInList = 1
        terminalUnitList.ZoneTUPtr.allocate(1)
        terminalUnitList.ZoneTUPtr[0] = 1
        terminalUnitList.TerminalUnitNotSizedYet.allocate(1)
        terminalUnitList.HRCoolRequest.allocate(1)
        terminalUnitList.HRHeatRequest.allocate(1)
        terminalUnitList.CoolingCoilPresent.allocate(1)
        terminalUnitList.CoolingCoilPresent = True
        terminalUnitList.HeatingCoilPresent.allocate(1)
        terminalUnitList.HeatingCoilPresent = True
        terminalUnitList.coolingCoilAvailScheds.allocate(1)
        terminalUnitList.coolingCoilAvailScheds[0] = sched1
        terminalUnitList.heatingCoilAvailScheds.allocate(1)
        terminalUnitList.heatingCoilAvailScheds[0] = sched1
        terminalUnitList.CoolingCoilAvailable.allocate(1)
        terminalUnitList.HeatingCoilAvailable.allocate(1)
        TUNum = 1
        VRFTU = self.state.dataHVACVarRefFlow.VRFTU[TUNum]
        coolCoilIndex = 1
        heatCoilIndex = 2
        VRFTUInletNodeNum = 30
        VRFTUOutletNodeNum = 31
        VRFTUOAMixerOANodeNum = 32
        VRFTUOAMixerRelNodeNum = 33
        VRFTUOAMixerRetNodeNum = VRFTUInletNodeNum
        VRFTUOAMixerMixNodeNum = 35
        coolCoilAirInNode = VRFTUOAMixerMixNodeNum
        coolCoilAirOutNode = 36
        heatCoilAirInNode = coolCoilAirOutNode
        heatCoilAirOutNode = VRFTUOutletNodeNum
        self.state.dataMixedAir.OAMixer[0].RetNode = VRFTUOAMixerRetNodeNum
        self.state.dataMixedAir.OAMixer[0].InletNode = VRFTUOAMixerOANodeNum
        self.state.dataMixedAir.OAMixer[0].RelNode = VRFTUOAMixerRelNodeNum
        self.state.dataMixedAir.OAMixer[0].MixNode = VRFTUOAMixerMixNodeNum
        VRFTU.Name = "VRFTU1"
        VRFTU.type = TUType.ConstantVolume
        VRFTU.availSched = sched1
        VRFTU.VRFSysNum = numVRFCond
        VRFTU.TUListIndex = TUNum
        VRFTU.IndexToTUInTUList = TUNum
        VRFTU.VRFTUInletNodeNum = VRFTUInletNodeNum
        VRFTU.VRFTUOutletNodeNum = VRFTUOutletNodeNum
        VRFTU.VRFTUOAMixerOANodeNum = VRFTUOAMixerOANodeNum
        VRFTU.VRFTUOAMixerRelNodeNum = VRFTUOAMixerRelNodeNum
        VRFTU.VRFTUOAMixerRetNodeNum = VRFTUOAMixerRetNodeNum
        VRFTU.VRFTUOAMixerMixedNodeNum = VRFTUOAMixerMixNodeNum
        VRFTU.MaxCoolAirVolFlow = DSizing.AutoSize
        VRFTU.MaxHeatAirVolFlow = DSizing.AutoSize
        VRFTU.MaxNoCoolAirVolFlow = DSizing.AutoSize
        VRFTU.MaxNoHeatAirVolFlow = DSizing.AutoSize
        VRFTU.MaxCoolAirMassFlow = DSizing.AutoSize
        VRFTU.MaxHeatAirMassFlow = DSizing.AutoSize
        VRFTU.MaxNoCoolAirMassFlow = DSizing.AutoSize
        VRFTU.MaxNoHeatAirMassFlow = DSizing.AutoSize
        VRFTU.CoolOutAirVolFlow = DSizing.AutoSize
        VRFTU.HeatOutAirVolFlow = DSizing.AutoSize
        VRFTU.NoCoolHeatOutAirVolFlow = DSizing.AutoSize
        VRFTU.MinOperatingPLR = 0.1
        VRFTU.fanType = HVAC.FanType.Invalid
        VRFTU.fanOpModeSched = sched2
        VRFTU.fanAvailSched = sched1
        VRFTU.FanIndex = 0
        VRFTU.fanPlace = HVAC.FanPlace.Invalid
        VRFTU.OAMixerName = "OAMixer1"
        VRFTU.OAMixerIndex = 1
        VRFTU.OAMixerUsed = True
        VRFTU.CoolCoilIndex = coolCoilIndex
        VRFTU.coolCoilAirInNode = coolCoilAirInNode
        VRFTU.coolCoilAirOutNode = coolCoilAirOutNode
        VRFTU.HeatCoilIndex = heatCoilIndex
        VRFTU.heatCoilAirInNode = heatCoilAirInNode
        VRFTU.heatCoilAirOutNode = heatCoilAirOutNode
        VRFTU.coolCoilType = HVAC.CoilType.CoolingVRF
        VRFTU.heatCoilType = HVAC.CoilType.HeatingVRF
        VRFTU.CoolingCoilPresent = True
        VRFTU.HeatingCoilPresent = True
        VRFTU.HVACSizingIndex = 0
        self.state.dataDXCoils.DXCoilNumericFields[0].PerfMode.allocate(5)
        self.state.dataDXCoils.DXCoilNumericFields[0].PerfMode[0].FieldNames.allocate(30)
        dxCoil1 = self.state.dataDXCoils.DXCoil[0]
        dxCoil1.Name = "VRFTUDXCOOLCOIL"
        dxCoil1.AirInNode = coolCoilAirInNode
        dxCoil1.AirOutNode = coolCoilAirOutNode
        dxCoil1.coilType = HVAC.CoilType.CoolingVRF
        dxCoil1.coilReportNum = RCS.getReportIndex(self.state, dxCoil1.Name, dxCoil1.coilType)
        dxCoil1.RatedAirVolFlowRate = DSizing.AutoSize
        dxCoil1.RatedTotCap = DSizing.AutoSize
        dxCoil1.RatedSHR = DSizing.AutoSize
        dxCoil1.availSched = sched1
        dxCoil1.CCapFTemp.allocate(1)
        dxCoil1.CCapFTemp[0] = Sch1
        dxCoil1.CCapFFlow.allocate(1)
        dxCoil1.CCapFFlow[0] = Sch1
        dxCoil1.PLFFPLR.allocate(1)
        dxCoil1.PLFFPLR[0] = Sch1
        self.state.dataDXCoils.DXCoilNumericFields[1].PerfMode.allocate(5)
        self.state.dataDXCoils.DXCoilNumericFields[1].PerfMode[0].FieldNames.allocate(30)
        dxCoil2 = self.state.dataDXCoils.DXCoil[1]
        dxCoil2.Name = "VRFTUDXHEATCOIL"
        dxCoil2.coilType = HVAC.CoilType.HeatingVRF
        dxCoil2.coilReportNum = RCS.getReportIndex(self.state, dxCoil2.Name, dxCoil2.coilType)
        dxCoil2.AirInNode = heatCoilAirInNode
        dxCoil2.AirOutNode = heatCoilAirOutNode
        dxCoil2.RatedAirVolFlowRate = DSizing.AutoSize
        dxCoil2.RatedTotCap = DSizing.AutoSize
        dxCoil2.RatedSHR = DSizing.AutoSize
        dxCoil2.availSched = sched1
        dxCoil2.CCapFTemp.allocate(1)
        dxCoil2.CCapFTemp[0] = Sch1
        dxCoil2.CCapFFlow.allocate(1)
        dxCoil2.CCapFFlow[0] = Sch1
        dxCoil2.PLFFPLR.allocate(1)
        dxCoil2.PLFFPLR[0] = Sch1

    def tearDown(self):
        super().tearDown()

    # Test methods are defined below...

    def test_VRF_SysModel_inAirloop(self):
        # (Copy the entire test function body here)

    # ... other tests

if __name__ == "__main__":
    unittest.main()