// Mojo translation of src/EnergyPlus/GroundHeatExchangers/Slinky.cc

from ..Data.EnergyPlusData import EnergyPlusData
from ..GroundHeatExchangers.Base import GLHEBase, GLHEResponseFactors
from ..GroundHeatExchangers.State import dataGroundHeatExchanger  // assumed
from ..BranchNodeConnections import ...
from ..NodeInputManager import Node
from ..Plant.DataPlant import DataPlant
from ..PlantUtilities import PlantUtilities
from ..UtilityRoutines import Util, ShowFatalError, ShowSevereError, ShowContinueError, DisplayString, getEnumValue
from ..GroundTemperature import GroundTemp
from ..Constants import Constant
from ..EnergyPlus import EnergyPlus, _.  // for format, etc.
from json import JSON as json  // assume json type

// Helper functions
def isEven(x: Int) -> Bool:
    return x % 2 == 0

def pow_2(x: Float64) -> Float64:
    return x * x

struct GLHESlinky(GLHEBase):
    static var moduleName: String = "GroundHeatExchanger:Slinky"
    var verticalConfig: Bool = False
    var coilDiameter: Float64 = 0.0
    var coilPitch: Float64 = 0.0
    var coilDepth: Float64 = 0.0
    var trenchDepth: Float64 = 0.0
    var trenchLength: Float64 = 0.0
    var numTrenches: Int = 0
    var trenchSpacing: Float64 = 0.0
    var numCoils: Int = 0
    var monthOfMinSurfTemp: Int = 0
    var maxSimYears: Float64 = 0.0
    var minSurfTemp: Float64 = 0.0
    var X0: List[Float64]  // 1-based index (size numCoils+1)
    var Y0: List[Float64]  // 1-based index (size numTrenches+1)
    var Z0: Float64 = 0.0

    // Additional members from base and derived:
    var myRespFactors: GLHEResponseFactors  // store by value (approximation)
    var prevTimeSteps: List[Float64]
    var SubAGG: Int = 15
    var AGG: Int = 192
    var QnMonthlyAgg: List[Float64]
    var QnHr: List[Float64]
    var QnSubHr: List[Float64]
    var LastHourN: List[Int]
    var currentSimTime: Float64 = 0.0
    var prevHour: Int = 0
    var lastQnSubHr: Float64 = 0.0
    var designMassFlow: Float64 = 0.0
    var massFlowRate: Float64 = 0.0
    var inletTemp: Float64 = 0.0
    var outletTemp: Float64 = 0.0
    var QGLHE: Float64 = 0.0
    var soil: SoilProperties
    var pipe: PipeProperties
    var plantLoc: PlantLocation
    var groundTempModel: GroundTempModel
    var myEnvrnFlag: Bool = True
    var timeSSFactor: Float64 = 0.0
    var tempGround: Float64 = 0.0
    var available: Bool = True
    var on: Bool = True
    var inletNodeNum: Int = 0
    var outletNodeNum: Int = 0
    var designFlow: Float64 = 0.0

    // Default constructor
    def __init__(inout self):

    // Constructor with arguments
    def __init__(inout self, inout state: EnergyPlusData, objName: String, j: json):
        var errorsFound: Bool = False
        self.name = objName
        var inletNodeName: String = Util.makeUPPER(j["inlet_node_name"].get[String]())
        var outletNodeName: String = Util.makeUPPER(j["outlet_node_name"].get[String]())
        self.inletNodeNum = Node.GetOnlySingleNode(state, inletNodeName, errorsFound,
            Node.ConnectionObjectType.GroundHeatExchangerSlinky, self.name, Node.FluidType.Water,
            Node.ConnectionType.Inlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
        self.outletNodeNum = Node.GetOnlySingleNode(state, outletNodeName, errorsFound,
            Node.ConnectionObjectType.GroundHeatExchangerSlinky, self.name, Node.FluidType.Water,
            Node.ConnectionType.Outlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
        self.available = True
        self.on = True
        Node.TestCompSet(state, self.moduleName, self.name, inletNodeName, outletNodeName, "Condenser Water Nodes")
        self.designFlow = j["design_flow_rate"].get[Float64]()
        PlantUtilities.RegisterPlantCompDesignFlow(state, self.inletNodeNum, self.designFlow)
        self.soil.k = j["soil_thermal_conductivity"].get[Float64]()
        self.soil.rho = j["soil_density"].get[Float64]()
        self.soil.cp = j["soil_specific_heat"].get[Float64]()
        self.soil.rhoCp = self.soil.rho * self.soil.cp
        self.pipe.k = j["pipe_thermal_conductivity"].get[Float64]()
        self.pipe.rho = j["pipe_density"].get[Float64]()
        self.pipe.cp = j["pipe_specific_heat"].get[Float64]()
        self.pipe.outDia = j["pipe_outer_diameter"].get[Float64]()
        self.pipe.outRadius = self.pipe.outDia / 2.0
        self.pipe.thickness = j["pipe_thickness"].get[Float64]()
        var hxConfig: String = Util.makeUPPER(j["heat_exchanger_configuration"].get[String]())
        if Util.SameString(hxConfig, "VERTICAL"):
            self.verticalConfig = True
        elif Util.SameString(hxConfig, "HORIZONTAL"):
            self.verticalConfig = False
        self.coilDiameter = j["coil_diameter"].get[Float64]()
        self.coilPitch = j["coil_pitch"].get[Float64]()
        self.trenchDepth = j["trench_depth"].get[Float64]()
        self.trenchLength = j["trench_length"].get[Float64]()
        self.numTrenches = j["number_of_trenches"].get[Int]()
        self.trenchSpacing = j["horizontal_spacing_between_pipes"].get[Float64]()
        self.maxSimYears = j["maximum_length_of_simulation"].get[Float64]()
        var thisRF: GLHEResponseFactors = GLHEResponseFactors()
        thisRF.name = "Response Factor Object Auto Generated No: " + str(state.dataGroundHeatExchanger.numAutoGeneratedResponseFactors + 1)
        self.myRespFactors = thisRF
        state.dataGroundHeatExchanger.responseFactorsVector.append(thisRF)
        self.numCoils = static_cast[Int](self.trenchLength / self.coilPitch)
        self.totalTubeLength = Constant.Pi * self.coilDiameter * self.trenchLength * self.numTrenches / self.coilPitch
        self.SubAGG = 15
        self.AGG = 192
        if self.verticalConfig:
            if self.trenchDepth - self.coilDiameter < 0.0:
                ShowSevereError(state, EnergyPlus.format("{}=\"{}\", invalid value in field.", self.moduleName, self.name))
                ShowContinueError(state, EnergyPlus.format("...{}=[{:.3G}].", "Trench Depth", self.trenchDepth))
                ShowContinueError(state, EnergyPlus.format("...{}=[{:.3G}].", "Coil Depth", self.coilDepth))
                ShowContinueError(state, "...Part of coil will be above ground.")
                errorsFound = True
            else:
                self.coilDepth = self.trenchDepth - (self.coilDiameter / 2.0)
        else:
            self.coilDepth = self.trenchDepth
        self.soil.diffusivity = self.soil.k / self.soil.rhoCp
        self.prevTimeSteps = List[Float64](static_cast[Int]((self.SubAGG + 1) * maxTSinHr + 1))  // allocate with size
        // Initialize all elements to 0.0
        for i in range(len(self.prevTimeSteps)):
            self.prevTimeSteps[i] = 0.0
        if self.pipe.thickness >= self.pipe.outDia / 2.0:
            ShowSevereError(state, EnergyPlus.format("{}=\"{}\", invalid value in field.", self.moduleName, self.name))
            ShowContinueError(state, EnergyPlus.format("...{}=[{:.3G}].", "Pipe Thickness", self.pipe.thickness))
            ShowContinueError(state, EnergyPlus.format("...{}=[{:.3G}].", "Pipe Outer Diameter", self.pipe.outDia))
            ShowContinueError(state, "...Radius will be <=0.")
            errorsFound = True
        var gtmType: GroundTemp.ModelType = static_cast[GroundTemp.ModelType](
            getEnumValue(GroundTemp.modelTypeNamesUC, Util.makeUPPER(j["undisturbed_ground_temperature_model_type"].get[String]())))
        assert(gtmType != GroundTemp.ModelType.Invalid)
        var gtmName: String = Util.makeUPPER(j["undisturbed_ground_temperature_model_name"].get[String]())
        self.groundTempModel = GroundTemp.GetGroundTempModelAndInit(state, gtmType, gtmName)
        if errorsFound:
            ShowFatalError(state, EnergyPlus.format("Errors found in processing input for {}", self.moduleName))

    def getAnnualTimeConstant(inout self):
        self.timeSSFactor = 1.0

    def doubleIntegral(self, m: Int, n: Int, m1: Int, n1: Int, t: Float64, I0: Int, J0: Int) -> Float64:
        var eta1: Float64 = 0.0
        var eta2: Float64 = 2 * Constant.Pi
        var g: List[Float64] = List[Float64]()
        var h: Float64 = (eta2 - eta1) / (I0 - 1)
        for i in range(I0):
            var eta: Float64 = eta1 + i * h
            g.append(self.integral(m, n, m1, n1, t, eta, J0))
        for i in range(1, len(g) - 1):
            if not isEven(i):
                g[i] = 4 * g[i]
            else:
                g[i] = 2 * g[i]
        return (h / 3) * sum(g)

    def calcGFunctions(inout self, inout state: EnergyPlusData):
        var tLg_min: Float64 = -2.0
        var tLg_grid: Float64 = 0.25
        var ts: Float64 = 3600.0
        var convertYearsToSeconds: Float64 = 356.0 * 24.0 * 60.0 * 60.0
        var fraction: Float64
        var valStored: List[List[Float64]] = List[List[Float64]]()
        var I0: Int
        var J0: Int
        DisplayString(state, "Initializing GroundHeatExchanger:Slinky: " + self.name)
        // Allocate X0 and Y0 as 1‑based lists
        self.X0 = List[Float64](self.numCoils + 1)
        self.Y0 = List[Float64](self.numTrenches + 1)
        var tLg_max: Float64 = math.log10(self.maxSimYears * convertYearsToSeconds / ts)
        var NPairs: Int = static_cast[Int]((tLg_max - tLg_min) / tLg_grid + 1)
        self.myRespFactors.GFNC = List[Float64](NPairs)
        for i in range(NPairs):
            self.myRespFactors.GFNC[i] = 0.0
        self.myRespFactors.LNTTS = List[Float64](NPairs)
        for i in range(NPairs):
            self.myRespFactors.LNTTS[i] = 0.0
        self.QnMonthlyAgg = List[Float64](static_cast[Int](self.maxSimYears * 12))
        self.QnHr = List[Float64](730 + self.AGG + self.SubAGG)
        self.QnSubHr = List[Float64](static_cast[Int]((self.SubAGG + 1) * maxTSinHr + 1))
        self.LastHourN = List[Int](self.SubAGG + 1)
        var numLC: Int = math.ceil(self.numCoils / 2.0)
        var numRC: Int = math.ceil(self.numTrenches / 2.0)
        for coil in range(1, self.numCoils + 1):
            self.X0[coil] = self.coilPitch * (coil - 1)
        for trench in range(1, self.numTrenches + 1):
            self.Y0[trench] = (trench - 1) * self.trenchSpacing
        self.Z0 = self.coilDepth
        if self.numTrenches > 1:
            fraction = 0.25
        else:
            fraction = 0.5
        for NT in range(1, NPairs + 1):
            var tLg: Float64 = tLg_min + tLg_grid * (NT - 1)
            var t: Float64 = math.pow(10.0, tLg) * ts
            var gFunc: Float64 = 0.0
            // Initialize valStored with -1.0
            valStored = List[List[Float64]](self.numTrenches + 1)
            for i in range(self.numTrenches + 1):
                valStored[i] = List[Float64](self.numCoils + 1)
                for j in range(self.numCoils + 1):
                    valStored[i][j] = -1.0
            for m1 in range(1, numRC + 1):
                for n1 in range(1, numLC + 1):
                    for m in range(1, self.numTrenches + 1):
                        for n in range(1, self.numCoils + 1):
                            var doubleIntegralVal: Float64 = 0.0
                            var midFieldVal: Float64 = 0.0
                            var disRing: Float64 = self.distToCenter(m, n, m1, n1)
                            var mm1: Int = abs(m - m1)
                            var nn1: Int = abs(n - n1)
                            if m1 == m and n1 == n:
                                I0 = 33
                                J0 = 1089
                            else:
                                I0 = 33
                                J0 = 561
                            var gFuncin: Float64
                            if disRing <= 2.5 + self.coilDiameter:
                                if valStored[mm1][nn1] < 0:
                                    doubleIntegralVal = self.doubleIntegral(m, n, m1, n1, t, I0, J0)
                                    valStored[mm1][nn1] = doubleIntegralVal
                                else:
                                    doubleIntegralVal = valStored[mm1][nn1]
                                if (!isEven(self.numTrenches) && !isEven(self.numCoils) && m1 == numRC && n1 == numLC && self.numTrenches > 1.5):
                                    gFuncin = 0.25 * doubleIntegralVal
                                elif (!isEven(self.numTrenches) && m1 == numRC && self.numTrenches > 1.5):
                                    gFuncin = 0.5 * doubleIntegralVal
                                elif (!isEven(self.numCoils) && n1 == numLC):
                                    gFuncin = 0.5 * doubleIntegralVal
                                else:
                                    gFuncin = doubleIntegralVal
                            elif disRing > (10 + self.coilDiameter):
                                gFuncin = 0.0
                            else:
                                if valStored[mm1][nn1] < 0.0:
                                    midFieldVal = self.midFieldResponseFunction(m, n, m1, n1, t)
                                    valStored[mm1][nn1] = midFieldVal
                                else:
                                    midFieldVal = valStored[mm1][nn1]
                                if (!isEven(self.numTrenches) && !isEven(self.numCoils) && m1 == numRC && n1 == numLC && self.numTrenches > 1.5):
                                    gFuncin = 0.25 * midFieldVal
                                elif (!isEven(self.numTrenches) && m1 == numRC && self.numTrenches > 1.5):
                                    gFuncin = 0.5 * midFieldVal
                                elif (!isEven(self.numCoils) && n1 == numLC):
                                    gFuncin = 0.5 * midFieldVal
                                else:
                                    gFuncin = midFieldVal
                            gFunc += gFuncin
            self.myRespFactors.GFNC[NT - 1] = (gFunc * (self.coilDiameter / 2.0)) / (4 * Constant.Pi * fraction * self.numTrenches * self.numCoils)
            self.myRespFactors.LNTTS[NT - 1] = tLg

    def nearFieldResponseFunction(self, m: Int, n: Int, m1: Int, n1: Int, eta: Float64, theta: Float64, t: Float64) -> Float64:
        var distance1: Float64 = self.distance(m, n, m1, n1, eta, theta)
        var sqrtAlphaT: Float64 = math.sqrt(self.soil.diffusivity * t)
        if not self.verticalConfig:
            var sqrtDistDepth: Float64 = math.sqrt(pow_2(distance1) + 4 * pow_2(self.coilDepth))
            var errFunc1: Float64 = math.erfc(0.5 * distance1 / sqrtAlphaT)
            var errFunc2: Float64 = math.erfc(0.5 * sqrtDistDepth / sqrtAlphaT)
            return errFunc1 / distance1 - errFunc2 / sqrtDistDepth
        var distance2: Float64 = self.distanceToFictRing(m, n, m1, n1, eta, theta)
        var errFunc1: Float64 = math.erfc(0.5 * distance1 / sqrtAlphaT)
        var errFunc2: Float64 = math.erfc(0.5 * distance2 / sqrtAlphaT)
        return errFunc1 / distance1 - errFunc2 / distance2

    def midFieldResponseFunction(self, m: Int, n: Int, m1: Int, n1: Int, t: Float64) -> Float64:
        var sqrtAlphaT: Float64 = math.sqrt(self.soil.diffusivity * t)
        var distance: Float64 = self.distToCenter(m, n, m1, n1)
        var sqrtDistDepth: Float64 = math.sqrt(pow_2(distance) + 4 * pow_2(self.coilDepth))
        var errFunc1: Float64 = math.erfc(0.5 * distance / sqrtAlphaT)
        var errFunc2: Float64 = math.erfc(0.5 * sqrtDistDepth / sqrtAlphaT)
        return 4 * pow_2(Constant.Pi) * (errFunc1 / distance - errFunc2 / sqrtDistDepth)

    def distance(self, m: Int, n: Int, m1: Int, n1: Int, eta: Float64, theta: Float64) -> Float64:
        var cos_theta: Float64 = math.cos(theta)
        var sin_theta: Float64 = math.sin(theta)
        var cos_eta: Float64 = math.cos(eta)
        var sin_eta: Float64 = math.sin(eta)
        var x: Float64 = self.X0[n] + cos_theta * (self.coilDiameter / 2.0)
        var y: Float64 = self.Y0[m] + sin_theta * (self.coilDiameter / 2.0)
        var xIn: Float64 = self.X0[n1] + cos_eta * (self.coilDiameter / 2.0 - self.pipe.outRadius)
        var yIn: Float64 = self.Y0[m1] + sin_eta * (self.coilDiameter / 2.0 - self.pipe.outRadius)
        var xOut: Float64 = self.X0[n1] + cos_eta * (self.coilDiameter / 2.0 + self.pipe.outRadius)
        var yOut: Float64 = self.Y0[m1] + sin_eta * (self.coilDiameter / 2.0 + self.pipe.outRadius)
        if not self.verticalConfig:
            return 0.5 * math.sqrt(pow_2(x - xIn) + pow_2(y - yIn)) + 0.5 * math.sqrt(pow_2(x - xOut) + pow_2(y - yOut))
        var z: Float64 = self.Z0 + sin_theta * (self.coilDiameter / 2.0)
        var zIn: Float64 = self.Z0 + sin_eta * (self.coilDiameter / 2.0 - self.pipe.outRadius)
        var zOut: Float64 = self.Z0 + sin_eta * (self.coilDiameter / 2.0 + self.pipe.outRadius)
        return 0.5 * math.sqrt(pow_2(x - xIn) + pow_2(self.Y0[m1] - self.Y0[m]) + pow_2(z - zIn)) + \
               0.5 * math.sqrt(pow_2(x - xOut) + pow_2(self.Y0[m1] - self.Y0[m]) + pow_2(z - zOut))

    def distanceToFictRing(self, m: Int, n: Int, m1: Int, n1: Int, eta: Float64, theta: Float64) -> Float64:
        var sin_theta: Float64 = math.sin(theta)
        var cos_theta: Float64 = math.cos(theta)
        var sin_eta: Float64 = math.sin(eta)
        var cos_eta: Float64 = math.cos(eta)
        var x: Float64 = self.X0[n] + cos_theta * (self.coilDiameter / 2.0)
        var z: Float64 = self.Z0 + sin_theta * (self.coilDiameter / 2.0) + 2 * self.coilDepth
        var xIn: Float64 = self.X0[n1] + cos_eta * (self.coilDiameter / 2.0 - self.pipe.outRadius)
        var zIn: Float64 = self.Z0 + sin_eta * (self.coilDiameter / 2.0 - self.pipe.outRadius)
        var xOut: Float64 = self.X0[n1] + cos_eta * (self.coilDiameter / 2.0 + self.pipe.outRadius)
        var zOut: Float64 = self.Z0 + sin_eta * (self.coilDiameter / 2.0 + self.pipe.outRadius)
        return 0.5 * math.sqrt(pow_2(x - xIn) + pow_2(self.Y0[m1] - self.Y0[m]) + pow_2(z - zIn)) + \
               0.5 * math.sqrt(pow_2(x - xOut) + pow_2(self.Y0[m1] - self.Y0[m]) + pow_2(z - zOut))

    def distToCenter(self, m: Int, n: Int, m1: Int, n1: Int) -> Float64:
        return math.sqrt(pow_2(self.X0[n] - self.X0[n1]) + pow_2(self.Y0[m] - self.Y0[m1]))

    def integral(self, m: Int, n: Int, m1: Int, n1: Int, t: Float64, eta: Float64, J0: Int) -> Float64:
        var theta: Float64 = 0.0
        var theta1: Float64 = 0.0
        var theta2: Float64 = 2 * Constant.Pi
        var f: List[Float64] = List[Float64]()
        var h: Float64 = (theta2 - theta1) / (J0 - 1)
        for j in range(J0):
            theta = theta1 + j * h
            f.append(self.nearFieldResponseFunction(m, n, m1, n1, eta, theta, t))
        for j in range(1, J0 - 1):
            if not isEven(j):
                f[j] = 4 * f[j]
            else:
                f[j] = 2 * f[j]
        return (h / 3) * sum(f)

    def calcHXResistance(inout self, inout state: EnergyPlusData) -> Float64:
        var RoutineName: String = "CalcSlinkyGroundHeatExchanger"
        var nusseltNum: Float64
        var Rconv: Float64
        const A: Float64 = 3150
        const B: Float64 = 350
        const laminarNusseltNo: Float64 = 4.364
        var cpFluid: Float64 = state.dataPlnt.PlantLoop(self.plantLoc.loopNum).glycol.getSpecificHeat(state, self.inletTemp, RoutineName)
        var kFluid: Float64 = state.dataPlnt.PlantLoop(self.plantLoc.loopNum).glycol.getConductivity(state, self.inletTemp, RoutineName)
        var fluidDensity: Float64 = state.dataPlnt.PlantLoop(self.plantLoc.loopNum).glycol.getDensity(state, self.inletTemp, RoutineName)
        var fluidViscosity: Float64 = state.dataPlnt.PlantLoop(self.plantLoc.loopNum).glycol.getViscosity(state, self.inletTemp, RoutineName)
        var singleSlinkyMassFlowRate: Float64 = self.massFlowRate / self.numTrenches
        var pipeInnerRad: Float64 = self.pipe.outRadius - self.pipe.thickness
        var pipeInnerDia: Float64 = 2.0 * pipeInnerRad
        if singleSlinkyMassFlowRate == 0.0:
            Rconv = 0.0
        else:
            var reynoldsNum: Float64 = fluidDensity * pipeInnerDia * (singleSlinkyMassFlowRate / fluidDensity / (Constant.Pi * pow_2(pipeInnerRad))) / fluidViscosity
            var prandtlNum: Float64 = (cpFluid * fluidViscosity) / kFluid
            if reynoldsNum <= 2300:
                nusseltNum = laminarNusseltNo
            elif reynoldsNum > 2300 and reynoldsNum <= 4000:
                var sf: Float64 = 0.5 + 0.5 * math.tanh((reynoldsNum - A) / B)
                var turbulentNusseltNo: Float64 = 0.023 * math.pow(reynoldsNum, 0.8) * math.pow(prandtlNum, 0.35)
                nusseltNum = laminarNusseltNo * (1 - sf) + turbulentNusseltNo * sf
            else:
                nusseltNum = 0.023 * math.pow(reynoldsNum, 0.8) * math.pow(prandtlNum, 0.35)
            var hci: Float64 = nusseltNum * kFluid / pipeInnerDia
            Rconv = 1.0 / (2.0 * Constant.Pi * pipeInnerDia * hci)
        var Rcond: Float64 = math.log(self.pipe.outRadius / pipeInnerRad) / (2.0 * Constant.Pi * self.pipe.k) / 2.0
        return Rcond + Rconv

    def getGFunc(self, time: Float64) -> Float64:
        var LNTTS: Float64 = math.log10(time)
        return self.interpGFunc(LNTTS)

    def initGLHESimVars(inout self, inout state: EnergyPlusData):
        var CurTime: Float64 = ((state.dataGlobal.DayOfSim - 1) * Constant.rHoursInDay + (state.dataGlobal.HourOfDay - 1) +
            (state.dataGlobal.TimeStep - 1) * state.dataGlobal.TimeStepZone + state.dataHVACGlobal.SysTimeElapsed) * Constant.rSecsInHour
        if self.myEnvrnFlag and state.dataGlobal.BeginEnvrnFlag:
            self.initEnvironment(state, CurTime)
        self.tempGround = self.groundTempModel.getGroundTempAtTimeInSeconds(state, self.coilDepth, CurTime)
        self.massFlowRate = PlantUtilities.RegulateCondenserCompFlowReqOp(state, self.plantLoc, self.designMassFlow)
        PlantUtilities.SetComponentFlowRate(state, self.massFlowRate, self.inletNodeNum, self.outletNodeNum, self.plantLoc)
        if not state.dataGlobal.BeginEnvrnFlag:
            self.myEnvrnFlag = True

    def initEnvironment(inout self, inout state: EnergyPlusData, CurTime: Float64):
        var RoutineName: String = "initEnvironment"
        self.myEnvrnFlag = False
        var fluidDensity: Float64 = state.dataPlnt.PlantLoop(self.plantLoc.loopNum).glycol.getDensity(state, 20.0, RoutineName)
        self.designMassFlow = self.designFlow * fluidDensity
        PlantUtilities.InitComponentNodes(state, 0.0, self.designMassFlow, self.inletNodeNum, self.outletNodeNum)
        self.lastQnSubHr = 0.0
        state.dataLoopNodes.Node(self.inletNodeNum).Temp = self.groundTempModel.getGroundTempAtTimeInSeconds(state, self.coilDepth, CurTime)
        state.dataLoopNodes.Node(self.outletNodeNum).Temp = self.groundTempModel.getGroundTempAtTimeInSeconds(state, self.coilDepth, CurTime)
        self.QnHr = List[Float64](len(self.QnHr))
        for i in range(len(self.QnHr)):
            self.QnHr[i] = 0.0
        self.QnMonthlyAgg = List[Float64](len(self.QnMonthlyAgg))
        for i in range(len(self.QnMonthlyAgg)):
            self.QnMonthlyAgg[i] = 0.0
        self.QnSubHr = List[Float64](len(self.QnSubHr))
        for i in range(len(self.QnSubHr)):
            self.QnSubHr[i] = 0.0
        self.LastHourN = List[Int](len(self.LastHourN))
        for i in range(len(self.LastHourN)):
            self.LastHourN[i] = 0
        self.prevTimeSteps = List[Float64](len(self.prevTimeSteps))
        for i in range(len(self.prevTimeSteps)):
            self.prevTimeSteps[i] = 0.0
        self.currentSimTime = 0.0
        self.QGLHE = 0.0
        self.prevHour = 1

    def oneTimeInit_new(inout self, inout state: EnergyPlusData):
        var errFlag: Bool = False
        PlantUtilities.ScanPlantLoopsForObject(state, self.name, DataPlant.PlantEquipmentType.GrndHtExchgSlinky, self.plantLoc, errFlag, _, _, _, _, _)
        if errFlag:
            ShowFatalError(state, "initGLHESimVars: Program terminated due to previous condition(s).")

    def oneTimeInit(inout self, inout state: EnergyPlusData):
