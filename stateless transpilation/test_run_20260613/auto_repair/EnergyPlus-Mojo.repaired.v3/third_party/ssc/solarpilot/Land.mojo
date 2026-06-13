"""
BSD-3-Clause
Copyright 2019 Alliance for Sustainable Energy, LLC
Redistribution and use in source and binary forms, with or without modification, are permitted provided 
that the following conditions are met :
1. Redistributions of source code must retain the above copyright notice, this list of conditions 
and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions 
and the following disclaimer in the documentation and/or other materials provided with the distribution.
3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse 
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

from math import sqrt, pow, fabs
from mod_base import mod_base
from definitions import var_map, var_land, sp_point, spexception
from Toolbox import Toolbox

struct Land:
    
    var _var_land: Pointer[var_land]
    var _bound_area: Float64

    def Create(inout self, inout V: var_map):
        self._var_land = Pointer[var_land].address_of(V.land)
        self._bound_area = 0.0
        self.updateCalculatedParameters(V)

    def updateCalculatedParameters(inout self, inout V: var_map):
        V.land.bound_area.Setval(self._bound_area)  #land bound area. Either we have it or we don't. Something will have to have called calcLandArea for this to be set.
        V.land.land_area.Setval(self._bound_area * V.land.land_mult.val / 4046.86 + V.land.land_const.val)
        var exts: List[Float64] = List[Float64](2)
        Land.getRadialExtents(V, exts, V.sf.tht.val)
        V.land.radmin_m.Setval(exts[0])
        V.land.radmax_m.Setval(exts[1])

    def getLandBoundArea(self) -> Float64:
        return self._bound_area

    @staticmethod
    def InBounds(inout V: var_land, inout P: sp_point, tht: Float64 = 1.0) -> Bool:
        var Po: sp_point = P
        var test: Bool = True
        var prad: Float64 = sqrt(pow(Po.x, 2) + pow(Po.y, 2))  #radial position of the point relative to the tower
        if V.is_bounds_scaled.val:  #Does the point lie within the limits scaling with tower height?
            test = (prad >= (tht * V.min_scaled_rad.val) and prad <= (tht * V.max_scaled_rad.val))
            if not test:
                return False
        if V.is_bounds_fixed.val:  #Does the point also lie within the fixed limits?
            test = test and (prad >= V.min_fixed_rad.val and prad <= V.max_fixed_rad.val)
            if not test:
                return False
        if V.is_bounds_array.val:
            if not V.is_exclusions_relative.val:  #if the exclusions are relative, wait to shift the point until after exclusion tests
                Po.x += V.tower_offset_x.val
                Po.y += V.tower_offset_y.val
            for i in range(len(V.exclusions.val)):
                if Toolbox.pointInPolygon(V.exclusions.val[i], Po):
                    return False  #if the point is in any exclusion, stop
            if V.is_exclusions_relative.val:  #if the point hasn't been shifted yet, do so now
                Po.x += V.tower_offset_x.val
                Po.y += V.tower_offset_y.val
            var intest: Bool = len(V.inclusions.val) == 0  #If there aren't any inclusions, all points are included. Otherwise initialize as false
            if intest and (not (V.is_bounds_scaled.val or V.is_bounds_fixed.val)):
                raise spexception("The land area in which heliostats may be placed is undefined. "
                                  "Please specify the layout bounds where heliostats are allowed.")
            for i in range(len(V.inclusions.val)):
                if Toolbox.pointInPolygon(V.inclusions.val[i], Po):
                    intest = True
                    break
            test = test and intest
        return test

    @staticmethod
    def getExtents(inout V: var_map, rval: List[Float64]):
        """
        **CALL FOR GUI**
        Take the rval[2] array (output) and the variable map structure from the interface and calculate {radmin, radmax}.
        This returns the min and max radial distance of the heliostat field from the tower location.
        The land bounds can be specified using up to three constraints: 1 - scale with tower height, 
        2 - fixed distances, 3 - user-specified polygon.
        This method considers all methods used and enforces the bounds based on satisfaction of all of
        the active criteria.
        This array takes an optional argument "tht" which multiplies by the scaled radii if appropriate.
        By default tht = 1.0
        The method returns an array size=2: {double min, double max}
        """
        var radmin: Float64 = 0.0
        var radmax: Float64 = 0.0
        var tht: Float64 = V.sf.tht.val
        var is_bounds_scaled: Bool = V.land.is_bounds_scaled.val
        var is_bounds_fixed: Bool = V.land.is_bounds_fixed.val
        var is_bounds_array: Bool = V.land.is_bounds_array.val
        if is_bounds_scaled:
            var min_scaled_rad: Float64 = V.land.min_scaled_rad.val
            var max_scaled_rad: Float64 = V.land.max_scaled_rad.val
            radmin = min_scaled_rad * tht
            radmax = max_scaled_rad * tht
        if is_bounds_fixed:
            var min_fixed_rad: Float64 = V.land.min_fixed_rad.val
            var max_fixed_rad: Float64 = V.land.max_fixed_rad.val
            if min_fixed_rad > radmin or radmin == 0:
                radmin = min_fixed_rad  #Only change if the fix min radius is larger than the previous bound
            if max_fixed_rad < radmax or radmax == 0:
                radmax = max_fixed_rad  #Only change if the fix max radius is smaller than the previous bound
        if is_bounds_array:
            var rad: Float64 = 0.0
            var trmax: Float64 = -1.0
            for i in range(len(V.land.inclusions.val)):
                for j in range(len(V.land.inclusions.val[i])):
                    rad = sqrt(
                        pow(V.land.inclusions.val[i][j].x - V.land.tower_offset_x.val, 2) +
                        pow(V.land.inclusions.val[i][j].y - V.land.tower_offset_y.val, 2)
                    )
                    if fabs(rad) > trmax:
                        trmax = rad
            if len(V.land.inclusions.val) > 0:
                if trmax < 0.0:
                    trmax = tht * 7.5  #use the default if nothing is set
                if trmax < radmax or radmax == 0:
                    radmax = trmax
            else:
                if not (is_bounds_scaled or is_bounds_fixed):
                    raise spexception("Insufficient information provided to specify land bounds. At least 1 'inclusion' region must be provided if not specifying fixed or scaled bounds.")
            var trmin: Float64 = 9.0e9
            var T: sp_point
            var pt1: sp_point
            var N: sp_point
            T.Set(V.land.tower_offset_x.val, V.land.tower_offset_y.val, 0.0)  #Tower location
            for i in range(len(V.land.inclusions.val)):  #For each polygon in the inclusions
                if Toolbox.pointInPolygon(V.land.inclusions.val[i], T):
                    trmin = 0.0
                    break
                var nincpt: Int = len(V.land.inclusions.val[i])
                for j in range(nincpt):
                    if j < nincpt - 1:
                        pt1.Set(V.land.inclusions.val[i][j+1])
                    else:
                        pt1.Set(V.land.inclusions.val[i][0])
                    Toolbox.line_norm_intersect(V.land.inclusions.val[i][j], pt1, T, N, rad)
                    if fabs(rad) < trmin:
                        trmin = rad
            var ex1: sp_point
            var excheck: Float64 = 9.0e9
            for i in range(len(V.land.exclusions.val)):  #For each polygon in the exclusions
                if not Toolbox.pointInPolygon(V.land.exclusions.val[i], T):
                    continue
                var nex: Int = len(V.land.exclusions.val[i])
                for j in range(nex):
                    if j < nex - 1:
                        ex1.Set(V.land.exclusions.val[i][j+1])
                    else:
                        ex1.Set(V.land.exclusions.val[i][0])
                    Toolbox.line_norm_intersect(V.land.exclusions.val[i][j], ex1, T, N, rad)
                    if fabs(rad) < excheck:
                        excheck = rad
            if excheck > trmin and excheck < 9.0e9:
                trmin = excheck
            if trmin > radmax:
                trmin = 0.001  #Use a small number larger than zero if nothing is set
            if trmin > radmin or radmin == 0:
                radmin = trmin
        rval[0] = radmin
        rval[1] = radmax

    @staticmethod
    def getRadialExtents(inout V: var_map, rval: List[Float64], tht: Float64):
        """ 
        Sets the values of rval equal to the [min radius, max radius] of the field. This ONLY APPLIES to the 
        radial boundary settings and not to the polygonal boundary settings. If no radial boundaries are used,
        return [-1,-1].
        """
        var radmin: Float64 = 0.0
        var radmax: Float64 = 0.0
        if V.land.is_bounds_scaled.val:
            radmin = V.land.min_scaled_rad.val * tht
            radmax = V.land.max_scaled_rad.val * tht
        if V.land.is_bounds_fixed.val:
            if V.land.min_fixed_rad.val > radmin or radmin == 0:
                radmin = V.land.min_fixed_rad.val  #Only change if the fix min radius is larger than the previous bound
            if V.land.max_fixed_rad.val < radmax or radmax == 0:
                radmax = V.land.max_fixed_rad.val  #Only change if the fix max radius is smaller than the previous bound
        rval[0] = radmin
        rval[1] = radmax
        if radmin == 0:
            rval[0] = -1.0
        if radmax == 0:
            rval[1] = -1.0

    @staticmethod
    def calcPolyLandArea(inout V: var_land) -> Float64:
        var area: Float64 = 0.0
        for i in range(len(V.inclusions.val)):
            var np: Int = len(V.inclusions.val[i])
            var j: Int = np - 1
            for k in range(np):
                var pj: sp_point = V.inclusions.val[i][j]
                var pk: sp_point = V.inclusions.val[i][k]
                area += (pj.x + pk.x) * (pj.y - pk.y) / 2.0
                j = k
        area = fabs(area)
        var excs: Float64 = 0.0
        for i in range(len(V.exclusions.val)):
            var np: Int = len(V.exclusions.val[i])
            var j: Int = np - 1
            for k in range(np):
                var pj: sp_point = V.exclusions.val[i][j]
                var pk: sp_point = V.exclusions.val[i][k]
                excs += (pj.x + pk.x) * (pj.y - pk.y) / 2.0
                j = k
        excs = fabs(excs)
        return area - excs

    def calcLandArea(inout self, inout V: var_land, inout layout: List[sp_point]):
        """ 
        Calculate the land area either using provided polygons, or using the convex hull around the heliostat field. 
        For polygons, assume that the geometry provided accurately represents the land area that is to be accounted for in the cost
        calculations. If only land exclusions are provided, use the convex hull method instead.
        """
        if V.is_bounds_array.val and (len(V.inclusions.val) > 0):
            self._bound_area = Land.calcPolyLandArea(V)
        else:
            var hull: List[sp_point] = List[sp_point]()
            Toolbox.convex_hull(layout, hull)
            self._bound_area = Toolbox.area_polygon(hull)
<<<FILE>>>