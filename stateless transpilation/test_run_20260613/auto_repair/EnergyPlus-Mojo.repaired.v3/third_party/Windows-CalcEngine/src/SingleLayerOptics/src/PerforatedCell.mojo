from memory import Arc
from UniformDiffuseCell import CUniformDiffuseCell, CBaseCell
from CellDescription import ICellDescription
from MaterialDescription import CMaterial
from WCECommon import *

class CPerforatedCell(CUniformDiffuseCell):
    def __init__(inout self, t_MaterialProperties: borrowed Arc[CMaterial], t_Cell: borrowed Arc[ICellDescription]):
        CBaseCell.__init__(self, t_MaterialProperties, t_Cell)
        CUniformDiffuseCell.__init__(self, t_MaterialProperties, t_Cell)