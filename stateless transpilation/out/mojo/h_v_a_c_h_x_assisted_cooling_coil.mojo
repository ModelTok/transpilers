from math import fabs


struct HXAssistedCoilParameters:
    var hxAssistedCoilType: Int32
    var Name: String
    var coolCoilType: Int32
    var CoolingCoilName: String
    var CoolingCoilIndex: Int32
    var DXCoilNumOfSpeeds: Int32
    var hxType: Int32
    var HeatExchangerName: String
    var HeatExchangerIndex: Int32
    var HXAssistedCoilInletNodeNum: Int32
    var HXAssistedCoilOutletNodeNum: Int32
    var HXExhaustAirInletNodeNum: Int32
    var MassFlowRate: Float64
    var MaxIterCounter: Int32
    var MaxIterIndex: Int32
    var ControllerIndex: Int32
    var ControllerName: String

    fn __init__(inout self):
        self.hxAssistedCoilType = 0
        self.Name = ""
        self.coolCoilType = 0
        self.CoolingCoilName = ""
        self.CoolingCoilIndex = 0
        self.DXCoilNumOfSpeeds = 0
        self.hxType = 0
        self.HeatExchangerName = ""
        self.HeatExchangerIndex = 0
        self.HXAssistedCoilInletNodeNum = 0
        self.HXAssistedCoilOutletNodeNum = 0
        self.HXExhaustAirInletNodeNum = 0
        self.MassFlowRate = 0.0
        self.MaxIterCounter = 0
        self.MaxIterIndex = 0
        self.ControllerIndex = 0
        self.ControllerName = ""


struct HVACHXAssistedCoolingCoilData:
    var TotalNumHXAssistedCoils: Int32
    var HXAssistedCoilOutletTemp: List[Float64]
    var HXAssistedCoilOutletHumRat: List[Float64]
    var GetCoilsInputFlag: Bool
    var CheckEquipName: List[Bool]
    var HXAssistedCoil: List[HXAssistedCoilParameters]
    var UniqueHXAssistedCoilNames: Dict[String, String]
    var CoilOutputTempLast: Float64
    var ErrCount: Int32
    var ErrCount2: Int32

    fn __init__(inout self):
        self.TotalNumHXAssistedCoils = 0
        self.HXAssistedCoilOutletTemp = List[Float64]()
        self.HXAssistedCoilOutletHumRat = List[Float64]()
        self.GetCoilsInputFlag = True
        self.CheckEquipName = List[Bool]()
        self.HXAssistedCoil = List[HXAssistedCoilParameters]()
        self.UniqueHXAssistedCoilNames = Dict[String, String]()
        self.CoilOutputTempLast = 0.0
        self.ErrCount = 0
        self.ErrCount2 = 0

    fn clear_state(inout self):
        self.TotalNumHXAssistedCoils = 0
        self.HXAssistedCoilOutletTemp = List[Float64]()
        self.HXAssistedCoilOutletHumRat = List[Float64]()
        self.GetCoilsInputFlag = True
        self.CheckEquipName = List[Bool]()
        self.HXAssistedCoil = List[HXAssistedCoilParameters]()
        self.UniqueHXAssistedCoilNames = Dict[String, String]()
        self.CoilOutputTempLast = 0.0
        self.ErrCount = 0
        self.ErrCount2 = 0


