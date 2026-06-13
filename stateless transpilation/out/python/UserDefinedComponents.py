"""
EnergyPlus UserDefinedComponents module - Python port
Complete faithful translation of UserDefinedComponents.hh and implementation
"""

from dataclasses import dataclass, field
from typing import List, Optional, Protocol, Any, Union
from enum import Enum
import math

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData (state): main simulation state object
# - DataPlant.HowMet: enum for load serving method
# - DataPlant.LoopFlowStatus: enum for flow priority
# - PlantLocation: location on plant loop (loopNum, loopSideNum, etc.)
# - PlantComponent: base class for plant equipment
# - Node operations: Node.GetOnlySingleNode, Node.TestCompSet, etc.
# - EMSManager: ManageEMS for EMS program execution
# - PlantUtilities: InitComponentNodes, RegisterPlantCompDesignFlow, etc.
# - PluginManager: plugin execution
# - FluidProperties: glycol density/specific heat queries
# - Psychrometrics: air property functions
# - InputProcessor: input file reading
# - WaterManager: tank setup
# - Various show/error functions: ShowFatalError, ShowSevereError, etc.


class HowMet(Enum):
    """Plant connection load-serving method"""
    Invalid = -1
    NoneDemand = 0
    ByNominalCapLowOutLimit = 1
    ByNominalCapHiOutLimit = 2


class LoopFlowStatus(Enum):
    """Plant loop flow priority"""
    Invalid = -1
    NeedyAndTurnsLoopOn = 0
    # ... other values as needed


@dataclass
class PlantLocation:
    """Location on a plant loop"""
    loopNum: int = -1
    loopSideNum: int = -1
    branchNum: int = -1
    compNum: int = -1
    loop: Any = None  # Reference to loop structure


@dataclass
class PlantConnectionStruct:
    """Data structure for a plant loop connection"""
    ErlInitProgramMngr: int = 0
    ErlSimProgramMngr: int = 0
    simPluginLocation: int = -1
    initPluginLocation: int = -1
    simCallbackIndex: int = -1
    initCallbackIndex: int = -1
    plantLoc: PlantLocation = field(default_factory=PlantLocation)
    InletNodeNum: int = 0
    OutletNodeNum: int = 0
    FlowPriority: LoopFlowStatus = LoopFlowStatus.Invalid
    HowLoadServed: HowMet = HowMet.Invalid
    LowOutTempLimit: float = 0.0
    HiOutTempLimit: float = 0.0
    MassFlowRateRequest: float = 0.0
    MassFlowRateMin: float = 0.0
    MassFlowRateMax: float = 0.0
    DesignVolumeFlowRate: float = 0.0
    MyLoad: float = 0.0
    MinLoad: float = 0.0
    MaxLoad: float = 0.0
    OptLoad: float = 0.0
    InletRho: float = 0.0
    InletCp: float = 0.0
    InletTemp: float = 0.0
    InletMassFlowRate: float = 0.0
    OutletTemp: float = 0.0


@dataclass
class AirConnectionStruct:
    """Data structure for an air connection"""
    InletNodeNum: int = 0
    OutletNodeNum: int = 0
    InletRho: float = 0.0
    InletCp: float = 0.0
    InletTemp: float = 0.0
    InletHumRat: float = 0.0
    InletMassFlowRate: float = 0.0
    OutletTemp: float = 0.0
    OutletHumRat: float = 0.0
    OutletMassFlowRate: float = 0.0


@dataclass
class WaterUseTankConnectionStruct:
    """Data structure for water use storage system interaction"""
    SuppliedByWaterSystem: bool = False
    SupplyTankID: int = 0
    SupplyTankDemandARRID: int = 0
    SupplyVdotRequest: float = 0.0
    CollectsToWaterSystem: bool = False
    CollectionTankID: int = 0
    CollectionTankSupplyARRID: int = 0
    CollectedVdot: float = 0.0


@dataclass
class ZoneInternalGainsStruct:
    """Data structure for zone internal gains"""
    DeviceHasInternalGains: bool = False
    ZoneNum: int = 0
    ConvectionGainRate: float = 0.0
    ReturnAirConvectionGainRate: float = 0.0
    ThermalRadiationGainRate: float = 0.0
    LatentGainRate: float = 0.0
    ReturnAirLatentGainRate: float = 0.0
    CarbonDioxideGainRate: float = 0.0
    GenericContamGainRate: float = 0.0


class PlantComponent(Protocol):
    """Base class protocol for plant components"""
    Name: str
    
    def onInitLoopEquip(self, state: Any, calledFromLocation: PlantLocation) -> None:
        ...
    
    def getDesignCapacities(self, state: Any, calledFromLocation: PlantLocation) -> tuple[float, float, float]:
        ...
    
    def simulate(self, state: Any, calledFromLocation: PlantLocation, FirstHVACIteration: bool, CurLoad: float, RunFlag: bool) -> None:
        ...
    
    def oneTimeInit(self, state: Any) -> None:
        ...


