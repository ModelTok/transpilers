from .Data.BaseData import BaseGlobalStruct
from DataGlobalConstants import Constant
from DataGlobals import DataGlobals
from  import EnergyPlusData
from .Data.EnergyPlusData import EnergyPlusData
from DataEnvironment import DataEnvironment
from DataGlobalConstants import Constant
from DataHVACGlobals import DataHVACGlobals
from DataIPShortCuts import DataIPShortCuts
from .InputProcessing.InputProcessor import InputProcessor
from OutputProcessor import OutputProcessor
from ScheduleManager import Sched
from UtilityRoutines import Util
from ObjexxFCL.Array1D import Array1D

from memory import Pointer
from math import *
from sys import *
from python import Python

alias Real64 = Float64
alias int = Int

enum Pollutant(Int):
    Invalid = -1
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

var pollNames: StaticArray[String, 16] = StaticArray[String, 16](
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
)

var poll2Resource: StaticArray[Constant.eResource, 16] = StaticArray[Constant.eResource, 16](
    Constant.eResource.CO2,
    Constant.eResource.CO,
    Constant.eResource.CH4,
    Constant.eResource.NOx,
    Constant.eResource.N2O,
    Constant.eResource.SO2,
    Constant.eResource.PM,
    Constant.eResource.PM10,
    Constant.eResource.PM2_5,
    Constant.eResource.NH3,
    Constant.eResource.NMVOC,
    Constant.eResource.Hg,
    Constant.eResource.Pb,
    Constant.eResource.WaterEnvironmentalFactors,
    Constant.eResource.NuclearHigh,
    Constant.eResource.NuclearLow
)

var pollUnits: StaticArray[Constant.Units, 16] = StaticArray[Constant.Units, 16](
    Constant.Units.kg, # CO2
    Constant.Units.kg, # CO
    Constant.Units.kg, # CH4
    Constant.Units.kg, # NOx
    Constant.Units.kg, # N2O
    Constant.Units.kg, # SO2
    Constant.Units.kg, # PM
    Constant.Units.kg, # PM10
    Constant.Units.kg, # PM2_5
    Constant.Units.kg, # NH3
    Constant.Units.kg, # NMVOC
    Constant.Units.kg, # Hg
    Constant.Units.kg, # Pb
    Constant.Units.L,  # Water
    Constant.Units.kg, # NuclearHigh
    Constant.Units.m3, # NuclearLow
)

var poll2outVarStrs: StaticArray[String, 16] = StaticArray[String, 16](
    "CO2 Emissions Mass",             # CO2
    "CO Emissions Mass",              # CO
    "CH4 Emissions Mass",             # CH4
    "NOx Emissions Mass",             # NOx
    "N2O Emissions Mass",             # N2O
    "SO2 Emissions Mass",             # SO2
    "PM Emissions Mass",              # PM
    "PM10 Emissions Mass",            # PM10
    "PM2.5 Emissions Mass",           # PM2_5
    "NH3 Emissions Mass",             # NH3
    "NMVOC Emissions Mass",           # NMVOC
    "Hg Emissions Mass",              # Hg
    "Pb Emissions Mass",              # Pb
    "Water Consumption Volume",       # Water
    "Nuclear High Level Waste Mass",  # NuclearHigh
    "Nuclear Low Level Waste Volume", # NuclearLow
)

enum PollFuel(Int):
    Invalid = -1
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

var pollFuelFactors: StaticArray[Real64, 10] = StaticArray[Real64, 10](
    3.167, # Electricity
    1.084, # NaturalGas
    1.05,  # FuelOil1
    1.05,  # FuelOil2
    1.05,  # Coal
    1.05,  # Gasoline
    1.05,  # Propane
    1.05,  # Diesel
    1.0,   # OtherFuel1
    1.0    # OtherFuel2
)

var fuel2pollFuel: StaticArray[PollFuel, 13] = StaticArray[PollFuel, 13](
    PollFuel.Electricity, # Electricity
    PollFuel.NaturalGas,  # NaturalGas
    PollFuel.Gasoline,    # Gasoline
    PollFuel.Diesel,      # Diesel
    PollFuel.Coal,        # Coal
    PollFuel.Propane,     # Propane
    PollFuel.FuelOil1,    # FuelOilNo1
    PollFuel.FuelOil2,    # FuelOilNo2
    PollFuel.OtherFuel1,  # OtherFuel1
    PollFuel.OtherFuel2,  # OtherFuel2
    PollFuel.Electricity, # DistrictCooling
    PollFuel.NaturalGas,  # DistrictHeatingWater
    PollFuel.NaturalGas,  # DistrictHeatingSteam
)

