from CellDescription import ICellDescription
from BeamDirection import CBeamDirection
from FenestrationCommon import Side
from WCECommon import ConstantsData
from math import acos, cos, tan, atan

class CWovenCellDescription(ICellDescription):
    var m_Diameter: Float64
    var m_Spacing: Float64

    def __init__(self, t_Diameter: Float64, t_Spacing: Float64):
        super().__init__()
        self.m_Diameter = t_Diameter
        self.m_Spacing = t_Spacing
        if self.m_Diameter <= 0:
            raise Error("Woven shade diameter must be greater than zero.")
        if self.m_Spacing <= 0:
            raise Error("Woven shade threads spacing must be greater than zero.")

    def diameter(self) -> Float64:
        return self.m_Diameter

    def spacing(self) -> Float64:
        return self.m_Spacing

    def gamma(self) -> Float64:
        assert self.m_Spacing > 0
        return self.m_Diameter / self.m_Spacing

    def cutOffAngle(self) -> Float64:
        return acos(self.gamma())

    def T_dir_dir(self, t_Side: Side, t_Direction: CBeamDirection) -> Float64:
        return self.Tx(t_Direction) * self.Ty(t_Direction)

    def R_dir_dir(self, t_Side: Side, t_Direction: CBeamDirection) -> Float64:
        return 0

    def Tx(self, t_Direction: CBeamDirection) -> Float64:
        var aTx: Float64 = 0
        var cutOffAngle: Float64 = self.cutOffAngle()
        var aAzimuth: Float64 = t_Direction.Azimuth()
        if aAzimuth > ConstantsData.WCE_PI / 2:
            aAzimuth = ConstantsData.WCE_PI - aAzimuth
        if aAzimuth < -ConstantsData.WCE_PI / 2:
            aAzimuth = -ConstantsData.WCE_PI - aAzimuth
        aAzimuth = abs(aAzimuth)
        if aAzimuth < cutOffAngle:
            aTx = 1 - self.gamma() / cos(aAzimuth)
        return aTx

    def Ty(self, t_Direction: CBeamDirection) -> Float64:
        var aTy: Float64 = 0
        var cutOffAngle: Float64 = self.cutOffAngle()
        var aAltitude: Float64 = t_Direction.Altitude()
        var aPrim: Float64 = abs(atan(tan(aAltitude) / cos(aAltitude)))
        if aPrim < cutOffAngle:
            aTy = 1 - self.gamma() / cos(aPrim)
        return aTy