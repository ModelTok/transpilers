# Verified C++->Mojo handoff for epmojo-agent (member-access lever)
# Source: EnergyPlus DataSizing.cc TermUnitSizingData::applyTermUnitSizing{Cool,Heat}Flow
# this->field reads; transpiled with struct in-context (attach-to-struct, main 9c54071).
# Oracle-verified vs g++: cool(10,8)=3.8, heat(12,9)=6.3 (rel<1e-9).

@fieldwise_init
struct TermUnitSizingData(Copyable, Movable):
    var SpecDesSensCoolingFrac: Float64
    var SpecDesCoolSATRatio: Float64
    var SpecDesSensHeatingFrac: Float64
    var SpecDesHeatSATRatio: Float64
    var SpecMinOAFrac: Float64

    def applyTermUnitSizingCoolFlow(self, coolFlowWithOA: Float64, coolFlowNoOA: Float64) -> Float64:
        var coolFlowRatio: Float64 = 1.0
        if self.SpecDesCoolSATRatio > 0.0:
            coolFlowRatio = self.SpecDesSensCoolingFrac / self.SpecDesCoolSATRatio
        else:
            coolFlowRatio = self.SpecDesSensCoolingFrac
        var adjustedFlow: Float64 = coolFlowNoOA * coolFlowRatio + (coolFlowWithOA - coolFlowNoOA) * self.SpecMinOAFrac
        return adjustedFlow

    def applyTermUnitSizingHeatFlow(self, heatFlowWithOA: Float64, heatFlowNoOA: Float64) -> Float64:
        var heatFlowRatio: Float64 = 1.0
        if self.SpecDesHeatSATRatio > 0.0:
            heatFlowRatio = self.SpecDesSensHeatingFrac / self.SpecDesHeatSATRatio
        else:
            heatFlowRatio = self.SpecDesSensHeatingFrac
        var adjustedFlow: Float64 = heatFlowNoOA * heatFlowRatio + (heatFlowWithOA - heatFlowNoOA) * self.SpecMinOAFrac
        return adjustedFlow
