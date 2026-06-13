from fenestration.common import WCECommon
from fenestration.materials import CMaterial, CUniformDiffuseCell
from fenestration.cell import CCellDescription

class CPerforatedCell(CUniformDiffuseCell):
    def __init__(self, t_MaterialProperties: CMaterial, t_Cell: CCellDescription):
        super().__init__(t_MaterialProperties, t_Cell)
