from math import exp, isfinite
from dataclasses import dataclass

alias MAX_EXP_ARG = 700.0
alias RSecsInHour = 3600.0

@dataclass
struct OperatingMode:
    """DataGenerators::OperatingMode"""
    var value: Int32
    
    @staticmethod
    fn Invalid() -> OperatingMode:
        return OperatingMode(-1)
    
    @staticmethod
    fn Off() -> OperatingMode:
        return OperatingMode(0)
    
    @staticmethod
    fn Standby() -> OperatingMode:
        return OperatingMode(1)
    
    @staticmethod
    fn WarmUp() -> OperatingMode:
        return OperatingMode(2)
    
    @staticmethod
    fn Normal() -> OperatingMode:
        return OperatingMode(3)
    
    @staticmethod
    fn CoolDown() -> OperatingMode:
        return OperatingMode(4)


@dataclass
struct LoopSideLocation:
    """DataPlant::LoopSideLocation"""
    var value: Int32
    
    @staticmethod
    fn Supply() -> LoopSideLocation:
        return LoopSideLocation(1)
    
    @staticmethod
    fn Demand() -> LoopSideLocation:
        return LoopSideLocation(2)


@dataclass
struct MicroCHPParamsNonNormalized:
    """Parameters for Micro CHP generator without normalization"""
    var Name: String
    var MaxElecPower: Float64
    var MinElecPower: Float64
    var MinWaterMdot: Float64
    var MaxWaterTemp: Float64
    var ElecEffCurve: AnyPointer
    var ThermalEffCurve: AnyPointer
    var InternalFlowControl: Bool
    var PlantFlowControl: Bool
    var WaterFlowCurve: AnyPointer
    var AirFlowCurve: AnyPointer
    var DeltaPelMax: Float64
    var DeltaFuelMdotMax: Float64
    var UAhx: Float64
    var UAskin: Float64
    var RadiativeFraction: Float64
    var MCeng: Float64
    var MCcw: Float64
    var Pstandby: Float64
    var WarmUpByTimeDelay: Bool
    var WarmUpByEngineTemp: Bool
    var kf: Float64
    var TnomEngOp: Float64
    var kp: Float64
    var Rfuelwarmup: Float64
    var WarmUpDelay: Float64
    var PcoolDown: Float64
    var CoolDownDelay: Float64
    var MandatoryFullCoolDown: Bool
    var WarmRestartOkay: Bool
    var TimeElapsed: Float64
    var OpMode: OperatingMode
    var OffModeTime: Float64
    var StandyByModeTime: Float64
    var WarmUpModeTime: Float64
    var NormalModeTime: Float64
    var CoolDownModeTime: Float64
    var TengLast: Float64
    var TempCWOutLast: Float64
    var Pnet: Float64
    var ElecEff: Float64
    var Qgross: Float64
    var ThermEff: Float64
    var Qgenss: Float64
    var NdotFuel: Float64
    var MdotFuel: Float64
    var Teng: Float64
    var TcwIn: Float64
    var TcwOut: Float64
    var MdotAir: Float64
    var QdotSkin: Float64
    var QdotConvZone: Float64
    var QdotRadZone: Float64
    var ACPowerGen: Float64
    var ACEnergyGen: Float64
    var QdotHX: Float64
    var QdotHR: Float64
    var TotalHeatEnergyRec: Float64
    var FuelEnergyLHV: Float64
    var FuelEnergyUseRateLHV: Float64
    var FuelEnergyHHV: Float64
    var FuelEnergyUseRateHHV: Float64
    var HeatRecInletTemp: Float64
    var HeatRecOutletTemp: Float64
    var FuelCompressPower: Float64
    var FuelCompressEnergy: Float64
    var FuelCompressSkinLoss: Float64
    var SkinLossPower: Float64
    var SkinLossEnergy: Float64
    var SkinLossConvect: Float64
    var SkinLossRadiat: Float64
    
    fn __init__(inout self):
        self.Name = String()
        self.MaxElecPower = 0.0
        self.MinElecPower = 0.0
        self.MinWaterMdot = 0.0
        self.MaxWaterTemp = 0.0
        self.ElecEffCurve = AnyPointer()
        self.ThermalEffCurve = AnyPointer()
        self.InternalFlowControl = False
        self.PlantFlowControl = True
        self.WaterFlowCurve = AnyPointer()
        self.AirFlowCurve = AnyPointer()
        self.DeltaPelMax = 0.0
        self.DeltaFuelMdotMax = 0.0
        self.UAhx = 0.0
        self.UAskin = 0.0
        self.RadiativeFraction = 0.0
        self.MCeng = 0.0
        self.MCcw = 0.0
        self.Pstandby = 0.0
        self.WarmUpByTimeDelay = False
        self.WarmUpByEngineTemp = True
        self.kf = 0.0
        self.TnomEngOp = 0.0
        self.kp = 0.0
        self.Rfuelwarmup = 0.0
        self.WarmUpDelay = 0.0
        self.PcoolDown = 0.0
        self.CoolDownDelay = 0.0
        self.MandatoryFullCoolDown = False
        self.WarmRestartOkay = True
        self.TimeElapsed = 0.0
        self.OpMode = OperatingMode.Invalid()
        self.OffModeTime = 0.0
        self.StandyByModeTime = 0.0
        self.WarmUpModeTime = 0.0
        self.NormalModeTime = 0.0
        self.CoolDownModeTime = 0.0
        self.TengLast = 20.0
        self.TempCWOutLast = 20.0
        self.Pnet = 0.0
        self.ElecEff = 0.0
        self.Qgross = 0.0
        self.ThermEff = 0.0
        self.Qgenss = 0.0
        self.NdotFuel = 0.0
        self.MdotFuel = 0.0
        self.Teng = 20.0
        self.TcwIn = 20.0
        self.TcwOut = 20.0
        self.MdotAir = 0.0
        self.QdotSkin = 0.0
        self.QdotConvZone = 0.0
        self.QdotRadZone = 0.0
        self.ACPowerGen = 0.0
        self.ACEnergyGen = 0.0
        self.QdotHX = 0.0
        self.QdotHR = 0.0
        self.TotalHeatEnergyRec = 0.0
        self.FuelEnergyLHV = 0.0
        self.FuelEnergyUseRateLHV = 0.0
        self.FuelEnergyHHV = 0.0
        self.FuelEnergyUseRateHHV = 0.0
        self.HeatRecInletTemp = 0.0
        self.HeatRecOutletTemp = 0.0
        self.FuelCompressPower = 0.0
        self.FuelCompressEnergy = 0.0
        self.FuelCompressSkinLoss = 0.0
        self.SkinLossPower = 0.0
        self.SkinLossEnergy = 0.0
        self.SkinLossConvect = 0.0
        self.SkinLossRadiat = 0.0


