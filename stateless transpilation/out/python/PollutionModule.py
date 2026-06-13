# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData (from EnergyPlus.Data.EnergyPlusData)
# - Constant.eResource, Constant.Units, Constant.eFuel, Constant.eFuelNames, Constant.eFuelNamesUC (from EnergyPlus.DataGlobalConstants)
# - Sched.Schedule, Sched.GetSchedule, Sched.ShowSevereBadMin (from EnergyPlus.ScheduleManager)
# - OutputProcessor.ReportFreq, OutputProcessor.EndUseCat, OutputProcessor.TimeStepType, OutputProcessor.StoreType, OutputProcessor.Group
# - OutputProcessor.GetMeterIndex, OutputProcessor.GetInstantMeterValue, OutputProcessor.ReportingThisVariable, OutputProcessor.SetupOutputVariable (from EnergyPlus.OutputProcessor)
# - InputProcessor.getNumObjectsFound, InputProcessor.getObjectItem (from EnergyPlus.InputProcessing.InputProcessor)
# - Util.makeUPPER, format, ShowSevereError, ShowWarningError, ShowContinueError, ShowFatalError, ShowSevereInvalidKey, ShowSevereItemNotFound, ErrorObjectHeader (from EnergyPlus.UtilityRoutines)

from enum import IntEnum
from dataclasses import dataclass, field
from typing import Optional, List, Protocol, Any, Tuple
import math

class Pollutant(IntEnum):
    INVALID = -1
    CO2 = 0
    CO = 1
    CH4 = 2
    NOx = 3
    N2O = 4
    SO2 = 5
    PM = 6
    PM10 = 7
    PM2_5 = 8
    NH3 = 9
    NMVOC = 10
    Hg = 11
    Pb = 12
    Water = 13
    NuclearHigh = 14
    NuclearLow = 15
    Num = 16

class PollFuel(IntEnum):
    INVALID = -1
    Electricity = 0
    NaturalGas = 1
    FuelOil1 = 2
    FuelOil2 = 3
    Coal = 4
    Gasoline = 5
    Propane = 6
    Diesel = 7
    OtherFuel1 = 8
    OtherFuel2 = 9
    Num = 10

class PollFuelComponent(IntEnum):
    INVALID = -1
    Electricity = 0
    NaturalGas = 1
    FuelOil1 = 2
    FuelOil2 = 3
    Coal = 4
    Gasoline = 5
    Propane = 6
    Diesel = 7
    OtherFuel1 = 8
    OtherFuel2 = 9
    ElectricitySurplusSold = 10
    ElectricityPurchased = 11
    Num = 12

class PollFacilityMeter(IntEnum):
    INVALID = -1
    Electricity = 0
    NaturalGas = 1
    FuelOil1 = 2
    FuelOil2 = 3
    Coal = 4
    Gasoline = 5
    Propane = 6
    Diesel = 7
    OtherFuel1 = 8
    OtherFuel2 = 9
    ElectricitySurplusSold = 10
    ElectricityPurchased = 11
    ElectricityProduced = 12
    Steam = 13
    HeatPurchased = 14
    CoolPurchased = 15
    Num = 16

pollNames = [
    "CO2",
    "CO",
    "CH4",
    "NOx",
    "N2O",
    "SO2",
    "PM",
    "PM10",
    "PM2.5",
    "NH3",
    "NMVOC",
    "Hg",
    "Pb",
    "WaterEnvironmentalFactors",
    "Nuclear High",
    "Nuclear Low"
]

poll2outVarStrs = [
    "CO2 Emissions Mass",
    "CO Emissions Mass",
    "CH4 Emissions Mass",
    "NOx Emissions Mass",
    "N2O Emissions Mass",
    "SO2 Emissions Mass",
    "PM Emissions Mass",
    "PM10 Emissions Mass",
    "PM2.5 Emissions Mass",
    "NH3 Emissions Mass",
    "NMVOC Emissions Mass",
    "Hg Emissions Mass",
    "Pb Emissions Mass",
    "Water Consumption Volume",
    "Nuclear High Level Waste Mass",
    "Nuclear Low Level Waste Volume"
]

pollFuelFactors = [
    3.167,
    1.084,
    1.05,
    1.05,
    1.05,
    1.05,
    1.05,
    1.05,
    1.0,
    1.0
]

pollFuelNamesUC = [
    None,
    None,
    None,
    None,
    None,
    None,
    None,
    None,
    None,
    None
]

pollFuelComp2pollFuel = [
    PollFuel.Electricity,
    PollFuel.NaturalGas,
    PollFuel.FuelOil1,
    PollFuel.FuelOil2,
    PollFuel.Coal,
    PollFuel.Gasoline,
    PollFuel.Propane,
    PollFuel.Diesel,
    PollFuel.OtherFuel1,
    PollFuel.OtherFuel2,
    PollFuel.Electricity,
    PollFuel.Electricity
]