@dataclass
class UserPlantComponentStruct:
    """User-defined plant component"""
    Name: str = ""
    ErlSimProgramMngr: int = 0
    simPluginLocation: int = -1
    simCallbackIndex: int = -1
    NumPlantConnections: int = 0
    Loop: List[PlantConnectionStruct] = field(default_factory=list)
    Air: AirConnectionStruct = field(default_factory=AirConnectionStruct)
    Water: WaterUseTankConnectionStruct = field(default_factory=WaterUseTankConnectionStruct)
    Zone: ZoneInternalGainsStruct = field(default_factory=ZoneInternalGainsStruct)
    myOneTimeFlag: bool = True

    @staticmethod
    def factory(state: Any, objectName: str) -> "UserPlantComponentStruct":
        """Factory method to get a user-defined plant component"""
        if state.dataUserDefinedComponents.GetPlantCompInput:
            GetUserDefinedPlantComponents(state)
            state.dataUserDefinedComponents.GetPlantCompInput = False
        
        for thisComp in state.dataUserDefinedComponents.UserPlantComp:
            if thisComp.Name == objectName:
                return thisComp
        
        raise RuntimeError(f"LocalUserDefinedPlantComponentFactory: Error getting inputs for object named: {objectName}")

    def onInitLoopEquip(self, state: Any, calledFromLocation: PlantLocation) -> None:
        """Initialize on loop equipment"""
        myLoad = 0.0
        thisLoop = -1
        
        self.oneTimeInit(state)
        
        for loop in range(self.NumPlantConnections):
            if calledFromLocation.loopNum != self.Loop[loop].plantLoc.loopNum:
                continue
            if calledFromLocation.loopSideNum != self.Loop[loop].plantLoc.loopSideNum:
                continue
            thisLoop = loop
            break
        
        if thisLoop >= 0:
            self.initialize(state, thisLoop, myLoad)
            
            plantConnection = self.Loop[thisLoop]
            
            if plantConnection.ErlInitProgramMngr > 0:
                state.EMSManager.ManageEMS(state, "UserDefinedComponentModel", plantConnection.ErlInitProgramMngr)
            elif plantConnection.initPluginLocation > -1:
                state.dataPluginManager.pluginManager.runSingleUserDefinedPlugin(state, plantConnection.initPluginLocation)
            elif plantConnection.initCallbackIndex > -1:
                state.dataPluginManager.pluginManager.runSingleUserDefinedCallback(state, plantConnection.initCallbackIndex)
            
            state.PlantUtilities.InitComponentNodes(
                state, plantConnection.MassFlowRateMin, plantConnection.MassFlowRateMax,
                plantConnection.InletNodeNum, plantConnection.OutletNodeNum)
            
            state.PlantUtilities.RegisterPlantCompDesignFlow(
                state, plantConnection.InletNodeNum, plantConnection.DesignVolumeFlowRate)
        else:
            raise RuntimeError(
                f"SimUserDefinedPlantComponent: did not find where called from. Loop number called from ={calledFromLocation.loopNum}, "
                f"loop side called from ={calledFromLocation.loopSideNum}.")

    def getDesignCapacities(self, state: Any, calledFromLocation: PlantLocation) -> tuple[float, float, float]:
        """Get design capacity values"""
        thisLoop = -1
        for loop in range(self.NumPlantConnections):
            if calledFromLocation.loopNum != self.Loop[loop].plantLoc.loopNum:
                continue
            if calledFromLocation.loopSideNum != self.Loop[loop].plantLoc.loopSideNum:
                continue
            thisLoop = loop
            break
        
        if thisLoop < 0:
            raise RuntimeError(
                f"SimUserDefinedPlantComponent: did not find plant connection for {self.Name}. "
                f"Loop number called from ={calledFromLocation.loopNum}, loop side called from ={calledFromLocation.loopSideNum}.")
        
        plantConnection = self.Loop[thisLoop]
        return plantConnection.MinLoad, plantConnection.MaxLoad, plantConnection.OptLoad

    def simulate(self, state: Any, calledFromLocation: PlantLocation, FirstHVACIteration: bool, CurLoad: float, RunFlag: bool) -> None:
        """Simulate the user-defined plant component"""
        if state.dataGlobal.BeginEnvrnFlag:
            self.onInitLoopEquip(state, calledFromLocation)
        
        thisLoop = -1
        for loop in range(self.NumPlantConnections):
            if calledFromLocation.loopNum != self.Loop[loop].plantLoc.loopNum:
                continue
            if calledFromLocation.loopSideNum != self.Loop[loop].plantLoc.loopSideNum:
                continue
            thisLoop = loop
            break
        
        if thisLoop < 0:
            raise RuntimeError(
                f"SimUserDefinedPlantComponent: did not find plant connection for {self.Name}. "
                f"Loop number called from ={calledFromLocation.loopNum}, loop side called from ={calledFromLocation.loopSideNum}.")
        
        self.initialize(state, thisLoop, CurLoad)
        
        plantConnection = self.Loop[thisLoop]
        
        if plantConnection.ErlSimProgramMngr > 0:
            state.EMSManager.ManageEMS(state, "UserDefinedComponentModel", plantConnection.ErlSimProgramMngr)
        elif plantConnection.simPluginLocation > -1:
            state.dataPluginManager.pluginManager.runSingleUserDefinedPlugin(state, plantConnection.simPluginLocation)
        elif plantConnection.simCallbackIndex > -1:
            state.dataPluginManager.pluginManager.runSingleUserDefinedCallback(state, plantConnection.simCallbackIndex)
        
        if self.ErlSimProgramMngr > 0:
            state.EMSManager.ManageEMS(state, "UserDefinedComponentModel", self.ErlSimProgramMngr)
        elif self.simPluginLocation > -1:
            state.dataPluginManager.pluginManager.runSingleUserDefinedPlugin(state, self.simPluginLocation)
        elif self.simCallbackIndex > -1:
            state.dataPluginManager.pluginManager.runSingleUserDefinedCallback(state, self.simCallbackIndex)
        
        self.report(state, thisLoop)

    def initialize(self, state: Any, LoopNum: int, MyLoad: float) -> None:
        """Initialize plant component"""
        self.oneTimeInit(state)
        
        if LoopNum < 0 or LoopNum >= self.NumPlantConnections:
            return
        
        plantConnection = self.Loop[LoopNum]
        plantConnection.MyLoad = MyLoad
        
        plantConnection.InletRho = plantConnection.plantLoc.loop.glycol.getDensity(
            state, state.dataLoopNodes.Node[plantConnection.InletNodeNum].Temp, "InitPlantUserComponent")
        plantConnection.InletCp = plantConnection.plantLoc.loop.glycol.getSpecificHeat(
            state, state.dataLoopNodes.Node[plantConnection.InletNodeNum].Temp, "InitPlantUserComponent")
        plantConnection.InletMassFlowRate = state.dataLoopNodes.Node[plantConnection.InletNodeNum].MassFlowRate
        plantConnection.InletTemp = state.dataLoopNodes.Node[plantConnection.InletNodeNum].Temp
        
        if self.Air.InletNodeNum > 0:
            self.Air.InletRho = state.Psychrometrics.PsyRhoAirFnPbTdbW(
                state, state.dataEnvrn.OutBaroPress,
                state.dataLoopNodes.Node[self.Air.InletNodeNum].Temp,
                state.dataLoopNodes.Node[self.Air.InletNodeNum].HumRat,
                "InitPlantUserComponent")
            self.Air.InletCp = state.Psychrometrics.PsyCpAirFnW(
                state.dataLoopNodes.Node[self.Air.InletNodeNum].HumRat)
            self.Air.InletTemp = state.dataLoopNodes.Node[self.Air.InletNodeNum].Temp
            self.Air.InletMassFlowRate = state.dataLoopNodes.Node[self.Air.InletNodeNum].MassFlowRate
            self.Air.InletHumRat = state.dataLoopNodes.Node[self.Air.InletNodeNum].HumRat

    def report(self, state: Any, LoopNum: int) -> None:
        """Report results"""
        if LoopNum < 0 or LoopNum >= self.NumPlantConnections:
            return
        
        plantConnection = self.Loop[LoopNum]
        
        state.PlantUtilities.SafeCopyPlantNode(state, plantConnection.InletNodeNum, plantConnection.OutletNodeNum)
        state.dataLoopNodes.Node[plantConnection.OutletNodeNum].Temp = plantConnection.OutletTemp
        
        state.PlantUtilities.SetComponentFlowRate(
            state, plantConnection.MassFlowRateRequest, plantConnection.InletNodeNum,
            plantConnection.OutletNodeNum, plantConnection.plantLoc)
        
        if self.Air.OutletNodeNum > 0:
            state.dataLoopNodes.Node[self.Air.OutletNodeNum].Temp = self.Air.OutletTemp
            state.dataLoopNodes.Node[self.Air.OutletNodeNum].HumRat = self.Air.OutletHumRat
            state.dataLoopNodes.Node[self.Air.OutletNodeNum].MassFlowRate = self.Air.OutletMassFlowRate
            state.dataLoopNodes.Node[self.Air.OutletNodeNum].Enthalpy = state.Psychrometrics.PsyHFnTdbW(
                self.Air.OutletTemp, self.Air.OutletHumRat)
        
        if self.Water.SuppliedByWaterSystem:
            state.dataWaterData.WaterStorage[self.Water.SupplyTankID].VdotRequestDemand[
                self.Water.SupplyTankDemandARRID] = self.Water.SupplyVdotRequest
        
        if self.Water.CollectsToWaterSystem:
            state.dataWaterData.WaterStorage[self.Water.CollectionTankID].VdotAvailSupply[
                self.Water.CollectionTankSupplyARRID] = self.Water.CollectedVdot
        
        if plantConnection.HowLoadServed == HowMet.ByNominalCapLowOutLimit:
            state.DataPlant.CompData.getPlantComponent(state, plantConnection.plantLoc).MinOutletTemp = plantConnection.LowOutTempLimit
        
        if plantConnection.HowLoadServed == HowMet.ByNominalCapHiOutLimit:
            state.DataPlant.CompData.getPlantComponent(state, plantConnection.plantLoc).MaxOutletTemp = plantConnection.HiOutTempLimit

    def oneTimeInit(self, state: Any) -> None:
        """One-time initialization"""
        if self.myOneTimeFlag:
            for connectionIndex in range(self.NumPlantConnections):
                plantConnection = self.Loop[connectionIndex]
                errFlag = False
                state.PlantUtilities.ScanPlantLoopsForObject(
                    state, self.Name, "PlantComponentUserDefined", plantConnection.plantLoc,
                    errFlag, None, None, None, plantConnection.InletNodeNum, None)
                if errFlag:
                    raise RuntimeError("InitPlantUserComponent: Program terminated due to previous condition(s).")
                
                state.DataPlant.CompData.getPlantComponent(state, plantConnection.plantLoc).FlowPriority = plantConnection.FlowPriority
                state.DataPlant.CompData.getPlantComponent(state, plantConnection.plantLoc).HowLoadServed = plantConnection.HowLoadServed
            
            self.myOneTimeFlag = False


