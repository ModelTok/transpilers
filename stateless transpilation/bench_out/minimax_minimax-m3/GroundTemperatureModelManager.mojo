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
# - BaseGroundTempsModel: struct from EnergyPlus.GroundTemperatureModeling.BaseGroundTemperatureModel
#   - fields: modelType: ModelType, Name: String
# - ModelType: enum from EnergyPlus.GroundTemperatureModeling.GroundTemperatureModelManager
#   - values: Kusuda, FiniteDiff, SiteBuildingSurface, SiteShallow, SiteDeep, SiteFCFactorMethod, Xing
# - KusudaGroundTempsModel.KusudaGTMFactory: from EnergyPlus.GroundTemperatureModeling.KusudaAchenbachGroundTemperatureModel
# - FiniteDiffGroundTempsModel.FiniteDiffGTMFactory: from EnergyPlus.GroundTemperatureModeling.FiniteDifferenceGroundTemperatureModel
# - SiteBuildingSurfaceGroundTemps.BuildingSurfaceGTMFactory: from EnergyPlus.GroundTemperatureModeling.SiteBuildingSurfaceGroundTemperatures
# - SiteShallowGroundTemps.ShallowGTMFactory: from EnergyPlus.GroundTemperatureModeling.SiteShallowGroundTemperatures
# - SiteDeepGroundTemps.DeepGTMFactory: from EnergyPlus.GroundTemperatureModeling.SiteDeepGroundTemperatures
# - SiteFCFactorMethodGroundTemps.FCFactorGTMFactory: from EnergyPlus.GroundTemperatureModeling.SiteFCFactorMethodGroundTemperatures
# - XingGroundTempsModel.XingGTMFactory: from EnergyPlus.GroundTemperatureModeling.XingGroundTemperatureModel
# - EnergyPlusData: struct from EnergyPlus.Data.EnergyPlusData
#   - state.dataGrndTempModelMgr.groundTempModels: List[BaseGroundTempsModel]

from utils import Optional
from collections import List


# --- Stub definitions (to be replaced by wired-in real types) ---

enum ModelType:
    Kusuda
    FiniteDiff
    SiteBuildingSurface
    SiteShallow
    SiteDeep
    SiteFCFactorMethod
    Xing


struct BaseGroundTempsModel:
    var modelType: ModelType
    var Name: String


struct _GrndTempModelMgr:
    var groundTempModels: List[BaseGroundTempsModel]


struct EnergyPlusData:
    var dataGrndTempModelMgr: _GrndTempModelMgr


# --- Factory stubs (real implementations come from external modules) ---

struct KusudaGroundTempsModel:
    @staticmethod
    fn KusudaGTMFactory(state: EnergyPlusData, name: String) raises -> Optional[BaseGroundTempsModel]:
        raise "wire in real factory"


struct FiniteDiffGroundTempsModel:
    @staticmethod
    fn FiniteDiffGTMFactory(state: EnergyPlusData, name: String) raises -> Optional[BaseGroundTempsModel]:
        raise "wire in real factory"


struct SiteBuildingSurfaceGroundTemps:
    @staticmethod
    fn BuildingSurfaceGTMFactory(state: EnergyPlusData, name: String) raises -> Optional[BaseGroundTempsModel]:
        raise "wire in real factory"


struct SiteShallowGroundTemps:
    @staticmethod
    fn ShallowGTMFactory(state: EnergyPlusData, name: String) raises -> Optional[BaseGroundTempsModel]:
        raise "wire in real factory"


struct SiteDeepGroundTemps:
    @staticmethod
    fn DeepGTMFactory(state: EnergyPlusData, name: String) raises -> Optional[BaseGroundTempsModel]:
        raise "wire in real factory"


struct SiteFCFactorMethodGroundTemps:
    @staticmethod
    fn FCFactorGTMFactory(state: EnergyPlusData, name: String) raises -> Optional[BaseGroundTempsModel]:
        raise "wire in real factory"


struct XingGroundTempsModel:
    @staticmethod
    fn XingGTMFactory(state: EnergyPlusData, name: String) raises -> Optional[BaseGroundTempsModel]:
        raise "wire in real factory"


# --- Translated function ---

fn GetGroundTempModelAndInit(state: EnergyPlusData, modelType: ModelType, name: String) raises -> Optional[BaseGroundTempsModel]:
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
        assert(False, "unhandled ModelType")
        return Optional[BaseGroundTempsModel]()