var pollFuel2fuel: StaticArray[Constant.eFuel, 10] = StaticArray[Constant.eFuel, 10](
    Constant.eFuel.Electricity, # Electricity
    Constant.eFuel.NaturalGas,  # NaturalGas
    Constant.eFuel.FuelOilNo1,  # FuelOil1
    Constant.eFuel.FuelOilNo2,  # FuelOil2
    Constant.eFuel.Coal,        # Coal
    Constant.eFuel.Gasoline,    # Gasoline
    Constant.eFuel.Propane,     # Propane
    Constant.eFuel.Diesel,      # Diesel
    Constant.eFuel.OtherFuel1,  # OtherFuel1
    Constant.eFuel.OtherFuel2   # OtherFuel2
)

var pollFuelNamesUC: StaticArray[String, 10] = StaticArray[String, 10](
    Constant.eFuelNamesUC[int(pollFuel2fuel[int(PollFuel.Electricity)])], # Electricity
    Constant.eFuelNamesUC[int(pollFuel2fuel[int(PollFuel.NaturalGas)])],  # NaturalGas
    Constant.eFuelNamesUC[int(pollFuel2fuel[int(PollFuel.FuelOil1)])],    # FuelOil1
    Constant.eFuelNamesUC[int(pollFuel2fuel[int(PollFuel.FuelOil2)])],    # FuelOil2
    Constant.eFuelNamesUC[int(pollFuel2fuel[int(PollFuel.Coal)])],        # Coal
    Constant.eFuelNamesUC[int(pollFuel2fuel[int(PollFuel.Gasoline)])],    # Gasoline
    Constant.eFuelNamesUC[int(pollFuel2fuel[int(PollFuel.Propane)])],     # Propane
    Constant.eFuelNamesUC[int(pollFuel2fuel[int(PollFuel.Diesel)])],      # Diesel
    Constant.eFuelNamesUC[int(pollFuel2fuel[int(PollFuel.OtherFuel1)])],  # OtherFuel1
    Constant.eFuelNamesUC[int(pollFuel2fuel[int(PollFuel.OtherFuel2)])]   # OtherFuel2
)

enum PollFuelComponent(Int):
    Invalid = -1
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

var pollFuelComp2pollFuel: StaticArray[PollFuel, 12] = StaticArray[PollFuel, 12](
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
)

var pollFuel2pollFuelComponent: StaticArray[PollFuelComponent, 10] = StaticArray[PollFuelComponent, 10](
    PollFuelComponent.Electricity,
    PollFuelComponent.NaturalGas,
    PollFuelComponent.FuelOil1,
    PollFuelComponent.FuelOil2,
    PollFuelComponent.Coal,
    PollFuelComponent.Gasoline,
    PollFuelComponent.Propane,
    PollFuelComponent.Diesel,
    PollFuelComponent.OtherFuel1,
    PollFuelComponent.OtherFuel2,
)

enum PollFacilityMeter(Int):
    Invalid = -1
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

var pollFacilityMeterNames: StaticArray[String, 16] = StaticArray[String, 16](
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
)

@value
struct ComponentProps:
    var sourceVal: Real64 = 0.0
    var pollutantVals: StaticArray[Real64, 16] = StaticArray[Real64, 16](0.0)

@value
struct CoefficientProps:
    var used: Bool = False
    var sourceCoeff: Real64 = 0.0
    var pollutantCoeffs: StaticArray[Real64, 16] = StaticArray[Real64, 16](0.0)
    var sourceSched: Pointer[Sched.Schedule] = Pointer[Sched.Schedule]()
    var pollutantScheds: StaticArray[Pointer[Sched.Schedule], 16] = StaticArray[Pointer[Sched.Schedule], 16](Pointer[Sched.Schedule]())

def CalculatePollution(state: EnergyPlusData):
    if not state.dataPollution.PollutionReportSetup:
        return
    ReadEnergyMeters(state)
    CalcPollution(state)

def SetupPollutionCalculations(state: EnergyPlusData):
    var NumPolluteRpt: Int
    var NumAlphas: Int
    var NumNums: Int
    var Loop: Int
    var IOStat: Int
    var cCurrentModuleObject: String = state.dataIPShortCut.cCurrentModuleObject
    cCurrentModuleObject = "Output:EnvironmentalImpactFactors"
    NumPolluteRpt = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, cCurrentModuleObject)
    state.dataPollution.PollutionReportSetup = True
    for Loop in range(1, NumPolluteRpt + 1):
        state.dataInputProcessing.inputProcessor.getObjectItem(state,
                                                                 cCurrentModuleObject,
                                                                 Loop,
                                                                 state.dataIPShortCut.cAlphaArgs,
                                                                 NumAlphas,
                                                                 state.dataIPShortCut.rNumericArgs,
                                                                 NumNums,
                                                                 IOStat,
                                                                 state.dataIPShortCut.lNumericFieldBlanks,
                                                                 state.dataIPShortCut.lAlphaFieldBlanks,
                                                                 state.dataIPShortCut.cAlphaFieldNames,
                                                                 state.dataIPShortCut.cNumericFieldNames)
        var freq: OutputProcessor.ReportFreq = OutputProcessor.ReportFreq.Simulation
        if not state.dataIPShortCut.lAlphaFieldBlanks[0]:
            freq = OutputProcessor.ReportFreq(
                getEnumValue(OutputProcessor.reportFreqNamesUC, Util.makeUPPER(state.dataIPShortCut.cAlphaArgs[0])))
            if freq == OutputProcessor.ReportFreq.Invalid:
                ShowSevereError(state, "Invalid reporting frequency " + state.dataIPShortCut.cAlphaArgs[0])
                continue
        InitPollutionMeterReporting(state, freq)

