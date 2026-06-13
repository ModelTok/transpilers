from algorithm import *
from cmath import *
from format import *
from set import *
from string import *
from ObjexxFCL.Array.functions import *
from Elements import *
from Solver import *
from ...BranchNodeConnections import *
from ...Coils.CoilCoolingDX import *
from ...Construction import *
from ...CurveManager import *
from ...DXCoils import *
from ...Data.EnergyPlusData import *
from ...DataAirLoop import *
from ...DataAirSystems import *
from ...DataBranchNodeConnections import *
from ...DataContaminantBalance import *
from ...DataDefineEquip import *
from ...DataEnvironment import *
from ...DataHVACGlobals import *
from ...DataHeatBalFanSys import *
from ...DataHeatBalSurface import *
from ...DataHeatBalance import *
from ...DataLoopNode import *
from ...DataRoomAirModel import *
from ...DataSurfaces import *
from ...DataZoneEquipment import *
from ...EMSManager import *
from ...Fans import *
from ...General import *
from ...GeneralRoutines import *
from ...GlobalNames import *
from ...HVACHXAssistedCoolingCoil import *
from ...HVACStandAloneERV import *
from ...HVACVariableRefrigerantFlow import *
from ...HeatingCoils import *
from ...InputProcessing.InputProcessor import *
from ...MixedAir import *
from ...NodeInputManager import *
from ...OutAirNodeManager import *
from ...OutputProcessor import *
from ...Psychrometrics import *
from ...RoomAirModelManager import *
from ...ScheduleManager import *
from ...SingleDuct import *
from ...SplitterComponent import *
from ...ThermalComfort import *
from ...UnitarySystem import *
from ...UtilityRoutines import *
from ...WaterThermalTanks import *
from ...WindowAC import *
from ...ZoneDehumidifier import *
from ...ZoneTempPredictorCorrector import *
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
