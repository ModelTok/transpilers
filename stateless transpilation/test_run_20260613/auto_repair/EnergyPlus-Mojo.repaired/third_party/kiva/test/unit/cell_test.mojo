from fixtures.bestest-fixture import BESTESTFixture
from fixtures.typical-fixture import GC10aFixture
from Errors import KivaError
from Kiva import Ground, Cell, CellType, Surface, Foundation, Domain
from builtin import Pointer, Tuple, List
from testing import assert_eq, assert_almost_eq  # use Mojo's test utilities

# Helper for EXPECT_DOUBLE_EQ
def assert_double_eq(a: Float64, b: Float64):
    assert_eq(a, b)

def resetValues(inout A: Float64, inout Alt: Tuple[Float64, Float64], inout bVal: Float64):
    A = 0.0
    Alt[0] = 0.0
    Alt[1] = 0.0
    bVal = 0.0

struct CellFixture:
    var ground: Ground
    var cell_vector: List[Cell]

    def __init__(inout self):

    def SetUp(inout self):
        self.specifySystem()
        self.ground = Ground(self.fnd, self.outputMap)  # assume fnd and outputMap from BESTESTFixture
        self.ground.foundation.createMeshData()
        var domain = self.ground.domain
        domain.setDomain(self.ground.foundation)
        self.cell_vector = domain.cell

    # stub methods expected from BESTESTFixture
    def specifySystem(inout self):

# ---------- TEST_F(CellFixture, cell_basics) ----------
def test_cell_basics():
    var fixture = CellFixture()
    fixture.SetUp()
    var cell_vector = fixture.cell_vector
    assert_eq(cell_vector[0].coords[0], 0)
    assert_eq(cell_vector[0].coords[1], 0)
    assert_eq(cell_vector[0].coords[2], 0)
    assert_eq(cell_vector[0].index, 0)
    assert_eq(cell_vector[0].cellType, CellType.BOUNDARY)
    assert_eq(cell_vector[0].surfacePtr.type, Surface.SurfaceType.ST_DEEP_GROUND)
    assert_eq(cell_vector[120].coords[0], 38)
    assert_eq(cell_vector[120].coords[1], 0)
    assert_eq(cell_vector[120].coords[2], 2)
    assert_eq(cell_vector[120].index, 120)
    assert_eq(cell_vector[120].cellType, CellType.NORMAL)
    assert_eq(cell_vector[47].dims[0], 0)
    assert_eq(cell_vector[47].dims[1], 5)
    assert_eq(cell_vector[47].dims[2], 2)

# ---------- TEST_F(GC10aFixture, calcCellADI) ----------
def test_calcCellADI():
    var fixture = GC10aFixture()
    fixture.SetUp()
    fixture.fnd.numericalScheme = Foundation.NS_ADI
    fixture.calculate()  # assume this method exists
    var A: Float64 = 0.0
    var Alt: Tuple[Float64, Float64] = (0.0, 0.0)
    var bVal: Float64 = 0.0
    var this_cell = fixture.ground.domain.cell[0]
    this_cell.calcCellADI(0, 3600.0, fixture.fnd, fixture.bcs, A, Alt, bVal)
    assert_double_eq(A, 1)
    assert_double_eq(Alt[1], 0)
    assert_double_eq(Alt[0], 0)
    assert_double_eq(bVal, this_cell.surfacePtr.temperature)
    this_cell = fixture.ground.domain.cell[120]
    resetValues(A, Alt, bVal)
    this_cell.calcCellADI(0, 3600.0, fixture.fnd, fixture.bcs, A, Alt, bVal)
    var theta = 3600.0 / (fixture.fnd.numberOfDimensions * this_cell.density * this_cell.specificHeat)
    var f = fixture.fnd.fADI
    assert_double_eq(A, 1.0 + (2 - f) * (this_cell.pde[0][1] - this_cell.pde[0][0]) * theta)
    assert_double_eq(Alt[1], (2 - f) * (-this_cell.pde[0][1] * theta))
    assert_double_eq(Alt[0], (2 - f) * (this_cell.pde[0][0] * theta))
    assert_double_eq(bVal,
        this_cell.told_ptr.load() * (1.0 + f * (this_cell.pde[2][0] - this_cell.pde[2][1]) * theta) -
        (this_cell.told_ptr.offset(-fixture.ground.domain.stepsize[2])).load() * f * this_cell.pde[2][0] * theta +
        (this_cell.told_ptr.offset(fixture.ground.domain.stepsize[2])).load() * f * this_cell.pde[2][1] * theta +
        this_cell.heatGain * theta)
    resetValues(A, Alt, bVal)
    this_cell.calcCellADI(2, 3600.0, fixture.fnd, fixture.bcs, A, Alt, bVal)
    assert_double_eq(A, 1.0 + (2 - f) * (this_cell.pde[2][1] - this_cell.pde[2][0]) * theta)
    assert_double_eq(Alt[1], (2 - f) * (-this_cell.pde[2][1] * theta))
    assert_double_eq(Alt[0], (2 - f) * (this_cell.pde[2][0] * theta))
    assert_double_eq(bVal,
        this_cell.told_ptr.load() * (1.0 + f * (this_cell.pde[0][0] - this_cell.pde[0][1]) * theta) -
        (this_cell.told_ptr.offset(-fixture.ground.domain.stepsize[0])).load() * f * this_cell.pde[0][0] * theta +
        (this_cell.told_ptr.offset(fixture.ground.domain.stepsize[0])).load() * f * this_cell.pde[0][1] * theta +
        this_cell.heatGain * theta)
    this_cell = fixture.ground.domain.cell[123]
    resetValues(A, Alt, bVal)
    this_cell.calcCellADI(0, 3600.0, fixture.fnd, fixture.bcs, A, Alt, bVal)
    assert_double_eq(A, 1)
    assert_double_eq(Alt[1], -1.0)
    assert_double_eq(Alt[0], 0)
    assert_double_eq(bVal, 0)
    resetValues(A, Alt, bVal)
    this_cell.calcCellADI(2, 3600.0, fixture.fnd, fixture.bcs, A, Alt, bVal)
    assert_double_eq(A, 1)
    assert_double_eq(Alt[1], 0)
    assert_double_eq(Alt[0], 0)
    assert_double_eq(bVal, (this_cell.told_ptr.offset(fixture.ground.domain.stepsize[0])).load())