def GetPollutionFactorInput(state: EnergyPlusData):
    var routineName: String = "GetPollutionFactorInput"
    var NumAlphas: Int
    var NumNums: Int
    var IOStat: Int
    var ErrorsFound: Bool = False
    var ip: InputProcessor = state.dataInputProcessing.inputProcessor
    var ipsc: DataIPShortCuts = state.dataIPShortCut
    var pm: PollutionData = state.dataPollution
    if not pm.GetInputFlagPollution:
        return # Input already gotten
    pm.GetInputFlagPollution = False
    ipsc.cCurrentModuleObject = "EnvironmentalImpactFactors"
    pm.NumEnvImpactFactors = ip.getNumObjectsFound(state, ipsc.cCurrentModuleObject)
    if pm.NumEnvImpactFactors > 0:
        ip.getObjectItem(state,
                          ipsc.cCurrentModuleObject,
                          1,
                          ipsc.cAlphaArgs,
                          NumAlphas,
                          ipsc.rNumericArgs,
                          NumNums,
                          IOStat,
                          ipsc.lNumericFieldBlanks,
                          ipsc.lAlphaFieldBlanks,
                          ipsc.cAlphaFieldNames,
                          ipsc.cNumericFieldNames)
    elif pm.PollutionReportSetup:
        ShowWarningError(state, routineName + ": " + ipsc.cCurrentModuleObject + " not entered.  Values will be defaulted.")
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
    for Loop in range(1, state.dataPollution.NumFuelFactors + 1):
        ip.getObjectItem(state,
                          ipsc.cCurrentModuleObject,
                          Loop,
                          ipsc.cAlphaArgs,
                          NumAlphas,
                          ipsc.rNumericArgs,
                          NumNums,
                          IOStat,
                          ipsc.lNumericFieldBlanks,
                          ipsc.lAlphaFieldBlanks,
                          ipsc.cAlphaFieldNames,
                          ipsc.cNumericFieldNames)
        var eoh: ErrorObjectHeader = ErrorObjectHeader(routineName, ipsc.cCurrentModuleObject, ipsc.cAlphaArgs[0])
        var pollFuel: PollFuel = PollFuel(getEnumValue(pollFuelNamesUC, Util.makeUPPER(ipsc.cAlphaArgs[0])))
        if pollFuel == PollFuel.Invalid:
            ShowSevereInvalidKey(state, eoh, ipsc.cAlphaFieldNames[0], ipsc.cAlphaArgs[0])
            ErrorsFound = True
            continue
        pm.pollFuelFactorList.append(pollFuel)
        var pollCoeff: CoefficientProps = pm.pollCoeffs[int(pollFuel)]
        var fuel: Constant.eFuel = pollFuel2fuel[int(pollFuel)]
        if pollCoeff.used:
            ShowWarningError(
                state,
                ipsc.cCurrentModuleObject + ": " + Constant.eFuelNames[int(fuel)] + " already entered. Previous entry will be used.")
            continue
        pollCoeff.used = True
        pollCoeff.sourceCoeff = ipsc.rNumericArgs[0]
        if ipsc.lAlphaFieldBlanks[1]:

        elif (pollCoeff.sourceSched = Sched.GetSchedule(state, ipsc.cAlphaArgs[1])) == Pointer[Sched.Schedule]():
            ShowSevereItemNotFound(state, eoh, ipsc.cAlphaFieldNames[1], ipsc.cAlphaArgs[1])
            ErrorsFound = True
        elif not pollCoeff.sourceSched[].checkMinVal(state, Clusive.In, 0.0):
            Sched.ShowSevereBadMin(state, eoh, ipsc.cAlphaFieldNames[1], ipsc.cAlphaArgs[1], Clusive.In, 0.0)
            ErrorsFound = True
        for iPollutant in range(0, int(Pollutant.Num)):
            pollCoeff.pollutantCoeffs[iPollutant] = ipsc.rNumericArgs[iPollutant + 1]
            if ipsc.lAlphaFieldBlanks[iPollutant + 2]:

            elif (pollCoeff.pollutantScheds[iPollutant] = Sched.GetSchedule(state, ipsc.cAlphaArgs[iPollutant + 2])) == Pointer[Sched.Schedule]():
                ShowSevereItemNotFound(state, eoh, ipsc.cAlphaFieldNames[iPollutant + 2], ipsc.cAlphaArgs[iPollutant + 2])
                ErrorsFound = True
            elif not pollCoeff.pollutantScheds[iPollutant][].checkMinVal(state, Clusive.In, 0.0):
                Sched.ShowSevereBadMin(state, eoh, ipsc.cAlphaFieldNames[iPollutant + 2], ipsc.cAlphaArgs[iPollutant + 2], Clusive.In, 0.0)
                ErrorsFound = True
        # for (iPollutant)
    # End of the NumEnergyTypes Do Loop
    if pm.PollutionReportSetup: # only do this if reporting on the pollution
        if not pm.pollCoeffs[int(PollFuel.Electricity)].used and ((pm.facilityMeterNums[int(PollFacilityMeter.Electricity)] > 0) or
                                                                 (pm.facilityMeterNums[int(PollFacilityMeter.ElectricityProduced)] > 0) or
                                                                 (pm.facilityMeterNums[int(PollFacilityMeter.CoolPurchased)] > 0)):
            ShowSevereError(state,
                            ipsc.cCurrentModuleObject + " Not Found or Fuel not specified For Pollution Calculation for ELECTRICITY")
            ErrorsFound = True
        if not pm.pollCoeffs[int(PollFuel.NaturalGas)].used and \
            ((pm.facilityMeterNums[int(PollFacilityMeter.NaturalGas)] > 0) or (pm.facilityMeterNums[int(PollFacilityMeter.HeatPurchased)] > 0) or \
             (pm.facilityMeterNums[int(PollFacilityMeter.Steam)] > 0)):
            ShowSevereError(state,
                            ipsc.cCurrentModuleObject + " Not Found or Fuel not specified For Pollution Calculation for NATURAL GAS")
            ErrorsFound = True
        if not pm.pollCoeffs[int(PollFuel.FuelOil2)].used and (pm.facilityMeterNums[int(PollFacilityMeter.FuelOil2)] > 0):
            ShowSevereError(state,
                            ipsc.cCurrentModuleObject + " Not Found or Fuel not specified For Pollution Calculation for FUEL OIL #2")
            ErrorsFound = True
        if not pm.pollCoeffs[int(PollFuel.FuelOil1)].used and (pm.facilityMeterNums[int(PollFacilityMeter.FuelOil1)] > 0):
            ShowSevereError(state,
                            ipsc.cCurrentModuleObject + " Not Found or Fuel not specified For Pollution Calculation for FUEL OIL #1")
            ErrorsFound = True
        if not pm.pollCoeffs[int(PollFuel.Coal)].used and (pm.facilityMeterNums[int(PollFacilityMeter.Coal)] > 0):
            ShowSevereError(state, ipsc.cCurrentModuleObject + " Not Found or Fuel not specified For Pollution Calculation for COAL")
            ErrorsFound = True
        if not pm.pollCoeffs[int(PollFuel.Gasoline)].used and (pm.facilityMeterNums[int(PollFacilityMeter.Gasoline)] > 0):
            ShowSevereError(state,
                            ipsc.cCurrentModuleObject + " Not Found or Fuel not specified For Pollution Calculation for GASOLINE")
            ErrorsFound = True
        if not pm.pollCoeffs[int(PollFuel.Propane)].used and (pm.facilityMeterNums[int(PollFacilityMeter.Propane)] > 0):
            ShowSevereError(state,
                            ipsc.cCurrentModuleObject + " Not Found or Fuel not specified For Pollution Calculation for PROPANE")
            ErrorsFound = True
        if not pm.pollCoeffs[int(PollFuel.Diesel)].used and (pm.facilityMeterNums[int(PollFacilityMeter.Diesel)] > 0):
            ShowSevereError(state,
                            ipsc.cCurrentModuleObject + " Not Found or Fuel not specified For Pollution Calculation for DIESEL")
            ErrorsFound = True
        if not pm.pollCoeffs[int(PollFuel.OtherFuel1)].used and (pm.facilityMeterNums[int(PollFacilityMeter.OtherFuel1)] > 0):
            ShowSevereError(state,
                            ipsc.cCurrentModuleObject + " Not Found or Fuel not specified For Pollution Calculation for OTHERFUEL1")
            ErrorsFound = True
        if not pm.pollCoeffs[int(PollFuel.OtherFuel2)].used and (pm.facilityMeterNums[int(PollFacilityMeter.OtherFuel2)] > 0):
            ShowSevereError(state,
                            ipsc.cCurrentModuleObject + " Not Found or Fuel not specified For Pollution Calculation for OTHERFUEL2")
            ErrorsFound = True
    if ErrorsFound:
        ShowFatalError(state, "Errors found in getting Pollution Calculation Reporting Input")

