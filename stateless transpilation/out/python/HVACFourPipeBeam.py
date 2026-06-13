# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData (state): main simulation state object
# - AirTerminalUnit: parent class with inherited members (name, unitType, airAvailSched, airLoopNum, zoneIndex, zoneNodeIndex, ctrlZoneInNodeIndex, aDUNum, airInNodeNum, airOutNodeNum, vDotDesignPrimAir, vDotDesignPrimAirWasAutosized, termUnitSizingNum)
# - Schedule type and Sched module (GetScheduleAlwaysOn, GetSchedule, getCurrentVal)
# - PlantLocation type
# - Node module (GetOnlySingleNode, ObjectIsNotParent, ObjectIsParent, TestCompSet, ConnectionObjectType, FluidType, ConnectionType, CompFluidStream)
# - Curve module (GetCurveIndex, CurveValue)
# - DataZoneEquipment module (CheckZoneEquipmentList)
# - PlantUtilities module (InitComponentNodes, ScanPlantLoopsForObject, SetComponentFlowRate, RegisterPlantCompDesignFlow, MyPlantSizingIndex)
# - DataPlant module (PlantEquipmentType, LoopSideLocation)
# - Psychrometrics module (PsyCpAirFnW)
# - General module (SolveRoot)
# - OutputProcessor, BaseSizer modules
# - Various data modules and functions from EnergyPlus

from __future__ import annotations
from typing import Optional, Callable, Any
from dataclasses import dataclass, field
import math

