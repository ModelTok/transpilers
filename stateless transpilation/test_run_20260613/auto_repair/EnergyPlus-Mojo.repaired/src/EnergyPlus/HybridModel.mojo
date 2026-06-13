# HybridModel.mojo - faithful translation from C++

from DataHeatBalance import *
from DataIPShortCuts import *
from DataRoomAirModel import *
from HeatBalanceManager import *
from InputProcessing.InputProcessor import *
from OutputProcessor import SetupOutputVariable, TimeStepType, StoreType
from ScheduleManager import Schedule, GetSchedule
from UtilityRoutines import FindItemInList, SameString, ShowSevereError, ShowContinueError, ShowWarningError, ShowFatalError
from Constant import Units

struct HybridModelZone:
    var Name: String = ""
    var measuredTempSched: Optional[Schedule] = None
    var measuredHumRatSched: Optional[Schedule] = None
    var measuredCO2ConcSched: Optional[Schedule] = None
    var peopleActivityLevelSched: Optional[Schedule] = None
    var peopleSensibleFracSched: Optional[Schedule] = None
    var peopleRadiantFracSched: Optional[Schedule] = None
    var peopleCO2GenRateSched: Optional[Schedule] = None
    var supplyAirTempSched: Optional[Schedule] = None
    var supplyAirMassFlowRateSched: Optional[Schedule] = None
    var supplyAirHumRatSched: Optional[Schedule] = None
    var supplyAirCO2ConcSched: Optional[Schedule] = None
    var InternalThermalMassCalc_T: Bool = False     # Calculate thermal mass flag with measured temperature
    var InfiltrationCalc_T: Bool = False            # Calculate air infiltration rate flag with measured temperature
    var InfiltrationCalc_H: Bool = False            # Calculate air infiltration rate flag with measured humidity ratio
    var InfiltrationCalc_C: Bool = False            # Calculate air infiltration rate flag with measured CO2 concentration
    var PeopleCountCalc_T: Bool = False             # Calculate zone people count flag with measured temperature
    var PeopleCountCalc_H: Bool = False             # Calculate zone people count flag with measured humidity ratio
    var PeopleCountCalc_C: Bool = False             # Calculate zone people count flag with measured CO2 concentration
    var IncludeSystemSupplyParameters: Bool = False # Flag to decide whether to include system supply terms
    var measuredTempStartMonth: Int = 0
    var measuredTempStartDate: Int = 0
    var measuredTempEndMonth: Int = 0
    var measuredTempEndDate: Int = 0
    var HybridStartDayOfYear: Int = 0 # Hybrid model start date of year
    var HybridEndDayOfYear: Int = 0   # Hybrid model end date of year

struct HybridModelData(BaseGlobalStruct):
    var FlagHybridModel: Bool = False    # True if hybrid model is activated
    var FlagHybridModel_TM: Bool = False # User input IM option - True if hybrid model (thermal mass) is activated
    var FlagHybridModel_AI: Bool = False # User input IM option - True if hybrid model (air infiltration) is activated
    var FlagHybridModel_PC: Bool = False # User input IM option - True if hybrid model (people count) is activated
    var NumOfHybridModelZones: Int = 0   # Number of hybrid model zones in the model
    var CurrentModuleObject: String = "" # to assist in getting input
    var hybridModelZones: List[HybridModelZone] = List[HybridModelZone]()

    def init_constant_state(inout self, inout state: EnergyPlusData):

    def init_state(inout self, inout state: EnergyPlusData):

    def clear_state(inout self):
        self.FlagHybridModel = False
        self.FlagHybridModel_TM = False
        self.FlagHybridModel_AI = False
        self.FlagHybridModel_PC = False
        self.NumOfHybridModelZones = 0
        self.CurrentModuleObject = ""
        self.hybridModelZones = List[HybridModelZone]()

