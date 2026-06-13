from math import exp, fabs
from collections import InlineArray


# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state container with dataInputProcessing, dataMaterial sub-objects
# - MaterialBase: base struct for materials (fields: group, name, hasPCM, hasEMPD, hasHAMT)
# - BaseGlobalStruct: base struct for global state
# - GetMaterialNum(state, name: String) -> Int: find material index by name
# - ShowSevereEmptyField(state, eoh, field_name: String, value: String): error reporting
# - ShowSevereItemNotFound(state, eoh, field_name: String, value: String): error reporting
# - ShowSevereCustom(state, eoh, msg: String): error reporting
# - ErrorObjectHeader: header for error reporting (routineName, objectType, name)
# - Group.Regular: enum value for regular material group


@export
fn phase_invalid() -> Int:
    return -1


@export
fn phase_liquid() -> Int:
    return 0


@export
fn phase_melting() -> Int:
    return 1


@export
fn phase_transition() -> Int:
    return 2


@export
fn phase_freezing() -> Int:
    return 3


@export
fn phase_crystallized() -> Int:
    return 4


@export
fn phase_num() -> Int:
    return 5


struct MaterialPhaseChange:
    var enthalpy_m: Float64
    var enthalpy_f: Float64
    
    var total_latent_heat: Float64
    var specific_heat_liquid: Float64
    var delta_temp_melting_high: Float64
    var peak_temp_melting: Float64
    var delta_temp_melting_low: Float64
    var specific_heat_solid: Float64
    var delta_temp_freezing_high: Float64
    var peak_temp_freezing: Float64
    var delta_temp_freezing_low: Float64
    
    var fully_solid_thermal_conductivity: Float64
    var fully_liquid_thermal_conductivity: Float64
    var fully_solid_density: Float64
    var fully_liquid_density: Float64
    
    var phase_change_transition: Bool
    var enth_old: Float64
    var enth_new: Float64
    var enth_rev: Float64
    var cp_old: Float64
    var spec_heat_transition: Float64
    
    var group: Int
    var name: String
    var has_pcm: Bool
    var has_empd: Bool
    var has_hamt: Bool
    
    fn __init__(inout self):
        self.enthalpy_m = 0.0
        self.enthalpy_f = 0.0
        self.total_latent_heat = 0.0
        self.specific_heat_liquid = 0.0
        self.delta_temp_melting_high = 0.0
        self.peak_temp_melting = 0.0
        self.delta_temp_melting_low = 0.0
        self.specific_heat_solid = 0.0
        self.delta_temp_freezing_high = 0.0
        self.peak_temp_freezing = 0.0
        self.delta_temp_freezing_low = 0.0
        self.fully_solid_thermal_conductivity = 0.0
        self.fully_liquid_thermal_conductivity = 0.0
        self.fully_solid_density = 0.0
        self.fully_liquid_density = 0.0
        self.phase_change_transition = False
        self.enth_old = 0.0
        self.enth_new = 0.0
        self.enth_rev = 0.0
        self.cp_old = 0.0
        self.spec_heat_transition = 0.0
        self.group = 0
        self.name = ""
        self.has_pcm = False
        self.has_empd = False
        self.has_hamt = False
    
    fn get_enthalpy(self, T: Float64, Tc: Float64, tau1: Float64, tau2: Float64) -> Float64:
        let eta1 = (self.total_latent_heat / 2.0) * exp(-2.0 * fabs(T - Tc) / tau1)
        let eta2 = (self.total_latent_heat / 2.0) * exp(-2.0 * fabs(T - Tc) / tau2)
        if T <= Tc:
            return (self.specific_heat_solid * T) + eta1
        return (self.specific_heat_solid * Tc) + self.total_latent_heat + self.specific_heat_liquid * (T - Tc) - eta2
    
    fn get_current_specific_heat(
        inout self,
        prev_temp_td: Float64,
        updated_temp_tdt: Float64,
        phase_change_temp_reverse: Float64,
        prev_phase_change_state: Int,
    ) -> (Float64, Int):
        let temp_low_pcm = self.peak_temp_melting - self.delta_temp_melting_low
        let temp_high_pcm = self.peak_temp_melting + self.delta_temp_melting_high
        var tc = 0.0
        var tau1 = 0.0
        var tau2 = 0.0
        let temp_low_pcf = self.peak_temp_freezing - self.delta_temp_freezing_low
        let temp_high_pcf = self.peak_temp_freezing + self.delta_temp_freezing_high
        var cp = 0.0
        let phase_change_delta_t = prev_temp_td - updated_temp_tdt
        
        var phase_change_state = prev_phase_change_state
        
        if phase_change_delta_t <= 0.0:
            tc = self.peak_temp_melting
            tau1 = self.delta_temp_melting_low
            tau2 = self.delta_temp_melting_high
            if updated_temp_tdt < temp_low_pcm:
                phase_change_state = phase_crystallized()
            elif updated_temp_tdt <= temp_high_pcm:
                phase_change_state = phase_melting()
                if prev_phase_change_state == phase_freezing() or prev_phase_change_state == phase_transition():
                    phase_change_state = phase_transition()
            else:
                phase_change_state = phase_liquid()
        else:
            tc = self.peak_temp_freezing
            tau1 = self.delta_temp_freezing_low
            tau2 = self.delta_temp_freezing_high
            if updated_temp_tdt < temp_low_pcf:
                phase_change_state = phase_crystallized()
            elif updated_temp_tdt <= temp_high_pcf:
                phase_change_state = phase_freezing()
                if prev_phase_change_state == phase_melting() or prev_phase_change_state == phase_transition():
                    phase_change_state = phase_transition()
            else:
                phase_change_state = phase_liquid()
        
        if prev_phase_change_state == phase_transition() and phase_change_state == phase_crystallized():
            self.phase_change_transition = True
        elif prev_phase_change_state == phase_transition() and phase_change_state == phase_freezing():
            self.phase_change_transition = True
        elif prev_phase_change_state == phase_freezing() and phase_change_state == phase_transition():
            self.phase_change_transition = True
        elif prev_phase_change_state == phase_crystallized() and phase_change_state == phase_transition():
            self.phase_change_transition = True
        else:
            self.phase_change_transition = False
        
        if not self.phase_change_transition:
            self.enth_old = self.get_enthalpy(prev_temp_td, tc, tau1, tau2)
            self.enth_new = self.get_enthalpy(updated_temp_tdt, tc, tau1, tau2)
        else:
            if prev_phase_change_state == phase_freezing() and phase_change_state == phase_transition():
                self.enth_rev = self.get_enthalpy(phase_change_temp_reverse, self.peak_temp_freezing, 
                                                   self.delta_temp_freezing_low, self.delta_temp_freezing_high)
                self.enth_new = (self.spec_heat_transition * updated_temp_tdt) + (self.enth_old - (self.spec_heat_transition * prev_temp_td))
                self.enthalpy_m = self.get_enthalpy(updated_temp_tdt, self.peak_temp_melting, 
                                                     self.delta_temp_melting_low, self.delta_temp_melting_high)
                self.enthalpy_f = self.get_enthalpy(updated_temp_tdt, self.peak_temp_freezing, 
                                                     self.delta_temp_freezing_low, self.delta_temp_freezing_high)
                if self.enth_new < self.enth_rev and self.enth_new >= self.enthalpy_f and updated_temp_tdt <= prev_temp_td:
                    phase_change_state = phase_freezing()
                    self.enth_new = self.get_enthalpy(updated_temp_tdt, self.peak_temp_freezing, 
                                                       self.delta_temp_freezing_low, self.delta_temp_freezing_high)
                elif (self.enth_new < self.enthalpy_f) and (self.enth_new > self.enthalpy_m):
                    phase_change_state = phase_transition()
                    self.enth_new = (self.spec_heat_transition * updated_temp_tdt) + (self.enth_old - (self.spec_heat_transition * prev_temp_td))
                elif (self.enth_new < self.enthalpy_f) and (updated_temp_tdt > phase_change_temp_reverse):
                    phase_change_state = phase_transition()
                    self.enth_new = (self.spec_heat_transition * updated_temp_tdt) + (self.enth_rev - (self.spec_heat_transition * phase_change_temp_reverse))
                elif (self.enth_new <= self.enthalpy_m) and (updated_temp_tdt <= phase_change_temp_reverse):
                    phase_change_state = phase_transition()
                    self.enth_new = (self.spec_heat_transition * updated_temp_tdt) + (self.enth_rev - (self.spec_heat_transition * phase_change_temp_reverse))
            elif prev_phase_change_state == phase_transition() and phase_change_state == phase_transition():
                if updated_temp_tdt < phase_change_temp_reverse:
                    tc = self.peak_temp_melting
                    tau1 = self.delta_temp_melting_low
                    tau2 = self.delta_temp_melting_high
                elif updated_temp_tdt > phase_change_temp_reverse:
                    tc = self.peak_temp_freezing
                    tau1 = self.delta_temp_freezing_low
                    tau2 = self.delta_temp_freezing_high
                self.enth_rev = self.get_enthalpy(phase_change_temp_reverse, tc, self.delta_temp_melting_low, self.delta_temp_melting_high)
                self.enth_new = (self.spec_heat_transition * updated_temp_tdt) + (self.enth_old - (self.spec_heat_transition * prev_temp_td))
                self.enthalpy_m = self.get_enthalpy(updated_temp_tdt, self.peak_temp_melting, 
                                                     self.delta_temp_melting_low, self.delta_temp_melting_high)
                self.enthalpy_f = self.get_enthalpy(updated_temp_tdt, self.peak_temp_melting, 
                                                     self.delta_temp_melting_low, self.delta_temp_melting_high)
                if (updated_temp_tdt < phase_change_temp_reverse) and (self.enth_new > self.enthalpy_f):
                    phase_change_state = phase_freezing()
                    self.enth_new = self.get_enthalpy(updated_temp_tdt, self.peak_temp_freezing, 
                                                       self.delta_temp_freezing_low, self.delta_temp_freezing_high)
                elif (self.enth_new < self.enthalpy_f) and (self.enth_new > self.enthalpy_m) and \
                     (updated_temp_tdt < prev_temp_td or updated_temp_tdt > prev_temp_td):
                    phase_change_state = phase_transition()
                    self.enth_new = (self.spec_heat_transition * updated_temp_tdt) + (self.enth_rev - (self.spec_heat_transition * phase_change_temp_reverse))
                elif self.enth_new <= self.enthalpy_m and updated_temp_tdt >= prev_temp_td and self.enth_new > self.enth_old:
                    phase_change_state = phase_melting()
                    self.enth_new = (self.spec_heat_transition * updated_temp_tdt) + (self.enth_rev - (self.spec_heat_transition * phase_change_temp_reverse))
            elif prev_phase_change_state == phase_transition() and phase_change_state == phase_crystallized():
                self.enth_rev = self.get_enthalpy(phase_change_temp_reverse, self.peak_temp_freezing, 
                                                   self.delta_temp_freezing_low, self.delta_temp_freezing_high)
                self.enth_new = (self.spec_heat_transition * updated_temp_tdt) + (self.enth_rev - (self.spec_heat_transition * phase_change_temp_reverse))
                self.enthalpy_m = self.get_enthalpy(updated_temp_tdt, self.peak_temp_melting, 
                                                     self.delta_temp_melting_low, self.delta_temp_melting_high)
                self.enthalpy_f = self.get_enthalpy(updated_temp_tdt, self.peak_temp_freezing, 
                                                     self.delta_temp_freezing_low, self.delta_temp_freezing_high)
                if (self.enth_new < self.enthalpy_f) and (self.enth_new > self.enthalpy_m):
                    phase_change_state = phase_transition()
                    self.enth_new = (self.spec_heat_transition * updated_temp_tdt) + (self.enth_rev - (self.spec_heat_transition * phase_change_temp_reverse))
                elif self.enth_new <= self.enthalpy_m and updated_temp_tdt >= prev_temp_td:
                    phase_change_state = phase_melting()
                    self.enth_new = self.get_enthalpy(updated_temp_tdt, self.peak_temp_melting, 
                                                       self.delta_temp_melting_low, self.delta_temp_melting_high)
            elif prev_phase_change_state == phase_melting() and phase_change_state == phase_transition():
                self.enth_new = (self.spec_heat_transition * updated_temp_tdt) + (self.enth_old - (self.spec_heat_transition * prev_temp_td))
                self.enthalpy_m = self.get_enthalpy(updated_temp_tdt, self.peak_temp_melting, 
                                                     self.delta_temp_melting_low, self.delta_temp_melting_high)
                self.enthalpy_f = self.get_enthalpy(updated_temp_tdt, self.peak_temp_freezing, 
                                                     self.delta_temp_freezing_low, self.delta_temp_freezing_high)
                if (self.enth_new < self.enth_old) and (updated_temp_tdt < prev_temp_td):
                    phase_change_state = phase_transition()
                    self.enth_new = (self.spec_heat_transition * updated_temp_tdt) + (self.enth_old - (self.spec_heat_transition * prev_temp_td))
                elif (self.enth_new < self.enthalpy_f) and (self.enth_new > self.enthalpy_m) and (updated_temp_tdt < prev_temp_td):
                    phase_change_state = phase_transition()
                    self.enth_new = (self.spec_heat_transition * updated_temp_tdt) + (self.enth_rev - (self.spec_heat_transition * phase_change_temp_reverse))
                elif (self.enth_new >= self.enthalpy_f) and (updated_temp_tdt <= phase_change_temp_reverse):
                    phase_change_state = phase_transition()
                    self.enth_new = (self.spec_heat_transition * updated_temp_tdt) + (self.enth_rev - (self.spec_heat_transition * phase_change_temp_reverse))
            elif prev_phase_change_state == phase_transition() and phase_change_state == phase_freezing():
                self.enthalpy_m = self.get_enthalpy(updated_temp_tdt, self.peak_temp_melting, 
                                                     self.delta_temp_melting_low, self.delta_temp_melting_high)
                self.enthalpy_f = self.get_enthalpy(updated_temp_tdt, self.peak_temp_freezing, 
                                                     self.delta_temp_freezing_low, self.delta_temp_freezing_high)
                self.enth_rev = self.get_enthalpy(phase_change_temp_reverse, self.peak_temp_freezing, 
                                                   self.delta_temp_freezing_low, self.delta_temp_freezing_high)
                self.enth_new = (self.spec_heat_transition * updated_temp_tdt) + (self.enth_rev - (self.spec_heat_transition * phase_change_temp_reverse))
        
        if not self.phase_change_transition:
            if self.enth_new == self.enth_old:
                cp = self.cp_old
            else:
                cp = self.spec_heat(prev_temp_td, updated_temp_tdt, tc, tau1, tau2, self.enth_old, self.enth_new)
        else:
            cp = self.spec_heat_transition
        
        self.cp_old = cp
        return (cp, phase_change_state)
    
    fn spec_heat(
        self,
        temperature_prev: Float64,
        temperature_current: Float64,
        critical_temperature: Float64,
        tau1: Float64,
        tau2: Float64,
        enthalpy_old: Float64,
        enthalpy_new: Float64,
    ) -> Float64:
        let t = temperature_current
        
        if t < critical_temperature:
            let d_eta1 = -(self.total_latent_heat * (t - critical_temperature) * 
                          exp(-2.0 * fabs(t - critical_temperature) / tau1)) / \
                         (tau1 * fabs(t - critical_temperature))
            let cp1 = self.specific_heat_solid
            return cp1 + d_eta1
        
        if t == critical_temperature:
            return (enthalpy_new - enthalpy_old) / (temperature_current - temperature_prev)
        
        let d_eta2 = (self.total_latent_heat * (t - critical_temperature) * 
                     exp(-2.0 * fabs(t - critical_temperature) / tau2)) / \
                    (tau2 * fabs(t - critical_temperature))
        let cp2 = self.specific_heat_liquid
        return cp2 + d_eta2
    
    fn get_conductivity(self, T: Float64) -> Float64:
        if T < self.peak_temp_melting:
            return self.fully_solid_thermal_conductivity
        if T > self.peak_temp_freezing:
            return self.fully_liquid_thermal_conductivity
        return (self.fully_solid_thermal_conductivity + self.fully_liquid_thermal_conductivity) / 2.0
    
    fn get_density(self, T: Float64) -> Float64:
        if T < self.peak_temp_melting:
            return self.fully_solid_density
        if T > self.peak_temp_freezing:
            return self.fully_liquid_density
        return (self.fully_solid_density + self.fully_liquid_density) / 2.0