pollFuel2pollFuelComponent = [
    PollFuelComponent.Electricity,
    PollFuelComponent.NaturalGas,
    PollFuelComponent.FuelOil1,
    PollFuelComponent.FuelOil2,
    PollFuelComponent.Coal,
    PollFuelComponent.Gasoline,
    PollFuelComponent.Propane,
    PollFuelComponent.Diesel,
    PollFuelComponent.OtherFuel1,
    PollFuelComponent.OtherFuel2
]

pollFacilityMeterNames = [
    "Electricity:Facility",
    "NaturalGas:Facility",
    "FuelOilNo1:Facility",
    "FuelOilNo2:Facility",
    "Coal:Facility",
    "Gasoline:Facility",
    "Propane:Facility",
    "Diesel:Facility",
    "OtherFuel1:Facility",
    "OtherFuel2:Facility",
    "ElectricitySurplusSold:Facility",
    "ElectricityPurchased:Facility",
    "ElectricityProduced:Facility",
    "DistrictHeatingSteam:Facility",
    "DistrictHeatingWater:Facility",
    "DistrictCooling:Facility"
]

@dataclass
class ComponentProps:
    sourceVal: float = 0.0
    pollutantVals: List[float] = field(default_factory=lambda: [0.0] * 16)

@dataclass
class CoefficientProps:
    used: bool = False
    sourceCoeff: float = 0.0
    pollutantCoeffs: List[float] = field(default_factory=lambda: [0.0] * 16)
    sourceSched: Optional[Any] = None
    pollutantScheds: List[Optional[Any]] = field(default_factory=lambda: [None] * 16)

@dataclass
class BaseGlobalStruct:
    pass

@dataclass
class PollutionData(BaseGlobalStruct):
    PollutionReportSetup: bool = False
    GetInputFlagPollution: bool = True
    NumEnvImpactFactors: int = 0
    NumFuelFactors: int = 0
    pollComps: List[ComponentProps] = field(default_factory=lambda: [ComponentProps() for _ in range(12)])
    facilityMeterNums: List[int] = field(default_factory=lambda: [-1] * 16)
    facilityMeterVals: List[float] = field(default_factory=lambda: [0.0] * 16)
    facilityMeterFuelComponentVals: List[float] = field(default_factory=lambda: [0.0] * 12)
    pollutantVals: List[float] = field(default_factory=lambda: [0.0] * 16)
    pollFuelFactorList: List[PollFuel] = field(default_factory=list)
    TotCarbonEquivFromN2O: float = 0.0
    TotCarbonEquivFromCH4: float = 0.0
    TotCarbonEquivFromCO2: float = 0.0
    pollCoeffs: List[CoefficientProps] = field(default_factory=lambda: [CoefficientProps() for _ in range(10)])
    CarbonEquivN2O: float = 0.0
    CarbonEquivCH4: float = 0.0
    CarbonEquivCO2: float = 0.0
    PurchHeatEffic: float = 0.0
    PurchCoolCOP: float = 0.0
    SteamConvEffic: float = 0.0

    def init_constant_state(self, state: EnergyPlusData) -> None:
        pass

    def init_state(self, state: EnergyPlusData) -> None:
        pass

    def clear_state(self) -> None:
        self.PollutionReportSetup = False
        self.GetInputFlagPollution = True
        self.NumEnvImpactFactors = 0
        self.NumFuelFactors = 0
        self.pollFuelFactorList.clear()

class EnergyPlusData(Protocol):
    dataPollution: PollutionData
    dataIPShortCut: Any
    dataInputProcessing: Any
    dataHVACGlobals: Any

def CalculatePollution(state: EnergyPlusData) -> None:
    if not state.dataPollution.PollutionReportSetup:
        return
    ReadEnergyMeters(state)
    CalcPollution(state)

def SetupPollutionCalculations(state: EnergyPlusData) -> None:
    cCurrentModuleObject = "Output:EnvironmentalImpactFactors"
    num_polute_rpt = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, cCurrentModuleObject)
    state.dataPollution.PollutionReportSetup = True

    for loop in range(1, num_polute_rpt + 1):
        state.dataInputProcessing.inputProcessor.getObjectItem(
            state,
            cCurrentModuleObject,
            loop,
            state.dataIPShortCut.cAlphaArgs,
            state.dataIPShortCut.NumAlphas,
            state.dataIPShortCut.rNumericArgs,
            state.dataIPShortCut.NumNums,
            state.dataIPShortCut.IOStat,
            state.dataIPShortCut.lNumericFieldBlanks,
            state.dataIPShortCut.lAlphaFieldBlanks,
            state.dataIPShortCut.cAlphaFieldNames,
            state.dataIPShortCut.cNumericFieldNames
        )

        freq = getattr(state.dataOutputProcessor, 'ReportFreq').Simulation

        if not state.dataIPShortCut.lAlphaFieldBlanks[0]:
            freq = getEnumValue(getattr(state.dataOutputProcessor, 'reportFreqNamesUC'),
                               state.dataIPShortCut.cAlphaArgs[0].upper())
            if freq == getattr(state.dataOutputProcessor, 'ReportFreq').Invalid:
                ShowSevereError(state, f"Invalid reporting frequency {state.dataIPShortCut.cAlphaArgs[0]}")
                continue

        InitPollutionMeterReporting(state, freq)

