# Converted from C++ to Mojo - Faithful 1:1 translation

from builtin import debug_assert, String, List, Bool, Int, Float64, Tuple
from sys import to_standard_system  # for format?
# Import necessary modules from EnergyPlus (assumed to be at same relative path)
from DataAirSystems import HVAC  # includes CoilType, FanType, etc.
from DataSizing import DataSizing
from Psychrometrics import PsyTwbFnTdbWPb, PsyHFnTdbW, PsyRhFnTdbWPb, PsyCpAirFnW, PsyTdpFnWPb, PsyWFnTdpPb
from Fans import Fans
from OutputReportPredefined import OutputReportPredefined
from PlantUtilities import PlantUtilities
from UtilityRoutines import Util, ShowWarningError, SameString
from FluidProperties import FluidProperties  # but we access glyph-> etc - we'll assume methods exist
from DataEnvironment import state_dataEnvrn  # not sure actual import
from DataHeatBalance import state_dataHeatBal
from DataAirLoop import state_dataAirLoop
from DataZoneEquipment import DataZoneEquipment
from MixedAir import MixedAir
from BoilerSteam import state_dataBoilerSteam
from AirLoopHVACDOAS import state_dataAirLoopHVACDOAS
from DataHVACGlobals import state_dataHVACGlobal
from Constant import Constant
from WeatherManager import state_dataWeather
from Psychrometrics import Psychrometrics  # if needed

# The following are from the base data, assume they are imported in state
# We'll use pointer to state as in C++? In Mojo, we'll have a global EnergyPlusData struct.
# For simplicity, we assume state is an object with nested data structures.
# We'll not define all the sub-structures here, just use them as given.

