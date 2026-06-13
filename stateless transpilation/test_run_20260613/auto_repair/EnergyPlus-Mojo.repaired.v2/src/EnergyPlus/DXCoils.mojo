from ObjexxFCL.Array1D import Array1D, Array1D_bool, Array1D_int, Array1D_string
from ObjexxFCL.Optional import Optional as ObjexxFCL_Optional
from EnergyPlus.Data.BaseData import EnergyPlusData, BaseGlobalStruct
from EnergyPlus.DataGlobalConstants import Constant
from DataHVACGlobals import HVAC
from DataHeatBalance import DataHeatBalance
from EnergyPlus.EnergyPlus import EnergyPlus
from StandardRatings import StandardRatings
from UtilityRoutines import ShowFatalError, ShowSevereError, ShowContinueError, ShowWarningError, ShowRecurringWarningErrorAtEnd, ShowWarningItemNotFound, ShowSevereItemNotFound, ShowSevereBadMin, ShowSevereBadMax, ShowSevereInvalidBool
from Psychrometrics import Psychrometrics
from CurveManager import Curve
from General import General
from GeneralRoutines import CreateSysTimeIntervalString, CalcComponentSensibleLatentOutput
from OutputProcessor import OutputProcessor, SetupOutputVariable
from OutputReportPredefined import OutputReportPredefined, PreDefTableEntry, addFootNoteSubTable
from NodeInputManager import Node
from OutAirNodeManager import CheckOutAirNodeNumber
from WaterManager import SetupTankDemandComponent, SetupTankSupplyComponent
from DataSizing import DataSizing
from EMSManager import EMSManager
from Fans import Fans
from GlobalNames import GlobalNames
from HeatBalanceInternalHeatGains import SetupZoneInternalGain
from .InputProcessing.InputProcessor import InputProcessor
from OutAirNodeManager import CheckOutAirNodeNumber
from ScheduleManager import Sched
from SimAirServingZones import SimAirServingZones
from StandardRatings import StandardRatings
from EnergyPlus.DataWater import DataWater
from EnergyPlus.DataContaminantBalance import DataContaminantBalance
from DataEnvironment import DataEnvironment
from EnergyPlus.DataLoopNode import DataLoopNode
from EnergyPlus.DataPrecisionGlobals import DataPrecisionGlobals
from ZoneTempPredictorCorrector import ZoneTempPredictorCorrector
from HVACVariableRefrigerantFlow import HVACVariableRefrigerantFlow
from BranchNodeConnections import BranchNodeConnections
from EnergyPlus.DataBranchNodeConnections import DataBranchNodeConnections
from DataAirSystems import DataAirSystems
from ReportCoilSelection import ReportCoilSelection
from .Autosizing.All_Simple_Sizing import AutoSize, AutoCalculateSizer, BaseSizer, SizerBase
from .Autosizing.CoolingAirFlowSizing import CoolingAirFlowSizer
from .Autosizing.CoolingCapacitySizing import CoolingCapacitySizer
from .Autosizing.CoolingSHRSizing import CoolingSHRSizer
from .Autosizing.HeatingAirFlowSizing import HeatingAirFlowSizer
from .Autosizing.HeatingCapacitySizing import HeatingCapacitySizer
import math
import sys
alias RatedInletAirTemp: Float64 = 26.6667          # 26.6667C or 80F
alias RatedInletWetBulbTemp: Float64 = 19.4444      # 19.44 or 67F
alias RatedInletAirHumRat: Float64 = 0.0111847      # Humidity ratio corresponding to 80F dry bulb/67F wet bulb
alias RatedOutdoorAirTemp: Float64 = 35.0           # 35 C or 95F
alias RatedInletAirTempHeat: Float64 = 21.1111      # 21.11C or 70F
alias RatedOutdoorAirTempHeat: Float64 = 8.3333     # 8.33 C or 47F
alias RatedOutdoorWetBulbTempHeat: Float64 = 6.1111 # 6.11 C or 43F
alias RatedInletWetBulbTempHeat: Float64 = 15.5556  # 15.55 or 60F
alias DryCoilOutletHumRatioMin: Float64 = 0.00001   # dry coil outlet minimum hum ratio kgWater/kgDryAir
alias MaxCapacityStages: Int = 2                               # Maximum number of capacity stages supported
alias MaxDehumidModes: Int = 1                                 # Maximum number of enhanced dehumidification modes supported
alias MaxModes: Int = MaxCapacityStages * (MaxDehumidModes + 1) # Maximum number of performance modes
enum CondensateCollectAction:
    Invalid = -1
    Discard = 0 # default mode where water is "lost"
    ToTank = 1  # collect coil condensate from air and store in water storage tank
    Num = 2
enum EvapWaterSupply:
    Invalid = -1
    FromMains = 0
    FromTank = 1
    Num = 2
