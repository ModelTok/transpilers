from .Data.EnergyPlusData import EnergyPlusData, BaseGlobalStruct
from DataContaminantBalance import *
from DataEnvironment import *
from DataHeatBalance import *
from DataZoneEnergyDemands import *
from DataZoneEquipment import *
from Psychrometrics import *
from ScheduleManager import Sched
from SizingManager import *
from DataGlobals import *
from DataHVACGlobals import *  # for HVAC::FanOp etc.
from DataStringGlobals import *
from EPVector import EPVector, Array1D, Array2D  # assume these wrappers exist
from EnergyPlus import *
from Util import *

# ----------------------------------------------------------------------
# Enums
# ----------------------------------------------------------------------
enum OAFlowCalcMethod(Int32):
    Invalid = -1
    PerPerson = 0
    PerZone = 1
    PerArea = 2
    ACH = 3
    Sum = 4
    Max = 5
    IAQProcedure = 6
    PCOccSch = 7
    PCDesOcc = 8
    Num = 9

const OAFlowCalcMethodNames: StaticArray[String, 9] = [
    "Flow/Person", "Flow/Zone", "Flow/Area", "AirChanges/Hour",
    "Sum", "Maximum", "IndoorAirQualityProcedure",
    "ProportionalControlBasedOnOccupancySchedule",
    "ProportionalControlBasedOnDesignOccupancy"
]

enum OAControl(Int32):
    Invalid = -1
    AllOA = 0
    MinOA = 1
    Num = 2

enum TypeOfPlantLoop(Int32):
    Invalid = -1
    Heating = 0
    Cooling = 1
    Condenser = 2
    Steam = 3
    Num = 4

enum SizingConcurrence(Int32):
    Invalid = -1
    NonCoincident = 0
    Coincident = 1
    Num = 2

const SizingConcurrenceNamesUC: StaticArray[String, 2] = ["NONCOINCIDENT", "COINCIDENT"]
const SizingConcurrenceNames: StaticArray[String, 2] = ["NonCoincident", "Coincident"]

enum CoilSizingConcurrence(Int32):
    Invalid = -1
    NonCoincident = 0
    Coincident = 1
    Combination = 2
    NA = 3
    Num = 4

const CoilSizingConcurrenceNames: StaticArray[String, 4] = [
    "Non-Coincident", "Coincident", "Combination", "N/A"
]

enum PeakLoad(Int32):
    Invalid = -1
    SensibleCooling = 0
    TotalCooling = 1
    Num = 2

enum CapacityControl(Int32):
    Invalid = -1
    VAV = 0
    Bypass = 1
    VT = 2
    OnOff = 3
    Num = 4

const SupplyAirTemperature: Int32 = 1
const TemperatureDifference: Int32 = 2
const SupplyAirHumidityRatio: Int32 = 3
const HumidityRatioDifference: Int32 = 4

enum AirflowSizingMethod(Int32):
    Invalid = -1
    FromDDCalc = 0
    InpDesAirFlow = 1
    DesAirFlowWithLim = 2
    Num = 3

enum DOASControl(Int32):
    Invalid = -1
    NeutralSup = 0
    NeutralDehumSup = 1
    CoolSup = 2
    Num = 3

enum LoadSizing(Int32):
    Invalid = -1
    Sensible = 0
    Latent = 1
    Total = 2
    Ventilation = 3
    Num = 4

const AutoSize: Float64 = -99999.0
const PeakHrMinFmt: String = "{:02}:{:02}:00"

enum SysOAMethod(Int32):
    Invalid = -1
    ZoneSum = 0
    VRP = 1
    IAQP = 2
    ProportionalControlSchOcc = 3
    IAQPGC = 4
    IAQPCOM = 5
    ProportionalControlDesOcc = 6
    ProportionalControlDesOARate = 7
    SP = 8
    VRPL = 9
    Num = 10

const SysOAMethodNames: StaticArray[String, 10] = [
    "Zone Sum", "Ventilation Rate Procedure", "IAQ Proc",
    "Proportional - Sch Occupancy", "IAQ Proc - Generic Contaminant",
    "IAQ Proc - Max Gen Cont or CO2.", "Proportional - Des Occupancy",
    "Proportional - Des OA Rate", "Simplified Procure",
    "Ventilation Rate Procedure Level"
]

enum DesignSizingType(Int32):
    Invalid = -1
    Dummy1BasedOffset = 0
    None = 1
    SupplyAirFlowRate = 2
    FlowPerFloorArea = 3
    FractionOfAutosizedCoolingAirflow = 4
    FractionOfAutosizedHeatingAirflow = 5
    FlowPerCoolingCapacity = 6
    FlowPerHeatingCapacity = 7
    CoolingDesignCapacity = 8
    HeatingDesignCapacity = 9
    CapacityPerFloorArea = 10
    FractionOfAutosizedCoolingCapacity = 11
    FractionOfAutosizedHeatingCapacity = 12
    Num = 13

const DesignSizingTypeNamesUC: StaticArray[String, 13] = [
    "DUMMY1BASEDOFFSET", "NONE", "SUPPLYAIRFLOWRATE", "FLOWPERFLOORAREA",
    "FRACTIONOFAUTOSIZEDCOOLINGAIRFLOW", "FRACTIONOFAUTOSIZEDHEATINGAIRFLOW",
    "FLOWPERCOOLINGCAPACITY", "FLOWPERHEATINGCAPACITY",
    "COOLINGDESIGNCAPACITY", "HEATINGDESIGNCAPACITY",
    "CAPACITYPERFLOORAREA", "FRACTIONOFAUTOSIZEDCOOLINGCAPACITY",
    "FRACTIONOFAUTOSIZEDHEATINGCAPACITY"
]

const None: Int32 = 1
const SupplyAirFlowRate: Int32 = 2
const FlowPerFloorArea: Int32 = 3
const FractionOfAutosizedCoolingAirflow: Int32 = 4
const FractionOfAutosizedHeatingAirflow: Int32 = 5
const FlowPerCoolingCapacity: Int32 = 6
const FlowPerHeatingCapacity: Int32 = 7
const CoolingDesignCapacity: Int32 = 8
const HeatingDesignCapacity: Int32 = 9
const CapacityPerFloorArea: Int32 = 10
const FractionOfAutosizedCoolingCapacity: Int32 = 11
const FractionOfAutosizedHeatingCapacity: Int32 = 12
const NoSizingFactorMode: Int32 = 101
const GlobalHeatingSizingFactorMode: Int32 = 102
const GlobalCoolingSizingFactorMode: Int32 = 103
const LoopComponentSizingFactorMode: Int32 = 104

enum ZoneSizing(Int32):
    Invalid = -1
    Sensible = 0
    Latent = 1
    SensibleAndLatent = 2
    SensibleOnly = 3
    Num = 4

const ZoneSizingMethodNamesUC: StaticArray[String, 4] = [
    "SENSIBLE LOAD", "LATENT LOAD", "SENSIBLE AND LATENT LOAD",
    "SENSIBLE LOAD ONLY NO LATENT LOAD"
]

enum HeatCoilSizMethod(Int32):
    Invalid = -1
    None = 0
    CoolingCapacity = 1
    HeatingCapacity = 2
    GreaterOfHeatingOrCooling = 3
    Num = 4