# Forward declaration of CoilSelectionData class
class CoilSelectionData:
    var coilName_: String
    var coilType: HVAC.CoilType
    var isCooling: Bool
    var isHeating: Bool
    var coilLocation: String
    var desDayNameAtSensPeak: String
    var coilSensePeakHrMin: String
    var desDayNameAtTotalPeak: String
    var coilTotalPeakHrMin: String
    var desDayNameAtAirFlowPeak: String
    var airPeakHrMin: String
    var coilNum: Int
    var airloopNum: Int
    var oaControllerNum: Int
    var zoneEqNum: Int
    var oASysNum: Int
    var zoneNum: List[Int]
    var zoneName: List[String]
    var typeHVACname: String
    var userNameforHVACsystem: String
    var zoneHVACTypeNum: Int
    var zoneHVACIndex: Int
    var typeof_Coil: Int
    var coilSizingMethodConcurrence: DataSizing.CoilSizingConcurrence
    var coilSizingMethodConcurrenceName: String
    var coilSizingMethodCapacity: Int
    var coilSizingMethodCapacityName: String
    var coilSizingMethodAirFlow: Int
    var coilSizingMethodAirFlowName: String
    var isCoilSizingForTotalLoad: Bool
    var coilPeakLoadTypeToSizeOnName: String
    var capIsAutosized: Bool
    var coilCapAutoMsg: String
    var volFlowIsAutosized: Bool
    var coilVolFlowAutoMsg: String
    var coilWaterFlowUser: Float64
    var coilWaterFlowAutoMsg: String
    var oaPretreated: Bool
    var coilOAPretreatMsg: String
    var isSupplementalHeater: Bool
    var coilTotCapFinal: Float64
    var coilSensCapFinal: Float64
    var coilRefAirVolFlowFinal: Float64
    var coilRefWaterVolFlowFinal: Float64
    var coilTotCapAtPeak: Float64
    var coilSensCapAtPeak: Float64
    var coilDesMassFlow: Float64
    var coilDesVolFlow: Float64
    var coilDesEntTemp: Float64
    var coilDesEntWetBulb: Float64
    var coilDesEntHumRat: Float64
    var coilDesEntEnth: Float64
    var coilDesLvgTemp: Float64
    var coilDesLvgWetBulb: Float64
    var coilDesLvgHumRat: Float64
    var coilDesLvgEnth: Float64
    var coilDesWaterMassFlow: Float64
    var coilDesWaterEntTemp: Float64
    var coilDesWaterLvgTemp: Float64
    var coilDesWaterTempDiff: Float64
    var pltSizNum: Int
    var waterLoopNum: Int
    var plantLoopName: String
    var oaPeakTemp: Float64
    var oaPeakHumRat: Float64
    var oaPeakWetBulb: Float64
    var oaPeakVolFlow: Float64
    var oaPeakVolFrac: Float64
    var oaDoaTemp: Float64
    var oaDoaHumRat: Float64
    var raPeakTemp: Float64
    var raPeakHumRat: Float64
    var rmPeakTemp: Float64
    var rmPeakHumRat: Float64
    var rmPeakRelHum: Float64
    var rmSensibleAtPeak: Float64
    var rmLatentAtPeak: Float64
    var coilIdealSizCapOverSimPeakCap: Float64
    var coilIdealSizCapUnderSimPeakCap: Float64
    var reheatLoadMult: Float64
    var minRatio: Float64
    var maxRatio: Float64
    var cpMoistAir: Float64
    var cpDryAir: Float64
    var rhoStandAir: Float64
    var rhoFluid: Float64
    var cpFluid: Float64
    var coilCapFTIdealPeak: Float64
    var coilRatedTotCap: Float64
    var coilRatedSensCap: Float64
    var ratedAirMassFlow: Float64
    var ratedCoilInDb: Float64
    var ratedCoilInWb: Float64
    var ratedCoilInHumRat: Float64
    var ratedCoilInEnth: Float64
    var ratedCoilOutDb: Float64
    var ratedCoilOutWb: Float64
    var ratedCoilOutHumRat: Float64
    var ratedCoilOutEnth: Float64
    var ratedCoilEff: Float64
    var ratedCoilBpFactor: Float64
    var ratedCoilAppDewPt: Float64
    var ratedCoilOadbRef: Float64
    var ratedCoilOawbRef: Float64
    var fanAssociatedWithCoilName: String
    var fanTypeName: String
    var supFanType: HVAC.FanType
    var supFanNum: Int
    var fanSizeMaxAirVolumeFlow: Float64
    var fanSizeMaxAirMassFlow: Float64
    var fanHeatGainIdealPeak: Float64
    var coilAndFanNetTotalCapacityIdealPeak: Float64
    var plantDesMaxMassFlowRate: Float64
    var plantDesRetTemp: Float64
    var plantDesSupTemp: Float64
    var plantDesDeltaTemp: Float64
    var plantDesCapacity: Float64
    var coilCapPrcntPlantCap: Float64
    var coilFlowPrcntPlantFlow: Float64
    var coilUA: Float64

    def __init__(inout self, coilName: String):
        self.coilName_ = coilName
        self.isCooling = False
        self.isHeating = False
        self.coilNum = -999
        self.airloopNum = -999
        self.oaControllerNum = -999
        self.zoneEqNum = -999
        self.oASysNum = -999
        self.zoneHVACTypeNum = 0
        self.zoneHVACIndex = 0
        self.typeof_Coil = -999
        self.coilSizingMethodCapacity = -999
        self.coilSizingMethodAirFlow = -999
        self.isCoilSizingForTotalLoad = False
        self.capIsAutosized = False
        self.volFlowIsAutosized = False
        self.coilWaterFlowUser = -999.0
        self.oaPretreated = False
        self.isSupplementalHeater = False
        self.coilTotCapFinal = -999.0
        self.coilSensCapFinal = -999.0
        self.coilRefAirVolFlowFinal = -999.0
        self.coilRefWaterVolFlowFinal = -999.0
        self.coilTotCapAtPeak = -999.0
        self.coilSensCapAtPeak = -999.0
        self.coilDesMassFlow = -999.0
        self.coilDesVolFlow = -999.0
        self.coilDesEntTemp = -999.0
        self.coilDesEntWetBulb = -999.0
        self.coilDesEntHumRat = -999.0
        self.coilDesEntEnth = -999.0
        self.coilDesLvgTemp = -999.0
        self.coilDesLvgWetBulb = -999.0
        self.coilDesLvgHumRat = -999.0
        self.coilDesLvgEnth = -999.0
        self.coilDesWaterMassFlow = -999.0
        self.coilDesWaterEntTemp = -999.0
        self.coilDesWaterLvgTemp = -999.0
        self.coilDesWaterTempDiff = -999.0
        self.pltSizNum = -999
        self.waterLoopNum = -999
        self.oaPeakTemp = -999.0
        self.oaPeakHumRat = -999.0
        self.oaPeakWetBulb = -999.0
        self.oaPeakVolFlow = -999.0
        self.oaPeakVolFrac = -999.0
        self.oaDoaTemp = -999.0
        self.oaDoaHumRat = -999.0
        self.raPeakTemp = -999.0
        self.raPeakHumRat = -999.0
        self.rmPeakTemp = -999.0
        self.rmPeakHumRat = -999.0
        self.rmPeakRelHum = -999.0
        self.rmSensibleAtPeak = -999.0
        self.rmLatentAtPeak = 0.0
        self.coilIdealSizCapOverSimPeakCap = -999.0
        self.coilIdealSizCapUnderSimPeakCap = -999.0
        self.reheatLoadMult = -999.0
        self.minRatio = -999.0
        self.maxRatio = -999.0
        self.cpMoistAir = -999.0
        self.cpDryAir = -999.0
        self.rhoStandAir = -999.0
        self.rhoFluid = -999.0
        self.cpFluid = -999.0
        self.coilCapFTIdealPeak = 1.0
        self.coilRatedTotCap = -999.0
        self.coilRatedSensCap = -999.0
        self.ratedAirMassFlow = -999.0
        self.ratedCoilInDb = -999.0
        self.ratedCoilInWb = -999.0
        self.ratedCoilInHumRat = -999.0
        self.ratedCoilInEnth = -999.0
        self.ratedCoilOutDb = -999.0
        self.ratedCoilOutWb = -999.0
        self.ratedCoilOutHumRat = -999.0
        self.ratedCoilOutEnth = -999.0
        self.ratedCoilEff = -999.0
        self.ratedCoilBpFactor = -999.0
        self.ratedCoilAppDewPt = -999.0
        self.ratedCoilOadbRef = -999.0
        self.ratedCoilOawbRef = -999.0
        self.supFanType = HVAC.FanType.Invalid
        self.supFanNum = 0
        self.fanSizeMaxAirVolumeFlow = -999.0
        self.fanSizeMaxAirMassFlow = -999.0
        self.fanHeatGainIdealPeak = -999.0
        self.coilAndFanNetTotalCapacityIdealPeak = -999.0
        self.plantDesMaxMassFlowRate = -999.0
        self.plantDesRetTemp = -999.0
        self.plantDesSupTemp = -999.0
        self.plantDesDeltaTemp = -999.0
        self.plantDesCapacity = -999.0
        self.coilCapPrcntPlantCap = -999.0
        self.coilFlowPrcntPlantFlow = -999.0
        self.coilUA = -999.0

        # Additional string initializations
        self.coilLocation = "unknown"
        self.desDayNameAtSensPeak = "unknown"
        self.coilSensePeakHrMin = "unknown"
        self.desDayNameAtTotalPeak = "unknown"
        self.coilTotalPeakHrMin = "unknown"
        self.desDayNameAtAirFlowPeak = "unknown"
        self.airPeakHrMin = "unknown"
        self.typeHVACname = "unknown"
        self.userNameforHVACsystem = "unknown"
        self.coilSizingMethodConcurrenceName = "N/A"
        self.coilSizingMethodCapacityName = "N/A"
        self.coilSizingMethodAirFlowName = "N/A"
        self.coilPeakLoadTypeToSizeOnName = "N/A"
        self.coilCapAutoMsg = "unknown"
        self.coilVolFlowAutoMsg = "unknown"
        self.coilWaterFlowAutoMsg = "unknown"
        self.coilOAPretreatMsg = "unknown"
        self.plantLoopName = "unknown"
        self.fanAssociatedWithCoilName = "unknown"
        self.fanTypeName = "unknown"

