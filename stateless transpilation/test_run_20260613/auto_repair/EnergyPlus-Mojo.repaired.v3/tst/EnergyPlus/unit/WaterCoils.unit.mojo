from .Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataAirLoop import *
from EnergyPlus.DataEnvironment import *
from EnergyPlus.DataHVACGlobals import *
from EnergyPlus.DataHeatBalFanSys import *
from EnergyPlus.DataHeatBalance import *
from EnergyPlus.DataLoopNode import *
from EnergyPlus.DataSizing import *
from EnergyPlus.DataZoneEnergyDemands import *
from EnergyPlus.DataZoneEquipment import *
from EnergyPlus.FanCoilUnits import *
from EnergyPlus.Fans import *
from EnergyPlus.FluidProperties import *
from EnergyPlus.General import *
from EnergyPlus.GlobalNames import *
from EnergyPlus.HeatBalanceManager import *
from EnergyPlus.MixedAir import *
from EnergyPlus.OutputReportPredefined import *
from EnergyPlus.Plant.DataPlant import *
from EnergyPlus.PlantUtilities import *
from EnergyPlus.Psychrometrics import *
from EnergyPlus.ReportCoilSelection import *
from EnergyPlus.ScheduleManager import *
from EnergyPlus.SizingManager import *
from EnergyPlus.UtilityRoutines import *
from EnergyPlus.WaterCoils import *
from EnergyPlus.DataAirSystems import *
from EnergyPlus.DataPlant import *
from EnergyPlus.DataSizing import *
from EnergyPlus.DataHeatBalance import *
from EnergyPlus.DataHeatBalFanSys import *
from EnergyPlus.DataZoneEnergyDemands import *
from EnergyPlus.DataZoneEquipment import *

class WaterCoilsTest(EnergyPlusFixture):
    @staticmethod
    def TearDownTestCase():

    def SetUp(self):
        EnergyPlusFixture.SetUp(self)
        state.dataSize.CurZoneEqNum = 0
        state.dataSize.CurSysNum = 0
        state.dataSize.CurOASysNum = 0
        state.dataWaterCoils.NumWaterCoils = 1
        state.dataWaterCoils.WaterCoil = Array[WaterCoilData](state.dataWaterCoils.NumWaterCoils)
        state.dataWaterCoils.WaterCoilNumericFields = Array[WaterCoilNumericFieldData](state.dataWaterCoils.NumWaterCoils)
        state.dataWaterCoils.WaterCoilNumericFields[state.dataWaterCoils.NumWaterCoils - 1].FieldNames = Array[String](17)
        state.dataPlnt.TotNumLoops = 1
        state.dataPlnt.PlantLoop = Array[PlantLoopData](state.dataPlnt.TotNumLoops)
        state.dataSize.PlantSizData = Array[PlantSizingData](1)
        state.dataSize.ZoneEqSizing = Array[ZoneEqSizingData](1)
        state.dataSize.UnitarySysEqSizing = Array[UnitarySysEqSizingData](1)
        state.dataSize.OASysEqSizing = Array[OASysEqSizingData](1)
        state.dataSize.SysSizInput = Array[SysSizInputData](1)
        state.dataSize.ZoneSizingInput = Array[ZoneSizingInputData](1)
        state.dataSize.SysSizPeakDDNum = Array[SysSizPeakDDNumData](1)
        state.dataSize.SysSizPeakDDNum[0].TimeStepAtSensCoolPk = Array[Int](1)
        state.dataSize.SysSizPeakDDNum[0].TimeStepAtCoolFlowPk = Array[Int](1)
        state.dataSize.SysSizPeakDDNum[0].TimeStepAtTotCoolPk = Array[Int](1)
        state.dataSize.SysSizPeakDDNum[0].SensCoolPeakDD = 1
        state.dataSize.SysSizPeakDDNum[0].CoolFlowPeakDD = 1
        state.dataSize.SysSizPeakDDNum[0].TotCoolPeakDD = 1
        state.dataSize.FinalSysSizing = Array[FinalSysSizingData](1)
        state.dataSize.CalcSysSizing = Array[CalcSysSizingData](1)
        state.dataSize.FinalZoneSizing = Array[FinalZoneSizingData](1)
        state.dataAirSystemsData.PrimaryAirSystems = Array[PrimaryAirSystemData](1)
        state.dataAirLoop.AirLoopControlInfo = Array[AirLoopControlInfoData](1)

    def TearDown(self):
        EnergyPlusFixture.TearDown(self)

@fixture
def WaterCoilsTest_WaterCoolingCoilSizing(self: WaterCoilsTest):
    Fluid.GetFluidPropertiesData(state)
    state.dataEnvrn.OutBaroPress = 101325.0
    state.dataEnvrn.StdRhoAir = PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress, 20.0, 0.0)
    state.dataSize.SysSizingRunDone = True
    state.dataSize.NumPltSizInput = 1
    state.dataSize.PlantSizData[0].PlantLoopName = "WaterLoop"
    for l in range(1, state.dataPlnt.TotNumLoops + 1):
        var &loopside = state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand]
        loopside.TotalBranches = 1
        loopside.Branch = Array[BranchData](1)
        var &loopsidebranch = state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0]
        loopsidebranch.TotalComponents = 1
        loopsidebranch.Comp = Array[CompData](1)
    state.dataPlnt.PlantLoop[0].Name = "WaterLoop"
    state.dataPlnt.PlantLoop[0].FluidName = "WATER"
    state.dataPlnt.PlantLoop[0].glycol = Fluid.GetWater(state)
    state.dataSize.FinalSysSizing[0].MixTempAtCoolPeak = 20.0
    state.dataSize.FinalSysSizing[0].CoolSupTemp = 10.0
    state.dataSize.FinalSysSizing[0].MixHumRatAtCoolPeak = 0.01
    state.dataSize.FinalSysSizing[0].DesMainVolFlow = 0.00159
    state.dataSize.FinalSysSizing[0].HeatSupTemp = 25.0
    state.dataSize.FinalSysSizing[0].HeatOutTemp = 5.0
    state.dataSize.FinalSysSizing[0].HeatRetTemp = 20.0
    CoilNum = 1
    var &waterCoil1 = state.dataWaterCoils.WaterCoil[CoilNum - 1]
    waterCoil1.Name = "Test Water Cooling Coil"
    waterCoil1.coilType = HVAC.CoilType.CoolingWater
    waterCoil1.coilReportNum = ReportCoilSelection.getReportIndex(state, waterCoil1.Name, waterCoil1.coilType)
    waterCoil1.WaterPlantLoc.loopNum = 1
    PlantUtilities.SetPlantLocationLinks(state, waterCoil1.WaterPlantLoc)
    waterCoil1.WaterCoilType = DataPlant.PlantEquipmentType.CoilWaterCooling
    waterCoil1.RequestingAutoSize = True
    waterCoil1.DesAirVolFlowRate = AutoSize
    waterCoil1.DesInletAirTemp = AutoSize
    waterCoil1.DesOutletAirTemp = AutoSize
    waterCoil1.DesInletWaterTemp = AutoSize
    waterCoil1.DesInletAirHumRat = AutoSize
    waterCoil1.DesOutletAirHumRat = AutoSize
    waterCoil1.MaxWaterVolFlowRate = AutoSize
    state.dataWaterCoils.WaterCoilNumericFields[CoilNum - 1].FieldNames[3] = "Maximum Flow Rate"
    waterCoil1.WaterInletNodeNum = 1
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp[0].NodeNumIn = waterCoil1.WaterInletNodeNum
    state.dataSize.CurZoneEqNum = 0
    state.dataSize.CurSysNum = 1
    state.dataSize.CurOASysNum = 0
    state.dataSize.SysSizInput[0].CoolCapControl = DataSizing.CapacityControl.VAV
    state.dataSize.PlantSizData[0].ExitTemp = 5.7
    state.dataSize.PlantSizData[0].DeltaT = 5.0
    state.dataSize.FinalSysSizing[0].MassFlowAtCoolPeak = state.dataSize.FinalSysSizing[0].DesMainVolFlow * state.dataEnvrn.StdRhoAir
    state.dataSize.DataWaterLoopNum = 1
    SizeWaterCoil(state, CoilNum)
    expect(waterCoil1.DesAirVolFlowRate == 0.00159)
    expect(state.dataSize.DataPltSizCoolNum == 0)
    expect(state.dataSize.DataWaterLoopNum == 0)
    expect(state.dataSize.DataConstantUsedForSizing == 0.0)
    expect(state.dataSize.DataFractionUsedForSizing == 0.0)
    expect(state.dataSize.DataAirFlowUsedForSizing == 0.0)
    expect(state.dataSize.DataFlowUsedForSizing == 0.0)
    expect(state.dataSize.DataWaterFlowUsedForSizing == 0.0)
    expect(state.dataSize.DataCapacityUsedForSizing == 0.0)
    expect(state.dataSize.DataDesInletAirTemp == 0.0)
    expect(state.dataSize.DataDesOutletAirTemp == 0.0)
    expect(state.dataSize.DataDesOutletAirHumRat == 0.0)
    expect(state.dataSize.DataDesInletAirHumRat == 0.0)
    expect(state.dataSize.DataDesInletWaterTemp == 0.0)
    state.dataSize.FinalSysSizing[0].DesMainVolFlow = 0.00259
    state.dataSize.FinalSysSizing[0].MassFlowAtCoolPeak = state.dataSize.FinalSysSizing[0].DesMainVolFlow * state.dataEnvrn.StdRhoAir
    waterCoil1.Name = "Test Water Cooling Coil 2"
    waterCoil1.DesAirVolFlowRate = AutoSize
    waterCoil1.DesInletAirTemp = AutoSize
    waterCoil1.DesOutletAirTemp = AutoSize
    waterCoil1.DesInletWaterTemp = AutoSize
    waterCoil1.DesInletAirHumRat = AutoSize
    waterCoil1.DesOutletAirHumRat = AutoSize
    waterCoil1.MaxWaterVolFlowRate = AutoSize
    SizeWaterCoil(state, CoilNum)
    expect(waterCoil1.DesAirVolFlowRate == 0.00259)
    expect(state.dataSize.DataPltSizCoolNum == 0)
    expect(state.dataSize.DataWaterLoopNum == 0)
    expect(state.dataSize.DataConstantUsedForSizing == 0.0)
    expect(state.dataSize.DataFractionUsedForSizing == 0.0)
    expect(state.dataSize.DataAirFlowUsedForSizing == 0.0)
    expect(state.dataSize.DataFlowUsedForSizing == 0.0)
    expect(state.dataSize.DataWaterFlowUsedForSizing == 0.0)
    expect(state.dataSize.DataCapacityUsedForSizing == 0.0)
    expect(state.dataSize.DataDesInletAirTemp == 0.0)
    expect(state.dataSize.DataDesOutletAirTemp == 0.0)
    expect(state.dataSize.DataDesOutletAirHumRat == 0.0)
    expect(state.dataSize.DataDesInletAirHumRat == 0.0)
    expect(state.dataSize.DataDesInletWaterTemp == 0.0)
    state.dataSize.CurZoneEqNum = 0
    state.dataSize.CurSysNum = 1
    state.dataSize.CurOASysNum = 0
    state.dataSize.FinalSysSizing[0].DesMainVolFlow = 0.00359
    state.dataSize.FinalSysSizing[0].MassFlowAtCoolPeak = state.dataSize.FinalSysSizing[0].DesMainVolFlow * state.dataEnvrn.StdRhoAir
    state.dataAirLoop.AirLoopControlInfo[0].UnitarySys = True
    waterCoil1.Name = "Test Water Heating Coil"
    waterCoil1.WaterCoilType = DataPlant.PlantEquipmentType.CoilWaterSimpleHeating
    waterCoil1.DesAirVolFlowRate = AutoSize
    waterCoil1.DesInletAirTemp = AutoSize
    waterCoil1.DesOutletAirTemp = AutoSize
    waterCoil1.DesInletWaterTemp = AutoSize
    waterCoil1.DesInletAirHumRat = AutoSize
    waterCoil1.DesOutletAirHumRat = AutoSize
    waterCoil1.MaxWaterVolFlowRate = AutoSize
    SizeWaterCoil(state, CoilNum)
    expect(waterCoil1.DesAirVolFlowRate == 0.00359)
    expect(state.dataSize.DataPltSizCoolNum == 0)
    expect(state.dataSize.DataWaterLoopNum == 0)
    expect(state.dataSize.DataConstantUsedForSizing == 0.0)
    expect(state.dataSize.DataFractionUsedForSizing == 0.0)
    expect(state.dataSize.DataAirFlowUsedForSizing == 0.0)
    expect(state.dataSize.DataFlowUsedForSizing == 0.0)
    expect(state.dataSize.DataWaterFlowUsedForSizing == 0.0)
    expect(state.dataSize.DataCapacityUsedForSizing == 0.0)
    expect(state.dataSize.DataDesInletAirTemp == 0.0)
    expect(state.dataSize.DataDesOutletAirTemp == 0.0)
    expect(state.dataSize.DataDesOutletAirHumRat == 0.0)
    expect(state.dataSize.DataDesInletAirHumRat == 0.0)
    expect(state.dataSize.DataDesInletWaterTemp == 0.0)
    state.dataSize.FinalSysSizing[0].DesMainVolFlow = 0.00459
    state.dataSize.FinalSysSizing[0].MassFlowAtCoolPeak = state.dataSize.FinalSysSizing[0].DesMainVolFlow * state.dataEnvrn.StdRhoAir
    waterCoil1.Name = "Test Water Heating Coil 2"
    waterCoil1.WaterCoilType = DataPlant.PlantEquipmentType.CoilWaterSimpleHeating
    waterCoil1.DesAirVolFlowRate = AutoSize
    waterCoil1.DesInletAirTemp = AutoSize
    waterCoil1.DesOutletAirTemp = AutoSize
    waterCoil1.DesInletWaterTemp = AutoSize
    waterCoil1.DesInletAirHumRat = AutoSize
    waterCoil1.DesOutletAirHumRat = AutoSize
    waterCoil1.MaxWaterVolFlowRate = AutoSize
    SizeWaterCoil(state, CoilNum)
    expect(waterCoil1.DesAirVolFlowRate == 0.00459)
    expect(state.dataSize.DataPltSizCoolNum == 0)
    expect(state.dataSize.DataWaterLoopNum == 0)
    expect(state.dataSize.DataConstantUsedForSizing == 0.0)
    expect(state.dataSize.DataFractionUsedForSizing == 0.0)
    expect(state.dataSize.DataAirFlowUsedForSizing == 0.0)
    expect(state.dataSize.DataFlowUsedForSizing == 0.0)
    expect(state.dataSize.DataWaterFlowUsedForSizing == 0.0)
    expect(state.dataSize.DataCapacityUsedForSizing == 0.0)
    expect(state.dataSize.DataDesInletAirTemp == 0.0)
    expect(state.dataSize.DataDesOutletAirTemp == 0.0)
    expect(state.dataSize.DataDesOutletAirHumRat == 0.0)
    expect(state.dataSize.DataDesInletAirHumRat == 0.0)
    expect(state.dataSize.DataDesInletWaterTemp == 0.0)
    state.dataSize.CurZoneEqNum = 1
    state.dataSize.CurSysNum = 0
    state.dataSize.PlantSizData[0].ExitTemp = 60.0
    state.dataSize.NumZoneSizingInput = 1
    state.dataSize.ZoneSizingRunDone = True
    state.dataSize.ZoneSizingInput[0].ZoneNum = state.dataSize.CurZoneEqNum
    state.dataSize.ZoneEqSizing[0].SizingMethod = Array[Int](25)
    state.dataSize.ZoneEqSizing[0].SizingMethod[HVAC.SystemAirflowSizing] = DataSizing.SupplyAirFlowRate
    state.dataSize.FinalZoneSizing[0].ZoneTempAtHeatPeak = 20.0
    state.dataSize.FinalZoneSizing[0].OutTempAtHeatPeak = -20.0
    state.dataSize.FinalZoneSizing[0].DesHeatCoilInTemp = -20.0
    state.dataSize.FinalZoneSizing[0].DesHeatCoilInHumRat = 0.005
    state.dataSize.FinalZoneSizing[0].HeatDesTemp = 30.0
    state.dataSize.FinalZoneSizing[0].HeatDesHumRat = 0.005
    state.dataSize.ZoneEqSizing[0].OAVolFlow = 0.01
    state.dataSize.ZoneEqSizing[0].HeatingAirFlow = True
    state.dataSize.ZoneEqSizing[0].HeatingAirVolFlow = 0.1
    state.dataSize.FinalZoneSizing[0].DesHeatMassFlow = state.dataEnvrn.StdRhoAir * state.dataSize.ZoneEqSizing[0].HeatingAirVolFlow
    state.dataWaterCoils.MySizeFlag = Array[Bool](1)
    state.dataWaterCoils.MySizeFlag[CoilNum - 1] = True
    state.dataWaterCoils.MyUAAndFlowCalcFlag = Array[Bool](1)
    state.dataWaterCoils.MyUAAndFlowCalcFlag[CoilNum - 1] = True
    waterCoil1.UACoil = AutoSize
    waterCoil1.DesTotWaterCoilLoad = AutoSize
    waterCoil1.DesAirVolFlowRate = AutoSize
    waterCoil1.DesInletAirTemp = AutoSize
    waterCoil1.DesOutletAirTemp = AutoSize
    waterCoil1.DesInletWaterTemp = AutoSize
    waterCoil1.DesInletAirHumRat = AutoSize
    waterCoil1.DesOutletAirHumRat = AutoSize
    waterCoil1.MaxWaterVolFlowRate = AutoSize
    SizeWaterCoil(state, CoilNum)
    expect(waterCoil1.InletAirTemp == 16.0).to_be_near(0.0001)
    expect(waterCoil1.DesTotWaterCoilLoad == 1709.8638).to_be_near(0.0001)
    expect(waterCoil1.UACoil == 51.2456).to_be_near(0.0001)
    expect(waterCoil1.OutletAirTemp == 30.1302).to_be_near(0.0001)