class HVACFourPipeBeam:
    """Four pipe cooled/heated beam air terminal unit."""
    
    def __init__(self):
        """Default constructor with full initialization."""
        self.coolingAvailSched: Optional[Any] = None
        self.coolingAvailable: bool = False
        self.heatingAvailSched: Optional[Any] = None
        self.heatingAvailable: bool = False
        
        self.totBeamLength: float = 0.0
        self.totBeamLengthWasAutosized: bool = False
        self.vDotNormRatedPrimAir: float = 0.0
        self.mDotNormRatedPrimAir: float = 0.0
        
        self.beamCoolingPresent: bool = False
        self.vDotDesignCW: float = 0.0
        self.vDotDesignCWWasAutosized: bool = False
        self.mDotDesignCW: float = 0.0
        self.qDotNormRatedCooling: float = 0.0
        self.deltaTempRatedCooling: float = 0.0
        self.vDotNormRatedCW: float = 0.0
        self.mDotNormRatedCW: float = 0.0
        self.modCoolingQdotDeltaTFuncNum: int = 0
        self.modCoolingQdotAirFlowFuncNum: int = 0
        self.modCoolingQdotCWFlowFuncNum: int = 0
        self.mDotCW: float = 0.0
        self.cWTempIn: float = 0.0
        self.cWTempOut: float = 0.0
        self.cWTempOutErrorCount: int = 0
        self.cWInNodeNum: int = 0
        self.cWOutNodeNum: int = 0
        self.cWplantLoc: Optional[Any] = None
        
        self.beamHeatingPresent: bool = False
        self.vDotDesignHW: float = 0.0
        self.vDotDesignHWWasAutosized: bool = False
        self.mDotDesignHW: float = 0.0
        self.qDotNormRatedHeating: float = 0.0
        self.deltaTempRatedHeating: float = 0.0
        self.vDotNormRatedHW: float = 0.0
        self.mDotNormRatedHW: float = 0.0
        self.modHeatingQdotDeltaTFuncNum: int = 0
        self.modHeatingQdotAirFlowFuncNum: int = 0
        self.modHeatingQdotHWFlowFuncNum: int = 0
        self.mDotHW: float = 0.0
        self.hWTempIn: float = 0.0
        self.hWTempOut: float = 0.0
        self.hWTempOutErrorCount: int = 0
        self.hWInNodeNum: int = 0
        self.hWOutNodeNum: int = 0
        self.hWplantLoc: Optional[Any] = None
        
        self.beamCoolingEnergy: float = 0.0
        self.beamCoolingRate: float = 0.0
        self.beamHeatingEnergy: float = 0.0
        self.beamHeatingRate: float = 0.0
        self.supAirCoolingEnergy: float = 0.0
        self.supAirCoolingRate: float = 0.0
        self.supAirHeatingEnergy: float = 0.0
        self.supAirHeatingRate: float = 0.0
        self.primAirFlow: float = 0.0
        self.OutdoorAirFlowRate: float = 0.0
        
        self.myEnvrnFlag: bool = True
        self.mySizeFlag: bool = True
        self.plantLoopScanFlag: bool = True
        self.zoneEquipmentListChecked: bool = False
        
        self.tDBZoneAirTemp: float = 0.0
        self.tDBSystemAir: float = 0.0
        self.mDotSystemAir: float = 0.0
        self.cpZoneAir: float = 0.0
        self.cpSystemAir: float = 0.0
        self.qDotSystemAir: float = 0.0
        self.qDotBeamCoolingMax: float = 0.0
        self.qDotBeamHeatingMax: float = 0.0
        self.qDotTotalDelivered: float = 0.0
        self.qDotBeamCooling: float = 0.0
        self.qDotBeamHeating: float = 0.0
        self.qDotZoneReq: float = 0.0
        self.qDotBeamReq: float = 0.0
        self.qDotZoneToHeatSetPt: float = 0.0
        self.qDotZoneToCoolSetPt: float = 0.0
        
        # Inherited from AirTerminalUnit
        self.name: str = ""
        self.unitType: str = ""
        self.airAvailSched: Optional[Any] = None
        self.airLoopNum: int = 0
        self.zoneIndex: int = 0
        self.zoneNodeIndex: int = 0
        self.ctrlZoneInNodeIndex: int = 0
        self.aDUNum: int = 0
        self.airInNodeNum: int = 0
        self.airOutNodeNum: int = 0
        self.vDotDesignPrimAir: float = 0.0
        self.vDotDesignPrimAirWasAutosized: bool = False
        self.termUnitSizingNum: int = 0
        self.airAvailable: bool = False

    def __del__(self):
        """Destructor."""
        pass

    @staticmethod
    def fourPipeBeamFactory(state: Any, objectName: str) -> Optional['HVACFourPipeBeam']:
        """Factory function to create and initialize a four pipe beam unit."""
        from EnergyPlus import (
            Sched, Node, Curve, GlobalNames, BranchNodeConnections,
            OutputProcessor, InputProcessing, DataZoneEquipment,
            PlantUtilities, DataPlant
        )
        
        routineName = "FourPipeBeamFactory "
        beamIndex = 0
        errFlag = False
        ErrorsFound = False
        found = False
        airNodeFound = False
        aDUIndex = 0
        
        thisBeam = HVACFourPipeBeam()
        cCurrentModuleObject = "AirTerminal:SingleDuct:ConstantVolume:FourPipeBeam"
        
        beamIndex = state.dataInputProcessing.inputProcessor.getObjectItemNum(
            state, cCurrentModuleObject, objectName
        )
        if beamIndex > 0:
            NumAlphas = 16
            NumNumbers = 11
            IOStatus = 0
            state.dataInputProcessing.inputProcessor.getObjectItem(
                state, cCurrentModuleObject, beamIndex,
                state.dataIPShortCut.cAlphaArgs, NumAlphas,
                state.dataIPShortCut.rNumericArgs, NumNumbers, IOStatus,
                state.dataIPShortCut.lNumericFieldBlanks,
                state.dataIPShortCut.lAlphaFieldBlanks,
                state.dataIPShortCut.cAlphaFieldNames,
                state.dataIPShortCut.cNumericFieldNames
            )
            found = True
        else:
            ErrorsFound = True
        
        eoh = (routineName, cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs[0])
        
        errFlag = False
        GlobalNames.VerifyUniqueADUName(
            state, cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs[0],
            errFlag, cCurrentModuleObject + " Name"
        )
        if errFlag:
            ErrorsFound = True
        
        thisBeam.name = state.dataIPShortCut.cAlphaArgs[0]
        thisBeam.unitType = cCurrentModuleObject
        
        if state.dataIPShortCut.lAlphaFieldBlanks[1]:
            thisBeam.airAvailSched = Sched.GetScheduleAlwaysOn(state)
        else:
            thisBeam.airAvailSched = Sched.GetSchedule(state, state.dataIPShortCut.cAlphaArgs[1])
            if thisBeam.airAvailSched is None:
                ErrorsFound = True
        
        if state.dataIPShortCut.lAlphaFieldBlanks[2]:
            thisBeam.coolingAvailSched = Sched.GetScheduleAlwaysOn(state)
        else:
            thisBeam.coolingAvailSched = Sched.GetSchedule(state, state.dataIPShortCut.cAlphaArgs[2])
            if thisBeam.coolingAvailSched is None:
                ErrorsFound = True
        
        if state.dataIPShortCut.lAlphaFieldBlanks[3]:
            thisBeam.heatingAvailSched = Sched.GetScheduleAlwaysOn(state)
        else:
            thisBeam.heatingAvailSched = Sched.GetSchedule(state, state.dataIPShortCut.cAlphaArgs[3])
            if thisBeam.heatingAvailSched is None:
                ErrorsFound = True
        
        thisBeam.airInNodeNum = Node.GetOnlySingleNode(
            state, state.dataIPShortCut.cAlphaArgs[4], ErrorsFound,
            Node.ConnectionObjectType.AirTerminalSingleDuctConstantVolumeFourPipeBeam,
            state.dataIPShortCut.cAlphaArgs[0],
            Node.FluidType.Air, Node.ConnectionType.Inlet,
            Node.CompFluidStream.Primary,
            Node.ObjectIsNotParent,
            state.dataIPShortCut.cAlphaFieldNames[4]
        )
        thisBeam.airOutNodeNum = Node.GetOnlySingleNode(
            state, state.dataIPShortCut.cAlphaArgs[5], ErrorsFound,
            Node.ConnectionObjectType.AirTerminalSingleDuctConstantVolumeFourPipeBeam,
            state.dataIPShortCut.cAlphaArgs[0],
            Node.FluidType.Air, Node.ConnectionType.Outlet,
            Node.CompFluidStream.Primary,
            Node.ObjectIsNotParent,
            state.dataIPShortCut.cAlphaFieldNames[5]
        )
        
        if state.dataIPShortCut.lAlphaFieldBlanks[6] and state.dataIPShortCut.lAlphaFieldBlanks[7]:
            thisBeam.beamCoolingPresent = False
        elif state.dataIPShortCut.lAlphaFieldBlanks[6] and not state.dataIPShortCut.lAlphaFieldBlanks[7]:
            thisBeam.beamCoolingPresent = False
        elif not state.dataIPShortCut.lAlphaFieldBlanks[6] and state.dataIPShortCut.lAlphaFieldBlanks[7]:
            thisBeam.beamCoolingPresent = False
        else:
            thisBeam.beamCoolingPresent = True
            thisBeam.cWInNodeNum = Node.GetOnlySingleNode(
                state, state.dataIPShortCut.cAlphaArgs[6], ErrorsFound,
                Node.ConnectionObjectType.AirTerminalSingleDuctConstantVolumeFourPipeBeam,
                state.dataIPShortCut.cAlphaArgs[0],
                Node.FluidType.Water, Node.ConnectionType.Inlet,
                Node.CompFluidStream.Secondary,
                Node.ObjectIsParent,
                state.dataIPShortCut.cAlphaFieldNames[6]
            )
            thisBeam.cWOutNodeNum = Node.GetOnlySingleNode(
                state, state.dataIPShortCut.cAlphaArgs[7], ErrorsFound,
                Node.ConnectionObjectType.AirTerminalSingleDuctConstantVolumeFourPipeBeam,
                state.dataIPShortCut.cAlphaArgs[0],
                Node.FluidType.Water, Node.ConnectionType.Outlet,
                Node.CompFluidStream.Secondary,
                Node.ObjectIsParent,
                state.dataIPShortCut.cAlphaFieldNames[7]
            )
        
        if state.dataIPShortCut.lAlphaFieldBlanks[8] and state.dataIPShortCut.lAlphaFieldBlanks[9]:
            thisBeam.beamHeatingPresent = False
        elif state.dataIPShortCut.lAlphaFieldBlanks[8] and not state.dataIPShortCut.lAlphaFieldBlanks[9]:
            thisBeam.beamHeatingPresent = False
        elif not state.dataIPShortCut.lAlphaFieldBlanks[8] and state.dataIPShortCut.lAlphaFieldBlanks[9]:
            thisBeam.beamHeatingPresent = False
        else:
            thisBeam.beamHeatingPresent = True
            thisBeam.hWInNodeNum = Node.GetOnlySingleNode(
                state, state.dataIPShortCut.cAlphaArgs[8], ErrorsFound,
                Node.ConnectionObjectType.AirTerminalSingleDuctConstantVolumeFourPipeBeam,
                state.dataIPShortCut.cAlphaArgs[0],
                Node.FluidType.Water, Node.ConnectionType.Inlet,
                Node.CompFluidStream.Secondary,
                Node.ObjectIsParent,
                state.dataIPShortCut.cAlphaFieldNames[8]
            )
            thisBeam.hWOutNodeNum = Node.GetOnlySingleNode(
                state, state.dataIPShortCut.cAlphaArgs[9], ErrorsFound,
                Node.ConnectionObjectType.AirTerminalSingleDuctConstantVolumeFourPipeBeam,
                state.dataIPShortCut.cAlphaArgs[0],
                Node.FluidType.Water, Node.ConnectionType.Outlet,
                Node.CompFluidStream.Secondary,
                Node.ObjectIsParent,
                state.dataIPShortCut.cAlphaFieldNames[9]
            )
        
        thisBeam.vDotDesignPrimAir = state.dataIPShortCut.rNumericArgs[0]
        if thisBeam.vDotDesignPrimAir == state.dataSize.AutoSize:
            thisBeam.vDotDesignPrimAirWasAutosized = True
        
        thisBeam.vDotDesignCW = state.dataIPShortCut.rNumericArgs[1]
        if thisBeam.vDotDesignCW == state.dataSize.AutoSize and thisBeam.beamCoolingPresent:
            thisBeam.vDotDesignCWWasAutosized = True
        
        thisBeam.vDotDesignHW = state.dataIPShortCut.rNumericArgs[2]
        if thisBeam.vDotDesignHW == state.dataSize.AutoSize and thisBeam.beamHeatingPresent:
            thisBeam.vDotDesignHWWasAutosized = True
        
        thisBeam.totBeamLength = state.dataIPShortCut.rNumericArgs[3]
        if thisBeam.totBeamLength == state.dataSize.AutoSize:
            thisBeam.totBeamLengthWasAutosized = True
        
        thisBeam.vDotNormRatedPrimAir = state.dataIPShortCut.rNumericArgs[4]
        thisBeam.qDotNormRatedCooling = state.dataIPShortCut.rNumericArgs[5]
        thisBeam.deltaTempRatedCooling = state.dataIPShortCut.rNumericArgs[6]
        thisBeam.vDotNormRatedCW = state.dataIPShortCut.rNumericArgs[7]
        
        thisBeam.modCoolingQdotDeltaTFuncNum = Curve.GetCurveIndex(state, state.dataIPShortCut.cAlphaArgs[10])
        if thisBeam.modCoolingQdotDeltaTFuncNum == 0 and thisBeam.beamCoolingPresent:
            ErrorsFound = True
        
        thisBeam.modCoolingQdotAirFlowFuncNum = Curve.GetCurveIndex(state, state.dataIPShortCut.cAlphaArgs[11])
        if thisBeam.modCoolingQdotAirFlowFuncNum == 0 and thisBeam.beamCoolingPresent:
            ErrorsFound = True
        
        thisBeam.modCoolingQdotCWFlowFuncNum = Curve.GetCurveIndex(state, state.dataIPShortCut.cAlphaArgs[12])
        if thisBeam.modCoolingQdotCWFlowFuncNum == 0 and thisBeam.beamCoolingPresent:
            ErrorsFound = True
        
        thisBeam.qDotNormRatedHeating = state.dataIPShortCut.rNumericArgs[8]
        thisBeam.deltaTempRatedHeating = state.dataIPShortCut.rNumericArgs[9]
        thisBeam.vDotNormRatedHW = state.dataIPShortCut.rNumericArgs[10]
        
        thisBeam.modHeatingQdotDeltaTFuncNum = Curve.GetCurveIndex(state, state.dataIPShortCut.cAlphaArgs[13])
        if thisBeam.modHeatingQdotDeltaTFuncNum == 0 and thisBeam.beamHeatingPresent:
            ErrorsFound = True
        
        thisBeam.modHeatingQdotAirFlowFuncNum = Curve.GetCurveIndex(state, state.dataIPShortCut.cAlphaArgs[14])
        if thisBeam.modHeatingQdotAirFlowFuncNum == 0 and thisBeam.beamHeatingPresent:
            ErrorsFound = True
        
        thisBeam.modHeatingQdotHWFlowFuncNum = Curve.GetCurveIndex(state, state.dataIPShortCut.cAlphaArgs[15])
        if thisBeam.modHeatingQdotHWFlowFuncNum == 0 and thisBeam.beamHeatingPresent:
            ErrorsFound = True
        
        Node.TestCompSet(state, cCurrentModuleObject, thisBeam.name,
                        state.dataLoopNodes.NodeID(thisBeam.airInNodeNum),
                        state.dataLoopNodes.NodeID(thisBeam.airOutNodeNum),
                        "Air Nodes")
        if thisBeam.beamCoolingPresent:
            Node.TestCompSet(state, cCurrentModuleObject, thisBeam.name,
                            state.dataLoopNodes.NodeID(thisBeam.cWInNodeNum),
                            state.dataLoopNodes.NodeID(thisBeam.cWOutNodeNum),
                            "Chilled Water Nodes")
        if thisBeam.beamHeatingPresent:
            Node.TestCompSet(state, cCurrentModuleObject, thisBeam.name,
                            state.dataLoopNodes.NodeID(thisBeam.hWInNodeNum),
                            state.dataLoopNodes.NodeID(thisBeam.hWOutNodeNum),
                            "Hot Water Nodes")
        
        if thisBeam.beamCoolingPresent:
            OutputProcessor.SetupOutputVariable(
                state, "Zone Air Terminal Beam Sensible Cooling Energy",
                "J", thisBeam, "beamCoolingEnergy"
            )
            OutputProcessor.SetupOutputVariable(
                state, "Zone Air Terminal Beam Sensible Cooling Rate",
                "W", thisBeam, "beamCoolingRate"
            )
        if thisBeam.beamHeatingPresent:
            OutputProcessor.SetupOutputVariable(
                state, "Zone Air Terminal Beam Sensible Heating Energy",
                "J", thisBeam, "beamHeatingEnergy"
            )
            OutputProcessor.SetupOutputVariable(
                state, "Zone Air Terminal Beam Sensible Heating Rate",
                "W", thisBeam, "beamHeatingRate"
            )
        
        OutputProcessor.SetupOutputVariable(
            state, "Zone Air Terminal Primary Air Sensible Cooling Energy",
            "J", thisBeam, "supAirCoolingEnergy"
        )
        OutputProcessor.SetupOutputVariable(
            state, "Zone Air Terminal Primary Air Sensible Cooling Rate",
            "W", thisBeam, "supAirCoolingRate"
        )
        OutputProcessor.SetupOutputVariable(
            state, "Zone Air Terminal Primary Air Sensible Heating Energy",
            "J", thisBeam, "supAirHeatingEnergy"
        )
        OutputProcessor.SetupOutputVariable(
            state, "Zone Air Terminal Primary Air Sensible Heating Rate",
            "W", thisBeam, "supAirHeatingRate"
        )
        OutputProcessor.SetupOutputVariable(
            state, "Zone Air Terminal Primary Air Flow Rate",
            "m3/s", thisBeam, "primAirFlow"
        )
        OutputProcessor.SetupOutputVariable(
            state, "Zone Air Terminal Outdoor Air Volume Flow Rate",
            "m3/s", thisBeam, "OutdoorAirFlowRate"
        )
        
        airNodeFound = False
        for aDUIndex in range(len(state.dataDefineEquipment.AirDistUnit)):
            if thisBeam.airOutNodeNum == state.dataDefineEquipment.AirDistUnit[aDUIndex].OutletNodeNum:
                thisBeam.aDUNum = aDUIndex + 1
                state.dataDefineEquipment.AirDistUnit[aDUIndex].InletNodeNum = thisBeam.airInNodeNum
        
        if thisBeam.aDUNum == 0:
            ErrorsFound = True
        else:
            for ctrlZone in range(state.dataGlobal.NumOfZones):
                if not state.dataZoneEquip.ZoneEquipConfig[ctrlZone].IsControlled:
                    continue
                for supAirIn in range(state.dataZoneEquip.ZoneEquipConfig[ctrlZone].NumInletNodes):
                    if thisBeam.airOutNodeNum == state.dataZoneEquip.ZoneEquipConfig[ctrlZone].InletNode[supAirIn]:
                        thisBeam.zoneIndex = ctrlZone + 1
                        thisBeam.zoneNodeIndex = state.dataZoneEquip.ZoneEquipConfig[ctrlZone].ZoneNode
                        thisBeam.ctrlZoneInNodeIndex = supAirIn + 1
                        state.dataZoneEquip.ZoneEquipConfig[ctrlZone].AirDistUnitCool[supAirIn].InNode = thisBeam.airInNodeNum
                        state.dataZoneEquip.ZoneEquipConfig[ctrlZone].AirDistUnitCool[supAirIn].OutNode = thisBeam.airOutNodeNum
                        state.dataDefineEquipment.AirDistUnit[thisBeam.aDUNum - 1].TermUnitSizingNum = \
                            state.dataZoneEquip.ZoneEquipConfig[ctrlZone].AirDistUnitCool[supAirIn].TermUnitSizingIndex
                        thisBeam.termUnitSizingNum = state.dataDefineEquipment.AirDistUnit[thisBeam.aDUNum - 1].TermUnitSizingNum
                        state.dataDefineEquipment.AirDistUnit[thisBeam.aDUNum - 1].ZoneEqNum = ctrlZone + 1
                        if thisBeam.beamHeatingPresent:
                            state.dataZoneEquip.ZoneEquipConfig[ctrlZone].AirDistUnitHeat[supAirIn].InNode = thisBeam.airInNodeNum
                            state.dataZoneEquip.ZoneEquipConfig[ctrlZone].AirDistUnitHeat[supAirIn].OutNode = thisBeam.airOutNodeNum
                        airNodeFound = True
                        break
        
        if not airNodeFound:
            ErrorsFound = True
        
        if found and not ErrorsFound:
            state.dataFourPipeBeam.FourPipeBeams.append(thisBeam)
            return thisBeam
        
        return None

    def getAirLoopNum(self) -> int:
        return self.airLoopNum

    def getZoneIndex(self) -> int:
        return self.zoneIndex

    def getPrimAirDesignVolFlow(self) -> float:
        return self.vDotDesignPrimAir

    def getTermUnitSizingIndex(self) -> int:
        return self.termUnitSizingNum

    def simulate(self, state: Any, FirstHVACIteration: bool) -> float:
        """Simulate the beam unit and return non-air system output."""
        NonAirSysOutput = 0.0
        
        self.init(state, FirstHVACIteration)
        
        if not self.mySizeFlag:
            self.control(state, FirstHVACIteration)
            NonAirSysOutput = self.qDotBeamCooling + self.qDotBeamHeating
            self.update(state)
            self.report(state)
        
        return NonAirSysOutput

    def init(self, state: Any, FirstHVACIteration: bool) -> None:
        """Initialize the unit."""
        from EnergyPlus import (
            DataZoneEquipment, PlantUtilities, Psychrometrics, HVAC
        )
        
        if self.plantLoopScanFlag and hasattr(state.dataPlnt, 'PlantLoop') and state.dataPlnt.PlantLoop:
            errFlag = False
            if self.beamCoolingPresent:
                PlantUtilities.ScanPlantLoopsForObject(
                    state, self.name,
                    state.dataPlant.PlantEquipmentType.FourPipeBeamAirTerminal,
                    self.cWplantLoc, errFlag, None, None, None,
                    self.cWInNodeNum, None
                )
                if errFlag:
                    pass
            
            if self.beamHeatingPresent:
                PlantUtilities.ScanPlantLoopsForObject(
                    state, self.name,
                    state.dataPlant.PlantEquipmentType.FourPipeBeamAirTerminal,
                    self.hWplantLoc, errFlag, None, None, None,
                    self.hWInNodeNum, None
                )
                if errFlag:
                    pass
            
            self.plantLoopScanFlag = False
        
        if not self.zoneEquipmentListChecked and state.dataZoneEquip.ZoneEquipInputsFilled:
            if self.aDUNum != 0:
                DataZoneEquipment.CheckZoneEquipmentList(
                    state, "ZONEHVAC:AIRDISTRIBUTIONUNIT",
                    state.dataDefineEquipment.AirDistUnit[self.aDUNum - 1].Name
                )
                self.zoneEquipmentListChecked = True
        
        if not state.dataGlobal.SysSizingCalc and self.mySizeFlag and not self.plantLoopScanFlag:
            self.airLoopNum = state.dataZoneEquip.ZoneEquipConfig[self.zoneIndex - 1].InletNodeAirLoopNum[self.ctrlZoneInNodeIndex - 1]
            state.dataDefineEquipment.AirDistUnit[self.aDUNum - 1].AirLoopNum = self.airLoopNum
            self.set_size(state)
            if self.beamCoolingPresent:
                PlantUtilities.InitComponentNodes(
                    state, 0.0, self.mDotDesignCW, self.cWInNodeNum, self.cWOutNodeNum
                )
            if self.beamHeatingPresent:
                PlantUtilities.InitComponentNodes(
                    state, 0.0, self.mDotDesignHW, self.hWInNodeNum, self.hWOutNodeNum
                )
            self.mySizeFlag = False
        
        if state.dataGlobal.BeginEnvrnFlag and self.myEnvrnFlag:
            state.dataLoopNodes.Node[self.airInNodeNum - 1].MassFlowRateMax = self.mDotDesignPrimAir
            state.dataLoopNodes.Node[self.airOutNodeNum - 1].MassFlowRateMax = self.mDotDesignPrimAir
            state.dataLoopNodes.Node[self.airInNodeNum - 1].MassFlowRateMin = 0.0
            state.dataLoopNodes.Node[self.airOutNodeNum - 1].MassFlowRateMin = 0.0
            
            if self.beamCoolingPresent:
                PlantUtilities.InitComponentNodes(
                    state, 0.0, self.mDotDesignCW, self.cWInNodeNum, self.cWOutNodeNum
                )
            if self.beamHeatingPresent:
                PlantUtilities.InitComponentNodes(
                    state, 0.0, self.mDotDesignHW, self.hWInNodeNum, self.hWOutNodeNum
                )
            
            if self.airLoopNum == 0:
                if self.zoneIndex > 0 and self.ctrlZoneInNodeIndex > 0:
                    self.airLoopNum = state.dataZoneEquip.ZoneEquipConfig[self.zoneIndex - 1].InletNodeAirLoopNum[self.ctrlZoneInNodeIndex - 1]
            
            self.myEnvrnFlag = False
        
        if not state.dataGlobal.BeginEnvrnFlag:
            self.myEnvrnFlag = True
        
        if FirstHVACIteration:
            self.airAvailable = (self.airAvailSched.getCurrentVal() > 0.0)
            self.coolingAvailable = (self.airAvailable and self.beamCoolingPresent and 
                                     (self.coolingAvailSched.getCurrentVal() > 0.0))
            self.heatingAvailable = (self.airAvailable and self.beamHeatingPresent and 
                                     (self.heatingAvailSched.getCurrentVal() > 0.0))
            
            if self.airAvailable and state.dataLoopNodes.Node[self.airInNodeNum - 1].MassFlowRate > 0.0:
                state.dataLoopNodes.Node[self.airInNodeNum - 1].MassFlowRate = self.mDotDesignPrimAir
            else:
                state.dataLoopNodes.Node[self.airInNodeNum - 1].MassFlowRate = 0.0
            
            if self.airAvailable and state.dataLoopNodes.Node[self.airInNodeNum - 1].MassFlowRateMaxAvail > 0.0:
                state.dataLoopNodes.Node[self.airInNodeNum - 1].MassFlowRateMaxAvail = self.mDotDesignPrimAir
                state.dataLoopNodes.Node[self.airInNodeNum - 1].MassFlowRateMinAvail = self.mDotDesignPrimAir
            else:
                state.dataLoopNodes.Node[self.airInNodeNum - 1].MassFlowRateMaxAvail = 0.0
                state.dataLoopNodes.Node[self.airInNodeNum - 1].MassFlowRateMinAvail = 0.0
        
        if self.beamCoolingPresent:
            self.cWTempIn = state.dataLoopNodes.Node[self.cWInNodeNum - 1].Temp
            self.cWTempOut = self.cWTempIn
        if self.beamHeatingPresent:
            self.hWTempIn = state.dataLoopNodes.Node[self.hWInNodeNum - 1].Temp
            self.hWTempOut = self.hWTempIn
        
        self.mDotSystemAir = state.dataLoopNodes.Node[self.airInNodeNum - 1].MassFlowRateMaxAvail
        state.dataLoopNodes.Node[self.airInNodeNum - 1].MassFlowRate = self.mDotSystemAir
        self.tDBZoneAirTemp = state.dataLoopNodes.Node[self.zoneNodeIndex - 1].Temp
        self.tDBSystemAir = state.dataLoopNodes.Node[self.airInNodeNum - 1].Temp
        self.cpZoneAir = Psychrometrics.PsyCpAirFnW(state.dataLoopNodes.Node[self.zoneNodeIndex - 1].HumRat)
        self.cpSystemAir = Psychrometrics.PsyCpAirFnW(state.dataLoopNodes.Node[self.airInNodeNum - 1].HumRat)
        self.qDotBeamCooling = 0.0
        self.qDotBeamHeating = 0.0
        self.supAirCoolingRate = 0.0
        self.supAirHeatingRate = 0.0
        self.beamCoolingRate = 0.0
        self.beamHeatingRate = 0.0
        self.primAirFlow = 0.0

    def set_size(self, state: Any) -> None:
        """Size the unit based on design loads."""
        from EnergyPlus import (
            DataSizing, PlantUtilities, Psychrometrics, General, BaseSizer, HVAC
        )
        
        routineName = "HVACFourPipeBeam::set_size "
        
        self.mDotNormRatedPrimAir = self.vDotNormRatedPrimAir * state.dataEnvrn.rhoAirSTP
        
        noHardSizeAnchorAvailable = False
        
        if state.dataSize.CurTermUnitSizingNum > 0:
            originalTermUnitSizeMaxVDot = max(
                state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum - 1].DesCoolVolFlow,
                state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum - 1].DesHeatVolFlow
            )
            originalTermUnitSizeCoolVDot = state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum - 1].DesCoolVolFlow
            originalTermUnitSizeHeatVDot = state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum - 1].DesHeatVolFlow
        else:
            originalTermUnitSizeMaxVDot = 0.0
            originalTermUnitSizeCoolVDot = 0.0
            originalTermUnitSizeHeatVDot = 0.0
        
        if (self.totBeamLengthWasAutosized and self.vDotDesignPrimAirWasAutosized and 
            self.vDotDesignCWWasAutosized and self.vDotDesignHWWasAutosized):
            noHardSizeAnchorAvailable = True
        elif (self.totBeamLengthWasAutosized and self.vDotDesignPrimAirWasAutosized and 
              self.vDotDesignCWWasAutosized and not self.beamHeatingPresent):
            noHardSizeAnchorAvailable = True
        elif (self.totBeamLengthWasAutosized and self.vDotDesignPrimAirWasAutosized and 
              not self.beamCoolingPresent and self.vDotDesignHWWasAutosized):
            noHardSizeAnchorAvailable = True
        elif not self.totBeamLengthWasAutosized:
            if self.vDotDesignPrimAirWasAutosized:
                self.vDotDesignPrimAir = self.vDotNormRatedPrimAir * self.totBeamLength
            if self.vDotDesignCWWasAutosized:
                self.vDotDesignCW = self.vDotNormRatedCW * self.totBeamLength
            if self.vDotDesignHWWasAutosized:
                self.vDotDesignHW = self.vDotNormRatedHW * self.totBeamLength
        else:
            if not self.vDotDesignPrimAirWasAutosized:
                self.totBeamLength = self.vDotDesignPrimAir / self.vDotNormRatedPrimAir
                if self.vDotDesignCWWasAutosized:
                    self.vDotDesignCW = self.vDotNormRatedCW * self.totBeamLength
                if self.vDotDesignHWWasAutosized:
                    self.vDotDesignHW = self.vDotNormRatedHW * self.totBeamLength
            else:
                if self.beamCoolingPresent and not self.vDotDesignCWWasAutosized:
                    self.totBeamLength = self.vDotDesignCW / self.vDotNormRatedCW
                    self.vDotDesignPrimAir = self.vDotNormRatedPrimAir * self.totBeamLength
                    if self.vDotDesignHWWasAutosized:
                        self.vDotDesignHW = self.vDotNormRatedHW * self.totBeamLength
                elif self.beamHeatingPresent and not self.vDotDesignHWWasAutosized:
                    self.totBeamLength = self.vDotDesignHW / self.vDotNormRatedHW
                    self.vDotDesignPrimAir = self.vDotNormRatedPrimAir * self.totBeamLength
                    if self.vDotDesignCWWasAutosized:
                        self.vDotDesignCW = self.vDotNormRatedCW * self.totBeamLength
        
        if (noHardSizeAnchorAvailable and (state.dataSize.CurZoneEqNum > 0) and
            (state.dataSize.CurTermUnitSizingNum > 0)):
            
            ErrTolerance = 0.001
            minFlow = min(
                state.dataEnvrn.StdRhoAir * originalTermUnitSizeMaxVDot,
                state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum - 1].MinOA * state.dataEnvrn.StdRhoAir
            )
            minFlow = max(0.0, minFlow)
            
            mDotAirSolutionCooling = 0.0
            mDotAirSolutionHeating = 0.0
            
            if self.beamCoolingPresent:
                cpAir = Psychrometrics.PsyCpAirFnW(
                    state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum - 1].DesCoolCoilInHumRatTU
                )
                
                if ((state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum - 1].ZoneTempAtCoolPeak -
                     state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum - 1].DesCoolCoilInTempTU) > 2.0):
                    maxFlowCool = (state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum - 1].DesCoolLoad /
                                  (cpAir * (state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum - 1].ZoneTempAtCoolPeak -
                                            state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum - 1].DesCoolCoilInTempTU)))
                else:
                    maxFlowCool = state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum - 1].DesCoolLoad / (cpAir * 2.0)
                
                if minFlow * 3.0 >= maxFlowCool:
                    minFlow = maxFlowCool / 3.0
                
                self.cWTempIn = state.dataSize.PlantSizData(0).ExitTemp
                self.mDotHW = 0.0
                self.tDBZoneAirTemp = state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum - 1].ZoneTempAtCoolPeak
                self.tDBSystemAir = state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum - 1].DesCoolCoilInTempTU
                self.cpZoneAir = Psychrometrics.PsyCpAirFnW(
                    state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum - 1].ZoneHumRatAtCoolPeak
                )
                self.cpSystemAir = Psychrometrics.PsyCpAirFnW(
                    state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum - 1].DesCoolCoilInHumRatTU
                )
                self.qDotZoneReq = -1.0 * state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum - 1].DesCoolLoad
                self.qDotZoneToCoolSetPt = -1.0 * state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum - 1].DesCoolLoad
                self.airAvailable = True
                self.coolingAvailable = True
                self.heatingAvailable = False
                
                def residual_cooling(airFlow: float) -> float:
                    self.mDotSystemAir = airFlow
                    self.vDotDesignPrimAir = self.mDotSystemAir / state.dataEnvrn.StdRhoAir
                    self.totBeamLength = self.vDotDesignPrimAir / self.vDotNormRatedPrimAir
                    if self.vDotDesignCWWasAutosized:
                        self.vDotDesignCW = self.vDotNormRatedCW * self.totBeamLength
                        rho = self.cWplantLoc.loop.glycol.getDensity(state, 6.0, routineName)
                        self.mDotNormRatedCW = self.vDotNormRatedCW * rho
                        self.mDotCW = self.vDotDesignCW * rho
                        if self.beamCoolingPresent:
                            PlantUtilities.InitComponentNodes(state, 0.0, self.mDotCW, self.cWInNodeNum, self.cWOutNodeNum)
                    if self.vDotDesignHWWasAutosized:
                        self.vDotDesignHW = self.vDotNormRatedHW * self.totBeamLength
                        rho = self.hWplantLoc.loop.glycol.getDensity(state, 60.0, routineName)
                        self.mDotNormRatedHW = self.vDotNormRatedHW * rho
                        self.mDotHW = self.vDotDesignHW * rho
                        if self.beamHeatingPresent:
                            PlantUtilities.InitComponentNodes(state, 0.0, self.mDotHW, self.hWInNodeNum, self.hWOutNodeNum)
                    self.calc(state)
                    if self.qDotZoneReq != 0.0:
                        return ((self.qDotZoneReq - self.qDotTotalDelivered) / self.qDotZoneReq)
                    return 1.0
                
                SolFlag = 0
                General.SolveRoot(state, ErrTolerance, 50, SolFlag, mDotAirSolutionCooling,
                                residual_cooling, minFlow, maxFlowCool)
            
            if self.beamHeatingPresent:
                cpAir = Psychrometrics.PsyCpAirFnW(
                    state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum - 1].DesHeatCoilInHumRatTU
                )
                if ((state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum - 1].DesHeatCoilInTempTU -
                     state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum - 1].ZoneTempAtHeatPeak) > 2.0):
                    maxFlowHeat = (state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum - 1].DesHeatLoad /
                                  (cpAir * (state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum - 1].DesHeatCoilInTempTU -
                                            state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum - 1].ZoneTempAtHeatPeak)))
                else:
                    maxFlowHeat = state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum - 1].DesHeatLoad / (cpAir * 2.0)
                
                self.hWTempIn = state.dataSize.PlantSizData(0).ExitTemp
                self.mDotCW = 0.0
                self.tDBZoneAirTemp = state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum - 1].ZoneTempAtHeatPeak
                self.tDBSystemAir = state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum - 1].DesHeatCoilInTempTU
                self.cpZoneAir = Psychrometrics.PsyCpAirFnW(
                    state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum - 1].ZoneHumRatAtHeatPeak
                )
                self.cpSystemAir = Psychrometrics.PsyCpAirFnW(
                    state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum - 1].DesHeatCoilInHumRatTU
                )
                self.qDotZoneReq = state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum - 1].DesHeatLoad
                self.qDotZoneToHeatSetPt = state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum - 1].DesHeatLoad
                self.airAvailable = True
                self.heatingAvailable = True
                self.coolingAvailable = False
                
                def residual_heating(airFlow: float) -> float:
                    self.mDotSystemAir = airFlow
                    self.vDotDesignPrimAir = self.mDotSystemAir / state.dataEnvrn.StdRhoAir
                    self.totBeamLength = self.vDotDesignPrimAir / self.vDotNormRatedPrimAir
                    if self.vDotDesignCWWasAutosized:
                        self.vDotDesignCW = self.vDotNormRatedCW * self.totBeamLength
                        rho = self.cWplantLoc.loop.glycol.getDensity(state, 6.0, routineName)
                        self.mDotNormRatedCW = self.vDotNormRatedCW * rho
                        self.mDotCW = self.vDotDesignCW * rho
                        if self.beamCoolingPresent:
                            PlantUtilities.InitComponentNodes(state, 0.0, self.mDotCW, self.cWInNodeNum, self.cWOutNodeNum)
                    if self.vDotDesignHWWasAutosized:
                        self.vDotDesignHW = self.vDotNormRatedHW * self.totBeamLength
                        rho = self.hWplantLoc.loop.glycol.getDensity(state, 60.0, routineName)
                        self.mDotNormRatedHW = self.vDotNormRatedHW * rho
                        self.mDotHW = self.vDotDesignHW * rho
                        if self.beamHeatingPresent:
                            PlantUtilities.InitComponentNodes(state, 0.0, self.mDotHW, self.hWInNodeNum, self.hWOutNodeNum)
                    self.calc(state)
                    if self.qDotZoneReq != 0.0:
                        return ((self.qDotZoneReq - self.qDotTotalDelivered) / self.qDotZoneReq)
                    return 1.0
                
                SolFlag = 0
                General.SolveRoot(state, ErrTolerance, 50, SolFlag, mDotAirSolutionHeating,
                                residual_heating, 0.0, maxFlowHeat)
            
            self.mDotDesignPrimAir = max(mDotAirSolutionHeating, mDotAirSolutionCooling)
            self.mDotDesignPrimAir = max(
                self.mDotDesignPrimAir,
                state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum - 1].MinOA * state.dataEnvrn.StdRhoAir
            )
            self.vDotDesignPrimAir = self.mDotDesignPrimAir / state.dataEnvrn.StdRhoAir
            self.totBeamLength = self.vDotDesignPrimAir / self.vDotNormRatedPrimAir
            if self.vDotDesignCWWasAutosized:
                self.vDotDesignCW = self.vDotNormRatedCW * self.totBeamLength
            if self.vDotDesignHWWasAutosized:
                self.vDotDesignHW = self.vDotNormRatedHW * self.totBeamLength
        
        self.mDotDesignPrimAir = self.vDotDesignPrimAir * state.dataEnvrn.StdRhoAir
        
        if self.beamCoolingPresent:
            rho = self.cWplantLoc.loop.glycol.getDensity(state, 6.0, routineName)
            self.mDotNormRatedCW = self.vDotNormRatedCW * rho
            self.mDotDesignCW = self.vDotDesignCW * rho
            PlantUtilities.InitComponentNodes(state, 0.0, self.mDotDesignCW, self.cWInNodeNum, self.cWOutNodeNum)
        
        if self.beamHeatingPresent:
            rho = self.hWplantLoc.loop.glycol.getDensity(state, 60.0, routineName)
            self.mDotNormRatedHW = self.vDotNormRatedHW * rho
            self.mDotDesignHW = self.vDotDesignHW * rho
            PlantUtilities.InitComponentNodes(state, 0.0, self.mDotDesignHW, self.hWInNodeNum, self.hWOutNodeNum)
        
        if self.vDotDesignPrimAirWasAutosized:
            BaseSizer.reportSizerOutput(state, self.unitType, self.name, "Supply Air Flow Rate [m3/s]", self.vDotDesignPrimAir)
        if self.vDotDesignCWWasAutosized:
            BaseSizer.reportSizerOutput(state, self.unitType, self.name, "Maximum Total Chilled Water Flow Rate [m3/s]", self.vDotDesignCW)
        if self.vDotDesignHWWasAutosized:
            BaseSizer.reportSizerOutput(state, self.unitType, self.name, "Maximum Total Hot Water Flow Rate [m3/s]", self.vDotDesignHW)
        if self.totBeamLengthWasAutosized:
            BaseSizer.reportSizerOutput(state, self.unitType, self.name, "Zone Total Beam Length [m]", self.totBeamLength)
        
        if self.vDotDesignCW > 0.0 and self.beamCoolingPresent:
            PlantUtilities.RegisterPlantCompDesignFlow(state, self.cWInNodeNum, self.vDotDesignCW)
            BaseSizer.calcCoilWaterFlowRates(
                state, self.name, self.unitType, self.vDotDesignCW,
                self.cWplantLoc.loopNum, state.dataSize.CurZoneEqNum,
                state.dataSize.CurSysNum, state.dataSize.CurOASysNum,
                state.dataSize.FinalZoneSizing, state.dataSize.FinalSysSizing
            )
        
        if self.vDotDesignHW > 0.0 and self.beamHeatingPresent:
            PlantUtilities.RegisterPlantCompDesignFlow(state, self.hWInNodeNum, self.vDotDesignHW)
            BaseSizer.calcCoilWaterFlowRates(
                state, self.name, self.unitType, self.vDotDesignHW,
                self.hWplantLoc.loopNum, state.dataSize.CurZoneEqNum,
                state.dataSize.CurSysNum, state.dataSize.CurOASysNum,
                state.dataSize.FinalZoneSizing, state.dataSize.FinalSysSizing
            )

    def control(self, state: Any, FirstHVACIteration: bool) -> None:
        """Control the beam unit output."""
        from EnergyPlus import DataZoneEnergyDemands, PlantUtilities, General, HVAC
        
        if (self.mDotSystemAir < HVAC.VerySmallMassFlow or
            (not self.airAvailable and not self.coolingAvailable and not self.heatingAvailable)):
            self.mDotHW = 0.0
            if self.beamHeatingPresent:
                PlantUtilities.SetComponentFlowRate(state, self.mDotHW, self.hWInNodeNum, self.hWOutNodeNum, self.hWplantLoc)
            self.hWTempOut = self.hWTempIn
            self.mDotCW = 0.0
            self.cWTempOut = self.cWTempIn
            if self.beamCoolingPresent:
                PlantUtilities.SetComponentFlowRate(state, self.mDotCW, self.cWInNodeNum, self.cWOutNodeNum, self.cWplantLoc)
            return
        
        if (self.airAvailable and self.mDotSystemAir > HVAC.VerySmallMassFlow and
            not self.coolingAvailable and not self.heatingAvailable):
            self.mDotHW = 0.0
            if self.beamHeatingPresent:
                PlantUtilities.SetComponentFlowRate(state, self.mDotHW, self.hWInNodeNum, self.hWOutNodeNum, self.hWplantLoc)
            self.hWTempOut = self.hWTempIn
            self.mDotCW = 0.0
            if self.beamCoolingPresent:
                PlantUtilities.SetComponentFlowRate(state, self.mDotCW, self.cWInNodeNum, self.cWOutNodeNum, self.cWplantLoc)
            self.cWTempOut = self.cWTempIn
            self.calc(state)
            return
        
        self.qDotZoneReq = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[self.zoneIndex - 1].RemainingOutputRequired
        self.qDotZoneToHeatSetPt = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[self.zoneIndex - 1].RemainingOutputReqToHeatSP
        self.qDotZoneToCoolSetPt = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[self.zoneIndex - 1].RemainingOutputReqToCoolSP
        
        self.qDotSystemAir = self.mDotSystemAir * ((self.cpSystemAir * self.tDBSystemAir) - (self.cpZoneAir * self.tDBZoneAirTemp))
        self.qDotBeamReq = self.qDotZoneReq - self.qDotSystemAir
        
        if self.qDotBeamReq < -HVAC.SmallLoad and self.coolingAvailable:
            self.mDotHW = 0.0
            if self.beamHeatingPresent:
                PlantUtilities.SetComponentFlowRate(state, self.mDotHW, self.hWInNodeNum, self.hWOutNodeNum, self.hWplantLoc)
            self.hWTempOut = self.hWTempIn
            self.mDotCW = self.mDotDesignCW
            self.calc(state)
            if self.qDotBeamCooling < (self.qDotBeamReq - HVAC.SmallLoad):
                self.qDotBeamCoolingMax = self.qDotBeamCooling
                ErrTolerance = 0.01
                
                def residual_cw(cWFlow: float) -> float:
                    self.mDotHW = 0.0
                    self.mDotCW = cWFlow
                    self.calc(state)
                    if self.qDotBeamCoolingMax != 0.0:
                        return (((self.qDotZoneToCoolSetPt - self.qDotSystemAir) - self.qDotBeamCooling) / self.qDotBeamCoolingMax)
                    return 1.0
                
                SolFlag = 0
                General.SolveRoot(state, ErrTolerance, 50, SolFlag, self.mDotCW,
                                residual_cw, 0.0, self.mDotDesignCW)
                self.calc(state)
            return
        
        if self.qDotBeamReq > HVAC.SmallLoad and self.heatingAvailable:
            self.mDotCW = 0.0
            if self.beamCoolingPresent:
                PlantUtilities.SetComponentFlowRate(state, self.mDotCW, self.cWInNodeNum, self.cWOutNodeNum, self.cWplantLoc)
            self.cWTempOut = self.cWTempIn
            self.mDotHW = self.mDotDesignHW
            self.calc(state)
            if self.qDotBeamHeating > (self.qDotBeamReq + HVAC.SmallLoad):
                self.qDotBeamHeatingMax = self.qDotBeamHeating
                ErrTolerance = 0.01
                
                def residual_hw(hWFlow: float) -> float:
                    self.mDotHW = hWFlow
                    self.mDotCW = 0.0
                    self.calc(state)
                    if self.qDotBeamHeatingMax != 0.0:
                        return (((self.qDotZoneToHeatSetPt - self.qDotSystemAir) - self.qDotBeamHeating) / self.qDotBeamHeatingMax)
                    return 1.0
                
                SolFlag = 0
                General.SolveRoot(state, ErrTolerance, 50, SolFlag, self.mDotHW,
                                residual_hw, 0.0, self.mDotDesignHW)
                self.calc(state)
            return
        
        self.mDotHW = 0.0
        if self.beamHeatingPresent:
            PlantUtilities.SetComponentFlowRate(state, self.mDotHW, self.hWInNodeNum, self.hWOutNodeNum, self.hWplantLoc)
        self.hWTempOut = self.hWTempIn
        self.mDotCW = 0.0
        self.cWTempOut = self.cWTempIn
        if self.beamCoolingPresent:
            PlantUtilities.SetComponentFlowRate(state, self.mDotCW, self.cWInNodeNum, self.cWOutNodeNum, self.cWplantLoc)

    def calc(self, state: Any) -> None:
        """Calculate beam performance."""
        from EnergyPlus import PlantUtilities, Curve, HVAC
        
        fModCoolCWMdot = 0.0
        fModCoolDeltaT = 0.0
        fModCoolAirMdot = 0.0
        fModHeatHWMdot = 0.0
        fModHeatDeltaT = 0.0
        fModHeatAirMdot = 0.0
        
        self.qDotBeamHeating = 0.0
        self.qDotBeamCooling = 0.0
        self.qDotSystemAir = self.mDotSystemAir * ((self.cpSystemAir * self.tDBSystemAir) - (self.cpZoneAir * self.tDBZoneAirTemp))
        
        if self.coolingAvailable and self.mDotCW > HVAC.VerySmallMassFlow:
            PlantUtilities.SetComponentFlowRate(state, self.mDotCW, self.cWInNodeNum, self.cWOutNodeNum, self.cWplantLoc)
            fModCoolCWMdot = Curve.CurveValue(
                state, self.modCoolingQdotCWFlowFuncNum,
                ((self.mDotCW / self.totBeamLength) / self.mDotNormRatedCW)
            )
            fModCoolDeltaT = Curve.CurveValue(
                state, self.modCoolingQdotDeltaTFuncNum,
                ((self.tDBZoneAirTemp - self.cWTempIn) / self.deltaTempRatedCooling)
            )
            fModCoolAirMdot = Curve.CurveValue(
                state, self.modCoolingQdotAirFlowFuncNum,
                ((self.mDotSystemAir / self.totBeamLength) / self.mDotNormRatedPrimAir)
            )
            self.qDotBeamCooling = (-1.0 * self.qDotNormRatedCooling * fModCoolDeltaT * fModCoolAirMdot * 
                                   fModCoolCWMdot * self.totBeamLength)
            cp = self.cWplantLoc.loop.glycol.getSpecificHeat(state, self.cWTempIn, "calc")
            if self.mDotCW > 0.0:
                self.cWTempOut = self.cWTempIn - (self.qDotBeamCooling / (self.mDotCW * cp))
            else:
                self.cWTempOut = self.cWTempIn
            
            if self.cWTempOut > (max(self.tDBSystemAir, self.tDBZoneAirTemp) - 1.0):
                self.cWTempOut = max(self.tDBSystemAir, self.tDBZoneAirTemp) - 1.0
                self.qDotBeamCooling = self.mDotCW * cp * (self.cWTempIn - self.cWTempOut)
        else:
            self.mDotCW = 0.0
            if self.beamCoolingPresent:
                PlantUtilities.SetComponentFlowRate(state, self.mDotCW, self.cWInNodeNum, self.cWOutNodeNum, self.cWplantLoc)
            self.cWTempOut = self.cWTempIn
            self.qDotBeamCooling = 0.0
        
        if self.heatingAvailable and self.mDotHW > HVAC.VerySmallMassFlow:
            PlantUtilities.SetComponentFlowRate(state, self.mDotHW, self.hWInNodeNum, self.hWOutNodeNum, self.hWplantLoc)
            fModHeatHWMdot = Curve.CurveValue(
                state, self.modHeatingQdotHWFlowFuncNum,
                ((self.mDotHW / self.totBeamLength) / self.mDotNormRatedHW)
            )
            fModHeatDeltaT = Curve.CurveValue(
                state, self.modHeatingQdotDeltaTFuncNum,
                ((self.hWTempIn - self.tDBZoneAirTemp) / self.deltaTempRatedHeating)
            )
            fModHeatAirMdot = Curve.CurveValue(
                state, self.modHeatingQdotAirFlowFuncNum,
                ((self.mDotSystemAir / self.totBeamLength) / self.mDotNormRatedPrimAir)
            )
            self.qDotBeamHeating = (self.qDotNormRatedHeating * fModHeatDeltaT * fModHeatAirMdot * 
                                   fModHeatHWMdot * self.totBeamLength)
            cp = self.hWplantLoc.loop.glycol.getSpecificHeat(state, self.hWTempIn, "calc")
            if self.mDotHW > 0.0:
                self.hWTempOut = self.hWTempIn - (self.qDotBeamHeating / (self.mDotHW * cp))
            else:
                self.hWTempOut = self.hWTempIn
            
            if self.hWTempOut < (min(self.tDBSystemAir, self.tDBZoneAirTemp) + 1.0):
                self.hWTempOut = min(self.tDBSystemAir, self.tDBZoneAirTemp) + 1.0
                self.qDotBeamHeating = self.mDotHW * cp * (self.hWTempIn - self.hWTempOut)
        else:
            self.mDotHW = 0.0
            if self.beamHeatingPresent:
                PlantUtilities.SetComponentFlowRate(state, self.mDotHW, self.hWInNodeNum, self.hWOutNodeNum, self.hWplantLoc)
            self.hWTempOut = self.hWTempIn
            self.qDotBeamHeating = 0.0
        
        self.qDotTotalDelivered = self.qDotSystemAir + self.qDotBeamCooling + self.qDotBeamHeating

    def update(self, state: Any) -> None:
        """Update outlet nodes with current values."""
        nodes = state.dataLoopNodes.Node
        
        nodes[self.airOutNodeNum - 1].MassFlowRate = nodes[self.airInNodeNum - 1].MassFlowRate
        nodes[self.airOutNodeNum - 1].Temp = nodes[self.airInNodeNum - 1].Temp
        nodes[self.airOutNodeNum - 1].HumRat = nodes[self.airInNodeNum - 1].HumRat
        nodes[self.airOutNodeNum - 1].Enthalpy = nodes[self.airInNodeNum - 1].Enthalpy
        nodes[self.airOutNodeNum - 1].Quality = nodes[self.airInNodeNum - 1].Quality
        nodes[self.airOutNodeNum - 1].Press = nodes[self.airInNodeNum - 1].Press
        nodes[self.airOutNodeNum - 1].MassFlowRateMin = nodes[self.airInNodeNum - 1].MassFlowRateMin
        nodes[self.airOutNodeNum - 1].MassFlowRateMax = nodes[self.airInNodeNum - 1].MassFlowRateMax
        nodes[self.airOutNodeNum - 1].MassFlowRateMinAvail = nodes[self.airInNodeNum - 1].MassFlowRateMinAvail
        nodes[self.airOutNodeNum - 1].MassFlowRateMaxAvail = nodes[self.airInNodeNum - 1].MassFlowRateMaxAvail
        
        if state.dataContaminantBalance.Contaminant.CO2Simulation:
            nodes[self.airOutNodeNum - 1].CO2 = nodes[self.airInNodeNum - 1].CO2
        
        if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
            nodes[self.airOutNodeNum - 1].GenContam = nodes[self.airInNodeNum - 1].GenContam
        
        if self.beamCoolingPresent:
            nodes[self.cWOutNodeNum - 1].Temp = self.cWTempOut
        if self.beamHeatingPresent:
            nodes[self.hWOutNodeNum - 1].Temp = self.hWTempOut

    def report(self, state: Any) -> None:
        """Fill report variables."""
        ReportingConstant = state.dataHVACGlobal.TimeStepSysSec
        
        if self.beamCoolingPresent:
            self.beamCoolingRate = abs(self.qDotBeamCooling)
            self.beamCoolingEnergy = self.beamCoolingRate * ReportingConstant
        if self.beamHeatingPresent:
            self.beamHeatingRate = self.qDotBeamHeating
            self.beamHeatingEnergy = self.beamHeatingRate * ReportingConstant
        if self.qDotSystemAir <= 0.0:
            self.supAirCoolingRate = abs(self.qDotSystemAir)
            self.supAirHeatingRate = 0.0
        else:
            self.supAirHeatingRate = self.qDotSystemAir
            self.supAirCoolingRate = 0.0
        
        self.supAirCoolingEnergy = self.supAirCoolingRate * ReportingConstant
        self.supAirHeatingEnergy = self.supAirHeatingRate * ReportingConstant
        self.primAirFlow = self.mDotSystemAir / state.dataEnvrn.StdRhoAir
        self.CalcOutdoorAirVolumeFlowRate(state)

    def CalcOutdoorAirVolumeFlowRate(self, state: Any) -> None:
        """Calculate outdoor air volume flow rate."""
        if self.airLoopNum > 0:
            self.OutdoorAirFlowRate = ((state.dataLoopNodes.Node[self.airOutNodeNum - 1].MassFlowRate / 
                                        state.dataEnvrn.StdRhoAir) *
                                       state.dataAirLoop.AirLoopFlow[self.airLoopNum - 1].OAFrac)
        else:
            self.OutdoorAirFlowRate = 0.0

    def reportTerminalUnit(self, state: Any) -> None:
        """Populate predefined equipment summary report."""
        orp = state.dataOutRptPredefined
        adu = state.dataDefineEquipment.AirDistUnit[self.aDUNum - 1]
        
        if state.dataSize.TermUnitFinalZoneSizing:
            sizing = state.dataSize.TermUnitFinalZoneSizing[adu.TermUnitSizingNum - 1]
            orp.PreDefTableEntry(orp.pdchAirTermMinFlow, adu.Name, sizing.DesCoolVolFlowMin)
            orp.PreDefTableEntry(orp.pdchAirTermMinOutdoorFlow, adu.Name, sizing.MinOA)
            orp.PreDefTableEntry(orp.pdchAirTermSupCoolingSP, adu.Name, sizing.CoolDesTemp)
            orp.PreDefTableEntry(orp.pdchAirTermSupHeatingSP, adu.Name, sizing.HeatDesTemp)
            orp.PreDefTableEntry(orp.pdchAirTermHeatingCap, adu.Name, sizing.DesHeatLoad)
            orp.PreDefTableEntry(orp.pdchAirTermCoolingCap, adu.Name, sizing.DesCoolLoad)
        
        orp.PreDefTableEntry(orp.pdchAirTermTypeInp, adu.Name, "AirTerminal:SingleDuct:ConstantVolume:FourPipeBeam")
        orp.PreDefTableEntry(orp.pdchAirTermPrimFlow, adu.Name, self.vDotNormRatedPrimAir)
        orp.PreDefTableEntry(orp.pdchAirTermSecdFlow, adu.Name, "n/a")
        orp.PreDefTableEntry(orp.pdchAirTermMinFlowSch, adu.Name, "n/a")
        orp.PreDefTableEntry(orp.pdchAirTermMaxFlowReh, adu.Name, "n/a")
        orp.PreDefTableEntry(orp.pdchAirTermMinOAflowSch, adu.Name, "n/a")
        
        if self.beamHeatingPresent:
            orp.PreDefTableEntry(orp.pdchAirTermHeatCoilType, adu.Name, "Included")
        else:
            orp.PreDefTableEntry(orp.pdchAirTermHeatCoilType, adu.Name, "None")
        
        if self.beamCoolingPresent:
            orp.PreDefTableEntry(orp.pdchAirTermCoolCoilType, adu.Name, "Included")
        else:
            orp.PreDefTableEntry(orp.pdchAirTermCoolCoilType, adu.Name, "None")
        
        orp.PreDefTableEntry(orp.pdchAirTermFanType, adu.Name, "n/a")
        orp.PreDefTableEntry(orp.pdchAirTermFanName, adu.Name, "n/a")


@dataclass
class FourPipeBeamData:
    """Global data structure for four pipe beam units."""
    FourPipeBeams: list = field(default_factory=list)
    
    def init_constant_state(self, state: Any) -> None:
        pass
    
    def init_state(self, state: Any) -> None:
        pass
    
    def clear_state(self) -> None:
        self.FourPipeBeams.clear()
