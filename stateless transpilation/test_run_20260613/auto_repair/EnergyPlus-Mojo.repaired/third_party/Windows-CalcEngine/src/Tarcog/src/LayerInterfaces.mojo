from WCECommon import FenestrationCommon, Side, CState
from WCEGases import Gases
from Surface import ISurface
from TarcogConstants import TarcogConstants

@value
struct ForcedVentilation:
    var Speed: Float64
    var Temperature: Float64

    def __init__(inout self):
        self.Speed = 0.0
        self.Temperature = 0.0

    def __init__(inout self, t_Speed: Float64, t_Temperature: Float64):
        self.Speed = t_Speed
        self.Temperature = t_Temperature

@value
struct CLayerGeometry(CState):
    var m_Width: Float64
    var m_Height: Float64
    var m_Tilt: Float64

    def __init__(inout self):
        self.m_Width = TarcogConstants.DEFAULT_WINDOW_WIDTH
        self.m_Height = TarcogConstants.DEFAULT_WINDOW_HEIGHT
        self.m_Tilt = TarcogConstants.DEFAULT_TILT

    def setWidth(inout self, t_Width: Float64):
        self.m_Width = t_Width
        self.resetCalculated()

    def setHeight(inout self, t_Height: Float64):
        self.m_Height = t_Height
        self.resetCalculated()

    def setTilt(inout self, t_Tilt: Float64):
        self.m_Tilt = t_Tilt
        self.resetCalculated()

@value
struct CLayerHeatFlow(CState):
    var m_ConductiveConvectiveCoeff: Float64
    var m_LayerGainFlow: Float64
    var m_Surface: Dict[Side, Pointer[ISurface]]

    def __init__(inout self):
        self.m_ConductiveConvectiveCoeff = 0.0
        self.m_LayerGainFlow = 0.0
        self.m_Surface = Dict[Side, Pointer[ISurface]]()
        self.m_Surface[Side.Front] = Pointer[ISurface]()
        self.m_Surface[Side.Back] = Pointer[ISurface]()

    def __init__(inout self, t_Layer: CLayerHeatFlow):
        CState.__init__(self, t_Layer)
        self.__copy__(t_Layer)

    def __copy__(inout self, t_Layer: CLayerHeatFlow):
        CState.__copy__(self, t_Layer)
        self.m_ConductiveConvectiveCoeff = t_Layer.m_ConductiveConvectiveCoeff
        self.m_LayerGainFlow = t_Layer.m_LayerGainFlow
        for aSide in FenestrationCommon.EnumSide():
            var aSurface = t_Layer.m_Surface[aSide]
            if aSurface.is_non_null():
                self.m_Surface[aSide] = aSurface.value().clone()

    def getHeatFlow(inout self) -> Float64:
        return self.getRadiationFlow() + self.getConvectionConductionFlow()

    def getGainFlow(inout self) -> Float64:
        self.calculateLayerHeatFlow()
        return self.m_LayerGainFlow

    def getConductionConvectionCoefficient(inout self) -> Float64:
        self.calculateLayerHeatFlow()
        return self.m_ConductiveConvectiveCoeff

    def getRadiationFlow(inout self) -> Float64:
        self.calculateRadiationFlow()
        assert(self.m_Surface[Side.Front].is_non_null())
        assert(self.m_Surface[Side.Back].is_non_null())
        return self.m_Surface[Side.Back].value().J() - self.m_Surface[Side.Front].value().J()

    def getConvectionConductionFlow(inout self) -> Float64:
        self.calculateLayerHeatFlow()
        assert(self.m_Surface[Side.Front].is_non_null())
        assert(self.m_Surface[Side.Back].is_non_null())
        return (self.m_Surface[Side.Back].value().getTemperature()
                - self.m_Surface[Side.Front].value().getTemperature()) * self.m_ConductiveConvectiveCoeff

    def calculateLayerHeatFlow(inout self):
        if not self.isCalculated():
            self.calculateRadiationFlow()
            self.calculateConvectionOrConductionFlow()
        self.setCalculated()

    def areSurfacesInitalized(self) -> Bool:
        var areInitialized = (self.m_Surface.size() == 2)
        if areInitialized:
            areInitialized = (self.m_Surface[Side.Front].is_non_null()
                              and self.m_Surface[Side.Back].is_non_null())
        return areInitialized

    def getSurface(self, t_Position: Side) -> Pointer[ISurface]:
        return self.m_Surface[t_Position]

    def setSurface(inout self, t_Surface: Pointer[ISurface], t_Position: Side):
        self.m_Surface[t_Position] = t_Surface
        if self.m_Surface.size() == 2:
            self.resetCalculated()

@value
enum AirVerticalDirection:
    None = 0
    Up = 1
    Down = 2

@value
enum AirHorizontalDirection:
    None = 0
    Leeward = 1
    Windward = 2

@value
struct CGasLayer(CState):
    var m_Pressure: Float64
    var m_AirSpeed: Float64
    var m_AirVerticalDirection: AirVerticalDirection
    var m_AirHorizontalDirection: AirHorizontalDirection
    var m_ForcedVentilation: ForcedVentilation
    var m_Gas: Gases.CGas

    def __init__(inout self):
        self.m_Pressure = 0.0
        self.m_AirSpeed = 0.0
        self.m_AirVerticalDirection = AirVerticalDirection.None
        self.m_AirHorizontalDirection = AirHorizontalDirection.None
        self.m_ForcedVentilation = ForcedVentilation()
        self.m_Gas = Gases.CGas()

    def __init__(inout self, t_Pressure: Float64):
        self.m_Pressure = t_Pressure
        self.m_AirSpeed = 0.0
        self.m_AirVerticalDirection = AirVerticalDirection.None
        self.m_AirHorizontalDirection = AirHorizontalDirection.None
        self.m_ForcedVentilation = ForcedVentilation()
        self.m_Gas = Gases.CGas()

    def __init__(inout self, t_Pressure: Float64, t_AirSpeed: Float64, t_AirVerticalDirection: AirVerticalDirection):
        self.m_Pressure = t_Pressure
        self.m_AirSpeed = t_AirSpeed
        self.m_AirVerticalDirection = t_AirVerticalDirection
        self.m_AirHorizontalDirection = AirHorizontalDirection.None
        self.m_ForcedVentilation = ForcedVentilation()
        self.m_Gas = Gases.CGas()

    def __init__(inout self, t_Pressure: Float64, t_AirSpeed: Float64, t_AirHorizontalDirection: AirHorizontalDirection):
        self.m_Pressure = t_Pressure
        self.m_AirSpeed = t_AirSpeed
        self.m_AirVerticalDirection = AirVerticalDirection.None
        self.m_AirHorizontalDirection = t_AirHorizontalDirection
        self.m_ForcedVentilation = ForcedVentilation()
        self.m_Gas = Gases.CGas()

    def __init__(inout self, t_Pressure: Float64, t_Gas: Gases.CGas):
        self.m_Pressure = t_Pressure
        self.m_AirSpeed = 0.0
        self.m_AirVerticalDirection = AirVerticalDirection.None
        self.m_AirHorizontalDirection = AirHorizontalDirection.None
        self.m_ForcedVentilation = ForcedVentilation()
        self.m_Gas = t_Gas

    def getPressure(inout self) -> Float64:
        return self.m_Pressure

    def getGasTemperature(self) -> Float64:
        # pure virtual, left unimplemented
        return 0.0

    def initializeStateVariables(inout self):
        self.m_Gas.setTemperatureAndPressure(self.getGasTemperature(), self.m_Pressure)