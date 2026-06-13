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
from lib_util import format
from math import sin, ceil, isnan

alias M_PI: Float32 = 3.14159265358979323846264338327

/**********************************************************************************
************************************************************************************
**
**	6 April 2015
**
**	Implementation of Bill Marion's snow model [1] to C++ for use in SAM
**	Original author: David Severin Ryberg
**
**
**********************************************************************************
**  References:
**  1: Marion, Bill, et al. "Measured and modeled photovoltaic system
**     energy losses from snow for Colorado and Wisconsin locations."
**     Solar Energy 97 (2013): 112-121.
**
**********************************************************************************
***********************************************************************************/
struct pvsnowmodel:
    var baseTilt: Float32
    var mSlope: Float32
    var sSlope: Float32
    var deltaThreshold: Float32
    var depthThreshold: Float32
    var previousDepth: Float32
    var coverage: Float32
    var pCvg: Float32
    var nmody: Int32
    var badValues: Int32
    var maxBadValues: Int32
    var msg: String
    var good: Bool

    def __init__(inout self):
        self.mSlope = -80
        self.sSlope = Float32(1.97)
        self.deltaThreshold = 1.00
        self.depthThreshold = 1.00
        self.previousDepth = 0
        self.badValues = 0
        self.maxBadValues = 500
        self.coverage = 0
        self.pCvg = 0
        self.good = True
        self.msg = ""

    def setup(inout self, nmody_in: Int32, baseTilt_in: Float32, limitTilt: Bool = True) -> Bool:
        self.nmody = nmody_in
        self.baseTilt = baseTilt_in
        if limitTilt and (self.baseTilt > 45 or self.baseTilt < 10):
            self.good = True
            self.msg = format("The snow model is designed to work for PV arrays with a tilt angle between 10 and 45 degrees, but will generate results for tilt angles outside this range. The system you are modeling includes a subarray tilt angle of %f degrees.", self.baseTilt)
            return False
        self.good = True
        return True

    def getLoss(inout self, poa: Float32, tilt: Float32, _: Float32, tdry: Float32, snowDepth: Float32, sunup: Int32, dt: Float32, inout returnLoss: Float32) -> Bool:
        var isGood: Bool = True
        if snowDepth < 0 or snowDepth > 610 or isnan(snowDepth):
            isGood = False
            snowDepth = 0
            self.badValues += 1
            if self.badValues == self.maxBadValues:
                self.good = False
                self.msg = format("The weather file contains no snow depth data or the data is not valid. Found (%d) bad snow depth values.", self.maxBadValues)
                return False
        if (snowDepth - self.previousDepth) >= self.deltaThreshold * dt and snowDepth >= self.depthThreshold:
            self.coverage = 1
        else:
            self.coverage = self.pCvg
        if snowDepth < self.depthThreshold:
            self.coverage = 0
        if sunup == 0:
            tilt = self.baseTilt
        if tdry - poa / self.mSlope > 0:
            self.coverage -= Float32(0.1 * self.sSlope * sin(tilt * M_PI / 180) * dt)
        if self.coverage < 0:
            self.coverage = 0
        returnLoss = 0
        if self.nmody > 0:
            returnLoss = Float32(ceil(self.coverage * self.nmody)) / self.nmody
        self.previousDepth = snowDepth
        self.pCvg = self.coverage
        if isGood:
            return True
        else:
            return False