# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state container with dataInputProcessing.inputProcessor and dataIPShortCut

from memory import UnsafePointer


struct OpticalDataModel:
    alias Invalid = -1
    alias SpectralAverage = 0
    alias Spectral = 1
    alias BSDF = 2
    alias SpectralAndAngle = 3
    alias Num = 4


struct WindowsModel:
    alias Invalid = -1
    alias BuiltIn = 0
    alias External = 1
    alias Num = 2


struct WindowsOpticalModel:
    alias Invalid = -1
    alias Simplified = 0
    alias BSDF = 1
    alias Num = 2


@always_inline
fn get_optical_data_model_names_0() -> StringSlice:
    return "SpectralAverage"

@always_inline
fn get_optical_data_model_names_1() -> StringSlice:
    return "Spectral"

@always_inline
fn get_optical_data_model_names_2() -> StringSlice:
    return "BSDF"

@always_inline
fn get_optical_data_model_names_3() -> StringSlice:
    return "SpectralAndAngle"


@always_inline
fn get_optical_data_model_names_uc_0() -> StringSlice:
    return "SPECTRALAVERAGE"

@always_inline
fn get_optical_data_model_names_uc_1() -> StringSlice:
    return "SPECTRAL"

@always_inline
fn get_optical_data_model_names_uc_2() -> StringSlice:
    return "BSDF"

@always_inline
fn get_optical_data_model_names_uc_3() -> StringSlice:
    return "SPECTRALANDANGLE"


@always_inline
fn get_windows_model_names_uc_0() -> StringSlice:
    return "BUILTINWINDOWSMODEL"

@always_inline
fn get_windows_model_names_uc_1() -> StringSlice:
    return "EXTERNALWINDOWSMODEL"


@always_inline
fn get_enum_value(names_0: StringSlice, names_1: StringSlice, value: StringSlice) -> Int32:
    if value == names_0:
        return 0
    elif value == names_1:
        return 1
    else:
        return -1


struct InputProcessor:
    pass


struct DataIPShortCut:
    pass


struct DataInputProcessing:
    pass


struct EnergyPlusData:
    pass


struct CWindowModel:
    var m_model: Int32
    
    fn __init__(inout self):
        self.m_model = WindowsModel.BuiltIn
    
    fn get_windows_model(self) -> Int32:
        return self.m_model
    
    fn is_external_library_model(self) -> Bool:
        return self.m_model == WindowsModel.External
    
    fn set_external_library_model(inout self, model: Int32):
        self.m_model = model


fn c_window_model_factory(state: EnergyPlusData, object_name: StringSlice) -> CWindowModel:
    var a_model = CWindowModel()
    var num_curr_models = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, object_name)
    
    if num_curr_models > 0:
        var num_nums: Int32 = 0
        var num_alphas: Int32 = 0
        var io_stat: Int32 = 0
        state.dataInputProcessing.inputProcessor.getObjectItem(
            state,
            object_name,
            1,
            state.dataIPShortCut.cAlphaArgs,
            num_alphas,
            state.dataIPShortCut.rNumericArgs,
            num_nums,
            io_stat
        )
        a_model.m_model = get_enum_value(
            get_windows_model_names_uc_0(),
            get_windows_model_names_uc_1(),
            state.dataIPShortCut.cAlphaArgs[0]
        )
    
    return a_model


struct CWindowOpticalModel:
    var m_model: Int32
    
    fn __init__(inout self):
        self.m_model = WindowsOpticalModel.Simplified
    
    fn get_windows_optical_model(self) -> Int32:
        return self.m_model
    
    fn is_simplified_model(self) -> Bool:
        return self.m_model == WindowsOpticalModel.Simplified


fn c_window_optical_model_factory(state: EnergyPlusData) -> CWindowOpticalModel:
    var a_model = CWindowOpticalModel()
    var num_curr_models = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state,
        "Construction:ComplexFenestrationState"
    )
    
    if num_curr_models > 0:
        a_model.m_model = WindowsOpticalModel.BSDF
    
    return a_model