fn SimHXAssistedCoolingCoil(
    state: AnyType,
    HXAssistedCoilName: String,
    FirstHVACIteration: Bool,
    compressorOp: Int32,
    PartLoadRatio: Float64,
    inout CompIndex: Int32,
    fanOp: Int32,
    HXUnitEnable: Optional[Bool] = None,
    OnOffAFR: Optional[Float64] = None,
    EconomizerFlag: Optional[Bool] = None,
    QTotOut: Optional[Float64] = None,
    DehumidificationMode: Optional[Int32] = None,
    LoadSHR: Optional[Float64] = None,
) -> Int32:
    if state.dataHVACAssistedCC.GetCoilsInputFlag:
        GetHXAssistedCoolingCoilInput(state)
        state.dataHVACAssistedCC.GetCoilsInputFlag = False

    var HXAssistedCoilNum: Int32
    if CompIndex == 0:
        HXAssistedCoilNum = find_item_in_list(
            HXAssistedCoilName, state.dataHVACAssistedCC.HXAssistedCoil
        )
        if HXAssistedCoilNum == -1:
            @always_inline
            fn format_error() -> String:
                return String("HX Assisted Coil not found=") + HXAssistedCoilName
            raise_error(format_error())
        HXAssistedCoilNum += 1
        CompIndex = HXAssistedCoilNum
    else:
        HXAssistedCoilNum = CompIndex
        if (
            HXAssistedCoilNum
            > state.dataHVACAssistedCC.TotalNumHXAssistedCoils
            or HXAssistedCoilNum < 1
        ):
            @always_inline
            fn format_error2() -> String:
                var s = String("SimHXAssistedCoolingCoil: Invalid CompIndex passed=")
                s += str(HXAssistedCoilNum)
                s += String(", Number of HX Assisted Cooling Coils=")
                s += str(state.dataHVACAssistedCC.TotalNumHXAssistedCoils)
                s += String(", Coil name=")
                s += HXAssistedCoilName
                return s
            raise_error(format_error2())
        if state.dataHVACAssistedCC.CheckEquipName[int(HXAssistedCoilNum - 1)]:
            if (
                HXAssistedCoilName != ""
                and HXAssistedCoilName
                != state.dataHVACAssistedCC.HXAssistedCoil[int(HXAssistedCoilNum - 1)].Name
            ):
                @always_inline
                fn format_error3() -> String:
                    var s = String("SimHXAssistedCoolingCoil: Invalid CompIndex passed=")
                    s += str(HXAssistedCoilNum)
                    s += String(", Coil name=")
                    s += HXAssistedCoilName
                    s += String(", stored Coil Name for that index=")
                    s += state.dataHVACAssistedCC.HXAssistedCoil[int(HXAssistedCoilNum - 1)].Name
                    return s
                raise_error(format_error3())
            state.dataHVACAssistedCC.CheckEquipName[int(HXAssistedCoilNum - 1)] = False

    InitHXAssistedCoolingCoil(state, HXAssistedCoilNum)

    var HXUnitOn: Bool
    if HXUnitEnable is not None:
        HXUnitOn = HXUnitEnable.value()
    else:
        HXUnitOn = True

    if compressorOp == 0:
        HXUnitOn = False

    var AirFlowRatio: Float64
    if OnOffAFR is not None:
        AirFlowRatio = OnOffAFR.value()
    else:
        AirFlowRatio = 1.0

    if (
        DehumidificationMode is not None
        and LoadSHR is not None
        and state.dataHVACAssistedCC.HXAssistedCoil[int(HXAssistedCoilNum - 1)].coolCoilType
        == 1
    ):
        CalcHXAssistedCoolingCoil(
            state,
            HXAssistedCoilNum,
            FirstHVACIteration,
            compressorOp,
            PartLoadRatio,
            HXUnitOn,
            fanOp,
            AirFlowRatio,
            EconomizerFlag,
            DehumidificationMode,
            LoadSHR,
        )
    else:
        CalcHXAssistedCoolingCoil(
            state,
            HXAssistedCoilNum,
            FirstHVACIteration,
            compressorOp,
            PartLoadRatio,
            HXUnitOn,
            fanOp,
            AirFlowRatio,
            EconomizerFlag,
        )

    if QTotOut is not None:
        var InletNodeNum = state.dataHVACAssistedCC.HXAssistedCoil[
            int(HXAssistedCoilNum - 1)
        ].HXAssistedCoilInletNodeNum
        var OutletNodeNum = state.dataHVACAssistedCC.HXAssistedCoil[
            int(HXAssistedCoilNum - 1)
        ].HXAssistedCoilOutletNodeNum
        var AirMassFlow = state.dataLoopNodes.Node[int(OutletNodeNum - 1)].MassFlowRate
        var qt = AirMassFlow * (
            state.dataLoopNodes.Node[int(InletNodeNum - 1)].Enthalpy
            - state.dataLoopNodes.Node[int(OutletNodeNum - 1)].Enthalpy
        )

    return CompIndex


