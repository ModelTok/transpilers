from gtest import Test, TestFixture, EXPECT_TRUE, EXPECT_FALSE, EXPECT_NEAR, ASSERT_TRUE
from Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataEnvironment import DataEnvironment
from EnergyPlus.DataLoopNode import DataLoopNode
from EnergyPlus.EMSManager import EMSManager
from EnergyPlus.HeatBalanceManager import HeatBalanceManager
from EnergyPlus.IOFiles import IOFiles
from EnergyPlus.NodeInputManager import NodeInputManager as Node
from EnergyPlus.OutAirNodeManager import OutAirNodeManager
from EnergyPlus.UtilityRoutines import delimited_string
class TestNodeMoreInfoEMSsensorCheck1(Test):
    def run(self, state: EnergyPlusData):
        var idf_objects: String = delimited_string([
            "OutdoorAir:Node, Test node;",
            "EnergyManagementSystem:Sensor,",
            "test_node_wb,",
            "Test Node, ",
            "System Node Wetbulb Temperature;",
            "EnergyManagementSystem:Sensor,",
            "test_node_rh,",
            "Test Node, ",
            "System Node Relative Humidity;",
            "EnergyManagementSystem:Sensor,",
            "test_node_dp,",
            "Test Node, ",
            "System Node Dewpoint Temperature;",
            "EnergyManagementSystem:Sensor,",
            "test_node_cp,",
            "Test Node, ",
            "System Node Specific Heat;",
        ])
        ASSERT_TRUE(process_idf(idf_objects))
        OutAirNodeManager.SetOutAirNodes(*state)
        Node.SetupNodeVarsForReporting(*state)
        EMSManager.CheckIfAnyEMS(*state)
        state.dataEMSMgr.FinishProcessingUserInput = True
        var anyEMSRan: Bool
        EMSManager.ManageEMS(*state, EMSManager.EMSCallFrom.SetupSimulation, anyEMSRan, Optional_int_const())
        state.dataLoopNodes.Node[0].Temp = 20.0
        state.dataLoopNodes.Node[0].HumRat = 0.01
        state.dataEnvrn.OutBaroPress = 100000
        state.dataEnvrn.StdRhoAir = 1.2
        Node.CalcMoreNodeInfo(*state)
        EXPECT_NEAR(state.dataLoopNodes.MoreNodeInfo[0].RelHumidity, 67.65, 0.01)
        EXPECT_NEAR(state.dataLoopNodes.MoreNodeInfo[0].AirDewPointTemp, 13.84, 0.01)
        EXPECT_NEAR(state.dataLoopNodes.MoreNodeInfo[0].WetBulbTemp, 16.12, 0.01)
        EXPECT_NEAR(state.dataLoopNodes.MoreNodeInfo[0].SpecificHeat, 1023.43, 0.01)
class TestCheckUniqueNodesTest_Test1(Test):
    def run(self, state: EnergyPlusData):
        var UniqueNodeError: Bool = False
        Node.InitUniqueNodeCheck(*state, "Context")
        Node.CheckUniqueNodeNames(*state, "NodeFieldName", UniqueNodeError, "TestInputNode1", "ObjectName")
        Node.CheckUniqueNodeNames(*state, "NodeFieldName", UniqueNodeError, "TestOutputNode1", "ObjectName")
        Node.CheckUniqueNodeNames(*state, "NodeFieldName", UniqueNodeError, "TestInputNode2", "ObjectName")
        Node.CheckUniqueNodeNames(*state, "NodeFieldName", UniqueNodeError, "TestOutputNode2", "ObjectName")
        Node.CheckUniqueNodeNames(*state, "NodeFieldName", UniqueNodeError, "NonUsedNode", "ObjectName")
        EXPECT_FALSE(UniqueNodeError)
        Node.CheckUniqueNodeNames(*state, "NodeFieldName", UniqueNodeError, "TestInputNode2", "ObjectName")
        EXPECT_TRUE(UniqueNodeError)
        Node.EndUniqueNodeCheck(*state, "Context")