# Free functions in namespace ReportCoilSelection
def finishCoilSummaryReportTable(inout state: EnergyPlusData):
    doFinalProcessingOfCoilData(state)
    writeCoilSelectionOutput(state)
    writeCoilSelectionOutput2(state)

def writeCoilSelectionOutput(inout state: EnergyPlusData):
    for c in state.dataRptCoilSelection.coils:
        c = c  # c is reference
        OutputReportPredefined.PreDefTableEntry(
            state, state.dataOutRptPredefined.pdchCoilType, c.coilName_, HVAC.coilTypeNames[int(c.coilType)])
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilLocation, c.coilName_, c.coilLocation)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilHVACType, c.coilName_, c.typeHVACname)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilHVACName, c.coilName_, c.userNameforHVACsystem)
        if c.isHeating:
            OutputReportPredefined.PreDefTableEntry(
                state, state.dataOutRptPredefined.pdchHeatCoilUsedAsSupHeat, c.coilName_, "Yes" if c.isSupplementalHeater else "No")
            airloopName: String
            if c.airloopNum > 0 and c.airloopNum <= int(state.dataHVACGlobal.NumPrimaryAirSys) and len(state.dataAirSystemsData.PrimaryAirSystems) >= c.airloopNum:
                airloopName = state.dataAirSystemsData.PrimaryAirSystems[c.airloopNum - 1].Name
            else:
                airloopName = "N/A"
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchHeatCoilAirloopName, c.coilName_, airloopName)
            plantLoopName: String
            if c.waterLoopNum > 0 and len(state.dataPlnt.PlantLoop) >= c.waterLoopNum:
                plantLoopName = state.dataPlnt.PlantLoop[c.waterLoopNum - 1].Name
            else:
                plantLoopName = "N/A"
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchHeatCoilPlantloopName, c.coilName_, plantLoopName)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilName_CCs, c.coilName_, c.coilName_)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilType_CCs, c.coilName_, HVAC.coilTypeNames[int(c.coilType)])
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilLoc_CCs, c.coilName_, c.coilLocation)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilHVACType_CCs, c.coilName_, c.typeHVACname)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilHVACName_CCs, c.coilName_, c.userNameforHVACsystem)
        if len(c.zoneName) == 1:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilZoneName, c.coilName_, c.zoneName[0])
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilZoneNames_CCs, c.coilName_, c.zoneName[0])
        elif len(c.zoneName) > 1:
            var tmpZoneList: String = ""
            for vecLoop in c.zoneName:
                tmpZoneList += vecLoop + "; "
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilZoneName, c.coilName_, tmpZoneList)
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilZoneNames_CCs, c.coilName_, tmpZoneList)
        else:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilZoneName, c.coilName_, "N/A")
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilZoneNames_CCs, c.coilName_, "N/A")
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchSysSizingMethCoinc, c.coilName_, c.coilSizingMethodConcurrenceName)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchSysSizingMethCap, c.coilName_, c.coilSizingMethodCapacityName)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchSysSizingMethAir, c.coilName_, c.coilSizingMethodAirFlowName)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilIsCapAutosized, c.coilName_, c.coilCapAutoMsg)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilIsAirFlowAutosized, c.coilName_, c.coilVolFlowAutoMsg)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilIsWaterFlowAutosized, c.coilName_, c.coilWaterFlowAutoMsg)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilIsOATreated, c.coilName_, c.coilOAPretreatMsg)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilFinalTotalCap, c.coilName_, c.coilTotCapFinal, 3)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilFinalSensCap, c.coilName_, c.coilSensCapFinal, 3)
        if c.coilRefAirVolFlowFinal == -999.0 or c.coilRefAirVolFlowFinal == -99999.0:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilFinalAirVolFlowRate, c.coilName_, c.coilRefAirVolFlowFinal, 1)
        else:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilFinalAirVolFlowRate, c.coilName_, c.coilRefAirVolFlowFinal, 6)
        if c.coilRefWaterVolFlowFinal == -999.0 or c.coilRefWaterVolFlowFinal == -99999.0:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilFinalPlantVolFlowRate, c.coilName_, c.coilRefWaterVolFlowFinal, 1)
        else:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilFinalPlantVolFlowRate, c.coilName_, c.coilRefWaterVolFlowFinal, 8)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchFanAssociatedWithCoilName, c.coilName_, c.fanAssociatedWithCoilName)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilSupFanName_CCs, c.coilName_, c.fanAssociatedWithCoilName)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchFanAssociatedWithCoilType, c.coilName_, c.fanTypeName)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilSupFanType_CCs, c.coilName_, c.fanTypeName)
        if c.fanSizeMaxAirVolumeFlow == -999.0 or c.fanSizeMaxAirVolumeFlow == -99999.0:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchFanAssociatedVdotSize, c.coilName_, c.fanSizeMaxAirVolumeFlow, 1)
        else:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchFanAssociatedVdotSize, c.coilName_, c.fanSizeMaxAirVolumeFlow, 6)
        if c.fanSizeMaxAirMassFlow == -999.0 or c.fanSizeMaxAirMassFlow == -99999.0:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchFanAssociatedMdotSize, c.coilName_, c.fanSizeMaxAirMassFlow, 1)
        else:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchFanAssociatedMdotSize, c.coilName_, c.fanSizeMaxAirMassFlow, 8)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilPlantName_CCs, c.coilName_, c.plantLoopName)
        airloopName2: String
        if c.airloopNum > 0 and c.airloopNum <= int(state.dataHVACGlobal.NumPrimaryAirSys) and len(state.dataAirSystemsData.PrimaryAirSystems) >= c.airloopNum:
            airloopName2 = state.dataAirSystemsData.PrimaryAirSystems[c.airloopNum - 1].Name
        else:
            airloopName2 = "N/A"
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilAirloopName_CCs, c.coilName_, airloopName2)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilPlantloopName_CCs, c.coilName_, c.plantLoopName)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilDDnameSensIdealPeak, c.coilName_, c.desDayNameAtSensPeak)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilDateTimeSensIdealPeak, c.coilName_, c.coilSensePeakHrMin)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilDDnameTotIdealPeak, c.coilName_, c.desDayNameAtTotalPeak)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilDateTimeTotIdealPeak, c.coilName_, c.coilTotalPeakHrMin)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilDDnameAirFlowIdealPeak, c.coilName_, c.desDayNameAtAirFlowPeak)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilDateTimeAirFlowIdealPeak, c.coilName_, c.airPeakHrMin)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilPeakLoadTypeToSizeOn, c.coilName_, c.coilPeakLoadTypeToSizeOnName)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilTotalCapIdealPeak, c.coilName_, c.coilTotCapAtPeak, 2)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilSensCapIdealPeak, c.coilName_, c.coilSensCapAtPeak, 2)
        if c.coilDesMassFlow == -999.0 or c.coilDesMassFlow == -99999.0:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilAirMassFlowIdealPeak, c.coilName_, c.coilDesMassFlow, 1)
        else:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilAirMassFlowIdealPeak, c.coilName_, c.coilDesMassFlow, 8)
        if c.coilDesVolFlow == -999.0 or c.coilDesVolFlow == -99999.0:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilAirVolumeFlowIdealPeak, c.coilName_, c.coilDesVolFlow, 1)
        else:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilAirVolumeFlowIdealPeak, c.coilName_, c.coilDesVolFlow, 6)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilEntDryBulbIdealPeak, c.coilName_, c.coilDesEntTemp, 2)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilEntWetBulbIdealPeak, c.coilName_, c.coilDesEntWetBulb, 2)
        if c.coilDesEntHumRat == -999.0 or c.coilDesEntHumRat == -99999.0:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilEntHumRatIdealPeak, c.coilName_, c.coilDesEntHumRat, 1)
        else:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilEntHumRatIdealPeak, c.coilName_, c.coilDesEntHumRat, 8)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilEntEnthalpyIdealPeak, c.coilName_, c.coilDesEntEnth, 1)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilLvgDryBulbIdealPeak, c.coilName_, c.coilDesLvgTemp, 2)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilLvgWetBulbIdealPeak, c.coilName_, c.coilDesLvgWetBulb, 2)
        if c.coilDesLvgHumRat == -999.0 or c.coilDesLvgHumRat == -99999.0:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilLvgHumRatIdealPeak, c.coilName_, c.coilDesLvgHumRat, 1)
        else:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilLvgHumRatIdealPeak, c.coilName_, c.coilDesLvgHumRat, 8)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilLvgEnthalpyIdealPeak, c.coilName_, c.coilDesLvgEnth, 1)
        if c.coilDesWaterMassFlow == -999.0 or c.coilDesWaterMassFlow == -99999.0:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilWaterMassFlowIdealPeak, c.coilName_, c.coilDesWaterMassFlow, 1)
        else:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilWaterMassFlowIdealPeak, c.coilName_, c.coilDesWaterMassFlow, 8)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilEntWaterTempIdealPeak, c.coilName_, c.coilDesWaterEntTemp, 2)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilLvgWaterTempIdealPeak, c.coilName_, c.coilDesWaterLvgTemp, 2)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilWaterDeltaTempIdealPeak, c.coilName_, c.coilDesWaterTempDiff, 2)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchFanHeatGainIdealPeak, c.coilName_, c.fanHeatGainIdealPeak, 3)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilNetTotalCapacityIdealPeak, c.coilName_, c.coilAndFanNetTotalCapacityIdealPeak, 2)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilRatedTotalCap, c.coilName_, c.coilRatedTotCap, 2)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilRatedSensCap, c.coilName_, c.coilRatedSensCap, 2)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilOffRatingCapacityModifierIdealPeak, c.coilName_, c.coilCapFTIdealPeak, 4)
        if c.ratedAirMassFlow == -999.0 or c.ratedAirMassFlow == -99999.0:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilRatedAirMass, c.coilName_, c.ratedAirMassFlow, 1)
        else:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilRatedAirMass, c.coilName_, c.ratedAirMassFlow, 8)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilRatedEntDryBulb, c.coilName_, c.ratedCoilInDb, 2)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilRatedEntWetBulb, c.coilName_, c.ratedCoilInWb, 2)
        if c.ratedCoilInHumRat == -999.0 or c.ratedCoilInHumRat == -99999.0:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilRatedEntHumRat, c.coilName_, c.ratedCoilInHumRat, 1)
        else:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilRatedEntHumRat, c.coilName_, c.ratedCoilInHumRat, 8)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilRatedEntEnthalpy, c.coilName_, c.ratedCoilInEnth, 1)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilRatedLvgDryBulb, c.coilName_, c.ratedCoilOutDb, 2)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilRatedLvgWetBulb, c.coilName_, c.ratedCoilOutWb, 2)
        if c.ratedCoilOutHumRat == -999.0 or c.ratedCoilOutHumRat == -99999.0:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilRatedLvgHumRat, c.coilName_, c.ratedCoilOutHumRat, 1)
        else:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilRatedLvgHumRat, c.coilName_, c.ratedCoilOutHumRat, 8)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilRatedLvgEnthalpy, c.coilName_, c.ratedCoilOutEnth, 1)
        if c.plantDesMaxMassFlowRate == -999.0 or c.plantDesMaxMassFlowRate == -99999.0:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchPlantMassFlowMaximum, c.coilName_, c.plantDesMaxMassFlowRate, 1)
        else:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchPlantMassFlowMaximum, c.coilName_, c.plantDesMaxMassFlowRate, 8)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchPlantRetTempDesign, c.coilName_, c.plantDesRetTemp, 2)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchPlantSupTempDesign, c.coilName_, c.plantDesSupTemp, 2)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchPlantDeltaTempDesign, c.coilName_, c.plantDesDeltaTemp, 2)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchPlantCapacity, c.coilName_, c.plantDesCapacity, 2)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilCapPrcntPlantCapacity, c.coilName_, c.coilCapPrcntPlantCap, 4)
        if c.coilFlowPrcntPlantFlow == -999.0 or c.coilFlowPrcntPlantFlow == -99999.0:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilFlowPrcntPlantFlow, c.coilName_, c.coilFlowPrcntPlantFlow, 1)
        else:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilFlowPrcntPlantFlow, c.coilName_, c.coilFlowPrcntPlantFlow, 6)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchOADryBulbIdealPeak, c.coilName_, c.oaPeakTemp, 2)
        if c.oaPeakHumRat == -999.0 or c.oaPeakHumRat == -99999.0:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchOAHumRatIdealPeak, c.coilName_, c.oaPeakHumRat, 1)
        else:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchOAHumRatIdealPeak, c.coilName_, c.oaPeakHumRat, 8)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchOAWetBulbatIdealPeak, c.coilName_, c.oaPeakWetBulb, 2)
        if c.oaPeakVolFlow == -999.0 or c.oaPeakVolFlow == -99999.0:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchOAVolFlowIdealPeak, c.coilName_, c.oaPeakVolFlow, 1)
        else:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchOAVolFlowIdealPeak, c.coilName_, c.oaPeakVolFlow, 8)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchOAFlowPrcntIdealPeak, c.coilName_, c.oaPeakVolFrac, 4)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchAirSysRADryBulbIdealPeak, c.coilName_, c.raPeakTemp, 2)
        if c.raPeakHumRat == -999.0 or c.raPeakHumRat == -99999.0:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchAirSysRAHumRatIdealPeak, c.coilName_, c.raPeakHumRat, 1)
        else:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchAirSysRAHumRatIdealPeak, c.coilName_, c.raPeakHumRat, 8)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchZoneAirDryBulbIdealPeak, c.coilName_, c.rmPeakTemp, 2)
        if c.rmPeakHumRat == -999.0 or c.rmPeakHumRat == -99999.0:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchZoneAirHumRatIdealPeak, c.coilName_, c.rmPeakHumRat, 1)
        else:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchZoneAirHumRatIdealPeak, c.coilName_, c.rmPeakHumRat, 8)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchZoneAirRelHumIdealPeak, c.coilName_, c.rmPeakRelHum, 4)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchCoilUA, c.coilName_, c.coilUA, 3)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchZoneSensibleLoadIdealPeak, c.coilName_, c.rmSensibleAtPeak, 2)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchZoneLatentLoadIdealPeak, c.coilName_, c.rmLatentAtPeak)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchReheatCoilMultiplier, c.coilName_, c.reheatLoadMult, 4)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchFlowCapRatioLowCapIncreaseRatio, c.coilName_, c.maxRatio, 5)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchFlowCapRatioHiCapDecreaseRatio, c.coilName_, c.minRatio, 5)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchPlantFluidSpecificHeat, c.coilName_, c.cpFluid, 4)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchPlantFluidDensity, c.coilName_, c.rhoFluid, 4)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchMoistAirSpecificHeat, c.coilName_, c.cpMoistAir, 4)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchDryAirSpecificHeat, c.coilName_, c.cpDryAir, 4)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdchStandRhoAir, c.coilName_, c.rhoStandAir, 4)

