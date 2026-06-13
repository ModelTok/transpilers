# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object with dataDuctLoss, dataInputProcessing, dataAirLoop, dataLoopNodes, etc.
# - Util module: makeUPPER, FindItemInList, SameString
# - Sched module: GetSchedule
# - Psychrometrics: PsyCpAirFnW, PsyHFnTdbW
# - General: epexp
# - Constant: Units module
# - OutputProcessor: SetupOutputVariable, TimeStepType, StoreType
# - ShowSevereError, ShowSevereItemNotFound, ShowFatalError: error reporting
# - ErrorObjectHeader: error header class

from memory import memcpy

alias Pi = 3.141592653589793


@value
struct EnvironmentType:
    alias Invalid = -1
    alias Zone = 0
    alias Schedule = 1
    alias Num = 2


@value
struct DuctLossType:
    alias Invalid = -1
    alias Conduction = 0
    alias Leakage = 1
    alias MakeupAir = 2
    alias Num = 3


@value
struct DuctLossSubType:
    alias Invalid = -1
    alias SupplyBranch = 0
    alias SupplyTrunk = 1
    alias ReturnBranch = 2
    alias ReturnTrunk = 3
    alias SupLeakTrunk = 4
    alias SupLeakBranch = 5
    alias RetLeakTrunk = 6
    alias RetLeakBranch = 7
    alias Num = 8


@value
struct AirPath:
    alias Invalid = -1
    alias Supply = 0
    alias Return = 1
    alias Num = 2


