# BSD-3-Clause
# Copyright 2019 Alliance for Sustainable Energy, LLC
# Redistribution and use in source and binary forms, with or without modification, are permitted provided 
# that the following conditions are met :
# 1. Redistributions of source code must retain the above copyright notice, this list of conditions 
# and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions 
# and the following disclaimer in the documentation and/or other materials provided with the distribution.
# 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse 
# or promote products derived from this software without specific prior written permission.
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, 
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED.IN NO EVENT SHALL THE COPYRIGHT HOLDER, CONTRIBUTORS, UNITED STATES GOVERNMENT OR UNITED STATES 
# DEPARTMENT OF ENERGY, NOR ANY OF THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, 
# OR CONSEQUENTIAL DAMAGES(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT 
# OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

from math import *
from List import List
from Toolbox import Toolbox
from mod_base import mod_base
from definitions import sp_point, Vect, PointVect, var_receiver, D2R
from exceptions import spexception

alias PI = pi
alias FluxGrid = List[List[FluxPoint]]
alias FluxSurfaces = List[FluxSurface]

struct FluxPoint:
    var location: sp_point
    var normal: Vect
    var maxflux: Float64
    var flux: Float64
    var area_factor: Float64
    var over_flux: Bool

    def __init__(inout self):
        self.over_flux = False
        self.flux = 0.0

    def setup(inout self, xloc: Float64, yloc: Float64, zloc: Float64, norm: Vect, flux_max: Float64, Area_factor: Float64 = 1.0):
        self.location.x = xloc
        self.location.y = yloc
        self.location.z = zloc
        self.normal.i = norm.i
        self.normal.j = norm.j
        self.normal.k = norm.k
        self.maxflux = flux_max
        self.over_flux = False
        self.area_factor = Area_factor

    def setup(inout self, loc: sp_point, norm: Vect, flux_max: Float64, Area_factor: Float64 = 1.0):
        self.location.x = loc.x
        self.location.y = loc.y
        self.location.z = loc.z
        self.normal.i = norm.i
        self.normal.j = norm.j
        self.normal.k = norm.k
        self.maxflux = flux_max
        self.over_flux = False
        self.area_factor = Area_factor