@dataclass
struct MicroCHPDataStruct:
    """Micro CHP Generator data structure"""
    var Name: String
    var ParamObjName: String
    var A42Model: MicroCHPParamsNonNormalized
    var NomEff: Float64
    var ZoneName: String
    var ZoneID: Int32
    var PlantInletNodeName: String
    var PlantInletNodeID: Int32
    var PlantOutletNodeName: String
    var PlantOutletNodeID: Int32
    var PlantMassFlowRate: Float64
    var PlantMassFlowRateMax: Float64
    var PlantMassFlowRateMaxWasAutoSized: Bool
    var AirInletNodeName: String
    var AirInletNodeID: Int32
    var AirOutletNodeName: String
    var AirOutletNodeID: Int32
    var FuelSupplyID: Int32
    var DynamicsControlID: Int32
    var availSched: AnyPointer
    var CWPlantLoc: AnyPointer
    var CheckEquipName: Bool
    var MySizeFlag: Bool
    var MyEnvrnFlag: Bool
    var MyPlantScanFlag: Bool
    var myFlag: Bool
    
    fn __init__(inout self):
        self.Name = String()
        self.ParamObjName = String()
        self.A42Model = MicroCHPParamsNonNormalized()
        self.NomEff = 0.0
        self.ZoneName = String()
        self.ZoneID = 0
        self.PlantInletNodeName = String()
        self.PlantInletNodeID = 0
        self.PlantOutletNodeName = String()
        self.PlantOutletNodeID = 0
        self.PlantMassFlowRate = 0.0
        self.PlantMassFlowRateMax = 0.0
        self.PlantMassFlowRateMaxWasAutoSized = False
        self.AirInletNodeName = String()
        self.AirInletNodeID = 0
        self.AirOutletNodeName = String()
        self.AirOutletNodeID = 0
        self.FuelSupplyID = 0
        self.DynamicsControlID = 0
        self.availSched = AnyPointer()
        self.CWPlantLoc = AnyPointer()
        self.CheckEquipName = True
        self.MySizeFlag = True
        self.MyEnvrnFlag = True
        self.MyPlantScanFlag = True
        self.myFlag = True
    
    fn simulate(
        inout self,
        state: AnyPointer,
        calledFromLocation: AnyPointer,
        FirstHVACIteration: Bool,
        CurLoad: Float64,
        RunFlag: Bool
    ) -> None:
        """Simulate plant component"""
        # Update component heat recovery side stub
        pass
    
    fn getDesignCapacities(
        self,
        state: AnyPointer,
        calledFromLocation: AnyPointer
    ) -> Tuple[Float64, Float64, Float64]:
        """Get design capacities"""
        return (0.0, 0.0, 0.0)
    
    fn onInitLoopEquip(
        inout self,
        state: AnyPointer,
        calledFromLocation: AnyPointer
    ) -> None:
        """Initialize loop equipment"""
        pass
    
    fn setupOutputVars(
        inout self,
        state: AnyPointer
    ) -> None:
        """Setup output variables for reporting"""
        pass
    
    fn InitMicroCHPNoNormalizeGenerators(
        inout self,
        state: AnyPointer
    ) -> None:
        """Initialize Micro CHP generators"""
        self.oneTimeInit(state)
        
        if self.MySizeFlag:
            return
        
        let DynaCntrlNum = self.DynamicsControlID
        
        # Initialize on begin environment
        # Implementation stubs for external state access
    
    fn CalcMicroCHPNoNormalizeGeneratorModel(
        inout self,
        state: AnyPointer,
        RunFlagElectCenter: Bool,
        RunFlagPlant: Bool,
        MyElectricLoad: Float64,
        MyThermalLoad: Float64
    ) -> None:
        """Main calculation for Micro CHP generator"""
        var CurrentOpMode = OperatingMode.Invalid()
        var NdotFuel: Float64 = 0.0
        var AllowedLoad: Float64 = 0.0
        var PLRforSubtimestepStartUp: Float64 = 1.0
        var PLRforSubtimestepShutDown: Float64 = 0.0
        
        # Call external generator dynamics manager
        # Manage generator control state
        
        var Teng = self.A42Model.Teng
        var TcwOut = self.A42Model.TcwOut
        
        var thisAmbientTemp: Float64 = 0.0
        if self.ZoneID > 0:
            # Get zone temperature
            thisAmbientTemp = 20.0  # stub
        else:
            # Get outdoor temperature
            thisAmbientTemp = 20.0  # stub
        
        var Pnetss: Float64 = 0.0
        var Pstandby: Float64 = 0.0
        var Pcooler: Float64 = 0.0
        var ElecEff: Float64 = 0.0
        var MdotAir: Float64 = 0.0
        var Qgenss: Float64 = 0.0
        var MdotCW: Float64 = 0.0
        var TcwIn: Float64 = 0.0
        var MdotFuel: Float64 = 0.0
        var Qgross: Float64 = 0.0
        var ThermEff: Float64 = 0.0
        
        # Mode-based calculations
        if CurrentOpMode.value == OperatingMode.Off().value:
            Qgenss = 0.0
            Pnetss = 0.0
            Pstandby = 0.0
            Pcooler = self.A42Model.PcoolDown * PLRforSubtimestepShutDown
            ElecEff = 0.0
            ThermEff = 0.0
            Qgross = 0.0
            NdotFuel = 0.0
            MdotFuel = 0.0
            MdotAir = 0.0
            MdotCW = 0.0
        elif CurrentOpMode.value == OperatingMode.Standby().value:
            Qgenss = 0.0
            Pnetss = 0.0
            Pstandby = self.A42Model.Pstandby * (1.0 - PLRforSubtimestepShutDown)
            Pcooler = self.A42Model.PcoolDown * PLRforSubtimestepShutDown
            ElecEff = 0.0
            ThermEff = 0.0
            Qgross = 0.0
            NdotFuel = 0.0
            MdotFuel = 0.0
            MdotAir = 0.0
            MdotCW = 0.0
        elif CurrentOpMode.value == OperatingMode.WarmUp().value:
            if self.A42Model.WarmUpByTimeDelay:
                Pnetss = MyElectricLoad
                Pstandby = 0.0
                Pcooler = self.A42Model.PcoolDown * PLRforSubtimestepShutDown
            elif self.A42Model.WarmUpByEngineTemp:
                let Pmax = self.A42Model.MaxElecPower
                Pstandby = 0.0
                Pcooler = self.A42Model.PcoolDown * PLRforSubtimestepShutDown
        elif CurrentOpMode.value == OperatingMode.Normal().value:
            if PLRforSubtimestepStartUp < 1.0:
                if RunFlagElectCenter:
                    Pnetss = MyElectricLoad
                if RunFlagPlant:
                    Pnetss = AllowedLoad
            else:
                Pnetss = AllowedLoad
            Pstandby = 0.0
            Pcooler = 0.0
        elif CurrentOpMode.value == OperatingMode.CoolDown().value:
            Pnetss = 0.0
            Pstandby = 0.0
            Pcooler = self.A42Model.PcoolDown
        
        # Iterative energy balance check
        for i in range(20):
            let dt: Float64 = 0.0  # state.dataHVACGlobal.TimeStepSysSec
            
            Teng = FuncDetermineEngineTemp(
                TcwOut, self.A42Model.MCeng, self.A42Model.UAhx,
                self.A42Model.UAskin, thisAmbientTemp, Qgenss,
                self.A42Model.TengLast, dt
            )
            
            TcwOut = FuncDetermineCoolantWaterExitTemp(
                TcwIn, self.A42Model.MCcw, self.A42Model.UAhx,
                MdotCW, Teng, self.A42Model.TempCWOutLast, dt
            )
            
            let EnergyBalOK = CheckMicroCHPThermalBalance(
                self.A42Model.MaxElecPower, TcwIn, TcwOut, Teng,
                thisAmbientTemp, self.A42Model.UAhx, self.A42Model.UAskin,
                Qgenss, self.A42Model.MCeng, self.A42Model.MCcw,
                MdotCW
            )
            
            if EnergyBalOK and i > 3:
                break
        
        self.PlantMassFlowRate = MdotCW
        self.A42Model.Pnet = Pnetss - Pcooler - Pstandby
        self.A42Model.ElecEff = ElecEff
        self.A42Model.Qgross = Qgross
        self.A42Model.ThermEff = ThermEff
        self.A42Model.Qgenss = Qgenss
        self.A42Model.NdotFuel = NdotFuel
        self.A42Model.MdotFuel = MdotFuel
        self.A42Model.Teng = Teng
        self.A42Model.TcwOut = TcwOut
        self.A42Model.TcwIn = TcwIn
        self.A42Model.MdotAir = MdotAir
        self.A42Model.QdotSkin = self.A42Model.UAskin * (Teng - thisAmbientTemp)
        self.A42Model.OpMode = CurrentOpMode
    
    fn CalcUpdateHeatRecovery(self, state: AnyPointer) -> None:
        """Update heat recovery"""
        pass
    
    fn UpdateMicroCHPGeneratorRecords(inout self, state: AnyPointer) -> None:
        """Update generator records"""
        self.A42Model.ACPowerGen = self.A42Model.Pnet
        self.A42Model.ACEnergyGen = self.A42Model.Pnet * 1.0  # TimeStepSysSec
        self.A42Model.QdotHX = self.A42Model.UAhx * (self.A42Model.Teng - self.A42Model.TcwOut)
        
        let Cp: Float64 = 1.0  # stub for glycol specific heat
        
        self.A42Model.QdotHR = self.PlantMassFlowRate * Cp * (self.A42Model.TcwOut - self.A42Model.TcwIn)
        self.A42Model.TotalHeatEnergyRec = self.A42Model.QdotHR * 1.0  # TimeStepSysSec
        
        self.A42Model.HeatRecInletTemp = self.A42Model.TcwIn
        self.A42Model.HeatRecOutletTemp = self.A42Model.TcwOut
        
        self.A42Model.FuelCompressPower = 0.0
        self.A42Model.FuelCompressEnergy = 0.0
        self.A42Model.FuelCompressSkinLoss = 0.0
        
        self.A42Model.FuelEnergyHHV = 0.0
        self.A42Model.FuelEnergyUseRateHHV = 0.0
        self.A42Model.FuelEnergyLHV = 0.0
        self.A42Model.FuelEnergyUseRateLHV = 0.0
        
        self.A42Model.SkinLossPower = self.A42Model.QdotConvZone + self.A42Model.QdotRadZone
        self.A42Model.SkinLossEnergy = (self.A42Model.QdotConvZone + self.A42Model.QdotRadZone) * 1.0
        self.A42Model.SkinLossConvect = self.A42Model.QdotConvZone
        self.A42Model.SkinLossRadiat = self.A42Model.QdotRadZone
        
        if self.AirInletNodeID > 0:
            pass  # Update node
        if self.AirOutletNodeID > 0:
            pass  # Update node
    
    fn oneTimeInit(inout self, state: AnyPointer) -> None:
        """One-time initialization"""
        if self.myFlag:
            self.setupOutputVars(state)
            self.myFlag = False
        
        if self.MyPlantScanFlag:
            self.MyPlantScanFlag = False


