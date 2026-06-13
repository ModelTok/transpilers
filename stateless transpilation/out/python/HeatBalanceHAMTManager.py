"""
HeatBalanceHAMTManager: Heat and Moisture Transfer Model for Building Surfaces
Converted from EnergyPlus C++ (HeatBalanceHAMTManager.hh/cc)
"""

from dataclasses import dataclass, field
from typing import List, Optional, Protocol
import math

# EXTERNAL DEPS (to wire in glue):
# EnergyPlusData: main simulation state object (EnergyPlus)
# Material: material properties and database (EnergyPlus.Material)
# DataSurfaces: surface definitions and constants (EnergyPlus.DataSurfaces)
# DataHeatBalance: heat balance state (EnergyPlus.DataHeatBalance)
# DataEnvironment: environment conditions (EnergyPlus.DataEnvironment)
# DataHeatBalSurface: surface heat balance data (EnergyPlus.DataHeatBalSurface)
# DataMoistureBalance: moisture balance state (EnergyPlus.DataMoistureBalance)
# Psychrometrics.PsyRhFnTdbRhov: RH from T, density (EnergyPlus.Psychrometrics)
# Psychrometrics.PsyPsatFnTemp: saturation vapor pressure (EnergyPlus.Psychrometrics)
# Construction: construction definitions (EnergyPlus.Construction)
# DataIPShortCuts: input processing (EnergyPlus.DataIPShortCuts)
# OutputProcessor: output reporting (EnergyPlus.OutputProcessor)
# UtilityRoutines: error/message handling (EnergyPlus.UtilityRoutines)
# ZoneTempPredictorCorrector: zone temperature (EnergyPlus.ZoneTempPredictorCorrector)

# CONSTANTS
ITTERMAX = 150
ADJMAX = 6

WDENSITY = 1000.0
WSPECH = 4180.0
WHV = 2489000.0
CONVT = 0.002
QVPLIM = 100000.0
RHMAX = 1.01

# Physical constants
KELVIN = 273.15
PI = math.pi


@dataclass
class MaterialBase:
    """Stub for Material::MaterialBase"""
    Name: str = ""
    group: int = 0
    ROnly: bool = False
    Thickness: float = 0.0
    Conductivity: float = 0.0
    Density: float = 0.0
    SpecHeat: float = 0.0
    NominalR: float = 0.0
    Num: int = 0
    hasHAMT: bool = False


@dataclass
class MaterialHAMT(MaterialBase):
    """HAMT material properties"""
    niso: int = -1
    isodata: List[float] = field(default_factory=lambda: [0.0] * 27)
    isorh: List[float] = field(default_factory=lambda: [0.0] * 27)
    nsuc: int = -1
    sucdata: List[float] = field(default_factory=lambda: [0.0] * 27)
    sucwater: List[float] = field(default_factory=lambda: [0.0] * 27)
    nred: int = -1
    reddata: List[float] = field(default_factory=lambda: [0.0] * 27)
    redwater: List[float] = field(default_factory=lambda: [0.0] * 27)
    nmu: int = -1
    mudata: List[float] = field(default_factory=lambda: [0.0] * 27)
    murh: List[float] = field(default_factory=lambda: [0.0] * 27)
    ntc: int = -1
    tcdata: List[float] = field(default_factory=lambda: [0.0] * 27)
    tcwater: List[float] = field(default_factory=lambda: [0.0] * 27)
    itemp: float = 10.0
    irh: float = 0.5
    iwater: float = 0.2
    divs: int = 3
    divsize: float = 0.005
    divmin: int = 3
    divmax: int = 10
    Porosity: float = 0.0

    def __post_init__(self):
        if self.group == 0:
            self.group = 1


@dataclass
class Subcell:
    """Subcell for discretized material"""
    matid: int = -1
    sid: int = -1
    Qadds: float = 0.0
    density: float = -1.0
    wthermalc: float = 0.0
    spech: float = 0.0
    htc: float = -1.0
    vtc: float = -1.0
    mu: float = -1.0
    volume: float = 0.0
    temp: float = 0.0
    tempp1: float = 0.0
    tempp2: float = 0.0
    wreport: float = 0.0
    water: float = 0.0
    vp: float = 0.0
    vpp1: float = 0.0
    vpsat: float = 0.0
    rh: float = 0.1
    rhp1: float = 0.1
    rhp2: float = 0.1
    rhp: float = 10.0
    dwdphi: float = -1.0
    dw: float = -1.0
    origin: List[float] = field(default_factory=lambda: [0.0, 0.0, 0.0])
    length: List[float] = field(default_factory=lambda: [0.0, 0.0, 0.0])
    overlap: List[float] = field(default_factory=lambda: [0.0] * 6)
    dist: List[float] = field(default_factory=lambda: [0.0] * 6)
    adjs: List[int] = field(default_factory=lambda: [-1] * 6)
    adjsl: List[int] = field(default_factory=lambda: [-1] * 6)


@dataclass
class HeatBalHAMTMgrData:
    """Global HAMT manager state"""
    firstcell: List[int] = field(default_factory=list)
    lastcell: List[int] = field(default_factory=list)
    Extcell: List[int] = field(default_factory=list)
    ExtRadcell: List[int] = field(default_factory=list)
    ExtConcell: List[int] = field(default_factory=list)
    ExtSkycell: List[int] = field(default_factory=list)
    ExtGrncell: List[int] = field(default_factory=list)
    Intcell: List[int] = field(default_factory=list)
    IntConcell: List[int] = field(default_factory=list)
    watertot: List[float] = field(default_factory=list)
    surfrh: List[float] = field(default_factory=list)
    surfextrh: List[float] = field(default_factory=list)
    surftemp: List[float] = field(default_factory=list)
    surfexttemp: List[float] = field(default_factory=list)
    surfvp: List[float] = field(default_factory=list)
    extvtc: List[float] = field(default_factory=list)
    intvtc: List[float] = field(default_factory=list)
    extvtcflag: List[bool] = field(default_factory=list)
    intvtcflag: List[bool] = field(default_factory=list)
    MyEnvrnFlag: List[bool] = field(default_factory=list)
    deltat: float = 0.0
    TotCellsMax: int = 0
    latswitch: bool = False
    rainswitch: bool = False
    cells: List[Subcell] = field(default_factory=list)
    OneTimeFlag: bool = True
    qvpErrCount: int = 0
    qvpErrReport: int = 0

    def clear_state(self):
        self.OneTimeFlag = True
        self.qvpErrCount = 0
        self.qvpErrReport = 0