fn GetHXAssistedCoolingCoilInput(state: AnyType):
    var num_hx_dx_coils = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, "CoilSystem:Cooling:DX:HeatExchangerAssisted"
    )
    var num_hx_water_coils = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, "CoilSystem:Cooling:Water:HeatExchangerAssisted"
    )
    state.dataHVACAssistedCC.TotalNumHXAssistedCoils = (
        num_hx_dx_coils + num_hx_water_coils
    )

    if state.dataHVACAssistedCC.TotalNumHXAssistedCoils > 0:
        for _ in range(state.dataHVACAssistedCC.TotalNumHXAssistedCoils):
            state.dataHVACAssistedCC.HXAssistedCoil.append(
                HXAssistedCoilParameters()
            )
            state.dataHVACAssistedCC.HXAssistedCoilOutletTemp.append(0.0)
            state.dataHVACAssistedCC.HXAssistedCoilOutletHumRat.append(0.0)
            state.dataHVACAssistedCC.CheckEquipName.append(True)

    for hx_coil_num in range(1, num_hx_dx_coils + 1):
        var this_hx_coil = state.dataHVACAssistedCC.HXAssistedCoil[hx_coil_num - 1]
        var alph_array = state.dataInputProcessing.inputProcessor.getObjectItem(
            state,
            "CoilSystem:Cooling:DX:HeatExchangerAssisted",
            hx_coil_num,
        )

        this_hx_coil.Name = alph_array[0]
        this_hx_coil.hxType = get_enum_value_hx_type(alph_array[1])
        this_hx_coil.HeatExchangerName = alph_array[2]
        this_hx_coil.CoolingCoilName = alph_array[4]

        if alph_array[3].upper() == "COIL:COOLING:DX":
            this_hx_coil.coolCoilType = 1
            this_hx_coil.hxAssistedCoilType = 17
            var cooling_coil_index_temp = state.dataCoilCoolingDX.factory(
                state, this_hx_coil.CoolingCoilName
            )
            this_hx_coil.CoolingCoilIndex = cooling_coil_index_temp
            if cooling_coil_index_temp < 0:
                raise_error("Cooling coil not found: " + this_hx_coil.CoolingCoilName)
            this_hx_coil.DXCoilNumOfSpeeds = (
                state.dataCoilCoolingDX.coilCoolingDXs[
                    int(cooling_coil_index_temp)
                ].performance.numSpeeds()
            )

        elif alph_array[3].upper() == "COIL:COOLING:DX:SINGLESPEED":
            this_hx_coil.coolCoilType = 2
            this_hx_coil.hxAssistedCoilType = 17
            DXCoils_GetDXCoilIndex(
                state, this_hx_coil.CoolingCoilName, this_hx_coil.CoolingCoilIndex
            )

        elif alph_array[3].upper() == "COIL:COOLING:DX:VARIABLESPEED":
            this_hx_coil.coolCoilType = 3
            this_hx_coil.hxAssistedCoilType = 17
            this_hx_coil.CoolingCoilIndex = (
                VariableSpeedCoils_GetCoilIndexVariableSpeed(
                    state, alph_array[3], alph_array[4]
                )
            )
            this_hx_coil.DXCoilNumOfSpeeds = (
                VariableSpeedCoils_GetVSCoilNumOfSpeeds(
                    state, this_hx_coil.CoolingCoilName
                )
            )

        var supply_air_inlet_node = HeatRecovery_GetSupplyInletNode(
            state, this_hx_coil.HeatExchangerName
        )
        var supply_air_outlet_node = HeatRecovery_GetSupplyOutletNode(
            state, this_hx_coil.HeatExchangerName
        )
        var secondary_air_inlet_node = HeatRecovery_GetSecondaryInletNode(
            state, this_hx_coil.HeatExchangerName
        )
        var secondary_air_outlet_node = HeatRecovery_GetSecondaryOutletNode(
            state, this_hx_coil.HeatExchangerName
        )

        this_hx_coil.HXAssistedCoilInletNodeNum = supply_air_inlet_node
        this_hx_coil.HXExhaustAirInletNodeNum = secondary_air_inlet_node
        this_hx_coil.HXAssistedCoilOutletNodeNum = secondary_air_outlet_node

    for hx_coil_num in range(
        num_hx_dx_coils + 1,
        state.dataHVACAssistedCC.TotalNumHXAssistedCoils + 1,
    ):
        var this_water_hx_num = hx_coil_num - num_hx_dx_coils
        var this_hx_coil = state.dataHVACAssistedCC.HXAssistedCoil[hx_coil_num - 1]

        var alph_array = state.dataInputProcessing.inputProcessor.getObjectItem(
            state,
            "CoilSystem:Cooling:Water:HeatExchangerAssisted",
            this_water_hx_num,
        )

        this_hx_coil.Name = alph_array[0]
        this_hx_coil.hxType = get_enum_value_hx_type(alph_array[1])
        this_hx_coil.HeatExchangerName = alph_array[2]
        this_hx_coil.CoolingCoilName = alph_array[4]

        if (
            alph_array[3].upper() == "COIL:COOLING:WATER"
            or alph_array[3].upper() == "COIL:COOLING:WATER:DETAILEDGEOMETRY"
        ):
            if alph_array[3].upper() == "COIL:COOLING:WATER:DETAILEDGEOMETRY":
                this_hx_coil.coolCoilType = 5
            else:
                this_hx_coil.coolCoilType = 4
            this_hx_coil.hxAssistedCoilType = 18

        var supply_air_inlet_node = HeatRecovery_GetSupplyInletNode(
            state, this_hx_coil.HeatExchangerName
        )
        var supply_air_outlet_node = HeatRecovery_GetSupplyOutletNode(
            state, this_hx_coil.HeatExchangerName
        )
        var secondary_air_inlet_node = HeatRecovery_GetSecondaryInletNode(
            state, this_hx_coil.HeatExchangerName
        )
        var secondary_air_outlet_node = HeatRecovery_GetSecondaryOutletNode(
            state, this_hx_coil.HeatExchangerName
        )

        this_hx_coil.HXAssistedCoilInletNodeNum = supply_air_inlet_node
        this_hx_coil.HXExhaustAirInletNodeNum = secondary_air_inlet_node
        this_hx_coil.HXAssistedCoilOutletNodeNum = secondary_air_outlet_node


fn InitHXAssistedCoolingCoil(state: AnyType, HXAssistedCoilNum: Int32):
    var this_hx_coil = state.dataHVACAssistedCC.HXAssistedCoil[
        int(HXAssistedCoilNum - 1)
    ]
    this_hx_coil.MassFlowRate = state.dataLoopNodes.Node[
        int(this_hx_coil.HXAssistedCoilInletNodeNum - 1)
    ].MassFlowRate


