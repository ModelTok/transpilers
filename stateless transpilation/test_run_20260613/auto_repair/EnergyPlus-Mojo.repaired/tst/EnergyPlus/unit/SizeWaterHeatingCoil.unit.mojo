from gtest import Test, TestFixture, Expect, Assert
from Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataAirLoop import DataAirLoop
from EnergyPlus.DataAirSystems import DataAirSystems
from EnergyPlus.DataEnvironment import DataEnvironment
from EnergyPlus.DataHVACGlobals import DataHVACGlobals
from EnergyPlus.DataHeatBalance import DataHeatBalance
from EnergyPlus.DataLoopNode import DataLoopNode
from EnergyPlus.DataSizing import DataSizing
from EnergyPlus.DataZoneEquipment import DataZoneEquipment
from EnergyPlus.General import General
from EnergyPlus.GlobalNames import GlobalNames
from EnergyPlus.HeatBalanceManager import HeatBalanceManager
from EnergyPlus.IOFiles import IOFiles
from EnergyPlus.OutputReportPredefined import OutputReportPredefined
from EnergyPlus.PlantUtilities import PlantUtilities
from EnergyPlus.Psychrometrics import Psychrometrics
from EnergyPlus.ScheduleManager import ScheduleManager
from EnergyPlus.SimAirServingZones import SimAirServingZones
from EnergyPlus.SingleDuct import SingleDuct
from EnergyPlus.SizingManager import SizingManager
from EnergyPlus.WaterCoils import WaterCoils
from EnergyPlus.ZoneAirLoopEquipmentManager import ZoneAirLoopEquipmentManager