@fixture
def WaterCoilsTest_TdbFnHRhPbTest(self: WaterCoilsTest):
    expect(TdbFnHRhPb(state, 45170., 0.40, 101312.) == 25.0).to_be_near(0.05)
    expect(TdbFnHRhPb(state, 34760., 0.40, 101312.) == 20.0).to_be_near(0.05)
    expect(TdbFnHRhPb(state, 50290., 0.50, 101312.) == 25.0).to_be_near(0.05)
    expect(TdbFnHRhPb(state, 38490., 0.50, 101312.) == 20.0).to_be_near(0.05)

@fixture
def WaterCoilsTest_CoilHeatingWaterUASizing(self: WaterCoilsTest):
    Fluid.GetFluidPropertiesData(state)
    state.dataEnvrn.OutBaroPress = 101325.0
    state.dataEnvrn.StdRhoAir = PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress, 20.0, 0.0)
    state.dataSize.SysSizingRunDone = True
    state.dataSize.NumPltSizInput = 1
    state.dataSize.PlantSizData[0].PlantLoopName = "HotWaterLoop"
    state.dataSize.PlantSizData[0].ExitTemp = 60.0
    state.dataSize.PlantSizData[0].DeltaT = 10.0
    for l in range(1, state.dataPlnt.TotNumLoops + 1):
        var &loopside = state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand]
        loopside.TotalBranches = 1
        loopside.Branch = Array[BranchData](1)
        var &loopsidebranch = state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0]
        loopsidebranch.TotalComponents = 1
        loopsidebranch.Comp = Array[CompData](1)
    state.dataPlnt.PlantLoop[0].Name = "HotWaterLoop"
    state.dataPlnt.PlantLoop[0].FluidName = "WATER"
    state.dataPlnt.PlantLoop[0].glycol = Fluid.GetWater(state)
    state.dataSize.FinalSysSizing[0].DesMainVolFlow = 1.00
    state.dataSize.FinalSysSizing[0].HeatSupTemp = 40.0
    state.dataSize.FinalSysSizing[0].HeatOutTemp = 5.0
    state.dataSize.FinalSysSizing[0].HeatRetTemp = 20.0
    state.dataSize.FinalSysSizing[0].HeatOAOption = DataSizing.OAControl.AllOA
    CoilNum = 1
    var &waterCoil1 = state.dataWaterCoils.WaterCoil[CoilNum - 1]
    waterCoil1.Name = "Water Heating Coil"
    waterCoil1.WaterPlantLoc.loopNum = 1
    PlantUtilities.SetPlantLocationLinks(state, waterCoil1.WaterPlantLoc)
    waterCoil1.WaterCoilType = DataPlant.PlantEquipmentType.CoilWaterSimpleHeating
    waterCoil1.WaterCoilModel = WaterCoils.CoilModel.HeatingSimple
    waterCoil1.availSched = Sched.GetScheduleAlwaysOn(state)
    waterCoil1.RequestingAutoSize = True
    waterCoil1.DesAirVolFlowRate = AutoSize
    waterCoil1.UACoil = AutoSize
    waterCoil1.MaxWaterVolFlowRate = AutoSize
    waterCoil1.CoilPerfInpMeth = state.dataWaterCoils.UAandFlow
    waterCoil1.DesInletAirTemp = AutoSize
    waterCoil1.DesOutletAirTemp = AutoSize
    waterCoil1.DesInletWaterTemp = AutoSize
    waterCoil1.DesInletAirHumRat = AutoSize
    waterCoil1.DesOutletAirHumRat = AutoSize
    state.dataWaterCoils.WaterCoilNumericFields[CoilNum - 1].FieldNames[2] = "Maximum Water Flow Rate"
    waterCoil1.WaterInletNodeNum = 1
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp[0].NodeNumIn = waterCoil1.WaterInletNodeNum
    state.dataSize.CurZoneEqNum = 0
    state.dataSize.CurSysNum = 1
    state.dataSize.CurOASysNum = 0
    state.dataSize.DataWaterLoopNum = 1
    state.dataWaterCoils.MyUAAndFlowCalcFlag = Array[Bool](1)
    state.dataWaterCoils.MyUAAndFlowCalcFlag[0] = True
    state.dataWaterCoils.MySizeFlag = Array[Bool](1)
    state.dataWaterCoils.MySizeFlag[0] = True
    SizeWaterCoil(state, CoilNum)
    expect(waterCoil1.DesAirVolFlowRate == 1.0)
    var CpAirStd: Real64 = 0.0
    var DesMassFlow: Real64 = 0.0
    var DesCoilHeatingLoad: Real64 = 0.0
    CpAirStd = PsyCpAirFnW(0.0)
    DesMassFlow = waterCoil1.DesAirVolFlowRate * state.dataEnvrn.StdRhoAir
    DesCoilHeatingLoad = CpAirStd * DesMassFlow * (40.0 - 5.0)
    expect(waterCoil1.DesWaterHeatingCoilRate == DesCoilHeatingLoad)
    var Cp: Real64 = 0
    var rho: Real64 = 0
    var DesWaterFlowRate: Real64 = 0
    Cp = state.dataPlnt.PlantLoop[0].glycol.getSpecificHeat(state, Constant.HWInitConvTemp, "Unit Test")
    rho = state.dataPlnt.PlantLoop[0].glycol.getDensity(state, Constant.HWInitConvTemp, "Unit Test")
    DesWaterFlowRate = waterCoil1.DesWaterHeatingCoilRate / (10.0 * Cp * rho)
    expect(waterCoil1.MaxWaterVolFlowRate == DesWaterFlowRate)
    expect(waterCoil1.UACoil == 1435.01).to_be_near(0.01)
    state.dataSize.CurZoneEqNum = 1
    state.dataSize.CurTermUnitSizingNum = 1
    state.dataSize.CurSysNum = 0
    state.dataSize.TermUnitSizing = Array[TermUnitSizingData](1)
    state.dataSize.TermUnitFinalZoneSizing = Array[TermUnitFinalZoneSizingData](1)
    state.dataSize.TermUnitSizing[state.dataSize.CurTermUnitSizingNum - 1].AirVolFlow = waterCoil1.DesAirVolFlowRate / 3.0
    state.dataSize.TermUnitSizing[state.dataSize.CurTermUnitSizingNum - 1].MaxHWVolFlow = waterCoil1.MaxWaterVolFlowRate / 3.0
    state.dataSize.TermUnitSizing[state.dataSize.CurTermUnitSizingNum - 1].MinPriFlowFrac = 0.5
    state.dataSize.TermUnitSingDuct = True
    waterCoil1.DesAirVolFlowRate = AutoSize
    waterCoil1.UACoil = AutoSize
    waterCoil1.MaxWaterVolFlowRate = AutoSize
    waterCoil1.CoilPerfInpMeth = state.dataWaterCoils.UAandFlow
    waterCoil1.DesInletAirTemp = AutoSize
    waterCoil1.DesOutletAirTemp = AutoSize
    waterCoil1.DesInletWaterTemp = AutoSize
    waterCoil1.DesInletAirHumRat = AutoSize
    waterCoil1.DesOutletAirHumRat = AutoSize
    state.dataSize.SysSizingRunDone = False
    state.dataSize.ZoneSizingRunDone = True
    state.dataSize.NumZoneSizingInput = 1
    state.dataSize.ZoneSizingInput = Array[ZoneSizingInputData](1)
    state.dataSize.ZoneSizingInput[0].ZoneNum = 1
    state.dataSize.ZoneEqSizing = Array[ZoneEqSizingData](1)
    state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum - 1].SizingMethod = Array[Int](20)
    state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum - 1].SizingMethod[HVAC.HeatingAirflowSizing] = HVAC.HeatingAirflowSizing
    state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum - 1].CoolingAirVolFlow = 0.0
    state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum - 1].HeatingAirVolFlow = 1.0
    state.dataSize.FinalZoneSizing = Array[FinalZoneSizingData](1)
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].DesCoolVolFlow = 0.0
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].DesHeatVolFlow = 1.0
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].DesHeatCoilInTempTU = 10.0
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].ZoneTempAtHeatPeak = 21.0
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].DesHeatCoilInHumRatTU = 0.006
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].ZoneHumRatAtHeatPeak = 0.008
    state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum - 1].copyFromZoneSizing(state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1])
    state.dataWaterCoils.MySizeFlag[0] = True
    SizeWaterCoil(state, CoilNum)
    expect(waterCoil1.UACoil == 577.686).to_be_near(0.01)

