# Translation of HeatBalanceInternalHeatGains.cc to Mojo (faithful, 1:1)
from Data.EnergyPlusData import EnergyPlusData
from DataHeatBalance import (
    DataHeatBalance,
    IntGainType,
    IntGainTypeNamesCC,
    SpaceIntGainDeviceData,  # type containing device, numberOfDevices, maxNumberOfDevices
)
from UtilityRoutines import makeUPPER, ShowSevereError, ShowContinueError

# Constant array from header (used in body)
alias AdjustTankLossMultipliers = List[IntGainType](
    IntGainType.WaterHeaterMixed,
    IntGainType.WaterHeaterStratified,
    IntGainType.ThermalStorageChilledWaterMixed,
    IntGainType.ThermalStorageChilledWaterStratified,
)

def SetupZoneInternalGain(
    ref state: EnergyPlusData,
    ZoneNum: Int,
    cComponentName: String,
    IntGainCompType: IntGainType,
    ConvectionGainRate: Float64 = None,
    ReturnAirConvectionGainRate: Float64 = None,
    ThermalRadiationGainRate: Float64 = None,
    LatentGainRate: Float64 = None,
    ReturnAirLatentGainRate: Float64 = None,
    CarbonDioxideGainRate: Float64 = None,
    GenericContamGainRate: Float64 = None,
    RetNodeNum: Int = 0,
):
    var gainFrac: Float64 = 1.0
    # zone spaceIndexes is 0‑based (converted from C++ 1‑based)
    for spaceNum in range(state.dataHeatBal.Zone[ZoneNum].spaceIndexes.len):
        var spIdx = state.dataHeatBal.Zone[ZoneNum].spaceIndexes[spaceNum]
        if state.dataHeatBal.Zone[ZoneNum].numSpaces > 1:
            gainFrac = state.dataHeatBal.space[spIdx].FloorArea / state.dataHeatBal.Zone[ZoneNum].FloorArea
        SetupSpaceInternalGain(
            state,
            spIdx,
            gainFrac,
            cComponentName,
            IntGainCompType,
            ConvectionGainRate,
            ReturnAirConvectionGainRate,
            ThermalRadiationGainRate,
            LatentGainRate,
            ReturnAirLatentGainRate,
            CarbonDioxideGainRate,
            GenericContamGainRate,
            RetNodeNum,
        )

