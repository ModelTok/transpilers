# EXTERNAL DEPS (to wire in glue):
# CMA.CreateBestWorstUFactorOption - function from WCETarcog
# CMA.Option - struct from WCETarcog (with Best and Worst attributes)

trait UValueProvider:
    fn uValue(self) -> Float64: ...

struct Option:
    var Best: Int32
    var Worst: Int32

fn CreateBestWorstUFactorOption(option: Int32) -> UValueProvider:
    raise Error("Import from WCETarcog")

struct CMA:
    pass

struct TestCMABestWorstUvalues:
    fn test_best_igu_uvalue(self) -> None:
        var option = Option(Best=0, Worst=1)
        var best = CreateBestWorstUFactorOption(option.Best)
        var uValue = best.uValue()
        var correctUValue: Float64 = 0.454198
        assert abs(correctUValue - uValue) <= 1e-5
    
    fn test_worst_igu_uvalue(self) -> None:
        var option = Option(Best=0, Worst=1)
        var worst = CreateBestWorstUFactorOption(option.Worst)
        var uValue = worst.uValue()
        var correctUValue: Float64 = 2.839511
        assert abs(correctUValue - uValue) <= 1e-5