@value
struct DuctLossComp:
    var Name: String
    var AirLoopName: String
    var EnvType: Int
    var ZoneName: String
    var ScheduleNameT: String
    var ScheduleNameW: String
    var tambSched: OpaquePointer
    var wambSched: OpaquePointer
    var LossType: Int
    var AirLoopNum: Int
    var LinkageNum: Int
    var ZoneNum: Int
    var LossSubType: Int
    var Qsen: Float64
    var Qlat: Float64
    var QsenSL: Float64
    var QlatSL: Float64
    var RetLeakZoneNum: Int

    fn __init__(inout self) -> None:
        self.Name = ""
        self.AirLoopName = ""
        self.EnvType = EnvironmentType.Invalid
        self.ZoneName = ""
        self.ScheduleNameT = ""
        self.ScheduleNameW = ""
        self.tambSched = OpaquePointer()
        self.wambSched = OpaquePointer()
        self.LossType = DuctLossType.Invalid
        self.AirLoopNum = 0
        self.LinkageNum = 0
        self.ZoneNum = 0
        self.LossSubType = DuctLossSubType.Invalid
        self.Qsen = 0.0
        self.Qlat = 0.0
        self.QsenSL = 0.0
        self.QlatSL = 0.0
        self.RetLeakZoneNum = 0

    fn CalcDuctLoss(inout self, state: OpaquePointer, Index: Int) -> None:
        let thisDuctComp = state.dataDuctLoss.ductloss[Index - 1]
        
        if thisDuctComp.LossType == DuctLossType.Conduction:
            self.CalcConduction(state)
        elif thisDuctComp.LossType == DuctLossType.Leakage:
            self.CalcLeakage(state)
        elif thisDuctComp.LossType == DuctLossType.MakeupAir:
            self.CalcMakeupAir(state)

    fn CalcConduction(inout self, state: OpaquePointer) -> None:
        var MassFlowRate: Float64 = 0.0
        var Tamb: Float64 = 0.0
        var Wamb: Float64 = 0.0
        var Tin: Float64 = 0.0
        var Tout: Float64 = 0.0
        var Win: Float64 = 0.0
        var Wout: Float64 = 0.0
        var CpAir: Float64 = 0.0
        var enthalpy: Float64 = 0.0
        var NodeNum1: Int = 0
        var NodeNum2: Int = 0
        var NodeNum: Int = 0
        
        let TypeNum = state.afn.AirflowNetworkCompData[state.afn.AirflowNetworkLinkageData[self.LinkageNum - 1].CompNum - 1].TypeNum
        let DuctSurfArea = state.afn.DisSysCompDuctData[TypeNum - 1].L * state.afn.DisSysCompDuctData[TypeNum - 1].hydraulicDiameter * Pi
        let UThermal = state.afn.DisSysCompDuctData[TypeNum - 1].UThermConduct
        let UMoisture = state.afn.DisSysCompDuctData[TypeNum - 1].UMoisture
        
        self.Qsen = 0.0
        self.Qlat = 0.0
        
        if self.EnvType == EnvironmentType.Zone and self.ZoneNum > 0:
            Tamb = state.dataZoneTempPredictorCorrector.zoneHeatBalance[self.ZoneNum - 1].MAT
            Wamb = state.dataZoneTempPredictorCorrector.zoneHeatBalance[self.ZoneNum - 1].airHumRat
        else:
            Tamb = self.tambSched.getCurrentVal()
            Wamb = self.wambSched.getCurrentVal()
        
        NodeNum1 = state.afn.AirflowNetworkLinkageData[self.LinkageNum - 1].NodeNums[0]
        NodeNum2 = state.afn.AirflowNetworkLinkageData[self.LinkageNum - 1].NodeNums[1]
        
        if self.LossSubType == DuctLossSubType.SupplyTrunk:
            NodeNum = state.afn.DisSysNodeData[NodeNum1 - 1].EPlusNodeNum
            MassFlowRate = state.dataLoopNodes.Node[NodeNum - 1].MassFlowRate
            Tin = state.dataLoopNodes.Node[NodeNum - 1].Temp
            Win = state.dataLoopNodes.Node[NodeNum - 1].HumRat
            state.afn.AirflowNetworkNodeSimu[NodeNum1 - 1].TZ = Tin
            state.afn.AirflowNetworkNodeSimu[NodeNum1 - 1].WZ = Win
            CpAir = Psychrometrics.PsyCpAirFnW(state.dataLoopNodes.Node[NodeNum - 1].HumRat)
            Tout = Tamb + (Tin - Tamb) * General.epexp(-UThermal * DuctSurfArea, MassFlowRate * CpAir)
            Wout = Wamb + (Win - Wamb) * General.epexp(-UMoisture * DuctSurfArea, MassFlowRate)
            self.Qsen = -MassFlowRate * CpAir * (Tamb - Tin) * (1.0 - General.epexp(-UThermal * DuctSurfArea, MassFlowRate * CpAir))
            self.Qlat = -MassFlowRate * (Wamb - Win) * (1.0 - General.epexp(-UMoisture * DuctSurfArea, MassFlowRate))
            state.afn.AirflowNetworkNodeSimu[NodeNum2 - 1].TZ = Tout
            state.afn.AirflowNetworkNodeSimu[NodeNum2 - 1].WZ = Wout
            if not state.dataDuctLoss.SubTypeSimuFlag[int(DuctLossSubType.SupplyBranch) + 1]:
                enthalpy = Psychrometrics.PsyHFnTdbW(Tout, Wout)
                for OutNodeNum in range(1, state.dataSplitterComponent.SplitterCond[state.dataDuctLoss.SplitterNum - 1].NumOutletNodes + 1):
                    state.dataLoopNodes.Node[state.dataSplitterComponent.SplitterCond[state.dataDuctLoss.SplitterNum - 1].OutletNode[OutNodeNum - 1] - 1].Temp = Tout
                    state.dataLoopNodes.Node[state.dataSplitterComponent.SplitterCond[state.dataDuctLoss.SplitterNum - 1].OutletNode[OutNodeNum - 1] - 1].HumRat = Wout
                    state.dataLoopNodes.Node[state.dataSplitterComponent.SplitterCond[state.dataDuctLoss.SplitterNum - 1].OutletNode[OutNodeNum - 1] - 1].Enthalpy = enthalpy
                    state.dataLoopNodes.Node[state.dataDuctLoss.ZoneEquipInletNodes[OutNodeNum - 1] - 1].Temp = Tout
                    state.dataLoopNodes.Node[state.dataDuctLoss.ZoneEquipInletNodes[OutNodeNum - 1] - 1].HumRat = Wout
                    state.dataLoopNodes.Node[state.dataDuctLoss.ZoneEquipInletNodes[OutNodeNum - 1] - 1].Enthalpy = enthalpy
        elif self.LossSubType == DuctLossSubType.SupplyBranch:
            NodeNum = state.afn.DisSysNodeData[NodeNum2 - 1].EPlusNodeNum
            MassFlowRate = state.dataLoopNodes.Node[NodeNum - 1].MassFlowRate
            if state.dataDuctLoss.SubTypeSimuFlag[int(DuctLossSubType.SupplyTrunk) + 1]:
                Tin = state.afn.AirflowNetworkNodeSimu[NodeNum1 - 1].TZ
                Win = state.afn.AirflowNetworkNodeSimu[NodeNum1 - 1].WZ
            else:
                Tin = state.dataLoopNodes.Node[state.dataDuctLoss.AirLoopInNodeNum - 1].Temp
                Win = state.dataLoopNodes.Node[state.dataDuctLoss.AirLoopInNodeNum - 1].HumRat
            CpAir = Psychrometrics.PsyCpAirFnW(state.dataLoopNodes.Node[NodeNum - 1].HumRat)
            Tout = Tamb + (Tin - Tamb) * General.epexp(-UThermal * DuctSurfArea, MassFlowRate * CpAir)
            Wout = Wamb + (Win - Wamb) * General.epexp(-UMoisture * DuctSurfArea, MassFlowRate)
            self.Qsen = -MassFlowRate * CpAir * (Tamb - Tin) * (1.0 - General.epexp(-UThermal * DuctSurfArea, MassFlowRate * CpAir))
            self.Qlat = -MassFlowRate * (Wamb - Win) * (1.0 - General.epexp(-UMoisture * DuctSurfArea, MassFlowRate))
            state.afn.AirflowNetworkNodeSimu[NodeNum2 - 1].TZ = Tout
            state.afn.AirflowNetworkNodeSimu[NodeNum2 - 1].WZ = Wout
        elif self.LossSubType == DuctLossSubType.ReturnTrunk:
            NodeNum = state.afn.DisSysNodeData[NodeNum2 - 1].EPlusNodeNum
            MassFlowRate = state.dataLoopNodes.Node[NodeNum - 1].MassFlowRate
            if state.dataDuctLoss.SubTypeSimuFlag[int(DuctLossSubType.ReturnBranch) + 1]:
                Tin = state.afn.AirflowNetworkNodeSimu[NodeNum1 - 1].TZ
                Win = state.afn.AirflowNetworkNodeSimu[NodeNum1 - 1].WZ
            else:
                Tin = state.dataMixerComponent.MixerCond[state.dataDuctLoss.MixerNum - 1].OutletTemp
                Win = state.dataMixerComponent.MixerCond[state.dataDuctLoss.MixerNum - 1].OutletHumRat
            CpAir = Psychrometrics.PsyCpAirFnW(state.dataLoopNodes.Node[NodeNum - 1].HumRat)
            Tout = Tamb + (Tin - Tamb) * General.epexp(-UThermal * DuctSurfArea, MassFlowRate * CpAir)
            Wout = Wamb + (Win - Wamb) * General.epexp(-UMoisture * DuctSurfArea, MassFlowRate * CpAir)
            self.Qsen = -MassFlowRate * CpAir * (Tamb - Tin) * (1.0 - General.epexp(-UThermal * DuctSurfArea, MassFlowRate * CpAir))
            self.Qlat = -MassFlowRate * (Wamb - Win) * (1.0 - General.epexp(-UMoisture * DuctSurfArea, MassFlowRate))
            state.afn.AirflowNetworkNodeSimu[NodeNum2 - 1].TZ = Tout
            state.afn.AirflowNetworkNodeSimu[NodeNum2 - 1].WZ = Wout
        elif self.LossSubType == DuctLossSubType.ReturnBranch:
            NodeNum = state.afn.DisSysNodeData[NodeNum1 - 1].EPlusNodeNum
            MassFlowRate = state.dataLoopNodes.Node[NodeNum - 1].MassFlowRate
            Tin = state.dataLoopNodes.Node[NodeNum - 1].Temp
            state.afn.AirflowNetworkNodeSimu[NodeNum1 - 1].TZ = Tin
            Win = state.dataLoopNodes.Node[NodeNum - 1].HumRat
            state.afn.AirflowNetworkNodeSimu[NodeNum1 - 1].WZ = Win
            CpAir = Psychrometrics.PsyCpAirFnW(state.dataLoopNodes.Node[NodeNum - 1].HumRat)
            Tout = Tamb + (Tin - Tamb) * General.epexp(-UThermal * DuctSurfArea, MassFlowRate * CpAir)
            Wout = Wamb + (Win - Wamb) * General.epexp(-UMoisture * DuctSurfArea, MassFlowRate)
            self.Qsen = -MassFlowRate * CpAir * (Tamb - Tin) * (1.0 - General.epexp(-UThermal * DuctSurfArea, MassFlowRate * CpAir))
            self.Qlat = -MassFlowRate * (Wamb - Win) * (1.0 - General.epexp(-UMoisture * DuctSurfArea, MassFlowRate))
            state.afn.AirflowNetworkNodeSimu[NodeNum2 - 1].TZ = Tout
            state.afn.AirflowNetworkNodeSimu[NodeNum2 - 1].WZ = Wout
            if not state.dataDuctLoss.SubTypeSimuFlag[int(DuctLossSubType.ReturnTrunk) + 1]:
                state.dataLoopNodes.Node[state.dataMixerComponent.MixerCond[state.dataDuctLoss.MixerNum - 1].OutletNode - 1].Temp = Tout
                state.dataLoopNodes.Node[state.dataMixerComponent.MixerCond[state.dataDuctLoss.MixerNum - 1].OutletNode - 1].HumRat = Wout

    fn CalcLeakage(inout self, state: OpaquePointer) -> None:
        var MassFlowRate: Float64 = 0.0
        var Tin: Float64 = 0.0
        var Tout: Float64 = 0.0
        var Win: Float64 = 0.0
        var Wout: Float64 = 0.0
        var CpAir: Float64 = 0.0
        let NodeNum1 = state.afn.AirflowNetworkLinkageData[self.LinkageNum - 1].NodeNums[0]
        let NodeNum2 = state.afn.AirflowNetworkLinkageData[self.LinkageNum - 1].NodeNums[1]
        
        let TypeNum = state.afn.AirflowNetworkCompData[state.afn.AirflowNetworkLinkageData[self.LinkageNum - 1].CompNum - 1].TypeNum
        let LeakRatio = state.afn.DisSysCompELRData[TypeNum - 1].ELR
        
        self.Qsen = 0.0
        self.Qlat = 0.0
        self.QsenSL = 0.0
        self.QlatSL = 0.0
        
        if self.LossSubType == DuctLossSubType.SupLeakTrunk:
            Tin = state.afn.AirflowNetworkNodeSimu[NodeNum1 - 1].TZ
            Win = state.afn.AirflowNetworkNodeSimu[NodeNum1 - 1].WZ
            CpAir = Psychrometrics.PsyCpAirFnW(Win)
            MassFlowRate = state.dataLoopNodes.Node[state.dataDuctLoss.AirLoopInNodeNum - 1].MassFlowRate
            self.Qsen = MassFlowRate * CpAir * LeakRatio * (Tin - state.dataZoneTempPredictorCorrector.zoneHeatBalance[state.afn.AirflowNetworkNodeData[NodeNum2 - 1].EPlusZoneNum - 1].MAT)
            self.Qlat = MassFlowRate * LeakRatio * (Win - state.dataZoneTempPredictorCorrector.zoneHeatBalance[state.afn.AirflowNetworkNodeData[NodeNum2 - 1].EPlusZoneNum - 1].airHumRat)
            self.QsenSL = MassFlowRate * CpAir * LeakRatio * (Tin - state.dataZoneTempPredictorCorrector.zoneHeatBalance[state.dataDuctLoss.CtrlZoneNum - 1].MAT)
            self.QlatSL = MassFlowRate * LeakRatio * (Win - state.dataZoneTempPredictorCorrector.zoneHeatBalance[state.dataDuctLoss.CtrlZoneNum - 1].airHumRat)
        elif self.LossSubType == DuctLossSubType.SupLeakBranch:
            Tin = state.afn.AirflowNetworkNodeSimu[NodeNum1 - 1].TZ
            Win = state.afn.AirflowNetworkNodeSimu[NodeNum1 - 1].WZ
            CpAir = Psychrometrics.PsyCpAirFnW(Win)
            MassFlowRate = state.dataLoopNodes.Node[state.dataDuctLoss.AirLoopInNodeNum - 1].MassFlowRate
            self.Qsen = MassFlowRate * CpAir * LeakRatio * (Tin - state.dataZoneTempPredictorCorrector.zoneHeatBalance[state.afn.AirflowNetworkNodeData[NodeNum2 - 1].EPlusZoneNum - 1].MAT)
            self.Qlat = MassFlowRate * LeakRatio * (Win - state.dataZoneTempPredictorCorrector.zoneHeatBalance[state.afn.AirflowNetworkNodeData[NodeNum2 - 1].EPlusZoneNum - 1].airHumRat)
            self.QsenSL = MassFlowRate * CpAir * LeakRatio * (Tin - state.dataZoneTempPredictorCorrector.zoneHeatBalance[state.dataDuctLoss.CtrlZoneNum - 1].MAT)
            self.QlatSL = MassFlowRate * LeakRatio * (Win - state.dataZoneTempPredictorCorrector.zoneHeatBalance[state.dataDuctLoss.CtrlZoneNum - 1].airHumRat)
        elif self.LossSubType == DuctLossSubType.RetLeakTrunk:
            MassFlowRate = state.dataLoopNodes.Node[state.dataDuctLoss.AirLoopInNodeNum - 1].MassFlowRate
            Tout = state.afn.AirflowNetworkNodeSimu[NodeNum2 - 1].TZ * (1.0 - LeakRatio) + state.dataZoneTempPredictorCorrector.zoneHeatBalance[state.afn.AirflowNetworkNodeData[NodeNum1 - 1].EPlusZoneNum - 1].MAT * LeakRatio
            Wout = state.afn.AirflowNetworkNodeSimu[NodeNum2 - 1].WZ * (1.0 - LeakRatio) + state.dataZoneTempPredictorCorrector.zoneHeatBalance[state.afn.AirflowNetworkNodeData[NodeNum1 - 1].EPlusZoneNum - 1].airHumRat * LeakRatio
            CpAir = Psychrometrics.PsyCpAirFnW(Wout)
            self.Qsen = MassFlowRate * CpAir * LeakRatio * (state.dataZoneTempPredictorCorrector.zoneHeatBalance[state.afn.AirflowNetworkNodeData[NodeNum1 - 1].EPlusZoneNum - 1].MAT - state.afn.AirflowNetworkNodeSimu[NodeNum2 - 1].TZ)
            self.Qlat = MassFlowRate * LeakRatio * (state.dataZoneTempPredictorCorrector.zoneHeatBalance[state.afn.AirflowNetworkNodeData[NodeNum1 - 1].EPlusZoneNum - 1].airHumRat - state.afn.AirflowNetworkNodeSimu[NodeNum2 - 1].WZ)
            state.afn.AirflowNetworkNodeSimu[NodeNum2 - 1].TZ = Tout
            state.afn.AirflowNetworkNodeSimu[NodeNum2 - 1].WZ = Wout
        elif self.LossSubType == DuctLossSubType.RetLeakBranch:
            let NodeNum = state.afn.DisSysNodeData[NodeNum2 - 1].EPlusNodeNum
            MassFlowRate = state.dataLoopNodes.Node[NodeNum - 1].MassFlowRate
            Tout = state.dataLoopNodes.Node[self.RetLeakZoneNum - 1].Temp * (1.0 - LeakRatio) + state.dataZoneTempPredictorCorrector.zoneHeatBalance[state.afn.AirflowNetworkNodeData[NodeNum1 - 1].EPlusZoneNum - 1].MAT * LeakRatio
            Wout = state.dataLoopNodes.Node[self.RetLeakZoneNum - 1].HumRat * (1.0 - LeakRatio) + state.dataZoneTempPredictorCorrector.zoneHeatBalance[state.afn.AirflowNetworkNodeData[NodeNum1 - 1].EPlusZoneNum - 1].airHumRat * LeakRatio
            CpAir = Psychrometrics.PsyCpAirFnW((Wout + state.dataLoopNodes.Node[NodeNum - 1].HumRat) / 2.0)
            self.Qsen = MassFlowRate * CpAir * LeakRatio * (state.dataZoneTempPredictorCorrector.zoneHeatBalance[state.afn.AirflowNetworkNodeData[NodeNum1 - 1].EPlusZoneNum - 1].MAT - Tout)
            self.Qlat = MassFlowRate * LeakRatio * (state.dataZoneTempPredictorCorrector.zoneHeatBalance[state.afn.AirflowNetworkNodeData[NodeNum1 - 1].EPlusZoneNum - 1].airHumRat - Wout)
            state.afn.AirflowNetworkNodeSimu[NodeNum2 - 1].TZ = Tout
            state.afn.AirflowNetworkNodeSimu[NodeNum2 - 1].WZ = Wout
            state.dataLoopNodes.Node[NodeNum - 1].Temp = Tout
            state.dataLoopNodes.Node[NodeNum - 1].HumRat = Wout

    fn CalcMakeupAir(inout self, state: OpaquePointer) -> None:
        let NodeNum1 = state.afn.AirflowNetworkLinkageData[self.LinkageNum - 1].NodeNums[0]
        let NodeNum2 = state.afn.AirflowNetworkLinkageData[self.LinkageNum - 1].NodeNums[1]
        
        let TypeNum = state.afn.AirflowNetworkCompData[state.afn.AirflowNetworkLinkageData[self.LinkageNum - 1].CompNum - 1].TypeNum
        let LeakRatio = state.afn.DisSysCompELRData[TypeNum - 1].ELR
        
        self.Qsen = 0.0
        self.Qlat = 0.0
        
        let Tin = state.afn.AirflowNetworkNodeSimu[NodeNum1 - 1].TZ
        let Win = state.afn.AirflowNetworkNodeSimu[NodeNum1 - 1].WZ
        let CpAir = Psychrometrics.PsyCpAirFnW(Win)
        self.Qsen = state.dataLoopNodes.Node[state.dataDuctLoss.AirLoopInNodeNum - 1].MassFlowRate * CpAir * LeakRatio * (Tin - state.dataZoneTempPredictorCorrector.zoneHeatBalance[state.afn.AirflowNetworkNodeData[NodeNum2 - 1].EPlusZoneNum - 1].MAT)
        self.Qlat = state.dataLoopNodes.Node[state.dataDuctLoss.AirLoopInNodeNum - 1].MassFlowRate * LeakRatio * (Win - state.dataZoneTempPredictorCorrector.zoneHeatBalance[state.afn.AirflowNetworkNodeData[NodeNum2 - 1].EPlusZoneNum - 1].airHumRat)
        let ZoneNum = state.afn.AirflowNetworkNodeData[NodeNum2 - 1].EPlusZoneNum
        if ZoneNum > 0:
            state.dataDuctLoss.ZoneSen[ZoneNum - 1] += self.Qsen
            state.dataDuctLoss.ZoneLat[ZoneNum - 1] += self.Qlat


