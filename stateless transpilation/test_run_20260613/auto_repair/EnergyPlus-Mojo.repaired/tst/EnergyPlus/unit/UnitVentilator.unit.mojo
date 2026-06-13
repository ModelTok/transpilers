from gtest import Test, TestFixture, EXPECT_NEAR
from Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataEnvironment import DataEnvironment
from EnergyPlus.DataHVACGlobals import DataHVACGlobals
from EnergyPlus.DataLoopNode import DataLoopNode
from EnergyPlus.DataSizing import DataSizing
from EnergyPlus.UnitVentilator import UnitVentilator

@register_test(EnergyPlusFixture)
class UnitVentilatorSetOAMassFlowRateForCoolingVariablePercentTest(Test):
    def run(self, state: EnergyPlusData):
        var MinOA: Float64
        var MassFlowRate: Float64
        var MaxOA: Float64
        var Tinlet: Float64
        var Toutdoor: Float64
        var OAMassFlowRate: Float64
        var ExpectedOAMassFlowRate: Float64
        var UnitVentNum: Float64
        state.dataLoopNodes.clear_state()
        state.dataUnitVentilators.clear_state()
        state.dataLoopNodes.Node.allocate(4)
        state.dataUnitVentilators.UnitVent.allocate(1)
        state.dataUnitVentilators.UnitVent[0].ATMixerExists = False
        state.dataUnitVentilators.UnitVent[0].ATMixerType = HVAC.MixerType.InletSide
        state.dataUnitVentilators.UnitVent[0].FanOutletNode = 1
        state.dataUnitVentilators.UnitVent[0].OAMixerOutNode = 2
        state.dataUnitVentilators.UnitVent[0].ATMixerOutNode = 3
        state.dataUnitVentilators.UnitVent[0].AirInNode = 4
        state.dataLoopNodes.Node[0].Enthalpy = 0.0
        state.dataLoopNodes.Node[1].Enthalpy = 0.0
        state.dataLoopNodes.Node[2].Enthalpy = 0.0
        state.dataLoopNodes.Node[3].Enthalpy = 0.0
        UnitVentNum = 1
        Tinlet = 20.0
        Toutdoor = 23.0
        MinOA = 0.1
        MaxOA = 0.9
        MassFlowRate = 1.234
        state.dataUnitVentilators.QZnReq = 2345.6
        state.dataEnvrn.OutHumRat = 0.008
        OAMassFlowRate = UnitVentilator.SetOAMassFlowRateForCoolingVariablePercent(state, UnitVentNum, MinOA, MassFlowRate, MaxOA, Tinlet, Toutdoor)
        ExpectedOAMassFlowRate = 0.1234
        EXPECT_NEAR(ExpectedOAMassFlowRate, OAMassFlowRate, 0.0001)
        Tinlet = 23.0
        Toutdoor = 1.0
        MinOA = 0.1
        MaxOA = 0.9
        MassFlowRate = 1.234
        state.dataUnitVentilators.QZnReq = 1.5678
        state.dataEnvrn.OutHumRat = 0.008
        OAMassFlowRate = UnitVentilator.SetOAMassFlowRateForCoolingVariablePercent(state, UnitVentNum, MinOA, MassFlowRate, MaxOA, Tinlet, Toutdoor)
        ExpectedOAMassFlowRate = 0.1234
        EXPECT_NEAR(ExpectedOAMassFlowRate, OAMassFlowRate, 0.0001)
        Tinlet = 23.0
        Toutdoor = 20.0
        MinOA = 0.1
        MaxOA = 0.9
        MassFlowRate = 1.234
        state.dataUnitVentilators.QZnReq = 4567.89
        state.dataEnvrn.OutHumRat = 0.010
        OAMassFlowRate = UnitVentilator.SetOAMassFlowRateForCoolingVariablePercent(state, UnitVentNum, MinOA, MassFlowRate, MaxOA, Tinlet, Toutdoor)
        ExpectedOAMassFlowRate = 1.1106
        EXPECT_NEAR(ExpectedOAMassFlowRate, OAMassFlowRate, 0.0001)
        Tinlet = 23.0
        Toutdoor = 8.0
        MinOA = 0.1
        MaxOA = 0.9
        MassFlowRate = 1.234
        state.dataUnitVentilators.QZnReq = 15678.9
        state.dataEnvrn.OutHumRat = 0.010
        OAMassFlowRate = UnitVentilator.SetOAMassFlowRateForCoolingVariablePercent(state, UnitVentNum, MinOA, MassFlowRate, MaxOA, Tinlet, Toutdoor)
        ExpectedOAMassFlowRate = 1.02133
        EXPECT_NEAR(ExpectedOAMassFlowRate, OAMassFlowRate, 0.0001)
        Tinlet = 23.0
        Toutdoor = 8.0
        MinOA = 0.1
        MaxOA = 0.9
        MassFlowRate = 1.234
        state.dataUnitVentilators.QZnReq = 15678.9 - 12.34
        state.dataEnvrn.OutHumRat = 0.010
        state.dataLoopNodes.Node[0].Enthalpy = 11.0
        state.dataLoopNodes.Node[1].Enthalpy = 1.0
        state.dataLoopNodes.Node[2].Enthalpy = 0.0
        state.dataLoopNodes.Node[3].Enthalpy = 0.0
        OAMassFlowRate = UnitVentilator.SetOAMassFlowRateForCoolingVariablePercent(state, UnitVentNum, MinOA, MassFlowRate, MaxOA, Tinlet, Toutdoor)
        ExpectedOAMassFlowRate = 1.02133
        EXPECT_NEAR(ExpectedOAMassFlowRate, OAMassFlowRate, 0.0001)
        Tinlet = 23.0
        Toutdoor = 8.0
        MinOA = 0.1
        MaxOA = 0.9
        MassFlowRate = 1.234
        state.dataUnitVentilators.QZnReq = 15678.9 - 12.34
        state.dataEnvrn.OutHumRat = 0.010
        state.dataLoopNodes.Node[0].Enthalpy = 11.0
        state.dataLoopNodes.Node[1].Enthalpy = 0.0
        state.dataLoopNodes.Node[2].Enthalpy = 1.0
        state.dataLoopNodes.Node[3].Enthalpy = 0.0
        state.dataUnitVentilators.UnitVent[0].ATMixerExists = True
        state.dataUnitVentilators.UnitVent[0].ATMixerType = HVAC.MixerType.InletSide
        OAMassFlowRate = UnitVentilator.SetOAMassFlowRateForCoolingVariablePercent(state, UnitVentNum, MinOA, MassFlowRate, MaxOA, Tinlet, Toutdoor)
        ExpectedOAMassFlowRate = 1.02133
        EXPECT_NEAR(ExpectedOAMassFlowRate, OAMassFlowRate, 0.0001)
        Tinlet = 23.0
        Toutdoor = 8.0
        MinOA = 0.1
        MaxOA = 0.9
        MassFlowRate = 1.234
        state.dataUnitVentilators.QZnReq = 15678.9 - 12.34
        state.dataEnvrn.OutHumRat = 0.010
        state.dataLoopNodes.Node[0].Enthalpy = 11.0
        state.dataLoopNodes.Node[1].Enthalpy = 0.0
        state.dataLoopNodes.Node[2].Enthalpy = 0.0
        state.dataLoopNodes.Node[3].Enthalpy = 1.0
        state.dataUnitVentilators.UnitVent[0].ATMixerExists = True
        state.dataUnitVentilators.UnitVent[0].ATMixerType = HVAC.MixerType.SupplySide
        OAMassFlowRate = UnitVentilator.SetOAMassFlowRateForCoolingVariablePercent(state, UnitVentNum, MinOA, MassFlowRate, MaxOA, Tinlet, Toutdoor)
        ExpectedOAMassFlowRate = 1.02133
        EXPECT_NEAR(ExpectedOAMassFlowRate, OAMassFlowRate, 0.0001)

