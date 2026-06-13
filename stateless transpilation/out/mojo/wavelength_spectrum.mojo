# EXTERNAL DEPS (to wire in glue):
# - WavelengthRange: from WCECommon (enum/constants with Solar, Visible)
# - CWavelengthRange: from WCECommon (struct, constructor(enum_val), max_lambda(), min_lambda())

from collections import List


struct WavelengthRange:
    """Stub: WavelengthRange from WCECommon."""
    alias Solar = 0
    alias Visible = 1


struct CWavelengthRange:
    """Stub: CWavelengthRange from WCECommon."""
    wavelength_range: Int

    fn __init__(inout self, wavelength_range: Int):
        self.wavelength_range = wavelength_range

    fn max_lambda(self) -> Float64:
        return 0.0

    fn min_lambda(self) -> Float64:
        return 0.0


fn generate_spectrum(num_of_visible_bands: Int, num_of_ir_bands: Int) -> List[Float64]:
    var result = List[Float64]()
    var solar_range = CWavelengthRange(WavelengthRange.Solar)
    var vis_range = CWavelengthRange(WavelengthRange.Visible)

    var delta_vis = (vis_range.max_lambda() - vis_range.min_lambda()) / Float64(num_of_visible_bands)
    var delta_solar = (solar_range.max_lambda() - vis_range.max_lambda()) / Float64(num_of_ir_bands)

    result.append(solar_range.min_lambda())

    for i in range(num_of_visible_bands):
        result.append(vis_range.min_lambda() + Float64(i) * delta_vis)

    for i in range(num_of_ir_bands):
        result.append(vis_range.max_lambda() + Float64(i) * delta_solar)

    result.append(solar_range.max_lambda())

    return result


fn generate_iso9050_wavelengths() -> List[Float64]:
    var result = List[Float64]()
    result.append(0.300)
    result.append(0.305)
    result.append(0.310)
    result.append(0.315)
    result.append(0.320)
    result.append(0.325)
    result.append(0.330)
    result.append(0.335)
    result.append(0.340)
    result.append(0.345)
    result.append(0.350)
    result.append(0.355)
    result.append(0.360)
    result.append(0.365)
    result.append(0.370)
    result.append(0.375)
    result.append(0.380)
    result.append(0.385)
    result.append(0.390)
    result.append(0.395)
    result.append(0.400)
    result.append(0.410)
    result.append(0.420)
    result.append(0.430)
    result.append(0.440)
    result.append(0.450)
    result.append(0.460)
    result.append(0.470)
    result.append(0.480)
    result.append(0.490)
    result.append(0.500)
    result.append(0.510)
    result.append(0.520)
    result.append(0.530)
    result.append(0.540)
    result.append(0.550)
    result.append(0.560)
    result.append(0.570)
    result.append(0.580)
    result.append(0.590)
    result.append(0.600)
    result.append(0.610)
    result.append(0.620)
    result.append(0.630)
    result.append(0.640)
    result.append(0.650)
    result.append(0.660)
    result.append(0.670)
    result.append(0.680)
    result.append(0.690)
    result.append(0.700)
    result.append(0.710)
    result.append(0.720)
    result.append(0.730)
    result.append(0.740)
    result.append(0.750)
    result.append(0.760)
    result.append(0.770)
    result.append(0.780)
    result.append(0.790)
    result.append(0.800)
    result.append(0.850)
    result.append(0.900)
    result.append(0.950)
    result.append(1.000)
    result.append(1.050)
    result.append(1.100)
    result.append(1.150)
    result.append(1.200)
    result.append(1.250)
    result.append(1.300)
    result.append(1.350)
    result.append(1.400)
    result.append(1.450)
    result.append(1.500)
    result.append(1.550)
    result.append(1.600)
    result.append(1.650)
    result.append(1.700)
    result.append(1.750)
    result.append(1.800)
    result.append(1.850)
    result.append(1.900)
    result.append(1.950)
    result.append(2.000)
    result.append(2.050)
    result.append(2.100)
    result.append(2.150)
    result.append(2.200)
    result.append(2.250)
    result.append(2.300)
    result.append(2.350)
    result.append(2.400)
    result.append(2.450)
    result.append(2.500)
    result.append(5.000)
    result.append(6.000)
    result.append(7.000)
    result.append(8.000)
    result.append(9.000)
    result.append(10.000)
    result.append(11.000)
    result.append(12.000)
    result.append(13.000)
    result.append(14.000)
    result.append(15.000)
    result.append(16.000)
    result.append(17.000)
    result.append(18.000)
    result.append(19.000)
    result.append(20.000)
    result.append(21.000)
    result.append(22.000)
    result.append(23.000)
    result.append(24.000)
    result.append(25.000)
    result.append(26.000)
    result.append(27.000)
    result.append(28.000)
    result.append(29.000)
    result.append(30.000)
    result.append(31.000)
    result.append(32.000)
    result.append(33.000)
    result.append(34.000)
    result.append(35.000)
    result.append(36.000)
    result.append(37.000)
    result.append(38.000)
    result.append(39.000)
    result.append(40.000)
    return result
