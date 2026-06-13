import math
import json
import os
from pathlib import Path
from typing import Protocol, Optional, Any
from dataclasses import dataclass, field
from enum import IntEnum
import subprocess
from datetime import datetime

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: main state object with nested data members
# - PlantLocation: plant loop location descriptor
# - MyCartesian: 3D point with x, y, z coordinates
# - GLHEVertSingle: single borehole representation
# - GLHEVertArray: array of boreholes
# - GLHEBase: parent class for ground heat exchangers
# - ResponseFactor: g-function and time data structure
# - GroundTempModel: undisturbed ground temperature model
# - Soil/Pipe/Grout: thermal property objects
# - Node: loop node reference
# - DisplayString, ShowFatalError, ShowWarningMessage, ShowSevereError: I/O functions
# - PlantUtilities: plant loop utilities
# - FileSystem: file system utilities
# - Constant: physical and conversion constants
# - DataPlant: plant loop data enumerations
# - Util: utility functions


class GFuncCalcMethod(IntEnum):
    Invalid = -1
    UniformHeatFlux = 0
    UniformBoreholeWallTemp = 1
    FullDesign = 2


@dataclass
class BorefieldSizingData:
    name: str = ""
    type: str = ""
    sizingPeriodName: str = ""
    designFlowRatePerBorehole: float = 0.0
    length: float = 0.0
    width: float = 0.0
    minSpacing: float = 0.0
    maxSpacing: float = 0.0
    minLength: float = 0.0
    maxLength: float = 0.0
    numBoreholes: int = 0
    minEFT: float = 0.0
    maxEFT: float = 0.0


class SoilProps(Protocol):
    k: float
    rhoCp: float
    diffusivity: float


class PipeProps(Protocol):
    outDia: float
    innerDia: float
    outRadius: float
    innerRadius: float
    thickness: float
    k: float
    rhoCp: float


class GroutProps(Protocol):
    k: float
    rhoCp: float


class RespFactorProps(Protocol):
    bhDiameter: float
    bhLength: float
    bhUTubeDist: float
    bhTopDepth: float
    pipe: PipeProps
    grout: GroutProps


class MyBoreholeArray(Protocol):
    pointLocations_i: list
    pointLocations_ii: list
    pointLocations_j: list
    dl_i: float
    dl_ii: float
    dl_j: float
    props: RespFactorProps


class RespFactors(Protocol):
    GFNC: list[float]
    LNTTS: list[float]
    time: list[float]
    numBoreholes: int
    maxSimYears: int
    gRefRatio: float
    myBorholes: list[MyBoreholeArray]
    props: RespFactorProps


class PlantLocation(Protocol):
    loopNum: int


class MyCartesian(Protocol):
    x: float
    y: float
    z: float


class GLHEVertSingle(Protocol):
    pointLocations_i: list[MyCartesian]
    pointLocations_ii: list[MyCartesian]
    pointLocations_j: list[MyCartesian]
    dl_i: float
    dl_ii: float
    dl_j: float
    props: RespFactorProps
    xLoc: float
    yLoc: float


class GroundTempModel(Protocol):
    def getGroundTempAtTimeInSeconds(self, state: Any, depth: float, time: float) -> float:
        ...


class GLHEBase(Protocol):
    name: str
    inletNodeNum: int
    outletNodeNum: int
    designFlow: float
    available: bool
    on: bool
    soil: SoilProps
    grout: GroutProps
    pipe: PipeProps
    plantLoc: PlantLocation
    gFunctionsExist: bool
    myRespFactors: RespFactors
    totalTubeLength: float
    inletTemp: float
    outletTemp: float
    tempGround: float
    massFlowRate: float
    designMassFlow: float
    myEnvrnFlag: bool
    gFuncCalcMethod: GFuncCalcMethod
    AGG: int
    SubAGG: int
    QnMonthlyAgg: list[float]
    QnHr: list[float]
    QnSubHr: list[float]
    LastHourN: list[int]
    prevTimeSteps: list[float]
    timeSS: float
    timeSSFactor: float
    groundTempModel: GroundTempModel
    lastQnSubHr: float
    currentSimTime: float
    QGLHE: float
    prevHour: int
    needToSetupOutputVars: bool

    def setupOutput(self, state: Any) -> None:
        ...

    def interpGFunc(self, lntts: float) -> float:
        ...

    def calcGroundHeatExchanger(self, state: Any) -> None:
        ...

    def updateGHX(self, state: Any) -> None:
        ...


class NodeState(Protocol):
    Temp: float


class NodeArray(Protocol):
    def __getitem__(self, idx: int) -> NodeState:
        ...


class GlycolObject(Protocol):
    GlycolName: str
    Concentration: float

    def getSpecificHeat(self, state: Any, temp: float, routine: str) -> float:
        ...

    def getDensity(self, state: Any, temp: float, routine: str) -> float:
        ...

    def getConductivity(self, state: Any, temp: float, routine: str) -> float:
        ...

    def getViscosity(self, state: Any, temp: float, routine: str) -> float:
        ...


class PlantLoopData(Protocol):
    FluidName: str
    glycol: GlycolObject


class PlantLoopArray(Protocol):
    def __getitem__(self, idx: int) -> PlantLoopData:
        ...


class EnergyPlusData(Protocol):
    class DataGroundHeatExchanger(Protocol):
        verticalGLHE: list

    class DataLoopNodes(Protocol):
        Node: NodeArray

    class DataPlnt(Protocol):
        PlantLoop: PlantLoopArray

    class DataGlobal(Protocol):
        DayOfSim: int
        HourOfDay: int
        TimeStep: int
        TimeStepZone: float
        KickOffSimulation: bool
        WarmupFlag: bool
        DoingHVACSizingSimulations: bool
        BeginEnvrnFlag: bool
        CurrentTime: float
        installRootOverride: bool

    class DataStrGlobals(Protocol):
        outDirPath: Path
        exeDirectoryPath: Path

    class DataEnvrn(Protocol):
        MaxNumberSimYears: int

    class DataHVACGlobal(Protocol):
        SysTimeElapsed: float

    class DataInputProcessing(Protocol):
        class InputProcessor(Protocol):
            epJSON: dict
            def getDefaultValue(self, state: Any, obj_type: str, field: str, out_val: list) -> None:
                ...
            def markObjectAsUsed(self, obj_type: str, name: str) -> None:
                ...

        inputProcessor: InputProcessor

    class DataWeather(Protocol):
        class RunPeriodDesign(Protocol):
            title: str
            totalDays: int

        RunPeriodDesignInput: list[RunPeriodDesign]

    dataGroundHeatExchanger: DataGroundHeatExchanger
    dataLoopNodes: DataLoopNodes
    dataPlnt: DataPlnt
    dataGlobal: DataGlobal
    dataStrGlobals: DataStrGlobals
    dataEnvrn: DataEnvrn
    dataHVACGlobal: DataHVACGlobal
    dataInputProcessing: DataInputProcessing
    dataWeather: DataWeather


