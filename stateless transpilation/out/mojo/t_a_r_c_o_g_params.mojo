# EnergyPlus, Copyright (c) 1996-present, The Board of Trustees of the University of Illinois,
# The Regents of the University of California, through Lawrence Berkeley National Laboratory
# (subject to receipt of any required approvals from the U.S. Dept. of Energy), Oak Ridge
# National Laboratory, managed by UT-Battelle, Alliance for Energy Innovation, LLC, and other
# contributors. All rights reserved.
#
# NOTICE: This Software was developed under funding from the U.S. Department of Energy and the
# U.S. Government consequently retains certain rights. As such, the U.S. Government has been
# granted for itself and others acting on its behalf a paid-up, nonexclusive, irrevocable,
# worldwide license in the Software to reproduce, distribute copies to the public, prepare
# derivative works, and perform publicly and display publicly, and to permit others to do so.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted
# provided that the following conditions are met:
#
# (1) Redistributions of source code must retain the above copyright notice, this list of
#     conditions and the following disclaimer.
#
# (2) Redistributions in binary form must reproduce the above copyright notice, this list of
#     conditions and the following disclaimer in the documentation and/or other materials
#     provided with the distribution.
#
# (3) Neither the name of the University of California, Lawrence Berkeley National Laboratory,
#     the University of Illinois, U.S. Dept. of Energy nor the names of its contributors may be
#     used to endorse or promote products derived from this software without specific prior
#     written permission.
#
# (4) Use of EnergyPlus(TM) Name. If Licensee (i) distributes the software in stand-alone form
#     without changes from the version obtained under this License, or (ii) Licensee makes a
#     reference solely to the software portion of its product, Licensee must refer to the
#     software as "EnergyPlus version X" software, where "X" is the version number Licensee
#     obtained under this License and may not use a different name for the software. Except as
#     specifically required in this Section (4), Licensee shall not use in a company name, a
#     product name, in advertising, publicity, or other promotional activities any name, trade
#     name, trademark, logo, or other designation of "EnergyPlus", "E+", "e+" or confusingly
#     similar designation, without the U.S. Department of Energy's prior written consent.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

alias e = 2.718281828459
alias DeflectionRelaxation = 0.005
alias DeflectionMaxIterations = 400
alias DeflectionErrorMargin = 0.01

alias maxlay = 100
alias MaxGap = maxlay - 1
alias maxlay1 = maxlay + 1
alias maxlay2 = maxlay * 2
alias maxlay3 = maxlay2 + 1


struct TARCOGLayerType:
    alias Invalid = -1
    alias SPECULAR = 0
    alias VENETBLIND_HORIZ = 1
    alias WOVSHADE = 2
    alias PERFORATED = 3
    alias DIFFSHADE = 4
    alias BSDF = 5
    alias VENETBLIND_VERT = 6
    alias Num = 7


@always_inline
fn layerTypeNamesUC(index: Int) -> StringLiteral:
    if index == 0:
        return "SPECULAR"
    elif index == 1:
        return "VENETIANHORIZONTAL"
    elif index == 2:
        return "WOVEN"
    elif index == 3:
        return "PERFORATED"
    elif index == 4:
        return "OTHERSHADINGTYPE"
    elif index == 5:
        return "BSDF"
    else:
        return "VENETIANVERTICAL"


struct TARCOGThermalModel:
    alias Invalid = -1
    alias ISO15099 = 0
    alias SCW = 1
    alias CSM = 2
    alias CSM_WithSDThickness = 3
    alias Num = 4


@always_inline
fn thermalModelNamesUC(index: Int) -> StringLiteral:
    if index == 0:
        return "ISO15099"
    elif index == 1:
        return "SCALEDCAVITYWIDTH"
    elif index == 2:
        return "CONVECTIVESCALARMODEL_NOSDTHICKNESS"
    else:
        return "CONVECTIVESCALARMODEL_WITHSDTHICKNESS"


alias YES_SupportPillar = 1


struct DeflectionCalculation:
    alias Invalid = -1
    alias NONE = 0
    alias TEMPERATURE = 1
    alias GAP_WIDTHS = 2
    alias Num = 3


@always_inline
fn deflectionCalculationNamesUC(index: Int) -> StringLiteral:
    if index == 0:
        return "NODEFLECTION"
    elif index == 1:
        return "TEMPERATUREANDPRESSUREINPUT"
    else:
        return "MEASUREDDEFLECTION"


alias MMax = 5
alias NMax = 5

alias NumOfIterations = 100
alias NumOfTries = 5

alias RelaxationStart = 0.6
alias RelaxationDecrease = 0.1

alias ConvergenceTolerance = 1e-2

alias AirflowConvergenceTolerance = 1e-2
alias AirflowRelaxationParameter = 0.9

alias TemperatureQuessDiff = 1.0

alias C1_VENET_HORIZONTAL = 0.016
alias C2_VENET_HORIZONTAL = -0.63
alias C3_VENET_HORIZONTAL = 0.53
alias C4_VENET_HORIZONTAL = 0.043

alias C1_VENET_VERTICAL = 0.041
alias C2_VENET_VERTICAL = 0.0
alias C3_VENET_VERTICAL = 0.270
alias C4_VENET_VERTICAL = 0.012

alias C1_SHADE = 0.078
alias C2_SHADE = 1.2
alias C3_SHADE = 1.0
alias C4_SHADE = 1.0
