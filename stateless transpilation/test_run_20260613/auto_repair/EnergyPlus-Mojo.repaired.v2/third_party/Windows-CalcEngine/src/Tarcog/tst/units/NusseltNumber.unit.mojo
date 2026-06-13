from testing import expect_approx_eq
from ...WCETarcog import Tarcog

struct TestNusseltNumber:
    var m_NusseltNumber: Tarcog.ISO15099.CNusseltNumber

    def __init__(inout self):
        self.m_NusseltNumber = Tarcog.ISO15099.CNusseltNumber()

    def GetNusselt(self) -> Tarcog.ISO15099.CNusseltNumber:
        return self.m_NusseltNumber

@test
def NusseltNumberDifferentAngles_Test1():
    # SCOPED_TRACE("Begin Test: Nusselt number (Test 1) - different angles")
    var aNusselt = GetNusselt()
    var tTilt = 30.0
    var tRa = 3638.21667064528
    var tAsp = 83.3333333333333
    var nusseltNumber = aNusselt.calculate(tTilt, tRa, tAsp)
    expect_approx_eq(1.40474349200254, nusseltNumber, 1e-6)
    tTilt = 60
    nusseltNumber = aNusselt.calculate(tTilt, tRa, tAsp)
    expect_approx_eq(1.08005742342789, nusseltNumber, 1e-6)
    tTilt = 73
    nusseltNumber = aNusselt.calculate(tTilt, tRa, tAsp)
    expect_approx_eq(1.05703042079892, nusseltNumber, 1e-6)
    tTilt = 90
    nusseltNumber = aNusselt.calculate(tTilt, tRa, tAsp)
    expect_approx_eq(1.02691818659179, nusseltNumber, 1e-6)
    tTilt = 134
    nusseltNumber = aNusselt.calculate(tTilt, tRa, tAsp)
    expect_approx_eq(1.01936332296842, nusseltNumber, 1e-6)

@test
def NusseltNumberDifferentAngles_Test2():
    # SCOPED_TRACE("Begin Test: Nusselt number (Test 2) - different angles")
    var aNusselt = GetNusselt()
    var tTilt = 30.0
    var tRa = 140.779077041012
    var tAsp = 200.0
    var nusseltNumber = aNusselt.calculate(tTilt, tRa, tAsp)
    expect_approx_eq(1.00000000000000, nusseltNumber, 1e-6)
    tTilt = 60
    nusseltNumber = aNusselt.calculate(tTilt, tRa, tAsp)
    expect_approx_eq(1.00002777439094, nusseltNumber, 1e-6)
    tTilt = 73
    nusseltNumber = aNusselt.calculate(tTilt, tRa, tAsp)
    expect_approx_eq(1.00002235511865, nusseltNumber, 1e-6)
    tTilt = 90
    nusseltNumber = aNusselt.calculate(tTilt, tRa, tAsp)
    expect_approx_eq(1.00001526837795, nusseltNumber, 1e-6)
    tTilt = 134
    nusseltNumber = aNusselt.calculate(tTilt, tRa, tAsp)
    expect_approx_eq(1.00001098315195, nusseltNumber, 1e-6)

@test
def NusseltNumberDifferentAngles_Test3():
    # SCOPED_TRACE("Begin Test: Nusselt number (Test 3) - different angles")
    var aNusselt = GetNusselt()
    var tTilt = 30.0
    var tRa = 4633340.8866717
    var tAsp = 10.0
    var nusseltNumber = aNusselt.calculate(tTilt, tRa, tAsp)
    expect_approx_eq(10.2680981545288, nusseltNumber, 1e-6)
    tTilt = 60
    nusseltNumber = aNusselt.calculate(tTilt, tRa, tAsp)
    expect_approx_eq(11.5975502261096, nusseltNumber, 1e-6)
    tTilt = 73
    nusseltNumber = aNusselt.calculate(tTilt, tRa, tAsp)
    expect_approx_eq(11.4398529673101, nusseltNumber, 1e-6)
    tTilt = 90
    nusseltNumber = aNusselt.calculate(tTilt, tRa, tAsp)
    expect_approx_eq(11.2336334750340, nusseltNumber, 1e-6)
    tTilt = 134
    nusseltNumber = aNusselt.calculate(tTilt, tRa, tAsp)
    expect_approx_eq(8.361460, nusseltNumber, 1e-6)