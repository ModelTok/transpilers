from camera import Camera
from Eigen import Vector2i, Vector3f, Quaternionf, AngleAxisf
from math import sin, acos, sqrt, pi

class Trackball:
    enum Mode:
        Around
        Local

    def __init__(inout self):
        self.mpCamera = None
        self.mLastPoint3D = Vector3f()
        self.mMode = Mode.Around
        self.mLastPointOk = False

    def start(inout self, m: Mode = Mode.Around):
        self.mMode = m
        self.mLastPointOk = False

    def setCamera(inout self, pCam: Camera):
        self.mpCamera = pCam

    def track(inout self, point2D: Vector2i):
        if self.mpCamera is None:
            return
        var newPoint3D = Vector3f()
        var newPointOk = self.mapToSphere(point2D, newPoint3D)
        if self.mLastPointOk and newPointOk:
            var axis = self.mLastPoint3D.cross(newPoint3D).normalized()
            var cos_angle = self.mLastPoint3D.dot(newPoint3D)
            if abs(cos_angle) < 1.0:
                var angle = 2.0 * acos(cos_angle)
                if self.mMode == Mode.Around:
                    self.mpCamera!.rotateAroundTarget(Quaternionf(AngleAxisf(angle, axis)))
                else:
                    self.mpCamera!.localRotate(Quaternionf(AngleAxisf(-angle, axis)))
        self.mLastPoint3D = newPoint3D
        self.mLastPointOk = newPointOk

    def mapToSphere(inout self, p2: Vector2i, inout v3: Vector3f) -> Bool:
        if (p2.x() >= 0) and (p2.x() <= Int(self.mpCamera!.vpWidth())) and (p2.y() >= 0) and (p2.y() <= Int(self.mpCamera!.vpHeight())):
            var x = Float64(p2.x() - 0.5 * self.mpCamera!.vpWidth()) / Float64(self.mpCamera!.vpWidth())
            var y = Float64(0.5 * self.mpCamera!.vpHeight() - p2.y()) / Float64(self.mpCamera!.vpHeight())
            var sinx = sin(pi * x * 0.5)
            var siny = sin(pi * y * 0.5)
            var sinx2siny2 = sinx * sinx + siny * siny
            v3.x = sinx
            v3.y = siny
            v3.z = sqrt(1.0 - sinx2siny2) if sinx2siny2 < 1.0 else 0.0
            return True
        else:
            return False