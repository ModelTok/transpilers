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
from math import sqrt, pow, fabs, exp, erf, sin, cos, atan2, log, floor, ceil, pi as PI
from pointer import AnyPointer
from exceptions import spexception
from definitions import PI as def_pi  # Not directly used, but keep import consistent

# Note: PI is defined in math as PI, but original uses PI from definitions.h. We'll use math.pi.

struct LayoutData:
    var extents_r: List[Float64]
    var extents_az: List[Float64]
    var tht: Float64
    var alpha: Float64
    var theta: Float64
    var L_f: Float64
    var H_h: Float64
    var H_w: Float64
    var s_h: Float64
    var w_rec: Float64
    var f_tol: Float64
    var t_res: Float64
    var max_zsize_r: Float64
    var max_zsize_a: Float64
    var min_zsize_r: Float64
    var min_zsize_a: Float64
    var flat: Bool
    var onslant: Bool
    var nph: Int
    var npw: Int

    def set_data(inout self, Extents_r: List[Float64], Extents_az: List[Float64], Tht: Float64, Alpha: Float64, Theta: Float64, l_f: Float64,
                h_h: Float64, h_w: Float64, S_h: Float64, W_rec: Float64, F_tol: Float64, T_res: Float64, Flat: Bool, Onslant: Bool,
                Nph: Int, Npw: Int):
        for i in range(2):
            self.extents_r[i] = Extents_r[i]
            self.extents_az[i] = Extents_az[i]
        self.tht = Tht
        self.alpha = Alpha
        self.theta = Theta
        self.L_f = l_f
        self.H_h = h_h
        self.H_w = h_w
        self.s_h = S_h
        self.w_rec = W_rec
        self.f_tol = F_tol
        self.t_res = T_res
        self.flat = Flat
        self.onslant = Onslant
        self.nph = Nph
        self.npw = Npw


class derivatives:
    var lbase: Float64
    var c1: Float64
    var c2: Float64
    var c3: Float64
    var tht2: Float64
    var sqt2: Float64
    var sqtpi: Float64
    var pi: Float64
    var Data: LayoutData

    def __init__(inout self, data: LayoutData):
        self.pi = PI
        self.Data = data
        self.lbase = sqrt(pow(self.Data.H_h / self.Data.nph, 2.0) + pow(self.Data.H_w / self.Data.npw, 2.0))
        self.tht2 = self.Data.tht * self.Data.tht
        self.sqt2 = sqrt(2.0)
        self.sqtpi = sqrt(PI)

    def __init__(inout self):

    def int_eval(self, r: Float64, lf: Float64) -> Float64:
        var ls: Float64 = sqrt(r * r + self.tht2)
        var lfmls: Float64 = lf - ls
        if fabs(lfmls) < 0.1:
            return -r * self.Data.w_rec / (self.sqt2 * self.sqtpi * ls * ls * ls * self.Data.s_h) * exp(-self.Data.w_rec * self.Data.w_rec / (8.0 * ls * ls * self.Data.s_h * self.Data.s_h))
        else:
            var D: Float64 = 2.0 * self.sqt2 * lf * ls * self.Data.s_h
            var Dinv: Float64 = 1.0 / D
            var N1: Float64 = self.lbase * lfmls + lf * self.Data.w_rec
            var N2: Float64 = self.lbase * (ls - lf) + lf * self.Data.w_rec
            var T1: Float64 = N1 * Dinv
            var T2: Float64 = N2 * Dinv
            return -r * lf / (2.0 * self.lbase * lfmls * lfmls * ls) * (2.0 * self.sqt2 / self.sqtpi * lf * self.Data.s_h * (
                exp(-T2 * T2) - exp(-T1 * T1)) + self.Data.w_rec * (erf(T2) - erf(T1)))

    def d_eval(self, r: Float64, beta: Float64, lf: Float64) -> List[Float64]:
        """
        Calculate the derivative of intercept factor as a function of position in 
        the field and certain optical parameters.
        r : Radial position
        beta : Elevation angle of the receiver aperture
        lf : Focal length of the heliostat at position r
        """
        var cos_theta: Float64 = cos(self.Data.theta)
        var slant: Float64 = sqrt(self.Data.tht * self.Data.tht + r * r)
        var dint_dr: Float64 = self.int_eval(r, lf)
        var results: List[Float64]
        if self.Data.flat:
            results.append(self.Data.tht * (self.Data.tht * cos_theta * cos(self.Data.alpha - beta) + r * sin(self.Data.theta)) / (slant * slant * slant) + dint_dr)  # dr
            results.append(r * cos_theta * sin(self.Data.alpha - beta) / slant)  # dB
        else:
            results.append(self.Data.tht * (self.Data.tht * cos_theta + r * sin(self.Data.theta)) / (slant * slant * slant) + dint_dr)  # dr
            results.append(0.0)  # dB
        return results


