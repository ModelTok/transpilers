from memory import Pointer
from utils import String
from VenetianCellDescription import CVenetianCellDescription
from BeamDirection import CBeamDirection
from MaterialDescription import CMaterial, RMaterialProperties, Property
from WCEViewer import BeamViewFactor
from WCECommon import SquareMatrix, CLinearSolver, CSeries, Side
from UniformDiffuseCell import CUniformDiffuseCell
from DirectionalDiffuseCell import CDirectionalDiffuseCell
from ICellDescription import ICellDescription

@value
struct SegmentIrradiance:
    var E_f: Float64
    var E_b: Float64
    def __init__(inout self):
        self.E_f = 0.0
        self.E_b = 0.0

@value
class CVenetianSlatEnergies:
    var m_SlatIrradiances: List[SegmentIrradiance]
    var m_SlatRadiances: List[Float64]
    var m_CalcDirection: Pointer[CBeamDirection]

    def __init__(inout self, t_BeamDirection: CBeamDirection, t_SlatIrradiances: List[SegmentIrradiance], t_SlatRadiances: List[Float64]):
        self.m_SlatIrradiances = t_SlatIrradiances
        self.m_SlatRadiances = t_SlatRadiances
        self.m_CalcDirection = Pointer[CBeamDirection].alloc(1)
        self.m_CalcDirection[0] = t_BeamDirection

    def irradiances(self, index: Int) -> SegmentIrradiance:
        if index > len(self.m_SlatIrradiances):
            raise Error("Index for slat irradiances is out of range.")
        return self.m_SlatIrradiances[index]

    def radiances(self, index: Int) -> Float64:
        if index > len(self.m_SlatRadiances):
            raise Error("Index for slat irradiances is out of range.")
        return self.m_SlatRadiances[index]

    def direction(self) -> Pointer[CBeamDirection]:
        return self.m_CalcDirection

    def size(self) -> Int:
        return len(self.m_SlatRadiances)

