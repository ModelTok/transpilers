# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData (from EnergyPlus.Data.EnergyPlusData)
# - Constant.eResource, Constant.Units, Constant.eFuel, Constant.eFuelNames, Constant.eFuelNamesUC (from EnergyPlus.DataGlobalConstants)
# - Sched.Schedule, Sched.GetSchedule, Sched.ShowSevereBadMin (from EnergyPlus.ScheduleManager)
# - OutputProcessor.ReportFreq, OutputProcessor.EndUseCat, OutputProcessor.TimeStepType, OutputProcessor.StoreType, OutputProcessor.Group
# - OutputProcessor.GetMeterIndex, OutputProcessor.GetInstantMeterValue, OutputProcessor.ReportingThisVariable, OutputProcessor.SetupOutputVariable (from EnergyPlus.OutputProcessor)
# - InputProcessor.getNumObjectsFound, InputProcessor.getObjectItem (from EnergyPlus.InputProcessing.InputProcessor)
# - Util.makeUPPER, format, ShowSevereError, ShowWarningError, ShowContinueError, ShowFatalError, ShowSevereInvalidKey, ShowSevereItemNotFound, ErrorObjectHeader (from EnergyPlus.UtilityRoutines)

from collections import InlineArray

alias Pollutant = Int32
alias PollFuel = Int32
alias PollFuelComponent = Int32
alias PollFacilityMeter = Int32

alias POLLUTANT_INVALID = -1
alias POLLUTANT_CO2 = 0
alias POLLUTANT_CO = 1
alias POLLUTANT_CH4 = 2
alias POLLUTANT_NOx = 3
alias POLLUTANT_N2O = 4
alias POLLUTANT_SO2 = 5
alias POLLUTANT_PM = 6
alias POLLUTANT_PM10 = 7
alias POLLUTANT_PM2_5 = 8
alias POLLUTANT_NH3 = 9
alias POLLUTANT_NMVOC = 10
alias POLLUTANT_Hg = 11
alias POLLUTANT_Pb = 12
alias POLLUTANT_Water = 13
alias POLLUTANT_NuclearHigh = 14
alias POLLUTANT_NuclearLow = 15
alias POLLUTANT_Num = 16

alias POLLFUEL_INVALID = -1
alias POLLFUEL_Electricity = 0
alias POLLFUEL_NaturalGas = 1
alias POLLFUEL_FuelOil1 = 2
alias POLLFUEL_FuelOil2 = 3
alias POLLFUEL_Coal = 4
alias POLLFUEL_Gasoline = 5
alias POLLFUEL_Propane = 6
alias POLLFUEL_Diesel = 7
alias POLLFUEL_OtherFuel1 = 8
alias POLLFUEL_OtherFuel2 = 9
alias POLLFUEL_Num = 10

alias POLLFUELCOMPONENT_INVALID = -1
alias POLLFUELCOMPONENT_Electricity = 0
alias POLLFUELCOMPONENT_NaturalGas = 1
alias POLLFUELCOMPONENT_FuelOil1 = 2
alias POLLFUELCOMPONENT_FuelOil2 = 3
alias POLLFUELCOMPONENT_Coal = 4
alias POLLFUELCOMPONENT_Gasoline = 5
alias POLLFUELCOMPONENT_Propane = 6
alias POLLFUELCOMPONENT_Diesel = 7
alias POLLFUELCOMPONENT_OtherFuel1 = 8
alias POLLFUELCOMPONENT_OtherFuel2 = 9
alias POLLFUELCOMPONENT_ElectricitySurplusSold = 10
alias POLLFUELCOMPONENT_ElectricityPurchased = 11
alias POLLFUELCOMPONENT_Num = 12