def SetupPollutionMeterReporting(state: EnergyPlusData):
    var pm: PollutionData = state.dataPollution
    if pm.GetInputFlagPollution:
        GetPollutionFactorInput(state)
        pm.GetInputFlagPollution = False
    for pollFuel in pm.pollFuelFactorList:
        if not pm.pollCoeffs[int(pollFuel)].used:
            continue
        var pollComp: ComponentProps = pm.pollComps[int(pollFuel2pollFuelComponent[int(pollFuel)])]
        var fuel: Constant.eFuel = pollFuel2fuel[int(pollFuel)]
        var fuel2sovEndUseCat: StaticArray[OutputProcessor.EndUseCat, 13] = StaticArray[OutputProcessor.EndUseCat, 13](
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
            OutputProcessor.EndUseCat.Invalid # used for OtherEquipment object
        )
        SetupOutputVariable(state,
                            "Environmental Impact " + Constant.eFuelNames[int(fuel)] + " Source Energy",
                            Constant.Units.J,
                            pollComp.sourceVal,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Sum,
                            "Site",
                            Constant.eResource.Source,
                            OutputProcessor.Group.Invalid,
                            fuel2sovEndUseCat[int(fuel)])
        for iPollutant in range(0, int(Pollutant.Num)):
            SetupOutputVariable(state,
                                "Environmental Impact " + Constant.eFuelNames[int(fuel)] + " " + poll2outVarStrs[iPollutant],
                                pollUnits[iPollutant],
                                pollComp.pollutantVals[iPollutant],
                                OutputProcessor.TimeStepType.System,
                                OutputProcessor.StoreType.Sum,
                                "Site",
                                poll2Resource[iPollutant],
                                OutputProcessor.Group.Invalid,
                                fuel2sovEndUseCat[int(fuel)])
        if fuel == Constant.eFuel.Electricity:
            SetupOutputVariable(state,
                                "Environmental Impact Purchased Electricity Source Energy",
                                Constant.Units.J,
                                pm.pollComps[int(PollFuelComponent.ElectricityPurchased)].sourceVal,
                                OutputProcessor.TimeStepType.System,
                                OutputProcessor.StoreType.Sum,
                                "Site",
                                Constant.eResource.Source,
                                OutputProcessor.Group.Invalid,
                                OutputProcessor.EndUseCat.PurchasedElectricityEmissions)
            SetupOutputVariable(state,
                                "Environmental Impact Surplus Sold Electricity Source",
                                Constant.Units.J,
                                pm.pollComps[int(PollFuelComponent.ElectricitySurplusSold)].sourceVal,
                                OutputProcessor.TimeStepType.System,
                                OutputProcessor.StoreType.Sum,
                                "Site",
                                Constant.eResource.Source,
                                OutputProcessor.Group.Invalid,
                                OutputProcessor.EndUseCat.SoldElectricityEmissions)
    # End of the NumEnergyTypes Do Loop
    SetupOutputVariable(state,
                        "Environmental Impact Total N2O Emissions Carbon Equivalent Mass",
                        Constant.Units.kg,
                        pm.TotCarbonEquivFromN2O,
                        OutputProcessor.TimeStepType.System,
                        OutputProcessor.StoreType.Sum,
                        "Site",
                        Constant.eResource.CarbonEquivalent,
                        OutputProcessor.Group.Invalid,
                        OutputProcessor.EndUseCat.CarbonEquivalentEmissions)
    SetupOutputVariable(state,
                        "Environmental Impact Total CH4 Emissions Carbon Equivalent Mass",
                        Constant.Units.kg,
                        pm.TotCarbonEquivFromCH4,
                        OutputProcessor.TimeStepType.System,
                        OutputProcessor.StoreType.Sum,
                        "Site",
                        Constant.eResource.CarbonEquivalent,
                        OutputProcessor.Group.Invalid,
                        OutputProcessor.EndUseCat.CarbonEquivalentEmissions)
    SetupOutputVariable(state,
                        "Environmental Impact Total CO2 Emissions Carbon Equivalent Mass",
                        Constant.Units.kg,
                        pm.TotCarbonEquivFromCO2,
                        OutputProcessor.TimeStepType.System,
                        OutputProcessor.StoreType.Sum,
                        "Site",
                        Constant.eResource.CarbonEquivalent,
                        OutputProcessor.Group.Invalid,
                        OutputProcessor.EndUseCat.CarbonEquivalentEmissions)
    for iMeter in range(0, int(PollFacilityMeter.Num)):
        pm.facilityMeterNums[iMeter] = GetMeterIndex(state, Util.makeUPPER(pollFacilityMeterNames[iMeter]))