const HeatCoilSizMethodNamesUC: StaticArray[String, 4] = [
    "NONE", "COOLINGCAPACITY", "HEATINGCAPACITY", "GREATEROFHEATINGORCOOLING"
]

# ----------------------------------------------------------------------
# Structs
# ----------------------------------------------------------------------
@value
struct ZoneSizingInputData:
    var ZoneName: String = ""
    var ZoneNum: Int32 = 0
    var ZnCoolDgnSAMethod: Int32 = 0
    var ZnHeatDgnSAMethod: Int32 = 0
    var CoolDesTemp: Float64 = 0.0
    var HeatDesTemp: Float64 = 0.0
    var CoolDesTempDiff: Float64 = 0.0
    var HeatDesTempDiff: Float64 = 0.0
    var CoolDesHumRat: Float64 = 0.0
    var HeatDesHumRat: Float64 = 0.0
    var DesignSpecOAObjName: String = ""
    var CoolAirDesMethod: AirflowSizingMethod = AirflowSizingMethod.Invalid
    var DesCoolAirFlow: Float64 = 0.0
    var DesCoolMinAirFlowPerArea: Float64 = 0.0
    var DesCoolMinAirFlow: Float64 = 0.0
    var DesCoolMinAirFlowFrac: Float64 = 0.0
    var HeatAirDesMethod: AirflowSizingMethod = AirflowSizingMethod.Invalid
    var DesHeatAirFlow: Float64 = 0.0
    var DesHeatMaxAirFlowPerArea: Float64 = 0.0
    var DesHeatMaxAirFlow: Float64 = 0.0
    var DesHeatMaxAirFlowFrac: Float64 = 0.0
    var HeatSizingFactor: Float64 = 0.0
    var CoolSizingFactor: Float64 = 0.0
    var ZoneADEffCooling: Float64 = 0.0
    var ZoneADEffHeating: Float64 = 0.0
    var ZoneAirDistEffObjName: String = ""
    var ZoneAirDistributionIndex: Int32 = 0
    var ZoneDesignSpecOAIndex: Int32 = 0
    var ZoneSecondaryRecirculation: Float64 = 0.0
    var ZoneVentilationEff: Float64 = 0.0
    var AccountForDOAS: Bool = False
    var DOASControlStrategy: DOASControl = DOASControl.Invalid
    var DOASLowSetpoint: Float64 = 0.0
    var DOASHighSetpoint: Float64 = 0.0
    var spaceConcurrence: SizingConcurrence = SizingConcurrence.Coincident
    var zoneLatentSizing: Bool = False
    var zoneRHDehumidifySetPoint: Float64 = 50.0
    var zoneRHHumidifySetPoint: Float64 = 50.0
    var LatentCoolDesHumRat: Float64 = 0.0
    var CoolDesHumRatDiff: Float64 = 0.005
    var LatentHeatDesHumRat: Float64 = 0.0
    var HeatDesHumRatDiff: Float64 = 0.005
    var ZnLatCoolDgnSAMethod: Int32 = 0
    var ZnLatHeatDgnSAMethod: Int32 = 0
    var zoneRHDehumidifySched: Optional[Sched.Schedule] = None
    var zoneRHHumidifySched: Optional[Sched.Schedule] = None
    var zoneSizingMethod: ZoneSizing = ZoneSizing.Invalid
    var heatCoilSizingMethod: HeatCoilSizMethod = HeatCoilSizMethod.Invalid
    var maxHeatCoilToCoolingLoadSizingRatio: Float64 = 0.0

@value
struct TermUnitZoneSizingCommonData:
    var ZoneName: String = ""
    var ADUName: String = ""
    var CoolDesTemp: Float64 = 0.0
    var HeatDesTemp: Float64 = 0.0
    var CoolDesHumRat: Float64 = 0.0
    var HeatDesHumRat: Float64 = 0.0
    var DesOAFlowPPer: Float64 = 0.0
    var DesOAFlowPerArea: Float64 = 0.0
    var DesCoolMinAirFlow: Float64 = 0.0
    var DesCoolMinAirFlowFrac: Float64 = 0.0
    var DesHeatMaxAirFlow: Float64 = 0.0
    var DesHeatMaxAirFlowFrac: Float64 = 0.0
    var ZoneNum: Int32 = 0
    var DesHeatMassFlow: Float64 = 0.0
    var DesHeatMassFlowNoOA: Float64 = 0.0
    var DesHeatOAFlowFrac: Float64 = 0.0
    var DesCoolMassFlow: Float64 = 0.0
    var DesCoolMassFlowNoOA: Float64 = 0.0
    var DesCoolOAFlowFrac: Float64 = 0.0
    var DesHeatLoad: Float64 = 0.0
    var NonAirSysDesHeatLoad: Float64 = 0.0
    var DesCoolLoad: Float64 = 0.0
    var NonAirSysDesCoolLoad: Float64 = 0.0
    var DesHeatVolFlow: Float64 = 0.0
    var DesHeatVolFlowNoOA: Float64 = 0.0
    var NonAirSysDesHeatVolFlow: Float64 = 0.0
    var DesCoolVolFlow: Float64 = 0.0
    var DesCoolVolFlowNoOA: Float64 = 0.0
    var NonAirSysDesCoolVolFlow: Float64 = 0.0
    var DesHeatVolFlowMax: Float64 = 0.0
    var DesCoolVolFlowMin: Float64 = 0.0
    var DesHeatCoilInTempTU: Float64 = 0.0
    var DesCoolCoilInTempTU: Float64 = 0.0
    var DesHeatCoilInHumRatTU: Float64 = 0.0
    var DesCoolCoilInHumRatTU: Float64 = 0.0
    var ZoneTempAtHeatPeak: Float64 = 0.0
    var ZoneRetTempAtHeatPeak: Float64 = 0.0
    var ZoneTempAtCoolPeak: Float64 = 0.0
    var ZoneRetTempAtCoolPeak: Float64 = 0.0
    var ZoneHumRatAtHeatPeak: Float64 = 0.0
    var ZoneHumRatAtCoolPeak: Float64 = 0.0
    var TimeStepNumAtHeatMax: Int32 = 0
    var TimeStepNumAtCoolMax: Int32 = 0
    var HeatDDNum: Int32 = 0
    var CoolDDNum: Int32 = 0
    var MinOA: Float64 = 0.0
    var DesCoolMinAirFlow2: Float64 = 0.0
    var DesHeatMaxAirFlow2: Float64 = 0.0
    var HeatFlowSeq: Array1D[Float64] = Array1D[Float64]()
    var HeatFlowSeqNoOA: Array1D[Float64] = Array1D[Float64]()
    var CoolFlowSeq: Array1D[Float64] = Array1D[Float64]()
    var CoolFlowSeqNoOA: Array1D[Float64] = Array1D[Float64]()
    var HeatZoneTempSeq: EPVector[Float64] = EPVector[Float64]()
    var HeatZoneRetTempSeq: Array1D[Float64] = Array1D[Float64]()
    var CoolZoneTempSeq: EPVector[Float64] = EPVector[Float64]()
    var CoolZoneRetTempSeq: Array1D[Float64] = Array1D[Float64]()
    var ZoneADEffCooling: Float64 = 1.0
    var ZoneADEffHeating: Float64 = 1.0
    var ZoneSecondaryRecirculation: Float64 = 0.0
    var ZoneVentilationEff: Float64 = 0.0
    var ZonePrimaryAirFraction: Float64 = 0.0
    var ZonePrimaryAirFractionHtg: Float64 = 0.0
    var ZoneOAFracCooling: Float64 = 0.0
    var ZoneOAFracHeating: Float64 = 0.0
    var TotalOAFromPeople: Float64 = 0.0
    var TotalOAFromArea: Float64 = 0.0
    var TotPeopleInZone: Float64 = 0.0
    var TotalZoneFloorArea: Float64 = 0.0
    var SupplyAirAdjustFactor: Float64 = 1.0
    var ZpzClgByZone: Float64 = 0.0
    var ZpzHtgByZone: Float64 = 0.0
    var VozClgByZone: Float64 = 0.0
    var VozHtgByZone: Float64 = 0.0
    var VpzMinByZoneSPSized: Bool = False
    var ZoneSizThermSetPtHi: Float64 = 0.0
    var ZoneSizThermSetPtLo: Float64 = 1000.0