class FluxSurface(mod_base):
    var _id: Int
    var _type: Int
    var _nflux_x: Int
    var _nflux_y: Int
    var _width: Float64
    var _height: Float64
    var _radius: Float64
    var _area: Float64
    var _span_ccw: Float64
    var _span_cw: Float64
    var _max_flux: Float64
    var _max_observed_flux: Float64
    var _normal: Vect
    var _offset: sp_point
    var _flux_grid: FluxGrid
    var _rec_parent: Receiver

    def getParent(self) -> Receiver:
        return self._rec_parent

    def getId(self) -> Int:
        return self._id

    def getFluxMap(self) -> FluxGrid:
        return self._flux_grid

    def getFluxNX(self) -> Int:
        return self._nflux_x

    def getFluxNY(self) -> Int:
        return self._nflux_y

    def getSurfaceOffset(self) -> sp_point:
        return self._offset

    def getSurfaceWidth(self) -> Float64:
        return self._width

    def getSurfaceHeight(self) -> Float64:
        return self._height

    def getSurfaceRadius(self) -> Float64:
        return self._radius

    def getSurfaceArea(self) -> Float64:
        return self._area

    def getMaxObservedFlux(self) -> Float64:
        return self._max_observed_flux

    def setParent(inout self, recptr: Receiver):
        self._rec_parent = recptr

    def setFluxPrecision(inout self, nx: Int, ny: Int):
        self._nflux_x = nx
        self._nflux_y = ny

    def setMaxFlux(inout self, maxflux: Float64):
        self._max_flux = maxflux

    def setNormalVector(inout self, vect: Vect):
        self._normal = vect

    def setSurfaceOffset(inout self, loc: sp_point):
        self._offset = loc

    def setSurfaceSpanAngle(inout self, span_min: Float64, span_max: Float64):
        self._span_ccw = span_min
        self._span_cw = span_max

    def setSurfaceGeometry(inout self, height: Float64, width: Float64, radius: Float64 = 0.0):
        self._width = width
        self._height = height
        self._radius = radius  # if radius is 0, assume flat surface.

    def setMaxObservedFlux(inout self, fmax: Float64):
        self._max_observed_flux = fmax

    def ClearFluxGrid(inout self):
        for i in range(len(self._flux_grid)):
            for j in range(len(self._flux_grid[i])):
                self._flux_grid[i][j].flux = 0.0

    def DefineFluxPoints(inout self, V: var_receiver, rec_geom: Int, nx: Int = -1, ny: Int = -1):
        # Given the receiver geometry in "_parent", create a grid of flux hit test points.
        # Flux points are in the global coordinate system but do not include receiver offset or tower height.
        if nx > 0:
            self._nflux_x = nx
        if ny > 0:
            self._nflux_y = ny
        if rec_geom == Receiver.REC_GEOM_TYPE.CYLINDRICAL_CLOSED:
            # 0 | Continuous closed cylinder - external
            self._area = self._height * self._radius * PI * 2.0
            self._flux_grid = List[List[FluxPoint]](self._nflux_x)  # number of rows
            daz = (self._span_cw - self._span_ccw) / Float64(self._nflux_x)
            faz: Float64
            floc: sp_point
            fnorm: Vect
            dz = self._height / Float64(self._nflux_y)  # height of each flux node
            for i in range(self._nflux_x):
                self._flux_grid[i] = List[FluxPoint](self._nflux_y)  # number of columns
                faz = self._span_cw - daz * (0.5 + Float64(i))  # The azimuth angle of the point
                fnorm.i = sin(faz)
                fnorm.j = cos(faz)
                fnorm.k = 0.0
                floc.x = fnorm.i * self._radius
                floc.y = fnorm.j * self._radius
                for j in range(self._nflux_y):
                    floc.z = -self._height / 2.0 + dz * (0.5 + Float64(j))
                    self._flux_grid[i][j].setup(floc, fnorm, self._max_flux)
        elif rec_geom == Receiver.REC_GEOM_TYPE.CYLINDRICAL_OPEN or rec_geom == Receiver.REC_GEOM_TYPE.CYLINDRICAL_CAV:
            # The flux map for this geometry allows an angling in the zenith direction of the surface.
            # The coordinates of the flux map are with respect to the xyz location of the receiver centroid.
            # These coordinates account for zenith rotation of the receiver. 
            # Flux points are stored beginning lower edge, clockwise extent. Final entry upper edge counterclockwise extent
            intmult = -1.0 if rec_geom == Receiver.REC_GEOM_TYPE.CYLINDRICAL_CAV else 1.0  # -1 multiplier for values that are inverted on the internal face of a cylinder
            spansize = (self._span_cw - self._span_ccw) * intmult
            self._area = self._height * self._radius * spansize
            self._flux_grid = List[List[FluxPoint]](self._nflux_x)  # Number of rows
            daz = spansize / Float64(self._nflux_x)
            rec_az = atan2(self._normal.i, self._normal.j)  # The azimuth angle of the receiver
            rec_zen = acos(self._normal.k)  # The zenith angle of the receiver at rec_az
            rec_dh = self._height / Float64(self._nflux_y)
            faz: Float64
            fzen: Float64
            floc: sp_point
            fnorm: Vect
            for i in range(self._nflux_x):
                self._flux_grid[i] = List[FluxPoint](self._nflux_y)  # number of columns
                faz = self._span_cw - daz * (0.5 + Float64(i))
                fzen = rec_zen * cos(rec_az - faz)  # Local receiver zenith angle
                for j in range(self._nflux_y):
                    floc.x = self._radius * sin(faz)
                    floc.y = self._radius * cos(faz)
                    floc.z = -self._height / 2.0 + rec_dh * (0.5 + Float64(j))
                    fnorm.i = sin(faz) * cos(fzen) * intmult
                    fnorm.j = cos(faz) * cos(fzen) * intmult
                    fnorm.k = sin(fzen)
                    Toolbox.rotation(rec_zen, 0, floc)  # Rotate the actual point
                    Toolbox.rotation(rec_zen, 0, fnorm)  # rotate the normal vector
                    Toolbox.rotation(rec_az, 2, floc)    # point
                    Toolbox.rotation(rec_az, 2, fnorm)   # normal vector
                    self._flux_grid[i][j].setup(floc, fnorm, self._max_flux)
        elif rec_geom == Receiver.REC_GEOM_TYPE.PLANE_RECT:
            # 3 | Planar rectangle
            # The receiver is a rectangle divided into _nflux_x nodes in the horizontal direction and
            # _nflux_y nodes in the vertical direction. Each node is of area A_rec/(_nflux_x * _nflux_y).
            self._area = self._height * self._width
            self._flux_grid = List[List[FluxPoint]](self._nflux_x)  # Number of rows
            rec_az = atan2(self._normal.i, self._normal.j)  # The azimuth angle of the receiver
            rec_zen = acos(self._normal.k)  # The zenith angle of the receiver at rec_az
            rec_dh = self._height / Float64(self._nflux_y)
            rec_dw = self._width / Float64(self._nflux_x)
            floc: sp_point
            for i in range(self._nflux_x):
                self._flux_grid[i] = List[FluxPoint](self._nflux_y)  # number of columns
                for j in range(self._nflux_y):
                    floc.x = (-self._width + rec_dw) / 2.0 + Float64(i) * rec_dw
                    floc.y = (-self._height + rec_dh) / 2.0 + Float64(j) * rec_dh
                    floc.z = 0.0
                    Toolbox.rotation(-rec_zen, 0, floc)
                    Toolbox.rotation(PI + rec_az, 2, floc)
                    self._flux_grid[i][j].setup(floc, self._normal, self._max_flux)
        elif rec_geom == Receiver.REC_GEOM_TYPE.PLANE_ELLIPSE:
            # 4 | Planar ellipse
            # The receiver is a rectangle divided into _nflux_x nodes in the horizontal direction and
            # _nflux_y nodes in the vertical direction. Each node is of area A_rec/(_nflux_x * _nflux_y).
            self._area = PI * self._width * self._height / 4.0
            self._flux_grid = List[List[FluxPoint]](self._nflux_x)  # Number of rows
            rec_az = atan2(self._normal.i, self._normal.j)  # The azimuth angle of the receiver
            rec_zen = acos(self._normal.k)  # The zenith angle of the receiver at rec_az
            rec_dh = self._height / Float64(self._nflux_y)
            rec_dw = self._width / Float64(self._nflux_x)
            floc: sp_point
            for i in range(self._nflux_x):
                self._flux_grid[i] = List[FluxPoint](self._nflux_y)  # number of columns
                for j in range(self._nflux_y):
                    floc.x = (-self._width + rec_dw) / 2.0 + Float64(i) * rec_dw
                    floc.y = 0.0
                    floc.z = (-self._height + rec_dh) / 2.0 + Float64(j) * rec_dh
                    rect: List[Float64] = [floc.x, floc.z, rec_dw, rec_dh]
                    ellipse: List[Float64] = [self._width, self._height]
                    afactor = fmin(fmax(Toolbox.intersect_ellipse_rect(rect, ellipse) / (rec_dw * rec_dh), 0.0), 1.0)
                    Toolbox.rotation(-rec_zen + PI / 2.0, 0, floc)  # unlike plane rect, the points start in X-Z plane
                    Toolbox.rotation(PI + rec_az, 2, floc)
                    self._flux_grid[i][j].setup(floc, self._normal, self._max_flux, afactor)
        elif rec_geom == Receiver.REC_GEOM_TYPE.POLYGON_CLOSED:
            self._area = self._height * self._radius * PI * 2.0
            self._flux_grid = List[List[FluxPoint]](self._nflux_x)  # number of rows
            span = (self._span_cw - self._span_ccw)
            daz = span / Float64(self._nflux_x)  # span will always be 2 PI for this
            npanels = V.n_panels.val
            panel_az_span = span / Float64(npanels)
            panel_normals: List[Vect] = List[Vect](npanels)
            panel_radii: List[Float64] = List[Float64](npanels)
            panel_azimuths: List[Float64] = List[Float64](npanels)
            rec_az = atan2(self._normal.i, self._normal.j)  # The azimuth angle of the receiver
            rec_zen = acos(self._normal.k)  # The zenith angle of the receiver at rec_az
            for i in range(npanels):
                paz = self._span_cw - (Float64(i) + 0.5) * panel_az_span
                sinpaz = sin(paz)
                cospaz = cos(paz)
                panel_normals[i] = Vect(sinpaz, cospaz, 0.0)
                panel_radii[i] = self._radius * cos(panel_az_span / 2.0)
                panel_azimuths[i] = paz + rec_az
                Toolbox.rotation(rec_zen + PI / 2.0, 0, panel_normals[i])
                Toolbox.rotation(rec_az, 2, panel_normals[i])
            faz: Float64
            fnorm: Vect
            for i in range(self._nflux_x):
                self._flux_grid[i] = List[FluxPoint](self._nflux_y)  # number of columns
                faz = self._span_cw - daz * (0.5 + Float64(i)) + rec_az  # The azimuth angle of the point
                ipanl = Int(floor(faz / panel_az_span))
                fnorm = panel_normals[ipanl]
                h = panel_radii[ipanl] / cos(panel_azimuths[ipanl] - faz)  # hypotenuse 
                floc: sp_point
                floc.x = h * sin(faz - rec_az)
                floc.y = h * cos(faz - rec_az)
                dz = self._height / Float64(self._nflux_y)  # height of each flux node
                for j in range(self._nflux_y):
                    floc.z = -self._height / 2.0 + dz * (0.5 + Float64(j))
                    Toolbox.rotation(rec_zen + PI / 2.0, 0, floc)
                    Toolbox.rotation(rec_az, 2, floc)
                    self._flux_grid[i][j].setup(floc, fnorm, self._max_flux)
        elif rec_geom == Receiver.REC_GEOM_TYPE.POLYGON_OPEN or rec_geom == Receiver.REC_GEOM_TYPE.POLYGON_CAV:

        else:

    def getTotalFlux(self) -> Float64:
        flux_tot = 0.0
        for i in range(self._nflux_x):
            for j in range(self._nflux_y):
                flux_tot += self._flux_grid[i][j].flux
        return flux_tot

    def Normalize(inout self):
        # Express each node on the flux map as a relative contribution toward the total 
        # absorbed flux, which is equal to 1.0. 
        # e.g:
        # sum_i=0->nfx( sum_j=0->nfy( flux[i][j] )) = 1.0
        flux_tot = self.getTotalFlux()
        for i in range(self._nflux_x):
            for j in range(self._nflux_y):
                self._flux_grid[i][j].flux *= 1.0 / flux_tot

