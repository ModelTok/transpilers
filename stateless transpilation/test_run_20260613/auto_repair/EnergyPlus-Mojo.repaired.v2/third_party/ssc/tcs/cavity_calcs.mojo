"""
BSD-3-Clause
Copyright 2019 Alliance for Sustainable Energy, LLC
Redistribution and use in source and binary forms, with or without modification, are permitted provided 
that the following conditions are met :
1.	Redistributions of source code must retain the above copyright notice, this list of conditions 
and the following disclaimer.
2.	Redistributions in binary form must reproduce the above copyright notice, this list of conditions 
and the following disclaimer in the documentation and/or other materials provided with the distribution.
3.	Neither the name of the copyright holder nor the names of its contributors may be used to endorse 
or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, 
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
ARE DISCLAIMED.IN NO EVENT SHALL THE COPYRIGHT HOLDER, CONTRIBUTORS, UNITED STATES GOVERNMENT OR UNITED STATES 
DEPARTMENT OF ENERGY, NOR ANY OF THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, 
OR CONSEQUENTIAL DAMAGES(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT 
OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
"""
from python import Python
from python.time import time as py_time
from python.random import seed as py_seed, random as py_random
from python.math import floor as py_floor, ceil as py_ceil, fabs as py_fabs, sin as py_sin, cos as py_cos, asin as py_asin, sqrt as py_sqrt, atan as py_atan, log as py_log, tan as py_tan, pi as py_pi, nan as py_nan, inf as py_inf

from htf_props import HTFProperties
from sam_csp_util import CSP
from lib_util import util

struct point:
    var x: Float64
    var y: Float64
    def __init__(inout self):
        self.x = 0.0
        self.y = 0.0
    def __init__(inout self, x_in: Float64, y_in: Float64):
        self.x = x_in
        self.y = y_in
    def __del__(owned self):

struct polygon:
    var p_points: List[point] = List[point]()
    var l_points: Int = 0
    var p_vertices: List[Int] = List[Int]()
    var l_vertices: Int = 0
    def __del__(owned self):
        # no delete needed in Mojo

    def sizePolygon(inout self, m_n_nodes: Int):
        self.p_points = List[point]()
        for _ in range(m_n_nodes):
            self.p_points.append(point())
        self.l_points = m_n_nodes
        self.l_vertices = 2 * self.l_points
        self.p_vertices = List[Int]()
        for _ in range(self.l_vertices):
            self.p_vertices.append(0)
    def getPoint(self, i: Int) -> point:
        return self.p_points[i]
    def getVertice(self, i: Int) -> Int:
        return self.p_vertices[i]
    def n_points(self) -> Int:
        return self.l_points
    def n_vertices(self) -> Int:
        return self.l_vertices
    def SetPoint(inout self, i: Int, p: point):
        self.p_points[i].x = p.x
        self.p_points[i].y = p.y
    def SetVertices(inout self, i: Int, v: Int):
        self.p_vertices[i] = v
    def SetVertices(inout self, arr: List[Int]):
        for i in range(self.l_vertices):
            self.p_vertices[i] = arr[i]

struct Matrix_t:
    var data: List[List[Float64]] = List[List[Float64]]()
    var n_rows: Int = 0
    var n_cols: Int = 0
    def __init__(inout self, rows: Int, cols: Int):
        self.n_rows = rows
        self.n_cols = cols
        self.data = List[List[Float64]]()
        for _ in range(rows):
            self.data.append(List[Float64]())
            for _ in range(cols):
                self.data[-1].append(0.0)
    def at(self, i: Int, j: Int) -> Float64:
        return self.data[i][j]
    def at(self, i: Int, j: Int, val: Float64):
        self.data[i][j] = val

