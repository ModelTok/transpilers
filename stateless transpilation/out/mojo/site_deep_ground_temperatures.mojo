from math import ceil

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object with dataInputProcessing, dataEnvrn, dataGrndTempModelMgr, dataWeather, files
# - InputProcessor: available via state.dataInputProcessing.inputProcessor
# - DataEnvironment.GroundTempType: enum with Deep variant
# - GroundTemp.modelTypeNames: array of model type names
# - ModelType: enum with SiteDeep variant
# - BaseGroundTempsModel: base class/trait
# - ShowSevereError(state, message): void function
# - ShowFatalError(state, message): void function
# - format(...): string formatting utility
# - write_ground_temps(file, label, temps): void function
# - Constant.rSecsInDay: Float64 constant for seconds in a day

struct BaseGroundTempsModel:
    pass

struct SiteDeepGroundTemps(BaseGroundTempsModel):
    var timeOfSimInMonths: Int = 12
    var deepGroundTemps: InlineArray[Float64, 12]
    var modelType: Int = 0
    var Name: String = ""
    
    fn __init__(inout self):
        self.timeOfSimInMonths = 12
        self.deepGroundTemps = InlineArray[Float64, 12](fill=13.0)
        self.modelType = 0
        self.Name = ""

fn SiteDeepGroundTemps_DeepGTMFactory(state: EnergyPlusData, objectName: String) -> SiteDeepGroundTemps:
    let num_months = 12
    var errors_found = False
    
    var this_model = SiteDeepGroundTemps()
    let model_type = ModelType.SiteDeep
    
    let c_current_module_object = GroundTemp.modelTypeNames[int(model_type)]
    let current_module_object = c_current_module_object
    let input_processor = state.dataInputProcessing.inputProcessor
    let num_curr_objects = input_processor.getNumObjectsFound(state, current_module_object)
    
    this_model.modelType = model_type
    this_model.Name = objectName
    
    if num_curr_objects == 1:
        let ground_temps_instances = input_processor.epJSON[current_module_object]
        let ground_temps_instance = ground_temps_instances.begin()
        let ground_temps_fields = ground_temps_instance.value()
        let ground_temps_schema_props = input_processor.getObjectSchemaProps(state, current_module_object)
        input_processor.markObjectAsUsed(current_module_object, ground_temps_instance.key())
        
        let field_names = InlineArray[StringRef, 12](
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
        )
        
        for i in range(num_months):
            this_model.deepGroundTemps[i] = input_processor.getRealFieldValue(
                ground_temps_fields, ground_temps_schema_props, String(field_names[i])
            )
        
        state.dataEnvrn.GroundTempInputs[int(DataEnvironment.GroundTempType.Deep)] = True
    
    elif num_curr_objects > 1:
        ShowSevereError(state, format("{}: Too many objects entered. Only one allowed.", GroundTemp.modelTypeNames[int(model_type)]))
        errors_found = True
    
    else:
        for i in range(num_months):
            this_model.deepGroundTemps[i] = 16.0
    
    write_ground_temps(state.files.eio, "Deep", this_model.deepGroundTemps)
    
    if not errors_found:
        state.dataGrndTempModelMgr.groundTempModels.append(this_model)
        return this_model
    
    ShowFatalError(state, format("{}--Errors getting input for ground temperature model", GroundTemp.modelTypeNames[int(model_type)]))
    return SiteDeepGroundTemps()

fn getGroundTemp(self: SiteDeepGroundTemps, state: EnergyPlusData) -> Float64:
    return self.deepGroundTemps[self.timeOfSimInMonths - 1]

fn getGroundTempAtTimeInSeconds(inout self: SiteDeepGroundTemps, state: EnergyPlusData, _depth: Float64, _seconds: Float64) -> Float64:
    let sec_per_month = state.dataWeather.NumDaysInYear * Constant.rSecsInDay / 12.0
    
    let month = ceil(_seconds / sec_per_month)
    
    if 1 <= month <= 12:
        self.timeOfSimInMonths = int(month)
    else:
        self.timeOfSimInMonths = int(month) % 12
    
    return getGroundTemp(self, state)

fn getGroundTempAtTimeInMonths(inout self: SiteDeepGroundTemps, state: EnergyPlusData, _depth: Float64, _month: Int) -> Float64:
    if 1 <= _month <= 12:
        self.timeOfSimInMonths = _month
    else:
        self.timeOfSimInMonths = _month % 12
    
    return getGroundTemp(self, state)
