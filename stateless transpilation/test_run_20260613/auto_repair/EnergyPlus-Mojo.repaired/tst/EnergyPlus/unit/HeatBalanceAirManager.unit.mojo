from gtest import *
from EnergyPlus.Data.EnergyPlusData import *
from EnergyPlus.DataHeatBalFanSys import *
from EnergyPlus.DataHeatBalance import *
from EnergyPlus.DataIPShortCuts import *
from EnergyPlus.HeatBalanceAirManager import *
from EnergyPlus.HeatBalanceManager import *
from EnergyPlus.IOFiles import *
from EnergyPlus.InputProcessing.InputProcessor import *
from EnergyPlus.SimulationManager import *
from EnergyPlus.SurfaceGeometry import *
from nlohmann.json import json as json
from Fixtures.EnergyPlusFixture import *
from Util import *
from Sched import *

# from nlohmann::literals
# using namespace nlohmann::literals; // Mojo equivalent: use json.parse

# namespace EnergyPlus
module EnergyPlus:
    # Test fixture assumed from import
    @fixture
    class EnergyPlusFixture:
        # state will be provided by fixture
        var state: EnergyPlusData

    def test_HeatBalanceAirManager_RoomAirModelType_Test():
        let idf_objects = delimited_string([
            "  RoomAirModelType,",
            "  Skinny_Model,            !- Name",
            "  South Skin,              !- Zone Name",
            "  AirflowNetwork,          !- Room - Air Modeling Type",
            "  Direct;                  !- Air Temperature Coupling Strategy",
            "  RoomAirModelType,",
            "  Phat_Model,              !- Name",
            "  Thermal Zone,            !- Zone Name",
            "  AirflowNetwork,          !- Room - Air Modeling Type",
            "  Direct;                  !- Air Temperature Coupling Strategy",
        ])
        assert_true(process_idf(idf_objects))
        state.init_state(state)
        state.dataGlobal.NumOfZones = 2
        state.dataHeatBal.Zone.allocate(2)
        state.dataHeatBal.Zone[0].Name = "SOUTH SKIN"
        state.dataHeatBal.Zone[1].Name = "THERMAL ZONE"
        var ErrorsFound = false
        HeatBalanceAirManager.GetRoomAirModelParameters(state, ErrorsFound)
        assert_true(ErrorsFound)
        let error_string = delimited_string([
            "   ** Severe  ** In RoomAirModelType = SKINNY_MODEL: Room-Air Modeling Type = AIRFLOWNETWORK.",
            "   **   ~~~   ** This model requires AirflowNetwork:* objects to form a complete network, including AirflowNetwork:Intrazone:Node and AirflowNetwork:Intrazone:Linkage.",
            "   **   ~~~   ** AirflowNetwork:SimulationControl not found.",
            "   ** Severe  ** In RoomAirModelType = PHAT_MODEL: Room-Air Modeling Type = AIRFLOWNETWORK.",
            "   **   ~~~   ** This model requires AirflowNetwork:* objects to form a complete network, including AirflowNetwork:Intrazone:Node and AirflowNetwork:Intrazone:Linkage.",
            "   **   ~~~   ** AirflowNetwork:SimulationControl not found.",
            "   ** Severe  ** Errors found in processing input for RoomAirModelType",
        ])
        assert_true(compare_err_stream(error_string, true))

    def test_HeatBalanceAirManager_GetInfiltrationAndVentilation():
        state.dataInputProcessing.inputProcessor.epJSON = json.parse("""
        {
            "Zone": {
                "Zone 1" : {
                    "volume": 100.0
                },
                "Zone 2" : {
                    "volume": 2000.0,
                     "floor_area": 1000.0
                }
            },
            "Space": {
                "Space 1a" : {
                     "zone_name": "Zone 1",
                     "floor_area": 10.0
                },
                "Space 1b" : {
                     "zone_name": "Zone 1",
                     "floor_area": 100.0
                }
            },
            "SpaceList": {
                "SomeSpaces" : {
                     "spaces": [
                        {
                            "space_name": "Space 1a"
                        },
                        {
                            "space_name": "Space 1b"
                        }
                    ]
                }
            },
            "ZoneList": {
                "AllZones" : {
                     "zones": [
                        {
                            "zone_name": "Zone 1"
                        },
                        {
                            "zone_name": "Zone 2"
                        }
                    ]
                }
            },
            "Building": {
                "Some building somewhere": {
                }
            },
            "GlobalGeometryRules": {
                "GlobalGeometryRules 1": {
                    "coordinate_system": "Relative",
                    "starting_vertex_position": "UpperLeftCorner",
                    "vertex_entry_direction": "Counterclockwise"
                }
            },
            "Construction": {
                "ext-slab": {
                    "outside_layer": "HW CONCRETE"
                }
            },
            "Material": {
                "HW CONCRETE": {
                    "conductivity": 1.311,
                    "density": 2240.0,
                    "roughness": "Rough",
                    "solar_absorptance": 0.7,
                    "specific_heat": 836.8,
                    "thermal_absorptance": 0.9,
                    "thickness": 0.1016,
                    "visible_absorptance": 0.7
                }
            },
            "BuildingSurface:Detailed": {
                "Dummy Space 1a Floor": {
                    "zone_name": "Zone 1",
                    "space_name": "Space 1a",
                    "surface_type": "Floor",
                    "construction_name": "ext-slab",
                    "number_of_vertices": 4,
                    "outside_boundary_condition": "adiabatic",
                    "sun_exposure": "nosun",
                    "vertices": [
                        {
                            "vertex_x_coordinate": 45.3375,
                            "vertex_y_coordinate": 28.7006,
                            "vertex_z_coordinate": 0.0
                        },
                        {
                            "vertex_x_coordinate": 45.3375,
                            "vertex_y_coordinate": 4.5732,
                            "vertex_z_coordinate": 0.0
                        },
                        {
                            "vertex_x_coordinate": 4.5732,
                            "vertex_y_coordinate": 4.5732,
                            "vertex_z_coordinate": 0.0
                        },
                        {
                            "vertex_x_coordinate": 4.5732,
                            "vertex_y_coordinate": 28.7006,
                            "vertex_z_coordinate": 0.0
                        }
                    ]
                },
                "Dummy Space 1b Floor": {
                    "zone_name": "Zone 1",
                    "space_name": "Space 1b",
                    "surface_type": "Floor",
                    "construction_name": "ext-slab",
                    "number_of_vertices": 4,
                    "outside_boundary_condition": "adiabatic",
                    "sun_exposure": "nosun",
                    "vertices": [
                        {
                            "vertex_x_coordinate": 45.3375,
                            "vertex_y_coordinate": 28.7006,
                            "vertex_z_coordinate": 0.0
                        },
                        {
                            "vertex_x_coordinate": 45.3375,
                            "vertex_y_coordinate": 4.5732,
                            "vertex_z_coordinate": 0.0
                        },
                        {
                            "vertex_x_coordinate": 4.5732,
                            "vertex_y_coordinate": 4.5732,
                            "vertex_z_coordinate": 0.0
                        },
                        {
                            "vertex_x_coordinate": 4.5732,
                            "vertex_y_coordinate": 28.7006,
                            "vertex_z_coordinate": 0.0
                        }
                    ]
                },
                "Dummy Zone 2 Floor": {
                    "zone_name": "Zone 2",
                    "surface_type": "Floor",
                    "construction_name": "ext-slab",
                    "number_of_vertices": 4,
                    "outside_boundary_condition": "adiabatic",
                    "sun_exposure": "nosun",
                    "vertices": [
                        {
                            "vertex_x_coordinate": 45.3375,
                            "vertex_y_coordinate": 28.7006,
                            "vertex_z_coordinate": 0.0
                        },
                        {
                            "vertex_x_coordinate": 45.3375,
                            "vertex_y_coordinate": 4.5732,
                            "vertex_z_coordinate": 0.0
                        },
                        {
                            "vertex_x_coordinate": 4.5732,
                            "vertex_y_coordinate": 4.5732,
                            "vertex_z_coordinate": 0.0
                        },
                        {
                            "vertex_x_coordinate": 4.5732,
                            "vertex_y_coordinate": 28.7006,
                            "vertex_z_coordinate": 0.0
                        }
                    ]
                }
            },
            "ZoneInfiltration:DesignFlowRate": {
                "Zone1Infiltration": {
                    "design_flow_rate_calculation_method": "Flow/Area",
                    "flow_rate_per_floor_area": 1.0,
                    "zone_or_zonelist_or_space_or_spacelist_name": "Zone 1",
                    "density_basis": "Standard"
                },
                "Zone2Infiltration": {
                    "design_flow_rate_calculation_method": "Flow/Area",
                    "flow_rate_per_floor_area": 2.0,
                    "zone_or_zonelist_or_space_or_spacelist_name": "Zone 2",
                    "density_basis": "Indoor"
                },
                "Space1aInfiltration": {
                    "design_flow_rate_calculation_method": "Flow/Area",
                    "flow_rate_per_floor_area": 3.0,
                    "zone_or_zonelist_or_space_or_spacelist_name": "Space 1a",
                    "density_basis": "Outdoor"
                },
                "Space1bInfiltration": {
                    "design_flow_rate_calculation_method": "Flow/Area",
                    "flow_rate_per_floor_area": 4.0,
                    "zone_or_zonelist_or_space_or_spacelist_name": "Space 1b"
                },
                "SomeSpacesInfiltration": {
                    "design_flow_rate_calculation_method": "Flow/Area",
                    "flow_rate_per_floor_area": 5.0,
                    "zone_or_zonelist_or_space_or_spacelist_name": "SomeSpaces"
                },
                "AllZonesInfiltration": {
                    "design_flow_rate_calculation_method": "Flow/Area",
                    "flow_rate_per_floor_area": 6.0,
                    "zone_or_zonelist_or_space_or_spacelist_name": "AllZones"
                }
            },
            "ZoneVentilation:DesignFlowRate": {
                "Zone1Ventilation": {
                    "design_flow_rate_calculation_method": "Flow/Area",
                    "flow_rate_per_floor_area": 1.0,
                    "zone_or_zonelist_or_space_or_spacelist_name": "Zone 1",
                    "density_basis": "Standard"
                },
                "Zone2Ventilation": {
                    "design_flow_rate_calculation_method": "Flow/Area",
                    "flow_rate_per_floor_area": 2.0,
                    "zone_or_zonelist_or_space_or_spacelist_name": "Zone 2",
                    "density_basis": "Indoor"
                },
                "Space1aVentilation": {
                    "design_flow_rate_calculation_method": "Flow/Area",
                    "flow_rate_per_floor_area": 3.0,
                    "zone_or_zonelist_or_space_or_spacelist_name": "Space 1a",
                    "density_basis": "Outdoor"
                },
                "Space1bVentilation": {
                    "design_flow_rate_calculation_method": "Flow/Area",
                    "flow_rate_per_floor_area": 4.0,
                    "zone_or_zonelist_or_space_or_spacelist_name": "Space 1b"
                },
                "SomeSpacesVentilation": {
                    "design_flow_rate_calculation_method": "Flow/Area",
                    "flow_rate_per_floor_area": 5.0,
                    "zone_or_zonelist_or_space_or_spacelist_name": "SomeSpaces"
                },
                "AllZonesVentilation": {
                    "design_flow_rate_calculation_method": "Flow/Area",
                    "flow_rate_per_floor_area": 6.0,
                    "zone_or_zonelist_or_space_or_spacelist_name": "AllZones"
                }
            }
        }
        """)
        state.dataGlobal.isEpJSON = true
        state.dataInputProcessing.inputProcessor.initializeMaps()
        var MaxArgs = 0
        var MaxAlpha = 0
        var MaxNumeric = 0
        state.dataInputProcessing.inputProcessor.getMaxSchemaArgs(MaxArgs, MaxAlpha, MaxNumeric)
        state.dataIPShortCut.cAlphaFieldNames.allocate(MaxAlpha)
        state.dataIPShortCut.cAlphaArgs.allocate(MaxAlpha)
        state.dataIPShortCut.lAlphaFieldBlanks.dimension(MaxAlpha, false)
        state.dataIPShortCut.cNumericFieldNames.allocate(MaxNumeric)
        state.dataIPShortCut.rNumericArgs.dimension(MaxNumeric, 0.0)
        state.dataIPShortCut.lNumericFieldBlanks.dimension(MaxNumeric, false)
        var ErrorsFound = false
        state.init_state(state)
        HeatBalanceManager.GetHeatBalanceInput(state)
        let error_string = delimited_string([
            EnergyPlus.format("   ** Warning ** Version: missing in IDF, processing for EnergyPlus version=\"{}\"", DataStringGlobals.MatchVersion),
            "   ** Warning ** No Timestep object found.  Number of TimeSteps in Hour defaulted to 4.",
            "   ** Warning ** GetSurfaceData: Entered Space Floor Area(s) differ more than 5% from calculated Space Floor Area(s).",
            "   **   ~~~   ** ...use Output:Diagnostics,DisplayExtraWarnings; to show more details on individual Spaces.",
            "   ** Warning ** CalculateZoneVolume: 1 zone is not fully enclosed. For more details use:  Output:Diagnostics,DisplayExtrawarnings; ",
            "   ** Warning ** CalcApproximateViewFactors: Zero area for all other zone surfaces.",
            "   **   ~~~   ** Happens for Surface=\"DUMMY SPACE 1A FLOOR\" in Zone=ZONE 1",
            "   ** Warning ** CalcApproximateViewFactors: Zero area for all other zone surfaces.",
            "   **   ~~~   ** Happens for Surface=\"DUMMY SPACE 1B FLOOR\" in Zone=ZONE 1",
            "   ** Warning ** Surfaces in Zone/Enclosure=\"ZONE 1\" do not define an enclosure.",
            "   **   ~~~   ** Number of surfaces <= 3, view factors are set to force reciprocity but may not fulfill completeness.",
            "   **   ~~~   ** Reciprocity means that radiant exchange between two surfaces will match and not lead to an energy loss.",
            "   **   ~~~   ** Completeness means that all of the view factors between a surface and the other surfaces in a zone add up to unity.",
            "   **   ~~~   ** So, when there are three or less surfaces in a zone, EnergyPlus will make sure there are no losses of energy but",
            "   **   ~~~   ** it will not exchange the full amount of radiation with the rest of the zone as it would if there was a completed enclosure."
        ])
        compare_err_stream(error_string, true)
        assert_false(ErrorsFound)
        state.dataHeatBalFanSys.ZoneReOrder.allocate(state.dataGlobal.NumOfZones)
        ErrorsFound = false
        HeatBalanceAirManager.GetSimpleAirModelInputs(state, ErrorsFound)
        compare_err_stream("", true)
        assert_false(ErrorsFound)
        const Space1aFloorArea = 10.0
        const Space1bFloorArea = 100.0
        const Zone2FloorArea = 1000.0
        let zone1 = Util.FindItemInList("ZONE 1", state.dataHeatBal.Zone)
        let zone2 = Util.FindItemInList("ZONE 2", state.dataHeatBal.Zone)
        let space1a = Util.FindItemInList("SPACE 1A", state.dataHeatBal.space)
        let space1b = Util.FindItemInList("SPACE 1B", state.dataHeatBal.space)
        let spaceZone2 = Util.FindItemInList("ZONE 2", state.dataHeatBal.space)
        var zoneNum = zone1
        assert_eq("ZONE 1", state.dataHeatBal.Zone[zoneNum].Name)
        assert_eq(2, state.dataHeatBal.Zone[zoneNum].numSpaces)
        assert_eq("SPACE 1A", state.dataHeatBal.space[state.dataHeatBal.Zone[zoneNum].spaceIndexes[0]].Name)
        assert_eq("SPACE 1B", state.dataHeatBal.space[state.dataHeatBal.Zone[zoneNum].spaceIndexes[1]].Name)
        zoneNum = zone2
        assert_eq("ZONE 2", state.dataHeatBal.Zone[zoneNum].Name)
        assert_eq(1, state.dataHeatBal.Zone[zoneNum].numSpaces)
        assert_eq("ZONE 2", state.dataHeatBal.space[state.dataHeatBal.Zone[zoneNum].spaceIndexes[0]].Name)
        var spaceNum = space1a
        assert_eq("SPACE 1A", state.dataHeatBal.space[spaceNum].Name)
        assert_eq("ZONE 1", state.dataHeatBal.Zone[state.dataHeatBal.space[spaceNum].zoneNum].Name)
        assert_eq(Space1aFloorArea, state.dataHeatBal.space[spaceNum].userEnteredFloorArea)
        assert_eq(Space1aFloorArea, state.dataHeatBal.space[spaceNum].FloorArea)
        spaceNum = space1b
        assert_eq("SPACE 1B", state.dataHeatBal.space[spaceNum].Name)
        assert_eq("ZONE 1", state.dataHeatBal.Zone[state.dataHeatBal.space[spaceNum].zoneNum].Name)
        assert_eq(Space1bFloorArea, state.dataHeatBal.space[spaceNum].userEnteredFloorArea)
        assert_eq(Space1bFloorArea, state.dataHeatBal.space[spaceNum].FloorArea)
        assert_eq("SOMESPACES", state.dataHeatBal.spaceList[0].Name)  # spaceList index 1 -> 0
        assert_eq(2, state.dataHeatBal.spaceList[0].spaces.size())
        assert_eq("SPACE 1A", state.dataHeatBal.space[state.dataHeatBal.spaceList[0].spaces[0]].Name)
        assert_eq("SPACE 1B", state.dataHeatBal.space[state.dataHeatBal.spaceList[0].spaces[1]].Name)
        spaceNum = spaceZone2
        assert_eq("ZONE 2", state.dataHeatBal.space[spaceNum].Name)
        assert_eq("ZONE 2", state.dataHeatBal.Zone[state.dataHeatBal.space[spaceNum].zoneNum].Name)
        assert_eq(-99999, state.dataHeatBal.space[spaceNum].userEnteredFloorArea)
        assert_eq(Zone2FloorArea, state.dataHeatBal.space[spaceNum].FloorArea)
        const numInstances = 10
        const AllZonesFlowPerArea = 6.0
        const SomeSpacesFlowPerArea = 5.0
        const Space1aFlowPerArea = 3.0
        const Space1bFlowPerArea = 4.0
        const Zone1FlowPerArea = 1.0
        const Zone2FlowPerArea = 2.0
        let spaceNums = [space1a, space1b, spaceZone2, space1a, space1b, space1a, space1b, space1a, space1b, spaceZone2]
        let zoneNums = [zone1, zone1, zone2, zone1, zone1, zone1, zone1, zone1, zone1, zone2]
        let infilNames = ["Space 1a AllZonesInfiltration",
                          "Space 1b AllZonesInfiltration",
                          "Zone 2 AllZonesInfiltration",
                          "Space 1a SomeSpacesInfiltration",
                          "Space 1b SomeSpacesInfiltration",
                          "Space1aInfiltration",
                          "Space1bInfiltration",
                          "Space 1a Zone1Infiltration",
                          "Space 1b Zone1Infiltration",
                          "Zone2Infiltration"]
        let ventNames = ["Space 1a AllZonesVentilation",
                         "Space 1b AllZonesVentilation",
                         "Zone 2 AllZonesVentilation",
                         "Space 1a SomeSpacesVentilation",
                         "Space 1b SomeSpacesVentilation",
                         "Space1aVentilation",
                         "Space1bVentilation",
                         "Space 1a Zone1Ventilation",
                         "Space 1b Zone1Ventilation",
                         "Zone2Ventilation"]
        let flows = [Space1aFloorArea * AllZonesFlowPerArea,
                     Space1bFloorArea * AllZonesFlowPerArea,
                     Zone2FloorArea * AllZonesFlowPerArea,
                     Space1aFloorArea * SomeSpacesFlowPerArea,
                     Space1bFloorArea * SomeSpacesFlowPerArea,
                     Space1aFloorArea * Space1aFlowPerArea,
                     Space1bFloorArea * Space1bFlowPerArea,
                     Space1aFloorArea * Zone1FlowPerArea,
                     Space1bFloorArea * Zone1FlowPerArea,
                     Zone2FloorArea * Zone2FlowPerArea]
        let density = [DataHeatBalance.InfVentDensityBasis.Outdoor,
                       DataHeatBalance.InfVentDensityBasis.Outdoor,
                       DataHeatBalance.InfVentDensityBasis.Outdoor,
                       DataHeatBalance.InfVentDensityBasis.Outdoor,
                       DataHeatBalance.InfVentDensityBasis.Outdoor,
                       DataHeatBalance.InfVentDensityBasis.Outdoor,
                       DataHeatBalance.InfVentDensityBasis.Outdoor,
                       DataHeatBalance.InfVentDensityBasis.Standard,
                       DataHeatBalance.InfVentDensityBasis.Standard,
                       DataHeatBalance.InfVentDensityBasis.Indoor]
        for itemNum in range(numInstances):
            var thisInfiltration = state.dataHeatBal.Infiltration[itemNum]
            var thisVentilation = state.dataHeatBal.Ventilation[itemNum]
            assert_true(Util.SameString(infilNames[itemNum], thisInfiltration.Name))
            assert_eq(thisInfiltration.DesignLevel, flows[itemNum])
            assert_true(Util.SameString(ventNames[itemNum], thisVentilation.Name))
            assert_eq(thisVentilation.DesignLevel, flows[itemNum])
            assert_eq(thisInfiltration.ZonePtr, zoneNums[itemNum])
            assert_eq(thisVentilation.ZonePtr, zoneNums[itemNum])
            assert_eq(thisInfiltration.spaceIndex, spaceNums[itemNum])
            assert_eq(thisVentilation.spaceIndex, spaceNums[itemNum])
            assert_eq(thisInfiltration.densityBasis, density[itemNum])
            assert_eq(thisVentilation.densityBasis, density[itemNum])

    def test_HeatBalanceAirManager_GetMixingAndCrossMixing():
        state.dataInputProcessing.inputProcessor.epJSON = json.parse("""
        {
        "SimulationControl": {
            "SimulationControl 1": {
                "do_plant_sizing_calculation": "No",
                "do_system_sizing_calculation": "No",
                "do_zone_sizing_calculation": "No",
                "run_simulation_for_sizing_periods": "Yes",
                "run_simulation_for_weather_file_run_periods": "No"
            }
        },
        "ZoneAirHeatBalanceAlgorithm": {
            "ZoneAirHeatBalanceAlgorithm 1": {
                "algorithm": "AnalyticalSolution",
                "do_space_heat_balance_for_simulation": "Yes"
            }
        },
        "Site:Location": {
            "USA IL-CHICAGO-OHARE": {
                "elevation": 190,
                "latitude": 41.77,
                "longitude": -87.75,
                "time_zone": -6.0
            }
        },
            "SizingPeriod:DesignDay": {
            "CHICAGO Ann Clg .4% Condns WB=>MDB": {
                "barometric_pressure": 99063.0,
                "daily_dry_bulb_temperature_range": 10.7,
                "day_of_month": 21,
                "day_type": "SummerDesignDay",
                "daylight_saving_time_indicator": "No",
                "humidity_condition_type": "WetBulb",
                "maximum_dry_bulb_temperature": 31.2,
                "month": 7,
                "rain_indicator": "No",
                "sky_clearness": 1.0,
                "snow_indicator": "No",
                "solar_model_indicator": "ASHRAEClearSky",
                "wetbulb_or_dewpoint_at_maximum_dry_bulb": 25.5,
                "wind_direction": 230,
                "wind_speed": 5.3
              }
            },
            "Zone": {
                "Zone 1" : {
                    "volume": 100.0
                },
                "Zone 2" : {
                    "volume": 2000.0,
                     "floor_area": 1000.0
                }
            },
            "Space": {
                "Space 1a" : {
                     "zone_name": "Zone 1",
                     "floor_area": 10.0
                },
                "Space 1b" : {
                     "zone_name": "Zone 1",
                     "floor_area": 100.0
                }
            },
            "SpaceList": {
                "SomeSpaces" : {
                     "spaces": [
                        {
                            "space_name": "Space 1a"
                        },
                        {
                            "space_name": "Space 1b"
                        }
                    ]
                }
            },
            "ZoneList": {
                "AllZones" : {
                     "zones": [
                        {
                            "zone_name": "Zone 1"
                        },
                        {
                            "zone_name": "Zone 2"
                        }
                    ]
                }
            },
            "Building": {
                "Some building somewhere": {
                }
            },
            "GlobalGeometryRules": {
                "GlobalGeometryRules 1": {
                    "coordinate_system": "Relative",
                    "starting_vertex_position": "UpperLeftCorner",
                    "vertex_entry_direction": "Counterclockwise"
                }
            },
            "Construction": {
                "ext-slab": {
                    "outside_layer": "HW CONCRETE"
                }
            },
            "Material": {
                "HW CONCRETE": {
                    "conductivity": 1.311,
                    "density": 2240.0,
                    "roughness": "Rough",
                    "solar_absorptance": 0.7,
                    "specific_heat": 836.8,
                    "thermal_absorptance": 0.9,
                    "thickness": 0.1016,
                    "visible_absorptance": 0.7
                }
            },
            "BuildingSurface:Detailed": {
                "Dummy Space 1a Floor": {
                    "zone_name": "Zone 1",
                    "space_name": "Space 1a",
                    "surface_type": "Floor",
                    "construction_name": "ext-slab",
                    "number_of_vertices": 4,
                    "outside_boundary_condition": "adiabatic",
                    "sun_exposure": "nosun",
                    "vertices": [
                        {
                            "vertex_x_coordinate": 45.3375,
                            "vertex_y_coordinate": 28.7006,
                            "vertex_z_coordinate": 0.0
                        },
                        {
                            "vertex_x_coordinate": 45.3375,
                            "vertex_y_coordinate": 4.5732,
                            "vertex_z_coordinate": 0.0
                        },
                        {
                            "vertex_x_coordinate": 4.5732,
                            "vertex_y_coordinate": 4.5732,
                            "vertex_z_coordinate": 0.0
                        },
                        {
                            "vertex_x_coordinate": 4.5732,
                            "vertex_y_coordinate": 28.7006,
                            "vertex_z_coordinate": 0.0
                        }
                    ]
                },
                "Dummy Space 1b Floor": {
                    "zone_name": "Zone 1",
                    "space_name": "Space 1b",
                    "surface_type": "Floor",
                    "construction_name": "ext-slab",
                    "number_of_vertices": 4,
                    "outside_boundary_condition": "adiabatic",
                    "sun_exposure": "nosun",
                    "vertices": [
                        {
                            "vertex_x_coordinate": 45.3375,
                            "vertex_y_coordinate": 28.7006,
                            "vertex_z_coordinate": 0.0
                        },
                        {
                            "vertex_x_coordinate": 45.3375,
                            "vertex_y_coordinate": 4.5732,
                            "vertex_z_coordinate": 0.0
                        },
                        {
                            "vertex_x_coordinate": 4.5732,
                            "vertex_y_coordinate": 4.5732,
                            "vertex_z_coordinate": 0.0
                        },
                        {
                            "vertex_x_coordinate": 4.5732,
                            "vertex_y_coordinate": 28.7006,
                            "vertex_z_coordinate": 0.0
                        }
                    ]
                },
                "Dummy Zone 2 Floor": {
                    "zone_name": "Zone 2",
                    "surface_type": "Floor",
                    "construction_name": "ext-slab",
                    "number_of_vertices": 4,
                    "outside_boundary_condition": "adiabatic",
                    "sun_exposure": "nosun",
                    "vertices": [
                        {
                            "vertex_x_coordinate": 45.3375,
                            "vertex_y_coordinate": 28.7006,
                            "vertex_z_coordinate": 0.0
                        },
                        {
                            "vertex_x_coordinate": 45.3375,
                            "vertex_y_coordinate": 4.5732,
                            "vertex_z_coordinate": 0.0
                        },
                        {
                            "vertex_x_coordinate": 4.5732,
                            "vertex_y_coordinate": 4.5732,
                            "vertex_z_coordinate": 0.0
                        },
                        {
                            "vertex_x_coordinate": 4.5732,
                            "vertex_y_coordinate": 28.7006,
                            "vertex_z_coordinate": 0.0
                        }
                    ]
                }
            },
            "ZoneMixing": {
                "Zone1Mixing": {
                    "design_flow_rate_calculation_method": "Flow/Area",
                    "flow_rate_per_floor_area": 1.0,
                    "zone_or_space_name": "Zone 1",
                    "source_zone_or_space_name": "Zone 2"
                },
                "Zone2Mixing": {
                    "design_flow_rate_calculation_method": "Flow/Area",
                    "flow_rate_per_floor_area": 2.0,
                    "zone_or_space_name": "Zone 2",
                    "source_zone_or_space_name": "Zone 1"
                },
                "Space1aMixing": {
                    "design_flow_rate_calculation_method": "Flow/Area",
                    "flow_rate_per_floor_area": 3.0,
                    "zone_or_space_name": "Space 1a",
                    "source_zone_or_space_name": "Space 1b"
                },
                "Space1bMixing": {
                    "design_flow_rate_calculation_method": "Flow/Area",
                    "flow_rate_per_floor_area": 4.0,
                    "zone_or_space_name": "Space 1b",
                    "source_zone_or_space_name": "Zone 2"
                }
            },
            "ZoneCrossMixing": {
                "Zone1CrossMixing": {
                    "design_flow_rate_calculation_method": "Flow/Area",
                    "flow_rate_per_floor_area": 1.0,
                    "zone_or_space_name": "Zone 1",
                    "source_zone_or_space_name": "Zone 2"
                },
                "Zone2CrossMixing": {
                    "design_flow_rate_calculation_method": "Flow/Area",
                    "flow_rate_per_floor_area": 2.0,
                    "zone_or_space_name": "Zone 2",
                    "source_zone_or_space_name": "Zone 1"
                },
                "Space1aCrossMixing": {
                    "design_flow_rate_calculation_method": "Flow/Area",
                    "flow_rate_per_floor_area": 3.0,
                    "zone_or_space_name": "Space 1a",
                    "source_zone_or_space_name": "Space 1b"
                },
                "Space1bCrossMixing": {
                    "design_flow_rate_calculation_method": "Flow/Area",
                    "flow_rate_per_floor_area": 4.0,
                    "zone_or_space_name": "Space 1b",
                    "source_zone_or_space_name": "Zone 2"
                }
            }
        }
        """)
        state.dataGlobal.isEpJSON = true
        state.dataInputProcessing.inputProcessor.initializeMaps()
        var MaxArgs = 0
        var MaxAlpha = 0
        var MaxNumeric = 0
        state.dataInputProcessing.inputProcessor.getMaxSchemaArgs(MaxArgs, MaxAlpha, MaxNumeric)
        state.dataIPShortCut.cAlphaFieldNames.allocate(MaxAlpha)
        state.dataIPShortCut.cAlphaArgs.allocate(MaxAlpha)
        state.dataIPShortCut.lAlphaFieldBlanks.dimension(MaxAlpha, false)
        state.dataIPShortCut.cNumericFieldNames.allocate(MaxNumeric)
        state.dataIPShortCut.rNumericArgs.dimension(MaxNumeric, 0.0)
        state.dataIPShortCut.lNumericFieldBlanks.dimension(MaxNumeric, false)
        state.init_state(state)
        let error_string = delimited_string([
            EnergyPlus.format("   ** Warning ** Version: missing in IDF, processing for EnergyPlus version=\"{}\"", DataStringGlobals.MatchVersion),
            "   ** Warning ** No Timestep object found.  Number of TimeSteps in Hour defaulted to 4.",
            "   ** Warning ** No reporting elements have been requested. No simulation results produced.",
            "   **   ~~~   ** ...Review requirements such as \"Output:Table:SummaryReports\", \"Output:Table:Monthly\", \"Output:Variable\", \"Output:Meter\" and others.",
            "   ** Warning ** GetSurfaceData: Entered Space Floor Area(s) differ more than 5% from calculated Space Floor Area(s).",
            "   **   ~~~   ** ...use Output:Diagnostics,DisplayExtraWarnings; to show more details on individual Spaces.",
            "   ** Warning ** CalculateZoneVolume: 1 zone is not fully enclosed. For more details use:  Output:Diagnostics,DisplayExtrawarnings; ",
            "   ** Warning ** CalcApproximateViewFactors: Zero area for all other zone surfaces.",
            "   **   ~~~   ** Happens for Surface=\"DUMMY SPACE 1A FLOOR\" in Zone=ZONE 1",
            "   ** Warning ** CalcApproximateViewFactors: Zero area for all other zone surfaces.",
            "   **   ~~~   ** Happens for Surface=\"DUMMY SPACE 1B FLOOR\" in Zone=ZONE 1",
            "   ** Warning ** Surfaces in Zone/Enclosure=\"ZONE 1\" do not define an enclosure.",
            "   **   ~~~   ** Number of surfaces <= 3, view factors are set to force reciprocity but may not fulfill completeness.",
            "   **   ~~~   ** Reciprocity means that radiant exchange between two surfaces will match and not lead to an energy loss.",
            "   **   ~~~   ** Completeness means that all of the view factors between a surface and the other surfaces in a zone add up to unity.",
            "   **   ~~~   ** So, when there are three or less surfaces in a zone, EnergyPlus will make sure there are no losses of energy but",
            "   **   ~~~   ** it will not exchange the full amount of radiation with the rest of the zone as it would if there was a completed enclosure.",
            "   ************* Testing Individual Branch Integrity",
            "   ************* All Branches passed integrity testing",
            "   ************* Testing Individual Supply Air Path Integrity",
            "   ************* All Supply Air Paths passed integrity testing",
            "   ************* Testing Individual Return Air Path Integrity",
            "   ************* All Return Air Paths passed integrity testing",
            "   ************* No node connection errors were found.",
            "   ************* Beginning Simulation"
        ])
        SimulationManager.ManageSimulation(state)
        compare_err_stream(error_string, true)
        const Space1aFloorArea = 10.0
        const Space1bFloorArea = 100.0
        const Zone2FloorArea = 1000.0
        let zone1 = Util.FindItemInList("ZONE 1", state.dataHeatBal.Zone)
        let zone2 = Util.FindItemInList("ZONE 2", state.dataHeatBal.Zone)
        let space1a = Util.FindItemInList("SPACE 1A", state.dataHeatBal.space)
        let space1b = Util.FindItemInList("SPACE 1B", state.dataHeatBal.space)
        let spaceZone2 = Util.FindItemInList("ZONE 2", state.dataHeatBal.space)
        var zoneNum = zone1
        assert_eq("ZONE 1", state.dataHeatBal.Zone[zoneNum].Name)
        assert_eq(2, state.dataHeatBal.Zone[zoneNum].numSpaces)
        assert_eq("SPACE 1A", state.dataHeatBal.space[state.dataHeatBal.Zone[zoneNum].spaceIndexes[0]].Name)
        assert_eq("SPACE 1B", state.dataHeatBal.space[state.dataHeatBal.Zone[zoneNum].spaceIndexes[1]].Name)
        zoneNum = zone2
        assert_eq("ZONE 2", state.dataHeatBal.Zone[zoneNum].Name)
        assert_eq(1, state.dataHeatBal.Zone[zoneNum].numSpaces)
        assert_eq("ZONE 2", state.dataHeatBal.space[state.dataHeatBal.Zone[zoneNum].spaceIndexes[0]].Name)
        var spaceNum = space1a
        assert_eq("SPACE 1A", state.dataHeatBal.space[spaceNum].Name)
        assert_eq("ZONE 1", state.dataHeatBal.Zone[state.dataHeatBal.space[spaceNum].zoneNum].Name)
        assert_eq(Space1aFloorArea, state.dataHeatBal.space[spaceNum].userEnteredFloorArea)
        assert_eq(Space1aFloorArea, state.dataHeatBal.space[spaceNum].FloorArea)
        spaceNum = space1b
        assert_eq("SPACE 1B", state.dataHeatBal.space[spaceNum].Name)
        assert_eq("ZONE 1", state.dataHeatBal.Zone[state.dataHeatBal.space[spaceNum].zoneNum].Name)
        assert_eq(Space1bFloorArea, state.dataHeatBal.space[spaceNum].userEnteredFloorArea)
        assert_eq(Space1bFloorArea, state.dataHeatBal.space[spaceNum].FloorArea)
        assert_eq("SOMESPACES", state.dataHeatBal.spaceList[0].Name)  # spaceList index 1 -> 0
        assert_eq(2, state.dataHeatBal.spaceList[0].spaces.size())
        assert_eq("SPACE 1A", state.dataHeatBal.space[state.dataHeatBal.spaceList[0].spaces[0]].Name)
        assert_eq("SPACE 1B", state.dataHeatBal.space[state.dataHeatBal.spaceList[0].spaces[1]].Name)
        spaceNum = spaceZone2
        assert_eq("ZONE 2", state.dataHeatBal.space[spaceNum].Name)
        assert_eq("ZONE 2", state.dataHeatBal.Zone[state.dataHeatBal.space[spaceNum].zoneNum].Name)
        assert_eq(-99999, state.dataHeatBal.space[spaceNum].userEnteredFloorArea)
        assert_eq(Zone2FloorArea, state.dataHeatBal.space[spaceNum].FloorArea)
        const numInstances = 5
        const Space1aFlowPerArea = 3.0
        const Space1bFlowPerArea = 4.0
        const Zone1FlowPerArea = 1.0
        const Zone2FlowPerArea = 2.0
        let spaceNums = [space1a, space1b, space1a, space1b, spaceZone2]
        let zoneNums = [zone1, zone1, zone1, zone1, zone2]
        let fromSpaceNums = [space1b, spaceZone2, spaceZone2, spaceZone2, 0]
        let fromZoneNums = [zone1, zone2, zone2, zone2, zone1]
        let mixNames = ["Space1aMixing", "Space1bMixing", "Space 1a Zone1Mixing", "Space 1b Zone1Mixing", "Zone2Mixing"]
        let crossMixNames = ["Space1aCrossMixing", "Space1bCrossMixing", "Space 1a Zone1CrossMixing", "Space 1b Zone1CrossMixing", "Zone2CrossMixing"]
        let flows = [Space1aFloorArea * Space1aFlowPerArea,
                     Space1bFloorArea * Space1bFlowPerArea,
                     Space1aFloorArea * Zone1FlowPerArea,
                     Space1bFloorArea * Zone1FlowPerArea,
                     Zone2FloorArea * Zone2FlowPerArea]
        for itemNum in range(numInstances):
            var thisMixing = state.dataHeatBal.Mixing[itemNum]
            var thisCrossMixing = state.dataHeatBal.CrossMixing[itemNum]
            assert_true(Util.SameString(mixNames[itemNum], thisMixing.Name))
            assert_eq(thisMixing.DesignLevel, flows[itemNum])
            assert_true(Util.SameString(crossMixNames[itemNum], thisCrossMixing.Name))
            assert_eq(thisCrossMixing.DesignLevel, flows[itemNum])
            assert_eq(thisMixing.ZonePtr, zoneNums[itemNum])
            assert_eq(thisCrossMixing.ZonePtr, zoneNums[itemNum])
            assert_eq(thisMixing.spaceIndex, spaceNums[itemNum])
            assert_eq(thisCrossMixing.spaceIndex, spaceNums[itemNum])
            assert_eq(thisMixing.fromSpaceIndex, fromSpaceNums[itemNum])
            assert_eq(thisCrossMixing.fromSpaceIndex, fromSpaceNums[itemNum])
            assert_eq(thisMixing.FromZone, fromZoneNums[itemNum])
            assert_eq(thisCrossMixing.FromZone, fromZoneNums[itemNum])

    def test_HeatBalanceAirManager_InitSimpleMixingConvectiveHeatGains_Test():
        state.init_state(state)
        var expectedResult1: Float64
        var expectedResult2: Float64
        const allowedTolerance = 0.00001
        state.dataHeatBal.TotRefDoorMixing = 0
        state.dataHeatBal.TotCrossMixing = 0
        state.dataHeatBal.TotMixing = 3
        state.dataHeatBal.Mixing.allocate(state.dataHeatBal.TotMixing)
        state.dataHeatBal.Mixing[0].sched = Sched.GetScheduleAlwaysOn(state)  # Mixing(1) -> [0]
        state.dataHeatBal.Mixing[1].sched = Sched.GetScheduleAlwaysOn(state)  # Mixing(2) -> [1]
        state.dataHeatBal.Mixing[2].sched = Sched.GetScheduleAlwaysOn(state)  # Mixing(3) -> [2]
        state.dataHeatBal.Mixing[0].EMSSimpleMixingOn = false
        state.dataHeatBal.Mixing[1].EMSSimpleMixingOn = false
        state.dataHeatBal.Mixing[2].EMSSimpleMixingOn = false
        state.dataHeatBal.ZoneAirMassFlow.EnforceZoneMassBalance = true
        state.dataHeatBal.MassConservation.allocate(2)
        state.dataHeatBal.MassConservation[0].NumReceivingZonesMixingObject = 2  # MassConservation(1) -> [0]
        state.dataHeatBal.MassConservation[1].NumReceivingZonesMixingObject = 0  # MassConservation(2) -> [1]
        state.dataHeatBal.MassConservation[0].ZoneMixingReceivingFr.allocate(2)
        state.dataHeatBal.AirFlowFlag = false
        state.dataHeatBal.MassConservation[0].ZoneMixingReceivingFr[0] = -9999.9  # ZoneMixingReceivingFr(1) -> [0]
        state.dataHeatBal.MassConservation[0].ZoneMixingReceivingFr[1] = -9999.9  # ZoneMixingReceivingFr(2) -> [1]
        expectedResult1 = -9999.9
        expectedResult2 = -9999.9
        HeatBalanceAirManager.InitSimpleMixingConvectiveHeatGains(state)
        assert_near(expectedResult1, state.dataHeatBal.MassConservation[0].ZoneMixingReceivingFr[0], allowedTolerance)
        assert_near(expectedResult2, state.dataHeatBal.MassConservation[0].ZoneMixingReceivingFr[1], allowedTolerance)
        state.dataHeatBal.AirFlowFlag = true
        state.dataHeatBal.Mixing[0].DesignLevel = 0.0
        state.dataHeatBal.Mixing[1].DesignLevel = 0.0
        state.dataHeatBal.MassConservation[0].ZoneMixingReceivingFr[0] = -9999.9
        state.dataHeatBal.MassConservation[0].ZoneMixingReceivingFr[1] = -9999.9
        expectedResult1 = 0.0
        expectedResult2 = 0.0
        HeatBalanceAirManager.InitSimpleMixingConvectiveHeatGains(state)
        assert_near(expectedResult1, state.dataHeatBal.MassConservation[0].ZoneMixingReceivingFr[0], allowedTolerance)
        assert_near(expectedResult2, state.dataHeatBal.MassConservation[0].ZoneMixingReceivingFr[1], allowedTolerance)
        state.dataHeatBal.AirFlowFlag = true
        state.dataHeatBal.Mixing[0].DesignLevel = 100.0
        state.dataHeatBal.Mixing[1].DesignLevel = 300.0
        state.dataHeatBal.MassConservation[0].ZoneMixingReceivingFr[0] = -9999.9
        state.dataHeatBal.MassConservation[0].ZoneMixingReceivingFr[1] = -9999.9
        expectedResult1 = 0.25
        expectedResult2 = 0.75
        HeatBalanceAirManager.InitSimpleMixingConvectiveHeatGains(state)
        assert_near(expectedResult1, state.dataHeatBal.MassConservation[0].ZoneMixingReceivingFr[0], allowedTolerance)
        assert_near(expectedResult2, state.dataHeatBal.MassConservation[0].ZoneMixingReceivingFr[1], allowedTolerance)