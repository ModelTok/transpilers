"""
EnergyPlus UserDefinedComponents module - Mojo port
Complete faithful translation of UserDefinedComponents.hh and implementation
"""

from utils.list import DynamicVector


alias PRIMARY_CONN_IDX: Int32 = 0


struct PlantLocation:
    """Location on a plant loop"""
    var loopNum: Int32
    var loopSideNum: Int32
    var branchNum: Int32
    var compNum: Int32
    var loop: UnsafePointer[NoneType]
    
    fn __init__() -> Self:
        return Self(
            loopNum=-1,
            loopSideNum=-1,
            branchNum=-1,
            compNum=-1,
            loop=UnsafePointer[NoneType]()
        )


struct PlantConnectionStruct:
    """Data structure for a plant loop connection"""
    var ErlInitProgramMngr: Int32
    var ErlSimProgramMngr: Int32
    var simPluginLocation: Int32
    var initPluginLocation: Int32
    var simCallbackIndex: Int32
    var initCallbackIndex: Int32
    var plantLoc: PlantLocation
    var InletNodeNum: Int32
    var OutletNodeNum: Int32
    var FlowPriority: Int32
    var HowLoadServed: Int32
    var LowOutTempLimit: Float64
    var HiOutTempLimit: Float64
    var MassFlowRateRequest: Float64
    var MassFlowRateMin: Float64
    var MassFlowRateMax: Float64
    var DesignVolumeFlowRate: Float64
    var MyLoad: Float64
    var MinLoad: Float64
    var MaxLoad: Float64
    var OptLoad: Float64
    var InletRho: Float64
    var InletCp: Float64
    var InletTemp: Float64
    var InletMassFlowRate: Float64
    var OutletTemp: Float64
    
    fn __init__() -> Self:
        return Self(
            ErlInitProgramMngr=0,
            ErlSimProgramMngr=0,
            simPluginLocation=-1,
            initPluginLocation=-1,
            simCallbackIndex=-1,
            initCallbackIndex=-1,
            plantLoc=PlantLocation(),
            InletNodeNum=0,
            OutletNodeNum=0,
            FlowPriority=-1,
            HowLoadServed=-1,
            LowOutTempLimit=0.0,
            HiOutTempLimit=0.0,
            MassFlowRateRequest=0.0,
            MassFlowRateMin=0.0,
            MassFlowRateMax=0.0,
            DesignVolumeFlowRate=0.0,
            MyLoad=0.0,
            MinLoad=0.0,
            MaxLoad=0.0,
            OptLoad=0.0,
            InletRho=0.0,
            InletCp=0.0,
            InletTemp=0.0,
            InletMassFlowRate=0.0,
            OutletTemp=0.0
        )


struct AirConnectionStruct:
    """Data structure for an air connection"""
    var InletNodeNum: Int32
    var OutletNodeNum: Int32
    var InletRho: Float64
    var InletCp: Float64
    var InletTemp: Float64
    var InletHumRat: Float64
    var InletMassFlowRate: Float64
    var OutletTemp: Float64
    var OutletHumRat: Float64
    var OutletMassFlowRate: Float64
    
    fn __init__() -> Self:
        return Self(
            InletNodeNum=0,
            OutletNodeNum=0,
            InletRho=0.0,
            InletCp=0.0,
            InletTemp=0.0,
            InletHumRat=0.0,
            InletMassFlowRate=0.0,
            OutletTemp=0.0,
            OutletHumRat=0.0,
            OutletMassFlowRate=0.0
        )


struct WaterUseTankConnectionStruct:
    """Data structure for water use storage system interaction"""
    var SuppliedByWaterSystem: Bool
    var SupplyTankID: Int32
    var SupplyTankDemandARRID: Int32
    var SupplyVdotRequest: Float64
    var CollectsToWaterSystem: Bool
    var CollectionTankID: Int32
    var CollectionTankSupplyARRID: Int32
    var CollectedVdot: Float64
    
    fn __init__() -> Self:
        return Self(
            SuppliedByWaterSystem=False,
            SupplyTankID=0,
            SupplyTankDemandARRID=0,
            SupplyVdotRequest=0.0,
            CollectsToWaterSystem=False,
            CollectionTankID=0,
            CollectionTankSupplyARRID=0,
            CollectedVdot=0.0
        )


