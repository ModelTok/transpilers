# Auto-transpiled EnergyPlus numeric kernels (C++ -> Mojo via transpilers).
# Pure functions only; state-coupled code is hand-ported separately.

# from FluidProperties.hh: GetInterpValue
def GetInterpValue(Tact: Float64, Tlo: Float64, Thi: Float64, Xlo: Float64, Xhi: Float64) -> Float64:
    return Xhi - (Thi - Tact) / (Thi - Tlo) * (Xhi - Xlo)

# from FluidProperties.cc: GlycolTempToTempIndex
def GlycolTempToTempIndex(Temp: Float64) -> Int:
    return Int(Temp / 5.0) + (6 if Temp < 0.0 else 7)
