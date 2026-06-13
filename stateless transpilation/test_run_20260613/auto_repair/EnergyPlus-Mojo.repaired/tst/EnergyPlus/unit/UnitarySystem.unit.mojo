from Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.BranchInputManager import *
from EnergyPlus.Coils.CoilCoolingDX import *
from EnergyPlus.Coils.CoilCoolingDXCurveFitPerformance import *
from EnergyPlus.CurveManager import *
from EnergyPlus.DXCoils import *
from EnergyPlus.Data.EnergyPlusData import *
from EnergyPlus.DataAirLoop import *
from EnergyPlus.DataAirSystems import *
from EnergyPlus.DataBranchNodeConnections import *
from EnergyPlus.Material import *
from EnergyPlus.SimAirServingZones import *
from EnergyPlus.Data.CommonIncludes import *
from EnergyPlus.DataHVACGlobals import *
from EnergyPlus.DataHeatBalFanSys import *
from EnergyPlus.DataHeatBalance import *
from EnergyPlus.DataLoopNode import *
from EnergyPlus.DataSizing import *
from EnergyPlus.DataZoneControls import *
from EnergyPlus.DataZoneEnergyDemands import *
from EnergyPlus.DataZoneEquipment import *
from EnergyPlus.ElectricPowerServiceManager import *
from EnergyPlus.Fans import *
from EnergyPlus.FluidProperties import *
from EnergyPlus.General import *
from EnergyPlus.HeatBalanceInternalHeatGains import *
from EnergyPlus.HeatBalanceManager import *
from EnergyPlus.HeatingCoils import *
from EnergyPlus.IOFiles import *
from EnergyPlus.MixedAir import *
from EnergyPlus.OutputReportPredefined import *
from EnergyPlus.Plant.DataPlant import *
from EnergyPlus.Psychrometrics import *
from EnergyPlus.RefrigeratedCase import *
from EnergyPlus.ReportCoilSelection import *
from EnergyPlus.ScheduleManager import *
from EnergyPlus.SimAirServingZones import *
from EnergyPlus.SimulationManager import *
from EnergyPlus.SingleDuct import *
from EnergyPlus.SizingManager import *
from EnergyPlus.SurfaceGeometry import *
from EnergyPlus.UnitarySystem import *
from EnergyPlus.UtilityRoutines import *
from EnergyPlus.VariableSpeedCoils import *
from EnergyPlus.WaterCoils import *
from EnergyPlus.WaterToAirHeatPumpSimple import *
from EnergyPlus.ZoneAirLoopEquipmentManager import *
from EnergyPlus.ZoneEquipmentManager import *
from EnergyPlus.ZoneTempPredictorCorrector import *

using EnergyPlus
using UnitarySystems

class ZoneUnitarySysTest(EnergyPlusFixture):
    var UnitarySysNum: Int = 1
    var NumNodes: Int = 1
    var ErrorsFound: Bool = False

    def SetUp() raises:
        EnergyPlusFixture.SetUp()
        state.dataEnvrn.StdRhoAir = Psychrometrics.PsyRhoAirFnPbTdbW(state, 101325.0, 20.0, 0.0)
        state.dataEnvrn.OutBaroPress = 101325.0
        state.dataGlobal.NumOfZones = 1
        state.dataHeatBal.Zone.allocate(state.dataGlobal.NumOfZones)
        state.dataZoneEquip.ZoneEquipConfig.allocate(state.dataGlobal.NumOfZones)
        state.dataZoneEquip.ZoneEquipList.allocate(state.dataGlobal.NumOfZones)
        state.dataZoneEquip.ZoneEquipAvail.dimension(state.dataGlobal.NumOfZones, Avail.Status.NoAction)
        state.dataHeatBal.Zone(1).Name = "EAST ZONE"
        state.dataZoneEquip.NumOfZoneEquipLists = 1
        state.dataHeatBal.Zone(1).IsControlled = True
        state.dataZoneEquip.ZoneEquipConfig(1).IsControlled = True
        state.dataZoneEquip.ZoneEquipConfig(1).ZoneName = "EAST ZONE"
        state.dataZoneEquip.ZoneEquipConfig(1).EquipListName = "ZONE2EQUIPMENT"
        state.dataZoneEquip.ZoneEquipConfig(1).ZoneNode = 1
        state.dataZoneEquip.ZoneEquipConfig(1).NumReturnNodes = 1
        state.dataZoneEquip.ZoneEquipConfig(1).ReturnNode.allocate(1)
        state.dataZoneEquip.ZoneEquipConfig(1).ReturnNode(1) = 21
        state.dataZoneEquip.ZoneEquipConfig(1).FixedReturnFlow.allocate(1)
        state.dataHeatBal.Zone(1).SystemZoneNodeNumber = state.dataZoneEquip.ZoneEquipConfig(1).ZoneNode
        state.dataZoneEquip.ZoneEquipConfig(1).returnFlowFracSched = Sched.GetScheduleAlwaysOn(state)
        state.dataZoneEquip.ZoneEquipList(1).Name = "ZONE2EQUIPMENT"
        var maxEquipCount: Int = 1
        state.dataZoneEquip.ZoneEquipList(1).NumOfEquipTypes = maxEquipCount
        state.dataZoneEquip.ZoneEquipList(1).EquipTypeName.allocate(state.dataZoneEquip.ZoneEquipList(1).NumOfEquipTypes)
        state.dataZoneEquip.ZoneEquipList(1).EquipType.allocate(state.dataZoneEquip.ZoneEquipList(1).NumOfEquipTypes)
        state.dataZoneEquip.ZoneEquipList(1).EquipName.allocate(state.dataZoneEquip.ZoneEquipList(1).NumOfEquipTypes)
        state.dataZoneEquip.ZoneEquipList(1).EquipIndex.allocate(state.dataZoneEquip.ZoneEquipList(1).NumOfEquipTypes)
        state.dataZoneEquip.ZoneEquipList(1).EquipIndex = 1
        state.dataZoneEquip.ZoneEquipList(1).EquipData.allocate(state.dataZoneEquip.ZoneEquipList(1).NumOfEquipTypes)
        state.dataZoneEquip.ZoneEquipList(1).CoolingPriority.allocate(state.dataZoneEquip.ZoneEquipList(1).NumOfEquipTypes)
        state.dataZoneEquip.ZoneEquipList(1).HeatingPriority.allocate(state.dataZoneEquip.ZoneEquipList(1).NumOfEquipTypes)
        state.dataZoneEquip.ZoneEquipList(1).EquipTypeName(1) = "AIRLOOPHVAC:UNITARYSYSTEM"
        state.dataZoneEquip.ZoneEquipList(1).EquipName(1) = "UNITARY SYSTEM MODEL"
        state.dataZoneEquip.ZoneEquipList(1).CoolingPriority(1) = 1
        state.dataZoneEquip.ZoneEquipList(1).HeatingPriority(1) = 1
        state.dataZoneEquip.ZoneEquipList(1).EquipType(1) = DataZoneEquipment.ZoneEquipType.UnitarySystem
        state.dataZoneEquip.ZoneEquipConfig(1).NumInletNodes = NumNodes
        state.dataZoneEquip.ZoneEquipConfig(1).InletNode.allocate(NumNodes)
        state.dataZoneEquip.ZoneEquipConfig(1).AirDistUnitCool.allocate(NumNodes)
        state.dataZoneEquip.ZoneEquipConfig(1).AirDistUnitHeat.allocate(NumNodes)
        state.dataZoneEquip.ZoneEquipConfig(1).InletNode(1) = 2
        state.dataZoneEquip.ZoneEquipConfig(1).NumExhaustNodes = NumNodes
        state.dataZoneEquip.ZoneEquipConfig(1).ExhaustNode.allocate(NumNodes)
        state.dataZoneEquip.ZoneEquipConfig(1).ExhaustNode(1) = 1
        state.dataZoneEquip.ZoneEquipConfig(1).EquipListIndex = 1
        state.dataSize.CurSysNum = 0
        state.dataSize.CurZoneEqNum = 1
        state.dataSize.FinalZoneSizing.allocate(1)
        state.dataSize.FinalZoneSizing(state.dataSize.CurZoneEqNum).DesCoolVolFlow = 1.5
        state.dataSize.FinalZoneSizing(state.dataSize.CurZoneEqNum).DesHeatVolFlow = 1.2
        state.dataSize.FinalZoneSizing(state.dataSize.CurZoneEqNum).DesCoolCoilInTemp = 25.0
        state.dataSize.FinalZoneSizing(state.dataSize.CurZoneEqNum).ZoneTempAtCoolPeak = 25.0
        state.dataSize.FinalZoneSizing(state.dataSize.CurZoneEqNum).ZoneRetTempAtCoolPeak = 25.0
        state.dataSize.FinalZoneSizing(state.dataSize.CurZoneEqNum).DesCoolCoilInHumRat = 0.009
        state.dataSize.FinalZoneSizing(state.dataSize.CurZoneEqNum).ZoneHumRatAtCoolPeak = 0.009
        state.dataSize.FinalZoneSizing(state.dataSize.CurZoneEqNum).CoolDesTemp = 15.0
        state.dataSize.FinalZoneSizing(state.dataSize.CurZoneEqNum).CoolDesHumRat = 0.006
        state.dataSize.FinalZoneSizing(state.dataSize.CurZoneEqNum).DesHeatCoilInTemp = 20.0
        state.dataSize.FinalZoneSizing(state.dataSize.CurZoneEqNum).ZoneTempAtHeatPeak = 20.0
        state.dataSize.FinalZoneSizing(state.dataSize.CurZoneEqNum).HeatDesTemp = 30.0
        state.dataSize.FinalZoneSizing(state.dataSize.CurZoneEqNum).HeatDesHumRat = 0.007
        state.dataSize.FinalZoneSizing(state.dataSize.CurZoneEqNum).DesHeatMassFlow = state.dataSize.FinalZoneSizing(state.dataSize.CurZoneEqNum).DesHeatVolFlow * state.dataEnvrn.StdRhoAir
        state.dataSize.FinalZoneSizing(state.dataSize.CurZoneEqNum).TimeStepNumAtCoolMax = 1
        state.dataSize.FinalZoneSizing(state.dataSize.CurZoneEqNum).CoolDDNum = 1
        state.dataSize.FinalZoneSizing(state.dataSize.CurZoneEqNum).heatCoilSizingMethod = DataSizing.HeatCoilSizMethod.None
        state.dataSize.DesDayWeath.allocate(1)
        state.dataSize.DesDayWeath(1).Temp.allocate(1)
        state.dataSize.DesDayWeath(1).Temp(1) = 35.0
        state.dataSize.ZoneEqSizing.allocate(1)
        state.dataSize.ZoneEqSizing(state.dataSize.CurZoneEqNum).SizingMethod.allocate(25)
        state.dataSize.ZoneEqSizing(state.dataSize.CurZoneEqNum).SizingMethod = 0
        state.dataSize.ZoneSizingRunDone = True
        state.dataPlnt.TotNumLoops = 2
        state.dataPlnt.PlantLoop.allocate(state.dataPlnt.TotNumLoops)
        state.dataSize.PlantSizData.allocate(state.dataPlnt.TotNumLoops)
        state.dataSize.NumPltSizInput = 2
        for loopindex in range(1, state.dataPlnt.TotNumLoops + 1):
            var loopside = state.dataPlnt.PlantLoop(loopindex).LoopSide(DataPlant.LoopSideLocation.Demand)
            loopside.TotalBranches = 1
            loopside.Branch.allocate(1)
            var loopsidebranch = state.dataPlnt.PlantLoop(loopindex).LoopSide(DataPlant.LoopSideLocation.Demand).Branch(1)
            loopsidebranch.TotalComponents = 2
            loopsidebranch.Comp.allocate(2)
        state.dataFluid.init_state(state)
        state.dataPlnt.PlantLoop(1).Name = "Hot Water Loop"
        state.dataPlnt.PlantLoop(1).FluidName = "WATER"
        state.dataPlnt.PlantLoop(1).glycol = Fluid.GetWater(state)
        state.dataPlnt.PlantLoop(2).Name = "Chilled Water Loop"
        state.dataPlnt.PlantLoop(2).FluidName = "WATER"
        state.dataPlnt.PlantLoop(2).glycol = Fluid.GetWater(state)
        state.dataSize.PlantSizData(1).PlantLoopName = "Hot Water Loop"
        state.dataSize.PlantSizData(1).ExitTemp = 80.0
        state.dataSize.PlantSizData(1).DeltaT = 10.0
        state.dataSize.PlantSizData(2).PlantLoopName = "Chilled Water Loop"
        state.dataSize.PlantSizData(2).ExitTemp = 6.0
        state.dataSize.PlantSizData(2).DeltaT = 5.0

    def TearDown() raises:
        EnergyPlusFixture.TearDown()