alias POLLFACILITYMETER_INVALID = -1
alias POLLFACILITYMETER_Electricity = 0
alias POLLFACILITYMETER_NaturalGas = 1
alias POLLFACILITYMETER_FuelOil1 = 2
alias POLLFACILITYMETER_FuelOil2 = 3
alias POLLFACILITYMETER_Coal = 4
alias POLLFACILITYMETER_Gasoline = 5
alias POLLFACILITYMETER_Propane = 6
alias POLLFACILITYMETER_Diesel = 7
alias POLLFACILITYMETER_OtherFuel1 = 8
alias POLLFACILITYMETER_OtherFuel2 = 9
alias POLLFACILITYMETER_ElectricitySurplusSold = 10
alias POLLFACILITYMETER_ElectricityPurchased = 11
alias POLLFACILITYMETER_ElectricityProduced = 12
alias POLLFACILITYMETER_Steam = 13
alias POLLFACILITYMETER_HeatPurchased = 14
alias POLLFACILITYMETER_CoolPurchased = 15
alias POLLFACILITYMETER_Num = 16

struct ComponentProps:
    var sourceVal: Float64
    var pollutantVals: InlineArray[Float64, 16]

    fn __init__(inout self):
        self.sourceVal = 0.0
        self.pollutantVals = InlineArray[Float64, 16](fill=0.0)

struct CoefficientProps:
    var used: Bool
    var sourceCoeff: Float64
    var pollutantCoeffs: InlineArray[Float64, 16]
    var sourceSched: DTypePointer[NoneType]
    var pollutantScheds: InlineArray[DTypePointer[NoneType], 16]

    fn __init__(inout self):
        self.used = False
        self.sourceCoeff = 0.0
        self.pollutantCoeffs = InlineArray[Float64, 16](fill=0.0)
        self.sourceSched = DTypePointer[NoneType]()
        self.pollutantScheds = InlineArray[DTypePointer[NoneType], 16]()

struct PollutionData:
    var PollutionReportSetup: Bool
    var GetInputFlagPollution: Bool
    var NumEnvImpactFactors: Int32
    var NumFuelFactors: Int32
    var pollComps: InlineArray[ComponentProps, 12]
    var facilityMeterNums: InlineArray[Int32, 16]
    var facilityMeterVals: InlineArray[Float64, 16]
    var facilityMeterFuelComponentVals: InlineArray[Float64, 12]
    var pollutantVals: InlineArray[Float64, 16]
    var pollFuelFactorList: List[PollFuel]
    var TotCarbonEquivFromN2O: Float64
    var TotCarbonEquivFromCH4: Float64
    var TotCarbonEquivFromCO2: Float64
    var pollCoeffs: InlineArray[CoefficientProps, 10]
    var CarbonEquivN2O: Float64
    var CarbonEquivCH4: Float64
    var CarbonEquivCO2: Float64
    var PurchHeatEffic: Float64
    var PurchCoolCOP: Float64
    var SteamConvEffic: Float64

    fn __init__(inout self):
        self.PollutionReportSetup = False
        self.GetInputFlagPollution = True
        self.NumEnvImpactFactors = 0
        self.NumFuelFactors = 0
        self.pollComps = InlineArray[ComponentProps, 12]()
        self.facilityMeterNums = InlineArray[Int32, 16](fill=-1)
        self.facilityMeterVals = InlineArray[Float64, 16](fill=0.0)
        self.facilityMeterFuelComponentVals = InlineArray[Float64, 12](fill=0.0)
        self.pollutantVals = InlineArray[Float64, 16](fill=0.0)
        self.pollFuelFactorList = List[PollFuel]()
        self.TotCarbonEquivFromN2O = 0.0
        self.TotCarbonEquivFromCH4 = 0.0
        self.TotCarbonEquivFromCO2 = 0.0
        self.pollCoeffs = InlineArray[CoefficientProps, 10]()
        self.CarbonEquivN2O = 0.0
        self.CarbonEquivCH4 = 0.0
        self.CarbonEquivCO2 = 0.0
        self.PurchHeatEffic = 0.0
        self.PurchCoolCOP = 0.0
        self.SteamConvEffic = 0.0

    fn init_constant_state(inout self, state: DTypePointer[NoneType]):
        pass

    fn init_state(inout self, state: DTypePointer[NoneType]):
        pass

    fn clear_state(inout self):
        self.PollutionReportSetup = False
        self.GetInputFlagPollution = True
        self.NumEnvImpactFactors = 0
        self.NumFuelFactors = 0
        self.pollFuelFactorList = List[PollFuel]()