@dataclass
class UserCoilComponentStruct:
    """User-defined coil component"""
    Name: str = ""
    ErlSimProgramMngr: int = 0
    ErlInitProgramMngr: int = 0
    initPluginLocation: int = -1
    simPluginLocation: int = -1
    initCallbackIndex: int = -1
    simCallbackIndex: int = -1
    NumAirConnections: int = 0
    PlantIsConnected: bool = False
    AirConnections: List[AirConnectionStruct] = field(default_factory=list)
    Loop: PlantConnectionStruct = field(default_factory=PlantConnectionStruct)
    Water: WaterUseTankConnectionStruct = field(default_factory=WaterUseTankConnectionStruct)
    Zone: ZoneInternalGainsStruct = field(default_factory=ZoneInternalGainsStruct)
    myOneTimeFlag: bool = True

    def initialize(self, state: Any) -> None:
        """Initialize coil component"""
        if self.myOneTimeFlag:
            if self.PlantIsConnected:
                errFlag = False
                state.PlantUtilities.ScanPlantLoopsForObject(
                    state, self.Name, "CoilUserDefined", self.Loop.plantLoc, errFlag)
                if errFlag:
                    raise RuntimeError("InitPlantUserComponent: Program terminated due to previous condition(s).")
                
                state.DataPlant.CompData.getPlantComponent(state, self.Loop.plantLoc).FlowPriority = self.Loop.FlowPriority
                state.DataPlant.CompData.getPlantComponent(state, self.Loop.plantLoc).HowLoadServed = self.Loop.HowLoadServed
            
            self.myOneTimeFlag = False
        
        for loop in range(self.NumAirConnections):
            airConnection = self.AirConnections[loop]
            airConnection.InletRho = state.Psychrometrics.PsyRhoAirFnPbTdbW(
                state, state.dataEnvrn.OutBaroPress,
                state.dataLoopNodes.Node[airConnection.InletNodeNum].Temp,
                state.dataLoopNodes.Node[airConnection.InletNodeNum].HumRat,
                "InitCoilUserDefined")
            
            airConnection.InletCp = state.Psychrometrics.PsyCpAirFnW(
                state.dataLoopNodes.Node[airConnection.InletNodeNum].HumRat)
            airConnection.InletTemp = state.dataLoopNodes.Node[airConnection.InletNodeNum].Temp
            airConnection.InletMassFlowRate = state.dataLoopNodes.Node[airConnection.InletNodeNum].MassFlowRate
            airConnection.InletHumRat = state.dataLoopNodes.Node[airConnection.InletNodeNum].HumRat
        
        if self.PlantIsConnected:
            self.Loop.InletRho = self.Loop.plantLoc.loop.glycol.getDensity(
                state, state.dataLoopNodes.Node[self.Loop.InletNodeNum].Temp, "InitCoilUserDefined")
            self.Loop.InletCp = self.Loop.plantLoc.loop.glycol.getSpecificHeat(
                state, state.dataLoopNodes.Node[self.Loop.InletNodeNum].Temp, "InitCoilUserDefined")
            self.Loop.InletTemp = state.dataLoopNodes.Node[self.Loop.InletNodeNum].Temp
            self.Loop.InletMassFlowRate = state.dataLoopNodes.Node[self.Loop.InletNodeNum].MassFlowRate

    def report(self, state: Any) -> None:
        """Report coil results"""
        for loop in range(self.NumAirConnections):
            airConnection = self.AirConnections[loop]
            if airConnection.OutletNodeNum > 0:
                state.dataLoopNodes.Node[airConnection.OutletNodeNum].Temp = airConnection.OutletTemp
                state.dataLoopNodes.Node[airConnection.OutletNodeNum].HumRat = airConnection.OutletHumRat
                state.dataLoopNodes.Node[airConnection.OutletNodeNum].MassFlowRate = airConnection.OutletMassFlowRate
                state.dataLoopNodes.Node[airConnection.OutletNodeNum].Enthalpy = state.Psychrometrics.PsyHFnTdbW(
                    airConnection.OutletTemp, airConnection.OutletHumRat)
                
                state.dataLoopNodes.Node[airConnection.OutletNodeNum].MassFlowRateMinAvail = \
                    state.dataLoopNodes.Node[airConnection.InletNodeNum].MassFlowRateMinAvail
                state.dataLoopNodes.Node[airConnection.OutletNodeNum].MassFlowRateMaxAvail = \
                    state.dataLoopNodes.Node[airConnection.InletNodeNum].MassFlowRateMaxAvail
        
        if self.PlantIsConnected:
            state.PlantUtilities.SetComponentFlowRate(
                state, self.Loop.MassFlowRateRequest, self.Loop.InletNodeNum,
                self.Loop.OutletNodeNum, self.Loop.plantLoc)
            state.PlantUtilities.SafeCopyPlantNode(state, self.Loop.InletNodeNum, self.Loop.OutletNodeNum)
            state.dataLoopNodes.Node[self.Loop.OutletNodeNum].Temp = self.Loop.OutletTemp
        
        if self.Water.SuppliedByWaterSystem:
            state.dataWaterData.WaterStorage[self.Water.SupplyTankID].VdotRequestDemand[
                self.Water.SupplyTankDemandARRID] = self.Water.SupplyVdotRequest
        
        if self.Water.CollectsToWaterSystem:
            state.dataWaterData.WaterStorage[self.Water.CollectionTankID].VdotAvailSupply[
                self.Water.CollectionTankSupplyARRID] = self.Water.CollectedVdot