def GetPollutionFactorInput(state: EnergyPlusData) -> None:
    routine_name = "GetPollutionFactorInput"
    ip = state.dataInputProcessing.inputProcessor
    ipsc = state.dataIPShortCut
    pm = state.dataPollution

    if not pm.GetInputFlagPollution:
        return
    pm.GetInputFlagPollution = False

    ipsc.cCurrentModuleObject = "EnvironmentalImpactFactors"
    pm.NumEnvImpactFactors = ip.getNumObjectsFound(state, ipsc.cCurrentModuleObject)

    if pm.NumEnvImpactFactors > 0:
        ip.getObjectItem(
            state,
            ipsc.cCurrentModuleObject,
            1,
            ipsc.cAlphaArgs,
            ipsc.NumAlphas,
            ipsc.rNumericArgs,
            ipsc.NumNums,
            ipsc.IOStat,
            ipsc.lNumericFieldBlanks,
            ipsc.lAlphaFieldBlanks,
            ipsc.cAlphaFieldNames,
            ipsc.cNumericFieldNames
        )
    elif pm.PollutionReportSetup:
        ShowWarningError(state, f"{ipsc.cCurrentModuleObject}: not entered.  Values will be defaulted.")

    pm.PurchHeatEffic = 0.3
    pm.PurchCoolCOP = 3.0
    pm.SteamConvEffic = 0.25
    pm.CarbonEquivN2O = 0.0
    pm.CarbonEquivCH4 = 0.0
    pm.CarbonEquivCO2 = 0.0

    if pm.NumEnvImpactFactors > 0:
        if ipsc.rNumericArgs[0] > 0.0:
            pm.PurchHeatEffic = ipsc.rNumericArgs[0]
        if ipsc.rNumericArgs[1] > 0.0:
            pm.PurchCoolCOP = ipsc.rNumericArgs[1]
        if ipsc.rNumericArgs[2] > 0.0:
            pm.SteamConvEffic = ipsc.rNumericArgs[2]
        pm.CarbonEquivN2O = ipsc.rNumericArgs[3]
        pm.CarbonEquivCH4 = ipsc.rNumericArgs[4]
        pm.CarbonEquivCO2 = ipsc.rNumericArgs[5]

    ipsc.cCurrentModuleObject = "FuelFactors"
    pm.NumFuelFactors = ip.getNumObjectsFound(state, ipsc.cCurrentModuleObject)

    errors_found = False

    for loop in range(1, pm.NumFuelFactors + 1):
        ip.getObjectItem(
            state,
            ipsc.cCurrentModuleObject,
            loop,
            ipsc.cAlphaArgs,
            ipsc.NumAlphas,
            ipsc.rNumericArgs,
            ipsc.NumNums,
            ipsc.IOStat,
            ipsc.lNumericFieldBlanks,
            ipsc.lAlphaFieldBlanks,
            ipsc.cAlphaFieldNames,
            ipsc.cNumericFieldNames
        )

        eoh = ErrorObjectHeader(routine_name, ipsc.cCurrentModuleObject, ipsc.cAlphaArgs[0])

        poll_fuel = getEnumValue(pollFuelNamesUC, ipsc.cAlphaArgs[0].upper())
        if poll_fuel == PollFuel.INVALID:
            ShowSevereInvalidKey(state, eoh, ipsc.cAlphaFieldNames[0], ipsc.cAlphaArgs[0])
            errors_found = True
            continue

        pm.pollFuelFactorList.append(poll_fuel)

        poll_coeff = pm.pollCoeffs[int(poll_fuel)]
        fuel = pollFuel2fuel[int(poll_fuel)]

        if poll_coeff.used:
            ShowWarningError(state, f"{ipsc.cCurrentModuleObject}: {Constant.eFuelNames[int(fuel)]} already entered. Previous entry will be used.")
            continue

        poll_coeff.used = True
        poll_coeff.sourceCoeff = ipsc.rNumericArgs[0]

        if not ipsc.lAlphaFieldBlanks[1]:
            poll_coeff.sourceSched = Sched.GetSchedule(state, ipsc.cAlphaArgs[1])
            if poll_coeff.sourceSched is None:
                ShowSevereItemNotFound(state, eoh, ipsc.cAlphaFieldNames[1], ipsc.cAlphaArgs[1])
                errors_found = True
            elif not poll_coeff.sourceSched.checkMinVal(state, Clusive.In, 0.0):
                Sched.ShowSevereBadMin(state, eoh, ipsc.cAlphaFieldNames[1], ipsc.cAlphaArgs[1], Clusive.In, 0.0)
                errors_found = True

        for i_pollutant in range(int(Pollutant.Num)):
            poll_coeff.pollutantCoeffs[i_pollutant] = ipsc.rNumericArgs[i_pollutant + 1]
            if not ipsc.lAlphaFieldBlanks[i_pollutant + 2]:
                poll_coeff.pollutantScheds[i_pollutant] = Sched.GetSchedule(state, ipsc.cAlphaArgs[i_pollutant + 2])
                if poll_coeff.pollutantScheds[i_pollutant] is None:
                    ShowSevereItemNotFound(state, eoh, ipsc.cAlphaFieldNames[i_pollutant + 2], ipsc.cAlphaArgs[i_pollutant + 2])
                    errors_found = True
                elif not poll_coeff.pollutantScheds[i_pollutant].checkMinVal(state, Clusive.In, 0.0):
                    Sched.ShowSevereBadMin(state, eoh, ipsc.cAlphaFieldNames[i_pollutant + 2], ipsc.cAlphaArgs[i_pollutant + 2], Clusive.In, 0.0)
                    errors_found = True

    if pm.PollutionReportSetup:
        if (not pm.pollCoeffs[int(PollFuel.Electricity)].used and
            (pm.facilityMeterNums[int(PollFacilityMeter.Electricity)] > 0 or
             pm.facilityMeterNums[int(PollFacilityMeter.ElectricityProduced)] > 0 or
             pm.facilityMeterNums[int(PollFacilityMeter.CoolPurchased)] > 0)):
            ShowSevereError(state, f"{ipsc.cCurrentModuleObject} Not Found or Fuel not specified For Pollution Calculation for ELECTRICITY")
            errors_found = True

        if (not pm.pollCoeffs[int(PollFuel.NaturalGas)].used and
            (pm.facilityMeterNums[int(PollFacilityMeter.NaturalGas)] > 0 or
             pm.facilityMeterNums[int(PollFacilityMeter.HeatPurchased)] > 0 or
             pm.facilityMeterNums[int(PollFacilityMeter.Steam)] > 0)):
            ShowSevereError(state, f"{ipsc.cCurrentModuleObject} Not Found or Fuel not specified For Pollution Calculation for NATURAL GAS")
            errors_found = True

        if (not pm.pollCoeffs[int(PollFuel.FuelOil2)].used and
            pm.facilityMeterNums[int(PollFacilityMeter.FuelOil2)] > 0):
            ShowSevereError(state, f"{ipsc.cCurrentModuleObject} Not Found or Fuel not specified For Pollution Calculation for FUEL OIL #2")
            errors_found = True

        if (not pm.pollCoeffs[int(PollFuel.FuelOil1)].used and
            pm.facilityMeterNums[int(PollFacilityMeter.FuelOil1)] > 0):
            ShowSevereError(state, f"{ipsc.cCurrentModuleObject} Not Found or Fuel not specified For Pollution Calculation for FUEL OIL #1")
            errors_found = True

        if (not pm.pollCoeffs[int(PollFuel.Coal)].used and
            pm.facilityMeterNums[int(PollFacilityMeter.Coal)] > 0):
            ShowSevereError(state, f"{ipsc.cCurrentModuleObject} Not Found or Fuel not specified For Pollution Calculation for COAL")
            errors_found = True

        if (not pm.pollCoeffs[int(PollFuel.Gasoline)].used and
            pm.facilityMeterNums[int(PollFacilityMeter.Gasoline)] > 0):
            ShowSevereError(state, f"{ipsc.cCurrentModuleObject} Not Found or Fuel not specified For Pollution Calculation for GASOLINE")
            errors_found = True

        if (not pm.pollCoeffs[int(PollFuel.Propane)].used and
            pm.facilityMeterNums[int(PollFacilityMeter.Propane)] > 0):
            ShowSevereError(state, f"{ipsc.cCurrentModuleObject} Not Found or Fuel not specified For Pollution Calculation for PROPANE")
            errors_found = True

        if (not pm.pollCoeffs[int(PollFuel.Diesel)].used and
            pm.facilityMeterNums[int(PollFacilityMeter.Diesel)] > 0):
            ShowSevereError(state, f"{ipsc.cCurrentModuleObject} Not Found or Fuel not specified For Pollution Calculation for DIESEL")
            errors_found = True

        if (not pm.pollCoeffs[int(PollFuel.OtherFuel1)].used and
            pm.facilityMeterNums[int(PollFacilityMeter.OtherFuel1)] > 0):
            ShowSevereError(state, f"{ipsc.cCurrentModuleObject} Not Found or Fuel not specified For Pollution Calculation for OTHERFUEL1")
            errors_found = True

        if (not pm.pollCoeffs[int(PollFuel.OtherFuel2)].used and
            pm.facilityMeterNums[int(PollFacilityMeter.OtherFuel2)] > 0):
            ShowSevereError(state, f"{ipsc.cCurrentModuleObject} Not Found or Fuel not specified For Pollution Calculation for OTHERFUEL2")
            errors_found = True

    if errors_found:
        ShowFatalError(state, "Errors found in getting Pollution Calculation Reporting Input")

