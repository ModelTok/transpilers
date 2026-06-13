from Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataRootFinder import DataRootFinder
from EnergyPlus.RootFinder import RootFinder

@fixture
def EnergyPlusFixture_RootFinder_CheckConvergence(state: EnergyPlusData):
    var rootFinderData: DataRootFinder.RootFinderDataType
    var slopeType: DataRootFinder.Slope = DataRootFinder.Slope.Decreasing
    var methodType: DataRootFinder.RootFinderMethod = DataRootFinder.RootFinderMethod.Brent
    var relativeXTolerance: Float64 = 0.0
    var absoluteXTolerance: Float64 = 1.0e-6
    var absoluteYTolerance: Float64 = 1.0e-5
    RootFinder.SetupRootFinder(state, rootFinderData, slopeType, methodType, relativeXTolerance, absoluteXTolerance, absoluteYTolerance)
    assert rootFinderData.StatusFlag == DataRootFinder.RootFinderStatus.None
    var xMin: Float64 = 0.0
    var xMax: Float64 = 100.0
    RootFinder.InitializeRootFinder(state, rootFinderData, xMin, xMax)
    assert rootFinderData.StatusFlag == DataRootFinder.RootFinderStatus.None
    var isDone: Bool = False
    var xValue: Float64 = xMin
    var yValue: Float64 = 100.0
    RootFinder.IterateRootFinder(state, rootFinderData, xValue, yValue, isDone)
    assert rootFinderData.StatusFlag == DataRootFinder.RootFinderStatus.None
    assert not isDone
    xValue = xMax
    yValue = -100.0
    RootFinder.IterateRootFinder(state, rootFinderData, xValue, yValue, isDone)
    assert rootFinderData.StatusFlag == DataRootFinder.RootFinderStatus.None
    assert not isDone
    xValue = 20.0
    yValue = -1.0
    RootFinder.IterateRootFinder(state, rootFinderData, xValue, yValue, isDone)
    assert rootFinderData.StatusFlag == DataRootFinder.RootFinderStatus.None
    assert not isDone
    xValue = rootFinderData.XCandidate
    yValue = absoluteYTolerance / 2.0
    RootFinder.IterateRootFinder(state, rootFinderData, xValue, yValue, isDone)
    assert rootFinderData.StatusFlag == DataRootFinder.RootFinderStatus.OK
    assert isDone

@fixture
def EnergyPlusFixture_RootFinder_CheckBracketRoundOff(state: EnergyPlusData):
    var rootFinderData: DataRootFinder.RootFinderDataType
    var slopeType: DataRootFinder.Slope = DataRootFinder.Slope.Decreasing
    var methodType: DataRootFinder.RootFinderMethod = DataRootFinder.RootFinderMethod.Brent
    var relativeXTolerance: Float64 = 0.0
    var absoluteXTolerance: Float64 = 1.0e-6
    var absoluteYTolerance: Float64 = 1.0e-5
    RootFinder.SetupRootFinder(state, rootFinderData, slopeType, methodType, relativeXTolerance, absoluteXTolerance, absoluteYTolerance)
    assert rootFinderData.StatusFlag == DataRootFinder.RootFinderStatus.None
    var xMin: Float64 = 0.0
    var xMax: Float64 = 100.0
    RootFinder.InitializeRootFinder(state, rootFinderData, xMin, xMax)
    assert rootFinderData.StatusFlag == DataRootFinder.RootFinderStatus.None
    var isDone: Bool = False
    var xValue: Float64 = xMin
    var yValue: Float64 = 100.0
    RootFinder.IterateRootFinder(state, rootFinderData, xValue, yValue, isDone)
    assert rootFinderData.StatusFlag == DataRootFinder.RootFinderStatus.None
    assert not isDone
    xValue = xMax
    yValue = -100.0
    RootFinder.IterateRootFinder(state, rootFinderData, xValue, yValue, isDone)
    assert rootFinderData.StatusFlag == DataRootFinder.RootFinderStatus.None
    assert not isDone
    xValue = 20.0
    yValue = -10.0
    RootFinder.IterateRootFinder(state, rootFinderData, xValue, yValue, isDone)
    assert rootFinderData.StatusFlag == DataRootFinder.RootFinderStatus.None
    assert not isDone
    xValue = xValue - absoluteXTolerance / 3.0
    yValue = 10.0
    RootFinder.IterateRootFinder(state, rootFinderData, xValue, yValue, isDone)
    assert rootFinderData.StatusFlag == DataRootFinder.RootFinderStatus.None
    assert not isDone
    xValue = rootFinderData.XCandidate
    yValue = 5.0
    RootFinder.IterateRootFinder(state, rootFinderData, xValue, yValue, isDone)
    assert rootFinderData.StatusFlag == DataRootFinder.RootFinderStatus.OKRoundOff
    assert isDone