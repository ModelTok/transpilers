from memory import shared_ptr
from vector import DynamicVector
from CellDescription import ICellDescription
from WCECommon import CSeries, Side, Property
from MaterialDescription import CMaterial
from BeamDirection import CBeamDirection

@value
class CBaseCell:
    var m_Material: shared_ptr[CMaterial]
    var m_CellDescription: shared_ptr[ICellDescription]
    var m_CellRotation: Float64

    def __init__(inout self):
        self.m_Material = shared_ptr[CMaterial]()
        self.m_CellDescription = shared_ptr[ICellDescription]()
        self.m_CellRotation = 0.0

    def __init__(inout self, t_Material: shared_ptr[CMaterial], t_CellDescription: shared_ptr[ICellDescription], rotation: Float64 = 0.0):
        self.m_Material = t_Material
        self.m_CellDescription = t_CellDescription
        self.m_CellRotation = rotation

    def setSourceData(inout self, t_SourceData: CSeries):
        self.m_Material.setSourceData(t_SourceData)

    def T_dir_dir(inout self, t_Side: Side, t_Direction: CBeamDirection) -> Float64:
        if self.m_CellRotation != 0.0:
            return self.m_CellDescription.T_dir_dir(t_Side, t_Direction.rotate(self.m_CellRotation))
        return self.m_CellDescription.T_dir_dir(t_Side, t_Direction)

    def R_dir_dir(inout self, t_Side: Side, t_Direction: CBeamDirection) -> Float64:
        if self.m_CellRotation != 0.0:
            return self.m_CellDescription.R_dir_dir(t_Side, t_Direction.rotate(self.m_CellRotation))
        return self.m_CellDescription.R_dir_dir(t_Side, t_Direction)

    def T_dir_dir_band(inout self, t_Side: Side, t_Direction: CBeamDirection) -> DynamicVector[Float64]:
        var value: Float64 = self.T_dir_dir(t_Side, t_Direction)
        var aResults = DynamicVector[Float64]()
        var aMaterials = self.m_Material.getBandProperties(Property.T, t_Side)
        var size: Int = aMaterials.size
        for i in range(size):
            aResults.push_back(value)
        return aResults

    def R_dir_dir_band(inout self, t_Side: Side, t_Direction: CBeamDirection) -> DynamicVector[Float64]:
        var value: Float64 = self.R_dir_dir(t_Side, t_Direction)
        var aResults = DynamicVector[Float64]()
        var aMaterials = self.m_Material.getBandProperties(Property.R, t_Side)
        var size: Int = aMaterials.size
        for i in range(size):
            aResults.push_back(value)
        return aResults

    def getBandWavelengths(self) -> DynamicVector[Float64]:
        assert(self.m_Material is not None)
        return self.m_Material.getBandWavelengths()

    def setBandWavelengths(self, wavelengths: DynamicVector[Float64]):
        assert(self.m_Material is not None)
        self.m_Material.setBandWavelengths(wavelengths)

    def getBandIndex(self, t_Wavelength: Float64) -> Int:
        return self.m_Material.getBandIndex(t_Wavelength)

    def getBandSize(self) -> Int:
        return self.m_Material.getBandSize()

    def getMinLambda(self) -> Float64:
        return self.m_Material.getMinLambda()

    def getMaxLambda(self) -> Float64:
        return self.m_Material.getMaxLambda()

    def Flipped(self, flipped: Bool):
        self.m_Material.Flipped(flipped)