
package FenestrationCommon:

    enum Combine:
        Interpolate
        Extrapolate

    struct CCommonWavelengths:
        var m_Wavelengths: List[List[Float64]]

        def __init__(inout self):

        def addWavelength(inout self, t_wv: borrowed List[Float64]):
            self.m_Wavelengths.append(List[Float64](t_wv))

        def getCombinedWavelengths(inout self, t_Combination: Combine) -> List[Float64]:
            var aCombined: List[Float64] = List[Float64]()
            for i in range(len(self.m_Wavelengths)):
                if i == 0:
                    aCombined = self.m_Wavelengths[i].copy()
                else:
                    aCombined = self.combineWavelegths(aCombined, self.m_Wavelengths[i], t_Combination)
            return aCombined

        def combineWavelegths(self, t_wv1: borrowed List[Float64], t_wv2: borrowed List[Float64], t_Combination: Combine) -> List[Float64]:
            var unionWavelengths: List[Float64] = List[Float64]()
            var combinedWavelengths: List[Float64] = List[Float64]()

            # manual set_union of two sorted lists
            var i1: Int = 0
            var i2: Int = 0
            while i1 < len(t_wv1) and i2 < len(t_wv2):
                if t_wv1[i1] < t_wv2[i2]:
                    unionWavelengths.append(t_wv1[i1])
                    i1 += 1
                elif t_wv1[i1] > t_wv2[i2]:
                    unionWavelengths.append(t_wv2[i2])
                    i2 += 1
                else:
                    unionWavelengths.append(t_wv1[i1])
                    i1 += 1
                    i2 += 1
            while i1 < len(t_wv1):
                unionWavelengths.append(t_wv1[i1])
                i1 += 1
            while i2 < len(t_wv2):
                unionWavelengths.append(t_wv2[i2])
                i2 += 1

            if t_Combination == Combine.Interpolate:
                var min1 = min(t_wv1)
                var min2 = min(t_wv2)
                var minWV = max(min1, min2)
                var max2 = max(t_wv2)
                var max1 = max(t_wv1)
                var maxWV = min(max1, max2)
                for val in unionWavelengths:
                    if (val >= minWV) and (val <= maxWV):
                        combinedWavelengths.append(val)
            elif t_Combination == Combine.Extrapolate:
                combinedWavelengths = unionWavelengths
            else:
                assert False, "Incorrect method for combining common wavelengths."
            return combinedWavelengths