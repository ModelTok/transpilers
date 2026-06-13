from gtest import TEST_F, EXPECT_DOUBLE_EQ, EXPECT_NEAR, EXPECT_EQ, EXPECT_ENUM_EQ, ASSERT_TRUE, ASSERT_THROW, delimited_string, process_idf, compare_err_stream
from EnergyPlus.CurveManager import AddCurve, CurveType, Curve
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataAirLoop import AirLoopFlow, AirLoopControlInfo
from EnergyPlus.DataAirSystems import PrimaryAirSystems, Branch, Comp
from EnergyPlus.DataEnvironment import OutBaroPress
from EnergyPlus.DataGlobalConstants import DataStringGlobals, MatchVersion
from EnergyPlus.DataLoopNode import Node
from EnergyPlus.DataSizing import AutoSize, SysSizingRunDone, NumSysSizInput, SysSizInput, CurSysNum, FinalSysSizing, DesMainVolFlow, DesOutAirVolFlow
from EnergyPlus.EvaporativeCoolers import EvapCond, EvapCoolerType, OperatingMode, CalcSecondaryAirOutletCondition, CalcIndirectRDDEvapCoolerOutletTemp, SizeEvapCooler, GetEvapInput, CalcDirectResearchSpecialEvapCooler, IndirectResearchSpecialEvapCoolerOperatingMode, IndEvapCoolerPower, SimAirLoopComponent, CompType
from EnergyPlus.Psychrometrics import PsyWFnTdbTwbPb, PsyTwbFnTdbWPb
from EnergyPlus.SimAirServingZones import SimAirLoopComponent
from EnergyPlus.Utility import format
from .Fixtures.EnergyPlusFixture import EnergyPlusFixture

@value
struct EnergyPlusFixture:
    var state: EnergyPlusData

@test
def EvapCoolers_SecondaryAirOutletCondition():
    var self = EnergyPlusFixture(EnergyPlusData())
    self.state.init_state(self.state)
    var EvapCond = self.state.dataEvapCoolers.EvapCond
    EvapCond.allocate(1)
    const EvapCoolNum: Int = 0  # 1-based -> 0-based
    EvapCond[EvapCoolNum].SecInletEnthalpy = 42000.0
    var OperatingMode: OperatingMode = OperatingMode.None
    var AirMassFlowSec: Float64 = 0.0
    const EDBTSec: Float64 = 20.0
    const EWBTSec: Float64 = 15.0
    const EHumRatSec: Float64 = 0.0085
    var QHXTotal: Float64 = 0.0
    var QHXLatent: Float64 = 0.0
    CalcSecondaryAirOutletCondition(self.state, EvapCoolNum, OperatingMode, AirMassFlowSec, EDBTSec, EWBTSec, EHumRatSec, QHXTotal, QHXLatent)
    EXPECT_DOUBLE_EQ(EvapCond[EvapCoolNum].SecOutletEnthalpy, EvapCond[EvapCoolNum].SecInletEnthalpy)
    EXPECT_DOUBLE_EQ(0.0, QHXLatent)
    OperatingMode = OperatingMode.DryFull
    AirMassFlowSec = 2.0
    QHXTotal = 10206.410750000941
    CalcSecondaryAirOutletCondition(self.state, EvapCoolNum, OperatingMode, AirMassFlowSec, EDBTSec, EWBTSec, EHumRatSec, QHXTotal, QHXLatent)
    EXPECT_NEAR(25.0, EvapCond[EvapCoolNum].SecOutletTemp, 0.000001)
    EXPECT_DOUBLE_EQ(0.0, QHXLatent)
    OperatingMode = OperatingMode.WetFull
    AirMassFlowSec = 2.0
    QHXTotal = 10206.410750000941
    CalcSecondaryAirOutletCondition(self.state, EvapCoolNum, OperatingMode, AirMassFlowSec, EDBTSec, EWBTSec, EHumRatSec, QHXTotal, QHXLatent)
    EXPECT_DOUBLE_EQ(20.0, EvapCond[EvapCoolNum].SecOutletTemp)
    EXPECT_DOUBLE_EQ(47103.205375000471, EvapCond[EvapCoolNum].SecOutletEnthalpy)
    EXPECT_DOUBLE_EQ(QHXTotal, QHXLatent)
    EvapCond.deallocate()

@test
def EvapCoolers_IndEvapCoolerOutletTemp():
    var self = EnergyPlusFixture(EnergyPlusData())
    self.state.init_state(self.state)
    var EvapCond = self.state.dataEvapCoolers.EvapCond
    const EvapCoolNum: Int = 0
    EvapCond.allocate(EvapCoolNum + 1)  # allocate 1 element
    self.state.dataEnvrn.OutBaroPress = 101325.0
    EvapCond[EvapCoolNum].InletMassFlowRate = 1.0
    EvapCond[EvapCoolNum].InletTemp = 24.0
    EvapCond[EvapCoolNum].InletHumRat = 0.013
    EvapCond[EvapCoolNum].DryCoilMaxEfficiency = 0.8
    var DryOrWetOperatingMode: OperatingMode = OperatingMode.DryFull
    const AirMassFlowSec: Float64 = 1.0
    const EDBTSec: Float64 = 14.0
    const EWBTSec: Float64 = 11.0
    const EHumRatSec: Float64 = 0.0075
    CalcIndirectRDDEvapCoolerOutletTemp(self.state, EvapCoolNum, DryOrWetOperatingMode, AirMassFlowSec, EDBTSec, EWBTSec, EHumRatSec)
    EXPECT_DOUBLE_EQ(16.0, EvapCond[EvapCoolNum].OutletTemp)
    DryOrWetOperatingMode = OperatingMode.WetFull
    EvapCond[EvapCoolNum].WetCoilMaxEfficiency = 0.75
    CalcIndirectRDDEvapCoolerOutletTemp(self.state, EvapCoolNum, DryOrWetOperatingMode, AirMassFlowSec, EDBTSec, EWBTSec, EHumRatSec)
    EXPECT_DOUBLE_EQ(14.25, EvapCond[EvapCoolNum].OutletTemp)
    EvapCond.deallocate()

