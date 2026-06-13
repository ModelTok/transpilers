from dataclasses import dataclass, field
from typing import Optional, List, Dict
from enum import Enum, auto


@dataclass
class HXAssistedCoilParameters:
    hxAssistedCoilType: int = 0  # HVAC::CoilType::Invalid
    Name: str = ""
    coolCoilType: int = 0  # HVAC::CoilType::Invalid
    CoolingCoilName: str = ""
    CoolingCoilIndex: int = 0
    DXCoilNumOfSpeeds: int = 0
    hxType: int = 0  # HVAC::HXType::Invalid
    HeatExchangerName: str = ""
    HeatExchangerIndex: int = 0
    HXAssistedCoilInletNodeNum: int = 0
    HXAssistedCoilOutletNodeNum: int = 0
    HXExhaustAirInletNodeNum: int = 0
    MassFlowRate: float = 0.0
    MaxIterCounter: int = 0
    MaxIterIndex: int = 0
    ControllerIndex: int = 0
    ControllerName: str = ""


@dataclass
class HVACHXAssistedCoolingCoilData:
    TotalNumHXAssistedCoils: int = 0
    HXAssistedCoilOutletTemp: List[float] = field(default_factory=list)
    HXAssistedCoilOutletHumRat: List[float] = field(default_factory=list)
    GetCoilsInputFlag: bool = True
    CheckEquipName: List[bool] = field(default_factory=list)
    HXAssistedCoil: List[HXAssistedCoilParameters] = field(default_factory=list)
    UniqueHXAssistedCoilNames: Dict[str, str] = field(default_factory=dict)
    CoilOutputTempLast: float = 0.0
    ErrCount: int = 0
    ErrCount2: int = 0

    def clear_state(self):
        self.TotalNumHXAssistedCoils = 0
        self.HXAssistedCoilOutletTemp.clear()
        self.HXAssistedCoilOutletHumRat.clear()
        self.GetCoilsInputFlag = True
        self.CheckEquipName.clear()
        self.HXAssistedCoil.clear()
        self.UniqueHXAssistedCoilNames.clear()
        self.CoilOutputTempLast = 0.0
        self.ErrCount = 0
        self.ErrCount2 = 0


def SimHXAssistedCoolingCoil(
    state,
    HXAssistedCoilName: str,
    FirstHVACIteration: bool,
    compressorOp: int,
    PartLoadRatio: float,
    CompIndex: int,
    fanOp: int,
    HXUnitEnable: Optional[bool] = None,
    OnOffAFR: Optional[float] = None,
    EconomizerFlag: Optional[bool] = None,
    QTotOut: Optional[float] = None,
    DehumidificationMode: Optional[int] = None,
    LoadSHR: Optional[float] = None,
) -> int:
    if state.dataHVACAssistedCC.GetCoilsInputFlag:
        GetHXAssistedCoolingCoilInput(state)
        state.dataHVACAssistedCC.GetCoilsInputFlag = False

    if CompIndex == 0:
        HXAssistedCoilNum = find_item_in_list(
            HXAssistedCoilName, state.dataHVACAssistedCC.HXAssistedCoil
        )
        if HXAssistedCoilNum == -1:
            raise RuntimeError(
                f"HX Assisted Coil not found={HXAssistedCoilName}"
            )
        HXAssistedCoilNum += 1
        CompIndex = HXAssistedCoilNum
    else:
        HXAssistedCoilNum = CompIndex
        if (
            HXAssistedCoilNum
            > state.dataHVACAssistedCC.TotalNumHXAssistedCoils
            or HXAssistedCoilNum < 1
        ):
            raise RuntimeError(
                f"SimHXAssistedCoolingCoil: Invalid CompIndex passed={HXAssistedCoilNum}, "
                f"Number of HX Assisted Cooling Coils={state.dataHVACAssistedCC.TotalNumHXAssistedCoils}, "
                f"Coil name={HXAssistedCoilName}"
            )
        if state.dataHVACAssistedCC.CheckEquipName[HXAssistedCoilNum - 1]:
            if (
                HXAssistedCoilName
                and HXAssistedCoilName
                != state.dataHVACAssistedCC.HXAssistedCoil[
                    HXAssistedCoilNum - 1
                ].Name
            ):
                raise RuntimeError(
                    f"SimHXAssistedCoolingCoil: Invalid CompIndex passed={HXAssistedCoilNum}, "
                    f"Coil name={HXAssistedCoilName}, "
                    f"stored Coil Name for that index="
                    f"{state.dataHVACAssistedCC.HXAssistedCoil[HXAssistedCoilNum - 1].Name}"
                )
            state.dataHVACAssistedCC.CheckEquipName[HXAssistedCoilNum - 1] = False

    InitHXAssistedCoolingCoil(state, HXAssistedCoilNum)

    if HXUnitEnable is not None:
        HXUnitOn = HXUnitEnable
    else:
        HXUnitOn = True

    if compressorOp == 0:  # HVAC::CompressorOp::Off
        HXUnitOn = False

    if OnOffAFR is not None:
        AirFlowRatio = OnOffAFR
    else:
        AirFlowRatio = 1.0

    if (
        DehumidificationMode is not None
        and LoadSHR is not None
        and state.dataHVACAssistedCC.HXAssistedCoil[
            HXAssistedCoilNum - 1
        ].coolCoilType
        == 1
    ):  # HVAC::CoilType::CoolingDX
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
        InletNodeNum = state.dataHVACAssistedCC.HXAssistedCoil[
            HXAssistedCoilNum - 1
        ].HXAssistedCoilInletNodeNum
        OutletNodeNum = state.dataHVACAssistedCC.HXAssistedCoil[
            HXAssistedCoilNum - 1
        ].HXAssistedCoilOutletNodeNum
        AirMassFlow = state.dataLoopNodes.Node[OutletNodeNum - 1].MassFlowRate
        QTotOut = AirMassFlow * (
            state.dataLoopNodes.Node[InletNodeNum - 1].Enthalpy
            - state.dataLoopNodes.Node[OutletNodeNum - 1].Enthalpy
        )

    return CompIndex