@value
struct ZoneSizingData(TermUnitZoneSizingCommonData):
    var CoolDesDay: String = ""
    var HeatDesDay: String = ""
    var ZnCoolDgnSAMethod: Int32 = 0
    var ZnHeatDgnSAMethod: Int32 = 0
    var CoolDesTempDiff: Float64 = 0.0
    var HeatDesTempDiff: Float64 = 0.0
    var ZoneAirDistributionIndex: Int32 = 0
    var ZoneDesignSpecOAIndex: Int32 = 0
    var CoolAirDesMethod: AirflowSizingMethod = AirflowSizingMethod.Invalid
    var InpDesCoolAirFlow: Float64 = 0.0
    var DesCoolMinAirFlowPerArea: Float64 = 0.0
    var HeatAirDesMethod: AirflowSizingMethod = AirflowSizingMethod.Invalid
    var InpDesHeatAirFlow: Float64 = 0.0
    var DesHeatMaxAirFlowPerArea: Float64 = 0.0
    var HeatSizingFactor: Float64 = 0.0
    var CoolSizingFactor: Float64 = 0.0
    var AccountForDOAS: Bool = False
    var DOASControlStrategy: DOASControl = DOASControl.Invalid
    var DOASLowSetpoint: Float64 = 0.0
    var DOASHighSetpoint: Float64 = 0.0
    var spaceConcurrence: SizingConcurrence = SizingConcurrence.Coincident
    var EMSOverrideDesHeatMassOn: Bool = False
    var EMSValueDesHeatMassFlow: Float64 = 0.0
    var EMSOverrideDesCoolMassOn: Bool = False
    var EMSValueDesCoolMassFlow: Float64 = 0.0
    var EMSOverrideDesHeatLoadOn: Bool = False
    var EMSValueDesHeatLoad: Float64 = 0.0
    var EMSOverrideDesCoolLoadOn: Bool = False
    var EMSValueDesCoolLoad: Float64 = 0.0
    var DesHeatDens: Float64 = 0.0
    var DesCoolDens: Float64 = 0.0
    var EMSOverrideDesHeatVolOn: Bool = False
    var EMSValueDesHeatVolFlow: Float64 = 0.0
    var EMSOverrideDesCoolVolOn: Bool = False
    var EMSValueDesCoolVolFlow: Float64 = 0.0
    var DesHeatCoilInTemp: Float64 = 0.0
    var DesCoolCoilInTemp: Float64 = 0.0
    var DesHeatCoilInHumRat: Float64 = 0.0
    var DesCoolCoilInHumRat: Float64 = 0.0
    var HeatMassFlow: Float64 = 0.0
    var CoolMassFlow: Float64 = 0.0
    var HeatLoad: Float64 = 0.0
    var CoolLoad: Float64 = 0.0
    var HeatZoneTemp: Float64 = 0.0
    var HeatOutTemp: Float64 = 0.0
    var HeatMCPI: Float64 = 0.0
    var HeatMCPV: Float64 = 0.0
    var HeatZoneRetTemp: Float64 = 0.0
    var HeatTstatTemp: Float64 = 0.0
    var CoolZoneTemp: Float64 = 0.0
    var CoolOutTemp: Float64 = 0.0
    var CoolZoneRetTemp: Float64 = 0.0
    var CoolTstatTemp: Float64 = 0.0
    var HeatZoneHumRat: Float64 = 0.0
    var CoolZoneHumRat: Float64 = 0.0
    var HeatOutHumRat: Float64 = 0.0
    var CoolOutHumRat: Float64 = 0.0
    var OutTempAtHeatPeak: Float64 = 0.0
    var MCPIAtHeatPeak: Float64 = 0.0
    var MCPVAtHeatPeak: Float64 = 0.0
    var OutTempAtCoolPeak: Float64 = 0.0
    var OutHumRatAtHeatPeak: Float64 = 0.0
    var OutHumRatAtCoolPeak: Float64 = 0.0
    var cHeatDDDate: String = ""
    var cCoolDDDate: String = ""
    var HeatLoadSeq: Array1D[Float64] = Array1D[Float64]()
    var CoolLoadSeq: Array1D[Float64] = Array1D[Float64]()
    var HeatOutTempSeq: Array1D[Float64] = Array1D[Float64]()
    var HeatMCPISeq: Array1D[Float64] = Array1D[Float64]()
    var HeatMCPVSeq: Array1D[Float64] = Array1D[Float64]()
    var HeatTstatTempSeq: Array1D[Float64] = Array1D[Float64]()
    var DesHeatSetPtSeq: Array1D[Float64] = Array1D[Float64]()
    var CoolOutTempSeq: Array1D[Float64] = Array1D[Float64]()
    var CoolTstatTempSeq: Array1D[Float64] = Array1D[Float64]()
    var DesCoolSetPtSeq: Array1D[Float64] = Array1D[Float64]()
    var HeatZoneHumRatSeq: Array1D[Float64] = Array1D[Float64]()
    var CoolZoneHumRatSeq: Array1D[Float64] = Array1D[Float64]()
    var HeatOutHumRatSeq: Array1D[Float64] = Array1D[Float64]()
    var CoolOutHumRatSeq: Array1D[Float64] = Array1D[Float64]()
    var ZonePeakOccupancy: Float64 = 0.0
    var DOASHeatLoad: Float64 = 0.0
    var DOASCoolLoad: Float64 = 0.0
    var DOASHeatAdd: Float64 = 0.0
    var DOASLatAdd: Float64 = 0.0
    var DOASSupMassFlow: Float64 = 0.0
    var DOASSupTemp: Float64 = 0.0
    var DOASSupHumRat: Float64 = 0.0
    var DOASTotCoolLoad: Float64 = 0.0
    var DOASHeatLoadSeq: Array1D[Float64] = Array1D[Float64]()
    var DOASCoolLoadSeq: Array1D[Float64] = Array1D[Float64]()
    var DOASHeatAddSeq: Array1D[Float64] = Array1D[Float64]()
    var DOASLatAddSeq: Array1D[Float64] = Array1D[Float64]()
    var DOASSupMassFlowSeq: Array1D[Float64] = Array1D[Float64]()
    var DOASSupTempSeq: Array1D[Float64] = Array1D[Float64]()
    var DOASSupHumRatSeq: Array1D[Float64] = Array1D[Float64]()
    var DOASTotCoolLoadSeq: Array1D[Float64] = Array1D[Float64]()
    var HeatLoadNoDOAS: Float64 = 0.0
    var CoolLoadNoDOAS: Float64 = 0.0
    var DesHeatLoadNoDOAS: Float64 = 0.0
    var DesCoolLoadNoDOAS: Float64 = 0.0
    var HeatLatentLoad: Float64 = 0.0
    var CoolLatentLoad: Float64 = 0.0
    var HeatLatentLoadNoDOAS: Float64 = 0.0
    var CoolLatentLoadNoDOAS: Float64 = 0.0
    var ZoneHeatLatentMassFlow: Float64 = 0.0
    var ZoneCoolLatentMassFlow: Float64 = 0.0
    var ZoneHeatLatentVolFlow: Float64 = 0.0
    var ZoneCoolLatentVolFlow: Float64 = 0.0
    var DesLatentHeatLoad: Float64 = 0.0
    var DesLatentCoolLoad: Float64 = 0.0
    var DesLatentHeatLoadNoDOAS: Float64 = 0.0
    var DesLatentCoolLoadNoDOAS: Float64 = 0.0
    var DesLatentHeatMassFlow: Float64 = 0.0
    var DesLatentCoolMassFlow: Float64 = 0.0
    var DesLatentHeatVolFlow: Float64 = 0.0
    var DesLatentCoolVolFlow: Float64 = 0.0
    var ZoneTempAtLatentCoolPeak: Float64 = 0.0
    var OutTempAtLatentCoolPeak: Float64 = 0.0
    var ZoneHumRatAtLatentCoolPeak: Float64 = 0.0
    var OutHumRatAtLatentCoolPeak: Float64 = 0.0
    var ZoneTempAtLatentHeatPeak: Float64 = 0.0
    var OutTempAtLatentHeatPeak: Float64 = 0.0
    var ZoneHumRatAtLatentHeatPeak: Float64 = 0.0
    var OutHumRatAtLatentHeatPeak: Float64 = 0.0
    var DesLatentHeatCoilInTemp: Float64 = 0.0
    var DesLatentCoolCoilInTemp: Float64 = 0.0
    var DesLatentHeatCoilInHumRat: Float64 = 0.0
    var DesLatentCoolCoilInHumRat: Float64 = 0.0
    var TimeStepNumAtLatentHeatMax: Int32 = 0
    var TimeStepNumAtLatentCoolMax: Int32 = 0
    var TimeStepNumAtLatentHeatNoDOASMax: Int32 = 0
    var TimeStepNumAtLatentCoolNoDOASMax: Int32 = 0
    var LatentHeatDDNum: Int32 = 0
    var LatentCoolDDNum: Int32 = 0
    var LatentHeatNoDOASDDNum: Int32 = 0
    var LatentCoolNoDOASDDNum: Int32 = 0
    var cLatentHeatDDDate: String = ""
    var cLatentCoolDDDate: String = ""
    var TimeStepNumAtHeatNoDOASMax: Int32 = 0
    var TimeStepNumAtCoolNoDOASMax: Int32 = 0
    var HeatNoDOASDDNum: Int32 = 0
    var CoolNoDOASDDNum: Int32 = 0
    var cHeatNoDOASDDDate: String = ""
    var cCoolNoDOASDDDate: String = ""
    var HeatLoadNoDOASSeq: Array1D[Float64] = Array1D[Float64]()
    var CoolLoadNoDOASSeq: Array1D[Float64] = Array1D[Float64]()
    var LatentHeatLoadSeq: Array1D[Float64] = Array1D[Float64]()
    var LatentCoolLoadSeq: Array1D[Float64] = Array1D[Float64]()
    var HeatLatentLoadNoDOASSeq: Array1D[Float64] = Array1D[Float64]()
    var CoolLatentLoadNoDOASSeq: Array1D[Float64] = Array1D[Float64]()
    var LatentCoolFlowSeq: Array1D[Float64] = Array1D[Float64]()
    var LatentHeatFlowSeq: Array1D[Float64] = Array1D[Float64]()
    var zoneLatentSizing: Bool = False
    var zoneRHDehumidifySetPoint: Float64 = 50.0
    var zoneRHDehumidifySched: Optional[Sched.Schedule] = None
    var zoneRHHumidifySetPoint: Float64 = 50.0
    var zoneRHHumidifySched: Optional[Sched.Schedule] = None
    var LatentCoolDesHumRat: Float64 = 0.0
    var CoolDesHumRatDiff: Float64 = 0.005
    var LatentHeatDesHumRat: Float64 = 0.0
    var HeatDesHumRatDiff: Float64 = 0.005
    var ZnLatCoolDgnSAMethod: Int32 = 0
    var ZnLatHeatDgnSAMethod: Int32 = 0
    var ZoneRetTempAtLatentCoolPeak: Float64 = 0.0
    var ZoneRetTempAtLatentHeatPeak: Float64 = 0.0
    var CoolNoDOASDesDay: String = ""
    var HeatNoDOASDesDay: String = ""
    var LatCoolDesDay: String = ""
    var LatHeatDesDay: String = ""
    var LatCoolNoDOASDesDay: String = ""
    var LatHeatNoDOASDesDay: String = ""
    var zoneSizingMethod: ZoneSizing = ZoneSizing.Invalid
    var CoolSizingType: String = ""
    var HeatSizingType: String = ""
    var CoolPeakDateHrMin: String = ""
    var HeatPeakDateHrMin: String = ""
    var LatCoolPeakDateHrMin: String = ""
    var LatHeatPeakDateHrMin: String = ""
    var heatCoilSizingMethod: HeatCoilSizMethod = HeatCoilSizMethod.Invalid
    var maxHeatCoilToCoolingLoadSizingRatio: Float64 = 0.0

