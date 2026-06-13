from math import exp, log, sqrt, cos, abs, pow
from Array1D import Array1D_bool
from DataGlobals import *
from DataEnvironment import *
from DataHVACGlobals import *
from DataHeatBalance import *
from EarthTube import *
from InputProcessor import *
from OutputProcessor import *
from Psychrometrics import *
from ScheduleManager import *
from UtilityRoutines import *
from ZoneTempPredictorCorrector import *
from EnergyPlusData import EnergyPlusData
from BaseData import BaseGlobalStruct, EPVector

enum SoilType(Int):
    Invalid = -1
    HeavyAndSat = 0
    HeavyAndDamp = 1
    HeavyAndDry = 2
    LightAndDry = 3
    Num = 4

var totEarthTube: Int = 0

var ventilationNamesUC: StaticTuple[StringRef, 3] = StaticTuple[StringRef, 3]("NATURAL", "INTAKE", "EXHAUST")
var soilTypeNamesUC: StaticTuple[StringRef, 4] = StaticTuple[StringRef, 4]("HEAVYANDSATURATED", "HEAVYANDDAMP", "HEAVYANDDRY", "LIGHTANDDRY")
var solutionTypeNamesUC: StaticTuple[StringRef, 2] = StaticTuple[StringRef, 2]("BASIC", "VERTICAL")

def ManageEarthTube(state: EnergyPlusData):
    if state.dataEarthTube.GetInputFlag:
        var ErrorsFound: Bool = False
        GetEarthTube(state, ErrorsFound)
        state.dataEarthTube.GetInputFlag = False
    if state.dataEarthTube.EarthTubeSys.size() == 0:
        return
    initEarthTubeVertical(state)
    CalcEarthTube(state)
    ReportEarthTube(state)