def TDMA(a: list[float], b: list[float], c: list[float], d: list[float]) -> list[float]:
    n = len(d)
    c_prime = [0.0] * n
    d_prime = [0.0] * n
    x = [0.0] * n

    c_prime[0] = c[0] / b[0]
    d_prime[0] = d[0] / b[0]

    for i in range(1, n):
        denom = b[i] - a[i] * c_prime[i - 1]
        if abs(denom) < 1e-10:
            denom = 1e-10
        c_prime[i] = c[i] / denom if i < n - 1 else 0.0
        d_prime[i] = (d[i] - a[i] * d_prime[i - 1]) / denom

    x[n - 1] = d_prime[n - 1]
    for i in range(n - 2, -1, -1):
        x[i] = d_prime[i] - c_prime[i] * x[i + 1]

    return x


def pow_2(x: float) -> float:
    return x * x


def pow_4(x: float) -> float:
    return x * x * x * x


def isEven(n: int) -> bool:
    return n % 2 == 0


def erfc(x: float) -> float:
    return math.erfc(x)


class GLHEVert(GLHEBase):
    moduleName: str = "GroundHeatExchanger:System"
    bhDiameter: float = 0.0
    bhRadius: float = 0.0
    bhLength: float = 0.0
    bhUTubeDist: float = 0.0
    gFuncCalcMethod: GFuncCalcMethod = GFuncCalcMethod.Invalid
    theta_1: float = 0.0
    theta_2: float = 0.0
    theta_3: float = 0.0
    sigma: float = 0.0
    loadsDuringSizingForDesign: dict[float, float] = field(default_factory=dict)
    GFNC_shortTimestep: list[float] = field(default_factory=list)
    LNTTS_shortTimestep: list[float] = field(default_factory=list)
    sizingData: BorefieldSizingData = field(default_factory=BorefieldSizingData)
    fullDesignLoadAccrualStarted: bool = False
    fullDesignCompleted: bool = False

    def __init__(self, state: EnergyPlusData, objName: str, j: dict):
        for existingObj in state.dataGroundHeatExchanger.verticalGLHE:
            if objName == existingObj.name:
                ShowFatalError(state, f"Invalid input for {self.moduleName} object: Duplicate name found: {existingObj.name}")

        errorsFound = False
        self.name = objName

        inletNodeName = Util.makeUPPER(j["inlet_node_name"])
        self.inletNodeNum = Node.GetOnlySingleNode(
            state, inletNodeName, errorsFound, Node.ConnectionObjectType.GroundHeatExchangerSystem,
            objName, Node.FluidType.Water, Node.ConnectionType.Inlet,
            Node.CompFluidStream.Primary, Node.ObjectIsNotParent
        )

        outletNodeName = Util.makeUPPER(j["outlet_node_name"])
        self.outletNodeNum = Node.GetOnlySingleNode(
            state, outletNodeName, errorsFound, Node.ConnectionObjectType.GroundHeatExchangerSystem,
            objName, Node.FluidType.Water, Node.ConnectionType.Outlet,
            Node.CompFluidStream.Primary, Node.ObjectIsNotParent
        )

        self.available = True
        self.on = True
        Node.TestCompSet(state, self.moduleName, objName, inletNodeName, outletNodeName, "Condenser Water Nodes")

        self.designFlow = j["design_flow_rate"]
        PlantUtilities.RegisterPlantCompDesignFlow(state, self.inletNodeNum, self.designFlow)

        self.soil.k = j["ground_thermal_conductivity"]
        self.soil.rhoCp = j["ground_thermal_heat_capacity"]

        if "ghe_vertical_responsefactors_object_name" in j:
            self.myRespFactors = GetResponseFactor(state, Util.makeUPPER(j["ghe_vertical_responsefactors_object_name"]))
            self.gFunctionsExist = True

        if not self.gFunctionsExist:
            if "g_function_calculation_method" in j:
                gFunctionMethodStr = Util.makeUPPER(j["g_function_calculation_method"])
                if gFunctionMethodStr == "UHFCALC":
                    self.gFuncCalcMethod = GFuncCalcMethod.UniformHeatFlux
                elif gFunctionMethodStr == "UBHWTCALC":
                    self.gFuncCalcMethod = GFuncCalcMethod.UniformBoreholeWallTemp
                elif gFunctionMethodStr == "FULLDESIGN":
                    self.gFuncCalcMethod = GFuncCalcMethod.FullDesign
                else:
                    errorsFound = True
                    ShowSevereError(state, f"g-Function Calculation Method: \"{gFunctionMethodStr}\" is invalid")

            if self.gFuncCalcMethod == GFuncCalcMethod.FullDesign:
                foundSizing = False
                objTypeFound = "ghe_vertical_sizing_object_type" in j
                objNameFound = "ghe_vertical_sizing_object_name" in j

                if not objTypeFound:
                    ShowSevereError(state, f"GroundHeatExchanger:System \"{self.name}\"")
                    ShowContinueError(state, f"g-Function Calculation Method = \"{j['g_function_calculation_method']}\"")
                    ShowContinueError(state, "GHE:Vertical:Sizing Object Type not specified.")
                    errorsFound = True
                if not objNameFound:
                    ShowSevereError(state, f"GroundHeatExchanger:System \"{self.name}\"")
                    ShowContinueError(state, f"g-Function Calculation Method = \"{j['g_function_calculation_method']}\"")
                    ShowContinueError(state, "GHE:Vertical:Sizing Object Name not specified.")
                    errorsFound = True

                self.sizingData.name = j["ghe_vertical_sizing_object_name"]
                self.sizingData.type = j["ghe_vertical_sizing_object_type"]

                if Util.makeUPPER(self.sizingData.type) != "GROUNDHEATEXCHANGER:VERTICAL:SIZING:RECTANGLE":
                    ShowSevereError(state, f"GroundHeatExchanger:System \"{self.name}\"")
                    ShowContinueError(state, f"GHE:Vertical:Sizing Object Type not supported \"{self.sizingData.type}\"")
                    errorsFound = True

                instances = state.dataInputProcessing.inputProcessor.epJSON.get("GroundHeatExchanger:Vertical:Sizing:Rectangle")
                if instances is None:
                    ShowSevereError(state, f"Expected to find GroundHeatExchanger:Vertical:Sizing named {self.sizingData.name}, but it was missing")
                    errorsFound = True
                else:
                    for thisSizingObjName, fields in instances.items():
                        objNameUC = Util.makeUPPER(thisSizingObjName)
                        if objNameUC == Util.makeUPPER(self.sizingData.name):
                            foundSizing = True

                            self.sizingData.sizingPeriodName = fields["sizingperiod_weatherfiledays_name"]
                            spInstances = state.dataInputProcessing.inputProcessor.epJSON.get("SizingPeriod:WeatherFileDays")
                            if spInstances is None:
                                ShowSevereError(state, f"Expected to find SizingPeriod:WeatherFileDays named {self.sizingData.sizingPeriodName}, but it was missing")
                                errorsFound = True

                            spIsAnnual = False
                            for designPeriod in state.dataWeather.RunPeriodDesignInput:
                                if (Util.makeUPPER(designPeriod.title) == Util.makeUPPER(self.sizingData.sizingPeriodName) and
                                    designPeriod.totalDays == 365):
                                    spIsAnnual = True
                                    break

                            if not spIsAnnual:
                                ShowSevereError(state, f"SizingPeriod:WeatherFileDays named {self.sizingData.sizingPeriodName}, must be an annual design period of 365 days")
                                errorsFound = True

                            if "design_flow_rate_per_borehole" in fields:
                                self.sizingData.designFlowRatePerBorehole = fields["design_flow_rate_per_borehole"]
                            else:
                                out_val = [0.0]
                                state.dataInputProcessing.inputProcessor.getDefaultValue(state, self.sizingData.type, "design_flow_rate_per_borehole", out_val)
                                self.sizingData.designFlowRatePerBorehole = out_val[0]

                            self.sizingData.length = fields["available_borehole_field_length"]
                            self.sizingData.width = fields["available_borehole_field_width"]
                            self.sizingData.numBoreholes = fields["maximum_number_of_boreholes"]

                            if "minimum_borehole_spacing" in fields:
                                self.sizingData.minSpacing = fields["minimum_borehole_spacing"]
                            else:
                                out_val = [0.0]
                                state.dataInputProcessing.inputProcessor.getDefaultValue(state, self.sizingData.type, "minimum_borehole_spacing", out_val)
                                self.sizingData.minSpacing = out_val[0]

                            if "maximum_borehole_spacing" in fields:
                                self.sizingData.maxSpacing = fields["maximum_borehole_spacing"]
                            else:
                                out_val = [0.0]
                                state.dataInputProcessing.inputProcessor.getDefaultValue(state, self.sizingData.type, "maximum_borehole_spacing", out_val)
                                self.sizingData.maxSpacing = out_val[0]

                            if "minimum_borehole_vertical_length" in fields:
                                self.sizingData.minLength = fields["minimum_borehole_vertical_length"]
                            else:
                                out_val = [0.0]
                                state.dataInputProcessing.inputProcessor.getDefaultValue(state, self.sizingData.type, "minimum_borehole_vertical_length", out_val)
                                self.sizingData.minLength = out_val[0]

                            if "maximum_borehole_vertical_length" in fields:
                                self.sizingData.maxLength = fields["maximum_borehole_vertical_length"]
                            else:
                                out_val = [0.0]
                                state.dataInputProcessing.inputProcessor.getDefaultValue(state, self.sizingData.type, "maximum_borehole_vertical_length", out_val)
                                self.sizingData.maxLength = out_val[0]

                            if "minimum_exiting_fluid_temperature_for_sizing" in fields:
                                self.sizingData.minEFT = fields["minimum_exiting_fluid_temperature_for_sizing"]
                            else:
                                out_val = [0.0]
                                state.dataInputProcessing.inputProcessor.getDefaultValue(state, self.sizingData.type, "minimum_exiting_fluid_temperature_for_sizing", out_val)
                                self.sizingData.minEFT = out_val[0]

                            if "maximum_exiting_fluid_temperature_for_sizing" in fields:
                                self.sizingData.maxEFT = fields["maximum_exiting_fluid_temperature_for_sizing"]
                            else:
                                out_val = [0.0]
                                state.dataInputProcessing.inputProcessor.getDefaultValue(state, self.sizingData.type, "maximum_exiting_fluid_temperature_for_sizing", out_val)
                                self.sizingData.maxEFT = out_val[0]

                            state.dataInputProcessing.inputProcessor.markObjectAsUsed("GroundHeatExchanger:Vertical:Sizing:Rectangle", self.sizingData.name)
                            break

                    if not foundSizing:
                        ShowSevereError(state, "Could not find matching GroundHeatExchanger:Vertical:Sizing:Rectangle")
                        errorsFound = True

                if "vertical_well_locations" not in j:
                    ShowSevereError(state, "For a full design GHE simulation, you must provide a GHE:Vertical:Single object")
                    ShowContinueError(state, "If you enter more than one, only the first is used to specify the borehole design")
                    ShowContinueError(state, f"Check references to these objects for GHE:System object: {self.name}")
                    errorsFound = True

                tempVectOfBHObjects = []
                vars_list = j["vertical_well_locations"]
                for var in vars_list:
                    if var["ghe_vertical_single_object_name"]:
                        tempBHptr = GLHEVertSingle.GetSingleBH(state, Util.makeUPPER(var["ghe_vertical_single_object_name"]))
                        tempVectOfBHObjects.append(tempBHptr)
                        self.myRespFactors = BuildAndGetResponseFactorsObjectFromSingleBHs(state, tempVectOfBHObjects)
                    break

                if not self.myRespFactors:
                    ShowSevereError(state, "Something went wrong creating response factor for GroundHeatExchanger, check previous errors.")
                    errorsFound = True

            elif "ghe_vertical_array_object_name" in j:
                self.myRespFactors = BuildAndGetResponseFactorObjectFromArray(
                    state, GLHEVertArray.GetVertArray(state, Util.makeUPPER(j["ghe_vertical_array_object_name"]))
                )
            else:
                if "vertical_well_locations" not in j:
                    ShowSevereError(state, "No GHE:ResponseFactors, GHE:Vertical:Array, or GHE:Vertical:Single objects found")
                    ShowContinueError(state, f"Check references to these objects for GHE:System object: {self.name}")
                    errorsFound = True

                vars_list = j["vertical_well_locations"]
                tempVectOfBHObjects = []

                for var in vars_list:
                    if var["ghe_vertical_single_object_name"]:
                        tempBHptr = GLHEVertSingle.GetSingleBH(state, Util.makeUPPER(var["ghe_vertical_single_object_name"]))
                        tempVectOfBHObjects.append(tempBHptr)
                    else:
                        break

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

        self.QnMonthlyAgg = [0.0] * int(self.myRespFactors.maxSimYears * 12)
        self.QnHr = [0.0] * (730 + self.AGG + self.SubAGG)
        self.QnSubHr = [0.0] * int((self.SubAGG + 1) * 6 + 1)
        self.LastHourN = [0] * (self.SubAGG + 1)

        self.prevTimeSteps = [0.0] * int((self.SubAGG + 1) * 6 + 1)

        modelTypeStr = j["undisturbed_ground_temperature_model_type"]
        self.groundTempModel = GroundTemp.GetGroundTempModelAndInit(
            state, modelTypeStr, Util.makeUPPER(j["undisturbed_ground_temperature_model_name"])
        )

        if errorsFound:
            ShowFatalError(state, f"Errors found in processing input for {self.moduleName}")

    def simulate(self, state: EnergyPlusData, calledFromLocation, FirstHVACIteration, CurLoad, RunFlag):
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
                pass
            elif not state.dataGlobal.WarmupFlag:
                if self.fullDesignLoadAccrualStarted:
                    if state.dataGlobal.DoingHVACSizingSimulations:
                        cpFluid = state.dataPlnt.PlantLoop[self.plantLoc.loopNum].glycol.getSpecificHeat(state, self.inletTemp, "GLHEVert::simulate")
                        q = self.massFlowRate * cpFluid * (self.outletTemp - self.inletTemp)
                        timeStamp = (state.dataGlobal.DayOfSim - 1) * 24 + state.dataGlobal.CurrentTime
                        self.loadsDuringSizingForDesign[timeStamp] = q
                    else:
                        self.fullDesignCompleted = True
                        if len(self.loadsDuringSizingForDesign) % 8760 != 0:
                            ShowFatalError(state, "Bad number of load values found when trying to accumulate ghe loads for design")
                        timeStepValues = list(self.loadsDuringSizingForDesign.values())
                        hourlyValues = []
                        numPerHour = len(timeStepValues) // 8760
                        for i in range(0, len(timeStepValues), numPerHour):
                            sum_val = sum(timeStepValues[i:i + numPerHour])
                            hourlyValues.append(sum_val / numPerHour)
                        self.performBoreholeFieldDesignAndSizingWithGHEDesigner(state, hourlyValues)
                else:
                    if state.dataGlobal.DoingHVACSizingSimulations:
                        self.fullDesignLoadAccrualStarted = True
                        cpFluid = state.dataPlnt.PlantLoop[self.plantLoc.loopNum].glycol.getSpecificHeat(state, self.inletTemp, "GLHEVert::simulate")
                        q = self.massFlowRate * cpFluid * (self.outletTemp - self.inletTemp)
                        timeStamp = (state.dataGlobal.DayOfSim - 1) * 24 + state.dataGlobal.CurrentTime
                        self.loadsDuringSizingForDesign[timeStamp] = q
            if self.fullDesignCompleted:
                self.calcGroundHeatExchanger(state)
        else:
            self.calcGroundHeatExchanger(state)
        self.updateGHX(state)

    def getAnnualTimeConstant(self):
        hrInYear = 8760.0
        self.timeSS = (pow_2(self.bhLength) / (9.0 * self.soil.diffusivity)) / Constant.rSecsInHour / hrInYear
        self.timeSSFactor = self.timeSS * 8760.0

    def combineShortAndLongTimestepGFunctions(self):
        GFNC_combined = []
        LNTTS_combined = []

        t_s = pow_2(self.bhLength) / (9.0 * self.soil.diffusivity)

        num_shortTimestepGFunctions = len(self.GFNC_shortTimestep)
        for index_shortTS in range(num_shortTimestepGFunctions):
            GFNC_combined.append(self.GFNC_shortTimestep[index_shortTS])
            LNTTS_combined.append(self.LNTTS_shortTimestep[index_shortTS])

        highest_lntts_from_sts = self.LNTTS_shortTimestep[-1]

        for index_longTS in range(len(self.myRespFactors.GFNC)):
            if self.myRespFactors.LNTTS[index_longTS] <= highest_lntts_from_sts:
                continue
            GFNC_combined.append(self.myRespFactors.GFNC[index_longTS])
            LNTTS_combined.append(self.myRespFactors.LNTTS[index_longTS])

        self.myRespFactors.time = [math.exp(c) * t_s for c in LNTTS_combined]
        self.myRespFactors.LNTTS = LNTTS_combined
        self.myRespFactors.GFNC = GFNC_combined

    @staticmethod
    def distances(point_i: MyCartesian, point_j: MyCartesian) -> list[float]:
        sumVals = [
            pow_2(point_i.x - point_j.x),
            pow_2(point_i.y - point_j.y),
            pow_2(point_i.z - point_j.z)
        ]

        sumTot = sum(sumVals)
        retVals = [math.sqrt(sumTot)]

        sumVals[-1] = pow_2(point_i.z - (-point_j.z))
        sumTot = sum(sumVals)
        retVals.append(math.sqrt(sumTot))

        return retVals

    def calcResponse(self, dists: list[float], currTime: float) -> float:
        pointToPointResponse = erfc(dists[0] / (2 * math.sqrt(self.soil.diffusivity * currTime))) / dists[0]
        pointToReflectedResponse = erfc(dists[1] / (2 * math.sqrt(self.soil.diffusivity * currTime))) / dists[1]
        return pointToPointResponse - pointToReflectedResponse

    def integral(self, point_i: MyCartesian, bh_j: GLHEVertSingle, currTime: float) -> float:
        sum_f = 0.0
        i = 0
        lastIndex_j = len(bh_j.pointLocations_j) - 1
        for point_j in bh_j.pointLocations_j:
            dists = self.distances(point_i, point_j)
            f = self.calcResponse(dists, currTime)

            if i == 0 or i == lastIndex_j:
                sum_f += f
            elif isEven(i):
                sum_f += 2 * f
            else:
                sum_f += 4 * f

            i += 1

        return (bh_j.dl_j / 3.0) * sum_f

    def doubleIntegral(self, bh_i: GLHEVertSingle, bh_j: GLHEVertSingle, currTime: float) -> float:
        if bh_i is bh_j:
            sum_f = 0
            i = 0
            lastIndex = len(bh_i.pointLocations_ii) - 1
            for thisPoint in bh_i.pointLocations_ii:
                f = self.integral(thisPoint, bh_j, currTime)

                if i == 0 or i == lastIndex:
                    sum_f += f
                elif isEven(i):
                    sum_f += 2 * f
                else:
                    sum_f += 4 * f

                i += 1

            return (bh_i.dl_ii / 3.0) * sum_f

        sum_f = 0
        i = 0
        lastIndex = len(bh_i.pointLocations_i) - 1
        for thisPoint in bh_i.pointLocations_i:
            f = self.integral(thisPoint, bh_j, currTime)

            if i == 0 or i == lastIndex:
                sum_f += f
            elif isEven(i):
                sum_f += 2 * f
            else:
                sum_f += 4 * f

            i += 1

        return (bh_i.dl_i / 3.0) * sum_f

    def calcLongTimestepGFunctions(self, state: EnergyPlusData):
        if self.gFuncCalcMethod == GFuncCalcMethod.UniformHeatFlux:
            self.calcUniformHeatFluxGFunctions(state)
        elif self.gFuncCalcMethod == GFuncCalcMethod.UniformBoreholeWallTemp:
            self.calcUniformBHWallTempGFunctionsWithGHEDesigner(state)
        elif self.gFuncCalcMethod == GFuncCalcMethod.FullDesign:
            pass

    def getCommonGHEDesignerInputs(self, state: EnergyPlusData) -> dict:
        gheDesignerInputs = {}
        gheDesignerInputs["version"] = 2
        gheDesignerInputs["topology"] = [{"type": "ground_heat_exchanger", "name": "ghe1"}]

        p = f"[G-Function Calculation for GHE Named: {self.name}] "

        if state.dataPlnt.PlantLoop[self.plantLoc.loopNum].FluidName == "WATER":
            gheDesignerInputs["fluid"] = {"fluid_name": "WATER", "concentration_percent": 0, "temperature": 20}
        elif state.dataPlnt.PlantLoop[self.plantLoc.loopNum].FluidName == "STEAM":
            ShowFatalError(state, p + "Detected steam loop, but GHEDesigner cannot run for a steam fluid loop, aborting.")
        else:
            thisGlycol = state.dataPlnt.PlantLoop[self.plantLoc.loopNum].glycol
            n = thisGlycol.GlycolName
            if n == "WATER" or n == "ETHYLENEGLYCOL" or n == "PROPYLENEGLYCOL":
                c = thisGlycol.Concentration
                if c > 0.6:
                    ShowWarningMessage(state, p + "EnergyPlus fluid concentration > 60% (GHEDesigner max), reducing to 60%, continuing")
                    c = 0.6
                gheDesignerInputs["fluid"] = {
                    "fluid_name": n,
                    "concentration_percent": c * 100.0,
                    "temperature": 20
                }
            else:
                ShowFatalError(state, p + "Could not identify glycol for setting up GHEDesigner run")

        return gheDesignerInputs

    @staticmethod
    def runGHEDesigner(state: EnergyPlusData, inputs: dict) -> Path:
        ghe_designer_input_file_path = state.dataStrGlobals.outDirPath / "eplus_ghedesigner_input.json"
        ghe_designer_output_directory = state.dataStrGlobals.outDirPath / "eplus_ghedesigner_outputs"

        if ghe_designer_input_file_path.exists():
            try:
                ghe_designer_input_file_path.unlink()
            except Exception as e:
                ShowFatalError(state, f"Failed to remove existing GHEDesigner input: {e}")

        try:
            with open(ghe_designer_input_file_path, 'w') as f:
                json.dump(inputs, f)
        except Exception as e:
            ShowFatalError(state, f"Failed to create file: {ghe_designer_input_file_path}: {e}")

        DisplayString(state, "Starting up GHEDesigner")

        if state.dataGlobal.installRootOverride:
            exePath = state.dataStrGlobals.exeDirectoryPath / "energyplus"
        else:
            exePath = FileSystem.getAbsolutePath(FileSystem.getProgramPath())
            exePath = exePath.parent / ("energyplus" + FileSystem.exeExtension)

        cmd = f'"{exePath}" auxiliary ghedesigner "{ghe_designer_input_file_path}" "{ghe_designer_output_directory}"'
        status = FileSystem.systemCall(cmd)
        if status != 0:
            ShowFatalError(state, "GHEDesigner failed to calculate G-functions.")
        DisplayString(state, "GHEDesigner complete")
        return ghe_designer_output_directory

    def performBoreholeFieldDesignAndSizingWithGHEDesigner(self, state: EnergyPlusData, hourlyLoads: list[float]):
        gheDesignerInputs = self.getCommonGHEDesignerInputs(state)

        grout = {"conductivity": self.grout.k, "rho_cp": self.grout.rhoCp}
        soil = {
            "conductivity": self.soil.k,
            "rho_cp": self.soil.rhoCp,
            "undisturbed_temp": self.tempGround,
        }
        shankSpacingForGHEDesigner = self.bhUTubeDist - self.pipe.outDia
        pipe = {
            "inner_diameter": self.pipe.innerDia,
            "outer_diameter": self.pipe.outDia,
            "shank_spacing": shankSpacingForGHEDesigner,
            "roughness": 0.000001,
            "conductivity": self.pipe.k,
            "rho_cp": self.pipe.rhoCp,
            "arrangement": "SINGLEUTUBE"
        }
        borehole = {
            "buried_depth": self.myRespFactors.props.bhTopDepth,
            "diameter": self.bhDiameter
        }

        geometricConstraints = {
            "length": self.sizingData.length,
            "width": self.sizingData.width,
            "b_min": self.sizingData.minSpacing,
            "b_max": self.sizingData.maxSpacing,
            "method": "RECTANGLE",
        }
        design = {
            "max_eft": self.sizingData.maxEFT,
            "min_eft": self.sizingData.minEFT,
            "max_height": self.sizingData.maxLength,
            "min_height": self.sizingData.minLength,
            "max_boreholes": self.sizingData.numBoreholes,
        }

        loads = {"load_values": hourlyLoads}

        ghe1 = {
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
            "sizing_run": False,
            "hourly_run": False,
            "sizing_months": 240
        }

        ghe_designer_output_directory = self.runGHEDesigner(state, gheDesignerInputs)
        output_json_file = ghe_designer_output_directory / "SimulationSummary.json"
        if not output_json_file.exists():
            ShowFatalError(state, "Although GHEDesigner appeared successful, the output file was not found, aborting ")
        output_borefield_file = ghe_designer_output_directory / "BoreFieldData.csv"
        if not output_borefield_file.exists():
            ShowFatalError(state, "Although GHEDesigner appeared successful, the output borefield file was not found, aborting ")

        found_length = 0.0
        try:
            with open(output_json_file) as f:
                data = json.load(f)
            found_length = data["ghe_system"]["active_borehole_length"]["value"]
        except Exception:
            ShowFatalError(state, "GHEDesigner completed, and output file found, but could not parse JSON")

        x, y = [], []
        try:
            with open(output_borefield_file) as f:
                next(f)
                for line in f:
                    if not line.strip():
                        continue
                    parts = line.strip().split(',')
                    try:
                        x.append(float(parts[0]))
                        y.append(float(parts[1]))
                    except (ValueError, IndexError):
                        ShowFatalError(state, "Bad data in GHEDesigner borefield results")
        except Exception:
            ShowFatalError(state, f"Could not open file: {output_borefield_file}")

        preDesigned = {"arrangement": "MANUAL", "H": found_length, "x": x, "y": y}
        ghe1["pre_designed"] = preDesigned
        del ghe1["geometric_constraints"]
        del ghe1["design"]
        del ghe1["loads"]
        gheDesignerInputs["ground_heat_exchanger"]["ghe1"] = ghe1

        ghe_designer_output_directory2 = self.runGHEDesigner(state, gheDesignerInputs)
        output_json_file2 = ghe_designer_output_directory2 / "SimulationSummary.json"
        if not output_json_file2.exists():
            ShowFatalError(state, "Although GHEDesigner appeared successful, the output file was not found, aborting ")

        try:
            with open(output_json_file2) as f:
                data = json.load(f)
            t = data["log_time"]
            g = data["g_values"]
            self.myRespFactors.time = t
            self.myRespFactors.LNTTS = t
            self.myRespFactors.GFNC = g
        except Exception:
            ShowFatalError(state, "GHEDesigner completed, and output file found, but could not parse JSON")

        oss = " ".join([f"({x[i]} {y[i]})" for i in range(len(x))])
        BaseSizer.reportSizerStrOutput(state, "GroundHeatExchanger:System", self.name, "Borehole Field Locations (x1 y1) (x2 y2) ...", oss)

    def calcUniformBHWallTempGFunctionsWithGHEDesigner(self, state: EnergyPlusData):
        gheDesignerInputs = self.getCommonGHEDesignerInputs(state)

        p = f"[GHEDesigner Calculation for GHE Named: {self.name}] "

        bhs = self.myRespFactors.myBorholes
        reference = bhs[0]
        allMatch = all(abs(bh.props.bhLength - reference.props.bhLength) <= 0.01 for bh in bhs)
        if not allMatch:
            ShowFatalError(state, p + "Multiple borehole heights in EnergyPlus inputs, g-function generation requires uniform, aborting")
        height = self.myRespFactors.myBorholes[0].props.bhLength

        grout = {"conductivity": self.grout.k, "rho_cp": self.grout.rhoCp}
        soil = {
            "conductivity": self.soil.k,
            "rho_cp": self.soil.rhoCp,
            "undisturbed_temp": self.tempGround,
        }
        shankSpacingForGHEDesigner = self.bhUTubeDist - self.pipe.outDia
        pipe = {
            "inner_diameter": self.pipe.innerDia,
            "outer_diameter": self.pipe.outDia,
            "shank_spacing": shankSpacingForGHEDesigner,
            "roughness": 0.000001,
            "conductivity": self.pipe.k,
            "rho_cp": self.pipe.rhoCp,
            "arrangement": "SINGLEUTUBE"
        }
        borehole = {
            "buried_depth": self.myRespFactors.props.bhTopDepth,
            "diameter": self.bhDiameter
        }

        x, y = [], []
        for bh in self.myRespFactors.myBorholes:
            x.append(bh.xLoc)
            y.append(bh.yLoc)
        preDesigned = {"arrangement": "MANUAL", "H": height, "x": x, "y": y}

        ghe1 = {
            "flow_rate": self.designMassFlow,
            "flow_type": "SYSTEM",
            "grout": grout,
            "soil": soil,
            "pipe": pipe,
            "borehole": borehole,
            "pre_designed": preDesigned
        }
        gheDesignerInputs["ground_heat_exchanger"] = {"ghe1": ghe1}

        ghe_designer_output_directory = self.runGHEDesigner(state, gheDesignerInputs)

        output_json_file = ghe_designer_output_directory / "SimulationSummary.json"
        if not output_json_file.exists():
            ShowFatalError(state, "Although GHEDesigner appeared successful, the output file was not found, aborting ")

        try:
            with open(output_json_file) as f:
                data = json.load(f)
            t = data["log_time"]
            g = data["g_values"]
            gbhw = data["g_bhw_values"]
            self.myRespFactors.time = t
            self.myRespFactors.LNTTS = t
            self.myRespFactors.GFNC = g
        except Exception:
            ShowFatalError(state, "GHEDesigner completed, and output file found, but could not parse JSON")

    def calcGFunctions(self, state: EnergyPlusData):
        self.setupTimeVectors()
        self.calcShortTimestepGFunctions(state)
        self.calcLongTimestepGFunctions(state)
        self.combineShortAndLongTimestepGFunctions()

    def setupTimeVectors(self):
        lntts_min_for_long_timestep = -8.5
        t_s = pow_2(self.bhLength) / (9 * self.soil.diffusivity)

        tempLNTTS = [lntts_min_for_long_timestep]

        while True:
            maxPossibleSimTime = math.exp(tempLNTTS[-1]) * t_s
            numDaysInYear = 365
            if maxPossibleSimTime < self.myRespFactors.maxSimYears * numDaysInYear * Constant.rHoursInDay * Constant.rSecsInHour:
                lnttsStepSize = 0.5
                tempLNTTS.append(tempLNTTS[-1] + lnttsStepSize)
            else:
                break

        self.myRespFactors.LNTTS = tempLNTTS
        self.myRespFactors.time = [math.exp(c) * t_s for c in tempLNTTS]
        self.myRespFactors.GFNC = [0.0] * len(tempLNTTS)

    def calcUniformHeatFluxGFunctions(self, state: EnergyPlusData):
        DisplayString(state, "Initializing GroundHeatExchanger:System: " + self.name)

        for lntts_index in range(len(self.myRespFactors.LNTTS)):
            for bh_i in self.myRespFactors.myBorholes:
                sum_T_ji = 0
                for bh_j in self.myRespFactors.myBorholes:
                    sum_T_ji += self.doubleIntegral(bh_i, bh_j, self.myRespFactors.time[lntts_index])
                self.myRespFactors.GFNC[lntts_index] += sum_T_ji
            self.myRespFactors.GFNC[lntts_index] /= (2 * self.totalTubeLength)

            progress = (lntts_index / len(self.myRespFactors.LNTTS)) * 100.0
            DisplayString(state, f"...progress: {progress:.1f}%")

    def calcShortTimestepGFunctions(self, state: EnergyPlusData):
        maxTSinHr = 6

        @dataclass
        class Cell:
            type: int = 0
            radius_center: float = 0.0
            radius_outer: float = 0.0
            radius_inner: float = 0.0
            thickness: float = 0.0
            vol: float = 0.0
            conductivity: float = 0.0
            rhoCp: float = 0.0
            temperature: float = 0.0
            temperature_prev_ts: float = 0.0

        FLUID = 0
        CONVECTION = 1
        PIPE = 2
        GROUT = 3
        SOIL = 4

        Cells = []

        num_pipe_cells = 4
        num_conv_cells = 1
        num_fluid_cells = 3
        pipe_thickness = self.pipe.thickness
        pcf_cell_thickness = pipe_thickness / num_pipe_cells
        radius_pipe_out = math.sqrt(2) * self.pipe.outRadius
        radius_pipe_in = radius_pipe_out - pipe_thickness
        radius_conv = radius_pipe_in - num_conv_cells * pcf_cell_thickness
        radius_fluid = radius_conv - (num_fluid_cells - 0.5) * pcf_cell_thickness

        num_grout_cells = 27
        radius_grout = self.bhRadius
        grout_cell_thickness = (radius_grout - radius_pipe_out) / num_grout_cells

        num_soil_cells = 500
        radius_soil = 10.0
        soil_cell_thickness = (radius_soil - radius_grout) / num_soil_cells

        self.massFlowRate = self.designMassFlow

        bhResistance = self.calcBHAverageResistance(state)
        bhConvectionResistance = self.calcPipeConvectionResistance(state)
        bh_equivalent_resistance_tube_grout = bhResistance - bhConvectionResistance / 2.0
        bh_equivalent_resistance_convection = bhResistance - bh_equivalent_resistance_tube_grout

        initial_temperature = self.inletTemp
        cpFluid_init = state.dataPlnt.PlantLoop[self.plantLoc.loopNum].glycol.getSpecificHeat(state, initial_temperature, "calcShortTimestepGFunctions")
        fluidDensity_init = state.dataPlnt.PlantLoop[self.plantLoc.loopNum].glycol.getDensity(state, initial_temperature, "calcShortTimestepGFunctions")

        for i in range(num_fluid_cells):
            thisCell = Cell()
            thisCell.type = FLUID
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

        for i in range(num_conv_cells):
            thisCell = Cell()
            thisCell.thickness = pcf_cell_thickness
            thisCell.radius_inner = radius_conv + i * thisCell.thickness
            thisCell.radius_center = thisCell.radius_inner + thisCell.thickness / 2.0
            thisCell.radius_outer = thisCell.radius_inner + thisCell.thickness
            thisCell.conductivity = math.log(radius_pipe_in / radius_conv) / (2 * Constant.Pi * bh_equivalent_resistance_convection)
            thisCell.rhoCp = 1
            Cells.append(thisCell)

        for i in range(num_pipe_cells):
            thisCell = Cell()
            thisCell.type = PIPE
            thisCell.thickness = pcf_cell_thickness
            thisCell.radius_inner = radius_pipe_in + i * thisCell.thickness
            thisCell.radius_center = thisCell.radius_inner + thisCell.thickness / 2.0
            thisCell.radius_outer = thisCell.radius_inner + thisCell.thickness
            thisCell.conductivity = math.log(radius_grout / radius_pipe_in) / (2 * Constant.Pi * bh_equivalent_resistance_tube_grout)
            thisCell.rhoCp = self.pipe.rhoCp
            Cells.append(thisCell)

        for i in range(num_grout_cells):
            thisCell = Cell()
            thisCell.type = GROUT
            thisCell.thickness = grout_cell_thickness
            thisCell.radius_inner = radius_pipe_out + i * thisCell.thickness
            thisCell.radius_center = thisCell.radius_inner + thisCell.thickness / 2.0
            thisCell.radius_outer = thisCell.radius_inner + thisCell.thickness
            thisCell.conductivity = math.log(radius_grout / radius_pipe_in) / (2 * Constant.Pi * bh_equivalent_resistance_tube_grout)
            thisCell.rhoCp = self.grout.rhoCp
            Cells.append(thisCell)

        for i in range(num_soil_cells):
            thisCell = Cell()
            thisCell.type = SOIL
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

        lntts_max_for_short_timestep = -8.6
        t_s = pow_2(self.bhLength) / (9.0 * self.soil.diffusivity)

        time_max_for_short_timestep = math.exp(lntts_max_for_short_timestep) * t_s
        total_time = 0.0

        while total_time < time_max_for_short_timestep:
            heat_flux = 1.0
            time_step = 120

            for thisCell in Cells:
                thisCell.temperature_prev_ts = thisCell.temperature

            a = []
            b = []
            c = []
            d = []

            num_cells = len(Cells)
            for cell_index in range(num_cells):
                if cell_index == 0:
                    thisCell = Cells[cell_index]
                    eastCell = Cells[cell_index + 1]

                    FE1 = math.log(thisCell.radius_outer / thisCell.radius_center) / (2 * Constant.Pi * thisCell.conductivity)
                    FE2 = math.log(eastCell.radius_center / eastCell.radius_inner) / (2 * Constant.Pi * eastCell.conductivity)
                    AE = 1 / (FE1 + FE2)

                    AD = thisCell.rhoCp * thisCell.vol / time_step

                    a.append(0)
                    b.append(-AE / AD - 1)
                    c.append(AE / AD)
                    d.append(-thisCell.temperature_prev_ts - heat_flux / AD)

                elif cell_index == num_cells - 1:
                    thisCell = Cells[cell_index]

                    a.append(0)
                    b.append(1)
                    c.append(0)
                    d.append(thisCell.temperature_prev_ts)

                else:
                    westCell = Cells[cell_index - 1]
                    eastCell = Cells[cell_index + 1]
                    thisCell = Cells[cell_index]

                    FE1 = math.log(thisCell.radius_outer / thisCell.radius_center) / (2 * Constant.Pi * thisCell.conductivity)
                    FE2 = math.log(eastCell.radius_center / eastCell.radius_inner) / (2 * Constant.Pi * eastCell.conductivity)
                    AE = 1 / (FE1 + FE2)

                    FW1 = math.log(westCell.radius_outer / westCell.radius_center) / (2 * Constant.Pi * westCell.conductivity)
                    FW2 = math.log(thisCell.radius_center / thisCell.radius_inner) / (2 * Constant.Pi * thisCell.conductivity)
                    AW = -1 / (FW1 + FW2)

                    AD = thisCell.rhoCp * thisCell.vol / time_step

                    a.append(-AW / AD)
                    b.append(AW / AD - AE / AD - 1)
                    c.append(AE / AD)
                    d.append(-thisCell.temperature_prev_ts)

            new_temps = TDMA(a, b, c, d)

            for cell_index in range(num_cells):
                Cells[cell_index].temperature = new_temps[cell_index]

            total_time += time_step

            self.GFNC_shortTimestep.append(2 * Constant.Pi * self.soil.k * ((Cells[0].temperature - initial_temperature) / heat_flux - bhResistance))
            self.LNTTS_shortTimestep.append(math.log(total_time / t_s))

    def calcBHAverageResistance(self, state: EnergyPlusData) -> float:
        beta = 2 * Constant.Pi * self.grout.k * self.calcPipeResistance(state)

        final_term_1 = math.log(self.theta_2 / (2 * self.theta_1 * pow(1 - pow_4(self.theta_1), self.sigma)))
        num_final_term_2 = pow_2(self.theta_3) * pow_2(1 - (4 * self.sigma * pow_4(self.theta_1)) / (1 - pow_4(self.theta_1)))
        den_final_term_2_pt_1 = (1 + beta) / (1 - beta)
        den_final_term_2_pt_2 = pow_2(self.theta_3) * (1 + (16 * self.sigma * pow_4(self.theta_1)) / pow_2(1 - pow_4(self.theta_1)))
        den_final_term_2 = den_final_term_2_pt_1 + den_final_term_2_pt_2
        final_term_2 = num_final_term_2 / den_final_term_2

        return 1 / (4 * Constant.Pi * self.grout.k) * (beta + final_term_1 - final_term_2)

    def calcBHTotalInternalResistance(self, state: EnergyPlusData) -> float:
        beta = 2 * Constant.Pi * self.grout.k * self.calcPipeResistance(state)

        final_term_1 = math.log(pow(1 + pow_2(self.theta_1), self.sigma) / (self.theta_3 * pow(1 - pow_2(self.theta_1), self.sigma)))
        num_term_2 = pow_2(self.theta_3) * pow_2(1 - pow_4(self.theta_1) + 4 * self.sigma * pow_2(self.theta_1))
        den_term_2_pt_1 = (1 + beta) / (1 - beta) * pow_2(1 - pow_4(self.theta_1))
        den_term_2_pt_2 = pow_2(self.theta_3) * pow_2(1 - pow_4(self.theta_1))
        den_term_2_pt_3 = 8 * self.sigma * pow_2(self.theta_1) * pow_2(self.theta_3) * (1 + pow_4(self.theta_1))
        den_term_2 = den_term_2_pt_1 - den_term_2_pt_2 + den_term_2_pt_3
        final_term_2 = num_term_2 / den_term_2

        return 1 / (Constant.Pi * self.grout.k) * (beta + final_term_1 - final_term_2)

    def calcBHGroutResistance(self, state: EnergyPlusData) -> float:
        return self.calcBHAverageResistance(state) - self.calcPipeResistance(state) / 2.0

    def calcHXResistance(self, state: EnergyPlusData) -> float:
        if self.massFlowRate <= 0.0:
            return 0
        cpFluid = state.dataPlnt.PlantLoop[self.plantLoc.loopNum].glycol.getSpecificHeat(state, self.inletTemp, "calcBHResistance")
        return self.calcBHAverageResistance(state) + 1 / (3 * self.calcBHTotalInternalResistance(state)) * pow_2(self.bhLength / (self.massFlowRate * cpFluid))

    def calcPipeConductionResistance(self) -> float:
        return math.log(self.pipe.outDia / self.pipe.innerDia) / (2 * Constant.Pi * self.pipe.k)

    def calcPipeConvectionResistance(self, state: EnergyPlusData) -> float:
        self.inletTemp = state.dataLoopNodes.Node[self.inletNodeNum].Temp

        cpFluid = state.dataPlnt.PlantLoop[self.plantLoc.loopNum].glycol.getSpecificHeat(state, self.inletTemp, "calcPipeConvectionResistance")
        kFluid = state.dataPlnt.PlantLoop[self.plantLoc.loopNum].glycol.getConductivity(state, self.inletTemp, "calcPipeConvectionResistance")
        fluidViscosity = state.dataPlnt.PlantLoop[self.plantLoc.loopNum].glycol.getViscosity(state, self.inletTemp, "calcPipeConvectionResistance")

        lower_limit = 2000.0
        upper_limit = 4000.0

        bhMassFlowRate = self.massFlowRate / self.myRespFactors.numBoreholes
        reynoldsNum = 4 * bhMassFlowRate / (fluidViscosity * Constant.Pi * self.pipe.innerDia)

        nusseltNum = 0.0
        if reynoldsNum < lower_limit:
            nusseltNum = 4.01
        elif reynoldsNum < upper_limit:
            nu_low = 4.01
            f = self.frictionFactor(reynoldsNum)
            prandtlNum = (cpFluid * fluidViscosity) / kFluid
            nu_high = (f / 8) * (reynoldsNum - 1000) * prandtlNum / (1 + 12.7 * math.sqrt(f / 8) * (pow(prandtlNum, 2.0 / 3.0) - 1))
            sf = 1 / (1 + math.exp(-(reynoldsNum - 3000) / 150.0))
            nusseltNum = (1 - sf) * nu_low + sf * nu_high
        else:
            f = self.frictionFactor(reynoldsNum)
            prandtlNum = (cpFluid * fluidViscosity) / kFluid
            nusseltNum = (f / 8) * (reynoldsNum - 1000) * prandtlNum / (1 + 12.7 * math.sqrt(f / 8) * (pow(prandtlNum, 2.0 / 3.0) - 1))

        h = nusseltNum * kFluid / self.pipe.innerDia

        return 1 / (h * Constant.Pi * self.pipe.innerDia)

    @staticmethod
    def frictionFactor(reynoldsNum: float) -> float:
        lower_limit = 1500.0
        upper_limit = 5000.0

        if reynoldsNum < lower_limit:
            return 64.0 / reynoldsNum
        if reynoldsNum < upper_limit:
            f_low = 64.0 / reynoldsNum
            f_high = pow(0.79 * math.log(reynoldsNum) - 1.64, -2.0)
            sf = 1 / (1 + math.exp(-(reynoldsNum - 3000.0) / 450.0))
            return (1 - sf) * f_low + sf * f_high
        return pow(0.79 * math.log(reynoldsNum) - 1.64, -2.0)

    def calcPipeResistance(self, state: EnergyPlusData) -> float:
        return self.calcPipeConductionResistance() + self.calcPipeConvectionResistance(state)

    def getGFunc(self, time: float) -> float:
        LNTTS = math.log(time)
        gFuncVal = self.interpGFunc(LNTTS)
        RATIO = self.bhRadius / self.bhLength

        if RATIO != self.myRespFactors.gRefRatio:
            gFuncVal -= math.log(self.bhRadius / (self.bhLength * self.myRespFactors.gRefRatio))

        return gFuncVal

    def initGLHESimVars(self, state: EnergyPlusData):
        currTime = ((state.dataGlobal.DayOfSim - 1) * 24 + (state.dataGlobal.HourOfDay - 1) +
                    (state.dataGlobal.TimeStep - 1) * state.dataGlobal.TimeStepZone + state.dataHVACGlobal.SysTimeElapsed) * Constant.rSecsInHour

        if self.myEnvrnFlag and state.dataGlobal.BeginEnvrnFlag:
            self.initEnvironment(state, currTime)

        minDepth = self.myRespFactors.props.bhTopDepth
        maxDepth = self.myRespFactors.props.bhLength + minDepth
        oneQuarterDepth = minDepth + (maxDepth - minDepth) * 0.25
        halfDepth = minDepth + (maxDepth - minDepth) * 0.5
        threeQuarterDepth = minDepth + (maxDepth - minDepth) * 0.75

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

    def initEnvironment(self, state: EnergyPlusData, CurTime: float):
        self.myEnvrnFlag = False

        fluidDensity = state.dataPlnt.PlantLoop[self.plantLoc.loopNum].glycol.getDensity(state, 20.0, "initEnvironment")
        self.designMassFlow = self.designFlow * fluidDensity
        PlantUtilities.InitComponentNodes(state, 0.0, self.designMassFlow, self.inletNodeNum, self.outletNodeNum)

        self.lastQnSubHr = 0.0
        state.dataLoopNodes.Node[self.inletNodeNum].Temp = self.tempGround
        state.dataLoopNodes.Node[self.outletNodeNum].Temp = self.tempGround

        self.QnHr = [0.0] * len(self.QnHr)
        self.QnMonthlyAgg = [0.0] * len(self.QnMonthlyAgg)
        self.QnSubHr = [0.0] * len(self.QnSubHr)
        self.LastHourN = [0] * len(self.LastHourN)
        self.prevTimeSteps = [0.0] * len(self.prevTimeSteps)
        self.currentSimTime = 0.0
        self.QGLHE = 0.0
        self.prevHour = 1

    def oneTimeInit_new(self, state: EnergyPlusData):
        errFlag = False
        PlantUtilities.ScanPlantLoopsForObject(
            state, self.name, DataPlant.PlantEquipmentType.GrndHtExchgSystem, self.plantLoc, errFlag
        )
        if errFlag:
            ShowFatalError(state, "initGLHESimVars: Program terminated due to previous condition(s).")

    def oneTimeInit(self, state: EnergyPlusData):
        pass


