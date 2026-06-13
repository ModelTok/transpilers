from .Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.RoomAirModelUserTempPattern import OutdoorDryBulbGrad
from testing import assert_eq, assert_approx_eq

@test
def RoomAirModelUserTempPattern_OutdoorDryBulbGradTest():
    assert_eq(8, OutdoorDryBulbGrad(20, 10, 8, 0, 2))
    assert_eq(2, OutdoorDryBulbGrad(-5, 10, 8, 0, 2))
    assert_eq(2, OutdoorDryBulbGrad(5, 10, 8, 10, 2))
    assert_approx_eq(4.307, OutdoorDryBulbGrad(5, 13, 8, 0, 2), .001)