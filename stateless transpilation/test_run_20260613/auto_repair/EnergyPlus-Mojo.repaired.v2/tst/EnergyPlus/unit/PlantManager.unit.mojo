from gtest import Test, TestFixture, EXPECT_EQ, EXPECT_ENUM_EQ, ASSERT_TRUE, ASSERT_FALSE
from ObjexxFCL.Fmath import *
from .Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataBranchNodeConnections import *
from EnergyPlus.DataLoopNode import *
from EnergyPlus.DataSizing import *
from EnergyPlus.EMSManager import *
from EnergyPlus.OutAirNodeManager import *
from EnergyPlus.Plant.PlantManager import *
from EnergyPlus.ScheduleManager import *
from EnergyPlus.SetPointManager import *
from EnergyPlus.UserDefinedComponents import *

alias EnergyPlus = __import__("EnergyPlus")
alias PlantManager = EnergyPlus.Plant.PlantManager
alias UserDefinedComponents = EnergyPlus.UserDefinedComponents

using DataPlant = __import__("EnergyPlus.DataPlant")
using DataSizing = __import__("EnergyPlus.DataSizing")
using SetPointManager = __import__("EnergyPlus.SetPointManager")

@register_test(EnergyPlusFixture)
class PlantManager_SizePlantLoopTest(Test):
    def __init__(self):
        super().__init__()
        self.state = EnergyPlusFixture.state

    def run(self):
        self.state.init_state(self.state)
        self.state.dataPlnt.PlantLoop.allocate(1)
        self.state.dataPlnt.PlantLoop[0].VolumeWasAutoSized = True
        self.state.dataPlnt.PlantLoop[0].MaxVolFlowRate = 5
        self.state.dataPlnt.PlantLoop[0].CirculationTime = 2
        self.state.dataPlnt.PlantLoop[0].FluidType = Node.FluidType.Water
        self.state.dataPlnt.PlantLoop[0].TypeOfLoop = LoopType.Plant
        self.state.dataPlnt.PlantLoop[0].glycol = Fluid.GetWater(self.state)
        SizePlantLoop(self.state, 1, True)
        var TestVolume: Int = 600
        EXPECT_EQ(TestVolume, self.state.dataPlnt.PlantLoop[0].Volume)

