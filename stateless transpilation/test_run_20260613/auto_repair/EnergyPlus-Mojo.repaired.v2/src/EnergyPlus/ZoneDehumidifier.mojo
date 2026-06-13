from Data.BaseData import BaseGlobalStruct, BaseData
from DataGlobals import *
from EnergyPlus import *
from CurveManager import Curve
from .Data.EnergyPlusData import EnergyPlusData
from DataContaminantBalance import *
from DataEnvironment import *
from DataHVACGlobals import *
from DataLoopNode import *
from DataWater import *
from DataZoneEnergyDemands import *
from DataZoneEquipment import *
from .InputProcessing.InputProcessor import *
from NodeInputManager import *
from OutputProcessor import *
from Psychrometrics import *
from ScheduleManager import *
from UtilityRoutines import *
from WaterManager import *
from ZoneDehumidifier import *

@value
struct CondensateOutlet:
    Invalid = -1
    Discarded = 0
    ToTank = 1
    Num = 2

@value
struct ZoneDehumidifierParams:
    var Name: String
    var UnitType: String
    var availSched: Schedule = None
    var RatedWaterRemoval: Float64 = 0.0
    var RatedEnergyFactor: Float64 = 0.0
    var RatedAirVolFlow: Float64 = 0.0
    var RatedAirMassFlow: Float64 = 0.0
    var MinInletAirTemp: Float64 = 0.0
    var MaxInletAirTemp: Float64 = 0.0
    var InletAirMassFlow: Float64 = 0.0
    var OutletAirEnthalpy: Float64 = 0.0
    var OutletAirHumRat: Float64 = 0.0
    var OffCycleParasiticLoad: Float64 = 0.0
    var AirInletNodeNum: Int = 0
    var AirOutletNodeNum: Int = 0
    var WaterRemovalCurve: Curve = None
    var WaterRemovalCurveErrorCount: Int = 0
    var WaterRemovalCurveErrorIndex: Int = 0
    var EnergyFactorCurve: Curve = None
    var EnergyFactorCurveErrorCount: Int = 0
    var EnergyFactorCurveErrorIndex: Int = 0
    var PartLoadCurve: Curve = None
    var LowPLFErrorCount: Int = 0
    var LowPLFErrorIndex: Int = 0
    var HighPLFErrorCount: Int = 0
    var HighPLFErrorIndex: Int = 0
    var HighRTFErrorCount: Int = 0
    var HighRTFErrorIndex: Int = 0
    var PLFPLRErrorCount: Int = 0
    var PLFPLRErrorIndex: Int = 0
    var CondensateCollectMode: CondensateOutlet = CondensateOutlet.Discarded
    var CondensateCollectName: String = ""
    var CondensateTankID: Int = 0
    var CondensateTankSupplyARRID: Int = 0
    var SensHeatingRate: Float64 = 0.0
    var SensHeatingEnergy: Float64 = 0.0
    var WaterRemovalRate: Float64 = 0.0
    var WaterRemoved: Float64 = 0.0
    var ElecPower: Float64 = 0.0
    var ElecConsumption: Float64 = 0.0
    var DehumidPLR: Float64 = 0.0
    var DehumidRTF: Float64 = 0.0
    var DehumidCondVolFlowRate: Float64 = 0.0
    var DehumidCondVol: Float64 = 0.0
    var OutletAirTemp: Float64 = 0.0
    var OffCycleParasiticElecPower: Float64 = 0.0
    var OffCycleParasiticElecCons: Float64 = 0.0
    var MyEnvrnFlag: Bool = True
    var CheckEquipName: Bool = True
    var ZoneEquipmentListChecked: Bool = False

