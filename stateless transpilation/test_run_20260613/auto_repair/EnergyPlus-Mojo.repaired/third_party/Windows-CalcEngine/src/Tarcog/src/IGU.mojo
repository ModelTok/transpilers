from std import (
    SharedPtr,
    dynamic_pointer_cast,
    make_unique,
    find,
    List,
    Dict,
    UniquePtr,
    math,
    sin,
    pow,
    pi as WCE_PI,
)
from BaseIGULayer import CBaseIGULayer
from IGUSolidLayer import CIGUSolidLayer
from IGUGapLayer import CIGUGapLayer
from IGUVentilatedGapLayer import CIGUVentilatedGapLayer
from BaseShade import CBaseShade
from Environment import Environment
from IGUSolidDeflection import CIGUSolidLayerDeflection, CIGUDeflectionMeasuread
from IGUGapDeflection import CIGUGapDeflection
from DeflectionFromCurves import DeflectionE1300, LayerData, GapData
from Surface import CSurface
from BaseLayer import CBaseLayer
from WCECommon import Side, EnumSide

@value
class CIGU:
    m_Width: Float64
    m_Height: Float64
    m_Tilt: Float64
    m_Layers: List[SharedPtr[CBaseLayer]]
    m_DeflectionFromE1300Curves: SharedPtr[DeflectionE1300] = SharedPtr[DeflectionE1300]()
    m_DeflectionAppliedLoad: List[Float64]

    def __init__(self, t_Width: Float64 = 1, t_Height: Float64 = 1, t_Tilt: Float64 = 90):
        self.m_Width = t_Width
        self.m_Height = t_Height
        self.m_Tilt = t_Tilt
        self.m_Layers = List[SharedPtr[CBaseLayer]]()
        self.m_DeflectionAppliedLoad = List[Float64]()

    def __init__(self, other: Self):
        self = other  # need proper copy, but Mojo doesn't have copy constructor; we'll use operator= later
        # Actually we implement __copyinit__ or operator=, but for simplicity use the assign overload.
        # We'll define __moveassign__? Instead, we'll define a method operator=.

    def __del__(self):
        for layer in self.getSolidLayers():
            layer.tearDownConnections()

    def operator=(self, other: Self) -> Self:
        self.m_Width = other.m_Width
        self.m_Height = other.m_Height
        self.m_Tilt = other.m_Tilt
        self.m_Layers.clear()
        for layer in other.m_Layers:
            var aLayer = layer.clone()
            self.addLayer(aLayer)
        if other.m_DeflectionFromE1300Curves is not None:
            self.m_DeflectionFromE1300Curves = make_unique[DeflectionE1300](other.m_DeflectionFromE1300Curves[0])
        return self

    def addLayer(self, t_Layer: SharedPtr[CBaseLayer]):
        if self.getNumOfLayers() == 0:
            var solidLayer = dynamic_pointer_cast[CIGUSolidLayer](t_Layer)
            if solidLayer is not None:
                self.m_Layers.append(t_Layer)
            else:
                raise Error("First inserted layer must be a solid layer.")
        else:
            var lastLayer = self.m_Layers[-1]
            var tLayerSolid = dynamic_pointer_cast[CIGUSolidLayer](t_Layer)
            var lastLayerSolid = dynamic_pointer_cast[CIGUSolidLayer](lastLayer)
            if tLayerSolid is not None and lastLayerSolid is not None:
                # both solid – error
                raise Error(
                    "Two adjecent layers in IGU cannot be of same type. "
                    "IGU must be constructed of array of solid and gap layers."
                )
            else:
                self.m_Layers.append(t_Layer)
                lastLayer.connectToBackSide(t_Layer)
        self.checkForLayerUpgrades(t_Layer)
        t_Layer.setTilt(self.m_Tilt)
        t_Layer.setWidth(self.m_Width)
        t_Layer.setHeight(self.m_Height)

    def addLayers(self, layers: *SharedPtr[CBaseIGULayer]):
        for layer in layers:
            self.addLayer(layer)

    def setTilt(self, t_Tilt: Float64):
        for layer in self.m_Layers:
            layer.setTilt(t_Tilt)
        self.m_Tilt = t_Tilt
        if self.m_DeflectionFromE1300Curves is not None:
            self.m_DeflectionFromE1300Curves.setIGUTilt(t_Tilt)

    def setWidth(self, t_Width: Float64):
        for layer in self.m_Layers:
            layer.setWidth(t_Width)
        self.m_Width = t_Width
        if self.m_DeflectionFromE1300Curves is not None:
            self.m_DeflectionFromE1300Curves.setDimensions(self.m_Width, self.m_Height)

    def setHeight(self, t_Height: Float64):
        for layer in self.m_Layers:
            layer.setHeight(t_Height)
        self.m_Height = t_Height
        if self.m_DeflectionFromE1300Curves is not None:
            self.m_DeflectionFromE1300Curves.setDimensions(self.m_Width, self.m_Height)

    def setSolarRadiation(self, t_SolarRadiation: Float64):
        for layer in self.getSolidLayers():
            layer.setSolarRadiation(t_SolarRadiation)

    def getEnvironment(self, t_Environment: Environment) -> SharedPtr[CBaseLayer]:
        var aLayer: SharedPtr[CBaseLayer] = None
        if t_Environment == Environment.Indoor:
            aLayer = self.m_Layers[-1]
        else:
            aLayer = self.m_Layers[0]
        return aLayer

    def getState(self) -> List[Float64]:
        var aState = List[Float64]()
        for layer in self.getSolidLayers():
            aState.append(layer.getTemperature(Side.Front))
            aState.append(layer.J(Side.Front))
            aState.append(layer.J(Side.Back))
            aState.append(layer.getTemperature(Side.Back))
        return aState

    def setState(self, t_State: List[Float64]):
        var i: Int = 0
        for aLayer in self.getSolidLayers():
            var Tf = t_State[4 * i]
            var Jf = t_State[4 * i + 1]
            var Jb = t_State[4 * i + 2]
            var Tb = t_State[4 * i + 3]
            aLayer.setLayerState(Tf, Tb, Jf, Jb)
            i += 1

    def getTemperatures(self) -> List[Float64]:
        var aTemperatures = List[Float64]()
        for layer in self.getSolidLayers():
            for aSide in EnumSide:
                aTemperatures.append(layer.getTemperature(aSide))
        return aTemperatures

    def getRadiosities(self) -> List[Float64]:
        var aRadiosities = List[Float64]()
        for layer in self.getSolidLayers():
            for aSide in EnumSide:
                aRadiosities.append(layer.J(aSide))
        return aRadiosities

    def getMaxDeflections(self) -> List[Float64]:
        var aMaxDeflections = List[Float64]()
        for layer in self.getSolidLayers():
            aMaxDeflections.append(layer.getMaxDeflection())
        return aMaxDeflections

    def getMeanDeflections(self) -> List[Float64]:
        var aMeanDeflections = List[Float64]()
        for layer in self.getSolidLayers():
            aMeanDeflections.append(layer.getMeanDeflection())
        return aMeanDeflections

    def getPanesLoad(self) -> List[Float64]:
        var paneLoad = List[Float64](size=self.getSolidLayers().size)
        if self.m_DeflectionFromE1300Curves is not None:
            paneLoad = self.m_DeflectionFromE1300Curves.results().paneLoad
        return paneLoad

    def getThickness(self) -> Float64:
        var totalWidth = 0.0
        for layer in self.m_Layers:
            totalWidth += layer.getThickness()
        return totalWidth

    def getTilt(self) -> Float64:
        return self.m_Tilt

    def getWidth(self) -> Float64:
        return self.m_Width

    def getHeight(self) -> Float64:
        return self.m_Height

    def getNumOfLayers(self) -> Int:
        return (self.m_Layers.size + 1) // 2

    def getVentilationFlow(self, t_Environment: Environment) -> Float64:
        var size = self.m_Layers.size
        var result = 0.0
        if size > 1:
            var envLayer = Dict[Environment, Int]()
            envLayer[Environment.Indoor] = size - 2
            envLayer[Environment.Outdoor] = 1
            var solidLayerIndex = Dict[Environment, Int]()
            solidLayerIndex[Environment.Indoor] = size - 1
            solidLayerIndex[Environment.Outdoor] = 0
            if self.m_Layers[solidLayerIndex[t_Environment]].isPermeable():
                result = self.m_Layers[envLayer[t_Environment]].getGainFlow()
        return result

    def setInitialGuess(self, t_Guess: List[Float64]):
        if 2 * self.getNumOfLayers() != t_Guess.size:
            print("Number of temperatures in initial guess cannot fit number of layers."
                  "Program will use initial guess instead")
        else:
            var Index: Int = 0
            for aLayer in self.getSolidLayers():
                for aSide in EnumSide:
                    var aSurface = aLayer.getSurface(aSide)
                    aSurface.initializeStart(t_Guess[Index])
                    Index += 1

    def setDeflectionProperties(
        self,
        t_Tini: Float64,
        t_Pini: Float64,
        t_InsidePressure: Float64 = 101325,
        t_OutsidePressure: Float64 = 101325,
    ):
        var layerData = List[LayerData]()
        for layer in self.getSolidLayers():
            layerData.append(
                LayerData(layer.getThickness(), layer.density(), layer.youngsModulus())
            )
        var gapData = List[GapData]()
        for gap in self.getGapLayers():
            gapData.append(GapData(gap.getThickness(), t_Tini, t_Pini))
        self.m_DeflectionFromE1300Curves = make_unique[DeflectionE1300](
            self.m_Width, self.m_Height, layerData, gapData
        )
        self.m_DeflectionFromE1300Curves.setIGUTilt(self.m_Tilt)
        self.m_DeflectionFromE1300Curves.setInteriorPressure(t_InsidePressure)
        self.m_DeflectionFromE1300Curves.setExteriorPressure(t_OutsidePressure)
        if self.m_DeflectionAppliedLoad.size == layerData.size:
            self.m_DeflectionFromE1300Curves.setAppliedLoad(self.m_DeflectionAppliedLoad)

    def setDeflectionProperties(self, t_MeasuredDeflections: List[Float64]):
        if t_MeasuredDeflections.size != self.getNumOfLayers() - 1:
            raise Error(
                "Number of measured deflection values must be equal to number of gaps.")
        var nominator = 0.0
        for i in range(t_MeasuredDeflections.size):
            var SumL = 0.0
            for j in range(i, t_MeasuredDeflections.size):
                SumL += self.getGapLayers()[j].getThickness() - t_MeasuredDeflections[j]
            var aDefLayer = CIGUSolidLayerDeflection(self.getSolidLayers()[i][0])
            nominator += SumL * aDefLayer.flexuralRigidity()
        var denominator = 0.0
        for i in range(self.getSolidLayers().size):
            var aDefLayer = CIGUSolidLayerDeflection(self.getSolidLayers()[i][0])
            denominator += aDefLayer.flexuralRigidity()
        var LDefNMax = nominator / denominator
        var deflectionRatio = self.Ldmean() / self.Ldmax()
        var LDefMax = List[Float64]()
        LDefMax.append(LDefNMax)
        for i in range(self.getNumOfLayers() - 1, 0, -1):
            LDefNMax = t_MeasuredDeflections[i - 1] - self.getGapLayers()[i - 1].getThickness() + LDefNMax
            LDefMax.insert(0, LDefNMax)
        for i in range(self.getNumOfLayers()):
            LDefNMax = LDefMax[i]
            var LDefNMean = deflectionRatio * LDefNMax
            var aLayer = self.getSolidLayers()[i]
            var aDefLayer = SharedPtr[CIGUSolidLayerDeflection](CIGUSolidLayerDeflection(aLayer[0]))
            aDefLayer = SharedPtr[CIGUDeflectionMeasuread](CIGUDeflectionMeasuread(aDefLayer, LDefNMean, LDefNMax))
            self.replaceLayer(aLayer, aDefLayer)

    def updateDeflectionState(self):
        if self.m_DeflectionFromE1300Curves is not None:
            var gapLayers = self.getGapLayers()
            var gapTemperatures = List[Float64](size=gapLayers.size)
            for i in range(gapTemperatures.size):
                gapTemperatures[i] = gapLayers[i].averageTemperature()
            self.m_DeflectionFromE1300Curves.setLoadTemperatures(gapTemperatures)
            var deflectionResults = self.m_DeflectionFromE1300Curves.results()
            var deflectionRatio = self.Ldmean() / self.Ldmax()
            var solidLayers = self.getSolidLayers()
            assert deflectionResults.deflection.size == solidLayers.size
            for i in range(deflectionResults.deflection.size):
                var def_ = deflectionResults.deflection[i]
                solidLayers[i].applyDeflection(deflectionRatio * def_, def_)

    def replaceLayer(self, t_Original: SharedPtr[CBaseIGULayer], t_Replacement: SharedPtr[CBaseIGULayer]):
        var index = find(self.m_Layers.begin(), self.m_Layers.end(), t_Original) - self.m_Layers.begin()
        self.m_Layers[index] = t_Replacement
        if index > 0:
            self.m_Layers[index - 1].connectToBackSide(t_Replacement)
        if index < self.m_Layers.size - 1:
            t_Replacement.connectToBackSide(self.m_Layers[index + 1])

    def checkForLayerUpgrades(self, t_Layer: SharedPtr[CBaseLayer]):
        var shadeLayer = dynamic_pointer_cast[CBaseShade](t_Layer)
        if shadeLayer is not None:
            var prevLayer = t_Layer.getPreviousLayer()
            var gapLayer = dynamic_pointer_cast[CIGUGapLayer](prevLayer)
            if gapLayer is not None:
                var newLayer = SharedPtr[CIGUVentilatedGapLayer](
                    CIGUVentilatedGapLayer(gapLayer)
                )
                self.replaceLayer(gapLayer, newLayer)
        var gapLayer = dynamic_pointer_cast[CIGUGapLayer](t_Layer)
        if gapLayer is not None:
            var prevLayer = t_Layer.getPreviousLayer()
            var shadeLayerPrev = dynamic_pointer_cast[CBaseShade](prevLayer)
            if shadeLayerPrev is not None:
                var newLayer = SharedPtr[CIGUVentilatedGapLayer](
                    CIGUVentilatedGapLayer(gapLayer)
                )
                self.replaceLayer(gapLayer, newLayer)

    def Ldmean(self) -> Float64:
        var coeff = 16.0 / pow(WCE_PI, 6)
        var totalSum = 0.0
        for m in range(1, 6, 2):
            for n in range(1, 6, 2):
                var nomin = 4.0
                var denom = m * m * n * n * WCE_PI * WCE_PI * pow(pow(m / self.m_Width, 2) + pow(n / self.m_Height, 2), 2)
                totalSum += nomin / denom
        return coeff * totalSum

    def Ldmax(self) -> Float64:
        var coeff = 16.0 / pow(WCE_PI, 6)
        var totalSum = 0.0
        for m in range(1, 6, 2):
            for n in range(1, 6, 2):
                var nomin = sin(m * WCE_PI / 2) * sin(n * WCE_PI / 2)
                var denom = m * n * pow(pow(m / self.m_Width, 2) + pow(n / self.m_Height, 2), 2)
                totalSum += nomin / denom
        return coeff * totalSum

    def getSolidLayers(self) -> List[SharedPtr[CIGUSolidLayer]]:
        var aVect = List[SharedPtr[CIGUSolidLayer]]()
        for aLayer in self.m_Layers:
            var solidLayer = dynamic_pointer_cast[CIGUSolidLayer](aLayer)
            if solidLayer is not None:
                aVect.append(solidLayer)
        return aVect

    def getGapLayers(self) -> List[SharedPtr[CIGUGapLayer]]:
        var aVect = List[SharedPtr[CIGUGapLayer]]()
        for aLayer in self.m_Layers:
            var gapLayer = dynamic_pointer_cast[CIGUGapLayer](aLayer)
            if gapLayer is not None:
                aVect.append(gapLayer)
        return aVect

    def getLayers(self) -> List[SharedPtr[CBaseLayer]]:
        return self.m_Layers

    def setAbsorptances(self, absorptances: List[Float64], solarRadiation: Float64):
        var solidLayers = self.getSolidLayers()
        if solidLayers.size != absorptances.size:
            raise Error(
                "Number of absorptances does not match number of solid layers.")
        for i in range(solidLayers.size):
            solidLayers[i].setSolarAbsorptance(absorptances[i], solarRadiation)

    def clearDeflection(self):
        self.m_DeflectionFromE1300Curves = None

    def setAppliedLoad(self, t_AppliedLoad: List[Float64]):
        self.m_DeflectionAppliedLoad = t_AppliedLoad
        if self.m_DeflectionFromE1300Curves is not None:
            self.m_DeflectionFromE1300Curves.setAppliedLoad(t_AppliedLoad)