class tree_node:
    var m0: tree_node?
    var m1: tree_node?
    var data: List[AnyPointer]
    var terminal: Bool

    def __init__(inout self):
        self.m0 = None
        self.m1 = None
        self.data = List[AnyPointer]()
        self.terminal = False

    def setup(inout self, child0: tree_node?):
        self.terminal = False
        self.m0 = child0
        self.m1 = self.m0

    def setup(inout self, child0: tree_node?, child1: tree_node?):
        self.terminal = False
        self.m0 = child0
        self.m1 = child1

    def setup(inout self, Data: List[AnyPointer]):
        self.terminal = True
        self.data = Data

    def is_terminal(self) -> Bool:
        return self.terminal

    def get_array(inout self) -> List[AnyPointer]:
        return self.data

    def m_proc(inout self, key: String, index: Int) -> tree_node?:
        var c: UInt8
        try:
            c = ord(key[index])
        except:
            return self
        if c == ord('t') or self.terminal:
            return self
        if c == ord('x') or c == ord('0'):
            return self.m0.m_proc(key, index + 1)
        if c == ord('1'):
            return self.m1.m_proc(key, index + 1)
        raise spexception("Invalid key index while parsing optical mesh.")

    def m_get_children(inout self) -> List[tree_node?]:
        var kids: List[tree_node?]
        if not self.terminal:
            if self.m0 is self.m1:
                kids.append(self.m0)
                var m0kids = self.m0.m_get_children()
                for i in range(len(m0kids)):
                    kids.append(m0kids[i])
            else:
                kids.append(self.m0)
                kids.append(self.m1)
                var m0kids = self.m0.m_get_children()
                var m1kids = self.m1.m_get_children()
                for i in range(len(m0kids)):
                    kids.append(m0kids[i])
                for i in range(len(m1kids)):
                    kids.append(m1kids[i])
        return kids

    def get_child_data(inout self) -> List[AnyPointer]:
        if self.terminal:
            return self.data
        else:
            if self.m0 is self.m1:
                return self.m0.get_child_data()
            else:
                var m0dat = self.m0.get_child_data()
                var m1dat = self.m1.get_child_data()
                var alldat: List[AnyPointer]
                for i in range(len(m0dat)):
                    alldat.append(m0dat[i])
                for i in range(len(m1dat)):
                    alldat.append(m1dat[i])
                return alldat


class opt_element(tree_node):
    var xr: List[Float64]
    var yr: List[Float64]

    def __init__(inout self):
        self.xr = List[Float64](2, 0.0)
        self.yr = List[Float64](2, 0.0)

    def __init__(inout self):

    def set_range(inout self, xrlo: Float64, xrhi: Float64, yrlo: Float64, yrhi: Float64):
        self.xr[0] = xrlo
        self.xr[1] = xrhi
        self.yr[0] = yrlo
        self.yr[1] = yrhi

    def set_range(inout self, xri: List[Float64], yri: List[Float64]):
        for i in range(2):
            self.xr[i] = xri[i]
            self.yr[i] = yri[i]

    def process(inout self, key: String, index: Int) -> opt_element?:
        return self.m_proc(key, index) as opt_element?

    def get_children(inout self) -> List[opt_element?]:
        var children: List[opt_element?]
        var m_children = self.m_get_children()
        for it in m_children:
            children.append(it as opt_element?)
        return children

    def get_yr(inout self) -> List[Float64]:
        return self.yr

    def get_xr(inout self) -> List[Float64]:
        return self.xr


