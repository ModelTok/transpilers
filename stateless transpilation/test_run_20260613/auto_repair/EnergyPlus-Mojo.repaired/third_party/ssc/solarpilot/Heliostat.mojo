/**
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
*/

from heliodata import helio_perf_data, sp_point, Vect, PointVect
from mod_base import mod_base
from definitions import matrix_t, PI, D2R, Toolbox, spexception, DateTime
from Flux import Flux
from SolarField import SolarField
from Receiver import Receiver
from Ambient import Ambient
from var_heliostat import var_heliostat
from var_map import var_map
from solpos00 import S_init, posdata, S_solpos, S_decode

# Forward declarations
class Reflector:
    var _width: Float64
    var _height: Float64
    var _diameter: Float64
    var _focal_length: Float64
    var _id: Int
    var _type: Int
    var _geometry: matrix_t[PointVect]
    var _locate_vector: PointVect

    def __init__(inout self):
        """Reflector::Reflector()"""
        self.setDefaults()

    def getId(self) -> Int:
        return self._id

    def getWidth(self) -> Float64:
        return self._width

    def getHeight(self) -> Float64:
        return self._height

    def getDiameter(self) -> Float64:
        return self._diameter

    def getFocalLength(self) -> Float64:
        return self._focal_length

    def getType(self) -> Int:
        return self._type

    def getOrientation(self) -> Pointer[PointVect]:
        return Pointer(self._locate_vector)

    def setId(inout self, id: Int):
        self._id = id

    def setType(inout self, type: Int):
        self._type = type

    def setWidth(inout self, width: Float64):
        self._width = width

    def setHeight(inout self, height: Float64):
        self._height = height

    def setDiameter(inout self, diam: Float64):
        self._diameter = diam

    def setDefaults(inout self):
        self._width = 0.0
        self._height = 0.0
        self._diameter = 0.0
        self._focal_length = 0.0
        self._id = -1
        self._type = 1
        self.setOrientation(0.0, 0.0, 0.0, 0.0, 0.0, 0.0)

    def setPosition(inout self, x: Float64, y: Float64, z: Float64):
        self._locate_vector.x = x
        self._locate_vector.y = y
        self._locate_vector.z = z

    def setAim(inout self, i: Float64, j: Float64, k: Float64):
        self._locate_vector.i = i
        self._locate_vector.j = j
        self._locate_vector.k = k

    def setAim(inout self, V: Vect):
        self._locate_vector.i = V.i
        self._locate_vector.j = V.j
        self._locate_vector.k = V.k

    def setOrientation(inout self, x: Float64, y: Float64, z: Float64, i: Float64, j: Float64, k: Float64):
        self.setPosition(x, y, z)
        self.setAim(i, j, k)

    def setOrientation(inout self, PV: PointVect):
        self.setPosition(PV.x, PV.y, PV.z)
        self.setAim(PV.i, PV.j, PV.k)


