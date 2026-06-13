from gtest import testing

class PropertyOne(testing.Test):
    def SetUp(self):
        self.RecordProperty("SetUpProp", 1)

    def TearDown(self):
        self.RecordProperty("TearDownProp", 1)

@testing.TEST_F(PropertyOne, "TestSomeProperties")
def TestSomeProperties(self):
    self.RecordProperty("TestSomeProperty", 1)