# Methods for ZoneSizingData
def ZoneSizingData.zeroMemberData(self):
    if not allocated(self.DOASSupMassFlowSeq):
        return
    # Fill arrays with 0.0
    fill(self.DOASSupMassFlowSeq, 0.0)
    fill(self.DOASHeatLoadSeq, 0.0)
    fill(self.DOASCoolLoadSeq, 0.0)
    fill(self.DOASHeatAddSeq, 0.0)
    fill(self.DOASLatAddSeq, 0.0)
    fill(self.DOASSupTempSeq, 0.0)
    fill(self.DOASSupHumRatSeq, 0.0)
    fill(self.DOASTotCoolLoadSeq, 0.0)
    fill(self.HeatFlowSeq, 0.0)
    fill(self.HeatFlowSeqNoOA, 0.0)
    fill(self.HeatLoadSeq, 0.0)
    fill(self.HeatZoneTempSeq, 0.0)
    fill(self.DesHeatSetPtSeq, 0.0)
    fill(self.HeatOutTempSeq, 0.0)
    fill(self.HeatMCPISeq, 0.0)
    fill(self.HeatMCPVSeq, 0.0)
    fill(self.HeatZoneRetTempSeq, 0.0)
    fill(self.HeatTstatTempSeq, 0.0)
    fill(self.HeatZoneHumRatSeq, 0.0)
    fill(self.HeatOutHumRatSeq, 0.0)
    fill(self.CoolFlowSeq, 0.0)
    fill(self.CoolFlowSeqNoOA, 0.0)
    fill(self.CoolLoadSeq, 0.0)
    fill(self.CoolZoneTempSeq, 0.0)
    fill(self.DesCoolSetPtSeq, 0.0)
    fill(self.CoolOutTempSeq, 0.0)
    fill(self.CoolZoneRetTempSeq, 0.0)
    fill(self.CoolTstatTempSeq, 0.0)
    fill(self.CoolZoneHumRatSeq, 0.0)
    fill(self.CoolOutHumRatSeq, 0.0)
    fill(self.HeatLoadNoDOASSeq, 0.0)
    fill(self.CoolLoadNoDOASSeq, 0.0)
    fill(self.LatentHeatLoadSeq, 0.0)
    fill(self.LatentCoolLoadSeq, 0.0)
    fill(self.HeatLatentLoadNoDOASSeq, 0.0)
    fill(self.CoolLatentLoadNoDOASSeq, 0.0)
    fill(self.LatentCoolFlowSeq, 0.0)
    fill(self.LatentHeatFlowSeq, 0.0)
    # Reset string and scalar members
    self.CoolDesDay = ""
    self.HeatDesDay = ""
    self.CoolNoDOASDesDay = ""
    self.HeatNoDOASDesDay = ""
    self.LatCoolDesDay = ""
    self.LatHeatDesDay = ""
    self.LatCoolNoDOASDesDay = ""
    self.LatHeatNoDOASDesDay = ""
    self.DesHeatMassFlow = 0.0
    self.DesCoolMassFlow = 0.0
    self.DesHeatLoad = 0.0
    self.DesCoolLoad = 0.0
    self.DesHeatDens = 0.0
    self.DesCoolDens = 0.0
    self.DesHeatVolFlow = 0.0
    self.DesCoolVolFlow = 0.0
    self.DesHeatVolFlowMax = 0.0
    self.DesCoolVolFlowMin = 0.0
    self.DesHeatCoilInTemp = 0.0
    self.DesCoolCoilInTemp = 0.0
    self.DesHeatCoilInHumRat = 0.0
    self.DesCoolCoilInHumRat = 0.0
    self.DesHeatCoilInTempTU = 0.0
    self.DesCoolCoilInTempTU = 0.0
    self.DesHeatCoilInHumRatTU = 0.0
    self.DesCoolCoilInHumRatTU = 0.0
    self.HeatMassFlow = 0.0
    self.CoolMassFlow = 0.0
    self.HeatLoad = 0.0
    self.CoolLoad = 0.0
    self.HeatZoneTemp = 0.0
    self.HeatOutTemp = 0.0
    self.HeatZoneRetTemp = 0.0
    self.HeatTstatTemp = 0.0
    self.CoolZoneTemp = 0.0
    self.CoolOutTemp = 0.0
    self.CoolZoneRetTemp = 0.0
    self.CoolTstatTemp = 0.0
    self.HeatZoneHumRat = 0.0
    self.CoolZoneHumRat = 0.0
    self.HeatOutHumRat = 0.0
    self.CoolOutHumRat = 0.0
    self.ZoneTempAtHeatPeak = 0.0
    self.ZoneRetTempAtHeatPeak = 0.0
    self.OutTempAtHeatPeak = 0.0
    self.ZoneTempAtCoolPeak = 0.0
    self.ZoneRetTempAtCoolPeak = 0.0
    self.OutTempAtCoolPeak = 0.0
    self.ZoneHumRatAtHeatPeak = 0.0
    self.ZoneHumRatAtCoolPeak = 0.0
    self.OutHumRatAtHeatPeak = 0.0
    self.OutHumRatAtCoolPeak = 0.0
    self.TimeStepNumAtHeatMax = 0
    self.TimeStepNumAtCoolMax = 0
    self.HeatDDNum = 0
    self.CoolDDNum = 0
    self.LatentHeatDDNum = 0
    self.LatentCoolDDNum = 0
    self.LatentHeatNoDOASDDNum = 0
    self.LatentCoolNoDOASDDNum = 0
    self.cHeatDDDate = ""
    self.cCoolDDDate = ""
    self.cLatentHeatDDDate = ""
    self.cLatentCoolDDDate = ""
    self.DOASHeatLoad = 0.0
    self.DOASCoolLoad = 0.0
    self.DOASSupMassFlow = 0.0
    self.DOASSupTemp = 0.0
    self.DOASSupHumRat = 0.0
    self.DOASTotCoolLoad = 0.0
    self.HeatLoadNoDOAS = 0.0
    self.CoolLoadNoDOAS = 0.0
    self.HeatLatentLoad = 0.0
    self.CoolLatentLoad = 0.0
    self.HeatLatentLoadNoDOAS = 0.0
    self.CoolLatentLoadNoDOAS = 0.0
    self.ZoneHeatLatentMassFlow = 0.0
    self.ZoneCoolLatentMassFlow = 0.0
    self.ZoneHeatLatentVolFlow = 0.0
    self.ZoneCoolLatentVolFlow = 0.0
    self.DesHeatLoadNoDOAS = 0.0
    self.DesCoolLoadNoDOAS = 0.0
    self.DesLatentHeatLoad = 0.0
    self.DesLatentCoolLoad = 0.0
    self.DesLatentHeatLoadNoDOAS = 0.0
    self.DesLatentCoolLoadNoDOAS = 0.0
    self.DesLatentHeatMassFlow = 0.0
    self.DesLatentCoolMassFlow = 0.0
    self.DesLatentHeatVolFlow = 0.0
    self.DesLatentCoolVolFlow = 0.0
    self.DesLatentHeatCoilInTemp = 0.0
    self.DesLatentCoolCoilInTemp = 0.0
    self.DesLatentHeatCoilInHumRat = 0.0
    self.DesLatentCoolCoilInHumRat = 0.0
    self.TimeStepNumAtLatentHeatMax = 0
    self.TimeStepNumAtLatentCoolMax = 0
    self.TimeStepNumAtLatentHeatNoDOASMax = 0
    self.TimeStepNumAtLatentCoolNoDOASMax = 0
    self.OutTempAtLatentCoolPeak = 0.0
    self.OutHumRatAtLatentCoolPeak = 0.0
    self.OutTempAtLatentHeatPeak = 0.0
    self.OutHumRatAtLatentHeatPeak = 0.0
    self.ZoneRetTempAtLatentCoolPeak = 0.0
    self.ZoneRetTempAtLatentHeatPeak = 0.0

