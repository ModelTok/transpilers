from Data.BaseData import BaseGlobalStruct
from EPVector import EPVector
from EnergyPlus import EnergyPlusData
from .Data.EnergyPlusData import EnergyPlusData
from DataHeatBalFanSys import DataHeatBalFanSys
from DataHeatBalance import DataHeatBalance
from OutputProcessor import SetupOutputVariable, OutputProcessor, Constant
from memory import memset_zero
from math import abs, min, max
@value
struct ZoneSystemDemandData:
    var RemainingOutputRequired: Float64 = 0.0
    var UnadjRemainingOutputRequired: Float64 = 0.0
    var TotalOutputRequired: Float64 = 0.0
    var NumZoneEquipment: Int = 0
    var SupplyAirAdjustFactor: Float64 = 1.0
    var StageNum: Int = 0
    def __del__(owned self):

    def beginEnvironmentInit(self):

    def setUpOutputVars(self, inout state: EnergyPlusData, prefix: StringLiteral, name: StringLiteral, staged: Bool, attachMeters: Bool, zoneMult: Int, listMult: Int):

@value
struct ZoneSystemSensibleDemand:
    var RemainingOutputRequired: Float64 = 0.0
    var UnadjRemainingOutputRequired: Float64 = 0.0
    var TotalOutputRequired: Float64 = 0.0
    var NumZoneEquipment: Int = 0
    var SupplyAirAdjustFactor: Float64 = 1.0
    var StageNum: Int = 0
    var OutputRequiredToHeatingSP: Float64 = 0.0
    var OutputRequiredToCoolingSP: Float64 = 0.0
    var RemainingOutputReqToHeatSP: Float64 = 0.0
    var RemainingOutputReqToCoolSP: Float64 = 0.0
    var UnadjRemainingOutputReqToHeatSP: Float64 = 0.0
    var UnadjRemainingOutputReqToCoolSP: Float64 = 0.0
    var SequencedOutputRequired: EPVector[Float64] = EPVector[Float64]()
    var SequencedOutputRequiredToHeatingSP: EPVector[Float64] = EPVector[Float64]()
    var SequencedOutputRequiredToCoolingSP: EPVector[Float64] = EPVector[Float64]()
    var predictedRate: Float64 = 0.0
    var predictedHSPRate: Float64 = 0.0
    var predictedCSPRate: Float64 = 0.0
    var airSysHeatRate: Float64 = 0.0
    var airSysCoolRate: Float64 = 0.0
    var airSysHeatEnergy: Float64 = 0.0
    var airSysCoolEnergy: Float64 = 0.0
    def beginEnvironmentInit(self):
        self.RemainingOutputRequired = 0.0
        self.TotalOutputRequired = 0.0
        if self.SequencedOutputRequired.allocated():
            for equipNum in range(1, self.NumZoneEquipment + 1):
                self.SequencedOutputRequired[equipNum - 1] = 0.0
                self.SequencedOutputRequiredToHeatingSP[equipNum - 1] = 0.0
                self.SequencedOutputRequiredToCoolingSP[equipNum - 1] = 0.0
        self.airSysHeatEnergy = 0.0
        self.airSysCoolEnergy = 0.0
        self.airSysHeatRate = 0.0
        self.airSysCoolRate = 0.0
        self.predictedRate = 0.0
        self.predictedHSPRate = 0.0
        self.predictedCSPRate = 0.0
    def setUpOutputVars(self, inout state: EnergyPlusData, prefix: StringLiteral, name: StringLiteral, staged: Bool, attachMeters: Bool, zoneMult: Int, listMult: Int):
        if attachMeters:
            SetupOutputVariable(state,
                "{} Air System Sensible Heating Energy".format(prefix),
                Constant.Units.J,
                self.airSysHeatEnergy,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Sum,
                name,
                Constant.eResource.EnergyTransfer,
                OutputProcessor.Group.Building,
                OutputProcessor.EndUseCat.Heating,
                "",
                name,
                zoneMult,
                listMult)
            SetupOutputVariable(state,
                "{} Air System Sensible Cooling Energy".format(prefix),
                Constant.Units.J,
                self.airSysCoolEnergy,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Sum,
                name,
                Constant.eResource.EnergyTransfer,
                OutputProcessor.Group.Building,
                OutputProcessor.EndUseCat.Cooling,
                "",
                name,
                zoneMult,
                listMult)
        else:
            SetupOutputVariable(state,
                "{} Air System Sensible Heating Energy".format(prefix),
                Constant.Units.J,
                self.airSysHeatEnergy,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Sum,
                name)
            SetupOutputVariable(state,
                "{} Air System Sensible Cooling Energy".format(prefix),
                Constant.Units.J,
                self.airSysCoolEnergy,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Sum,
                name)
        SetupOutputVariable(state,
            "{} Air System Sensible Heating Rate".format(prefix),
            Constant.Units.W,
            self.airSysHeatRate,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            name)
        SetupOutputVariable(state,
            "{} Air System Sensible Cooling Rate".format(prefix),
            Constant.Units.W,
            self.airSysCoolRate,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            name)
        SetupOutputVariable(state,
            "{} Predicted Sensible Load to Setpoint Heat Transfer Rate".format(prefix),
            Constant.Units.W,
            self.predictedRate,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            name)
        SetupOutputVariable(state,
            "{} Predicted Sensible Load to Heating Setpoint Heat Transfer Rate".format(prefix),
            Constant.Units.W,
            self.predictedHSPRate,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            name)
        SetupOutputVariable(state,
            "{} Predicted Sensible Load to Cooling Setpoint Heat Transfer Rate".format(prefix),
            Constant.Units.W,
            self.predictedCSPRate,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            name)
        SetupOutputVariable(state,
            "{} System Predicted Sensible Load to Setpoint Heat Transfer Rate".format(prefix),
            Constant.Units.W,
            self.TotalOutputRequired,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            name)
        SetupOutputVariable(state,
            "{} System Predicted Sensible Load to Heating Setpoint Heat Transfer Rate".format(prefix),
            Constant.Units.W,
            self.OutputRequiredToHeatingSP,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            name)
        SetupOutputVariable(state,
            "{} System Predicted Sensible Load to Cooling Setpoint Heat Transfer Rate".format(prefix),
            Constant.Units.W,
            self.OutputRequiredToCoolingSP,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            name)
        if staged:
            SetupOutputVariable(state,
                "{} Thermostat Staged Number".format(prefix),
                Constant.Units.None,
                self.StageNum,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                name)
    def reportZoneAirSystemSensibleLoads(self, inout state: EnergyPlusData, SNLoad: Float64):
        self.airSysHeatRate = max(SNLoad, 0.0)
        self.airSysCoolRate = abs(min(SNLoad, 0.0))
        self.airSysHeatEnergy = self.airSysHeatRate * state.dataHVACGlobal.TimeStepSysSec
        self.airSysCoolEnergy = self.airSysCoolRate * state.dataHVACGlobal.TimeStepSysSec
    def reportSensibleLoadsZoneMultiplier(self, inout state: EnergyPlusData, zoneNum: Int, totalLoad: Float64, loadToHeatingSetPoint: Float64, loadToCoolingSetPoint: Float64):
        var loadCorrFactor: Float64 = state.dataHeatBalFanSys.LoadCorrectionFactor[zoneNum - 1]
        self.predictedRate = totalLoad * loadCorrFactor
        self.predictedHSPRate = loadToHeatingSetPoint * loadCorrFactor
        self.predictedCSPRate = loadToCoolingSetPoint * loadCorrFactor
        var ZoneMultFac: Float64 = state.dataHeatBal.Zone[zoneNum - 1].Multiplier * state.dataHeatBal.Zone[zoneNum - 1].ListMultiplier
        self.TotalOutputRequired = self.predictedRate * ZoneMultFac
        self.OutputRequiredToHeatingSP = self.predictedHSPRate * ZoneMultFac
        self.OutputRequiredToCoolingSP = self.predictedCSPRate * ZoneMultFac
        if state.dataHeatBal.Zone[zoneNum - 1].IsControlled and self.NumZoneEquipment > 0:
            for equipNum in range(1, self.NumZoneEquipment + 1):
                self.SequencedOutputRequired[equipNum - 1] = self.TotalOutputRequired
                self.SequencedOutputRequiredToHeatingSP[equipNum - 1] = self.OutputRequiredToHeatingSP
                self.SequencedOutputRequiredToCoolingSP[equipNum - 1] = self.OutputRequiredToCoolingSP
