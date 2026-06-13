from testing import *
from splinter.datatable import DataTable
from splinter.bspline import BSpline
from splinter.bsplinebuilder import BSplineBuilder

def f1d(x: DenseVector) -> Float64:
    assert(x.rows() == 1)
    return (4 - 2.1*x[0]*x[0]
        + (1 / 3.)*x[0]*x[0]*x[0]*x[0])*x[0]*x[0]

def f(x: DenseVector) -> Float64:
    assert(x.rows() == 2)
    return (4 - 2.1*x[0]*x[0]
        + (1 / 3.)*x[0]*x[0]*x[0]*x[0])*x[0]*x[0]
        + x[0]*x[1]
        + (-4 + 4 * x[1]*x[1])*x[1]*x[1]

@fixture
def testCamelback2d():
    samples = DataTable()
    x = DenseVector(2)
    y: Float64
    for i in range(20):
        for j in range(20):
            x[0] = i * 0.1
            x[1] = j * 0.1
            y = f(x)
            samples.addSample(x, y)
    bspline1 = BSpline.Builder(samples).degree(1).build()
    bspline3 = BSpline.Builder(samples).degree(3).build()
    pspline = BSpline.Builder(samples) \
        .degree(3) \
        .smoothing(BSpline.Smoothing.PSPLINE) \
        .alpha(0.03) \
        .build()
    /* Evaluate the approximants at x = (1,1)
     * Note that the error will be 0 at that point (except for the P-spline, which may introduce an error
     * in favor of a smooth approximation) because it is a point we sampled at.
     */
    x[0] = 0.35; x[1] = 1.68
    func_val = f(x)
    lin_spline = bspline1.eval(x)
    cubic_spline = bspline3.eval(x)
    p_spline = pspline.eval(x)
    expect_almost_equal(lin_spline, func_val, 0.15) << "Linear Spline"
    expect_almost_equal(cubic_spline, func_val, 0.01) << "Cubic Spline"
    expect_almost_equal(p_spline, func_val, 0.1) << "P Spline"
    /*
    cout << "-----------------------------------------------------" << endl;
    cout << "Function at x:                 " << f(x) << endl;
    cout << "Linear B-spline at x:          " << bspline1.eval(x) << endl;
    cout << "Cubic B-spline at x:           " << bspline3.eval(x) << endl;
    cout << "P-spline at x:                 " << pspline.eval(x) << endl;
    cout << "-----------------------------------------------------" << endl;
    */

@fixture
def testCamelback1d():
    samples = DataTable()
    x = DenseVector(1)
    y: Float64
    for i in range(20):
            x[0] = i * 0.1
            y = f1d(x)
            samples.addSample(x, y)
    bspline1 = BSpline.Builder(samples).degree(1).build()
    bspline3 = BSpline.Builder(samples).degree(3).build()
    pspline = BSpline.Builder(samples) \
        .degree(3) \
        .smoothing(BSpline.Smoothing.PSPLINE) \
        .alpha(0.03) \
        .build()
    /* Evaluate the approximants at x = (1,1)
     * Note that the error will be 0 at that point (except for the P-spline, which may introduce an error
     * in favor of a smooth approximation) because it is a point we sampled at.
     */
    x[0] = 0.35
    func_val = f1d(x)
    lin_spline = bspline1.eval(x)
    cubic_spline = bspline3.eval(x)
    p_spline = pspline.eval(x)
    expect_almost_equal(lin_spline, func_val, 0.15) << "Linear Spline"
    expect_almost_equal(cubic_spline, func_val, 0.01) << "Cubic Spline"
    expect_almost_equal(p_spline, func_val, 0.1) << "P Spline"
    /*
    cout << "-----------------------------------------------------" << endl;
    cout << "Function at x:                 " << f1d(x) << endl;
    cout << "Linear B-spline at x:          " << bspline1.eval(x) << endl;
    cout << "Cubic B-spline at x:           " << bspline3.eval(x) << endl;
    cout << "P-spline at x:                 " << pspline.eval(x) << endl;
    cout << "-----------------------------------------------------" << endl;
    */