# EXTERNAL DEPS (to wire in glue):
# EnergyPlusData: state object containing data modules
# Node.GetOnlySingleNode: from EnergyPlus.NodeInputManager
# DataZoneEquipment.AirLoopHVACZone: enum from EnergyPlus.DataZoneEquipment
# DataZoneEquipment.AirLoopHVACTypeNamesCC: lookup from EnergyPlus.DataZoneEquipment
# Node enums: ConnectionObjectType, FluidType, ConnectionType, CompFluidStream, ObjectIsParent
# Util functions: SameString, ValidateComponent, ShowContinueError, ShowSevereError, ShowFatalError
# getEnumValue: from EnergyPlus.GeneralRoutines
# MixerComponent.SimAirMixer: from EnergyPlus.MixerComponent
# ZonePlenum.SimAirZonePlenum: from EnergyPlus.ZonePlenum
# DuctLoss.SimulateDuctLoss, DuctLoss.AirPath: from EnergyPlus.DuctLoss
# nint: round-half-away-from-zero function

from typing import Any, List, Optional

def nint(x: float) -> int:
    """Round to nearest integer, half away from zero"""
    if x >= 0.0:
        return int(x + 0.5)
    else:
        return int(x - 0.5)

def SimReturnAirPath(state: Any) -> None:
    """Simulate return air path"""
    if state.dataRetAirPathMrg.GetInputFlag:
        GetReturnAirPathInput(state)
        state.dataRetAirPathMrg.GetInputFlag = False
    
    for ReturnAirPathNum in range(state.dataZoneEquip.NumReturnAirPaths):
        CalcReturnAirPath(state, ReturnAirPathNum)

def GetReturnAirPathInput(state: Any) -> None:
    """Get return air path input"""
    from EnergyPlus.NodeInputManager import GetOnlySingleNode
    from EnergyPlus.DataLoopNode import ConnectionObjectType, FluidType, ConnectionType, CompFluidStream, ObjectIsParent
    from EnergyPlus.DataZoneEquipment import AirLoopHVACZone, AirLoopHVACTypeNamesCC
    from EnergyPlus.UtilityRoutines import SameString, ValidateComponent, ShowContinueError, ShowSevereError, ShowFatalError
    from EnergyPlus.GeneralRoutines import getEnumValue
    
    ErrorsFound = False
    
    if state.dataZoneEquip.ReturnAirPath is not None:
        return
    
    cCurrentModuleObject = "AirLoopHVAC:ReturnPath"
    state.dataIPShortCut.cCurrentModuleObject = cCurrentModuleObject
    state.dataZoneEquip.NumReturnAirPaths = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, cCurrentModuleObject
    )
    
    if state.dataZoneEquip.NumReturnAirPaths > 0:
        state.dataZoneEquip.ReturnAirPath = [None] * state.dataZoneEquip.NumReturnAirPaths
        
        for PathNum in range(state.dataZoneEquip.NumReturnAirPaths):
            NumAlphas = 0
            NumNums = 0
            IOStat = 0
            
            state.dataInputProcessing.inputProcessor.getObjectItem(
                state,
                cCurrentModuleObject,
                PathNum,
                state.dataIPShortCut.cAlphaArgs,
                NumAlphas,
                state.dataIPShortCut.rNumericArgs,
                NumNums,
                IOStat
            )
            
            state.dataZoneEquip.ReturnAirPath[PathNum] = ReturnAirPathData()
            state.dataZoneEquip.ReturnAirPath[PathNum].Name = state.dataIPShortCut.cAlphaArgs[0]
            state.dataZoneEquip.ReturnAirPath[PathNum].NumOfComponents = nint((NumAlphas - 2.0) / 2.0)
            
            state.dataZoneEquip.ReturnAirPath[PathNum].OutletNodeNum = GetOnlySingleNode(
                state,
                state.dataIPShortCut.cAlphaArgs[1],
                ErrorsFound,
                ConnectionObjectType.AirLoopHVACReturnPath,
                state.dataIPShortCut.cAlphaArgs[0],
                FluidType.Air,
                ConnectionType.Outlet,
                CompFluidStream.Primary,
                ObjectIsParent
            )
            
            num_comps = state.dataZoneEquip.ReturnAirPath[PathNum].NumOfComponents
            state.dataZoneEquip.ReturnAirPath[PathNum].ComponentType = [""] * num_comps
            state.dataZoneEquip.ReturnAirPath[PathNum].ComponentTypeEnum = [AirLoopHVACZone.Invalid] * num_comps
            state.dataZoneEquip.ReturnAirPath[PathNum].ComponentName = [""] * num_comps
            state.dataZoneEquip.ReturnAirPath[PathNum].ComponentIndex = [0] * num_comps
            
            Counter = 2
            
            for CompNum in range(num_comps):
                if (SameString(state.dataIPShortCut.cAlphaArgs[Counter], "AirLoopHVAC:ZoneMixer") or
                    SameString(state.dataIPShortCut.cAlphaArgs[Counter], "AirLoopHVAC:ReturnPlenum")):
                    
                    IsNotOK = False
                    state.dataZoneEquip.ReturnAirPath[PathNum].ComponentType[CompNum] = state.dataIPShortCut.cAlphaArgs[Counter]
                    state.dataZoneEquip.ReturnAirPath[PathNum].ComponentName[CompNum] = state.dataIPShortCut.cAlphaArgs[Counter + 1]
                    
                    ValidateComponent(
                        state,
                        state.dataZoneEquip.ReturnAirPath[PathNum].ComponentType[CompNum],
                        state.dataZoneEquip.ReturnAirPath[PathNum].ComponentName[CompNum],
                        IsNotOK,
                        "AirLoopHVAC:ReturnPath"
                    )
                    
                    if IsNotOK:
                        ShowContinueError(state, f"In AirLoopHVAC:ReturnPath ={state.dataZoneEquip.ReturnAirPath[PathNum].Name}")
                        ErrorsFound = True
                    
                    state.dataZoneEquip.ReturnAirPath[PathNum].ComponentTypeEnum[CompNum] = getEnumValue(
                        AirLoopHVACTypeNamesCC,
                        state.dataIPShortCut.cAlphaArgs[Counter]
                    )
                
                else:
                    ShowSevereError(state, f"Unhandled component type in AirLoopHVAC:ReturnPath of {state.dataIPShortCut.cAlphaArgs[Counter]}")
                    ShowContinueError(state, f"Occurs in AirLoopHVAC:ReturnPath = {state.dataZoneEquip.ReturnAirPath[PathNum].Name}")
                    ShowContinueError(state, "Must be \"AirLoopHVAC:ZoneMixer\" or \"AirLoopHVAC:ReturnPlenum\"")
                    ErrorsFound = True
                
                Counter += 2
    
    if ErrorsFound:
        ShowFatalError(state, "Errors found getting AirLoopHVAC:ReturnPath.  Preceding condition(s) causes termination.")