@test
def EvapCoolers_SizeIndEvapCoolerTest():
    var self = EnergyPlusFixture(EnergyPlusData())
    self.state.init_state(self.state)
    var EvapCond = self.state.dataEvapCoolers.EvapCond
    const EvapCoolNum: Int = 0
    var PrimaryAirDesignFlow: Float64 = 0.0
    var SecondaryAirDesignFlow: Float64 = 0.0
    self.state.dataSize.SysSizingRunDone = true
    self.state.dataSize.NumSysSizInput = 1
    self.state.dataSize.SysSizInput = Array[SystemSizingInputData](1)
    self.state.dataSize.SysSizInput[0].AirLoopNum = 1
    self.state.dataSize.CurSysNum = 0  # 1 -> 0
    self.state.dataSize.FinalSysSizing = Array[FinalSysSizingData](self.state.dataSize.CurSysNum + 1)
    self.state.dataSize.FinalSysSizing[0].DesMainVolFlow = 1.0
    self.state.dataSize.FinalSysSizing[0].DesOutAirVolFlow = 0.4
    self.state.dataAirSystemsData.PrimaryAirSystems = Array[PrimaryAirSystemData](self.state.dataSize.CurSysNum + 1)
    self.state.dataAirSystemsData.PrimaryAirSystems[0].Branch = Array[BranchData](1)
    self.state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].Comp = Array[CompData](1)
    self.state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].Comp[0].Name = "INDRDD EVAP COOLER"
    self.state.dataAirSystemsData.PrimaryAirSystems[0].NumBranches = 1
    self.state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].TotalComponents = 1
    const idf_objects: String = delimited_string(Array[String](
        "\tEvaporativeCooler:Indirect:ResearchSpecial,",
        "\tIndRDD Evap Cooler,  !- Name",
        "\t,\t\t\t         !- Availability Schedule Name",
        "\t0.750,\t\t\t\t !- Cooler Wetbulb Design Effectiveness",
        "\t,\t\t\t\t\t !- Wetbulb Effectiveness Flow Ratio Modifier Curve Name",
        "\t,\t\t\t\t\t !- Cooler Drybulb Design Effectiveness",
        "\t,\t\t\t\t\t !- Drybulb Effectiveness Flow Ratio Modifier Curve Name",
        "\t30.0,\t\t\t\t !- Recirculating Water Pump Design Power { W }",
        "\t,\t\t\t\t\t !- Water Pump Power Sizing Factor",
        "\t,\t\t\t\t\t !- Water Pump Power Modifier Curve Name",
        "\tautosize,\t\t\t !- Secondary Air Design Flow Rate { m3 / s }",
        "\t1.2,\t\t\t\t !- Secondary Air Flow Sizing Factor",
        "\tautosize,\t\t\t !- Secondary Air Fan Design Power",
        "\t207.6,\t\t\t\t !- Secondary Air Fan Sizing Specific Power",
        "\t,\t\t\t\t\t !- Secondary Fan Power Modifier Curve Name",
        "\tPriAir Inlet Node,\t !- Primary Air Inlet Node Name",
        "\tPriAir Outlet Node,\t !- Primary Air Outlet Node Name",
        "\tautosize,\t\t\t !- Primary Air Design Air Flow Rate",
        "\t0.90,\t\t\t\t !- Dewpoint Effectiveness Factor",
        "\tSecAir Inlet Node,   !- Secondary Air Inlet Node Name",
        "\tSecAir Outlet Node,  !- Secondary Air Outlet Node Name",
        "\tPriAir Outlet Node,\t !- Sensor Node Name",
        "\t,\t\t\t\t\t !- Relief Air Inlet Node Name",
        "\t,\t\t\t\t\t !- Water Supply Storage Tank Name",
        "\t0.0,\t\t\t\t !- Drift Loss Fraction",
        "\t3;                   !- Blowdown Concentration Ratio",
    ))
    ASSERT_TRUE(process_idf(idf_objects))
    GetEvapInput(self.state)
    self.state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].Comp[0].Name = EvapCond[EvapCoolNum].Name
    EvapCond[EvapCoolNum].DesVolFlowRate = AutoSize
    EvapCond[EvapCoolNum].IndirectVolFlowRate = AutoSize
    self.state.dataSize.FinalSysSizing[0].DesMainVolFlow = 1.0
    self.state.dataSize.FinalSysSizing[0].DesOutAirVolFlow = 0.2
    PrimaryAirDesignFlow = self.state.dataSize.FinalSysSizing[0].DesMainVolFlow
    SecondaryAirDesignFlow = PrimaryAirDesignFlow * EvapCond[EvapCoolNum].IndirectVolFlowScalingFactor
    SizeEvapCooler(self.state, EvapCoolNum)
    EXPECT_EQ(PrimaryAirDesignFlow, EvapCond[EvapCoolNum].DesVolFlowRate)
    EXPECT_EQ(SecondaryAirDesignFlow, EvapCond[EvapCoolNum].IndirectVolFlowRate)
    EvapCond[EvapCoolNum].Name = "EvapCool On OA System"
    EvapCond[EvapCoolNum].DesVolFlowRate = AutoSize
    EvapCond[EvapCoolNum].IndirectVolFlowRate = AutoSize
    self.state.dataSize.FinalSysSizing[0].DesMainVolFlow = 1.0
    self.state.dataSize.FinalSysSizing[0].DesOutAirVolFlow = 0.2
    PrimaryAirDesignFlow = self.state.dataSize.FinalSysSizing[0].DesOutAirVolFlow
    SecondaryAirDesignFlow = max(PrimaryAirDesignFlow, 0.5 * self.state.dataSize.FinalSysSizing[0].DesMainVolFlow)
    SecondaryAirDesignFlow = SecondaryAirDesignFlow * EvapCond[EvapCoolNum].IndirectVolFlowScalingFactor
    SizeEvapCooler(self.state, EvapCoolNum)
    EXPECT_EQ(0.5, EvapCond[EvapCoolNum].DesVolFlowRate)
    EXPECT_EQ(SecondaryAirDesignFlow, EvapCond[EvapCoolNum].IndirectVolFlowRate)
    EvapCond.deallocate()
    self.state.dataAirSystemsData.PrimaryAirSystems.deallocate()
    self.state.dataSize.FinalSysSizing.deallocate()

