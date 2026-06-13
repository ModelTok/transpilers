# EnergyPlus, Copyright (c) 1996-present, The Board of Trustees of the University of Illinois,
# The Regents of the University of California, through Lawrence Berkeley National Laboratory
# (subject to receipt of any required approvals from the U.S. Dept. of Energy), Oak Ridge
# National Laboratory, managed by UT-Battelle, Alliance for Energy Innovation, LLC, and other
# contributors. All rights reserved.

from math import sqrt, log10, log, sin, cos, erfc, tanh, pow, ceil, pi
from memory import UnsafePointer
from collections.abc import KeyElement

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object with dataGlobal, dataPlnt, dataLoopNodes, dataHVACGlobal, dataGroundHeatExchanger
# - GLHEBase: base struct with inherited members (name, inletNodeNum, outletNodeNum, soil, pipe, etc.)
# - GLHEResponseFactors: response factor storage struct
# - GroundTemp: module with ModelType enum and GetGroundTempModelAndInit function
# - Constant: module with Pi, rHoursInDay, rSecsInHour values
# - Node, PlantUtilities, BranchNodeConnections: utility modules
# - GroundTempModel: temperature model with getGroundTempAtTimeInSeconds method
# - ShowFatalError, ShowSevereError, ShowContinueError, DisplayString: error/logging functions
# - maxTSinHr: constant for max time steps in hour
# - Util: utility module with makeUPPER, SameString functions

fn pow_2(x: Float64) -> Float64:
    return x * x

fn is_even(n: Int32) -> Bool:
    return (n % 2) == 0

struct SoilProperties:
    var k: Float64
    var rho: Float64
    var cp: Float64
    var rhoCp: Float64
    var diffusivity: Float64
    
    fn __init__(inout self):
        self.k = 0.0
        self.rho = 0.0
        self.cp = 0.0
        self.rhoCp = 0.0
        self.diffusivity = 0.0

struct PipeProperties:
    var k: Float64
    var rho: Float64
    var cp: Float64
    var outDia: Float64
    var outRadius: Float64
    var thickness: Float64
    
    fn __init__(inout self):
        self.k = 0.0
        self.rho = 0.0
        self.cp = 0.0
        self.outDia = 0.0
        self.outRadius = 0.0
        self.thickness = 0.0

struct GLHEResponseFactors:
    var name: String
    var GFNC: DynamicVector[Float64]
    var LNTTS: DynamicVector[Float64]
    
    fn __init__(inout self):
        self.name = ""
        self.GFNC = DynamicVector[Float64]()
        self.LNTTS = DynamicVector[Float64]()