def SetupPollutionMeterReporting(state: EnergyPlusData) -> None:
    pm = state.dataPollution

    if pm.GetInputFlagPollution:
        GetPollutionFactorInput(state)
        pm.GetInputFlagPollution = False

    for poll_fuel in pm.pollFuelFactorList:
        if not pm.pollCoeffs[int(poll_fuel)].used:
            continue

        poll_comp = pm.pollComps[int(pollFuel2pollFuelComponent[int(poll_fuel)])]
        fuel = pollFuel2fuel[int(poll_fuel)]

        fuel2sovEndUseCat = [
            OutputProcessor.EndUseCat.ElectricityEmissions,
            OutputProcessor.EndUseCat.NaturalGasEmissions,
            OutputProcessor.EndUseCat.GasolineEmissions,
            OutputProcessor.EndUseCat.DieselEmissions,
            OutputProcessor.EndUseCat.CoalEmissions,
            OutputProcessor.EndUseCat.PropaneEmissions,
            OutputProcessor.EndUseCat.FuelOilNo1Emissions,
            OutputProcessor.EndUseCat.FuelOilNo2Emissions,
            OutputProcessor.EndUseCat.OtherFuel1Emissions,
            OutputProcessor.EndUseCat.OtherFuel2Emissions,
            OutputProcessor.EndUseCat.Invalid,
            OutputProcessor.EndUseCat.Invalid,
            OutputProcessor.EndUseCat.Invalid,
            OutputProcessor.EndUseCat.Invalid,
            OutputProcessor.EndUseCat.Invalid
        ]

        SetupOutputVariable(
            state,
            f"Environmental Impact {Constant.eFuelNames[int(fuel)]} Source Energy",
            Constant.Units.J,
            poll_comp.sourceVal,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Sum,
            "Site",
            Constant.eResource.Source,
            OutputProcessor.Group.Invalid,
            fuel2sovEndUseCat[int(fuel)]
        )

        for i_pollutant in range(int(Pollutant.Num)):
            SetupOutputVariable(
                state,
                f"Environmental Impact {Constant.eFuelNames[int(fuel)]} {poll2outVarStrs[i_pollutant]}",
                pollUnits[i_pollutant],
                poll_comp.pollutantVals[i_pollutant],
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Sum,
                "Site",
                poll2Resource[i_pollutant],
                OutputProcessor.Group.Invalid,
                fuel2sovEndUseCat[int(fuel)]
            )

        if fuel == Constant.eFuel.Electricity:
            SetupOutputVariable(
                state,
                "Environmental Impact Purchased Electricity Source Energy",
                Constant.Units.J,
                pm.pollComps[int(PollFuelComponent.ElectricityPurchased)].sourceVal,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Sum,
                "Site",
                Constant.eResource.Source,
                OutputProcessor.Group.Invalid,
                OutputProcessor.EndUseCat.PurchasedElectricityEmissions
            )
            SetupOutputVariable(
                state,
                "Environmental Impact Surplus Sold Electricity Source",
                Constant.Units.J,
                pm.pollComps[int(PollFuelComponent.ElectricitySurplusSold)].sourceVal,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Sum,
                "Site",
                Constant.eResource.Source,
                OutputProcessor.Group.Invalid,
                OutputProcessor.EndUseCat.SoldElectricityEmissions
            )

    SetupOutputVariable(
        state,
        "Environmental Impact Total N2O Emissions Carbon Equivalent Mass",
        Constant.Units.kg,
        pm.TotCarbonEquivFromN2O,
        OutputProcessor.TimeStepType.System,
        OutputProcessor.StoreType.Sum,
        "Site",
        Constant.eResource.CarbonEquivalent,
        OutputProcessor.Group.Invalid,
        OutputProcessor.EndUseCat.CarbonEquivalentEmissions
    )
    SetupOutputVariable(
        state,
        "Environmental Impact Total CH4 Emissions Carbon Equivalent Mass",
        Constant.Units.kg,
        pm.TotCarbonEquivFromCH4,
        OutputProcessor.TimeStepType.System,
        OutputProcessor.StoreType.Sum,
        "Site",
        Constant.eResource.CarbonEquivalent,
        OutputProcessor.Group.Invalid,
        OutputProcessor.EndUseCat.CarbonEquivalentEmissions
    )
    SetupOutputVariable(
        state,
        "Environmental Impact Total CO2 Emissions Carbon Equivalent Mass",
        Constant.Units.kg,
        pm.TotCarbonEquivFromCO2,
        OutputProcessor.TimeStepType.System,
        OutputProcessor.StoreType.Sum,
        "Site",
        Constant.eResource.CarbonEquivalent,
        OutputProcessor.Group.Invalid,
        OutputProcessor.EndUseCat.CarbonEquivalentEmissions
    )

    for i_meter in range(int(PollFacilityMeter.Num)):
        pm.facilityMeterNums[i_meter] = GetMeterIndex(state, pollFacilityMeterNames[i_meter].upper())