def SimZoneDehumidifier(
    state: EnergyPlusData,
    CompName: String,
    ZoneNum: Int,
    FirstHVACIteration: Bool,
    QSensOut: Float64,
    QLatOut: Float64,
    CompIndex: Int
):
    var ZoneDehumidNum: Int
    var QZnDehumidReq: Float64
    if state.dataZoneDehumidifier.GetInputFlag:
        GetZoneDehumidifierInput(state)
        state.dataZoneDehumidifier.GetInputFlag = False
    if CompIndex == 0:
        ZoneDehumidNum = Util.FindItemInList(CompName, state.dataZoneDehumidifier.ZoneDehumid)
        if ZoneDehumidNum == 0:
            ShowFatalError(state, "SimZoneDehumidifier: Unit not found= " + CompName)
        CompIndex = ZoneDehumidNum
    else:
        ZoneDehumidNum = CompIndex
        var NumDehumidifiers: Int = state.dataZoneDehumidifier.ZoneDehumid.size()
        if ZoneDehumidNum > NumDehumidifiers or ZoneDehumidNum < 1:
            ShowFatalError(
                state,
                "SimZoneDehumidifier:  Invalid CompIndex passed= " + str(ZoneDehumidNum) +
                ", Number of Units= " + str(NumDehumidifiers) +
                ", Entered Unit name= " + CompName
            )
        if state.dataZoneDehumidifier.ZoneDehumid[ZoneDehumidNum - 1].CheckEquipName:
            if CompName != state.dataZoneDehumidifier.ZoneDehumid[ZoneDehumidNum - 1].Name:
                ShowFatalError(
                    state,
                    "SimZoneDehumidifier: Invalid CompIndex passed=" + str(ZoneDehumidNum) +
                    ", Unit name= " + CompName +
                    ", stored Unit Name for that index= " +
                    state.dataZoneDehumidifier.ZoneDehumid[ZoneDehumidNum - 1].Name
                )
            state.dataZoneDehumidifier.ZoneDehumid[ZoneDehumidNum - 1].CheckEquipName = False
    QZnDehumidReq = state.dataZoneEnergyDemand.ZoneSysMoistureDemand[ZoneNum - 1].RemainingOutputReqToDehumidSP
    InitZoneDehumidifier(state, ZoneDehumidNum)
    CalcZoneDehumidifier(state, ZoneDehumidNum, QZnDehumidReq, QSensOut, QLatOut)
    UpdateZoneDehumidifier(state, ZoneDehumidNum)
    ReportZoneDehumidifier(state, ZoneDehumidNum)