@fixture
def WaterCoilsTest_CoilHeatingWaterLowAirFlowUASizing(self: WaterCoilsTest):
    Fluid.GetFluidPropertiesData(state)
    state.dataEnvrn.OutBaroPress = 101325.0
    state.dataEnvrn.StdRhoAir = PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress, 20.0, 0.0)
    state.dataSize.SysSizingRunDone = True
    state.dataSize.NumPltSizInput = 1
    state.dataSize.PlantSizData[0].PlantLoopName = "HotWaterLoop"
    state.dataSize.PlantSizData[0].ExitTemp = 60.0
    state.dataSize.PlantSizData[0].DeltaT = 10.0
    for l in range(1, state.dataPlnt.TotNumLoops + 1):
        var &loopside = state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand]
        loopside.TotalBranches = 1
        loopside.Branch = Array[BranchData](1)
        var &loopsidebranch = state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0]
        loopsidebranch.TotalComponents = 1
        loopsidebranch.Comp = Array[CompData](1)
    state.dataPlnt.PlantLoop[0].Name = "HotWaterLoop"
    state.dataPlnt.PlantLoop[0].FluidName = "WATER"
    state.dataPlnt.PlantLoop[0].glycol = Fluid.GetWater(state)
    state.dataSize.FinalSysSizing[0].DesMainVolFlow = 1.00
    state.dataSize.FinalSysSizing[0].HeatSupTemp = 40.0
    state.dataSize.FinalSysSizing[0].HeatOutTemp = 5.0
    state.dataSize.FinalSysSizing[0].HeatRetTemp = 20.0
    state.dataSize.FinalSysSizing[0].HeatOAOption = DataSizing.OAControl.AllOA
    CoilNum = 1
    var &waterCoil1 = state.dataWaterCoils.WaterCoil[CoilNum - 1]
    waterCoil1.Name = "Water Heating Coil"
    waterCoil1.WaterPlantLoc.loopNum = 1
    PlantUtilities.SetPlantLocationLinks(state, waterCoil1.WaterPlantLoc)
    waterCoil1.WaterCoilType = DataPlant.PlantEquipmentType.CoilWaterSimpleHeating
    waterCoil1.WaterCoilModel = WaterCoils.CoilModel.HeatingSimple
    waterCoil1.availSched = Sched.GetScheduleAlwaysOn(state)
    waterCoil1.RequestingAutoSize = True
    waterCoil1.DesAirVolFlowRate = AutoSize
    waterCoil1.UACoil = AutoSize
    waterCoil1.MaxWaterVolFlowRate = AutoSize
    waterCoil1.CoilPerfInpMeth = state.dataWaterCoils.UAandFlow
    waterCoil1.DesInletAirTemp = AutoSize
    waterCoil1.DesOutletAirTemp = AutoSize
    waterCoil1.DesInletWaterTemp = AutoSize
    waterCoil1.DesInletAirHumRat = AutoSize
    waterCoil1.DesOutletAirHumRat = AutoSize
    state.dataWaterCoils.WaterCoilNumericFields[CoilNum - 1].FieldNames[2] = "Maximum Water Flow Rate"
    waterCoil1.WaterInletNodeNum = 1
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp[0].NodeNumIn = waterCoil1.WaterInletNodeNum
    state.dataSize.CurZoneEqNum = 0
    state.dataSize.CurSysNum = 1
    state.dataSize.CurOASysNum = 0
    state.dataSize.DataWaterLoopNum = 1
    state.dataWaterCoils.MyUAAndFlowCalcFlag = Array[Bool](1)
    state.dataWaterCoils.MyUAAndFlowCalcFlag[0] = True
    state.dataWaterCoils.MySizeFlag = Array[Bool](1)
    state.dataWaterCoils.MySizeFlag[0] = True
    SizeWaterCoil(state, CoilNum)
    expect(waterCoil1.DesAirVolFlowRate == 1.0)
    var CpAirStd: Real64 = 0.0
    var DesMassFlow: Real64 = 0.0
    var DesCoilHeatingLoad: Real64 = 0.0
    CpAirStd = PsyCpAirFnW(0.0)
    DesMassFlow = waterCoil1.DesAirVolFlowRate * state.dataEnvrn.StdRhoAir
    DesCoilHeatingLoad = CpAirStd * DesMassFlow * (40.0 - 5.0)
    expect(waterCoil1.DesWaterHeatingCoilRate == DesCoilHeatingLoad)
    var Cp: Real64 = 0
    var rho: Real64 = 0
    var DesWaterFlowRate: Real64 = 0
    Cp = state.dataPlnt.PlantLoop[0].glycol.getSpecificHeat(state, Constant.HWInitConvTemp, "Unit Test")
    rho = state.dataPlnt.PlantLoop[0].glycol.getDensity(state, Constant.HWInitConvTemp, "Unit Test")
    DesWaterFlowRate = waterCoil1.DesWaterHeatingCoilRate / (10.0 * Cp * rho)
    expect(waterCoil1.MaxWaterVolFlowRate == DesWaterFlowRate)
    expect(waterCoil1.UACoil == 1435.01).to_be_near(0.01)
    state.dataSize.CurZoneEqNum = 1
    state.dataSize.CurSysNum = 0
    state.dataSize.CurTermUnitSizingNum = 1
    state.dataSize.TermUnitSizing = Array[TermUnitSizingData](1)
    state.dataSize.TermUnitFinalZoneSizing = Array[TermUnitFinalZoneSizingData](1)
    state.dataSize.TermUnitSizing[state.dataSize.CurTermUnitSizingNum - 1].AirVolFlow = waterCoil1.DesAirVolFlowRate / 1500.0
    state.dataSize.TermUnitSizing[state.dataSize.CurTermUnitSizingNum - 1].MaxHWVolFlow = waterCoil1.MaxWaterVolFlowRate / 1500.0
    state.dataSize.TermUnitSizing[state.dataSize.CurTermUnitSizingNum - 1].MinPriFlowFrac = 0.5
    state.dataSize.TermUnitSingDuct = True
    waterCoil1.DesAirVolFlowRate = AutoSize
    waterCoil1.UACoil = AutoSize
    waterCoil1.MaxWaterVolFlowRate = AutoSize
    waterCoil1.CoilPerfInpMeth = state.dataWaterCoils.UAandFlow
    waterCoil1.DesInletAirTemp = AutoSize
    waterCoil1.DesOutletAirTemp = AutoSize
    waterCoil1.DesInletWaterTemp = AutoSize
    waterCoil1.DesInletAirHumRat = AutoSize
    waterCoil1.DesOutletAirHumRat = AutoSize
    state.dataSize.SysSizingRunDone = False
    state.dataSize.ZoneSizingRunDone = True
    state.dataSize.NumZoneSizingInput = 1
    state.dataSize.ZoneSizingInput = Array[ZoneSizingInputData](1)
    state.dataSize.ZoneSizingInput[0].ZoneNum = 1
    state.dataSize.ZoneEqSizing = Array[ZoneEqSizingData](1)
    state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum - 1].SizingMethod = Array[Int](20)
    state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum - 1].SizingMethod[HVAC.HeatingAirflowSizing] = HVAC.HeatingAirflowSizing
    state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum - 1].CoolingAirVolFlow = 0.0
    state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum - 1].HeatingAirVolFlow = 1.0
    state.dataSize.FinalZoneSizing = Array[FinalZoneSizingData](1)
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].DesCoolVolFlow = 0.0
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].DesHeatVolFlow = 0.00095
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].DesHeatCoilInTempTU = 10.0
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].ZoneTempAtHeatPeak = 21.0
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].DesHeatCoilInHumRatTU = 0.006
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].ZoneHumRatAtHeatPeak = 0.008
    state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum - 1].copyFromZoneSizing(state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1])
    state.dataWaterCoils.MySizeFlag[0] = True
    SizeWaterCoil(state, CoilNum)
    expect(waterCoil1.InletWaterMassFlowRate > 0.0)
    expect(waterCoil1.InletAirMassFlowRate == 0.0)
    expect(waterCoil1.UACoil == 1.0).to_be_near(0.0001)

