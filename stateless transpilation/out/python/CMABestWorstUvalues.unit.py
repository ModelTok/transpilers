# EXTERNAL DEPS (to wire in glue):
# CMA.CreateBestWorstUFactorOption - function from WCETarcog
# CMA.Option - class/enum from WCETarcog (with Best and Worst attributes)

from typing import Protocol

class UValueObject(Protocol):
    def uValue(self) -> float: ...

class Option:
    Best: int = 0
    Worst: int = 1

def CreateBestWorstUFactorOption(option: int) -> UValueObject:
    raise NotImplementedError("Import from WCETarcog")

class CMA:
    Option = Option
    CreateBestWorstUFactorOption = staticmethod(CreateBestWorstUFactorOption)

class TestCMABestWorstUvalues:
    def test_best_igu_uvalue(self) -> None:
        best = CMA.CreateBestWorstUFactorOption(CMA.Option.Best)
        uValue = best.uValue()
        correctUValue = 0.454198
        assert abs(correctUValue - uValue) <= 1e-5
    
    def test_worst_igu_uvalue(self) -> None:
        worst = CMA.CreateBestWorstUFactorOption(CMA.Option.Worst)
        uValue = worst.uValue()
        correctUValue = 2.839511
        assert abs(correctUValue - uValue) <= 1e-5