def GetHybridModelZone(inout state: EnergyPlusData):
    var lAlphaFieldBlanks: List[Bool] = List[Bool](16, False)
    var lNumericFieldBlanks: List[Bool] = List[Bool](4, False)
    var CurrentModuleObject: String = "" # to assist in getting input
    var cAlphaArgs: List[String] = List[String](16, "")   # Alpha input items for object
    var cAlphaFieldNames: List[String] = List[String](16, "")
    var cNumericFieldNames: List[String] = List[String](4, "")
    var rNumericArgs: List[Float64] = List[Float64](4, 0.0) # Numeric input items for object
    CurrentModuleObject = "HybridModel:Zone"
    state.dataHybridModel.NumOfHybridModelZones = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, CurrentModuleObject)
    if state.dataHybridModel.NumOfHybridModelZones > 0:
        state.dataHybridModel.hybridModelZones = [HybridModelZone() for _ in range(state.dataGlobal.NumOfZones)]
        var ErrorsFound: Bool = False # If errors detected in input
        var NumAlphas: Int = 0        # Number of Alphas for each GetobjectItem call
        var NumNumbers: Int = 0       # Number of Numbers for each GetobjectItem call
        var IOStatus: Int = 0
        for HybridModelNum in range(1, state.dataHybridModel.NumOfHybridModelZones + 1):
            state.dataInputProcessing.inputProcessor.getObjectItem(state,
                                                                   CurrentModuleObject,
                                                                   HybridModelNum,
                                                                   cAlphaArgs,
                                                                   &NumAlphas,
                                                                   rNumericArgs,
                                                                   &NumNumbers,
                                                                   &IOStatus,
                                                                   lNumericFieldBlanks,
                                                                   lAlphaFieldBlanks,
                                                                   cAlphaFieldNames,
                                                                   cNumericFieldNames)
            var ZonePtr: Int = FindItemInList(cAlphaArgs[1], state.dataHeatBal.Zone) # "Zone" is a 1D array, cAlphaArgs(2) is the zone name
            if ZonePtr > 0:
                var hmZone: HybridModelZone = state.dataHybridModel.hybridModelZones[ZonePtr - 1]
                hmZone.Name = cAlphaArgs[0]                                                        # Zone HybridModel name
                state.dataHybridModel.FlagHybridModel_TM = SameString(cAlphaArgs[2], "Yes") # Calculate thermal mass option
                state.dataHybridModel.FlagHybridModel_AI = SameString(cAlphaArgs[3], "Yes") # Calculate infiltration rate option
                state.dataHybridModel.FlagHybridModel_PC = SameString(cAlphaArgs[4], "Yes") # Calculate people count option
                var temperatureSched: Optional[Schedule] = GetSchedule(state, cAlphaArgs[5])
                var humidityRatioSched: Optional[Schedule] = GetSchedule(state, cAlphaArgs[6])
                var CO2ConcentrationSched: Optional[Schedule] = GetSchedule(state, cAlphaArgs[7])
                var peopleActivityLevelSched: Optional[Schedule] = GetSchedule(state, cAlphaArgs[8])
                var peopleSensibleFractionSched: Optional[Schedule] = GetSchedule(state, cAlphaArgs[9])
                var peopleRadiantFractionSched: Optional[Schedule] = GetSchedule(state, cAlphaArgs[10])
                var peopleCO2GenRateSched: Optional[Schedule] = GetSchedule(state, cAlphaArgs[11])
                var supplyAirTemperatureSched: Optional[Schedule] = GetSchedule(state, cAlphaArgs[12])
                var supplyAirMassFlowRateSched: Optional[Schedule] = GetSchedule(state, cAlphaArgs[13])
                var supplyAirHumidityRatioSched: Optional[Schedule] = GetSchedule(state, cAlphaArgs[14])
                var supplyAirCO2ConcentrationSched: Optional[Schedule] = GetSchedule(state, cAlphaArgs[15])
                hmZone.InternalThermalMassCalc_T = False
                hmZone.InfiltrationCalc_T = False
                hmZone.InfiltrationCalc_H = False
                hmZone.InfiltrationCalc_C = False
                hmZone.PeopleCountCalc_T = False
                hmZone.PeopleCountCalc_H = False
                hmZone.PeopleCountCalc_C = False
                if state.dataHybridModel.FlagHybridModel_TM:
                    if state.dataHybridModel.FlagHybridModel_AI:
                        ShowSevereError(state,
                                        f"Field \"{cAlphaFieldNames[2]} and {cAlphaFieldNames[3]}\" cannot be both set to YES.")
                        ErrorsFound = True
                    if state.dataHybridModel.FlagHybridModel_PC:
                        ShowSevereError(state,
                                        f"Field \"{cAlphaFieldNames[2]} and {cAlphaFieldNames[4]}\" cannot be both set to YES.")
                        ErrorsFound = True
                    if temperatureSched == None:
                        ShowSevereError(state, f"Measured Zone Air Temperature Schedule is not defined for: {CurrentModuleObject}")
                        ErrorsFound = True
                    else:
                        hmZone.InternalThermalMassCalc_T = True
                if state.dataHybridModel.FlagHybridModel_AI:
                    if state.dataHybridModel.FlagHybridModel_PC:
                        ShowSevereError(state,
                                        f"Field \"{cAlphaFieldNames[3]}\" and \"{cAlphaFieldNames[4]}\" cannot be both set to YES.")
                        ErrorsFound = True
                    if temperatureSched == None and humidityRatioSched == None and CO2ConcentrationSched == None:
                        ShowSevereError(state, f"No measured environmental parameter is provided for: {CurrentModuleObject}")
                        ShowContinueError(state,
                                          f"One of the field \"{cAlphaFieldNames[5]}\", \"{cAlphaFieldNames[6]}\", or {cAlphaFieldNames[7]}\" must be provided for the HybridModel:Zone.")
                        ErrorsFound = True
                    else:
                        if temperatureSched != None and not state.dataHybridModel.FlagHybridModel_TM:
                            hmZone.InfiltrationCalc_T = True
                            if humidityRatioSched != None:
                                ShowWarningError(state, f"Field \"{cAlphaFieldNames[5]}\" is provided.")
                                ShowContinueError(state, f"Field \"{cAlphaFieldNames[6]}\" will not be used.")
                            if CO2ConcentrationSched != None:
                                ShowWarningError(state, f"Field \"{cAlphaFieldNames[5]}\" is provided.")
                                ShowContinueError(state, f"Field \"{cAlphaFieldNames[7]}\" will not be used.")
                        if humidityRatioSched != None and temperatureSched == None:
                            hmZone.InfiltrationCalc_H = True
                            if CO2ConcentrationSched != None:
                                ShowWarningError(state, f"Field \"{cAlphaFieldNames[6]}\" is provided.")
                                ShowContinueError(state, f"Field \"{cAlphaFieldNames[7]}\" will not be used.")
                        if CO2ConcentrationSched != None and temperatureSched == None and humidityRatioSched == None:
                            hmZone.InfiltrationCalc_C = True
                if state.dataHybridModel.FlagHybridModel_PC:
                    if temperatureSched == None and humidityRatioSched == None and CO2ConcentrationSched == None:
                        ShowSevereError(state, f"No measured environmental parameter is provided for: {CurrentModuleObject}")
                        ShowContinueError(state,
                                          f"One of the field \"{cAlphaFieldNames[5]}\", \"{cAlphaFieldNames[6]}\", or {cAlphaFieldNames[7]}\" must be provided for the HybridModel:Zone.")
                        ErrorsFound = True
                    else:
                        if temperatureSched != None and not state.dataHybridModel.FlagHybridModel_TM:
                            hmZone.PeopleCountCalc_T = True
                            if humidityRatioSched != None:
                                ShowWarningError(state,
                                                 "The measured air humidity ratio schedule will not be used since measured air temperature is provided.")
                            if CO2ConcentrationSched != None:
                                ShowWarningError(state,
                                                 "The measured air CO2 concentration schedule will not be used since measured air temperature is provided.")
                        if humidityRatioSched != None and temperatureSched == None:
                            hmZone.PeopleCountCalc_H = True
                            if CO2ConcentrationSched != None:
                                ShowWarningError(state,
                                                 "The measured air CO2 concentration schedule will not be used since measured air humidity ratio is provided.")
                        if CO2ConcentrationSched != None and temperatureSched == None and humidityRatioSched == None:
                            hmZone.PeopleCountCalc_C = True
                if supplyAirTemperatureSched != None and supplyAirMassFlowRateSched != None and supplyAirHumidityRatioSched != None:
                    if hmZone.InfiltrationCalc_T or hmZone.PeopleCountCalc_T:
                        hmZone.IncludeSystemSupplyParameters = True
                    else:
                        ShowWarningError(state,
                                         f"Field \"{cAlphaFieldNames[12]}\", {cAlphaFieldNames[13]}, and \"{cAlphaFieldNames[14]}\" will not be used in the inverse balance equation.")
                if supplyAirHumidityRatioSched != None and supplyAirMassFlowRateSched != None:
                    if hmZone.InfiltrationCalc_H or hmZone.PeopleCountCalc_H:
                        hmZone.IncludeSystemSupplyParameters = True
                    else:
                        ShowWarningError(state,
                                         f"Field \"{cAlphaFieldNames[14]}\" and \"{cAlphaFieldNames[13]}\" will not be used in the inverse balance equation.")
                if supplyAirCO2ConcentrationSched != None and supplyAirMassFlowRateSched != None:
                    if hmZone.InfiltrationCalc_C or hmZone.PeopleCountCalc_C:
                        hmZone.IncludeSystemSupplyParameters = True
                    else:
                        ShowWarningError(state,
                                         f"Field \"{cAlphaFieldNames[15]}\" and \"{cAlphaFieldNames[13]}\" will not be used in the inverse balance equation.")
                state.dataHybridModel.FlagHybridModel = hmZone.InternalThermalMassCalc_T or hmZone.InfiltrationCalc_T or \
                                                         hmZone.InfiltrationCalc_H or hmZone.InfiltrationCalc_C or hmZone.PeopleCountCalc_T or \
                                                         hmZone.PeopleCountCalc_H or hmZone.PeopleCountCalc_C
                if hmZone.InternalThermalMassCalc_T or hmZone.InfiltrationCalc_T or hmZone.PeopleCountCalc_T:
                    hmZone.measuredTempSched = temperatureSched
                if hmZone.InfiltrationCalc_H or hmZone.PeopleCountCalc_H:
                    hmZone.measuredHumRatSched = humidityRatioSched
                if hmZone.InfiltrationCalc_C or hmZone.PeopleCountCalc_C:
                    hmZone.measuredCO2ConcSched = CO2ConcentrationSched
                if hmZone.IncludeSystemSupplyParameters:
                    hmZone.supplyAirTempSched = supplyAirTemperatureSched
                    hmZone.supplyAirMassFlowRateSched = supplyAirMassFlowRateSched
                    hmZone.supplyAirHumRatSched = supplyAirHumidityRatioSched
                    hmZone.supplyAirCO2ConcSched = supplyAirCO2ConcentrationSched
                if hmZone.PeopleCountCalc_T or hmZone.PeopleCountCalc_H or hmZone.PeopleCountCalc_C:
                    if peopleActivityLevelSched != None:
                        hmZone.peopleActivityLevelSched = peopleActivityLevelSched
                    else:
                        ShowWarningError(state,
                                         f"Field \"{cAlphaFieldNames[8]}\": default people activity level is not provided, default value of 130W/person will be used.")
                    if peopleSensibleFractionSched != None:
                        hmZone.peopleSensibleFracSched = peopleSensibleFractionSched
                    else:
                        ShowWarningError(state,
                                         f"Field \"{cAlphaFieldNames[9]}\": default people sensible heat rate is not provided, default value of 0.6 will be used.")
                    if peopleRadiantFractionSched != None:
                        hmZone.peopleRadiantFracSched = peopleRadiantFractionSched
                    else:
                        ShowWarningError(state,
                                         f"Field \"{cAlphaFieldNames[10]}\": default people radiant heat portion (of sensible heat) is not provided, default value of 0.7 will be used.")
                    if peopleCO2GenRateSched != None:
                        hmZone.peopleCO2GenRateSched = peopleCO2GenRateSched
                    else:
                        ShowWarningError(state,
                                         f"Field \"{cAlphaFieldNames[11]}\": default people CO2 generation rate is not provided, default value of 0.0000000382 kg/W will be used.")
                if state.dataHybridModel.FlagHybridModel:
                    hmZone.measuredTempStartMonth = int(rNumericArgs[0])
                    hmZone.measuredTempStartDate = int(rNumericArgs[1])
                    hmZone.measuredTempEndMonth = int(rNumericArgs[2])
                    hmZone.measuredTempEndDate = int(rNumericArgs[3])
                    var HMDayArr: List[Int] = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]
                    var HybridModelStartMonth: Int = hmZone.measuredTempStartMonth
                    var HybridModelStartDate: Int = hmZone.measuredTempStartDate
                    var HybridModelEndMonth: Int = hmZone.measuredTempEndMonth
                    var HybridModelEndDate: Int = hmZone.measuredTempEndDate
                    var HMStartDay: Int = 0
                    var HMEndDay: Int = 0
                    if HybridModelStartMonth >= 1 and HybridModelStartMonth <= 12:
                        HMStartDay = HMDayArr[HybridModelStartMonth - 1]
                    if HybridModelEndMonth >= 1 and HybridModelEndMonth <= 12:
                        HMEndDay = HMDayArr[HybridModelEndMonth - 1]
                    hmZone.HybridStartDayOfYear = HMStartDay + HybridModelStartDate
                    hmZone.HybridEndDayOfYear = HMEndDay + HybridModelEndDate
                if hmZone.InfiltrationCalc_T or hmZone.InfiltrationCalc_H or hmZone.InfiltrationCalc_C:
                    SetupOutputVariable(state,
                                        "Zone Infiltration Hybrid Model Air Change Rate",
                                        Units.ach,
                                        state.dataHeatBal.Zone[ZonePtr - 1].InfilOAAirChangeRateHM,
                                        TimeStepType.Zone,
                                        StoreType.Average,
                                        state.dataHeatBal.Zone[ZonePtr - 1].Name)
                    SetupOutputVariable(state,
                                        "Zone Infiltration Hybrid Model Mass Flow Rate",
                                        Units.kg_s,
                                        state.dataHeatBal.Zone[ZonePtr - 1].MCPIHM,
                                        TimeStepType.Zone,
                                        StoreType.Average,
                                        state.dataHeatBal.Zone[ZonePtr - 1].Name)
                if hmZone.PeopleCountCalc_T or hmZone.PeopleCountCalc_H or hmZone.PeopleCountCalc_C:
                    SetupOutputVariable(state,
                                        "Zone Hybrid Model People Count",
                                        Units.None,
                                        state.dataHeatBal.Zone[ZonePtr - 1].NumOccHM,
                                        TimeStepType.Zone,
                                        StoreType.Average,
                                        state.dataHeatBal.Zone[ZonePtr - 1].Name)
                if hmZone.InternalThermalMassCalc_T:
                    SetupOutputVariable(state,
                                        "Zone Hybrid Model Thermal Mass Multiplier",
                                        Units.None,
                                        state.dataHeatBal.Zone[ZonePtr - 1].ZoneVolCapMultpSensHM,
                                        TimeStepType.Zone,
                                        StoreType.Average,
                                        state.dataHeatBal.Zone[ZonePtr - 1].Name)
                if hmZone.InfiltrationCalc_T and state.dataHeatBal.ZoneAirMassFlow.EnforceZoneMassBalance:
                    state.dataHeatBal.ZoneAirMassFlow.EnforceZoneMassBalance = False
                    ShowWarningError(state, "ZoneAirMassFlowConservation is deactivated when Hybrid Modeling is performed.")
                state.dataHybridModel.hybridModelZones[ZonePtr - 1] = hmZone
            else:
                ShowSevereError(state,
                                f"{CurrentModuleObject}=\"{cAlphaArgs[0]}\" invalid {cAlphaFieldNames[1]}=\"{cAlphaArgs[1]}\" not found.")
                ErrorsFound = True
        if state.dataHybridModel.FlagHybridModel:
            for ZonePtr in range(1, state.dataGlobal.NumOfZones + 1):
                var hmZone: HybridModelZone = state.dataHybridModel.hybridModelZones[ZonePtr - 1]
                if (hmZone.InternalThermalMassCalc_T or hmZone.InfiltrationCalc_T) and \
                    (state.dataRoomAir.AirModel[ZonePtr - 1].AirModel != RoomAir.RoomAirModel.Mixing):
                    state.dataRoomAir.AirModel[ZonePtr - 1].AirModel = RoomAir.RoomAirModel.Mixing
                    ShowWarningError(state, "Room Air Model Type should be Mixing if Hybrid Modeling is performed for the zone.")
            if state.dataHeatBal.doSpaceHeatBalanceSimulation or state.dataHeatBal.doSpaceHeatBalanceSizing:
                ShowSevereError(state, "Hybrid Modeling is not supported with ZoneAirHeatBalanceAlgorithm Space Heat Balance.")
                ErrorsFound = True
        if ErrorsFound:
            ShowFatalError(state, "Errors getting Hybrid Model input data. Preceding condition(s) cause termination.")