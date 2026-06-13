from gtest import Test, Expect, AssertTrue, AssertFalse
from EnergyPlus.ConfiguredFunctions import *
from EnergyPlus.Construction import *
from EnergyPlus.Data.EnergyPlusData import *
from EnergyPlus.DataAirLoop import *
from EnergyPlus.DataAirSystems import *
from EnergyPlus.DataEnvironment import *
from EnergyPlus.DataHVACGlobals import *
from EnergyPlus.DataHeatBalFanSys import *
from EnergyPlus.DataHeatBalSurface import *
from EnergyPlus.DataHeatBalance import *
from EnergyPlus.DataIPShortCuts import *
from EnergyPlus.DataLoopNode import *
from EnergyPlus.DataSurfaces import *
from EnergyPlus.DataZoneEquipment import *
from EnergyPlus.DaylightingManager import *
from EnergyPlus.General import *
from EnergyPlus.HVACSystemRootFindingAlgorithm import *
from EnergyPlus.HeatBalanceAirManager import *
from EnergyPlus.HeatBalanceManager import *
from EnergyPlus.HeatBalanceSurfaceManager import *
from EnergyPlus.IOFiles import *
from EnergyPlus.InputProcessing.InputProcessor import *
from EnergyPlus.Material import *
from EnergyPlus.OutAirNodeManager import *
from EnergyPlus.ScheduleManager import *
from EnergyPlus.SimulationManager import *
from EnergyPlus.SurfaceGeometry import *
from EnergyPlus.UtilityRoutines import *
from EnergyPlus.WeatherManager import *
from EnergyPlus.ZoneEquipmentManager import *
from EnergyPlus.ZoneTempPredictorCorrector import *
from nlohmann.json import *
from Fixtures.EnergyPlusFixture import EnergyPlusFixture, delimited_string, process_idf, compare_err_stream, compare_err_stream_substring

using EnergyPlus.HeatBalanceManager: *
using EnergyPlus.DataHeatBalance: *
using EnergyPlus.ZoneEquipmentManager: *
using EnergyPlus.HeatBalanceAirManager: *
using EnergyPlus.DataHeatBalFanSys: *
using EnergyPlus.DataZoneEquipment: *
using EnergyPlus.DataAirLoop: *
using EnergyPlus.DataAirSystems: *
using nlohmann.literals: *

def HeatBalanceManager_ZoneAirBalance_OutdoorAir(self: EnergyPlusFixture) raises:
    var idf_objects: String = delimited_string([
        "ZoneAirBalance:OutdoorAir,\n",
        "    LIVING ZONE Balance 1,   !- Name\n",
        "    LIVING ZONE,             !- Zone Name\n",
        "    Quadrature,              !- Air Balance Method\n",
        "    0.01,                    !- Induced Outdoor Air Due to Unbalanced Duct Leakage {m3/s}\n",
        "    INF-SCHED;               !- Induced Outdoor Air Schedule Name",
        "ZoneAirBalance:OutdoorAir,\n",
        "    LIVING ZONE Balance 2,   !- Name\n",
        "    LIVING ZONE,             !- Zone Name\n",
        "    Quadrature,              !- Air Balance Method\n",
        "    0.01,                    !- Induced Outdoor Air Due to Unbalanced Duct Leakage {m3/s}\n",
        "    INF-SCHED2;              !- Induced Outdoor Air Schedule Name",
        "Zone,",
        "LIVING ZONE,             !- Name",
        "0,                       !- Direction of Relative North {deg}",
        "0,                       !- X Origin {m}",
        "0,                       !- Y Origin {m}",
        "0,                       !- Z Origin {m}",
        "1,                       !- Type",
        "1,                       !- Multiplier",
        "autocalculate,           !- Ceiling Height {m}",
        "autocalculate;           !- Volume {m3}",
    ])
    AssertTrue(process_idf(idf_objects))
    self.state.init_state(self.state)
    var ErrorsFound: Bool = false
    var numZones: Int = self.state.dataInputProcessing.inputProcessor.getNumObjectsFound(self.state, "Zone")
    self.state.dataHeatBalFanSys.ZoneReOrder.allocate(numZones)
    GetZoneData(self.state, ErrorsFound)
    GetAirFlowFlag(self.state, ErrorsFound)
    ExpectTrue(ErrorsFound)

# ifdef GET_OUT
def HeatBalanceManager_WindowMaterial_Gap_Duplicate_Names(self: EnergyPlusFixture) raises:
    var idf_objects: String = delimited_string([
        "  WindowMaterial:Gap,",
        "    Gap_1_Layer,             !- Name",
        "    0.0127,                  !- Thickness {m}",
        "    Gas_1_W_0_0127,          !- Gas (or Gas Mixture)",
        "    101325.0000;             !- Pressure {Pa}",
        "  WindowGap:DeflectionState,",
        "    DeflectionState_813_Measured_Gap_1,  !- Name",
        "    0.0120;                  !- Deflected Thickness {m}",
        "  WindowMaterial:Gap,",
        "    Gap_6_Layer,             !- Name",
        "    0.0060,                  !- Thickness {m}",
        "    Gap_6_W_0_0060,          !- Gas (or Gas Mixture)",
        "    101300.0000,             !- Pressure {Pa}",
        "    DeflectionState_813_Measured_Gap_1;  !- Deflection State",
        "  WindowMaterial:Gap,",
        "    Gap_1_Layer,             !- Name",
        "    0.0100,                  !- Thickness {m}",
        "    Gas_1_W_0_0100,          !- Gas (or Gas Mixture)",
        "    101325.0000;             !- Pressure {Pa}",
    ])
    AssertFalse(process_idf(idf_objects, false))  # expect errors
    var error_string: String = delimited_string([
        "   ** Severe  ** Duplicate name found for object of type \"WindowMaterial:Gap\" named \"Gap_1_Layer\". Overwriting existing object.",
    ])
    ExpectTrue(compare_err_stream(error_string, true))
    var ErrorsFound: Bool = false
    Material.GetMaterialData(self.state, ErrorsFound)
    ExpectFalse(ErrorsFound)

def HeatBalanceManager_WindowMaterial_Gap_Duplicate_Names_2(self: EnergyPlusFixture) raises:
    var idf_objects: String = delimited_string([
        "  WindowGap:DeflectionState,",
        "    DeflectionState_813_Measured_Gap_1,  !- Name",
        "    0.0120;                  !- Deflected Thickness {m}",
        "  WindowMaterial:Gap,",
        "    Gap_6_Layer,             !- Name",
        "    0.0060,                  !- Thickness {m}",
        "    Gap_6_W_0_0060,          !- Gas (or Gas Mixture)",
        "    101300.0000,             !- Pressure {Pa}",
        "    DeflectionState_813_Measured_Gap_1;  !- Deflection State",
        "  WindowMaterial:Gap,",
        "    Gap_1_Layer,             !- Name",
        "    0.0127,                  !- Thickness {m}",
        "    Gas_1_W_0_0127,          !- Gas (or Gas Mixture)",
        "    101325.0000;             !- Pressure {Pa}",
        "  WindowMaterial:Gap,",
        "    Gap_1_Layer,             !- Name",
        "    0.0100,                  !- Thickness {m}",
        "    Gas_1_W_0_0100,          !- Gas (or Gas Mixture)",
        "    101325.0000;             !- Pressure {Pa}",
    ])
    AssertFalse(process_idf(idf_objects, false))  # expect errors
    var error_string: String = delimited_string([
        "   ** Severe  ** Duplicate name found for object of type \"WindowMaterial:Gap\" named \"Gap_1_Layer\". Overwriting existing object.",
    ])
    ExpectTrue(compare_err_stream(error_string, true))
    var ErrorsFound: Bool = false
    Material.GetMaterialData(self.state, ErrorsFound)
    ExpectFalse(ErrorsFound)
# #endif // GET_OUT

