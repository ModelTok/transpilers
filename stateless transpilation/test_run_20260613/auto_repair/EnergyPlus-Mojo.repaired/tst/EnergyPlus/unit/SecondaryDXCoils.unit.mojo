from Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.DXCoils import DXCoils, CalcSecondaryDXCoils, CalcSecondaryDXCoilsSHR
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataEnvironment import DataEnvironment
from EnergyPlus.DataHVACGlobals import HVAC, CoilType
from EnergyPlus.DataLoopNode import DataLoopNode
from EnergyPlus.Psychrometrics import Psychrometrics as Psy
from EnergyPlus.ZoneTempPredictorCorrector import ZoneTempPredictorCorrector

alias PsyHFnTdbW = Psy.PsyHFnTdbW
alias PsyRhoAirFnPbTdbW = Psy.PsyRhoAirFnPbTdbW
alias PsyTwbFnTdbWPb = Psy.PsyTwbFnTdbWPb

def EXPECT_DOUBLE_EQ(expected: Float64, actual: Float64) -> Bool:
    # Simple approximate equality for translation
    const tol: Float64 = 1.0e-5
    if abs(actual - expected) > tol:
        print("EXPECT_DOUBLE_EQ failed: expected", expected, "actual", actual)
        return False
    return True

struct EnergyPlusFixture:
    var state: EnergyPlusData

    def __init__(inout self):
        self.state = EnergyPlusData()

    def init_state(inout self):
        self.state.init_state(self.state)

    def SecondaryDXCoolingCoilSingleSpeed_Test1(inout self):
        var DXCoilNum: Int
        self.state.dataDXCoils.NumDXCoils = 1
        DXCoilNum = 1
        self.state.dataDXCoils.DXCoil.allocate(self.state.dataDXCoils.NumDXCoils)
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].IsSecondaryDXCoilInZone = True
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].coilType = CoilType.CoolingDXSingleSpeed
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].TotalCoolingEnergyRate = 5000.0
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].ElecCoolingPower = 500.0
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].SecCoilSensibleHeatGainRate = 0.0
        self.state.dataZoneTempPredictorCorrector.zoneHeatBalance.allocate(1)
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].SecZonePtr = 1
        CalcSecondaryDXCoils(self.state, DXCoilNum)
        EXPECT_DOUBLE_EQ(5500.0, self.state.dataDXCoils.DXCoil[DXCoilNum - 1].SecCoilSensibleHeatGainRate)
        self.state.dataDXCoils.DXCoil.deallocate()

    def SecondaryDXCoolingCoilTwoSpeed_Test2(inout self):
        var DXCoilNum: Int
        self.state.dataDXCoils.NumDXCoils = 1
        DXCoilNum = 1
        self.state.dataDXCoils.DXCoil.allocate(self.state.dataDXCoils.NumDXCoils)
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].IsSecondaryDXCoilInZone = True
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].coilType = CoilType.CoolingDXTwoSpeed
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].TotalCoolingEnergyRate = 5000.0
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].ElecCoolingPower = 500.0
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].SecCoilSensibleHeatGainRate = 0.0
        self.state.dataZoneTempPredictorCorrector.zoneHeatBalance.allocate(1)
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].SecZonePtr = 1
        CalcSecondaryDXCoils(self.state, DXCoilNum)
        EXPECT_DOUBLE_EQ(5500.0, self.state.dataDXCoils.DXCoil[DXCoilNum - 1].SecCoilSensibleHeatGainRate)
        self.state.dataDXCoils.DXCoil.deallocate()

    def SecondaryDXCoolingCoilMultiSpeed_Test3(inout self):
        var DXCoilNum: Int
        self.state.dataDXCoils.NumDXCoils = 1
        DXCoilNum = 1
        self.state.dataDXCoils.DXCoil.allocate(self.state.dataDXCoils.NumDXCoils)
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].IsSecondaryDXCoilInZone = True
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].coilType = CoilType.CoolingDXMultiSpeed
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].TotalCoolingEnergyRate = 5000.0
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].ElecCoolingPower = 500.0
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].SecCoilSensibleHeatGainRate = 0.0
        self.state.dataZoneTempPredictorCorrector.zoneHeatBalance.allocate(1)
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].SecZonePtr = 1
        CalcSecondaryDXCoils(self.state, DXCoilNum)
        EXPECT_DOUBLE_EQ(5500.0, self.state.dataDXCoils.DXCoil[DXCoilNum - 1].SecCoilSensibleHeatGainRate)
        self.state.dataDXCoils.DXCoil.deallocate()

    def SecondaryDXHeatingCoilSingleSpeed_Test4(inout self):
        self.state.init_state(self.state)
        var DXCoilNum: Int
        self.state.dataDXCoils.NumDXCoils = 1
        DXCoilNum = 1
        self.state.dataDXCoils.DXCoil.allocate(self.state.dataDXCoils.NumDXCoils)
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].IsSecondaryDXCoilInZone = True
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].coilType = CoilType.HeatingDXSingleSpeed
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].MinOATCompressor = -5.0
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].TotalHeatingEnergyRate = 5500.0
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].ElecHeatingPower = 500.0
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].SecCoilTotalHeatRemovalRate = 0.0
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].SecCoilSensibleHeatRemovalRate = 0.0
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].SecCoilLatentHeatRemovalRate = 0.0
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].SecZonePtr = 1
        self.state.dataLoopNodes.Node.allocate(2)
        self.state.dataZoneTempPredictorCorrector.zoneHeatBalance.allocate(1)
        self.state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].ZT = 10.0
        self.state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].airHumRat = 0.003
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].SecCoilAirFlow = 1.0
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].CompressorPartLoadRatio = 1.0
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].SecCoilRatedSHR = 1.0
        self.state.dataEnvrn.OutBaroPress = 101325.0
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].AirInNode = 2
        self.state.dataLoopNodes.Node[self.state.dataDXCoils.DXCoil[DXCoilNum - 1].AirInNode - 1].Temp = 20.0
        CalcSecondaryDXCoils(self.state, DXCoilNum)
        EXPECT_DOUBLE_EQ(-5000.0, self.state.dataDXCoils.DXCoil[DXCoilNum - 1].SecCoilTotalHeatRemovalRate)
        EXPECT_DOUBLE_EQ(1.0, self.state.dataDXCoils.DXCoil[DXCoilNum - 1].SecCoilSHR)
        alias EvapAirMassFlow: Float64 = 1.2
        alias TotalHeatRemovalRate: Float64 = 5500.0
        alias PartLoadRatio: Float64 = 1.0
        alias SecCoilRatedSHR: Float64 = 1.0
        alias EvapInletDryBulb: Float64 = 10.0
        alias EvapInletHumRat: Float64 = 0.003
        alias EvapInletWetBulb: Float64 = 4.5
        alias EvapInletEnthalpy: Float64 = 17607.0
        alias CondInletDryBulb: Float64 = 20.0
        alias SecCoilFlowFraction: Float64 = 1.0
        alias SecCoilSHRFT: Int = 0
        alias SecCoilSHRFF: Int = 0
        var SHRTest: Float64
        SHRTest = CalcSecondaryDXCoilsSHR(self.state,
                                          DXCoilNum,
                                          EvapAirMassFlow,
                                          TotalHeatRemovalRate,
                                          PartLoadRatio,
                                          SecCoilRatedSHR,
                                          EvapInletDryBulb,
                                          EvapInletHumRat,
                                          EvapInletWetBulb,
                                          EvapInletEnthalpy,
                                          CondInletDryBulb,
                                          SecCoilFlowFraction,
                                          SecCoilSHRFT,
                                          SecCoilSHRFF)
        EXPECT_DOUBLE_EQ(1.0, SHRTest)
        self.state.dataDXCoils.DXCoil.deallocate()
        self.state.dataLoopNodes.Node.deallocate()

    def SecondaryDXHeatingCoilMultiSpeed_Test5(inout self):
        self.state.init_state(self.state)
        var DXCoilNum: Int
        self.state.dataDXCoils.NumDXCoils = 1
        DXCoilNum = 1
        self.state.dataDXCoils.DXCoil.allocate(self.state.dataDXCoils.NumDXCoils)
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].NumOfSpeeds = 2
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].MSSecCoilAirFlow.allocate(self.state.dataDXCoils.DXCoil[DXCoilNum - 1].NumOfSpeeds)
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].MSSecCoilRatedSHR.allocate(self.state.dataDXCoils.DXCoil[DXCoilNum - 1].NumOfSpeeds)
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].MSSecCoilSHRFT.allocate(self.state.dataDXCoils.DXCoil[DXCoilNum - 1].NumOfSpeeds)
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].MSSecCoilSHRFF.allocate(self.state.dataDXCoils.DXCoil[DXCoilNum - 1].NumOfSpeeds)
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].IsSecondaryDXCoilInZone = True
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].coilType = CoilType.HeatingDXMultiSpeed
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].MinOATCompressor = -5.0
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].TotalHeatingEnergyRate = 5500.0
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].ElecHeatingPower = 500.0
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].SecCoilTotalHeatRemovalRate = 0.0
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].SecCoilSensibleHeatRemovalRate = 0.0
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].SecCoilLatentHeatRemovalRate = 0.0
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].SecZonePtr = 1
        self.state.dataLoopNodes.Node.allocate(2)
        self.state.dataZoneTempPredictorCorrector.zoneHeatBalance.allocate(1)
        self.state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].ZT = 10.0
        self.state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].airHumRat = 0.003
        # Note: 1-based -> 0-based indexing for multi-speed arrays
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].MSSecCoilAirFlow[0] = 1.0
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].MSSecCoilAirFlow[1] = 1.0
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].MSSecCoilSHRFT[0] = 0
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].MSSecCoilSHRFF[0] = 0
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].MSSecCoilSHRFT[1] = 0
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].MSSecCoilSHRFF[1] = 0
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].MSSecCoilRatedSHR[0] = 1.0
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].MSSecCoilRatedSHR[1] = 1.0
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].MSSpeedRatio = 0
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].MSCycRatio = 1
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].MSSpeedNumHS = 1
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].MSSpeedNumLS = 1
        self.state.dataEnvrn.OutBaroPress = 101325.0
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].AirInNode = 2
        self.state.dataLoopNodes.Node[self.state.dataDXCoils.DXCoil[DXCoilNum - 1].AirInNode - 1].Temp = 20.0
        CalcSecondaryDXCoils(self.state, DXCoilNum)
        EXPECT_DOUBLE_EQ(-5000.0, self.state.dataDXCoils.DXCoil[DXCoilNum - 1].SecCoilTotalHeatRemovalRate)
        EXPECT_DOUBLE_EQ(1.0, self.state.dataDXCoils.DXCoil[DXCoilNum - 1].SecCoilSHR)
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].MSSecCoilAirFlow.deallocate()
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].MSSecCoilRatedSHR.deallocate()
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].MSSecCoilSHRFT.deallocate()
        self.state.dataDXCoils.DXCoil[DXCoilNum - 1].MSSecCoilSHRFF.deallocate()
        self.state.dataDXCoils.DXCoil.deallocate()
        self.state.dataLoopNodes.Node.deallocate()
<<<FILE>>>