struct GLHESlinky:
    var MODULE_NAME: StringLiteral
    
    var name: String
    var moduleName: String
    var verticalConfig: Bool
    var coilDiameter: Float64
    var coilPitch: Float64
    var coilDepth: Float64
    var trenchDepth: Float64
    var trenchLength: Float64
    var numTrenches: Int32
    var trenchSpacing: Float64
    var numCoils: Int32
    var monthOfMinSurfTemp: Int32
    var maxSimYears: Float64
    var minSurfTemp: Float64
    var X0: DynamicVector[Float64]
    var Y0: DynamicVector[Float64]
    var Z0: Float64
    
    # Inherited from GLHEBase (stub)
    var inletNodeNum: Int32
    var outletNodeNum: Int32
    var available: Bool
    var on: Bool
    var designFlow: Float64
    var inletTemp: Float64
    var plantLoc: UnsafePointer[UInt8]
    var massFlowRate: Float64
    var soil: SoilProperties
    var pipe: PipeProperties
    var myRespFactors: UnsafePointer[GLHEResponseFactors]
    var timeSSFactor: Float64
    var tempGround: Float64
    var designMassFlow: Float64
    var myEnvrnFlag: Bool
    var groundTempModel: UnsafePointer[UInt8]
    var QnMonthlyAgg: DynamicVector[Float64]
    var QnHr: DynamicVector[Float64]
    var QnSubHr: DynamicVector[Float64]
    var LastHourN: DynamicVector[Int32]
    var prevTimeSteps: DynamicVector[Float64]
    var AGG: Int32
    var SubAGG: Int32
    var totalTubeLength: Float64
    var QGLHE: Float64
    var prevHour: Int32
    var currentSimTime: Float64
    var lastQnSubHr: Float64
    
    fn __init__(inout self):
        self.MODULE_NAME = "GroundHeatExchanger:Slinky"
        self.name = ""
        self.moduleName = "GroundHeatExchanger:Slinky"
        self.verticalConfig = False
        self.coilDiameter = 0.0
        self.coilPitch = 0.0
        self.coilDepth = 0.0
        self.trenchDepth = 0.0
        self.trenchLength = 0.0
        self.numTrenches = 0
        self.trenchSpacing = 0.0
        self.numCoils = 0
        self.monthOfMinSurfTemp = 0
        self.maxSimYears = 0.0
        self.minSurfTemp = 0.0
        self.X0 = DynamicVector[Float64]()
        self.Y0 = DynamicVector[Float64]()
        self.Z0 = 0.0
        
        self.inletNodeNum = 0
        self.outletNodeNum = 0
        self.available = True
        self.on = True
        self.designFlow = 0.0
        self.inletTemp = 0.0
        self.plantLoc = UnsafePointer[UInt8]()
        self.massFlowRate = 0.0
        self.soil = SoilProperties()
        self.pipe = PipeProperties()
        self.myRespFactors = UnsafePointer[GLHEResponseFactors]()
        self.timeSSFactor = 1.0
        self.tempGround = 0.0
        self.designMassFlow = 0.0
        self.myEnvrnFlag = True
        self.groundTempModel = UnsafePointer[UInt8]()
        self.QnMonthlyAgg = DynamicVector[Float64]()
        self.QnHr = DynamicVector[Float64]()
        self.QnSubHr = DynamicVector[Float64]()
        self.LastHourN = DynamicVector[Int32]()
        self.prevTimeSteps = DynamicVector[Float64]()
        self.AGG = 0
        self.SubAGG = 0
        self.totalTubeLength = 0.0
        self.QGLHE = 0.0
        self.prevHour = 1
        self.currentSimTime = 0.0
        self.lastQnSubHr = 0.0
    
    fn calc_hx_resistance(inout self, state: UnsafePointer[UInt8]) -> Float64:
        let routine_name = "CalcSlinkyGroundHeatExchanger"
        
        # Placeholder for accessing state - actual implementation would need proper state object
        # cp_fluid = state.dataPlnt.PlantLoop[self.plantLoc.loopNum].glycol.getSpecificHeat(state, self.inletTemp, routine_name)
        # k_fluid = state.dataPlnt.PlantLoop[self.plantLoc.loopNum].glycol.getConductivity(state, self.inletTemp, routine_name)
        # fluid_density = state.dataPlnt.PlantLoop[self.plantLoc.loopNum].glycol.getDensity(state, self.inletTemp, routine_name)
        # fluid_viscosity = state.dataPlnt.PlantLoop[self.plantLoc.loopNum].glycol.getViscosity(state, self.inletTemp, routine_name)
        
        var cp_fluid: Float64 = 0.0
        var k_fluid: Float64 = 0.0
        var fluid_density: Float64 = 0.0
        var fluid_viscosity: Float64 = 0.0
        
        # calculate mass flow rate
        let single_slinky_mass_flow_rate = self.massFlowRate / Float64(self.numTrenches)
        
        let pipe_inner_rad = self.pipe.outRadius - self.pipe.thickness
        let pipe_inner_dia = 2.0 * pipe_inner_rad
        
        var rconv: Float64
        if single_slinky_mass_flow_rate == 0.0:
            rconv = 0.0
        else:
            let reynolds_num = (fluid_density * pipe_inner_dia * 
                              (single_slinky_mass_flow_rate / fluid_density / (pi * pow_2(pipe_inner_rad))) / 
                              fluid_viscosity)
            let prandtl_num = (cp_fluid * fluid_viscosity) / k_fluid
            
            let laminar_nusselt_no: Float64 = 4.364
            var nusselt_num: Float64
            if reynolds_num <= 2300:
                nusselt_num = laminar_nusselt_no
            elif reynolds_num > 2300 and reynolds_num <= 4000:
                let A: Float64 = 3150
                let B: Float64 = 350
                let sf = 0.5 + 0.5 * tanh((reynolds_num - A) / B)
                let turbulent_nusselt_no = 0.023 * pow(reynolds_num, 0.8) * pow(prandtl_num, 0.35)
                nusselt_num = laminar_nusselt_no * (1 - sf) + turbulent_nusselt_no * sf
            else:
                nusselt_num = 0.023 * pow(reynolds_num, 0.8) * pow(prandtl_num, 0.35)
            
            let hci = nusselt_num * k_fluid / pipe_inner_dia
            rconv = 1.0 / (2.0 * pi * pipe_inner_dia * hci)
        
        # Conduction Resistance
        let rcond = log(self.pipe.outRadius / pipe_inner_rad) / (2.0 * pi * self.pipe.k) / 2.0
        
        return rcond + rconv
    
    fn calc_g_functions(inout self, state: UnsafePointer[UInt8]) -> None:
        let t_lg_min: Float64 = -2.0
        let t_lg_grid: Float64 = 0.25
        let ts: Float64 = 3600.0
        let convert_years_to_seconds: Float64 = 356.0 * 24.0 * 60.0 * 60.0
        
        var val_stored = DynamicVector[Float64]()
        
        # DisplayString(state, f"Initializing GroundHeatExchanger:Slinky: {self.name}")
        
        self.X0 = DynamicVector[Float64](capacity=self.numCoils)
        self.Y0 = DynamicVector[Float64](capacity=self.numTrenches)
        for _ in range(self.numCoils):
            self.X0.push_back(0.0)
        for _ in range(self.numTrenches):
            self.Y0.push_back(0.0)
        
        # Calculate the number of g-functions required
        let t_lg_max = log10(self.maxSimYears * convert_years_to_seconds / ts)
        let n_pairs = Int32(Int32(t_lg_max - t_lg_min) / Int32(t_lg_grid) + 1)
        
        # Allocate and setup g-function arrays
        self.myRespFactors[].GFNC = DynamicVector[Float64](capacity=Int(n_pairs))
        self.myRespFactors[].LNTTS = DynamicVector[Float64](capacity=Int(n_pairs))
        for _ in range(Int(n_pairs)):
            self.myRespFactors[].GFNC.push_back(0.0)
            self.myRespFactors[].LNTTS.push_back(0.0)
        
        self.QnMonthlyAgg = DynamicVector[Float64](capacity=Int(self.maxSimYears * 12))
        self.QnHr = DynamicVector[Float64](capacity=730 + Int(self.AGG) + Int(self.SubAGG))
        self.QnSubHr = DynamicVector[Float64](capacity=Int((self.SubAGG + 1) * 4 + 1))  # assuming maxTSinHr = 4
        self.LastHourN = DynamicVector[Int32](capacity=Int(self.SubAGG + 1))
        
        for _ in range(Int(self.maxSimYears * 12)):
            self.QnMonthlyAgg.push_back(0.0)
        for _ in range(730 + Int(self.AGG) + Int(self.SubAGG)):
            self.QnHr.push_back(0.0)
        for _ in range(Int((self.SubAGG + 1) * 4 + 1)):
            self.QnSubHr.push_back(0.0)
        for _ in range(Int(self.SubAGG + 1)):
            self.LastHourN.push_back(0)
        
        # Calculate the number of loops (per trench) and number of trenches to be involved
        let num_lc = Int32(ceil(Float64(self.numCoils) / 2.0))
        let num_rc = Int32(ceil(Float64(self.numTrenches) / 2.0))
        
        # Calculate coordinates (X0, Y0, Z0) of a ring's center
        for coil in range(self.numCoils):
            self.X0[Int(coil)] = self.coilPitch * Float64(coil)
        
        for trench in range(self.numTrenches):
            self.Y0[Int(trench)] = Float64(trench) * self.trenchSpacing
        
        self.Z0 = self.coilDepth
        
        # If number of trenches is greater than 1, one quarter of the rings are involved.
        # If number of trenches is 1, one half of the rings are involved.
        var fraction: Float64
        if self.numTrenches > 1:
            fraction = 0.25
        else:
            fraction = 0.5
        
        # Calculate the corresponding time of each temperature response factor
        for nt in range(Int(n_pairs)):
            let t_lg = t_lg_min + t_lg_grid * Float64(nt)
            let t = pow(10.0, t_lg) * ts
            
            # Set the average temperature response of the whole field to zero
            var g_func: Float64 = 0.0
            
            for m1 in range(1, Int(num_rc) + 1):
                for n1 in range(1, Int(num_lc) + 1):
                    for m in range(1, Int(self.numTrenches) + 1):
                        for n in range(1, Int(self.numCoils) + 1):
                            # Zero out val after each iteration
                            var double_integral_val: Float64 = 0.0
                            var mid_field_val: Float64 = 0.0
                            
                            # Calculate the distance between ring centers
                            let dis_ring = self.dist_to_center(Int32(m), Int32(n), Int32(m1), Int32(n1))
                            
                            # Save mm1 and nn1
                            let mm1 = Int32(abs(m - m1))
                            let nn1 = Int32(abs(n - n1))
                            
                            # If we're calculating a ring's temperature response to itself as a ring source,
                            # then we need some extra effort in calculating the double integral
                            var i0: Int32
                            var j0: Int32
                            if Int32(m1) == Int32(m) and Int32(n1) == Int32(n):
                                i0 = 33
                                j0 = 1089
                            else:
                                i0 = 33
                                j0 = 561
                            
                            var g_funcin: Float64
                            
                            # if the ring(n1, m1) is the near-field ring of the ring(n,m)
                            if dis_ring <= 2.5 + self.coilDiameter:
                                double_integral_val = self.double_integral(Int32(m), Int32(n), Int32(m1), Int32(n1), t, i0, j0)
                                
                                # due to symmetry, the temperature response of ring(n1, m1) should be 0.25, 0.5, or 1 times its calculated value
                                if (not is_even(self.numTrenches) and not is_even(self.numCoils) and 
                                    Int32(m1) == num_rc and Int32(n1) == num_lc and self.numTrenches > Int32(1)):
                                    g_funcin = 0.25 * double_integral_val
                                elif (not is_even(self.numTrenches) and Int32(m1) == num_rc and self.numTrenches > Int32(1)):
                                    g_funcin = 0.5 * double_integral_val
                                elif not is_even(self.numCoils) and Int32(n1) == num_lc:
                                    g_funcin = 0.5 * double_integral_val
                                else:
                                    g_funcin = double_integral_val
                            
                            # if the ring(n1, m1) is in the far-field or the ring(n,m)
                            elif dis_ring > (10 + self.coilDiameter):
                                g_funcin = 0.0
                            
                            # else the ring(n1, m1) is in the middle-field of the ring(n,m)
                            else:
                                mid_field_val = self.mid_field_response_function(Int32(m), Int32(n), Int32(m1), Int32(n1), t)
                                
                                # due to symmetry, the temperature response of ring(n1, m1) should be 0.25, 0.5, or 1 times its calculated value
                                if (not is_even(self.numTrenches) and not is_even(self.numCoils) and 
                                    Int32(m1) == num_rc and Int32(n1) == num_lc and self.numTrenches > Int32(1)):
                                    g_funcin = 0.25 * mid_field_val
                                elif (not is_even(self.numTrenches) and Int32(m1) == num_rc and self.numTrenches > Int32(1)):
                                    g_funcin = 0.5 * mid_field_val
                                elif not is_even(self.numCoils) and Int32(n1) == num_lc:
                                    g_funcin = 0.5 * mid_field_val
                                else:
                                    g_funcin = mid_field_val
                            
                            g_func += g_funcin
            
            let gfnc_val = (g_func * (self.coilDiameter / 2.0)) / (4 * pi * fraction * Float64(self.numTrenches) * Float64(self.numCoils))
            self.myRespFactors[].GFNC[nt] = gfnc_val
            self.myRespFactors[].LNTTS[nt] = t_lg
    
    fn near_field_response_function(self, m: Int32, n: Int32, m1: Int32, n1: Int32, eta: Float64, theta: Float64, t: Float64) -> Float64:
        let distance1 = self.distance(m, n, m1, n1, eta, theta)
        let sqrt_alpha_t = sqrt(self.soil.diffusivity * t)
        
        if not self.verticalConfig:
            let sqrt_dist_depth = sqrt(pow_2(distance1) + 4 * pow_2(self.coilDepth))
            let err_func1 = erfc(0.5 * distance1 / sqrt_alpha_t)
            let err_func2 = erfc(0.5 * sqrt_dist_depth / sqrt_alpha_t)
            
            return err_func1 / distance1 - err_func2 / sqrt_dist_depth
        
        let distance2 = self.distance_to_fict_ring(m, n, m1, n1, eta, theta)
        let err_func1 = erfc(0.5 * distance1 / sqrt_alpha_t)
        let err_func2 = erfc(0.5 * distance2 / sqrt_alpha_t)
        
        return err_func1 / distance1 - err_func2 / distance2
    
    fn mid_field_response_function(self, m: Int32, n: Int32, m1: Int32, n1: Int32, t: Float64) -> Float64:
        let sqrt_alpha_t = sqrt(self.soil.diffusivity * t)
        
        let distance = self.dist_to_center(m, n, m1, n1)
        let sqrt_dist_depth = sqrt(pow_2(distance) + 4 * pow_2(self.coilDepth))
        
        let err_func1 = erfc(0.5 * distance / sqrt_alpha_t)
        let err_func2 = erfc(0.5 * sqrt_dist_depth / sqrt_alpha_t)
        
        return 4 * pow_2(pi) * (err_func1 / distance - err_func2 / sqrt_dist_depth)
    
    fn distance(self, m: Int32, n: Int32, m1: Int32, n1: Int32, eta: Float64, theta: Float64) -> Float64:
        let cos_theta = cos(theta)
        let sin_theta = sin(theta)
        let cos_eta = cos(eta)
        let sin_eta = sin(eta)
        
        let x = self.X0[Int(n - 1)] + cos_theta * (self.coilDiameter / 2.0)
        let y = self.Y0[Int(m - 1)] + sin_theta * (self.coilDiameter / 2.0)
        
        let x_in = self.X0[Int(n1 - 1)] + cos_eta * (self.coilDiameter / 2.0 - self.pipe.outRadius)
        let y_in = self.Y0[Int(m1 - 1)] + sin_eta * (self.coilDiameter / 2.0 - self.pipe.outRadius)
        
        let x_out = self.X0[Int(n1 - 1)] + cos_eta * (self.coilDiameter / 2.0 + self.pipe.outRadius)
        let y_out = self.Y0[Int(m1 - 1)] + sin_eta * (self.coilDiameter / 2.0 + self.pipe.outRadius)
        
        if not self.verticalConfig:
            return 0.5 * sqrt(pow_2(x - x_in) + pow_2(y - y_in)) + 0.5 * sqrt(pow_2(x - x_out) + pow_2(y - y_out))
        
        let z = self.Z0 + sin_theta * (self.coilDiameter / 2.0)
        let z_in = self.Z0 + sin_eta * (self.coilDiameter / 2.0 - self.pipe.outRadius)
        let z_out = self.Z0 + sin_eta * (self.coilDiameter / 2.0 + self.pipe.outRadius)
        
        return (0.5 * sqrt(pow_2(x - x_in) + pow_2(self.Y0[Int(m1 - 1)] - self.Y0[Int(m - 1)]) + pow_2(z - z_in)) +
                0.5 * sqrt(pow_2(x - x_out) + pow_2(self.Y0[Int(m1 - 1)] - self.Y0[Int(m - 1)]) + pow_2(z - z_out)))
    
    fn distance_to_fict_ring(self, m: Int32, n: Int32, m1: Int32, n1: Int32, eta: Float64, theta: Float64) -> Float64:
        let sin_theta = sin(theta)
        let cos_theta = cos(theta)
        let sin_eta = sin(eta)
        let cos_eta = cos(eta)
        
        let x = self.X0[Int(n - 1)] + cos_theta * (self.coilDiameter / 2.0)
        let z = self.Z0 + sin_theta * (self.coilDiameter / 2.0) + 2 * self.coilDepth
        
        let x_in = self.X0[Int(n1 - 1)] + cos_eta * (self.coilDiameter / 2.0 - self.pipe.outRadius)
        let z_in = self.Z0 + sin_eta * (self.coilDiameter / 2.0 - self.pipe.outRadius)
        
        let x_out = self.X0[Int(n1 - 1)] + cos_eta * (self.coilDiameter / 2.0 + self.pipe.outRadius)
        let z_out = self.Z0 + sin_eta * (self.coilDiameter / 2.0 + self.pipe.outRadius)
        
        return (0.5 * sqrt(pow_2(x - x_in) + pow_2(self.Y0[Int(m1 - 1)] - self.Y0[Int(m - 1)]) + pow_2(z - z_in)) +
                0.5 * sqrt(pow_2(x - x_out) + pow_2(self.Y0[Int(m1 - 1)] - self.Y0[Int(m - 1)]) + pow_2(z - z_out)))
    
    fn dist_to_center(self, m: Int32, n: Int32, m1: Int32, n1: Int32) -> Float64:
        return sqrt(pow_2(self.X0[Int(n - 1)] - self.X0[Int(n1 - 1)]) + pow_2(self.Y0[Int(m - 1)] - self.Y0[Int(m1 - 1)]))
    
    fn double_integral(self, m: Int32, n: Int32, m1: Int32, n1: Int32, t: Float64, i0: Int32, j0: Int32) -> Float64:
        let eta1: Float64 = 0.0
        let eta2: Float64 = 2 * pi
        
        var g = DynamicVector[Float64](capacity=Int(i0))
        let h = (eta2 - eta1) / Float64(i0 - 1)
        
        # Calculates the value of the function at various equally spaced values
        for i in range(Int(i0)):
            let eta = eta1 + Float64(i) * h
            g.push_back(self.integral(m, n, m1, n1, t, eta, j0))
        
        for i in range(1, Int(g.size()) - 1):
            if not is_even(Int32(i)):
                g[i] = 4 * g[i]
            else:
                g[i] = 2 * g[i]
        
        var sum: Float64 = 0.0
        for val in g:
            sum += val
        return (h / 3) * sum
    
    fn integral(self, m: Int32, n: Int32, m1: Int32, n1: Int32, t: Float64, eta: Float64, j0: Int32) -> Float64:
        let theta1: Float64 = 0.0
        let theta2: Float64 = 2 * pi
        var f = DynamicVector[Float64](capacity=Int(j0))
        
        let h = (theta2 - theta1) / Float64(j0 - 1)
        
        # Calculate the function at various equally spaced x values
        for j in range(Int(j0)):
            let theta = theta1 + Float64(j) * h
            f.push_back(self.near_field_response_function(m, n, m1, n1, eta, theta, t))
        
        for j in range(1, Int(j0) - 1):
            if not is_even(Int32(j)):
                f[j] = 4 * f[j]
            else:
                f[j] = 2 * f[j]
        
        var sum: Float64 = 0.0
        for val in f:
            sum += val
        return (h / 3) * sum
    
    fn get_annual_time_constant(inout self) -> None:
        self.timeSSFactor = 1.0
    
    fn get_g_func(self, time: Float64) -> Float64:
        let lntts = log10(time)
        return self.interp_g_func(lntts)
    
    fn interp_g_func(self, lntts: Float64) -> Float64:
        # Placeholder for interpolation function
        # This would need the actual GFNC and LNTTS data
        if self.myRespFactors == UnsafePointer[GLHEResponseFactors]():
            return 0.0
        
        let gfnc = self.myRespFactors[].GFNC
        let lntts_data = self.myRespFactors[].LNTTS
        
        if gfnc.size() == 0:
            return 0.0
        
        for i in range(Int(gfnc.size()) - 1):
            if lntts_data[i] <= lntts and lntts <= lntts_data[i + 1]:
                let frac = (lntts - lntts_data[i]) / (lntts_data[i + 1] - lntts_data[i])
                return gfnc[i] + frac * (gfnc[i + 1] - gfnc[i])
        
        return gfnc[Int(gfnc.size()) - 1]
    
    fn init_glhe_sim_vars(inout self, state: UnsafePointer[UInt8]) -> None:
        # Placeholder for time calculation from state
        # let cur_time = ((state.dataGlobal.DayOfSim - 1) * Constant.rHoursInDay + ...)
        var cur_time: Float64 = 0.0
        
        # Init more variables
        if self.myEnvrnFlag:  # and state.dataGlobal.BeginEnvrnFlag:
            self.init_environment(state, cur_time)
        
        # self.tempGround = self.groundTempModel.getGroundTempAtTimeInSeconds(state, self.coilDepth, cur_time)
        # self.massFlowRate = PlantUtilities.RegulateCondenserCompFlowReqOp(state, self.plantLoc, self.designMassFlow)
        # PlantUtilities.SetComponentFlowRate(state, self.massFlowRate, self.inletNodeNum, self.outletNodeNum, self.plantLoc)
        
        # Reset local environment init flag
        # if not state.dataGlobal.BeginEnvrnFlag:
        #     self.myEnvrnFlag = True
    
    fn init_environment(inout self, state: UnsafePointer[UInt8], cur_time: Float64) -> None:
        self.myEnvrnFlag = False
        
        # Placeholder for property lookups
        var fluid_density: Float64 = 0.0
        self.designMassFlow = self.designFlow * fluid_density
        
        self.lastQnSubHr = 0.0
        
        # zero out all history arrays
        for i in range(Int(self.QnHr.size())):
            self.QnHr[i] = 0.0
        for i in range(Int(self.QnMonthlyAgg.size())):
            self.QnMonthlyAgg[i] = 0.0
        for i in range(Int(self.QnSubHr.size())):
            self.QnSubHr[i] = 0.0
        for i in range(Int(self.LastHourN.size())):
            self.LastHourN[i] = 0
        for i in range(Int(self.prevTimeSteps.size())):
            self.prevTimeSteps[i] = 0.0
        
        self.currentSimTime = 0.0
        self.QGLHE = 0.0
        self.prevHour = 1
    
    fn one_time_init_new(inout self, state: UnsafePointer[UInt8]) -> None:
        # Placeholder: Locate the hx on the plant loops for later usage
        pass
    
    fn one_time_init(inout self, state: UnsafePointer[UInt8]) -> None:
        pass
