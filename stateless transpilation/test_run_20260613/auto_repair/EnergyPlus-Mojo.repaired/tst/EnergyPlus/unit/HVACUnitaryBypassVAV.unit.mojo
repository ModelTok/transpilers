from ......EnergyPlus.Psychrometrics import PsyRhoAirFnPbTdbW, PsyHFnTdbW
from ......EnergyPlus.CurveManager import AddCurve
from ......EnergyPlus.DXCoils import DXCoil as DXCoilType, DXCoilNumericFields, CheckEquipName, NumDXCoils, GetCoilsInputFlag, DXCoilFullLoadOutAirTemp, DXCoilFullLoadOutAirHumRat, DXCoilOutletTemp, DXCoilOutletHumRat, DXCoilPartLoadRatio, DXCoilFanOp
from ......EnergyPlus.DataAirLoop import AirLoopFlow, AirLoopControlInfo
from ......EnergyPlus.DataAirSystems import PrimaryAirSystems
from ......EnergyPlus.DataEnvironment import OutDryBulbTemp, OutHumRat, OutWetBulbTemp, OutBaroPress, StdBaroPress, StdRhoAir
from ......EnergyPlus.DataHVACGlobals import FanOp, CoilType, DefrostElecPower, DXElecCoolingPower, DXElecHeatingPower, ElecHeatingCoilPower, SuppHeatingCoilPower
from ......EnergyPlus.DataHeatBalance import Zone, HeatReclaimDXCoil, MassConservation
from ......EnergyPlus.DataLoopNode import Node, NodeID, NumOfNodes, FindItemInList
from ......EnergyPlus.DataSizing import AutoSize, FinalSysSizing, ZoneEqSizing, UnitarySysEqSizing, SysSizingRunDone, ZoneSizingRunDone, DesDayWeath, CurSysNum, CurZoneEqNum, CurOASysNum
from ......EnergyPlus.DataZoneEnergyDemands import ZoneSysEnergyDemand, CurDeadBandOrSetback, ZoneSysMoistureDemand
from ......EnergyPlus.DataZoneEquipment import ZoneEquipConfig, ZoneEquipList, ZoneEquipAvail, NumOfZoneEquipLists, ZoneEquipType, AirDistributionUnit
from ......EnergyPlus.Fans import fans
from ......EnergyPlus.HVACUnitaryBypassVAV import CBVAV, NumCBVAV, GetCBVAV, InitCBVAV, GetZoneLoads, ControlCBVAVOutput, CalcCBVAV, SimCBVAV, CoolingMode, HeatingMode, PriorityCtrlMode, AirFlowCtrlMode
from ......EnergyPlus.HeatBalanceManager import GetProjectControlData, GetHeatBalanceInput, AllocateHeatBalArrays
from ......EnergyPlus.HeatingCoils import HeatingCoil, HeatingCoilNumericFields, NumHeatingCoils, ValidSourceType, GetCoilsInputFlag as HeatingGetCoilsInputFlag
from ......EnergyPlus.IOFiles import IOFiles  # placeholder
from ......EnergyPlus.MixedAir import OAMixer
from ......EnergyPlus.OutputReportPredefined import ReportCoilSelection
from ......EnergyPlus.ScheduleManager import Sched, GetScheduleAlwaysOn
from ......EnergyPlus.SimAirServingZones import GetAirPathData, InitAirLoops
from ......EnergyPlus.SimulationManager import init_state
from ......EnergyPlus.SplitterComponent import GetSplitterInput
from ......EnergyPlus.VariableSpeedCoils import VarSpeedCoil
from ......EnergyPlus.ZoneAirLoopEquipmentManager import ZoneAirLoopEquipmentManager  # placeholder
from ......EnergyPlus.ZoneEquipmentManager import ManageZoneEquipment
from ......EnergyPlus.ZoneTempPredictorCorrector import InitZoneAirSetPoints
from ......EnergyPlus.DataGlobal import TimeStepZone, DayOfSim, HourOfDay, NumOfZones, SysSizingCalc, BeginEnvrnFlag
from ......EnergyPlus.Data.EnergyPlusData import EnergyPlusData, state
from ......EnergyPlus.Util import delimited_string  # or from "EnergyPlus/Utility"
from ......EnergyPlus.GlobalFixture import EnergyPlusFixture