def CalcReturnAirPath(state: Any, ReturnAirPathNum: int) -> None:
    """Calculate return air path"""
    from EnergyPlus.DataZoneEquipment import AirLoopHVACZone
    from EnergyPlus.MixerComponent import SimAirMixer
    from EnergyPlus.ZonePlenum import SimAirZonePlenum
    from EnergyPlus.DuctLoss import SimulateDuctLoss, AirPath
    from EnergyPlus.UtilityRoutines import ShowSevereError, ShowFatalError, ShowContinueError
    
    for ComponentNum in range(state.dataZoneEquip.ReturnAirPath[ReturnAirPathNum].NumOfComponents):
        component_type_enum = state.dataZoneEquip.ReturnAirPath[ReturnAirPathNum].ComponentTypeEnum[ComponentNum]
        
        if component_type_enum == AirLoopHVACZone.Mixer:
            if not (state.afn.AirflowNetworkFanActivated and state.afn.distribution_simulated):
                SimAirMixer(
                    state,
                    state.dataZoneEquip.ReturnAirPath[ReturnAirPathNum].ComponentName[ComponentNum],
                    state.dataZoneEquip.ReturnAirPath[ReturnAirPathNum].ComponentIndex[ComponentNum]
                )
                if state.dataDuctLoss.DuctLossSimu:
                    SimulateDuctLoss(
                        state,
                        AirPath.Return,
                        state.dataZoneEquip.ReturnAirPath[ReturnAirPathNum].ComponentIndex[ComponentNum]
                    )
        
        elif component_type_enum == AirLoopHVACZone.ReturnPlenum:
            SimAirZonePlenum(
                state,
                state.dataZoneEquip.ReturnAirPath[ReturnAirPathNum].ComponentName[ComponentNum],
                AirLoopHVACZone.ReturnPlenum,
                state.dataZoneEquip.ReturnAirPath[ReturnAirPathNum].ComponentIndex[ComponentNum]
            )
        
        else:
            ShowSevereError(state, f"Invalid AirLoopHVAC:ReturnPath Component={state.dataZoneEquip.ReturnAirPath[ReturnAirPathNum].ComponentType[ComponentNum]}")
            ShowContinueError(state, f"Occurs in AirLoopHVAC:ReturnPath ={state.dataZoneEquip.ReturnAirPath[ReturnAirPathNum].Name}")
            ShowFatalError(state, "Preceding condition causes termination.")

def ReportReturnAirPath(ReturnAirPathNum: int) -> None:
    """Report return air path"""
    pass

class ReturnAirPathData:
    """Data structure for return air path"""
    def __init__(self):
        self.Name = ""
        self.NumOfComponents = 0
        self.OutletNodeNum = 0
        self.ComponentType: List[str] = []
        self.ComponentTypeEnum: List[int] = []
        self.ComponentName: List[str] = []
        self.ComponentIndex: List[int] = []

class ReturnAirPathMgr:
    """Manager for return air path state"""
    def __init__(self):
        self.GetInputFlag = True
    
    def init_constant_state(self, state: Any) -> None:
        pass
    
    def init_state(self, state: Any) -> None:
        pass
    
    def clear_state(self) -> None:
        self.GetInputFlag = True