@fixture
def WaterCoilsTest_CoilHeatingWaterUASizingLowHwaterInletTemp(self: WaterCoilsTest):
    Fluid.GetFluidPropertiesData(state)
    state.dataEnvrn.OutBaroPress = 101325.0
    state.dataEnvrn.StdRhoAir = PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress, 20.0, 0.0)
    state.dataSize.SysSizingRunDone = True
    state.dataSize.NumPltSizInput = 1
    state.dataSize.PlantSizData[0].PlantLoopName = "HotWaterLoop"
    state.dataSize.PlantSizData[0].ExitTemp = 40.0
    state.dataSize.PlantSizData[0].DeltaT = 10.0
    for l in range(1, state.dataPlnt.TotNumLoops + 1):
        var &loopside = state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand]
        loopside.TotalBranches = 1
        loopside.Branch = Array[BranchData](1)
        var &loopsidebranch = state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0]
        loopsidebranch.TotalComponents = 1
        loopsidebranch.Comp = Array[CompData](1)
    state.dataPlnt.PlantLoop[0].Name = "HotWaterLoop"
    state.dataPlnt.PlantLoop[0].FluidName = "WATER"
    state.dataPlnt.PlantLoop[0].glycol = Fluid.GetWater(state)
    state.dataSize.FinalSysSizing[0].DesMainVolFlow = 1.00
    state.dataSize.FinalSysSizing[0].HeatSupTemp = 40.0
    state.dataSize.FinalSysSizing[0].HeatOutTemp = 5.0
    state.dataSize.FinalSysSizing[0].HeatRetTemp = 20.0
    state.dataSize.FinalSysSizing[0].HeatOAOption = DataSizing.OAControl.AllOA
    CoilNum = 1
    var &waterCoil1 = state.dataWaterCoils.WaterCoil[CoilNum - 1]
    waterCoil1.Name = "Water Heating Coil"
    waterCoil1.WaterPlantLoc.loopNum = 1
    PlantUtilities.SetPlantLocationLinks(state, waterCoil1.WaterPlantLoc)
    waterCoil1.WaterCoilType = DataPlant.PlantEquipmentType.CoilWaterSimpleHeating
    waterCoil1.WaterCoilModel = WaterCoils.CoilModel.HeatingSimple
    waterCoil1.availSched = Sched.GetScheduleAlwaysOn(state)
    waterCoil1.RequestingAutoSize = True
    waterCoil1.DesAirVolFlowRate = AutoSize
    waterCoil1.UACoil = AutoSize
    waterCoil1.MaxWaterVolFlowRate = AutoSize
    waterCoil1.CoilPerfInpMeth = state.dataWaterCoils.UAandFlow
    waterCoil1.DesInletAirTemp = AutoSize
    waterCoil1.DesOutletAirTemp = AutoSize
    waterCoil1.DesInletWaterTemp = AutoSize
    waterCoil1.DesInletAirHumRat = AutoSize
    waterCoil1.DesOutletAirHumRat = AutoSize
    state.dataWaterCoils.WaterCoilNumericFields[CoilNum - 1].FieldNames[2] = "Maximum Water Flow Rate"
    waterCoil1.WaterInletNodeNum = 1
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp[0].NodeNumIn = waterCoil1.WaterInletNodeNum
    state.dataSize.CurZoneEqNum = 0
    state.dataSize.CurSysNum = 1
    state.dataSize.CurOASysNum = 0
    state.dataSize.DataWaterLoopNum = 1
    state.dataWaterCoils.MyUAAndFlowCalcFlag = Array[Bool](1)
    state.dataWaterCoils.MyUAAndFlowCalcFlag[0] = True
    state.dataWaterCoils.MySizeFlag = Array[Bool](1)
    state.dataWaterCoils.MySizeFlag[0] = True
    SizeWaterCoil(state, CoilNum)
    expect(waterCoil1.DesAirVolFlowRate == 1.0)
    var CpAirStd: Real64 = 0.0
    var DesMassFlow: Real64 = 0.0
    var DesCoilHeatingLoad: Real64 = 0.0
    CpAirStd = PsyCpAirFnW(0.0)
    DesMassFlow = waterCoil1.DesAirVolFlowRate * state.dataEnvrn.StdRhoAir
    DesCoilHeatingLoad = CpAirStd * DesMassFlow * (40.0 - 5.0)
    expect(waterCoil1.DesWaterHeatingCoilRate == DesCoilHeatingLoad)
    var Cp: Real64 = 0
    var rho: Real64 = 0
    var DesWaterFlowRate: Real64 = 0
    Cp = state.dataPlnt.PlantLoop[0].glycol.getSpecificHeat(state, Constant.HWInitConvTemp, "Unit Test")
    rho = state.dataPlnt.PlantLoop[0].glycol.getDensity(state, Constant.HWInitConvTemp, "Unit Test")
    DesWaterFlowRate = waterCoil1.DesWaterHeatingCoilRate / (10.0 * Cp * rho)
    expect(waterCoil1.MaxWaterVolFlowRate == DesWaterFlowRate)
    expect(waterCoil1.UACoil == 2479.27).to_be_near(0.01)
    var DesCoilInletWaterTempUsed: Real64 = 0.0
    var fanOp = HVAC.FanOp.Continuous
    var UAMax = waterCoil1.DesWaterHeatingCoilRate
    EstimateCoilInletWaterTemp(state, CoilNum, fanOp, 1.0, UAMax, DesCoilInletWaterTempUsed)
    expect(DesCoilInletWaterTempUsed > state.dataSize.PlantSizData[0].ExitTemp)
    expect(DesCoilInletWaterTempUsed == 48.73).to_be_near(0.01)

@fixture
def WaterCoilsTest_CoilCoolingWaterSimpleSizing(self: WaterCoilsTest):
    state.init_state(state)
    state.dataEnvrn.OutBaroPress = 101325.0
    state.dataEnvrn.StdRhoAir = PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress, 20.0, 0.0)
    ShowMessage(state, "Begin Test: state->dataWaterCoils->WaterCoilsTest, CoilCoolingWaterSimpleSizing")
    state.dataSize.SysSizingRunDone = True
    state.dataSize.NumPltSizInput = 1
    state.dataSize.PlantSizData[0].PlantLoopName = "WaterLoop"
    for l in range(1, state.dataPlnt.TotNumLoops + 1):
        var &loopside = state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand]
        loopside.TotalBranches = 1
        loopside.Branch = Array[BranchData](1)
        var &loopsidebranch = state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0]
        loopsidebranch.TotalComponents = 1
        loopsidebranch.Comp = Array[CompData](1)
    state.dataPlnt.PlantLoop[0].Name = "WaterLoop"
    state.dataPlnt.PlantLoop[0].FluidName = "WATER"
    state.dataPlnt.PlantLoop[0].glycol = Fluid.GetWater(state)
    state.dataSize.FinalSysSizing[0].MixTempAtCoolPeak = 20.0
    state.dataSize.FinalSysSizing[0].MixHumRatAtCoolPeak = 0.01
    state.dataSize.FinalSysSizing[0].CoolSupTemp = 10.0
    state.dataSize.FinalSysSizing[0].CoolSupHumRat = 0.0085
    state.dataSize.FinalSysSizing[0].DesMainVolFlow = 1.00
    state.dataSize.FinalSysSizing[0].MassFlowAtCoolPeak = state.dataSize.FinalSysSizing[0].DesMainVolFlow * state.dataEnvrn.StdRhoAir
    CoilNum = 1
    var &waterCoil1 = state.dataWaterCoils.WaterCoil[CoilNum - 1]
    waterCoil1.Name = "Test Simple Water Cooling Coil"
    waterCoil1.WaterPlantLoc.loopNum = 1
    PlantUtilities.SetPlantLocationLinks(state, waterCoil1.WaterPlantLoc)
    waterCoil1.WaterCoilType = DataPlant.PlantEquipmentType.CoilWaterCooling
    waterCoil1.WaterCoilModel = WaterCoils.CoilModel.CoolingSimple
    waterCoil1.RequestingAutoSize = True
    waterCoil1.DesAirVolFlowRate = AutoSize
    waterCoil1.DesInletAirTemp = AutoSize
    waterCoil1.DesOutletAirTemp = AutoSize
    waterCoil1.DesInletWaterTemp = AutoSize
    waterCoil1.DesInletAirHumRat = AutoSize
    waterCoil1.DesOutletAirHumRat = AutoSize
    waterCoil1.MaxWaterVolFlowRate = AutoSize
    waterCoil1.DesignWaterDeltaTemp = 6.67
    waterCoil1.UseDesignWaterDeltaTemp = True
    state.dataWaterCoils.WaterCoilNumericFields[CoilNum - 1].FieldNames[1] = "Design Water Flow Rate"
    waterCoil1.WaterInletNodeNum = 1
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp[0].NodeNumIn = waterCoil1.WaterInletNodeNum
    state.dataSize.CurZoneEqNum = 0
    state.dataSize.CurSysNum = 1
    state.dataSize.CurOASysNum = 0
    state.dataSize.SysSizInput[0].CoolCapControl = DataSizing.CapacityControl.VAV
    state.dataSize.PlantSizData[0].ExitTemp = 5.7
    state.dataSize.PlantSizData[0].DeltaT = 5.0
    state.dataSize.DataWaterLoopNum = 1
    SizeWaterCoil(state, CoilNum)
    expect(waterCoil1.DesAirVolFlowRate == 1.0)
    var DesCoilCoolingLoad: Real64 = 0.0
    var CoilInEnth: Real64 = 0.0
    var CoilOutEnth: Real64 = 0.0
    CoilInEnth = PsyHFnTdbW(20.0, 0.01)
    CoilOutEnth = PsyHFnTdbW(10.0, 0.0085)
    DesCoilCoolingLoad = waterCoil1.DesAirVolFlowRate * state.dataEnvrn.StdRhoAir * (CoilInEnth - CoilOutEnth)
    expect(waterCoil1.DesWaterCoolingCoilRate == DesCoilCoolingLoad)
    var Cp: Real64 = 0
    var rho: Real64 = 0
    var DesWaterFlowRate: Real64 = 0
    Cp = state.dataPlnt.PlantLoop[0].glycol.getSpecificHeat(state, Constant.CWInitConvTemp, "Unit Test")
    rho = state.dataPlnt.PlantLoop[0].glycol.getDensity(state, Constant.CWInitConvTemp, "Unit Test")
    DesWaterFlowRate = waterCoil1.DesWaterCoolingCoilRate / (waterCoil1.DesignWaterDeltaTemp * Cp * rho)
    expect(waterCoil1.MaxWaterVolFlowRate == DesWaterFlowRate)

@fixture
def WaterCoilsTest_CoilCoolingWaterDetailedSizing(self: WaterCoilsTest):
    state.init_state(state)
    state.dataEnvrn.OutBaroPress = 101325.0
    state.dataEnvrn.StdRhoAir = PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress, 20.0, 0.0)
    ShowMessage(state, "Begin Test: state->dataWaterCoils->WaterCoilsTest, CoilCoolingWaterDetailedSizing")
    state.dataSize.SysSizingRunDone = True
    state.dataSize.NumPltSizInput = 1
    state.dataSize.PlantSizData[0].PlantLoopName = "WaterLoop"
    for l in range(1, state.dataPlnt.TotNumLoops + 1):
        var &loopside = state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand]
        loopside.TotalBranches = 1
        loopside.Branch = Array[BranchData](1)
        var &loopsidebranch = state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0]
        loopsidebranch.TotalComponents = 1
        loopsidebranch.Comp = Array[CompData](1)
    state.dataPlnt.PlantLoop[0].Name = "WaterLoop"
    state.dataPlnt.PlantLoop[0].FluidName = "WATER"
    state.dataPlnt.PlantLoop[0].glycol = Fluid.GetWater(state)
    state.dataSize.FinalSysSizing[0].MixTempAtCoolPeak = 20.0
    state.dataSize.FinalSysSizing[0].MixHumRatAtCoolPeak = 0.01
    state.dataSize.FinalSysSizing[0].CoolSupTemp = 10.0
    state.dataSize.FinalSysSizing[0].CoolSupHumRat = 0.0085
    state.dataSize.FinalSysSizing[0].DesMainVolFlow = 1.00
    state.dataSize.FinalSysSizing[0].MassFlowAtCoolPeak = state.dataSize.FinalSysSizing[0].DesMainVolFlow * state.dataEnvrn.StdRhoAir
    CoilNum = 1
    var &waterCoil1 = state.dataWaterCoils.WaterCoil[CoilNum - 1]
    waterCoil1.Name = "Test Detailed Water Cooling Coil"
    waterCoil1.WaterPlantLoc.loopNum = 1
    PlantUtilities.SetPlantLocationLinks(state, waterCoil1.WaterPlantLoc)
    waterCoil1.WaterCoilType = DataPlant.PlantEquipmentType.CoilWaterCooling
    waterCoil1.WaterCoilModel = WaterCoils.CoilModel.CoolingDetailed
    waterCoil1.TubeOutsideSurfArea = 6.23816
    waterCoil1.TotTubeInsideArea = 6.20007018
    waterCoil1.FinSurfArea = 101.7158224
    waterCoil1.MinAirFlowArea = 0.810606367
    waterCoil1.CoilDepth = 0.165097968
    waterCoil1.FinDiam = 0.43507152
    waterCoil1.FinThickness = 0.001499982
    waterCoil1.TubeInsideDiam = 0.014449958
    waterCoil1.TubeOutsideDiam = 0.015879775
    waterCoil1.TubeThermConductivity = 385.764854
    waterCoil1.FinThermConductivity = 203.882537
    waterCoil1.FinSpacing = 0.001814292
    waterCoil1.TubeDepthSpacing = 0.02589977
    waterCoil1.NumOfTubeRows = 6
    waterCoil1.NumOfTubesPerRow = 16
    waterCoil1.DesignWaterDeltaTemp = 6.67
    waterCoil1.UseDesignWaterDeltaTemp = True
    waterCoil1.RequestingAutoSize = True
    waterCoil1.DesAirVolFlowRate = AutoSize
    waterCoil1.MaxWaterVolFlowRate = AutoSize
    waterCoil1.DesInletAirTemp = AutoSize
    waterCoil1.DesOutletAirTemp = AutoSize
    waterCoil1.DesInletWaterTemp = AutoSize
    waterCoil1.DesInletAirHumRat = AutoSize
    waterCoil1.DesOutletAirHumRat = AutoSize
    waterCoil1.MaxWaterVolFlowRate = AutoSize
    state.dataWaterCoils.WaterCoilNumericFields[CoilNum - 1].FieldNames[1] = "Design Water Flow Rate"
    waterCoil1.WaterInletNodeNum = 1
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp[0].NodeNumIn = waterCoil1.WaterInletNodeNum
    state.dataSize.CurZoneEqNum = 0
    state.dataSize.CurSysNum = 1
    state.dataSize.CurOASysNum = 0
    state.dataSize.SysSizInput[0].CoolCapControl = DataSizing.CapacityControl.VAV
    state.dataSize.PlantSizData[0].ExitTemp = 5.7
    state.dataSize.PlantSizData[0].DeltaT = 5.0
    state.dataSize.DataWaterLoopNum = 1
    SizeWaterCoil(state, CoilNum)
    expect(waterCoil1.DesAirVolFlowRate == 1.0)
    var DesCoilCoolingLoad: Real64 = 0.0
    var CoilInEnth: Real64 = 0.0
    var CoilOutEnth: Real64 = 0.0
    CoilInEnth = PsyHFnTdbW(state.dataSize.FinalSysSizing[0].MixTempAtCoolPeak, state.dataSize.FinalSysSizing[0].MixHumRatAtCoolPeak)
    CoilOutEnth = PsyHFnTdbW(state.dataSize.FinalSysSizing[0].CoolSupTemp, state.dataSize.FinalSysSizing[0].CoolSupHumRat)
    DesCoilCoolingLoad = waterCoil1.DesAirVolFlowRate * state.dataEnvrn.StdRhoAir * (CoilInEnth - CoilOutEnth)
    expect(waterCoil1.DesWaterCoolingCoilRate == DesCoilCoolingLoad)
    var Cp: Real64 = 0
    var rho: Real64 = 0
    var DesWaterFlowRate: Real64 = 0
    Cp = state.dataPlnt.PlantLoop[0].glycol.getSpecificHeat(state, Constant.CWInitConvTemp, "Unit Test")
    rho = state.dataPlnt.PlantLoop[0].glycol.getDensity(state, Constant.CWInitConvTemp, "Unit Test")
    DesWaterFlowRate = waterCoil1.DesWaterCoolingCoilRate / (6.67 * Cp * rho)
    expect(waterCoil1.MaxWaterVolFlowRate == DesWaterFlowRate)