alias cCMO_DuctLossConduction = "Duct:Loss:Conduction"
alias cCMO_DuctLossLeakage = "Duct:Loss:Leakage"
alias cCMO_DuctLossMakeupAir = "Duct:Loss:MakeupAir"


fn SimulateDuctLoss(state: OpaquePointer, AirPathWay: Int = AirPath.Invalid, PathNum: Int = 0) -> None:
    if state.dataDuctLoss.GetDuctLossInputFlag:
        GetDuctLossInput(state)
        state.dataDuctLoss.GetDuctLossInputFlag = False
    
    if PathNum == 0:
        return
    
    if state.dataAirLoop.AirLoopInputsFilled:
        InitDuctLoss(state)
        if state.dataLoopNodes.Node[state.dataDuctLoss.AirLoopInNodeNum - 1].MassFlowRate == 0.0:
            for i in range(len(state.dataDuctLoss.ZoneSen)):
                state.dataDuctLoss.ZoneSen[i] = 0.0
                state.dataDuctLoss.ZoneLat[i] = 0.0
            state.dataDuctLoss.SysSen = 0.0
            state.dataDuctLoss.SysLat = 0.0
            for DuctLossNum in range(1, state.dataDuctLoss.NumOfDuctLosses + 1):
                state.dataDuctLoss.ductloss[DuctLossNum - 1].Qsen = 0.0
                state.dataDuctLoss.ductloss[DuctLossNum - 1].Qlat = 0.0
                state.dataDuctLoss.ductloss[DuctLossNum - 1].QsenSL = 0.0
                state.dataDuctLoss.ductloss[DuctLossNum - 1].QlatSL = 0.0
            return
    
    if not state.dataDuctLoss.AirLoopConnectionFlag and state.dataLoopNodes.Node[state.dataDuctLoss.AirLoopInNodeNum - 1].MassFlowRate > 0.0:
        if AirPathWay == AirPath.Supply:
            for DuctLossNum in range(1, state.dataDuctLoss.NumOfDuctLosses + 1):
                if state.dataDuctLoss.ductloss[DuctLossNum - 1].LossSubType == DuctLossSubType.SupplyTrunk:
                    state.dataDuctLoss.ductloss[DuctLossNum - 1].CalcDuctLoss(state, DuctLossNum)
            for DuctLossNum in range(1, state.dataDuctLoss.NumOfDuctLosses + 1):
                if state.dataDuctLoss.ductloss[DuctLossNum - 1].LossSubType == DuctLossSubType.SupLeakTrunk:
                    state.dataDuctLoss.ductloss[DuctLossNum - 1].CalcDuctLoss(state, DuctLossNum)
            for DuctLossNum in range(1, state.dataDuctLoss.NumOfDuctLosses + 1):
                if state.dataDuctLoss.ductloss[DuctLossNum - 1].LossSubType == DuctLossSubType.SupplyBranch:
                    state.dataDuctLoss.ductloss[DuctLossNum - 1].CalcDuctLoss(state, DuctLossNum)
            for DuctLossNum in range(1, state.dataDuctLoss.NumOfDuctLosses + 1):
                if state.dataDuctLoss.ductloss[DuctLossNum - 1].LossSubType == DuctLossSubType.SupLeakBranch:
                    state.dataDuctLoss.ductloss[DuctLossNum - 1].CalcDuctLoss(state, DuctLossNum)
            SupplyPathUpdate(state, PathNum)
            ReportDuctLoss(state)
        elif AirPathWay == AirPath.Return:
            for DuctLossNum in range(1, state.dataDuctLoss.NumOfDuctLosses + 1):
                if state.dataDuctLoss.ductloss[DuctLossNum - 1].LossSubType == DuctLossSubType.RetLeakBranch:
                    state.dataDuctLoss.ductloss[DuctLossNum - 1].CalcDuctLoss(state, DuctLossNum)
            for DuctLossNum in range(1, state.dataDuctLoss.NumOfDuctLosses + 1):
                if state.dataDuctLoss.ductloss[DuctLossNum - 1].LossSubType == DuctLossSubType.ReturnBranch:
                    state.dataDuctLoss.ductloss[DuctLossNum - 1].CalcDuctLoss(state, DuctLossNum)
            for DuctLossNum in range(1, state.dataDuctLoss.NumOfDuctLosses + 1):
                if state.dataDuctLoss.ductloss[DuctLossNum - 1].LossSubType == DuctLossSubType.RetLeakTrunk:
                    state.dataDuctLoss.ductloss[DuctLossNum - 1].CalcDuctLoss(state, DuctLossNum)
            for DuctLossNum in range(1, state.dataDuctLoss.NumOfDuctLosses + 1):
                if state.dataDuctLoss.ductloss[DuctLossNum - 1].LossSubType == DuctLossSubType.ReturnTrunk:
                    state.dataDuctLoss.ductloss[DuctLossNum - 1].CalcDuctLoss(state, DuctLossNum)
            for DuctLossNum in range(1, state.dataDuctLoss.NumOfDuctLosses + 1):
                if state.dataDuctLoss.ductloss[DuctLossNum - 1].LossType == DuctLossType.MakeupAir:
                    state.dataDuctLoss.ductloss[DuctLossNum - 1].CalcDuctLoss(state, DuctLossNum)
            ReturnPathUpdate(state, PathNum)


