from .Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.ConfiguredFunctions import configured_source_directory
from EnergyPlus.CurveManager import *
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataAirLoop import *
from EnergyPlus.DataAirSystems import *
from EnergyPlus.DataContaminantBalance import *
from EnergyPlus.DataEnvironment import *
from EnergyPlus.DataGlobalConstants import Constant
from EnergyPlus.DataGlobals import *
from EnergyPlus.DataHVACGlobals import *
from EnergyPlus.DataHeatBalance import *
from EnergyPlus.DataLoopNode import *
from EnergyPlus.DataSizing import *
from EnergyPlus.DataZoneControls import *
from EnergyPlus.DataZoneEnergyDemands import *
from EnergyPlus.DataZoneEquipment import *
from EnergyPlus.EvaporativeCoolers import *
from EnergyPlus.FileSystem import *
from EnergyPlus.General import General
from EnergyPlus.HeatBalanceManager import *
from EnergyPlus.Humidifiers import *
from EnergyPlus.HybridEvapCoolingModel import CMode, CSetting, Model, CStepInputs, ObjectiveFunctionType
from EnergyPlus.HybridUnitaryAirConditioners import *
from EnergyPlus.IOFiles import *
from EnergyPlus.MixedAir import *
from EnergyPlus.OutputReportPredefined import *
from EnergyPlus.Psychrometrics import PsyHFnTdbRhPb, PsyRhFnTdbWPb, PsyWFnTdbRhPb
from EnergyPlus.ScheduleManager import Sched
from EnergyPlus.SizingManager import *
from EnergyPlus.SystemReports import *
from EnergyPlus.ZoneTempPredictorCorrector import *

alias Real64 = Float64

def expect_eq[T: Equatable](actual: T, expected: T):
    assert actual == expected

def expect_near(actual: Real64, expected: Real64, tol: Real64):
    assert Math.abs(actual - expected) <= tol

def expect_gt(actual: Real64, threshold: Real64):
    assert actual > threshold

def expect_lt(actual: Real64, threshold: Real64):
    assert actual < threshold

def expect_false(condition: Bool):
    assert not condition

def assert_true(condition: Bool):
    assert condition

def delimited_string(lines: List[String]) -> String:
    return "\n".join(lines)

def read_lines_in_file(path: String) -> List[String]:
    # stub, assume file reading works
    return List[String]()

# Test fixture struct
struct EnergyPlusFixture:
    var state: EnergyPlusData

    def __init__(inout self):
        self.state = EnergyPlusData()

    def process_idf(self, idf_string: String) -> Bool:
        # stub
        return True