def SetupSpaceInternalGain(
    ref state: EnergyPlusData,
    spaceNum: Int,
    spaceGainFraction: Float64,
    cComponentName: String,
    IntGainCompType: IntGainType,
    ConvectionGainRate: Float64 = None,
    ReturnAirConvectionGainRate: Float64 = None,
    ThermalRadiationGainRate: Float64 = None,
    LatentGainRate: Float64 = None,
    ReturnAirLatentGainRate: Float64 = None,
    CarbonDioxideGainRate: Float64 = None,
    GenericContamGainRate: Float64 = None,
    RetNodeNum: Int = 0,
):
    let DeviceAllocInc: Int = 100
    var FoundDuplicate: Bool = False
    var UpperCaseObjectName: String = makeUPPER(cComponentName)
    # Access space internal gain device data (0‑based)
    var thisIntGain: ref[SpaceIntGainDeviceData] = state.dataHeatBal.spaceIntGainDevices[spaceNum]
    # Loop from 0 to numberOfDevices‑1 (C++ loop starts at 1)
    for IntGainsNum in range(thisIntGain.numberOfDevices):
        if (thisIntGain.device[IntGainsNum].CompType == IntGainCompType) and (
            thisIntGain.device[IntGainsNum].CompObjectName == UpperCaseObjectName
        ):
            FoundDuplicate = True
            break
    if FoundDuplicate:
        ShowSevereError(
            state,
            "SetupZoneInternalGain: developer error, trapped duplicate internal gains sent to SetupZoneInternalGain",
        )
        ShowContinueError(
            state,
            String.format("The duplicate object user name ={}", cComponentName),
        )
        ShowContinueError(
            state,
            String.format(
                "The duplicate object type = {}",
                IntGainTypeNamesCC[Int(IntGainCompType)],
            ),
        )
        ShowContinueError(state, "This internal gain will not be modeled, and the simulation continues")
        return
    if thisIntGain.numberOfDevices == 0:
        # Pre‑allocate device list with DeviceAllocInc default elements
        thisIntGain.device = List[thisIntGain.device.element_type]()
        thisIntGain.device.resize(DeviceAllocInc)
        thisIntGain.maxNumberOfDevices = DeviceAllocInc
    else:
        if thisIntGain.numberOfDevices + 1 > thisIntGain.maxNumberOfDevices:
            thisIntGain.maxNumberOfDevices += DeviceAllocInc
            thisIntGain.device.resize(thisIntGain.maxNumberOfDevices)
    # Increment count (C++ does ++)
    thisIntGain.numberOfDevices += 1
    # Use 0‑based index = numberOfDevices‑1 (C++ uses new count as 1‑based index)
    let devIdx = thisIntGain.numberOfDevices - 1
    thisIntGain.device[devIdx].CompObjectName = UpperCaseObjectName
    thisIntGain.device[devIdx].CompType = IntGainCompType
    # Check if device type matches one of the tank loss multipliers (loop for find)
    var isTankLossMult = False
    for adj in AdjustTankLossMultipliers:
        if adj == IntGainCompType:
            isTankLossMult = True
            break
    if isTankLossMult:
        let zoneNum = state.dataHeatBal.space[spaceNum].zoneNum
        let multiplier = state.dataHeatBal.Zone[zoneNum].Multiplier * state.dataHeatBal.Zone[zoneNum].ListMultiplier
        if multiplier > 1:
            spaceGainFraction /= multiplier
    thisIntGain.device[devIdx].spaceGainFrac = spaceGainFraction
    if ConvectionGainRate != None:
        thisIntGain.device[devIdx].PtrConvectGainRate = ConvectionGainRate
    else:
        thisIntGain.device[devIdx].PtrConvectGainRate = state.dataHeatBal.zeroPointerVal
    if ReturnAirConvectionGainRate != None:
        thisIntGain.device[devIdx].PtrReturnAirConvGainRate = ReturnAirConvectionGainRate
    else:
        thisIntGain.device[devIdx].PtrReturnAirConvGainRate = state.dataHeatBal.zeroPointerVal
    if ThermalRadiationGainRate != None:
        thisIntGain.device[devIdx].PtrRadiantGainRate = ThermalRadiationGainRate
    else:
        thisIntGain.device[devIdx].PtrRadiantGainRate = state.dataHeatBal.zeroPointerVal
    if LatentGainRate != None:
        thisIntGain.device[devIdx].PtrLatentGainRate = LatentGainRate
    else:
        thisIntGain.device[devIdx].PtrLatentGainRate = state.dataHeatBal.zeroPointerVal
    if ReturnAirLatentGainRate != None:
        thisIntGain.device[devIdx].PtrReturnAirLatentGainRate = ReturnAirLatentGainRate
    else:
        thisIntGain.device[devIdx].PtrReturnAirLatentGainRate = state.dataHeatBal.zeroPointerVal
    if CarbonDioxideGainRate != None:
        thisIntGain.device[devIdx].PtrCarbonDioxideGainRate = CarbonDioxideGainRate
    else:
        thisIntGain.device[devIdx].PtrCarbonDioxideGainRate = state.dataHeatBal.zeroPointerVal
    if GenericContamGainRate != None:
        thisIntGain.device[devIdx].PtrGenericContamGainRate = GenericContamGainRate
    else:
        thisIntGain.device[devIdx].PtrGenericContamGainRate = state.dataHeatBal.zeroPointerVal
    thisIntGain.device[devIdx].ReturnAirNodeNum = RetNodeNum