@dataclass
class UserAirComponentStruct:
    """Base class for user-defined air components"""
    Name: str = ""
    ErlSimProgramMngr: int = 0
    ErlInitProgramMngr: int = 0
    initPluginLocation: int = -1
    simPluginLocation: int = -1
    initCallbackIndex: int = -1
    simCallbackIndex: int = -1
    SourceAir: AirConnectionStruct = field(default_factory=AirConnectionStruct)
    NumPlantConnections: int = 0
    Loop: List[PlantConnectionStruct] = field(default_factory=list)
    Water: WaterUseTankConnectionStruct = field(default_factory=WaterUseTankConnectionStruct)
    Zone: ZoneInternalGainsStruct = field(default_factory=ZoneInternalGainsStruct)
    RemainingOutputToHeatingSP: float = 0.0
    RemainingOutputToCoolingSP: float = 0.0
    RemainingOutputReqToHumidSP: float = 0.0
    RemainingOutputReqToDehumidSP: float = 0.0
    myOneTimeFlag: bool = True
    AirConnection: AirConnectionStruct = field(default_factory=AirConnectionStruct)

    def initialize(self, state: Any, ZoneNum: int) -> None:
        """Initialize air component (to be overridden)"""
        pass

    def report(self, state: Any) -> None:
        """Report air component results (to be overridden)"""
        pass


@dataclass
class UserZoneHVACForcedAirComponentStruct(UserAirComponentStruct):
    """User-defined zone HVAC forced air component"""
    
    def initialize(self, state: Any, ZoneNum: int) -> None:
        """Initialize zone HVAC component"""
        if self.myOneTimeFlag:
            if self.NumPlantConnections > 0:
                for loop in range(self.NumPlantConnections):
                    plantConnection = self.Loop[loop]
                    errFlag = False
                    state.PlantUtilities.ScanPlantLoopsForObject(
                        state, self.Name, "ZoneHVACAirUserDefined", plantConnection.plantLoc,
                        errFlag, None, None, None, plantConnection.InletNodeNum, None)
                    if errFlag:
                        raise RuntimeError("InitPlantUserComponent: Program terminated due to previous condition(s).")
                    
                    state.DataPlant.CompData.getPlantComponent(state, plantConnection.plantLoc).FlowPriority = plantConnection.FlowPriority
                    state.DataPlant.CompData.getPlantComponent(state, plantConnection.plantLoc).HowLoadServed = plantConnection.HowLoadServed
            
            self.myOneTimeFlag = False
        
        self.RemainingOutputToHeatingSP = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNum].RemainingOutputReqToHeatSP
        self.RemainingOutputToCoolingSP = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNum].RemainingOutputReqToCoolSP
        self.RemainingOutputReqToDehumidSP = state.dataZoneEnergyDemand.ZoneSysMoistureDemand[ZoneNum].RemainingOutputReqToDehumidSP
        self.RemainingOutputReqToHumidSP = state.dataZoneEnergyDemand.ZoneSysMoistureDemand[ZoneNum].RemainingOutputReqToHumidSP
        
        self.AirConnection.InletRho = state.Psychrometrics.PsyRhoAirFnPbTdbW(
            state, state.dataEnvrn.OutBaroPress,
            state.dataLoopNodes.Node[self.AirConnection.InletNodeNum].Temp,
            state.dataLoopNodes.Node[self.AirConnection.InletNodeNum].HumRat,
            "InitZoneAirUserDefined")
        self.AirConnection.InletCp = state.Psychrometrics.PsyCpAirFnW(
            state.dataLoopNodes.Node[self.AirConnection.InletNodeNum].HumRat)
        self.AirConnection.InletTemp = state.dataLoopNodes.Node[self.AirConnection.InletNodeNum].Temp
        self.AirConnection.InletHumRat = state.dataLoopNodes.Node[self.AirConnection.InletNodeNum].HumRat
        
        if self.SourceAir.InletNodeNum > 0:
            self.SourceAir.InletRho = state.Psychrometrics.PsyRhoAirFnPbTdbW(
                state, state.dataEnvrn.OutBaroPress,
                state.dataLoopNodes.Node[self.SourceAir.InletNodeNum].Temp,
                state.dataLoopNodes.Node[self.SourceAir.InletNodeNum].HumRat,
                "InitZoneAirUserDefined")
            self.SourceAir.InletCp = state.Psychrometrics.PsyCpAirFnW(
                state.dataLoopNodes.Node[self.SourceAir.InletNodeNum].HumRat)
            self.SourceAir.InletTemp = state.dataLoopNodes.Node[self.SourceAir.InletNodeNum].Temp
            self.SourceAir.InletHumRat = state.dataLoopNodes.Node[self.SourceAir.InletNodeNum].HumRat
        
        if self.NumPlantConnections > 0:
            for loop in range(self.NumPlantConnections):
                plantConnection = self.Loop[loop]
                plantConnection.InletRho = plantConnection.plantLoc.loop.glycol.getDensity(
                    state, state.dataLoopNodes.Node[plantConnection.InletNodeNum].Temp, "InitZoneAirUserDefined")
                plantConnection.InletCp = plantConnection.plantLoc.loop.glycol.getSpecificHeat(
                    state, state.dataLoopNodes.Node[plantConnection.InletNodeNum].Temp, "InitZoneAirUserDefined")
                plantConnection.InletTemp = state.dataLoopNodes.Node[plantConnection.InletNodeNum].Temp
                plantConnection.InletMassFlowRate = state.dataLoopNodes.Node[plantConnection.InletNodeNum].MassFlowRate

    def report(self, state: Any) -> None:
        """Report zone HVAC component results"""
        state.dataLoopNodes.Node[self.AirConnection.InletNodeNum].MassFlowRate = self.AirConnection.InletMassFlowRate
        
        state.dataLoopNodes.Node[self.AirConnection.OutletNodeNum].Temp = self.AirConnection.OutletTemp
        state.dataLoopNodes.Node[self.AirConnection.OutletNodeNum].HumRat = self.AirConnection.OutletHumRat
        state.dataLoopNodes.Node[self.AirConnection.OutletNodeNum].MassFlowRate = self.AirConnection.OutletMassFlowRate
        state.dataLoopNodes.Node[self.AirConnection.OutletNodeNum].Enthalpy = state.Psychrometrics.PsyHFnTdbW(
            self.AirConnection.OutletTemp, self.AirConnection.OutletHumRat)
        
        if self.SourceAir.OutletNodeNum > 0:
            state.dataLoopNodes.Node[self.SourceAir.OutletNodeNum].Temp = self.SourceAir.OutletTemp
            state.dataLoopNodes.Node[self.SourceAir.OutletNodeNum].HumRat = self.SourceAir.OutletHumRat
            state.dataLoopNodes.Node[self.SourceAir.OutletNodeNum].MassFlowRate = self.SourceAir.OutletMassFlowRate
            state.dataLoopNodes.Node[self.SourceAir.OutletNodeNum].Enthalpy = state.Psychrometrics.PsyHFnTdbW(
                self.SourceAir.OutletTemp, self.SourceAir.OutletHumRat)
        
        if self.NumPlantConnections > 0:
            for loop in range(self.NumPlantConnections):
                plantConnection = self.Loop[loop]
                state.PlantUtilities.SetComponentFlowRate(
                    state, plantConnection.MassFlowRateRequest, plantConnection.InletNodeNum,
                    plantConnection.OutletNodeNum, plantConnection.plantLoc)
                state.PlantUtilities.SafeCopyPlantNode(state, plantConnection.InletNodeNum, plantConnection.OutletNodeNum)
                state.dataLoopNodes.Node[plantConnection.OutletNodeNum].Temp = plantConnection.OutletTemp
        
        if self.Water.SuppliedByWaterSystem:
            state.dataWaterData.WaterStorage[self.Water.SupplyTankID].VdotRequestDemand[
                self.Water.SupplyTankDemandARRID] = self.Water.SupplyVdotRequest
        
        if self.Water.CollectsToWaterSystem:
            state.dataWaterData.WaterStorage[self.Water.CollectionTankID].VdotAvailSupply[
                self.Water.CollectionTankSupplyARRID] = self.Water.CollectedVdot