class EnergyPlusDataProtocol(Protocol):
    """Protocol for EnergyPlusData state object"""
    dataHeatBalHAMTMgr: HeatBalHAMTMgrData
    dataGlobal: object
    dataSurface: object
    dataConstruction: object
    dataMaterial: object
    dataEnvironment: object
    dataMstBal: object
    dataHeatBalSurf: object
    dataInputProcessing: object
    dataZoneTempPredictorCorrector: object
    files: object


def manage_heat_bal_hamt(state: EnergyPlusDataProtocol, surf_num: int,
                         surf_temp_in_tmp: list, temp_surf_out_tmp: list) -> None:
    """
    Manage Heat and Moisture Transfer calculations
    
    Args:
        state: EnergyPlus state object
        surf_num: Surface number
        surf_temp_in_tmp: [output] internal surface temperature
        temp_surf_out_tmp: [output] external surface temperature
    """
    if state.dataHeatBalHAMTMgr.OneTimeFlag:
        state.dataHeatBalHAMTMgr.OneTimeFlag = False
        get_heat_bal_hamt_input(state)
        init_heat_bal_hamt(state)
    
    calc_heat_bal_hamt(state, surf_num, surf_temp_in_tmp, temp_surf_out_tmp)


def get_heat_bal_hamt_input(state: EnergyPlusDataProtocol) -> None:
    """Get HAMT input from IDD"""
    routine_name = "GetHeatBalHAMTInput"
    
    c_hamt_object1 = "MaterialProperty:HeatAndMoistureTransfer:Settings"
    c_hamt_object2 = "MaterialProperty:HeatAndMoistureTransfer:SorptionIsotherm"
    c_hamt_object3 = "MaterialProperty:HeatAndMoistureTransfer:Suction"
    c_hamt_object4 = "MaterialProperty:HeatAndMoistureTransfer:Redistribution"
    c_hamt_object5 = "MaterialProperty:HeatAndMoistureTransfer:Diffusion"
    c_hamt_object6 = "MaterialProperty:HeatAndMoistureTransfer:ThermalConductivity"
    c_hamt_object7 = "SurfaceProperties:VaporCoefficients"
    
    errors_found = False
    
    s_ip = state.dataInputProcessing.inputProcessor
    s_mat = state.dataMaterial
    
    tot_surfaces = state.dataSurface.TotSurfaces
    
    state.dataHeatBalHAMTMgr.watertot = [0.0] * (tot_surfaces + 1)
    state.dataHeatBalHAMTMgr.surfrh = [0.0] * (tot_surfaces + 1)
    state.dataHeatBalHAMTMgr.surfextrh = [0.0] * (tot_surfaces + 1)
    state.dataHeatBalHAMTMgr.surftemp = [0.0] * (tot_surfaces + 1)
    state.dataHeatBalHAMTMgr.surfexttemp = [0.0] * (tot_surfaces + 1)
    state.dataHeatBalHAMTMgr.surfvp = [0.0] * (tot_surfaces + 1)
    
    state.dataHeatBalHAMTMgr.firstcell = [0] * (tot_surfaces + 1)
    state.dataHeatBalHAMTMgr.lastcell = [0] * (tot_surfaces + 1)
    state.dataHeatBalHAMTMgr.Extcell = [0] * (tot_surfaces + 1)
    state.dataHeatBalHAMTMgr.ExtRadcell = [0] * (tot_surfaces + 1)
    state.dataHeatBalHAMTMgr.ExtConcell = [0] * (tot_surfaces + 1)
    state.dataHeatBalHAMTMgr.ExtSkycell = [0] * (tot_surfaces + 1)
    state.dataHeatBalHAMTMgr.ExtGrncell = [0] * (tot_surfaces + 1)
    state.dataHeatBalHAMTMgr.Intcell = [0] * (tot_surfaces + 1)
    state.dataHeatBalHAMTMgr.IntConcell = [0] * (tot_surfaces + 1)
    
    state.dataHeatBalHAMTMgr.extvtc = [-1.0] * (tot_surfaces + 1)
    state.dataHeatBalHAMTMgr.intvtc = [-1.0] * (tot_surfaces + 1)
    state.dataHeatBalHAMTMgr.extvtcflag = [False] * (tot_surfaces + 1)
    state.dataHeatBalHAMTMgr.intvtcflag = [False] * (tot_surfaces + 1)
    state.dataHeatBalHAMTMgr.MyEnvrnFlag = [True] * (tot_surfaces + 1)
    
    state.dataHeatBalHAMTMgr.latswitch = True
    state.dataHeatBalHAMTMgr.rainswitch = True
    
    # Process MaterialProperty:HeatAndMoistureTransfer:Settings
    hamt_items = s_ip.getNumObjectsFound(state, c_hamt_object1)
    for item in range(1, hamt_items + 1):
        alpha_array = s_ip.getObjectItem(state, c_hamt_object1, item)
        
        mat_num = s_mat.GetMaterialNum(state, alpha_array[0])
        if mat_num == 0:
            errors_found = True
            continue
        
        mat = s_mat.materials[mat_num]
        if mat.ROnly:
            continue
        
        mat_hamt = MaterialHAMT(**vars(mat))
        s_mat.materials[mat_num] = mat_hamt
        
        mat_hamt.hasHAMT = True
        if len(alpha_array) > 3:
            mat_hamt.Porosity = float(alpha_array[3])
        if len(alpha_array) > 4:
            mat_hamt.iwater = float(alpha_array[4])
    
    # Process MaterialProperty:HeatAndMoistureTransfer:SorptionIsotherm
    hamt_items = s_ip.getNumObjectsFound(state, c_hamt_object2)
    for item in range(1, hamt_items + 1):
        alpha_array = s_ip.getObjectItem(state, c_hamt_object2, item)
        num_array = s_ip.getNumericFields(state, c_hamt_object2, item)
        
        mat_num = s_mat.GetMaterialNum(state, alpha_array[0])
        if mat_num == 0 or mat_num >= len(s_mat.materials):
            errors_found = True
            continue
        
        mat = s_mat.materials[mat_num]
        if not isinstance(mat, MaterialHAMT):
            continue
        
        mat_hamt = mat
        numid = 0
        mat_hamt.niso = int(num_array[numid])
        
        for iso in range(1, mat_hamt.niso + 1):
            numid += 1
            mat_hamt.isorh[iso - 1] = num_array[numid]
            numid += 1
            mat_hamt.isodata[iso - 1] = num_array[numid]
        
        mat_hamt.niso += 1
        mat_hamt.isorh[mat_hamt.niso - 1] = RHMAX
        mat_hamt.isodata[mat_hamt.niso - 1] = mat_hamt.Porosity * WDENSITY
        
        mat_hamt.niso += 1
        mat_hamt.isorh[mat_hamt.niso - 1] = 0.0
        mat_hamt.isodata[mat_hamt.niso - 1] = 0.0
        
        # Sort isotherm
        for jj in range(1, mat_hamt.niso):
            for ii in range(jj + 1, mat_hamt.niso):
                if mat_hamt.isorh[jj - 1] > mat_hamt.isorh[ii - 1]:
                    mat_hamt.isorh[jj - 1], mat_hamt.isorh[ii - 1] = \
                        mat_hamt.isorh[ii - 1], mat_hamt.isorh[jj - 1]
                    mat_hamt.isodata[jj - 1], mat_hamt.isodata[ii - 1] = \
                        mat_hamt.isodata[ii - 1], mat_hamt.isodata[jj - 1]
        
        # Ensure data rises
        isoerrrise = False
        for _ in range(100):
            avflag = True
            for jj in range(1, mat_hamt.niso):
                if mat_hamt.isodata[jj - 1] > mat_hamt.isodata[jj]:
                    isoerrrise = True
                    avdata = (mat_hamt.isodata[jj - 1] + mat_hamt.isodata[jj]) / 2.0
                    mat_hamt.isodata[jj - 1] = avdata
                    mat_hamt.isodata[jj] = avdata
                    avflag = False
            if avflag:
                break
    
    # Process MaterialProperty:HeatAndMoistureTransfer:Suction
    hamt_items = s_ip.getNumObjectsFound(state, c_hamt_object3)
    for item in range(1, hamt_items + 1):
        alpha_array = s_ip.getObjectItem(state, c_hamt_object3, item)
        num_array = s_ip.getNumericFields(state, c_hamt_object3, item)
        
        mat_num = s_mat.GetMaterialNum(state, alpha_array[0])
        if mat_num == 0 or mat_num >= len(s_mat.materials):
            errors_found = True
            continue
        
        mat = s_mat.materials[mat_num]
        if not isinstance(mat, MaterialHAMT):
            continue
        
        mat_hamt = mat
        numid = 0
        mat_hamt.nsuc = int(num_array[numid])
        
        for suc in range(1, mat_hamt.nsuc + 1):
            numid += 1
            mat_hamt.sucwater[suc - 1] = num_array[numid]
            numid += 1
            mat_hamt.sucdata[suc - 1] = num_array[numid]
        
        mat_hamt.nsuc += 1
        mat_hamt.sucwater[mat_hamt.nsuc - 1] = mat_hamt.isodata[mat_hamt.niso - 1]
        mat_hamt.sucdata[mat_hamt.nsuc - 1] = mat_hamt.sucdata[mat_hamt.nsuc - 2]
    
    # Process MaterialProperty:HeatAndMoistureTransfer:Redistribution
    hamt_items = s_ip.getNumObjectsFound(state, c_hamt_object4)
    for item in range(1, hamt_items + 1):
        alpha_array = s_ip.getObjectItem(state, c_hamt_object4, item)
        num_array = s_ip.getNumericFields(state, c_hamt_object4, item)
        
        mat_num = s_mat.GetMaterialNum(state, alpha_array[0])
        if mat_num == 0 or mat_num >= len(s_mat.materials):
            errors_found = True
            continue
        
        mat = s_mat.materials[mat_num]
        if not isinstance(mat, MaterialHAMT):
            continue
        
        mat_hamt = mat
        numid = 0
        mat_hamt.nred = int(num_array[numid])
        
        for red in range(1, mat_hamt.nred + 1):
            numid += 1
            mat_hamt.redwater[red - 1] = num_array[numid]
            numid += 1
            mat_hamt.reddata[red - 1] = num_array[numid]
        
        mat_hamt.nred += 1
        mat_hamt.redwater[mat_hamt.nred - 1] = mat_hamt.isodata[mat_hamt.niso - 1]
        mat_hamt.reddata[mat_hamt.nred - 1] = mat_hamt.reddata[mat_hamt.nred - 2]
    
    # Process MaterialProperty:HeatAndMoistureTransfer:Diffusion
    hamt_items = s_ip.getNumObjectsFound(state, c_hamt_object5)
    for item in range(1, hamt_items + 1):
        alpha_array = s_ip.getObjectItem(state, c_hamt_object5, item)
        num_array = s_ip.getNumericFields(state, c_hamt_object5, item)
        
        mat_num = s_mat.GetMaterialNum(state, alpha_array[0])
        if mat_num == 0 or mat_num >= len(s_mat.materials):
            errors_found = True
            continue
        
        mat = s_mat.materials[mat_num]
        if not isinstance(mat, MaterialHAMT):
            continue
        
        mat_hamt = mat
        numid = 0
        mat_hamt.nmu = int(num_array[numid])
        
        if mat_hamt.nmu > 0:
            for mu in range(1, mat_hamt.nmu + 1):
                numid += 1
                mat_hamt.murh[mu - 1] = num_array[numid]
                numid += 1
                mat_hamt.mudata[mu - 1] = num_array[numid]
            
            mat_hamt.nmu += 1
            mat_hamt.murh[mat_hamt.nmu - 1] = mat_hamt.isorh[mat_hamt.niso - 1]
            mat_hamt.mudata[mat_hamt.nmu - 1] = mat_hamt.mudata[mat_hamt.nmu - 2]
    
    # Process MaterialProperty:HeatAndMoistureTransfer:ThermalConductivity
    hamt_items = s_ip.getNumObjectsFound(state, c_hamt_object6)
    for item in range(1, hamt_items + 1):
        alpha_array = s_ip.getObjectItem(state, c_hamt_object6, item)
        num_array = s_ip.getNumericFields(state, c_hamt_object6, item)
        
        mat_num = s_mat.GetMaterialNum(state, alpha_array[0])
        if mat_num == 0 or mat_num >= len(s_mat.materials):
            errors_found = True
            continue
        
        mat = s_mat.materials[mat_num]
        if not isinstance(mat, MaterialHAMT):
            continue
        
        mat_hamt = mat
        numid = 0
        mat_hamt.ntc = int(num_array[numid])
        
        if mat_hamt.ntc > 0:
            for tc in range(1, mat_hamt.ntc + 1):
                numid += 1
                mat_hamt.tcwater[tc - 1] = num_array[numid]
                numid += 1
                mat_hamt.tcdata[tc - 1] = num_array[numid]
            
            mat_hamt.ntc += 1
            mat_hamt.tcwater[mat_hamt.ntc - 1] = mat_hamt.isodata[mat_hamt.niso - 1]
            mat_hamt.tcdata[mat_hamt.ntc - 1] = mat_hamt.tcdata[mat_hamt.ntc - 2]
    
    # Process SurfaceProperties:VaporCoefficients
    hamt_items = s_ip.getNumObjectsFound(state, c_hamt_object7)
    for item in range(1, hamt_items + 1):
        alpha_array = s_ip.getObjectItem(state, c_hamt_object7, item)
        num_array = s_ip.getNumericFields(state, c_hamt_object7, item)
        
        vtcsid = find_item_in_list(alpha_array[0], state.dataSurface.Surface)
        if vtcsid <= 0 or vtcsid > len(state.dataHeatBalHAMTMgr.extvtc) - 1:
            errors_found = True
            continue
        
        if len(alpha_array) > 1 and alpha_array[1] == "YES":
            state.dataHeatBalHAMTMgr.extvtcflag[vtcsid] = True
            if len(num_array) > 0:
                state.dataHeatBalHAMTMgr.extvtc[vtcsid] = num_array[0]
        
        if len(alpha_array) > 2 and alpha_array[2] == "YES":
            state.dataHeatBalHAMTMgr.intvtcflag[vtcsid] = True
            if len(num_array) > 1:
                state.dataHeatBalHAMTMgr.intvtc[vtcsid] = num_array[1]


