from collections import Dict, List
from math import pi, log, exp, erfc, sqrt, fabs, pow
import json
from pathlib import Path

alias Float64 = Float64
alias Real64 = Float64

struct GFuncCalcMethod:
    alias Invalid = -1
    alias UniformHeatFlux = 0
    alias UniformBoreholeWallTemp = 1
    alias FullDesign = 2


struct BorefieldSizingData:
    var name: String
    var type: String
    var sizingPeriodName: String
    var designFlowRatePerBorehole: Float64
    var length: Float64
    var width: Float64
    var minSpacing: Float64
    var maxSpacing: Float64
    var minLength: Float64
    var maxLength: Float64
    var numBoreholes: UInt32
    var minEFT: Float64
    var maxEFT: Float64

    fn __init__(inout self):
        self.name = ""
        self.type = ""
        self.sizingPeriodName = ""
        self.designFlowRatePerBorehole = 0.0
        self.length = 0.0
        self.width = 0.0
        self.minSpacing = 0.0
        self.maxSpacing = 0.0
        self.minLength = 0.0
        self.maxLength = 0.0
        self.numBoreholes = 0
        self.minEFT = 0.0
        self.maxEFT = 0.0


struct MyCartesian:
    var x: Float64
    var y: Float64
    var z: Float64

    fn __init__(inout self, x: Float64, y: Float64, z: Float64):
        self.x = x
        self.y = y
        self.z = z


struct SoilProps:
    var k: Float64
    var rhoCp: Float64
    var diffusivity: Float64

    fn __init__(inout self):
        self.k = 0.0
        self.rhoCp = 0.0
        self.diffusivity = 0.0


struct PipeProps:
    var outDia: Float64
    var innerDia: Float64
    var outRadius: Float64
    var innerRadius: Float64
    var thickness: Float64
    var k: Float64
    var rhoCp: Float64

    fn __init__(inout self):
        self.outDia = 0.0
        self.innerDia = 0.0
        self.outRadius = 0.0
        self.innerRadius = 0.0
        self.thickness = 0.0
        self.k = 0.0
        self.rhoCp = 0.0


struct GroutProps:
    var k: Float64
    var rhoCp: Float64

    fn __init__(inout self):
        self.k = 0.0
        self.rhoCp = 0.0


struct RespFactorProps:
    var bhDiameter: Float64
    var bhLength: Float64
    var bhUTubeDist: Float64
    var bhTopDepth: Float64
    var pipe: PipeProps
    var grout: GroutProps

    fn __init__(inout self):
        self.bhDiameter = 0.0
        self.bhLength = 0.0
        self.bhUTubeDist = 0.0
        self.bhTopDepth = 0.0
        self.pipe = PipeProps()
        self.grout = GroutProps()


struct PlantLocation:
    var loopNum: Int32

    fn __init__(inout self, loopNum: Int32):
        self.loopNum = loopNum


struct EnergyPlusData:
    pass


@always_inline
fn pow_2(x: Float64) -> Float64:
    return x * x


@always_inline
fn pow_4(x: Float64) -> Float64:
    return x * x * x * x


@always_inline
fn isEven(n: Int) -> Bool:
    return n % 2 == 0


fn TDMA(a: List[Float64], b: List[Float64], c: List[Float64], d: List[Float64]) -> List[Float64]:
    let n = len(d)
    var c_prime = List[Float64](capacity=n)
    var d_prime = List[Float64](capacity=n)
    var x = List[Float64](capacity=n)

    for i in range(n):
        c_prime.append(0.0)
        d_prime.append(0.0)
        x.append(0.0)

    c_prime[0] = c[0] / b[0]
    d_prime[0] = d[0] / b[0]

    for i in range(1, n):
        var denom = b[i] - a[i] * c_prime[i - 1]
        if fabs(denom) < 1e-10:
            denom = 1e-10
        if i < n - 1:
            c_prime[i] = c[i] / denom
        else:
            c_prime[i] = 0.0
        d_prime[i] = (d[i] - a[i] * d_prime[i - 1]) / denom

    x[n - 1] = d_prime[n - 1]
    for i in range(n - 2, -1, -1):
        x[i] = d_prime[i] - c_prime[i] * x[i + 1]

    return x