class Util:
    @staticmethod
    def makeUPPER(s: str) -> str:
        return s.upper()


class Node:
    class ConnectionObjectType:
        GroundHeatExchangerSystem = 0

    class FluidType:
        Water = 0

    class ConnectionType:
        Inlet = 0
        Outlet = 1

    class CompFluidStream:
        Primary = 0

    class ObjectIsNotParent:
        pass

    @staticmethod
    def GetOnlySingleNode(state, node_name, errors_found, obj_type, obj_name, fluid_type, conn_type, comp_fluid, is_parent):
        pass

    @staticmethod
    def TestCompSet(state, module_name, obj_name, inlet_name, outlet_name, description):
        pass


class PlantUtilities:
    @staticmethod
    def RegisterPlantCompDesignFlow(state, node_num, design_flow):
        pass

    @staticmethod
    def RegulateCondenserCompFlowReqOp(state, plant_loc, design_mass_flow):
        return design_mass_flow

    @staticmethod
    def SetComponentFlowRate(state, mass_flow_rate, inlet_node, outlet_node, plant_loc):
        pass

    @staticmethod
    def ScanPlantLoopsForObject(state, name, eq_type, plant_loc, err_flag):
        pass

    @staticmethod
    def InitComponentNodes(state, min_flow, max_flow, inlet_node, outlet_node):
        pass