def CheckPollutionMeterReporting(state: EnergyPlusData) -> None:
    pm = state.dataPollution

    if pm.NumFuelFactors == 0 or pm.NumEnvImpactFactors == 0:
        if (ReportingThisVariable(state, "Environmental Impact Total N2O Emissions Carbon Equivalent Mass") or
            ReportingThisVariable(state, "Environmental Impact Total CH4 Emissions Carbon Equivalent Mass") or
            ReportingThisVariable(state, "Environmental Impact Total CO2 Emissions Carbon Equivalent Mass") or
            ReportingThisVariable(state, "Carbon Equivalent:Facility") or
            ReportingThisVariable(state, "CarbonEquivalentEmissions:Carbon Equivalent")):
            ShowWarningError(state, "GetPollutionFactorInput: Requested reporting for Carbon Equivalent Pollution, but insufficient information is entered.")
            ShowContinueError(state, "Both \"FuelFactors\" and \"EnvironmentalImpactFactors\" must be entered or the displayed carbon pollution will all be zero.")

def CalcPollution(state: EnergyPlusData) -> None:
    pm = state.dataPollution

    for i_poll in range(int(Pollutant.Num)):
        pm.pollutantVals[i_poll] = 0.0

        for i_poll_fuel in range(int(PollFuel.Num)):
            poll_coeff = pm.pollCoeffs[i_poll_fuel]
            poll_fuel_comp = pollFuel2pollFuelComponent[i_poll_fuel]
            poll_comp = pm.pollComps[int(poll_fuel_comp)]

            if poll_coeff.used:
                poll_comp.pollutantVals[i_poll] = 0.0
                pollutant_val = poll_coeff.pollutantCoeffs[i_poll]

                if i_poll != int(Pollutant.Water) and i_poll != int(Pollutant.NuclearLow):
                    pollutant_val *= 0.001

                if poll_coeff.pollutantScheds[i_poll] is not None:
                    pollutant_val *= poll_coeff.pollutantScheds[i_poll].getCurrentVal()

                poll_comp.pollutantVals[i_poll] = pm.facilityMeterFuelComponentVals[int(poll_fuel_comp)] * 1.0e-6 * pollutant_val

            pm.pollutantVals[i_poll] += poll_comp.pollutantVals[i_poll]

    pm.TotCarbonEquivFromN2O = pm.pollutantVals[int(Pollutant.N2O)] * pm.CarbonEquivN2O
    pm.TotCarbonEquivFromCH4 = pm.pollutantVals[int(Pollutant.CH4)] * pm.CarbonEquivCH4
    pm.TotCarbonEquivFromCO2 = pm.pollutantVals[int(Pollutant.CO2)] * pm.CarbonEquivCO2

    poll_coeff_elec = pm.pollCoeffs[int(PollFuel.Electricity)]
    poll_comp_elec = pm.pollComps[int(PollFuelComponent.Electricity)]
    poll_comp_elec_purchased = pm.pollComps[int(PollFuelComponent.ElectricityPurchased)]
    poll_comp_elec_surplus_sold = pm.pollComps[int(PollFuelComponent.ElectricitySurplusSold)]

    poll_comp_elec.sourceVal = pm.facilityMeterFuelComponentVals[int(PollFuelComponent.Electricity)] * poll_coeff_elec.sourceCoeff
    poll_comp_elec_purchased.sourceVal = pm.facilityMeterFuelComponentVals[int(PollFuelComponent.ElectricityPurchased)] * poll_coeff_elec.sourceCoeff
    poll_comp_elec_surplus_sold.sourceVal = pm.facilityMeterFuelComponentVals[int(PollFuelComponent.ElectricitySurplusSold)] * poll_coeff_elec.sourceCoeff

    if poll_coeff_elec.sourceSched is not None:
        poll_coeff_elec_sched_val = poll_coeff_elec.sourceSched.getCurrentVal()
        poll_comp_elec.sourceVal *= poll_coeff_elec_sched_val
        poll_comp_elec_purchased.sourceVal *= poll_coeff_elec_sched_val
        poll_comp_elec_surplus_sold.sourceVal *= poll_coeff_elec_sched_val

    poll_coeff_gas = pm.pollCoeffs[int(PollFuel.NaturalGas)]
    poll_comp_gas = pm.pollComps[int(PollFuelComponent.NaturalGas)]
    poll_comp_gas.sourceVal = pm.facilityMeterVals[int(PollFacilityMeter.NaturalGas)] * poll_coeff_gas.sourceCoeff
    if poll_coeff_gas.sourceSched is not None:
        poll_comp_gas.sourceVal *= poll_coeff_gas.sourceSched.getCurrentVal()

    for poll_fuel in [PollFuel.FuelOil1, PollFuel.FuelOil2, PollFuel.Diesel, PollFuel.Gasoline,
                      PollFuel.Propane, PollFuel.Coal, PollFuel.OtherFuel1, PollFuel.OtherFuel2]:
        poll_coeff = pm.pollCoeffs[int(poll_fuel)]
        poll_fuel_component = pollFuel2pollFuelComponent[int(poll_fuel)]
        poll_comp = pm.pollComps[int(poll_fuel_component)]

        poll_comp.sourceVal = pm.facilityMeterFuelComponentVals[int(poll_fuel_component)] * poll_coeff.sourceCoeff
        if poll_coeff.sourceSched is not None:
            poll_comp.sourceVal *= poll_coeff.sourceSched.getCurrentVal()

