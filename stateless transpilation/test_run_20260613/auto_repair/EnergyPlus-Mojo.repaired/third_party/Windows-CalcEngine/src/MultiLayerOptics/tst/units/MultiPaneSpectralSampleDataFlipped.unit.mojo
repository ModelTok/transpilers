from ...WCEMultiLayerOptics import CMultiPaneSampleData
from ...WCESingleLayerOptics import CSpectralSampleData
from ...WCESpectralAveraging import (
    # No types needed from that header in this file
)
from ...WCECommon import (
    CSeries,
    Property,
    Side,
)

class TestMultiLayerOpticsMeasuredSampleDataFlipped:
    var m_MultiLayerOptics: CMultiPaneSampleData

    def __init__(inout self):
        self.m_MultiLayerOptics = CMultiPaneSampleData()

    def SetUp(inout self):
        var sampleMeasurements1 = CSpectralSampleData()
        sampleMeasurements1.addRecord(0.330, 0.0857, 0.0560, 0.2646)
        sampleMeasurements1.addRecord(0.335, 0.1280, 0.0623, 0.2664)
        sampleMeasurements1.addRecord(0.340, 0.1707, 0.0719, 0.2668)
        sampleMeasurements1.addRecord(0.345, 0.2125, 0.0840, 0.2680)
        sampleMeasurements1.addRecord(0.350, 0.2536, 0.0990, 0.2706)
        sampleMeasurements1.addRecord(0.355, 0.2953, 0.1165, 0.2735)
        sampleMeasurements1.addRecord(0.360, 0.3370, 0.1365, 0.2773)
        sampleMeasurements1.addRecord(0.365, 0.3774, 0.1579, 0.2809)
        sampleMeasurements1.addRecord(0.370, 0.4125, 0.1773, 0.2829)
        sampleMeasurements1.addRecord(0.375, 0.4414, 0.1931, 0.2836)
        sampleMeasurements1.addRecord(0.380, 0.4671, 0.2074, 0.2827)
        sampleMeasurements1.addRecord(0.385, 0.4953, 0.2244, 0.2814)
        sampleMeasurements1.addRecord(0.390, 0.5229, 0.2415, 0.2801)
        sampleMeasurements1.addRecord(0.395, 0.5455, 0.2553, 0.2781)
        sampleMeasurements1.addRecord(0.400, 0.5630, 0.2651, 0.2757)

        var sampleMeasurements2 = CSpectralSampleData()
        sampleMeasurements2.addRecord(0.330, 0.1600, 0.0450, 0.0470)
        sampleMeasurements2.addRecord(0.335, 0.2940, 0.0490, 0.0500)
        sampleMeasurements2.addRecord(0.340, 0.4370, 0.0550, 0.0560)
        sampleMeasurements2.addRecord(0.345, 0.5660, 0.0620, 0.0620)
        sampleMeasurements2.addRecord(0.350, 0.6710, 0.0690, 0.0690)
        sampleMeasurements2.addRecord(0.355, 0.7440, 0.0740, 0.0740)
        sampleMeasurements2.addRecord(0.360, 0.7930, 0.0780, 0.0780)
        sampleMeasurements2.addRecord(0.365, 0.8220, 0.0800, 0.0800)
        sampleMeasurements2.addRecord(0.370, 0.8320, 0.0810, 0.0810)
        sampleMeasurements2.addRecord(0.375, 0.8190, 0.0800, 0.0800)
        sampleMeasurements2.addRecord(0.380, 0.8090, 0.0790, 0.0790)
        sampleMeasurements2.addRecord(0.385, 0.8290, 0.0800, 0.0800)
        sampleMeasurements2.addRecord(0.390, 0.8530, 0.0820, 0.0820)
        sampleMeasurements2.addRecord(0.395, 0.8680, 0.0830, 0.0830)
        sampleMeasurements2.addRecord(0.400, 0.8750, 0.0830, 0.0830)

        sampleMeasurements1.Filpped(true)
        self.m_MultiLayerOptics = CMultiPaneSampleData()
        self.m_MultiLayerOptics.addSample(sampleMeasurements1)
        self.m_MultiLayerOptics.addSample(sampleMeasurements2)

    def getMultiLayerOptics(self) -> CMultiPaneSampleData:
        return self.m_MultiLayerOptics

    def testDoublePaneResultsFlipped(self):
        print("Begin Test: Test simple double pane calculations - Flipped (T, Rf, Rb and equivalent absorptances).")
        var MultiLayerOptics: CMultiPaneSampleData = self.getMultiLayerOptics()
        var correctT: List[Float64] = List[Float64]()
        correctT.append(0.013746642)
        correctT.append(0.037747231)
        correctT.append(0.074892061)
        correctT.append(0.120904672)
        correctT.append(0.171335996)
        correctT.append(0.221613732)
        correctT.append(0.270116935)
        correctT.append(0.314191669)
        correctT.append(0.348200613)
        correctT.append(0.367178778)
        correctT.append(0.384178511)
        correctT.append(0.418109604)
        correctT.append(0.455044955)
        correctT.append(0.483744498)
        correctT.append(0.503708244)

        var transmittances: CSeries = MultiLayerOptics.properties(Property.T, Side.Front)
        assert len(transmittances) == len(correctT)
        for i in range(len(transmittances)):
            assert abs(correctT[i] - transmittances[i].value()) <= 1e-6

        var correctRf: List[Float64] = List[Float64]()
        correctRf.append(0.264931337)
        correctRf.append(0.267205274)
        correctRf.append(0.268408980)
        correctRf.append(0.270814345)
        correctRf.append(0.275068116)
        correctRf.append(0.280009069)
        correctRf.append(0.286253712)
        correctRf.append(0.292440237)
        correctRf.append(0.296883477)
        correctRf.append(0.299431278)
        correctRf.append(0.300223526)
        correctRf.append(0.301384529)
        correctRf.append(0.302973771)
        correctRf.append(0.303333016)
        correctRf.append(0.302600323)

        var Rf: CSeries = MultiLayerOptics.properties(Property.R, Side.Front)
        assert len(Rf) == len(correctRf)
        for i in range(len(Rf)):
            assert abs(correctRf[i] - Rf[i].value()) <= 1e-6

        var correctRb: List[Float64] = List[Float64]()
        correctRb.append(0.048437222)
        correctRb.append(0.055401452)
        correctRb.append(0.069785185)
        correctRb.append(0.089050784)
        correctRb.append(0.113880437)
        correctRb.append(0.139047720)
        correctRb.append(0.164761640)
        correctRb.append(0.188055460)
        correctRb.append(0.205519578)
        correctRb.append(0.211556230)
        correctRb.append(0.217000441)
        correctRb.append(0.237035991)
        correctRb.append(0.261267610)
        correctRb.append(0.279513243)
        correctRb.append(0.290533612)

        var Rb: CSeries = MultiLayerOptics.properties(Property.R, Side.Back)
        assert len(Rb) == len(correctRb)
        for i in range(len(Rb)):
            assert abs(correctRb[i] - Rb[i].value()) <= 1e-6

        var correctAbs: List[Float64] = List[Float64]()
        correctAbs.append(0.721322021)
        correctAbs.append(0.695047495)
        correctAbs.append(0.656698960)
        correctAbs.append(0.608280984)
        correctAbs.append(0.553595888)
        correctAbs.append(0.498377199)
        correctAbs.append(0.443629353)
        correctAbs.append(0.393368094)
        correctAbs.append(0.354915909)
        correctAbs.append(0.333389944)
        correctAbs.append(0.315597962)
        correctAbs.append(0.280505867)
        correctAbs.append(0.241981274)
        correctAbs.append(0.212922487)
        correctAbs.append(0.193691434)

        var Abs: CSeries = MultiLayerOptics.properties(Property.Abs, Side.Front)
        assert len(Abs) == len(correctAbs)
        for i in range(len(Abs)):
            assert abs(correctAbs[i] - Abs[i].value()) <= 1e-6

    def testDoublePaneAbsorptancesFlipped(self):
        print("Begin Test: Test layer absroptances - Flipped.")
        var MultiLayerOptics: CMultiPaneSampleData = self.getMultiLayerOptics()

        var correctAbs: List[Float64] = List[Float64]()
        correctAbs.append(0.653018396)
        correctAbs.append(0.610693989)
        correctAbs.append(0.569639081)
        correctAbs.append(0.528817136)
        correctAbs.append(0.487206381)
        correctAbs.append(0.444165237)
        correctAbs.append(0.399688515)
        correctAbs.append(0.355909720)
        correctAbs.append(0.318505509)
        correctAbs.append(0.288109045)
        correctAbs.append(0.262411321)
        correctAbs.append(0.234609638)
        correctAbs.append(0.207306101)
        correctAbs.append(0.185614330)
        correctAbs.append(0.169513438)

        var abs: CSeries = MultiLayerOptics.getLayerAbsorptances(1)
        assert len(abs) == len(correctAbs)
        for i in range(len(abs)):
            assert abs(correctAbs[i] - abs[i].value()) <= 1e-6

        correctAbs.clear()
        correctAbs.append(0.068303625)
        correctAbs.append(0.084353506)
        correctAbs.append(0.087059878)
        correctAbs.append(0.079463848)
        correctAbs.append(0.066389507)
        correctAbs.append(0.054211961)
        correctAbs.append(0.043940838)
        correctAbs.append(0.037458374)
        correctAbs.append(0.036410401)
        correctAbs.append(0.045280899)
        correctAbs.append(0.053186642)
        correctAbs.append(0.045896229)
        correctAbs.append(0.034675172)
        correctAbs.append(0.027308157)
        correctAbs.append(0.024177996)

        abs = MultiLayerOptics.getLayerAbsorptances(2)
        assert len(abs) == len(correctAbs)
        for i in range(len(abs)):
            assert abs(correctAbs[i] - abs[i].value()) <= 1e-6

def main():
    var test = TestMultiLayerOpticsMeasuredSampleDataFlipped()
    test.SetUp()
    test.testDoublePaneResultsFlipped()
    test.testDoublePaneAbsorptancesFlipped()
    print("All tests passed.")