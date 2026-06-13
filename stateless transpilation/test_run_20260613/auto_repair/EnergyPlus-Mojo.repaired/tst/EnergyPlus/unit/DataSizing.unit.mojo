from gtest import Test, TestFixture, EXPECT_TRUE, EXPECT_FALSE, EXPECT_EQ, EXPECT_NE, EXPECT_GT, EXPECT_NEAR
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataEnvironment import DataEnvironment
from EnergyPlus.DataHeatBalance import DataHeatBalance
from EnergyPlus.DataIPShortCuts import DataIPShortCuts
from EnergyPlus.DataSizing import DataSizing
from EnergyPlus.DataZoneEquipment import DataZoneEquipment
from EnergyPlus.HeatBalanceManager import HeatBalanceManager
from EnergyPlus.InputProcessing.InputProcessor import InputProcessor
from EnergyPlus.SizingManager import SizingManager
from EnergyPlus.ZoneEquipmentManager import ZoneEquipmentManager
from Fixtures.EnergyPlusFixture import EnergyPlusFixture
from nlohmann.json import json
from EnergyPlus.DataStringGlobals import DataStringGlobals
from EnergyPlus.UtilityRoutines import Util
from EnergyPlus.HVAC import HVAC

using EnergyPlus
using nlohmann::literals

@fixture
class EnergyPlusFixture(TestFixture):
    var state: EnergyPlusData

    def __init__(inout self):
        self.state = EnergyPlusData()

    def SetUp(inout self):
        self.state.init_state(self.state)

    def TearDown(inout self):

