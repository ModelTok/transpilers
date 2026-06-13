from .. import Tarcog.ISO15099.FrameData  # Placeholder - adjust path
from .. import CMA.CMAFrame, CMA.CMAWindowSingleVision  # Placeholder - adjust path

# Helper for approximate equality
def assert_approx_equal(actual: Float64, expected: Float64, tolerance: Float64):
    assert(abs(actual - expected) < tolerance, "Value " + str(actual) + " not near " + str(expected))

struct TestCMASingleVisionWindow:
    def SetUp(inout self):

    def CMASingleVision(inout self):
        # SCOPED_TRACE("Begin Test: CMA test for single vision window.")
        print("Begin Test: CMA test for single vision window.")
        let frameDataBestBestHead = Tarcog.ISO15099.FrameData(
            1.306919, 0.794668, 0.042875183, 0.110605026
        )
        let frameDataBestWorstHead = Tarcog.ISO15099.FrameData(
            1.65724, 2.71409, 0.042875183, 0.110605026
        )
        let frameDataWorstBestHead = Tarcog.ISO15099.FrameData(
            2.27964, 1.65214, 0.042875183, 0.110605026
        )
        let frameDataWorstWorstHead = Tarcog.ISO15099.FrameData(
            2.32377, 3.19643, 0.042875183, 0.110605026
        )
        let cmaFrameHead = CMA.CMAFrame(
            frameDataBestBestHead,
            frameDataBestWorstHead,
            frameDataWorstBestHead,
            frameDataWorstWorstHead
        )
        let frameDataBestBestJamb = Tarcog.ISO15099.FrameData(
            1.25968, 0.76981, 0.042875183, 0.110605026
        )
        let frameDataBestWorstJamb = Tarcog.ISO15099.FrameData(
            1.62145, 2.70202, 0.042875183, 0.110605026
        )
        let frameDataWorstBestJamb = Tarcog.ISO15099.FrameData(
            2.26579, 1.64520, 0.042875183, 0.110605026
        )
        let frameDataWorstWorstJamb = Tarcog.ISO15099.FrameData(
            2.30879, 3.18888, 0.042875183, 0.110605026
        )
        let cmaFrameJamb = CMA.CMAFrame(
            frameDataBestBestJamb,
            frameDataBestWorstJamb,
            frameDataWorstBestJamb,
            frameDataWorstWorstJamb
        )
        let frameDataBestBestSill = Tarcog.ISO15099.FrameData(
            1.30474, 0.79449, 0.042875183, 0.110605026
        )
        let frameDataBestWorstSill = Tarcog.ISO15099.FrameData(
            1.64813, 2.71240, 0.042875183, 0.110605026
        )
        let frameDataWorstBestSill = Tarcog.ISO15099.FrameData(
            2.27038, 1.64528, 0.042875183, 0.110605026
        )
        let frameDataWorstWorstSill = Tarcog.ISO15099.FrameData(
            2.31302, 3.18880, 0.042875183, 0.110605026
        )
        let cmaFrameSill = CMA.CMAFrame(
            frameDataBestBestSill,
            frameDataBestWorstSill,
            frameDataWorstBestSill,
            frameDataWorstWorstSill
        )
        let width = 1.2
        let height = 1.5
        var window = CMA.CMAWindowSingleVision(width, height)
        window.setFrameTop(cmaFrameHead)
        window.setFrameBottom(cmaFrameSill)
        window.setFrameLeft(cmaFrameJamb)
        window.setFrameRight(cmaFrameJamb)
        let UvalueCOG = 1.258
        let SHGCCOG = 0.341
        let tVis = 0.535
        let spacerKeff = 0.750454253
        let vt = window.vt(tVis)
        assert_approx_equal(0.468371, vt, 1e-6)
        let uvalue = window.uValue(UvalueCOG, spacerKeff)
        assert_approx_equal(1.451714, uvalue, 1e-6)
        let windowSHGC = window.shgc(SHGCCOG, spacerKeff)
        assert_approx_equal(0.299620, windowSHGC, 1e-6)
        let iguDimensions = window.getIGUDimensions()
        assert_approx_equal(1.114250, iguDimensions.width, 1e-6)
        assert_approx_equal(1.414250, iguDimensions.height, 1e-6)

def main():
    let test = TestCMASingleVisionWindow()
    test.CMASingleVision()