fn CalcHXAssistedCoolingCoil(
    state: AnyType,
    HXAssistedCoilNum: Int32,
    FirstHVACIteration: Bool,
    compressorOp: Int32,
    PartLoadRatio: Float64,
    HXUnitOn: Bool,
    fanOp: Int32,
    OnOffAirFlow: Optional[Float64] = None,
    EconomizerFlag: Optional[Bool] = None,
    DehumidificationMode: Optional[Int32] = None,
    LoadSHR: Optional[Float64] = None,
):
    var MAX_ITER: Int32 = 50

    var this_hx_coil = state.dataHVACAssistedCC.HXAssistedCoil[
        int(HXAssistedCoilNum - 1)
    ]
    var AirMassFlow = this_hx_coil.MassFlowRate
    var Error: Float64 = 1.0
    var ErrorLast: Float64 = Error
    var Iter: Int32 = 0

    state.dataLoopNodes.Node[
        int(this_hx_coil.HXExhaustAirInletNodeNum - 1)
    ].MassFlowRate = AirMassFlow

    var CompanionCoilIndexNum: Int32
    if this_hx_coil.coolCoilType in [1, 2, 3]:
        CompanionCoilIndexNum = this_hx_coil.CoolingCoilIndex
    else:
        CompanionCoilIndexNum = 0

    if PartLoadRatio == 0.0:
        state.dataLoopNodes.Node[
            int(this_hx_coil.HXExhaustAirInletNodeNum - 1)
        ].Temp = state.dataLoopNodes.Node[
            int(this_hx_coil.HXAssistedCoilInletNodeNum - 1)
        ].Temp
        state.dataLoopNodes.Node[
            int(this_hx_coil.HXExhaustAirInletNodeNum - 1)
        ].HumRat = state.dataLoopNodes.Node[
            int(this_hx_coil.HXAssistedCoilInletNodeNum - 1)
        ].HumRat
        state.dataLoopNodes.Node[
            int(this_hx_coil.HXExhaustAirInletNodeNum - 1)
        ].Enthalpy = state.dataLoopNodes.Node[
            int(this_hx_coil.HXAssistedCoilInletNodeNum - 1)
        ].Enthalpy
        state.dataLoopNodes.Node[
            int(this_hx_coil.HXExhaustAirInletNodeNum - 1)
        ].MassFlowRate = state.dataLoopNodes.Node[
            int(this_hx_coil.HXAssistedCoilInletNodeNum - 1)
        ].MassFlowRate

    while (fabs(Error) > 0.0005 and Iter <= MAX_ITER) or Iter < 2:
        HeatRecovery_SimHeatRecovery(
            state,
            this_hx_coil.HeatExchangerName,
            FirstHVACIteration,
            this_hx_coil.HeatExchangerIndex,
            fanOp,
            PartLoadRatio,
            HXUnitOn,
            CompanionCoilIndexNum,
            EconomizerFlag,
            this_hx_coil.coolCoilType,
        )

        if this_hx_coil.coolCoilType == 1:
            var coolingCoilIndex = this_hx_coil.CoolingCoilIndex
            var m_single_mode = (
                state.dataCoilCoolingDX.coilCoolingDXs[
                    int(coolingCoilIndex)
                ].getNumModes()
            )
            var single_mode = m_single_mode == 1

            var m_cooling_speed_num = (
                state.dataCoilCoolingDX.coilCoolingDXs[
                    int(coolingCoilIndex)
                ].performance.numSpeeds()
            )

            var coil_mode: Int32 = 0
            if (
                state.dataCoilCoolingDX.coilCoolingDXs[
                    int(coolingCoilIndex)
                ].subcoolReheatFlag
            ):
                coil_mode = 2
            elif DehumidificationMode is not None and DehumidificationMode.value() == 1:
                coil_mode = 1

            var CoilPLR: Float64 = 1.0
            if compressorOp == 0:
                m_cooling_speed_num = 1
            else:
                if single_mode:
                    CoilPLR = PartLoadRatio if m_cooling_speed_num == 1 else 0.0
                else:
                    CoilPLR = PartLoadRatio

            state.dataCoilCoolingDX.coilCoolingDXs[
                int(this_hx_coil.CoolingCoilIndex)
            ].simulate(
                state, coil_mode, m_cooling_speed_num, CoilPLR, fanOp, single_mode
            )

        elif this_hx_coil.coolCoilType == 2:
            DXCoils_SimDXCoil(
                state,
                this_hx_coil.CoolingCoilName,
                compressorOp,
                FirstHVACIteration,
                this_hx_coil.CoolingCoilIndex,
                fanOp,
                PartLoadRatio,
                OnOffAirFlow,
            )

        elif this_hx_coil.coolCoilType == 3:
            var QZnReq: Float64 = -1.0
            var QLatReq: Float64 = 0.0
            var OnOffAirFlowRatio: Float64 = 1.0
            var compressor_on = compressorOp
            if PartLoadRatio == 0.0:
                compressor_on = 0

            VariableSpeedCoils_SimVariableSpeedCoils(
                state,
                this_hx_coil.CoolingCoilName,
                this_hx_coil.CoolingCoilIndex,
                fanOp,
                compressor_on,
                PartLoadRatio,
                this_hx_coil.DXCoilNumOfSpeeds,
                QZnReq,
                QLatReq,
                OnOffAirFlowRatio,
            )

        else:
            WaterCoils_SimulateWaterCoilComponents(
                state,
                this_hx_coil.CoolingCoilName,
                FirstHVACIteration,
                this_hx_coil.CoolingCoilIndex,
            )

        Error = (
            state.dataHVACAssistedCC.CoilOutputTempLast
            - state.dataLoopNodes.Node[
                int(this_hx_coil.HXExhaustAirInletNodeNum - 1)
            ].Temp
        )
        if Iter > 40:
            if Error + ErrorLast < 0.000001:
                Error = 0.0

        ErrorLast = Error
        state.dataHVACAssistedCC.CoilOutputTempLast = state.dataLoopNodes.Node[
            int(this_hx_coil.HXExhaustAirInletNodeNum - 1)
        ].Temp
        Iter += 1

    if Iter > MAX_ITER:
        if this_hx_coil.MaxIterCounter < 1:
            this_hx_coil.MaxIterCounter += 1

    state.dataHVACAssistedCC.HXAssistedCoilOutletTemp[
        int(HXAssistedCoilNum - 1)
    ] = state.dataLoopNodes.Node[
        int(this_hx_coil.HXAssistedCoilOutletNodeNum - 1)
    ].Temp
    state.dataHVACAssistedCC.HXAssistedCoilOutletHumRat[
        int(HXAssistedCoilNum - 1)
    ] = state.dataLoopNodes.Node[
        int(this_hx_coil.HXAssistedCoilOutletNodeNum - 1)
    ].HumRat


fn GetHXDXCoilIndex(
    state: AnyType, HXDXCoilName: String, CurrentModuleObject: String = ""
) -> Int32:
    if state.dataHVACAssistedCC.GetCoilsInputFlag:
        GetHXAssistedCoolingCoilInput(state)
        state.dataHVACAssistedCC.GetCoilsInputFlag = False

    var HXDXCoilIndex: Int32
    if state.dataHVACAssistedCC.TotalNumHXAssistedCoils > 0:
        HXDXCoilIndex = find_item(
            HXDXCoilName, state.dataHVACAssistedCC.HXAssistedCoil
        )
    else:
        HXDXCoilIndex = -1

    if HXDXCoilIndex == -1:
        if CurrentModuleObject != "":
            raise_error(
                CurrentModuleObject
                + ", GetHXDXCoilIndex: HX Assisted Cooling Coil not found="
                + HXDXCoilName
            )
        else:
            raise_error(
                "GetHXDXCoilIndex: HX Assisted Cooling Coil not found="
                + HXDXCoilName
            )

    return HXDXCoilIndex + 1