class Receiver(mod_base):
    var _absorber_area: Float64
    var _therm_loss: Float64
    var _piping_loss: Float64
    var _is_enabled: Bool
    var _thermal_eff: Float64
    var _normal: PointVect
    var _rec_geom: Int
    var _surfaces: FluxSurfaces
    var _var_receiver: var_receiver

    struct REC_GEOM_TYPE:
        var CYLINDRICAL_CLOSED: Int = 0
        var CYLINDRICAL_OPEN: Int = 1
        var CYLINDRICAL_CAV: Int = 2
        var PLANE_RECT: Int = 3
        var PLANE_ELLIPSE: Int = 4
        var POLYGON_CLOSED: Int = 5
        var POLYGON_OPEN: Int = 6
        var POLYGON_CAV: Int = 7

    def Create(inout self, V: var_receiver, tht: Float64):
        self._var_receiver = V
        self._is_enabled = V.is_enabled.val
        self._normal = PointVect(0.0, 0.0, 0.0, 0.0, 1.0, 0.0)  # Unit vector of the normal to the reciever
        self.DefineReceiverGeometry()
        self.updateCalculatedParameters(V, tht)

    def updateCalculatedParameters(inout self, V: var_receiver, tht: Float64):
        if self._var_receiver.rec_type.mapval() == var_receiver.REC_TYPE.EXTERNAL_CYLINDRICAL:
            if not self._var_receiver.is_open_geom.val:
                self._rec_geom = Receiver.REC_GEOM_TYPE.POLYGON_CLOSED if self._var_receiver.is_polygon.val else Receiver.REC_GEOM_TYPE.CYLINDRICAL_CLOSED
                # 0 | Continuous closed cylinder - external
            else:
                self._rec_geom = Receiver.REC_GEOM_TYPE.POLYGON_OPEN if self._var_receiver.is_polygon.val else Receiver.REC_GEOM_TYPE.CYLINDRICAL_OPEN
                # 1 | Continuous open cylinder - external
        elif self._var_receiver.rec_type.mapval() == var_receiver.REC_TYPE.FLAT_PLATE:
            # Flat plate
            if self._var_receiver.aperture_type.mapval() == var_receiver.APERTURE_TYPE.RECTANGULAR:
                self._rec_geom = Receiver.REC_GEOM_TYPE.PLANE_RECT  # 3 | Planar rectangle
            else:
                self._rec_geom = Receiver.REC_GEOM_TYPE.PLANE_ELLIPSE  # 4 | Planar ellipse
        else:

        self.CalculateAbsorberArea()
        height = V.rec_height.val
        if V.rec_type.mapval() == var_receiver.REC_TYPE.EXTERNAL_CYLINDRICAL:
            aspect = height / V.rec_diameter.val
        elif V.rec_type.mapval() == var_receiver.REC_TYPE.FLAT_PLATE:
            aspect = height / V.rec_width.val
        else:
            raise spexception("Invalid receiver type in UpdateCalculatedMapValues()")
        V.rec_aspect.Setval(aspect)
        V.absorber_area.Setval(self._absorber_area)  # calculated by CalculateAbsorberArea
        zoff = V.rec_offset_z.val
        V.optical_height.Setval(tht + zoff)
        tp = 0.0
        for i in range(int(V.therm_loss_load.val.ncells())):
            tp += V.therm_loss_load.val.at(i)
        therm_loss_base = V.therm_loss_base.val
        V.therm_loss.Setval(therm_loss_base * self._absorber_area / 1.0e3 * tp)
        V.piping_loss.Setval((V.piping_loss_coef.val * tht + V.piping_loss_const.val) / 1.0e3)

    @staticmethod
    def getReceiverWidth(V: var_receiver) -> Float64:
        if V.rec_type.mapval() == var_receiver.REC_TYPE.EXTERNAL_CYLINDRICAL:
            return V.rec_diameter.val
        else:
            return V.rec_width.val

    def getReceiverThermalLoss(self) -> Float64:
        return self._therm_loss

    def getReceiverPipingLoss(self) -> Float64:
        return self._piping_loss

    def getThermalEfficiency(self) -> Float64:
        return self._thermal_eff

    def getAbsorberArea(self) -> Float64:
        return self._absorber_area

    def getGeometryType(self) -> Int:
        return self._rec_geom

    def getFluxSurfaces(self) -> FluxSurfaces:
        return self._surfaces

    def getVarMap(self) -> var_receiver:
        return self._var_receiver

    def isReceiverEnabled(self) -> Bool:
        return self._is_enabled

    def isReceiverEnabled(inout self, enable: Bool):
        self._is_enabled = enable

    def CalculateNormalVector(self, NV: PointVect):
        Vn: sp_point
        Vn.Set(0.0, 0.0, 0.0)
        self.CalculateNormalVector(Vn, NV)

    def CalculateNormalVector(self, Hloc: sp_point, NV: PointVect):
        # This subroutine should be used to calculate the normal vector to the receiver for a given heliostat location.
        # Ultimately, the optical calculations should not use this method to calculate the normal vector. Instead, use
        # the normal vector that is assigned to the receiver surface during setup. 
        # In the case of continuous cylindrical surfaces, this method can be called during optical calculations.
        # Given a heliostat at point Hloc{x,y,z}, return a normal vector to the receiver absorber surface.
        rec_elevation = self._var_receiver.rec_elevation.val * D2R
        rec_az = self._var_receiver.rec_azimuth.val * D2R
        if self._rec_geom == Receiver.REC_GEOM_TYPE.CYLINDRICAL_CLOSED or self._rec_geom == Receiver.REC_GEOM_TYPE.POLYGON_CLOSED:
            vaz = atan2(Hloc.x, Hloc.y)
            NV.z = self._var_receiver.optical_height.Val()
            NV.x = self._var_receiver.rec_diameter.val / 2.0 * sin(vaz) + self._var_receiver.rec_offset_x.val  # [m] x-location of surface at angle vaz, given radius _var_receiver->rec_diameter.val/2
            NV.y = self._var_receiver.rec_diameter.val / 2.0 * cos(vaz) + self._var_receiver.rec_offset_y.val  # [m] y-location "" "" ""
            NV.i = sin(vaz) * cos(rec_elevation)
            NV.j = cos(vaz) * cos(rec_elevation)
            NV.k = sin(rec_elevation)
        elif (self._rec_geom == Receiver.REC_GEOM_TYPE.CYLINDRICAL_OPEN or
              self._rec_geom == Receiver.REC_GEOM_TYPE.CYLINDRICAL_CAV or
              self._rec_geom == Receiver.REC_GEOM_TYPE.PLANE_RECT or
              self._rec_geom == Receiver.REC_GEOM_TYPE.PLANE_ELLIPSE):
            NV.x = self._var_receiver.rec_offset_x.val
            NV.y = self._var_receiver.rec_offset_y.val
            NV.z = self._var_receiver.optical_height.Val()
            NV.i = sin(rec_az) * cos(rec_elevation)
            NV.j = cos(rec_az) * cos(rec_elevation)
            NV.k = sin(rec_elevation)
        else:
            raise spexception("Unsupported receiver type")
        return

    def DefineReceiverGeometry(inout self, nflux_x: Int = 1, nflux_y: Int = 1):
        # The process of defining receiver geometry for each receiver should be:
        # 1) Indicate which specific geometry type should be used with "_rec_geom"
        # 2) Calculate and set the number of surfaces used for the recever. Resize "_surfaces".
        # 3) Calculate and set the normal vector for each surface (if not curved surfaces) with setNormalVector(Vect).
        # 4) Setup the geometry etc.. including setSurfaceGeometry, setSurfaceOffset, setSurfaceSpanAngle, if applicable.
        # 5) Define the precision of the flux map.
        # 6) Define the maximum flux for each panel.
        # 7) Call the method to set up the flux hit test grid.
        # Geometries are:
        # 0 | Continuous closed cylinder - external
        # 1 | Continuous open cylinder - external
        # 2 | Continuous open cylinder - internal cavity
        # 3 | Planar rectangle
        # 4 | Planar ellipse
        # 5 | Discrete closed N-polygon - external
        # 6 | Discrete open N-polygon - external
        # 7 | Discrete open N-polygon - internal cavity
        rec_type = self._var_receiver.rec_type.mapval()
        if rec_type == var_receiver.REC_TYPE.EXTERNAL_CYLINDRICAL:
            # continuous external cylinders. Setup shares some common features..
            self._surfaces = List[FluxSurface](1)
            S = self._surfaces[0]
            S.setParent(self)
            loc: sp_point
            loc.Set(self._var_receiver.rec_offset_x.val, self._var_receiver.rec_offset_y.val, self._var_receiver.rec_offset_z.val)
            S.setSurfaceGeometry(self._var_receiver.rec_height.val, 0.0, self._var_receiver.rec_diameter.val / 2.0)
            S.setSurfaceOffset(loc)
            nv: Vect
            rec_az = self._var_receiver.rec_azimuth.val * D2R
            rec_el = self._var_receiver.rec_elevation.val * D2R
            nv.i = sin(rec_az) * cos(rec_el)
            nv.j = cos(rec_az) * cos(rec_el)
            nv.k = sin(rec_el)
            S.setNormalVector(nv)
            if not self._var_receiver.is_open_geom.val:
                S.setSurfaceSpanAngle(-PI, PI)  # Full surround
            else:
                S.setSurfaceSpanAngle(self._var_receiver.span_min.val * D2R, self._var_receiver.span_max.val * D2R)
            S.setFluxPrecision(nflux_x, nflux_y)
            S.setMaxFlux(self._var_receiver.peak_flux.val)
            S.DefineFluxPoints(self._var_receiver, self._rec_geom)
        elif rec_type == var_receiver.REC_TYPE.FLAT_PLATE:
            # Flat plate
            self._surfaces = List[FluxSurface](1)
            S = self._surfaces[0]
            loc: sp_point
            loc.Set(self._var_receiver.rec_offset_x.val, self._var_receiver.rec_offset_y.val, self._var_receiver.rec_offset_z.val)
            S.setSurfaceGeometry(self._var_receiver.rec_height.val, self._var_receiver.rec_width.val, 0.0)
            S.setSurfaceOffset(loc)
            nv: Vect
            rec_az = self._var_receiver.rec_azimuth.val * D2R
            rec_elevation = self._var_receiver.rec_elevation.val * D2R
            nv.i = sin(rec_az) * cos(rec_elevation)
            nv.j = cos(rec_az) * cos(rec_elevation)
            nv.k = sin(rec_elevation)
            S.setNormalVector(nv)
            S.setSurfaceSpanAngle(-PI / 2.0, PI / 2.0)
            S.setFluxPrecision(nflux_x, nflux_y)
            S.setMaxFlux(self._var_receiver.peak_flux.val)
            S.DefineFluxPoints(self._var_receiver, self._rec_geom)

    def CalculateAbsorberArea(inout self):
        # Calculate the receiver absorber surface area based on the geometry type. This doesn't consider
        # the area of individual tubes or elements, only the area of the major geometrical surfaces.
        # The local variable _absorber_area is set, which can be accessed via
        # getReceiverAbsorberArea()
        recgeom = self._rec_geom
        if recgeom == Receiver.REC_GEOM_TYPE.CYLINDRICAL_CLOSED:
            self._absorber_area = (self._var_receiver.rec_height.val * self._var_receiver.rec_diameter.val * PI)
        elif recgeom == Receiver.REC_GEOM_TYPE.CYLINDRICAL_OPEN or recgeom == Receiver.REC_GEOM_TYPE.CYLINDRICAL_CAV:
            self._absorber_area = (self._var_receiver.rec_height.val * self._var_receiver.rec_diameter.val * fabs(self._var_receiver.span_max.val * D2R - self._var_receiver.span_min.val * D2R) / 2.0)
        elif recgeom == Receiver.REC_GEOM_TYPE.PLANE_RECT:
            self._absorber_area = (self._var_receiver.rec_height.val * self._var_receiver.rec_width.val)
        elif recgeom == Receiver.REC_GEOM_TYPE.PLANE_ELLIPSE:
            self._absorber_area = (PI * self._var_receiver.rec_height.val * self._var_receiver.rec_width.val / 4.0)
        elif recgeom == Receiver.REC_GEOM_TYPE.POLYGON_CLOSED:
            self._absorber_area = (self._var_receiver.rec_height.val * Float64(self._var_receiver.n_panels.val) * self._var_receiver.rec_diameter.val / 2.0 * tan(2.0 * PI / Float64(self._var_receiver.n_panels.val)))
        elif recgeom == Receiver.REC_GEOM_TYPE.POLYGON_OPEN or recgeom == Receiver.REC_GEOM_TYPE.POLYGON_CAV:
            self._absorber_area = (self._var_receiver.rec_height.val * Float64(self._var_receiver.n_panels.val) * self._var_receiver.rec_diameter.val / 2.0 * tan(fabs(self._var_receiver.span_max.val * D2R - self._var_receiver.span_min.val * D2R) / Float64(self._var_receiver.n_panels.val - 1)))
        else:

    def CalculateThermalLoss(inout self, load: Float64, v_wind: Float64):
        # Calculate the thermal loss from the receiver. Update the local values of thermal and piping loss.
        # _therm_loss [MWt]   Local value updated
        # _piping_loss [MWt]   Local value updated
        # Load is a normalized thermal load for the receiver. 
        # V_wind is m/s.
        fload = 0.0
        fwind = 0.0
        for i in range(int(self._var_receiver.therm_loss_load.val.ncells())):
            fload += self._var_receiver.therm_loss_load.val.at(i) * pow(load, Float64(i))
        for i in range(int(self._var_receiver.therm_loss_wind.val.ncells())):
            fwind += self._var_receiver.therm_loss_wind.val.at(i) * pow(v_wind, Float64(i))
        self._therm_loss = self._var_receiver.therm_loss_base.val * fload * fwind * self._absorber_area * 1.0e-3  # _therm_loss_base [kWt/m2]
        self._piping_loss = (self._var_receiver.piping_loss_coef.val * self._var_receiver.optical_height.Val() + self._var_receiver.piping_loss_const.val) * 1.0e-3

    def CalculateThermalEfficiency(inout self, dni: Float64, dni_des: Float64, v_wind: Float64, q_des: Float64):
        # Calculate thermal efficiency and update local values.
        # Inputs:
        #     DNI         W/m2    DNI at current time
        #     dni_des     W/m2    DNI at system design point
        #     v_wind      m/s     Wind velocity at current time
        #     q_des       MWt     Design-point receiver output power
        # Sets:
        #     _thermal_eff
        #     _therm_loss     (via CalculateThermalLoss)
        #     _piping_loss    (via CalculateThermalLoss)
        load = dni / dni_des
        self.CalculateThermalLoss(load, v_wind)
        self._thermal_eff = 1.0 - self._therm_loss / (self._therm_loss + q_des)

    def CalculateApparentDiameter(self, Hloc: sp_point) -> Float64:
        # [m] Return the apparent receiver diameter given the polygonal structure
        # Take the specified heliostat location, the number of receiver panels, and the orientation
        # of the primary receiver panel, and calculate the apparent width of the reciever.
        # This convention assumes that the receiver diameter CIRCUMSCRIBES all panels. That is, 
        # the maximum receiver apparent width is the specified receiver diameter.
        if self._rec_geom == Receiver.REC_GEOM_TYPE.CYLINDRICAL_CLOSED:
            return self._var_receiver.rec_diameter.val
        elif self._rec_geom == Receiver.REC_GEOM_TYPE.POLYGON_CLOSED:
            alpha = fabs(atan2(Hloc.x, Hloc.y) - self._var_receiver.rec_azimuth.val * D2R)
            theta_hat = fmod(alpha, 2.0 * PI / Float64(self._var_receiver.n_panels.val))
            return cos(theta_hat) * self._var_receiver.rec_diameter.val
        else:
            raise spexception("Attempting to calculate an apparent diameter for an unsupported receiver geometry.")