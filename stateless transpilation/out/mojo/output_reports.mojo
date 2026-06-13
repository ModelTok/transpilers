from collections import Dict
from memory import memcpy
from math import min as math_min


@value
struct OutputReportsData:
    var optiondone: Bool
    var lastoption: String

    fn __init__(inout self) -> None:
        self.optiondone = False
        self.lastoption = ""

    fn init_constant_state(inout self, state: EnergyPlusData) -> None:
        pass

    fn init_state(inout self, state: EnergyPlusData) -> None:
        pass

    fn clear_state(inout self) -> None:
        self.optiondone = False
        self.lastoption = ""


fn normalize_name(name: String) -> String:
    var result = name.replace(" ", "_").replace(":", "_")
    return result


fn report_surfaces(inout state: EnergyPlusData) -> None:
    state.dataErrTracking.AskForSurfacesReport = False

    var surf_details: Int = 0
    var surf_vert: Bool = False
    var surf_det: Bool = False
    var dxf_done: Bool = False
    var option1: String = ""
    var option2: String = ""

    var do_report: Bool = False
    state.General.ScanForReports(state, "Surfaces", do_report, "Lines", option1)
    if do_report:
        lines_out(state, option1)

    do_report = False
    state.General.ScanForReports(state, "Surfaces", do_report, "Vertices")
    if do_report:
        surf_details += 1
        surf_vert = True

    do_report = False
    state.General.ScanForReports(state, "Surfaces", do_report, "Details")
    if do_report:
        surf_details += 10
        surf_det = True

    do_report = False
    state.General.ScanForReports(state, "Surfaces", do_report, "DetailsWithVertices")
    if do_report:
        if not surf_det:
            surf_details += 10
            surf_det = True
        if not surf_vert:
            surf_details += 1
            surf_vert = True

    do_report = False
    option1 = ""
    option2 = ""
    state.General.ScanForReports(state, "Surfaces", do_report, "DXF", option1, option2)
    if do_report:
        if option2:
            state.DataSurfaceColors.SetUpSchemeColors(state, option2, "DXF")
        dxf_out(state, option1, option2)
        dxf_done = True

    do_report = False
    option1 = ""
    option2 = ""
    state.General.ScanForReports(state, "Surfaces", do_report, "DXF:WireFrame", option1, option2)
    if do_report:
        if not dxf_done:
            if option2:
                state.DataSurfaceColors.SetUpSchemeColors(state, option2, "DXF")
            dxf_out_wireframe(state, option2)
        else:
            state.General.ShowWarningError(
                state, "ReportSurfaces: DXF output already generated.  DXF:WireFrame will not be generated."
            )

    do_report = False
    option1 = ""
    option2 = ""
    state.General.ScanForReports(state, "Surfaces", do_report, "VRML", option1, option2)
    if do_report:
        vrml_out(state, option1, option2)

    do_report = False
    state.General.ScanForReports(state, "Surfaces", do_report, "CostInfo")
    if do_report:
        cost_info_out(state)

    if surf_det or surf_vert:
        details_for_surfaces(state, surf_details)


fn lines_out(inout state: EnergyPlusData, option: String) -> None:
    var vertex_string: StringRef = "X,Y,Z ==> Vertex"

    if state.dataSurface.TotSurfaces > 0 and not state.dataSurface.Surface:
        return

    if state.dataOutputReports.optiondone:
        state.General.ShowWarningError(
            state,
            "Report of Surfaces/Lines Option has already been completed with option=" + state.dataOutputReports.lastoption,
        )
        state.General.ShowContinueError(state, "..option=\"" + option + "\" will not be done this time.")
        return

    state.dataOutputReports.lastoption = option
    state.dataOutputReports.optiondone = True

    var slnfile = state.files.sln.open(state, "LinesOut", state.files.outputControl.sln)

    if option != "IDF":
        for surf in state.dataSurface.AllSurfaceListReportOrder:
            var this_surface = state.dataSurface.Surface[surf]
            if this_surface.Class == state.DataSurfaces.SurfaceClass.IntMass:
                continue
            if this_surface.Sides == 0:
                continue
            slnfile.write(this_surface.ZoneName + ":" + this_surface.Name + "\n")
            for vert in range(1, this_surface.Sides + 1):
                if vert != this_surface.Sides:
                    slnfile.write(
                        String(this_surface.Vertex(vert).x) + "," +
                        String(this_surface.Vertex(vert).y) + "," +
                        String(this_surface.Vertex(vert).z) + "," +
                        String(this_surface.Vertex(vert + 1).x) + "," +
                        String(this_surface.Vertex(vert + 1).y) + "," +
                        String(this_surface.Vertex(vert + 1).z) + "\n"
                    )
                else:
                    slnfile.write(
                        String(this_surface.Vertex(vert).x) + "," +
                        String(this_surface.Vertex(vert).y) + "," +
                        String(this_surface.Vertex(vert).z) + "," +
                        String(this_surface.Vertex(1).x) + "," +
                        String(this_surface.Vertex(1).y) + "," +
                        String(this_surface.Vertex(1).z) + "\n"
                    )
    else:
        slnfile.write(" Building North Axis = 0\n")
        slnfile.write("GlobalGeometryRules,UpperLeftCorner,CounterClockwise,WorldCoordinates;\n")
        for surf in state.dataSurface.AllSurfaceListReportOrder:
            var this_surface = state.dataSurface.Surface[surf]
            if this_surface.Class == state.DataSurfaces.SurfaceClass.IntMass:
                continue
            if this_surface.Sides == 0:
                continue
            slnfile.write(
                " Surface=" + state.DataSurfaces.cSurfaceClass(this_surface.Class) + ", " +
                "Name=" + this_surface.Name + ", Azimuth=" + String(this_surface.Azimuth) + "\n"
            )
            slnfile.write("  " + String(this_surface.Sides) + ",  !- Number of (X,Y,Z) groups in this surface\n")
            for vert in range(1, this_surface.Sides + 1):
                var opt_comma_semi = "," if vert != this_surface.Sides else ";"
                slnfile.write(
                    "  " + String(this_surface.Vertex(vert).x) + "," +
                    String(this_surface.Vertex(vert).y) + "," +
                    String(this_surface.Vertex(vert).z) +
                    opt_comma_semi + "  !- " + vertex_string + " " + String(vert) + "\n"
                )


