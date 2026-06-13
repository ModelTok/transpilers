from math import pow, atan2, acos, log, sqrt, fabs, round, min, max
from collections import InlineArray

alias KIVAZONE_UNCONTROLLED = 0
alias KIVAZONE_TEMPCONTROL = 1
alias KIVAZONE_COMFORTCONTROL = 2
alias KIVAZONE_STAGEDCONTROL = 3


struct KivaWeatherData:
    var intervalsPerHour: Int
    var annualAverageDrybulbTemp: Float64
    var dryBulb: DynamicVector[Float64]
    var windSpeed: DynamicVector[Float64]
    var skyEmissivity: DynamicVector[Float64]

    fn __init__(inout self):
        self.intervalsPerHour = 0
        self.annualAverageDrybulbTemp = 0.0
        self.dryBulb = DynamicVector[Float64]()
        self.windSpeed = DynamicVector[Float64]()
        self.skyEmissivity = DynamicVector[Float64]()


struct FoundationKiva:
    var foundation: Pointer[UInt8]
    var intHIns: Pointer[UInt8]
    var intVIns: Pointer[UInt8]
    var extHIns: Pointer[UInt8]
    var extVIns: Pointer[UInt8]
    var footing: Pointer[UInt8]
    var name: String
    var surfaces: DynamicVector[Int]
    var wallConstructionIndex: Int
    var assumedIndoorTemperature: Float64

    fn __init__(inout self):
        self.foundation = Pointer[UInt8]()
        self.intHIns = Pointer[UInt8]()
        self.intVIns = Pointer[UInt8]()
        self.extHIns = Pointer[UInt8]()
        self.extVIns = Pointer[UInt8]()
        self.footing = Pointer[UInt8]()
        self.name = ""
        self.surfaces = DynamicVector[Int]()
        self.wallConstructionIndex = 0
        self.assumedIndoorTemperature = 0.0


struct KivaInstanceMap:
    var instance: Pointer[UInt8]
    var floorSurface: Int
    var wallSurfaces: DynamicVector[Int]
    var zoneNum: Int
    var zoneControlType: Int
    var zoneControlNum: Int
    var zoneAssumedTemperature: Float64
    var floorWeight: Float64
    var constructionNum: Int
    var kmPtr: Pointer[UInt8]
    var debugDir: String
    var plotNum: Int

    fn __init__(inout self, state: Pointer[UInt8], foundation: Pointer[UInt8],
                floor_surface: Int, wall_surfaces: DynamicVector[Int],
                zone_num: Int, zone_assumed_temperature: Float64,
                floor_weight: Float64, construction_num: Int,
                km_ptr: Pointer[UInt8] = Pointer[UInt8]()):
        self.instance = Pointer[UInt8]()
        self.floorSurface = floor_surface
        self.wallSurfaces = wall_surfaces
        self.zoneNum = zone_num
        self.zoneControlType = KIVAZONE_UNCONTROLLED
        self.zoneControlNum = 0
        self.zoneAssumedTemperature = zone_assumed_temperature
        self.floorWeight = floor_weight
        self.constructionNum = construction_num
        self.kmPtr = km_ptr
        self.debugDir = ""
        self.plotNum = 0

    fn initGround(inout self, state: Pointer[UInt8], kiva_weather: Pointer[KivaWeatherData]):
        pass

    fn getAccDate(inout self, state: Pointer[UInt8], num_accelerated_timesteps: Int,
                  accelerated_timestep: Int) -> Int:
        return 0

    fn setInitialBoundaryConditions(inout self, state: Pointer[UInt8],
                                    kiva_weather: Pointer[KivaWeatherData],
                                    date: Int, hour: Int, timestep: Int):
        pass

    fn setBoundaryConditions(inout self, state: Pointer[UInt8]):
        pass


struct ConvectionAlgorithms:
    var in_: Pointer[UInt8]
    var out: Pointer[UInt8]
    var f: Pointer[UInt8]

    fn __init__(inout self):
        self.in_ = Pointer[UInt8]()
        self.out = Pointer[UInt8]()
        self.f = Pointer[UInt8]()


struct Settings:
    var soilK: Float64
    var soilRho: Float64
    var soilCp: Float64
    var groundSolarAbs: Float64
    var groundThermalAbs: Float64
    var groundRoughness: Float64
    var farFieldWidth: Float64
    var deepGroundBoundary: Int
    var deepGroundDepth: Float64
    var autocalculateDeepGroundDepth: Bool
    var minCellDim: Float64
    var maxGrowthCoeff: Float64
    var timestepType: Int

    alias ZERO_FLUX = 0
    alias GROUNDWATER = 1
    alias AUTO = 2
    alias HOURLY = 0
    alias TIMESTEP = 1

    fn __init__(inout self):
        self.soilK = 0.864
        self.soilRho = 1510.0
        self.soilCp = 1260.0
        self.groundSolarAbs = 0.9
        self.groundThermalAbs = 0.9
        self.groundRoughness = 0.9
        self.farFieldWidth = 40.0
        self.deepGroundBoundary = Self.AUTO
        self.deepGroundDepth = 40.0
        self.autocalculateDeepGroundDepth = True
        self.minCellDim = 0.02
        self.maxGrowthCoeff = 1.5
        self.timestepType = Self.HOURLY


struct WallGroup:
    var exposedPerimeter: Float64
    var wallIDs: DynamicVector[Int]

    fn __init__(inout self):
        self.exposedPerimeter = 0.0
        self.wallIDs = DynamicVector[Int]()

    fn __init__(inout self, exposed_perimeter: Float64, wall_ids: DynamicVector[Int]):
        self.exposedPerimeter = exposed_perimeter
        self.wallIDs = wall_ids


struct KivaManager:
    var kivaWeather: KivaWeatherData
    var defaultFoundation: FoundationKiva
    var foundationInputs: DynamicVector[FoundationKiva]
    var kivaInstances: DynamicVector[KivaInstanceMap]
    var surfaceConvMap: Pointer[UInt8]
    var surfaceMap: Pointer[UInt8]
    var timestep: Float64
    var settings: Settings
    var defaultAdded: Bool
    var defaultIndex: Int

    fn __init__(inout self):
        self.kivaWeather = KivaWeatherData()
        self.defaultFoundation = FoundationKiva()
        self.foundationInputs = DynamicVector[FoundationKiva]()
        self.kivaInstances = DynamicVector[KivaInstanceMap]()
        self.surfaceConvMap = Pointer[UInt8]()
        self.surfaceMap = Pointer[UInt8]()
        self.timestep = 3600.0
        self.settings = Settings()
        self.defaultAdded = False
        self.defaultIndex = 0

    fn readWeatherData(inout self, state: Pointer[UInt8]):
        pass

    fn setupKivaInstances(inout self, state: Pointer[UInt8]) -> Bool:
        return False

    fn getDeepGroundDepth(self, fnd: Pointer[UInt8]) -> Float64:
        return 0.0

    fn initKivaInstances(inout self, state: Pointer[UInt8]):
        pass

    fn calcKivaInstances(inout self, state: Pointer[UInt8]):
        pass

    fn defineDefaultFoundation(inout self, state: Pointer[UInt8]):
        pass

    fn addDefaultFoundation(inout self):
        pass

    fn findFoundation(self, name: String) -> Int:
        return 0

    fn calcKivaSurfaceResults(inout self, state: Pointer[UInt8]):
        pass


fn kivaErrorCallback(message_type: Int, message: String, context_ptr: Pointer[UInt8]):
    pass