struct DXCoilData:
    var Name: String                                       # Name of the DX Coil
    var coilType: HVAC.CoilType = HVAC.CoilType.Invalid    # Integer equivalent to DXCoilType
    var coilReportNum: Int = -1
    var availSched: Optional[Sched.Schedule] = None        # availability schedule
    var RatedTotCap: Array1D[Float64]                      # Gross total cooling capacity at rated conditions [watts]
    var HeatSizeRatio: Float64
    var RatedTotCapEMSOverrideOn: Array1D_bool             # if true, then EMS is calling to override rated total capacity
    var RatedTotCapEMSOverrideValue: Array1D[Float64]      # value to use for EMS override
    var FrostHeatingCapacityMultiplierEMSOverrideOn: Bool   # if true, then EMS is calling to override multiplier for heating capacity when system is
    var FrostHeatingCapacityMultiplierEMSOverrideValue: Float64 # value to use for EMS override
    var FrostHeatingInputPowerMultiplierEMSOverrideOn: Bool # if true, then EMS is calling to override multiplier for power when system is in defrost
    var FrostHeatingInputPowerMultiplierEMSOverrideValue: Float64 # value to use for EMS override
    var RatedSHR: Array1D[Float64]                                # Sensible heat ratio (sens cap/total cap) at rated conditions
    var RatedSHREMSOverrideOn: Array1D_bool                      # if true, then EMS is calling to override Sensible heat ratio
    var RatedSHREMSOverrideValue: Array1D[Float64]                # value to use for EMS override forSensible heat ratio
    var RatedCOP: Array1D[Float64]                                # Coefficient of performance at rated conditions
    var RatedAirVolFlowRate: Array1D[Float64]                     # Air volume flow rate through coil at rated conditions [m3/s]
    var RatedAirVolFlowRateEMSOverrideON: Array1D_bool       # if true, then EMS is calling to override Air volume flow rate
    var RatedAirVolFlowRateEMSOverrideValue: Array1D[Float64] # value to use for EMS override Air volume flow rate
    var FanPowerPerEvapAirFlowRate: Array1D[Float64]          # Fan Power Per Air volume flow rate through the
    var FanPowerPerEvapAirFlowRate_2023: Array1D[Float64]
    var RatedAirMassFlowRate: Array1D[Float64] # Air mass flow rate through coil at rated conditions [kg/s]
    var BypassedFlowFrac: Array1D[Float64] # Fraction of air flow bypassed around coil
    var RatedCBF: Array1D[Float64]         # rated coil bypass factor, determined using RatedTotCap and RatedSHR
    var AirInNode: Int                     # Air inlet node number
    var AirOutNode: Int                    # Air outlet node number
    var CCapFTemp: Array1D_int             # index of total cooling capacity modifier curve
    var CCapFTempErrorIndex: Int # Used for warning messages when output of CCapFTemp is negative
    var CCapFFlow: Array1D_int   # index of total cooling capacity modifier curve
    var CCapFFlowErrorIndex: Int # Used for warning messages when output of CCapFFlow is negative
    var EIRFTemp: Array1D_int    # index of energy input ratio modifier curve
    var EIRFTempErrorIndex: Int # Used for warning messages when output of EIRFTemp is negative
    var EIRFFlow: Array1D_int   # index of energy input ratio modifier curve
    var EIRFFlowErrorIndex: Int                # Used for warning messages when output of EIRFFlow is negative
    var PLFFPLR: Array1D_int                   # index of part-load factor vs part-load ratio curve
    var ReportCoolingCoilCrankcasePower: Bool  # logical determines if the cooling coil crankcase heater power is reported
    var CrankcaseHeaterCapacity: Float64        # total crankcase heater capacity [W]
    var CrankcaseHeaterPower: Float64           # report variable for average crankcase heater power [W]
    var MaxOATCrankcaseHeater: Float64          # maximum OAT for crankcase heater operation [C]
    var CrankcaseHeaterCapacityCurveIndex: Int # Crankcase heater power-temperature curve or table index
    var CrankcaseHeaterConsumption: Float64     # report variable for total crankcase heater energy consumption [J]
    var BasinHeaterPowerFTempDiff: Float64      # Basin heater capacity per degree C below setpoint (W/C)
    var BasinHeaterSetPointTemp: Float64        # setpoint temperature for basin heater operation (C)
    var CompanionUpstreamDXCoil: Int            # index number of the DX coil that is "upstream" of this DX coil. Currently used for
    var FindCompanionUpStreamCoil: Bool              # Flag to get the companion coil in Init.
    var CondenserInletNodeNum: Array1D_int           # Node number of outdoor condenser(s) (actually an evaporator for heating coils)
    var LowOutletTempIndex: Int                      # used for low outlet temperature warnings
    var FullLoadOutAirTempLast: Float64               # used for low outlet temperature warnings
    var FullLoadInletAirTempLast: Float64             # used for low outlet temperature warnings
    var PrintLowOutTempMessage: Bool                 # used to print warning message for low outlet air dry-bulb conditions
    var LowOutTempBuffer1: String                    # holds warning message until next iteration (only prints 1 message/iteration)
    var LowOutTempBuffer2: String                    # holds warning message until next iteration (only prints 1 message/iteration)
    var HeatingCoilPLFCurvePTR: Int                  # PLF curve index to gas or electric heating coil (used in latent degradation model)
    var basinHeaterSched: Optional[Sched.Schedule] = None # Pointer to basin heater schedule
    var RatedTotCap2: Float64 # Gross total cooling capacity at rated conditions, low speed [watts]
    var RatedSHR2: Float64            # Sensible heat ratio (sens cap/total cap) at rated conditions, low speed
    var RatedCOP2: Float64            # Coefficient of performance at rated conditions, low speed
    var RatedAirVolFlowRate2: Float64 # Air volume flow rate through unit at rated conditions, low speed [m3/s]
    var FanPowerPerEvapAirFlowRate_LowSpeed: Array1D[Float64] # Fan Power Per Air volume flow rate through the
    var FanPowerPerEvapAirFlowRate_2023_LowSpeed: Array1D[Float64]
    var RatedAirMassFlowRate2: Float64 # Air mass flow rate through unit at rated conditions, low speed [kg/s]
    var RatedCBF2: Float64             # rated coil bypass factor (low speed), determined using RatedTotCap2 and RatedSHR2
    var CCapFTemp2: Int                # index of total cooling capacity modifier curve (low speed)
    var EIRFTemp2: Int                 # index of energy input ratio modifier curve (low speed)
    var RatedEIR2: Float64                  # rated energy input ratio (low speed, inverse of COP2)
    var InternalStaticPressureDrop: Float64  # for rating VAV system
    var RateWithInternalStaticAndFanObject: Bool
    var SupplyFanIndex: Int          # index of this fan in fan array or vector
    var supplyFanType: HVAC.FanType # type of fan, in DataHVACGlobals
    var SupplyFanName: String        # name of fan associated with this dx coil
    var CoilSystemName: String
    var RatedEIR: Array1D[Float64] # rated energy input ratio (inverse of COP)
    var InletAirMassFlowRate: Float64
    var InletAirMassFlowRateMax: Float64
    var InletAirTemp: Float64
    var InletAirHumRat: Float64
    var InletAirEnthalpy: Float64
    var OutletAirTemp: Float64
    var OutletAirHumRat: Float64
    var OutletAirEnthalpy: Float64
    var PartLoadRatio: Float64 # Ratio of actual sensible cooling load to steady-state sensible cooling capacity
    var TotalCoolingEnergy: Float64
    var SensCoolingEnergy: Float64
    var LatCoolingEnergy: Float64
    var TotalCoolingEnergyRate: Float64
    var SensCoolingEnergyRate: Float64
    var LatCoolingEnergyRate: Float64
    var ElecCoolingConsumption: Float64
    var ElecCoolingPower: Float64
    var CoolingCoilRuntimeFraction: Float64 # Run time fraction of the DX cooling unit
    var TotalHeatingEnergy: Float64
    var TotalHeatingEnergyRate: Float64
    var ElecHeatingConsumption: Float64
    var ElecHeatingPower: Float64
    var HeatingCoilRuntimeFraction: Float64                # Run time fraction of the DX heating unit
    var DefrostStrategy: StandardRatings.DefrostStrat    # defrost strategy; 1=reverse-cycle, 2=resistive
    var DefrostControl: StandardRatings.HPdefrostControl # defrost control; 1=timed, 2=on-demand
    var EIRFPLR: Int                                      # index of energy input ratio vs part-load ratio curve
    var DefrostEIRFT: Int                                 # index of defrost mode total cooling capacity for reverse cycle heat pump
    var RegionNum: Int                                    # Region number for calculating HSPF of single speed DX heating coil
    var MinOATCompressor: Float64                          # Minimum OAT for heat pump compressor operation
    var OATempCompressorOn: Float64                        # The outdoor temperature when the compressor is automatically turned back on,
    var MaxOATCompressor: Float64                 # Maximum OAT for VRF heat pump compressor operation
    var MaxOATDefrost: Float64                    # Maximum OAT for defrost operation
    var DefrostTime: Float64                      # Defrost time period in hours
    var DefrostCapacity: Float64                  # Resistive defrost to nominal capacity (at 21.11C/8.33C) ratio
    var HPCompressorRuntime: Float64              # keep track of compressor runtime
    var HPCompressorRuntimeLast: Float64          # keep track of last time step compressor runtime (if simulation downshifts)
    var TimeLeftToDefrost: Float64                # keep track of time left to defrost heat pump
    var DefrostPower: Float64                     # power used during defrost
    var DefrostConsumption: Float64               # energy used during defrost
    var HeatingPerformanceOATType: HVAC.OATType # Heating performance curve OAT type (1-wetbulb, 2-drybulb)
    var HPCoilIsInCoilSystemHeatingDX: Bool
    var OATempCompressorOnOffBlank: Bool
    var Twet_Rated: Array1D[Float64] # Nominal time for condensate to begin leaving the coil's
    var Gamma_Rated: Array1D[Float64] # Initial moisture evaporation rate divided by steady-state
    var MaxONOFFCyclesperHour: Array1D[Float64]      # Maximum ON/OFF cycles per hour for the compressor (cycles/hour)
    var LatentCapacityTimeConstant: Array1D[Float64] # Time constant for latent capacity to reach steady state
    var CondenserType: Array1D[DataHeatBalance.RefrigCondenserType] # Type of condenser for DX cooling coil: AIR COOLED or EVAP COOLED
    var ReportEvapCondVars: Bool        # true if any performance mode includes an evap condenser
    var EvapCondEffect: Array1D[Float64] # effectiveness of the evaporatively cooled condenser
    var CondInletTemp: Float64            # Evap condenser inlet temperature [C], report variable
    var EvapCondAirFlow: Array1D[Float64] # Air flow rate through the evap condenser at high speed,
    var EvapCondPumpElecNomPower: Array1D[Float64] # Nominal power input to the evap condenser water circulation pump
    var EvapCondPumpElecPower: Float64 # Average power consumed by the evap condenser water circulation pump over
    var EvapCondPumpElecConsumption: Float64 # Electric energy consumed by the evap condenser water circulation pump [J]
    var EvapWaterConsumpRate: Float64        # Evap condenser water consumption rate [m3/s]
    var EvapWaterConsump: Float64            # Evap condenser water consumption [m3]
    var EvapCondAirFlow2: Float64            # Air flow rate through the evap condenser at low speed, for water use calcs [m3/s]
    var EvapCondEffect2: Float64             # effectiveness of the evaporatively cooled condenser at low speed (-)
    var EvapCondPumpElecNomPower2: Float64   # Nominal power input to the evap condenser water circulation pump at low speed [W]
    var BasinHeaterPower: Float64            # Basin heater power (W)
    var BasinHeaterConsumption: Float64      # Basin heater energy consumption (J)
    var NumCapacityStages: Int # number of capacity stages, up to MaxCapacityStages for Multimode DX coil,
    var NumDehumidModes: Int # number of enhanced dehumidification modes, up to MaxDehumidModes for Multimode DX coil,
    var CoilPerformanceType: Array1D_string                            # Coil Performance object type
    var CoilPerformanceType_Num: Array1D_int                           # Coil Performance object type number
    var CoilPerformanceName: Array1D_string                            # Coil Performance object names
    var CoolingCoilStg2RuntimeFrac: Float64                             # Run time fraction of stage 2
    var DehumidificationMode: HVAC.CoilMode = HVAC.CoilMode.Invalid # Dehumidification mode for multimode coil,
    var WaterInNode: Int                                                # Condenser water inlet node number for HPWH DX coil
    var WaterOutNode: Int                                               # Condenser water outlet node number for HPWH DX coil
    var HCOPFTemp: Int                                                  # COP as a function of temperature curve index
    var HCOPFTempErrorIndex: Int                                        # Used for warning messages when output of HCOPFTemp is negative
    var HCOPFAirFlow: Int                                               # COP as a function of air flow rate ratio curve index
    var HCOPFAirFlowErrorIndex: Int                                     # Used for warning messages when output of HCOPFAirFlow is negative
    var HCOPFWaterFlow: Int                                             # COP as a function of water flow rate ratio curve index
    var HCOPFWaterFlowErrorIndex: Int                                   # Used for warning messages when output of HCOPFWaterFlow is negative
    var HCapFTemp: Int                                                  # Heating capacity as a function of temperature curve index
    var HCapFTempErrorIndex: Int                                        # Used for warning messages when output of HCapFTemp is negative
    var HCapFAirFlow: Int                                               # Heating capacity as a function of air flow rate ratio curve index
    var HCapFAirFlowErrorIndex: Int                                     # Used for warning messages when output of HCapFAirFlow is negative
    var HCapFWaterFlow: Int                                             # Heating capacity as a function of water flow rate ratio curve index
    var HCapFWaterFlowErrorIndex: Int                                   # Used for warning messages when output of HCapFWaterFlow is negative
    var InletAirTemperatureType: HVAC.OATType = HVAC.OATType.Invalid # Specifies to use either air wet-bulb or dry-bulb temp for curve objects
    var RatedInletDBTemp: Float64                                        # Rated inlet air dry-bulb temperature [C]
    var RatedInletWBTemp: Float64                                        # Rated inlet air wet-bulb temperature [C]
    var RatedInletWaterTemp: Float64                                     # Rated condenser water inlet temperature [C]
    var HPWHCondPumpElecNomPower: Float64    # Nominal power input to the condenser water circulation pump [W]
    var HPWHCondPumpFracToWater: Float64     # Nominal power fraction to water for the condenser water circulation pump
    var RatedHPWHCondWaterFlow: Float64      # Rated water flow rate through the condenser of the HPWH DX coil [m3/s]
    var ElecWaterHeatingPower: Float64       # Total electric power consumed by compressor and condenser pump [W]
    var ElecWaterHeatingConsumption: Float64 # Total electric consumption by compressor and condenser pump [J]
    var FanPowerIncludedInCOP: Bool         # Indicates that fan heat is included in heating capacity and COP
    var CondPumpHeatInCapacity: Bool        # Indicates that condenser pump heat is included in heating capacity
    var CondPumpPowerInCOP: Bool            # Indicates that condenser pump power is included in heating COP
    var LowTempLast: Float64  # low ambient temp entering condenser when warning message occurred
    var HighTempLast: Float64 # high ambient temp entering condenser when warning message occurred
    var ErrIndex1: Int       # index/pointer to recurring error structure for Air volume flow rate per watt of
    var ErrIndex2: Int              # index/pointer to recurring error structure for PLF curve values must be >= 0.7. error
    var ErrIndex3: Int              # index/pointer to recurring error structure for DX cooling coil runtime fraction > 1.0 warning
    var ErrIndex4: Int              # index/pointer to recurring error structure for DX heating coil runtime fraction > 1.0 warning
    var LowAmbErrIndex: Int         # index/pointer to recurring error structure for low ambient temp entering condenser
    var HighAmbErrIndex: Int        # index/pointer to recurring error structure for high ambient temp entering condenser
    var PLFErrIndex: Int            # index/pointer to recurring error structure for PLF <> 1 at speed 1 for a multiple speed coil
    var PLRErrIndex: Int            # index/pointer to recurring error structure for PLR < .7
    var PrintLowAmbMessage: Bool    # used to print warning message for low ambient conditions
    var LowAmbBuffer1: String      # holds warning message until next iteration (only prints 1 message/iteration)
    var LowAmbBuffer2: String      # holds warning message until next iteration (only prints 1 message/iteration)
    var PrintHighAmbMessage: Bool   # used to print warning message for high ambient conditions
    var HighAmbBuffer1: String     # holds warning message until next iteration (only prints 1 message/iteration)
    var HighAmbBuffer2: String     # holds warning message until next iteration (only prints 1 message/iteration)
    var EvapWaterSupplyMode: EvapWaterSupply # where does water come from
    var EvapWaterSupplyName: String          # name of water source e.g. water storage tank
    var EvapWaterSupTankID: Int
    var EvapWaterTankDemandARRID: Int
    var CondensateCollectMode: CondensateCollectAction # where does water come from
    var CondensateCollectName: String                  # name of water source e.g. water storage tank
    var CondensateTankID: Int
    var CondensateTankSupplyARRID: Int
    var CondensateVdot: Float64 # rate of water condensation from air stream [m3/s]
    var CondensateVol: Float64  # amount of water condensed from air stream [m3]
    var CurrentEndTimeLast: Float64 # end time of time step for last simulation time step
    var TimeStepSysLast: Float64    # last system time step (used to check for downshifting)
    var FuelType: Constant.eFuel                   # Fuel type number
    var NumOfSpeeds: Int                            # Number of speeds
    var PLRImpact: Bool                             # Part load fraction applied to Speed Number > 1
    var LatentImpact: Bool                          # Latent degradation applied to Speed Number > 1
    var MSErrIndex: Array1D_int                     # index flag for num speeds/recurring messages
    var MSRatedTotCap: Array1D[Float64]              # Rated cooling capacity for MS heat pump [W]
    var MSRatedTotCapDes: Array1D[Float64]           # Autosized Gross total cooling capacity at rated conditions [watts]
    var MSRatedSHR: Array1D[Float64]                 # Rated SHR for MS heat pump [dimensionless]
    var MSRatedCOP: Array1D[Float64]                 # Rated COP for MS heat pump [dimensionless]
    var MSRatedAirVolFlowRate: Array1D[Float64]      # Air volume flow rate through unit at rated conditions [m3/s]
    var MSRatedAirMassFlowRate: Array1D[Float64]     # Air mass flow rate through unit at rated conditions [m3/s]
    var MSRatedCBF: Array1D[Float64]                 # rated coil bypass factor
    var MSCCapFTemp: Array1D_int                    # index of total cooling capacity modifier curve
    var MSCCapFFlow: Array1D_int                    # index of total cooling capacity modifier curve
    var MSEIRFTemp: Array1D_int                     # index of energy input ratio modifier curve as a function of temperature
    var MSEIRFFlow: Array1D_int                     # index of energy input ratio modifier curve as a function of flow fraction
    var MSPLFFPLR: Array1D_int                      # index of part load factor as a function of part load ratio
    var MSWasteHeat: Array1D_int                    # index of waste heat as a function of temperature
    var MSWasteHeatFrac: Array1D[Float64]            # Waste heat fraction
    var MSEvapCondEffect: Array1D[Float64]           # effectiveness of the evaporatively cooled condenser
    var MSEvapCondAirFlow: Array1D[Float64]          # Air flow rate through the evap condenser for water use calcs [m3/s]
    var MSEvapCondPumpElecNomPower: Array1D[Float64] # Nominal power input to the evap condenser
    var MSTwet_Rated: Array1D[Float64] # Nominal time for condensate to begin leaving the coil's
    var MSGamma_Rated: Array1D[Float64] # Initial moisture evaporation rate divided by steady-state
    var MSMaxONOFFCyclesperHour: Array1D[Float64]      # Maximum ON/OFF cycles per hour for the compressor (cycles/hour)
    var MSLatentCapacityTimeConstant: Array1D[Float64] # Time constant for latent capacity to reach steady state
    var MSFanPowerPerEvapAirFlowRate: Array1D[Float64]
    var MSFanPowerPerEvapAirFlowRate_2023: Array1D[Float64]
    var FuelUsed: Float64 = 0.0     # Energy used, in addition to electricity [W]
    var FuelConsumed: Float64 = 0.0 # Energy consumed, in addition to electricity [J]
    var MSFuelWasteHeat: Float64    # Total waste heat [J]
    var MSHPHeatRecActive: Bool    # True when entered Heat Rec Vol Flow Rate > 0
    var MSHPDesignSpecIndex: Int   # index to MSHPDesignSpecification object used for variable speed coils
    var CoolingCoilPresent: Bool         # FALSE if coil not present
    var HeatingCoilPresent: Bool         # FALSE if coil not present
    var ISHundredPercentDOASDXCoil: Bool # FALSE if coil is regular dx coil
    var SHRFTemp: Array1D_int            # index of sensible heat ratio modifier curve
    var SHRFTempErrorIndex: Int # Used for warning messages when output of SHRFTemp is negative
    var SHRFFlow: Array1D_int   # index of sensible heat ratio modifier curve
    var SHRFFlowErrorIndex: Int # Used for warning messages when output of SHRFFlow is negative
    var SHRFTemp2: Int          # index of sensible heat ratio modifier curve
    var SHRFFlow2: Int # index of sensible heat ratio modifier curve
    var UserSHRCurveExists: Bool # TRUE if user specified SHR modifier curve exists
    var ASHRAE127StdRprt: Bool   # TRUE if user wishes to report ASHRAE 127 standard ratings
    var SecZonePtr: Int                                # index to the zone where the secondary coil is placed
    var SecCoilSHRFT: Int                              # index to the secondary coil sensible heat ratio temperature modifier curve
    var SecCoilSHRFF: Int                              # index to the secondary coil sensible heat ratio flor fraction modifier curve
    var SecCoilAirFlow: Float64                         # secondary coil air flow rate
    var SecCoilAirFlowScalingFactor: Float64            # secondary coil air flow rate autosize scaling factor
    var SecCoilRatedSHR: Float64                        # secondary coil nominal or rated sensible heat ratio
    var SecCoilSHR: Float64                             # secondary coil current sensible heat ratio
    var EvapInletWetBulb: Float64                       # secondary DX coil inlet wet bulb temperature (zone air node wet bulb temp.)
    var SecCoilSensibleHeatGainRate: Float64            # secondary zone sensible heat gain rate [W]
    var SecCoilTotalHeatRemovalRate: Float64            # secondary zone total heat removal rate [W]
    var SecCoilSensibleHeatRemovalRate: Float64         # secondary zone sensible heat removal rate [W]
    var SecCoilLatentHeatRemovalRate: Float64           # secondary zone latent heat removal rate [W]
    var IsSecondaryDXCoilInZone: Bool                  # true means secondary dx coil is zone instead of outside
    var IsDXCoilInZone: Bool                           # true means dx coil is in zone instead of outside
    var CompressorPartLoadRatio: Float64                # compressor part load ratio of the primary DX coil
    var MSSecCoilSHRFT: Array1D_int                    # index to the multi speed secondary coil sensible heat ratio temperature modifier curve
    var MSSecCoilSHRFF: Array1D_int                    #  index to the multi speed secondary coil sensible heat ratio flow fraction modifier curve
    var MSSecCoilAirFlow: Array1D[Float64]              # multispeed secondary coil air flow rate
    var MSSecCoilAirFlowScalingFactor: Array1D[Float64] # multispeed secondary coil air flow rate autosize scaling factor
    var MSSecCoilRatedSHR: Array1D[Float64]             # multispeed secondary coil nominal or rated sensible heat ratio
    var MSSpeedNumLS: Int                              # current low speed number of multspeed HP
    var MSSpeedNumHS: Int                              # current high speed number of multspeed HP
    var MSSpeedRatio: Float64                           # current speed ratio of multspeed HP
    var MSCycRatio: Float64                             # current cycling ratio of multspeed HP
    var VRFIUPtr: Int              # index to the VRF Indoor Unit where the coil is placed
    var VRFOUPtr: Int              # index to the VRF Outdoor Unit that the coil serves
    var EvaporatingTemp: Float64    # indoor unit evaporating temperature [C]
    var CondensingTemp: Float64     # indoor unit condensing temperature [C]
    var C1Te: Float64               # VRF Indoor Unit Coefficient 1 to calculate Te,req [--]
    var C2Te: Float64               # VRF Indoor Unit Coefficient 2 to calculate Te,req [--]
    var C3Te: Float64               # VRF Indoor Unit Coefficient 3 to calculate Te,req [--]
    var C1Tc: Float64               # VRF Indoor Unit Coefficient 1 to calculate Tc,req [--]
    var C2Tc: Float64               # VRF Indoor Unit Coefficient 2 to calculate Tc,req [--]
    var C3Tc: Float64               # VRF Indoor Unit Coefficient 3 to calculate Tc,req [--]
    var SH: Float64                 # Superheating degrees [C]
    var SC: Float64                 # Subcooling  degrees [C]
    var ActualSH: Float64           # Actual superheating degrees [C]
    var ActualSC: Float64           # Actual subcooling degrees [C]
    var RateBFVRFIUEvap: Float64    # VRF Iutdoor Unit Evaporator Rated Bypass Factor
    var RateBFVRFIUCond: Float64    # VRF Iutdoor Unit Condenser Rated Bypass Factor
    var CAPFTErrIndex: Int         # index/pointer to recurring error structure for CAPFT curve value <= 0.0
    var EIRFTErrIndex: Int         # index/pointer to recurring error structure for EIRFT curve value <= 0.0
    var reportCoilFinalSizes: Bool # one time report of sizes to coil selection report
    var capModFacTotal: Float64     # current coil capacity modification factor
    var AirLoopNum: Int            # Airloop number
    def __init__(inout self):
        self.RatedTotCap = Array1D[Float64](MaxModes, 0.0)
        self.HeatSizeRatio = 1.0
        self.RatedTotCapEMSOverrideOn = Array1D_bool(MaxModes, false)
        self.RatedTotCapEMSOverrideValue = Array1D[Float64](MaxModes, 0.0)
        self.FrostHeatingCapacityMultiplierEMSOverrideOn = false
        self.FrostHeatingCapacityMultiplierEMSOverrideValue = 0.0
        self.FrostHeatingInputPowerMultiplierEMSOverrideOn = false
        self.FrostHeatingInputPowerMultiplierEMSOverrideValue = 0.0
        self.RatedSHR = Array1D[Float64](MaxModes, 0.0)
        self.RatedSHREMSOverrideOn = Array1D_bool(MaxModes, false)
        self.RatedSHREMSOverrideValue = Array1D[Float64](MaxModes, 0.0)
        self.RatedCOP = Array1D[Float64](MaxModes, 0.0)
        self.RatedAirVolFlowRate = Array1D[Float64](MaxModes, 0.0)
        self.RatedAirVolFlowRateEMSOverrideON = Array1D_bool(MaxModes, false)
        self.RatedAirVolFlowRateEMSOverrideValue = Array1D[Float64](MaxModes, 0.0)
        self.FanPowerPerEvapAirFlowRate = Array1D[Float64](MaxModes, 0.0)
        self.FanPowerPerEvapAirFlowRate_2023 = Array1D[Float64](MaxModes, 0.0)
        self.RatedAirMassFlowRate = Array1D[Float64](MaxModes, 0.0)
        self.BypassedFlowFrac = Array1D[Float64](MaxModes, 0.0)
        self.RatedCBF = Array1D[Float64](MaxModes, 0.0)
        self.AirInNode = 0
        self.AirOutNode = 0
        self.CCapFTemp = Array1D_int(MaxModes, 0)
        self.CCapFTempErrorIndex = 0
        self.CCapFFlow = Array1D_int(MaxModes, 0)
        self.CCapFFlowErrorIndex = 0
        self.EIRFTemp = Array1D_int(MaxModes, 0)
        self.EIRFTempErrorIndex = 0
        self.EIRFFlow = Array1D_int(MaxModes, 0)
        self.EIRFFlowErrorIndex = 0
        self.PLFFPLR = Array1D_int(MaxModes, 0)
        self.ReportCoolingCoilCrankcasePower = true
        self.CrankcaseHeaterCapacity = 0.0
        self.CrankcaseHeaterPower = 0.0
        self.MaxOATCrankcaseHeater = 0.0
        self.CrankcaseHeaterCapacityCurveIndex = 0
        self.CrankcaseHeaterConsumption = 0.0
        self.BasinHeaterPowerFTempDiff = 0.0
        self.BasinHeaterSetPointTemp = 0.0
        self.CompanionUpstreamDXCoil = 0
        self.FindCompanionUpStreamCoil = true
        self.CondenserInletNodeNum = Array1D_int(MaxModes, 0)
        self.LowOutletTempIndex = 0
        self.FullLoadOutAirTempLast = 0.0
        self.FullLoadInletAirTempLast = 0.0
        self.PrintLowOutTempMessage = false
        self.HeatingCoilPLFCurvePTR = 0
        self.RatedTotCap2 = 0.0
        self.RatedSHR2 = 0.0
        self.RatedCOP2 = 0.0
        self.RatedAirVolFlowRate2 = 0.0
        self.FanPowerPerEvapAirFlowRate_LowSpeed = Array1D[Float64](MaxModes, 0.0)
        self.FanPowerPerEvapAirFlowRate_2023_LowSpeed = Array1D[Float64](MaxModes, 0.0)
        self.RatedAirMassFlowRate2 = 0.0
        self.RatedCBF2 = 0.0
        self.CCapFTemp2 = 0
        self.EIRFTemp2 = 0
        self.RatedEIR2 = 0.0
        self.InternalStaticPressureDrop = 0.0
        self.RateWithInternalStaticAndFanObject = false
        self.SupplyFanIndex = 0
        self.supplyFanType = HVAC.FanType.Invalid
        self.RatedEIR = Array1D[Float64](MaxModes, 0.0)
        self.InletAirMassFlowRate = 0.0
        self.InletAirMassFlowRateMax = 0.0
        self.InletAirTemp = 0.0
        self.InletAirHumRat = 0.0
        self.InletAirEnthalpy = 0.0
        self.OutletAirTemp = 0.0
        self.OutletAirHumRat = 0.0
        self.OutletAirEnthalpy = 0.0
        self.PartLoadRatio = 0.0
        self.TotalCoolingEnergy = 0.0
        self.SensCoolingEnergy = 0.0
        self.LatCoolingEnergy = 0.0
        self.TotalCoolingEnergyRate = 0.0
        self.SensCoolingEnergyRate = 0.0
        self.LatCoolingEnergyRate = 0.0
        self.ElecCoolingConsumption = 0.0
        self.ElecCoolingPower = 0.0
        self.CoolingCoilRuntimeFraction = 0.0
        self.TotalHeatingEnergy = 0.0
        self.TotalHeatingEnergyRate = 0.0
        self.ElecHeatingConsumption = 0.0
        self.ElecHeatingPower = 0.0
        self.HeatingCoilRuntimeFraction = 0.0
        self.DefrostStrategy = StandardRatings.DefrostStrat.Invalid
        self.DefrostControl = StandardRatings.HPdefrostControl.Invalid
        self.EIRFPLR = 0
        self.DefrostEIRFT = 0
        self.RegionNum = 0
        self.MinOATCompressor = 0.0
        self.OATempCompressorOn = 0.0
        self.MaxOATCompressor = 0.0
        self.MaxOATDefrost = 0.0
        self.DefrostTime = 0.0
        self.DefrostCapacity = 0.0
        self.HPCompressorRuntime = 0.0
        self.HPCompressorRuntimeLast = 0.0
        self.TimeLeftToDefrost = 0.0
        self.DefrostPower = 0.0
        self.DefrostConsumption = 0.0
        self.HeatingPerformanceOATType = HVAC.OATType.DryBulb
        self.HPCoilIsInCoilSystemHeatingDX = false
        self.OATempCompressorOnOffBlank = false
        self.Twet_Rated = Array1D[Float64](MaxModes, 0.0)
        self.Gamma_Rated = Array1D[Float64](MaxModes, 0.0)
        self.MaxONOFFCyclesperHour = Array1D[Float64](MaxModes, 0.0)
        self.LatentCapacityTimeConstant = Array1D[Float64](MaxModes, 0.0)
        self.CondenserType = Array1D[DataHeatBalance.RefrigCondenserType](MaxModes, DataHeatBalance.RefrigCondenserType.Air)
        self.ReportEvapCondVars = false
        self.EvapCondEffect = Array1D[Float64](MaxModes, 0.0)
        self.CondInletTemp = 0.0
        self.EvapCondAirFlow = Array1D[Float64](MaxModes, 0.0)
        self.EvapCondPumpElecNomPower = Array1D[Float64](MaxModes, 0.0)
        self.EvapCondPumpElecPower = 0.0
        self.EvapCondPumpElecConsumption = 0.0
        self.EvapWaterConsumpRate = 0.0
        self.EvapWaterConsump = 0.0
        self.EvapCondAirFlow2 = 0.0
        self.EvapCondEffect2 = 0.0
        self.EvapCondPumpElecNomPower2 = 0.0
        self.BasinHeaterPower = 0.0
        self.BasinHeaterConsumption = 0.0
        self.NumCapacityStages = 1
        self.NumDehumidModes = 0
        self.CoilPerformanceType = Array1D_string(MaxModes)
        self.CoilPerformanceType_Num = Array1D_int(MaxModes, 0)
        self.CoilPerformanceName = Array1D_string(MaxModes)
        self.CoolingCoilStg2RuntimeFrac = 0.0
        self.WaterInNode = 0
        self.WaterOutNode = 0
        self.HCOPFTemp = 0
        self.HCOPFTempErrorIndex = 0
        self.HCOPFAirFlow = 0
        self.HCOPFAirFlowErrorIndex = 0
        self.HCOPFWaterFlow = 0
        self.HCOPFWaterFlowErrorIndex = 0
        self.HCapFTemp = 0
        self.HCapFTempErrorIndex = 0
        self.HCapFAirFlow = 0
        self.HCapFAirFlowErrorIndex = 0
        self.HCapFWaterFlow = 0
        self.HCapFWaterFlowErrorIndex = 0
        self.RatedInletDBTemp = 0.0
        self.RatedInletWBTemp = 0.0
        self.RatedInletWaterTemp = 0.0
        self.HPWHCondPumpElecNomPower = 0.0
        self.HPWHCondPumpFracToWater = 0.0
        self.RatedHPWHCondWaterFlow = 0.0
        self.ElecWaterHeatingPower = 0.0
        self.ElecWaterHeatingConsumption = 0.0
        self.FanPowerIncludedInCOP = true
        self.CondPumpHeatInCapacity = false
        self.CondPumpPowerInCOP = false
        self.LowTempLast = 0.0
        self.HighTempLast = 0.0
        self.ErrIndex1 = 0
        self.ErrIndex2 = 0
        self.ErrIndex3 = 0
        self.ErrIndex4 = 0
        self.LowAmbErrIndex = 0
        self.HighAmbErrIndex = 0
        self.PLFErrIndex = 0
        self.PLRErrIndex = 0
        self.PrintLowAmbMessage = false
        self.PrintHighAmbMessage = false
        self.EvapWaterSupplyMode = EvapWaterSupply.FromMains
        self.EvapWaterSupTankID = 0
        self.EvapWaterTankDemandARRID = 0
        self.CondensateCollectMode = CondensateCollectAction.Discard
        self.CondensateTankID = 0
        self.CondensateTankSupplyARRID = 0
        self.CondensateVdot = 0.0
        self.CondensateVol = 0.0
        self.CurrentEndTimeLast = 0.0
        self.TimeStepSysLast = 0.0
        self.FuelType = Constant.eFuel.Invalid
        self.NumOfSpeeds = 0
        self.PLRImpact = false
        self.LatentImpact = false
        self.MSFuelWasteHeat = 0.0
        self.MSHPHeatRecActive = false
        self.MSHPDesignSpecIndex = 0
        self.CoolingCoilPresent = true
        self.HeatingCoilPresent = true
        self.ISHundredPercentDOASDXCoil = false
        self.SHRFTemp = Array1D_int(MaxModes, 0)
        self.SHRFTempErrorIndex = 0
        self.SHRFFlow = Array1D_int(MaxModes, 0)
        self.SHRFFlowErrorIndex = 0
        self.SHRFTemp2 = 0
        self.SHRFFlow2 = 0
        self.UserSHRCurveExists = false
        self.ASHRAE127StdRprt = false
        self.SecZonePtr = 0
        self.SecCoilSHRFT = 0
        self.SecCoilSHRFF = 0
        self.SecCoilAirFlow = 0.0
        self.SecCoilAirFlowScalingFactor = 1.0
        self.SecCoilRatedSHR = 1.0
        self.SecCoilSHR = 1.0
        self.EvapInletWetBulb = 0.0
        self.SecCoilSensibleHeatGainRate = 0.0
        self.SecCoilTotalHeatRemovalRate = 0.0
        self.SecCoilSensibleHeatRemovalRate = 0.0
        self.SecCoilLatentHeatRemovalRate = 0.0
        self.IsSecondaryDXCoilInZone = false
        self.IsDXCoilInZone = false
        self.CompressorPartLoadRatio = 0.0
        self.MSSpeedNumLS = 1
        self.MSSpeedNumHS = 2
        self.MSSpeedRatio = 0.0
        self.MSCycRatio = 0.0
        self.VRFIUPtr = 0
        self.VRFOUPtr = 0
        self.EvaporatingTemp = 4.0
        self.CondensingTemp = 40.0
        self.C1Te = 0.0
        self.C2Te = 0.0
        self.C3Te = 0.0
        self.C1Tc = 0.0
        self.C2Tc = 0.0
        self.C3Tc = 0.0
        self.SH = 0.0
        self.SC = 0.0
        self.ActualSH = 0.0
        self.ActualSC = 0.0
        self.RateBFVRFIUEvap = 0.0592
        self.RateBFVRFIUCond = 0.1360
        self.CAPFTErrIndex = 0
        self.EIRFTErrIndex = 0
        self.reportCoilFinalSizes = true
        self.capModFacTotal = 0.0
        self.AirLoopNum = 0
}
struct PerfModeData:
    var FieldNames: Array1D[String]
    def __init__(inout self):
        self.FieldNames = Array1D[String]()
