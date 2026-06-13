from IGUSolidLayer import CIGUSolidLayer
from Surface import ISurface
from IGUGapLayer import CIGUGapLayer
from Environment import CEnvironment
from TarcogConstants import IterationConstants
from IGUVentilatedGapLayer import CIGUVentilatedGapLayer, AirVerticalDirection
from Gases import CGas
from FenestrationCommon import Side
from Math import abs, pow, sqrt

struct CShadeOpenings:
    var m_Atop: Float64
    var m_Abot: Float64
    var m_Aleft: Float64
    var m_Aright: Float64
    var m_Afront: Float64
    var m_FrontPorosity: Float64

    def __init__(self, t_Atop: Float64, t_Abot: Float64, t_Aleft: Float64, t_Aright: Float64, t_Afront: Float64, t_FrontPorosity: Float64):
        self.m_Atop = t_Atop
        self.m_Abot = t_Abot
        self.m_Aleft = t_Aleft
        self.m_Aright = t_Aright
        self.m_Afront = t_Afront
        self.m_FrontPorosity = t_FrontPorosity
        self.initialize()

    def __init__(self):
        self.m_Atop = 0.0
        self.m_Abot = 0.0
        self.m_Aleft = 0.0
        self.m_Aright = 0.0
        self.m_Afront = 0.0
        self.m_FrontPorosity = 0.0
        self.initialize()

    def initialize(self):
        if self.m_Atop == 0.0:
            self.m_Atop = OPENING_TOLERANCE
        if self.m_Abot == 0.0:
            self.m_Abot = OPENING_TOLERANCE

    def openingMultiplier(self) -> Float64:
        return (self.m_Aleft + self.m_Aright + self.m_Afront) / (self.m_Abot + self.m_Atop)

    def Aeq_bot(self) -> Float64:
        return self.m_Abot + 0.5 * self.m_Atop * self.openingMultiplier()

    def Aeq_top(self) -> Float64:
        return self.m_Atop + 0.5 * self.m_Abot * self.openingMultiplier()

    def frontPorositiy(self) -> Float64:
        return self.m_FrontPorosity

    def isOpen(self) -> Bool:
        return self.m_Abot > 0.0 or self.m_Atop > 0.0 or self.m_Aleft > 0.0 or self.m_Aright > 0.0 or self.m_Afront > 0.0

let OPENING_TOLERANCE = 1e-6