@value
struct ZoneSystemMoistureDemand:
    var RemainingOutputRequired: Float64 = 0.0
    var UnadjRemainingOutputRequired: Float64 = 0.0
    var TotalOutputRequired: Float64 = 0.0
    var NumZoneEquipment: Int = 0
    var SupplyAirAdjustFactor: Float64 = 1.0
    var StageNum: Int = 0
    var OutputRequiredToHumidifyingSP: Float64 = 0.0
    var OutputRequiredToDehumidifyingSP: Float64 = 0.0
    var RemainingOutputReqToHumidSP: Float64 = 0.0
    var RemainingOutputReqToDehumidSP: Float64 = 0.0
    var UnadjRemainingOutputReqToHumidSP: Float64 = 0.0
    var UnadjRemainingOutputReqToDehumidSP: Float64 = 0.0
    var SequencedOutputRequired: EPVector[Float64] = EPVector[Float64]()
    var SequencedOutputRequiredToHumidSP: EPVector[Float64] = EPVector[Float64]()
    var SequencedOutputRequiredToDehumidSP: EPVector[Float64] = EPVector[Float64]()
    var predictedRate: Float64 = 0.0
    var predictedHumSPRate: Float64 = 0.0
    var predictedDehumSPRate: Float64 = 0.0
    var airSysHeatRate: Float64 = 0.0
    var airSysCoolRate: Float64 = 0.0
    var airSysHeatEnergy: Float64 = 0.0
    var airSysCoolEnergy: Float64 = 0.0
    var airSysSensibleHeatRatio: Float64 = 0.0
    var vaporPressureDifference: Float64 = 0.0
    def beginEnvironmentInit(self):
        self.RemainingOutputRequired = 0.0
        self.TotalOutputRequired = 0.0
        if self.SequencedOutputRequired.allocated():
            for equipNum in range(1, self.NumZoneEquipment + 1):
                self.SequencedOutputRequired[equipNum - 1] = 0.0
                self.SequencedOutputRequiredToHumidSP[equipNum - 1] = 0.0
                self.SequencedOutputRequiredToDehumidSP[equipNum - 1] = 0.0
        self.airSysHeatEnergy = 0.0
        self.airSysCoolEnergy = 0.0
        self.airSysHeatRate = 0.0
        self.airSysCoolRate = 0.0
        self.airSysSensibleHeatRatio = 0.0
        self.vaporPressureDifference = 0.0
        self.predictedRate = 0.0
        self.predictedHumSPRate = 0.0
        self.predictedDehumSPRate = 0.0
    def setUpOutputVars(self, inout state: EnergyPlusData, prefix: StringLiteral, name: StringLiteral, staged: Bool, attachMeters: Bool, zoneMult: Int, listMult: Int):
        if state.dataHeatBal.DoLatentSizing:
            SetupOutputVariable(state,
                "{} Air System Latent Heating Energy".format(prefix),
                Constant.Units.J,
                self.airSysHeatEnergy,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Sum,
                name)
            SetupOutputVariable(state,
                "{} Air System Latent Cooling Energy".format(prefix),
                Constant.Units.J,
                self.airSysCoolEnergy,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Sum,
                name)
            SetupOutputVariable(state,
                "{} Air System Latent Heating Rate".format(prefix),
                Constant.Units.W,
                self.airSysHeatRate,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                name)
            SetupOutputVariable(state,
                "{} Air System Latent Cooling Rate".format(prefix),
                Constant.Units.W,
                self.airSysCoolRate,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                name)
            SetupOutputVariable(state,
                "{} Air System Sensible Heat Ratio".format(prefix),
                Constant.Units.None,
                self.airSysSensibleHeatRatio,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                name)
            SetupOutputVariable(state,
                "{} Air Vapor Pressure Difference".format(prefix),
                Constant.Units.Pa,
                self.vaporPressureDifference,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                name)
        SetupOutputVariable(state,
            "{} Predicted Moisture Load Moisture Transfer Rate".format(prefix),
            Constant.Units.kgWater_s,
            self.predictedRate,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            name)
        SetupOutputVariable(state,
            "{} Predicted Moisture Load to Humidifying Setpoint Moisture Transfer Rate".format(prefix),
            Constant.Units.kgWater_s,
            self.predictedHumSPRate,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            name)
        SetupOutputVariable(state,
            "{} Predicted Moisture Load to Dehumidifying Setpoint Moisture Transfer Rate".format(prefix),
            Constant.Units.kgWater_s,
            self.predictedDehumSPRate,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            name)
        SetupOutputVariable(state,
            "{} System Predicted Moisture Load Moisture Transfer Rate".format(prefix),
            Constant.Units.kgWater_s,
            self.TotalOutputRequired,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            name)
        SetupOutputVariable(state,
            "{} System Predicted Moisture Load to Humidifying Setpoint Moisture Transfer Rate".format(prefix),
            Constant.Units.kgWater_s,
            self.OutputRequiredToHumidifyingSP,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            name)
        SetupOutputVariable(state,
            "{} System Predicted Moisture Load to Dehumidifying Setpoint Moisture Transfer Rate".format(prefix),
            Constant.Units.kgWater_s,
            self.OutputRequiredToDehumidifyingSP,
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            name)
    def reportZoneAirSystemMoistureLoads(self, inout state: EnergyPlusData, latentGain: Float64, sensibleLoad: Float64, vaporPressureDiff: Float64):
        self.airSysHeatRate = abs(min(latentGain, 0.0))
        self.airSysCoolRate = max(latentGain, 0.0)
        self.airSysHeatEnergy = self.airSysHeatRate * state.dataHVACGlobal.TimeStepSysSec
        self.airSysCoolEnergy = self.airSysCoolRate * state.dataHVACGlobal.TimeStepSysSec
        if (sensibleLoad + latentGain) != 0.0:
            self.airSysSensibleHeatRatio = sensibleLoad / (sensibleLoad + latentGain)
        elif sensibleLoad != 0.0:
            self.airSysSensibleHeatRatio = 1.0
        else:
            self.airSysSensibleHeatRatio = 0.0
        self.vaporPressureDifference = vaporPressureDiff
    def reportMoistLoadsZoneMultiplier(self, inout state: EnergyPlusData, zoneNum: Int, totalLoad: Float64, loadToHumidifySetPoint: Float64, loadToDehumidifySetPoint: Float64):
        self.predictedRate = totalLoad
        self.predictedHumSPRate = loadToHumidifySetPoint
        self.predictedDehumSPRate = loadToDehumidifySetPoint
        var zoneMultFac: Float64 = state.dataHeatBal.Zone[zoneNum - 1].Multiplier * state.dataHeatBal.Zone[zoneNum - 1].ListMultiplier
        self.TotalOutputRequired = totalLoad * zoneMultFac
        self.OutputRequiredToHumidifyingSP = loadToHumidifySetPoint * zoneMultFac
        self.OutputRequiredToDehumidifyingSP = loadToDehumidifySetPoint * zoneMultFac
        if state.dataHeatBal.Zone[zoneNum - 1].IsControlled and self.NumZoneEquipment > 0:
            for equipNum in range(1, self.NumZoneEquipment + 1):
                self.SequencedOutputRequired[equipNum - 1] = self.TotalOutputRequired
                self.SequencedOutputRequiredToHumidSP[equipNum - 1] = self.OutputRequiredToHumidifyingSP
                self.SequencedOutputRequiredToDehumidSP[equipNum - 1] = self.OutputRequiredToDehumidifyingSP
@value
struct DataZoneEnergyDemandsData(BaseGlobalStruct):
    var DeadBandOrSetback: Array1D_bool = Array1D_bool()
    var Setback: Array1D_bool = Array1D_bool()
    var CurDeadBandOrSetback: Array1D_bool = Array1D_bool()
    var ZoneSysEnergyDemand: EPVector[ZoneSystemSensibleDemand] = EPVector[ZoneSystemSensibleDemand]()
    var ZoneSysMoistureDemand: EPVector[ZoneSystemMoistureDemand] = EPVector[ZoneSystemMoistureDemand]()
    var spaceSysEnergyDemand: EPVector[ZoneSystemSensibleDemand] = EPVector[ZoneSystemSensibleDemand]()
    var spaceSysMoistureDemand: EPVector[ZoneSystemMoistureDemand] = EPVector[ZoneSystemMoistureDemand]()
    def init_constant_state(self, inout state: EnergyPlusData):

    def init_state(self, inout state: EnergyPlusData):

    def clear_state(self):
        self = DataZoneEnergyDemandsData()