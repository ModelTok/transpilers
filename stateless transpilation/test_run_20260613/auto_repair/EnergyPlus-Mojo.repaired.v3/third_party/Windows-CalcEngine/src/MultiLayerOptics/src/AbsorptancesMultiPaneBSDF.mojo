from WCESingleLayerOptics import CBSDFLayer
from WCECommon import Side, CSeries, SquareMatrix, IntegrationType, PropertySimple

# Helper to mimic vector<double> -> List[Float64]
alias VectorD = List[Float64]

# Custom type for SquareMatrices
alias SquareMatrices = List[SquareMatrix]

struct CAbsorptancesMultiPaneBSDF:
    var m_Lambda: SquareMatrix
    var m_LambdaVector: VectorD
    var m_SolarRadiation: CSeries
    var m_TausF: List[SquareMatrices]
    var m_TausB: List[SquareMatrices]
    var m_RhosF: List[SquareMatrices]
    var m_RhosB: List[SquareMatrices]
    var m_rCoeffs: List[SquareMatrices]
    var m_tCoeffs: List[SquareMatrices]
    var m_Abs: List[VectorD]
    var m_CommonWavelengths: VectorD
    var m_StateCalculated: Bool
    var m_Side: Side
    var m_NumOfLayers: Int
    var m_Integrator: IntegrationType
    var m_NormalizationCoefficient: Float64

    def __init__(
        inout self,
        t_Side: Side,
        t_CommonWavelengths: VectorD,
        t_SolarRadiation: CSeries,
        t_Layer: CBSDFLayer,
        t_integrator: IntegrationType,
        normalizationCoefficient: Float64
    ):
        self.m_CommonWavelengths = t_CommonWavelengths.copy()
        self.m_StateCalculated = False
        self.m_Side = t_Side
        self.m_NumOfLayers = 0
        self.m_Integrator = t_integrator
        self.m_NormalizationCoefficient = normalizationCoefficient
        self.m_SolarRadiation = t_SolarRadiation.interpolate(self.m_CommonWavelengths)
        self.m_LambdaVector = t_Layer.getResults().lambdaVector()
        self.m_Lambda = t_Layer.getResults().lambdaMatrix()
        self.addLayer(t_Layer)

    def addLayer(inout self, t_Layer: CBSDFLayer):
        self.m_StateCalculated = False
        self.m_NumOfLayers += 1
        var aResults = t_Layer.getWavelengthResults()
        var aTausF = SquareMatrices()
        var aTausB = SquareMatrices()
        var aRhosF = SquareMatrices()
        var aRhosB = SquareMatrices()
        var size = self.m_CommonWavelengths.size()
        for i in range(size):
            var curWL = self.m_CommonWavelengths[i]
            var index = t_Layer.getBandIndex(curWL)
            if index <= -1:
                panic("Assertion failed: index > -1")
            aTausF.append(aResults[index].getMatrix(Side.Front, PropertySimple.T))
            aTausB.append(aResults[index].getMatrix(Side.Back, PropertySimple.T))
            aRhosF.append(aResults[index].getMatrix(Side.Front, PropertySimple.R))
            aRhosB.append(aResults[index].getMatrix(Side.Back, PropertySimple.R))
        self.m_TausF.append(aTausF)
        self.m_TausB.append(aTausB)
        self.m_RhosF.append(aRhosF)
        self.m_RhosB.append(aRhosB)

    def Abs(self, minLambda: Float64, maxLambda: Float64, Index: Int) -> VectorD:
        if Index > self.m_TausF.size():
            panic("Index for glazing layer absorptance is out of range.")
        var aLayerIndex = self.layerIndex(Index - 1)
        if not self.m_StateCalculated:
            self.calculateState(minLambda, maxLambda)
            self.m_StateCalculated = True
        return self.m_Abs[aLayerIndex]

    @staticmethod
    def multVectors(t_vec1: VectorD, t_vec2: VectorD) -> VectorD:
        if t_vec1.size() != t_vec2.size():
            panic("Vectors are not same size.")
        var Result = VectorD()
        for i in range(t_vec1.size()):
            var value = t_vec1[i] * t_vec2[i]
            Result.append(value)
        return Result

    @staticmethod
    def divVectors(t_vec1: VectorD, t_vec2: VectorD) -> VectorD:
        if t_vec1.size() != t_vec2.size():
            panic("Vectors are not same size.")
        var Result = VectorD()
        for i in range(t_vec1.size()):
            var value = t_vec1[i] / t_vec2[i]
            Result.append(value)
        return Result

    @staticmethod
    def addVectors(t_vec1: VectorD, t_vec2: VectorD) -> VectorD:
        if t_vec1.size() != t_vec2.size():
            panic("Vectors are not same size.")
        var Result = VectorD()
        for i in range(t_vec1.size()):
            var value = t_vec1[i] + t_vec2[i]
            Result.append(value)
        return Result

    def calculateState(inout self, minLambda: Float64, maxLambda: Float64):
        var numOfWavelengths = self.m_CommonWavelengths.size()
        var matrixSize = self.m_TausF[0][0].size()
        for i in range(self.m_NumOfLayers - 1, -1, -1):
            var r = SquareMatrices()
            var t = SquareMatrices()
            var vTauF: SquareMatrices
            var vTauB: SquareMatrices
            var vRhoF: SquareMatrices
            var vRhoB: SquareMatrices
            var aLayerIndex = self.layerIndex(i)
            if self.m_Side == Side.Front:
                vTauF = self.m_TausF[aLayerIndex]
                vTauB = self.m_TausB[aLayerIndex]
                vRhoF = self.m_RhosF[aLayerIndex]
                vRhoB = self.m_RhosB[aLayerIndex]
            elif self.m_Side == Side.Back:
                vTauF = self.m_TausB[aLayerIndex]
                vTauB = self.m_TausF[aLayerIndex]
                vRhoF = self.m_RhosB[aLayerIndex]
                vRhoB = self.m_RhosF[aLayerIndex]
            else:
                panic("Incorrect side selection.")
            for j in range(numOfWavelengths):
                var aTauF = vTauF[j]
                var aTauB = vTauB[j]
                var aRhoF = vRhoF[j]
                var aRhoB = vRhoB[j]
                var aRi = self.m_Lambda * aRhoF
                if i != self.m_NumOfLayers - 1:
                    var prevR = self.m_rCoeffs[i][j]
                    var lambdaTauF = self.m_Lambda * aTauF
                    var Denominator = self.getDenomForRTCoeff(aRhoB, prevR)
                    var rsecF = lambdaTauF * lambdaTauF
                    rsecF = rsecF * prevR
                    rsecF = rsecF * Denominator
                    aRi = aRi + rsecF
                    var tfwd = lambdaTauF * Denominator
                    t.append(tfwd)
                else:
                    t.append(self.m_Lambda * aTauF)
                r.append(aRi)
            self.m_rCoeffs.insert(0, r)
            self.m_tCoeffs.insert(0, t)

        var IminusM = List[SquareMatrices]()
        var IplusM = List[SquareMatrices]()
        for i in range(self.m_NumOfLayers):
            IminusM.append(SquareMatrices())
            IplusM.append(SquareMatrices())
            for _ in range(numOfWavelengths):
                IminusM[i].append(SquareMatrix())
                IplusM[i].append(SquareMatrix())
        # Actually need to resize after init
        for i in range(self.m_NumOfLayers):
            IminusM[i].resize(numOfWavelengths)
            IplusM[i].resize(numOfWavelengths)

        var Iincoming = SquareMatrix(matrixSize)
        Iincoming.setIdentity()
        for i in range(self.m_NumOfLayers):
            for j in range(numOfWavelengths):
                var r = self.m_rCoeffs[i][j]
                var t = self.m_tCoeffs[i][j]
                var activeI: SquareMatrix
                if i == 0:
                    activeI = Iincoming
                else:
                    activeI = IminusM[i - 1][j]
                IplusM[i][j] = r * activeI
                IminusM[i][j] = t * activeI

        var IminusV = List[List[VectorD]]()
        var IplusV = List[List[VectorD]]()
        for i in range(self.m_NumOfLayers):
            IminusV.append(List[VectorD]())
            IplusV.append(List[VectorD]())
            for _ in range(numOfWavelengths):
                IminusV[i].append(VectorD())
                IplusV[i].append(VectorD())
        for j in range(self.m_NumOfLayers):
            for k in range(self.m_CommonWavelengths.size()):
                IminusV[j][k] = VectorD(matrixSize, 1) * IminusM[j][k]
                IplusV[j][k] = VectorD(matrixSize, 1) * IplusM[j][k]

        self.m_Abs.clear()
        self.m_Abs.resize(self.m_NumOfLayers)
        for i in range(self.m_NumOfLayers):
            self.m_Abs[i].resize(matrixSize)

        var totalSolar = self.m_SolarRadiation.integrate(self.m_Integrator, self.m_NormalizationCoefficient).sum(minLambda, maxLambda)
        for i in range(matrixSize):
            for j in range(self.m_NumOfLayers):
                var curSpectralProperties = CSeries()
                for k in range(self.m_CommonWavelengths.size()):
                    var IminusIncoming = 0.0
                    var IminusOutgoing = 0.0
                    var IplusIncoming = 0.0
                    var IplusOutgoing = 0.0
                    IminusOutgoing = IminusV[j][k][i]
                    IplusOutgoing = IplusV[j][k][i]
                    if j == 0:
                        IminusIncoming = 1.0
                    else:
                        IminusIncoming = (IminusV[j - 1][k])[i]
                    if j == self.m_NumOfLayers - 1:
                        IplusIncoming = 0.0
                    else:
                        IplusIncoming = (IplusV[j + 1][k])[i]
                    var absValue = IminusIncoming + IplusIncoming - IminusOutgoing - IplusOutgoing
                    curSpectralProperties.addProperty(self.m_CommonWavelengths[k], absValue)
                var absorbedIrradiance = curSpectralProperties * self.m_SolarRadiation
                var integratedAbsorbed = absorbedIrradiance.integrate(self.m_Integrator, self.m_NormalizationCoefficient)
                var value = integratedAbsorbed.sum(minLambda, maxLambda)
                value = value / totalSolar
                self.m_Abs[j][i] = value
        self.m_StateCalculated = True

    def getDenomForRTCoeff(self, t_Reflectance: SquareMatrix, t_PreviousR: SquareMatrix) -> SquareMatrix:
        var matrixSize = t_Reflectance.size()
        var denominator = SquareMatrix(matrixSize)
        denominator.setIdentity()
        var lambdaRf = self.m_Lambda * t_Reflectance
        lambdaRf = lambdaRf * t_PreviousR
        denominator = denominator - lambdaRf
        denominator = denominator.inverse()
        return denominator

    def layerIndex(self, Index: Int) -> Int:
        var aLayerIndex: Int = 0
        if self.m_Side == Side.Front:
            aLayerIndex = Index
        elif self.m_Side == Side.Back:
            aLayerIndex = self.m_NumOfLayers - Index - 1
        else:
            panic("Incorrect side selection.")
        return aLayerIndex