struct Cell:
    var type: Int32
    var radius_center: Float64
    var radius_outer: Float64
    var radius_inner: Float64
    var thickness: Float64
    var vol: Float64
    var conductivity: Float64
    var rhoCp: Float64
    var temperature: Float64
    var temperature_prev_ts: Float64

    fn __init__(inout self):
        self.type = 0
        self.radius_center = 0.0
        self.radius_outer = 0.0
        self.radius_inner = 0.0
        self.thickness = 0.0
        self.vol = 0.0
        self.conductivity = 0.0
        self.rhoCp = 0.0
        self.temperature = 0.0
        self.temperature_prev_ts = 0.0


struct GLHEVert:
    var moduleName: String
    var name: String
    var bhDiameter: Float64
    var bhRadius: Float64
    var bhLength: Float64
    var bhUTubeDist: Float64
    var gFuncCalcMethod: Int32
    var theta_1: Float64
    var theta_2: Float64
    var theta_3: Float64
    var sigma: Float64
    var loadsDuringSizingForDesign: Dict[Float64, Float64]
    var GFNC_shortTimestep: List[Float64]
    var LNTTS_shortTimestep: List[Float64]
    var sizingData: BorefieldSizingData
    var fullDesignLoadAccrualStarted: Bool
    var fullDesignCompleted: Bool
    var inletNodeNum: Int32
    var outletNodeNum: Int32
    var designFlow: Float64
    var designMassFlow: Float64
    var available: Bool
    var on: Bool
    var soil: SoilProps
    var grout: GroutProps
    var pipe: PipeProps
    var plantLoc: PlantLocation
    var gFunctionsExist: Bool
    var totalTubeLength: Float64
    var inletTemp: Float64
    var outletTemp: Float64
    var tempGround: Float64
    var massFlowRate: Float64
    var myEnvrnFlag: Bool
    var AGG: Int32
    var SubAGG: Int32
    var QnMonthlyAgg: List[Float64]
    var QnHr: List[Float64]
    var QnSubHr: List[Float64]
    var LastHourN: List[Int32]
    var prevTimeSteps: List[Float64]
    var timeSS: Float64
    var timeSSFactor: Float64
    var lastQnSubHr: Float64
    var currentSimTime: Float64
    var QGLHE: Float64
    var prevHour: Int32
    var needToSetupOutputVars: Bool

    fn __init__(inout self):
        self.moduleName = "GroundHeatExchanger:System"
        self.name = ""
        self.bhDiameter = 0.0
        self.bhRadius = 0.0
        self.bhLength = 0.0
        self.bhUTubeDist = 0.0
        self.gFuncCalcMethod = -1
        self.theta_1 = 0.0
        self.theta_2 = 0.0
        self.theta_3 = 0.0
        self.sigma = 0.0
        self.loadsDuringSizingForDesign = Dict[Float64, Float64]()
        self.GFNC_shortTimestep = List[Float64]()
        self.LNTTS_shortTimestep = List[Float64]()
        self.sizingData = BorefieldSizingData()
        self.fullDesignLoadAccrualStarted = False
        self.fullDesignCompleted = False
        self.inletNodeNum = 0
        self.outletNodeNum = 0
        self.designFlow = 0.0
        self.designMassFlow = 0.0
        self.available = False
        self.on = False
        self.soil = SoilProps()
        self.grout = GroutProps()
        self.pipe = PipeProps()
        self.plantLoc = PlantLocation(0)
        self.gFunctionsExist = False
        self.totalTubeLength = 0.0
        self.inletTemp = 0.0
        self.outletTemp = 0.0
        self.tempGround = 0.0
        self.massFlowRate = 0.0
        self.myEnvrnFlag = False
        self.AGG = 192
        self.SubAGG = 15
        self.QnMonthlyAgg = List[Float64]()
        self.QnHr = List[Float64]()
        self.QnSubHr = List[Float64]()
        self.LastHourN = List[Int32]()
        self.prevTimeSteps = List[Float64]()
        self.timeSS = 0.0
        self.timeSSFactor = 0.0
        self.lastQnSubHr = 0.0
        self.currentSimTime = 0.0
        self.QGLHE = 0.0
        self.prevHour = 1
        self.needToSetupOutputVars = False

    fn getAnnualTimeConstant(inout self):
        let hrInYear = 8760.0
        self.timeSS = (pow_2(self.bhLength) / (9.0 * self.soil.diffusivity)) / (1.0 / 3600.0) / hrInYear
        self.timeSSFactor = self.timeSS * 8760.0

    fn combineShortAndLongTimestepGFunctions(inout self):
        var GFNC_combined = List[Float64]()
        var LNTTS_combined = List[Float64]()

        let t_s = pow_2(self.bhLength) / (9.0 * self.soil.diffusivity)

        let num_shortTimestepGFunctions = len(self.GFNC_shortTimestep)
        for index_shortTS in range(num_shortTimestepGFunctions):
            GFNC_combined.append(self.GFNC_shortTimestep[index_shortTS])
            LNTTS_combined.append(self.LNTTS_shortTimestep[index_shortTS])

        let highest_lntts_from_sts = self.LNTTS_shortTimestep[len(self.LNTTS_shortTimestep) - 1]

    fn distances(point_i: MyCartesian, point_j: MyCartesian) -> List[Float64]:
        var sumVals = List[Float64]()
        sumVals.append(pow_2(point_i.x - point_j.x))
        sumVals.append(pow_2(point_i.y - point_j.y))
        sumVals.append(pow_2(point_i.z - point_j.z))

        var sumTot = 0.0
        for val in sumVals:
            sumTot += val
        var retVals = List[Float64]()
        retVals.append(sqrt(sumTot))

        sumVals[2] = pow_2(point_i.z - (-point_j.z))
        sumTot = 0.0
        for val in sumVals:
            sumTot += val
        retVals.append(sqrt(sumTot))

        return retVals

    fn calcResponse(inout self, dists: List[Float64], currTime: Float64) -> Float64:
        let pointToPointResponse = erfc(dists[0] / (2 * sqrt(self.soil.diffusivity * currTime))) / dists[0]
        let pointToReflectedResponse = erfc(dists[1] / (2 * sqrt(self.soil.diffusivity * currTime))) / dists[1]
        return pointToPointResponse - pointToReflectedResponse

    fn getGFunc(inout self, time: Float64) -> Float64:
        let LNTTS = log(time)
        return 0.0

    fn initEnvironment(inout self):
        self.myEnvrnFlag = False
        self.lastQnSubHr = 0.0
        self.currentSimTime = 0.0
        self.QGLHE = 0.0
        self.prevHour = 1

    fn oneTimeInit_new(inout self):
        pass

    fn oneTimeInit(inout self):
        pass

    fn setupTimeVectors(inout self):
        let lntts_min_for_long_timestep = -8.5
        let t_s = pow_2(self.bhLength) / (9 * self.soil.diffusivity)
        var tempLNTTS = List[Float64]()
        tempLNTTS.append(lntts_min_for_long_timestep)

        while True:
            let maxPossibleSimTime = exp(tempLNTTS[len(tempLNTTS) - 1]) * t_s
            let numDaysInYear = 365
            if maxPossibleSimTime < 100.0 * numDaysInYear * (1.0 / 24.0) * (1.0 / 3600.0):
                let lnttsStepSize = 0.5
                tempLNTTS.append(tempLNTTS[len(tempLNTTS) - 1] + lnttsStepSize)
            else:
                break
