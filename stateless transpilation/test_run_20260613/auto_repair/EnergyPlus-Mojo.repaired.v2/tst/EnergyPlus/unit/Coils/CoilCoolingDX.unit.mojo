# Mojo translation of CoilCoolingDX.unit.cc

from gtest import *
from ...Fixtures.SQLiteFixture import *
from EnergyPlus.Coils.CoilCoolingDX import *
from EnergyPlus.Data.EnergyPlusData import *
from EnergyPlus.Psychrometrics import *
from ...Coils.CoilCoolingDXFixture import *
from EnergyPlus.Coils.CoilCoolingDXCurveFitPerformance import *
from EnergyPlus.CurveManager import *
from EnergyPlus.DXCoils import *
from EnergyPlus.DataAirSystems import *
from EnergyPlus.DataHVACGlobals import *
from EnergyPlus.DataSizing import *
from EnergyPlus.General import *

using EnergyPlus.*

@Test
class TestCoilCoolingDX:
    def test_CoilCoolingDXInput(self):
        string idf_objects = self.getCoilObjectString("coolingCoil", false, 2)
        EXPECT_TRUE(process_idf(idf_objects, false))
        self.state.init_state(*self.state)
        int coilIndex = CoilCoolingDX.factory(*self.state, "coolingCoil")
        var const &thisCoil = self.state.dataCoilCoolingDX.coilCoolingDXs[coilIndex]
        EXPECT_EQ("COOLINGCOIL", thisCoil.name)
        EXPECT_EQ("PERFORMANCEOBJECTNAME", thisCoil.performance.name)

    def test_CoilCoolingDXAlternateModePerformance(self):
        string idf_objects = delimited_string({"  Coil:Cooling:DX,",
                                                    "    Coil,",
                                                    "    Evaporator Inlet Node,Evaporator Outlet Node,",
                                                    "    ,,",
                                                    "    Condenser Inlet Node,Condenser Outlet Node,",
                                                    "    Coil Performance,",
                                                    "    ,;",
                                                    "  Coil:Cooling:DX:CurveFit:Performance,",
                                                    "    Coil Performance,,,,,,,,,,Electricity,Coil Mode 1,Coil Mode 2;",
                                                    "  Coil:Cooling:DX:CurveFit:OperatingMode,",
                                                    "    Coil Mode 1,",
                                                    "    5000,   !- Rated Gross Total Cooling Capacity {W}",
                                                    "    0.25,   !- Rated Evaporator Air Flow Rate {m3/s}",
                                                    "    ,,,,,,,,,",
                                                    "    2,Coil Mode 1 Speed 1,Coil Mode 1 Speed 2;",
                                                    "  Coil:Cooling:DX:CurveFit:Speed,",
                                                    "    Coil Mode 1 Speed 1,     !- Name",
                                                    "    0.50,                    !- Gross Total Cooling Capacity Fraction",
                                                    "    0.50,                    !- Evaporator Air Flow Rate Fraction",
                                                    "    ,                        !- Condenser Air Flow Rate Fraction",
                                                    "    0.7,                     !- Gross Sensible Heat Ratio",
                                                    "    3,                       !- Gross Cooling COP {W/W}",
                                                    "    0.5,                     !- Active Fraction of Coil Face Area",
                                                    "    ,,,,,,,,,,,;",
                                                    "  Coil:Cooling:DX:CurveFit:Speed,",
                                                    "    Coil Mode 1 Speed 2,     !- Name",
                                                    "    1.0,                     !- Gross Total Cooling Capacity Fraction",
                                                    "    1.0,                     !- Evaporator Air Flow Rate Fraction",
                                                    "    ,                        !- Condenser Air Flow Rate Fraction",
                                                    "    0.7,                     !- Gross Sensible Heat Ratio",
                                                    "    3,                       !- Gross Cooling COP {W/W}",
                                                    "    1.0,                     !- Active Fraction of Coil Face Area",
                                                    "    ,,,,,,,,,,,;",
                                                    "  Coil:Cooling:DX:CurveFit:OperatingMode,",
                                                    "    Coil Mode 2,",
                                                    "    5000,   !- Rated Gross Total Cooling Capacity {W}",
                                                    "    0.25,   !- Rated Evaporator Air Flow Rate {m3/s}",
                                                    "    ,,,,,,,,,",
                                                    "    2,Coil Mode 2 Speed 1,Coil Mode 2 Speed 2;",
                                                    "  Coil:Cooling:DX:CurveFit:Speed,",
                                                    "    Coil Mode 2 Speed 1,     !- Name",
                                                    "    0.45,                    !- Gross Total Cooling Capacity Fraction",
                                                    "    0.50,                    !- Evaporator Air Flow Rate Fraction",
                                                    "    ,                        !- Condenser Air Flow Rate Fraction",
                                                    "    0.6,                     !- Gross Sensible Heat Ratio",
                                                    "    2.7,                     !- Gross Cooling COP {W/W}",
                                                    "    0.5,                     !- Active Fraction of Coil Face Area",
                                                    "    ,,,,,,,,,,,;",
                                                    "  Coil:Cooling:DX:CurveFit:Speed,",
                                                    "    Coil Mode 2 Speed 2,     !- Name",
                                                    "    0.9,                     !- Gross Total Cooling Capacity Fraction",
                                                    "    1.0,                     !- Evaporator Air Flow Rate Fraction",
                                                    "    ,                        !- Condenser Air Flow Rate Fraction",
                                                    "    0.6,                     !- Gross Sensible Heat Ratio",
                                                    "    2.7,                     !- Gross Cooling COP {W/W}",
                                                    "    1.0,                     !- Active Fraction of Coil Face Area",
                                                    "    ,,,,,,,,,,,;"})
        EXPECT_TRUE(process_idf(idf_objects, false))
        self.state.init_state(*self.state)
        int coilIndex = CoilCoolingDX.factory(*self.state, "Coil")
        var &thisCoil = self.state.dataCoilCoolingDX.coilCoolingDXs[coilIndex]
        var &evapInletNode = self.state.dataLoopNodes.Node(thisCoil.evapInletNodeIndex)
        var &condInletNode = self.state.dataLoopNodes.Node(thisCoil.condInletNodeIndex)
        evapInletNode.Temp = 28.5
        evapInletNode.Press = 101325
        evapInletNode.HumRat = 0.014
        evapInletNode.Enthalpy = Psychrometrics.PsyHFnTdbW(evapInletNode.Temp, evapInletNode.HumRat)
        condInletNode.Temp = 35.0
        condInletNode.Press = 101325
        condInletNode.HumRat = 0.008
        condInletNode.Enthalpy = Psychrometrics.PsyHFnTdbW(condInletNode.Temp, condInletNode.HumRat)
        thisCoil.size(*self.state)
        self.state.dataHVACGlobal.MSHPMassFlowRateHigh = thisCoil.performance.ratedAirMassFlowRateMaxSpeed(*self.state)
        var &evapOutletNode = self.state.dataLoopNodes.Node(thisCoil.evapOutletNodeIndex)
        evapInletNode.MassFlowRate = thisCoil.performance.ratedAirMassFlowRateMinSpeed(*self.state)
        HVAC.CoilMode coilMode = HVAC.CoilMode.Normal
        int speedNum = 1
        Real64 speedRatio = 1.0
        HVAC.FanOp fanOp = HVAC.FanOp.Cycling
        bool singleMode = false
        thisCoil.simulate(*self.state, coilMode, speedNum, speedRatio, fanOp, singleMode)
        EXPECT_NEAR(2500, thisCoil.totalCoolingEnergyRate, 0.1) // expect the coil to run full out, at speed 1
        EXPECT_NEAR(19.485, evapOutletNode.Temp, 0.01)
        EXPECT_NEAR(0.0114, evapOutletNode.HumRat, 0.001)
        evapInletNode.MassFlowRate = thisCoil.performance.ratedAirMassFlowRateMaxSpeed(*self.state)
        speedNum = 2
        thisCoil.simulate(*self.state, coilMode, speedNum, speedRatio, fanOp, singleMode)
        EXPECT_NEAR(5000, thisCoil.totalCoolingEnergyRate, 0.01) // expect the coil to run full out, at speed 1
        EXPECT_NEAR(17.943, evapOutletNode.Temp, 0.01)
        EXPECT_NEAR(0.0114, evapOutletNode.HumRat, 0.001)
        coilMode = HVAC.CoilMode.Enhanced
        speedNum = 1
        thisCoil.simulate(*self.state, coilMode, speedNum, speedRatio, fanOp, singleMode)
        EXPECT_NEAR(2250, thisCoil.totalCoolingEnergyRate, 0.01) // expect the coil to run full out, at speed 1
        EXPECT_NEAR(24.47, evapOutletNode.Temp, 0.01)
        EXPECT_NEAR(0.0126, evapOutletNode.HumRat, 0.0001)
        coilMode = HVAC.CoilMode.Enhanced
        speedNum = 2
        thisCoil.simulate(*self.state, coilMode, speedNum, speedRatio, fanOp, singleMode)
        EXPECT_NEAR(4500, thisCoil.totalCoolingEnergyRate, 0.01) // expect the coil to run full out, at speed 1
        EXPECT_NEAR(20.42, evapOutletNode.Temp, 0.01)
        EXPECT_NEAR(0.0111, evapOutletNode.HumRat, 0.0001)

    def test_CoilCoolingDXAlternateModePerformanceHitsSaturation(self):
        string idf_objects = delimited_string({"  Coil:Cooling:DX,",
                                                    "    Coil,",
                                                    "    Evaporator Inlet Node,Evaporator Outlet Node,",
                                                    "    ,,",
                                                    "    Condenser Inlet Node,Condenser Outlet Node,",
                                                    "    Coil Performance,",
                                                    "    ,;",
                                                    "  Coil:Cooling:DX:CurveFit:Performance,",
                                                    "    Coil Performance,,,,,,,,,,Electricity,Coil Mode 1,Coil Mode 2;",
                                                    "  Coil:Cooling:DX:CurveFit:OperatingMode,",
                                                    "    Coil Mode 1,",
                                                    "    10000,   !- Rated Gross Total Cooling Capacity {W}",
                                                    "    0.25,   !- Rated Evaporator Air Flow Rate {m3/s}",
                                                    "    ,,,,,,,,,",
                                                    "    2,Coil Mode 1 Speed 1,Coil Mode 1 Speed 2;",
                                                    "  Coil:Cooling:DX:CurveFit:Speed,",
                                                    "    Coil Mode 1 Speed 1,     !- Name",
                                                    "    0.50,                    !- Gross Total Cooling Capacity Fraction",
                                                    "    0.50,                    !- Evaporator Air Flow Rate Fraction",
                                                    "    ,                        !- Condenser Air Flow Rate Fraction",
                                                    "    0.7,                     !- Gross Sensible Heat Ratio",
                                                    "    3,                       !- Gross Cooling COP {W/W}",
                                                    "    0.5,                     !- Active Fraction of Coil Face Area",
                                                    "    ,,,,,,,,,,,;",
                                                    "  Coil:Cooling:DX:CurveFit:Speed,",
                                                    "    Coil Mode 1 Speed 2,     !- Name",
                                                    "    1.0,                     !- Gross Total Cooling Capacity Fraction",
                                                    "    1.0,                     !- Evaporator Air Flow Rate Fraction",
                                                    "    ,                        !- Condenser Air Flow Rate Fraction",
                                                    "    0.7,                     !- Gross Sensible Heat Ratio",
                                                    "    3,                       !- Gross Cooling COP {W/W}",
                                                    "    1.0,                     !- Active Fraction of Coil Face Area",
                                                    "    ,,,,,,,,,,,;",
                                                    "  Coil:Cooling:DX:CurveFit:OperatingMode,",
                                                    "    Coil Mode 2,",
                                                    "    10000,   !- Rated Gross Total Cooling Capacity {W}",
                                                    "    0.25,   !- Rated Evaporator Air Flow Rate {m3/s}",
                                                    "    ,,,,,,,,,",
                                                    "    2,Coil Mode 2 Speed 1,Coil Mode 2 Speed 2;",
                                                    "  Coil:Cooling:DX:CurveFit:Speed,",
                                                    "    Coil Mode 2 Speed 1,     !- Name",
                                                    "    0.45,                    !- Gross Total Cooling Capacity Fraction",
                                                    "    0.50,                    !- Evaporator Air Flow Rate Fraction",
                                                    "    ,                        !- Condenser Air Flow Rate Fraction",
                                                    "    0.6,                     !- Gross Sensible Heat Ratio",
                                                    "    2.7,                     !- Gross Cooling COP {W/W}",
                                                    "    0.5,                     !- Active Fraction of Coil Face Area",
                                                    "    ,,,,,,,,,,,;",
                                                    "  Coil:Cooling:DX:CurveFit:Speed,",
                                                    "    Coil Mode 2 Speed 2,     !- Name",
                                                    "    0.9,                     !- Gross Total Cooling Capacity Fraction",
                                                    "    1.0,                     !- Evaporator Air Flow Rate Fraction",
                                                    "    ,                        !- Condenser Air Flow Rate Fraction",
                                                    "    0.6,                     !- Gross Sensible Heat Ratio",
                                                    "    2.7,                     !- Gross Cooling COP {W/W}",
                                                    "    1.0,                     !- Active Fraction of Coil Face Area",
                                                    "    ,,,,,,,,,,,;"})
        EXPECT_TRUE(process_idf(idf_objects, false))
        self.state.init_state(*self.state)
        int coilIndex = CoilCoolingDX.factory(*self.state, "Coil")
        var &thisCoil = self.state.dataCoilCoolingDX.coilCoolingDXs[coilIndex]
        var &evapInletNode = self.state.dataLoopNodes.Node(thisCoil.evapInletNodeIndex)
        var &condInletNode = self.state.dataLoopNodes.Node(thisCoil.condInletNodeIndex)
        evapInletNode.Temp = 28.5
        evapInletNode.Press = 101325
        evapInletNode.HumRat = 0.014
        evapInletNode.Enthalpy = Psychrometrics.PsyHFnTdbW(evapInletNode.Temp, evapInletNode.HumRat)
        condInletNode.Temp = 35.0
        condInletNode.Press = 101325
        condInletNode.HumRat = 0.008
        condInletNode.Enthalpy = Psychrometrics.PsyHFnTdbW(condInletNode.Temp, condInletNode.HumRat)
        thisCoil.size(*self.state)
        self.state.dataHVACGlobal.MSHPMassFlowRateHigh = thisCoil.performance.ratedAirMassFlowRateMaxSpeed(*self.state)
        var &evapOutletNode = self.state.dataLoopNodes.Node(thisCoil.evapOutletNodeIndex)
        bool setExpectations = true
        evapInletNode.MassFlowRate = thisCoil.performance.ratedAirMassFlowRateMinSpeed(*self.state)
        HVAC.CoilMode coilMode = HVAC.CoilMode.Normal
        int speedNum = 1
        Real64 speedRatio = 1.0
        HVAC.FanOp fanOp = HVAC.FanOp.Cycling
        bool singleMode = false
        thisCoil.simulate(*self.state, coilMode, speedNum, speedRatio, fanOp, singleMode)
        if (!setExpectations) {
            cout << thisCoil.totalCoolingEnergyRate << ',' << evapOutletNode.Temp << ',' << evapOutletNode.HumRat << endl
        } else {
            EXPECT_NEAR(5000, thisCoil.totalCoolingEnergyRate, 0.1) // expect the coil to run full out, at speed 1
            EXPECT_NEAR(10.238, evapOutletNode.Temp, 0.01)
            EXPECT_NEAR(0.007748, evapOutletNode.HumRat, 0.0001)
        }
        EXPECT_EQ(thisCoil.availSched.currentVal, 1.0)
        EXPECT_EQ(thisCoil.performance.coilCoolingDXAvailSched.currentVal, 1.0)
        var coilPerformance = DynamicCast[EnergyPlus.CoilCoolingDXCurveFitPerformance](thisCoil.performance)
        EXPECT_EQ(coilPerformance.normalMode.coilCoolingDXAvailSched.currentVal, 1.0)
        EXPECT_EQ(coilPerformance.alternateMode.coilCoolingDXAvailSched.currentVal, 1.0)
        EXPECT_EQ(coilPerformance.alternateMode2.coilCoolingDXAvailSched.currentVal, 1.0)
        evapInletNode.MassFlowRate = thisCoil.performance.ratedAirMassFlowRateMaxSpeed(*self.state)
        speedNum = 2
        thisCoil.simulate(*self.state, coilMode, speedNum, speedRatio, fanOp, singleMode)
        if (!setExpectations) {
            cout << thisCoil.totalCoolingEnergyRate << ',' << evapOutletNode.Temp << ',' << evapOutletNode.HumRat << endl
        } else {
            EXPECT_NEAR(10000, thisCoil.totalCoolingEnergyRate, 0.01) // expect the coil to run full out, at speed 1
            EXPECT_NEAR(10.247, evapOutletNode.Temp, 0.01)
            EXPECT_NEAR(0.00774, evapOutletNode.HumRat, 0.0001)
        }
        coilMode = HVAC.CoilMode.Enhanced
        speedNum = 1
        thisCoil.simulate(*self.state, coilMode, speedNum, speedRatio, fanOp, singleMode)
        if (!setExpectations) {
            cout << thisCoil.totalCoolingEnergyRate << ',' << evapOutletNode.Temp << ',' << evapOutletNode.HumRat << endl
        } else {
            EXPECT_NEAR(4500, thisCoil.totalCoolingEnergyRate, 0.01) // expect the coil to run full out, at speed 1
            EXPECT_NEAR(20.411, evapOutletNode.Temp, 0.01)
            EXPECT_NEAR(0.0111, evapOutletNode.HumRat, 0.0001)
        }
        coilMode = HVAC.CoilMode.Enhanced
        speedNum = 2
        thisCoil.simulate(*self.state, coilMode, speedNum, speedRatio, fanOp, singleMode)
        if (!setExpectations) {
            cout << thisCoil.totalCoolingEnergyRate << ',' << evapOutletNode.Temp << ',' << evapOutletNode.HumRat << endl
        } else {
            EXPECT_NEAR(9000, thisCoil.totalCoolingEnergyRate, 0.01) // expect the coil to run full out, at speed 1
            EXPECT_NEAR(12.239, evapOutletNode.Temp, 0.01)
            EXPECT_NEAR(0.00833, evapOutletNode.HumRat, 0.0001)
        }

    def test_CoilCoolingDX_LowerSpeedFlowSizingTest(self):
        string const idf_objects = delimited_string({
            "  Coil:Cooling:DX,",
            "    DX Cooling Coil,                 !- Name",
            "    DX Cooling Coil Air Inlet Node,  !- Evaporator Inlet Node Name",
            "    DX Cooling Coil Air Outlet Node, !- Evaporator Outlet Node Name",
            "    ,                                !- Availability Schedule Name",
            "    ,                                !- Condenser Zone Name",
            "    DX Cooling Coil Condenser Inlet Node,   !- Condenser Inlet Node Name",
            "    DX Cooling Coil Condenser Outlet Node,  !- Condenser Outlet Node Name",
            "    DX Cooling Coil Performance,     !- Performance Object Name",
            "    ,                                !- Condensate Collection Water Storage Tank Name",
            "    ;                                !- Evaporative Condenser Supply Water Storage Tank Name",
            "  Coil:Cooling:DX:CurveFit:Performance,",
            "    DX Cooling Coil Performance,  !- Name",
            "    0,                       !- Crankcase Heater Capacity {W}",
            "    ,                        !- Crankcase Heater Capacity Function of Temperature Curve Name",
            "    ,                        !- Minimum Outdoor Dry-Bulb Temperature for Compressor Operation {C}",
            "    10,                      !- Maximum Outdoor Dry-Bulb Temperature for Crankcase Heater Operation {C}",
            "    ,                        !- Unit Internal Static Air Pressure {Pa}",
            "    ,                        !- Capacity Control Method",
            "    ,                        !- Evaporative Condenser Basin Heater Capacity {W/K}",
            "    ,                        !- Evaporative Condenser Basin Heater Setpoint Temperature {C}",
            "    ,                        !- Evaporative Condenser Basin Heater Operating Schedule Name",
            "    Electricity,             !- Compressor Fuel Type",
            "    DX Cooling Coil Operating Mode,  !- Base Operating Mode",
            "    ,                        !- Alternative Operating Mode 1",
            "    ;                        !- Alternative Operating Mode 2",
            "  Coil:Cooling:DX:CurveFit:OperatingMode,",
            "    DX Cooling Coil Operating Mode,  !- Name",
            "    15000,                   !- Rated Gross Total Cooling Capacity {W}",
            "    0.95,                    !- Rated Evaporator Air Flow Rate {m3/s}",
            "    ,                        !- Rated Condenser Air Flow Rate {m3/s}",
            "    0,                       !- Maximum Cycling Rate {cycles/hr}",
            "    0,                       !- Ratio of Initial Moisture Evaporation Rate and Steady State Latent Capacity {dimensionless}",
            "    0,                       !- Latent Capacity Time Constant {s}",
            "    0,                       !- Nominal Time for Condensate Removal to Begin {s}",
            "    ,                        !- Apply Part Load Fraction to Speeds Greater than 1",
            "    ,                        !- Apply Latent Degradation to Speeds Greater than 1",
            "    AirCooled,               !- Condenser Type",
            "    0,                       !- Nominal Evaporative Condenser Pump Power {W}",
            "    4,                       !- Nominal Speed Number",
            "    DX Cooling Coil Speed 1 Performance,  !- Speed 1 Name",
            "    DX Cooling Coil Speed 2 Performance,  !- Speed 2 Name",
            "    DX Cooling Coil Speed 3 Performance,  !- Speed 3 Name",
            "    DX Cooling Coil Speed 4 Performance;  !- Speed 4 Name",
            "  Coil:Cooling:DX:CurveFit:Speed,",
            "    DX Cooling Coil Speed 1 Performance,  !- Name",
            "    0.25,                    !- Gross Total Cooling Capacity Fraction",
            "    0.25,                    !- Evaporator Air Flow Rate Fraction",
            "    0.25,                    !- Condenser Air Flow Rate Fraction",
            "    0.77,                    !- Gross Sensible Heat Ratio",
            "    4.17,                    !- Gross Cooling COP {W/W}",
            "    1.0,                     !- Active Fraction of Coil Face Area",
            "    ,                        !- 2017 Rated Evaporator Fan Power Per Volume Flow Rate {W/(m3/s)}",
            "    ,                        !- 2023 Rated Evaporator Fan Power Per Volume Flow Rate {W/(m3/s)}",
            "    ,                        !- Evaporative Condenser Pump Power Fraction",
            "    0,                       !- Evaporative Condenser Effectiveness {dimensionless}",
            "    CAPFT,                   !- Total Cooling Capacity Modifier Function of Temperature Curve Name",
            "    CAPFF,                   !- Total Cooling Capacity Modifier Function of Air Flow Fraction Curve Name",
            "    EIRFT,                   !- Energy Input Ratio Modifier Function of Temperature Curve Name",
            "    EIRFF,                   !- Energy Input Ratio Modifier Function of Air Flow Fraction Curve Name",
            "    PLFFPLR,                 !- Part Load Fraction Correlation Curve Name",
            "    ,                        !- Rated Waste Heat Fraction of Power Input {dimensionless}",
            "    ,                        !- Waste Heat Modifier Function of Temperature Curve Name",
            "    ,                        !- Sensible Heat Ratio Modifier Function of Temperature Curve Name",
            "    ;                        !- Sensible Heat Ratio Modifier Function of Flow Fraction Curve Name",
            "  Coil:Cooling:DX:CurveFit:Speed,",
            "    DX Cooling Coil Speed 2 Performance,  !- Name",
            "    0.50,                    !- Gross Total Cooling Capacity Fraction",
            "    0.50,                    !- Evaporator Air Flow Rate Fraction",
            "    0.50,                    !- Condenser Air Flow Rate Fraction",
            "    0.77,                    !- Gross Sensible Heat Ratio",
            "    4.17,                    !- Gross Cooling COP {W/W}",
            "    1.0,                     !- Active Fraction of Coil Face Area",
            "    ,                        !- 2017 Rated Evaporator Fan Power Per Volume Flow Rate {W/(m3/s)}",
            "    ,                        !- 2023 Rated Evaporator Fan Power Per Volume Flow Rate {W/(m3/s)}",
            "    ,                        !- Evaporative Condenser Pump Power Fraction",
            "    0,                       !- Evaporative Condenser Effectiveness {dimensionless}",
            "    CAPFT,                   !- Total Cooling Capacity Modifier Function of Temperature Curve Name",
            "    CAPFF,                   !- Total Cooling Capacity Modifier Function of Air Flow Fraction Curve Name",
            "    EIRFT,                   !- Energy Input Ratio Modifier Function of Temperature Curve Name",
            "    EIRFF,                   !- Energy Input Ratio Modifier Function of Air Flow Fraction Curve Name",
            "    PLFFPLR,                 !- Part Load Fraction Correlation Curve Name",
            "    ,                        !- Rated Waste Heat Fraction of Power Input {dimensionless}",
            "    ,                        !- Waste Heat Modifier Function of Temperature Curve Name",
            "    ,                        !- Sensible Heat Ratio Modifier Function of Temperature Curve Name",
            "    ;                        !- Sensible Heat Ratio Modifier Function of Flow Fraction Curve Name",
            "  Coil:Cooling:DX:CurveFit:Speed,",
            "    DX Cooling Coil Speed 3 Performance,  !- Name",
            "    0.75,                    !- Gross Total Cooling Capacity Fraction",
            "    0.75,                    !- Evaporator Air Flow Rate Fraction",
            "    0.75,                    !- Condenser Air Flow Rate Fraction",
            "    0.77,                    !- Gross Sensible Heat Ratio",
            "    4.17,                    !- Gross Cooling COP {W/W}",
            "    1.0,                     !- Active Fraction of Coil Face Area",
            "    ,                        !- 2017 Rated Evaporator Fan Power Per Volume Flow Rate {W/(m3/s)}",
            "    ,                        !- 2023 Rated Evaporator Fan Power Per Volume Flow Rate {W/(m3/s)}",
            "    ,                        !- Evaporative Condenser Pump Power Fraction",
            "    0,                       !- Evaporative Condenser Effectiveness {dimensionless}",
            "    CAPFT,                   !- Total Cooling Capacity Modifier Function of Temperature Curve Name",
            "    CAPFF,                   !- Total Cooling Capacity Modifier Function of Air Flow Fraction Curve Name",
            "    EIRFT,                   !- Energy Input Ratio Modifier Function of Temperature Curve Name",
            "    EIRFF,                   !- Energy Input Ratio Modifier Function of Air Flow Fraction Curve Name",
            "    PLFFPLR,                 !- Part Load Fraction Correlation Curve Name",
            "    ,                        !- Rated Waste Heat Fraction of Power Input {dimensionless}",
            "    ,                        !- Waste Heat Modifier Function of Temperature Curve Name",
            "    ,                        !- Sensible Heat Ratio Modifier Function of Temperature Curve Name",
            "    ;                        !- Sensible Heat Ratio Modifier Function of Flow Fraction Curve Name",
            "  Coil:Cooling:DX:CurveFit:Speed,",
            "    DX Cooling Coil Speed 4 Performance,  !- Name",
            "    1.0,                     !- Gross Total Cooling Capacity Fraction",
            "    1.0,                     !- Evaporator Air Flow Rate Fraction",
            "    1.0,                     !- Condenser Air Flow Rate Fraction",
            "    0.77,                    !- Gross Sensible Heat Ratio",
            "    4.17,                    !- Gross Cooling COP {W/W}",
            "    1.0,                     !- Active Fraction of Coil Face Area",
            "    ,                        !- 2017 Rated Evaporator Fan Power Per Volume Flow Rate {W/(m3/s)}",
            "    ,                        !- 2023 Rated Evaporator Fan Power Per Volume Flow Rate {W/(m3/s)}",
            "    ,                        !- Evaporative Condenser Pump Power Fraction",
            "    0,                       !- Evaporative Condenser Effectiveness {dimensionless}",
            "    CAPFT,                   !- Total Cooling Capacity Modifier Function of Temperature Curve Name",
            "    CAPFF,                   !- Total Cooling Capacity Modifier Function of Air Flow Fraction Curve Name",
            "    EIRFT,                   !- Energy Input Ratio Modifier Function of Temperature Curve Name",
            "    EIRFF,                   !- Energy Input Ratio Modifier Function of Air Flow Fraction Curve Name",
            "    PLFFPLR,                 !- Part Load Fraction Correlation Curve Name",
            "    ,                        !- Rated Waste Heat Fraction of Power Input {dimensionless}",
            "    ,                        !- Waste Heat Modifier Function of Temperature Curve Name",
            "    ,                        !- Sensible Heat Ratio Modifier Function of Temperature Curve Name",
            "    ;                        !- Sensible Heat Ratio Modifier Function of Flow Fraction Curve Name",
            "Curve:Quadratic, PLFFPLR, 0.85, 0.83, 0.0, 0.0, 0.3, 0.85, 1.0, Dimensionless, Dimensionless; ",
            "Curve:Cubic, CAPFF, 1, 0, 0, 0, 0, 1, , , Dimensionless, Dimensionless; ",
            "Curve:Cubic, EIRFF, 1, 0, 0, 0, 0, 1, , , Dimensionless, Dimensionless; ",
            "Curve:Biquadratic, CAPFT, 1, 0, 0, 0, 0, 0, 0, 100, 0, 100, , , Temperature, Temperature, Dimensionless;",
            "Curve:Biquadratic, EIRFT, 1, 0, 0, 0, 0, 0, 0, 100, 0, 100, , , Temperature, Temperature, Dimensionless;",
        })
        ASSERT_TRUE(process_idf(idf_objects))
        self.state.init_state(*self.state)
        int coilIndex = CoilCoolingDX.factory(*self.state, "DX Cooling Coil")
        var &this_dx_clg_coil = self.state.dataCoilCoolingDX.coilCoolingDXs[coilIndex]
        EXPECT_EQ(this_dx_clg_coil.name, "DX COOLING COIL")
        self.state.dataEnvrn.OutDryBulbTemp = 35.0
        self.state.dataEnvrn.OutHumRat = 0.0196
        self.state.dataEnvrn.OutBaroPress = 101325.0
        self.state.dataEnvrn.OutWetBulbTemp = 27.0932
        self.state.dataSize.CurZoneEqNum = 0
        self.state.dataSize.CurOASysNum = 0
        self.state.dataSize.CurSysNum = 1
        self.state.dataSize.CurDuctType = HVAC.AirDuctType.Cooling
        self.state.dataSize.FinalSysSizing.allocate(1)
        self.state.dataSize.FinalSysSizing(self.state.dataSize.CurSysNum).CoolSupTemp = 12.0
        self.state.dataSize.FinalSysSizing(self.state.dataSize.CurSysNum).CoolSupHumRat = 0.0085
        self.state.dataSize.FinalSysSizing(self.state.dataSize.CurSysNum).MixTempAtCoolPeak = 28.0
        self.state.dataSize.FinalSysSizing(self.state.dataSize.CurSysNum).MixHumRatAtCoolPeak = 0.0075
        self.state.dataSize.FinalSysSizing(self.state.dataSize.CurSysNum).DesCoolVolFlow = 0.80
        self.state.dataSize.FinalSysSizing(self.state.dataSize.CurSysNum).DesOutAirVolFlow = 0.2
        self.state.dataHVACGlobal.NumPrimaryAirSys = 1
        self.state.dataAirSystemsData.PrimaryAirSystems.allocate(1)
        self.state.dataAirSystemsData.PrimaryAirSystems(self.state.dataSize.CurSysNum).NumOACoolCoils = 0
        self.state.dataAirSystemsData.PrimaryAirSystems(self.state.dataSize.CurSysNum).supFanNum = -1
        self.state.dataAirSystemsData.PrimaryAirSystems(self.state.dataSize.CurSysNum).retFanNum = -1
        self.state.dataSize.SysSizingRunDone = true
        self.state.dataSize.SysSizInput.allocate(1)
        self.state.dataSize.SysSizInput(1).AirLoopNum = self.state.dataSize.CurSysNum
        self.state.dataSize.NumSysSizInput = 1
        self.state.dataEnvrn.StdBaroPress = 101325.0
        self.state.dataEnvrn.StdRhoAir = 1.0
        self.state.dataSize.DataAirFlowUsedForSizing = self.state.dataSize.FinalSysSizing(self.state.dataSize.CurSysNum).DesCoolVolFlow
        this_dx_clg_coil.size(*self.state)
        EXPECT_EQ(this_dx_clg_coil.performance.nameAtSpeed(0), "DX COOLING COIL SPEED 1 PERFORMANCE")
        EXPECT_EQ(this_dx_clg_coil.performance.nameAtSpeed(1), "DX COOLING COIL SPEED 2 PERFORMANCE")
        EXPECT_EQ(this_dx_clg_coil.performance.nameAtSpeed(2), "DX COOLING COIL SPEED 3 PERFORMANCE")
        EXPECT_EQ(this_dx_clg_coil.performance.nameAtSpeed(3), "DX COOLING COIL SPEED 4 PERFORMANCE")
        struct TestQuery
        {
            TestQuery(string t_description, string t_units, Real64 t_value)
                : description(t_description), units(t_units), expectedValue(t_value),
                  displayString("Description='" + description + "'; Units='" + units + "'") {}
            const string description
            const string units
            const Real64 expectedValue
            const string displayString
        }
        string compType = "Coil:Cooling:DX:CurveFit:Speed"
        string compName = "DX COOLING COIL SPEED 1 PERFORMANCE" // this_dx_clg_coil.performance.normalMode.speeds[0].name;
        var speed1_testQueries = list[TestQuery](
            TestQuery("Design Size Rated Air Flow Rate", "m3/s", 0.2000), TestQuery("Design Size Gross Cooling Capacity", "W", 3260.1028))
        for testQuery in speed1_testQueries:
            string query("SELECT Value From ComponentSizes"
                              "  WHERE CompType = '" +
                              compType +
                              "'"
                              "  AND CompName = '" +
                              compName +
                              "'"
                              "  AND Description = '" +
                              testQuery.description + "'" + "  AND Units = '" + testQuery.units + "'")
            Real64 return_val = SQLiteFixture.execAndReturnFirstDouble(query)
            if (return_val < 0) {
                EXPECT_TRUE(false) << "Query returned nothing for " << testQuery.displayString
            } else {
                EXPECT_NEAR(testQuery.expectedValue, return_val, 0.0001) << "Failed for " << testQuery.displayString
            }
        compType = "Coil:Cooling:DX:CurveFit:Speed"
        compName = this_dx_clg_coil.performance.nameAtSpeed(1)
        var speed2_testQueries = list[TestQuery](
            TestQuery("Design Size Rated Air Flow Rate", "m3/s", 0.4000), TestQuery("Design Size Gross Cooling Capacity", "W", 6520.2056))
        for testQuery in speed2_testQueries:
            string query("SELECT Value From ComponentSizes"
                              "  WHERE CompType = '" +
                              compType +
                              "'"
                              "  AND CompName = '" +
                              compName +
                              "'"
                              "  AND Description = '" +
                              testQuery.description + "'" + "  AND Units = '" + testQuery.units + "'")
            Real64 return_val = SQLiteFixture.execAndReturnFirstDouble(query)
            if (return_val < 0) {
                EXPECT_TRUE(false) << "Query returned nothing for " << testQuery.displayString
            } else {
                EXPECT_NEAR(testQuery.expectedValue, return_val, 0.0001) << "Failed for " << testQuery.displayString
            }
        compType = "Coil:Cooling:DX:CurveFit:Speed"
        compName = this_dx_clg_coil.performance.nameAtSpeed(2)
        var speed3_testQueries = list[TestQuery](
            TestQuery("Design Size Rated Air Flow Rate", "m3/s", 0.6000), TestQuery("Design Size Gross Cooling Capacity", "W", 9780.3084))
        for testQuery in speed3_testQueries:
            string query("SELECT Value From ComponentSizes"
                              "  WHERE CompType = '" +
                              compType +
                              "'"
                              "  AND CompName = '" +
                              compName +
                              "'"
                              "  AND Description = '" +
                              testQuery.description + "'" + "  AND Units = '" + testQuery.units + "'")
            Real64 return_val = SQLiteFixture.execAndReturnFirstDouble(query)
            if (return_val < 0) {
                EXPECT_TRUE(false) << "Query returned nothing for " << testQuery.displayString
            } else {
                EXPECT_NEAR(testQuery.expectedValue, return_val, 0.0001) << "Failed for " << testQuery.displayString
            }