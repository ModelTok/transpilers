from math import max
from dataclasses import dataclass

alias CondensateOutletInvalid = -1
alias CondensateOutletDiscarded = 0
alias CondensateOutletToTank = 1
alias CondensateOutletNum = 2

@dataclass
struct Curve:
    pass

@dataclass
struct Schedule:
    pass

@dataclass
struct ZoneDehumidifierParams:
    var Name: String
    var UnitType: String
    var availSched: Optional[Schedule]
    var RatedWaterRemoval: Float64
    var RatedEnergyFactor: Float64
    var RatedAirVolFlow: Float64
    var RatedAirMassFlow: Float64
    var MinInletAirTemp: Float64
    var MaxInletAirTemp: Float64
    var InletAirMassFlow: Float64
    var OutletAirEnthalpy: Float64
    var OutletAirHumRat: Float64
    var OffCycleParasiticLoad: Float64
    var AirInletNodeNum: Int32
    var AirOutletNodeNum: Int32
    var WaterRemovalCurve: Optional[Curve]
    var WaterRemovalCurveErrorCount: Int32
    var WaterRemovalCurveErrorIndex: Int32
    var EnergyFactorCurve: Optional[Curve]
    var EnergyFactorCurveErrorCount: Int32
    var EnergyFactorCurveErrorIndex: Int32
    var PartLoadCurve: Optional[Curve]
    var LowPLFErrorCount: Int32
    var LowPLFErrorIndex: Int32
    var HighPLFErrorCount: Int32
    var HighPLFErrorIndex: Int32
    var HighRTFErrorCount: Int32
    var HighRTFErrorIndex: Int32
    var PLFPLRErrorCount: Int32
    var PLFPLRErrorIndex: Int32
    var CondensateCollectMode: Int32
    var CondensateCollectName: String
    var CondensateTankID: Int32
    var CondensateTankSupplyARRID: Int32
    var SensHeatingRate: Float64
    var SensHeatingEnergy: Float64
    var WaterRemovalRate: Float64
    var WaterRemoved: Float64
    var ElecPower: Float64
    var ElecConsumption: Float64
    var DehumidPLR: Float64
    var DehumidRTF: Float64
    var DehumidCondVolFlowRate: Float64
    var DehumidCondVol: Float64
    var OutletAirTemp: Float64
    var OffCycleParasiticElecPower: Float64
    var OffCycleParasiticElecCons: Float64
    var MyEnvrnFlag: Bool
    var CheckEquipName: Bool
    var ZoneEquipmentListChecked: Bool
    
    fn __init__(inout self):
        self.Name = ""
        self.UnitType = ""
        self.availSched = None
        self.RatedWaterRemoval = 0.0
        self.RatedEnergyFactor = 0.0
        self.RatedAirVolFlow = 0.0
        self.RatedAirMassFlow = 0.0
        self.MinInletAirTemp = 0.0
        self.MaxInletAirTemp = 0.0
        self.InletAirMassFlow = 0.0
        self.OutletAirEnthalpy = 0.0
        self.OutletAirHumRat = 0.0
        self.OffCycleParasiticLoad = 0.0
        self.AirInletNodeNum = 0
        self.AirOutletNodeNum = 0
        self.WaterRemovalCurve = None
        self.WaterRemovalCurveErrorCount = 0
        self.WaterRemovalCurveErrorIndex = 0
        self.EnergyFactorCurve = None
        self.EnergyFactorCurveErrorCount = 0
        self.EnergyFactorCurveErrorIndex = 0
        self.PartLoadCurve = None
        self.LowPLFErrorCount = 0
        self.LowPLFErrorIndex = 0
        self.HighPLFErrorCount = 0
        self.HighPLFErrorIndex = 0
        self.HighRTFErrorCount = 0
        self.HighRTFErrorIndex = 0
        self.PLFPLRErrorCount = 0
        self.PLFPLRErrorIndex = 0
        self.CondensateCollectMode = CondensateOutletDiscarded
        self.CondensateCollectName = ""
        self.CondensateTankID = 0
        self.CondensateTankSupplyARRID = 0
        self.SensHeatingRate = 0.0
        self.SensHeatingEnergy = 0.0
        self.WaterRemovalRate = 0.0
        self.WaterRemoved = 0.0
        self.ElecPower = 0.0
        self.ElecConsumption = 0.0
        self.DehumidPLR = 0.0
        self.DehumidRTF = 0.0
        self.DehumidCondVolFlowRate = 0.0
        self.DehumidCondVol = 0.0
        self.OutletAirTemp = 0.0
        self.OffCycleParasiticElecPower = 0.0
        self.OffCycleParasiticElecCons = 0.0
        self.MyEnvrnFlag = True
        self.CheckEquipName = True
        self.ZoneEquipmentListChecked = False

@dataclass
struct ZoneDehumidifierData:
    var GetInputFlag: Bool
    var ZoneDehumid: List[ZoneDehumidifierParams]
    
    fn __init__(inout self):
        self.GetInputFlag = True
        self.ZoneDehumid = List[ZoneDehumidifierParams]()