@value
class CVenetianCellEnergy:
    struct BeamSegmentView:
        var viewFactor: Float64
        var percentViewed: Float64
        def __init__(inout self):
            self.viewFactor = 0.0
            self.percentViewed = 0.0

    class CSlatEnergyResults:
        var m_Energies: List[Pointer[CVenetianSlatEnergies]]

        def __init__(inout self):
            self.m_Energies = List[Pointer[CVenetianSlatEnergies]]()

        def getEnergies(self, t_BeamDirection: CBeamDirection) -> Pointer[CVenetianSlatEnergies]:
            var Energies: Pointer[CVenetianSlatEnergies] = Pointer[CVenetianSlatEnergies]()
            for obj in self.m_Energies:
                if obj[0].direction()[0] == t_BeamDirection:
                    Energies = obj
                    break
            return Energies

        def append(inout self, t_BeamDirection: CBeamDirection, t_SlatIrradiances: List[SegmentIrradiance], t_SlatRadiances: List[Float64]) -> Pointer[CVenetianSlatEnergies]:
            var aEnergy = Pointer[CVenetianSlatEnergies].alloc(1)
            aEnergy[0] = CVenetianSlatEnergies(t_BeamDirection, t_SlatIrradiances, t_SlatRadiances)
            self.m_Energies.append(aEnergy)
            return aEnergy

    var m_Cell: Pointer[CVenetianCellDescription]
    var m_Tf: Float64
    var m_Tb: Float64
    var m_Rf: Float64
    var m_Rb: Float64
    var m_Energy: Pointer[SquareMatrix]
    var b: List[Int]
    var f: List[Int]
    var m_CurrentSlatEnergies: Pointer[CVenetianSlatEnergies]
    var m_SlatEnergyResults: CSlatEnergyResults

    def __init__(inout self):
        self.m_Cell = Pointer[CVenetianCellDescription]()
        self.m_Tf = 0.0
        self.m_Tb = 0.0
        self.m_Rf = 0.0
        self.m_Rb = 0.0
        self.m_Energy = Pointer[SquareMatrix]()
        self.b = List[Int]()
        self.f = List[Int]()
        self.m_CurrentSlatEnergies = Pointer[CVenetianSlatEnergies]()
        self.m_SlatEnergyResults = CSlatEnergyResults()

    def __init__(inout self, t_Cell: Pointer[CVenetianCellDescription], Tf: Float64, Tb: Float64, Rf: Float64, Rb: Float64):
        self.m_Cell = t_Cell
        self.m_Tf = Tf
        self.m_Tb = Tb
        self.m_Rf = Rf
        self.m_Rb = Rb
        self.b = List[Int]()
        self.f = List[Int]()
        self.m_CurrentSlatEnergies = Pointer[CVenetianSlatEnergies]()
        self.m_SlatEnergyResults = CSlatEnergyResults()
        self.createSlatsMapping()
        self.formEnergyMatrix()

    def T_dir_dir(self, t_Direction: CBeamDirection) -> Float64:
        return self.m_Cell[0].T_dir_dir(Side.Front, t_Direction)

    def T_dir_dif(self, t_Direction: CBeamDirection) -> Float64:
        self.calculateSlatEnergiesFromBeam(t_Direction)
        var numSeg: Int = int(self.m_Cell[0].numberOfSegments() / 2)
        return self.m_CurrentSlatEnergies[0].irradiances(numSeg).E_f - self.T_dir_dir(t_Direction)

    def R_dir_dif(self, t_Direction: CBeamDirection) -> Float64:
        self.calculateSlatEnergiesFromBeam(t_Direction)
        return self.m_CurrentSlatEnergies[0].irradiances(0).E_b

    def T_dir_dir(self, t_IncomingDirection: CBeamDirection, t_OutgoingDirection: CBeamDirection) -> Float64:
        self.calculateSlatEnergiesFromBeam(t_IncomingDirection)
        var BVF: List[BeamSegmentView] = self.beamVector(t_OutgoingDirection, Side.Back)
        var aResult: Float64 = 0.0
        for i in range(1, self.m_CurrentSlatEnergies[0].size()):
            aResult += self.m_CurrentSlatEnergies[0].radiances(i) * BVF[i].percentViewed * BVF[i].viewFactor / self.m_Cell[0].segmentLength(i)
        var insideSegIndex: Int = int(self.m_Cell[0].numberOfSegments() / 2)
        var insideSegLength: Float64 = self.m_Cell[0].segmentLength(insideSegIndex)
        return insideSegLength * aResult

    def R_dir_dir(self, t_IncomingDirection: CBeamDirection, t_OutgoingDirection: CBeamDirection) -> Float64:
        self.calculateSlatEnergiesFromBeam(t_IncomingDirection)
        var BVF: List[BeamSegmentView] = self.beamVector(t_OutgoingDirection, Side.Front)
        var aResult: Float64 = 0.0
        for i in range(1, self.m_CurrentSlatEnergies[0].size()):
            aResult += self.m_CurrentSlatEnergies[0].radiances(i) * BVF[i].percentViewed * BVF[i].viewFactor / self.m_Cell[0].segmentLength(i)
        var insideSegIndex: Int = int(self.m_Cell[0].numberOfSegments() / 2)
        var insideSegLength: Float64 = self.m_Cell[0].segmentLength(insideSegIndex)
        return insideSegLength * aResult

    def T_dif_dif(self) -> Float64:
        var numSeg: Int = int(self.m_Cell[0].numberOfSegments() / 2)
        var B: Pointer[List[Float64]] = self.diffuseVector()
        var aEnergy: SquareMatrix = SquareMatrix(self.m_Energy[0].size())
        aEnergy = self.m_Energy[0]
        var aSolver: CLinearSolver = CLinearSolver()
        var aSolution: List[Float64] = aSolver.solveSystem(aEnergy, B[0])
        return aSolution[numSeg - 1]

    def R_dif_dif(self) -> Float64:
        var numSeg: Int = int(self.m_Cell[0].numberOfSegments() / 2)
        var B: Pointer[List[Float64]] = self.diffuseVector()
        var aEnergy: SquareMatrix = SquareMatrix(self.m_Energy[0].size())
        aEnergy = self.m_Energy[0]
        var aSolver: CLinearSolver = CLinearSolver()
        var aSolution: List[Float64] = aSolver.solveSystem(aEnergy, B[0])
        return aSolution[numSeg]

    def slatIrradiances(self, t_IncomingDirection: CBeamDirection) -> List[SegmentIrradiance]:
        var aIrradiances: List[SegmentIrradiance] = List[SegmentIrradiance]()
        var numSeg: Int = int(self.m_Cell[0].numberOfSegments() / 2)
        var BVF: List[BeamSegmentView] = self.beamVector(t_IncomingDirection, Side.Front)
        var B: Pointer[List[Float64]] = Pointer[List[Float64]].alloc(1)
        B[0] = List[Float64]()
        for i in range(0, 2 * numSeg):
            var index: Int = 0
            if i < numSeg:
                index = self.f[i]
            else:
                index = self.b[i - numSeg]
            B[0].append(-BVF[index].viewFactor)
        var aEnergy: SquareMatrix = SquareMatrix(self.m_Energy[0].size())
        aEnergy = self.m_Energy[0]
        var aSolver: CLinearSolver = CLinearSolver()
        var aSolution: List[Float64] = aSolver.solveSystem(aEnergy, B[0])
        for i in range(0, numSeg + 1):
            var aIrr: SegmentIrradiance = SegmentIrradiance()
            if i == 0:
                aIrr.E_f = 1.0
                aIrr.E_b = aSolution[numSeg + i]
            elif i == numSeg:
                aIrr.E_f = aSolution[i - 1]
                aIrr.E_b = 0.0
            else:
                aIrr.E_f = aSolution[i - 1]
                aIrr.E_b = aSolution[numSeg + i]
            aIrradiances.append(aIrr)
        return aIrradiances

    def slatRadiances(self, t_Irradiances: List[SegmentIrradiance]) -> List[Float64]:
        var numSlats: Int = len(t_Irradiances)
        var aRadiances: List[Float64] = List[Float64](2 * numSlats - 2)
        for i in range(0, numSlats):
            if i == 0:
                aRadiances[self.b[i]] = 1.0
            elif i == numSlats - 1:
                aRadiances[self.f[i - 1]] = t_Irradiances[i].E_f
            else:
                aRadiances[self.b[i]] = self.m_Tf * t_Irradiances[i].E_f + self.m_Rb * t_Irradiances[i].E_b
                aRadiances[self.f[i - 1]] = self.m_Tb * t_Irradiances[i].E_b + self.m_Rf * t_Irradiances[i].E_f
        return aRadiances

    def createSlatsMapping(inout self):
        var numSeg: Int = int(self.m_Cell[0].numberOfSegments() / 2)
        self.b.clear()
        self.f.clear()
        for i in range(0, numSeg):
            self.b.append(i)
            self.f.append(2 * numSeg - 1 - i)

    def formEnergyMatrix(inout self):
        var aViewFactors: SquareMatrix = self.m_Cell[0].viewFactors()
        var numSeg: Int = int(self.m_Cell[0].numberOfSegments() / 2)
        self.m_Energy = Pointer[SquareMatrix].alloc(1)
        self.m_Energy[0] = SquareMatrix(2 * numSeg)
        var T: Float64 = self.m_Tf
        var R: Float64 = self.m_Rf
        for i in range(0, numSeg):
            for j in range(0, numSeg):
                if i != numSeg - 1:
                    var value: Float64 = aViewFactors[self.b[i + 1], self.f[j]] * T + aViewFactors[self.f[i], self.f[j]] * R
                    if i == j:
                        value -= 1.0
                    self.m_Energy[0][j, i] = value
                else:
                    if i != j:
                        self.m_Energy[0][j, i] = 0.0
                    else:
                        self.m_Energy[0][j, i] = -1.0
        for i in range(0, numSeg):
            for j in range(0, numSeg):
                if i != numSeg - 1:
                    var value: Float64 = aViewFactors[self.b[i + 1], self.b[j]] * T + aViewFactors[self.f[i], self.b[j]] * R
                    self.m_Energy[0][j + numSeg, i] = value
                else:
                    self.m_Energy[0][j + numSeg, i] = 0.0
        T = self.m_Tb
        R = self.m_Rb
        for i in range(0, numSeg):
            for j in range(0, numSeg):
                if i != 0:
                    var value: Float64 = aViewFactors[self.f[i - 1], self.f[j]] * T + aViewFactors[self.b[i], self.f[j]] * R
                    self.m_Energy[0][j, i + numSeg] = value
                else:
                    self.m_Energy[0][j, i + numSeg] = 0.0
        for i in range(0, numSeg):
            for j in range(0, numSeg):
                if i != 0:
                    var value: Float64 = aViewFactors[self.f[i - 1], self.b[j]] * T + aViewFactors[self.b[i], self.b[j]] * R
                    if i == j:
                        value -= 1.0
                    self.m_Energy[0][j + numSeg, i + numSeg] = value
                else:
                    if i != j:
                        self.m_Energy[0][j + numSeg, i + numSeg] = 0.0
                    else:
                        self.m_Energy[0][j + numSeg, i + numSeg] = -1.0

    def calculateSlatEnergiesFromBeam(inout self, t_Direction: CBeamDirection):
        if self.m_CurrentSlatEnergies:
            if self.m_CurrentSlatEnergies[0].direction()[0] != t_Direction:
                self.m_CurrentSlatEnergies = self.m_SlatEnergyResults.getEnergies(t_Direction)
        if not self.m_CurrentSlatEnergies:
            var aIrradiances: List[SegmentIrradiance] = self.slatIrradiances(t_Direction)
            var aRadiances: List[Float64] = self.slatRadiances(aIrradiances)
            self.m_CurrentSlatEnergies = self.m_SlatEnergyResults.append(t_Direction, aIrradiances, aRadiances)

    def diffuseVector(self) -> Pointer[List[Float64]]:
        var numSeg: Int = int(self.m_Cell[0].numberOfSegments() / 2)
        var aViewFactors: SquareMatrix = self.m_Cell[0].viewFactors()
        var B: Pointer[List[Float64]] = Pointer[List[Float64]].alloc(1)
        B[0] = List[Float64](2 * numSeg)
        for i in range(0, numSeg):
            B[0][i] = -aViewFactors[self.b[0], self.f[i]]
            B[0][i + numSeg] = -aViewFactors[self.b[0], self.b[i]]
        return B

    def beamVector(self, t_Direction: CBeamDirection, t_Side: Side) -> List[BeamSegmentView]:
        var numSeg: Int = int(self.m_Cell[0].numberOfSegments() / 2)
        var profileAngle: Float64 = t_Direction.profileAngle()
        if t_Side == Side.Back:
            profileAngle = -profileAngle
        var beamVF: Pointer[List[BeamViewFactor]] = self.m_Cell[0].beamViewFactors(profileAngle, t_Side)
        var B: List[BeamSegmentView] = List[BeamSegmentView](2 * numSeg)
        var index: Int = 0
        for aVF in beamVF[0]:
            if aVF.enclosureIndex == 0:
                index = aVF.segmentIndex + 1
            elif aVF.enclosureIndex == 1:
                index = numSeg + 1 + aVF.segmentIndex
            else:

            B[index].viewFactor = aVF.value
            B[index].percentViewed = aVF.percentHit
        var sideIndex: Dict[Side, Int] = Dict[Side, Int]()
        sideIndex[Side.Front] = numSeg
        sideIndex[Side.Back] = 0
        B[sideIndex[t_Side]].viewFactor = self.m_Cell[0].T_dir_dir(t_Side, t_Direction)
        return B

