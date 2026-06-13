from gpuhelper import *
from camera import *
from trackball import *
from icosphere import *
from Eigen.Geometry import *
from Eigen.QR import *
from Eigen.LU import *
from QTimer import *
from QApplication import *
from QGLWidget import *
from QMainWindow import *
from QEvent import *
from QMouseEvent import *
from QInputDialog import *
from QGridLayout import *
from QButtonGroup import *
from QRadioButton import *
from QDockWidget import *
from QPushButton import *
from QGroupBox import *
from QSizePolicy import *
from QVBoxLayout import *
from QWidget import *
from QKeyEvent import *
from QObject import *
from QFlags import *
from QSpacerItem import *
from iostream import *
from cmath import *
from vector import *
from map import *
from algorithm import *

class FancySpheres:
    def __init__(self):
        levels = 4
        scale = 0.33
        radius = 100.0
        parents = List[int]()
        self.mCenters = List[Vector3f]()
        self.mRadii = List[float]()
        self.mIcoSphere = IcoSphere()
        self.mCenters.append(Vector3f.Zero())
        parents.append(-1)
        self.mRadii.append(radius)
        radius *= 0.45
        dist = self.mRadii[0] * 0.9
        for i in range(12):
            self.mCenters.append(self.mIcoSphere.vertices()[i] * dist)
            self.mRadii.append(radius)
            parents.append(0)
        angles = [0.0, 0.0, 3.141592653589793, 0.0, 3.141592653589793, 0.5 * 3.141592653589793, 3.141592653589793, 1.0 * 3.141592653589793, 3.141592653589793, 1.5 * 3.141592653589793]
        start = 1
        for l in range(1, levels):
            radius *= scale
            end = len(self.mCenters)
            for i in range(start, end):
                c = self.mCenters[i]
                ax0 = (c - self.mCenters[parents[i]]).normalized()
                ax1 = ax0.unitOrthogonal()
                q = Quaternionf()
                q.setFromTwoVectors(Vector3f.UnitZ(), ax0)
                t = Translation3f(c) * q * Scaling(self.mRadii[i] + radius)
                for j in range(5):
                    newC = c + ((AngleAxisf(angles[j*2+1], ax0) * AngleAxisf(angles[j*2+0] * (0.35 if l == 1 else 0.5), ax1)) * ax0) * (self.mRadii[i] + radius * 0.8)
                    self.mCenters.append(newC)
                    self.mRadii.append(radius)
                    parents.append(i)
            start = end

    def draw(self):
        end = len(self.mCenters)
        glEnable(GL_NORMALIZE)
        for i in range(end):
            t = Translation3f(self.mCenters[i]) * Scaling(self.mRadii[i])
            gpu.pushMatrix(GL_MODELVIEW)
            gpu.multMatrix(t.matrix(), GL_MODELVIEW)
            self.mIcoSphere.draw(2)
            gpu.popMatrix(GL_MODELVIEW)
        glDisable(GL_NORMALIZE)

def lerp(t: float, a: T, b: T) -> T:
    return a * (1 - t) + b * t

def lerp_quaternionf(t: float, a: Quaternionf, b: Quaternionf) -> Quaternionf:
    return a.slerp(t, b)

def lerpFrame(alpha: float, a: Frame, b: Frame) -> Frame:
    return Frame(lerp(alpha, a.position, b.position), Quaternionf(lerp(alpha, OrientationType(a.orientation), OrientationType(b.orientation))))