fn SimZoneDehumidifier(inout state: EnergyPlusData, CompName: StringRef, ZoneNum: Int32, FirstHVACIteration: Bool) -> (Float64, Float64, Int32):
    var QSensOut: Float64 = 0.0
    var QLatOut: Float64 = 0.0
    var CompIndex: Int32 = 0
    
    if state.dataZoneDehumidifier.GetInputFlag:
        GetZoneDehumidifierInput(state)
        state.dataZoneDehumidifier.GetInputFlag = False
    
    if CompIndex == 0:
        var ZoneDehumidNum = Util.FindItemInList(CompName, state.dataZoneDehumidifier.ZoneDehumid)
        if ZoneDehumidNum == 0:
            ShowFatalError(state, String("SimZoneDehumidifier: Unit not found= ") + CompName)
        CompIndex = ZoneDehumidNum
    else:
        var ZoneDehumidNum = CompIndex
        var NumDehumidifiers = len(state.dataZoneDehumidifier.ZoneDehumid)
        if ZoneDehumidNum > NumDehumidifiers or ZoneDehumidNum < 1:
            ShowFatalError(state, String("SimZoneDehumidifier:  Invalid CompIndex passed= ") + String(ZoneDehumidNum) + String(", Number of Units= ") + String(NumDehumidifiers) + String(", Entered Unit name= ") + CompName)
        if state.dataZoneDehumidifier.ZoneDehumid[ZoneDehumidNum - 1].CheckEquipName:
            if CompName != state.dataZoneDehumidifier.ZoneDehumid[ZoneDehumidNum - 1].Name:
                ShowFatalError(state, String("SimZoneDehumidifier: Invalid CompIndex passed=") + String(ZoneDehumidNum) + String(", Unit name= ") + CompName + String(", stored Unit Name for that index= ") + state.dataZoneDehumidifier.ZoneDehumid[ZoneDehumidNum - 1].Name)
            state.dataZoneDehumidifier.ZoneDehumid[ZoneDehumidNum - 1].CheckEquipName = False
    
    var QZnDehumidReq = state.dataZoneEnergyDemand.ZoneSysMoistureDemand[ZoneNum].RemainingOutputReqToDehumidSP
    
    InitZoneDehumidifier(state, CompIndex)
    
    var SensOut: Float64
    var LatOut: Float64
    SensOut, LatOut = CalcZoneDehumidifier(state, CompIndex, QZnDehumidReq)
    QSensOut = SensOut
    QLatOut = LatOut
    
    UpdateZoneDehumidifier(state, CompIndex)
    
    ReportZoneDehumidifier(state, CompIndex)
    
    return QSensOut, QLatOut, CompIndex

