from Eigen import Vector3f, Matrix3f, Matrix4f, Color
from GL import (
    glMatrixMode, glLoadMatrixf, glLoadMatrixd, glMultMatrixf, glMultMatrixd,
    glLoadIdentity, glPushMatrix, glPopMatrix, glDrawArrays, glDrawElements,
    glColor4fv, glTranslatef, glRotatef, glScalef, glBegin, glEnd, glNormal3f,
    glVertex3fv, glGetIntegerv, glOrtho, GL_PROJECTION, GL_MODELVIEW, GL_VIEWPORT,
    GL_QUADS, GL_UNSIGNED_INT
)
from GLU import gluNewQuadric, gluCylinder
from icosphere import IcoSphere

alias uint = UInt32
alias GLenum = Int32
alias GLint = Int32
alias GLuint = UInt32

struct GlMatrixHelper[RowMajor: Bool, _Flags: Int]:
    @staticmethod
    def loadMatrix(mat: Matrix[float32, 4, 4, _Flags, 4, 4]):
        glLoadMatrixf(mat.data())
    @staticmethod
    def loadMatrix(mat: Matrix[float64, 4, 4, _Flags, 4, 4]):
        glLoadMatrixd(mat.data())
    @staticmethod
    def multMatrix(mat: Matrix[float32, 4, 4, _Flags, 4, 4]):
        glMultMatrixf(mat.data())
    @staticmethod
    def multMatrix(mat: Matrix[float64, 4, 4, _Flags, 4, 4]):
        glMultMatrixd(mat.data())

