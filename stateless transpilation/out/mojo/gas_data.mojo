# EXTERNAL DEPS (to wire in glue):
# from GasProperties import CoeffType, CIntCoeff

struct CGasData {
    var m_gasName: String
    var m_molWeight: Double
    var m_specificHeatRatio: Double
    var m_Coefficients: Map[CoeffType, CIntCoeff]
}

fn CGasData() -> CGasData {
    CGasData {
        m_gasName: "Air",
        m_molWeight: 28.97,
        m_specificHeatRatio: 1.4,
        m_Coefficients: {
            CoeffType.cCp: CIntCoeff(1.002737e+03, 1.2324e-02, 0.0),
            CoeffType.cCond: CIntCoeff(2.8733e-03, 7.76e-05, 0.0),
            CoeffType.cVisc: CIntCoeff(3.7233e-06, 4.94e-08, 0.0)
        }
    }
}

fn CGasData(t_GasData: CGasData) -> CGasData {
    var self = CGasData()
    self = t_GasData
    self
}

fn CGasData(t_Name: String, t_Wght: Double, t_SpecHeatRatio: Double, t_Cp: CIntCoeff, t_Con: CIntCoeff, t_Visc: CIntCoeff) -> CGasData {
    CGasData {
        m_gasName: t_Name,
        m_molWeight: t_Wght,
        m_specificHeatRatio: t_SpecHeatRatio,
        m_Coefficients: {
            CoeffType.cCp: t_Cp,
            CoeffType.cCond: t_Con,
            CoeffType.cVisc: t_Visc
        }
    }
}

fn operator=(self: CGasData, t_GasData: CGasData) -> CGasData {
    self.m_gasName = t_GasData.m_gasName
    self.m_molWeight = t_GasData.m_molWeight
    self.m_specificHeatRatio = t_GasData.m_specificHeatRatio
    self.m_Coefficients = t_GasData.m_Coefficients
    self
}

fn getPropertyValue(self: CGasData, t_Type: CoeffType, t_Temperature: Double) -> Double {
    self.m_Coefficients[t_Type].interpolationValue(t_Temperature)
}

fn getSpecificHeatRatio(self: CGasData) -> Double {
    self.m_specificHeatRatio
}

fn getMolecularWeight(self: CGasData) -> Double {
    self.m_molWeight
}
