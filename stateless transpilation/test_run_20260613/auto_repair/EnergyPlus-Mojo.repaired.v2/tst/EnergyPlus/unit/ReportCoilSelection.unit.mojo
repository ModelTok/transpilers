from gtest import Test, Expect
from .Fixtures.EnergyPlusFixture import EnergyPlusFixture
from Fixtures.SQLiteFixture import SQLiteFixture
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataAirLoop import DataAirLoop
from EnergyPlus.DataEnvironment import DataEnvironment
from EnergyPlus.DataHVACGlobals import DataHVACGlobals
from EnergyPlus.DataPrecisionGlobals import DataPrecisionGlobals
from EnergyPlus.DataSizing import DataSizing
from EnergyPlus.DataZoneEquipment import DataZoneEquipment
from EnergyPlus.Fans import Fans
from EnergyPlus.Psychrometrics import Psychrometrics
from EnergyPlus.ReportCoilSelection import ReportCoilSelection
from EnergyPlus.DataPlant import DataPlant
from EnergyPlus.Fluid import Fluid
from EnergyPlus.Util import Util
from EnergyPlus.HVAC import HVAC

@fixture
def state():
    return EnergyPlusData()

@fixture
def EnergyPlusFixture():
    return EnergyPlusFixture()

def test_ReportCoilSelection_ChWCoil():
    coil1Name = "Coil 1"
    coil1Type = HVAC.CoilType.CoolingWater
    chWInletNodeNum = 9
    chWOutletNodeNum = 15
    state.init_state(state)
    state.dataPlnt.TotNumLoops = 1
    state.dataPlnt.PlantLoop = [None] * 1
    state.dataPlnt.PlantLoop[0] = DataPlant.PlantLoopData()
    state.dataPlnt.PlantLoop[0].Name = "Chilled Water Loop"
    state.dataPlnt.PlantLoop[0].FluidName = "Water"
    state.dataPlnt.PlantLoop[0].glycol = Fluid.GetWater(state)
    state.dataPlnt.PlantLoop[0].MaxMassFlowRate = 0.1
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch = [None] * 1
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].TotalBranches = 1
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp = [None] * 1
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].TotalComponents = 1
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].Branch = [None] * 1
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].TotalBranches = 1
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].Branch[0].Comp = [None] * 1
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].Branch[0].TotalComponents = 1
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp[0].NodeNumIn = 0
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp[0].NodeNumOut = 0
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].Branch[0].Comp[0].NodeNumIn = chWInletNodeNum
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].Branch[0].Comp[0].NodeNumOut = chWOutletNodeNum
    airVdot = 0.052
    isAutoSized = False
    ReportCoilSelection.setCoilAirFlow(state, ReportCoilSelection.getReportIndex(state, coil1Name, coil1Type), airVdot, isAutoSized)
    c1 = state.dataRptCoilSelection.coils[0]
    Expect(c1.coilName_ == coil1Name)
    Expect(c1.coilType == coil1Type)
    Expect(c1.coilDesVolFlow == airVdot)
    Expect(c1.volFlowIsAutosized == isAutoSized)
    loopNum = 1
    waterVdot = 0.05
    isAutoSized = False
    ReportCoilSelection.setCoilWaterFlowNodeNums(state, ReportCoilSelection.getReportIndex(state, coil1Name, coil1Type), waterVdot, isAutoSized, chWInletNodeNum, chWOutletNodeNum, loopNum)
    Expect(c1.pltSizNum == -999)
    Expect(c1.waterLoopNum == loopNum)
    Expect(c1.plantLoopName == state.dataPlnt.PlantLoop[0].Name)
    Expect(c1.rhoFluid == -999)
    Expect(c1.cpFluid == -999)
    Expect(c1.coilDesWaterMassFlow == -999)
    Expect(c1.coilWaterFlowAutoMsg == "No")
    ReportCoilSelection.finishCoilSummaryReportTable(state)
    coil2Name = "Coil 2"
    coil2Type = HVAC.CoilType.CoolingWater
    pltSizNum = -999
    ReportCoilSelection.setCoilWaterFlowPltSizNum(state, ReportCoilSelection.getReportIndex(state, coil2Name, coil2Type), waterVdot, isAutoSized, pltSizNum, loopNum)
    c2 = state.dataRptCoilSelection.coils[1]
    Expect(c2.pltSizNum == -999)
    Expect(c2.waterLoopNum == loopNum)
    Expect(c2.plantLoopName == state.dataPlnt.PlantLoop[0].Name)
    Expect(c2.rhoFluid == -999)
    Expect(c2.cpFluid == -999)
    Expect(c2.coilDesWaterMassFlow == -999)
    Expect(c2.coilWaterFlowAutoMsg == "No")
    state.dataSize.NumPltSizInput = 1
    state.dataSize.PlantSizData = [None] * 1
    state.dataSize.PlantSizData[0] = DataSizing.PlantSizingData()
    state.dataSize.PlantSizData[0].PlantLoopName = "Chilled Water Loop"
    isAutoSized = True
    ReportCoilSelection.setCoilWaterFlowNodeNums(state, ReportCoilSelection.getReportIndex(state, coil1Name, coil1Type), waterVdot, isAutoSized, chWInletNodeNum, chWOutletNodeNum, loopNum)
    c1b = state.dataRptCoilSelection.coils[0]
    Expect(c1b.pltSizNum == 1)
    Expect(c1b.waterLoopNum == loopNum)
    Expect(c1b.plantLoopName == state.dataPlnt.PlantLoop[0].Name)
    Expect(c1b.rhoFluid == 999.9, delta=0.1)
    Expect(c1b.cpFluid == 4197.9, delta=0.1)
    expFlow = waterVdot * c1b.rhoFluid
    Expect(c1b.coilDesWaterMassFlow == expFlow, delta=0.01)
    Expect(c1b.coilWaterFlowAutoMsg == "Yes")
    uA = 1000.00
    sizingCap = 500.0
    curSysNum = 1
    curZoneEqNum = 0
    isAutoSized = True
    state.dataAirSystemsData.PrimaryAirSystems = [None] * 1
    state.dataAirLoop.AirToZoneNodeInfo = [None] * 1
    state.dataAirLoop.AirToZoneNodeInfo[0] = DataAirLoop.AirToZoneNodeInfoStruct()
    state.dataAirLoop.AirToZoneNodeInfo[0].NumZonesHeated = 2
    state.dataAirLoop.AirToZoneNodeInfo[0].HeatCtrlZoneNums = [0] * state.dataAirLoop.AirToZoneNodeInfo[0].NumZonesHeated
    state.dataAirLoop.AirToZoneNodeInfo[0].HeatCtrlZoneNums[0] = 2
    state.dataAirLoop.AirToZoneNodeInfo[0].HeatCtrlZoneNums[1] = 3
    state.dataGlobal.NumOfZones = 3
    state.dataHeatBal.Zone = [None] * state.dataGlobal.NumOfZones
    state.dataHeatBal.Zone[0] = DataHeatBal.ZoneData()
    state.dataHeatBal.Zone[0].Name = "Zone 1"
    state.dataHeatBal.Zone[1] = DataHeatBal.ZoneData()
    state.dataHeatBal.Zone[1].Name = "Zone 2"
    state.dataHeatBal.Zone[2] = DataHeatBal.ZoneData()
    state.dataHeatBal.Zone[2].Name = "Zone 3"
    ReportCoilSelection.setCoilUA(state, ReportCoilSelection.getReportIndex(state, coil2Name, coil2Type), uA, sizingCap, isAutoSized, curSysNum, curZoneEqNum)
    Expect(c2.coilUA == uA)
    Expect(c2.coilTotCapAtPeak == sizingCap)
    Expect(c2.airloopNum == curSysNum)
    Expect(c2.zoneEqNum == curZoneEqNum)
    zoneCoolingLatentLoad = 1000.0
    zoneNum = 1
    ReportCoilSelection.setZoneLatentLoadCoolingIdealPeak(state, zoneNum, zoneCoolingLatentLoad)
    Expect(c2.rmLatentAtPeak == 0.0)
    zoneNum = 2
    ReportCoilSelection.setZoneLatentLoadCoolingIdealPeak(state, zoneNum, zoneCoolingLatentLoad)
    Expect(c2.rmLatentAtPeak == 1000.0)
    zoneNum = 3
    ReportCoilSelection.setZoneLatentLoadCoolingIdealPeak(state, zoneNum, zoneCoolingLatentLoad)
    Expect(c2.rmLatentAtPeak == 2000.0)
    coil3Name = "Coil 3"
    coil3Type = HVAC.CoilType.HeatingElectric
    uA = -999.0
    sizingCap = 500.0
    curSysNum = 1
    curZoneEqNum = 0
    isAutoSized = False
    ReportCoilSelection.setCoilUA(state, ReportCoilSelection.getReportIndex(state, coil3Name, coil3Type), uA, sizingCap, isAutoSized, curSysNum, curZoneEqNum)
    c3 = state.dataRptCoilSelection.coils[2]
    Expect(c3.coilUA == uA)
    Expect(c3.coilTotCapAtPeak == sizingCap)
    Expect(c3.airloopNum == curSysNum)
    Expect(c3.zoneEqNum == curZoneEqNum)
    zoneHeatingLatentLoad = 100.0
    zoneNum = 1
    ReportCoilSelection.setZoneLatentLoadHeatingIdealPeak(state, zoneNum, zoneHeatingLatentLoad)
    Expect(c3.rmLatentAtPeak == 0.0)
    zoneNum = 2
    ReportCoilSelection.setZoneLatentLoadHeatingIdealPeak(state, zoneNum, zoneHeatingLatentLoad)
    Expect(c3.rmLatentAtPeak == 100.0)
    zoneNum = 3
    ReportCoilSelection.setZoneLatentLoadHeatingIdealPeak(state, zoneNum, zoneHeatingLatentLoad)
    Expect(c3.rmLatentAtPeak == 200.0)
    ReportCoilSelection.finishCoilSummaryReportTable(state)

