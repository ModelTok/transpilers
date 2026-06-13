"""
EnergyPlus HVACSingleDuctInduc Module - Mojo Port (continued)
"""

fn SizeIndUnit_continued(inout state: AnyType, IUNum: Int32) -> None:
    var indUnit = state.dataHVACSingleDuctInduc.IndUnit[IUNum - 1]
    var RhoAir = state.dataEnvrn.StdRhoAir
    
    var MaxVolHotWaterFlowDes: Float64 = 0.0
    var MaxVolHotWaterFlowUser: Float64 = 0.0
    var MaxVolColdWaterFlowDes: Float64 = 0.0
    var MaxVolColdWaterFlowUser: Float64 = 0.0

    var IsAutoSize = False
    if indUnit.MaxVolColdWaterFlow == AutoSize:
        IsAutoSize = True

    if state.dataSize.CurZoneEqNum > 0 and state.dataSize.CurTermUnitSizingNum > 0:
        if not IsAutoSize and not state.dataSize.ZoneSizingRunDone:
            if indUnit.MaxVolColdWaterFlow > 0.0:
                reportSizerOutput(
                    state, indUnit.UnitType, indUnit.Name, "User-Specified Maximum Cold Water Flow Rate [m3/s]", indUnit.MaxVolColdWaterFlow
                )
        else:
            CheckZoneSizing(state, indUnit.UnitType, indUnit.Name)

            if SameString(indUnit.CCoilType, "Coil:Cooling:Water") or SameString(indUnit.CCoilType, "Coil:Cooling:Water:DetailedGeometry"):
                var CoilWaterInletNode = GetCoilWaterInletNode(state, indUnit.CCoilType, indUnit.CCoil, ErrorsFound)
                var CoilWaterOutletNode = GetCoilWaterOutletNode(state, indUnit.CCoilType, indUnit.CCoil, ErrorsFound)

                if IsAutoSize:
                    var PltSizCoolNum = MyPlantSizingIndex(
                        state, indUnit.CCoilType, indUnit.CCoil, CoilWaterInletNode, CoilWaterOutletNode, ErrorsFound
                    )
                    if PltSizCoolNum > 0:
                        if state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].DesCoolMassFlow >= SmallAirVolFlow:
                            var DesPriVolFlow = indUnit.MaxTotAirVolFlow / (1.0 + indUnit.InducRatio)
                            var CpAir = PsyCpAirFnW(
                                state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].CoolDesHumRat
                            )

                            var DesCoilLoad: Float64
                            if state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].ZoneTempAtCoolPeak > 0.0:
                                DesCoilLoad = (
                                    state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].NonAirSysDesCoolLoad -
                                    CpAir * RhoAir * DesPriVolFlow *
                                    (state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].ZoneTempAtCoolPeak -
                                     state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].DesCoolCoilInTempTU)
                                )
                            else:
                                DesCoilLoad = (
                                    CpAir * RhoAir * DesPriVolFlow *
                                    (state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].DesCoolCoilInTempTU -
                                     state.dataSize.TermUnitFinalZoneSizing[state.dataSize.CurTermUnitSizingNum].ZoneSizThermSetPtHi)
                                )

                            indUnit.DesCoolingLoad = DesCoilLoad
                            var Cp = indUnit.CWPlantLoc.loop.glycol.getSpecificHeat(state, 5.0, "SizeIndUnit")
                            var rho = indUnit.CWPlantLoc.loop.glycol.getDensity(state, 5.0, "SizeIndUnit")
                            MaxVolColdWaterFlowDes = DesCoilLoad / (state.dataSize.PlantSizData[PltSizCoolNum].DeltaT * Cp * rho)
                            MaxVolColdWaterFlowDes = max(MaxVolColdWaterFlowDes, 0.0)
                        else:
                            MaxVolColdWaterFlowDes = 0.0
                    else:
                        ShowSevereError(state, "Autosizing of water flow requires a cooling loop Sizing:Plant object")
                        ShowContinueError(state, "Occurs in " + indUnit.UnitType + " Object=" + indUnit.Name)
                        var ErrorsFound = True

                    indUnit.MaxVolColdWaterFlow = MaxVolColdWaterFlowDes
                    reportSizerOutput(
                        state, indUnit.UnitType, indUnit.Name, "Design Size Maximum Cold Water Flow Rate [m3/s]", MaxVolColdWaterFlowDes
                    )
                else:
                    if indUnit.MaxVolColdWaterFlow > 0.0 and MaxVolColdWaterFlowDes > 0.0:
                        MaxVolColdWaterFlowUser = indUnit.MaxVolColdWaterFlow
                        reportSizerOutput(
                            state, indUnit.UnitType, indUnit.Name,
                            "Design Size Maximum Cold Water Flow Rate [m3/s]", MaxVolColdWaterFlowDes,
                            "User-Specified Maximum Cold Water Flow Rate [m3/s]", MaxVolColdWaterFlowUser
                        )
                        if state.dataGlobal.DisplayExtraWarnings:
                            if (abs(MaxVolColdWaterFlowDes - MaxVolColdWaterFlowUser) / MaxVolColdWaterFlowUser) > state.dataSize.AutoVsHardSizingThreshold:
                                ShowMessage(
                                    state,
                                    "SizeHVACSingleDuctInduction: Potential issue with equipment sizing for " + indUnit.UnitType + " = \"" + indUnit.Name + "\"."
                                )
                                ShowContinueError(state, "User-Specified Maximum Cold Water Flow Rate of " + str_precision(MaxVolColdWaterFlowUser, 10) + " [m3/s]")
                                ShowContinueError(state, "differs from Design Size Maximum Cold Water Flow Rate of " + str_precision(MaxVolColdWaterFlowDes, 10) + " [m3/s]")
                                ShowContinueError(state, "This may, or may not, indicate mismatched component sizes.")
                                ShowContinueError(state, "Verify that the value entered is intended and is consistent with other components.")
            else:
                indUnit.MaxVolColdWaterFlow = 0.0

    if state.dataSize.CurTermUnitSizingNum > 0:
        var termUnitSizing = state.dataSize.TermUnitSizing[state.dataSize.CurTermUnitSizingNum]
        termUnitSizing.AirVolFlow = indUnit.MaxTotAirVolFlow * indUnit.InducRatio / (1.0 + indUnit.InducRatio)
        termUnitSizing.MaxHWVolFlow = indUnit.MaxVolHotWaterFlow
        termUnitSizing.MaxCWVolFlow = indUnit.MaxVolColdWaterFlow
        termUnitSizing.DesCoolingLoad = indUnit.DesCoolingLoad
        termUnitSizing.DesHeatingLoad = indUnit.DesHeatingLoad
        termUnitSizing.InducRat = indUnit.InducRatio

        if SameString(indUnit.HCoilType, "Coil:Heating:Water"):
            SetCoilDesFlow(state, indUnit.HCoilType, indUnit.HCoil, termUnitSizing.AirVolFlow, ErrorsFound)
        if SameString(indUnit.CCoilType, "Coil:Cooling:Water:DetailedGeometry"):
            SetCoilDesFlow(state, indUnit.CCoilType, indUnit.CCoil, termUnitSizing.AirVolFlow, ErrorsFound)