def init_heat_bal_hamt(state: EnergyPlusDataProtocol) -> None:
    """Initialize HAMT calculations"""
    adjdist = 0.00005
    routine_name = "InitCombinedHeatAndMoistureFiniteElement"
    
    s_mat = state.dataMaterial
    s_hbh = state.dataHeatBalHAMTMgr
    
    s_hbh.deltat = state.dataGlobal.TimeStepZone * 3600.0
    
    error_count = 0
    s_hbh.TotCellsMax = 0
    
    for sid in range(1, state.dataSurface.TotSurfaces + 1):
        surf = state.dataSurface.Surface[sid]
        if surf.Class == 5:
            continue
        if surf.HeatTransferAlgorithm != 6:
            continue
        if surf.Construction <= 0:
            continue
        
        constr = state.dataConstruction.Construct[surf.Construction]
        
        for lid in range(1, constr.TotLayers + 1):
            mat = s_mat.materials[constr.LayerPoint[lid]]
            if mat.ROnly:
                error_count += 1
                continue
            
            if not isinstance(mat, MaterialHAMT):
                mat = MaterialHAMT(**vars(mat))
                s_mat.materials[constr.LayerPoint[lid]] = mat
            
            mat_hamt = mat
            
            if mat_hamt.nmu < 0:
                error_count += 1
            if mat_hamt.niso < 0:
                error_count += 1
            if mat_hamt.nsuc < 0:
                error_count += 1
            if mat_hamt.nred < 0:
                error_count += 1
            if mat_hamt.ntc < 0:
                if mat_hamt.Conductivity > 0:
                    mat_hamt.ntc = 2
                    mat_hamt.tcwater[0] = 0.0
                    mat_hamt.tcdata[0] = mat_hamt.Conductivity
                    mat_hamt.tcwater[1] = mat_hamt.isodata[mat_hamt.niso - 1]
                    mat_hamt.tcdata[1] = mat_hamt.Conductivity
                else:
                    error_count += 1
            
            waterd = mat_hamt.iwater * mat_hamt.Density
            interp(mat_hamt.niso, mat_hamt.isodata, mat_hamt.isorh, waterd, mat_hamt.irh)
            
            mat_hamt.divs = int(mat_hamt.Thickness / mat_hamt.divsize) + mat_hamt.divmin
            if mat_hamt.divs > mat_hamt.divmax:
                mat_hamt.divs = mat_hamt.divmax
            
            sin_neg_pi_ovr2 = math.sin(-PI / 2.0)
            while True:
                testlen = mat_hamt.Thickness * (
                    (math.sin(PI * (-1.0 / float(mat_hamt.divs)) - PI / 2.0) / 2.0) -
                    (sin_neg_pi_ovr2 / 2.0)
                )
                if testlen > adjdist:
                    break
                mat_hamt.divs -= 1
                if mat_hamt.divs < 1:
                    error_count += 1
                    break
            
            s_hbh.TotCellsMax += mat_hamt.divs
        
        s_hbh.TotCellsMax += 7
    
    if error_count > 0:
        return
    
    s_hbh.cells = [Subcell() for _ in range(s_hbh.TotCellsMax + 1)]
    
    cid = 0
    
    for sid in range(1, state.dataSurface.TotSurfaces + 1):
        surf = state.dataSurface.Surface[sid]
        if not surf.HeatTransSurf:
            continue
        if surf.Class == 5:
            continue
        if surf.HeatTransferAlgorithm != 6:
            continue
        
        runor = -0.02
        
        cid += 1
        s_hbh.firstcell[sid] = cid
        s_hbh.ExtConcell[sid] = cid
        air_conv_cell = s_hbh.cells[cid]
        air_conv_cell.rh = 0.0
        air_conv_cell.sid = sid
        air_conv_cell.length[0] = 0.01
        air_conv_cell.origin[0] = air_conv_cell.length[0] / 2.0 + runor
        
        cid += 1
        s_hbh.ExtRadcell[sid] = cid
        air_rad_cell = s_hbh.cells[cid]
        air_rad_cell.rh = 0.0
        air_rad_cell.sid = sid
        air_rad_cell.length[0] = 0.01
        air_rad_cell.origin[0] = air_rad_cell.length[0] / 2.0 + runor
        
        cid += 1
        s_hbh.ExtSkycell[sid] = cid
        sky_cell = s_hbh.cells[cid]
        sky_cell.rh = 0.0
        sky_cell.sid = sid
        sky_cell.length[0] = 0.01
        sky_cell.origin[0] = sky_cell.length[0] / 2.0 + runor
        
        cid += 1
        s_hbh.ExtGrncell[sid] = cid
        ground_cell = s_hbh.cells[cid]
        ground_cell.rh = 0.0
        ground_cell.sid = sid
        ground_cell.length[0] = 0.01
        ground_cell.origin[0] = ground_cell.length[0] / 2.0 + runor
        runor += ground_cell.length[0]
        
        cid += 1
        s_hbh.Extcell[sid] = cid
        ext_virt_cell = s_hbh.cells[cid]
        ext_virt_cell.rh = 0.0
        ext_virt_cell.sid = sid
        ext_virt_cell.length[0] = 0.01
        ext_virt_cell.origin[0] = ext_virt_cell.length[0] / 2.0 + runor
        runor += ext_virt_cell.length[0]
        
        constr = state.dataConstruction.Construct[surf.Construction]
        for lid in range(1, constr.TotLayers + 1):
            mat = s_mat.materials[constr.LayerPoint[lid]]
            if not isinstance(mat, MaterialHAMT):
                mat = MaterialHAMT(**vars(mat))
            mat_hamt = mat
            
            for did in range(1, mat_hamt.divs + 1):
                cid += 1
                
                mat_cell = s_hbh.cells[cid]
                mat_cell.matid = mat_hamt.Num
                mat_cell.sid = sid
                
                mat_cell.temp = mat_hamt.itemp
                mat_cell.tempp1 = mat_hamt.itemp
                mat_cell.tempp2 = mat_hamt.itemp
                
                mat_cell.rh = mat_hamt.irh
                mat_cell.rhp1 = mat_hamt.irh
                mat_cell.rhp2 = mat_hamt.irh
                
                mat_cell.density = mat_hamt.Density
                mat_cell.spech = mat_hamt.SpecHeat
                
                sin_val_curr = math.sin(PI * (-float(did) / float(mat_hamt.divs)) - PI / 2.0) / 2.0
                sin_val_prev = math.sin(PI * (-float(did - 1) / float(mat_hamt.divs)) - PI / 2.0) / 2.0
                mat_cell.length[0] = mat_hamt.Thickness * (sin_val_curr - sin_val_prev)
                
                mat_cell.origin[0] = runor + mat_cell.length[0] / 2.0
                runor += mat_cell.length[0]
                
                mat_cell.volume = mat_cell.length[0] * surf.Area
        
        cid += 1
        s_hbh.Intcell[sid] = cid
        int_virt_cell = s_hbh.cells[cid]
        int_virt_cell.sid = sid
        int_virt_cell.rh = 0.0
        int_virt_cell.length[0] = 0.01
        int_virt_cell.origin[0] = int_virt_cell.length[0] / 2.0 + runor
        runor += int_virt_cell.length[0]
        
        cid += 1
        s_hbh.lastcell[sid] = cid
        s_hbh.IntConcell[sid] = cid
        air_conv_cell2 = s_hbh.cells[cid]
        air_conv_cell2.rh = 0.0
        air_conv_cell2.sid = sid
        air_conv_cell2.length[0] = 0.01
        air_conv_cell2.origin[0] = air_conv_cell2.length[0] / 2.0 + runor
    
    for cid1 in range(1, s_hbh.TotCellsMax + 1):
        for cid2 in range(1, s_hbh.TotCellsMax + 1):
            if cid1 == cid2:
                continue
            
            cell1 = s_hbh.cells[cid1]
            cell2 = s_hbh.cells[cid2]
            
            if cell1.sid != cell2.sid:
                continue
            
            high1 = cell1.origin[0] + cell1.length[0] / 2.0
            low2 = cell2.origin[0] - cell2.length[0] / 2.0
            
            if abs(low2 - high1) < adjdist:
                adj1 = 0
                for ii in range(1, ADJMAX + 1):
                    adj1 += 1
                    if cell1.adjs[adj1 - 1] == -1:
                        break
                
                adj2 = 0
                for ii in range(1, ADJMAX + 1):
                    adj2 += 1
                    if cell2.adjs[adj2 - 1] == -1:
                        break
                
                cell1.adjs[adj1 - 1] = cid2
                cell2.adjs[adj2 - 1] = cid1
                
                cell1.adjsl[adj1 - 1] = adj2
                cell2.adjsl[adj2 - 1] = adj1
                
                surf_num = cell1.sid
                cell1.overlap[adj1 - 1] = state.dataSurface.Surface[surf_num].Area
                cell2.overlap[adj2 - 1] = state.dataSurface.Surface[surf_num].Area
                cell1.dist[adj1 - 1] = cell1.length[0] / 2.0
                cell2.dist[adj2 - 1] = cell2.length[0] / 2.0


