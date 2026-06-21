# Verified C++->Mojo handoff for epmojo-agent (member-access lever)
# Source: EnergyPlus DataSizing.{hh,cc} TermUnitSizingData (4 self-contained methods)
# this->field reads -> self.field; struct-attach (main 9c54071).
# Oracle-verified vs g++: coolFlow(10,8)=3.8 heatFlow(12,9)=6.3 coolLoad(1000)=800 heatLoad(1000)=900 (rel<1e-9).

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
        return coolFlowNoOA * coolFlowRatio + (coolFlowWithOA - coolFlowNoOA) * self.SpecMinOAFrac

    def applyTermUnitSizingHeatFlow(self, heatFlowWithOA: Float64, heatFlowNoOA: Float64) -> Float64:
        var heatFlowRatio: Float64 = 1.0
        if self.SpecDesHeatSATRatio > 0.0:
            heatFlowRatio = self.SpecDesSensHeatingFrac / self.SpecDesHeatSATRatio
        else:
            heatFlowRatio = self.SpecDesSensHeatingFrac
        return heatFlowNoOA * heatFlowRatio + (heatFlowWithOA - heatFlowNoOA) * self.SpecMinOAFrac

    def applyTermUnitSizingCoolLoad(self, coolLoad: Float64) -> Float64:
        return coolLoad * self.SpecDesSensCoolingFrac

    def applyTermUnitSizingHeatLoad(self, heatLoad: Float64) -> Float64:
        return heatLoad * self.SpecDesSensHeatingFrac
