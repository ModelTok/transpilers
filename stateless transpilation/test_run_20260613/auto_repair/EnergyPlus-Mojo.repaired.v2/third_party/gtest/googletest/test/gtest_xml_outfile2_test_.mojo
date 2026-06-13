from gtest.gtest import Test, RecordProperty

class PropertyTwo(Test):
    def SetUp(self):
        RecordProperty("SetUpProp", 2)
    def TearDown(self):
        RecordProperty("TearDownProp", 2)

class TestSomeProperties(PropertyTwo):
    def TestBody(self):
        RecordProperty("TestSomeProperty", 2)