def GetEarthTube(state: EnergyPlusData, ErrorsFound: Bool):
    var routineName: StringRef = "GetEarthTube"
    var EarthTubeTempLimit: Float64 = 100.0
    var earthTubeParametersModuleObject: String = "ZoneEarthtube:Parameters"
    var earthTubeModuleObject: String = "ZoneEarthtube"
    var earthTubeModelParametersNameFieldName: StringRef = "Earth Tube Model Parameters Name"
    var zoneNameFieldName: StringRef = "Zone Name"
    var scheduleNameFieldName: StringRef = "Schedule Name"
    var numericFieldNames: StaticTuple[StringRef, 18] = StaticTuple[StringRef, 18](
        "Design Flow Rate",
        "Minimum Zone Temperature when Cooling",
        "Maximum Zone Temperature when Heating",
        "Delta Temperature",
        "Fan Pressure Rise",
        "Fan Total Efficiency",
        "Pipe Radius",
        "Pipe Thickness",
        "Pipe Length",
        "Pipe Thermal Conductivity",
        "Pipe Depth Under Ground Surface",
        "Average Soil Surface Temperature",
        "Amplitude of Soil Surface Temperature",
        "Phase Constant of Soil Surface Temperature",
        "Constant Term Flow Coefficient",
        "Temperature Term Flow Coefficient",
        "Velocity Term Flow Coefficient",
        "Velocity Squared Term Flow Coefficient"
    )
    var Loop: Int
    var RepVarSet = Array1D_bool()
    RepVarSet.dimension(state.dataGlobal.NumOfZones, True)
    state.dataEarthTube.ZnRptET.allocate(state.dataGlobal.NumOfZones)
    var inputProcessor = state.dataInputProcessing.inputProcessor
    var totEarthTubePars: Int = inputProcessor.getNumObjectsFound(state, earthTubeParametersModuleObject)
    state.dataEarthTube.EarthTubePars.allocate(totEarthTubePars)
    var earthTubeParametersSchemaProps = inputProcessor.getObjectSchemaProps(state, earthTubeParametersModuleObject)
    var earthTubeParameterObjects = inputProcessor.epJSON.find(earthTubeParametersModuleObject)
    Loop = 0
    if earthTubeParameterObjects != inputProcessor.epJSON.end():
        for earthTubeParameterInstance in earthTubeParameterObjects.value().items():
            Loop += 1
            var thisEarthTubePars = state.dataEarthTube.EarthTubePars[Loop - 1]
            var earthTubeParameterFields = earthTubeParameterInstance.value()
            thisEarthTubePars.nameParameters = inputProcessor.getAlphaFieldValue(earthTubeParameterFields, earthTubeParametersSchemaProps, "earth_tube_model_parameters_name")
            inputProcessor.markObjectAsUsed(earthTubeParametersModuleObject, earthTubeParameterInstance.key())
            for otherParams in range(1, Loop):
                if Util.SameString(thisEarthTubePars.nameParameters, state.dataEarthTube.EarthTubePars[otherParams - 1].nameParameters):
                    ShowSevereError(state, "{}: {} = {} is not a unique name.".format(earthTubeParametersModuleObject, earthTubeModelParametersNameFieldName, thisEarthTubePars.nameParameters))
                    ShowContinueError(state, "Check the other {} names for a duplicate.".format(earthTubeParametersModuleObject))
                    ErrorsFound = True
            thisEarthTubePars.numNodesAbove = inputProcessor.getIntFieldValue(earthTubeParameterFields, earthTubeParametersSchemaProps, "nodes_above_earth_tube")
            thisEarthTubePars.numNodesBelow = inputProcessor.getIntFieldValue(earthTubeParameterFields, earthTubeParametersSchemaProps, "nodes_below_earth_tube")
            thisEarthTubePars.dimBoundAbove = inputProcessor.getRealFieldValue(earthTubeParameterFields, earthTubeParametersSchemaProps, "earth_tube_dimensionless_boundary_above")
            thisEarthTubePars.dimBoundBelow = inputProcessor.getRealFieldValue(earthTubeParameterFields, earthTubeParametersSchemaProps, "earth_tube_dimensionless_boundary_below")
            thisEarthTubePars.width = inputProcessor.getRealFieldValue(earthTubeParameterFields, earthTubeParametersSchemaProps, "earth_tube_solution_space_width")
    totEarthTube = inputProcessor.getNumObjectsFound(state, earthTubeModuleObject)
    state.dataEarthTube.EarthTubeSys.allocate(totEarthTube)
    var earthTubeSchemaProps = inputProcessor.getObjectSchemaProps(state, earthTubeModuleObject)
    var earthTubeObjects = inputProcessor.epJSON.find(earthTubeModuleObject)
    var lastZoneName: String
    Loop = 0
    if earthTubeObjects != inputProcessor.epJSON.end():
        for earthTubeInstance in earthTubeObjects.value().items():
            Loop += 1
            var thisEarthTube = state.dataEarthTube.EarthTubeSys[Loop - 1]
            var earthTubeFields = earthTubeInstance.value()
            var zoneName = inputProcessor.getAlphaFieldValue(earthTubeFields, earthTubeSchemaProps, "zone_name")
            var scheduleName = inputProcessor.getAlphaFieldValue(earthTubeFields, earthTubeSchemaProps, "schedule_name")
            var earthTubeType = inputProcessor.getAlphaFieldValue(earthTubeFields, earthTubeSchemaProps, "earthtube_type")
            var soilCondition = inputProcessor.getAlphaFieldValue(earthTubeFields, earthTubeSchemaProps, "soil_condition")
            var earthTubeModelType = inputProcessor.getAlphaFieldValue(earthTubeFields, earthTubeSchemaProps, "earth_tube_model_type")
            var earthTubeModelParameters = inputProcessor.getAlphaFieldValue(earthTubeFields, earthTubeSchemaProps, "earth_tube_model_parameters")
            inputProcessor.markObjectAsUsed(earthTubeModuleObject, earthTubeInstance.key())
            var eoh = ErrorObjectHeader(routineName, earthTubeModuleObject, zoneName)
            lastZoneName = zoneName
            thisEarthTube.ZonePtr = Util.FindItemInList(zoneName, state.dataHeatBal.Zone)
            if thisEarthTube.ZonePtr == 0:
                ShowSevereError(state, "{}: {} not found={}".format(earthTubeModuleObject, zoneNameFieldName, zoneName))
                ErrorsFound = True
            if scheduleName.empty():
                ShowSevereEmptyField(state, eoh, scheduleNameFieldName)
                ErrorsFound = True
            elif (thisEarthTube.availSched = Sched.GetSchedule(state, scheduleName)) is None:
                ShowSevereItemNotFound(state, eoh, scheduleNameFieldName, scheduleName)
                ErrorsFound = True
            thisEarthTube.DesignLevel = inputProcessor.getRealFieldValue(earthTubeFields, earthTubeSchemaProps, "design_flow_rate")
            thisEarthTube.MinTemperature = inputProcessor.getRealFieldValue(earthTubeFields, earthTubeSchemaProps, "minimum_zone_temperature_when_cooling")
            if (thisEarthTube.MinTemperature < -EarthTubeTempLimit) or (thisEarthTube.MinTemperature > EarthTubeTempLimit):
                ShowSevereError(state, "{}: {}={} must have a minimum temperature between -{:.2f}C and {:.2f}C".format(earthTubeModuleObject, zoneNameFieldName, zoneName, EarthTubeTempLimit, EarthTubeTempLimit))
                ShowContinueError(state, "Entered value={:#G}".format(thisEarthTube.MinTemperature))
                ErrorsFound = True
            thisEarthTube.MaxTemperature = inputProcessor.getRealFieldValue(earthTubeFields, earthTubeSchemaProps, "maximum_zone_temperature_when_heating")
            if (thisEarthTube.MaxTemperature < -EarthTubeTempLimit) or (thisEarthTube.MaxTemperature > EarthTubeTempLimit):
                ShowSevereError(state, "{}: {}={} must have a maximum temperature between -{:.2f}C and {:.2f}C".format(earthTubeModuleObject, zoneNameFieldName, zoneName, EarthTubeTempLimit, EarthTubeTempLimit))
                ShowContinueError(state, "Entered value={:#G}".format(thisEarthTube.MaxTemperature))
                ErrorsFound = True
            thisEarthTube.DelTemperature = inputProcessor.getRealFieldValue(earthTubeFields, earthTubeSchemaProps, "delta_temperature")
            if earthTubeType.empty():
                thisEarthTube.FanType = Ventilation.Natural
            else:
                thisEarthTube.FanType = Ventilation(getEnumValue(ventilationNamesUC, earthTubeType))
                if thisEarthTube.FanType == Ventilation.Invalid:
                    ShowSevereInvalidKey(state, eoh, "Earthtube Type", earthTubeType)
                    ErrorsFound = True
            thisEarthTube.FanPressure = inputProcessor.getRealFieldValue(earthTubeFields, earthTubeSchemaProps, "fan_pressure_rise")
            if thisEarthTube.FanPressure < 0.0:
                ShowSevereError(state, "{}: {}={}, {} must be positive, entered value={:#G}".format(earthTubeModuleObject, zoneNameFieldName, zoneName, numericFieldNames[4], thisEarthTube.FanPressure))
                ErrorsFound = True
            thisEarthTube.FanEfficiency = inputProcessor.getRealFieldValue(earthTubeFields, earthTubeSchemaProps, "fan_total_efficiency")
            if (thisEarthTube.FanEfficiency <= 0.0) or (thisEarthTube.FanEfficiency > 1.0):
                ShowSevereError(state, "{}: {}={}, {} must be greater than zero and less than or equal to one, entered value={:#G}".format(earthTubeModuleObject, zoneNameFieldName, zoneName, numericFieldNames[5], thisEarthTube.FanEfficiency))
                ErrorsFound = True
            thisEarthTube.r1 = inputProcessor.getRealFieldValue(earthTubeFields, earthTubeSchemaProps, "pipe_radius")
            if thisEarthTube.r1 <= 0.0:
                ShowSevereError(state, "{}: {}={}, {} must be positive, entered value={:#G}".format(earthTubeModuleObject, zoneNameFieldName, zoneName, numericFieldNames[6], thisEarthTube.r1))
                ErrorsFound = True
            thisEarthTube.r2 = inputProcessor.getRealFieldValue(earthTubeFields, earthTubeSchemaProps, "pipe_thickness")
            if thisEarthTube.r2 <= 0.0:
                ShowSevereError(state, "{}: {}={}, {} must be positive, entered value={:#G}".format(earthTubeModuleObject, zoneNameFieldName, zoneName, numericFieldNames[7], thisEarthTube.r2))
                ErrorsFound = True
            thisEarthTube.r3 = 2.0 * thisEarthTube.r1
            thisEarthTube.PipeLength = inputProcessor.getRealFieldValue(earthTubeFields, earthTubeSchemaProps, "pipe_length")
            if thisEarthTube.PipeLength <= 0.0:
                ShowSevereError(state, "{}: {}={}, {} must be positive, entered value={:#G}".format(earthTubeModuleObject, zoneNameFieldName, zoneName, numericFieldNames[8], thisEarthTube.PipeLength))
                ErrorsFound = True
            thisEarthTube.PipeThermCond = inputProcessor.getRealFieldValue(earthTubeFields, earthTubeSchemaProps, "pipe_thermal_conductivity")
            if thisEarthTube.PipeThermCond <= 0.0:
                ShowSevereError(state, "{}: {}={}, {} must be positive, entered value={:#G}".format(earthTubeModuleObject, zoneNameFieldName, zoneName, numericFieldNames[9], thisEarthTube.PipeThermCond))
                ErrorsFound = True
            thisEarthTube.z = inputProcessor.getRealFieldValue(earthTubeFields, earthTubeSchemaProps, "pipe_depth_under_ground_surface")
            if thisEarthTube.z <= 0.0:
                ShowSevereError(state, "{}: {}={}, {} must be positive, entered value={:#G}".format(earthTubeModuleObject, zoneNameFieldName, zoneName, numericFieldNames[10], thisEarthTube.z))
                ErrorsFound = True
            if thisEarthTube.z <= (thisEarthTube.r1 + thisEarthTube.r2 + thisEarthTube.r3):
                ShowSevereError(state, "{}: {}={}, {} must be greater than 3*{} + {} entered value={:#G} ref sum={:#G}".format(earthTubeModuleObject, zoneNameFieldName, zoneName, numericFieldNames[10], numericFieldNames[6], numericFieldNames[7], thisEarthTube.z, thisEarthTube.r1 + thisEarthTube.r2 + thisEarthTube.r3))
                ErrorsFound = True
            var soilType: SoilType = SoilType(getEnumValue(soilTypeNamesUC, soilCondition))
            var thermalDiffusivity: StaticTuple[Float64, 4] = StaticTuple[Float64, 4](0.0781056, 0.055728, 0.0445824, 0.024192)
            var thermalConductivity: StaticTuple[Float64, 4] = StaticTuple[Float64, 4](2.42, 1.3, 0.865, 0.346)
            if soilType == SoilType.Invalid:
                ShowSevereInvalidKey(state, eoh, "Soil Condition", soilCondition)
                ErrorsFound = True
            else:
                thisEarthTube.SoilThermDiff = thermalDiffusivity[soilType.value()]
                thisEarthTube.SoilThermCond = thermalConductivity[soilType.value()]
            thisEarthTube.AverSoilSurTemp = inputProcessor.getRealFieldValue(earthTubeFields, earthTubeSchemaProps, "average_soil_surface_temperature")
            thisEarthTube.ApmlSoilSurTemp = inputProcessor.getRealFieldValue(earthTubeFields, earthTubeSchemaProps, "amplitude_of_soil_surface_temperature")
            thisEarthTube.SoilSurPhaseConst = Int(inputProcessor.getRealFieldValue(earthTubeFields, earthTubeSchemaProps, "phase_constant_of_soil_surface_temperature"))
            if thisEarthTube.FanType == Ventilation.Natural:
                thisEarthTube.FanPressure = 0.0
                thisEarthTube.FanEfficiency = 1.0
            thisEarthTube.ConstantTermCoef = inputProcessor.getRealFieldValue(earthTubeFields, earthTubeSchemaProps, "constant_term_flow_coefficient")
            thisEarthTube.TemperatureTermCoef = inputProcessor.getRealFieldValue(earthTubeFields, earthTubeSchemaProps, "temperature_term_flow_coefficient")
            thisEarthTube.VelocityTermCoef = inputProcessor.getRealFieldValue(earthTubeFields, earthTubeSchemaProps, "velocity_term_flow_coefficient")
            thisEarthTube.VelocitySQTermCoef = inputProcessor.getRealFieldValue(earthTubeFields, earthTubeSchemaProps, "velocity_squared_term_flow_coefficient")
            if earthTubeModelType.empty():
                thisEarthTube.ModelType = EarthTubeModelType.Basic
            else:
                thisEarthTube.ModelType = EarthTubeModelType(getEnumValue(solutionTypeNamesUC, earthTubeModelType))
                if thisEarthTube.ModelType == EarthTubeModelType.Invalid:
                    ShowSevereInvalidKey(state, eoh, "Earth Tube Model Type", earthTubeModelType)
                    ErrorsFound = True
            if thisEarthTube.ModelType == EarthTubeModelType.Vertical:
                thisEarthTube.r3 = 0.0
                thisEarthTube.vertParametersPtr = 0
                for parIndex in range(1, totEarthTubePars + 1):
                    if Util.SameString(earthTubeModelParameters, state.dataEarthTube.EarthTubePars[parIndex - 1].nameParameters):
                        thisEarthTube.vertParametersPtr = parIndex
                        break
                if thisEarthTube.vertParametersPtr == 0:
                    ShowSevereItemNotFound(state, eoh, "Earth Tube Model Parameters", earthTubeModelParameters)
                    ErrorsFound = True
            if thisEarthTube.ZonePtr > 0:
                if RepVarSet[thisEarthTube.ZonePtr - 1]:
                    RepVarSet[thisEarthTube.ZonePtr - 1] = False
                    var zone = state.dataHeatBal.Zone[thisEarthTube.ZonePtr - 1]
                    var thisZnRptET = state.dataEarthTube.ZnRptET[thisEarthTube.ZonePtr - 1]
                    SetupOutputVariable(state, "Earth Tube Zone Sensible Cooling Energy", Constant.Units.J, thisZnRptET.EarthTubeHeatLoss, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, zone.Name)
                    SetupOutputVariable(state, "Earth Tube Zone Sensible Cooling Rate", Constant.Units.W, thisZnRptET.EarthTubeHeatLossRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, zone.Name)
                    SetupOutputVariable(state, "Earth Tube Zone Sensible Heating Energy", Constant.Units.J, thisZnRptET.EarthTubeHeatGain, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, zone.Name)
                    SetupOutputVariable(state, "Earth Tube Zone Sensible Heating Rate", Constant.Units.W, thisZnRptET.EarthTubeHeatGainRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, zone.Name)
                    SetupOutputVariable(state, "Earth Tube Air Flow Volume", Constant.Units.m3, thisZnRptET.EarthTubeVolume, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, zone.Name)
                    SetupOutputVariable(state, "Earth Tube Current Density Air Volume Flow Rate", Constant.Units.m3_s, thisZnRptET.EarthTubeVolFlowRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, zone.Name)
                    SetupOutputVariable(state, "Earth Tube Standard Density Air Volume Flow Rate", Constant.Units.m3_s, thisZnRptET.EarthTubeVolFlowRateStd, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, zone.Name)
                    SetupOutputVariable(state, "Earth Tube Air Flow Mass", Constant.Units.kg, thisZnRptET.EarthTubeMass, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, zone.Name)
                    SetupOutputVariable(state, "Earth Tube Air Mass Flow Rate", Constant.Units.kg_s, thisZnRptET.EarthTubeMassFlowRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, zone.Name)
                    SetupOutputVariable(state, "Earth Tube Water Mass Flow Rate", Constant.Units.kg_s, thisZnRptET.EarthTubeWaterMassFlowRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, zone.Name)
                    SetupOutputVariable(state, "Earth Tube Fan Electricity Energy", Constant.Units.J, thisZnRptET.EarthTubeFanElec, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, zone.Name, Constant.eResource.Electricity, OutputProcessor.Group.Building)
                    SetupOutputVariable(state, "Earth Tube Fan Electricity Rate", Constant.Units.W, thisZnRptET.EarthTubeFanElecPower, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, zone.Name)
                    SetupOutputVariable(state, "Earth Tube Zone Inlet Air Temperature", Constant.Units.C, thisZnRptET.EarthTubeAirTemp, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, zone.Name)
                    SetupOutputVariable(state, "Earth Tube Ground Interface Temperature", Constant.Units.C, thisEarthTube.GroundTempt, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, zone.Name)
                    SetupOutputVariable(state, "Earth Tube Outdoor Air Heat Transfer Rate", Constant.Units.W, thisZnRptET.EarthTubeOATreatmentPower, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, zone.Name)
                    SetupOutputVariable(state, "Earth Tube Zone Inlet Wet Bulb Temperature", Constant.Units.C, thisZnRptET.EarthTubeWetBulbTemp, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, zone.Name)
                    SetupOutputVariable(state, "Earth Tube Zone Inlet Humidity Ratio", Constant.Units.kgWater_kgDryAir, thisZnRptET.EarthTubeHumRat, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, zone.Name)
    CheckEarthTubesInZones(state, lastZoneName, earthTubeModuleObject, ErrorsFound)
    if ErrorsFound:
        ShowFatalError(state, "{}: Errors getting input.  Program terminates.".format(earthTubeModuleObject))