def writeCoilSelectionOutput2(inout state: EnergyPlusData):
    for c in state.dataRptCoilSelection.coils:
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdch2CoilType, c.coilName_, HVAC.coilTypeNames[int(c.coilType)])
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdch2CoilHVACType, c.coilName_, c.typeHVACname)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdch2CoilHVACName, c.coilName_, c.userNameforHVACsystem)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdch2CoilFinalTotalCap, c.coilName_, c.coilTotCapFinal, 3)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdch2CoilFinalSensCap, c.coilName_, c.coilSensCapFinal, 3)
        if c.coilRefAirVolFlowFinal == -999.0 or c.coilRefAirVolFlowFinal == -99999.0:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdch2CoilFinalAirVolFlowRate, c.coilName_, c.coilRefAirVolFlowFinal, 1)
        else:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdch2CoilFinalAirVolFlowRate, c.coilName_, c.coilRefAirVolFlowFinal, 6)
        if c.coilRefWaterVolFlowFinal == -999.0 or c.coilRefWaterVolFlowFinal == -99999.0:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdch2CoilFinalPlantVolFlowRate, c.coilName_, c.coilRefWaterVolFlowFinal, 1)
        else:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdch2CoilFinalPlantVolFlowRate, c.coilName_, c.coilRefWaterVolFlowFinal, 8)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdch2CoilDDnameSensIdealPeak, c.coilName_, c.desDayNameAtSensPeak)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdch2CoilDateTimeSensIdealPeak, c.coilName_, c.coilSensePeakHrMin)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdch2CoilDDnameAirFlowIdealPeak, c.coilName_, c.desDayNameAtAirFlowPeak)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdch2CoilDateTimeAirFlowIdealPeak, c.coilName_, c.airPeakHrMin)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdch2CoilTotalCapIdealPeak, c.coilName_, c.coilTotCapAtPeak, 2)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdch2CoilSensCapIdealPeak, c.coilName_, c.coilSensCapAtPeak, 2)
        if c.coilDesVolFlow == -999.0 or c.coilDesVolFlow == -99999.0:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdch2CoilAirVolumeFlowIdealPeak, c.coilName_, c.coilDesVolFlow, 1)
        else:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdch2CoilAirVolumeFlowIdealPeak, c.coilName_, c.coilDesVolFlow, 6)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdch2CoilEntDryBulbIdealPeak, c.coilName_, c.coilDesEntTemp, 2)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdch2CoilEntWetBulbIdealPeak, c.coilName_, c.coilDesEntWetBulb, 2)
        if c.coilDesEntHumRat == -999.0 or c.coilDesEntHumRat == -99999.0:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdch2CoilEntHumRatIdealPeak, c.coilName_, c.coilDesEntHumRat, 1)
        else:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdch2CoilEntHumRatIdealPeak, c.coilName_, c.coilDesEntHumRat, 8)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdch2CoilLvgDryBulbIdealPeak, c.coilName_, c.coilDesLvgTemp, 2)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdch2CoilLvgWetBulbIdealPeak, c.coilName_, c.coilDesLvgWetBulb, 2)
        if c.coilDesLvgHumRat == -999.0 or c.coilDesLvgHumRat == -99999.0:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdch2CoilLvgHumRatIdealPeak, c.coilName_, c.coilDesLvgHumRat, 1)
        else:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdch2CoilLvgHumRatIdealPeak, c.coilName_, c.coilDesLvgHumRat, 8)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdch2CoilRatedTotalCap, c.coilName_, c.coilRatedTotCap, 2)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdch2CoilRatedSensCap, c.coilName_, c.coilRatedSensCap, 2)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdch2OADryBulbIdealPeak, c.coilName_, c.oaPeakTemp, 2)
        if c.oaPeakHumRat == -999.0 or c.oaPeakHumRat == -99999.0:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdch2OAHumRatIdealPeak, c.coilName_, c.oaPeakHumRat, 1)
        else:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdch2OAHumRatIdealPeak, c.coilName_, c.oaPeakHumRat, 8)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdch2OAWetBulbatIdealPeak, c.coilName_, c.oaPeakWetBulb, 2)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdch2OAFlowPrcntIdealPeak, c.coilName_, c.oaPeakVolFrac, 4)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdch2ZoneAirDryBulbIdealPeak, c.coilName_, c.rmPeakTemp, 2)
        if c.rmPeakHumRat == -999.0 or c.rmPeakHumRat == -99999.0:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdch2ZoneAirHumRatIdealPeak, c.coilName_, c.rmPeakHumRat, 1)
        else:
            OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdch2ZoneAirHumRatIdealPeak, c.coilName_, c.rmPeakHumRat, 8)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdch2ZoneAirRelHumIdealPeak, c.coilName_, c.rmPeakRelHum, 4)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdch2CoilUA, c.coilName_, c.coilUA, 3)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdch2ZoneSensibleLoadIdealPeak, c.coilName_, c.rmSensibleAtPeak, 2)
        OutputReportPredefined.PreDefTableEntry(state, state.dataOutRptPredefined.pdch2ZoneLatentLoadIdealPeak, c.coilName_, c.rmLatentAtPeak)