def CheckPollutionMeterReporting(state: EnergyPlusData):
    var pm: PollutionData = state.dataPollution
    if pm.NumFuelFactors == 0 or pm.NumEnvImpactFactors == 0:
        if ReportingThisVariable(state, "Environmental Impact Total N2O Emissions Carbon Equivalent Mass") or \
            ReportingThisVariable(state, "Environmental Impact Total CH4 Emissions Carbon Equivalent Mass") or \
            ReportingThisVariable(state, "Environmental Impact Total CO2 Emissions Carbon Equivalent Mass") or \
            ReportingThisVariable(state, "Carbon Equivalent:Facility") or \
            ReportingThisVariable(state, "CarbonEquivalentEmissions:Carbon Equivalent"):
            ShowWarningError(
                state, "GetPollutionFactorInput: Requested reporting for Carbon Equivalent Pollution, but insufficient information is entered.")
            ShowContinueError(
                state, "Both \"FuelFactors\" and \"EnvironmentalImpactFactors\" must be entered or the displayed carbon pollution will all be zero.")

def CalcPollution(state: EnergyPlusData):
    var pm: PollutionData = state.dataPollution
    for iPoll in range(0, int(Pollutant.Num)):
        pm.pollutantVals[iPoll] = 0.0
        for iPollFuel in range(0, int(PollFuel.Num)):
            var pollCoeff: CoefficientProps = pm.pollCoeffs[iPollFuel]
            var pollFuelComp: PollFuelComponent = pollFuel2pollFuelComponent[iPollFuel]
            var pollComp: ComponentProps = pm.pollComps[int(pollFuelComp)]
            if pollCoeff.used:
                pollComp.pollutantVals[iPoll] = 0.0
                var pollutantVal: Real64 = pollCoeff.pollutantCoeffs[iPoll]
                if iPoll != int(Pollutant.Water) and iPoll != int(Pollutant.NuclearLow):
                    pollutantVal *= 0.001
                if pollCoeff.pollutantScheds[iPoll] != Pointer[Sched.Schedule]():
                    pollutantVal *= pollCoeff.pollutantScheds[iPoll][].getCurrentVal()
                pollComp.pollutantVals[iPoll] = pm.facilityMeterFuelComponentVals[int(pollFuelComp)] * 1.0e-6 * pollutantVal
            pm.pollutantVals[iPoll] += pollComp.pollutantVals[iPoll]
        # for (iPollFactor)
    # for (iPoll)
    pm.TotCarbonEquivFromN2O = pm.pollutantVals[int(Pollutant.N2O)] * pm.CarbonEquivN2O
    pm.TotCarbonEquivFromCH4 = pm.pollutantVals[int(Pollutant.CH4)] * pm.CarbonEquivCH4
    pm.TotCarbonEquivFromCO2 = pm.pollutantVals[int(Pollutant.CO2)] * pm.CarbonEquivCO2
    var pollCoeffElec: CoefficientProps = pm.pollCoeffs[int(PollFuel.Electricity)]
    var pollCompElec: ComponentProps = pm.pollComps[int(PollFuelComponent.Electricity)]
    var pollCompElecPurchased: ComponentProps = pm.pollComps[int(PollFuelComponent.ElectricityPurchased)]
    var pollCompElecSurplusSold: ComponentProps = pm.pollComps[int(PollFuelComponent.ElectricitySurplusSold)]
    pollCompElec.sourceVal = pm.facilityMeterFuelComponentVals[int(PollFuelComponent.Electricity)] * pollCoeffElec.sourceCoeff
    pollCompElecPurchased.sourceVal = pm.facilityMeterFuelComponentVals[int(PollFuelComponent.ElectricityPurchased)] * pollCoeffElec.sourceCoeff
    pollCompElecSurplusSold.sourceVal = \
        pm.facilityMeterFuelComponentVals[int(PollFuelComponent.ElectricitySurplusSold)] * pollCoeffElec.sourceCoeff
    if pollCoeffElec.sourceSched != Pointer[Sched.Schedule]():
        var pollCoeffElecSchedVal: Real64 = pollCoeffElec.sourceSched[].getCurrentVal()
        pollCompElec.sourceVal *= pollCoeffElecSchedVal
        pollCompElecPurchased.sourceVal *= pollCoeffElecSchedVal
        pollCompElecSurplusSold.sourceVal *= pollCoeffElecSchedVal
    var pollCoeffGas: CoefficientProps = pm.pollCoeffs[int(PollFuel.NaturalGas)]
    var pollCompGas: ComponentProps = pm.pollComps[int(PollFuelComponent.NaturalGas)]
    pollCompGas.sourceVal = pm.facilityMeterVals[int(PollFacilityMeter.NaturalGas)] * pollCoeffGas.sourceCoeff
    if pollCoeffGas.sourceSched != Pointer[Sched.Schedule]():
        pollCompGas.sourceVal *= pollCoeffGas.sourceSched[].getCurrentVal()
    for pollFuel in [PollFuel.FuelOil1,
                              PollFuel.FuelOil2,
                              PollFuel.Diesel,
                              PollFuel.Gasoline,
                              PollFuel.Propane,
                              PollFuel.Coal,
                              PollFuel.OtherFuel1,
                              PollFuel.OtherFuel2]:
        var pollCoeff: CoefficientProps = pm.pollCoeffs[int(pollFuel)]
        var pollFuelComponent: PollFuelComponent = pollFuel2pollFuelComponent[int(pollFuel)]
        var pollComp: ComponentProps = pm.pollComps[int(pollFuelComponent)]
        pollComp.sourceVal = pm.facilityMeterFuelComponentVals[int(pollFuelComponent)] * pollCoeff.sourceCoeff
        if pollCoeff.sourceSched != Pointer[Sched.Schedule]():
            pollComp.sourceVal *= pollCoeff.sourceSched[].getCurrentVal()
    # for (pollFuelComponent)