fn write_dxf_common(inout state: EnergyPlusData, of: OutputFile, color_scheme: String) -> None:
    var stem_x = InlineArray[Float64, 4](fill=-10.0)
    var stem_y = InlineArray[Float64, 4]()
    stem_y[0] = 3.0
    stem_y[1] = 3.0
    stem_y[2] = 0.0
    stem_y[3] = 0.0

    var stem_z = InlineArray[Float64, 4]()
    stem_z[0] = 0.1
    stem_z[1] = 0.0
    stem_z[2] = 0.0
    stem_z[3] = 0.1

    var head1_x = InlineArray[Float64, 4]()
    head1_x[0] = -10.0
    head1_x[1] = -10.0
    head1_x[2] = -10.5
    head1_x[3] = -10.5

    var head1_y = InlineArray[Float64, 4]()
    head1_y[0] = 3.0
    head1_y[1] = 3.0
    head1_y[2] = 2.133975
    head1_y[3] = 2.133975

    var head1_z = InlineArray[Float64, 4]()
    head1_z[0] = 0.1
    head1_z[1] = 0.0
    head1_z[2] = 0.0
    head1_z[3] = 0.1

    var head2_x = InlineArray[Float64, 4]()
    head2_x[0] = -10.0
    head2_x[1] = -10.0
    head2_x[2] = -9.5
    head2_x[3] = -9.5

    var head2_y = InlineArray[Float64, 4]()
    head2_y[0] = 3.0
    head2_y[1] = 3.0
    head2_y[2] = 2.133975
    head2_y[3] = 2.133975

    var head2_z = InlineArray[Float64, 4]()
    head2_z[0] = 0.1
    head2_z[1] = 0.0
    head2_z[2] = 0.0
    head2_z[3] = 0.1

    var nside1_x = InlineArray[Float64, 4](fill=-10.5)
    var nside1_y = InlineArray[Float64, 4]()
    nside1_y[0] = 4.5
    nside1_y[1] = 4.5
    nside1_y[2] = 3.5
    nside1_y[3] = 3.5

    var nside1_z = InlineArray[Float64, 4]()
    nside1_z[0] = 0.1
    nside1_z[1] = 0.0
    nside1_z[2] = 0.0
    nside1_z[3] = 0.1

    var nside2_x = InlineArray[Float64, 4]()
    nside2_x[0] = -10.5
    nside2_x[1] = -10.5
    nside2_x[2] = -9.5
    nside2_x[3] = -9.5

    var nside2_y = InlineArray[Float64, 4]()
    nside2_y[0] = 4.5
    nside2_y[1] = 4.5
    nside2_y[2] = 3.5
    nside2_y[3] = 3.5

    var nside2_z = InlineArray[Float64, 4]()
    nside2_z[0] = 0.1
    nside2_z[1] = 0.0
    nside2_z[2] = 0.0
    nside2_z[3] = 0.1

    var nside3_x = InlineArray[Float64, 4](fill=-9.5)
    var nside3_y = InlineArray[Float64, 4]()
    nside3_y[0] = 4.5
    nside3_y[1] = 4.5
    nside3_y[2] = 3.5
    nside3_y[3] = 3.5

    var nside3_z = InlineArray[Float64, 4]()
    nside3_z[0] = 0.1
    nside3_z[1] = 0.0
    nside3_z[2] = 0.0
    nside3_z[3] = 0.1

    if not color_scheme:
        of.write("999\nColor Scheme,Default\n")
    else:
        of.write("999\nColor Scheme," + color_scheme + "\n")

    var minx: Float64 = 99999.0
    var miny: Float64 = 99999.0
    for surf in state.dataSurface.AllSurfaceListReportOrder:
        var this_surface = state.dataSurface.Surface[surf]
        if this_surface.Class == state.DataSurfaces.SurfaceClass.IntMass:
            continue
        for vert in range(1, this_surface.Sides + 1):
            minx = math_min(minx, this_surface.Vertex(vert).x)
            miny = math_min(miny, this_surface.Vertex(vert).y)

    for i in range(4):
        stem_x[i] += minx
        stem_y[i] += miny
        head1_x[i] += minx
        head1_y[i] += miny
        head2_x[i] += minx
        head2_y[i] += miny
        nside1_x[i] += minx
        nside1_y[i] += miny
        nside2_x[i] += minx
        nside2_y[i] += miny
        nside3_x[i] += minx
        nside3_y[i] += miny

    var dxf_colorno = state.dataSurfColor.DXFcolorno

    of.write("999\nText - True North\n")
    of.write("  0\nTEXT\n  8\n1\n  6\nContinuous\n 62\n" + String(dxf_colorno[int(state.DataSurfaceColors.ColorNo.Text)]) + "\n 10\n" + String(stem_x[0] - 1.0) + "\n 20\n" + String(stem_y[0]) + "\n 30\n" + String(stem_z[0]) + "\n 40\n .25\n  1\nTrue North\n 41\n 0.0\n  7\nMONOTXT\n210\n0.0\n220\n0.0\n230\n1.0\n")

    of.write("999\nText - Building Title\n")
    of.write("  0\nTEXT\n  8\n1\n  6\nContinuous\n 62\n" + String(dxf_colorno[int(state.DataSurfaceColors.ColorNo.Text)]) + "\n 10\n" + String(stem_x[0] - 4.0) + "\n 20\n" + String(stem_y[0] - 4.0) + "\n 30\n" + String(stem_z[0]) + "\n 40\n .4\n  1\nBuilding - " + state.dataHeatBal.BuildingName + "\n 41\n 0.0\n  7\nMONOTXT\n210\n0.0\n220\n0.0\n230\n1.0\n")

    of.write("999\nNorth Arrow Stem\n")
    of.write("  0\n3DFACE\n  8\n1\n 62\n" + String(dxf_colorno[int(state.DataSurfaceColors.ColorNo.Text)]) + "\n 10\n" + String(stem_x[0]) + "\n 20\n" + String(stem_y[0]) + "\n 30\n" + String(stem_z[0]) + "\n 11\n" + String(stem_x[1]) + "\n 21\n" + String(stem_y[1]) + "\n 31\n" + String(stem_z[1]) + "\n 12\n" + String(stem_x[2]) + "\n 22\n" + String(stem_y[2]) + "\n 32\n" + String(stem_z[2]) + "\n 13\n" + String(stem_x[3]) + "\n 23\n" + String(stem_y[3]) + "\n 33\n" + String(stem_z[3]) + "\n")

    of.write("999\nNorth Arrow Head 1\n")
    of.write("  0\n3DFACE\n  8\n1\n 62\n" + String(dxf_colorno[int(state.DataSurfaceColors.ColorNo.Text)]) + "\n 10\n" + String(head1_x[0]) + "\n 20\n" + String(head1_y[0]) + "\n 30\n" + String(head1_z[0]) + "\n 11\n" + String(head1_x[1]) + "\n 21\n" + String(head1_y[1]) + "\n 31\n" + String(head1_z[1]) + "\n 12\n" + String(head1_x[2]) + "\n 22\n" + String(head1_y[2]) + "\n 32\n" + String(head1_z[2]) + "\n 13\n" + String(head1_x[3]) + "\n 23\n" + String(head1_y[3]) + "\n 33\n" + String(head1_z[3]) + "\n")

    of.write("999\nNorth Arrow Head 2\n")
    of.write("  0\n3DFACE\n  8\n1\n 62\n" + String(dxf_colorno[int(state.DataSurfaceColors.ColorNo.Text)]) + "\n 10\n" + String(head2_x[0]) + "\n 20\n" + String(head2_y[0]) + "\n 30\n" + String(head2_z[0]) + "\n 11\n" + String(head2_x[1]) + "\n 21\n" + String(head2_y[1]) + "\n 31\n" + String(head2_z[1]) + "\n 12\n" + String(head2_x[2]) + "\n 22\n" + String(head2_y[2]) + "\n 32\n" + String(head2_z[2]) + "\n 13\n" + String(head2_x[3]) + "\n 23\n" + String(head2_y[3]) + "\n 33\n" + String(head2_z[3]) + "\n")

    of.write("999\nNorth Arrow Side 1\n")
    of.write("  0\n3DFACE\n  8\n1\n 62\n" + String(dxf_colorno[int(state.DataSurfaceColors.ColorNo.Text)]) + "\n 10\n" + String(nside1_x[0]) + "\n 20\n" + String(nside1_y[0]) + "\n 30\n" + String(nside1_z[0]) + "\n 11\n" + String(nside1_x[1]) + "\n 21\n" + String(nside1_y[1]) + "\n 31\n" + String(nside1_z[1]) + "\n 12\n" + String(nside1_x[2]) + "\n 22\n" + String(nside1_y[2]) + "\n 32\n" + String(nside1_z[2]) + "\n 13\n" + String(nside1_x[3]) + "\n 23\n" + String(nside1_y[3]) + "\n 33\n" + String(nside1_z[3]) + "\n")

    of.write("999\nNorth Arrow Side 2\n")
    of.write("  0\n3DFACE\n  8\n1\n 62\n" + String(dxf_colorno[int(state.DataSurfaceColors.ColorNo.Text)]) + "\n 10\n" + String(nside2_x[0]) + "\n 20\n" + String(nside2_y[0]) + "\n 30\n" + String(nside2_z[0]) + "\n 11\n" + String(nside2_x[1]) + "\n 21\n" + String(nside2_y[1]) + "\n 31\n" + String(nside2_z[1]) + "\n 12\n" + String(nside2_x[2]) + "\n 22\n" + String(nside2_y[2]) + "\n 32\n" + String(nside2_z[2]) + "\n 13\n" + String(nside2_x[3]) + "\n 23\n" + String(nside2_y[3]) + "\n 33\n" + String(nside2_z[3]) + "\n")

    of.write("999\nNorth Arrow Side 3\n")
    of.write("  0\n3DFACE\n  8\n1\n 62\n" + String(dxf_colorno[int(state.DataSurfaceColors.ColorNo.Text)]) + "\n 10\n" + String(nside3_x[0]) + "\n 20\n" + String(nside3_y[0]) + "\n 30\n" + String(nside3_z[0]) + "\n 11\n" + String(nside3_x[1]) + "\n 21\n" + String(nside3_y[1]) + "\n 31\n" + String(nside3_z[1]) + "\n 12\n" + String(nside3_x[2]) + "\n 22\n" + String(nside3_y[2]) + "\n 32\n" + String(nside3_z[2]) + "\n 13\n" + String(nside3_x[3]) + "\n 23\n" + String(nside3_y[3]) + "\n 33\n" + String(nside3_z[3]) + "\n")

    of.write("999\nZone Names\n")

    for zones in range(1, state.dataGlobal.NumOfZones + 1):
        of.write("999\nZone=" + String(zones) + ":" + normalize_name(state.dataHeatBal.Zone(zones).Name) + "\n")


