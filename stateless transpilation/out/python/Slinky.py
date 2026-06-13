# EnergyPlus, Copyright (c) 1996-present, The Board of Trustees of the University of Illinois,
# The Regents of the University of California, through Lawrence Berkeley National Laboratory
# (subject to receipt of any required approvals from the U.S. Dept. of Energy), Oak Ridge
# National Laboratory, managed by UT-Battelle, Alliance for Energy Innovation, LLC, and other
# contributors. All rights reserved.

import math
from typing import Any, Dict, List, Protocol, Optional
from dataclasses import dataclass, field

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object with dataGlobal, dataPlnt, dataLoopNodes, dataHVACGlobal, dataGroundHeatExchanger
# - GLHEBase: base class with inherited members (name, inletNodeNum, outletNodeNum, soil, pipe, etc.)
# - GLHEResponseFactors: response factor storage object
# - GroundTemp: module with ModelType enum and GetGroundTempModelAndInit function
# - Constant: module with Pi, rHoursInDay, rSecsInHour values
# - Node, PlantUtilities, BranchNodeConnections: utility modules
# - GroundTempModel: temperature model with getGroundTempAtTimeInSeconds method
# - ShowFatalError, ShowSevereError, ShowContinueError, DisplayString: error/logging functions
# - maxTSinHr: constant for max time steps in hour
# - Util: utility module with makeUPPER, SameString functions

def pow_2(x: float) -> float:
    return x * x

def is_even(n: int) -> bool:
    return n % 2 == 0

@dataclass
class SoilProperties:
    k: float = 0.0
    rho: float = 0.0
    cp: float = 0.0
    rhoCp: float = 0.0
    diffusivity: float = 0.0

@dataclass
class PipeProperties:
    k: float = 0.0
    rho: float = 0.0
    cp: float = 0.0
    outDia: float = 0.0
    outRadius: float = 0.0
    thickness: float = 0.0