fn SimFourPipeIndUnit(inout state: AnyType, IUNum: Int32, ZoneNum: Int32, ZoneNodeNum: Int32, FirstHVACIteration: Bool) -> None:
    var SolveMaxIter: Int32 = 50

    var indUnit = state.dataHVACSingleDuctInduc.IndUnit[IUNum - 1]

    var UnitOn = True
    var PowerMet: Float64 = 0.0
    var InducRat = indUnit.InducRatio
    var PriNode = indUnit.PriAirInNode
    var SecNode = indUnit.SecAirInNode
    var OutletNode = indUnit.OutAirNode
    var HotControlNode = indUnit.HWControlNode
    var HWOutletNode = CompData.getPlantComponent(state, indUnit.HWPlantLoc).NodeNumOut
    var ColdControlNode = indUnit.CWControlNode
    var CWOutletNode = CompData.getPlantComponent(state, indUnit.CWPlantLoc).NodeNumOut
    var PriAirMassFlow = state.dataLoopNodes.Node[PriNode].MassFlowRateMaxAvail
    var SecAirMassFlow = InducRat * PriAirMassFlow
    var QToHeatSetPt = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNum].RemainingOutputReqToHeatSP
    var QToCoolSetPt = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNum].RemainingOutputReqToCoolSP

    var MaxHotWaterFlow = indUnit.MaxHotWaterFlow
    SetComponentFlowRate(state, MaxHotWaterFlow, HotControlNode, HWOutletNode, indUnit.HWPlantLoc)

    var MinHotWaterFlow = indUnit.MinHotWaterFlow
    SetComponentFlowRate(state, MinHotWaterFlow, HotControlNode, HWOutletNode, indUnit.HWPlantLoc)

    var MaxColdWaterFlow = indUnit.MaxColdWaterFlow
    SetComponentFlowRate(state, MaxColdWaterFlow, ColdControlNode, CWOutletNode, indUnit.CWPlantLoc)

    var MinColdWaterFlow = indUnit.MinColdWaterFlow
    SetComponentFlowRate(state, MinColdWaterFlow, ColdControlNode, CWOutletNode, indUnit.CWPlantLoc)

    if indUnit.availSched.getCurrentVal() <= 0.0:
        UnitOn = False
    if PriAirMassFlow <= SmallMassFlow:
        UnitOn = False

    state.dataLoopNodes.Node[PriNode].MassFlowRate = PriAirMassFlow
    state.dataLoopNodes.Node[SecNode].MassFlowRate = SecAirMassFlow

    var QPriOnly: Float64
    _, QPriOnly = CalcFourPipeIndUnit(state, IUNum, FirstHVACIteration, ZoneNodeNum, MinHotWaterFlow, MinColdWaterFlow)

    if UnitOn:
        var SolFlag: Int32 = 0
        if QToHeatSetPt - QPriOnly > SmallLoad:
            _, PowerMet = CalcFourPipeIndUnit(state, IUNum, FirstHVACIteration, ZoneNodeNum, MaxHotWaterFlow, MinColdWaterFlow)
            if PowerMet > QToHeatSetPt + SmallLoad:
                var ErrTolerance = indUnit.HotControlOffset
                var HWFlow: Float64 = 0.0

                @always_inline
                fn f(HWFlowVal: Float64) -> Float64:
                    var _, UnitOutput = CalcFourPipeIndUnit(state, IUNum, FirstHVACIteration, ZoneNodeNum, HWFlowVal, MinColdWaterFlow)
                    return (QToHeatSetPt - UnitOutput) / (PowerMet - QPriOnly)

                SolveRoot(state, ErrTolerance, SolveMaxIter, SolFlag, HWFlow, f, MinHotWaterFlow, MaxHotWaterFlow)
                if SolFlag == -1:
                    if indUnit.HWCoilFailNum1 == 0:
                        ShowWarningMessage(
                            state,
                            "SimFourPipeIndUnit: Hot water coil control failed for " + indUnit.UnitType + "=\"" + indUnit.Name + "\""
                        )
                        ShowContinueErrorTimeStamp(state, "")
                        ShowContinueError(state, "  Iteration limit [" + str(SolveMaxIter) + "] exceeded in calculating hot water mass flow rate")
                    ShowRecurringWarningErrorAtEnd(
                        state,
                        "SimFourPipeIndUnit: Hot water coil control failed (iteration limit [" + str(SolveMaxIter) + "]) for " + indUnit.UnitType + "=\"" + indUnit.Name + "\"",
                        indUnit.HWCoilFailNum1
                    )
                elif SolFlag == -2:
                    if indUnit.HWCoilFailNum2 == 0:
                        ShowWarningMessage(
                            state,
                            "SimFourPipeIndUnit: Hot water coil control failed (maximum flow limits) for " + indUnit.UnitType + "=\"" + indUnit.Name + "\""
                        )
                        ShowContinueErrorTimeStamp(state, "")
                        ShowContinueError(state, "...Bad hot water maximum flow rate limits")
                        ShowContinueError(state, "...Given minimum water flow rate=" + str_precision(MinHotWaterFlow, 10) + " kg/s")
                        ShowContinueError(state, "...Given maximum water flow rate=" + str_precision(MaxHotWaterFlow, 10) + " kg/s")
                    ShowRecurringWarningErrorAtEnd(
                        state,
                        "SimFourPipeIndUnit: Hot water coil control failed (flow limits) for " + indUnit.UnitType + "=\"" + indUnit.Name + "\"",
                        indUnit.HWCoilFailNum2,
                        MaxHotWaterFlow,
                        MinHotWaterFlow,
                        units1="[kg/s]",
                        units2="[kg/s]"
                    )
        elif QToCoolSetPt - QPriOnly < -SmallLoad:
            _, PowerMet = CalcFourPipeIndUnit(state, IUNum, FirstHVACIteration, ZoneNodeNum, MinHotWaterFlow, MaxColdWaterFlow)
            if PowerMet < QToCoolSetPt - SmallLoad:
                var ErrTolerance = indUnit.ColdControlOffset
                var CWFlow: Float64 = 0.0

                @always_inline
                fn f(CWFlowVal: Float64) -> Float64:
                    var _, UnitOutput = CalcFourPipeIndUnit(state, IUNum, FirstHVACIteration, ZoneNodeNum, MinHotWaterFlow, CWFlowVal)
                    return (QToCoolSetPt - UnitOutput) / (PowerMet - QPriOnly)

                SolveRoot(state, ErrTolerance, SolveMaxIter, SolFlag, CWFlow, f, MinColdWaterFlow, MaxColdWaterFlow)
                if SolFlag == -1:
                    if indUnit.CWCoilFailNum1 == 0:
                        ShowWarningMessage(
                            state,
                            "SimFourPipeIndUnit: Cold water coil control failed for " + indUnit.UnitType + "=\"" + indUnit.Name + "\""
                        )
                        ShowContinueErrorTimeStamp(state, "")
                        ShowContinueError(state, "  Iteration limit [" + str(SolveMaxIter) + "] exceeded in calculating cold water mass flow rate")
                    ShowRecurringWarningErrorAtEnd(
                        state,
                        "SimFourPipeIndUnit: Cold water coil control failed (iteration limit [" + str(SolveMaxIter) + "]) for " + indUnit.UnitType + "=\"" + indUnit.Name + "\"",
                        indUnit.CWCoilFailNum1
                    )
                elif SolFlag == -2:
                    if indUnit.CWCoilFailNum2 == 0:
                        ShowWarningMessage(
                            state,
                            "SimFourPipeIndUnit: Cold water coil control failed (maximum flow limits) for " + indUnit.UnitType + "=\"" + indUnit.Name + "\""
                        )
                        ShowContinueErrorTimeStamp(state, "")
                        ShowContinueError(state, "...Bad cold water maximum flow rate limits")
                        ShowContinueError(state, "...Given minimum water flow rate=" + str_precision(MinColdWaterFlow, 10) + " kg/s")
                        ShowContinueError(state, "...Given maximum water flow rate=" + str_precision(MaxColdWaterFlow, 10) + " kg/s")
                    ShowRecurringWarningErrorAtEnd(
                        state,
                        "SimFourPipeIndUnit: Cold water coil control failed (flow limits) for " + indUnit.UnitType + "=\"" + indUnit.Name + "\"",
                        indUnit.CWCoilFailNum2,
                        MaxColdWaterFlow,
                        MinColdWaterFlow,
                        units1="[kg/s]",
                        units2="[kg/s]"
                    )
        else:
            _, PowerMet = CalcFourPipeIndUnit(state, IUNum, FirstHVACIteration, ZoneNodeNum, MinHotWaterFlow, MinColdWaterFlow)
    else:
        _, PowerMet = CalcFourPipeIndUnit(state, IUNum, FirstHVACIteration, ZoneNodeNum, MinHotWaterFlow, MinColdWaterFlow)

    state.dataLoopNodes.Node[OutletNode].MassFlowRateMax = indUnit.MaxTotAirMassFlow


