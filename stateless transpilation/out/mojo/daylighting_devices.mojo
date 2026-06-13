from math import cos, sin, sqrt, log, tan, atan, pow
from sys import exit


alias NumOfAngles = 37
alias MaxTZones = 10
alias iHoursInDay = 24


struct Constant:
    alias DegToRad = 3.141592653589793 / 180.0
    alias Pi = 3.141592653589793
    alias PiOvr2 = 3.141592653589793 / 2.0


struct RadType:
    alias VisibleBeam = 1
    alias SolarBeam = 2
    alias SolarAniso = 3
    alias SolarIso = 4


@dataclass
struct TDDPipeStoredData:
    var AspectRatio: Float64
    var Reflectance: Float64
    var TransBeam: InlineArray[Float64, NumOfAngles]

    fn __init__(inout self) -> None:
        self.AspectRatio = 0.0
        self.Reflectance = 0.0
        self.TransBeam = InlineArray[Float64, NumOfAngles](0.0)


@dataclass
struct DaylightingDevicesData:
    var COSAngle: InlineArray[Float64, NumOfAngles]
    var ShelfReported: Bool
    var GetTDDInputErrorsFound: Bool
    var GetShelfInputErrorsFound: Bool
    var MyEnvrnFlag: Bool

    fn __init__(inout self) -> None:
        self.COSAngle = InlineArray[Float64, NumOfAngles](0.0)
        self.ShelfReported = False
        self.GetTDDInputErrorsFound = False
        self.GetShelfInputErrorsFound = False
        self.MyEnvrnFlag = True

    fn init_constant_state(inout self, state: EnergyPlusData) -> None:
        pass

    fn init_state(inout self, state: EnergyPlusData) -> None:
        pass

    fn clear_state(inout self) -> None:
        for i in range(NumOfAngles):
            self.COSAngle[i] = 0.0
        self.ShelfReported = False
        self.GetTDDInputErrorsFound = False
        self.GetShelfInputErrorsFound = False
        self.MyEnvrnFlag = True


struct EnergyPlusData:
    pass


fn init_daylighting_devices(state: EnergyPlusData) -> None:
    """Initialize all daylighting devices: TDD pipes and daylighting shelves."""
    var stored_pipes = DynamicVector[TDDPipeStoredData]()

    get_tdd_input(state)

    # Initialize TDDs
    display_string(state, "Initializing Tubular Daylighting Devices")
    
    state.dataDaylightingDevices.COSAngle[0] = 0.0
    state.dataDaylightingDevices.COSAngle[NumOfAngles - 1] = 1.0

    var dTheta = 90.0 * Constant.DegToRad / (NumOfAngles - 1.0)
    var Theta = 90.0 * Constant.DegToRad
    
    for AngleNum in range(1, NumOfAngles - 1):
        Theta -= dTheta
        state.dataDaylightingDevices.COSAngle[AngleNum] = cos(Theta)

    get_shelf_input(state)

    display_string(state, "Initializing Light Shelf Daylighting Devices")


fn get_tdd_input(state: EnergyPlusData) -> None:
    """Gets the input for TDD pipes and does some error checking."""
    pass


fn get_shelf_input(state: EnergyPlusData) -> None:
    """Gets the input for light shelves and does some error checking."""
    pass


fn calc_pipe_trans_beam(R: Float64, A: Float64, Theta: Float64) -> Float64:
    """Calculates the numerical integral for the transmittance of a reflective cylinder."""
    
    var N = 100000.0
    var xTol = 150.0
    var myLocalTiny = 1e-30

    var CalcPipeTransBeam = 0.0
    var T = 0.0
    var i = 1.0 / N
    var xLimit = (log(N * N * myLocalTiny) / log(R)) / xTol
    var c1 = A * tan(Theta)
    var c2 = 4.0 / Constant.Pi
    var s = i
    
    while s < (1.0 - i):
        var x = c1 / s
        if x < xLimit:
            var dT = c2 * pow(R, Int(x)) * (1.0 - (1.0 - R) * (x - Int(x))) * (s * s) / sqrt(1.0 - s * s)
            T += dT
        s += i

    T /= (N - 1.0)
    CalcPipeTransBeam = T

    return CalcPipeTransBeam