@test
def EvapCoolers_SizeDirEvapCoolerTest():
    var self = EnergyPlusFixture(EnergyPlusData())
    self.state.init_state(self.state)
    var EvapCond = self.state.dataEvapCoolers.EvapCond
    const EvapCoolNum: Int = 0
    var PrimaryAirDesignFlow: Float64 = 0.0
    var RecirWaterPumpDesignPower: Float64 = 0.0
    self.state.dataSize.SysSizingRunDone = true
    self.state.dataSize.NumSysSizInput = 1
    self.state.dataSize.SysSizInput = Array[SystemSizingInputData](1)
    self.state.dataSize.SysSizInput[0].AirLoopNum = 1
    self.state.dataSize.CurSysNum = 0
    self.state.dataSize.FinalSysSizing = Array[FinalSysSizingData](self.state.dataSize.CurSysNum + 1)
    self.state.dataSize.FinalSysSizing[0].DesMainVolFlow = 1.0
    self.state.dataSize.FinalSysSizing[0].DesOutAirVolFlow = 0.4
    self.state.dataAirSystemsData.PrimaryAirSystems = Array[PrimaryAirSystemData](self.state.dataSize.CurSysNum + 1)
    self.state.dataAirSystemsData.PrimaryAirSystems[0].Branch = Array[BranchData](1)
    self.state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].Comp = Array[CompData](1)
    self.state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].Comp[0].Name = "DIRECTEVAPCOOLER"
    self.state.dataAirSystemsData.PrimaryAirSystems[0].NumBranches = 1
    self.state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].TotalComponents = 1
    const idf_objects: String = delimited_string(Array[String](
        "\tEvaporativeCooler:Direct:ResearchSpecial,",
        "\tDirectEvapCooler,    !- Name",
        "\t,\t\t\t         !- Availability Schedule Name",
        "\t0.7,\t\t\t\t !- Cooler Design Effectiveness",
        "\t,\t\t\t\t\t !- Effectiveness Flow Ratio Modifier Curve Name",
        "\tautosize,\t\t\t !- Primary Air Design Flow Rate",
        "\tautosize,\t\t\t !- Recirculating Water Pump Power Consumption { W }",
        "\t55.0,\t\t\t\t !- Water Pump Power Sizing Factor",
        "\t,\t\t\t\t\t !- Water Pump Power Modifier Curve Name",
        "\tFan Outlet Node,     !- Air Inlet Node Name",
        "\tZone Inlet Node,\t !- Air Outlet Node Name",
        "\tZone Inlet Node,\t !- Sensor Node Name",
        "\t,\t\t\t\t\t !- Water Supply Storage Tank Name",
        "\t0.0,\t\t\t\t !- Drift Loss Fraction",
        "\t3;                   !- Blowdown Concentration Ratio",
    ))
    ASSERT_TRUE(process_idf(idf_objects))
    GetEvapInput(self.state)
    EXPECT_EQ(AutoSize, EvapCond[EvapCoolNum].DesVolFlowRate)
    EXPECT_EQ(AutoSize, EvapCond[EvapCoolNum].RecircPumpPower)
    self.state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].Comp[0].Name = EvapCond[EvapCoolNum].Name
    self.state.dataSize.FinalSysSizing[0].DesMainVolFlow = 0.50
    PrimaryAirDesignFlow = self.state.dataSize.FinalSysSizing[0].DesMainVolFlow
    RecirWaterPumpDesignPower = PrimaryAirDesignFlow * EvapCond[EvapCoolNum].RecircPumpSizingFactor
    SizeEvapCooler(self.state, 0)  # EvapCoolNum = 0
    EXPECT_EQ(PrimaryAirDesignFlow, EvapCond[EvapCoolNum].DesVolFlowRate)
    EXPECT_EQ(RecirWaterPumpDesignPower, EvapCond[EvapCoolNum].RecircPumpPower)
    EvapCond.deallocate()
    self.state.dataAirSystemsData.PrimaryAirSystems.deallocate()
    self.state.dataSize.FinalSysSizing.deallocate()

@test
def EvaporativeCoolers_CalcSecondaryAirOutletCondition():
    var self = EnergyPlusFixture(EnergyPlusData())
    self.state.init_state(self.state)
    var EvapCond = self.state.dataEvapCoolers.EvapCond
    EvapCond.allocate(1)
    const EvapCoolNum: Int = 0
    EvapCond[EvapCoolNum].SecInletEnthalpy = 42000.0
    var OperatingMode: OperatingMode = OperatingMode.None
    var AirMassFlowSec: Float64 = 0.0
    const EDBTSec: Float64 = 20.0
    const EWBTSec: Float64 = 15.0
    const EHumRatSec: Float64 = 0.0085
    var QHXTotal: Float64 = 0.0
    var QHXLatent: Float64 = 0.0
    EvaporativeCoolers.CalcSecondaryAirOutletCondition(
        self.state, EvapCoolNum, OperatingMode, AirMassFlowSec, EDBTSec, EWBTSec, EHumRatSec, QHXTotal, QHXLatent)
    EXPECT_DOUBLE_EQ(EvapCond[EvapCoolNum].SecOutletEnthalpy, EvapCond[EvapCoolNum].SecInletEnthalpy)
    EXPECT_DOUBLE_EQ(0.0, QHXLatent)
    OperatingMode = OperatingMode.DryFull
    AirMassFlowSec = 2.0
    QHXTotal = 10206.410750000941
    EvaporativeCoolers.CalcSecondaryAirOutletCondition(
        self.state, EvapCoolNum, OperatingMode, AirMassFlowSec, EDBTSec, EWBTSec, EHumRatSec, QHXTotal, QHXLatent)
    EXPECT_NEAR(25.0, EvapCond[EvapCoolNum].SecOutletTemp, 0.000001)
    EXPECT_DOUBLE_EQ(0.0, QHXLatent)
    OperatingMode = OperatingMode.WetFull
    AirMassFlowSec = 2.0
    QHXTotal = 10206.410750000941
    EvaporativeCoolers.CalcSecondaryAirOutletCondition(
        self.state, EvapCoolNum, OperatingMode, AirMassFlowSec, EDBTSec, EWBTSec, EHumRatSec, QHXTotal, QHXLatent)
    EXPECT_DOUBLE_EQ(20.0, EvapCond[EvapCoolNum].SecOutletTemp)
    EXPECT_DOUBLE_EQ(47103.205375000471, EvapCond[EvapCoolNum].SecOutletEnthalpy)
    EXPECT_DOUBLE_EQ(QHXTotal, QHXLatent)
    EvapCond.deallocate()