def setCoilFinalSizes(inout state: EnergyPlusData,
                     coilNum: Int,
                     totGrossCap: Float64,
                     sensGrossCap: Float64,
                     airFlowRate: Float64,
                     waterFlowRate: Float64):
    debug_assert(coilNum >= 0 and coilNum < len(state.dataRptCoilSelection.coils))
    var c = state.dataRptCoilSelection.coils[coilNum]
    c.coilTotCapFinal = totGrossCap
    c.coilSensCapFinal = sensGrossCap
    c.coilRefAirVolFlowFinal = airFlowRate
    c.coilRefWaterVolFlowFinal = waterFlowRate

def doAirLoopSetup(inout state: EnergyPlusData, coilVecIndex: Int):
    var c = state.dataRptCoilSelection.coils[coilVecIndex]
    if c.airloopNum > 0 and c.airloopNum <= int(len(state.dataAirSystemsData.PrimaryAirSystems)):
        if state.dataAirSystemsData.PrimaryAirSystems[c.airloopNum - 1].OASysExists:
            for loop in range(1, state.dataMixedAir.NumOAControllers + 1):
                if state.dataAirSystemsData.PrimaryAirSystems[c.airloopNum - 1].OASysInletNodeNum == state.dataMixedAir.OAController[loop - 1].RetNode:
                    c.oaControllerNum = loop
        if len(state.dataAirLoop.AirToZoneNodeInfo) > 0:
            var atzni = state.dataAirLoop.AirToZoneNodeInfo[c.airloopNum - 1]
            if atzni.NumZonesCooled > 0:
                var zoneCount = atzni.NumZonesCooled
                c.zoneNum = List[Int](zoneCount)
                c.zoneName = List[String](zoneCount)
                for loopZone in range(1, atzni.NumZonesCooled + 1):
                    c.zoneNum[loopZone - 1] = atzni.CoolCtrlZoneNums[loopZone - 1]
                    c.zoneName[loopZone - 1] = state.dataHeatBal.Zone[c.zoneNum[loopZone - 1] - 1].Name
            if atzni.NumZonesHeated > 0:
                var zoneCount = atzni.NumZonesHeated
                for loopZone in range(1, zoneCount + 1):
                    var zoneIndex = atzni.HeatCtrlZoneNums[loopZone - 1]
                    var found = False
                    for z in c.zoneNum:
                        if z == zoneIndex:
                            found = True
                            break
                    if not found:
                        c.zoneNum.append(zoneIndex)
                        c.zoneName.append(state.dataHeatBal.Zone[zoneIndex - 1].Name)

