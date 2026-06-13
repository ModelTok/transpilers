# EXTERNAL DEPS (to wire in glue):
# - ICellDescription: from CellDescription (trait)
# - CBeamDirection: from WCECommon
# - FenestrationCommon.Side: from FenestrationCommon


struct Side:
    pass


struct CBeamDirection:
    pass


trait ICellDescription:
    fn T_dir_dir(self, t_Side: Side, t_Direction: CBeamDirection) -> Float64:
        ...

    fn R_dir_dir(self, t_Side: Side, t_Direction: CBeamDirection) -> Float64:
        ...

    fn Rspecular(self, t_Side: Side, t_Direction: CBeamDirection) -> Float64:
        ...


struct CSpecularCellDescription(ICellDescription):
    fn __init__(inout self):
        pass

    fn T_dir_dir(self, t_Side: Side, t_Direction: CBeamDirection) -> Float64:
        return 0.0

    fn R_dir_dir(self, t_Side: Side, t_Direction: CBeamDirection) -> Float64:
        return 0.0

    fn Rspecular(self, t_Side: Side, t_Direction: CBeamDirection) -> Float64:
        return 0.0
