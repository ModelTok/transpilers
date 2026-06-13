/* Copyright (c) 2012-2022 Big Ladder Software LLC. All rights reserved.
 * See the LICENSE file for additional terms and conditions. */
from Instance import Instance
from Ground import Ground, GroundOutput
from Foundation import Foundation
from BoundaryConditions import BoundaryConditions
from Surface import Surface
from Polygon import isConvex
from memory import shared_ptr, make_shared

@value
struct Instance:
    var ground: shared_ptr[Ground]
    var foundation: shared_ptr[Foundation]
    var bcs: shared_ptr[BoundaryConditions]

    def __init__(inout self):

    def __init__(inout self, fnd: Foundation):
        self.foundation = make_shared[Foundation](fnd)
        self.create()

    def create(inout self):
        var outputMap = GroundOutput.OutputMap()
        outputMap.append(Surface.ST_SLAB_CORE)
        if self.foundation.hasPerimeterSurface:
            outputMap.append(Surface.ST_SLAB_PERIM)
        if self.foundation.foundationDepth:
            outputMap.append(Surface.ST_WALL_INT)
        if not self.foundation.useDetailedExposedPerimeter or not isConvex(self.foundation.polygon) or self.foundation.exposedFraction == 0:
            if self.foundation.reductionStrategy == Foundation.RS_BOUNDARY:
                self.foundation.reductionStrategy = Foundation.RS_AP
        self.ground = make_shared[Ground](self.foundation[], outputMap)
        if self.foundation.reductionStrategy == Foundation.RS_BOUNDARY:
            self.ground.calculateBoundaryLayer()
            self.ground.setNewBoundaryGeometry()
        self.ground.buildDomain()

    def calculate(inout self, ts: Float64 = 0.0):
        self.ground.calculate(self.bcs[], ts)

    def calculate_surface_averages(inout self):
        self.ground.calculateSurfaceAverages()