def test_resetHVACSizingGlobals():
    var state = EnergyPlusData()
    state.init_state(state)
    state.dataSize.ZoneEqSizing.allocate(1)
    state.dataSize.CurZoneEqNum = 1
    var FirstPass: Bool = True
    state.dataSize.DataTotCapCurveIndex = 1
    state.dataSize.DataPltSizCoolNum = 1
    state.dataSize.DataPltSizHeatNum = 1
    state.dataSize.DataWaterLoopNum = 1
    state.dataSize.DataCoilNum = 1
    state.dataSize.DataFanOp = HVAC.FanOp.Cycling
    state.dataSize.DataCoilIsSuppHeater = True
    state.dataSize.DataIsDXCoil = True
    state.dataSize.DataAutosizable = False
    state.dataSize.DataEMSOverrideON = True
    state.dataSize.DataScalableSizingON = True
    state.dataSize.DataScalableCapSizingON = True
    state.dataSize.DataSysScalableFlowSizingON = True
    state.dataSize.DataSysScalableCapSizingON = True
    state.dataSize.DataDesInletWaterTemp = 1.0
    state.dataSize.DataDesInletAirHumRat = 1.0
    state.dataSize.DataDesInletAirTemp = 1.0
    state.dataSize.DataDesOutletAirTemp = 1.0
    state.dataSize.DataDesOutletAirHumRat = 1.0
    state.dataSize.DataCoolCoilCap = 1.0
    state.dataSize.DataFlowUsedForSizing = 1.0
    state.dataSize.DataAirFlowUsedForSizing = 1.0
    state.dataSize.DataWaterFlowUsedForSizing = 1.0
    state.dataSize.DataCapacityUsedForSizing = 1.0
    state.dataSize.DataDesignCoilCapacity = 1.0
    state.dataSize.DataHeatSizeRatio = 2.0
    state.dataSize.DataEMSOverride = 1.0
    state.dataSize.DataBypassFrac = 1.0
    state.dataSize.DataFracOfAutosizedCoolingAirflow = 2.0
    state.dataSize.DataFracOfAutosizedHeatingAirflow = 2.0
    state.dataSize.DataFlowPerCoolingCapacity = 1.0
    state.dataSize.DataFlowPerHeatingCapacity = 1.0
    state.dataSize.DataFracOfAutosizedCoolingCapacity = 2.0
    state.dataSize.DataFracOfAutosizedHeatingCapacity = 2.0
    state.dataSize.DataAutosizedCoolingCapacity = 1.0
    state.dataSize.DataAutosizedHeatingCapacity = 1.0
    state.dataSize.DataConstantUsedForSizing = 1.0
    state.dataSize.DataFractionUsedForSizing = 1.0
    state.dataSize.DataNonZoneNonAirloopValue = 1.0
    state.dataSize.DataZoneNumber = 1
    state.dataSize.DataFanType = HVAC.FanType.Constant
    state.dataSize.DataFanIndex = 0
    state.dataSize.DataWaterCoilSizCoolDeltaT = 1.0
    state.dataSize.DataWaterCoilSizHeatDeltaT = 1.0
    state.dataSize.DataNomCapInpMeth = True
    state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum].AirFlow = True
    state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum].CoolingAirFlow = True
    state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum].HeatingAirFlow = True
    state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum].SystemAirFlow = True
    state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum].Capacity = True
    state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum].CoolingCapacity = True
    state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum].HeatingCapacity = True
    state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum].AirVolFlow = 1.0
    state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum].MaxHWVolFlow = 1.0
    state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum].MaxCWVolFlow = 1.0
    state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum].OAVolFlow = 1.0
    state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum].DesCoolingLoad = 1.0
    state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum].DesHeatingLoad = 1.0
    state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum].CoolingAirVolFlow = 1.0
    state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum].HeatingAirVolFlow = 1.0
    state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum].SystemAirVolFlow = 1.0
    EXPECT_NE(state.dataSize.DataTotCapCurveIndex, 0)
    EXPECT_NE(state.dataSize.DataDesInletWaterTemp, 0.0)
    EXPECT_NE(state.dataSize.DataHeatSizeRatio, 1.0)
    EXPECT_NE(Int(state.dataSize.DataFanType), Int(HVAC.FanType.Invalid))
    EXPECT_TRUE(state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum].AirFlow)
    EXPECT_FALSE(state.dataSize.DataAutosizable)
    EXPECT_TRUE(FirstPass)
    DataSizing.resetHVACSizingGlobals(state, state.dataSize.CurZoneEqNum, 0, FirstPass)
    EXPECT_FALSE(FirstPass)
    EXPECT_EQ(state.dataSize.DataTotCapCurveIndex, 0)
    EXPECT_EQ(state.dataSize.DataPltSizCoolNum, 0)
    EXPECT_EQ(state.dataSize.DataPltSizHeatNum, 0)
    EXPECT_EQ(state.dataSize.DataWaterLoopNum, 0)
    EXPECT_EQ(state.dataSize.DataCoilNum, 0)
    EXPECT_EQ(Int(state.dataSize.DataFanOp), Int(HVAC.FanOp.Invalid))
    EXPECT_FALSE(state.dataSize.DataCoilIsSuppHeater)
    EXPECT_FALSE(state.dataSize.DataIsDXCoil)
    EXPECT_TRUE(state.dataSize.DataAutosizable)
    EXPECT_FALSE(state.dataSize.DataEMSOverrideON)
    EXPECT_FALSE(state.dataSize.DataScalableSizingON)
    EXPECT_FALSE(state.dataSize.DataScalableCapSizingON)
    EXPECT_FALSE(state.dataSize.DataSysScalableFlowSizingON)
    EXPECT_FALSE(state.dataSize.DataSysScalableCapSizingON)
    EXPECT_EQ(state.dataSize.DataDesInletWaterTemp, 0.0)
    EXPECT_EQ(state.dataSize.DataDesInletAirHumRat, 0.0)
    EXPECT_EQ(state.dataSize.DataDesInletAirTemp, 0.0)
    EXPECT_EQ(state.dataSize.DataDesOutletAirTemp, 0.0)
    EXPECT_EQ(state.dataSize.DataDesOutletAirHumRat, 0.0)
    EXPECT_EQ(state.dataSize.DataCoolCoilCap, 0.0)
    EXPECT_EQ(state.dataSize.DataFlowUsedForSizing, 0.0)
    EXPECT_EQ(state.dataSize.DataAirFlowUsedForSizing, 0.0)
    EXPECT_EQ(state.dataSize.DataWaterFlowUsedForSizing, 0.0)
    EXPECT_EQ(state.dataSize.DataCapacityUsedForSizing, 0.0)
    EXPECT_EQ(state.dataSize.DataDesignCoilCapacity, 0.0)
    EXPECT_EQ(state.dataSize.DataHeatSizeRatio, 1.0)
    EXPECT_EQ(state.dataSize.DataEMSOverride, 0.0)
    EXPECT_EQ(state.dataSize.DataBypassFrac, 0.0)
    EXPECT_EQ(state.dataSize.DataFracOfAutosizedCoolingAirflow, 1.0)
    EXPECT_EQ(state.dataSize.DataFracOfAutosizedHeatingAirflow, 1.0)
    EXPECT_EQ(state.dataSize.DataFlowPerCoolingCapacity, 0.0)
    EXPECT_EQ(state.dataSize.DataFlowPerHeatingCapacity, 0.0)
    EXPECT_EQ(state.dataSize.DataFracOfAutosizedCoolingCapacity, 1.0)
    EXPECT_EQ(state.dataSize.DataFracOfAutosizedHeatingCapacity, 1.0)
    EXPECT_EQ(state.dataSize.DataAutosizedCoolingCapacity, 0.0)
    EXPECT_EQ(state.dataSize.DataAutosizedHeatingCapacity, 0.0)
    EXPECT_EQ(state.dataSize.DataConstantUsedForSizing, 0.0)
    EXPECT_EQ(state.dataSize.DataFractionUsedForSizing, 0.0)
    EXPECT_EQ(state.dataSize.DataNonZoneNonAirloopValue, 0.0)
    EXPECT_EQ(state.dataSize.DataZoneNumber, 0)
    EXPECT_EQ(Int(state.dataSize.DataFanType), Int(HVAC.FanType.Invalid))
    EXPECT_EQ(state.dataSize.DataFanIndex, 0)
    EXPECT_EQ(state.dataSize.DataWaterCoilSizCoolDeltaT, 0.0)
    EXPECT_EQ(state.dataSize.DataWaterCoilSizHeatDeltaT, 0.0)
    EXPECT_FALSE(state.dataSize.DataNomCapInpMeth)
    EXPECT_FALSE(state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum].AirFlow)
    EXPECT_FALSE(state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum].CoolingAirFlow)
    EXPECT_FALSE(state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum].HeatingAirFlow)
    EXPECT_FALSE(state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum].SystemAirFlow)
    EXPECT_FALSE(state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum].Capacity)
    EXPECT_FALSE(state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum].CoolingCapacity)
    EXPECT_FALSE(state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum].HeatingCapacity)
    EXPECT_EQ(state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum].AirVolFlow, 0.0)
    EXPECT_EQ(state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum].MaxHWVolFlow, 0.0)
    EXPECT_EQ(state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum].MaxCWVolFlow, 0.0)
    EXPECT_EQ(state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum].OAVolFlow, 0.0)
    EXPECT_EQ(state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum].DesCoolingLoad, 0.0)
    EXPECT_EQ(state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum].DesHeatingLoad, 0.0)
    EXPECT_EQ(state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum].CoolingAirVolFlow, 0.0)
    EXPECT_EQ(state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum].HeatingAirVolFlow, 0.0)
    EXPECT_EQ(state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum].SystemAirVolFlow, 0.0)
    FirstPass = True
    state.dataSize.CurZoneEqNum = 0
    DataSizing.resetHVACSizingGlobals(state, state.dataSize.CurZoneEqNum, 0, FirstPass)
    EXPECT_FALSE(FirstPass)
    state.dataSize.ZoneEqSizing.deallocate()
    state.dataSize.CurZoneEqNum = 1
    FirstPass = True
    DataSizing.resetHVACSizingGlobals(state, state.dataSize.CurZoneEqNum, 0, FirstPass)
    EXPECT_FALSE(FirstPass)