class EulerAngles:
    Dim = 3
    Scalar = _Scalar
    Matrix3 = Matrix[Scalar, 3, 3]
    Vector3 = Matrix[Scalar, 3, 1]
    QuaternionType = Quaternion[Scalar]

    def __init__(self):
        self.m_angles = Vector3()

    def __init__(self, a0: Scalar, a1: Scalar, a2: Scalar):
        self.m_angles = Vector3(a0, a1, a2)

    def __init__(self, q: QuaternionType):
        self.m_angles = Vector3()
        self = q

    def coeffs(self) -> Vector3:
        return self.m_angles

    def coeffs_mut(self) -> Vector3:
        return self.m_angles

    def __setitem__(self, q: QuaternionType):
        m = q.toRotationMatrix()
        self = m

    def __setitem__(self, m: Matrix3):
        self.m_angles.coeffRef(1) = asin(m.coeff(0, 2))
        self.m_angles.coeffRef(0) = atan2(-m.coeff(1, 2), m.coeff(2, 2))
        self.m_angles.coeffRef(2) = atan2(-m.coeff(0, 1), m.coeff(0, 0))

    def toRotationMatrix(self) -> Matrix3:
        c = self.m_angles.array().cos()
        s = self.m_angles.array().sin()
        res = Matrix3()
        res << c.y() * c.z(), -c.y() * s.z(), s.y(), c.z() * s.x() * s.y() + c.x() * s.z(), c.x() * c.z() - s.x() * s.y() * s.z(), -c.y() * s.x(), -c.x() * c.z() * s.y() + s.x() * s.z(), c.z() * s.x() + c.x() * s.y() * s.z(), c.x() * c.y()
        return res

    def __to_quaternion(self) -> QuaternionType:
        return QuaternionType(self.toRotationMatrix())

def lerp_euler_angles(t: float, a: EulerAngles[float], b: EulerAngles[float]) -> EulerAngles[float]:
    res = EulerAngles[float]()
    res.coeffs_mut() = lerp(t, a.coeffs(), b.coeffs())
    return res