def GetHXAssistedCoolingCoilInput(state):
    num_hx_dx_coils = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, "CoilSystem:Cooling:DX:HeatExchangerAssisted"
    )
    num_hx_water_coils = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, "CoilSystem:Cooling:Water:HeatExchangerAssisted"
    )
    state.dataHVACAssistedCC.TotalNumHXAssistedCoils = (
        num_hx_dx_coils + num_hx_water_coils
    )

    if state.dataHVACAssistedCC.TotalNumHXAssistedCoils > 0:
        state.dataHVACAssistedCC.HXAssistedCoil = [
            HXAssistedCoilParameters()
            for _ in range(state.dataHVACAssistedCC.TotalNumHXAssistedCoils)
        ]
        state.dataHVACAssistedCC.HXAssistedCoilOutletTemp = [
            0.0 for _ in range(state.dataHVACAssistedCC.TotalNumHXAssistedCoils)
        ]
        state.dataHVACAssistedCC.HXAssistedCoilOutletHumRat = [
            0.0 for _ in range(state.dataHVACAssistedCC.TotalNumHXAssistedCoils)
        ]
        state.dataHVACAssistedCC.CheckEquipName = [
            True for _ in range(state.dataHVACAssistedCC.TotalNumHXAssistedCoils)
        ]

    for hx_coil_num in range(1, num_hx_dx_coils + 1):
        this_hx_coil = state.dataHVACAssistedCC.HXAssistedCoil[hx_coil_num - 1]
        alph_array, num_array = (
            state.dataInputProcessing.inputProcessor.getObjectItem(
                state,
                "CoilSystem:Cooling:DX:HeatExchangerAssisted",
                hx_coil_num,
            )
        )

        this_hx_coil.Name = alph_array[0]
        this_hx_coil.hxType = get_enum_value_hx_type(alph_array[1])
        this_hx_coil.HeatExchangerName = alph_array[2]
        this_hx_coil.CoolingCoilName = alph_array[4]

        if alph_array[3].upper() == "COIL:COOLING:DX":
            this_hx_coil.coolCoilType = 1  # HVAC::CoilType::CoolingDX
            this_hx_coil.hxAssistedCoilType = 17  # HVAC::CoilType::CoolingDXHXAssisted
            cooling_coil_index_temp = state.dataCoilCoolingDX.factory(
                state, this_hx_coil.CoolingCoilName
            )
            this_hx_coil.CoolingCoilIndex = cooling_coil_index_temp
            if cooling_coil_index_temp < 0:
                raise RuntimeError(
                    f"Cooling coil not found: {this_hx_coil.CoolingCoilName}"
                )
            this_hx_coil.DXCoilNumOfSpeeds = (
                state.dataCoilCoolingDX.coilCoolingDXs[
                    cooling_coil_index_temp
                ].performance.numSpeeds()
            )

        elif alph_array[3].upper() == "COIL:COOLING:DX:SINGLESPEED":
            this_hx_coil.coolCoilType = 2  # HVAC::CoilType::CoolingDXSingleSpeed
            this_hx_coil.hxAssistedCoilType = 17  # HVAC::CoilType::CoolingDXHXAssisted
            DXCoils_GetDXCoilIndex(
                state, this_hx_coil.CoolingCoilName, this_hx_coil.CoolingCoilIndex
            )

        elif alph_array[3].upper() == "COIL:COOLING:DX:VARIABLESPEED":
            this_hx_coil.coolCoilType = (
                3  # HVAC::CoilType::CoolingDXVariableSpeed
            )
            this_hx_coil.hxAssistedCoilType = 17  # HVAC::CoilType::CoolingDXHXAssisted
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

        supply_air_inlet_node = HeatRecovery_GetSupplyInletNode(
            state, this_hx_coil.HeatExchangerName
        )
        supply_air_outlet_node = HeatRecovery_GetSupplyOutletNode(
            state, this_hx_coil.HeatExchangerName
        )
        secondary_air_inlet_node = HeatRecovery_GetSecondaryInletNode(
            state, this_hx_coil.HeatExchangerName
        )
        secondary_air_outlet_node = HeatRecovery_GetSecondaryOutletNode(
            state, this_hx_coil.HeatExchangerName
        )

        this_hx_coil.HXAssistedCoilInletNodeNum = supply_air_inlet_node
        this_hx_coil.HXExhaustAirInletNodeNum = secondary_air_inlet_node
        this_hx_coil.HXAssistedCoilOutletNodeNum = secondary_air_outlet_node

    for hx_coil_num in range(
        num_hx_dx_coils + 1,
        state.dataHVACAssistedCC.TotalNumHXAssistedCoils + 1,
    ):
        this_water_hx_num = hx_coil_num - num_hx_dx_coils
        this_hx_coil = state.dataHVACAssistedCC.HXAssistedCoil[hx_coil_num - 1]

        alph_array, num_array = (
            state.dataInputProcessing.inputProcessor.getObjectItem(
                state,
                "CoilSystem:Cooling:Water:HeatExchangerAssisted",
                this_water_hx_num,
            )
        )

        this_hx_coil.Name = alph_array[0]
        this_hx_coil.hxType = get_enum_value_hx_type(alph_array[1])
        this_hx_coil.HeatExchangerName = alph_array[2]
        this_hx_coil.CoolingCoilName = alph_array[4]

        if (
            alph_array[3].upper() == "COIL:COOLING:WATER"
            or alph_array[3].upper() == "COIL:COOLING:WATER:DETAILEDGEOMETRY"
        ):
            if (
                alph_array[3].upper()
                == "COIL:COOLING:WATER:DETAILEDGEOMETRY"
            ):
                this_hx_coil.coolCoilType = (
                    5  # HVAC::CoilType::CoolingWaterDetailed
                )
            else:
                this_hx_coil.coolCoilType = 4  # HVAC::CoilType::CoolingWater
            this_hx_coil.hxAssistedCoilType = (
                18  # HVAC::CoilType::CoolingWaterHXAssisted
            )

        supply_air_inlet_node = HeatRecovery_GetSupplyInletNode(
            state, this_hx_coil.HeatExchangerName
        )
        supply_air_outlet_node = HeatRecovery_GetSupplyOutletNode(
            state, this_hx_coil.HeatExchangerName
        )
        secondary_air_inlet_node = HeatRecovery_GetSecondaryInletNode(
            state, this_hx_coil.HeatExchangerName
        )
        secondary_air_outlet_node = HeatRecovery_GetSecondaryOutletNode(
            state, this_hx_coil.HeatExchangerName
        )

        this_hx_coil.HXAssistedCoilInletNodeNum = supply_air_inlet_node
        this_hx_coil.HXExhaustAirInletNodeNum = secondary_air_inlet_node
        this_hx_coil.HXAssistedCoilOutletNodeNum = secondary_air_outlet_node


