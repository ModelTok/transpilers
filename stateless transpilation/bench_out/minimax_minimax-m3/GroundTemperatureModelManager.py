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

# EXTERNAL DEPS (to wire in glue):
# - BaseGroundTempsModel: class from EnergyPlus.GroundTemperatureModeling.BaseGroundTemperatureModel
#   - fields: modelType: ModelType, Name: str
# - ModelType: enum from EnergyPlus.GroundTemperatureModeling.GroundTemperatureModelManager
#   - values: Kusuda, FiniteDiff, SiteBuildingSurface, SiteShallow, SiteDeep, SiteFCFactorMethod, Xing
# - KusudaGroundTempsModel.KusudaGTMFactory(state, name) -> BaseGroundTempsModel
#   from EnergyPlus.GroundTemperatureModeling.KusudaAchenbachGroundTemperatureModel
# - FiniteDiffGroundTempsModel.FiniteDiffGTMFactory(state, name) -> BaseGroundTempsModel
#   from EnergyPlus.GroundTemperatureModeling.FiniteDifferenceGroundTemperatureModel
# - SiteBuildingSurfaceGroundTemps.BuildingSurfaceGTMFactory(state, name) -> BaseGroundTempsModel
#   from EnergyPlus.GroundTemperatureModeling.SiteBuildingSurfaceGroundTemperatures
# - SiteShallowGroundTemps.ShallowGTMFactory(state, name) -> BaseGroundTempsModel
#   from EnergyPlus.GroundTemperatureModeling.SiteShallowGroundTemperatures
# - SiteDeepGroundTemps.DeepGTMFactory(state, name) -> BaseGroundTempsModel
#   from EnergyPlus.GroundTemperatureModeling.SiteDeepGroundTemperatures
# - SiteFCFactorMethodGroundTemps.FCFactorGTMFactory(state, name) -> BaseGroundTempsModel
#   from EnergyPlus.GroundTemperatureModeling.SiteFCFactorMethodGroundTemperatures
# - XingGroundTempsModel.XingGTMFactory(state, name) -> BaseGroundTempsModel
#   from EnergyPlus.GroundTemperatureModeling.XingGroundTemperatureModel
# - EnergyPlusData: class from EnergyPlus.Data.EnergyPlusData
#   - state.dataGrndTempModelMgr.groundTempModels: List[BaseGroundTempsModel]

from enum import Enum, auto
from typing import List, Optional, Protocol


# --- Stub definitions (to be replaced by wired-in real types) ---

class ModelType(Enum):
    Kusuda = auto()
    FiniteDiff = auto()
    SiteBuildingSurface = auto()
    SiteShallow = auto()
    SiteDeep = auto()
    SiteFCFactorMethod = auto()
    Xing = auto()


class _BaseGroundTempsModelT(Protocol):
    modelType: ModelType
    Name: str


class _GrndTempModelMgrT(Protocol):
    groundTempModels: List[_BaseGroundTempsModelT]


class EnergyPlusData(Protocol):
    dataGrndTempModelMgr: _GrndTempModelMgrT


# --- Factory stubs (real implementations come from external modules) ---

class KusudaGroundTempsModel:
    @staticmethod
    def KusudaGTMFactory(state: EnergyPlusData, name: str) -> _BaseGroundTempsModelT:
        raise NotImplementedError("wire in real factory")


class FiniteDiffGroundTempsModel:
    @staticmethod
    def FiniteDiffGTMFactory(state: EnergyPlusData, name: str) -> _BaseGroundTempsModelT:
        raise NotImplementedError("wire in real factory")


class SiteBuildingSurfaceGroundTemps:
    @staticmethod
    def BuildingSurfaceGTMFactory(state: EnergyPlusData, name: str) -> _BaseGroundTempsModelT:
        raise NotImplementedError("wire in real factory")


class SiteShallowGroundTemps:
    @staticmethod
    def ShallowGTMFactory(state: EnergyPlusData, name: str) -> _BaseGroundTempsModelT:
        raise NotImplementedError("wire in real factory")


class SiteDeepGroundTemps:
    @staticmethod
    def DeepGTMFactory(state: EnergyPlusData, name: str) -> _BaseGroundTempsModelT:
        raise NotImplementedError("wire in real factory")


class SiteFCFactorMethodGroundTemps:
    @staticmethod
    def FCFactorGTMFactory(state: EnergyPlusData, name: str) -> _BaseGroundTempsModelT:
        raise NotImplementedError("wire in real factory")


class XingGroundTempsModel:
    @staticmethod
    def XingGTMFactory(state: EnergyPlusData, name: str) -> _BaseGroundTempsModelT:
        raise NotImplementedError("wire in real factory")


# --- Translated function ---

def GetGroundTempModelAndInit(state: EnergyPlusData, modelType: ModelType, name: str) -> Optional[_BaseGroundTempsModelT]:
    # SUBROUTINE INFORMATION:
    #       AUTHOR         Matt Mitchell
    #       DATE WRITTEN   Summer 2015

    # PURPOSE OF THIS SUBROUTINE:
    # Called by objects requiring ground temperature models. Determines type and calls appropriate factory method.

    # Check if this instance of this model has already been retrieved
    for gtm in state.dataGrndTempModelMgr.groundTempModels:
        # Check if the type and name match
        if modelType == gtm.modelType and name == gtm.Name:
            return gtm

    # If not found, create new instance of the model
    if modelType == ModelType.Kusuda:
        return KusudaGroundTempsModel.KusudaGTMFactory(state, name)
    elif modelType == ModelType.FiniteDiff:
        return FiniteDiffGroundTempsModel.FiniteDiffGTMFactory(state, name)
    elif modelType == ModelType.SiteBuildingSurface:
        return SiteBuildingSurfaceGroundTemps.BuildingSurfaceGTMFactory(state, name)
    elif modelType == ModelType.SiteShallow:
        return SiteShallowGroundTemps.ShallowGTMFactory(state, name)
    elif modelType == ModelType.SiteDeep:
        return SiteDeepGroundTemps.DeepGTMFactory(state, name)
    elif modelType == ModelType.SiteFCFactorMethod:
        return SiteFCFactorMethodGroundTemps.FCFactorGTMFactory(state, name)
    elif modelType == ModelType.Xing:
        return XingGroundTempsModel.XingGTMFactory(state, name)
    else:
        assert False
        return None
