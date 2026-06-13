from Fixtures.EnergyPlusFixture import EnergyPlusFixture, process_idf, delimited_string, match_err_stream
from Data.EnergyPlusData import EnergyPlusData
from DataSizing import FinalSysSizing
from PoweredInductionUnits import PIU
from SimulationManager import ManageSimulation
from SingleDuct import sd_airterminal

struct EnergyPlusFixture:
    var state: EnergyPlusData

    def __init__(inout self):
        # Initialize state as needed (placeholder)
        ...

    def SimplifiedProcedureTest1(self) raises:
        var idf_objects: String = delimited_string({
            " Output:Diagnostics, DisplayExtraWarnings;",
            " Timestep, 4;",
            " BUILDING, Standard621 Simplified Procedure Test, 0.0, Suburbs, .04, .4, FullExterior, 25, 6;",
            " SimulationControl, YES, YES, NO, YES, NO;",
            " ",
            "  Site:Location,",
            "    Miami Intl Ap FL USA TMY3 WMO=722020E,    !- Name",
            "    25.82,                 !- Latitude {deg}",
            "    -80.30,                !- Longitude {deg}",
            "    -5.00,                 !- Time Zone {hr}",
            "    11;                    !- Elevation {m}",
            " ",
            "SizingPeriod:DesignDay,",
            " Miami Intl Ap Ann Clg .4% Condns DB/MCWB, !- Name",
            " 7,                        !- Month",
            " 21,                       !- Day of Month",
            " SummerDesignDay,          !- Day Type",
            " 31.7,                     !- Maximum Dry - Bulb Temperature{ C }",
            " 10.0,                      !- Daily Dry - Bulb Temperature Range{ deltaC }",
            " ,                         !- Dry - Bulb Temperature Range Modifier Type",
            " ,                         !- Dry - Bulb Temperature Range Modifier Day Schedule Name",
            " Wetbulb,                  !- Humidity Condition Type",
            " 22.7,                     !- Wetbulb or DewPoint at Maximum Dry - Bulb{ C }",
            " ,                         !- Humidity Condition Day Schedule Name",
            " ,                         !- Humidity Ratio at Maximum Dry - Bulb{ kgWater / kgDryAir }",
            " ,                         !- Enthalpy at Maximum Dry - Bulb{ J / kg }",
            " ,                         !- Daily Wet - Bulb Temperature Range{ deltaC }",
            " 101217.,                  !- Barometric Pressure{ Pa }",
            " 3.8,                      !- Wind Speed{ m / s }",
            " 340,                      !- Wind Direction{ deg }",
            " No,                       !- Rain Indicator",
            " No,                       !- Snow Indicator",
            " No,                       !- Daylight Saving Time Indicator",
            " ASHRAEClearSky,           !- Solar Model Indicator",
            " ,                         !- Beam Solar Day Schedule Name",
            " ,                         !- Diffuse Solar Day Schedule Name",
            " ,                         !- ASHRAE Clear Sky Optical Depth for Beam Irradiance( taub ) { dimensionless }",
            " ,                         !- ASHRAE Clear Sky Optical Depth for Diffuse Irradiance( taud ) { dimensionless }",
            " 1.00;                     !- Sky Clearness",
            " ",
            "SizingPeriod:DesignDay,",
            " Miami Intl Ap Ann Htg 99.6% Condns DB, !- Name",
            " 1,                        !- Month",
            " 21,                       !- Day of Month",
            " WinterDesignDay,          !- Day Type",
            " 8.7,                      !- Maximum Dry - Bulb Temperature{ C }",
            " 0.0,                      !- Daily Dry - Bulb Temperature Range{ deltaC }",
            " ,                         !- Dry - Bulb Temperature Range Modifier Type",
            " ,                         !- Dry - Bulb Temperature Range Modifier Day Schedule Name",
            " Wetbulb,                  !- Humidity Condition Type",
            " 8.7,                      !- Wetbulb or DewPoint at Maximum Dry - Bulb{ C }",
            " ,                         !- Humidity Condition Day Schedule Name",
            " ,                         !- Humidity Ratio at Maximum Dry - Bulb{ kgWater / kgDryAir }",
            " ,                         !- Enthalpy at Maximum Dry - Bulb{ J / kg }",
            " ,                         !- Daily Wet - Bulb Temperature Range{ deltaC }",
            " 101217.,                  !- Barometric Pressure{ Pa }",
            " 3.8,                      !- Wind Speed{ m / s }",
            " 340,                      !- Wind Direction{ deg }",
            " No,                       !- Rain Indicator",
            " No,                       !- Snow Indicator",
            " No,                       !- Daylight Saving Time Indicator",
            " ASHRAEClearSky,           !- Solar Model Indicator",
            " ,                         !- Beam Solar Day Schedule Name",
            " ,                         !- Diffuse Solar Day Schedule Name",
            " ,                         !- ASHRAE Clear Sky Optical Depth for Beam Irradiance( taub ) { dimensionless }",
            " ,                         !- ASHRAE Clear Sky Optical Depth for Diffuse Irradiance( taud ) { dimensionless }",
            " 0.00;                     !- Sky Clearness",
            " ",
            "Zone,",
            "  Space,                   !- Name",
            "  0.0000,                  !- Direction of Relative North {deg}",
            "  0.0000,                  !- X Origin {m}",
            "  0.0000,                  !- Y Origin {m}",
            "  0.0000,                  !- Z Origin {m}",
            "  1,                       !- Type",
            "  1,                       !- Multiplier",
            "  2.4,                     !- Ceiling Height {m}",
            "  ,                        !- Volume {m3}",
            "  autocalculate,           !- Floor Area {m2}",
            "  ,                        !- Zone Inside Convection Algorithm",
            "  ,                        !- Zone Outside Convection Algorithm",
            "  Yes;                     !- Part of Total Floor Area",
            " ",
            "ZoneGroup,",
            " Zone Group,               !- Name",
            " Zone List,                !- Zone List Name",
            " 10;                       !- Zone List Multiplier",
            " ",
            "ZoneList,",
            " Zone List,                !- Name",
            " Spacex10;                 !- Zone 1 Name",
            " ",
            "Zone,",
            "  Spacex10,                !- Name",
            "  0.0000,                  !- Direction of Relative North {deg}",
            "  0.0000,                  !- X Origin {m}",
            "  0.0000,                  !- Y Origin {m}",
            "  0.0000,                  !- Z Origin {m}",
            "  1,                       !- Type",
            "  1,                       !- Multiplier",
            "  2.4,                     !- Ceiling Height {m}",
            "  ,                        !- Volume {m3}",
            "  autocalculate,           !- Floor Area {m2}",
            "  ,                        !- Zone Inside Convection Algorithm",
            "  ,                        !- Zone Outside Convection Algorithm",
            "  Yes;                     !- Part of Total Floor Area",
            " ",
            "Sizing:Zone,",
            " Space,                    !- Zone or ZoneList Name",
            " SupplyAirTemperature,     !- Zone Cooling Design Supply Air Temperature Input Method",
            " 12.,                      !- Zone Cooling Design Supply Air Temperature{ C }",
            " ,                         !- Zone Cooling Design Supply Air Temperature Difference{ deltaC }",
            " SupplyAirTemperature,     !- Zone Heating Design Supply Air Temperature Input Method",
            " 50.,                      !- Zone Heating Design Supply Air Temperature{ C }",
            " ,                         !- Zone Heating Design Supply Air Temperature Difference{ deltaC }",
            " 0.008,                    !- Zone Cooling Design Supply Air Humidity Ratio{ kgWater / kgDryAir }",
            " 0.008,                    !- Zone Heating Design Supply Air Humidity Ratio{ kgWater / kgDryAir }",
            " Space DSOA Design OA Spec,  !- Design Specification Outdoor Air Object Name",
            " 0.0,                      !- Zone Heating Sizing Factor",
            " 0.0,                      !- Zone Cooling Sizing Factor",
            " DesignDay,                !- Cooling Design Air Flow Method",
            " 0,                        !- Cooling Design Air Flow Rate{ m3 / s }",
            " ,                         !- Cooling Minimum Air Flow per Zone Floor Area{ m3 / s - m2 }",
            " ,                         !- Cooling Minimum Air Flow{ m3 / s }",
            " ,                         !- Cooling Minimum Air Flow Fraction",
            " DesignDay,                !- Heating Design Air Flow Method",
            " 0,                        !- Heating Design Air Flow Rate{ m3 / s }",
            " ,                         !- Heating Maximum Air Flow per Zone Floor Area{ m3 / s - m2 }",
            " ,                         !- Heating Maximum Air Flow{ m3 / s }",
            " ;                         !- Heating Maximum Air Flow Fraction",
            " ",
            ...
        })
        assert_true(process_idf(idf_objects))
        ManageSimulation(self.state[])
        assert_approx_equal(2.154067, self.state.dataSize.FinalSysSizing[0].DesOutAirVolFlow, 0.0001)
        assert_equal(0.0, self.state.dataSingleDuct.sd_airterminal[0].ZoneFixedMinAir)
        assert_approx_equal(2.658660, self.state.dataSingleDuct.sd_airterminal[0].MaxAirVolFlowRate, 0.0001)
        assert_equal(1.0, self.state.dataPowerInductionUnits.PIU[0].MinPriAirFlowFrac)
        assert_approx_equal(0.089244, self.state.dataPowerInductionUnits.PIU[0].MaxTotAirVolFlow, 0.0001)

    def SimplifiedProcedureTest2(self) raises:
        var idf_objects: String = delimited_string({ ... })  # same IDF as Test1
        assert_true(process_idf(idf_objects))
        ManageSimulation(self.state[])
        assert_approx_equal(2.154067, self.state.dataSize.FinalSysSizing[0].DesOutAirVolFlow, 0.0001)
        assert_equal(0.20, self.state.dataSingleDuct.sd_airterminal[0].ZoneFixedMinAir)
        assert_equal(0.20, self.state.dataSingleDuct.sd_airterminal[0].MaxAirVolFlowRate)
        var error_string: String = delimited_string({
            "** Warning ** SingleDuctSystem:SizeSys: Maximum air flow rate for SPACEX10 AIR TERMINAL is potentially too low.",
        })
        assert_true(match_err_stream(error_string))
        assert_equal(1.0, self.state.dataPowerInductionUnits.PIU[0].MinPriAirFlowFrac)
        assert_approx_equal(0.089244, self.state.dataPowerInductionUnits.PIU[0].MaxTotAirVolFlow, 0.0001)

    def SimplifiedProcedureTest3(self) raises:
        var idf_objects: String = delimited_string({ ... })  # variant IDF
        assert_true(process_idf(idf_objects))
        ManageSimulation(self.state[])
        assert_approx_equal(2.154067, self.state.dataSize.FinalSysSizing[0].DesOutAirVolFlow, 0.0001)
        assert_approx_equal(2.658660, self.state.dataSingleDuct.sd_airterminal[0].ZoneFixedMinAir, 0.0001)
        assert_approx_equal(2.658660, self.state.dataSingleDuct.sd_airterminal[0].MaxAirVolFlowRate, 0.0001)
        assert_approx_equal(1.0, self.state.dataPowerInductionUnits.PIU[0].MinPriAirFlowFrac, 0.0001)
        assert_approx_equal(0.089244, self.state.dataPowerInductionUnits.PIU[0].MaxTotAirVolFlow, 0.0001)
        assert_approx_equal(0.05, self.state.dataPowerInductionUnits.PIU[0].MaxPriAirVolFlow, 0.0001)
        var error_string: String = delimited_string({
            "   ** Warning ** SingleDuctSystem:SizeSys: Maximum primary air flow rate for SPACE AIR TERMINAL is potentially too low.",
        })
        assert_true(match_err_stream(error_string))