class RenderingWidget(QGLWidget):
    Q_OBJECT

    def __init__(self):
        self.mAnimate = False
        self.mCurrentTrackingMode = TM_NO_TRACK
        self.mNavMode = NavTurnAround
        self.mLerpMode = LerpQuaternion
        self.mRotationMode = RotationStable
        self.mTrackball = Trackball()
        self.mTrackball.setCamera(&self.mCamera)
        self.setFocusPolicy(Qt.ClickFocus)
        self.m_timeline = Dict[float, Frame]()
        self.mInitFrame = Frame()
        self.m_alpha = 0.0
        self.mCamera = Camera()
        self.mMouseCoords = Vector2i()
        self.m_timer = QTimer()
        self.mVertices = List[Vector3f]()
        self.mNormals = List[Vector3f]()
        self.mIndices = List[int]()

    def grabFrame(self):
        ok = False
        t = 0.0
        if len(self.m_timeline) > 0:
            t = (list(self.m_timeline.keys())[-1]) + 1.0
        t = QInputDialog.getDouble(self, "Eigen's RenderingWidget", "time value: ", t, 0, 1e3, 1, &ok)
        if ok:
            aux = Frame()
            aux.orientation = self.mCamera.viewMatrix().linear()
            aux.position = self.mCamera.viewMatrix().translation()
            self.m_timeline[t] = aux

    def drawScene(self):
        sFancySpheres = FancySpheres()
        length = 50.0
        gpu.drawVector(Vector3f.Zero(), length * Vector3f.UnitX(), Color(1, 0, 0, 1))
        gpu.drawVector(Vector3f.Zero(), length * Vector3f.UnitY(), Color(0, 1, 0, 1))
        gpu.drawVector(Vector3f.Zero(), length * Vector3f.UnitZ(), Color(0, 0, 1, 1))
        sqrt3 = sqrt(3.0)
        glLightfv(GL_LIGHT0, GL_AMBIENT, Vector4f(0.5, 0.5, 0.5, 1).data())
        glLightfv(GL_LIGHT0, GL_DIFFUSE, Vector4f(0.5, 1, 0.5, 1).data())
        glLightfv(GL_LIGHT0, GL_SPECULAR, Vector4f(1, 1, 1, 1).data())
        glLightfv(GL_LIGHT0, GL_POSITION, Vector4f(-sqrt3, -sqrt3, sqrt3, 0).data())
        glLightfv(GL_LIGHT1, GL_AMBIENT, Vector4f(0, 0, 0, 1).data())
        glLightfv(GL_LIGHT1, GL_DIFFUSE, Vector4f(1, 0.5, 0.5, 1).data())
        glLightfv(GL_LIGHT1, GL_SPECULAR, Vector4f(1, 1, 1, 1).data())
        glLightfv(GL_LIGHT1, GL_POSITION, Vector4f(-sqrt3, sqrt3, -sqrt3, 0).data())
        glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, Vector4f(0.7, 0.7, 0.7, 1).data())
        glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, Vector4f(0.8, 0.75, 0.6, 1).data())
        glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, Vector4f(1, 1, 1, 1).data())
        glMaterialf(GL_FRONT_AND_BACK, GL_SHININESS, 64)
        glEnable(GL_LIGHTING)
        glEnable(GL_LIGHT0)
        glEnable(GL_LIGHT1)
        sFancySpheres.draw()
        glVertexPointer(3, GL_FLOAT, 0, self.mVertices[0].data())
        glNormalPointer(GL_FLOAT, 0, self.mNormals[0].data())
        glEnableClientState(GL_VERTEX_ARRAY)
        glEnableClientState(GL_NORMAL_ARRAY)
        glDrawArrays(GL_TRIANGLES, 0, len(self.mVertices))
        glDisableClientState(GL_VERTEX_ARRAY)
        glDisableClientState(GL_NORMAL_ARRAY)
        glDisable(GL_LIGHTING)

    def animate(self):
        self.m_alpha += float(self.m_timer.interval()) * 1e-3
        keys = sorted(self.m_timeline.keys())
        hi_idx = 0
        for i, k in enumerate(keys):
            if k > self.m_alpha:
                hi_idx = i
                break
        else:
            hi_idx = len(keys)
        lo_idx = hi_idx - 1
        currentFrame = Frame()
        if hi_idx == len(keys):
            currentFrame = self.m_timeline[keys[lo_idx]]
            self.stopAnimation()
        elif hi_idx == 0:
            currentFrame = self.m_timeline[keys[hi_idx]]
        else:
            s = (self.m_alpha - keys[lo_idx]) / (keys[hi_idx] - keys[lo_idx])
            if self.mLerpMode == LerpEulerAngles:
                currentFrame = lerpFrame[EulerAngles[float]](s, self.m_timeline[keys[lo_idx]], self.m_timeline[keys[hi_idx]])
            elif self.mLerpMode == LerpQuaternion:
                currentFrame = lerpFrame[Quaternionf](s, self.m_timeline[keys[lo_idx]], self.m_timeline[keys[hi_idx]])
            else:
                print("Invalid rotation interpolation mode (abort)", file=stderr)
                exit(2)
            currentFrame.orientation.coeffs().normalize()
        currentFrame.orientation = currentFrame.orientation.inverse()
        currentFrame.position = -(currentFrame.orientation * currentFrame.position)
        self.mCamera.setFrame(currentFrame)
        self.updateGL()

    def keyPressEvent(self, e: QKeyEvent):
        if e.key() == Qt.Key_Up:
            self.mCamera.zoom(2)
        elif e.key() == Qt.Key_Down:
            self.mCamera.zoom(-2)
        elif e.key() == Qt.Key_G:
            self.grabFrame()
        elif e.key() == Qt.Key_C:
            self.m_timeline.clear()
        elif e.key() == Qt.Key_R:
            self.resetCamera()
        elif e.key() == Qt.Key_A:
            if self.mAnimate:
                self.stopAnimation()
            else:
                self.m_alpha = 0
                self.m_timer.timeout.connect(self.animate)
                self.m_timer.start(1000 // 30)
                self.mAnimate = True
        self.updateGL()

    def stopAnimation(self):
        self.m_timer.timeout.disconnect(self.animate)
        self.m_timer.stop()
        self.mAnimate = False
        self.m_alpha = 0

    def mousePressEvent(self, e: QMouseEvent):
        self.mMouseCoords = Vector2i(e.pos().x(), e.pos().y())
        fly = (self.mNavMode == NavFly) or ((e.modifiers() & Qt.ControlModifier) != 0)
        if e.button() == Qt.LeftButton:
            if fly:
                self.mCurrentTrackingMode = TM_LOCAL_ROTATE
                self.mTrackball.start(Trackball.Local)
            else:
                self.mCurrentTrackingMode = TM_ROTATE_AROUND
                self.mTrackball.start(Trackball.Around)
            self.mTrackball.track(self.mMouseCoords)
        elif e.button() == Qt.MidButton:
            if fly:
                self.mCurrentTrackingMode = TM_FLY_Z
            else:
                self.mCurrentTrackingMode = TM_ZOOM
        elif e.button() == Qt.RightButton:
            self.mCurrentTrackingMode = TM_FLY_PAN

    def mouseReleaseEvent(self, e: QMouseEvent):
        self.mCurrentTrackingMode = TM_NO_TRACK
        self.updateGL()

    def mouseMoveEvent(self, e: QMouseEvent):
        if self.mCurrentTrackingMode != TM_NO_TRACK:
            dx = float(e.x() - self.mMouseCoords.x()) / float(self.mCamera.vpWidth())
            dy = -float(e.y() - self.mMouseCoords.y()) / float(self.mCamera.vpHeight())
            if (e.modifiers() & Qt.ShiftModifier) != 0:
                dx *= 10.0
                dy *= 10.0
            if self.mCurrentTrackingMode == TM_ROTATE_AROUND or self.mCurrentTrackingMode == TM_LOCAL_ROTATE:
                if self.mRotationMode == RotationStable:
                    self.mTrackball.track(Vector2i(e.pos().x(), e.pos().y()))
                else:
                    q = AngleAxisf(dx * 3.141592653589793, Vector3f.UnitY()) * AngleAxisf(-dy * 3.141592653589793, Vector3f.UnitX())
                    if self.mCurrentTrackingMode == TM_LOCAL_ROTATE:
                        self.mCamera.localRotate(q)
                    else:
                        self.mCamera.rotateAroundTarget(q)
            elif self.mCurrentTrackingMode == TM_ZOOM:
                self.mCamera.zoom(dy * 100)
            elif self.mCurrentTrackingMode == TM_FLY_Z:
                self.mCamera.localTranslate(Vector3f(0, 0, -dy * 200))
            elif self.mCurrentTrackingMode == TM_FLY_PAN:
                self.mCamera.localTranslate(Vector3f(dx * 200, dy * 200, 0))
            self.updateGL()
        self.mMouseCoords = Vector2i(e.pos().x(), e.pos().y())

    def paintGL(self):
        glEnable(GL_DEPTH_TEST)
        glDisable(GL_CULL_FACE)
        glPolygonMode(GL_FRONT_AND_BACK, GL_FILL)
        glDisable(GL_COLOR_MATERIAL)
        glDisable(GL_BLEND)
        glDisable(GL_ALPHA_TEST)
        glDisable(GL_TEXTURE_1D)
        glDisable(GL_TEXTURE_2D)
        glDisable(GL_TEXTURE_3D)
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
        self.mCamera.activateGL()
        self.drawScene()

    def initializeGL(self):
        glClearColor(1.0, 1.0, 1.0, 0.0)
        glLightModeli(GL_LIGHT_MODEL_LOCAL_VIEWER, 1)
        glDepthMask(GL_TRUE)
        glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE)
        self.mCamera.setPosition(Vector3f(-200, -200, -200))
        self.mCamera.setTarget(Vector3f(0, 0, 0))
        self.mInitFrame.orientation = self.mCamera.orientation().inverse()
        self.mInitFrame.position = self.mCamera.viewMatrix().translation()

    def resizeGL(self, width: int, height: int):
        self.mCamera.setViewport(width, height)

    def setNavMode(self, m: int):
        self.mNavMode = NavMode(m)

    def setLerpMode(self, m: int):
        self.mLerpMode = LerpMode(m)

    def setRotationMode(self, m: int):
        self.mRotationMode = RotationMode(m)

    def resetCamera(self):
        if self.mAnimate:
            self.stopAnimation()
        self.m_timeline.clear()
        aux0 = self.mCamera.frame()
        aux0.orientation = aux0.orientation.inverse()
        aux0.position = self.mCamera.viewMatrix().translation()
        self.m_timeline[0] = aux0
        currentTarget = self.mCamera.target()
        self.mCamera.setTarget(Vector3f.Zero())
        aux1 = self.mCamera.frame()
        aux1.orientation = aux1.orientation.inverse()
        aux1.position = self.mCamera.viewMatrix().translation()
        duration = aux0.orientation.angularDistance(aux1.orientation) * 0.9
        if duration < 0.1:
            duration = 0.1
        aux1 = aux0.lerp(duration / 2, self.mInitFrame)
        aux1.orientation = aux1.orientation.inverse()
        aux1.position = -(aux1.orientation * aux1.position)
        self.mCamera.setFrame(aux1)
        self.mCamera.setTarget(Vector3f.Zero())
        aux1.orientation = aux1.orientation.inverse()
        aux1.position = self.mCamera.viewMatrix().translation()
        self.m_timeline[duration] = aux1
        self.m_timeline[2] = self.mInitFrame
        self.m_alpha = 0
        self.animate()
        self.m_timer.timeout.connect(self.animate)
        self.m_timer.start(1000 // 30)
        self.mAnimate = True

    def createNavigationControlWidget(self) -> QWidget:
        panel = QWidget()
        layout = QVBoxLayout()
        but = QPushButton("reset")
        but.setToolTip("move the camera to initial position (with animation)")
        layout.addWidget(but)
        but.clicked.connect(self.resetCamera)
        box = QGroupBox("navigation mode")
        boxLayout = QVBoxLayout()
        group = QButtonGroup(panel)
        but = QRadioButton("turn around")
        but.setToolTip("look around an object")
        group.addButton(but, NavTurnAround)
        boxLayout.addWidget(but)
        but = QRadioButton("fly")
        but.setToolTip("free navigation like a spaceship\n(this mode can also be enabled pressing the \"shift\" key)")
        group.addButton(but, NavFly)
        boxLayout.addWidget(but)
        group.button(self.mNavMode).setChecked(True)
        group.buttonClicked.connect(self.setNavMode)
        box.setLayout(boxLayout)
        layout.addWidget(box)
        box = QGroupBox("rotation mode")
        boxLayout = QVBoxLayout()
        group = QButtonGroup(panel)
        but = QRadioButton("stable trackball")
        group.addButton(but, RotationStable)
        boxLayout.addWidget(but)
        but.setToolTip("use the stable trackball implementation mapping\nthe 2D coordinates to 3D points on a sphere")
        but = QRadioButton("standard rotation")
        group.addButton(but, RotationStandard)
        boxLayout.addWidget(but)
        but.setToolTip("standard approach mapping the x and y displacements\nas rotations around the camera's X and Y axes")
        group.button(self.mRotationMode).setChecked(True)
        group.buttonClicked.connect(self.setRotationMode)
        box.setLayout(boxLayout)
        layout.addWidget(box)
        box = QGroupBox("spherical interpolation")
        boxLayout = QVBoxLayout()
        group = QButtonGroup(panel)
        but = QRadioButton("quaternion slerp")
        group.addButton(but, LerpQuaternion)
        boxLayout.addWidget(but)
        but.setToolTip("use quaternion spherical interpolation\nto interpolate orientations")
        but = QRadioButton("euler angles")
        group.addButton(but, LerpEulerAngles)
        boxLayout.addWidget(but)
        but.setToolTip("use Euler angles to interpolate orientations")
        group.button(self.mNavMode).setChecked(True)
        group.buttonClicked.connect(self.setLerpMode)
        box.setLayout(boxLayout)
        layout.addWidget(box)
        layout.addItem(QSpacerItem(0, 0, QSizePolicy.Minimum, QSizePolicy.Expanding))
        panel.setLayout(layout)
        return panel

class QuaternionDemo(QMainWindow):
    Q_OBJECT

    def __init__(self):
        self.mRenderingWidget = RenderingWidget()
        self.setCentralWidget(self.mRenderingWidget)
        panel = QDockWidget("navigation", self)
        panel.setAllowedAreas(Qt.RightDockWidgetArea | Qt.LeftDockWidgetArea)
        self.addDockWidget(Qt.RightDockWidgetArea, panel)
        panel.setWidget(self.mRenderingWidget.createNavigationControlWidget())

def main(argc: int, argv: List[String]):
    print("Navigation:")
    print("  left button:           rotate around the target")
    print("  middle button:         zoom")
    print("  left button + ctrl     quake rotate (rotate around camera position)")
    print("  middle button + ctrl   walk (progress along camera's z direction)")
    print("  left button:           pan (translate in the XY camera's plane)")
    print("")
    print("R : move the camera to initial position")
    print("A : start/stop animation")
    print("C : clear the animation")
    print("G : add a key frame")
    app = QApplication(argc, argv)
    demo = QuaternionDemo()
    demo.resize(600, 500)
    demo.show()
    return app.exec()