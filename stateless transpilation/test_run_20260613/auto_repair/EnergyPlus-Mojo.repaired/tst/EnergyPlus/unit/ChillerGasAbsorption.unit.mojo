from EnergyPlus.ChillerGasAbsorption import *
from EnergyPlus.Data.EnergyPlusData import *
from EnergyPlus.Plant.DataPlant import *
from EnergyPlus.PlantUtilities import *
from Fixtures.EnergyPlusFixture import *
from EnergyPlus import Constant

struct GasAbsorptionTest(EnergyPlusFixture):
    @test
    def GasAbsorption_GetInput_Test(self):
        var idf_objects = """
  ChillerHeater:Absorption:DirectFired,                                                                      
    Big Chiller,             !- Name                                                                         
    100000,                  !- Nominal Cooling Capacity {W}                                                 
    0.8,                     !- Heating to Cooling Capacity Ratio                                            
    0.97,                    !- Fuel Input to Cooling Output Ratio                                           
    1.25,                    !- Fuel Input to Heating Output Ratio                                           
    0.01,                    !- Electric Input to Cooling Output Ratio                                       
    0.005,                   !- Electric Input to Heating Output Ratio                                       
    Big Chiller Inlet Node,  !- Chilled Water Inlet Node Name                                                
    Big Chiller Outlet Node, !- Chilled Water Outlet Node Name                                               
    Big Chiller Condenser Inlet Node,  !- Condenser Inlet Node Name                                          
    Big Chiller Condenser Outlet Node,  !- Condenser Outlet Node Name                                        
    Purchased Heat Inlet Node,  !- Hot Water Inlet Node Name                                                 
    Purchased Heat Outlet Node,  !- Hot Water Outlet Node Name                                               
    0.000001,                !- Minimum Part Load Ratio                                                      
    1.0,                     !- Maximum Part Load Ratio                                                      
    0.6,                     !- Optimum Part Load Ratio                                                      
    29,                      !- Design Entering Condenser Water Temperature {C}                              
    7,                       !- Design Leaving Chilled Water Temperature {C}                                 
    0.0011,                  !- Design Chilled Water Flow Rate {m3/s}                                        
    0.0011,                  !- Design Condenser Water Flow Rate {m3/s}                                      
    0.0043,                  !- Design Hot Water Flow Rate {m3/s}                                            
    GasAbsFlatBiQuad,        !- Cooling Capacity Function of Temperature Curve Name                          
    GasAbsFlatBiQuad,        !- Fuel Input to Cooling Output Ratio Function of Temperature Curve Name        
    GasAbsLinearQuad,        !- Fuel Input to Cooling Output Ratio Function of Part Load Ratio Curve Name    
    GasAbsFlatBiQuad,        !- Electric Input to Cooling Output Ratio Function of Temperature Curve Name    
    GasAbsFlatQuad,          !- Electric Input to Cooling Output Ratio Function of Part Load Ratio Curve Name
    GasAbsInvLinearQuad,     !- Heating Capacity Function of Cooling Capacity Curve Name                     
    GasAbsLinearQuad,        !- Fuel Input to Heat Output Ratio During Heating Only Operation Curve Name     
    EnteringCondenser,       !- Temperature Curve Input Variable                                             
    AirCooled,               !- Condenser Type                                                               
    2,                       !- Chilled Water Temperature Lower Limit {C}                                    
    0,                       !- Fuel Higher Heating Value {kJ/kg}                                            
    NaturalGas,              !- Fuel Type                                                                    
    ;                        !- Sizing Factor                                                                
                                                                                                             
  Curve:Biquadratic,                                                                                         
    GasAbsFlatBiQuad,        !- Name                                                                         
    1.000000000,             !- Coefficient1 Constant                                                        
    0.000000000,             !- Coefficient2 x                                                               
    0.000000000,             !- Coefficient3 x**2                                                            
    0.000000000,             !- Coefficient4 y                                                               
    0.000000000,             !- Coefficient5 y**2                                                            
    0.000000000,             !- Coefficient6 x*y                                                             
    0.,                      !- Minimum Value of x                                                           
    50.,                     !- Maximum Value of x                                                           
    0.,                      !- Minimum Value of y                                                           
    50.;                     !- Maximum Value of y                                                           
                                                                                                             
  Curve:Quadratic,                                                                                           
    GasAbsFlatQuad,          !- Name                                                                         
    1.000000000,             !- Coefficient1 Constant                                                        
    0.000000000,             !- Coefficient2 x                                                               
    0.000000000,             !- Coefficient3 x**2                                                            
    0.,                      !- Minimum Value of x                                                           
    50.;                     !- Maximum Value of x                                                           
                                                                                                             
  Curve:Quadratic,                                                                                           
    GasAbsLinearQuad,        !- Name                                                                         
    0.000000000,             !- Coefficient1 Constant                                                        
    1.000000000,             !- Coefficient2 x                                                               
    0.000000000,             !- Coefficient3 x**2                                                            
    0.,                      !- Minimum Value of x                                                           
    50.;                     !- Maximum Value of x                                                           
                                                                                                             
  Curve:Quadratic,                                                                                           
    GasAbsInvLinearQuad,     !- Name                                                                         
    1.000000000,             !- Coefficient1 Constant                                                        
    -1.000000000,            !- Coefficient2 x                                                               
    0.000000000,             !- Coefficient3 x**2                                                            
    0.,                      !- Minimum Value of x                                                           
    50.;                     !- Maximum Value of x                                                           
"""
        ASSERT_TRUE(process_idf(idf_objects))
        state.init_state(state)
        GetGasAbsorberInput(state)
        EXPECT_EQ(state.dataChillerGasAbsorption.GasAbsorber.size(), 1)
        EXPECT_EQ(state.dataChillerGasAbsorption.GasAbsorber[0].Name, "BIG CHILLER")
        EXPECT_NEAR(state.dataChillerGasAbsorption.GasAbsorber[0].NomCoolingCap, 100000.0, 0.0)
        EXPECT_NEAR(state.dataChillerGasAbsorption.GasAbsorber[0].NomHeatCoolRatio, 0.8, 0.0)
        EXPECT_NEAR(state.dataChillerGasAbsorption.GasAbsorber[0].FuelCoolRatio, 0.97, 0.0)
        EXPECT_NEAR(state.dataChillerGasAbsorption.GasAbsorber[0].FuelHeatRatio, 1.25, 0.0)
        EXPECT_NEAR(state.dataChillerGasAbsorption.GasAbsorber[0].ElecCoolRatio, 0.01, 0.0)
        EXPECT_NEAR(state.dataChillerGasAbsorption.GasAbsorber[0].ElecHeatRatio, 0.005, 0.0)
        EXPECT_NEAR(state.dataChillerGasAbsorption.GasAbsorber[0].MinPartLoadRat, 0.000001, 0.0)
        EXPECT_NEAR(state.dataChillerGasAbsorption.GasAbsorber[0].MaxPartLoadRat, 1.0, 0.0)
        EXPECT_NEAR(state.dataChillerGasAbsorption.GasAbsorber[0].OptPartLoadRat, 0.6, 0.0)
        EXPECT_NEAR(state.dataChillerGasAbsorption.GasAbsorber[0].TempDesCondReturn, 29.0, 0.0)
        EXPECT_NEAR(state.dataChillerGasAbsorption.GasAbsorber[0].TempDesCHWSupply, 7.0, 0.0)
        EXPECT_NEAR(state.dataChillerGasAbsorption.GasAbsorber[0].EvapVolFlowRate, 0.0011, 0.0)
        EXPECT_NEAR(state.dataChillerGasAbsorption.GasAbsorber[0].HeatVolFlowRate, 0.0043, 0.0)
        EXPECT_TRUE(state.dataChillerGasAbsorption.GasAbsorber[0].isEnterCondensTemp)
        EXPECT_FALSE(state.dataChillerGasAbsorption.GasAbsorber[0].isWaterCooled)
        EXPECT_NEAR(state.dataChillerGasAbsorption.GasAbsorber[0].CHWLowLimitTemp, 2.0, 0.0)
        EXPECT_ENUM_EQ(state.dataChillerGasAbsorption.GasAbsorber[0].FuelType, Constant.eFuel.NaturalGas)

    @test
    def GasAbsorption_getDesignCapacities_Test(self):
        state.init_state(state)
        state.dataPlnt.TotNumLoops = 3
        state.dataPlnt.PlantLoop.allocate(state.dataPlnt.TotNumLoops)
        state.dataPlnt.PlantLoop[0].LoopSide(DataPlant.LoopSideLocation.Demand).TotalBranches = 3
        state.dataPlnt.PlantLoop[0].LoopSide(DataPlant.LoopSideLocation.Demand).Branch.allocate(3)
        state.dataPlnt.PlantLoop[0].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].TotalComponents = 2
        state.dataPlnt.PlantLoop[0].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp.allocate(2)
        state.dataPlnt.PlantLoop[0].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp[0].NodeNumIn = 100
        state.dataPlnt.PlantLoop[0].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp[1].NodeNumIn = 111
        state.dataPlnt.PlantLoop[1].LoopSide(DataPlant.LoopSideLocation.Demand).TotalBranches = 3
        state.dataPlnt.PlantLoop[1].LoopSide(DataPlant.LoopSideLocation.Demand).Branch.allocate(3)
        state.dataPlnt.PlantLoop[1].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].TotalComponents = 2
        state.dataPlnt.PlantLoop[1].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp.allocate(2)
        state.dataPlnt.PlantLoop[1].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp[0].NodeNumIn = 200
        state.dataPlnt.PlantLoop[1].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp[1].NodeNumIn = 222
        state.dataPlnt.PlantLoop[2].LoopSide(DataPlant.LoopSideLocation.Demand).TotalBranches = 4
        state.dataPlnt.PlantLoop[2].LoopSide(DataPlant.LoopSideLocation.Demand).Branch.allocate(4)
        state.dataPlnt.PlantLoop[2].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].TotalComponents = 2
        state.dataPlnt.PlantLoop[2].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp.allocate(2)
        state.dataPlnt.PlantLoop[2].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp[0].NodeNumIn = 300
        state.dataPlnt.PlantLoop[2].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp[1].NodeNumIn = 333
        var thisChillerHeater: GasAbsorberSpecs
        thisChillerHeater.ChillReturnNodeNum = 111
        thisChillerHeater.HeatReturnNodeNum = 222
        thisChillerHeater.CondReturnNodeNum = 333
        var loc_1 = PlantLocation(1, DataPlant.LoopSideLocation.Demand, 1, 1)
        PlantUtilities.SetPlantLocationLinks(state, loc_1)
        var maxload: Real64 = -1.0
        var minload: Real64 = -1.0
        var optload: Real64 = -1.0
        thisChillerHeater.NomCoolingCap = 100000.0
        thisChillerHeater.MinPartLoadRat = 0.1
        thisChillerHeater.MaxPartLoadRat = 0.9
        thisChillerHeater.OptPartLoadRat = 0.8
        thisChillerHeater.getDesignCapacities(state, loc_1, maxload, minload, optload)
        EXPECT_NEAR(minload, 10000.0, 0.001)
        EXPECT_NEAR(maxload, 90000.0, 0.001)
        EXPECT_NEAR(optload, 80000.0, 0.001)
        thisChillerHeater.NomHeatCoolRatio = 0.9
        var loc_2 = PlantLocation(2, DataPlant.LoopSideLocation.Demand, 1, 1)
        PlantUtilities.SetPlantLocationLinks(state, loc_2)
        thisChillerHeater.getDesignCapacities(state, loc_2, maxload, minload, optload)
        EXPECT_NEAR(minload, 9000.0, 0.001)
        EXPECT_NEAR(maxload, 81000.0, 0.001)
        EXPECT_NEAR(optload, 72000.0, 0.001)
        var loc_3 = PlantLocation(3, DataPlant.LoopSideLocation.Demand, 1, 1)
        PlantUtilities.SetPlantLocationLinks(state, loc_3)
        thisChillerHeater.getDesignCapacities(state, loc_3, maxload, minload, optload)
        EXPECT_NEAR(minload, 0.0, 0.001)
        EXPECT_NEAR(maxload, 0.0, 0.001)
        EXPECT_NEAR(optload, 0.0, 0.001)

    @test
    def GasAbsorption_calculateHeater_Fix_Test(self):
        var idf_objects = """
  ChillerHeater:Absorption:DirectFired,                                                                      
    Big Chiller,             !- Name                                                                         
    100000,                  !- Nominal Cooling Capacity {W}                                                 
    0.8,                     !- Heating to Cooling Capacity Ratio                                            
    0.97,                    !- Fuel Input to Cooling Output Ratio                                           
    1.25,                    !- Fuel Input to Heating Output Ratio                                           
    0.01,                    !- Electric Input to Cooling Output Ratio                                       
    0.005,                   !- Electric Input to Heating Output Ratio                                       
    Big Chiller Inlet Node,  !- Chilled Water Inlet Node Name                                                
    Big Chiller Outlet Node, !- Chilled Water Outlet Node Name                                               
    Big Chiller Condenser Inlet Node,  !- Condenser Inlet Node Name                                          
    Big Chiller Condenser Outlet Node,  !- Condenser Outlet Node Name                                        
    Purchased Heat Inlet Node,  !- Hot Water Inlet Node Name                                                 
    Purchased Heat Outlet Node,  !- Hot Water Outlet Node Name                                               
    0.000001,                !- Minimum Part Load Ratio                                                      
    1.0,                     !- Maximum Part Load Ratio                                                      
    0.6,                     !- Optimum Part Load Ratio                                                      
    29,                      !- Design Entering Condenser Water Temperature {C}                              
    7,                       !- Design Leaving Chilled Water Temperature {C}                                 
    0.0011,                  !- Design Chilled Water Flow Rate {m3/s}                                        
    0.0011,                  !- Design Condenser Water Flow Rate {m3/s}                                      
    0.0043,                  !- Design Hot Water Flow Rate {m3/s}                                            
    GasAbsFlatBiQuad,        !- Cooling Capacity Function of Temperature Curve Name                          
    GasAbsFlatBiQuad,        !- Fuel Input to Cooling Output Ratio Function of Temperature Curve Name        
    GasAbsLinearQuad,        !- Fuel Input to Cooling Output Ratio Function of Part Load Ratio Curve Name    
    GasAbsFlatBiQuad,        !- Electric Input to Cooling Output Ratio Function of Temperature Curve Name    
    GasAbsFlatQuad,          !- Electric Input to Cooling Output Ratio Function of Part Load Ratio Curve Name
    GasAbsInvLinearQuad,     !- Heating Capacity Function of Cooling Capacity Curve Name                     
    GasAbsLinearQuad,        !- Fuel Input to Heat Output Ratio During Heating Only Operation Curve Name     
    EnteringCondenser,       !- Temperature Curve Input Variable                                             
    AirCooled,               !- Condenser Type                                                               
    2,                       !- Chilled Water Temperature Lower Limit {C}                                    
    0,                       !- Fuel Higher Heating Value {kJ/kg}                                            
    NaturalGas,              !- Fuel Type                                                                    
    ;                        !- Sizing Factor                                                                
                                                                                                             
  Curve:Biquadratic,                                                                                         
    GasAbsFlatBiQuad,        !- Name                                                                         
    1.000000000,             !- Coefficient1 Constant                                                        
    0.000000000,             !- Coefficient2 x                                                               
    0.000000000,             !- Coefficient3 x**2                                                            
    0.000000000,             !- Coefficient4 y                                                               
    0.000000000,             !- Coefficient5 y**2                                                            
    0.000000000,             !- Coefficient6 x*y                                                             
    0.,                      !- Minimum Value of x                                                           
    50.,                     !- Maximum Value of x                                                           
    0.,                      !- Minimum Value of y                                                           
    50.;                     !- Maximum Value of y                                                           
                                                                                                             
  Curve:Quadratic,                                                                                           
    GasAbsFlatQuad,          !- Name                                                                         
    1.000000000,             !- Coefficient1 Constant                                                        
    0.000000000,             !- Coefficient2 x                                                               
    0.000000000,             !- Coefficient3 x**2                                                            
    0.,                      !- Minimum Value of x                                                           
    50.;                     !- Maximum Value of x                                                           
                                                                                                             
  Curve:Quadratic,                                                                                           
    GasAbsLinearQuad,        !- Name                                                                         
    0.000000000,             !- Coefficient1 Constant                                                        
    1.000000000,             !- Coefficient2 x                                                               
    0.000000000,             !- Coefficient3 x**2                                                            
    0.,                      !- Minimum Value of x                                                           
    50.;                     !- Maximum Value of x                                                           
                                                                                                             
  Curve:Quadratic,                                                                                           
    GasAbsInvLinearQuad,     !- Name                                                                         
    1.000000000,             !- Coefficient1 Constant                                                        
    -1.000000000,            !- Coefficient2 x                                                               
    0.000000000,             !- Coefficient3 x**2                                                            
    0.,                      !- Minimum Value of x                                                           
    50.;                     !- Maximum Value of x                                                           
"""
        ASSERT_TRUE(process_idf(idf_objects))
        compare_err_stream("")
        state.init_state(state)
        GetGasAbsorberInput(state)
        ref thisChillerHeater = state.dataChillerGasAbsorption.GasAbsorber[0]
        var loadinput: Real64 = 5000.0
        var runflaginput: Bool = true
        thisChillerHeater.CoolingLoad = 100000.0
        thisChillerHeater.CoolPartLoadRatio = 1.0
        state.dataPlnt.TotNumLoops = 1
        state.dataPlnt.PlantLoop.allocate(state.dataPlnt.TotNumLoops)
        thisChillerHeater.HWplantLoc.loopNum = 1
        thisChillerHeater.HWplantLoc.loopSideNum = DataPlant.LoopSideLocation.Demand
        PlantUtilities.SetPlantLocationLinks(state, thisChillerHeater.HWplantLoc)
        state.dataPlnt.PlantLoop[0].FluidName = "WATER"
        state.dataPlnt.PlantLoop[0].glycol = Fluid.GetWater(state)
        state.dataPlnt.PlantLoop[0].LoopDemandCalcScheme = DataPlant.LoopDemandCalcScheme.SingleSetPoint
        state.dataPlnt.PlantLoop[0].LoopSide(DataPlant.LoopSideLocation.Demand).FlowLock = DataPlant.FlowLock.Locked
        state.dataLoopNodes.Node[2].Temp = 60.0
        state.dataLoopNodes.Node[2].MassFlowRate = 0.5
        state.dataLoopNodes.Node[3].TempSetPoint = 70.0
        thisChillerHeater.calculateHeater(state, loadinput, runflaginput)
        EXPECT_NEAR(thisChillerHeater.HeatingLoad, 21085.0, 1e-6)
        EXPECT_NEAR(thisChillerHeater.HeatElectricPower, 400.0, 1e-6)
        EXPECT_NEAR(thisChillerHeater.HotWaterReturnTemp, 60.0, 1e-6)
        EXPECT_NEAR(thisChillerHeater.HotWaterSupplyTemp, 70.0, 1e-6)
        EXPECT_NEAR(thisChillerHeater.HotWaterFlowRate, 0.5, 1e-6)
        EXPECT_NEAR(thisChillerHeater.ElectricPower, 400.0, 1e-6)
        EXPECT_NEAR(thisChillerHeater.HeatPartLoadRatio, 0.0, 1e-6)
        EXPECT_NEAR(thisChillerHeater.HeatingCapacity, 0.0, 1e-6)
        EXPECT_NEAR(thisChillerHeater.FractionOfPeriodRunning, 1.0, 1e-6)