@test
def Test_UnitaryHybridAirConditioner_Unittest():
    var fixture = EnergyPlusFixture()
    var state = fixture.state
    var idf_path = configured_source_directory() + "/tst/EnergyPlus/unit/Resources/UnitaryHybridUnitTest_DOSA.idf"
    var idf_content = read_lines_in_file(idf_path)
    assert_true(fixture.process_idf(delimited_string(idf_content)))
    state.dataGlobal.TimeStepsInHour = 1
    state.dataGlobal.MinutesInTimeStep = 60
    state.init_state(state)
    var ErrorsFound: Bool = False
    GetZoneData(state, ErrorsFound)
    expect_false(ErrorsFound)
    state.dataGlobal.TimeStep = 1
    state.dataHVACGlobal.TimeStepSys = 1
    state.dataHVACGlobal.TimeStepSysSec = state.dataHVACGlobal.TimeStepSys * Constant.rSecsInHour
    state.dataEnvrn.Month = 1
    state.dataEnvrn.DayOfMonth = 21
    state.dataGlobal.HourOfDay = 1
    state.dataEnvrn.DSTIndicator = 0
    state.dataEnvrn.DayOfWeek = 2
    state.dataEnvrn.HolidayIndex = 0
    state.dataGlobal.WarmupFlag = False
    state.dataEnvrn.DayOfYear_Schedule = General.OrdinalDay(state.dataEnvrn.Month, state.dataEnvrn.DayOfMonth, 1)
    Sched.UpdateScheduleVals(state)
    state.dataHeatBal.Zone[0].FloorArea = 232.26  # 1-based -> 0-based
    state.dataEnvrn.StdRhoAir = 1.225
    state.dataEnvrn.OutBaroPress = 101325
    state.dataHeatBal.ZoneIntGain.allocate(1)
    SizingManager.GetOARequirements(state)
    GetOAControllerInputs(state)
    using DataEnvironment: # not needed in Mojo
    Sched.UpdateScheduleVals(state)
    GetInputZoneHybridUnitaryAirConditioners(state, ErrorsFound)
    expect_eq(state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner.size(), 1)
    GetOARequirements(state)
    expect_false(ErrorsFound)
    var thisUnitary = state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[0]  # 1-based -> 0-based
    const DesignMinVR: Real64 = 1.622720855
    const Tra: Real64 = 22.93929413
    const Tosa: Real64 = 26.67733333
    const RHra: Real64 = 17.3042157
    const RHosa: Real64 = 13.1602401
    const Press: Real64 = 101325.0
    var Wra = PsyWFnTdbRhPb(state, Tra, RHra / 100, Press)
    var Wosa = PsyWFnTdbRhPb(state, Tosa, RHosa / 100, Press)
    var inletNode = state.dataLoopNodes.Node[thisUnitary.InletNode - 1]  # 1-based -> 0-based
    inletNode.Temp = Tra
    inletNode.HumRat = Wra
    inletNode.Press = Press
    inletNode.Enthalpy = Psychrometrics.PsyHFnTdbW(inletNode.Temp, inletNode.HumRat)
    var secondaryInletNode = state.dataLoopNodes.Node[thisUnitary.SecondaryInletNode - 1]
    secondaryInletNode.Temp = Tosa
    secondaryInletNode.HumRat = Wosa
    secondaryInletNode.Press = Press
    secondaryInletNode.Enthalpy = Psychrometrics.PsyHFnTdbW(secondaryInletNode.Temp, secondaryInletNode.HumRat)
    InitZoneHybridUnitaryAirConditioners(state, 1, 1)
    var RequestedHeating: Real64 = 0.0
    var RequestedCooling: Real64 = 0.0
    const Requested_Humidification: Real64 = 0.0
    const Requested_Dehumidification: Real64 = 0.0
    var modenumber: Int = 0
    RequestedHeating = -122396.255
    RequestedCooling = -58469.99445
    thisUnitary.Initialize(1)
    thisUnitary.InitializeModelParams()
    thisUnitary.doStep(state, RequestedCooling, RequestedHeating, Requested_Humidification, Requested_Dehumidification, DesignMinVR)
    var NormalizationDivisor: Real64 = 3.0176
    var ScaledMaxMsa = thisUnitary.ScaledSystemMaximumSupplyAirMassFlowRate
    var MinFlowFraction = DesignMinVR / ScaledMaxMsa
    modenumber = thisUnitary.PrimaryMode
    var Tsa = thisUnitary.OutletTemp
    var Msa = thisUnitary.OutletMassFlowRate
    var deliveredSC = thisUnitary.UnitSensibleCoolingRate
    var deliveredSH = thisUnitary.UnitSensibleHeatingRate
    var averageOSAF = thisUnitary.averageOSAF
    var Electricpower = thisUnitary.FinalElectricalPower
    expect_eq(modenumber, 3)
    expect_near(1.0, averageOSAF, 0.001)
    expect_gt(deliveredSC, 0)
    expect_near(0.0, deliveredSH, 0.001)
    expect_lt(Tsa, Tra)
    expect_gt(Msa, DesignMinVR)
    expect_gt(Electricpower, 10500 / NormalizationDivisor * MinFlowFraction)
    expect_lt(Electricpower, 12500 / NormalizationDivisor)
    thisUnitary.Initialize(1)
    thisUnitary.InitializeModelParams()
    thisUnitary.ScalingFactor = thisUnitary.ScalingFactor * 2
    thisUnitary.ScaledSystemMaximumSupplyAirMassFlowRate = thisUnitary.ScaledSystemMaximumSupplyAirMassFlowRate * 2
    thisUnitary.doStep(state, RequestedCooling, RequestedHeating, Requested_Humidification, Requested_Dehumidification, DesignMinVR)
    modenumber = thisUnitary.PrimaryMode
    Tsa = thisUnitary.OutletTemp
    Msa = thisUnitary.OutletMassFlowRate
    deliveredSC = thisUnitary.UnitSensibleCoolingRate
    deliveredSH = thisUnitary.UnitSensibleHeatingRate
    averageOSAF = thisUnitary.averageOSAF
    Electricpower = thisUnitary.FinalElectricalPower
    expect_eq(modenumber, 1)
    expect_near(1.0, averageOSAF, 0.001)
    expect_gt(deliveredSC, 0)
    expect_near(0.0, deliveredSH, 0.001)
    expect_lt(Tsa, Tra)
    expect_gt(Msa, DesignMinVR)
    expect_gt(Electricpower, 4000 / NormalizationDivisor * MinFlowFraction)
    expect_lt(Electricpower, 5000 / NormalizationDivisor)
    thisUnitary.Initialize(1)
    thisUnitary.InitializeModelParams()
    thisUnitary.ScalingFactor = thisUnitary.ScalingFactor / 2
    thisUnitary.ScaledSystemMaximumSupplyAirMassFlowRate = thisUnitary.ScaledSystemMaximumSupplyAirMassFlowRate / 2
    thisUnitary.SecInletTemp = 150
    thisUnitary.SecInletHumRat = 0
    thisUnitary.doStep(state, RequestedCooling, RequestedHeating, Requested_Humidification, Requested_Dehumidification, DesignMinVR)
    modenumber = thisUnitary.PrimaryMode
    Electricpower = thisUnitary.FinalElectricalPower
    expect_eq(modenumber, 0)
    expect_near(Electricpower, 244 / NormalizationDivisor, 1)
    RequestedHeating = -64358.68966
    RequestedCooling = -633.6613591
    thisUnitary.Initialize(1)
    thisUnitary.InitializeModelParams()
    thisUnitary.SecInletTemp = Tosa
    thisUnitary.SecInletHumRat = Wosa
    thisUnitary.doStep(state, RequestedCooling, RequestedHeating, Requested_Humidification, Requested_Dehumidification, DesignMinVR)
    modenumber = thisUnitary.PrimaryMode
    Tsa = thisUnitary.OutletTemp
    deliveredSC = thisUnitary.UnitSensibleCoolingRate
    deliveredSH = thisUnitary.UnitSensibleHeatingRate
    averageOSAF = thisUnitary.averageOSAF
    Electricpower = thisUnitary.FinalElectricalPower
    expect_eq(modenumber, 1)
    expect_near(1.0, averageOSAF, 0.001)
    expect_gt(deliveredSC, 0)
    expect_near(0.0, deliveredSH, 0.001)
    expect_lt(Tsa, Tra)
    expect_gt(Electricpower, 4000 / NormalizationDivisor * MinFlowFraction)
    expect_lt(Electricpower, 5000 / NormalizationDivisor)
    RequestedHeating = -55795.8058
    RequestedCooling = 8171.47128
    thisUnitary.Initialize(1)
    thisUnitary.InitializeModelParams()
    thisUnitary.SecInletTemp = Tosa
    thisUnitary.SecInletHumRat = Wosa
    thisUnitary.doStep(state, RequestedCooling, RequestedHeating, Requested_Humidification, Requested_Dehumidification, DesignMinVR)
    modenumber = thisUnitary.PrimaryMode
    Tsa = thisUnitary.OutletTemp
    Msa = thisUnitary.OutletMassFlowRate
    Electricpower = thisUnitary.FinalElectricalPower
    expect_eq(modenumber, 4)
    expect_near(Tsa, Tosa, 1.0)
    expect_near(Msa, DesignMinVR, 0.001)
    expect_gt(Electricpower, 4000 / NormalizationDivisor * MinFlowFraction)
    expect_lt(Electricpower, 5000 / NormalizationDivisor)
    thisUnitary.FanHeatGain = True
    thisUnitary.FanHeatGainLocation = "SUPPLYAIRSTREAM"
    thisUnitary.FanHeatInAirFrac = 1.0
    thisUnitary.Initialize(1)
    thisUnitary.InitializeModelParams()
    thisUnitary.SecInletTemp = Tosa
    thisUnitary.SecInletHumRat = Wosa
    thisUnitary.doStep(state, RequestedCooling, RequestedHeating, Requested_Humidification, Requested_Dehumidification, DesignMinVR)
    Tsa = thisUnitary.OutletTemp
    expect_near(Tsa, Tosa + 0.36, 0.1)
    thisUnitary.FanHeatGain = True
    thisUnitary.FanHeatGainLocation = "MIXEDAIRSTREAM"
    thisUnitary.FanHeatInAirFrac = 1.0
    thisUnitary.Initialize(1)
    thisUnitary.InitializeModelParams()
    thisUnitary.SecInletTemp = Tosa
    thisUnitary.SecInletHumRat = Wosa
    thisUnitary.doStep(state, RequestedCooling, RequestedHeating, Requested_Humidification, Requested_Dehumidification, DesignMinVR)
    Tsa = thisUnitary.OutletTemp
    expect_near(Tsa, Tosa + 0.36, 0.1)
    RequestedHeating = -122396.255
    RequestedCooling = -58469.99445
    thisUnitary.Initialize(1)
    thisUnitary.InitializeModelParams()
    thisUnitary.SecInletTemp = Tosa
    thisUnitary.SecInletHumRat = Wosa
    thisUnitary.availStatus = Avail.Status.ForceOff
    thisUnitary.doStep(state, RequestedCooling, RequestedHeating, Requested_Humidification, Requested_Dehumidification, DesignMinVR)
    modenumber = thisUnitary.PrimaryMode
    Msa = thisUnitary.OutletMassFlowRate
    deliveredSC = thisUnitary.UnitSensibleCoolingRate
    Electricpower = thisUnitary.FinalElectricalPower
    expect_eq(modenumber, 0)
    expect_eq(Msa, 0)
    expect_eq(deliveredSC, 0)
    expect_near(Electricpower, 244 / NormalizationDivisor, 1)
    state.dataGlobal.NumOfZones = 1
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand.allocate(state.dataGlobal.NumOfZones)
    state.dataZoneEnergyDemand.DeadBandOrSetback.allocate(state.dataGlobal.NumOfZones)
    DataZoneEquipment.GetZoneEquipmentData(state)
    state.dataZoneEquip.ZoneEquipInputsFilled = True
    state.dataHeatBal.ZnAirRpt.allocate(state.dataGlobal.NumOfZones)
    state.dataZoneTempPredictorCorrector.zoneHeatBalance.allocate(state.dataGlobal.NumOfZones)
    SystemReports.AllocateAndSetUpVentReports(state)
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].TotalOutputRequired = 58469.99445  # 1-based -> 0-based
    state.dataZoneEnergyDemand.DeadBandOrSetback[0] = False
    state.dataZoneEquip.ZoneEquipList[state.dataZoneEquip.ZoneEquipConfig[0].EquipListIndex - 1].EquipIndex[0] = 1  # multiple 1-based
    CreateEnergyReportStructure(state)
    SizingManager.GetOARequirements(state)
    using DataEnvironment:

    Sched.UpdateScheduleVals(state)
    expect_eq(state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner.size(), 1)
    GetOARequirements(state)
    RequestedHeating = -122396.255
    RequestedCooling = -58469.99445
    thisUnitary.Initialize(1)
    thisUnitary.InitializeModelParams()
    thisUnitary.InletTemp = Tra
    thisUnitary.SecInletTemp = Tosa
    thisUnitary.SecInletMassFlowRate = DesignMinVR
    thisUnitary.doStep(state, RequestedCooling, RequestedHeating, Requested_Humidification, Requested_Dehumidification, DesignMinVR)
    ReportZoneHybridUnitaryAirConditioners(state, 1)
    SystemReports.ReportVentilationLoads(state)
    var zone_oa_mass_flow = state.dataSysRpts.ZoneVentRepVars[0].OAMassFlow
    expect_eq(zone_oa_mass_flow, DesignMinVR)
    var NumFound: Int
    var TypeOfComp = "ZoneHVAC:HybridUnitaryHVAC"
    var NameOfComp = thisUnitary.Name
    var NumVariables = GetNumMeteredVariables(state, TypeOfComp, NameOfComp)
    var meteredVars = List[OutputProcessor.MeteredVar]()
    meteredVars.resize(NumVariables)
    NumFound = GetMeteredVariables(state, NameOfComp, meteredVars)
    var MaxFlow = thisUnitary.ScaledSystemMaximumSupplyAirVolumeFlowRate
    expect_eq(14, NumFound)
    # Note: meteredVars is 0-indexed, but in C++ it's 1-indexed, so subtract 1
    expect_eq(meteredVars[0].resource, Constant.eResource.EnergyTransfer)
    expect_eq(meteredVars[0].endUseCat, OutputProcessor.EndUseCat.CoolingCoils)
    expect_eq(meteredVars[0].group, OutputProcessor.Group.HVAC)
    expect_eq(meteredVars[1].resource, Constant.eResource.EnergyTransfer)
    expect_eq(meteredVars[1].endUseCat, OutputProcessor.EndUseCat.HeatingCoils)
    expect_eq(meteredVars[1].group, OutputProcessor.Group.HVAC)
    expect_eq(meteredVars[2].resource, Constant.eResource.Electricity)
    expect_eq(meteredVars[2].endUseCat, OutputProcessor.EndUseCat.Cooling)
    expect_eq(meteredVars[2].group, OutputProcessor.Group.HVAC)
    expect_eq(meteredVars[3].resource, Constant.eResource.Electricity)
    expect_eq(meteredVars[3].endUseCat, OutputProcessor.EndUseCat.Fans)
    expect_eq(meteredVars[3].group, OutputProcessor.Group.HVAC)
    expect_eq(meteredVars[4].resource, Constant.eResource.NaturalGas)
    expect_eq(meteredVars[4].endUseCat, OutputProcessor.EndUseCat.Cooling)
    expect_eq(meteredVars[4].group, OutputProcessor.Group.HVAC)
    expect_eq(meteredVars[5].resource, Constant.eResource.DistrictCooling)
    expect_eq(meteredVars[5].endUseCat, OutputProcessor.EndUseCat.Cooling)
    expect_eq(meteredVars[5].group, OutputProcessor.Group.HVAC)
    expect_eq(meteredVars[6].resource, Constant.eResource.Water)
    expect_eq(meteredVars[6].endUseCat, OutputProcessor.EndUseCat.Cooling)
    expect_eq(meteredVars[6].group, OutputProcessor.Group.HVAC)
    expect_eq("ZoneHVAC:HybridUnitaryHVAC", state.dataOutRptPredefined.CompSizeTableEntry[0].typeField)
    expect_eq("MUNTERSEPX5000", state.dataOutRptPredefined.CompSizeTableEntry[0].nameField)
    expect_eq("Scaled Maximum Supply Air Volume Flow Rate [m3/s]", state.dataOutRptPredefined.CompSizeTableEntry[0].description)
    expect_eq(MaxFlow, state.dataOutRptPredefined.CompSizeTableEntry[0].valField)

