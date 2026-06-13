from memory import Pointer
from SpecularCell import CSpecularCell
from ......FenestrationCommon import Side, CBeamDirection, CSeries
from ...Material import CMaterial

struct BaseLayer:
    def __init__(inout self):

    def __del__(owned self):

    def Flipped(inout self, flipped: Bool):

struct SpecularLayer(BaseLayer):
    var m_Cell: CSpecularCell

    def __init__(inout self, m_Cell: borrowed CSpecularCell):
        self.m_Cell = m_Cell

    @staticmethod
    def createLayer(t_Material: Pointer[CMaterial]) -> Pointer[SpecularLayer]:
        var aCell = CSpecularCell(t_Material)
        return Pointer[SpecularLayer](SpecularLayer(aCell^))

    def T_dir_dir(borrowed self, t_Side: Side, t_Direction: borrowed CBeamDirection) -> Float64:
        return self.m_Cell.T_dir_dir(t_Side, t_Direction)

    def R_dir_dir(borrowed self, t_Side: Side, t_Direction: borrowed CBeamDirection) -> Float64:
        return self.m_Cell.R_dir_dir(t_Side, t_Direction)

    def T_dir_dir_band(borrowed self, t_Side: Side, t_Direction: borrowed CBeamDirection) -> List[Float64]:
        return self.m_Cell.T_dir_dir_band(t_Side, t_Direction)

    def R_dir_dir_band(borrowed self, t_Side: Side, t_Direction: borrowed CBeamDirection) -> List[Float64]:
        return self.m_Cell.R_dir_dir_band(t_Side, t_Direction)

    def getBandWavelengths(borrowed self) -> List[Float64]:
        return self.m_Cell.getBandWavelengths()

    def setSourceData(inout self, t_SourceData: inout CSeries):
        self.m_Cell.setSourceData(t_SourceData)

    def getMinLambda(borrowed self) -> Float64:
        return self.getBandWavelengths()[0]

    def getMaxLambda(borrowed self) -> Float64:
        var lastIndex = self.getBandWavelengths().size()
        return self.getBandWavelengths()[lastIndex - 1]

    def Flipped(inout self, flipped: Bool):
        self.m_Cell.Flipped(flipped)