@always_inline
fn pollutation_names() -> List[StringRef]:
    var names = List[StringRef]()
    names.append("CO2")
    names.append("CO")
    names.append("CH4")
    names.append("NOx")
    names.append("N2O")
    names.append("SO2")
    names.append("PM")
    names.append("PM10")
    names.append("PM2.5")
    names.append("NH3")
    names.append("NMVOC")
    names.append("Hg")
    names.append("Pb")
    names.append("WaterEnvironmentalFactors")
    names.append("Nuclear High")
    names.append("Nuclear Low")
    return names

@always_inline
fn poll2out_var_strs() -> List[StringRef]:
    var strs = List[StringRef]()
    strs.append("CO2 Emissions Mass")
    strs.append("CO Emissions Mass")
    strs.append("CH4 Emissions Mass")
    strs.append("NOx Emissions Mass")
    strs.append("N2O Emissions Mass")
    strs.append("SO2 Emissions Mass")
    strs.append("PM Emissions Mass")
    strs.append("PM10 Emissions Mass")
    strs.append("PM2.5 Emissions Mass")
    strs.append("NH3 Emissions Mass")
    strs.append("NMVOC Emissions Mass")
    strs.append("Hg Emissions Mass")
    strs.append("Pb Emissions Mass")
    strs.append("Water Consumption Volume")
    strs.append("Nuclear High Level Waste Mass")
    strs.append("Nuclear Low Level Waste Volume")
    return strs

@always_inline
fn poll_fuel_factors() -> InlineArray[Float64, 10]:
    return InlineArray[Float64, 10](3.167, 1.084, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.0, 1.0)

@always_inline
fn poll_fuel_comp_2_poll_fuel() -> InlineArray[PollFuel, 12]:
    var arr = InlineArray[PollFuel, 12]()
    return arr

@always_inline
fn poll_fuel_2_poll_fuel_component() -> InlineArray[PollFuelComponent, 10]:
    var arr = InlineArray[PollFuelComponent, 10]()
    return arr

@always_inline
fn poll_facility_meter_names() -> List[StringRef]:
    var names = List[StringRef]()
    names.append("Electricity:Facility")
    names.append("NaturalGas:Facility")
    names.append("FuelOilNo1:Facility")
    names.append("FuelOilNo2:Facility")
    names.append("Coal:Facility")
    names.append("Gasoline:Facility")
    names.append("Propane:Facility")
    names.append("Diesel:Facility")
    names.append("OtherFuel1:Facility")
    names.append("OtherFuel2:Facility")
    names.append("ElectricitySurplusSold:Facility")
    names.append("ElectricityPurchased:Facility")
    names.append("ElectricityProduced:Facility")
    names.append("DistrictHeatingSteam:Facility")
    names.append("DistrictHeatingWater:Facility")
    names.append("DistrictCooling:Facility")
    return names

fn CalculatePollution(state: DTypePointer[NoneType]) -> None:
    pass

fn SetupPollutionCalculations(state: DTypePointer[NoneType]) -> None:
    pass

fn GetPollutionFactorInput(state: DTypePointer[NoneType]) -> None:
    pass

fn SetupPollutionMeterReporting(state: DTypePointer[NoneType]) -> None:
    pass

fn CheckPollutionMeterReporting(state: DTypePointer[NoneType]) -> None:
    pass

fn CalcPollution(state: DTypePointer[NoneType]) -> None:
    pass

fn ReadEnergyMeters(state: DTypePointer[NoneType]) -> None:
    pass

fn GetFuelFactorInfo(
    state: DTypePointer[NoneType],
    fuel: Int32,
    inout fuelFactorUsed: Bool,
    inout fuelSourceFactor: Float64,
    inout fuelFactorScheduleUsed: Bool,
    inout ffSched: DTypePointer[NoneType]
) -> None:
    pass

fn GetEnvironmentalImpactFactorInfo(
    state: DTypePointer[NoneType],
    inout efficiencyDistrictHeatingWater: Float64,
    inout efficiencyDistrictCooling: Float64,
    inout sourceFactorDistrictHeatingSteam: Float64
) -> None:
    pass