@test
def EvaporativeCoolers_CalcIndirectRDDEvapCoolerOutletTemp():
    var self = EnergyPlusFixture(EnergyPlusData())
    self.state.init_state(self.state)
    var EvapCond = self.state.dataEvapCoolers.EvapCond
    self.state.dataEnvrn.OutBaroPress = 101325.0
    EvapCond.allocate(1)
    const EvapCoolNum: Int = 0
    EvapCond[EvapCoolNum].InletMassFlowRate = 1.0
    EvapCond[EvapCoolNum].InletTemp = 24.0
    EvapCond[EvapCoolNum].InletHumRat = 0.013
    EvapCond[EvapCoolNum].DryCoilMaxEfficiency = 0.8
    var DryOrWetOperatingMode: OperatingMode = OperatingMode.DryFull
    const AirMassFlowSec: Float64 = 1.0
    const EDBTSec: Float64 = 14.0
    const EWBTSec: Float64 = 11.0
    const EHumRatSec: Float64 = 0.0075
    EvaporativeCoolers.CalcIndirectRDDEvapCoolerOutletTemp(self.state, EvapCoolNum, DryOrWetOperatingMode, AirMassFlowSec, EDBTSec, EWBTSec, EHumRatSec)
    EXPECT_DOUBLE_EQ(16.0, EvapCond[EvapCoolNum].OutletTemp)
    DryOrWetOperatingMode = OperatingMode.WetFull
    EvapCond[EvapCoolNum].WetCoilMaxEfficiency = 0.75
    EvaporativeCoolers.CalcIndirectRDDEvapCoolerOutletTemp(self.state, EvapCoolNum, DryOrWetOperatingMode, AirMassFlowSec, EDBTSec, EWBTSec, EHumRatSec)
    EXPECT_DOUBLE_EQ(14.25, EvapCond[EvapCoolNum].OutletTemp)
    EvapCond.deallocate()

@test
def EvaporativeCoolers_IndEvapCoolerPower():
    var self = EnergyPlusFixture(EnergyPlusData())
    self.state.init_state(self.state)
    var EvapCond = self.state.dataEvapCoolers.EvapCond
    EvapCond.allocate(1)
    const EvapCoolNum: Int = 0
    EvapCond[EvapCoolNum].IndirectFanPower = 200.0
    EvapCond[EvapCoolNum].IndirectRecircPumpPower = 100.0
    var DryWetMode: OperatingMode = OperatingMode.DryFull
    var FlowRatio: Float64 = 1.0
    var curve = AddCurve(self.state, "Curve1")
    EvapCond[EvapCoolNum].FanPowerModifierCurve = curve
    curve.curveType = CurveType.Quadratic
    curve.coeff[0] = 0.0
    curve.coeff[1] = 1.0
    curve.coeff[2] = 0.0
    curve.coeff[3] = 0.0
    curve.coeff[4] = 0.0
    curve.coeff[5] = 0.0
    curve.inputLimits[0].min = 0.0
    curve.inputLimits[0].max = 1.0
    curve.inputLimits[1].min = 0
    curve.inputLimits[1].max = 0
    EvapCond[EvapCoolNum].EvapCoolerPower = IndEvapCoolerPower(self.state, EvapCoolNum, DryWetMode, FlowRatio)
    EXPECT_EQ(200.0, EvapCond[EvapCoolNum].EvapCoolerPower)
    DryWetMode = OperatingMode.WetModulated
    FlowRatio = 0.8
    EvapCond[EvapCoolNum].PartLoadFract = 0.5
    EvapCond[EvapCoolNum].EvapCoolerPower = IndEvapCoolerPower(self.state, EvapCoolNum, DryWetMode, FlowRatio)
    EXPECT_EQ(200 * 0.8 + 100 * 0.8 * 0.5, EvapCond[EvapCoolNum].EvapCoolerPower)
    EvapCond.deallocate()
    self.state.dataCurveManager.curves.deallocate()

