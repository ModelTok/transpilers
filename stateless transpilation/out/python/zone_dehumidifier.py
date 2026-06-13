# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object with .dataZoneDehumidifier, .dataZoneEnergyDemand, .dataLoopNodes, etc.
# - Curve: Curve struct with .value(state, arg1, arg2), .numDims, .name
# - Sched: Schedule with .getCurrentVal()
# - ShowFatalError, ShowSevereError, ShowWarningError, ShowContinueError, ShowContinueErrorTimeStamp, ShowRecurringWarningErrorAtEnd, ShowSevereItemNotFound, ShowSevereEmptyField
# - Psychrometrics: PsyRhoAirFnPbTdbW, PsyWFnTdbRhPb, PsyRhFnTdbWPb, PsyHfgAirFnWTdb, PsyHFnTdbW, PsyCpAirFnW, RhoH2O
# - Curve: GetCurve, ShowSevereCurveDims
# - Sched: GetSchedule, GetScheduleAlwaysOn
# - DataZoneEquipment: CheckZoneEquipmentList
# - WaterManager: SetupTankSupplyComponent
# - Node: GetOnlySingleNode, ConnectionObjectType, FluidType, ConnectionType, CompFluidStream, ObjectIsNotParent
# - InputProcessor: for JSON iteration and field extraction
# - OutputProcessor: SetupOutputVariable, TimeStepType, StoreType, Group, EndUseCat
# - UtilityRoutines: Util.FindItemInList, Util.makeUPPER, Util.SameString
# - Constants: rSecsInDay, Units, eResource, etc.
# - ErrorObjectHeader: for error handling

from enum import IntEnum
from typing import Optional, List, Protocol
from dataclasses import dataclass, field

class CondensateOutlet(IntEnum):
    Invalid = -1
    Discarded = 0
    ToTank = 1
    Num = 2

@dataclass
class Curve:
    pass

@dataclass
class Schedule:
    pass

@dataclass
class ZoneDehumidifierParams:
    Name: str = ""
    UnitType: str = ""
    availSched: Optional[Schedule] = None
    RatedWaterRemoval: float = 0.0
    RatedEnergyFactor: float = 0.0
    RatedAirVolFlow: float = 0.0
    RatedAirMassFlow: float = 0.0
    MinInletAirTemp: float = 0.0
    MaxInletAirTemp: float = 0.0
    InletAirMassFlow: float = 0.0
    OutletAirEnthalpy: float = 0.0
    OutletAirHumRat: float = 0.0
    OffCycleParasiticLoad: float = 0.0
    AirInletNodeNum: int = 0
    AirOutletNodeNum: int = 0
    WaterRemovalCurve: Optional[Curve] = None
    WaterRemovalCurveErrorCount: int = 0
    WaterRemovalCurveErrorIndex: int = 0
    EnergyFactorCurve: Optional[Curve] = None
    EnergyFactorCurveErrorCount: int = 0
    EnergyFactorCurveErrorIndex: int = 0
    PartLoadCurve: Optional[Curve] = None
    LowPLFErrorCount: int = 0
    LowPLFErrorIndex: int = 0
    HighPLFErrorCount: int = 0
    HighPLFErrorIndex: int = 0
    HighRTFErrorCount: int = 0
    HighRTFErrorIndex: int = 0
    PLFPLRErrorCount: int = 0
    PLFPLRErrorIndex: int = 0
    CondensateCollectMode: CondensateOutlet = CondensateOutlet.Discarded
    CondensateCollectName: str = ""
    CondensateTankID: int = 0
    CondensateTankSupplyARRID: int = 0
    SensHeatingRate: float = 0.0
    SensHeatingEnergy: float = 0.0
    WaterRemovalRate: float = 0.0
    WaterRemoved: float = 0.0
    ElecPower: float = 0.0
    ElecConsumption: float = 0.0
    DehumidPLR: float = 0.0
    DehumidRTF: float = 0.0
    DehumidCondVolFlowRate: float = 0.0
    DehumidCondVol: float = 0.0
    OutletAirTemp: float = 0.0
    OffCycleParasiticElecPower: float = 0.0
    OffCycleParasiticElecCons: float = 0.0
    MyEnvrnFlag: bool = True
    CheckEquipName: bool = True
    ZoneEquipmentListChecked: bool = False

