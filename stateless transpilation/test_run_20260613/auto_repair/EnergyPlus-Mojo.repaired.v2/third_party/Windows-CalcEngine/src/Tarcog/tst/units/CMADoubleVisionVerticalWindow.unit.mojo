from testing import *
from WCETarcog import Tarcog, CMA

@value
struct TestCMADoubleVisionVerticalWindow(Test):
    def setup(self) -> None:

    def test_CMADualVerticalVision(self) -> None:
        print("Begin Test: CMA test for double vision vertical window.")
        let frameDataBestBestHead = Tarcog.ISO15099.FrameData(1.306919, 0.794668, 0.042875183, 0.110605026)
        let frameDataBestWorstHead = Tarcog.ISO15099.FrameData(1.65724, 2.71409, 0.042875183, 0.110605026)
        let frameDataWorstBestHead = Tarcog.ISO15099.FrameData(2.27964, 1.65214, 0.042875183, 0.110605026)
        let frameDataWorstWorstHead = Tarcog.ISO15099.FrameData(2.32377, 3.19643, 0.042875183, 0.110605026)
        let cmaFrameHead = CMA.CMAFrame(frameDataBestBestHead, frameDataBestWorstHead, frameDataWorstBestHead, frameDataWorstWorstHead)

        let frameDataBestBestJamb = Tarcog.ISO15099.FrameData(1.25968, 0.76981, 0.042875183, 0.110605026)
        let frameDataBestWorstJamb = Tarcog.ISO15099.FrameData(1.62145, 2.70202, 0.042875183, 0.110605026)
        let frameDataWorstBestJamb = Tarcog.ISO15099.FrameData(2.26579, 1.64520, 0.042875183, 0.110605026)
        let frameDataWorstWorstJamb = Tarcog.ISO15099.FrameData(2.30879, 3.18888, 0.042875183, 0.110605026)
        let cmaFrameJamb = CMA.CMAFrame(frameDataBestBestJamb, frameDataBestWorstJamb, frameDataWorstBestJamb, frameDataWorstWorstJamb)

        let frameDataBestBestSill = Tarcog.ISO15099.FrameData(1.30474, 0.79449, 0.042875183, 0.110605026)
        let frameDataBestWorstSill = Tarcog.ISO15099.FrameData(1.64813, 2.71240, 0.042875183, 0.110605026)
        let frameDataWorstBestSill = Tarcog.ISO15099.FrameData(2.27038, 1.64528, 0.042875183, 0.110605026)
        let frameDataWorstWorstSill = Tarcog.ISO15099.FrameData(2.31302, 3.18880, 0.042875183, 0.110605026)
        let cmaFrameSill = CMA.CMAFrame(frameDataBestBestSill, frameDataBestWorstSill, frameDataWorstBestSill, frameDataWorstWorstSill)

        let width = 1.2
        let height = 1.5
        var window = CMA.CMAWindowDualVisionVertical(width, height)
        window.setFrameTop(cmaFrameHead)
        window.setFrameBottom(cmaFrameSill)
        window.setFrameTopLeft(cmaFrameJamb)
        window.setFrameTopRight(cmaFrameJamb)
        window.setFrameBottomLeft(cmaFrameJamb)
        window.setFrameBottomRight(cmaFrameJamb)
        window.setFrameMeetingRail(cmaFrameJamb)

        let UvalueCOG = 1.258
        let SHGCCOG = 0.341
        let tVis = 0.535
        let spacerKeff = 0.750454253
        let vt = window.vt(tVis)
        expect_near(0.454171, vt, 1e-6)
        let uvalue = window.uValue(UvalueCOG, spacerKeff)
        expect_near(1.511768, uvalue, 1e-6)
        let windowSHGC = window.shgc(SHGCCOG, spacerKeff)
        expect_near(0.290800, windowSHGC, 1e-6)
        let iguDimensions = window.getIGUDimensions()
        expect_near(1.114250, iguDimensions.width, 1e-6)
        expect_near(0.685687, iguDimensions.height, 1e-6)

def main() -> None:
    var test = TestCMADoubleVisionVerticalWindow()
    test.run()