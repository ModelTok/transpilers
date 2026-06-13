from UniformDiffuseCell import CUniformDiffuseCell
from DirectionalDiffuseCell import CDirectionalDiffuseCell
from UniformDiffuseBSDFLayer import CUniformDiffuseBSDFLayer
from DirectionalDiffuseBSDFLayer import CDirectionalDiffuseBSDFLayer
from CellDescription import ICellDescription
from SpecularCellDescription import CSpecularCellDescription
from SpecularCell import CSpecularCell
from SpecularBSDFLayer import CSpecularBSDFLayer
from VenetianCellDescription import CVenetianCellDescription
from VenetianCell import CVenetianCell
from PerforatedCellDescription import CCircularCellDescription, CRectangularCellDescription
from PerforatedCell import CPerforatedCell
from WovenCellDescription import CWovenCellDescription
from WovenCell import CWovenCell
from FlatCellDescription import CFlatCellDescription
from Material import CMaterial
from BSDFHemisphere import CBSDFHemisphere
from BSDFLayer import CBSDFLayer
from BaseCell import CBaseCell
from MatrixBSDFLayer import CMatrixBSDFLayer

@value
struct CBSDFLayerMaker:
    var m_Layer: Pointer[CBSDFLayer]
    var m_Cell: Pointer[CBaseCell]

    @staticmethod
    def getSpecularLayer(t_Material: Pointer[CMaterial], t_BSDF: CBSDFHemisphere) -> Pointer[CBSDFLayer]:
        var aDescription = Pointer[CSpecularCellDescription].new()
        var aCell = Pointer[CSpecularCell].new(t_Material, aDescription)
        return Pointer[CSpecularBSDFLayer].new(aCell, t_BSDF)

    @staticmethod
    def getCircularPerforatedLayer(
        t_Material: Pointer[CMaterial],
        t_BSDF: CBSDFHemisphere,
        x: Float64,
        y: Float64,
        thickness: Float64,
        radius: Float64
    ) -> Pointer[CBSDFLayer]:
        var aCellDescription = Pointer[CCircularCellDescription].new(x, y, thickness, radius)
        var aCell = Pointer[CPerforatedCell].new(t_Material, aCellDescription)
        return Pointer[CUniformDiffuseBSDFLayer].new(aCell, t_BSDF)

    @staticmethod
    def getRectangularPerforatedLayer(
        t_Material: Pointer[CMaterial],
        t_BSDF: CBSDFHemisphere,
        x: Float64,
        y: Float64,
        thickness: Float64,
        xHole: Float64,
        yHole: Float64
    ) -> Pointer[CBSDFLayer]:
        var aCellDescription = Pointer[CRectangularCellDescription].new(x, y, thickness, xHole, yHole)
        var aCell = Pointer[CPerforatedCell].new(t_Material, aCellDescription)
        return Pointer[CUniformDiffuseBSDFLayer].new(aCell, t_BSDF)

    @staticmethod
    def getVenetianLayer(
        t_Material: Pointer[CMaterial],
        t_BSDF: CBSDFHemisphere,
        slatWidth: Float64,
        slatSpacing: Float64,
        slatTiltAngle: Float64,
        curvatureRadius: Float64,
        numOfSlatSegments: Int,
        method: DistributionMethod = DistributionMethod.DirectionalDiffuse,
        isHorizontal: Bool = True
    ) -> Pointer[CBSDFLayer]:
        var aCellDescription = Pointer[CVenetianCellDescription].new(
            slatWidth, slatSpacing, slatTiltAngle, curvatureRadius, numOfSlatSegments
        )
        let horizontalVenetianRotation: Float64 = 0.0
        let verticalVenetianRotation: Float64 = 90.0
        let rotation = isHorizontal ? horizontalVenetianRotation : verticalVenetianRotation
        if method == DistributionMethod.UniformDiffuse:
            var aCell = Pointer[CVenetianCell].new(t_Material, aCellDescription, rotation)
            return Pointer[CUniformDiffuseBSDFLayer].new(aCell, t_BSDF)
        else:
            var aCell = Pointer[CVenetianCell].new(t_Material, aCellDescription)
            return Pointer[CDirectionalDiffuseBSDFLayer].new(aCell, t_BSDF)

    @staticmethod
    def getPerfectlyDiffuseLayer(
        t_Material: Pointer[CMaterial],
        t_BSDF: CBSDFHemisphere
    ) -> Pointer[CBSDFLayer]:
        var aDescription = Pointer[CFlatCellDescription].new()
        var aCell = Pointer[CUniformDiffuseCell].new(t_Material, aDescription)
        return Pointer[CUniformDiffuseBSDFLayer].new(aCell, t_BSDF)

    @staticmethod
    def getDirectionalDiffuseLayer(
        t_Material: Pointer[CMaterial],
        t_BSDF: CBSDFHemisphere
    ) -> Pointer[CBSDFLayer]:
        var aDescription = Pointer[CFlatCellDescription].new()
        var aCell = Pointer[CDirectionalDiffuseCell].new(t_Material, aDescription)
        return Pointer[CDirectionalDiffuseBSDFLayer].new(aCell, t_BSDF)

    @staticmethod
    def getPreLoadedBSDFLayer(
        t_Material: Pointer[CMaterial],
        t_BSDF: CBSDFHemisphere
    ) -> Pointer[CBSDFLayer]:
        var aDescription = Pointer[CFlatCellDescription].new()
        var aCell = Pointer[CDirectionalDiffuseCell].new(t_Material, aDescription)
        return Pointer[CMatrixBSDFLayer].new(aCell, t_BSDF)

    @staticmethod
    def getWovenLayer(
        t_Material: Pointer[CMaterial],
        t_BSDF: CBSDFHemisphere,
        diameter: Float64,
        spacing: Float64
    ) -> Pointer[CBSDFLayer]:
        var aDescription = Pointer[CWovenCellDescription].new(diameter, spacing)
        var aCell = Pointer[CWovenCell].new(t_Material, aDescription)
        return Pointer[CUniformDiffuseBSDFLayer].new(aCell, t_BSDF)

    def __init__(
        inout self,
        t_Material: Pointer[CMaterial],
        t_BSDF: CBSDFHemisphere,
        t_Description: Pointer[ICellDescription] = Pointer[ICellDescription](),
        t_Method: DistributionMethod = DistributionMethod.UniformDiffuse
    ):
        self.m_Cell = Pointer[CBaseCell]()
        if t_Material is None:
            raise Error("Material for BSDF layer must be defined.")
        if t_Description is None:
            t_Description = Pointer[CSpecularCellDescription].new()
        if (t_Description as CSpecularCellDescription) is not None:
            self.m_Layer = CBSDFLayerMaker.getSpecularLayer(t_Material, t_BSDF)
        if (t_Description as CFlatCellDescription) is not None:
            self.m_Layer = CBSDFLayerMaker.getPerfectlyDiffuseLayer(t_Material, t_BSDF)
        if (t_Description as CVenetianCellDescription) is not None:
            let description = t_Description as CVenetianCellDescription
            self.m_Layer = CBSDFLayerMaker.getVenetianLayer(
                t_Material,
                t_BSDF,
                description.slatWidth(),
                description.slatSpacing(),
                description.slatSpacing(),
                description.curvatureRadius(),
                description.numberOfSegments(),
                t_Method,
                0
            )
        if (t_Description as CCircularCellDescription) is not None:
            let description = t_Description as CCircularCellDescription
            self.m_Layer = CBSDFLayerMaker.getCircularPerforatedLayer(
                t_Material,
                t_BSDF,
                description.xDimension(),
                description.yDimension(),
                description.thickness(),
                description.radius()
            )
        if (t_Description as CRectangularCellDescription) is not None:
            let description = t_Description as CRectangularCellDescription
            self.m_Layer = CBSDFLayerMaker.getRectangularPerforatedLayer(
                t_Material,
                t_BSDF,
                description.xDimension(),
                description.yDimension(),
                description.thickness(),
                description.xHole(),
                description.yHole()
            )
        if (t_Description as CWovenCellDescription) is not None:
            let description = t_Description as CWovenCellDescription
            self.m_Layer = CBSDFLayerMaker.getWovenLayer(
                t_Material,
                t_BSDF,
                description.diameter(),
                description.spacing()
            )

    def getLayer(self) -> Pointer[CBSDFLayer]:
        return self.m_Layer

    def getCell(self) -> Pointer[CBaseCell]:
        return self.m_Cell