fn CalcFourPipeIndUnit(inout state: AnyType, IUNum: Int32, FirstHVACIteration: Bool, ZoneNode: Int32, HWFlow: Float64, CWFlow: Float64) -> Tuple[Int32, Float64]:
    var indUnit = state.dataHVACSingleDuctInduc.IndUnit[IUNum - 1]

    var PriNode = indUnit.PriAirInNode
    var OutletNode = indUnit.OutAirNode
    var PriAirMassFlow = state.dataLoopNodes.Node[PriNode].MassFlowRateMaxAvail
    var InducRat = indUnit.InducRatio
    var SecAirMassFlow = InducRat * PriAirMassFlow
    var TotAirMassFlow = PriAirMassFlow + SecAirMassFlow
    var HotControlNode = indUnit.HWControlNode
    var HWOutletNode = CompData.getPlantComponent(state, indUnit.HWPlantLoc).NodeNumOut
    var ColdControlNode = indUnit.CWControlNode
    var CWOutletNode = CompData.getPlantComponent(state, indUnit.CWPlantLoc).NodeNumOut

    var mdotHW = HWFlow
    SetComponentFlowRate(state, mdotHW, HotControlNode, HWOutletNode, indUnit.HWPlantLoc)

    var mdotCW = CWFlow
    SetComponentFlowRate(state, mdotCW, ColdControlNode, CWOutletNode, indUnit.CWPlantLoc)

    SimulateWaterCoilComponents(state, indUnit.HCoil, FirstHVACIteration, indUnit.HCoil_Num)
    SimulateWaterCoilComponents(state, indUnit.CCoil, FirstHVACIteration, indUnit.CCoil_Num)
    SimAirMixer(state, indUnit.MixerName, indUnit.Mixer_Num)

    var LoadMet = (
        TotAirMassFlow *
        PsyDeltaHSenFnTdb2W2Tdb1W1(
            state.dataLoopNodes.Node[OutletNode].Temp,
            state.dataLoopNodes.Node[OutletNode].HumRat,
            state.dataLoopNodes.Node[ZoneNode].Temp,
            state.dataLoopNodes.Node[ZoneNode].HumRat
        )
    )

    return (0, LoadMet)


