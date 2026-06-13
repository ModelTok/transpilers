from gtest import Test, TestFixture, Assert, AssertTrue, AssertFalse, AssertEqual, AssertEnumEqual, AssertNear, CompareErrStream, DelimitedString
from ObjexxFCL.Array1D import Array1D
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataAirLoop import DataAirLoop
from EnergyPlus.DataConvergParams import DataConvergParams
from EnergyPlus.DataHVACGlobals import DataHVACGlobals
from EnergyPlus.DataSizing import DataSizing
from EnergyPlus.HVACControllers import HVACControllers
from EnergyPlus.MixedAir import MixedAir
from EnergyPlus.OutputReportPredefined import OutputReportPredefined
from EnergyPlus.ScheduleManager import ScheduleManager
from EnergyPlus.SetPointManager import SetPointManager
from EnergyPlus.SimAirServingZones import SimAirServingZones
from EnergyPlus.WaterCoils import WaterCoils
from Fixtures.EnergyPlusFixture import EnergyPlusFixture

using EnergyPlus::MixedAir
using EnergyPlus::HVACControllers
using EnergyPlus::SetPointManager
using EnergyPlus::WaterCoils

@fixture
class EnergyPlusFixture(TestFixture):

@fixture
class HVACControllers_ResetHumidityRatioCtrlVarType(EnergyPlusFixture):
    def TestBody(self):
        var idf_objects: String = DelimitedString([
            " Coil:Cooling:Water,",
            "	Chilled Water Coil,	!- Name",
            "	AvailSched,			!- Availability Schedule Name",
            "	autosize,			!- Design Water Flow Rate { m3 / s }",
            "	autosize,			!- Design Air Flow Rate { m3 / s }",
            "	autosize,			!- Design Inlet Water Temperature { C }",
            "	autosize,			!- Design Inlet Air Temperature { C }",
            "	autosize,			!- Design Outlet Air Temperature { C }",
            "	autosize,			!- Design Inlet Air Humidity Ratio { kgWater / kgDryAir }",
            "	autosize,			!- Design Outlet Air Humidity Ratio { kgWater / kgDryAir }",
            "	Water Inlet Node,	!- Water Inlet Node Name",
            "	Water Outlet Node,  !- Water Outlet Node Name",
            "	Air Inlet Node,		!- Air Inlet Node Name",
            "	Air Outlet Node,	!- Air Outlet Node Name",
            "	SimpleAnalysis,		!- Type of Analysis",
            "	CrossFlow;          !- Heat Exchanger Configuration",
            " Controller:WaterCoil,",
            "	CW Coil Controller, !- Name",
            "	HumidityRatio,		!- Control Variable",
            "	Reverse,			!- Action",
            "	FLOW,				!- Actuator Variable",
            "	Air Outlet Node,	!- Sensor Node Name",
            "	Water Inlet Node,	!- Actuator Node Name",
            "	autosize,			!- Controller Convergence Tolerance { deltaC }",
            "	autosize,			!- Maximum Actuated Flow { m3 / s }",
            "	0.0;				!- Minimum Actuated Flow { m3 / s }",
            " SetpointManager:Scheduled,",
            "	HumRatSPManager,	!- Name",
            "	HumidityRatio,		!- Control Variable",
            "	HumRatioSched,		!- Schedule Name",
            "	Air Outlet Node;	!- Setpoint Node or NodeList Name",
            " Schedule:Compact,",
            "   HumRatioSched,		!- Name",
            "	Any Number,			!- Schedule Type Limits Name",
            "	Through: 12/31,		!- Field 1",
            "	For: AllDays,		!- Field 2",
            "	Until: 24:00, 0.015; !- Field 3",
            " Schedule:Compact,",
            "   AvailSched,			!- Name",
            "	Fraction,			!- Schedule Type Limits Name",
            "	Through: 12/31,		!- Field 1",
            "	For: AllDays,		!- Field 2",
            "	Until: 24:00, 1.0;  !- Field 3",
            " AirLoopHVAC:ControllerList,",
            "	CW Coil Controller, !- Name",
            "	Controller:WaterCoil, !- Controller 1 Object Type",
            "	CW Coil Controller; !- Controller 1 Name",
        ])
        AssertTrue(process_idf(idf_objects))
        state.init_state(state)
        GetSetPointManagerInputs(state)
        AssertEnumEqual(HVAC.CtrlVarType.HumRat, state.dataSetPointManager.spms[1].ctrlVar)
        GetControllerInput(state)
        AssertEnumEqual(HVAC.CtrlVarType.MaxHumRat, state.dataSetPointManager.spms[1].ctrlVar)
        state.dataHVACControllers.ControllerProps[1].HumRatCntrlType = GetHumidityRatioVariableType(state, state.dataHVACControllers.ControllerProps[1].SensedNode)
        AssertEqual(state.dataHVACControllers.ControllerProps.size(), 1)
        AssertEqual(state.dataHVACControllers.ControllerProps[1].MaxVolFlowActuated, DataSizing.AutoSize)
        AssertEqual(state.dataHVACControllers.ControllerProps[1].Offset, DataSizing.AutoSize)