def doZoneEqSetup(inout state: EnergyPlusData, coilNum: Int):
    debug_assert(coilNum >= 0 and coilNum < len(state.dataRptCoilSelection.coils))
    var c = state.dataRptCoilSelection.coils[coilNum]
    c.coilLocation = "Zone"
    c.zoneNum = List[Int](1)
    c.zoneNum[0] = c.zoneEqNum
    c.zoneName = List[String](1)
    c.zoneName[0] = state.dataHeatBal.Zone[c.zoneNum[0] - 1].Name
    c.typeHVACname = "Zone Equipment"
    if c.airloopNum > 0:
        if state.dataAirSystemsData.PrimaryAirSystems[c.airloopNum - 1].OASysExists:
            for loop in range(1, state.dataMixedAir.NumOAControllers + 1):
                if state.dataAirSystemsData.PrimaryAirSystems[c.airloopNum - 1].OASysInletNodeNum == state.dataMixedAir.OAController[loop - 1].RetNode:
                    c.oaControllerNum = loop
        var fan = state.dataFans.fans[state.dataAirSystemsData.PrimaryAirSystems[c.airloopNum - 1].supFanNum - 1]
        setCoilSupplyFanInfo(state, coilNum, fan.Name, fan.type, state.dataAirSystemsData.PrimaryAirSystems[c.airloopNum - 1].supFanNum)
    if c.zoneEqNum > 0:
        associateZoneCoilWithParent(state, c)

