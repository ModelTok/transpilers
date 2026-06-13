# EXTERNAL DEPS (to wire in glue):
# from GasProperties import CoeffType, CIntCoeff

class CGasData:
    def __init__(self):
        self.m_gasName = "Air"
        self.m_molWeight = 28.97
        self.m_specificHeatRatio = 1.4
        self.m_Coefficients = {
            CoeffType.cCp: CIntCoeff(1.002737e+03, 1.2324e-02, 0.0),
            CoeffType.cCond: CIntCoeff(2.8733e-03, 7.76e-05, 0.0),
            CoeffType.cVisc: CIntCoeff(3.7233e-06, 4.94e-08, 0.0)
        }

    def __init__(self, t_GasData):
        self.__init__()
        self = t_GasData

    def __init__(self, t_Name, t_Wght, t_SpecHeatRatio, t_Cp, t_Con, t_Visc):
        self.m_gasName = t_Name
        self.m_molWeight = t_Wght
        self.m_specificHeatRatio = t_SpecHeatRatio
        self.m_Coefficients = {
            CoeffType.cCp: t_Cp,
            CoeffType.cCond: t_Con,
            CoeffType.cVisc: t_Visc
        }

    def __eq__(self, t_GasData):
        self.m_gasName = t_GasData.m_gasName
        self.m_molWeight = t_GasData.m_molWeight
        self.m_specificHeatRatio = t_GasData.m_specificHeatRatio
        self.m_Coefficients = t_GasData.m_Coefficients
        return self

    def getPropertyValue(self, t_Type, t_Temperature):
        return self.m_Coefficients[t_Type].interpolationValue(t_Temperature)

    def getSpecificHeatRatio(self):
        return self.m_specificHeatRatio

    def getMolecularWeight(self):
        return self.m_molWeight
