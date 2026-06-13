from WCECommon import CWavelengthRange
from WavelengthSpectrum.hpp import generateSpectrum, generateISO9050Wavelengths

def generateSpectrum(numOfVisibleBands: size_t, numOfIRBands: size_t) -> std.vector[float64]:
    var result: std.vector[float64] = std.vector[float64]()
    var solarRange: CWavelengthRange = CWavelengthRange(WavelengthRange.Solar)
    var visRange: CWavelengthRange = CWavelengthRange(WavelengthRange.Visible)
    var deltaVis: float64 = (visRange.maxLambda() - visRange.minLambda()) / numOfVisibleBands
    var deltaSolar: float64 = (solarRange.maxLambda() - visRange.maxLambda()) / numOfIRBands
    result.emplace_back(solarRange.minLambda())
    for i in range(0, numOfVisibleBands):
        result.emplace_back(visRange.minLambda() + i * deltaVis)
    for i in range(0, numOfIRBands):
        result.emplace_back(visRange.maxLambda() + i * deltaSolar)
    result.emplace_back(solarRange.maxLambda())
    return result

def generateISO9050Wavelengths() -> std.vector[float64]:
    return std.vector[float64](
          0.300,  0.305,  0.310,  0.315,  0.320,  0.325,  0.330,  0.335,  0.340,  0.345,  0.350,
          0.355,  0.360,  0.365,  0.370,  0.375,  0.380,  0.385,  0.390,  0.395,  0.400,  0.410,
          0.420,  0.430,  0.440,  0.450,  0.460,  0.470,  0.480,  0.490,  0.500,  0.510,  0.520,
          0.530,  0.540,  0.550,  0.560,  0.570,  0.580,  0.590,  0.600,  0.610,  0.620,  0.630,
          0.640,  0.650,  0.660,  0.670,  0.680,  0.690,  0.700,  0.710,  0.720,  0.730,  0.740,
          0.750,  0.760,  0.770,  0.780,  0.790,  0.800,  0.850,  0.900,  0.950,  1.000,  1.050,
          1.100,  1.150,  1.200,  1.250,  1.300,  1.350,  1.400,  1.450,  1.500,  1.550,  1.600,
          1.650,  1.700,  1.750,  1.800,  1.850,  1.900,  1.950,  2.000,  2.050,  2.100,  2.150,
          2.200,  2.250,  2.300,  2.350,  2.400,  2.450,  2.500,  5.000,  6.000,  7.000,  8.000,
          9.000,  10.000, 11.000, 12.000, 13.000, 14.000, 15.000, 16.000, 17.000, 18.000, 19.000,
          20.000, 21.000, 22.000, 23.000, 24.000, 25.000, 26.000, 27.000, 28.000, 29.000, 30.000,
          31.000, 32.000, 33.000, 34.000, 35.000, 36.000, 37.000, 38.000, 39.000, 40.000)