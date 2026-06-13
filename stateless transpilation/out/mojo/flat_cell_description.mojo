# EXTERNAL DEPS (to wire in glue):
# - FenestrationCommon.Side: side enum (from FenestrationCommon module)
# - CBeamDirection: beam direction struct (from CellDescription module)
# - ICellDescription: base trait (from CellDescription module)

alias Side = Int

struct CBeamDirection:
    pass

trait ICellDescription:
    fn T_dir_dir(self, t_Side: Side, t_Direction: CBeamDirection) -> Float64:
        ...
    fn R_dir_dir(self, t_Side: Side, t_Direction: CBeamDirection) -> Float64:
        ...

struct CFlatCellDescription(ICellDescription):
    """Cell description that needs to be used for perfect diffusers. Specular components are set to zero"""
    
    fn __init__(inout self):
        pass
    
    fn T_dir_dir(self, t_Side: Side, t_Direction: CBeamDirection) -> Float64:
        return 0.0
    
    fn R_dir_dir(self, t_Side: Side, t_Direction: CBeamDirection) -> Float64:
        return 0.0