def CheckEarthTubesInZones(state: EnergyPlusData, ZoneName: String, FieldName: StringRef, ErrorsFound: Bool):
    var numEarthTubes: Int = state.dataEarthTube.EarthTubeSys.size()
    for Loop in range(1, numEarthTubes):
        for Loop1 in range(Loop + 1, numEarthTubes + 1):
            if state.dataEarthTube.EarthTubeSys[Loop - 1].ZonePtr == state.dataEarthTube.EarthTubeSys[Loop1 - 1].ZonePtr:
                ShowSevereError(state, "{} has more than one {} associated with it.".format(ZoneName, FieldName))
                ShowContinueError(state, "Only one {} is allowed per zone.  Check the definitions of {}".format(FieldName, FieldName))
                ShowContinueError(state, "in your input file and make sure that there is only one defined for each zone.")
                ErrorsFound = True

def initEarthTubeVertical(state: EnergyPlusData):
    if state.dataEarthTube.initFirstTime:
        state.dataEarthTube.initFirstTime = False
        for etNum in range(1, totEarthTube + 1):
            var thisEarthTube = state.dataEarthTube.EarthTubeSys[etNum - 1]
            if thisEarthTube.ModelType != EarthTubeModelType.Vertical:
                continue
            var thisEarthTubeParams = state.dataEarthTube.EarthTubePars[thisEarthTube.vertParametersPtr - 1]
            thisEarthTube.totNodes = thisEarthTubeParams.numNodesAbove + thisEarthTubeParams.numNodesBelow + 1
            thisEarthTube.aCoeff = List[Float64](thisEarthTube.totNodes)
            thisEarthTube.bCoeff = List[Float64](thisEarthTube.totNodes)
            thisEarthTube.cCoeff = List[Float64](thisEarthTube.totNodes)
            thisEarthTube.cCoeff0 = List[Float64](thisEarthTube.totNodes)
            thisEarthTube.dCoeff = List[Float64](thisEarthTube.totNodes)
            thisEarthTube.cPrime = List[Float64](thisEarthTube.totNodes)
            thisEarthTube.dPrime = List[Float64](thisEarthTube.totNodes)
            thisEarthTube.cPrime0 = List[Float64](thisEarthTube.totNodes)
            thisEarthTube.tCurrent = List[Float64](thisEarthTube.totNodes)
            thisEarthTube.tLast = List[Float64](thisEarthTube.totNodes)
            thisEarthTube.depthNode = List[Float64](thisEarthTube.totNodes)
            thisEarthTube.tUndist = List[Float64](thisEarthTube.totNodes)
            var thickBase: Float64 = (thisEarthTube.z - 3.0 * thisEarthTube.r1)
            var thickTop: Float64 = thickBase * thisEarthTubeParams.dimBoundAbove / Float64(thisEarthTubeParams.numNodesAbove)
            var thickBottom: Float64 = thickBase * thisEarthTubeParams.dimBoundBelow / Float64(thisEarthTubeParams.numNodesBelow)
            var thickEarthTube: Float64 = 4.0 * thisEarthTube.r1
            var deltat: Float64 = state.dataGlobal.TimeStepZone
            var thermDiff: Float64 = thisEarthTube.SoilThermDiff / Constant.rHoursInDay
            var commonTerm: Float64 = thermDiff * deltat / (thickTop * thickTop)
            thisEarthTube.aCoeff[0] = 0.0
            thisEarthTube.bCoeff[0] = 1.0 + 3.0 * commonTerm
            thisEarthTube.cCoeff[0] = -1.0 * commonTerm
            thisEarthTube.dMult0 = 2.0 * commonTerm
            for nodeNum in range(1, thisEarthTubeParams.numNodesAbove - 1):
                thisEarthTube.aCoeff[nodeNum] = -1.0 * commonTerm
                thisEarthTube.bCoeff[nodeNum] = 1.0 + 2.0 * commonTerm
                thisEarthTube.cCoeff[nodeNum] = -1.0 * commonTerm
            var thisNode: Int = thisEarthTubeParams.numNodesAbove - 1
            var commonTerm2: Float64 = 2.0 * thermDiff * deltat / (thickTop + thickEarthTube) / thickTop
            thisEarthTube.aCoeff[thisNode] = -1.0 * commonTerm
            thisEarthTube.bCoeff[thisNode] = 1.0 + commonTerm + commonTerm2
            thisEarthTube.cCoeff[thisNode] = -1.0 * commonTerm2
            thisNode = thisEarthTubeParams.numNodesAbove
            commonTerm = 2.0 * thermDiff * deltat / (thickTop + thickEarthTube) / thickEarthTube
            commonTerm2 = 2.0 * thermDiff * deltat / (thickBottom + thickEarthTube) / thickEarthTube
            thisEarthTube.aCoeff[thisNode] = -1.0 * commonTerm
            thisEarthTube.bCoeff[thisNode] = 1.0 + commonTerm + commonTerm2
            thisEarthTube.cCoeff[thisNode] = -1.0 * commonTerm2
            thisNode = thisEarthTubeParams.numNodesAbove + 1
            commonTerm = thermDiff * deltat / (thickBottom * thickBottom)
            commonTerm2 = 2.0 * thermDiff * deltat / (thickBottom + thickEarthTube) / thickBottom
            thisEarthTube.aCoeff[thisNode] = -1.0 * commonTerm2
            thisEarthTube.bCoeff[thisNode] = 1.0 + commonTerm + commonTerm2
            thisEarthTube.cCoeff[thisNode] = -1.0 * commonTerm
            for nodeNum in range(thisNode + 1, thisEarthTube.totNodes - 1):
                thisEarthTube.aCoeff[nodeNum] = -1.0 * commonTerm
                thisEarthTube.bCoeff[nodeNum] = 1.0 + 2.0 * commonTerm
                thisEarthTube.cCoeff[nodeNum] = -1.0 * commonTerm
            thisNode = thisEarthTube.totNodes - 1
            thisEarthTube.aCoeff[thisNode] = -1.0 * commonTerm
            thisEarthTube.bCoeff[thisNode] = 1.0 + 3.0 * commonTerm
            thisEarthTube.cCoeff[thisNode] = 0.0
            thisEarthTube.dMultN = 2.0 * commonTerm
            thisEarthTube.depthNode[thisEarthTubeParams.numNodesAbove - 1] = thisEarthTube.z - 0.5 * (thickEarthTube + thickTop)
            for nodeNum in range(thisEarthTubeParams.numNodesAbove - 2, -1, -1):
                thisEarthTube.depthNode[nodeNum] = thisEarthTube.depthNode[nodeNum + 1] - thickTop
            thisEarthTube.depthNode[thisEarthTubeParams.numNodesAbove] = thisEarthTube.z
            thisEarthTube.depthNode[thisEarthTubeParams.numNodesAbove + 1] = thisEarthTube.z + 0.5 * (thickEarthTube + thickBottom)
            for nodeNumBelow in range(2, thisEarthTubeParams.numNodesBelow + 1):
                var nodeNum: Int = thisEarthTubeParams.numNodesAbove + nodeNumBelow
                thisEarthTube.depthNode[nodeNum] = thisEarthTube.depthNode[nodeNum - 1] + thickBottom
            thisEarthTube.depthUpperBound = thisEarthTube.depthNode[0] - 0.5 * thickTop
            thisEarthTube.depthLowerBound = thisEarthTube.depthNode[thisEarthTube.totNodes - 1] + 0.5 * thickBottom
            thisEarthTube.airFlowCoeff = state.dataGlobal.TimeStepZone * thermDiff / thisEarthTube.SoilThermCond / thickEarthTube / thisEarthTubeParams.width / thisEarthTube.PipeLength
            for nodeNum in range(thisEarthTube.totNodes):
                thisEarthTube.cCoeff0[nodeNum] = thisEarthTube.cCoeff[nodeNum]
            thisEarthTube.initCPrime0()
            var zone = state.dataHeatBal.Zone[thisEarthTube.ZonePtr - 1]
            for nodeNum in range(1, thisEarthTube.totNodes + 1):
                SetupOutputVariable(state, "Earth Tube Node Temperature {}".format(nodeNum), Constant.Units.C, thisEarthTube.tCurrent[nodeNum - 1], OutputProcessor.TimeStepType.Zone, OutputProcessor.StoreType.Average, zone.Name)
                SetupOutputVariable(state, "Earth Tube Undisturbed Ground Temperature {}".format(nodeNum), Constant.Units.C, thisEarthTube.tUndist[nodeNum - 1], OutputProcessor.TimeStepType.Zone, OutputProcessor.StoreType.Average, zone.Name)
            SetupOutputVariable(state, "Earth Tube Upper Boundary Ground Temperature", Constant.Units.C, thisEarthTube.tUpperBound, OutputProcessor.TimeStepType.Zone, OutputProcessor.StoreType.Average, zone.Name)
            SetupOutputVariable(state, "Earth Tube Lower Boundary Ground Temperature", Constant.Units.C, thisEarthTube.tLowerBound, OutputProcessor.TimeStepType.Zone, OutputProcessor.StoreType.Average, zone.Name)
    var timeElapsedLoc: Float64 = state.dataGlobal.HourOfDay + state.dataGlobal.TimeStep * state.dataGlobal.TimeStepZone + state.dataHVACGlobal.SysTimeElapsed
    if state.dataEarthTube.timeElapsed != timeElapsedLoc:
        if state.dataGlobal.BeginDayFlag or state.dataGlobal.BeginEnvrnFlag:
            for etNum in range(1, totEarthTube + 1):
                var thisEarthTube = state.dataEarthTube.EarthTubeSys[etNum - 1]
                if thisEarthTube.ModelType != EarthTubeModelType.Vertical:
                    continue
                thisEarthTube.tUpperBound = thisEarthTube.calcUndisturbedGroundTemperature(state, thisEarthTube.depthUpperBound)
                thisEarthTube.tLowerBound = thisEarthTube.calcUndisturbedGroundTemperature(state, thisEarthTube.depthLowerBound)
                for nodeNum in range(thisEarthTube.totNodes):
                    thisEarthTube.tUndist[nodeNum] = thisEarthTube.calcUndisturbedGroundTemperature(state, thisEarthTube.depthNode[nodeNum])
        if state.dataGlobal.BeginEnvrnFlag or (not state.dataGlobal.WarmupFlag and state.dataGlobal.BeginDayFlag and state.dataGlobal.DayOfSim == 1):
            for etNum in range(1, totEarthTube + 1):
                var thisEarthTube = state.dataEarthTube.EarthTubeSys[etNum - 1]
                if thisEarthTube.ModelType != EarthTubeModelType.Vertical:
                    continue
                for nodeNum in range(thisEarthTube.totNodes):
                    thisEarthTube.tLast[nodeNum] = thisEarthTube.tUndist[nodeNum]
                    thisEarthTube.tCurrent[nodeNum] = thisEarthTube.tLast[nodeNum]
        for etNum in range(1, totEarthTube + 1):
            var thisEarthTube = state.dataEarthTube.EarthTubeSys[etNum - 1]
            if thisEarthTube.ModelType != EarthTubeModelType.Vertical:
                continue
            for nodeNum in range(thisEarthTube.totNodes):
                thisEarthTube.tLast[nodeNum] = thisEarthTube.tCurrent[nodeNum]
    state.dataEarthTube.timeElapsed = timeElapsedLoc

