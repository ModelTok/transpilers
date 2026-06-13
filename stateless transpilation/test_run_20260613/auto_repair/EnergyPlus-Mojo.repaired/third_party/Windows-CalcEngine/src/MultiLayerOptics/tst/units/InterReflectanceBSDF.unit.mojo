from memory import shared_ptr, make_shared
from testing import Test, Expect
from WCEMultiLayerOptics import CInterReflectance
from WCESingleLayerOptics import CBSDFDefinition, CBSDFDirections, BSDFDirection
from WCECommon import SquareMatrix

class TestInterReflectanceBSDF(Test):
    private:
        var m_InterReflectance: shared_ptr[CInterReflectance]

    protected:
        def SetUp() raises:
            var aDefinitions = List[CBSDFDefinition]()
            aDefinitions.append(CBSDFDefinition(0, 1))
            aDefinitions.append(CBSDFDefinition(15, 1))
            aDefinitions.append(CBSDFDefinition(30, 1))
            aDefinitions.append(CBSDFDefinition(45, 1))
            aDefinitions.append(CBSDFDefinition(60, 1))
            aDefinitions.append(CBSDFDefinition(75, 1))
            aDefinitions.append(CBSDFDefinition(86.25, 1))
            var aDirections = CBSDFDirections(aDefinitions, BSDFDirection.Incoming)
            var aLambdas = aDirections.lambdaMatrix()
            var Rb = SquareMatrix(
                [[1.438618083, 0, 0, 0, 0, 0, 0],
                 [0, 0.189397664, 0, 0, 0, 0, 0],
                 [0, 0, 0.112189021, 0, 0, 0, 0],
                 [0, 0, 0, 0.114376511, 0, 0, 0],
                 [0, 0, 0, 0, 0.207336671, 0, 0],
                 [0, 0, 0, 0, 0, 0.951907739, 0],
                 [0, 0, 0, 0, 0, 0, 15.28298172]]
            )
            var Rf = SquareMatrix(
                [[1.438618083, 0, 0, 0, 0, 0, 0],
                 [0, 0.189397664, 0, 0, 0, 0, 0],
                 [0, 0, 0.112189021, 0, 0, 0, 0],
                 [0, 0, 0, 0.114376511, 0, 0, 0],
                 [0, 0, 0, 0, 0.207336671, 0, 0],
                 [0, 0, 0, 0, 0, 0.951907739, 0],
                 [0, 0, 0, 0, 0, 0, 15.28298172]]
            )
            m_InterReflectance = make_shared[CInterReflectance](aLambdas, Rb, Rf)

    public:
        def getInterReflectance() -> shared_ptr[CInterReflectance]:
            return m_InterReflectance

def TestBSDFInterreflectance() raises:
    SCOPED_TRACE("Begin Test: Simple BSDF interreflectance.")
    var interRefl = *getInterReflectance()
    var results = interRefl.value()
    var matrixSize = results.size()
    var size: Int = 7
    Expect.equal(size, matrixSize)
    var correctResults = SquareMatrix(
        [[1.005964363, 0, 0, 0, 0, 0, 0],
         [0, 1.005964363, 0, 0, 0, 0, 0],
         [0, 0, 1.006280195, 0, 0, 0, 0],
         [0, 0, 0, 1.008724458, 0, 0, 0],
         [0, 0, 0, 0, 1.021780268, 0, 0],
         [0, 0, 0, 0, 0, 1.176150952, 0],
         [0, 0, 0, 0, 0, 0, 3.022280250]]
    )
    for i in range(size):
        for j in range(size):
            Expect.near(correctResults[i][j], results[i][j], 1e-6)