fn FourPipeInductionUnitHasMixer(inout state: AnyType, CompName: StringLiteral) -> Bool:
    if state.dataHVACSingleDuctInduc.GetIUInputFlag:
        GetIndUnits(state)
        state.dataHVACSingleDuctInduc.GetIUInputFlag = False

    if state.dataHVACSingleDuctInduc.NumIndUnits > 0:
        for i in range(state.dataHVACSingleDuctInduc.IndUnit.size()):
            if state.dataHVACSingleDuctInduc.IndUnit[i].MixerName == CompName:
                return True

    return False


fn FindItemInList(CompName: StringLiteral, IndUnits: VectorList[IndUnitData]) -> Int32:
    for i in range(IndUnits.size()):
        if IndUnits[i].Name == CompName:
            return i + 1
    return 0


fn GetScheduleAlwaysOn(inout state: AnyType) -> AnyType:
    pass


fn GetSchedule(inout state: AnyType, SchedName: String) -> AnyType:
    pass


fn GetOnlySingleNode(inout state: AnyType, NodeName: String, inout ErrorsFound: Bool, FieldName: String) -> Int32:
    pass


fn SameString(String1: String, String2: String) -> Bool:
    pass


fn GetCoilWaterInletNode(inout state: AnyType, CoilType: String, CoilName: String, inout ErrorsFound: Bool) -> Int32:
    pass