def ReadEnergyMeters(state: EnergyPlusData) -> None:
    frac_time_step_zone = state.dataHVACGlobals.FracTimeStepZone
    pm = state.dataPollution

    for i_meter in range(int(PollFacilityMeter.Num)):
        pm.facilityMeterVals[i_meter] = (
            GetInstantMeterValue(state, pm.facilityMeterNums[i_meter], OutputProcessor.TimeStepType.Zone) * frac_time_step_zone +
            GetInstantMeterValue(state, pm.facilityMeterNums[i_meter], OutputProcessor.TimeStepType.System)
        )

    pm.facilityMeterFuelComponentVals[int(PollFuelComponent.Electricity)] = (
        pm.facilityMeterVals[int(PollFacilityMeter.Electricity)] -
        pm.facilityMeterVals[int(PollFacilityMeter.ElectricityProduced)] +
        pm.facilityMeterVals[int(PollFacilityMeter.CoolPurchased)] / pm.PurchCoolCOP
    )

    if pm.facilityMeterFuelComponentVals[int(PollFuelComponent.Electricity)] < 0.0:
        pm.facilityMeterFuelComponentVals[int(PollFuelComponent.Electricity)] = 0.0

    pm.facilityMeterFuelComponentVals[int(PollFuelComponent.NaturalGas)] = (
        pm.facilityMeterVals[int(PollFacilityMeter.NaturalGas)] +
        pm.facilityMeterVals[int(PollFacilityMeter.HeatPurchased)] / pm.PurchHeatEffic +
        pm.facilityMeterVals[int(PollFacilityMeter.Steam)] / pm.SteamConvEffic
    )

    pm.facilityMeterFuelComponentVals[int(PollFuelComponent.FuelOil1)] = pm.facilityMeterVals[int(PollFacilityMeter.FuelOil1)]
    pm.facilityMeterFuelComponentVals[int(PollFuelComponent.FuelOil2)] = pm.facilityMeterVals[int(PollFacilityMeter.FuelOil2)]
    pm.facilityMeterFuelComponentVals[int(PollFuelComponent.Gasoline)] = pm.facilityMeterVals[int(PollFacilityMeter.Gasoline)]
    pm.facilityMeterFuelComponentVals[int(PollFuelComponent.Propane)] = pm.facilityMeterVals[int(PollFacilityMeter.Propane)]
    pm.facilityMeterFuelComponentVals[int(PollFuelComponent.Coal)] = pm.facilityMeterVals[int(PollFacilityMeter.Coal)]
    pm.facilityMeterFuelComponentVals[int(PollFuelComponent.Diesel)] = pm.facilityMeterVals[int(PollFacilityMeter.Diesel)]
    pm.facilityMeterFuelComponentVals[int(PollFuelComponent.OtherFuel1)] = pm.facilityMeterVals[int(PollFacilityMeter.OtherFuel1)]
    pm.facilityMeterFuelComponentVals[int(PollFuelComponent.OtherFuel2)] = pm.facilityMeterVals[int(PollFacilityMeter.OtherFuel2)]
    pm.facilityMeterFuelComponentVals[int(PollFuelComponent.ElectricityPurchased)] = pm.facilityMeterVals[int(PollFacilityMeter.ElectricityPurchased)]
    pm.facilityMeterFuelComponentVals[int(PollFuelComponent.ElectricitySurplusSold)] = pm.facilityMeterVals[int(PollFacilityMeter.ElectricitySurplusSold)]

