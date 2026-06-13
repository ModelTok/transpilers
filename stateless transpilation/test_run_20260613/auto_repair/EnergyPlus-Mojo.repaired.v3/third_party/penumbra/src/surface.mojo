/* Copyright (c) 2017 Big Ladder Software LLC. All rights reserved.
 * See the LICENSE file for additional terms and conditions. */
from polygon import Polygon
from surface-implementation import SurfaceImplementation

module Penumbra:
    struct Surface:
        var surface: Ref[SurfaceImplementation]

        def __init__(inout self):
            self.surface = Ref[SurfaceImplementation]()

        def __init__(inout self, polygon: Polygon, name_in: String):
            self.surface = Ref[SurfaceImplementation](polygon)
            self.surface.name = name_in

        def __copyinit__(inout self, other: Self):
            self.surface = other.surface

        def __del__(owned self):

        def add_hole(inout self, hole: Polygon):
            self.surface.holes.append(hole)