class optical_hash_tree:
    var Data: LayoutData?
    var nodes: List[opt_element]
    var derivs: derivatives
    var head_node: opt_element
    var divs_updated: Bool
    var nr_req: Int
    var na_req: Int
    var min_rec_level_r: Int
    var max_rec_level_r: Int
    var min_rec_level_a_dr: Float64
    var max_rec_level_a_dr: Float64
    var log2inv: Float64
    var pi: Float64

    def __init__(inout self):
        self.pi = PI
        self.divs_updated = False
        self.log2inv = 1.0 / log(2.0)
        self.nr_req = 0
        self.na_req = 0
        self.min_rec_level_r = 0
        self.max_rec_level_r = 0
        self.min_rec_level_a_dr = 0.0
        self.max_rec_level_a_dr = 0.0
        self.Data = None
        self.nodes = List[opt_element]()
        self.derivs = derivatives()
        self.head_node = opt_element()
        self.divs_updated = False

    def create_mesh(inout self, data: LayoutData):
        """
        Create a mesh of the heliostat field according to the performance surface
        provided by the 'integrals' class.
        """
        self.Data = data
        var dextr: Float64 = (self.Data.extents_r[1] - self.Data.extents_r[0])
        self.max_rec_level_r = floor(log(dextr / self.Data.min_zsize_r) * self.log2inv) as Int
        self.min_rec_level_r = ceil(log(dextr / self.Data.max_zsize_r) * self.log2inv) as Int
        var dexta: Float64 = (self.Data.extents_az[1] - self.Data.extents_az[0])
        self.max_rec_level_a_dr = dexta / self.Data.min_zsize_a
        self.min_rec_level_a_dr = dexta / self.Data.max_zsize_a
        self.derivs = derivatives(self.Data)
        var nmaxdivr: Int = pow(2.0, self.max_rec_level_r) as Int  # maximum number of zones radially
        var maxreclevela: Int = floor(log(self.max_rec_level_a_dr * (self.Data.extents_r[1] + self.Data.extents_r[0]) * 0.5) * self.log2inv) as Int  # max azimuthal recursion
        var nmaxdiva: Int = pow(2.0, maxreclevela) as Int  # max azimuthal zones (estimate)
        var nmaxterm: Int = nmaxdivr * nmaxdiva  # total max number of zones
        var maxreclevel: Int = max(self.max_rec_level_r, maxreclevela)  # worst case max recursion level
        var nmaxnodes: Int = 0
        for i in range(maxreclevel):
            nmaxnodes += nmaxterm // pow(2.0, i) as Int  # Add each level in the node tree
        try:
            self.nodes.reserve(nmaxnodes * 2)  # include a 100% buffer
        except:
            var msg: String = "An error occurred while allocating memory for the optical mesh elements. This can occur when the field layout zone settings are configured incorrectly or when insufficient memory is available. Attempting %d nodes." % nmaxnodes
            raise spexception(msg)
        self.head_node.set_range(self.Data.extents_r[0], self.Data.extents_r[1], self.Data.extents_az[0], self.Data.extents_az[1])
        self.create_node(self.head_node, True, 0, 0)

    def create_node(inout self, node: opt_element, rad_direction: Bool, rec_level_r: Int, rec_level_a: Int):
        var xr0: Float64 = node.get_xr()[0]
        var xr1: Float64 = node.get_xr()[1]
        var yr0: Float64 = node.get_yr()[0]
        var yr1: Float64 = node.get_yr()[1]
        var C0: Float64 = (xr0 + xr1) * 0.5
        var C1: Float64 = (yr0 + yr1) * 0.5
        var Lf: Float64
        if self.Data.onslant:
            Lf = sqrt(C0 * C0 + self.Data.tht * self.Data.tht)
        else:
            Lf = self.Data.L_f
        var ddr: Float64
        var ddB: Float64
        var res = self.derivs.d_eval(C0, C1, Lf)
        ddr = res[0]
        ddB = res[1]
        var dr: Float64 = fabs(ddr * (xr1 - xr0))
        var dB: Float64 = fabs(ddB * (yr1 - yr0))
        var max_rec_level_a: Int = floor(self.log2inv * log(C0 * self.max_rec_level_a_dr)) as Int
        var min_rec_level_a: Int = ceil(self.log2inv * log(C0 * self.min_rec_level_a_dr)) as Int
        if rad_direction:
            var x_r_o: List[Float64] = List[Float64]([C0, xr1])
            var x_r_i: List[Float64] = List[Float64]([xr0, C0])
            var y_r: List[Float64] = List[Float64]([yr0, yr1])
            if (dr > self.Data.f_tol or rec_level_r < self.min_rec_level_r) and (rec_level_r < self.max_rec_level_r):
                self.nodes.append(opt_element())
                var m1: Optional[opt_element] = Optional(self.nodes[-1])
                m1.set_range(x_r_o, y_r)
                self.nodes.append(opt_element())
                var m0: Optional[opt_element] = Optional(self.nodes[-1])
                m0.set_range(x_r_i, y_r)
                node.setup(m0, m1)
                self.create_node(m0, not rad_direction, rec_level_r + 1, rec_level_a)
                self.create_node(m1, not rad_direction, rec_level_r + 1, rec_level_a)
                return
            elif (dB > self.Data.f_tol or rec_level_a < min_rec_level_a) and (rec_level_a < max_rec_level_a):
                self.nodes.append(opt_element())
                var m0: Optional[opt_element] = Optional(self.nodes[-1])
                m0.set_range(xr0, xr1, yr0, yr1)  # keep current range
                node.setup(m0)
                self.create_node(m0, not rad_direction, rec_level_r, rec_level_a)
                return
            else:
                var T: List[AnyPointer] = List[AnyPointer]()
                node.setup(T)
                return
        else:
            var x_r: List[Float64] = List[Float64]([xr0, xr1])
            var y_r_i: List[Float64] = List[Float64]([yr0, C1])
            var y_r_o: List[Float64] = List[Float64]([C1, yr1])
            if (dB > self.Data.f_tol or rec_level_a < min_rec_level_a) and (rec_level_a < max_rec_level_a):
                self.nodes.append(opt_element())
                var m1: Optional[opt_element] = Optional(self.nodes[-1])
                m1.set_range(x_r, y_r_o)
                self.nodes.append(opt_element())
                var m0: Optional[opt_element] = Optional(self.nodes[-1])
                m0.set_range(x_r, y_r_i)
                node.setup(m0, m1)
                self.create_node(m0, not rad_direction, rec_level_r, rec_level_a + 1)
                self.create_node(m1, not rad_direction, rec_level_r, rec_level_a + 1)
                return
            elif (dr > self.Data.f_tol or rec_level_r < self.min_rec_level_r) and (rec_level_r < self.max_rec_level_r):
                self.nodes.append(opt_element())
                var m0: Optional[opt_element] = Optional(self.nodes[-1])
                m0.set_range(xr0, xr1, yr0, yr1)  # keep current range
                node.setup(m0)
                self.create_node(m0, not rad_direction, rec_level_r, rec_level_a)
                return
            else:
                var T: List[AnyPointer] = List[AnyPointer]()
                node.setup(T)
                return
            return

    def update_divisions(inout self, res: Float64):
        var r: List[Float64] = self.Data.extents_r
        self.nr_req = ceil(log((r[1] - r[0]) / res) / log(2.0)) as Int
        self.na_req = ceil(log((PI * (r[1] - r[0])) / res) / log(2.0)) as Int
        self.divs_updated = True

    def pos_to_binary(inout self, x: Float64, y: Float64) -> String:
        return self.pos_to_binary(x, y, self.Data.t_res)

    def pos_to_binary(inout self, x: Float64, y: Float64, res: Float64) -> String:
        """
        Convert an x-y position into a binary tag
        """
        if not self.divs_updated:
            self.update_divisions(res)
        var tag: String
        var pr: Float64 = sqrt(x * x + y * y)
        var paz: Float64 = atan2(x, y)
        var rad_mode: Bool = True  # start with radius
        var az0: Float64 = self.Data.extents_az[0]
        var az1: Float64 = self.Data.extents_az[1]
        var r0: Float64 = self.Data.extents_r[0]
        var r1: Float64 = self.Data.extents_r[1]
        var nc: Int = max(self.nr_req, self.na_req) * 2
        for i in range(nc):
            if rad_mode:
                var cr: Float64 = (r0 + r1) * 0.5
                if pr > cr:
                    r0 = cr
                    tag += "1"
                else:
                    r1 = cr
                    tag += "0"
            else:
                var caz: Float64 = (az0 + az1) * 0.5
                if paz > caz:
                    az0 = caz
                    tag += "1"
                else:
                    az1 = caz
                    tag += "0"
            rad_mode = not rad_mode
        return tag

    def add_object(inout self, object: AnyPointer, locx: Float64, locy: Float64):
        self.add_object(object, locx, locy, self.Data.t_res)

    def add_object(inout self, object: AnyPointer, locx: Float64, locy: Float64, res: Float64):
        """
        Take an object in cartesian coordinates and add it to the appropriate
        element in the mesh
        """
        var tag: String = self.pos_to_binary(locx, locy, res)
        var element: opt_element? = self.head_node.process(tag, 0) as opt_element?
        element.get_array().append(object)

    def reset(inout self):
        self.Data = None
        self.head_node = opt_element()
        self.nodes.clear()
        self.divs_updated = False
        self.nr_req = -1
        self.na_req = -1

    def get_terminal_data(inout self) -> List[List[AnyPointer]]:
        var retdata: List[List[AnyPointer]]
        for it in self.nodes:
            if not it.is_terminal():
                continue
            retdata.append(it.get_array())
        return retdata

    def get_terminal_nodes(inout self) -> List[opt_element?]:
        var tnodes: List[opt_element?]
        for i in range(len(self.nodes)):
            if self.nodes[i].is_terminal():
                tnodes.append(Optional(self.nodes[i]))
        return tnodes
<<<END_FILE>>>