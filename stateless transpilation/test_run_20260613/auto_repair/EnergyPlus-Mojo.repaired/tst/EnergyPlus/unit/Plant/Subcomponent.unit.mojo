from testing import Test
from ...Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.Plant.Subcomponents import SubcomponentData, SubSubcomponentData

@test
def Plant_Topology_Subcomponent():
    var sc = SubcomponentData()
    var ssc = SubSubcomponentData()