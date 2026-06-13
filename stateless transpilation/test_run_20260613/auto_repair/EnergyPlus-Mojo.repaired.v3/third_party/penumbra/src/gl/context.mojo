/* Copyright (c) 2017 Big Ladder Software LLC. All rights reserved.
 * See the LICENSE file for additional terms and conditions. */

from penumbra.logging import PenumbraException
from context import Context, SurfaceBuffer, GLModel, GLProgram
from glad.glad import *
from GLFW.glfw3 import *
from courierr.courierr import Courierr
from linmath import *
from memory import memset, memcpy
from math import min, max
from sys import int_types
from utils import String

alias MAX_FLOAT = Float32.max

@value
struct glfw_logger:

var glfw_logger_ptr: Courierr? = None

def glfw_error_callback(error: Int32, description: Pointer[UInt8]):
    if glfw_logger_ptr:
        glfw_logger_ptr.info("GLFW message: " + String(description))

@value
struct Context:
    var window: GLFWwindow?
    var framebuffer_object: GLuint = 0
    var renderbuffer_object: GLuint = 0
    var render_vertex_shader_source: Pointer[UInt8] = "src"
    var render_fragment_shader_source: Pointer[UInt8] = "src"
    var calculation_vertex_shader_source: Pointer[UInt8] = "src"
    var size: GLint
    var model: GLModel
    var render_program: GLProgram?
    var calculation_program: GLProgram?
    var model_is_set: Bool = False
    var model_bounding_box: StaticMatrix[Float32, 8, 4] = StaticMatrix[Float32, 8, 4]()
    var projection: StaticMatrix[Float32, 4, 4] = StaticMatrix[Float32, 4, 4]()
    var view: StaticMatrix[Float32, 4, 4] = StaticMatrix[Float32, 4, 4]()
    var mvp: StaticMatrix[Float32, 4, 4] = StaticMatrix[Float32, 4, 4]()
    var camera_view: StaticMatrix[Float32, 4, 4] = StaticMatrix[Float32, 4, 4]()
    var mvp_location: GLint = 0
    var vertex_color_location: GLint = 0
    var is_wire_frame_mode: Bool = False
    var is_camera_mode: Bool = False
    var left: Float32 = 0.0
    var right: Float32 = 0.0
    var bottom: Float32 = 0.0
    var top: Float32 = 0.0
    var near_: Float32 = 0.0
    var far_: Float32 = 0.0
    var view_scale: Float32 = 1.0
    var previous_x_position: Float64 = 0.0
    var previous_y_position: Float64 = 0.0
    var camera_x_rotation_angle: Float32 = 0.0
    var camera_y_rotation_angle: Float32 = 0.0
    var left_mouse_button_pressed: Bool = True
    var queries: List[GLuint]
    var pixel_areas: List[Float32]
    var pixel_counts: List[GLint]
    var logger: Courierr?

    def __init__(inout self, size_in: GLint, logger_in: Courierr):
        self.size = size_in
        self.logger = logger_in
        glfw_logger_ptr = logger_in
        glfwSetErrorCallback(glfw_error_callback)
        if not glfwInit():
            raise PenumbraException(
                "Unable to initialize GLFW. Either there is no GPU, libraries are missing, or "
                "some other error happened.",
                self.logger)
        glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 2)
        glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 1)
        glfwWindowHint(GLFW_VISIBLE, GL_FALSE)
        self.window = glfwCreateWindow(1, 1, "Penumbra", None, None)
        glfwMakeContextCurrent(self.window)
        if not self.window:
            raise PenumbraException(
                "Unable to create OpenGL context. OpenGL 2.1+ is required to perform GPU "
                "accelerated shading calculations.",
                self.logger)
        if not gladLoadGLLoader(glfwGetProcAddress):
            raise PenumbraException("Failed to load required OpenGL extensions.", self.logger)
        if not glfwExtensionSupported("GL_ARB_vertex_array_object") and \
           not glfwExtensionSupported("GL_APPLE_vertex_array_object"):
            raise PenumbraException("The current version of OpenGL does not support vertex array objects.",
                                    self.logger)
        if not glfwExtensionSupported("GL_EXT_framebuffer_object"):
            raise PenumbraException("The current version of OpenGL does not support framebuffer objects.",
                                    self.logger)
        var max_view_size: StaticArray[GLint, 2]
        glGetIntegerv(GL_MAX_VIEWPORT_DIMS, max_view_size.data)
        var max_res: GLint = min(GL_MAX_RENDERBUFFER_SIZE_EXT, max_view_size[0])
        if self.size >= max_res:
            self.logger.warning(
                "The selected resolution, " + String(self.size) + ", is larger than the maximum allowable by your "
                "hardware, " + String(max_res) + ". The size will be reset to be equal to the maximum allowable.")
            self.size = max_res
        glViewport(0, 0, self.size, self.size)
        glfwSetWindowUserPointer(self.window, self)
        glfwSetKeyCallback(self.window, self.key_callback)
        glfwSetScrollCallback(self.window, self.scroll_callback)
        glfwSetMouseButtonCallback(self.window, self.mouse_callback)
        glfwSetCursorPosCallback(self.window, self.cursor_position_callback)
        glfwSwapInterval(1)
        glEnable(GL_DEPTH_TEST)
        self.calculation_program = GLProgram(self.calculation_vertex_shader_source, None, self.logger)
        glBindAttribLocation(self.calculation_program.get(), 0, "vPos")
        self.render_program = GLProgram(self.render_vertex_shader_source,
                                        self.render_fragment_shader_source, self.logger)
        glBindAttribLocation(self.render_program.get(), 0, "vPos")
        self.vertex_color_location = glGetUniformLocation(self.render_program.get(), "vCol")
        glGenFramebuffersEXT(1, self.framebuffer_object)
        glGenRenderbuffersEXT(1, self.renderbuffer_object)
        self.initialize_off_screen_mode()

    def __del__(owned self):
        glDeleteQueries(static_cast[GLsizei](len(self.queries)), self.queries.data)
        glDeleteFramebuffersEXT(1, self.framebuffer_object)
        glDeleteRenderbuffersEXT(1, self.renderbuffer_object)
        glDeleteProgram(self.calculation_program.get())
        glDeleteProgram(self.render_program.get())
        self.model.clear_model()
        glfwTerminate()

    def toggle_wire_frame_mode(inout self):
        self.is_wire_frame_mode = not self.is_wire_frame_mode
        if self.is_wire_frame_mode:
            glPolygonMode(GL_FRONT_AND_BACK, GL_LINE)
        else:
            glPolygonMode(GL_FRONT_AND_BACK, GL_FILL)

    def toggle_camera_mode(inout self):
        self.is_camera_mode = not self.is_camera_mode
        self.left_mouse_button_pressed = False
        if self.is_camera_mode:
            self.view_scale = 1.0
            mat4x4_dup(self.camera_view, self.view)
            self.set_camera_mvp()
        else:
            self.set_mvp()

    @staticmethod
    def get_vendor_name() -> String:
        return String(glGetString(GL_VENDOR))

    def clear_model(inout self):
        self.model.clear_model()
        glDeleteQueries(static_cast[GLsizei](len(self.queries)), self.queries.data)
        self.model_is_set = False

    def set_model(inout self, vertices: List[Float32], surface_buffers: List[SurfaceBuffer]):
        if self.model_is_set:
            self.clear_model()
        self.model.set_vertices(vertices)
        self.model.set_surface_buffers(surface_buffers)
        self.queries = List[GLuint](len(surface_buffers))
        self.pixel_areas = List[Float32](len(surface_buffers))
        self.pixel_counts = List[GLint](len(surface_buffers), -1)
        glGenQueries(static_cast[GLsizei](len(self.queries)), self.queries.data)
        var box_left: Float32 = MAX_FLOAT
        var box_bottom: Float32 = MAX_FLOAT
        var box_front: Float32 = MAX_FLOAT
        var box_right: Float32 = -MAX_FLOAT
        var box_top: Float32 = -MAX_FLOAT
        var box_back: Float32 = -MAX_FLOAT
        for i in range(0, len(vertices), GLModel.vertex_size):
            var x: Float32 = vertices[i]
            var y: Float32 = vertices[i + 1]
            var z: Float32 = vertices[i + 2]
            box_left = min(x, box_left)
            box_right = max(x, box_right)
            box_front = min(y, box_front)
            box_back = max(y, box_back)
            box_bottom = min(z, box_bottom)
            box_top = max(z, box_top)
        var tempBox: StaticMatrix[Float32, 8, 4] = StaticMatrix[Float32, 8, 4](
            [box_left, box_front, box_bottom, 0.0],
            [box_left, box_front, box_top, 0.0],
            [box_left, box_back, box_bottom, 0.0],
            [box_left, box_back, box_top, 0.0],
            [box_right, box_front, box_bottom, 0.0],
            [box_right, box_front, box_top, 0.0],
            [box_right, box_back, box_bottom, 0.0],
            [box_right, box_back, box_top, 0.0])
        for i in range(8):
            for j in range(4):
                self.model_bounding_box[i][j] = tempBox[i][j]
        self.model_is_set = True

    def set_scene(inout self, sun_view: StaticMatrix[Float32, 4, 4], surface_buffer: SurfaceBuffer? = None, clip_far: Bool = True) -> Float32:
        if not self.model_is_set:
            raise PenumbraException("Model has not been set. Cannot set OpenGL scene.", self.logger)
        mat4x4_dup(self.view, sun_view)
        self.left = MAX_FLOAT
        self.right = -MAX_FLOAT
        self.bottom = MAX_FLOAT
        self.top = -MAX_FLOAT
        self.near_ = -MAX_FLOAT
        self.far_ = MAX_FLOAT
        var beg: GLuint = 0
        var end: GLuint = 0
        if surface_buffer:
            beg = surface_buffer.begin * GLModel.vertex_size
            end = surface_buffer.begin * GLModel.vertex_size + surface_buffer.count * GLModel.vertex_size
        else:
            end = static_cast[GLuint](len(self.model.vertex_array))
        for i in range(beg, end, GLModel.vertex_size):
            var translation: StaticArray[Float32, 4]
            var point: StaticArray[Float32, 4] = [self.model.vertex_array[i], self.model.vertex_array[i + 1], self.model.vertex_array[i + 2], 0.0]
            mat4x4_mul_vec4(translation, self.view, point)
            self.left = min(translation[0], self.left)
            self.right = max(translation[0], self.right)
            self.bottom = min(translation[1], self.bottom)
            self.top = max(translation[1], self.top)
            self.far_ = min(translation[2], self.far_)
        for coordinate in self.model_bounding_box:
            var translation: StaticArray[Float32, 4]
            mat4x4_mul_vec4(translation, self.view, coordinate)
            self.near_ = max(translation[2], self.near_)
            if not clip_far:
                self.far_ = min(translation[2], self.far_)
        self.near_ -= 0.999
        self.far_ -= 1.001
        var inverse_size: Float32 = 1.0 / static_cast[Float32](self.size)
        var delta_x: Float32 = (self.right - self.left) * inverse_size
        self.left -= delta_x
        self.right += delta_x
        var delta_y: Float32 = (self.top - self.bottom) * inverse_size
        self.bottom -= delta_y
        self.top += delta_y
        var pixel_area: Float32 = (self.right - self.left) * (self.top - self.bottom) * inverse_size * inverse_size
        if pixel_area > 0.0:
            mat4x4_ortho(self.projection, self.left, self.right, self.bottom, self.top, -self.near_, -self.far_)
            mat4x4_mul(self.mvp, self.projection, self.view)
            self.set_mvp()
        return pixel_area

    def calculate_camera_view(inout self):
        var temporary_matrix: StaticMatrix[Float32, 4, 4]
        mat4x4_transpose(temporary_matrix, self.camera_view)
        mat4x4_rotate_X(self.camera_view, temporary_matrix, self.camera_x_rotation_angle)
        mat4x4_rotate_Y(temporary_matrix, self.camera_view, self.camera_y_rotation_angle)
        mat4x4_transpose(self.camera_view, temporary_matrix)

    def set_mvp(inout self):
        glUniformMatrix4fv(self.mvp_location, 1, GL_FALSE, self.mvp.data)

    def set_camera_mvp(inout self):
        var delta_width: Float32
        var delta_height: Float32
        var camera_right: Float32 = self.right
        var camera_left: Float32 = self.left
        var camera_top: Float32 = self.top
        var camera_bottom: Float32 = self.bottom
        var camera_near: Float32 = 100.0
        var camera_far: Float32 = -100.0
        delta_width = (camera_right - camera_left) / 2.0
        delta_height = (camera_top - camera_bottom) / 2.0
        if delta_width > delta_height:
            camera_top += (delta_width - delta_height)
            camera_bottom -= (delta_width - delta_height)
        else:
            camera_left -= (delta_height - delta_width)
            camera_right += (delta_width - delta_height)
        var camera_projection: StaticMatrix[Float32, 4, 4]
        var camera_mvp: StaticMatrix[Float32, 4, 4]
        mat4x4_ortho(camera_projection, self.view_scale * camera_left, self.view_scale * camera_right,
                     self.view_scale * camera_bottom, self.view_scale * camera_top, -camera_near, -camera_far)
        mat4x4_mul(camera_mvp, camera_projection, self.camera_view)
        glUniformMatrix4fv(self.mvp_location, 1, GL_FALSE, camera_mvp.data)

    def draw_model(inout self):
        glClearColor(0.0, 0.0, 0.0, 1.0)
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
        glDepthFunc(GL_LESS)
        self.model.draw_all()
        glDepthFunc(GL_EQUAL)

    def draw_except(inout self, hidden_surfaces: List[SurfaceBuffer]):
        glClearColor(0.0, 0.0, 0.0, 1.0)
        glClear(GL_DEPTH_BUFFER_BIT)
        glDepthFunc(GL_LESS)
        self.model.draw_except(hidden_surfaces)
        glDepthFunc(GL_EQUAL)

    def show_rendering(inout self, surface_index: UInt32, sun_view: StaticMatrix[Float32, 4, 4]):
        glfwSetWindowSize(self.window, self.size, self.size)
        glfwShowWindow(self.window)
        self.initialize_render_mode()
        var surface_buffer: SurfaceBuffer = self.model.surface_buffers[surface_index]
        self.set_scene(sun_view, surface_buffer)
        while not glfwWindowShouldClose(self.window):
            glUniform3f(self.vertex_color_location, 0.5, 0.5, 0.5)
            self.draw_model()
            glUniform3f(self.vertex_color_location, 1.0, 1.0, 1.0)
            GLModel.draw_surface(surface_buffer)
            glfwSwapBuffers(self.window)
            glfwPollEvents()
        glfwSetWindowShouldClose(self.window, 0)
        glfwHideWindow(self.window)
        self.initialize_off_screen_mode()

    def show_interior_rendering(inout self, hidden_surface_indices: List[UInt32], interior_surface_index: UInt32, sun_view: StaticMatrix[Float32, 4, 4]):
        glfwSetWindowSize(self.window, self.size, self.size)
        glfwShowWindow(self.window)
        self.initialize_render_mode()
        var interior_surface: SurfaceBuffer = self.model.surface_buffers[interior_surface_index]
        var hidden_surfaces: List[SurfaceBuffer]
        hidden_surfaces.reserve(len(hidden_surface_indices))
        for hidden_surface in hidden_surface_indices:
            hidden_surfaces.push_back(self.model.surface_buffers[hidden_surface])
        self.set_scene(sun_view, self.model.surface_buffers[hidden_surface_indices[0]], False)
        while not glfwWindowShouldClose(self.window):
            glUniform3f(self.vertex_color_location, 0.5, 0.5, 0.5)
            self.draw_except(hidden_surfaces)
            glUniform3f(self.vertex_color_location, 1.0, 1.0, 1.0)
            GLModel.draw_surface(interior_surface)
            glfwSwapBuffers(self.window)
            glfwPollEvents()
        glfwSetWindowShouldClose(self.window, 0)
        glfwHideWindow(self.window)
        self.initialize_off_screen_mode()

    def submit_pssa(inout self, surface_buffer: SurfaceBuffer, sun_view: StaticMatrix[Float32, 4, 4]):
        var pixel_area: Float32 = self.set_scene(sun_view, surface_buffer)
        self.draw_model()
        glBeginQuery(GL_SAMPLES_PASSED, self.queries[surface_buffer.index])
        GLModel.draw_surface(surface_buffer)
        glEndQuery(GL_SAMPLES_PASSED)
        self.pixel_areas[surface_buffer.index] = pixel_area

    def submit_pssa(inout self, surface_index: UInt32, sun_view: StaticMatrix[Float32, 4, 4]):
        self.submit_pssa(self.model.surface_buffers[surface_index], sun_view)

    def submit_pssas(inout self, surface_indices: List[UInt32], sun_view: StaticMatrix[Float32, 4, 4]):
        for surface_index in surface_indices:
            self.submit_pssa(surface_index, sun_view)

    def submit_pssa(inout self, sun_view: StaticMatrix[Float32, 4, 4]):
        for surface_buffer in self.model.surface_buffers:
            self.submit_pssa(surface_buffer, sun_view)

    def retrieve_pssa(inout self, surface_index: UInt32) -> Float32:
        glGetQueryObjectiv(self.queries[surface_index], GL_QUERY_RESULT, self.pixel_counts[surface_index])
        return static_cast[Float32](self.pixel_counts[surface_index]) * self.pixel_areas[surface_index]

    def retrieve_pssas(inout self, surface_indices: List[UInt32]) -> List[Float32]:
        var pssas: List[Float32]
        pssas.reserve(len(surface_indices))
        for surface_index in surface_indices:
            pssas.push_back(self.retrieve_pssa(surface_index))
        return pssas

    def retrieve_pssa(inout self) -> List[Float32]:
        var pssas: List[Float32]
        pssas.reserve(len(self.model.surface_buffers))
        for surface_buffer in self.model.surface_buffers:
            pssas.push_back(self.retrieve_pssa(surface_buffer.index))
        return pssas

    def calculate_interior_pssas(inout self, hidden_surface_indices: List[UInt32], interior_surface_indices: List[UInt32], sun_view: StaticMatrix[Float32, 4, 4]) -> Dict[UInt32, Float32]:
        var interior_queries: List[GLuint] = List[GLuint](len(interior_surface_indices))
        var pssas: Dict[UInt32, Float32]
        glGenQueries(static_cast[GLsizei](len(interior_queries)), interior_queries.data)
        var pixel_area: Float32 = self.set_scene(sun_view, self.model.surface_buffers[hidden_surface_indices[0]], False)
        var hidden_surfaces: List[SurfaceBuffer]
        hidden_surfaces.reserve(len(hidden_surface_indices))
        for hidden_surface in hidden_surface_indices:
            hidden_surfaces.push_back(self.model.surface_buffers[hidden_surface])
        var interior_surfaces: List[SurfaceBuffer]
        interior_surfaces.reserve(len(interior_surface_indices))
        for interior_surface in interior_surface_indices:
            interior_surfaces.push_back(self.model.surface_buffers[interior_surface])
        self.draw_except(hidden_surfaces)
        for i in range(len(interior_surfaces)):
            glBeginQuery(GL_SAMPLES_PASSED, interior_queries[i])
            GLModel.draw_surface(interior_surfaces[i])
            glEndQuery(GL_SAMPLES_PASSED)
        for i in range(len(interior_surfaces)):
            var pixel_count: GLint
            glGetQueryObjectiv(interior_queries[i], GL_QUERY_RESULT, pixel_count)
            pssas[interior_surfaces[i].index] = static_cast[Float32](pixel_count) * pixel_area
        glDeleteQueries(static_cast[GLsizei](len(interior_queries)), interior_queries.data)
        return pssas

    def initialize_off_screen_mode(inout self):
        glUseProgram(self.calculation_program.get())
        self.mvp_location = glGetUniformLocation(self.calculation_program.get(), "MVP")
        glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, self.framebuffer_object)
        glDrawBuffer(GL_NONE)
        glReadBuffer(GL_NONE)
        glBindRenderbufferEXT(GL_RENDERBUFFER_EXT, self.renderbuffer_object)
        glRenderbufferStorageEXT(GL_RENDERBUFFER_EXT, GL_DEPTH_COMPONENT24, self.size, self.size)
        glFramebufferRenderbufferEXT(GL_FRAMEBUFFER_EXT, GL_DEPTH_ATTACHMENT_EXT, GL_RENDERBUFFER_EXT,
                                     self.renderbuffer_object)
        var status: GLenum = glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT)
        if status != GL_FRAMEBUFFER_COMPLETE_EXT:
            var reason: String
            if status == GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT_EXT:
                reason = "Incomplete attachment."
            elif status == GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT_EXT:
                reason = "Incomplete or missing attachment."
            elif status == GL_FRAMEBUFFER_INCOMPLETE_FORMATS_EXT:
                reason = "Incomplete formats."
            elif status == GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER_EXT:
                reason = "Incomplete draw buffer."
            elif status == GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER_EXT:
                reason = "Incomplete read buffer."
            elif status == GL_FRAMEBUFFER_UNSUPPORTED_EXT:
                reason = "Framebuffers are not supported."
            else:
                reason = "Reason unknown."
            raise PenumbraException("Unable to create framebuffer. " + reason, self.logger)
        glColorMask(GL_FALSE, GL_FALSE, GL_FALSE, GL_FALSE)

    def initialize_render_mode(inout self):
        glUseProgram(self.render_program.get())
        self.mvp_location = glGetUniformLocation(self.render_program.get(), "MVP")
        self.set_mvp()
        glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0)
        glBindRenderbufferEXT(GL_RENDERBUFFER_EXT, 0)
        glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE)

    def key_callback(w: GLFWwindow?, key: Int32, scancode: Int32, action: Int32, mods: Int32):
        if key == GLFW_KEY_W and action == GLFW_PRESS:
            glfwWPtr(w).toggle_wire_frame_mode()
        if key == GLFW_KEY_O and action == GLFW_PRESS:
            glfwWPtr(w).toggle_camera_mode()

    def scroll_callback(w: GLFWwindow?, xOffset: Float64, yOffset: Float64):
        glfwWPtr(w).view_scale += static_cast[Float32](0.1 * yOffset)
        if glfwWPtr(w).is_camera_mode:
            glfwWPtr(w).set_camera_mvp()

    def mouse_callback(w: GLFWwindow?, button: Int32, action: Int32, mods: Int32):
        if button == GLFW_MOUSE_BUTTON_LEFT:
            if GLFW_PRESS == action:
                glfwWPtr(w).left_mouse_button_pressed = True
                glfwGetCursorPos(w, glfwWPtr(w).previous_x_position, glfwWPtr(w).previous_y_position)
            elif GLFW_RELEASE == action:
                glfwWPtr(w).left_mouse_button_pressed = False

    def cursor_position_callback(w: GLFWwindow?, x_position: Float64, y_position: Float64):
        if glfwWPtr(w).left_mouse_button_pressed and glfwWPtr(w).is_camera_mode:
            var rotation_speed: Float64 = 1.0 / 300.0
            glfwWPtr(w).camera_x_rotation_angle = static_cast[Float32](-(y_position - glfwWPtr(w).previous_y_position) * rotation_speed)
            glfwWPtr(w).camera_y_rotation_angle = static_cast[Float32]((x_position - glfwWPtr(w).previous_x_position) * rotation_speed)
            glfwWPtr(w).previous_x_position = x_position
            glfwWPtr(w).previous_y_position = y_position
            glfwWPtr(w).calculate_camera_view()
            glfwWPtr(w).set_camera_mvp()

def glfwWPtr(w: GLFWwindow?) -> Context:
    return glfwGetWindowUserPointer(w) as Context