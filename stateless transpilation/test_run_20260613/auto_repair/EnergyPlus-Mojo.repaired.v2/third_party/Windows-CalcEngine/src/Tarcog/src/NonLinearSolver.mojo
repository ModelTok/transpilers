from WCECommon import FenestrationCommon
from HeatFlowBalance import CHeatFlowBalance
from IGU import CIGU
from TarcogConstants import IterationConstants

struct CNonLinearSolver:
    var m_IGU: CIGU
    var m_LinearSolver: FenestrationCommon.CLinearSolver
    var m_QBalance: CHeatFlowBalance
    var m_IGUState: List[Float64]
    var m_Tolerance: Float64
    var m_Iterations: UInt
    var m_RelaxParam: Float64
    var m_SolutionTolerance: Float64

    def __init__(inout self, t_IGU: CIGU, numberOfIterations: UInt = 0):
        self.m_IGU = t_IGU
        self.m_LinearSolver = FenestrationCommon.CLinearSolver()
        self.m_QBalance = CHeatFlowBalance(self.m_IGU)
        self.m_Tolerance = IterationConstants.CONVERGENCE_TOLERANCE
        self.m_Iterations = numberOfIterations
        self.m_RelaxParam = IterationConstants.RELAXATION_PARAMETER_MAX
        self.m_SolutionTolerance = 0.0

    def calculateTolerance(self, borrowed t_Solution: List[Float64]) -> Float64:
        assert(len(t_Solution) == len(self.m_IGUState))
        var aError = abs(t_Solution[0] - self.m_IGUState[0])
        for i in range(1, len(self.m_IGUState)):
            aError = max(aError, abs(t_Solution[i] - self.m_IGUState[i]))
        return aError

    def estimateNewState(inout self, borrowed t_Solution: List[Float64]):
        assert(len(t_Solution) == len(self.m_IGUState))
        for i in range(len(self.m_IGUState)):
            self.m_IGUState[i] = self.m_RelaxParam * t_Solution[i] + (1 - self.m_RelaxParam) * self.m_IGUState[i]

    def setTolerance(inout self, t_Tolerance: Float64):
        self.m_Tolerance = t_Tolerance

    def getNumOfIterations(self) -> UInt:
        return self.m_Iterations

    def solve(inout self):
        self.m_IGUState = self.m_IGU.getState()
        let initialState = List[Float64](self.m_IGUState)
        var bestSolution = List[Float64](self.m_IGUState.size(), 0.0)
        var achievedTolerance = 1000.0
        self.m_SolutionTolerance = achievedTolerance
        self.m_Iterations = 0
        var iterate = True
        while iterate:
            self.m_Iterations += 1
            var aSolution = self.m_QBalance.calcBalanceMatrix()
            achievedTolerance = self.calculateTolerance(aSolution)
            self.estimateNewState(aSolution)
            self.m_IGU.setState(self.m_IGUState)
            self.m_IGU.updateDeflectionState()
            if achievedTolerance < self.m_SolutionTolerance:
                initialState = List[Float64](self.m_IGUState)
                self.m_SolutionTolerance = min(achievedTolerance, self.m_SolutionTolerance)
                bestSolution = List[Float64](self.m_IGUState)
            if self.m_Iterations > IterationConstants.NUMBER_OF_STEPS:
                self.m_Iterations = 0
                self.m_RelaxParam -= IterationConstants.RELAXATION_PARAMETER_STEP
                self.m_IGU.setState(initialState)
                self.m_IGUState = List[Float64](initialState)
            iterate = achievedTolerance > self.m_Tolerance
            if self.m_RelaxParam < IterationConstants.RELAXATION_PARAMETER_MIN:
                iterate = False
        self.m_IGUState = bestSolution

    def solutionTolerance(self) -> Float64:
        return self.m_SolutionTolerance

    def isToleranceAchieved(self) -> Bool:
        return self.m_SolutionTolerance < self.m_Tolerance