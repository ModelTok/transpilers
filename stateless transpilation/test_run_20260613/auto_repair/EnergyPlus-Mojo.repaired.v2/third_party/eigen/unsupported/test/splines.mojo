from main import main, g_repeat, CALL_SUBTEST, VERIFY, VERIFY_IS_APPROX
from unsupported.Eigen.Splines import Spline, SplineFitting, ChordLengths, RowVectorXd, MatrixXd, VectorXd, Vector2d, Vector3d, ArrayXXd, DenseIndex

def closed_spline2d() -> Spline[float64, 2, Dynamic]:
    var knots = RowVectorXd(12)
    knots = RowVectorXd([0.0,
        0.0,
        0.0,
        0.0,
        0.867193179093898,
        1.660330955342408,
        2.605084834823134,
        3.484154586374428,
        4.252699478956276,
        4.252699478956276,
        4.252699478956276,
        4.252699478956276])
    var ctrls = MatrixXd(8, 2)
    ctrls = MatrixXd([[-0.370967741935484,   0.236842105263158],
        [-0.231401860693277,   0.442245185027632],
        [0.344361228532831,   0.773369994120753],
        [0.828990216203802,   0.106550882647595],
        [0.407270163678382,  -1.043452922172848],
        [-0.488467813584053,  -0.390098582530090],
        [-0.494657189446427,   0.054804824897884],
        [-0.370967741935484,   0.236842105263158]])
    ctrls.transposeInPlace()
    return Spline[float64, 2, Dynamic](knots, ctrls)

def spline3d() -> Spline[float64, 3, Dynamic]:
    var knots = RowVectorXd(11)
    knots = RowVectorXd([0.0,
        0.0,
        0.0,
        0.118997681558377,
        0.162611735194631,
        0.498364051982143,
        0.655098003973841,
        0.679702676853675,
        1.000000000000000,
        1.000000000000000,
        1.000000000000000])
    var ctrls = MatrixXd(8, 3)
    ctrls = MatrixXd([[0.959743958516081,   0.340385726666133,   0.585267750979777],
        [0.223811939491137,   0.751267059305653,   0.255095115459269],
        [0.505957051665142,   0.699076722656686,   0.890903252535799],
        [0.959291425205444,   0.547215529963803,   0.138624442828679],
        [0.149294005559057,   0.257508254123736,   0.840717255983663],
        [0.254282178971531,   0.814284826068816,   0.243524968724989],
        [0.929263623187228,   0.349983765984809,   0.196595250431208],
        [0.251083857976031,   0.616044676146639,   0.473288848902729]])
    ctrls.transposeInPlace()
    return Spline[float64, 3, Dynamic](knots, ctrls)

def eval_spline3d():
    var spline = spline3d()
    var u = RowVectorXd(10)
    u = RowVectorXd([0.351659507062997,
        0.830828627896291,
        0.585264091152724,
        0.549723608291140,
        0.917193663829810,
        0.285839018820374,
        0.757200229110721,
        0.753729094278495,
        0.380445846975357,
        0.567821640725221])
    var pts = MatrixXd(10, 3)
    pts = MatrixXd([[0.707620811535916,   0.510258911240815,   0.417485437023409],
        [0.603422256426978,   0.529498282727551,   0.270351549348981],
        [0.228364197569334,   0.423745615677815,   0.637687289287490],
        [0.275556796335168,   0.350856706427970,   0.684295784598905],
        [0.514519311047655,   0.525077224890754,   0.351628308305896],
        [0.724152914315666,   0.574461155457304,   0.469860285484058],
        [0.529365063753288,   0.613328702656816,   0.237837040141739],
        [0.522469395136878,   0.619099658652895,   0.237139665242069],
        [0.677357023849552,   0.480655768435853,   0.422227610314397],
        [0.247046593173758,   0.380604672404750,   0.670065791405019]])
    pts.transposeInPlace()
    for i in range(u.size()):
        var pt = spline(u[i])
        VERIFY((pt - pts.col(i)).norm() < 1e-14)