@fixture
class HVACControllers_TestTempAndHumidityRatioCtrlVarType(EnergyPlusFixture):
    def TestBody(self):
        var idf_objects: String = DelimitedString([
            " Coil:Cooling:Water,",
            "	Chilled Water Coil,	!- Name",
            "	AvailSched,			!- Availability Schedule Name",
            "	0.01,				!- Design Water Flow Rate { m3 / s }",
            "	1.0,				!- Design Air Flow Rate { m3 / s }",
            "	7.2,				!- Design Inlet Water Temperature { C }",
            "	32.0,				!- Design Inlet Air Temperature { C }",
            "	12.0,				!- Design Outlet Air Temperature { C }",
            "	0.01,				!- Design Inlet Air Humidity Ratio { kgWater / kgDryAir }",
            "	0.07,				!- Design Outlet Air Humidity Ratio { kgWater / kgDryAir }",
            "	Water Inlet Node,	!- Water Inlet Node Name",
            "	Water Outlet Node,  !- Water Outlet Node Name",
            "	Air Inlet Node,		!- Air Inlet Node Name",
            "	Air Outlet Node,	!- Air Outlet Node Name",
            "	SimpleAnalysis,		!- Type of Analysis",
            "	CrossFlow;          !- Heat Exchanger Configuration",
            " Controller:WaterCoil,",
            "	CW Coil Controller, !- Name",
            "	TemperatureAndHumidityRatio,		!- Control Variable",
            "	Reverse,			!- Action",
            "	FLOW,				!- Actuator Variable",
            "	Air Outlet Node,	!- Sensor Node Name",
            "	Water Inlet Node,	!- Actuator Node Name",
            "	0.001,				!- Controller Convergence Tolerance { deltaC }",
            "	0.01,				!- Maximum Actuated Flow { m3 / s }",
            "	0.0;				!- Minimum Actuated Flow { m3 / s }",
            " SetpointManager:Scheduled,",
            "	HumRatSPManager,	!- Name",
            "	MaximumHumidityRatio,  !- Control Variable",
            "	HumRatioSched,		!- Schedule Name",
            "	Air Outlet Node;	!- Setpoint Node or NodeList Name",
            " Schedule:Compact,",
            "   HumRatioSched,		!- Name",
            "	Any Number,			!- Schedule Type Limits Name",
            "	Through: 12/31,		!- Field 1",
            "	For: AllDays,		!- Field 2",
            "	Until: 24:00, 0.015; !- Field 3",
            " Schedule:Compact,",
            "   AvailSched,			!- Name",
            "	Fraction,			!- Schedule Type Limits Name",
            "	Through: 12/31,		!- Field 1",
            "	For: AllDays,		!- Field 2",
            "	Until: 24:00, 1.0;  !- Field 3",
            " AirLoopHVAC:ControllerList,",
            "	CW Coil Controller, !- Name",
            "	Controller:WaterCoil, !- Controller 1 Object Type",
            "	CW Coil Controller; !- Controller 1 Name",
        ])
        AssertTrue(process_idf(idf_objects))
        state.init_state(state)
        GetSetPointManagerInputs(state)
        AssertEnumEqual(HVAC.CtrlVarType.MaxHumRat, state.dataSetPointManager.spms[1].ctrlVar)
        GetControllerInput(state)
        AssertEnumEqual(HVAC.CtrlVarType.MaxHumRat, state.dataSetPointManager.spms[1].ctrlVar)
        state.dataHVACControllers.ControllerProps[1].HumRatCntrlType = GetHumidityRatioVariableType(state, state.dataHVACControllers.ControllerProps[1].SensedNode)
        AssertEnumEqual(HVAC.CtrlVarType.MaxHumRat, state.dataHVACControllers.ControllerProps[1].HumRatCntrlType)
        AssertEqual(0, state.dataHVACControllers.ControllerProps[1].AirLoopControllerIndex)
        state.dataSimAirServingZones.GetAirLoopInputFlag = False
        state.dataHVACGlobal.NumPrimaryAirSys = 1
        state.dataAirLoop.PriAirSysAvailMgr.allocate(1)
        state.dataAirLoop.AirLoopControlInfo.allocate(1)
        state.dataAirLoop.AirToZoneNodeInfo.allocate(1)
        state.dataAirLoop.AirToZoneNodeInfo[1].NumSupplyNodes = 1
        state.dataAirLoop.AirToZoneNodeInfo[1].AirLoopSupplyNodeNum.allocate(1)
        state.dataAirLoop.AirToZoneNodeInfo[1].AirLoopSupplyNodeNum[1] = 1
        state.dataAirLoop.AirToZoneNodeInfo[1].ZoneEquipSupplyNodeNum.allocate(1)
        state.dataAirLoop.AirToZoneNodeInfo[1].ZoneEquipSupplyNodeNum[1] = 4
        state.dataConvergeParams.AirLoopConvergence.allocate(1)
        state.dataAirSystemsData.PrimaryAirSystems.allocate(1)
        state.dataAirSystemsData.PrimaryAirSystems[1].NumBranches = 1
        state.dataAirSystemsData.PrimaryAirSystems[1].NumControllers = 1
        state.dataAirSystemsData.PrimaryAirSystems[1].ControllerIndex.allocate(1)
        state.dataAirSystemsData.PrimaryAirSystems[1].ControllerIndex[1] = 0
        state.dataAirSystemsData.PrimaryAirSystems[1].ControllerName.allocate(1)
        state.dataAirSystemsData.PrimaryAirSystems[1].ControllerName[1] = "CW COIL CONTROLLER"
        state.dataAirSystemsData.PrimaryAirSystems[1].ControlConverged.allocate(1)
        state.dataAirSystemsData.PrimaryAirSystems[1].Branch.allocate(1)
        state.dataAirSystemsData.PrimaryAirSystems[1].Branch[1].NodeNumIn = 4
        state.dataAirSystemsData.PrimaryAirSystems[1].Branch[1].NodeNumOut = 1
        state.dataAirSystemsData.PrimaryAirSystems[1].Branch[1].TotalNodes = 1
        state.dataAirSystemsData.PrimaryAirSystems[1].Branch[1].TotalComponents = 1
        state.dataAirSystemsData.PrimaryAirSystems[1].Branch[1].NodeNum.allocate(1)
        state.dataAirSystemsData.PrimaryAirSystems[1].Branch[1].NodeNum[1] = 1
        state.dataAirSystemsData.PrimaryAirSystems[1].Branch[1].Comp.allocate(1)
        state.dataAirSystemsData.PrimaryAirSystems[1].Branch[1].Comp[1].Name = "CHILLED WATER COIL"
        state.dataAirSystemsData.PrimaryAirSystems[1].Branch[1].Comp[1].CompType_Num = SimAirServingZones.CompType.WaterCoil_Cooling
        state.dataPlnt.PlantLoop.allocate(1)
        state.dataPlnt.TotNumLoops = 1
        state.dataPlnt.PlantLoop[1].FluidName = "WATER"
        state.dataPlnt.PlantLoop[1].glycol = Fluid.GetWater(state)
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].TotalBranches = 1
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch.allocate(1)
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].TotalComponents = 1
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp.allocate(1)
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].Type = DataPlant.PlantEquipmentType.CoilWaterCooling
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].NodeNumIn = 2
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].NodeNumOut = 3
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].Name = "CHILLED WATER COIL"
        var SimZoneEquipment: Bool = False
        SimAirServingZones.SimAirLoops(state, True, SimZoneEquipment)
        AssertEqual(1, state.dataAirSystemsData.PrimaryAirSystems[1].NumControllers)
        AssertEqual(1, state.dataAirSystemsData.PrimaryAirSystems[1].ControllerIndex[1])
        AssertEqual(1, state.dataHVACControllers.ControllerProps[1].AirLoopControllerIndex)