def EarthTubeData.initCPrime0(self):
    self.cPrime0[0] = self.cCoeff0[0] / self.bCoeff[0]
    for i in range(1, self.totNodes - 1):
        self.cPrime0[i] = self.cCoeff0[i] / (self.bCoeff[i] - self.aCoeff[i] * self.cPrime0[i - 1])
    self.cPrime0[self.totNodes - 1] = 0.0

def CalcEarthTube(state: EnergyPlusData):
    var Process1: Float64
    var GroundTempt: Float64
    var AirThermCond: Float64
    var AirKinemVisco: Float64
    var AirThermDiffus: Float64
    var Re: Float64
    var Pr: Float64
    var Nu: Float64
    var fa: Float64
    var PipeHeatTransCoef: Float64
    var Rc: Float64
    var Rp: Float64
    var Rs: Float64
    var Rt: Float64
    var OverallHeatTransCoef: Float64
    var AverPipeAirVel: Float64
    var AirMassFlowRate: Float64
    var AirSpecHeat: Float64
    var AirDensity: Float64
    var EVF: Float64
    var numEarthTubes: Int = state.dataEarthTube.EarthTubeSys.size()
    var outTdb: Float64 = state.dataEnvrn.OutDryBulbTemp
    for Loop in range(1, numEarthTubes + 1):
        var thisEarthTube = state.dataEarthTube.EarthTubeSys[Loop - 1]
        var NZ: Int = thisEarthTube.ZonePtr
        var thisZoneHB = state.dataZoneTempPredictorCorrector.zoneHeatBalance[NZ - 1]
        thisZoneHB.MCPTE = 0.0
        thisZoneHB.MCPE = 0.0
        thisZoneHB.EAMFL = 0.0
        thisZoneHB.EAMFLxHumRat = 0.0
        thisEarthTube.FanPower = 0.0
        var tempShutDown: Bool = thisZoneHB.MAT < thisEarthTube.MinTemperature or thisZoneHB.MAT > thisEarthTube.MaxTemperature or abs(thisZoneHB.MAT - outTdb) < thisEarthTube.DelTemperature
        if (thisEarthTube.ModelType == EarthTubeModelType.Basic) and tempShutDown:
            continue
        AirDensity = Psychrometrics.PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress, outTdb, state.dataEnvrn.OutHumRat)
        AirSpecHeat = Psychrometrics.PsyCpAirFnW(state.dataEnvrn.OutHumRat)
        if tempShutDown:
            EVF = 0.0
        else:
            EVF = thisEarthTube.DesignLevel * thisEarthTube.availSched.getCurrentVal()
        thisZoneHB.MCPE = EVF * AirDensity * AirSpecHeat * (thisEarthTube.ConstantTermCoef + abs(outTdb - state.dataZoneTempPredictorCorrector.zoneHeatBalance[NZ - 1].MAT) * thisEarthTube.TemperatureTermCoef + state.dataEnvrn.WindSpeed * (thisEarthTube.VelocityTermCoef + state.dataEnvrn.WindSpeed * thisEarthTube.VelocitySQTermCoef))
        thisZoneHB.EAMFL = thisZoneHB.MCPE / AirSpecHeat
        if thisEarthTube.FanEfficiency > 0.0:
            thisEarthTube.FanPower = thisZoneHB.EAMFL * thisEarthTube.FanPressure / (thisEarthTube.FanEfficiency * AirDensity)
        AverPipeAirVel = EVF / Constant.Pi / pow(thisEarthTube.r1, 2)
        AirMassFlowRate = EVF * AirDensity
        if thisEarthTube.ModelType == EarthTubeModelType.Basic:
            GroundTempt = thisEarthTube.calcUndisturbedGroundTemperature(state, thisEarthTube.z)
            thisEarthTube.GroundTempt = GroundTempt
        AirThermCond = 0.02442 + 0.6992 * outTdb / 10000.0
        AirKinemVisco = (0.1335 + 0.000925 * outTdb) / 10000.0
        AirThermDiffus = (0.0014 * outTdb + 0.1872) / 10000.0
        Re = 2.0 * thisEarthTube.r1 * AverPipeAirVel / AirKinemVisco
        Pr = AirKinemVisco / AirThermDiffus
        if Re <= 2300.0:
            Nu = 3.66
        elif Re <= 4000.0:
            fa = pow(1.58 * log(Re) - 3.28, -2)
            Process1 = (fa / 2.0) * (Re - 1000.0) * Pr / (1.0 + 12.7 * sqrt(fa / 2.0) * (pow(Pr, 2.0 / 3.0) - 1.0))
            Nu = (Process1 - 3.66) / (1700.0) * Re + (4000.0 * 3.66 - 2300.0 * Process1) / 1700.0
        else:
            fa = pow(1.58 * log(Re) - 3.28, -2)
            Nu = (fa / 2.0) * (Re - 1000.0) * Pr / (1.0 + 12.7 * sqrt(fa / 2.0) * (pow(Pr, 2.0 / 3.0) - 1.0))
        PipeHeatTransCoef = Nu * AirThermCond / 2.0 / thisEarthTube.r1
        Rc = 1.0 / 2.0 / Constant.Pi / thisEarthTube.r1 / PipeHeatTransCoef
        Rp = log((thisEarthTube.r1 + thisEarthTube.r2) / thisEarthTube.r1) / 2.0 / Constant.Pi / thisEarthTube.PipeThermCond
        if thisEarthTube.r3 > 0.0:
            Rs = log((thisEarthTube.r1 + thisEarthTube.r2 + thisEarthTube.r3) / (thisEarthTube.r1 + thisEarthTube.r2)) / 2.0 / Constant.Pi / thisEarthTube.SoilThermCond
        else:
            Rs = 0.0
        Rt = Rc + Rp + Rs
        OverallHeatTransCoef = 1.0 / Rt
        if thisEarthTube.ModelType == EarthTubeModelType.Vertical:
            var eff: Float64
            if AirMassFlowRate > 0.0:
                var NTU: Float64 = OverallHeatTransCoef * 2.0 * Constant.Pi * thisEarthTube.r1 * thisEarthTube.PipeLength / (AirMassFlowRate * AirSpecHeat)
                var maxExpPower: Float64 = 50.0
                if NTU > maxExpPower:
                    eff = 1.0
                else:
                    eff = 1.0 - exp(-NTU)
            else:
                eff = 0.0
            var airFlowTerm: Float64 = AirMassFlowRate * AirSpecHeat * eff * thisEarthTube.airFlowCoeff
            thisEarthTube.calcVerticalEarthTube(state, airFlowTerm)
            var nodeET: Int = state.dataEarthTube.EarthTubePars[thisEarthTube.vertParametersPtr - 1].numNodesAbove
            if eff <= 0.0:
                thisEarthTube.InsideAirTemp = outTdb
            elif eff >= 1.0:
                thisEarthTube.InsideAirTemp = thisEarthTube.tCurrent[nodeET]
            else:
                thisEarthTube.InsideAirTemp = outTdb - eff * (outTdb - thisEarthTube.tCurrent[nodeET])
        elif thisEarthTube.ModelType == EarthTubeModelType.Basic:
            if AirMassFlowRate * AirSpecHeat == 0.0:
                thisEarthTube.InsideAirTemp = GroundTempt
            else:
                if outTdb > GroundTempt:
                    Process1 = (log(abs(outTdb - GroundTempt)) * AirMassFlowRate * AirSpecHeat - OverallHeatTransCoef * thisEarthTube.PipeLength) / (AirMassFlowRate * AirSpecHeat)
                    thisEarthTube.InsideAirTemp = exp(Process1) + GroundTempt
                elif outTdb == GroundTempt:
                    thisEarthTube.InsideAirTemp = GroundTempt
                else:
                    Process1 = (log(abs(outTdb - GroundTempt)) * AirMassFlowRate * AirSpecHeat - OverallHeatTransCoef * thisEarthTube.PipeLength) / (AirMassFlowRate * AirSpecHeat)
                    thisEarthTube.InsideAirTemp = GroundTempt - exp(Process1)
        else:
            assert(False)
        thisEarthTube.CalcEarthTubeHumRat(state, NZ)