@fixture
def WaterCoilsTest_CoilCoolingWaterDetailed_WarningMath(self: WaterCoilsTest):
    state.init_state(state)
    state.dataEnvrn.OutBaroPress = 101325.0
    state.dataEnvrn.StdRhoAir = PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress, 20.0, 0.0)
    state.dataSize.SysSizingRunDone = True
    state.dataSize.NumPltSizInput = 1
    state.dataSize.PlantSizData[0].PlantLoopName = "WaterLoop"
    for l in range(1, state.dataPlnt.TotNumLoops + 1):
        var &loopside = state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand]
        loopside.TotalBranches = 1
        loopside.Branch = Array[BranchData](1)
        var &loopsidebranch = state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0]
        loopsidebranch.TotalComponents = 1
        loopsidebranch.Comp = Array[CompData](1)
    state.dataPlnt.PlantLoop[0].Name = "WaterLoop"
    state.dataPlnt.PlantLoop[0].FluidName = "WATER"
    state.dataPlnt.PlantLoop[0].glycol = Fluid.GetWater(state)
    state.dataSize.FinalSysSizing[0].MixTempAtCoolPeak = 20.0
    state.dataSize.FinalSysSizing[0].MixHumRatAtCoolPeak = 0.01
    state.dataSize.FinalSysSizing[0].CoolSupTemp = 10.0
    state.dataSize.FinalSysSizing[0].CoolSupHumRat = 0.0085
    state.dataSize.FinalSysSizing[0].DesMainVolFlow = 1.00
    state.dataSize.FinalSysSizing[0].MassFlowAtCoolPeak = state.dataSize.FinalSysSizing[0].DesMainVolFlow * state.dataEnvrn.StdRhoAir
    CoilNum = 1
    var &waterCoil1 = state.dataWaterCoils.WaterCoil[CoilNum - 1]
    waterCoil1.Name = "Test Detailed Water Cooling Coil"
    waterCoil1.coilType = HVAC.CoilType.CoolingWaterDetailed
    waterCoil1.coilReportNum = ReportCoilSelection.getReportIndex(state, waterCoil1.Name, waterCoil1.coilType)
    waterCoil1.availSched = Sched.GetScheduleAlwaysOff(state)
    waterCoil1.WaterCoilType = DataPlant.PlantEquipmentType.CoilWaterDetailedFlatCooling
    waterCoil1.WaterCoilModel = WaterCoils.CoilModel.CoolingDetailed
    waterCoil1.TubeOutsideSurfArea = 6.23816
    waterCoil1.TotTubeInsideArea = 6.20007018
    waterCoil1.FinSurfArea = 101.7158224
    waterCoil1.MinAirFlowArea = 0.810606367
    waterCoil1.CoilDepth = 0.165097968
    waterCoil1.FinDiam = 0.43507152
    waterCoil1.FinThickness = 0.001499982
    waterCoil1.TubeInsideDiam = 0.014449958
    waterCoil1.TubeOutsideDiam = 0.015879775
    waterCoil1.TubeThermConductivity = 385.764854
    waterCoil1.FinThermConductivity = 203.882537
    waterCoil1.FinSpacing = 0.001814292
    waterCoil1.TubeDepthSpacing = 0.02589977
    waterCoil1.NumOfTubeRows = 6
    waterCoil1.NumOfTubesPerRow = 16
    waterCoil1.DesignWaterDeltaTemp = 6.67
    waterCoil1.UseDesignWaterDeltaTemp = True
    waterCoil1.RequestingAutoSize = True
    waterCoil1.DesAirVolFlowRate = AutoSize
    waterCoil1.MaxWaterVolFlowRate = AutoSize
    waterCoil1.DesInletAirTemp = AutoSize
    waterCoil1.DesOutletAirTemp = AutoSize
    waterCoil1.DesInletWaterTemp = AutoSize
    waterCoil1.DesInletAirHumRat = AutoSize
    waterCoil1.DesOutletAirHumRat = AutoSize
    waterCoil1.MaxWaterVolFlowRate = AutoSize
    state.dataWaterCoils.WaterCoilNumericFields[CoilNum - 1].FieldNames[1] = "Design Water Flow Rate"
    waterCoil1.WaterInletNodeNum = 1
    waterCoil1.WaterOutletNodeNum = 2
    waterCoil1.AirInletNodeNum = 3
    waterCoil1.AirOutletNodeNum = 4
    waterCoil1.WaterPlantLoc.loopNum = 1
    waterCoil1.WaterPlantLoc.loopSideNum = DataPlant.LoopSideLocation.Demand
    waterCoil1.WaterPlantLoc.branchNum = 1
    waterCoil1.WaterPlantLoc.compNum = 1
    PlantUtilities.SetPlantLocationLinks(state, waterCoil1.WaterPlantLoc)
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp[0].Name = waterCoil1.Name
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp[0].Type = DataPlant.PlantEquipmentType.CoilWaterDetailedFlatCooling
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp[0].NodeNumIn = waterCoil1.WaterInletNodeNum
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp[0].NodeNumOut = waterCoil1.WaterOutletNodeNum
    state.dataSize.CurZoneEqNum = 0
    state.dataSize.CurSysNum = 1
    state.dataSize.CurOASysNum = 0
    state.dataSize.SysSizInput[0].CoolCapControl = DataSizing.CapacityControl.VAV
    state.dataSize.PlantSizData[0].ExitTemp = 5.7
    state.dataSize.PlantSizData[0].DeltaT = 5.0
    state.dataSize.DataWaterLoopNum = 1
    SizeWaterCoil(state, CoilNum)
    expect(waterCoil1.DesAirVolFlowRate == 1.0)
    var DesCoilCoolingLoad: Real64 = 0.0
    var CoilInEnth: Real64 = 0.0
    var CoilOutEnth: Real64 = 0.0
    CoilInEnth = PsyHFnTdbW(state.dataSize.FinalSysSizing[0].MixTempAtCoolPeak, state.dataSize.FinalSysSizing[0].MixHumRatAtCoolPeak)
    CoilOutEnth = PsyHFnTdbW(state.dataSize.FinalSysSizing[0].CoolSupTemp, state.dataSize.FinalSysSizing[0].CoolSupHumRat)
    DesCoilCoolingLoad = waterCoil1.DesAirVolFlowRate * state.dataEnvrn.StdRhoAir * (CoilInEnth - CoilOutEnth)
    expect(waterCoil1.DesWaterCoolingCoilRate == DesCoilCoolingLoad)
    var Cp: Real64 = 0
    var rho: Real64 = 0
    var DesWaterFlowRate: Real64 = 0
    Cp = state.dataPlnt.PlantLoop[0].glycol.getSpecificHeat(state, Constant.CWInitConvTemp, "Unit Test")
    rho = state.dataPlnt.PlantLoop[0].glycol.getDensity(state, Constant.CWInitConvTemp, "Unit Test")
    DesWaterFlowRate = waterCoil1.DesWaterCoolingCoilRate / (6.67 * Cp * rho)
    expect(waterCoil1.MaxWaterVolFlowRate == DesWaterFlowRate)
    state.dataLoopNodes.Node = Array[NodeData](10)
    InitWaterCoil(state, 1, False)
    var PartLoadRatio: Real64 = 1.0
    var TempAirIn: Real64 = waterCoil1.InletAirTemp
    var InletAirHumRat: Real64 = waterCoil1.InletAirHumRat
    var TempWaterIn: Real64 = waterCoil1.InletWaterTemp
    var AirDensity: Real64 = Psychrometrics.PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress, TempAirIn, InletAirHumRat, "RoutineName")
    var MinAirMassFlow: Real64 = 5.0 * waterCoil1.MinAirFlowArea * AirDensity
    waterCoil1.InletAirMassFlowRate = 1.1 * MinAirMassFlow
    var AirMassFlow: Real64 = waterCoil1.InletAirMassFlowRate / PartLoadRatio
    expect(waterCoil1.MinAirFlowArea == 0.81060636699999999)
    var expected_error = delimited_string([
        "   ** Warning ** Version: missing in IDF, processing for EnergyPlus version=\"{matchVersion}\"",
        "   ** Warning ** Coil:Cooling:Water:DetailedGeometry in Coil =Test Detailed Water Cooling Coil",
        "   **   ~~~   ** Air Flow Rate Velocity has greatly exceeded upper design guidelines of ~2.5 m/s",
        "   **   ~~~   ** Air Mass Flow Rate[kg/s]={:.6f}".format(waterCoil1.InletAirMassFlowRate),
        "   **   ~~~   ** Air Face Velocity[m/s]={:.6f}".format(AirMassFlow / (waterCoil1.MinAirFlowArea * AirDensity)),
        "   **   ~~~   ** Approximate Mass Flow Rate limit for Face Area[kg/s]={:.6f}".format(2.5 * waterCoil1.MinAirFlowArea * AirDensity),
        "   **   ~~~   ** Coil:Cooling:Water:DetailedGeometry could be resized/autosized to handle capacity",
    ])
    CalcDetailFlatFinCoolingCoil(state, CoilNum, 2, HVAC.FanOp.Continuous, 1)
    compare_err_stream(expected_error, True)
    AirMassFlow = waterCoil1.InletAirMassFlowRate / PartLoadRatio
    TempAirIn = waterCoil1.InletAirTemp
    InletAirHumRat = waterCoil1.InletAirHumRat
    TempWaterIn = waterCoil1.InletWaterTemp
    AirDensity = Psychrometrics.PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress, TempAirIn, InletAirHumRat, "RoutineName")
    MinAirMassFlow = 44.7 * waterCoil1.MinAirFlowArea * AirDensity
    waterCoil1.InletAirMassFlowRate = 1.1 * MinAirMassFlow
    AirMassFlow = waterCoil1.InletAirMassFlowRate / PartLoadRatio
    var expected_fatal_error = delimited_string([
        "   ** Severe  ** Coil:Cooling:Water:DetailedGeometry in Coil =Test Detailed Water Cooling Coil",
        "   **   ~~~   ** Air Flow Rate Velocity is > 100MPH (44.7m/s) and simulation cannot continue",
        "   **   ~~~   ** Air Mass Flow Rate[kg/s]={:.6f}".format(waterCoil1.InletAirMassFlowRate),
        "   **   ~~~   ** Air Face Velocity[m/s]={:.6f}".format(AirMassFlow / (waterCoil1.MinAirFlowArea * AirDensity)),
        "   **   ~~~   ** Approximate Mass Flow Rate limit for Face Area[kg/s]={:.6f}".format(44.7 * waterCoil1.MinAirFlowArea * AirDensity),
        "   **  Fatal  ** Coil:Cooling:Water:DetailedGeometry needs to be resized/autosized to handle capacity",
        "   ...Summary of Errors that led to program termination:",
        "   ..... Reference severe error count=1",
        "   ..... Last severe error=Coil:Cooling:Water:DetailedGeometry in Coil =Test Detailed Water Cooling Coil",
    ])
    expect(CalcDetailFlatFinCoolingCoil(state, CoilNum, 2, HVAC.FanOp.Continuous, 1)).to_throw()
    compare_err_stream(expected_fatal_error, True)