class AirloopUnitarySysTest(EnergyPlusFixture):
    @staticmethod
    def TearDownTestCase():

    def SetUp() raises:
        EnergyPlusFixture.SetUp()
        state.dataSize.CurZoneEqNum = 0
        state.dataSize.CurSysNum = 0
        state.dataSize.CurOASysNum = 0
        state.dataWaterCoils.NumWaterCoils = 2
        state.dataWaterCoils.WaterCoil.allocate(state.dataWaterCoils.NumWaterCoils)
        state.dataWaterCoils.WaterCoilNumericFields.allocate(state.dataWaterCoils.NumWaterCoils)
        for i in range(1, state.dataWaterCoils.NumWaterCoils + 1):
            state.dataWaterCoils.WaterCoilNumericFields(i).FieldNames.allocate(17)
        state.dataPlnt.TotNumLoops = 2
        state.dataPlnt.PlantLoop.allocate(state.dataPlnt.TotNumLoops)
        state.dataSize.PlantSizData.allocate(2)
        state.dataSize.PlantSizData(1).DeltaT = 5.0
        state.dataSize.PlantSizData(2).DeltaT = 5.0
        state.dataSize.PlantSizData(1).ExitTemp = 7.0
        state.dataSize.PlantSizData(2).ExitTemp = 7.0
        state.dataSize.ZoneEqSizing.allocate(2)
        state.dataSize.UnitarySysEqSizing.allocate(2)
        state.dataSize.OASysEqSizing.allocate(2)
        state.dataSize.SysSizInput.allocate(1)
        state.dataSize.ZoneSizingInput.allocate(1)
        state.dataSize.SysSizPeakDDNum.allocate(1)
        state.dataSize.SysSizPeakDDNum(1).TimeStepAtSensCoolPk.allocate(1)
        state.dataSize.SysSizPeakDDNum(1).TimeStepAtCoolFlowPk.allocate(1)
        state.dataSize.SysSizPeakDDNum(1).TimeStepAtTotCoolPk.allocate(1)
        state.dataSize.SysSizPeakDDNum(1).SensCoolPeakDD = 1
        state.dataSize.SysSizPeakDDNum(1).CoolFlowPeakDD = 1
        state.dataSize.SysSizPeakDDNum(1).TotCoolPeakDD = 1
        state.dataSize.FinalSysSizing.allocate(1)
        state.dataSize.FinalSysSizing(1).heatCoilSizingMethod = DataSizing.HeatCoilSizMethod.None
        state.dataSize.CalcSysSizing.allocate(1)
        state.dataSize.FinalZoneSizing.allocate(1)
        state.dataSize.FinalZoneSizing(1).heatCoilSizingMethod = DataSizing.HeatCoilSizMethod.None
        state.dataHVACGlobal.NumPrimaryAirSys = 1
        state.dataAirSystemsData.PrimaryAirSystems.allocate(1)
        state.dataAirLoop.AirLoopControlInfo.allocate(1)
        state.dataLoopNodes.Node.allocate(30)
        state.dataHeatBal.HeatReclaimVS_Coil.allocate(4)

    def TearDown() raises:
        EnergyPlusFixture.TearDown()