fn dxf_daylighting_reference_points(inout state: EnergyPlusData, of: OutputFile) -> None:
    if len(state.dataDayltg.DaylRefPt) > 0:
        for daylight_ctrl_num in range(1, len(state.dataDayltg.daylightControl) + 1):
            var this_daylight_control = state.dataDayltg.daylightControl(daylight_ctrl_num)
            var cur_colorno = state.DataSurfaceColors.ColorNo.DaylSensor1
            var ref_pt_type = ""
            if this_daylight_control.DaylightMethod == state.Dayltg.DaylightingMethod.DElight:
                ref_pt_type = "DEDayRefPt"
            elif this_daylight_control.DaylightMethod == state.Dayltg.DaylightingMethod.SplitFlux:
                ref_pt_type = "DayRefPt"

            for ref_pt in this_daylight_control.refPts:
                of.write("999\n" + this_daylight_control.ZoneName + ":" + ref_pt_type + ":" + state.dataDayltg.DaylRefPt(ref_pt.num).Name + "\n")
                of.write("  0\nCIRCLE\n  8\n" + normalize_name(this_daylight_control.ZoneName) + "\n 62\n" + String(state.dataSurfColor.DXFcolorno[int(cur_colorno)]) + "\n 10\n" + String(ref_pt.absCoords.x) + "\n 20\n" + String(ref_pt.absCoords.y) + "\n 30\n" + String(ref_pt.absCoords.z) + "\n 40\n0.2\n")
                cur_colorno = state.DataSurfaceColors.ColorNo.DaylSensor2