@test
def Test_UnitaryHybridAirConditioner_ValidateFieldsParsing():
    var fixture = EnergyPlusFixture()
    var state = fixture.state
    var idf_objects = delimited_string([
        "ZoneHVAC:HybridUnitaryHVAC,",
        "Hybrid Unit 1,          !- Name",
        "ALWAYS_ON,               !- Availability Schedule Name",
        ",                        !- Availability Manager List Name",
        ",                        !- Minimum Supply Air Temperature Schedule Name",
        ",                        !- Maximum Supply Air Temperature Schedule Name",
        ",                        !- Minimum Supply Air Humidity Ratio Schedule Name",
        ",                        !- Maximum Supply Air Humidity Ratio Schedule Name",
        "AUTOMATIC,               !- Method to Choose Controlled Inputs and Part Runtime Fraction",
        "Return Air Node 1 Name,  !- Return Air Node Name",
        "Outside Air Inlet 1 Node,  !- Outside Air Node Name",
        "Zone Inlet 1 Node,    !- Supply Air Node Name",
        "Relief 1 Node,        !- Relief Node Name",
        "2.51,                    !- System Maximum Supply AirFlow Rate {m3/s}",
        ",                        !- External Static Pressure at System Maximum Supply Air Flow Rate {Pa}",
        "Yes,                     !- Fan Heat Included in Lookup Tables",
        ",                        !- Fan Heat Gain Location",
        ",                        !- Fan Heat Gain In Airstream Fraction",
        "1,                       !- Scaling Factor",
        "10,                      !- Minimum Time Between Mode Change {minutes}",
        "Electricity,             !- First fuel type",
        "NaturalGas,              !- Second fuel type",
        "DistrictCooling,         !- Third fuel type",
        "Electricity Use,         !- Objective Function Minimizes",
        "SZ DSOA SPACE 1,         !- Design Specification Outdoor Air Object Name",
        "Mode0 Standby,           !- Mode0 Name",
        ",                        !- Mode0 Supply Air Temperature Lookup Table Name",
        ",                        !- Mode0 Supply Air Humidity Ratio Lookup Table Name",
        ",                        !- Mode0 System Electric Power Lookup Table Name",
        ",                        !- Mode0 Supply Fan Electric Power Lookup Table Name",
        ",                        !- Mode0 External Static Pressure Lookup Table Name",
        ",                        !- Mode0 System Second Fuel Consumption Lookup Table Name",
        ",                        !- Mode0 System Third Fuel Consumption Lookup Table Name",
        ",                        !- Mode0 System Water Use Lookup Table Name",
        "0,                       !- Mode0 Outside Air Fraction",
        "0,                       !- Mode0 Supply Air Mass Flow Rate Ratio",
        "Mode1_IEC,               !- Mode1 Name",
        ",                        !- Mode1 Supply Air Temperature Lookup Table Name",
        ",                        !- Mode1 Supply Air Humidity Ratio Lookup Table Name",
        ",                        !- Mode1 System Electric Power Lookup Table Name",
        ",                        !- Mode1 Supply Fan Electric Power Lookup Table Name",
        ",                        !- Mode1 External Static Pressure Lookup Table Name",
        ",                        !- Mode1 System Second Fuel Consumption Lookup Table Name",
        ",                        !- Mode1 System Third Fuel Consumption Lookup Table Name",
        ",                        !- Mode1 System Water Use Lookup Table Name",
        "-20,                     !- Mode1 Minimum Outside Air Temperature {C}",
        "100,                     !- Mode1 Maximum Outside Air Temperature {C}",
        "0,                       !- Mode1 Minimum Outside Air Humidity Ratio {kgWater/kgDryAir}",
        "0.03,                    !- Mode1 Maximum Outside Air Humidity Ratio {kgWater/kgDryAir}",
        "0,                       !- Mode1 Minimum Outside Air Relative Humidity {percent}",
        "100,                     !- Mode1 Maximum Outside Air Relative Humidity {percent}",
        "-20,                     !- Mode1 Minimum Return Air Temperature {C}",
        "100,                     !- Mode1 Maximum Return Air Temperature {C}",
        "0,                       !- Mode1 Minimum Return Air Humidity Ratio {kgWater/kgDryAir}",
        "0.03,                    !- Mode1 Maximum Return Air Humidity Ratio {kgWater/kgDryAir}",
        "0,                       !- Mode1 Minimum Return Air Relative Humidity {percent}",
        "100,                     !- Mode1 Maximum Return Air Relative Humidity {percent}",
        "1,                       !- Mode1 Minimum Outside Air Fraction",
        "1,                       !- Mode1 Maximum Outside Air Fraction",
        "0.715,                   !- Mode1 Minimum Supply Air Mass Flow Rate Ratio",
        "0.964;                   !- Mode1 Maximum Supply Air Mass Flow Rate Ratio",
        "ZoneHVAC:HybridUnitaryHVAC,",
        "Hybrid Unit 2,          !- Name",
        "ALWAYS_ON,               !- Availability Schedule Name",
        ",                        !- Availability Manager List Name",
        ",                        !- Minimum Supply Air Temperature Schedule Name",
        ",                        !- Maximum Supply Air Temperature Schedule Name",
        ",                        !- Minimum Supply Air Humidity Ratio Schedule Name",
        ",                        !- Maximum Supply Air Humidity Ratio Schedule Name",
        "AUTOMATIC,               !- Method to Choose Controlled Inputs and Part Runtime Fraction",
        "Return Air Node 2 Name,  !- Return Air Node Name",
        "Outside Air Inlet 2 Node,  !- Outside Air Node Name",
        "Zone Inlet 2 Node,    !- Supply Air Node Name",
        "Relief 2 Node,        !- Relief Node Name",
        "2.51,                    !- System Maximum Supply AirFlow Rate {m3/s}",
        ",                        !- External Static Pressure at System Maximum Supply Air Flow Rate {Pa}",
        "Yes,                     !- Fan Heat Included in Lookup Tables",
        ",                        !- Fan Heat Gain Location",
        ",                        !- Fan Heat Gain In Airstream Fraction",
        "1,                       !- Scaling Factor",
        "10,                      !- Minimum Time Between Mode Change {minutes}",
        "Electricity,             !- First fuel type",
        "NaturalGas,              !- Second fuel type",
        "DistrictCooling,         !- Third fuel type",
        "Water Use,               !- Objective Function Minimizes",
        "SZ DSOA SPACE 2,         !- Design Specification Outdoor Air Object Name",
        "Mode0 Standby,           !- Mode0 Name",
        ",                        !- Mode0 Supply Air Temperature Lookup Table Name",
        ",                        !- Mode0 Supply Air Humidity Ratio Lookup Table Name",
        ",                        !- Mode0 System Electric Power Lookup Table Name",
        ",                        !- Mode0 Supply Fan Electric Power Lookup Table Name",
        ",                        !- Mode0 External Static Pressure Lookup Table Name",
        ",                        !- Mode0 System Second Fuel Consumption Lookup Table Name",
        ",                        !- Mode0 System Third Fuel Consumption Lookup Table Name",
        ",                        !- Mode0 System Water Use Lookup Table Name",
        "0,                       !- Mode0 Outside Air Fraction",
        "0,                       !- Mode0 Supply Air Mass Flow Rate Ratio",
        "Mode1_IEC,               !- Mode1 Name",
        ",                        !- Mode1 Supply Air Temperature Lookup Table Name",
        ",                        !- Mode1 Supply Air Humidity Ratio Lookup Table Name",
        ",                        !- Mode1 System Electric Power Lookup Table Name",
        ",                        !- Mode1 Supply Fan Electric Power Lookup Table Name",
        ",                        !- Mode1 External Static Pressure Lookup Table Name",
        ",                        !- Mode1 System Second Fuel Consumption Lookup Table Name",
        ",                        !- Mode1 System Third Fuel Consumption Lookup Table Name",
        ",                        !- Mode1 System Water Use Lookup Table Name",
        ",                        !- Mode1 Minimum Outside Air Temperature {C}",
        ",                        !- Mode1 Maximum Outside Air Temperature {C}",
        "0,                       !- Mode1 Minimum Outside Air Humidity Ratio {kgWater/kgDryAir}",
        "0.03,                    !- Mode1 Maximum Outside Air Humidity Ratio {kgWater/kgDryAir}",
        "0,                       !- Mode1 Minimum Outside Air Relative Humidity {percent}",
        "100,                     !- Mode1 Maximum Outside Air Relative Humidity {percent}",
        ",                        !- Mode1 Minimum Return Air Temperature {C}",
        ",                        !- Mode1 Maximum Return Air Temperature {C}",
        "0,                       !- Mode1 Minimum Return Air Humidity Ratio {kgWater/kgDryAir}",
        "0.03,                    !- Mode1 Maximum Return Air Humidity Ratio {kgWater/kgDryAir}",
        "0,                       !- Mode1 Minimum Return Air Relative Humidity {percent}",
        "100,                     !- Mode1 Maximum Return Air Relative Humidity {percent}",
        "1,                       !- Mode1 Minimum Outside Air Fraction",
        "1,                       !- Mode1 Maximum Outside Air Fraction",
        "0.715,                   !- Mode1 Minimum Supply Air Mass Flow Rate Ratio",
        "0.964;                   !- Mode1 Maximum Supply Air Mass Flow Rate Ratio"
    ])
    assert_true(fixture.process_idf(idf_objects))
    var ErrorsFound: Bool = False
    GetInputZoneHybridUnitaryAirConditioners(state, ErrorsFound)
    var expectedOperatingModesSize: UInt = 2
    var hybridUnit1 = state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[0]  # 1-based -> 0-based
    var hybridUnit2 = state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[1]
    expect_eq(hybridUnit1.OperatingModes.size(), expectedOperatingModesSize)
    expect_eq(hybridUnit2.OperatingModes.size(), expectedOperatingModesSize)
    expect_eq(hybridUnit1.Name, "HYBRID UNIT 1")
    expect_eq(hybridUnit2.Name, "HYBRID UNIT 2")
    expect_eq(hybridUnit1.ObjectiveFunction, HybridEvapCoolingModel.ObjectiveFunctionType.ElectricityUse)
    expect_eq(hybridUnit2.ObjectiveFunction, HybridEvapCoolingModel.ObjectiveFunctionType.WaterUse)
    var mode1 = hybridUnit1.OperatingModes[0]  # index 0 for first mode (Mode0)
    expect_eq(mode1.Minimum_Outdoor_Air_Temperature_Blank, False)
    expect_eq(mode1.Minimum_Outdoor_Air_Temperature, -20)
    expect_eq(mode1.Maximum_Outdoor_Air_Temperature_Blank, False)
    expect_eq(mode1.Maximum_Outdoor_Air_Temperature, 100)
    expect_eq(mode1.Minimum_Return_Air_Temperature_Blank, False)
    expect_eq(mode1.Minimum_Return_Air_Temperature, -20)
    expect_eq(mode1.Maximum_Return_Air_Temperature_Blank, False)
    expect_eq(mode1.Maximum_Return_Air_Temperature, 100)
    expect_eq(mode1.MeetsConstraints(120, 0.01, 30, 120, 0.01, 30), False)
    expect_eq(mode1.MeetsConstraints(20, 0.01, 30, 20, 0.01, 30), True)
    mode1 = hybridUnit2.OperatingModes[0]  # index 0 for first mode
    expect_eq(mode1.Minimum_Outdoor_Air_Temperature_Blank, True)
    expect_eq(mode1.Minimum_Outdoor_Air_Temperature, 0)
    expect_eq(mode1.Maximum_Outdoor_Air_Temperature_Blank, True)
    expect_eq(mode1.Maximum_Outdoor_Air_Temperature, 0)
    expect_eq(mode1.Minimum_Return_Air_Temperature_Blank, True)
    expect_eq(mode1.Minimum_Return_Air_Temperature, 0)
    expect_eq(mode1.Maximum_Return_Air_Temperature_Blank, True)
    expect_eq(mode1.Maximum_Return_Air_Temperature, 0)
    expect_eq(mode1.MeetsConstraints(120, 0.01, 30, 120, 0.01, 30), True)
    expect_eq(mode1.MeetsConstraints(20, 0.01, 30, 20, 0.01, 30), True)

