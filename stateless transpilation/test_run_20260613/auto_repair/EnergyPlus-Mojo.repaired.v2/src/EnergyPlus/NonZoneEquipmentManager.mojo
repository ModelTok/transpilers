from .Data.EnergyPlusData import EnergyPlusData
from DataGlobals import *
from .InputProcessing.InputProcessor import InputProcessor
from WaterThermalTanks import SimulateWaterHeaterStandAlone
from WaterUse import SimulateWaterUse

def ManageNonZoneEquipment(inout state: EnergyPlusData,
                          FirstHVACIteration: Bool,
                          inout SimNonZoneEquipment: Bool // Simulation convergence flag
):
    # using WaterThermalTanks::SimulateWaterHeaterStandAlone;
    # using WaterUse::SimulateWaterUse;
    var CountNonZoneEquip: ref Bool = state.dataGlobal.CountNonZoneEquip  # reference
    if CountNonZoneEquip:
        state.dataGlobal.NumOfWaterHeater = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "WaterHeater:Mixed") +
                                             state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "WaterHeater:Stratified")
        CountNonZoneEquip = False
    SimulateWaterUse(state, FirstHVACIteration)  # simulate non-plant loop water use.
    if not state.dataGlobal.ZoneSizingCalc:
        for WaterHeaterNum in range(state.dataGlobal.NumOfWaterHeater):
            SimulateWaterHeaterStandAlone(state, WaterHeaterNum, FirstHVACIteration)
        # end for
    if FirstHVACIteration:
        SimNonZoneEquipment = True
    else:
        SimNonZoneEquipment = False
    # end if