fn dxf_out(inout state: EnergyPlusData, polygon_action: String, color_scheme: String) -> None:
    var triangulate_face: Bool = False
    var regular_polyline: Bool = False
    var thick_polyline: Bool = False
    var polyline_width: String = " 0.55"

    if polygon_action in ("TRIANGULATE3DFACE", "TRIANGULATE") or not polygon_action:
        triangulate_face = True
        regular_polyline = False
        thick_polyline = False
    elif polygon_action == "THICKPOLYLINE":
        thick_polyline = True
        regular_polyline = False
        triangulate_face = False
    elif polygon_action == "REGULARPOLYLINE":
        regular_polyline = True
        triangulate_face = False
        thick_polyline = False
        polyline_width = " 0"
    else:
        state.General.ShowWarningError(state, "DXFOut: Illegal key specified for Surfaces with > 4 sides=" + polygon_action)
        state.General.ShowContinueError(state, "\"ThickPolyline\", \"RegularPolyline\", \"Triangulate3DFace\".")
        state.General.ShowContinueError(state, "\"Triangulate3DFace\" will be used for any surfaces with > 4 sides.")
        triangulate_face = True
        regular_polyline = False
        thick_polyline = False

    if state.dataSurface.TotSurfaces > 0 and not state.dataSurface.Surface:
        return

    var dxffile = state.files.dxf.open(state, "DXFOut", state.files.outputControl.dxf)

    dxffile.write("  0\nSECTION\n  2\nENTITIES\n")
    dxffile.write("999\nDXF created from EnergyPlus\n")
    dxffile.write("999\nProgram Version," + state.dataStrGlobals.VerStringVar + "\n")

    if not polygon_action:
        dxffile.write("999\nPolygon Action,Triangulate3DFace\n")
    else:
        dxffile.write("999\nPolygon Action," + polygon_action + "\n")

    write_dxf_common(state, dxffile, color_scheme)
    var dxf_colorno = state.dataSurfColor.DXFcolorno
    var color_index = state.DataSurfaceColors.ColorNo.ShdDetFix

    for surf in state.dataSurface.AllSurfaceListReportOrder:
        var shade_type: String = ""
        var this_surface = state.dataSurface.Surface[surf]

        if this_surface.HeatTransSurf:
            continue
        if this_surface.Class == state.DataSurfaces.SurfaceClass.Shading:
            continue
        if this_surface.Sides == 0:
            continue
        if this_surface.Class == state.DataSurfaces.SurfaceClass.Detached_F:
            color_index = state.DataSurfaceColors.ColorNo.ShdDetFix
        if this_surface.Class == state.DataSurfaces.SurfaceClass.Detached_B:
            color_index = state.DataSurfaceColors.ColorNo.ShdDetBldg
        if state.dataSurface.SurfIsPV(surf):
            color_index = state.DataSurfaceColors.ColorNo.PV
        if this_surface.Class == state.DataSurfaces.SurfaceClass.Detached_F:
            shade_type = "Fixed Shading"
            dxffile.write("999\nFixed Shading:" + this_surface.Name + "\n")
        elif this_surface.Class == state.DataSurfaces.SurfaceClass.Detached_B:
            shade_type = "Building Shading"
            dxffile.write("999\nBuilding Shading:" + this_surface.Name + "\n")

        if this_surface.Sides <= 4:
            dxffile.write("  0\n3DFACE\n  8\n" + shade_type + "\n 62\n" + String(dxf_colorno[int(color_index)]) + "\n")
            dxffile.write(" 10\n" + String(this_surface.Vertex(1).x) + "\n 20\n" + String(this_surface.Vertex(1).y) + "\n 30\n" + String(this_surface.Vertex(1).z) + "\n")
            dxffile.write(" 11\n" + String(this_surface.Vertex(2).x) + "\n 21\n" + String(this_surface.Vertex(2).y) + "\n 31\n" + String(this_surface.Vertex(2).z) + "\n")
            dxffile.write(" 12\n" + String(this_surface.Vertex(3).x) + "\n 22\n" + String(this_surface.Vertex(3).y) + "\n 32\n" + String(this_surface.Vertex(3).z) + "\n")
            if this_surface.Sides == 3:
                dxffile.write(" 13\n" + String(this_surface.Vertex(3).x) + "\n 23\n" + String(this_surface.Vertex(3).y) + "\n 33\n" + String(this_surface.Vertex(3).z) + "\n")
            else:
                dxffile.write(" 13\n" + String(this_surface.Vertex(4).x) + "\n 23\n" + String(this_surface.Vertex(4).y) + "\n 33\n" + String(this_surface.Vertex(4).z) + "\n")

    for zones in range(1, state.dataGlobal.NumOfZones + 1):
        var temp_zone_name = normalize_name(state.dataHeatBal.Zone(zones).Name)

        for surf in state.dataSurface.AllSurfaceListReportOrder:
            var this_surface = state.dataSurface.Surface[surf]
            if this_surface.Zone != zones:
                continue
            if this_surface.Sides == 0:
                continue
            if this_surface.Class == state.DataSurfaces.SurfaceClass.IntMass:
                continue
            if this_surface.Class == state.DataSurfaces.SurfaceClass.Wall:
                color_index = state.DataSurfaceColors.ColorNo.Wall
            if this_surface.Class == state.DataSurfaces.SurfaceClass.Roof:
                color_index = state.DataSurfaceColors.ColorNo.Roof
            if this_surface.Class == state.DataSurfaces.SurfaceClass.Floor:
                color_index = state.DataSurfaceColors.ColorNo.Floor
            if this_surface.Class == state.DataSurfaces.SurfaceClass.Door:
                color_index = state.DataSurfaceColors.ColorNo.Door
            if this_surface.Class == state.DataSurfaces.SurfaceClass.Window:
                if this_surface.OriginalClass == state.DataSurfaces.SurfaceClass.Window:
                    color_index = state.DataSurfaceColors.ColorNo.Window
                if this_surface.OriginalClass == state.DataSurfaces.SurfaceClass.GlassDoor:
                    color_index = state.DataSurfaceColors.ColorNo.GlassDoor
                if this_surface.OriginalClass == state.DataSurfaces.SurfaceClass.TDD_Dome:
                    color_index = state.DataSurfaceColors.ColorNo.TDDDome
                if this_surface.OriginalClass == state.DataSurfaces.SurfaceClass.TDD_Diffuser:
                    color_index = state.DataSurfaceColors.ColorNo.TDDDiffuser
            if state.dataSurface.SurfIsPV(surf):
                color_index = state.DataSurfaceColors.ColorNo.PV

            dxffile.write("999\n" + this_surface.ZoneName + ":" + this_surface.Name + "\n")
            if this_surface.Sides <= 4:
                dxffile.write("  0\n3DFACE\n  8\n" + temp_zone_name + "\n 62\n" + String(dxf_colorno[int(color_index)]) + "\n")
                dxffile.write(" 10\n" + String(this_surface.Vertex(1).x) + "\n 20\n" + String(this_surface.Vertex(1).y) + "\n 30\n" + String(this_surface.Vertex(1).z) + "\n")
                dxffile.write(" 11\n" + String(this_surface.Vertex(2).x) + "\n 21\n" + String(this_surface.Vertex(2).y) + "\n 31\n" + String(this_surface.Vertex(2).z) + "\n")
                dxffile.write(" 12\n" + String(this_surface.Vertex(3).x) + "\n 22\n" + String(this_surface.Vertex(3).y) + "\n 32\n" + String(this_surface.Vertex(3).z) + "\n")
                if this_surface.Sides == 3:
                    dxffile.write(" 13\n" + String(this_surface.Vertex(3).x) + "\n 23\n" + String(this_surface.Vertex(3).y) + "\n 33\n" + String(this_surface.Vertex(3).z) + "\n")
                else:
                    dxffile.write(" 13\n" + String(this_surface.Vertex(4).x) + "\n 23\n" + String(this_surface.Vertex(4).y) + "\n 33\n" + String(this_surface.Vertex(4).z) + "\n")

    dxf_daylighting_reference_points(state, dxffile)

    for zones in range(1, state.dataGlobal.NumOfZones + 1):
        var cur_color_no = state.DataSurfaceColors.ColorNo.DaylSensor1

        for illum_map in state.dataDayltg.illumMaps:
            if illum_map.zoneIndex != zones:
                continue
            var num_ref_pt: Int = 0
            for ref_pt in illum_map.refPts:
                dxffile.write("999\n" + state.dataHeatBal.Zone(zones).Name + ":MapRefPt:" + String(num_ref_pt + 1) + "\n")
                num_ref_pt += 1
                dxffile.write("  0\nCIRCLE\n  8\n" + normalize_name(state.dataHeatBal.Zone(zones).Name) + "\n 62\n" + String(dxf_colorno[int(cur_color_no)]) + "\n 10\n" + String(ref_pt.absCoords.x) + "\n 20\n" + String(ref_pt.absCoords.y) + "\n 30\n" + String(ref_pt.absCoords.z) + "\n 40\n0.05\n")

    dxffile.write("  0\nENDSEC\n  0\nEOF\n")


