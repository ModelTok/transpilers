from CellDescription import ICellDescription
from WCECommon import Side, MaterialType, CBeamDirection

@value
struct CSpecularCellDescription(ICellDescription):
    def __init__(inout self):

    def T_dir_dir(self, t_Side: Side, borrowed t_Direction: CBeamDirection) -> Float64:
        return 0.0

    def R_dir_dir(self, t_Side: Side, borrowed t_Direction: CBeamDirection) -> Float64:
        return 0.0

    def Rspecular(self, t_Side: Side, borrowed t_Direction: CBeamDirection) -> Float64:
        return 0.0