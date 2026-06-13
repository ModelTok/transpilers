from ..GroundHeatExchangers.Base import GLHEBase, GFuncCalcMethod, MyCartesian
from ..Autosizing.Base import BaseSizer
from ..BranchNodeConnections import ...
from ..Data.EnergyPlusData import EnergyPlusData
from ..DataLoopNode import Node
from ..DataStringGlobals import ...
from ..DataSystemVariables import ...
from ..DisplayRoutines import DisplayString
from BoreholeArray import GLHEVertArray, BuildAndGetResponseFactorObjectFromArray
from ..GroundHeatExchangers.State import ...
from ..InputProcessing.InputProcessor import InputProcessor
from ..Plant.DataPlant import PlantLocation, DataPlant
from ..PlantUtilities import PlantUtilities
from ..WeatherManager import ...
from ..GroundTemperature import GroundTemp
from ..DataGlobals import Constant
from memory import Pointer, SharedPointer
from math import log, exp, sqrt, erfc, pow
from fmt import format as EnergyPlus_format
from os import path as fs_path
from io import open, File
from string import String, StringIO
from algorithm import accumulate, transform
from typealiases import Float64, Int, UInt

alias Real64 = Float64
alias json = Dict[String, object]

struct BorefieldSizingData:
    var name: String
    var type: String
    var sizingPeriodName: String
    var designFlowRatePerBorehole: Real64
    var length: Real64
    var width: Real64
    var minSpacing: Real64
    var maxSpacing: Real64
    var minLength: Real64
    var maxLength: Real64
    var numBoreholes: UInt
    var minEFT: Real64
    var maxEFT: Real64

    def __init__(inout self):
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

