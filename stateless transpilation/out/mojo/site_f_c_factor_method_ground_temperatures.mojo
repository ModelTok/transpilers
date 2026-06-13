# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData (state): main state object with sub-containers
#   source: EnergyPlus/Data/EnergyPlusData.hh
# - state.dataWeather: contains NumDaysInYear, GroundTempsFCFromEPWHeader, wthFCGroundTemps
#   source: EnergyPlus/DataEnvironment.hh
# - state.dataEnvrn: contains GroundTempInputs array indexed by GroundTempType
#   source: EnergyPlus/DataEnvironment.hh
# - state.dataInputProcessing.inputProcessor: JSON input processor interface
#   source: EnergyPlus/InputProcessing/InputProcessor.hh
# - state.dataGrndTempModelMgr.groundTempModels: list of temperature models
#   source: GroundTemperatureModeling module
# - state.files.eio: EIO output file handle
#   source: EnergyPlus/FileSystem.hh
# - ShowSevereError, ShowFatalError: error reporting functions
#   source: EnergyPlus/UtilityRoutines.hh
# - write_ground_temps: ground temperature output writer
#   source: GroundTemperatureModeling module

from math import ceil
from collections import InlineArray


trait DataWeather:
    fn get_num_days_in_year(self) -> Int: ...
    fn get_ground_temps_fc_from_epw_header(self, month: Int) -> Float64: ...
    fn get_wth_fc_ground_temps(self) -> Bool: ...


trait DataEnvironment:
    fn get_ground_temp_inputs(self, idx: Int) -> Bool: ...
    fn set_ground_temp_inputs(self, idx: Int, value: Bool): ...


trait InputProcessor:
    fn get_num_objects_found(self, state: EnergyPlusData, objectType: String) -> Int: ...
    fn get_object_schema_props(self, state: EnergyPlusData, objectType: String) -> AnyType: ...
    fn get_real_field_value(self, fields: AnyType, schemaProps: AnyType, fieldName: String) -> Float64: ...
    fn mark_object_as_used(self, objectType: String, objectName: String): ...
    fn get_epjson(self) -> AnyType: ...


trait DataInputProcessing:
    fn get_input_processor(self) -> InputProcessor: ...


trait DataGrndTempModelMgr:
    fn append_ground_temp_model(self, model: SiteFCFactorMethodGroundTemps): ...


trait Files:
    fn get_eio(self) -> AnyType: ...


trait EnergyPlusData:
    fn get_data_weather(self) -> DataWeather: ...
    fn get_data_envrn(self) -> DataEnvironment: ...
    fn get_data_input_processing(self) -> DataInputProcessing: ...
    fn get_data_grnd_temp_model_mgr(self) -> DataGrndTempModelMgr: ...
    fn get_files(self) -> Files: ...


struct SiteFCFactorMethodGroundTemps:
    var modelType: AnyType
    var Name: String
    var timeOfSimInMonths: Int
    var fcFactorGroundTemps: InlineArray[Float64, 12]
    
    fn __init__(inout self):
        self.modelType = None
        self.Name = ""
        self.timeOfSimInMonths = 0
        self.fcFactorGroundTemps = InlineArray[Float64, 12](fill=0.0)
        self.fcFactorGroundTemps[0] = 13.0
    
    @staticmethod
    fn FCFactorGTMFactory(state: EnergyPlusData, objectName: String) -> Self:
        var numMonths: Int = 12
        var found: Bool = False
        
        var thisModel = SiteFCFactorMethodGroundTemps()
        
        var modelType: String = "SiteFCFactorMethod"
        
        var cCurrentModuleObject: String = modelType
        var currentModuleObject: String = cCurrentModuleObject
        var inputProcessor = state.get_data_input_processing().get_input_processor()
        var numCurrObjects: Int = inputProcessor.get_num_objects_found(state, currentModuleObject)
        
        thisModel.modelType = modelType
        thisModel.Name = objectName
        
        if numCurrObjects == 1:
            var groundTempsInstances = inputProcessor.get_epjson()[currentModuleObject]
            var groundTempsFields = groundTempsInstances  # simplified access
            var groundTempsSchemaProps = inputProcessor.get_object_schema_props(state, currentModuleObject)
            inputProcessor.mark_object_as_used(currentModuleObject, objectName)
            
            var fieldNames = InlineArray[StringRef, 12](fill="")
            fieldNames[0] = "january_ground_temperature"
            fieldNames[1] = "february_ground_temperature"
            fieldNames[2] = "march_ground_temperature"
            fieldNames[3] = "april_ground_temperature"
            fieldNames[4] = "may_ground_temperature"
            fieldNames[5] = "june_ground_temperature"
            fieldNames[6] = "july_ground_temperature"
            fieldNames[7] = "august_ground_temperature"
            fieldNames[8] = "september_ground_temperature"
            fieldNames[9] = "october_ground_temperature"
            fieldNames[10] = "november_ground_temperature"
            fieldNames[11] = "december_ground_temperature"
            
            for i in range(numMonths):
                thisModel.fcFactorGroundTemps[i] = inputProcessor.get_real_field_value(
                    groundTempsFields, groundTempsSchemaProps, String(fieldNames[i])
                )
            
            state.get_data_envrn().set_ground_temp_inputs(0, True)
            found = True
        
        elif numCurrObjects > 1:
            ShowSevereError(state, cCurrentModuleObject + ": Too many objects entered. Only one allowed.")
        
        elif state.get_data_weather().get_wth_fc_ground_temps():
            for i in range(1, 13):
                thisModel.fcFactorGroundTemps[i - 1] = state.get_data_weather().get_ground_temps_fc_from_epw_header(i)
            
            state.get_data_envrn().set_ground_temp_inputs(0, True)
            found = True
        
        else:
            for i in range(12):
                thisModel.fcFactorGroundTemps[i] = 0.0
            found = True
        
        if state.get_data_envrn().get_ground_temp_inputs(0):
            write_ground_temps(state.get_files().get_eio(), "FCfactorMethod", thisModel.fcFactorGroundTemps)
        
        if found:
            state.get_data_grnd_temp_model_mgr().append_ground_temp_model(thisModel)
            return thisModel
        
        ShowFatalError(state, cCurrentModuleObject + "--Errors getting input for ground temperature model")
        return thisModel
    
    fn getGroundTemp(self, state: EnergyPlusData) -> Float64:
        return self.fcFactorGroundTemps[self.timeOfSimInMonths - 1]
    
    fn getGroundTempAtTimeInSeconds(inout self, state: EnergyPlusData, depth: Float64, seconds: Float64) -> Float64:
        var secPerMonth: Float64 = (state.get_data_weather().get_num_days_in_year() as Float64) * 86400.0 / 12.0
        
        var month: Int = int(ceil(seconds / secPerMonth))
        
        if month >= 1 and month <= 12:
            self.timeOfSimInMonths = month
        else:
            self.timeOfSimInMonths = month % 12
        
        return self.getGroundTemp(state)
    
    fn getGroundTempAtTimeInMonths(inout self, state: EnergyPlusData, depth: Float64, month: Int) -> Float64:
        if month >= 1 and month <= 12:
            self.timeOfSimInMonths = month
        else:
            self.timeOfSimInMonths = month % 12
        
        return self.getGroundTemp(state)


fn ShowSevereError(state: EnergyPlusData, message: String):
    pass


fn ShowFatalError(state: EnergyPlusData, message: String):
    pass


fn write_ground_temps(eio_file: AnyType, method_name: String, temps: InlineArray[Float64, 12]):
    pass
