from Fixtures.EnergyPlusFixture import EnergyPlusFixture, delimited_string, process_idf
from EnergyPlus.OutsideEnergySources import GetOutsideEnergySourcesInput
from EnergyPlus.FluidProperties import GetWater, GetSteam
from EnergyPlus.Plant.DataPlant import PlantEquipmentType, LoopSideLocation, PlantLocation
from EnergyPlus.Plant.DataPlant import PurchHotWater, PurchChilledWater, PurchSteam
from EnergyPlus.PlantUtilities import SetPlantLocationLinks
from EnergyPlus.DataEnvironment import StdPressureSeaLevel

def test_DistrictCoolingandHeating():
    var state = EnergyPlusFixture()
    var idf_objects = String(
        "  DistrictCooling,\n"
        "    Purchased Cooling,              !- Name                            \n"
        "    Purchased Cooling Inlet Node,   !- Chilled Water Inlet Node Name   \n"
        "    Purchased Cooling Outlet Node,  !- Chilled Water Outlet Node Name  \n"
        "    900000;                         !- Nominal Capacity {W}            \n"
        "  DistrictHeating:Water,\n"
        "    Purchased Heating,           !- Name                        \n"
        "    Purchased Heat Inlet Node,   !- Hot Water Inlet Node Name   \n"
        "    Purchased Heat Outlet Node,  !- Hot Water Outlet Node Name  \n"
        "    1000000;                     !- Nominal Capacity {W}        \n"
        "  DistrictHeating:Steam,\n"
        "    DistrictHeating Steam,              !- Name                    \n"
        "    DistrictHeating Steam Inlet Node,   !- Steam Inlet Node Name   \n"
        "    DistrictHeating Steam Outlet Node,  !- Steam Outlet Node Name  \n"
        "    1100000;                            !- Nominal Capacity {W}    \n"
    )
    assert process_idf(idf_objects, False), "process_idf failed"
    state.init_state(state)
    GetOutsideEnergySourcesInput(state)
    var thisDistrictHeatingWater = state.dataOutsideEnergySrcs.EnergySource[0]
    var thisDistrictCooling = state.dataOutsideEnergySrcs.EnergySource[1]
    var thisDistrictHeatingSteam = state.dataOutsideEnergySrcs.EnergySource[2]
    assert thisDistrictHeatingWater.EnergyType == PurchHotWater, "EnergyType mismatch"
    assert thisDistrictCooling.EnergyType == PurchChilledWater, "EnergyType mismatch"
    assert thisDistrictHeatingSteam.EnergyType == PurchSteam, "EnergyType mismatch"
    assert thisDistrictHeatingWater.NomCap == 1000000.0, "NomCap mismatch"
    assert thisDistrictCooling.NomCap == 900000.0, "NomCap mismatch"
    assert thisDistrictHeatingSteam.NomCap == 1100000.0, "NomCap mismatch"
    var RunFlag: Bool = True
    var MyLoad: Float64 = 1000000.0
    var firstHVAC: Bool = True
    state.dataGlobal.BeginEnvrnFlag = True
    var RoutineName: String = "OutsideEnergySourcesTests"
    state.dataPlnt.TotNumLoops = 3
    state.dataPlnt.PlantLoop = List[PlantLoop](3)  # allocate 3 elements
    var thisHotWaterLoop = state.dataPlnt.PlantLoop[0]
    var thisChilledWaterLoop = state.dataPlnt.PlantLoop[1]
    var thisSteamLoop = state.dataPlnt.PlantLoop[2]
    var locHotWater = PlantLocation(1, LoopSideLocation.Supply, 1, 1)
    thisHotWaterLoop.Name = "HotWaterLoop"
    thisHotWaterLoop.FluidName = "WATER"
    thisHotWaterLoop.glycol = GetWater(state)
    thisHotWaterLoop.MinTemp = 1.0
    thisHotWaterLoop.MaxTemp = 99.0
    thisHotWaterLoop.MinMassFlowRate = 0.001
    thisHotWaterLoop.MaxMassFlowRate = 20
    thisHotWaterLoop.LoopSide[LoopSideLocation.Supply].Branch = List[BranchType](1)
    thisHotWaterLoop.LoopSide[LoopSideLocation.Supply].TotalBranches = 1
    thisHotWaterLoop.LoopSide[LoopSideLocation.Supply].Branch[0].Comp = List[CompType](1)
    thisHotWaterLoop.LoopSide[LoopSideLocation.Supply].Branch[0].TotalComponents = 1
    thisHotWaterLoop.LoopSide[LoopSideLocation.Supply].Branch[0].Comp[0].Name = thisDistrictHeatingWater.Name
    thisHotWaterLoop.LoopSide[LoopSideLocation.Supply].Branch[0].Comp[0].Type = PurchHotWater
    state.dataLoopNodes.Node[thisDistrictHeatingWater.InletNodeNum - 1].Temp = 55.0
    thisDistrictHeatingWater.plantLoc = locHotWater
    thisDistrictHeatingWater.plantLoc.loopNum = 1
    SetPlantLocationLinks(state, thisDistrictHeatingWater.plantLoc)
    thisDistrictHeatingWater.BeginEnvrnInitFlag = True
    thisDistrictHeatingWater.simulate(state, locHotWater, firstHVAC, MyLoad, RunFlag)
    var Cp: Float64 = thisHotWaterLoop.glycol.getSpecificHeat(state, thisDistrictHeatingWater.InletTemp, RoutineName)
    var calOutletTemp: Float64 = (MyLoad + thisHotWaterLoop.MaxMassFlowRate * Cp * thisDistrictHeatingWater.InletTemp) / (thisHotWaterLoop.MaxMassFlowRate * Cp)
    assert thisDistrictHeatingWater.OutletTemp == calOutletTemp, "Hot water outlet temperature mismatch"
    MyLoad = -900000.0
    var locChilledWater = PlantLocation(2, LoopSideLocation.Supply, 1, 1)
    thisChilledWaterLoop.Name = "ChilledWaterLoop"
    thisChilledWaterLoop.FluidName = "WATER"
    thisChilledWaterLoop.glycol = GetWater(state)
    thisChilledWaterLoop.MinTemp = 1.0
    thisChilledWaterLoop.MaxTemp = 99.0
    thisChilledWaterLoop.MinMassFlowRate = 0.001
    thisChilledWaterLoop.MaxMassFlowRate = 20
    thisChilledWaterLoop.LoopSide[LoopSideLocation.Supply].Branch = List[BranchType](1)
    thisChilledWaterLoop.LoopSide[LoopSideLocation.Supply].TotalBranches = 1
    thisChilledWaterLoop.LoopSide[LoopSideLocation.Supply].Branch[0].Comp = List[CompType](1)
    thisChilledWaterLoop.LoopSide[LoopSideLocation.Supply].Branch[0].TotalComponents = 1
    thisChilledWaterLoop.LoopSide[LoopSideLocation.Supply].Branch[0].Comp[0].Name = thisDistrictCooling.Name
    thisChilledWaterLoop.LoopSide[LoopSideLocation.Supply].Branch[0].Comp[0].Type = PurchChilledWater
    thisChilledWaterLoop.LoopSide[LoopSideLocation.Supply].Branch[0].Comp[0].NodeNumIn = thisDistrictCooling.InletNodeNum
    thisChilledWaterLoop.LoopSide[LoopSideLocation.Supply].Branch[0].Comp[0].NodeNumOut = thisDistrictCooling.OutletNodeNum
    state.dataLoopNodes.Node[thisDistrictCooling.InletNodeNum - 1].Temp = 65.0
    thisDistrictCooling.plantLoc = locChilledWater
    thisDistrictCooling.plantLoc.loopNum = 2
    SetPlantLocationLinks(state, thisDistrictCooling.plantLoc)
    thisDistrictCooling.BeginEnvrnInitFlag = True
    thisDistrictCooling.simulate(state, locChilledWater, firstHVAC, MyLoad, RunFlag)
    Cp = thisChilledWaterLoop.glycol.getSpecificHeat(state, thisDistrictCooling.InletTemp, RoutineName)
    calOutletTemp = (MyLoad + thisChilledWaterLoop.MaxMassFlowRate * Cp * thisDistrictCooling.InletTemp) / (thisChilledWaterLoop.MaxMassFlowRate * Cp)
    assert thisDistrictCooling.OutletTemp == calOutletTemp, "Chilled water outlet temperature mismatch"
    MyLoad = 1100000.0
    var locSteam = PlantLocation(3, LoopSideLocation.Supply, 1, 1)
    thisSteamLoop.Name = "SteamLoop"
    thisSteamLoop.FluidName = "STEAM"
    thisSteamLoop.steam = GetSteam(state)
    thisSteamLoop.glycol = GetWater(state)
    thisSteamLoop.MinMassFlowRate = 0.00001
    thisSteamLoop.MaxMassFlowRate = 20
    thisSteamLoop.TempSetPointNodeNum = thisDistrictHeatingSteam.OutletNodeNum
    thisSteamLoop.LoopSide[LoopSideLocation.Supply].Branch = List[BranchType](1)
    thisSteamLoop.LoopSide[LoopSideLocation.Supply].TotalBranches = 1
    thisSteamLoop.LoopSide[LoopSideLocation.Supply].Branch[0].Comp = List[CompType](1)
    thisSteamLoop.LoopSide[LoopSideLocation.Supply].Branch[0].TotalComponents = 1
    thisSteamLoop.LoopSide[LoopSideLocation.Supply].Branch[0].Comp[0].Name = thisDistrictHeatingSteam.Name
    thisSteamLoop.LoopSide[LoopSideLocation.Supply].Branch[0].Comp[0].Type = PurchSteam
    state.dataLoopNodes.Node[thisDistrictHeatingSteam.InletNodeNum - 1].Temp = 95.0
    state.dataLoopNodes.Node[thisDistrictHeatingSteam.OutletNodeNum - 1].TempSetPoint = 105.0
    thisDistrictHeatingSteam.plantLoc = locSteam
    thisDistrictHeatingSteam.plantLoc.loopNum = 3
    SetPlantLocationLinks(state, thisDistrictHeatingSteam.plantLoc)
    thisDistrictHeatingSteam.BeginEnvrnInitFlag = True
    thisDistrictHeatingSteam.simulate(state, locSteam, firstHVAC, MyLoad, RunFlag)
    var SatTempAtmPress: Float64 = thisSteamLoop.steam.getSatTemperature(state, StdPressureSeaLevel, RoutineName)
    var CpCondensate: Float64 = thisSteamLoop.glycol.getSpecificHeat(state, thisDistrictHeatingSteam.InletTemp, RoutineName)
    var deltaTsensible: Float64 = SatTempAtmPress - thisDistrictHeatingSteam.InletTemp
    var EnthSteamInDry: Float64 = thisSteamLoop.steam.getSatEnthalpy(state, thisDistrictHeatingSteam.InletTemp, 1.0, RoutineName)
    var EnthSteamOutWet: Float64 = thisSteamLoop.steam.getSatEnthalpy(state, thisDistrictHeatingSteam.InletTemp, 0.0, RoutineName)
    var LatentHeatSteam: Float64 = EnthSteamInDry - EnthSteamOutWet
    var calOutletMdot: Float64 = MyLoad / (LatentHeatSteam + (CpCondensate * deltaTsensible))
    assert thisDistrictHeatingSteam.MassFlowRate == calOutletMdot, "Steam mass flow rate mismatch"