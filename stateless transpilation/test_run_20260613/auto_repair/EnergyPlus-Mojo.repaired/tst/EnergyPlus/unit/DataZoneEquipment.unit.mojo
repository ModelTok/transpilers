from EnergyPlus.DataZoneEquipment import *
from EnergyPlus.DataContaminantBalance import *
from EnergyPlus.DataEnvironment import *
from EnergyPlus.DataHeatBalance import *
from EnergyPlus.DataIPShortCuts import *
from EnergyPlus.DataSizing import *
from EnergyPlus.HeatBalanceManager import *
from EnergyPlus.InputProcessing.InputProcessor import *
from EnergyPlus.ScheduleManager import *
from Fixtures.EnergyPlusFixture import *
from Sched import Sched
from json import loads as json_loads

# ------------------------------------------------------------------------------
# Test: DataZoneEquipment_TestGetSystemNodeNumberForZone
# ------------------------------------------------------------------------------
def DataZoneEquipment_TestGetSystemNodeNumberForZone() raises:
    var state = EnergyPlusFixture.new_state()
    state.init_state(state)
    state.dataGlobal.NumOfZones = 2
    state.dataZoneEquip.ZoneEquipConfig = List[ZoneEquipConfig]()
    for i in range(2):
        state.dataZoneEquip.ZoneEquipConfig.append(ZoneEquipConfig())
    state.dataZoneEquip.ZoneEquipConfig[0].ZoneName = "Zone1"
    state.dataZoneEquip.ZoneEquipConfig[0].ZoneNode = 1
    state.dataZoneEquip.ZoneEquipConfig[0].IsControlled = true
    state.dataZoneEquip.ZoneEquipConfig[1].ZoneName = "Zone2"
    state.dataZoneEquip.ZoneEquipConfig[1].ZoneNode = 2
    state.dataZoneEquip.ZoneEquipConfig[1].IsControlled = true
    state.dataZoneEquip.ZoneEquipInputsFilled = true
    assert_equal(0, GetSystemNodeNumberForZone(state, 0))
    assert_equal(1, GetSystemNodeNumberForZone(state, 1))
    state.dataZoneEquip.ZoneEquipConfig = List[ZoneEquipConfig]()