@test
def EvaporativeCoolers_SizeEvapCooler():
    var self = EnergyPlusFixture(EnergyPlusData())
    self.state.init_state(self.state)
    var EvapCond = self.state.dataEvapCoolers.EvapCond
    const EvapCoolNum: Int = 0
    EvapCond.allocate(EvapCoolNum + 1)
    var thisEvapCooler = EvapCond[EvapCoolNum]
    self.state.dataSize.SysSizingRunDone = true
    self.state.dataSize.ZoneSizingRunDone = false
    self.state.dataSize.CurSysNum = 0
    self.state.dataSize.NumSysSizInput = 1
    self.state.dataSize.SysSizInput = Array[SystemSizingInputData](1)
    self.state.dataSize.SysSizInput[0].AirLoopNum = 1
    self.state.dataAirSystemsData.PrimaryAirSystems = Array[PrimaryAirSystemData](1)
    self.state.dataAirSystemsData.PrimaryAirSystems[0].NumBranches = 1
    self.state.dataAirSystemsData.PrimaryAirSystems[0].Branch = Array[BranchData](1)
    self.state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].TotalComponents = 1
    self.state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].Comp = Array[CompData](1)
    self.state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].Comp[0].Name = "MyEvapCooler"
    thisEvapCooler.Name = "MyEvapCooler"
    self.state.dataSize.FinalSysSizing = Array[FinalSysSizingData](1)
    self.state.dataSize.FinalSysSizing[0].DesMainVolFlow = 1.0
    self.state.dataSize.FinalSysSizing[0].DesOutAirVolFlow = 0.4
    thisEvapCooler.evapCoolerType = EvapCoolerType.IndirectRDDSpecial
    thisEvapCooler.DesVolFlowRate = AutoSize
    thisEvapCooler.PadArea = 0.0
    thisEvapCooler.PadDepth = 0.0
    thisEvapCooler.IndirectPadArea = 0.0
    thisEvapCooler.IndirectPadDepth = 0.0
    thisEvapCooler.IndirectVolFlowRate = AutoSize
    thisEvapCooler.IndirectVolFlowScalingFactor = 0.3
    SizeEvapCooler(self.state, EvapCoolNum)
    EXPECT_NEAR(0.3, thisEvapCooler.IndirectVolFlowRate, 0.0001)
    EXPECT_NEAR(1.0, thisEvapCooler.DesVolFlowRate, 0.0001)
    thisEvapCooler.evapCoolerType = EvapCoolerType.DirectCELDEKPAD
    thisEvapCooler.DesVolFlowRate = 1.0
    thisEvapCooler.PadArea = AutoSize
    thisEvapCooler.PadDepth = AutoSize
    thisEvapCooler.IndirectPadArea = 0.0
    thisEvapCooler.IndirectPadDepth = 0.0
    thisEvapCooler.IndirectVolFlowRate = 1.0
    SizeEvapCooler(self.state, EvapCoolNum)
    EXPECT_NEAR(0.333333, thisEvapCooler.PadArea, 0.0001)
    EXPECT_NEAR(0.17382, thisEvapCooler.PadDepth, 0.0001)
    self.state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].Comp[0].Name = "NOT-MyEvapCooler"
    thisEvapCooler.evapCoolerType = EvapCoolerType.IndirectCELDEKPAD
    thisEvapCooler.DesVolFlowRate = AutoSize
    thisEvapCooler.PadArea = 0.0
    thisEvapCooler.PadDepth = 0.0
    thisEvapCooler.IndirectPadArea = 0.0
    thisEvapCooler.IndirectPadDepth = 0.0
    thisEvapCooler.IndirectVolFlowRate = AutoSize
    thisEvapCooler.IndirectVolFlowScalingFactor = 0.3
    SizeEvapCooler(self.state, EvapCoolNum)
    EXPECT_NEAR(0.5, thisEvapCooler.IndirectVolFlowRate, 0.0001)
    EXPECT_NEAR(0.5, thisEvapCooler.DesVolFlowRate, 0.0001)
    EvapCond.deallocate()
    self.state.dataSize.FinalSysSizing.deallocate()
    self.state.dataAirSystemsData.PrimaryAirSystems.deallocate()
    self.state.dataSize.SysSizInput.deallocate()

@test
def DefaultAutosizeIndEvapCoolerTest():
    var self = EnergyPlusFixture(EnergyPlusData())
    self.state.init_state(self.state)
    const EvapCoolNum: Int = 0
    var PrimaryAirDesignFlow: Float64 = 0.0
    var SecondaryAirDesignFlow: Float64 = 0.0
    var SecondaryFanPower: Float64 = 0.0
    var RecirculatingWaterPumpPower: Float64 = 0.0
    self.state.dataSize.SysSizingRunDone = true
    self.state.dataSize.NumSysSizInput = 1
    self.state.dataSize.SysSizInput = Array[SystemSizingInputData](1)
    self.state.dataSize.SysSizInput[0].AirLoopNum = 1
    self.state.dataSize.CurSysNum = 0
    self.state.dataSize.FinalSysSizing = Array[FinalSysSizingData](self.state.dataSize.CurSysNum + 1)
    self.state.dataSize.FinalSysSizing[0].DesMainVolFlow = 1.0
    self.state.dataSize.FinalSysSizing[0].DesOutAirVolFlow = 0.4
    self.state.dataAirSystemsData.PrimaryAirSystems = Array[PrimaryAirSystemData](self.state.dataSize.CurSysNum + 1)
    self.state.dataAirSystemsData.PrimaryAirSystems[0].Branch = Array[BranchData](1)
    self.state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].Comp = Array[CompData](1)
    self.state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].Comp[0].Name = "INDRDD EVAP COOLER"
    self.state.dataAirSystemsData.PrimaryAirSystems[0].NumBranches = 1
    self.state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].TotalComponents = 1
    const idf_objects: String = delimited_string(Array[String](
        "\tEvaporativeCooler:Indirect:ResearchSpecial,",
        "\tIndRDD Evap Cooler,  !- Name",
        "\t,\t\t\t         !- Availability Schedule Name",
        "\t0.750,\t\t\t\t !- Cooler Wetbulb Design Effectiveness",
        "\t,\t\t\t\t\t !- Wetbulb Effectiveness Flow Ratio Modifier Curve Name",
        "\t,\t\t\t\t\t !- Cooler Drybulb Design Effectiveness",
        "\t,\t\t\t\t\t !- Drybulb Effectiveness Flow Ratio Modifier Curve Name",
        "\t,   \t\t\t\t !- Recirculating Water Pump Design Power { W }",
        "\t,\t\t\t\t\t !- Water Pump Power Sizing Factor",
        "\t,\t\t\t\t\t !- Water Pump Power Modifier Curve Name",
        "\t,        \t\t\t !- Secondary Air Design Flow Rate { m3 / s }",
        "\t1.2,\t\t\t\t !- Secondary Air Flow Sizing Factor",
        "\t,        \t\t\t !- Secondary Air Fan Design Power",
        "\t207.6,\t\t\t\t !- Secondary Air Fan Sizing Specific Power",
        "\t,\t\t\t\t\t !- Secondary Fan Power Modifier Curve Name",
        "\tPriAir Inlet Node,\t !- Primary Air Inlet Node Name",
        "\tPriAir Outlet Node,\t !- Primary Air Outlet Node Name",
        "\t,       \t\t\t !- Primary Air Design Air Flow Rate",
        "\t0.90,\t\t\t\t !- Dewpoint Effectiveness Factor",
        "\tSecAir Inlet Node,   !- Secondary Air Inlet Node Name",
        "\tSecAir Outlet Node,  !- Secondary Air Outlet Node Name",
        "\tPriAir Outlet Node,\t !- Sensor Node Name",
        "\t,\t\t\t\t\t !- Relief Air Inlet Node Name",
        "\t,\t\t\t\t\t !- Water Supply Storage Tank Name",
        "\t0.0,\t\t\t\t !- Drift Loss Fraction",
        "\t3;                   !- Blowdown Concentration Ratio",
        "Schedule:Constant,",
        "  ALWAYS_ON,    !- Name",
        "  ,             !- Schedule Type Limits Name",
        "  1.0;          !- Hourly Value",
    ))
    ASSERT_TRUE(process_idf(idf_objects))
    GetEvapInput(self.state)
    var EvapCond = self.state.dataEvapCoolers.EvapCond
    EXPECT_EQ(AutoSize, EvapCond[EvapCoolNum].DesVolFlowRate)
    EXPECT_EQ(AutoSize, EvapCond[EvapCoolNum].IndirectVolFlowRate)
    EXPECT_EQ(AutoSize, EvapCond[EvapCoolNum].IndirectFanPower)
    EXPECT_EQ(AutoSize, EvapCond[EvapCoolNum].IndirectRecircPumpPower)
    self.state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].Comp[0].Name = EvapCond[EvapCoolNum].Name
    self.state.dataSize.FinalSysSizing[0].DesMainVolFlow = 1.0
    self.state.dataSize.FinalSysSizing[0].DesOutAirVolFlow = 0.2
    PrimaryAirDesignFlow = self.state.dataSize.FinalSysSizing[0].DesMainVolFlow
    SecondaryAirDesignFlow = PrimaryAirDesignFlow * EvapCond[EvapCoolNum].IndirectVolFlowScalingFactor
    SizeEvapCooler(self.state, EvapCoolNum)
    EXPECT_EQ(PrimaryAirDesignFlow, EvapCond[EvapCoolNum].DesVolFlowRate)
    EXPECT_EQ(SecondaryAirDesignFlow, EvapCond[EvapCoolNum].IndirectVolFlowRate)
    SecondaryFanPower = SecondaryAirDesignFlow * EvapCond[EvapCoolNum].FanSizingSpecificPower
    RecirculatingWaterPumpPower = SecondaryAirDesignFlow * EvapCond[EvapCoolNum].RecircPumpSizingFactor
    EXPECT_EQ(SecondaryFanPower, EvapCond[EvapCoolNum].IndirectFanPower)
    EXPECT_EQ(RecirculatingWaterPumpPower, EvapCond[EvapCoolNum].IndirectRecircPumpPower)
    EvapCond.deallocate()
    self.state.dataAirSystemsData.PrimaryAirSystems.deallocate()
    self.state.dataSize.FinalSysSizing.deallocate()