def EarthTubeData.calcUndisturbedGroundTemperature(self, state: EnergyPlusData, depth: Float64) -> Float64:
    return self.AverSoilSurTemp - self.ApmlSoilSurTemp * exp(-depth * sqrt(Constant.Pi / 365.0 / self.SoilThermDiff)) * cos(2.0 * Constant.Pi / 365.0 * (state.dataEnvrn.DayOfYear - self.SoilSurPhaseConst - depth / 2.0 * sqrt(365.0 / Constant.Pi / self.SoilThermDiff)))

def EarthTubeData.calcVerticalEarthTube(self, state: EnergyPlusData, airFlowTerm: Float64):
    var nodeET: Int = state.dataEarthTube.EarthTubePars[self.vertParametersPtr - 1].numNodesAbove
    var nodeLast: Int = self.totNodes - 1
    if airFlowTerm <= 0.0:
        for nodeNum in range(nodeLast + 1):
            self.cPrime[nodeNum] = self.cPrime0[nodeNum]
    else:
        self.cPrime[0] = self.cCoeff[0] / self.bCoeff[0]
        for nodeNum in range(1, nodeLast + 1):
            var addTerm: Float64 = 0.0
            if nodeNum == nodeET:
                addTerm = airFlowTerm
            self.cPrime[nodeNum] = self.cCoeff[nodeNum] / (self.bCoeff[nodeNum] + addTerm - self.aCoeff[nodeNum] * self.cPrime[nodeNum - 1])
    self.dCoeff[0] = self.tLast[0] + self.dMult0 * self.tUpperBound
    for nodeNum in range(1, nodeLast):
        if nodeNum != nodeET:
            self.dCoeff[nodeNum] = self.tLast[nodeNum]
        else:
            self.dCoeff[nodeNum] = self.tLast[nodeNum] + airFlowTerm * state.dataEnvrn.OutDryBulbTemp
    self.dCoeff[nodeLast] = self.tLast[nodeLast] + self.dMultN * self.tLowerBound
    self.dPrime[0] = self.dCoeff[0] / self.bCoeff[0]
    for nodeNum in range(1, nodeLast + 1):
        var addTerm: Float64 = 0.0
        if nodeNum == nodeET:
            addTerm = airFlowTerm
        self.dPrime[nodeNum] = (self.dCoeff[nodeNum] - self.aCoeff[nodeNum] * self.dPrime[nodeNum - 1]) / (self.bCoeff[nodeNum] + addTerm - self.aCoeff[nodeNum] * self.cPrime[nodeNum - 1])
    self.tCurrent[nodeLast] = self.dPrime[nodeLast]
    for nodeNum in range(nodeLast - 1, -1, -1):
        self.tCurrent[nodeNum] = self.dPrime[nodeNum] - self.cPrime[nodeNum] * self.tCurrent[nodeNum + 1]