fn CheckHXAssistedCoolingCoilSchedule(
    state: AnyType, CompType: String, CompName: String, inout CompIndex: Int32
) -> Float64:
    if state.dataHVACAssistedCC.GetCoilsInputFlag:
        GetHXAssistedCoolingCoilInput(state)
        state.dataHVACAssistedCC.GetCoilsInputFlag = False

    var HXAssistedCoilNum: Int32
    var Value: Float64

    if CompIndex == 0:
        if state.dataHVACAssistedCC.TotalNumHXAssistedCoils > 0:
            HXAssistedCoilNum = find_item(
                CompName, state.dataHVACAssistedCC.HXAssistedCoil
            )
        else:
            HXAssistedCoilNum = -1

        if HXAssistedCoilNum == -1:
            raise_error(
                "CheckHXAssistedCoolingCoilSchedule: HX Assisted Coil not found="
                + CompName
            )
        CompIndex = HXAssistedCoilNum + 1
        Value = 1.0
    else:
        HXAssistedCoilNum = CompIndex - 1
        if (
            HXAssistedCoilNum
            >= state.dataHVACAssistedCC.TotalNumHXAssistedCoils
            or HXAssistedCoilNum < 0
        ):
            raise_error(
                "CheckHXAssistedCoolingCoilSchedule: Invalid CompIndex passed="
                + str(CompIndex)
            )
        if (
            CompName
            != state.dataHVACAssistedCC.HXAssistedCoil[int(HXAssistedCoilNum)].Name
        ):
            raise_error(
                "CheckHXAssistedCoolingCoilSchedule: Invalid CompIndex passed="
                + str(CompIndex)
            )
        Value = 1.0

    return Value


fn GetCoilCapacity(
    state: AnyType, CoilType: String, CoilName: String
) -> Float64:
    if state.dataHVACAssistedCC.GetCoilsInputFlag:
        GetHXAssistedCoolingCoilInput(state)
        state.dataHVACAssistedCC.GetCoilsInputFlag = False

    var CoilCapacity: Float64 = 0.0

    var WhichCoil: Int32 = -1
    if state.dataHVACAssistedCC.TotalNumHXAssistedCoils > 0:
        WhichCoil = find_item(
            CoilName, state.dataHVACAssistedCC.HXAssistedCoil
        )

    if CoilType.upper() == "COILSYSTEM:COOLING:DX:HEATEXCHANGERASSISTED":
        if WhichCoil != -1:
            if (
                state.dataHVACAssistedCC.HXAssistedCoil[int(WhichCoil)].coolCoilType
                == 1
            ):
                var coolingCoilDXIndex = (
                    state.dataHVACAssistedCC.HXAssistedCoil[int(WhichCoil)].CoolingCoilIndex
                )
                CoilCapacity = (
                    state.dataCoilCoolingDX.coilCoolingDXs[int(coolingCoilDXIndex)].performance.ratedGrossTotalCap()
                )

    elif CoilType.upper() == "COILSYSTEM:COOLING:WATER:HEATEXCHANGERASSISTED":
        if WhichCoil != -1:
            CoilCapacity = WaterCoils_GetWaterCoilCapacity(
                state,
                get_coil_type_name(
                    state.dataHVACAssistedCC.HXAssistedCoil[int(WhichCoil)].coolCoilType
                ),
                state.dataHVACAssistedCC.HXAssistedCoil[int(WhichCoil)].CoolingCoilName,
            )

    if WhichCoil == -1:
        raise_error('GetCoilCapacity: Could not find Coil, Type="' + CoilType + '" Name="' + CoilName + '"')

    return CoilCapacity


fn GetCoilGroupTypeNum(
    state: AnyType, CoilType: String, CoilName: String, PrintWarning: Bool = True
) -> Int32:
    if state.dataHVACAssistedCC.GetCoilsInputFlag:
        GetHXAssistedCoolingCoilInput(state)
        state.dataHVACAssistedCC.GetCoilsInputFlag = False

    var WhichCoil: Int32 = -1
    if state.dataHVACAssistedCC.TotalNumHXAssistedCoils > 0:
        WhichCoil = find_item(
            CoilName, state.dataHVACAssistedCC.HXAssistedCoil
        )

    if WhichCoil != -1:
        return state.dataHVACAssistedCC.HXAssistedCoil[int(WhichCoil)].hxAssistedCoilType

    if PrintWarning:
        raise_error('GetCoilGroupTypeNum: Could not find Coil, Type="' + CoilType + '" Name="' + CoilName + '"')
    return 0


fn GetCoilObjectTypeNum(
    state: AnyType, CoilType: String, CoilName: String, PrintWarning: Bool = True
) -> Int32:
    if state.dataHVACAssistedCC.GetCoilsInputFlag:
        GetHXAssistedCoolingCoilInput(state)
        state.dataHVACAssistedCC.GetCoilsInputFlag = False

    var WhichCoil: Int32 = -1
    if state.dataHVACAssistedCC.TotalNumHXAssistedCoils > 0:
        WhichCoil = find_item(
            CoilName, state.dataHVACAssistedCC.HXAssistedCoil
        )

    if WhichCoil != -1:
        return state.dataHVACAssistedCC.HXAssistedCoil[int(WhichCoil)].coolCoilType

    if PrintWarning:
        raise_error('GetCoilObjectTypeNum: Could not find Coil, Type="' + CoilType + '" Name="' + CoilName + '"')
    return 0