def TEST_F_AirloopUnitarySysTest_MultipleWaterCoolingCoilSizing() raises:
    state.init_state(state)
    state.dataEnvrn.OutBaroPress = 101325.0
    state.dataEnvrn.StdRhoAir = Psychrometrics.PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress, 20.0, 0.0)
    state.dataSize.SysSizingRunDone = True
    state.dataSize.NumPltSizInput = 2
    state.dataSize.PlantSizData(1).PlantLoopName = "ColdWaterLoop"
    state.dataSize.PlantSizData(2).PlantLoopName = "HotWaterLoop"
    state.dataSize.CurDuctType = HVAC.AirDuctType.Main
    for l in range(1, state.dataPlnt.TotNumLoops + 1):
        var loopside = state.dataPlnt.PlantLoop(l).LoopSide(DataPlant.LoopSideLocation.Demand)
        loopside.TotalBranches = 1
        loopside.Branch.allocate(1)
        var loopsidebranch = state.dataPlnt.PlantLoop(l).LoopSide(DataPlant.LoopSideLocation.Demand).Branch(1)
        loopsidebranch.TotalComponents = 1
        loopsidebranch.Comp.allocate(1)
    state.dataPlnt.PlantLoop(1).Name = "ColdWaterLoop"
    state.dataPlnt.PlantLoop(1).FluidName = "WATER"
    state.dataPlnt.PlantLoop(1).glycol = Fluid.GetWater(state)
    state.dataPlnt.PlantLoop(2).Name = "HotWaterLoop"
    state.dataPlnt.PlantLoop(2).FluidName = "WATER"
    state.dataPlnt.PlantLoop(2).glycol = Fluid.GetWater(state)
    state.dataSize.FinalSysSizing(1).MixTempAtCoolPeak = 20.0
    state.dataSize.FinalSysSizing(1).CoolSupTemp = 10.0
    state.dataSize.FinalSysSizing(1).MixHumRatAtCoolPeak = 0.01
    state.dataSize.FinalSysSizing(1).DesMainVolFlow = 0.159
    state.dataSize.FinalSysSizing(1).DesCoolVolFlow = 0.159
    state.dataSize.FinalSysSizing(1).DesHeatVolFlow = 0.159
    state.dataSize.FinalSysSizing(1).HeatSupTemp = 25.0
    state.dataSize.FinalSysSizing(1).HeatOutTemp = 5.0
    state.dataSize.FinalSysSizing(1).HeatRetTemp = 20.0
    var CoilNum: Int = 1
    state.dataWaterCoils.WaterCoil(CoilNum).Name = "Test Water Cooling Coil"
    state.dataWaterCoils.WaterCoil(CoilNum).WaterPlantLoc = {1, DataPlant.LoopSideLocation.Demand, 1, 1}
    PlantUtilities.SetPlantLocationLinks(state, state.dataWaterCoils.WaterCoil(CoilNum).WaterPlantLoc)
    state.dataWaterCoils.WaterCoil(CoilNum).WaterCoilType = DataPlant.PlantEquipmentType.CoilWaterCooling
    state.dataWaterCoils.WaterCoil(CoilNum).RequestingAutoSize = True
    state.dataWaterCoils.WaterCoil(CoilNum).DesAirVolFlowRate = DataSizing.AutoSize
    state.dataWaterCoils.WaterCoil(CoilNum).DesInletAirTemp = DataSizing.AutoSize
    state.dataWaterCoils.WaterCoil(CoilNum).DesOutletAirTemp = DataSizing.AutoSize
    state.dataWaterCoils.WaterCoil(CoilNum).DesInletWaterTemp = DataSizing.AutoSize
    state.dataWaterCoils.WaterCoil(CoilNum).DesInletAirHumRat = DataSizing.AutoSize
    state.dataWaterCoils.WaterCoil(CoilNum).DesOutletAirHumRat = DataSizing.AutoSize
    state.dataWaterCoils.WaterCoil(CoilNum).MaxWaterVolFlowRate = DataSizing.AutoSize
    state.dataWaterCoils.WaterCoilNumericFields(CoilNum).FieldNames(3) = "Maximum Flow Rate"
    state.dataWaterCoils.WaterCoil(CoilNum).WaterInletNodeNum = 1
    state.dataWaterCoils.WaterCoil(CoilNum).WaterOutletNodeNum = 2
    state.dataWaterCoils.WaterCoil(CoilNum).AirInletNodeNum = 3
    state.dataWaterCoils.WaterCoil(CoilNum).AirOutletNodeNum = 4
    state.dataWaterCoils.WaterCoil(CoilNum).availSched = Sched.GetScheduleAlwaysOff(state)
    state.dataPlnt.PlantLoop(1).LoopSide(DataPlant.LoopSideLocation.Demand).Branch(1).Comp(1).NodeNumIn = state.dataWaterCoils.WaterCoil(CoilNum).WaterInletNodeNum
    state.dataSize.CurZoneEqNum = 0
    state.dataSize.CurSysNum = 1
    state.dataSize.CurOASysNum = 0
    state.dataSize.FinalSysSizing(1).SysAirMinFlowRat = 0.3
    var heatFlowRat: Float64 = 0.3
    state.dataSize.SysSizInput(1).CoolCapControl = DataSizing.CapacityControl.VAV
    state.dataSize.PlantSizData(1).ExitTemp = 5.7
    state.dataSize.PlantSizData(1).DeltaT = 5.0
    state.dataSize.FinalSysSizing(1).MassFlowAtCoolPeak = state.dataSize.FinalSysSizing(1).DesMainVolFlow * state.dataEnvrn.StdRhoAir
    state.dataPlnt.PlantLoop(1).LoopSide(DataPlant.LoopSideLocation.Demand).Branch(1).Comp(1).Type = state.dataWaterCoils.WaterCoil(CoilNum).WaterCoilType
    state.dataPlnt.PlantLoop(1).LoopSide(DataPlant.LoopSideLocation.Demand).Branch(1).Comp(1).Name = state.dataWaterCoils.WaterCoil(CoilNum).Name
    state.dataSize.DataWaterLoopNum = 1
    WaterCoils.SizeWaterCoil(state, CoilNum)
    assert state.dataWaterCoils.WaterCoil(CoilNum).DesAirVolFlowRate == 0.159
    assert abs(state.dataWaterCoils.WaterCoil(CoilNum).DesWaterCoolingCoilRate - 6779.0) <= 1.0
    assert state.dataWaterCoils.WaterCoil(CoilNum).DesInletAirTemp == 20.0
    var coil1CoolingCoilRate: Float64 = state.dataWaterCoils.WaterCoil(CoilNum).DesWaterCoolingCoilRate
    var coil1CoolingAirFlowRate: Float64 = state.dataWaterCoils.WaterCoil(CoilNum).DesAirVolFlowRate
    state.dataWaterCoils.WaterCoil(CoilNum).DesAirVolFlowRate = DataSizing.AutoSize
    state.dataWaterCoils.WaterCoil(CoilNum).DesInletAirTemp = DataSizing.AutoSize
    state.dataWaterCoils.WaterCoil(CoilNum).DesOutletAirTemp = DataSizing.AutoSize
    state.dataWaterCoils.WaterCoil(CoilNum).DesInletWaterTemp = DataSizing.AutoSize
    state.dataWaterCoils.WaterCoil(CoilNum).DesInletAirHumRat = DataSizing.AutoSize
    state.dataWaterCoils.WaterCoil(CoilNum).DesOutletAirHumRat = DataSizing.AutoSize
    state.dataWaterCoils.WaterCoil(CoilNum).MaxWaterVolFlowRate = DataSizing.AutoSize
    CoilNum = 2
    state.dataSize.FinalSysSizing(1).MassFlowAtCoolPeak = state.dataSize.FinalSysSizing(1).DesMainVolFlow * state.dataEnvrn.StdRhoAir
    state.dataAirLoop.AirLoopControlInfo(1).UnitarySys = True
    state.dataWaterCoils.WaterCoil(CoilNum).WaterInletNodeNum = 5
    state.dataWaterCoils.WaterCoil(CoilNum).WaterOutletNodeNum = 6
    state.dataWaterCoils.WaterCoil(CoilNum).AirInletNodeNum = 7
    state.dataWaterCoils.WaterCoil(CoilNum).AirOutletNodeNum = 8
    state.dataWaterCoils.WaterCoil(CoilNum).Name = "Test Water Heating Coil"
    state.dataWaterCoils.WaterCoil(CoilNum).WaterPlantLoc = {2, DataPlant.LoopSideLocation.Demand, 1, 1}
    PlantUtilities.SetPlantLocationLinks(state, state.dataWaterCoils.WaterCoil(CoilNum).WaterPlantLoc)
    state.dataWaterCoils.WaterCoil(CoilNum).WaterCoilType = DataPlant.PlantEquipmentType.CoilWaterSimpleHeating
    state.dataWaterCoils.WaterCoil(CoilNum).RequestingAutoSize = True
    state.dataWaterCoils.WaterCoil(CoilNum).DesAirVolFlowRate = DataSizing.AutoSize
    state.dataWaterCoils.WaterCoil(CoilNum).DesInletAirTemp = DataSizing.AutoSize
    state.dataWaterCoils.WaterCoil(CoilNum).DesOutletAirTemp = DataSizing.AutoSize
    state.dataWaterCoils.WaterCoil(CoilNum).DesInletWaterTemp = DataSizing.AutoSize
    state.dataWaterCoils.WaterCoil(CoilNum).DesInletAirHumRat = DataSizing.AutoSize
    state.dataWaterCoils.WaterCoil(CoilNum).DesOutletAirHumRat = DataSizing.AutoSize
    state.dataWaterCoils.WaterCoil(CoilNum).MaxWaterVolFlowRate = DataSizing.AutoSize
    state.dataPlnt.PlantLoop(2).LoopSide(DataPlant.LoopSideLocation.Demand).Branch(1).Comp(1).NodeNumIn = state.dataWaterCoils.WaterCoil(CoilNum).WaterInletNodeNum
    state.dataPlnt.PlantLoop(2).LoopSide(DataPlant.LoopSideLocation.Demand).Branch(1).Comp(1).Type = state.dataWaterCoils.WaterCoil(CoilNum).WaterCoilType
    state.dataPlnt.PlantLoop(2).LoopSide(DataPlant.LoopSideLocation.Demand).Branch(1).Comp(1).Name = state.dataWaterCoils.WaterCoil(CoilNum).Name
    state.dataSize.DataWaterLoopNum = 2
    state.dataSize.PlantSizData(2).DeltaT = 5.0
    WaterCoils.SizeWaterCoil(state, CoilNum)
    assert abs(state.dataWaterCoils.WaterCoil(CoilNum).DesAirVolFlowRate - (0.159 * heatFlowRat)) <= 0.00001
    assert abs(state.dataWaterCoils.WaterCoil(CoilNum).DesWaterHeatingCoilRate - 1154.0) <= 1.0
    var coil2HeatingCoilRate: Float64 = state.dataWaterCoils.WaterCoil(CoilNum).DesWaterHeatingCoilRate
    state.dataWaterCoils.WaterCoil(CoilNum).DesAirVolFlowRate = DataSizing.AutoSize
    state.dataWaterCoils.WaterCoil(CoilNum).DesInletAirTemp = DataSizing.AutoSize
    state.dataWaterCoils.WaterCoil(CoilNum).DesOutletAirTemp = DataSizing.AutoSize
    state.dataWaterCoils.WaterCoil(CoilNum).DesInletWaterTemp = DataSizing.AutoSize
    state.dataWaterCoils.WaterCoil(CoilNum).DesInletAirHumRat = DataSizing.AutoSize
    state.dataWaterCoils.WaterCoil(CoilNum).DesOutletAirHumRat = DataSizing.AutoSize
    state.dataWaterCoils.WaterCoil(CoilNum).MaxWaterVolFlowRate = DataSizing.AutoSize
    CoilNum = 1
    var fan1 = Fans.FanComponent()
    fan1.Name = "FAN1"
    fan1.type = HVAC.FanType.Constant
    fan1.deltaPress = 600.0
    fan1.totalEff = 0.9
    fan1.motorEff = 0.7
    fan1.motorInAirFrac = 1.0
    state.dataFans.fans.push_back(fan1)
    state.dataFans.fanMap.insert_or_assign(fan1.Name, state.dataFans.fans.size())
    state.dataAirSystemsData.PrimaryAirSystems(1).supFanType = HVAC.FanType.Constant
    state.dataAirSystemsData.PrimaryAirSystems(1).supFanNum = Fans.GetFanIndex(state, "FAN1")
    state.dataAirSystemsData.PrimaryAirSystems(1).supFanPlace = HVAC.FanPlace.BlowThru
    var FanCoolLoad: Float64 = fan1.getDesignHeatGain(state, coil1CoolingAirFlowRate)
    WaterCoils.SizeWaterCoil(state, CoilNum)
    assert abs(FanCoolLoad - 106.0) <= 1.0
    assert abs(6779.4 + FanCoolLoad - state.dataWaterCoils.WaterCoil(CoilNum).DesWaterCoolingCoilRate) <= 1.0
    assert abs(state.dataWaterCoils.WaterCoil(CoilNum).DesInletAirTemp - 20.541) <= 0.001
    state.dataWaterCoils.WaterCoil(CoilNum).DesAirVolFlowRate = DataSizing.AutoSize
    state.dataWaterCoils.WaterCoil(CoilNum).DesInletAirTemp = DataSizing.AutoSize
    state.dataWaterCoils.WaterCoil(CoilNum).DesOutletAirTemp = DataSizing.AutoSize
    state.dataWaterCoils.WaterCoil(CoilNum).DesInletWaterTemp = DataSizing.AutoSize
    state.dataWaterCoils.WaterCoil(CoilNum).DesInletAirHumRat = DataSizing.AutoSize
    state.dataWaterCoils.WaterCoil(CoilNum).DesOutletAirHumRat = DataSizing.AutoSize
    state.dataWaterCoils.WaterCoil(CoilNum).MaxWaterVolFlowRate = DataSizing.AutoSize
    state.dataAirSystemsData.PrimaryAirSystems(1).supFanType = HVAC.FanType.Invalid
    state.dataAirSystemsData.PrimaryAirSystems(1).supFanPlace = HVAC.FanPlace.Invalid
    var AirLoopNum: Int = 1
    var FirstHVACIteration: Bool = True
    var thisSys: UnitarySys = UnitarySys()
    var mySys: UnitarySys = thisSys
    mySys.UnitType = "AirLoopHVAC:UnitarySystem"
    mySys.m_sysType = UnitarySys.SysType.Unitary
    mySys.m_CoolCoilExists = True
    mySys.m_HeatCoilExists = True
    mySys.m_MaxCoolAirVolFlow = DataSizing.AutoSize
    mySys.m_MaxHeatAirVolFlow = DataSizing.AutoSize
    mySys.m_CoolingSAFMethod = DataSizing.SupplyAirFlowRate
    mySys.m_HeatingSAFMethod = DataSizing.SupplyAirFlowRate
    mySys.m_DesignCoolingCapacity = DataSizing.AutoSize
    mySys.m_DesignHeatingCapacity = DataSizing.AutoSize
    mySys.m_coolCoilType = HVAC.CoilType.CoolingWater
    mySys.m_CoolingCoilName = "Test Water Cooling Coil"
    mySys.m_heatCoilType = HVAC.CoilType.HeatingWater
    mySys.m_HeatingCoilName = "Test Water Heating Coil"
    state.dataWaterCoils.GetWaterCoilsInputFlag = False
    state.dataWaterCoils.MySizeFlag = True
    state.dataWaterCoils.WaterCoil(1).DesWaterCoolingCoilRate = 0.0
    state.dataWaterCoils.WaterCoil(2).DesWaterHeatingCoilRate = 0.0
    state.dataGlobal.DoingSizing = True
    mySys.sizeSystem(state, FirstHVACIteration, AirLoopNum)
    assert abs(state.dataWaterCoils.WaterCoil(1).DesWaterCoolingCoilRate - 6779.4) <= 1.0
    assert state.dataWaterCoils.WaterCoil(CoilNum).DesInletAirTemp == 20.0
    assert abs(state.dataWaterCoils.WaterCoil(2).DesWaterHeatingCoilRate - 3848.0) <= 1.0
    assert coil2HeatingCoilRate < 3838.0
    assert abs(state.dataWaterCoils.WaterCoil(CoilNum).DesAirVolFlowRate - 0.159) <= 0.00001
    assert abs(coil1CoolingCoilRate - state.dataWaterCoils.WaterCoil(1).DesWaterCoolingCoilRate) <= 1.0
    assert abs(coil1CoolingCoilRate - mySys.m_DesignCoolingCapacity) <= 1.0
    assert coil2HeatingCoilRate < state.dataWaterCoils.WaterCoil(2).DesWaterHeatingCoilRate
    assert coil2HeatingCoilRate < mySys.m_DesignHeatingCapacity
    mySys.m_FanExists = True
    mySys.m_FanIndex = Fans.GetFanIndex(state, "FAN1")
    mySys.m_FanType = HVAC.FanType.Constant
    mySys.m_FanPlace = HVAC.FanPlace.BlowThru
    mySys.m_MaxCoolAirVolFlow = DataSizing.AutoSize
    mySys.m_MaxHeatAirVolFlow = DataSizing.AutoSize
    mySys.m_CoolingSAFMethod = DataSizing.SupplyAirFlowRate
    mySys.m_HeatingSAFMethod = DataSizing.SupplyAirFlowRate
    mySys.m_DesignCoolingCapacity = DataSizing.AutoSize
    mySys.m_DesignHeatingCapacity = DataSizing.AutoSize
    mySys.m_CoolingCoilIndex = 0
    mySys.m_HeatingCoilIndex = 0
    state.dataWaterCoils.MySizeFlag = True
    state.dataWaterCoils.WaterCoil(1).DesAirVolFlowRate = DataSizing.AutoSize
    state.dataWaterCoils.WaterCoil(1).DesInletAirTemp = DataSizing.AutoSize
    state.dataWaterCoils.WaterCoil(1).DesOutletAirTemp = DataSizing.AutoSize
    state.dataWaterCoils.WaterCoil(1).DesInletWaterTemp = DataSizing.AutoSize
    state.dataWaterCoils.WaterCoil(1).DesInletAirHumRat = DataSizing.AutoSize
    state.dataWaterCoils.WaterCoil(1).DesOutletAirHumRat = DataSizing.AutoSize
    state.dataWaterCoils.WaterCoil(1).MaxWaterVolFlowRate = DataSizing.AutoSize
    state.dataWaterCoils.WaterCoil(1).MaxWaterVolFlowRate = DataSizing.AutoSize
    state.dataWaterCoils.WaterCoil(2).DesAirVolFlowRate = DataSizing.AutoSize
    state.dataWaterCoils.WaterCoil(2).DesInletAirTemp = DataSizing.AutoSize
    state.dataWaterCoils.WaterCoil(2).DesOutletAirTemp = DataSizing.AutoSize
    state.dataWaterCoils.WaterCoil(2).DesInletWaterTemp = DataSizing.AutoSize
    state.dataWaterCoils.WaterCoil(2).DesInletAirHumRat = DataSizing.AutoSize
    state.dataWaterCoils.WaterCoil(2).DesOutletAirHumRat = DataSizing.AutoSize
    state.dataWaterCoils.WaterCoil(2).MaxWaterVolFlowRate = DataSizing.AutoSize
    state.dataWaterCoils.WaterCoil(2).MaxWaterVolFlowRate = DataSizing.AutoSize
    state.dataWaterCoils.WaterCoil(1).DesWaterCoolingCoilRate = 0.0
    state.dataWaterCoils.WaterCoil(2).DesWaterHeatingCoilRate = 0.0
    mySys.sizeSystem(state, FirstHVACIteration, AirLoopNum)
    assert abs(state.dataWaterCoils.WaterCoil(1).DesWaterCoolingCoilRate - (6779.4 + FanCoolLoad)) <= 1.0
    assert abs(mySys.m_DesignCoolingCapacity - (6779.4 + FanCoolLoad)) <= 1.0
    assert abs(state.dataWaterCoils.WaterCoil(1).DesInletAirTemp - 20.541) <= 0.001
    assert abs(state.dataWaterCoils.WaterCoil(2).DesWaterHeatingCoilRate - 3848.0) <= 1.0