@value
class CVenetianEnergy:
    var m_CellEnergy: Dict[Side, Pointer[CVenetianCellEnergy]]

    def __init__(inout self):
        self.m_CellEnergy = Dict[Side, Pointer[CVenetianCellEnergy]]()
        self.m_CellEnergy[Side.Front] = Pointer[CVenetianCellEnergy]()
        self.m_CellEnergy[Side.Back] = Pointer[CVenetianCellEnergy]()

    def __init__(inout self, t_Material: CMaterial, t_Cell: Pointer[CVenetianCellDescription]):
        self.m_CellEnergy = Dict[Side, Pointer[CVenetianCellEnergy]]()
        var Tf: Float64 = t_Material.getProperty(Property.T, Side.Front)
        var Tb: Float64 = t_Material.getProperty(Property.T, Side.Back)
        var Rf: Float64 = t_Material.getProperty(Property.R, Side.Front)
        var Rb: Float64 = t_Material.getProperty(Property.R, Side.Back)
        self.createForwardAndBackward(Tf, Tb, Rf, Rb, t_Cell)

    def __init__(inout self, Tf: Float64, Tb: Float64, Rf: Float64, Rb: Float64, t_Cell: Pointer[CVenetianCellDescription]):
        self.m_CellEnergy = Dict[Side, Pointer[CVenetianCellEnergy]]()
        self.createForwardAndBackward(Tf, Tb, Rf, Rb, t_Cell)

    def getCell(self, t_Side: Side) -> Pointer[CVenetianCellEnergy]:
        return self.m_CellEnergy[t_Side]

    def createForwardAndBackward(inout self, Tf: Float64, Tb: Float64, Rf: Float64, Rb: Float64, t_Cell: Pointer[CVenetianCellDescription]):
        self.m_CellEnergy[Side.Front] = Pointer[CVenetianCellEnergy].alloc(1)
        self.m_CellEnergy[Side.Front][0] = CVenetianCellEnergy(t_Cell, Tf, Tb, Rf, Rb)
        var aBackwardCell: Pointer[CVenetianCellDescription] = t_Cell[0].makeBackwardCell()
        self.m_CellEnergy[Side.Back] = Pointer[CVenetianCellEnergy].alloc(1)
        self.m_CellEnergy[Side.Back][0] = CVenetianCellEnergy(aBackwardCell, Tf, Tb, Rf, Rb)