def test_ReportCoilSelection_SteamCoil():
    coil1Name = "Coil 1"
    coil1Type = HVAC.CoilType.HeatingSteam
    wInletNodeNum = 9
    wOutletNodeNum = 15
    state.init_state(state)
    state.dataPlnt.TotNumLoops = 1
    state.dataPlnt.PlantLoop = [None] * 1
    state.dataPlnt.PlantLoop[0] = DataPlant.PlantLoopData()
    state.dataPlnt.PlantLoop[0].Name = "Steam Loop"
    state.dataPlnt.PlantLoop[0].FluidName = "Steam"
    state.dataPlnt.PlantLoop[0].steam = Fluid.GetSteam(state)
    state.dataPlnt.PlantLoop[0].glycol = Fluid.GetWater(state)
    state.dataPlnt.PlantLoop[0].MaxMassFlowRate = 0.1
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch = [None] * 1
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].TotalBranches = 1
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp = [None] * 1
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].TotalComponents = 1
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].Branch = [None] * 1
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].TotalBranches = 1
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].Branch[0].Comp = [None] * 1
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].Branch[0].TotalComponents = 1
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp[0].NodeNumIn = 0
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp[0].NodeNumOut = 0
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].Branch[0].Comp[0].NodeNumIn = wInletNodeNum
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].Branch[0].Comp[0].NodeNumOut = wOutletNodeNum
    airVdot = 0.052
    isAutoSized = False
    ReportCoilSelection.setCoilAirFlow(state, ReportCoilSelection.getReportIndex(state, coil1Name, coil1Type), airVdot, isAutoSized)
    c1 = state.dataRptCoilSelection.coils[0]
    Expect(c1.coilName_ == coil1Name)
    Expect(c1.coilType == coil1Type)
    Expect(c1.coilDesVolFlow == airVdot)
    Expect(c1.volFlowIsAutosized == isAutoSized)
    loopNum = 1
    waterVdot = 0.05
    isAutoSized = False
    ReportCoilSelection.setCoilWaterFlowNodeNums(state, ReportCoilSelection.getReportIndex(state, coil1Name, coil1Type), waterVdot, isAutoSized, wInletNodeNum, wOutletNodeNum, loopNum)
    Expect(c1.pltSizNum == -999)
    Expect(c1.waterLoopNum == loopNum)
    Expect(c1.plantLoopName == state.dataPlnt.PlantLoop[0].Name)
    Expect(c1.rhoFluid == -999)
    Expect(c1.cpFluid == -999)
    Expect(c1.coilDesWaterMassFlow == -999)
    Expect(c1.coilWaterFlowAutoMsg == "No")
    state.dataSize.NumPltSizInput = 1
    state.dataSize.PlantSizData = [None] * 1
    state.dataSize.PlantSizData[0] = DataSizing.PlantSizingData()
    state.dataSize.PlantSizData[0].PlantLoopName = "Steam Loop"
    state.dataSize.PlantSizData[0].LoopType = DataSizing.TypeOfPlantLoop.Steam
    isAutoSized = True
    ReportCoilSelection.setCoilWaterFlowNodeNums(state, ReportCoilSelection.getReportIndex(state, coil1Name, coil1Type), waterVdot, isAutoSized, wInletNodeNum, wOutletNodeNum, loopNum)
    c1b = state.dataRptCoilSelection.coils[0]
    Expect(c1b.pltSizNum == 1)
    Expect(c1b.waterLoopNum == loopNum)
    Expect(c1b.plantLoopName == state.dataPlnt.PlantLoop[0].Name)
    Expect(c1b.rhoFluid == 0.6, delta=0.01)
    Expect(c1b.cpFluid == 4216.0, delta=0.1)
    expFlow = waterVdot * c1b.rhoFluid
    Expect(c1b.coilDesWaterMassFlow == expFlow, delta=0.01)
    Expect(c1b.coilWaterFlowAutoMsg == "Yes")
    ReportCoilSelection.finishCoilSummaryReportTable(state)

