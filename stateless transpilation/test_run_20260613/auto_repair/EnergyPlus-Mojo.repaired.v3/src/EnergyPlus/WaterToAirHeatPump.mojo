from .Data.BaseData import *
from DataGlobals import *
from  import *
from FluidProperties import *
from General import *
from <cmath> import *
from BranchNodeConnections import *
from CurveManager import *
from DataContaminantBalance import *
from DataHVACGlobals import *
from DataLoopNode import *
from FluidProperties import *
from General import *
from GlobalNames import *
from .InputProcessing.InputProcessor import *
from NodeInputManager import *
from OutputProcessor import *
from OutputReportPredefined import *
from .Plant.DataPlant import *
from PlantUtilities import *
from Psychrometrics import *
from UtilityRoutines import *

enum CompressorType:
    Invalid = -1
    Reciprocating
    Rotary
    Scroll
    Num

struct WatertoAirHPEquipConditions:
    var Name: String  # Name of the Water to Air Heat pump
    var availSched: Optional[Sched.Schedule] = None  # availability schedule
    var WatertoAirHPType: String  # Type of WatertoAirHP ie. Heating or Cooling
    var WAHPType: DataPlant.PlantEquipmentType  # type of component in plant
    var Refrigerant: String  # Refrigerant name
    var refrig: Optional[Fluid.RefrigProps] = None
    var SimFlag: Bool
    var InletAirMassFlowRate: Float64  # Inlet Air Mass Flow through the Water to Air Heat Pump being Simulated [kg/s]
    var OutletAirMassFlowRate: Float64  # Outlet Air Mass Flow through the Water to Air Heat Pump being Simulated [kg/s]
    var InletAirDBTemp: Float64  # Inlet Air Dry Bulb Temperature [C]
    var InletAirHumRat: Float64  # Inlet Air Humidity Ratio [kg/kg]
    var OutletAirDBTemp: Float64  # Outlet Air Dry Bulb Temperature [C]
    var OutletAirHumRat: Float64  # Outlet Air Humidity Ratio [kg/kg]
    var InletAirEnthalpy: Float64  # Inlet Air Enthalpy [J/kg]
    var OutletAirEnthalpy: Float64  # Outlet Air Enthalpy [J/kg]
    var InletWaterTemp: Float64  # Inlet Water Temperature [C]
    var OutletWaterTemp: Float64  # Outlet Water Temperature [C]
    var InletWaterMassFlowRate: Float64  # Inlet Water Mass Flow Rate [kg/s]
    var OutletWaterMassFlowRate: Float64  # Outlet Water Mass Flow Rate [kg/s]
    var DesignWaterMassFlowRate: Float64  # Design Water Mass Flow Rate [kg/s]
    var DesignWaterVolFlowRate: Float64  # Design Water Volumetric Flow Rate [m3/s]
    var InletWaterEnthalpy: Float64  # Inlet Water Enthalpy [J/kg]
    var OutletWaterEnthalpy: Float64  # Outlet Water Enthalpy [J/kg]
    var Power: Float64  # Power Consumption [W]
    var Energy: Float64  # Energy Consumption [J]
    var QSensible: Float64  # Sensible Load Side Heat Transfer Rate [W]
    var QLatent: Float64  # Latent Load Side Heat Transfer Rate [W]
    var QSource: Float64  # Source Side Heat Transfer Rate [W]
    var EnergySensible: Float64  # Sensible Load Side Heat Transferred [J]
    var EnergyLatent: Float64  # Latent Load Side Heat Transferred [J]
    var EnergySource: Float64  # Source Side Heat Transferred [J]
    var RunFrac: Float64  # Duty Factor
    var PartLoadRatio: Float64  # Part Load Ratio
    var HeatingCapacity: Float64  # Nominal Heating Capacity
    var CoolingCapacity: Float64  # Nominal Cooling Capacity
    var QLoadTotal: Float64  # Load Side Total Heat Transfer Rate [W]
    var EnergyLoadTotal: Float64  # Load Side Total Heat Transferred [J]
    var Twet_Rated: Float64  # Nominal Time for Condensate Removal to Begin [s]
    var Gamma_Rated: Float64  # Ratio of Initial Moisture Evaporation Rate and Steady-state Latent Capacity
    var MaxONOFFCyclesperHour: Float64  # Maximum cycling rate of heat pump [cycles/hr]
    var LatentCapacityTimeConstant: Float64  # Latent capacity time constant [s]
    var FanDelayTime: Float64  # Fan delay time, time delay for the HP's fan to
    var SourceSideUACoeff: Float64  # Source Side Heat Transfer coefficient [W/C]
    var LoadSideTotalUACoeff: Float64  # Load Side Total Heat Transfer coefficient [W/C]
    var LoadSideOutsideUACoeff: Float64  # Load Side Outside Heat Transfer coefficient [W/C]
    var CompPistonDisp: Float64  # Compressor Piston Displacement [m3/s]
    var CompClearanceFactor: Float64  # Compressor Clearance Factor
    var CompSucPressDrop: Float64  # Suction Pressure Drop [Pa]
    var SuperheatTemp: Float64  # Superheat Temperature [C]
    var PowerLosses: Float64  # Constant Part of the Compressor Power Losses [W]
    var LossFactor: Float64  # Compressor Power Loss Factor
    var RefVolFlowRate: Float64  # Refrigerant Volume Flow rate at the beginning
    var VolumeRatio: Float64  # Built-in-volume ratio [~]
    var LeakRateCoeff: Float64  # Coefficient for the relationship between
    var SourceSideHTR1: Float64  # Source Side Heat Transfer Resistance coefficient 1 [~]
    var SourceSideHTR2: Float64  # Source Side Heat Transfer Resistance coefficient 2 [k/kW]
    var PLFCurveIndex: Int = 0  # Index of the Part Load Factor curve
    var HighPressCutoff: Float64  # High Pressure Cut-off [Pa]
    var LowPressCutoff: Float64  # Low Pressure Cut-off [Pa]
    var compressorType: CompressorType  # Type of Compressor ie. Reciprocating,Rotary or Scroll
    var AirInletNodeNum: Int  # air side coil inlet node number
    var AirOutletNodeNum: Int  # air side coil outlet node number
    var WaterInletNodeNum: Int  # water side coil inlet node number
    var WaterOutletNodeNum: Int  # water side coil outlet node number
    var LowPressClgError: Int  # count for low pressure errors (cooling)
    var HighPressClgError: Int  # count for high pressure errors (cooling)
    var LowPressHtgError: Int  # count for low pressure errors (heating)
    var HighPressHtgError: Int  # count for high pressure errors (heating)
    var plantLoc: PlantLocation
    var solveRootStats: General.SolveRootStats = General.SolveRootStats()

    def __init__(inout self):
        self.Name = String("")
        self.WatertoAirHPType = String("")
        self.WAHPType = DataPlant.PlantEquipmentType.Invalid
        self.SimFlag = False
        self.InletAirMassFlowRate = 0.0
        self.OutletAirMassFlowRate = 0.0
        self.InletAirDBTemp = 0.0
        self.InletAirHumRat = 0.0
        self.OutletAirDBTemp = 0.0
        self.OutletAirHumRat = 0.0
        self.InletAirEnthalpy = 0.0
        self.OutletAirEnthalpy = 0.0
        self.InletWaterTemp = 0.0
        self.OutletWaterTemp = 0.0
        self.InletWaterMassFlowRate = 0.0
        self.OutletWaterMassFlowRate = 0.0
        self.DesignWaterMassFlowRate = 0.0
        self.DesignWaterVolFlowRate = 0.0
        self.InletWaterEnthalpy = 0.0
        self.OutletWaterEnthalpy = 0.0
        self.Power = 0.0
        self.Energy = 0.0
        self.QSensible = 0.0
        self.QLatent = 0.0
        self.QSource = 0.0
        self.EnergySensible = 0.0
        self.EnergyLatent = 0.0
        self.EnergySource = 0.0
        self.RunFrac = 0.0
        self.PartLoadRatio = 0.0
        self.HeatingCapacity = 0.0
        self.CoolingCapacity = 0.0
        self.QLoadTotal = 0.0
        self.EnergyLoadTotal = 0.0
        self.Twet_Rated = 0.0
        self.Gamma_Rated = 0.0
        self.MaxONOFFCyclesperHour = 0.0
        self.LatentCapacityTimeConstant = 0.0
        self.FanDelayTime = 0.0
        self.SourceSideUACoeff = 0.0
        self.LoadSideTotalUACoeff = 0.0
        self.LoadSideOutsideUACoeff = 0.0
        self.CompPistonDisp = 0.0
        self.CompClearanceFactor = 0.0
        self.CompSucPressDrop = 0.0
        self.SuperheatTemp = 0.0
        self.PowerLosses = 0.0
        self.LossFactor = 0.0
        self.RefVolFlowRate = 0.0
        self.VolumeRatio = 0.0
        self.LeakRateCoeff = 0.0
        self.SourceSideHTR1 = 0.0
        self.SourceSideHTR2 = 0.0
        self.HighPressCutoff = 0.0
        self.LowPressCutoff = 0.0
        self.compressorType = CompressorType.Invalid
        self.AirInletNodeNum = 0
        self.AirOutletNodeNum = 0
        self.WaterInletNodeNum = 0
        self.WaterOutletNodeNum = 0
        self.LowPressClgError = 0
        self.HighPressClgError = 0
        self.LowPressHtgError = 0
        self.HighPressHtgError = 0

def SimWatertoAirHP(inout state: EnergyPlusData, CompName: StringLiteral, inout CompIndex: Int, DesignAirflow: Float64, fanOp: HVAC.FanOp, FirstHVACIteration: Bool, InitFlag: Bool, SensLoad: Float64, LatentLoad: Float64, compressorOp: HVAC.CompressorOp, PartLoadRatio: Float64):
    var HPNum: Int
    if state.dataWaterToAirHeatPump.GetCoilsInputFlag:
        GetWatertoAirHPInput(state)
        state.dataWaterToAirHeatPump.GetCoilsInputFlag = False
    if CompIndex == 0:
        HPNum = Util.FindItemInList(CompName, state.dataWaterToAirHeatPump.WatertoAirHP)
        if HPNum == 0:
            ShowFatalError(state, EnergyPlus.format("WaterToAir HP not found={}", CompName))
        CompIndex = HPNum
    else:
        HPNum = CompIndex
        if HPNum > state.dataWaterToAirHeatPump.NumWatertoAirHPs or HPNum < 1:
            ShowFatalError(state, EnergyPlus.format("SimWatertoAirHP: Invalid CompIndex passed={}, Number of Water to Air HPs={}, WaterToAir HP name={}", HPNum, state.dataWaterToAirHeatPump.NumWatertoAirHPs, CompName))
        if state.dataWaterToAirHeatPump.CheckEquipName[HPNum]:
            if not CompName.empty() and CompName != state.dataWaterToAirHeatPump.WatertoAirHP[HPNum].Name:
                ShowFatalError(state, EnergyPlus.format("SimWatertoAirHP: Invalid CompIndex passed={}, WaterToAir HP name={}, stored WaterToAir HP Name for that index={}", HPNum, CompName, state.dataWaterToAirHeatPump.WatertoAirHP[HPNum].Name))
            state.dataWaterToAirHeatPump.CheckEquipName[HPNum] = False
    if state.dataWaterToAirHeatPump.WatertoAirHP[HPNum].WAHPType == DataPlant.PlantEquipmentType.CoilWAHPCoolingParamEst:
        InitWatertoAirHP(state, HPNum, InitFlag, SensLoad, LatentLoad, DesignAirflow, PartLoadRatio)
        CalcWatertoAirHPCooling(state, HPNum, fanOp, FirstHVACIteration, InitFlag, SensLoad, compressorOp, PartLoadRatio)
        UpdateWatertoAirHP(state, HPNum)
    elif state.dataWaterToAirHeatPump.WatertoAirHP[HPNum].WAHPType == DataPlant.PlantEquipmentType.CoilWAHPHeatingParamEst:
        InitWatertoAirHP(state, HPNum, InitFlag, SensLoad, LatentLoad, DesignAirflow, PartLoadRatio)
        CalcWatertoAirHPHeating(state, HPNum, fanOp, FirstHVACIteration, InitFlag, SensLoad, compressorOp, PartLoadRatio)
        UpdateWatertoAirHP(state, HPNum)
    else:
        ShowFatalError(state, "SimWatertoAirHP: AirtoAir heatpump not in either HEATING or COOLING")

