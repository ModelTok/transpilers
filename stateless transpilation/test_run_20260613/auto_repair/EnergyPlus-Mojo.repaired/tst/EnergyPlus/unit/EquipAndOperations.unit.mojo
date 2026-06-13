from Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataAirLoop import DataAirLoop
from EnergyPlus.DataGlobals import DataGlobals
from EnergyPlus.DataHVACGlobals import DataHVACGlobals
from EnergyPlus.DataHeatBalance import DataHeatBalance
from EnergyPlus.DataZoneEnergyDemands import DataZoneEnergyDemands
from EnergyPlus.Plant.DataPlant import DataPlant
from EnergyPlus.Plant.EquipAndOperations import EquipAndOperations
from EnergyPlus.Plant.PlantManager import PlantManager
from EnergyPlus.PlantCondLoopOperation import PlantCondLoopOperation
from EnergyPlus.ScheduleManager import ScheduleManager
from EnergyPlus.SetPointManager import SetPointManager
from EnergyPlus.Fluid import Fluid
from testing import expect_true, expect_eq, expect_near, assert_true

struct DistributeEquipOpTest(EnergyPlusFixture):
    var state: EnergyPlusData

    def __init__(inout self):

    def TearDownTestCase():

    def SetUp(inout self):
        EnergyPlusFixture.SetUp()  # Sets up individual test cases.
        self.state.dataHeatBal.Zone.resize(4)
        self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand.resize(4)
        self.state.dataHeatBal.NumOfZoneLists = 1
        self.state.dataHeatBal.ZoneList.resize(1)
        self.state.dataHeatBal.ZoneList[0].Name = "THIS ZONE LIST"
        self.state.dataHeatBal.ZoneList[0].NumOfZones = 4
        self.state.dataHeatBal.ZoneList[0].Zone.resize(4)
        self.state.dataHeatBal.ZoneList[0].Zone[0] = 1
        self.state.dataHeatBal.ZoneList[0].Zone[1] = 2
        self.state.dataHeatBal.ZoneList[0].Zone[2] = 3
        self.state.dataHeatBal.ZoneList[0].Zone[3] = 4
        self.state.dataHVACGlobal.NumPrimaryAirSys = 1
        self.state.dataAirLoop.AirLoopFlow.resize(self.state.dataHVACGlobal.NumPrimaryAirSys)
        self.state.dataAirLoop.AirToZoneNodeInfo.resize(self.state.dataHVACGlobal.NumPrimaryAirSys)
        self.state.dataAirLoop.AirToZoneNodeInfo[0].AirLoopReturnNodeNum.resize(1)
        self.state.dataAirLoop.AirToZoneNodeInfo[0].NumZonesCooled = 4
        self.state.dataAirLoop.AirToZoneNodeInfo[0].CoolCtrlZoneNums.resize(4)
        self.state.dataAirLoop.AirToZoneNodeInfo[0].CoolCtrlZoneNums[0] = self.state.dataHeatBal.ZoneList[0].Zone[2]  # 1-based 3 -> index 2
        self.state.dataAirLoop.AirToZoneNodeInfo[0].CoolCtrlZoneNums[1] = self.state.dataHeatBal.ZoneList[0].Zone[0]  # 1-based 1 -> index 0
        self.state.dataAirLoop.AirToZoneNodeInfo[0].CoolCtrlZoneNums[2] = self.state.dataHeatBal.ZoneList[0].Zone[3]  # 1-based 4 -> index 3
        self.state.dataAirLoop.AirToZoneNodeInfo[0].CoolCtrlZoneNums[3] = self.state.dataHeatBal.ZoneList[0].Zone[1]  # 1-based 2 -> index 1
        self.state.dataHVACGlobal.NumPlantLoops = 2
        self.state.dataPlnt.TotNumLoops = self.state.dataHVACGlobal.NumPlantLoops
        self.state.dataPlnt.PlantLoop.resize(self.state.dataPlnt.TotNumLoops)
        var loop: Int = 0
        for i in range(self.state.dataPlnt.PlantLoop.size):
            var thisPlantLoop = self.state.dataPlnt.PlantLoop[i]
            loop += 1
            if loop == 1:
                thisPlantLoop.Name = "Cooling Plant"
                thisPlantLoop.OperationScheme = "Cooling Loop Operation Scheme List"
            else:
                thisPlantLoop.Name = "Heating Plant"
                thisPlantLoop.OperationScheme = "Heating Loop Operation Scheme List"
            thisPlantLoop.FluidName = "WATER"
            thisPlantLoop.glycol = Fluid.GetWater(self.state)
            thisPlantLoop.NumOpSchemes = 1
            thisPlantLoop.OpScheme.resize(thisPlantLoop.NumOpSchemes)
            var opSch1 = thisPlantLoop.OpScheme[0]
            opSch1.NumEquipLists = 1
            opSch1.EquipList.resize(2)
            for LoopSideNum in DataPlant.LoopSideKeys:
                thisPlantLoop.LoopSide[LoopSideNum].TotalBranches = 2
                thisPlantLoop.LoopSide[LoopSideNum].Branch.resize(2)
                thisPlantLoop.LoopSide[LoopSideNum].Branch[0].TotalComponents = 1
                thisPlantLoop.LoopSide[LoopSideNum].Branch[1].TotalComponents = 1
                thisPlantLoop.LoopSide[LoopSideNum].Branch[0].Comp.resize(1)
                thisPlantLoop.LoopSide[LoopSideNum].Branch[1].Comp.resize(1)
            for opSch in thisPlantLoop.OpScheme:
                for eqListNum in range(1, opSch.EquipList.size + 1):  # 1-based loop
                    opSch.NumEquipLists = eqListNum
                    var thisEquipList = opSch.EquipList[eqListNum - 1]  # 0-based index
                    thisEquipList.NumComps = eqListNum
                    thisEquipList.Comp.resize(thisEquipList.NumComps)
                    for compNum in range(1, opSch.EquipList[eqListNum - 1].NumComps + 1):
                        thisEquipList.Comp[compNum - 1].CompNumPtr = compNum
                        thisEquipList.Comp[compNum - 1].BranchNumPtr = 1

    def ResetLoads(inout self):
        for thisPlantLoop in self.state.dataPlnt.PlantLoop:
            var thisBranch = thisPlantLoop.LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0]
            for compNum in range(1, thisPlantLoop.OpScheme[0].EquipList[0].NumComps + 1):
                thisBranch.Comp[compNum - 1].MyLoad = 0.0

    def TearDown(inout self):
        EnergyPlusFixture.TearDown()  # Remember to tear down the base fixture after cleaning up derived fixture!