def InitHXAssistedCoolingCoil(state, HXAssistedCoilNum: int):
    this_hx_coil = state.dataHVACAssistedCC.HXAssistedCoil[
        HXAssistedCoilNum - 1
    ]
    this_hx_coil.MassFlowRate = state.dataLoopNodes.Node[
        this_hx_coil.HXAssistedCoilInletNodeNum - 1
    ].MassFlowRate


def CalcHXAssistedCoolingCoil(
    state,
    HXAssistedCoilNum: int,
    FirstHVACIteration: bool,
    compressorOp: int,
    PartLoadRatio: float,
    HXUnitOn: bool,
    fanOp: int,
    OnOffAirFlow: Optional[float] = None,
    EconomizerFlag: Optional[bool] = None,
    DehumidificationMode: Optional[int] = None,
    LoadSHR: Optional[float] = None,
):
    MAX_ITER = 50

    this_hx_coil = state.dataHVACAssistedCC.HXAssistedCoil[
        HXAssistedCoilNum - 1
    ]
    AirMassFlow = this_hx_coil.MassFlowRate
    Error = 1.0
    ErrorLast = Error
    Iter = 0

    state.dataLoopNodes.Node[
        this_hx_coil.HXExhaustAirInletNodeNum - 1
    ].MassFlowRate = AirMassFlow

    if this_hx_coil.coolCoilType in [1, 2, 3]:  # DX coil types
        CompanionCoilIndexNum = this_hx_coil.CoolingCoilIndex
    else:
        CompanionCoilIndexNum = 0

    if PartLoadRatio == 0.0:
        state.dataLoopNodes.Node[
            this_hx_coil.HXExhaustAirInletNodeNum - 1
        ].Temp = state.dataLoopNodes.Node[
            this_hx_coil.HXAssistedCoilInletNodeNum - 1
        ].Temp
        state.dataLoopNodes.Node[
            this_hx_coil.HXExhaustAirInletNodeNum - 1
        ].HumRat = state.dataLoopNodes.Node[
            this_hx_coil.HXAssistedCoilInletNodeNum - 1
        ].HumRat
        state.dataLoopNodes.Node[
            this_hx_coil.HXExhaustAirInletNodeNum - 1
        ].Enthalpy = state.dataLoopNodes.Node[
            this_hx_coil.HXAssistedCoilInletNodeNum - 1
        ].Enthalpy
        state.dataLoopNodes.Node[
            this_hx_coil.HXExhaustAirInletNodeNum - 1
        ].MassFlowRate = state.dataLoopNodes.Node[
            this_hx_coil.HXAssistedCoilInletNodeNum - 1
        ].MassFlowRate

    while (abs(Error) > 0.0005 and Iter <= MAX_ITER) or Iter < 2:
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

        if this_hx_coil.coolCoilType == 1:  # CoolingDX
            coolingCoilIndex = this_hx_coil.CoolingCoilIndex
            m_single_mode = (
                state.dataCoilCoolingDX.coilCoolingDXs[
                    coolingCoilIndex
                ].getNumModes()
            )
            single_mode = m_single_mode == 1

            m_cooling_speed_num = (
                state.dataCoilCoolingDX.coilCoolingDXs[
                    coolingCoilIndex
                ].performance.numSpeeds()
            )

            coil_mode = 0  # HVAC::CoilMode::Normal
            if (
                state.dataCoilCoolingDX.coilCoolingDXs[
                    coolingCoilIndex
                ].subcoolReheatFlag
            ):
                coil_mode = 2  # HVAC::CoilMode::SubcoolReheat
            elif DehumidificationMode == 1:  # HVAC::CoilMode::Enhanced
                coil_mode = 1  # HVAC::CoilMode::Enhanced

            CoilPLR = 1.0
            if compressorOp == 0:  # CompressorOp::Off
                m_cooling_speed_num = 1
            else:
                if single_mode:
                    CoilPLR = (
                        PartLoadRatio
                        if m_cooling_speed_num == 1
                        else 0.0
                    )
                else:
                    CoilPLR = PartLoadRatio

            state.dataCoilCoolingDX.coilCoolingDXs[
                this_hx_coil.CoolingCoilIndex
            ].simulate(state, coil_mode, m_cooling_speed_num, CoilPLR, fanOp, single_mode)

        elif this_hx_coil.coolCoilType == 2:  # CoolingDXSingleSpeed
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

        elif this_hx_coil.coolCoilType == 3:  # CoolingDXVariableSpeed
            QZnReq = -1.0
            QLatReq = 0.0
            OnOffAirFlowRatio = 1.0
            compressor_on = compressorOp
            if PartLoadRatio == 0.0:
                compressor_on = 0  # CompressorOp::Off

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

        else:  # Water coil
            WaterCoils_SimulateWaterCoilComponents(
                state,
                this_hx_coil.CoolingCoilName,
                FirstHVACIteration,
                this_hx_coil.CoolingCoilIndex,
            )

        Error = (
            state.dataHVACAssistedCC.CoilOutputTempLast
            - state.dataLoopNodes.Node[
                this_hx_coil.HXExhaustAirInletNodeNum - 1
            ].Temp
        )
        if Iter > 40:
            if Error + ErrorLast < 0.000001:
                Error = 0.0

        ErrorLast = Error
        state.dataHVACAssistedCC.CoilOutputTempLast = state.dataLoopNodes.Node[
            this_hx_coil.HXExhaustAirInletNodeNum - 1
        ].Temp
        Iter += 1

    if Iter > MAX_ITER:
        if this_hx_coil.MaxIterCounter < 1:
            this_hx_coil.MaxIterCounter += 1
            print(
                f"Warning: {this_hx_coil.Name} -- Exceeded max iterations "
                f"({MAX_ITER}) while calculating operating conditions."
            )

    state.dataHVACAssistedCC.HXAssistedCoilOutletTemp[
        HXAssistedCoilNum - 1
    ] = state.dataLoopNodes.Node[
        this_hx_coil.HXAssistedCoilOutletNodeNum - 1
    ].Temp
    state.dataHVACAssistedCC.HXAssistedCoilOutletHumRat[
        HXAssistedCoilNum - 1
    ] = state.dataLoopNodes.Node[
        this_hx_coil.HXAssistedCoilOutletNodeNum - 1
    ].HumRat


