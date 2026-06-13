/* Copyright (c) 2017 Big Ladder Software LLC. All rights reserved.
 * See the LICENSE file for additional terms and conditions. */
from glad import GLuint, GLenum, GLint, GLsizei, GLchar, glCreateShader, glShaderSource, glCompileShader, glGetShaderiv, glGetShaderInfoLog, glDeleteShader, GL_COMPILE_STATUS, GL_TRUE, GL_FRAGMENT_SHADER
from courierr.courierr import Courierr
from penumbra.logging import PenumbraException
from fmt import format as fmt_format
from builtin import Pointer, StaticArray

@value
struct GLShader:
    var shader: GLuint
    var logger: Pointer[Courierr]

    def __init__(inout self, type: GLenum, source: Pointer[UInt8], logger_in: Pointer[Courierr]):
        self.logger = logger_in
        var shader_ok: GLint
        var log_length: GLsizei
        var info_log: StaticArray[UInt8, 8192]
        self.shader = glCreateShader(type)
        if self.shader != 0:
            var src_ptr: Pointer[GLchar] = source.bitcast[GLchar]()
            var src_ptr_ptr: Pointer[Pointer[GLchar]] = Pointer[Pointer[GLchar]].address_of(src_ptr)
            glShaderSource(self.shader, 1, src_ptr_ptr, Pointer[GLint].null())
            glCompileShader(self.shader)
            glGetShaderiv(self.shader, GL_COMPILE_STATUS, Pointer[GLint].address_of(shader_ok))
            if shader_ok != GL_TRUE:
                glGetShaderInfoLog(self.shader, 8192, Pointer[GLsizei].address_of(log_length), Pointer[GLchar](info_log.data))
                glDeleteShader(self.shader)
                self.shader = 0
                var shader_type_string: String = "fragment" if type == GL_FRAGMENT_SHADER else "vertex"
                self.logger[].info(fmt_format("OpenGL {} shader: {}", shader_type_string, String(info_log.data)))
                raise PenumbraException(fmt_format("Unable to compile {} shader.", shader_type_string), self.logger[])

    def get(self) -> GLuint:
        return self.shader