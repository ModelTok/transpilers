from CellDescription import ICellDescription
from ...FenestrationCommon import Side, CBeamDirection

struct CFlatCellDescription(ICellDescription):
    def __init__(inout self):
        super().__init__()

    def T_dir_dir(self, t_Side: Side, t_Direction: CBeamDirection) -> Float64:
        return 0.0

    def R_dir_dir(self, t_Side: Side, t_Direction: CBeamDirection) -> Float64:
        return 0.0