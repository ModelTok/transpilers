# Translated from C++ to Mojo – faithful 1:1 (no refactoring)
# Original: third_party/eigen/test/mixingtypes.cpp

# Note: Mojo does not have preprocessor; conditionals are preserved as comments.
# Eigen types/functions are assumed available from an "Eigen" module.
# Macros are implemented as Mojo functions.

from Eigen import (
    Matrix, Matrix as Mat_f, Matrix as Mat_d, Matrix as Mat_cf, Matrix as Mat_cd,
    Vec_f, Vec_d, Vec_cf, Vec_cd,
    internal, internal_random,  # for random
    ComplexFloat, ComplexDouble,
    Index, Dynamic,
    VERIFY_IS_APPROX, VERIFY_RAISES_ASSERT,
    CALL_SUBTEST as call_subtest
)
from math import sqrt
from sys import get_float_info
import builtins

# Global flag set by EIGEN_SCALAR_BINARY_OP_PLUGIN
var g_called: Bool = False

# Simulate the plugin macro: define a function that checks scalar types
def mixingtypes_binary_op_plugin[LhsScalar: AnyType, RhsScalar: AnyType]():
    g_called = g_called or (not (LhsScalar == RhsScalar))

# Macro VERIFY_MIX_SCALAR
macro VERIFY_MIX_SCALAR(XPR, REF):
    {||
        g_called = False
        VERIFY_IS_APPROX(XPR, REF)
        if not g_called:
            print("Warning: ", XPR, " not properly optimized")
    }

# raise_assertion template function
def raise_assertion[SizeAtCompileType: Int](size: Index = SizeAtCompileType):
    var vf = Mat_f[SizeAtCompileType, 1]()
    vf.setRandom(size)
    var vd = Mat_d[SizeAtCompileType, 1]()
    vd.setRandom(size)
    VERIFY_RAISES_ASSERT(vf = vd)
    VERIFY_RAISES_ASSERT(vf += vd)
    VERIFY_RAISES_ASSERT(vf -= vd)
    VERIFY_RAISES_ASSERT(vd = vf)
    VERIFY_RAISES_ASSERT(vd += vf)
    VERIFY_RAISES_ASSERT(vd -= vf)
    # // 0: we get other compilation errors here than just static asserts
    # VERIFY_RAISES_ASSERT(vd.dot(vf))

