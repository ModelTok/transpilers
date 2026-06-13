from gtest import Test, TestFixture, ExpectNear
from .Fixtures.EnergyPlusFixture import EnergyPlusFixture
from AirflowNetwork.Solver import *
from EnergyPlus.Data.EnergyPlusData import *
from EnergyPlus.DataEnvironment import *
from EnergyPlus.DataHVACGlobals import *
from EnergyPlus.DataHeatBalFanSys import *
from EnergyPlus.DataHeatBalSurface import *
from EnergyPlus.DataHeatBalance import *
from EnergyPlus.DataLoopNode import *
from EnergyPlus.DataPrecisionGlobals import *
from EnergyPlus.DataRoomAirModel import *
from EnergyPlus.DataSizing import *
from EnergyPlus.DataSurfaces import *
from EnergyPlus.DataZoneControls import *
from EnergyPlus.DataZoneEnergyDemands import *
from EnergyPlus.DataZoneEquipment import *
from EnergyPlus.HeatBalanceManager import *
from EnergyPlus.HybridModel import *
from EnergyPlus.ScheduleManager import *
from EnergyPlus.ZoneContaminantPredictorCorrector import *
from EnergyPlus.ZonePlenum import *
from EnergyPlus.ZoneTempPredictorCorrector import *

using EnergyPlus
using EnergyPlus.DataHeatBalance
using EnergyPlus.DataContaminantBalance
using EnergyPlus.DataHeatBalFanSys
using EnergyPlus.DataZoneControls
using EnergyPlus.DataZoneEquipment
using EnergyPlus.DataZoneEnergyDemands
using EnergyPlus.DataSizing
using EnergyPlus.HeatBalanceManager
using EnergyPlus.ZonePlenum
using EnergyPlus.ZoneTempPredictorCorrector
using EnergyPlus.ZoneContaminantPredictorCorrector
using EnergyPlus.DataSurfaces
using EnergyPlus.DataEnvironment
using EnergyPlus.Psychrometrics
using EnergyPlus.RoomAir
using EnergyPlus.HybridModel
using EnergyPlus.DataPrecisionGlobals