# ------------------------------------------------------------------------------
# Test: DataZoneEquipment_TestCalcDesignSpecificationOutdoorAir
# ------------------------------------------------------------------------------
def DataZoneEquipment_TestCalcDesignSpecificationOutdoorAir() raises:
    var state = EnergyPlusFixture.new_state()
    state.init_state(state)
    state.dataHeatBal.Zone = List[ZoneData]()
    state.dataHeatBal.Zone.append(ZoneData())
    state.dataSize.OARequirements = List[OARequirementsData]()
    state.dataSize.OARequirements.append(OARequirementsData())
    state.dataHeatBal.ZoneIntGain = List[ZoneIntGainData]()
    state.dataHeatBal.ZoneIntGain.append(ZoneIntGainData())
    state.dataHeatBal.People = List[PeopleData]()
    state.dataHeatBal.People.append(PeopleData())
    state.dataContaminantBalance.ZoneCO2GainFromPeople = List[Float64]()
    state.dataContaminantBalance.ZoneCO2GainFromPeople.append(0.0)
    state.dataContaminantBalance.ZoneAirCO2 = List[Float64]()
    state.dataContaminantBalance.ZoneAirCO2.append(0.0)
    state.dataContaminantBalance.ZoneSysContDemand = List[ZoneSysContDemandData]()
    state.dataContaminantBalance.ZoneSysContDemand.append(ZoneSysContDemandData())
    state.dataEnvrn.StdRhoAir = 1.20
    state.dataHeatBal.Zone[0].FloorArea = 10.0
    state.dataHeatBal.Zone[0].TotOccupants = 5.0
    state.dataHeatBal.Zone[0].zoneContamControllerSched = Sched.AddScheduleConstant(state, "ZONE CONTAM CONTROLLER")
    state.dataHeatBal.People[0].ZonePtr = 1
    state.dataHeatBal.TotPeople = 1
    state.dataHeatBal.People[0].activityLevelSched = Sched.AddScheduleConstant(state, "ACTIVITY LEVEL SCHED")
    state.dataHeatBal.People[0].CO2RateFactor = 3.82e-8
    state.dataHeatBal.People[0].NumberOfPeople = state.dataHeatBal.Zone[0].TotOccupants
    state.dataContaminantBalance.Contaminant.CO2Simulation = true
    state.dataContaminantBalance.OutdoorCO2 = 400.0
    state.dataContaminantBalance.ZoneCO2GainFromPeople[0] = 3.82e-8 * 5.0
    state.dataSize.NumOARequirements = 1
    state.dataSize.OARequirements[0].Name = "ZONE OA"
    state.dataSize.OARequirements[0].OAFlowMethod = OAFlowCalcMethod.PCOccSch
    state.dataSize.OARequirements[0].OAFlowPerPerson = 0.002
    state.dataSize.OARequirements[0].OAFlowPerArea = 0.003
    state.dataHeatBal.ZoneIntGain[0].NOFOCC = 0.5
    state.dataHeatBal.Zone[0].zoneContamControllerSched.currentVal = 1.0
    state.dataHeatBal.People[0].activityLevelSched.currentVal = 131.881995
    var OAVolumeFlowRate: Float64
    state.dataContaminantBalance.ZoneAirCO2[0] = 500.0
    OAVolumeFlowRate = DataSizing.calcDesignSpecificationOutdoorAir(state, 1, 1, false, false)
    assert_almost_equal(0.031, OAVolumeFlowRate, 0.00001)
    state.dataContaminantBalance.ZoneAirCO2[0] = 405.0
    OAVolumeFlowRate = DataSizing.calcDesignSpecificationOutdoorAir(state, 1, 1, false, false)
    assert_almost_equal(0.0308115, OAVolumeFlowRate, 0.00001)
    state.dataContaminantBalance.ZoneAirCO2[0] = 500.0
    state.dataSize.OARequirements[0].OAFlowMethod = OAFlowCalcMethod.PCDesOcc
    OAVolumeFlowRate = DataSizing.calcDesignSpecificationOutdoorAir(state, 1, 1, false, false)
    assert_almost_equal(0.0315879, OAVolumeFlowRate, 0.00001)
    state.dataSize.OARequirements[0].OAFlowMethod = OAFlowCalcMethod.IAQProcedure
    state.dataContaminantBalance.ZoneSysContDemand[0].OutputRequiredToCO2SP = 0.2 * state.dataEnvrn.StdRhoAir
    OAVolumeFlowRate = DataSizing.calcDesignSpecificationOutdoorAir(state, 1, 1, false, false)
    assert_almost_equal(0.2, OAVolumeFlowRate, 0.00001)
    state.dataHeatBal.Zone = List[ZoneData]()
    state.dataSize.OARequirements = List[OARequirementsData]()
    state.dataHeatBal.ZoneIntGain = List[ZoneIntGainData]()
    state.dataHeatBal.People = List[PeopleData]()
    state.dataContaminantBalance.ZoneCO2GainFromPeople = List[Float64]()
    state.dataContaminantBalance.ZoneAirCO2 = List[Float64]()
    state.dataContaminantBalance.ZoneSysContDemand = List[ZoneSysContDemandData]()