def HeatBalanceManager_ProcessZoneData(self: EnergyPlusFixture) raises:
    var ErrorsFound: Bool = false
    var ZoneNum: Int = 0
    var NumAlphas: Int = 2
    var NumNumbers: Int = 9
    self.state.dataIPShortCut.cCurrentModuleObject = "Zone"
    self.state.dataGlobal.NumOfZones = 2
    self.state.dataHeatBal.Zone.allocate(self.state.dataGlobal.NumOfZones)
    NumAlphas = 2
    NumNumbers = 9
    self.state.dataIPShortCut.lNumericFieldBlanks.allocate(NumNumbers)
    self.state.dataIPShortCut.lAlphaFieldBlanks.allocate(NumAlphas)
    self.state.dataIPShortCut.cAlphaFieldNames.allocate(NumAlphas)
    self.state.dataIPShortCut.cNumericFieldNames.allocate(NumNumbers)
    self.state.dataIPShortCut.cAlphaArgs.allocate(NumAlphas)
    self.state.dataIPShortCut.rNumericArgs.allocate(NumNumbers)
    self.state.dataIPShortCut.lNumericFieldBlanks = false
    self.state.dataIPShortCut.lAlphaFieldBlanks = false
    self.state.dataIPShortCut.cAlphaFieldNames = " "
    self.state.dataIPShortCut.cNumericFieldNames = " "
    self.state.dataIPShortCut.cAlphaArgs = " "
    self.state.dataIPShortCut.rNumericArgs = 0.0
    ZoneNum = 1
    self.state.dataIPShortCut.cAlphaArgs[0] = "Zone One"                     # Name
    self.state.dataIPShortCut.rNumericArgs[0] = 0.0                          # Direction of Relative North[deg]
    self.state.dataIPShortCut.rNumericArgs[1] = 0.0                          # X [m]
    self.state.dataIPShortCut.rNumericArgs[2] = 0.0                          # Y [m]
    self.state.dataIPShortCut.rNumericArgs[3] = 0.0                          # Z [m]
    self.state.dataIPShortCut.rNumericArgs[4] = 0.0                          # Type
    self.state.dataIPShortCut.rNumericArgs[5] = 0.0                          # Multiplier
    self.state.dataIPShortCut.lNumericFieldBlanks[6] = true                  # Ceiling Height{ m }
    self.state.dataIPShortCut.lNumericFieldBlanks[7] = true                  # Volume{ m3 }
    self.state.dataIPShortCut.lNumericFieldBlanks[8] = true                  # Floor Area{ m2 }
    self.state.dataIPShortCut.cAlphaArgs[1] = "ADAPTIVECONVECTIONALGORITHM"  # Zone Inside Convection Algorithm - Must be UPPERCASE by this point
    ErrorsFound = false
    ProcessZoneData(self.state,
                    self.state.dataIPShortCut.cCurrentModuleObject,
                    ZoneNum,
                    self.state.dataIPShortCut.cAlphaArgs,
                    NumAlphas,
                    self.state.dataIPShortCut.rNumericArgs,
                    NumNumbers,
                    self.state.dataIPShortCut.lNumericFieldBlanks,
                    self.state.dataIPShortCut.lAlphaFieldBlanks,
                    self.state.dataIPShortCut.cAlphaFieldNames,
                    self.state.dataIPShortCut.cNumericFieldNames,
                    ErrorsFound)
    ExpectFalse(ErrorsFound)
    ZoneNum = 2
    self.state.dataIPShortCut.cAlphaArgs[0] = "Zone Two"      # Name
    self.state.dataIPShortCut.cAlphaArgs[1] = "InvalidChoice"  # Zone Inside Convection Algorithm - Must be UPPERCASE by this point
    ErrorsFound = false
    ProcessZoneData(self.state,
                    self.state.dataIPShortCut.cCurrentModuleObject,
                    ZoneNum,
                    self.state.dataIPShortCut.cAlphaArgs,
                    NumAlphas,
                    self.state.dataIPShortCut.rNumericArgs,
                    NumNumbers,
                    self.state.dataIPShortCut.lNumericFieldBlanks,
                    self.state.dataIPShortCut.lAlphaFieldBlanks,
                    self.state.dataIPShortCut.cAlphaFieldNames,
                    self.state.dataIPShortCut.cNumericFieldNames,
                    ErrorsFound)
    ExpectTrue(ErrorsFound)
    ZoneNum = 2
    self.state.dataIPShortCut.cAlphaArgs[0] = "Zone Two"  # Name
    self.state.dataIPShortCut.cAlphaArgs[1] = "TARP"      # Zone Inside Convection Algorithm - Must be UPPERCASE by this point
    ErrorsFound = false
    ProcessZoneData(self.state,
                    self.state.dataIPShortCut.cCurrentModuleObject,
                    ZoneNum,
                    self.state.dataIPShortCut.cAlphaArgs,
                    NumAlphas,
                    self.state.dataIPShortCut.rNumericArgs,
                    NumNumbers,
                    self.state.dataIPShortCut.lNumericFieldBlanks,
                    self.state.dataIPShortCut.lAlphaFieldBlanks,
                    self.state.dataIPShortCut.cAlphaFieldNames,
                    self.state.dataIPShortCut.cNumericFieldNames,
                    ErrorsFound)
    ExpectFalse(ErrorsFound)
    ExpectEq("Zone One", self.state.dataHeatBal.Zone[0].Name)
    ExpectEq(Convect.HcInt.AdaptiveConvectionAlgorithm, self.state.dataHeatBal.Zone[0].IntConvAlgo)
    ExpectEq("Zone Two", self.state.dataHeatBal.Zone[1].Name)
    ExpectEq(Convect.HcInt.ASHRAETARP, self.state.dataHeatBal.Zone[1].IntConvAlgo)

def HeatBalanceManager_GetWindowConstructData(self: EnergyPlusFixture) raises:
    var idf_objects: String = delimited_string([
        "Construction,",
        " WINDOWWBLIND, !- Name",
        " GLASS,        !- Outside Layer",
        " AIRGAP,       !- Layer 2",
        " GLASS;        !- Layer 3",
    ])
    AssertTrue(process_idf(idf_objects))
    var s_mat = self.state.dataMaterial
    var ErrorsFound: Bool = false
    var mat1 = Material.MaterialGlass()
    mat1.group = Material.Group.Glass
    mat1.Name = "GLASS"
    s_mat.materials.push_back(mat1)
    mat1.Num = s_mat.materials.isize()
    s_mat.materialMap.insert_or_assign(mat1.Name, mat1.Num)
    var mat2 = Material.MaterialGasMix()
    mat2.group = Material.Group.Gas
    mat2.Name = "AIRGAP"
    s_mat.materials.push_back(mat2)
    mat2.Num = s_mat.materials.isize()
    s_mat.materialMap.insert_or_assign(mat2.Name, mat2.Num)
    self.state.dataHeatBal.NominalRforNominalUCalculation.allocate(1)
    self.state.dataHeatBal.NominalRforNominalUCalculation[0] = 0.0
    mat1.NominalR = 0.4
    mat2.NominalR = 0.4
    ErrorsFound = false
    GetConstructData(self.state, ErrorsFound)
    ExpectFalse(ErrorsFound)
    self.state.dataConstruction.Construct.deallocate()

def HeatBalanceManager_ZoneAirMassFlowConservationData1(self: EnergyPlusFixture) raises:
    var idf_objects: String = delimited_string([
        "Building,",
        "My Building, !- Name",
        "30., !- North Axis{ deg }",
        "City, !- Terrain",
        "0.04, !- Loads Convergence Tolerance Value",
        "0.4, !- Temperature Convergence Tolerance Value{ deltaC }",
        "FullExterior, !- Solar Distribution",
        "25, !- Maximum Number of Warmup Days",
        "6;                       !- Minimum Number of Warmup Days",
        "ZoneAirMassFlowConservation,",
        "AdjustMixingOnly, !- Adjust Zone Mixing and Return For Air Mass Flow Balance",
        "AddInfiltrationFlow, !- Infiltration Balancing Method",
        "MixingSourceZonesOnly; !- Infiltration Balancing Zones",
    ])
    AssertTrue(process_idf(idf_objects))
    var ErrorsFound: Bool = false
    ErrorsFound = false
    GetProjectControlData(self.state, ErrorsFound)
    ExpectFalse(ErrorsFound)
    ExpectTrue(self.state.dataHeatBal.ZoneAirMassFlow.EnforceZoneMassBalance)
    ExpectEnumEq(self.state.dataHeatBal.ZoneAirMassFlow.ZoneFlowAdjustment, DataHeatBalance.AdjustmentType.AdjustMixingOnly)
    ExpectEnumEq(self.state.dataHeatBal.ZoneAirMassFlow.InfiltrationTreatment, DataHeatBalance.InfiltrationFlow.Add)
    ExpectEnumEq(self.state.dataHeatBal.ZoneAirMassFlow.InfiltrationForZones, DataHeatBalance.InfiltrationZoneType.MixingSourceZonesOnly)