fn GetCoilWaterOutletNode(inout state: AnyType, CoilType: String, CoilName: String, inout ErrorsFound: Bool) -> Int32:
    pass


fn GetZoneMixerIndex(inout state: AnyType, MixerName: String, inout MixerNum: Int32, inout ErrorsFound: Bool, ModuleObject: String) -> None:
    pass


fn SetUpCompSets(inout state: AnyType, CompType: String, CompName: String, SubCompType: String, SubCompName: String, NodeName1: String, NodeName2: String) -> None:
    pass


fn TestCompSet(inout state: AnyType, CompType: String, CompName: String, NodeName1: String, NodeName2: String, Description: String) -> None:
    pass


fn NodeID(NodeNum: Int32) -> String:
    pass


fn SetupOutputVariable(inout state: AnyType, VarName: String, VarUnits: String, inout VarPtr: Float64, TimeStepType: String, StoreType: String, ObjectName: String) -> None:
    pass


fn ShowFatalError(inout state: AnyType, Message: String) -> None:
    pass


fn ShowSevereError(inout state: AnyType, Message: String) -> None:
    pass


fn ShowWarningMessage(inout state: AnyType, Message: String) -> None:
    pass


fn ShowContinueError(inout state: AnyType, Message: String) -> None:
    pass


fn ShowSevereItemNotFound(inout state: AnyType, RoutineName: String, ObjectType: String, ObjectName: String, FieldName: String, FieldValue: String) -> None:
    pass