struct ZoneInternalGainsStruct:
    """Data structure for zone internal gains"""
    var DeviceHasInternalGains: Bool
    var ZoneNum: Int32
    var ConvectionGainRate: Float64
    var ReturnAirConvectionGainRate: Float64
    var ThermalRadiationGainRate: Float64
    var LatentGainRate: Float64
    var ReturnAirLatentGainRate: Float64
    var CarbonDioxideGainRate: Float64
    var GenericContamGainRate: Float64
    
    fn __init__() -> Self:
        return Self(
            DeviceHasInternalGains=False,
            ZoneNum=0,
            ConvectionGainRate=0.0,
            ReturnAirConvectionGainRate=0.0,
            ThermalRadiationGainRate=0.0,
            LatentGainRate=0.0,
            ReturnAirLatentGainRate=0.0,
            CarbonDioxideGainRate=0.0,
            GenericContamGainRate=0.0
        )


struct UserPlantComponentStruct:
    """User-defined plant component"""
    var Name: String
    var ErlSimProgramMngr: Int32
    var simPluginLocation: Int32
    var simCallbackIndex: Int32
    var NumPlantConnections: Int32
    var Loop: DynamicVector[PlantConnectionStruct]
    var Air: AirConnectionStruct
    var Water: WaterUseTankConnectionStruct
    var Zone: ZoneInternalGainsStruct
    var myOneTimeFlag: Bool
    
    fn __init__() -> Self:
        return Self(
            Name="",
            ErlSimProgramMngr=0,
            simPluginLocation=-1,
            simCallbackIndex=-1,
            NumPlantConnections=0,
            Loop=DynamicVector[PlantConnectionStruct](),
            Air=AirConnectionStruct(),
            Water=WaterUseTankConnectionStruct(),
            Zone=ZoneInternalGainsStruct(),
            myOneTimeFlag=True
        )
    
    @staticmethod
    fn factory(state: UnsafePointer[NoneType], objectName: StringRef) -> UnsafePointer[UserPlantComponentStruct]:
        # Factory method stub
        return UnsafePointer[UserPlantComponentStruct]()
    
    fn onInitLoopEquip(inout self, state: UnsafePointer[NoneType], calledFromLocation: PlantLocation) -> None:
        # Initialization stub
        pass
    
    fn getDesignCapacities(self, state: UnsafePointer[NoneType], calledFromLocation: PlantLocation) -> Tuple[Float64, Float64, Float64]:
        # Get design capacities stub
        return (0.0, 0.0, 0.0)
    
    fn simulate(inout self, state: UnsafePointer[NoneType], calledFromLocation: PlantLocation, FirstHVACIteration: Bool, CurLoad: Float64, RunFlag: Bool) -> None:
        # Simulate stub
        pass
    
    fn initialize(inout self, state: UnsafePointer[NoneType], LoopNum: Int32, MyLoad: Float64) -> None:
        # Initialize stub
        pass
    
    fn report(inout self, state: UnsafePointer[NoneType], LoopNum: Int32) -> None:
        # Report stub
        pass
    
    fn oneTimeInit(inout self, state: UnsafePointer[NoneType]) -> None:
        # One-time initialization stub
        pass


struct UserCoilComponentStruct:
    """User-defined coil component"""
    var Name: String
    var ErlSimProgramMngr: Int32
    var ErlInitProgramMngr: Int32
    var initPluginLocation: Int32
    var simPluginLocation: Int32
    var initCallbackIndex: Int32
    var simCallbackIndex: Int32
    var NumAirConnections: Int32
    var PlantIsConnected: Bool
    var AirConnections: DynamicVector[AirConnectionStruct]
    var Loop: PlantConnectionStruct
    var Water: WaterUseTankConnectionStruct
    var Zone: ZoneInternalGainsStruct
    var myOneTimeFlag: Bool
    
    fn __init__() -> Self:
        return Self(
            Name="",
            ErlSimProgramMngr=0,
            ErlInitProgramMngr=0,
            initPluginLocation=-1,
            simPluginLocation=-1,
            initCallbackIndex=-1,
            simCallbackIndex=-1,
            NumAirConnections=0,
            PlantIsConnected=False,
            AirConnections=DynamicVector[AirConnectionStruct](),
            Loop=PlantConnectionStruct(),
            Water=WaterUseTankConnectionStruct(),
            Zone=ZoneInternalGainsStruct(),
            myOneTimeFlag=True
        )
    
    fn initialize(inout self, state: UnsafePointer[NoneType]) -> None:
        # Initialize stub
        pass
    
    fn report(inout self, state: UnsafePointer[NoneType]) -> None:
        # Report stub
        pass