def EarthTubeData.CalcEarthTubeHumRat(self, state: EnergyPlusData, NZ: Int):
    var InsideDewPointTemp: Float64 = Psychrometrics.PsyTdpFnWPb(state, state.dataEnvrn.OutHumRat, state.dataEnvrn.OutBaroPress)
    var InsideHumRat: Float64 = 0.0
    var thisZoneHB = state.dataZoneTempPredictorCorrector.zoneHeatBalance[NZ - 1]
    if self.InsideAirTemp >= InsideDewPointTemp:
        InsideHumRat = state.dataEnvrn.OutHumRat
        var InsideEnthalpy: Float64 = Psychrometrics.PsyHFnTdbW(self.InsideAirTemp, state.dataEnvrn.OutHumRat)
        if self.FanType == Ventilation.Intake:
            var OutletAirEnthalpy: Float64
            if thisZoneHB.EAMFL == 0.0:
                OutletAirEnthalpy = InsideEnthalpy
            else:
                OutletAirEnthalpy = InsideEnthalpy + self.FanPower / thisZoneHB.EAMFL
            self.AirTemp = Psychrometrics.PsyTdbFnHW(OutletAirEnthalpy, state.dataEnvrn.OutHumRat)
        else:
            self.AirTemp = self.InsideAirTemp
        thisZoneHB.MCPTE = thisZoneHB.MCPE * self.AirTemp
    else:
        InsideHumRat = Psychrometrics.PsyWFnTdpPb(state, self.InsideAirTemp, state.dataEnvrn.OutBaroPress)
        var InsideEnthalpy: Float64 = Psychrometrics.PsyHFnTdbW(self.InsideAirTemp, InsideHumRat)
        if self.FanType == Ventilation.Intake:
            var OutletAirEnthalpy: Float64
            if thisZoneHB.EAMFL == 0.0:
                OutletAirEnthalpy = InsideEnthalpy
            else:
                OutletAirEnthalpy = InsideEnthalpy + self.FanPower / thisZoneHB.EAMFL
            self.AirTemp = Psychrometrics.PsyTdbFnHW(OutletAirEnthalpy, InsideHumRat)
        else:
            self.AirTemp = self.InsideAirTemp
        thisZoneHB.MCPTE = thisZoneHB.MCPE * self.AirTemp
    self.HumRat = InsideHumRat
    self.WetBulbTemp = Psychrometrics.PsyTwbFnTdbWPb(state, self.InsideAirTemp, InsideHumRat, state.dataEnvrn.OutBaroPress)
    thisZoneHB.EAMFLxHumRat = thisZoneHB.EAMFL * InsideHumRat