def doFinalProcessingOfCoilData(inout state: EnergyPlusData):
    for c in state.dataRptCoilSelection.coils:
        if c.zoneEqNum > 0:
            associateZoneCoilWithParent(state, c)
        if c.airloopNum > state.dataHVACGlobal.NumPrimaryAirSys and c.oASysNum > 0:
            c.coilLocation = "DOAS AirLoop"
            c.typeHVACname = "AirLoopHVAC:DedicatedOutdoorAirSystem"
            var DOASSysNum = state.dataAirLoop.OutsideAirSys[c.oASysNum - 1].AirLoopDOASNum
            c.userNameforHVACsystem = state.dataAirLoopHVACDOAS.airloopDOAS[DOASSysNum - 1].Name
        elif c.airloopNum > 0 and c.zoneEqNum == 0:
            c.coilLocation = "AirLoop"
            c.typeHVACname = "AirLoopHVAC"
            c.userNameforHVACsystem = state.dataAirSystemsData.PrimaryAirSystems[c.airloopNum - 1].Name
        elif c.zoneEqNum > 0 and c.airloopNum > 0:
            c.userNameforHVACsystem += " on air system named " + state.dataAirSystemsData.PrimaryAirSystems[c.airloopNum - 1].Name
            c.coilLocation = "Zone Equipment"
        if c.coilDesVolFlow > 0:
            c.oaPeakVolFrac = (c.oaPeakVolFlow / c.coilDesVolFlow) * 100.0
        else:
            c.oaPeakVolFrac = -999.0
        # Convert enum index to name (string assignment from enum names)
        c.coilSizingMethodConcurrenceName = DataSizing.CoilSizingConcurrenceNames[int(c.coilSizingMethodConcurrence)]
        if c.coilSizingMethodCapacity == DataSizing.CoolingDesignCapacity:
            c.coilSizingMethodCapacityName = "CoolingDesignCapacity"
        elif c.coilSizingMethodCapacity == DataSizing.HeatingDesignCapacity:
            c.coilSizingMethodCapacityName = "HeatingDesignCapacity"
        elif c.coilSizingMethodCapacity == DataSizing.CapacityPerFloorArea:
            c.coilSizingMethodCapacityName = "CapacityPerFloorArea"
        elif c.coilSizingMethodCapacity == DataSizing.FractionOfAutosizedCoolingCapacity:
            c.coilSizingMethodCapacityName = "FractionOfAutosizedCoolingCapacity"
        elif c.coilSizingMethodCapacity == DataSizing.FractionOfAutosizedHeatingCapacity:
            c.coilSizingMethodCapacityName = "FractionOfAutosizedHeatingCapacity"
        if c.coilSizingMethodAirFlow == DataSizing.SupplyAirFlowRate:
            c.coilSizingMethodAirFlowName = "SupplyAirFlowRate"
        elif c.coilSizingMethodAirFlow == DataSizing.FlowPerFloorArea:
            c.coilSizingMethodAirFlowName = "FlowPerFloorArea"
        elif c.coilSizingMethodAirFlow == DataSizing.FractionOfAutosizedCoolingAirflow:
            c.coilSizingMethodAirFlowName = "FractionOfAutosizedCoolingAirflow"
        elif c.coilSizingMethodAirFlow == DataSizing.FractionOfAutosizedHeatingAirflow:
            c.coilSizingMethodAirFlowName = "FractionOfAutosizedHeatingAirflow"
        if c.isCoilSizingForTotalLoad:
            c.coilPeakLoadTypeToSizeOnName = "Total"
        else:
            c.coilPeakLoadTypeToSizeOnName = "Sensible"
        if c.capIsAutosized:
            c.coilCapAutoMsg = "Yes"
        else:
            c.coilCapAutoMsg = "No"
        if c.volFlowIsAutosized:
            c.coilVolFlowAutoMsg = "Yes"
        else:
            c.coilVolFlowAutoMsg = "No"
        if c.oaPretreated:
            c.coilOAPretreatMsg = "Yes"
        else:
            c.coilOAPretreatMsg = "No"
        if c.coilDesEntTemp != -999.0 and c.coilDesEntHumRat != -999.0:
            c.coilDesEntWetBulb = Psychrometrics.PsyTwbFnTdbWPb(state, c.coilDesEntTemp, c.coilDesEntHumRat, state.dataEnvrn.StdBaroPress, "doFinalProcessingOfCoilData")
            if c.coilDesEntHumRat != -999.0:
                c.coilDesEntEnth = Psychrometrics.PsyHFnTdbW(c.coilDesEntTemp, c.coilDesEntHumRat)
        if c.oaPeakTemp != -999.0 and c.oaPeakHumRat != -999.0:
            c.oaPeakWetBulb = Psychrometrics.PsyTwbFnTdbWPb(state, c.oaPeakTemp, c.oaPeakHumRat, state.dataEnvrn.StdBaroPress, "doFinalProcessingOfCoilData")
        if c.waterLoopNum > 0 and c.pltSizNum > 0:
            c.plantLoopName = state.dataPlnt.PlantLoop[c.waterLoopNum - 1].Name
            if state.dataSize.PlantSizData[c.pltSizNum - 1].LoopType != DataSizing.TypeOfPlantLoop.Steam:
                c.rhoFluid = state.dataPlnt.PlantLoop[c.waterLoopNum - 1].glycol.getDensity(state, Constant.InitConvTemp, "doFinalProcessingOfCoilData")
                c.cpFluid = state.dataPlnt.PlantLoop[c.waterLoopNum - 1].glycol.getSpecificHeat(state, Constant.InitConvTemp, "doFinalProcessingOfCoilData")
            else:
                c.rhoFluid = state.dataPlnt.PlantLoop[c.waterLoopNum - 1].steam.getSatDensity(state, 100.0, 1.0, "doFinalProcessingOfCoilData")
                c.cpFluid = state.dataPlnt.PlantLoop[c.waterLoopNum - 1].steam.getSatSpecificHeat(state, 100.0, 0.0, "doFinalProcessingOfCoilData")
            c.plantDesMaxMassFlowRate = state.dataPlnt.PlantLoop[c.waterLoopNum - 1].MaxMassFlowRate
            if c.plantDesMaxMassFlowRate > 0.0 and c.coilDesWaterMassFlow > 0.0:
                c.coilFlowPrcntPlantFlow = (c.coilDesWaterMassFlow / c.plantDesMaxMassFlowRate) * 100.0
        var locFanType: HVAC.FanType = HVAC.F