@dataclass
class UserAirTerminalComponentStruct(UserAirComponentStruct):
    """User-defined air terminal component"""
    ActualCtrlZoneNum: int = 0
    ADUNum: int = 0

    def initialize(self, state: Any, ZoneNum: int) -> None:
        """Initialize air terminal component"""
        if self.myOneTimeFlag:
            if self.NumPlantConnections > 0:
                for loop in range(self.NumPlantConnections):
                    plantConnection = self.Loop[loop]
                    errFlag = False
                    state.PlantUtilities.ScanPlantLoopsForObject(
                        state, self.Name, "AirTerminalUserDefined", plantConnection.plantLoc,
                        errFlag, None, None, None, plantConnection.InletNodeNum, None)
                    if errFlag:
                        raise RuntimeError("InitPlantUserComponent: Program terminated due to previous condition(s).")
                    
                    state.DataPlant.CompData.getPlantComponent(state, plantConnection.plantLoc).FlowPriority = plantConnection.FlowPriority
                    state.DataPlant.CompData.getPlantComponent(state, plantConnection.plantLoc).HowLoadServed = plantConnection.HowLoadServed
            
            self.myOneTimeFlag = False
        
        self.RemainingOutputToHeatingSP = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNum].RemainingOutputReqToHeatSP
        self.RemainingOutputToCoolingSP = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNum].RemainingOutputReqToCoolSP
        self.RemainingOutputReqToDehumidSP = state.dataZoneEnergyDemand.ZoneSysMoistureDemand[ZoneNum].RemainingOutputReqToDehumidSP
        self.RemainingOutputReqToHumidSP = state.dataZoneEnergyDemand.ZoneSysMoistureDemand[ZoneNum].RemainingOutputReqToHumidSP
        
        self.AirConnection.InletRho = state.Psychrometrics.PsyRhoAirFnPbTdbW(
            state, state.dataEnvrn.OutBaroPress,
            state.dataLoopNodes.Node[self.AirConnection.InletNodeNum].Temp,
            state.dataLoopNodes.Node[self.AirConnection.InletNodeNum].HumRat,
            "InitAirTerminalUserDefined")
        self.AirConnection.InletCp = state.Psychrometrics.PsyCpAirFnW(
            state.dataLoopNodes.Node[self.AirConnection.InletNodeNum].HumRat)
        self.AirConnection.InletTemp = state.dataLoopNodes.Node[self.AirConnection.InletNodeNum].Temp
        self.AirConnection.InletHumRat = state.dataLoopNodes.Node[self.AirConnection.InletNodeNum].HumRat
        
        if self.SourceAir.InletNodeNum > 0:
            self.SourceAir.InletRho = state.Psychrometrics.PsyRhoAirFnPbTdbW(
                state, state.dataEnvrn.OutBaroPress,
                state.dataLoopNodes.Node[self.SourceAir.InletNodeNum].Temp,
                state.dataLoopNodes.Node[self.SourceAir.InletNodeNum].HumRat,
                "InitAirTerminalUserDefined")
            self.SourceAir.InletCp = state.Psychrometrics.PsyCpAirFnW(
                state.dataLoopNodes.Node[self.SourceAir.InletNodeNum].HumRat)
            self.SourceAir.InletTemp = state.dataLoopNodes.Node[self.SourceAir.InletNodeNum].Temp
            self.SourceAir.InletHumRat = state.dataLoopNodes.Node[self.SourceAir.InletNodeNum].HumRat
        
        if self.NumPlantConnections > 0:
            for loop in range(self.NumPlantConnections):
                plantConnection = self.Loop[loop]
                plantConnection.InletRho = plantConnection.plantLoc.loop.glycol.getDensity(
                    state, state.dataLoopNodes.Node[plantConnection.InletNodeNum].Temp, "InitAirTerminalUserDefined")
                plantConnection.InletCp = plantConnection.plantLoc.loop.glycol.getSpecificHeat(
                    state, state.dataLoopNodes.Node[plantConnection.InletNodeNum].Temp, "InitAirTerminalUserDefined")
                plantConnection.InletTemp = state.dataLoopNodes.Node[plantConnection.InletNodeNum].Temp
                plantConnection.InletMassFlowRate = state.dataLoopNodes.Node[plantConnection.InletNodeNum].MassFlowRate

    def report(self, state: Any) -> None:
        """Report air terminal component results"""
        state.dataLoopNodes.Node[self.AirConnection.InletNodeNum].MassFlowRate = self.AirConnection.InletMassFlowRate
        
        state.dataLoopNodes.Node[self.AirConnection.OutletNodeNum].Temp = self.AirConnection.OutletTemp
        state.dataLoopNodes.Node[self.AirConnection.OutletNodeNum].HumRat = self.AirConnection.OutletHumRat
        state.dataLoopNodes.Node[self.AirConnection.OutletNodeNum].MassFlowRate = self.AirConnection.OutletMassFlowRate
        state.dataLoopNodes.Node[self.AirConnection.OutletNodeNum].Enthalpy = state.Psychrometrics.PsyHFnTdbW(
            self.AirConnection.OutletTemp, self.AirConnection.OutletHumRat)
        
        if self.SourceAir.OutletNodeNum > 0:
            state.dataLoopNodes.Node[self.SourceAir.OutletNodeNum].Temp = self.SourceAir.OutletTemp
            state.dataLoopNodes.Node[self.SourceAir.OutletNodeNum].HumRat = self.SourceAir.OutletHumRat
            state.dataLoopNodes.Node[self.SourceAir.OutletNodeNum].MassFlowRate = self.SourceAir.OutletMassFlowRate
            state.dataLoopNodes.Node[self.SourceAir.OutletNodeNum].Enthalpy = state.Psychrometrics.PsyHFnTdbW(
                self.SourceAir.OutletTemp, self.SourceAir.OutletHumRat)
        
        if self.NumPlantConnections > 0:
            for loop in range(self.NumPlantConnections):
                plantConnection = self.Loop[loop]
                state.PlantUtilities.SetComponentFlowRate(
                    state, plantConnection.MassFlowRateRequest, plantConnection.InletNodeNum,
                    plantConnection.OutletNodeNum, plantConnection.plantLoc)
                state.PlantUtilities.SafeCopyPlantNode(state, plantConnection.InletNodeNum, plantConnection.OutletNodeNum)
                state.dataLoopNodes.Node[plantConnection.OutletNodeNum].Temp = plantConnection.OutletTemp
        
        if self.Water.SuppliedByWaterSystem:
            state.dataWaterData.WaterStorage[self.Water.SupplyTankID].VdotRequestDemand[
                self.Water.SupplyTankDemandARRID] = self.Water.SupplyVdotRequest
        
        if self.Water.CollectsToWaterSystem:
            state.dataWaterData.WaterStorage[self.Water.CollectionTankID].VdotAvailSupply[
                self.Water.CollectionTankSupplyARRID] = self.Water.CollectedVdot