def GetWatertoAirHPInput(inout state: EnergyPlusData):
    alias RoutineName: StringLiteral = "GetWatertoAirHPInput: "
    alias routineName: StringLiteral = "GetWatertoAirHPInput"
    var HPNum: Int
    var NumCool: Int
    var NumHeat: Int
    var ErrorsFound: Bool = False
    var CurrentModuleObject: String
    alias CompressTypeNamesUC: StaticArray[StringLiteral, 3] = StaticArray("RECIPROCATING", "ROTARY", "SCROLL")
    var s_ip = state.dataInputProcessing.inputProcessor
    NumCool = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "Coil:Cooling:WaterToAirHeatPump:ParameterEstimation")
    NumHeat = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "Coil:Heating:WaterToAirHeatPump:ParameterEstimation")
    state.dataWaterToAirHeatPump.NumWatertoAirHPs = NumCool + NumHeat
    HPNum = 0
    if state.dataWaterToAirHeatPump.NumWatertoAirHPs <= 0:
        ShowSevereError(state, "No Equipment found in SimWatertoAirHP")
        ErrorsFound = True
    if state.dataWaterToAirHeatPump.NumWatertoAirHPs > 0:
        state.dataWaterToAirHeatPump.WatertoAirHP = List[WatertoAirHPEquipConditions](capacity=state.dataWaterToAirHeatPump.NumWatertoAirHPs)
        for _ in range(state.dataWaterToAirHeatPump.NumWatertoAirHPs + 1):
            state.dataWaterToAirHeatPump.WatertoAirHP.append(WatertoAirHPEquipConditions())
        state.dataWaterToAirHeatPump.CheckEquipName = List[Bool](repeated=True, capacity=state.dataWaterToAirHeatPump.NumWatertoAirHPs + 1)
        for _ in range(state.dataWaterToAirHeatPump.NumWatertoAirHPs + 1):
            state.dataWaterToAirHeatPump.CheckEquipName.append(True)
    CurrentModuleObject = "Coil:Cooling:WaterToAirHeatPump:ParameterEstimation"
    var instances = s_ip.epJSON.get(CurrentModuleObject)
    HPNum = 0
    if instances:
        var schemaProps = s_ip.getObjectSchemaProps(state, CurrentModuleObject)
        var instancesValue = instances.value()
        for instance in instancesValue.items():
            var cFieldName: String
            var fields = instance.value()
            var thisObjectName = instance.key()
            s_ip.markObjectAsUsed(CurrentModuleObject, thisObjectName)
            HPNum += 1
            var heatPump = state.dataWaterToAirHeatPump.WatertoAirHP[HPNum]
            heatPump.Name = Util.makeUPPER(thisObjectName)
            heatPump.WatertoAirHPType = "COOLING"
            heatPump.WAHPType = DataPlant.PlantEquipmentType.CoilWAHPCoolingParamEst
            var eoh = ErrorObjectHeader(routineName, CurrentModuleObject, heatPump.Name)
            GlobalNames.VerifyUniqueCoilName(state, CurrentModuleObject, heatPump.Name, ErrorsFound, EnergyPlus.format("{} Name", CurrentModuleObject))
            var availSchedName = s_ip.getAlphaFieldValue(fields, schemaProps, "availability_schedule_name")
            if availSchedName.empty():
                heatPump.availSched = Sched.GetScheduleAlwaysOn(state)
            else:
                heatPump.availSched = Sched.GetSchedule(state, availSchedName)
                if heatPump.availSched is None:
                    ShowSevereItemNotFound(state, eoh, "Availability Schedule Name", availSchedName)
                    ErrorsFound = True
            cFieldName = "Refrigerant Type"
            heatPump.Refrigerant = s_ip.getAlphaFieldValue(fields, schemaProps, "refrigerant_type")
            if heatPump.Refrigerant.empty():
                ShowSevereEmptyField(state, eoh, cFieldName)
                ErrorsFound = True
            else:
                heatPump.refrig = Fluid.GetRefrig(state, heatPump.Refrigerant)
                if heatPump.refrig is None:
                    ShowSevereItemNotFound(state, eoh, cFieldName, heatPump.Refrigerant)
                    ErrorsFound = True
            heatPump.DesignWaterVolFlowRate = s_ip.getRealFieldValue(fields, schemaProps, "design_source_side_flow_rate")
            heatPump.CoolingCapacity = s_ip.getRealFieldValue(fields, schemaProps, "nominal_cooling_coil_capacity")
            heatPump.Twet_Rated = s_ip.getRealFieldValue(fields, schemaProps, "nominal_time_for_condensate_removal_to_begin")
            heatPump.Gamma_Rated = s_ip.getRealFieldValue(fields, schemaProps, "ratio_of_initial_moisture_evaporation_rate_and_steady_state_latent_capacity")
            heatPump.HighPressCutoff = s_ip.getRealFieldValue(fields, schemaProps, "high_pressure_cutoff")
            heatPump.LowPressCutoff = s_ip.getRealFieldValue(fields, schemaProps, "low_pressure_cutoff")
            var waterInletNodeName = s_ip.getAlphaFieldValue(fields, schemaProps, "water_inlet_node_name")
            var waterOutletNodeName = s_ip.getAlphaFieldValue(fields, schemaProps, "water_outlet_node_name")
            var airInletNodeName = s_ip.getAlphaFieldValue(fields, schemaProps, "air_inlet_node_name")
            var airOutletNodeName = s_ip.getAlphaFieldValue(fields, schemaProps, "air_outlet_node_name")
            heatPump.WaterInletNodeNum = GetOnlySingleNode(state, waterInletNodeName, ErrorsFound, Node.ConnectionObjectType.CoilCoolingWaterToAirHeatPumpParameterEstimation, heatPump.Name, Node.FluidType.Water, Node.ConnectionType.Inlet, Node.CompFluidStream.Secondary, Node.ObjectIsNotParent)
            heatPump.WaterOutletNodeNum = GetOnlySingleNode(state, waterOutletNodeName, ErrorsFound, Node.ConnectionObjectType.CoilCoolingWaterToAirHeatPumpParameterEstimation, heatPump.Name, Node.FluidType.Water, Node.ConnectionType.Outlet, Node.CompFluidStream.Secondary, Node.ObjectIsNotParent)
            heatPump.AirInletNodeNum = GetOnlySingleNode(state, airInletNodeName, ErrorsFound, Node.ConnectionObjectType.CoilCoolingWaterToAirHeatPumpParameterEstimation, heatPump.Name, Node.FluidType.Air, Node.ConnectionType.Inlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
            heatPump.AirOutletNodeNum = GetOnlySingleNode(state, airOutletNodeName, ErrorsFound, Node.ConnectionObjectType.CoilCoolingWaterToAirHeatPumpParameterEstimation, heatPump.Name, Node.FluidType.Air, Node.ConnectionType.Outlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
            heatPump.LoadSideTotalUACoeff = s_ip.getRealFieldValue(fields, schemaProps, "load_side_total_heat_transfer_coefficient")
            heatPump.LoadSideOutsideUACoeff = s_ip.getRealFieldValue(fields, schemaProps, "load_side_outside_surface_heat_transfer_coefficient")
            if (heatPump.LoadSideOutsideUACoeff < Constant.rTinyValue) or (heatPump.LoadSideTotalUACoeff < Constant.rTinyValue):
                ShowSevereError(state, EnergyPlus.format("Input problem for {}={}", CurrentModuleObject, heatPump.Name))
                ShowContinueError(state, " One or both load side UA values entered are below tolerance, likely zero or blank.")
                ShowContinueError(state, " Verify inputs, as the parameter syntax for this object went through a change with")
                ShowContinueError(state, "  the release of EnergyPlus version 5.")
                ErrorsFound = True
            heatPump.SuperheatTemp = s_ip.getRealFieldValue(fields, schemaProps, "superheat_temperature_at_the_evaporator_outlet")
            heatPump.PowerLosses = s_ip.getRealFieldValue(fields, schemaProps, "compressor_power_losses")
            heatPump.LossFactor = s_ip.getRealFieldValue(fields, schemaProps, "compressor_efficiency")
            var compType = s_ip.getAlphaFieldValue(fields, schemaProps, "compressor_type")
            heatPump.compressorType = CompressorType(getEnumValue(CompressTypeNamesUC, Util.makeUPPER(compType)))
            if heatPump.compressorType == CompressorType.Reciprocating:
                heatPump.CompPistonDisp = s_ip.getRealFieldValue(fields, schemaProps, "compressor_piston_displacement")
                heatPump.CompSucPressDrop = s_ip.getRealFieldValue(fields, schemaProps, "compressor_suction_discharge_pressure_drop")
                heatPump.CompClearanceFactor = s_ip.getRealFieldValue(fields, schemaProps, "compressor_clearance_factor")
            elif heatPump.compressorType == CompressorType.Rotary:
                heatPump.CompPistonDisp = s_ip.getRealFieldValue(fields, schemaProps, "compressor_piston_displacement")
                heatPump.CompSucPressDrop = s_ip.getRealFieldValue(fields, schemaProps, "compressor_suction_discharge_pressure_drop")
            elif heatPump.compressorType == CompressorType.Scroll:
                heatPump.RefVolFlowRate = s_ip.getRealFieldValue(fields, schemaProps, "refrigerant_volume_flow_rate")
                heatPump.VolumeRatio = s_ip.getRealFieldValue(fields, schemaProps, "volume_ratio")
                heatPump.LeakRateCoeff = s_ip.getRealFieldValue(fields, schemaProps, "leak_rate_coefficient")
            else:
                ShowSevereInvalidKey(state, eoh, "Compressor Type", compType)
                ErrorsFound = True
            heatPump.SourceSideUACoeff = s_ip.getRealFieldValue(fields, schemaProps, "source_side_heat_transfer_coefficient")
            heatPump.SourceSideHTR1 = s_ip.getRealFieldValue(fields, schemaProps, "source_side_heat_transfer_resistance1")
            heatPump.SourceSideHTR2 = s_ip.getRealFieldValue(fields, schemaProps, "source_side_heat_transfer_resistance2")
            cFieldName = "Part Load Fraction Correlation Curve Name"
            var coolPLFCurveName = s_ip.getAlphaFieldValue(fields, schemaProps, "part_load_fraction_correlation_curve_name")
            if coolPLFCurveName.empty():
                ShowWarningEmptyField(state, eoh, cFieldName, "Required field is blank.")
                ErrorsFound = True
            else:
                heatPump.PLFCurveIndex = Curve.GetCurveIndex(state, coolPLFCurveName)
                if heatPump.PLFCurveIndex == 0:
                    ShowSevereItemNotFound(state, eoh, cFieldName, coolPLFCurveName)
                    ErrorsFound = True
                elif Curve.CheckCurveDims(state, heatPump.PLFCurveIndex, {1}, RoutineName, CurrentModuleObject, heatPump.Name, cFieldName):
                    ShowSevereCustomField(state, eoh, cFieldName, coolPLFCurveName, "Illegal curve dimension.")
                    ErrorsFound = True
                else:
                    var MinCurveVal: Float64 = 999.0
                    var MaxCurveVal: Float64 = -999.0
                    var CurveInput: Float64 = 0.0
                    var MinCurvePLR: Float64 = 0.0
                    var MaxCurvePLR: Float64 = 0.0
                    while CurveInput <= 1.0:
                        var CurveVal = Curve.CurveValue(state, heatPump.PLFCurveIndex, CurveInput)
                        if CurveVal < MinCurveVal:
                            MinCurveVal = CurveVal
                            MinCurvePLR = CurveInput
                        if CurveVal > MaxCurveVal:
                            MaxCurveVal = CurveVal
                            MaxCurvePLR = CurveInput
                        CurveInput += 0.01
                    if MinCurveVal < 0.7:
                        ShowSevereBadMin(state, eoh, cFieldName, MinCurveVal, Clusive.In, 0.7, "Setting curve minimum to 0.7 and simulation continues.")
                        Curve.SetCurveOutputMinValue(state, heatPump.PLFCurveIndex, ErrorsFound, 0.7)
                    if MaxCurveVal > 1.0:
                        ShowSevereBadMax(state, eoh, cFieldName, MaxCurveVal, Clusive.In, 1.0, "Setting curve maximum to 1.0 and simulation continues.")
                        Curve.SetCurveOutputMaxValue(state, heatPump.PLFCurveIndex, ErrorsFound, 1.0)
            Node.TestCompSet(state, CurrentModuleObject, heatPump.Name, waterInletNodeName, waterOutletNodeName, "Water Nodes")
            Node.TestCompSet(state, CurrentModuleObject, heatPump.Name, airInletNodeName, airOutletNodeName, "Air Nodes")
            heatPump.MaxONOFFCyclesperHour = s_ip.getRealFieldValue(fields, schemaProps, "maximum_cycling_rate")
            heatPump.LatentCapacityTimeConstant = s_ip.getRealFieldValue(fields, schemaProps, "latent_capacity_time_constant")
            heatPump.FanDelayTime = s_ip.getRealFieldValue(fields, schemaProps, "fan_delay_time")
            SetupOutputVariable(state, "Cooling Coil Electricity Energy", Constant.Units.J, heatPump.Energy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, heatPump.Name, Constant.eResource.Electricity, OutputProcessor.Group.HVAC, OutputProcessor.EndUseCat.Cooling)
            SetupOutputVariable(state, "Cooling Coil Total Cooling Energy", Constant.Units.J, heatPump.EnergyLoadTotal, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, heatPump.Name, Constant.eResource.EnergyTransfer, OutputProcessor.Group.HVAC, OutputProcessor.EndUseCat.CoolingCoils)
            SetupOutputVariable(state, "Cooling Coil Sensible Cooling Energy", Constant.Units.J, heatPump.EnergySensible, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, heatPump.Name)
            SetupOutputVariable(state, "Cooling Coil Latent Cooling Energy", Constant.Units.J, heatPump.EnergyLatent, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, heatPump.Name)
            SetupOutputVariable(state, "Cooling Coil Source Side Heat Transfer Energy", Constant.Units.J, heatPump.EnergySource, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, heatPump.Name, Constant.eResource.PlantLoopCoolingDemand, OutputProcessor.Group.HVAC, OutputProcessor.EndUseCat.CoolingCoils)
            PlantUtilities.RegisterPlantCompDesignFlow(state, heatPump.WaterInletNodeNum, 0.5 * heatPump.DesignWaterVolFlowRate)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoolCoilType, heatPump.Name, CurrentModuleObject)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoolCoilTotCap, heatPump.Name, heatPump.CoolingCapacity)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoolCoilSensCap, heatPump.Name, "-")
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoolCoilLatCap, heatPump.Name, "-")
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoolCoilSHR, heatPump.Name, "-")
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoolCoilNomEff, heatPump.Name, "-")
    CurrentModuleObject = "Coil:Heating:WaterToAirHeatPump:ParameterEstimation"
    var instances_h = s_ip.epJSON.get(CurrentModuleObject)
    if instances_h:
        var schemaProps = s_ip.getObjectSchemaProps(state, CurrentModuleObject)
        var instancesValue = instances_h.value()
        for instance in instancesValue.items():
            var cFieldName: String
            var fields = instance.value()
            var thisObjectName = instance.key()
            s_ip.markObjectAsUsed(CurrentModuleObject, thisObjectName)
            HPNum += 1
            var heatPump = state.dataWaterToAirHeatPump.WatertoAirHP[HPNum]
            heatPump.Name = Util.makeUPPER(thisObjectName)
            heatPump.WatertoAirHPType = "HEATING"
            heatPump.WAHPType = DataPlant.PlantEquipmentType.CoilWAHPHeatingParamEst
            var eoh = ErrorObjectHeader(routineName, CurrentModuleObject, heatPump.Name)
            GlobalNames.VerifyUniqueCoilName(state, CurrentModuleObject, heatPump.Name, ErrorsFound, EnergyPlus.format("{} Name", CurrentModuleObject))
            var availSchedName = s_ip.getAlphaFieldValue(fields, schemaProps, "availability_schedule_name")
            if availSchedName.empty():
                heatPump.availSched = Sched.GetScheduleAlwaysOn(state)
            else:
                heatPump.availSched = Sched.GetSchedule(state, availSchedName)
                if heatPump.availSched is None:
                    ShowSevereItemNotFound(state, eoh, "Availability Schedule Name", availSchedName)
                    ErrorsFound = True
            cFieldName = "Refrigerant Type"
            heatPump.Refrigerant = s_ip.getAlphaFieldValue(fields, schemaProps, "refrigerant_type")
            if heatPump.Refrigerant.empty():
                ShowSevereEmptyField(state, eoh, cFieldName)
                ErrorsFound = True
            else:
                heatPump.refrig = Fluid.GetRefrig(state, heatPump.Refrigerant)
                if heatPump.refrig is None:
                    ShowSevereItemNotFound(state, eoh, cFieldName, heatPump.Refrigerant)
                    ErrorsFound = True
            heatPump.DesignWaterVolFlowRate = s_ip.getRealFieldValue(fields, schemaProps, "design_source_side_flow_rate")
            heatPump.HeatingCapacity = s_ip.getRealFieldValue(fields, schemaProps, "gross_rated_heating_capacity")
            heatPump.HighPressCutoff = s_ip.getRealFieldValue(fields, schemaProps, "high_pressure_cutoff")
            heatPump.LowPressCutoff = s_ip.getRealFieldValue(fields, schemaProps, "low_pressure_cutoff")
            var waterInletNodeName = s_ip.getAlphaFieldValue(fields, schemaProps, "water_inlet_node_name")
            var waterOutletNodeName = s_ip.getAlphaFieldValue(fields, schemaProps, "water_outlet_node_name")
            var airInletNodeName = s_ip.getAlphaFieldValue(fields, schemaProps, "air_inlet_node_name")
            var airOutletNodeName = s_ip.getAlphaFieldValue(fields, schemaProps, "air_outlet_node_name")
            heatPump.WaterInletNodeNum = GetOnlySingleNode(state, waterInletNodeName, ErrorsFound, Node.ConnectionObjectType.CoilCoolingWaterToAirHeatPumpParameterEstimation, heatPump.Name, Node.FluidType.Water, Node.ConnectionType.Inlet, Node.CompFluidStream.Secondary, Node.ObjectIsNotParent)
            heatPump.WaterOutletNodeNum = GetOnlySingleNode(state, waterOutletNodeName, ErrorsFound, Node.ConnectionObjectType.CoilCoolingWaterToAirHeatPumpParameterEstimation, heatPump.Name, Node.FluidType.Water, Node.ConnectionType.Outlet, Node.CompFluidStream.Secondary, Node.ObjectIsNotParent)
            heatPump.AirInletNodeNum = GetOnlySingleNode(state, airInletNodeName, ErrorsFound, Node.ConnectionObjectType.CoilCoolingWaterToAirHeatPumpParameterEstimation, heatPump.Name, Node.FluidType.Air, Node.ConnectionType.Inlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
            heatPump.AirOutletNodeNum = GetOnlySingleNode(state, airOutletNodeName, ErrorsFound, Node.ConnectionObjectType.CoilCoolingWaterToAirHeatPumpParameterEstimation, heatPump.Name, Node.FluidType.Air, Node.ConnectionType.Outlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
            heatPump.LoadSideTotalUACoeff = s_ip.getRealFieldValue(fields, schemaProps, "load_side_total_heat_transfer_coefficient")
            if heatPump.LoadSideTotalUACoeff < Constant.rTinyValue:
                ShowSevereError(state, EnergyPlus.format("Input problem for {}={}", CurrentModuleObject, heatPump.Name))
                ShowContinueError(state, " Load side UA value is less than tolerance, likely zero or blank.")
                ShowContinueError(state, " Verify inputs, as the parameter syntax for this object went through a change with")
                ShowContinueError(state, "  the release of EnergyPlus version 5.")
                ErrorsFound = True
            heatPump.SuperheatTemp = s_ip.getRealFieldValue(fields, schemaProps, "superheat_temperature_at_the_evaporator_outlet")
            heatPump.PowerLosses = s_ip.getRealFieldValue(fields, schemaProps, "compressor_power_losses")
            heatPump.LossFactor = s_ip.getRealFieldValue(fields, schemaProps, "compressor_efficiency")
            var compType = s_ip.getAlphaFieldValue(fields, schemaProps, "compressor_type")
            heatPump.compressorType = CompressorType(getEnumValue(CompressTypeNamesUC, Util.makeUPPER(compType)))
            if heatPump.compressorType == CompressorType.Reciprocating:
                heatPump.CompPistonDisp = s_ip.getRealFieldValue(fields, schemaProps, "compressor_piston_displacement")
                heatPump.CompSucPressDrop = s_ip.getRealFieldValue(fields, schemaProps, "compressor_suction_discharge_pressure_drop")
                heatPump.CompClearanceFactor = s_ip.getRealFieldValue(fields, schemaProps, "compressor_clearance_factor")
            elif heatPump.compressorType == CompressorType.Rotary:
                heatPump.CompPistonDisp = s_ip.getRealFieldValue(fields, schemaProps, "compressor_piston_displacement")
                heatPump.CompSucPressDrop = s_ip.getRealFieldValue(fields, schemaProps, "compressor_suction_discharge_pressure_drop")
            elif heatPump.compressorType == CompressorType.Scroll:
                heatPump.RefVolFlowRate = s_ip.getRealFieldValue(fields, schemaProps, "refrigerant_volume_flow_rate")
                heatPump.VolumeRatio = s_ip.getRealFieldValue(fields, schemaProps, "volume_ratio")
                heatPump.LeakRateCoeff = s_ip.getRealFieldValue(fields, schemaProps, "leak_rate_coefficient")
            else:
                ShowSevereInvalidKey(state, eoh, "Compressor Type", compType)
                ErrorsFound = True
            heatPump.SourceSideUACoeff = s_ip.getRealFieldValue(fields, schemaProps, "source_side_heat_transfer_coefficient")
            heatPump.SourceSideHTR1 = s_ip.getRealFieldValue(fields, schemaProps, "source_side_heat_transfer_resistance1")
            heatPump.SourceSideHTR2 = s_ip.getRealFieldValue(fields, schemaProps, "source_side_heat_transfer_resistance2")
            cFieldName = "Part Load Fraction Correlation Curve Name"
            var coolPLFCurveName = s_ip.getAlphaFieldValue(fields, schemaProps, "part_load_fraction_correlation_curve_name")
            if coolPLFCurveName.empty():
                ShowWarningEmptyField(state, eoh, cFieldName, "Required field is blank.")
                ErrorsFound = True
            else:
                heatPump.PLFCurveIndex = Curve.GetCurveIndex(state, coolPLFCurveName)
                if heatPump.PLFCurveIndex == 0:
                    ShowSevereItemNotFound(state, eoh, cFieldName, coolPLFCurveName)
                    ErrorsFound = True
                elif Curve.CheckCurveDims(state, heatPump.PLFCurveIndex, {1}, RoutineName, CurrentModuleObject, heatPump.Name, cFieldName):
                    ShowSevereCustomField(state, eoh, cFieldName, coolPLFCurveName, "Illegal curve dimension.")
                    ErrorsFound = True
                else:
                    var MinCurveVal: Float64 = 999.0
                    var MaxCurveVal: Float64 = -999.0
                    var CurveInput: Float64 = 0.0
                    var MinCurvePLR: Float64 = 0.0
                    var MaxCurvePLR: Float64 = 0.0
                    while CurveInput <= 1.0:
                        var CurveVal = Curve.CurveValue(state, heatPump.PLFCurveIndex, CurveInput)
                        if CurveVal < MinCurveVal:
                            MinCurveVal = CurveVal
                            MinCurvePLR = CurveInput
                        if CurveVal > MaxCurveVal:
                            MaxCurveVal = CurveVal
                            MaxCurvePLR = CurveInput
                        CurveInput += 0.01
                    if MinCurveVal < 0.7:
                        ShowSevereBadMin(state, eoh, cFieldName, MinCurveVal, Clusive.In, 0.7, "Setting curve minimum to 0.7 and simulation continues.")
                        Curve.SetCurveOutputMinValue(state, heatPump.PLFCurveIndex, ErrorsFound, 0.7)
                    if MaxCurveVal > 1.0:
                        ShowSevereBadMax(state, eoh, cFieldName, MaxCurveVal, Clusive.In, 1.0, "Setting curve maximum to 1.0 and simulation continues.")
                        Curve.SetCurveOutputMaxValue(state, heatPump.PLFCurveIndex, ErrorsFound, 1.0)
            Node.TestCompSet(state, CurrentModuleObject, heatPump.Name, waterInletNodeName, waterOutletNodeName, "Water Nodes")
            Node.TestCompSet(state, CurrentModuleObject, heatPump.Name, airInletNodeName, airOutletNodeName, "Air Nodes")
            SetupOutputVariable(state, "Heating Coil Electricity Energy", Constant.Units.J, heatPump.Energy, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, heatPump.Name, Constant.eResource.Electricity, OutputProcessor.Group.HVAC, OutputProcessor.EndUseCat.Heating)
            SetupOutputVariable(state, "Heating Coil Heating Energy", Constant.Units.J, heatPump.EnergyLoadTotal, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, heatPump.Name, Constant.eResource.EnergyTransfer, OutputProcessor.Group.HVAC, OutputProcessor.EndUseCat.HeatingCoils)
            SetupOutputVariable(state, "Heating Coil Source Side Heat Transfer Energy", Constant.Units.J, heatPump.EnergySource, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, heatPump.Name, Constant.eResource.PlantLoopHeatingDemand, OutputProcessor.Group.HVAC, OutputProcessor.EndUseCat.HeatingCoils)
            PlantUtilities.RegisterPlantCompDesignFlow(state, heatPump.WaterInletNodeNum, 0.5 * heatPump.DesignWaterVolFlowRate)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchHeatCoilType, heatPump.Name, CurrentModuleObject)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchHeatCoilNomCap, heatPump.Name, heatPump.HeatingCapacity)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchHeatCoilNomEff, heatPump.Name, "-")
    if ErrorsFound:
        ShowFatalError(state, EnergyPlus.format("{}Errors found getting input. Program terminates.", RoutineName))
    for HPNum in range(1, state.dataWaterToAirHeatPump.NumWatertoAirHPs + 1):
        var heatPump = state.dataWaterToAirHeatPump.WatertoAirHP[HPNum]
        if heatPump.WAHPType == DataPlant.PlantEquipmentType.CoilWAHPCoolingParamEst:
            SetupOutputVariable(state, "Cooling Coil Electricity Rate", Constant.Units.W, heatPump.Power, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, heatPump.Name)
            SetupOutputVariable(state, "Cooling Coil Total Cooling Rate", Constant.Units.W, heatPump.QLoadTotal, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, heatPump.Name)
            SetupOutputVariable(state, "Cooling Coil Sensible Cooling Rate", Constant.Units.W, heatPump.QSensible, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, heatPump.Name)
            SetupOutputVariable(state, "Cooling Coil Latent Cooling Rate", Constant.Units.W, heatPump.QLatent, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, heatPump.Name)
            SetupOutputVariable(state, "Cooling Coil Source Side Heat Transfer Rate", Constant.Units.W, heatPump.QSource, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, heatPump.Name)
            SetupOutputVariable(state, "Cooling Coil Part Load Ratio", Constant.Units.None, heatPump.PartLoadRatio, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, heatPump.Name)
            SetupOutputVariable(state, "Cooling Coil Runtime Fraction", Constant.Units.None, heatPump.RunFrac, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, heatPump.Name)
            SetupOutputVariable(state, "Cooling Coil Air Mass Flow Rate", Constant.Units.kg_s, heatPump.OutletAirMassFlowRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, heatPump.Name)
            SetupOutputVariable(state, "Cooling Coil Air Inlet Temperature", Constant.Units.C, heatPump.InletAirDBTemp, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, heatPump.Name)
            SetupOutputVariable(state, "Cooling Coil Air Inlet Humidity Ratio", Constant.Units.kgWater_kgDryAir, heatPump.InletAirHumRat, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, heatPump.Name)
            SetupOutputVariable(state, "Cooling Coil Air Outlet Temperature", Constant.Units.C, heatPump.OutletAirDBTemp, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, heatPump.Name)
            SetupOutputVariable(state, "Cooling Coil Air Outlet Humidity Ratio", Constant.Units.kgWater_kgDryAir, heatPump.OutletAirHumRat, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, heatPump.Name)
            SetupOutputVariable(state, "Cooling Coil Source Side Mass Flow Rate", Constant.Units.kg_s, heatPump.OutletWaterMassFlowRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, heatPump.Name)
            SetupOutputVariable(state, "Cooling Coil Source Side Inlet Temperature", Constant.Units.C, heatPump.InletWaterTemp, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, heatPump.Name)
            SetupOutputVariable(state, "Cooling Coil Source Side Outlet Temperature", Constant.Units.C, heatPump.OutletWaterTemp, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, heatPump.Name)
        elif heatPump.WAHPType == DataPlant.PlantEquipmentType.CoilWAHPHeatingParamEst:
            SetupOutputVariable(state, "Heating Coil Electricity Rate", Constant.Units.W, heatPump.Power, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, heatPump.Name)
            SetupOutputVariable(state, "Heating Coil Heating Rate", Constant.Units.W, heatPump.QLoadTotal, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, heatPump.Name)
            SetupOutputVariable(state, "Heating Coil Sensible Heating Rate", Constant.Units.W, heatPump.QSensible, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, heatPump.Name)
            SetupOutputVariable(state, "Heating Coil Source Side Heat Transfer Rate", Constant.Units.W, heatPump.QSource, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, heatPump.Name)
            SetupOutputVariable(state, "Heating Coil Part Load Ratio", Constant.Units.None, heatPump.PartLoadRatio, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, heatPump.Name)
            SetupOutputVariable(state, "Heating Coil Runtime Fraction", Constant.Units.None, heatPump.RunFrac, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, heatPump.Name)
            SetupOutputVariable(state, "Heating Coil Air Mass Flow Rate", Constant.Units.kg_s, heatPump.OutletAirMassFlowRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, heatPump.Name)
            SetupOutputVariable(state, "Heating Coil Air Inlet Temperature", Constant.Units.C, heatPump.InletAirDBTemp, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, heatPump.Name)
            SetupOutputVariable(state, "Heating Coil Air Inlet Humidity Ratio", Constant.Units.kgWater_kgDryAir, heatPump.InletAirHumRat, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, heatPump.Name)
            SetupOutputVariable(state, "Heating Coil Air Outlet Temperature", Constant.Units.C, heatPump.OutletAirDBTemp, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, heatPump.Name)
            SetupOutputVariable(state, "Heating Coil Air Outlet Humidity Ratio", Constant.Units.kgWater_kgDryAir, heatPump.OutletAirHumRat, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, heatPump.Name)
            SetupOutputVariable(state, "Heating Coil Source Side Mass Flow Rate", Constant.Units.kg_s, heatPump.OutletWaterMassFlowRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, heatPump.Name)
            SetupOutputVariable(state, "Heating Coil Source Side Inlet Temperature", Constant.Units.C, heatPump.InletWaterTemp, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, heatPump.Name)
            SetupOutputVariable(state, "Heating Coil Source Side Outlet Temperature", Constant.Units.C, heatPump.OutletWaterTemp, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, heatPump.Name)

