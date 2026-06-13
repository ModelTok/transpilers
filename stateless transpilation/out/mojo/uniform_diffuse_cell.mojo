// EXTERNAL DEPS (to wire in glue):
// import fenestration_common.{Side, Property}
// import single_layer_optics.{ICellDescription, CBeamDirection, CMaterial, CBaseCell}

struct CUniformDiffuseCell {
    material_properties: Optional<CMaterial>,
    cell: Optional<ICellDescription>,
    rotation: f64,
}

impl CUniformDiffuseCell {
    fn new(material_properties: Optional<CMaterial>, cell: Optional<ICellDescription>, rotation: f64) -> Self {
        Self {
            material_properties,
            cell,
            rotation,
        }
    }

    fn T_dir_dif(&self, t_Side: Side, t_Direction: CBeamDirection) -> f64 {
        self.getMaterialProperty(Property.T, t_Side, t_Direction)
    }

    fn R_dir_dif(&self, t_Side: Side, t_Direction: CBeamDirection) -> f64 {
        ((1.0 - self.T_dir_dir(t_Side, t_Direction))
         * self.material_properties.getProperty(Property.R, t_Side))
    }

    fn T_dir_dif_band(&self, t_Side: Side, t_Direction: CBeamDirection) -> InlineArray[f64, 10] {
        self.getMaterialProperties(Property.T, t_Side, t_Direction)
    }

    fn R_dir_dif_band(&self, t_Side: Side, t_Direction: CBeamDirection) -> InlineArray[f64, 10] {
        self.getMaterialProperties(Property.R, t_Side, t_Direction)
    }

    fn getMaterialProperty(&self, t_Property: Property, t_Side: Side, t_Direction: CBeamDirection) -> f64 {
        ((1.0 - self.T_dir_dir(t_Side, t_Direction)) * self.material_properties.getProperty(t_Property, t_Side))
    }

    fn getMaterialProperties(&self, t_Property: Property, t_Side: Side, t_Direction: CBeamDirection) -> InlineArray[f64, 10] {
        let materialCoverFraction = 1.0 - self.T_dir_dir(t_Side, t_Direction);
        let aMaterialProperties = self.material_properties.getBandProperties(t_Property, t_Side);
        let mut aProperty = InlineArray[f64, 10](fill: 0.0);
        for i in 0..aMaterialProperties.len() {
            aProperty[i] = materialCoverFraction * aMaterialProperties[i];
        }
        aProperty
    }
}