from EnergyPlus.GlobalNames import *
from EnergyPlus.DataHeatBalance import *
from EnergyPlus.DataPlant import *
from EnergyPlus.DataSizing import *
from EnergyPlus.DataZoneEquipment import *
from EnergyPlus.HeatBalanceManager import *
from EnergyPlus.Psychrometrics import *
from EnergyPlus.SimAirServingZones import *
from EnergyPlus.SingleDuct import *
from EnergyPlus.SizingManager import *
from EnergyPlus.WaterCoils import *
from EnergyPlus.ZoneAirLoopEquipmentManager import *
from EnergyPlus.DataAirSystems import *
from EnergyPlus.DataAirLoop import *
from EnergyPlus.OutputReportPredefined import *
class EnergyPlus:

    @staticmethod
    def TestSizingRoutineForHotWaterCoils1(using: TestFixture):
        var ErrorsFound: Bool = False
        state.dataEnvrn.StdRhoAir = 1.20
        var idf_objects: String = delimited_string([
            "\tZone,",
            "\tSPACE1-1, !- Name",
            "\t0, !- Direction of Relative North { deg }",
            "\t0, !- X Origin { m }",
            "\t0, !- Y Origin { m }",
            "\t0, !- Z Origin { m }",
            "\t1, !- Type",
            "\t1, !- Multiplier",
            "\t2.438400269, !- Ceiling Height {m}",
            "\t239.247360229; !- Volume {m3}",
            "\tSizing:Zone,",
            "\tSPACE1-1, !- Zone or ZoneList Name",
            "\tSupplyAirTemperature, !- Zone Cooling Design Supply Air Temperature Input Method",
            "\t14., !- Zone Cooling Design Supply Air Temperature { C }",
            "\t, !- Zone Cooling Design Supply Air Temperature Difference { deltaC }",
            "\tSupplyAirTemperature, !- Zone Heating Design Supply Air Temperature Input Method",
            "\t50., !- Zone Heating Design Supply Air Temperature { C }",
            "\t, !- Zone Heating Design Supply Air Temperature Difference { deltaC }",
            "\t0.009, !- Zone Cooling Design Supply Air Humidity Ratio { kgWater/kgDryAir }",
            "\t0.004, !- Zone Heating Design Supply Air Humidity Ratio { kgWater/kgDryAir }",
            "\tSZ DSOA SPACE1-1, !- Design Specification Outdoor Air Object Name",
            "\t0.0, !- Zone Heating Sizing Factor",
            "\t0.0, !- Zone Cooling Sizing Factor",
            "\tDesignDayWithLimit, !- Cooling Design Air Flow Method",
            "\t, !- Cooling Design Air Flow Rate { m3/s }",
            "\t, !- Cooling Minimum Air Flow per Zone Floor Area { m3/s-m2 }",
            "\t, !- Cooling Minimum Air Flow { m3/s }",
            "\t, !- Cooling Minimum Air Flow Fraction",
            "\tDesignDay, !- Heating Design Air Flow Method",
            "\t, !- Heating Design Air Flow Rate { m3/s }",
            "\t, !- Heating Maximum Air Flow per Zone Floor Area { m3/s-m2 }",
            "\t, !- Heating Maximum Air Flow { m3/s }",
            "\t, !- Heating Maximum Air Flow Fraction",
            "\tSZ DZAD SPACE1-1;        !- Design Specification Zone Air Distribution Object Name",
            "\tDesignSpecification:ZoneAirDistribution,",
            "\tSZ DZAD SPACE1-1, !- Name",
            "\t1, !- Zone Air Distribution Effectiveness in Cooling Mode { dimensionless }",
            "\t1; !- Zone Air Distribution Effectiveness in Heating Mode { dimensionless }",
            "\tDesignSpecification:OutdoorAir,",
            "\tSZ DSOA SPACE1-1, !- Name",
            "\tsum, !- Outdoor Air Method",
            "\t0.00236, !- Outdoor Air Flow per Person { m3/s-person }",
            "\t0.000305, !- Outdoor Air Flow per Zone Floor Area { m3/s-m2 }",
            "\t0.0; !- Outdoor Air Flow per Zone { m3/s }",
            "\tScheduleTypeLimits,",
            "\tFraction, !- Name",
            "\t0.0, !- Lower Limit Value",
            "\t1.0, !- Upper Limit Value",
            "\tCONTINUOUS; !- Numeric Type",
            "\tSchedule:Compact,",
            "\tReheatCoilAvailSched, !- Name",
            "\tFraction, !- Schedule Type Limits Name",
            "\tThrough: 12/31, !- Field 1",
            "\tFor: AllDays, !- Field 2",
            "\tUntil: 24:00,1.0; !- Field 3",
            "\tZoneHVAC:EquipmentConnections,",
            "\tSPACE1-1, !- Zone Name",
            "\tSPACE1-1 Eq, !- Zone Conditioning Equipment List Name",
            "\tSPACE1-1 In Node, !- Zone Air Inlet Node or NodeList Name",
            "\t, !- Zone Air Exhaust Node or NodeList Name",
            "\tSPACE1-1 Node, !- Zone Air Node Name",
            "\tSPACE1-1 Out Node; !- Zone Return Air Node Name",
            "\tZoneHVAC:EquipmentList,",
            "\tSPACE1-1 Eq, !- Name",
            "   SequentialLoad,          !- Load Distribution Scheme",
            "\tZoneHVAC:AirDistributionUnit, !- Zone Equipment 1 Object Type",
            "\tSPACE1-1 ATU, !- Zone Equipment 1 Name",
            "\t1, !- Zone Equipment 1 Cooling Sequence",
            "\t1; !- Zone Equipment 1 Heating or No - Load Sequence",
            "\tZoneHVAC:AirDistributionUnit,",
            "\tSPACE1-1 ATU, !- Name",
            "\tSPACE1-1 In Node, !- Air Distribution Unit Outlet Node Name",
            "\tAirTerminal:SingleDuct:VAV:Reheat, !- Air Terminal Object Type",
            "\tSPACE1-1 VAV Reheat; !- Air Terminal Name",
            "\tCoil:Heating:Water,",
            "\tGronk1 Zone Coil, !- Name",
            "\tReheatCoilAvailSched, !- Availability Schedule Name",
            "\t, !- U-Factor Times Area Value { W/K }",
            "\t, !- Maximum Water Flow Rate { m3/s }",
            "\tSPACE1-1 Zone Coil Water In Node, !- Water Inlet Node Name",
            "\tSPACE1-1 Zone Coil Water Out Node, !- Water Outlet Node Name",
            "\tSPACE1-1 Zone Coil Air In Node, !- Air Inlet Node Name",
            "\tSPACE1-1 In Node, !- Air Outlet Node Name",
            "\tNominalCapacity, !- Performance Input Method",
            "\t10000., !- Rated Capacity { W }",
            "\t82.2, !- Rated Inlet Water Temperature { C }",
            "\t16.6, !- Rated Inlet Air Temperature { C }",
            "\t71.1, !- Rated Outlet Water Temperature { C }",
            "\t32.2, !- Rated Outlet Air Temperature { C }",
            "\t; !- Rated Ratio for Air and Water Convection",
            "\tAirTerminal:SingleDuct:VAV:Reheat,",
            "\tSPACE1-1 VAV Reheat, !- Name",
            "\tReheatCoilAvailSched, !- Availability Schedule Name",
            "\tSPACE1-1 Zone Coil Air In Node, !- Damper Air Outlet Node Name",
            "\tSPACE1-1 ATU In Node, !- Air Inlet Node Name",
            "\tautosize, !- Maximum Air Flow Rate { m3/s }",
            "\t, !- Zone Minimum Air Flow Input Method",
            "\t, !- Constant Minimum Air Flow Fraction",
            "\t, !- Fixed Minimum Air Flow Rate { m3/s }",
            "\t, !- Minimum Air Flow Fraction Schedule Name",
            "\tCoil:Heating:Water, !- Reheat Coil Object Type",
            "\tGronk1 Zone Coil, !- Reheat Coil Name",
            "\tautosize, !- Maximum Hot Water or Steam Flow Rate { m3/s }",
            "\t0.0, !- Minimum Hot Water or Steam Flow Rate { m3/s }",
            "\tSPACE1-1 In Node, !- Air Outlet Node Name",
            "\t0.001, !- Convergence Tolerance",
            "\t, !- Damper Heating Action",
            "\t, !- Maximum Flow per Zone Floor Area During Reheat { m3/s-m2 }",
            "\t; !- Maximum Flow Fraction During Reheat",
        ])
        Assert(process_idf(idf_objects))
        state.init_state(state)
        state.dataSize.FinalZoneSizing.allocate(1)
        state.dataSize.TermUnitFinalZoneSizing.allocate(1)
        state.dataSize.CalcFinalZoneSizing.allocate(1)
        state.dataSize.TermUnitSizing.allocate(1)
        state.dataSize.ZoneEqSizing.allocate(1)
        state.dataPlnt.TotNumLoops = 1
        state.dataPlnt.PlantLoop.allocate(state.dataPlnt.TotNumLoops)
        state.dataSize.PlantSizData.allocate(1)
        state.dataWaterCoils.MySizeFlag.allocate(1)
        state.dataWaterCoils.MyUAAndFlowCalcFlag.allocate(1)
        state.dataSize.NumPltSizInput = 1
        for l in range(1, state.dataPlnt.TotNumLoops+1):
            var loopside: & = state.dataPlnt.PlantLoop[l].LoopSide[DataPlant.LoopSideLocation.Demand]
            loopside.TotalBranches = 1
            loopside.Branch.allocate(1)
            var loopsidebranch: & = state.dataPlnt.PlantLoop[l].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1]
            loopsidebranch.TotalComponents = 1
            loopsidebranch.Comp.allocate(1)
        GetZoneData(state, ErrorsFound)
        Expect_EQ("SPACE1-1", state.dataHeatBal.Zone[1].Name)
        GetOARequirements(state)      # get the OA requirements object
        GetZoneAirDistribution(state) # get zone air distribution objects
        GetZoneSizingInput(state)
        GetZoneEquipmentData(state)
        GetZoneAirLoopEquipment(state)
        GetWaterCoilInput(state)
        state.dataWaterCoils.GetWaterCoilsInputFlag = False
        state.dataWaterCoils.MySizeFlag[1] = True
        state.dataWaterCoils.MyUAAndFlowCalcFlag[1] = False
        GetSysInput(state)
        state.dataSize.TermUnitSingDuct = True
        state.dataPlnt.PlantLoop[1].Name = "HotWaterLoop"
        state.dataPlnt.PlantLoop[1].FluidName = "WATER"
        state.dataPlnt.PlantLoop[1].glycol = Fluid.GetWater(state)
        state.dataWaterCoils.WaterCoil[1].WaterPlantLoc = {1, DataPlant.LoopSideLocation.Demand, 1, 1}
        PlantUtilities.SetPlantLocationLinks(state, state.dataWaterCoils.WaterCoil[1].WaterPlantLoc)
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].Name = state.dataWaterCoils.WaterCoil[1].Name
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].Type = DataPlant.PlantEquipmentType.CoilWaterSimpleHeating
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].NodeNumIn = state.dataWaterCoils.WaterCoil[1].WaterInletNodeNum
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].NodeNumOut = state.dataWaterCoils.WaterCoil[1].WaterOutletNodeNum
        state.dataSingleDuct.sd_airterminal[1].HWplantLoc = {1, DataPlant.LoopSideLocation.Demand, 1, 0}
        PlantUtilities.SetPlantLocationLinks(state, state.dataSingleDuct.sd_airterminal[1].HWplantLoc)
        state.dataSize.PlantSizData[1].DeltaT = 11.0
        state.dataSize.PlantSizData[1].ExitTemp = 82
        state.dataSize.PlantSizData[1].PlantLoopName = "HotWaterLoop"
        state.dataSize.PlantSizData[1].LoopType = DataSizing.TypeOfPlantLoop.Heating
        state.dataSize.ZoneSizingRunDone = True
        state.dataSize.CurZoneEqNum = 1
        state.dataSize.CurSysNum = 0
        state.dataHeatBal.Zone[1].FloorArea = 99.16
        state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum].DesignSizeFromParent = False
        state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum].SizingMethod.allocate(25)
        state.dataSize.CurTermUnitSizingNum = 1
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolVolFlow = 0.28794
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatVolFlow = 0.12046
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatCoilInTempTU = 16.7
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatCoilInHumRatTU = 0.008
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolVolFlow = 0.28794
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatVolFlow = 0.12046
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolMinAirFlowFrac = state.dataSize.ZoneSizingInput[state.dataSize.CurZoneEqNum].DesCoolMinAirFlowFrac
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].NonAirSysDesHeatVolFlow = 0.12046
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].HeatSizingFactor = 1.0
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].NonAirSysDesHeatLoad = 3191.7
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].ZoneTempAtHeatPeak = 21.099
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].ZoneHumRatAtHeatPeak = 0.0038485
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatCoilInTempTU = 16.6
        state.dataSize.TermUnitSizing[state.dataSize.CurZoneEqNum].AirVolFlow = 0.12046
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolMinAirFlow = state.dataSize.ZoneSizingInput[state.dataSize.CurZoneEqNum].DesCoolMinAirFlow
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolMinAirFlowFrac = state.dataSize.ZoneSizingInput[state.dataSize.CurZoneEqNum].DesCoolMinAirFlowFrac
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolMinAirFlow2 = state.dataSize.ZoneSizingInput[state.dataSize.CurZoneEqNum].DesCoolMinAirFlowPerArea * state.dataHeatBal.Zone[1].FloorArea
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolVolFlowMin = max(
            state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolMinAirFlow,
            state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolMinAirFlow2,
            state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolVolFlow * state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolMinAirFlowFrac
        )
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatMaxAirFlow = state.dataSize.ZoneSizingInput[state.dataSize.CurZoneEqNum].DesHeatMaxAirFlow
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatMaxAirFlowFrac = state.dataSize.ZoneSizingInput[state.dataSize.CurZoneEqNum].DesHeatMaxAirFlowFrac
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatMaxAirFlowPerArea = state.dataSize.ZoneSizingInput[state.dataSize.CurZoneEqNum].DesHeatMaxAirFlowPerArea
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatMaxAirFlow2 = state.dataSize.ZoneSizingInput[state.dataSize.CurZoneEqNum].DesHeatMaxAirFlowPerArea * state.dataHeatBal.Zone[1].FloorArea
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatVolFlowMax = max(
            state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatMaxAirFlow,
            state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatMaxAirFlow2,
            max(
                state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolVolFlow,
                state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatVolFlow
            ) * state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatMaxAirFlowFrac
        )
        state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].copyFromZoneSizing(state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum])
        state.dataSingleDuct.sd_airterminal[1].ZoneFloorArea = state.dataHeatBal.Zone[1].FloorArea
        state.dataSingleDuct.sd_airterminal[1].SizeSys(state)
        SizeWaterCoil(state, 1)
        Expect_NEAR(state.dataWaterCoils.WaterCoil[1].UACoil, 199.86, 0.01)
        state.dataLoopNodes.Node.deallocate()
        state.dataZoneEquip.ZoneEquipConfig.deallocate()
        state.dataHeatBal.Zone.deallocate()
        state.dataSize.FinalZoneSizing.deallocate()
        state.dataSize.TermUnitFinalZoneSizing.deallocate()
        state.dataSize.CalcFinalZoneSizing.deallocate()
        state.dataSize.TermUnitSizing.deallocate()
        state.dataSingleDuct.sd_airterminal.deallocate()
        state.dataSize.ZoneEqSizing.deallocate()
        state.dataPlnt.PlantLoop.deallocate()
        state.dataSize.PlantSizData.deallocate()
        state.dataWaterCoils.MySizeFlag.deallocate()
        state.dataWaterCoils.MyUAAndFlowCalcFlag.deallocate()

    @staticmethod
    def TestSizingRoutineForHotWaterCoils2(using: TestFixture):
        var ErrorsFound: Bool = False
        state.dataEnvrn.StdRhoAir = 1.20
        var idf_objects: String = delimited_string([
            "\tZone,",
            "\tSPACE1-1, !- Name",
            "\t0, !- Direction of Relative North { deg }",
            "\t0, !- X Origin { m }",
            "\t0, !- Y Origin { m }",
            "\t0, !- Z Origin { m }",
            "\t1, !- Type",
            "\t1, !- Multiplier",
            "\t2.438400269, !- Ceiling Height {m}",
            "\t239.247360229; !- Volume {m3}",
            "\tSizing:Zone,",
            "\tSPACE1-1, !- Zone or ZoneList Name",
            "\tSupplyAirTemperature, !- Zone Cooling Design Supply Air Temperature Input Method",
            "\t14., !- Zone Cooling Design Supply Air Temperature { C }",
            "\t, !- Zone Cooling Design Supply Air Temperature Difference { deltaC }",
            "\tSupplyAirTemperature, !- Zone Heating Design Supply Air Temperature Input Method",
            "\t50., !- Zone Heating Design Supply Air Temperature { C }",
            "\t, !- Zone Heating Design Supply Air Temperature Difference { deltaC }",
            "\t0.009, !- Zone Cooling Design Supply Air Humidity Ratio { kgWater/kgDryAir }",
            "\t0.004, !- Zone Heating Design Supply Air Humidity Ratio { kgWater/kgDryAir }",
            "\tSZ DSOA SPACE1-1, !- Design Specification Outdoor Air Object Name",
            "\t0.0, !- Zone Heating Sizing Factor",
            "\t0.0, !- Zone Cooling Sizing Factor",
            "\tDesignDayWithLimit, !- Cooling Design Air Flow Method",
            "\t, !- Cooling Design Air Flow Rate { m3/s }",
            "\t, !- Cooling Minimum Air Flow per Zone Floor Area { m3/s-m2 }",
            "\t, !- Cooling Minimum Air Flow { m3/s }",
            "\t, !- Cooling Minimum Air Flow Fraction",
            "\tDesignDay, !- Heating Design Air Flow Method",
            "\t, !- Heating Design Air Flow Rate { m3/s }",
            "\t, !- Heating Maximum Air Flow per Zone Floor Area { m3/s-m2 }",
            "\t, !- Heating Maximum Air Flow { m3/s }",
            "\t, !- Heating Maximum Air Flow Fraction",
            "\tSZ DZAD SPACE1-1;        !- Design Specification Zone Air Distribution Object Name",
            "\tDesignSpecification:ZoneAirDistribution,",
            "\tSZ DZAD SPACE1-1, !- Name",
            "\t1, !- Zone Air Distribution Effectiveness in Cooling Mode { dimensionless }",
            "\t1; !- Zone Air Distribution Effectiveness in Heating Mode { dimensionless }",
            "\tDesignSpecification:OutdoorAir,",
            "\tSZ DSOA SPACE1-1, !- Name",
            "\tsum, !- Outdoor Air Method",
            "\t0.00236, !- Outdoor Air Flow per Person { m3/s-person }",
            "\t0.000305, !- Outdoor Air Flow per Zone Floor Area { m3/s-m2 }",
            "\t0.0; !- Outdoor Air Flow per Zone { m3/s }",
            "\tScheduleTypeLimits,",
            "\tFraction, !- Name",
            "\t0.0, !- Lower Limit Value",
            "\t1.0, !- Upper Limit Value",
            "\tCONTINUOUS; !- Numeric Type",
            "\tSchedule:Compact,",
            "\tReheatCoilAvailSched, !- Name",
            "\tFraction, !- Schedule Type Limits Name",
            "\tThrough: 12/31, !- Field 1",
            "\tFor: AllDays, !- Field 2",
            "\tUntil: 24:00,1.0; !- Field 3",
            "\tZoneHVAC:EquipmentConnections,",
            "\tSPACE1-1, !- Zone Name",
            "\tSPACE1-1 Eq, !- Zone Conditioning Equipment List Name",
            "\tSPACE1-1 In Node, !- Zone Air Inlet Node or NodeList Name",
            "\t, !- Zone Air Exhaust Node or NodeList Name",
            "\tSPACE1-1 Node, !- Zone Air Node Name",
            "\tSPACE1-1 Out Node; !- Zone Return Air Node Name",
            "\tZoneHVAC:EquipmentList,",
            "\tSPACE1-1 Eq, !- Name",
            "   SequentialLoad,          !- Load Distribution Scheme",
            "\tZoneHVAC:AirDistributionUnit, !- Zone Equipment 1 Object Type",
            "\tSPACE1-1 ATU, !- Zone Equipment 1 Name",
            "\t1, !- Zone Equipment 1 Cooling Sequence",
            "\t1; !- Zone Equipment 1 Heating or No - Load Sequence",
            "\tZoneHVAC:AirDistributionUnit,",
            "\tSPACE1-1 ATU, !- Name",
            "\tSPACE1-1 In Node, !- Air Distribution Unit Outlet Node Name",
            "\tAirTerminal:SingleDuct:VAV:Reheat, !- Air Terminal Object Type",
            "\tSPACE1-1 VAV Reheat; !- Air Terminal Name",
            "\tCoil:Heating:Water,",
            "\tGronk1 Zone Coil, !- Name",
            "\tReheatCoilAvailSched, !- Availability Schedule Name",
            "\t, !- U-Factor Times Area Value { W/K }",
            "\t, !- Maximum Water Flow Rate { m3/s }",
            "\tSPACE1-1 Zone Coil Water In Node, !- Water Inlet Node Name",
            "\tSPACE1-1 Zone Coil Water Out Node, !- Water Outlet Node Name",
            "\tSPACE1-1 Zone Coil Air In Node, !- Air Inlet Node Name",
            "\tSPACE1-1 In Node, !- Air Outlet Node Name",
            "\tUFactorTimesAreaAndDesignWaterFlowRate, !- Performance Input Method",
            "\t, !- Rated Capacity { W }",
            "\t82.2, !- Rated Inlet Water Temperature { C }",
            "\t16.6, !- Rated Inlet Air Temperature { C }",
            "\t71.1, !- Rated Outlet Water Temperature { C }",
            "\t32.2, !- Rated Outlet Air Temperature { C }",
            "\t; !- Rated Ratio for Air and Water Convection",
            "\tAirTerminal:SingleDuct:VAV:Reheat,",
            "\tSPACE1-1 VAV Reheat, !- Name",
            "\tReheatCoilAvailSched, !- Availability Schedule Name",
            "\tSPACE1-1 Zone Coil Air In Node, !- Damper Air Outlet Node Name",
            "\tSPACE1-1 ATU In Node, !- Air Inlet Node Name",
            "\tautosize, !- Maximum Air Flow Rate { m3/s }",
            "\t, !- Zone Minimum Air Flow Input Method",
            "\t, !- Constant Minimum Air Flow Fraction",
            "\t, !- Fixed Minimum Air Flow Rate { m3/s }",
            "\t, !- Minimum Air Flow Fraction Schedule Name",
            "\tCoil:Heating:Water, !- Reheat Coil Object Type",
            "\tGronk1 Zone Coil, !- Reheat Coil Name",
            "\tautosize, !- Maximum Hot Water or Steam Flow Rate { m3/s }",
            "\t0.0, !- Minimum Hot Water or Steam Flow Rate { m3/s }",
            "\tSPACE1-1 In Node, !- Air Outlet Node Name",
            "\t0.001, !- Convergence Tolerance",
            "\t, !- Damper Heating Action",
            "\t, !- Maximum Flow per Zone Floor Area During Reheat { m3/s-m2 }",
            "\t; !- Maximum Flow Fraction During Reheat",
        ])
        Assert(process_idf(idf_objects))
        state.init_state(state)
        state.dataSize.FinalZoneSizing.allocate(1)
        state.dataSize.TermUnitFinalZoneSizing.allocate(1)
        state.dataSize.CalcFinalZoneSizing.allocate(1)
        state.dataSize.TermUnitSizing.allocate(1)
        state.dataSize.ZoneEqSizing.allocate(1)
        state.dataPlnt.TotNumLoops = 1
        state.dataPlnt.PlantLoop.allocate(state.dataPlnt.TotNumLoops)
        state.dataSize.PlantSizData.allocate(1)
        state.dataWaterCoils.MySizeFlag.allocate(1)
        state.dataWaterCoils.MyUAAndFlowCalcFlag.allocate(1)
        state.dataSize.NumPltSizInput = 1
        for l in range(1, state.dataPlnt.TotNumLoops+1):
            var loopside: & = state.dataPlnt.PlantLoop[l].LoopSide[DataPlant.LoopSideLocation.Demand]
            loopside.TotalBranches = 1
            loopside.Branch.allocate(1)
            var loopsidebranch: & = state.dataPlnt.PlantLoop[l].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1]
            loopsidebranch.TotalComponents = 1
            loopsidebranch.Comp.allocate(1)
        GetZoneData(state, ErrorsFound)
        Expect_EQ("SPACE1-1", state.dataHeatBal.Zone[1].Name)
        GetOARequirements(state)      # get the OA requirements object
        GetZoneAirDistribution(state) # get zone air distribution objects
        GetZoneSizingInput(state)
        GetZoneEquipmentData(state)
        GetZoneAirLoopEquipment(state)
        GetWaterCoilInput(state)
        state.dataWaterCoils.GetWaterCoilsInputFlag = False
        state.dataWaterCoils.MySizeFlag[1] = True
        state.dataWaterCoils.MyUAAndFlowCalcFlag[1] = False
        GetSysInput(state)
        state.dataSize.TermUnitSingDuct = True
        state.dataPlnt.PlantLoop[1].Name = "HotWaterLoop"
        state.dataPlnt.PlantLoop[1].FluidName = "WATER"
        state.dataPlnt.PlantLoop[1].glycol = Fluid.GetWater(state)
        state.dataWaterCoils.WaterCoil[1].WaterPlantLoc = {1, DataPlant.LoopSideLocation.Demand, 1, 1}
        PlantUtilities.SetPlantLocationLinks(state, state.dataWaterCoils.WaterCoil[1].WaterPlantLoc)
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].Name = state.dataWaterCoils.WaterCoil[1].Name
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].Type = DataPlant.PlantEquipmentType.CoilWaterSimpleHeating
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].NodeNumIn = state.dataWaterCoils.WaterCoil[1].WaterInletNodeNum
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].NodeNumOut = state.dataWaterCoils.WaterCoil[1].WaterOutletNodeNum
        state.dataSingleDuct.sd_airterminal[1].HWplantLoc = {1, DataPlant.LoopSideLocation.Demand, 1, 0}
        PlantUtilities.SetPlantLocationLinks(state, state.dataSingleDuct.sd_airterminal[1].HWplantLoc)
        state.dataSize.PlantSizData[1].DeltaT = 11.0
        state.dataSize.PlantSizData[1].ExitTemp = 82
        state.dataSize.PlantSizData[1].PlantLoopName = "HotWaterLoop"
        state.dataSize.PlantSizData[1].LoopType = DataSizing.TypeOfPlantLoop.Heating
        state.dataSize.ZoneSizingRunDone = True
        state.dataSize.CurZoneEqNum = 1
        state.dataSize.CurSysNum = 0
        state.dataHeatBal.Zone[1].FloorArea = 99.16
        state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum].DesignSizeFromParent = False
        state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum].SizingMethod.allocate(25)
        state.dataSize.CurTermUnitSizingNum = 1
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolVolFlow = 0.28794
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatVolFlow = 0.12046
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatCoilInTempTU = 16.6
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatCoilInHumRatTU = 0.008
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolVolFlow = 0.28794
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatVolFlow = 0.12046
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolMinAirFlowFrac = state.dataSize.ZoneSizingInput[state.dataSize.CurZoneEqNum].DesCoolMinAirFlowFrac
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].NonAirSysDesHeatVolFlow = 0.12046
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].HeatSizingFactor = 1.0
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].NonAirSysDesHeatLoad = 3191.7
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].ZoneTempAtHeatPeak = 21.099
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].ZoneHumRatAtHeatPeak = 0.0038485
        state.dataSize.TermUnitSizing[state.dataSize.CurTermUnitSizingNum].AirVolFlow = 0.12046
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolMinAirFlow = state.dataSize.ZoneSizingInput[state.dataSize.CurZoneEqNum].DesCoolMinAirFlow
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolMinAirFlowFrac = state.dataSize.ZoneSizingInput[state.dataSize.CurZoneEqNum].DesCoolMinAirFlowFrac
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolMinAirFlow2 = state.dataSize.ZoneSizingInput[state.dataSize.CurZoneEqNum].DesCoolMinAirFlowPerArea * state.dataHeatBal.Zone[1].FloorArea
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolVolFlowMin = max(
            state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolMinAirFlow,
            state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolMinAirFlow2,
            state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolVolFlow * state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolMinAirFlowFrac
        )
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatMaxAirFlow = state.dataSize.ZoneSizingInput[state.dataSize.CurZoneEqNum].DesHeatMaxAirFlow
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatMaxAirFlowFrac = state.dataSize.ZoneSizingInput[state.dataSize.CurZoneEqNum].DesHeatMaxAirFlowFrac
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatMaxAirFlowPerArea = state.dataSize.ZoneSizingInput[state.dataSize.CurZoneEqNum].DesHeatMaxAirFlowPerArea
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatMaxAirFlow2 = state.dataSize.ZoneSizingInput[state.dataSize.CurZoneEqNum].DesHeatMaxAirFlowPerArea * state.dataHeatBal.Zone[1].FloorArea
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatVolFlowMax = max(
            state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatMaxAirFlow,
            state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatMaxAirFlow2,
            max(
                state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolVolFlow,
                state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatVolFlow
            ) * state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatMaxAirFlowFrac
        )
        state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].copyFromZoneSizing(state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum])
        state.dataSingleDuct.sd_airterminal[1].ZoneFloorArea = state.dataHeatBal.Zone[1].FloorArea
        state.dataSingleDuct.sd_airterminal[1].ZoneFloorArea = state.dataHeatBal.Zone[1].FloorArea
        state.dataSingleDuct.sd_airterminal[1].SizeSys(state)
        SizeWaterCoil(state, 1)
        Expect_NEAR(state.dataWaterCoils.WaterCoil[1].MaxWaterVolFlowRate, .0000850575, 0.000000001)
        Expect_NEAR(state.dataWaterCoils.WaterCoil[1].UACoil, 85.97495, 0.01)
        state.dataLoopNodes.Node.deallocate()
        state.dataZoneEquip.ZoneEquipConfig.deallocate()
        state.dataHeatBal.Zone.deallocate()
        state.dataSize.FinalZoneSizing.deallocate()
        state.dataSize.TermUnitFinalZoneSizing.deallocate()
        state.dataSize.CalcFinalZoneSizing.deallocate()
        state.dataSize.TermUnitSizing.deallocate()
        state.dataSingleDuct.sd_airterminal.deallocate()
        state.dataSize.ZoneEqSizing.deallocate()
        state.dataPlnt.PlantLoop.deallocate()
        state.dataSize.PlantSizData.deallocate()
        state.dataWaterCoils.MySizeFlag.deallocate()
        state.dataWaterCoils.MyUAAndFlowCalcFlag.deallocate()

    @staticmethod
    def TestSizingRoutineForHotWaterCoils3(using: TestFixture):
        var ErrorsFound: Bool = False
        state.dataEnvrn.StdRhoAir = 1.20
        var idf_objects: String = delimited_string([
            "\tZone,",
            "\tSPACE1-1, !- Name",
            "\t0, !- Direction of Relative North { deg }",
            "\t0, !- X Origin { m }",
            "\t0, !- Y Origin { m }",
            "\t0, !- Z Origin { m }",
            "\t1, !- Type",
            "\t1, !- Multiplier",
            "\t2.438400269, !- Ceiling Height {m}",
            "\t239.247360229; !- Volume {m3}",
            "\tSizing:Zone,",
            "\tSPACE1-1, !- Zone or ZoneList Name",
            "\tSupplyAirTemperature, !- Zone Cooling Design Supply Air Temperature Input Method",
            "\t14., !- Zone Cooling Design Supply Air Temperature { C }",
            "\t, !- Zone Cooling Design Supply Air Temperature Difference { deltaC }",
            "\tSupplyAirTemperature, !- Zone Heating Design Supply Air Temperature Input Method",
            "\t50., !- Zone Heating Design Supply Air Temperature { C }",
            "\t, !- Zone Heating Design Supply Air Temperature Difference { deltaC }",
            "\t0.009, !- Zone Cooling Design Supply Air Humidity Ratio { kgWater/kgDryAir }",
            "\t0.004, !- Zone Heating Design Supply Air Humidity Ratio { kgWater/kgDryAir }",
            "\tSZ DSOA SPACE1-1, !- Design Specification Outdoor Air Object Name",
            "\t0.0, !- Zone Heating Sizing Factor",
            "\t0.0, !- Zone Cooling Sizing Factor",
            "\tDesignDayWithLimit, !- Cooling Design Air Flow Method",
            "\t, !- Cooling Design Air Flow Rate { m3/s }",
            "\t, !- Cooling Minimum Air Flow per Zone Floor Area { m3/s-m2 }",
            "\t, !- Cooling Minimum Air Flow { m3/s }",
            "\t, !- Cooling Minimum Air Flow Fraction",
            "\tDesignDay, !- Heating Design Air Flow Method",
            "\t, !- Heating Design Air Flow Rate { m3/s }",
            "\t, !- Heating Maximum Air Flow per Zone Floor Area { m3/s-m2 }",
            "\t, !- Heating Maximum Air Flow { m3/s }",
            "\t, !- Heating Maximum Air Flow Fraction",
            "\tSZ DZAD SPACE1-1;        !- Design Specification Zone Air Distribution Object Name",
            "\tDesignSpecification:ZoneAirDistribution,",
            "\tSZ DZAD SPACE1-1, !- Name",
            "\t1, !- Zone Air Distribution Effectiveness in Cooling Mode { dimensionless }",
            "\t1; !- Zone Air Distribution Effectiveness in Heating Mode { dimensionless }",
            "\tDesignSpecification:OutdoorAir,",
            "\tSZ DSOA SPACE1-1, !- Name",
            "\tsum, !- Outdoor Air Method",
            "\t0.00236, !- Outdoor Air Flow per Person { m3/s-person }",
            "\t0.000305, !- Outdoor Air Flow per Zone Floor Area { m3/s-m2 }",
            "\t0.0; !- Outdoor Air Flow per Zone { m3/s }",
            "\tScheduleTypeLimits,",
            "\tFraction, !- Name",
            "\t0.0, !- Lower Limit Value",
            "\t1.0, !- Upper Limit Value",
            "\tCONTINUOUS; !- Numeric Type",
            "\tSchedule:Compact,",
            "\tReheatCoilAvailSched, !- Name",
            "\tFraction, !- Schedule Type Limits Name",
            "\tThrough: 12/31, !- Field 1",
            "\tFor: AllDays, !- Field 2",
            "\tUntil: 24:00,1.0; !- Field 3",
            "\tZoneHVAC:EquipmentConnections,",
            "\tSPACE1-1, !- Zone Name",
            "\tSPACE1-1 Eq, !- Zone Conditioning Equipment List Name",
            "\tSPACE1-1 In Node, !- Zone Air Inlet Node or NodeList Name",
            "\t, !- Zone Air Exhaust Node or NodeList Name",
            "\tSPACE1-1 Node, !- Zone Air Node Name",
            "\tSPACE1-1 Out Node; !- Zone Return Air Node Name",
            "\tZoneHVAC:EquipmentList,",
            "\tSPACE1-1 Eq, !- Name",
            "   SequentialLoad,          !- Load Distribution Scheme",
            "\tZoneHVAC:AirDistributionUnit, !- Zone Equipment 1 Object Type",
            "\tSPACE1-1 ATU, !- Zone Equipment 1 Name",
            "\t1, !- Zone Equipment 1 Cooling Sequence",
            "\t1; !- Zone Equipment 1 Heating or No - Load Sequence",
            "\tZoneHVAC:AirDistributionUnit,",
            "\tSPACE1-1 ATU, !- Name",
            "\tSPACE1-1 In Node, !- Air Distribution Unit Outlet Node Name",
            "\tAirTerminal:SingleDuct:VAV:Reheat, !- Air Terminal Object Type",
            "\tSPACE1-1 VAV Reheat; !- Air Terminal Name",
            "\tCoil:Heating:Water,",
            "\tGronk1 Zone Coil, !- Name",
            "\tReheatCoilAvailSched, !- Availability Schedule Name",
            "\t, !- U-Factor Times Area Value { W/K }",
            "\t, !- Maximum Water Flow Rate { m3/s }",
            "\tSPACE1-1 Zone Coil Water In Node, !- Water Inlet Node Name",
            "\tSPACE1-1 Zone Coil Water Out Node, !- Water Outlet Node Name",
            "\tSPACE1-1 Zone Coil Air In Node, !- Air Inlet Node Name",
            "\tSPACE1-1 In Node, !- Air Outlet Node Name",
            "\tNominalCapacity, !- Performance Input Method",
            "\t, !- Rated Capacity { W }",
            "\t82.2, !- Rated Inlet Water Temperature { C }",
            "\t16.6, !- Rated Inlet Air Temperature { C }",
            "\t71.1, !- Rated Outlet Water Temperature { C }",
            "\t32.2, !- Rated Outlet Air Temperature { C }",
            "\t; !- Rated Ratio for Air and Water Convection",
            "\tAirTerminal:SingleDuct:VAV:Reheat,",
            "\tSPACE1-1 VAV Reheat, !- Name",
            "\tReheatCoilAvailSched, !- Availability Schedule Name",
            "\tSPACE1-1 Zone Coil Air In Node, !- Damper Air Outlet Node Name",
            "\tSPACE1-1 ATU In Node, !- Air Inlet Node Name",
            "\tautosize, !- Maximum Air Flow Rate { m3/s }",
            "\t, !- Zone Minimum Air Flow Input Method",
            "\t, !- Constant Minimum Air Flow Fraction",
            "\t, !- Fixed Minimum Air Flow Rate { m3/s }",
            "\t, !- Minimum Air Flow Fraction Schedule Name",
            "\tCoil:Heating:Water, !- Reheat Coil Object Type",
            "\tGronk1 Zone Coil, !- Reheat Coil Name",
            "\tautosize, !- Maximum Hot Water or Steam Flow Rate { m3/s }",
            "\t0.0, !- Minimum Hot Water or Steam Flow Rate { m3/s }",
            "\tSPACE1-1 In Node, !- Air Outlet Node Name",
            "\t0.001, !- Convergence Tolerance",
            "\t, !- Damper Heating Action",
            "\t, !- Maximum Flow per Zone Floor Area During Reheat { m3/s-m2 }",
            "\t; !- Maximum Flow Fraction During Reheat",
        ])
        Assert(process_idf(idf_objects))
        state.init_state(state)
        state.dataSize.FinalZoneSizing.allocate(1)
        state.dataSize.TermUnitFinalZoneSizing.allocate(1)
        state.dataSize.CalcFinalZoneSizing.allocate(1)
        state.dataSize.TermUnitSizing.allocate(1)
        state.dataSize.ZoneEqSizing.allocate(1)
        state.dataPlnt.TotNumLoops = 1
        state.dataPlnt.PlantLoop.allocate(state.dataPlnt.TotNumLoops)
        state.dataSize.PlantSizData.allocate(1)
        state.dataWaterCoils.MySizeFlag.allocate(1)
        state.dataWaterCoils.MyUAAndFlowCalcFlag.allocate(1)
        state.dataSize.NumPltSizInput = 1
        for l in range(1, state.dataPlnt.TotNumLoops+1):
            var loopside: & = state.dataPlnt.PlantLoop[l].LoopSide[DataPlant.LoopSideLocation.Demand]
            loopside.TotalBranches = 1
            loopside.Branch.allocate(1)
            var loopsidebranch: & = state.dataPlnt.PlantLoop[l].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1]
            loopsidebranch.TotalComponents = 1
            loopsidebranch.Comp.allocate(1)
        GetZoneData(state, ErrorsFound)
        Expect_EQ("SPACE1-1", state.dataHeatBal.Zone[1].Name)
        GetOARequirements(state)      # get the OA requirements object
        GetZoneAirDistribution(state) # get zone air distribution objects
        GetZoneSizingInput(state)
        GetZoneEquipmentData(state)
        GetZoneAirLoopEquipment(state)
        GetWaterCoilInput(state)
        state.dataWaterCoils.GetWaterCoilsInputFlag = False
        state.dataWaterCoils.MySizeFlag[1] = True
        state.dataWaterCoils.MyUAAndFlowCalcFlag[1] = False
        GetSysInput(state)
        state.dataSize.TermUnitSingDuct = True
        state.dataPlnt.PlantLoop[1].Name = "HotWaterLoop"
        state.dataPlnt.PlantLoop[1].FluidName = "WATER"
        state.dataPlnt.PlantLoop[1].glycol = Fluid.GetWater(state)
        state.dataWaterCoils.WaterCoil[1].WaterPlantLoc = {1, DataPlant.LoopSideLocation.Demand, 1, 1}
        PlantUtilities.SetPlantLocationLinks(state, state.dataWaterCoils.WaterCoil[1].WaterPlantLoc)
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].Name = state.dataWaterCoils.WaterCoil[1].Name
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].Type = DataPlant.PlantEquipmentType.CoilWaterSimpleHeating
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].NodeNumIn = state.dataWaterCoils.WaterCoil[1].WaterInletNodeNum
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].NodeNumOut = state.dataWaterCoils.WaterCoil[1].WaterOutletNodeNum
        state.dataSingleDuct.sd_airterminal[1].HWplantLoc = {1, DataPlant.LoopSideLocation.Demand, 1, 0}
        PlantUtilities.SetPlantLocationLinks(state, state.dataSingleDuct.sd_airterminal[1].HWplantLoc)
        state.dataSize.PlantSizData[1].DeltaT = 11.0
        state.dataSize.PlantSizData[1].ExitTemp = 82
        state.dataSize.PlantSizData[1].PlantLoopName = "HotWaterLoop"
        state.dataSize.PlantSizData[1].LoopType = DataSizing.TypeOfPlantLoop.Heating
        state.dataSize.ZoneSizingRunDone = True
        state.dataSize.CurZoneEqNum = 1
        state.dataSize.CurSysNum = 0
        state.dataHeatBal.Zone[1].FloorArea = 99.16
        state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum].DesignSizeFromParent = False
        state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum].SizingMethod.allocate(25)
        state.dataSize.CurTermUnitSizingNum = 1
        state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].DesCoolVolFlow = 0.28794
        state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].DesHeatVolFlow = 0.12046
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatCoilInTempTU = 16.6
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatCoilInHumRatTU = 0.008
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolVolFlow = 0.28794
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatVolFlow = 0.12046
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolMinAirFlowFrac = state.dataSize.ZoneSizingInput[state.dataSize.CurZoneEqNum].DesCoolMinAirFlowFrac
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].NonAirSysDesHeatVolFlow = 0.12046
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].HeatSizingFactor = 1.0
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].NonAirSysDesHeatLoad = 3191.7
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].ZoneTempAtHeatPeak = 21.099
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].ZoneHumRatAtHeatPeak = 0.0038485
        state.dataSize.TermUnitSizing[state.dataSize.CurTermUnitSizingNum].AirVolFlow = 0.12046
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolMinAirFlow = state.dataSize.ZoneSizingInput[state.dataSize.CurZoneEqNum].DesCoolMinAirFlow
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolMinAirFlowFrac = state.dataSize.ZoneSizingInput[state.dataSize.CurZoneEqNum].DesCoolMinAirFlowFrac
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolMinAirFlow2 = state.dataSize.ZoneSizingInput[state.dataSize.CurZoneEqNum].DesCoolMinAirFlowPerArea * state.dataHeatBal.Zone[1].FloorArea
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolVolFlowMin = max(
            state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolMinAirFlow,
            state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolMinAirFlow2,
            state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolVolFlow * state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolMinAirFlowFrac
        )
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatMaxAirFlow = state.dataSize.ZoneSizingInput[state.dataSize.CurZoneEqNum].DesHeatMaxAirFlow
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatMaxAirFlowFrac = state.dataSize.ZoneSizingInput[state.dataSize.CurZoneEqNum].DesHeatMaxAirFlowFrac
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatMaxAirFlowPerArea = state.dataSize.ZoneSizingInput[state.dataSize.CurZoneEqNum].DesHeatMaxAirFlowPerArea
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatMaxAirFlow2 = state.dataSize.ZoneSizingInput[state.dataSize.CurZoneEqNum].DesHeatMaxAirFlowPerArea * state.dataHeatBal.Zone[1].FloorArea
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatVolFlowMax = max(
            state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatMaxAirFlow,
            state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatMaxAirFlow2,
            max(
                state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolVolFlow,
                state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatVolFlow
            ) * state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatMaxAirFlowFrac
        )
        state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].copyFromZoneSizing(state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum])
        state.dataSingleDuct.sd_airterminal[1].ZoneFloorArea = state.dataHeatBal.Zone[1].FloorArea
        state.dataSingleDuct.sd_airterminal[1].SizeSys(state)
        SizeWaterCoil(state, 1)
        Expect_NEAR(state.dataWaterCoils.WaterCoil[1].MaxWaterVolFlowRate, .0000850575, 0.000000001)
        Expect_NEAR(state.dataWaterCoils.WaterCoil[1].UACoil, 85.97495, 0.02)
        state.dataLoopNodes.Node.deallocate()
        state.dataZoneEquip.ZoneEquipConfig.deallocate()
        state.dataHeatBal.Zone.deallocate()
        state.dataSize.FinalZoneSizing.deallocate()
        state.dataSize.TermUnitFinalZoneSizing.deallocate()
        state.dataSize.CalcFinalZoneSizing.deallocate()
        state.dataSize.TermUnitSizing.deallocate()
        state.dataSingleDuct.sd_airterminal.deallocate()
        state.dataSize.ZoneEqSizing.deallocate()
        state.dataPlnt.PlantLoop.deallocate()
        state.dataSize.PlantSizData.deallocate()
        state.dataWaterCoils.MySizeFlag.deallocate()
        state.dataWaterCoils.MyUAAndFlowCalcFlag.deallocate()

    @staticmethod
    def TestSizingRoutineForHotWaterCoils4(using: TestFixture):
        var ErrorsFound: Bool = False
        state.dataEnvrn.StdRhoAir = 1.20
        var idf_objects: String = delimited_string([
            "\tZone,",
            "\tSPACE1-1, !- Name",
            "\t0, !- Direction of Relative North { deg }",
            "\t0, !- X Origin { m }",
            "\t0, !- Y Origin { m }",
            "\t0, !- Z Origin { m }",
            "\t1, !- Type",
            "\t1, !- Multiplier",
            "\t2.438400269, !- Ceiling Height {m}",
            "\t239.247360229; !- Volume {m3}",
            "\tSizing:Zone,",
            "\tSPACE1-1, !- Zone or ZoneList Name",
            "\tSupplyAirTemperature, !- Zone Cooling Design Supply Air Temperature Input Method",
            "\t14., !- Zone Cooling Design Supply Air Temperature { C }",
            "\t, !- Zone Cooling Design Supply Air Temperature Difference { deltaC }",
            "\tSupplyAirTemperature, !- Zone Heating Design Supply Air Temperature Input Method",
            "\t50., !- Zone Heating Design Supply Air Temperature { C }",
            "\t, !- Zone Heating Design Supply Air Temperature Difference { deltaC }",
            "\t0.009, !- Zone Cooling Design Supply Air Humidity Ratio { kgWater/kgDryAir }",
            "\t0.004, !- Zone Heating Design Supply Air Humidity Ratio { kgWater/kgDryAir }",
            "\tSZ DSOA SPACE1-1, !- Design Specification Outdoor Air Object Name",
            "\t0.0, !- Zone Heating Sizing Factor",
            "\t0.0, !- Zone Cooling Sizing Factor",
            "\tDesignDayWithLimit, !- Cooling Design Air Flow Method",
            "\t, !- Cooling Design Air Flow Rate { m3/s }",
            "\t, !- Cooling Minimum Air Flow per Zone Floor Area { m3/s-m2 }",
            "\t, !- Cooling Minimum Air Flow { m3/s }",
            "\t, !- Cooling Minimum Air Flow Fraction",
            "\tDesignDay, !- Heating Design Air Flow Method",
            "\t, !- Heating Design Air Flow Rate { m3/s }",
            "\t, !- Heating Maximum Air Flow per Zone Floor Area { m3/s-m2 }",
            "\t, !- Heating Maximum Air Flow { m3/s }",
            "\t, !- Heating Maximum Air Flow Fraction",
            "\tSZ DZAD SPACE1-1;        !- Design Specification Zone Air Distribution Object Name",
            "\tDesignSpecification:ZoneAirDistribution,",
            "\tSZ DZAD SPACE1-1, !- Name",
            "\t1, !- Zone Air Distribution Effectiveness in Cooling Mode { dimensionless }",
            "\t1; !- Zone Air Distribution Effectiveness in Heating Mode { dimensionless }",
            "\tDesignSpecification:OutdoorAir,",
            "\tSZ DSOA SPACE1-1, !- Name",
            "\tsum, !- Outdoor Air Method",
            "\t0.00236, !- Outdoor Air Flow per Person { m3/s-person }",
            "\t0.000305, !- Outdoor Air Flow per Zone Floor Area { m3/s-m2 }",
            "\t0.0; !- Outdoor Air Flow per Zone { m3/s }",
            "\tScheduleTypeLimits,",
            "\tFraction, !- Name",
            "\t0.0, !- Lower Limit Value",
            "\t1.0, !- Upper Limit Value",
            "\tCONTINUOUS; !- Numeric Type",
            "\tSchedule:Compact,",
            "\tReheatCoilAvailSched, !- Name",
            "\tFraction, !- Schedule Type Limits Name",
            "\tThrough: 12/31, !- Field 1",
            "\tFor: AllDays, !- Field 2",
            "\tUntil: 24:00,1.0; !- Field 3",
            "\tZoneHVAC:EquipmentConnections,",
            "\tSPACE1-1, !- Zone Name",
            "\tSPACE1-1 Eq, !- Zone Conditioning Equipment List Name",
            "\tSPACE1-1 In Node, !- Zone Air Inlet Node or NodeList Name",
            "\t, !- Zone Air Exhaust Node or NodeList Name",
            "\tSPACE1-1 Node, !- Zone Air Node Name",
            "\tSPACE1-1 Out Node; !- Zone Return Air Node Name",
            "\tZoneHVAC:EquipmentList,",
            "\tSPACE1-1 Eq, !- Name",
            "   SequentialLoad,          !- Load Distribution Scheme",
            "\tZoneHVAC:AirDistributionUnit, !- Zone Equipment 1 Object Type",
            "\tSPACE1-1 ATU, !- Zone Equipment 1 Name",
            "\t1, !- Zone Equipment 1 Cooling Sequence",
            "\t1; !- Zone Equipment 1 Heating or No - Load Sequence",
            "\tZoneHVAC:AirDistributionUnit,",
            "\tSPACE1-1 ATU, !- Name",
            "\tSPACE1-1 In Node, !- Air Distribution Unit Outlet Node Name",
            "\tAirTerminal:SingleDuct:VAV:Reheat, !- Air Terminal Object Type",
            "\tSPACE1-1 VAV Reheat; !- Air Terminal Name",
            "\tCoil:Heating:Water,",
            "\tGronk1 Zone Coil, !- Name",
            "\tReheatCoilAvailSched, !- Availability Schedule Name",
            "\t300., !- U-Factor Times Area Value { W/K }",
            "\t, !- Maximum Water Flow Rate { m3/s }",
            "\tSPACE1-1 Zone Coil Water In Node, !- Water Inlet Node Name",
            "\tSPACE1-1 Zone Coil Water Out Node, !- Water Outlet Node Name",
            "\tSPACE1-1 Zone Coil Air In Node, !- Air Inlet Node Name",
            "\tSPACE1-1 In Node, !- Air Outlet Node Name",
            "\tUFactorTimesAreaAndDesignWaterFlowRate, !- Performance Input Method",
            "\t, !- Rated Capacity { W }",
            "\t82.2, !- Rated Inlet Water Temperature { C }",
            "\t16.6, !- Rated Inlet Air Temperature { C }",
            "\t71.1, !- Rated Outlet Water Temperature { C }",
            "\t32.2, !- Rated Outlet Air Temperature { C }",
            "\t; !- Rated Ratio for Air and Water Convection",
            "\tAirTerminal:SingleDuct:VAV:Reheat,",
            "\tSPACE1-1 VAV Reheat, !- Name",
            "\tReheatCoilAvailSched, !- Availability Schedule Name",
            "\tSPACE1-1 Zone Coil Air In Node, !- Damper Air Outlet Node Name",
            "\tSPACE1-1 ATU In Node, !- Air Inlet Node Name",
            "\tautosize, !- Maximum Air Flow Rate { m3/s }",
            "\t, !- Zone Minimum Air Flow Input Method",
            "\t, !- Constant Minimum Air Flow Fraction",
            "\t, !- Fixed Minimum Air Flow Rate { m3/s }",
            "\t, !- Minimum Air Flow Fraction Schedule Name",
            "\tCoil:Heating:Water, !- Reheat Coil Object Type",
            "\tGronk1 Zone Coil, !- Reheat Coil Name",
            "\tautosize, !- Maximum Hot Water or Steam Flow Rate { m3/s }",
            "\t0.0, !- Minimum Hot Water or Steam Flow Rate { m3/s }",
            "\tSPACE1-1 In Node, !- Air Outlet Node Name",
            "\t0.001, !- Convergence Tolerance",
            "\t, !- Damper Heating Action",
            "\t, !- Maximum Flow per Zone Floor Area During Reheat { m3/s-m2 }",
            "\t; !- Maximum Flow Fraction During Reheat",
        ])
        Assert(process_idf(idf_objects))
        state.init_state(state)
        state.dataSize.FinalZoneSizing.allocate(1)
        state.dataSize.TermUnitFinalZoneSizing.allocate(1)
        state.dataSize.CalcFinalZoneSizing.allocate(1)
        state.dataSize.TermUnitSizing.allocate(1)
        state.dataSize.ZoneEqSizing.allocate(1)
        state.dataPlnt.TotNumLoops = 1
        state.dataPlnt.PlantLoop.allocate(state.dataPlnt.TotNumLoops)
        state.dataSize.PlantSizData.allocate(1)
        state.dataWaterCoils.MySizeFlag.allocate(1)
        state.dataWaterCoils.MyUAAndFlowCalcFlag.allocate(1)
        state.dataSize.NumPltSizInput = 1
        for l in range(1, state.dataPlnt.TotNumLoops+1):
            var loopside: & = state.dataPlnt.PlantLoop[l].LoopSide[DataPlant.LoopSideLocation.Demand]
            loopside.TotalBranches = 1
            loopside.Branch.allocate(1)
            var loopsidebranch: & = state.dataPlnt.PlantLoop[l].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1]
            loopsidebranch.TotalComponents = 1
            loopsidebranch.Comp.allocate(1)
        GetZoneData(state, ErrorsFound)
        Expect_EQ("SPACE1-1", state.dataHeatBal.Zone[1].Name)
        GetOARequirements(state)      # get the OA requirements object
        GetZoneAirDistribution(state) # get zone air distribution objects
        GetZoneSizingInput(state)
        GetZoneEquipmentData(state)
        GetZoneAirLoopEquipment(state)
        GetWaterCoilInput(state)
        state.dataWaterCoils.GetWaterCoilsInputFlag = False
        state.dataWaterCoils.MySizeFlag[1] = True
        state.dataWaterCoils.MyUAAndFlowCalcFlag[1] = False
        GetSysInput(state)
        state.dataSize.TermUnitSingDuct = True
        state.dataPlnt.PlantLoop[1].Name = "HotWaterLoop"
        state.dataPlnt.PlantLoop[1].FluidName = "WATER"
        state.dataPlnt.PlantLoop[1].glycol = Fluid.GetWater(state)
        state.dataWaterCoils.WaterCoil[1].WaterPlantLoc = {1, DataPlant.LoopSideLocation.Demand, 1, 1}
        PlantUtilities.SetPlantLocationLinks(state, state.dataWaterCoils.WaterCoil[1].WaterPlantLoc)
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].Name = state.dataWaterCoils.WaterCoil[1].Name
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].Type = DataPlant.PlantEquipmentType.CoilWaterSimpleHeating
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].NodeNumIn = state.dataWaterCoils.WaterCoil[1].WaterInletNodeNum
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].NodeNumOut = state.dataWaterCoils.WaterCoil[1].WaterOutletNodeNum
        state.dataSingleDuct.sd_airterminal[1].HWplantLoc = {1, DataPlant.LoopSideLocation.Demand, 1, 0}
        PlantUtilities.SetPlantLocationLinks(state, state.dataSingleDuct.sd_airterminal[1].HWplantLoc)
        state.dataSize.PlantSizData[1].DeltaT = 11.0
        state.dataSize.PlantSizData[1].ExitTemp = 82
        state.dataSize.PlantSizData[1].PlantLoopName = "HotWaterLoop"
        state.dataSize.PlantSizData[1].LoopType = DataSizing.TypeOfPlantLoop.Heating
        state.dataSize.ZoneSizingRunDone = True
        state.dataSize.CurZoneEqNum = 1
        state.dataSize.CurSysNum = 0
        state.dataHeatBal.Zone[1].FloorArea = 99.16
        state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum].DesignSizeFromParent = False
        state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum].SizingMethod.allocate(25)
        state.dataSize.CurTermUnitSizingNum = 1
        state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].DesCoolVolFlow = 0.28794
        state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].DesHeatVolFlow = 0.12046
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatCoilInTempTU = 16.6
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatCoilInHumRatTU = 0.008
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolVolFlow = 0.28794
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatVolFlow = 0.12046
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolMinAirFlowFrac = state.dataSize.ZoneSizingInput[state.dataSize.CurZoneEqNum].DesCoolMinAirFlowFrac
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].NonAirSysDesHeatVolFlow = 0.12046
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].HeatSizingFactor = 1.0
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].NonAirSysDesHeatLoad = 3191.7
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].ZoneTempAtHeatPeak = 21.099
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].ZoneHumRatAtHeatPeak = 0.0038485
        state.dataSize.TermUnitSizing[state.dataSize.CurTermUnitSizingNum].AirVolFlow = 0.12046
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolMinAirFlow = state.dataSize.ZoneSizingInput[state.dataSize.CurZoneEqNum].DesCoolMinAirFlow
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolMinAirFlowFrac = state.dataSize.ZoneSizingInput[state.dataSize.CurZoneEqNum].DesCoolMinAirFlowFrac
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolMinAirFlow2 = state.dataSize.ZoneSizingInput[state.dataSize.CurZoneEqNum].DesCoolMinAirFlowPerArea * state.dataHeatBal.Zone[1].FloorArea
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolVolFlowMin = max(
            state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolMinAirFlow,
            state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolMinAirFlow2,
            state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolVolFlow * state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolMinAirFlowFrac
        )
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatMaxAirFlow = state.dataSize.ZoneSizingInput[state.dataSize.CurZoneEqNum].DesHeatMaxAirFlow
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatMaxAirFlowFrac = state.dataSize.ZoneSizingInput[state.dataSize.CurZoneEqNum].DesHeatMaxAirFlowFrac
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatMaxAirFlowPerArea = state.dataSize.ZoneSizingInput[state.dataSize.CurZoneEqNum].DesHeatMaxAirFlowPerArea
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatMaxAirFlow2 = state.dataSize.ZoneSizingInput[state.dataSize.CurZoneEqNum].DesHeatMaxAirFlowPerArea * state.dataHeatBal.Zone[1].FloorArea
        state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatVolFlowMax = max(
            state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatMaxAirFlow,
            state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatMaxAirFlow2,
            max(
                state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolVolFlow,
                state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatVolFlow
            ) * state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatMaxAirFlowFrac
        )
        state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].copyFromZoneSizing(state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum])
        state.dataSingleDuct.sd_airterminal[1].ZoneFloorArea = state.dataHeatBal.Zone[1].FloorArea
        state.dataSingleDuct.sd_airterminal[1].SizeSys(state)
        SizeWaterCoil(state, 1)
        Expect_NEAR(state.dataWaterCoils.WaterCoil[1].MaxWaterVolFlowRate, .0000850575, 0.000000001)
        Expect_NEAR(state.dataWaterCoils.WaterCoil[1].UACoil, 300.00, 0.01)
        state.dataLoopNodes.Node.deallocate()
        state.dataZoneEquip.ZoneEquipConfig.deallocate()
        state.dataHeatBal.Zone.deallocate()
        state.dataSize.FinalZoneSizing.deallocate()
        state.dataSize.TermUnitFinalZoneSizing.deallocate()
        state.dataSize.CalcFinalZoneSizing.deallocate()
        state.dataSize.TermUnitSizing.deallocate()
        state.dataSingleDuct.sd_airterminal.deallocate()
        state.dataSize.ZoneEqSizing.deallocate()
        state.dataPlnt.PlantLoop.deallocate()
        state.dataSize.PlantSizData.deallocate()
        state.dataWaterCoils.MySizeFlag.deallocate()
        state.dataWaterCoils.MyUAAndFlowCalcFlag.deallocate()

    @staticmethod
    def TestSizingRoutineForHotWaterCoils5(using: TestFixture):
        var ErrorsFound: Bool = False
        state.dataEnvrn.StdRhoAir = 1.20
        var idf_objects: String = delimited_string([
            "\tZone,",
            "\tSPACE1-1, !- Name",
            "\t0, !- Direction of Relative North { deg }",
            "\t0, !- X Origin { m }",
            "\t0, !- Y Origin { m }",
            "\t0, !- Z Origin { m }",
            "\t1, !- Type",
            "\t1, !- Multiplier",
            "\t2.438400269, !- Ceiling Height {m}",
            "\t239.247360229; !- Volume {m3}",
            "\tSizing:System,",
            "\tVAV Sys 1, !- AirLoop Name",
            "\tsensible, !- Type of Load to Size On",
            "\tautosize, !- Design Outdoor Air Flow Rate { m3/s }",
            "\t0.3, !- Central Heating Maximum System Air Flow Ratio",
            "\t7.0, !- Preheat Design Temperature { C }",
            "\t0.008, !- Preheat Design Humidity Ratio { kgWater/kgDryAir }",
            "\t11.0, !- Precool Design Temperature { C }",
            "\t0.008, !- Precool Design Humidity Ratio { kgWater/kgDryAir }",
            "\t12.8, !- Central Cooling Design Supply Air Temperature { C }",
            "\t16.7, !- Central Heating Design Supply Air Temperature { C }",
            "\tnoncoincident, !- Type of Zone Sum to Use",
            "\tno, !- 100% Outdoor Air in Cooling",
            "\tno, !- 100% Outdoor Air in Heating",
            "\t0.008, !- Central Cooling Design Supply Air Humidity Ratio { kgWater/kgDryAir }",
            "\t0.008, !- Central Heating Design Supply Air Humidity Ratio { kgWater/kgDryAir }",
            "\tDesignDay, !- Cooling Design Air Flow Method",
            "\t0, !- Cooling Design Air Flow Rate { m3/s }",
            "\t, !- Supply Air Flow Rate Per Floor Area During Cooling Operation { m3/s-m2 }",
            "\t, !- Fraction of Autosized Design Cooling Supply Air Flow Rate",
            "\t, !- Design Supply Air Flow Rate Per Unit Cooling Capacity { m3/s-W }",
            "\tFlowPerHeatingCapacity, !- Heating Design Air Flow Method",
            "\t0, !- Heating Design Air Flow Rate { m3/s }",
            "\t, !- Supply Air Flow Rate Per Floor Area During Heating Operation { m3/s-m2 }",
            "\t, !- Fraction of Autosized Design Heating Supply Air Flow Rate",
            "\t, !- Fraction of Autosized Design Cooling Supply Air Flow Rate",
            "\t0.000174194, !- Design Supply Air Flow Rate Per Unit Heating Capacity { m3/s-W }",
            "\t, !- System Outdoor Air Method",
            "\t1.0, !- Zone Maximum Outdoor Air Fraction { dimensionless }",
            "\tCoolingDesignCapacity, !- Cooling Design Capacity Method",
            "\tautosize, !- Cooling Design Capacity { W }",
            "\t, !- Cooling Design Capacity Per Floor Area { W/m2 }",
            "\t, !- Fraction of Autosized Cooling Design Capacity",
            "\tHeatingDesignCapacity, !- Heating Design Capacity Method",
            "\t12000, !- Heating Design Capacity { W }",
            "\t, !- Heating Design Capacity Per Floor Area { W/m2 }",
            "\t, !- Fraction of Autosized Heating Design Capacity",
            "\tVAV;                     !- Central Cooling Capacity Control Method",
            "\tScheduleTypeLimits,",
            "\tFraction, !- Name",
            "\t0.0, !- Lower Limit Value",
            "\t1.0, !- Upper Limit Value",
            "\tCONTINUOUS; !- Numeric Type",
            "\tSchedule:Compact,",
            "\tReheatCoilAvailSched, !- Name",
            "\tFraction, !- Schedule Type Limits Name",
            "\tThrough: 12/31, !- Field 1",
            "\tFor: AllDays, !- Field 2",
            "\tUntil: 24:00,1.0; !- Field 3",
            "\tCoil:Heating:Water,",
            "\tGronk1 Zone Coil, !- Name",
            "\tReheatCoilAvailSched, !- Availability Schedule Name",
            "\t, !- U-Factor Times Area Value { W/K }",
            "\t, !- Maximum Water Flow Rate { m3/s }",
            "\tSPACE1-1 Zone Coil Water In Node, !- Water Inlet Node Name",
            "\tSPACE1-1 Zone Coil Water Out Node, !- Water Outlet Node Name",
            "\tSPACE1-1 Zone Coil Air In Node, !- Air Inlet Node Name",
            "\tSPACE1-1 In Node, !- Air Outlet Node Name",
            "\tNominalCapacity, !- Performance Input Method",
            "\t, !- Rated Capacity { W }",
            "\t82.2, !- Rated Inlet Water Temperature { C }",
            "\t16.6, !- Rated Inlet Air Temperature { C }",
            "\t71.1, !- Rated Outlet Water Temperature { C }",
            "\t32.2, !- Rated Outlet Air Temperature { C }",
            "\t; !- Rated Ratio for Air and Water Convection",
        ])
        Assert(process_idf(idf_objects))
        state.init_state(state)
        state.dataSize.FinalSysSizing.allocate(1)
        state.dataSize.UnitarySysEqSizing.allocate(1)
        state.dataAirSystemsData.PrimaryAirSystems.allocate(1)
        state.dataAirLoop.AirLoopControlInfo.allocate(1)
        state.dataPlnt.TotNumLoops = 1
        state.dataPlnt.PlantLoop.allocate(state.dataPlnt.TotNumLoops)
        state.dataSize.PlantSizData.allocate(1)
        state.dataWaterCoils.MySizeFlag.allocate(1)
        state.dataWaterCoils.MyUAAndFlowCalcFlag.allocate(1)
        state.dataSize.NumPltSizInput = 1
        for l in range(1, state.dataPlnt.TotNumLoops+1):
            var loopside: & = state.dataPlnt.PlantLoop[l].LoopSide[DataPlant.LoopSideLocation.Demand]
            loopside.TotalBranches = 1
            loopside.Branch.allocate(1)
            var loopsidebranch: & = state.dataPlnt.PlantLoop[l].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1]
            loopsidebranch.TotalComponents = 1
            loopsidebranch.Comp.allocate(1)
        GetZoneData(state, ErrorsFound)
        Expect_EQ("SPACE1-1", state.dataHeatBal.Zone[1].Name)
        GetWaterCoilInput(state)
        state.dataWaterCoils.GetWaterCoilsInputFlag = False
        state.dataWaterCoils.MySizeFlag[1] = True
        state.dataWaterCoils.MyUAAndFlowCalcFlag[1] = False
        state.dataSize.TermUnitSingDuct = True
        state.dataPlnt.PlantLoop[1].Name = "HotWaterLoop"
        state.dataPlnt.PlantLoop[1].FluidName = "WATER"
        state.dataPlnt.PlantLoop[1].glycol = Fluid.GetWater(state)
        state.dataWaterCoils.WaterCoil[1].WaterPlantLoc = {1, DataPlant.LoopSideLocation.Demand, 1, 1}
        PlantUtilities.SetPlantLocationLinks(state, state.dataWaterCoils.WaterCoil[1].WaterPlantLoc)
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].Name = state.dataWaterCoils.WaterCoil[1].Name
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].Type = DataPlant.PlantEquipmentType.CoilWaterSimpleHeating
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].NodeNumIn = state.dataWaterCoils.WaterCoil[1].WaterInletNodeNum
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].NodeNumOut = state.dataWaterCoils.WaterCoil[1].WaterOutletNodeNum
        state.dataSize.PlantSizData[1].DeltaT = 11.0
        state.dataSize.PlantSizData[1].ExitTemp = 82
        state.dataSize.PlantSizData[1].PlantLoopName = "HotWaterLoop"
        state.dataSize.PlantSizData[1].LoopType = DataSizing.TypeOfPlantLoop.Heating
        state.dataSize.ZoneSizingRunDone = True
        state.dataSize.SysSizingRunDone = True
        state.dataSize.CurZoneEqNum = 0
        state.dataSize.CurSysNum = 1
        state.dataSize.CurDuctType = HVAC.AirDuctType.Main
        state.dataHeatBal.Zone[1].FloorArea = 99.16
        state.dataSize.FinalSysSizing[state.dataSize.CurSysNum].HeatingCapMethod = 9
        state.dataSize.FinalSysSizing[state.dataSize.CurSysNum].HeatingTotalCapacity = 12000.
        state.dataSize.FinalSysSizing[state.dataSize.CurSysNum].SysAirMinFlowRat = 0.3
        state.dataSize.FinalSysSizing[state.dataSize.CurSysNum].DesMainVolFlow = 3.4
        state.dataSize.FinalSysSizing[state.dataSize.CurSysNum].DesOutAirVolFlow = 0.49
        state.dataSize.FinalSysSizing[state.dataSize.CurSysNum].HeatOutTemp = -17.3
        state.dataSize.FinalSysSizing[state.dataSize.CurSysNum].HeatRetTemp = 21.3
        state.dataSize.FinalSysSizing[state.dataSize.CurSysNum].HeatSupTemp = 16.7
        state.dataSize.UnitarySysEqSizing[state.dataSize.CurSysNum].CoolingCapacity = False
        state.dataSize.UnitarySysEqSizing[state.dataSize.CurSysNum].HeatingCapacity = False
        state.dataHVACGlobal.NumPrimaryAirSys = 1
        SizeWaterCoil(state, 1)
        Expect_NEAR(state.dataWaterCoils.WaterCoil[1].MaxWaterMassFlowRate, .258323, 0.00001)
        Expect_NEAR(state.dataWaterCoils.WaterCoil[1].UACoil, 239.835, 0.01)
        state.dataLoopNodes.Node.deallocate()
        state.dataHeatBal.Zone.deallocate()
        state.dataPlnt.PlantLoop.deallocate()
        state.dataSize.PlantSizData.deallocate()
        state.dataWaterCoils.MySizeFlag.deallocate()
        state.dataWaterCoils.MyUAAndFlowCalcFlag.deallocate()
        state.dataSize.FinalSysSizing.deallocate()
        state.dataSize.UnitarySysEqSizing.deallocate()
        state.dataAirSystemsData.PrimaryAirSystems.deallocate()
        state.dataAirLoop.AirLoopControlInfo.deallocate()

    @staticmethod
    def TestSizingRoutineForHotWaterCoils6(using: TestFixture):
        var ErrorsFound: Bool = False
        state.dataEnvrn.StdRhoAir = 1.20
        var idf_objects: String = delimited_string([
            " Zone,",
            "\tSPACE1-1,      !- Name",
            "\t0,             !- Direction of Relative North { deg }",
            "\t0,             !- X Origin { m }",
            "\t0,             !- Y Origin { m }",
            "\t0,             !- Z Origin { m }",
            "\t1,             !- Type",
            "\t1,             !- Multiplier",
            "\t2.438400269,   !- Ceiling Height {m}",
            "\t239.247360229; !- Volume {m3}",
            " Sizing:Zone,",
            "\tSPACE1-1,      !- Zone or ZoneList Name",
            "\tSupplyAirTemperature, !- Zone Cooling Design Supply Air Temperature Input Method",
            "\t14.,           !- Zone Cooling Design Supply Air Temperature { C }",
            "\t,              !- Zone Cooling Design Supply Air Temperature Difference { deltaC }",
            "\tSupplyAirTemperature, !- Zone Heating Design Supply Air Temperature Input Method",
            "\t50.,           !- Zone Heating Design Supply Air Temperature { C }",
            "\t,              !- Zone Heating Design Supply Air Temperature Difference { deltaC }",
            "\t0.009,         !- Zone Cooling Design Supply Air Humidity Ratio { kgWater/kgDryAir }",
            "\t0.004,         !- Zone Heating Design Supply Air Humidity Ratio { kgWater/kgDryAir }",
            "\tSZ DSOA SPACE1-1, !- Design Specification Outdoor Air Object Name",
            "\t0.0,           !- Zone Heating Sizing Factor",
            "\t0.0,           !- Zone Cooling Sizing Factor",
            "\tDesignDayWithLimit, !- Cooling Design Air Flow Method",
            "\t,              !- Cooling Design Air Flow Rate { m3/s }",
            "\t,              !- Cooling Minimum Air Flow per Zone Floor Area { m3/s-m2 }",
            "\t,              !- Cooling Minimum Air Flow { m3/s }",
            "\t,              !- Cooling Minimum Air Flow Fraction",
            "\tDesignDay,     !- Heating Design Air Flow Method",
            "\t,              !- Heating Design Air Flow Rate { m3/s }",
            "\t,              !- Heating Maximum Air Flow per Zone Floor Area { m3/s-m2 }",
            "\t,              !- Heating Maximum Air Flow { m3/s }",
            "\t,              !- Heating Maximum Air Flow Fraction",
            "\tSZ DZAD SPACE1-1;   !- Design Specification Zone Air Distribution Object Name",
            " DesignSpecification:ZoneAirDistribution,",
            "\tSZ DZAD SPACE1-1, !- Name",
            "\t1,                !- Zone Air Distribution Effectiveness in Cooling Mode { dimensionless }",
            "\t1;                !- Zone Air Distribution Effectiveness in Heating Mode { dimensionless }",
            " DesignSpecification:OutdoorAir,",
            "\tSZ DSOA SPACE1-1, !- Name",
            "\tsum,              !- Outdoor Air Method",
            "\t0.00236,          !- Outdoor Air Flow per Person { m3/s-person }",
            "\t0.000305,         !- Outdoor Air Flow per Zone Floor Area { m3/s-m2 }",
            "\t0.0;              !- Outdoor Air Flow per Zone { m3/s }",
            " ScheduleTypeLimits,",
            "\tFraction,         !- Name",
            "\t0.0,              !- Lower Limit Value",
            "\t1.0,              !- Upper Limit Value",
            "\tCONTINUOUS;       !- Numeric Type",
            " Schedule:Compact,",
            "\tReheatCoilAvailSched, !- Name",
            "\tFraction,         !- Schedule Type Limits Name",
            "\tThrough: 12/31,   !- Field 1",
            "\tFor: AllDays,     !- Field 2",
            "\tUntil: 24:00,1.0; !- Field 3",
            " ZoneHVAC:EquipmentConnections,",
            "\tSPACE1-1,         !- Zone Name",
            "\tSPACE1-1 Eq,      !- Zone Conditioning Equipment List Name",
            "\tSPACE1-1 In Node, !- Zone Air Inlet Node or NodeList Name",
            "\t,                 !- Zone Air Exhaust Node or NodeList Name",
            "\tSPACE1-1 Node,    !- Zone Air Node Name",
            "\tSPACE1-1 Out Node; !- Zone Return Air Node Name",
            " ZoneHVAC:EquipmentList,",
            "\tSPACE1-1 Eq,      !- Name",
            "   SequentialLoad,   !- Load Distribution Scheme",
            "\tZoneHVAC:AirDistributionUnit, !- Zone Equipment 1 Object Type",
            "\tSPACE1-1 ATU,     !- Zone Equipment 1 Name",
            "\t1,                !- Zone Equipment 1 Cooling Sequence",
            "\t1;                !- Zone Equipment 1 Heating or No - Load Sequence",
            " ZoneHVAC:AirDistributionUnit,",
            "\tSPACE1-1 ATU,     !- Name",
            "\tSPACE1-1 In Node, !- Air Distribution Unit Outlet Node Name",
            "\tAirTerminal:SingleDuct:VAV:Reheat, !- Air Terminal Object Type",
            "\tSPACE1-1 VAV Reheat; !- Air Terminal Name",
            " Coil:Heating:Water,",
            "\tGronk1 Zone Coil, !- Name",
            "\tReheatCoilAvailSched, !- Availability Schedule Name",
            "\t300.,             !- U-Factor Times Area Value { W/K }",
            "\t0.0000850575,     !- Maximum Water Flow Rate { m3/s }",
            "\tSPACE1-1 Zone Coil Water In Node, !- Water Inlet Node Name",
            "\tSPACE1-1 Zone Coil Water Out Node, !- Water Outlet Node Name",
            "\tSPACE1-1 Zone Coil Air In Node, !- Air Inlet Node Name",
            "\tSPACE1-1 In Node, !- Air Outlet Node Name",
            "\tUFactorTimesAreaAndDesignWaterFlowRate, !- Performance Input Method",
            "\tautosize,         !- Rated Capacity { W }",
            "\t82.2,             !- Rated Inlet Water Temperature { C }",
            "\t16.6,             !- Rated Inlet Air Temperature { C }",
            "\t71.1,             !- Rated Outlet Water Temperature { C }",
            "\t32.2,             !- Rated Outlet Air Temperature { C }",
            "\t;                 !- Rated Ratio for Air and Water Convection",
            " AirTerminal:SingleDuct:VAV:Reheat,",
            "\tSPACE1-1 VAV Reheat,  !- Name",
            "\tReheatCoilAvailSched, !- Availability Schedule Name",
            "\tSPACE1-1 Zone Coil Air In Node, !- Damper Air Outlet Node Name",
            "\tSPACE1-1 ATU In Node, !- Air Inlet Node Name",
            "\t0.12046,              !- Maximum Air Flow Rate { m3/s }",
            "\t,                     !- Zone Minimum Air Flow Input Method",
            "\t0.3,                  !- Constant Minimum Air Flow Fraction",
            "\t,                     !- Fixed Minimum Air Flow Rate { m3/s }",
            "\t,                     !- Minimum Air Flow Fraction Schedule Name",
            "\tCoil:Heating:Water,   !- Reheat Coil Object Type",
            "\tGronk1 Zone Coil,     !- Reheat Coil Name",
            "\t0.0000850575,         !- Maximum Hot Water or Steam Flow Rate { m3/s }",
            "\t0.0,                  !- Minimum Hot Water or Steam Flow Rate { m3/s }",
            "\tSPACE1-1 In Node,     !- Air Outlet Node Name",
            "\t0.001,                !- Convergence Tolerance",
            "\t,                     !- Damper Heating Action",
            "\t,                     !- Maximum Flow per Zone Floor Area During Reheat { m3/s-m2 }",
            "\t;                     !- Maximum Flow Fraction During Reheat",
        ])
        Assert(process_idf(idf_objects))
        state.init_state(state)
        state.dataSize.TermUnitSizing.allocate(1)
        state.dataPlnt.TotNumLoops = 1
        state.dataPlnt.PlantLoop.allocate(state.dataPlnt.TotNumLoops)
        state.dataWaterCoils.MySizeFlag.allocate(1)
        state.dataWaterCoils.MyUAAndFlowCalcFlag.allocate(1)
        for l in range(1, state.dataPlnt.TotNumLoops+1):
            var loopside: & = state.dataPlnt.PlantLoop[l].LoopSide[DataPlant.LoopSideLocation.Demand]
            loopside.TotalBranches = 1
            loopside.Branch.allocate(1)
            var loopsidebranch: & = state.dataPlnt.PlantLoop[l].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1]
            loopsidebranch.TotalComponents = 1
            loopsidebranch.Comp.allocate(1)
        GetZoneData(state, ErrorsFound)
        Expect_EQ("SPACE1-1", state.dataHeatBal.Zone[1].Name)
        GetOARequirements(state)      # get the OA requirements object
        GetZoneAirDistribution(state) # get zone air distribution objects
        GetZoneSizingInput(state)
        GetZoneEquipmentData(state)
        GetZoneAirLoopEquipment(state)
        GetWaterCoilInput(state)
        state.dataWaterCoils.GetWaterCoilsInputFlag = False
        state.dataWaterCoils.MySizeFlag[1] = True
        state.dataWaterCoils.MyUAAndFlowCalcFlag[1] = False
        GetSysInput(state)
        state.dataSize.TermUnitSingDuct = True
        state.dataPlnt.PlantLoop[1].Name = "HotWaterLoop"
        state.dataPlnt.PlantLoop[1].FluidName = "WATER"
        state.dataWaterCoils.WaterCoil[1].WaterPlantLoc = {1, DataPlant.LoopSideLocation.Demand, 1, 1}
        PlantUtilities.SetPlantLocationLinks(state, state.dataWaterCoils.WaterCoil[1].WaterPlantLoc)
        state.dataPlnt.PlantLoop[1].glycol = Fluid.GetWater(state)
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].Name = state.dataWaterCoils.WaterCoil[1].Name
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].Type = DataPlant.PlantEquipmentType.CoilWaterSimpleHeating
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].NodeNumIn = state.dataWaterCoils.WaterCoil[1].WaterInletNodeNum
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].NodeNumOut = state.dataWaterCoils.WaterCoil[1].WaterOutletNodeNum
        state.dataSingleDuct.sd_airterminal[1].HWplantLoc = {1, DataPlant.LoopSideLocation.Demand, 1, 0}
        PlantUtilities.SetPlantLocationLinks(state, state.dataSingleDuct.sd_airterminal[1].HWplantLoc)
        state.dataSize.CurZoneEqNum = 1
        state.dataSize.CurTermUnitSizingNum = 1
        state.dataSize.CurSysNum = 0
        state.dataHeatBal.Zone[1].FloorArea = 99.16
        state.dataSingleDuct.sd_airterminal[1].ZoneFloorArea = state.dataHeatBal.Zone[1].FloorArea
        state.dataSingleDuct.sd_airterminal[1].SizeSys(state)
        state.dataGlobal.BeginEnvrnFlag = True
        Expect_NEAR(state.dataWaterCoils.WaterCoil[1].MaxWaterVolFlowRate, .0000850575, 0.000000001) # water flow rate input by user
        Expect_NEAR(state.dataWaterCoils.WaterCoil[1].UACoil, 300.00, 0.01)                          # Ua input by user
        Expect_EQ(state.dataWaterCoils.WaterCoil[1].DesTotWaterCoilLoad, DataSizing.AutoSize)       # Rated Capacity input by user
        Expect_EQ(state.dataWaterCoils.WaterCoil[1].DesWaterHeatingCoilRate, 0.0)                    # model output not yet set
        InitWaterCoil(state, 1, False)
        Expect_NEAR(state.dataWaterCoils.WaterCoil[1].DesWaterHeatingCoilRate, 7390.73, 0.01)
        Expect_EQ(state.dataWaterCoils.WaterCoil[1].DesTotWaterCoilLoad, DataSizing.AutoSize)
        state.dataSingleDuct.sd_airterminal.deallocate()