fn dxf_out_wireframe(inout state: EnergyPlusData, color_scheme: String) -> None:
    var polyline_width: String = " 0.55"

    if state.dataSurface.TotSurfaces > 0 and not state.dataSurface.Surface:
        return

    var dxffile = state.files.dxf.open(state, "DXFOutWireFrame", state.files.outputControl.dxf)

    dxffile.write("  0\nSECTION\n  2\nENTITIES\n")
    dxffile.write("999\nDXF created from EnergyPlus\n")
    dxffile.write("999\nProgram Version," + state.dataStrGlobals.VerStringVar + "\n")
    dxffile.write("999\nDXF using Wireframe  \n")

    write_dxf_common(state, dxffile, color_scheme)

    var surfcount: Int = 0
    var color_index = state.DataSurfaceColors.ColorNo.Invalid
    for surf in state.dataSurface.AllSurfaceListReportOrder:
        var shade_type: String = ""
        var this_surface = state.dataSurface.Surface[surf]
        if this_surface.HeatTransSurf:
            continue
        if this_surface.Class == state.DataSurfaces.SurfaceClass.Shading:
            continue
        if this_surface.Class == state.DataSurfaces.SurfaceClass.Detached_F:
            color_index = state.DataSurfaceColors.ColorNo.ShdDetFix
        if this_surface.Class == state.DataSurfaces.SurfaceClass.Detached_B:
            color_index = state.DataSurfaceColors.ColorNo.ShdDetBldg
        if state.dataSurface.SurfIsPV(surf):
            color_index = state.DataSurfaceColors.ColorNo.PV
        if this_surface.Class == state.DataSurfaces.SurfaceClass.Detached_F:
            shade_type = "Fixed Shading"
            dxffile.write("999\nFixed Shading:" + this_surface.Name + "\n")
        elif this_surface.Class == state.DataSurfaces.SurfaceClass.Detached_B:
            shade_type = "Building Shading"
            dxffile.write("999\nBuilding Shading:" + this_surface.Name + "\n")
        surfcount += 1
        shade_type = shade_type + "_" + String(surfcount)
        var minz: Float64 = 99999.0
        for vert in range(1, this_surface.Sides + 1):
            minz = math_min(minz, this_surface.Vertex(vert).z)

        dxffile.write("  0\nPOLYLINE\n  8\n" + shade_type + "\n 62\n" + String(state.dataSurfColor.DXFcolorno[int(color_index)]) + "\n 66\n  1\n 10\n 0.0\n 20\n 0.0\n 30\n" + String(minz) + "\n 70\n   9\n 40\n" + polyline_width + "\n 41\n" + polyline_width + "\n")
        for vert in range(1, this_surface.Sides + 1):
            dxffile.write("  0\nVERTEX\n  8\n" + shade_type + "\n 10\n" + String(this_surface.Vertex(vert).x) + "\n 20\n" + String(this_surface.Vertex(vert).y) + "\n 30\n" + String(this_surface.Vertex(vert).z) + "\n")
        dxffile.write("  0\nSEQEND\n  8\n" + shade_type + "\n")

    for zones in range(1, state.dataGlobal.NumOfZones + 1):
        var save_zone_name = normalize_name(state.dataHeatBal.Zone(zones).Name)

        surfcount = 0
        for surf in state.dataSurface.AllSurfaceListReportOrder:
            var this_surface = state.dataSurface.Surface[surf]
            if this_surface.Zone != zones:
                continue
            if this_surface.Class == state.DataSurfaces.SurfaceClass.IntMass:
                continue
            if this_surface.Class == state.DataSurfaces.SurfaceClass.Wall:
                color_index = state.DataSurfaceColors.ColorNo.Wall
            if this_surface.Class == state.DataSurfaces.SurfaceClass.Roof:
                color_index = state.DataSurfaceColors.ColorNo.Roof
            if this_surface.Class == state.DataSurfaces.SurfaceClass.Floor:
                color_index = state.DataSurfaceColors.ColorNo.Floor
            if this_surface.Class == state.DataSurfaces.SurfaceClass.Door:
                color_index = state.DataSurfaceColors.ColorNo.Door
            if this_surface.Class == state.DataSurfaces.SurfaceClass.Window:
                if this_surface.OriginalClass == state.DataSurfaces.SurfaceClass.Window:
                    color_index = state.DataSurfaceColors.ColorNo.Window
                if this_surface.OriginalClass == state.DataSurfaces.SurfaceClass.GlassDoor:
                    color_index = state.DataSurfaceColors.ColorNo.GlassDoor
                if this_surface.OriginalClass == state.DataSurfaces.SurfaceClass.TDD_Dome:
                    color_index = state.DataSurfaceColors.ColorNo.TDDDome
                if this_surface.OriginalClass == state.DataSurfaces.SurfaceClass.TDD_Diffuser:
                    color_index = state.DataSurfaceColors.ColorNo.TDDDiffuser
            if state.dataSurface.SurfIsPV(surf):
                color_index = state.DataSurfaceColors.ColorNo.PV
            surfcount += 1

            dxffile.write("999\n" + this_surface.ZoneName + ":" + this_surface.Name + "\n")
            var temp_zone_name = save_zone_name + "_" + String(surfcount)
            var minz: Float64 = 99999.0
            for vert in range(1, this_surface.Sides + 1):
                minz = math_min(minz, this_surface.Vertex(vert).z)

            dxffile.write("  0\nPOLYLINE\n  8\n" + temp_zone_name + "\n 62\n" + String(state.dataSurfColor.DXFcolorno[int(color_index)]) + "\n 66\n  1\n 10\n 0.0\n 20\n 0.0\n 30\n" + String(minz) + "\n 70\n   9\n 40\n" + polyline_width + "\n 41\n" + polyline_width + "\n")
            for vert in range(1, this_surface.Sides + 1):
                dxffile.write("  0\nVERTEX\n  8\n" + temp_zone_name + "\n 10\n" + String(this_surface.Vertex(vert).x) + "\n 20\n" + String(this_surface.Vertex(vert).y) + "\n 30\n" + String(this_surface.Vertex(vert).z) + "\n")
            dxffile.write("  0\nSEQEND\n  8\n" + temp_zone_name + "\n")

        surfcount = 0
        for surf in state.dataSurface.AllSurfaceListReportOrder:
            var this_surface = state.dataSurface.Surface[surf]
            if this_surface.Class != state.DataSurfaces.SurfaceClass.Shading:
                continue
            if this_surface.ZoneName != state.dataHeatBal.Zone(zones).Name:
                continue
            color_index = state.DataSurfaceColors.ColorNo.ShdAtt
            if state.dataSurface.SurfIsPV(surf):
                color_index = state.DataSurfaceColors.ColorNo.PV
            surfcount += 1

            dxffile.write("999\n" + this_surface.ZoneName + ":" + this_surface.Name + "\n")
            var temp_zone_name = save_zone_name + "_" + String(surfcount)
            var minz: Float64 = 99999.0
            for vert in range(1, this_surface.Sides + 1):
                minz = math_min(minz, this_surface.Vertex(vert).z)

            dxffile.write("  0\nPOLYLINE\n  8\n" + temp_zone_name + "\n 62\n" + String(state.dataSurfColor.DXFcolorno[int(color_index)]) + "\n 66\n  1\n 10\n 0.0\n 20\n 0.0\n 30\n" + String(minz) + "\n 70\n   9\n 40\n" + polyline_width + "\n 41\n" + polyline_width + "\n")
            for vert in range(1, this_surface.Sides + 1):
                dxffile.write("  0\nVERTEX\n  8\n" + temp_zone_name + "\n 10\n" + String(this_surface.Vertex(vert).x) + "\n 20\n" + String(this_surface.Vertex(vert).y) + "\n 30\n" + String(this_surface.Vertex(vert).z) + "\n")
            dxffile.write("  0\nSEQEND\n  8\n" + temp_zone_name + "\n")

    dxf_daylighting_reference_points(state, dxffile)

    dxffile.write("  0\nENDSEC\n  0\nEOF\n")