@fixture
class HVACControllers_SchSetPointMgrsOrderTest(EnergyPlusFixture):
    def TestBody(self):
        var idf_objects: String = DelimitedString([
            "  Coil:Cooling:Water,",
            "    Main Cooling Coil 1,     !- Name",
            "    CoolingCoilAvailSched,   !- Availability Schedule Name",
            "    autosize,                !- Design Water Flow Rate {m3/s}",
            "    autosize,                !- Design Air Flow Rate {m3/s}",
            "    autosize,                !- Design Inlet Water Temperature {C}",
            "    autosize,                !- Design Inlet Air Temperature {C}",
            "    autosize,                !- Design Outlet Air Temperature {C}",
            "    autosize,                !- Design Inlet Air Humidity Ratio {kgWater/kgDryAir}",
            "    autosize,                !- Design Outlet Air Humidity Ratio {kgWater/kgDryAir}",
            "    CCoil Water Inlet Node,  !- Water Inlet Node Name",
            "    CCoil Water Outlet Node, !- Water Outlet Node Name",
            "    Mixed Air Node 1,        !- Air Inlet Node Name",
            "    CCoil Air Outlet Node,   !- Air Outlet Node Name",
            "    SimpleAnalysis,          !- Type of Analysis",
            "    CrossFlow;               !- Heat Exchanger Configuration",
            "  Schedule:Compact,",
            "   CoolingCoilAvailSched,	  !- Name",
            "	Fraction,			      !- Schedule Type Limits Name",
            "	Through: 12/31,		      !- Field 1",
            "	For: AllDays,		      !- Field 2",
            "	Until: 24:00, 1.0;        !- Field 3",
            "  Controller:WaterCoil,",
            "    Cooling Coil Controller,  !- Name",
            "    HumidityRatio,           !- Control Variable",
            "    Reverse,                 !- Action",
            "    FLOW,                    !- Actuator Variable",
            "    CCoil Air Outlet Node,   !- Sensor Node Name",
            "    CCoil Water Inlet Node,  !- Actuator Node Name",
            "    autosize,                !- Controller Convergence Tolerance {deltaC}",
            "    autosize,                !- Maximum Actuated Flow {m3/s}",
            "    0.0;                     !- Minimum Actuated Flow {m3/s}",
            "  SetpointManager:Scheduled,",
            "    CCoil Temp Setpoint Mgr, !- Name",
            "    Temperature,             !- Control Variable",
            "    Always 16,               !- Schedule Name",
            "    CCoil Air Outlet Node;   !- Setpoint Node or NodeList Name",
            "  Schedule:Compact,",
            "    Always 16,               !- Name",
            "    Temperature,             !- Schedule Type Limits Name",
            "    Through: 12/31,          !- Field 1",
            "    For: AllDays,            !- Field 2",
            "    Until: 24:00,16;         !- Field 3",
            "  SetpointManager:Scheduled,",
            "    CCoil Hum Setpoint Mgr,  !- Name",
            "    MaximumHumidityRatio,    !- Control Variable",
            "    HumSetPt,                !- Schedule Name",
            "    CCoil Air Outlet Node;   !- Setpoint Node or NodeList Name",
            "  Schedule:Compact,",
            "    HumSetPt,                !- Name",
            "    AnyNumber,               !- Schedule Type Limits Name",
            "    Through: 12/31,          !- Field 1",
            "    For: AllDays,            !- Field 2",
            "    Until: 24:00, 0.009;     !- Field 3",
            "  AirLoopHVAC:ControllerList,",
            "	CW Coil Controller,       !- Name",
            "	Controller:WaterCoil,     !- Controller 1 Object Type",
            "	Cooling Coil Controller;   !- Controller 1 Name",
        ])
        AssertTrue(process_idf(idf_objects))
        state.init_state(state)
        GetSetPointManagerInputs(state)
        AssertEqual(2, state.dataSetPointManager.spms.size()) // 2 schedule set point managers
        var spmCCoilHumNum: Int = SetPointManager.GetSetPointManagerIndex(state, "CCOIL HUM SETPOINT MGR")
        var spmCCoilHum = state.dataSetPointManager.spms[spmCCoilHumNum]
        var spmCCoilTempNum: Int = SetPointManager.GetSetPointManagerIndex(state, "CCOIL TEMP SETPOINT MGR")
        var spmCCoilTemp = state.dataSetPointManager.spms[spmCCoilTempNum]
        AssertEnumEqual(HVAC.CtrlVarType.Temp, spmCCoilTemp.ctrlVar)     // is "Temperature"
        AssertEnumEqual(HVAC.CtrlVarType.MaxHumRat, spmCCoilHum.ctrlVar) // is "MaximumHumidityRatio"
        GetControllerInput(state)
        state.dataHVACControllers.ControllerProps[1].HumRatCntrlType = GetHumidityRatioVariableType(state, state.dataHVACControllers.ControllerProps[1].SensedNode)
        AssertEnumEqual(HVAC.CtrlVarType.MaxHumRat, state.dataHVACControllers.ControllerProps[1].HumRatCntrlType) // MaximumHumidityRatio

@fixture
class HVACControllers_WaterCoilOnPrimaryLoopCheckTest(EnergyPlusFixture):
    def TestBody(self):
        var idf_objects: String = DelimitedString([
            " Coil:Cooling:Water,",
            "	Chilled Water Coil,	!- Name",
            "	,        			!- Availability Schedule Name",
            "	0.01,				!- Design Water Flow Rate { m3 / s }",
            "	1.0,				!- Design Air Flow Rate { m3 / s }",
            "	7.2,				!- Design Inlet Water Temperature { C }",
            "	32.0,				!- Design Inlet Air Temperature { C }",
            "	12.0,				!- Design Outlet Air Temperature { C }",
            "	0.01,				!- Design Inlet Air Humidity Ratio { kgWater / kgDryAir }",
            "	0.07,				!- Design Outlet Air Humidity Ratio { kgWater / kgDryAir }",
            "	Water Inlet Node,	!- Water Inlet Node Name",
            "	Water Outlet Node,  !- Water Outlet Node Name",
            "	Air Inlet Node,		!- Air Inlet Node Name",
            "	Air Outlet Node,	!- Air Outlet Node Name",
            "	SimpleAnalysis,		!- Type of Analysis",
            "	CrossFlow;          !- Heat Exchanger Configuration",
            " Controller:WaterCoil,",
            "	CW Coil Controller, !- Name",
            "	TemperatureAndHumidityRatio,!- Control Variable",
            "	Reverse,			!- Action",
            "	FLOW,				!- Actuator Variable",
            "	Air Outlet Node,	!- Sensor Node Name",
            "	Water Inlet Node,	!- Actuator Node Name",
            "	0.001,				!- Controller Convergence Tolerance { deltaC }",
            "	0.01,				!- Maximum Actuated Flow { m3 / s }",
            "	0.0;				!- Minimum Actuated Flow { m3 / s }",
            " AirLoopHVAC:ControllerList,",
            "	CW Coil Controller, !- Name",
            "	Controller:WaterCoil,   !- Controller 1 Object Type",
            "	CW Coil Controller; !- Controller 1 Name",
        ])
        AssertTrue(process_idf(idf_objects))
        state.init_state(state)
        GetControllerInput(state)
        AssertEqual(state.dataWaterCoils.WaterCoil[1].Name, "CHILLED WATER COIL")
        AssertEqual(state.dataWaterCoils.WaterCoil[1].WaterCoilType, DataPlant.PlantEquipmentType.CoilWaterCooling)
        state.dataSimAirServingZones.GetAirLoopInputFlag = False
        state.dataHVACGlobal.NumPrimaryAirSys = 1
        state.dataAirSystemsData.PrimaryAirSystems.allocate(1)
        state.dataAirSystemsData.PrimaryAirSystems[1].NumBranches = 1
        state.dataAirSystemsData.PrimaryAirSystems[1].NumControllers = 1
        state.dataAirSystemsData.PrimaryAirSystems[1].ControllerIndex.allocate(1)
        state.dataAirSystemsData.PrimaryAirSystems[1].ControllerIndex[1] = 0
        state.dataAirSystemsData.PrimaryAirSystems[1].ControllerName.allocate(1)
        state.dataAirSystemsData.PrimaryAirSystems[1].ControllerName[1] = "CW COIL CONTROLLER"
        state.dataAirSystemsData.PrimaryAirSystems[1].ControlConverged.allocate(1)
        state.dataAirSystemsData.PrimaryAirSystems[1].Branch.allocate(1)
        state.dataAirSystemsData.PrimaryAirSystems[1].Branch[1].NodeNumIn = 4
        state.dataAirSystemsData.PrimaryAirSystems[1].Branch[1].NodeNumOut = 1
        state.dataAirSystemsData.PrimaryAirSystems[1].Branch[1].TotalNodes = 1
        state.dataAirSystemsData.PrimaryAirSystems[1].Branch[1].TotalComponents = 1
        state.dataAirSystemsData.PrimaryAirSystems[1].Branch[1].NodeNum.allocate(1)
        state.dataAirSystemsData.PrimaryAirSystems[1].Branch[1].NodeNum[1] = 1
        state.dataAirSystemsData.PrimaryAirSystems[1].Branch[1].Comp.allocate(1)
        state.dataAirSystemsData.PrimaryAirSystems[1].Branch[1].Comp[1].Name = state.dataWaterCoils.WaterCoil[1].Name
        state.dataAirSystemsData.PrimaryAirSystems[1].Branch[1].Comp[1].CompType_Num = SimAirServingZones.CompType.WaterCoil_Cooling
        var WaterCoilOnAirLoop: Bool = True
        var CompType: String = String(HVAC.coilTypeNames[Int(HVAC.CoilType.CoolingWater)]) //"Coil:Cooling:Water";
        var CompName: String = "CHILLED WATER COIL"
        var CoilTypeNum: SimAirServingZones.CompType = SimAirServingZones.CompType.WaterCoil_Cooling
        WaterCoilOnAirLoop = SimAirServingZones.CheckWaterCoilOnPrimaryAirLoopBranch(state, CoilTypeNum, CompName)
        AssertTrue(WaterCoilOnAirLoop)
        WaterCoilOnAirLoop = True
        WaterCoilOnAirLoop = SimAirServingZones.CheckWaterCoilOnOASystem(state, CoilTypeNum, CompName)
        AssertFalse(WaterCoilOnAirLoop)
        WaterCoilOnAirLoop = True
        WaterCoilOnAirLoop = SimAirServingZones.CheckWaterCoilSystemOnAirLoopOrOASystem(state, CoilTypeNum, CompName)
        AssertFalse(WaterCoilOnAirLoop)
        WaterCoilOnAirLoop = True
        SimAirServingZones.CheckWaterCoilIsOnAirLoop(state, CoilTypeNum, CompType, CompName, WaterCoilOnAirLoop)
        AssertTrue(WaterCoilOnAirLoop)
        CoilTypeNum = SimAirServingZones.CompType.WaterCoil_DetailedCool
        WaterCoilOnAirLoop = SimAirServingZones.CheckWaterCoilOnPrimaryAirLoopBranch(state, CoilTypeNum, CompName)
        AssertFalse(WaterCoilOnAirLoop)