@test
def DefaultAutosizeDirEvapCoolerTest():
    var self = EnergyPlusFixture(EnergyPlusData())
    self.state.init_state(self.state)
    const EvapCoolNum: Int = 0
    var PrimaryAirDesignFlow: Float64 = 0.0
    var RecirWaterPumpDesignPower: Float64 = 0.0
    self.state.dataSize.SysSizingRunDone = true
    self.state.dataSize.NumSysSizInput = 1
    self.state.dataSize.SysSizInput = Array[SystemSizingInputData](1)
    self.state.dataSize.SysSizInput[0].AirLoopNum = 1
    self.state.dataSize.CurSysNum = 0
    self.state.dataSize.FinalSysSizing = Array[FinalSysSizingData](self.state.dataSize.CurSysNum + 1)
    self.state.dataSize.FinalSysSizing[0].DesMainVolFlow = 1.0
    self.state.dataSize.FinalSysSizing[0].DesOutAirVolFlow = 0.4
    self.state.dataAirSystemsData.PrimaryAirSystems = Array[PrimaryAirSystemData](self.state.dataSize.CurSysNum + 1)
    self.state.dataAirSystemsData.PrimaryAirSystems[0].Branch = Array[BranchData](1)
    self.state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].Comp = Array[CompData](1)
    self.state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].Comp[0].Name = "DIRECTEVAPCOOLER"
    self.state.dataAirSystemsData.PrimaryAirSystems[0].NumBranches = 1
    self.state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].TotalComponents = 1
    const idf_objects: String = delimited_string(Array[String](
        "\tEvaporativeCooler:Direct:ResearchSpecial,",
        "\tDirectEvapCooler,    !- Name",
        "\t,\t\t\t         !- Availability Schedule Name",
        "\t0.7,\t\t\t\t !- Cooler Design Effectiveness",
        "\t,\t\t\t\t\t !- Effectiveness Flow Ratio Modifier Curve Name",
        "\t,          \t\t\t !- Primary Air Design Flow Rate",
        "\t,               \t !- Recirculating Water Pump Power Consumption { W }",
        "\t55.0,\t\t\t\t !- Water Pump Power Sizing Factor",
        "\t,\t\t\t\t\t !- Water Pump Power Modifier Curve Name",
        "\tFan Outlet Node,     !- Air Inlet Node Name",
        "\tZone Inlet Node,\t !- Air Outlet Node Name",
        "\tZone Inlet Node,\t !- Sensor Node Name",
        "\t,\t\t\t\t\t !- Water Supply Storage Tank Name",
        "\t0.0,\t\t\t\t !- Drift Loss Fraction",
        "\t3;                   !- Blowdown Concentration Ratio",
    ))
    ASSERT_TRUE(process_idf(idf_objects))
    GetEvapInput(self.state)
    var EvapCond = self.state.dataEvapCoolers.EvapCond
    EXPECT_EQ(AutoSize, EvapCond[EvapCoolNum].DesVolFlowRate)
    EXPECT_EQ(AutoSize, EvapCond[EvapCoolNum].RecircPumpPower)
    self.state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].Comp[0].Name = EvapCond[EvapCoolNum].Name
    self.state.dataSize.FinalSysSizing[0].DesMainVolFlow = 0.50
    PrimaryAirDesignFlow = self.state.dataSize.FinalSysSizing[0].DesMainVolFlow
    RecirWaterPumpDesignPower = PrimaryAirDesignFlow * EvapCond[EvapCoolNum].RecircPumpSizingFactor
    SizeEvapCooler(self.state, 0)
    EXPECT_EQ(PrimaryAirDesignFlow, EvapCond[EvapCoolNum].DesVolFlowRate)
    EXPECT_EQ(RecirWaterPumpDesignPower, EvapCond[EvapCoolNum].RecircPumpPower)
    EvapCond.deallocate()
    self.state.dataAirSystemsData.PrimaryAirSystems.deallocate()
    self.state.dataSize.FinalSysSizing.deallocate()