def InitWatertoAirHP(inout state: EnergyPlusData, HPNum: Int, InitFlag: Bool, SensLoad: Float64, LatentLoad: Float64, DesignAirFlow: Float64, PartLoadRatio: Float64):
    var heatPump = state.dataWaterToAirHeatPump.WatertoAirHP[HPNum]
    alias RoutineName: StringLiteral = "InitWatertoAirHP"
    var WaterInletNode = heatPump.WaterInletNodeNum
    if state.dataWaterToAirHeatPump.MyOneTimeFlag:
        state.dataWaterToAirHeatPump.MyEnvrnFlag = List[Bool](capacity=state.dataWaterToAirHeatPump.NumWatertoAirHPs + 1)
        for _ in range(state.dataWaterToAirHeatPump.NumWatertoAirHPs + 1):
            state.dataWaterToAirHeatPump.MyEnvrnFlag.append(True)
        state.dataWaterToAirHeatPump.MyPlantScanFlag = List[Bool](capacity=state.dataWaterToAirHeatPump.NumWatertoAirHPs + 1)
        for _ in range(state.dataWaterToAirHeatPump.NumWatertoAirHPs + 1):
            state.dataWaterToAirHeatPump.MyPlantScanFlag.append(True)
        state.dataWaterToAirHeatPump.MyOneTimeFlag = False
    if state.dataWaterToAirHeatPump.MyPlantScanFlag[HPNum] and allocated(state.dataPlnt.PlantLoop):
        var errFlag: Bool = False
        PlantUtilities.ScanPlantLoopsForObject(state, heatPump.Name, heatPump.WAHPType, heatPump.plantLoc, errFlag)
        if heatPump.plantLoc.loop.FluidName == "WATER":
            if heatPump.SourceSideUACoeff < Constant.rTinyValue:
                ShowSevereError(state, EnergyPlus.format("Input problem for water to air heat pump, \"{}\".", heatPump.Name))
                ShowContinueError(state, " Source side UA value is less than tolerance, likely zero or blank.")
                ShowContinueError(state, " Verify inputs, as the parameter syntax for this object went through a change with")
                ShowContinueError(state, "  the release of EnergyPlus version 5.")
                errFlag = True
        else:
            if (heatPump.SourceSideHTR1 < Constant.rTinyValue) or (heatPump.SourceSideHTR2 < Constant.rTinyValue):
                ShowSevereError(state, EnergyPlus.format("Input problem for water to air heat pump, \"{}\".", heatPump.Name))
                ShowContinueError(state, " A source side heat transfer resistance value is less than tolerance, likely zero or blank.")
                ShowContinueError(state, " Verify inputs, as the parameter syntax for this object went through a change with")
                ShowContinueError(state, "  the release of EnergyPlus version 5.")
                errFlag = True
        if errFlag:
            ShowFatalError(state, "InitWatertoAirHP: Program terminated for previous conditions.")
        state.dataWaterToAirHeatPump.MyPlantScanFlag[HPNum] = False
    if state.dataGlobal.BeginEnvrnFlag and state.dataWaterToAirHeatPump.MyEnvrnFlag[HPNum] and not state.dataWaterToAirHeatPump.MyPlantScanFlag[HPNum]:
        heatPump.Power = 0.0
        heatPump.Energy = 0.0
        heatPump.QLoadTotal = 0.0
        heatPump.QSensible = 0.0
        heatPump.QLatent = 0.0
        heatPump.QSource = 0.0
        heatPump.EnergyLoadTotal = 0.0
        heatPump.EnergySensible = 0.0
        heatPump.EnergyLatent = 0.0
        heatPump.EnergySource = 0.0
        heatPump.RunFrac = 0.0
        heatPump.PartLoadRatio = 0.0
        heatPump.OutletAirDBTemp = 0.0
        heatPump.OutletAirHumRat = 0.0
        heatPump.InletAirDBTemp = 0.0
        heatPump.InletAirHumRat = 0.0
        heatPump.OutletWaterTemp = 0.0
        heatPump.InletWaterTemp = 0.0
        heatPump.InletAirMassFlowRate = 0.0
        heatPump.InletWaterMassFlowRate = 0.0
        heatPump.OutletAirEnthalpy = 0.0
        heatPump.OutletWaterEnthalpy = 0.0
        var rho = heatPump.plantLoc.loop.glycol.getDensity(state, Constant.InitConvTemp, RoutineName)
        var Cp = heatPump.plantLoc.loop.glycol.getSpecificHeat(state, Constant.InitConvTemp, RoutineName)
        heatPump.DesignWaterMassFlowRate = rho * heatPump.DesignWaterVolFlowRate
        var PlantOutletNode = DataPlant.CompData.getPlantComponent(state, heatPump.plantLoc).NodeNumOut
        PlantUtilities.InitComponentNodes(state, 0.0, heatPump.DesignWaterMassFlowRate, WaterInletNode, PlantOutletNode)
        state.dataLoopNodes.Node[WaterInletNode].Temp = 5.0
        state.dataLoopNodes.Node[WaterInletNode].Enthalpy = Cp * state.dataLoopNodes.Node[WaterInletNode].Temp
        state.dataLoopNodes.Node[WaterInletNode].Quality = 0.0
        state.dataLoopNodes.Node[WaterInletNode].Press = 0.0
        state.dataLoopNodes.Node[WaterInletNode].HumRat = 0.0
        state.dataLoopNodes.Node[PlantOutletNode].Temp = 5.0
        state.dataLoopNodes.Node[PlantOutletNode].Enthalpy = Cp * state.dataLoopNodes.Node[WaterInletNode].Temp
        state.dataLoopNodes.Node[PlantOutletNode].Quality = 0.0
        state.dataLoopNodes.Node[PlantOutletNode].Press = 0.0
        state.dataLoopNodes.Node[PlantOutletNode].HumRat = 0.0
        heatPump.SimFlag = True
        state.dataWaterToAirHeatPump.MyEnvrnFlag[HPNum] = False
    if not state.dataGlobal.BeginEnvrnFlag:
        state.dataWaterToAirHeatPump.MyEnvrnFlag[HPNum] = True
    var AirInletNode = heatPump.AirInletNodeNum
    if ((SensLoad != 0.0 or LatentLoad != 0.0) or (SensLoad == 0.0 and InitFlag)) and state.dataLoopNodes.Node[AirInletNode].MassFlowRate > 0.0 and PartLoadRatio > 0.0 and (heatPump.availSched.getCurrentVal() > 0.0):
        heatPump.InletWaterMassFlowRate = heatPump.DesignWaterMassFlowRate
        heatPump.InletAirMassFlowRate = DesignAirFlow
    else:
        heatPump.InletWaterMassFlowRate = 0.0
        heatPump.InletAirMassFlowRate = 0.0
    PlantUtilities.SetComponentFlowRate(state, heatPump.InletWaterMassFlowRate, heatPump.WaterInletNodeNum, heatPump.WaterOutletNodeNum, heatPump.plantLoc)
    heatPump.InletWaterTemp = state.dataLoopNodes.Node[WaterInletNode].Temp
    heatPump.InletWaterEnthalpy = state.dataLoopNodes.Node[WaterInletNode].Enthalpy
    heatPump.InletAirDBTemp = state.dataLoopNodes.Node[AirInletNode].Temp
    heatPump.InletAirHumRat = state.dataLoopNodes.Node[AirInletNode].HumRat
    heatPump.InletAirEnthalpy = state.dataLoopNodes.Node[AirInletNode].Enthalpy
    heatPump.Power = 0.0
    heatPump.Energy = 0.0
    heatPump.QLoadTotal = 0.0
    heatPump.QSensible = 0.0
    heatPump.QLatent = 0.0
    heatPump.QSource = 0.0
    heatPump.EnergyLoadTotal = 0.0
    heatPump.EnergySensible = 0.0
    heatPump.EnergyLatent = 0.0
    heatPump.EnergySource = 0.0
    heatPump.RunFrac = 0.0
    heatPump.OutletAirDBTemp = 0.0
    heatPump.OutletAirHumRat = 0.0
    heatPump.OutletWaterTemp = 0.0
    heatPump.OutletAirEnthalpy = 0.0
    heatPump.OutletWaterEnthalpy = 0.0

