from Eigen import (
    Vector3f, Quaternionf, Affine3f, Matrix4f, Matrix3f,
    Translation3f, Vector4f, Vector2f,
)
from gpuhelper import gpu
from OpenGL import glViewport, GL_PROJECTION, GL_MODELVIEW
from math import tan, M_PI

struct Frame:
    var orientation: Quaternionf
    var position: Vector3f

    def __init__(inout self, pos: Vector3f = Vector3f.Zero(), o: Quaternionf = Quaternionf()):
        self.orientation = o
        self.position = pos

    def lerp(self, alpha: Float32, other: Frame) -> Frame:
        return Frame(
            (1.0 - alpha) * self.position + alpha * other.position,
            self.orientation.slerp(alpha, other.orientation),
        )

struct Camera:
    var mVpX: UInt32
    var mVpY: UInt32
    var mVpWidth: UInt32
    var mVpHeight: UInt32
    var mFrame: Frame
    var mViewMatrix: Affine3f
    var mProjectionMatrix: Matrix4f
    var mViewIsUptodate: Bool
    var mProjIsUptodate: Bool
    var mTarget: Vector3f
    var mFovY: Float32
    var mNearDist: Float32
    var mFarDist: Float32

    def __init__(inout self):
        self.mViewIsUptodate = False
        self.mProjIsUptodate = False
        self.mViewMatrix.setIdentity()
        self.mFovY = M_PI / 3.0
        self.mNearDist = 1.0
        self.mFarDist = 50000.0
        self.mVpX = 0
        self.mVpY = 0
        self.setPosition(Vector3f.Constant(100.0))
        self.setTarget(Vector3f.Zero())

    def __copyinit__(inout self, other: Self):
        self.mViewIsUptodate = False
        self.mProjIsUptodate = False
        self.mVpX = other.mVpX
        self.mVpY = other.mVpY
        self.mVpWidth = other.mVpWidth
        self.mVpHeight = other.mVpHeight
        self.mTarget = other.mTarget
        self.mFovY = other.mFovY
        self.mNearDist = other.mNearDist
        self.mFarDist = other.mFarDist
        self.mViewMatrix = other.mViewMatrix
        self.mProjectionMatrix = other.mProjectionMatrix

    def __del__(owned self):

    def op_assign(inout self, other: Self) -> Self:
        self.mViewIsUptodate = False
        self.mProjIsUptodate = False
        self.mVpX = other.mVpX
        self.mVpY = other.mVpY
        self.mVpWidth = other.mVpWidth
        self.mVpHeight = other.mVpHeight
        self.mTarget = other.mTarget
        self.mFovY = other.mFovY
        self.mNearDist = other.mNearDist
        self.mFarDist = other.mFarDist
        self.mViewMatrix = other.mViewMatrix
        self.mProjectionMatrix = other.mProjectionMatrix
        return self

    def setViewport(inout self, offsetx: UInt32, offsety: UInt32, width: UInt32, height: UInt32):
        self.mVpX = offsetx
        self.mVpY = offsety
        self.mVpWidth = width
        self.mVpHeight = height
        self.mProjIsUptodate = False

    def setViewport(inout self, width: UInt32, height: UInt32):
        self.mVpWidth = width
        self.mVpHeight = height
        self.mProjIsUptodate = False

    def vpX(self) -> UInt32:
        return self.mVpX

    def vpY(self) -> UInt32:
        return self.mVpY

    def vpWidth(self) -> UInt32:
        return self.mVpWidth

    def vpHeight(self) -> UInt32:
        return self.mVpHeight

    def fovY(self) -> Float32:
        return self.mFovY

    def setFovY(inout self, value: Float32):
        self.mFovY = value
        self.mProjIsUptodate = False

    def setPosition(inout self, pos: Vector3f):
        self.mFrame.position = pos
        self.mViewIsUptodate = False

    def position(self) -> Vector3f:
        return self.mFrame.position

    def setOrientation(inout self, q: Quaternionf):
        self.mFrame.orientation = q
        self.mViewIsUptodate = False

    def orientation(self) -> Quaternionf:
        return self.mFrame.orientation

    def setFrame(inout self, f: Frame):
        self.mFrame = f
        self.mViewIsUptodate = False

    def frame(self) -> Frame:
        return self.mFrame

    def setDirection(inout self, newDirection: Vector3f):
        var up: Vector3f = self.up()
        var camAxes: Matrix3f = Matrix3f()
        camAxes.col(2) = (-newDirection).normalized()
        camAxes.col(0) = up.cross(camAxes.col(2)).normalized()
        camAxes.col(1) = camAxes.col(2).cross(camAxes.col(0)).normalized()
        self.setOrientation(Quaternionf(camAxes))
        self.mViewIsUptodate = False

    def direction(self) -> Vector3f:
        return -(self.orientation() * Vector3f.UnitZ())

    def setUp(inout self, vectorUp: Vector3f):
        # Not implemented? Original header has setUp but no implementation in .cpp? Actually header declares setUp but .cpp has setDirection etc. but not setUp. We'll leave as placeholder.

    def up(self) -> Vector3f:
        return self.orientation() * Vector3f.UnitY()

    def right(self) -> Vector3f:
        return self.orientation() * Vector3f.UnitX()

    def setTarget(inout self, target: Vector3f):
        self.mTarget = target
        if not self.mTarget.isApprox(self.position()):
            var newDirection: Vector3f = self.mTarget - self.position()
            self.setDirection(newDirection.normalized())

    def target(self) -> Vector3f:
        return self.mTarget

    def viewMatrix(inout self) -> Affine3f:
        self.updateViewMatrix()
        return self.mViewMatrix

    def projectionMatrix(inout self) -> Matrix4f:
        self.updateProjectionMatrix()
        return self.mProjectionMatrix

    def rotateAroundTarget(inout self, q: Quaternionf):
        var mrot: Matrix4f = Matrix4f()
        var mt: Matrix4f = Matrix4f()
        var mtm: Matrix4f = Matrix4f()
        self.updateViewMatrix()
        var t: Vector3f = self.mViewMatrix * self.mTarget
        self.mViewMatrix = Translation3f(t) * q * Translation3f(-t) * self.mViewMatrix
        var qa: Quaternionf = Quaternionf(self.mViewMatrix.linear())
        qa = qa.conjugate()
        self.setOrientation(qa)
        self.setPosition(-(qa * self.mViewMatrix.translation()))
        self.mViewIsUptodate = True

    def localRotate(inout self, q: Quaternionf):
        var dist: Float32 = (self.position() - self.mTarget).norm()
        self.setOrientation(self.orientation() * q)
        self.mTarget = self.position() + dist * self.direction()
        self.mViewIsUptodate = False

    def zoom(inout self, d: Float32):
        var dist: Float32 = (self.position() - self.mTarget).norm()
        if dist > d:
            self.setPosition(self.position() + self.direction() * d)
            self.mViewIsUptodate = False

    def localTranslate(inout self, t: Vector3f):
        var trans: Vector3f = self.orientation() * t
        self.setPosition(self.position() + trans)
        self.setTarget(self.mTarget + trans)
        self.mViewIsUptodate = False

    def updateViewMatrix(inout self):
        if not self.mViewIsUptodate:
            var q: Quaternionf = self.orientation().conjugate()
            self.mViewMatrix.linear() = q.toRotationMatrix()
            self.mViewMatrix.translation() = -(self.mViewMatrix.linear() * self.position())
            self.mViewIsUptodate = True

    def updateProjectionMatrix(inout self):
        if not self.mProjIsUptodate:
            self.mProjectionMatrix.setIdentity()
            var aspect: Float32 = Float32(self.mVpWidth) / Float32(self.mVpHeight)
            var theta: Float32 = self.mFovY * 0.5
            var range: Float32 = self.mFarDist - self.mNearDist
            var invtan: Float32 = 1.0 / tan(theta)
            self.mProjectionMatrix(0, 0) = invtan / aspect
            self.mProjectionMatrix(1, 1) = invtan
            self.mProjectionMatrix(2, 2) = -(self.mNearDist + self.mFarDist) / range
            self.mProjectionMatrix(3, 2) = -1.0
            self.mProjectionMatrix(2, 3) = -2.0 * self.mNearDist * self.mFarDist / range
            self.mProjectionMatrix(3, 3) = 0.0
            self.mProjIsUptodate = True

    def activateGL(inout self):
        glViewport(self.vpX(), self.vpY(), self.vpWidth(), self.vpHeight())
        gpu.loadMatrix(self.projectionMatrix(), GL_PROJECTION)
        gpu.loadMatrix(self.viewMatrix().matrix(), GL_MODELVIEW)

    def unProject(inout self, uv: Vector2f, depth: Float32) -> Vector3f:
        var inv: Matrix4f = self.mViewMatrix.inverse().matrix()
        return self.unProject(uv, depth, inv)

    def unProject(inout self, uv: Vector2f, depth: Float32, invModelview: Matrix4f) -> Vector3f:
        self.updateViewMatrix()
        self.updateProjectionMatrix()
        var a: Vector3f = Vector3f(
            2.0 * uv.x() / Float32(self.mVpWidth) - 1.0,
            2.0 * uv.y() / Float32(self.mVpHeight) - 1.0,
            1.0,
        )
        a.x() *= depth / self.mProjectionMatrix(0, 0)
        a.y() *= depth / self.mProjectionMatrix(1, 1)
        a.z() = -depth
        var b: Vector4f = invModelview * Vector4f(a.x(), a.y(), a.z(), 1.0)
        return Vector3f(b.x(), b.y(), b.z())