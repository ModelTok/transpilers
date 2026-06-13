# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state parameter with attributes:
#     - dataWeather.NumDaysInYear: int, number of days in simulation year
#     - dataGrndTempModelMgr.groundTempModels: list to append models to
#     - dataInputProcessing.inputProcessor: input processing instance
#     - Constant.Pi: float, π constant
#     - Constant.rSecsInDay: float, seconds per day (86400.0)
#     - modelTypeNames: dict mapping model type to string name
# - InputProcessor: object with methods:
#     - epJSON: dict of JSON objects
#     - getRealFieldValue(fields, schema, key): float
#     - getObjectSchemaProps(state, objectName): dict
#     - markObjectAsUsed(objectName, instanceKey): None

import math
from typing import Any, Optional


class XingGroundTempsModel:
    def __init__(self):
        self.depth: float = 0.0
        self.groundThermalDiffusivity: float = 0.0
        self.simTimeInDays: float = 0.0
        self.aveGroundTemp: float = 0.0
        self.surfTempAmplitude_1: float = 0.0
        self.phaseShift_1: float = 0.0
        self.surfTempAmplitude_2: float = 0.0
        self.phaseShift_2: float = 0.0
        self.modelType: Any = None
        self.Name: str = ""

    @staticmethod
    def XingGTMFactory(state: Any, objectName: str) -> Optional['XingGroundTempsModel']:
        found = False
        thisModel = XingGroundTempsModel()

        modelType = "Xing"

        cCurrentModuleObject = state.modelTypeNames[modelType]
        currentModuleObject = cCurrentModuleObject
        inputProcessor = state.dataInputProcessing.inputProcessor

        if currentModuleObject not in inputProcessor.epJSON:
            raise RuntimeError(f"{state.modelTypeNames[modelType]}--Errors getting input for ground temperature model")

        modelInstances = inputProcessor.epJSON[currentModuleObject]
        modelSchemaProps = inputProcessor.getObjectSchemaProps(state, currentModuleObject)

        thisModel.modelType = modelType
        thisModel.Name = objectName

        for modelName, modelFields in modelInstances.items():
            modelNameUpper = modelName.upper()

            if thisModel.Name == modelNameUpper:
                inputProcessor.markObjectAsUsed(currentModuleObject, modelName)
                thisModel.Name = modelNameUpper
                thisModel.groundThermalDiffusivity = (inputProcessor.getRealFieldValue(modelFields, modelSchemaProps, "soil_thermal_conductivity") /
                                                      (inputProcessor.getRealFieldValue(modelFields, modelSchemaProps, "soil_density") *
                                                       inputProcessor.getRealFieldValue(modelFields, modelSchemaProps, "soil_specific_heat"))) * state.Constant.rSecsInDay
                thisModel.aveGroundTemp = inputProcessor.getRealFieldValue(modelFields, modelSchemaProps, "average_soil_surface_temperature")
                thisModel.surfTempAmplitude_1 = inputProcessor.getRealFieldValue(modelFields, modelSchemaProps, "soil_surface_temperature_amplitude_1")
                thisModel.surfTempAmplitude_2 = inputProcessor.getRealFieldValue(modelFields, modelSchemaProps, "soil_surface_temperature_amplitude_2")
                thisModel.phaseShift_1 = inputProcessor.getRealFieldValue(modelFields, modelSchemaProps, "phase_shift_of_temperature_amplitude_1")
                thisModel.phaseShift_2 = inputProcessor.getRealFieldValue(modelFields, modelSchemaProps, "phase_shift_of_temperature_amplitude_2")

                found = True
                break

        if found:
            state.dataGrndTempModelMgr.groundTempModels.append(thisModel)
            return thisModel

        raise RuntimeError(f"{state.modelTypeNames[modelType]}--Errors getting input for ground temperature model")

    def getGroundTemp(self, state: Any) -> float:
        tp = state.dataWeather.NumDaysInYear

        Ts_1 = self.surfTempAmplitude_1
        PL_1 = self.phaseShift_1
        Ts_2 = self.surfTempAmplitude_2
        PL_2 = self.phaseShift_2

        n1 = 1
        gamma1 = math.sqrt((n1 * state.Constant.Pi) / (self.groundThermalDiffusivity * tp))
        exp1 = -self.depth * gamma1
        cos1 = 2 * state.Constant.Pi * n1 / tp * (self.simTimeInDays - PL_1) - self.depth * gamma1

        n2 = 2
        gamma2 = math.sqrt((n2 * state.Constant.Pi) / (self.groundThermalDiffusivity * tp))
        exp2 = -self.depth * gamma2
        cos2 = 2 * state.Constant.Pi * n2 / tp * (self.simTimeInDays - PL_2) - self.depth * gamma2

        summation = math.exp(exp1) * Ts_1 * math.cos(cos1) + math.exp(exp2) * Ts_2 * math.cos(cos2)

        return self.aveGroundTemp - summation

    def getGroundTempAtTimeInMonths(self, state: Any, _depth: float, _month: int) -> float:
        aveDaysInMonth = state.dataWeather.NumDaysInYear / 12

        self.depth = _depth

        if _month >= 1 and _month <= 12:
            self.simTimeInDays = aveDaysInMonth * (_month - 1 + 0.5)
        else:
            monthIndex = _month % 12
            self.simTimeInDays = aveDaysInMonth * (monthIndex - 1 + 0.5)

        return self.getGroundTemp(state)

    def getGroundTempAtTimeInSeconds(self, state: Any, _depth: float, seconds: float) -> float:
        self.depth = _depth

        self.simTimeInDays = seconds / state.Constant.rSecsInDay

        if self.simTimeInDays > state.dataWeather.NumDaysInYear:
            self.simTimeInDays = math.remainder(self.simTimeInDays, state.dataWeather.NumDaysInYear)

        return self.getGroundTemp(state)