# mixingtypes template function
def mixingtypes[SizeAtCompileType: Int](size: Index = SizeAtCompileType):
    typedef CF = ComplexFloat
    typedef CD = ComplexDouble

    typedef Mat_f = Matrix[Float, SizeAtCompileType, SizeAtCompileType]
    typedef Mat_d = Matrix[Double, SizeAtCompileType, SizeAtCompileType]
    typedef Mat_cf = Matrix[CF, SizeAtCompileType, SizeAtCompileType]
    typedef Mat_cd = Matrix[CD, SizeAtCompileType, SizeAtCompileType]

    typedef Vec_f = Matrix[Float, SizeAtCompileType, 1]
    typedef Vec_d = Matrix[Double, SizeAtCompileType, 1]
    typedef Vec_cf = Matrix[CF, SizeAtCompileType, 1]
    typedef Vec_cd = Matrix[CD, SizeAtCompileType, 1]

    var mf = Mat_f.Random(size, size)
    var md = mf.template cast[Double]()
    var mcf = Mat_cf.Random(size, size)
    var mcd = mcf.template cast[CD]()
    var rcd = mcd

    var vf = Vec_f.Random(size, 1)
    var vd = vf.template cast[Double]()
    var vcf = Vec_cf.Random(size, 1)
    var vcd = vcf.template cast[CD]()

    var sf = internal_random[Float]()
    var sd = internal_random[Double]()
    var scf = internal_random[CF]()
    var scd = internal_random[CD]()

    # mf+mf  // just expression, no assignment – ignore

    var epsf = sqrt(get_float_info[Float].min_value)
    var epsd = sqrt(get_float_info[Double].min_value)

    while builtins.abs(sf) < epsf:
        sf = internal_random[Float]()
    while builtins.abs(sd) < epsd:
        sd = internal_random[Double]()
    while builtins.abs(scf) < epsf:
        scf = internal_random[CF]()
    while builtins.abs(scd) < epsd:
        scd = internal_random[CD]()

    # VERIFY_MIX_SCALAR calls
    VERIFY_MIX_SCALAR(vcf * sf, vcf * CF(sf))
    VERIFY_MIX_SCALAR(sd * vcd, CD(sd) * vcd)
    VERIFY_MIX_SCALAR(vf * scf, vf.template cast[CF]() * scf)
    VERIFY_MIX_SCALAR(scd * vd, scd * vd.template cast[CD]())
    VERIFY_MIX_SCALAR(vcf * 2, vcf * CF(2))
    VERIFY_MIX_SCALAR(vcf * 2.1, vcf * CF(2.1))
    VERIFY_MIX_SCALAR(2 * vcf, vcf * CF(2))
    VERIFY_MIX_SCALAR(2.1 * vcf, vcf * CF(2.1))
    VERIFY_MIX_SCALAR(vcf / sf, vcf / CF(sf))
    VERIFY_MIX_SCALAR(vf / scf, vf.template cast[CF]() / scf)
    VERIFY_MIX_SCALAR(vf.array() / scf, vf.template cast[CF]().array() / scf)
    VERIFY_MIX_SCALAR(scd / vd.array(), scd / vd.template cast[CD]().array())
    VERIFY_MIX_SCALAR(vcf.array() + sf, vcf.array() + CF(sf))
    VERIFY_MIX_SCALAR(sd + vcd.array(), CD(sd) + vcd.array())
    VERIFY_MIX_SCALAR(vf.array() + scf, vf.template cast[CF]().array() + scf)
    VERIFY_MIX_SCALAR(scd + vd.array(), scd + vd.template cast[CD]().array())
    VERIFY_MIX_SCALAR(vcf.array() - sf, vcf.array() - CF(sf))
    VERIFY_MIX_SCALAR(sd - vcd.array(), CD(sd) - vcd.array())
    VERIFY_MIX_SCALAR(vf.array() - scf, vf.template cast[CF]().array() - scf)
    VERIFY_MIX_SCALAR(scd - vd.array(), scd - vd.template cast[CD]().array())
    VERIFY_MIX_SCALAR(pow(vcf.array(), sf), Eigen.pow(vcf.array(), CF(sf)))
    VERIFY_MIX_SCALAR(vcf.array().pow(sf), Eigen.pow(vcf.array(), CF(sf)))
    VERIFY_MIX_SCALAR(pow(sd, vcd.array()), Eigen.pow(CD(sd), vcd.array()))
    VERIFY_MIX_SCALAR(Eigen.pow(vf.array(), scf), Eigen.pow(vf.template cast[CF]().array(), scf))
    VERIFY_MIX_SCALAR(vf.array().pow(scf), Eigen.pow(vf.template cast[CF]().array(), scf))
    VERIFY_MIX_SCALAR(Eigen.pow(scd, vd.array()), Eigen.pow(scd, vd.template cast[CD]().array()))

    # vf.dot(vf) // expression only
    VERIFY_IS_APPROX(vcf.dot(vf), vcf.dot(vf.template cast[CF]()))
    VERIFY_IS_APPROX(vf.asDiagonal() * mcf, vf.template cast[CF]().asDiagonal() * mcf)
    VERIFY_IS_APPROX(vcd.asDiagonal() * md, vcd.asDiagonal() * md.template cast[CD]())
    VERIFY_IS_APPROX(mcf * vf.asDiagonal(), mcf * vf.template cast[CF]().asDiagonal())
    VERIFY_IS_APPROX(md * vcd.asDiagonal(), md.template cast[CD]() * vcd.asDiagonal())
    VERIFY_IS_APPROX((vf.transpose() * vcf).value(), (vf.template cast[CF]().transpose() * vcf).value())
    VERIFY_IS_APPROX((vf * vcf.transpose()).eval(), (vf.template cast[CF]() * vcf.transpose()).eval())
    VERIFY_IS_APPROX((vf * vcf.transpose()).eval(), (vf.template cast[CF]() * vcf.transpose()).eval())

    var mcd2 = mcd
    VERIFY_IS_APPROX(mcd.array() *= md.array(), mcd2.array() *= md.array().template cast[CD]())
    VERIFY_IS_APPROX(sd * md * mcd, (sd * md).template cast[CD]().eval() * mcd)
    VERIFY_IS_APPROX(sd * mcd * md, sd * mcd * md.template cast[CD]())
    VERIFY_IS_APPROX(scd * md * mcd, scd * md.template cast[CD]().eval() * mcd)
    VERIFY_IS_APPROX(scd * mcd * md, scd * mcd * md.template cast[CD]())
    VERIFY_IS_APPROX(sf * mf * mcf, sf * mf.template cast[CF]() * mcf)
    VERIFY_IS_APPROX(sf * mcf * mf, sf * mcf * mf.template cast[CF]())
    VERIFY_IS_APPROX(scf * mf * mcf, scf * mf.template cast[CF]() * mcf)
    VERIFY_IS_APPROX(scf * mcf * mf, scf * mcf * mf.template cast[CF]())
    VERIFY_IS_APPROX(sd * md.adjoint() * mcd, (sd * md).template cast[CD]().eval().adjoint() * mcd)
    VERIFY_IS_APPROX(sd * mcd.adjoint() * md, sd * mcd.adjoint() * md.template cast[CD]())
    VERIFY_IS_APPROX(sd * md.adjoint() * mcd.adjoint(), (sd * md).template cast[CD]().eval().adjoint() * mcd.adjoint())
    VERIFY_IS_APPROX(sd * mcd.adjoint() * md.adjoint(), sd * mcd.adjoint() * md.template cast[CD]().adjoint())
    VERIFY_IS_APPROX(sd * md * mcd.adjoint(), (sd * md).template cast[CD]().eval() * mcd.adjoint())
    VERIFY_IS_APPROX(sd * mcd * md.adjoint(), sd * mcd * md.template cast[CD]().adjoint())
    VERIFY_IS_APPROX(sf * mf.adjoint() * mcf, (sf * mf).template cast[CF]().eval().adjoint() * mcf)
    VERIFY_IS_APPROX(sf * mcf.adjoint() * mf, sf * mcf.adjoint() * mf.template cast[CF]())
    VERIFY_IS_APPROX(sf * mf.adjoint() * mcf.adjoint(), (sf * mf).template cast[CF]().eval().adjoint() * mcf.adjoint())
    VERIFY_IS_APPROX(sf * mcf.adjoint() * mf.adjoint(), sf * mcf.adjoint() * mf.template cast[CF]().adjoint())
    VERIFY_IS_APPROX(sf * mf * mcf.adjoint(), (sf * mf).template cast[CF]().eval() * mcf.adjoint())
    VERIFY_IS_APPROX(sf * mcf * mf.adjoint(), sf * mcf * mf.template cast[CF]().adjoint())
    VERIFY_IS_APPROX(sf * mf * vcf, (sf * mf).template cast[CF]().eval() * vcf)
    VERIFY_IS_APPROX(scf * mf * vcf, (scf * mf.template cast[CF]()).eval() * vcf)
    VERIFY_IS_APPROX(sf * mcf * vf, sf * mcf * vf.template cast[CF]())
    VERIFY_IS_APPROX(scf * mcf * vf, scf * mcf * vf.template cast[CF]())
    VERIFY_IS_APPROX(sf * vcf.adjoint() * mf, sf * vcf.adjoint() * mf.template cast[CF]().eval())
    VERIFY_IS_APPROX(scf * vcf.adjoint() * mf, scf * vcf.adjoint() * mf.template cast[CF]().eval())
    VERIFY_IS_APPROX(sf * vf.adjoint() * mcf, sf * vf.adjoint().template cast[CF]().eval() * mcf)
    VERIFY_IS_APPROX(scf * vf.adjoint() * mcf, scf * vf.adjoint().template cast[CF]().eval() * mcf)
    VERIFY_IS_APPROX(sd * md * vcd, (sd * md).template cast[CD]().eval() * vcd)
    VERIFY_IS_APPROX(scd * md * vcd, (scd * md.template cast[CD]()).eval() * vcd)
    VERIFY_IS_APPROX(sd * mcd * vd, sd * mcd * vd.template cast[CD]().eval())
    VERIFY_IS_APPROX(scd * mcd * vd, scd * mcd * vd.template cast[CD]().eval())
    VERIFY_IS_APPROX(sd * vcd.adjoint() * md, sd * vcd.adjoint() * md.template cast[CD]().eval())
    VERIFY_IS_APPROX(scd * vcd.adjoint() * md, scd * vcd.adjoint() * md.template cast[CD]().eval())
    VERIFY_IS_APPROX(sd * vd.adjoint() * mcd, sd * vd.adjoint().template cast[CD]().eval() * mcd)
    VERIFY_IS_APPROX(scd * vd.adjoint() * mcd, scd * vd.adjoint().template cast[CD]().eval() * mcd)
    VERIFY_IS_APPROX(sd * vcd.adjoint() * md.template triangularView[Upper](), sd * vcd.adjoint() * md.template cast[CD]().eval().template triangularView[Upper]())
    VERIFY_IS_APPROX(scd * vcd.adjoint() * md.template triangularView[Lower](), scd * vcd.adjoint() * md.template cast[CD]().eval().template triangularView[Lower]())
    VERIFY_IS_APPROX(sd * vcd.adjoint() * md.transpose().template triangularView[Upper](), sd * vcd.adjoint() * md.transpose().template cast[CD]().eval().template triangularView[Upper]())
    VERIFY_IS_APPROX(scd * vcd.adjoint() * md.transpose().template triangularView[Lower](), scd * vcd.adjoint() * md.transpose().template cast[CD]().eval().template triangularView[Lower]())
    VERIFY_IS_APPROX(sd * vd.adjoint() * mcd.template triangularView[Lower](), sd * vd.adjoint().template cast[CD]().eval() * mcd.template triangularView[Lower]())
    VERIFY_IS_APPROX(scd * vd.adjoint() * mcd.template triangularView[Upper](), scd * vd.adjoint().template cast[CD]().eval() * mcd.template triangularView[Upper]())
    VERIFY_IS_APPROX(sd * vd.adjoint() * mcd.transpose().template triangularView[Lower](), sd * vd.adjoint().template cast[CD]().eval() * mcd.transpose().template triangularView[Lower]())
    VERIFY_IS_APPROX(scd * vd.adjoint() * mcd.transpose().template triangularView[Upper](), scd * vd.adjoint().template cast[CD]().eval() * mcd.transpose().template triangularView[Upper]())

    rcd.setZero()
    VERIFY_IS_APPROX(Mat_cd(rcd.template triangularView[Upper]() = sd * mcd * md),
                     Mat_cd((sd * mcd * md.template cast[CD]().eval()).template triangularView[Upper]()))
    VERIFY_IS_APPROX(Mat_cd(rcd.template triangularView[Upper]() = sd * md * mcd),
                     Mat_cd((sd * md.template cast[CD]().eval() * mcd).template triangularView[Upper]()))
    VERIFY_IS_APPROX(Mat_cd(rcd.template triangularView[Upper]() = scd * mcd * md),
                     Mat_cd((scd * mcd * md.template cast[CD]().eval()).template triangularView[Upper]()))
    VERIFY_IS_APPROX(Mat_cd(rcd.template triangularView[Upper]() = scd * md * mcd),
                     Mat_cd((scd * md.template cast[CD]().eval() * mcd).template triangularView[Upper]()))
    VERIFY_IS_APPROX(md.array() * mcd.array(), md.template cast[CD]().eval().array() * mcd.array())
    VERIFY_IS_APPROX(mcd.array() * md.array(), mcd.array() * md.template cast[CD]().eval().array())
    VERIFY_IS_APPROX(md.array() + mcd.array(), md.template cast[CD]().eval().array() + mcd.array())
    VERIFY_IS_APPROX(mcd.array() + md.array(), mcd.array() + md.template cast[CD]().eval().array())
    VERIFY_IS_APPROX(md.array() - mcd.array(), md.template cast[CD]().eval().array() - mcd.array())
    VERIFY_IS_APPROX(mcd.array() - md.array(), mcd.array() - md.template cast[CD]().eval().array())

    if mcd.array().abs().minCoeff() > epsd:
        VERIFY_IS_APPROX(md.array() / mcd.array(), md.template cast[CD]().eval().array() / mcd.array())
    if md.array().abs().minCoeff() > epsd:
        VERIFY_IS_APPROX(mcd.array() / md.array(), mcd.array() / md.template cast[CD]().eval().array())
    if (md.array().abs().minCoeff() > epsd) or (mcd.array().abs().minCoeff() > epsd):
        VERIFY_IS_APPROX(md.array().pow(mcd.array()), md.template cast[CD]().eval().array().pow(mcd.array()))
        VERIFY_IS_APPROX(mcd.array().pow(md.array()), mcd.array().pow(md.template cast[CD]().eval().array()))
        VERIFY_IS_APPROX(pow(md.array(), mcd.array()), md.template cast[CD]().eval().array().pow(mcd.array()))
        VERIFY_IS_APPROX(pow(mcd.array(), md.array()), mcd.array().pow(md.template cast[CD]().eval().array()))

    rcd = mcd
    VERIFY_IS_APPROX(rcd = md, md.template cast[CD]().eval())
    rcd = mcd
    VERIFY_IS_APPROX(rcd += md, mcd + md.template cast[CD]().eval())
    rcd = mcd
    VERIFY_IS_APPROX(rcd -= md, mcd - md.template cast[CD]().eval())
    rcd = mcd
    VERIFY_IS_APPROX(rcd.array() *= md.array(), mcd.array() * md.template cast[CD]().eval().array())
    rcd = mcd
    if md.array().abs().minCoeff() > epsd:
        VERIFY_IS_APPROX(rcd.array() /= md.array(), mcd.array() / md.template cast[CD]().eval().array())

    rcd = mcd
    VERIFY_IS_APPROX(rcd.noalias() += md + mcd * md, mcd + (md.template cast[CD]().eval()) + mcd * (md.template cast[CD]().eval()))
    VERIFY_IS_APPROX(rcd.noalias() = md * md, (md * md).eval().template cast[CD]())
    rcd = mcd
    VERIFY_IS_APPROX(rcd.noalias() += md * md, mcd + (md * md).eval().template cast[CD]())
    rcd = mcd
    VERIFY_IS_APPROX(rcd.noalias() -= md * md, mcd - (md * md).eval().template cast[CD]())
    VERIFY_IS_APPROX(rcd.noalias() = mcd + md * md, mcd + (md * md).eval().template cast[CD]())
    rcd = mcd
    VERIFY_IS_APPROX(rcd.noalias() += mcd + md * md, mcd + mcd + (md * md).eval().template cast[CD]())
    rcd = mcd
    VERIFY_IS_APPROX(rcd.noalias() -= mcd + md * md, -((md * md).eval().template cast[CD]()))

def test_mixingtypes():
    for i in range(g_repeat):
        call_subtest(1, mixingtypes[3]())
        call_subtest(2, mixingtypes[4]())
        call_subtest(3, mixingtypes[Dynamic](internal_random[Int](1, EIGEN_TEST_MAX_SIZE)))
        call_subtest(4, mixingtypes[3]())
        call_subtest(5, mixingtypes[4]())
        call_subtest(6, mixingtypes[Dynamic](internal_random[Int](1, EIGEN_TEST_MAX_SIZE)))
        call_subtest(7, raise_assertion[Dynamic](internal_random[Int](1, EIGEN_TEST_MAX_SIZE)))
    call_subtest(7, raise_assertion[0]())
    call_subtest(7, raise_assertion[3]())
    call_subtest(7, raise_assertion[4]())
    call_subtest(7, raise_assertion[Dynamic](0))
<<<FILE>>>