def EvaluateChillerHeaterChangeoverOpSchemeTest(inout self: DistributeEquipOpTest):
    let idf_objects: String = """
      PlantEquipmentOperationSchemes,
        Cooling Loop Operation Scheme List, !- Name
        PlantEquipmentOperation:ChillerHeaterChangeover, !- Control Scheme 1 Object Type
        Two AWHP Operation Scheme,         !- Control Scheme 1 Name
        ALWAYS_ON;                         !- Control Scheme 1 Schedule Name
      PlantEquipmentOperationSchemes,
        Heating Loop Operation Scheme List, !- Name
        PlantEquipmentOperation:ChillerHeaterChangeover,  !- Control Scheme 1 Object Type
        Two AWHP Operation Scheme,         !- Control Scheme 1 Name
        ALWAYS_ON;                         !- Control Scheme 1 Schedule Name
      Schedule:Compact, ALWAYS_ON, On/Off, Through: 12/31, For: AllDays, Until: 24:00,1;
    PlantEquipmentOperation:ChillerHeaterChangeover,
      Two AWHP Operation Scheme ,          !- Name
      6.6 ,                                !- Primary Cooling Plant Setpoint Temperature
      13.7,                                !- Secondary Distribution Cooling Plant Setpoint Temperature
      59.8 ,                               !- Primary Heating Plant Setpoint at Outdoor High Temperature
      10.0,                                !- Outdoor High Temperature
      37.6 ,                               !- Primary Heating Plant Setpoint at Outdoor Low Temperature
      0.0 ,                                !- Outdoor Low Temperature
      45.0 ,                               !- Secondary Distribution Heating Plant Setpoint Temperature
      This Zone List,                      !- Zone Load Polling ZoneList Name
      Two AWHP Cooling Operation Scheme,   !- Cooling Only Load Plant Equipment Operation Cooling Load Name
      Two AWHP Heating Operation Scheme,   !- Heating Only Load Plant Equipment Operation Heating Load Name
      One AWHP Cooling Operation Scheme,   !- Simultaneous Cooling And Heating Plant Equipment Operation Cooling Load Name
      One AWHP Heating Operation Scheme,   !- Simultaneous Cooling And Heating Plant Equipment Operation Heating Load Name
      ,                                    !- Dedicated Chilled Water Return Recovery HeatPump Name
      ,                                    !- Dedicated Hot Water Return Recovery HeatPump Name
      1.0;                                 !-  Dedicated Recovery Heat Pump Control Load Capacity Factor
      PlantEquipmentOperation:CoolingLoad,
        Two AWHP Cooling Operation Scheme, !- Name
        0.0,                               !- Load Range 1 Lower Limit {W}
        50000,                             !- Load Range 1 Upper Limit {W}
        One AWHP Cooling Equipment List,   !- Range 1 Equipment List Name
        50000,                             !- Load Range 2 Lower Limit {W}
        10000000000000,                    !- Load Range 2 Upper Limit {W}
        Two AWHP Cooling Equipment List;   !- Range 2 Equipment List Name
      PlantEquipmentOperation:HeatingLoad,
        Two AWHP Heating Operation Scheme, !- Name
        0.0,                               !- Load Range 1 Lower Limit {W}
        100000,                            !- Load Range 1 Upper Limit {W}
        One AWHP Heating Equipment List,   !- Range 1 Equipment List Name
        100000,                            !- Load Range 2 Lower Limit {W}
        10000000000000,                    !- Load Range 2 Upper Limit {W}
        Two AWHP Heating Equipment List;   !- Range 2 Equipment List Name
      PlantEquipmentOperation:CoolingLoad,
        One AWHP Cooling Operation Scheme, !- Name
        0.0,                               !- Load Range 1 Lower Limit {W}
        10000000000000000,                 !- Load Range 1 Upper Limit {W}
        One AWHP Cooling Equipment List;   !- Range 1 Equipment List Name
      PlantEquipmentOperation:HeatingLoad,
        One AWHP Heating Operation Scheme, !- Name
        0.0,                               !- Load Range 1 Lower Limit {W}
        10000000000000000,                 !- Load Range 1 Upper Limit {W}
        One AWHP Heating Equipment List;   !- Range 1 Equipment List Name
      PlantEquipmentList,
        One AWHP Heating Equipment List,   !- Name
        HeatPump:PlantLoop:EIR:Heating,    !- Equipment 1 Object Type
        AWHP_2 Heating Side;               !- Equipment 1 Name
      PlantEquipmentList,
        One AWHP Cooling Equipment List,   !- Name
        HeatPump:PlantLoop:EIR:Cooling,    !- Equipment 1 Object Type
        AWHP_1 Cooling Side;               !- Equipment 1 Name
      PlantEquipmentList,
        Two AWHP Heating Equipment List,   !- Name
        HeatPump:PlantLoop:EIR:Heating,    !- Equipment 1 Object Type
        AWHP_1 Heating Side,               !- Equipment 1 Name
        HeatPump:PlantLoop:EIR:Heating,    !- Equipment 2 Object Type
        AWHP_2 Heating Side;               !- Equipment 2 Name
      PlantEquipmentList,
        Two AWHP Cooling Equipment List,   !- Name
        HeatPump:PlantLoop:EIR:Cooling,    !- Equipment 1 Object Type
        AWHP_1 Cooling Side,               !- Equipment 1 Name
        HeatPump:PlantLoop:EIR:Cooling,    !- Equipment 2 Object Type
        AWHP_2 Cooling Side;               !- Equipment 2 Name
      ZoneList,
        This Zone List,                    !- Name
        Zone1,                             !- Zone Name 1
        Zone2,                             !- Zone Name 2
        Zone3,                             !- Zone Name 3
        Zone4;                             !- Zone Name 4
     """
    assert_true(process_idf(idf_objects))
    self.state.init_state(self.state)
    var heatBranch1 = self.state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Supply].Branch[0]
    var heatComp1 = self.state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Supply].Branch[0].Comp[0]
    heatComp1.Type = DataPlant.PlantEquipmentType.HeatPumpEIRHeating
    heatComp1.Name = "AWHP_1 Heating Side"
    heatBranch1.NodeNumIn = 1
    heatBranch1.NodeNumOut = 2
    heatComp1.NodeNumIn = 1
    heatComp1.NodeNumOut = 2
    self.state.dataPlnt.PlantLoop[1].TempSetPointNodeNum = 2
    var heatBranch2 = self.state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Supply].Branch[1]
    var heatComp2 = self.state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Supply].Branch[1].Comp[0]
    heatComp2.Type = DataPlant.PlantEquipmentType.HeatPumpEIRHeating
    heatComp2.Name = "AWHP_2 Heating Side"
    heatBranch2.NodeNumIn = 3
    heatBranch2.NodeNumOut = 4
    heatComp2.NodeNumIn = 3
    heatComp2.NodeNumOut = 4
    var coolBranch1 = self.state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].Branch[0]
    var coolComp1 = self.state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].Branch[0].Comp[0]
    coolComp1.Type = DataPlant.PlantEquipmentType.HeatPumpEIRCooling
    coolComp1.Name = "AWHP_1 Cooling Side"
    coolBranch1.NodeNumIn = 5
    coolBranch1.NodeNumOut = 6
    coolComp1.NodeNumIn = 5
    coolComp1.NodeNumOut = 6
    self.state.dataPlnt.PlantLoop[0].TempSetPointNodeNum = 6
    var coolBranch2 = self.state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].Branch[1]
    var coolComp2 = self.state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].Branch[1].Comp[0]
    coolComp2.Type = DataPlant.PlantEquipmentType.HeatPumpEIRCooling
    coolComp2.Name = "AWHP_2 Cooling Side"
    coolBranch2.NodeNumIn = 7
    coolBranch2.NodeNumOut = 8
    coolComp2.NodeNumIn = 7
    coolComp2.NodeNumOut = 8
    self.state.dataAirLoop.AirToZoneNodeInfo[0].AirLoopReturnNodeNum[0] = 9
    self.state.dataLoopNodes.Node.resize(10)
    var FirstHVACIteration: Bool = False
    var CurrentModuleObject: String = "PlantEquipmentOperation:ChillerHeaterChangeover"
    PlantCondLoopOperation.InitLoadDistribution(self.state, FirstHVACIteration)
    var chillerHeaterSupervisor = self.state.dataPlantCondLoopOp.ChillerHeaterSupervisoryOperationSchemes[0]
    expect_true(chillerHeaterSupervisor.oneTimeSetupComplete)  # getInput completed
    expect_eq(1, chillerHeaterSupervisor.PlantOps.NumOfAirLoops)
    expect_eq(0, chillerHeaterSupervisor.PlantOps.numPlantLoadProfiles)
    expect_eq(2, chillerHeaterSupervisor.PlantOps.NumHeatingOnlyEquipLists)
    expect_eq(2, chillerHeaterSupervisor.PlantOps.NumCoolingOnlyEquipLists)
    expect_eq(1, chillerHeaterSupervisor.PlantOps.NumSimultHeatCoolHeatingEquipLists)
    expect_eq(1, chillerHeaterSupervisor.PlantOps.NumSimultHeatCoolCoolingEquipLists)
    expect_true(chillerHeaterSupervisor.PlantOps.SimultHeatCoolOpAvailable)
    expect_near(6.60, chillerHeaterSupervisor.Setpoint.PrimCW, 0.001)      # cooling set point temperature
    expect_near(59.8, chillerHeaterSupervisor.Setpoint.PrimHW_High, 0.001) # heating set point temperature
    expect_near(37.6, chillerHeaterSupervisor.Setpoint.PrimHW_Low, 0.001)  # heating set point temperature
    expect_near(13.7, chillerHeaterSupervisor.Setpoint.SecCW, 0.001)       # cooling set point temperature
    expect_near(45.0, chillerHeaterSupervisor.Setpoint.SecHW, 0.001)       # cooling set point temperature
    expect_near(0.00, chillerHeaterSupervisor.TempReset.LowOutdoorTemp, 0.001)
    expect_near(10.0, chillerHeaterSupervisor.TempReset.HighOutdoorTemp, 0.001)
    expect_eq(1, chillerHeaterSupervisor.ZonePtrs[0])
    expect_eq(2, chillerHeaterSupervisor.ZonePtrs[1])
    expect_eq(3, chillerHeaterSupervisor.ZonePtrs[2])
    expect_eq(4, chillerHeaterSupervisor.ZonePtrs[3])
    FirstHVACIteration = True
    var thisSupervisor = self.state.dataPlnt.PlantLoop[0].OpScheme[0].ChillerHeaterSupervisoryOperation
    thisSupervisor.EvaluateChillerHeaterChangeoverOpScheme(self.state)
    expect_eq(0, chillerHeaterSupervisor.Report.AirSourcePlant_OpMode)  # off
    expect_near(0.0, chillerHeaterSupervisor.Report.BuildingPolledCoolingLoad, 0.001)
    expect_near(0.0, chillerHeaterSupervisor.Report.BuildingPolledHeatingLoad, 0.001)
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[chillerHeaterSupervisor.ZonePtrs[0] - 1].OutputRequiredToHeatingSP = 100.0
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[chillerHeaterSupervisor.ZonePtrs[1] - 1].OutputRequiredToHeatingSP = 200.0
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[chillerHeaterSupervisor.ZonePtrs[2] - 1].OutputRequiredToHeatingSP = 300.0
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[chillerHeaterSupervisor.ZonePtrs[3] - 1].OutputRequiredToHeatingSP = 400.0
    self.state.dataLoopNodes.Node[heatBranch1.NodeNumIn - 1].MassFlowRate = 0.001  # set fake HW plant flow rate
    thisSupervisor.EvaluateChillerHeaterChangeoverOpScheme(self.state)
    expect_eq(1, chillerHeaterSupervisor.Report.AirSourcePlant_OpMode)  # heating
    expect_near(0.0, chillerHeaterSupervisor.Report.BuildingPolledCoolingLoad, 0.001)
    expect_near(1000.0, chillerHeaterSupervisor.Report.BuildingPolledHeatingLoad, 0.001)
    expect_near(0.0, chillerHeaterSupervisor.Report.PrimaryPlantCoolingLoad, 0.001)
    expect_near(158.559, chillerHeaterSupervisor.Report.PrimaryPlantHeatingLoad, 0.001)
    var eqcool = chillerHeaterSupervisor.CoolingOnlyEquipList[0].Comp[0]
    self.state.dataLoopNodes.Node[eqcool.DemandNodeNum - 1].Temp = 10.0
    var eqheat = chillerHeaterSupervisor.HeatingOnlyEquipList[0].Comp[0]
    var thisCoolEq1 = self.state.dataPlnt.PlantLoop[0].LoopSide[eqcool.LoopSideNumPtr].Branch[eqcool.BranchNumPtr - 1].Comp[eqcool.CompNumPtr - 1].ON
    var thisHeatEq1 = self.state.dataPlnt.PlantLoop[1].LoopSide[eqheat.LoopSideNumPtr].Branch[eqheat.BranchNumPtr - 1].Comp[eqheat.CompNumPtr - 1].ON
    expect_false(thisCoolEq1)  # cooling equipment is not active
    expect_true(thisHeatEq1)   # heating equipment active
    expect_eq(self.state.dataPlnt.PlantLoop[0].Name, "Cooling Plant")
    expect_eq(self.state.dataPlnt.PlantLoop[1].Name, "Heating Plant")
    expect_near(0.0, chillerHeaterSupervisor.Report.PrimaryPlantCoolingLoad, 0.001)
    expect_near(158.559, chillerHeaterSupervisor.Report.PrimaryPlantHeatingLoad, 0.001)
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[chillerHeaterSupervisor.ZonePtrs[0] - 1].OutputRequiredToHeatingSP = 0.0
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[chillerHeaterSupervisor.ZonePtrs[1] - 1].OutputRequiredToHeatingSP = 0.0
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[chillerHeaterSupervisor.ZonePtrs[2] - 1].OutputRequiredToHeatingSP = 0.0
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[chillerHeaterSupervisor.ZonePtrs[3] - 1].OutputRequiredToHeatingSP = 0.0
    self.state.dataLoopNodes.Node[heatBranch1.NodeNumIn - 1].MassFlowRate = 0.0  # set HW plant flow rate
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[chillerHeaterSupervisor.ZonePtrs[0] - 1].OutputRequiredToCoolingSP = 100.0
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[chillerHeaterSupervisor.ZonePtrs[1] - 1].OutputRequiredToCoolingSP = 200.0
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[chillerHeaterSupervisor.ZonePtrs[2] - 1].OutputRequiredToCoolingSP = 300.0
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[chillerHeaterSupervisor.ZonePtrs[3] - 1].OutputRequiredToCoolingSP = 400.0
    self.state.dataLoopNodes.Node[coolBranch1.NodeNumIn - 1].MassFlowRate = 0.0  # set CW plant flow rate
    thisSupervisor.EvaluateChillerHeaterChangeoverOpScheme(self.state)
    expect_eq(0, chillerHeaterSupervisor.Report.AirSourcePlant_OpMode)  # off
    expect_near(0.0, chillerHeaterSupervisor.Report.BuildingPolledCoolingLoad, 0.001)
    expect_near(0.0, chillerHeaterSupervisor.Report.BuildingPolledHeatingLoad, 0.001)
    expect_near(0.0, chillerHeaterSupervisor.Report.PrimaryPlantCoolingLoad, 0.001)
    expect_near(0.0, chillerHeaterSupervisor.Report.PrimaryPlantHeatingLoad, 0.001)
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[chillerHeaterSupervisor.ZonePtrs[0] - 1].OutputRequiredToCoolingSP = -100.0
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[chillerHeaterSupervisor.ZonePtrs[1] - 1].OutputRequiredToCoolingSP = -200.0
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[chillerHeaterSupervisor.ZonePtrs[2] - 1].OutputRequiredToCoolingSP = -300.0
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[chillerHeaterSupervisor.ZonePtrs[3] - 1].OutputRequiredToCoolingSP = -400.0
    self.state.dataLoopNodes.Node[coolBranch1.NodeNumIn - 1].MassFlowRate = 0.001  # set fake CW plant flow rate
    thisSupervisor.EvaluateChillerHeaterChangeoverOpScheme(self.state)
    expect_eq(2, chillerHeaterSupervisor.Report.AirSourcePlant_OpMode)  # cooling
    expect_near(-1000.0, chillerHeaterSupervisor.Report.BuildingPolledCoolingLoad, 0.001)
    expect_near(0.0, chillerHeaterSupervisor.Report.BuildingPolledHeatingLoad, 0.001)
    var thisCoolEq2 = self.state.dataPlnt.PlantLoop[0].LoopSide[eqcool.LoopSideNumPtr].Branch[eqcool.BranchNumPtr - 1].Comp[eqcool.CompNumPtr - 1].ON
    var thisHeatEq2 = self.state.dataPlnt.PlantLoop[1].LoopSide[eqheat.LoopSideNumPtr].Branch[eqheat.BranchNumPtr - 1].Comp[eqheat.CompNumPtr - 1].ON
    expect_false(thisHeatEq2)  # heating equipment is not active
    expect_true(thisCoolEq2)   # cooling equipment active
    expect_near(-14.249, chillerHeaterSupervisor.Report.PrimaryPlantCoolingLoad, 0.001)
    expect_near(0.0, chillerHeaterSupervisor.Report.PrimaryPlantHeatingLoad, 0.001)
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[chillerHeaterSupervisor.ZonePtrs[0] - 1].OutputRequiredToHeatingSP = 100.0
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[chillerHeaterSupervisor.ZonePtrs[1] - 1].OutputRequiredToHeatingSP = 200.0
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[chillerHeaterSupervisor.ZonePtrs[2] - 1].OutputRequiredToHeatingSP = 300.0
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[chillerHeaterSupervisor.ZonePtrs[3] - 1].OutputRequiredToHeatingSP = 400.0
    self.state.dataLoopNodes.Node[heatBranch1.NodeNumIn - 1].MassFlowRate = 0.001  # set fake HW plant flow rate
    thisSupervisor.EvaluateChillerHeaterChangeoverOpScheme(self.state)
    expect_eq(3, chillerHeaterSupervisor.Report.AirSourcePlant_OpMode)  # simultaneous cooling and heating
    expect_near(-1000.0, chillerHeaterSupervisor.Report.BuildingPolledCoolingLoad, 0.001)
    expect_near(1000.0, chillerHeaterSupervisor.Report.BuildingPolledHeatingLoad, 0.001)
    expect_near(-14.249, chillerHeaterSupervisor.Report.PrimaryPlantCoolingLoad, 0.001)
    expect_near(158.559, chillerHeaterSupervisor.Report.PrimaryPlantHeatingLoad, 0.001)