fn GetCoilInletNode(
    state: AnyType, CoilType: String, CoilName: String
) -> Int32:
    if state.dataHVACAssistedCC.GetCoilsInputFlag:
        GetHXAssistedCoolingCoilInput(state)
        state.dataHVACAssistedCC.GetCoilsInputFlag = False

    var WhichCoil: Int32 = -1
    if state.dataHVACAssistedCC.TotalNumHXAssistedCoils > 0:
        WhichCoil = find_item(
            CoilName, state.dataHVACAssistedCC.HXAssistedCoil
        )

    if WhichCoil != -1:
        return state.dataHVACAssistedCC.HXAssistedCoil[int(WhichCoil)].HXAssistedCoilInletNodeNum

    raise_error('GetCoilInletNode: Could not find Coil, Type="' + CoilType + '" Name="' + CoilName + '"')
    return 0


fn GetCoilWaterInletNode(
    state: AnyType, CoilType: String, CoilName: String
) -> Int32:
    if state.dataHVACAssistedCC.GetCoilsInputFlag:
        GetHXAssistedCoolingCoilInput(state)
        state.dataHVACAssistedCC.GetCoilsInputFlag = False

    var WhichCoil: Int32 = -1
    if state.dataHVACAssistedCC.TotalNumHXAssistedCoils > 0:
        WhichCoil = find_item(
            CoilName, state.dataHVACAssistedCC.HXAssistedCoil
        )

    var NodeNumber: Int32 = 0
    if WhichCoil != -1:
        if (
            state.dataHVACAssistedCC.HXAssistedCoil[int(WhichCoil)].coolCoilType
            == 4
        ):
            NodeNumber = WaterCoils_GetCoilWaterInletNode(
                state,
                get_coil_type_name(
                    state.dataHVACAssistedCC.HXAssistedCoil[int(WhichCoil)].coolCoilType
                ),
                state.dataHVACAssistedCC.HXAssistedCoil[int(WhichCoil)].CoolingCoilName,
            )
        elif (
            state.dataHVACAssistedCC.HXAssistedCoil[int(WhichCoil)].coolCoilType
            == 5
        ):
            NodeNumber = WaterCoils_GetCoilWaterInletNode(
                state,
                get_coil_type_name(
                    state.dataHVACAssistedCC.HXAssistedCoil[int(WhichCoil)].coolCoilType
                ),
                state.dataHVACAssistedCC.HXAssistedCoil[int(WhichCoil)].CoolingCoilName,
            )
        else:
            raise_error('GetCoilWaterInletNode: Invalid Cooling Coil for HX Assisted Coil')
        return NodeNumber
    else:
        raise_error('GetCoilWaterInletNode: Could not find Coil, Type="' + CoilType + '" Name="' + CoilName + '"')
        return 0


fn GetCoilOutletNode(
    state: AnyType, CoilType: String, CoilName: String
) -> Int32:
    if state.dataHVACAssistedCC.GetCoilsInputFlag:
        GetHXAssistedCoolingCoilInput(state)
        state.dataHVACAssistedCC.GetCoilsInputFlag = False

    var WhichCoil: Int32 = -1
    if state.dataHVACAssistedCC.TotalNumHXAssistedCoils > 0:
        WhichCoil = find_item(
            CoilName, state.dataHVACAssistedCC.HXAssistedCoil
        )

    if WhichCoil != -1:
        return state.dataHVACAssistedCC.HXAssistedCoil[int(WhichCoil)].HXAssistedCoilOutletNodeNum

    raise_error('GetCoilOutletNode: Could not find Coil, Type="' + CoilType + '" Name="' + CoilName + '"')
    return 0


fn GetHXDXCoilType(
    state: AnyType, CoilType: String, CoilName: String
) -> String:
    if state.dataHVACAssistedCC.GetCoilsInputFlag:
        GetHXAssistedCoolingCoilInput(state)
        state.dataHVACAssistedCC.GetCoilsInputFlag = False

    var WhichCoil: Int32 = -1
    if state.dataHVACAssistedCC.TotalNumHXAssistedCoils > 0:
        WhichCoil = find_item(
            CoilName, state.dataHVACAssistedCC.HXAssistedCoil
        )

    if WhichCoil != -1:
        return get_coil_type_name(
            state.dataHVACAssistedCC.HXAssistedCoil[int(WhichCoil)].coolCoilType
        )

    raise_error('Could not find Coil, Type="' + CoilType + '" Name="' + CoilName + '"')
    return ""


fn GetHXDXCoilName(
    state: AnyType, CoilType: String, CoilName: String
) -> String:
    if state.dataHVACAssistedCC.GetCoilsInputFlag:
        GetHXAssistedCoolingCoilInput(state)
        state.dataHVACAssistedCC.GetCoilsInputFlag = False

    var WhichCoil: Int32 = -1
    if state.dataHVACAssistedCC.TotalNumHXAssistedCoils > 0:
        WhichCoil = find_item(
            CoilName, state.dataHVACAssistedCC.HXAssistedCoil
        )

    if WhichCoil != -1:
        return state.dataHVACAssistedCC.HXAssistedCoil[int(WhichCoil)].CoolingCoilName

    raise_error('Could not find Coil, Type="' + CoilType + '" Name="' + CoilName + '"')
    return ""


