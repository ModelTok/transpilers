/* Copyright (c) 2017 Big Ladder Software LLC. All rights reserved.
 * See the LICENSE file for additional terms and conditions. */

from algorithm import sort
from model import SurfaceBuffer, GLModel
from external.ffi import *

# OpenGL constants
alias GL_TRIANGLES = 0x0004
alias GL_ARRAY_BUFFER = 0x8892
alias GL_STATIC_DRAW = 0x88E4
alias GL_FLOAT = 0x1406
alias GL_FALSE = 0

# OpenGL function declarations (simplified FFI)
def glGenVertexArrays(n: UInt32, arrays: Pointer[UInt32]): ...
def glBindVertexArray(array: UInt32): ...
def glDeleteVertexArrays(n: UInt32, arrays: Pointer[UInt32]): ...
def glGenBuffers(n: UInt32, buffers: Pointer[UInt32]): ...
def glBindBuffer(target: UInt32, buffer: UInt32): ...
def glBufferData(target: UInt32, size: Int, data: Pointer[UInt8], usage: UInt32): ...
def glEnableVertexAttribArray(index: UInt32): ...
def glVertexAttribPointer(index: UInt32, size: Int, type: UInt32, normalized: UInt8, stride: Int, pointer: Pointer[UInt8]): ...
def glDrawArrays(mode: UInt32, first: Int, count: Int): ...
def glDeleteBuffers(n: UInt32, buffers: Pointer[UInt32]): ...

# Platform-specific macros
alias glGenVertexArraysX = glGenVertexArrays
alias glBindVertexArrayX = glBindVertexArray
alias glDeleteVertexArraysX = glDeleteVertexArrays

struct SurfaceBuffer:
    var begin: UInt32
    var count: UInt32
    var index: Int32

    def __init__(inout self, begin: UInt32 = 0, count: UInt32 = 0, index: Int32 = -1):
        self.begin = begin
        self.count = count
        self.index = index

struct GLModel:
    var vertex_array: List[Float32]
    var surface_buffers: List[SurfaceBuffer]
    var number_of_points: UInt32
    var vertex_buffer_object: UInt32
    var vertex_array_object: UInt32
    var objects_set: Bool

    alias vertex_size: Int32 = 3

    def __init__(inout self):
        self.vertex_array = List[Float32]()
        self.surface_buffers = List[SurfaceBuffer]()
        self.number_of_points = 0
        self.vertex_buffer_object = 0
        self.vertex_array_object = 0
        self.objects_set = False

    def __del__(inout self):

    def clear_model(inout self):
        if self.objects_set:
            glDeleteVertexArraysX(1, Pointer[UInt32].address_of(self.vertex_array_object))
            glDeleteBuffers(1, Pointer[UInt32].address_of(self.vertex_buffer_object))
        self.surface_buffers.clear()

    def set_vertices(inout self, vertices: List[Float32]):
        self.vertex_array = vertices
        self.number_of_points = UInt32(vertices.size) // GLModel.vertex_size
        glGenVertexArraysX(1, Pointer[UInt32].address_of(self.vertex_array_object))
        glBindVertexArrayX(self.vertex_array_object)
        glGenBuffers(1, Pointer[UInt32].address_of(self.vertex_buffer_object))
        glBindBuffer(GL_ARRAY_BUFFER, self.vertex_buffer_object)
        glBufferData(GL_ARRAY_BUFFER, Int(sizeof[Float32]() * vertices.size), Pointer[UInt8](vertices.data), GL_STATIC_DRAW)
        glEnableVertexAttribArray(0)
        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, sizeof[Float32]() * 3, Pointer[UInt8]())
        self.objects_set = True

    def set_surface_buffers(inout self, surface_buffers_in: List[SurfaceBuffer]):
        self.surface_buffers = surface_buffers_in

    @staticmethod
    def draw_surface(surface_buffer: SurfaceBuffer):
        glDrawArrays(GL_TRIANGLES, Int(surface_buffer.begin), Int(surface_buffer.count))

    def draw_all(self):
        glDrawArrays(GL_TRIANGLES, 0, Int(self.number_of_points))

    def draw_except(self, hidden_surfaces: List[SurfaceBuffer]):
        if hidden_surfaces.size == 0: # draw all if no hidden surfaces
            self.draw_all()
            return
        sort(
            hidden_surfaces,
            lambda a: SurfaceBuffer, b: SurfaceBuffer -> Bool: return a.begin > b.begin
        )
        if hidden_surfaces[0].begin != 0:
            glDrawArrays(GL_TRIANGLES, 0, Int(hidden_surfaces[0].begin))
        var nextBegin: UInt32 = hidden_surfaces[0].begin + hidden_surfaces[0].count
        for i in range(1, hidden_surfaces.size):
            if nextBegin == self.number_of_points:
                return
            if nextBegin == hidden_surfaces[i].begin:
                nextBegin = hidden_surfaces[i].begin + hidden_surfaces[i].count
                break
            glDrawArrays(GL_TRIANGLES, Int(nextBegin), Int(hidden_surfaces[i + 1].begin - 1))
        if nextBegin < self.number_of_points:
            glDrawArrays(GL_TRIANGLES, Int(nextBegin), Int(self.number_of_points - nextBegin))