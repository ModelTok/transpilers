from gtest import Test, TestFixture, Expect
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataEnvironment import DataEnvironment
from Fixtures.EnergyPlusFixture import EnergyPlusFixture

@fixture
def EnergyPlusFixture():
    return EnergyPlusFixture()

@test
def DataEnvironment_WindSpeedAt(fixture: EnergyPlusFixture):
    state = fixture.state
    state.dataEnvrn.WindSpeed = 10
    state.dataEnvrn.WeatherFileWindModCoeff = 0.3
    state.dataEnvrn.SiteWindBLHeight = 20
    state.dataEnvrn.SiteWindExp = 0.1
    Expect.near(0.000, DataEnvironment.WindSpeedAt(state, -1.0), 0.001)
    Expect.near(0.000, DataEnvironment.WindSpeedAt(state, 0.0), 0.001)
    Expect.near(2.223, DataEnvironment.WindSpeedAt(state, 1.0), 0.001)
    Expect.near(2.612, DataEnvironment.WindSpeedAt(state, 5.0), 0.001)
    Expect.near(2.799, DataEnvironment.WindSpeedAt(state, 10.0), 0.001)
    Expect.near(3.000, DataEnvironment.WindSpeedAt(state, 20.0), 0.001)
    state.dataEnvrn.SiteWindExp = 0.0
    Expect.near(0.0, DataEnvironment.WindSpeedAt(state, -1.0), 0.001)
    Expect.near(0.0, DataEnvironment.WindSpeedAt(state, 0.0), 0.001)
    Expect.near(10.0, DataEnvironment.WindSpeedAt(state, 1.0), 0.001)