# The test fixture class
class CBVAVSys:
    var cbvavNum: Int = 1
    var FirstHVACIteration: Bool = True
    var AirLoopNum: Int = 1
    var OnOffAirFlowRatio: Float64 = 1.0
    var HXUnitOn: Bool = True
    var NumNodes: Int = 1
    var ErrorsFound: Bool = False

    def SetUp(inout self):
        EnergyPlusFixture.SetUp(self)  # Sets up the base fixture first.
        state.init_state(state)
        state.dataGlobal.TimeStepZone = 0  # Why do we need to override this?  Why is it not okay to just set this?
        state.dataGlobal.DayOfSim = 1
        state.dataGlobal.HourOfDay = 1
        state.dataEnvrn.StdRhoAir = PsyRhoAirFnPbTdbW(state, 101325.0, 20.0, 0.0)  # initialize StdRhoAir
        state.dataEnvrn.OutBaroPress = 101325.0
        state.dataGlobal.NumOfZones = 1
        state.dataHeatBal.Zone.allocate(state.dataGlobal.NumOfZones)
        state.dataZoneEquip.ZoneEquipConfig.allocate(state.dataGlobal.NumOfZones)
        state.dataZoneEquip.ZoneEquipList.allocate(state.dataGlobal.NumOfZones)
        state.dataZoneEquip.ZoneEquipAvail.dimension(state.dataGlobal.NumOfZones, Avail.Status.NoAction)
        state.dataHeatBal.Zone[0].Name = "EAST ZONE"
        state.dataZoneEquip.NumOfZoneEquipLists = 1
        state.dataHeatBal.Zone[0].IsControlled = True
        state.dataZoneEquip.ZoneEquipConfig[0].IsControlled = True
        state.dataZoneEquip.ZoneEquipConfig[0].ZoneName = "EAST ZONE"
        state.dataZoneEquip.ZoneEquipConfig[0].EquipListName = "ZONEEQUIPMENT"
        state.dataZoneEquip.ZoneEquipConfig[0].ZoneNode = 20
        state.dataZoneEquip.ZoneEquipConfig[0].NumReturnNodes = 1
        state.dataZoneEquip.ZoneEquipConfig[0].ReturnNode.allocate(1)
        state.dataZoneEquip.ZoneEquipConfig[0].ReturnNode[0] = 21
        state.dataZoneEquip.ZoneEquipConfig[0].FixedReturnFlow.allocate(1)
        state.dataHeatBal.Zone[0].SystemZoneNodeNumber = state.dataZoneEquip.ZoneEquipConfig[0].ZoneNode
        state.dataZoneEquip.ZoneEquipConfig[0].returnFlowFracSched = GetScheduleAlwaysOn(state)
        state.dataZoneEquip.ZoneEquipList[0].Name = "ZONEEQUIPMENT"
        var maxEquipCount: Int = 1
        state.dataZoneEquip.ZoneEquipList[0].NumOfEquipTypes = maxEquipCount
        state.dataZoneEquip.ZoneEquipList[0].EquipTypeName.allocate(state.dataZoneEquip.ZoneEquipList[0].NumOfEquipTypes)
        state.dataZoneEquip.ZoneEquipList[0].EquipType.allocate(state.dataZoneEquip.ZoneEquipList[0].NumOfEquipTypes)
        state.dataZoneEquip.ZoneEquipList[0].EquipName.allocate(state.dataZoneEquip.ZoneEquipList[0].NumOfEquipTypes)
        state.dataZoneEquip.ZoneEquipList[0].EquipIndex.allocate(state.dataZoneEquip.ZoneEquipList[0].NumOfEquipTypes)
        state.dataZoneEquip.ZoneEquipList[0].EquipIndex = [1]
        state.dataZoneEquip.ZoneEquipList[0].EquipData.allocate(state.dataZoneEquip.ZoneEquipList[0].NumOfEquipTypes)
        state.dataZoneEquip.ZoneEquipList[0].CoolingPriority.allocate(state.dataZoneEquip.ZoneEquipList[0].NumOfEquipTypes)
        state.dataZoneEquip.ZoneEquipList[0].HeatingPriority.allocate(state.dataZoneEquip.ZoneEquipList[0].NumOfEquipTypes)
        state.dataZoneEquip.ZoneEquipList[0].EquipTypeName[0] = "ZONEHVAC:AIRDISTRIBUTIONUNIT"
        state.dataZoneEquip.ZoneEquipList[0].EquipName[0] = "ZONEREHEATTU"
        state.dataZoneEquip.ZoneEquipList[0].CoolingPriority[0] = 1
        state.dataZoneEquip.ZoneEquipList[0].HeatingPriority[0] = 1
        state.dataZoneEquip.ZoneEquipList[0].EquipType[0] = AirDistributionUnit
        state.dataZoneEquip.ZoneEquipConfig[0].NumInletNodes = NumNodes
        state.dataZoneEquip.ZoneEquipConfig[0].InletNode.allocate(NumNodes)
        state.dataZoneEquip.ZoneEquipConfig[0].AirDistUnitCool.allocate(NumNodes)
        state.dataZoneEquip.ZoneEquipConfig[0].AirDistUnitHeat.allocate(NumNodes)
        state.dataZoneEquip.ZoneEquipConfig[0].InletNode[0] = 2
        state.dataZoneEquip.ZoneEquipConfig[0].NumExhaustNodes = NumNodes
        state.dataZoneEquip.ZoneEquipConfig[0].ExhaustNode.allocate(NumNodes)
        state.dataZoneEquip.ZoneEquipConfig[0].ExhaustNode[0] = 1
        state.dataZoneEquip.ZoneEquipConfig[0].EquipListIndex = 1
        state.dataSize.CurSysNum = 1
        state.dataSize.CurZoneEqNum = 0
        state.dataSize.CurOASysNum = 0
        state.dataSize.FinalSysSizing.allocate(1)
        state.dataSize.FinalSysSizing[state.dataSize.CurSysNum - 1].DesMainVolFlow = 1.5
        state.dataSize.FinalSysSizing[state.dataSize.CurSysNum - 1].DesCoolVolFlow = 1.5
        state.dataSize.FinalSysSizing[state.dataSize.CurSysNum - 1].DesHeatVolFlow = 1.2
        state.dataSize.FinalSysSizing[state.dataSize.CurSysNum - 1].DesOutAirVolFlow = 0.3
        state.dataSize.FinalSysSizing[state.dataSize.CurSysNum - 1].MixTempAtCoolPeak = 25.0
        state.dataSize.FinalSysSizing[state.dataSize.CurSysNum - 1].MixHumRatAtCoolPeak = 0.009
        state.dataSize.FinalSysSizing[state.dataSize.CurSysNum - 1].CoolSupTemp = 15.0
        state.dataSize.FinalSysSizing[state.dataSize.CurSysNum - 1].CoolSupHumRat = 0.006
        state.dataSize.FinalSysSizing[state.dataSize.CurSysNum - 1].HeatSupTemp = 35.0
        state.dataSize.FinalSysSizing[state.dataSize.CurSysNum - 1].HeatRetTemp = 20.0
        state.dataSize.FinalSysSizing[state.dataSize.CurSysNum - 1].HeatRetHumRat = 0.007
        state.dataSize.FinalSysSizing[state.dataSize.CurSysNum - 1].HeatOutTemp = 10.0
        state.dataSize.FinalSysSizing[state.dataSize.CurSysNum - 1].HeatOutHumRat = 0.004
        state.dataSize.FinalSysSizing[state.dataSize.CurSysNum - 1].CoolDDNum = 1
        state.dataSize.DesDayWeath.allocate(1)
        state.dataSize.DesDayWeath[0].Temp.allocate(1)
        state.dataSize.DesDayWeath[0].Temp[0] = 35.0
        state.dataSize.ZoneEqSizing.allocate(1)
        state.dataSize.ZoneEqSizing[state.dataSize.CurSysNum - 1].SizingMethod.allocate(25)
        state.dataSize.ZoneSizingRunDone = True
        state.dataZoneEnergyDemand.ZoneSysEnergyDemand.allocate(1)
        state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].SequencedOutputRequiredToCoolingSp.allocate(1)
        state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].SequencedOutputRequiredToHeatingSp.allocate(1)
        state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].SequencedOutputRequiredToCoolingSp[0] = 0.0
        state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].SequencedOutputRequiredToHeatingSp[0] = 0.0
        state.dataZoneEnergyDemand.CurDeadBandOrSetback.allocate(1)
        state.dataZoneEnergyDemand.CurDeadBandOrSetback[0] = False
        state.dataLoopNodes.Node.allocate(50)
        state.dataHVACUnitaryBypassVAV.NumCBVAV = 1
        state.dataHVACUnitaryBypassVAV.CBVAV.allocate(1)
        var cbvav = state.dataHVACUnitaryBypassVAV.CBVAV[0]
        cbvav.Name = "CBVAVAirLoop"
        cbvav.UnitType = "AirLoopHVAC:UnitaryHeatCool:VAVChangeoverBypass"
        cbvav.availSched = GetScheduleAlwaysOn(state)
        cbvav.ControlledZoneNodeNum.allocate(1)
        cbvav.ControlledZoneNodeNum[0] = 1
        cbvav.DXCoolCoilIndexNum = 1
        state.dataDXCoils.DXCoil.allocate(1)
        state.dataDXCoils.DXCoilNumericFields.allocate(1)
        state.dataDXCoils.DXCoilNumericFields[0].PerfMode.allocate(1)
        state.dataDXCoils.DXCoilNumericFields[0].PerfMode[0].FieldNames.allocate(20)
        var dxCoil1 = state.dataDXCoils.DXCoil[0]
        dxCoil1.Name = "MyDXCoolCoil"
        dxCoil1.coilType = CoilType.CoolingDXSingleSpeed
        dxCoil1.coilReportNum = ReportCoilSelection.getReportIndex(state, dxCoil1.Name, dxCoil1.coilType)
        state.dataDXCoils.NumDXCoils = 1
        state.dataDXCoils.CheckEquipName.dimension(1, True)
        state.dataDXCoils.GetCoilsInputFlag = False
        dxCoil1.CCapFFlow.allocate(1)
        dxCoil1.CCapFFlow[0] = 1
        dxCoil1.CCapFTemp.allocate(1)
        dxCoil1.CCapFTemp[0] = 1
        dxCoil1.EIRFFlow.allocate(1)
        dxCoil1.EIRFFlow[0] = 1
        dxCoil1.EIRFTemp.allocate(1)
        dxCoil1.EIRFTemp[0] = 1
        dxCoil1.PLFFPLR.allocate(1)
        dxCoil1.PLFFPLR[0] = 1
        state.dataDXCoils.DXCoilFullLoadOutAirTemp.allocate(1)
        state.dataDXCoils.DXCoilFullLoadOutAirHumRat.allocate(1)
        dxCoil1.RatedAirVolFlowRate.allocate(1)
        dxCoil1.RatedAirVolFlowRate[0] = 0.5
        dxCoil1.RatedTotCap.allocate(1)
        dxCoil1.RatedTotCap[0] = 10000.0
        dxCoil1.RatedCop[0] = 3.3333
        dxCoil1.RatedEIR.allocate(1)
        dxCoil1.RatedEIR[0] = 0.3
        dxCoil1.RatedSHR.allocate(1)
        dxCoil1.RatedSHR[0] = 0.7
        dxCoil1.availSched = GetScheduleAlwaysOn(state)
        state.dataDXCoils.DXCoilOutletTemp.allocate(1)
        state.dataDXCoils.DXCoilOutletHumRat.allocate(1)
        state.dataDXCoils.DXCoilPartLoadRatio.allocate(1)
        state.dataDXCoils.DXCoilFanOp.allocate(1)
        state.dataHeatBal.HeatReclaimDXCoil.allocate(1)
        cbvav.DXCoolCoilName = "MyDXCoolCoil"
        dxCoil1.coilType = CoilType.CoolingDXSingleSpeed
        dxCoil1.coilReportNum = ReportCoilSelection.getReportIndex(state, dxCoil1.Name, dxCoil1.coilType)
        state.dataHeatingCoils.HeatingCoil.allocate(1)
        state.dataHeatingCoils.HeatingCoilNumericFields.allocate(1)
        state.dataHeatingCoils.HeatingCoilNumericFields[0].FieldNames.allocate(20)
        var heatingCoil1 = state.dataHeatingCoils.HeatingCoil[0]
        heatingCoil1.Name = "MyHeatingCoil"
        heatingCoil1.coilType = CoilType.HeatingElectric
        heatingCoil1.coilReportNum = ReportCoilSelection.getReportIndex(state, heatingCoil1.Name, heatingCoil1.coilType)
        state.dataHeatingCoils.NumHeatingCoils = 1
        state.dataHeatingCoils.ValidSourceType.dimension(state.dataHeatingCoils.NumHeatingCoils, False)
        state.dataHeatingCoils.GetCoilsInputFlag = False
        state.dataSize.UnitarySysEqSizing.allocate(1)
        cbvav.HeatCoilName = "MyHeatingCoil"
        cbvav.coolCoilType = CoilType.CoolingDXSingleSpeed
        cbvav.heatCoilType = CoilType.HeatingElectric
        cbvav.minModeChangeTime = 0.0
        cbvav.AirInNode = 1
        cbvav.AirOutNode = 2
        cbvav.MixerOutsideAirNode = 3
        cbvav.MixerReliefAirNode = 4
        cbvav.MixerMixedAirNode = 5
        cbvav.MixerInletAirNode = 6
        cbvav.HeatingCoilOutletNode = 9
        cbvav.SplitterOutletAirNode = 9
        cbvav.NumControlledZones = 1
        cbvav.ControlledZoneNum.allocate(1)
        cbvav.ControlledZoneNum = [1]
        cbvav.MinLATCooling = 7.0
        cbvav.MaxLATHeating = 40.0
        cbvav.ZoneSequenceCoolingNum.allocate(1)
        cbvav.ZoneSequenceHeatingNum.allocate(1)
        cbvav.ZoneSequenceCoolingNum = [1]
        cbvav.ZoneSequenceHeatingNum = [1]
        cbvav.OAMixName = "MyOAMixer"
        state.dataMixedAir.OAMixer.allocate(1)
        state.dataMixedAir.OAMixer[0].Name = "MyOAMixer"
        state.dataMixedAir.OAMixer[0].InletNode = 3
        state.dataMixedAir.OAMixer[0].RelNode = 4
        state.dataMixedAir.OAMixer[0].RetNode = 6
        state.dataMixedAir.OAMixer[0].MixNode = 7
        dxCoil1.AirInNode = 7
        cbvav.DXCoilInletNode = dxCoil1.AirInNode
        dxCoil1.AirOutNode = 8
        cbvav.DXCoilOutletNode = dxCoil1.AirOutNode
        heatingCoil1.AirInletNodeNum = 8
        cbvav.HeatingCoilInletNode = heatingCoil1.AirInletNodeNum
        heatingCoil1.AirOutletNodeNum = 9
        heatingCoil1.TempSetPointNodeNum = 9
        cbvav.HeatingCoilOutletNode = heatingCoil1.AirOutletNodeNum
        heatingCoil1.NominalCapacity = 10000.0
        heatingCoil1.Efficiency = 1.0
        heatingCoil1.availSched = GetScheduleAlwaysOn(state)
        cbvav.CBVAVBoxOutletNode.allocate(1)
        cbvav.CBVAVBoxOutletNode[0] = 11
        var curve1 = AddCurve(state, "Curve1")
        curve1.curveType = Curve.CurveType.Linear
        curve1.coeff[0] = 1.0
        state.dataEnvrn.OutDryBulbTemp = 35.0
        state.dataEnvrn.OutHumRat = 0.0141066
        state.dataEnvrn.OutWetBulbTemp = 23.9
        state.dataEnvrn.OutBaroPress = 101325.0
        state.dataAirLoop.AirLoopFlow.allocate(1)
        state.dataAirSystemsData.PrimaryAirSystems.allocate(1)
        state.dataAirLoop.AirLoopControlInfo.allocate(1)

    def TearDown(inout self):
        EnergyPlusFixture.TearDown(self)  # Remember to tear down the base fixture after cleaning up derived fixture!

