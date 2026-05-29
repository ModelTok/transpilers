# Auto-transpiled EnergyPlus numeric kernels (C++ -> Mojo via transpilers).
# Pure functions only; state-coupled code is hand-ported separately.

# from WindowManager.cc: InterpolateBetweenTwoValues
def InterpolateBetweenTwoValues(X: Float64, X0: Float64, X1: Float64, F0: Float64, F1: Float64) -> Float64:
    var InterpResult: Float64 = 0
    InterpResult = F0 + (X - X0) / (X1 - X0) * (F1 - F0)
    return InterpResult

# from WindowManager.cc: InterpolateBetweenFourValues
def InterpolateBetweenFourValues(X: Float64, Y: Float64, X1: Float64, X2: Float64, Y1: Float64, Y2: Float64, Fx1y1: Float64, Fx1y2: Float64, Fx2y1: Float64, Fx2y2: Float64) -> Float64:
    var InterpResult: Float64 = 0
    InterpResult = Fx1y1 / ((X2 - X1) * (Y2 - Y1)) * (X2 - X) * (Y2 - Y) + Fx2y1 / ((X2 - X1) * (Y2 - Y1)) * (X - X1) * (Y2 - Y) + Fx1y2 / ((X2 - X1) * (Y2 - Y1)) * (X2 - X) * (Y - Y1) + Fx2y2 / ((X2 - X1) * (Y2 - Y1)) * (X - X1) * (Y - Y1)
    return InterpResult