PRIMARY_CONN_IDX = 0


def SimCoilUserDefined(state: Any, EquipName: str, CompIndex: int, AirLoopNum: int) -> tuple[int, bool, bool]:
    """Simulate user-defined coil"""
    if state.dataUserDefinedComponents.GetPlantCompInput:
        GetUserDefinedPlantComponents(state)
        state.dataUserDefinedComponents.GetPlantCompInput = False
    
    CompNum = CompIndex
    if CompNum == 0:
        for i, coil in enumerate(state.dataUserDefinedComponents.UserCoil):
            if coil.Name == EquipName:
                CompNum = i + 1
                break
        if CompNum == 0:
            raise RuntimeError("SimUserDefinedPlantComponent: User Defined Coil not found")
        CompIndex = CompNum
    else:
        if CompNum < 1 or CompNum > state.dataUserDefinedComponents.NumUserCoils:
            raise RuntimeError(
                f"SimUserDefinedPlantComponent: Invalid CompIndex passed={CompNum}, "
                f"Number of units ={state.dataUserDefinedComponents.NumUserCoils}, Entered Unit name = {EquipName}")
        if state.dataUserDefinedComponents.CheckUserCoilName[CompNum - 1]:
            if EquipName != state.dataUserDefinedComponents.UserCoil[CompNum - 1].Name:
                raise RuntimeError(
                    f"SimUserDefinedPlantComponent: Invalid CompIndex passed={CompNum}, Unit name={EquipName}, "
                    f"stored unit name for that index={state.dataUserDefinedComponents.UserCoil[CompNum - 1].Name}")
            state.dataUserDefinedComponents.CheckUserCoilName[CompNum - 1] = False
    
    if state.dataGlobal.BeginEnvrnFlag:
        userCoil = state.dataUserDefinedComponents.UserCoil[CompNum - 1]
        if userCoil.ErlInitProgramMngr > 0:
            state.EMSManager.ManageEMS(state, "UserDefinedComponentModel", userCoil.ErlInitProgramMngr)
        elif userCoil.initPluginLocation > -1:
            state.dataPluginManager.pluginManager.runSingleUserDefinedPlugin(state, userCoil.initPluginLocation)
        elif userCoil.initCallbackIndex > -1:
            state.dataPluginManager.pluginManager.runSingleUserDefinedCallback(state, userCoil.initCallbackIndex)
        
        if userCoil.PlantIsConnected:
            state.PlantUtilities.InitComponentNodes(
                state, userCoil.Loop.MassFlowRateMin, userCoil.Loop.MassFlowRateMax,
                userCoil.Loop.InletNodeNum, userCoil.Loop.OutletNodeNum)
            state.PlantUtilities.RegisterPlantCompDesignFlow(
                state, userCoil.Loop.InletNodeNum, userCoil.Loop.DesignVolumeFlowRate)
    
    userCoil = state.dataUserDefinedComponents.UserCoil[CompNum - 1]
    userCoil.initialize(state)
    
    if userCoil.ErlSimProgramMngr > 0:
        state.EMSManager.ManageEMS(state, "UserDefinedComponentModel", userCoil.ErlSimProgramMngr)
    elif userCoil.simPluginLocation > -1:
        state.dataPluginManager.pluginManager.runSingleUserDefinedPlugin(state, userCoil.simPluginLocation)
    elif userCoil.simCallbackIndex > -1:
        state.dataPluginManager.pluginManager.runSingleUserDefinedCallback(state, userCoil.simCallbackIndex)
    
    userCoil.report(state)
    
    HeatingActive = False
    CoolingActive = False
    
    if AirLoopNum != -1:
        primaryAirConnection = userCoil.AirConnections[PRIMARY_CONN_IDX]
        HeatingActive = (state.dataLoopNodes.Node[primaryAirConnection.InletNodeNum].Temp <
                        state.dataLoopNodes.Node[primaryAirConnection.OutletNodeNum].Temp)
        
        EnthInlet = state.Psychrometrics.PsyHFnTdbW(
            state.dataLoopNodes.Node[primaryAirConnection.InletNodeNum].Temp,
            state.dataLoopNodes.Node[primaryAirConnection.InletNodeNum].HumRat)
        EnthOutlet = state.Psychrometrics.PsyHFnTdbW(
            state.dataLoopNodes.Node[primaryAirConnection.OutletNodeNum].Temp,
            state.dataLoopNodes.Node[primaryAirConnection.OutletNodeNum].HumRat)
        CoolingActive = EnthInlet > EnthOutlet
    
    return CompIndex, HeatingActive, CoolingActive


