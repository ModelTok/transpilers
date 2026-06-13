from main import *
from std.io import *
from GL.glew import *
from Eigen.OpenGLSupport import *
from GL.glut import *
using Eigen

# define VERIFY_MATRIX(CODE,REF) { \
#     glLoadIdentity(); \
#     CODE; \
#     Matrix<float,4,4,ColMajor> m; m.setZero(); \
#     glGet(GL_MODELVIEW_MATRIX, m); \
#     if(!(REF).cast<float>().isApprox(m)) { \
#       cerr << "Expected:\n" << ((REF).cast<float>()) << "\n" << "got\n" << m << "\n\n"; \
#     } \
#     VERIFY_IS_APPROX((REF).cast<float>(), m); \
#   }
# define VERIFY_UNIFORM(SUFFIX,NAME,TYPE) { \
#     TYPE value; value.setRandom(); \
#     TYPE data; \
#     int loc = glGetUniformLocation(prg_id, #NAME); \
#     VERIFY((loc!=-1) && "uniform not found"); \
#     glUniform(loc,value); \
#     EIGEN_CAT(glGetUniform,SUFFIX)(prg_id,loc,data.data()); \
#     if(!value.isApprox(data)) { \
#       cerr << "Expected:\n" << value << "\n" << "got\n" << data << "\n\n"; \
#     } \
#     VERIFY_IS_APPROX(value, data); \
#   }
# define VERIFY_UNIFORMi(NAME,TYPE) { \
#     TYPE value = TYPE::Random().eval().cast<float>().cast<TYPE::Scalar>(); \
#     TYPE data; \
#     int loc = glGetUniformLocation(prg_id, #NAME); \
#     VERIFY((loc!=-1) && "uniform not found"); \
#     glUniform(loc,value); \
#     glGetUniformiv(prg_id,loc,(GLint*)data.data()); \
#     if(!value.isApprox(data)) { \
#       cerr << "Expected:\n" << value << "\n" << "got\n" << data << "\n\n"; \
#     } \
#     VERIFY_IS_APPROX(value, data); \
#   }

def printInfoLog(objectID: GLuint):
    var infologLength: int
    var charsWritten: int
    var infoLog: GLchar*
    glGetProgramiv(objectID, GL_INFO_LOG_LENGTH, &infologLength)
    if infologLength > 0:
        infoLog = new GLchar[infologLength]
        glGetProgramInfoLog(objectID, infologLength, &charsWritten, infoLog)
        if charsWritten > 0:
            std.cerr << "Shader info : \n" << infoLog << std.endl
        delete[] infoLog

def createShader(vtx: const char*, frg: const char*) -> GLint:
    var prg_id: GLint = glCreateProgram()
    var vtx_id: GLint = glCreateShader(GL_VERTEX_SHADER)
    var frg_id: GLint = glCreateShader(GL_FRAGMENT_SHADER)
    var ok: GLint
    glShaderSource(vtx_id, 1, &vtx, 0)
    glCompileShader(vtx_id)
    glGetShaderiv(vtx_id, GL_COMPILE_STATUS, &ok)
    if not ok:
        std.cerr << "vtx compilation failed\n"
    glShaderSource(frg_id, 1, &frg, 0)
    glCompileShader(frg_id)
    glGetShaderiv(frg_id, GL_COMPILE_STATUS, &ok)
    if not ok:
        std.cerr << "frg compilation failed\n"
    glAttachShader(prg_id, vtx_id)
    glAttachShader(prg_id, frg_id)
    glLinkProgram(prg_id)
    glGetProgramiv(prg_id, GL_LINK_STATUS, &ok)
    if not ok:
        std.cerr << "linking failed\n"
    printInfoLog(prg_id)
    glUseProgram(prg_id)
    return prg_id