fn details_for_surfaces(inout state: EnergyPlusData, rpt_type: Int) -> None:
    if state.dataSurface.TotSurfaces > 0 and not state.dataSurface.Surface:
        return

    var eio_output: String = ""

    if rpt_type == 10:
        eio_output += "! <Zone Surfaces>,Zone Name,# Surfaces\n"
        eio_output += "! <Shading Surfaces>,Number of Shading Surfaces,# Surfaces\n"
        eio_output += "! <HeatTransfer Surface>,Surface Name,Surface Class,Base Surface,Heat Transfer Algorithm,Construction,Nominal U (w/o film coefs) {W/m2-K},Nominal U (with film coefs) {W/m2-K},Solar Diffusing,Area (Net) {m2},Area (Gross) {m2},Area (Sunlit Calc) {m2},Azimuth {deg},Tilt {deg},~Width {m},~Height {m},Reveal {m},ExtBoundCondition,ExtConvCoeffCalc,IntConvCoeffCalc,SunExposure,WindExposure,ViewFactorToGround,ViewFactorToSky,ViewFactorToGround-IR,ViewFactorToSky-IR,#Sides\n"
        eio_output += "! <Shading Surface>,Surface Name,Surface Class,Base Surface,Heat Transfer Algorithm,Transmittance Schedule,Min Schedule Value,Max Schedule Value,Solar Diffusing,Area (Net) {m2},Area (Gross) {m2},Area (Sunlit Calc) {m2},Azimuth {deg},Tilt {deg},~Width {m},~Height {m},Reveal {m},ExtBoundCondition,ExtConvCoeffCalc,IntConvCoeffCalc,SunExposure,WindExposure,ViewFactorToGround,ViewFactorToSky,ViewFactorToGround-IR,ViewFactorToSky-IR,#Sides\n"
        eio_output += "! <Frame/Divider Surface>,Surface Name,Surface Class,Base Surface,Heat Transfer Algorithm,Construction,Nominal U (w/o film coefs) {W/m2-K},Nominal U (with film coefs) {W/m2-K},Solar Diffusing,Area (Net) {m2},Area (Gross) {m2},Area (Sunlit Calc) {m2},Azimuth {deg},Tilt {deg},~Width {m},~Height {m},Reveal {m}\n"

    var surf2: Int = 0
    for surf in state.dataSurface.AllSurfaceListReportOrder:
        surf2 = surf
        var this_surface = state.dataSurface.Surface[surf]
        if this_surface.Zone != 0:
            break

    if (surf2 - 1) > 0:
        eio_output += "Shading Surfaces,Number of Shading Surfaces," + String(surf2 - 1) + "\n"
        for surf in state.dataSurface.AllSurfaceListReportOrder:
            var this_surface = state.dataSurface.Surface[surf]
            if this_surface.Zone != 0:
                break
            var algo_name = "None"
            eio_output += "Shading Surface," + this_surface.Name + "," + state.DataSurfaces.cSurfaceClass(this_surface.Class) + "," + this_surface.BaseSurfName + "," + algo_name + ",,,,,,,,,,,,,,,,,,,,,\n"

    for zone_num in range(1, state.dataGlobal.NumOfZones + 1):
        eio_output += "Zone Surfaces," + state.dataHeatBal.Zone(zone_num).Name + "," + String(state.dataHeatBal.Zone(zone_num).AllSurfaceLast - state.dataHeatBal.Zone(zone_num).AllSurfaceFirst + 1) + "\n"
        for surf in state.dataSurface.AllSurfaceListReportOrder:
            var this_surface = state.dataSurface.Surface[surf]
            if this_surface.Zone != zone_num:
                continue
            if rpt_type == 10 or rpt_type == 11:
                var base_surf_name = ""
                if this_surface.BaseSurf == surf:
                    base_surf_name = ""
                else:
                    base_surf_name = this_surface.BaseSurfName

                var algo_name = state.DataSurfaces.HeatTransAlgoStrs[int(this_surface.HeatTransferAlgorithm)]
                eio_output += "HeatTransfer Surface," + this_surface.Name + "," + state.DataSurfaces.cSurfaceClass(this_surface.Class) + "," + base_surf_name + "," + algo_name + ",\n"

    state.files.eio.write(eio_output)