@fixture
class HVACControllers_WaterCoilOnOutsideAirSystemCheckTest(EnergyPlusFixture):
    def TestBody(self):
        var idf_objects: String = DelimitedString([
            "  AirLoopHVAC:ControllerList,",
            "    OA Sys 1 Controllers,    !- Name",
            "    Controller:WaterCoil,    !- Controller 1 Object Type",
            "    Preheat Coil Controller; !- Controller 1 Name",
            "  Coil:Heating:Water,",
            "    OA Preheat HW Coil,      !- Name",
            "    ,                        !- Availability Schedule Name",
            "    autosize,                !- U-Factor Times Area Value {W/K}",
            "    autosize,                !- Maximum Water Flow Rate {m3/s}",
            "    HWCoil Water InletNode,  !- Zone1UnitHeatHWInletNode,!- Water Inlet Node Name",
            "    HWCoil Water OutletNode, !- Water Outlet Node Name",
            "    Outside Air Inlet Node,  !- Air Inlet Node Name",
            "    HW Coil Air OutletNode,  !- Air Outlet Node Name",
            "    UFactorTimesAreaAndDesignWaterFlowRate,  !- Performance Input Method",
            "    autosize,                !- Rated Capacity {W}",
            "    82.2,                    !- Rated Inlet Water Temperature {C}",
            "    16.6,                    !- Rated Inlet Air Temperature {C}",
            "    71.1,                    !- Rated Outlet Water Temperature {C}",
            "    32.2,                    !- Rated Outlet Air Temperature {C}",
            "    ;                        !- Rated Ratio for Air and Water Convection",
            "  Controller:WaterCoil,",
            "    Preheat Coil Controller, !- Name",
            "    Temperature,             !- Control Variable",
            "    Normal,                  !- Action",
            "    Flow,                    !- Actuator Variable",
            "    HW Coil Air OutletNode,  !- Sensor Node Name",
            "    HWCoil Water InletNode,  !- Actuator Node Name",
            "    Autosize,                !- Controller Convergence Tolerance {deltaC}",
            "    Autosize,                !- Maximum Actuated Flow {m3/s}",
            "    0;                       !- Minimum Actuated Flow {m3/s}",
        ])
        AssertTrue(process_idf(idf_objects))
        state.init_state(state)
        GetControllerInput(state)
        AssertEqual(state.dataWaterCoils.WaterCoil[1].Name, "OA PREHEAT HW COIL")
        AssertEqual(state.dataWaterCoils.WaterCoil[1].WaterCoilType, DataPlant.PlantEquipmentType.CoilWaterSimpleHeating)
        state.dataSimAirServingZones.GetAirLoopInputFlag = False
        state.dataAirLoop.NumOASystems = 1
        state.dataAirLoop.OutsideAirSys.allocate(1)
        state.dataAirLoop.OutsideAirSys[1].Name = "AIRLOOP OASYSTEM"
        state.dataAirLoop.OutsideAirSys[1].NumControllers = 1
        state.dataAirLoop.OutsideAirSys[1].ControllerName.allocate(1)
        state.dataAirLoop.OutsideAirSys[1].ControllerName[1] = "OA CONTROLLER 1"
        state.dataAirLoop.OutsideAirSys[1].NumComponents = 2
        state.dataAirLoop.OutsideAirSys[1].ComponentType.allocate(2)
        state.dataAirLoop.OutsideAirSys[1].ComponentType[1] = HVAC.coilTypeNames[Int(HVAC.CoilType.HeatingWater)]
        state.dataAirLoop.OutsideAirSys[1].ComponentType[2] = "OutdoorAir:Mixer"
        state.dataAirLoop.OutsideAirSys[1].ComponentName.allocate(2)
        state.dataAirLoop.OutsideAirSys[1].ComponentName[1] = state.dataWaterCoils.WaterCoil[1].Name
        state.dataAirLoop.OutsideAirSys[1].ComponentName[2] = "OAMixer"
        state.dataAirLoop.OutsideAirSys[1].ComponentTypeEnum.allocate(2)
        state.dataAirLoop.OutsideAirSys[1].ComponentTypeEnum[1] = SimAirServingZones.CompType.WaterCoil_SimpleHeat
        state.dataAirLoop.OutsideAirSys[1].ComponentTypeEnum[2] = SimAirServingZones.CompType.OAMixer_Num
        state.dataMixedAir.OAMixer.allocate(1)
        state.dataMixedAir.OAMixer[1].Name = "OAMixer"
        state.dataMixedAir.OAMixer[1].InletNode = 2
        state.dataHVACGlobal.NumPrimaryAirSys = 1
        state.dataAirSystemsData.PrimaryAirSystems.allocate(1)
        state.dataAirSystemsData.PrimaryAirSystems[1].Name = "PrimaryAirLoop"
        state.dataAirSystemsData.PrimaryAirSystems[1].NumBranches = 1
        state.dataAirSystemsData.PrimaryAirSystems[1].Branch.allocate(1)
        state.dataAirSystemsData.PrimaryAirSystems[1].Branch[1].TotalComponents = 1
        state.dataAirSystemsData.PrimaryAirSystems[1].Branch[1].Comp.allocate(1)
        state.dataAirSystemsData.PrimaryAirSystems[1].Branch[1].Comp[1].Name = state.dataAirLoop.OutsideAirSys[1].Name
        state.dataAirSystemsData.PrimaryAirSystems[1].Branch[1].Comp[1].TypeOf = "AirLoopHVAC:OutdoorAirSystem"
        var WaterCoilOnAirLoop: Bool = True
        var CompType: String = String(HVAC.coilTypeNames[Int(HVAC.CoilType.HeatingWater)])
        var CompName: String = state.dataWaterCoils.WaterCoil[1].Name
        var CoilTypeNum: SimAirServingZones.CompType = SimAirServingZones.CompType.WaterCoil_SimpleHeat
        WaterCoilOnAirLoop = SimAirServingZones.CheckWaterCoilOnPrimaryAirLoopBranch(state, CoilTypeNum, CompName)
        AssertFalse(WaterCoilOnAirLoop)
        WaterCoilOnAirLoop = False
        WaterCoilOnAirLoop = SimAirServingZones.CheckWaterCoilOnOASystem(state, CoilTypeNum, CompName)
        AssertTrue(WaterCoilOnAirLoop)
        WaterCoilOnAirLoop = False
        SimAirServingZones.CheckWaterCoilIsOnAirLoop(state, CoilTypeNum, CompType, CompName, WaterCoilOnAirLoop)
        AssertTrue(WaterCoilOnAirLoop)
        CoilTypeNum = SimAirServingZones.CompType.WaterCoil_DetailedCool
        WaterCoilOnAirLoop = True
        WaterCoilOnAirLoop = SimAirServingZones.CheckWaterCoilOnOASystem(state, CoilTypeNum, CompName)
        AssertFalse(WaterCoilOnAirLoop)

