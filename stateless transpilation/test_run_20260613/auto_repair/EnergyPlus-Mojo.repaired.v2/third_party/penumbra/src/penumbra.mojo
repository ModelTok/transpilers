from penumbra import PenumbraException, VendorType, Surface, TessData, SurfaceBuffer, Context, Sun
from penumbra-implementation import PenumbraImplementation
from Courierr.Courierr import Courierr
from glfw import glfwInit, glfwWindowHint, glfwCreateWindow, glfwMakeContextCurrent, glfwDestroyWindow
from memory import Pointer, SharedPtr
from sys import platform

# Conditional compilation parameters
@parameter
if __debug__:
    @parameter
    if __unix__:
        from cfenv import fedisableexcept, feenableexcept, FE_DIVBYZERO, FE_INVALID, FE_OVERFLOW

struct Penumbra:
    var penumbra: Pointer[PenumbraImplementation]

    def __init__(inout self, size: UInt32, logger: SharedPtr[Courierr.Courierr]):
        self.penumbra = Pointer[PenumbraImplementation](Int32(size), logger)

    def __init__(inout self, logger: SharedPtr[Courierr.Courierr]):
        self.penumbra = Pointer[PenumbraImplementation](512, logger)

    def __del__(owned self):

    def is_valid_context() -> Bool:
        var invalid: Bool = False
        if not glfwInit():
            invalid = True
        glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 2)
        glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 1)
        glfwWindowHint(GLFW_VISIBLE, GL_FALSE)
        @parameter
        if not __debug__:
            @parameter
            if __unix__:
                fedisableexcept(FE_DIVBYZERO | FE_INVALID | FE_OVERFLOW)
        var window: Pointer[GLFWwindow] = glfwCreateWindow(1, 1, "Penumbra", None, None)
        @parameter
        if not __debug__:
            @parameter
            if __unix__:
                feenableexcept(FE_DIVBYZERO | FE_INVALID | FE_OVERFLOW)
        glfwMakeContextCurrent(window)
        invalid = invalid or (window is None)
        glfwDestroyWindow(window)
        return not invalid

    def get_vendor_name() -> VendorType:
        var vendor_type: VendorType
        var vendor_name = Context.get_vendor_name()
        if vendor_name == "NVIDIA":
            vendor_type = VendorType.nvidia
        elif vendor_name == "AMD" or vendor_name == "ATI" or vendor_name == "Advanced Micro Devices" or vendor_name == "ATI Technologies Inc.":
            vendor_type = VendorType.amd
        elif vendor_name == "Intel" or vendor_name == "INTEL" or vendor_name == "Intel Inc.":
            vendor_type = VendorType.intel
        elif vendor_name == "VMware, Inc.":
            vendor_type = VendorType.vmware
        elif vendor_name == "Mesa" or vendor_name == "Mesa/X.org":
            vendor_type = VendorType.mesa
        else:
            raise PenumbraException(
                String.format("Failed to find GPU or vendor name ({}) is not in list.", vendor_name),
                *(self.penumbra.logger))
        return vendor_type

    def add_surface(inout self, surface: Surface) -> UInt32:
        self.penumbra.add_surface(surface)
        return UInt32(self.penumbra.surfaces.size()) - 1

    def get_number_of_surfaces(self) -> UInt32:
        return UInt32(self.penumbra.surfaces.size())

    def set_model(inout self):
        if len(self.penumbra.surfaces) != 0:
            var surface_buffers: List[SurfaceBuffer] = List[SurfaceBuffer]()
            var next_starting_index: UInt32 = 0
            var surface_index: UInt32 = 0
            for surface in self.penumbra.surfaces:
                var tess: TessData = surface.tessellate()
                surface_buffers.append(SurfaceBuffer(next_starting_index / TessData.vertex_size,
                                                     tess.number_of_vertices / TessData.vertex_size, surface_index))
                for i in range(tess.number_of_vertices):
                    self.penumbra.model.append(tess.vertices[i])
                next_starting_index += tess.number_of_vertices
                surface_index += 1
            self.penumbra.context.set_model(self.penumbra.model, surface_buffers)
        else:
            self.penumbra.logger.warning("No surfaces added to Penumbra before calling set_model().")

    def clear_model(inout self):
        self.penumbra.surfaces.clear()
        self.penumbra.model.clear()
        self.penumbra.context.clear_model()

    def set_sun_position(inout self, azimuth: Float32, altitude: Float32):
        self.penumbra.sun.set_view(azimuth, altitude)

    def get_sun_azimuth(self) -> Float32:
        return self.penumbra.sun.get_azimuth()

    def get_sun_altitude(self) -> Float32:
        return self.penumbra.sun.get_altitude()

    def submit_pssa(inout self, surface_index: UInt32):
        self.penumbra.check_surface(surface_index)
        self.penumbra.context.submit_pssa(surface_index, self.penumbra.sun.get_view())

    def submit_pssa(inout self, surface_indices: List[UInt32]):
        for surface_index in surface_indices:
            self.penumbra.check_surface(surface_index)
        self.penumbra.context.submit_pssas(surface_indices, self.penumbra.sun.get_view())

    def submit_pssa(inout self):
        self.penumbra.context.submit_pssa(self.penumbra.sun.get_view())

    def retrieve_pssa(self, surface_index: UInt32) -> Float32:
        self.penumbra.check_surface(surface_index)
        return self.penumbra.context.retrieve_pssa(surface_index)

    def retrieve_pssa(self, surface_indices: List[UInt32]) -> List[Float32]:
        for surface_index in surface_indices:
            self.penumbra.check_surface(surface_index)
        return self.penumbra.context.retrieve_pssas(surface_indices)

    def retrieve_pssa(self) -> List[Float32]:
        return self.penumbra.context.retrieve_pssa()

    def calculate_pssa(inout self, surface_index: UInt32) -> Float32:
        self.submit_pssa(surface_index)
        return self.retrieve_pssa(surface_index)

    def calculate_pssa(inout self, surface_indices: List[UInt32]) -> List[Float32]:
        self.submit_pssa(surface_indices)
        return self.retrieve_pssa(surface_indices)

    def calculate_pssa(inout self) -> List[Float32]:
        self.submit_pssa()
        return self.retrieve_pssa()

    def calculate_interior_pssas(inout self, transparent_surface_indices: List[UInt32],
                                interior_surface_indices: List[UInt32]) -> Dict[UInt32, Float32]:
        var pssas: Dict[UInt32, Float32] = Dict[UInt32, Float32]()
        if len(transparent_surface_indices) != 0:
            for transparent_surface_index in transparent_surface_indices:
                self.penumbra.check_surface(transparent_surface_index, "Transparent surface")
            for interior_surface_index in interior_surface_indices:
                self.penumbra.check_surface(interior_surface_index, "Interior surface")
            pssas = self.penumbra.context.calculate_interior_pssas(
                transparent_surface_indices, interior_surface_indices, self.penumbra.sun.get_view())
        else:
            raise PenumbraException(
                "Cannot calculate interior PSSAs without defining at least one transparent surface index.",
                *(self.penumbra.logger))
        return pssas

    def render_scene(inout self, surface_index: UInt32):
        self.penumbra.check_surface(surface_index)
        self.penumbra.context.show_rendering(surface_index, self.penumbra.sun.get_view())

    def render_interior_scene(inout self, transparent_surface_indices: List[UInt32],
                             interior_surface_indices: List[UInt32]):
        if len(transparent_surface_indices) != 0:
            for transparent_surface_index in transparent_surface_indices:
                self.penumbra.check_surface(transparent_surface_index, "Transparent surface")
            for interior_surface_index in interior_surface_indices:
                self.penumbra.check_surface(interior_surface_index, "Interior surface")
                self.penumbra.context.show_interior_rendering(transparent_surface_indices, interior_surface_index,
                                                              self.penumbra.sun.get_view())
        else:
            raise PenumbraException("Cannot render interior scene without defining at least one "
                                    "transparent surface index.",
                                    *(self.penumbra.logger))

    def get_logger(self) -> SharedPtr[Courierr.Courierr]:
        return self.penumbra.logger