def test_openglsupport():
    var argc: int = 0
    glutInit(&argc, 0)
    glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGB | GLUT_DEPTH)
    glutInitWindowPosition(0, 0)
    glutInitWindowSize(10, 10)
    if glutCreateWindow("Eigen") <= 0:
        std.cerr << "Error: Unable to create GLUT Window.\n"
        exit(1)
    glewExperimental = GL_TRUE
    if glewInit() != GLEW_OK:
        std.cerr << "Warning: Failed to initialize GLEW\n"
    var v3f: Vector3f
    var rot: Matrix3f
    glBegin(GL_POINTS)
    glVertex(v3f)
    glVertex(2 * v3f + v3f)
    glVertex(rot * v3f)
    glEnd()
    var mf44: Matrix4f
    mf44.setRandom()
    VERIFY_MATRIX(glLoadMatrix(mf44), mf44)
    VERIFY_MATRIX(glMultMatrix(mf44), mf44)
    var md44: Matrix4d
    md44.setRandom()
    VERIFY_MATRIX(glLoadMatrix(md44), md44)
    VERIFY_MATRIX(glMultMatrix(md44), md44)
    var qd: Quaterniond = Quaterniond(AngleAxisd(internal.random[double](), Vector3d.Random()))
    VERIFY_MATRIX(glRotate(qd), Projective3d(qd).matrix())
    var qf: Quaternionf = Quaternionf(AngleAxisf(internal.random[double](), Vector3f.Random()))
    VERIFY_MATRIX(glRotate(qf), Projective3f(qf).matrix())
    var acf3: Transform[float32, 3, AffineCompact]
    acf3.matrix().setRandom()
    VERIFY_MATRIX(glLoadMatrix(acf3), Projective3f(acf3).matrix())
    VERIFY_MATRIX(glMultMatrix(acf3), Projective3f(acf3).matrix())
    var af3: Transform[float32, 3, Affine] = Transform[float32, 3, Affine](acf3)
    VERIFY_MATRIX(glLoadMatrix(af3), Projective3f(af3).matrix())
    VERIFY_MATRIX(glMultMatrix(af3), Projective3f(af3).matrix())
    var pf3: Transform[float32, 3, Projective]
    pf3.matrix().setRandom()
    VERIFY_MATRIX(glLoadMatrix(pf3), Projective3f(pf3).matrix())
    VERIFY_MATRIX(glMultMatrix(pf3), Projective3f(pf3).matrix())
    var acd3: Transform[float64, 3, AffineCompact]
    acd3.matrix().setRandom()
    VERIFY_MATRIX(glLoadMatrix(acd3), Projective3d(acd3).matrix())
    VERIFY_MATRIX(glMultMatrix(acd3), Projective3d(acd3).matrix())
    var ad3: Transform[float64, 3, Affine] = Transform[float64, 3, Affine](acd3)
    VERIFY_MATRIX(glLoadMatrix(ad3), Projective3d(ad3).matrix())
    VERIFY_MATRIX(glMultMatrix(ad3), Projective3d(ad3).matrix())
    var pd3: Transform[float64, 3, Projective]
    pd3.matrix().setRandom()
    VERIFY_MATRIX(glLoadMatrix(pd3), Projective3d(pd3).matrix())
    VERIFY_MATRIX(glMultMatrix(pd3), Projective3d(pd3).matrix())
    {
        var vf2: Vector2f
        vf2.setRandom()
        var vf23: Vector3f
        vf23 << vf2, 0
        VERIFY_MATRIX(glTranslate(vf2), Projective3f(Translation3f(vf23)).matrix())
        var vd2: Vector2d
        vd2.setRandom()
        var vd23: Vector3d
        vd23 << vd2, 0
        VERIFY_MATRIX(glTranslate(vd2), Projective3d(Translation3d(vd23)).matrix())
        var vf3: Vector3f
        vf3.setRandom()
        VERIFY_MATRIX(glTranslate(vf3), Projective3f(Translation3f(vf3)).matrix())
        var vd3: Vector3d
        vd3.setRandom()
        VERIFY_MATRIX(glTranslate(vd3), Projective3d(Translation3d(vd3)).matrix())
        var tf3: Translation[float32, 3]
        tf3.vector().setRandom()
        VERIFY_MATRIX(glTranslate(tf3), Projective3f(tf3).matrix())
        var td3: Translation[float64, 3]
        td3.vector().setRandom()
        VERIFY_MATRIX(glTranslate(td3), Projective3d(td3).matrix())
    }
    {
        var vf2: Vector2f
        vf2.setRandom()
        var vf23: Vector3f
        vf23 << vf2, 1
        VERIFY_MATRIX(glScale(vf2), Projective3f(Scaling(vf23)).matrix())
        var vd2: Vector2d
        vd2.setRandom()
        var vd23: Vector3d
        vd23 << vd2, 1
        VERIFY_MATRIX(glScale(vd2), Projective3d(Scaling(vd23)).matrix())
        var vf3: Vector3f
        vf3.setRandom()
        VERIFY_MATRIX(glScale(vf3), Projective3f(Scaling(vf3)).matrix())
        var vd3: Vector3d
        vd3.setRandom()
        VERIFY_MATRIX(glScale(vd3), Projective3d(Scaling(vd3)).matrix())
        var usf: UniformScaling[float32] = UniformScaling[float32](internal.random[float32]())
        VERIFY_MATRIX(glScale(usf), Projective3f(usf).matrix())
        var usd: UniformScaling[float64] = UniformScaling[float64](internal.random[float64]())
        VERIFY_MATRIX(glScale(usd), Projective3d(usd).matrix())
    }
    {
        var vtx: const char* = "void main(void) { gl_Position = gl_Vertex; }\n"
        if GLEW_VERSION_2_0:
            # ifdef GL_VERSION_2_0
            var frg: const char* = ""
                "uniform vec2 v2f;\n"
                "uniform vec3 v3f;\n"
                "uniform vec4 v4f;\n"
                "uniform ivec2 v2i;\n"
                "uniform ivec3 v3i;\n"
                "uniform ivec4 v4i;\n"
                "uniform mat2 m2f;\n"
                "uniform mat3 m3f;\n"
                "uniform mat4 m4f;\n"
                "void main(void) { gl_FragColor = vec4(v2f[0]+v3f[0]+v4f[0])+vec4(v2i[0]+v3i[0]+v4i[0])+vec4(m2f[0][0]+m3f[0][0]+m4f[0][0]); }\n"
            var prg_id: GLint = createShader(vtx, frg)
            VERIFY_UNIFORM(fv, v2f, Vector2f)
            VERIFY_UNIFORM(fv, v3f, Vector3f)
            VERIFY_UNIFORM(fv, v4f, Vector4f)
            VERIFY_UNIFORMi(v2i, Vector2i)
            VERIFY_UNIFORMi(v3i, Vector3i)
            VERIFY_UNIFORMi(v4i, Vector4i)
            VERIFY_UNIFORM(fv, m2f, Matrix2f)
            VERIFY_UNIFORM(fv, m3f, Matrix3f)
            VERIFY_UNIFORM(fv, m4f, Matrix4f)
            # endif
        else:
            std.cerr << "Warning: opengl 2.0 was not tested\n"
        if GLEW_VERSION_2_1:
            # ifdef GL_VERSION_2_1
            var frg: const char* = "#version 120\n"
                "uniform mat2x3 m23f;\n"
                "uniform mat3x2 m32f;\n"
                "uniform mat2x4 m24f;\n"
                "uniform mat4x2 m42f;\n"
                "uniform mat3x4 m34f;\n"
                "uniform mat4x3 m43f;\n"
                "void main(void) { gl_FragColor = vec4(m23f[0][0]+m32f[0][0]+m24f[0][0]+m42f[0][0]+m34f[0][0]+m43f[0][0]); }\n"
            var prg_id: GLint = createShader(vtx, frg)
            typedef Matrix[float32, 2, 3] Matrix23f
            typedef Matrix[float32, 3, 2] Matrix32f
            typedef Matrix[float32, 2, 4] Matrix24f
            typedef Matrix[float32, 4, 2] Matrix42f
            typedef Matrix[float32, 3, 4] Matrix34f
            typedef Matrix[float32, 4, 3] Matrix43f
            VERIFY_UNIFORM(fv, m23f, Matrix23f)
            VERIFY_UNIFORM(fv, m32f, Matrix32f)
            VERIFY_UNIFORM(fv, m24f, Matrix24f)
            VERIFY_UNIFORM(fv, m42f, Matrix42f)
            VERIFY_UNIFORM(fv, m34f, Matrix34f)
            VERIFY_UNIFORM(fv, m43f, Matrix43f)
            # endif
        else:
            std.cerr << "Warning: opengl 2.1 was not tested\n"
        if GLEW_VERSION_3_0:
            # ifdef GL_VERSION_3_0
            var frg: const char* = "#version 150\n"
                "uniform uvec2 v2ui;\n"
                "uniform uvec3 v3ui;\n"
                "uniform uvec4 v4ui;\n"
                "out vec4 data;\n"
                "void main(void) { data = vec4(v2ui[0]+v3ui[0]+v4ui[0]); }\n"
            var prg_id: GLint = createShader(vtx, frg)
            typedef Matrix[uint32, 2, 1] Vector2ui
            typedef Matrix[uint32, 3, 1] Vector3ui
            typedef Matrix[uint32, 4, 1] Vector4ui
            VERIFY_UNIFORMi(v2ui, Vector2ui)
            VERIFY_UNIFORMi(v3ui, Vector3ui)
            VERIFY_UNIFORMi(v4ui, Vector4ui)
            # endif
        else:
            std.cerr << "Warning: opengl 3.0 was not tested\n"
        # ifdef GLEW_ARB_gpu_shader_fp64
        if GLEW_ARB_gpu_shader_fp64:
            # ifdef GL_ARB_gpu_shader_fp64
            var frg: const char* = "#version 150\n"
                "uniform dvec2 v2d;\n"
                "uniform dvec3 v3d;\n"
                "uniform dvec4 v4d;\n"
                "out vec4 data;\n"
                "void main(void) { data = vec4(v2d[0]+v3d[0]+v4d[0]); }\n"
            var prg_id: GLint = createShader(vtx, frg)
            VERIFY_UNIFORM(dv, v2d, Vector2d)
            VERIFY_UNIFORM(dv, v3d, Vector3d)
            VERIFY_UNIFORM(dv, v4d, Vector4d)
            # endif
        else:
            std.cerr << "Warning: GLEW_ARB_gpu_shader_fp64 was not tested\n"
        # else
        #     cerr << "Warning: GLEW_ARB_gpu_shader_fp64 was not tested\n"
        # endif
    }