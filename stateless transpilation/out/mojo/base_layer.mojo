// EXTERNAL DEPS (to wire in glue):
// - LayerInterfaces (from wherever it comes from)

import math

struct CLayerGeometry {}
struct CLayerHeatFlow {}
struct CState {}

struct FenestrationCommon {
    enum class Side {}
}

struct Tarcog {
    struct ISO15099 {
        struct CBaseLayer: CLayerGeometry, CLayerHeatFlow {
            var m_PreviousLayer: Optional[CBaseLayer] = None
            var m_NextLayer: Optional[CBaseLayer] = None

            fn getPreviousLayer(self) -> Optional[CBaseLayer] {
                return self.m_PreviousLayer
            }

            fn getNextLayer(self) -> Optional[CBaseLayer] {
                return self.m_NextLayer
            }

            fn connectToBackSide(self, t_Layer: CBaseLayer) {
                self.m_NextLayer = t_Layer
                t_Layer.m_PreviousLayer = self
            }

            fn tearDownConnections(self) {
                self.m_PreviousLayer = None
                self.m_NextLayer = None
            }

            fn calculateRadiationFlow(self) {
                // Implementation goes here
            }

            fn getThickness(self) -> Float64 {
                return 0.0
            }

            fn isPermeable(self) -> Bool {
                return false
            }

            fn clone(self) -> CBaseLayer {
                // Implementation goes here
                unimplemented()
            }

            fn calculateConvectionOrConductionFlow(self) {
                // Implementation goes here
                unimplemented()
            }
        }
    }
}