struct Cavity_Calcs:
    var m_n_rays: Int = -1
    var m_h_rec: Float64 = py_nan
    var m_r_rec: Float64 = py_nan
    var m_rec_angle: Float64 = py_nan
    var m_h_lip: Float64 = py_nan
    var m_h_node: Float64 = py_nan
    var m_alpha: Float64 = py_nan
    var m_W: Float64 = py_nan
    var m_c: Float64 = py_nan
    var m_z: Float64 = py_nan
    var m_A_f: Float64 = py_nan
    var m_A_ce: Float64 = py_nan
    var m_A_lip: Float64 = py_nan
    var m_A_o: Float64 = py_nan
    static var m_n_nodes: Int = 5

    def __init__(inout self):
        self.m_n_rays = -1
        self.m_h_rec = py_nan
        self.m_r_rec = py_nan
        self.m_rec_angle = py_nan
        self.m_h_lip = py_nan
        self.m_h_node = py_nan
        self.m_alpha = py_nan
        self.m_W = py_nan
        self.m_c = py_nan
        self.m_z = py_nan
        self.m_A_f = py_nan
        self.m_A_ce = py_nan
        self.m_A_lip = py_nan
        self.m_A_o = py_nan

    def Define_Cavity(inout self, n_rays: Int, h_rec: Float64, r_rec: Float64, rec_angle: Float64, h_lip: Float64) -> Bool:
        self.m_n_rays = n_rays
        self.m_h_rec = h_rec
        self.m_r_rec = r_rec
        self.m_rec_angle = rec_angle
        self.m_h_lip = h_lip
        self.m_h_node = h_rec / Float64(Cavity_Calcs.m_n_nodes)
        self.m_alpha = self.m_rec_angle * 0.25
        self.m_W = 2.0 * self.m_r_rec * py_sin(self.m_alpha / 2.0)
        self.m_c = 2.0 * self.m_r_rec * py_sin(CSP.pi - 2.0 * self.m_alpha)
        self.m_z = self.m_r_rec * py_cos(CSP.pi - 2.0 * self.m_alpha)
        self.m_A_f = 2.0 * self.m_W * self.m_r_rec * py_cos(self.m_alpha / 2.0) + self.m_z * self.m_c
        self.m_A_ce = self.m_A_f
        self.m_A_lip = h_lip * self.m_c
        self.m_A_o = (h_rec - h_lip) * self.m_c
        return False

    def OuterPanel_Floor(inout self, F_AF: List[Float64]):
        const poly_sides: Int = 5
        var floor_polygon: polygon
        floor_polygon.sizePolygon(poly_sides)
        floor_polygon.SetPoint(0, point(0.0, 0.0))
        floor_polygon.SetPoint(1, point(self.m_W, 0.0))
        floor_polygon.SetPoint(2, point(self.m_W * (1.0 + py_cos(self.m_alpha)), self.m_W * py_sin(self.m_alpha)))
        floor_polygon.SetPoint(3, point(self.m_W + 2.0 * self.m_r_rec * py_sin(self.m_alpha) * py_cos(self.m_alpha + py_acos(self.m_r_rec * py_sin(self.m_alpha) / self.m_W)),
                                        2.0 * self.m_r_rec * py_sin(self.m_alpha) * py_sin(self.m_alpha + py_acos(self.m_r_rec * py_sin(self.m_alpha) / self.m_W))))
        floor_polygon.SetPoint(4, point(self.m_c * py_cos(3.0 / 2.0 * self.m_alpha), self.m_c * py_sin(3.0 / 2.0 * self.m_alpha)))
        var vertices: List[Int] = List[Int]([0,1, 1,2, 2,3, 3,4, 4,0])
        floor_polygon.SetVertices(vertices)
        var floor_box: polygon
        floor_box.sizePolygon(4)
        floor_box.SetPoint(0, floor_polygon.getPoint(0))
        floor_box.SetPoint(1, point(floor_polygon.getPoint(2).x, 0.0))
        floor_box.SetPoint(2, point(floor_polygon.getPoint(2).x, floor_polygon.getPoint(4).y))
        floor_box.SetPoint(3, point(0.0, floor_polygon.getPoint(4).y))
        var hits: List[Int] = List[Int]()
        for _ in range(Cavity_Calcs.m_n_nodes):
            hits.append(0)
        var Ptheta: Float64
        var Pphi: Float64
        var theta: Float64
        var phi: Float64
        var r1: Float64
        var r2: Float64
        var x: Float64
        var y: Float64
        var y_i: Float64
        var z_i: Float64
        var p: point
        var hit: Int
        var ray_counts: Int
        py_seed(py_time())
        for ray_counts in range(1, self.m_n_rays + 1):
            for i in range(Cavity_Calcs.m_n_nodes):
                Ptheta = py_random()
                Pphi = py_random()
                theta = py_asin(py_sqrt(Ptheta))
                phi = Pphi * 2.0 * CSP.pi
                if (CSP.pi / 2.0 <= phi and phi <= 3.0 / 2.0 * CSP.pi) or theta == 0.0:
                    hit = 0
                else:
                    r1 = py_random()
                    r2 = py_random()
                    x = (Float64(i + 1) - 1.0 + r1) * self.m_h_node
                    y = r2 * self.m_W
                    y_i = y + py_tan(phi) * (self.m_h_rec - x)
                    z_i = (self.m_h_rec - x) / (py_cos(phi) * py_tan(theta))
                    if y_i < floor_box.getPoint(0).x:
                        hit = 0
                    elif y_i > floor_box.getPoint(1).x:
                        hit = 0
                    elif z_i < floor_box.getPoint(0).y:
                        hit = 0
                    elif z_i > floor_box.getPoint(3).y:
                        hit = 0
                    else:
                        p = point(y_i, z_i)
                        if self.Point_Is_Inside(p, floor_polygon):
                            hit = 1
                        else:
                            hit = 0
                if hit == 1:
                    hits[i] = hits[i] + 1
        for i in range(Cavity_Calcs.m_n_nodes):
            F_AF[Cavity_Calcs.m_n_nodes - 1 - i] = Float64(hits[i]) / Float64(ray_counts)
        return

    def InnerPanel_Floor(inout self, F_BF: List[Float64]):
        const poly_sides: Int = 5
        var floor_polygon: polygon
        floor_polygon.sizePolygon(poly_sides)
        floor_polygon.SetPoint(0, point(-self.m_W * py_sin(CSP.pi / 2.0 - self.m_alpha), self.m_W * py_cos(CSP.pi / 2.0 - self.m_alpha)))
        floor_polygon.SetPoint(1, point(0.0, 0.0))
        floor_polygon.SetPoint(2, point(self.m_W, 0.0))
        floor_polygon.SetPoint(3, point(self.m_W * (1.0 + py_cos(self.m_alpha)), self.m_W * py_sin(self.m_alpha)))
        floor_polygon.SetPoint(4, point(self.m_W + 2.0 * self.m_r_rec * py_sin(self.m_alpha) * py_cos(self.m_alpha + py_acos(self.m_r_rec * py_sin(self.m_alpha) / self.m_W)),
                                        2.0 * self.m_r_rec * py_sin(self.m_alpha) * py_sin(self.m_alpha + py_acos(self.m_r_rec * py_sin(self.m_alpha) / self.m_W))))
        var vertices: List[Int] = List[Int]([0,1, 1,2, 2,3, 3,4, 4,0])
        floor_polygon.SetVertices(vertices)
        var floor_box: polygon
        floor_box.sizePolygon(4)
        floor_box.SetPoint(0, point(floor_polygon.getPoint(0).x, 0.0))
        floor_box.SetPoint(1, point(floor_polygon.getPoint(3).x, 0.0))
        floor_box.SetPoint(2, point(floor_polygon.getPoint(3).x, floor_polygon.getPoint(4).y))
        floor_box.SetPoint(3, point(floor_polygon.getPoint(0).x, floor_polygon.getPoint(4).y))
        var hits: List[Int] = List[Int]()
        for _ in range(Cavity_Calcs.m_n_nodes):
            hits.append(0)
        var Ptheta: Float64
        var Pphi: Float64
        var theta: Float64
        var phi: Float64
        var r1: Float64
        var r2: Float64
        var x: Float64
        var y: Float64
        var y_i: Float64
        var z_i: Float64
        var p: point
        var hit: Int
        var ray_counts: Int
        py_seed(py_time())
        for ray_counts in range(1, self.m_n_rays + 1):
            for i in range(Cavity_Calcs.m_n_nodes):
                Ptheta = py_random()
                Pphi = py_random()
                theta = py_asin(py_sqrt(Ptheta))
                phi = Pphi * 2.0 * CSP.pi
                if (CSP.pi / 2.0 <= phi and phi <= 3.0 / 2.0 * CSP.pi) or theta == 0.0:
                    hit = 0
                else:
                    r1 = py_random()
                    r2 = py_random()
                    x = (Float64(i + 1) - 1.0 + r1) * self.m_h_node
                    y = r2 * self.m_W
                    y_i = y + py_tan(phi) * (self.m_h_rec - x)
                    z_i = (self.m_h_rec - x) / (py_cos(phi) * py_tan(theta))
                    if y_i < floor_box.getPoint(0).x:
                        hit = 0
                    elif y_i > floor_box.getPoint(1).x:
                        hit = 0
                    elif z_i < floor_box.getPoint(0).y:
                        hit = 0
                    elif z_i > floor_box.getPoint(3).y:
                        hit = 0
                    else:
                        p = point(y_i, z_i)
                        if self.Point_Is_Inside(p, floor_polygon):
                            hit = 1
                        else:
                            hit = 0
                if hit == 1:
                    hits[i] = hits[i] + 1
        for i in range(Cavity_Calcs.m_n_nodes):
            F_BF[Cavity_Calcs.m_n_nodes - 1 - i] = Float64(hits[i]) / Float64(ray_counts)
        return

    def Lip_Ceiling(inout self, inout F_LCE: Float64):
        const poly_sides: Int = 5
        var floor_polygon: polygon
        floor_polygon.sizePolygon(poly_sides)
        floor_polygon.SetPoint(0, point(self.m_c, 0.0))
        floor_polygon.SetPoint(1, point(0.5 * self.m_c + self.m_r_rec * py_sin(self.m_alpha), self.m_z + self.m_r_rec * py_cos(self.m_alpha)))
        floor_polygon.SetPoint(2, point(0.5 * self.m_c, self.m_z + self.m_r_rec))
        floor_polygon.SetPoint(3, point(self.m_W * py_cos(1.5 * self.m_alpha), self.m_W * py_sin(1.5 * self.m_alpha)))
        floor_polygon.SetPoint(4, point(0.0, 0.0))
        var vertices: List[Int] = List[Int]([0,1, 1,2, 2,3, 3,4, 4,0])
        floor_polygon.SetVertices(vertices)
        var floor_box: polygon
        floor_box.sizePolygon(4)
        floor_box.SetPoint(0, point(0.0, 0.0))
        floor_box.SetPoint(1, point(self.m_c, 0.0))
        floor_box.SetPoint(2, point(self.m_c, self.m_z + self.m_r_rec))
        floor_box.SetPoint(3, point(0.0, self.m_z + self.m_r_rec))
        var hits: Int = 0
        var Ptheta: Float64
        var Pphi: Float64
        var theta: Float64
        var phi: Float64
        var r1: Float64
        var r2: Float64
        var x: Float64
        var y: Float64
        var y_i: Float64
        var z_i: Float64
        var p: point
        var hit: Int
        var ray_counts: Int
        py_seed(py_time())
        for ray_counts in range(1, self.m_n_rays + 1):
            Ptheta = py_random()
            Pphi = py_random()
            theta = py_asin(py_sqrt(Ptheta))
            phi = Pphi * 2.0 * CSP.pi
            if (CSP.pi / 2.0 <= phi and phi <= 3.0 / 2.0 * CSP.pi) or theta == 0.0:
                hit = 0
            else:
                r1 = py_random()
                r2 = py_random()
                x = r1 * self.m_h_lip
                y = r2 * self.m_c
                y_i = y + py_tan(phi) * (self.m_h_lip - x)
                z_i = (self.m_h_lip - x) / (py_cos(phi) * py_tan(theta))
                if y_i < floor_box.getPoint(0).x:
                    hit = 0
                elif y_i > floor_box.getPoint(1).x:
                    hit = 0
                elif z_i < floor_box.getPoint(0).y:
                    hit = 0
                elif z_i > floor_box.getPoint(3).y:
                    hit = 0
                else:
                    p = point(y_i, z_i)
                    if self.Point_Is_Inside(p, floor_polygon):
                        hit = 1
                    else:
                        hit = 0
            if hit == 1:
                hits = hits + 1
        for _ in range(Cavity_Calcs.m_n_nodes):
            F_LCE = Float64(hits) / Float64(ray_counts)
        return

    def Lip_Floor(inout self, inout F_LF: Float64):
        const poly_sides: Int = 5
        var floor_polygon: polygon
        floor_polygon.sizePolygon(poly_sides)
        floor_polygon.SetPoint(0, point(self.m_c, 0.0))
        floor_polygon.SetPoint(1, point(0.5 * self.m_c + self.m_r_rec * py_sin(self.m_alpha), self.m_z + self.m_r_rec * py_cos(self.m_alpha)))
        floor_polygon.SetPoint(2, point(0.5 * self.m_c, self.m_z + self.m_r_rec))
        floor_polygon.SetPoint(3, point(self.m_W * py_cos(1.5 * self.m_alpha), self.m_W * py_sin(1.5 * self.m_alpha)))
        floor_polygon.SetPoint(4, point(0.0, 0.0))
        var vertices: List[Int] = List[Int]([0,1, 1,2, 2,3, 3,4, 4,0])
        floor_polygon.SetVertices(vertices)
        var floor_box: polygon
        floor_box.sizePolygon(4)
        floor_box.SetPoint(0, point(0.0, 0.0))
        floor_box.SetPoint(1, point(self.m_c, 0.0))
        floor_box.SetPoint(2, point(self.m_c, self.m_z + self.m_r_rec))
        floor_box.SetPoint(3, point(0.0, self.m_z + self.m_r_rec))
        var hits: Int = 0
        var Ptheta: Float64
        var Pphi: Float64
        var theta: Float64
        var phi: Float64
        var r1: Float64
        var r2: Float64
        var x: Float64
        var y: Float64
        var y_i: Float64
        var z_i: Float64
        var p: point
        var hit: Int
        var ray_counts: Int
        py_seed(py_time())
        for ray_counts in range(1, self.m_n_rays + 1):
            Ptheta = py_random()
            Pphi = py_random()
            theta = py_asin(py_sqrt(Ptheta))
            phi = Pphi * 2.0 * CSP.pi
            if (CSP.pi / 2.0 <= phi and phi <= 3.0 / 2.0 * CSP.pi) or theta == 0.0:
                hit = 0
            else:
                r1 = py_random()
                r2 = py_random()
                x = r1 * self.m_h_lip
                y = r2 * self.m_c
                y_i = y + py_tan(phi) * (self.m_h_rec - x)
                z_i = (self.m_h_rec - x) / (py_cos(phi) * py_tan(theta))
                if y_i < floor_box.getPoint(0).x:
                    hit = 0
                elif y_i > floor_box.getPoint(1).x:
                    hit = 0
                elif z_i < floor_box.getPoint(0).y:
                    hit = 0
                elif z_i > floor_box.getPoint(3).y:
                    hit = 0
                else:
                    p = point(y_i, z_i)
                    if self.Point_Is_Inside(p, floor_polygon):
                        hit = 1
                    else:
                        hit = 0
            if hit == 1:
                hits = hits + 1
        for _ in range(Cavity_Calcs.m_n_nodes):
            F_LF = Float64(hits) / Float64(ray_counts)
        return

    def Opening_Ceiling(inout self, inout F_OCE: Float64):
        const poly_sides: Int = 5
        var floor_polygon: polygon
        floor_polygon.sizePolygon(poly_sides)
        floor_polygon.SetPoint(0, point(self.m_c, 0.0))
        floor_polygon.SetPoint(1, point(0.5 * self.m_c + self.m_r_rec * py_sin(self.m_alpha), self.m_z + self.m_r_rec * py_cos(self.m_alpha)))
        floor_polygon.SetPoint(2, point(0.5 * self.m_c, self.m_z + self.m_r_rec))
        floor_polygon.SetPoint(3, point(self.m_W * py_cos(1.5 * self.m_alpha), self.m_W * py_sin(1.5 * self.m_alpha)))
        floor_polygon.SetPoint(4, point(0.0, 0.0))
        var vertices: List[Int] = List[Int]([0,1, 1,2, 2,3, 3,4, 4,0])
        floor_polygon.SetVertices(vertices)
        var floor_box: polygon
        floor_box.sizePolygon(4)
        floor_box.SetPoint(0, point(0.0, 0.0))
        floor_box.SetPoint(1, point(self.m_c, 0.0))
        floor_box.SetPoint(2, point(self.m_c, self.m_z + self.m_r_rec))
        floor_box.SetPoint(3, point(0.0, self.m_z + self.m_r_rec))
        var hits: Int = 0
        var Ptheta: Float64
        var Pphi: Float64
        var theta: Float64
        var phi: Float64
        var r1: Float64
        var r2: Float64
        var x: Float64
        var y: Float64
        var y_i: Float64
        var z_i: Float64
        var p: point
        var hit: Int
        var ray_counts: Int
        py_seed(py_time())
        for ray_counts in range(1, self.m_n_rays + 1):
            Ptheta = py_random()
            Pphi = py_random()
            theta = py_asin(py_sqrt(Ptheta))
            phi = Pphi * 2.0 * CSP.pi
            if (CSP.pi / 2.0 <= phi and phi <= 3.0 / 2.0 * CSP.pi) or theta == 0.0:
                hit = 0
            else:
                r1 = py_random()
                r2 = py_random()
                x = r1 * (self.m_h_rec - self.m_h_lip)
                y = r2 * self.m_c
                y_i = y + py_tan(phi) * (self.m_h_rec - x)
                z_i = (self.m_h_rec - x) / (py_cos(phi) * py_tan(theta))
                if y_i < floor_box.getPoint(0).x:
                    hit = 0
                elif y_i > floor_box.getPoint(1).x:
                    hit = 0
                elif z_i < floor_box.getPoint(0).y:
                    hit = 0
                elif z_i > floor_box.getPoint(3).y:
                    hit = 0
                else:
                    p = point(y_i, z_i)
                    if self.Point_Is_Inside(p, floor_polygon):
                        hit = 1
                    else:
                        hit = 0
            if hit == 1:
                hits = hits + 1
        for _ in range(Cavity_Calcs.m_n_nodes):
            F_OCE = Float64(hits) / Float64(ray_counts)
        return

    def Opening_Floor(inout self, inout F_OF: Float64):
        const poly_sides: Int = 5
        var floor_polygon: polygon
        floor_polygon.sizePolygon(poly_sides)
        floor_polygon.SetPoint(0, point(self.m_c, 0.0))
        floor_polygon.SetPoint(1, point(0.5 * self.m_c + self.m_r_rec * py_sin(self.m_alpha), self.m_z + self.m_r_rec * py_cos(self.m_alpha)))
        floor_polygon.SetPoint(2, point(0.5 * self.m_c, self.m_z + self.m_r_rec))
        floor_polygon.SetPoint(3, point(self.m_W * py_cos(1.5 * self.m_alpha), self.m_W * py_sin(1.5 * self.m_alpha)))
        floor_polygon.SetPoint(4, point(0.0, 0.0))
        var vertices: List[Int] = List[Int]([0,1, 1,2, 2,3, 3,4, 4,0])
        floor_polygon.SetVertices(vertices)
        var floor_box: polygon
        floor_box.sizePolygon(4)
        floor_box.SetPoint(0, point(0.0, 0.0))
        floor_box.SetPoint(1, point(self.m_c, 0.0))
        floor_box.SetPoint(2, point(self.m_c, self.m_z + self.m_r_rec))
        floor_box.SetPoint(3, point(0.0, self.m_z + self.m_r_rec))
        var hits: Int = 0
        var Ptheta: Float64
        var Pphi: Float64
        var theta: Float64
        var phi: Float64
        var r1: Float64
        var r2: Float64
        var x: Float64
        var y: Float64
        var y_i: Float64
        var z_i: Float64
        var p: point
        var hit: Int
        var ray_counts: Int
        py_seed(py_time())
        for ray_counts in range(1, self.m_n_rays + 1):
            Ptheta = py_random()
            Pphi = py_random()
            theta = py_asin(py_sqrt(Ptheta))
            phi = Pphi * 2.0 * CSP.pi
            if (CSP.pi / 2.0 <= phi and phi <= 3.0 / 2.0 * CSP.pi) or theta == 0.0:
                hit = 0
            else:
                r1 = py_random()
                r2 = py_random()
                x = self.m_h_lip + r1 * (self.m_h_rec - self.m_h_lip)
                y = r2 * self.m_c
                y_i = y + py_tan(phi) * (self.m_h_rec - x)
                z_i = (self.m_h_rec - x) / (py_cos(phi) * py_tan(theta))
                if y_i < floor_box.getPoint(0).x:
                    hit = 0
                elif y_i > floor_box.getPoint(1).x:
                    hit = 0
                elif z_i < floor_box.getPoint(0).y:
                    hit = 0
                elif z_i > floor_box.getPoint(3).y:
                    hit = 0
                else:
                    p = point(y_i, z_i)
                    if self.Point_Is_Inside(p, floor_polygon):
                        hit = 1
                    else:
                        hit = 0
            if hit == 1:
                hits = hits + 1
        for _ in range(Cavity_Calcs.m_n_nodes):
            F_OF = Float64(hits) / Float64(ray_counts)
        return

    def PanelViewFactors(inout self, inout F_A_B: Matrix_t, inout F_A_C: Matrix_t, inout F_A_D: Matrix_t,
        F_A_O: List[Float64], F_A_L: List[Float64], F_B_O: List[Float64], F_B_L: List[Float64]):
        """
Author: Lukas Feierabend
Converted from Fortran (sam_lf_pt_viewmod) to c++ in November 2012 by Ty Neises
!This programs returns the view factors from each panel 1-4, counted from one outer panel to the other side (assuming symmetric setup), to its surroundings.
!The calculations can only be made for receivers with four panels which are of equal size.
!----------------------------------------------------------------------------------------------------------------------
!-outputs
!   * F_A_B     |   View factors between nodes of panel A and nodes of panel B
!   * F_A_C     |   View factors between nodes of panel A and nodes of panel C
!   * F_A_D     |   View factors between nodes of panel A and nodes of panel D
!   * F_A_O     |   View factors between nodes of panel A and opening (O)
!   * F_A_L     |   View factors between nodes of panel A and lip (L)
!   * F_B_O     |   View factors between nodes of panel B and opening (O)
!   * F_B_L     |   View factors between nodes of panel B and opening (L)
!---------------------------------------------------------------------------------------------------------------------- """
        var phi_1: Float64 = CSP.pi - self.m_alpha
        var phi_2: Float64 = CSP.pi - 2 * self.m_alpha
        var phi_3: Float64 = CSP.pi - 3 * self.m_alpha
        var phi_4: Float64 = (self.m_rec_angle - self.m_alpha) / 2.0
        var phi_5: Float64 = self.m_alpha / 2.0
        var a_1: Float64 = self.m_W / (2.0 * py_cos(self.m_alpha))
        var a_2: Float64 = self.m_r_rec * py_sin(self.m_alpha) / py_sin((CSP.pi - 3.0 * self.m_alpha) / 2.0)
        var a_3: Float64 = (self.m_r_rec + self.m_z) / py_sin(self.m_alpha / 2.0) - self.m_W
        var a_4: Float64 = (self.m_r_rec + self.m_z) / py_tan(self.m_alpha / 2.0) - self.m_c / 2.0
        for i in range(Cavity_Calcs.m_n_nodes):
            F_A_B.at(i, 0, self.F3D_30(0.0, self.m_W, 0.0, self.m_h_node, Float64(i) * self.m_h_node, Float64(i + 1) * self.m_h_node, 0.0, self.m_W, phi_1))
            F_A_C.at(i, 0, self.F3D_30(a_1, a_1 + self.m_W, 0.0, self.m_h_node, Float64(i) * self.m_h_node, Float64(i + 1) * self.m_h_node, a_1, a_1 + self.m_W, phi_2))
            F_A_D.at(i, 0, self.F3D_30(a_2, a_2 + self.m_W, 0.0, self.m_h_node, Float64(i) * self.m_h_node, Float64(i + 1) * self.m_h_node, a_2, a_2 + self.m_W, phi_3))
            F_A_O[Cavity_Calcs.m_n_nodes - i - 1] = self.F3D_30(0.0, self.m_W, Float64(i) * self.m_h_node, Float64(i + 1) * self.m_h_node, self.m_h_lip, self.m_h_rec, 0.0, self.m_c, phi_4)
            F_A_L[Cavity_Calcs.m_n_nodes - i - 1] = self.F3D_30(0.0, self.m_W, Float64(i) * self.m_h_node, Float64(i + 1) * self.m_h_node, 0.0, self.m_h_lip, 0.0, self.m_c, phi_4)
            F_B_O[Cavity_Calcs.m_n_nodes - i - 1] = self.F3D_30(a_3, a_3 + self.m_W, Float64(i) * self.m_h_node, Float64(i + 1) * self.m_h_node, self.m_h_lip, self.m_h_rec, a_4, a_4 + self.m_c, phi_5)
            F_B_L[Cavity_Calcs.m_n_nodes - i - 1] = self.F3D_30(a_3, a_3 + self.m_W, Float64(i) * self.m_h_node, Float64(i + 1) * self.m_h_node, 0.0, self.m_h_lip, a_4, a_4 + self.m_c, phi_5)
        return

    def GetGeometry(self, inout h_node: Float64, inout alpha: Float64, inout W_panel: Float64, inout W_aperture: Float64, inout z: Float64):
        h_node = self.m_h_node
        alpha = self.m_alpha
        W_panel = self.m_W
        W_aperture = self.m_c
        z = self.m_z
        return

    def CalG(self, x: Float64, y: Float64, eta: Float64, xi_1: Float64, xi_2: Float64, theta: Float64) -> Float64:
        # This function integrates the expression for G using a flexible step size. The step size for the next step is based on 
        # the magnitude of the second derivative G''. This is evaluated by considering the difference between the predicted 
        # position of the current value based on the previous 2 values and the actual value obtained from the equation. 
        var recalc: Bool = False
        var tol: Float64 = 1.E-6
        var min_step: Float64 = 1.E-9 * (xi_2 - xi_1)
        var step: Float64 = min_step
        var xi: Float64 = xi_1
        var G: Float64 = 0.0
        var xi0: Float64 = xi
        var v1: Float64
        var v2: Float64
        var v3: Float64
        var dx32: Float64
        var dx21: Float64
        var dv32: Float64
        var vexp: Float64
        var err: Float64
        var i: Int = 0
        var n: Int = 0
        while True:
            i = i + 1
            n = n + 1
            if not recalc and i > 1:
                v3 = v2
                v2 = v1
                dx32 = dx21
            dx21 = step
            v1 = ((x - xi * py_cos(theta)) * py_cos(theta) - xi * py_pow(py_sin(theta), 2)) / \
                 (py_pow((py_pow(x, 2) - 2 * x * xi * py_cos(theta) + py_pow(xi, 2)), 0.5) *
                  py_pow(py_sin(theta), 2)) * py_atan((eta - y) / py_pow((py_pow(x, 2) - 2 * x * xi * py_cos(theta) + py_pow(xi, 2)), 0.5)) + \
                 py_cos(theta) / ((eta - y) * py_pow(py_sin(theta), 2)) * \
                 (py_pow(((py_pow(xi, 2) * py_pow(py_sin(theta), 2)) + py_pow((eta - y), 2)), 0.5) *
                  py_atan((x - xi * py_cos(theta)) / py_pow((py_pow(xi, 2) * py_pow(py_sin(theta), 2) + py_pow((eta - y), 2)), 0.5)) -
                  xi * py_sin(theta) * py_atan((x - xi * py_cos(theta)) / py_sin(theta))) + \
                 xi / (2 * (eta - y)) * py_log((py_pow(x, 2) - 2 * x * xi * py_cos(theta) + py_pow(xi, 2) +
                                               py_pow((eta - y), 2)) / (py_pow(x, 2) - 2 * x * xi * py_cos(theta) + py_pow(xi, 2)))
            if i == 1:
                v2 = v1
                v3 = v1
                dx32 = step
                dx21 = step
            dv32 = (v2 - v3) / dx32
            if i > 2:
                vexp = v2 + dx21 * dv32
            else:
                vexp = v1
            err = py_fabs((vexp - v1) / v1) / tol
            if err > 1.0 and step > min_step:
                if i > 2:
                    step = max(step * py_pow(10, 1.0 - err), min_step)
                recalc = True
                xi = min(xi0 + step, xi_2)
                i = i - 1
            else:
                G = G + (v1 + v2) / 2.0 * step
                if i > 2:
                    step = max(step * py_pow(10, (1.0 - err)), min_step)
                recalc = False
                if xi >= xi_2:
                    break
                xi0 = xi
                xi = min(xi + step, xi_2)
        var calG: Float64 = -(eta - y) * py_pow(py_sin(theta), 2) / (2 * CSP.pi) * G
        return calG

    def G3D30(self, x: Float64, y: Float64, eta: Float64, xi_1: Float64, xi_2: Float64, alpha: Float64) -> Float64:
        # !Function for calculating the view factor for rectangles with parallel and perpendicular edges and 
        # !with an arbitrary angle theta between their intersecting planes, the rectangles can't be flush in 
        # !the direction of the intersection line.
        # !Reference: http://www.me.utexas.edu/~howell/sectionc/C-17.html. 
        # Author: Lukas Feierabend
        # Converted from Fortran (sam_lf_pt_viewmod) to c++ in November 2012 by Ty Neises	
        if y == eta:
            y = y + 1.E-6
        if x == 0 and xi_1 == 0:
            x = 1.E-6
        var G3D30: Float64 = self.CalG(x, y, eta, xi_1, xi_2, alpha)
        return G3D30

    def F3D_30(self, x_1: Float64, x_2: Float64, y_1: Float64, y_2: Float64, eta_1: Float64, eta_2: Float64,
                z_1: Float64, z_2: Float64, theta: Float64) -> Float64:
        # !Function for calculating the view factor for rectangles with parallel and perpendicular edges and 
        # !with an arbitrary angle theta between their intersecting planes, the rectangles can't be flush in 
        # !the direction of the intersection line.
        # !Reference: http://www.me.utexas.edu/~howell/sectionc/C-17.html. 
        # Author: Lukas Feierabend
        # Converted from Fortran (sam_lf_pt_viewmod) to c++ in November 2012 by Ty Neises	
        var G_1_1_1: Float64 = self.G3D30(x_1, y_1, eta_1, z_1, z_2, theta)
        var G_1_1_2: Float64 = self.G3D30(x_1, y_1, eta_2, z_1, z_2, theta)
        var G_1_2_1: Float64 = self.G3D30(x_1, y_2, eta_1, z_1, z_2, theta)
        var G_1_2_2: Float64 = self.G3D30(x_1, y_2, eta_2, z_1, z_2, theta)
        var G_2_1_1: Float64 = self.G3D30(x_2, y_1, eta_1, z_1, z_2, theta)
        var G_2_1_2: Float64 = self.G3D30(x_2, y_1, eta_2, z_1, z_2, theta)
        var G_2_2_1: Float64 = self.G3D30(x_2, y_2, eta_1, z_1, z_2, theta)
        var G_2_2_2: Float64 = self.G3D30(x_2, y_2, eta_2, z_1, z_2, theta)
        return (-G_1_1_1 + G_2_1_1 + G_1_2_1 - G_2_2_1 + G_1_1_2 - G_2_1_2 - G_1_2_2 + G_2_2_2) / ((x_2 - x_1) * (y_2 - y_1))

    def Ray_Intersects_Seg(self, p: point, a0: point, b0: point) -> Bool:
        # Author: Lukas Feierabend
        # Converted from Fortran (sam_lf_pt_viewmod) to c++ in November 2012 by Ty Neises	
        var a: point
        var b: point
        var eps: Float64 = 0.00001
        if a0.y > b0.y:
            b = a0
            a = b0
        else:
            a = a0
            b = b0
        if p.y == a.y or p.y == b.y:
            p.y = p.y + eps
        if p.y > b.y or p.y < a.y:
            return False
        if p.x > max(a.x, b.x):
            return False
        var m_red: Float64
        var m_blue: Float64
        if p.x < min(a.x, b.x):
            return True
        else:
            if py_fabs(a.x - b.x) > py_inf:
                m_red = (b.y - a.y) / (b.x - a.x)
            else:
                m_red = py_inf
            if py_fabs(a.x - p.x) > py_inf:
                m_blue = (p.y - a.y) / (p.x - a.x)
            else:
                m_blue = py_inf
            if m_blue >= m_red:
                return True
            else:
                return False

    def Point_Is_Inside(self, inout p: point, pol: polygon) -> Bool:
        # Author: Lukas Feierabend
        # Converted from Fortran (sam_lf_pt_viewmod) to c++ in November 2012 by Ty Neises	
        var count: Int = 0
        var index_a: Int
        var index_b: Int
        var size_pol: Int = pol.n_vertices()
        for i in range(0, size_pol, 2):
            index_a = pol.getVertice(i)
            index_b = pol.getVertice(i + 1)
            if self.Ray_Intersects_Seg(p, pol.getPoint(index_a), pol.getPoint(index_b)):
                count = count + 1
        if count % 2 == 0:
            return False
        else:
            return True

    def ConvectionClausing1983(inout self, n_panels: Int, inout T_s: Matrix_t, T_F: Float64, T_CE: Float64,
        T_L: Float64, T_amb: Float64, P_amb: Float64, A_node: Float64,
        Q_radiation_loss: Float64, inout q_convection_Clausing1983: Float64, inout h_F: Float64, inout h_avg: Float64,
        inout h_stag: Float64, inout T_stag: Float64, inout T_bulk: Float64, inout S: Int):
        # Author: Soenke Teichel
        # Converted from Fortran (sam_lf_pt_viewmod) to c++ in November 2012 by Ty Neises	
        /***********************************************************************************
        !This subroutine calculates the total convective heat losses from the receiver
        !with the correlations presented in Clausing (1983).
        !  The inputs are:
        !    - N_nodes -> number of vertical nodes per receiver panel [-]
        !    - N_panels -> number of receiver panels [-]
        !    - T_F -> the temperature of the receiver FLOOR [K]
        !    - T_amb -> ambient temperature [K]
        !    - P_amb -> ambient pressure [Pa]
        !    - H_rec -> internal receiver height [m]
        !    - H_lip -> height of the upper lip [m]
        !    - R_rec -> internal receiver radius [m]
        !    - alpha -> segment angle [rad]
        !    - W_panel -> width of one receiver panel [m]
        !    - A_node -> area of the active receiver surfaces [m2]
        !    - A_F -> area of the FLOOR surface [m2]
        !    - A_O -> area of the aperture [m2]
        !  The outputs are:
        !    - q_convection_Clausing1983 -> the total convective heat losses through the aperture [W]
        !**********************************************************************************
        !ST - from EES
        W = 2.*R_rec*SIN(alpha/2.)		!panel width if panels have equal size
        c = 2.*R_rec*SIN(PI-2.*alpha)    !distance between the vertical aperture edges if the aperature is considered to be at the outer edges of the outer panels */
        var grav: Float64 = 9.81
        S = py_ceil(self.m_h_lip / (self.m_h_rec / Float64(Cavity_Calcs.m_n_nodes)))
        var T_F_calc: Float64 = T_F
        var T_sum_avg: Float64 = 0.0
        for i in range(Cavity_Calcs.m_n_nodes - S):
            for j in range(n_panels):
                T_sum_avg += T_s.at(i, j)
        var T_sum_stag: Float64 = 0.0
        for i in range(Cavity_Calcs.m_n_nodes - S, Cavity_Calcs.m_n_nodes):
            for j in range(n_panels):
                T_sum_stag += T_s.at(i, j)
        var T_avg: Float64 = T_sum_avg / Float64(n_panels * (Cavity_Calcs.m_n_nodes - S))
        T_stag = T_sum_stag / 8.0
        T_stag = (T_sum_stag + T_CE + T_L) / Float64(S * n_panels + 2)
        if T_F_calc / T_amb > 2.6:
            T_F_calc = 2.6 * T_amb
        if T_stag / T_amb > 2.6:
            T_stag = 2.6 * T_amb
        if T_avg / T_amb > 2.6:
            T_avg = 2.6 * T_amb
        var beta_amb: Float64 = 1.0 / T_amb
        var air: HTFProperties
        air.SetFluid(HTFProperties.Air)
        var rho_amb: Float64
        var c_p_amb: Float64
        rho_amb = air.dens(T_amb, P_amb)
        c_p_amb = air.Cp(T_amb) * 1000.0
        var v: Float64 = 0.0
        var error: Float64 = 9999.9
        var iter: Int = 0
        var T_c: Float64 = T_avg
        var q_convection_Clausing1983X: Float64 = Q_radiation_loss
        q_convection_Clausing1983 = 5.0
        var T_film_F: Float64
        var T_film_stag: Float64
        var T_film_avg: Float64
        var beta_F: Float64
        var beta_stag: Float64
        var beta_avg: Float64
        var k_F: Float64
        var k_stag: Float64
        var k_avg: Float64
        var c_p_F: Float64
        var c_p_stag: Float64
        var c_p_avg: Float64
        var mu_F: Float64
        var mu_stag: Float64
        var mu_avg: Float64
        var Pr_F: Float64
        var Pr_stag: Float64
        var Pr_avg: Float64
        var rho_F: Float64
        var rho_stag: Float64
        var rho_avg: Float64
        var Gr_F: Float64
        var Gr_stag: Float64
        var Gr_avg: Float64
        var Ra_F: Float64
        var Ra_stag: Float64
        var Ra_avg: Float64
        var Nusselt_F: Float64
        var Nusselt_stag: Float64
        var Nusselt_avg: Float64
        var q_conv_1: Float64
        var q_conv_2: Float64
        var q_conv_3: Float64
        var q_conv_4: Float64
        var v_b: Float64
        var v_a: Float64
        while error > 1.E-12 and iter < 50:
            iter += 1
            error = py_fabs((q_convection_Clausing1983X - q_convection_Clausing1983) / q_convection_Clausing1983)
            q_convection_Clausing1983 = q_convection_Clausing1983X
            T_bulk = (T_c + T_amb) / 2.0
            T_film_F = (T_F_calc + T_bulk) / 2.0
            T_film_stag = (T_stag + T_bulk) / 2.0
            T_film_avg = (T_avg + T_bulk) / 2.0
            beta_F = 1.0 / T_film_F
            beta_stag = 1.0 / T_film_stag
            beta_avg = 1.0 / T_film_avg
            k_F = air.cond(T_film_F)
            k_stag = air.cond(T_film_stag)
            k_avg = air.cond(T_film_avg)
            c_p_F = air.Cp(T_film_F) * 1000.0
            c_p_stag = air.Cp(T_film_stag) * 1000.0
            c_p_avg = air.Cp(T_film_avg) * 1000.0
            mu_F = air.visc(T_film_F)
            mu_stag = air.visc(T_film_stag)
            mu_avg = air.visc(T_film_avg)
            Pr_F = (c_p_F * mu_F) / k_F
            Pr_stag = (c_p_stag * mu_stag) / k_stag
            Pr_avg = (c_p_avg * mu_avg) / k_avg
            rho_F = air.dens(T_film_F, P_amb)
            rho_stag = air.dens(T_film_stag, P_amb)
            rho_avg = air.dens(T_film_avg, P_amb)
            Gr_F = ((grav * beta_F * (T_F_calc - T_bulk) * py_pow((self.m_A_f / (4 * self.m_W + self.m_c)), 3)) / (py_pow((mu_F / rho_F), 2)))
            Gr_stag = ((grav * beta_stag * (T_stag - T_bulk) * py_pow((self.m_A_f / (4 * self.m_W + self.m_c)), 3)) / (py_pow((mu_stag / rho_stag), 2)))
            Gr_avg = ((grav * beta_avg * (T_avg - T_bulk) * py_pow((self.m_h_rec - self.m_h_lip), 3)) / (py_pow((mu_avg / rho_avg), 2)))
            Ra_F = py_fabs(Gr_F * Pr_F)
            Ra_stag = py_fabs(Gr_stag * Pr_stag)
            Ra_avg = py_fabs(Gr_avg * Pr_avg)
            Nusselt_F = (0.082 * py_pow(Ra_F, (1. / 3.)) * (-0.9 + 2.4 * (T_F_calc / T_amb) - 0.5 * py_pow((T_F_calc / T_amb), 2)))
            Nusselt_stag = (2. / 3. * 0.082 * py_pow(Ra_stag, (1. / 3.)) * (-0.9 + 2.4 * (T_stag / T_amb) - 0.5 * py_pow((T_stag / T_amb), 2)))
            Nusselt_avg = (0.082 * py_pow(Ra_avg, (1. / 3.)) * (-0.9 + 2.4 * (T_avg / T_amb) - 0.5 * py_pow((T_avg / T_amb), 2)))
            h_F = (((4. * self.m_W + self.m_c) * k_F) / (self.m_A_f)) * Nusselt_F
            h_stag = (((4. * self.m_W + self.m_c) * k_stag) / (self.m_A_f)) * Nusselt_stag
            h_avg = (k_avg / (self.m_h_rec - self.m_h_lip)) * Nusselt_avg
            q_conv_1 = 0.0
            for i in range(Cavity_Calcs.m_n_nodes - S):
                for j in range(n_panels):
                    q_conv_1 += h_avg * A_node * (T_s.at(i, j) - T_bulk)
            q_conv_2 = 0.0
            for i in range(Cavity_Calcs.m_n_nodes - S, Cavity_Calcs.m_n_nodes):
                for j in range(n_panels):
                    q_conv_2 += h_avg * (S * A_node - self.m_W * self.m_h_lip) * (T_s.at(i, j) - T_bulk)
            q_conv_3 = 0.0
            q_conv_4 = h_F * self.m_A_f * (T_F_calc - T_bulk) + h_stag * 0.3 * self.m_A_f * (T_stag - T_bulk)
            q_convection_Clausing1983X = q_conv_1 + q_conv_2 + q_conv_3 + q_conv_4
            v_b = py_sqrt(grav * beta_amb * (T_c - T_amb) * (self.m_h_rec - self.m_h_lip))
            v_a = 0.5 * py_sqrt(py_pow(v_b, 2.0) + py_pow((v / 2.), 2.0))
            T_c = q_convection_Clausing1983X / (rho_amb * v_a * self.m_A_o * 0.5 * c_p_amb) + T_amb
        return

    def ConvectionClausing1987(inout self, n_panels: Int, inout T_s: Matrix_t, T_F: Float64, T_amb: Float64,
        P_amb: Float64, inout q_convection: Float64):
        # Author: Lukas Feierabend
        # Converted from Fortran (sam_lf_pt_viewmod) to c++ in November 2012 by Ty Neises	
        # /* **********************************************************************************
        # !This subroutine calculates the total convective heat losses from the receiver
        # !with the correlations presented in Clausing (1987).
        # !  The inputs are:
        # !    - N_nodes -> number of vertical nodes per receiver panel [-]
        # !    - N_panels -> number of receiver panels [-]
        # !    - T_s -> the array of surface temperature for every active surface node [K]
        # !    - T_F -> the temperature of the receiver FLOOR [K]
        # !    - T_amb -> ambient temperature [K]
        # !    - P_amb -> ambient pressure [Pa]
        # !    - H_rec -> internal receiver height [m]
        # !    - H_lip -> height of the upper lip [m]
        # !    - W_panel -> width of one receiver panel [m]
        # !    - A_F -> area of the FLOOR surface [m2]
        # !    - A_O -> area of the aperture [m2]
        # !  The outputs are:
        # !    - q_convection -> the total convective heat losses through the aperture [W]
        # !********************************************************************************** */
        var grav: Float64 = 9.81
        var ratio_H: Float64 = self.m_h_lip / self.m_h_node
        var CE: Float64 = py_ceil(ratio_H)
        var FL: Float64 = py_floor(ratio_H)
        var MO: Float64 = ratio_H - Float64(FL)
        var A_node: Float64 = self.m_h_node * self.m_W
        var sum_T_lower: Float64 = 0.0
        for i in range(Cavity_Calcs.m_n_nodes - Int(CE)):
            for j in range(n_panels):
                sum_T_lower += T_s.at(i, j)
        var sum_T_upper: Float64 = 0.0
        for i in range(Cavity_Calcs.m_n_nodes - Int(CE), Cavity_Calcs.m_n_nodes):
            for j in range(n_panels):
                sum_T_upper += T_s.at(i, j)
        var T_w_ave: Float64 = (sum_T_lower * A_node + (1.0 - MO) * sum_T_upper * A_node + (2.0 / 3.0) * self.m_A_f * T_F) / ( (Float64(Cavity_Calcs.m_n_nodes - Int(CE)) + 1.0 - MO) * Float64(n_panels) * A_node + (2.0 / 3.0) * self.m_A_f )
        if T_w_ave < 250.0:
            q_convection = 0.0
            return
        var T_film: Float64 = (T_w_ave + T_amb) / 2.0
        var L_a: Float64 = self.m_h_rec - self.m_h_lip
        var L_c: Float64 = L_a + 0.5 * self.m_h_rec
        var A_cz: Float64 = self.m_A_f + self.m_A_o + Float64(n_panels) * self.m_W * (self.m_h_rec - self.m_h_lip) * CSP.pi / 2.0
        var air: HTFProperties
        air.SetFluid(HTFProperties.Air)
        var c_p_amb: Float64 = air.Cp(T_amb) * 1000.0
        var c_p_film: Float64 = air.Cp(T_film) * 1000.0
        var beta_amb: Float64 = 1.0 / T_amb
        var beta_film: Float64 = 1.0 / T_film
        var k_amb: Float64 = air.cond(T_amb)
        var k_film: Float64 = air.cond(T_film)
        var mu_amb: Float64 = air.visc(T_amb)
        var mu_film: Float64 = air.visc(T_film)
        var rho_amb: Float64 = air.dens(T_amb, P_amb)
        var rho_film: Float64 = air.dens(T_film, P_amb)
        var Pr_amb: Float64 = c_p_amb * mu_amb / k_amb
        var Pr_film: Float64 = c_p_film * mu_film / k_film
        var Ra_amb: Float64 = grav * beta_amb * (T_w_ave - T_amb) * py_pow(L_c, 3) * py_pow((rho_amb / mu_amb), 2) * Pr_amb
        var Ra_film: Float64 = grav * beta_film * (T_w_ave - T_amb) * py_pow(L_c, 3) * py_pow((rho_film / mu_film), 2) * Pr_film
        var g: Float64
        var f: Float64
        if Ra_film < 3.8E+8:
            g = 0.63 * py_pow(Ra_film, 0.25)
            f = 1.0
        elif Ra_film < 1.6E+9:
            g = 0.63 * py_pow(Ra_film, 0.25)
            f = (-0.7476 + 0.9163 * (T_w_ave / T_amb) - 0.1663 * py_pow((T_w_ave / T_amb), 2)) * (py_pow(Ra_film, (1.0 / 3.0)) - py_pow(3.8E8, (1.0 / 3.0))) / (py_pow(1.69E9, (1.0 / 3.0)) - py_pow(3.8E8, (1.0 / 3.0))) + 1
        else:
            g = 0.108 * py_pow(Ra_film, (1.0 / 3.0))
            f = 0.2524 + 0.9163 * (T_w_ave / T_amb) - 0.1663 * py_pow((T_w_ave / T_amb), 2)
        var b: Float64 = 1.0
        var error: Float64 = 9999.0
        var bX: Float64
        while error > 1.E-6:
            bX = 1 - 1.57 * py_pow(((g * f * b * k_film / k_amb) / (py_pow((Ra_amb * Pr_amb * L_a / L_c), 0.5) * self.m_A_o / A_cz)), (2.0 / 3.0))
            error = py_fabs(b - bX) / b
            b = bX
        q_convection = g * f * b * k_film * A_cz * (T_w_ave - T_amb) / L_c
        return