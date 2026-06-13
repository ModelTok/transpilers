from testing import *
from .Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.PluginManager import PluginManager

def TestTrendVariable():
    let pluginManager = PluginManager(*state)
    pluginManager.addGlobalVariable(*state, "my_var")
    let globalVarIndex = PluginManager.getGlobalVariableHandle(*state, "my_var", True)
    EXPECT_EQ(0, globalVarIndex)
    let numValues: size_t = 4
    state.dataPluginManager.trends.emplace_back(*state, "TREND_VAR", numValues, globalVarIndex)
    let trendVarIndex = PluginManager.getTrendVariableHandle(*state, "trend_var")
    EXPECT_EQ(0, trendVarIndex)
    EXPECT_EQ(numValues, pluginManager.getTrendVariableHistorySize(*state, trendVarIndex))
    for i in range(numValues):
        EXPECT_DOUBLE_EQ(0.0, pluginManager.getTrendVariableValue(*state, trendVarIndex, i))
    let fakeValues = [3.14, 2.78, 12.0]
    for i in range(3):
        PluginManager.setGlobalVariableValue(*state, globalVarIndex, fakeValues[i])
        PluginManager.updatePluginValues(*state)
    EXPECT_NEAR(fakeValues[2], pluginManager.getTrendVariableValue(*state, trendVarIndex, 0), 0.001)
    EXPECT_NEAR(fakeValues[1], pluginManager.getTrendVariableValue(*state, trendVarIndex, 1), 0.001)
    EXPECT_NEAR(fakeValues[0], pluginManager.getTrendVariableValue(*state, trendVarIndex, 2), 0.001)
    EXPECT_DOUBLE_EQ(0.0, pluginManager.getTrendVariableValue(*state, trendVarIndex, 3))

def MultiplePluginVariableObjects():
    let idf_objects: String = (
        "PythonPlugin:Variables, Variables1, VariableA, VariableB;  PythonPlugin:Variables, Variables2, VariableA, VariableC;"
    )
    ASSERT_TRUE(process_idf(idf_objects))