def ZoneSizingData.allocateMemberArrays(self, numOfTimeStepInDay: Int32):
    self.HeatFlowSeq.dimension(numOfTimeStepInDay, 0.0)
    self.CoolFlowSeq.dimension(numOfTimeStepInDay, 0.0)
    self.HeatFlowSeqNoOA.dimension(numOfTimeStepInDay, 0.0)
    self.CoolFlowSeqNoOA.dimension(numOfTimeStepInDay, 0.0)
    self.HeatLoadSeq.dimension(numOfTimeStepInDay, 0.0)
    self.CoolLoadSeq.dimension(numOfTimeStepInDay, 0.0)
    self.HeatZoneTempSeq.dimension(numOfTimeStepInDay, 0.0)
    self.DesHeatSetPtSeq.dimension(numOfTimeStepInDay, 0.0)
    self.CoolZoneTempSeq.dimension(numOfTimeStepInDay, 0.0)
    self.DesCoolSetPtSeq.dimension(numOfTimeStepInDay, 0.0)
    self.HeatOutTempSeq.dimension(numOfTimeStepInDay, 0.0)
    self.HeatMCPISeq.dimension(numOfTimeStepInDay, 0.0)
    self.HeatMCPVSeq.dimension(numOfTimeStepInDay, 0.0)
    self.CoolOutTempSeq.dimension(numOfTimeStepInDay, 0.0)
    self.HeatZoneRetTempSeq.dimension(numOfTimeStepInDay, 0.0)
    self.HeatTstatTempSeq.dimension(numOfTimeStepInDay, 0.0)
    self.CoolZoneRetTempSeq.dimension(numOfTimeStepInDay, 0.0)
    self.CoolTstatTempSeq.dimension(numOfTimeStepInDay, 0.0)
    self.HeatZoneHumRatSeq.dimension(numOfTimeStepInDay, 0.0)
    self.CoolZoneHumRatSeq.dimension(numOfTimeStepInDay, 0.0)
    self.HeatOutHumRatSeq.dimension(numOfTimeStepInDay, 0.0)
    self.CoolOutHumRatSeq.dimension(numOfTimeStepInDay, 0.0)
    self.DOASHeatLoadSeq.dimension(numOfTimeStepInDay, 0.0)
    self.DOASCoolLoadSeq.dimension(numOfTimeStepInDay, 0.0)
    self.DOASHeatAddSeq.dimension(numOfTimeStepInDay, 0.0)
    self.DOASLatAddSeq.dimension(numOfTimeStepInDay, 0.0)
    self.DOASSupMassFlowSeq.dimension(numOfTimeStepInDay, 0.0)
    self.DOASSupTempSeq.dimension(numOfTimeStepInDay, 0.0)
    self.DOASSupHumRatSeq.dimension(numOfTimeStepInDay, 0.0)
    self.DOASTotCoolLoadSeq.dimension(numOfTimeStepInDay, 0.0)
    self.HeatLoadNoDOASSeq.dimension(numOfTimeStepInDay, 0.0)
    self.CoolLoadNoDOASSeq.dimension(numOfTimeStepInDay, 0.0)
    self.LatentHeatLoadSeq.dimension(numOfTimeStepInDay, 0.0)
    self.LatentCoolLoadSeq.dimension(numOfTimeStepInDay, 0.0)
    self.HeatLatentLoadNoDOASSeq.dimension(numOfTimeStepInDay, 0.0)
    self.CoolLatentLoadNoDOASSeq.dimension(numOfTimeStepInDay, 0.0)
    self.LatentCoolFlowSeq.dimension(numOfTimeStepInDay, 0.0)
    self.LatentHeatFlowSeq.dimension(numOfTimeStepInDay, 0.0)