@fixture
def WaterCoilsTest_CoilHeatingWaterSimpleSizing(self: WaterCoilsTest):
    state.init_state(state)
    state.dataEnvrn.OutBaroPress = 101325.0
    state.dataEnvrn.StdRhoAir = PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress, 20.0, 0.0)
    ShowMessage(state, "Begin Test: state->dataWaterCoils->WaterCoilsTest, CoilHeatingWaterSimpleSizing")
    state.dataSize.SysSizingRunDone = True
    state.dataSize.NumPltSizInput = 1
    state.dataSize.PlantSizData[0].PlantLoopName = "WaterLoop"
    for l in range(1, state.dataPlnt.TotNumLoops + 1):
        var &loopside = state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand]
        loopside.TotalBranches = 1
        loopside.Branch = Array[BranchData](1)
        var &loopsidebranch = state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0]
        loopsidebranch.TotalComponents = 1
        loopsidebranch.Comp = Array[CompData](1)
    state.dataPlnt.PlantLoop[0].Name = "WaterLoop"
    state.dataPlnt.PlantLoop[0].FluidName = "WATER"
    state.dataPlnt.PlantLoop[0].glycol = Fluid.GetWater(state)
    state.dataSize.FinalSysSizing[0].DesMainVolFlow = 1.00
    state.dataSize.FinalSysSizing[0].HeatSupTemp = 40.0
    state.dataSize.FinalSysSizing[0].HeatOutTemp = 5.0
    state.dataSize.FinalSysSizing[0].HeatRetTemp = 20.0
    state.dataSize.FinalSysSizing[0].HeatOAOption = DataSizing.OAControl.AllOA
    CoilNum = 1
    var &waterCoil1 = state.dataWaterCoils.WaterCoil[CoilNum - 1]
    waterCoil1.Name = "Test Simple Water Heating Coil"
    waterCoil1.WaterPlantLoc.loopNum = 1
    PlantUtilities.SetPlantLocationLinks(state, waterCoil1.WaterPlantLoc)
    waterCoil1.WaterCoilType = DataPlant.PlantEquipmentType.CoilWaterSimpleHeating
    waterCoil1.WaterCoilModel = WaterCoils.CoilModel.HeatingSimple
    waterCoil1.RequestingAutoSize = True
    waterCoil1.DesAirVolFlowRate = AutoSize
    waterCoil1.DesInletAirTemp = AutoSize
    waterCoil1.DesOutletAirTemp = AutoSize
    waterCoil1.DesInletWaterTemp = AutoSize
    waterCoil1.DesInletAirHumRat = AutoSize
    waterCoil1.DesOutletAirHumRat = AutoSize
    waterCoil1.MaxWaterVolFlowRate = AutoSize
    waterCoil1.DesignWaterDeltaTemp = 11.0
    waterCoil1.UseDesignWaterDeltaTemp = True
    state.dataWaterCoils.WaterCoilNumericFields[CoilNum - 1].FieldNames[2] = "Maximum Water Flow Rate"
    waterCoil1.WaterInletNodeNum = 1
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp[0].NodeNumIn = waterCoil1.WaterInletNodeNum
    state.dataSize.CurZoneEqNum = 0
    state.dataSize.CurSysNum = 1
    state.dataSize.CurOASysNum = 0
    state.dataSize.PlantSizData[0].ExitTemp = 60.0
    state.dataSize.PlantSizData[0].DeltaT = 10.0
    state.dataSize.DataWaterLoopNum = 1
    SizeWaterCoil(state, CoilNum)
    expect(waterCoil1.DesAirVolFlowRate == 1.0)
    var CpAirStd: Real64 = 0.0
    var DesMassFlow: Real64 = 0.0
    var DesCoilHeatingLoad: Real64 = 0.0
    CpAirStd = PsyCpAirFnW(0.0)
    DesMassFlow = state.dataSize.FinalSysSizing[0].DesMainVolFlow * state.dataEnvrn.StdRhoAir
    DesCoilHeatingLoad = CpAirStd * DesMassFlow * (40.0 - 5.0)
    expect(waterCoil1.DesWaterHeatingCoilRate == DesCoilHeatingLoad)
    var Cp: Real64 = 0
    var rho: Real64 = 0
    var DesWaterFlowRate: Real64 = 0
    Cp = state.dataPlnt.PlantLoop[0].glycol.getSpecificHeat(state, Constant.HWInitConvTemp, "Unit Test")
    rho = state.dataPlnt.PlantLoop[0].glycol.getDensity(state, Constant.HWInitConvTemp, "Unit Test")
    DesWaterFlowRate = waterCoil1.DesWaterHeatingCoilRate / (11.0 * Cp * rho)
    expect(waterCoil1.MaxWaterVolFlowRate == DesWaterFlowRate)

@fixture
def WaterCoilsTest_HotWaterHeatingCoilAutoSizeTempTest(self: WaterCoilsTest):
    Fluid.GetFluidPropertiesData(state)
    state.dataEnvrn.OutBaroPress = 101325.0
    state.dataEnvrn.StdRhoAir = PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress, 20.0, 0.0)
    state.dataSize.SysSizingRunDone = True
    state.dataSize.NumPltSizInput = 1
    state.dataSize.PlantSizData[0].PlantLoopName = "HotWaterLoop"
    state.dataSize.PlantSizData[0].ExitTemp = 60.0
    state.dataSize.PlantSizData[0].DeltaT = 10.0
    for l in range(1, state.dataPlnt.TotNumLoops + 1):
        var &loopside = state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand]
        loopside.TotalBranches = 1
        loopside.Branch = Array[BranchData](1)
        var &loopsidebranch = state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0]
        loopsidebranch.TotalComponents = 1
        loopsidebranch.Comp = Array[CompData](1)
    state.dataPlnt.PlantLoop[0].Name = "HotWaterLoop"
    state.dataPlnt.PlantLoop[0].FluidName = "WATER"
    state.dataPlnt.PlantLoop[0].glycol = Fluid.GetWater(state)
    state.dataSize.FinalSysSizing[0].DesMainVolFlow = 1.00
    state.dataSize.FinalSysSizing[0].HeatSupTemp = 40.0
    state.dataSize.FinalSysSizing[0].HeatOutTemp = 5.0
    state.dataSize.FinalSysSizing[0].HeatRetTemp = 20.0
    state.dataSize.FinalSysSizing[0].HeatOAOption = DataSizing.OAControl.AllOA
    CoilNum = 1
    var &waterCoil1 = state.dataWaterCoils.WaterCoil[CoilNum - 1]
    waterCoil1.Name = "Water Heating Coil"
    waterCoil1.coilType = HVAC.CoilType.HeatingWater
    waterCoil1.coilReportNum = ReportCoilSelection.getReportIndex(state, waterCoil1.Name, waterCoil1.coilType)
    waterCoil1.WaterPlantLoc.loopNum = 1
    PlantUtilities.SetPlantLocationLinks(state, waterCoil1.WaterPlantLoc)
    waterCoil1.WaterCoilModel = WaterCoils.CoilModel.HeatingSimple
    waterCoil1.WaterCoilType = DataPlant.PlantEquipmentType.CoilWaterSimpleHeating
    waterCoil1.availSched = Sched.GetScheduleAlwaysOn(state)
    waterCoil1.RequestingAutoSize = True
    waterCoil1.DesAirVolFlowRate = AutoSize
    waterCoil1.UACoil = AutoSize
    waterCoil1.MaxWaterVolFlowRate = AutoSize
    waterCoil1.CoilPerfInpMeth = state.dataWaterCoils.UAandFlow
    waterCoil1.DesInletAirTemp = AutoSize
    waterCoil1.DesOutletAirTemp = AutoSize
    waterCoil1.DesInletWaterTemp = AutoSize
    waterCoil1.DesInletAirHumRat = AutoSize
    waterCoil1.DesOutletAirHumRat = AutoSize
    state.dataWaterCoils.WaterCoilNumericFields[CoilNum - 1].FieldNames[2] = "Maximum Water Flow Rate"
    waterCoil1.WaterInletNodeNum = 1
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp[0].NodeNumIn = waterCoil1.WaterInletNodeNum
    state.dataSize.CurZoneEqNum = 0
    state.dataSize.CurSysNum = 1
    state.dataSize.CurOASysNum = 0
    state.dataSize.DataWaterLoopNum = 1
    state.dataWaterCoils.MyUAAndFlowCalcFlag = Array[Bool](1)
    state.dataWaterCoils.MyUAAndFlowCalcFlag[0] = True
    state.dataWaterCoils.MySizeFlag = Array[Bool](1)
    state.dataWaterCoils.MySizeFlag[0] = True
    SizeWaterCoil(state, CoilNum)
    expect(waterCoil1.DesAirVolFlowRate == 1.0)
    var CpAirStd: Real64 = 0.0
    var DesMassFlow: Real64 = 0.0
    var DesCoilHeatingLoad: Real64 = 0.0
    CpAirStd = PsyCpAirFnW(0.0)
    DesMassFlow = waterCoil1.DesAirVolFlowRate * state.dataEnvrn.StdRhoAir
    DesCoilHeatingLoad = DesMassFlow * CpAirStd * (40.0 - 5.0)
    expect(waterCoil1.DesWaterHeatingCoilRate == DesCoilHeatingLoad)
    var Cp: Real64 = 0.0
    var rho: Real64 = 0.0
    var DesWaterFlowRate: Real64 = 0.0
    Cp = state.dataPlnt.PlantLoop[0].glycol.getSpecificHeat(state, 60.0, "Unit Test")
    rho = state.dataPlnt.PlantLoop[0].glycol.getDensity(state, 60.0, "Unit Test")
    DesWaterFlowRate = DesCoilHeatingLoad / (state.dataSize.PlantSizData[0].DeltaT * Cp * rho)
    expect(waterCoil1.MaxWaterVolFlowRate == DesWaterFlowRate)

