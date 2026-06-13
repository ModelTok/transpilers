from algorithm import *
from cmath import *
from format import *
from set import *
from string import *
from ObjexxFCL.Array.functions import *
from Elements import *
from Solver import *
from EnergyPlus.BranchNodeConnections import *
from EnergyPlus.Coils.CoilCoolingDX import *
from EnergyPlus.Construction import *
from EnergyPlus.CurveManager import *
from EnergyPlus.DXCoils import *
from EnergyPlus.Data.EnergyPlusData import *
from EnergyPlus.DataAirLoop import *
from EnergyPlus.DataAirSystems import *
from EnergyPlus.DataBranchNodeConnections import *
from EnergyPlus.DataContaminantBalance import *
from EnergyPlus.DataDefineEquip import *
from EnergyPlus.DataEnvironment import *
from EnergyPlus.DataHVACGlobals import *
from EnergyPlus.DataHeatBalFanSys import *
from EnergyPlus.DataHeatBalSurface import *
from EnergyPlus.DataHeatBalance import *
from EnergyPlus.DataLoopNode import *
from EnergyPlus.DataRoomAirModel import *
from EnergyPlus.DataSurfaces import *
from EnergyPlus.DataZoneEquipment import *
from EnergyPlus.EMSManager import *
from EnergyPlus.Fans import *
from EnergyPlus.General import *
from EnergyPlus.GeneralRoutines import *
from EnergyPlus.GlobalNames import *
from EnergyPlus.HVACHXAssistedCoolingCoil import *
from EnergyPlus.HVACStandAloneERV import *
from EnergyPlus.HVACVariableRefrigerantFlow import *
from EnergyPlus.HeatingCoils import *
from EnergyPlus.InputProcessing.InputProcessor import *
from EnergyPlus.MixedAir import *
from EnergyPlus.NodeInputManager import *
from EnergyPlus.OutAirNodeManager import *
from EnergyPlus.OutputProcessor import *
from EnergyPlus.Psychrometrics import *
from EnergyPlus.RoomAirModelManager import *
from EnergyPlus.ScheduleManager import *
from EnergyPlus.SingleDuct import *
from EnergyPlus.SplitterComponent import *
from EnergyPlus.ThermalComfort import *
from EnergyPlus.UnitarySystem import *
from EnergyPlus.UtilityRoutines import *
from EnergyPlus.WaterThermalTanks import *
from EnergyPlus.WindowAC import *
from EnergyPlus.ZoneDehumidifier import *
from EnergyPlus.ZoneTempPredictorCorrector import *
namespace EnergyPlus:
    namespace AirflowNetwork:
        from Curve import CurveValue
        from Curve import GetCurveIndex
        from DataEnvironment import OutDryBulbTempAt
        from DataSurfaces import cExtBoundCondition
        from DataSurfaces import ExternalEnvironment
        from DataSurfaces import OtherSideCoefNoCalcExt
        from DataSurfaces import SurfaceClass
        from Fans import GetFanIndex
        from Psychrometrics import PsyCpAirFnW
        from Psychrometrics import PsyHFnTdbW
        from Psychrometrics import PsyRhoAirFnPbTdbW
        struct Solver:
            var m_state: EnergyPlusData
            var properties: AirflowNetworkProperty
            def __init__(inout self, state: EnergyPlusData):
                self.m_state = state
                self.properties = AirflowNetworkProperty(state)
            const NumOfVentCtrTypes = 6
            def manage_balance(inout self, 
                              FirstHVACIteration: Optional_bool_const = Optional_bool_const(), 
                              Iter: Optional_int_const = Optional_int_const(), 
                              ResimulateAirZone: Optional_bool = Optional_bool()):