@test
def DirectEvapCoolerResearchSpecialCalcTest():
    var self = EnergyPlusFixture(EnergyPlusData())
    self.state.init_state(self.state)
    var EvapCond = self.state.dataEvapCoolers.EvapCond
    const EvapCoolNum: Int = 0
    EvapCond.allocate(EvapCoolNum + 1)
    self.state.dataLoopNodes.Node = Array[NodeData](2)
    var thisEvapCooler = EvapCond[EvapCoolNum]
    self.state.dataEnvrn.OutBaroPress = 101325.0
    var curve = AddCurve(self.state, "Curve1")
    curve.curveType = CurveType.Quadratic
    curve.coeff[0] = 0.0
    curve.coeff[1] = 1.0
    curve.inputLimits[0].min = 0.0
    curve.inputLimits[0].max = 1.0
    thisEvapCooler.evapCoolerType = EvapCoolerType.DirectResearchSpecial
    thisEvapCooler.Name = "MyDirectEvapCoolerRS"
    thisEvapCooler.availSched = Sched.GetScheduleAlwaysOn(self.state)
    thisEvapCooler.PumpPowerModifierCurve = curve
    thisEvapCooler.DirectEffectiveness = 0.75
    thisEvapCooler.DesVolFlowRate = 1.0
    thisEvapCooler.InletNode = 0  # 1-based -> 0-based
    thisEvapCooler.InletTemp = 25.0
    thisEvapCooler.InletWetBulbTemp = 21.0
    thisEvapCooler.InletHumRat = PsyWFnTdbTwbPb(self.state, thisEvapCooler.InletTemp, thisEvapCooler.InletWetBulbTemp, self.state.dataEnvrn.OutBaroPress)
    self.state.dataLoopNodes.Node[thisEvapCooler.InletNode].MassFlowRateMax = 1.0
    thisEvapCooler.InletMassFlowRate = 1.0
    thisEvapCooler.RecircPumpPower = 200.0
    thisEvapCooler.PartLoadFract = 1.0
    CalcDirectResearchSpecialEvapCooler(self.state, EvapCoolNum)
    EXPECT_DOUBLE_EQ(200.0, thisEvapCooler.RecircPumpPower)
    EXPECT_DOUBLE_EQ(200.0, thisEvapCooler.EvapCoolerPower)
    thisEvapCooler.InletMassFlowRate = 0.5
    CalcDirectResearchSpecialEvapCooler(self.state, EvapCoolNum)
    EXPECT_DOUBLE_EQ(200.0, thisEvapCooler.RecircPumpPower)
    EXPECT_DOUBLE_EQ(100.0, thisEvapCooler.EvapCoolerPower)

@test
def EvaporativeCoolers_IndirectRDDEvapCoolerOperatingMode():
    var self = EnergyPlusFixture(EnergyPlusData())
    self.state.init_state(self.state)
    var EvapCond = self.state.dataEvapCoolers.EvapCond
    self.state.dataEnvrn.OutBaroPress = 101325.0
    const EvapCoolNum: Int = 0
    EvapCond.allocate(EvapCoolNum + 1)
    var thisEvapCooler = EvapCond[EvapCoolNum]
    thisEvapCooler.InletMassFlowRate = 1.0
    thisEvapCooler.SecInletMassFlowRate = 1.0
    thisEvapCooler.MinOATDBEvapCooler = -99.0
    thisEvapCooler.MaxOATDBEvapCooler = 99.0
    thisEvapCooler.MaxOATWBEvapCooler = 99.0
    thisEvapCooler.WetCoilMaxEfficiency = 0.8
    thisEvapCooler.InletTemp = 25.5
    thisEvapCooler.InletHumRat = 0.0140
    thisEvapCooler.InletWetBulbTemp =
        PsyTwbFnTdbWPb(self.state, EvapCond[EvapCoolNum].InletTemp, EvapCond[EvapCoolNum].InletHumRat, self.state.dataEnvrn.OutBaroPress)
    thisEvapCooler.SecInletTemp = thisEvapCooler.InletTemp
    thisEvapCooler.SecInletHumRat = thisEvapCooler.InletHumRat
    thisEvapCooler.SecInletWetBulbTemp = thisEvapCooler.InletWetBulbTemp
    const TdbOutSysWetMin: Float64 = 22.0
    const TdbOutSysDryMin: Float64 = 25.5
    thisEvapCooler.DesiredOutletTemp = 21.0
    var Result_WetFullOperatingMode: OperatingMode = IndirectResearchSpecialEvapCoolerOperatingMode(
        self.state, EvapCoolNum, thisEvapCooler.SecInletTemp, thisEvapCooler.SecInletWetBulbTemp, TdbOutSysWetMin, TdbOutSysDryMin)
    EXPECT_ENUM_EQ(Result_WetFullOperatingMode, OperatingMode.WetFull)
    CalcIndirectRDDEvapCoolerOutletTemp(self.state,
                                        EvapCoolNum,
                                        Result_WetFullOperatingMode,
                                        thisEvapCooler.SecInletMassFlowRate,
                                        thisEvapCooler.SecInletTemp,
                                        thisEvapCooler.SecInletWetBulbTemp,
                                        thisEvapCooler.SecInletHumRat)
    EXPECT_NEAR(22.036, thisEvapCooler.OutletTemp, 0.001)

