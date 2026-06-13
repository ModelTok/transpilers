from gtest import Test, ExpectNear
from Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataEnvironment import DataEnvironment
from EnergyPlus.DataLoopNode import DataLoopNode
from EnergyPlus.OutAirNodeManager import OutAirNodeManager, InitOutAirNodes
from EnergyPlus.Psychrometrics import Psychrometrics
from EnergyPlus.ScheduleManager import ScheduleManager as Sched

struct OutAirNodeManager_OATdbTwbOverrideTest(EnergyPlusFixture):
    def run(self):
        self.state.dataOutAirNodeMgr.NumOutsideAirNodes = 3
        self.state.dataOutAirNodeMgr.OutsideAirNodeList.allocate(3)
        self.state.dataLoopNodes.Node.allocate(3)
        self.state.dataEnvrn.OutDryBulbTemp = 25.0
        self.state.dataEnvrn.OutWetBulbTemp = 15.0
        self.state.dataEnvrn.WindSpeed = 2.0
        self.state.dataEnvrn.WindDir = 0.0
        self.state.dataEnvrn.OutBaroPress = 101325
        self.state.dataEnvrn.OutHumRat = Psychrometrics.PsyWFnTdbTwbPb(self.state, self.state.dataEnvrn.OutDryBulbTemp, self.state.dataEnvrn.OutWetBulbTemp, self.state.dataEnvrn.OutBaroPress)
        self.state.dataOutAirNodeMgr.OutsideAirNodeList[0] = 1
        self.state.dataOutAirNodeMgr.OutsideAirNodeList[1] = 2
        self.state.dataOutAirNodeMgr.OutsideAirNodeList[2] = 3
        self.state.dataLoopNodes.Node[0].IsLocalNode = true
        self.state.dataLoopNodes.Node[0].outAirDryBulbSched = Sched.AddScheduleConstant(self.state, "Out Air Dry Bulb")
        self.state.dataLoopNodes.Node[0].outAirDryBulbSched.currentVal = 24.0
        self.state.dataLoopNodes.Node[0].OutAirDryBulb = self.state.dataEnvrn.OutDryBulbTemp
        self.state.dataLoopNodes.Node[0].OutAirWetBulb = self.state.dataEnvrn.OutWetBulbTemp
        self.state.dataLoopNodes.Node[1].IsLocalNode = true
        self.state.dataLoopNodes.Node[1].EMSOverrideOutAirDryBulb = true
        self.state.dataLoopNodes.Node[1].EMSOverrideOutAirWetBulb = true
        self.state.dataLoopNodes.Node[1].EMSValueForOutAirDryBulb = 26.0
        self.state.dataLoopNodes.Node[1].EMSValueForOutAirWetBulb = 16.0
        self.state.dataLoopNodes.Node[1].OutAirDryBulb = self.state.dataEnvrn.OutDryBulbTemp
        self.state.dataLoopNodes.Node[1].OutAirWetBulb = self.state.dataEnvrn.OutWetBulbTemp
        self.state.dataLoopNodes.Node[2].OutAirDryBulb = self.state.dataEnvrn.OutDryBulbTemp
        self.state.dataLoopNodes.Node[2].OutAirWetBulb = self.state.dataEnvrn.OutWetBulbTemp
        InitOutAirNodes(self.state)
        ExpectNear(14.6467, self.state.dataLoopNodes.Node[0].OutAirWetBulb, 0.0001)
        ExpectNear(0.007253013, self.state.dataLoopNodes.Node[1].HumRat, 0.000001)
        ExpectNear(0.006543816, self.state.dataLoopNodes.Node[2].HumRat, 0.000001)

struct OutAirNodeManager_EMSWetbulbOverride_NoIsLocalNode(EnergyPlusFixture):
    def run(self):
        self.state.dataOutAirNodeMgr.NumOutsideAirNodes = 2
        self.state.dataOutAirNodeMgr.OutsideAirNodeList.allocate(2)
        self.state.dataLoopNodes.Node.allocate(2)
        self.state.dataEnvrn.OutDryBulbTemp = 25.0
        self.state.dataEnvrn.OutWetBulbTemp = 15.0
        self.state.dataEnvrn.WindSpeed = 2.0
        self.state.dataEnvrn.WindDir = 0.0
        self.state.dataEnvrn.OutBaroPress = 101325
        self.state.dataEnvrn.OutHumRat = Psychrometrics.PsyWFnTdbTwbPb(self.state, self.state.dataEnvrn.OutDryBulbTemp, self.state.dataEnvrn.OutWetBulbTemp, self.state.dataEnvrn.OutBaroPress)
        self.state.dataOutAirNodeMgr.OutsideAirNodeList[0] = 1
        self.state.dataOutAirNodeMgr.OutsideAirNodeList[1] = 2
        self.state.dataLoopNodes.Node[0].IsLocalNode = false
        self.state.dataLoopNodes.Node[0].EMSOverrideOutAirDryBulb = true
        self.state.dataLoopNodes.Node[0].EMSOverrideOutAirWetBulb = true
        self.state.dataLoopNodes.Node[0].EMSValueForOutAirDryBulb = 26.7
        self.state.dataLoopNodes.Node[0].EMSValueForOutAirWetBulb = 19.4
        self.state.dataLoopNodes.Node[0].OutAirDryBulb = self.state.dataEnvrn.OutDryBulbTemp
        self.state.dataLoopNodes.Node[0].OutAirWetBulb = self.state.dataEnvrn.OutWetBulbTemp
        self.state.dataLoopNodes.Node[1].IsLocalNode = false
        self.state.dataLoopNodes.Node[1].EMSOverrideOutAirWetBulb = true
        self.state.dataLoopNodes.Node[1].EMSValueForOutAirWetBulb = 19.4
        self.state.dataLoopNodes.Node[1].OutAirDryBulb = self.state.dataEnvrn.OutDryBulbTemp
        self.state.dataLoopNodes.Node[1].OutAirWetBulb = self.state.dataEnvrn.OutWetBulbTemp
        InitOutAirNodes(self.state)
        var expectedHumRat1: Float64 = Psychrometrics.PsyWFnTdbTwbPb(self.state, 26.7, 19.4, self.state.dataEnvrn.OutBaroPress)
        ExpectNear(expectedHumRat1, self.state.dataLoopNodes.Node[0].HumRat, 0.000001)
        ExpectNear(26.7, self.state.dataLoopNodes.Node[0].Temp, 0.001)
        ExpectNear(19.4, self.state.dataLoopNodes.Node[0].OutAirWetBulb, 0.001)
        var expectedHumRat2: Float64 = Psychrometrics.PsyWFnTdbTwbPb(self.state, 25.0, 19.4, self.state.dataEnvrn.OutBaroPress)
        ExpectNear(expectedHumRat2, self.state.dataLoopNodes.Node[1].HumRat, 0.000001)
        ExpectNear(19.4, self.state.dataLoopNodes.Node[1].OutAirWetBulb, 0.001)