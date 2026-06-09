# Swarm worklist — amber→green priority queue

Ranks the 160 PARTIAL ("amber") EnergyPlus modules — those with a Python data-model/records loader but **no Mojo physics yet** — so the transpiler swarm converts the highest-leverage ones first.
**Ranking method:** by **inbound `#include` count** (how many other C++ modules depend on this one — a direct proxy for blast-radius/leverage), computed by `migraph` over `EnergyPlus/src/EnergyPlus/*.{cc,hh}`; ties broken by LOC (bigger port = more value unlocked). No profiler weighting applied: the existing `profile_snapshots` measure *runtime* self-time of already-ported (COMPLETE) code, not these unported modules, so they can't rank amber work.

> **Heads-up for the runner:** rows marked **infra** are global data-structs / the IDD input processor / generic node-plumbing helpers that energyplus-mojo replaces *architecturally* (no 1:1 Mojo-physics port). They top this list only because everything `#include`s them. **Skip them for amber→green physics work** and start from the physics-priority table below.

## Full inbound-#include ranking (top 30 of 160 PARTIAL)

| rank | C++ module | infra? | inbound #includes | LOC | current port target(s) in energyplus-mojo | note |
|---:|---|:--:|---:|---:|---|---|
| 1 | `InputProcessor.cc` | infra | 189 | 2810 | site/ground_heat_transfer_records.py | node-connection / input-processing registry — all referenced objects loaded via records (input handled by epJSON loaders). |
| 2 | `DataEnvironment.cc` | infra | 172 | 517 | weather/, site/ (+kernels: Environment data spread across site + weather modules.) |  |
| 3 | `DataHVACGlobals.cc` | infra | 160 | 947 | runtime/, hvac/ (+kernels: HVAC global state distributed across runtime modules.) |  |
| 4 | `General.cc` | infra | 141 | 1955 | output/config.py | 5/5 IDD object types parsed (records present; reconciled from coverage). |
| 5 | `DataHeatBalance.cc` | infra | 123 | 3107 | heat_balance/, runtime/ctf.py (+kernels: Heat balance data handled implicitly in CTF runtime.) |  |
| 6 | `NodeInputManager.cc` | infra | 115 | 1467 | hvac/plant_loops/records.py, hvac/airloop_components.py | Node/branch/connector records parsed. |
| 7 | `BranchNodeConnections.cc` | infra | 99 | 2753 | hvac/airloop_components.py | node-connection / input-processing registry — all referenced objects loaded via records (input handled by epJSON loaders). |
| 8 | `PlantUtilities.cc` | infra | 89 | 2354 | runtime/plant.py | Plant utility functions distributed in runtime. |
| 9 | `EMSManager.cc` |  | 72 | 2497 | runtime/ems_manager.py, ems/ems.py, ems/erl.py (+kernels: erl_arith.mojo) | Architecture-in-place: EMS program runner. Sensor/actuator binding not wired. |
| 10 | `DataZoneEquipment.cc` | infra | 70 | 3154 | hvac/zone_hvac.py (+kernels: Zone equipment configuration distributed in HVAC records.) |  |
| 11 | `GeneralRoutines.cc` | infra | 65 | 1931 | — (+kernels: psychrometrics.mojo) | General utility routines; psychrometric parts ported. |
| 12 | `DataSurfaces.cc` | infra | 64 | 2689 | geometry/, heat_balance/surface.py (+kernels: Surface data in geometry + heat balance records.) |  |
| 13 | `Base.cc` | infra | 63 | 1396 | hvac/fans/records.py | 9 IDD object types loaded; records present, reconciled from coverage. |
| 14 | `DataZoneEnergyDemands.cc` | infra | 44 | 589 | — (+kernels: Zone demands computed at runtime.) |  |
| 15 | `OutAirNodeManager.cc` | infra | 36 | 739 | hvac/controllers/records.py (OutdoorAir:Node) (+kernels: Outdoor air node records parsed.) |  |
| 16 | `FaultsManager.cc` |  | 20 | 2560 | faults/records.py | Records layer for all 16 `FaultModel:*` objects (sensor/setpoint offsets + fouling/scaling) with IDD range/enum validation; wired into `BuildingModel` (fields + |
| 17 | `WaterManager.cc` |  | 19 | 1875 | water_use/ | Water system management records. |
| 18 | `HeatingCapacitySizing.cc` |  | 19 | 565 | hvac/coils.py | 2 IDD object types loaded; records present, reconciled from coverage. |
| 19 | `SteamCoils.cc` |  | 17 | 2427 | hvac/coils.py | 1/1 IDD object types parsed (records present; reconciled from coverage). |
| 20 | `MixedAir.cc` |  | 16 | 6148 | hvac/controllers/records.py | OA mixer + controller as load-only records. |
| 21 | `ZonePlenum.cc` |  | 16 | 1558 | runtime/ctf.py, hvac/air_distribution/records.py | Plenum temperature modeling in stacked zones; `AirLoopHVAC:SupplyPlenum`/`ReturnPlenum` records parsed (load-only). |
| 22 | `CoolingCapacitySizing.cc` |  | 16 | 665 | hvac/coils.py | 2 IDD object types loaded; records present, reconciled from coverage. |
| 23 | `VariableSpeedCoils.cc` |  | 14 | 8624 | hvac/coils_heating/records.py, hvac/coil_curve_fit.py | Variable-speed DX coil records parsed. |
| 24 | `ReportCoilSelection.cc` |  | 13 | 2492 | hvac/airloop_components.py | 2/3 IDD object types parsed (records present; reconciled from coverage). |
| 25 | `SimAirServingZones.cc` |  | 12 | 8141 | hvac/airloop_components.py | Air loop simulation. Records parsed, runtime via ideal loads. |
| 26 | `SetPointManager.cc` |  | 12 | 5291 | hvac/setpoint_managers/records.py (+kernels: setpoint_dual_setband.mojo) | 30+ setpoint manager types as load-only records. |
| 27 | `HVACHXAssistedCoolingCoil.cc` |  | 12 | 2067 | hvac/coils.py | 5/7 IDD object types parsed (records present; reconciled from coverage). |
| 28 | `PluginManager.cc` |  | 12 | 1862 | python_plugin/records.py | PythonPlugin:SearchPaths and PythonPlugin:Variables records. |
| 29 | `CoolingAirFlowSizing.cc` |  | 12 | 492 | hvac/coils.py | 2 IDD object types loaded; records present, reconciled from coverage. |
| 30 | `HVACVariableRefrigerantFlow.cc` |  | 10 | 16442 | hvac/coils.py (CoilCoolingDXVariableRefrigerantFlow) | VRF records parsed. |

## Physics-priority queue (infra stripped) — pull these first

Same ranking, with the architecturally-replaced infra modules removed. These are real EnergyPlus component/physics modules with records already loadable and no Mojo kernel yet — the highest-leverage amber→green conversions.

| rank | C++ module | inbound #includes | LOC | current port target(s) | note |
|---:|---|---:|---:|---|---|
| 1 | `EMSManager.cc` | 72 | 2497 | runtime/ems_manager.py, ems/ems.py, ems/erl.py (+kernels: erl_arith.mojo) | Architecture-in-place: EMS program runner. Sensor/actuator binding not wired. |
| 2 | `FaultsManager.cc` | 20 | 2560 | faults/records.py | Records layer for all 16 `FaultModel:*` objects (sensor/setpoint offsets + fouling/scaling) with IDD range/enum validation; wired into `BuildingModel` (fields + |
| 3 | `WaterManager.cc` | 19 | 1875 | water_use/ | Water system management records. |
| 4 | `HeatingCapacitySizing.cc` | 19 | 565 | hvac/coils.py | 2 IDD object types loaded; records present, reconciled from coverage. |
| 5 | `SteamCoils.cc` | 17 | 2427 | hvac/coils.py | 1/1 IDD object types parsed (records present; reconciled from coverage). |
| 6 | `MixedAir.cc` | 16 | 6148 | hvac/controllers/records.py | OA mixer + controller as load-only records. |
| 7 | `ZonePlenum.cc` | 16 | 1558 | runtime/ctf.py, hvac/air_distribution/records.py | Plenum temperature modeling in stacked zones; `AirLoopHVAC:SupplyPlenum`/`ReturnPlenum` records parsed (load-only). |
| 8 | `CoolingCapacitySizing.cc` | 16 | 665 | hvac/coils.py | 2 IDD object types loaded; records present, reconciled from coverage. |
| 9 | `VariableSpeedCoils.cc` | 14 | 8624 | hvac/coils_heating/records.py, hvac/coil_curve_fit.py | Variable-speed DX coil records parsed. |
| 10 | `ReportCoilSelection.cc` | 13 | 2492 | hvac/airloop_components.py | 2/3 IDD object types parsed (records present; reconciled from coverage). |
| 11 | `SimAirServingZones.cc` | 12 | 8141 | hvac/airloop_components.py | Air loop simulation. Records parsed, runtime via ideal loads. |
| 12 | `SetPointManager.cc` | 12 | 5291 | hvac/setpoint_managers/records.py (+kernels: setpoint_dual_setband.mojo) | 30+ setpoint manager types as load-only records. |
| 13 | `HVACHXAssistedCoolingCoil.cc` | 12 | 2067 | hvac/coils.py | 5/7 IDD object types parsed (records present; reconciled from coverage). |
| 14 | `PluginManager.cc` | 12 | 1862 | python_plugin/records.py | PythonPlugin:SearchPaths and PythonPlugin:Variables records. |
| 15 | `CoolingAirFlowSizing.cc` | 12 | 492 | hvac/coils.py | 2 IDD object types loaded; records present, reconciled from coverage. |
| 16 | `HVACVariableRefrigerantFlow.cc` | 10 | 16442 | hvac/coils.py (CoilCoolingDXVariableRefrigerantFlow) | VRF records parsed. |
| 17 | `PoweredInductionUnits.cc` | 10 | 3077 | hvac/air_terminals.py (ParallelPIUReheat) | PIU records parsed. |
| 18 | `CoilCoolingDX.cc` | 10 | 1337 | hvac/coils.py | 1 IDD object types loaded; records present, reconciled from coverage. |
| 19 | `SystemAirFlowSizing.cc` | 10 | 1062 | hvac/zonehvac_terminal_units/records.py | 3 IDD object types loaded; records present, reconciled from coverage. |
| 20 | `UnitarySystem.cc` | 9 | 19469 | hvac/airloop_components.py (AirLoopHVACUnitarySystem) | Unitary system record parsed. |
| 21 | `ResultsFramework.cc` | 9 | 1801 | output/config.py | 2/2 IDD object types parsed (records present; reconciled from coverage). |
| 22 | `MixerComponent.cc` | 9 | 891 | hvac/air_distribution/records.py | `AirLoopHVAC:ZoneMixer` records parsed (load-only). Ported from the Phase-1 lift. |
| 23 | `HVACControllers.cc` | 8 | 3164 | hvac/controllers/records.py | Controller records parsed (OA, humidistat, water coil, etc). |
| 24 | `StandardRatings.cc` | 7 | 8562 | hvac/standard_ratings.py | Single-speed DX cooling AHRI ratings ported as pure stdlib-only functions: net cooling capacity, EER (AHRI 340/360 Test A), SEER user/standard (AHRI 210/240 Tes |
| 25 | `ZoneEquipmentManager.cc` | 7 | 7411 | runtime/multi_zone.py, hvac/zone_exhaust_control.py | Zone equipment dispatch in multi-zone runtime. `ZoneHVAC:ExhaustControl` records parsed + wired into BuildingModel (load-only). |
| 26 | `SingleDuct.cc` | 7 | 6393 | hvac/airterminal_vav/records.py, hvac/air_terminals.py | Single duct terminal records parsed. |
| 27 | `WindowComplexManager.cc` | 7 | 3947 | windows/complex_fenestration.py, windows/complex_shade.py | Complex fenestration system records parsed. |
| 28 | `ThermalComfort.cc` | 7 | 3611 | internal_gains/people_extended.py | Thermal comfort model (Fanger, Pierce, KSU) configuration records. |
| 29 | `UserDefinedComponents.cc` | 7 | 3443 | hvac/zone_hvac.py (ZoneHVACForcedAirUserDefined), hvac/airterminal_cv/records.py | User-defined HVAC records parsed. |
| 30 | `HVACDXHeatPumpSystem.cc` | 7 | 1393 | hvac/coils_heating/records.py | 3/3 IDD object types parsed (records present; reconciled from coverage). |