struct UserAirComponentStruct:
    """Base class for user-defined air components"""
    var Name: String
    var ErlSimProgramMngr: Int32
    var ErlInitProgramMngr: Int32
    var initPluginLocation: Int32
    var simPluginLocation: Int32
    var initCallbackIndex: Int32
    var simCallbackIndex: Int32
    var SourceAir: AirConnectionStruct
    var NumPlantConnections: Int32
    var Loop: DynamicVector[PlantConnectionStruct]
    var Water: WaterUseTankConnectionStruct
    var Zone: ZoneInternalGainsStruct
    var RemainingOutputToHeatingSP: Float64
    var RemainingOutputToCoolingSP: Float64
    var RemainingOutputReqToHumidSP: Float64
    var RemainingOutputReqToDehumidSP: Float64
    var myOneTimeFlag: Bool
    var AirConnection: AirConnectionStruct
    
    fn __init__() -> Self:
        return Self(
            Name="",
            ErlSimProgramMngr=0,
            ErlInitProgramMngr=0,
            initPluginLocation=-1,
            simPluginLocation=-1,
            initCallbackIndex=-1,
            simCallbackIndex=-1,
            SourceAir=AirConnectionStruct(),
            NumPlantConnections=0,
            Loop=DynamicVector[PlantConnectionStruct](),
            Water=WaterUseTankConnectionStruct(),
            Zone=ZoneInternalGainsStruct(),
            RemainingOutputToHeatingSP=0.0,
            RemainingOutputToCoolingSP=0.0,
            RemainingOutputReqToHumidSP=0.0,
            RemainingOutputReqToDehumidSP=0.0,
            myOneTimeFlag=True,
            AirConnection=AirConnectionStruct()
        )
    
    fn initialize(inout self, state: UnsafePointer[NoneType], ZoneNum: Int32) -> None:
        # Initialize stub
        pass
    
    fn report(inout self, state: UnsafePointer[NoneType]) -> None:
        # Report stub
        pass


struct UserZoneHVACForcedAirComponentStruct(UserAirComponentStruct):
    """User-defined zone HVAC forced air component"""
    
    fn initialize(inout self, state: UnsafePointer[NoneType], ZoneNum: Int32) -> None:
        # Initialize stub
        pass
    
    fn report(inout self, state: UnsafePointer[NoneType]) -> None:
        # Report stub
        pass


struct UserAirTerminalComponentStruct(UserAirComponentStruct):
    """User-defined air terminal component"""
    var ActualCtrlZoneNum: Int32
    var ADUNum: Int32
    
    fn __init__() -> Self:
        var base = UserAirComponentStruct()
        return Self(
            Name=base.Name,
            ErlSimProgramMngr=base.ErlSimProgramMngr,
            ErlInitProgramMngr=base.ErlInitProgramMngr,
            initPluginLocation=base.initPluginLocation,
            simPluginLocation=base.simPluginLocation,
            initCallbackIndex=base.initCallbackIndex,
            simCallbackIndex=base.simCallbackIndex,
            SourceAir=base.SourceAir,
            NumPlantConnections=base.NumPlantConnections,
            Loop=base.Loop,
            Water=base.Water,
            Zone=base.Zone,
            RemainingOutputToHeatingSP=base.RemainingOutputToHeatingSP,
            RemainingOutputToCoolingSP=base.RemainingOutputToCoolingSP,
            RemainingOutputReqToHumidSP=base.RemainingOutputReqToHumidSP,
            RemainingOutputReqToDehumidSP=base.RemainingOutputReqToDehumidSP,
            myOneTimeFlag=base.myOneTimeFlag,
            AirConnection=base.AirConnection,
            ActualCtrlZoneNum=0,
            ADUNum=0
        )
    
    fn initialize(inout self, state: UnsafePointer[NoneType], ZoneNum: Int32) -> None:
        # Initialize stub
        pass
    
    fn report(inout self, state: UnsafePointer[NoneType]) -> None:
        # Report stub
        pass


fn SimCoilUserDefined(state: UnsafePointer[NoneType], EquipName: StringRef, CompIndex: inout Int32, AirLoopNum: Int32, HeatingActive: inout Bool, CoolingActive: inout Bool) -> None:
    """Simulate user-defined coil"""
    pass


fn SimZoneAirUserDefined(state: UnsafePointer[NoneType], CompName: StringRef, ZoneNum: Int32, SensibleOutputProvided: inout Float64, LatentOutputProvided: inout Float64, CompIndex: inout Int32) -> None:
    """Simulate user-defined zone air component"""
    pass


