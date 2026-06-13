from memory import Pointer
from ...Coils.CoilCoolingDXPerformanceBase import CoilCoolingDXPerformanceBase
from ...Coils.CoilCoolingDXAshrae205Performance import CoilCoolingDX205Performance
from ...Coils.CoilCoolingDXCurveFitPerformance import CoilCoolingDXCurveFitPerformance
from ...Data.EnergyPlusData import EnergyPlusData, ErrorObjectHeader
from ...DataAirLoop import (
    SetupOutputVariable,
    CalcComponentSensibleLatentOutput,
    getReportIndex,
    setCoilFinalSizes,
    setCoilSupplyFanInfo,
    setRatedCoilConditions,
)
from ...DataEnvironment import OutDryBulbTemp, OutHumRat, OutWetBulbTemp, OutBaroPress, StdPressureSeaLevel
from ...DataGlobalConstants import eResource, eFuelNames, eFuel2eResource
from ...DataGlobals import WarmupFlag, DoingHVACSizingSimulations, DoingSizing
from ...DataHVACGlobals import TimeStepSys, rSecsInHour, DXElecCoolingPower, StandardRatingsMyCoolOneTimeFlag, StandardRatingsMyCoolOneTimeFlag2
from ...DataHeatBalance import HeatReclaimDataBase
from ...DataLoopNode import Node, GetOnlySingleNode, TestCompSet, ConnectionObjectType, FluidType, ConnectionType, CompFluidStream, ObjectIsNotParent
from ...DataWater import WaterStorage, VdotAvailSupply, TwaterSupply, VdotRequestDemand
from ...Fans import fans
from ...GeneralRoutines import ShowFatalError, ShowSevereError, ShowSevereItemNotFound
from ...InputProcessing.InputProcessor import getObjectSchemaProps, getAlphaFieldValue, markObjectAsUsed
from ...NodeInputManager import (unused)
from ...OutAirNodeManager import (unused)
from ...OutputProcessor import OutputProcessor, Constant, StoreType, TimeStepType, Group, EndUseCat
from ...OutputReportPredefined import PreDefTableEntry, addFootNoteSubTable, pdchDXCoolCoilType, pdchDXCoolCoilNetCapSI, pdchDXCoolCoilCOP, pdchDXCoolCoilEERIP, pdchDXCoolCoilSEERUserIP, pdchDXCoolCoilSEERStandardIP, pdchDXCoolCoilIEERIP, pdstDXCoolCoil, pdchDXCoolCoilType_2023, pdchDXCoolCoilNetCapSI_2023, pdchDXCoolCoilCOP_2023, pdchDXCoolCoilEERIP_2023, pdchDXCoolCoilSEER2UserIP_2023, pdchDXCoolCoilSEER2StandardIP_2023, pdchDXCoolCoilIEERIP_2023, pdstDXCoolCoil_2023
from ...Psychrometrics import RhoH2O, PsyWFnTdbTwbPb, PsyHFnTdbW, PsyTwbFnTdbWPb
from ...ReportCoilSelection import getReportIndex, setCoilFinalSizes, setCoilSupplyFanInfo, setRatedCoilConditions
from ...ScheduleManager import Schedule, GetScheduleAlwaysOn, GetSchedule
from ...SimAirServingZones import AirLoopAFNInfo
from ...StandardRatings import AHRI2017FOOTNOTE, AHRI2023FOOTNOTE
from ...WaterManager import SetupTankSupplyComponent, SetupTankDemandComponent
from ...Util import makeUPPER
from ...HVAC import CoilMode, CoilType, FanOp, FanType
struct CoilCoolingDXInputSpecification:
    var name: String
    var evaporator_inlet_node_name: String
    var evaporator_outlet_node_name: String
    var availability_schedule_name: String
    var condenser_zone_name: String
    var condenser_inlet_node_name: String
    var condenser_outlet_node_name: String
    var performance_object_name: String
    var condensate_collection_water_storage_tank_name: String
    var evaporative_condenser_supply_water_storage_tank_name: String
