from .Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataBranchAirLoopPlant import DataBranchAirLoopPlant
from EnergyPlus.DataEnvironment import DataEnvironment
from EnergyPlus.DataGlobalConstants import DataGlobalConstants
from EnergyPlus.DataSizing import DataSizing
from EnergyPlus.FluidProperties import FluidProperties
from EnergyPlus.Plant.DataPlant import DataPlant
from EnergyPlus.PlantLoadProfile import PlantLoadProfile, GetPlantProfileInput
from EnergyPlus.PlantUtilities import PlantUtilities
from EnergyPlus.ScheduleManager import ScheduleManager

using EnergyPlus
using PlantLoadProfile

struct EnergyPlusFixture_Tests(EnergyPlusFixture):
    def LoadProfile_GetInput(self):
        let idf_objects: String = delimited_string({
            "  Schedule:Compact,",
            "    Load Profile Load Schedule,    !- Name                       ",
            "    Any Number,                    !- Schedule Type Limits Name  ",
            "    THROUGH: 12/31,                !- Field 1                    ",
            "    FOR: AllDays,                  !- Field 2                    ",
            "    UNTIL: 24:00,10000;            !- Field 3                    ",
            "  Schedule:Compact,",
            "    Load Profile Flow Frac Schedule,     !- Name                       ",
            "    Any Number,                          !- Schedule Type Limits Name  ",
            "    THROUGH: 12/31,                      !- Field 1                    ",
            "    FOR: AllDays,                        !- Field 2                    ",
            "    UNTIL: 24:00,1.0;                    !- Field 3                    ",
            "  LoadProfile:Plant,",
            "    Load Profile Water,                     !- Name                              ",
            "    Demand Load Profile Water Inlet Node,   !- Inlet Node Name                   ",
            "    Demand Load Profile Water Outlet Node,  !- Outlet Node Name                  ",
            "    Load Profile Load Schedule,             !- Load Schedule Name                ",
            "    0.002,                                  !- Peak Flow Rate {m3/s}             ",
            "    Load Profile Flow Frac Schedule,        !- Flow Rate Fraction Schedule Name  ",
            "    Water;                                  !- Plant Loop Fluid Type             ",
            "  LoadProfile:Plant,",
            "    Load Profile Steam,                     !- Name                              ",
            "    Demand Load Profile Steam Inlet Node,   !- Inlet Node Name                   ",
            "    Demand Load Profile Steam Outlet Node,  !- Outlet Node Name                  ",
            "    Load Profile Load Schedule,             !- Load Schedule Name                ",
            "    0.008,                                  !- Peak Flow Rate {m3/s}             ",
            "    Load Profile Flow Frac Schedule,        !- Flow Rate Fraction Schedule Name  ",
            "    Steam;                                  !- Plant Loop Fluid Type             ",
        })
        ASSERT_TRUE(process_idf(idf_objects, false))
        self.state.init_state(*self.state)
        GetPlantProfileInput(*self.state)
        EXPECT_EQ(self.state.dataPlantLoadProfile.PlantProfile[0].Name, "LOAD PROFILE WATER")
        EXPECT_ENUM_EQ(self.state.dataPlantLoadProfile.PlantProfile[0].FluidType, PlantLoopFluidType.Water)
        EXPECT_EQ(self.state.dataPlantLoadProfile.PlantProfile[0].PeakVolFlowRate, 0.002)
        EXPECT_EQ(self.state.dataPlantLoadProfile.PlantProfile[1].Name, "LOAD PROFILE STEAM")
        EXPECT_ENUM_EQ(self.state.dataPlantLoadProfile.PlantProfile[1].FluidType, PlantLoopFluidType.Steam)
        EXPECT_EQ(self.state.dataPlantLoadProfile.PlantProfile[1].PeakVolFlowRate, 0.008)
        EXPECT_EQ(self.state.dataPlantLoadProfile.PlantProfile[1].DegOfSubcooling, 5.0)
        EXPECT_EQ(self.state.dataPlantLoadProfile.PlantProfile[1].LoopSubcoolReturn, 20.0)

    def LoadProfile_initandsimulate_Waterloop(self):
        self.state.init_state(*self.state)
        self.state.dataPlnt.PlantLoop.allocate(1)
        self.state.dataLoopNodes.Node.allocate(2)
        self.state.dataPlantLoadProfile.PlantProfile.allocate(1)
        var thisWaterLoop = self.state.dataPlnt.PlantLoop[0]
        thisWaterLoop.FluidName = "WATER"
        thisWaterLoop.glycol = Fluid.GetWater(*self.state)
        thisWaterLoop.LoopSide(DataPlant.LoopSideLocation.Demand).Branch.allocate(1)
        thisWaterLoop.LoopSide(DataPlant.LoopSideLocation.Demand).TotalBranches = 1
        thisWaterLoop.LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].TotalComponents = 1
        thisWaterLoop.LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp.allocate(1)
        thisWaterLoop.LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp[0].Type = DataPlant.PlantEquipmentType.PlantLoadProfile
        thisWaterLoop.LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp[0].Name = "LOAD PROFILE WATER"
        thisWaterLoop.LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp[0].NodeNumIn = 1
        thisWaterLoop.LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp[0].NodeNumOut = 2
        self.state.dataLoopNodes.Node[0].Temp = 60.0
        self.state.dataLoopNodes.Node[0].MassFlowRateMax = 10
        self.state.dataLoopNodes.Node[0].MassFlowRateMaxAvail = 10
        self.state.dataLoopNodes.Node[1].MassFlowRateMax = 10
        self.state.dataLoopNodes.Node[1].MassFlowRateMaxAvail = 10
        var thisLoadProfileWaterLoop = self.state.dataPlantLoadProfile.PlantProfile[0]
        var locWater = PlantLocation(1, DataPlant.LoopSideLocation.Demand, 1, 1)
        thisLoadProfileWaterLoop.Name = "LOAD PROFILE WATER"
        thisLoadProfileWaterLoop.FluidType = PlantLoopFluidType.Water
        thisLoadProfileWaterLoop.PeakVolFlowRate = 0.002
        thisLoadProfileWaterLoop.loadSched = Sched.AddScheduleConstant(*self.state, "LOAD")
        thisLoadProfileWaterLoop.flowRateFracSched = Sched.AddScheduleConstant(*self.state, "FLOWRATEFRAC")
        thisLoadProfileWaterLoop.InletNode = 1
        thisLoadProfileWaterLoop.OutletNode = 2
        thisLoadProfileWaterLoop.plantLoc = locWater
        thisLoadProfileWaterLoop.plantLoc.loopNum = 1
        PlantUtilities.SetPlantLocationLinks(*self.state, thisLoadProfileWaterLoop.plantLoc)
        thisLoadProfileWaterLoop.loadSched.EMSActuatedOn = false
        thisLoadProfileWaterLoop.loadSched.currentVal = 10000
        thisLoadProfileWaterLoop.flowRateFracSched.EMSActuatedOn = false
        thisLoadProfileWaterLoop.flowRateFracSched.currentVal = 0.8
        thisLoadProfileWaterLoop.InitPlantProfile(*self.state)
        EXPECT_EQ(thisLoadProfileWaterLoop.InletTemp, 60.0)
        EXPECT_EQ(thisLoadProfileWaterLoop.Power, 10000)
        EXPECT_EQ(thisLoadProfileWaterLoop.VolFlowRate, 0.0016)
        var firstHVAC: Bool = true
        var curLoad: Real64 = 10000.0
        var runFlag: Bool = true
        var RoutineName: String = "PlantLoadProfileTests"
        thisLoadProfileWaterLoop.simulate(*self.state, locWater, firstHVAC, curLoad, runFlag)
        var rhoWater = thisWaterLoop.glycol.getDensity(*self.state, 60, RoutineName)
        var Cp = thisWaterLoop.glycol.getSpecificHeat(*self.state, thisLoadProfileWaterLoop.InletTemp, RoutineName)
        var deltaTemp = curLoad / (rhoWater * thisLoadProfileWaterLoop.VolFlowRate * Cp)
        var calOutletTemp = thisLoadProfileWaterLoop.InletTemp - deltaTemp
        EXPECT_EQ(thisLoadProfileWaterLoop.OutletTemp, calOutletTemp)

    def LoadProfile_initandsimulate_Steamloop(self):
        self.state.init_state(*self.state)
        self.state.dataPlnt.PlantLoop.allocate(1)
        self.state.dataLoopNodes.Node.allocate(2)
        self.state.dataPlantLoadProfile.PlantProfile.allocate(1)
        var thisSteamLoop = self.state.dataPlnt.PlantLoop[0]
        thisSteamLoop.FluidName = "STEAM"
        thisSteamLoop.steam = Fluid.GetSteam(*self.state)
        thisSteamLoop.glycol = Fluid.GetWater(*self.state)
        thisSteamLoop.LoopSide(DataPlant.LoopSideLocation.Demand).Branch.allocate(1)
        thisSteamLoop.LoopSide(DataPlant.LoopSideLocation.Demand).TotalBranches = 1
        thisSteamLoop.LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].TotalComponents = 1
        thisSteamLoop.LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp.allocate(1)
        thisSteamLoop.LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp[0].Type = DataPlant.PlantEquipmentType.PlantLoadProfile
        thisSteamLoop.LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp[0].Name = "LOAD PROFILE STEAM"
        thisSteamLoop.LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp[0].NodeNumIn = 1
        thisSteamLoop.LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp[0].NodeNumOut = 2
        var RoutineName: String = "PlantLoadProfileTests"
        var SatTempAtmPress = self.state.dataPlnt.PlantLoop[0].steam.getSatTemperature(*self.state, DataEnvironment.StdPressureSeaLevel, RoutineName)
        self.state.dataLoopNodes.Node[0].Temp = SatTempAtmPress
        self.state.dataLoopNodes.Node[0].MassFlowRateMax = 1
        self.state.dataLoopNodes.Node[0].MassFlowRateMaxAvail = 1
        self.state.dataLoopNodes.Node[1].MassFlowRateMax = 1
        self.state.dataLoopNodes.Node[1].MassFlowRateMaxAvail = 1
        var thisLoadProfileSteamLoop = self.state.dataPlantLoadProfile.PlantProfile[0]
        var locSteam = PlantLocation(1, DataPlant.LoopSideLocation.Demand, 1, 1)
        thisLoadProfileSteamLoop.Name = "LOAD PROFILE STEAM"
        thisLoadProfileSteamLoop.FluidType = PlantLoopFluidType.Steam
        thisLoadProfileSteamLoop.PeakVolFlowRate = 0.008
        thisLoadProfileSteamLoop.DegOfSubcooling = 3.0
        thisLoadProfileSteamLoop.loadSched = Sched.AddScheduleConstant(*self.state, "LOAD")
        thisLoadProfileSteamLoop.flowRateFracSched = Sched.AddScheduleConstant(*self.state, "FLOWRATEFRAC")
        thisLoadProfileSteamLoop.InletNode = 1
        thisLoadProfileSteamLoop.OutletNode = 2
        thisLoadProfileSteamLoop.plantLoc = locSteam
        thisLoadProfileSteamLoop.plantLoc.loopNum = 1
        PlantUtilities.SetPlantLocationLinks(*self.state, thisLoadProfileSteamLoop.plantLoc)
        thisLoadProfileSteamLoop.loadSched.EMSActuatedOn = false
        thisLoadProfileSteamLoop.loadSched.currentVal = 10000
        thisLoadProfileSteamLoop.flowRateFracSched.EMSActuatedOn = false
        thisLoadProfileSteamLoop.flowRateFracSched.currentVal = 0.8
        thisLoadProfileSteamLoop.InitPlantProfile(*self.state)
        EXPECT_EQ(thisLoadProfileSteamLoop.InletTemp, SatTempAtmPress)
        EXPECT_EQ(thisLoadProfileSteamLoop.Power, 10000)
        EXPECT_EQ(thisLoadProfileSteamLoop.VolFlowRate, 0.0064)
        var firstHVAC: Bool = true
        var curLoad: Real64 = 10000.0
        var runFlag: Bool = true
        thisLoadProfileSteamLoop.simulate(*self.state, locSteam, firstHVAC, curLoad, runFlag)
        var EnthSteamIn = thisSteamLoop.steam.getSatEnthalpy(*self.state, SatTempAtmPress, 1.0, RoutineName)
        var EnthSteamOut = thisSteamLoop.steam.getSatEnthalpy(*self.state, SatTempAtmPress, 0.0, RoutineName)
        var LatentHeatSteam = EnthSteamIn - EnthSteamOut
        var CpCondensate = thisSteamLoop.glycol.getSpecificHeat(*self.state, SatTempAtmPress, RoutineName)
        var calOutletMdot = curLoad / (LatentHeatSteam + thisLoadProfileSteamLoop.DegOfSubcooling * CpCondensate)
        EXPECT_EQ(thisLoadProfileSteamLoop.MassFlowRate, calOutletMdot)