def GetZoneDehumidifierInput(state: EnergyPlusData):
    var routineName: String = "GetZoneDehumidifierInput"
    var CurrentModuleObject: String = "ZoneHVAC:Dehumidifier:DX"
    var RatedInletAirTemp: Float64 = 26.7
    var RatedInletAirRH: Float64 = 60.0
    var ZoneDehumidIndex: Int
    var ErrorsFound: Bool = False
    var inputProcessor = state.dataInputProcessing.inputProcessor
    var NumDehumidifiers: Int = inputProcessor.getNumObjectsFound(state, CurrentModuleObject)
    state.dataZoneDehumidifier.ZoneDehumid.allocate(NumDehumidifiers)
    var objectSchemaProps = inputProcessor.getObjectSchemaProps(state, CurrentModuleObject)
    var dehumidObjects = inputProcessor.epJSON.find(CurrentModuleObject)
    ZoneDehumidIndex = 1
    if dehumidObjects != inputProcessor.epJSON.end():
        for dehumidInstance in dehumidObjects.value().items():
            var dehumidFields = dehumidInstance.value()
            var dehumidName = Util.makeUPPER(dehumidInstance.key())
            var availabilityScheduleName = inputProcessor.getAlphaFieldValue(dehumidFields, objectSchemaProps, "availability_schedule_name")
            var airInletNodeName = inputProcessor.getAlphaFieldValue(dehumidFields, objectSchemaProps, "air_inlet_node_name")
            var airOutletNodeName = inputProcessor.getAlphaFieldValue(dehumidFields, objectSchemaProps, "air_outlet_node_name")
            var waterRemovalCurveName = inputProcessor.getAlphaFieldValue(dehumidFields, objectSchemaProps, "water_removal_curve_name")
            var energyFactorCurveName = inputProcessor.getAlphaFieldValue(dehumidFields, objectSchemaProps, "energy_factor_curve_name")
            var partLoadFractionCorrelationCurveName = inputProcessor.getAlphaFieldValue(dehumidFields, objectSchemaProps, "part_load_fraction_correlation_curve_name")
            var condensateCollectionWaterStorageTankName = inputProcessor.getAlphaFieldValue(dehumidFields, objectSchemaProps, "condensate_collection_water_storage_tank_name")
            inputProcessor.markObjectAsUsed(CurrentModuleObject, dehumidInstance.key())
            var eoh = ErrorObjectHeader(routineName, CurrentModuleObject, dehumidName)
            var dehumid = state.dataZoneDehumidifier.ZoneDehumid[ZoneDehumidIndex - 1]
            dehumid.Name = dehumidName
            dehumid.UnitType = CurrentModuleObject
            if availabilityScheduleName.empty():
                dehumid.availSched = Sched.GetScheduleAlwaysOn(state)
            elif (dehumid.availSched = Sched.GetSchedule(state, availabilityScheduleName)) == None:
                ShowSevereItemNotFound(state, eoh, "Availability Schedule Name", availabilityScheduleName)
                ErrorsFound = True
            dehumid.AirInletNodeNum = Node.GetOnlySingleNode(
                state,
                airInletNodeName,
                ErrorsFound,
                Node.ConnectionObjectType.ZoneHVACDehumidifierDX,
                dehumidName,
                Node.FluidType.Air,
                Node.ConnectionType.Inlet,
                Node.CompFluidStream.Primary,
                Node.ObjectIsNotParent
            )
            dehumid.AirOutletNodeNum = Node.GetOnlySingleNode(
                state,
                airOutletNodeName,
                ErrorsFound,
                Node.ConnectionObjectType.ZoneHVACDehumidifierDX,
                dehumidName,
                Node.FluidType.Air,
                Node.ConnectionType.Outlet,
                Node.CompFluidStream.Primary,
                Node.ObjectIsNotParent
            )
            dehumid.RatedWaterRemoval = inputProcessor.getRealFieldValue(dehumidFields, objectSchemaProps, "rated_water_removal")
            if dehumid.RatedWaterRemoval <= 0.0:
                ShowSevereError(state, "Rated Water Removal must be greater than zero.")
                ShowContinueError(state, "Value specified = {:.5f}".format(dehumid.RatedWaterRemoval))
                ShowContinueError(state, "Occurs in {} = {}".format(CurrentModuleObject, dehumid.Name))
                ErrorsFound = True
            dehumid.RatedEnergyFactor = inputProcessor.getRealFieldValue(dehumidFields, objectSchemaProps, "rated_energy_factor")
            if dehumid.RatedEnergyFactor <= 0.0:
                ShowSevereError(state, "Rated Energy Factor must be greater than zero.")
                ShowContinueError(state, "Value specified = {:.5f}".format(dehumid.RatedEnergyFactor))
                ShowContinueError(state, "Occurs in {} = {}".format(CurrentModuleObject, dehumid.Name))
                ErrorsFound = True
            dehumid.RatedAirVolFlow = inputProcessor.getRealFieldValue(dehumidFields, objectSchemaProps, "rated_air_flow_rate")
            if dehumid.RatedAirVolFlow <= 0.0:
                ShowSevereError(state, "Rated Air Flow Rate must be greater than zero.")
                ShowContinueError(state, "Value specified = {:.5f}".format(dehumid.RatedAirVolFlow))
                ShowContinueError(state, "Occurs in {} = {}".format(CurrentModuleObject, dehumid.Name))
                ErrorsFound = True
            if waterRemovalCurveName.empty():
                ShowSevereEmptyField(state, eoh, "Water Removal Curve Name")
                ErrorsFound = True
            elif (dehumid.WaterRemovalCurve = Curve.GetCurve(state, waterRemovalCurveName)) == None:
                ShowSevereItemNotFound(state, eoh, "Water Removal Curve Name", waterRemovalCurveName)
                ErrorsFound = True
            elif dehumid.WaterRemovalCurve.numDims != 2:
                Curve.ShowSevereCurveDims(state, eoh, "Water Removal Curve Name", waterRemovalCurveName, "2", dehumid.WaterRemovalCurve.numDims)
                ErrorsFound = True
            else:
                var CurveVal: Float64 = dehumid.WaterRemovalCurve.value(state, RatedInletAirTemp, RatedInletAirRH)
                if CurveVal > 1.10 or CurveVal < 0.90:
                    ShowWarningError(state, "Water Removal Curve Name output is not equal to 1.0")
                    ShowContinueError(state, "(+ or -10%) at rated conditions for {} = {}".format(CurrentModuleObject, dehumidName))
                    ShowContinueError(state, "Curve output at rated conditions = {:.3f}".format(CurveVal))
            if energyFactorCurveName.empty():
                ShowSevereEmptyField(state, eoh, "Energy Factor Curve Name")
                ErrorsFound = True
            elif (dehumid.EnergyFactorCurve = Curve.GetCurve(state, energyFactorCurveName)) == None:
                ShowSevereItemNotFound(state, eoh, "Energy Factor Curve Name", energyFactorCurveName)
                ErrorsFound = True
            elif dehumid.EnergyFactorCurve.numDims != 2:
                Curve.ShowSevereCurveDims(state, eoh, "Energy Factor Curve Name", energyFactorCurveName, "2", dehumid.EnergyFactorCurve.numDims)
                ErrorsFound = True
            else:
                var CurveVal: Float64 = dehumid.EnergyFactorCurve.value(state, RatedInletAirTemp, RatedInletAirRH)
                if CurveVal > 1.10 or CurveVal < 0.90:
                    ShowWarningError(state, "Energy Factor Curve Name output is not equal to 1.0")
                    ShowContinueError(state, "(+ or -10%) at rated conditions for {} = {}".format(CurrentModuleObject, dehumidName))
                    ShowContinueError(state, "Curve output at rated conditions = {:.3f}".format(CurveVal))
            if partLoadFractionCorrelationCurveName.empty():
                ShowSevereEmptyField(state, eoh, "Part Load Fraction Correlation Curve Name")
                ErrorsFound = True
            elif (dehumid.PartLoadCurve = Curve.GetCurve(state, partLoadFractionCorrelationCurveName)) == None:
                ShowSevereItemNotFound(state, eoh, "Part Load Fraction Correlation Curve Name", partLoadFractionCorrelationCurveName)
                ErrorsFound = True
            elif dehumid.PartLoadCurve.numDims != 1:
                Curve.ShowSevereCurveDims(state, eoh, "Part Load Fraction Correlation Curve Name", partLoadFractionCorrelationCurveName, "1", dehumid.PartLoadCurve.numDims)
                ErrorsFound = True
            dehumid.MinInletAirTemp = inputProcessor.getRealFieldValue(dehumidFields, objectSchemaProps, "minimum_dry_bulb_temperature_for_dehumidifier_operation")
            dehumid.MaxInletAirTemp = inputProcessor.getRealFieldValue(dehumidFields, objectSchemaProps, "maximum_dry_bulb_temperature_for_dehumidifier_operation")
            if dehumid.MinInletAirTemp >= dehumid.MaxInletAirTemp:
                ShowSevereError(state, "Maximum Dry-Bulb Temperature for Dehumidifier Operation must be greater than Minimum Dry-Bulb Temperature for Dehumidifier Operation")
                ShowContinueError(state, "{} specified = {:.1f}".format("Maximum Dry-Bulb Temperature for Dehumidifier Operation", dehumid.MaxInletAirTemp))
                ShowContinueError(state, "{} specified = {:.1f}".format("Minimum Dry-Bulb Temperature for Dehumidifier Operation", dehumid.MinInletAirTemp))
                ShowContinueError(state, "Occurs in {} = {}".format(CurrentModuleObject, dehumid.Name))
                ErrorsFound = True
            dehumid.OffCycleParasiticLoad = inputProcessor.getRealFieldValue(dehumidFields, objectSchemaProps, "off_cycle_parasitic_electric_load")
            if dehumid.OffCycleParasiticLoad < 0.0:
                ShowSevereError(state, "Off-Cycle Parasitic Electric Load must be >= zero.")
                ShowContinueError(state, "Value specified = {:.2f}".format(dehumid.OffCycleParasiticLoad))
                ShowContinueError(state, "Occurs in {} = {}".format(CurrentModuleObject, dehumid.Name))
                ErrorsFound = True
            dehumid.CondensateCollectName = condensateCollectionWaterStorageTankName
            if condensateCollectionWaterStorageTankName.empty():
                dehumid.CondensateCollectMode = CondensateOutlet.Discarded
            else:
                dehumid.CondensateCollectMode = CondensateOutlet.ToTank
                WaterManager.SetupTankSupplyComponent(
                    state,
                    dehumid.Name,
                    CurrentModuleObject,
                    condensateCollectionWaterStorageTankName,
                    ErrorsFound,
                    dehumid.CondensateTankID,
                    dehumid.CondensateTankSupplyARRID
                )
            ZoneDehumidIndex += 1
    if ErrorsFound:
        ShowFatalError(state, "{}:{}: Errors found in input.".format(routineName, CurrentModuleObject))
    for ZoneDehumidIndex in range(1, NumDehumidifiers + 1):
        var dehumid = state.dataZoneDehumidifier.ZoneDehumid[ZoneDehumidIndex - 1]
        SetupOutputVariable(
            state,
            "Zone Dehumidifier Sensible Heating Rate",
            Constant.Units.W,
            dehumid.SensHeatingRate,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            dehumid.Name
        )
        SetupOutputVariable(
            state,
            "Zone Dehumidifier Sensible Heating Energy",
            Constant.Units.J,
            dehumid.SensHeatingEnergy,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Sum,
            dehumid.Name
        )
        SetupOutputVariable(
            state,
            "Zone Dehumidifier Removed Water Mass Flow Rate",
            Constant.Units.kg_s,
            dehumid.WaterRemovalRate,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            dehumid.Name
        )
        SetupOutputVariable(
            state,
            "Zone Dehumidifier Removed Water Mass",
            Constant.Units.kg,
            dehumid.WaterRemoved,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Sum,
            dehumid.Name
        )
        SetupOutputVariable(
            state,
            "Zone Dehumidifier Electricity Rate",
            Constant.Units.W,
            dehumid.ElecPower,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            dehumid.Name
        )
        SetupOutputVariable(
            state,
            "Zone Dehumidifier Electricity Energy",
            Constant.Units.J,
            dehumid.ElecConsumption,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Sum,
            dehumid.Name,
            Constant.eResource.Electricity,
            OutputProcessor.Group.HVAC,
            OutputProcessor.EndUseCat.Cooling
        )
        SetupOutputVariable(
            state,
            "Zone Dehumidifier Off Cycle Parasitic Electricity Rate",
            Constant.Units.W,
            dehumid.OffCycleParasiticElecPower,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            dehumid.Name
        )
        SetupOutputVariable(
            state,
            "Zone Dehumidifier Off Cycle Parasitic Electricity Energy",
            Constant.Units.J,
            dehumid.OffCycleParasiticElecCons,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Sum,
            dehumid.Name
        )
        SetupOutputVariable(
            state,
            "Zone Dehumidifier Part Load Ratio",
            Constant.Units.None,
            dehumid.DehumidPLR,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            dehumid.Name
        )
        SetupOutputVariable(
            state,
            "Zone Dehumidifier Runtime Fraction",
            Constant.Units.None,
            dehumid.DehumidRTF,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            dehumid.Name
        )
        SetupOutputVariable(
            state,
            "Zone Dehumidifier Outlet Air Temperature",
            Constant.Units.C,
            dehumid.OutletAirTemp,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            dehumid.Name
        )
        if dehumid.CondensateCollectMode == CondensateOutlet.ToTank:
            SetupOutputVariable(
                state,
                "Zone Dehumidifier Condensate Volume Flow Rate",
                Constant.Units.m3_s,
                dehumid.DehumidCondVolFlowRate,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                dehumid.Name
            )
            SetupOutputVariable(
                state,
                "Zone Dehumidifier Condensate Volume",
                Constant.Units.m3,
                dehumid.DehumidCondVol,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Sum,
                dehumid.Name,
                Constant.eResource.OnSiteWater,
                OutputProcessor.Group.HVAC,
                OutputProcessor.EndUseCat.Condensate
            )