struct CoilCoolingDX:
    var original_input_specs: CoilCoolingDXInputSpecification
    var name: String
    var coilType: CoilType = CoilType.Invalid
    var coilReportNum: Int = -1
    var myOneTimeInitFlag: Bool = True
    var evapInletNodeIndex: Int = 0
    var evapOutletNodeIndex: Int = 0
    var availSched: Pointer[Schedule] = None
    var condInletNodeIndex: Int = 0
    var condOutletNodeIndex: Int = 0
    var performance: Pointer[CoilCoolingDXPerformanceBase] = None
    var condensateTankIndex: Int = 0
    var condensateTankSupplyARRID: Int = 0
    var condensateVolumeFlow: Float64 = 0.0
    var condensateVolumeConsumption: Float64 = 0.0
    var evaporativeCondSupplyTankIndex: Int = 0
    var evaporativeCondSupplyTankARRID: Int = 0
    var evaporativeCondSupplyTankVolumeFlow: Float64 = 0.0
    var evaporativeCondSupplyTankConsump: Float64 = 0.0
    var evapCondPumpElecPower: Float64 = 0.0
    var evapCondPumpElecConsumption: Float64 = 0.0
    var airLoopNum: Int = 0
    var supplyFanIndex: Int = 0
    var supplyFanType: FanType = FanType.Invalid
    var supplyFanName: String
    var subcoolReheatFlag: Bool = False
    var totalCoolingEnergyRate: Float64 = 0.0
    var totalCoolingEnergy: Float64 = 0.0
    var sensCoolingEnergyRate: Float64 = 0.0
    var sensCoolingEnergy: Float64 = 0.0
    var latCoolingEnergyRate: Float64 = 0.0
    var latCoolingEnergy: Float64 = 0.0
    var coolingCoilRuntimeFraction: Float64 = 0.0
    var elecCoolingPower: Float64 = 0.0
    var elecCoolingConsumption: Float64 = 0.0
    var airMassFlowRate: Float64 = 0.0
    var inletAirDryBulbTemp: Float64 = 0.0
    var inletAirHumRat: Float64 = 0.0
    var outletAirDryBulbTemp: Float64 = 0.0
    var outletAirHumRat: Float64 = 0.0
    var partLoadRatioReport: Float64 = 0.0
    var runTimeFraction: Float64 = 0.0
    var speedNumReport: Int = 0
    var speedRatioReport: Float64 = 0.0
    var wasteHeatEnergyRate: Float64 = 0.0
    var wasteHeatEnergy: Float64 = 0.0
    var recoveredHeatEnergy: Float64 = 0.0
    var recoveredHeatEnergyRate: Float64 = 0.0
    var condenserInletTemperature: Float64 = 0.0
    var dehumidificationMode: CoilMode = CoilMode.Normal
    var reportCoilFinalSizes: Bool = True
    var isSecondaryDXCoilInZone: Bool = False
    var secCoilSensHeatRejEnergyRate: Float64 = 0.0
    var secCoilSensHeatRejEnergy: Float64 = 0.0
    var reclaimHeat: HeatReclaimDataBase
    def __init__(inout self):
        return
    def makePerformanceSubclass(
        state: EnergyPlusData,
        performance_object_name: String
    ) -> Pointer[CoilCoolingDXPerformanceBase]:
        var a205_object_name = CoilCoolingDX205Performance.object_name
        var curve_fit_object_name = CoilCoolingDXCurveFitPerformance.object_name
        if self.findPerformanceSubclass(state, a205_object_name, performance_object_name):
            return Pointer[CoilCoolingDX205Performance](CoilCoolingDX205Performance(state, performance_object_name)).to_base()
        if self.findPerformanceSubclass(state, curve_fit_object_name, performance_object_name):
            return Pointer[CoilCoolingDXCurveFitPerformance](CoilCoolingDXCurveFitPerformance(state, performance_object_name)).to_base()
        ShowFatalError(state, String.format("Could not find Coil:Cooling:DX:Performance object with name: {}", performance_object_name))
        return None
    def factory(state: EnergyPlusData, coilName: String) -> Int:
        if state.dataCoilCoolingDX.coilCoolingDXGetInputFlag:
            CoilCoolingDX.getInput(state)
            state.dataCoilCoolingDX.coilCoolingDXGetInputFlag = False
        var handle: Int = -1
        var coilNameUpper = makeUPPER(coilName)
        for thisCoil in state.dataCoilCoolingDX.coilCoolingDXs:
            handle += 1
            if coilNameUpper == makeUPPER(thisCoil.name):
                return handle
        ShowSevereError(state, "Coil:Cooling:DX Coil not found=" + coilName)
        return -1
    def getInput(state: EnergyPlusData):
        var inputProcessor = state.dataInputProcessing.inputProcessor[]
        var coilInstances = inputProcessor.epJSON.find(state.dataCoilCoolingDX.coilCoolingDXObjectName)
        if coilInstances == inputProcessor.epJSON.end() or coilInstances.empty():
            ShowFatalError(state, R"(No "Coil:Cooling:DX" objects in input file)")
        var coilSchemaProps = inputProcessor.getObjectSchemaProps(state, state.dataCoilCoolingDX.coilCoolingDXObjectName)
        for coilInstance in coilInstances.value().items():
            var coilFields = coilInstance.value()
            var input_specs = CoilCoolingDXInputSpecification()
            input_specs.name = makeUPPER(coilInstance.key())
            input_specs.evaporator_inlet_node_name = inputProcessor.getAlphaFieldValue(coilFields, coilSchemaProps, "evaporator_inlet_node_name")
            input_specs.evaporator_outlet_node_name = inputProcessor.getAlphaFieldValue(coilFields, coilSchemaProps, "evaporator_outlet_node_name")
            input_specs.availability_schedule_name = inputProcessor.getAlphaFieldValue(coilFields, coilSchemaProps, "availability_schedule_name")
            input_specs.condenser_zone_name = inputProcessor.getAlphaFieldValue(coilFields, coilSchemaProps, "condenser_zone_name")
            input_specs.condenser_inlet_node_name = inputProcessor.getAlphaFieldValue(coilFields, coilSchemaProps, "condenser_inlet_node_name")
            input_specs.condenser_outlet_node_name = inputProcessor.getAlphaFieldValue(coilFields, coilSchemaProps, "condenser_outlet_node_name")
            input_specs.performance_object_name = inputProcessor.getAlphaFieldValue(coilFields, coilSchemaProps, "performance_object_name")
            input_specs.condensate_collection_water_storage_tank_name = inputProcessor.getAlphaFieldValue(coilFields, coilSchemaProps, "condensate_collection_water_storage_tank_name")
            input_specs.evaporative_condenser_supply_water_storage_tank_name = inputProcessor.getAlphaFieldValue(coilFields, coilSchemaProps, "evaporative_condenser_supply_water_storage_tank_name")
            var thisCoil = CoilCoolingDX()
            thisCoil.instantiateFromInputSpec(state, input_specs)
            inputProcessor.markObjectAsUsed(state.dataCoilCoolingDX.coilCoolingDXObjectName, coilInstance.key())
            state.dataCoilCoolingDX.coilCoolingDXs.append(thisCoil)
    def instantiateFromInputSpec(inout self, state: EnergyPlusData, input_data: CoilCoolingDXInputSpecification):
        alias routineName: StringLiteral = "CoilCoolingDX::instantiateFromInputSpec"
        var eoh = ErrorObjectHeader(routineName, "Coil:Cooling:DX", input_data.name)
        self.original_input_specs = input_data
        var errorsFound: Bool = False
        self.name = input_data.name
        self.coilType = CoilType.CoolingDX
        self.coilReportNum = getReportIndex(state, self.name, self.coilType)
        self.reclaimHeat.Name = self.name
        self.reclaimHeat.SourceType = state.dataCoilCoolingDX.coilCoolingDXObjectName
        self.evapInletNodeIndex = GetOnlySingleNode(
            state, input_data.evaporator_inlet_node_name,
            errorsFound, ConnectionObjectType.CoilCoolingDX,
            input_data.name, FluidType.Air,
            ConnectionType.Inlet, CompFluidStream.Primary,
            ObjectIsNotParent
        )
        self.evapOutletNodeIndex = GetOnlySingleNode(
            state, input_data.evaporator_outlet_node_name,
            errorsFound, ConnectionObjectType.CoilCoolingDX,
            input_data.name, FluidType.Air,
            ConnectionType.Outlet, CompFluidStream.Primary,
            ObjectIsNotParent
        )
        self.condInletNodeIndex = GetOnlySingleNode(
            state, input_data.condenser_inlet_node_name,
            errorsFound, ConnectionObjectType.CoilCoolingDX,
            input_data.name, FluidType.Air,
            ConnectionType.Inlet, CompFluidStream.Secondary,
            ObjectIsNotParent
        )
        self.condOutletNodeIndex = GetOnlySingleNode(
            state, input_data.condenser_outlet_node_name,
            errorsFound, ConnectionObjectType.CoilCoolingDX,
            input_data.name, FluidType.Air,
            ConnectionType.Outlet, CompFluidStream.Secondary,
            ObjectIsNotParent
        )
        self.performance = self.makePerformanceSubclass(state, input_data.performance_object_name)
        self.subcoolReheatFlag = self.performance[].subcoolReheatFlag()
        if not input_data.condensate_collection_water_storage_tank_name.empty():
            SetupTankSupplyComponent(
                state, self.name,
                state.dataCoilCoolingDX.coilCoolingDXObjectName,
                input_data.condensate_collection_water_storage_tank_name,
                errorsFound,
                self.condensateTankIndex,
                self.condensateTankSupplyARRID
            )
        if not input_data.evaporative_condenser_supply_water_storage_tank_name.empty():
            SetupTankDemandComponent(
                state, self.name,
                state.dataCoilCoolingDX.coilCoolingDXObjectName,
                input_data.evaporative_condenser_supply_water_storage_tank_name,
                errorsFound,
                self.evaporativeCondSupplyTankIndex,
                self.evaporativeCondSupplyTankARRID
            )
        if input_data.availability_schedule_name.empty():
            self.availSched = GetScheduleAlwaysOn(state)
        else:
            var sched = GetSchedule(state, input_data.availability_schedule_name)
            if sched is None:
                ShowSevereItemNotFound(state, eoh, "Availability Schedule Name", input_data.availability_schedule_name)
                errorsFound = True
            else:
                self.availSched = sched
        self.performance[].coilCoolingDXAvailSched = self.availSched
        if not input_data.condenser_zone_name.empty():
            self.isSecondaryDXCoilInZone = True
        TestCompSet(
            state,
            state.dataCoilCoolingDX.coilCoolingDXObjectName,
            self.name,
            input_data.evaporator_inlet_node_name,
            input_data.evaporator_outlet_node_name,
            "Air Nodes"
        )
        if errorsFound:
            ShowFatalError(state,
                String(routineName) + "Errors found in getting " + state.dataCoilCoolingDX.coilCoolingDXObjectName +
                " input. Preceding condition(s) causes termination.")
    def oneTimeInit(inout self, state: EnergyPlusData):
        SetupOutputVariable(state,
            "Cooling Coil Total Cooling Rate",
            Constant.Units.W,
            self.totalCoolingEnergyRate,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            self.name)
        SetupOutputVariable(state,
            "Cooling Coil Total Cooling Energy",
            Constant.Units.J,
            self.totalCoolingEnergy,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Sum,
            self.name,
            Constant.eResource.EnergyTransfer,
            OutputProcessor.Group.HVAC,
            OutputProcessor.EndUseCat.CoolingCoils)
        SetupOutputVariable(state,
            "Cooling Coil Sensible Cooling Rate",
            Constant.Units.W,
            self.sensCoolingEnergyRate,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            self.name)
        SetupOutputVariable(state,
            "Cooling Coil Sensible Cooling Energy",
            Constant.Units.J,
            self.sensCoolingEnergy,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Sum,
            self.name)
        SetupOutputVariable(state,
            "Cooling Coil Latent Cooling Rate",
            Constant.Units.W,
            self.latCoolingEnergyRate,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            self.name)
        SetupOutputVariable(state,
            "Cooling Coil Latent Cooling Energy",
            Constant.Units.J,
            self.latCoolingEnergy,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Sum,
            self.name)
        SetupOutputVariable(state,
            "Cooling Coil Electricity Rate",
            Constant.Units.W,
            self.performance[].powerUse,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            self.name)
        SetupOutputVariable(state,
            "Cooling Coil Electricity Energy",
            Constant.Units.J,
            self.performance[].electricityConsumption,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Sum,
            self.name,
            Constant.eResource.Electricity,
            OutputProcessor.Group.HVAC,
            OutputProcessor.EndUseCat.Cooling)
        if self.performance[].compressorFuelType != Constant.eFuel.Electricity:
            var sFuelType: StringLiteral = Constant.eFuelNames[Int(self.performance[].compressorFuelType)]
            SetupOutputVariable(state,
                String.format("Cooling Coil {} Rate", sFuelType),
                Constant.Units.W,
                self.performance[].compressorFuelRate,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                self.name)
            SetupOutputVariable(state,
                String.format("Cooling Coil {} Energy", sFuelType),
                Constant.Units.J,
                self.performance[].compressorFuelConsumption,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Sum,
                self.name,
                Constant.eFuel2eResource[Int(self.performance[].compressorFuelType)],
                OutputProcessor.Group.HVAC,
                OutputProcessor.EndUseCat.Cooling)
        SetupOutputVariable(state,
            "Cooling Coil Runtime Fraction",
            Constant.Units.None,
            self.coolingCoilRuntimeFraction,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            self.name)
        if self.performance[].ReportCoolingCoilCrankcasePower:
            SetupOutputVariable(state,
                "Cooling Coil Crankcase Heater Electricity Rate",
                Constant.Units.W,
                self.performance[].crankcaseHeaterPower,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                self.name)
            SetupOutputVariable(state,
                "Cooling Coil Crankcase Heater Electricity Energy",
                Constant.Units.J,
                self.performance[].crankcaseHeaterElectricityConsumption,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Sum,
                self.name,
                Constant.eResource.Electricity,
                OutputProcessor.Group.HVAC,
                OutputProcessor.EndUseCat.Cooling)
        SetupOutputVariable(state,
            "Cooling Coil Air Mass Flow Rate",
            Constant.Units.kg_s,
            self.airMassFlowRate,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            self.name)
        SetupOutputVariable(state,
            "Cooling Coil Air Inlet Temperature",
            Constant.Units.C,
            self.inletAirDryBulbTemp,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            self.name)
        SetupOutputVariable(state,
            "Cooling Coil Air Inlet Humidity Ratio",
            Constant.Units.kgWater_kgDryAir,
            self.inletAirHumRat,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            self.name)
        SetupOutputVariable(state,
            "Cooling Coil Air Outlet Temperature",
            Constant.Units.C,
            self.outletAirDryBulbTemp,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            self.name)
        SetupOutputVariable(state,
            "Cooling Coil Air Outlet Humidity Ratio",
            Constant.Units.kgWater_kgDryAir,
            self.outletAirHumRat,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            self.name)
        SetupOutputVariable(state,
            "Cooling Coil Part Load Ratio",
            Constant.Units.None,
            self.partLoadRatioReport,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            self.name)
        SetupOutputVariable(state,
            "Cooling Coil Upper Speed Level",
            Constant.Units.None,
            self.speedNumReport,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            self.name)
        SetupOutputVariable(state,
            "Cooling Coil Neighboring Speed Levels Ratio",
            Constant.Units.None,
            self.speedRatioReport,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            self.name)
        SetupOutputVariable(state,
            "Cooling Coil Condenser Inlet Temperature",
            Constant.Units.C,
            self.condenserInletTemperature,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            self.name)
        SetupOutputVariable(state,
            "Cooling Coil Dehumidification Mode",
            Constant.Units.None,
            self.dehumidificationMode,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            self.name)
        SetupOutputVariable(state,
            "Cooling Coil Waste Heat Power",
            Constant.Units.W,
            self.wasteHeatEnergyRate,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            self.name)
        SetupOutputVariable(state,
            "Cooling Coil Waste Heat Energy",
            Constant.Units.J,
            self.wasteHeatEnergy,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Sum,
            self.name)
        if self.performance[].evapCondBasinHeatCap > 0:
            SetupOutputVariable(state,
                "Cooling Coil Basin Heater Electricity Rate",
                Constant.Units.W,
                self.performance[].basinHeaterPower,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                self.name)
            SetupOutputVariable(state,
                "Cooling Coil Basin Heater Electricity Energy",
                Constant.Units.J,
                self.performance[].basinHeaterElectricityConsumption,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Sum,
                self.name,
                Constant.eResource.Electricity,
                OutputProcessor.Group.HVAC,
                OutputProcessor.EndUseCat.Cooling)
        if self.condensateTankIndex > 0:
            SetupOutputVariable(state,
                "Cooling Coil Condensate Volume Flow Rate",
                Constant.Units.m3_s,
                self.condensateVolumeFlow,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                self.name)
            SetupOutputVariable(state,
                "Cooling Coil Condensate Volume",
                Constant.Units.m3,
                self.condensateVolumeConsumption,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Sum,
                self.name,
                Constant.eResource.OnSiteWater,
                OutputProcessor.Group.HVAC,
                OutputProcessor.EndUseCat.Condensate)
        if self.evaporativeCondSupplyTankIndex > 0:
            SetupOutputVariable(state,
                "Cooling Coil Evaporative Condenser Pump Electricity Rate",
                Constant.Units.W,
                self.evapCondPumpElecPower,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                self.name)
            SetupOutputVariable(state,
                "Cooling Coil Evaporative Condenser Pump Electricity Energy",
                Constant.Units.J,
                self.evapCondPumpElecConsumption,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Sum,
                self.name,
                Constant.eResource.Electricity,
                OutputProcessor.Group.HVAC,
                OutputProcessor.EndUseCat.Condensate)
            SetupOutputVariable(state,
                "Cooling Coil Evaporative Condenser Water Volume Flow Rate",
                Constant.Units.m3_s,
                self.evaporativeCondSupplyTankVolumeFlow,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                self.name)
            SetupOutputVariable(state,
                "Cooling Coil Evaporative Condenser Water Volume",
                Constant.Units.m3,
                self.evaporativeCondSupplyTankConsump,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Sum,
                self.name,
                Constant.eResource.Water,
                OutputProcessor.Group.HVAC,
                OutputProcessor.EndUseCat.Condensate)
            SetupOutputVariable(state,
                "Cooling Coil Evaporative Condenser Mains Supply Water Volume",
                Constant.Units.m3,
                self.evaporativeCondSupplyTankConsump,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Sum,
                self.name,
                Constant.eResource.MainsWater,
                OutputProcessor.Group.HVAC,
                OutputProcessor.EndUseCat.Cooling)
        if self.subcoolReheatFlag:
            SetupOutputVariable(state,
                "SubcoolReheat Cooling Coil Operation Mode",
                Constant.Units.None,
                self.performance[].OperatingMode,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                self.name)
            SetupOutputVariable(state,
                "SubcoolReheat Cooling Coil Operation Mode Ratio",
                Constant.Units.None,
                self.performance[].ModeRatio,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                self.name)
            SetupOutputVariable(state,
                "SubcoolReheat Cooling Coil Recovered Heat Energy Rate",
                Constant.Units.W,
                self.recoveredHeatEnergyRate,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                self.name)
            SetupOutputVariable(state,
                "SubcoolReheat Cooling Coil Recovered Heat Energy",
                Constant.Units.J,
                self.recoveredHeatEnergy,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Sum,
                self.name,
                Constant.eResource.EnergyTransfer,
                OutputProcessor.Group.HVAC,
                OutputProcessor.EndUseCat.HeatRecovery)
        if self.isSecondaryDXCoilInZone:
            SetupOutputVariable(state,
                "Secondary Coil Heat Rejection Rate",
                Constant.Units.W,
                self.secCoilSensHeatRejEnergyRate,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                self.name)
            SetupOutputVariable(state,
                "Secondary Coil Heat Rejection Energy",
                Constant.Units.J,
                self.secCoilSensHeatRejEnergy,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Sum,
                self.name)
    def getNumModes(self) -> Int:
        var numModes: Int = 1
        if self.performance[].maxAvailCoilMode != CoilMode.Normal:
            numModes += 1
        return numModes
    def getOpModeCapFTIndex(self, mode: CoilMode) -> Int:
        return self.performance[].indexCapFT(mode)
    def setData(inout self, fanIndex: Int, fanType: FanType, fanName: String, _airLoopNum: Int):
        self.supplyFanIndex = fanIndex
        self.supplyFanName = fanName
        self.supplyFanType = fanType
        self.airLoopNum = _airLoopNum
    def getFixedData(self, inout _evapInletNodeIndex: Int, inout _evapOutletNodeIndex: Int, inout _condInletNodeIndex: Int,
                    inout _normalModeNumSpeeds: Int, inout _capacityControlMethod: CoilCoolingDXPerformanceBase.CapControlMethod,
                    inout _minOutdoorDryBulb: Float64):
        _evapInletNodeIndex = self.evapInletNodeIndex
        _evapOutletNodeIndex = self.evapOutletNodeIndex
        _condInletNodeIndex = self.condInletNodeIndex
        _normalModeNumSpeeds = Int(self.performance[].numSpeeds())
        _capacityControlMethod = self.performance[].capControlMethod
        _minOutdoorDryBulb = self.performance[].minOutdoorDrybulb
    def getDataAfterSizing(self, state: EnergyPlusData,
                          inout _normalModeRatedEvapAirFlowRate: Float64,
                          inout _normalModeRatedCapacity: Float64,
                          inout _normalModeFlowRates: List[Float64],
                          inout _normalModeRatedCapacities: List[Float64]):
        _normalModeRatedEvapAirFlowRate = self.performance[].ratedEvapAirFlowRate(state)
        _normalModeFlowRates.clear()
        _normalModeRatedCapacities.clear()
        for speed in range(Int(self.performance[].numSpeeds())):
            _normalModeFlowRates.append(self.performance[].evapAirFlowRateAtSpeedIndex(state, speed))
            _normalModeRatedCapacities.append(self.performance[].ratedTotalCapacityAtSpeedIndex(state, speed))
        _normalModeRatedCapacity = self.performance[].ratedGrossTotalCap()
    def condMassFlowRate(self, state: EnergyPlusData, mode: CoilMode) -> Float64:
        return self.performance[].ratedCondAirMassFlowRateNomSpeed(state, mode)
    def size(inout self, state: EnergyPlusData):
        self.performance[].parentName = self.name
        self.performance[].size(state)
    def simulate(inout self, state: EnergyPlusData,
                coilMode: CoilMode,
                speedNum: Int,
                speedRatio: Float64,
                fanOp: FanOp,
                singleMode: Bool,
                LoadSHR: Float64 = -1.0):
        if self.myOneTimeInitFlag:
            self.oneTimeInit(state)
            self.myOneTimeInitFlag = False
        alias RoutineName: StringLiteral = "CoilCoolingDX::simulate"
        var evapInletNode = state.dataLoopNodes.Node[self.evapInletNodeIndex]
        var evapOutletNode = state.dataLoopNodes.Node[self.evapOutletNodeIndex]
        var condInletNode = state.dataLoopNodes.Node[self.condInletNodeIndex]
        var condOutletNode = state.dataLoopNodes.Node[self.condOutletNodeIndex]
        self.condenserInletTemperature = condInletNode.Temp
        self.dehumidificationMode = coilMode
        condInletNode.MassFlowRate = self.condMassFlowRate(state, coilMode)
        condOutletNode.MassFlowRate = condInletNode.MassFlowRate
        self.performance[].OperatingMode = 0
        self.performance[].ModeRatio = 0.0
        self.performance[].simulate(
            state, evapInletNode, evapOutletNode, coilMode, speedNum, speedRatio, fanOp, condInletNode, condOutletNode, singleMode, LoadSHR
        )
        CoilCoolingDX.passThroughNodeData(evapInletNode, evapOutletNode)
        var reportingConstant: Float64 = state.dataHVACGlobal.TimeStepSys * Constant.rSecsInHour
        if self.condensateTankIndex > 0:
            if speedNum > 0:
                var averageTemp = (evapInletNode.Temp + evapOutletNode.Temp) / 2.0
                var waterDensity = RhoH2O(averageTemp)
                var inHumidityRatio = evapInletNode.HumRat
                var outHumidityRatio = evapOutletNode.HumRat
                self.condensateVolumeFlow = max(0.0, (evapInletNode.MassFlowRate * (inHumidityRatio - outHumidityRatio) / waterDensity))
                self.condensateVolumeConsumption = self.condensateVolumeFlow * reportingConstant
                state.dataWaterData.WaterStorage[self.condensateTankIndex].VdotAvailSupply[self.condensateTankSupplyARRID] = self.condensateVolumeFlow
                state.dataWaterData.WaterStorage[self.condensateTankIndex].TwaterSupply[self.condensateTankSupplyARRID] = evapOutletNode.Temp
            else:
                state.dataWaterData.WaterStorage[self.condensateTankIndex].VdotAvailSupply[self.condensateTankSupplyARRID] = 0.0
                state.dataWaterData.WaterStorage[self.condensateTankIndex].TwaterSupply[self.condensateTankSupplyARRID] = evapOutletNode.Temp
        if self.evaporativeCondSupplyTankIndex > 0:
            if speedNum > 0:
                var condInletTemp = (
                    state.dataEnvrn.OutWetBulbTemp + (state.dataEnvrn.OutDryBulbTemp - state.dataEnvrn.OutWetBulbTemp) *
                    (1.0 - self.performance[].evapCondenserEffectivenessAtSpeedIndex(state, speedNum - 1))
                )
                var condInletHumRat = PsyWFnTdbTwbPb(state, condInletTemp, state.dataEnvrn.OutWetBulbTemp, state.dataEnvrn.OutBaroPress, RoutineName)
                var outdoorHumRat = state.dataEnvrn.OutHumRat
                var condAirMassFlow = condInletNode.MassFlowRate
                var waterDensity = RhoH2O(state.dataEnvrn.OutDryBulbTemp)
                self.evaporativeCondSupplyTankVolumeFlow = (condInletHumRat - outdoorHumRat) * condAirMassFlow / waterDensity
                self.evaporativeCondSupplyTankConsump = self.evaporativeCondSupplyTankVolumeFlow * reportingConstant
                if coilMode == CoilMode.Normal:
                    self.evapCondPumpElecPower = self.performance[].currentEvapCondPumpPowerAtSpeed(state, speedNum)
                state.dataWaterData.WaterStorage[self.evaporativeCondSupplyTankIndex].VdotRequestDemand[self.evaporativeCondSupplyTankARRID] = self.evaporativeCondSupplyTankVolumeFlow
            else:
                state.dataWaterData.WaterStorage[self.evaporativeCondSupplyTankIndex].VdotRequestDemand[self.evaporativeCondSupplyTankARRID] = 0.0
        self.airMassFlowRate = evapOutletNode.MassFlowRate
        self.inletAirDryBulbTemp = evapInletNode.Temp
        self.inletAirHumRat = evapInletNode.HumRat
        self.outletAirDryBulbTemp = evapOutletNode.Temp
        self.outletAirHumRat = evapOutletNode.HumRat
        CalcComponentSensibleLatentOutput(
            evapOutletNode.MassFlowRate,
            evapInletNode.Temp,
            evapInletNode.HumRat,
            evapOutletNode.Temp,
            evapOutletNode.HumRat,
            self.sensCoolingEnergyRate,
            self.latCoolingEnergyRate,
            self.totalCoolingEnergyRate
        )
        self.totalCoolingEnergy = self.totalCoolingEnergyRate * reportingConstant
        self.sensCoolingEnergy = self.sensCoolingEnergyRate * reportingConstant
        self.latCoolingEnergy = self.latCoolingEnergyRate * reportingConstant
        self.evapCondPumpElecConsumption = self.evapCondPumpElecPower * reportingConstant
        self.coolingCoilRuntimeFraction = self.performance[].RTF
        self.elecCoolingPower = self.performance[].powerUse
        self.elecCoolingConsumption = self.performance[].powerUse * reportingConstant
        self.wasteHeatEnergyRate = self.performance[].wasteHeatRate
        self.wasteHeatEnergy = self.performance[].wasteHeatRate * reportingConstant
        self.partLoadRatioReport = 1.0 if speedNum > 1 else speedRatio
        self.speedNumReport = speedNum
        self.speedRatioReport = 0.0 if speedNum <= 1 else speedRatio
        if coilMode == CoilMode.SubcoolReheat:
            self.recoveredHeatEnergyRate = self.performance[].recoveredEnergyRate
            self.recoveredHeatEnergy = self.recoveredHeatEnergyRate * reportingConstant
        if self.isSecondaryDXCoilInZone:
            self.secCoilSensHeatRejEnergyRate = self.totalCoolingEnergyRate + self.elecCoolingPower
            self.secCoilSensHeatRejEnergy = self.totalCoolingEnergy + self.elecCoolingConsumption
        state.dataAirLoop.LoopDXCoilRTF = self.coolingCoilRuntimeFraction
        state.dataHVACGlobal.DXElecCoolingPower = self.elecCoolingPower
        if self.airLoopNum > 0:
            state.dataAirLoop.AirLoopAFNInfo[self.airLoopNum].AFNLoopDXCoilRTF = self.coolingCoilRuntimeFraction
        if self.reportCoilFinalSizes:
            if not state.dataGlobal.WarmupFlag and not state.dataGlobal.DoingHVACSizingSimulations and not state.dataGlobal.DoingSizing:
                var ratedSensCap: Float64 = 0.0
                ratedSensCap = self.performance[].ratedGrossTotalCap() * self.performance[].grossRatedSHR(state)
                setCoilFinalSizes(
                    state, self.coilReportNum,
                    self.performance[].ratedGrossTotalCap(),
                    ratedSensCap,
                    self.performance[].ratedEvapAirFlowRate(state),
                    -999.0
                )
                if self.supplyFanIndex > 0:
                    setCoilSupplyFanInfo(
                        state, self.coilReportNum,
                        state.dataFans.fans[self.supplyFanIndex].Name,
                        state.dataFans.fans[self.supplyFanIndex].type,
                        self.supplyFanIndex
                    )
                var dummyEvapInlet = Node.NodeData()
                var dummyEvapOutlet = Node.NodeData()
                var dummyCondInlet = Node.NodeData()
                var dummyCondOutlet = Node.NodeData()
                var dummySpeedNum: Int = 1
                var dummySpeedRatio: Float64 = 1.0
                var dummyFanOp: FanOp = FanOp.Cycling
                var dummySingleMode: Bool = False
                alias RatedInletAirTemp: Float64 = 26.6667
                alias RatedInletWetBulbTemp: Float64 = 19.44
                alias RatedOutdoorAirTemp: Float64 = 35.0
                var ratedOutdoorAirWetBulb: Float64 = 23.9
                var ratedInletEvapMassFlowRate = self.performance[].ratedEvapAirMassFlowRate(state)
                dummyEvapInlet.MassFlowRate = ratedInletEvapMassFlowRate
                dummyEvapInlet.Temp = RatedInletAirTemp
                var dummyInletAirHumRat = PsyWFnTdbTwbPb(state, RatedInletAirTemp, RatedInletWetBulbTemp, StdPressureSeaLevel, RoutineName)
                dummyEvapInlet.Press = StdPressureSeaLevel
                dummyEvapInlet.HumRat = dummyInletAirHumRat
                dummyEvapInlet.Enthalpy = PsyHFnTdbW(RatedInletAirTemp, dummyInletAirHumRat)
                dummyCondInlet.Temp = RatedOutdoorAirTemp
                dummyCondInlet.HumRat = PsyWFnTdbTwbPb(state, RatedOutdoorAirTemp, ratedOutdoorAirWetBulb, StdPressureSeaLevel, RoutineName)
                dummyCondInlet.OutAirWetBulb = ratedOutdoorAirWetBulb
                dummyCondInlet.Press = condInletNode.Press
                var holdOutDryBulbTemp = state.dataEnvrn.OutDryBulbTemp
                var holdOutHumRat = state.dataEnvrn.OutHumRat
                var holdOutWetBulb = state.dataEnvrn.OutWetBulbTemp
                var holdOutBaroPress = state.dataEnvrn.OutBaroPress
                state.dataEnvrn.OutDryBulbTemp = RatedOutdoorAirTemp
                state.dataEnvrn.OutWetBulbTemp = ratedOutdoorAirWetBulb
                state.dataEnvrn.OutBaroPress = StdPressureSeaLevel
                state.dataEnvrn.OutHumRat = PsyWFnTdbTwbPb(state, RatedOutdoorAirTemp, ratedOutdoorAirWetBulb, StdPressureSeaLevel, RoutineName)
                self.performance[].simulate(
                    state, dummyEvapInlet, dummyEvapOutlet,
                    CoilMode.Normal, dummySpeedNum, dummySpeedRatio,
                    dummyFanOp, dummyCondInlet, dummyCondOutlet, dummySingleMode
                )
                state.dataEnvrn.OutDryBulbTemp = holdOutDryBulbTemp
                state.dataEnvrn.OutWetBulbTemp = holdOutWetBulb
                state.dataEnvrn.OutBaroPress = holdOutBaroPress
                state.dataEnvrn.OutHumRat = holdOutHumRat
                var coolingRate: Float64 = 0.0
                var sensCoolingRate: Float64 = 0.0
                var latCoolingRate: Float64 = 0.0
                CalcComponentSensibleLatentOutput(
                    dummyEvapInlet.MassFlowRate,
                    dummyEvapInlet.Temp,
                    dummyEvapInlet.HumRat,
                    dummyEvapOutlet.Temp,
                    dummyEvapOutlet.HumRat,
                    sensCoolingRate,
                    latCoolingRate,
                    coolingRate
                )
                var ratedOutletWetBulb = PsyTwbFnTdbWPb(
                    state, dummyEvapOutlet.Temp, dummyEvapOutlet.HumRat, StdPressureSeaLevel, "Coil:Cooling:DX::simulate"
                )
                setRatedCoilConditions(
                    state, self.coilReportNum,
                    coolingRate, sensCoolingRate,
                    ratedInletEvapMassFlowRate,
                    RatedInletAirTemp,
                    dummyInletAirHumRat,
                    RatedInletWetBulbTemp,
                    dummyEvapOutlet.Temp,
                    dummyEvapOutlet.HumRat,
                    ratedOutletWetBulb,
                    RatedOutdoorAirTemp,
                    ratedOutdoorAirWetBulb,
                    self.performance[].ratedCBF(state),
                    -999.0
                )
                self.reportCoilFinalSizes = False
        self.reclaimHeat.AvailCapacity = self.totalCoolingEnergyRate + self.elecCoolingPower
    def setToHundredPercentDOAS(inout self):
        self.performance[].setToHundredPercentDOAS()
    def passThroughNodeData(in: Node.NodeData, out: Node.NodeData):
        out.MassFlowRate = in.MassFlowRate
        out.Press = in.Press
        out.Quality = in.Quality
        out.MassFlowRateMax = in.MassFlowRateMax
        out.MassFlowRateMin = in.MassFlowRateMin
        out.MassFlowRateMaxAvail = in.MassFlowRateMaxAvail
        out.MassFlowRateMinAvail = in.MassFlowRateMinAvail
    def clear_state():

    def reportAllStandardRatings(state: EnergyPlusData):
        if not state.dataCoilCoolingDX.coilCoolingDXs.empty():
            alias ConvFromSIToIP: Float64 = 3.412141633
            if state.dataHVACGlobal.StandardRatingsMyCoolOneTimeFlag:
                alias Format_994: StringLiteral = (
                    "! <DX Cooling Coil Standard Rating Information>, Component Type, Component Name, Standard Rating (Net) "
                    "Cooling Capacity {W}, Standard Rating Net COP {W/W}, EER {Btu/W-h}, SEER User {Btu/W-h}, SEER Standard {Btu/W-h}, "
                    "IEER "
                    "{Btu/W-h}"
                )
                print(state.files.eio, "{}\n".format(Format_994))
                state.dataHVACGlobal.StandardRatingsMyCoolOneTimeFlag = False
            for coil in state.dataCoilCoolingDX.coilCoolingDXs:
                coil.performance[].calcStandardRatings210240(state)
                PopulateCoolingCoilStandardRatingInformation(
                    state.files.eio, coil.name,
                    coil.performance[].standardRatingCoolingCapacity,
                    coil.performance[].standardRatingEER,
                    coil.performance[].standardRatingSEER,
                    coil.performance[].standardRatingSEER_Standard,
                    coil.performance[].standardRatingIEER,
                    False
                )
                PreDefTableEntry(state, state.dataOutRptPredefined.pdchDXCoolCoilType, coil.name, "Coil:Cooling:DX")
                PreDefTableEntry(state, state.dataOutRptPredefined.pdchDXCoolCoilNetCapSI, coil.name, coil.performance[].standardRatingCoolingCapacity, 1)
                if coil.performance[].standardRatingEER > 0.0:
                    PreDefTableEntry(state, state.dataOutRptPredefined.pdchDXCoolCoilCOP, coil.name, coil.performance[].standardRatingEER, 2)
                else:
                    PreDefTableEntry(state, state.dataOutRptPredefined.pdchDXCoolCoilCOP, coil.name, "N/A")
                if coil.performance[].standardRatingEER > 0.0:
                    PreDefTableEntry(state, state.dataOutRptPredefined.pdchDXCoolCoilEERIP, coil.name, coil.performance[].standardRatingEER * ConvFromSIToIP, 2)
                else:
                    PreDefTableEntry(state, state.dataOutRptPredefined.pdchDXCoolCoilEERIP, coil.name, "N/A")
                if coil.performance[].standardRatingSEER > 0.0:
                    PreDefTableEntry(state, state.dataOutRptPredefined.pdchDXCoolCoilSEERUserIP, coil.name, coil.performance[].standardRatingSEER * ConvFromSIToIP, 2)
                else:
                    PreDefTableEntry(state, state.dataOutRptPredefined.pdchDXCoolCoilSEERUserIP, coil.name, "N/A")
                if coil.performance[].standardRatingSEER_Standard > 0.0:
                    PreDefTableEntry(state, state.dataOutRptPredefined.pdchDXCoolCoilSEERStandardIP, coil.name, coil.performance[].standardRatingSEER_Standard * ConvFromSIToIP, 2)
                else:
                    PreDefTableEntry(state, state.dataOutRptPredefined.pdchDXCoolCoilSEERStandardIP, coil.name, "N/A")
                if coil.performance[].standardRatingIEER > 0.0:
                    PreDefTableEntry(state, state.dataOutRptPredefined.pdchDXCoolCoilIEERIP, coil.name, coil.performance[].standardRatingIEER * ConvFromSIToIP, 1)
                else:
                    PreDefTableEntry(state, state.dataOutRptPredefined.pdchDXCoolCoilIEERIP, coil.name, "N/A")
                addFootNoteSubTable(state, state.dataOutRptPredefined.pdstDXCoolCoil, AHRI2017FOOTNOTE)
                if state.dataHVACGlobal.StandardRatingsMyCoolOneTimeFlag2:
                    alias Format_991_: StringLiteral = (
                        "! <DX Cooling Coil AHRI 2023 Standard Rating Information>, Component Type, Component Name, Standard Rating (Net) "
                        "Cooling Capacity {W}, Standard Rating Net COP2 {W/W}, EER2 {Btu/W-h}, SEER2 User {Btu/W-h}, SEER2 Standard "
                        "{Btu/W-h}, "
                        "IEER 2022 "
                        "{Btu/W-h}"
                    )
                    print(state.files.eio, "{}\n".format(Format_991_))
                    state.dataHVACGlobal.StandardRatingsMyCoolOneTimeFlag2 = False
                PopulateCoolingCoilStandardRatingInformation(
                    state.files.eio, coil.name,
                    coil.performance[].standardRatingCoolingCapacity2023,
                    coil.performance[].standardRatingEER2,
                    coil.performance[].standardRatingSEER2_User,
                    coil.performance[].standardRatingSEER2_Standard,
                    coil.performance[].standardRatingIEER2,
                    True
                )
                PreDefTableEntry(state, state.dataOutRptPredefined.pdchDXCoolCoilType_2023, coil.name, "Coil:Cooling:DX")
                PreDefTableEntry(state, state.dataOutRptPredefined.pdchDXCoolCoilNetCapSI_2023, coil.name, coil.performance[].standardRatingCoolingCapacity2023, 1)
                if coil.performance[].standardRatingEER2 > 0.0:
                    PreDefTableEntry(state, state.dataOutRptPredefined.pdchDXCoolCoilCOP_2023, coil.name, coil.performance[].standardRatingEER2, 2)
                else:
                    PreDefTableEntry(state, state.dataOutRptPredefined.pdchDXCoolCoilCOP_2023, coil.name, "N/A")
                if coil.performance[].standardRatingEER2 > 0.0:
                    PreDefTableEntry(state, state.dataOutRptPredefined.pdchDXCoolCoilEERIP_2023, coil.name, coil.performance[].standardRatingEER2 * ConvFromSIToIP, 2)
                else:
                    PreDefTableEntry(state, state.dataOutRptPredefined.pdchDXCoolCoilEERIP_2023, coil.name, "N/A")
                if coil.performance[].standardRatingSEER2_User > 0.0:
                    PreDefTableEntry(state, state.dataOutRptPredefined.pdchDXCoolCoilSEER2UserIP_2023, coil.name, coil.performance[].standardRatingSEER2_User * ConvFromSIToIP, 2)
                else:
                    PreDefTableEntry(state, state.dataOutRptPredefined.pdchDXCoolCoilSEER2UserIP_2023, coil.name, "N/A")
                if coil.performance[].standardRatingSEER2_Standard > 0.0:
                    PreDefTableEntry(state, state.dataOutRptPredefined.pdchDXCoolCoilSEER2StandardIP_2023, coil.name, coil.performance[].standardRatingSEER2_Standard * ConvFromSIToIP, 2)
                else:
                    PreDefTableEntry(state, state.dataOutRptPredefined.pdchDXCoolCoilSEER2StandardIP_2023, coil.name, "N/A")
                if coil.performance[].standardRatingIEER2 > 0.0:
                    PreDefTableEntry(state, state.dataOutRptPredefined.pdchDXCoolCoilIEERIP_2023, coil.name, coil.performance[].standardRatingIEER2 * ConvFromSIToIP, 1)
                else:
                    PreDefTableEntry(state, state.dataOutRptPredefined.pdchDXCoolCoilIEERIP_2023, coil.name, "N/A")
                addFootNoteSubTable(state, state.dataOutRptPredefined.pdstDXCoolCoil_2023, AHRI2023FOOTNOTE)
        state.dataCoilCoolingDX.stillNeedToReportStandardRatings = False
    def findPerformanceSubclass(state: EnergyPlusData, object_to_find: StringLiteral, idd_performance_name: String) -> Bool:
        var ip = state.dataInputProcessing.inputProcessor[]
        if ip.getNumObjectsFound(state, object_to_find) > 0:
            var json_dict_performance = ip.epJSON.find(String(object_to_find))[]
            for instance in json_dict_performance.items():
                var performance_name = makeUPPER(instance.key())
                if performance_name == idd_performance_name:
                    return True
        return False
