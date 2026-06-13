/*******************************************************************************************************
*  Copyright 2017 Alliance for Sustainable Energy, LLC
*
*  NOTICE: This software was developed at least in part by Alliance for Sustainable Energy, LLC
*  (“Alliance”) under Contract No. DE-AC36-08GO28308 with the U.S. Department of Energy and the U.S.
*  The Government retains for itself and others acting on its behalf a nonexclusive, paid-up,
*  irrevocable worldwide license in the software to reproduce, prepare derivative works, distribute
*  copies to the public, perform publicly and display publicly, and to permit others to do so.
* 
*  Redistribution and use in source and binary forms, with or without modification, are permitted
*  provided that the following conditions are met:
* 
*  1. Redistributions of source code must retain the above copyright notice, the above government
*  rights notice, this list of conditions and the following disclaimer.
* 
*  2. Redistributions in binary form must reproduce the above copyright notice, the above government
*  rights notice, this list of conditions and the following disclaimer in the documentation and/or
*  other materials provided with the distribution.
* 
*  3. The entire corresponding source code of any redistribution, with or without modification, by a
*  research entity, including but not limited to any contracting manager/operator of a United States
*  National Laboratory, any institution of higher learning, and any non-profit organization, must be
*  made publicly available under this license for as long as the redistribution is made available by
*  the research entity.
* 
*  4. Redistribution of this software, without modification, must refer to the software by the same
*  designation. Redistribution of a modified version of this software (i) may not refer to the modified
*  version by the same designation, or by any confusingly similar designation, and (ii) must refer to
*  the underlying software originally provided by Alliance as “System Advisor Model” or “SAM”. Except
*  to comply with the foregoing, the terms “System Advisor Model”, “SAM”, or any confusingly similar
*  designation may not be used to refer to any modified version of this software or any modified
*  version of the underlying software originally provided by Alliance without the prior written consent
*  of Alliance.
* 
*  5. The name of the copyright holder, contributors, the United States Government, the United States
*  Department of Energy, or any of their employees may not be used to endorse or promote products
*  derived from this software without specific prior written permission.
* 
*  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
*  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
*  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER,
*  CONTRIBUTORS, UNITED STATES GOVERNMENT OR UNITED STATES DEPARTMENT OF ENERGY, NOR ANY OF THEIR
*  EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
*  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
*  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
*  IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
*  THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*******************************************************************************************************/
from STSimulateThread import STSimThread
from definitions import *
from exceptions import spexception
from stapi import st_context_t, st_uint_t, st_free_context, st_sim_run
from STSimulateThread import STCallback_MT
from STSimulateThread import SP_USE_SOLTRACE

alias st_context_t = Pointer[None]

@value
struct STSimThread:
    var Finished: Bool
    var CancelFlag: Bool
    var SaveStage0Data: Bool
    var LoadStage0Data: Bool
    var NToTrace: Int
    var NTraced: Int
    var NTraceTotal: Int
    var ResultCode: Int
    var SeedVal: Int
    var CurStage: Int
    var NStages: Int
    var ThreadNum: Int
    var ContextId: st_context_t
    var StatusLock: Pointer[None]
    var CancelLock: Pointer[None]
    var FinishedLock: Pointer[None]
    var raydata_st0: List[List[Float64]]
    var raydata_st1: List[List[Float64]]

    def __init__(inout self):
        self.Finished = False
        self.CancelFlag = False
        self.SaveStage0Data = False
        self.LoadStage0Data = False
        self.NToTrace = 0
        self.NTraced = 0
        self.NTraceTotal = 0
        self.ResultCode = -1
        self.SeedVal = 0
        self.CurStage = 0
        self.NStages = 0
        self.ThreadNum = 0
        self.ContextId = None
        self.StatusLock = None
        self.CancelLock = None
        self.FinishedLock = None
        self.raydata_st0 = List[List[Float64]]()
        self.raydata_st1 = List[List[Float64]]()

    def __del__(owned self):
        st_free_context(self.ContextId)

    def GetResultCode(self) -> Int:
        return self.ResultCode

    def GetContextId(self) -> st_context_t:
        return self.ContextId

    def Setup(inout self, spcxt: st_context_t, thd_num: Int, seed: Int, is_load_st0: Bool = False, is_save_st0: Bool = False):
        self.ThreadNum = thd_num
        self.CancelFlag = False
        self.Finished = False
        self.SeedVal = seed
        self.ContextId = spcxt
        self.LoadStage0Data = is_load_st0
        self.SaveStage0Data = is_save_st0
        self.ResultCode = -1
        self.NToTrace = 0
        self.NTraced = 0
        self.NTraceTotal = 0
        self.CurStage = 0
        self.NStages = 0

    def CopyStageRayData(inout self, src: List[List[Float64]], which_stage: Int, istart: Int, iend: Int):
        var which_raydat: Pointer[List[List[Float64]]]
        if which_stage == 0:
            which_raydat = Pointer.address_of(self.raydata_st0)
        else:
            which_raydat = Pointer.address_of(self.raydata_st1)
        which_raydat[].clear()
        try:
            which_raydat[].reserve(iend - istart)
        except e:
            var msg: String = String(e)
            msg += ": Error resizing raytrace data array"
            raise spexception(msg)

        for i in range(istart, iend):
            which_raydat[].append(src[i])

    def GetStage0RayDataObject(inout self) -> Pointer[List[List[Float64]]]:
        return Pointer.address_of(self.raydata_st0)

    def GetStage1RayDataObject(inout self) -> Pointer[List[List[Float64]]]:
        return Pointer.address_of(self.raydata_st1)

    def CancelTrace(inout self):
        self.CancelLock[].lock()
        self.CancelFlag = True
        self.CancelLock[].unlock()

    def IsTraceCancelled(self) -> Bool:
        var r: Bool
        self.CancelLock[].lock()
        r = self.CancelFlag
        self.CancelLock[].unlock()
        return r

    def IsFinished(self) -> Bool:
        var f: Bool
        self.FinishedLock[].lock()
        f = self.Finished
        self.FinishedLock[].unlock()
        return f

    def UpdateStatus(inout self, ntracedtotal: Int, ntraced: Int, ntotrace: Int, curstage: Int, nstages: Int):
        self.StatusLock[].lock()
        self.NTraceTotal = ntracedtotal
        self.NTraced = ntraced
        self.NToTrace = ntotrace
        self.CurStage = curstage
        self.NStages = nstages
        self.StatusLock[].unlock()

    def GetStatus(self, total: Pointer[Int], traced: Pointer[Int], ntotrace: Pointer[Int], stage: Pointer[Int], nstages: Pointer[Int]):
        self.StatusLock[].lock()
        total[] = self.NTraceTotal
        traced[] = self.NTraced
        ntotrace[] = self.NToTrace
        stage[] = self.CurStage
        nstages[] = self.NStages
        self.StatusLock[].unlock()

    def StartThread(inout self):
        self.ResultCode = st_sim_run(self.ContextId, UInt32(self.SeedVal), True, STCallback_MT, Pointer.address_of(self))
        self.FinishedLock[].lock()
        self.Finished = True
        self.FinishedLock[].unlock()

def STCallback_MT(ntracedtotal: st_uint_t, ntraced: st_uint_t, ntotrace: st_uint_t, curstage: st_uint_t, nstages: st_uint_t, data: Pointer[None]) -> Int:
    var t: Pointer[STSimThread] = Pointer[STSimThread](data)
    t[].UpdateStatus(Int(ntracedtotal), Int(ntraced), Int(ntotrace), Int(curstage), Int(nstages))
    return 0 if t[].IsTraceCancelled() else 1