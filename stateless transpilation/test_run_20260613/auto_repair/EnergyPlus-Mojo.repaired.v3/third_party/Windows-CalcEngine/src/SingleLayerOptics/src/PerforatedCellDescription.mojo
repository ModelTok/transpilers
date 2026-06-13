module SingleLayerOptics:

    from CellDescription import ICellDescription
    from WCECommon import Side, radians, WCE_PI
    from BeamDirection import CBeamDirection
    from math import atan, tan, cos, sin

    struct CPerforatedCellDescription:
        var m_x: Float64
        var m_y: Float64
        var m_Thickness: Float64

        def __init__(inout self, t_x: Float64, t_y: Float64, t_Thickness: Float64):
            self.m_x = t_x
            self.m_y = t_y
            self.m_Thickness = t_Thickness

        def R_dir_dir(self, t_Side: Side, t_Direction: &CBeamDirection) -> Float64:
            return 0.0

    struct CCircularCellDescription(CPerforatedCellDescription):
        var m_Radius: Float64

        def __init__(inout self, t_x: Float64, t_y: Float64, t_Thickness: Float64, t_Radius: Float64):
            self.m_x = t_x
            self.m_y = t_y
            self.m_Thickness = t_Thickness
            self.m_Radius = t_Radius

        def T_dir_dir(self, t_Side: FenestrationCommon.Side, t_Direction: &CBeamDirection) -> Float64:
            return self.visibleAhole(t_Direction) / self.visibleAcell(t_Direction)

        def visibleAhole(self, t_Direction: &CBeamDirection) -> Float64:
            var aHole: Float64 = 0.0
            var angleLimit: Float64 = atan(2.0 * self.m_Radius / self.m_Thickness)
            var aTheta: Float64 = radians(t_Direction.theta())
            if (aTheta < 0.0) or (aTheta > angleLimit):
                aHole = 0.0
            else:
                var A1: Float64 = 0.0
                var A2: Float64 = 0.0
                A1 = WCE_PI / 2.0 * self.m_Radius * self.m_Radius * cos(aTheta)
                A2 = WCE_PI / 2.0 * (self.m_Radius * self.m_Radius * cos(aTheta) - self.m_Radius * self.m_Thickness * sin(aTheta))
                aHole = A1 + A2
            return aHole

        def visibleAcell(self, t_Direction: &CBeamDirection) -> Float64:
            var aTheta: Float64 = radians(t_Direction.theta())
            return (self.m_x * self.m_y) * cos(aTheta)

        def xDimension(self) -> Float64:
            return self.m_x

        def yDimension(self) -> Float64:
            return self.m_y

        def thickness(self) -> Float64:
            return self.m_Thickness

        def radius(self) -> Float64:
            return self.m_Radius

    struct CRectangularCellDescription(CPerforatedCellDescription):
        var m_XHole: Float64
        var m_YHole: Float64

        def __init__(inout self, t_x: Float64, t_y: Float64, t_Thickness: Float64, t_XHole: Float64, t_YHole: Float64):
            self.m_x = t_x
            self.m_y = t_y
            self.m_Thickness = t_Thickness
            self.m_XHole = t_XHole
            self.m_YHole = t_YHole

        def T_dir_dir(self, t_Side: FenestrationCommon.Side, t_Direction: &CBeamDirection) -> Float64:
            return self.TransmittanceH(t_Direction) * self.TransmittanceV(t_Direction)

        def TransmittanceV(self, t_Direction: &CBeamDirection) -> Float64:
            var Psi: Float64 = 0.0
            var lowerLimit: Float64 = 0.0
            var upperLimit: Float64 = 0.0
            lowerLimit = -(atan(self.m_YHole / self.m_Thickness))
            upperLimit = -lowerLimit
            Psi = -t_Direction.profileAngle()
            Psi = radians(Psi)
            if (Psi <= lowerLimit) or (Psi >= upperLimit):
                return 0.0
            else:
                var Transmittance: Float64 = 0.0
                Transmittance = ((self.m_YHole / self.m_y) - abs(self.m_Thickness / self.m_y * tan(Psi)))
                if Transmittance < 0.0:
                    Transmittance = 0.0
                return Transmittance

        def TransmittanceH(self, t_Direction: &CBeamDirection) -> Float64:
            var Eta: Float64 = 0.0
            var lowerLimit: Float64 = 0.0
            var upperLimit: Float64 = 0.0
            lowerLimit = -(atan(self.m_XHole / self.m_Thickness))
            upperLimit = -lowerLimit
            var Phi: Float64 = radians(t_Direction.phi())
            var Theta: Float64 = radians(t_Direction.theta())
            Eta = atan(cos(Phi) * tan(Theta))
            if (Eta <= lowerLimit) or (Eta >= upperLimit):
                return 0.0
            else:
                var Transmittance: Float64 = 0.0
                Transmittance = ((self.m_XHole / self.m_x) - abs(self.m_Thickness / self.m_x * tan(Eta)))
                if Transmittance < 0.0:
                    Transmittance = 0.0
                return Transmittance

        def xDimension(self) -> Float64:
            return self.m_x

        def yDimension(self) -> Float64:
            return self.m_y

        def thickness(self) -> Float64:
            return self.m_Thickness

        def xHole(self) -> Float64:
            return self.m_XHole

        def yHole(self) -> Float64:
            return self.m_YHole