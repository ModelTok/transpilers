# EXTERNAL DEPS (to wire in glue):
# - ICellDescription: from CellDescription (base class)
# - CBeamDirection: from WCECommon
# - FenestrationCommon.Side: from FenestrationCommon

from typing import Protocol


class Side(Protocol):
    pass


class CBeamDirection(Protocol):
    pass


class ICellDescription(Protocol):
    def T_dir_dir(self, t_Side: Side, t_Direction: CBeamDirection) -> float:
        ...

    def R_dir_dir(self, t_Side: Side, t_Direction: CBeamDirection) -> float:
        ...

    def Rspecular(self, t_Side: Side, t_Direction: CBeamDirection) -> float:
        ...


class CSpecularCellDescription(ICellDescription):
    def __init__(self):
        pass

    def T_dir_dir(self, t_Side: Side, t_Direction: CBeamDirection) -> float:
        return 0.0

    def R_dir_dir(self, t_Side: Side, t_Direction: CBeamDirection) -> float:
        return 0.0

    def Rspecular(self, t_Side: Side, t_Direction: CBeamDirection) -> float:
        return 0.0