@fixture
def WaterCoilsTest_FanCoilCoolingWaterFlowTest(self: WaterCoilsTest):
    state.dataSize.PlantSizData = Array[PlantSizingData](2)
    state.dataSize.NumPltSizInput = 2
    state.dataSize.PlantSizData[1].PlantLoopName = "ChilledWaterLoop"
    state.dataSize.PlantSizData[1].ExitTemp = 7.22
    state.dataSize.PlantSizData[1].DeltaT = 6.67
    state.dataSize.PlantSizData[0].PlantLoopName = "HotWaterLoop"
    state.dataSize.PlantSizData[0].ExitTemp = 60
    state.dataSize.PlantSizData[0].DeltaT = 12
    var FanCoilNum: Int = 1
    var ZoneNum: Int = 1
    var FirstHVACIteration: Bool = True
    var ErrorsFound: Bool = False
    var QZnReq: Real64 = 0.0
    var HotWaterMassFlowRate: Real64 = 0.0
    var ColdWaterMassFlowRate: Real64 = 0.0
    var QUnitOut: Real64 = 0.0
    var AirMassFlow: Real64 = 0.0
    var MaxAirMassFlow: Real64 = 0.0
    var LatOutputProvided: Real64 = 0.0
    state.dataEnvrn.OutBaroPress = 101325.0
    state.dataEnvrn.StdRhoAir = 1.20
    state.dataWaterCoils.GetWaterCoilsInputFlag = True
    state.dataGlobalNames.NumCoils = 0
    state.dataGlobal.TimeStepsInHour = 1
    state.dataGlobal.TimeStep = 1
    state.dataGlobal.MinutesInTimeStep = 60
    var idf_objects = delimited_string([
        "	Zone,",
        "	EAST ZONE, !- Name",
        "	0, !- Direction of Relative North { deg }",
        "	0, !- X Origin { m }",
        "	0, !- Y Origin { m }",
        "	0, !- Z Origin { m }",
        "	1, !- Type",
        "	1, !- Multiplier",
        "	autocalculate, !- Ceiling Height { m }",
        "	autocalculate; !- Volume { m3 }",
        "	ZoneHVAC:EquipmentConnections,",
        "	EAST ZONE, !- Zone Name",
        "	Zone1Equipment, !- Zone Conditioning Equipment List Name",
        "	Zone1Inlets, !- Zone Air Inlet Node or NodeList Name",
        "	Zone1Exhausts, !- Zone Air Exhaust Node or NodeList Name",
        "	Zone 1 Node, !- Zone Air Node Name",
        "	Zone 1 Outlet Node;      !- Zone Return Air Node Name",
        "	ZoneHVAC:EquipmentList,",
        "	Zone1Equipment, !- Name",
        "   SequentialLoad,          !- Load Distribution Scheme",
        "	ZoneHVAC:FourPipeFanCoil, !- Zone Equipment 1 Object Type",
        "	Zone1FanCoil, !- Zone Equipment 1 Name",
        "	1, !- Zone Equipment 1 Cooling Sequence",
        "	1;                       !- Zone Equipment 1 Heating or No - Load Sequence",
        "   NodeList,",
        "	Zone1Inlets, !- Name",
        "	Zone1FanCoilAirOutletNode;  !- Node 1 Name",
        "	NodeList,",
        "	Zone1Exhausts, !- Name",
        "	Zone1FanCoilAirInletNode; !- Node 1 Name",
        "	OutdoorAir:NodeList,",
        "	Zone1FanCoilOAInNode;    !- Node or NodeList Name 1",
        "	OutdoorAir:Mixer,",
        "	Zone1FanCoilOAMixer, !- Name",
        "	Zone1FanCoilOAMixerOutletNode, !- Mixed Air Node Name",
        "	Zone1FanCoilOAInNode, !- Outdoor Air Stream Node Name",
        "	Zone1FanCoilExhNode, !- Relief Air Stream Node Name",
        "	Zone1FanCoilAirInletNode; !- Return Air Stream Node Name",
        "	Schedule:Compact,",
        "	FanAndCoilAvailSched, !- Name",
        "	Fraction, !- Schedule Type Limits Name",
        "	Through: 12/31, !- Field 1",
        "	For: AllDays, !- Field 2",
        "	Until: 24:00, 1.0;        !- Field 3",
        "	ScheduleTypeLimits,",
        "	Fraction, !- Name",
        "	0.0, !- Lower Limit Value",
        "	1.0, !- Upper Limit Value",
        "	CONTINUOUS;              !- Numeric Type",
        "   Fan:OnOff,",
        "	Zone1FanCoilFan, !- Name",
        "	FanAndCoilAvailSched, !- Availability Schedule Name",
        "	0.5, !- Fan Total Efficiency",
        "	75.0, !- Pressure Rise { Pa }",
        "	Autosize, !- Maximum Flow Rate { m3 / s }",
        "	0.9, !- Motor Efficiency",
        "	1.0, !- Motor In Airstream Fraction",
        "	Zone1FanCoilOAMixerOutletNode, !- Air Inlet Node Name",
        "	Zone1FanCoilFanOutletNode, !- Air Outlet Node Name",
        "	, !- Fan Power Ratio Function of Speed Ratio Curve Name",
        "	;                        !- Fan Efficiency Ratio Function of Speed Ratio Curve Name	",
        "	Coil:Cooling:Water,",
        "	Zone1FanCoilCoolingCoil, !- Name",
        "	FanAndCoilAvailSched, !- Availability Schedule Namev",
        "	Autosize, !- Design Water Flow Rate { m3 / s }",
        "	Autosize, !- Design Air Flow Rate { m3 / s }",
        "	7.22,   !- Design Inlet Water Temperature { Cv }",
        "	24.340, !- Design Inlet Air Temperature { C }",
        "	14.000, !- Design Outlet Air Temperature { C }",
        "	0.0095, !- Design Inlet Air Humidity Ratio { kgWater / kgDryAir }",
        "	0.0090, !- Design Outlet Air Humidity Ratio { kgWater / kgDryAir }",
        "	Zone1FanCoilChWInletNode, !- Water Inlet Node Name",
        "	Zone1FanCoilChWOutletNode, !- Water Outlet Node Name",
        "	Zone1FanCoilFanOutletNode, !- Air Inlet Node Name",
        "	Zone1FanCoilCCOutletNode, !- Air Outlet Node Name",
        "	SimpleAnalysis, !- Type of Analysis",
        "	CrossFlow;               !- Heat Exchanger Configuration",
        "	Coil:Heating:Water,",
        "   Zone1FanCoilHeatingCoil, !- Name",
        "	FanAndCoilAvailSched, !- Availability Schedule Name",
        "	150.0,   !- U - Factor Times Area Value { W / K }",
        "	Autosize, !- Maximum Water Flow Rate { m3 / s }",
        "	Zone1FanCoilHWInletNode, !- Water Inlet Node Name",
        "	Zone1FanCoilHWOutletNode, !- Water Outlet Node Name",
        "	Zone1FanCoilCCOutletNode, !- Air Inlet Node Name",
        "	Zone1FanCoilAirOutletNode, !- Air Outlet Node Name",
        "	UFactorTimesAreaAndDesignWaterFlowRate, !- Performance Input Method",
        "	autosize, !- Rated Capacity { W }",
        "	82.2, !- Rated Inlet Water Temperature { C }",
        "	16.6, !- Rated Inlet Air Temperature { C }",
        "	71.1, !- Rated Outlet Water Temperature { C }",
        "	32.2, !- Rated Outlet Air Temperature { C }",
        "	;     !- Rated Ratio for Air and Water Convection",
        "	ZoneHVAC:FourPipeFanCoil,",
        "	Zone1FanCoil, !- Name",
        "	FanAndCoilAvailSched, !- Availability Schedule Name",
        "	ConstantFanVariableFlow, !- Capacity Control Method",
        "	0.5, !- Maximum Supply Air Flow Rate { m3 / s }",
        "	0.3, !- Low Speed Supply Air Flow Ratio",
        "	0.6, !- Medium Speed Supply Air Flow Ratio",
        "	0.1, !- Maximum Outdoor Air Flow Rate { m3 / s }",
        "	FanAndCoilAvailSched, !- Outdoor Air Schedule Name",
        "	Zone1FanCoilAirInletNode, !- Air Inlet Node Name",
        "	Zone1FanCoilAirOutletNode, !- Air Outlet Node Name",
        "	OutdoorAir:Mixer, !- Outdoor Air Mixer Object Type",
        "	Zone1FanCoilOAMixer, !- Outdoor Air Mixer Name",
        "	Fan:OnOff, !- Supply Air Fan Object Type",
        "	Zone1FanCoilFan, !- Supply Air Fan Name",
        "	Coil:Cooling:Water, !- Cooling Coil Object Type",
        "	Zone1FanCoilCoolingCoil, !- Cooling Coil Name",
        "	0.0002, !- Maximum Cold Water Flow Rate { m3 / s }",
        "	0.0, !- Minimum Cold Water Flow Rate { m3 / s }",
        "	0.001, !- Cooling Convergence Tolerance",
        "	Coil:Heating:Water, !- Heating Coil Object Type",
        "	Zone1FanCoilHeatingCoil, !- Heating Coil Name",
        "	0.0002, !- Maximum Hot Water Flow Rate { m3 / s }",
        "	0.0, !- Minimum Hot Water Flow Rate { m3 / s }",
        "	0.001; !- Heating Convergence Tolerance",
    ])
    expect(process_idf(idf_objects))
    state.init_state(state)
    GetZoneData(state, ErrorsFound)
    expect(state.dataHeatBal.Zone[0].Name == "EAST ZONE")
    GetZoneEquipmentData(state)
    GetFanInput(state)
    expect(state.dataFans.fans[0].type.__int__() == HVAC.FanType.OnOff.__int__())
    GetFanCoilUnits(state)
    expect(state.dataFanCoilUnits.FanCoil[0].CapCtrlMeth_Num.__int__() == CCM.ConsFanVarFlow.__int__())
    expect(state.dataFanCoilUnits.FanCoil[0].OAMixType == "OUTDOORAIR:MIXER")
    expect(state.dataFanCoilUnits.FanCoil[0].fanType.__int__() == HVAC.FanType.OnOff.__int__())
    expect(state.dataFanCoilUnits.FanCoil[0].CCoilType == "COIL:COOLING:WATER")
    expect(state.dataFanCoilUnits.FanCoil[0].HCoilType == "COIL:HEATING:WATER")
    state.dataPlnt.TotNumLoops = 2
    state.dataPlnt.PlantLoop = Array[PlantLoopData](state.dataPlnt.TotNumLoops)
    AirMassFlow = 0.60
    MaxAirMassFlow = 0.60
    HotWaterMassFlowRate = 0.0
    ColdWaterMassFlowRate = 0.14
    state.dataLoopNodes.Node[state.dataMixedAir.OAMixer[0].RetNode - 1].MassFlowRate = AirMassFlow
    state.dataLoopNodes.Node[state.dataMixedAir.OAMixer[0].RetNode - 1].MassFlowRateMax = MaxAirMassFlow
    state.dataLoopNodes.Node[state.dataMixedAir.OAMixer[0].RetNode - 1].Temp = 24.0
    state.dataLoopNodes.Node[state.dataMixedAir.OAMixer[0].RetNode - 1].Enthalpy = 36000
    state.dataLoopNodes.Node[state.dataMixedAir.OAMixer[0].RetNode - 1].HumRat = PsyWFnTdbH(state, state.dataLoopNodes.Node[state.dataMixedAir.OAMixer[0].RetNode - 1].Temp, state.dataLoopNodes.Node[state.dataMixedAir.OAMixer[0].RetNode - 1].Enthalpy)
    state.dataLoopNodes.Node[state.dataMixedAir.OAMixer[0].InletNode - 1].Temp = 30.0
    state.dataLoopNodes.Node[state.dataMixedAir.OAMixer[0].InletNode - 1].Enthalpy = 53000
    state.dataLoopNodes.Node[state.dataMixedAir.OAMixer[0].InletNode - 1].HumRat = PsyWFnTdbH(state, state.dataLoopNodes.Node[state.dataMixedAir.OAMixer[0].InletNode - 1].Temp, state.dataLoopNodes.Node[state.dataMixedAir.OAMixer[0].InletNode - 1].Enthalpy)
    state.dataLoopNodes.Node[state.dataFanCoilUnits.FanCoil[0].AirInNode - 1].MassFlowRate = AirMassFlow
    state.dataLoopNodes.Node[state.dataFanCoilUnits.FanCoil[0].AirInNode - 1].MassFlowRateMin = AirMassFlow
    state.dataLoopNodes.Node[state.dataFanCoilUnits.FanCoil[0].AirInNode - 1].MassFlowRateMinAvail = AirMassFlow
    state.dataLoopNodes.Node[state.dataFanCoilUnits.FanCoil[0].AirInNode - 1].MassFlowRateMax = MaxAirMassFlow
    state.dataLoopNodes.Node[state.dataFanCoilUnits.FanCoil[0].AirInNode - 1].MassFlowRateMaxAvail = MaxAirMassFlow
    state.dataFanCoilUnits.FanCoil[0].OutAirMassFlow = 0.0
    state.dataFanCoilUnits.FanCoil[0].MaxAirMassFlow = MaxAirMassFlow
    state.dataFanCoilUnits.FanCoil[0].MaxCoolCoilFluidFlow = 0.14
    state.dataFanCoilUnits.FanCoil[0].MaxHeatCoilFluidFlow = 0.14
    state.dataLoopNodes.Node[state.dataFanCoilUnits.FanCoil[0].OutsideAirNode - 1].MassFlowRateMax = 0.0
    state.dataLoopNodes.Node[state.dataFanCoilUnits.FanCoil[0].CoolCoilFluidInletNode - 1].MassFlowRateMax = 0.14
    state.dataLoopNodes.Node[state.dataFanCoilUnits.FanCoil[0].HeatCoilFluidInletNode - 1].MassFlowRateMax = 0.14
    state.dataLoopNodes.Node[state.dataFanCoilUnits.FanCoil[0].CoolCoilFluidInletNode - 1].MassFlowRateMaxAvail = 0.14
    state.dataLoopNodes.Node[state.dataFanCoilUnits.FanCoil[0].HeatCoilFluidInletNode - 1].MassFlowRateMaxAvail = 0.14
    state.dataFans.fans[0].inletAirMassFlowRate = AirMassFlow
    state.dataFans.fans[0].maxAirMassFlowRate = MaxAirMassFlow
    state.dataLoopNodes.Node[state.dataFans.fans[0].inletNodeNum - 1].MassFlowRate = AirMassFlow
    state.dataLoopNodes.Node[state.dataFans.fans[0].inletNodeNum - 1].MassFlowRateMin = AirMassFlow
    state.dataLoopNodes.Node[state.dataFans.fans[0].inletNodeNum - 1].MassFlowRateMax = AirMassFlow
    state.dataLoopNodes.Node[state.dataFans.fans[0].inletNodeNum - 1].MassFlowRateMaxAvail = AirMassFlow
    state.dataWaterCoils.WaterCoil[1].UACoilTotal = 470.0
    state.dataWaterCoils.WaterCoil[1].UACoilExternal = 611.0
    state.dataWaterCoils.WaterCoil[1].UACoilInternal = 2010.0
    state.dataWaterCoils.WaterCoil[1].TotCoilOutsideSurfArea = 50.0
    state.dataLoopNodes.Node[state.dataWaterCoils.WaterCoil[1].AirInletNodeNum - 1].MassFlowRate = AirMassFlow
    state.dataLoopNodes.Node[state.dataWaterCoils.WaterCoil[1].AirInletNodeNum - 1].MassFlowRateMin = AirMassFlow
    state.dataLoopNodes.Node[state.dataWaterCoils.WaterCoil[1].AirInletNodeNum - 1].MassFlowRateMax = AirMassFlow
    state.dataLoopNodes.Node[state.dataWaterCoils.WaterCoil[1].AirInletNodeNum - 1].MassFlowRateMaxAvail = AirMassFlow
    state.dataWaterCoils.WaterCoil[1].InletWaterMassFlowRate = ColdWaterMassFlowRate
    state.dataWaterCoils.WaterCoil[1].MaxWaterMassFlowRate = ColdWaterMassFlowRate
    state.dataLoopNodes.Node[state.dataWaterCoils.WaterCoil[1].WaterInletNodeNum - 1].MassFlowRate = ColdWaterMassFlowRate
    state.dataLoopNodes.Node[state.dataWaterCoils.WaterCoil[1].WaterInletNodeNum - 1].MassFlowRateMaxAvail = ColdWaterMassFlowRate
    state.dataLoopNodes.Node[state.dataWaterCoils.WaterCoil[1].WaterInletNodeNum - 1].Temp = 6.0
    state.dataLoopNodes.Node[state.dataWaterCoils.WaterCoil[1].WaterOutletNodeNum - 1].MassFlowRate = ColdWaterMassFlowRate
    state.dataLoopNodes.Node[state.dataWaterCoils.WaterCoil[1].WaterOutletNodeNum - 1].MassFlowRateMaxAvail = ColdWaterMassFlowRate
    state.dataWaterCoils.WaterCoil[0].AirInletNodeNum = 1
    state.dataLoopNodes.Node[state.dataWaterCoils.WaterCoil[0].AirInletNodeNum - 1].MassFlowRate = AirMassFlow
    state.dataLoopNodes.Node[state.dataWaterCoils.WaterCoil[0].AirInletNodeNum - 1].MassFlowRateMaxAvail = AirMassFlow
    state.dataWaterCoils.WaterCoil[0].WaterInletNodeNum = 1
    state.dataLoopNodes.Node[state.dataWaterCoils.WaterCoil[0].WaterInletNodeNum - 1].Temp = 60.0
    state.dataLoopNodes.Node[state.dataWaterCoils.WaterCoil[0].WaterInletNodeNum - 1].MassFlowRate = HotWaterMassFlowRate
    state.dataLoopNodes.Node[state.dataWaterCoils.WaterCoil[0].WaterInletNodeNum - 1].MassFlowRateMaxAvail = HotWaterMassFlowRate
    state.dataLoopNodes.Node[state.dataWaterCoils.WaterCoil[0].WaterOutletNodeNum - 1].MassFlowRate = HotWaterMassFlowRate
    state.dataLoopNodes.Node[state.dataWaterCoils.WaterCoil[0].WaterOutletNodeNum - 1].MassFlowRateMaxAvail = HotWaterMassFlowRate
    state.dataWaterCoils.WaterCoil[0].InletWaterMassFlowRate = HotWaterMassFlowRate
    state.dataWaterCoils.WaterCoil[0].MaxWaterMassFlowRate = HotWaterMassFlowRate
    for l in range(1, state.dataPlnt.TotNumLoops + 1):
        var &loopside = state.dataPlnt.PlantLoop[l - 1].LoopSide[DataPlant.LoopSideLocation.Demand]
        loopside.TotalBranches = 1
        loopside.Branch = Array[BranchData](1)
        var &loopsidebranch = state.dataPlnt.PlantLoop[l - 1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0]
        loopsidebranch.TotalComponents = 1
        loopsidebranch.Comp = Array[CompData](1)
    state.dataHeatBalFanSys.TempControlType = Array[Int](1)
    state.dataHeatBalFanSys.TempControlType[0] = HVAC.SetptType.DualHeatCool.__int__()
    state.dataWaterCoils.WaterCoil[1].WaterPlantLoc.loopNum = 1
    state.dataWaterCoils.WaterCoil[1].WaterPlantLoc.loopSideNum = DataPlant.LoopSideLocation.Demand
    state.dataWaterCoils.WaterCoil[1].WaterPlantLoc.branchNum = 1
    state.dataWaterCoils.WaterCoil[1].WaterPlantLoc.compNum = 1
    PlantUtilities.SetPlantLocationLinks(state, state.dataWaterCoils.WaterCoil[1].WaterPlantLoc)
    state.dataWaterCoils.WaterCoil[0].WaterPlantLoc.loopNum = 2
    state.dataWaterCoils.WaterCoil[0].WaterPlantLoc.loopSideNum = DataPlant.LoopSideLocation.Demand
    state.dataWaterCoils.WaterCoil[0].WaterPlantLoc.branchNum = 1
    state.dataWaterCoils.WaterCoil[0].WaterPlantLoc.compNum = 1
    PlantUtilities.SetPlantLocationLinks(state, state.dataWaterCoils.WaterCoil[0].WaterPlantLoc)
    state.dataPlnt.PlantLoop[1].Name = "ChilledWaterLoop"
    state.dataPlnt.PlantLoop[1].FluidName = "WATER"
    state.dataPlnt.PlantLoop[1].glycol = Fluid.GetWater(state)
    state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp[0].Name = state.dataWaterCoils.WaterCoil[1].Name
    state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp[0].Type = DataPlant.PlantEquipmentType.CoilWaterCooling
    state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp[0].NodeNumIn = state.dataWaterCoils.WaterCoil[1].WaterInletNodeNum
    state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp[0].NodeNumOut = state.dataWaterCoils.WaterCoil[1].WaterOutletNodeNum
    state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].FlowLock = DataPlant.FlowLock.Unlocked
    state.dataPlnt.PlantLoop[0].Name = "HotWaterLoop"
    state.dataPlnt.PlantLoop[0].FluidName = "WATER"
    state.dataPlnt.PlantLoop[0].glycol = Fluid.GetWater(state)
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp[0].Name = state.dataWaterCoils.WaterCoil[0].Name
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp[0].Type = DataPlant.PlantEquipmentType.CoilWaterSimpleHeating
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp[0].NodeNumIn = state.dataWaterCoils.WaterCoil[0].WaterInletNodeNum
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp[0].NodeNumOut = state.dataWaterCoils.WaterCoil[0].WaterOutletNodeNum
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].FlowLock = DataPlant.FlowLock.Unlocked
    state.dataFanCoilUnits.FanCoil[0].CoolCoilPlantLoc.loopNum = 2
    state.dataFanCoilUnits.FanCoil[0].HeatCoilPlantLoc.loopNum = 1
    state.dataFanCoilUnits.FanCoil[0].CoolCoilPlantLoc.loopSideNum = DataPlant.LoopSideLocation.Demand
    state.dataFanCoilUnits.FanCoil[0].HeatCoilPlantLoc.loopSideNum = DataPlant.LoopSideLocation.Demand
    state.dataFanCoilUnits.FanCoil[0].HeatCoilFluidOutletNodeNum = state.dataWaterCoils.WaterCoil[0].WaterOutletNodeNum
    state.dataFanCoilUnits.FanCoil[0].CoolCoilFluidOutletNodeNum = state.dataWaterCoils.WaterCoil[1].WaterOutletNodeNum
    state.dataFanCoilUnits.FanCoil[0].CoolCoilPlantLoc.branchNum = 1
    state.dataFanCoilUnits.FanCoil[0].CoolCoilPlantLoc.compNum = 1
    state.dataFanCoilUnits.FanCoil[0].HeatCoilPlantLoc.branchNum = 1
    state.dataFanCoilUnits.FanCoil[0].HeatCoilPlantLoc.compNum = 1
    PlantUtilities.SetPlantLocationLinks(state, state.dataFanCoilUnits.FanCoil[0].CoolCoilPlantLoc)
    PlantUtilities.SetPlantLocationLinks(state, state.dataFanCoilUnits.FanCoil[0].HeatCoilPlantLoc)
    state.dataFanCoilUnits.HeatingLoad = False
    state.dataFanCoilUnits.CoolingLoad = True
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand = Array[ZoneSysEnergyDemandData](1)
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].RemainingOutputReqToCoolSP = -4000.00
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].RemainingOutputReqToHeatSP = -8000.0
    state.dataFanCoilUnits.FanCoil[0].SpeedFanSel = 2
    QUnitOut = 0.0
    QZnReq = -4000.0
    state.dataGlobal.DoingSizing = True
    state.dataSize.CurZoneEqNum = 1
    state.dataSize.ZoneSizingRunDone = True
    state.dataSize.ZoneEqSizing = Array[ZoneEqSizingData](state.dataSize.CurZoneEqNum)
    state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum - 1].SizingMethod = Array[Int](25)
    state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum - 1].SizingMethod[24] = 0
    state.dataSize.ZoneEqFanCoil = True
    state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum - 1].DesignSizeFromParent = True
    state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum - 1].AirVolFlow = 0.5
    state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum - 1].MaxCWVolFlow = 0.0002
    state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum - 1].MaxHWVolFlow = 0.0002
    state.dataWaterCoils.WaterCoil[1].DesAirVolFlowRate = DataSizing.AutoSize
    state.dataWaterCoils.WaterCoil[1].MaxWaterVolFlowRate = DataSizing.AutoSize
    Sim4PipeFanCoil(state, FanCoilNum, ZoneNum, FirstHVACIteration, QUnitOut, LatOutputProvided)
    expect(state.dataWaterCoils.WaterCoil[1].DesAirVolFlowRate == 0.5)
    expect(state.dataWaterCoils.WaterCoil[1].MaxWaterVolFlowRate == 0.0002)