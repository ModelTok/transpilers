module FenestrationCommon:

    enum WavelengthRange:
        IR
        Solar
        Visible

    struct WavelengthRangeData:
        var startLambda: Float64
        var endLambda: Float64

        def __init__(inout self, startLambda: Float64, endLambda: Float64):
            self.startLambda = startLambda
            self.endLambda = endLambda

    struct CWavelengthRange:
        var m_MinLambda: Float64
        var m_MaxLambda: Float64
        let m_WavelengthRange: Dict[WavelengthRange, WavelengthRangeData] = {
            WavelengthRange.IR: WavelengthRangeData(5.0, 100.0),
            WavelengthRange.Solar: WavelengthRangeData(0.3, 2.5),
            WavelengthRange.Visible: WavelengthRangeData(0.38, 0.78)
        }

        def __init__(inout self, t_Range: WavelengthRange):
            self.setWavelengthRange(t_Range)

        def minLambda(self) -> Float64:
            return self.m_MinLambda

        def maxLambda(self) -> Float64:
            return self.m_MaxLambda

        def setWavelengthRange(inout self, t_Range: WavelengthRange):
            let wRange = self.m_WavelengthRange[t_Range]
            self.m_MinLambda = wRange.startLambda
            self.m_MaxLambda = wRange.endLambda