def InitZoneDehumidifier(state: EnergyPlusData, ZoneDehumNum: Int):
    var RoutineName: String = "InitZoneDehumidifier"
    var AirInletNode: Int
    var RatedAirHumrat: Float64
    var RatedAirDBTemp: Float64
    var RatedAirRH: Float64
    var dehumid = state.dataZoneDehumidifier.ZoneDehumid[ZoneDehumNum - 1]
    if not dehumid.ZoneEquipmentListChecked and state.dataZoneEquip.ZoneEquipInputsFilled:
        dehumid.ZoneEquipmentListChecked = True
        if not DataZoneEquipment.CheckZoneEquipmentList(state, dehumid.UnitType, dehumid.Name):
            ShowSevereError(
                state,
                "InitZoneDehumidifier: Zone Dehumidifier=\"{},{}\" is not on any ZoneHVAC:EquipmentList.  It will not be simulated.".format(
                    dehumid.UnitType, dehumid.Name
                )
            )
    AirInletNode = dehumid.AirInletNodeNum
    if state.dataGlobal.BeginEnvrnFlag and dehumid.MyEnvrnFlag:
        RatedAirDBTemp = 26.6667
        RatedAirRH = 0.6
        RatedAirHumrat = Psychrometrics.PsyWFnTdbRhPb(state, RatedAirDBTemp, RatedAirRH, state.dataEnvrn.StdBaroPress, RoutineName)
        dehumid.RatedAirMassFlow = Psychrometrics.PsyRhoAirFnPbTdbW(state, state.dataEnvrn.StdBaroPress, RatedAirDBTemp, RatedAirHumrat, RoutineName) * dehumid.RatedAirVolFlow
        state.dataLoopNodes.Node[AirInletNode - 1].MassFlowRateMax = dehumid.RatedAirMassFlow
        state.dataLoopNodes.Node[AirInletNode - 1].MassFlowRateMaxAvail = dehumid.RatedAirMassFlow
        state.dataLoopNodes.Node[AirInletNode - 1].MassFlowRateMinAvail = 0.0
        state.dataLoopNodes.Node[AirInletNode - 1].MassFlowRateMin = 0.0
        dehumid.MyEnvrnFlag = False
    if not state.dataGlobal.BeginEnvrnFlag:
        dehumid.MyEnvrnFlag = True
    state.dataLoopNodes.Node[AirInletNode - 1].MassFlowRate = dehumid.RatedAirMassFlow
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
    dehumid.OutletAirTemp = state.dataLoopNodes.Node[AirInletNode - 1].Temp