@fixture
class HVACControllers_CoilSystemCoolingWaterOnOutsideAirSystemCheckTest(EnergyPlusFixture):
    def TestBody(self):
        var idf_objects: String = DelimitedString([
            "  AirLoopHVAC:ControllerList,",
            "    OA System Controllers,   !- Name",
            "    Controller:WaterCoil,    !- Controller 1 Object Type",
            "    Detailed WaterCoil Cntrl;!- Controller 1 Name",
            "  Controller:WaterCoil,",
            "    Detailed WaterCoil Cntrl,!- Name",
            "    Temperature,             !- Control Variable",
            "    Reverse,                 !- Action",
            "    FLOW,                    !- Actuator Variable",
            "    Main Cooling Coil 1 Outlet Node,  !- Sensor Node Name",
            "    Main Cooling Coil 1 Water Inlet Node,  !- Actuator Node Name",
            "    0.002,                   !- Controller Convergence Tolerance {deltaC}",
            "    autosize,                !- Maximum Actuated Flow {m3/s}",
            "    0.0;                     !- Minimum Actuated Flow {m3/s}",
            "  Coil:Cooling:Water:DetailedGeometry,",
            "    Detailed Pre Cooling Coil, !- Name",
            "    ,                        !- Availability Schedule Name",
            "    autosize,                !- Maximum Water Flow Rate {m3/s}",
            "    autosize,                !- Tube Outside Surface Area {m2}",
            "    autosize,                !- Total Tube Inside Area {m2}",
            "    autosize,                !- Fin Surface Area {m2}",
            "    autosize,                !- Minimum Airflow Area {m2}",
            "    autosize,                !- Coil Depth {m}",
            "    autosize,                !- Fin Diameter {m}",
            "    ,                        !- Fin Thickness {m}",
            "    ,                        !- Tube Inside Diameter {m}",
            "    ,                        !- Tube Outside Diameter {m}",
            "    ,                        !- Tube Thermal Conductivity {W/m-K}",
            "    ,                        !- Fin Thermal Conductivity {W/m-K}",
            "    ,                        !- Fin Spacing {m}",
            "    ,                        !- Tube Depth Spacing {m}",
            "    ,                        !- Number of Tube Rows",
            "    autosize,                !- Number of Tubes per Row",
            "    Main Cooling Coil 1 Water Inlet Node,  !- Water Inlet Node Name",
            "    Main Cooling Coil 1 Water Outlet Node,  !- Water Outlet Node Name",
            "    Main Cooling Coil 1 Inlet Node,  !- Air Inlet Node Name",
            "    Main Cooling Coil 1 Outlet Node;  !- Air Outlet Node Name",
            "  CoilSystem:Cooling:Water:HeatExchangerAssisted,",
            "    HXAssisting Cooling Coil,  !- Name",
            "    HeatExchanger:AirToAir:FlatPlate,  !- Heat Exchanger Object Type",
            "    HXAssisting Cooling Coil,  !- Heat Exchanger Name",
            "    Coil:Cooling:Water:DetailedGeometry,  !- Cooling Coil Object Type",
            "    Detailed Pre Cooling Coil; !- Cooling Coil Name",
            "  HeatExchanger:AirToAir:FlatPlate,",
            "    HXAssisting Cooling Coil,!- Name",
            "    ,                        !- Availability Schedule Name",
            "    CounterFlow,             !- Flow Arrangement Type",
            "    Yes,                     !- Economizer Lockout",
            "    1.0,                     !- Ratio of Supply to Secondary hA Values",
            "    1.32,                    !- Nominal Supply Air Flow Rate {m3/s}",
            "    24.0,                    !- Nominal Supply Air Inlet Temperature {C}",
            "    21.0,                    !- Nominal Supply Air Outlet Temperature {C}",
            "    1.32,                    !- Nominal Secondary Air Flow Rate {m3/s}",
            "    12.0,                    !- Nominal Secondary Air Inlet Temperature {C}",
            "    100.0,                   !- Nominal Electric Power {W}",
            "    Mixed Air Node 1,        !- Supply Air Inlet Node Name",
            "    Main Cooling Coil 1 Inlet Node,  !- Supply Air Outlet Node Name",
            "    Main Cooling Coil 1 Outlet Node,  !- Secondary Air Inlet Node Name",
            "    Main Heating Coil 1 Inlet Node;  !- Secondary Air Outlet Node Name",
        ])
        AssertTrue(process_idf(idf_objects))
        state.init_state(state)
        GetControllerInput(state)
        AssertEqual(state.dataWaterCoils.WaterCoil[1].Name, "DETAILED PRE COOLING COIL")
        AssertEqual(state.dataWaterCoils.WaterCoil[1].WaterCoilType, DataPlant.PlantEquipmentType.CoilWaterDetailedFlatCooling)
        state.dataSimAirServingZones.GetAirLoopInputFlag = False
        state.dataAirLoop.NumOASystems = 1
        state.dataAirLoop.OutsideAirSys.allocate(1)
        state.dataAirLoop.OutsideAirSys[1].Name = "AIRLOOP OASYSTEM"
        state.dataAirLoop.OutsideAirSys[1].NumControllers = 1
        state.dataAirLoop.OutsideAirSys[1].ControllerName.allocate(1)
        state.dataAirLoop.OutsideAirSys[1].ControllerName[1] = "OA CONTROLLER 1"
        state.dataAirLoop.OutsideAirSys[1].NumComponents = 2
        state.dataAirLoop.OutsideAirSys[1].ComponentType.allocate(2)
        state.dataAirLoop.OutsideAirSys[1].ComponentType[1] = HVAC.coilTypeNames[Int(HVAC.CoilType.CoolingWaterHXAssisted)]
        state.dataAirLoop.OutsideAirSys[1].ComponentType[2] = "OutdoorAir:Mixer"
        state.dataAirLoop.OutsideAirSys[1].ComponentName.allocate(2)
        state.dataAirLoop.OutsideAirSys[1].ComponentName[1] = "HXAssisting Cooling Coil"
        state.dataAirLoop.OutsideAirSys[1].ComponentName[2] = "OAMixer"
        state.dataAirLoop.OutsideAirSys[1].ComponentTypeEnum.allocate(2)
        state.dataAirLoop.OutsideAirSys[1].ComponentTypeEnum[1] = SimAirServingZones.CompType.WaterCoil_CoolingHXAsst
        state.dataAirLoop.OutsideAirSys[1].ComponentTypeEnum[2] = SimAirServingZones.CompType.OAMixer_Num
        state.dataMixedAir.OAMixer.allocate(1)
        state.dataMixedAir.OAMixer[1].Name = "OAMixer"
        state.dataMixedAir.OAMixer[1].InletNode = 2
        state.dataHVACGlobal.NumPrimaryAirSys = 1
        state.dataAirSystemsData.PrimaryAirSystems.allocate(1)
        state.dataAirSystemsData.PrimaryAirSystems[1].Name = "PrimaryAirLoop"
        state.dataAirSystemsData.PrimaryAirSystems[1].NumBranches = 1
        state.dataAirSystemsData.PrimaryAirSystems[1].Branch.allocate(1)
        state.dataAirSystemsData.PrimaryAirSystems[1].Branch[1].TotalComponents = 1
        state.dataAirSystemsData.PrimaryAirSystems[1].Branch[1].Comp.allocate(1)
        state.dataAirSystemsData.PrimaryAirSystems[1].Branch[1].Comp[1].Name = state.dataAirLoop.OutsideAirSys[1].Name
        state.dataAirSystemsData.PrimaryAirSystems[1].Branch[1].Comp[1].TypeOf = "AirLoopHVAC:OutdoorAirSystem"
        var WaterCoilOnAirLoop: Bool = True
        var CompType: String = String(HVAC.coilTypeNames[Int(HVAC.CoilType.CoolingWaterDetailed)])
        var CompName: String = state.dataWaterCoils.WaterCoil[1].Name
        var CoilTypeNum: SimAirServingZones.CompType = SimAirServingZones.CompType.WaterCoil_DetailedCool
        WaterCoilOnAirLoop = SimAirServingZones.CheckWaterCoilOnPrimaryAirLoopBranch(state, CoilTypeNum, CompName)
        AssertFalse(WaterCoilOnAirLoop)
        WaterCoilOnAirLoop = True
        WaterCoilOnAirLoop = SimAirServingZones.CheckWaterCoilOnOASystem(state, CoilTypeNum, CompName)
        AssertFalse(WaterCoilOnAirLoop)
        WaterCoilOnAirLoop = False
        WaterCoilOnAirLoop = SimAirServingZones.CheckWaterCoilSystemOnAirLoopOrOASystem(state, CoilTypeNum, CompName)
        AssertTrue(WaterCoilOnAirLoop)
        WaterCoilOnAirLoop = False
        SimAirServingZones.CheckWaterCoilIsOnAirLoop(state, CoilTypeNum, CompType, CompName, WaterCoilOnAirLoop)
        AssertTrue(WaterCoilOnAirLoop)