def CalcWatertoAirHPCooling(inout state: EnergyPlusData, HPNum: Int, fanOp: HVAC.FanOp, FirstHVACIteration: Bool, InitFlag: Bool, SensDemand: Float64, compressorOp: HVAC.CompressorOp, PartLoadRatio: Float64):
    var heatPump = state.dataWaterToAirHeatPump.WatertoAirHP[HPNum]
    alias CpWater: Float64 = 4210.0
    alias DegreeofSuperheat: Float64 = 80.0
    alias gamma: Float64 = 1.114
    alias ERR: Float64 = 0.01
    alias PB: Float64 = 1.013e5
    alias STOP1: Int = 1000
    alias STOP2: Int = 1000
    alias STOP3: Int = 1000
    alias RoutineNameSourceSideInletTemp: StringLiteral = "CalcWatertoAirHPCooling:SourceSideInletTemp"
    alias RoutineNameSourceSideTemp: StringLiteral = "CalcWatertoAirHPCooling:SourceSideTemp"
    alias RoutineNameLoadSideTemp: StringLiteral = "CalcWatertoAirHPCooling:LoadSideTemp"
    alias RoutineNameLoadSideSurfaceTemp: StringLiteral = "CalcWatertoAirHPCooling:LoadSideSurfaceTemp"
    alias RoutineNameLoadSideEvapTemp: StringLiteral = "CalcWatertoAirHPCooling:LoadSideEvapTemp"
    alias RoutineNameLoadSideOutletEnthalpy: StringLiteral = "CalcWatertoAirHPCooling:LoadSideOutletEnthalpy"
    alias RoutineNameCompressInletTemp: StringLiteral = "CalcWatertoAirHPCooling:CompressInletTemp"
    alias RoutineNameSuctionPr: StringLiteral = "CalcWatertoAirHPCooling:SuctionPr"
    alias RoutineNameCompSuctionTemp: StringLiteral = "CalcWatertoAirHPCooling:CompSuctionTemp"
    var NumIteration3: Int
    var NumIteration4: Int
    var Quality: Float64
    var SourceSideOutletTemp: Float64
    var SourceSideVolFlowRate: Float64
    var DegradFactor: Float64
    var CpFluid: Float64
    var LoadSideInletWBTemp: Float64
    var LoadSideInletDBTemp: Float64
    var LoadSideInletHumRat: Float64
    var LoadSideOutletDBTemp: Float64
    var LoadSideOutletHumRat: Float64
    var LoadSideAirInletEnth: Float64
    var LoadSideAirOutletEnth: Float64
    var EffectiveSurfaceTemp: Float64
    var EffectiveSatEnth: Float64
    var QSource: Float64
    var QLoadTotal: Float64
    var QSensible: Float64
    var Power: Float64
    var EvapTemp: Float64
    var ANTUWET: Float64
    var EffectWET: Float64
    var EvapSatEnth: Float64
    var SourceSideEffect: Float64
    var SourceSideTemp: Float64
    var LoadSideTemp: Float64
    var SourceSidePressure: Float64
    var LoadSidePressure: Float64
    var SuctionPr: Float64
    var DischargePr: Float64
    var CompressInletTemp: Float64
    var MassRef: Float64
    var SourceSideOutletEnth: Float64
    var LoadSideOutletEnth: Float64
    var CpAir: Float64
    var SuperHeatEnth: Float64
    var CompSuctionTemp1: Float64
    var CompSuctionTemp2: Float64
    var CompSuctionEnth: Float64
    var CompSuctionDensity: Float64
    var CompSuctionSatTemp: Float64
    var LatDegradModelSimFlag: Bool
    var StillSimulatingFlag: Bool
    var Converged: Bool
    var QLatRated: Float64
    var QLatActual: Float64
    var SHRss: Float64
    var SHReff: Float64
    var SolFlag: Int
    var LoadSideAirInletEnth_Unit: Float64
    var LoadResidual: Float64
    var SourceResidual: Float64
    var RelaxParam: Float64 = 0.5
    if state.dataWaterToAirHeatPump.firstTime:
        state.dataWaterToAirHeatPump.LoadSideInletDBTemp_Init = 26.7
        state.dataWaterToAirHeatPump.LoadSideInletHumRat_Init = 0.0111
        state.dataWaterToAirHeatPump.LoadSideAirInletEnth_Init = Psychrometrics.PsyHFnTdbW(state.dataWaterToAirHeatPump.LoadSideInletDBTemp_Init, state.dataWaterToAirHeatPump.LoadSideInletHumRat_Init)
        state.dataWaterToAirHeatPump.firstTime = False
    CpAir = Psychrometrics.PsyCpAirFnW(heatPump.InletAirHumRat)
    LoadSideAirInletEnth_Unit = Psychrometrics.PsyHFnTdbW(heatPump.InletAirDBTemp, heatPump.InletAirHumRat)
    SourceSideVolFlowRate = heatPump.InletWaterMassFlowRate / heatPump.plantLoc.loop.glycol.getDensity(state, heatPump.InletWaterTemp, RoutineNameSourceSideInletTemp)
    StillSimulatingFlag = True
    if SensDemand == 0.0 or heatPump.InletAirMassFlowRate <= 0.0 or heatPump.InletWaterMassFlowRate <= 0.0 or (heatPump.availSched.getCurrentVal() <= 0.0):
        heatPump.SimFlag = False
        return
    heatPump.SimFlag = True
    if compressorOp == HVAC.CompressorOp.Off:
        heatPump.SimFlag = False
        return
    if FirstHVACIteration:
        state.dataWaterToAirHeatPump.initialQSource_calc = heatPump.CoolingCapacity
        state.dataWaterToAirHeatPump.initialQLoadTotal_calc = heatPump.CoolingCapacity
    if state.dataWaterToAirHeatPump.initialQLoadTotal_calc == 0.0:
        state.dataWaterToAirHeatPump.initialQLoadTotal_calc = heatPump.CoolingCapacity
    if state.dataWaterToAirHeatPump.initialQSource_calc == 0.0:
        state.dataWaterToAirHeatPump.initialQSource_calc = heatPump.CoolingCapacity
    var PLF: Float64 = 1.0
    if heatPump.PLFCurveIndex > 0:
        PLF = Curve.CurveValue(state, heatPump.PLFCurveIndex, PartLoadRatio)
    if fanOp == HVAC.FanOp.Cycling:
        state.dataHVACGlobal.OnOffFanPartLoadFraction = PLF
    heatPump.RunFrac = PartLoadRatio / PLF
    QLatRated = 0.0
    QLatActual = 0.0
    if (heatPump.RunFrac >= 1.0) or (heatPump.Twet_Rated <= 0.0) or (heatPump.Gamma_Rated <= 0.0) or (fanOp == HVAC.FanOp.Cycling):
        LatDegradModelSimFlag = False
        NumIteration4 = 1
    else:
        LatDegradModelSimFlag = True
        NumIteration4 = 0
    var LoadSideMassFlowRate_CpAir_inv: Float64 = 1.0 / (heatPump.InletAirMassFlowRate * CpAir)
    var LoadSideEffec: Float64 = 1.0 - exp(-heatPump.LoadSideOutsideUACoeff * LoadSideMassFlowRate_CpAir_inv)
    var LoadSideEffec_MassFlowRate_inv: Float64 = 1.0 / (LoadSideEffec * heatPump.InletAirMassFlowRate)
    ANTUWET = heatPump.LoadSideTotalUACoeff * LoadSideMassFlowRate_CpAir_inv
    EffectWET = 1.0 - exp(-ANTUWET)
    while True:
        NumIteration4 += 1
        if NumIteration4 == 1:
            LoadSideInletDBTemp = state.dataWaterToAirHeatPump.LoadSideInletDBTemp_Init
            LoadSideInletHumRat = state.dataWaterToAirHeatPump.LoadSideInletHumRat_Init
            LoadSideAirInletEnth = state.dataWaterToAirHeatPump.LoadSideAirInletEnth_Init
        else:
            LoadSideInletDBTemp = heatPump.InletAirDBTemp
            LoadSideInletHumRat = heatPump.InletAirHumRat
            LoadSideAirInletEnth = LoadSideAirInletEnth_Unit
        var NumIteration2: Int = 0
        Converged = False
        StillSimulatingFlag = True
        SourceResidual = 1.0
        while StillSimulatingFlag:
            if Converged:
                StillSimulatingFlag = False
            NumIteration2 += 1
            if NumIteration2 == 1:
                RelaxParam = 0.5
            if NumIteration2 > STOP2:
                heatPump.SimFlag = False
                return
            NumIteration3 = 0
            LoadResidual = 1.0
            while LoadResidual > ERR:
                NumIteration3 += 1
                if NumIteration3 > STOP3:
                    heatPump.SimFlag = False
                    return
                CpFluid = heatPump.plantLoc.loop.glycol.getSpecificHeat(state, heatPump.InletWaterTemp, RoutineNameSourceSideInletTemp)
                if heatPump.plantLoc.loop.glycol.Num == Fluid.GlycolNum_Water:
                    SourceSideEffect = 1.0 - exp(-heatPump.SourceSideUACoeff / (CpFluid * heatPump.InletWaterMassFlowRate))
                else:
                    DegradFactor = DegradF(state, heatPump.plantLoc.loop.glycol, heatPump.InletWaterTemp)
                    SourceSideEffect = 1.0 / ((heatPump.SourceSideHTR1 * pow(SourceSideVolFlowRate, -0.8)) / DegradFactor + heatPump.SourceSideHTR2)
                SourceSideTemp = heatPump.InletWaterTemp + state.dataWaterToAirHeatPump.initialQSource_calc / (SourceSideEffect * CpFluid * heatPump.InletWaterMassFlowRate)
                EffectiveSatEnth = LoadSideAirInletEnth - state.dataWaterToAirHeatPump.initialQLoadTotal_calc * LoadSideEffec_MassFlowRate_inv
                EffectiveSurfaceTemp = Psychrometrics.PsyTsatFnHPb(state, EffectiveSatEnth, PB, RoutineNameLoadSideSurfaceTemp)
                QSensible = heatPump.InletAirMassFlowRate * CpAir * (LoadSideInletDBTemp - EffectiveSurfaceTemp) * LoadSideEffec
                EvapSatEnth = LoadSideAirInletEnth - state.dataWaterToAirHeatPump.initialQLoadTotal_calc / (EffectWET * heatPump.InletAirMassFlowRate)
                EvapTemp = Psychrometrics.PsyTsatFnHPb(state, EvapSatEnth, PB, RoutineNameLoadSideEvapTemp)
                LoadSideTemp = EvapTemp
                SourceSidePressure = heatPump.refrig.getSatPressure(state, SourceSideTemp, RoutineNameSourceSideTemp)
                LoadSidePressure = heatPump.refrig.getSatPressure(state, LoadSideTemp, RoutineNameLoadSideTemp)
                if LoadSidePressure < heatPump.LowPressCutoff and not FirstHVACIteration:
                    if not state.dataGlobal.WarmupFlag:
                        ShowRecurringWarningErrorAtEnd(state, EnergyPlus.format("WaterToAir Heat pump:cooling [{}] shut off on low pressure < {:.0R}", heatPump.Name, heatPump.LowPressCutoff), heatPump.LowPressClgError, LoadSidePressure, LoadSidePressure, "[Pa]", "[Pa]")
                    heatPump.SimFlag = False
                    return
                if SourceSidePressure > heatPump.HighPressCutoff and not FirstHVACIteration:
                    if not state.dataGlobal.WarmupFlag:
                        ShowRecurringWarningErrorAtEnd(state, EnergyPlus.format("WaterToAir Heat pump:cooling [{}] shut off on high pressure > {:.0R}", heatPump.Name, heatPump.HighPressCutoff), heatPump.HighPressClgError, heatPump.InletWaterTemp, heatPump.InletWaterTemp, "SourceSideInletTemp[C]", "SourceSideInletTemp[C]")
                    heatPump.SimFlag = False
                    return
                if heatPump.compressorType == CompressorType.Reciprocating:
                    SuctionPr = LoadSidePressure - heatPump.CompSucPressDrop
                    DischargePr = SourceSidePressure + heatPump.CompSucPressDrop
                elif heatPump.compressorType == CompressorType.Rotary:
                    SuctionPr = LoadSidePressure
                    DischargePr = SourceSidePressure + heatPump.CompSucPressDrop
                elif heatPump.compressorType == CompressorType.Scroll:
                    SuctionPr = LoadSidePressure
                    DischargePr = SourceSidePressure
                Quality = 1.0
                LoadSideOutletEnth = heatPump.refrig.getSatEnthalpy(state, LoadSideTemp, Quality, RoutineNameLoadSideTemp)
                Quality = 0.0
                SourceSideOutletEnth = heatPump.refrig.getSatEnthalpy(state, SourceSideTemp, Quality, RoutineNameSourceSideTemp)
                CompressInletTemp = LoadSideTemp + heatPump.SuperheatTemp
                SuperHeatEnth = heatPump.refrig.getSupHeatEnthalpy(state, CompressInletTemp, LoadSidePressure, RoutineNameCompressInletTemp)
                if not Converged:
                    CompSuctionSatTemp = heatPump.refrig.getSatTemperature(state, SuctionPr, RoutineNameSuctionPr)
                    CompSuctionTemp1 = CompSuctionSatTemp
                    CompSuctionTemp2 = CompSuctionSatTemp + DegreeofSuperheat
                def f(CompSuctionTemp: Float64) -> Float64:
                    alias RoutineName: StringLiteral = "CalcWaterToAirHPHeating:CalcCompSuctionTemp"
                    var compSuctionEnth = heatPump.refrig.getSupHeatEnthalpy(state, CompSuctionTemp, SuctionPr, RoutineName)
                    return (compSuctionEnth - SuperHeatEnth) / SuperHeatEnth
                state.dataWaterToAirHeatPump.CompSuctionTemp = General.SolveRoot2(state, ERR, STOP1, SolFlag, f, CompSuctionTemp1, CompSuctionTemp2, heatPump.solveRootStats)
                if SolFlag == General.SOLVEROOT_ERROR_ITER:
                    heatPump.SimFlag = False
                    return
                CompSuctionEnth = heatPump.refrig.getSupHeatEnthalpy(state, state.dataWaterToAirHeatPump.CompSuctionTemp, SuctionPr, RoutineNameCompSuctionTemp)
                CompSuctionDensity = heatPump.refrig.getSupHeatDensity(state, state.dataWaterToAirHeatPump.CompSuctionTemp, SuctionPr, RoutineNameCompSuctionTemp)
                if heatPump.compressorType == CompressorType.Reciprocating:
                    MassRef = heatPump.CompPistonDisp * CompSuctionDensity * (1.0 + heatPump.CompClearanceFactor - heatPump.CompClearanceFactor * pow(DischargePr / SuctionPr, 1.0 / gamma))
                elif heatPump.compressorType == CompressorType.Rotary:
                    MassRef = heatPump.CompPistonDisp * CompSuctionDensity
                elif heatPump.compressorType == CompressorType.Scroll:
                    MassRef = heatPump.RefVolFlowRate * CompSuctionDensity - heatPump.LeakRateCoeff * (DischargePr / SuctionPr)
                MassRef = max(0.0, MassRef)
                QLoadTotal = MassRef * (LoadSideOutletEnth - SourceSideOutletEnth)
                LoadResidual = abs(QLoadTotal - state.dataWaterToAirHeatPump.initialQLoadTotal_calc) / state.dataWaterToAirHeatPump.initialQLoadTotal_calc
                state.dataWaterToAirHeatPump.initialQLoadTotal_calc += RelaxParam * (QLoadTotal - state.dataWaterToAirHeatPump.initialQLoadTotal_calc)
                if NumIteration3 > 8:
                    RelaxParam = 0.3
            if heatPump.compressorType == CompressorType.Reciprocating or heatPump.compressorType == CompressorType.Rotary:
                Power = heatPump.PowerLosses + (1.0 / heatPump.LossFactor) * (MassRef * gamma / (gamma - 1.0) * SuctionPr / CompSuctionDensity * (pow(DischargePr / SuctionPr, (gamma - 1.0) / gamma) - 1.0))
            elif heatPump.compressorType == CompressorType.Scroll:
                Power = heatPump.PowerLosses + (1.0 / heatPump.LossFactor) * (gamma / (gamma - 1.0)) * SuctionPr * heatPump.RefVolFlowRate * (((gamma - 1.0) / gamma) * ((DischargePr / SuctionPr) / heatPump.VolumeRatio) + ((1.0 / gamma) * pow(heatPump.VolumeRatio, gamma - 1.0)) - 1.0)
            QSource = Power + QLoadTotal
            SourceResidual = abs(QSource - state.dataWaterToAirHeatPump.initialQSource_calc) / state.dataWaterToAirHeatPump.initialQSource_calc
            if SourceResidual < ERR:
                Converged = True
            state.dataWaterToAirHeatPump.initialQSource_calc += RelaxParam * (QSource - state.dataWaterToAirHeatPump.initialQSource_calc)
            if NumIteration2 > 8:
                RelaxParam = 0.2
        if SuctionPr < heatPump.LowPressCutoff:
            ShowWarningError(state, "Heat pump:cooling shut down on low pressure")
            heatPump.SimFlag = False
        if DischargePr > heatPump.HighPressCutoff and not FirstHVACIteration:
            ShowWarningError(state, "Heat pump:cooling shut down on high pressure")
            heatPump.SimFlag = False
        if QSensible > QLoadTotal:
            QSensible = QLoadTotal
        if LatDegradModelSimFlag:
            if NumIteration4 == 1:
                QLatRated = QLoadTotal - QSensible
            elif NumIteration4 == 2:
                QLatActual = QLoadTotal - QSensible
                SHRss = QSensible / QLoadTotal
                LoadSideInletWBTemp = Psychrometrics.PsyTwbFnTdbWPb(state, LoadSideInletDBTemp, LoadSideInletHumRat, PB)
                SHReff = CalcEffectiveSHR(state, HPNum, SHRss, fanOp, heatPump.RunFrac, QLatRated, QLatActual, LoadSideInletDBTemp, LoadSideInletWBTemp)
                QSensible = QLoadTotal * SHReff
                break
        else:
            SHReff = QSensible / QLoadTotal
            break
    LoadSideAirOutletEnth = LoadSideAirInletEnth - QLoadTotal / heatPump.InletAirMassFlowRate
    LoadSideOutletDBTemp = LoadSideInletDBTemp - QSensible * LoadSideMassFlowRate_CpAir_inv
    LoadSideOutletHumRat = Psychrometrics.PsyWFnTdbH(state, LoadSideOutletDBTemp, LoadSideAirOutletEnth, RoutineNameLoadSideOutletEnthalpy)
    SourceSideOutletTemp = heatPump.InletWaterTemp + QSource / (heatPump.InletWaterMassFlowRate * CpWater)
    if fanOp == HVAC.FanOp.Continuous:
        heatPump.OutletAirEnthalpy = PartLoadRatio * LoadSideAirOutletEnth + (1.0 - PartLoadRatio) * LoadSideAirInletEnth
        heatPump.OutletAirHumRat = PartLoadRatio * LoadSideOutletHumRat + (1.0 - PartLoadRatio) * LoadSideInletHumRat
        heatPump.OutletAirDBTemp = Psychrometrics.PsyTdbFnHW(heatPump.OutletAirEnthalpy, heatPump.OutletAirHumRat)
    else:
        heatPump.OutletAirEnthalpy = LoadSideAirOutletEnth
        heatPump.OutletAirHumRat = LoadSideOutletHumRat
        heatPump.OutletAirDBTemp = LoadSideOutletDBTemp
    QLoadTotal *= PartLoadRatio
    QSensible *= PartLoadRatio
    Power *= heatPump.RunFrac
    QSource *= PartLoadRatio
    state.dataHVACGlobal.DXElecCoolingPower = Power
    heatPump.Power = Power
    heatPump.QLoadTotal = QLoadTotal
    heatPump.QSensible = QSensible
    heatPump.QLatent = QLoadTotal - QSensible
    heatPump.QSource = QSource
    heatPump.PartLoadRatio = PartLoadRatio
    heatPump.OutletAirMassFlowRate = heatPump.InletAirMassFlowRate
    heatPump.OutletWaterTemp = SourceSideOutletTemp
    heatPump.OutletWaterMassFlowRate = heatPump.InletWaterMassFlowRate
    heatPump.OutletWaterEnthalpy = heatPump.InletWaterEnthalpy + QSource / heatPump.InletWaterMassFlowRate

