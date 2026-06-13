// EXTERNAL DEPS (to wire in glue):
// - SingleLayerOptics.CScatteringSurface
// - FenestrationCommon.ScatteringSimple

struct CScatteringSurface {
    T_dir_dir: f64,
    R_dir_dir: f64,
    T_dir_dif: f64,
    R_dir_dif: f64,
    T_dif_dif: f64,
    R_dif_dif: f64,
}

impl CScatteringSurface {
    fn new(T_dir_dir: f64, R_dir_dir: f64, T_dir_dif: f64, R_dir_dif: f64, T_dif_dif: f64, R_dif_dif: f64) -> Self {
        Self {
            T_dir_dir,
            R_dir_dir,
            T_dir_dif,
            R_dir_dif,
            T_dif_dif,
            R_dif_dif,
        }
    }

    fn getAbsorptance(self, scattering_type: i32) -> f64 {
        match scattering_type {
            0 => 1.0 - self.T_dir_dir - self.R_dir_dir,
            1 => 1.0 - self.T_dif_dif - self.R_dif_dif,
            _ => 0.0,
        }
    }
}

struct ScatteringSimple {
    static Direct: i32 = 0;
    static Diffuse: i32 = 1;
}

struct TestScatteringSurface {
    m_Surface: Option<CScatteringSurface>;
}

impl TestScatteringSurface {
    fn new() -> Self {
        Self {
            m_Surface: None,
        }
    }

    fn setUp(self) {
        let T_dir_dir = 0.08;
        let R_dir_dir = 0.05;

        let T_dir_dif = 0.46;
        let R_dir_dif = 0.23;

        let T_dif_dif = 0.46;
        let R_dif_dif = 0.52;

        self.m_Surface = Some(CScatteringSurface::new(T_dir_dir, R_dir_dir, T_dir_dif, R_dir_dif, T_dif_dif, R_dif_dif));
    }

    fn getSurface(self) -> CScatteringSurface {
        self.m_Surface.unwrap()
    }
}

fn test_scattering_surface1() {
    let test = TestScatteringSurface::new();
    test.setUp();

    let surf = test.getSurface();

    let A_dir = surf.getAbsorptance(ScatteringSimple::Direct);
    assert!(A_dir.abs() - 0.18 < 1e-6);

    let A_dif = surf.getAbsorptance(ScatteringSimple::Diffuse);
    assert!(A_dif.abs() - 0.02 < 1e-6);
}