@register_test(EnergyPlusFixture)
class PlantManager_TwoWayCommonPipeSetPointManagerTest(Test):
    def __init__(self):
        super().__init__()
        self.state = EnergyPlusFixture.state

    def run(self):
        var ErrorsFound: Bool = False
        var idf_objects: String = delimited_string([
            "  PlantLoop,",
            "    Chilled Water Loop,      !- Name",
            "    Water,                   !- Fluid Type",
            "    ,                        !- User Defined Fluid Type",
            "    Chilled Water Loop Operation,  !- Plant Equipment Operation Scheme Name",
            "    Chilled Water Loop Supply Outlet,  !- Loop Temperature Setpoint Node Name",
            "    98,                      !- Maximum Loop Temperature {C}",
            "    1,                       !- Minimum Loop Temperature {C}",
            "    0.12396E-02,             !- Maximum Loop Flow Rate {m3/s}",
            "    0,                       !- Minimum Loop Flow Rate {m3/s}",
            "    autocalculate,           !- Plant Loop Volume {m3}",
            "    Chilled Water Loop Supply Inlet,  !- Plant Side Inlet Node Name",
            "    Chilled Water Loop Supply Outlet,  !- Plant Side Outlet Node Name",
            "    Chilled Water Loop Supply Side Branches,  !- Plant Side Branch List Name",
            "    Chilled Water Loop Supply Side Connectors,  !- Plant Side Connector List Name",
            "    Chilled Water Loop Demand Inlet,  !- Demand Side Inlet Node Name",
            "    Chilled Water Loop Demand Outlet,  !- Demand Side Outlet Node Name",
            "    Chilled Water Loop Demand Side Branches,  !- Demand Side Branch List Name",
            "    Chilled Water Loop Demand Side Connectors,  !- Demand Side Connector List Name",
            "    SequentialLoad,          !- Load Distribution Scheme",
            "    ,                        !- Availability Manager List Name",
            "    SingleSetPoint,          !- Plant Loop Demand Calculation Scheme",
            "    TwoWayCommonPipe;        !- Common Pipe Simulation",
            "  BranchList,",
            "    Chilled Water Loop Supply Side Branches,  !- Name",
            "    Chilled Water Loop Supply Inlet Branch,  !- Branch 1 Name",
            "    Main Chiller ChW Branch, !- Branch 2 Name",
            "    Chilled Water Loop Supply Bypass Branch,  !- Branch 3 Name",
            "    Chilled Water Loop Supply Outlet Branch;  !- Branch 4 Name",
            "  Branch,",
            "    Chilled Water Loop Supply Inlet Branch,  !- Name",
            "    ,                        !- Pressure Drop Curve Name",
            "    Pump:ConstantSpeed,      !- Component 1 Object Type",
            "    Chilled Water Loop Pri Supply Pump,  !- Component 1 Name",
            "    Chilled Water Loop Supply Inlet,  !- Component 1 Inlet Node Name",
            "    Chilled Water Loop Pri Pump Outlet;  !- Component 1 Outlet Node Name",
            "  Branch,",
            "    Chilled Water Loop Supply Outlet Branch,  !- Name",
            "    ,                        !- Pressure Drop Curve Name",
            "    Pipe:Adiabatic,          !- Component 1 Object Type",
            "    Chilled Water Loop Supply Outlet Pipe,  !- Component 1 Name",
            "    Chilled Water Loop Supply Outlet Pipe Inlet,  !- Component 1 Inlet Node Name",
            "    Chilled Water Loop Supply Outlet;  !- Component 1 Outlet Node Name",
            "  Pipe:Adiabatic,",
            "    Chilled Water Loop Supply Outlet Pipe,  !- Name",
            "    Chilled Water Loop Supply Outlet Pipe Inlet,  !- Inlet Node Name",
            "    Chilled Water Loop Supply Outlet;  !- Outlet Node Name",
            "  BranchList,",
            "    Chilled Water Loop Demand Side Branches,  !- Name",
            "    Chilled Water Loop Demand Inlet Branch,  !- Branch 1 Name",
            "    VAV Sys 1 Cooling Coil ChW Branch,  !- Branch 2 Name",
            "    Chilled Water Loop Demand Bypass Branch,  !- Branch 3 Name",
            "    Chilled Water Loop Demand Outlet Branch;  !- Branch 4 Name",
            "  Branch,",
            "    Chilled Water Loop Demand Inlet Branch,  !- Name",
            "    ,                        !- Pressure Drop Curve Name",
            "    Pump:VariableSpeed,      !- Component 1 Object Type",
            "    Chilled Water Loop Demand Pump,  !- Component 1 Name",
            "    Chilled Water Loop Demand Inlet,  !- Component 1 Inlet Node Name",
            "    Chilled Water Loop Demand Pump Outlet;  !- Component 1 Outlet Node Name",
            "  Branch,",
            "    Chilled Water Loop Demand Outlet Branch,  !- Name",
            "    ,                        !- Pressure Drop Curve Name",
            "    Pipe:Adiabatic,          !- Component 1 Object Type",
            "    Chilled Water Loop Demand Outlet Pipe,  !- Component 1 Name",
            "    Chilled Water Loop Demand Outlet Pipe Inlet,  !- Component 1 Inlet Node Name",
            "    Chilled Water Loop Demand Outlet;  !- Component 1 Outlet Node Name",
            "  Pipe:Adiabatic,",
            "    Chilled Water Loop Demand Outlet Pipe,  !- Name",
            "    Chilled Water Loop Demand Outlet Pipe Inlet,  !- Inlet Node Name",
            "    Chilled Water Loop Demand Outlet;  !- Outlet Node Name",
            "  Schedule:Compact,",
            "    COMPACT HVAC-ALWAYS 5.0, !- Name",
            "    COMPACT HVAC Any Number, !- Schedule Type Limits Name",
            "    Through: 12/31,          !- Field 1",
            "    For: AllDays,            !- Field 2",
            "    Until: 24:00,5.0;        !- Field 3",
            "  SetpointManager:Scheduled,",
            "    Chilled Water Primary Loop Setpoint Manager,  !- Name",
            "    Temperature,             !- Control Variable",
            "    COMPACT HVAC-ALWAYS 5.0, !- Schedule Name",
            "    Chilled Water Loop Supply Outlet;  !- Setpoint Node or NodeList Name",
            "  Schedule:Compact,",
            "    COMPACT HVAC-ALWAYS 8.00,!- Name",
            "    COMPACT HVAC Any Number, !- Schedule Type Limits Name",
            "    Through: 12/31,          !- Field 1",
            "    For: AllDays,            !- Field 2",
            "    Until: 24:00,8.00;       !- Field 3",
            " SetpointManager:OutdoorAirReset,",
            "    Chilled Water Secondary Loop Setpoint Manager,  !- Name",
            "    Temperature,             !- Control Variable",
            "    11.11,                   !- Setpoint at Outdoor Low Temperature {C}",
            "    7.22,                    !- Outdoor Low Temperature {C}",
            "    7.22,                    !- Setpoint at Outdoor High Temperature {C}",
            "    29.44,                   !- Outdoor High Temperature {C}",
            "    Chilled Water Loop Supply inlet;  !- Setpoint Node or NodeList Name",
        ])
        ASSERT_TRUE(process_idf(idf_objects))
        self.state.init_state(self.state)
        GetPlantLoopData(self.state)
        ASSERT_FALSE(ErrorsFound)
        EXPECT_EQ(2, self.state.dataSetPointManager.spms.size())  # SetpointManager:Scheduled
        EXPECT_EQ(Int(self.state.dataSetPointManager.spms[0].ctrlVar), Int(HVAC.CtrlVarType.Temp))
        EXPECT_EQ(self.state.dataLoopNodes.NodeID(self.state.dataSetPointManager.spms[0].ctrlNodeNums[0]), "CHILLED WATER LOOP SUPPLY OUTLET")
        EXPECT_EQ(Int(self.state.dataSetPointManager.spms[1].ctrlVar), Int(HVAC.CtrlVarType.Temp))
        EXPECT_EQ(self.state.dataLoopNodes.NodeID(self.state.dataSetPointManager.spms[1].ctrlNodeNums[0]), "CHILLED WATER LOOP SUPPLY INLET")