@fixture
class HVACControllers_CheckTempAndHumRatCtrl(EnergyPlusFixture):
    def TestBody(self):
        state.dataHVACControllers.ControllerProps.allocate(1)
        state.dataHVACControllers.RootFinders.allocate(1)
        var isConverged: Bool = True
        var controlNum: Int = 1
        var thisController = state.dataHVACControllers.ControllerProps[1]
        thisController.ControlVar = HVACControllers.CtrlVarType.TemperatureAndHumidityRatio
        thisController.Offset = 0.0001
        var sensedNode: Int = 1
        thisController.SensedNode = sensedNode
        state.dataLoopNodes.Node.allocate(2)
        state.dataLoopNodes.Node[sensedNode].Temp = 21.2
        state.dataLoopNodes.Node[sensedNode].HumRatMax = 0.001
        thisController.ActuatedNode = 2
        thisController.ActuatedNodePlantLoc = (0, DataPlant.LoopSideLocation.Invalid, 0, 0)
        isConverged = False
        thisController.HumRatCtrlOverride = False
        thisController.SetPointValue = 21.1
        thisController.IsSetPointDefinedFlag = True
        thisController.NumCalcCalls = 5
        state.dataLoopNodes.Node[sensedNode].HumRat = 0.0011
        HVACControllers.CheckTempAndHumRatCtrl(state, controlNum, isConverged)
        AssertFalse(isConverged)
        AssertFalse(thisController.HumRatCtrlOverride)
        AssertNear(thisController.SetPointValue, 21.1, 0.0001)
        AssertTrue(thisController.IsSetPointDefinedFlag)
        AssertEqual(thisController.NumCalcCalls, 5)
        isConverged = True
        thisController.HumRatCtrlOverride = True
        thisController.SetPointValue = 21.1
        thisController.IsSetPointDefinedFlag = True
        thisController.NumCalcCalls = 5
        state.dataLoopNodes.Node[sensedNode].HumRat = 0.0011
        HVACControllers.CheckTempAndHumRatCtrl(state, controlNum, isConverged)
        AssertTrue(isConverged)
        AssertTrue(thisController.HumRatCtrlOverride)
        AssertNear(thisController.SetPointValue, 21.1, 0.0001)
        AssertTrue(thisController.IsSetPointDefinedFlag)
        AssertEqual(thisController.NumCalcCalls, 5)
        isConverged = True
        thisController.HumRatCtrlOverride = False
        thisController.SetPointValue = 21.1
        thisController.IsSetPointDefinedFlag = True
        thisController.NumCalcCalls = 5
        state.dataLoopNodes.Node[sensedNode].HumRat = state.dataLoopNodes.Node[sensedNode].HumRatMax - 0.001
        HVACControllers.CheckTempAndHumRatCtrl(state, controlNum, isConverged)
        AssertTrue(isConverged)
        AssertFalse(thisController.HumRatCtrlOverride)
        AssertNear(thisController.SetPointValue, 21.1, 0.0001)
        AssertTrue(thisController.IsSetPointDefinedFlag)
        AssertEqual(thisController.NumCalcCalls, 5)
        isConverged = True
        thisController.HumRatCtrlOverride = False
        thisController.SetPointValue = 21.1
        thisController.IsSetPointDefinedFlag = True
        thisController.NumCalcCalls = 5
        state.dataLoopNodes.Node[sensedNode].HumRat = state.dataLoopNodes.Node[sensedNode].HumRatMax + 0.002
        HVACControllers.CheckTempAndHumRatCtrl(state, controlNum, isConverged)
        AssertFalse(isConverged)
        AssertTrue(thisController.HumRatCtrlOverride)
        AssertNear(thisController.SetPointValue, 0.0, 0.0001)
        AssertFalse(thisController.IsSetPointDefinedFlag)
        AssertEqual(thisController.NumCalcCalls, 0)
        isConverged = True
        thisController.HumRatCtrlOverride = False
        thisController.SetPointValue = 21.1
        thisController.IsSetPointDefinedFlag = True
        thisController.NumCalcCalls = 5
        state.dataLoopNodes.Node[sensedNode].HumRat = state.dataLoopNodes.Node[sensedNode].HumRatMax - 0.001
        thisController.ControlVar = HVACControllers.CtrlVarType.Temperature
        HVACControllers.CheckTempAndHumRatCtrl(state, controlNum, isConverged)
        AssertTrue(isConverged)
        AssertFalse(thisController.HumRatCtrlOverride)
        AssertNear(thisController.SetPointValue, 21.1, 0.0001)
        AssertTrue(thisController.IsSetPointDefinedFlag)
        AssertEqual(thisController.NumCalcCalls, 5)