def CalcWatertoAirHPHeating(inout state: EnergyPlusData, HPNum: Int, fanOp: HVAC.FanOp, FirstHVACIteration: Bool, InitFlag: Bool, SensDemand: Float64, compressorOp: HVAC.CompressorOp, PartLoadRatio: Float64):
    var heatPump = state.dataWaterToAirHeatPump.WatertoAirHP[HPNum]
    alias CpWater: Float64 = 4210.0
    alias DegreeofSuperheat: Float64 = 80.0
    alias gamma: Float64 = 1.114
    var RelaxParam: Float64 = 0.5
    alias ERR: Float64 = 0.01
    alias STOP1: Int = 1000
    alias STOP2: Int = 1000
    alias STOP3: Int = 1000
    alias RoutineNameSourceSideInletTemp: StringLiteral = "CalcWatertoAirHPHeating:SourceSideInletTemp"
    alias RoutineNameSourceSideTemp: StringLiteral = "CalcWatertoAirHPHeating:SourceSideTemp"
    alias RoutineNameLoadSideTemp: StringLiteral = "CalcWatertoAirHPHeating:LoadSideTemp"
    alias RoutineNameLoadSideOutletEnthalpy: StringLiteral = "CalcWatertoAirHPHeating:LoadSideOutletEnthalpy"
    alias RoutineNameCompressInletTemp: StringLiteral = "CalcWatertoAirHPHeating:CompressInletTemp"
    alias RoutineNameSuctionPr: StringLiteral = "CalcWatertoAirHPHeating:SuctionPr"
    alias RoutineNameCompSuctionTemp: StringLiteral = "CalcWatertoAirHPHeating:CompSuctionTemp"
    var NumIteration3: Int
    var Quality: Float64
    var SourceSideOutletTemp: Float64
    var SourceSideVolFlowRate: Float64
    var CpFluid: Float64
    var LoadSideOutletDBTemp: Float64
    var LoadSideOutletHumRat: Float64
    var LoadSideAirOutletEnth: Float64
    var CpAir: Float64
    var DegradFactor: Float64
    var QSource: Float64
    var QLoadTotal: Float64
    var Power: Float64
    var SourceSideEffect: Float64
    var SourceSideTemp: Float64
    var LoadSideTemp: Float64
    var SourceSidePressure: Float64
    var LoadSidePressure: Float64
    var SuctionPr: Float64
    var DischargePr: Float64
    var CompressInletTemp: Float64
    var MassRef: Float64
    var SourceSideOutletEnth: Float64
    var LoadSideOutletEnth: Float64
    var SuperHeatEnth: Float64
    var CompSuctionTemp1: Float64
    var CompSuctionTemp2: Float64
    var CompSuctionTemp: Float64
    var CompSuctionEnth: Float64
    var CompSuctionDensity: Float64
    var CompSuctionSatTemp: Float64
    var StillSimulatingFlag: Bool
    var Converged: Bool
    var SolFlag: Int
    var LoadResidual: Float64
    var SourceResidual: Float64
    CpAir = Psychrometrics.PsyCpAirFnW(heatPump.InletAirHumRat)
    SourceSideVolFlowRate = heatPump.InletWaterMassFlowRate / heatPump.plantLoc.loop.glycol.getDensity(state, heatPump.InletWaterTemp, RoutineNameSourceSideInletTemp)
    if SensDemand == 0.0 or heatPump.InletAirMassFlowRate <= 0.0 or heatPump.InletWaterMassFlowRate <= 0.0 or (heatPump.availSched.getCurrentVal() <= 0.0):
        heatPump.SimFlag = False
        return
    heatPump.SimFlag = True
    if compressorOp == HVAC.CompressorOp.Off:
        heatPump.SimFlag = False
        return
    if FirstHVACIteration:
        state.dataWaterToAirHeatPump.initialQLoad = heatPump.HeatingCapacity
        state.dataWaterToAirHeatPump.initialQSource = heatPump.HeatingCapacity
    if state.dataWaterToAirHeatPump.initialQLoad == 0.0:
        state.dataWaterToAirHeatPump.initialQLoad = heatPump.HeatingCapacity
    if state.dataWaterToAirHeatPump.initialQSource == 0.0:
        state.dataWaterToAirHeatPump.initialQSource = heatPump.HeatingCapacity
    var LoadSideMassFlowRate_CpAir_inv: Float64 = 1.0 / (heatPump.InletAirMassFlowRate * CpAir)
    var LoadSideEffect: Float64 = 1.0 - exp(-heatPump.LoadSideTotalUACoeff * LoadSideMassFlowRate_CpAir_inv)
    var LoadSideEffect_CpAir_MassFlowRate_inv: Float64 = 1.0 / (LoadSideEffect * CpAir * heatPump.InletAirMassFlowRate)
    NumIteration3 = 0
    Converged = False
    StillSimulatingFlag = True
    LoadResidual = 1.0
    while StillSimulatingFlag:
        if Converged:
            StillSimulatingFlag = False
        NumIteration3 += 1
        if NumIteration3 == 1:
            RelaxParam = 0.5
        if NumIteration3 > STOP3:
            heatPump.SimFlag = False
            return
        var NumIteration2: Int = 0
        SourceResidual = 1.0
        while SourceResidual > ERR:
            NumIteration2 += 1
            if NumIteration2 > STOP2:
                heatPump.SimFlag = False
                return
            CpFluid = heatPump.plantLoc.loop.glycol.getSpecificHeat(state, heatPump.InletWaterTemp, RoutineNameSourceSideInletTemp)
            if heatPump.plantLoc.loop.glycol.Num == Fluid.GlycolNum_Water:
                SourceSideEffect = 1.0 - exp(-heatPump.SourceSideUACoeff / (CpFluid * heatPump.InletWaterMassFlowRate))
            else:
                DegradFactor = DegradF(state, heatPump.plantLoc.loop.glycol, heatPump.InletWaterTemp)
                SourceSideEffect = 1.0 / ((heatPump.SourceSideHTR1 * pow(SourceSideVolFlowRate, -0.8)) / DegradFactor + heatPump.SourceSideHTR2)
            SourceSideTemp = heatPump.InletWaterTemp - state.dataWaterToAirHeatPump.initialQSource / (SourceSideEffect * CpFluid * heatPump.InletWaterMassFlowRate)
            LoadSideTemp = heatPump.InletAirDBTemp + state.dataWaterToAirHeatPump.initialQLoad * LoadSideEffect_CpAir_MassFlowRate_inv
            SourceSidePressure = heatPump.refrig.getSatPressure(state, SourceSideTemp, RoutineNameSourceSideTemp)
            LoadSidePressure = heatPump.refrig.getSatPressure(state, LoadSideTemp, RoutineNameLoadSideTemp)
            if SourceSidePressure < heatPump.LowPressCutoff and not FirstHVACIteration:
                if not state.dataGlobal.WarmupFlag:
                    ShowRecurringWarningErrorAtEnd(state, EnergyPlus.format("WaterToAir Heat pump:heating [{}] shut off on low pressure < {:.0R}", heatPump.Name, heatPump.LowPressCutoff), heatPump.LowPressHtgError, SourceSidePressure, SourceSidePressure, "[Pa]", "[Pa]")
                heatPump.SimFlag = False
                return
            if LoadSidePressure > heatPump.HighPressCutoff and not FirstHVACIteration:
                if not state.dataGlobal.WarmupFlag:
                    ShowRecurringWarningErrorAtEnd(state, EnergyPlus.format("WaterToAir Heat pump:heating [{}] shut off on high pressure > {:.0R}", heatPump.Name, heatPump.HighPressCutoff), heatPump.HighPressHtgError, heatPump.InletWaterTemp, heatPump.InletWaterTemp, "SourceSideInletTemp[C]", "SourceSideInletTemp[C]")
                heatPump.SimFlag = False
                return
            if heatPump.compressorType == CompressorType.Reciprocating:
                SuctionPr = SourceSidePressure - heatPump.CompSucPressDrop
                DischargePr = LoadSidePressure + heatPump.CompSucPressDrop
            elif heatPump.compressorType == CompressorType.Rotary:
                SuctionPr = SourceSidePressure
                DischargePr = LoadSidePressure + heatPump.CompSucPressDrop
            elif heatPump.compressorType == CompressorType.Scroll:
                SuctionPr = SourceSidePressure
                DischargePr = LoadSidePressure
            Quality = 1.0
            SourceSideOutletEnth = heatPump.refrig.getSatEnthalpy(state, SourceSideTemp, Quality, RoutineNameSourceSideTemp)
            Quality = 0.0
            LoadSideOutletEnth = heatPump.refrig.getSatEnthalpy(state, LoadSideTemp, Quality, RoutineNameLoadSideTemp)
            CompressInletTemp = SourceSideTemp + heatPump.SuperheatTemp
            SuperHeatEnth = heatPump.refrig.getSupHeatEnthalpy(state, CompressInletTemp, SourceSidePressure, RoutineNameCompressInletTemp)
            if not Converged:
                CompSuctionSatTemp = heatPump.refrig.getSatTemperature(state, SuctionPr, RoutineNameSuctionPr)
                CompSuctionTemp1 = CompSuctionSatTemp
                CompSuctionTemp2 = CompSuctionSatTemp + DegreeofSuperheat
            def f(CompSuctionTemp: Float64) -> Float64:
                alias RoutineName: StringLiteral = "CalcWaterToAirHPHeating:CalcCompSuctionTemp"
                var compSuctionEnth = heatPump.refrig.getSupHeatEnthalpy(state, CompSuctionTemp, SuctionPr, RoutineName)
                return (compSuctionEnth - SuperHeatEnth) / SuperHeatEnth
            CompSuctionTemp = General.SolveRoot2(state, ERR, STOP1, SolFlag, f, CompSuctionTemp1, CompSuctionTemp2, heatPump.solveRootStats)
            if SolFlag == General.SOLVEROOT_ERROR_ITER:
                heatPump.SimFlag = False
                return
            CompSuctionEnth = heatPump.refrig.getSupHeatEnthalpy(state, CompSuctionTemp, SuctionPr, RoutineNameCompSuctionTemp)
            CompSuctionDensity = heatPump.refrig.getSupHeatDensity(state, CompSuctionTemp, SuctionPr, RoutineNameCompSuctionTemp)
            if heatPump.compressorType == CompressorType.Reciprocating:
                MassRef = heatPump.CompPistonDisp * CompSuctionDensity * (1.0 + heatPump.CompClearanceFactor - heatPump.CompClearanceFactor * pow(DischargePr / SuctionPr, 1.0 / gamma))
            elif heatPump.compressorType == CompressorType.Rotary:
                MassRef = heatPump.CompPistonDisp * CompSuctionDensity
            elif heatPump.compressorType == CompressorType.Scroll:
                MassRef = heatPump.RefVolFlowRate * CompSuctionDensity - heatPump.LeakRateCoeff * (DischargePr / SuctionPr)
            MassRef = max(0.0, MassRef)
            QSource = MassRef * (SourceSideOutletEnth - LoadSideOutletEnth)
            SourceResidual = abs(QSource - state.dataWaterToAirHeatPump.initialQSource) / state.dataWaterToAirHeatPump.initialQSource
            state.dataWaterToAirHeatPump.initialQSource += RelaxParam * (QSource - state.dataWaterToAirHeatPump.initialQSource)
            if NumIteration2 > 8:
                RelaxParam = 0.3
        if heatPump.compressorType == CompressorType.Reciprocating or heatPump.compressorType == CompressorType.Rotary:
            Power = heatPump.PowerLosses + (1.0 / heatPump.LossFactor) * (MassRef * gamma / (gamma - 1.0) * SuctionPr / CompSuctionDensity * (pow(DischargePr / SuctionPr, (gamma - 1.0) / gamma) - 1.0))
        elif heatPump.compressorType == CompressorType.Scroll:
            Power = heatPump.PowerLosses + (1.0 / heatPump.LossFactor) * (gamma / (gamma - 1.0)) * SuctionPr * heatPump.RefVolFlowRate * (((gamma - 1.0) / gamma) * ((DischargePr / SuctionPr) / heatPump.VolumeRatio) + ((1.0 / gamma) * pow(heatPump.VolumeRatio, gamma - 1.0)) - 1.0)
        QLoadTotal = Power + QSource
        LoadResidual = abs(QLoadTotal - state.dataWaterToAirHeatPump.initialQLoad) / state.dataWaterToAirHeatPump.initialQLoad
        if LoadResidual < ERR:
            Converged = True
        state.dataWaterToAirHeatPump.initialQLoad += RelaxParam * (QLoadTotal - state.dataWaterToAirHeatPump.initialQLoad)
        if NumIteration3 > 8:
            RelaxParam = 0.2
    if SuctionPr < heatPump.LowPressCutoff and not FirstHVACIteration:
        ShowWarningError(state, "Heat pump:heating shut down on low pressure")
        heatPump.SimFlag = False
        return
    if DischargePr > heatPump.HighPressCutoff and not FirstHVACIteration:
        ShowWarningError(state, "Heat pump:heating shut down on high pressure")
        heatPump.SimFlag = False
        return
    LoadSideAirOutletEnth = heatPump.InletAirEnthalpy + QLoadTotal / heatPump.InletAirMassFlowRate
    LoadSideOutletDBTemp = heatPump.InletAirDBTemp + QLoadTotal / (heatPump.InletAirMassFlowRate * CpAir)
    LoadSideOutletHumRat = Psychrometrics.PsyWFnTdbH(state, LoadSideOutletDBTemp, LoadSideAirOutletEnth, RoutineNameLoadSideOutletEnthalpy)
    SourceSideOutletTemp = heatPump.InletWaterTemp - QSource / (heatPump.InletWaterMassFlowRate * CpWater)
    if fanOp == HVAC.FanOp.Continuous:
        heatPump.OutletAirEnthalpy = PartLoadRatio * LoadSideAirOutletEnth + (1.0 - PartLoadRatio) * heatPump.InletAirEnthalpy
        heatPump.OutletAirHumRat = PartLoadRatio * LoadSideOutletHumRat + (1.0 - PartLoadRatio) * heatPump.InletAirHumRat
        heatPump.OutletAirDBTemp = Psychrometrics.PsyTdbFnHW(heatPump.OutletAirEnthalpy, heatPump.OutletAirHumRat)
    else:
        heatPump.OutletAirEnthalpy = LoadSideAirOutletEnth
        heatPump.OutletAirHumRat = LoadSideOutletHumRat
        heatPump.OutletAirDBTemp = LoadSideOutletDBTemp
    var PLF: Float64 = 1.0
    if heatPump.PLFCurveIndex > 0:
        PLF = Curve.CurveValue(state, heatPump.PLFCurveIndex, PartLoadRatio)
    if fanOp == HVAC.FanOp.Cycling:
        state.dataHVACGlobal.OnOffFanPartLoadFraction = PLF
    heatPump.RunFrac = PartLoadRatio / PLF
    QLoadTotal *= PartLoadRatio
    Power *= heatPump.RunFrac
    QSource *= PartLoadRatio
    state.dataHVACGlobal.DXElecHeatingPower = Power
    heatPump.Power = Power
    heatPump.QLoadTotal = QLoadTotal
    heatPump.QSensible = QLoadTotal
    heatPump.QSource = QSource
    heatPump.PartLoadRatio = PartLoadRatio
    heatPump.OutletAirMassFlowRate = heatPump.InletAirMassFlowRate
    heatPump.OutletWaterTemp = SourceSideOutletTemp
    heatPump.OutletWaterMassFlowRate = heatPump.InletWaterMassFlowRate
    heatPump.OutletWaterEnthalpy = heatPump.InletWaterEnthalpy - QSource / heatPump.InletWaterMassFlowRate