def GetHXDXCoilIndex(
    state, HXDXCoilName: str, CurrentModuleObject: str = ""
) -> int:
    if state.dataHVACAssistedCC.GetCoilsInputFlag:
        GetHXAssistedCoolingCoilInput(state)
        state.dataHVACAssistedCC.GetCoilsInputFlag = False

    if state.dataHVACAssistedCC.TotalNumHXAssistedCoils > 0:
        HXDXCoilIndex = find_item(
            HXDXCoilName, state.dataHVACAssistedCC.HXAssistedCoil
        )
    else:
        HXDXCoilIndex = -1

    if HXDXCoilIndex == -1:
        if CurrentModuleObject:
            raise RuntimeError(
                f"{CurrentModuleObject}, GetHXDXCoilIndex: HX Assisted Cooling Coil not found={HXDXCoilName}"
            )
        else:
            raise RuntimeError(
                f"GetHXDXCoilIndex: HX Assisted Cooling Coil not found={HXDXCoilName}"
            )

    return HXDXCoilIndex + 1


def CheckHXAssistedCoolingCoilSchedule(
    state, CompType: str, CompName: str, CompIndex: int
) -> tuple:
    if state.dataHVACAssistedCC.GetCoilsInputFlag:
        GetHXAssistedCoolingCoilInput(state)
        state.dataHVACAssistedCC.GetCoilsInputFlag = False

    if CompIndex == 0:
        if state.dataHVACAssistedCC.TotalNumHXAssistedCoils > 0:
            HXAssistedCoilNum = find_item(
                CompName, state.dataHVACAssistedCC.HXAssistedCoil
            )
        else:
            HXAssistedCoilNum = -1

        if HXAssistedCoilNum == -1:
            raise RuntimeError(
                f"CheckHXAssistedCoolingCoilSchedule: HX Assisted Coil not found={CompName}"
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
            raise RuntimeError(
                f"CheckHXAssistedCoolingCoilSchedule: Invalid CompIndex passed={CompIndex}, "
                f"Number of Heating Coils={state.dataHVACAssistedCC.TotalNumHXAssistedCoils}, "
                f"Coil name={CompName}"
            )
        if (
            CompName
            != state.dataHVACAssistedCC.HXAssistedCoil[
                HXAssistedCoilNum
            ].Name
        ):
            raise RuntimeError(
                f"CheckHXAssistedCoolingCoilSchedule: Invalid CompIndex passed={CompIndex}, "
                f"Coil name={CompName}, "
                f"stored Coil Name for that index="
                f"{state.dataHVACAssistedCC.HXAssistedCoil[HXAssistedCoilNum].Name}"
            )
        Value = 1.0

    return Value, CompIndex


def GetCoilCapacity(
    state, CoilType: str, CoilName: str
) -> float:
    if state.dataHVACAssistedCC.GetCoilsInputFlag:
        GetHXAssistedCoolingCoilInput(state)
        state.dataHVACAssistedCC.GetCoilsInputFlag = False

    CoilCapacity = 0.0

    WhichCoil = -1
    if state.dataHVACAssistedCC.TotalNumHXAssistedCoils > 0:
        WhichCoil = find_item(
            CoilName, state.dataHVACAssistedCC.HXAssistedCoil
        )

    if CoilType.upper() == "COILSYSTEM:COOLING:DX:HEATEXCHANGERASSISTED":
        if WhichCoil != -1:
            if (
                state.dataHVACAssistedCC.HXAssistedCoil[WhichCoil].coolCoilType
                == 1
            ):  # CoolingDX
                coolingCoilDXIndex = (
                    state.dataHVACAssistedCC.HXAssistedCoil[
                        WhichCoil
                    ].CoolingCoilIndex
                )
                CoilCapacity = (
                    state.dataCoilCoolingDX.coilCoolingDXs[
                        coolingCoilDXIndex
                    ].performance.ratedGrossTotalCap()
                )

    elif CoilType.upper() == "COILSYSTEM:COOLING:WATER:HEATEXCHANGERASSISTED":
        if WhichCoil != -1:
            CoilCapacity = WaterCoils_GetWaterCoilCapacity(
                state,
                get_coil_type_name(
                    state.dataHVACAssistedCC.HXAssistedCoil[
                        WhichCoil
                    ].coolCoilType
                ),
                state.dataHVACAssistedCC.HXAssistedCoil[WhichCoil].CoolingCoilName,
            )

    if WhichCoil == -1:
        raise RuntimeError(
            f'GetCoilCapacity: Could not find Coil, Type="{CoilType}" Name="{CoilName}"'
        )

    return CoilCapacity


def GetCoilGroupTypeNum(
    state, CoilType: str, CoilName: str, PrintWarning: bool = True
) -> int:
    if state.dataHVACAssistedCC.GetCoilsInputFlag:
        GetHXAssistedCoolingCoilInput(state)
        state.dataHVACAssistedCC.GetCoilsInputFlag = False

    WhichCoil = -1
    if state.dataHVACAssistedCC.TotalNumHXAssistedCoils > 0:
        WhichCoil = find_item(
            CoilName, state.dataHVACAssistedCC.HXAssistedCoil
        )

    if WhichCoil != -1:
        return state.dataHVACAssistedCC.HXAssistedCoil[
            WhichCoil
        ].hxAssistedCoilType

    if PrintWarning:
        raise RuntimeError(
            f'GetCoilGroupTypeNum: Could not find Coil, Type="{CoilType}" Name="{CoilName}"'
        )
    return 0  # HVAC::CoilType::Invalid


def GetCoilObjectTypeNum(
    state, CoilType: str, CoilName: str, PrintWarning: bool = True
) -> int:
    if state.dataHVACAssistedCC.GetCoilsInputFlag:
        GetHXAssistedCoolingCoilInput(state)
        state.dataHVACAssistedCC.GetCoilsInputFlag = False

    WhichCoil = -1
    if state.dataHVACAssistedCC.TotalNumHXAssistedCoils > 0:
        WhichCoil = find_item(
            CoilName, state.dataHVACAssistedCC.HXAssistedCoil
        )

    if WhichCoil != -1:
        return state.dataHVACAssistedCC.HXAssistedCoil[WhichCoil].coolCoilType

    if PrintWarning:
        raise RuntimeError(
            f'GetCoilObjectTypeNum: Could not find Coil, Type="{CoilType}" Name="{CoilName}"'
        )
    return 0  # HVAC::CoilType::Invalid


def GetCoilInletNode(
    state, CoilType: str, CoilName: str
) -> int:
    if state.dataHVACAssistedCC.GetCoilsInputFlag:
        GetHXAssistedCoolingCoilInput(state)
        state.dataHVACAssistedCC.GetCoilsInputFlag = False

    WhichCoil = -1
    if state.dataHVACAssistedCC.TotalNumHXAssistedCoils > 0:
        WhichCoil = find_item(
            CoilName, state.dataHVACAssistedCC.HXAssistedCoil
        )

    if WhichCoil != -1:
        return state.dataHVACAssistedCC.HXAssistedCoil[
            WhichCoil
        ].HXAssistedCoilInletNodeNum

    raise RuntimeError(
        f'GetCoilInletNode: Could not find Coil, Type="{CoilType}" Name="{CoilName}"'
    )


def GetCoilWaterInletNode(
    state, CoilType: str, CoilName: str
) -> int:
    if state.dataHVACAssistedCC.GetCoilsInputFlag:
        GetHXAssistedCoolingCoilInput(state)
        state.dataHVACAssistedCC.GetCoilsInputFlag = False

    WhichCoil = -1
    if state.dataHVACAssistedCC.TotalNumHXAssistedCoils > 0:
        WhichCoil = find_item(
            CoilName, state.dataHVACAssistedCC.HXAssistedCoil
        )

    if WhichCoil != -1:
        if (
            state.dataHVACAssistedCC.HXAssistedCoil[WhichCoil].coolCoilType
            == 4
        ):  # CoolingWater
            NodeNumber = WaterCoils_GetCoilWaterInletNode(
                state,
                get_coil_type_name(
                    state.dataHVACAssistedCC.HXAssistedCoil[
                        WhichCoil
                    ].coolCoilType
                ),
                state.dataHVACAssistedCC.HXAssistedCoil[WhichCoil].CoolingCoilName,
            )
        elif (
            state.dataHVACAssistedCC.HXAssistedCoil[WhichCoil].coolCoilType
            == 5
        ):  # CoolingWaterDetailed
            NodeNumber = WaterCoils_GetCoilWaterInletNode(
                state,
                get_coil_type_name(
                    state.dataHVACAssistedCC.HXAssistedCoil[
                        WhichCoil
                    ].coolCoilType
                ),
                state.dataHVACAssistedCC.HXAssistedCoil[WhichCoil].CoolingCoilName,
            )
        else:
            raise RuntimeError(
                f'GetCoilWaterInletNode: Invalid Cooling Coil for HX Assisted Coil, '
                f'Type="{get_coil_type_name(state.dataHVACAssistedCC.HXAssistedCoil[WhichCoil].coolCoilType)}" '
                f'Name="{CoilName}"'
            )
        return NodeNumber
    else:
        raise RuntimeError(
            f'GetCoilWaterInletNode: Could not find Coil, Type="{CoilType}" Name="{CoilName}"'
        )


def GetCoilOutletNode(
    state, CoilType: str, CoilName: str
) -> int:
    if state.dataHVACAssistedCC.GetCoilsInputFlag:
        GetHXAssistedCoolingCoilInput(state)
        state.dataHVACAssistedCC.GetCoilsInputFlag = False

    WhichCoil = -1
    if state.dataHVACAssistedCC.TotalNumHXAssistedCoils > 0:
        WhichCoil = find_item(
            CoilName, state.dataHVACAssistedCC.HXAssistedCoil
        )

    if WhichCoil != -1:
        return state.dataHVACAssistedCC.HXAssistedCoil[
            WhichCoil
        ].HXAssistedCoilOutletNodeNum

    raise RuntimeError(
        f'GetCoilOutletNode: Could not find Coil, Type="{CoilType}" Name="{CoilName}'
    )


def GetHXDXCoilType(
    state, CoilType: str, CoilName: str
) -> str:
    if state.dataHVACAssistedCC.GetCoilsInputFlag:
        GetHXAssistedCoolingCoilInput(state)
        state.dataHVACAssistedCC.GetCoilsInputFlag = False

    WhichCoil = -1
    if state.dataHVACAssistedCC.TotalNumHXAssistedCoils > 0:
        WhichCoil = find_item(
            CoilName, state.dataHVACAssistedCC.HXAssistedCoil
        )

    if WhichCoil != -1:
        return get_coil_type_name(
            state.dataHVACAssistedCC.HXAssistedCoil[WhichCoil].coolCoilType
        )

    raise RuntimeError(
        f'Could not find Coil, Type="{CoilType}" Name="{CoilName}"'
    )


def GetHXDXCoilName(
    state, CoilType: str, CoilName: str
) -> str:
    if state.dataHVACAssistedCC.GetCoilsInputFlag:
        GetHXAssistedCoolingCoilInput(state)
        state.dataHVACAssistedCC.GetCoilsInputFlag = False

    WhichCoil = -1
    if state.dataHVACAssistedCC.TotalNumHXAssistedCoils > 0:
        WhichCoil = find_item(
            CoilName, state.dataHVACAssistedCC.HXAssistedCoil
        )

    if WhichCoil != -1:
        return state.dataHVACAssistedCC.HXAssistedCoil[WhichCoil].CoolingCoilName

    raise RuntimeError(
        f'Could not find Coil, Type="{CoilType}" Name="{CoilName}"'
    )


def GetActualDXCoilIndex(
    state, CoilType: str, CoilName: str
) -> int:
    if state.dataHVACAssistedCC.GetCoilsInputFlag:
        GetHXAssistedCoolingCoilInput(state)
        state.dataHVACAssistedCC.GetCoilsInputFlag = False

    WhichCoil = -1
    if state.dataHVACAssistedCC.TotalNumHXAssistedCoils > 0:
        WhichCoil = find_item(
            CoilName, state.dataHVACAssistedCC.HXAssistedCoil
        )

    if WhichCoil != -1:
        return state.dataHVACAssistedCC.HXAssistedCoil[WhichCoil].CoolingCoilIndex

    raise RuntimeError(
        f'Could not find Coil, Type="{CoilType}" Name="{CoilName}"'
    )


def GetHXCoilType(
    state, CoilType: str, CoilName: str
) -> str:
    if state.dataHVACAssistedCC.GetCoilsInputFlag:
        GetHXAssistedCoolingCoilInput(state)
        state.dataHVACAssistedCC.GetCoilsInputFlag = False

    WhichCoil = -1
    if state.dataHVACAssistedCC.TotalNumHXAssistedCoils > 0:
        WhichCoil = find_item(
            CoilName, state.dataHVACAssistedCC.HXAssistedCoil
        )

    if WhichCoil != -1:
        return get_coil_type_name(
            state.dataHVACAssistedCC.HXAssistedCoil[WhichCoil].coolCoilType
        )

    raise RuntimeError(
        f'Could not find Coil, Type="{CoilType}" Name="{CoilName}"'
    )


def GetHXCoilTypeAndName(
    state, CoilType: str, CoilName: str
) -> tuple:
    if state.dataHVACAssistedCC.GetCoilsInputFlag:
        GetHXAssistedCoolingCoilInput(state)
        state.dataHVACAssistedCC.GetCoilsInputFlag = False

    WhichCoil = -1
    if state.dataHVACAssistedCC.TotalNumHXAssistedCoils > 0:
        WhichCoil = find_item(
            CoilName, state.dataHVACAssistedCC.HXAssistedCoil
        )

    if WhichCoil != -1:
        CoolingCoilType = get_coil_type_name(
            state.dataHVACAssistedCC.HXAssistedCoil[WhichCoil].coolCoilType
        )
        CoolingCoilName = (
            state.dataHVACAssistedCC.HXAssistedCoil[WhichCoil].CoolingCoilName
        )
        return CoolingCoilType, CoolingCoilName
    else:
        raise RuntimeError(
            f'Could not find Coil, Type="{CoilType}" Name="{CoilName}"'
        )


def GetCoilMaxWaterFlowRate(
    state, CoilType: str, CoilName: str
) -> float:
    if state.dataHVACAssistedCC.GetCoilsInputFlag:
        GetHXAssistedCoolingCoilInput(state)
        state.dataHVACAssistedCC.GetCoilsInputFlag = False

    if state.dataHVACAssistedCC.TotalNumHXAssistedCoils > 0:
        WhichCoil = find_item(
            CoilName, state.dataHVACAssistedCC.HXAssistedCoil
        )

        if CoilType.upper() == "COILSYSTEM:COOLING:DX:HEATEXCHANGERASSISTED":
            if WhichCoil != -1:
                MaxWaterFlowRate = 0.0
                return MaxWaterFlowRate

        elif CoilType.upper() == "COILSYSTEM:COOLING:WATER:HEATEXCHANGERASSISTED":
            if WhichCoil != -1:
                MaxWaterFlowRate = WaterCoils_GetCoilMaxWaterFlowRate(
                    state,
                    CoilType,
                    GetHXDXCoilName(state, CoilType, CoilName),
                )
                return MaxWaterFlowRate

        if WhichCoil == -1:
            raise RuntimeError(
                f'GetCoilMaxWaterFlowRate: Could not find Coil, Type="{CoilType}" Name="{CoilName}"'
            )
    else:
        raise RuntimeError(
            f'GetCoilMaxWaterFlowRate: Could not find Coil, Type="{CoilType}" Name="{CoilName}"'
        )

    return -1000.0


def GetHXCoilAirFlowRate(
    state, CoilType: str, CoilName: str
) -> float:
    if state.dataHVACAssistedCC.GetCoilsInputFlag:
        GetHXAssistedCoolingCoilInput(state)
        state.dataHVACAssistedCC.GetCoilsInputFlag = False

    if state.dataHVACAssistedCC.TotalNumHXAssistedCoils > 0:
        WhichCoil = find_item(
            CoilName, state.dataHVACAssistedCC.HXAssistedCoil
        )

        if (
            CoilType.upper()
            == "COILSYSTEM:COOLING:DX:HEATEXCHANGERASSISTED"
            or CoilType.upper()
            == "COILSYSTEM:COOLING:WATER:HEATEXCHANGERASSISTED"
        ):
            if WhichCoil != -1:
                MaxAirFlowRate = HeatRecovery_GetSupplyAirFlowRate(
                    state,
                    state.dataHVACAssistedCC.HXAssistedCoil[
                        WhichCoil
                    ].HeatExchangerName,
                )
                return MaxAirFlowRate

        if WhichCoil == -1:
            raise RuntimeError(
                f'GetHXCoilAirFlowRate: Could not find HX, Type="{CoilType}" Name="{CoilName}"'
            )
    else:
        raise RuntimeError(
            f'GetHXCoilAirFlowRate: Could not find HX, Type="{CoilType}" Name="{CoilName}"'
        )

    return -1000.0


def VerifyHeatExchangerParent(
    state, HXType: str, HXName: str
) -> bool:
    if state.dataHVACAssistedCC.GetCoilsInputFlag:
        GetHXAssistedCoolingCoilInput(state)
        state.dataHVACAssistedCC.GetCoilsInputFlag = False

    WhichCoil = -1
    if state.dataHVACAssistedCC.TotalNumHXAssistedCoils > 0:
        for i, coil in enumerate(state.dataHVACAssistedCC.HXAssistedCoil):
            if coil.HeatExchangerName == HXName:
                WhichCoil = i
                break

    if WhichCoil != -1:
        if get_hx_type_name(
            state.dataHVACAssistedCC.HXAssistedCoil[WhichCoil].hxType
        ).upper() == HXType.upper():
            return True

    return False


def find_item(name: str, array) -> int:
    for i, item in enumerate(array):
        if item.Name.upper() == name.upper():
            return i
    return -1


def find_item_in_list(name: str, array) -> int:
    for i, item in enumerate(array):
        if item.Name.upper() == name.upper():
            return i
    return -1


def get_coil_type_name(coil_type: int) -> str:
    coil_types = {
        1: "Coil:Cooling:DX",
        2: "Coil:Cooling:DX:SingleSpeed",
        3: "Coil:Cooling:DX:VariableSpeed",
        4: "Coil:Cooling:Water",
        5: "Coil:Cooling:Water:DetailedGeometry",
        17: "CoilSystem:Cooling:DX:HeatExchangerAssisted",
        18: "CoilSystem:Cooling:Water:HeatExchangerAssisted",
    }
    return coil_types.get(coil_type, "Unknown")


def get_hx_type_name(hx_type: int) -> str:
    hx_types = {
        1: "HeatExchanger:AirToAir:FlatPlate",
        2: "HeatExchanger:AirToAir:SensibleAndLatent",
        3: "HeatExchanger:Desiccant:BalancedFlow",
    }
    return hx_types.get(hx_type, "Unknown")


def get_enum_value_hx_type(hx_type_name: str) -> int:
    hx_types = {
        "HEATEXCHANGER:AIRTOAIR:FLATPLATE": 1,
        "HEATEXCHANGER:AIRTOAIR:SENSIBLEANDLATENT": 2,
        "HEATEXCHANGER:DESICCANT:BALANCEDFLOW": 3,
    }
    return hx_types.get(hx_type_name.upper(), 0)


def HeatRecovery_GetSupplyInletNode(state, hx_name: str) -> int:
    pass


def HeatRecovery_GetSupplyOutletNode(state, hx_name: str) -> int:
    pass


def HeatRecovery_GetSecondaryInletNode(state, hx_name: str) -> int:
    pass


def HeatRecovery_GetSecondaryOutletNode(state, hx_name: str) -> int:
    pass


def HeatRecovery_SimHeatRecovery(
    state,
    hx_name: str,
    first_hvac_iteration: bool,
    hx_index: int,
    fan_op: int,
    part_load_ratio: float,
    hx_unit_on: bool,
    companion_coil_index: int,
    economizer_flag: Optional[bool],
    coil_type: int,
):
    pass


def HeatRecovery_GetSupplyAirFlowRate(state, hx_name: str) -> float:
    pass


def DXCoils_GetDXCoilIndex(
    state, coil_name: str, coil_index: int
):
    pass


def DXCoils_SimDXCoil(
    state,
    coil_name: str,
    compressor_op: int,
    first_hvac_iteration: bool,
    coil_index: int,
    fan_op: int,
    part_load_ratio: float,
    on_off_air_flow: Optional[float],
):
    pass


def VariableSpeedCoils_GetCoilIndexVariableSpeed(
    state, coil_type: str, coil_name: str
) -> int:
    pass


def VariableSpeedCoils_GetVSCoilNumOfSpeeds(
    state, coil_name: str
) -> int:
    pass


def VariableSpeedCoils_SimVariableSpeedCoils(
    state,
    coil_name: str,
    coil_index: int,
    fan_op: int,
    compressor_op: int,
    part_load_ratio: float,
    num_of_speeds: int,
    qzn_req: float,
    qlat_req: float,
    on_off_air_flow_ratio: float,
):
    pass


def WaterCoils_GetCoilInletNode(
    state, coil_type: str, coil_name: str
) -> int:
    pass


def WaterCoils_GetCoilWaterInletNode(
    state, coil_type: str, coil_name: str
) -> int:
    pass


def WaterCoils_GetCoilOutletNode(
    state, coil_type: str, coil_name: str
) -> int:
    pass


def WaterCoils_SimulateWaterCoilComponents(
    state, coil_name: str, first_hvac_iteration: bool, coil_index: int
):
    pass


def WaterCoils_GetWaterCoilCapacity(
    state, coil_type: str, coil_name: str
) -> float:
    pass


def WaterCoils_GetCoilMaxWaterFlowRate(
    state, coil_type: str, coil_name: str
) -> float:
    pass
