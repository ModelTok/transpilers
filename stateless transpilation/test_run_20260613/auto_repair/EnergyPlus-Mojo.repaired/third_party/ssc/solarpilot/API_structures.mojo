// File: API_structures.mojo
// Translated from C++ (API_structures.cpp) with faithful 1:1 translation

/**
BSD-3-Clause
Copyright 2019 Alliance for Sustainable Energy, LLC
Redistribution and use in source and binary forms, with or without modification, are permitted provided 
that the following conditions are met :
1.	Redistributions of source code must retain the above copyright notice, this list of conditions 
and the following disclaimer.
2.	Redistributions in binary form must reproduce the above copyright notice, this list of conditions 
and the following disclaimer in the documentation and/or other materials provided with the distribution.
3.	Neither the name of the copyright holder nor the names of its contributors may be used to endorse 
or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, 
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
ARE DISCLAIMED.IN NO EVENT SHALL THE COPYRIGHT HOLDER, CONTRIBUTORS, UNITED STATES GOVERNMENT OR UNITED STATES 
DEPARTMENT OF ENERGY, NOR ANY OF THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, 
OR CONSEQUENTIAL DAMAGES(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT 
OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
// Corresponds to #include <stdio.h> (omitted – not used)
// Corresponds to #include "API_structures.h" (merged)
// Corresponds to #include "exceptions.hpp" (omitted – not used)
// Corresponds to #include "definitions.h" (omitted – not used)

from mod_base import block_t

// Helper struct for anonymous 3‑point structures used in sp_layout::h_position and sp_layout_table::h_position
struct _Anonymous3D:
    var x: Float64
    var y: Float64
    var z: Float64

struct sp_optimize:
    private:
        var _optimization_sim_points: List[List[Float64]]
        var _optimization_objectives: List[Float64]
        var _optimization_fluxes: List[Float64]
    public:
        def getOptimizationSimulationHistory(inout self, inout sim_points: List[List[Float64]], inout obj_values: List[Float64], inout flux_values: List[Float64]):
            /* 
            Return the addresses of the optimization simulation history data, if applicable.
            */
            sim_points = self._optimization_sim_points
            obj_values = self._optimization_objectives
            flux_values = self._optimization_fluxes

        def setOptimizationSimulationHistory(inout self, inout sim_points: List[List[Float64]], inout obj_values: List[Float64], inout flux_values: List[Float64]):
            self._optimization_sim_points = sim_points
            self._optimization_objectives = obj_values
            self._optimization_fluxes = flux_values

struct sp_layout:
    struct h_position:
        var location: _Anonymous3D
        var aimpoint: _Anonymous3D
        var template_number: Int  // 0 based
        var cant_vector: _Anonymous3D  // [optional] Canting aim vector of total magnitude equal to the cant radius
        var focal_length: Float64  // [optional] Heliostat focal length

    var heliostat_positions: List[sp_layout.h_position]

struct sp_optical_table:
    /* 
    Optical table stores whole-field optical efficiency as a function of 
    solar azimuth and zenith angles.
    */
    var is_user_positions: Bool  // user will specify azimuths and zeniths
    var zeniths: List[Float64]
    var azimuths: List[Float64]
    var eff_data: List[List[Float64]]

    def __init__(inout self):
        is_user_positions = false

struct sp_flux_map:
    struct sp_flux_stack:
        var map_name: String
        var xpos: List[Float64]
        var ypos: List[Float64]
        var flux_data: block_t[Float64]

    var flux_surfaces: List[sp_flux_map.sp_flux_stack]

struct sp_flux_table(sp_flux_map):
    /* 
    Flux table stores flux maps for each receiver & receiver surface (if applicable) 
    for the annual set of sun azimuth and zenith angles. 
    */
    var is_user_spacing: Bool  // user will specify data in 'n_flux_days' and 'delta_flux_hours'
    var n_flux_days: Int  // How many days are used to calculate flux maps? (default = 8)
    var delta_flux_hrs: Float64  // How much time (hrs) between each flux map? (default = 1)
    var azimuths: List[Float64]
    var zeniths: List[Float64]
    var efficiency: List[Float64]

    def __init__(inout self):
        is_user_spacing = false

struct sp_layout_table:
    struct h_position:
        var location: _Anonymous3D
        var aimpoint: _Anonymous3D
        var template_number: Int  // 0 based
        var user_optics: Bool  // indicate whether the user will provide a cant/focus vector
        var cant_vector: _Anonymous3D  // [optional] canting aim vector of total magnitude equal to the cant radius
        var focal_length: Float64  // [optional] heliostat focal length

    var positions: List[sp_layout_table.h_position]