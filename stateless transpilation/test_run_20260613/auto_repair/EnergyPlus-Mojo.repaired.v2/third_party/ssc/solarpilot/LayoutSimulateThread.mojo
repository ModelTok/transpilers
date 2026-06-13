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
from SolarField import SolarField, Heliostat, sim_results, sim_params, matrix_t, spexception
from WeatherData import WeatherData
from Ambient import Ambient
from DateTime import DateTime
from thread import Mutex
let PI: Float64 = 3.14159265358979323846
let D2R: Float64 = PI / 180.0

class LayoutSimThread:
    var _is_user_sun_pos: Bool
    var _is_shadow_detail: Bool
    var _is_flux_detail: Bool
    var _is_flux_normalized: Bool
    var Finished: Bool
    var CancelFlag: Bool
    var FinishedWithErrors: Bool
    var Nsim_complete: Int
    var Nsim_total: Int
    var _thread_id: String
    var _SF: SolarField
    var _sim_first: Int
    var _sim_last: Int
    var _sort_metric: Int
    var _wdata: WeatherData
    var _results: sim_results
    var _sol_azzen: matrix_t[Float64]
    var _sim_params: sim_params
    var _sim_messages: DynamicVector[String]
    var StatusLock: Mutex
    var CancelLock: Mutex
    var FinishedLock: Mutex
    var FinErrLock: Mutex

    def Setup(borrowed tname: String, borrowed SF: SolarField, borrowed results: sim_results, borrowed wdata: WeatherData,
        sim_first: Int, sim_last: Int, is_shadow_detail: Bool, is_flux_detail: Bool):
        """
        Assign all of the arguments to local memory
        """
        _thread_id = tname
        _SF = SF
        _results = results
        _wdata = wdata
        _sol_azzen = matrix_t[Float64]()
        _sim_first = sim_first
        _sim_last = sim_last
        Finished = False
        CancelFlag = False
        Nsim_complete = 0
        Nsim_total = _sim_last - _sim_first
        _is_user_sun_pos = False
        _is_shadow_detail = is_shadow_detail
        _is_flux_detail = is_flux_detail
        _is_flux_normalized = True

    def Setup(borrowed tname: String, borrowed SF: SolarField, borrowed results: sim_results, borrowed sol_azzen: matrix_t[Float64],
        borrowed simpars: sim_params, sim_first: Int, sim_last: Int, is_shadow_detail: Bool, is_flux_detail: Bool):
        """
        overload to allow specification of simulation sun positions. 
        Sun positions provided in a matrix_t
                |	Azimuth	|	Elevation
        Row		|	(rad)	|	(rad)
        --------------------------------
        1		|	az1		|	el1
        2		|	az2		|	el2
        ...
        Args:
        args[0]	|	DNI		|	W/m2
        args[1]	|	Tdb		|	C
        args[2]	|	Vwind	|	m/s
        args[3]	|	Pres	|	bar
        """
        _thread_id = tname
        _SF = SF
        _results = results
        _wdata = WeatherData()  # placeholder, not used
        _sol_azzen = sol_azzen
        _sim_first = sim_first
        _sim_last = sim_last
        Finished = False
        CancelFlag = False
        Nsim_complete = 0
        Nsim_total = _sim_last - _sim_first
        _is_user_sun_pos = True
        _sim_params = simpars
        _is_shadow_detail = is_shadow_detail
        _is_flux_detail = is_flux_detail
        _is_flux_normalized = True

    def IsFluxmapNormalized(is_normal: Bool):
        _is_flux_normalized = is_normal

    def CancelSimulation():
        CancelLock.lock()
        CancelFlag = True
        CancelLock.unlock()

    def IsSimulationCancelled() -> Bool:
        var r: Bool
        CancelLock.lock()
        r = CancelFlag
        CancelLock.unlock()
        return r

    def IsFinished() -> Bool:
        var f: Bool
        FinishedLock.lock()
        f = Finished
        FinishedLock.unlock()
        return f

    def IsFinishedWithErrors() -> Bool:
        var f: Bool
        FinErrLock.lock()
        f = FinishedWithErrors
        FinErrLock.unlock()
        return f

    def UpdateStatus(nsim_complete: Int, nsim_total: Int):
        StatusLock.lock()
        Nsim_complete = nsim_complete
        Nsim_total = nsim_total
        StatusLock.unlock()

    def GetStatus(ref nsim_complete: Int, ref nsim_total: Int):
        StatusLock.lock()
        nsim_complete = this.Nsim_complete
        nsim_total = this.Nsim_total
        StatusLock.unlock()

    def GetSimMessages() -> ref[DynamicVector[String]]:
        return _sim_messages

    def StartThread():  # Entry()
        """
        This method duplicates the functionality of SolarField::LayoutSimulate(...)
        This method is intended to be thread safe and can be called by the GUI directly. Each thread must have 
        its own instance of _SF. Before running multiple threads, create a solar field object, prepare it with
        PrepareFieldLayout(...), and use the deep copy constructor in SolarField to create as many duplicate
        objects as there are threads. Call this method for each duplicate object.
        """
        try:
            FinErrLock.lock()
            FinishedWithErrors = False
            FinErrLock.unlock()
            _sim_messages.clear()
            var pi: Float64 = PI
            var dom: Float64 = 0.0
            var doy: Float64 = 0.0
            var hour: Float64 = 0.0
            var month: Float64 = 0.0
            var az: Float64 = 0.0
            var zen: Float64 = 0.0
            var is_pmt_factors: Bool = _SF.getVarMap().fin.is_pmt_factors.val
            var tous: DynamicVector[Float64] = _SF.getVarMap().fin.pricing_array.Val()
            var Npos: Int = (_SF.getHeliostats().size()).to_int()
            StatusLock.lock()
            var is_cancel: Bool = this.CancelFlag  # check for cancelled simulation
            StatusLock.unlock()
            if is_cancel:
                FinishedLock.lock()
                Finished = True
                FinishedLock.unlock()
                return  # (wxThread::ExitCode)-1;
            if _sim_first < 0:
                _sim_first = 0
            if _sim_last < 0:
                _sim_last = _wdata.size()
            var nsim: Int = _sim_last - _sim_first + 1
            for i in range(_sim_first, _sim_last):
                var P: sim_params = sim_params()
                var DT: DateTime = DateTime()
                if not _is_user_sun_pos:
                    _wdata.getStep(i, dom, hour, month, P.dni, P.Tamb, P.Patm, P.Vwind, P.Simweight)
                    P.Patm = P.Patm * 0.001
                    doy = DT.GetDayOfYear(2011, month.to_int(), dom.to_int())
                    Ambient.setDateTime(DT, hour, doy)
                    if is_pmt_factors:
                        P.TOUweight = tous[DT.GetHourOfYear()]
                    Ambient.calcSunPosition(_SF.getVarMap(), DT, az, zen, True)
                    if zen > 90.0:
                        continue
                    az = az * D2R
                    zen = zen * D2R
                else:
                    az = _sol_azzen[i][0]
                    zen = _sol_azzen[i][1]
                    P = _sim_params
                var is_cancel: Bool = False
                StatusLock.lock()
                is_cancel = this.CancelFlag
                StatusLock.unlock()
                #if( (_is_shadow_detail || _is_flux_detail ) && !is_cancel)
                #    interop::AimpointUpdateHandler(*_SF);
                #StatusLock.lock();
                #is_cancel = this.CancelFlag; 
                #StatusLock.unlock();
                P.is_layout = not _is_shadow_detail
                if not is_cancel:
                    _SF.Simulate(az, zen, P)
                if (not is_cancel) and _is_flux_detail:
                    _SF.HermiteFluxSimulation(_SF.getHeliostats())
                StatusLock.lock()
                is_cancel = this.CancelFlag
                StatusLock.unlock()
                var azzen_list: Float64[2] = Float64[2](az, zen)
                if not is_cancel:
                    _results[i].process_analytical_simulation(_SF, 2 if _is_flux_detail else 0, azzen_list)  # 2);
                StatusLock.lock()
                is_cancel = this.CancelFlag
                StatusLock.unlock()
                if _is_flux_detail and (not is_cancel):
                    _results[i].process_flux(_SF, _is_flux_normalized)
                UpdateStatus(i - _sim_first + 1, nsim)
                StatusLock.lock()
                is_cancel = this.CancelFlag
                StatusLock.unlock()
                if is_cancel:
                    FinishedLock.lock()
                    Finished = True
                    FinishedLock.unlock()
                    return
            FinishedLock.lock()
            Finished = True
            FinishedLock.unlock()
        except spexception as e:
            # Handle exceptions within a thread by adding the exception to a list and returning normally
            StatusLock.lock()
            this.CancelFlag = True
            StatusLock.unlock()
            FinishedLock.lock()
            Finished = True
            FinishedLock.unlock()
            FinErrLock.lock()
            FinishedWithErrors = True
            FinErrLock.unlock()
            _sim_messages.push_back("Thread " + this._thread_id + ": " + e.what())
        except:
            # Handle exceptions within a thread by adding the exception to a list and returning normally
            StatusLock.lock()
            this.CancelFlag = True
            StatusLock.unlock()
            FinishedLock.lock()
            Finished = True
            FinishedLock.unlock()
            FinErrLock.lock()
            FinishedWithErrors = True
            FinErrLock.unlock()
            _sim_messages.push_back("Thread " + this._thread_id + ": " + "Caught unspecified error in a simulation thread. Simulation was not successful.")
        return