def PopulateCoolingCoilStandardRatingInformation(
    eio: OutputFile,
    coilName: String,
    capacity: Float64,
    eer: Float64,
    seer_User: Float64,
    seer_Standard: Float64,
    ieer: Float64,
    AHRI2023StandardRatings: Bool
):
    alias ConvFromSIToIP: Float64 = 3.412141633
    var Format_991: StringLiteral
    if not AHRI2023StandardRatings:
        Format_991 = " DX Cooling Coil Standard Rating Information, {}, {}, {:.1f}, {:.2f}, {:.2f}, {:.2f}, {:.2f}, {:.1f}\n"
    else:
        Format_991 = " DX Cooling Coil AHRI 2023 Standard Rating Information, {}, {}, {:.1f}, {:.2f}, {:.2f}, {:.2f}, {:.2f}, {:.1f}\n"
    print(eio,
          Format_991,
          "Coil:Cooling:DX",
          coilName,
          capacity,
          eer,
          eer * ConvFromSIToIP,
          seer_User * ConvFromSIToIP,
          seer_Standard * ConvFromSIToIP,
          ieer * ConvFromSIToIP)
struct CoilCoolingDXData:
    var coilCoolingDXs: List[CoilCoolingDX]
    var coilCoolingDXGetInputFlag: Bool = True
    var coilCoolingDXObjectName: String = "Coil:Cooling:DX"
    var coilType: CoilType = CoilType.CoolingDX
    var stillNeedToReportStandardRatings: Bool = True
    def init_constant_state(self, state: EnergyPlusData):

    def init_state(self, state: EnergyPlusData):

    def clear_state(inout self):
        self.coilCoolingDXs.clear()
        self.coilCoolingDXGetInputFlag = True
        self.stillNeedToReportStandardRatings = True