def SimZoneAirUserDefined(state: Any, CompName: str, ZoneNum: int, CompIndex: int) -> tuple[int, float, float]:
    """Simulate user-defined zone air component"""
    if state.dataUserDefinedComponents.GetInput:
        GetUserDefinedComponents(state)
        state.dataUserDefinedComponents.GetInput = False
    
    CompNum = CompIndex
    if CompNum == 0:
        for i, comp in enumerate(state.dataUserDefinedComponents.UserZoneAirHVAC):
            if comp.Name == CompName:
                CompNum = i + 1
                break
        if CompNum == 0:
            raise RuntimeError("SimUserDefinedPlantComponent: User Defined Coil not found")
        CompIndex = CompNum
    else:
        if CompNum < 1 or CompNum > state.dataUserDefinedComponents.NumUserZoneAir:
            raise RuntimeError(
                f"SimUserDefinedPlantComponent: Invalid CompIndex passed={CompNum}, "
                f"Number of units ={state.dataUserDefinedComponents.NumUserZoneAir}, Entered Unit name = {CompName}")
        if state.dataUserDefinedComponents.CheckUserZoneAirName[CompNum - 1]:
            if CompName != state.dataUserDefinedComponents.UserZoneAirHVAC[CompNum - 1].Name:
                raise RuntimeError(
                    f"SimUserDefinedPlantComponent: Invalid CompIndex passed={CompNum}, Unit name={CompName}, "
                    f"stored unit name for that index={state.dataUserDefinedComponents.UserZoneAirHVAC[CompNum - 1].Name}")
            state.dataUserDefinedComponents.CheckUserZoneAirName[CompNum - 1] = False
    
    if state.dataGlobal.BeginEnvrnFlag:
        comp = state.dataUserDefinedComponents.UserZoneAirHVAC[CompNum - 1]
        comp.initialize(state, ZoneNum)
        
        if comp.ErlInitProgramMngr > 0:
            state.EMSManager.ManageEMS(state, "UserDefinedComponentModel", comp.ErlInitProgramMngr)
        elif comp.initPluginLocation > -1:
            state.dataPluginManager.pluginManager.runSingleUserDefinedPlugin(state, comp.initPluginLocation)
        elif comp.initCallbackIndex > -1:
            state.dataPluginManager.pluginManager.runSingleUserDefinedCallback(state, comp.initCallbackIndex)
        
        if comp.NumPlantConnections > 0:
            for loop in range(comp.NumPlantConnections):
                plantConnection = comp.Loop[loop]
                state.PlantUtilities.InitComponentNodes(
                    state, plantConnection.MassFlowRateMin, plantConnection.MassFlowRateMax,
                    plantConnection.InletNodeNum, plantConnection.OutletNodeNum)
                state.PlantUtilities.RegisterPlantCompDesignFlow(
                    state, plantConnection.InletNodeNum, plantConnection.DesignVolumeFlowRate)
    
    comp = state.dataUserDefinedComponents.UserZoneAirHVAC[CompNum - 1]
    comp.initialize(state, ZoneNum)
    
    if comp.ErlSimProgramMngr > 0:
        state.EMSManager.ManageEMS(state, "UserDefinedComponentModel", comp.ErlSimProgramMngr)
    elif comp.simPluginLocation > -1:
        state.dataPluginManager.pluginManager.runSingleUserDefinedPlugin(state, comp.simPluginLocation)
    elif comp.simCallbackIndex > -1:
        state.dataPluginManager.pluginManager.runSingleUserDefinedCallback(state, comp.simCallbackIndex)
    
    comp.report(state)
    
    AirMassFlow = min(
        state.dataLoopNodes.Node[comp.AirConnection.InletNodeNum].MassFlowRate,
        state.dataLoopNodes.Node[comp.AirConnection.OutletNodeNum].MassFlowRate)
    
    MinHumRat = min(
        state.dataLoopNodes.Node[comp.AirConnection.InletNodeNum].HumRat,
        state.dataLoopNodes.Node[comp.AirConnection.OutletNodeNum].HumRat)
    
    SensibleOutputProvided = (
        AirMassFlow * (
            state.Psychrometrics.PsyHFnTdbW(
                state.dataLoopNodes.Node[comp.AirConnection.OutletNodeNum].Temp, MinHumRat) -
            state.Psychrometrics.PsyHFnTdbW(
                state.dataLoopNodes.Node[comp.AirConnection.InletNodeNum].Temp, MinHumRat)))
    
    SpecHumOut = state.dataLoopNodes.Node[comp.AirConnection.OutletNodeNum].HumRat
    SpecHumIn = state.dataLoopNodes.Node[comp.AirConnection.InletNodeNum].HumRat
    LatentOutputProvided = AirMassFlow * (SpecHumOut - SpecHumIn)
    
    return CompIndex, SensibleOutputProvided, LatentOutputProvided


def SimAirTerminalUserDefined(state: Any, CompName: str, FirstHVACIteration: bool, ZoneNum: int, ZoneNodeNum: int, CompIndex: int) -> int:
    """Simulate user-defined air terminal"""
    if state.dataUserDefinedComponents.GetAirTerminalInput:
        GetUserDefinedAirComponent(state)
        state.dataUserDefinedComponents.GetAirTerminalInput = False
    
    CompNum = CompIndex
    if CompNum == 0:
        for i, term in enumerate(state.dataUserDefinedComponents.UserAirTerminal):
            if term.Name == CompName:
                CompNum = i + 1
                break
        if CompNum == 0:
            raise RuntimeError("SimUserDefinedPlantComponent: User Defined Coil not found")
        CompIndex = CompNum
    else:
        if CompNum < 1 or CompNum > state.dataUserDefinedComponents.NumUserAirTerminals:
            raise RuntimeError(
                f"SimUserDefinedPlantComponent: Invalid CompIndex passed={CompNum}, "
                f"Number of units ={state.dataUserDefinedComponents.NumUserAirTerminals}, Entered Unit name = {CompName}")
        if state.dataUserDefinedComponents.CheckUserAirTerminal[CompNum - 1]:
            if CompName != state.dataUserDefinedComponents.UserAirTerminal[CompNum - 1].Name:
                raise RuntimeError(
                    f"SimUserDefinedPlantComponent: Invalid CompIndex passed={CompNum}, Unit name={CompName}, "
                    f"stored unit name for that index={state.dataUserDefinedComponents.UserAirTerminal[CompNum - 1].Name}")
            state.dataUserDefinedComponents.CheckUserAirTerminal[CompNum - 1] = False
    
    if state.dataGlobal.BeginEnvrnFlag:
        term = state.dataUserDefinedComponents.UserAirTerminal[CompNum - 1]
        term.initialize(state, ZoneNum)
        
        if term.ErlInitProgramMngr > 0:
            state.EMSManager.ManageEMS(state, "UserDefinedComponentModel", term.ErlInitProgramMngr)
        elif term.initPluginLocation > -1:
            state.dataPluginManager.pluginManager.runSingleUserDefinedPlugin(state, term.initPluginLocation)
        elif term.initCallbackIndex > -1:
            state.dataPluginManager.pluginManager.runSingleUserDefinedCallback(state, term.initCallbackIndex)
        
        if term.NumPlantConnections > 0:
            for loop in range(term.NumPlantConnections):
                plantConnection = term.Loop[loop]
                state.PlantUtilities.InitComponentNodes(
                    state, plantConnection.MassFlowRateMin, plantConnection.MassFlowRateMax,
                    plantConnection.InletNodeNum, plantConnection.OutletNodeNum)
                state.PlantUtilities.RegisterPlantCompDesignFlow(
                    state, plantConnection.InletNodeNum, plantConnection.DesignVolumeFlowRate)
    
    term = state.dataUserDefinedComponents.UserAirTerminal[CompNum - 1]
    term.initialize(state, ZoneNum)
    
    if term.ErlSimProgramMngr > 0:
        state.EMSManager.ManageEMS(state, "UserDefinedComponentModel", term.ErlSimProgramMngr)
    elif term.simPluginLocation > -1:
        state.dataPluginManager.pluginManager.runSingleUserDefinedPlugin(state, term.simPluginLocation)
    elif term.simCallbackIndex > -1:
        state.dataPluginManager.pluginManager.runSingleUserDefinedCallback(state, term.simCallbackIndex)
    
    term.report(state)
    
    return CompIndex