@fixture(EnergyPlusFixture)
class HybridModel_correctZoneAirTempsTest(Test):
    def run(self) raises:
        state.init_state(state)
        state.dataHeatBal.Zone.allocate(1)
        state.dataHybridModel.hybridModelZones.allocate(1)
        state.dataHybridModel.FlagHybridModel = True
        state.dataRoomAir.AirModel.allocate(1)
        state.dataRoomAir.ZTOC.allocate(1)
        state.dataRoomAir.ZTMX.allocate(1)
        state.dataRoomAir.ZTMMX.allocate(1)
        state.afn.exchangeData.allocate(1)
        state.dataLoopNodes.Node.allocate(1)
        state.dataHeatBalFanSys.TempTstatAir.allocate(1)
        state.dataHeatBalFanSys.LoadCorrectionFactor.allocate(1)
        state.dataHeatBalFanSys.PreviousMeasuredZT1.allocate(1)
        state.dataHeatBalFanSys.PreviousMeasuredZT2.allocate(1)
        state.dataHeatBalFanSys.PreviousMeasuredZT3.allocate(1)
        state.dataHeatBalFanSys.PreviousMeasuredHumRat1.allocate(1)
        state.dataHeatBalFanSys.PreviousMeasuredHumRat2.allocate(1)
        state.dataHeatBalFanSys.PreviousMeasuredHumRat3.allocate(1)
        state.dataSurface.SurfaceWindow.allocate(1)
        state.dataSurface.Surface.allocate(2)
        state.dataHeatBalSurf.SurfHConvInt.allocate(1)
        state.dataZoneEnergyDemand.ZoneSysEnergyDemand.allocate(1)
        state.dataRoomAir.IsZoneDispVent3Node.dimension(1, False)
        state.dataRoomAir.IsZoneCrossVent.dimension(1, False)
        state.dataRoomAir.IsZoneUFAD.dimension(1, False)
        state.dataRoomAir.ZoneDispVent3NodeMixedFlag.allocate(1)
        state.dataHeatBal.ZnAirRpt.allocate(1)
        state.dataZoneEquip.ZoneEquipConfig.allocate(1)
        state.dataHeatBal.ZoneIntGain.allocate(1)
        state.dataSize.ZoneEqSizing.allocate(1)
        state.dataHeatBalFanSys.SumLatentHTRadSys.allocate(1)
        state.dataHeatBalFanSys.SumLatentHTRadSys[0] = 0.0
        state.dataHeatBalFanSys.SumConvHTRadSys.allocate(1)
        state.dataHeatBalFanSys.SumConvHTRadSys[0] = 0.0
        state.dataHeatBalFanSys.SumConvPool.allocate(1)
        state.dataHeatBalFanSys.SumConvPool[0] = 0.0
        state.dataZoneTempPredictorCorrector.zoneHeatBalance.allocate(1)
        state.dataZoneTempPredictorCorrector.spaceHeatBalance.allocate(1)
        var thisZoneHB = state.dataZoneTempPredictorCorrector.zoneHeatBalance[0]
        thisZoneHB.MixingMassFlowXHumRat = 0.0
        thisZoneHB.MixingMassFlowZone = 0.0
        thisZoneHB.ZT = 0.0
        state.dataHeatBalFanSys.SumLatentPool.allocate(1)
        state.dataHeatBalFanSys.SumLatentPool[0] = 0.0
        state.dataContaminantBalance.AZ.allocate(1)
        state.dataContaminantBalance.BZ.allocate(1)
        state.dataContaminantBalance.CZ.allocate(1)
        state.dataContaminantBalance.AZGC.allocate(1)
        state.dataContaminantBalance.BZGC.allocate(1)
        state.dataContaminantBalance.CZGC.allocate(1)
        state.dataContaminantBalance.AZ[0] = 0.0
        state.dataContaminantBalance.BZ[0] = 0.0
        state.dataContaminantBalance.CZ[0] = 0.0
        state.dataContaminantBalance.AZGC[0] = 0.0
        state.dataContaminantBalance.BZGC[0] = 0.0
        state.dataContaminantBalance.CZGC[0] = 0.0
        state.dataContaminantBalance.ZoneAirDensityCO.allocate(1)
        state.dataContaminantBalance.ZoneAirDensityCO[0] = 0.0
        state.dataContaminantBalance.ZoneGCGain.allocate(1)
        state.dataContaminantBalance.ZoneGCGain[0] = 0.0
        state.dataGlobal.NumOfZones = 1
        state.dataSize.CurZoneEqNum = 1
        state.dataZonePlenum.NumZoneReturnPlenums = 0
        state.dataZonePlenum.NumZoneSupplyPlenums = 0
        state.dataHeatBal.Zone[0].IsControlled = True
        state.dataHeatBal.Zone[0].Multiplier = 1
        state.dataHeatBal.Zone[0].SystemZoneNodeNumber = 1
        state.dataHeatBal.space.allocate(1)
        state.dataHeatBal.spaceIntGainDevices.allocate(1)
        state.dataHeatBal.Zone[0].spaceIndexes.append(1)
        state.dataHeatBal.space[0].HTSurfaceFirst = 0
        state.dataHeatBal.space[0].HTSurfaceLast = -1
        state.dataHeatBal.Zone[0].Volume = 1061.88
        state.dataGlobal.TimeStepZone = 10.0 / 60.0
        state.dataHVACGlobal.TimeStepSys = 10.0 / 60.0
        state.dataHVACGlobal.TimeStepSysSec = state.dataHVACGlobal.TimeStepSys * Constant.rSecsInHour
        var ZoneTempChange: Float64
        state.dataHybridModel.FlagHybridModel_TM = True
        state.dataGlobal.WarmupFlag = False
        state.dataGlobal.DoingSizing = False
        state.dataEnvrn.DayOfYear = 1
        var hmZone = state.dataHybridModel.hybridModelZones[0]
        hmZone.InternalThermalMassCalc_T = True
        hmZone.InfiltrationCalc_T = False
        hmZone.InfiltrationCalc_H = False
        hmZone.InfiltrationCalc_C = False
        hmZone.PeopleCountCalc_T = False
        hmZone.PeopleCountCalc_H = False
        hmZone.PeopleCountCalc_C = False
        hmZone.HybridStartDayOfYear = 1
        hmZone.HybridEndDayOfYear = 2
        thisZoneHB.MAT = 0.0
        state.dataHeatBalFanSys.PreviousMeasuredZT1[0] = 0.1
        state.dataHeatBalFanSys.PreviousMeasuredZT2[0] = 0.2
        state.dataHeatBalFanSys.PreviousMeasuredZT3[0] = 0.3
        state.dataHeatBal.Zone[0].OutDryBulbTemp = -5.21
        thisZoneHB.airHumRat = 0.002083
        thisZoneHB.MCPV = 1414.60
        thisZoneHB.MCPTV = -3335.10
        state.dataEnvrn.OutBaroPress = 99166.67
        ZoneTempChange = correctZoneAirTemps(state, True)
        ExpectNear(15.13, state.dataHeatBal.Zone[0].ZoneVolCapMultpSensHM, 0.01)
        hmZone.InternalThermalMassCalc_T = False
        hmZone.InfiltrationCalc_T = True
        hmZone.InfiltrationCalc_H = False
        hmZone.InfiltrationCalc_C = False
        hmZone.PeopleCountCalc_T = False
        hmZone.PeopleCountCalc_H = False
        hmZone.PeopleCountCalc_C = False
        hmZone.HybridStartDayOfYear = 1
        hmZone.HybridEndDayOfYear = 2
        thisZoneHB.MAT = 0.0
        state.dataHeatBalFanSys.PreviousMeasuredZT1[0] = 0.02
        state.dataHeatBalFanSys.PreviousMeasuredZT2[0] = 0.04
        state.dataHeatBalFanSys.PreviousMeasuredZT3[0] = 0.06
        state.dataHeatBal.Zone[0].ZoneVolCapMultpSens = 8.0
        state.dataHeatBal.Zone[0].OutDryBulbTemp = -6.71
        thisZoneHB.airHumRat = 0.002083
        thisZoneHB.MCPV = 539.49
        thisZoneHB.MCPTV = 270.10
        state.dataEnvrn.OutBaroPress = 99250
        ZoneTempChange = correctZoneAirTemps(state, True)
        ExpectNear(0.2444, state.dataHeatBal.Zone[0].InfilOAAirChangeRateHM, 0.01)
        hmZone.InternalThermalMassCalc_T = False
        hmZone.InfiltrationCalc_T = False
        hmZone.InfiltrationCalc_H = True
        hmZone.InfiltrationCalc_C = False
        hmZone.PeopleCountCalc_T = False
        hmZone.PeopleCountCalc_H = False
        hmZone.PeopleCountCalc_C = False
        hmZone.HybridStartDayOfYear = 1
        hmZone.HybridEndDayOfYear = 2
        state.dataHeatBal.Zone[0].Volume = 4000
        state.dataHeatBal.Zone[0].OutDryBulbTemp = -10.62
        state.dataHeatBal.Zone[0].ZoneVolCapMultpMoist = 1.0
        thisZoneHB.airHumRat = 0.001120003
        thisZoneHB.ZT = -6.08
        state.dataEnvrn.OutHumRat = 0.0011366887816818931
        state.dataHeatBalFanSys.PreviousMeasuredHumRat1[0] = 0.0011186324286
        state.dataHeatBalFanSys.PreviousMeasuredHumRat2[0] = 0.0011172070768
        state.dataHeatBalFanSys.PreviousMeasuredHumRat3[0] = 0.0011155109625
        hmZone.measuredHumRatSched = Sched.AddScheduleConstant(state, "Measured HumRat 1")
        hmZone.measuredHumRatSched.currentVal = 0.001120003
        thisZoneHB.MCPV = 539.49
        thisZoneHB.MCPTV = 270.10
        state.dataEnvrn.OutBaroPress = 99500
        thisZoneHB.correctHumRat(state, 1)
        ExpectNear(0.5, state.dataHeatBal.Zone[0].InfilOAAirChangeRateHM, 0.01)
        hmZone.InternalThermalMassCalc_T = False
        hmZone.InfiltrationCalc_T = False
        hmZone.InfiltrationCalc_H = False
        hmZone.InfiltrationCalc_C = False
        hmZone.PeopleCountCalc_T = True
        hmZone.PeopleCountCalc_H = False
        hmZone.PeopleCountCalc_C = False
        hmZone.HybridStartDayOfYear = 1
        hmZone.HybridEndDayOfYear = 2
        thisZoneHB.MAT = -2.89
        state.dataHeatBalFanSys.PreviousMeasuredZT1[0] = -2.887415174
        state.dataHeatBalFanSys.PreviousMeasuredZT2[0] = -2.897557416
        state.dataHeatBalFanSys.PreviousMeasuredZT3[0] = -2.909294101
        state.dataHeatBal.Zone[0].ZoneVolCapMultpSens = 1.0
        state.dataHeatBal.Zone[0].OutDryBulbTemp = -6.71
        thisZoneHB.airHumRat = 0.0024964
        state.dataEnvrn.OutBaroPress = 98916.7
        thisZoneHB.MCPV = 5163.5
        thisZoneHB.MCPTV = -15956.8
        hmZone.measuredTempSched = Sched.AddScheduleConstant(state, "Measured Temp 1")
        hmZone.measuredTempSched.currentVal = -2.923892218
        ZoneTempChange = correctZoneAirTemps(state, True)
        ExpectNear(0, state.dataHeatBal.Zone[0].NumOccHM, 0.1)
        hmZone.InternalThermalMassCalc_T = False
        hmZone.InfiltrationCalc_T = False
        hmZone.InfiltrationCalc_H = False
        hmZone.InfiltrationCalc_C = False
        hmZone.PeopleCountCalc_T = False
        hmZone.PeopleCountCalc_H = True
        hmZone.PeopleCountCalc_C = False
        hmZone.HybridStartDayOfYear = 1
        hmZone.HybridEndDayOfYear = 2
        state.dataHeatBal.Zone[0].Volume = 4000
        state.dataHeatBal.Zone[0].OutDryBulbTemp = -10.62
        state.dataHeatBal.Zone[0].ZoneVolCapMultpMoist = 1.0
        thisZoneHB.airHumRat = 0.0024964
        thisZoneHB.ZT = -2.92
        state.dataEnvrn.OutHumRat = 0.0025365002784602363
        state.dataEnvrn.OutBaroPress = 98916.7
        thisZoneHB.OAMFL = 0.700812
        thisZoneHB.latentGain = 211.2
        thisZoneHB.latentGainExceptPeople = 0.0
        state.dataHeatBalFanSys.PreviousMeasuredHumRat1[0] = 0.002496356
        state.dataHeatBalFanSys.PreviousMeasuredHumRat2[0] = 0.002489048
        state.dataHeatBalFanSys.PreviousMeasuredHumRat3[0] = 0.002480404
        hmZone.measuredHumRatSched = Sched.GetSchedule(state, "MEASURED HUMRAT 1")
        hmZone.measuredHumRatSched.currentVal = 0.002506251487737
        thisZoneHB.correctHumRat(state, 1)
        ExpectNear(4, state.dataHeatBal.Zone[0].NumOccHM, 0.1)
        hmZone.InternalThermalMassCalc_T = False
        hmZone.InfiltrationCalc_T = True
        hmZone.InfiltrationCalc_H = False
        hmZone.InfiltrationCalc_C = False
        hmZone.PeopleCountCalc_T = False
        hmZone.PeopleCountCalc_H = False
        hmZone.PeopleCountCalc_C = False
        hmZone.IncludeSystemSupplyParameters = True
        hmZone.HybridStartDayOfYear = 1
        hmZone.HybridEndDayOfYear = 2
        thisZoneHB.MAT = 15.56
        state.dataHeatBalFanSys.PreviousMeasuredZT1[0] = 15.56
        state.dataHeatBalFanSys.PreviousMeasuredZT2[0] = 15.56
        state.dataHeatBalFanSys.PreviousMeasuredZT3[0] = 15.56
        state.dataHeatBal.Zone[0].ZoneVolCapMultpSens = 1.0
        state.dataHeatBal.Zone[0].OutDryBulbTemp = -10.62
        thisZoneHB.airHumRat = 0.0077647
        thisZoneHB.MCPV = 4456
        thisZoneHB.MCPTV = 60650
        state.dataEnvrn.OutBaroPress = 99500
        state.dataEnvrn.OutHumRat = 0.00113669
        hmZone.measuredTempSched = Sched.GetSchedule(state, "MEASURED TEMP 1")
        hmZone.supplyAirTempSched = Sched.AddScheduleConstant(state, "Supply Temp 1")
        hmZone.supplyAirMassFlowRateSched = Sched.AddScheduleConstant(state, "Mass Flow Rate 1")
        hmZone.measuredTempSched.currentVal = 15.56
        hmZone.supplyAirTempSched.currentVal = 50
        hmZone.supplyAirMassFlowRateSched.currentVal = 0.7974274
        ZoneTempChange = correctZoneAirTemps(state, True)
        ExpectNear(0.49, state.dataHeatBal.Zone[0].InfilOAAirChangeRateHM, 0.01)
        hmZone.InternalThermalMassCalc_T = False
        hmZone.InfiltrationCalc_T = False
        hmZone.InfiltrationCalc_H = True
        hmZone.InfiltrationCalc_C = False
        hmZone.PeopleCountCalc_T = False
        hmZone.PeopleCountCalc_H = False
        hmZone.PeopleCountCalc_C = False
        hmZone.IncludeSystemSupplyParameters = True
        hmZone.HybridStartDayOfYear = 1
        hmZone.HybridEndDayOfYear = 2
        state.dataHeatBal.Zone[0].Volume = 4000
        state.dataHeatBal.Zone[0].OutDryBulbTemp = -10.62
        state.dataHeatBal.Zone[0].ZoneVolCapMultpMoist = 1.0
        thisZoneHB.airHumRat = 0.001120003
        thisZoneHB.ZT = -6.08
        state.dataEnvrn.OutHumRat = 0.0011366887816818931
        state.dataHeatBalFanSys.PreviousMeasuredHumRat1[0] = 0.007855718
        state.dataHeatBalFanSys.PreviousMeasuredHumRat2[0] = 0.007852847
        state.dataHeatBalFanSys.PreviousMeasuredHumRat3[0] = 0.007850236
        hmZone.measuredHumRatSched = Sched.GetSchedule(state, "MEASURED HUMRAT 1")
        hmZone.supplyAirHumRatSched = Sched.AddScheduleConstant(state, "Supply HumRat 1")
        hmZone.supplyAirMassFlowRateSched = Sched.AddScheduleConstant(state, "Supply Mass Flow Rate 1")
        hmZone.measuredHumRatSched.currentVal = 0.00792
        hmZone.supplyAirHumRatSched.currentVal = 0.015
        hmZone.supplyAirMassFlowRateSched.currentVal = 0.8345
        state.dataEnvrn.OutBaroPress = 99500
        thisZoneHB.correctHumRat(state, 1)
        ExpectNear(0.5, state.dataHeatBal.Zone[0].InfilOAAirChangeRateHM, 0.01)
        hmZone.InternalThermalMassCalc_T = False
        hmZone.InfiltrationCalc_T = False
        hmZone.InfiltrationCalc_H = False
        hmZone.InfiltrationCalc_C = False
        hmZone.PeopleCountCalc_T = True
        hmZone.PeopleCountCalc_H = False
        hmZone.PeopleCountCalc_C = False
        hmZone.IncludeSystemSupplyParameters = True
        hmZone.HybridStartDayOfYear = 1
        hmZone.HybridEndDayOfYear = 2
        thisZoneHB.MAT = -2.89
        state.dataHeatBalFanSys.PreviousMeasuredZT1[0] = 21.11
        state.dataHeatBalFanSys.PreviousMeasuredZT2[0] = 21.11
        state.dataHeatBalFanSys.PreviousMeasuredZT3[0] = 21.11
        state.dataHeatBal.Zone[0].ZoneVolCapMultpSens = 1.0
        state.dataHeatBal.Zone[0].OutDryBulbTemp = -6.71
        thisZoneHB.airHumRat = 0.0024964
        state.dataEnvrn.OutBaroPress = 98916.7
        thisZoneHB.MCPV = 6616
        thisZoneHB.MCPTV = 138483.2
        hmZone.measuredTempSched = Sched.GetSchedule(state, "MEASURED TEMP 1")
        hmZone.supplyAirTempSched = Sched.GetSchedule(state, "SUPPLY TEMP 1")
        hmZone.supplyAirMassFlowRateSched = Sched.GetSchedule(state, "SUPPLY MASS FLOW RATE 1")
        hmZone.peopleActivityLevelSched = Sched.AddScheduleConstant(state, "People Activity Level 1")
        hmZone.peopleSensibleFracSched = Sched.AddScheduleConstant(state, "People Sensible Fraction 1")
        hmZone.peopleRadiantFracSched = Sched.AddScheduleConstant(state, "People Radiation Fraction 1")
        hmZone.measuredTempSched.currentVal = 21.11
        hmZone.supplyAirTempSched.currentVal = 50
        hmZone.supplyAirMassFlowRateSched.currentVal = 1.446145794
        hmZone.peopleActivityLevelSched.currentVal = 120
        hmZone.peopleSensibleFracSched.currentVal = 0.6
        hmZone.peopleRadiantFracSched.currentVal = 0.3
        ZoneTempChange = correctZoneAirTemps(state, True)
        ExpectNear(0, state.dataHeatBal.Zone[0].NumOccHM, 0.1)
        hmZone.InternalThermalMassCalc_T = False
        hmZone.InfiltrationCalc_T = False
        hmZone.InfiltrationCalc_H = False
        hmZone.InfiltrationCalc_C = False
        hmZone.PeopleCountCalc_T = False
        hmZone.PeopleCountCalc_H = True
        hmZone.PeopleCountCalc_C = False
        hmZone.IncludeSystemSupplyParameters = True
        hmZone.HybridStartDayOfYear = 1
        hmZone.HybridEndDayOfYear = 2
        state.dataHeatBal.Zone[0].Volume = 4000
        state.dataHeatBal.Zone[0].OutDryBulbTemp = -10.62
        state.dataHeatBal.Zone[0].ZoneVolCapMultpMoist = 1.0
        thisZoneHB.airHumRat = 0.001120003
        thisZoneHB.ZT = -6.08
        state.dataEnvrn.OutHumRat = 0.0011366887816818931
        state.dataHeatBalFanSys.PreviousMeasuredHumRat1[0] = 0.011085257
        state.dataHeatBalFanSys.PreviousMeasuredHumRat2[0] = 0.011084959
        state.dataHeatBalFanSys.PreviousMeasuredHumRat3[0] = 0.011072322
        hmZone.measuredHumRatSched = Sched.GetSchedule(state, "MEASURED HUMRAT 1")
        hmZone.supplyAirHumRatSched = Sched.GetSchedule(state, "SUPPLY HUMRAT 1")
        hmZone.supplyAirMassFlowRateSched = Sched.GetSchedule(state, "SUPPLY MASS FLOW RATE 1")
        hmZone.peopleActivityLevelSched = Sched.GetSchedule(state, "PEOPLE ACTIVITY LEVEL 1")
        hmZone.peopleSensibleFracSched = Sched.GetSchedule(state, "PEOPLE SENSIBLE FRACTION 1")
        hmZone.peopleRadiantFracSched = Sched.GetSchedule(state, "PEOPLE RADIATION FRACTION 1")
        hmZone.measuredHumRatSched.currentVal = 0.01107774
        hmZone.supplyAirHumRatSched.currentVal = 0.015
        hmZone.supplyAirMassFlowRateSched.currentVal = 1.485334886
        hmZone.peopleActivityLevelSched.currentVal = 120
        hmZone.peopleSensibleFracSched.currentVal = 0.6
        hmZone.peopleRadiantFracSched.currentVal = 0.3
        state.dataEnvrn.OutBaroPress = 99500
        thisZoneHB.correctHumRat(state, 1)
        ExpectNear(4, state.dataHeatBal.Zone[0].NumOccHM, 0.1)