@test
def Test_UnitaryHybridAirConditioner_ValidateMinimumIdfInput():
    var fixture = EnergyPlusFixture()
    var state = fixture.state
    var idf_objects = delimited_string([
        "ZoneHVAC:HybridUnitaryHVAC,",
        "MUNTERSEPX5000,          !- Name",
        "ALWAYS_ON,               !- Availability Schedule Name",
        ",                        !- Availability Manager List Name",
        ",                        !- Minimum Supply Air Temperature Schedule Name",
        ",                        !- Maximum Supply Air Temperature Schedule Name",
        ",                        !- Minimum Supply Air Humidity Ratio Schedule Name",
        ",                        !- Maximum Supply Air Humidity Ratio Schedule Name",
        "AUTOMATIC,               !- Method to Choose Controlled Inputs and Part Runtime Fraction",
        "Main Return Air Node Name,  !- Return Air Node Name",
        "Outside Air Inlet Node,  !- Outside Air Node Name",
        "Main Zone Inlet Node,    !- Supply Air Node Name",
        "Main Relief Node,        !- Relief Node Name",
        "2.51,                    !- System Maximum Supply AirFlow Rate {m3/s}",
        ",                        !- External Static Pressure at System Maximum Supply Air Flow Rate {Pa}",
        "Yes,                     !- Fan Heat Included in Lookup Tables",
        ",                        !- Fan Heat Gain Location",
        ",                        !- Fan Heat Gain In Airstream Fraction",
        "1,                       !- Scaling Factor",
        "10,                      !- Minimum Time Between Mode Change {minutes}",
        "Electricity,             !- First fuel type",
        "NaturalGas,              !- Second fuel type",
        "DistrictCooling,         !- Third fuel type",
        ",                        !- Objective Function Minimizes",
        "SZ DSOA SPACE2-1,        !- Design Specification Outdoor Air Object Name",
        "Mode0 Standby;           !- Mode0 Name"
    ])
    assert_true(fixture.process_idf(idf_objects))
    var ErrorsFound: Bool = False
    GetInputZoneHybridUnitaryAirConditioners(state, ErrorsFound)
    var thisUnitary = state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[0]  # 1-based -> 0-based
    var inletNode = state.dataLoopNodes.Node[thisUnitary.InletNode - 1]  # 1-based -> 0-based
    inletNode.Temp = 17.57
    inletNode.HumRat = 0.007
    inletNode.Press = 101325.0
    inletNode.Enthalpy = Psychrometrics.PsyHFnTdbW(inletNode.Temp, inletNode.HumRat)
    inletNode.MassFlowRate = 0.25
    var secondaryInletNode = state.dataLoopNodes.Node[thisUnitary.SecondaryInletNode - 1]
    secondaryInletNode.Temp = 17.57
    secondaryInletNode.HumRat = 0.007
    secondaryInletNode.Press = 101325.0
    secondaryInletNode.Enthalpy = Psychrometrics.PsyHFnTdbW(secondaryInletNode.Temp, secondaryInletNode.HumRat)
    secondaryInletNode.MassFlowRate = 0.25
    InitZoneHybridUnitaryAirConditioners(state, 1, 1)
    thisUnitary.Initialize(1)
    thisUnitary.InitializeModelParams()
    var expectedOperatingModesSize: UInt = 1
    expect_eq(thisUnitary.OperatingModes.size(), expectedOperatingModesSize)