def HeatBalanceManager_ZoneAirMassFlowConservationData2(self: EnergyPlusFixture) raises:
    var idf_objects: String = delimited_string(["Building,",
                                                "My Building, !- Name",
                                                "30., !- North Axis{ deg }",
                                                "City, !- Terrain",
                                                "0.04, !- Loads Convergence Tolerance Value",
                                                "0.4, !- Temperature Convergence Tolerance Value{ deltaC }",
                                                "FullExterior, !- Solar Distribution",
                                                "25, !- Maximum Number of Warmup Days",
                                                "6;                       !- Minimum Number of Warmup Days",
                                                "ZoneAirMassFlowConservation,",
                                                "None, !- Adjust Zone Mixing and Return For Air Mass Flow Balance",
                                                "AdjustInfiltrationFlow, !- Infiltration Balancing Method",
                                                "AllZones;                !- Infiltration Balancing Zones",
                                                "Zone, Zone 1;",
                                                "Zone, Zone 2;",
                                                "ZoneMixing,",
                                                "Zone 2 Zone Mixing, !- Name",
                                                "Zone 2, !- Zone Name",
                                                "Always1, !- Schedule Name",
                                                "Flow/Zone, !- Design Flow Rate Calculation Method",
                                                "0.07, !- Design Flow Rate{ m3 / s }",
                                                ", !- Flow Rate per Zone Floor Area{ m3 / s - m2 }",
                                                ", !- Flow Rate per Person{ m3 / s - person }",
                                                ", !- Air Changes per Hour{ 1 / hr }",
                                                "Zone 1, !- Source Zone Name",
                                                "0.0;                     !- Delta Temperature{ deltaC }",
                                                "ZoneInfiltration:DesignFlowRate,",
                                                "Zone 1 Infil 1, !- Name",
                                                "Zone 1, !- Zone or ZoneList Name",
                                                "Always1, !- Schedule Name",
                                                "flow/zone, !- Design Flow Rate Calculation Method",
                                                "0.032, !- Design Flow Rate{ m3 / s }",
                                                ", !- Flow per Zone Floor Area{ m3 / s - m2 }",
                                                ", !- Flow per Exterior Surface Area{ m3 / s - m2 }",
                                                ", !- Air Changes per Hour{ 1 / hr }",
                                                "1, !- Constant Term Coefficient",
                                                "0, !- Temperature Term Coefficient",
                                                "0, !- Velocity Term Coefficient",
                                                "0; !- Velocity Squared Term Coefficient",
                                                "Schedule:Constant,Always1,,1.0;"
    ])
    AssertTrue(process_idf(idf_objects))
    self.state.init_state(self.state)
    var ErrorsFound: Bool = false
    HeatBalanceManager.GetProjectControlData(self.state, ErrorsFound)
    ExpectTrue(self.state.dataHeatBal.ZoneAirMassFlow.EnforceZoneMassBalance)
    ExpectEnumEq(self.state.dataHeatBal.ZoneAirMassFlow.ZoneFlowAdjustment, DataHeatBalance.AdjustmentType.NoAdjustReturnAndMixing)
    ExpectEnumEq(self.state.dataHeatBal.ZoneAirMassFlow.InfiltrationTreatment, DataHeatBalance.InfiltrationFlow.Adjust)
    ExpectEnumEq(self.state.dataHeatBal.ZoneAirMassFlow.InfiltrationForZones, DataHeatBalance.InfiltrationZoneType.AllZones)
    self.state.dataGlobal.NumOfZones = 2
    self.state.dataHeatBalFanSys.ZoneReOrder.allocate(self.state.dataGlobal.NumOfZones)
    ErrorsFound = false
    GetZoneData(self.state, ErrorsFound)
    ExpectFalse(ErrorsFound)
    AllocateHeatBalArrays(self.state)
    ErrorsFound = false
    GetSimpleAirModelInputs(self.state, ErrorsFound)
    ExpectFalse(ErrorsFound)
    SetZoneMassConservationFlag(self.state)
    self.state.dataZoneEquip.ZoneEquipConfig.allocate(self.state.dataGlobal.NumOfZones)
    self.state.dataZoneEquip.ZoneEquipConfig[0].ZoneName = "Zone 1"
    self.state.dataZoneEquip.ZoneEquipConfig[0].NumInletNodes = 1
    self.state.dataZoneEquip.ZoneEquipConfig[0].InletNode.allocate(1)
    self.state.dataZoneEquip.ZoneEquipConfig[0].NumExhaustNodes = 1
    self.state.dataZoneEquip.ZoneEquipConfig[0].ExhaustNode.allocate(1)
    self.state.dataZoneEquip.ZoneEquipConfig[0].ZoneNode = 1
    self.state.dataZoneEquip.ZoneEquipConfig[0].InletNode[0] = 2
    self.state.dataZoneEquip.ZoneEquipConfig[0].ExhaustNode[0] = 3
    self.state.dataZoneEquip.ZoneEquipConfig[0].NumReturnNodes = 1
    self.state.dataZoneEquip.ZoneEquipConfig[0].ReturnNode.allocate(1)
    self.state.dataZoneEquip.ZoneEquipConfig[0].ReturnNode[0] = 4
    self.state.dataZoneEquip.ZoneEquipConfig[0].FixedReturnFlow.allocate(1)
    self.state.dataZoneEquip.ZoneEquipConfig[0].IsControlled = true
    self.state.dataZoneEquip.ZoneEquipConfig[0].returnFlowFracSched = Sched.GetScheduleAlwaysOn(self.state)
    self.state.dataZoneEquip.ZoneEquipConfig[0].InletNodeAirLoopNum.allocate(1)
    self.state.dataZoneEquip.ZoneEquipConfig[0].InletNodeADUNum.allocate(1)
    self.state.dataZoneEquip.ZoneEquipConfig[0].AirDistUnitCool.allocate(1)
    self.state.dataZoneEquip.ZoneEquipConfig[0].AirDistUnitHeat.allocate(1)
    self.state.dataZoneEquip.ZoneEquipConfig[0].InletNodeAirLoopNum[0] = 1
    self.state.dataZoneEquip.ZoneEquipConfig[0].InletNodeADUNum[0] = 0
    self.state.dataZoneEquip.ZoneEquipConfig[0].AirDistUnitCool[0].InNode = 2
    self.state.dataZoneEquip.ZoneEquipConfig[0].ReturnNodeAirLoopNum.allocate(1)
    self.state.dataZoneEquip.ZoneEquipConfig[0].ReturnNodeInletNum.allocate(1)
    self.state.dataZoneEquip.ZoneEquipConfig[0].ReturnNodeAirLoopNum[0] = 1
    self.state.dataZoneEquip.ZoneEquipConfig[0].ReturnNodeInletNum[0] = 1
    self.state.dataZoneEquip.ZoneEquipConfig[1].ZoneName = "Zone 2"
    self.state.dataZoneEquip.ZoneEquipConfig[1].NumExhaustNodes = 1
    self.state.dataZoneEquip.ZoneEquipConfig[1].ExhaustNode.allocate(1)
    self.state.dataZoneEquip.ZoneEquipConfig[1].NumInletNodes = 1
    self.state.dataZoneEquip.ZoneEquipConfig[1].InletNode.allocate(1)
    self.state.dataZoneEquip.ZoneEquipConfig[1].ZoneNode = 5
    self.state.dataZoneEquip.ZoneEquipConfig[1].InletNode[0] = 6
    self.state.dataZoneEquip.ZoneEquipConfig[1].ExhaustNode[0] = 7
    self.state.dataZoneEquip.ZoneEquipConfig[1].NumReturnNodes = 1
    self.state.dataZoneEquip.ZoneEquipConfig[1].ReturnNode.allocate(1)
    self.state.dataZoneEquip.ZoneEquipConfig[1].ReturnNode[0] = 8
    self.state.dataZoneEquip.ZoneEquipConfig[1].FixedReturnFlow.allocate(1)
    self.state.dataZoneEquip.ZoneEquipConfig[1].IsControlled = true
    self.state.dataZoneEquip.ZoneEquipConfig[1].returnFlowFracSched = Sched.GetScheduleAlwaysOn(self.state)
    self.state.dataZoneEquip.ZoneEquipConfig[1].InletNodeAirLoopNum.allocate(1)
    self.state.dataZoneEquip.ZoneEquipConfig[1].InletNodeADUNum.allocate(1)
    self.state.dataZoneEquip.ZoneEquipConfig[1].AirDistUnitCool.allocate(1)
    self.state.dataZoneEquip.ZoneEquipConfig[1].AirDistUnitHeat.allocate(1)
    self.state.dataZoneEquip.ZoneEquipConfig[1].InletNodeAirLoopNum[0] = 1
    self.state.dataZoneEquip.ZoneEquipConfig[1].InletNodeADUNum[0] = 0
    self.state.dataZoneEquip.ZoneEquipConfig[1].AirDistUnitCool[0].InNode = 6
    self.state.dataZoneEquip.ZoneEquipConfig[1].ReturnNodeAirLoopNum.allocate(1)
    self.state.dataZoneEquip.ZoneEquipConfig[1].ReturnNodeInletNum.allocate(1)
    self.state.dataZoneEquip.ZoneEquipConfig[1].ReturnNodeAirLoopNum[0] = 1
    self.state.dataZoneEquip.ZoneEquipConfig[1].ReturnNodeInletNum[0] = 1
    self.state.dataZoneEquip.ZoneEquipInputsFilled = true
    self.state.dataHVACGlobal.NumPrimaryAirSys = 1
    self.state.dataAirLoop.AirLoopFlow.allocate(1)
    self.state.dataAirSystemsData.PrimaryAirSystems.allocate(1)
    self.state.dataAirSystemsData.PrimaryAirSystems[0].OASysExists = true
    self.state.dataLoopNodes.Node.allocate(8)
    self.state.dataEnvrn.StdRhoAir = 1.2
    self.state.dataEnvrn.OutBaroPress = 100000.0
    self.state.dataLoopNodes.Node[self.state.dataZoneEquip.ZoneEquipConfig[0].ZoneNode - 1?].Temp = 20.0
    self.state.dataLoopNodes.Node[self.state.dataZoneEquip.ZoneEquipConfig[0].ZoneNode - 1?].HumRat = 0.004
    self.state.dataLoopNodes.Node[self.state.dataZoneEquip.ZoneEquipConfig[1].ZoneNode - 1?].Temp = 20.0
    self.state.dataLoopNodes.Node[self.state.dataZoneEquip.ZoneEquipConfig[1].ZoneNode - 1?].HumRat = 0.004
    self.state.dataLoopNodes.Node[0].MassFlowRate = 0.0
    self.state.dataLoopNodes.Node[1].MassFlowRate = 1.0
    self.state.dataLoopNodes.Node[2].MassFlowRate = 2.0
    self.state.dataLoopNodes.Node[3].MassFlowRate = 9.0
    self.state.dataZoneEquip.ZoneEquipConfig[0].ZoneExh = 2.0
    self.state.dataLoopNodes.Node[4].MassFlowRate = 0.0
    self.state.dataLoopNodes.Node[5].MassFlowRate = 2.0
    self.state.dataLoopNodes.Node[6].MassFlowRate = 0.0
    self.state.dataLoopNodes.Node[7].MassFlowRate = 8.0
    self.state.dataZoneEquip.ZoneEquipConfig[1].ZoneExh = 0.0
    self.state.dataAirLoop.AirLoopFlow[0].OAFlow = self.state.dataLoopNodes.Node[1].MassFlowRate + self.state.dataLoopNodes.Node[5].MassFlowRate
    self.state.dataAirLoop.AirLoopFlow[0].MaxOutAir = self.state.dataAirLoop.AirLoopFlow[0].OAFlow
    self.state.dataHeatBal.Infiltration[0].MassFlowRate = 0.5
    self.state.dataHeatBal.Mixing[0].MixingMassFlowRate = 0.1
    CalcZoneMassBalance(self.state, false)
    ExpectEq(self.state.dataLoopNodes.Node[3].MassFlowRate, 0.0)
    ExpectEq(self.state.dataHeatBal.Infiltration[0].MassFlowRate, 1.0)
    ExpectEq(self.state.dataHeatBal.Mixing[0].MixingMassFlowRate, 0.1)
    ExpectEq(self.state.dataLoopNodes.Node[7].MassFlowRate, 2.0)
    self.state.dataHeatBalFanSys.ZoneReOrder.deallocate()
    self.state.dataZoneEquip.ZoneEquipConfig.deallocate()
    self.state.dataLoopNodes.Node.deallocate()
    self.state.dataAirSystemsData.PrimaryAirSystems.deallocate()
    self.state.dataAirLoop.AirLoopFlow.deallocate()
    self.state.dataHVACGlobal.NumPrimaryAirSys = 0