def CalcZoneDehumidifier(
    state: EnergyPlusData,
    ZoneDehumNum: Int,
    QZnDehumidReq: Float64,
    SensibleOutput: Float64,
    LatentOutput: Float64
):
    var RoutineName: String = "CalcZoneDehumidifier"
    var WaterRemovalRateFactor: Float64
    var WaterRemovalVolRate: Float64
    var WaterRemovalMassRate: Float64
    var EnergyFactorAdjFactor: Float64
    var EnergyFactor: Float64
    var InletAirTemp: Float64
    var InletAirHumRat: Float64
    var InletAirRH: Float64
    var OutletAirTemp: Float64
    var OutletAirHumRat: Float64
    var PLR: Float64
    var PLF: Float64
    var RunTimeFraction: Float64
    var ElectricPowerOnCycle: Float64
    var ElectricPowerAvg: Float64
    var hfg: Float64
    var AirMassFlowRate: Float64
    var Cp: Float64
    var AirInletNodeNum: Int = 0
    var dehumid = state.dataZoneDehumidifier.ZoneDehumid[ZoneDehumNum - 1]
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
    InletAirTemp = state.dataLoopNodes.Node[AirInletNodeNum - 1].Temp
    InletAirHumRat = state.dataLoopNodes.Node[AirInletNodeNum - 1].HumRat
    InletAirRH = 100.0 * Psychrometrics.PsyRhFnTdbWPb(state, InletAirTemp, InletAirHumRat, state.dataEnvrn.OutBaroPress, RoutineName)
    if QZnDehumidReq < 0.0 and dehumid.availSched.getCurrentVal() > 0.0 and InletAirTemp >= dehumid.MinInletAirTemp and InletAirTemp <= dehumid.MaxInletAirTemp:
        WaterRemovalRateFactor = dehumid.WaterRemovalCurve.value(state, InletAirTemp, InletAirRH)
        if WaterRemovalRateFactor <= 0.0:
            if dehumid.WaterRemovalCurveErrorCount < 1:
                dehumid.WaterRemovalCurveErrorCount += 1
                ShowWarningError(state, "{} \"{}\":".format(dehumid.UnitType, dehumid.Name))
                ShowContinueError(state, " Water Removal Rate Curve output is <= 0.0 ({:.5f}).".format(WaterRemovalRateFactor))
                ShowContinueError(
                    state,
                    " Negative value occurs using an inlet air dry-bulb temperature of {:.2f} and an inlet air relative humidity of {:.1f}.".format(
                        InletAirTemp, InletAirRH
                    )
                )
                ShowContinueErrorTimeStamp(state, " Dehumidifier turned off for this time step but simulation continues.")
            else:
                ShowRecurringWarningErrorAtEnd(
                    state,
                    dehumid.UnitType + " \"" + dehumid.Name + "\": Water Removal Rate Curve output is <= 0.0 warning continues...",
                    dehumid.WaterRemovalCurveErrorIndex,
                    WaterRemovalRateFactor,
                    WaterRemovalRateFactor
                )
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
                ShowWarningError(state, "{} \"{}\":".format(dehumid.UnitType, dehumid.Name))
                ShowContinueError(state, " Energy Factor Curve output is <= 0.0 ({:.5f}).".format(EnergyFactorAdjFactor))
                ShowContinueError(
                    state,
                    " Negative value occurs using an inlet air dry-bulb temperature of {:.2f} and an inlet air relative humidity of {:.1f}.".format(
                        InletAirTemp, InletAirRH
                    )
                )
                ShowContinueErrorTimeStamp(state, " Dehumidifier turned off for this time step but simulation continues.")
            else:
                ShowRecurringWarningErrorAtEnd(
                    state,
                    dehumid.UnitType + " \"" + dehumid.Name + "\": Energy Factor Curve output is <= 0.0 warning continues...",
                    dehumid.EnergyFactorCurveErrorIndex,
                    EnergyFactorAdjFactor,
                    EnergyFactorAdjFactor
                )
            ElectricPowerAvg = 0.0
            PLR = 0.0
            RunTimeFraction = 0.0
        else:
            EnergyFactor = EnergyFactorAdjFactor * dehumid.RatedEnergyFactor
            if dehumid.PartLoadCurve != None:
                PLF = dehumid.PartLoadCurve.value(state, PLR)
            else:
                PLF = 1.0
            if PLF < 0.7:
                if dehumid.LowPLFErrorCount < 1:
                    dehumid.LowPLFErrorCount += 1
                    ShowWarningError(state, "{} \"{}\":".format(dehumid.UnitType, dehumid.Name))
                    ShowContinueError(
                        state,
                        " The Part Load Fraction Correlation Curve output is ({:.2f}) at a part-load ratio ={:.3f}".format(PLF, PLR)
                    )
                    ShowContinueErrorTimeStamp(state, " PLF curve values must be >= 0.7.  PLF has been reset to 0.7 and simulation is continuing.")
                else:
                    ShowRecurringWarningErrorAtEnd(
                        state,
                        dehumid.UnitType + " \"" + dehumid.Name + "\": Part Load Fraction Correlation Curve output < 0.7 warning continues...",
                        dehumid.LowPLFErrorIndex,
                        PLF,
                        PLF
                    )
                PLF = 0.7
            if PLF > 1.0:
                if dehumid.HighPLFErrorCount < 1:
                    dehumid.HighPLFErrorCount += 1
                    ShowWarningError(state, "{} \"{}\":".format(dehumid.UnitType, dehumid.Name))
                    ShowContinueError(
                        state,
                        " The Part Load Fraction Correlation Curve output is ({:.2f}) at a part-load ratio ={:.3f}".format(PLF, PLR)
                    )
                    ShowContinueErrorTimeStamp(state, " PLF curve values must be < 1.0.  PLF has been reset to 1.0 and simulation is continuing.")
                else:
                    ShowRecurringWarningErrorAtEnd(
                        state,
                        "{} \"{}\": Part Load Fraction Correlation Curve output > 1.0 warning continues...".format(dehumid.UnitType, dehumid.Name),
                        dehumid.HighPLFErrorIndex,
                        PLF,
                        PLF
                    )
                PLF = 1.0
            if PLF > 0.0 and PLF >= PLR:
                RunTimeFraction = PLR / PLF
            else:
                if dehumid.PLFPLRErrorCount < 1:
                    dehumid.PLFPLRErrorCount += 1
                    ShowWarningError(state, "{} \"{}\":".format(dehumid.UnitType, dehumid.Name))
                    ShowContinueError(
                        state,
                        "The part load fraction was less than the part load ratio calculated for this time step [PLR={:.4f}, PLF={:.4f}].".format(PLR, PLF)
                    )
                    ShowContinueError(state, "Runtime fraction reset to 1 and the simulation will continue.")
                    ShowContinueErrorTimeStamp(state, "")
                else:
                    ShowRecurringWarningErrorAtEnd(
                        state,
                        dehumid.UnitType + " \"" + dehumid.Name + "\": Part load fraction less than part load ratio warning continues...",
                        dehumid.PLFPLRErrorIndex
                    )
                RunTimeFraction = 1.0
            if RunTimeFraction > 1.0 and abs(RunTimeFraction - 1.0) > 0.001:
                if dehumid.HighRTFErrorCount < 1:
                    dehumid.HighRTFErrorCount += 1
                    ShowWarningError(state, "{} \"{}\":".format(dehumid.UnitType, dehumid.Name))
                    ShowContinueError(state, "The runtime fraction for this zone dehumidifier exceeded 1.0 [{:.4f}].".format(RunTimeFraction))
                    ShowContinueError(state, "Runtime fraction reset to 1 and the simulation will continue.")
                    ShowContinueErrorTimeStamp(state, "")
                else:
                    ShowRecurringWarningErrorAtEnd(
                        state,
                        dehumid.UnitType + " \"" + dehumid.Name + "\": Runtime fraction for zone dehumidifier exceeded 1.0 warning continues...",
                        dehumid.HighRTFErrorIndex,
                        RunTimeFraction,
                        RunTimeFraction
                    )
                RunTimeFraction = 1.0
            ElectricPowerOnCycle = WaterRemovalVolRate / (EnergyFactor * 24.0) * 1000.0
            ElectricPowerAvg = ElectricPowerOnCycle * RunTimeFraction + (1.0 - RunTimeFraction) * dehumid.OffCycleParasiticLoad
        LatentOutput = WaterRemovalMassRate * PLR
        hfg = Psychrometrics.PsyHfgAirFnWTdb(InletAirHumRat, InletAirTemp)
        SensibleOutput = (LatentOutput * hfg) + ElectricPowerAvg
        state.dataLoopNodes.Node[AirInletNodeNum - 1].MassFlowRate = dehumid.RatedAirMassFlow * PLR
        AirMassFlowRate = state.dataLoopNodes.Node[AirInletNodeNum - 1].MassFlowRate
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
        state.dataLoopNodes.Node[AirInletNodeNum - 1].MassFlowRate = 0.0
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