fn GetZoneDehumidifierInput(inout state: EnergyPlusData):
    var routineName = "GetZoneDehumidifierInput"
    var CurrentModuleObject = "ZoneHVAC:Dehumidifier:DX"
    var RatedInletAirTemp: Float64 = 26.7
    var RatedInletAirRH: Float64 = 60.0
    
    var ErrorsFound: Bool = False
    
    var inputProcessor = state.dataInputProcessing.inputProcessor
    var NumDehumidifiers = inputProcessor.getNumObjectsFound(state, CurrentModuleObject)
    
    state.dataZoneDehumidifier.ZoneDehumid = List[ZoneDehumidifierParams]()
    for _ in range(NumDehumidifiers):
        state.dataZoneDehumidifier.ZoneDehumid.append(ZoneDehumidifierParams())
    
    var objectSchemaProps = inputProcessor.getObjectSchemaProps(state, CurrentModuleObject)
    var dehumidObjects = inputProcessor.epJSON.get(CurrentModuleObject)
    
    var ZoneDehumidIndex: Int32 = 0
    
    if dehumidObjects is not None:
        for dehumidInstance_key in dehumidObjects.items():
            var dehumidName = Util.makeUPPER(dehumidInstance_key)
            var dehumidFields = dehumidObjects.get(dehumidInstance_key)
            
            var availabilityScheduleName = inputProcessor.getAlphaFieldValue(dehumidFields, objectSchemaProps, "availability_schedule_name")
            var airInletNodeName = inputProcessor.getAlphaFieldValue(dehumidFields, objectSchemaProps, "air_inlet_node_name")
            var airOutletNodeName = inputProcessor.getAlphaFieldValue(dehumidFields, objectSchemaProps, "air_outlet_node_name")
            var waterRemovalCurveName = inputProcessor.getAlphaFieldValue(dehumidFields, objectSchemaProps, "water_removal_curve_name")
            var energyFactorCurveName = inputProcessor.getAlphaFieldValue(dehumidFields, objectSchemaProps, "energy_factor_curve_name")
            var partLoadFractionCorrelationCurveName = inputProcessor.getAlphaFieldValue(dehumidFields, objectSchemaProps, "part_load_fraction_correlation_curve_name")
            var condensateCollectionWaterStorageTankName = inputProcessor.getAlphaFieldValue(dehumidFields, objectSchemaProps, "condensate_collection_water_storage_tank_name")
            
            inputProcessor.markObjectAsUsed(CurrentModuleObject, dehumidInstance_key)
            
            var eoh = ErrorObjectHeader(routineName, CurrentModuleObject, dehumidName)
            
            var dehumid = state.dataZoneDehumidifier.ZoneDehumid[ZoneDehumidIndex]
            dehumid.Name = dehumidName
            dehumid.UnitType = CurrentModuleObject
            
            if availabilityScheduleName == "":
                dehumid.availSched = Sched.GetScheduleAlwaysOn(state)
            else:
                dehumid.availSched = Sched.GetSchedule(state, availabilityScheduleName)
                if dehumid.availSched is None:
                    ShowSevereItemNotFound(state, eoh, "Availability Schedule Name", availabilityScheduleName)
                    ErrorsFound = True
            
            dehumid.AirInletNodeNum = Node.GetOnlySingleNode(state, airInletNodeName, ErrorsFound, Node.ConnectionObjectType.ZoneHVACDehumidifierDX, dehumidName, Node.FluidType.Air, Node.ConnectionType.Inlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
            
            dehumid.AirOutletNodeNum = Node.GetOnlySingleNode(state, airOutletNodeName, ErrorsFound, Node.ConnectionObjectType.ZoneHVACDehumidifierDX, dehumidName, Node.FluidType.Air, Node.ConnectionType.Outlet, Node.CompFluidStream.Primary, Node.ObjectIsNotParent)
            
            dehumid.RatedWaterRemoval = inputProcessor.getRealFieldValue(dehumidFields, objectSchemaProps, "rated_water_removal")
            if dehumid.RatedWaterRemoval <= 0.0:
                ShowSevereError(state, "Rated Water Removal must be greater than zero.")
                ShowContinueError(state, String("Value specified = ") + String(dehumid.RatedWaterRemoval))
                ShowContinueError(state, String("Occurs in ") + CurrentModuleObject + String(" = ") + dehumid.Name)
                ErrorsFound = True
            
            dehumid.RatedEnergyFactor = inputProcessor.getRealFieldValue(dehumidFields, objectSchemaProps, "rated_energy_factor")
            if dehumid.RatedEnergyFactor <= 0.0:
                ShowSevereError(state, "Rated Energy Factor must be greater than zero.")
                ShowContinueError(state, String("Value specified = ") + String(dehumid.RatedEnergyFactor))
                ShowContinueError(state, String("Occurs in ") + CurrentModuleObject + String(" = ") + dehumid.Name)
                ErrorsFound = True
            
            dehumid.RatedAirVolFlow = inputProcessor.getRealFieldValue(dehumidFields, objectSchemaProps, "rated_air_flow_rate")
            if dehumid.RatedAirVolFlow <= 0.0:
                ShowSevereError(state, "Rated Air Flow Rate must be greater than zero.")
                ShowContinueError(state, String("Value specified = ") + String(dehumid.RatedAirVolFlow))
                ShowContinueError(state, String("Occurs in ") + CurrentModuleObject + String(" = ") + dehumid.Name)
                ErrorsFound = True
            
            if waterRemovalCurveName == "":
                ShowSevereEmptyField(state, eoh, "Water Removal Curve Name")
                ErrorsFound = True
            else:
                dehumid.WaterRemovalCurve = Curve.GetCurve(state, waterRemovalCurveName)
                if dehumid.WaterRemovalCurve is None:
                    ShowSevereItemNotFound(state, eoh, "Water Removal Curve Name", waterRemovalCurveName)
                    ErrorsFound = True
                elif dehumid.WaterRemovalCurve.numDims != 2:
                    Curve.ShowSevereCurveDims(state, eoh, "Water Removal Curve Name", waterRemovalCurveName, "2", dehumid.WaterRemovalCurve.numDims)
                    ErrorsFound = True
                else:
                    var CurveVal = dehumid.WaterRemovalCurve.value(state, RatedInletAirTemp, RatedInletAirRH)
                    if CurveVal > 1.10 or CurveVal < 0.90:
                        ShowWarningError(state, "Water Removal Curve Name output is not equal to 1.0")
                        ShowContinueError(state, String("(+ or -10%) at rated conditions for ") + CurrentModuleObject + String(" = ") + dehumidName)
                        ShowContinueError(state, String("Curve output at rated conditions = ") + String(CurveVal))
            
            if energyFactorCurveName == "":
                ShowSevereEmptyField(state, eoh, "Energy Factor Curve Name")
                ErrorsFound = True
            else:
                dehumid.EnergyFactorCurve = Curve.GetCurve(state, energyFactorCurveName)
                if dehumid.EnergyFactorCurve is None:
                    ShowSevereItemNotFound(state, eoh, "Energy Factor Curve Name", energyFactorCurveName)
                    ErrorsFound = True
                elif dehumid.EnergyFactorCurve.numDims != 2:
                    Curve.ShowSevereCurveDims(state, eoh, "Energy Factor Curve Name", energyFactorCurveName, "2", dehumid.EnergyFactorCurve.numDims)
                    ErrorsFound = True
                else:
                    var CurveVal = dehumid.EnergyFactorCurve.value(state, RatedInletAirTemp, RatedInletAirRH)
                    if CurveVal > 1.10 or CurveVal < 0.90:
                        ShowWarningError(state, "Energy Factor Curve Name output is not equal to 1.0")
                        ShowContinueError(state, String("(+ or -10%) at rated conditions for ") + CurrentModuleObject + String(" = ") + dehumidName)
                        ShowContinueError(state, String("Curve output at rated conditions = ") + String(CurveVal))
            
            if partLoadFractionCorrelationCurveName == "":
                ShowSevereEmptyField(state, eoh, "Part Load Fraction Correlation Curve Name")
                ErrorsFound = True
            else:
                dehumid.PartLoadCurve = Curve.GetCurve(state, partLoadFractionCorrelationCurveName)
                if dehumid.PartLoadCurve is None:
                    ShowSevereItemNotFound(state, eoh, "Part Load Fraction Correlation Curve Name", partLoadFractionCorrelationCurveName)
                    ErrorsFound = True
                elif dehumid.PartLoadCurve.numDims != 1:
                    Curve.ShowSevereCurveDims(state, eoh, "Part Load Fraction Correlation Curve Name", partLoadFractionCorrelationCurveName, "1", dehumid.PartLoadCurve.numDims)
                    ErrorsFound = True
            
            dehumid.MinInletAirTemp = inputProcessor.getRealFieldValue(dehumidFields, objectSchemaProps, "minimum_dry_bulb_temperature_for_dehumidifier_operation")
            dehumid.MaxInletAirTemp = inputProcessor.getRealFieldValue(dehumidFields, objectSchemaProps, "maximum_dry_bulb_temperature_for_dehumidifier_operation")
            
            if dehumid.MinInletAirTemp >= dehumid.MaxInletAirTemp:
                ShowSevereError(state, "Maximum Dry-Bulb Temperature for Dehumidifier Operation must be greater than Minimum Dry-Bulb Temperature for Dehumidifier Operation")
                ShowContinueError(state, String("Maximum Dry-Bulb Temperature for Dehumidifier Operation specified = ") + String(dehumid.MaxInletAirTemp))
                ShowContinueError(state, String("Minimum Dry-Bulb Temperature for Dehumidifier Operation specified = ") + String(dehumid.MinInletAirTemp))
                ShowContinueError(state, String("Occurs in ") + CurrentModuleObject + String(" = ") + dehumid.Name)
                ErrorsFound = True
            
            dehumid.OffCycleParasiticLoad = inputProcessor.getRealFieldValue(dehumidFields, objectSchemaProps, "off_cycle_parasitic_electric_load")
            
            if dehumid.OffCycleParasiticLoad < 0.0:
                ShowSevereError(state, "Off-Cycle Parasitic Electric Load must be >= zero.")
                ShowContinueError(state, String("Value specified = ") + String(dehumid.OffCycleParasiticLoad))
                ShowContinueError(state, String("Occurs in ") + CurrentModuleObject + String(" = ") + dehumid.Name)
                ErrorsFound = True
            
            dehumid.CondensateCollectName = condensateCollectionWaterStorageTankName
            if condensateCollectionWaterStorageTankName == "":
                dehumid.CondensateCollectMode = CondensateOutletDiscarded
            else:
                dehumid.CondensateCollectMode = CondensateOutletToTank
                WaterManager.SetupTankSupplyComponent(state, dehumid.Name, CurrentModuleObject, condensateCollectionWaterStorageTankName, ErrorsFound, dehumid.CondensateTankID, dehumid.CondensateTankSupplyARRID)
            
            ZoneDehumidIndex += 1
    
    if ErrorsFound:
        ShowFatalError(state, routineName + String(":") + CurrentModuleObject + String(": Errors found in input."))
    
    for ZoneDehumidIndex in range(NumDehumidifiers):
        var dehumid = state.dataZoneDehumidifier.ZoneDehumid[ZoneDehumidIndex]
        
        SetupOutputVariable(state, "Zone Dehumidifier Sensible Heating Rate", Constant.Units.W, dehumid, "SensHeatingRate", OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, dehumid.Name)
        SetupOutputVariable(state, "Zone Dehumidifier Sensible Heating Energy", Constant.Units.J, dehumid, "SensHeatingEnergy", OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, dehumid.Name)
        SetupOutputVariable(state, "Zone Dehumidifier Removed Water Mass Flow Rate", Constant.Units.kg_s, dehumid, "WaterRemovalRate", OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, dehumid.Name)
        SetupOutputVariable(state, "Zone Dehumidifier Removed Water Mass", Constant.Units.kg, dehumid, "WaterRemoved", OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, dehumid.Name)
        SetupOutputVariable(state, "Zone Dehumidifier Electricity Rate", Constant.Units.W, dehumid, "ElecPower", OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, dehumid.Name)
        SetupOutputVariable(state, "Zone Dehumidifier Electricity Energy", Constant.Units.J, dehumid, "ElecConsumption", OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, dehumid.Name, Constant.eResource.Electricity, OutputProcessor.Group.HVAC, OutputProcessor.EndUseCat.Cooling)
        SetupOutputVariable(state, "Zone Dehumidifier Off Cycle Parasitic Electricity Rate", Constant.Units.W, dehumid, "OffCycleParasiticElecPower", OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, dehumid.Name)
        SetupOutputVariable(state, "Zone Dehumidifier Off Cycle Parasitic Electricity Energy", Constant.Units.J, dehumid, "OffCycleParasiticElecCons", OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, dehumid.Name)
        SetupOutputVariable(state, "Zone Dehumidifier Part Load Ratio", Constant.Units.None, dehumid, "DehumidPLR", OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, dehumid.Name)
        SetupOutputVariable(state, "Zone Dehumidifier Runtime Fraction", Constant.Units.None, dehumid, "DehumidRTF", OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, dehumid.Name)
        SetupOutputVariable(state, "Zone Dehumidifier Outlet Air Temperature", Constant.Units.C, dehumid, "OutletAirTemp", OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, dehumid.Name)
        
        if dehumid.CondensateCollectMode == CondensateOutletToTank:
            SetupOutputVariable(state, "Zone Dehumidifier Condensate Volume Flow Rate", Constant.Units.m3_s, dehumid, "DehumidCondVolFlowRate", OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, dehumid.Name)
            SetupOutputVariable(state, "Zone Dehumidifier Condensate Volume", Constant.Units.m3, dehumid, "DehumidCondVol", OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, dehumid.Name, Constant.eResource.OnSiteWater, OutputProcessor.Group.HVAC, OutputProcessor.EndUseCat.Condensate)

fn InitZoneDehumidifier(inout state: EnergyPlusData, ZoneDehumNum: Int32):
    var RoutineName = "InitZoneDehumidifier"
    
    var dehumid = state.dataZoneDehumidifier.ZoneDehumid[ZoneDehumNum - 1]
    
    if not dehumid.ZoneEquipmentListChecked and state.dataZoneEquip.ZoneEquipInputsFilled:
        dehumid.ZoneEquipmentListChecked = True
        if not DataZoneEquipment.CheckZoneEquipmentList(state, dehumid.UnitType, dehumid.Name):
            ShowSevereError(state, String("InitZoneDehumidifier: Zone Dehumidifier=\"") + dehumid.UnitType + String(",") + dehumid.Name + String("\" is not on any ZoneHVAC:EquipmentList.  It will not be simulated."))
    
    var AirInletNode = dehumid.AirInletNodeNum
    
    if state.dataGlobal.BeginEnvrnFlag and dehumid.MyEnvrnFlag:
        var RatedAirDBTemp: Float64 = 26.6667
        var RatedAirRH: Float64 = 0.6
        var RatedAirHumrat = Psychrometrics.PsyWFnTdbRhPb(state, RatedAirDBTemp, RatedAirRH, state.dataEnvrn.StdBaroPress, RoutineName)
        dehumid.RatedAirMassFlow = Psychrometrics.PsyRhoAirFnPbTdbW(state, state.dataEnvrn.StdBaroPress, RatedAirDBTemp, RatedAirHumrat, RoutineName) * dehumid.RatedAirVolFlow
        
        state.dataLoopNodes.Node[AirInletNode].MassFlowRateMax = dehumid.RatedAirMassFlow
        state.dataLoopNodes.Node[AirInletNode].MassFlowRateMaxAvail = dehumid.RatedAirMassFlow
        state.dataLoopNodes.Node[AirInletNode].MassFlowRateMinAvail = 0.0
        state.dataLoopNodes.Node[AirInletNode].MassFlowRateMin = 0.0
        
        dehumid.MyEnvrnFlag = False
    
    if not state.dataGlobal.BeginEnvrnFlag:
        dehumid.MyEnvrnFlag = True
    
    state.dataLoopNodes.Node[AirInletNode].MassFlowRate = dehumid.RatedAirMassFlow
    
    dehumid.SensHeatingRate = 0.0
    dehumid.SensHeatingEnergy = 0.0
    dehumid.WaterRemovalRate = 0.0
    dehumid.WaterRemoved = 0.0
    dehumid.ElecPower = 0.0
    dehumid.ElecConsumption = 0.0
    dehumid.DehumidPLR = 0.0
    dehumid.DehumidRTF = 0.0
    dehumid.OffCycleParasiticElecPower = 0.0
    dehumid.OffCycleParasiticElecCons = 0.0
    dehumid.DehumidCondVolFlowRate = 0.0
    dehumid.DehumidCondVol = 0.0
    dehumid.OutletAirTemp = state.dataLoopNodes.Node[AirInletNode].Temp

fn CalcZoneDehumidifier(inout state: EnergyPlusData, ZoneDehumNum: Int32, QZnDehumidReq: Float64) -> (Float64, Float64):
    var RoutineName = "CalcZoneDehumidifier"
    
    var dehumid = state.dataZoneDehumidifier.ZoneDehumid[ZoneDehumNum - 1]
    
    var SensibleOutput: Float64 = 0.0
    var LatentOutput: Float64 = 0.0
    var WaterRemovalRateFactor: Float64 = 0.0
    var AirMassFlowRate: Float64 = 0.0
    var PLR: Float64 = 0.0
    var PLF: Float64 = 0.0
    var EnergyFactorAdjFactor: Float64 = 0.0
    var RunTimeFraction: Float64 = 0.0
    var ElectricPowerAvg: Float64 = 0.0
    var ElectricPowerOnCycle: Float64 = 0.0
    
    var AirInletNodeNum = dehumid.AirInletNodeNum
    
    var InletAirTemp = state.dataLoopNodes.Node[AirInletNodeNum].Temp
    var InletAirHumRat = state.dataLoopNodes.Node[AirInletNodeNum].HumRat
    var InletAirRH = 100.0 * Psychrometrics.PsyRhFnTdbWPb(state, InletAirTemp, InletAirHumRat, state.dataEnvrn.OutBaroPress, RoutineName)
    
    var OutletAirTemp: Float64
    var OutletAirHumRat: Float64
    
    if QZnDehumidReq < 0.0 and dehumid.availSched.getCurrentVal() > 0.0 and InletAirTemp >= dehumid.MinInletAirTemp and InletAirTemp <= dehumid.MaxInletAirTemp:
        
        WaterRemovalRateFactor = dehumid.WaterRemovalCurve.value(state, InletAirTemp, InletAirRH)
        
        if WaterRemovalRateFactor <= 0.0:
            if dehumid.WaterRemovalCurveErrorCount < 1:
                dehumid.WaterRemovalCurveErrorCount += 1
                ShowWarningError(state, String(dehumid.UnitType) + String(" \"") + dehumid.Name + String("\":"))
                ShowContinueError(state, String(" Water Removal Rate Curve output is <= 0.0 (") + String(WaterRemovalRateFactor) + String(")."))
                ShowContinueError(state, String(" Negative value occurs using an inlet air dry-bulb temperature of ") + String(InletAirTemp) + String(" and an inlet air relative humidity of ") + String(InletAirRH) + String("."))
                ShowContinueErrorTimeStamp(state, " Dehumidifier turned off for this time step but simulation continues.")
            else:
                ShowRecurringWarningErrorAtEnd(state, String(dehumid.UnitType) + String(" \"") + dehumid.Name + String("\": Water Removal Rate Curve output is <= 0.0 warning continues..."), dehumid.WaterRemovalCurveErrorIndex, WaterRemovalRateFactor, WaterRemovalRateFactor)
            WaterRemovalRateFactor = 0.0
        
        var WaterRemovalVolRate = WaterRemovalRateFactor * dehumid.RatedWaterRemoval
        
        var WaterRemovalMassRate = WaterRemovalVolRate / (Constant.rSecsInDay * 1000.0) * Psychrometrics.RhoH2O(max((InletAirTemp - 11.0), 1.0))
        
        if WaterRemovalMassRate > 0.0:
            PLR = max(0.0, min(1.0, -QZnDehumidReq / WaterRemovalMassRate))
        else:
            PLR = 0.0
            RunTimeFraction = 0.0
        
        EnergyFactorAdjFactor = dehumid.EnergyFactorCurve.value(state, InletAirTemp, InletAirRH)
        
        if EnergyFactorAdjFactor <= 0.0:
            if dehumid.EnergyFactorCurveErrorCount < 1:
                dehumid.EnergyFactorCurveErrorCount += 1
                ShowWarningError(state, String(dehumid.UnitType) + String(" \"") + dehumid.Name + String("\":"))
                ShowContinueError(state, String(" Energy Factor Curve output is <= 0.0 (") + String(EnergyFactorAdjFactor) + String(")."))
                ShowContinueError(state, String(" Negative value occurs using an inlet air dry-bulb temperature of ") + String(InletAirTemp) + String(" and an inlet air relative humidity of ") + String(InletAirRH) + String("."))
                ShowContinueErrorTimeStamp(state, " Dehumidifier turned off for this time step but simulation continues.")
            else:
                ShowRecurringWarningErrorAtEnd(state, String(dehumid.UnitType) + String(" \"") + dehumid.Name + String("\": Energy Factor Curve output is <= 0.0 warning continues..."), dehumid.EnergyFactorCurveErrorIndex, EnergyFactorAdjFactor, EnergyFactorAdjFactor)
            ElectricPowerAvg = 0.0
            PLR = 0.0
            RunTimeFraction = 0.0
        else:
            var EnergyFactor = EnergyFactorAdjFactor * dehumid.RatedEnergyFactor
            
            if dehumid.PartLoadCurve is not None:
                PLF = dehumid.PartLoadCurve.value(state, PLR)
            else:
                PLF = 1.0
            
            if PLF < 0.7:
                if dehumid.LowPLFErrorCount < 1:
                    dehumid.LowPLFErrorCount += 1
                    ShowWarningError(state, String(dehumid.UnitType) + String(" \"") + dehumid.Name + String("\":"))
                    ShowContinueError(state, String(" The Part Load Fraction Correlation Curve output is (") + String(PLF) + String(") at a part-load ratio =") + String(PLR))
                    ShowContinueErrorTimeStamp(state, " PLF curve values must be >= 0.7.  PLF has been reset to 0.7 and simulation is continuing.")
                else:
                    ShowRecurringWarningErrorAtEnd(state, String(dehumid.UnitType) + String(" \"") + dehumid.Name + String("\": Part Load Fraction Correlation Curve output < 0.7 warning continues..."), dehumid.LowPLFErrorIndex, PLF, PLF)
                PLF = 0.7
            
            if PLF > 1.0:
                if dehumid.HighPLFErrorCount < 1:
                    dehumid.HighPLFErrorCount += 1
                    ShowWarningError(state, String(dehumid.UnitType) + String(" \"") + dehumid.Name + String("\":"))
                    ShowContinueError(state, String(" The Part Load Fraction Correlation Curve output is (") + String(PLF) + String(") at a part-load ratio =") + String(PLR))
                    ShowContinueErrorTimeStamp(state, " PLF curve values must be < 1.0.  PLF has been reset to 1.0 and simulation is continuing.")
                else:
                    ShowRecurringWarningErrorAtEnd(state, String(dehumid.UnitType) + String(" \"") + dehumid.Name + String("\": Part Load Fraction Correlation Curve output > 1.0 warning continues..."), dehumid.HighPLFErrorIndex, PLF, PLF)
                PLF = 1.0
            
            if PLF > 0.0 and PLF >= PLR:
                RunTimeFraction = PLR / PLF
            else:
                if dehumid.PLFPLRErrorCount < 1:
                    dehumid.PLFPLRErrorCount += 1
                    ShowWarningError(state, String(dehumid.UnitType) + String(" \"") + dehumid.Name + String("\":"))
                    ShowContinueError(state, String("The part load fraction was less than the part load ratio calculated for this time step [PLR=") + String(PLR) + String(", PLF=") + String(PLF) + String("]."))
                    ShowContinueError(state, "Runtime fraction reset to 1 and the simulation will continue.")
                    ShowContinueErrorTimeStamp(state, "")
                else:
                    ShowRecurringWarningErrorAtEnd(state, String(dehumid.UnitType) + String(" \"") + dehumid.Name + String("\": Part load fraction less than part load ratio warning continues..."), dehumid.PLFPLRErrorIndex)
                RunTimeFraction = 1.0
            
            if RunTimeFraction > 1.0 and abs(RunTimeFraction - 1.0) > 0.001:
                if dehumid.HighRTFErrorCount < 1:
                    dehumid.HighRTFErrorCount += 1
                    ShowWarningError(state, String(dehumid.UnitType) + String(" \"") + dehumid.Name + String("\":"))
                    ShowContinueError(state, String("The runtime fraction for this zone dehumidifier exceeded 1.0 [") + String(RunTimeFraction) + String("]."))
                    ShowContinueError(state, "Runtime fraction reset to 1 and the simulation will continue.")
                    ShowContinueErrorTimeStamp(state, "")
                else:
                    ShowRecurringWarningErrorAtEnd(state, String(dehumid.UnitType) + String(" \"") + dehumid.Name + String("\": Runtime fraction for zone dehumidifier exceeded 1.0 warning continues..."), dehumid.HighRTFErrorIndex, RunTimeFraction, RunTimeFraction)
                RunTimeFraction = 1.0
            
            ElectricPowerOnCycle = WaterRemovalVolRate / (EnergyFactor * 24.0) * 1000.0
            ElectricPowerAvg = ElectricPowerOnCycle * RunTimeFraction + (1.0 - RunTimeFraction) * dehumid.OffCycleParasiticLoad
        
        LatentOutput = WaterRemovalMassRate * PLR
        var hfg = Psychrometrics.PsyHfgAirFnWTdb(InletAirHumRat, InletAirTemp)
        SensibleOutput = (LatentOutput * hfg) + ElectricPowerAvg
        
        state.dataLoopNodes.Node[AirInletNodeNum].MassFlowRate = dehumid.RatedAirMassFlow * PLR
        AirMassFlowRate = state.dataLoopNodes.Node[AirInletNodeNum].MassFlowRate
        var Cp = Psychrometrics.PsyCpAirFnW(InletAirHumRat)
        if AirMassFlowRate > 0.0 and Cp > 0.0:
            OutletAirTemp = InletAirTemp + (ElectricPowerOnCycle + (WaterRemovalMassRate * hfg)) / (dehumid.RatedAirMassFlow * Cp)
            OutletAirHumRat = InletAirHumRat - LatentOutput / AirMassFlowRate
        else:
            OutletAirTemp = InletAirTemp
            OutletAirHumRat = InletAirHumRat
    
    else:
        OutletAirTemp = InletAirTemp
        OutletAirHumRat = InletAirHumRat
        PLR = 0.0
        RunTimeFraction = 0.0
        state.dataLoopNodes.Node[AirInletNodeNum].MassFlowRate = 0.0
        if dehumid.availSched.getCurrentVal() > 0.0:
            ElectricPowerAvg = dehumid.OffCycleParasiticLoad
        else:
            ElectricPowerAvg = 0.0
    
    dehumid.OutletAirTemp = OutletAirTemp
    dehumid.OutletAirHumRat = OutletAirHumRat
    
    dehumid.OutletAirEnthalpy = Psychrometrics.PsyHFnTdbW(InletAirTemp, OutletAirHumRat)
    
    dehumid.SensHeatingRate = SensibleOutput
    dehumid.WaterRemovalRate = LatentOutput
    LatentOutput = -LatentOutput
    
    dehumid.OffCycleParasiticElecPower = (1.0 - RunTimeFraction) * dehumid.OffCycleParasiticLoad
    dehumid.ElecPower = ElectricPowerAvg
    dehumid.DehumidPLR = PLR
    dehumid.DehumidRTF = RunTimeFraction
    
    return SensibleOutput, LatentOutput

fn UpdateZoneDehumidifier(inout state: EnergyPlusData, ZoneDehumNum: Int32):
    var dehumid = state.dataZoneDehumidifier.ZoneDehumid[ZoneDehumNum - 1]
    var airInletNode = state.dataLoopNodes.Node[dehumid.AirInletNodeNum]
    var airOutletNode = state.dataLoopNodes.Node[dehumid.AirOutletNodeNum]
    
    airOutletNode.Enthalpy = dehumid.OutletAirEnthalpy
    airOutletNode.HumRat = dehumid.OutletAirHumRat
    airOutletNode.Temp = airInletNode.Temp
    
    airOutletNode.Quality = airInletNode.Quality
    airOutletNode.Press = airInletNode.Press
    airOutletNode.MassFlowRate = airInletNode.MassFlowRate
    airOutletNode.MassFlowRateMin = airInletNode.MassFlowRateMin
    airOutletNode.MassFlowRateMax = airInletNode.MassFlowRateMax
    airOutletNode.MassFlowRateMinAvail = airInletNode.MassFlowRateMinAvail
    airOutletNode.MassFlowRateMaxAvail = airInletNode.MassFlowRateMaxAvail
    
    if state.dataContaminantBalance.Contaminant.CO2Simulation:
        airOutletNode.CO2 = airInletNode.CO2
    if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
        airOutletNode.GenContam = airInletNode.GenContam

fn ReportZoneDehumidifier(inout state: EnergyPlusData, DehumidNum: Int32):
    var TimeStepSysSec = state.dataHVACGlobal.TimeStepSysSec
    
    var dehumid = state.dataZoneDehumidifier.ZoneDehumid[DehumidNum - 1]
    
    dehumid.SensHeatingEnergy = dehumid.SensHeatingRate * TimeStepSysSec
    dehumid.WaterRemoved = dehumid.WaterRemovalRate * TimeStepSysSec
    dehumid.ElecConsumption = dehumid.ElecPower * TimeStepSysSec
    dehumid.OffCycleParasiticElecCons = dehumid.OffCycleParasiticElecPower * TimeStepSysSec
    
    if dehumid.CondensateCollectMode == CondensateOutletToTank:
        var AirInletNodeNum = dehumid.AirInletNodeNum
        var InletAirTemp = state.dataLoopNodes.Node[AirInletNodeNum].Temp
        var OutletAirTemp = max((InletAirTemp - 11.0), 1.0)
        var RhoWater = Psychrometrics.RhoH2O(OutletAirTemp)
        
        if RhoWater > 0.0:
            dehumid.DehumidCondVolFlowRate = dehumid.WaterRemovalRate / RhoWater
        
        dehumid.DehumidCondVol = dehumid.DehumidCondVolFlowRate * TimeStepSysSec
        
        state.dataWaterData.WaterStorage[dehumid.CondensateTankID].VdotAvailSupply[dehumid.CondensateTankSupplyARRID] = dehumid.DehumidCondVolFlowRate
        state.dataWaterData.WaterStorage[dehumid.CondensateTankID].TwaterSupply[dehumid.CondensateTankSupplyARRID] = OutletAirTemp

fn GetZoneDehumidifierNodeNumber(inout state: EnergyPlusData, NodeNumber: Int32) -> Bool:
    if state.dataZoneDehumidifier.GetInputFlag:
        GetZoneDehumidifierInput(state)
        state.dataZoneDehumidifier.GetInputFlag = False
    
    var FindZoneDehumidifierNodeNumber = False
    for ZoneDehumidIndex in range(len(state.dataZoneDehumidifier.ZoneDehumid)):
        if NodeNumber == state.dataZoneDehumidifier.ZoneDehumid[ZoneDehumidIndex].AirInletNodeNum:
            FindZoneDehumidifierNodeNumber = True
            break
        if NodeNumber == state.dataZoneDehumidifier.ZoneDehumid[ZoneDehumidIndex].AirOutletNodeNum:
            FindZoneDehumidifierNodeNumber = True
            break
    
    return FindZoneDehumidifierNodeNumber

fn getZoneDehumidifierIndex(inout state: EnergyPlusData, CompName: StringRef) -> Int32:
    if state.dataZoneDehumidifier.GetInputFlag:
        GetZoneDehumidifierInput(state)
        state.dataZoneDehumidifier.GetInputFlag = False
    
    for ZoneDehumidNum in range(len(state.dataZoneDehumidifier.ZoneDehumid)):
        if Util.SameString(state.dataZoneDehumidifier.ZoneDehumid[ZoneDehumidNum].Name, CompName):
            return ZoneDehumidNum + 1
    
    return 0

@dataclass
struct ErrorObjectHeader:
    var routine: String
    var object_type: String
    var object_name: String
    
    fn __init__(inout self, routine: StringRef, object_type: StringRef, object_name: StringRef):
        self.routine = String(routine)
        self.object_type = String(object_type)
        self.object_name = String(object_name)