@dataclass
class ZoneDehumidifierData:
    GetInputFlag: bool = True
    ZoneDehumid: List[ZoneDehumidifierParams] = field(default_factory=list)

def SimZoneDehumidifier(state, CompName: str, ZoneNum: int, FirstHVACIteration: bool):
    QSensOut = [0.0]
    QLatOut = [0.0]
    CompIndex = [0]
    
    if state.dataZoneDehumidifier.GetInputFlag:
        GetZoneDehumidifierInput(state)
        state.dataZoneDehumidifier.GetInputFlag = False
    
    if CompIndex[0] == 0:
        ZoneDehumidNum = Util.FindItemInList(CompName, state.dataZoneDehumidifier.ZoneDehumid)
        if ZoneDehumidNum == 0:
            ShowFatalError(state, f"SimZoneDehumidifier: Unit not found= {CompName}")
        CompIndex[0] = ZoneDehumidNum
    else:
        ZoneDehumidNum = CompIndex[0]
        NumDehumidifiers = len(state.dataZoneDehumidifier.ZoneDehumid)
        if ZoneDehumidNum > NumDehumidifiers or ZoneDehumidNum < 1:
            ShowFatalError(state, f"SimZoneDehumidifier:  Invalid CompIndex passed= {ZoneDehumidNum}, Number of Units= {NumDehumidifiers}, Entered Unit name= {CompName}")
        if state.dataZoneDehumidifier.ZoneDehumid[ZoneDehumidNum - 1].CheckEquipName:
            if CompName != state.dataZoneDehumidifier.ZoneDehumid[ZoneDehumidNum - 1].Name:
                ShowFatalError(state, f"SimZoneDehumidifier: Invalid CompIndex passed={ZoneDehumidNum}, Unit name= {CompName}, stored Unit Name for that index= {state.dataZoneDehumidifier.ZoneDehumid[ZoneDehumidNum - 1].Name}")
            state.dataZoneDehumidifier.ZoneDehumid[ZoneDehumidNum - 1].CheckEquipName = False
    
    QZnDehumidReq = state.dataZoneEnergyDemand.ZoneSysMoistureDemand[ZoneNum].RemainingOutputReqToDehumidSP
    
    InitZoneDehumidifier(state, ZoneDehumidNum)
    
    SensOut, LatOut = CalcZoneDehumidifier(state, ZoneDehumidNum, QZnDehumidReq)
    QSensOut[0] = SensOut
    QLatOut[0] = LatOut
    
    UpdateZoneDehumidifier(state, ZoneDehumidNum)
    
    ReportZoneDehumidifier(state, ZoneDehumidNum)
    
    return QSensOut[0], QLatOut[0], CompIndex[0]

