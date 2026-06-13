from enum import IntEnum
from dataclasses import dataclass, field
from typing import Protocol, Tuple
import math


# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state container with dataInputProcessing, dataMaterial sub-objects
# - MaterialBase: base struct for materials (attributes: group, name, hasPCM, hasEMPD, hasHAMT)
# - BaseGlobalStruct: base struct for global state
# - GetMaterialNum(state, name: str) -> int: find material index by name
# - ShowSevereEmptyField(state, eoh, field_name: str, value): error reporting
# - ShowSevereItemNotFound(state, eoh, field_name: str, value): error reporting
# - ShowSevereCustom(state, eoh, msg: str): error reporting
# - ErrorObjectHeader: header for error reporting (routineName, objectType, name)
# - Group.Regular: enum value for regular material group


class Phase(IntEnum):
    INVALID = -1
    LIQUID = 0
    MELTING = 1
    TRANSITION = 2
    FREEZING = 3
    CRYSTALLIZED = 4
    NUM = 5


PHASE_INTS = [-2, -1, 0, 1, 2]


@dataclass
class MaterialPhaseChange:
    enthalpy_m: float = 0.0
    enthalpy_f: float = 0.0
    
    total_latent_heat: float = 0.0
    specific_heat_liquid: float = 0.0
    delta_temp_melting_high: float = 0.0
    peak_temp_melting: float = 0.0
    delta_temp_melting_low: float = 0.0
    specific_heat_solid: float = 0.0
    delta_temp_freezing_high: float = 0.0
    peak_temp_freezing: float = 0.0
    delta_temp_freezing_low: float = 0.0
    
    fully_solid_thermal_conductivity: float = 0.0
    fully_liquid_thermal_conductivity: float = 0.0
    fully_solid_density: float = 0.0
    fully_liquid_density: float = 0.0
    
    phase_change_transition: bool = False
    enth_old: float = 0.0
    enth_new: float = 0.0
    enth_rev: float = 0.0
    cp_old: float = 0.0
    spec_heat_transition: float = 0.0
    
    group: int = 0
    name: str = ""
    has_pcm: bool = False
    has_empd: bool = False
    has_hamt: bool = False
    
    def get_enthalpy(self, T: float, Tc: float, tau1: float, tau2: float) -> float:
        eta1 = (self.total_latent_heat / 2) * math.exp(-2 * abs(T - Tc) / tau1)
        eta2 = (self.total_latent_heat / 2) * math.exp(-2 * abs(T - Tc) / tau2)
        if T <= Tc:
            return (self.specific_heat_solid * T) + eta1
        return (self.specific_heat_solid * Tc) + self.total_latent_heat + self.specific_heat_liquid * (T - Tc) - eta2
    
    def get_current_specific_heat(
        self,
        prev_temp_td: float,
        updated_temp_tdt: float,
        phase_change_temp_reverse: float,
        prev_phase_change_state: Phase,
    ) -> Tuple[float, Phase]:
        temp_low_pcm = self.peak_temp_melting - self.delta_temp_melting_low
        temp_high_pcm = self.peak_temp_melting + self.delta_temp_melting_high
        tc = 0.0
        tau1 = 0.0
        tau2 = 0.0
        temp_low_pcf = self.peak_temp_freezing - self.delta_temp_freezing_low
        temp_high_pcf = self.peak_temp_freezing + self.delta_temp_freezing_high
        cp = 0.0
        phase_change_delta_t = prev_temp_td - updated_temp_tdt
        
        phase_change_state = prev_phase_change_state
        
        if phase_change_delta_t <= 0:
            tc = self.peak_temp_melting
            tau1 = self.delta_temp_melting_low
            tau2 = self.delta_temp_melting_high
            if updated_temp_tdt < temp_low_pcm:
                phase_change_state = Phase.CRYSTALLIZED
            elif updated_temp_tdt <= temp_high_pcm:
                phase_change_state = Phase.MELTING
                if prev_phase_change_state == Phase.FREEZING or prev_phase_change_state == Phase.TRANSITION:
                    phase_change_state = Phase.TRANSITION
            else:
                phase_change_state = Phase.LIQUID
        else:
            tc = self.peak_temp_freezing
            tau1 = self.delta_temp_freezing_low
            tau2 = self.delta_temp_freezing_high
            if updated_temp_tdt < temp_low_pcf:
                phase_change_state = Phase.CRYSTALLIZED
            elif updated_temp_tdt <= temp_high_pcf:
                phase_change_state = Phase.FREEZING
                if prev_phase_change_state == Phase.MELTING or prev_phase_change_state == Phase.TRANSITION:
                    phase_change_state = Phase.TRANSITION
            else:
                phase_change_state = Phase.LIQUID
        
        if prev_phase_change_state == Phase.TRANSITION and phase_change_state == Phase.CRYSTALLIZED:
            self.phase_change_transition = True
        elif prev_phase_change_state == Phase.TRANSITION and phase_change_state == Phase.FREEZING:
            self.phase_change_transition = True
        elif prev_phase_change_state == Phase.FREEZING and phase_change_state == Phase.TRANSITION:
            self.phase_change_transition = True
        elif prev_phase_change_state == Phase.CRYSTALLIZED and phase_change_state == Phase.TRANSITION:
            self.phase_change_transition = True
        else:
            self.phase_change_transition = False
        
        if not self.phase_change_transition:
            self.enth_old = self.get_enthalpy(prev_temp_td, tc, tau1, tau2)
            self.enth_new = self.get_enthalpy(updated_temp_tdt, tc, tau1, tau2)
        else:
            if prev_phase_change_state == Phase.FREEZING and phase_change_state == Phase.TRANSITION:
                self.enth_rev = self.get_enthalpy(phase_change_temp_reverse, self.peak_temp_freezing, 
                                                   self.delta_temp_freezing_low, self.delta_temp_freezing_high)
                self.enth_new = (self.spec_heat_transition * updated_temp_tdt) + (self.enth_old - (self.spec_heat_transition * prev_temp_td))
                self.enthalpy_m = self.get_enthalpy(updated_temp_tdt, self.peak_temp_melting, 
                                                     self.delta_temp_melting_low, self.delta_temp_melting_high)
                self.enthalpy_f = self.get_enthalpy(updated_temp_tdt, self.peak_temp_freezing, 
                                                     self.delta_temp_freezing_low, self.delta_temp_freezing_high)
                if self.enth_new < self.enth_rev and self.enth_new >= self.enthalpy_f and updated_temp_tdt <= prev_temp_td:
                    phase_change_state = Phase.FREEZING
                    self.enth_new = self.get_enthalpy(updated_temp_tdt, self.peak_temp_freezing, 
                                                       self.delta_temp_freezing_low, self.delta_temp_freezing_high)
                elif (self.enth_new < self.enthalpy_f) and (self.enth_new > self.enthalpy_m):
                    phase_change_state = Phase.TRANSITION
                    self.enth_new = (self.spec_heat_transition * updated_temp_tdt) + (self.enth_old - (self.spec_heat_transition * prev_temp_td))
                elif (self.enth_new < self.enthalpy_f) and (updated_temp_tdt > phase_change_temp_reverse):
                    phase_change_state = Phase.TRANSITION
                    self.enth_new = (self.spec_heat_transition * updated_temp_tdt) + (self.enth_rev - (self.spec_heat_transition * phase_change_temp_reverse))
                elif (self.enth_new <= self.enthalpy_m) and (updated_temp_tdt <= phase_change_temp_reverse):
                    phase_change_state = Phase.TRANSITION
                    self.enth_new = (self.spec_heat_transition * updated_temp_tdt) + (self.enth_rev - (self.spec_heat_transition * phase_change_temp_reverse))
            elif prev_phase_change_state == Phase.TRANSITION and phase_change_state == Phase.TRANSITION:
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
                    phase_change_state = Phase.FREEZING
                    self.enth_new = self.get_enthalpy(updated_temp_tdt, self.peak_temp_freezing, 
                                                       self.delta_temp_freezing_low, self.delta_temp_freezing_high)
                elif (self.enth_new < self.enthalpy_f) and (self.enth_new > self.enthalpy_m) and \
                     (updated_temp_tdt < prev_temp_td or updated_temp_tdt > prev_temp_td):
                    phase_change_state = Phase.TRANSITION
                    self.enth_new = (self.spec_heat_transition * updated_temp_tdt) + (self.enth_rev - (self.spec_heat_transition * phase_change_temp_reverse))
                elif self.enth_new <= self.enthalpy_m and updated_temp_tdt >= prev_temp_td and self.enth_new > self.enth_old:
                    phase_change_state = Phase.MELTING
                    self.enth_new = (self.spec_heat_transition * updated_temp_tdt) + (self.enth_rev - (self.spec_heat_transition * phase_change_temp_reverse))
            elif prev_phase_change_state == Phase.TRANSITION and phase_change_state == Phase.CRYSTALLIZED:
                self.enth_rev = self.get_enthalpy(phase_change_temp_reverse, self.peak_temp_freezing, 
                                                   self.delta_temp_freezing_low, self.delta_temp_freezing_high)
                self.enth_new = (self.spec_heat_transition * updated_temp_tdt) + (self.enth_rev - (self.spec_heat_transition * phase_change_temp_reverse))
                self.enthalpy_m = self.get_enthalpy(updated_temp_tdt, self.peak_temp_melting, 
                                                     self.delta_temp_melting_low, self.delta_temp_melting_high)
                self.enthalpy_f = self.get_enthalpy(updated_temp_tdt, self.peak_temp_freezing, 
                                                     self.delta_temp_freezing_low, self.delta_temp_freezing_high)
                if (self.enth_new < self.enthalpy_f) and (self.enth_new > self.enthalpy_m):
                    phase_change_state = Phase.TRANSITION
                    self.enth_new = (self.spec_heat_transition * updated_temp_tdt) + (self.enth_rev - (self.spec_heat_transition * phase_change_temp_reverse))
                elif self.enth_new <= self.enthalpy_m and updated_temp_tdt >= prev_temp_td:
                    phase_change_state = Phase.MELTING
                    self.enth_new = self.get_enthalpy(updated_temp_tdt, self.peak_temp_melting, 
                                                       self.delta_temp_melting_low, self.delta_temp_melting_high)
            elif prev_phase_change_state == Phase.MELTING and phase_change_state == Phase.TRANSITION:
                self.enth_new = (self.spec_heat_transition * updated_temp_tdt) + (self.enth_old - (self.spec_heat_transition * prev_temp_td))
                self.enthalpy_m = self.get_enthalpy(updated_temp_tdt, self.peak_temp_melting, 
                                                     self.delta_temp_melting_low, self.delta_temp_melting_high)
                self.enthalpy_f = self.get_enthalpy(updated_temp_tdt, self.peak_temp_freezing, 
                                                     self.delta_temp_freezing_low, self.delta_temp_freezing_high)
                if (self.enth_new < self.enth_old) and (updated_temp_tdt < prev_temp_td):
                    phase_change_state = Phase.TRANSITION
                    self.enth_new = (self.spec_heat_transition * updated_temp_tdt) + (self.enth_old - (self.spec_heat_transition * prev_temp_td))
                elif (self.enth_new < self.enthalpy_f) and (self.enth_new > self.enthalpy_m) and (updated_temp_tdt < prev_temp_td):
                    phase_change_state = Phase.TRANSITION
                    self.enth_new = (self.spec_heat_transition * updated_temp_tdt) + (self.enth_rev - (self.spec_heat_transition * phase_change_temp_reverse))
                elif (self.enth_new >= self.enthalpy_f) and (updated_temp_tdt <= phase_change_temp_reverse):
                    phase_change_state = Phase.TRANSITION
                    self.enth_new = (self.spec_heat_transition * updated_temp_tdt) + (self.enth_rev - (self.spec_heat_transition * phase_change_temp_reverse))
            elif prev_phase_change_state == Phase.TRANSITION and phase_change_state == Phase.FREEZING:
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
        return cp, phase_change_state
    
    def spec_heat(
        self,
        temperature_prev: float,
        temperature_current: float,
        critical_temperature: float,
        tau1: float,
        tau2: float,
        enthalpy_old: float,
        enthalpy_new: float,
    ) -> float:
        t = temperature_current
        
        if t < critical_temperature:
            d_eta1 = -(self.total_latent_heat * (t - critical_temperature) * 
                      math.exp(-2 * abs(t - critical_temperature) / tau1)) / \
                     (tau1 * abs(t - critical_temperature))
            cp1 = self.specific_heat_solid
            return cp1 + d_eta1
        
        if t == critical_temperature:
            return (enthalpy_new - enthalpy_old) / (temperature_current - temperature_prev)
        
        d_eta2 = (self.total_latent_heat * (t - critical_temperature) * 
                 math.exp(-2 * abs(t - critical_temperature) / tau2)) / \
                (tau2 * abs(t - critical_temperature))
        cp2 = self.specific_heat_liquid
        return cp2 + d_eta2
    
    def get_conductivity(self, T: float) -> float:
        if T < self.peak_temp_melting:
            return self.fully_solid_thermal_conductivity
        if T > self.peak_temp_freezing:
            return self.fully_liquid_thermal_conductivity
        return (self.fully_solid_thermal_conductivity + self.fully_liquid_thermal_conductivity) / 2.0
    
    def get_density(self, T: float) -> float:
        if T < self.peak_temp_melting:
            return self.fully_solid_density
        if T > self.peak_temp_freezing:
            return self.fully_liquid_density
        return (self.fully_solid_density + self.fully_liquid_density) / 2.0