fn GetDuctLossInput(state: OpaquePointer) -> None:
    pass


fn InitDuctLoss(state: OpaquePointer) -> None:
    pass


fn ReportDuctLoss(state: OpaquePointer) -> None:
    state.dataDuctLoss.ZoneSen = [0.0] * len(state.dataDuctLoss.ZoneSen)
    state.dataDuctLoss.ZoneLat = [0.0] * len(state.dataDuctLoss.ZoneLat)
    state.dataDuctLoss.SysSen = 0.0
    state.dataDuctLoss.SysLat = 0.0
    
    for DuctLossNum in range(1, state.dataDuctLoss.NumOfDuctLosses + 1):
        if state.dataDuctLoss.ductloss[DuctLossNum - 1].LossType == DuctLossType.Conduction:
            let ZoneNum = state.dataDuctLoss.ductloss[DuctLossNum - 1].ZoneNum
            if ZoneNum > 0:
                state.dataDuctLoss.ZoneSen[ZoneNum - 1] += state.dataDuctLoss.ductloss[DuctLossNum - 1].Qsen
                state.dataDuctLoss.ZoneLat[ZoneNum - 1] += state.dataDuctLoss.ductloss[DuctLossNum - 1].Qlat
            if (state.dataDuctLoss.ductloss[DuctLossNum - 1].LossSubType == DuctLossSubType.SupplyBranch or
                state.dataDuctLoss.ductloss[DuctLossNum - 1].LossSubType == DuctLossSubType.SupplyTrunk):
                state.dataDuctLoss.SysSen += state.dataDuctLoss.ductloss[DuctLossNum - 1].Qsen
                state.dataDuctLoss.SysLat += state.dataDuctLoss.ductloss[DuctLossNum - 1].Qlat
        
        if (state.dataDuctLoss.ductloss[DuctLossNum - 1].LossSubType == DuctLossSubType.SupLeakBranch or
            state.dataDuctLoss.ductloss[DuctLossNum - 1].LossSubType == DuctLossSubType.SupLeakTrunk):
            let ZoneNum = state.afn.AirflowNetworkNodeData[state.afn.AirflowNetworkLinkageData[state.dataDuctLoss.ductloss[DuctLossNum - 1].LinkageNum - 1].NodeNums[1] - 1].EPlusZoneNum
            if ZoneNum > 0:
                state.dataDuctLoss.ZoneSen[ZoneNum - 1] += state.dataDuctLoss.ductloss[DuctLossNum - 1].Qsen
                state.dataDuctLoss.ZoneLat[ZoneNum - 1] += state.dataDuctLoss.ductloss[DuctLossNum - 1].Qlat
            state.dataDuctLoss.SysSen += state.dataDuctLoss.ductloss[DuctLossNum - 1].QsenSL
            state.dataDuctLoss.SysLat += state.dataDuctLoss.ductloss[DuctLossNum - 1].QlatSL
    
    state.dataDuctLoss.ZoneSen[state.dataDuctLoss.CtrlZoneNum - 1] -= state.dataDuctLoss.SysSen
    state.dataDuctLoss.ZoneLat[state.dataDuctLoss.CtrlZoneNum - 1] -= state.dataDuctLoss.SysLat