class CVenetianBase(CUniformDiffuseCell, CDirectionalDiffuseCell):
    def __init__(inout self, t_MaterialProperties: Pointer[CMaterial], t_Cell: Pointer[ICellDescription], rotation: Float64 = 0.0):
        CUniformDiffuseCell.__init__(self, t_MaterialProperties, t_Cell, rotation)
        CDirectionalDiffuseCell.__init__(self, t_MaterialProperties, t_Cell, rotation)

    def getCellAsVenetian(self) -> Pointer[CVenetianCellDescription]:
        var aCell: Pointer[CVenetianCellDescription] = Pointer[CVenetianCellDescription]()
        # dynamic_pointer_cast equivalent: assume m_CellDescription is CVenetianCellDescription
        aCell = Pointer[CVenetianCellDescription](self.m_CellDescription)
        return aCell

class CVenetianCell(CVenetianBase):
    var m_Energy: CVenetianEnergy
    var m_EnergiesBand: List[CVenetianEnergy]

    def __init__(inout self, t_MaterialProperties: Pointer[CMaterial], t_Cell: Pointer[ICellDescription], rotation: Float64 = 0.0):
        CBaseCell.__init__(self, t_MaterialProperties, t_Cell, rotation)
        CVenetianBase.__init__(self, t_MaterialProperties, t_Cell, rotation)
        self.m_EnergiesBand = List[CVenetianEnergy]()
        self.generateVenetianEnergy()

    def generateVenetianEnergy(inout self):
        self.m_Energy = CVenetianEnergy(self.m_Material[0], self.getCellAsVenetian())
        self.m_EnergiesBand.clear()
        var aMat: List[RMaterialProperties] = self.m_Material[0].getBandProperties()
        if len(aMat) > 0:
            var size: Int = self.m_Material[0].getBandSize()
            for i in range(0, size):
                var Tf: Float64 = aMat[i].getProperty(Property.T, Side.Front)
                var Tb: Float64 = aMat[i].getProperty(Property.T, Side.Back)
                var Rf: Float64 = aMat[i].getProperty(Property.R, Side.Front)
                var Rb: Float64 = aMat[i].getProperty(Property.R, Side.Back)
                var aEnergy: CVenetianEnergy = CVenetianEnergy(Tf, Tb, Rf, Rb, self.getCellAsVenetian())
                self.m_EnergiesBand.append(aEnergy)

    def setSourceData(inout self, t_SourceData: CSeries):
        CBaseCell.setSourceData(self, t_SourceData)
        self.generateVenetianEnergy()

    def T_dir_dir(self, t_Side: Side, t_Direction: CBeamDirection) -> Float64:
        var aCell: Pointer[CVenetianCellEnergy] = self.m_Energy.getCell(t_Side)
        if self.m_CellRotation != 0.0:
            return aCell[0].T_dir_dir(t_Direction.rotate(self.m_CellRotation))
        return aCell[0].T_dir_dir(t_Direction)

    def T_dir_dir_band(self, t_Side: Side, t_Direction: CBeamDirection) -> List[Float64]:
        var size: Int = len(self.m_EnergiesBand)
        var aProperties: List[Float64] = List[Float64]()
        for i in range(0, size):
            var aCell: CVenetianCellEnergy = self.m_EnergiesBand[i].getCell(t_Side)[0]
            if self.m_CellRotation != 0.0:
                aProperties.append(aCell.T_dir_dir(t_Direction.rotate(self.m_CellRotation)))
            else:
                aProperties.append(aCell.T_dir_dir(t_Direction))
        return aProperties

    def T_dir_dif(self, t_Side: Side, t_Direction: CBeamDirection) -> Float64:
        var aCell: Pointer[CVenetianCellEnergy] = self.m_Energy.getCell(t_Side)
        if self.m_CellRotation != 0.0:
            return aCell[0].T_dir_dif(t_Direction.rotate(self.m_CellRotation))
        return aCell[0].T_dir_dif(t_Direction)

    def T_dir_dif_band(self, t_Side: Side, t_Direction: CBeamDirection) -> List[Float64]:
        var size: Int = len(self.m_EnergiesBand)
        var aProperties: List[Float64] = List[Float64]()
        for i in range(0, size):
            var aCell: CVenetianCellEnergy = self.m_EnergiesBand[i].getCell(t_Side)[0]
            if self.m_CellRotation != 0.0:
                aProperties.append(aCell.T_dir_dif(t_Direction.rotate(self.m_CellRotation)))
            else:
                aProperties.append(aCell.T_dir_dif(t_Direction))
        return aProperties

    def R_dir_dif(self, t_Side: Side, t_Direction: CBeamDirection) -> Float64:
        var aCell: Pointer[CVenetianCellEnergy] = self.m_Energy.getCell(t_Side)
        if self.m_CellRotation != 0.0:
            return aCell[0].R_dir_dif(t_Direction.rotate(self.m_CellRotation))
        return aCell[0].R_dir_dif(t_Direction)

    def R_dir_dif_band(self, t_Side: Side, t_Direction: CBeamDirection) -> List[Float64]:
        var size: Int = len(self.m_EnergiesBand)
        var aProperties: List[Float64] = List[Float64]()
        for i in range(0, size):
            var aCell: Pointer[CVenetianCellEnergy] = self.m_EnergiesBand[i].getCell(t_Side)
            if self.m_CellRotation != 0.0:
                aProperties.append(aCell[0].R_dir_dif(t_Direction.rotate(self.m_CellRotation)))
            else:
                aProperties.append(aCell[0].R_dir_dif(t_Direction))
        return aProperties

    def T_dir_dif(self, t_Side: Side, t_IncomingDirection: CBeamDirection, t_OutgoingDirection: CBeamDirection) -> Float64:
        var aCell: Pointer[CVenetianCellEnergy] = self.m_Energy.getCell(t_Side)
        if self.m_CellRotation != 0.0:
            return aCell[0].T_dir_dir(t_IncomingDirection.rotate(self.m_CellRotation), t_OutgoingDirection.rotate(self.m_CellRotation))
        return aCell[0].T_dir_dir(t_IncomingDirection, t_OutgoingDirection)

    def T_dir_dif_band(self, t_Side: Side, t_IncomingDirection: CBeamDirection, t_OutgoingDirection: CBeamDirection) -> List[Float64]:
        var size: Int = len(self.m_EnergiesBand)
        var aProperties: List[Float64] = List[Float64]()
        for i in range(0, size):
            var aCell: Pointer[CVenetianCellEnergy] = self.m_EnergiesBand[i].getCell(t_Side)
            if self.m_CellRotation != 0.0:
                aProperties.append(aCell[0].T_dir_dir(t_IncomingDirection.rotate(self.m_CellRotation), t_OutgoingDirection.rotate(self.m_CellRotation)))
            else:
                aProperties.append(aCell[0].T_dir_dir(t_IncomingDirection, t_OutgoingDirection))
        return aProperties

    def R_dir_dif(self, t_Side: Side, t_IncomingDirection: CBeamDirection, t_OutgoingDirection: CBeamDirection) -> Float64:
        var aCell: Pointer[CVenetianCellEnergy] = self.m_Energy.getCell(t_Side)
        if self.m_CellRotation != 0.0:
            return aCell[0].R_dir_dir(t_IncomingDirection.rotate(self.m_CellRotation), t_OutgoingDirection.rotate(self.m_CellRotation))
        return aCell[0].R_dir_dir(t_IncomingDirection, t_OutgoingDirection)

    def R_dir_dif_band(self, t_Side: Side, t_IncomingDirection: CBeamDirection, t_OutgoingDirection: CBeamDirection) -> List[Float64]:
        var size: Int = len(self.m_EnergiesBand)
        var aProperties: List[Float64] = List[Float64]()
        for i in range(0, size):
            var aCell: Pointer[CVenetianCellEnergy] = self.m_EnergiesBand[i].getCell(t_Side)
            if self.m_CellRotation != 0.0:
                aProperties.append(aCell[0].R_dir_dir(t_IncomingDirection.rotate(self.m_CellRotation), t_OutgoingDirection.rotate(self.m_CellRotation)))
            else:
                aProperties.append(aCell[0].R_dir_dir(t_IncomingDirection, t_OutgoingDirection))
        return aProperties

    def T_dif_dif(self, t_Side: Side) -> Float64:
        var aCell: Pointer[CVenetianCellEnergy] = self.m_Energy.getCell(t_Side)
        return aCell[0].T_dif_dif()

    def R_dif_dif(self, t_Side: Side) -> Float64:
        var aCell: Pointer[CVenetianCellEnergy] = self.m_Energy.getCell(t_Side)
        return aCell[0].R_dif_dif()