# Test function: UnitaryBypassVAV_GetInputZoneEquipment
def test_UnitaryBypassVAV_GetInputZoneEquipment():
    # Create fixture instance (EnergyPlusFixture)
    var fixture = EnergyPlusFixture()
    fixture.SetUp()
    var idf_objects = delimited_string([
        "Zone,",
        "  Zone 2;                                 !- Name",
        "Zone,",
        "  Zone 1;                                 !- Name",
        "BuildingSurface:Detailed,",
        "  Surface_1,               !- Name",
        "  WALL,                    !- Surface Type",
        "  EXTWALL80,               !- Construction Name",
        "  Zone 1,                  !- Zone Name",
        "    ,                        !- Space Name",
        "  Outdoors,                !- Outside Boundary Condition",
        "  ,                        !- Outside Boundary Condition Object",
        "  SunExposed,              !- Sun Exposure",
        "  WindExposed,             !- Wind Exposure",
        "  0.5000000,               !- View Factor to Ground",
        "  4,                       !- Number of Vertices",
        "  0,6.096000,3.048000,     !- X,Y,Z ==> Vertex 1 {m}",
        "  0,6.096000,0,            !- X,Y,Z ==> Vertex 2 {m}",
        "  0,0,0,                   !- X,Y,Z ==> Vertex 3 {m}",
        "  0,0,3.048000;            !- X,Y,Z ==> Vertex 4 {m}",
        "BuildingSurface:Detailed,",
        "  Surface_2,               !- Name",
        "  WALL,                    !- Surface Type",
        "  EXTWALL80,               !- Construction Name",
        "  Zone 2,                  !- Zone Name",
        "    ,                        !- Space Name",
        "  Outdoors,                !- Outside Boundary Condition",
        "  ,                        !- Outside Boundary Condition Object",
        "  SunExposed,              !- Sun Exposure",
        "  WindExposed,             !- Wind Exposure",
        "  0.5000000,               !- View Factor to Ground",
        "  4,                       !- Number of Vertices",
        "  0,6.096000,3.048000,     !- X,Y,Z ==> Vertex 1 {m}",
        "  0,6.096000,0,            !- X,Y,Z ==> Vertex 2 {m}",
        "  0,0,0,                   !- X,Y,Z ==> Vertex 3 {m}",
        "  0,0,3.048000;            !- X,Y,Z ==> Vertex 4 {m}",
        "Construction,",
        "  EXTWALL80,               !- Name",
        "  C10 - 8 IN HW CONCRETE;        !- Outside Layer",
        "Material,",
        "  C10 - 8 IN HW CONCRETE,  !- Name",
        "  MediumRough,             !- Roughness",
        "  0.2033016,               !- Thickness {m}",
        "  1.729577,                !- Conductivity {W/m-K}",
        "  2242.585,                !- Density {kg/m3}",
        "  836.8000,                !- Specific Heat {J/kg-K}",
        "  0.9000000,               !- Thermal Absorptance",
        "  0.6500000,               !- Solar Absorptance",
        "  0.6500000;               !- Visible Absorptance",
        "  ZoneControl:Thermostat,",
        "    Zone Thermostat,         !- Name",
        "    Zone 1,           !- Zone or ZoneList Name",
        "    Dual Zone Control Type Sched,  !- Control Type Schedule Name",
        "    ThermostatSetpoint:DualSetpoint,  !- Control 1 Object Type",
        "    Setpoints;               !- Control 1 Name",
        "  ThermostatSetpoint:DualSetpoint,",
        "    Setpoints,               !- Name",
        "    Dual Heating Setpoints,  !- Heating Setpoint Temperature Schedule Name",
        "    Dual Cooling Setpoints;  !- Cooling Setpoint Temperature Schedule Name",
        "  Schedule:Compact,",
        "    Dual Heating Setpoints,  !- Name",
        "    Temperature,             !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00,            !- Field 3",
        "    23.0;                    !- Field 4",
        "  Schedule:Compact,",
        "    Dual Cooling Setpoints,  !- Name",
        "    Temperature,             !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00,            !- Field 3",
        "    23.0;                    !- Field 4",
        "  Schedule:Compact,",
        "    Dual Zone Control Type Sched,  !- Name",
        "    Control Type,            !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00,            !- Field 3",
        "    4;                       !- Field 4",
        "ZoneHVAC:EquipmentConnections,",
        "  Zone 1,                                 !- Zone Name",
        "  Zone 1 Equipment List,                  !- Zone Conditioning Equipment List Name",
        "  Zone 1 Inlet Node List,                 !- Zone Air Inlet Node or NodeList Name",
        "  ,                                       !- Zone Air Exhaust Node or NodeList Name",
        "  Zone 1 Zone Air Node,                   !- Zone Air Node Name",
        "  Zone 1 Zone Return Air Node;            !- Zone Return Air Node or NodeList Name",
        "NodeList,",
        "  Zone 1 Inlet Node List,                 !- Name",
        "  Zone 1 Dummy Inlet Node,",
        "  Zone 1 ATU VAVHeatAndCoolNoReheat Outlet Node; !- Node Name 1",
        "ZoneHVAC:AirDistributionUnit,",
        "  ADU Zone 1 ATU VAVHeatAndCoolNoReheat,  !- Name",
        "  Zone 1 ATU VAVHeatAndCoolNoReheat Outlet Node, !- Air Distribution Unit Outlet Node Name",
        "  AirTerminal:SingleDuct:VAV:HeatAndCool:NoReheat, !- Air Terminal Object Type",
        "  Zone 1 ATU VAVHeatAndCoolNoReheat;      !- Air Terminal Name",
        "AirTerminal:SingleDuct:VAV:HeatAndCool:NoReheat,",
        "  Zone 1 ATU VAVHeatAndCoolNoReheat,      !- Name",
        "  ,                                       !- Availability Schedule Name",
        "  Zone 1 ATU VAVHeatAndCoolNoReheat Outlet Node, !- Air Outlet Node Name",
        "  Zone 1 ATU VAVHeatAndCoolNoReheat Inlet Node, !- Air Inlet Node Name",
        "  0.02,                               !- Maximum Air Flow Rate {m3/s}",
        "  0;                                      !- Zone Minimum Air Flow Fraction",
        "ZoneHVAC:EquipmentList,",
        "  Zone 1 Equipment List,                  !- Name",
        "  ,                                       !- Load Distribution Scheme",
        "  ZoneHVAC:AirDistributionUnit,           !- Zone Equipment Object Type 1",
        "  ADU Zone 1 ATU VAVHeatAndCoolNoReheat,  !- Zone Equipment Name 1",
        "  1,                                      !- Zone Equipment Cooling Sequence 1",
        "  1;                                      !- Zone Equipment Heating or No-Load Sequence 1",
        "OutdoorAir:Node,",
        "  Model Outdoor Air Node;                 !- Name",
        "AirLoopHVAC,",
        "  UnitaryHeatCoolVAVChangeoverBypass Loop, !- Name",
        "  ,                                       !- Controller List Name",
        "  , !- Availability Manager List Name",
        "  0.02,                               !- Design Supply Air Flow Rate {m3/s}",
        "  UnitaryHeatCoolVAVChangeoverBypass Loop Supply Branches, !- Branch List Name",
        "  ,                                       !- Connector List Name",
        "  UnitaryHeatCoolVAVChangeoverBypass Loop Supply Inlet Node, !- Supply Side Inlet Node Name",
        "  UnitaryHeatCoolVAVChangeoverBypass Loop Demand Outlet Node, !- Demand Side Outlet Node Name",
        "  UnitaryHeatCoolVAVChangeoverBypass Loop Demand Inlet Nodes, !- Demand Side Inlet Node Names",
        "  UnitaryHeatCoolVAVChangeoverBypass Loop Supply Outlet Nodes; !- Supply Side Outlet Node Names",
        "NodeList,",
        "  UnitaryHeatCoolVAVChangeoverBypass Loop Supply Outlet Nodes, !- Name",
        "  UnitaryHeatCoolVAVChangeoverBypass Loop Supply Outlet Node; !- Node Name 1",
        "NodeList,",
        "  UnitaryHeatCoolVAVChangeoverBypass Loop Demand Inlet Nodes, !- Name",
        "  UnitaryHeatCoolVAVChangeoverBypass Loop Demand Inlet Node; !- Node Name 1",
        "BranchList,",
        "  UnitaryHeatCoolVAVChangeoverBypass Loop Supply Branches, !- Name",
        "  UnitaryHeatCoolVAVChangeoverBypass Loop Main Branch; !- Branch Name 1",
        "Branch,",
        "  UnitaryHeatCoolVAVChangeoverBypass Loop Main Branch, !- Name",
        "  ,                                       !- Pressure Drop Curve Name",
        "  AirLoopHVAC:UnitaryHeatCool:VAVChangeoverBypass, !- Component Object Type 1",
        "  Air Loop HVAC Unitary Heat Cool VAVChangeover Bypass 1, !- Component Name 1",
        "  UnitaryHeatCoolVAVChangeoverBypass Loop Supply Inlet Node, !- Component Inlet Node Name 1",
        "  UnitaryHeatCoolVAVChangeoverBypass Loop Supply Outlet Node; !- Component Outlet Node Name 1",
        "AirLoopHVAC:UnitaryHeatCool:VAVChangeoverBypass,",
        "  Air Loop HVAC Unitary Heat Cool VAVChangeover Bypass 1, !- Name",
        "  ,                                       !- Availability Schedule Name",
        "  0.021,                               !- Cooling Supply Air Flow Rate {m3/s}",
        "  0.022,                               !- Heating Supply Air Flow Rate {m3/s}",
        "  0.023,                               !- No Load Supply Air Flow Rate {m3/s}",
        "  0.011,                               !- Cooling Outdoor Air Flow Rate {m3/s}",
        "  0.012,                               !- Heating Outdoor Air Flow Rate {m3/s}",
        "  0.013,                               !- No Load Outdoor Air Flow Rate {m3/s}",
        "  ,                                       !- Outdoor Air Flow Rate Multiplier Schedule Name",
        "  UnitaryHeatCoolVAVChangeoverBypass Loop Supply Inlet Node, !- Air Inlet Node Name",
        "  Air Loop HVAC Unitary Heat Cool VAVChangeover Bypass 1 Bypass Duct Mixer Node, !- Bypass Duct Mixer Node Name",
        "  Air Loop HVAC Unitary Heat Cool VAVChangeover Bypass 1 Bypass Duct Splitter Node, !- Bypass Duct Splitter Node Name",
        "  UnitaryHeatCoolVAVChangeoverBypass Loop Supply Outlet Node, !- Air Outlet Node Name",
        "  OutdoorAir:Mixer,                       !- Outdoor Air Mixer Object Type",
        "  Air Loop HVAC Unitary Heat Cool VAVChangeover Bypass 1 Outdoor Air Mixer, !- Outdoor Air Mixer Name",
        "  Fan:ConstantVolume,                     !- Supply Air Fan Object Type",
        "  Fan Constant Volume 1,                  !- Supply Air Fan Name",
        "  DrawThrough,                            !- Supply Air Fan Placement",
        "  ,                                       !- Supply Air Fan Operating Mode Schedule Name",
        "  Coil:Cooling:DX:SingleSpeed,            !- Cooling Coil Object Type",
        "  Coil Cooling DX Single Speed 1,         !- Cooling Coil Name",
        "  Coil:Heating:Fuel,                      !- Heating Coil Object Type",
        "  Coil Heating Gas 1,                     !- Heating Coil Name",
        "  ZonePriority,                           !- Priority Control Mode",
        "  8,                                      !- Minimum Outlet Air Temperature During Cooling Operation {C}",
        "  50,                                     !- Maximum Outlet Air Temperature During Heating Operation {C}",
        "  None;                                   !- Dehumidification Control Type",
        "Fan:ConstantVolume,",
        "  Fan Constant Volume 1,                  !- Name",
        "  ,                                       !- Availability Schedule Name",
        "  0.7,                                    !- Fan Total Efficiency",
        "  250,                                    !- Pressure Rise {Pa}",
        "  0.023,                               !- Maximum Flow Rate {m3/s}",
        "  0.9,                                    !- Motor Efficiency",
        "  1,                                      !- Motor In Airstream Fraction",
        "  Air Loop HVAC Unitary Heat Cool VAVChangeover Bypass 1 Heating Coil Outlet Node, !- Air Inlet Node Name",
        "  Air Loop HVAC Unitary Heat Cool VAVChangeover Bypass 1 Bypass Duct Splitter Node; !- Air Outlet Node Name",
        "Coil:Heating:Fuel,",
        "  Coil Heating Gas 1,                     !- Name",
        "  ,                                       !- Availability Schedule Name",
        "  NaturalGas,                             !- Fuel Type",
        "  0.8,                                    !- Burner Efficiency",
        "  1000.0,                               !- Nominal Capacity {W}",
        "  Air Loop HVAC Unitary Heat Cool VAVChangeover Bypass 1 Cooling Coil Outlet Node, !- Air Inlet Node Name",
        "  Air Loop HVAC Unitary Heat Cool VAVChangeover Bypass 1 Heating Coil Outlet Node, !- Air Outlet Node Name",
        "  ,                                       !- Temperature Setpoint Node Name",
        "  0,                                      !- On Cycle Parasitic Electric Load {W}",
        "  ,                                       !- Part Load Fraction Correlation Curve Name",
        "  0;                                      !- Off Cycle Parasitic Fuel Load {W}",
        "Curve:Biquadratic,",
        "  Curve Biquadratic 1,                    !- Name",
        "  0.942587793,                            !- Coefficient1 Constant",
        "  0.009543347,                            !- Coefficient2 x",
        "  0.00068377,                             !- Coefficient3 x**2",
        "  -0.011042676,                           !- Coefficient4 y",
        "  5.249e-06,                              !- Coefficient5 y**2",
        "  -9.72e-06,                              !- Coefficient6 x*y",
        "  17,                                     !- Minimum Value of x {BasedOnField A2}",
        "  22,                                     !- Maximum Value of x {BasedOnField A2}",
        "  13,                                     !- Minimum Value of y {BasedOnField A3}",
        "  46;                                     !- Maximum Value of y {BasedOnField A3}",
        "Curve:Quadratic,",
        "  Curve Quadratic 1,                      !- Name",
        "  0.8,                                    !- Coefficient1 Constant",
        "  0.2,                                    !- Coefficient2 x",
        "  0,                                      !- Coefficient3 x**2",
        "  0.5,                                    !- Minimum Value of x {BasedOnField A2}",
        "  1.5;                                    !- Maximum Value of x {BasedOnField A2}",
        "Curve:Biquadratic,",
        "  Curve Biquadratic 2,                    !- Name",
        "  0.342414409,                            !- Coefficient1 Constant",
        "  0.034885008,                            !- Coefficient2 x",
        "  -0.0006237,                             !- Coefficient3 x**2",
        "  0.004977216,                            !- Coefficient4 y",
        "  0.000437951,                            !- Coefficient5 y**2",
        "  -0.000728028,                           !- Coefficient6 x*y",
        "  17,                                     !- Minimum Value of x {BasedOnField A2}",
        "  22,                                     !- Maximum Value of x {BasedOnField A2}",
        "  13,                                     !- Minimum Value of y {BasedOnField A3}",
        "  46;                                     !- Maximum Value of y {BasedOnField A3}",
        "Curve:Quadratic,",
        "  Curve Quadratic 2,                      !- Name",
        "  1.1552,                                 !- Coefficient1 Constant",
        "  -0.1808,                                !- Coefficient2 x",
        "  0.0256,                                 !- Coefficient3 x**2",
        "  0.5,                                    !- Minimum Value of x {BasedOnField A2}",
        "  1.5;                                    !- Maximum Value of x {BasedOnField A2}",
        "Curve:Quadratic,",
        "  Curve Quadratic 3,                      !- Name",
        "  0.85,                                   !- Coefficient1 Constant",
        "  0.15,                                   !- Coefficient2 x",
        "  0,                                      !- Coefficient3 x**2",
        "  0,                                      !- Minimum Value of x {BasedOnField A2}",
        "  1;                                      !- Maximum Value of x {BasedOnField A2}",
        "Coil:Cooling:DX:SingleSpeed,",
        "  Coil Cooling DX Single Speed 1,         !- Name",
        "  ,                                       !- Availability Schedule Name",
        "  1000,                               !- Gross Rated Total Cooling Capacity {W}",
        "  0.7,                               !- Gross Rated Sensible Heat Ratio",
        "  3,                                      !- Gross Rated Cooling COP {W/W}",
        "  0.021,                               !- Rated Air Flow Rate {m3/s}",
        "  773.3,                                  !- 2017 Rated Evaporator Fan Power Per Volume Flow Rate {W/(m3/s)}",
        "  773.3,                                  !- 2023 Rated Evaporator Fan Power Per Volume Flow Rate {W/(m3/s)}", //??BPS:TBD
        "  Air Loop HVAC Unitary Heat Cool VAVChangeover Bypass 1 Mixed Air Node, !- Air Inlet Node Name",
        "  Air Loop HVAC Unitary Heat Cool VAVChangeover Bypass 1 Cooling Coil Outlet Node, !- Air Outlet Node Name",
        "  Curve Biquadratic 1,                    !- Total Cooling Capacity Function of Temperature Curve Name",
        "  Curve Quadratic 1,                      !- Total Cooling Capacity Function of Flow Fraction Curve Name",
        "  Curve Biquadratic 2,                    !- Energy Input Ratio Function of Temperature Curve Name",
        "  Curve Quadratic 2,                      !- Energy Input Ratio Function of Flow Fraction Curve Name",
        "  Curve Quadratic 3,                      !- Part Load Fraction Correlation Curve Name",
        "  ,                                       !- Minimum Outdoor Dry-Bulb Temperature for Compressor Operation {C}",
        "  ,                                       !- Nominal Time for Condensate Removal to Begin {s}",
        "  ,                                       !- Ratio of Initial Moisture Evaporation Rate and Steady State Latent Capacity {dimensionless}",
        "  ,                                       !- Maximum Cycling Rate {cycles/hr}",
        "  ,                                       !- Latent Capacity Time Constant {s}",
        "  ,                                       !- Condenser Air Inlet Node Name",
        "  EvaporativelyCooled,                    !- Condenser Type",
        "  0,                                      !- Evaporative Condenser Effectiveness {dimensionless}",
        "  Autosize,                               !- Evaporative Condenser Air Flow Rate {m3/s}",
        "  Autosize,                               !- Evaporative Condenser Pump Rated Power Consumption {W}",
        "  0,                                      !- Crankcase Heater Capacity {W}",
        "  ,                                       !- Crankcase Heater Capacity Function of Temperature Curve Name",
        "  0,                                      !- Maximum Outdoor Dry-Bulb Temperature for Crankcase Heater Operation {C}",
        "  ,                                       !- Supply Water Storage Tank Name",
        "  ,                                       !- Condensate Collection Water Storage Tank Name",
        "  0,                                      !- Basin Heater Capacity {W/K}",
        "  10;                                     !- Basin Heater Setpoint Temperature {C}",
        "OutdoorAir:Mixer,",
        "  Air Loop HVAC Unitary Heat Cool VAVChangeover Bypass 1 Outdoor Air Mixer, !- Name",
        "  Air Loop HVAC Unitary Heat Cool VAVChangeover Bypass 1 Mixed Air Node, !- Mixed Air Node Name",
        "  Air Loop HVAC Unitary Heat Cool VAVChangeover Bypass 1 OA Node, !- Outdoor Air Stream Node Name",
        "  Air Loop HVAC Unitary Heat Cool VAVChangeover Bypass 1 Relief Air Node, !- Relief Air Stream Node Name",
        "  Air Loop HVAC Unitary Heat Cool VAVChangeover Bypass 1 Bypass Duct Mixer Node; !- Return Air Stream Node Name",
        "OutdoorAir:NodeList,",
        "  Air Loop HVAC Unitary Heat Cool VAVChangeover Bypass 1 OA Node; !- Node or NodeList Name 1",
        "AirLoopHVAC:SupplyPath,",
        "  UnitaryHeatCoolVAVChangeoverBypass Loop UnitaryHeatCoolVAVChangeoverBypass Loop Demand Inlet Node Supply Path, !- Name",
        "  UnitaryHeatCoolVAVChangeoverBypass Loop Demand Inlet Node, !- Supply Air Path Inlet Node Name",
        "  AirLoopHVAC:ZoneSplitter,               !- Component Object Type 1",
        "  UnitaryHeatCoolVAVChangeoverBypass Loop Demand Splitter; !- Component Name 1",
        "AirLoopHVAC:ZoneSplitter,",
        "  UnitaryHeatCoolVAVChangeoverBypass Loop Demand Splitter, !- Name",
        "  UnitaryHeatCoolVAVChangeoverBypass Loop Demand Inlet Node, !- Inlet Node Name",
        "  Zone 1 ATU VAVHeatAndCoolNoReheat Inlet Node; !- Outlet Node Name 1",
        "AirLoopHVAC:ReturnPath,",
        "  UnitaryHeatCoolVAVChangeoverBypass Loop Return Path, !- Name",
        "  UnitaryHeatCoolVAVChangeoverBypass Loop Demand Outlet Node, !- Return Air Path Outlet Node Name",
        "  AirLoopHVAC:ZoneMixer,                  !- Component Object Type 1",
        "  UnitaryHeatCoolVAVChangeoverBypass Loop Demand Mixer; !- Component Name 1",
        "AirLoopHVAC:ZoneMixer,",
        "  UnitaryHeatCoolVAVChangeoverBypass Loop Demand Mixer, !- Name",
        "  UnitaryHeatCoolVAVChangeoverBypass Loop Demand Outlet Node, !- Outlet Node Name",
        "  Zone 1 Zone Return Air Node;            !- Inlet Node Name 1",
    ])
    process_idf(idf_objects)  # assume process_idf is imported
    state.init_state(state)
    var ErrorsFound: Bool = False
    var firstHVACIteration: Bool = True
    GetProjectControlData(state, ErrorsFound)
    expect(not ErrorsFound)
    GetHeatBalanceInput(state)
    AllocateHeatBalArrays(state)
    InitZoneAirSetPoints(state)
    var simZone: Bool = False
    var simAir: Bool = False
    state.dataHeatBal.MassConservation.allocate(state.dataGlobal.NumOfZones)
    ManageZoneEquipment(state, firstHVACIteration, simZone, simAir)
    GetAirPathData(state)
    GetSplitterInput(state)
    InitAirLoops(state, firstHVACIteration)
    state.dataZoneEnergyDemand.CurDeadBandOrSetback.allocate(2)
    state.dataZoneEnergyDemand.CurDeadBandOrSetback[0] = True
    state.dataZoneEnergyDemand.CurDeadBandOrSetback[1] = False
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand.allocate(2)
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].SequencedOutputRequiredToCoolingSp.allocate(1)
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].SequencedOutputRequiredToHeatingSp.allocate(1)
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].SequencedOutputRequiredToCoolingSp[0] = 0.0
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].SequencedOutputRequiredToHeatingSp[0] = 0.0
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand[1].SequencedOutputRequiredToCoolingSp.allocate(1)
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand[1].SequencedOutputRequiredToHeatingSp.allocate(1)
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand[1].SequencedOutputRequiredToCoolingSp[0] = -1000.0
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand[1].SequencedOutputRequiredToHeatingSp[0] = -2000.0
    GetCBVAV(state)  # get UnitarySystem input from object above
    var CBVAVNum: Int = 1
    var zoneIndex: Int = 1
    var cbvav = state.dataHVACUnitaryBypassVAV.CBVAV[CBVAVNum - 1]
    expect(cbvav.ControlledZoneNum[CBVAVNum - 1] == 2)
    expect(cbvav.ZoneSequenceCoolingNum[cbvav.ZoneSequenceCoolingNum[zoneIndex - 1] - 1] == 1)
    expect(cbvav.ZoneSequenceHeatingNum[cbvav.ZoneSequenceHeatingNum[zoneIndex - 1] - 1] == 1)
    expect(cbvav.CoolOutAirVolFlow == 0.011)
    expect(cbvav.HeatOutAirVolFlow == 0.012)
    expect(cbvav.NoCoolHeatOutAirVolFlow == 0.013)
    expect(cbvav.MaxCoolAirVolFlow == 0.021)
    expect(cbvav.MaxHeatAirVolFlow == 0.022)
    expect(cbvav.MaxNoCoolHeatAirVolFlow == 0.023)
    expect(cbvav.FanVolFlow == 0.023)
    cbvav.changeOverTimer = -1.0  # reset timer so GetZoneLoads executes
    state.dataGlobal.DayOfSim = 1
    state.dataGlobal.HourOfDay = 1
    GetZoneLoads(state, CBVAVNum)
    expect(cbvav.NumZonesCooled == 1)
    expect(cbvav.HeatCoolMode == CoolingMode)
    fixture.TearDown()