fn ReturnPathUpdate(state: OpaquePointer, MixerNum: Int) -> None:
    let OutletNode = state.dataMixerComponent.MixerCond[MixerNum - 1].OutletNode
    
    for NodeNum in range(1, state.afn.AirflowNetworkNumOfNodes + 1):
        if state.afn.DisSysNodeData[NodeNum - 1].EPlusNodeNum == OutletNode:
            state.dataLoopNodes.Node[OutletNode - 1].Temp = state.afn.AirflowNetworkNodeSimu[NodeNum - 1].TZ
            state.dataLoopNodes.Node[OutletNode - 1].HumRat = state.afn.AirflowNetworkNodeSimu[NodeNum - 1].WZ
            state.dataLoopNodes.Node[OutletNode - 1].Enthalpy = Psychrometrics.PsyHFnTdbW(state.afn.AirflowNetworkNodeSimu[NodeNum - 1].TZ, state.afn.AirflowNetworkNodeSimu[NodeNum - 1].WZ)
            break
    
    state.dataMixerComponent.MixerCond[MixerNum - 1].OutletTemp = state.dataLoopNodes.Node[OutletNode - 1].Temp
    state.dataMixerComponent.MixerCond[MixerNum - 1].OutletHumRat = state.dataLoopNodes.Node[OutletNode - 1].HumRat
    state.dataMixerComponent.MixerCond[MixerNum - 1].OutletEnthalpy = state.dataLoopNodes.Node[OutletNode - 1].Enthalpy