# CalcPollution()

def ReadEnergyMeters(state: EnergyPlusData):
    var FracTimeStepZone: Real64 = state.dataHVACGlobal.FracTimeStepZone
    var pm: PollutionData = state.dataPollution
    for iMeter in range(0, int(PollFacilityMeter.Num)):
        pm.facilityMeterVals[iMeter] = \
            GetInstantMeterValue(state, pm.facilityMeterNums[iMeter], OutputProcessor.TimeStepType.Zone) * FracTimeStepZone + \
            GetInstantMeterValue(state, pm.facilityMeterNums[iMeter], OutputProcessor.TimeStepType.System)
    pm.facilityMeterFuelComponentVals[int(PollFuelComponent.Electricity)] = \
        pm.facilityMeterVals[int(PollFacilityMeter.Electricity)] - pm.facilityMeterVals[int(PollFacilityMeter.ElectricityProduced)] + \
        pm.facilityMeterVals[int(PollFacilityMeter.CoolPurchased)] / pm.PurchCoolCOP
    if pm.facilityMeterFuelComponentVals[int(PollFuelComponent.Electricity)] < 0.0:
        pm.facilityMeterFuelComponentVals[int(PollFuelComponent.Electricity)] = 0.0
    pm.facilityMeterFuelComponentVals[int(PollFuelComponent.NaturalGas)] = \
        pm.facilityMeterVals[int(PollFacilityMeter.NaturalGas)] + \
        pm.facilityMeterVals[int(PollFacilityMeter.HeatPurchased)] / pm.PurchHeatEffic + \
        pm.facilityMeterVals[int(PollFacilityMeter.Steam)] / pm.SteamConvEffic
    pm.facilityMeterFuelComponentVals[int(PollFuelComponent.FuelOil1)] = pm.facilityMeterVals[int(PollFacilityMeter.FuelOil1)]
    pm.facilityMeterFuelComponentVals[int(PollFuelComponent.FuelOil2)] = pm.facilityMeterVals[int(PollFacilityMeter.FuelOil2)]
    pm.facilityMeterFuelComponentVals[int(PollFuelComponent.Gasoline)] = pm.facilityMeterVals[int(PollFacilityMeter.Gasoline)]
    pm.facilityMeterFuelComponentVals[int(PollFuelComponent.Propane)] = pm.facilityMeterVals[int(PollFacilityMeter.Propane)]
    pm.facilityMeterFuelComponentVals[int(PollFuelComponent.Coal)] = pm.facilityMeterVals[int(PollFacilityMeter.Coal)]
    pm.facilityMeterFuelComponentVals[int(PollFuelComponent.Diesel)] = pm.facilityMeterVals[int(PollFacilityMeter.Diesel)]
    pm.facilityMeterFuelComponentVals[int(PollFuelComponent.OtherFuel1)] = pm.facilityMeterVals[int(PollFacilityMeter.OtherFuel1)]
    pm.facilityMeterFuelComponentVals[int(PollFuelComponent.OtherFuel2)] = pm.facilityMeterVals[int(PollFacilityMeter.OtherFuel2)]
    pm.facilityMeterFuelComponentVals[int(PollFuelComponent.ElectricityPurchased)] = \
        pm.facilityMeterVals[int(PollFacilityMeter.ElectricityPurchased)]
    pm.facilityMeterFuelComponentVals[int(PollFuelComponent.ElectricitySurplusSold)] = \
        pm.facilityMeterVals[int(PollFacilityMeter.ElectricitySurplusSold)]