def GetZoneDehumidifierInput(state):
    routineName = "GetZoneDehumidifierInput"
    CurrentModuleObject = "ZoneHVAC:Dehumidifier:DX"
    RatedInletAirTemp = 26.7
    RatedInletAirRH = 60.0
    
    ErrorsFound = False
    
    inputProcessor = state.dataInputProcessing.inputProcessor
    NumDehumidifiers = inputProcessor.getNumObjectsFound(state, CurrentModuleObject)
    
    state.dataZoneDehumidifier.ZoneDehumid = [ZoneDehumidifierParams() for _ in range(NumDehumidifiers)]
    
    objectSchemaProps = inputProcessor.getObjectSchemaProps(state, CurrentModuleObject)
    dehumidObjects = inputProcessor.epJSON.get(CurrentModuleObject, {})
    
    ZoneDehumidIndex = 0
    
    for dehumidInstance_key, dehumidFields in dehumidObjects.items():
        dehumidName = Util.makeUPPER(dehumidInstance_key)
        availabilityScheduleName = inputProcessor.getAlphaFieldValue(dehumidFields, objectSchemaProps, "availability_schedule_name")
        airInletNodeName = inputProcessor.getAlphaFieldValue(dehumidFields, objectSchemaProps, "air_inlet_node_name")
        airOutletNodeName = inputProcessor.getAlphaFieldValue(dehumidFields, objectSchemaProps, "air_outlet_node_name")
        waterRemovalCurveName = inputProcessor.getAlphaFieldValue(dehumidFields, objectSchemaProps, "water_removal_curve_name")
        energyFactorCurveName = inputProcessor.getAlphaFieldValue(dehumidFields, objectSchemaProps, "energy_factor_curve_name")
        partLoadFractionCorrelationCurveName = inputProcessor.getAlphaFieldValue(dehumidFields, objectSchemaProps, "part_load_fraction_correlation_curve_name")
        condensateCollectionWaterStorageTankName = inputProcessor.getAlphaFieldValue(dehumidFields, objectSchemaProps, "condensate_collection_water_storage_tank_name")
        
        inputProcessor.markObjectAsUsed(CurrentModuleObject, dehumidInstance_key)
        
        eoh = ErrorObjectHeader(routineName, CurrentModuleObject, dehumidName)
        
        dehumid = state.dataZoneDehumidifier.ZoneDehumid[ZoneDehumidIndex]
        dehumid.Name = dehumidName
        dehumid.UnitType = CurrentModuleObject
        
        if not availabilityScheduleName:
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
            ShowContinueError(state, f"Value specified = {dehumid.RatedWaterRemoval:.5f}")
            ShowContinueError(state, f"Occurs in {CurrentModuleObject} = {dehumid.Name}")
            ErrorsFound = True
        
        dehumid.RatedEnergyFactor = inputProcessor.getRealFieldValue(dehumidFields, objectSchemaProps, "rated_energy_factor")
        if dehumid.RatedEnergyFactor <= 0.0:
            ShowSevereError(state, "Rated Energy Factor must be greater than zero.")
            ShowContinueError(state, f"Value specified = {dehumid.RatedEnergyFactor:.5f}")
            ShowContinueError(state, f"Occurs in {CurrentModuleObject} = {dehumid.Name}")
            ErrorsFound = True
        
        dehumid.RatedAirVolFlow = inputProcessor.getRealFieldValue(dehumidFields, objectSchemaProps, "rated_air_flow_rate")
        if dehumid.RatedAirVolFlow <= 0.0:
            ShowSevereError(state, "Rated Air Flow Rate must be greater than zero.")
            ShowContinueError(state, f"Value specified = {dehumid.RatedAirVolFlow:.5f}")
            ShowContinueError(state, f"Occurs in {CurrentModuleObject} = {dehumid.Name}")
            ErrorsFound = True
        
        if not waterRemovalCurveName:
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
                CurveVal = dehumid.WaterRemovalCurve.value(state, RatedInletAirTemp, RatedInletAirRH)
                if CurveVal > 1.10 or CurveVal < 0.90:
                    ShowWarningError(state, "Water Removal Curve Name output is not equal to 1.0")
                    ShowContinueError(state, f"(+ or -10%) at rated conditions for {CurrentModuleObject} = {dehumidName}")
                    ShowContinueError(state, f"Curve output at rated conditions = {CurveVal:.3f}")
        
        if not energyFactorCurveName:
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
                CurveVal = dehumid.EnergyFactorCurve.value(state, RatedInletAirTemp, RatedInletAirRH)
                if CurveVal > 1.10 or CurveVal < 0.90:
                    ShowWarningError(state, "Energy Factor Curve Name output is not equal to 1.0")
                    ShowContinueError(state, f"(+ or -10%) at rated conditions for {CurrentModuleObject} = {dehumidName}")
                    ShowContinueError(state, f"Curve output at rated conditions = {CurveVal:.3f}")
        
        if not partLoadFractionCorrelationCurveName:
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
            ShowContinueError(state, f"Maximum Dry-Bulb Temperature for Dehumidifier Operation specified = {dehumid.MaxInletAirTemp:.1f}")
            ShowContinueError(state, f"Minimum Dry-Bulb Temperature for Dehumidifier Operation specified = {dehumid.MinInletAirTemp:.1f}")
            ShowContinueError(state, f"Occurs in {CurrentModuleObject} = {dehumid.Name}")
            ErrorsFound = True
        
        dehumid.OffCycleParasiticLoad = inputProcessor.getRealFieldValue(dehumidFields, objectSchemaProps, "off_cycle_parasitic_electric_load")
        
        if dehumid.OffCycleParasiticLoad < 0.0:
            ShowSevereError(state, "Off-Cycle Parasitic Electric Load must be >= zero.")
            ShowContinueError(state, f"Value specified = {dehumid.OffCycleParasiticLoad:.2f}")
            ShowContinueError(state, f"Occurs in {CurrentModuleObject} = {dehumid.Name}")
            ErrorsFound = True
        
        dehumid.CondensateCollectName = condensateCollectionWaterStorageTankName
        if not condensateCollectionWaterStorageTankName:
            dehumid.CondensateCollectMode = CondensateOutlet.Discarded
        else:
            dehumid.CondensateCollectMode = CondensateOutlet.ToTank
            WaterManager.SetupTankSupplyComponent(state, dehumid.Name, CurrentModuleObject, condensateCollectionWaterStorageTankName, ErrorsFound, dehumid.CondensateTankID, dehumid.CondensateTankSupplyARRID)
        
        ZoneDehumidIndex += 1
    
    if ErrorsFound:
        ShowFatalError(state, f"{routineName}:{CurrentModuleObject}: Errors found in input.")
    
    for ZoneDehumidIndex in range(NumDehumidifiers):
        dehumid = state.dataZoneDehumidifier.ZoneDehumid[ZoneDehumidIndex]
        
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
        
        if dehumid.CondensateCollectMode == CondensateOutlet.ToTank:
            SetupOutputVariable(state, "Zone Dehumidifier Condensate Volume Flow Rate", Constant.Units.m3_s, dehumid, "DehumidCondVolFlowRate", OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, dehumid.Name)
            SetupOutputVariable(state, "Zone Dehumidifier Condensate Volume", Constant.Units.m3, dehumid, "DehumidCondVol", OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, dehumid.Name, Constant.eResource.OnSiteWater, OutputProcessor.Group.HVAC, OutputProcessor.EndUseCat.Condensate)