def GetFuelFactorInfo(
    state: EnergyPlusData,
    fuel: Any,
    fuelFactorUsed: list,
    fuelSourceFactor: list,
    fuelFactorScheduleUsed: list,
    ffSched: list
) -> None:
    pm = state.dataPollution

    if pm.GetInputFlagPollution:
        GetPollutionFactorInput(state)
        pm.GetInputFlagPollution = False

    fuelFactorUsed[0] = False
    fuelSourceFactor[0] = 0.0
    fuelFactorScheduleUsed[0] = False
    ffSched[0] = None

    poll_fuel = fuel2pollFuel[int(fuel)]
    poll_coeff = pm.pollCoeffs[int(poll_fuel)]

    if poll_coeff.used:
        fuelFactorUsed[0] = True
        fuelSourceFactor[0] = poll_coeff.sourceCoeff
        if poll_coeff.sourceSched is None:
            fuelFactorScheduleUsed[0] = False
        else:
            fuelFactorScheduleUsed[0] = True
            ffSched[0] = poll_coeff.sourceSched
    else:
        fuelSourceFactor[0] = pollFuelFactors[int(poll_fuel)]

    if fuel == Constant.eFuel.DistrictHeatingWater:
        fuelSourceFactor[0] /= pm.PurchHeatEffic
    elif fuel == Constant.eFuel.DistrictCooling:
        fuelSourceFactor[0] /= pm.PurchCoolCOP
    elif fuel == Constant.eFuel.DistrictHeatingSteam:
        fuelSourceFactor[0] = 0.3 / pm.SteamConvEffic