struct GpuHelper:
    enum ProjectionMode2D:
        PM_Normalized = 1
        PM_Viewport = 2

    var mColorBufferId: GLuint
    var mVpWidth: Int32
    var mVpHeight: Int32
    var mCurrentMatrixTarget: GLenum
    var mInitialized: Bool

    def __init__(inout self):
        self.mVpWidth = 0
        self.mVpHeight = 0
        self.mCurrentMatrixTarget = 0
        self.mInitialized = False

    def __del__(owned self):

    def pushProjectionMode2D(inout self, pm: ProjectionMode2D):
        self.pushMatrix(Matrix4f.Identity(), GL_PROJECTION)
        if pm == ProjectionMode2D.PM_Normalized:

        elif pm == ProjectionMode2D.PM_Viewport:
            var vp: StaticTuple[4, GLint]
            glGetIntegerv(GL_VIEWPORT, vp.data)
            glOrtho(0.0, Float64(vp[2]), 0.0, Float64(vp[3]), -1.0, 1.0)
        self.pushMatrix(Matrix4f.Identity(), GL_MODELVIEW)

    def popProjectionMode2D(inout self):
        self.popMatrix(GL_PROJECTION)
        self.popMatrix(GL_MODELVIEW)

    def drawVector(inout self, position: Vector3f, vec: Vector3f, color: Color, aspect: float32 = 50.0):
        var cylindre = gluNewQuadric()
        glColor4fv(color.data())
        var length = vec.norm()
        self.pushMatrix(GL_MODELVIEW)
        glTranslatef(position.x(), position.y(), position.z())
        var ax = Matrix3f.Identity().col(2).cross(vec)
        ax.normalize()
        var tmp = vec
        tmp.normalize()
        var angle = 180.0 / 3.141592653589793 * acos(tmp.z())
        if angle > 1e-3:
            glRotatef(angle, ax.x(), ax.y(), ax.z())
        gluCylinder(cylindre, length/aspect, length/aspect, 0.8*length, 10, 10)
        glTranslatef(0.0, 0.0, 0.8*length)
        gluCylinder(cylindre, 2.0*length/aspect, 0.0, 0.2*length, 10, 10)
        self.popMatrix(GL_MODELVIEW)

    def drawVectorBox(inout self, position: Vector3f, vec: Vector3f, color: Color, aspect: float32):
        var cylindre = gluNewQuadric()
        glColor4fv(color.data())
        var length = vec.norm()
        self.pushMatrix(GL_MODELVIEW)
        glTranslatef(position.x(), position.y(), position.z())
        var ax = Matrix3f.Identity().col(2).cross(vec)
        ax.normalize()
        var tmp = vec
        tmp.normalize()
        var angle = 180.0 / 3.141592653589793 * acos(tmp.z())
        if angle > 1e-3:
            glRotatef(angle, ax.x(), ax.y(), ax.z())
        gluCylinder(cylindre, length/aspect, length/aspect, 0.8*length, 10, 10)
        glTranslatef(0.0, 0.0, 0.8*length)
        glScalef(4.0*length/aspect, 4.0*length/aspect, 4.0*length/aspect)
        self.drawUnitCube()
        self.popMatrix(GL_MODELVIEW)

    def drawUnitCube(inout self):
        var vertices: StaticTuple[8, StaticTuple[3, float32]] = StaticTuple(
            StaticTuple(-0.5, -0.5, -0.5),
            StaticTuple( 0.5, -0.5, -0.5),
            StaticTuple(-0.5,  0.5, -0.5),
            StaticTuple( 0.5,  0.5, -0.5),
            StaticTuple(-0.5, -0.5,  0.5),
            StaticTuple( 0.5, -0.5,  0.5),
            StaticTuple(-0.5,  0.5,  0.5),
            StaticTuple( 0.5,  0.5,  0.5)
        )
        glBegin(GL_QUADS)
        glNormal3f(0,0,-1); glVertex3fv(vertices[0].data); glVertex3fv(vertices[2].data); glVertex3fv(vertices[3].data); glVertex3fv(vertices[1].data)
        glNormal3f(0,0, 1); glVertex3fv(vertices[4].data); glVertex3fv(vertices[5].data); glVertex3fv(vertices[7].data); glVertex3fv(vertices[6].data)
        glNormal3f(0,-1,0); glVertex3fv(vertices[0].data); glVertex3fv(vertices[1].data); glVertex3fv(vertices[5].data); glVertex3fv(vertices[4].data)
        glNormal3f(0, 1,0); glVertex3fv(vertices[2].data); glVertex3fv(vertices[6].data); glVertex3fv(vertices[7].data); glVertex3fv(vertices[3].data)
        glNormal3f(-1,0,0); glVertex3fv(vertices[0].data); glVertex3fv(vertices[4].data); glVertex3fv(vertices[6].data); glVertex3fv(vertices[2].data)
        glNormal3f( 1,0,0); glVertex3fv(vertices[1].data); glVertex3fv(vertices[3].data); glVertex3fv(vertices[7].data); glVertex3fv(vertices[5].data)
        glEnd()

    def drawUnitSphere(inout self, level: Int32 = 0):
        var sphere = IcoSphere()
        sphere.draw(level)

    def setMatrixTarget(inout self, matrixTarget: GLenum):
        if matrixTarget != self.mCurrentMatrixTarget:
            glMatrixMode(matrixTarget)
            self.mCurrentMatrixTarget = matrixTarget

    def forceMatrixTarget(inout self, matrixTarget: GLenum):
        glMatrixMode(matrixTarget)
        self.mCurrentMatrixTarget = matrixTarget

    def multMatrix[type: AnyType, _Flags: Int](inout self, mat: Matrix[type, 4, 4, _Flags, 4, 4], matrixTarget: GLenum):
        self.setMatrixTarget(matrixTarget)
        if _Flags & Eigen.RowMajorBit:
            GlMatrixHelper[True, _Flags].multMatrix(mat)
        else:
            GlMatrixHelper[False, _Flags].multMatrix(mat)

    def loadMatrix[type: AnyType, _Flags: Int](inout self, mat: Matrix[type, 4, 4, _Flags, 4, 4], matrixTarget: GLenum):
        self.setMatrixTarget(matrixTarget)
        if (_Flags & Eigen.RowMajorBit) != 0:
            GlMatrixHelper[True, _Flags].loadMatrix(mat)
        else:
            GlMatrixHelper[False, _Flags].loadMatrix(mat)

    def loadMatrix[type: AnyType, Derived: AnyType](inout self, mat: CwiseNullaryOp[scalar_identity_op[type], Derived], matrixTarget: GLenum):
        self.setMatrixTarget(matrixTarget)
        glLoadIdentity()

    def pushMatrix(inout self, matrixTarget: GLenum):
        self.setMatrixTarget(matrixTarget)
        glPushMatrix()

    def pushMatrix[type: AnyType, _Flags: Int](inout self, mat: Matrix[type, 4, 4, _Flags, 4, 4], matrixTarget: GLenum):
        self.pushMatrix(matrixTarget)
        if _Flags & Eigen.RowMajorBit:
            GlMatrixHelper[True, _Flags].loadMatrix(mat)
        else:
            GlMatrixHelper[False, _Flags].loadMatrix(mat)

    def pushMatrix[type: AnyType, Derived: AnyType](inout self, mat: CwiseNullaryOp[scalar_identity_op[type], Derived], matrixTarget: GLenum):
        self.pushMatrix(matrixTarget)
        glLoadIdentity()

    def popMatrix(inout self, matrixTarget: GLenum):
        self.setMatrixTarget(matrixTarget)
        glPopMatrix()

    def draw(inout self, mode: GLenum, nofElement: uint):
        glDrawArrays(mode, 0, nofElement)

    def draw(inout self, mode: GLenum, pIndexes: Pointer[uint]):
        glDrawElements(mode, pIndexes.size, GL_UNSIGNED_INT, pIndexes)

    def draw(inout self, mode: GLenum, start: uint, end: uint):
        glDrawArrays(mode, start, end - start)

var gpu = GpuHelper()