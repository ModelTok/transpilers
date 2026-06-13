// EXTERNAL DEPS (to wire in glue):
// - CMaterial
// - ICellDescription
// - CBeamDirection
// - CBaseCell
// - CSpecularCellDescription
// - FenestrationCommon.Side
// - SpectralAveraging.Property

import math

struct CMaterial {
    fn getProperty(self, property: String, side: FenestrationCommon.Side, direction: CBeamDirection) -> Float64
    fn getBandProperties(self, property: String, side: FenestrationCommon.Side, direction: CBeamDirection) -> Array[Float64]
}

struct ICellDescription {}

struct CBeamDirection {}

struct CBaseCell {
    var m_Material: CMaterial
    var m_CellDescription: Optional[ICellDescription]

    fn __init__(self, material_properties: CMaterial, cell: Optional[ICellDescription] = None) {
        self.m_Material = material_properties
        self.m_CellDescription = cell
    }

    fn T_dir_dir(self, side: FenestrationCommon.Side, direction: CBeamDirection) -> Float64
    fn R_dir_dir(self, side: FenestrationCommon.Side, direction: CBeamDirection) -> Float64
    fn T_dir_dir_band(self, side: FenestrationCommon.Side, direction: CBeamDirection) -> Array[Float64]
    fn R_dir_dir_band(self, side: FenestrationCommon.Side, direction: CBeamDirection) -> Array[Float64]
}

struct CSpecularCellDescription: ICellDescription {}

struct FenestrationCommon {
    enum class Side {}
}

struct SpectralAveraging {
    enum class Property {
        T,
        R
    }
}

struct SingleLayerOptics {
    struct CSpecularCell: CBaseCell {
        fn __init__(self, material_properties: CMaterial, cell: Optional[ICellDescription] = None) {
            super(material_properties, cell)
        }

        fn __init__(self, material_properties: CMaterial) {
            super(material_properties, CSpecularCellDescription())
        }

        fn T_dir_dir(self, side: FenestrationCommon.Side, direction: CBeamDirection) -> Float64 {
            return self.m_Material.getProperty(SpectralAveraging.Property.T, side, direction)
        }

        fn R_dir_dir(self, side: FenestrationCommon.Side, direction: CBeamDirection) -> Float64 {
            return self.m_Material.getProperty(SpectralAveraging.Property.R, side, direction)
        }

        fn T_dir_dir_band(self, side: FenestrationCommon.Side, direction: CBeamDirection) -> Array[Float64] {
            return self.m_Material.getBandProperties(SpectralAveraging.Property.T, side, direction)
        }

        fn R_dir_dir_band(self, side: FenestrationCommon.Side, direction: CBeamDirection) -> Array[Float64] {
            return self.m_Material.getBandProperties(SpectralAveraging.Property.R, side, direction)
        }

        fn getCellAsSpecular(self) -> CSpecularCellDescription {
            if !(self.m_CellDescription is CSpecularCellDescription) {
                panic("Incorrectly assigned cell description.")
            }
            return self.m_CellDescription as CSpecularCellDescription
        }
    }
}
