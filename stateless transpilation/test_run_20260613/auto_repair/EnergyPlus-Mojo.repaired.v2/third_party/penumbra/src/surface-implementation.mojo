# Copyright (c) 2017 Big Ladder Software LLC. All rights reserved.
# See the LICENSE file for additional terms and conditions.

from surface import Polygon
from penumbra.logging import PenumbraException
from tesselator import (
    TESStesselator,
    tessNewTess,
    tessAddContour,
    tessTesselate,
    tessGetVertices,
    tessGetElementCount,
    tessGetElements,
    tessDeleteTess,
    TESSreal,
    TESSindex,
    TESS_WINDING_ODD,
    TESS_POLYGONS,
)
from courierr.courierr import Courierr
from fmt import format

module Penumbra:

    struct TessData:
        alias polygon_size: Int = 3   # making triangles
        alias vertex_size: Int = 3    # i.e., 3D

        var vertices: List[Float32]
        var number_of_vertices: UInt32

        def __init__(inout self, array: Pointer[Float32], number_of_vertices: UInt32):
            self.number_of_vertices = number_of_vertices
            self.vertices = List[Float32]()
            for i in range(number_of_vertices):
                self.vertices.append(array[i])

    @dynamic
    class SurfaceImplementation:
        var polygon: Polygon
        var holes: List[Polygon]
        var logger: Pointer[Courierr]
        var name: String

        def __init__(inout self):

        def __init__(inout self, polygon: Polygon):
            self.polygon = polygon

        def tessellate(self) -> TessData:
            var tess: Pointer[TESStesselator] = tessNewTess(None)
            if tess.is_null():
                raise PenumbraException(
                    format("Unable to create tessellator for surface, \"{}\".", self.name),
                    self.logger,
                )
            tessAddContour(
                tess,
                TessData.polygon_size,
                self.polygon.data,   # assumes Polygon has .data member (Pointer[Float32])
                sizeof[Float32]() * TessData.vertex_size,
                Int(len(self.polygon)) // TessData.vertex_size,
            )
            for hole in self.holes:
                tessAddContour(
                    tess,
                    TessData.polygon_size,
                    hole.data,
                    sizeof[Float32]() * TessData.vertex_size,
                    Int(len(hole)) // TessData.vertex_size,
                )
            if not tessTesselate(
                tess,
                TESS_WINDING_ODD,
                TESS_POLYGONS,
                TessData.polygon_size,
                TessData.vertex_size,
                None,
            ):
                raise PenumbraException(
                    format("Unable to tessellate surface, \"{}\".", self.name),
                    self.logger,
                )
            var vertex_array: List[Float32] = List[Float32]()
            var vertices: Pointer[TESSreal] = tessGetVertices(tess)
            var number_of_elements: Int = tessGetElementCount(tess)
            var elements: Pointer[TESSindex] = tessGetElements(tess)
            for i in range(number_of_elements * TessData.polygon_size):
                var vertex: Int = elements[i]
                for j in range(TessData.vertex_size):
                    vertex_array.append(vertices[vertex * TessData.vertex_size + j])
            var data: TessData = TessData(vertex_array.data, UInt32(len(vertex_array)))
            tessDeleteTess(tess)
            return data