def InitZoneDehumidifier(state, ZoneDehumNum: int):
    RoutineName = "InitZoneDehumidifier"
    
    dehumid = state.dataZoneDehumidifier.ZoneDehumid[ZoneDehumNum - 1]
    
    if not dehumid.ZoneEquipmentListChecked and state.dataZoneEquip.ZoneEquipInputsFilled:
        dehumid.ZoneEquipmentListChecked = True
        if not DataZoneEquipment.CheckZoneEquipmentList(state, dehumid.UnitType, dehumid.Name):
            ShowSevereError(state, f"InitZoneDehumidifier: Zone Dehumidifier=\"{dehumid.UnitType},{dehumid.Name}\" is not on any ZoneHVAC:EquipmentList.  It will not be simulated.")
    
    AirInletNode = dehumid.AirInletNodeNum
    
    if state.dataGlobal.BeginEnvrnFlag and dehumid.MyEnvrnFlag:
        RatedAirDBTemp = 26.6667
        RatedAirRH = 0.6
        RatedAirHumrat = Psychrometrics.PsyWFnTdbRhPb(state, RatedAirDBTemp, RatedAirRH, state.dataEnvrn.StdBaroPress, RoutineName)
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

def CalcZoneDehumidifier(state, ZoneDehumNum: int, QZnDehumidReq: float):
    RoutineName = "CalcZoneDehumidifier"
    
    dehumid = state.dataZoneDehumidifier.ZoneDehumid[ZoneDehumNum - 1]
    
    SensibleOutput = 0.0
    LatentOutput = 0.0
    WaterRemovalRateFactor = 0.0
    AirMassFlowRate = 0.0
    PLR = 0.0
    PLF = 0.0
    EnergyFactorAdjFactor = 0.0
    RunTimeFraction = 0.0
    ElectricPowerAvg = 0.0
    ElectricPowerOnCycle = 0.0
    
    AirInletNodeNum = dehumid.AirInletNodeNum
    
    InletAirTemp = state.dataLoopNodes.Node[AirInletNodeNum].Temp
    InletAirHumRat = state.dataLoopNodes.Node[AirInletNodeNum].HumRat
    InletAirRH = 100.0 * Psychrometrics.PsyRhFnTdbWPb(state, InletAirTemp, InletAirHumRat, state.dataEnvrn.OutBaroPress, RoutineName)
    
    if QZnDehumidReq < 0.0 and dehumid.availSched.getCurrentVal() > 0.0 and InletAirTemp >= dehumid.MinInletAirTemp and InletAirTemp <= dehumid.MaxInletAirTemp:
        
        WaterRemovalRateFactor = dehumid.WaterRemovalCurve.value(state, InletAirTemp, InletAirRH)
        
        if WaterRemovalRateFactor <= 0.0:
            if dehumid.WaterRemovalCurveErrorCount < 1:
                dehumid.WaterRemovalCurveErrorCount += 1
                ShowWarningError(state, f"{dehumid.UnitType} \"{dehumid.Name}\":")
                ShowContinueError(state, f" Water Removal Rate Curve output is <= 0.0 ({WaterRemovalRateFactor:.5f}).")
                ShowContinueError(state, f" Negative value occurs using an inlet air dry-bulb temperature of {InletAirTemp:.2f} and an inlet air relative humidity of {InletAirRH:.1f}.")
                ShowContinueErrorTimeStamp(state, " Dehumidifier turned off for this time step but simulation continues.")
            else:
                ShowRecurringWarningErrorAtEnd(state, f"{dehumid.UnitType} \"{dehumid.Name}\": Water Removal Rate Curve output is <= 0.0 warning continues...", dehumid.WaterRemovalCurveErrorIndex, WaterRemovalRateFactor, WaterRemovalRateFactor)
            WaterRemovalRateFactor = 0.0
        
        WaterRemovalVolRate = WaterRemovalRateFactor * dehumid.RatedWaterRemoval
        
        WaterRemovalMassRate = WaterRemovalVolRate / (Constant.rSecsInDay * 1000.0) * Psychrometrics.RhoH2O(max((InletAirTemp - 11.0), 1.0))
        
        if WaterRemovalMassRate > 0.0:
            PLR = max(0.0, min(1.0, -QZnDehumidReq / WaterRemovalMassRate))
        else:
            PLR = 0.0
            RunTimeFraction = 0.0
        
        EnergyFactorAdjFactor = dehumid.EnergyFactorCurve.value(state, InletAirTemp, InletAirRH)
        
        if EnergyFactorAdjFactor <= 0.0:
            if dehumid.EnergyFactorCurveErrorCount < 1:
                dehumid.EnergyFactorCurveErrorCount += 1
                ShowWarningError(state, f"{dehumid.UnitType} \"{dehumid.Name}\":")
                ShowContinueError(state, f" Energy Factor Curve output is <= 0.0 ({EnergyFactorAdjFactor:.5f}).")
                ShowContinueError(state, f" Negative value occurs using an inlet air dry-bulb temperature of {InletAirTemp:.2f} and an inlet air relative humidity of {InletAirRH:.1f}.")
                ShowContinueErrorTimeStamp(state, " Dehumidifier turned off for this time step but simulation continues.")
            else:
                ShowRecurringWarningErrorAtEnd(state, f"{dehumid.UnitType} \"{dehumid.Name}\": Energy Factor Curve output is <= 0.0 warning continues...", dehumid.EnergyFactorCurveErrorIndex, EnergyFactorAdjFactor, EnergyFactorAdjFactor)
            ElectricPowerAvg = 0.0
            PLR = 0.0
            RunTimeFraction = 0.0
        else:
            EnergyFactor = EnergyFactorAdjFactor * dehumid.RatedEnergyFactor
            
            if dehumid.PartLoadCurve is not None:
                PLF = dehumid.PartLoadCurve.value(state, PLR)
            else:
                PLF = 1.0
            
            if PLF < 0.7:
                if dehumid.LowPLFErrorCount < 1:
                    dehumid.LowPLFErrorCount += 1
                    ShowWarningError(state, f"{dehumid.UnitType} \"{dehumid.Name}\":")
                    ShowContinueError(state, f" The Part Load Fraction Correlation Curve output is ({PLF:.2f}) at a part-load ratio ={PLR:.3f}")
                    ShowContinueErrorTimeStamp(state, " PLF curve values must be >= 0.7.  PLF has been reset to 0.7 and simulation is continuing.")
                else:
                    ShowRecurringWarningErrorAtEnd(state, f"{dehumid.UnitType} \"{dehumid.Name}\": Part Load Fraction Correlation Curve output < 0.7 warning continues...", dehumid.LowPLFErrorIndex, PLF, PLF)
                PLF = 0.7
            
            if PLF > 1.0:
                if dehumid.HighPLFErrorCount < 1:
                    dehumid.HighPLFErrorCount += 1
                    ShowWarningError(state, f"{dehumid.UnitType} \"{dehumid.Name}\":")
                    ShowContinueError(state, f" The Part Load Fraction Correlation Curve output is ({PLF:.2f}) at a part-load ratio ={PLR:.3f}")
                    ShowContinueErrorTimeStamp(state, " PLF curve values must be < 1.0.  PLF has been reset to 1.0 and simulation is continuing.")
                else:
                    ShowRecurringWarningErrorAtEnd(state, f"{dehumid.UnitType} \"{dehumid.Name}\": Part Load Fraction Correlation Curve output > 1.0 warning continues...", dehumid.HighPLFErrorIndex, PLF, PLF)
                PLF = 1.0
            
            if PLF > 0.0 and PLF >= PLR:
                RunTimeFraction = PLR / PLF
            else:
                if dehumid.PLFPLRErrorCount < 1:
                    dehumid.PLFPLRErrorCount += 1
                    ShowWarningError(state, f"{dehumid.UnitType} \"{dehumid.Name}\":")
                    ShowContinueError(state, f"The part load fraction was less than the part load ratio calculated for this time step [PLR={PLR:.4f}, PLF={PLF:.4f}].")
                    ShowContinueError(state, "Runtime fraction reset to 1 and the simulation will continue.")
                    ShowContinueErrorTimeStamp(state, "")
                else:
                    ShowRecurringWarningErrorAtEnd(state, f"{dehumid.UnitType} \"{dehumid.Name}\": Part load fraction less than part load ratio warning continues...", dehumid.PLFPLRErrorIndex)
                RunTimeFraction = 1.0
            
            if RunTimeFraction > 1.0 and abs(RunTimeFraction - 1.0) > 0.001:
                if dehumid.HighRTFErrorCount < 1:
                    dehumid.HighRTFErrorCount += 1
                    ShowWarningError(state, f"{dehumid.UnitType} \"{dehumid.Name}\":")
                    ShowContinueError(state, f"The runtime fraction for this zone dehumidifier exceeded 1.0 [{RunTimeFraction:.4f}].")
                    ShowContinueError(state, "Runtime fraction reset to 1 and the simulation will continue.")
                    ShowContinueErrorTimeStamp(state, "")
                else:
                    ShowRecurringWarningErrorAtEnd(state, f"{dehumid.UnitType} \"{dehumid.Name}\": Runtime fraction for zone dehumidifier exceeded 1.0 warning continues...", dehumid.HighRTFErrorIndex, RunTimeFraction, RunTimeFraction)
                RunTimeFraction = 1.0
            
            ElectricPowerOnCycle = WaterRemovalVolRate / (EnergyFactor * 24.0) * 1000.0
            ElectricPowerAvg = ElectricPowerOnCycle * RunTimeFraction + (1.0 - RunTimeFraction) * dehumid.OffCycleParasiticLoad
        
        LatentOutput = WaterRemovalMassRate * PLR
        hfg = Psychrometrics.PsyHfgAirFnWTdb(InletAirHumRat, InletAirTemp)
        SensibleOutput = (LatentOutput * hfg) + ElectricPowerAvg
        
        state.dataLoopNodes.Node[AirInletNodeNum].MassFlowRate = dehumid.RatedAirMassFlow * PLR
        AirMassFlowRate = state.dataLoopNodes.Node[AirInletNodeNum].MassFlowRate
        Cp = Psychrometrics.PsyCpAirFnW(InletAirHumRat)
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