@register_test(EnergyPlusFixture)
class UnitVentilatorCalcMdotCCoilCycFanTest(Test):
    def run(self, state: EnergyPlusData):
        var QZnReq: Float64
        var QCoilReq: Float64
        var UnitVentNum: Int
        var PartLoadRatio: Float64
        var mdot: Float64
        var ExpectedResult: Float64
        UnitVentNum = 1
        state.dataUnitVentilators.UnitVent.allocate(UnitVentNum)
        state.dataUnitVentilators.UnitVent[UnitVentNum - 1].FanOutletNode = 1
        state.dataUnitVentilators.UnitVent[UnitVentNum - 1].AirInNode = 2
        state.dataLoopNodes.Node.allocate(2)
        state.dataLoopNodes.Node[1].HumRat = 0.006
        state.dataLoopNodes.Node[1].Temp = 23.0
        state.dataLoopNodes.Node[0].Temp = 23.0
        state.dataLoopNodes.Node[0].MassFlowRate = 1.0
        state.dataUnitVentilators.UnitVent[0].MaxColdWaterFlow = 0.1234
        mdot = -0.9999
        QCoilReq = 5678.9
        QZnReq = 5678.9
        PartLoadRatio = 1.0
        ExpectedResult = 0.0
        UnitVentilator.CalcMdotCCoilCycFan(state, mdot, QCoilReq, QZnReq, UnitVentNum, PartLoadRatio)
        EXPECT_NEAR(ExpectedResult, mdot, 0.0001)
        EXPECT_NEAR(ExpectedResult, QCoilReq, 0.0001)
        state.dataUnitVentilators.UnitVent[0].MaxColdWaterFlow = 0.1234
        mdot = -0.9999
        QCoilReq = 0.0
        QZnReq = 0.0
        PartLoadRatio = 1.0
        ExpectedResult = 0.0
        UnitVentilator.CalcMdotCCoilCycFan(state, mdot, QCoilReq, QZnReq, UnitVentNum, PartLoadRatio)
        EXPECT_NEAR(ExpectedResult, mdot, 0.0001)
        EXPECT_NEAR(ExpectedResult, QCoilReq, 0.0001)
        state.dataUnitVentilators.UnitVent[0].MaxColdWaterFlow = 0.1234
        mdot = -0.9999
        QCoilReq = -5678.9
        QZnReq = -5678.9
        PartLoadRatio = 1.0
        ExpectedResult = 0.1234
        UnitVentilator.CalcMdotCCoilCycFan(state, mdot, QCoilReq, QZnReq, UnitVentNum, PartLoadRatio)
        EXPECT_NEAR(ExpectedResult, mdot, 0.0001)
        EXPECT_NEAR(QCoilReq, QZnReq, 0.1)
        state.dataUnitVentilators.UnitVent[0].MaxColdWaterFlow = 1.6
        mdot = -0.9999
        QCoilReq = -5678.9
        QZnReq = -5678.9
        PartLoadRatio = 0.5
        ExpectedResult = 0.8
        UnitVentilator.CalcMdotCCoilCycFan(state, mdot, QCoilReq, QZnReq, UnitVentNum, PartLoadRatio)
        EXPECT_NEAR(ExpectedResult, mdot, 0.0001)
        EXPECT_NEAR(QCoilReq, QZnReq, 0.1)