@test
def Test_UnitaryHybridAirConditioner_CalculateCurveVal():
    var fixture = EnergyPlusFixture()
    var state = fixture.state
    var idf_objects = delimited_string([
        "ZoneHVAC:HybridUnitaryHVAC,",
        "MUNTERSEPX5000,          !- Name",
        "ALWAYS_ON,               !- Availability Schedule Name",
        ",                        !- Availability Manager List Name",
        ",                        !- Minimum Supply Air Temperature Schedule Name",
        ",                        !- Maximum Supply Air Temperature Schedule Name",
        ",                        !- Minimum Supply Air Humidity Ratio Schedule Name",
        ",                        !- Maximum Supply Air Humidity Ratio Schedule Name",
        "AUTOMATIC,               !- Method to Choose Controlled Inputs and Part Runtime Fraction",
        "Main Return Air Node Name,  !- Return Air Node Name",
        "Outside Air Inlet Node,  !- Outside Air Node Name",
        "Main Zone Inlet Node,    !- Supply Air Node Name",
        "Main Relief Node,        !- Relief Node Name",
        "2.51,                    !- System Maximum Supply AirFlow Rate {m3/s}",
        ",                        !- External Static Pressure at System Maximum Supply Air Flow Rate {Pa}",
        "Yes,                     !- Fan Heat Included in Lookup Tables",
        ",                        !- Fan Heat Gain Location",
        ",                        !- Fan Heat Gain In Airstream Fraction",
        "2.0,                     !- Scaling Factor",
        "10,                      !- Minimum Time Between Mode Change {minutes}",
        "Electricity,             !- First fuel type",
        "NaturalGas,              !- Second fuel type",
        "DistrictCooling,         !- Third fuel type",
        ",                        !- Objective Function Minimizes",
        "SZ DSOA SPACE2-1,        !- Design Specification Outdoor Air Object Name",
        "Mode0 Standby,           !- Mode0 Name",
        "Mode0_Tsa_lookup,        !- Mode0 Supply Air Temperature Lookup Table Name",
        "Mode0_Wsa_lookup,        !- Mode0 Supply Air Humidity Ratio Lookup Table Name",
        "Mode0_Power_lookup,      !- Mode0 System Electric Power Lookup Table Name",
        "Mode0_FanPower_lookup,   !- Mode0 Supply Fan Electric Power Lookup Table Name",
        ",                        !- Mode0 External Static Pressure Lookup Table Name",
        ",                        !- Mode0 System Second Fuel Consumption Lookup Table Name",
        ",                        !- Mode0 System Third Fuel Consumption Lookup Table Name",
        ",                        !- Mode0 System Water Use Lookup Table Name",
        "0,                       !- Mode0 Outside Air Fraction",
        "0;                       !- Mode0 Supply Air Mass Flow Rate Ratio",
        "Table:IndependentVariableList,",
        "Mode0_IndependentVariableList,  !- Name",
        "Mode0_Toa,                      !- Independent Variable 1 Name",
        "Mode0_Woa,                      !- Independent Variable 2 Name",
        "Mode0_Tra,                      !- Extended Field",
        "Mode0_Wra,                      !- Extended Field",
        "Mode0_Ma,                       !- Extended Field",
        "Mode0_OAF;                      !- Extended Field",
        "Table:IndependentVariable,",
        "Mode0_Toa,               !- Name",
        "Linear,                  !- Interpolation Method",
        "Constant,                !- Extrapolation Method",
        "-20,                     !- Minimum Value",
        "100,                     !- Maximum Value",
        ",                        !- Normalization Reference Value",
        "Dimensionless,           !- Unit Type",
        ",                        !- External File Name",
        ",                        !- External File Column Number",
        ",                        !- External File Starting Row Number",
        "10.0;                    !- Value 1",
        "Table:IndependentVariable,",
        "Mode0_Woa,               !- Name",
        "Linear,                  !- Interpolation Method",
        "Constant,                !- Extrapolation Method",
        "0,                       !- Minimum Value",
        "0.03,                    !- Maximum Value",
        ",                        !- Normalization Reference Value",
        "Dimensionless,           !- Unit Type",
        ",                        !- External File Name",
        ",                        !- External File Column Number",
        ",                        !- External File Starting Row Number",
        "0.005;                   !- Value 1",
        "Table:IndependentVariable,",
        "Mode0_Tra,               !- Name",
        "Linear,                  !- Interpolation Method",
        "Constant,                !- Extrapolation Method",
        "-20,                     !- Minimum Value",
        "100,                     !- Maximum Value",
        ",                        !- Normalization Reference Value",
        "Dimensionless,           !- Unit Type",
        ",                        !- External File Name",
        ",                        !- External File Column Number",
        ",                        !- External File Starting Row Number",
        "20.0;                    !- Value 1",
        "Table:IndependentVariable,",
        "Mode0_Wra,               !- Name",
        "Linear,                  !- Interpolation Method",
        "Constant,                !- Extrapolation Method",
        "0,                       !- Minimum Value",
        "0.03,                    !- Maximum Value",
        ",                        !- Normalization Reference Value",
        "Dimensionless,           !- Unit Type",
        ",                        !- External File Name",
        ",                        !- External File Column Number",
        ",                        !- External File Starting Row Number",
        "0.01;                    !- Value 1",
        "Table:IndependentVariable,",
        "Mode0_Ma,                !- Name",
        "Linear,                  !- Interpolation Method",
        "Constant,                !- Extrapolation Method",
        "0,                       !- Minimum Value",
        "1,                       !- Maximum Value",
        ",                        !- Normalization Reference Value",
        "Dimensionless,           !- Unit Type",
        ",                        !- External File Name",
        ",                        !- External File Column Number",
        ",                        !- External File Starting Row Number",
        "0.5;                     !- Value 1",
        "Table:IndependentVariable,",
        "Mode0_OAF,               !- Name",
        "Linear,                  !- Interpolation Method",
        "Constant,                !- Extrapolation Method",
        "0,                       !- Minimum Value",
        "1,                       !- Maximum Value",
        ",                        !- Normalization Reference Value",
        "Dimensionless,           !- Unit Type",
        ",                        !- External File Name",
        ",                        !- External File Column Number",
        ",                        !- External File Starting Row Number",
        "1;                       !- Value 1",
        "Table:Lookup,",
        "Mode0_Tsa_lookup,        !- Name",
        "Mode0_IndependentVariableList,  !- Independent Variable List Name",
        "DivisorOnly,             !- Normalization Method",
        ",                        !- Normalization Divisor",
        "-9999,                   !- Minimum Output",
        "9999,                    !- Maximum Output",
        "Dimensionless,           !- Output Unit Type",
        ",                        !- External File Name",
        ",                        !- External File Column Number",
        ",                        !- External File Starting Row Number",
        "5.0;                     !- Output Value 1",
        "Table:Lookup,",
        "Mode0_Wsa_lookup,        !- Name",
        "Mode0_IndependentVariableList,  !- Independent Variable List Name",
        "DivisorOnly,             !- Normalization Method",
        "3.0,                     !- Normalization Divisor",
        "-9999,                   !- Minimum Output",
        "9999,                    !- Maximum Output",
        "Dimensionless,           !- Output Unit Type",
        ",                        !- External File Name",
        ",                        !- External File Column Number",
        ",                        !- External File Starting Row Number",
        "0.005;                     !- Output Value 1",
        "Table:Lookup,",
        "Mode0_Power_lookup,      !- Name",
        "Mode0_IndependentVariableList,  !- Independent Variable List Name",
        "DivisorOnly,             !- Normalization Method",
        "3.0176,                  !- Normalization Divisor",
        "-9999,                   !- Minimum Output",
        "9999,                    !- Maximum Output",
        "Dimensionless,           !- Output Unit Type",
        ",                        !- External File Name",
        ",                        !- External File Column Number",
        ",                        !- External File Starting Row Number",
        "1000.0;                  !- Output Value 1",
        "Table:Lookup,",
        "Mode0_FanPower_lookup,   !- Name",
        "Mode0_IndependentVariableList,  !- Independent Variable List Name",
        "DivisorOnly,             !- Normalization Method",
        "3.0176,                  !- Normalization Divisor",
        "-9999,                   !- Minimum Output",
        "9999,                    !- Maximum Output",
        "Dimensionless,           !- Output Unit Type",
        ",                        !- External File Name",
        ",                        !- External File Column Number",
        ",                        !- External File Starting Row Number",
        "3.25;                    !- Output Value 1"
    ])
    assert_true(fixture.process_idf(idf_objects))
    state.init_state(state)
    expect_eq(4, state.dataCurveManager.curves.size())
    var ErrorsFound: Bool = False
    GetInputZoneHybridUnitaryAirConditioners(state, ErrorsFound)
    GetOARequirements(state)
    expect_false(ErrorsFound)
    var thisUnitary = state.dataHybridUnitaryAC.ZoneHybridUnitaryAirConditioner[0]  # 1-based -> 0-based
    const Toa: Real64 = 10.0
    const Woa: Real64 = 0.005
    const Tra: Real64 = 20.0
    const Wra: Real64 = 0.01
    const Press: Real64 = 101325.0
    var inletNode = state.dataLoopNodes.Node[thisUnitary.InletNode - 1]
    inletNode.Temp = Tra
    inletNode.HumRat = Wra
    inletNode.Press = Press
    inletNode.Enthalpy = Psychrometrics.PsyHFnTdbW(inletNode.Temp, inletNode.HumRat)
    var secondaryInletNode = state.dataLoopNodes.Node[thisUnitary.SecondaryInletNode - 1]
    secondaryInletNode.Temp = Toa
    secondaryInletNode.HumRat = Woa
    secondaryInletNode.Press = Press
    secondaryInletNode.Enthalpy = Psychrometrics.PsyHFnTdbW(secondaryInletNode.Temp, secondaryInletNode.HumRat)
    InitZoneHybridUnitaryAirConditioners(state, 1, 1)
    thisUnitary.Initialize(1)
    thisUnitary.InitializeModelParams()
    const Msa: Real64 = 0.5
    const OSAF: Real64 = 1.0
    const ExpectedTsa: Real64 = 5.0
    const ExpectedWsa: Real64 = 0.005 / 3.0
    const ExpectedPowerOutput: Real64 = 1000.0 * 2.0 / 3.0176
    const ExpectedFanPowerOutput: Real64 = 3.25 * 2.0 / 3.0176
    const ExpectedResults: StaticArray[Real64, 4] = [ExpectedTsa, ExpectedWsa, ExpectedPowerOutput, ExpectedFanPowerOutput]
    var mode0 = thisUnitary.OperatingModes[0]  # index 0
    for i in range(4):
        var testCurveVal = mode0.CalculateCurveVal(state, Toa, Woa, Tra, Wra, Msa, OSAF, i)
        expect_eq(testCurveVal, ExpectedResults[i])

