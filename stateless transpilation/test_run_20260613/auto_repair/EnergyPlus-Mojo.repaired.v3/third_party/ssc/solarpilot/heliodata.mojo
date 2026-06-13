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

struct helio_perf_data:
    var _dvars: List[Pointer[Float64]]

    struct PERF_VALUES:
        enum A:
            case POWER_TO_REC = 0
            case ETA_TOT = 1
            case ETA_COS = 2
            case ETA_ATT = 3
            case ETA_INT = 4
            case ETA_BLOCK = 5
            case ETA_SHADOW = 6
            case POWER_VALUE = 7
            case REFLECTIVITY = 8
            case SOILING = 9
            case REC_ABSORPTANCE = 10
            case RANK_METRIC = 11
            case ETA_CLOUD = 12

    var n_metric: Int
    var eta_cos: Float64
    var eta_att: Float64
    var eta_int: Float64
    var eta_block: Float64
    var eta_shadow: Float64
    var eta_tot: Float64
    var reflectivity: Float64
    var soiling: Float64
    var rec_absorptance: Float64
    var power_to_rec: Float64
    var power_value: Float64
    var rank_metric: Float64
    var eta_cloud: Float64

    def __init__(inout self):
        self.resetMetrics()
        self.n_metric = 13

    def getDataByIndex(inout self, id: Int) -> Float64:
        var rval: Float64
        if id == helio_perf_data.PERF_VALUES.A.POWER_TO_REC:
            rval = self.power_to_rec
        elif id == helio_perf_data.PERF_VALUES.A.ETA_TOT:
            rval = self.eta_tot
        elif id == helio_perf_data.PERF_VALUES.A.ETA_COS:
            rval = self.eta_cos
        elif id == helio_perf_data.PERF_VALUES.A.ETA_ATT:
            rval = self.eta_att
        elif id == helio_perf_data.PERF_VALUES.A.ETA_INT:
            rval = self.eta_int
        elif id == helio_perf_data.PERF_VALUES.A.ETA_BLOCK:
            rval = self.eta_block
        elif id == helio_perf_data.PERF_VALUES.A.ETA_SHADOW:
            rval = self.eta_shadow
        elif id == helio_perf_data.PERF_VALUES.A.POWER_VALUE:
            rval = self.power_value
        elif id == helio_perf_data.PERF_VALUES.A.REFLECTIVITY:
            rval = self.reflectivity
        elif id == helio_perf_data.PERF_VALUES.A.SOILING:
            rval = self.soiling
        elif id == helio_perf_data.PERF_VALUES.A.RANK_METRIC:
            rval = self.rank_metric
        elif id == helio_perf_data.PERF_VALUES.A.REC_ABSORPTANCE:
            rval = self.rec_absorptance
        elif id == helio_perf_data.PERF_VALUES.A.ETA_CLOUD:
            rval = self.eta_cloud
        else:
            rval = 0.0
        return rval

    def setDataByIndex(inout self, id: Int, value: Float64):
        if id == helio_perf_data.PERF_VALUES.A.ETA_ATT:
            self.eta_att = value
        elif id == helio_perf_data.PERF_VALUES.A.ETA_BLOCK:
            self.eta_block = value
        elif id == helio_perf_data.PERF_VALUES.A.ETA_COS:
            self.eta_cos = value
        elif id == helio_perf_data.PERF_VALUES.A.ETA_INT:
            self.eta_int = value
        elif id == helio_perf_data.PERF_VALUES.A.ETA_SHADOW:
            self.eta_shadow = value
        elif id == helio_perf_data.PERF_VALUES.A.ETA_TOT:
            self.eta_tot = value
        elif id == helio_perf_data.PERF_VALUES.A.REFLECTIVITY:
            self.reflectivity = value
        elif id == helio_perf_data.PERF_VALUES.A.SOILING:
            self.soiling = value
        elif id == helio_perf_data.PERF_VALUES.A.POWER_TO_REC:
            self.power_to_rec = value
        elif id == helio_perf_data.PERF_VALUES.A.POWER_VALUE:
            self.power_value = value
        elif id == helio_perf_data.PERF_VALUES.A.RANK_METRIC:
            self.rank_metric = value
        elif id == helio_perf_data.PERF_VALUES.A.REC_ABSORPTANCE:
            self.rec_absorptance = value
        elif id == helio_perf_data.PERF_VALUES.A.ETA_CLOUD:
            self.eta_cloud = value

    def resetMetrics(inout self):
        self.eta_tot = 0.0
        self.eta_cos = 1.0
        self.eta_att = 1.0
        self.eta_int = 1.0
        self.eta_block = 1.0
        self.eta_shadow = 1.0
        self.eta_cloud = 1.0
        self.power_to_rec = 0.0
        self.power_value = 0.0
        self.rank_metric = 0.0

    def calcTotalEfficiency(inout self) -> Float64:
        self.eta_tot = self.eta_cos * self.eta_att * self.eta_int * self.eta_block * self.eta_shadow * self.reflectivity * self.soiling * self.eta_cloud
        return self.eta_tot