from DElightManagerC import NaN_QUIET
from BGL import point3, vector3, norm, normalize, sqrlen, len, cross, dot, Char, writewndo
from math import sqrt
from io import StringIO
from sys import isspace

namespace BldgGeomLib:

    @value
    struct line3:
        var origin: point3
        var lDir: vector3

        def __init__(inout self):
            self.origin = point3(0,0,0)
            self.lDir = vector3(1,0,0)

        def __init__(inout self, p1: point3, dir: vector3):
            self.origin = p1
            self.lDir = dir
            if sqrlen(self.lDir) == 0:
                self.lDir = vector3(1,0,0)	# assume x-axis 
                return
            else:
                normalize(self.lDir)

        def __init__(inout self, p1: point3, p2: point3):
            self.origin = p1
            if p1 == p2:
                self.lDir = vector3(1,0,0)	# assume x-axis 
                return
            var xDelta: Float64 = p2[0] - p1[0]
            var yDelta: Float64 = p2[1] - p1[1]
            var zDelta: Float64 = p2[2] - p1[2]
            self.lDir = norm(vector3(xDelta,yDelta,zDelta))
            return

        def __del__(owned self):

        def Origin(self) -> point3:
            return self.origin

        def dir(self) -> vector3:
            return self.lDir

        def normVec(self) -> vector3:
            return norm(cross(self.lDir,vector3(self.origin - point3(0,0,0))))

        def PointOnLine(self, param: Float64) -> point3:
            return (self.origin + param * self.lDir)

        def DistTo(self, pExt: point3) -> Float64:
            return len(cross(self.lDir,(pExt - self.origin)))


    @value
    struct lineseg3(line3):
        var length: Float64

        def __init__(inout self):
            self.origin = point3(0,0,0)
            self.lDir = vector3(1,0,0)
            self.length = 0

        def __init__(inout self, p1: point3, dir: vector3, len: Float64):
            self.origin = p1
            self.lDir = dir
            if sqrlen(self.lDir) == 0:
                self.lDir = vector3(1,0,0)	# assume x-axis 
            else:
                normalize(self.lDir)
            self.length = len

        def __init__(inout self, p1: point3, p2: point3):
            self.origin = p1
            if p1 == p2:
                self.lDir = vector3(1,0,0)	# assume x-axis 
            else:
                var xDelta: Float64 = p2[0] - p1[0]
                var yDelta: Float64 = p2[1] - p1[1]
                var zDelta: Float64 = p2[2] - p1[2]
                self.lDir = norm(vector3(xDelta,yDelta,zDelta))
            var Dx: Float64 = p2[0] - p1[0]
            var Dy: Float64 = p2[1] - p1[1]
            var Dz: Float64 = p2[2] - p1[2]
            self.length = sqrt(Dx*Dx + Dy*Dy + Dz*Dz)

        def __del__(owned self):

        def Length(self) -> Float64:
            return self.length

        def end(self, ii: Int) -> point3:
            if ii == 1:
                return self.origin
            elif ii == 2:
                return self.origin + self.length * self.lDir
            else:
                return point3(NaN_QUIET,NaN_QUIET,NaN_QUIET)	#	need error handler here!

        def xMax(self) -> Float64:
            return (self.end(2)[0] if self.end(2)[0] > self.origin[0] else self.origin[0])

        def xMin(self) -> Float64:
            return (self.end(2)[0] if self.end(2)[0] < self.origin[0] else self.origin[0])

        def yMax(self) -> Float64:
            return (self.end(2)[1] if self.end(2)[1] > self.origin[1] else self.origin[1])

        def yMin(self) -> Float64:
            return (self.end(2)[1] if self.end(2)[1] < self.origin[1] else self.origin[1])

        def zMax(self) -> Float64:
            return (self.end(2)[2] if self.end(2)[2] > self.origin[2] else self.origin[2])

        def zMin(self) -> Float64:
            return (self.end(2)[2] if self.end(2)[2] < self.origin[2] else self.origin[2])


    @value
    struct ray3(line3):
        def __init__(inout self):
            self.origin = point3(0,0,0)
            self.lDir = vector3(1,0,0)

        def __init__(inout self, p1: point3, dir: vector3):
            self.origin = p1
            self.lDir = dir
            if sqrlen(self.lDir) == 0:
                self.lDir = vector3(1,0,0)	# assume x-axis 
            else:
                normalize(self.lDir)

        def __init__(inout self, p1: point3, p2: point3):
            self.origin = p1
            if p1 == p2:
                self.lDir = vector3(1,0,0)	# assume x-axis 
            else:
                var xDelta: Float64 = p2[0] - p1[0]
                var yDelta: Float64 = p2[1] - p1[1]
                var zDelta: Float64 = p2[2] - p1[2]
                self.lDir = norm(vector3(xDelta,yDelta,zDelta))

        def __del__(owned self):

        def PointsToward(self, pl3: plane3) -> Bool:
            var dist: Float64 = pl3.DistTo(self.Origin())
            return (dist * dot(self.lDir, pl3.normVec()) < 0)

        def intersect(self, pl3: plane3, inout param: Float64) -> Bool:
            if not self.PointsToward(pl3):
                return False
            param = dot(pl3.normVec(), (pl3.Origin() - self.origin)) / dot(pl3.normVec(), self.lDir)
            return True


    def write_line3(s: StringIO, line: line3) -> StringIO:
        s.write('[')
        s.write(str(line.Origin()))
        s.write(' ')
        s.write(str(line.dir()))
        s.write(']')
        return s

    def read_line3(s: StringIO, inout line: line3) -> StringIO:
        var lorigin: point3
        var ldir: vector3
        var c: Char
        var osstream = StringIO()
        while s.read(c) and isspace(c):

        if c == '[':
            s.read(lorigin)
            s.read(ldir)
            if not s:
                osstream.write("line3: Expected number while reading line\n")
                writewndo(osstream.str(),"e")
                return s
            while s.read(c) and isspace(c):

            if c != ']':
                s.clear(1)  # ios::failbit
                osstream.write("line3: Expected ']' while reading vector\n")
                writewndo(osstream.str(),"e")
                return s
        else:
            s.clear(1)  # ios::failbit
            osstream.write("line3: Expected '[' while reading vector\n")
            writewndo(osstream.str(),"e")
            return s
        line = line3(lorigin, ldir)
        return s

    def write_lineseg3(s: StringIO, ls: lineseg3) -> StringIO:
        s.write('[')
        s.write(str(ls.end(1)))
        s.write(' ')
        s.write(str(ls.end(2)))
        s.write(']')
        return s

    def read_lineseg3(s: StringIO, inout ls: lineseg3) -> StringIO:
        var end1: point3
        var end2: point3
        var c: Char
        var osstream = StringIO()
        while s.read(c) and isspace(c):

        if c == '[':
            s.read(end1)
            s.read(end2)
            if not s:
                osstream.write("lineseg3: Expected number while reading line\n")
                writewndo(osstream.str(),"e")
                return s
            while s.read(c) and isspace(c):

            if c != ']':
                s.clear(1)  # ios::failbit
                osstream.write("lineseg3: Expected ']' while reading vector\n")
                writewndo(osstream.str(),"e")
                return s
        else:
            s.clear(1)  # ios::failbit
            osstream.write("lineseg3: Expected '[' while reading vector\n")
            writewndo(osstream.str(),"e")
            return s
        ls = lineseg3(end1, end2)
        return s

    def write_ray3(s: StringIO, ray: ray3) -> StringIO:
        s.write('[')
        s.write(str(ray.Origin()))
        s.write(' ')
        s.write(str(ray.dir()))
        s.write(']')
        return s

    def read_ray3(s: StringIO, inout ray: ray3) -> StringIO:
        var rorigin: point3
        var rdir: vector3
        var c: Char
        var osstream = StringIO()
        while s.read(c) and isspace(c):

        if c == '[':
            s.read(rorigin)
            s.read(rdir)
            if not s:
                osstream.write("ray3: Expected number while reading line\n")
                writewndo(osstream.str(),"e")
                return s
            while s.read(c) and isspace(c):

            if c != ']':
                s.clear(1)  # ios::failbit
                osstream.write("ray3: Expected ']' while reading vector\n")
                writewndo(osstream.str(),"e")
                return s
        else:
            s.clear(1)  # ios::failbit
            osstream.write("ray3: Expected '[' while reading vector\n")
            writewndo(osstream.str(),"e")
            return s
        ray = ray3(rorigin, rdir)
        return s