@test
def DirectEvapCoolerAutosizeWithoutSysSizingRunDone():
    var self = EnergyPlusFixture(EnergyPlusData())
    self.state.init_state(self.state)
    const EvapCoolNum: Int = 0
    self.state.dataSize.NumSysSizInput = 1
    self.state.dataSize.SysSizInput = Array[SystemSizingInputData](1)
    self.state.dataSize.SysSizInput[0].AirLoopNum = 1
    self.state.dataSize.CurSysNum = 0
    self.state.dataAirSystemsData.PrimaryAirSystems = Array[PrimaryAirSystemData](self.state.dataSize.CurSysNum + 1)
    self.state.dataAirSystemsData.PrimaryAirSystems[0].Branch = Array[BranchData](1)
    self.state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].Comp = Array[CompData](1)
    self.state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].Comp[0].Name = "DIRECTEVAPCOOLER"
    self.state.dataAirSystemsData.PrimaryAirSystems[0].NumBranches = 1
    self.state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].TotalComponents = 1
    const idf_objects: String = delimited_string(Array[String](
        "\tEvaporativeCooler:Direct:ResearchSpecial,",
        "\tDirectEvapCooler,    !- Name",
        "\t,\t\t\t         !- Availability Schedule Name",
        "\t0.7,\t\t\t\t !- Cooler Design Effectiveness",
        "\t,\t\t\t\t\t !- Effectiveness Flow Ratio Modifier Curve Name",
        "\t,          \t\t\t !- Primary Air Design Flow Rate",
        "\t440,               \t !- Recirculating Water Pump Power Consumption { W }",
        "\t1.0,     \t\t\t !- Water Pump Power Sizing Factor",
        "\t,\t\t\t\t\t !- Water Pump Power Modifier Curve Name",
        "\tFan Outlet Node,     !- Air Inlet Node Name",
        "\tZone Inlet Node,\t !- Air Outlet Node Name",
        "\tZone Inlet Node,\t !- Sensor Node Name",
        "\t,\t\t\t\t\t !- Water Supply Storage Tank Name",
        "\t0.0,\t\t\t\t !- Drift Loss Fraction",
        "\t3;                   !- Blowdown Concentration Ratio",
    ))
    ASSERT_TRUE(process_idf(idf_objects))
    GetEvapInput(self.state)
    var EvapCond = self.state.dataEvapCoolers.EvapCond
    EXPECT_EQ(AutoSize, EvapCond[EvapCoolNum].DesVolFlowRate)
    self.state.dataAirSystemsData.PrimaryAirSystems[0].Branch[0].Comp[0].Name = EvapCond[EvapCoolNum].Name
    self.state.dataSize.SysSizingRunDone = false
    ASSERT_THROW(SizeEvapCooler(self.state, 0), RuntimeError)
    const error_string: String = delimited_string(Array[String](
        format("   ** Warning ** Version: missing in IDF, processing for EnergyPlus version=\"{}\"", DataStringGlobals.MatchVersion),
        "   ** Severe  ** For autosizing of EvaporativeCooler:Direct:ResearchSpecial DIRECTEVAPCOOLER, a system sizing run must be done.",
        "   **   ~~~   ** The \"SimulationControl\" object did not have the field \"Do System Sizing Calculation\" set to Yes.",
        "   **  Fatal  ** Program terminates due to previously shown condition(s).",
        "   ...Summary of Errors that led to program termination:",
        "   ..... Reference severe error count=1",
        "   ..... Last severe error=For autosizing of EvaporativeCooler:Direct:ResearchSpecial DIRECTEVAPCOOLER, a system sizing run must be done.",
    ))
    EXPECT_TRUE(compare_err_stream(error_string, true))

@test
def EvapCoolerAirLoopPumpCycling():
    var ErrorsFound: Bool = false
    const idf_objects: String = delimited_string(Array[String](
        " EvaporativeCooler:Direct:CelDekPad,",
        "    Direct CelDekPad EvapCooler, !- Name",
        "    ,                            !- Availability Schedule Name",
        "    0.6,                         !- Direct Pad Area {m2}",
        "    0.17,                        !- Direct Pad Depth {m}",
        "    60,                          !- Recirculating Water Pump Power Consumption {W}",
        "    ZoneEvapCool Fan outlet,     !- Air Inlet Node Name",
        "    ZoneEvapCool Inlet Node,     !- Air Outlet Node Name",
        "    ;                            !- Control Type",
    ))
    ASSERT_TRUE(process_idf(idf_objects))
    var self = EnergyPlusFixture(EnergyPlusData())
    self.state.init_state(self.state)
    GetEvapInput(self.state)
    ASSERT_FALSE(ErrorsFound)
    var EvapCond = self.state.dataEvapCoolers.EvapCond
    var AirLoopNum: Int = 0  # 1 -> 0
    var EvapCoolNum: Int = 0
    self.state.dataEnvrn.OutBaroPress = 101325.0
    self.state.dataAirLoop.AirLoopFlow = Array[AirLoopFlowData](AirLoopNum + 1)
    self.state.dataAirLoop.AirLoopControlInfo = Array[AirLoopControlInfo](AirLoopNum + 1)
    self.state.dataAirLoop.AirLoopFlow[0].FanPLR = 0.8
    self.state.dataLoopNodes.Node[EvapCond[EvapCoolNum].InletNode].MassFlowRate = 0.5
    self.state.dataLoopNodes.Node[EvapCond[EvapCoolNum].InletNode].Temp = 28.0
    self.state.dataLoopNodes.Node[EvapCond[EvapCoolNum].InletNode].HumRat = 0.001
    self.state.dataLoopNodes.Node[EvapCond[EvapCoolNum].InletNode].Press = self.state.dataEnvrn.OutBaroPress
    self.state.dataGlobal.BeginEnvrnFlag = true
    var airLoopNum: Int = 0
    var branchNum: Int = 0
    var compNum: Int = 0
    SimAirLoopComponent(self.state,
                        EvapCond[EvapCoolNum].Name,
                        CompType.EvapCooler,
                        false,
                        AirLoopNum,
                        EvapCoolNum,
                        0,
                        airLoopNum,
                        branchNum,
                        compNum)
    EXPECT_EQ(EvapCond[EvapCoolNum].EvapCoolerPower, 60 * 0.8)