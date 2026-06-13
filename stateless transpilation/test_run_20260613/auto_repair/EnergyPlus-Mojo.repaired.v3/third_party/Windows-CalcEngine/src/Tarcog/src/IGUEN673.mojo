from WCEGases import (CGas)
from WCECommon import (ConstantsData)
from memory import (Ptr, new_ptr, delete_ptr)
from vector import DynamicVector
from math import abs, pow

# Header content inlined
struct Glass:
    var Thickness: Float64
    var Conductivity: Float64
    var EmissFront: Float64
    var EmissBack: Float64
    var SolarAbsorptance: Float64
    
    def __init__(inout self, Conductivity: Float64, Thickness: Float64, emissFront: Float64, emissBack: Float64, Sol: Float64 = 0.0):
        self.Thickness = Thickness
        self.Conductivity = Conductivity
        self.EmissFront = emissFront
        self.EmissBack = emissBack
        self.SolarAbsorptance = Sol

struct Gap:
    var Thickness: Float64
    var Pressure: Float64
    var Gas: CGas
    
    def __init__(inout self, Thickness: Float64, Pressure: Float64 = 101325.0, tGas: CGas = CGas()):
        self.Thickness = Thickness
        self.Pressure = Pressure
        self.Gas = tGas

struct Environment:
    var Temperature: Float64
    var filmCoefficient: Float64
    
    def __init__(inout self, Temperature: Float64, filmCoefficient: Float64):
        self.Temperature = Temperature
        self.filmCoefficient = filmCoefficient