struct HysteresisPhaseChangeData:
    var get_hysteresis_models: Bool
    
    fn __init__(inout self):
        self.get_hysteresis_models = True
    
    fn init_constant_state(inout self, state):
        pass
    
    fn init_state(inout self, state):
        pass
    
    fn clear_state(inout self):
        self.get_hysteresis_models = True


fn get_hysteresis_data(state, inout errors_found: Bool) -> Bool:
    let routine_name = "GetHysteresisData"
    
    let s_ip = state.dataInputProcessing.inputProcessor
    let s_mat = state.dataMaterial
    
    let current_module_object = "MaterialProperty:PhaseChangeHysteresis"
    let hysteresis_schema_props = s_ip.getObjectSchemaProps(state, current_module_object)
    let hysteresis_objects = s_ip.epJSON.get(current_module_object)
    let name_field_name = "Name"
    
    if not hysteresis_objects:
        return errors_found
    
    for hysteresis_instance_key in hysteresis_objects.keys():
        let hysteresis_fields = hysteresis_objects[hysteresis_instance_key]
        let material_name = hysteresis_instance_key.upper()
        
        s_ip.markObjectAsUsed(current_module_object, hysteresis_instance_key)
        
        if material_name.is_empty():
            errors_found = True
            continue
        
        let mat_num = 0
        if mat_num == 0:
            errors_found = True
            continue
        
        let mat = s_mat.materials[mat_num]
        
        if mat.group != 0:
            errors_found = True
            continue
        
        if mat.has_pcm:
            errors_found = True
            continue
        
        if mat.has_empd:
            errors_found = True
            continue
        
        if mat.has_hamt:
            errors_found = True
            continue
        
        var mat_pc = MaterialPhaseChange()
        mat_pc.name = mat.name
        mat_pc.group = mat.group
        
        s_mat.materials[mat_num] = mat_pc
        
        mat_pc.total_latent_heat = s_ip.getRealFieldValue(hysteresis_fields, hysteresis_schema_props, 
                                                           "latent_heat_during_the_entire_phase_change_process")
        mat_pc.fully_liquid_thermal_conductivity = s_ip.getRealFieldValue(hysteresis_fields, hysteresis_schema_props, 
                                                                           "liquid_state_thermal_conductivity")
        mat_pc.fully_liquid_density = s_ip.getRealFieldValue(hysteresis_fields, hysteresis_schema_props, 
                                                              "liquid_state_density")
        mat_pc.specific_heat_liquid = s_ip.getRealFieldValue(hysteresis_fields, hysteresis_schema_props, 
                                                              "liquid_state_specific_heat")
        mat_pc.delta_temp_melting_high = s_ip.getRealFieldValue(hysteresis_fields, hysteresis_schema_props, 
                                                                 "high_temperature_difference_of_melting_curve")
        mat_pc.peak_temp_melting = s_ip.getRealFieldValue(hysteresis_fields, hysteresis_schema_props, 
                                                           "peak_melting_temperature")
        mat_pc.delta_temp_melting_low = s_ip.getRealFieldValue(hysteresis_fields, hysteresis_schema_props, 
                                                                "low_temperature_difference_of_melting_curve")
        mat_pc.fully_solid_thermal_conductivity = s_ip.getRealFieldValue(hysteresis_fields, hysteresis_schema_props, 
                                                                          "solid_state_thermal_conductivity")
        mat_pc.fully_solid_density = s_ip.getRealFieldValue(hysteresis_fields, hysteresis_schema_props, 
                                                             "solid_state_density")
        mat_pc.specific_heat_solid = s_ip.getRealFieldValue(hysteresis_fields, hysteresis_schema_props, 
                                                             "solid_state_specific_heat")
        mat_pc.delta_temp_freezing_high = s_ip.getRealFieldValue(hysteresis_fields, hysteresis_schema_props, 
                                                                  "high_temperature_difference_of_freezing_curve")
        mat_pc.peak_temp_freezing = s_ip.getRealFieldValue(hysteresis_fields, hysteresis_schema_props, 
                                                            "peak_freezing_temperature")
        mat_pc.delta_temp_freezing_low = s_ip.getRealFieldValue(hysteresis_fields, hysteresis_schema_props, 
                                                                 "low_temperature_difference_of_freezing_curve")
        mat_pc.spec_heat_transition = (mat_pc.specific_heat_solid + mat_pc.specific_heat_liquid) / 2.0
        mat_pc.cp_old = mat_pc.specific_heat_solid
        mat_pc.has_pcm = True
    
    return errors_found