def test_OARequirements_calcDesignSpecificationOutdoorAir():
    var state = EnergyPlusData()
    state.init_state(state)
    var NumAlphas: Int = 4
    var NumNumbers: Int = 9
    state.dataIPShortCut.lNumericFieldBlanks.allocate(NumNumbers)
    state.dataIPShortCut.lAlphaFieldBlanks.allocate(NumAlphas)
    state.dataIPShortCut.cAlphaFieldNames.allocate(NumAlphas)
    state.dataIPShortCut.cNumericFieldNames.allocate(NumNumbers)
    state.dataIPShortCut.cAlphaArgs.allocate(NumAlphas)
    state.dataIPShortCut.rNumericArgs.allocate(NumNumbers)
    state.dataIPShortCut.lNumericFieldBlanks = False
    state.dataIPShortCut.lAlphaFieldBlanks = False
    state.dataIPShortCut.cAlphaFieldNames = " "
    state.dataIPShortCut.cNumericFieldNames = " "
    state.dataIPShortCut.cAlphaArgs = " "
    state.dataIPShortCut.rNumericArgs = 0.0
    state.dataInputProcessing.inputProcessor.epJSON = json.parse("""
    {
        "Zone": {
            "Zone 1" : {
                 "volume": 1200.0,
                 "floor_area": 400.0
            },
            "Zone 2" : {
                 "volume": 1200.0,
                 "floor_area": 400.0
            }
        },
        "Space": {
            "Space 1a" : {
                 "zone_name": "Zone 1",
                 "floor_area": 100.0
            },
            "Space 1b" : {
                 "zone_name": "Zone 1",
                 "floor_area": 100.0
            },
            "Space 1c" : {
                 "zone_name": "Zone 1",
                 "floor_area": 100.0
            },
            "Space 1d" : {
                 "zone_name": "Zone 1",
                 "floor_area": 100.0,
                 "volume": 300.0
            }
        },
        "DesignSpecification:OutdoorAir": {
            "DSOA Per Person": {
                "outdoor_air_flow_per_person": 0.0125,
                "outdoor_air_method": "Flow/Person"
            },
            "DSOA Per Area": {
                "outdoor_air_flow_per_zone_floor_area": 0.001,
                "outdoor_air_method": "Flow/Area"
            },
            "DSOA Per Zone": {
                "outdoor_air_flow_per_zone": 1.0,
                "outdoor_air_method": "Flow/Zone"
            },
            "DSOA ACH": {
                "outdoor_air_flow_air_changes_per_hour": 0.1,
                "outdoor_air_method": "AirChanges/Hour"
            },
            "DSOA Sum": {
                "outdoor_air_method": "Sum",
                "outdoor_air_flow_per_person": 0.0125,
                "outdoor_air_flow_per_zone_floor_area": 0.00025,
                "outdoor_air_flow_per_zone": 1.0,
                "outdoor_air_flow_air_changes_per_hour": 0.025
            }
        },
        "DesignSpecification:OutdoorAir:SpaceList": {
            "DSOA Zone 1 Spaces" : {
                 "space_specs": [
                    {
                        "space_name": "Space 1a",
                        "space_design_specification_outdoor_air_object_name": "DSOA Per Person"
                    },
                    {
                        "space_name": "Space 1b",
                        "space_design_specification_outdoor_air_object_name": "DSOA Per Area"
                    },
                    {
                        "space_name": "Space 1c",
                        "space_design_specification_outdoor_air_object_name": "DSOA Per Zone"
                    },
                    {
                        "space_name": "Space 1d",
                        "space_design_specification_outdoor_air_object_name": "DSOA ACH"
                    }
                ]
            }
        }
    }
    """)
    state.dataGlobal.isEpJSON = True
    state.dataInputProcessing.inputProcessor.initializeMaps()
    state.init_state(state)
    var ErrorsFound: Bool = False
    HeatBalanceManager.GetZoneData(state, ErrorsFound)
    var error_string: String = delimited_string(
        [format("   ** Warning ** Version: missing in IDF, processing for EnergyPlus version=\"{}\"", DataStringGlobals.MatchVersion),
         "   ** Warning ** No Timestep object found.  Number of TimeSteps in Hour defaulted to 4."])
    EXPECT_TRUE(compare_err_stream(error_string, True))
    EXPECT_FALSE(ErrorsFound)
    var zoneNum: Int = 1
    EXPECT_EQ("ZONE 1", state.dataHeatBal.Zone[zoneNum].Name)
    EXPECT_EQ(4, state.dataHeatBal.Zone[zoneNum].numSpaces)
    EXPECT_EQ("SPACE 1A", state.dataHeatBal.space[state.dataHeatBal.Zone[zoneNum].spaceIndexes[0]].Name)
    EXPECT_EQ("SPACE 1B", state.dataHeatBal.space[state.dataHeatBal.Zone[zoneNum].spaceIndexes[1]].Name)
    EXPECT_EQ("SPACE 1C", state.dataHeatBal.space[state.dataHeatBal.Zone[zoneNum].spaceIndexes[2]].Name)
    EXPECT_EQ("SPACE 1D", state.dataHeatBal.space[state.dataHeatBal.Zone[zoneNum].spaceIndexes[3]].Name)
    zoneNum = 2
    EXPECT_EQ("ZONE 2", state.dataHeatBal.Zone[zoneNum].Name)
    EXPECT_EQ(1, state.dataHeatBal.Zone[zoneNum].numSpaces)
    EXPECT_EQ("ZONE 2", state.dataHeatBal.space[state.dataHeatBal.Zone[zoneNum].spaceIndexes[0]].Name)
    SizingManager.GetOARequirements(state)
    state.dataZoneEquip.ZoneEquipConfig.allocate(state.dataGlobal.numSpaces)
    ZoneEquipmentManager.SetUpZoneSizingArrays(state)
    compare_err_stream("")
    var thisOAReqName: String = "DSOA ZONE 1 SPACES"
    var oaNum: Int = Util.FindItemInList(thisOAReqName, state.dataSize.OARequirements)
    EXPECT_TRUE(oaNum > 0)
    EXPECT_EQ(4, state.dataSize.OARequirements[oaNum].dsoaIndexes.size())
    state.dataHeatBal.spaceIntGain.allocate(state.dataGlobal.numSpaces)
    state.dataHeatBal.ZoneIntGain.allocate(state.dataGlobal.NumOfZones)
    var thisSpaceName: String = "SPACE 1A"
    var spaceNum: Int = Util.FindItemInList(thisSpaceName, state.dataHeatBal.space)
    state.dataHeatBal.space[spaceNum].FloorArea = 100.0
    state.dataHeatBal.space[spaceNum].TotOccupants = 10
    state.dataHeatBal.spaceIntGain[spaceNum].NOFOCC = 1
    state.dataHeatBal.space[spaceNum].maxOccupants = 12
    thisSpaceName = "SPACE 1B"
    spaceNum = Util.FindItemInList(thisSpaceName, state.dataHeatBal.space)
    state.dataHeatBal.space[spaceNum].FloorArea = 100.0
    thisSpaceName = "SPACE 1C"
    spaceNum = Util.FindItemInList(thisSpaceName, state.dataHeatBal.space)
    state.dataHeatBal.space[spaceNum].FloorArea = 100.0
    thisSpaceName = "SPACE 1D"
    spaceNum = Util.FindItemInList(thisSpaceName, state.dataHeatBal.space)
    state.dataHeatBal.space[spaceNum].FloorArea = 100.0
    state.dataHeatBal.space[spaceNum].Volume = 300.0
    var thisZoneName: String = "ZONE 2"
    zoneNum = Util.FindItemInList(thisZoneName, state.dataHeatBal.Zone)
    state.dataHeatBal.Zone[zoneNum].FloorArea = 400.0
    state.dataHeatBal.Zone[zoneNum].TotOccupants = 10
    state.dataHeatBal.ZoneIntGain[zoneNum].NOFOCC = 1
    state.dataHeatBal.Zone[zoneNum].maxOccupants = 12
    var UseOccSchFlag: Bool = False
    var UseMinOASchFlag: Bool = False
    thisZoneName = "ZONE 1"
    zoneNum = Util.FindItemInList(thisZoneName, state.dataHeatBal.Zone)
    state.dataHeatBal.Zone[zoneNum].FloorArea = 400.0
    thisOAReqName = "DSOA ZONE 1 SPACES"
    oaNum = Util.FindItemInList(thisOAReqName, state.dataSize.OARequirements)
    var zone1OA: Float64 = DataSizing.calcDesignSpecificationOutdoorAir(state, oaNum, zoneNum, UseOccSchFlag, UseMinOASchFlag)
    var expectedOA: Float64 = 0.0125 * 10.0 + 0.001 * 100.0 + 1.0 + 0.1 * 300.0 / 3600.0
    EXPECT_EQ(expectedOA, zone1OA)
    thisZoneName = "ZONE 2"
    zoneNum = Util.FindItemInList(thisZoneName, state.dataHeatBal.Zone)
    state.dataHeatBal.Zone[zoneNum].FloorArea = 400.0
    thisOAReqName = "DSOA SUM"
    oaNum = Util.FindItemInList(thisOAReqName, state.dataSize.OARequirements)
    var zone2OA: Float64 = DataSizing.calcDesignSpecificationOutdoorAir(state, oaNum, zoneNum, UseOccSchFlag, UseMinOASchFlag)
    EXPECT_EQ(expectedOA, zone2OA)

