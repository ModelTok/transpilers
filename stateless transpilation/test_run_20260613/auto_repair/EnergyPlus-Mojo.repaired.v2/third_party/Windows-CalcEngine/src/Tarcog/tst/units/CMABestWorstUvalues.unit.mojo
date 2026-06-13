# Translated from C++ (CMABestWorstUvalues.unit.cpp)
# Includes memory, stdexcept, gtest, WCETarcog.hpp dropped (Mojo equivalents used)

from testing import assert_approx_equal
from ...WCETarcog import CMA

struct TestCMABestWorstUvalues:

def TestCMABestWorstUvalues_TestBestIGUUValue_Test():
    # SCOPED_TRACE("Begin Test: Test CMA Best Worst IGU U-value calculations")
    var best = CMA.CreateBestWorstUFactorOption(CMA.Option.Best)
    let uValue = best.uValue()
    let correctUValue = 0.454198
    assert_approx_equal(uValue, correctUValue, 1e-5)

def TestCMABestWorstUvalues_TestWorstIGUUValue_Test():
    # SCOPED_TRACE("Begin Test: Test CMA Best Worst IGU U-value calculations")
    var worst = CMA.CreateBestWorstUFactorOption(CMA.Option.Worst)
    let uValue = worst.uValue()
    let correctUValue = 2.839511
    assert_approx_equal(uValue, correctUValue, 1e-5)