@test
def Test_UnitaryHybridAirConditioner_ModelOperatingSettings_SolutionSpaceSearching():
    var fixture = EnergyPlusFixture()
    var state = fixture.state
    var idf_objects = delimited_string([
        "ZoneHVAC:HybridUnitaryHVAC,",
        "MUNTERSEPX5000,          !- Name",
        "ALWAYS_ON,               !- Availability Schedule Name",
        ",                        !- Availability Manager List Name",
        ",                        !- Minimum Supply Air Temperature Schedule Name",
        ",                        !- Maximum Supply Air Temperature Schedule Name",
        ",                        !- Minimum Supply Air Humidity Ratio Schedule Name",
        "1.0,                     !- Maximum Supply Air Humidity Ratio Schedule Name",
        "AUTOMATIC,               !- Method to Choose Controlled Inputs and Part Runtime Fraction",
        "Main Return Air Node Name,  !- Return Air Node Name",
        "Outside Air Inlet Node,  !- Outside Air Node Name",
        "Main Zone Inlet Node,    !- Supply Air Node Name",
        "Main Relief Node,        !- Relief Node Name",
        "2.51,                    !- System Maximum Supply AirFlow Rate {m3/s}",
        ",                        !- External Static Pressure at System Maximum Supply Air Flow Rate {Pa}",
        "Yes,                     !- Fan Heat Included in Lookup Tables",
        ",                        !- Fan Heat Gain Location",
        ",                        !- Fan Heat Gain In Airstream Fraction",
        "2.0,                     !- Scaling Factor",
        "10,                      !- Minimum Time Between Mode Change {minutes}",
        "Electricity,             !- First fuel type",
        "NaturalGas,              !- Second fuel type",
        "DistrictCooling,         !- Third fuel type",
        ",                        !- Objective Function Minimizes",
        "SZ DSOA SPACE2-1,        !- Design Specification Outdoor Air Object Name",
        "Mode0 Standby,           !- Mode0 Name",
        "Mode0_Tsa_lookup,        !- Mode0 Supply Air Temperature Lookup Table Name",
        "Mode0_Wsa_lookup,        !- Mode0 Supply Air Humidity Ratio Lookup Table Name",
        "Mode0_Power_lookup,      !- Mode0 System Electric Power Lookup Table Name",
        "Mode0_FanPower_lookup,   !- Mode0 Supply Fan Electric Power Lookup Table Name",
        ",                        !- Mode0 External Static Pressure Lookup Table Name",
        ",                        !- Mode0 System Second Fuel Consumption Lookup Table Name",
        ",                        !- Mode0 System Third Fuel Consumption Lookup Table Name",
        ",                        !- Mode0 System Water Use Lookup Table Name",
        "0,                       !- Mode0 Outside Air Fraction",
        "0,                       !- Mode0 Supply Air Mass Flow Rate Ratio",
        "Mode1_IEC,               !- Mode1 Name",
        "Mode1_Tsa_lookup,        !- Mode1 Supply Air Temperature Lookup Table Name",
        "Mode1_Wsa_lookup,        !- Mode1 Supply Air Humidity Ratio Lookup Table Name",
        "Mode1_Power_lookup,      !- Mode1 System Electric Power Lookup Table Name",
        "Mode1_FanPower_lookup,   !- Mode1 Supply Fan Electric Power Lookup Table Name",
        ",                        !- Mode1 External Static Pressure Lookup Table Name",
        ",                        !- Mode1 System Second Fuel Consumption Lookup Table Name",
        ",                        !- Mode1 System Third Fuel Consumption Lookup Table Name",
        ",                        !- Mode1 System Water Use Lookup Table Name",
        "-20,                     !- Mode1 Minimum Outside Air Temperature {C}",
        "100,                     !- Mode1 Maximum Outside Air Temperature {C}",
        "0,                       !- Mode1 Minimum Outside Air Humidity Ratio {kgWater/kgDryAir}",
        "0.03,                    !- Mode1 Maximum Outside Air Humidity Ratio {kgWater/kgDryAir}",
        "0,                       !- Mode1 Minimum Outside Air Relative Humidity {percent}",
        "100,                     !- Mode1 Maximum Outside Air Relative Humidity {percent}",
        "-20,                     !- Mode1 Minimum Return Air Temperature {C}",
        "100,                     !- Mode1 Maximum Return Air Temperature {C}",
        "0,                       !- Mode1 Minimum Return Air Humidity Ratio {kgWater/kgDryAir}",
        "0.03,                    !- Mode1 Maximum Return Air Humidity Ratio {kgWater/kgDryAir}",
        "0,                       !- Mode1 Minimum Return Air Relative Humidity {percent}",
        "100,                     !- Mode1 Maximum Return Air Relative Humidity {percent}",
        "0,                       !- Mode1 Minimum Outside Air Fraction",
        "1,                       !- Mode1 Maximum Outside Air Fraction",
        "0.715,                   !- Mode1 Minimum Supply Air Mass Flow Rate Ratio",
        "0.964;                   !- Mode1 Maximum Supply Air Mass Flow Rate Ratio",
        "Schedule:Compact,",
        "ALWAYS_ON,               !- Name",
        "On/Off,                  !- Schedule Type Limits Name",
        "Through: 12/31,          !- Field 1",
        "For: AllDays,            !- Field 2",
        "Until: 24:00,1;          !- Field 3",
        "Table:IndependentVariableList,",
        "Mode0_IndependentVariableList,  !- Name",
        "Mode0_Toa,                      !- Independent Variable 1 Name",
        "Mode0_Woa,                      !- Independent Variable 2 Name",
        "Mode0_Tra,                      !- Extended Field",
        "Mode0_Wra,                      !- Extended Field",
        "Mode0_Ma,                       !- Extended Field",
        "Mode0_OAF;                      !- Extended Field",
        "Table:IndependentVariable,",
        "Mode0_Toa,               !- Name",
        "Linear,                  !- Interpolation Method",
        "Constant,                !- Extrapolation Method",
        "-20,                     !- Minimum Value",
        "100,                     !- Maximum Value",
        ",                        !- Normalization Reference Value",
        "Dimensionless,           !- Unit Type",
        ",                        !- External File Name",
        ",                        !- External File Column Number",
        ",                        !- External File Starting Row Number",
        "10.0;                    !- Value 1",
        "Table:IndependentVariable,",
        "Mode0_Woa,               !- Name",
        "Linear,                  !- Interpolation Method",
        "Constant,                !- Extrapolation Method",
        "0,                       !- Minimum Value",
        "0.03,                    !- Maximum Value",
        ",                        !- Normalization Reference Value",
        "Dimensionless,           !- Unit Type",
        ",                        !- External File Name",
        ",                        !- External File Column Number",
        ",                        !- External File Starting Row Number",
        "0.005;                   !- Value 1",
        "Table:IndependentVariable,",
        "Mode0_Tra,               !- Name",
        "Linear,                  !- Interpolation Method",
        "Constant,                !- Extrapolation Method",
        "-20,                     !- Minimum Value",
        "100,                     !- Maximum Value",
        ",                        !- Normalization Reference Value",
        "Dimensionless,           !- Unit Type",
        ",                        !- External File Name",
        ",                        !- External File Column Number",
        ",                        !- External File Starting Row Number",
        "20.0;                    !- Value 1",
        "Table:IndependentVariable,",
        "Mode0_Wra,               !- Name",
        "Linear,                  !- Interpolation Method",
        "Constant,                !- Extrapolation Method",
        "0,                       !- Minimum Value",
        "0.03,                    !- Maximum Value",
        ",                        !- Normalization Reference Value",
        "Dimensionless,           !- Unit Type",
        ",                        !- External File Name",
        ",                        !- External File Column Number",
        ",                        !- External File Starting Row Number",
        "0.01;                    !- Value 1",
        "Table:IndependentVariable,",
        "Mode0_Ma,                !- Name",
        "Linear,                  !- Interpolation Method",
        "Constant,                !- Extrapolation Method",
        "0,                       !- Minimum Value",
        "1,                       !- Maximum Value",
        ",                        !- Normalization Reference Value",
        "Dimensionless,           !- Unit Type",
        ",                        !- External File Name",
        ",                        !- External File Column Number",
        ",                        !- External File Starting Row Number",
        "0.5;                     !- Value 1",
        "Table:IndependentVariable,",
        "Mode0_OAF,               !- Name",
        "Linear,                  !- Interpolation Method",
        "Constant,                !- Extrapolation Method",
        "0,                       !- Minimum Value",
        "1,                       !- Maximum Value",
        ",                        !- Normalization Reference Value",
        "Dimensionless,           !- Unit Type",
        ",                        !- External File Name",
        ",                        !- External File Column Number",
        ",                        !- External File Starting Row Number",
        "1;                       !- Value 1",
        "Table:Lookup,",
        "Mode0_Tsa_lookup,        !- Name",
        "Mode0_IndependentVariableList,  !- Independent Variable List Name",
        "DivisorOnly,             !- Normalization Method",
        ",                        !- Normalization Divisor",
        "-9999,                   !- Minimum Output",
        "9999,                    !- Maximum Output",
        "Dimensionless,           !- Output Unit Type",
        ",                        !- External File Name",
        ",                        !- External File Column Number",
        ",                        !- External File Starting Row Number",
        "5.0;                     !- Output Value 1",
        "Table:Lookup,",
        "Mode0_Wsa_lookup,        !- Name",
        "Mode0_IndependentVariableList,  !- Independent Variable List Name",
        "DivisorOnly,             !- Normalization Method",
        "3.0,                     !- Normalization Divisor",
        "-9999,                   !- Minimum Output",
        "9999,                    !- Maximum Output",
        "Dimensionless,           !- Output Unit Type",
        ",                        !- External File Name",
        ",                        !- External File Column Number",
        ",                        !- External File Starting Row Number",
        "0.005;                     !- Output Value 1",
        "Table:Lookup,",
        "Mode0_Power_lookup,      !- Name",
        "Mode0_IndependentVariableList,  !- Independent Variable List Name",
        "DivisorOnly,             !- Normalization Method",
        "3.0176,                  !- Normalization Divisor",
        "-9999,                   !- Minimum Output",
        "9999,                    !- Maximum Output",
        "Dimensionless,           !- Output Unit Type",
        ",                        !- External File Name",
        ",                        !- External File Column Number",
        ",                        !- External File Starting Row Number",
        "1000.0;                  !- Output Value 1",
        "Table:Lookup,",
        "Mode0_FanPower_lookup,   !- Name",
        "Mode0_IndependentVariableList,  !- Independent Variable List Name",
        "DivisorOnly,             !- Normalization Method",
        "3.0176,                  !- Normalization Divisor",
        "-9999,                   !- Minimum Output",
        "9999,                    !- Maximum Output",
        "Dimensionless,           !- Output Unit Type",
        ",                        !- External File Name",
        ",                        !- External File Column Number",
        ",                        !- External File Starting Row Number",
        "3.25;                    !- Output Value 1",
        "Table:IndependentVariableList,",
        "Mode1_IndependentVariableList,  !- Name",
        "Mode1_Toa,                      !- Independent Variable 1 Name",
        "Mode1_Woa,                      !- Independent Variable 2 Name",
        "Mode1_Tra,                      !- Extended Field",
        "Mode1_Wra,                      !- Extended Field",
        "Mode1_Ma,                       !- Extended Field",
        "Mode1_OAF;                      !- Extended Field",
        "Table:IndependentVariable,",
        "Mode1_Toa,               !- Name",
        "Linear,                  !- Interpolation Method",
        "Constant,                !- Extrapolation Method",
        "-20,                     !- Minimum Value",
        "100,                     !- Maximum Value",
        ",                        !- Normal