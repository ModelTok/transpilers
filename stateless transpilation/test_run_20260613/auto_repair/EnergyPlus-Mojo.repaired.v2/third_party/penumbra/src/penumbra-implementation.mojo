/* Copyright (c) 2017 Big Ladder Software LLC. All rights reserved.
 * See the LICENSE file for additional terms and conditions. */
from memory import shared_ptr
from courierr.courierr import Courierr
from penumbra import Penumbra
from surface import Surface
from surface-implementation import SurfaceImplementation
from sun import Sun
from .gl.context import Context
from utils import fmt

struct PenumbraImplementation:
    var context: Context
    var sun: Sun
    var model: List[Float32]
    var surfaces: List[SurfaceImplementation]
    var logger: shared_ptr[Courierr]

    def __init__(inout self, size: Int, logger_in: shared_ptr[Courierr]):
        self.context = Context(size, logger_in.get())
        self.logger = logger_in

    def add_surface(inout self, surface: Surface):
        surface.surface.logger = self.logger
        if surface.surface.name == "":
            surface.surface.name = fmt.format("Surface {}", self.surfaces.size())
        self.surfaces.push_back(surface.surface[])

    def check_surface(self, surface_index: UInt, surface_context: String = "Surface") raises:
        if surface_index >= self.surfaces.size():
            raise SurfaceException(surface_index, surface_context, *(self.logger))