def SupervisoryControlLogicForAirSourcePlantsTest(inout self: DistributeEquipOpTest):
    let idf_objects: String = """
      PlantEquipmentOperationSchemes,
        Cooling Loop Operation Scheme List, !- Name
        PlantEquipmentOperation:ChillerHeaterChangeover, !- Control Scheme 1 Object Type
        Two AWHP Operation Scheme,         !- Control Scheme 1 Name
        ALWAYS_ON;                         !- Control Scheme 1 Schedule Name
      PlantEquipmentOperationSchemes,
        Heating Loop Operation Scheme List, !- Name
        PlantEquipmentOperation:ChillerHeaterChangeover,  !- Control Scheme 1 Object Type
        Two AWHP Operation Scheme,         !- Control Scheme 1 Name
        ALWAYS_ON;                         !- Control Scheme 1 Schedule Name
      Schedule:Compact, ALWAYS_ON, On/Off, Through: 12/31, For: AllDays, Until: 24:00,1;
      PlantEquipmentOperation:ChillerHeaterChangeover,
        Two AWHP Operation Scheme ,          !- Name
        6.6 ,                                !- Primary Cooling Plant Setpoint Temperature
        13.7,                                !- Secondary Distribution Cooling Plant Setpoint Temperature
        59.8 ,                               !- Primary Heating Plant Setpoint at Outdoor High Temperature
        10.0,                                !- Outdoor High Temperature
        37.6 ,                               !- Primary Heating Plant Setpoint at Outdoor Low Temperature
        0.0 ,                                !- Outdoor Low Temperature
        45.0 ,                               !- Secondary Distribution Heating Plant Setpoint Temperature
        This Zone List,                      !- Zone Load Polling ZoneList Name
        One AWHP Cooling Operation Scheme,   !- Cooling Only Load Plant Equipment Operation Cooling Load Name
        One AWHP Heating Operation Scheme,   !- Heating Only Load Plant Equipment Operation Heating Load Name
        ,                                    !- Simultaneous Cooling And Heating Plant Equipment Operation Cooling Load Name
        ,                                    !- Simultaneous Cooling And Heating Plant Equipment Operation Heating Load Name
        ,                                    !- Dedicated Chilled Water Return Recovery HeatPump Name
        ,                                    !- Dedicated Hot Water Return Recovery HeatPump Name
        1.0;                                 !-  Dedicated Recovery Heat Pump Control Load Capacity Factor
      PlantEquipmentOperation:CoolingLoad,
        One AWHP Cooling Operation Scheme, !- Name
        0.0,                               !- Load Range 1 Lower Limit {W}
        10000000000000000,                 !- Load Range 1 Upper Limit {W}
        One AWHP Cooling Equipment List;   !- Range 1 Equipment List Name
      PlantEquipmentList,
        One AWHP Cooling Equipment List,   !- Name
        HeatPump:PlantLoop:EIR:Cooling,    !- Equipment 1 Object Type
        AWHP_1 Cooling Side;               !- Equipment 1 Name
      PlantEquipmentOperation:HeatingLoad,
        One AWHP Heating Operation Scheme, !- Name
        0.0,                               !- Load Range 1 Lower Limit {W}
        10000000000000000,                 !- Load Range 1 Upper Limit {W}
        One AWHP Heating Equipment List;   !- Range 1 Equipment List Name
      PlantEquipmentList,
        One AWHP Heating Equipment List,   !- Name
        HeatPump:PlantLoop:EIR:Heating,    !- Equipment 1 Object Type
        AWHP_1 Heating Side;               !- Equipment 1 Name
      ZoneList,
        This Zone List,                    !- Name
        Zone1,                             !- Zone Name 1
        Zone2,                             !- Zone Name 2
        Zone3,                             !- Zone Name 3
        Zone4;                             !- Zone Name 4
     """
    assert_true(process_idf(idf_objects))
    self.state.init_state(self.state)
    var heatBranch1 = self.state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Supply].Branch[0]
    var heatComp1 = self.state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Supply].Branch[0].Comp[0]
    heatComp1.Type = DataPlant.PlantEquipmentType.HeatPumpEIRHeating
    heatComp1.Name = "AWHP_1 Heating Side"
    heatBranch1.NodeNumIn = 1
    heatBranch1.NodeNumOut = 2
    heatComp1.NodeNumIn = 1
    heatComp1.NodeNumOut = 2
    self.state.dataPlnt.PlantLoop[1].TempSetPointNodeNum = 2
    var coolBranch1 = self.state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].Branch[0]
    var coolComp1 = self.state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].Branch[0].Comp[0]
    coolComp1.Type = DataPlant.PlantEquipmentType.HeatPumpEIRCooling
    coolComp1.Name = "AWHP_1 Cooling Side"
    coolBranch1.NodeNumIn = 5
    coolBranch1.NodeNumOut = 6
    coolComp1.NodeNumIn = 5
    coolComp1.NodeNumOut = 6
    self.state.dataPlnt.PlantLoop[0].TempSetPointNodeNum = 6
    self.state.dataAirLoop.AirToZoneNodeInfo[0].AirLoopReturnNodeNum[0] = 9
    self.state.dataLoopNodes.Node.resize(10)
    var FirstHVACIteration: Bool = False
    var CurrentModuleObject: String = "PlantEquipmentOperation:ChillerHeaterChangeover"
    PlantCondLoopOperation.InitLoadDistribution(self.state, FirstHVACIteration)
    expect_eq(self.state.dataPlnt.PlantLoop[0].Name, "Cooling Plant")
    expect_eq(self.state.dataPlnt.PlantLoop[1].Name, "Heating Plant")
    var chillerHeaterSupervisor = self.state.dataPlantCondLoopOp.ChillerHeaterSupervisoryOperationSchemes[0]
    expect_true(chillerHeaterSupervisor.oneTimeSetupComplete)  # getInput completed
    expect_eq(1, chillerHeaterSupervisor.PlantOps.NumOfAirLoops)
    expect_eq(0, chillerHeaterSupervisor.PlantOps.numPlantLoadProfiles)
    expect_eq(1, chillerHeaterSupervisor.PlantOps.NumHeatingOnlyEquipLists)
    expect_eq(1, chillerHeaterSupervisor.PlantOps.NumCoolingOnlyEquipLists)
    expect_eq(0, chillerHeaterSupervisor.PlantOps.NumSimultHeatCoolHeatingEquipLists)
    expect_eq(0, chillerHeaterSupervisor.PlantOps.NumSimultHeatCoolCoolingEquipLists)
    expect_false(chillerHeaterSupervisor.PlantOps.SimultHeatCoolOpAvailable)
    expect_near(6.60, chillerHeaterSupervisor.Setpoint.PrimCW, 0.001)      # cooling set point temperature
    expect_near(59.8, chillerHeaterSupervisor.Setpoint.PrimHW_High, 0.001) # heating set point temperature
    expect_near(37.6, chillerHeaterSupervisor.Setpoint.PrimHW_Low, 0.001)  # heating set point temperature
    expect_near(13.7, chillerHeaterSupervisor.Setpoint.SecCW, 0.001)       # cooling set point temperature
    expect_near(45.0, chillerHeaterSupervisor.Setpoint.SecHW, 0.001)       # cooling set point temperature
    expect_near(0.00, chillerHeaterSupervisor.TempReset.LowOutdoorTemp, 0.001)
    expect_near(10.0, chillerHeaterSupervisor.TempReset.HighOutdoorTemp, 0.001)
    expect_eq(1, chillerHeaterSupervisor.ZonePtrs[0])
    expect_eq(2, chillerHeaterSupervisor.ZonePtrs[1])
    expect_eq(3, chillerHeaterSupervisor.ZonePtrs[2])
    expect_eq(4, chillerHeaterSupervisor.ZonePtrs[3])
    FirstHVACIteration = True
    var thisSupervisor = self.state.dataPlnt.PlantLoop[0].OpScheme[0].ChillerHeaterSupervisoryOperation
    thisSupervisor.EvaluateChillerHeaterChangeoverOpScheme(self.state)
    expect_eq(0, chillerHeaterSupervisor.Report.AirSourcePlant_OpMode)  # off
    expect_near(0.0, chillerHeaterSupervisor.Report.BuildingPolledCoolingLoad, 0.001)
    expect_near(0.0, chillerHeaterSupervisor.Report.BuildingPolledHeatingLoad, 0.001)
    var eqheat = chillerHeaterSupervisor.HeatingOnlyEquipList[0].Comp[0]
    var eqcool = chillerHeaterSupervisor.CoolingOnlyEquipList[0].Comp[0]
    var CoolEq1_status = self.state.dataPlnt.PlantLoop[0].LoopSide[eqcool.LoopSideNumPtr].Branch[eqcool.BranchNumPtr - 1].Comp[eqcool.CompNumPtr - 1].ON
    var HeatEq1_status = self.state.dataPlnt.PlantLoop[1].LoopSide[eqheat.LoopSideNumPtr].Branch[eqheat.BranchNumPtr - 1].Comp[eqheat.CompNumPtr - 1].ON
    self.state.dataLoopNodes.Node[eqcool.DemandNodeNum - 1].Temp = 10.0
    var zone1SysEnergyDemand = self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[chillerHeaterSupervisor.ZonePtrs[0] - 1]
    var zone2SysEnergyDemand = self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[chillerHeaterSupervisor.ZonePtrs[1] - 1]
    var zone3SysEnergyDemand = self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[chillerHeaterSupervisor.ZonePtrs[2] - 1]
    var zone4SysEnergyDemand = self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[chillerHeaterSupervisor.ZonePtrs[3] - 1]
    zone1SysEnergyDemand.OutputRequiredToHeatingSP = 100.0
    zone2SysEnergyDemand.OutputRequiredToHeatingSP = 200.0
    zone3SysEnergyDemand.OutputRequiredToHeatingSP = 300.0
    zone4SysEnergyDemand.OutputRequiredToHeatingSP = 400.0
    self.state.dataLoopNodes.Node[heatBranch1.NodeNumIn - 1].MassFlowRate = 0.00189204
    thisSupervisor.EvaluateChillerHeaterChangeoverOpScheme(self.state)
    expect_eq(1, chillerHeaterSupervisor.Report.AirSourcePlant_OpMode)  # heating
    expect_near(0.0, chillerHeaterSupervisor.Report.BuildingPolledCoolingLoad, 0.001)
    expect_near(1000.0, chillerHeaterSupervisor.Report.BuildingPolledHeatingLoad, 0.001)
    expect_near(0.0, chillerHeaterSupervisor.Report.PrimaryPlantCoolingLoad, 0.001)
    expect_near(300.0, chillerHeaterSupervisor.Report.PrimaryPlantHeatingLoad, 0.001)
    expect_true(chillerHeaterSupervisor.PlantOps.AirSourcePlantHeatingOnly)
    expect_false(chillerHeaterSupervisor.PlantOps.AirSourcePlantCoolingOnly)
    expect_false(CoolEq1_status)  # cooling equipment is not active
    expect_true(HeatEq1_status)   # heating equipment is active
    zone1SysEnergyDemand.OutputRequiredToHeatingSP = 0.0
    zone2SysEnergyDemand.OutputRequiredToHeatingSP = 0.0
    zone3SysEnergyDemand.OutputRequiredToHeatingSP = 0.0
    zone4SysEnergyDemand.OutputRequiredToHeatingSP = 0.0
    self.state.dataLoopNodes.Node[heatBranch1.NodeNumIn - 1].MassFlowRate = 0.0
    zone1SysEnergyDemand.OutputRequiredToCoolingSP = -100.0
    zone2SysEnergyDemand.OutputRequiredToCoolingSP = -200.0
    zone3SysEnergyDemand.OutputRequiredToCoolingSP = -300.0
    zone4SysEnergyDemand.OutputRequiredToCoolingSP = -400.0
    self.state.dataLoopNodes.Node[coolBranch1.NodeNumIn - 1].MassFlowRate = 0.00002
    thisSupervisor.EvaluateChillerHeaterChangeoverOpScheme(self.state)
    expect_near(-1000.0, chillerHeaterSupervisor.Report.BuildingPolledCoolingLoad, 0.001)
    expect_near(0.0, chillerHeaterSupervisor.Report.BuildingPolledHeatingLoad, 0.001)
    expect_near(-0.28, chillerHeaterSupervisor.Report.PrimaryPlantCoolingLoad, 0.01)
    expect_near(0.0, chillerHeaterSupervisor.Report.PrimaryPlantHeatingLoad, 0.01)
    expect_eq(2, chillerHeaterSupervisor.Report.AirSourcePlant_OpMode)  # cooling plant on
    expect_false(chillerHeaterSupervisor.PlantOps.AirSourcePlantHeatingOnly)
    expect_true(chillerHeaterSupervisor.PlantOps.AirSourcePlantCoolingOnly)
    expect_true(CoolEq1_status)   # cooling equipment is active
    expect_false(HeatEq1_status)  # heating equipment is not active
    zone1SysEnergyDemand.OutputRequiredToHeatingSP = 20.0
    zone2SysEnergyDemand.OutputRequiredToHeatingSP = 40.0
    zone3SysEnergyDemand.OutputRequiredToHeatingSP = 60.0
    zone4SysEnergyDemand.OutputRequiredToHeatingSP = 80.0
    self.state.dataLoopNodes.Node[heatBranch1.NodeNumIn - 1].MassFlowRate = 0.0189204
    thisSupervisor.EvaluateChillerHeaterChangeoverOpScheme(self.state)
    expect_near(-1000.0, chillerHeaterSupervisor.Report.BuildingPolledCoolingLoad, 0.001)
    expect_near(200.0, chillerHeaterSupervisor.Report.BuildingPolledHeatingLoad, 0.001)
    expect_near(-0.28, chillerHeaterSupervisor.Report.PrimaryPlantCoolingLoad, 0.01)
    expect_near(3000.0, chillerHeaterSupervisor.Report.PrimaryPlantHeatingLoad, 0.01)
    expect_eq(1, chillerHeaterSupervisor.Report.AirSourcePlant_OpMode)  # heating plant on
    expect_true(chillerHeaterSupervisor.PlantOps.AirSourcePlantHeatingOnly)
    expect_false(chillerHeaterSupervisor.PlantOps.AirSourcePlantCoolingOnly)
    expect_false(CoolEq1_status)  # cooling equipment is not active
    expect_true(HeatEq1_status)   # heating equipment is active