def UpdateWatertoAirHP(inout state: EnergyPlusData, HPNum: Int):
    var TimeStepSysSec = state.dataHVACGlobal.TimeStepSysSec
    var heatPump = state.dataWaterToAirHeatPump.WatertoAirHP[HPNum]
    if not heatPump.SimFlag:
        heatPump.Power = 0.0
        heatPump.Energy = 0.0
        heatPump.QLoadTotal = 0.0
        heatPump.QSensible = 0.0
        heatPump.QLatent = 0.0
        heatPump.QSource = 0.0
        heatPump.RunFrac = 0.0
        heatPump.PartLoadRatio = 0.0
        heatPump.OutletAirDBTemp = heatPump.InletAirDBTemp
        heatPump.OutletAirHumRat = heatPump.InletAirHumRat
        heatPump.OutletWaterTemp = heatPump.InletWaterTemp
        heatPump.OutletAirMassFlowRate = heatPump.InletAirMassFlowRate
        heatPump.OutletWaterMassFlowRate = heatPump.InletWaterMassFlowRate
        heatPump.OutletAirEnthalpy = heatPump.InletAirEnthalpy
        heatPump.OutletWaterEnthalpy = heatPump.InletWaterEnthalpy
    state.dataLoopNodes.Node[heatPump.AirOutletNodeNum].MassFlowRate = state.dataLoopNodes.Node[heatPump.AirInletNodeNum].MassFlowRate
    state.dataLoopNodes.Node[heatPump.AirOutletNodeNum].Temp = heatPump.OutletAirDBTemp
    state.dataLoopNodes.Node[heatPump.AirOutletNodeNum].HumRat = heatPump.OutletAirHumRat
    state.dataLoopNodes.Node[heatPump.AirOutletNodeNum].Enthalpy = heatPump.OutletAirEnthalpy
    PlantUtilities.SafeCopyPlantNode(state, heatPump.WaterInletNodeNum, heatPump.WaterOutletNodeNum)
    state.dataLoopNodes.Node[heatPump.WaterOutletNodeNum].Temp = heatPump.OutletWaterTemp
    state.dataLoopNodes.Node[heatPump.WaterOutletNodeNum].Enthalpy = heatPump.OutletWaterEnthalpy
    state.dataLoopNodes.Node[heatPump.AirOutletNodeNum].Quality = state.dataLoopNodes.Node[heatPump.AirInletNodeNum].Quality
    state.dataLoopNodes.Node[heatPump.AirOutletNodeNum].Press = state.dataLoopNodes.Node[heatPump.AirInletNodeNum].Press
    state.dataLoopNodes.Node[heatPump.AirOutletNodeNum].MassFlowRateMin = state.dataLoopNodes.Node[heatPump.AirInletNodeNum].MassFlowRateMin
    state.dataLoopNodes.Node[heatPump.AirOutletNodeNum].MassFlowRateMax = state.dataLoopNodes.Node[heatPump.AirInletNodeNum].MassFlowRateMax
    state.dataLoopNodes.Node[heatPump.AirOutletNodeNum].MassFlowRateMinAvail = state.dataLoopNodes.Node[heatPump.AirInletNodeNum].MassFlowRateMinAvail
    state.dataLoopNodes.Node[heatPump.AirOutletNodeNum].MassFlowRateMaxAvail = state.dataLoopNodes.Node[heatPump.AirInletNodeNum].MassFlowRateMaxAvail
    heatPump.InletAirMassFlowRate = state.dataLoopNodes.Node[heatPump.AirInletNodeNum].MassFlowRate
    heatPump.OutletAirMassFlowRate = heatPump.InletAirMassFlowRate
    heatPump.Energy = heatPump.Power * TimeStepSysSec
    heatPump.EnergyLoadTotal = heatPump.QLoadTotal * TimeStepSysSec
    heatPump.EnergySensible = heatPump.QSensible * TimeStepSysSec
    heatPump.EnergyLatent = heatPump.QLatent * TimeStepSysSec
    heatPump.EnergySource = heatPump.QSource * TimeStepSysSec
    if state.dataContaminantBalance.Contaminant.CO2Simulation:
        state.dataLoopNodes.Node[heatPump.AirOutletNodeNum].CO2 = state.dataLoopNodes.Node[heatPump.AirInletNodeNum].CO2
    if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
        state.dataLoopNodes.Node[heatPump.AirOutletNodeNum].GenContam = state.dataLoopNodes.Node[heatPump.AirInletNodeNum].GenContam

