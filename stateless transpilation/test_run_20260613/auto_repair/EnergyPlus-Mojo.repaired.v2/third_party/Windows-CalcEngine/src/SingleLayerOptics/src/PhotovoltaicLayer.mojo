from memory import shared_ptr, make_shared
from SpecularLayer import SpecularLayer, CSpecularCell
from MaterialDescription import CMaterialPhotovoltaic
from FenestrationCommon import CSeries, Side, linearInterpolation
from utils import Vector

@value
struct PVPowerProperties:
    var JSC: Float64   # mA/cm^2
    var VOC: Float64   # V
    var FF: Float64    # Unitless

    def __init__(inout self, jsc: Float64, voc: Float64, ff: Float64):
        self.JSC = jsc
        self.VOC = voc
        self.FF = ff

@value
struct PVPowerPropertiesTable:
    var m_PVPowerProperties: Vector[PVPowerProperties]

    def __init__(inout self):
        self.m_PVPowerProperties = Vector[PVPowerProperties]()

    def __init__(inout self, pvPowerProperties: Vector[PVPowerProperties]):
        self.m_PVPowerProperties = pvPowerProperties

    def voc(self, jsc: Float64) -> Float64:
        let el = jsc / 10   # Need to convert from standard SI into what user provided
        let ind = self.findIndexes(el)
        let value = linearInterpolation(
            self.m_PVPowerProperties[ind.first].JSC,
            self.m_PVPowerProperties[ind.second].JSC,
            self.m_PVPowerProperties[ind.first].VOC,
            self.m_PVPowerProperties[ind.second].VOC,
            el)
        return value

    def ff(self, jsc: Float64) -> Float64:
        let el = jsc / 10   # Need to convert from standard SI into what user provided
        let ind = self.findIndexes(el)
        let value = linearInterpolation(
            self.m_PVPowerProperties[ind.first].JSC,
            self.m_PVPowerProperties[ind.second].JSC,
            self.m_PVPowerProperties[ind.first].FF,
            self.m_PVPowerProperties[ind.second].FF,
            el)
        return value

    struct SearchIndexes:
        var first: Int
        var second: Int

    def findIndexes(self, el: Float64) -> SearchIndexes:
        var index: Int = 0
        for i in range(self.m_PVPowerProperties.size):
            if el > self.m_PVPowerProperties[i].JSC:
                index = i
        let lastIndex = index if index == self.m_PVPowerProperties.size else index + 1
        return SearchIndexes{first: index, second: lastIndex}

@value
class PhotovoltaicLayer(SpecularLayer):
    var m_PVMaterial: shared_ptr[CMaterialPhotovoltaic]
    var m_PVPowerTable: PVPowerPropertiesTable

    def __init__(inout self, cell: CSpecularCell, material: shared_ptr[CMaterialPhotovoltaic]):
        SpecularLayer.__init__(self, cell)
        self.m_PVMaterial = material
        self.m_PVPowerTable = PVPowerPropertiesTable()

    @staticmethod
    def createLayer(material: shared_ptr[CMaterialPhotovoltaic], powerTable: PVPowerPropertiesTable) -> shared_ptr[PhotovoltaicLayer]:
        var aCell = CSpecularCell(material)
        var layer = make_shared[PhotovoltaicLayer](aCell, material)
        layer.assignPowerTable(powerTable)
        return layer

    def jscPrime(self, t_Side: Side) -> CSeries:
        return self.m_PVMaterial.jscPrime(t_Side)

    def assignPowerTable(inout self, powerTable: PVPowerPropertiesTable):
        self.m_PVPowerTable = powerTable

    def voc(self, electricity: Float64) -> Float64:
        return self.m_PVPowerTable.voc(electricity)

    def ff(self, electricity: Float64) -> Float64:
        return self.m_PVPowerTable.ff(electricity)