def TEST_F_ZoneUnitarySysTest_Test_UnitarySystemModel_factory() raises:
    var idf_objects: String = R"IDF(
        AirLoopHVAC:UnitarySystem,
          Unitary System Model,           !- Name
          Setpoint,                       !- Control Type
          East Zone,                      !- Controlling Zone or Thermostat Location
          None,                           !- Dehumidification Control Type
          Constant-1.0,                      !- Availability Schedule Name
          Zone Exhaust Node,              !- Air Inlet Node Name
          Zone 2 Inlet Node,              !- Air Outlet Node Name
          Fan:OnOff,                      !- Supply Fan Object Type
          Supply Fan 1,                   !- Supply Fan Name
          BlowThrough,                    !- Fan Placement
          ,                               !- Supply Air Fan Operating Mode Schedule Name
          ,                               !- Heating Coil Object Type
          ,                               !- Heating Coil Name
          ,                               !- DX Heating Coil Sizing Ratio
          Coil:Cooling:DX:MultiSpeed,     !- Cooling Coil Object Type
          DX Cooling Coil,                !- Cooling Coil Name
          No,                             !- Use DOAS DX Cooling Coil
          2.0,                            !- DOAS DX Cooling Coil Leaving Minimum Air Temperature{ C }
          SensibleOnlyLoadControl,        !- Latent Load Control
          ,                               !- Supplemental Heating Coil Object Type
          ,                               !- Supplemental Heating Coil Name
          ,                               !- Supply Air Flow Rate Method During Cooling Operation
          AutoSize,                       !- Supply Air Flow Rate During Cooling Operation{ m3/s }
          ,                               !- Supply Air Flow Rate Per Floor Area During Cooling Operation{ m3/s-m2 }
          ,                               !- Fraction of Autosized Design Cooling Supply Air Flow Rate
          ,                               !- Design Supply Air Flow Rate Per Unit of Capacity During Cooling Operation{ m3/s-W }
          ,                               !- Supply air Flow Rate Method During Heating Operation
          AutoSize,                       !- Supply Air Flow Rate During Heating Operation{ m3/s }
          ,                               !- Supply Air Flow Rate Per Floor Area during Heating Operation{ m3/s-m2 }
          ,                               !- Fraction of Autosized Design Heating Supply Air Flow Rate
          ,                               !- Design Supply Air Flow Rate Per Unit of Capacity During Heating Operation{ m3/s-W }
          ,                               !- Supply Air Flow Rate Method When No Cooling or Heating is Required
          AutoSize,                       !- Supply Air Flow Rate When No Cooling or Heating is Required{ m3/s }
          ,                               !- Supply Air Flow Rate Per Floor Area When No Cooling or Heating is Required{ m3/s-m2 }
          ,                               !- Fraction of Autosized Design Cooling Supply Air Flow Rate
          ,                               !- Fraction of Autosized Design Heating Supply Air Flow Rate
          ,                               !- Design Supply Air Flow Rate Per Unit of Capacity During Cooling Operation{ m3/s-W }
          ,                               !- Design Supply Air Flow Rate Per Unit of Capacity During Heating Operation{ m3/s-W }
          ,                               !- No Load Supply Air Flow Rate Control Set To Low Speed
          80.0,                           !- Maximum Supply Air Temperature{ C }
          ,                               !- Maximum Outdoor Dry-Bulb Temperature for Supplemental Heater Operation {C}
          ,                               !- Outdoor Dry-Bulb Temperature Sensor Node Name
          100,                            !- Ancillary On-Cycle Electric Power
          50,                             !- Ancillary Off-Cycle Electric Power
          ,                               !- Design Heat Recovery Water Flow Rate
          ,                               !- Maximum Temperature for Heat Recovery
          ,                               !- Heat Recovery Water Inlet Node Name
          ,                               !- Heat Recovery Water Outlet Node Name
          UnitarySystemPerformance:Multispeed,                     !- Design Specification Multispeed Object Type
          DX Cool MultiSpd Unitary System MultiSpeed Performance;  !- Design Specification Multispeed Object Name
        UnitarySystemPerformance:Multispeed,
          DX Cool MultiSpd Unitary System MultiSpeed Performance,  !- Name
          1,                              !- Number of Speeds for Heating
          2,                              !- Number of Speeds for Cooling
          No,                             !- Single Mode Operation
          ,                               !- No Load Supply Air Flow Rate Ratio
          AutoSize,                       !- Heating Speed 1 Supply Air Flow Ratio
          AutoSize,                       !- Cooling Speed 1 Supply Air Flow Ratio
          AutoSize,                       !- Heating Speed 2 Supply Air Flow Ratio
          AutoSize;                       !- Cooling Speed 2 Supply Air Flow Ratio
        Fan:OnOff,
          Supply Fan 1,                   !- Name
          Constant-1.0,                      !- Availability Schedule Name
          0.7,                            !- Fan Total Efficiency
          600.0,                          !- Pressure Rise{ Pa }
          AutoSize,                       !- Maximum Flow Rate{ m3 / s }
          0.9,                            !- Motor Efficiency
          1.0,                            !- Motor In Airstream Fraction
          Zone Exhaust Node,              !- Air Inlet Node Name
          Cooling Coil Air Inlet Node;    !- Air Outlet Node Name
        Coil:Cooling:DX:MultiSpeed,
          DX Cooling Coil,                !- Name
          Constant-1.0,                      !- Availability Schedule Name
          Cooling Coil Air Inlet Node,    !- Air Inlet Node Name
          Zone 2 Inlet Node,              !- Air Outlet Node Name
          ,                               !- Condenser Air Inlet Node Name
          AirCooled,                      !- Condenser Type
          ,                               !- Minimum Outdoor Dry - Bulb Temperature for Compressor Operation{ C }
          ,                               !- Supply Water Storage Tank Name
          ,                               !- Condensate Collection Water Storage Tank Name
          No,                             !- Apply Part Load Fraction to Speeds Greater than 1
          No,                             !- Apply Latent Degradation to Speeds Greater than 1
          0,                              !- Crankcase Heater Capacity{ W }
          ,                               !- Crankcase Heater Capacity Function of Temperature Curve Name
          10,                             !- Maximum Outdoor Dry - Bulb Temperature for Crankcase Heater Operation{ C }
          0,                              !- Basin Heater Capacity{ W / K }
          2,                              !- Basin Heater Setpoint Temperature{ C }
          ,                               !- Basin Heater Operating Schedule Name
          Electricity,                    !- Fuel Type
          2,                              !- Number of Speeds
          AutoSize,                       !- Speed 1 Gross Rated Total Cooling Capacity{ W }
          AutoSize,                       !- Speed 1 Gross Rated Sensible Heat Ratio
          5.12895662368113,               !- Speed 1 Gross Rated Cooling COP{ W / W }
          AutoSize,                       !- Speed 1 Rated Air Flow Rate{ m3 / s }
          773.3,                          !- 2017 Speed 1 Rated Evaporator Fan Power Per Volume Flow Rate {W/(m3/s)}
          934.4,                          !- 2023 Speed 1 Rated Evaporator Fan Power Per Volume Flow Rate {W/(m3/s)}", //??BPS:T
          Biquadratic,                    !- Speed 1 Total Cooling Capacity Function of Temperature Curve Name
          Quadratic,                      !- Speed 1 Total Cooling Capacity Function of Flow Fraction Curve Name
          Biquadratic,                    !- Speed 1 Energy Input Ratio Function of Temperature Curve Name
          Quadratic,                      !- Speed 1 Energy Input Ratio Function of Flow Fraction Curve Name
          Quadratic,                      !- Speed 1 Part Load Fraction Correlation Curve Name
          0,                              !- Speed 1 Nominal Time for Condensate Removal to Begin{ s }
          0,                              !- Speed 1 Ratio of Initial Moisture Evaporation Rate and Steady State Latent Capacity{ dimensionless }
          0,                              !- Speed 1 Maximum Cycling Rate{ cycles / hr }
          0,                              !- Speed 1 Latent Capacity Time Constant{ s }
          0.5,                            !- Speed 1 Rated Waste Heat Fraction of Power Input{ dimensionless }
          Biquadratic,                    !- Speed 1 Waste Heat Function of Temperature Curve Name
          0.9,                            !- Speed 1 Evaporative Condenser Effectiveness{ dimensionless }
          AutoSize,                       !- Speed 1 Evaporative Condenser Air Flow Rate{ m3 / s }
          AutoSize,                       !- Speed 1 Rated Evaporative Condenser Pump Power Consumption{ W }
          AutoSize,                       !- Speed 2 Gross Rated Total Cooling Capacity{ W }
          AutoSize,                       !- Speed 2 Gross Rated Sensible Heat Ratio
          4.68933177022274,               !- Speed 2 Gross Rated Cooling COP{ W / W }
          AutoSize,                       !- Speed 2 Rated Air Flow Rate{ m3 / s }
          773.3,                          !- 2017 Speed 2 Rated Evaporator Fan Power Per Volume Flow Rate {W/(m3/s)}
          934.4,                          !- 2023 Speed 2 Rated Evaporator Fan Power Per Volume Flow Rate {W/(m3/s)}
          Biquadratic,                    !- Speed 2 Total Cooling Capacity Function of Temperature Curve Name
          Quadratic,                      !- Speed 2 Total Cooling Capacity Function of Flow Fraction Curve Name
          Biquadratic,                    !- Speed 2 Energy Input Ratio Function of Temperature Curve Name
          Quadratic,                      !- Speed 2 Energy Input Ratio Function of Flow Fraction Curve Name
          Quadratic,                      !- Speed 2 Part Load Fraction Correlation Curve Name
          0,                              !- Speed 2 Nominal Time for Condensate Removal to Begin{ s }
          0,                              !- Speed 2 Ratio of Initial Moisture Evaporation Rate and Steady State Latent Capacity{ dimensionless }
          0,                              !- Speed 2 Maximum Cycling Rate{ cycles / hr }
          0,                              !- Speed 2 Latent Capacity Time Constant{ s }
          0.5,                            !- Speed 2 Rated Waste Heat Fraction of Power Input{ dimensionless }
          Biquadratic,                    !- Speed 2 Waste Heat Function of Temperature Curve Name
          0.9,                            !- Speed 2 Evaporative Condenser Effectiveness{ dimensionless }
          AutoSize,                       !- Speed 2 Evaporative Condenser Air Flow Rate{ m3 / s }
          AutoSize;                       !- Speed 2 Rated Evaporative Condenser Pump Power Consumption{ W }
        ScheduleTypeLimits,
          Any Number;                     !- Name
        Schedule:Compact,
          Always 20C,                     !- Name
          Any Number,                     !- Schedule Type Limits Name
          Through: 12/31,                 !- Field 1
          For: AllDays,                   !- Field 2
          Until: 24:00, 20.0;             !- Field 3
        SetpointManager:Scheduled,
          Cooling Coil Setpoint Manager,  !- Name
          Temperature,                    !- Control Variable
          Always 20C,                     !- Schedule Name
          Zone 2 Inlet Node;              !- Setpoint Node or NodeList Name
        Curve:Quadratic,
          Quadratic,                      !- Name
          0.8,                            !- Coefficient1 Constant
          0.2,                            !- Coefficient2 x
          0.0,                            !- Coefficient3 x**2
          0.5,                            !- Minimum Value of x
          1.5;                            !- Maximum Value of x
        Curve:Biquadratic,
          Biquadratic,                    !- Name
          0.942587793,                    !- Coefficient1 Constant
          0.009543347,                    !- Coefficient2 x
          0.000683770,                    !- Coefficient3 x**2
          -0.011042676,                   !- Coefficient4 y
          0.000005249,                    !- Coefficient5 y**2
          -0.000009720,                   !- Coefficient6 x*y
          12.77778,                       !- Minimum Value of x
          23.88889,                       !- Maximum Value of x
          18.0,                           !- Minimum Value of y
          46.11111,                       !- Maximum Value of y
          ,                               !- Minimum Curve Output
          ,                               !- Maximum Curve Output
          Temperature,                    !- Input Unit Type for X
          Temperature,                    !- Input Unit Type for Y
          Dimensionless;                  !- Output Unit Type
    )IDF"
    assert process_idf(idf_objects)
    state.init_state(state)
    var compName: String = "UNITARY SYSTEM MODEL"
    var zoneEquipment: Bool = True
    var FirstHVACIteration: Bool = True
    UnitarySystems.UnitarySys.factory(state, HVAC.UnitarySysType.Unitary_AnyCoilType, compName, zoneEquipment, 0)
    var thisSys: UnitarySys = state.dataUnitarySystems.unitarySys[0]
    state.dataZoneEquip.ZoneEquipInputsFilled = True
    thisSys.getUnitarySystemInputData(state, compName, zoneEquipment, 0, ErrorsFound)
    assert state.dataUnitarySystems.unitarySys.size() == 1
    assert thisSys.Name == compName
    state.dataGlobal.BeginEnvrnFlag = True
    state.dataLoopNodes.Node(1).MassFlowRate = 1.0
    state.dataLoopNodes.Node(1).MassFlowRateMaxAvail = 1.0
    state.dataLoopNodes.Node(1).Temp = 24.0
    state.dataLoopNodes.Node(1).HumRat = 0.00922
    state.dataLoopNodes.Node(1).Enthalpy = 47597.03
    state.dataLoopNodes.Node(3).MassFlowRateMax = 1.0
    state.dataLoopNodes.Node(2).TempSetPoint = 17.0
    var AirLoopNum: Int = 0
    var CompIndex: Int = 0
    var HeatingActive: Bool = False
    var CoolingActive: Bool = False
    var OAUnitNum: Int = 0
    var OAUCoilOutTemp: Float64 = 0.0
    var sensOut: Float64 = 0.0
    var latOut: Float64 = 0.0
    state.dataGlobal.SysSizingCalc = False
    assert thisSys.Name == compName
    thisSys.simulate(state, compName, FirstHVACIteration, AirLoopNum, CompIndex, HeatingActive, CoolingActive, OAUnitNum, OAUCoilOutTemp, zoneEquipment, sensOut, latOut)
    assert thisSys.Name == compName
    assert abs(thisSys.m_AncillaryOnPower - 100.0) <= 0.00000001
    assert abs(thisSys.m_AncillaryOffPower - 50.0) <= 0.00000001
    assert abs(thisSys.m_PartLoadFrac - 0.4787718) <= 0.000001
    var totalAncillaryPower: Float64 = thisSys.m_AncillaryOnPower * thisSys.m_PartLoadFrac + thisSys.m_AncillaryOffPower * (1.0 - thisSys.m_PartLoadFrac)
    assert abs(totalAncillaryPower - thisSys.m_TotalAuxElecPower) <= 0.00000001
    assert abs(thisSys.m_TotalAuxElecPower - 73.93859) <= 0.0001
    var fanDT: Float64 = thisSys.getFanDeltaTemp(state, True, 1, 1.0)
    assert abs(fanDT - 0.7070) <= 0.0001
    fanDT = thisSys.getFanDeltaTemp(state, True, 0.5, 0.5)
    assert abs(fanDT - 0.7070) <= 0.0001
    assert thisSys.m_useNoLoadLowSpeedAirFlow