fn SupplyPathUpdate(state: OpaquePointer, SplitterNum: Int) -> None:
    for NodeNum in range(1, state.afn.AirflowNetworkNumOfNodes + 1):
        for OutletNodeNum in range(1, state.dataSplitterComponent.SplitterCond[SplitterNum - 1].NumOutletNodes + 1):
            if state.afn.DisSysNodeData[NodeNum - 1].EPlusNodeNum == state.dataSplitterComponent.SplitterCond[SplitterNum - 1].OutletNode[OutletNodeNum - 1]:
                state.dataLoopNodes.Node[state.dataSplitterComponent.SplitterCond[SplitterNum - 1].OutletNode[OutletNodeNum - 1] - 1].Temp = state.afn.AirflowNetworkNodeSimu[NodeNum - 1].TZ
                state.dataLoopNodes.Node[state.dataSplitterComponent.SplitterCond[SplitterNum - 1].OutletNode[OutletNodeNum - 1] - 1].HumRat = state.afn.AirflowNetworkNodeSimu[NodeNum - 1].WZ
                state.dataLoopNodes.Node[state.dataSplitterComponent.SplitterCond[SplitterNum - 1].OutletNode[OutletNodeNum - 1] - 1].Enthalpy = Psychrometrics.PsyHFnTdbW(state.afn.AirflowNetworkNodeSimu[NodeNum - 1].TZ, state.afn.AirflowNetworkNodeSimu[NodeNum - 1].WZ)
                if state.afn.DisSysNodeData[NodeNum - 1].EPlusZoneInletNodeNum != state.afn.DisSysNodeData[NodeNum - 1].EPlusNodeNum:
                    state.dataLoopNodes.Node[state.afn.DisSysNodeData[NodeNum - 1].EPlusZoneInletNodeNum - 1].Temp = state.afn.AirflowNetworkNodeSimu[NodeNum - 1].TZ
                    state.dataLoopNodes.Node[state.afn.DisSysNodeData[NodeNum - 1].EPlusZoneInletNodeNum - 1].HumRat = state.afn.AirflowNetworkNodeSimu[NodeNum - 1].WZ
                    state.dataLoopNodes.Node[state.afn.DisSysNodeData[NodeNum - 1].EPlusZoneInletNodeNum - 1].Enthalpy = Psychrometrics.PsyHFnTdbW(state.afn.AirflowNetworkNodeSimu[NodeNum - 1].TZ, state.afn.AirflowNetworkNodeSimu[NodeNum - 1].WZ)
                break
