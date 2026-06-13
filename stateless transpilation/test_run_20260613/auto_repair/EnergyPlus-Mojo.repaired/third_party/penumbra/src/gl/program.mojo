/* Copyright (c) 2017 Big Ladder Software LLC. All rights reserved.
 * See the LICENSE file for additional terms and conditions. */
from gl import glCreateProgram, glAttachShader, glLinkProgram, GLuint, GL_VERTEX_SHADER, GL_FRAGMENT_SHADER
from shader import GLShader
from courierr import Courierr

module Penumbra:
    struct GLProgram:
        var program: GLuint

        def __init__(inout self, vertex_source: Pointer[Int8], fragment_source: Pointer[Int8], logger: Pointer[Courierr]):
            self.program = glCreateProgram()
            var vertex = GLShader(GL_VERTEX_SHADER, vertex_source, logger)
            glAttachShader(self.program, vertex.get())
            if not fragment_source.is_null():
                var fragment = GLShader(GL_FRAGMENT_SHADER, fragment_source, logger)
                glAttachShader(self.program, fragment.get())
            glLinkProgram(self.program)

        def __del__(inout self):

        def get(self) -> GLuint:
            return self.program