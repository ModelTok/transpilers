# TARCOGParams.mojo
# Faithful translation from C++

# Enums
enum TARCOGLayerType(Int):
    Invalid = -1
    SPECULAR = 0
    VENETBLIND_HORIZ = 1
    WOVSHADE = 2
    PERFORATED = 3
    DIFFSHADE = 4
    BSDF = 5
    VENETBLIND_VERT = 6
    Num = 7

enum TARCOGThermalModel(Int):
    Invalid = -1
    ISO15099 = 0
    SCW = 1
    CSM = 2
    CSM_WithSDThickness = 3
    Num = 4

enum DeflectionCalculation(Int):
    Invalid = -1
    NONE = 0
    TEMPERATURE = 1
    GAP_WIDTHS = 2
    Num = 3

# Constants
let e: Float64 = 2.718281828459
let DeflectionRelaxation: Float64 = 0.005
let DeflectionMaxIterations: Int = 400
let DeflectionErrorMargin: Float64 = 0.01
let maxlay: Int = 100
let MaxGap: Int = maxlay - 1
let maxlay1: Int = maxlay + 1
let maxlay2: Int = maxlay * 2
let maxlay3: Int = maxlay2 + 1

let YES_SupportPillar: Int = 1  # Exsqueeze me?

let MMax: Int = 5
let NMax: Int = 5
let NumOfIterations: Int = 100
let NumOfTries: Int = 5
let RelaxationStart: Float64 = 0.6
let RelaxationDecrease: Float64 = 0.1
let ConvergenceTolerance: Float64 = 1e-2
let AirflowConvergenceTolerance: Float64 = 1e-2
let AirflowRelaxationParameter: Float64 = 0.9
let TemperatureQuessDiff: Float64 = 1.0
let C1_VENET_HORIZONTAL: Float64 = 0.016
let C2_VENET_HORIZONTAL: Float64 = -0.63
let C3_VENET_HORIZONTAL: Float64 = 0.53
let C4_VENET_HORIZONTAL: Float64 = 0.043
let C1_VENET_VERTICAL: Float64 = 0.041
let C2_VENET_VERTICAL: Float64 = 0.000
let C3_VENET_VERTICAL: Float64 = 0.270
let C4_VENET_VERTICAL: Float64 = 0.012
let C1_SHADE: Float64 = 0.078
let C2_SHADE: Float64 = 1.2
let C3_SHADE: Float64 = 1.0
let C4_SHADE: Float64 = 1.0

# Arrays (array equivalent)
let layerTypeNamesUC = (
    "SPECULAR",
    "VENETIANHORIZONTAL",
    "WOVEN",
    "PERFORATED",
    "OTHERSHADINGTYPE",
    "BSDF",
    "VENETIANVERTICAL"
)

let thermalModelNamesUC = (
    "ISO15099",
    "SCALEDCAVITYWIDTH",
    "CONVECTIVESCALARMODEL_NOSDTHICKNESS",
    "CONVECTIVESCALARMODEL_WITHSDTHICKNESS"
)

let deflectionCalculationNamesUC = (
    "NODEFLECTION",
    "TEMPERATUREANDPRESSUREINPUT",
    "MEASUREDDEFLECTION"
)