def ReportEarthTube(state: EnergyPlusData):
    var ReportingConstant: Float64 = state.dataHVACGlobal.TimeStepSysSec
    for ZoneLoop in range(1, state.dataGlobal.NumOfZones + 1):
        var thisZone = state.dataEarthTube.ZnRptET[ZoneLoop - 1]
        var thisZoneHB = state.dataZoneTempPredictorCorrector.zoneHeatBalance[ZoneLoop - 1]
        var AirDensity: Float64 = Psychrometrics.PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress, state.dataEnvrn.OutDryBulbTemp, state.dataEnvrn.OutHumRat)
        var CpAir: Float64 = Psychrometrics.PsyCpAirFnW(state.dataEnvrn.OutHumRat)
        thisZone.EarthTubeVolume = (thisZoneHB.MCPE / CpAir / AirDensity) * ReportingConstant
        thisZone.EarthTubeMass = (thisZoneHB.MCPE / CpAir) * ReportingConstant
        thisZone.EarthTubeVolFlowRate = thisZoneHB.MCPE / CpAir / AirDensity
        thisZone.EarthTubeVolFlowRateStd = thisZoneHB.MCPE / CpAir / state.dataEnvrn.StdRhoAir
        thisZone.EarthTubeMassFlowRate = thisZoneHB.MCPE / CpAir
        thisZone.EarthTubeWaterMassFlowRate = thisZoneHB.EAMFLxHumRat
        thisZone.EarthTubeFanElec = 0.0
        thisZone.EarthTubeAirTemp = 0.0
        for thisEarthTube in state.dataEarthTube.EarthTubeSys:
            if thisEarthTube.ZonePtr == ZoneLoop:
                thisZone.EarthTubeFanElec = thisEarthTube.FanPower * ReportingConstant
                thisZone.EarthTubeFanElecPower = thisEarthTube.FanPower
                if thisZoneHB.ZT > thisEarthTube.AirTemp:
                    thisZone.EarthTubeHeatLoss = thisZoneHB.MCPE * (thisZoneHB.ZT - thisEarthTube.AirTemp) * ReportingConstant
                    thisZone.EarthTubeHeatLossRate = thisZoneHB.MCPE * (thisZoneHB.ZT - thisEarthTube.AirTemp)
                    thisZone.EarthTubeHeatGain = 0.0
                    thisZone.EarthTubeHeatGainRate = 0.0
                else:
                    thisZone.EarthTubeHeatGain = thisZoneHB.MCPE * (thisEarthTube.AirTemp - thisZoneHB.ZT) * ReportingConstant
                    thisZone.EarthTubeHeatGainRate = thisZoneHB.MCPE * (thisEarthTube.AirTemp - thisZoneHB.ZT)
                    thisZone.EarthTubeHeatLoss = 0.0
                    thisZone.EarthTubeHeatLossRate = 0.0
                thisZone.EarthTubeAirTemp = thisEarthTube.AirTemp
                thisZone.EarthTubeWetBulbTemp = thisEarthTube.WetBulbTemp
                thisZone.EarthTubeHumRat = thisEarthTube.HumRat
                thisZone.EarthTubeOATreatmentPower = thisZoneHB.MCPE * (thisEarthTube.AirTemp - state.dataEnvrn.OutDryBulbTemp)
                break