def GetFuelFactorInfo(state: EnergyPlusData,
                       fuel: Constant.eFuel,         # input fuel name  (standard from Tabular reports)
                       fuelFactorUsed: Bool,         # return value true if user has entered this fuel
                       fuelSourceFactor: Real64,     # if used, the source factor
                       fuelFactorScheduleUsed: Bool, # if true, schedules for this fuel are used
                       ffSched: Pointer[Pointer[Sched.Schedule]]     # if schedules for this fuel are used, return schedule index
):
    var pm: PollutionData = state.dataPollution
    if pm.GetInputFlagPollution:
        GetPollutionFactorInput(state)
        pm.GetInputFlagPollution = False
    fuelFactorUsed = False
    fuelSourceFactor = 0.0
    fuelFactorScheduleUsed = False
    ffSched[] = Pointer[Sched.Schedule]()
    var pollFuel: PollFuel = fuel2pollFuel[int(fuel)]
    var pollCoeff: CoefficientProps = pm.pollCoeffs[int(pollFuel)]
    if pollCoeff.used:
        fuelFactorUsed = True
        fuelSourceFactor = pollCoeff.sourceCoeff
        if pollCoeff.sourceSched == Pointer[Sched.Schedule]():
            fuelFactorScheduleUsed = False
        else:
            fuelFactorScheduleUsed = True
            ffSched[] = pollCoeff.sourceSched
    else:
        fuelSourceFactor = pollFuelFactors[int(pollFuel)]
    if fuel == Constant.eFuel.DistrictHeatingWater:
        fuelSourceFactor /= pm.PurchHeatEffic
    elif fuel == Constant.eFuel.DistrictCooling:
        fuelSourceFactor /= pm.PurchCoolCOP
    elif fuel == Constant.eFuel.DistrictHeatingSteam:
        fuelSourceFactor = 0.3 / pm.SteamConvEffic