@register_test(EnergyPlusFixture)
class UnitVentilatorOASizing(Test):
    def run(self, state: EnergyPlusData):
        var UnitVentNum: Int = 1
        var numNumericFields: Int = 5
        state.dataUnitVentilators.UnitVent.allocate(UnitVentNum)
        state.dataSize.ZoneEqSizing.allocate(UnitVentNum)
        state.dataSize.FinalZoneSizing.allocate(UnitVentNum)
        state.dataSize.ZoneHVACSizing.allocate(UnitVentNum)
        state.dataUnitVentilators.UnitVentNumericFields.allocate(UnitVentNum)
        state.dataUnitVentilators.UnitVentNumericFields[UnitVentNum - 1].FieldNames.allocate(numNumericFields)
        state.dataSize.CurZoneEqNum = UnitVentNum
        state.dataSize.ZoneSizingRunDone = True
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].MinOA = 0.1
        state.dataUnitVentilators.UnitVent[UnitVentNum - 1].HVACSizingIndex = 1
        state.dataUnitVentilators.UnitVent[UnitVentNum - 1].MaxAirVolFlow = 1.0
        state.dataUnitVentilators.UnitVent[UnitVentNum - 1].CoilOption = UnitVentilator.CoilsUsed.None
        state.dataUnitVentilators.UnitVent[UnitVentNum - 1].OutAirVolFlow = DataSizing.AutoSize
        state.dataUnitVentilators.UnitVent[UnitVentNum - 1].OAControlType = UnitVentilator.OAControl.FixedAmount
        UnitVentilator.SizeUnitVentilator(state, UnitVentNum)
        EXPECT_NEAR(state.dataUnitVentilators.UnitVent[UnitVentNum - 1].OutAirVolFlow,
                    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].MinOA,
                    0.001)
        state.dataUnitVentilators.UnitVent[UnitVentNum - 1].OutAirVolFlow = DataSizing.AutoSize
        state.dataUnitVentilators.UnitVent[UnitVentNum - 1].OAControlType = UnitVentilator.OAControl.VariablePercent
        UnitVentilator.SizeUnitVentilator(state, UnitVentNum)
        EXPECT_NEAR(
            state.dataUnitVentilators.UnitVent[UnitVentNum - 1].OutAirVolFlow, state.dataUnitVentilators.UnitVent[UnitVentNum - 1].MaxAirVolFlow, 0.001)
        state.dataUnitVentilators.UnitVent[UnitVentNum - 1].OutAirVolFlow = DataSizing.AutoSize
        state.dataUnitVentilators.UnitVent[UnitVentNum - 1].OAControlType = UnitVentilator.OAControl.FixedTemperature
        UnitVentilator.SizeUnitVentilator(state, UnitVentNum)
        EXPECT_NEAR(
            state.dataUnitVentilators.UnitVent[UnitVentNum - 1].OutAirVolFlow, state.dataUnitVentilators.UnitVent[UnitVentNum - 1].MaxAirVolFlow, 0.001)
        state.dataUnitVentilators.UnitVent[UnitVentNum - 1].HVACSizingIndex = 0
        state.dataUnitVentilators.UnitVent[UnitVentNum - 1].OutAirVolFlow = DataSizing.AutoSize
        state.dataUnitVentilators.UnitVent[UnitVentNum - 1].OAControlType = UnitVentilator.OAControl.FixedAmount
        UnitVentilator.SizeUnitVentilator(state, UnitVentNum)
        EXPECT_NEAR(state.dataUnitVentilators.UnitVent[UnitVentNum - 1].OutAirVolFlow,
                    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].MinOA,
                    0.001)
        state.dataUnitVentilators.UnitVent[UnitVentNum - 1].OutAirVolFlow = DataSizing.AutoSize
        state.dataUnitVentilators.UnitVent[UnitVentNum - 1].OAControlType = UnitVentilator.OAControl.VariablePercent
        UnitVentilator.SizeUnitVentilator(state, UnitVentNum)
        EXPECT_NEAR(
            state.dataUnitVentilators.UnitVent[UnitVentNum - 1].OutAirVolFlow, state.dataUnitVentilators.UnitVent[UnitVentNum - 1].MaxAirVolFlow, 0.001)
        state.dataUnitVentilators.UnitVent[UnitVentNum - 1].OutAirVolFlow = DataSizing.AutoSize
        state.dataUnitVentilators.UnitVent[UnitVentNum - 1].OAControlType = UnitVentilator.OAControl.FixedTemperature
        UnitVentilator.SizeUnitVentilator(state, UnitVentNum)
        EXPECT_NEAR(
            state.dataUnitVentilators.UnitVent[UnitVentNum - 1].OutAirVolFlow, state.dataUnitVentilators.UnitVent[UnitVentNum - 1].MaxAirVolFlow, 0.001)