fn GetActualDXCoilIndex(
    state: AnyType, CoilType: String, CoilName: String
) -> Int32:
    if state.dataHVACAssistedCC.GetCoilsInputFlag:
        GetHXAssistedCoolingCoilInput(state)
        state.dataHVACAssistedCC.GetCoilsInputFlag = False

    var WhichCoil: Int32 = -1
    if state.dataHVACAssistedCC.TotalNumHXAssistedCoils > 0:
        WhichCoil = find_item(
            CoilName, state.dataHVACAssistedCC.HXAssistedCoil
        )

    if WhichCoil != -1:
        return state.dataHVACAssistedCC.HXAssistedCoil[int(WhichCoil)].CoolingCoilIndex

    raise_error('Could not find Coil, Type="' + CoilType + '" Name="' + CoilName + '"')
    return 0


fn GetHXCoilType(
    state: AnyType, CoilType: String, CoilName: String
) -> String:
    if state.dataHVACAssistedCC.GetCoilsInputFlag:
        GetHXAssistedCoolingCoilInput(state)
        state.dataHVACAssistedCC.GetCoilsInputFlag = False

    var WhichCoil: Int32 = -1
    if state.dataHVACAssistedCC.TotalNumHXAssistedCoils > 0:
        WhichCoil = find_item(
            CoilName, state.dataHVACAssistedCC.HXAssistedCoil
        )

    if WhichCoil != -1:
        return get_coil_type_name(
            state.dataHVACAssistedCC.HXAssistedCoil[int(WhichCoil)].coolCoilType
        )

    raise_error('Could not find Coil, Type="' + CoilType + '" Name="' + CoilName + '"')
    return ""


fn GetHXCoilTypeAndName(
    state: AnyType, CoilType: String, CoilName: String
) -> Tuple[String, String]:
    if state.dataHVACAssistedCC.GetCoilsInputFlag:
        GetHXAssistedCoolingCoilInput(state)
        state.dataHVACAssistedCC.GetCoilsInputFlag = False

    var WhichCoil: Int32 = -1
    if state.dataHVACAssistedCC.TotalNumHXAssistedCoils > 0:
        WhichCoil = find_item(
            CoilName, state.dataHVACAssistedCC.HXAssistedCoil
        )

    if WhichCoil != -1:
        var CoolingCoilType = get_coil_type_name(
            state.dataHVACAssistedCC.HXAssistedCoil[int(WhichCoil)].coolCoilType
        )
        var CoolingCoilName = (
            state.dataHVACAssistedCC.HXAssistedCoil[int(WhichCoil)].CoolingCoilName
        )
        return CoolingCoilType, CoolingCoilName
    else:
        raise_error('Could not find Coil, Type="' + CoilType + '" Name="' + CoilName + '"')
        return "", ""


fn GetCoilMaxWaterFlowRate(
    state: AnyType, CoilType: String, CoilName: String
) -> Float64:
    if state.dataHVACAssistedCC.GetCoilsInputFlag:
        GetHXAssistedCoolingCoilInput(state)
        state.dataHVACAssistedCC.GetCoilsInputFlag = False

    if state.dataHVACAssistedCC.TotalNumHXAssistedCoils > 0:
        var WhichCoil = find_item(
            CoilName, state.dataHVACAssistedCC.HXAssistedCoil
        )

        if CoilType.upper() == "COILSYSTEM:COOLING:DX:HEATEXCHANGERASSISTED":
            if WhichCoil != -1:
                return 0.0

        elif CoilType.upper() == "COILSYSTEM:COOLING:WATER:HEATEXCHANGERASSISTED":
            if WhichCoil != -1:
                var MaxWaterFlowRate = WaterCoils_GetCoilMaxWaterFlowRate(
                    state,
                    CoilType,
                    GetHXDXCoilName(state, CoilType, CoilName),
                )
                return MaxWaterFlowRate

        if WhichCoil == -1:
            raise_error('GetCoilMaxWaterFlowRate: Could not find Coil, Type="' + CoilType + '" Name="' + CoilName + '"')
    else:
        raise_error('GetCoilMaxWaterFlowRate: Could not find Coil, Type="' + CoilType + '" Name="' + CoilName + '"')

    return -1000.0


fn GetHXCoilAirFlowRate(
    state: AnyType, CoilType: String, CoilName: String
) -> Float64:
    if state.dataHVACAssistedCC.GetCoilsInputFlag:
        GetHXAssistedCoolingCoilInput(state)
        state.dataHVACAssistedCC.GetCoilsInputFlag = False

    if state.dataHVACAssistedCC.TotalNumHXAssistedCoils > 0:
        var WhichCoil = find_item(
            CoilName, state.dataHVACAssistedCC.HXAssistedCoil
        )

        if (
            CoilType.upper() == "COILSYSTEM:COOLING:DX:HEATEXCHANGERASSISTED"
            or CoilType.upper() == "COILSYSTEM:COOLING:WATER:HEATEXCHANGERASSISTED"
        ):
            if WhichCoil != -1:
                var MaxAirFlowRate = HeatRecovery_GetSupplyAirFlowRate(
                    state,
                    state.dataHVACAssistedCC.HXAssistedCoil[int(WhichCoil)].HeatExchangerName,
                )
                return MaxAirFlowRate

        if WhichCoil == -1:
            raise_error('GetHXCoilAirFlowRate: Could not find HX, Type="' + CoilType + '" Name="' + CoilName + '"')
    else:
        raise_error('GetHXCoilAirFlowRate: Could not find HX, Type="' + CoilType + '" Name="' + CoilName + '"')

    return -1000.0