def HeatBalanceManager_ZoneAirMassFlowConservationData3(self: EnergyPlusFixture) raises:
    var idf_objects: String = delimited_string(["Building,",
                                                "My Building, !- Name",
                                                "30., !- North Axis{ deg }",
                                                "City, !- Terrain",
                                                "0.04, !- Loads Convergence Tolerance Value",
                                                "0.4, !- Temperature Convergence Tolerance Value{ deltaC }",
                                                "FullExterior, !- Solar Distribution",
                                                "25, !- Maximum Number of Warmup Days",
                                                "6;                       !- Minimum Number of Warmup Days",
                                                "ZoneAirMassFlowConservation,",
                                                "None, !- Adjust Zone Mixing and Return For Air Mass Flow Balance",
                                                "None, !- Infiltration Balancing Method",
                                                ";                !- Infiltration Balancing Zones"])
    AssertTrue(process_idf(idf_objects))
    var ErrorsFound: Bool = false
    ErrorsFound = false
    GetProjectControlData(self.state, ErrorsFound)
    ExpectFalse(ErrorsFound)
    ExpectFalse(self.state.dataHeatBal.ZoneAirMassFlow.EnforceZoneMassBalance)
    ExpectEnumEq(self.state.dataHeatBal.ZoneAirMassFlow.ZoneFlowAdjustment, DataHeatBalance.AdjustmentType.NoAdjustReturnAndMixing)
    ExpectEnumEq(self.state.dataHeatBal.ZoneAirMassFlow.InfiltrationTreatment, DataHeatBalance.InfiltrationFlow.No)
    ExpectEnumEq(self.state.dataHeatBal.ZoneAirMassFlow.InfiltrationForZones, DataHeatBalance.InfiltrationZoneType.Invalid)

def HeatBalanceManager_ZoneAirMassFlowConservationReportVariableTest(self: EnergyPlusFixture) raises:
    var idf_objects: String = delimited_string([
        "Building,",
        "My Building, !- Name",
        "30., !- North Axis{ deg }",
        "City, !- Terrain",
        "0.04, !- Loads Convergence Tolerance Value",
        "0.4, !- Temperature Convergence Tolerance Value{ deltaC }",
        "FullExterior, !- Solar Distribution",
        "25, !- Maximum Number of Warmup Days",
        "6;                       !- Minimum Number of Warmup Days",
        "ZoneAirMassFlowConservation,",
        "AdjustMixingOnly, !- Adjust Zone Mixing and Return For Air Mass Flow Balance",
        "AdjustInfiltrationFlow, !- Infiltration Balancing Method",
        "AllZones;                !- Infiltration Balancing Zones",
        "  Zone,",
        "    WEST ZONE,               !- Name",
        "    0,                       !- Direction of Relative North {deg}",
        "    0,                       !- X Origin {m}",
        "    0,                       !- Y Origin {m}",
        "    0,                       !- Z Origin {m}",
        "    1,                       !- Type",
        "    1,                       !- Multiplier",
        "    autocalculate,           !- Ceiling Height {m}",
        "    autocalculate;           !- Volume {m3}",
        "  Zone,",
        "    EAST ZONE,               !- Name",
        "    0,                       !- Direction of Relative North {deg}",
        "    0,                       !- X Origin {m}",
        "    0,                       !- Y Origin {m}",
        "    0,                       !- Z Origin {m}",
        "    1,                       !- Type",
        "    1,                       !- Multiplier",
        "    autocalculate,           !- Ceiling Height {m}",
        "    autocalculate;           !- Volume {m3}",
        " Output:Variable,",
        "   *, !- Key Value",
        "   Zone Air Mass Balance Exhaust Mass Flow Rate, !- Variable Name",
        "   hourly;                  !- Reporting Frequency",
    ])
    AssertTrue(process_idf(idf_objects))
    var ErrorsFound: Bool = false
    ErrorsFound = false
    GetProjectControlData(self.state, ErrorsFound)
    ExpectFalse(ErrorsFound)
    self.state.dataGlobal.NumOfZones = 2
    self.state.dataHeatBalFanSys.ZoneReOrder.allocate(self.state.dataGlobal.NumOfZones)
    ErrorsFound = false
    GetZoneData(self.state, ErrorsFound)
    ExpectFalse(ErrorsFound)
    ErrorsFound = false
    GetSimpleAirModelInputs(self.state, ErrorsFound)
    ExpectFalse(ErrorsFound)
    ExpectEq("WEST ZONE:Zone Air Mass Balance Exhaust Mass Flow Rate", self.state.dataOutputProcessor.outVars[0].keyColonName)
    ExpectEq("EAST ZONE:Zone Air Mass Balance Exhaust Mass Flow Rate", self.state.dataOutputProcessor.outVars[1].keyColonName)
    ExpectEq(1, self.state.dataOutputProcessor.outVars[0].ReportID)
    ExpectEq(2, self.state.dataOutputProcessor.outVars[1].ReportID)

