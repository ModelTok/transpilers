"""
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
"""
from core import var_info, var_info_invalid, compute_module, SSC_INPUT, SSC_OUTPUT, SSC_MATRIX, SSC_NUMBER, ssc_number_t
from lib_util import matrix_t
from Toolbox import convex_hull, area_polygon, sp_point

# static var_info table
_cm_vtab_layoutarea = [
    #   VARTYPE           DATATYPE         NAME                         LABEL                                          UNITS     META        GROUP          REQUIRED_IF         CONSTRAINTS         UI_HINTS
    var_info(SSC_INPUT,    SSC_MATRIX,      "positions",                 "Positions within calculataed area",          "",       "",         "layoutarea",   "*",                "",                ""),
    # outputs
    var_info(SSC_OUTPUT,   SSC_MATRIX,      "convex_hull",               "Convex hull bounding the region",            "",       "",         "layoutarea",   "*",                "",                ""),
    var_info(SSC_OUTPUT,   SSC_NUMBER,      "area",                      "Area inside the convex hull",                "",       "",         "layoutarea",   "*",                "",                ""),
    var_info_invalid,
]

class cm_layoutarea(compute_module):
    """Layout area calculation module."""
    
    def __init__(self):
        super().__init__()
        self.add_var_info(_cm_vtab_layoutarea)

    def exec(self):
        positions = matrix_t[float64]()
        self.get_matrix("positions", positions)
        var pos_pts = List[sp_point]()
        pos_pts.reserve(positions.nrows())
        for i in range(positions.nrows()):
            pos_pts.append(sp_point())
            pos_pts[-1].x = positions[i, 0]
            pos_pts[-1].y = positions[i, 1]
        var hull = List[sp_point]()
        convex_hull(pos_pts, hull)
        var area = area_polygon(hull)
        self.assign("area", ssc_number_t(area * 0.000247105))  # acres
        var hull_t = self.allocate("convex_hull", hull.size(), 2)
        for i in range(hull.size()):
            hull_t[i * 2] = ssc_number_t(hull[i].x)
            hull_t[i * 2 + 1] = ssc_number_t(hull[i].y)

def get_module_entry():
    return cm_layoutarea()