def test_ReportCoilSelection_ZoneEqCoil():
    coil1Name = "Coil 1"
    coil1Type = HVAC.CoilType.HeatingGasOrOtherFuel
    state.dataGlobal.NumOfZones = 3
    state.dataHeatBal.Zone = [None] * state.dataGlobal.NumOfZones
    state.dataHeatBal.Zone[0] = DataHeatBal.ZoneData()
    state.dataHeatBal.Zone[0].Name = "Zone 1"
    state.dataHeatBal.Zone[1] = DataHeatBal.ZoneData()
    state.dataHeatBal.Zone[1].Name = "Zone 2"
    state.dataHeatBal.Zone[2] = DataHeatBal.ZoneData()
    state.dataHeatBal.Zone[2].Name = "Zone 3"
    curSysNum = 0
    curZoneEqNum = 2
    curOASysNum = 0
    state.dataZoneEquip.ZoneEquipList = [None] * 3
    state.dataZoneEquip.ZoneEquipList[curZoneEqNum] = DataZoneEquipment.ZoneEquipListStruct()
    state.dataZoneEquip.ZoneEquipList[curZoneEqNum].NumOfEquipTypes = 2
    state.dataZoneEquip.ZoneEquipList[curZoneEqNum].EquipName = [""] * 2
    state.dataZoneEquip.ZoneEquipList[curZoneEqNum].EquipTypeName = [""] * 2
    state.dataZoneEquip.ZoneEquipList[curZoneEqNum].EquipType = [None] * 2
    state.dataZoneEquip.ZoneEquipList[curZoneEqNum].EquipName[0] = "Zone 2 Fan Coil"
    state.dataZoneEquip.ZoneEquipList[curZoneEqNum].EquipTypeName[0] = "ZoneHVAC:FourPipeFanCoil"
    state.dataZoneEquip.ZoneEquipList[curZoneEqNum].EquipType[0] = DataZoneEquipment.ZoneEquipType.FourPipeFanCoil
    state.dataZoneEquip.ZoneEquipList[curZoneEqNum].EquipName[1] = "Zone 2 Unit Heater"
    state.dataZoneEquip.ZoneEquipList[curZoneEqNum].EquipTypeName[1] = "ZoneHVAC:UnitHeater"
    state.dataZoneEquip.ZoneEquipList[curZoneEqNum].EquipType[1] = DataZoneEquipment.ZoneEquipType.UnitHeater
    state.dataZoneEquip.ZoneEquipList[curZoneEqNum].EquipData = [None] * 3
    totGrossCap = 500.0
    sensGrossCap = 500.0
    airFlowRate = 0.11
    waterFlowRate = 0.0
    ReportCoilSelection.setCoilFinalSizes(state, ReportCoilSelection.getReportIndex(state, coil1Name, coil1Type), totGrossCap, sensGrossCap, airFlowRate, waterFlowRate)
    c1 = state.dataRptCoilSelection.coils[0]
    Expect(c1.coilTotCapFinal == totGrossCap)
    Expect(c1.coilSensCapFinal == sensGrossCap)
    Expect(c1.coilRefAirVolFlowFinal == airFlowRate)
    Expect(c1.coilRefWaterVolFlowFinal == waterFlowRate)
    RatedCoilTotCap = 400.0
    RatedCoilSensCap = 399.0
    RatedAirMassFlow = 0.001
    RatedCoilInDb = -999.0
    RatedCoilInHumRat = -999.0
    RatedCoilInWb = 20.0
    RatedCoilOutDb = -999.0
    RatedCoilOutHumRat = -999.0
    RatedCoilOutWb = 30.0
    RatedCoilOadbRef = 24.0
    RatedCoilOawbRef = 16.0
    RatedCoilBpFactor = 0.2
    RatedCoilEff = 0.8
    ReportCoilSelection.setRatedCoilConditions(state, ReportCoilSelection.getReportIndex(state, coil1Name, coil1Type), RatedCoilTotCap, RatedCoilSensCap, RatedAirMassFlow, RatedCoilInDb, RatedCoilInHumRat, RatedCoilInWb, RatedCoilOutDb, RatedCoilOutHumRat, RatedCoilOutWb, RatedCoilOadbRef, RatedCoilOawbRef, RatedCoilBpFactor, RatedCoilEff)
    Expect(c1.coilRatedTotCap == RatedCoilTotCap)
    Expect(c1.coilCapFTIdealPeak == 1.0, delta=0.000001)
    Expect(c1.coilRatedSensCap == RatedCoilSensCap)
    Expect(c1.ratedAirMassFlow == RatedAirMassFlow)
    Expect(c1.ratedCoilInDb == RatedCoilInDb)
    Expect(c1.ratedCoilInWb == RatedCoilInWb)
    Expect(c1.ratedCoilInHumRat == RatedCoilInHumRat)
    Expect(c1.ratedCoilInEnth == -999.0)
    Expect(c1.ratedCoilOutDb == RatedCoilOutDb)
    Expect(c1.ratedCoilOutWb == RatedCoilOutWb)
    Expect(c1.ratedCoilOutHumRat == RatedCoilOutHumRat)
    Expect(c1.ratedCoilOutEnth == -999.0)
    Expect(c1.ratedCoilEff == RatedCoilEff)
    Expect(c1.ratedCoilBpFactor == RatedCoilBpFactor)
    Expect(c1.ratedCoilOadbRef == RatedCoilOadbRef)
    Expect(c1.ratedCoilOawbRef == RatedCoilOawbRef)
    RatedCoilInDb = 23.0
    RatedCoilInHumRat = 0.008
    RatedCoilOutDb = 40.0
    RatedCoilOutHumRat = 0.009
    ReportCoilSelection.setRatedCoilConditions(state, ReportCoilSelection.getReportIndex(state, coil1Name, coil1Type), RatedCoilTotCap, RatedCoilSensCap, RatedAirMassFlow, RatedCoilInDb, RatedCoilInHumRat, RatedCoilInWb, RatedCoilOutDb, RatedCoilOutHumRat, RatedCoilOutWb, RatedCoilOadbRef, RatedCoilOawbRef, RatedCoilBpFactor, RatedCoilEff)
    Expect(c1.ratedCoilInDb == RatedCoilInDb)
    Expect(c1.ratedCoilInHumRat == RatedCoilInHumRat)
    Expect(c1.ratedCoilInEnth == 43460.9, delta=0.1)
    Expect(c1.ratedCoilOutDb == RatedCoilOutDb)
    Expect(c1.ratedCoilOutHumRat == RatedCoilOutHumRat)
    Expect(c1.ratedCoilOutEnth == 63371.3, delta=0.1)
    entAirDryBulbTemp = 24.0
    ReportCoilSelection.setCoilEntAirTemp(state, ReportCoilSelection.getReportIndex(state, coil1Name, coil1Type), entAirDryBulbTemp, curSysNum, curZoneEqNum)
    Expect(c1.coilDesEntTemp == entAirDryBulbTemp)
    Expect(c1.airloopNum == curSysNum)
    Expect(c1.zoneEqNum == curZoneEqNum)
    entAirHumRat = 0.004
    ReportCoilSelection.setCoilEntAirHumRat(state, ReportCoilSelection.getReportIndex(state, coil1Name, coil1Type), entAirHumRat)
    Expect(c1.coilDesEntHumRat == entAirHumRat)
    entWaterTemp = 60.0
    ReportCoilSelection.setCoilEntWaterTemp(state, ReportCoilSelection.getReportIndex(state, coil1Name, coil1Type), entWaterTemp)
    Expect(c1.coilDesWaterEntTemp == entWaterTemp)
    lvgWaterTemp = 50.0
    ReportCoilSelection.setCoilLvgWaterTemp(state, ReportCoilSelection.getReportIndex(state, coil1Name, coil1Type), lvgWaterTemp)
    Expect(c1.coilDesWaterLvgTemp == lvgWaterTemp)
    CoilWaterDeltaT = 50.0
    ReportCoilSelection.setCoilWaterDeltaT(state, ReportCoilSelection.getReportIndex(state, coil1Name, coil1Type), CoilWaterDeltaT)
    Expect(c1.coilDesWaterTempDiff == CoilWaterDeltaT)
    lvgAirDryBulbTemp = 12.0
    ReportCoilSelection.setCoilLvgAirTemp(state, ReportCoilSelection.getReportIndex(state, coil1Name, coil1Type), lvgAirDryBulbTemp)
    Expect(c1.coilDesLvgTemp == lvgAirDryBulbTemp)
    lvgAirHumRat = 0.006
    ReportCoilSelection.setCoilLvgAirHumRat(state, ReportCoilSelection.getReportIndex(state, coil1Name, coil1Type), lvgAirHumRat)
    Expect(c1.coilDesLvgHumRat == lvgAirHumRat)
    zoneNum = 1
    zoneCoolingLatentLoad = 1234.0
    ReportCoilSelection.setZoneLatentLoadCoolingIdealPeak(state, zoneNum, zoneCoolingLatentLoad)
    Expect(c1.rmLatentAtPeak == 0.0)
    zoneHeatingLatentLoad = 4321.0
    ReportCoilSelection.setZoneLatentLoadHeatingIdealPeak(state, zoneNum, zoneHeatingLatentLoad)
    Expect(c1.rmLatentAtPeak == 0.0)
    ReportCoilSelection.finishCoilSummaryReportTable(state)
    curZoneEqNum = 1
    state.dataSize.ZoneEqSizing = [None] * 1
    state.dataSize.TermUnitFinalZoneSizing = [None] * 1
    state.dataSize.CurTermUnitSizingNum = curZoneEqNum
    state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum] = DataSizing.TermUnitFinalZoneSizingStruct()
    state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].DesHeatCoilInTempTU = RatedCoilInDb
    state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].DesHeatCoilInHumRatTU = RatedCoilInHumRat
    state.dataZoneEquip.ZoneEquipConfig = [None] * 1
    state.dataZoneEquip.ZoneEquipConfig[curZoneEqNum] = DataZoneEquipment.ZoneEquipConfigStruct()
    state.dataZoneEquip.ZoneEquipConfig[curZoneEqNum].ZoneName = state.dataHeatBal.Zone[0].Name
    state.dataSize.FinalZoneSizing = [None] * 1
    state.dataSize.FinalZoneSizing[curZoneEqNum] = DataSizing.FinalZoneSizingStruct()
    state.dataSize.FinalZoneSizing[curZoneEqNum].HeatDesDay = "Heat Design Day"
    state.dataSize.FinalZoneSizing[curZoneEqNum].DesHeatLoad = RatedCoilSensCap
    state.dataSize.FinalZoneSizing[curZoneEqNum].OutTempAtHeatPeak = RatedCoilOutDb
    state.dataSize.FinalZoneSizing[curZoneEqNum].OutHumRatAtHeatPeak = RatedCoilOutHumRat
    state.dataSize.FinalZoneSizing[curZoneEqNum].ZoneRetTempAtHeatPeak = 21.6
    state.dataSize.FinalZoneSizing[curZoneEqNum].ZoneHumRatAtHeatPeak = 0.007
    state.dataSize.FinalZoneSizing[curZoneEqNum].ZoneTempAtHeatPeak = 21.0
    state.dataSize.FinalZoneSizing[curZoneEqNum].HeatDesTemp = 30.0
    state.dataSize.FinalZoneSizing[curZoneEqNum].HeatDesHumRat = 0.007
    fanHeatGain = 1.3
    coilCapFunTempFac = 1.0
    DXFlowPerCapMinRatio = 0.00004
    DXFlowPerCapMaxRatio = 0.00006
    state.dataEnvrn.StdRhoAir = 1.2
    state.dataSize.DataFlowUsedForSizing = airFlowRate / state.dataEnvrn.StdRhoAir
    ReportCoilSelection.setCoilHeatingCapacity(state, ReportCoilSelection.getReportIndex(state, coil1Name, coil1Type), RatedCoilTotCap, False, curSysNum, curZoneEqNum, curOASysNum, fanHeatGain, coilCapFunTempFac, DXFlowPerCapMinRatio, DXFlowPerCapMaxRatio)
    Expect(c1.coilDesEntTemp == entAirDryBulbTemp)
    ReportCoilSelection.setZoneLatentLoadHeatingIdealPeak(state, zoneNum, zoneHeatingLatentLoad)
    Expect(zoneHeatingLatentLoad > 0.0)
    Expect(c1.rmLatentAtPeak == zoneHeatingLatentLoad, delta=0.000001)
    entAirDryBulbTemp = 21.0
    ReportCoilSelection.setCoilEntAirTemp(state, ReportCoilSelection.getReportIndex(state, coil1Name, coil1Type), entAirDryBulbTemp, curSysNum, curZoneEqNum)
    lvgAirDryBulbTemp = 30.0
    ReportCoilSelection.setCoilLvgAirTemp(state, ReportCoilSelection.getReportIndex(state, coil1Name, coil1Type), lvgAirDryBulbTemp)
    Expect(c1.coilDesEntTemp == entAirDryBulbTemp)
    Expect(c1.coilDesLvgTemp == lvgAirDryBulbTemp)
    state.dataSize.TermUnitSingDuct = True
    c1.coilDesEntTemp = -999.0
    c1.coilDesEntHumRat = -999.0
    c1.coilDesLvgTemp = -999.0
    c1.coilDesLvgHumRat = -999.0
    ReportCoilSelection.setCoilHeatingCapacity(state, ReportCoilSelection.getReportIndex(state, coil1Name, coil1Type), RatedCoilTotCap, False, curSysNum, curZoneEqNum, curOASysNum, fanHeatGain, coilCapFunTempFac, DXFlowPerCapMinRatio, DXFlowPerCapMaxRatio)
    Expect(c1.coilDesEntTemp == RatedCoilInDb)
    Expect(c1.coilDesEntHumRat == RatedCoilInHumRat)
    Expect(c1.coilDesLvgTemp == state.dataSize.FinalZoneSizing[curZoneEqNum].HeatDesTemp)
    Expect(c1.coilDesLvgHumRat == state.dataSize.FinalZoneSizing[curZoneEqNum].HeatDesHumRat)
    Expect(c1.coilTotCapAtPeak == RatedCoilTotCap * coilCapFunTempFac, delta=0.000001)
    Expect(coilCapFunTempFac == 1.0, delta=0.000001)
    Expect(c1.coilTotCapAtPeak == RatedCoilTotCap, delta=0.000001)
    coilCapFunTempFac = 1.15
    ReportCoilSelection.setCoilHeatingCapacity(state, ReportCoilSelection.getReportIndex(state, coil1Name, coil1Type), RatedCoilTotCap, False, curSysNum, curZoneEqNum, curOASysNum, fanHeatGain, coilCapFunTempFac, DXFlowPerCapMinRatio, DXFlowPerCapMaxRatio)
    Expect(c1.coilTotCapAtPeak == RatedCoilTotCap * coilCapFunTempFac, delta=0.000001)
    Expect(RatedCoilTotCap < c1.coilTotCapAtPeak)