def UpdateZoneDehumidifier(state: EnergyPlusData, ZoneDehumNum: Int):
    var dehumid = state.dataZoneDehumidifier.ZoneDehumid[ZoneDehumNum - 1]
    var airInletNode = state.dataLoopNodes.Node[dehumid.AirInletNodeNum - 1]
    var airOutletNode = state.dataLoopNodes.Node[dehumid.AirOutletNodeNum - 1]
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

def ReportZoneDehumidifier(state: EnergyPlusData, DehumidNum: Int):
    var TimeStepSysSec: Float64 = state.dataHVACGlobal.TimeStepSysSec
    var dehumid = state.dataZoneDehumidifier.ZoneDehumid[DehumidNum - 1]
    dehumid.SensHeatingEnergy = dehumid.SensHeatingRate * TimeStepSysSec
    dehumid.WaterRemoved = dehumid.WaterRemovalRate * TimeStepSysSec
    dehumid.ElecConsumption = dehumid.ElecPower * TimeStepSysSec
    dehumid.OffCycleParasiticElecCons = dehumid.OffCycleParasiticElecPower * TimeStepSysSec
    if dehumid.CondensateCollectMode == CondensateOutlet.ToTank:
        var AirInletNodeNum: Int = dehumid.AirInletNodeNum
        var InletAirTemp: Float64 = state.dataLoopNodes.Node[AirInletNodeNum - 1].Temp
        var OutletAirTemp: Float64 = max((InletAirTemp - 11.0), 1.0)
        var RhoWater: Float64 = Psychrometrics.RhoH2O(OutletAirTemp)
        if RhoWater > 0.0:
            dehumid.DehumidCondVolFlowRate = dehumid.WaterRemovalRate / RhoWater
        dehumid.DehumidCondVol = dehumid.DehumidCondVolFlowRate * TimeStepSysSec
        state.dataWaterData.WaterStorage[dehumid.CondensateTankID - 1].VdotAvailSupply[dehumid.CondensateTankSupplyARRID - 1] = dehumid.DehumidCondVolFlowRate
        state.dataWaterData.WaterStorage[dehumid.CondensateTankID - 1].TwaterSupply[dehumid.CondensateTankSupplyARRID - 1] = OutletAirTemp