fn GetMicroCHPGeneratorInput(state: AnyPointer) -> None:
    """Get input for Micro CHP generators"""
    pass


fn FuncDetermineEngineTemp(
    TcwOut: Float64,
    MCeng: Float64,
    UAHX: Float64,
    UAskin: Float64,
    Troom: Float64,
    Qgenss: Float64,
    TengLast: Float64,
    time: Float64
) -> Float64:
    """Determine engine temperature"""
    let a = ((UAHX * TcwOut / MCeng) + (UAskin * Troom / MCeng) + (Qgenss / MCeng))
    let b = ((-1.0 * UAHX / MCeng) + (-1.0 * UAskin / MCeng))
    return (TengLast + a / b) * exp(b * time) - a / b


fn FuncDetermineCoolantWaterExitTemp(
    TcwIn: Float64,
    MCcw: Float64,
    UAHX: Float64,
    MdotCpcw: Float64,
    Teng: Float64,
    TcwoutLast: Float64,
    time: Float64
) -> Float64:
    """Determine coolant water exit temperature"""
    let a = (MdotCpcw * TcwIn / MCcw) + (UAHX * Teng / MCcw)
    let b = ((-1.0 * MdotCpcw / MCcw) + (-1.0 * UAHX / MCcw))
    
    if b * time < (-1.0 * MAX_EXP_ARG):
        return -a / b
    return (TcwoutLast + a / b) * exp(b * time) - a / b