def GetEnvironmentalImpactFactorInfo(
    state: EnergyPlusData,
    efficiencyDistrictHeatingWater: list,
    efficiencyDistrictCooling: list,
    sourceFactorDistrictHeatingSteam: list
) -> None:
    pm = state.dataPollution

    if pm.GetInputFlagPollution:
        GetPollutionFactorInput(state)
        pm.GetInputFlagPollution = False

    if pm.NumEnvImpactFactors > 0:
        efficiencyDistrictHeatingWater[0] = pm.PurchHeatEffic
        sourceFactorDistrictHeatingSteam[0] = pm.SteamConvEffic
        efficiencyDistrictCooling[0] = pm.PurchCoolCOP

def InitPollutionMeterReporting(state: EnergyPlusData, freq: Any) -> None:
    pass

def getEnumValue(names_list: list, name: str) -> int:
    try:
        return names_list.index(name)
    except ValueError:
        return -1

def GetMeterIndex(state: EnergyPlusData, meter_name: str) -> int:
    pass

def GetInstantMeterValue(state: EnergyPlusData, meter_index: int, time_step_type: Any) -> float:
    pass

def SetupOutputVariable(state: EnergyPlusData, *args, **kwargs) -> None:
    pass

def ReportingThisVariable(state: EnergyPlusData, var_name: str) -> bool:
    pass

def ShowSevereError(state: EnergyPlusData, msg: str) -> None:
    pass

def ShowWarningError(state: EnergyPlusData, msg: str) -> None:
    pass

def ShowContinueError(state: EnergyPlusData, msg: str) -> None:
    pass

def ShowFatalError(state: EnergyPlusData, msg: str) -> None:
    pass

def ShowSevereInvalidKey(state: EnergyPlusData, eoh: Any, field_name: str, key: str) -> None:
    pass

def ShowSevereItemNotFound(state: EnergyPlusData, eoh: Any, field_name: str, item: str) -> None:
    pass

class ErrorObjectHeader:
    def __init__(self, routine_name: str, obj_type: str, obj_name: str):
        self.routine_name = routine_name
        self.obj_type = obj_type
        self.obj_name = obj_name

class Clusive:
    In = 0
    Out = 1

class Constant:
    class eResource:
        pass
    class Units:
        kg = 0
        J = 1
        L = 2
        m3 = 3
    class eFuel:
        pass
    eFuelNames = []
    eFuelNamesUC = []

class Sched:
    class Schedule:
        pass
    @staticmethod
    def GetSchedule(state: EnergyPlusData, name: str) -> Any:
        return None
    @staticmethod
    def ShowSevereBadMin(state: EnergyPlusData, eoh: Any, field_name: str, item: str, clusive: int, min_val: float) -> None:
        pass

class OutputProcessor:
    class ReportFreq:
        Simulation = 0
        Invalid = -1
    class EndUseCat:
        pass
    class TimeStepType:
        Zone = 0
        System = 1
    class StoreType:
        Sum = 0
    class Group:
        Invalid = -1

pollFuel2fuel = [
    None,
    None,
    None,
    None,
    None,
    None,
    None,
    None,
    None,
    None
]

poll2Resource = [
    None,
    None,
    None,
    None,
    None,
    None,
    None,
    None,
    None,
    None,
    None,
    None,
    None,
    None,
    None,
    None
]

pollUnits = [
    Constant.Units.kg,
    Constant.Units.kg,
    Constant.Units.kg,
    Constant.Units.kg,
    Constant.Units.kg,
    Constant.Units.kg,
    Constant.Units.kg,
    Constant.Units.kg,
    Constant.Units.kg,
    Constant.Units.kg,
    Constant.Units.kg,
    Constant.Units.kg,
    Constant.Units.kg,
    Constant.Units.L,
    Constant.Units.kg,
    Constant.Units.m3
]
