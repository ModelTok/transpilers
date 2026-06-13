# EXTERNAL DEPS (to wire in glue):
# - CMaterial: from material_description
# - ICellDescription: from cell_description
# - CBaseCell: from base_cell
# - CUniformDiffuseCell: from uniform_diffuse_cell

struct CMaterial:
    pass

struct ICellDescription:
    pass

struct CBaseCell:
    var material_properties: CMaterial
    var cell: ICellDescription

    fn __init__(inout self, material_properties: CMaterial, cell: ICellDescription):
        self.material_properties = material_properties
        self.cell = cell

struct CUniformDiffuseCell(CBaseCell):
    fn __init__(inout self, material_properties: CMaterial, cell: ICellDescription):
        self.material_properties = material_properties
        self.cell = cell

struct CPerforatedCell(CUniformDiffuseCell):
    fn __init__(inout self, material_properties: CMaterial, cell: ICellDescription):
        CBaseCell.__init__(self, material_properties, cell)
        CUniformDiffuseCell.__init__(self, material_properties, cell)