@fixture
class HVACControllers_BlankAutosized(EnergyPlusFixture):
    def TestBody(self):
        var idf_objects: String = DelimitedString([
            " Coil:Cooling:Water,",
            "   Chilled Water Coil, !- Name",
            "   AvailSched,         !- Availability Schedule Name",
            "   autosize,           !- Design Water Flow Rate { m3 / s }",
            "   autosize,           !- Design Air Flow Rate { m3 / s }",
            "   autosize,           !- Design Inlet Water Temperature { C }",
            "   autosize,           !- Design Inlet Air Temperature { C }",
            "   autosize,           !- Design Outlet Air Temperature { C }",
            "   autosize,           !- Design Inlet Air Humidity Ratio { kgWater / kgDryAir }",
            "   autosize,           !- Design Outlet Air Humidity Ratio { kgWater / kgDryAir }",
            "   Water Inlet Node,   !- Water Inlet Node Name",
            "   Water Outlet Node,  !- Water Outlet Node Name",
            "   Air Inlet Node,     !- Air Inlet Node Name",
            "   Air Outlet Node,    !- Air Outlet Node Name",
            "   SimpleAnalysis,     !- Type of Analysis",
            "   CrossFlow;          !- Heat Exchanger Configuration",
            " Controller:WaterCoil,",
            "   CW Coil Controller, !- Name",
            "   HumidityRatio,      !- Control Variable",
            "   Reverse,            !- Action",
            "   FLOW,               !- Actuator Variable",
            "   Air Outlet Node,    !- Sensor Node Name",
            "   Water Inlet Node,   !- Actuator Node Name",
            "   ,                   !- Controller Convergence Tolerance { deltaC }",
            "   ,                   !- Maximum Actuated Flow { m3 / s }",
            "   ;                   !- Minimum Actuated Flow { m3 / s }",
            " SetpointManager:Scheduled,",
            "   HumRatSPManager,    !- Name",
            "   HumidityRatio,      !- Control Variable",
            "   HumRatioSched,      !- Schedule Name",
            "   Air Outlet Node;    !- Setpoint Node or NodeList Name",
            " Schedule:Compact,",
            "   HumRatioSched,      !- Name",
            "   Any Number,         !- Schedule Type Limits Name",
            "   Through: 12/31,     !- Field 1",
            "   For: AllDays,       !- Field 2",
            "   Until: 24:00, 0.015; !- Field 3",
            " Schedule:Compact,",
            "   AvailSched,         !- Name",
            "   Fraction,           !- Schedule Type Limits Name",
            "   Through: 12/31,     !- Field 1",
            "   For: AllDays,       !- Field 2",
            "   Until: 24:00, 1.0;  !- Field 3",
            " AirLoopHVAC:ControllerList,",
            "   CW Coil Controller, !- Name",
            "   Controller:WaterCoil, !- Controller 1 Object Type",
            "   CW Coil Controller; !- Controller 1 Name",
        ])
        AssertTrue(process_idf(idf_objects))
        state.init_state(state)
        GetSetPointManagerInputs(state)
        GetControllerInput(state)
        AssertEqual(state.dataHVACControllers.ControllerProps.size(), 1)
        AssertEqual(state.dataHVACControllers.ControllerProps[1].MaxVolFlowActuated, DataSizing.AutoSize)
        AssertEqual(state.dataHVACControllers.ControllerProps[1].Offset, DataSizing.AutoSize)
        AssertEqual(state.dataHVACControllers.ControllerProps[1].MinVolFlowActuated, 0.0)