@register_test(EnergyPlusFixture)
class PlantManager_SizePlantLoop_CorrectTempReportTest(Test):
    def __init__(self):
        super().__init__()
        self.state = EnergyPlusFixture.state

    def run(self):
        var loopNum: Int = 1
        var okToFinish: Bool = False
        self.state.dataPlnt.PlantLoop.allocate(1)
        self.state.dataPlnt.PlantLoop[0].PlantSizNum = 1
        self.state.dataPlantMgr.GetCompSizFac = False
        self.state.dataSize.PlantSizData.allocate(1)
        self.state.dataPlnt.PlantLoop[0].LoopSide[LoopSideLocation.Demand].TotalBranches = 0
        self.state.dataPlnt.PlantLoop[0].MaxVolFlowRate = 0.0
        self.state.dataPlnt.PlantLoop[0].MaxVolFlowRateWasAutoSized = False
        self.state.dataPlnt.PlantLoop[0].VolumeWasAutoSized = True
        self.state.dataPlnt.PlantLoop[0].CirculationTime = 1.0
        self.state.dataPlnt.PlantFinalSizesOkayToReport = True
        self.state.dataPlnt.PlantLoop[0].MinVolFlowRate = 0.0
        self.state.dataPlnt.PlantLoop[0].FluidType = Node.FluidType.Steam
        self.state.dataSize.PlantSizData[0].DesVolFlowRate = 1.0
        self.state.dataSize.PlantSizData[0].DeltaT = 5.0
        self.state.dataSize.PlantSizData[0].ExitTemp = 25.0
        self.state.dataPlnt.PlantLoop[0].Name = "A LONG TIME AGO"
        self.state.dataPlnt.PlantLoop[0].TypeOfLoop = LoopType.Plant
        self.state.dataSize.PlantSizData[0].LoopType = DataSizing.TypeOfPlantLoop.Heating
        self.state.dataPlnt.PlantLoop[0].Name = "HOTH"
        SizePlantLoop(self.state, loopNum, okToFinish)
        var heating_eio_output: String = "PlantLoop, HOTH, Design Return Temperature [C], 20.0"
        compare_eio_stream_substring(heating_eio_output, True)
        self.state.dataPlnt.PlantLoop[0].TypeOfLoop = LoopType.Plant
        self.state.dataSize.PlantSizData[0].LoopType = DataSizing.TypeOfPlantLoop.Cooling
        self.state.dataPlnt.PlantLoop[0].Name = "MUSTAFAR"
        SizePlantLoop(self.state, loopNum, okToFinish)
        var cooling_eio_output: String = "PlantLoop, MUSTAFAR, Design Return Temperature [C], 30.0"
        compare_eio_stream_substring(cooling_eio_output, True)
        self.state.dataPlnt.PlantLoop[0].TypeOfLoop = LoopType.Condenser
        self.state.dataPlnt.PlantLoop[0].Name = "KAMINO"
        SizePlantLoop(self.state, loopNum, okToFinish)
        var condenser_eio_output: String = "CondenserLoop, KAMINO, Design Return Temperature [C], 30.0"
        compare_eio_stream_substring(condenser_eio_output, True)

