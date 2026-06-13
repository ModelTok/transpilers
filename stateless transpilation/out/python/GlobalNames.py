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

from typing import Dict, Set, Optional

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: main state object (from EnergyPlus.Data.EnergyPlusData)
# - BaseGlobalStruct: base class for global data structs (from EnergyPlus.Data.BaseData)
# - ShowSevereError(state: EnergyPlusData, msg: str) -> None (from EnergyPlus.UtilityRoutines)
# - ShowContinueError(state: EnergyPlusData, msg: str) -> None (from EnergyPlus.UtilityRoutines)
# - Util.makeUPPER(s: str) -> str (from EnergyPlus.UtilityRoutines)

class ComponentNameData:
    def __init__(self):
        self.CompType: str = ""
        self.CompName: str = ""

class GlobalNamesData:
    def __init__(self):
        self.NumChillers: int = 0
        self.NumBoilers: int = 0
        self.NumBaseboards: int = 0
        self.NumCoils: int = 0
        self.CurMaxChillers: int = 0
        self.CurMaxCoils: int = 0
        self.numAirDistUnits: int = 0
        self.ChillerNames: Dict[str, str] = {}
        self.BoilerNames: Dict[str, str] = {}
        self.BaseboardNames: Dict[str, str] = {}
        self.CoilNames: Dict[str, str] = {}
        self.aDUNames: Dict[str, str] = {}
    
    def init_constant_state(self, state) -> None:
        pass
    
    def init_state(self, state) -> None:
        pass
    
    def clear_state(self) -> None:
        self.NumChillers = 0
        self.NumBoilers = 0
        self.NumBaseboards = 0
        self.NumCoils = 0
        self.CurMaxChillers = 0
        self.CurMaxCoils = 0
        self.numAirDistUnits = 0
        self.ChillerNames.clear()
        self.BoilerNames.clear()
        self.BaseboardNames.clear()
        self.CoilNames.clear()
        self.aDUNames.clear()

def IntraObjUniquenessCheck(state, NameToVerify: str, CurrentModuleObject: str,
                           FieldName: str, UniqueStrings: Set[str], ErrorsFound: list) -> None:
    if not NameToVerify:
        ShowSevereError(state, f"E+ object type {CurrentModuleObject} cannot have a blank {FieldName} field")
        ErrorsFound[0] = True
        return
    
    if NameToVerify not in UniqueStrings:
        UniqueStrings.add(NameToVerify)
    else:
        ErrorsFound[0] = True
        ShowSevereError(state, f"{CurrentModuleObject} has a duplicate field {NameToVerify}")

def VerifyUniqueInterObjectName(state, names: Dict[str, str], object_name: str,
                               object_type, ErrorsFound: list,
                               field_name: Optional[str] = None) -> bool:
    if not object_name:
        if field_name is not None:
            ShowSevereError(state, f"E+ object type {object_name} cannot have blank {field_name} field")
        else:
            ShowSevereError(state, f"E+ object type {object_name} has a blank field")
        ErrorsFound[0] = True
        return True
    
    if object_name in names:
        ErrorsFound[0] = True
        ShowSevereError(state, f"{object_name} with object type {object_type} duplicates a name in object type {names[object_name]}")
        return True
    else:
        names[object_name] = object_type
    
    return False

def VerifyUniqueChillerName(state, TypeToVerify: str, NameToVerify: str,
                           ErrorsFound: list, StringToDisplay: str) -> None:
    iter_result = state.dataGlobalNames.ChillerNames.get(NameToVerify)
    if iter_result is not None:
        ShowSevereError(state, f"{StringToDisplay}, duplicate name={NameToVerify}, Chiller Type=\"{iter_result}\".")
        ShowContinueError(state, f"...Current entry is Chiller Type=\"{TypeToVerify}\".")
        ErrorsFound[0] = True
    else:
        state.dataGlobalNames.ChillerNames[NameToVerify] = Util.makeUPPER(TypeToVerify)
        state.dataGlobalNames.NumChillers = len(state.dataGlobalNames.ChillerNames)

def VerifyUniqueBaseboardName(state, TypeToVerify: str, NameToVerify: str,
                             ErrorsFound: list, StringToDisplay: str) -> None:
    iter_result = state.dataGlobalNames.BaseboardNames.get(NameToVerify)
    if iter_result is not None:
        ShowSevereError(state, f"{StringToDisplay}, duplicate name={NameToVerify}, Baseboard Type=\"{iter_result}\".")
        ShowContinueError(state, f"...Current entry is Baseboard Type=\"{TypeToVerify}\".")
        ErrorsFound[0] = True
    else:
        state.dataGlobalNames.BaseboardNames[NameToVerify] = Util.makeUPPER(TypeToVerify)
        state.dataGlobalNames.NumBaseboards = len(state.dataGlobalNames.BaseboardNames)

def VerifyUniqueBoilerName(state, TypeToVerify: str, NameToVerify: str,
                          ErrorsFound: list, StringToDisplay: str) -> None:
    iter_result = state.dataGlobalNames.BoilerNames.get(NameToVerify)
    if iter_result is not None:
        ShowSevereError(state, f"{StringToDisplay}, duplicate name={NameToVerify}, Boiler Type=\"{iter_result}\".")
        ShowContinueError(state, f"...Current entry is Boiler Type=\"{TypeToVerify}\".")
        ErrorsFound[0] = True
    else:
        state.dataGlobalNames.BoilerNames[NameToVerify] = Util.makeUPPER(TypeToVerify)
        state.dataGlobalNames.NumBoilers = len(state.dataGlobalNames.BoilerNames)

def VerifyUniqueCoilName(state, TypeToVerify: str, NameToVerify: str,
                        ErrorsFound: list, StringToDisplay: str) -> None:
    if not NameToVerify:
        ShowSevereError(state, f"\"{TypeToVerify}\" cannot have a blank field")
        ErrorsFound[0] = True
        NameToVerify = "xxxxx"
        return
    
    iter_result = state.dataGlobalNames.CoilNames.get(NameToVerify)
    if iter_result is not None:
        ShowSevereError(state, f"{StringToDisplay}, duplicate name={NameToVerify}, Coil Type=\"{iter_result}\".")
        ShowContinueError(state, f"...Current entry is Coil Type=\"{TypeToVerify}\".")
        ErrorsFound[0] = True
    else:
        state.dataGlobalNames.CoilNames[NameToVerify] = Util.makeUPPER(TypeToVerify)
        state.dataGlobalNames.NumCoils = len(state.dataGlobalNames.CoilNames)

def VerifyUniqueADUName(state, TypeToVerify: str, NameToVerify: str,
                       ErrorsFound: list, StringToDisplay: str) -> None:
    iter_result = state.dataGlobalNames.aDUNames.get(NameToVerify)
    if iter_result is not None:
        ShowSevereError(state, f"{StringToDisplay}, duplicate name={NameToVerify}, ADU Type=\"{iter_result}\".")
        ShowContinueError(state, f"...Current entry is Air Distribution Unit Type=\"{TypeToVerify}\".")
        ErrorsFound[0] = True
    else:
        state.dataGlobalNames.aDUNames[NameToVerify] = Util.makeUPPER(TypeToVerify)
        state.dataGlobalNames.numAirDistUnits = len(state.dataGlobalNames.aDUNames)