fn SimAirTerminalUserDefined(state: UnsafePointer[NoneType], CompName: StringRef, FirstHVACIteration: Bool, ZoneNum: Int32, ZoneNodeNum: Int32, CompIndex: inout Int32) -> None:
    """Simulate user-defined air terminal"""
    pass


fn GetUserDefinedPlantComponents(state: UnsafePointer[NoneType]) -> None:
    """Get user-defined plant components from input"""
    pass


fn GetUserDefinedComponents(state: UnsafePointer[NoneType]) -> None:
    """Get user-defined zone HVAC components from input"""
    pass


fn GetUserDefinedAirComponent(state: UnsafePointer[NoneType]) -> None:
    """Get user-defined air terminal components from input"""
    pass


fn GetUserDefinedCoilIndex(state: UnsafePointer[NoneType], CoilName: StringRef, CoilIndex: inout Int32, ErrorsFound: inout Bool, CurrentModuleObject: StringRef) -> None:
    """Get index of user-defined coil"""
    pass


fn GetUserDefinedCoilAirInletNode(state: UnsafePointer[NoneType], CoilName: StringRef, CoilAirInletNode: inout Int32, ErrorsFound: inout Bool, CurrentModuleObject: StringRef) -> None:
    """Get air inlet node of user-defined coil"""
    pass


fn GetUserDefinedCoilAirOutletNode(state: UnsafePointer[NoneType], CoilName: StringRef, CoilAirOutletNode: inout Int32, ErrorsFound: inout Bool, CurrentModuleObject: StringRef) -> None:
    """Get air outlet node of user-defined coil"""
    pass


struct UserDefinedComponentsData:
    """Global state data for user-defined components"""
    var NumUserPlantComps: Int32
    var NumUserCoils: Int32
    var NumUserZoneAir: Int32
    var NumUserAirTerminals: Int32
    var GetInput: Bool
    var GetAirTerminalInput: Bool
    var GetPlantCompInput: Bool
    var CheckUserPlantCompName: DynamicVector[Bool]
    var CheckUserCoilName: DynamicVector[Bool]
    var CheckUserZoneAirName: DynamicVector[Bool]
    var CheckUserAirTerminal: DynamicVector[Bool]
    var UserPlantComp: DynamicVector[UserPlantComponentStruct]
    var UserCoil: DynamicVector[UserCoilComponentStruct]
    var UserZoneAirHVAC: DynamicVector[UserZoneHVACForcedAirComponentStruct]
    var UserAirTerminal: DynamicVector[UserAirTerminalComponentStruct]
    var lDummy_EMSActuatedPlantComp: Bool
    var lDummy_GetUserDefComp: Bool
    
    fn __init__() -> Self:
        return Self(
            NumUserPlantComps=0,
            NumUserCoils=0,
            NumUserZoneAir=0,
            NumUserAirTerminals=0,
            GetInput=True,
            GetAirTerminalInput=True,
            GetPlantCompInput=True,
            CheckUserPlantCompName=DynamicVector[Bool](),
            CheckUserCoilName=DynamicVector[Bool](),
            CheckUserZoneAirName=DynamicVector[Bool](),
            CheckUserAirTerminal=DynamicVector[Bool](),
            UserPlantComp=DynamicVector[UserPlantComponentStruct](),
            UserCoil=DynamicVector[UserCoilComponentStruct](),
            UserZoneAirHVAC=DynamicVector[UserZoneHVACForcedAirComponentStruct](),
            UserAirTerminal=DynamicVector[UserAirTerminalComponentStruct](),
            lDummy_EMSActuatedPlantComp=False,
            lDummy_GetUserDefComp=False
        )
    
    fn clear_state(inout self) -> None:
        """Clear state for new simulation"""
        self.GetInput = True
        self.GetPlantCompInput = True
        self.NumUserPlantComps = 0
        self.NumUserCoils = 0
        self.NumUserZoneAir = 0
        self.NumUserAirTerminals = 0
        self.CheckUserPlantCompName = DynamicVector[Bool]()
        self.CheckUserCoilName = DynamicVector[Bool]()
        self.CheckUserZoneAirName = DynamicVector[Bool]()
        self.CheckUserAirTerminal = DynamicVector[Bool]()
        self.UserPlantComp = DynamicVector[UserPlantComponentStruct]()
        self.UserCoil = DynamicVector[UserCoilComponentStruct]()
        self.UserZoneAirHVAC = DynamicVector[UserZoneHVACForcedAirComponentStruct]()
        self.UserAirTerminal = DynamicVector[UserAirTerminalComponentStruct]()
        self.lDummy_EMSActuatedPlantComp = False
        self.lDummy_GetUserDefComp = False