def CalcEffectiveSHR(inout state: EnergyPlusData, HPNum: Int, SHRss: Float64, fanOp: HVAC.FanOp, RTF: Float64, QLatRated: Float64, QLatActual: Float64, EnteringDB: Float64, EnteringWB: Float64) -> Float64:
    var heatPump = state.dataWaterToAirHeatPump.WatertoAirHP[HPNum]
    var SHReff: Float64
    var Twet: Float64
    var Gamma: Float64
    var Twet_max: Float64
    var Ton: Float64
    var Toff: Float64
    var Toffa: Float64
    var aa: Float64
    var To1: Float64
    var To2: Float64
    var Error: Float64
    var LHRmult: Float64
    if (RTF >= 1.0) or (QLatRated == 0.0) or (QLatActual == 0.0) or (heatPump.Twet_Rated <= 0.0) or (heatPump.Gamma_Rated <= 0.0) or (heatPump.MaxONOFFCyclesperHour <= 0.0) or (heatPump.LatentCapacityTimeConstant <= 0.0) or (RTF <= 0.0):
        SHReff = SHRss
        return SHReff
    Twet_max = 9999.0
    Twet = min(heatPump.Twet_Rated * QLatRated / (QLatActual + 1e-10), Twet_max)
    Gamma = heatPump.Gamma_Rated * QLatRated * (EnteringDB - EnteringWB) / ((26.7 - 19.4) * QLatActual + 1e-10)
    Ton = 3600.0 / (4.0 * heatPump.MaxONOFFCyclesperHour * (1.0 - RTF))
    if (fanOp == HVAC.FanOp.Cycling) and (heatPump.FanDelayTime != 0.0):
        Toff = heatPump.FanDelayTime
    else:
        Toff = 3600.0 / (4.0 * heatPump.MaxONOFFCyclesperHour * RTF)
    if Gamma > 0.0:
        Toffa = min(Toff, 2.0 * Twet / Gamma)
    else:
        Toffa = Toff
    aa = (Gamma * Toffa) - (0.25 / Twet) * pow(Gamma, 2.0) * pow(Toffa, 2.0)
    To1 = aa + heatPump.LatentCapacityTimeConstant
    Error = 1.0
    while Error > 0.001:
        To2 = aa - heatPump.LatentCapacityTimeConstant * expm1(min(700.0, -To1 / heatPump.LatentCapacityTimeConstant))
        Error = abs((To2 - To1) / To1)
        To1 = To2
    aa = exp(max(-700.0, -Ton / heatPump.LatentCapacityTimeConstant))
    LHRmult = max(((Ton - To2) / (Ton + heatPump.LatentCapacityTimeConstant * (aa - 1.0))), 0.0)
    SHReff = 1.0 - (1.0 - SHRss) * LHRmult
    if SHReff < SHRss:
        SHReff = SHRss
    if SHReff > 1.0:
        SHReff = 1.0
    return SHReff

