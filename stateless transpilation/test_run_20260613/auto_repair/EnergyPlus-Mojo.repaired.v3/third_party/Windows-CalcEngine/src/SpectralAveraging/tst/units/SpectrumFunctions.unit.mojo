from testing import test, assert_eq, assert_almost_eq
import "../../SpectralAveraging" as SpectralAveraging

struct TestSpectrumFunctions:
    var inputVector: List[Float64]

    def __init__(inout self):
        self.inputVector = List[Float64]()

    def SetUp(inout self):
        self.inputVector = List[Float64](0.1, 0.2, 0.3, 0.4, 0.5)

    def getInputVector(self) -> List[Float64]:
        return self.inputVector

@test
def TestRatio() raises:
    # SCOPED_TRACE("Begin Test: Test UV Function.")
    var test = TestSpectrumFunctions()
    test.SetUp()
    var vector = test.getInputVector()
    var results = SpectralAveraging.UVAction(vector)
    var correctResults = List[(Float64, Float64)](
        (0.1, 11.02317638), (0.2, 3.320116923), (0.3, 1.0), (0.4, 0.301194212), (0.5, 0.090717953)
    )
    assert_eq(correctResults.size, results.size)
    for i in range(correctResults.size):
        assert_almost_eq(correctResults[i][0], results[i][0], 1e-6)
        assert_almost_eq(correctResults[i][1], results[i][1], 1e-6)

@test
def TestUVKrochmann() raises:
    # SCOPED_TRACE("Begin Test: Test UV Krochmann.")
    var test = TestSpectrumFunctions()
    test.SetUp()
    var vector = test.getInputVector()
    var results = SpectralAveraging.Krochmann(vector)
    var correctResults = List[(Float64, Float64)](
        (0.1, 16713.967064), (0.2, 1297.247512), (0.3, 100.6853190), (0.4, 7.814648615), (0.5, 0.606530660)
    )
    assert_eq(correctResults.size, results.size)
    for i in range(correctResults.size):
        assert_almost_eq(correctResults[i][0], results[i][0], 1e-6)
        assert_almost_eq(correctResults[i][1], results[i][1], 1e-6)

@test
def TestBlackBody() raises:
    # SCOPED_TRACE("Begin Test: Test BlackBody.")
    var vector = List[Float64](5.0, 5.1, 5.2, 5.3, 5.4)
    var BlackBodyTemperature = 300.0
    var results = SpectralAveraging.BlackBodySpectrum(vector, BlackBodyTemperature)
    var correctResults = List[(Float64, Float64)](
        (5.0, 1.090913e-10), (5.1, 1.192546e-10), (5.2, 1.296744e-10), (5.3, 1.403053e-10), (5.4, 1.511017e-10)
    )
    assert_eq(correctResults.size, results.size)
    for i in range(correctResults.size):
        assert_almost_eq(correctResults[i][0], results[i][0], 1e-16)
        assert_almost_eq(correctResults[i][1], results[i][1], 1e-16)