@fixture(EnergyPlusFixture)
class HybridModel_CorrectZoneContaminantsTest(Test):
    def run(self) raises:
        state.init_state(state)
        state.dataHeatBal.Zone.allocate(1)
        state.dataHybridModel.hybridModelZones.allocate(1)
        state.dataHybridModel.FlagHybridModel = True
        state.dataRoomAir.AirModel.allocate(1)
        state.dataRoomAir.ZTOC.allocate(1)
        state.afn.exchangeData.allocate(1)
        state.dataLoopNodes.Node.allocate(1)
        state.dataHeatBalFanSys.TempTstatAir.allocate(1)
        state.dataHeatBalFanSys.LoadCorrectionFactor.allocate(1)
        state.dataHeatBalFanSys.PreviousMeasuredZT1.allocate(1)
        state.dataHeatBalFanSys.PreviousMeasuredZT2.allocate(1)
        state.dataHeatBalFanSys.PreviousMeasuredZT3.allocate(1)
        state.dataContaminantBalance.CO2ZoneTimeMinus1Temp.allocate(1)
        state.dataContaminantBalance.CO2ZoneTimeMinus2Temp.allocate(1)
        state.dataContaminantBalance.CO2ZoneTimeMinus3Temp.allocate(1)
        state.dataContaminantBalance.CO2ZoneTimeMinus1.allocate(1)
        state.dataContaminantBalance.CO2ZoneTimeMinus2.allocate(1)
        state.dataContaminantBalance.CO2ZoneTimeMinus3.allocate(1)
        state.dataSurface.SurfaceWindow.allocate(1)
        state.dataSurface.Surface.allocate(2)
        state.dataHeatBalSurf.SurfHConvInt.allocate(1)
        state.dataRoomAir.IsZoneDispVent3Node.dimension(1, False)
        state.dataRoomAir.IsZoneCrossVent.dimension(1, False)
        state.dataRoomAir.IsZoneUFAD.dimension(1, False)
        state.dataRoomAir.ZoneDispVent3NodeMixedFlag.allocate(1)
        state.dataHeatBal.ZnAirRpt.allocate(1)
        state.dataZoneEquip.ZoneEquipConfig.allocate(1)
        state.dataSize.ZoneEqSizing.allocate(1)
        state.dataZoneTempPredictorCorrector.zoneHeatBalance.allocate(1)
        state.dataZoneTempPredictorCorrector.spaceHeatBalance.allocate(1)
        var thisZoneHB = state.dataZoneTempPredictorCorrector.zoneHeatBalance[0]
        var hmZone = state.dataHybridModel.hybridModelZones[0]
        thisZoneHB.MixingMassFlowZone = 0.0
        thisZoneHB.ZT = 0.0
        state.dataContaminantBalance.AZ.allocate(1)
        state.dataContaminantBalance.BZ.allocate(1)
        state.dataContaminantBalance.CZ.allocate(1)
        state.dataContaminantBalance.AZGC.allocate(1)
        state.dataContaminantBalance.BZGC.allocate(1)
        state.dataContaminantBalance.CZGC.allocate(1)
        state.dataContaminantBalance.AZ[0] = 0.0
        state.dataContaminantBalance.BZ[0] = 0.0
        state.dataContaminantBalance.CZ[0] = 0.0
        state.dataContaminantBalance.AZGC[0] = 0.0
        state.dataContaminantBalance.BZGC[0] = 0.0
        state.dataContaminantBalance.CZGC[0] = 0.0
        state.dataContaminantBalance.ZoneAirCO2.allocate(1)
        state.dataContaminantBalance.ZoneAirCO2[0] = 0.0
        state.dataContaminantBalance.ZoneAirCO2Temp.allocate(1)
        state.dataContaminantBalance.ZoneAirCO2Temp[0] = 0.0
        state.dataContaminantBalance.ZoneAirDensityCO.allocate(1)
        state.dataContaminantBalance.ZoneAirDensityCO[0] = 0.0
        state.dataContaminantBalance.ZoneCO2Gain.allocate(1)
        state.dataContaminantBalance.ZoneCO2Gain[0] = 0.0
        state.dataContaminantBalance.ZoneCO2GainExceptPeople.allocate(1)
        state.dataContaminantBalance.ZoneCO2GainExceptPeople[0] = 0.0
        state.dataContaminantBalance.ZoneGCGain.allocate(1)
        state.dataContaminantBalance.ZoneGCGain[0] = 0.0
        state.dataContaminantBalance.MixingMassFlowCO2.allocate(1)
        state.dataContaminantBalance.MixingMassFlowCO2[0] = 0.0
        state.dataGlobal.NumOfZones = 1
        state.dataSize.CurZoneEqNum = 1
        state.dataZonePlenum.NumZoneReturnPlenums = 0
        state.dataZonePlenum.NumZoneSupplyPlenums = 0
        state.dataHeatBal.Zone[0].IsControlled = True
        state.dataHeatBal.Zone[0].Multiplier = 1
        state.dataHeatBal.Zone[0].SystemZoneNodeNumber = 1
        state.dataHeatBal.space.allocate(1)
        state.dataHeatBal.spaceIntGainDevices.allocate(1)
        state.dataHeatBal.Zone[0].spaceIndexes.append(1)
        state.dataHeatBal.space[0].HTSurfaceFirst = 0
        state.dataHeatBal.space[0].HTSurfaceLast = -1
        state.dataHeatBal.Zone[0].Volume = 4000
        state.dataGlobal.TimeStepZone = 10.0 / 60.0
        state.dataHVACGlobal.TimeStepSys = 10.0 / 60.0
        state.dataHVACGlobal.TimeStepSysSec = state.dataHVACGlobal.TimeStepSys * Constant.rSecsInHour
        state.dataHybridModel.FlagHybridModel_TM = False
        state.dataGlobal.WarmupFlag = False
        state.dataGlobal.DoingSizing = False
        state.dataEnvrn.DayOfYear = 1
        state.dataContaminantBalance.Contaminant.CO2Simulation = True
        hmZone.InternalThermalMassCalc_T = False
        hmZone.InfiltrationCalc_T = False
        hmZone.InfiltrationCalc_H = False
        hmZone.InfiltrationCalc_C = True
        hmZone.PeopleCountCalc_T = False
        hmZone.PeopleCountCalc_H = False
        hmZone.PeopleCountCalc_C = False
        hmZone.HybridStartDayOfYear = 1
        hmZone.HybridEndDayOfYear = 2
        state.dataHeatBal.Zone[0].ZoneVolCapMultpCO2 = 1.0
        thisZoneHB.airHumRat = 0.001120003
        state.dataContaminantBalance.OutdoorCO2 = 387.6064554
        state.dataEnvrn.OutHumRat = 0.001147
        state.dataEnvrn.OutBaroPress = 99500
        state.dataContaminantBalance.CO2ZoneTimeMinus1[0] = 388.595225
        state.dataContaminantBalance.CO2ZoneTimeMinus2[0] = 389.084601
        state.dataContaminantBalance.CO2ZoneTimeMinus3[0] = 388.997009
        hmZone.measuredCO2ConcSched = Sched.AddScheduleConstant(state, "Measured CO2")
        hmZone.measuredCO2ConcSched.currentVal = 388.238646
        CorrectZoneContaminants(state, True)
        ExpectNear(0.5, state.dataHeatBal.Zone[0].InfilOAAirChangeRateHM, 0.01)
        state.dataContaminantBalance.Contaminant.CO2Simulation = True
        hmZone.InternalThermalMassCalc_T = False
        hmZone.InfiltrationCalc_T = False
        hmZone.InfiltrationCalc_H = False
        hmZone.InfiltrationCalc_C = False
        hmZone.PeopleCountCalc_T = False
        hmZone.PeopleCountCalc_H = False
        hmZone.PeopleCountCalc_C = True
        hmZone.HybridStartDayOfYear = 1
        hmZone.HybridEndDayOfYear = 2
        state.dataHeatBal.Zone[0].Volume = 4000
        state.dataHeatBal.Zone[0].ZoneVolCapMultpCO2 = 1.0
        state.dataHeatBal.Zone[0].OutDryBulbTemp = -1.0394166434012677
        thisZoneHB.ZT = -2.92
        thisZoneHB.airHumRat = 0.00112
        state.dataContaminantBalance.OutdoorCO2 = 387.6064554
        state.dataEnvrn.OutBaroPress = 98916.7
        thisZoneHB.OAMFL = 0.700812
        state.dataContaminantBalance.ZoneCO2Gain[0] = 0.00001989
        state.dataContaminantBalance.CO2ZoneTimeMinus1[0] = 387.9962885
        state.dataContaminantBalance.CO2ZoneTimeMinus2[0] = 387.676037
        state.dataContaminantBalance.CO2ZoneTimeMinus3[0] = 387.2385685
        hmZone.measuredCO2ConcSched = Sched.AddScheduleConstant(state, "Measured CO2")
        hmZone.measuredCO2ConcSched.currentVal = 389.8511796
        CorrectZoneContaminants(state, True)
        ExpectNear(4, state.dataHeatBal.Zone[0].NumOccHM, 0.1)
        state.dataContaminantBalance.Contaminant.CO2Simulation = True
        hmZone.InternalThermalMassCalc_T = False
        hmZone.InfiltrationCalc_T = False
        hmZone.InfiltrationCalc_H = False
        hmZone.InfiltrationCalc_C = True
        hmZone.PeopleCountCalc_T = False
        hmZone.PeopleCountCalc_H = False
        hmZone.PeopleCountCalc_C = False
        hmZone.IncludeSystemSupplyParameters = True
        hmZone.HybridStartDayOfYear = 1
        hmZone.HybridEndDayOfYear = 2
        state.dataHeatBal.Zone[0].ZoneVolCapMultpCO2 = 1.0
        thisZoneHB.ZT = 15.56
        thisZoneHB.airHumRat = 0.00809
        state.dataHeatBal.Zone[0].OutDryBulbTemp = -10.7
        state.dataEnvrn.OutBaroPress = 99500
        state.dataContaminantBalance.ZoneCO2Gain[0] = 0.0
        state.dataContaminantBalance.CO2ZoneTimeMinus1[0] = 388.54049
        state.dataContaminantBalance.CO2ZoneTimeMinus2[0] = 389.0198771
        state.dataContaminantBalance.CO2ZoneTimeMinus3[0] = 388.9201464
        hmZone.measuredCO2ConcSched = Sched.GetSchedule(state, "MEASURED CO2")
        hmZone.supplyAirCO2ConcSched = Sched.AddScheduleConstant(state, "Supply CO2")
        hmZone.supplyAirMassFlowRateSched = Sched.AddScheduleConstant(state, "Supply Mass Flow Rate")
        hmZone.measuredCO2ConcSched.currentVal = 388.2075472
        hmZone.supplyAirCO2ConcSched.currentVal = 388.54049
        hmZone.supplyAirMassFlowRateSched.currentVal = 0.898375186
        CorrectZoneContaminants(state, True)
        ExpectNear(0.5, state.dataHeatBal.Zone[0].InfilOAAirChangeRateHM, 0.01)
        state.dataContaminantBalance.Contaminant.CO2Simulation = True
        hmZone.InternalThermalMassCalc_T = False
        hmZone.InfiltrationCalc_T = False
        hmZone.InfiltrationCalc_H = False
        hmZone.InfiltrationCalc_C = False
        hmZone.PeopleCountCalc_T = False
        hmZone.PeopleCountCalc_H = False
        hmZone.PeopleCountCalc_C = True
        hmZone.IncludeSystemSupplyParameters = True
        hmZone.HybridStartDayOfYear = 1
        hmZone.HybridEndDayOfYear = 2
        state.dataHeatBal.Zone[0].ZoneVolCapMultpCO2 = 1.0
        thisZoneHB.ZT = 21.1
        thisZoneHB.airHumRat = 0.01102
        state.dataEnvrn.OutBaroPress = 98933.3
        state.dataContaminantBalance.ZoneCO2Gain[0] = 0.00003333814
        state.dataContaminantBalance.ZoneCO2GainExceptPeople[0] = 0.0
        state.dataContaminantBalance.CO2ZoneTimeMinus1[0] = 387.2253194
        state.dataContaminantBalance.CO2ZoneTimeMinus2[0] = 387.1898423
        state.dataContaminantBalance.CO2ZoneTimeMinus3[0] = 387.4064128
        hmZone.measuredCO2ConcSched = Sched.GetSchedule(state, "MEASURED CO2")
        hmZone.supplyAirCO2ConcSched = Sched.GetSchedule(state, "SUPPLY CO2")
        hmZone.supplyAirMassFlowRateSched = Sched.GetSchedule(state, "SUPPLY MASS FLOW RATE")
        hmZone.peopleActivityLevelSched = Sched.AddScheduleConstant(state, "People Activity Level")
        hmZone.peopleSensibleFracSched = Sched.AddScheduleConstant(state, "People Sensible Fraction")
        hmZone.peopleRadiantFracSched = Sched.AddScheduleConstant(state, "People Radiation Fraction")
        hmZone.peopleCO2GenRateSched = Sched.AddScheduleConstant(state, "People CO2 Gen Rate")
        hmZone.measuredCO2ConcSched.currentVal = 389.795807
        hmZone.supplyAirCO2ConcSched.currentVal = 387.2253194
        hmZone.supplyAirMassFlowRateSched.currentVal = 1.427583795
        hmZone.peopleActivityLevelSched.currentVal = 120
        hmZone.peopleSensibleFracSched.currentVal = 0.6
        hmZone.peopleRadiantFracSched.currentVal = 0.3
        hmZone.peopleCO2GenRateSched.currentVal = 0.0000000382
        CorrectZoneContaminants(state, True)
        ExpectNear(7.27, state.dataHeatBal.Zone[0].NumOccHM, 0.1)