@register_test(EnergyPlusFixture)
class PlantManager_CheckPlantEquipmentCtrlType(Test):
    def __init__(self):
        super().__init__()
        self.state = EnergyPlusFixture.state

    def run(self):
        EXPECT_EQ(Int(DataPlant.PlantEquipmentCtrlType.size()), Int(DataPlant.PlantEquipmentType.Num))
        var ctrlType: DataPlant.CtrlType = DataPlant.PlantEquipmentCtrlType[Int(DataPlant.PlantEquipmentType.Boiler_Simple)]
        EXPECT_EQ(ctrlType, DataPlant.CtrlType.HeatingOp)
        ctrlType = DataPlant.PlantEquipmentCtrlType[Int(DataPlant.PlantEquipmentType.CoolingPanel_Simple)]
        EXPECT_EQ(ctrlType, DataPlant.CtrlType.Invalid)
        ctrlType = DataPlant.PlantEquipmentCtrlType[Int(DataPlant.PlantEquipmentType.HeatPumpEIRCooling)]
        EXPECT_EQ(ctrlType, DataPlant.CtrlType.CoolingOp)
        ctrlType = DataPlant.PlantEquipmentCtrlType[Int(DataPlant.PlantEquipmentType.HeatPumpEIRHeating)]
        EXPECT_EQ(ctrlType, DataPlant.CtrlType.HeatingOp)
        ctrlType = DataPlant.PlantEquipmentCtrlType[Int(DataPlant.PlantEquipmentType.PurchSteam)]
        EXPECT_EQ(ctrlType, DataPlant.CtrlType.HeatingOp)
        ctrlType = DataPlant.PlantEquipmentCtrlType[Int(DataPlant.PlantEquipmentType.Num) - 1]
        EXPECT_EQ(ctrlType, DataPlant.CtrlType.HeatingOp)
        ctrlType = DataPlant.PlantEquipmentCtrlType[Int(DataPlant.PlantEquipmentType.FluidCooler_SingleSpd)]
        EXPECT_EQ(ctrlType, DataPlant.CtrlType.CoolingOp)
        ctrlType = DataPlant.PlantEquipmentCtrlType[Int(DataPlant.PlantEquipmentType.GrndHtExchgSlinky)]
        EXPECT_EQ(ctrlType, DataPlant.CtrlType.DualOp)
        ctrlType = DataPlant.PlantEquipmentCtrlType[Int(DataPlant.PlantEquipmentType.PurchHotWater)]
        EXPECT_EQ(ctrlType, DataPlant.CtrlType.HeatingOp)