fn CheckMicroCHPThermalBalance(
    NomHeatGen: Float64,
    TcwIn: Float64,
    TcwOut: Float64,
    Teng: Float64,
    Troom: Float64,
    UAHX: Float64,
    UAskin: Float64,
    Qgenss: Float64,
    MCeng: Float64,
    MCcw: Float64,
    MdotCpcw: Float64
) -> Bool:
    """Check Micro CHP thermal balance"""
    let a = ((UAHX * TcwOut / MCeng) + (UAskin * Troom / MCeng) + (Qgenss / MCeng))
    let b = ((-1.0 * UAHX / MCeng) + (-1.0 * UAskin / MCeng))
    let DTengDTime = a + b * Teng
    
    let c = (MdotCpcw * TcwIn / MCcw) + (UAHX * Teng / MCcw)
    let d = ((-1.0 * MdotCpcw / MCcw) + (-1.0 * UAHX / MCcw))
    let DCoolOutTDtime = c + d * TcwOut
    
    let magImbalEng = UAHX * (TcwOut - Teng) + UAskin * (Troom - Teng) + Qgenss - MCeng * DTengDTime
    let magImbalCooling = MdotCpcw * (TcwIn - TcwOut) + UAHX * (Teng - TcwOut) - MCcw * DCoolOutTDtime
    
    let threshold = NomHeatGen / 10000000.0
    
    return (threshold > magImbalEng) and (threshold > magImbalCooling)


fn FigureMicroCHPZoneGains(state: AnyPointer) -> None:
    """Figure Micro CHP zone gains"""
    pass