def test_ReportCoilSelection_ZoneEqCoolingCoil():
    coil1Name = "Coil 1"
    coil1Type = HVAC.CoilType.CoolingDX
    state.dataGlobal.NumOfZones = 3
    state.dataHeatBal.Zone = [None] * state.dataGlobal.NumOfZones
    state.dataHeatBal.Zone[0] = DataHeatBal.ZoneData()
    state.dataHeatBal.Zone[0].Name = "Zone 1"
    state.dataHeatBal.Zone[1] = DataHeatBal.ZoneData()
    state.dataHeatBal.Zone[1].Name = "Zone 2"
    state.dataHeatBal.Zone[2] = DataHeatBal.ZoneData()
    state.dataHeatBal.Zone[2].Name = "Zone 3"
    curSysNum = 0
    curZoneEqNum = 2
    curOASysNum = 0
    state.dataZoneEquip.ZoneEquipList = [None] * 3
    state.dataZoneEquip.ZoneEquipList[curZoneEqNum] = DataZoneEquipment.ZoneEquipListStruct()
    state.dataZoneEquip.ZoneEquipList[curZoneEqNum].NumOfEquipTypes = 2
    state.dataZoneEquip.ZoneEquipList[curZoneEqNum].EquipName = [""] * 2
    state.dataZoneEquip.ZoneEquipList[curZoneEqNum].EquipTypeName = [""] * 2
    state.dataZoneEquip.ZoneEquipList[curZoneEqNum].EquipType = [None] * 2
    state.dataZoneEquip.ZoneEquipList[curZoneEqNum].EquipName[0] = "Zone 2 DX Eq"
    state.dataZoneEquip.ZoneEquipList[curZoneEqNum].EquipTypeName[0] = "ZoneHVAC:WindowAirConditioner"
    state.dataZoneEquip.ZoneEquipList[curZoneEqNum].EquipType[0] = DataZoneEquipment.ZoneEquipType.WindowAirConditioner
    state.dataZoneEquip.ZoneEquipList[curZoneEqNum].EquipName[1] = "Zone 2 Unit Heater"
    state.dataZoneEquip.ZoneEquipList[curZoneEqNum].EquipTypeName[1] = "ZoneHVAC:UnitHeater"
    state.dataZoneEquip.ZoneEquipList[curZoneEqNum].EquipType[1] = DataZoneEquipment.ZoneEquipType.UnitHeater
    state.dataZoneEquip.ZoneEquipList[curZoneEqNum].EquipData = [None] * 3
    totGrossCap = 500.0
    sensGrossCap = 400.0
    airFlowRate = 0.11
    waterFlowRate = 0.0
    ReportCoilSelection.setCoilFinalSizes(state, ReportCoilSelection.getReportIndex(state, coil1Name, coil1Type), totGrossCap, sensGrossCap, airFlowRate, waterFlowRate)
    c1 = state.dataRptCoilSelection.coils[0]
    Expect(c1.coilTotCapFinal == totGrossCap)
    Expect(c1.coilSensCapFinal == sensGrossCap)
    Expect(c1.coilRefAirVolFlowFinal == airFlowRate)
    Expect(c1.coilRefWaterVolFlowFinal == waterFlowRate)
    RatedCoilTotCap = 400.0
    RatedCoilSensCap = 300.0
    RatedAirMassFlow = 0.001
    RatedCoilInDb = -999.0
    RatedCoilInHumRat = -999.0
    RatedCoilInWb = 20.0
    RatedCoilOutDb = -999.0
    RatedCoilOutHumRat = -999.0
    RatedCoilOutWb = 30.0
    RatedCoilOadbRef = 24.0
    RatedCoilOawbRef = 16.0
    RatedCoilBpFactor = 0.2
    RatedCoilEff = 0.8
    ReportCoilSelection.setRatedCoilConditions(state, ReportCoilSelection.getReportIndex(state, coil1Name, coil1Type), RatedCoilTotCap, RatedCoilSensCap, RatedAirMassFlow, RatedCoilInDb, RatedCoilInHumRat, RatedCoilInWb, RatedCoilOutDb, RatedCoilOutHumRat, RatedCoilOutWb, RatedCoilOadbRef, RatedCoilOawbRef, RatedCoilBpFactor, RatedCoilEff)
    Expect(c1.coilRatedTotCap == RatedCoilTotCap)
    Expect(c1.coilCapFTIdealPeak == 1.0, delta=0.000001)
    Expect(c1.coilRatedSensCap == RatedCoilSensCap)
    Expect(c1.ratedAirMassFlow == RatedAirMassFlow)
    Expect(c1.ratedCoilInDb == RatedCoilInDb)
    Expect(c1.ratedCoilInWb == RatedCoilInWb)
    Expect(c1.ratedCoilInHumRat == RatedCoilInHumRat)
    Expect(c1.ratedCoilInEnth == -999.0)
    Expect(c1.ratedCoilOutDb == RatedCoilOutDb)
    Expect(c1.ratedCoilOutWb == RatedCoilOutWb)
    Expect(c1.ratedCoilOutHumRat == RatedCoilOutHumRat)
    Expect(c1.ratedCoilOutEnth == -999.0)
    Expect(c1.ratedCoilEff == RatedCoilEff)
    Expect(c1.ratedCoilBpFactor == RatedCoilBpFactor)
    Expect(c1.ratedCoilOadbRef == RatedCoilOadbRef)
    Expect(c1.ratedCoilOawbRef == RatedCoilOawbRef)
    RatedCoilInDb = 23.0
    RatedCoilInHumRat = 0.008
    RatedCoilOutDb = 12.0
    RatedCoilOutHumRat = 0.006
    ReportCoilSelection.setRatedCoilConditions(state, ReportCoilSelection.getReportIndex(state, coil1Name, coil1Type), RatedCoilTotCap, RatedCoilSensCap, RatedAirMassFlow, RatedCoilInDb, RatedCoilInHumRat, RatedCoilInWb, RatedCoilOutDb, RatedCoilOutHumRat, RatedCoilOutWb, RatedCoilOadbRef, RatedCoilOawbRef, RatedCoilBpFactor, RatedCoilEff)
    Expect(c1.ratedCoilInDb == RatedCoilInDb)
    Expect(c1.ratedCoilInHumRat == RatedCoilInHumRat)
    Expect(c1.ratedCoilInEnth == 43460.9, delta=0.1)
    Expect(c1.ratedCoilOutDb == RatedCoilOutDb)
    Expect(c1.ratedCoilOutHumRat == RatedCoilOutHumRat)
    Expect(c1.ratedCoilOutEnth == 27197.5, delta=0.1)
    entAirDryBulbTemp = 24.0
    ReportCoilSelection.setCoilEntAirTemp(state, ReportCoilSelection.getReportIndex(state, coil1Name, coil1Type), entAirDryBulbTemp, curSysNum, curZoneEqNum)
    Expect(c1.coilDesEntTemp == entAirDryBulbTemp)
    Expect(c1.airloopNum == curSysNum)
    Expect(c1.zoneEqNum == curZoneEqNum)
    entAirHumRat = 0.004
    ReportCoilSelection.setCoilEntAirHumRat(state, ReportCoilSelection.getReportIndex(state, coil1Name, coil1Type), entAirHumRat)
    Expect(c1.coilDesEntHumRat == entAirHumRat)
    lvgAirDryBulbTemp = 14.0
    ReportCoilSelection.setCoilLvgAirTemp(state, ReportCoilSelection.getReportIndex(state, coil1Name, coil1Type), lvgAirDryBulbTemp)
    Expect(c1.coilDesLvgTemp == lvgAirDryBulbTemp)
    lvgAirHumRat = 0.005
    ReportCoilSelection.setCoilLvgAirHumRat(state, ReportCoilSelection.getReportIndex(state, coil1Name, coil1Type), lvgAirHumRat)
    Expect(c1.coilDesLvgHumRat == lvgAirHumRat)
    zoneNum = 1
    zoneCoolingLatentLoad = 1234.0
    ReportCoilSelection.setZoneLatentLoadCoolingIdealPeak(state, zoneNum, zoneCoolingLatentLoad)
    Expect(c1.rmLatentAtPeak == 0.0)
    zoneHeatingLatentLoad = 4321.0
    ReportCoilSelection.setZoneLatentLoadHeatingIdealPeak(state, zoneNum, zoneHeatingLatentLoad)
    Expect(c1.rmLatentAtPeak == 0.0)
    ReportCoilSelection.finishCoilSummaryReportTable(state)
    curZoneEqNum = 1
    state.dataSize.ZoneEqSizing = [None] * 1
    state.dataZoneEquip.ZoneEquipConfig = [None] * 1
    state.dataZoneEquip.ZoneEquipConfig[curZoneEqNum] = DataZoneEquipment.ZoneEquipConfigStruct()
    state.dataZoneEquip.ZoneEquipConfig[curZoneEqNum].ZoneName = state.dataHeatBal.Zone[0].Name
    state.dataSize.FinalZoneSizing = [None] * 1
    state.dataSize.FinalZoneSizing[curZoneEqNum] = DataSizing.FinalZoneSizingStruct()
    state.dataSize.FinalZoneSizing[curZoneEqNum].CoolDesDay = "Cool Design Day"
    state.dataSize.FinalZoneSizing[curZoneEqNum].DesCoolLoad = RatedCoilSensCap
    state.dataSize.FinalZoneSizing[curZoneEqNum].OutTempAtCoolPeak = RatedCoilOutDb
    state.dataSize.FinalZoneSizing[curZoneEqNum].OutHumRatAtCoolPeak = RatedCoilOutHumRat
    state.dataSize.FinalZoneSizing[curZoneEqNum].DesCoolCoilInTemp = 25.0
    state.dataSize.FinalZoneSizing[curZoneEqNum].DesCoolCoilInHumRat = 0.007
    state.dataSize.FinalZoneSizing[curZoneEqNum].CoolDesTemp = 12.0
    state.dataSize.FinalZoneSizing[curZoneEqNum].CoolDesHumRat = 0.007
    fanHeatGain = 1.3
    coilCapFunTempFac = 1.0
    DXFlowPerCapMinRatio = 0.00004
    DXFlowPerCapMaxRatio = 0.00006
    state.dataEnvrn.StdRhoAir = 1.2
    state.dataSize.DataFlowUsedForSizing = airFlowRate / state.dataEnvrn.StdRhoAir
    ReportCoilSelection.setCoilCoolingCapacity(state, ReportCoilSelection.getReportIndex(state, coil1Name, coil1Type), RatedCoilTotCap, False, curSysNum, curZoneEqNum, curOASysNum, fanHeatGain, coilCapFunTempFac, DXFlowPerCapMinRatio, DXFlowPerCapMaxRatio)
    Expect(c1.coilDesEntTemp == entAirDryBulbTemp)
    Expect(c1.coilDesEntHumRat == entAirHumRat)
    Expect(c1.coilDesLvgTemp == lvgAirDryBulbTemp)
    Expect(c1.coilDesLvgHumRat == lvgAirHumRat)
    CpMoistAir = Psychrometrics.PsyCpAirFnW(c1.coilDesEntHumRat)
    Expect(c1.cpMoistAir == CpMoistAir)
    Expect(c1.fanHeatGainIdealPeak == fanHeatGain, delta=0.000001)
    ReportCoilSelection.setZoneLatentLoadCoolingIdealPeak(state, zoneNum, zoneCoolingLatentLoad)
    Expect(c1.rmLatentAtPeak == zoneCoolingLatentLoad)
    entAirDryBulbTemp = 21.0
    ReportCoilSelection.setCoilEntAirTemp(state, ReportCoilSelection.getReportIndex(state, coil1Name, coil1Type), entAirDryBulbTemp, curSysNum, curZoneEqNum)
    lvgAirDryBulbTemp = 12.0
    ReportCoilSelection.setCoilLvgAirTemp(state, ReportCoilSelection.getReportIndex(state, coil1Name, coil1Type), lvgAirDryBulbTemp)
    Expect(c1.coilDesEntTemp == entAirDryBulbTemp)
    Expect(c1.coilDesLvgTemp == lvgAirDryBulbTemp)
    c1.coilDesEntTemp = -999.0
    c1.coilDesEntHumRat = -999.0
    c1.coilDesLvgTemp = -999.0
    c1.coilDesLvgHumRat = -999.0
    ReportCoilSelection.setCoilCoolingCapacity(state, ReportCoilSelection.getReportIndex(state, coil1Name, coil1Type), RatedCoilTotCap, False, curSysNum, curZoneEqNum, curOASysNum, fanHeatGain, coilCapFunTempFac, DXFlowPerCapMinRatio, DXFlowPerCapMaxRatio)
    Expect(c1.coilDesEntTemp == state.dataSize.FinalZoneSizing[curZoneEqNum].DesCoolCoilInTemp)
    Expect(c1.coilDesEntHumRat == state.dataSize.FinalZoneSizing[curZoneEqNum].DesCoolCoilInHumRat)
    Expect(c1.coilDesLvgTemp == state.dataSize.FinalZoneSizing[curZoneEqNum].CoolDesTemp)
    Expect(c1.coilDesLvgHumRat == state.dataSize.FinalZoneSizing[curZoneEqNum].CoolDesHumRat)
    Expect(c1.coilTotCapAtPeak == RatedCoilTotCap * coilCapFunTempFac, delta=0.000001)
    Expect(coilCapFunTempFac == 1.0, delta=0.000001)
    Expect(c1.coilTotCapAtPeak == RatedCoilTotCap, delta=0.000001)
    coilCapFunTempFac = 1.15
    ReportCoilSelection.setCoilCoolingCapacity(state, ReportCoilSelection.getReportIndex(state, coil1Name, coil1Type), RatedCoilTotCap, False, curSysNum, curZoneEqNum, curOASysNum, fanHeatGain, coilCapFunTempFac, DXFlowPerCapMinRatio, DXFlowPerCapMaxRatio)
    Expect(c1.coilTotCapAtPeak == RatedCoilTotCap * coilCapFunTempFac, delta=0.000001)
    Expect(RatedCoilTotCap < c1.coilTotCapAtPeak)