class CIGUShadeLayer(CIGUSolidLayer):
    var m_ShadeOpenings: Pointer[CShadeOpenings]
    var m_MaterialConductivity: Float64

    def __init__(self, t_Thickness: Float64, t_Conductivity: Float64, t_ShadeOpenings: Pointer[CShadeOpenings], t_FrontSurface: Pointer[ISurface] = Pointer[ISurface](), t_BackSurface: Pointer[ISurface] = Pointer[ISurface]()):
        CIGUSolidLayer.__init__(self, t_Thickness, t_Conductivity, t_FrontSurface, t_BackSurface)
        self.m_ShadeOpenings = t_ShadeOpenings
        self.m_MaterialConductivity = t_Conductivity

    def __init__(self, t_Layer: Pointer[CIGUSolidLayer], t_ShadeOpenings: Pointer[CShadeOpenings]):
        CIGUSolidLayer.__init__(self, *t_Layer)
        self.m_ShadeOpenings = t_ShadeOpenings
        self.m_MaterialConductivity = t_Layer.getConductance()

    def __init__(self, t_Thickness: Float64, t_Conductivity: Float64):
        CIGUSolidLayer.__init__(self, t_Thickness, t_Conductivity)
        self.m_ShadeOpenings = Pointer[CShadeOpenings](new CShadeOpenings())
        self.m_MaterialConductivity = t_Conductivity

    def clone(self) -> Pointer[CBaseLayer]:
        return Pointer[CIGUShadeLayer](new CIGUShadeLayer(self))

    def isPermeable(self) -> Bool:
        return self.m_ShadeOpenings.isOpen()

    def calculateConvectionOrConductionFlow(self):
        self.m_Conductivity = self.equivalentConductivity(self.m_MaterialConductivity, self.m_ShadeOpenings.frontPorositiy())
        CIGUSolidLayer.calculateConvectionOrConductionFlow(self)
        assert(self.m_NextLayer != Pointer[CBaseLayer]())
        assert(self.m_PreviousLayer != Pointer[CBaseLayer]())
        self.setCalculated()
        if (self.m_PreviousLayer as? CIGUGapLayer) != None and (self.m_NextLayer as? CIGUGapLayer) != None:
            self.calcInBetweenShadeFlow(self.m_PreviousLayer as CIGUVentilatedGapLayer, self.m_NextLayer as CIGUVentilatedGapLayer)
        elif (self.m_PreviousLayer as? CEnvironment) != None and (self.m_NextLayer as? CIGUVentilatedGapLayer) != None:
            self.calcEdgeShadeFlow(self.m_PreviousLayer as CEnvironment, self.m_NextLayer as CIGUVentilatedGapLayer)
        elif (self.m_PreviousLayer as? CIGUVentilatedGapLayer) != None and (self.m_NextLayer as? CEnvironment) != None:
            self.calcEdgeShadeFlow(self.m_NextLayer as CEnvironment, self.m_PreviousLayer as CIGUVentilatedGapLayer)

    def calcInBetweenShadeFlow(self, t_Gap1: Pointer[CIGUVentilatedGapLayer], t_Gap2: Pointer[CIGUVentilatedGapLayer]):
        var Tup: Float64 = t_Gap1.layerTemperature()
        var Tdown: Float64 = t_Gap2.layerTemperature()
        let RelaxationParameter: Float64 = IterationConstants.RELAXATION_PARAMETER_AIRFLOW
        var converged: Bool = False
        var iterationStep: UInt = 0
        while not converged:
            let tempGap1: Float64 = t_Gap1.layerTemperature()
            let tempGap2: Float64 = t_Gap2.layerTemperature()
            let Tav1: Float64 = t_Gap1.averageTemperature()
            let Tav2: Float64 = t_Gap2.averageTemperature()
            if tempGap1 > tempGap2:
                t_Gap1.setFlowGeometry(self.m_ShadeOpenings.Aeq_bot(), self.m_ShadeOpenings.Aeq_top(), AirVerticalDirection.Up)
                t_Gap2.setFlowGeometry(self.m_ShadeOpenings.Aeq_top(), self.m_ShadeOpenings.Aeq_bot(), AirVerticalDirection.Down)
            else:
                t_Gap1.setFlowGeometry(self.m_ShadeOpenings.Aeq_top(), self.m_ShadeOpenings.Aeq_bot(), AirVerticalDirection.Down)
                t_Gap2.setFlowGeometry(self.m_ShadeOpenings.Aeq_bot(), self.m_ShadeOpenings.Aeq_top(), AirVerticalDirection.Up)
            let drivingPressure: Float64 = t_Gap1.getAirflowReferencePoint(tempGap2)
            let ratio: Float64 = t_Gap1.getThickness() / t_Gap2.getThickness()
            let A1: Float64 = t_Gap1.bernoullyPressureTerm() + t_Gap1.pressureLossTerm()
            let A2: Float64 = t_Gap2.bernoullyPressureTerm() + t_Gap2.pressureLossTerm()
            let B1: Float64 = t_Gap1.hagenPressureTerm()
            let B2: Float64 = t_Gap2.hagenPressureTerm()
            let A: Float64 = A1 + pow(ratio, 2.0) * A2
            let B: Float64 = B1 + ratio * B2
            let speed1: Float64 = (sqrt(abs(pow(B, 2.0) + 4.0 * A * drivingPressure)) - B) / (2.0 * A)
            let speed2: Float64 = speed1 / ratio
            t_Gap1.setFlowSpeed(speed1)
            t_Gap2.setFlowSpeed(speed2)
            let beta1: Float64 = t_Gap1.betaCoeff()
            let beta2: Float64 = t_Gap2.betaCoeff()
            let alpha1: Float64 = 1.0 - beta1
            let alpha2: Float64 = 1.0 - beta2
            let TupOld: Float64 = Tup
            let TdownOld: Float64 = Tdown
            if tempGap1 > tempGap2:
                Tup = (alpha1 * Tav1 + beta1 * alpha2 * Tav2) / (1.0 - beta1 * beta2)
                Tdown = alpha2 * Tav2 + beta2 * Tup
            else:
                Tdown = (alpha1 * Tav1 + beta1 * alpha2 * Tav2) / (1.0 - beta1 * beta2)
                Tup = alpha2 * Tav2 + beta2 * Tdown
            Tup = RelaxationParameter * Tup + (1.0 - RelaxationParameter) * TupOld
            Tdown = RelaxationParameter * Tdown + (1.0 - RelaxationParameter) * TdownOld
            var gap1Direction: AirVerticalDirection
            var gap2Direction: AirVerticalDirection
            if tempGap1 > tempGap2:
                gap1Direction = AirVerticalDirection.Up
                gap2Direction = AirVerticalDirection.Down
            else:
                gap1Direction = AirVerticalDirection.Down
                gap2Direction = AirVerticalDirection.Up
            converged = abs(Tup - TupOld) < IterationConstants.CONVERGENCE_TOLERANCE_AIRFLOW
            converged = converged and (abs(Tdown - TdownOld) < IterationConstants.CONVERGENCE_TOLERANCE_AIRFLOW)
            t_Gap1.setFlowTemperatures(Tup, Tdown, gap1Direction)
            t_Gap2.setFlowTemperatures(Tup, Tdown, gap2Direction)
            iterationStep = iterationStep + 1
            if iterationStep > IterationConstants.NUMBER_OF_STEPS:
                converged = True
                raise Error("Airflow iterations fail to converge. Maximum number of iteration steps reached.")
        let qv1: Float64 = t_Gap1.getGainFlow()
        let qv2: Float64 = t_Gap2.getGainFlow()
        t_Gap1.smoothEnergyGain(qv1, qv2)
        t_Gap2.smoothEnergyGain(qv1, qv2)

    def calcEdgeShadeFlow(self, t_Environment: Pointer[CEnvironment], t_Gap: Pointer[CIGUVentilatedGapLayer]):
        var TgapOut: Float64 = t_Gap.layerTemperature()
        var RelaxationParameter: Float64 = IterationConstants.RELAXATION_PARAMETER_AIRFLOW
        var converged: Bool = False
        var iterationStep: UInt = 0
        var tempGap: Float64 = t_Gap.layerTemperature()
        while not converged:
            let tempEnvironment: Float64 = t_Environment.getGasTemperature()
            let TavGap: Float64 = t_Gap.averageTemperature()
            if tempGap > tempEnvironment:
                t_Gap.setFlowGeometry(self.m_ShadeOpenings.Aeq_bot(), self.m_ShadeOpenings.Aeq_top(), AirVerticalDirection.Up)
            else:
                t_Gap.setFlowGeometry(self.m_ShadeOpenings.Aeq_top(), self.m_ShadeOpenings.Aeq_bot(), AirVerticalDirection.Down)
            let drivingPressure: Float64 = t_Gap.getAirflowReferencePoint(tempEnvironment)
            let A: Float64 = t_Gap.bernoullyPressureTerm() + t_Gap.pressureLossTerm()
            let B: Float64 = t_Gap.hagenPressureTerm()
            let speed: Float64 = (sqrt(abs(pow(B, 2.0) + 4.0 * A * drivingPressure)) - B) / (2.0 * A)
            t_Gap.setFlowSpeed(speed)
            let beta: Float64 = t_Gap.betaCoeff()
            let alpha: Float64 = 1.0 - beta
            let TgapOutOld: Float64 = TgapOut
            TgapOut = alpha * TavGap + beta * tempEnvironment
            var gapDirection: AirVerticalDirection
            if TgapOut > tempEnvironment:
                gapDirection = AirVerticalDirection.Up
                t_Gap.setFlowTemperatures(TgapOut, tempEnvironment, gapDirection)
            else:
                gapDirection = AirVerticalDirection.Down
                t_Gap.setFlowTemperatures(tempEnvironment, TgapOut, gapDirection)
            tempGap = t_Gap.layerTemperature()
            TgapOut = RelaxationParameter * tempGap + (1.0 - RelaxationParameter) * TgapOutOld
            converged = abs(TgapOut - TgapOutOld) < IterationConstants.CONVERGENCE_TOLERANCE_AIRFLOW
            iterationStep = iterationStep + 1
            if iterationStep > IterationConstants.NUMBER_OF_STEPS:
                RelaxationParameter = RelaxationParameter - IterationConstants.RELAXATION_PARAMETER_AIRFLOW_STEP
                iterationStep = 0
                if RelaxationParameter == IterationConstants.RELAXATION_PARAMETER_AIRFLOW_MIN:
                    converged = True
                    raise Error("Airflow iterations fail to converge. Maximum number of iteration steps reached.")

    def equivalentConductivity(self, t_Conductivity: Float64, permeabilityFactor: Float64) -> Float64:
        let standardPressure: Float64 = 101325.0  # Pa
        let Tf: Float64 = self.m_Surface[Side.Front].getTemperature()
        let Tb: Float64 = self.m_Surface[Side.Back].getTemperature()
        var air: CGas = CGas()
        air.setTemperatureAndPressure((Tf + Tb) / 2.0, standardPressure)
        let airThermalConductivity: Float64 = air.getGasProperties().m_ThermalConductivity
        return airThermalConductivity * permeabilityFactor + (1.0 - permeabilityFactor) * t_Conductivity