def UpdateZoneDehumidifier(state, ZoneDehumNum: int):
    dehumid = state.dataZoneDehumidifier.ZoneDehumid[ZoneDehumNum - 1]
    airInletNode = state.dataLoopNodes.Node[dehumid.AirInletNodeNum]
    airOutletNode = state.dataLoopNodes.Node[dehumid.AirOutletNodeNum]
    
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

def ReportZoneDehumidifier(state, DehumidNum: int):
    TimeStepSysSec = state.dataHVACGlobal.TimeStepSysSec
    
    dehumid = state.dataZoneDehumidifier.ZoneDehumid[DehumidNum - 1]
    
    dehumid.SensHeatingEnergy = dehumid.SensHeatingRate * TimeStepSysSec
    dehumid.WaterRemoved = dehumid.WaterRemovalRate * TimeStepSysSec
    dehumid.ElecConsumption = dehumid.ElecPower * TimeStepSysSec
    dehumid.OffCycleParasiticElecCons = dehumid.OffCycleParasiticElecPower * TimeStepSysSec
    
    if dehumid.CondensateCollectMode == CondensateOutlet.ToTank:
        AirInletNodeNum = dehumid.AirInletNodeNum
        InletAirTemp = state.dataLoopNodes.Node[AirInletNodeNum].Temp
        OutletAirTemp = max((InletAirTemp - 11.0), 1.0)
        RhoWater = Psychrometrics.RhoH2O(OutletAirTemp)
        
        if RhoWater > 0.0:
            dehumid.DehumidCondVolFlowRate = dehumid.WaterRemovalRate / RhoWater
        
        dehumid.DehumidCondVol = dehumid.DehumidCondVolFlowRate * TimeStepSysSec
        
        state.dataWaterData.WaterStorage[dehumid.CondensateTankID].VdotAvailSupply[dehumid.CondensateTankSupplyARRID] = dehumid.DehumidCondVolFlowRate
        state.dataWaterData.WaterStorage[dehumid.CondensateTankID].TwaterSupply[dehumid.CondensateTankSupplyARRID] = OutletAirTemp