def test_ReportCoilSelection_4PipeFCU_ElecHeatingCoil():
    coil1Name = "ElecHeatCoil"
    coil1Type = HVAC.CoilType.HeatingElectric
    state.dataGlobal.NumOfZones = 1
    state.dataHeatBal.Zone = [None] * state.dataGlobal.NumOfZones
    state.dataHeatBal.Zone[0] = DataHeatBal.ZoneData()
    state.dataHeatBal.Zone[0].Name = "Zone 1"
    curSysNum = 0
    curOASysNum = 0
    curZoneEqNum = 1
    state.dataZoneEquip.ZoneEquipList = [None] * 1
    zoneEquipList = state.dataZoneEquip.ZoneEquipList[curZoneEqNum]
    zoneEquipList = DataZoneEquipment.ZoneEquipListStruct()
    zoneEquipList.NumOfEquipTypes = 1
    zoneEquipList.EquipName = [""] * 1
    zoneEquipList.EquipTypeName = [""] * 1
    zoneEquipList.EquipType = [None] * 1
    zoneEquipList.EquipName[0] = "Zone 1 FCU"
    zoneEquipList.EquipTypeName[0] = "ZoneHVAC:FourPipeFanCoil"
    zoneEquipList.EquipType[0] = DataZoneEquipment.ZoneEquipType.FourPipeFanCoil
    totGrossCap = 6206.4
    sensGrossCap = 6206.4
    airVolFlowRate = 0.1385
    waterFlowRate = 0.0
    ReportCoilSelection.setCoilFinalSizes(state, ReportCoilSelection.getReportIndex(state, coil1Name, coil1Type), totGrossCap, sensGrossCap, airVolFlowRate, waterFlowRate)
    c1 = state.dataRptCoilSelection.coils[0]
    Expect(c1.coilTotCapFinal == totGrossCap)
    Expect(c1.coilSensCapFinal == sensGrossCap)
    Expect(c1.coilRefAirVolFlowFinal == airVolFlowRate)
    Expect(c1.coilRefWaterVolFlowFinal == waterFlowRate)
    RatedCoilTotCap = 6206.5
    RatedCoilSensCap = 6206.5
    RatedAirMassFlow = 0.163
    RatedCoilInDb = 12.3785
    RatedCoilInHumRat = 0.00335406
    RatedCoilInWb = 6.02
    RatedCoilOutDb = 50.0
    RatedCoilOutHumRat = 0.004
    RatedCoilOutWb = -999.0
    RatedCoilOadbRef = -17.30
    RatedCoilOawbRef = -17.30
    MinOaFrac = 0.0
    RatedCoilBpFactor = 0.0
    RatedCoilEff = 0.80
    result_coilDesEntEnth = Psychrometrics.PsyHFnTdbW(RatedCoilInDb, RatedCoilInHumRat)
    result_coilDesOutEnth = Psychrometrics.PsyHFnTdbW(RatedCoilOutDb, RatedCoilOutHumRat)
    ReportCoilSelection.setRatedCoilConditions(state, ReportCoilSelection.getReportIndex(state, coil1Name, coil1Type), RatedCoilTotCap, RatedCoilSensCap, RatedAirMassFlow, RatedCoilInDb, RatedCoilInHumRat, RatedCoilInWb, RatedCoilOutDb, RatedCoilOutHumRat, RatedCoilOutWb, RatedCoilOadbRef, RatedCoilOawbRef, RatedCoilBpFactor, RatedCoilEff)
    Expect(c1.ratedCoilInDb == RatedCoilInDb)
    Expect(c1.ratedCoilInHumRat == RatedCoilInHumRat)
    Expect(c1.ratedCoilInEnth == result_coilDesEntEnth, delta=0.1)
    Expect(c1.ratedCoilOutDb == RatedCoilOutDb)
    Expect(c1.ratedCoilOutHumRat == RatedCoilOutHumRat)
    Expect(c1.ratedCoilOutEnth == result_coilDesOutEnth, delta=0.1)
    state.dataSize.ZoneEqSizing = [None] * 1
    zoneEqSizing = state.dataSize.ZoneEqSizing[curZoneEqNum]
    zoneEqSizing = DataSizing.ZoneEqSizingStruct()
    state.dataSize.FinalZoneSizing = [None] * 1
    finalZoneSizing = state.dataSize.FinalZoneSizing[curZoneEqNum]
    finalZoneSizing = DataSizing.FinalZoneSizingStruct()
    state.dataSize.ZoneEqFanCoil = True
    zoneEqSizing.OAVolFlow = 0.02830
    state.dataEnvrn.StdRhoAir = 1.1759
    MinOaFrac = zoneEqSizing.OAVolFlow * state.dataEnvrn.StdRhoAir / RatedAirMassFlow
    finalZoneSizing.HeatDesDay = "Heat Design Day"
    finalZoneSizing.DesHeatLoad = RatedCoilSensCap
    finalZoneSizing.OutTempAtHeatPeak = -17.30
    finalZoneSizing.OutHumRatAtHeatPeak = 0.00083893
    finalZoneSizing.ZoneRetTempAtHeatPeak = 20.0
    finalZoneSizing.ZoneHumRatAtHeatPeak = 0.007
    finalZoneSizing.ZoneTempAtHeatPeak = 20.0
    finalZoneSizing.HeatDesTemp = 50.0
    finalZoneSizing.HeatDesHumRat = 0.004
    finalZoneSizing.DesHeatOAFlowFrac = MinOaFrac
    finalZoneSizing.DesHeatMassFlow = RatedAirMassFlow
    fanHeatGain = 0.0
    coilCapFunTempFac = 1.0
    DXFlowPerCapMinRatio = 0.00004
    DXFlowPerCapMaxRatio = 0.00006
    result_coilEntAirDryBulbTemp = MinOaFrac * finalZoneSizing.OutTempAtHeatPeak + (1.0 - MinOaFrac) * finalZoneSizing.ZoneTempAtHeatPeak
    result_coilEntAirHumRat = MinOaFrac * finalZoneSizing.OutHumRatAtHeatPeak + (1.0 - MinOaFrac) * finalZoneSizing.ZoneHumRatAtHeatPeak
    result_sensCapacity = Psychrometrics.PsyCpAirFnW(finalZoneSizing.HeatDesHumRat) * RatedAirMassFlow * (finalZoneSizing.HeatDesTemp - result_coilEntAirDryBulbTemp)
    c1.coilDesEntTemp = -999.0
    c1.coilDesEntHumRat = -999.0
    c1.coilDesLvgTemp = -999.0
    c1.coilDesLvgHumRat = -999.0
    ReportCoilSelection.setCoilHeatingCapacity(state, ReportCoilSelection.getReportIndex(state, coil1Name, coil1Type), RatedCoilTotCap, False, curSysNum, curZoneEqNum, curOASysNum, fanHeatGain, coilCapFunTempFac, DXFlowPerCapMinRatio, DXFlowPerCapMaxRatio)
    Expect(c1.coilDesLvgTemp == finalZoneSizing.HeatDesTemp)
    Expect(c1.coilDesLvgHumRat == finalZoneSizing.HeatDesHumRat)
    Expect(c1.coilDesEntTemp == result_coilEntAirDryBulbTemp, delta=0.0001)
    Expect(c1.coilDesEntHumRat == result_coilEntAirHumRat, delta=0.000001)
    Expect(RatedCoilTotCap == 6206.5)
    Expect(c1.coilTotCapAtPeak == RatedCoilTotCap, delta=0.1)
    Expect(c1.coilSensCapAtPeak == RatedCoilTotCap, delta=0.1)
    Expect(c1.coilSensCapAtPeak == result_sensCapacity, delta=0.1)