def DegradF(inout state: EnergyPlusData, glycol: Fluid.GlycolProps, inout Temp: Float64) -> Float64:
    var DegradF: Float64
    alias CalledFrom: StringLiteral = "HVACWaterToAir:DegradF"
    var VisWater: Float64
    var DensityWater: Float64
    var CpWater: Float64
    var CondWater: Float64
    var VisCoolant: Float64
    var DensityCoolant: Float64
    var CpCoolant: Float64
    var CondCoolant: Float64
    var water = Fluid.GetWater(state)
    VisWater = water.getViscosity(state, Temp, CalledFrom)
    DensityWater = water.getDensity(state, Temp, CalledFrom)
    CpWater = water.getSpecificHeat(state, Temp, CalledFrom)
    CondWater = water.getConductivity(state, Temp, CalledFrom)
    VisCoolant = glycol.getViscosity(state, Temp, CalledFrom)
    DensityCoolant = glycol.getDensity(state, Temp, CalledFrom)
    CpCoolant = glycol.getSpecificHeat(state, Temp, CalledFrom)
    CondCoolant = glycol.getConductivity(state, Temp, CalledFrom)
    DegradF = pow(VisCoolant / VisWater, -0.47) * pow(DensityCoolant / DensityWater, 0.8) * pow(CpCoolant / CpWater, 0.33) * pow(CondCoolant / CondWater, 0.67)
    return DegradF

def GetCoilIndex(inout state: EnergyPlusData, CoilType: String, CoilName: String, inout ErrorsFound: Bool) -> Int:
    if state.dataWaterToAirHeatPump.GetCoilsInputFlag:
        GetWatertoAirHPInput(state)
        state.dataWaterToAirHeatPump.GetCoilsInputFlag = False
    var IndexNum = Util.FindItemInList(CoilName, state.dataWaterToAirHeatPump.WatertoAirHP)
    if IndexNum == 0:
        ShowSevereError(state, EnergyPlus.format("Could not find CoilType=\"{}\" with Name=\"{}\"", CoilType, CoilName))
        ErrorsFound = True
    return IndexNum

def GetCoilCapacity(inout state: EnergyPlusData, coilType: StringLiteral, CoilName: String, inout ErrorsFound: Bool) -> Float64:
    var CoilCapacity: Float64
    var WhichCoil: Int
    if state.dataWaterToAirHeatPump.GetCoilsInputFlag:
        GetWatertoAirHPInput(state)
        state.dataWaterToAirHeatPump.GetCoilsInputFlag = False
    if Util.SameString(CoilType, "COIL:HEATING:WATERTOAIRHEATPUMP:PARAMETERESTIMATION") or Util.SameString(CoilType, "COIL:COOLING:WATERTOAIRHEATPUMP:PARAMETERESTIMATION"):
        WhichCoil = Util.FindItemInList(CoilName, state.dataWaterToAirHeatPump.WatertoAirHP)
        if WhichCoil != 0:
            if Util.SameString(CoilType, "COIL:HEATING:WATERTOAIRHEATPUMP:PARAMETERESTIMATION"):
                CoilCapacity = state.dataWaterToAirHeatPump.WatertoAirHP[WhichCoil].HeatingCapacity
            else:
                CoilCapacity = state.dataWaterToAirHeatPump.WatertoAirHP[WhichCoil].CoolingCapacity
    else:
        WhichCoil = 0
    if WhichCoil == 0:
        ShowSevereError(state, EnergyPlus.format("Could not find CoilType=\"{}\" with Name=\"{}\"", CoilType, CoilName))
        ErrorsFound = True
        CoilCapacity = -1000.0
    return CoilCapacity

def GetCoilInletNode(inout state: EnergyPlusData, CoilType: String, CoilName: String, inout ErrorsFound: Bool) -> Int:
    var NodeNumber: Int
    if state.dataWaterToAirHeatPump.GetCoilsInputFlag:
        GetWatertoAirHPInput(state)
        state.dataWaterToAirHeatPump.GetCoilsInputFlag = False
    var WhichCoil = Util.FindItemInList(CoilName, state.dataWaterToAirHeatPump.WatertoAirHP)
    if WhichCoil != 0:
        NodeNumber = state.dataWaterToAirHeatPump.WatertoAirHP[WhichCoil].AirInletNodeNum
    if WhichCoil == 0:
        ShowSevereError(state, EnergyPlus.format("Could not find CoilType=\"{}\" with Name=\"{}\"", CoilType, CoilName))
        ErrorsFound = True
        NodeNumber = 0
    return NodeNumber

def GetCoilOutletNode(inout state: EnergyPlusData, CoilType: String, CoilName: String, inout ErrorsFound: Bool) -> Int:
    var NodeNumber: Int
    if state.dataWaterToAirHeatPump.GetCoilsInputFlag:
        GetWatertoAirHPInput(state)
        state.dataWaterToAirHeatPump.GetCoilsInputFlag = False
    var WhichCoil = Util.FindItemInList(CoilName, state.dataWaterToAirHeatPump.WatertoAirHP)
    if WhichCoil != 0:
        NodeNumber = state.dataWaterToAirHeatPump.WatertoAirHP[WhichCoil].AirOutletNodeNum
    if WhichCoil == 0:
        ShowSevereError(state, EnergyPlus.format("Could not find CoilType=\"{}\" with Name=\"{}\"", CoilType, CoilName))
        ErrorsFound = True
        NodeNumber = 0
    return NodeNumber