@value
class IGU:
    var interior: Environment
    var exterior: Environment
    var numOfSolidLayers: Int
    
    # BaseLayer as a trait or class - using class with virtual-like dispatch via pointer
    @value
    class BaseLayer:
        var m_Thickness: Float64
        var T1: Float64
        var T2: Float64
        var EmissivityFront: Float64
        var EmissivityBack: Float64
        
        def __init__(inout self, thickness: Float64, t1: Float64, t2: Float64):
            self.m_Thickness = thickness
            self.T1 = t1
            self.T2 = t2
            self.EmissivityFront = 0.84
            self.EmissivityBack = 0.84
        
        def getEmissivityFront(self) -> Float64:
            return self.EmissivityFront
        
        def setEmissivityFront(inout self, tEmissivityFront: Float64):
            self.EmissivityFront = tEmissivityFront
        
        def getEmissivityBack(self) -> Float64:
            return self.EmissivityBack
        
        def setEmissivityBack(inout self, tEmissivityBack: Float64):
            self.EmissivityBack = tEmissivityBack
        
        def updateTemperatures(inout self, t1: Float64, t2: Float64):
            self.T1 = t1
            self.T2 = t2
        
        def thermalConductance(self) -> Float64:
            return 0.0  # base
    
    @value
    class GapLayer(BaseLayer):
        var pressure: Float64
        var m_Gas: CGas
        
        def __init__(inout self, gap: Gap, t1: Float64, t2: Float64):
            # BaseLayer init
            self.m_Thickness = gap.Thickness
            self.T1 = t1
            self.T2 = t2
            self.EmissivityFront = 0.84
            self.EmissivityBack = 0.84
            self.pressure = gap.Pressure
            self.m_Gas = gap.Gas
        
        def thermalConductance(self) -> Float64:
            let STEFANBOLTZMANN: Float64 = ConstantsData().STEFANBOLTZMANN
            let Tm: Float64 = (self.T1 + self.T2) / 2.0
            self.m_Gas.setTemperatureAndPressure(Tm, self.pressure)
            let prop = self.m_Gas.getGasProperties()
            let convection: Float64 = prop.m_ThermalConductivity / self.m_Thickness
            let radiation: Float64 = 4.0 * STEFANBOLTZMANN * 1.0 / (1.0 / self.EmissivityFront + 1.0 / self.EmissivityBack - 1.0) * pow(Tm, 3.0)
            return convection + radiation
    
    @value
    class SolidLayer(BaseLayer):
        var m_Conductivity: Float64
        
        def __init__(inout self, glass: Glass, t1: Float64, t2: Float64):
            self.m_Thickness = glass.Thickness
            self.T1 = t1
            self.T2 = t2
            self.EmissivityFront = 0.84
            self.EmissivityBack = 0.84
            self.m_Conductivity = glass.Conductivity
        
        def thermalConductance(self) -> Float64:
            return self.m_Conductivity / self.m_Thickness
    
    var layers: DynamicVector[Ptr[BaseLayer]]
    var temperature: DynamicVector[Float64]
    var thermalResistance: DynamicVector[Float64]
    var abs: DynamicVector[Float64]
    
    def __init__(inout self, interior: Environment, exterior: Environment):
        self.interior = interior
        self.exterior = exterior
        self.numOfSolidLayers = 0
        self.layers = DynamicVector[Ptr[BaseLayer]]()
        self.temperature = DynamicVector[Float64]()
        self.thermalResistance = DynamicVector[Float64]()
        self.abs = DynamicVector[Float64]()
    
    def __moveinit__(inout self, owned existing: Self):
        self.interior = existing.interior
        self.exterior = existing.exterior
        self.numOfSolidLayers = existing.numOfSolidLayers
        self.layers = existing.layers
        self.temperature = existing.temperature
        self.thermalResistance = existing.thermalResistance
        self.abs = existing.abs
    
    def __del__(owned self):
        for i in range(self.layers.size):
            delete_ptr(self.layers[i])
    
    @staticmethod
    def create(interior: Environment, exterior: Environment) -> Self:
        return IGU(interior, exterior)
    
    def addGlass(inout self, glass: Glass):
        if self.temperature.size > 0:
            self.temperature.push_back(self.temperature[self.temperature.size - 1] + 3.0)
        else:
            self.temperature.push_back(3.0)
            self.temperature.push_back(self.exterior.Temperature + 6.0)
            self.layers.push_back(new_ptr[SolidLayer](SolidLayer(glass, self.temperature[0], self.temperature[1])))
        self.abs.push_back(glass.SolarAbsorptance)
        self.numOfSolidLayers += 1
        if self.layers.size > 1:
            let gap = self.layers[self.layers.size - 1].value
            if gap is GapLayer:  # dynamic_cast equivalent via type check
                gap.setEmissivityBack(glass.EmissFront)
                self.layers.push_back(new_ptr[SolidLayer](SolidLayer(glass,
                    self.temperature[self.temperature.size - 2],
                    self.temperature[self.temperature.size - 1])))
            else:
                raise Error("Cannot put two consecutive glass layers to IGU.")
    
    def addGap(inout self, gap: Gap):
        self.temperature.push_back(self.temperature[self.temperature.size - 1] + 3.0)
        let solid = self.layers[self.layers.size - 1].value
        if solid is SolidLayer:
            self.layers.push_back(new_ptr[GapLayer](GapLayer(
                gap,
                self.temperature[self.temperature.size - 2],
                self.temperature[self.temperature.size - 1])))
            self.layers[self.layers.size - 1].value.setEmissivityFront(solid.getEmissivityBack())
        else:
            raise Error("Cannot put two consecutive gap layers to IGU.")
    
    def conductanceSums(self) -> Float64:
        var accumulator: Float64 = 0.0
        for i in range(self.layers.size):
            accumulator += self.layers[i].value.thermalConductance()
        return accumulator
    
    def calculateNewTemperatures(inout self, scaleFactor: Float64):
        self.temperature[0] = scaleFactor / self.exterior.filmCoefficient + self.exterior.Temperature
        self.temperature[self.temperature.size - 1] = self.interior.Temperature - scaleFactor / self.interior.filmCoefficient
        for i in range(self.layers.size - 1):
            self.temperature[i + 1] = scaleFactor / self.layers[i].value.thermalConductance() + self.temperature[i]
        self.updateLayerTemperatures()
    
    def updateThermalResistances(inout self):
        self.thermalResistance.clear()
        self.thermalResistance.push_back(1.0 / self.exterior.filmCoefficient)
        for i in range(self.layers.size):
            self.thermalResistance.push_back(1.0 / self.layers[i].value.thermalConductance())
        self.thermalResistance.push_back(1.0 / self.interior.filmCoefficient)
    
    def Uvalue(inout self) -> Float64:
        var condSum: Float64 = self.conductanceSums()
        var condSumNew: Float64 = 0.0
        var ug: Float64 = 0.0
        while abs(condSum - condSumNew) > 1e-4:
            condSum = condSumNew
            let intExt: Float64 = 1.0 / self.exterior.filmCoefficient + 1.0 / self.interior.filmCoefficient
            var accumulator: Float64 = intExt
            for i in range(self.layers.size):
                accumulator += 1.0 / self.layers[i].value.thermalConductance()
            ug = 1.0 / accumulator
            self.calculateNewTemperatures(ug * (self.interior.Temperature - self.exterior.Temperature))
            self.updateThermalResistances()
            condSumNew = self.conductanceSums()
        return ug
    
    def shgc(inout self, totSol: Float64) -> Float64:
        var lambdaCoeff = DynamicVector[Float64]()
        for _ in range(self.numOfSolidLayers - 1):
            lambdaCoeff.push_back(0.0)
        var cNom: Float64 = 0.0
        var cDen: Float64 = 0.0
        var cAbs: Float64 = 0.0
        self.Uvalue()
        var i: Int = self.numOfSolidLayers - 1
        while i > 0:
            i -= 1
            var j: Int = 2 * (i + 1)
            var k1: Float64 = 0.5
            var k2: Float64 = 0.5
            cAbs += self.abs[i]
            if i == 0:
                k1 = 1.0
            if i == (self.numOfSolidLayers - 2):
                k2 = 1.0
            lambdaCoeff[i] = 1.0 / (k1 * self.thermalResistance[j - 1] + self.thermalResistance[j] + k2 * self.thermalResistance[j + 1])
            cNom += cAbs / lambdaCoeff[i]
            cDen += 1.0 / lambdaCoeff[i]
        cAbs += self.abs[0]
        let flowin: Float64 = (cAbs * self.thermalResistance[0] + cNom) / (self.thermalResistance[0] + self.thermalResistance[2 * self.numOfSolidLayers] + cDen)
        return flowin + totSol
    
    def updateLayerTemperatures(inout self):
        for i in range(self.layers.size):
            self.layers[i].value.updateTemperatures(self.temperature[i], self.temperature[i + 1])