def eval_spline3d_onbrks():
    var spline = spline3d()
    var u = spline.knots()
    var pts = MatrixXd(11, 3)
    pts = MatrixXd([[0.959743958516081,   0.340385726666133,   0.585267750979777],
        [0.959743958516081,   0.340385726666133,   0.585267750979777],
        [0.959743958516081,   0.340385726666133,   0.585267750979777],
        [0.430282980289940,   0.713074680056118,   0.720373307943349],
        [0.558074875553060,   0.681617921034459,   0.804417124839942],
        [0.407076008291750,   0.349707710518163,   0.617275937419545],
        [0.240037008286602,   0.738739390398014,   0.324554153129411],
        [0.302434111480572,   0.781162443963899,   0.240177089094644],
        [0.251083857976031,   0.616044676146639,   0.473288848902729],
        [0.251083857976031,   0.616044676146639,   0.473288848902729],
        [0.251083857976031,   0.616044676146639,   0.473288848902729]])
    pts.transposeInPlace()
    for i in range(u.size()):
        var pt = spline(u[i])
        VERIFY((pt - pts.col(i)).norm() < 1e-14)

def eval_closed_spline2d():
    var spline = closed_spline2d()
    var u = RowVectorXd(12)
    u = RowVectorXd([0.0,
        0.332457030395796,
        0.356467130532952,
        0.453562180176215,
        0.648017921874804,
        0.973770235555003,
        1.882577647219307,
        2.289408593930498,
        3.511951429883045,
        3.884149321369450,
        4.236261590369414,
        4.252699478956276])
    var pts = MatrixXd(12, 2)
    pts = MatrixXd([[-0.370967741935484,   0.236842105263158],
        [-0.152576775123250,   0.448975001279334],
        [-0.133417538277668,   0.461615613865667],
        [-0.053199060826740,   0.507630360006299],
        [0.114249591147281,   0.570414135097409],
        [0.377810316891987,   0.560497102875315],
        [0.665052120135908,  -0.157557441109611],
        [0.516006487053228,  -0.559763292174825],
        [-0.379486035348887,  -0.331959640488223],
        [-0.462034726249078,  -0.039105670080824],
        [-0.378730600917982,   0.225127015099919],
        [-0.370967741935484,   0.236842105263158]])
    pts.transposeInPlace()
    for i in range(u.size()):
        var pt = spline(u[i])
        VERIFY((pt - pts.col(i)).norm() < 1e-14)

def check_global_interpolation2d():
    alias PointType = Spline2d.PointType
    alias KnotVectorType = Spline2d.KnotVectorType
    alias ControlPointVectorType = Spline2d.ControlPointVectorType
    var points = ControlPointVectorType.Random(2, 100)
    var chord_lengths = KnotVectorType()
    ChordLengths(points, chord_lengths)
    {
        var spline = SplineFitting[Spline2d].Interpolate(points, 3)
        for i in range(points.cols()):
            var pt = spline(chord_lengths[i])
            var ref = points.col(i)
            VERIFY((pt - ref).matrix().norm() < 1e-14)
    }
    {
        var spline = SplineFitting[Spline2d].Interpolate(points, 3, chord_lengths)
        for i in range(points.cols()):
            var pt = spline(chord_lengths[i])
            var ref = points.col(i)
            VERIFY((pt - ref).matrix().norm() < 1e-14)
    }

def check_global_interpolation_with_derivatives2d():
    alias PointType = Spline2d.PointType
    alias KnotVectorType = Spline2d.KnotVectorType
    var numPoints = 100
    var dimension = 2
    var degree = 3
    var points = ArrayXXd.Random(dimension, numPoints)
    var knots = KnotVectorType()
    ChordLengths(points, knots)
    var derivatives = ArrayXXd.Random(dimension, numPoints)
    var derivativeIndices = VectorXd(numPoints)
    for i in range(numPoints):
        derivativeIndices[i] = float64(i)
    var spline = SplineFitting[Spline2d].InterpolateWithDerivatives(
        points, derivatives, derivativeIndices, degree)
    for i in range(points.cols()):
        var point = spline(knots[i])
        var referencePoint = points.col(i)
        VERIFY_IS_APPROX(point, referencePoint)
        var derivative = spline.derivatives(knots[i], 1).col(1)
        var referenceDerivative = derivatives.col(i)
        VERIFY_IS_APPROX(derivative, referenceDerivative)

def test_splines():
    for i in range(g_repeat):
        CALL_SUBTEST(eval_spline3d)
        CALL_SUBTEST(eval_spline3d_onbrks)
        CALL_SUBTEST(eval_closed_spline2d)
        CALL_SUBTEST(check_global_interpolation2d)
        CALL_SUBTEST(check_global_interpolation_with_derivatives2d)