def GetEnvironmentalImpactFactorInfo(state: EnergyPlusData,
                                      efficiencyDistrictHeatingWater: Real64,  # if entered, the efficiency of District Heating Water
                                      efficiencyDistrictCooling: Real64,       # if entered, the efficiency of District Cooling
                                      sourceFactorDistrictHeatingSteam: Real64 # if entered, the source factor for Dictrict Heating Steam
):
    var pm: PollutionData = state.dataPollution
    if pm.GetInputFlagPollution:
        GetPollutionFactorInput(state)
        pm.GetInputFlagPollution = False
    if pm.NumEnvImpactFactors > 0:
        efficiencyDistrictHeatingWater = pm.PurchHeatEffic
        sourceFactorDistrictHeatingSteam = pm.SteamConvEffic
        efficiencyDistrictCooling = pm.PurchCoolCOP

struct PollutionData(BaseGlobalStruct):
    var PollutionReportSetup: Bool = False
    var GetInputFlagPollution: Bool = True
    var NumEnvImpactFactors: Int = 0
    var NumFuelFactors: Int = 0
    var pollComps: StaticArray[ComponentProps, 12] = StaticArray[ComponentProps, 12](ComponentProps())
    var facilityMeterNums: StaticArray[Int, 16] = StaticArray[Int, 16](-1)
    var facilityMeterVals: StaticArray[Real64, 16] = StaticArray[Real64, 16](0.0)
    var facilityMeterFuelComponentVals: StaticArray[Real64, 12] = StaticArray[Real64, 12](0.0)
    var pollutantVals: StaticArray[Real64, 16] = StaticArray[Real64, 16](0.0)
    var pollFuelFactorList: List[PollFuel] = List[PollFuel]()
    var TotCarbonEquivFromN2O: Real64 = 0.0
    var TotCarbonEquivFromCH4: Real64 = 0.0
    var TotCarbonEquivFromCO2: Real64 = 0.0
    var pollCoeffs: StaticArray[CoefficientProps, 10] = StaticArray[CoefficientProps, 10](CoefficientProps())
    var CarbonEquivN2O: Real64 = 0.0
    var CarbonEquivCH4: Real64 = 0.0
    var CarbonEquivCO2: Real64 = 0.0
    var PurchHeatEffic: Real64 = 0.0
    var PurchCoolCOP: Real64 = 0.0
    var SteamConvEffic: Real64 = 0.0

    def init_constant_state(state: EnergyPlusData):

    def init_state(state: EnergyPlusData):

    def clear_state():
        self.PollutionReportSetup = False
        self.GetInputFlagPollution = True
        self.NumEnvImpactFactors = 0
        self.NumFuelFactors = 0
        self.pollFuelFactorList.clear()