def GetZoneDehumidifierNodeNumber(state, NodeNumber: int) -> bool:
    if state.dataZoneDehumidifier.GetInputFlag:
        GetZoneDehumidifierInput(state)
        state.dataZoneDehumidifier.GetInputFlag = False
    
    FindZoneDehumidifierNodeNumber = False
    for ZoneDehumidIndex in range(len(state.dataZoneDehumidifier.ZoneDehumid)):
        if NodeNumber == state.dataZoneDehumidifier.ZoneDehumid[ZoneDehumidIndex].AirInletNodeNum:
            FindZoneDehumidifierNodeNumber = True
            break
        if NodeNumber == state.dataZoneDehumidifier.ZoneDehumid[ZoneDehumidIndex].AirOutletNodeNum:
            FindZoneDehumidifierNodeNumber = True
            break
    
    return FindZoneDehumidifierNodeNumber

def getZoneDehumidifierIndex(state, CompName: str) -> int:
    if state.dataZoneDehumidifier.GetInputFlag:
        GetZoneDehumidifierInput(state)
        state.dataZoneDehumidifier.GetInputFlag = False
    
    for ZoneDehumidNum in range(len(state.dataZoneDehumidifier.ZoneDehumid)):
        if Util.SameString(state.dataZoneDehumidifier.ZoneDehumid[ZoneDehumidNum].Name, CompName):
            return ZoneDehumidNum + 1
    
    return 0

class ErrorObjectHeader:
    def __init__(self, routine, object_type, object_name):
        self.routine = routine
        self.object_type = object_type
        self.object_name = object_name