fn VerifyHeatExchangerParent(
    state: AnyType, HXType: String, HXName: String
) -> Bool:
    if state.dataHVACAssistedCC.GetCoilsInputFlag:
        GetHXAssistedCoolingCoilInput(state)
        state.dataHVACAssistedCC.GetCoilsInputFlag = False

    var WhichCoil: Int32 = -1
    if state.dataHVACAssistedCC.TotalNumHXAssistedCoils > 0:
        for i in range(state.dataHVACAssistedCC.HXAssistedCoil.__len__()):
            if state.dataHVACAssistedCC.HXAssistedCoil[i].HeatExchangerName == HXName:
                WhichCoil = Int32(i)
                break

    if WhichCoil != -1:
        if get_hx_type_name(
            state.dataHVACAssistedCC.HXAssistedCoil[int(WhichCoil)].hxType
        ).upper() == HXType.upper():
            return True

    return False


fn find_item(name: String, array: List[HXAssistedCoilParameters]) -> Int32:
    for i in range(array.__len__()):
        if array[i].Name.upper() == name.upper():
            return Int32(i)
    return -1


fn find_item_in_list(name: String, array: List[HXAssistedCoilParameters]) -> Int32:
    for i in range(array.__len__()):
        if array[i].Name.upper() == name.upper():
            return Int32(i)
    return -1


@always_inline
fn get_coil_type_name(coil_type: Int32) -> String:
    if coil_type == 1:
        return "Coil:Cooling:DX"
    elif coil_type == 2:
        return "Coil:Cooling:DX:SingleSpeed"
    elif coil_type == 3:
        return "Coil:Cooling:DX:VariableSpeed"
    elif coil_type == 4:
        return "Coil:Cooling:Water"
    elif coil_type == 5:
        return "Coil:Cooling:Water:DetailedGeometry"
    elif coil_type == 17:
        return "CoilSystem:Cooling:DX:HeatExchangerAssisted"
    elif coil_type == 18:
        return "CoilSystem:Cooling:Water:HeatExchangerAssisted"
    else:
        return "Unknown"


@always_inline
fn get_hx_type_name(hx_type: Int32) -> String:
    if hx_type == 1:
        return "HeatExchanger:AirToAir:FlatPlate"
    elif hx_type == 2:
        return "HeatExchanger:AirToAir:SensibleAndLatent"
    elif hx_type == 3:
        return "HeatExchanger:Desiccant:BalancedFlow"
    else:
        return "Unknown"


@always_inline
fn get_enum_value_hx_type(hx_type_name: String) -> Int32:
    var upper_name = hx_type_name.upper()
    if upper_name == "HEATEXCHANGER:AIRTOAIR:FLATPLATE":
        return 1
    elif upper_name == "HEATEXCHANGER:AIRTOAIR:SENSIBLEANDLATENT":
        return 2
    elif upper_name == "HEATEXCHANGER:DESICCANT:BALANCEDFLOW":
        return 3
    else:
        return 0


fn HeatRecovery_GetSupplyInletNode(state: AnyType, hx_name: String) -> Int32:
    return 0


fn HeatRecovery_GetSupplyOutletNode(state: AnyType, hx_name: String) -> Int32:
    return 0


fn HeatRecovery_GetSecondaryInletNode(state: AnyType, hx_name: String) -> Int32:
    return 0


fn HeatRecovery_GetSecondaryOutletNode(state: AnyType, hx_name: String) -> Int32:
    return 0


fn HeatRecovery_SimHeatRecovery(
    state: AnyType,
    hx_name: String,
    first_hvac_iteration: Bool,
    hx_index: Int32,
    fan_op: Int32,
    part_load_ratio: Float64,
    hx_unit_on: Bool,
    companion_coil_index: Int32,
    economizer_flag: Optional[Bool],
    coil_type: Int32,
):
    pass


fn HeatRecovery_GetSupplyAirFlowRate(state: AnyType, hx_name: String) -> Float64:
    return 0.0


fn DXCoils_GetDXCoilIndex(
    state: AnyType, coil_name: String, inout coil_index: Int32
):
    pass


fn DXCoils_SimDXCoil(
    state: AnyType,
    coil_name: String,
    compressor_op: Int32,
    first_hvac_iteration: Bool,
    coil_index: Int32,
    fan_op: Int32,
    part_load_ratio: Float64,
    on_off_air_flow: Optional[Float64],
):
    pass


fn VariableSpeedCoils_GetCoilIndexVariableSpeed(
    state: AnyType, coil_type: String, coil_name: String
) -> Int32:
    return 0


fn VariableSpeedCoils_GetVSCoilNumOfSpeeds(
    state: AnyType, coil_name: String
) -> Int32:
    return 0


fn VariableSpeedCoils_SimVariableSpeedCoils(
    state: AnyType,
    coil_name: String,
    coil_index: Int32,
    fan_op: Int32,
    compressor_op: Int32,
    part_load_ratio: Float64,
    num_of_speeds: Int32,
    qzn_req: Float64,
    qlat_req: Float64,
    on_off_air_flow_ratio: Float64,
):
    pass


fn WaterCoils_GetCoilInletNode(
    state: AnyType, coil_type: String, coil_name: String
) -> Int32:
    return 0


fn WaterCoils_GetCoilWaterInletNode(
    state: AnyType, coil_type: String, coil_name: String
) -> Int32:
    return 0


fn WaterCoils_GetCoilOutletNode(
    state: AnyType, coil_type: String, coil_name: String
) -> Int32:
    return 0


fn WaterCoils_SimulateWaterCoilComponents(
    state: AnyType, coil_name: String, first_hvac_iteration: Bool, coil_index: Int32
):
    pass


fn WaterCoils_GetWaterCoilCapacity(
    state: AnyType, coil_type: String, coil_name: String
) -> Float64:
    return 0.0


fn WaterCoils_GetCoilMaxWaterFlowRate(
    state: AnyType, coil_type: String, coil_name: String
) -> Float64:
    return 0.0


fn raise_error(message: String):
    pass