fn calc_tdd_trans_sol_iso(state: EnergyPlusData, PipeNum: Int) -> Float64:
    """Calculates the transmittance of sky isotropic radiation."""
    
    var NPH = 1000
    var FluxInc = 0.0
    var FluxTrans = 0.0
    var dPH = 90.0 * Constant.DegToRad / NPH
    var PH = 0.5 * dPH

    for N in range(1, NPH + 1):
        var COSI = cos(Constant.PiOvr2 - PH)
        var SINI = sin(Constant.PiOvr2 - PH)
        var P = COSI
        var trans = trans_tdd(state, PipeNum, COSI, RadType.SolarBeam)
        FluxInc += P * SINI * dPH
        FluxTrans += trans * P * SINI * dPH
        PH += dPH

    var CalcTDDTransSolIso = 0.0
    if FluxInc != 0:
        CalcTDDTransSolIso = FluxTrans / FluxInc

    return CalcTDDTransSolIso


fn calc_tdd_trans_sol_horizon(state: EnergyPlusData, PipeNum: Int) -> Float64:
    """Calculates the transmittance of sky horizon radiation."""
    
    var NTH = 18
    var FluxInc = 0.0
    var FluxTrans = 0.0
    var CosPhi = cos(Constant.PiOvr2 - 0.0)  # Tilt in radians
    var Theta = 0.0  # Azimuth in radians

    if CosPhi > 0.01:
        var THMIN = Theta - Constant.PiOvr2
        var dTH = 180.0 * Constant.DegToRad / NTH
        var TH = THMIN + 0.5 * dTH

        for N in range(1, NTH + 1):
            var COSI = CosPhi * cos(TH - Theta)
            var trans = trans_tdd(state, PipeNum, COSI, RadType.SolarBeam)
            FluxInc += COSI * dTH
            FluxTrans += trans * COSI * dTH
            TH += dTH

        return FluxTrans / FluxInc if FluxInc != 0 else 0.0
    else:
        return 0.0


fn calc_tdd_trans_sol_aniso(state: EnergyPlusData, PipeNum: Int, COSI: Float64) -> Float64:
    """Calculates the transmittance of the anisotropic sky."""
    return 0.0


fn trans_tdd(state: EnergyPlusData, PipeNum: Int, COSI: Float64, RadiationType: Int) -> Float64:
    """Calculates the total transmittance of the TDD for specified radiation type."""
    var TransTDD = 0.0

    if RadiationType == RadType.VisibleBeam:
        pass
    elif RadiationType == RadType.SolarBeam:
        pass
    elif RadiationType == RadType.SolarAniso:
        TransTDD = calc_tdd_trans_sol_aniso(state, PipeNum, COSI)
    elif RadiationType == RadType.SolarIso:
        pass

    return TransTDD


fn interpolate_pipe_trans_beam(state: EnergyPlusData, COSI: Float64, transBeam: DynamicVector[Float64]) -> Float64:
    """Interpolates the beam transmittance vs. cosine angle table."""
    var InterpolatePipeTransBeam = 0.0
    return InterpolatePipeTransBeam


fn find_tdd_pipe(state: EnergyPlusData, WinNum: Int) -> Int:
    """Given the TDD:DOME or TDD:DIFFUSER object number, returns TDD pipe number."""
    return 0


fn distribute_tdd_absorbed_solar(state: EnergyPlusData) -> None:
    """Sums the absorbed solar gains from TDD pipes that pass through transition zones."""
    pass


fn calc_view_factor_to_shelf(state: EnergyPlusData, ShelfNum: Int) -> None:
    """Attempts to calculate exact analytical view factor from window to outside shelf."""
    pass


fn adjust_view_factors_with_shelf(
    state: EnergyPlusData,
    inout viewFactorToShelf: Float64,
    inout viewFactorToSky: Float64,
    inout viewFactorToGround: Float64,
    WinSurf: Int,
    ShelfNum: Int
) -> None:
    """Adjusts view factors when a shelf is present."""
    pass


fn figure_tdd_zone_gains(state: EnergyPlusData) -> None:
    """Initialize zone gains at begin new environment."""
    pass


fn display_string(state: EnergyPlusData, msg: String) -> None:
    """Display a string message."""
    print(msg)


fn show_severe_error(state: EnergyPlusData, msg: String) -> None:
    """Show a severe error message."""
    print("** Severe **: " + msg)


fn show_warning_error(state: EnergyPlusData, msg: String) -> None:
    """Show a warning error message."""
    print("** Warning **: " + msg)


fn show_continue_error(state: EnergyPlusData, msg: String) -> None:
    """Show a continuation error message."""
    print("   >>>  " + msg)


fn show_fatal_error(state: EnergyPlusData, msg: String) -> None:
    """Show a fatal error message and exit."""
    print("** Fatal **: " + msg)
    exit(1)