# Test function: UnitaryBypassVAV_AutoSize
def test_UnitaryBypassVAV_AutoSize():
    var fixture = CBVAVSys()
    fixture.SetUp()
    var cbvav = state.dataHVACUnitaryBypassVAV.CBVAV[0]
    var finalSysSizing = state.dataSize.FinalSysSizing[state.dataSize.CurSysNum - 1]
    state.dataSize.SysSizingRunDone = True  # inform sizing that system sizing run is done
    cbvav.FanVolFlow = AutoSize
    cbvav.MaxCoolAirVolFlow = AutoSize
    cbvav.MaxHeatAirVolFlow = AutoSize
    cbvav.MaxNoCoolHeatAirVolFlow = AutoSize
    cbvav.CoolOutAirVolFlow = AutoSize
    cbvav.HeatOutAirVolFlow = AutoSize
    cbvav.NoCoolHeatOutAirVolFlow = AutoSize
    state.dataHeatingCoils.HeatingCoil[0].NominalCapacity = AutoSize
    state.dataDXCoils.DXCoil[0].RatedAirVolFlowRate[0] = AutoSize
    state.dataDXCoils.DXCoil[0].RatedTotCap[0] = AutoSize
    cbvav.fanOp = FanOp.Cycling  # must set one type of fan operating mode to initialize CalcSetPointTempTarget
    state.dataLoopNodes.Node[cbvav.AirInNode - 1].Temp = 24.0  # initialize inlet node temp used to initialize CalcSetPointTempTarget
    cbvav.AirLoopNumber = 1
    state.dataAirLoop.AirLoopFlow.allocate(cbvav.AirLoopNumber)
    InitCBVAV(state, fixture.cbvavNum, fixture.FirstHVACIteration, fixture.AirLoopNum, fixture.OnOffAirFlowRatio, fixture.HXUnitOn)
    expect(cbvav.MaxCoolAirVolFlow == finalSysSizing.DesMainVolFlow)
    expect(cbvav.MaxHeatAirVolFlow == finalSysSizing.DesMainVolFlow)
    expect(cbvav.MaxNoCoolHeatAirVolFlow == finalSysSizing.DesMainVolFlow)
    expect(cbvav.CoolOutAirVolFlow == finalSysSizing.DesOutAirVolFlow)
    expect(cbvav.HeatOutAirVolFlow == finalSysSizing.DesOutAirVolFlow)
    expect(cbvav.NoCoolHeatOutAirVolFlow == finalSysSizing.DesOutAirVolFlow)
    expect(state.dataDXCoils.DXCoil[0].RatedAirVolFlowRate[0] == finalSysSizing.DesMainVolFlow)
    expect(state.dataDXCoils.DXCoil[0].RatedTotCap[0] > 30000.0)
    expect(state.dataHeatingCoils.HeatingCoil[0].NominalCapacity > 45000.0)
    fixture.TearDown()