def test_Test_finishCoilSummaryReportTable():
    mult = 1.0
    curZoneEqNum = 1
    coil1Name = "ElecHeatCoil"
    coil1Type = HVAC.CoilType.HeatingElectric
    ReportCoilSelection.setCoilReheatMultiplier(state, ReportCoilSelection.getReportIndex(state, coil1Name, coil1Type), mult)
    c1 = state.dataRptCoilSelection.coils[0]
    c1.zoneEqNum = curZoneEqNum
    state.dataHeatBal.Zone = [None] * 1
    state.dataHeatBal.Zone[0] = DataHeatBal.ZoneData()
    state.dataHeatBal.Zone[0].Name = "ThisZone"
    state.dataZoneEquip.ZoneEquipList = [None] * 1
    zoneEquipList = state.dataZoneEquip.ZoneEquipList[curZoneEqNum]
    zoneEquipList = DataZoneEquipment.ZoneEquipListStruct()
    zoneEquipList.NumOfEquipTypes = 1
    zoneEquipList.EquipName = [""] * 1
    zoneEquipList.EquipTypeName = [""] * 1
    zoneEquipList.EquipData = [None] * 1
    zoneEquipList.EquipType = [None] * 1
    zoneEquipList.EquipName[0] = "Zone 1 FCU"
    zoneEquipList.EquipTypeName[0] = "ZoneHVAC:FourPipeFanCoil"
    zoneEquipList.EquipType[0] = DataZoneEquipment.ZoneEquipType.FourPipeFanCoil
    zoneEquipList.EquipData[0] = DataZoneEquipment.EquipDataStruct()
    zoneEquipList.EquipData[0].Name = "ZoneHVAC:FourPipeFanCoil"
    zoneEquipList.EquipData[0].NumSubEquip = 2
    zoneEquipList.EquipData[0].SubEquipData = [None] * 2
    zoneEquipList.EquipData[0].SubEquipData[0] = DataZoneEquipment.SubEquipDataStruct()
    zoneEquipList.EquipData[0].SubEquipData[0].Name = "ElecHeatCoil"
    zoneEquipList.EquipData[0].SubEquipData[0].TypeOf = "Coil:Heating:Electric"
    zoneEquipList.EquipData[0].SubEquipData[1] = DataZoneEquipment.SubEquipDataStruct()
    zoneEquipList.EquipData[0].SubEquipData[1].Name = "MyFan1"
    zoneEquipList.EquipData[0].SubEquipData[1].TypeOf = "FAN:ONOFF"
    Expect(Util.SameString(c1.coilLocation, "unknown"))
    Expect(Util.SameString(c1.typeHVACname, "unknown"))
    Expect(Util.SameString(c1.userNameforHVACsystem, "unknown"))
    ReportCoilSelection.finishCoilSummaryReportTable(state)
    Expect(Util.SameString(c1.coilLocation, "Zone Equipment"))
    Expect(Util.SameString(c1.typeHVACname, "ZoneHVAC:FourPipeFanCoil"))
    Expect(Util.SameString(c1.userNameforHVACsystem, "Zone 1 FCU"))
    Expect(Util.SameString(c1.zoneName[0], "ThisZone"))
    Expect(Util.SameString(c1.fanTypeName, "FAN:ONOFF"))
    Expect(Util.SameString(c1.fanAssociatedWithCoilName, "MyFan1"))
    zoneEquipList.NumOfEquipTypes = 2
    zoneEquipList.EquipName = [""] * 2
    zoneEquipList.EquipTypeName = [""] * 2
    zoneEquipList.EquipData = [None] * 2
    zoneEquipList.EquipType = [None] * 2
    zoneEquipList.EquipIndex = [0] * 2
    Expect(Util.SameString(zoneEquipList.EquipName[0], ""))
    Expect(Util.SameString(zoneEquipList.EquipName[1], ""))
    coil2Name = "ElecHeatCoil 2"
    coil2Type = HVAC.CoilType.HeatingElectric
    zoneEquipList.EquipName[0] = "Zone 1 FCU"
    zoneEquipList.EquipTypeName[0] = "ZoneHVAC:FourPipeFanCoil"
    zoneEquipList.EquipType[0] = DataZoneEquipment.ZoneEquipType.FourPipeFanCoil
    zoneEquipList.EquipData[0] = DataZoneEquipment.EquipDataStruct()
    zoneEquipList.EquipData[0].Name = "ZoneHVAC:FourPipeFanCoil"
    zoneEquipList.EquipData[0].NumSubEquip = 2
    zoneEquipList.EquipData[0].SubEquipData = [None] * 2
    zoneEquipList.EquipData[0].SubEquipData[0] = DataZoneEquipment.SubEquipDataStruct()
    zoneEquipList.EquipData[0].SubEquipData[0].Name = coil1Name
    zoneEquipList.EquipData[0].SubEquipData[1] = DataZoneEquipment.SubEquipDataStruct()
    zoneEquipList.EquipData[0].SubEquipData[1].Name = "MyFan1"
    zoneEquipList.EquipData[0].SubEquipData[1].TypeOf = "FAN:ONOFF"
    zoneEquipList.EquipName[1] = "Zone 1 ADU"
    zoneEquipList.EquipTypeName[1] = "ZoneHVAC:AirDistributionUnit"
    zoneEquipList.EquipType[1] = DataZoneEquipment.ZoneEquipType.AirDistributionUnit
    zoneEquipList.EquipData[1] = DataZoneEquipment.EquipDataStruct()
    zoneEquipList.EquipData[1].Name = "Zone 1 ADU"
    zoneEquipList.EquipData[1].NumSubEquip = 1
    zoneEquipList.EquipData[1].SubEquipData = [None] * 1
    zoneEquipList.EquipData[1].SubEquipData[0] = DataZoneEquipment.SubEquipDataStruct()
    zoneEquipList.EquipData[1].SubEquipData[0].Name = "AIRTERMINAL:SINGLEDUCT:VAV:REHEAT"
    zoneEquipList.EquipData[1].SubEquipData[0].NumSubSubEquip = 1
    zoneEquipList.EquipData[1].SubEquipData[0].SubSubEquipData = [None] * 1
    zoneEquipList.EquipData[1].SubEquipData[0].SubSubEquipData[0] = DataZoneEquipment.SubSubEquipDataStruct()
    zoneEquipList.EquipData[1].SubEquipData[0].SubSubEquipData[0].Name = coil2Name
    ReportCoilSelection.setCoilReheatMultiplier(state, ReportCoilSelection.getReportIndex(state, coil2Name, coil2Type), mult)
    c1a = state.dataRptCoilSelection.coils[0]
    c2a = state.dataRptCoilSelection.coils[1]
    c2a.zoneEqNum = curZoneEqNum
    Expect(Util.SameString(c2a.coilLocation, "unknown"))
    Expect(Util.SameString(c2a.typeHVACname, "unknown"))
    Expect(Util.SameString(c2a.userNameforHVACsystem, "unknown"))
    ReportCoilSelection.finishCoilSummaryReportTable(state)
    Expect(Util.SameString(c1a.coilLocation, "Zone Equipment"))
    Expect(Util.SameString(c1a.typeHVACname, "ZoneHVAC:FourPipeFanCoil"))
    Expect(Util.SameString(c1a.userNameforHVACsystem, "Zone 1 FCU"))
    Expect(Util.SameString(c1a.coilName_, coil1Name))
    Expect(Util.SameString(c1a.zoneName[0], "ThisZone"))
    Expect(Util.SameString(c1a.fanTypeName, "FAN:ONOFF"))
    Expect(Util.SameString(c1a.fanAssociatedWithCoilName, "MyFan1"))
    Expect(Util.SameString(c2a.coilLocation, "Zone Equipment"))
    Expect(Util.SameString(c2a.typeHVACname, "ZoneHVAC:AirDistributionUnit"))
    Expect(Util.SameString(c2a.userNameforHVACsystem, "Zone 1 ADU"))
    Expect(Util.SameString(c2a.coilName_, coil2Name))
    Expect(Util.SameString(c2a.zoneName[0], "ThisZone"))
    Expect(zoneEquipList.EquipType[0] == DataZoneEquipment.ZoneEquipType.FourPipeFanCoil)
    Expect(Util.SameString(zoneEquipList.EquipData[0].SubEquipData[0].Name, coil1Name))
    Expect(zoneEquipList.EquipType[1] == DataZoneEquipment.ZoneEquipType.AirDistributionUnit)
    Expect(Util.SameString(zoneEquipList.EquipData[1].SubEquipData[0].SubSubEquipData[0].Name, coil2Name))
    state.dataRptCoilSelection.clear_state()
    ReportCoilSelection.setCoilReheatMultiplier(state, ReportCoilSelection.getReportIndex(state, coil2Name, coil2Type), mult)
    ReportCoilSelection.setCoilReheatMultiplier(state, ReportCoilSelection.getReportIndex(state, coil1Name, coil1Type), mult)
    c1b = state.dataRptCoilSelection.coils[0]
    c2b = state.dataRptCoilSelection.coils[1]
    c1b.zoneEqNum = curZoneEqNum
    c2b.zoneEqNum = curZoneEqNum
    tmpEquipName = zoneEquipList.EquipName[0]
    tmpEquipTypeName = zoneEquipList.EquipTypeName[0]
    tmpEqData = zoneEquipList.EquipData[0]
    tmpEquipType = zoneEquipList.EquipType[0]
    zoneEquipList.EquipName[0] = zoneEquipList.EquipName[1]
    zoneEquipList.EquipTypeName[0] = zoneEquipList.EquipTypeName[1]
    zoneEquipList.EquipType[0] = zoneEquipList.EquipType[1]
    zoneEquipList.EquipData[0] = zoneEquipList.EquipData[1]
    zoneEquipList.EquipName[1] = tmpEquipName
    zoneEquipList.EquipTypeName[1] = tmpEquipTypeName
    zoneEquipList.EquipType[1] = tmpEquipType
    zoneEquipList.EquipData[1] = tmpEqData
    Expect(zoneEquipList.EquipType[0] == DataZoneEquipment.ZoneEquipType.AirDistributionUnit)
    Expect(Util.SameString(zoneEquipList.EquipData[0].SubEquipData[0].SubSubEquipData[0].Name, coil2Name))
    Expect(zoneEquipList.EquipType[1] == DataZoneEquipment.ZoneEquipType.FourPipeFanCoil)
    Expect(Util.SameString(zoneEquipList.EquipData[1].SubEquipData[0].Name, coil1Name))
    ReportCoilSelection.finishCoilSummaryReportTable(state)
    Expect(Util.SameString(c1b.coilLocation, "Zone Equipment"))
    Expect(Util.SameString(c1b.typeHVACname, "ZoneHVAC:AirDistributionUnit"))
    Expect(Util.SameString(c1b.userNameforHVACsystem, "Zone 1 ADU"))
    Expect(Util.SameString(c1b.coilName_, coil2Name))
    Expect(Util.SameString(c1b.zoneName[0], "ThisZone"))
    Expect(Util.SameString(c2b.coilLocation, "Zone Equipment"))
    Expect(Util.SameString(c2b.typeHVACname, "ZoneHVAC:FourPipeFanCoil"))
    Expect(Util.SameString(c2b.userNameforHVACsystem, "Zone 1 FCU"))
    Expect(Util.SameString(c2b.coilName_, coil1Name))
    Expect(Util.SameString(c2b.zoneName[0], "ThisZone"))
    Expect(Util.SameString(c2b.fanTypeName, "FAN:ONOFF"))
    Expect(Util.SameString(c2b.fanAssociatedWithCoilName, "MyFan1"))