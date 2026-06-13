/* Copyright (c) 2012-2022 Big Ladder Software LLC. All rights reserved.
 * See the LICENSE file for additional terms and conditions. */

from math import isfinite
from memory import Pointer
from Ground import Ground, Surface
from Errors import showMessage
from Foundation import isEqual

struct Aggregator:
    struct Results:
        var hconv: Float64
        var hrad: Float64
        var qtot: Float64
        var qconv: Float64
        var qrad: Float64
        var Tconv: Float64
        var Tavg: Float64
        var Trad: Float64

        def reset(inout self):
            self.hconv = 0.0
            self.hrad = 0.0
            self.qtot = 0.0
            self.qconv = 0.0
            self.qrad = 0.0
            self.Tconv = 0.0
            self.Tavg = 0.0
            self.Trad = 0.0

    var instances: List[Tuple[Pointer[Ground], Float64]]
    var surface_type: Surface.SurfaceType
    var surface_type_set: Bool
    var validated: Bool
    var results: Results

    def __init__(inout self):
        self.surface_type_set = False
        self.validated = False
        self.instances = List[Tuple[Pointer[Ground], Float64]]()
        self.results = Results()

    def __init__(inout self, st: Surface.SurfaceType):
        self.surface_type = st
        self.surface_type_set = True
        self.validated = False
        self.instances = List[Tuple[Pointer[Ground], Float64]]()
        self.results = Results()

    def add_instance(inout self, st: Surface.SurfaceType, grnd: Pointer[Ground], weight: Float64):
        if not self.surface_type_set:
            self.surface_type = st
        elif st != self.surface_type:
            showMessage(MSG_ERR, "Inconsistent surface type added to aggregator.")
        self.add_instance(grnd, weight)

    def add_instance(inout self, grnd: Pointer[Ground], weight: Float64):
        self.instances.append((grnd, weight))

    def size(self) -> Int:
        return len(self.instances)

    def validate(inout self):
        var check_weights: Float64 = 0.0
        for var instance in self.instances:
            var grnd = instance[0]
            check_weights += instance[1]
            if not grnd[].foundation.hasSurface[self.surface_type]:
                showMessage(MSG_ERR,
                    "Aggregation requested for surface that is not part of foundation instance.")
        if not isEqual(check_weights, 1.0):
            if isEqual(check_weights, 1.0, 0.01):
                showMessage(MSG_WARN,
                    "The weights of associated Kiva instances do not quite add to unity--check "
                    "exposed perimeter values. Weights will be slightly modified to add to unity.")
                for var instance in self.instances:
                    instance[1] /= check_weights
            else:
                showMessage(MSG_ERR, "The weights of associated Kiva instances do not add to unity--check "
                    "exposed perimeter values.")
        self.validated = True

    def calc_weighted_results(inout self):
        if not self.validated:
            self.validate()
        self.results.reset()
        var Tz: Float64 = 293.15
        var Tr: Float64 = 293.15
        for var instance in self.instances:
            var grnd = instance[0]
            Tz = self.surface_type == Surface.ST_WALL_INT ? grnd[].bcs.wallConvectiveTemp : grnd[].bcs.slabConvectiveTemp
            Tr = self.surface_type == Surface.ST_WALL_INT ? grnd[].bcs.wallRadiantTemp : grnd[].bcs.slabRadiantTemp
            var p = instance[1]
            var hci = grnd[].getSurfaceAverageValue({self.surface_type, Kiva.GroundOutput.OT_CONV})
            var hri = grnd[].getSurfaceAverageValue({self.surface_type, Kiva.GroundOutput.OT_RAD})
            var Ts = grnd[].getSurfaceAverageValue({self.surface_type, Kiva.GroundOutput.OT_TEMP})
            var Ta = grnd[].getSurfaceAverageValue({self.surface_type, Kiva.GroundOutput.OT_AVG_TEMP})
            var qi = -grnd[].getSurfaceAverageValue({self.surface_type, Kiva.GroundOutput.OT_FLUX})
            if not isfinite(Ts):
                showMessage(MSG_ERR, "Kiva is not giving realistic results!")
            self.results.qconv += p * hci * (Tz - Ts)
            self.results.qrad += p * hri * (Tr - Ts)
            self.results.qtot += p * qi
            self.results.hconv += p * hci
            self.results.hrad += p * hri
            self.results.Tavg += p * Ta
        self.results.Tconv = 0.0 if self.results.hconv == 0 else Tz - self.results.qconv / self.results.hconv
        self.results.Trad = 0.0 if self.results.hrad == 0 else Tr - self.results.qrad / self.results.hrad
        return

    def get_instance(self, index: Int) -> Tuple[Pointer[Ground], Float64]:
        return self.instances[index]