def TEST_F_ZoneUnitarySysTest_UnitarySystemModel_TwoSpeedDXCoolCoil_Only() raises:
    var idf_objects: String = R"IDF(
        AirLoopHVAC:UnitarySystem,
          Unitary System Model,           !- Name
          Setpoint,                       !- Control Type
          East Zone,                      !- Controlling Zone or Thermostat Location
          None,                           !- Dehumidification Control Type
          Constant-1.0,                      !- Availability Schedule Name
          Zone Exhaust Node,              !- Air Inlet Node Name
          Zone 2 Inlet Node,              !- Air Outlet Node Name
          Fan:OnOff,                      !- Supply Fan Object Type
          Supply Fan 1,                   !- Supply Fan Name
          BlowThrough,                    !- Fan Placement
          ,                               !- Supply Air Fan Operating Mode Schedule Name
          ,                               !- Heating Coil Object Type
          ,                               !- Heating Coil Name
          ,                               !- DX Heating Coil Sizing Ratio
          Coil:Cooling:DX:TwoSpeed,       !- Cooling Coil Object Type
          DX Cooling Coil,                !- Cooling Coil Name
          No,                             !- Use DOAS DX Cooling Coil
          2.0,                            !- DOAS DX Cooling Coil Leaving Minimum Air Temperature{ C }
          SensibleOnlyLoadControl,        !- Latent Load Control
          ,                               !- Supplemental Heating Coil Object Type
          ,                               !- Supplemental Heating Coil Name
          ,                               !- Supply Air Flow Rate Method During Cooling Operation
          autosize,                       !- Supply Air Flow Rate During Cooling Operation{ m3/s }
          ,                               !- Supply Air Flow Rate Per Floor Area During Cooling Operation{ m3/s-m2 }
          ,                               !- Fraction of Autosized Design Cooling Supply Air Flow Rate
          ,                               !- Design Supply Air Flow Rate Per Unit of Capacity During Cooling Operation{ m3/s-W }
          ,                               !- Supply air Flow Rate Method During Heating Operation
          autosize,                       !- Supply Air Flow Rate During Heating Operation{ m3/s }
          ,                               !- Supply Air Flow Rate Per Floor Area during Heating Operation{ m3/s-m2 }
          ,                               !- Fraction of Autosized Design Heating Supply Air Flow Rate
          ,                               !- Design Supply Air Flow Rate Per Unit of Capacity During Heating Operation{ m3/s-W }
          ,                               !- Supply Air Flow Rate Method When No Cooling or Heating is Required
          autosize,                       !- Supply Air Flow Rate When No Cooling or Heating is Required{ m3/s }
          ,                               !- Supply Air Flow Rate Per Floor Area When No Cooling or Heating is Required{ m3/s-m2 }
          ,                               !- Fraction of Autosized Design Cooling Supply Air Flow Rate
          ,                               !- Fraction of Autosized Design Heating Supply Air Flow Rate
          ,                               !- Design Supply Air Flow Rate Per Unit of Capacity During Cooling Operation{ m3/s-W }
          ,                               !- Design Supply Air Flow Rate Per Unit of Capacity During Heating Operation{ m3/s-W }
          ,                               !- No Load Supply Air Flow Rate Control Set To Low Speed
          80.0;                           !- Maximum Supply Air Temperature{ C }
        Fan:OnOff,
          Supply Fan 1,                   !- Name
          Constant-1.0,                      !- Availability Schedule Name
          0.7,                            !- Fan Total Efficiency
          600.0,                          !- Pressure Rise{ Pa }
          autosize,                       !- Maximum Flow Rate{ m3 / s }
          0.9,                            !- Motor Efficiency
          1.0,                            !- Motor In Airstream Fraction
          Zone Exhaust Node,              !- Air Inlet Node Name
          Cooling Coil Air Inlet Node;    !- Air Outlet Node Name
        Coil:Cooling:DX:TwoSpeed,
          DX Cooling Coil,                !- Name
          ,                               !- Availability Schedule Name
          autosize,                       !- High Speed Gross Rated Total Cooling Capacity{ W }
          0.8,                            !- High Speed Rated Sensible Heat Ratio
          3.0,                            !- High Speed Gross Rated Cooling COP{ W / W }
         autosize,                        !- High Speed Rated Air Flow Rate{ m3 / s }
          ,
          ,
         450,                             !- Unit Internal Static Air Pressure{ Pa }
         Cooling Coil Air Inlet Node,     !- Air Inlet Node Name
         Zone 2 Inlet Node,               !- Air Outlet Node Name
         Biquadratic,                     !- Total Cooling Capacity Function of Temperature Curve Name
         Quadratic,                       !- Total Cooling Capacity Function of Flow Fraction Curve Name
         Biquadratic,                     !- Energy Input Ratio Function of Temperature Curve Name
         Quadratic,                       !- Energy Input Ratio Function of Flow Fraction Curve Name
         Quadratic,                       !- Part Load Fraction Correlation Curve Name
         autosize,                        !- Low Speed Gross Rated Total Cooling Capacity{ W }
         0.8,                             !- Low Speed Gross Rated Sensible Heat Ratio
         4.2,                             !- Low Speed Gross Rated Cooling COP{ W / W }
         autosize,                        !- Low Speed Rated Air Flow Rate{ m3 / s }
          ,
          ,
         Biquadratic,                     !- Low Speed Total Cooling Capacity Function of Temperature Curve Name
         Biquadratic,                     !- Low Speed Energy Input Ratio Function of Temperature Curve Name
         ,                                !- Condenser Air Inlet Node Name
         EvaporativelyCooled; !- Condenser Type
        ScheduleTypeLimits,
          Any Number;                     !- Name
        Schedule:Compact,
          Always 20C,                     !- Name
          Any Number,                     !- Schedule Type Limits Name
          Through: 12/31,                 !- Field 1
          For: AllDays,                   !- Field 2
          Until: 24:00, 20.0;             !- Field 3
        SetpointManager:Scheduled,
          Cooling Coil Setpoint Manager,  !- Name
          Temperature,                    !- Control Variable
          Always 20C,                     !- Schedule Name
          Zone 2 Inlet Node;              !- Setpoint Node or NodeList Name
        Curve:Quadratic,
          Quadratic,                      !- Name
          0.8,                            !- Coefficient1 Constant
          0.2,                            !- Coefficient2 x
          0.0,                            !- Coefficient3 x**2
          0.5,                            !- Minimum Value of x
          1.5;                            !- Maximum Value of x
        Curve:Biquadratic,
          Biquadratic,                    !- Name
          0.942587793,                    !- Coefficient1 Constant
          0.009543347,                    !- Coefficient2 x
          0.000683770,                    !- Coefficient3 x**2
          -0.011042676,                   !- Coefficient4 y
          0.000005249,                    !- Coefficient5 y**2
          -0.000009720,                   !- Coefficient6 x*y
          12.77778,                       !- Minimum Value of x
          23.88889,                       !- Maximum Value of x
          18.0,                           !- Minimum Value of y
          46.11111,                       !- Maximum Value of y
          ,                               !- Minimum Curve Output
          ,                               !- Maximum Curve Output
          Temperature,                    !- Input Unit Type for X
          Temperature,                    !- Input Unit Type for Y
          Dimensionless;                  !- Output Unit Type
    )IDF"
    assert process_idf(idf_objects)
    state.init_state(state)
    var compName: String = "UNITARY SYSTEM MODEL"
    var zoneEquipment: Bool = True
    var FirstHVACIteration: Bool = True
    UnitarySystems.UnitarySys.factory(state, HVAC.UnitarySysType.Unitary_AnyCoilType, compName, zoneEquipment, 0)
    var thisSys: UnitarySys = state.dataUnitarySystems.unitarySys[0]
    state.dataZoneEquip.ZoneEquipInputsFilled = True
    thisSys.getUnitarySystemInputData(state, compName, zoneEquipment, 0, ErrorsFound)
    assert not ErrorsFound
    FirstHVACIteration = False
    state.dataGlobal.BeginEnvrnFlag = False
    state.dataSize.DesDayWeath(1).Temp(1) = 29.4
    state.dataLoopNodes.Node(thisSys.CoolCoilInletNodeNum).MassFlowRate = 0.05
    var AirLoopNum: Int = 0
    var CompIndex: Int = 1
    var HeatActive: Bool = False
    var CoolActive: Bool = True
    var ZoneOAUnitNum: Int = 0
    var OAUCoilOutTemp: Float64 = 0.0
    var ZoneEquipment: Bool = True
    var sensOut: Float64 = 0.0
    var latOut: Float64 = 0.0
    thisSys.simulate(state, thisSys.Name, FirstHVACIteration, AirLoopNum, CompIndex, HeatActive, CoolActive, ZoneOAUnitNum, OAUCoilOutTemp, ZoneEquipment, sensOut, latOut)
    state.dataLoopNodes.Node(1).MassFlowRate = thisSys.m_DesignMassFlowRate
    state.dataLoopNodes.Node(1).MassFlowRateMaxAvail = thisSys.m_DesignMassFlowRate
    state.dataLoopNodes.Node(1).Temp = 24.0
    state.dataLoopNodes.Node(1).HumRat = 0.00922
    state.dataLoopNodes.Node(1).Enthalpy = 47597.03
    state.dataLoopNodes.Node(3).MassFlowRateMax = thisSys.m_DesignMassFlowRate
    state.dataLoopNodes.Node(2).TempSetPoint = 17.0
    state.dataGlobal.BeginEnvrnFlag = True
    thisSys.simulate(state, thisSys.Name, FirstHVACIteration, AirLoopNum, CompIndex, HeatActive, CoolActive, ZoneOAUnitNum, OAUCoilOutTemp, ZoneEquipment, sensOut, latOut)
    assert abs(state.dataLoopNodes.Node(2).Temp - state.dataLoopNodes.Node(2).TempSetPoint) <= 0.001
    assert state.dataLoopNodes.Node(3).Temp > state.dataLoopNodes.Node(2).Temp
    assert thisSys.m_useNoLoadLowSpeedAirFlow