def test_GetCoilDesFlowT_Test():
    var state = EnergyPlusData()
    state.init_state(state)
    state.dataEnvrn.StdRhoAir = 1.1
    state.dataSize.SysSizInput.allocate(1)
    state.dataSize.FinalSysSizing.allocate(1)
    state.dataSize.SysSizPeakDDNum.allocate(1)
    state.dataSize.SysSizPeakDDNum[1].TimeStepAtTotCoolPk.allocate(2)
    state.dataSize.SysSizPeakDDNum[1].TimeStepAtSensCoolPk.allocate(2)
    state.dataSize.CalcSysSizing.allocate(1)
    state.dataSize.CalcSysSizing[1].SumZoneCoolLoadSeq.allocate(2)
    state.dataSize.CalcSysSizing[1].CoolZoneAvgTempSeq.allocate(2)
    state.dataSize.SysSizInput[1].AirPriLoopName = "MyAirloop"
    state.dataSize.FinalSysSizing[1].AirPriLoopName = "MyAirloop"
    state.dataSize.FinalSysSizing[1].CoolSupTemp = 12.3
    state.dataSize.FinalSysSizing[1].CoolSupHumRat = 0.008
    state.dataSize.FinalSysSizing[1].DesCoolVolFlow = 1.0
    state.dataSize.FinalSysSizing[1].MassFlowAtCoolPeak = state.dataSize.FinalSysSizing[1].DesCoolVolFlow * state.dataEnvrn.StdRhoAir
    state.dataSize.SysSizPeakDDNum[1].TotCoolPeakDD = 1
    state.dataSize.SysSizPeakDDNum[1].SensCoolPeakDD = 1
    state.dataSize.SysSizPeakDDNum[1].TimeStepAtTotCoolPk[1] = 1
    state.dataSize.SysSizPeakDDNum[1].TimeStepAtSensCoolPk[1] = 2
    state.dataSize.CalcSysSizing[1].SumZoneCoolLoadSeq[1] = 1000.0
    state.dataSize.CalcSysSizing[1].CoolZoneAvgTempSeq[1] = 24.0
    state.dataSize.CalcSysSizing[1].SumZoneCoolLoadSeq[2] = 500.0
    state.dataSize.CalcSysSizing[1].CoolZoneAvgTempSeq[2] = 22.0
    state.dataSize.CalcSysSizing[1].MixTempAtCoolPeak = 30.0
    state.dataSize.DataAirFlowUsedForSizing = 0.5
    var curSysNum: Int = 1
    var CpAirStd: Float64 = 1.1
    var DesCoilAirFlow: Float64 = 0.0
    var DesCoilExitTemp: Float64 = 0.0
    var DesCoilExitHumRat: Float64 = 0.0
    state.dataSize.SysSizInput[1].coolingPeakLoad = DataSizing.PeakLoad.TotalCooling
    state.dataSize.SysSizInput[1].CoolCapControl = DataSizing.CapacityControl.VAV
    DataSizing.GetCoilDesFlowT(state, curSysNum, CpAirStd, DesCoilAirFlow, DesCoilExitTemp, DesCoilExitHumRat)
    EXPECT_NEAR(DesCoilAirFlow, state.dataSize.FinalSysSizing[1].MassFlowAtCoolPeak / state.dataEnvrn.StdRhoAir, 0.00001)
    EXPECT_NEAR(DesCoilExitTemp, state.dataSize.FinalSysSizing[1].CoolSupTemp, 0.00001)
    EXPECT_NEAR(DesCoilExitHumRat, state.dataSize.FinalSysSizing[1].CoolSupHumRat, 0.00001)
    state.dataSize.SysSizInput[1].CoolCapControl = DataSizing.CapacityControl.OnOff
    DesCoilAirFlow = 0.0
    DesCoilExitTemp = 0.0
    DesCoilExitHumRat = 0.0
    DataSizing.GetCoilDesFlowT(state, curSysNum, CpAirStd, DesCoilAirFlow, DesCoilExitTemp, DesCoilExitHumRat)
    EXPECT_NEAR(DesCoilAirFlow, state.dataSize.DataAirFlowUsedForSizing, 0.00001)
    EXPECT_NEAR(DesCoilExitTemp, state.dataSize.FinalSysSizing[1].CoolSupTemp, 0.00001)
    EXPECT_NEAR(DesCoilExitHumRat, state.dataSize.FinalSysSizing[1].CoolSupHumRat, 0.00001)
    state.dataSize.SysSizInput[1].CoolCapControl = DataSizing.CapacityControl.VT
    DesCoilAirFlow = 0.0
    DesCoilExitTemp = 0.0
    DesCoilExitHumRat = 0.0
    DataSizing.GetCoilDesFlowT(state, curSysNum, CpAirStd, DesCoilAirFlow, DesCoilExitTemp, DesCoilExitHumRat)
    EXPECT_NEAR(DesCoilAirFlow, state.dataSize.FinalSysSizing[1].DesCoolVolFlow, 0.00001)
    EXPECT_NEAR(DesCoilExitTemp, state.dataSize.FinalSysSizing[1].CoolSupTemp, 0.00001)
    EXPECT_NEAR(DesCoilExitHumRat, 0.008005, 0.00001)
    DesCoilAirFlow = 0.0
    DesCoilExitTemp = 0.0
    DesCoilExitHumRat = 0.0
    state.dataSize.CalcSysSizing[1].SumZoneCoolLoadSeq[1] = 10.0
    DataSizing.GetCoilDesFlowT(state, curSysNum, CpAirStd, DesCoilAirFlow, DesCoilExitTemp, DesCoilExitHumRat)
    EXPECT_NEAR(DesCoilAirFlow, state.dataSize.FinalSysSizing[1].DesCoolVolFlow, 0.00001)
    EXPECT_GT(DesCoilExitTemp, state.dataSize.FinalSysSizing[1].CoolSupTemp)
    EXPECT_NEAR(DesCoilExitTemp, 15.735537, 0.00001)
    EXPECT_GT(DesCoilExitHumRat, state.dataSize.FinalSysSizing[1].CoolSupHumRat)
    EXPECT_NEAR(DesCoilExitHumRat, 0.01003, 0.00001)
    state.dataSize.SysSizInput[1].CoolCapControl = DataSizing.CapacityControl.Bypass
    DesCoilAirFlow = 0.0
    DesCoilExitTemp = 0.0
    DesCoilExitHumRat = 0.0
    DataSizing.GetCoilDesFlowT(state, curSysNum, CpAirStd, DesCoilAirFlow, DesCoilExitTemp, DesCoilExitHumRat)
    EXPECT_NEAR(DesCoilAirFlow, 0.805901, 0.00001)
    EXPECT_NEAR(DesCoilExitTemp, state.dataSize.FinalSysSizing[1].CoolSupTemp, 0.00001)
    EXPECT_NEAR(DesCoilExitHumRat, 0.008005, 0.00001)
    state.dataSize.SysSizInput[1].coolingPeakLoad = DataSizing.PeakLoad.SensibleCooling
    state.dataSize.SysSizInput[1].CoolCapControl = DataSizing.CapacityControl.VT
    DesCoilAirFlow = 0.0
    DesCoilExitTemp = 0.0
    DesCoilExitHumRat = 0.0
    DataSizing.GetCoilDesFlowT(state, curSysNum, CpAirStd, DesCoilAirFlow, DesCoilExitTemp, DesCoilExitHumRat)
    EXPECT_NEAR(DesCoilAirFlow, state.dataSize.FinalSysSizing[1].DesCoolVolFlow, 0.00001)
    EXPECT_NEAR(DesCoilExitTemp, state.dataSize.FinalSysSizing[1].CoolSupTemp, 0.00001)
    EXPECT_NEAR(DesCoilExitHumRat, 0.008005, 0.00001)
    state.dataSize.SysSizInput[1].CoolCapControl = DataSizing.CapacityControl.Bypass
    DesCoilAirFlow = 0.0
    DesCoilExitTemp = 0.0
    DesCoilExitHumRat = 0.0
    DataSizing.GetCoilDesFlowT(state, curSysNum, CpAirStd, DesCoilAirFlow, DesCoilExitTemp, DesCoilExitHumRat)
    EXPECT_NEAR(DesCoilAirFlow, state.dataSize.FinalSysSizing[1].DesCoolVolFlow, 0.00001)
    EXPECT_NEAR(DesCoilExitTemp, state.dataSize.FinalSysSizing[1].CoolSupTemp, 0.00001)
    EXPECT_NEAR(DesCoilExitHumRat, 0.008005, 0.00001)
    state.dataSize.CalcSysSizing[1].SumZoneCoolLoadSeq[2] = 5.0
    DesCoilAirFlow = 0.0
    DesCoilExitTemp = 0.0
    DesCoilExitHumRat = 0.0
    DataSizing.GetCoilDesFlowT(state, curSysNum, CpAirStd, DesCoilAirFlow, DesCoilExitTemp, DesCoilExitHumRat)
    EXPECT_NEAR(DesCoilAirFlow, 0.685436, 0.00001)
    EXPECT_NEAR(DesCoilExitTemp, state.dataSize.FinalSysSizing[1].CoolSupTemp, 0.00001)
    EXPECT_NEAR(DesCoilExitHumRat, 0.008005, 0.00001)