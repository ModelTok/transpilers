# EXTERNAL DEPS (to wire in glue):
# - CMaterial: from material_description
# - ICellDescription: from cell_description
# - CBaseCell: from base_cell
# - CUniformDiffuseCell: from uniform_diffuse_cell

class CMaterial:
    pass

class ICellDescription:
    pass

class CBaseCell:
    def __init__(self, material_properties, cell):
        self.material_properties = material_properties
        self.cell = cell

class CUniformDiffuseCell(CBaseCell):
    def __init__(self, material_properties, cell):
        self.material_properties = material_properties
        self.cell = cell

class CPerforatedCell(CUniformDiffuseCell):
    def __init__(self, material_properties, cell):
        CBaseCell.__init__(self, material_properties, cell)
        CUniformDiffuseCell.__init__(self, material_properties, cell)