struct DXCoilNumericFieldData:
    var PerfMode: Array1D[PerfModeData] # Coil Performance object type
    def __init__(inout self):
        self.PerfMode = Array1D[PerfModeData](0)
def SimDXCoil(
    inout state: EnergyPlusData,
    CompName: StringView,            
    compressorOp: HVAC.CompressorOp, 
    FirstHVACIteration: Bool,        
    inout CompIndex: Int,
    fanOp: HVAC.FanOp,                                      
    PartLoadRatio: ObjexxFCL_Optional[Float64] = None,              
    OnOffAFR: ObjexxFCL_Optional[Float64] = None,                   
    CoilCoolingHeatingPLRRatio: ObjexxFCL_Optional[Float64] = None, 
    MaxCap: ObjexxFCL_Optional[Float64] = None,                     
    CompCyclingRatio: ObjexxFCL_Optional[Float64] = None            
)
{
    var DXCoilNum: Int       
    var AirFlowRatio: Float64 
    var CompCycRatio: Float64 
    if state.dataDXCoils.GetCoilsInputFlag:
        GetDXCoils(state)
        state.dataDXCoils.GetCoilsInputFlag = false 
    if CompIndex == 0:
        DXCoilNum = Util.FindItemInList(CompName, state.dataDXCoils.DXCoil)
        if DXCoilNum == 0:
            ShowFatalError(state, String("DX Coil not found={}").format(CompName))
        CompIndex = DXCoilNum
    else:
        DXCoilNum = CompIndex
        if DXCoilNum > state.dataDXCoils.NumDXCoils or DXCoilNum < 1:
            ShowFatalError(state,
                           String("SimDXCoil: Invalid CompIndex passed={}, Number of DX Coils={}, Coil name={}").format(
                               DXCoilNum, state.dataDXCoils.NumDXCoils, CompName))
        if state.dataDXCoils.CheckEquipName[DXCoilNum]:
            if not CompName.isEmpty() and CompName != state.dataDXCoils.DXCoil[DXCoilNum].Name:
                ShowFatalError(state,
                               String("SimDXCoil: Invalid CompIndex passed={}, Coil name={}, stored Coil Name for that index={}").format(
                                   DXCoilNum, CompName, state.dataDXCoils.DXCoil[DXCoilNum].Name))
            state.dataDXCoils.CheckEquipName[DXCoilNum] = false
    if OnOffAFR.is_some():
        AirFlowRatio = OnOffAFR.value()
    else:
        AirFlowRatio = 1.0
    if CompCyclingRatio.is_some():
        CompCycRatio = CompCyclingRatio.value()
    else:
        CompCycRatio = 1.0
    InitDXCoil(state, DXCoilNum)
    switch state.dataDXCoils.DXCoil[DXCoilNum].coilType: 
        case HVAC.CoilType.CoolingDXSingleSpeed:
            if CoilCoolingHeatingPLRRatio.is_some():
                CalcDoe2DXCoil(state, DXCoilNum, compressorOp, FirstHVACIteration, PartLoadRatio, fanOp, ObjexxFCL_Optional[Int](), AirFlowRatio, CoilCoolingHeatingPLRRatio)
            else:
                CalcDoe2DXCoil(state, DXCoilNum, compressorOp, FirstHVACIteration, PartLoadRatio, fanOp, ObjexxFCL_Optional[Int](), AirFlowRatio)
        case HVAC.CoilType.HeatingDXSingleSpeed:
            CalcDXHeatingCoil(state, DXCoilNum, PartLoadRatio, fanOp, AirFlowRatio)
        case HVAC.CoilType.WaterHeatingDXPumped:
        case HVAC.CoilType.WaterHeatingDXWrapped:
            CalcHPWHDXCoil(state, DXCoilNum, PartLoadRatio)
            CalcDoe2DXCoil(state, DXCoilNum, HVAC.CompressorOp.On, FirstHVACIteration, PartLoadRatio, fanOp)
        case HVAC.CoilType.CoolingVRF:
            CalcVRFCoolingCoil(state, DXCoilNum, HVAC.CompressorOp.On, FirstHVACIteration, PartLoadRatio, fanOp, CompCycRatio, ObjexxFCL_Optional[Int](), AirFlowRatio, MaxCap)
        case HVAC.CoilType.HeatingVRF:
            CalcDXHeatingCoil(state, DXCoilNum, PartLoadRatio, fanOp, AirFlowRatio, MaxCap)
        case HVAC.CoilType.CoolingVRFFluidTCtrl:
            CalcVRFCoolingCoil_FluidTCtrl(state, DXCoilNum, HVAC.CompressorOp.On, FirstHVACIteration, PartLoadRatio, fanOp, CompCycRatio, ObjexxFCL_Optional[Int](), ObjexxFCL_Optional[Float64](), MaxCap)
        case HVAC.CoilType.HeatingVRFFluidTCtrl:
            CalcVRFHeatingCoil_FluidTCtrl(state, compressorOp, DXCoilNum, PartLoadRatio, fanOp, ObjexxFCL_Optional[Float64](), MaxCap)
        default:
            ShowSevereError(state, String("Error detected in DX Coil={}").format(CompName))
            ShowContinueError(state, String("Invalid DX Coil Type={}").format(HVAC.coilTypeNames[int(state.dataDXCoils.DXCoil[DXCoilNum].coilType)]))
            ShowFatalError(state, "Preceding condition causes termination.")
    UpdateDXCoil(state, DXCoilNum)
    ReportDXCoil(state, DXCoilNum)
}