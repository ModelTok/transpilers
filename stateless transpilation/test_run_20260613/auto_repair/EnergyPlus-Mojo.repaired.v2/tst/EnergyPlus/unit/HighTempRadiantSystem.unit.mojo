from gtest import Test, TestFixture, EXPECT_TRUE, EXPECT_FALSE, ASSERT_TRUE
from .Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataHVACGlobals import *
from EnergyPlus.DataHeatBalance import *
from EnergyPlus.DataSizing import *
from EnergyPlus.DataSurfaces import *
from EnergyPlus.HighTempRadiantSystem import GetHighTempRadiantSystem, SizeHighTempRadiantSystem, HighTempRadSys, HighTempRadSysNumericFields
from EnergyPlus.DataSizing import DesignSizingType
from EnergyPlus.DataHVACGlobals import HVAC

def delimited_string(lines: List[String]) -> String:
    var result: String = ""
    for line in lines:
        result += line + "\n"
    return result
class HighTempRadiantSystemTest(EnergyPlusFixture):
    def HighTempRadiantSystemTest_GetHighTempRadiantSystem(self):
        var ErrorsFound: Bool
        var idf_objects: String = delimited_string([
            "  ZoneHVAC:HighTemperatureRadiant,",
            "    ZONERADHEATER,           !- Name",
            "    ,                        !- Availability Schedule Name",
            "	 ZONE1,                   !- Zone Name",
            "	 HeatingDesignCapacity,   !- Heating Design Capacity Method",
            "	 10000,                   !- Heating Design Capacity {W}",
            "	 ,                        !- Heating Design Capacity Per Floor Area {W/m2}",
            "	 ,                        !- Fraction of Autosized Heating Design Capacity",
            "	 Electricity,             !- Fuel Type",
            "	 1.0,                     !- Combustion Efficiency",
            "	 0.80,                    !- Fraction of Input Converted to Radiant Energy",
            "	 0.00,                    !- Fraction of Input Converted to Latent Energy",
            "	 0.00,                    !- Fraction of Input that Is Lost",
            "	 MeanAirTemperature,      !- Temperature Control Type",
            "	 2.0,                     !- Heating Throttling Range {deltaC}",
            "	 Radiant Heating Setpoints, !- Heating Setpoint Temperature Schedule Name",
            "	 0.04,                    !- Fraction of Radiant Energy Incident on People",
            "	 WALL1,                   !- Surface 1 Name",
            "	 0.80;                    !- Fraction of Radiant Energy to Surface 1",
        ])
        ASSERT_TRUE(process_idf(idf_objects))
        self.state.init_state(self.state)
        self.state.dataHeatBal.Zone.allocate(1)
        self.state.dataHeatBal.Zone[0].Name = "ZONE1"
        self.state.dataSurface.Surface.allocate(1)
        self.state.dataSurface.Surface[0].Name = "WALL1"
        self.state.dataSurface.Surface[0].Zone = 1
        self.state.dataSurface.surfIntConv.allocate(1)
        self.state.dataSurface.surfIntConv[0].getsRadiantHeat = False
        ErrorsFound = False
        GetHighTempRadiantSystem(self.state, ErrorsFound)
        var error_string01: String = delimited_string([
            "   ** Severe  ** GetHighTempRadiantSystem: ZoneHVAC:HighTemperatureRadiant = ZONERADHEATER",
            "   **   ~~~   ** Heating Setpoint Temperature Schedule Name = RADIANT HEATING SETPOINTS, item not found.",
            "   ** Severe  ** Fraction of radiation distributed to surfaces and people sums up to less than 1 for ZONERADHEATER",
            "   **   ~~~   ** This would result in some of the radiant energy delivered by the high temp radiant heater being lost.",
            "   **   ~~~   ** The sum of all radiation fractions to surfaces = 0.80000",
            "   **   ~~~   ** The radiant fraction to people = 0.04000",
            "   **   ~~~   ** So, all radiant fractions including surfaces and people = 0.84000",
            "   **   ~~~   ** This means that the fraction of radiant energy that would be lost from the high temperature radiant heater would be = 0.16000",
            "   **   ~~~   ** Please check and correct this so that all radiant energy is accounted for in ZoneHVAC:HighTemperatureRadiant = ZONERADHEATER"
        ])
        EXPECT_TRUE(compare_err_stream(error_string01, True))
        EXPECT_TRUE(ErrorsFound)
        EXPECT_EQ(self.state.dataSurface.allGetsRadiantHeatSurfaceList[0], 1)
        EXPECT_TRUE(self.state.dataSurface.surfIntConv[0].getsRadiantHeat)

    def HighTempRadiantSystemTest_SizeHighTempRadiantSystemScalableFlagSetTest(self):
        self.state.init_state(self.state)
        var RadSysNum: Int
        var SizingTypesNum: Int
        self.state.dataSize.DataScalableCapSizingON = False
        self.state.dataSize.CurZoneEqNum = 1
        RadSysNum = 1
        self.state.dataHighTempRadSys.HighTempRadSys.allocate(RadSysNum)
        self.state.dataHighTempRadSys.HighTempRadSysNumericFields.allocate(RadSysNum)
        self.state.dataHighTempRadSys.HighTempRadSysNumericFields[RadSysNum - 1].FieldNames.allocate(1)
        self.state.dataHighTempRadSys.HighTempRadSys[RadSysNum - 1].Name = "TESTSCALABLEFLAG"
        self.state.dataHighTempRadSys.HighTempRadSys[RadSysNum - 1].ZonePtr = 1
        self.state.dataHighTempRadSys.HighTempRadSys[RadSysNum - 1].HeatingCapMethod = DesignSizingType.CapacityPerFloorArea
        self.state.dataHighTempRadSys.HighTempRadSys[RadSysNum - 1].ScaledHeatingCapacity = 100.0
        self.state.dataSize.ZoneEqSizing.allocate(1)
        self.state.dataHeatBal.Zone.allocate(1)
        self.state.dataHeatBal.Zone[0].FloorArea = 10.0
        SizingTypesNum = HVAC.NumOfSizingTypes
        if SizingTypesNum < 1:
            SizingTypesNum = 1
        self.state.dataSize.ZoneEqSizing[self.state.dataSize.CurZoneEqNum - 1].SizingMethod.allocate(HVAC.NumOfSizingTypes)
        SizeHighTempRadiantSystem(self.state, RadSysNum)
        EXPECT_FALSE(self.state.dataSize.DataScalableSizingON)