fn ShowContinueErrorTimeStamp(inout state: AnyType, TimeStamp: String) -> None:
    pass


fn ShowRecurringWarningErrorAtEnd(inout state: AnyType, Message: String, inout ErrorCount: Int32, Arg1: Float64 = 0.0, Arg2: Float64 = 0.0, units1: String = "", units2: String = "") -> None:
    pass


fn ShowMessage(inout state: AnyType, Message: String) -> None:
    pass


fn CheckZoneSizing(inout state: AnyType, CompType: String, CompName: String) -> None:
    pass


fn ScanPlantLoopsForObject(inout state: AnyType, CompName: String, CompType: AnyType, inout PlantLoc: AnyType, inout ErrorsFound: Bool) -> None:
    pass


fn InitComponentNodes(inout state: AnyType, MinFlow: Float64, MaxFlow: Float64, InNode: Int32, OutNode: Int32) -> None:
    pass


fn SetComponentFlowRate(inout state: AnyType, inout Flow: Float64, InNode: Int32, OutNode: Int32, PlantLoc: AnyType) -> None:
    pass


fn MyPlantSizingIndex(inout state: AnyType, CoilType: String, CoilName: String, InNode: Int32, OutNode: Int32, inout ErrorsFound: Bool) -> Int32:
    pass


fn SimulateWaterCoilComponents(inout state: AnyType, CompName: String, FirstHVACIteration: Bool, CompIndex: Int32) -> None:
    pass


fn SimAirMixer(inout state: AnyType, MixerName: String, MixerNum: Int32) -> None:
    pass


fn PsyCpAirFnW(HumRat: Float64) -> Float64:
    pass


fn PsyDeltaHSenFnTdb2W2Tdb1W1(Tdb2: Float64, W2: Float64, Tdb1: Float64, W1: Float64) -> Float64:
    pass


fn str_precision(val: Float64, precision: Int32) -> String:
    pass


fn max(a: Float64, b: Float64) -> Float64:
    if a > b:
        return a
    return b


fn abs(val: Float64) -> Float64:
    if val < 0:
        return -val
    return val


alias HWInitConvTemp = 60.0
alias CWInitConvTemp = 5.0
alias SmallMassFlow = 0.001
alias SmallLoad = 1.0
alias SmallAirVolFlow = 0.001
alias AutoSize = -1.0
alias PlantEquipmentType = Int32

struct CompData:
    @staticmethod
    fn getPlantComponent(inout state: AnyType, PlantLoc: AnyType) -> AnyType:
        pass


struct Tuple[T0, T1]:
    var item0: T0
    var item1: T1
    
    fn __init__(inout self, val0: T0, val1: T1):
        self.item0 = val0
        self.item1 = val1
    
    fn __getitem__(self, index: Int32) -> AnyType:
        if index == 0:
            return self.item0
        return self.item1
