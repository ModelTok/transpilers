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

from core import *

var _cm_vtab_timeseq: List[var_info] = List[var_info]()
_cm_vtab_timeseq.append( var_info(SSC_INPUT, SSC_NUMBER, "start_time", "Start time", "seconds", "0=jan1st 12am", "Time Sequence", "*", "MIN=0,MAX=31536000", "") )
_cm_vtab_timeseq.append( var_info(SSC_INPUT, SSC_NUMBER, "end_time", "End time", "seconds", "0=jan1st 12am", "Time Sequence", "*", "MIN=0,MAX=31536000", "") )
_cm_vtab_timeseq.append( var_info(SSC_INPUT, SSC_NUMBER, "time_step", "Time step", "seconds", "", "Time Sequence", "*", "MIN=1,MAX=3600", "") )
_cm_vtab_timeseq.append( var_info(SSC_OUTPUT, SSC_ARRAY, "time", "Time", "secs", "0=jan1st 12am", "Time", "*", "", "") )
_cm_vtab_timeseq.append( var_info(SSC_OUTPUT, SSC_ARRAY, "timehr", "HourTime", "hours", "0=jan1st 12am", "Time", "*", "", "") )
_cm_vtab_timeseq.append( var_info(SSC_OUTPUT, SSC_ARRAY, "month", "Month", "", "1-12", "Time", "*", "", "") )
_cm_vtab_timeseq.append( var_info(SSC_OUTPUT, SSC_ARRAY, "day", "Day", "", "1-{28,30,31}", "Time", "*", "", "") )
_cm_vtab_timeseq.append( var_info(SSC_OUTPUT, SSC_ARRAY, "hour", "Hour", "", "0-23", "Time", "*", "", "") )
_cm_vtab_timeseq.append( var_info(SSC_OUTPUT, SSC_ARRAY, "minute", "Minute", "", "0-59", "Time", "*", "", "") )
_cm_vtab_timeseq.append( var_info_invalid )

class cm_timeseq(compute_module):
    def __init__(self):
        self.add_var_info(_cm_vtab_timeseq)

    def exec(self):
        var t_start = self.as_double("start_time")
        var t_end = self.as_double("end_time")
        var t_step = self.as_double("time_step") # seconds
        var num_steps = self.check_timestep_seconds(t_start, t_end, t_step)
        var time = self.allocate("time", num_steps)
        var timehr = self.allocate("timehr", num_steps)
        var month = self.allocate("month", num_steps)
        var day = self.allocate("day", num_steps)
        var hour = self.allocate("hour", num_steps)
        var minute = self.allocate("minute", num_steps)
        var T = t_start
        var idx = 0
        while T < t_end and idx < num_steps:
            var Thr = T / 3600.0
            time[idx] = Float32(T)
            timehr[idx] = Float32(Thr)
            var m = util.month_of(Thr)
            month[idx] = ssc_number_t(m)              # month goes 1-12
            day[idx] = ssc_number_t(util.day_of_month(m, Thr))   # day goes 1-nday_in_month
            hour[idx] = ssc_number_t(Int(Thr) % 24)		         # hour goes 0-23
            minute[idx] = ssc_number_t(Int((Thr - math.floor(Thr)) * 60 + t_step / 3600.0 * 30))      # minute goes 0-59
            T += t_step
            idx += 1

#DEFINE_MODULE_ENTRY( timeseq, "Time sequence generator", 1 )