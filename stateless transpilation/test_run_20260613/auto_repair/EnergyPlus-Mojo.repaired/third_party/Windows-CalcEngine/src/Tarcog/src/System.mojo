from IGUConfigurations import System, Environment, IIGUSystem
from IGU import CIGU
from Environment import CEnvironment
from SingleSystem import CSingleSystem
from IGUSolidLayer import CIGUSolidLayer

class CSystem(IIGUSystem):
    var m_System: Dict[System, Pointer[CSingleSystem]]
    var m_Solved: Bool = False

    def __init__(inout self, t_IGU: borrowed CIGU, t_Indoor: Pointer[CEnvironment], t_Outdoor: Pointer[CEnvironment]):
        self.m_System[System.SHGC] = Pointer[CSingleSystem](new CSingleSystem(t_IGU, t_Indoor, t_Outdoor))
        self.m_System[System.Uvalue] = Pointer[CSingleSystem](new CSingleSystem(t_IGU, t_Indoor.cloneEnvironment(), t_Outdoor.cloneEnvironment()))
        self.m_System[System.Uvalue].setSolarRadiation(0)
        self.solve()

    def getTemperatures(inout self, t_System: System) -> List[Float64]:
        self.checkSolved()
        return self.m_System[t_System].getTemperatures()

    def getRadiosities(inout self, t_System: System) -> List[Float64]:
        self.checkSolved()
        return self.m_System[t_System].getRadiosities()

    def getMaxDeflections(inout self, t_System: System) -> List[Float64]:
        self.checkSolved()
        return self.m_System[t_System].getMaxDeflections()

    def getMeanDeflections(inout self, t_System: System) -> List[Float64]:
        self.checkSolved()
        return self.m_System[t_System].getMeanDeflections()

    def getPanesLoad(inout self, t_System: System) -> List[Float64]:
        self.checkSolved()
        return self.m_System[t_System].getPanesLoad()

    def setAppliedLoad(inout self, load: List[Float64]):
        self.m_Solved = False
        for key, value in self.m_System.items():
            _ = key
            value.setAppliedLoad(load)

    def getSolidLayers(self, t_System: System) -> List[Pointer[CIGUSolidLayer]]:
        return self.m_System[t_System].getSolidLayers()

    def getHeatFlow(inout self, t_System: System, t_Environment: Environment) -> Float64:
        self.checkSolved()
        return self.m_System[t_System].getHeatFlow(t_Environment)

    def getUValue(inout self) -> Float64:
        self.checkSolved()
        return self.m_System[System.Uvalue].getUValue()

    def getSHGC(inout self, t_TotSol: Float64) -> Float64:
        self.checkSolved()
        var ventilatedFlowSHGC: Float64 = self.m_System[System.SHGC].getVentilationFlow(Environment.Indoor)
        var ventilatedFlowU: Float64 = self.m_System[System.Uvalue].getVentilationFlow(Environment.Indoor)
        var indoorFlowSHGC: Float64 = self.m_System[System.SHGC].getHeatFlow(Environment.Indoor) + ventilatedFlowSHGC
        var indoorFlowU: Float64 = self.m_System[System.Uvalue].getHeatFlow(Environment.Indoor) + ventilatedFlowU
        var result: Float64 = 0.0
        if self.m_System[System.SHGC].getSolarRadiation() != 0.0:
            result = t_TotSol - (indoorFlowSHGC - indoorFlowU) / self.m_System[System.SHGC].getSolarRadiation()
        else:
            result = 0.0
        return result

    def getNumberOfIterations(inout self, t_System: System) -> Int:
        self.checkSolved()
        return self.m_System[t_System].getNumberOfIterations()

    def getSolidEffectiveLayerConductivities(inout self, t_System: System) -> List[Float64]:
        self.checkSolved()
        return self.m_System[t_System].getSolidEffectiveLayerConductivities()

    def getGapEffectiveLayerConductivities(inout self, t_System: System) -> List[Float64]:
        self.checkSolved()
        return self.m_System[t_System].getGapEffectiveLayerConductivities()

    def getEffectiveSystemConductivity(inout self, t_System: System) -> Float64:
        self.checkSolved()
        return self.m_System[t_System].EffectiveConductivity()

    def thickness(self, t_System: System) -> Float64:
        return self.m_System[t_System].thickness()

    def relativeHeatGain(inout self, Tsol: Float64) -> Float64:
        return self.getUValue() * 7.78 + self.getSHGC(Tsol) / 0.87 * 630.9

    def setAbsorptances(inout self, absorptances: List[Float64]):
        self.m_System[System.SHGC].setAbsorptances(absorptances)
        self.m_Solved = False

    def setWidth(inout self, width: Float64):
        for key, system in self.m_System.items():
            _ = key
            system.setWidth(width)
        self.m_Solved = False

    def setHeight(inout self, height: Float64):
        for key, system in self.m_System.items():
            _ = key
            system.setHeight(height)
        self.m_Solved = False

    def setTilt(inout self, tilt: Float64):
        for key, system in self.m_System.items():
            _ = key
            system.setTilt(tilt)
        self.m_Solved = False

    def setWidthAndHeight(inout self, width: Float64, height: Float64):
        for key, system in self.m_System.items():
            _ = key
            system.setWidth(width)
            system.setHeight(height)
        self.m_Solved = False

    def setInteriorAndExteriorSurfacesHeight(inout self, height: Float64):
        for key, system in self.m_System.items():
            _ = key
            system.setInteriorAndExteriorSurfacesHeight(height)
        self.m_Solved = False

    def solve(inout self):
        for key, system in self.m_System.items():
            _ = key
            system.solve()
        self.m_Solved = True

    def checkSolved(inout self):
        if not self.m_Solved:
            self.solve()
            self.m_Solved = True

    def getH(self, sys: System, environment: Environment) -> Float64:
        return self.m_System[sys].getH(environment)

    def setDeflectionProperties(inout self, t_Tini: Float64, t_Pini: Float64):
        for key, system in self.m_System.items():
            _ = key
            system.setDeflectionProperties(t_Tini, t_Pini)
        self.m_Solved = False

    def clearDeflection(inout self):
        for key, system in self.m_System.items():
            _ = key
            system.clearDeflection()
        self.m_Solved = False