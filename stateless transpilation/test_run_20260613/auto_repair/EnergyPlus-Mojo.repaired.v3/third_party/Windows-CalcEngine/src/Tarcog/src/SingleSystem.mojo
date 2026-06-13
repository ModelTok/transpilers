from memory import shared_ptr, make_shared
from map import Map
from vector import Vector
from IGU import CIGU
from BaseLayer import *
from BaseIGULayer import *
from IGUSolidLayer import CIGUSolidLayer
from IGUGapLayer import CIGUGapLayer
from OutdoorEnvironment import COutdoorEnvironment
from IndoorEnvironment import CIndoorEnvironment
from Surface import *
from NonLinearSolver import CNonLinearSolver
from WCECommon import *
from FenestrationCommon import Side
from math import abs
from runtime import assert

enum Environment:
    Indoor
    Outdoor

class CBaseIGULayer:

class CIGUSolidLayer:

class CIGUGapLayer:

class CEnvironment:

class CNonLinearSolver:

@value
class CSingleSystem:
    var m_IGU: CIGU
    var m_Environment: Map[Environment, shared_ptr[CEnvironment]]
    var m_NonLinearSolver: shared_ptr[CNonLinearSolver]

    def __init__(inout self, t_IGU: CIGU, t_Indoor: shared_ptr[CEnvironment], t_Outdoor: shared_ptr[CEnvironment]):
        self.m_IGU = t_IGU
        self.m_Environment = Map[Environment, shared_ptr[CEnvironment]]()
        self.m_Environment[Environment.Indoor] = t_Indoor
        self.m_Environment[Environment.Outdoor] = t_Outdoor
        if t_Indoor is None:
            raise Error("Indoor environment has not been assigned to the system. Null value passed.")
        if t_Outdoor is None:
            raise Error("Outdoor environment has not been assigned to the system. Null value passed.")
        let aIndoorLayer = self.m_IGU.getEnvironment(Environment.Indoor)
        var aIndoor = self.m_Environment[Environment.Indoor]
        aIndoor.connectToIGULayer(aIndoorLayer)
        aIndoor.setTilt(self.m_IGU.getTilt())
        aIndoor.setWidth(self.m_IGU.getWidth())
        aIndoor.setHeight(self.m_IGU.getHeight())
        let aOutdoorLayer = self.m_IGU.getEnvironment(Environment.Outdoor)
        var aOutdoor = self.m_Environment[Environment.Outdoor]
        aOutdoor.connectToIGULayer(aOutdoorLayer)
        aOutdoor.setTilt(self.m_IGU.getTilt())
        aOutdoor.setWidth(self.m_IGU.getWidth())
        aOutdoor.setHeight(self.m_IGU.getHeight())
        let solarRadiation = t_Outdoor.getDirectSolarRadiation()
        self.m_IGU.setSolarRadiation(solarRadiation)
        self.initializeStartValues()
        self.m_NonLinearSolver = make_shared[CNonLinearSolver](self.m_IGU)

    def __copyinit__(inout self, other: CSingleSystem):
        self.m_IGU = other.m_IGU
        self.m_Environment = Map[Environment, shared_ptr[CEnvironment]]()
        self.m_Environment[Environment.Indoor] = other.m_Environment[Environment.Indoor].cloneEnvironment()
        let aLastLayer = self.m_IGU.getEnvironment(Environment.Indoor)
        self.m_Environment[Environment.Indoor].connectToIGULayer(aLastLayer)
        self.m_Environment[Environment.Outdoor] = other.m_Environment[Environment.Outdoor].cloneEnvironment()
        let aFirstLayer = self.m_IGU.getEnvironment(Environment.Outdoor)
        self.m_Environment[Environment.Outdoor].connectToIGULayer(aFirstLayer)
        self.m_NonLinearSolver = make_shared[CNonLinearSolver](self.m_IGU, other.getNumberOfIterations())

    def __del__(inout self):

    def getSolidLayers(self) -> Vector[shared_ptr[CIGUSolidLayer]]:
        return self.m_IGU.getSolidLayers()

    def getGapLayers(self) -> Vector[shared_ptr[CIGUGapLayer]]:
        return self.m_IGU.getGapLayers()

    def getSolidEffectiveLayerConductivities(self) -> Vector[Float64]:
        var results = Vector[Float64]()
        for layer in self.getSolidLayers():
            results.push_back(layer.getEffectiveThermalConductivity())
        return results

    def getGapEffectiveLayerConductivities(self) -> Vector[Float64]:
        var results = Vector[Float64]()
        for layer in self.getGapLayers():
            results.push_back(layer.getEffectiveThermalConductivity())
        return results

    def getTemperatures(self) -> Vector[Float64]:
        return self.m_IGU.getTemperatures()

    def getRadiosities(self) -> Vector[Float64]:
        return self.m_IGU.getRadiosities()

    def getMaxDeflections(self) -> Vector[Float64]:
        return self.m_IGU.getMaxDeflections()

    def getMeanDeflections(self) -> Vector[Float64]:
        return self.m_IGU.getMeanDeflections()

    def getPanesLoad(self) -> Vector[Float64]:
        return self.m_IGU.getPanesLoad()

    def setAppliedLoad(inout self, load: Vector[Float64]):
        self.m_IGU.setAppliedLoad(load)

    def clone(self) -> shared_ptr[CSingleSystem]:
        return make_shared[CSingleSystem](self)

    def getHeatFlow(self, t_Environment: Environment) -> Float64:
        return self.m_Environment[t_Environment].getHeatFlow()

    def getConvectiveHeatFlow(self, t_Environment: Environment) -> Float64:
        return self.m_Environment[t_Environment].getConvectionConductionFlow()

    def getRadiationHeatFlow(self, t_Environment: Environment) -> Float64:
        return self.m_Environment[t_Environment].getRadiationFlow()

    def getHc(self, t_Environment: Environment) -> Float64:
        return self.m_Environment[t_Environment].getHc()

    def getHr(self, t_Environment: Environment) -> Float64:
        return self.m_Environment[t_Environment].getHr()

    def getH(self, t_Environment: Environment) -> Float64:
        return self.getHc(t_Environment) + self.getHr(t_Environment)

    def getAirTemperature(self, t_Environment: Environment) -> Float64:
        return self.m_Environment[t_Environment].getAirTemperature()

    def getVentilationFlow(self, t_Environment: Environment) -> Float64:
        return self.m_IGU.getVentilationFlow(t_Environment)

    def getUValue(self) -> Float64:
        let interiorAirTemperature = self.m_Environment[Environment.Indoor].getAmbientTemperature()
        let outdoorAirTemperature = self.m_Environment[Environment.Outdoor].getAmbientTemperature()
        let ventilatedFlow = self.getVentilationFlow(Environment.Indoor)
        return (self.getHeatFlow(Environment.Indoor) + ventilatedFlow) / (interiorAirTemperature - outdoorAirTemperature)

    def getNumberOfIterations(self) -> UInt:
        assert(self.m_NonLinearSolver is not None)
        return self.m_NonLinearSolver.getNumOfIterations()

    def solutionTolarance(self) -> Float64:
        assert(self.m_NonLinearSolver is not None)
        return self.m_NonLinearSolver.solutionTolerance()

    def isToleranceAchieved(self) -> Bool:
        assert(self.m_NonLinearSolver is not None)
        return self.m_NonLinearSolver.isToleranceAchieved()

    def EffectiveConductivity(self) -> Float64:
        let temperatures = self.getTemperatures()
        let deltaTemp = abs(temperatures[0] - temperatures[temperatures.size() - 1])
        return abs(self.thickness() * self.getHeatFlow(Environment.Indoor) / deltaTemp)

    def setTolerance(self, t_Tolerance: Float64):
        assert(self.m_NonLinearSolver is not None)
        self.m_NonLinearSolver.setTolerance(t_Tolerance)

    def setInitialGuess(self, t_Temperatures: Vector[Float64]):
        self.m_IGU.setInitialGuess(t_Temperatures)

    def setSolarRadiation(inout self, t_SolarRadiation: Float64):
        (self.m_Environment[Environment.Outdoor] as COutdoorEnvironment).setSolarRadiation(t_SolarRadiation)
        self.m_IGU.setSolarRadiation(t_SolarRadiation)

    def getSolarRadiation(self) -> Float64:
        return (self.m_Environment[Environment.Outdoor] as COutdoorEnvironment).getSolarRadiation()

    def solve(self):
        assert(self.m_NonLinearSolver is not None)
        self.m_NonLinearSolver.solve()

    def thickness(self) -> Float64:
        var thickness: Float64 = 0.0
        for layer in self.getSolidLayers():
            thickness += layer.getThickness()
        for gap in self.getGapLayers():
            thickness += gap.getThickness()
        return thickness

    def setAbsorptances(inout self, absorptances: Vector[Float64]):
        self.m_IGU.setAbsorptances(absorptances, self.m_Environment[Environment.Outdoor].getDirectSolarRadiation())
        self.solve()

    def setWidth(inout self, width: Float64):
        self.m_IGU.setWidth(width)

    def setHeight(inout self, height: Float64):
        self.m_IGU.setHeight(height)

    def setTilt(inout self, tilt: Float64):
        self.m_IGU.setTilt(tilt)

    def setInteriorAndExteriorSurfacesHeight(inout self, height: Float64):
        for key, environment in self.m_Environment:
            environment.setHeight(height)

    def setDeflectionProperties(inout self, t_Tini: Float64, t_Pini: Float64):
        self.m_IGU.setDeflectionProperties(t_Tini, t_Pini, self.m_Environment[Environment.Indoor].getPressure(), self.m_Environment[Environment.Outdoor].getPressure())
        self.initializeStartValues()

    def clearDeflection(inout self):
        self.m_IGU.clearDeflection()

    def initializeStartValues(inout self):
        let startX = 0.001
        let thickness = self.m_IGU.getThickness() + startX + 0.01
        let tOut = self.m_Environment[Environment.Outdoor].getGasTemperature()
        let tInd = self.m_Environment[Environment.Indoor].getGasTemperature()
        let deltaTemp = (tInd - tOut) / thickness
        let aLayers = self.m_IGU.getLayers()
        let aLayer = aLayers.front()
        var currentXPosition = startX
        var aSurface = aLayer.getSurface(Side.Front)
        var curTemp = tOut + currentXPosition * deltaTemp
        aSurface.initializeStart(curTemp)
        for layer in aLayers:
            currentXPosition += layer.getThickness()
            curTemp = tOut + currentXPosition * deltaTemp
            aSurface = layer.getSurface(Side.Back)
            aSurface.initializeStart(curTemp)