struct GLHEVert(GLHEBase):
    @staticmethod
    const moduleName: String = "GroundHeatExchanger:System"

    var bhDiameter: Real64
    var bhRadius: Real64
    var bhLength: Real64
    var bhUTubeDist: Real64
    var gFuncCalcMethod: GFuncCalcMethod
    var theta_1: Real64
    var theta_2: Real64
    var theta_3: Real64
    var sigma: Real64
    var loadsDuringSizingForDesign: Dict[Real64, Real64]
    var GFNC_shortTimestep: List[Real64]
    var LNTTS_shortTimestep: List[Real64]
    var sizingData: BorefieldSizingData

    # additional members from the class body (not in header but used)
    var needToSetupOutputVars: Bool
    var outletTemp: Real64
    var inletTemp: Real64
    var fullDesignLoadAccrualStarted: Bool
    var fullDesignCompleted: Bool
    var myRespFactors: Pointer[ResponseFactors]  # assume type ResponseFactors defined elsewhere
    var gFunctionsExist: Bool
    var soil: SoilProps  # assume SoilProps struct
    var pipe: PipeProps
    var grout: GroutProps
    var totalTubeLength: Real64
    var SubAGG: Int
    var AGG: Int
    var QnMonthlyAgg: List[Real64]
    var QnHr: List[Real64]
    var QnSubHr: List[Real64]
    var LastHourN: List[Int]
    var prevTimeSteps: List[Real64]
    var groundTempModel: GroundTempModelPtr  # need type
    var timeSS: Real64
    var timeSSFactor: Real64
    var massFlowRate: Real64
    var designMassFlow: Real64
    var currentSimTime: Real64
    var QGLHE: Real64
    var prevHour: Int
    var lastQnSubHr: Real64
    var tempGround: Real64
    var myEnvrnFlag: Bool
    var plantLoc: PlantLocation
    # ... many more from base class

    def __init__(inout self, state: EnergyPlusData, objName: String, j: json):
        for existingObj in state.dataGroundHeatExchanger.verticalGLHE:
            if objName == existingObj.name:
                ShowFatalError(state, EnergyPlus_format("Invalid input for {} object: Duplicate name found: {}", moduleName, existingObj.name))
        var errorsFound: Bool = False
        self.name = objName

        var inletNodeName: String = Util.makeUPPER(j["inlet_node_name"] as String)
        self.inletNodeNum = Node.GetOnlySingleNode(state,
            inletNodeName,
            errorsFound,
            Node.ConnectionObjectType.GroundHeatExchangerSystem,
            objName,
            Node.FluidType.Water,
            Node.ConnectionType.Inlet,
            Node.CompFluidStream.Primary,
            Node.ObjectIsNotParent)

        var outletNodeName: String = Util.makeUPPER(j["outlet_node_name"] as String)
        self.outletNodeNum = Node.GetOnlySingleNode(state,
            outletNodeName,
            errorsFound,
            Node.ConnectionObjectType.GroundHeatExchangerSystem,
            objName,
            Node.FluidType.Water,
            Node.ConnectionType.Outlet,
            Node.CompFluidStream.Primary,
            Node.ObjectIsNotParent)

        self.available = True
        self.on = True
        Node.TestCompSet(state, moduleName, objName, inletNodeName, outletNodeName, "Condenser Water Nodes")

        self.designFlow = j["design_flow_rate"] as Real64
        PlantUtilities.RegisterPlantCompDesignFlow(state, self.inletNodeNum, self.designFlow)

        self.soil.k = j["ground_thermal_conductivity"] as Real64
        self.soil.rhoCp = j["ground_thermal_heat_capacity"] as Real64

        if "ghe_vertical_responsefactors_object_name" in j:
            self.myRespFactors = GetResponseFactor(state, Util.makeUPPER(j["ghe_vertical_responsefactors_object_name"] as String))
            self.gFunctionsExist = True

        if not self.gFunctionsExist:
            if "g_function_calculation_method" in j:
                gFunctionMethodStr: String = Util.makeUPPER(j["g_function_calculation_method"] as String)
                if gFunctionMethodStr == "UHFCALC":
                    self.gFuncCalcMethod = GFuncCalcMethod.UniformHeatFlux
                elif gFunctionMethodStr == "UBHWTCALC":
                    self.gFuncCalcMethod = GFuncCalcMethod.UniformBoreholeWallTemp
                elif gFunctionMethodStr == "FULLDESIGN":
                    self.gFuncCalcMethod = GFuncCalcMethod.FullDesign
                else:
                    errorsFound = True
                    ShowSevereError(state, EnergyPlus_format("g-Function Calculation Method: \"{}\" is invalid", gFunctionMethodStr))

            if self.gFuncCalcMethod == GFuncCalcMethod.FullDesign:
                # #ifndef PYTHON_CLI
                ShowFatalError(state, "Attempted to use borehole field design in a build without PYTHON_CLI, which is invalid")
                # #endif
                var foundSizing: Bool = False
                var objTypeFound: Bool = "ghe_vertical_sizing_object_type" in j
                var objNameFound: Bool = "ghe_vertical_sizing_object_name" in j
                if not objTypeFound:
                    ShowSevereError(state, EnergyPlus_format("GroundHeatExchanger:System \"{}\"", self.name))
                    ShowContinueError(state, EnergyPlus_format("g-Function Calculation Method = \"{}\"", j["g_function_calculation_method"] as String))
                    ShowContinueError(state, "GHE:Vertical:Sizing Object Type not specified.")
                    errorsFound = True
                if not objNameFound:
                    ShowSevereError(state, EnergyPlus_format("GroundHeatExchanger:System \"{}\"", self.name))
                    ShowContinueError(state, EnergyPlus_format("g-Function Calculation Method = \"{}\"", j["g_function_calculation_method"] as String))
                    ShowContinueError(state, "GHE:Vertical:Sizing Object Name not specified.")
                    errorsFound = True

                self.sizingData.name = j["ghe_vertical_sizing_object_name"] as String
                self.sizingData.type = j["ghe_vertical_sizing_object_type"] as String
                if Util.makeUPPER(self.sizingData.type) != "GROUNDHEATEXCHANGER:VERTICAL:SIZING:RECTANGLE":
                    ShowSevereError(state, EnergyPlus_format("GroundHeatExchanger:System \"{}\"", self.name))
                    ShowContinueError(state, EnergyPlus_format("GHE:Vertical:Sizing Object Type not supported \"{}\"", self.sizingData.type))
                    errorsFound = True

                var instances: json = state.dataInputProcessing.inputProcessor.epJSON.get("GroundHeatExchanger:Vertical:Sizing:Rectangle", {})
                if not instances:
                    ShowSevereError(state, EnergyPlus_format("Expected to find GroundHeatExchanger:Vertical:Sizing named {}, but it was missing", self.sizingData.name))
                    errorsFound = True
                for thisSizingObjName, fields in instances.items():
                    var objNameUC: String = Util.makeUPPER(thisSizingObjName)
                    if objNameUC == Util.makeUPPER(self.sizingData.name):
                        foundSizing = True
                        self.sizingData.sizingPeriodName = fields["sizingperiod_weatherfiledays_name"] as String
                        var spInstances: json = state.dataInputProcessing.inputProcessor.epJSON.get("SizingPeriod:WeatherFileDays", {})
                        if not spInstances:
                            ShowSevereError(state, EnergyPlus_format("Expected to find SizingPeriod:WeatherFileDays named {}, but it was missing", self.sizingData.sizingPeriodName))
                            errorsFound = True
                        var spIsAnnual: Bool = False
                        for designPeriod in state.dataWeather.RunPeriodDesignInput:
                            if Util.makeUPPER(designPeriod.title) == Util.makeUPPER(self.sizingData.sizingPeriodName) and designPeriod.totalDays == 365:
                                spIsAnnual = True
                                break
                        if not spIsAnnual:
                            ShowSevereError(state, EnergyPlus_format("SizingPeriod:WeatherFileDays named {}, must be an annual design period of 365 days", self.sizingData.sizingPeriodName))
                            errorsFound = True

                        if "design_flow_rate_per_borehole" in fields:
                            self.sizingData.designFlowRatePerBorehole = fields["design_flow_rate_per_borehole"] as Real64
                        else:
                            state.dataInputProcessing.inputProcessor.getDefaultValue(state, self.sizingData.type, "design_flow_rate_per_borehole", self.sizingData.designFlowRatePerBorehole)

                        self.sizingData.length = fields["available_borehole_field_length"] as Real64
                        self.sizingData.width = fields["available_borehole_field_width"] as Real64
                        self.sizingData.numBoreholes = fields["maximum_number_of_boreholes"] as UInt
                        if "minimum_borehole_spacing" in fields:
                            self.sizingData.minSpacing = fields["minimum_borehole_spacing"] as Real64
                        else:
                            state.dataInputProcessing.inputProcessor.getDefaultValue(state, self.sizingData.type, "minimum_borehole_spacing", self.sizingData.minSpacing)
                        if "maximum_borehole_spacing" in fields:
                            self.sizingData.maxSpacing = fields["maximum_borehole_spacing"] as Real64
                        else:
                            state.dataInputProcessing.inputProcessor.getDefaultValue(state, self.sizingData.type, "maximum_borehole_spacing", self.sizingData.maxSpacing)
                        if "minimum_borehole_vertical_length" in fields:
                            self.sizingData.minLength = fields["minimum_borehole_vertical_length"] as Real64
                        else:
                            state.dataInputProcessing.inputProcessor.getDefaultValue(state, self.sizingData.type, "minimum_borehole_vertical_length", self.sizingData.minLength)
                        if "maximum_borehole_vertical_length" in fields:
                            self.sizingData.maxLength = fields["maximum_borehole_vertical_length"] as Real64
                        else:
                            state.dataInputProcessing.inputProcessor.getDefaultValue(state, self.sizingData.type, "maximum_borehole_vertical_length", self.sizingData.maxLength)
                        if "minimum_exiting_fluid_temperature_for_sizing" in fields:
                            self.sizingData.minEFT = fields["minimum_exiting_fluid_temperature_for_sizing"] as Real64
                        else:
                            state.dataInputProcessing.inputProcessor.getDefaultValue(state, self.sizingData.type, "minimum_exiting_fluid_temperature_for_sizing", self.sizingData.minEFT)
                        if "maximum_exiting_fluid_temperature_for_sizing" in fields:
                            self.sizingData.maxEFT = fields["maximum_exiting_fluid_temperature_for_sizing"] as Real64
                        else:
                            state.dataInputProcessing.inputProcessor.getDefaultValue(state, self.sizingData.type, "maximum_exiting_fluid_temperature_for_sizing", self.sizingData.maxEFT)

                        state.dataInputProcessing.inputProcessor.markObjectAsUsed("GroundHeatExchanger:Vertical:Sizing:Rectangle", self.sizingData.name)
                        break

                if not foundSizing:
                    ShowSevereError(state, "Could not find matching GroundHeatExchanger:Vertical:Sizing:Rectangle")
                    errorsFound = True

                if "vertical_well_locations" not in j:
                    ShowSevereError(state, "For a full design GHE simulation, you must provide a GHE:Vertical:Single object")
                    ShowContinueError(state, "If you enter more than one, only the first is used to specify the borehole design")
                    ShowContinueError(state, EnergyPlus_format("Check references to these objects for GHE:System object: {}", self.name))
                    errorsFound = True

                var tempVectOfBHObjects: List[Pointer[GLHEVertSingle]] = []
                var vars: List[json] = j["vertical_well_locations"] as List[json]
                for var in vars:
                    if not var["ghe_vertical_single_object_name"]:
                        continue
                    var tempBHptr: Pointer[GLHEVertSingle] = GLHEVertSingle.GetSingleBH(state, Util.makeUPPER(var["ghe_vertical_single_object_name"] as String))
                    tempVectOfBHObjects.append(tempBHptr)
                    self.myRespFactors = BuildAndGetResponseFactorsObjectFromSingleBHs(state, tempVectOfBHObjects)
                    break

                if not self.myRespFactors:
                    ShowSevereError(state, "Something went wrong creating response factor for GroundHeatExchanger, check previous errors.")
                    errorsFound = True

            elif "ghe_vertical_array_object_name" in j:
                self.myRespFactors = BuildAndGetResponseFactorObjectFromArray(state, GLHEVertArray.GetVertArray(state, Util.makeUPPER(j["ghe_vertical_array_object_name"] as String)))
            else:
                if "vertical_well_locations" not in j:
                    ShowSevereError(state, "No GHE:ResponseFactors, GHE:Vertical:Array, or GHE:Vertical:Single objects found")
                    ShowContinueError(state, EnergyPlus_format("Check references to these objects for GHE:System object: {}", self.name))
                    errorsFound = True
                var vars: List[json] = j["vertical_well_locations"] as List[json]
                var tempVectOfBHObjects: List[Pointer[GLHEVertSingle]] = []
                for var in vars:
                    if not var["ghe_vertical_single_object_name"]:
                        break
                    var tempBHptr: Pointer[GLHEVertSingle] = GLHEVertSingle.GetSingleBH(state, Util.makeUPPER(var["ghe_vertical_single_object_name"] as String))
                    tempVectOfBHObjects.append(tempBHptr)
                self.myRespFactors = BuildAndGetResponseFactorsObjectFromSingleBHs(state, tempVectOfBHObjects)
                if not self.myRespFactors:
                    ShowSevereError(state, "GroundHeatExchanger:Vertical:Single objects not found.")
                    errorsFound = True

        self.bhDiameter = self.myRespFactors.props.bhDiameter
        self.bhRadius = self.bhDiameter / 2.0
        self.bhLength = self.myRespFactors.props.bhLength
        self.bhUTubeDist = self.myRespFactors.props.bhUTubeDist

        self.pipe.outDia = self.myRespFactors.props.pipe.outDia
        self.pipe.innerDia = self.myRespFactors.props.pipe.innerDia
        self.pipe.outRadius = self.pipe.outDia / 2
        self.pipe.innerRadius = self.pipe.innerDia / 2
        self.pipe.thickness = self.myRespFactors.props.pipe.thickness
        self.pipe.k = self.myRespFactors.props.pipe.k
        self.pipe.rhoCp = self.myRespFactors.props.pipe.rhoCp
        self.grout.k = self.myRespFactors.props.grout.k
        self.grout.rhoCp = self.myRespFactors.props.grout.rhoCp

        self.myRespFactors.gRefRatio = self.bhRadius / self.bhLength
        self.myRespFactors.maxSimYears = state.dataEnvrn.MaxNumberSimYears
        self.totalTubeLength = self.myRespFactors.numBoreholes * self.myRespFactors.props.bhLength
        self.soil.diffusivity = self.soil.k / self.soil.rhoCp

        self.theta_1 = self.bhUTubeDist / (2 * self.bhRadius)
        self.theta_2 = self.bhRadius / self.pipe.outRadius
        self.theta_3 = 1 / (2 * self.theta_1 * self.theta_2)
        self.sigma = (self.grout.k - self.soil.k) / (self.grout.k + self.soil.k)

        self.SubAGG = 15
        self.AGG = 192
        self.QnMonthlyAgg = List[Real64](size = Int(self.myRespFactors.maxSimYears * 12), fill = 0.0)
        self.QnHr = List[Real64](size = 730 + self.AGG + self.SubAGG, fill = 0.0)
        self.QnSubHr = List[Real64](size = Int((self.SubAGG + 1) * maxTSinHr + 1), fill = 0.0)
        self.LastHourN = List[Int](size = self.SubAGG + 1, fill = 0)
        self.prevTimeSteps = List[Real64](size = Int((self.SubAGG + 1) * maxTSinHr + 1), fill = 0.0)

        var modelType: GroundTemp.ModelType = static_cast[GroundTemp.ModelType](getEnumValue(GroundTemp.modelTypeNamesUC, Util.makeUPPER(j["undisturbed_ground_temperature_model_type"] as String)))
        assert modelType != GroundTemp.ModelType.Invalid
        self.groundTempModel = GroundTemp.GetGroundTempModelAndInit(state, modelType, Util.makeUPPER(j["undisturbed_ground_temperature_model_name"] as String))

        if errorsFound:
            ShowFatalError(state, EnergyPlus_format("Errors found in processing input for {}", moduleName))

    def simulate(inout self, state: EnergyPlusData, calledFromLocation: PlantLocation, FirstHVACIteration: Bool, CurLoad: Real64, RunFlag: Bool):
        if self.needToSetupOutputVars:
            self.setupOutput(state)
            self.needToSetupOutputVars = False
        self.initGLHESimVars(state)
        if state.dataGlobal.KickOffSimulation:
            return
        if self.gFuncCalcMethod == GFuncCalcMethod.FullDesign:
            self.outletTemp = self.tempGround
            self.inletTemp = state.dataLoopNodes.Node[self.inletNodeNum].Temp
            if self.fullDesignCompleted:

            elif not state.dataGlobal.WarmupFlag:
                if self.fullDesignLoadAccrualStarted:
                    if state.dataGlobal.DoingHVACSizingSimulations:
                        var cpFluid: Real64 = state.dataPlnt.PlantLoop[self.plantLoc.loopNum].glycol.getSpecificHeat(state, self.inletTemp, "GLHEVert::simulate")
                        var q: Real64 = self.massFlowRate * cpFluid * (self.outletTemp - self.inletTemp)
                        var timeStamp: Real64 = (state.dataGlobal.DayOfSim - 1) * 24 + state.dataGlobal.CurrentTime
                        self.loadsDuringSizingForDesign[timeStamp] = q
                    else:
                        self.fullDesignCompleted = True
                        if len(self.loadsDuringSizingForDesign) % 8760 != 0:
                            ShowFatalError(state, "Bad number of load values found when trying to accumulate ghe loads for design")
                        var timeStepValues: List[Real64] = List[Real64](reserve = len(self.loadsDuringSizingForDesign))
                        for kv in self.loadsDuringSizingForDesign.items():
                            timeStepValues.append(kv[1])
                        var hourlyValues: List[Real64] = List[Real64](reserve = 8760)
                        var numPerHour: UInt = len(timeStepValues) // 8760
                        var i: Int = 0
                        while i < len(timeStepValues):
                            var sum: Real64 = 0.0
                            for j in range(i, i + numPerHour):
                                sum += timeStepValues[j]
                            hourlyValues.append(sum / Float64(numPerHour))
                            i += numPerHour
                        self.performBoreholeFieldDesignAndSizingWithGHEDesigner(state, hourlyValues)
                else:
                    if state.dataGlobal.DoingHVACSizingSimulations:
                        self.fullDesignLoadAccrualStarted = True
                        var cpFluid: Real64 = state.dataPlnt.PlantLoop[self.plantLoc.loopNum].glycol.getSpecificHeat(state, self.inletTemp, "GLHEVert::simulate")
                        var q: Real64 = self.massFlowRate * cpFluid * (self.outletTemp - self.inletTemp)
                        var timeStamp: Real64 = (state.dataGlobal.DayOfSim - 1) * 24 + state.dataGlobal.CurrentTime
                        self.loadsDuringSizingForDesign[timeStamp] = q
                    else:

            if self.fullDesignCompleted:
                self.calcGroundHeatExchanger(state)
        else:
            self.calcGroundHeatExchanger(state)
        self.updateGHX(state)

    def getAnnualTimeConstant(inout self):
        const hrInYear: Real64 = 8760
        self.timeSS = (pow_2(self.bhLength) / (9.0 * self.soil.diffusivity)) / Constant.rSecsInHour / hrInYear
        self.timeSSFactor = self.timeSS * 8760.0

    def combineShortAndLongTimestepGFunctions(inout self):
        var GFNC_combined: List[Real64] = List[Real64]()
        var LNTTS_combined: List[Real64] = List[Real64]()
        var t_s: Real64 = pow_2(self.bhLength) / (9.0 * self.soil.diffusivity)
        var num_shortTimestepGFunctions: UInt = len(self.GFNC_shortTimestep)
        for index_shortTS in range(num_shortTimestepGFunctions):
            GFNC_combined.append(self.GFNC_shortTimestep[index_shortTS])
            LNTTS_combined.append(self.LNTTS_shortTimestep[index_shortTS])
        var highest_lntts_from_sts: Real64 = self.LNTTS_shortTimestep[-1]
        for index_longTS in range(len(self.myRespFactors.GFNC)):
            if self.myRespFactors.LNTTS[index_longTS] <= highest_lntts_from_sts:
                continue
            GFNC_combined.append(self.myRespFactors.GFNC[index_longTS])
            LNTTS_combined.append(self.myRespFactors.LNTTS[index_longTS])
        self.myRespFactors.time = LNTTS_combined
        for i in range(len(self.myRespFactors.time)):
            self.myRespFactors.time[i] = exp(self.myRespFactors.time[i]) * t_s
        self.myRespFactors.LNTTS = LNTTS_combined
        self.myRespFactors.GFNC = GFNC_combined

    @staticmethod
    def distances(point_i: MyCartesian, point_j: MyCartesian) -> List[Real64]:
        var sumVals: List[Real64] = List[Real64]()
        sumVals.append(pow_2(point_i.x - point_j.x))
        sumVals.append(pow_2(point_i.y - point_j.y))
        sumVals.append(pow_2(point_i.z - point_j.z))
        var sumTot: Real64 = 0.0
        var retVals: List[Real64] = List[Real64]()
        for n in sumVals:
            sumTot += n
        retVals.append(sqrt(sumTot))
        sumVals.pop()
        sumVals.append(pow_2(point_i.z - (-point_j.z)))
        sumTot = 0.0
        for n in sumVals:
            sumTot += n
        retVals.append(sqrt(sumTot))
        return retVals

    def calcResponse(self, dists: List[Real64], currTime: Real64) -> Real64:
        var pointToPointResponse: Real64 = erfc(dists[0] / (2 * sqrt(self.soil.diffusivity * currTime))) / dists[0]
        var pointToReflectedResponse: Real64 = erfc(dists[1] / (2 * sqrt(self.soil.diffusivity * currTime))) / dists[1]
        return pointToPointResponse - pointToReflectedResponse

    def integral(self, point_i: MyCartesian, bh_j: Pointer[GLHEVertSingle], currTime: Real64) -> Real64:
        var sum_f: Real64 = 0.0
        var i: Int = 0
        var lastIndex_j: Int = Int(len(bh_j.pointLocations_j) - 1)
        for point_j in bh_j.pointLocations_j:
            var dists: List[Real64] = self.distances(point_i, point_j)
            var f: Real64 = self.calcResponse(dists, currTime)
            if i == 0 or i == lastIndex_j:
                sum_f += f
            elif i % 2 == 0:
                sum_f += 2 * f
            else:
                sum_f += 4 * f
            i += 1
        return (bh_j.dl_j / 3.0) * sum_f

    def doubleIntegral(self, bh_i: Pointer[GLHEVertSingle], bh_j: Pointer[GLHEVertSingle], currTime: Real64) -> Real64:
        if bh_i == bh_j:
            var sum_f: Real64 = 0.0
            var i: Int = 0
            var lastIndex: Int = Int(len(bh_i.pointLocations_ii) - 1)
            for thisPoint in bh_i.pointLocations_ii:
                var f: Real64 = self.integral(thisPoint, bh_j, currTime)
                if i == 0 or i == lastIndex:
                    sum_f += f
                elif i % 2 == 0:
                    sum_f += 2 * f
                else:
                    sum_f += 4 * f
                i += 1
            return (bh_i.dl_ii / 3.0) * sum_f
        else:
            var sum_f: Real64 = 0.0
            var i: Int = 0
            var lastIndex: Int = Int(len(bh_i.pointLocations_i) - 1)
            for thisPoint in bh_i.pointLocations_i:
                var f: Real64 = self.integral(thisPoint, bh_j, currTime)
                if i == 0 or i == lastIndex:
                    sum_f += f
                elif i % 2 == 0:
                    sum_f += 2 * f
                else:
                    sum_f += 4 * f
                i += 1
            return (bh_i.dl_i / 3.0) * sum_f

    def calcLongTimestepGFunctions(self, state: EnergyPlusData):
        var switchVal: GFuncCalcMethod = self.gFuncCalcMethod
        if switchVal == GFuncCalcMethod.UniformHeatFlux:
            self.calcUniformHeatFluxGFunctions(state)
        elif switchVal == GFuncCalcMethod.UniformBoreholeWallTemp:
            self.calcUniformBHWallTempGFunctionsWithGHEDesigner(state)
        elif switchVal == GFuncCalcMethod.FullDesign:

        else:
            assert False

    def getCommonGHEDesignerInputs(self, state: EnergyPlusData) -> json:
        var gheDesignerInputs: json = {}
        gheDesignerInputs["version"] = 2
        gheDesignerInputs["topology"] = [{"type": "ground_heat_exchanger", "name": "ghe1"}]
        var p: String = EnergyPlus_format("[G-Function Calculation for GHE Named: {}] ", self.name)
        var fluidObject: json = {}
        if state.dataPlnt.PlantLoop[self.plantLoc.loopNum].FluidName == "WATER":
            gheDesignerInputs["fluid"] = {"fluid_name": "WATER", "concentration_percent": 0, "temperature": 20}
        elif state.dataPlnt.PlantLoop[self.plantLoc.loopNum].FluidName == "STEAM":
            ShowFatalError(state, p + "Detected steam loop, but GHEDesigner cannot run for a steam fluid loop, aborting.")
        else:
            var thisGlycol = state.dataPlnt.PlantLoop[self.plantLoc.loopNum].glycol
            var n: String = thisGlycol.GlycolName
            if n == "WATER" or n == "ETHYLENEGLYCOL" or n == "PROPYLENEGLYCOL":
                var c: Real64 = thisGlycol.Concentration
                if c > 0.6:
                    ShowWarningMessage(state, p + "EnergyPlus fluid concentration > 60% (GHEDesigner max), reducing to 60%, continuing")
                    c = 0.6
                gheDesignerInputs["fluid"] = {"fluid_name": n, "concentration_percent": c * 100.0, "temperature": 20}
            else:
                ShowFatalError(state, p + "Could not identify glycol for setting up GHEDesigner run")
        return gheDesignerInputs

    @staticmethod
    def runGHEDesigner(state: EnergyPlusData, inputs: json) -> fs_path:
        var ghe_designer_input_file_path = state.dataStrGlobals.outDirPath / "eplus_ghedesigner_input.json"
        var ghe_designer_output_directory = state.dataStrGlobals.outDirPath / "eplus_ghedesigner_outputs"
        try:
            if fs_path.exists(ghe_designer_input_file_path):
                var ec: String = ""
                if not fs_path.remove(ghe_designer_input_file_path):
                    if ec:
                        ShowFatalError(state, "Failed to remove existing GHEDesigner input: " + ec)
                    ShowFatalError(state, "Path exists but is not a removable file.")
            var ghe_designer_input_file = open(ghe_designer_input_file_path, mode = "w")
            if not ghe_designer_input_file:
                ShowFatalError(state, "Failed to create file: " + str(ghe_designer_input_file_path))
            if not ghe_designer_input_file.is_open():
                ShowFatalError(state, "Failed to open output file")
            ghe_designer_input_file.write(str(inputs))
            ghe_designer_input_file.close()
        except:
            ShowFatalError(state, "Filesystem error")
        DisplayString(state, "Starting up GHEDesigner")
        var exePath: fs_path
        if state.dataGlobal.installRootOverride:
            exePath = state.dataStrGlobals.exeDirectoryPath / "energyplus"
        else:
            exePath = FileSystem.getAbsolutePath(FileSystem.getProgramPath())
            exePath = exePath.parent_path() / ("energyplus" + FileSystem.exeExtension)
        var cmd: String = EnergyPlus_format("\"{}\" auxiliary ghedesigner \"{}\" \"{}\"",
            FileSystem.toString(exePath),
            FileSystem.toGenericString(ghe_designer_input_file_path),
            FileSystem.toGenericString(ghe_designer_output_directory))
        var status: Int = FileSystem.systemCall(cmd)
        if status != 0:
            ShowFatalError(state, "GHEDesigner failed to calculate G-functions.")
        DisplayString(state, "GHEDesigner complete")
        return ghe_designer_output_directory

    def performBoreholeFieldDesignAndSizingWithGHEDesigner(self, state: EnergyPlusData, hourlyLoads: List[Real64]):
        var gheDesignerInputs: json = self.getCommonGHEDesignerInputs(state)
        var grout: json = {"conductivity": self.grout.k, "rho_cp": self.grout.rhoCp}
        var soil: json = {
            "conductivity": self.soil.k,
            "rho_cp": self.soil.rhoCp,
            "undisturbed_temp": self.tempGround
        }
        var shankSpacingForGHEDesigner: Real64 = self.bhUTubeDist - self.pipe.outDia
        var pipe: json = {
            "inner_diameter": self.pipe.innerDia,
            "outer_diameter": self.pipe.outDia,
            "shank_spacing": shankSpacingForGHEDesigner,
            "roughness": 0.000001,
            "conductivity": self.pipe.k,
            "rho_cp": self.pipe.rhoCp,
            "arrangement": "SINGLEUTUBE"
        }
        var borehole: json = {
            "buried_depth": self.myRespFactors.props.bhTopDepth,
            "diameter": self.bhDiameter
        }
        var geometricConstraints: json = {
            "length": self.sizingData.length,
            "width": self.sizingData.width,
            "b_min": self.sizingData.minSpacing,
            "b_max": self.sizingData.maxSpacing,
            "method": "RECTANGLE"
        }
        var design: json = {
            "max_eft": self.sizingData.maxEFT,
            "min_eft": self.sizingData.minEFT,
            "max_height": self.sizingData.maxLength,
            "min_height": self.sizingData.minLength,
            "max_boreholes": self.sizingData.numBoreholes
        }
        var loads: json = {}
        loads["load_values"] = hourlyLoads
        var ghe1: json = {
            "flow_rate": self.sizingData.designFlowRatePerBorehole * 1000,
            "flow_type": "BOREHOLE",
            "grout": grout,
            "soil": soil,
            "pipe": pipe,
            "borehole": borehole,
            "geometric_constraints": geometricConstraints,
            "design": design,
            "loads": loads
        }
        gheDesignerInputs["ground_heat_exchanger"] = {"ghe1": ghe1}
        gheDesignerInputs["simulation_control"] = {
            "sizing_run": False, "hourly_run": False, "sizing_months": 240
        }
        var ghe_designer_output_directory: fs_path = self.runGHEDesigner(state, gheDesignerInputs)
        var output_json_file: fs_path = ghe_designer_output_directory / "SimulationSummary.json"
        if not fs_path.exists(output_json_file):
            ShowFatalError(state, "Although GHEDesigner appeared successful, the output file was not found, aborting ")
        var output_borefield_file: fs_path = ghe_designer_output_directory / "BoreFieldData.csv"
        if not fs_path.exists(output_borefield_file):
            ShowFatalError(state, "Although GHEDesigner appeared successful, the output borefield file was not found, aborting ")
        var found_length: Real64 = 0.0
        var file = open(output_json_file, "r")
        try:
            var data: json = json.parse(file.read())  # assume json.parse
            found_length = data["ghe_system"]["active_borehole_length"]["value"] as Real64
        except:
            ShowFatalError(state, "GHEDesigner completed, and output file found, but could not parse JSON")
        file.close()

        var file2 = open(output_borefield_file, "r")
        if not file2.is_open():
            ShowFatalError(state, "Could not open file: " + str(output_borefield_file))
        var x: List[Real64] = []
        var y: List[Real64] = []
        var line: String = ""
        if not file2.readline(line):
            ShowFatalError(state, "File is empty or missing header: " + str(output_borefield_file))
        while file2.readline(line):
            if line.isempty():
                continue
            var ss: List[String] = line.split(",")
            if len(ss) < 2:
                continue
            var x1: Real64 = 0.0
            var y1: Real64 = 0.0
            try:
                x1 = Float64(ss[0])
                y1 = Float64(ss[1])
            except:
                ShowFatalError(state, "Bad data in GHEDesigner borefield results")
            x.append(x1)
            y.append(y1)
        file2.close()

        var preDesigned: json = {"arrangement": "MANUAL", "H": found_length, "x": x, "y": y}
        ghe1["pre_designed"] = preDesigned
        ghe1.erase("geometric_constraints")
        ghe1.erase("design")
        ghe1.erase("loads")
        gheDesignerInputs["ground_heat_exchanger"]["ghe1"] = ghe1
        var ghe_designer_output_directory2: fs_path = self.runGHEDesigner(state, gheDesignerInputs)
        var output_json_file2: fs_path = ghe_designer_output_directory2 / "SimulationSummary.json"
        if not fs_path.exists(output_json_file2):
            ShowFatalError(state, "Although GHEDesigner appeared successful, the output file was not found, aborting ")
        var file3 = open(output_json_file2, "r")
        try:
            var data: json = json.parse(file3.read())
            var t: List[Real64] = data["log_time"] as List[Real64]
            var g: List[Real64] = data["g_values"] as List[Real64]
            self.myRespFactors.time = t
            self.myRespFactors.LNTTS = t
            self.myRespFactors.GFNC = g
        except:
            ShowFatalError(state, "GHEDesigner completed, and output file found, but could not parse JSON")
        file3.close()

        var oss: String = ""
        for i in range(len(x)):
            oss += " (" + str(x[i]) + " " + str(y[i]) + ")"
        BaseSizer.reportSizerStrOutput(state, "GroundHeatExchanger:System", self.name, "Borehole Field Locations (x1 y1) (x2 y2) ...", oss)

    def calcUniformBHWallTempGFunctionsWithGHEDesigner(self, state: EnergyPlusData):
        var gheDesignerInputs: json = self.getCommonGHEDesignerInputs(state)
        var p: String = EnergyPlus_format("[GHEDesigner Calculation for GHE Named: {}] ", self.name)
        var bhs: List[Pointer[GLHEVertSingle]] = self.myRespFactors.myBorholes
        var reference = bhs[0]
        var allMatch: Bool = True
        for bh in bhs:
            if abs(bh.props.bhLength - reference.props.bhLength) > 0.01:
                allMatch = False
                break
        if not allMatch:
            ShowFatalError(state, p + "Multiple borehole heights in EnergyPlus inputs, g-function generation requires uniform, aborting")
        var height: Real64 = self.myRespFactors.myBorholes[0].props.bhLength
        var grout: json = {"conductivity": self.grout.k, "rho_cp": self.grout.rhoCp}
        var soil: json = {
            "conductivity": self.soil.k,
            "rho_cp": self.soil.rhoCp,
            "undisturbed_temp": self.tempGround
        }
        var shankSpacingForGHEDesigner: Real64 = self.bhUTubeDist - self.pipe.outDia
        var pipe: json = {
            "inner_diameter": self.pipe.innerDia,
            "outer_diameter": self.pipe.outDia,
            "shank_spacing": shankSpacingForGHEDesigner,
            "roughness": 0.000001,
            "conductivity": self.pipe.k,
            "rho_cp": self.pipe.rhoCp,
            "arrangement": "SINGLEUTUBE"
        }
        var borehole: json = {
            "buried_depth": self.myRespFactors.props.bhTopDepth,
            "diameter": self.bhDiameter
        }
        var x: List[Real64] = []
        var y: List[Real64] = []
        for bh in self.myRespFactors.myBorholes:
            x.append(bh.xLoc)
            y.append(bh.yLoc)
        var preDesigned: json = {"arrangement": "MANUAL", "H": height, "x": x, "y": y}
        var ghe1: json = {
            "flow_rate": self.designMassFlow,
            "flow_type": "SYSTEM",
            "grout": grout,
            "soil": soil,
            "pipe": pipe,
            "borehole": borehole,
            "pre_designed": preDesigned
        }
        gheDesignerInputs["ground_heat_exchanger"] = {"ghe1": ghe1}
        var ghe_designer_output_directory: fs_path = self.runGHEDesigner(state, gheDesignerInputs)
        var output_json_file: fs_path = ghe_designer_output_directory / "SimulationSummary.json"
        if not fs_path.exists(output_json_file):
            ShowFatalError(state, "Although GHEDesigner appeared successful, the output file was not found, aborting ")
        var file = open(output_json_file, "r")
        try:
            var data: json = json.parse(file.read())
            var t: List[Real64] = data["log_time"] as List[Real64]
            var g: List[Real64] = data["g_values"] as List[Real64]
            var gbhw: List[Real64] = data["g_bhw_values"] as List[Real64]
            self.myRespFactors.time = t
            self.myRespFactors.LNTTS = t
            self.myRespFactors.GFNC = g
        except:
            ShowFatalError(state, "GHEDesigner completed, and output file found, but could not parse JSON")
        file.close()

    def calcGFunctions(inout self, state: EnergyPlusData):
        self.setupTimeVectors()
        self.calcShortTimestepGFunctions(state)
        self.calcLongTimestepGFunctions(state)
        self.combineShortAndLongTimestepGFunctions()

    def setupTimeVectors(inout self):
        const lntts_min_for_long_timestep: Real64 = -8.5
        var t_s: Real64 = pow_2(self.bhLength) / (9 * self.soil.diffusivity)
        var tempLNTTS: List[Real64] = [lntts_min_for_long_timestep]
        while True:
            var maxPossibleSimTime: Real64 = exp(tempLNTTS[-1]) * t_s
            const numDaysInYear: Int = 365
            if maxPossibleSimTime < self.myRespFactors.maxSimYears * numDaysInYear * Constant.rHoursInDay * Constant.rSecsInHour:
                const lnttsStepSize: Real64 = 0.5
                tempLNTTS.append(tempLNTTS[-1] + lnttsStepSize)
            else:
                break
        self.myRespFactors.LNTTS = tempLNTTS
        self.myRespFactors.time = tempLNTTS
        for i in range(len(self.myRespFactors.time)):
            self.myRespFactors.time[i] = exp(self.myRespFactors.time[i]) * t_s
        self.myRespFactors.GFNC = List[Real64](size = len(tempLNTTS), fill = 0.0)

    def calcUniformHeatFluxGFunctions(self, state: EnergyPlusData):
        DisplayString(state, "Initializing GroundHeatExchanger:System: " + self.name)
        for lntts_index in range(len(self.myRespFactors.LNTTS)):
            for bh_i in self.myRespFactors.myBorholes:
                var sum_T_ji: Real64 = 0.0
                for bh_j in self.myRespFactors.myBorholes:
                    sum_T_ji += self.doubleIntegral(bh_i, bh_j, self.myRespFactors.time[lntts_index])
                self.myRespFactors.GFNC[lntts_index] += sum_T_ji
            self.myRespFactors.GFNC[lntts_index] /= (2 * self.totalTubeLength)
            var ss: String = String(format = "{:.1f}", value = Float64(lntts_index) / Float64(len(self.myRespFactors.LNTTS)) * 100.0)
            DisplayString(state, "...progress: " + ss + "%")

    def calcShortTimestepGFunctions(inout self, state: EnergyPlusData):
        const RoutineName: String = "calcShortTimestepGFunctions"
        #[CellType]
        enum CellType:
            Invalid = -1
            FLUID
            CONVECTION
            PIPE
            GROUT
            SOIL
            Num

        struct Cell:
            var type: CellType
            var radius_center: Real64
            var radius_outer: Real64
            var radius_inner: Real64
            var thickness: Real64
            var vol: Real64
            var conductivity: Real64
            var rhoCp: Real64
            var temperature: Real64
            var temperature_prev_ts: Real64

        var Cells: List[Cell] = []
        const num_pipe_cells: Int = 4
        const num_conv_cells: Int = 1
        const num_fluid_cells: Int = 3
        var pipe_thickness: Real64 = self.pipe.thickness
        var pcf_cell_thickness: Real64 = pipe_thickness / num_pipe_cells
        var radius_pipe_out: Real64 = sqrt(2) * self.pipe.outRadius
        var radius_pipe_in: Real64 = radius_pipe_out - pipe_thickness
        var radius_conv: Real64 = radius_pipe_in - num_conv_cells * pcf_cell_thickness
        var radius_fluid: Real64 = radius_conv - (num_fluid_cells - 0.5) * pcf_cell_thickness
        const num_grout_cells: Int = 27
        var radius_grout: Real64 = self.bhRadius
        var grout_cell_thickness: Real64 = (radius_grout - radius_pipe_out) / num_grout_cells
        const num_soil_cells: Int = 500
        const radius_soil: Real64 = 10.0
        var soil_cell_thickness: Real64 = (radius_soil - radius_grout) / num_soil_cells

        self.massFlowRate = self.designMassFlow
        var bhResistance: Real64 = self.calcBHAverageResistance(state)
        var bhConvectionResistance: Real64 = self.calcPipeConvectionResistance(state)
        var bh_equivalent_resistance_tube_grout: Real64 = bhResistance - bhConvectionResistance / 2.0
        var bh_equivalent_resistance_convection: Real64 = bhResistance - bh_equivalent_resistance_tube_grout
        var initial_temperature: Real64 = self.inletTemp
        var cpFluid_init: Real64 = state.dataPlnt.PlantLoop[self.plantLoc.loopNum].glycol.getSpecificHeat(state, initial_temperature, RoutineName)
        var fluidDensity_init: Real64 = state.dataPlnt.PlantLoop[self.plantLoc.loopNum].glycol.getDensity(state, initial_temperature, RoutineName)

        # FLUID cells
        for i in range(num_fluid_cells):
            var thisCell: Cell
            thisCell.type = CellType.FLUID
            thisCell.thickness = pcf_cell_thickness
            thisCell.radius_center = radius_fluid + i * thisCell.thickness
            if i == 0:
                thisCell.radius_inner = thisCell.radius_center
            else:
                thisCell.radius_inner = thisCell.radius_center - thisCell.thickness / 2.0
            thisCell.radius_outer = thisCell.radius_center + thisCell.thickness / 2.0
            thisCell.conductivity = 200
            thisCell.rhoCp = 2.0 * cpFluid_init * fluidDensity_init * pow_2(self.pipe.innerRadius) / (pow_2(radius_conv) - pow_2(radius_fluid))
            Cells.append(thisCell)

        # CONVECTION cells
        for i in range(num_conv_cells):
            var thisCell: Cell
            thisCell.thickness = pcf_cell_thickness
            thisCell.radius_inner = radius_conv + i * thisCell.thickness
            thisCell.radius_center = thisCell.radius_inner + thisCell.thickness / 2.0
            thisCell.radius_outer = thisCell.radius_inner + thisCell.thickness
            thisCell.conductivity = log(radius_pipe_in / radius_conv) / (2 * Constant.Pi * bh_equivalent_resistance_convection)
            thisCell.rhoCp = 1
            Cells.append(thisCell)

        # PIPE cells
        for i in range(num_pipe_cells):
            var thisCell: Cell
            thisCell.type = CellType.PIPE
            thisCell.thickness = pcf_cell_thickness
            thisCell.radius_inner = radius_pipe_in + i * thisCell.thickness
            thisCell.radius_center = thisCell.radius_inner + thisCell.thickness / 2.0
            thisCell.radius_outer = thisCell.radius_inner + thisCell.thickness
            thisCell.conductivity = log(radius_grout / radius_pipe_in) / (2 * Constant.Pi * bh_equivalent_resistance_tube_grout)
            thisCell.rhoCp = self.pipe.rhoCp
            Cells.append(thisCell)

        # GROUT cells
        for i in range(num_grout_cells):
            var thisCell: Cell
            thisCell.type = CellType.GROUT
            thisCell.thickness = grout_cell_thickness
            thisCell.radius_inner = radius_pipe_out + i * thisCell.thickness
            thisCell.radius_center = thisCell.radius_inner + thisCell.thickness / 2.0
            thisCell.radius_outer = thisCell.radius_inner + thisCell.thickness
            thisCell.conductivity = log(radius_grout / radius_pipe_in) / (2 * Constant.Pi * bh_equivalent_resistance_tube_grout)
            thisCell.rhoCp = self.grout.rhoCp
            Cells.append(thisCell)

        # SOIL cells
        for i in range(num_soil_cells):
            var thisCell: Cell
            thisCell.type = CellType.SOIL
            thisCell.thickness = soil_cell_thickness
            thisCell.radius_inner = radius_grout + i * thisCell.thickness
            thisCell.radius_center = thisCell.radius_inner + thisCell.thickness / 2.0
            thisCell.radius_outer = thisCell.radius_inner + thisCell.thickness
            thisCell.conductivity = self.soil.k
            thisCell.rhoCp = self.soil.rhoCp
            Cells.append(thisCell)

        for thisCell in Cells:
            thisCell.vol = Constant.Pi * (pow_2(thisCell.radius_outer) - pow_2(thisCell.radius_inner))
            thisCell.temperature = initial_temperature

        const lntts_max_for_short_timestep: Real64 = -8.6
        var t_s: Real64 = pow_2(self.bhLength) / (9.0 * self.soil.diffusivity)
        var time_max_for_short_timestep: Real64 = exp(lntts_max_for_short_timestep) * t_s
        var total_time: Real64 = 0.0
        while total_time < time_max_for_short_timestep:
            const heat_flux: Real64 = 1.0
            const time_step: Real64 = 120
            for thisCell in Cells:
                thisCell.temperature_prev_ts = thisCell.temperature

            var a: List[Real64] = []
            var b: List[Real64] = []
            var c: List[Real64] = []
            var d: List[Real64] = []
            var num_cells: UInt = len(Cells)
            for cell_index in range(num_cells):
                if cell_index == 0:
                    var thisCell = Cells[cell_index]
                    var eastCell = Cells[cell_index + 1]
                    var FE1: Real64 = log(thisCell.radius_outer / thisCell.radius_center) / (2 * Constant.Pi * thisCell.conductivity)
                    var FE2: Real64 = log(eastCell.radius_center / eastCell.radius_inner) / (2 * Constant.Pi * eastCell.conductivity)
                    var AE: Real64 = 1 / (FE1 + FE2)
                    var AD: Real64 = thisCell.rhoCp * thisCell.vol / time_step
                    a.append(0)
                    b.append(-AE / AD - 1)
                    c.append(AE / AD)
                    d.append(-thisCell.temperature_prev_ts - heat_flux / AD)
                elif cell_index == num_cells - 1:
                    var thisCell = Cells[cell_index]
                    a.append(0)
                    b.append(1)
                    c.append(0)
                    d.append(thisCell.temperature_prev_ts)
                else:
                    var westCell = Cells[cell_index - 1]
                    var eastCell = Cells[cell_index + 1]
                    var thisCell = Cells[cell_index]
                    var FE1: Real64 = log(thisCell.radius_outer / thisCell.radius_center) / (2 * Constant.Pi * thisCell.conductivity)
                    var FE2: Real64 = log(eastCell.radius_center / eastCell.radius_inner) / (2 * Constant.Pi * eastCell.conductivity)
                    var AE: Real64 = 1 / (FE1 + FE2)
                    var FW1: Real64 = log(westCell.radius_outer / westCell.radius_center) / (2 * Constant.Pi * westCell.conductivity)
                    var FW2: Real64 = log(thisCell.radius_center / thisCell.radius_inner) / (2 * Constant.Pi * thisCell.conductivity)
                    var AW: Real64 = -1 / (FW1 + FW2)
                    var AD: Real64 = thisCell.rhoCp * thisCell.vol / time_step
                    a.append(-AW / AD)
                    b.append(AW / AD - AE / AD - 1)
                    c.append(AE / AD)
                    d.append(-thisCell.temperature_prev_ts)

            var new_temps: List[Real64] = TDMA(a, b, c, d)
            for cell_index in range(num_cells):
                Cells[cell_index].temperature = new_temps[cell_index]
            total_time += time_step
            self.GFNC_shortTimestep.append(2 * Constant.Pi * self.soil.k * ((Cells[0].temperature - initial_temperature) / heat_flux - bhResistance))
            self.LNTTS_shortTimestep.append(log(total_time / t_s))

        var l: String = ""
        var g: String = ""
        for val in self.LNTTS_shortTimestep:
            l += str(val) + "\n"
        for val in self.GFNC_shortTimestep:
            g += str(val) + "\n"

    def calcBHAverageResistance(self, state: EnergyPlusData) -> Real64:
        var beta: Real64 = 2 * Constant.Pi * self.grout.k * self.calcPipeResistance(state)
        var final_term_1: Real64 = log(self.theta_2 / (2 * self.theta_1 * pow(1 - pow_4(self.theta_1), self.sigma)))
        var num_final_term_2: Real64 = pow_2(self.theta_3) * pow_2(1 - (4 * self.sigma * pow_4(self.theta_1)) / (1 - pow_4(self.theta_1)))
        var den_final_term_2_pt_1: Real64 = (1 + beta) / (1 - beta)
        var den_final_term_2_pt_2: Real64 = pow_2(self.theta_3) * (1 + (16 * self.sigma * pow_4(self.theta_1)) / pow_2(1 - pow_4(self.theta_1)))
        var den_final_term_2: Real64 = den_final_term_2_pt_1 + den_final_term_2_pt_2
        var final_term_2: Real64 = num_final_term_2 / den_final_term_2
        return 1 / (4 * Constant.Pi * self.grout.k) * (beta + final_term_1 - final_term_2)

    def calcBHTotalInternalResistance(self, state: EnergyPlusData) -> Real64:
        var beta: Real64 = 2 * Constant.Pi * self.grout.k * self.calcPipeResistance(state)
        var final_term_1: Real64 = log(pow(1 + pow_2(self.theta_1), self.sigma) / (self.theta_3 * pow(1 - pow_2(self.theta_1), self.sigma)))
        var num_term_2: Real64 = pow_2(self.theta_3) * pow_2(1 - pow_4(self.theta_1) + 4 * self.sigma * pow_2(self.theta_1))
        var den_term_2_pt_1: Real64 = (1 + beta) / (1 - beta) * pow_2(1 - pow_4(self.theta_1))
        var den_term_2_pt_2: Real64 = pow_2(self.theta_3) * pow_2(1 - pow_4(self.theta_1))
        var den_term_2_pt_3: Real64 = 8 * self.sigma * pow_2(self.theta_1) * pow_2(self.theta_3) * (1 + pow_4(self.theta_1))
        var den_term_2: Real64 = den_term_2_pt_1 - den_term_2_pt_2 + den_term_2_pt_3
        var final_term_2: Real64 = num_term_2 / den_term_2
        return 1 / (Constant.Pi * self.grout.k) * (beta + final_term_1 - final_term_2)

    def calcBHGroutResistance(self, state: EnergyPlusData) -> Real64:
        return self.calcBHAverageResistance(state) - self.calcPipeResistance(state) / 2.0

    def calcHXResistance(self, state: EnergyPlusData) -> Real64:
        if self.massFlowRate <= 0.0:
            return 0
        const RoutineName: String = "calcBHResistance"
        var cpFluid: Real64 = state.dataPlnt.PlantLoop[self.plantLoc.loopNum].glycol.getSpecificHeat(state, self.inletTemp, RoutineName)
        return self.calcBHAverageResistance(state) + 1 / (3 * self.calcBHTotalInternalResistance(state)) * pow_2(self.bhLength / (self.massFlowRate * cpFluid))

    def calcPipeConductionResistance(self) -> Real64:
        return log(self.pipe.outDia / self.pipe.innerDia) / (2 * Constant.Pi * self.pipe.k)

    def calcPipeConvectionResistance(self, state: EnergyPlusData) -> Real64:
        const RoutineName: String = "calcPipeConvectionResistance"
        self.inletTemp = state.dataLoopNodes.Node[self.inletNodeNum].Temp
        var cpFluid: Real64 = state.dataPlnt.PlantLoop[self.plantLoc.loopNum].glycol.getSpecificHeat(state, self.inletTemp, RoutineName)
        var kFluid: Real64 = state.dataPlnt.PlantLoop[self.plantLoc.loopNum].glycol.getConductivity(state, self.inletTemp, RoutineName)
        var fluidViscosity: Real64 = state.dataPlnt.PlantLoop[self.plantLoc.loopNum].glycol.getViscosity(state, self.inletTemp, RoutineName)
        const lower_limit: Real64 = 2000
        const upper_limit: Real64 = 4000
        var bhMassFlowRate: Real64 = self.massFlowRate / self.myRespFactors.numBoreholes
        var reynoldsNum: Real64 = 4 * bhMassFlowRate / (fluidViscosity * Constant.Pi * self.pipe.innerDia)
        var nusseltNum: Real64 = 0.0
        if reynoldsNum < lower_limit:
            nusseltNum = 4.01
        elif reynoldsNum < upper_limit:
            var nu_low: Real64 = 4.01
            var f: Real64 = self.frictionFactor(reynoldsNum)
            var prandtlNum: Real64 = (cpFluid * fluidViscosity) / kFluid
            var nu_high: Real64 = (f / 8) * (reynoldsNum - 1000) * prandtlNum / (1 + 12.7 * sqrt(f / 8) * (pow(prandtlNum, 2.0 / 3.0) - 1))
            var sf: Real64 = 1 / (1 + exp(-(reynoldsNum - 3000) / 150.0))
            nusseltNum = (1 - sf) * nu_low + sf * nu_high
        else:
            var f: Real64 = self.frictionFactor(reynoldsNum)
            var prandtlNum: Real64 = (cpFluid * fluidViscosity) / kFluid
            nusseltNum = (f / 8) * (reynoldsNum - 1000) * prandtlNum / (1 + 12.7 * sqrt(f / 8) * (pow(prandtlNum, 2.0 / 3.0) - 1))
        var h: Real64 = nusseltNum * kFluid / self.pipe.innerDia
        return 1 / (h * Constant.Pi * self.pipe.innerDia)

    @staticmethod
    def frictionFactor(reynoldsNum: Real64) -> Real64:
        const lower_limit: Real64 = 1500
        const upper_limit: Real64 = 5000
        if reynoldsNum < lower_limit:
            return 64.0 / reynoldsNum
        if reynoldsNum < upper_limit:
            var f_low: Real64 = 64.0 / reynoldsNum
            var f_high: Real64 = pow(0.79 * log(reynoldsNum) - 1.64, -2.0)
            var sf: Real64 = 1 / (1 + exp(-(reynoldsNum - 3000.0) / 450.0))
            return (1 - sf) * f_low + sf * f_high
        return pow(0.79 * log(reynoldsNum) - 1.64, -2.0)

    def calcPipeResistance(self, state: EnergyPlusData) -> Real64:
        return self.calcPipeConductionResistance() + self.calcPipeConvectionResistance(state)

    def getGFunc(self, time: Real64) -> Real64:
        var LNTTS: Real64 = log(time)
        var gFuncVal: Real64 = self.interpGFunc(LNTTS)
        var RATIO: Real64 = self.bhRadius / self.bhLength
        if RATIO != self.myRespFactors.gRefRatio:
            gFuncVal -= log(self.bhRadius / (self.bhLength * self.myRespFactors.gRefRatio))
        return gFuncVal

    def initGLHESimVars(inout self, state: EnergyPlusData):
        var currTime: Real64 = ((state.dataGlobal.DayOfSim - 1) * 24 + (state.dataGlobal.HourOfDay - 1) +
            (state.dataGlobal.TimeStep - 1) * state.dataGlobal.TimeStepZone + state.dataHVACGlobal.SysTimeElapsed) * Constant.rSecsInHour
        if self.myEnvrnFlag and state.dataGlobal.BeginEnvrnFlag:
            self.initEnvironment(state, currTime)
        var minDepth: Real64 = self.myRespFactors.props.bhTopDepth
        var maxDepth: Real64 = self.myRespFactors.props.bhLength + minDepth
        var oneQuarterDepth: Real64 = minDepth + (maxDepth - minDepth) * 0.25
        var halfDepth: Real64 = minDepth + (maxDepth - minDepth) * 0.5
        var threeQuarterDepth: Real64 = minDepth + (maxDepth - minDepth) * 0.75
        self.tempGround = 0
        self.tempGround += self.groundTempModel.getGroundTempAtTimeInSeconds(state, minDepth, currTime)
        self.tempGround += self.groundTempModel.getGroundTempAtTimeInSeconds(state, maxDepth, currTime)
        self.tempGround += self.groundTempModel.getGroundTempAtTimeInSeconds(state, oneQuarterDepth, currTime)
        self.tempGround += self.groundTempModel.getGroundTempAtTimeInSeconds(state, halfDepth, currTime)
        self.tempGround += self.groundTempModel.getGroundTempAtTimeInSeconds(state, threeQuarterDepth, currTime)
        self.tempGround /= 5.0
        self.massFlowRate = PlantUtilities.RegulateCondenserCompFlowReqOp(state, self.plantLoc, self.designMassFlow)
        PlantUtilities.SetComponentFlowRate(state, self.massFlowRate, self.inletNodeNum, self.outletNodeNum, self.plantLoc)
        if not state.dataGlobal.BeginEnvrnFlag:
            self.myEnvrnFlag = True

    def initEnvironment(inout self, state: EnergyPlusData, CurTime: Real64):
        const RoutineName: String = "initEnvironment"
        self.myEnvrnFlag = False
        var fluidDensity: Real64 = state.dataPlnt.PlantLoop[self.plantLoc.loopNum].glycol.getDensity(state, 20.0, RoutineName)
        self.designMassFlow = self.designFlow * fluidDensity
        PlantUtilities.InitComponentNodes(state, 0.0, self.designMassFlow, self.inletNodeNum, self.outletNodeNum)
        self.lastQnSubHr = 0.0
        state.dataLoopNodes.Node[self.inletNodeNum].Temp = self.tempGround
        state.dataLoopNodes.Node[self.outletNodeNum].Temp = self.tempGround
        self.QnHr = List[Real64]()
        self.QnMonthlyAgg = List[Real64]()
        self.QnSubHr = List[Real64]()
        self.LastHourN = List[Int]()
        self.prevTimeSteps = List[Real64]()
        self.currentSimTime = 0.0
        self.QGLHE = 0.0
        self.prevHour = 1

    def oneTimeInit_new(inout self, state: EnergyPlusData):
        var errFlag: Bool = False
        PlantUtilities.ScanPlantLoopsForObject(state, self.name, DataPlant.PlantEquipmentType.GrndHtExchgSystem, self.plantLoc, errFlag, _, _, _, _, _)
        if errFlag:
            ShowFatalError(state, "initGLHESimVars: Program terminated due to previous condition(s).")

    def oneTimeInit(inout self, state: EnergyPlusData):

# Helper functions (not in class but used)
def pow_2(x: Real64) -> Real64:
    return x * x

def pow_4(x: Real64) -> Real64:
    return x * x * x * x

def pow_2(x: Int) -> Int:
    return x * x

def isEven(x: Int) -> Bool:
    return x % 2 == 0

# TDMA solver (from C++ code, assumed defined elsewhere; we stub it here)
def TDMA(a: List[Real64], b: List[Real64], c: List[Real64], d: List[Real64]) -> List[Real64]:
    # stub: needs implementation
    return List[Real64]()

# Note: many types and functions are assumed to be imported/defined in other modules.
# This translation is provided as a faithful representation of the source structure.
# Missing imports should be added based on actual EnergyPlus-Mojo project structure.