def calc_heat_bal_hamt(state: EnergyPlusDataProtocol, sid: int,
                       surf_temp_in_tmp: list, temp_surf_out_tmp: list) -> None:
    """Calculate heat and moisture transfer"""
    hamt_ext = "HAMT-Ext"
    hamt_int = "HAMT-Int"
    
    s_mat = state.dataMaterial
    s_hbh = state.dataHeatBalHAMTMgr
    
    if state.dataGlobal.BeginEnvrnFlag and s_hbh.MyEnvrnFlag[sid]:
        ext_cell = s_hbh.cells[s_hbh.Extcell[sid]]
        ext_cell.rh = 0.0
        ext_cell.rhp1 = 0.0
        ext_cell.rhp2 = 0.0
        ext_cell.temp = 10.0
        ext_cell.tempp1 = 10.0
        ext_cell.tempp2 = 10.0
        
        int_cell = s_hbh.cells[s_hbh.Intcell[sid]]
        int_cell.rh = 0.0
        int_cell.rhp1 = 0.0
        int_cell.rhp2 = 0.0
        int_cell.temp = 10.0
        int_cell.tempp1 = 10.0
        int_cell.tempp2 = 10.0
        
        for cid in range(s_hbh.Extcell[sid] + 1, s_hbh.Intcell[sid]):
            cell = s_hbh.cells[cid]
            mat = s_mat.materials[cell.matid]
            if isinstance(mat, MaterialHAMT):
                mat_hamt = mat
                cell.temp = mat_hamt.itemp
                cell.tempp1 = mat_hamt.itemp
                cell.tempp2 = mat_hamt.itemp
                cell.rh = mat_hamt.irh
                cell.rhp1 = mat_hamt.irh
                cell.rhp2 = mat_hamt.irh
        
        s_hbh.MyEnvrnFlag[sid] = False
    
    if not state.dataGlobal.BeginEnvrnFlag:
        s_hbh.MyEnvrnFlag[sid] = True
    
    ext_cell = s_hbh.cells[s_hbh.Extcell[sid]]
    ext_rad_cell = s_hbh.cells[s_hbh.ExtRadcell[sid]]
    ext_sky_cell = s_hbh.cells[s_hbh.ExtSkycell[sid]]
    ext_grn_cell = s_hbh.cells[s_hbh.ExtGrncell[sid]]
    ext_con_cell = s_hbh.cells[s_hbh.ExtConcell[sid]]
    
    ext_rad_cell.temp = state.dataMstBal.TempOutsideAirFD[sid]
    ext_con_cell.temp = state.dataMstBal.TempOutsideAirFD[sid]
    space_mat = state.dataZoneTempPredictorCorrector.spaceHeatBalance[state.dataSurface.Surface[sid].spaceNum].MAT
    
    if state.dataSurface.Surface[sid].ExtBoundCond == 12:
        ext_sky_cell.temp = state.dataSurface.OSCM[state.dataSurface.Surface[sid].OSCMPtr].TRad
        ext_cell.Qadds = 0.0
    else:
        ext_sky_cell.temp = state.dataEnvironment.SkyTemp
        ext_cell.Qadds = state.dataSurface.Surface[sid].Area * state.dataHeatBalSurf.SurfOpaqQRadSWOutAbs[sid]
    
    ext_grn_cell.temp = state.dataMstBal.TempOutsideAirFD[sid]
    rho_out = state.dataMstBal.RhoVaporAirOut[sid]
    
    if state.dataSurface.Surface[sid].ExtBoundCond == sid:
        ext_con_cell.temp = space_mat
        rho_out = state.dataMstBal.RhoVaporAirIn[sid]
    
    rho_in = state.dataMstBal.RhoVaporAirIn[sid]
    
    ext_rad_cell.htc = state.dataMstBal.HAirFD[sid]
    ext_con_cell.htc = state.dataMstBal.HConvExtFD[sid]
    ext_sky_cell.htc = state.dataMstBal.HSkyFD[sid]
    ext_grn_cell.htc = state.dataMstBal.HGrndFD[sid]
    
    int_cell = s_hbh.cells[s_hbh.Intcell[sid]]
    int_con_cell = s_hbh.cells[s_hbh.IntConcell[sid]]
    
    int_con_cell.temp = space_mat
    int_con_cell.htc = state.dataMstBal.HConvInFD[sid]
    
    int_cell.Qadds = state.dataSurface.Surface[sid].Area * (
        state.dataHeatBalSurf.SurfOpaqQRadSWInAbs[sid] +
        state.dataHeatBalSurf.SurfQdotRadNetLWInPerArea[sid] +
        state.dataHeatBalSurf.SurfQdotRadHVACInPerArea[sid] +
        state.dataHeatBal.SurfQdotRadIntGainsInPerArea[sid] +
        state.dataHeatBalSurf.SurfQAdditionalHeatSourceInside[sid]
    )
    
    ext_con_cell.rh = psychrometrics_psy_rh_fn_tdb_rhov(state, ext_con_cell.temp, rho_out, hamt_ext)
    int_con_cell.rh = psychrometrics_psy_rh_fn_tdb_rhov(state, int_con_cell.temp, rho_in, hamt_int)
    
    if ext_con_cell.rh > RHMAX:
        ext_con_cell.rh = RHMAX
    if int_con_cell.rh > RHMAX:
        int_con_cell.rh = RHMAX
    
    if s_hbh.extvtcflag[sid]:
        ext_con_cell.vtc = s_hbh.extvtc[sid]
    else:
        if ext_con_cell.rh > 0:
            ext_con_cell.vtc = (
                state.dataMstBal.HMassConvExtFD[sid] * rho_out /
                (psychrometrics_psy_psat_fn_temp(state, state.dataMstBal.TempOutsideAirFD[sid]) * ext_con_cell.rh)
            )
        else:
            ext_con_cell.vtc = 10000.0
    
    if s_hbh.intvtcflag[sid]:
        int_con_cell.vtc = s_hbh.intvtc[sid]
        state.dataMstBal.HMassConvInFD[sid] = (
            int_con_cell.vtc * psychrometrics_psy_psat_fn_temp(state, space_mat) * int_con_cell.rh / rho_in
        )
    else:
        if int_con_cell.rh > 0:
            int_con_cell.vtc = (
                state.dataMstBal.HMassConvInFD[sid] * rho_in /
                (psychrometrics_psy_psat_fn_temp(state, space_mat) * int_con_cell.rh)
            )
        else:
            int_con_cell.vtc = 10000.0
    
    for cid in range(s_hbh.firstcell[sid], s_hbh.Extcell[sid]):
        cell = s_hbh.cells[cid]
        cell.tempp1 = cell.temp
        cell.tempp2 = cell.temp
        cell.rhp1 = cell.rh
        cell.rhp2 = cell.rh
    
    for cid in range(s_hbh.Intcell[sid] + 1, s_hbh.lastcell[sid] + 1):
        cell = s_hbh.cells[cid]
        cell.tempp1 = cell.temp
        cell.tempp2 = cell.temp
        cell.rhp1 = cell.rh
        cell.rhp2 = cell.rh
    
    itter = 0
    while True:
        itter += 1
        
        for cid in range(s_hbh.firstcell[sid], s_hbh.lastcell[sid] + 1):
            cell = s_hbh.cells[cid]
            cell.vp = rh_to_vp(state, cell.rh, cell.temp)
            cell.vpp1 = rh_to_vp(state, cell.rhp1, cell.tempp1)
            cell.vpsat = psychrometrics_psy_psat_fn_temp(state, cell.tempp1)
            
            if cell.matid > 0:
                mat = s_mat.materials[cell.matid]
                if isinstance(mat, MaterialHAMT):
                    mat_hamt = mat
                    outwater = [0.0]
                    outgrad = [0.0]
                    interp(mat_hamt.niso, mat_hamt.isorh, mat_hamt.isodata, cell.rhp1, outwater, outgrad)
                    cell.water = outwater[0]
                    cell.dwdphi = outgrad[0]
                    
                    if state.dataEnvironment.IsRain and s_hbh.rainswitch:
                        outwater = [0.0]
                        interp(mat_hamt.nsuc, mat_hamt.sucwater, mat_hamt.sucdata, cell.water, outwater)
                        cell.dw = outwater[0]
                    else:
                        outwater = [0.0]
                        interp(mat_hamt.nred, mat_hamt.redwater, mat_hamt.reddata, cell.water, outwater)
                        cell.dw = outwater[0]
                    
                    outmu = [0.0]
                    interp(mat_hamt.nmu, mat_hamt.murh, mat_hamt.mudata, cell.rhp1, outmu)
                    cell.mu = outmu[0]
                    
                    outtc = [0.0]
                    interp(mat_hamt.ntc, mat_hamt.tcwater, mat_hamt.tcdata, cell.water, outtc)
                    cell.wthermalc = outtc[0]
        
        for cid in range(s_hbh.Extcell[sid], s_hbh.Intcell[sid] + 1):
            torsum = 0.0
            oorsum = 0.0
            vpdiff = 0.0
            cell = s_hbh.cells[cid]
            
            for ii in range(1, ADJMAX + 1):
                adj = cell.adjs[ii - 1]
                adjl = cell.adjsl[ii - 1]
                
                if adj == -1:
                    break
                
                if cell.htc > 0:
                    thermr1 = 1.0 / (cell.overlap[ii - 1] * cell.htc)
                elif cell.matid > 0:
                    thermr1 = cell.dist[ii - 1] / (cell.overlap[ii - 1] * cell.wthermalc)
                else:
                    thermr1 = 0.0
                
                if cell.vtc > 0:
                    vaporr1 = 1.0 / (cell.overlap[ii - 1] * cell.vtc)
                elif cell.matid > 0:
                    vaporr1 = (cell.dist[ii - 1] * cell.mu) / (
                        cell.overlap[ii - 1] * wvdc(cell.tempp1, state.dataEnvironment.OutBaroPress)
                    )
                else:
                    vaporr1 = 0.0
                
                adj_cell = s_hbh.cells[adj]
                
                if adj_cell.htc > 0:
                    thermr2 = 1.0 / (cell.overlap[ii - 1] * adj_cell.htc)
                elif adj_cell.matid > 0:
                    thermr2 = adj_cell.dist[adjl - 1] / (cell.overlap[ii - 1] * adj_cell.wthermalc)
                else:
                    thermr2 = 0.0
                
                if adj_cell.vtc > 0:
                    vaporr2 = 1.0 / (cell.overlap[ii - 1] * adj_cell.vtc)
                elif adj_cell.matid > 0:
                    vaporr2 = (adj_cell.mu * adj_cell.dist[adjl - 1]) / (
                        wvdc(adj_cell.tempp1, state.dataEnvironment.OutBaroPress) * cell.overlap[ii - 1]
                    )
                else:
                    vaporr2 = 0.0
                
                if thermr1 + thermr2 > 0:
                    oorsum += 1.0 / (thermr1 + thermr2)
                    torsum += adj_cell.tempp1 / (thermr1 + thermr2)
                
                if vaporr1 + vaporr2 > 0:
                    vpdiff += (adj_cell.vp - cell.vp) / (vaporr1 + vaporr2)
            
            tcap = (cell.density * cell.spech + cell.water * WSPECH) * cell.volume
            
            qvp = 0.0
            if cell.matid > 0 and s_hbh.latswitch:
                qvp = vpdiff * WHV
            
            if abs(qvp) > QVPLIM:
                if not state.dataGlobal.WarmupFlag:
                    s_hbh.qvpErrCount += 1
                qvp = 0.0
            
            cell.tempp1 = (torsum + qvp + cell.Qadds + (tcap * cell.temp / s_hbh.deltat)) / (
                oorsum + (tcap / s_hbh.deltat)
            )
        
        tempmax = max([s_hbh.cells[cid].tempp1 for cid in range(1, s_hbh.TotCellsMax + 1)])
        tempmin = min([s_hbh.cells[cid].tempp1 for cid in range(1, s_hbh.TotCellsMax + 1)])
        
        for cid in range(s_hbh.Extcell[sid], s_hbh.Intcell[sid] + 1):
            phioosum = 0.0
            phiorsum = 0.0
            vpoosum = 0.0
            vporsum = 0.0
            
            cell = s_hbh.cells[cid]
            
            for ii in range(1, ADJMAX + 1):
                adj = cell.adjs[ii - 1]
                adjl = cell.adjsl[ii - 1]
                
                if adj == -1:
                    break
                
                if cell.vtc > 0:
                    vaporr1 = 1.0 / (cell.overlap[ii - 1] * cell.vtc)
                elif cell.matid > 0:
                    vaporr1 = (cell.dist[ii - 1] * cell.mu) / (
                        cell.overlap[ii - 1] * wvdc(cell.tempp1, state.dataEnvironment.OutBaroPress)
                    )
                else:
                    vaporr1 = 0.0
                
                adj_cell = s_hbh.cells[adj]
                
                if adj_cell.vtc > 0:
                    vaporr2 = 1.0 / (cell.overlap[ii - 1] * adj_cell.vtc)
                elif adj_cell.matid > 0:
                    vaporr2 = (adj_cell.dist[adjl - 1] * adj_cell.mu) / (
                        cell.overlap[ii - 1] * wvdc(adj_cell.tempp1, state.dataEnvironment.OutBaroPress)
                    )
                else:
                    vaporr2 = 0.0
                
                if vaporr1 + vaporr2 > 0:
                    vpoosum += 1.0 / (vaporr1 + vaporr2)
                    vporsum += adj_cell.vpp1 / (vaporr1 + vaporr2)
                
                if cell.dw > 0 and cell.dwdphi > 0:
                    rhr1 = cell.dist[ii - 1] / (cell.overlap[ii - 1] * cell.dw * cell.dwdphi)
                else:
                    rhr1 = 0.0
                
                if adj_cell.dw > 0 and adj_cell.dwdphi > 0:
                    rhr2 = adj_cell.dist[adjl - 1] / (cell.overlap[ii - 1] * adj_cell.dw * adj_cell.dwdphi)
                else:
                    rhr2 = 0.0
                
                if rhr1 * rhr2 > 0:
                    phioosum += 1.0 / (rhr1 + rhr2)
                    phiorsum += adj_cell.rhp1 / (rhr1 + rhr2)
            
            if cell.dwdphi > 0.0:
                wcap = cell.dwdphi * cell.volume
            else:
                wcap = 0.0
            
            denominator = phioosum + vpoosum * cell.vpsat + wcap / s_hbh.deltat
            if denominator != 0.0:
                cell.rhp1 = (phiorsum + vporsum + (wcap * cell.rh) / s_hbh.deltat) / denominator
            else:
                return
            
            if cell.rhp1 > RHMAX:
                cell.rhp1 = RHMAX
        
        sumtp1 = 0.0
        for cid in range(s_hbh.Extcell[sid], s_hbh.Intcell[sid] + 1):
            cell = s_hbh.cells[cid]
            if sumtp1 < abs(cell.tempp2 - cell.tempp1):
                sumtp1 = abs(cell.tempp2 - cell.tempp1)
        
        if sumtp1 < CONVT:
            break
        if itter > ITTERMAX:
            break
        
        for cid in range(s_hbh.firstcell[sid], s_hbh.lastcell[sid] + 1):
            cell = s_hbh.cells[cid]
            cell.tempp2 = cell.tempp1
            cell.rhp2 = cell.rhp1
    
    temp_surf_out_tmp[0] = ext_cell.tempp1
    surf_temp_in_tmp[0] = int_cell.tempp1
    
    surf_temp_in_p = int_cell.rhp1 * psychrometrics_psy_psat_fn_temp(state, int_cell.tempp1)
    
    state.dataMstBal.RhoVaporSurfIn[sid] = surf_temp_in_p / (461.52 * (space_mat + KELVIN))


