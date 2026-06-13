/* ARD This is a new class for radiative cooling panel model. */
from csp_solver_core import C_csp_solver_core
from csp_solver_util import util
from sam_csp_util import SAM_csp_util
from water_properties import water_TP, water_visc, water_cond, water_state
from HTFProperties import HTFProperties
from file import File
from io import print
from math import abs, tanh, exp, sqrt, pow as math_pow

# Helper to replace numeric_limits<double>::quiet_NaN()
alias DOUBLE_NAN = Float64.NAN

struct C_csp_radiator:

    var mc_coldhtf: water_state
    var mc_air: HTFProperties

    var T_S_measured: Array[Float64, 8760]  # measured sky temperature [K], initially zeros.
    var T_S_localhr: Array[Int, 8760]       # local time in hours for measured sky temp, initially zeros.
    var T_S_time: Array[Float64, 8760]      # time in seconds at end of timestep for measured sky temp, initially zeros.
    /*int T_EG30[1][71] = { -10, -9,-8,-7,-6,-5,-4,-3,-2,-1,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60 };	// Temperatures [C] for EG properties
    double cp_EG30[1][71] = { 3.627,3.63,3.633,3.636,3.64,3.643,3.646,3.649,3.652,3.655,3.658,3.661,3.664,3.667,3.67,3.673,3.676,3.679,3.682,3.685,3.689,3.692,3.695,3.698,3.7,3.703,3.706,3.709,3.712,3.715,3.718,3.721,3.724,3.727,3.73,3.733,3.736,3.739,3.741,3.744,3.747,3.75,3.753,3.756,3.759,3.761,3.764,3.767,3.77,3.773,3.775,3.778,3.781,3.784,3.786,3.789,3.792,3.794,3.797,3.8,3.803,3.805,3.808,3.811,3.813,3.816,3.818,3.821,3.824,3.826,3.829 };		//Specific heat [kJ/kg-K] of ethyene glycol 30% by mass from -10 C to 60 C
    double rho_EG30[1][71] = { 1047,1047,1047,1047,1047,1046,1046,1046,1046,1045,1045,1045,1044,1044,1044,1043,1043,1043,1042,1042,1042,1041,1041,1041,1040,1040,1040,1039,1039,1038,1038,1038,1037,1037,1036,1036,1036,1035,1035,1034,1034,1033,1033,1032,1032,1031,1031,1030,1030,1029,1029,1028,1028,1027,1027,1026,1026,1025,1025,1024,1023,1023,1022,1022,1021,1020,1020,1019,1019,1018,1017 };	//Density [kg/m^3]
    double mu_EG30[1][71] = { 0.006508,0.006228,0.005964,0.005715,0.005478,0.005254,0.005042,0.004841,0.00465,0.004469,0.004298,0.004135,0.00398,0.003832,0.003692,0.003559,0.003433,0.003312,0.003197,0.003087,0.002983,0.002883,0.002788,0.002698,0.002611,0.002529,0.002449,0.002374,0.002302,0.002233,0.002166,0.002103,0.002042,0.001984,0.001929,0.001875,0.001824,0.001775,0.001728,0.001682,0.001639,0.001597,0.001557,0.001518,0.001481,0.001445,0.001411,0.001378,0.001346,0.001315,0.001286,0.001257,0.001229,0.001203,0.001177,0.001153,0.001129,0.001106,0.001083,0.001062,0.001041,0.001021,0.001001,0.0009824,0.0009642,0.0009465,0.0009294,0.0009128,0.0008967,0.0008812,0.000866 };		//Viscosity [kg/m-sec]
    double alpha_EG30[1][71] = { 1.15E-07,1.15E-07,1.15E-07,1.15E-07,1.16E-07,1.16E-07,1.16E-07,1.16E-07,1.16E-07,1.17E-07,1.17E-07,1.17E-07,1.17E-07,1.17E-07,1.17E-07,1.18E-07,1.18E-07,1.18E-07,1.18E-07,1.18E-07,1.19E-07,1.19E-07,1.19E-07,1.19E-07,1.19E-07,1.20E-07,1.20E-07,1.20E-07,1.20E-07,1.20E-07,1.20E-07,1.21E-07,1.21E-07,1.21E-07,1.21E-07,1.21E-07,1.22E-07,1.22E-07,1.22E-07,1.22E-07,1.22E-07,1.23E-07,1.23E-07,1.23E-07,1.23E-07,1.23E-07,1.24E-07,1.24E-07,1.24E-07,1.24E-07,1.24E-07,1.25E-07,1.25E-07,1.25E-07,1.25E-07,1.25E-07,1.26E-07,1.26E-07,1.26E-07,1.26E-07,1.26E-07,1.27E-07,1.27E-07,1.27E-07,1.27E-07,1.27E-07,1.28E-07,1.28E-07,1.28E-07,1.28E-07,1.28E-07 };	//Thermal diffusivity [m^2/sec]
    double k_EG30[1][71] = {0.4362, 0.4371, 0.4381, 0.4391, 0.4401, 0.4411, 0.442, 0.443, 0.444, 0.445, 0.4459, 0.4469, 0.4479, 0.4488, 0.4498, 0.4507, 0.4517, 0.4527, 0.4536, 0.4546, 0.4555, 0.4565, 0.4574, 0.4583, 0.4593, 0.4602, 0.4612, 0.4621, 0.463, 0.464, 0.4649, 0.4658, 0.4668, 0.4677, 0.4686, 0.4695, 0.4704, 0.4713, 0.4723, 0.4732, 0.4741, 0.475, 0.4759, 0.4768, 0.4777, 0.4786, 0.4795, 0.4804, 0.4813, 0.4821, 0.483, 0.4839, 0.4848, 0.4857, 0.4865, 0.4874, 0.4883, 0.4891, 0.49, 0.4909, 0.4917, 0.4926, 0.4934, 0.4943, 0.4951, 0.496, 0.4968, 0.4977, 0.4985, 0.4994, 0.5002}; //Thermal conductivity [W/m-K]
    */
    var T_PG20: StaticArray[68, Int] = StaticArray[68, Int](-7, -6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60)    # Temperatures [C] for PG properties
    var cp_PG20: StaticArray[68, Float64] = StaticArray[68, Float64](3.922,3.924,3.926,3.928,3.93,3.932,3.934,3.936,3.938,3.94,3.942,3.944,3.946,3.948,3.95,3.952,3.954,3.956,3.958,3.96,3.962,3.964,3.966,3.968,3.971,3.973,3.975,3.977,3.979,3.981,3.983,3.985,3.987,3.989,3.991,3.994,3.996,3.998,4,4.002,4.004,4.006,4.008,4.011,4.013,4.015,4.017,4.019,4.021,4.023,4.025,4.028,4.03,4.032,4.034,4.036,4.038,4.04,4.042,4.044,4.047,4.049,4.051,4.053,4.055,4.057,4.059,4.061)        #Specific heat [kJ/kg-K] of propylene glycol 20% by mass from -7 C to 60 C
    var rho_PG20: StaticArray[68, Float64] = StaticArray[68, Float64](1021,1021,1021,1021,1021,1020,1020,1020,1020,1020,1020,1019,1019,1019,1019,1018,1018,1018,1018,1017,1017,1017,1016,1016,1016,1015,1015,1015,1014,1014,1014,1013,1013,1013,1012,1012,1011,1011,1010,1010,1010,1009,1009,1008,1008,1007,1007,1006,1006,1005,1005,1004,1004,1003,1003,1002,1002,1001,1001,1000,999.6,999,998.5,997.9,997.3,996.8,996.2,995.6)    #Density [kg/m^3]
    var mu_PG20: StaticArray[68, Float64] = StaticArray[68, Float64](0.005951,0.005672,0.00541,0.005163,0.004931,0.004712,0.004506,0.004312,0.004129,0.003957,0.003794,0.00364,0.003494,0.003356,0.003226,0.003103,0.002986,0.002875,0.00277,0.00267,0.002575,0.002485,0.002399,0.002318,0.002241,0.002167,0.002097,0.00203,0.001966,0.001906,0.001848,0.001792,0.001739,0.001689,0.001641,0.001594,0.00155,0.001508,0.001467,0.001428,0.001391,0.001355,0.001321,0.001288,0.001257,0.001226,0.001197,0.001169,0.001142,0.001116,0.001091,0.001067,0.001044,0.001022,0.001,0.0009795,0.0009594,0.00094,0.0009213,0.0009032,0.0008857,0.0008688,0.0008524,0.0008365,0.0008211,0.0008062,0.0007918,0.0007778)        #Viscosity [kg/m-sec]
    var alpha_PG20: StaticArray[68, Float64] = StaticArray[68, Float64](1.16E-07,1.16E-07,1.16E-07,1.16E-07,1.17E-07,1.17E-07,1.17E-07,1.17E-07,1.18E-07,1.18E-07,1.18E-07,1.18E-07,1.19E-07,1.19E-07,1.19E-07,1.19E-07,1.19E-07,1.20E-07,1.20E-07,1.20E-07,1.20E-07,1.21E-07,1.21E-07,1.21E-07,1.21E-07,1.22E-07,1.22E-07,1.22E-07,1.22E-07,1.22E-07,1.23E-07,1.23E-07,1.23E-07,1.23E-07,1.24E-07,1.24E-07,1.24E-07,1.24E-07,1.25E-07,1.25E-07,1.25E-07,1.25E-07,1.26E-07,1.26E-07,1.26E-07,1.26E-07,1.26E-07,1.27E-07,1.27E-07,1.27E-07,1.27E-07,1.28E-07,1.28E-07,1.28E-07,1.28E-07,1.29E-07,1.29E-07,1.29E-07,1.29E-07,1.30E-07,1.30E-07,1.30E-07,1.30E-07,1.30E-07,1.31E-07,1.31E-07,1.31E-07,1.31E-07)    #Thermal diffusivity [m^2/sec]
    var k_PG20: StaticArray[68, Float64] = StaticArray[68, Float64](0.4636,0.4646,0.4657,0.4668,0.4679,0.469,0.47,0.4711,0.4722,0.4733,0.4743,0.4754,0.4765,0.4775,0.4786,0.4797,0.4807,0.4818,0.4828,0.4839,0.4849,0.486,0.487,0.4881,0.4891,0.4901,0.4912,0.4922,0.4932,0.4943,0.4953,0.4963,0.4973,0.4984,0.4994,0.5004,0.5014,0.5024,0.5034,0.5044,0.5054,0.5064,0.5074,0.5084,0.5093,0.5103,0.5113,0.5123,0.5132,0.5142,0.5152,0.5161,0.5171,0.518,0.519,0.5199,0.5209,0.5218,0.5228,0.5237,0.5246,0.5255,0.5265,0.5274,0.5283,0.5292,0.5301,0.531) #Thermal conductivity [W/m-K]

    struct S_params:
        var m_field_fl: Int
        var m_field_fl_props: util.matrix_t[Float64]
        var m_dot_panel: Float64     #Total mass flow rate through panel : m_dot[kg / sec]
        var n: Int                   #Number of parallel tubes on a single panel : n
        var W: Float64               #Distance between two parallel tubes : W[m]
        var L: Float64               #Length of tubes : L[m]
        var L_c: Float64             #Characteristic length for forced convection, typically equal to n*W
        var th: Float64              #Thickness of plate : th[m]
        var D: Float64               #Diameter of tube : D[m]
        var k_panel: Float64         #Conductivity of plate : k[W / m - K]
        var epsilon: Float64         #Emissivity of plate top surface : epsilon[-]
        var epsilonb: Float64        #Emissivity of plate bottom surface : epsilonb[-]
        var epsilong: Float64        #Emissivity of ground : epsilong[-]
        var Lsec: Float64            #Length of series - connected sections of panels(if single panel, set equal to L) : Lsec[m]
        var m_night_hrs: Float64     #Number of hours plant will run at summer peak
        var m_power_hrs: Float64     #Number of hours plant operates in one day at summer peak
        var Afield: Float64
        var RM: Float64
        var Asolar_refl: Float64
        var Np: Int                  #Number of radiator panels in parallel
        var epsilon_HX: Float64      #Effectiveness of the heat exchanger between cold storage and radiative field
        var radfield_dp: Float64     #Pressure drop through panel and distribution in radiative field [kPa]

        def __init__(inout self):
            self.n = 0
            self.Np = 0
            self.Afield = 0.0
            self.radfield_dp = 0.0
            self.m_dot_panel = DOUBLE_NAN
            self.W = DOUBLE_NAN
            self.L = DOUBLE_NAN
            self.L_c = DOUBLE_NAN
            self.th = DOUBLE_NAN
            self.D = DOUBLE_NAN
            self.k_panel = DOUBLE_NAN
            self.epsilon = DOUBLE_NAN
            self.epsilonb = DOUBLE_NAN
            self.epsilong = DOUBLE_NAN
            self.Lsec = DOUBLE_NAN
            self.m_night_hrs = DOUBLE_NAN
            self.m_power_hrs = DOUBLE_NAN
            self.RM = DOUBLE_NAN
            self.epsilon_HX = DOUBLE_NAN
            self.Asolar_refl = DOUBLE_NAN

    var ms_params: S_params

    def __init__(inout self):
        # Initialize arrays to zeros (already done by default, but ensure)
        for i in range(8760):
            self.T_S_measured[i] = 0.0
            self.T_S_localhr[i] = 0
            self.T_S_time[i] = 0.0
        # Initialize HTFProperties for air
        self.mc_air = HTFProperties()
        self.mc_air.SetFluid(1)   #initialize class for air
        self.mc_coldhtf = water_state()

    def init(inout self):
        self.mc_air.SetFluid(1)   #initialize class for air
        var ii: Int = 0
        var inputFile = File("C:/Users/adyreson/OneDrive/Documents/PhD/09_System/Desert_Rock_Weather/DesertRock2015_TS_localhr.txt", "r")
        if inputFile.is_open():
            while not inputFile.eof():
                # note that this only works if file is TAB separated and all spaces are deleted after end of file. Otherwise it reads last entry twice.
                var line: String = inputFile.readline()
                if line == "":
                    break
                # Split by whitespace, assume two values per line
                var parts = line.split()
                if len(parts) >= 2:
                    self.T_S_measured[ii] = Float64(parts[0])     # measured sky temp [K]
                    self.T_S_localhr[ii] = Int(parts[1])          # hr
                    self.T_S_time[ii] = Float64((ii + 1) * 3600)  # record the time in seconds at the end of the timestep.
                    ii += 1
        else:
            print("Could not open file")

    def night_cool(inout self, var T_db: Float64, var T_rad_in: Float64, var u: Float64, var T_s: Float64, var m_dot_rad: Float64, var Np: Float64, var m_dot_coldstorage: Float64, inout T_rad_out: Float64, inout W_radpump: Float64):
        var Tp: Float64 = DOUBLE_NAN
        var error_Tp: Float64 = 10.0    # [K]
        var tol: Float64 = 1.0          # [K]
        var Tp_est: Float64 = T_rad_in  # Initial estimate = inlet fluid temp.
        if self.ms_params.m_field_fl == 3:    # If using water directly in radiator field (no HX)
            while error_Tp > tol:              # Iterate on the plate temperature.
                self.analytical_panel_calc(T_db, T_rad_in, Tp_est, u, T_s, m_dot_rad, T_rad_out, Tp, W_radpump)
                error_Tp = abs(Tp_est - Tp)     # Update error
                Tp_est = Tp                     # Update guess value
        else:
            while error_Tp > tol:              # Iterate on the plate temperature.
                self.analytical_panel_calc_HX(T_db, T_rad_in, Tp_est, u, T_s, m_dot_rad, Np, m_dot_coldstorage, T_rad_out, Tp, W_radpump)
                error_Tp = abs(Tp_est - Tp)     # Update error
                Tp_est = Tp                     # Update guess value
    # night cool

    def analytical_panel_calc(inout self, var T_db: Float64, var Tin: Float64, var Tp_est: Float64, var u: Float64, var T_s: Float64, var m_dot: Float64, inout T_rad_out: Float64, inout Tp: Float64, inout W_radpump: Float64):
        /*	% Author: Ana Dyreson University of Wisconsin - Madison
            % Summary : This function determines the outlet temperature of a fluid
            % flowing through a radiative - convective cooling panel given the inlet
            % conditions, ambient weather, and geometry of the cooling panel.
            % This method is described in  Dyreson, A., Klein, S.A., Miller F.,
            % "Modeling Radiative-Convective Panels for Nighttime Passive Cooling Applications",
            % Journal of Solar Energy Engineering, October 2017, Volume 139.
            % This code demonstrates the method using water as the cooling fluid.
            % As described in the article, the calculation in this code can be iterated by updating
            % the estimated plate temperature using the results of the previous
            % calculation to obtain a more accurate solution. (This code does not
            % perform the iterations but can be called iteratively from another script.)
            % GEOMETRY:
            %This implementation assumes roll - bond type geometry or tubes otherwise
            %well connected to plate surface.The back of the plate is not insulated.
            %The method can be adapted for other geometry or other cooling fluids, etc.
            %INPUTS :
            %Inlet temperature of fluid : Tin[K]
            % Estimated temperature of plate(an initial estimate cold be Tin) : Tp_est[K]
            % Total mass flow rate through panel : m_dot[kg / sec]
            % Number of parallel tubes on a single panel : n
            % Distance between two parallel tubes : W[m]
            % Length of tubes : L[m]
            % Characteristic length for forced convection, typically equal to n*W
            %unless wind direction is known to determine flow path : Lc[m]
            % Dry bulb ambient air temperature : Tdb[K]
            % Ground temperature, often assumed equal to air temperature : Tg[K]
            % Wind speed : u[m / s]
            % Effective sky temperature, from measurement or correlations : Ts[K]
            % Thickness of plate : th[m]
            % Diameter of tube : D[m]
            % Conductivity of plate : k[W / m - K]
            % Emissivity of plate top surface : epsilon[-]
            % Emissivity of plate bottom surface : epsilonb[-]
            % Emissivity of ground : epsilong[-]
            % Length of series - connected sections of panels(if single panel, set equal
                %to L) : Lsec[m]
            % SAMPLE CALL in matlab
            %[Tout, Qu, Tp] = rad_cool(319.3, 319.3, 2.25, 50, 0.2, 100, 10, 299.3, 299.3, 3.1, 280.9, .002, .02, 235, .95, .07, .9, 100)
            %function[Tout, Qu, Tp, F, FR, h_w, h_forc_t, h_g, ULad, Fprime, Tad, hfi] = rad_cool(Tin, Tp_est, m_dot, n, W, L, Lc, Tdb, Tg, u, Ts, th, D, k, epsilon, epsilonb, epsilong, Lsec)
            % Function may be called with fewer outputs.*/
        var n: Int = self.ms_params.n
        var W: Float64 = self.ms_params.W
        var L: Float64 = self.ms_params.L
        var Lc: Float64 = self.ms_params.L_c
        var Lsec: Float64 = self.ms_params.Lsec
        var D: Float64 = self.ms_params.D
        var epsilon: Float64 = self.ms_params.epsilon
        var epsilonb: Float64 = self.ms_params.epsilonb
        var epsilong: Float64 = self.ms_params.epsilong
        var k: Float64 = self.ms_params.k_panel
        var th: Float64 = self.ms_params.th
        var c_free: Int
        var c_force: Int
        var L_c_tot: Float64
        var hfi: Float64
        var T_g: Float64 = T_db                                 # assume ground T = air T
        var m_dot_tube: Float64 = m_dot / n                     #Tube mass flow rate
        var A_c: Float64 = n * W * L                            #Area of panel
        var W_plate: Float64 = n * W                            #Plate width
        var h_forc_t: Float64 = 5.73 * (u ** 0.8) * (Lc ** -0.2) #Forced convection coefficient
        var Sigma: Float64 = 5.67e-8                             #Stefan - Boltzmann constant
        var Tf: Float64 = T_db + 0.25 * (Tp_est - T_db)         #Estimate of film temperature
        var mu: Float64 = self.mc_air.visc(300.0)                # [kg / m - sec] Viscosity of air
        var alpha: Float64 = self.mc_air.therm_diff(300.0, 101300.0)  # [m ^ 2 / sec] Thermal diffusivity of air
        var rho: Float64 = self.mc_air.dens(300.0, 101300.0)     # [kg / m ^ 3] Density of air
        var nu: Float64 = self.mc_air.kin_visc(300.0, 101300.0) # [m ^ 2 / sec] Kinematic viscosity
        var Pr: Float64 = self.mc_air.Pr(300.0, 101300.0)       # [-] Prandtl number.
        var k_air: Float64 = self.mc_air.cond(300.0)            # [W / m - K] Conductivity of air, assumed constant.
        var L_c_free: Float64 = (Lsec * W_plate) / (2.0 * Lsec + 2.0 * W_plate)  # [m] Characteristic length for free convection.
        var Ra: Float64 = 9.81 * (1.0 / Tf) * abs(Tp_est - T_db) * (L_c_free ** 3) / (nu * alpha)  # [-] Rayleigh number estimate.
        var Gr: Float64 = Ra / Pr                                # [-] Grashof number
        var Re: Float64 = rho * u * Lc / mu                      # [-] Reynolds number for forced convection based on given characteristic length.
        var GrRe2: Float64 = Gr / ((Re ** 2) + 0.00001)          # Ratio of Grashof to Reynolds ^ 2 indicates importance of free vs.forced convection.
        if GrRe2 <= 0.1:                                         #If < 0.1, free convection ignored.
            c_free = 0
        else:
            c_free = 1                                           #If > 0.1, free convection considered.
        if 100 <= GrRe2:                                         #If > 100, forced convection ignored.
            c_force = 0
        else:
            c_force = 1                                          #If < 100, forced convection considered.
        if 100 <= GrRe2:                                         #Only if > 100, set characteristic length equal to Lc free.
            L_c_tot = L_c_free
        else:
            L_c_tot = Lc                                         #In all other cases, set characteristic length equal to Lc forced.
        var Nusselt_free_t: Float64 = 0.13 * (Ra ** (1.0 / 3.0))  #Correlation for free convection from heated plate.
        var h_free_t: Float64 = Nusselt_free_t * k_air / L_c_free  #Related free convection h.
        var Nusselt_forc_t: Float64 = h_forc_t * Lc / k_air       #Nusselt number related to forced convection correlation h.
        var m_conv: Float64 = 3.5                                 #Constant for combining free & forced convection.
        var Nusselt_tot_t: Float64 = ((c_free * (Nusselt_free_t ** m_conv) + c_force * (Nusselt_forc_t ** m_conv)) ** (1.0 / m_conv))  #Combined free & forced convection.
        var h_w: Float64 = Nusselt_tot_t * k_air / L_c_tot        #Total Nu number.
        var Nusselt_free_b: Float64 = 0.58 * (Ra ** 0.2)          #Correlation for free convection from heated plate(bottom).
        var h_g: Float64 = Nusselt_free_b * k_air / L_c_free      #Related free convection h from bottom.
        water_TP(Tin, 101.3, self.mc_coldhtf)                     #Get water state at inlet temperature of fluid
        var cp: Float64 = self.mc_coldhtf.cp * 1000.0              # [J / kg - K] Specific heat capacity of water
        var rho_water: Float64 = self.mc_coldhtf.dens              # [kg/m^3]
        var mu_water: Float64 = water_visc(rho_water, Tin) * 1e-6  #Function result  is uPa-s, convert to kg/m-s. nu_water * rho_water;
        var nu_water: Float64 = mu_water / rho_water
        var alpha_water: Float64 = 1.478e-7                        # [m^2/s] Assuming constant thermal diffusivity under temperatures 0 to 80 C.
        var Pr_water: Float64 = nu_water / alpha_water
        var Re_tube: Float64 = 4.0 * m_dot_tube / (3.1415 * mu_water * D)  # [-] Reynolds number inside tube
        var k_water: Float64 = water_cond(rho_water, Tin)          # [W / m - K]
        if Re_tube < 2300.0:
            hfi = 3.66 * k_water / D                               # [W / m ^ 2 - K] For laminar flow assuming uniform wall temperature(conservative)
        else:
            hfi = 0.023 * (Re_tube ** 0.8) * (Pr_water ** 0.3) * k_water / D  # [W / m ^ 2 - K] Dittus - Boelter equation for turbulent, internal forced flow.Assumes smooth tubes.
        var T_bar: Float64 = 0.5 * (Tp_est + T_db)                 # An estimate of average of plate and ambient temperatures.
        var Tad: Float64 = T_db - (Sigma * epsilon * (T_db ** 4 - T_s ** 4) + Sigma * (1.0 / (1.0 / epsilonb + 1.0 / epsilong - 1.0)) * (T_db ** 4 - T_g ** 4) + h_g * (T_db - T_g)) / (4.0 * Sigma * (epsilon + 1.0 / (1.0 / epsilonb + 1.0 / epsilong - 1.0)) * (T_bar ** 3) + h_g + h_w)  #Adiab. T
        var ULad: Float64 = 4.0 * Sigma * (epsilon + 1.0 / (1.0 / epsilonb + 1.0 / epsilong - 1.0)) * (T_bar ** 3) + h_g + h_w   #Adiabatic loss coefficient.
        var m_param: Float64 = sqrt(ULad / (k * th))               #Fin parameter
        var F: Float64 = tanh(m_param * (W - D) / 2.0) / (m_param * (W - D) / 2.0)  #Fin efficiency
        var Fprime: Float64 = 1.0 / (W * ULad / (3.1415 * D * hfi) + W / (D + (W - D) * F))  #Collector efficiency based on roll bond type geometry.
        var FR: Float64 = (m_dot * cp) / (A_c * ULad) * (1.0 - exp(-(A_c * ULad * Fprime) / (m_dot * cp)))  #Flow direction collector heat removal factor.
        var Qu: Float64 = FR * A_c * ULad * (Tin - Tad)            #Heat
        T_rad_out = Tin - Qu / (m_dot * cp)                        #Outlet temperature
        Tp = Qu / (ULad * A_c) + Tad                               #Plate temperature
        var Tpa: Float64 = 0.5 * (Tp + T_db)                       #Updated value for average of plate & ambient temperature.
        W_radpump = (self.ms_params.radfield_dp * self.ms_params.m_dot_panel * Float64(self.ms_params.Np)) / (rho_water * 0.75 * 0.85) / 1000.0  #MWe pumping power when radiator field is operating. Isentropic eff = 0.75 and Mechanical pump eff = 0.85.
    # adiabatic calc

    def analytical_panel_calc_HX(inout self, var T_db: Float64, var Tin: Float64, var Tp_est: Float64, var u: Float64, var T_s: Float64, var m_dot: Float64, var Np: Float64, var m_dot_water: Float64, inout T_rad_out: Float64, inout Tp: Float64, inout W_radpump: Float64):
        /*	% Author: Ana Dyreson University of Wisconsin - Madison
        % Summary : This function determines the outlet temperature of a fluid
        % flowing through a radiative - convective cooling panel given the inlet
        % conditions, ambient weather, and geometry of the cooling panel.
        % This method is described in  Dyreson, A., Klein, S.A., Miller F.,
        % "Modeling Radiative-Convective Panels for Nighttime Passive Cooling Applications",
        % Journal of Solar Energy Engineering, October 2017, Volume 139.
        % This code demonstrates the method using water as the cooling fluid.
        % As described in the article, the calculation in this code can be iterated by updating
        % the estimated plate temperature using the results of the previous
        % calculation to obtain a more accurate solution. (This code does not
        % perform the iterations but can be called iteratively from another script.)
        % GEOMETRY:
        %This implementation assumes roll - bond type geometry or tubes otherwise
        %well connected to plate surface.The back of the plate is not insulated.
        %The method can be adapted for other geometry or other cooling fluids, etc.
        %INPUTS :
        %Inlet temperature of fluid : Tin[K]
        % Estimated temperature of plate(an initial estimate cold be Tin) : Tp_est[K]
        % Total mass flow rate through panel : m_dot[kg / sec]
        % Number of parallel tubes on a single panel : n
        % Distance between two parallel tubes : W[m]
        % Length of tubes : L[m]
        % Characteristic length for forced convection, typically equal to n*W
        %unless wind direction is known to determine flow path : Lc[m]
        % Dry bulb ambient air temperature : Tdb[K]
        % Ground temperature, often assumed equal to air temperature : Tg[K]
        % Wind speed : u[m / s]
        % Effective sky temperature, from measurement or correlations : Ts[K]
        % Thickness of plate : th[m]
        % Diameter of tube : D[m]
        % Conductivity of plate : k[W / m - K]
        % Emissivity of plate top surface : epsilon[-]
        % Emissivity of plate bottom surface : epsilonb[-]
        % Emissivity of ground : epsilong[-]
        % Length of series - connected sections of panels(if single panel, set equal
        %to L) : Lsec[m]
        % SAMPLE CALL in matlab
        %[Tout, Qu, Tp] = rad_cool(319.3, 319.3, 2.25, 50, 0.2, 100, 10, 299.3, 299.3, 3.1, 280.9, .002, .02, 235, .95, .07, .9, 100)
        %function[Tout, Qu, Tp, F, FR, h_w, h_forc_t, h_g, ULad, Fprime, Tad, hfi] = rad_cool(Tin, Tp_est, m_dot, n, W, L, Lc, Tdb, Tg, u, Ts, th, D, k, epsilon, epsilonb, epsilong, Lsec)
        % Function may be called with fewer outputs.*/
        var n: Int = self.ms_params.n
        var W: Float64 = self.ms_params.W
        var L: Float64 = self.ms_params.L
        var Lc: Float64 = self.ms_params.L_c
        var Lsec: Float64 = self.ms_params.Lsec
        var D: Float64 = self.ms_params.D
        var epsilon: Float64 = self.ms_params.epsilon
        var epsilonb: Float64 = self.ms_params.epsilonb
        var epsilong: Float64 = self.ms_params.epsilong
        var k: Float64 = self.ms_params.k_panel
        var th: Float64 = self.ms_params.th
        var epsilon_HX: Float64 = self.ms_params.epsilon_HX          #Enter constant value HX effectiveness
        var c_free: Int
        var c_force: Int
        var L_c_tot: Float64
        var hfi: Float64
        var T_g: Float64 = T_db                                 # assume ground T = air T
        var m_dot_tube: Float64 = m_dot / n                     #Tube mass flow rate
        var A_c: Float64 = n * W * L                            #Area of panel
        var W_plate: Float64 = n * W                            #Plate width
        var h_forc_t: Float64 = 5.73 * (u ** 0.8) * (Lc ** -0.2) #Forced convection coefficient
        var Sigma: Float64 = 5.67e-8                             #Stefan - Boltzmann constant
        var Tf: Float64 = T_db + 0.25 * (Tp_est - T_db)         #Estimate of film temperature
        var mu: Float64 = self.mc_air.visc(300.0)                # [kg / m - sec] Viscosity of air
        var alpha: Float64 = self.mc_air.therm_diff(300.0, 101300.0)  # [m ^ 2 / sec] Thermal diffusivity of air
        var rho: Float64 = self.mc_air.dens(300.0, 101300.0)     # [kg / m ^ 3] Density of air
        var nu: Float64 = self.mc_air.kin_visc(300.0, 101300.0) # [m ^ 2 / sec] Kinematic viscosity
        var Pr: Float64 = self.mc_air.Pr(300.0, 101300.0)       # [-] Prandtl number.
        var k_air: Float64 = self.mc_air.cond(300.0)            # [W / m - K] Conductivity of air, assumed constant.
        var L_c_free: Float64 = (Lsec * W_plate) / (2.0 * Lsec + 2.0 * W_plate)  # [m] Characteristic length for free convection.
        var Ra: Float64 = 9.81 * (1.0 / Tf) * abs(Tp_est - T_db) * (L_c_free ** 3) / (nu * alpha)  # [-] Rayleigh number estimate.
        var Gr: Float64 = Ra / Pr                                # [-] Grashof number
        var Re: Float64 = rho * u * Lc / mu                      # [-] Reynolds number for forced convection based on given characteristic length.
        var GrRe2: Float64 = Gr / ((Re ** 2) + 0.00001)          #Ratio of Grashof to Reynolds ^ 2 indicates importance of free vs.forced convection.
        if GrRe2 <= 0.1:                                         #If < 0.1, free convection ignored.
            c_free = 0
        else:
            c_free = 1                                           #If > 0.1, free convection considered.
        if 100 <= GrRe2:                                         #If > 100, forced convection ignored.
            c_force = 0
        else:
            c_force = 1                                          #If < 100, forced convection considered.
        if 100 <= GrRe2:                                         #Only if > 100, set characteristic length equal to Lc free.
            L_c_tot = L_c_free
        else:
            L_c_tot = Lc                                         #In all other cases, set characteristic length equal to Lc forced.
        var Nusselt_free_t: Float64 = 0.13 * (Ra ** (1.0 / 3.0))  #Correlation for free convection from heated plate.
        var h_free_t: Float64 = Nusselt_free_t * k_air / L_c_free  #Related free convection h.
        var Nusselt_forc_t: Float64 = h_forc_t * Lc / k_air       #Nusselt number related to forced convection correlation h.
        var m_conv: Float64 = 3.5                                 #Constant for combining free & forced convection.
        var Nusselt_tot_t: Float64 = ((c_free * (Nusselt_free_t ** m_conv) + c_force * (Nusselt_forc_t ** m_conv)) ** (1.0 / m_conv))  #Combined free & forced convection.
        var h_w: Float64 = Nusselt_tot_t * k_air / L_c_tot        #Total Nu number.
        var Nusselt_free_b: Float64 = 0.58 * (Ra ** 0.2)          #Correlation for free convection from heated plate(bottom).
        var h_g: Float64 = Nusselt_free_b * k_air / L_c_free      #Related free convection h from bottom.
        var cp_water: Float64 = 0.0
        if Tin <= 274.0:
            cp_water = 4183.0                                     # [J/kg-K] hardcode in case glycol loop is less than freezing point of water
        else:
            water_TP(Tin, 101.3, self.mc_coldhtf)                 #Get water state at inlet temperature of fluid - this only approximates water temp
            cp_water = self.mc_coldhtf.cp * 1000.0                # [J / kg - K] Specific heat capacity of water
        var idx_props: Int = Int(Tin - 273.15) - self.T_PG20[0] + 1  #Truncate temperature to degree [C] and get index in EG property data as provided based on starting point of that property data.
        var idx_props_check: Int = 0  # In case temperature is at an extreme end, use next closest value.
        if idx_props > 67:
            idx_props_check = 67
        elif idx_props < 0:
            idx_props_check = 0
        else:
            idx_props_check = idx_props
        var cp: Float64 = self.cp_PG20[idx_props_check] * 1000.0   #Get property data based on temperature. Convert to J/kg-K
        var rho_fluid: Float64 = self.rho_PG20[idx_props_check]
        var mu_fluid: Float64 = self.mu_PG20[idx_props_check]
        var nu_fluid: Float64 = mu_fluid / rho_fluid
        var alpha_fluid: Float64 = self.alpha_PG20[idx_props_check]
        var k_fluid: Float64 = self.k_PG20[idx_props_check]
        var Pr_fluid: Float64 = nu_fluid / alpha_fluid             # [-] Prandtl number of water
        var Re_tube: Float64 = 4.0 * m_dot_tube / (3.1415 * mu_fluid * D)  # [-] Reynolds number inside tube
        if Re_tube < 2300.0:
            hfi = 3.66 * k_fluid / D                               # [W / m ^ 2 - K] For laminar flow assuming uniform wall temperature(conservative)
        else:
            hfi = 0.023 * (Re_tube ** 0.8) * (Pr_fluid ** 0.3) * k_fluid / D  # [W / m ^ 2 - K] Dittus - Boelter equation for turbulent, internal forced flow.Assumes smooth tubes.
        var T_bar: Float64 = 0.5 * (Tp_est + T_db)                 # An estimate of average of plate and ambient temperatures.
        var Tad: Float64 = T_db - (Sigma * epsilon * (T_db ** 4 - T_s ** 4) + Sigma * (1.0 / (1.0 / epsilonb + 1.0 / epsilong - 1.0)) * (T_db ** 4 - T_g ** 4) + h_g * (T_db - T_g)) / (4.0 * Sigma * (epsilon + 1.0 / (1.0 / epsilonb + 1.0 / epsilong - 1.0)) * (T_bar ** 3) + h_g + h_w)  #Adiab. T
        var ULad: Float64 = 4.0 * Sigma * (epsilon + 1.0 / (1.0 / epsilonb + 1.0 / epsilong - 1.0)) * (T_bar ** 3) + h_g + h_w   #Adiabatic loss coefficient.
        var m_param: Float64 = sqrt(ULad / (k * th))               #Fin parameter
        var F: Float64 = tanh(m_param * (W - D) / 2.0) / (m_param * (W - D) / 2.0)  #Fin efficiency
        var Fprime: Float64 = 1.0 / (W * ULad / (3.1415 * D * hfi) + W / (D + (W - D) * F))  #Collector efficiency based on roll bond type geometry.
        var FR: Float64 = (m_dot * cp) / (A_c * ULad) * (1.0 - exp(-(A_c * ULad * Fprime) / (m_dot * cp)))  #Flow direction collector heat removal factor.
        var CMIN: Float64 = DOUBLE_NAN
        if (Float64(self.ms_params.Np) * m_dot * cp) < (m_dot_water * cp_water):      #Use the full flow rates at HX to compare
            CMIN = Float64(self.ms_params.Np) * m_dot * cp
        else:
            CMIN = m_dot_water * cp_water
        var FRprime: Float64 = FR / (1.0 + (A_c * FR * ULad) / (m_dot * cp) * ((Float64(self.ms_params.Np) * m_dot * cp) / (epsilon_HX * CMIN) - 1.0))
        var Qu: Float64 = FRprime * A_c * ULad * (Tin - Tad)       #Heat
        T_rad_out = Tin - Qu * Float64(self.ms_params.Np) / (m_dot_water * cp_water)  #Outlet temperature of water side of HX. Because this flow rate is full for all panels through HX, need to multiply Qu by Np.
        Tp = Qu / (ULad * A_c) + Tad                               #Plate temperature
        var Tpa: Float64 = 0.5 * (Tp + T_db)                       #Updated value for average of plate & ambient temperature.
        W_radpump = (self.ms_params.radfield_dp * self.ms_params.m_dot_panel * Float64(self.ms_params.Np)) / (rho_fluid * 0.75 * 0.85) / 1000.0  #MWe pumping power when radiator field is operating. Isentropic eff = 0.75 and Mechanical pump eff = 0.85.
    # adiabatic calc using a separate fluid in radiator loop