class Heliostat(mod_base):
    var _location: sp_point
    var _aim_point: sp_point
    var _aim_fluxplane: sp_point
    var _track: Vect
    var _tower_vect: Vect
    var _cant_vect: Vect
    var _neighbors: Pointer[List[Pointer[Heliostat]]]
    var _panels: matrix_t[Reflector]
    var _corners: List[sp_point]
    var _shadow: List[sp_point]
    var _master_template: Pointer[Heliostat]
    var _mu_MN: matrix_t[Float64]
    var _mu_S: matrix_t[Float64]
    var _mu_G: matrix_t[Float64]
    var _mu_M: matrix_t[Float64]
    var _mu_F: matrix_t[Float64]
    var _hcoef: matrix_t[Float64]
    var _hc_tht: matrix_t[Float64]
    var _in_layout: Bool
    var _is_user_canted: Bool
    var _is_enabled: Bool
    var _id: Int
    var _group: StaticTuple[Int, 2]
    var _xfocal: Float64
    var _yfocal: Float64
    var eff_data: helio_perf_data
    var _slant: Float64
    var _zenith: Float64
    var _azimuth: Float64
    var _r_collision: Float64
    var _area: Float64
    var _image_size_xy: StaticTuple[Float64, 2]
    var _helio_name: String
    var _which_rec: Pointer[Receiver]
    var _var_helio: Pointer[var_heliostat]

    def __init__(inout self):
        # Default constructor (not explicitly defined in C++, but needed)
        # Fields default-initialized by Mojo

    def calcTotalEfficiency(self) -> Float64:
        return self.eff_data.calcTotalEfficiency()

    def getId(self) -> Int:
        return self._id

    def getGroupId(self) -> Pointer[Int]:
        return Pointer(self._group.data)

    def IsInLayout(self) -> Bool:
        return self._in_layout

    def getFocalX(self) -> Float64:
        return self._xfocal

    def getFocalY(self) -> Float64:
        return self._yfocal

    def getSlantRange(self) -> Float64:
        return self._slant

    def getWhichReceiver(self) -> Pointer[Receiver]:
        return self._which_rec

    def getRadialPos(self) -> Float64:
        return sqrt(pow(self._location.x, 2.0) + pow(self._location.y, 2.0) + pow(self._location.z, 2.0))

    def getAzimuthalPos(self) -> Float64:
        return atan2(self._location.x, self._location.y)

    def getPanels(self) -> Pointer[matrix_t[Reflector]]:
        return Pointer(self._panels)

    def getTrackVector(self) -> Pointer[Vect]:
        return Pointer(self._track)

    def getTowerVector(self) -> Pointer[Vect]:
        return Pointer(self._tower_vect)

    def getCantVector(self) -> Pointer[Vect]:
        return Pointer(self._cant_vect)

    def getLocation(self) -> Pointer[sp_point]:
        return Pointer(self._location)

    def getAimPoint(self) -> Pointer[sp_point]:
        return Pointer(self._aim_point)

    def getAimPointFluxPlane(self) -> Pointer[sp_point]:
        return Pointer(self._aim_fluxplane)

    def getEfficiencyObject(self) -> Pointer[helio_perf_data]:
        return Pointer(self.eff_data)

    def getTotalReflectivity(self) -> Float64:
        return self.eff_data.reflectivity * self.eff_data.soiling

    def getEfficiencyTotal(self) -> Float64:
        return self.eff_data.eta_tot

    def getEfficiencyCosine(self) -> Float64:
        return self.eff_data.eta_cos

    def getEfficiencyAtten(self) -> Float64:
        return self.eff_data.eta_att

    def getEfficiencyIntercept(self) -> Float64:
        return self.eff_data.eta_int

    def getEfficiencyBlock(self) -> Float64:
        return self.eff_data.eta_block

    def getEfficiencyShading(self) -> Float64:
        return self.eff_data.eta_shadow

    def getEfficiencyCloudiness(self) -> Float64:
        return self.eff_data.eta_cloud

    def getPowerToReceiver(self) -> Float64:
        return self.eff_data.power_to_rec

    def getPowerValue(self) -> Float64:
        return self.eff_data.power_value

    def getRankingMetricValue(self) -> Float64:
        return self.eff_data.rank_metric

    def getAzimuthTrack(self) -> Float64:
        return self._azimuth

    def getZenithTrack(self) -> Float64:
        return self._zenith

    def getCollisionRadius(self) -> Float64:
        return self._r_collision

    def getArea(self) -> Float64:
        return self._area

    def getNeighborList(self) -> Pointer[List[Pointer[Heliostat]]]:
        return self._neighbors

    def getCornerCoords(self) -> Pointer[List[sp_point]]:
        return Pointer(self._corners)

    def getShadowCoords(self) -> Pointer[List[sp_point]]:
        return Pointer(self._shadow)

    def getMirrorShapeNormCoefObject(self) -> Pointer[matrix_t[Float64]]:
        return Pointer(self._mu_MN)

    def getMirrorShapeCoefObject(self) -> Pointer[matrix_t[Float64]]:
        return Pointer(self._mu_M)

    def getSunShapeCoefObject(self) -> Pointer[matrix_t[Float64]]:
        return Pointer(self._mu_S)

    def getErrorDistCoefObject(self) -> Pointer[matrix_t[Float64]]:
        return Pointer(self._mu_G)

    def getFluxMomentsObject(self) -> Pointer[matrix_t[Float64]]:
        return Pointer(self._mu_F)

    def getHermiteCoefObject(self) -> Pointer[matrix_t[Float64]]:
        return Pointer(self._hcoef)

    def getHermiteNormCoefObject(self) -> Pointer[matrix_t[Float64]]:
        return Pointer(self._hc_tht)

    def getImageSize(self) -> Pointer[Float64]:
        return Pointer(self._image_size_xy.data)

    def getImageSize(self, sigx_n: inout Float64, sigy_n: inout Float64):
        sigx_n = self._image_size_xy[0]
        sigy_n = self._image_size_xy[1]

    def getHeliostatName(self) -> Pointer[String]:
        return Pointer(self._helio_name)

    def getMasterTemplate(self) -> Pointer[Heliostat]:
        return self._master_template

    def getVarMap(self) -> Pointer[var_heliostat]:
        return self._var_helio

    def IsUserCant(self) -> Bool:
        return self._is_user_canted

    def IsUserCant(inout self, setting: Bool):
        self._is_user_canted = setting

    def IsEnabled(self) -> Bool:
        return self._is_enabled

    def IsEnabled(inout self, enable: Bool):
        self._is_enabled = enable

    def setId(inout self, id: Int):
        self._id = id

    def setGroupId(inout self, row: Int, col: Int):
        self._group[0] = row
        self._group[1] = col

    def setInLayout(inout self, in_layout: Bool):
        self._in_layout = in_layout

    def setNeighborList(inout self, list: Pointer[List[Pointer[Heliostat]]]):
        self._neighbors = list

    def setEfficiencyCosine(inout self, eta_cos: Float64):
        self.eff_data.eta_cos = fmin(fmax(eta_cos, 0.0), 1.0)

    def setEfficiencyAtmAtten(inout self, eta_att: Float64):
        self.eff_data.eta_att = eta_att

    def setEfficiencyIntercept(inout self, eta_int: Float64):
        self.eff_data.eta_int = eta_int

    def setEfficiencyBlocking(inout self, eta_block: Float64):
        self.eff_data.eta_block = eta_block

    def setEfficiencyShading(inout self, eta_shadow: Float64):
        self.eff_data.eta_shadow = eta_shadow

    def setEfficiencyCloudiness(inout self, eta_cloud: Float64):
        self.eff_data.eta_cloud = eta_cloud

    def setEfficiencyTotal(inout self, eta_tot: Float64):
        self.eff_data.eta_tot = eta_tot

    def setRankingMetricValue(inout self, rval: Float64):
        self.eff_data.rank_metric = rval

    def setAimPointFluxPlane(inout self, Aim: sp_point):
        self._aim_fluxplane.Set(Aim.x, Aim.y, Aim.z)

    def setAimPointFluxPlane(inout self, x: Float64, y: Float64, z: Float64):
        self._aim_fluxplane.Set(x, y, z)

    def setTrackVector(inout self, tr: Vect):
        self._track = tr

    def setTowerVector(inout self, tow: Vect):
        self._tower_vect = tow

    def setTrackAngleZenith(inout self, zenith: Float64):
        self._zenith = zenith

    def setTrackAngleAzimuth(inout self, azimuth: Float64):
        self._azimuth = azimuth

    def setTrackAngles(inout self, azimuth: Float64, zenith: Float64):
        self._zenith = zenith
        self._azimuth = azimuth

    def setCantVector(inout self, cant: Vect):
        self._cant_vect.Set(cant.i, cant.j, cant.k)

    def setCantVector(inout self, cant: StaticTuple[Float64, 3]):
        self._cant_vect.Set(cant[0], cant[1], cant[2])

    def setSlantRange(inout self, L: Float64):
        self._slant = L
        if self._var_helio[].cant_method.mapval() == var_heliostat.CANT_METHOD.ONAXIS_AT_SLANT:
            self._xfocal = L
            self._yfocal = L

    def setFocalLengthX(inout self, L: Float64):
        self._xfocal = L

    def setFocalLengthY(inout self, L: Float64):
        self._yfocal = L

    def setFocalLength(inout self, L: Float64):
        self._yfocal = L
        self._xfocal = L

    def setWhichReceiver(inout self, rec: Pointer[Receiver]):
        self._which_rec = rec

    def setPowerToReceiver(inout self, P: Float64):
        self.eff_data.power_to_rec = P

    def setPowerValue(inout self, P: Float64):
        self.eff_data.power_value = P

    def setImageSize(inout self, sigx_n: Float64, sigy_n: Float64):
        self._image_size_xy[0] = sigx_n
        self._image_size_xy[1] = sigy_n

    def setMasterTemplate(inout self, htemp: Pointer[Heliostat]):
        self._master_template = htemp

    def resetMetrics(inout self):
        self.eff_data.resetMetrics()

    def Create(inout self, V: var_map, htnum: Int):
        self._var_helio = Pointer(V.hels[htnum])
        self._helio_name = self._var_helio[].helio_name.val
        self._id = self._var_helio[].id.val
        self._is_enabled = self._var_helio[].is_enabled.val
        self._location.Set(0.0, 0.0, 0.0)  # default
        self._xfocal = self._var_helio[].x_focal_length.val
        self._yfocal = self._var_helio[].y_focal_length.val
        self._cant_vect.Set(0.0, 0.0, 1.0)
        self.eff_data.reflectivity = self._var_helio[].reflectivity.val
        self.eff_data.soiling = self._var_helio[].soiling.val
        self._track = Vect()  # The tracking vector for the heliostat, defaults to 0,0,1
        self._tower_vect = Vect()  # Heliostat-to-tower unit vector
        self.updateCalculatedParameters(V, htnum)  # updates var_map
        self.installPanels()

    def updateCalculatedParameters(inout self, Vm: var_map, htnum: Int):
        let tht: Float64 = Vm.sf.tht.val
        let V: Pointer[var_heliostat] = Pointer(Vm.hels[htnum])
        if V[].is_round.mapval() == var_heliostat.IS_ROUND.ROUND:
            self._r_collision = V[].diameter.val / 2.0
            self._area = PI * pow(V[].diameter.val / 2.0, 2.0) * V[].reflect_ratio.val
        else:
            self._r_collision = sqrt(
                V[].height.val * V[].height.val / 4.0 + V[].width.val * V[].width.val / 4.0
            )
            self._area = (
                V[].width.val * V[].height.val * V[].reflect_ratio.val  # width * height * structural density is the base area
                - V[].x_gap.val * V[].height.val * (V[].n_cant_x.val - 1)
                - V[].y_gap.val * V[].width.val * (V[].n_cant_y.val - 1)  # subtract off gap areas
                + (V[].n_cant_y.val - 1) * (V[].n_cant_x.val - 1) * V[].x_gap.val * V[].y_gap.val
            )  # but don't double-count the little squares in both gaps
        V[].area.Setval(self._area)
        V[].r_collision.Setval(self._r_collision)
        var err_elevation: Float64
        var err_azimuth: Float64
        var err_surface_x: Float64
        var err_surface_y: Float64
        var err_reflect_x: Float64
        var err_reflect_y: Float64
        err_elevation = V[].err_elevation.val
        err_azimuth = V[].err_azimuth.val
        err_surface_x = V[].err_surface_x.val
        err_surface_y = V[].err_surface_y.val
        err_reflect_x = V[].err_reflect_x.val
        err_reflect_y = V[].err_reflect_y.val
        let err_tot: Float64 = sqrt(
            pow(2.0 * err_elevation, 2.0) + pow(2.0 * err_azimuth, 2.0) + pow(2.0 * err_surface_x, 2.0)
            + pow(2.0 * err_surface_y, 2.0) + pow(err_reflect_x, 2.0) + pow(err_reflect_y, 2.0)
        )
        V[].err_total.Setval(err_tot)
        let ref: Float64 = V[].reflectivity.val
        let soil: Float64 = V[].soiling.val
        V[].ref_total.Setval(ref * soil)
        let cant_method: Int = V[].cant_method.mapval()
        # 
        # No canting=0
        # On-axis at slant=-1
        # On-axis, user-defined=1
        # Off-axis, day and hour=3
        # User-defined vector=4 
        # 
        if cant_method == var_heliostat.CANT_METHOD.NO_CANTING:

        elif cant_method == var_heliostat.CANT_METHOD.ONAXIS_AT_SLANT:

        elif cant_method == var_heliostat.CANT_METHOD.ONAXIS_USERDEFINED:
            var cant_radius: Float64
            let cant_rad_scaled: Float64 = V[].cant_rad_scaled.val
            if V[].is_cant_rad_scaled.val:
                cant_radius = cant_rad_scaled * tht
            else:
                cant_radius = cant_rad_scaled
            V[].cant_radius.Setval(cant_radius)
        elif cant_method == var_heliostat.CANT_METHOD.OFFAXIS_DAY_AND_HOUR:
            # Calculate the sun position at this day and hour 
            let cant_day: Int = V[].cant_day.val
            let cant_hour: Float64 = V[].cant_hour.val
            let lat: Float64 = Vm.amb.latitude.val
            let lon: Float64 = Vm.amb.longitude.val
            let tmz: Float64 = Vm.amb.time_zone.val
            let DT: DateTime = DateTime()
            var month: Int
            var dom: Int
            DT.hours_to_date((cant_day - 1) * 24 + cant_hour + 12, month, dom)
            var SP: posdata
            var pdat: Pointer[posdata] = Pointer(SP)  # point to structure for convenience
            S_init(pdat)  # Initialize the values
            var cant_hour_int: Int
            var cant_min_int: Int
            cant_hour_int = Int(floor(cant_hour + 0.001))
            cant_min_int = Int(floor((cant_hour - Float64(cant_hour_int)) * 60.0))
            pdat[].latitude = Float32(lat)  # [deg] {float} North is positive
            pdat[].longitude = Float32(lon)  # [deg] {float} Degrees east. West is negative
            pdat[].timezone = Float32(tmz)  # [hr] {float} Time zone, east pos. west negative. Mountain -7, Central -6, etc..
            pdat[].year = 2011  # [year] {int} 4-digit year
            pdat[].month = month  # [mo] {int} (1-12)
            pdat[].day = dom  # [day] {int} Day of the month
            pdat[].daynum = cant_day  # [day] {int} Day of the year
            pdat[].hour = cant_hour_int + 12  # [hr] {int} 0-23
            pdat[].minute = cant_min_int  # [min] {int} 0-59
            pdat[].second = 0  # [sec]	{int} 0-59
            pdat[].interval = 0  # [sec] {int} Measurement interval. See solpos documentation.
            var retcode: Int = 0  # Initialize with no errors
            retcode = S_solpos(pdat)  # Call the solar position algorithm
            S_decode(retcode, pdat)  # Check the return code
            # Check to see if the time/day entered is below sunset. If so, notify the user 
            DT.SetHour(12)
            DT.SetDate(2011, month, dom)
            DT.SetYearDay(cant_day + 1)
            var hrs: StaticTuple[Float64, 2]
            Ambient.calcDaytimeHours(hrs, lat * D2R, lon * D2R, tmz, DT)
            hrs[0] += -12.0
            hrs[1] += -12.0
            V[].cant_sun_el.Setval(90.0 - SP.zenetr)
            V[].cant_sun_az.Setval(SP.azim)
        elif cant_method == var_heliostat.CANT_METHOD.USERDEFINED_VECTOR:
            let i: Float64 = V[].cant_vect_i.val * V[].cant_vect_i.val
            let j: Float64 = V[].cant_vect_j.val * V[].cant_vect_j.val
            let k: Float64 = V[].cant_vect_k.val * V[].cant_vect_k.val
            let cmag: Float64 = sqrt(i * i + j * j + k * k)
            V[].cant_norm_i.Setval(i / cmag)
            V[].cant_norm_j.Setval(j / cmag)
            V[].cant_norm_k.Setval(k / cmag)
            let scale: Float64 = V[].cant_vect_scale.val
            V[].cant_mag_i.Setval(i / cmag * scale)
            V[].cant_mag_j.Setval(j / cmag * scale)
            V[].cant_mag_k.Setval(k / cmag * scale)
        else:

    def getSummaryResults(self, results: inout List[Float64]):
        # Fill the vector "results" with performance metrics of interest
        results.resize(self.eff_data.n_metric)
        for i in range(self.eff_data.n_metric):
            results[i] = self.eff_data.getDataByIndex(i)

    def setAimPoint(inout self, x: Float64, y: Float64, z: Float64):
        self._aim_point.x = x
        self._aim_point.y = y
        self._aim_point.z = z

    def setAimPoint(inout self, Aim: sp_point):
        self.setAimPoint(Aim.x, Aim.y, Aim.z)

    def installPanels(inout self):
        # 
        # This method uses the inputs to define the location and pointing vector of each
        # panel on the heliostat. 
        # DELSOL3 lines 6494-6520
        # Note that in DELSOL3, this originally is part of the flux algorithm. The panel
        # arrangement is more conveniently conceptualized as an attribute of the heliostat
        # rather than as part of the flux algorithm, so it is placed here instead.
        # 
        let V: Pointer[var_heliostat] = self._var_helio
        self.setImageSize(0.0, 0.0)
        if V[].is_round.mapval() == var_heliostat.IS_ROUND.ROUND:
            # 
            # This configuration allows only 1 facet per heliostat. By default, the canting is normal.
            # 
            self._panels.resize(1, 1)
            self._panels[0, 0].setId(0)
            self._panels[0, 0].setType(2)  # Circular
            self._panels[0, 0].setDiameter(V[].diameter.val)
            self._panels[0, 0].setHeight(V[].diameter.val)
            self._panels[0, 0].setWidth(V[].diameter.val)
            self._panels[0, 0].setPosition(0.0, 0.0, 0.0)
            self._panels[0, 0].setAim(0.0, 0.0, 1.0)
        else:  # Rectangular heliostats
            var dx: Float64
            var dy: Float64
            var x: Float64
            var y: Float64
            dx = (V[].width.val - V[].x_gap.val * (V[].n_cant_x.val - 1.0)) / Float64(V[].n_cant_x.val)  # [m] width of each canting panel
            dy = (V[].height.val - V[].y_gap.val * (V[].n_cant_y.val - 1.0)) / Float64(V[].n_cant_y.val)  # [m] height of each panel
            var id: Int = 0
            self._panels.resize(V[].n_cant_y.val, V[].n_cant_x.val)
            var paim: sp_point  # heliostat aimpoint
            paim.x = self._location.x + self._slant * self._tower_vect.i
            paim.y = self._location.y + self._slant * self._tower_vect.j
            paim.z = self._location.z + self._slant * self._tower_vect.k
            y = -V[].height.val / 2.0 + dy * 0.5
            for j in range(V[].n_cant_y.val):
                x = -V[].width.val / 2.0 + dx * 0.5
                for i in range(V[].n_cant_x.val):
                    self._panels[j, i].setId(id)
                    id += 1
                    self._panels[j, i].setType(1)  # Type=1, rectangular panel
                    self._panels[j, i].setWidth(dx)
                    self._panels[j, i].setHeight(dy)
                    self._panels[j, i].setPosition(x, y, 0.0)
                    if V[].cant_method.mapval() == var_heliostat.CANT_METHOD.ONAXIS_AT_SLANT:
                        let hyp: Float64 = sqrt(pow(self._slant, 2.0) + pow(x, 2.0) + pow(y, 2.0))  # hypotenuse length
                        self._panels[j, i].setAim(-x / hyp, -y / hyp, 2.0 * self._slant / hyp)
                    elif V[].cant_method.mapval() == var_heliostat.CANT_METHOD.NO_CANTING:
                        self._panels[j, i].setAim(0.0, 0.0, 1.0)
                    elif V[].cant_method.mapval() == var_heliostat.CANT_METHOD.ONAXIS_USERDEFINED:
                        let hyp: Float64 = sqrt(V[].cant_radius.Val() * V[].cant_radius.Val() + x * x + y * y)  # cant focal length
                        self._panels[j, i].setAim(-x / hyp, -y / hyp, 2.0 * V[].cant_radius.Val() / hyp)
                    elif V[].cant_method.mapval() == var_heliostat.CANT_METHOD.OFFAXIS_DAY_AND_HOUR:
                        let track_az: Float64 = atan2(self._track.i, self._track.j)
                        let track_zen: Float64 = acos(self._track.k)
                        let prad: Float64 = sqrt(pow(x, 2.0) + pow(y * sin(track_zen), 2.0))  # the radius of the panel from the heliostat centroid
                        let theta_rot: Float64 = atan2(x, y)  # angle of rotation of the centroid of the point w/r/t the heliostat coordinates
                        var pg: sp_point
                        pg.x = self._location.x + prad * sin(track_az + theta_rot)
                        pg.y = self._location.y + prad * cos(track_az + theta_rot)
                        pg.z = self._location.z + y * sin(track_zen)
                        let pslant: Float64 = sqrt(pow(pg.x - paim.x, 2.0) + pow(pg.y - paim.y, 2.0) + pow(pg.z - paim.z, 2.0))
                        var pref: Vect
                        pref.i = (paim.x - pg.x) / pslant
                        pref.j = (paim.y - pg.y) / pslant
                        pref.k = (paim.z - pg.z) / pslant
                        var s_hat: Vect
                        s_hat.i = 2.0 * self._track.i - pref.i
                        s_hat.j = 2.0 * self._track.j - pref.j
                        s_hat.k = 2.0 * self._track.k - pref.k
                        self._panels[j, i].setAim(
                            (s_hat.i + pref.i) / 2.0 - self._track.i,
                            (s_hat.j + pref.j) / 2.0 - self._track.j,
                            (s_hat.k + pref.k) / 2.0 - self._track.k + 1.0,
                        )
                    elif V[].cant_method.mapval() == var_heliostat.CANT_METHOD.USERDEFINED_VECTOR:
                        var paim: Vect
                        let rscale: Float64 = V[].is_cant_rad_scaled.val if V[].cant_vect_scale.val else 1.0
                        # coordinate system: looking at the heliostat face on, +x is horizontal, +y vertical. Vector is assumed to come out of the 
                        # plane containing the heliostat in the direction of the viewer (i.e. it hits you in the face). This is -z. The if the 
                        # vector tilts to the right as viewed, this is +i / +x, up is +j / +y.
                        paim.Set(self._cant_vect.i * rscale - x, self._cant_vect.j * rscale - y, self._cant_vect.k * rscale)
                        Toolbox.unitvect(paim)
                        self._panels[j, i].setAim(paim)
                    else:
                        raise spexception(
                            "The requested canting option is not correctly implemented in the installPanels() algorithm. Contact support for help resolving this issue."
                        )
                    x += dx + V[].x_gap.val
                y += dy + V[].y_gap.val

    def updateTrackVector(inout self, sunvect: Vect):
        # 
        # Calculates the tracking vector given a solar position in "Ambient"
        # and a receiver in "Receiver".
        # Updates the coordinates of the heliostat corners for shadowing/blocking calculations.
        # Do not update the aim point. This method uses the currently assigned aim point.
        # This also updates:
        # _track			| setTrackVector()		| The tracking vector for the heliostat
        # _azimuth		| setTrackAngles()		| The tracking azimuth angle
        # _zenith			| setTrackAngles()		| The tracking zenith angle
        # _corners		| none					| The location of the heliostat corners in global coordinates (for shadowing and blocking)
        # Store the new tracking vector in _track
        # From Snell's law, n_hat = (s_hat + t_hat) / mag(s_hat + t_hat)
        # 	where:
        # 	n_hat is the normal tracking vector
        # 	s_hat is the heliostat to sun vector
        # 	t_hat is the helostat to receiver vector
        # 
        var n_hat: Vect  # tracking vector
        var s_hat: Vect  # heliostat to sun
        var t_hat: Vect  # heliostat to receiver
        s_hat = sunvect
        if self._is_enabled:
            t_hat.Set(
                self._aim_point.x - self._location.x,
                self._aim_point.y - self._location.y,
                self._aim_point.z - self._location.z,
            )
            Toolbox.unitvect(t_hat)
            var ts: Vect
            ts.i = t_hat.i + s_hat.i
            ts.j = t_hat.j + s_hat.j
            ts.k = t_hat.k + s_hat.k  # break down to save on calculation
            let ts_mag: Float64 = sqrt(pow(ts.i, 2.0) + pow(ts.j, 2.0) + pow(ts.k, 2.0))
            n_hat.i = ts.i / ts_mag
            n_hat.j = ts.j / ts_mag
            n_hat.k = ts.k / ts_mag
            self.setTrackAngles(atan2(n_hat.i, n_hat.j), acos(n_hat.k))
        else:
            t_hat.Set(-sunvect.i, -sunvect.j, sunvect.k)
            n_hat.Set(0.0, 0.0, 1.0)
            self.setTrackAngles(atan2(self._location.x, self._location.y), 0.0)
        self.setTrackVector(n_hat)
        self.setTowerVector(t_hat)
        # Calculate the location in global coordinates of the top two heliostat corners. Note that 
        # by the azimuth convention where North is 0deg, the upper edges of the heliostat will begin on
        # the southernmost edge of the heliostat.
        # Assume that the heliostat is starting out facing upward in the z direction with the 
        # upper and lower edges parallel to the global x axis (i.e. zenth=0, azimuth=0)
        # 
        if not (self._var_helio[].is_round.mapval() == var_heliostat.IS_ROUND.ROUND):
            let wm2: Float64 = self._var_helio[].width.val / 2.0
            let hm2: Float64 = self._var_helio[].height.val / 2.0
            self._corners.resize(4)
            self._corners[0].Set(-wm2, -hm2, 0.0)  # Upper right corner
            self._corners[1].Set(wm2, -hm2, 0.0)  # upper left corner
            self._corners[2].Set(wm2, hm2, 0.0)  # lower left
            self._corners[3].Set(-wm2, hm2, 0.0)  # lower right
            for i in range(4):  # For each point of interest...
                Toolbox.rotation(self._zenith, 0, self._corners[i])
                Toolbox.rotation(self._azimuth, 2, self._corners[i])
                self._corners[i].Add(self._location.x, self._location.y, self._location.z)
        else:

    @staticmethod
    def calcAndSetAimPointFluxPlane(aimpos_abs: sp_point, Rec: Pointer[Receiver], H: Pointer[Heliostat]):
        # 
        # Given a particular aim point in space, translate the position to an aimpoint on the actual
        # flux plane of the receiver. The original aimpoint may not necessarily be on the plane of the 
        # receiver, but the final aim point will be.
        # 
        var aimpos: sp_point = aimpos_abs
        var NV: PointVect
        Rec[].CalculateNormalVector(*H[].getLocation(), NV)  # Get the receiver normal vector
        let az: Float64 = atan2(NV.i, NV.j)
        let el: Float64 = atan2(NV.k * NV.k, NV.i * NV.i + NV.j * NV.j)
        Toolbox.rotation(PI - az, 2, aimpos)
        Toolbox.rotation(PI / 2.0 - el, 0, aimpos)
        if abs(aimpos.z) < 1.0e-6:
            aimpos.z = 0.0
        H[].setAimPointFluxPlane(aimpos.x, aimpos.y, aimpos.z)

    def setLocation(inout self, x: Float64, y: Float64, z: Float64):
        self._location.x = x
        self._location.y = y
        self._location.z = z

    def getPanelById(self, id: Int) -> Pointer[Reflector]:
        var ncantx: Int
        var ncanty: Int
        self._panels.size(ncantx, ncanty)  # is this the right order?
        for j in range(ncantx):
            for i in range(ncanty):
                if self._panels[j, i].getId() == id:
                    return Pointer(self._panels[j, i])
        return Pointer(self._panels[0, 0])

    def getPanel(self, row: Int, col: Int) -> Pointer[Reflector]:
        let nr: Int = Int(self._panels.nrows())
        let nc: Int = Int(self._panels.ncols())
        if row < nr and col < nc:
            return Pointer(self._panels[row, col])
        else:
            raise spexception("Index out of range in Heliostat::getPanel()")

    def CopyImageData(inout self, Hsrc: Pointer[Heliostat]):
        # 
        # Copy the image coefficients and data from 'Hsrc' and set as the local heliostat image coefs.
        # The following arrays are copied:
        # matrix_t<double>
        # 	_mu_MN,		//Normalized mirror shape hermite expansion coefficients (n_terms x n_terms)
        # 	_mu_S,		//Moments of sunshape
        # 	_mu_G,		//Moments of the error distribution
        # 	_mu_M,		//Moments of the mirror shape
        # 	_mu_F,		//Flux moments distribution - result
        # 	_hcoef,		//Hermite coefficients
        # 	_hc_tht; 	//Hermite coefs depending on tower height - equiv. to mu_F, reused in optimization calcs
        # 
        var nr: Int
        var nc: Int
        nr = Int(Hsrc[]._mu_MN.nrows())
        nc = Int(Hsrc[]._mu_MN.ncols())
        self._mu_MN.resize(nr, nc)
        for i in range(nr):
            for j in range(nc):
                self._mu_MN[i, j] = Hsrc[]._mu_MN[i, j]
        nr = Int(Hsrc[]._mu_S.nrows())
        nc = Int(Hsrc[]._mu_S.ncols())
        self._mu_S.resize(nr, nc)
        for i in range(nr):
            for j in range(nc):
                self._mu_S[i, j] = Hsrc[]._mu_S[i, j]
        nr = Int(Hsrc[]._mu_G.nrows())
        nc = Int(Hsrc[]._mu_G.ncols())
        self._mu_G.resize(nr, nc)
        for i in range(nr):
            for j in range(nc):
                self._mu_G[i, j] = Hsrc[]._mu_G[i, j]
        nr = Int(Hsrc[]._mu_M.nrows())
        nc = Int(Hsrc[]._mu_M.ncols())
        self._mu_M.resize(nr, nc)
        for i in range(nr):
            for j in range(nc):
                self._mu_M[i, j] = Hsrc[]._mu_M[i, j]
        nr = Int(Hsrc[]._mu_F.nrows())
        nc = Int(Hsrc[]._mu_F.ncols())
        self._mu_F.resize(nr, nc)
        for i in range(nr):
            for j in range(nc):
                self._mu_F[i, j] = Hsrc[]._mu_F[i, j]
        nc = Int(Hsrc[]._hcoef.ncells())
        self._hcoef.resize(nc)
        for j in range(nc):
            self._hcoef[j] = Hsrc[]._hcoef[j]
        nr = Int(Hsrc[]._hc_tht.nrows())
        nc = Int(Hsrc[]._hc_tht.ncols())
        self._hc_tht.resize(nr, nc)
        for i in range(nr):
            for j in range(nc):
                self._hc_tht[i, j] = Hsrc[]._hc_tht[i, j]


class HelioTemplate(Heliostat):
    def __init__(inout self):

    def __del__(owned self):