def GetZoneDehumidifierNodeNumber(state: EnergyPlusData, NodeNumber: Int) -> Bool:
    var FindZoneDehumidifierNodeNumber: Bool
    if state.dataZoneDehumidifier.GetInputFlag:
        GetZoneDehumidifierInput(state)
        state.dataZoneDehumidifier.GetInputFlag = False
    FindZoneDehumidifierNodeNumber = False
    for ZoneDehumidIndex in range(1, state.dataZoneDehumidifier.ZoneDehumid.size() + 1):
        if NodeNumber == state.dataZoneDehumidifier.ZoneDehumid[ZoneDehumidIndex - 1].AirInletNodeNum:
            FindZoneDehumidifierNodeNumber = True
            break
        if NodeNumber == state.dataZoneDehumidifier.ZoneDehumid[ZoneDehumidIndex - 1].AirOutletNodeNum:
            FindZoneDehumidifierNodeNumber = True
            break
    return FindZoneDehumidifierNodeNumber

def getZoneDehumidifierIndex(state: EnergyPlusData, CompName: String) -> Int:
    if state.dataZoneDehumidifier.GetInputFlag:
        GetZoneDehumidifierInput(state)
        state.dataZoneDehumidifier.GetInputFlag = False
    for ZoneDehumidNum in range(1, state.dataZoneDehumidifier.ZoneDehumid.size() + 1):
        if Util.SameString(state.dataZoneDehumidifier.ZoneDehumid[ZoneDehumidNum - 1].Name, CompName):
            return ZoneDehumidNum
    return 0

struct ZoneDehumidifierData(BaseGlobalStruct):
    var GetInputFlag: Bool = True
    var ZoneDehumid: EPVector[ZoneDehumidifierParams] = EPVector[ZoneDehumidifierParams]()
    def init_constant_state(state: EnergyPlusData):

    def init_state(state: EnergyPlusData):

    def clear_state():
        new (self) ZoneDehumidifierData()