@value
struct TermUnitZoneSizingData(TermUnitZoneSizingCommonData):
    var ADUName: String = ""  # Override? Actually not listed in struct but okay
    # Methods will be added below

def TermUnitZoneSizingData.scaleZoneCooling(self, ratio: Float64):
    self.DesCoolVolFlow *= ratio
    self.DesCoolMassFlow *= ratio
    self.DesCoolLoad *= ratio
    for i in range(len(self.CoolFlowSeq)):
        self.CoolFlowSeq[i] *= ratio

def TermUnitZoneSizingData.scaleZoneHeating(self, ratio: Float64):
    self.DesHeatVolFlow *= ratio
    self.DesHeatMassFlow *= ratio
    self.DesHeatLoad *= ratio
    for i in range(len(self.HeatFlowSeq)):
        self.HeatFlowSeq[i] *= ratio

def TermUnitZoneSizingData.copyFromZoneSizing(self, sourceData: ZoneSizingData):
    self.ZoneName = sourceData.ZoneName
    self.ADUName = sourceData.ADUName
    self.CoolDesTemp = sourceData.CoolDesTemp
    self.HeatDesTemp = sourceData.HeatDesTemp
    self.CoolDesHumRat = sourceData.CoolDesHumRat
    self.HeatDesHumRat = sourceData.HeatDesHumRat
    self.DesOAFlowPPer = sourceData.DesOAFlowPPer
    self.DesOAFlowPerArea = sourceData.DesOAFlowPerArea
    self.DesCoolMinAirFlow = sourceData.DesCoolMinAirFlow
    self.DesCoolMinAirFlowFrac = sourceData.DesCoolMinAirFlowFrac
    self.DesHeatMaxAirFlow = sourceData.DesHeatMaxAirFlow
    self.DesHeatMaxAirFlowFrac = sourceData.DesHeatMaxAirFlowFrac
    self.ZoneNum = sourceData.ZoneNum
    self.DesHeatMassFlow = sourceData.DesHeatMassFlow
    self.DesHeatMassFlowNoOA = sourceData.DesHeatMassFlowNoOA
    self.DesHeatOAFlowFrac = sourceData.DesHeatOAFlowFrac
    self.DesCoolMassFlow = sourceData.DesCoolMassFlow
    self.DesCoolMassFlowNoOA = sourceData.DesCoolMassFlowNoOA
    self.DesCoolOAFlowFrac = sourceData.DesCoolOAFlowFrac
    self.DesHeatLoad = sourceData.DesHeatLoad
    self.NonAirSysDesHeatLoad = sourceData.NonAirSysDesHeatLoad
    self.DesCoolLoad = sourceData.DesCoolLoad
    self.NonAirSysDesCoolLoad = sourceData.NonAirSysDesCoolLoad
    self.DesHeatVolFlow = sourceData.DesHeatVolFlow
    self.DesHeatVolFlowNoOA = sourceData.DesHeatVolFlowNoOA
    self.NonAirSysDesHeatVolFlow = sourceData.NonAirSysDesHeatVolFlow
    self.DesCoolVolFlow = sourceData.DesCoolVolFlow
    self.DesCoolVolFlowNoOA = sourceData.DesCoolVolFlowNoOA
    self.NonAirSysDesCoolVolFlow = sourceData.NonAirSysDesCoolVolFlow
    self.DesHeatVolFlowMax = sourceData.DesHeatVolFlowMax
    self.DesCoolVolFlowMin = sourceData.DesCoolVolFlowMin
    self.DesHeatCoilInTempTU = sourceData.DesHeatCoilInTempTU
    self.DesCoolCoilInTempTU = sourceData.DesCoolCoilInTempTU
    self.DesHeatCoilInHumRatTU = sourceData.DesHeatCoilInHumRatTU
    self.DesCoolCoilInHumRatTU = sourceData.DesCoolCoilInHumRatTU
    self.ZoneTempAtHeatPeak = sourceData.ZoneTempAtHeatPeak
    self.ZoneRetTempAtHeatPeak = sourceData.ZoneRetTempAtHeatPeak
    self.ZoneTempAtCoolPeak = sourceData.ZoneTempAtCoolPeak
    self.ZoneRetTempAtCoolPeak = sourceData.ZoneRetTempAtCoolPeak
    self.ZoneHumRatAtHeatPeak = sourceData.ZoneHumRatAtHeatPeak
    self.ZoneHumRatAtCoolPeak = sourceData.ZoneHumRatAtCoolPeak
    self.TimeStepNumAtHeatMax = sourceData.TimeStepNumAtHeatMax
    self.TimeStepNumAtCoolMax = sourceData.TimeStepNumAtCoolMax
    self.HeatDDNum = sourceData.HeatDDNum
    self.CoolDDNum = sourceData.CoolDDNum
    self.MinOA = sourceData.MinOA
    self.DesCoolMinAirFlow2 = sourceData.DesCoolMinAirFlow2
    self.DesHeatMaxAirFlow2 = sourceData.DesHeatMaxAirFlow2
    # Copy arrays element by element (1-based to 0-based)
    for t in range(min(len(self.HeatFlowSeq), len(sourceData.HeatFlowSeq))):
        self.HeatFlowSeq[t] = sourceData.HeatFlowSeq[t]
        self.HeatFlowSeqNoOA[t] = sourceData.HeatFlowSeqNoOA[t]
        self.CoolFlowSeq[t] = sourceData.CoolFlowSeq[t]
        self.CoolFlowSeqNoOA[t] = sourceData.CoolFlowSeqNoOA[t]
        self.HeatZoneTempSeq[t] = sourceData.HeatZoneTempSeq[t]
        self.HeatZoneRetTempSeq[t] = sourceData.HeatZoneRetTempSeq[t]
        self.CoolZoneTempSeq[t] = sourceData.CoolZoneTempSeq[t]
        self.CoolZoneRetTempSeq[t] = sourceData.CoolZoneRetTempSeq[t]
    self.ZoneADEffCooling = sourceData.ZoneADEffCooling
    self.ZoneADEffHeating = sourceData.ZoneADEffHeating
    self.ZoneSecondaryRecirculation = sourceData.ZoneSecondaryRecirculation
    self.ZoneVentilationEff = sourceData.ZoneVentilationEff
    self.ZonePrimaryAirFraction = sourceData.ZonePrimaryAirFraction
    self.ZonePrimaryAirFractionHtg = sourceData.ZonePrimaryAirFractionHtg
    self.ZoneOAFracCooling = sourceData.ZoneOAFracCooling
    self.ZoneOAFracHeating = sourceData.ZoneOAFracHeating
    self.TotalOAFromPeople = sourceData.TotalOAFromPeople
    self.TotalOAFromArea = sourceData.TotalOAFromArea
    self.TotPeopleInZone = sourceData.TotPeopleInZone
    self.TotalZoneFloorArea = sourceData.TotalZoneFloorArea
    self.SupplyAirAdjustFactor = sourceData.SupplyAirAdjustFactor
    self.ZpzClgByZone = sourceData.ZpzClgByZone
    self.ZpzHtgByZone = sourceData.ZpzHtgByZone
    self.VozClgByZone = sourceData.VozClgByZone
    self.VozHtgByZone = sourceData.VozHtgByZone
    self.VpzMinByZoneSPSized = sourceData.VpzMinByZoneSPSized
    self.ZoneSizThermSetPtHi = sourceData.ZoneSizThermSetPtHi
    self.ZoneSizThermSetPtLo = sourceData.ZoneSizThermSetPtLo

