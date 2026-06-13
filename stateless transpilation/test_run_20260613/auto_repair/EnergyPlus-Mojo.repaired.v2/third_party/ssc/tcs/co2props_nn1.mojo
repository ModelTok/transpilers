from CO2_properties import CO2_state, CO2_TD, CO2_TP, CO2_PH, CO2_PS, CO2_HS, CO2_cond, CO2_visc

struct _property_info:
    var T: Float64
    var Q: Float64
    var P: Float64
    var V: Float64
    var U: Float64
    var H: Float64
    var S: Float64
    var dens: Float64
    var Cv: Float64
    var Cp: Float64
    var cond: Float64
    var visc: Float64
    var ssnd: Float64

alias property_info = _property_info

def co2_TD(T: Float64, D: Float64, inout data: property_info) -> Int:
    var state: CO2_state
    var val = CO2_TD(T, D, state)
    data.T = state.temp
    data.Q = state.qual
    data.P = state.pres
    data.V = 1.0 / state.dens
    data.U = state.inte
    data.H = state.enth
    data.S = state.entr
    data.dens = state.dens
    data.Cv = state.cv
    data.Cp = state.cp
    data.cond = CO2_cond(state.dens, state.temp)
    data.visc = CO2_visc(state.dens, state.temp)
    data.ssnd = state.ssnd
    return val

def co2_TP(T: Float64, P: Float64, inout data: property_info) -> Int:
    var state: CO2_state
    var val = CO2_TP(T, P, state)
    data.T = state.temp
    data.Q = state.qual
    data.P = state.pres
    data.V = 1.0 / state.dens
    data.U = state.inte
    data.H = state.enth
    data.S = state.entr
    data.dens = state.dens
    data.Cv = state.cv
    data.Cp = state.cp
    data.cond = CO2_cond(state.dens, state.temp)
    data.visc = CO2_visc(state.dens, state.temp)
    data.ssnd = state.ssnd
    return val

def co2_PH(P: Float64, H: Float64, inout data: property_info) -> Int:
    var state: CO2_state
    var val = CO2_PH(P, H, state)
    data.T = state.temp
    data.Q = state.qual
    data.P = state.pres
    data.V = 1.0 / state.dens
    data.U = state.inte
    data.H = state.enth
    data.S = state.entr
    data.dens = state.dens
    data.Cv = state.cv
    data.Cp = state.cp
    data.cond = CO2_cond(state.dens, state.temp)
    data.visc = CO2_visc(state.dens, state.temp)
    data.ssnd = state.ssnd
    return val

def co2_PS(P: Float64, S: Float64, inout data: property_info) -> Int:
    var state: CO2_state
    var val = CO2_PS(P, S, state)
    data.T = state.temp
    data.Q = state.qual
    data.P = state.pres
    data.V = 1.0 / state.dens
    data.U = state.inte
    data.H = state.enth
    data.S = state.entr
    data.dens = state.dens
    data.Cv = state.cv
    data.Cp = state.cp
    data.cond = CO2_cond(state.dens, state.temp)
    data.visc = CO2_visc(state.dens, state.temp)
    data.ssnd = state.ssnd
    return val

def co2_HS(H: Float64, S: Float64, inout data: property_info) -> Int:
    var state: CO2_state
    var val = CO2_HS(H, S, state)
    data.T = state.temp
    data.Q = state.qual
    data.P = state.pres
    data.V = 1.0 / state.dens
    data.U = state.inte
    data.H = state.enth
    data.S = state.entr
    data.dens = state.dens
    data.Cv = state.cv
    data.Cp = state.cp
    data.cond = CO2_cond(state.dens, state.temp)
    data.visc = CO2_visc(state.dens, state.temp)
    data.ssnd = state.ssnd
    return val