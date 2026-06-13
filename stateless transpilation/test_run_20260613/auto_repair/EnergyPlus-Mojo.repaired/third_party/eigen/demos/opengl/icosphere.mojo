from icosphere import IcoSphere
from Eigen.Core import *
from GL.gl import *
from map import *
from vector import *

# define X .525731112119133606
# define Z .850650808352039932
let X: Float32 = 0.525731112119133606
let Z: Float32 = 0.850650808352039932

var vdata: StaticFloat32Array[12, 3] = StaticFloat32Array[12, 3](
    (-X, 0.0, Z), (X, 0.0, Z), (-X, 0.0, -Z), (X, 0.0, -Z),
    (0.0, Z, X), (0.0, Z, -X), (0.0, -Z, X), (0.0, -Z, -X),
    (Z, X, 0.0), (-Z, X, 0.0), (Z, -X, 0.0), (-Z, -X, 0.0)
)

var tindices: StaticInt32Array[20, 3] = StaticInt32Array[20, 3](
    (0,4,1), (0,9,4), (9,5,4), (4,5,8), (4,8,1),
    (8,10,1), (8,3,10), (5,3,8), (5,2,3), (2,7,3),
    (7,10,3), (7,6,10), (7,11,6), (11,0,6), (0,1,6),
    (6,1,10), (9,0,11), (9,11,2), (9,2,5), (7,2,11)
)

@value
struct IcoSphere:
    var mVertices: List[Vector3f]
    var mIndices: List[Pointer[List[Int32]]]
    var mListIds: List[Int32]

    def __init__(inout self, levels: UInt32 = 1):
        self.mVertices = List[Vector3f]()
        self.mIndices = List[Pointer[List[Int32]]]()
        self.mListIds = List[Int32]()
        for i in range(12):
            self.mVertices.append(Map[Vector3f](vdata[i]))
        self.mIndices.append(Pointer[List[Int32]](List[Int32]()))
        var indices: List[Int32] = self.mIndices.back()[]
        for i in range(20):
            for k in range(3):
                indices.append(tindices[i][k])
        self.mListIds.append(0)
        while len(self.mIndices) < levels:
            self._subdivide()

    def vertices(self) -> List[Vector3f]:
        return self.mVertices

    def indices(self, level: Int32) -> List[Int32]:
        while level >= len(self.mIndices):
            self._subdivide()
        return self.mIndices[level][]

    def _subdivide(inout self):
        typedef Key: UInt64
        var edgeMap: Map[Key, Int32] = Map[Key, Int32]()
        var indices: List[Int32] = self.mIndices.back()[]
        self.mIndices.append(Pointer[List[Int32]](List[Int32]()))
        var refinedIndices: List[Int32] = self.mIndices.back()[]
        var end: Int32 = len(indices)
        for i in range(0, end, 3):
            var ids0: StaticInt32Array[3] = StaticInt32Array[3]()
            var ids1: StaticInt32Array[3] = StaticInt32Array[3]()
            for k in range(3):
                var k1: Int32 = (k + 1) % 3
                var e0: Int32 = indices[i + k]
                var e1: Int32 = indices[i + k1]
                ids0[k] = e0
                if e1 > e0:
                    swap(e0, e1)
                var edgeKey: Key = Key(e0) | (Key(e1) << 32)
                var it: Map[Key, Int32].Iterator = edgeMap.find(edgeKey)
                if it == edgeMap.end():
                    ids1[k] = len(self.mVertices)
                    edgeMap[edgeKey] = ids1[k]
                    self.mVertices.append((self.mVertices[e0] + self.mVertices[e1]).normalized())
                else:
                    ids1[k] = it.second()
            refinedIndices.append(ids0[0])
            refinedIndices.append(ids1[0])
            refinedIndices.append(ids1[2])
            refinedIndices.append(ids0[1])
            refinedIndices.append(ids1[1])
            refinedIndices.append(ids1[0])
            refinedIndices.append(ids0[2])
            refinedIndices.append(ids1[2])
            refinedIndices.append(ids1[1])
            refinedIndices.append(ids1[0])
            refinedIndices.append(ids1[1])
            refinedIndices.append(ids1[2])
        self.mListIds.append(0)

    def draw(inout self, level: Int32):
        while level >= len(self.mIndices):
            self._subdivide()
        if self.mListIds[level] == 0:
            self.mListIds[level] = glGenLists(1)
            glNewList(self.mListIds[level], GL_COMPILE)
            glVertexPointer(3, GL_FLOAT, 0, self.mVertices[0].data())
            glNormalPointer(GL_FLOAT, 0, self.mVertices[0].data())
            glEnableClientState(GL_VERTEX_ARRAY)
            glEnableClientState(GL_NORMAL_ARRAY)
            glDrawElements(GL_TRIANGLES, len(self.mIndices[level][]), GL_UNSIGNED_INT, &(self.mIndices[level][][0]))
            glDisableClientState(GL_VERTEX_ARRAY)
            glDisableClientState(GL_NORMAL_ARRAY)
            glEndList()
        glCallList(self.mListIds[level])