class GLHESlinky:
    MODULE_NAME = "GroundHeatExchanger:Slinky"
    
    def __init__(self):
        self.name: str = ""
        self.moduleName: str = self.MODULE_NAME
        self.verticalConfig: bool = False
        self.coilDiameter: float = 0.0
        self.coilPitch: float = 0.0
        self.coilDepth: float = 0.0
        self.trenchDepth: float = 0.0
        self.trenchLength: float = 0.0
        self.numTrenches: int = 0
        self.trenchSpacing: float = 0.0
        self.numCoils: int = 0
        self.monthOfMinSurfTemp: int = 0
        self.maxSimYears: float = 0.0
        self.minSurfTemp: float = 0.0
        self.X0: List[float] = []
        self.Y0: List[float] = []
        self.Z0: float = 0.0
        
        # Inherited from GLHEBase (stub)
        self.inletNodeNum: int = 0
        self.outletNodeNum: int = 0
        self.available: bool = True
        self.on: bool = True
        self.designFlow: float = 0.0
        self.inletTemp: float = 0.0
        self.plantLoc: Any = None
        self.massFlowRate: float = 0.0
        self.soil: SoilProperties = SoilProperties()
        self.pipe: PipeProperties = PipeProperties()
        self.myRespFactors: Any = None
        self.timeSSFactor: float = 1.0
        self.tempGround: float = 0.0
        self.designMassFlow: float = 0.0
        self.myEnvrnFlag: bool = True
        self.groundTempModel: Any = None
        self.QnMonthlyAgg: List[float] = []
        self.QnHr: List[float] = []
        self.QnSubHr: List[float] = []
        self.LastHourN: List[int] = []
        self.prevTimeSteps: List[float] = []
        self.AGG: int = 0
        self.SubAGG: int = 0
        self.totalTubeLength: float = 0.0
        self.QGLHE: float = 0.0
        self.prevHour: int = 1
        self.currentSimTime: float = 0.0
        self.lastQnSubHr: float = 0.0
    
    def init_from_json(self, state: Any, obj_name: str, j: Dict[str, Any]) -> None:
        # Check for duplicates
        for existing_obj in state.dataGroundHeatExchanger.singleBoreholesVector:
            if obj_name == existing_obj.name:
                raise ValueError(f"Invalid input for {self.moduleName} object: Duplicate name found: {existing_obj.name}")
        
        errors_found = False
        self.name = obj_name
        
        inlet_node_name = j["inlet_node_name"].upper()
        outlet_node_name = j["outlet_node_name"].upper()
        
        # get inlet node num
        self.inletNodeNum = Node.GetOnlySingleNode(
            state, inlet_node_name, errors_found,
            Node.ConnectionObjectType.GroundHeatExchangerSlinky,
            self.name, Node.FluidType.Water,
            Node.ConnectionType.Inlet,
            Node.CompFluidStream.Primary,
            Node.ObjectIsNotParent
        )
        
        # get outlet node num
        self.outletNodeNum = Node.GetOnlySingleNode(
            state, outlet_node_name, errors_found,
            Node.ConnectionObjectType.GroundHeatExchangerSlinky,
            self.name, Node.FluidType.Water,
            Node.ConnectionType.Outlet,
            Node.CompFluidStream.Primary,
            Node.ObjectIsNotParent
        )
        
        self.available = True
        self.on = True
        
        Node.TestCompSet(state, self.moduleName, self.name, inlet_node_name, outlet_node_name, "Condenser Water Nodes")
        
        # load data
        self.designFlow = j["design_flow_rate"]
        PlantUtilities.RegisterPlantCompDesignFlow(state, self.inletNodeNum, self.designFlow)
        
        self.soil.k = j["soil_thermal_conductivity"]
        self.soil.rho = j["soil_density"]
        self.soil.cp = j["soil_specific_heat"]
        self.soil.rhoCp = self.soil.rho * self.soil.cp
        self.pipe.k = j["pipe_thermal_conductivity"]
        self.pipe.rho = j["pipe_density"]
        self.pipe.cp = j["pipe_specific_heat"]
        self.pipe.outDia = j["pipe_outer_diameter"]
        self.pipe.outRadius = self.pipe.outDia / 2.0
        self.pipe.thickness = j["pipe_thickness"]
        
        hx_config = j["heat_exchanger_configuration"].upper()
        if hx_config == "VERTICAL":
            self.verticalConfig = True
        elif hx_config == "HORIZONTAL":
            self.verticalConfig = False
        
        self.coilDiameter = j["coil_diameter"]
        self.coilPitch = j["coil_pitch"]
        self.trenchDepth = j["trench_depth"]
        self.trenchLength = j["trench_length"]
        self.numTrenches = j["number_of_trenches"]
        self.trenchSpacing = j["horizontal_spacing_between_pipes"]
        self.maxSimYears = j["maximum_length_of_simulation"]
        
        # Need to add a response factor object for the slinky model
        self.myRespFactors = GLHEResponseFactors()
        self.myRespFactors.name = f"Response Factor Object Auto Generated No: {state.dataGroundHeatExchanger.numAutoGeneratedResponseFactors + 1}"
        state.dataGroundHeatExchanger.responseFactorsVector.append(self.myRespFactors)
        
        # Number of coils
        self.numCoils = int(self.trenchLength / self.coilPitch)
        
        # Total tube length
        self.totalTubeLength = Constant.Pi * self.coilDiameter * self.trenchLength * self.numTrenches / self.coilPitch
        
        # Get g function data
        self.SubAGG = 15
        self.AGG = 192
        
        # Average coil depth
        if self.verticalConfig:
            if self.trenchDepth - self.coilDiameter < 0.0:
                raise ValueError(f"{self.moduleName}=\"{self.name}\", invalid value in field.")
            else:
                self.coilDepth = self.trenchDepth - (self.coilDiameter / 2.0)
        else:
            self.coilDepth = self.trenchDepth
        
        # Thermal diffusivity of the ground
        self.soil.diffusivity = self.soil.k / self.soil.rhoCp
        
        max_ts_in_hr = getattr(state, 'maxTSinHr', 4)  # Default to 4 if not found
        self.prevTimeSteps = [0.0] * ((self.SubAGG + 1) * max_ts_in_hr + 1)
        
        if self.pipe.thickness >= self.pipe.outDia / 2.0:
            raise ValueError(f"{self.moduleName}=\"{self.name}\", invalid pipe thickness.")
        
        # Initialize ground temperature model
        gtm_type = GroundTemp.ModelType[j["undisturbed_ground_temperature_model_type"].upper()]
        gtm_name = j["undisturbed_ground_temperature_model_name"].upper()
        self.groundTempModel = GroundTemp.GetGroundTempModelAndInit(state, gtm_type, gtm_name)
    
    def calc_hx_resistance(self, state: Any) -> float:
        routine_name = "CalcSlinkyGroundHeatExchanger"
        
        cp_fluid = state.dataPlnt.PlantLoop[self.plantLoc.loopNum].glycol.getSpecificHeat(state, self.inletTemp, routine_name)
        k_fluid = state.dataPlnt.PlantLoop[self.plantLoc.loopNum].glycol.getConductivity(state, self.inletTemp, routine_name)
        fluid_density = state.dataPlnt.PlantLoop[self.plantLoc.loopNum].glycol.getDensity(state, self.inletTemp, routine_name)
        fluid_viscosity = state.dataPlnt.PlantLoop[self.plantLoc.loopNum].glycol.getViscosity(state, self.inletTemp, routine_name)
        
        # calculate mass flow rate
        single_slinky_mass_flow_rate = self.massFlowRate / self.numTrenches
        
        pipe_inner_rad = self.pipe.outRadius - self.pipe.thickness
        pipe_inner_dia = 2.0 * pipe_inner_rad
        
        if single_slinky_mass_flow_rate == 0.0:
            rconv = 0.0
        else:
            reynolds_num = (fluid_density * pipe_inner_dia * 
                          (single_slinky_mass_flow_rate / fluid_density / (Constant.Pi * pow_2(pipe_inner_rad))) / 
                          fluid_viscosity)
            prandtl_num = (cp_fluid * fluid_viscosity) / k_fluid
            
            laminar_nusselt_no = 4.364
            if reynolds_num <= 2300:
                nusselt_num = laminar_nusselt_no
            elif reynolds_num > 2300 and reynolds_num <= 4000:
                A = 3150
                B = 350
                sf = 0.5 + 0.5 * math.tanh((reynolds_num - A) / B)
                turbulent_nusselt_no = 0.023 * pow(reynolds_num, 0.8) * pow(prandtl_num, 0.35)
                nusselt_num = laminar_nusselt_no * (1 - sf) + turbulent_nusselt_no * sf
            else:
                nusselt_num = 0.023 * pow(reynolds_num, 0.8) * pow(prandtl_num, 0.35)
            
            hci = nusselt_num * k_fluid / pipe_inner_dia
            rconv = 1.0 / (2.0 * Constant.Pi * pipe_inner_dia * hci)
        
        # Conduction Resistance
        rcond = math.log(self.pipe.outRadius / pipe_inner_rad) / (2.0 * Constant.Pi * self.pipe.k) / 2.0
        
        return rcond + rconv
    
    def calc_g_functions(self, state: Any) -> None:
        t_lg_min = -2.0
        t_lg_grid = 0.25
        ts = 3600.0
        convert_years_to_seconds = 356.0 * 24.0 * 60.0 * 60.0
        
        val_stored: Dict[tuple, float] = {}
        
        DisplayString(state, f"Initializing GroundHeatExchanger:Slinky: {self.name}")
        
        self.X0 = [0.0] * self.numCoils
        self.Y0 = [0.0] * self.numTrenches
        
        # Calculate the number of g-functions required
        t_lg_max = math.log10(self.maxSimYears * convert_years_to_seconds / ts)
        n_pairs = int((t_lg_max - t_lg_min) / t_lg_grid + 1)
        
        # Allocate and setup g-function arrays
        self.myRespFactors.GFNC = [0.0] * n_pairs
        self.myRespFactors.LNTTS = [0.0] * n_pairs
        self.QnMonthlyAgg = [0.0] * int(self.maxSimYears * 12)
        self.QnHr = [0.0] * (730 + self.AGG + self.SubAGG)
        self.QnSubHr = [0.0] * (int((self.SubAGG + 1) * getattr(state, 'maxTSinHr', 4)) + 1)
        self.LastHourN = [0] * (self.SubAGG + 1)
        
        # Calculate the number of loops (per trench) and number of trenches to be involved
        num_lc = math.ceil(self.numCoils / 2.0)
        num_rc = math.ceil(self.numTrenches / 2.0)
        
        # Calculate coordinates (X0, Y0, Z0) of a ring's center
        for coil in range(self.numCoils):
            self.X0[coil] = self.coilPitch * coil
        
        for trench in range(self.numTrenches):
            self.Y0[trench] = trench * self.trenchSpacing
        
        self.Z0 = self.coilDepth
        
        # If number of trenches is greater than 1, one quarter of the rings are involved.
        # If number of trenches is 1, one half of the rings are involved.
        if self.numTrenches > 1:
            fraction = 0.25
        else:
            fraction = 0.5
        
        # Calculate the corresponding time of each temperature response factor
        for nt in range(n_pairs):
            t_lg = t_lg_min + t_lg_grid * nt
            t = pow(10, t_lg) * ts
            
            # Set the average temperature response of the whole field to zero
            g_func = 0.0
            
            val_stored.clear()
            
            for m1 in range(1, int(num_rc) + 1):
                for n1 in range(1, int(num_lc) + 1):
                    for m in range(1, self.numTrenches + 1):
                        for n in range(1, self.numCoils + 1):
                            # Zero out val after each iteration
                            double_integral_val = 0.0
                            mid_field_val = 0.0
                            
                            # Calculate the distance between ring centers
                            dis_ring = self.dist_to_center(m, n, m1, n1)
                            
                            # Save mm1 and nn1
                            mm1 = abs(m - m1)
                            nn1 = abs(n - n1)
                            
                            # If we're calculating a ring's temperature response to itself as a ring source,
                            # then we need some extra effort in calculating the double integral
                            if m1 == m and n1 == n:
                                i0 = 33
                                j0 = 1089
                            else:
                                i0 = 33
                                j0 = 561
                            
                            # if the ring(n1, m1) is the near-field ring of the ring(n,m)
                            if dis_ring <= 2.5 + self.coilDiameter:
                                # if no calculated value has been stored
                                if (mm1, nn1) not in val_stored:
                                    double_integral_val = self.double_integral(m, n, m1, n1, t, i0, j0)
                                    val_stored[(mm1, nn1)] = double_integral_val
                                else:
                                    double_integral_val = val_stored[(mm1, nn1)]
                                
                                # due to symmetry, the temperature response of ring(n1, m1) should be 0.25, 0.5, or 1 times its calculated value
                                if (not is_even(self.numTrenches) and not is_even(self.numCoils) and 
                                    m1 == num_rc and n1 == num_lc and self.numTrenches > 1.5):
                                    g_funcin = 0.25 * double_integral_val
                                elif (not is_even(self.numTrenches) and m1 == num_rc and self.numTrenches > 1.5):
                                    g_funcin = 0.5 * double_integral_val
                                elif not is_even(self.numCoils) and n1 == num_lc:
                                    g_funcin = 0.5 * double_integral_val
                                else:
                                    g_funcin = double_integral_val
                            
                            # if the ring(n1, m1) is in the far-field or the ring(n,m)
                            elif dis_ring > (10 + self.coilDiameter):
                                g_funcin = 0.0
                            
                            # else the ring(n1, m1) is in the middle-field of the ring(n,m)
                            else:
                                # if no calculated value have been stored
                                if (mm1, nn1) not in val_stored:
                                    mid_field_val = self.mid_field_response_function(m, n, m1, n1, t)
                                    val_stored[(mm1, nn1)] = mid_field_val
                                else:
                                    mid_field_val = val_stored[(mm1, nn1)]
                                
                                # due to symmetry, the temperature response of ring(n1, m1) should be 0.25, 0.5, or 1 times its calculated value
                                if (not is_even(self.numTrenches) and not is_even(self.numCoils) and 
                                    m1 == num_rc and n1 == num_lc and self.numTrenches > 1.5):
                                    g_funcin = 0.25 * mid_field_val
                                elif (not is_even(self.numTrenches) and m1 == num_rc and self.numTrenches > 1.5):
                                    g_funcin = 0.5 * mid_field_val
                                elif not is_even(self.numCoils) and n1 == num_lc:
                                    g_funcin = 0.5 * mid_field_val
                                else:
                                    g_funcin = mid_field_val
                            
                            g_func += g_funcin
            
            self.myRespFactors.GFNC[nt] = (g_func * (self.coilDiameter / 2.0)) / (4 * Constant.Pi * fraction * self.numTrenches * self.numCoils)
            self.myRespFactors.LNTTS[nt] = t_lg
    
    def near_field_response_function(self, m: int, n: int, m1: int, n1: int, eta: float, theta: float, t: float) -> float:
        distance1 = self.distance(m, n, m1, n1, eta, theta)
        sqrt_alpha_t = math.sqrt(self.soil.diffusivity * t)
        
        if not self.verticalConfig:
            sqrt_dist_depth = math.sqrt(pow_2(distance1) + 4 * pow_2(self.coilDepth))
            err_func1 = math.erfc(0.5 * distance1 / sqrt_alpha_t)
            err_func2 = math.erfc(0.5 * sqrt_dist_depth / sqrt_alpha_t)
            
            return err_func1 / distance1 - err_func2 / sqrt_dist_depth
        
        distance2 = self.distance_to_fict_ring(m, n, m1, n1, eta, theta)
        err_func1 = math.erfc(0.5 * distance1 / sqrt_alpha_t)
        err_func2 = math.erfc(0.5 * distance2 / sqrt_alpha_t)
        
        return err_func1 / distance1 - err_func2 / distance2
    
    def mid_field_response_function(self, m: int, n: int, m1: int, n1: int, t: float) -> float:
        sqrt_alpha_t = math.sqrt(self.soil.diffusivity * t)
        
        distance = self.dist_to_center(m, n, m1, n1)
        sqrt_dist_depth = math.sqrt(pow_2(distance) + 4 * pow_2(self.coilDepth))
        
        err_func1 = math.erfc(0.5 * distance / sqrt_alpha_t)
        err_func2 = math.erfc(0.5 * sqrt_dist_depth / sqrt_alpha_t)
        
        return 4 * pow_2(Constant.Pi) * (err_func1 / distance - err_func2 / sqrt_dist_depth)
    
    def distance(self, m: int, n: int, m1: int, n1: int, eta: float, theta: float) -> float:
        cos_theta = math.cos(theta)
        sin_theta = math.sin(theta)
        cos_eta = math.cos(eta)
        sin_eta = math.sin(eta)
        
        x = self.X0[n - 1] + cos_theta * (self.coilDiameter / 2.0)
        y = self.Y0[m - 1] + sin_theta * (self.coilDiameter / 2.0)
        
        x_in = self.X0[n1 - 1] + cos_eta * (self.coilDiameter / 2.0 - self.pipe.outRadius)
        y_in = self.Y0[m1 - 1] + sin_eta * (self.coilDiameter / 2.0 - self.pipe.outRadius)
        
        x_out = self.X0[n1 - 1] + cos_eta * (self.coilDiameter / 2.0 + self.pipe.outRadius)
        y_out = self.Y0[m1 - 1] + sin_eta * (self.coilDiameter / 2.0 + self.pipe.outRadius)
        
        if not self.verticalConfig:
            return 0.5 * math.sqrt(pow_2(x - x_in) + pow_2(y - y_in)) + 0.5 * math.sqrt(pow_2(x - x_out) + pow_2(y - y_out))
        
        z = self.Z0 + sin_theta * (self.coilDiameter / 2.0)
        z_in = self.Z0 + sin_eta * (self.coilDiameter / 2.0 - self.pipe.outRadius)
        z_out = self.Z0 + sin_eta * (self.coilDiameter / 2.0 + self.pipe.outRadius)
        
        return (0.5 * math.sqrt(pow_2(x - x_in) + pow_2(self.Y0[m1 - 1] - self.Y0[m - 1]) + pow_2(z - z_in)) +
                0.5 * math.sqrt(pow_2(x - x_out) + pow_2(self.Y0[m1 - 1] - self.Y0[m - 1]) + pow_2(z - z_out)))
    
    def distance_to_fict_ring(self, m: int, n: int, m1: int, n1: int, eta: float, theta: float) -> float:
        sin_theta = math.sin(theta)
        cos_theta = math.cos(theta)
        sin_eta = math.sin(eta)
        cos_eta = math.cos(eta)
        
        x = self.X0[n - 1] + cos_theta * (self.coilDiameter / 2.0)
        z = self.Z0 + sin_theta * (self.coilDiameter / 2.0) + 2 * self.coilDepth
        
        x_in = self.X0[n1 - 1] + cos_eta * (self.coilDiameter / 2.0 - self.pipe.outRadius)
        z_in = self.Z0 + sin_eta * (self.coilDiameter / 2.0 - self.pipe.outRadius)
        
        x_out = self.X0[n1 - 1] + cos_eta * (self.coilDiameter / 2.0 + self.pipe.outRadius)
        z_out = self.Z0 + sin_eta * (self.coilDiameter / 2.0 + self.pipe.outRadius)
        
        return (0.5 * math.sqrt(pow_2(x - x_in) + pow_2(self.Y0[m1 - 1] - self.Y0[m - 1]) + pow_2(z - z_in)) +
                0.5 * math.sqrt(pow_2(x - x_out) + pow_2(self.Y0[m1 - 1] - self.Y0[m - 1]) + pow_2(z - z_out)))
    
    def dist_to_center(self, m: int, n: int, m1: int, n1: int) -> float:
        return math.sqrt(pow_2(self.X0[n - 1] - self.X0[n1 - 1]) + pow_2(self.Y0[m - 1] - self.Y0[m1 - 1]))
    
    def double_integral(self, m: int, n: int, m1: int, n1: int, t: float, i0: int, j0: int) -> float:
        eta1 = 0.0
        eta2 = 2 * Constant.Pi
        
        g = []
        h = (eta2 - eta1) / (i0 - 1)
        
        # Calculates the value of the function at various equally spaced values
        for i in range(i0):
            eta = eta1 + i * h
            g.append(self.integral(m, n, m1, n1, t, eta, j0))
        
        for i in range(1, len(g) - 1):
            if not is_even(i):
                g[i] = 4 * g[i]
            else:
                g[i] = 2 * g[i]
        
        return (h / 3) * sum(g)
    
    def integral(self, m: int, n: int, m1: int, n1: int, t: float, eta: float, j0: int) -> float:
        theta1 = 0.0
        theta2 = 2 * Constant.Pi
        f = []
        
        h = (theta2 - theta1) / (j0 - 1)
        
        # Calculate the function at various equally spaced x values
        for j in range(j0):
            theta = theta1 + j * h
            f.append(self.near_field_response_function(m, n, m1, n1, eta, theta, t))
        
        for j in range(1, j0 - 1):
            if not is_even(j):
                f[j] = 4 * f[j]
            else:
                f[j] = 2 * f[j]
        
        return (h / 3) * sum(f)
    
    def get_annual_time_constant(self) -> None:
        self.timeSSFactor = 1.0
    
    def get_g_func(self, time: float) -> float:
        lntts = math.log10(time)
        return self.interp_g_func(lntts)
    
    def interp_g_func(self, lntts: float) -> float:
        # Placeholder for interpolation function
        # This would need the actual GFNC and LNTTS data
        if not self.myRespFactors or not self.myRespFactors.GFNC:
            return 0.0
        
        # Simple linear interpolation
        gfnc = self.myRespFactors.GFNC
        lntts_data = self.myRespFactors.LNTTS
        
        for i in range(len(lntts_data) - 1):
            if lntts_data[i] <= lntts <= lntts_data[i + 1]:
                frac = (lntts - lntts_data[i]) / (lntts_data[i + 1] - lntts_data[i])
                return gfnc[i] + frac * (gfnc[i + 1] - gfnc[i])
        
        return gfnc[-1] if gfnc else 0.0
    
    def init_glhe_sim_vars(self, state: Any) -> None:
        cur_time = ((state.dataGlobal.DayOfSim - 1) * Constant.rHoursInDay + (state.dataGlobal.HourOfDay - 1) +
                    (state.dataGlobal.TimeStep - 1) * state.dataGlobal.TimeStepZone + state.dataHVACGlobal.SysTimeElapsed) * Constant.rSecsInHour
        
        # Init more variables
        if self.myEnvrnFlag and state.dataGlobal.BeginEnvrnFlag:
            self.init_environment(state, cur_time)
        
        self.tempGround = self.groundTempModel.getGroundTempAtTimeInSeconds(state, self.coilDepth, cur_time)
        
        self.massFlowRate = PlantUtilities.RegulateCondenserCompFlowReqOp(state, self.plantLoc, self.designMassFlow)
        
        PlantUtilities.SetComponentFlowRate(state, self.massFlowRate, self.inletNodeNum, self.outletNodeNum, self.plantLoc)
        
        # Reset local environment init flag
        if not state.dataGlobal.BeginEnvrnFlag:
            self.myEnvrnFlag = True
    
    def init_environment(self, state: Any, cur_time: float) -> None:
        routine_name = "initEnvironment"
        self.myEnvrnFlag = False
        
        fluid_density = state.dataPlnt.PlantLoop[self.plantLoc.loopNum].glycol.getDensity(state, 20.0, routine_name)
        self.designMassFlow = self.designFlow * fluid_density
        PlantUtilities.InitComponentNodes(state, 0.0, self.designMassFlow, self.inletNodeNum, self.outletNodeNum)
        
        self.lastQnSubHr = 0.0
        state.dataLoopNodes.Node[self.inletNodeNum].Temp = self.groundTempModel.getGroundTempAtTimeInSeconds(state, self.coilDepth, cur_time)
        state.dataLoopNodes.Node[self.outletNodeNum].Temp = self.groundTempModel.getGroundTempAtTimeInSeconds(state, self.coilDepth, cur_time)
        
        # zero out all history arrays
        self.QnHr = [0.0] * len(self.QnHr)
        self.QnMonthlyAgg = [0.0] * len(self.QnMonthlyAgg)
        self.QnSubHr = [0.0] * len(self.QnSubHr)
        self.LastHourN = [0] * len(self.LastHourN)
        self.prevTimeSteps = [0.0] * len(self.prevTimeSteps)
        self.currentSimTime = 0.0
        self.QGLHE = 0.0
        self.prevHour = 1
    
    def one_time_init_new(self, state: Any) -> None:
        # Locate the hx on the plant loops for later usage
        PlantUtilities.ScanPlantLoopsForObject(
            state, self.name, "GrndHtExchgSlinky", self.plantLoc
        )
    
    def one_time_init(self, state: Any) -> None:
        pass


@dataclass
class GLHEResponseFactors:
    name: str = ""
    GFNC: List[float] = field(default_factory=list)
    LNTTS: List[float] = field(default_factory=list)