fn cost_info_out(inout state: EnergyPlusData) -> None:
    if state.dataSurface.TotSurfaces > 0 and not state.dataSurface.Surface:
        return

    var unique_surf = InlineArray[Bool, 1024]()
    for i in range(state.dataSurface.TotSurfaces):
        unique_surf[i] = True

    for surf in state.dataSurface.AllSurfaceListReportOrder:
        var this_surface = state.dataSurface.Surface[surf]
        if this_surface.ExtBoundCond > 0:
            if this_surface.ExtBoundCond < surf:
                unique_surf[surf - 1] = False
        if this_surface.Construction == 0:
            unique_surf[surf - 1] = False

    var scifile = state.files.sci.open(state, "CostInfoOut", state.files.outputControl.sci)

    var num_unique: Int = 0
    for i in range(state.dataSurface.TotSurfaces):
        if unique_surf[i]:
            num_unique += 1

    scifile.write(String(state.dataSurface.TotSurfaces) + "  " + String(num_unique) + "\n")
    scifile.write(" data for surfaces useful for cost information\n")
    scifile.write(" Number, Name, Construction, class, area, grossarea\n")

    for surf in state.dataSurface.AllSurfaceListReportOrder:
        if not unique_surf[surf - 1]:
            continue
        var this_surface = state.dataSurface.Surface[surf]
        if this_surface.Construction != 0:
            scifile.write(
                String(surf) + "," + this_surface.Name + "," +
                state.dataConstruction.Construct(this_surface.Construction).Name + "," +
                state.DataSurfaces.cSurfaceClass(this_surface.Class) + "," +
                String(this_surface.Area) + "," + String(this_surface.GrossArea) + "\n"
            )