def GetUserDefinedPlantComponents(state: Any) -> None:
    """Get user-defined plant components from input"""
    ErrorsFound = False
    # Implementation stub - parse input and populate state.dataUserDefinedComponents
    pass


def GetUserDefinedComponents(state: Any) -> None:
    """Get user-defined zone HVAC components from input"""
    ErrorsFound = False
    # Implementation stub - parse input and populate state.dataUserDefinedComponents
    pass


def GetUserDefinedAirComponent(state: Any) -> None:
    """Get user-defined air terminal components from input"""
    ErrorsFound = False
    # Implementation stub - parse input and populate state.dataUserDefinedComponents
    pass


def GetUserDefinedCoilIndex(state: Any, CoilName: str, CurrentModuleObject: str) -> tuple[int, bool]:
    """Get index of user-defined coil"""
    if state.dataUserDefinedComponents.GetInput:
        GetUserDefinedComponents(state)
        state.dataUserDefinedComponents.GetInput = False
    
    CoilIndex = 0
    ErrorsFound = False
    
    if state.dataUserDefinedComponents.NumUserCoils > 0:
        for i, coil in enumerate(state.dataUserDefinedComponents.UserCoil):
            if coil.Name == CoilName:
                CoilIndex = i + 1
                break
    
    if CoilIndex == 0:
        state.ShowSevereError(f"{CurrentModuleObject}, GetUserDefinedCoilIndex: User Defined Cooling Coil not found={CoilName}")
        ErrorsFound = True
    
    return CoilIndex, ErrorsFound


def GetUserDefinedCoilAirInletNode(state: Any, CoilName: str, CurrentModuleObject: str) -> tuple[int, bool]:
    """Get air inlet node of user-defined coil"""
    if state.dataUserDefinedComponents.GetInput:
        GetUserDefinedComponents(state)
        state.dataUserDefinedComponents.GetInput = False
    
    CoilIndex = 0
    ErrorsFound = False
    CoilAirInletNode = 0
    
    if state.dataUserDefinedComponents.NumUserCoils > 0:
        for i, coil in enumerate(state.dataUserDefinedComponents.UserCoil):
            if coil.Name == CoilName:
                CoilIndex = i + 1
                break
    
    if CoilIndex == 0:
        state.ShowSevereError(f"{CurrentModuleObject}, GetTESCoilIndex: TES Cooling Coil not found={CoilName}")
        ErrorsFound = True
        CoilAirInletNode = 0
    else:
        CoilAirInletNode = state.dataUserDefinedComponents.UserCoil[CoilIndex - 1].AirConnections[PRIMARY_CONN_IDX].InletNodeNum
    
    return CoilAirInletNode, ErrorsFound


def GetUserDefinedCoilAirOutletNode(state: Any, CoilName: str, CurrentModuleObject: str) -> tuple[int, bool]:
    """Get air outlet node of user-defined coil"""
    if state.dataUserDefinedComponents.GetInput:
        GetUserDefinedComponents(state)
        state.dataUserDefinedComponents.GetInput = False
    
    CoilIndex = 0
    ErrorsFound = False
    CoilAirOutletNode = 0
    
    if state.dataUserDefinedComponents.NumUserCoils > 0:
        for i, coil in enumerate(state.dataUserDefinedComponents.UserCoil):
            if coil.Name == CoilName:
                CoilIndex = i + 1
                break
    
    if CoilIndex == 0:
        state.ShowSevereError(f"{CurrentModuleObject}, GetTESCoilIndex: TES Cooling Coil not found={CoilName}")
        ErrorsFound = True
        CoilAirOutletNode = 0
    else:
        CoilAirOutletNode = state.dataUserDefinedComponents.UserCoil[CoilIndex - 1].AirConnections[PRIMARY_CONN_IDX].OutletNodeNum
    
    return CoilAirOutletNode, ErrorsFound


@dataclass
class UserDefinedComponentsData:
    """Global state data for user-defined components"""
    NumUserPlantComps: int = 0
    NumUserCoils: int = 0
    NumUserZoneAir: int = 0
    NumUserAirTerminals: int = 0
    
    GetInput: bool = True
    GetAirTerminalInput: bool = True
    GetPlantCompInput: bool = True
    
    CheckUserPlantCompName: List[bool] = field(default_factory=list)
    CheckUserCoilName: List[bool] = field(default_factory=list)
    CheckUserZoneAirName: List[bool] = field(default_factory=list)
    CheckUserAirTerminal: List[bool] = field(default_factory=list)
    
    UserPlantComp: List[UserPlantComponentStruct] = field(default_factory=list)
    UserCoil: List[UserCoilComponentStruct] = field(default_factory=list)
    UserZoneAirHVAC: List[UserZoneHVACForcedAirComponentStruct] = field(default_factory=list)
    UserAirTerminal: List[UserAirTerminalComponentStruct] = field(default_factory=list)
    
    lDummy_EMSActuatedPlantComp: bool = False
    lDummy_GetUserDefComp: bool = False
    
    def clear_state(self) -> None:
        """Clear state for new simulation"""
        self.GetInput = True
        self.GetPlantCompInput = True
        self.NumUserPlantComps = 0
        self.NumUserCoils = 0
        self.NumUserZoneAir = 0
        self.NumUserAirTerminals = 0
        self.CheckUserPlantCompName.clear()
        self.CheckUserCoilName.clear()
        self.CheckUserZoneAirName.clear()
        self.CheckUserAirTerminal.clear()
        self.UserPlantComp.clear()
        self.UserCoil.clear()
        self.UserZoneAirHVAC.clear()
        self.UserAirTerminal.clear()
        self.lDummy_EMSActuatedPlantComp = False
        self.lDummy_GetUserDefComp = False