# ------------------------------------------------------------------------------
# Test: GetZoneEquipmentData_epJSON
# ------------------------------------------------------------------------------
def GetZoneEquipmentData_epJSON() raises:
    var state = EnergyPlusFixture.new_state()
    state.dataInputProcessing.inputProcessor.epJSON = json_loads("""
{
  "ZoneHVAC:EquipmentList": {
    "Zone1 Equipment List": {
      "equipment": [
        {
          "zone_equipment_cooling_sequence": 1,
          "zone_equipment_heating_or_no_load_sequence": 1,
          "zone_equipment_name": "Fan Zone Exhaust 1",
          "zone_equipment_object_type": "Fan:ZoneExhaust"
        },
        {
          "zone_equipment_cooling_sequence": 3,
          "zone_equipment_heating_or_no_load_sequence": 2,
          "zone_equipment_name": "ADU Air Terminal Single Duct Constant Volume No Reheat 1",
          "zone_equipment_object_type": "ZoneHVAC:AirDistributionUnit"
        },
        {
          "zone_equipment_cooling_sequence": 2,
          "zone_equipment_heating_or_no_load_sequence": 3,
          "zone_equipment_name": "ADU Air Terminal Single Duct VAV Reheat 1",
          "zone_equipment_object_type": "ZoneHVAC:AirDistributionUnit"
        }
      ],
      "load_distribution_scheme": "SequentialLoad"
    }
  },
  "Zone": {
    "Zone1": {
      "direction_of_relative_north": 0.0,
      "multiplier": 1,
      "part_of_total_floor_area": "Yes",
      "x_origin": 0.0,
      "y_origin": 0.0,
      "z_origin": 0.0
    }
  },
  "NodeList": {
    "Packaged Rooftop Air Conditioner Demand Inlet Nodes": {
      "nodes": [
        {
          "node_name": "Node 6"
        }
      ]
    },
    "Packaged Rooftop Air Conditioner Supply Outlet Nodes": {
      "nodes": [
        {
          "node_name": "Node 5"
        }
      ]
    },
    "VAV with Reheat Demand Inlet Nodes": {
      "nodes": [
        {
          "node_name": "Node 18"
        }
      ]
    },
    "VAV with Reheat Supply Outlet Nodes": {
      "nodes": [
        {
          "node_name": "Node 17"
        }
      ]
    },
    "Zone1 Exhaust Node List": {
      "nodes": [
        {
          "node_name": "Node 2"
        }
      ]
    },
    "Zone1 Inlet Node List": {
      "nodes": [
        {
          "node_name": "Node 8"
        },
        {
          "node_name": "Node 20"
        }
      ]
    },
    "Zone1 Return Node List": {
      "nodes": [
        {
          "node_name": "Node 15"
        },
        {
          "node_name": "Node 77"
        }
      ]
    }
  },
  "ZoneHVAC:EquipmentConnections": {
    "ZoneHVAC:EquipmentConnections 1": {
      "zone_air_exhaust_node_or_nodelist_name": "Zone1 Exhaust Node List",
      "zone_air_inlet_node_or_nodelist_name": "Zone1 Inlet Node List",
      "zone_air_node_name": "Node 1",
      "zone_conditioning_equipment_list_name": "Zone1 Equipment List",
      "zone_name": "Zone1",
      "zone_return_air_node_or_nodelist_name": "Zone1 Return Node List"
    }
  },
  "AirLoopHVAC:SupplyPath": {
    "Packaged Rooftop Air Conditioner Node 6 Supply Path": {
      "components": [
        {
          "component_name": "Air Loop HVAC Zone Splitter 1",
          "component_object_type": "AirLoopHVAC:ZoneSplitter"
        }
      ],
      "supply_air_path_inlet_node_name": "Node 6"
    },
    "VAV with Reheat Node 18 Supply Path": {
      "components": [
        {
          "component_name": "Air Loop HVAC Zone Splitter 2",
          "component_object_type": "AirLoopHVAC:ZoneSplitter"
        }
      ],
      "supply_air_path_inlet_node_name": "Node 18"
    }
  },
  "AirLoopHVAC:ReturnPath": {
    "Packaged Rooftop Air Conditioner Return Path": {
      "components": [
        {
          "component_name": "Air Loop HVAC Zone Mixer 1",
          "component_object_type": "AirLoopHVAC:ZoneMixer"
        }
      ],
      "return_air_path_outlet_node_name": "Node 7"
    },
    "VAV with Reheat Return Path": {
      "components": [
        {
          "component_name": "Air Loop HVAC Zone Mixer 2",
          "component_object_type": "AirLoopHVAC:ZoneMixer"
        }
      ],
      "return_air_path_outlet_node_name": "Node 19"
    }
  },
  "Fan:ZoneExhaust": {
    "Fan Zone Exhaust 1": {
      "air_inlet_node_name": "Node 2",
      "air_outlet_node_name": "Node 3",
      "end_use_subcategory": "General",
      "fan_total_efficiency": 0.6,
      "pressure_rise": 0.0,
      "system_availability_manager_coupling_mode": "Decoupled"
    }
  },
  "ZoneHVAC:AirDistributionUnit": {
    "ADU Air Terminal Single Duct Constant Volume No Reheat 1": {
      "air_distribution_unit_outlet_node_name": "Node 8",
      "air_terminal_name": "Air Terminal Single Duct Constant Volume No Reheat 1",
      "air_terminal_object_type": "AirTerminal:SingleDuct:ConstantVolume:NoReheat"
    },
    "ADU Air Terminal Single Duct VAV Reheat 1": {
      "air_distribution_unit_outlet_node_name": "Node 20",
      "air_terminal_name": "Air Terminal Single Duct VAV Reheat 1",
      "air_terminal_object_type": "AirTerminal:SingleDuct:VAV:Reheat"
    }
  },
  "AirLoopHVAC:ZoneMixer": {
    "Air Loop HVAC Zone Mixer 1": {
      "nodes": [
        {
          "inlet_node_name": "Node 15"
        }
      ],
      "outlet_node_name": "Node 7"
    },
    "Air Loop HVAC Zone Mixer 2": {
      "nodes": [
        {
          "inlet_node_name": "Node 77"
        }
      ],
      "outlet_node_name": "Node 19"
    }
  },
  "AirLoopHVAC:ZoneSplitter": {
    "Air Loop HVAC Zone Splitter 1": {
      "inlet_node_name": "Node 6",
      "nodes": [
        {
          "outlet_node_name": "Node 14"
        }
      ]
    },
    "Air Loop HVAC Zone Splitter 2": {
      "inlet_node_name": "Node 18",
      "nodes": [
        {
          "outlet_node_name": "Node 54"
        }
      ]
    }
  }
}
    """)
    state.dataGlobal.isEpJSON = true
    state.dataInputProcessing.inputProcessor.initializeMaps()
    var MaxArgs: Int = 0
    var MaxAlpha: Int = 0
    var MaxNumeric: Int = 0
    state.dataInputProcessing.inputProcessor.getMaxSchemaArgs(MaxArgs, MaxAlpha, MaxNumeric)
    state.dataIPShortCut.cAlphaFieldNames = List[String]()
    state.dataIPShortCut.cAlphaFieldNames.resize(MaxAlpha)
    state.dataIPShortCut.cAlphaArgs = List[String]()
    state.dataIPShortCut.cAlphaArgs.resize(MaxAlpha)
    state.dataIPShortCut.lAlphaFieldBlanks = List[Bool]()
    state.dataIPShortCut.lAlphaFieldBlanks.resize(MaxAlpha, false)
    state.dataIPShortCut.cNumericFieldNames = List[String]()
    state.dataIPShortCut.cNumericFieldNames.resize(MaxNumeric)
    state.dataIPShortCut.rNumericArgs = List[Float64]()
    state.dataIPShortCut.rNumericArgs.resize(MaxNumeric, 0.0)
    state.dataIPShortCut.lNumericFieldBlanks = List[Bool]()
    state.dataIPShortCut.lNumericFieldBlanks.resize(MaxNumeric, false)
    state.dataGlobal.TimeStepsInHour = 1
    state.dataGlobal.MinutesInTimeStep = 60
    state.init_state(state)
    var ErrorsFound: Bool = false
    HeatBalanceManager.GetZoneData(state, ErrorsFound)
    assert_false(ErrorsFound)
    DataZoneEquipment.GetZoneEquipmentData(state)
    assert_equal(1, state.dataZoneEquip.ZoneEquipList.size())
    var thisZoneEquipList_ref = state.dataZoneEquip.ZoneEquipList[0]
    assert_equal(3, thisZoneEquipList_ref.NumOfEquipTypes)
    assert_equal(LoadDist.Sequential, thisZoneEquipList_ref.LoadDistScheme)
    assert_equal("FAN ZONE EXHAUST 1", thisZoneEquipList_ref.EquipName[0])
    assert_equal("FAN:ZONEEXHAUST", thisZoneEquipList_ref.EquipTypeName[0])
    assert_equal(ZoneEquipType.ExhaustFan, thisZoneEquipList_ref.EquipType[0])
    assert_equal(1, thisZoneEquipList_ref.CoolingPriority[0])
    assert_equal(1, thisZoneEquipList_ref.HeatingPriority[0])
    assert_equal(Sched.GetScheduleAlwaysOn(state), thisZoneEquipList_ref.sequentialCoolingFractionScheds[0])
    assert_equal(Sched.GetScheduleAlwaysOn(state), thisZoneEquipList_ref.sequentialHeatingFractionScheds[0])
    assert_equal("ADU AIR TERMINAL SINGLE DUCT CONSTANT VOLUME NO REHEAT 1", thisZoneEquipList_ref.EquipName[1])
    assert_equal("ZONEHVAC:AIRDISTRIBUTIONUNIT", thisZoneEquipList_ref.EquipTypeName[1])
    assert_equal(ZoneEquipType.AirDistributionUnit, thisZoneEquipList_ref.EquipType[1])
    assert_equal(3, thisZoneEquipList_ref.CoolingPriority[1])
    assert_equal(2, thisZoneEquipList_ref.HeatingPriority[1])
    assert_equal(Sched.GetScheduleAlwaysOn(state), thisZoneEquipList_ref.sequentialCoolingFractionScheds[1])
    assert_equal(Sched.GetScheduleAlwaysOn(state), thisZoneEquipList_ref.sequentialHeatingFractionScheds[1])
    assert_equal("ADU AIR TERMINAL SINGLE DUCT VAV REHEAT 1", thisZoneEquipList_ref.EquipName[2])
    assert_equal("ZONEHVAC:AIRDISTRIBUTIONUNIT", thisZoneEquipList_ref.EquipTypeName[2])
    assert_equal(ZoneEquipType.AirDistributionUnit, thisZoneEquipList_ref.EquipType[2])
    assert_equal(2, thisZoneEquipList_ref.CoolingPriority[2])
    assert_equal(3, thisZoneEquipList_ref.HeatingPriority[2])
    assert_equal(Sched.GetScheduleAlwaysOn(state), thisZoneEquipList_ref.sequentialCoolingFractionScheds[2])
    assert_equal(Sched.GetScheduleAlwaysOn(state), thisZoneEquipList_ref.sequentialHeatingFractionScheds[2])
<<<FILE>>>