fn vrml_out(inout state: EnergyPlusData, polygon_action: String, color_scheme: String) -> None:
    var triangulate_face: Bool = False
    var regular_polyline: Bool = False
    var thick_polyline: Bool = False
    var polyline_width: String = " 0.55"

    if polygon_action in ("TRIANGULATE3DFACE", "TRIANGULATE"):
        triangulate_face = True
    elif polygon_action in ("THICKPOLYLINE", "") or not polygon_action:
        thick_polyline = True
    elif polygon_action == "REGULARPOLYLINE":
        regular_polyline = True
        polyline_width = " 0"
    else:
        state.General.ShowWarningError(state, "VRMLOut: Illegal key specified for Surfaces with > 4 sides=" + polygon_action)
        state.General.ShowContinueError(state, "\"TRIANGULATE 3DFACE\" will be used for any surfaces with > 4 sides.")
        triangulate_face = True

    if state.dataSurface.TotSurfaces > 0 and not state.dataSurface.Surface:
        return

    var wrlfile = state.files.wrl.open(state, "VRMLOut", state.files.outputControl.wrl)

    wrlfile.write("#VRML V2.0 utf8\n")

    var color_label = color_scheme if color_scheme else "Default"
    wrlfile.write("WorldInfo {\n   title \"Building - " + state.dataHeatBal.BuildingName + "\"\n   info [\"EnergyPlus Program Version " + state.dataStrGlobals.VerStringVar + "\"]\n   info [\"Surface Color Scheme " + color_label + "\"]\n}\n")

    wrlfile.write("# Zone Names\n")
    for zones in range(1, state.dataGlobal.NumOfZones + 1):
        wrlfile.write("# Zone=" + String(zones) + ":" + normalize_name(state.dataHeatBal.Zone(zones).Name) + "\n")

    wrlfile.write("Shape {\nappearance DEF FLOOR Appearance {\nmaterial Material { diffuseColor 0.502 0.502 0.502 }\n}\n}\n")
    wrlfile.write("Shape {\nappearance DEF ROOF Appearance {\nmaterial Material { diffuseColor 1 1 0 }\n}\n}\n")
    wrlfile.write("Shape {\nappearance DEF WALL Appearance {\nmaterial Material { diffuseColor 0 1 0 }\n}\n}\n")
    wrlfile.write("Shape {\nappearance DEF WINDOW Appearance {\nmaterial Material { diffuseColor 0 1 1 }\n}\n}\n")
    wrlfile.write("Shape {\nappearance DEF DOOR Appearance {\nmaterial Material { diffuseColor 0 1 1 }\n}\n}\n")
    wrlfile.write("Shape {\nappearance DEF GLASSDOOR Appearance {\nmaterial Material { diffuseColor 0 1 1 }\n}\n}\n")
    wrlfile.write("Shape {\nappearance DEF FIXEDSHADE Appearance {\nmaterial Material { diffuseColor 1 0 1 }\n}\n}\n")
    wrlfile.write("Shape {\nappearance DEF BLDGSHADE Appearance {\nmaterial Material { diffuseColor 0 0 1 }\n}\n}\n")
    wrlfile.write("Shape {\nappearance DEF SUBSHADE Appearance {\nmaterial Material { diffuseColor 1 0 1 }\n}\n}\n")
    wrlfile.write("Shape {\nappearance DEF BACKCOLOR Appearance {\nmaterial Material { diffuseColor 0.502 0.502 0.784 }\n}\n}\n")