@fixture
class HVACControllers_MaxFlowZero(EnergyPlusFixture):
    def TestBody(self):
        var idf_objects: String = DelimitedString([
            " Coil:Cooling:Water,",
            "   Chilled Water Coil, !- Name",
            "   AvailSched,         !- Availability Schedule Name",
            "   0.00,               !- Design Water Flow Rate { m3 / s }",
            "   1.0,                !- Design Air Flow Rate { m3 / s }",
            "   7.2,                !- Design Inlet Water Temperature { C }",
            "   32.0,               !- Design Inlet Air Temperature { C }",
            "   12.0,               !- Design Outlet Air Temperature { C }",
            "   0.01,               !- Design Inlet Air Humidity Ratio { kgWater / kgDryAir }",
            "   0.07,               !- Design Outlet Air Humidity Ratio { kgWater / kgDryAir }",
            "   Water Inlet Node,   !- Water Inlet Node Name",
            "   Water Outlet Node,  !- Water Outlet Node Name",
            "   Air Inlet Node,     !- Air Inlet Node Name",
            "   Air Outlet Node,    !- Air Outlet Node Name",
            "   SimpleAnalysis,     !- Type of Analysis",
            "   CrossFlow;          !- Heat Exchanger Configuration",
            " Controller:WaterCoil,",
            "   CW Coil Controller, !- Name",
            "   HumidityRatio,      !- Control Variable",
            "   Reverse,            !- Action",
            "   FLOW,               !- Actuator Variable",
            "   Air Outlet Node,    !- Sensor Node Name",
            "   Water Inlet Node,   !- Actuator Node Name",
            "   ,                   !- Controller Convergence Tolerance { deltaC }",
            "   ,                   !- Maximum Actuated Flow { m3 / s }",
            "   ;                   !- Minimum Actuated Flow { m3 / s }",
            " SetpointManager:Scheduled,",
            "   HumRatSPManager,    !- Name",
            "   MaximumHumidityRatio, !- Control Variable",
            "   HumRatioSched,      !- Schedule Name",
            "   Air Outlet Node;    !- Setpoint Node or NodeList Name",
            " Schedule:Compact,",
            "   HumRatioSched,      !- Name",
            "   Fraction,           !- Schedule Type Limits Name",
            "   Through: 12/31,     !- Field 1",
            "   For: AllDays,       !- Field 2",
            "   Until: 24:00, 0.015; !- Field 3",
            " Schedule:Compact,",
            "   AvailSched,         !- Name",
            "   Fraction,           !- Schedule Type Limits Name",
            "   Through: 12/31,     !- Field 1",
            "   For: AllDays,       !- Field 2",
            "   Until: 24:00, 1.0;  !- Field 3",
            " ScheduleTypeLimits,",
            "   Fraction,         !- Name",
            "   0.0,              !- Lower Limit Value",
            "   1.0,              !- Upper Limit Value",
            "   CONTINUOUS;       !- Numeric Type",
            " AirLoopHVAC:ControllerList,",
            "   CW Coil Controller, !- Name",
            "   Controller:WaterCoil, !- Controller 1 Object Type",
            "   CW Coil Controller; !- Controller 1 Name",
        ])
        AssertTrue(process_idf(idf_objects))
        state.init_state(state)
        GetSetPointManagerInputs(state)
        GetControllerInput(state)
        AssertEqual(state.dataHVACControllers.ControllerProps.size(), 1)
        AssertEqual(state.dataHVACControllers.ControllerProps[1].MaxVolFlowActuated, DataSizing.AutoSize)
        AssertEqual(state.dataHVACControllers.ControllerProps[1].Offset, DataSizing.AutoSize)
        AssertEqual(state.dataHVACControllers.ControllerProps[1].MinVolFlowActuated, 0.0)
        AssertEqual(0, state.dataHVACControllers.ControllerProps[1].AirLoopControllerIndex)
        state.dataSimAirServingZones.GetAirLoopInputFlag = False
        state.dataHVACGlobal.NumPrimaryAirSys = 1
        state.dataAirLoop.PriAirSysAvailMgr.allocate(1)
        state.dataAirLoop.AirLoopControlInfo.allocate(1)
        state.dataAirLoop.AirToZoneNodeInfo.allocate(1)
        state.dataAirLoop.AirToZoneNodeInfo[1].NumSupplyNodes = 1
        state.dataAirLoop.AirToZoneNodeInfo[1].AirLoopSupplyNodeNum.allocate(1)
        state.dataAirLoop.AirToZoneNodeInfo[1].AirLoopSupplyNodeNum[1] = 1
        state.dataAirLoop.AirToZoneNodeInfo[1].ZoneEquipSupplyNodeNum.allocate(1)
        state.dataAirLoop.AirToZoneNodeInfo[1].ZoneEquipSupplyNodeNum[1] = 4
        state.dataConvergeParams.AirLoopConvergence.allocate(1)
        state.dataAirSystemsData.PrimaryAirSystems.allocate(1)
        state.dataAirSystemsData.PrimaryAirSystems[1].NumBranches = 1
        state.dataAirSystemsData.PrimaryAirSystems[1].NumControllers = 1
        state.dataAirSystemsData.PrimaryAirSystems[1].ControllerIndex.allocate(1)
        state.dataAirSystemsData.PrimaryAirSystems[1].ControllerIndex[1] = 0
        state.dataAirSystemsData.PrimaryAirSystems[1].ControllerName.allocate(1)
        state.dataAirSystemsData.PrimaryAirSystems[1].ControllerName[1] = "CW COIL CONTROLLER"
        state.dataAirSystemsData.PrimaryAirSystems[1].ControlConverged.allocate(1)
        state.dataAirSystemsData.PrimaryAirSystems[1].Branch.allocate(1)
        state.dataAirSystemsData.PrimaryAirSystems[1].Branch[1].NodeNumIn = 4
        state.dataAirSystemsData.PrimaryAirSystems[1].Branch[1].NodeNumOut = 1
        state.dataAirSystemsData.PrimaryAirSystems[1].Branch[1].TotalNodes = 1
        state.dataAirSystemsData.PrimaryAirSystems[1].Branch[1].TotalComponents = 1
        state.dataAirSystemsData.PrimaryAirSystems[1].Branch[1].NodeNum.allocate(1)
        state.dataAirSystemsData.PrimaryAirSystems[1].Branch[1].NodeNum[1] = 1
        state.dataAirSystemsData.PrimaryAirSystems[1].Branch[1].Comp.allocate(1)
        state.dataAirSystemsData.PrimaryAirSystems[1].Branch[1].Comp[1].Name = "CHILLED WATER COIL"
        state.dataAirSystemsData.PrimaryAirSystems[1].Branch[1].Comp[1].CompType_Num = SimAirServingZones.CompType.WaterCoil_Cooling
        state.dataPlnt.PlantLoop.allocate(1)
        state.dataPlnt.TotNumLoops = 1
        state.dataPlnt.PlantLoop[1].Name = "CHW LOOP"
        state.dataPlnt.PlantLoop[1].PlantSizNum = 1
        state.dataPlnt.PlantLoop[1].FluidName = "WATER"
        state.dataPlnt.PlantLoop[1].glycol = Fluid.GetWater(state)
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].TotalBranches = 1
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch.allocate(1)
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].TotalComponents = 1
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp.allocate(1)
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].Type = DataPlant.PlantEquipmentType.CoilWaterCooling
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].NodeNumIn = 2
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].NodeNumOut = 3
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].Name = "CHILLED WATER COIL"
        state.dataSize.NumPltSizInput = 1
        state.dataSize.PlantSizData.allocate(1)
        state.dataSize.PlantSizData[1].DeltaT = 5.0
        state.dataSize.PlantSizData[1].ExitTemp = 6.0
        state.dataSize.PlantSizData[1].PlantLoopName = "CHW LOOP"
        state.dataSize.PlantSizData[1].LoopType = DataSizing.TypeOfPlantLoop.Cooling
        state.dataSize.PlantSizData[1].DesVolFlowRate = 1.0
        state.dataPlnt.PlantFirstSizesOkayToFinalize = True
        state.dataPlnt.PlantFirstSizesOkayToReport = True
        state.dataPlnt.PlantFinalSizesOkayToReport = True
        state.dataSize.UnitarySysEqSizing.allocate(1)
        state.dataSize.UnitarySysEqSizing[1].CoolingCapacity = False
        state.dataSize.UnitarySysEqSizing[1].HeatingCapacity = False
        state.dataSize.UnitarySysEqSizing.deallocate()
        var SimZoneEquipment: Bool = False
        SimAirServingZones.SimAirLoops(state, True, SimZoneEquipment)
        AssertEqual(1, state.dataAirSystemsData.PrimaryAirSystems[1].NumControllers)
        AssertEqual(1, state.dataAirSystemsData.PrimaryAirSystems[1].ControllerIndex[1])
        AssertEqual(1, state.dataHVACControllers.ControllerProps[1].AirLoopControllerIndex)
        AssertEqual(state.dataHVACControllers.ControllerProps[1].MaxVolFlowActuated, 0.0)
        AssertEqual(state.dataHVACControllers.ControllerProps[1].MinVolFlowActuated, 0.0)
        var expectedOffset: Float64 = (0.001 / (2100.0 * HVAC.SmallWaterVolFlow)) * (DataConvergParams.HVACEnergyToler / 10.0)
        expectedOffset = min(0.1 * DataConvergParams.HVACTemperatureToler, expectedOffset)
        AssertEqual(expectedOffset, 0.1 * DataConvergParams.HVACTemperatureToler)
        AssertEqual(state.dataHVACControllers.ControllerProps[1].Offset, expectedOffset)
        var error_string: String = DelimitedString([
            "   ** Warning ** InitController: Controller:WaterCoil=\"CW COIL CONTROLLER\", Maximum Actuated Flow is zero.",
        ])
        AssertTrue(compare_err_stream(error_string, True))