# Test function: UnitaryBypassVAV_NoOASys
def test_UnitaryBypassVAV_NoOASys():
    var fixture = CBVAVSys()
    fixture.SetUp()
    var cbvav = state.dataHVACUnitaryBypassVAV.CBVAV[0]
    cbvav.FanVolFlow = 0.5
    cbvav.MaxCoolAirVolFlow = 0.5
    cbvav.MaxHeatAirVolFlow = 0.5
    cbvav.MaxNoCoolHeatAirVolFlow = 0.0
    cbvav.CoolOutAirVolFlow = 0.0
    cbvav.HeatOutAirVolFlow = 0.0
    cbvav.NoCoolHeatOutAirVolFlow = 0.0
    state.dataLoopNodes.Node[cbvav.AirInNode - 1].Temp = 24.0  # sugartech.co.za using 24C db and 17 wb
    state.dataLoopNodes.Node[cbvav.AirInNode - 1].HumRat = 0.009222
    state.dataLoopNodes.Node[cbvav.AirInNode - 1].Enthalpy = 47591.3
    state.dataLoopNodes.Node[cbvav.AirInNode - 1].MassFlowRate = 0.57
    state.dataLoopNodes.Node[state.dataMixedAir.OAMixer[0].InletNode - 1].Temp = state.dataEnvrn.OutDryBulbTemp
    state.dataLoopNodes.Node[state.dataMixedAir.OAMixer[0].InletNode - 1].HumRat = state.dataEnvrn.OutHumRat
    state.dataLoopNodes.Node[state.dataMixedAir.OAMixer[0].InletNode - 1].Enthalpy = 71299.267
    state.dataLoopNodes.Node[cbvav.CBVAVBoxOutletNode[0] - 1].MassFlowRateMax = 0.61
    state.dataLoopNodes.Node[cbvav.CBVAVBoxOutletNode[0] - 1].MassFlowRate = 0.61
    cbvav.fanOp = FanOp.Cycling  # set fan operating mode
    cbvav.AirLoopNumber = 1
    state.dataAirLoop.AirLoopFlow.allocate(cbvav.AirLoopNumber)
    InitCBVAV(state, fixture.cbvavNum, fixture.FirstHVACIteration, fixture.AirLoopNum, fixture.OnOffAirFlowRatio, fixture.HXUnitOn)
    expect(cbvav.HeatCoolMode == 0)
    expect(cbvav.NumZonesCooled == 0)
    expect(cbvav.NumZonesHeated == 0)
    expect(state.dataLoopNodes.Node[cbvav.AirInNode - 1].Temp =~ state.dataLoopNodes.Node[cbvav.AirOutNode - 1].Temp with 0.0001)
    expect(state.dataLoopNodes.Node[cbvav.AirInNode - 1].HumRat =~ state.dataLoopNodes.Node[cbvav.AirOutNode - 1].HumRat with 0.000001)
    expect(state.dataLoopNodes.Node[cbvav.AirInNode - 1].Enthalpy =~ state.dataLoopNodes.Node[cbvav.AirOutNode - 1].Enthalpy with 0.1)
    expect(cbvav.changeOverTimer == -1.0)  # expect no change in timer, remains at default value
    cbvav.PriorityControl = PriorityCtrlMode.CoolingPriority
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].SequencedOutputRequiredToCoolingSp[0] = -9000.0  # load to cooling set point
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].SequencedOutputRequiredToHeatingSp[0] = -15000.0  # more load to heating set point
    InitCBVAV(state, fixture.cbvavNum, fixture.FirstHVACIteration, fixture.AirLoopNum, fixture.OnOffAirFlowRatio, fixture.HXUnitOn)
    expect(cbvav.changeOverTimer == 0.0)  # expect timer now set to current time (0.0) plus minModeChangeTime(0.0), so = 0.0
    expect(cbvav.HeatCoolMode == CoolingMode)
    expect(cbvav.NumZonesCooled == 1)
    expect(cbvav.NumZonesHeated == 0)
    expect(cbvav.OutletTempSetPoint >= cbvav.MinLATCooling)
    expect(cbvav.OutletTempSetPoint <= cbvav.MaxLATHeating)
    expect(cbvav.OutletTempSetPoint =~ 9.56 with 0.01)
    var PartLoadFrac: Float64 = 0.0
    ControlCBVAVOutput(state, fixture.cbvavNum, fixture.FirstHVACIteration, PartLoadFrac, fixture.OnOffAirFlowRatio, fixture.HXUnitOn)
    expect(PartLoadFrac == 1.0)  # load = -9000 W, coil capacity = 10,000 W, SHR = 0.7 so max sensible is around 7,000 W
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].SequencedOutputRequiredToCoolingSp[0] = -7000.0  # load to cooling set point
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].SequencedOutputRequiredToHeatingSp[0] = -15000.0  # more load to heating set point
    InitCBVAV(state, fixture.cbvavNum, fixture.FirstHVACIteration, fixture.AirLoopNum, fixture.OnOffAirFlowRatio, fixture.HXUnitOn)
    var FullOutput: Float64 = 0.0
    CalcCBVAV(state, fixture.cbvavNum, fixture.FirstHVACIteration, PartLoadFrac, FullOutput, fixture.OnOffAirFlowRatio, fixture.HXUnitOn)
    expect(PartLoadFrac =~ 0.9387 with 0.001)  # load = -7000 W, coil capacity = 10,000 W, SHR = 0.7 so max sensible is just over 7,000 W
    expect(cbvav.OutletTempSetPoint =~ state.dataLoopNodes.Node[cbvav.AirOutNode - 1].Temp with 0.0001)
    expect(cbvav.OutletTempSetPoint =~ 12.771 with 0.001)
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].SequencedOutputRequiredToCoolingSp[0] = 15000.0  # more load to cooling set point
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].SequencedOutputRequiredToHeatingSp[0] = 7000.0  # load to heating set point
    cbvav.changeOverTimer = -1.0  # The load switched to heating so reset timer so GetZoneLoads executes
    cbvav.minModeChangeTime = 2.0
    InitCBVAV(state, fixture.cbvavNum, fixture.FirstHVACIteration, fixture.AirLoopNum, fixture.OnOffAirFlowRatio, fixture.HXUnitOn)
    expect(cbvav.changeOverTimer == 2.0)  # expect timer now set to current time (0.0) plus minModeChangeTime(2.0), so = 2.0
    expect(cbvav.HeatCoolMode == HeatingMode)
    expect(cbvav.NumZonesCooled == 0)
    expect(cbvav.NumZonesHeated == 1)
    expect(cbvav.OutletTempSetPoint >= cbvav.MinLATCooling)
    expect(cbvav.OutletTempSetPoint <= cbvav.MaxLATHeating)
    expect(cbvav.OutletTempSetPoint =~ 35.23 with 0.01)
    FullOutput = 0.0
    CalcCBVAV(state, fixture.cbvavNum, fixture.FirstHVACIteration, PartLoadFrac, FullOutput, fixture.OnOffAirFlowRatio, fixture.HXUnitOn)
    expect(PartLoadFrac < 1.0)  # load = 7000 W, coil capacity = 10,000 W
    expect(cbvav.OutletTempSetPoint =~ state.dataLoopNodes.Node[cbvav.AirOutNode - 1].Temp with 0.0001)
    expect(cbvav.OutletTempSetPoint =~ 35.228 with 0.001)
    fixture.TearDown()