def TermUnitZoneSizingData.allocateMemberArrays(self, numOfTimeStepInDay: Int32):
    self.HeatFlowSeq.dimension(numOfTimeStepInDay, 0.0)
    self.CoolFlowSeq.dimension(numOfTimeStepInDay, 0.0)
    self.HeatFlowSeqNoOA.dimension(numOfTimeStepInDay, 0.0)
    self.CoolFlowSeqNoOA.dimension(numOfTimeStepInDay, 0.0)
    self.HeatZoneTempSeq.dimension(numOfTimeStepInDay, 0.0)
    self.HeatZoneRetTempSeq.dimension(numOfTimeStepInDay, 0.0)
    self.CoolZoneTempSeq.dimension(numOfTimeStepInDay, 0.0)
    self.CoolZoneRetTempSeq.dimension(numOfTimeStepInDay, 0.0)

# ----------------------------------------------------------------------
# TermUnitSizingData
# ----------------------------------------------------------------------
@value
struct TermUnitSizingData:
    var CtrlZoneNum: Int32 = 0
    var ADUName: String = ""
    var AirVolFlow: Float64 = 0.0
    var MaxHWVolFlow: Float64 = 0.0
    var MaxSTVolFlow: Float64 = 0.0
    var MaxCWVolFlow: Float64 = 0.0
    var MinPriFlowFrac: Float64 = 0.0
    var InducRat: Float64 = 0.0
    var InducesPlenumAir: Bool = False
    var ReheatAirFlowMult: Float64 = 1.0
    var ReheatLoadMult: Float64 = 1.0
    var DesCoolingLoad: Float64 = 0.0
    var DesHeatingLoad: Float64 = 0.0
    var SpecDesSensCoolingFrac: Float64 = 1.0
    var SpecDesCoolSATRatio: Float64 = 1.0
    var SpecDesSensHeatingFrac: Float64 = 1.0
    var SpecDesHeatSATRatio: Float64 = 1.0
    var SpecMinOAFrac: Float64 = 1.0
    var plenumIndex: Int32 = 0

def TermUnitSizingData.applyTermUnitSizingCoolFlow(self, coolFlowWithOA: Float64, coolFlowNoOA: Float64) -> Float64:
    var coolFlowRatio: Float64 = 1.0
    if self.SpecDesCoolSATRatio > 0.0:
        coolFlowRatio = self.SpecDesSensCoolingFrac / self.SpecDesCoolSATRatio
    else:
        coolFlowRatio = self.SpecDesSensCoolingFrac
    var adjustedFlow: Float64 = coolFlowNoOA * coolFlowRatio + (coolFlowWithOA - coolFlowNoOA) * self.SpecMinOAFrac
    return adjustedFlow

def TermUnitSizingData.applyTermUnitSizingHeatFlow(self, heatFlowWithOA: Float64, heatFlowNoOA: Float64) -> Float64:
    var heatFlowRatio: Float64 = 1.0
    if self.SpecDesHeatSATRatio > 0.0:
        heatFlowRatio = self.SpecDesSensHeatingFrac / self.SpecDesHeatSATRatio
    else:
        heatFlowRatio = self.SpecDesSensHeatingFrac
    var adjustedFlow: Float64 = heatFlowNoOA * heatFlowRatio + (heatFlowWithOA - heatFlowNoOA) * self.SpecMinOAFrac
    return adjustedFlow

def TermUnitSizingData.applyTermUnitSizingCoolLoad(self, coolLoad: Float64) -> Float64:
    return coolLoad * self.SpecDesSensCoolingFrac

def TermUnitSizingData.applyTermUnitSizingHeatLoad(self, heatLoad: Float64) -> Float64:
    return heatLoad * self.SpecDesSensHeatingFrac

