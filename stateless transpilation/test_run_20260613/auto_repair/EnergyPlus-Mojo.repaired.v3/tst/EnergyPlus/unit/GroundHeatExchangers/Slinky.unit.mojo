from gtest import Test, EXPECT_EQ, EXPECT_DOUBLE_EQ, EXPECT_NEAR
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.Plant.DataPlant import PlantLoop, Fluid
from EnergyPlus.GroundHeatExchangers.ResponseFactors import GLHEResponseFactors
from EnergyPlus.GroundHeatExchangers.Slinky import GLHESlinky
from ...Fixtures.EnergyPlusFixture import EnergyPlusFixture

@register_test(EnergyPlusFixture)
def GroundHeatExchangerTest_Slinky_GetGFunc():
    thisGLHE = GLHESlinky()
    thisGFunc: Float64
    time: Float64
    NPairs: Int = 2
    thisRF = GLHEResponseFactors()
    thisGLHE.myRespFactors = thisRF
    thisGLHE.myRespFactors.GFNC = List[Float64](NPairs)
    thisGLHE.myRespFactors.LNTTS.append(0.0)
    thisGLHE.myRespFactors.LNTTS.append(5.0)
    thisGLHE.myRespFactors.GFNC[0] = 0.0
    thisGLHE.myRespFactors.GFNC[1] = 5.0
    time = pow(10.0, 2.5)
    thisGFunc = thisGLHE.getGFunc(time)
    EXPECT_EQ(2.5, thisGFunc)

@register_test(EnergyPlusFixture)
def GroundHeatExchangerTest_Interpolate():
    thisGLHE = GLHESlinky()
    thisLNTTS: Float64
    thisGFunc: Float64
    NPairs: Int = 2
    thisRF = GLHEResponseFactors()
    thisGLHE.myRespFactors = thisRF
    thisGLHE.myRespFactors.GFNC = List[Float64](NPairs)
    thisGLHE.myRespFactors.LNTTS.append(0.0)
    thisGLHE.myRespFactors.LNTTS.append(5.0)
    thisGLHE.myRespFactors.GFNC[0] = 0.0
    thisGLHE.myRespFactors.GFNC[1] = 5.0
    thisLNTTS = -1.0
    thisGFunc = thisGLHE.interpGFunc(thisLNTTS)
    EXPECT_DOUBLE_EQ(-1.0, thisGFunc)
    thisLNTTS = 6.0
    thisGFunc = thisGLHE.interpGFunc(thisLNTTS)
    EXPECT_DOUBLE_EQ(6.0, thisGFunc)
    thisLNTTS = 2.5
    thisGFunc = thisGLHE.interpGFunc(thisLNTTS)
    EXPECT_DOUBLE_EQ(2.5, thisGFunc)

@register_test(EnergyPlusFixture)
def GroundHeatExchangerTest_Slinky_CalcHXResistance():
    state.init_state(state)
    thisGLHE = GLHESlinky()
    state.dataPlnt.PlantLoop.allocate(1)
    thisGLHE.plantLoc.loopNum = 1
    state.dataPlnt.PlantLoop[thisGLHE.plantLoc.loopNum - 1].FluidName = "WATER"
    state.dataPlnt.PlantLoop[thisGLHE.plantLoc.loopNum - 1].glycol = Fluid.GetWater(state)
    thisGLHE.inletTemp = 5.0
    thisGLHE.massFlowRate = 0.01
    thisGLHE.numTrenches = 1
    thisGLHE.pipe.outDia = 0.02667
    thisGLHE.pipe.outRadius = thisGLHE.pipe.outDia / 2.0
    thisGLHE.pipe.thickness = 0.004
    thisGLHE.pipe.k = 0.4
    EXPECT_NEAR(0.13487, thisGLHE.calcHXResistance(state), 0.0001)
    thisGLHE.massFlowRate = 0.07
    EXPECT_NEAR(0.08582, thisGLHE.calcHXResistance(state), 0.0001)
    thisGLHE.massFlowRate = 0.1
    EXPECT_NEAR(0.077185, thisGLHE.calcHXResistance(state), 0.0001)
    thisGLHE.massFlowRate = 0.0
    EXPECT_NEAR(0.07094, thisGLHE.calcHXResistance(state), 0.0001)

@register_test(EnergyPlusFixture)
def GroundHeatExchangerTest_Slinky_CalcGroundHeatExchanger():
    thisGLHE = GLHESlinky()
    thisRF = GLHEResponseFactors()
    thisGLHE.myRespFactors = thisRF
    thisGLHE.numCoils = 100
    thisGLHE.numTrenches = 2
    thisGLHE.maxSimYears = 10
    thisGLHE.coilPitch = 0.4
    thisGLHE.coilDepth = 1.5
    thisGLHE.coilDiameter = 0.8
    thisGLHE.pipe.outDia = 0.034
    thisGLHE.pipe.outRadius = thisGLHE.pipe.outDia / 2.0
    thisGLHE.trenchSpacing = 3.0
    thisGLHE.soil.diffusivity = 3.0e-007
    thisGLHE.AGG = 192
    thisGLHE.SubAGG = 15
    thisGLHE.calcGFunctions(state)
    EXPECT_NEAR(19.08237, thisGLHE.myRespFactors.GFNC[27], 0.0001)
    thisGLHE.verticalConfig = True
    thisGLHE.calcGFunctions(state)
    EXPECT_NEAR(18.91819, thisGLHE.myRespFactors.GFNC[27], 0.0001)