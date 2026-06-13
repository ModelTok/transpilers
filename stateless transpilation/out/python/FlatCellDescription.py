# EXTERNAL DEPS (to wire in glue):
# - FenestrationCommon.Side: side enum (from FenestrationCommon module)
# - CBeamDirection: beam direction class (from CellDescription module)
# - ICellDescription: base class (from CellDescription module)

class ICellDescription:
    pass

class CBeamDirection:
    pass

class Side:
    pass

class CFlatCellDescription(ICellDescription):
    """Cell description that needs to be used for perfect diffusers. Specular components are set to zero"""
    
    def __init__(self) -> None:
        super().__init__()
    
    def T_dir_dir(self, t_Side: Side, t_Direction: CBeamDirection) -> float:
        return 0.0
    
    def R_dir_dir(self, t_Side: Side, t_Direction: CBeamDirection) -> float:
        return 0.0