def TEST_F_ZoneUnitarySysTest_UnitarySystemModel_MultiSpeedDXCoolCoil_Only() raises:
    var idf_objects: String = R"IDF(
        AirLoopHVAC:UnitarySystem,
          Unitary System Model,           !- Name
          Setpoint,                       !- Control Type
          East Zone,                      !- Controlling Zone or Thermostat Location
          None,                           !- Dehumidification Control Type
          Constant-1.0,                      !- Availability Schedule Name
          Zone Exhaust Node,              !- Air Inlet Node Name
          Zone 2 Inlet Node,              !- Air Outlet Node Name
          Fan:OnOff,                      !- Supply Fan Object Type
          Supply Fan 1,                   !- Supply Fan Name
          BlowThrough,                    !- Fan Placement
          ,                               !- Supply Air Fan Operating Mode Schedule Name
          ,                               !- Heating Coil Object Type
          ,                               !- Heating Coil Name
          ,                               !- DX Heating Coil Sizing Ratio
          Coil:Cooling:DX:MultiSpeed,     !- Cooling Coil Object Type
          DX Cooling Coil,                !- Cooling Coil Name
          No,                             !- Use DOAS DX Cooling Coil
          2.0,                            !- DOAS DX Cooling Coil Leaving Minimum Air Temperature{ C }
          SensibleOnlyLoadControl,        !- Latent Load Control
          ,                               !- Supplemental Heating Coil Object Type
          ,                               !- Supplemental Heating Coil Name
          ,                               !- Supply Air Flow Rate Method During Cooling Operation
          autosize,                       !- Supply Air Flow Rate During Cooling Operation{ m3/s }
          ,                               !- Supply Air Flow Rate Per Floor Area During Cooling Operation{ m3/s-m2 }
          ,                               !- Fraction of Autosized Design Cooling Supply Air Flow Rate
          ,                               !- Design Supply Air Flow Rate Per Unit of Capacity During Cooling Operation{ m3/s-W }
          ,                               !- Supply air Flow Rate Method During Heating Operation
          autosize,                       !- Supply Air Flow Rate During Heating Operation{ m3/s }
          ,                               !- Supply Air Flow Rate Per Floor Area during Heating Operation{ m3/s-m2 }
          ,                               !- Fraction of Autosized Design Heating Supply Air Flow Rate
          ,                               !- Design Supply Air Flow Rate Per Unit of Capacity During Heating Operation{ m3/s-W }
          ,                               !- Supply Air Flow Rate Method When No Cooling or Heating is Required
          autosize,                       !- Supply Air Flow Rate When No Cooling or Heating is Required{ m3/s }
          ,                               !- Supply Air Flow Rate Per Floor Area When No Cooling or Heating is Required{ m3/s-m2 }
          ,                               !- Fraction of Autosized Design Cooling Supply Air Flow Rate
          ,                               !- Fraction of Autosized Design Heating Supply Air Flow Rate
          ,                               !- Design Supply Air Flow Rate Per Unit of Capacity During Cooling Operation{ m3/s-W }
          ,                               !- Design Supply Air Flow Rate Per Unit of Capacity During Heating Operation{ m3/s-W }
          ,                               !- No Load Supply Air Flow Rate Control Set To Low Speed
          80.0,                           !- Maximum Supply Air Temperature{ C }
          ,                               !- Maximum Outdoor Dry-Bulb Temperature for Supplemental Heater Operation {C}
          ,                               !- Outdoor Dry-Bulb Temperature Sensor Node Name
          ,                               !- Ancilliary On-Cycle Electric Power
          ,                               !- Ancilliary Off-Cycle Electric Power
          ,                               !- Design Heat Recovery Water Flow Rate
          ,                               !- Maximum Temperature for Heat Recovery
          ,                               !- Heat Recovery Water Inlet Node Name
          ,                               !- Heat Recovery Water Outlet Node Name
          UnitarySystemPerformance:Multispeed,                     !- Design Specification Multispeed Object Type
          DX Cool MultiSpd Unitary System MultiSpeed Performance;  !- Design Specification Multispeed Object Name
        UnitarySystemPerformance:Multispeed,
          DX Cool MultiSpd Unitary System MultiSpeed Performance,  !- Name
          1,                              !- Number of Speeds for Heating
          2,                              !- Number of Speeds for Cooling
          No,                             !- Single Mode Operation
          ,                               !- No Load Supply Air Flow Rate Ratio
          1,                              !- Heating Speed 1 Supply Air Flow Ratio
          1,                              !- Cooling Speed 1 Supply Air Flow Ratio
          Autosize,                       !- Heating Speed 2 Supply Air Flow Ratio
          Autosize;                       !- Cooling Speed 2 Supply Air Flow Ratio
        Fan:OnOff,
          Supply Fan 1,                   !- Name
          Constant-1.0,                      !- Availability Schedule Name
          0.7,                            !- Fan Total Efficiency
          600.0,                          !- Pressure Rise{ Pa }
          autosize,                       !- Maximum Flow Rate{ m3 / s }
          0.9,                            !- Motor Efficiency
          1.0,                            !- Motor In Airstream Fraction
          Zone Exhaust Node,              !- Air Inlet Node Name
          Cooling Coil Air Inlet Node;    !- Air Outlet Node Name
        Coil:Cooling:DX:MultiSpeed,
          DX Cooling Coil,                !- Name
          ,                               !- Availability Schedule Name
          Cooling Coil Air Inlet Node,    !- Air Inlet Node Name
          Zone 2 Inlet Node,              !- Air Outlet Node Name
          ,                               !- Condenser Air Inlet Node Name
          AirCooled,                      !- Condenser Type
          ,                               !- Minimum Outdoor Dry - Bulb Temperature for Compressor Operation{ C }
          ,                               !- Supply Water Storage Tank Name
          ,                               !- Condensate Collection Water Storage Tank Name
          No,                             !- Apply Part Load Fraction to Speeds Greater than 1
          No,                             !- Apply Latent Degradation to Speeds Greater than 1
          0,                              !- Crankcase Heater Capacity{ W }
          ,                               !- Crankcase Heater Capacity Function of Temperature Curve Name
          10,                             !- Maximum Outdoor Dry - Bulb Temperature for Crankcase Heater Operation{ C }
          0,                              !- Basin Heater Capacity{ W / K }
          2,                              !- Basin Heater Setpoint Temperature{ C }
          ,                               !- Basin Heater Operating Schedule Name
          Electricity,                    !- Fuel Type
          2,                              !- Number of Speeds
          AutoSize,                       !- Speed 1 Gross Rated Total Cooling Capacity{ W }
          AutoSize,                       !- Speed 1 Gross Rated Sensible Heat Ratio
          5.12895662368113,               !- Speed 1 Gross Rated Cooling COP{ W / W }
          AutoSize,                       !- Speed 1 Rated Air Flow Rate{ m3 / s }
          773.3,                          !- 2017 Speed 1 Rated Evaporator Fan Power Per Volume Flow Rate {W/(m3/s)}
          934.4,                          !- 2023 Speed 1 Rated Evaporator Fan Power Per Volume Flow Rate {W