# Test function: UnitaryBypassVAV_InternalOAMixer
def test_UnitaryBypassVAV_InternalOAMixer():
    var fixture = CBVAVSys()
    fixture.SetUp()
    var cbvav = state.dataHVACUnitaryBypassVAV.CBVAV[0]
    cbvav.FanVolFlow = 0.5
    cbvav.MaxCoolAirVolFlow = 0.5
    cbvav.MaxHeatAirVolFlow = 0.5
    cbvav.MaxNoCoolHeatAirVolFlow = 0.0
    cbvav.CoolOutAirVolFlow = 0.1
    cbvav.HeatOutAirVolFlow = 0.1
    cbvav.NoCoolHeatOutAirVolFlow = 0.1
    state.dataLoopNodes.Node[cbvav.AirInNode - 1].Temp = 24.0  # sugartech.co.za using 24C db and 17 wb
    state.dataLoopNodes.Node[cbvav.AirInNode - 1].HumRat = 0.009222
    state.dataLoopNodes.Node[cbvav.AirInNode - 1].Enthalpy = 47591.3
    state.dataLoopNodes.Node[cbvav.AirInNode - 1].MassFlowRate = 0.57
    state.dataLoopNodes.Node[state.dataMixedAir.OAMixer[0].InletNode - 1].Temp = state.dataEnvrn.OutDryBulbTemp
    state.dataLoopNodes.Node[state.dataMixedAir.OAMixer[0].InletNode - 1].HumRat = state.dataEnvrn.OutHumRat
    state.dataLoopNodes.Node[state.dataMixedAir.OAMixer[0].InletNode - 1].Enthalpy = 71299.267
    state.dataLoopNodes.Node[cbvav.CBVAVBoxOutletNode[0] - 1].MassFlowRateMax = 0.61
    state.dataLoopNodes.Node[cbvav.CBVAVBoxOutletNode[0] - 1].MassFlowRate = 0.61
    cbvav.fanOp = FanOp.Cycling  # set fan operating mode
    cbvav.AirLoopNumber = 1
    state.dataAirLoop.AirLoopFlow.allocate(cbvav.AirLoopNumber)
    InitCBVAV(state, fixture.cbvavNum, fixture.FirstHVACIteration, fixture.AirLoopNum, fixture.OnOffAirFlowRatio, fixture.HXUnitOn)
    expect(cbvav.HeatCoolMode == 0)
    expect(cbvav.NumZonesCooled == 0)
    expect(cbvav.NumZonesHeated == 0)
    expect(state.dataLoopNodes.Node[cbvav.AirInNode - 1].Temp != state.dataLoopNodes.Node[cbvav.AirOutNode - 1].Temp)
    expect(state.dataLoopNodes.Node[cbvav.AirInNode - 1].HumRat != state.dataLoopNodes.Node[cbvav.AirOutNode - 1].HumRat)
    expect(state.dataLoopNodes.Node[cbvav.AirInNode - 1].Enthalpy != state.dataLoopNodes.Node[cbvav.AirOutNode - 1].Enthalpy)
    cbvav.PriorityControl = PriorityCtrlMode.CoolingPriority
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].SequencedOutputRequiredToCoolingSp[0] = -9000.0  # load to cooling set point
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].SequencedOutputRequiredToHeatingSp[0] = -15000.0  # more load to heating set point
    InitCBVAV(state, fixture.cbvavNum, fixture.FirstHVACIteration, fixture.AirLoopNum, fixture.OnOffAirFlowRatio, fixture.HXUnitOn)
    expect(cbvav.HeatCoolMode == CoolingMode)
    expect(cbvav.NumZonesCooled == 1)
    expect(cbvav.NumZonesHeated == 0)
    expect(cbvav.OutletTempSetPoint >= cbvav.MinLATCooling)
    expect(cbvav.OutletTempSetPoint <= cbvav.MaxLATHeating)
    expect(cbvav.OutletTempSetPoint =~ 9.59 with 0.01)
    var PartLoadFrac: Float64 = 0.0
    ControlCBVAVOutput(state, fixture.cbvavNum, fixture.FirstHVACIteration, PartLoadFrac, fixture.OnOffAirFlowRatio, fixture.HXUnitOn)
    expect(PartLoadFrac == 1.0)  # load = -9000 W, coil capacity = 10,000 W, SHR = 0.7 so max sensible is around 7,000 W
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].SequencedOutputRequiredToCoolingSp[0] = -6000.0  # load to cooling set point
    state.data