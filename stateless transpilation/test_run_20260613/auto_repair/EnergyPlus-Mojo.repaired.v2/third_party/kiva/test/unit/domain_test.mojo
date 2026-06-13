from fixtures.bestest-fixture import BESTESTFixture
from fixtures.typical-fixture import TypicalFixture
from Errors import Errors
from Ground import Ground
from Domain import Domain
from Foundation import Foundation
from CellType import CellType
from math import atan

const PI: Float64 = 4.0 * atan(1.0)

class DomainFixture(BESTESTFixture):
    var ground: Ground
    var domain: Domain
    var outputMap: OutputMap

    def __init__(inout self):

    def SetUp(inout self):
        self.specifySystem()
        self.ground = Ground(self.fnd, self.outputMap)
        self.fnd.createMeshData()
        self.domain = Domain(self.ground.domain)
        self.domain.setDomain(self.fnd)

def domain_basics():
    var fixture = DomainFixture()
    fixture.SetUp()
    let domain = fixture.domain
    check_eq(domain.dim_lengths[0], 41)
    check_eq(domain.dim_lengths[1], 1)
    check_eq(domain.dim_lengths[2], 19)
    check_eq(domain.stepsize[0], 1)
    check_eq(domain.stepsize[1], 41)
    check_eq(domain.stepsize[2], 41)
    check_eq(domain.dest_index_vector.size(), 3)
    check_eq(domain.dest_index_vector[2].size(), domain.dim_lengths[0] * domain.dim_lengths[1] * domain.dim_lengths[2])

def surface_indices():
    var fixture = DomainFixture()
    fixture.SetUp()
    let ground = fixture.ground
    let domain = fixture.domain
    check_eq(ground.foundation.surfaces[0].indices.size(), domain.dim_lengths[2])
    check_eq(ground.foundation.surfaces[4].indices.size(), domain.dim_lengths[0])
    check_eq(ground.foundation.surfaces[5].indices.size(), 11)

def surface_tilt():
    var fixture = DomainFixture()
    fixture.SetUp()
    let ground = fixture.ground
    check_almost_eq(ground.foundation.surfaces[0].tilt, PI / 2)
    check_almost_eq(ground.foundation.surfaces[4].tilt, PI)
    check_almost_eq(ground.foundation.surfaces[5].tilt, 0.0)

def cell_vector():
    var fixture = DomainFixture()
    fixture.SetUp()
    let domain = fixture.domain
    check_eq(domain.cell.size(), domain.dim_lengths[0] * domain.dim_lengths[1] * domain.dim_lengths[2])
    check_eq(domain.cell[0].cellType, CellType.BOUNDARY)
    check_eq(domain.cell[49].cellType, CellType.NORMAL)