def HeatBalanceManager_GetMaterialRoofVegetation(self: EnergyPlusFixture) raises:
    var idf_objects: String = delimited_string([
        "  Material:RoofVegetation,",
        "    ThickSoil,               !- Name",
        "    0.5,                     !- Height of Plants {m}",
        "    5,                       !- Leaf Area Index {dimensionless}",
        "    0.2,                     !- Leaf Reflectivity {dimensionless}",
        "    0.95,                    !- Leaf Emissivity",
        "    180,                     !- Minimum Stomatal Resistance {s/m}",
        "    EcoRoofSoil,             !- Soil Layer Name",
        "    MediumSmooth,            !- Roughness",
        "    0.36,                    !- Thickness {m}",
        "    0.4,                     !- Conductivity of Dry Soil {W/m-K}",
        "    641,                     !- Density of Dry Soil {kg/m3}",
        "    1100,                    !- Specific Heat of Dry Soil {J/kg-K}",
        "    0.95,                    !- Thermal Absorptance",
        "    0.8,                     !- Solar Absorptance",
        "    0.7,                     !- Visible Absorptance",
        "    0.4,                     !- Saturation Volumetric Moisture Content of the Soil Layer",
        "    0.01,                    !- Residual Volumetric Moisture Content of the Soil Layer",
        "    0.45,                    !- Initial Volumetric Moisture Content of the Soil Layer",
        "    Advanced;                !- Moisture Diffusion Calculation Method",
    ])
    AssertTrue(process_idf(idf_objects))
    var ErrorsFound: Bool = false
    Material.GetMaterialData(self.state, ErrorsFound)
    ExpectFalse(ErrorsFound)
    var mat1 = dynamic_cast[Material.MaterialEcoRoof](self.state.dataMaterial.materials[0])
    ExpectEq(mat1.Name, "THICKSOIL")
    ExpectEq(0.4, mat1.Porosity)
    ExpectEq(0.4, mat1.InitMoisture)

def HeatBalanceManager_WarmUpConvergenceSmallLoadTest(self: EnergyPlusFixture) raises:
    self.state.dataGlobal.WarmupFlag = false
    self.state.dataGlobal.DayOfSim = 7
    self.state.dataHeatBal.MinNumberOfWarmupDays = 25
    self.state.dataGlobal.NumOfZones = 1
    self.state.dataHeatBalMgr.WarmupConvergenceValues.allocate(self.state.dataGlobal.NumOfZones)
    self.state.dataHeatBal.TempConvergTol = 0.01
    self.state.dataHeatBal.LoadsConvergTol = 0.01
    self.state.dataHeatBalMgr.MaxTempPrevDay.allocate(self.state.dataGlobal.NumOfZones)
    self.state.dataHeatBalMgr.MaxTempPrevDay[0] = 23.0
    self.state.dataHeatBalMgr.MaxTempZone.allocate(self.state.dataGlobal.NumOfZones)
    self.state.dataHeatBalMgr.MaxTempZone[0] = 23.0
    self.state.dataHeatBalMgr.MinTempPrevDay.allocate(self.state.dataGlobal.NumOfZones)
    self.state.dataHeatBalMgr.MinTempPrevDay[0] = 23.0
    self.state.dataHeatBalMgr.MinTempZone.allocate(self.state.dataGlobal.NumOfZones)
    self.state.dataHeatBalMgr.MinTempZone[0] = 23.0
    self.state.dataHeatBalMgr.MaxHeatLoadZone.allocate(self.state.dataGlobal.NumOfZones)
    self.state.dataHeatBalMgr.MaxHeatLoadPrevDay.allocate(self.state.dataGlobal.NumOfZones)
    self.state.dataHeatBalMgr.WarmupConvergenceValues[0].TestMaxHeatLoadValue = 0.0
    self.state.dataHeatBalMgr.MaxCoolLoadZone.allocate(self.state.dataGlobal.NumOfZones)
    self.state.dataHeatBalMgr.MaxCoolLoadPrevDay.allocate(self.state.dataGlobal.NumOfZones)
    self.state.dataHeatBalMgr.WarmupConvergenceValues[0].TestMaxCoolLoadValue = 0.0
    self.state.dataHeatBalMgr.MaxHeatLoadZone[0] = 50.0
    self.state.dataHeatBalMgr.MaxHeatLoadPrevDay[0] = 90.0
    self.state.dataHeatBalMgr.MaxCoolLoadZone[0] = 50.0
    self.state.dataHeatBalMgr.MaxCoolLoadPrevDay[0] = 90.0
    CheckWarmupConvergence(self.state)
    ExpectEq(self.state.dataHeatBalMgr.WarmupConvergenceValues[0].PassFlag[2?], 2)
    ExpectEq(self.state.dataHeatBalMgr.WarmupConvergenceValues[0].PassFlag[3?], 2)
    ExpectNear(self.state.dataHeatBalMgr.WarmupConvergenceValues[0].TestMaxHeatLoadValue, 0.0, 0.0001)
    ExpectNear(self.state.dataHeatBalMgr.WarmupConvergenceValues[0].TestMaxCoolLoadValue, 0.0, 0.0001)
    self.state.dataHeatBalMgr.MaxHeatLoadZone[0] = 100.5
    self.state.dataHeatBalMgr.MaxHeatLoadPrevDay[0] = 90.0
    self.state.dataHeatBalMgr.MaxCoolLoadZone[0] = 100.5
    self.state.dataHeatBalMgr.MaxCoolLoadPrevDay[0] = 90.0
    CheckWarmupConvergence(self.state)
    ExpectEq(self.state.dataHeatBalMgr.WarmupConvergenceValues[0].PassFlag[2?], 2)
    ExpectEq(self.state.dataHeatBalMgr.WarmupConvergenceValues[0].PassFlag[3?], 2)
    ExpectNear(self.state.dataHeatBalMgr.WarmupConvergenceValues[0].TestMaxHeatLoadValue, 0.005, 0.0001)
    ExpectNear(self.state.dataHeatBalMgr.WarmupConvergenceValues[0].TestMaxCoolLoadValue, 0.005, 0.0001)
    self.state.dataHeatBalMgr.MaxHeatLoadZone[0] = 90.0
    self.state.dataHeatBalMgr.MaxHeatLoadPrevDay[0] = 100.5
    self.state.dataHeatBalMgr.MaxCoolLoadZone[0] = 90.0
    self.state.dataHeatBalMgr.MaxCoolLoadPrevDay[0] = 100.5
    CheckWarmupConvergence(self.state)
    ExpectEq(self.state.dataHeatBalMgr.WarmupConvergenceValues[0].PassFlag[2?], 2)
    ExpectEq(self.state.dataHeatBalMgr.WarmupConvergenceValues[0].PassFlag[3?], 2)
    ExpectNear(self.state.dataHeatBalMgr.WarmupConvergenceValues[0].TestMaxHeatLoadValue, 0.005, 0.0001)
    ExpectNear(self.state.dataHeatBalMgr.WarmupConvergenceValues[0].TestMaxCoolLoadValue, 0.005, 0.0001)
    self.state.dataHeatBalMgr.MaxHeatLoadZone[0] = 201.0
    self.state.dataHeatBalMgr.MaxHeatLoadPrevDay[0] = 200.0
    self.state.dataHeatBalMgr.MaxCoolLoadZone[0] = 201.0
    self.state.dataHeatBalMgr.MaxCoolLoadPrevDay[0] = 200.0
    CheckWarmupConvergence(self.state)
    ExpectEq(self.state.dataHeatBalMgr.WarmupConvergenceValues[0].PassFlag[2?], 2)
    ExpectEq(self.state.dataHeatBalMgr.WarmupConvergenceValues[0].PassFlag[3?], 2)
    ExpectNear(self.state.dataHeatBalMgr.WarmupConvergenceValues[0].TestMaxHeatLoadValue, 0.005, 0.0001)
    ExpectNear(self.state.dataHeatBalMgr.WarmupConvergenceValues[0].TestMaxCoolLoadValue, 0.005, 0.0001)
    self.state.dataHeatBalMgr.MaxHeatLoadZone[0] = 210.0
    self.state.dataHeatBalMgr.MaxHeatLoadPrevDay[0] = 200.0
    self.state.dataHeatBalMgr.MaxCoolLoadZone[0] = 210.0
    self.state.dataHeatBalMgr.MaxCoolLoadPrevDay[0] = 200.0
    CheckWarmupConvergence(self.state)
    ExpectEq(self.state.dataHeatBalMgr.WarmupConvergenceValues[0].PassFlag[2?], 1)
    ExpectEq(self.state.dataHeatBalMgr.WarmupConvergenceValues[0].PassFlag[3?], 1)
    ExpectNear(self.state.dataHeatBalMgr.WarmupConvergenceValues[0].TestMaxHeatLoadValue, 0.05, 0.005)
    ExpectNear(self.state.dataHeatBalMgr.WarmupConvergenceValues[0].TestMaxCoolLoadValue, 0.05, 0.005)