@register_test(EnergyPlusFixture)
class Fix_CoilUserDefined_Test(Test):
    def __init__(self):
        super().__init__()
        self.state = EnergyPlusFixture.state

    def run(self):
        var ErrorsFound: Bool = False
        var idf_objects: String = delimited_string([
            "  Coil:UserDefined,",
            "    CoilUserDef_1, !-Name",
            "    , !-Overall Model Simulation Program Calling Manager Name",
            "    Test Program Calling Manager, !-Model Setup and Sizing Program Calling Manager Name",
            "    2, !-Number of Air Connections",
            "    Primary_Inlet_Node, !-Air Connection 1 Inlet Node Name",
            "    Primary_Outlet_Node, !-Air Connection 1 Outlet Node Name",
            "    Secondary_Inlet_Node, !-Air Connection 2 Inlet Node Name",
            "    Secondary_Outlet_Node, !-Air Connection 2 Outlet Node Name",
            "    No, !-Plant Connection is Used",
            "    , !-Plant Connection Inlet Node Name",
            "    ; !-Plant Connection Outlet Node Name",
            "  OutdoorAir:Node,",
            "    Test_OA_Node;",
            "  EnergyManagementSystem:Actuator,",
            "    TempSetpointLo,          !- Name",
            "    Test_OA_Node,  !- Actuated Component Unique Name",
            "    System Node Setpoint,    !- Actuated Component Type",
            "    Temperature Minimum Setpoint;    !- Actuated Component Control Type",
            "  EnergyManagementSystem:Actuator,",
            "    TempSetpointHi,          !- Name",
            "    Test_OA_Node,  !- Actuated Component Unique Name",
            "    System Node Setpoint,    !- Actuated Component Type",
            "    Temperature Maximum Setpoint;    !- Actuated Component Control Type",
            "  EnergyManagementSystem:ProgramCallingManager,",
            "    Test Program Calling Manager,  !- Name",
            "    BeginNewEnvironment,  !- EnergyPlus Model Calling Point",
            "    DualSetpointTestControl;  !- Program Name 1",
            "  EnergyManagementSystem:Program,",
            "    DualSetpointTestControl,",
            "    Set TempSetpointLo = 16.0,",
            "    Set TempSetpointHi  = 20.0;",
        ])
        ASSERT_TRUE(process_idf(idf_objects))
        self.state.init_state(self.state)
        OutAirNodeManager.SetOutAirNodes(self.state)
        EMSManager.CheckIfAnyEMS(self.state)
        self.state.dataEMSMgr.FinishProcessingUserInput = True
        var anyRan: Bool
        EMSManager.ManageEMS(self.state, EMSManager.EMSCallFrom.SetupSimulation, anyRan, ObjexxFCL.Optional_int_const())
        EMSManager.ManageEMS(self.state, EMSManager.EMSCallFrom.BeginNewEnvironment, anyRan, ObjexxFCL.Optional_int_const())
        GetUserDefinedPlantComponents(self.state)
        ASSERT_FALSE(ErrorsFound)
        EXPECT_EQ(5, self.state.dataBranchNodeConnections.NumOfNodeConnections)
        EXPECT_ENUM_EQ(Node.CompFluidStream.Primary, self.state.dataBranchNodeConnections.NodeConnections[0].FluidStream)
        EXPECT_ENUM_EQ(Node.ConnectionObjectType.OutdoorAirNode, self.state.dataBranchNodeConnections.NodeConnections[0].ObjectType)
        EXPECT_EQ("OutdoorAir:Node", self.state.dataBranchNodeConnections.NodeConnections[0].ObjectName)
        EXPECT_ENUM_EQ(Node.ConnectionType.OutsideAir, self.state.dataBranchNodeConnections.NodeConnections[0].ConnectionType)
        EXPECT_EQ("TEST_OA_NODE", self.state.dataBranchNodeConnections.NodeConnections[0].NodeName)
        EXPECT_ENUM_EQ(Node.CompFluidStream.Primary, self.state.dataBranchNodeConnections.NodeConnections[1].FluidStream)
        EXPECT_ENUM_EQ(Node.ConnectionObjectType.CoilUserDefined, self.state.dataBranchNodeConnections.NodeConnections[1].ObjectType)
        EXPECT_EQ("COILUSERDEF_1", self.state.dataBranchNodeConnections.NodeConnections[1].ObjectName)
        EXPECT_ENUM_EQ(Node.ConnectionType.Inlet, self.state.dataBranchNodeConnections.NodeConnections[1].ConnectionType)
        EXPECT_EQ("PRIMARY_INLET_NODE", self.state.dataBranchNodeConnections.NodeConnections[1].NodeName)
        EXPECT_ENUM_EQ(Node.CompFluidStream.Primary, self.state.dataBranchNodeConnections.NodeConnections[2].FluidStream)
        EXPECT_ENUM_EQ(Node.ConnectionObjectType.CoilUserDefined, self.state.dataBranchNodeConnections.NodeConnections[2].ObjectType)
        EXPECT_EQ("COILUSERDEF_1", self.state.dataBranchNodeConnections.NodeConnections[2].ObjectName)
        EXPECT_ENUM_EQ(Node.ConnectionType.Outlet, self.state.dataBranchNodeConnections.NodeConnections[2].ConnectionType)
        EXPECT_EQ("PRIMARY_OUTLET_NODE", self.state.dataBranchNodeConnections.NodeConnections[2].NodeName)
        EXPECT_ENUM_EQ(Node.CompFluidStream.Secondary, self.state.dataBranchNodeConnections.NodeConnections[3].FluidStream)
        EXPECT_ENUM_EQ(Node.ConnectionObjectType.CoilUserDefined, self.state.dataBranchNodeConnections.NodeConnections[3].ObjectType)
        EXPECT_EQ("COILUSERDEF_1", self.state.dataBranchNodeConnections.NodeConnections[3].ObjectName)
        EXPECT_ENUM_EQ(Node.ConnectionType.Inlet, self.state.dataBranchNodeConnections.NodeConnections[3].ConnectionType)
        EXPECT_EQ("SECONDARY_INLET_NODE", self.state.dataBranchNodeConnections.NodeConnections[3].NodeName)
        EXPECT_ENUM_EQ(Node.CompFluidStream.Secondary, self.state.dataBranchNodeConnections.NodeConnections[4].FluidStream)
        EXPECT_ENUM_EQ(Node.ConnectionObjectType.CoilUserDefined, self.state.dataBranchNodeConnections.NodeConnections[4].ObjectType)
        EXPECT_EQ("COILUSERDEF_1", self.state.dataBranchNodeConnections.NodeConnections[4].ObjectName)
        EXPECT_ENUM_EQ(Node.ConnectionType.Outlet, self.state.dataBranchNodeConnections.NodeConnections[4].ConnectionType)
        EXPECT_EQ("SECONDARY_OUTLET_NODE", self.state.dataBranchNodeConnections.NodeConnections[4].NodeName)