def update_heat_bal_hamt(state: EnergyPlusDataProtocol, sid: int) -> None:
    """Update HAMT values after convergence"""
    s_hbh = state.dataHeatBalHAMTMgr
    
    matmass = 0.0
    watermass = 0.0
    
    for cid in range(s_hbh.firstcell[sid], s_hbh.lastcell[sid] + 1):
        cell = s_hbh.cells[cid]
        cell.temp = cell.tempp1
        cell.rh = cell.rhp1
        cell.rhp = cell.rh * 100.0
        
        if cell.density > 0.0:
            cell.wreport = cell.water / cell.density
            watermass += cell.water * cell.volume
            matmass += cell.density * cell.volume
    
    s_hbh.watertot[sid] = 0.0
    if matmass > 0:
        s_hbh.watertot[sid] = watermass / matmass
    
    s_hbh.surfrh[sid] = 100.0 * s_hbh.cells[s_hbh.Intcell[sid]].rh
    s_hbh.surfextrh[sid] = 100.0 * s_hbh.cells[s_hbh.Extcell[sid]].rh
    s_hbh.surftemp[sid] = s_hbh.cells[s_hbh.Intcell[sid]].temp
    s_hbh.surfexttemp[sid] = s_hbh.cells[s_hbh.Extcell[sid]].temp
    s_hbh.surfvp[sid] = rh_to_vp(state, s_hbh.cells[s_hbh.Intcell[sid]].rh,
                                 s_hbh.cells[s_hbh.Intcell[sid]].temp)