class FileSystem:
    exeExtension = ""

    @staticmethod
    def getAbsolutePath(path):
        return Path(path)

    @staticmethod
    def getProgramPath():
        return "."

    @staticmethod
    def toString(path):
        return str(path)

    @staticmethod
    def toGenericString(path):
        return str(path).replace("\\", "/")

    @staticmethod
    def systemCall(cmd):
        result = subprocess.run(cmd, shell=True)
        return result.returncode


class BaseSizer:
    @staticmethod
    def reportSizerStrOutput(state, comp_type, comp_name, field_name, value):
        pass


class Constant:
    Pi = 3.141592653589793
    rSecsInHour = 1.0 / 3600.0
    rHoursInDay = 1.0 / 24.0


class DataPlant:
    class PlantEquipmentType:
        GrndHtExchgSystem = 0


class DisplayString:
    @staticmethod
    def __call__(state, msg):
        pass


def DisplayString(state, msg):
    pass


def ShowFatalError(state, msg):
    raise RuntimeError(msg)


def ShowWarningMessage(state, msg):
    pass


def ShowSevereError(state, msg):
    pass


def ShowContinueError(state, msg):
    pass


def GetResponseFactor(state, name):
    pass


def BuildAndGetResponseFactorObjectFromArray(state, array):
    pass


def BuildAndGetResponseFactorsObjectFromSingleBHs(state, bh_list):
    pass


class GLHEVertArray:
    @staticmethod
    def GetVertArray(state, name):
        pass


class GroundTemp:
    @staticmethod
    def GetGroundTempModelAndInit(state, model_type, model_name):
        pass