# ---------- TEST_F(GC10aFixture, calcCellMatrix) ----------
def test_calcCellMatrix():
    var fixture = GC10aFixture()
    fixture.SetUp()
    fixture.fnd.numericalScheme = Foundation.NS_IMPLICIT
    fixture.calculate()
    var A: Float64 = 0.0
    var bVal: Float64 = 0.0
    var Alt: Tuple[Tuple[Float64, Float64], Tuple[Float64, Float64], Tuple[Float64, Float64]] = ((0.0,0.0),(0.0,0.0),(0.0,0.0))
    var this_cell = fixture.ground.domain.cell[0]
    this_cell.calcCellMatrix(fixture.fnd.numericalScheme, 3600.0, fixture.fnd, fixture.bcs, A, Alt, bVal)
    assert_double_eq(A, 1)
    assert_double_eq(Alt[0][1], 0)
    assert_double_eq(Alt[0][0], 0)
    assert_double_eq(bVal, this_cell.surfacePtr.temperature)
    this_cell = fixture.ground.domain.cell[120]
    this_cell.calcCellMatrix(fixture.fnd.numericalScheme, 3600.0, fixture.fnd, fixture.bcs, A, Alt, bVal)
    var theta = 3600.0 / (this_cell.density * this_cell.specificHeat)
    assert_double_eq(A, (1.0 + (this_cell.pde[0][1] + this_cell.pde[2][1] - this_cell.pde[0][0] - this_cell.pde[2][0]) * theta))
    assert_double_eq(Alt[0][1], -this_cell.pde[0][1] * theta)
    assert_double_eq(Alt[0][0], this_cell.pde[0][0] * theta)
    assert_double_eq(bVal, this_cell.told_ptr.load() + this_cell.heatGain * theta)

# ---------- TEST_F(GC10aFixture, calcCellMatrixSS) ----------
def test_calcCellMatrixSS():
    var fixture = GC10aFixture()
    fixture.SetUp()
    fixture.fnd.numericalScheme = Foundation.NS_STEADY_STATE
    fixture.calculate()
    var A: Float64 = 0.0
    var bVal: Float64 = 0.0
    var Alt: Tuple[Tuple[Float64, Float64], Tuple[Float64, Float64], Tuple[Float64, Float64]] = ((0.0,0.0),(0.0,0.0),(0.0,0.0))
    var this_cell = fixture.ground.domain.cell[0]
    this_cell.calcCellMatrix(fixture.fnd.numericalScheme, 3600.0, fixture.fnd, fixture.bcs, A, Alt, bVal)
    assert_double_eq(A, 1)
    assert_double_eq(Alt[0][1], 0)
    assert_double_eq(Alt[0][1], 0)  # note: repeated as in original
    assert_double_eq(bVal, this_cell.surfacePtr.temperature)
    this_cell = fixture.ground.domain.cell[120]
    this_cell.calcCellMatrix(fixture.fnd.numericalScheme, 3600.0, fixture.fnd, fixture.bcs, A, Alt, bVal)
    assert_double_eq(A, this_cell.pde[0][0] + this_cell.pde[2][0] - this_cell.pde[0][1] - this_cell.pde[2][1])
    assert_double_eq(Alt[0][1], this_cell.pde[0][1])
    assert_double_eq(Alt[0][0], -this_cell.pde[0][0])
    assert_double_eq(bVal, 0)