def interp(ndata: int, xx: List[float], yy: List[float], invalue: float,
           outvalue: list, outgrad: Optional[list] = None) -> None:
    """
    Interpolate to find value by searching array
    
    Args:
        ndata: number of data points
        xx: x values (1-indexed in C++, adjusted here)
        yy: y values (1-indexed in C++, adjusted here)
        invalue: input x value
        outvalue: [output] interpolated y value
        outgrad: [output] gradient (optional)
    """
    mygrad = 0.0
    outvalue[0] = 0.0
    
    if ndata > 1:
        xxlow = xx[0]
        yylow = yy[0]
        
        for step in range(1, ndata):
            xxhigh = xx[step]
            yyhigh = yy[step]
            if invalue <= xxhigh:
                break
            xxlow = xxhigh
            yylow = yyhigh
        
        if xxhigh > xxlow:
            mygrad = (yyhigh - yylow) / (xxhigh - xxlow)
            outvalue[0] = (invalue - xxlow) * mygrad + yylow
        elif abs(xxhigh - xxlow) < 1e-10:
            outvalue[0] = yylow
    
    if outgrad is not None:
        outgrad[0] = mygrad


def rh_to_vp(state: EnergyPlusDataProtocol, rh: float, temperature: float) -> float:
    """Convert RH and temperature to vapor pressure"""
    vpsat = psychrometrics_psy_psat_fn_temp(state, temperature)
    return rh * vpsat


def wvdc(temperature: float, ambp: float) -> float:
    """Calculate water vapor diffusion coefficient"""
    return (2.0e-7 * pow(temperature + KELVIN, 0.81)) / ambp


def find_item_in_list(item: str, list_to_search: list) -> int:
    """Find item in list (1-indexed)"""
    for i, elem in enumerate(list_to_search, 1):
        if str(elem).strip() == item.strip():
            return i
    return 0


def psychrometrics_psy_rh_fn_tdb_rhov(state: EnergyPlusDataProtocol, tdb: float,
                                      rhov: float, context: str) -> float:
    """Psychrometric RH from T and vapor density (stub)"""
    return 0.5


def psychrometrics_psy_psat_fn_temp(state: EnergyPlusDataProtocol, temperature: float) -> float:
    """Saturation vapor pressure (stub)"""
    return 2000.0