# ----------------------------------------------------------------------
# ZoneEqSizingData
# ----------------------------------------------------------------------
@value
struct ZoneEqSizingData:
    var AirVolFlow: Float64 = 0.0
    var MaxHWVolFlow: Float64 = 0.0
    var MaxCWVolFlow: Float64 = 0.0
    var OAVolFlow: Float64 = 0.0
    var ATMixerVolFlow: Float64 = 0.0
    var ATMixerCoolPriDryBulb: Float64 = 0.0
    var ATMixerCoolPriHumRat: Float64 = 0.0
    var ATMixerHeatPriDryBulb: Float64 = 0.0
    var ATMixerHeatPriHumRat: Float64 = 0.0
    var DesCoolingLoad: Float64 = 0.0
    var DesHeatingLoad: Float64 = 0.0
    var CoolingAirVolFlow: Float64 = 0.0
    var HeatingAirVolFlow: Float64 = 0.0
    var SystemAirVolFlow: Float64 = 0.0
    var AirFlow: Bool = False
    var CoolingAirFlow: Bool = False
    var HeatingAirFlow: Bool = False
    var SystemAirFlow: Bool = False
    var Capacity: Bool = False
    var CoolingCapacity: Bool = False
    var HeatingCapacity: Bool = False
    var SystemCapacity: Bool = False
    var DesignSizeFromParent: Bool = False
    var HVACSizingIndex: Int32 = 0
    var SizingMethod: Array1D[Int32] = Array1D[Int32]()
    var CapSizingMethod: Array1D[Int32] = Array1D[Int32]()

# ----------------------------------------------------------------------
# ZoneHVACSizingData
# ----------------------------------------------------------------------
@value
struct ZoneHVACSizingData:
    var Name: String = ""
    var CoolingSAFMethod: Int32 = 0
    var HeatingSAFMethod: Int32 = 0
    var NoCoolHeatSAFMethod: Int32 = 0
    var CoolingCapMethod: Int32 = 0
    var HeatingCapMethod: Int32 = 0
    var MaxCoolAirVolFlow: Float64 = 0.0
    var MaxHeatAirVolFlow: Float64 = 0.0
    var MaxNoCoolHeatAirVolFlow: Float64 = 0.0
    var ScaledCoolingCapacity: Float64 = 0.0
    var ScaledHeatingCapacity: Float64 = 0.0
    var RequestAutoSize: Bool = False
    var heatCoilSizingMethod: HeatCoilSizMethod = HeatCoilSizMethod.Invalid
    var maxHeatCoilToCoolingLoadSizingRatio: Float64 = 0.0

# ----------------------------------------------------------------------
# AirTerminalSizingSpecData
# ----------------------------------------------------------------------
@value
struct AirTerminalSizingSpecData:
    var Name: String = ""
    var DesSensCoolingFrac: Float64 = 1.0
    var DesCoolSATRatio: Float64 = 1.0
    var DesSensHeatingFrac: Float64 = 1.0
    var DesHeatSATRatio: Float64 = 1.0
    var MinOAFrac: Float64 = 1.0

# ----------------------------------------------------------------------
# SystemSizingInputData
# ----------------------------------------------------------------------
@value
struct SystemSizingInputData:
    var AirPriLoopName: String = ""
    var AirLoopNum: Int32 = 0
    var loadSizingType: LoadSizing = LoadSizing.Invalid
    var SizingOption: SizingConcurrence = SizingConcurrence.NonCoincident
    var CoolOAOption: OAControl = OAControl.Invalid
    var HeatOAOption: OAControl = OAControl.Invalid
    var DesOutAirVolFlow: Float64 = 0.0
    var SysAirMinFlowRat: Float64 = 0.0
    var SysAirMinFlowRatWasAutoSized: Bool = False
    var PreheatTemp: Float64 = 0.0
    var PrecoolTemp: Float64 = 0.0
    var PreheatHumRat: Float64 = 0.0
    var PrecoolHumRat: Float64 = 0.0
    var CoolSupTemp: Float64 = 0.0
    var HeatSupTemp: Float64 = 0.0
    var CoolSupHumRat: Float64 = 0.0
    var HeatSupHumRat: Float64 = 0.0
    var CoolAirDesMethod: AirflowSizingMethod = AirflowSizingMethod.Invalid
    var DesCoolAirFlow: Float64 = 0.0
    var HeatAirDesMethod: AirflowSizingMethod = AirflowSizingMethod.Invalid
    var DesHeatAirFlow: Float64 = 0.0
    var ScaleCoolSAFMethod: Int32 = 0
    var ScaleHeatSAFMethod: Int32 = 0
    var SystemOAMethod: SysOAMethod = SysOAMethod.Invalid
    var MaxZoneOAFraction: Float64 = 0.0
    var OAAutoSized: Bool = False
    var CoolingCapMethod: Int32 = 0
    var HeatingCapMethod: Int32 = 0
    var ScaledCoolingCapacity: Float64 = 0.0
    var ScaledHeatingCapacity: Float64 = 0.0
    var FloorAreaOnAirLoopCooled: Float64 = 0.0
    var FloorAreaOnAirLoopHeated: Float64 = 0.0
    var FlowPerFloorAreaCooled: Float64 = 0.0
    var FlowPerFloorAreaHeated: Float64 = 0.0
    var FractionOfAutosizedCoolingAirflow: Float64 = 1.0
    var FractionOfAutosizedHeatingAirflow: Float64 = 1.0
    var FlowPerCoolingCapacity: Float64 = 0.0
    var FlowPerHeatingCapacity: Float64 = 0.0
    var coolingPeakLoad: PeakLoad = PeakLoad.Invalid
    var CoolCapControl: CapacityControl = CapacityControl.Invalid
    var OccupantDiversity: Float64 = 0.0
    var heatCoilSizingMethod: HeatCoilSizMethod = HeatCoilSizMethod.Invalid
    var maxHeatCoilToCoolingLoadSizingRatio: Float64 = 0.0

# ----------------------------------------------------------------------
# SystemSizingData
# ----------------------------------------------------------------------
@value
struct SystemSizingData:
    var AirPriLoopName: String = ""
    var CoolDesDay: String = ""
    var HeatDesDay: String = ""
    var loadSizingType: LoadSizing = LoadSizing.Invalid
    var SizingOption: SizingConcurrence = SizingConcurrence.NonCoincident
    var CoolOAOption: OAControl = OAControl.Invalid
    var HeatOAOption: OAControl = OAControl.Invalid
    var DesOutAirVolFlow: Float64 = 0.0
    var SysAirMinFlowRat: Float64 = 0.0
    var SysAirMinFlowRatWasAutoSized: Bool = False
    var PreheatTemp: Float64 = 0.0
    var PrecoolTemp: Float64 = 0.0
    var PreheatHumRat: Float64 = 0.0
    var PrecoolHumRat: Float64 = 0.0
    var CoolSupTemp: Float64 = 0.0
    var HeatSupTemp: Float64 = 0.0
    var CoolSupHumRat: Float64 = 0.0
    var HeatSupHumRat: Float64 = 0.0
    var CoolAirDesMethod: AirflowSizingMethod = AirflowSizingMethod.Invalid
    var HeatAirDesMethod: AirflowSizingMethod = AirflowSizingMethod.Invalid
    var InpDesCoolAirFlow: Float64 = 0.0
    var InpDesHeatAirFlow: Float64 = 0.0
    var CoinCoolMassFlow: Float64 = 0.0
    var EMSOverrideCoinCoolMassFlowOn: Bool = False
    var EMSValueCoinCoolMassFlow: Float64 = 0.0
    var CoinHeatMassFlow: Float64 = 0.0
    var