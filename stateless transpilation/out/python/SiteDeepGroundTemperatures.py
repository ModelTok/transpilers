from dataclasses import dataclass, field
from typing import Any, List
from math import ceil

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object with dataInputProcessing, dataEnvrn, dataGrndTempModelMgr, dataWeather, files
# - InputProcessor: available via state.dataInputProcessing.inputProcessor
# - DataEnvironment.GroundTempType: enum with Deep variant
# - GroundTemp.modelTypeNames: array/list of model type names
# - ModelType: enum with SiteDeep variant
# - BaseGroundTempsModel: base class
# - ShowSevereError(state, message): void function
# - ShowFatalError(state, message): void function
# - format(...): string formatting utility
# - write_ground_temps(file, label, temps): void function
# - Constant.rSecsInDay: float constant for seconds in a day

class BaseGroundTempsModel:
    pass

@dataclass
class SiteDeepGroundTemps(BaseGroundTempsModel):
    timeOfSimInMonths: int = 12
    deepGroundTemps: List[float] = field(default_factory=lambda: [13.0] * 12)
    modelType: Any = None
    Name: str = ""
    
    @staticmethod
    def DeepGTMFactory(state: Any, objectName: str) -> 'SiteDeepGroundTemps':
        num_months = 12
        errors_found = False
        
        this_model = SiteDeepGroundTemps()
        model_type = ModelType.SiteDeep
        
        c_current_module_object = GroundTemp.modelTypeNames[int(model_type)]
        current_module_object = str(c_current_module_object)
        input_processor = state.dataInputProcessing.inputProcessor
        num_curr_objects = input_processor.getNumObjectsFound(state, current_module_object)
        
        this_model.modelType = model_type
        this_model.Name = objectName
        
        if num_curr_objects == 1:
            ground_temps_instances = input_processor.epJSON[current_module_object]
            ground_temps_instance = next(iter(ground_temps_instances.items()))
            ground_temps_fields = ground_temps_instance[1]
            ground_temps_schema_props = input_processor.getObjectSchemaProps(state, current_module_object)
            input_processor.markObjectAsUsed(current_module_object, ground_temps_instance[0])
            
            field_names = [
                "january_deep_ground_temperature",
                "february_deep_ground_temperature",
                "march_deep_ground_temperature",
                "april_deep_ground_temperature",
                "may_deep_ground_temperature",
                "june_deep_ground_temperature",
                "july_deep_ground_temperature",
                "august_deep_ground_temperature",
                "september_deep_ground_temperature",
                "october_deep_ground_temperature",
                "november_deep_ground_temperature",
                "december_deep_ground_temperature"
            ]
            
            for i in range(num_months):
                this_model.deepGroundTemps[i] = input_processor.getRealFieldValue(
                    ground_temps_fields, ground_temps_schema_props, field_names[i]
                )
            
            state.dataEnvrn.GroundTempInputs[int(DataEnvironment.GroundTempType.Deep)] = True
        
        elif num_curr_objects > 1:
            ShowSevereError(state, format("{}: Too many objects entered. Only one allowed.", GroundTemp.modelTypeNames[int(model_type)]))
            errors_found = True
        
        else:
            this_model.deepGroundTemps = [16.0] * 12
        
        write_ground_temps(state.files.eio, "Deep", this_model.deepGroundTemps)
        
        if not errors_found:
            state.dataGrndTempModelMgr.groundTempModels.append(this_model)
            return this_model
        
        ShowFatalError(state, format("{}--Errors getting input for ground temperature model", GroundTemp.modelTypeNames[int(model_type)]))
        return None
    
    def getGroundTemp(self, state: Any) -> float:
        return self.deepGroundTemps[self.timeOfSimInMonths - 1]
    
    def getGroundTempAtTimeInSeconds(self, state: Any, _depth: float, _seconds: float) -> float:
        sec_per_month = state.dataWeather.NumDaysInYear * Constant.rSecsInDay / 12
        
        month = ceil(_seconds / sec_per_month)
        
        if 1 <= month <= 12:
            self.timeOfSimInMonths = month
        else:
            self.timeOfSimInMonths = month % 12
        
        return self.getGroundTemp(state)
    
    def getGroundTempAtTimeInMonths(self, state: Any, _depth: float, _month: int) -> float:
        if 1 <= _month <= 12:
            self.timeOfSimInMonths = _month
        else:
            self.timeOfSimInMonths = _month % 12
        
        return self.getGroundTemp(state)
