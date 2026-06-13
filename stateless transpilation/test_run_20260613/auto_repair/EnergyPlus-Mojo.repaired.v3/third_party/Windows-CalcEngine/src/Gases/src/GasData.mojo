from GasProperties import CoeffType, CIntCoeff

struct CGasData:
    var m_gasName: String
    var m_molWeight: Float64
    var m_specificHeatRatio: Float64
    var m_Coefficients: Dict[CoeffType, CIntCoeff]

    def __init__(self):
        self.m_gasName = "Air"
        self.m_molWeight = 28.97
        self.m_specificHeatRatio = 1.4
        self.m_Coefficients = Dict[CoeffType, CIntCoeff]()
        self.m_Coefficients[CoeffType.cCp] = CIntCoeff(1.002737e+03, 1.2324e-02, 0.0)
        self.m_Coefficients[CoeffType.cCond] = CIntCoeff(2.8733e-03, 7.76e-05, 0.0)
        self.m_Coefficients[CoeffType.cVisc] = CIntCoeff(3.7233e-06, 4.94e-08, 0.0)

    def __init__(self, other: Self):
        `operator=`(self, other)

    def __init__(self, t_Name: String, t_Wght: Float64, t_SpecHeatRatio: Float64,
                t_Cp: CIntCoeff, t_Con: CIntCoeff, t_Visc: CIntCoeff):
        self.m_gasName = t_Name
        self.m_molWeight = t_Wght
        self.m_specificHeatRatio = t_SpecHeatRatio
        self.m_Coefficients = Dict[CoeffType, CIntCoeff]()
        self.m_Coefficients[CoeffType.cCp] = t_Cp
        self.m_Coefficients[CoeffType.cCond] = t_Con
        self.m_Coefficients[CoeffType.cVisc] = t_Visc

    def `operator=`(self, other: Self) -> Self:
        self.m_gasName = other.m_gasName
        self.m_molWeight = other.m_molWeight
        self.m_specificHeatRatio = other.m_specificHeatRatio
        self.m_Coefficients = other.m_Coefficients
        return self

    def getMolecularWeight(self) -> Float64:
        return self.m_molWeight

    def getPropertyValue(self, t_Type: CoeffType, t_Temperature: Float64) -> Float64:
        return self.m_Coefficients[t_Type].interpolationValue(t_Temperature)

    def getSpecificHeatRatio(self) -> Float64:
        return self.m_specificHeatRatio