def HeatBalanceManager_TestZonePropertyLocalEnv(self: EnergyPlusFixture) raises:
    var idf_objects: String = delimited_string([
        "  Building,",
        "    House with Local Air Nodes,  !- Name",
        "    0,                       !- North Axis {deg}",
        "    Suburbs,                 !- Terrain",
        "    0.001,                   !- Loads Convergence Tolerance Value",
        "    0.0050000,               !- Temperature Convergence Tolerance Value {deltaC}",
        "    FullInteriorAndExterior, !- Solar Distribution",
        "    25,                      !- Maximum Number of Warmup Days",
        "    6;                       !- Minimum Number of Warmup Days",
        "  Timestep,6;",
        "  SurfaceConvectionAlgorithm:Inside,TARP;",
        "  SurfaceConvectionAlgorithm:Outside,DOE-2;",
        "  HeatBalanceAlgorithm,ConductionTransferFunction;",
        "  SimulationControl,",
        "    No,                      !- Do Zone Sizing Calculation",
        "    No,                      !- Do System Sizing Calculation",
        "    No,                      !- Do Plant Sizing Calculation",
        "    Yes,                     !- Run Simulation for Sizing Periods",
        "    Yes;                     !- Run Simulation for Weather File Run Periods",
        "  RunPeriod,",
        "    WinterDay,               !- Name",
        "    1,                       !- Begin Month",
        "    14,                      !- Begin Day of Month",
        "    ,                        !- Begin Year",
        "    1,                       !- End Month",
        "    14,                      !- End Day of Month",
        "    ,                        !- End Year",
        "    Tuesday,                 !- Day of Week for Start Day",
        "    Yes,                     !- Use Weather File Holidays and Special Days",
        "    Yes,                     !- Use Weather File Daylight Saving Period",
        "    No,                      !- Apply Weekend Holiday Rule",
        "    Yes,                     !- Use Weather File Rain Indicators",
        "    Yes;                     !- Use Weather File Snow Indicators",
        "  RunPeriod,",
        "    SummerDay,               !- Name",
        "    7,                       !- Begin Month",
        "    7,                       !- Begin Day of Month",
        "    ,                        !- Begin Year",
        "    7,                       !- End Month",
        "    7,                       !- End Day of Month",
        "    ,                        !- End Year",
        "    Tuesday,                 !- Day of Week for Start Day",
        "    Yes,                     !- Use Weather File Holidays and Special Days",
        "    Yes,                     !- Use Weather File Daylight Saving Period",
        "    No,                      !- Apply Weekend Holiday Rule",
        "    Yes,                     !- Use Weather File Rain Indicators",
        "    No;                      !- Use Weather File Snow Indicators",
        "  Site:Location,",
        "    CHICAGO_IL_USA TMY2-94846,  !- Name",
        "    41.78,                   !- Latitude {deg}",
        "    -87.75,                  !- Longitude {deg}",
        "    -6.00,                   !- Time Zone {hr}",
        "    190.00;                  !- Elevation {m}",
        "  SizingPeriod:DesignDay,",
        "    CHICAGO_IL_USA Annual Heating 99% Design Conditions DB,  !- Name",
        "    1,                       !- Month",
        "    21,                      !- Day of Month",
        "    WinterDesignDay,         !- Day Type",
        "    -17.3,                   !- Maximum Dry-Bulb Temperature {C}",
        "    0.0,                     !- Daily Dry-Bulb Temperature Range {deltaC}",
        "    ,                        !- Dry-Bulb Temperature Range Modifier Type",
        "    ,                        !- Dry-Bulb Temperature Range Modifier Day Schedule Name",
        "    Wetbulb,                 !- Humidity Condition Type",
        "    -17.3,                   !- Wetbulb or DewPoint at Maximum Dry-Bulb {C}",
        "    ,                        !- Humidity Condition Day Schedule Name",
        "    ,                        !- Humidity Ratio at Maximum Dry-Bulb {kgWater/kgDryAir}",
        "    ,                        !- Enthalpy at Maximum Dry-Bulb {J/kg}",
        "    ,                        !- Daily Wet-Bulb Temperature Range {deltaC}",
        "    99063.,                  !- Barometric Pressure {Pa}",
        "    4.9,                     !- Wind Speed {m/s}",
        "    270,                     !- Wind Direction {deg}",
        "    No,                      !- Rain Indicator",
        "    No,                      !- Snow Indicator",
        "    No,                      !- Daylight Saving Time Indicator",
        "    ASHRAEClearSky,          !- Solar Model Indicator",
        "    ,                        !- Beam Solar Day Schedule Name",
        "    ,                        !- Diffuse Solar Day Schedule Name",
        "    ,                        !- ASHRAE Clear Sky Optical Depth for Beam Irradiance (taub) {dimensionless}",
        "    ,                        !- ASHRAE Clear Sky Optical Depth for Diffuse Irradiance (taud) {dimensionless}",
        "    0.0;                     !- Sky Clearness",
        "  SizingPeriod:DesignDay,",
        "    CHICAGO_IL_USA Annual Cooling 1% Design Conditions DB/MCWB,  !- Name",
        "    7,                       !- Month",
        "    21,                      !- Day of Month",
        "    SummerDesignDay,         !- Day Type",
        "    31.5,                    !- Maximum Dry-Bulb Temperature {C}",
        "    10.7,                    !- Daily Dry-Bulb Temperature Range {deltaC}",
        "    ,                        !- Dry-Bulb Temperature Range Modifier Type",
        "    ,                        !- Dry-Bulb Temperature Range Modifier Day Schedule Name",
        "    Wetbulb,                 !- Humidity Condition Type",
        "    23.0,                    !- Wetbulb or DewPoint at Maximum Dry-Bulb {C}",
        "    ,                        !- Humidity Condition Day Schedule Name",
        "    ,                        !- Humidity Ratio at Maximum Dry-Bulb {kgWater/kgDryAir}",
        "    ,                        !- Enthalpy at Maximum Dry-Bulb {J/kg}",
        "    ,                        !- Daily Wet-Bulb Temperature Range {deltaC}",
        "    99063.,                  !- Barometric Pressure {Pa}",
        "    5.3,                     !- Wind Speed {m/s}",
        "    230,                     !- Wind Direction {deg}",
        "    No,                      !- Rain Indicator",
        "    No,                      !- Snow Indicator",
        "    No,                      !- Daylight Saving Time Indicator",
        "    ASHRAEClearSky,          !- Solar Model Indicator",
        "    ,                        !- Beam Solar Day Schedule Name",
        "    ,                        !- Diffuse Solar Day Schedule Name",
        "    ,                        !- ASHRAE Clear Sky Optical Depth for Beam Irradiance (taub) {dimensionless}",
        "    ,                        !- ASHRAE Clear Sky Optical Depth for Diffuse Irradiance (taud) {dimensionless}",
        "    1.0;                     !- Sky Clearness",
        "  Site:GroundTemperature:BuildingSurface,20.03,20.03,20.13,20.30,20.43,20.52,20.62,20.77,20.78,20.55,20.44,20.20;",
        "  Material,",
        "    A1 - 1 IN STUCCO,        !- Name",
        "    Smooth,                  !- Roughness",
        "    2.5389841E-02,           !- Thickness {m}",
        "    0.6918309,               !- Conductivity {W/m-K}",
        "    1858.142,                !- Density {kg/m3}",
        "    836.8000,                !- Specific Heat {J/kg-K}",
        "    0.9000000,               !- Thermal Absorptance",
        "    0.9200000,               !- Solar Absorptance",
        "    0.9200000;               !- Visible Absorptance",
        "  Material,",
        "    CB11,                    !- Name",
        "    MediumRough,             !- Roughness",
        "    0.2032000,               !- Thickness {m}",
        "    1.048000,                !- Conductivity {W/m-K}",
        "    1105.000,                !- Density {kg/m3}",
        "    837.0000,                !- Specific Heat {J/kg-K}",
        "    0.9000000,               !- Thermal Absorptance",
        "    0.2000000,               !- Solar Absorptance",
        "    0.2000000;               !- Visible Absorptance",
        "  Material,",
        "    GP01,                    !- Name",
        "    MediumSmooth,            !- Roughness",
        "    1.2700000E-02,           !- Thickness {m}",
        "    0.1600000,               !- Conductivity {W/m-K}",
        "    801.0000,                !- Density {kg/m3}",
        "    837.0000,                !- Specific Heat {J/kg-K}",
        "    0.9000000,               !- Thermal Absorptance",
        "    0.7500000,               !- Solar Absorptance",
        "    0.7500000;               !- Visible Absorptance",
        "  Material,",
        "    IN02,                    !- Name",
        "    Rough,                   !- Roughness",
        "    9.0099998E-02,           !- Thickness {m}",
        "    4.3000001E-02,           !- Conductivity {W/m-K}",
        "    10.00000,                !- Density {kg/m3}",
        "    837.0000,                !- Specific Heat {J/kg-K}",
        "    0.9000000,               !- Thermal Absorptance",
        "    0.7500000,               !- Solar Absorptance",
        "    0.7500000;               !- Visible Absorptance",
        "  Material,",
        "    IN05,                    !- Name",
        "    Rough,                   !- Roughness",
        "    0.2458000,               !- Thickness {m}",
        "    4.3000001E-02,           !- Conductivity {W/m-K}",
        "    10.00000,                !- Density {kg/m3}",
        "    837.0000,                !- Specific Heat {J/kg-K}",
        "    0.9000000,               !- Thermal Absorptance",
        "    0.7500000,               !- Solar Absorptance",
        "    0.7500000;               !- Visible Absorptance",
        "  Material,",
        "    PW03,                    !- Name",
        "    MediumSmooth,            !- Roughness",
        "    1.2700000E-02,           !- Thickness {m}",
        "    0.1150000,               !- Conductivity {W/m-K}",
        "    545.0000,                !- Density {kg/m3}",
        "    1213.000,                !- Specific Heat {J/kg-K}",
        "    0.9000000,               !- Thermal Absorptance",
        "    0.7800000,               !- Solar Absorptance",
        "    0.7800000;               !- Visible Absorptance",
        "  Material,",
        "    CC03,                    !- Name",
        "    MediumRough,             !- Roughness",
        "    0.1016000,               !- Thickness {m}",
        "    1.310000,                !- Conductivity {W/m-K}",
        "    2243.000,                !- Density {kg/m3}",
        "    837.0000,                !- Specific Heat {J/kg-K}",
        "    0.9000000,               !- Thermal Absorptance",
        "    0.6500000,               !- Solar Absorptance",
        "    0.6500000;               !- Visible Absorptance",
        "  Material,",
        "    HF-A3,                   !- Name",
        "    Smooth,                  !- Roughness",
        "    1.5000000E-03,           !- Thickness {m}",
        "    44.96960,                !- Conductivity {W/m-K}",
        "    7689.000,                !- Density {kg/m3}",
        "    418.0000,                !- Specific Heat {J/kg-K}",
        "    0.9000000,               !- Thermal Absorptance",
        "    0.2000000,               !- Solar Absorptance",
        "    0.2000000;               !- Visible Absorptance",
        "  Material:NoMass,",
        "    AR02,                    !- Name",
        "    VeryRough,               !- Roughness",
        "    7.8000002E-02,           !- Thermal Resistance {m2-K/W}",
        "    0.9000000,               !- Thermal Absorptance",
        "    0.7000000,               !- Solar Absorptance",
        "    0.7000000;               !- Visible Absorptance",
        "  Material:NoMass,",
        "    CP02,                    !- Name",
        "    Rough,                   !- Roughness",
        "    0.2170000,               !- Thermal Resistance {m2-K/W}",
        "    0.9000000,               !- Thermal Absorptance",
        "    0.7500000,               !- Solar Absorptance",
        "    0.7500000;               !- Visible Absorptance",
        "  Construction,",
        "    EXTWALL:LIVING,          !- Name",
        "    A1 - 1 IN STUCCO,        !- Outside Layer",
        "    GP01;                    !- Layer 3",
        "  Construction,",
        "    FLOOR:LIVING,            !- Name",
        "    CC03,                    !- Outside Layer",
        "    CP02;                    !- Layer 2",
        "  Construction,",
        "    ROOF,                    !- Name",
        "    AR02,                    !- Outside Layer",
        "    PW03;                    !- Layer 2",
        "  Zone,",
        "    LIVING ZONE,             !- Name",
        "    0,                       !- Direction of Relative North {deg}",
        "    0,                       !- X Origin {m}",
        "    0,                       !- Y Origin {m}",
        "    0,                       !- Z Origin {m}",
        "    1,                       !- Type",
        "    1,                       !- Multiplier",
        "    autocalculate,           !- Ceiling Height {m}",
        "    autocalculate;           !- Volume {m3}",
        "  GlobalGeometryRules,",
        "    UpperLeftCorner,         !- Starting Vertex Position",
        "    CounterClockWise,        !- Vertex Entry Direction",
        "    World;                   !- Coordinate System",
        "  BuildingSurface:Detailed,",
        "    Living:North,            !- Name",
        "    Wall,                    !- Surface Type",
        "    EXTWALL:LIVING,          !- Construction Name",
        "    LIVING ZONE,             !- Zone Name",
        "    ,                        !- Space Name",
        "    Outdoors,                !- Outside Boundary Condition",
        "    ,                        !- Outside Boundary Condition Object",
        "    SunExposed,              !- Sun Exposure",
        "    WindExposed,             !- Wind Exposure",
        "    0.5000000,               !- View Factor to Ground",
        "    4,                       !- Number of Vertices",
        "    1,1,1,  !- X,Y,Z ==> Vertex 1 {m}",
        "    1,1,0,  !- X,Y,Z ==> Vertex 2 {m}",
        "    0,1,0,  !- X,Y,Z ==> Vertex 3 {m}",
        "    0,1,1;  !- X,Y,Z ==> Vertex 4 {m}",
        "  BuildingSurface:Detailed,",
        "    Living:East,             !- Name",
        "    Wall,                    !- Surface Type",
        "    EXTWALL:LIVING,          !- Construction Name",
        "    LIVING ZONE,             !- Zone Name",
        "    ,                        !- Space Name",
        "    Outdoors,                !- Outside Boundary Condition",
        "    ,                        !- Outside Boundary Condition Object",
        "    SunExposed,              !- Sun Exposure",
        "    WindExposed,             !- Wind Exposure",
        "    0.5000000,               !- View Factor to Ground",
        "    4,                       !- Number of Vertices",
        "    1,0,1,  !- X,Y,Z ==> Vertex 1 {m}",
        "    1,0,0,  !- X,Y,Z ==> Vertex 2 {m}",
        "    1,1,0,  !- X,Y,Z ==> Vertex 3 {m}",
        "    1,1,1;  !- X,Y,Z ==> Vertex 4 {m}",
        "  BuildingSurface:Detailed,",
        "    Living:South,            !- Name",
        "    Wall,                    !- Surface Type",
        "    EXTWALL:LIVING,          !- Construction Name",
        "    LIVING ZONE,             !- Zone Name",
        "    ,                        !- Space Name",
        "    Outdoors,                !- Outside Boundary Condition",
        "    ,                        !- Outside Boundary Condition Object",
        "    SunExposed,              !- Sun Exposure",
        "    WindExposed,             !- Wind Exposure",
        "    0.5000000,               !- View Factor to Ground",
        "    4,                       !- Number of Vertices",
        "    0,0,1,  !- X,Y,Z ==> Vertex 1 {m}",
        "    0,0,0,  !- X,Y,Z ==> Vertex 2 {m}",
        "    1,0,0,  !- X,Y,Z ==> Vertex 3 {m}",
        "    1,0,1;  !- X,Y,Z ==> Vertex 4 {m}",
        "  BuildingSurface:Detailed,",
        "    Living:West,             !- Name",
        "    Wall,                    !- Surface Type",
        "    EXTWALL:LIVING,          !- Construction Name",
        "    LIVING ZONE,             !- Zone Name",
        "    ,                        !- Space Name",
        "    Outdoors,                !- Outside Boundary Condition",
        "    ,                        !- Outside Boundary Condition Object",
        "    SunExposed,              !- Sun Exposure",
        "    WindExposed,             !- Wind Exposure",
        "    0.5000000,               !- View Factor to Ground",
        "    4,                       !- Number of Vertices",
        "    0,1,1,  !- X,Y,Z ==> Vertex 1 {m}",
        "    0,1,0,  !- X,Y,Z ==> Vertex 2 {m}",
        "    0,0,0,  !- X,Y,Z ==> Vertex 3 {m}",
        "    0,0,1;  !- X,Y,Z ==> Vertex 4 {m}",
        "  BuildingSurface:Detailed,",
        "    Living:Floor,            !- Name",
        "    FLOOR,                   !- Surface Type",
        "    FLOOR:LIVING,            !- Construction Name",
        "    LIVING ZONE,             !- Zone Name",
        "    ,                        !- Space Name",
        "    Surface,                 !- Outside Boundary Condition",
        "    Living:Floor,            !- Outside Boundary Condition Object",
        "    NoSun,                   !- Sun Exposure",
        "    NoWind,                  !- Wind Exposure",
        "    0,                       !- View Factor to Ground",
        "    4,                       !- Number of Vertices",
        "    0,0,0,  !- X,Y,Z ==> Vertex 1 {m}",
        "    0,1,0,  !- X,Y,Z ==> Vertex 2 {m}",
        "    1,1,0,  !- X,Y,Z ==> Vertex 3 {m}",
        "    1,0,0;  !- X,Y,Z ==> Vertex 4 {m}",
        "  BuildingSurface:Detailed,",
        "    Living:Ceiling,          !- Name",
        "    ROOF,                 !- Surface Type",
        "    ROOF,          !- Construction Name",
        "    LIVING ZONE,             !- Zone Name",
        "    ,                        !- Space Name",
        "    Outdoors,                !- Outside Boundary Condition",
        "    ,                        !- Outside Boundary Condition Object",
        "    SunExposed,              !- Sun Exposure",
        "    WindExposed,             !- Wind Exposure",
        "    0,                       !- View Factor to Ground",
        "    4,                       !- Number of Vertices",
        "    0,1,1,  !- X,Y,Z ==> Vertex 1 {m}",
        "    0,0,1,  !- X,Y,Z ==> Vertex 2 {m}",
        "    1,0,1,  !- X,Y,Z ==> Vertex 3 {m}",
        "    1,1,1;  !- X,Y,Z ==> Vertex 4 {m}",
        "  ZoneProperty:LocalEnvironment,",
        "    LocEnv:LIVING ZONE,           !- Name",
        "    LIVING ZONE,                  !- Exterior Surface Name",
        "    OutdoorAirNode:0001;          !- Outdoor Air Node Name",
        "  OutdoorAir:Node,",
        "    OutdoorAirNode:0001,          !- Name",
        "    ,                             !- Height Above Ground",
        "    OutdoorAirNodeDryBulb:0001,   !- Drybulb Temperature Schedule Name",
        "    OutdoorAirNodeWetBulb:0001,   !- Wetbulb Schedule Name",
        "    OutdoorAirNodeWindSpeed:0001, !- Wind Speed Schedule Name",
        "    OutdoorAirNodeWindDir:0001;   !- Wind Direction Schedule Name",
        "  ScheduleTypeLimits,",
        "    Any Number;                   !- Name",
        "  Schedule:Compact,",
        "    OutdoorAirNodeDryBulb:0001,   !- Name",
        "    Any Number,                   !- Schedule Type Limits Name",
        "    Through: 12/31,               !- Field 1",
        "    For: AllDays,                 !- Field 2",
        "    Until: 24:00, 15.0;           !- Field 3",
        "  Schedule:Compact,",
        "    OutdoorAirNodeWetBulb:0001,   !- Name",
        "    Any Number,                   !- Schedule Type Limits Name",
        "    Through: 12/31,               !- Field 1",
        "    For: AllDays,                 !- Field 2",
        "    Until: 24:00, 12.0;           !- Field 3",
        "  Schedule:Compact,",
        "    OutdoorAirNodeWindSpeed:0001, !- Name",
        "    Any Number,                   !- Schedule Type Limits Name",
        "    Through: 12/31,               !- Field 1",
        "    For: AllDays,                 !- Field 2",
        "    Until: 24:00, 1.23;           !- Field 3",
        "  Schedule:Compact,",
        "    OutdoorAirNodeWindDir:0001,   !- Name",
        "    Any Number,                   !- Schedule Type Limits Name",
        "    Through: 12/31,               !- Field 1",
        "    For: AllDays,                 !- Field 2",
        "    Until: 24:00, 90;             !- Field 3"})
    AssertTrue(process_idf(idf_objects))
    self.state.init_state(self.state)
    var ErrorsFound: Bool = false
    HeatBalanceManager.GetZoneData(self.state, ErrorsFound)
    ExpectFalse(ErrorsFound)
    Material.GetMaterialData(self.state, ErrorsFound)
    ExpectFalse(ErrorsFound)
    HeatBalanceManager.GetConstructData(self.state, ErrorsFound)
    ExpectFalse(ErrorsFound)
    ExpectTrue(self.state.dataGlobal.AnyLocalEnvironmentsInModel)
    self.state.dataZoneEquip.ZoneEquipConfig.allocate(1)
    self.state.dataZoneEquip.ZoneEquipConfig[0].ZoneName = "LIVING ZONE"
    var controlledZoneEquipConfigNums: List[Int] = [1]
    self.state.dataHeatBal.Zone[0].IsControlled = true
    self.state.dataZoneEquip.ZoneEquipConfig[0].NumInletNodes = 2
    self.state.dataZoneEquip.ZoneEquipConfig[0].InletNode.allocate(2)
    self.state.dataZoneEquip.ZoneEquipConfig[0].InletNode[0] = 1
    self.state.dataZoneEquip.ZoneEquipConfig[0].InletNode[1] = 2
    self.state.dataZoneEquip.ZoneEquipConfig[0].NumExhaustNodes = 1
    self.state.dataZoneEquip.ZoneEquipConfig[0].ExhaustNode.allocate(1)
    self.state.dataZoneEquip.ZoneEquipConfig[0].ExhaustNode[0] = 3
    self.state.dataZoneEquip.ZoneEquipConfig[0].NumReturnNodes = 1
    self.state.dataZoneEquip.ZoneEquipConfig[0].ReturnNode.allocate(1)
    self.state.dataZoneEquip.ZoneEquipConfig[0].ReturnNode[0] = 4
    self.state.dataZoneEquip.ZoneEquipConfig[0].FixedReturnFlow.allocate(1)
    self.state.dataHeatBal.SurfTempEffBulkAir.allocate(6)
    self.state.dataHeatBalSurf.SurfHConvInt.allocate(6)
    self