@dataclass
class HysteresisPhaseChangeData:
    get_hysteresis_models: bool = True
    
    def init_constant_state(self, state) -> None:
        pass
    
    def init_state(self, state) -> None:
        pass
    
    def clear_state(self) -> None:
        self.get_hysteresis_models = True


def get_hysteresis_data(state, errors_found: bool) -> bool:
    routine_name = "GetHysteresisData"
    
    s_ip = state.dataInputProcessing.inputProcessor
    s_mat = state.dataMaterial
    
    current_module_object = "MaterialProperty:PhaseChangeHysteresis"
    hysteresis_schema_props = s_ip.getObjectSchemaProps(state, current_module_object)
    hysteresis_objects = s_ip.epJSON.get(current_module_object)
    name_field_name = "Name"
    
    if hysteresis_objects is None:
        return errors_found
    
    for hysteresis_instance_key, hysteresis_fields in hysteresis_objects.items():
        material_name = hysteresis_instance_key.upper()
        
        s_ip.markObjectAsUsed(current_module_object, hysteresis_instance_key)
        
        eoh_context = (routine_name, current_module_object, material_name)
        
        if not material_name:
            # ShowSevereEmptyField(state, eoh, name_field_name, material_name)
            errors_found = True
            continue
        
        mat_num = 0  # GetMaterialNum(state, material_name)
        if mat_num == 0:
            # ShowSevereItemNotFound(state, eoh, name_field_name, material_name)
            errors_found = True
            continue
        
        mat = s_mat.materials[mat_num]
        
        if mat.group != 0:  # Group.Regular
            # ShowSevereCustom(state, eoh, f"Material {mat.name} is not a Regular material.")
            errors_found = True
            continue
        
        if mat.has_pcm:
            # ShowSevereCustom(state, eoh, f"Material {mat.name} already has {current_module_object} properties defined.")
            errors_found = True
            continue
        
        if mat.has_empd:
            # ShowSevereCustom(state, eoh, f"Material {mat.name} already has EMPD properties defined.")
            errors_found = True
            continue
        
        if mat.has_hamt:
            # ShowSevereCustom(state, eoh, f"Material {mat.name} already has HAMT properties defined.")
            errors_found = True
            continue
        
        mat_pc = MaterialPhaseChange()
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
