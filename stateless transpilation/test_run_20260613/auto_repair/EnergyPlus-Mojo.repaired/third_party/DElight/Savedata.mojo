/* Copyright 1992-2009	Regents of University of California
 *						Lawrence Berkeley National Laboratory
 *
 *  Authors: R.J. Hitchcock and W.L. Carroll
 *           Building Technologies Department
 *           Lawrence Berkeley National Laboratory
 */
/**************************************************************
 * C Language Implementation of DOE2.1d and Superlite 3.0
 * Daylighting Algorithms with new Complex Fenestration System
 * analysis algorithms.
 *
 * The original DOE2 daylighting algorithms and implementation
 * in FORTRAN were developed by F.C. Winkelmann at the
 * Lawrence Berkeley National Laboratory.
 *
 * The original Superlite algorithms and implementation in FORTRAN
 * were developed by Michael Modest and Jong-Jin Kim
 * under contract with Lawrence Berkeley National Laboratory.
 **************************************************************/
/*
NOTICE: The Government is granted for itself and others acting on its behalf 
a paid-up, nonexclusive, irrevocable worldwide license in this data to reproduce, 
prepare derivative works, and perform publicly and display publicly. 
Beginning five (5) years after (date permission to assert copyright was obtained),
subject to two possible five year renewals, the Government is granted for itself 
and others acting on its behalf a paid-up, nonexclusive, irrevocable worldwide
license in this data to reproduce, prepare derivative works, distribute copies to 
the public, perform publicly and display publicly, and to permit others to do so. 
NEITHER THE UNITED STATES NOR THE UNITED STATES DEPARTMENT OF ENERGY, NOR ANY OF
THEIR EMPLOYEES, MAKES ANY WARRANTY, EXPRESS OR IMPLIED, OR ASSUMES ANY LEGAL 
LIABILITY OR RESPONSIBILITY FOR THE ACCURACY, COMPLETENESS, OR USEFULNESS OF ANY 
INFORMATION, APPARATUS, PRODUCT, OR PROCESS DISCLOSED, OR REPRESENTS THAT ITS USE 
WOULD NOT INFRINGE PRIVATELY OWNED RIGHTS.
*/
from BGL import *
from CONST import *
from DBCONST import *
from DEF import *
from NodeMesh2 import *
from WLCSurface import *
from helpers import *
from hemisphiral import *
from btdf import *
from CFSSystem import *
from CFSSurface import *
from DOE2DL import *
from savedata import *
from os import FileHandle

/****************************** subroutine dump_bldg *****************************/
/* Writes bldg structure data to disk. */
/****************************************************************************/
/* C Language Implementation of DOE2 Daylighting Algorithms */
/* by Rob Hitchcock */
/* Building Technologies Program, Lawrence Berkeley Laboratory */
/****************************** subroutine dump_bldg *****************************/
def dump_bldg(
    bldg_ptr: BLDG,		/* building structure pointer */
    inout outfile: FileHandle)		/* pointer to building data file */
{
    /* BLDG dump headings */
    outfile.write("\n")
    outfile.write("BUILDING DATA\n")
    /* Dump site data */
    outfile.write(f"Building_Name {bldg_ptr.name}\n")
    outfile.write(f"Site_Latitude {bldg_ptr.lat:5.2f}\n")
    outfile.write(f"Site_Longitude {bldg_ptr.lon:5.2f}\n")
    outfile.write(f"Site_Altitude {bldg_ptr.alt:5.2f}\n")
    outfile.write(f"Building_Azimuth {bldg_ptr.azm:5.2f}\n")
    outfile.write(f"Site_TimeZone {bldg_ptr.timezone:5.2f}\n")
    /* monthly atmospheric turbidity */
    outfile.write("Atm_Turbidity")
    for im in range(MONTHS):
        outfile.write(f" {bldg_ptr.atmtur[im]:5.2f}")
    outfile.write("\n")
    /* monthly atmospheric moisture */
    outfile.write("Atm_Moisture")
    for im in range(MONTHS):
        outfile.write(f" {bldg_ptr.atmmoi[im]:5.2f}")
    outfile.write("\n")
    /* ----- derived quantities ----- */
    outfile.write("Exterior Horizontal Illuminance Components\n")
    outfile.write("        Overcast_Sky Clear_Sky Clear_Sun\n")
    for iphs in range(NPHS-1, -1, -1):
        outfile.write(f"SunAlt {iphs}: {bldg_ptr.hillumskyo[iphs]:9.2f} {bldg_ptr.hillumskyc[iphs]:9.2f} {bldg_ptr.hillumsunc[iphs]:9.2f}\n")
    /* Dump zone data */
    outfile.write("\n")
    outfile.write("ZONES\n")
    outfile.write(f"N_Zones {bldg_ptr.nzones}\n")
    for iz in range(bldg_ptr.nzones):
        /* Write ZONE headings lines */
        outfile.write("\n")
        outfile.write("ZONE DATA\n")
        outfile.write(f"Zone {bldg_ptr.zone[iz].name}\n")
        /* zone origin in bldg system coordinates */
        outfile.write("BldgSystem_Zone_Origin")
        for icoord in range(NCOORDS):
            outfile.write(f" {bldg_ptr.zone[iz].origin[icoord]:5.2f}")
        outfile.write("\n")
        outfile.write(f"Zone_Azimuth {bldg_ptr.zone[iz].azm:5.2f}\n")
        outfile.write(f"Zone_Multiplier {bldg_ptr.zone[iz].mult:5.2f}\n")
        outfile.write(f"Zone_Floor_Area {bldg_ptr.zone[iz].flarea:5.2f}\n")
        outfile.write(f"Zone_Volume {bldg_ptr.zone[iz].volume:5.2f}\n")
        outfile.write(f"Zone_Lighting {bldg_ptr.zone[iz].lighting:5.2f}\n")
        outfile.write(f"Min_Input_Power {bldg_ptr.zone[iz].min_power:5.2f}\n")
        outfile.write(f"Min_Light_Fraction {bldg_ptr.zone[iz].min_light:5.2f}\n")
        outfile.write(f"Light_Ctrl_Steps {bldg_ptr.zone[iz].lt_ctrl_steps}\n")
        outfile.write(f"Light_Ctrl_Prob {bldg_ptr.zone[iz].lt_ctrl_prob:5.2f}\n")
        outfile.write(f"View_Azimuth {bldg_ptr.zone[iz].view_azm:5.2f}\n")
        outfile.write(f"Max_Grid_Node_Area {bldg_ptr.zone[iz].max_grid_node_area:5.2f}\n")
        /* Write ZONE LIGHTING SCHEDULE headings lines */
        outfile.write("\n")
        outfile.write("ZONE LIGHTING SCHEDULES\n")
        outfile.write(f"N_Lt_Scheds {bldg_ptr.zone[iz].nltsch}\n")
        /* Dump lighting schedule data */
        for ils in range(bldg_ptr.zone[iz].nltsch):
            /* Write ZONE LIGHTING SCHEDULE headings lines */
            outfile.write("\n")
            outfile.write("ZONE LIGHTING SCHEDULE DATA\n")
            outfile.write(f"Lt_Sched {bldg_ptr.zone[iz].ltsch[ils].name}\n")
            outfile.write(f"Month_Begin {bldg_ptr.zone[iz].ltsch[ils].mon_begin}\n")
            outfile.write(f"Day_Begin {bldg_ptr.zone[iz].ltsch[ils].day_begin}\n")
            outfile.write(f"Month_End {bldg_ptr.zone[iz].ltsch[ils].mon_end}\n")
            outfile.write(f"Day_End {bldg_ptr.zone[iz].ltsch[ils].day_end}\n")
            outfile.write(f"Day_of_Week_Begin {bldg_ptr.zone[iz].ltsch[ils].dow_begin}\n")
            outfile.write(f"Day_of_Week_End {bldg_ptr.zone[iz].ltsch[ils].dow_end}\n")
            outfile.write("Hour_Fractions")
            for ihr in range(HOURS):
                outfile.write(f" {bldg_ptr.zone[iz].ltsch[ils].frac[ihr]:3.1f}")
            outfile.write("\n")
            /* ----- derived quantities ----- */
            outfile.write(f"Day_of_Year_Begin {bldg_ptr.zone[iz].ltsch[ils].doy_begin}\n")
            outfile.write(f"Day_of_Year_End {bldg_ptr.zone[iz].ltsch[ils].doy_end}\n")
        /* Write ZONE SURFACE headings lines */
        outfile.write("\n")
        outfile.write("ZONE SURFACES\n")
        outfile.write(f"N_Surfaces {bldg_ptr.zone[iz].nsurfs}\n")
        /* Dump surface data */
        for is in range(bldg_ptr.zone[iz].nsurfs):
            /* Write SURFACE headings lines */
            outfile.write("\n")
            outfile.write("ZONE SURFACE DATA\n")
            outfile.write(f"Surface {bldg_ptr.zone[iz].surf[is].name}\n")
            /* surface origin in zone system coordinates */
            outfile.write("ZoneSystem_Surface_Origin")
            for icoord in range(NCOORDS):
                outfile.write(f" {bldg_ptr.zone[iz].surf[is].origin[icoord]:5.2f}")
            outfile.write("\n")
            outfile.write(f"Height {bldg_ptr.zone[iz].surf[is].height:5.2f}\n")
            outfile.write(f"Width {bldg_ptr.zone[iz].surf[is].width:5.2f}\n")
            outfile.write(f"ZoneSystem_Azimuth {bldg_ptr.zone[iz].surf[is].azm_zs:5.2f}\n")
            outfile.write(f"ZoneSystem_Tilt {bldg_ptr.zone[iz].surf[is].tilt_zs:5.2f}\n")
            outfile.write(f"Vis_Refl {bldg_ptr.zone[iz].surf[is].vis_refl:5.2f}\n")
            outfile.write(f"Ext_Refl {bldg_ptr.zone[iz].surf[is].ext_vis_refl:5.2f}\n")
            outfile.write(f"Gnd_Refl {bldg_ptr.zone[iz].surf[is].gnd_refl:5.2f}\n")
            outfile.write(f"Surface_Type {bldg_ptr.zone[iz].surf[is].type}\n")
            outfile.write(f"Area {bldg_ptr.zone[iz].surf[is].area:8.2f}\n")
            outfile.write(f"E10Surf_Type_Index {bldg_ptr.zone[iz].surf[is].E10ndx}\n")
            /* ----- derived quantities ----- */
            outfile.write("BldgSystem_Surface_Vertices\n")
            for ivert in range(NVERTS):
                outfile.write(f"Vertex {ivert}: ")
                for icoord in range(NCOORDS):
                    outfile.write(f" {bldg_ptr.zone[iz].surf[is].vert[icoord][ivert]:5.2f}")
                outfile.write("\n")
            outfile.write(f"BldgSystem_Surface_Azimuth {bldg_ptr.zone[iz].surf[is].azm_bs:5.2f}\n")
            outfile.write(f"BldgSystem_Surface_Tilt {bldg_ptr.zone[iz].surf[is].tilt_bs:5.2f}\n")
            outfile.write("BldgSystem_Surface_Outward_Normal_Unit_Vector")
            for icoord in range(NCOORDS):
                outfile.write(f" {bldg_ptr.zone[iz].surf[is].outward_uvect[icoord]:5.2f}")
            outfile.write("\n")
            outfile.write("BldgSystem_Surface_Inward_Normal_Unit_Vector")
            for icoord in range(NCOORDS):
                outfile.write(f" {bldg_ptr.zone[iz].surf[is].inward_uvect[icoord]:5.2f}")
            outfile.write("\n")
            outfile.write("Surface_Direction_Cosines")
            for idc in range(NDC):
                outfile.write(f" {bldg_ptr.zone[iz].surf[is].dircos[idc]:5.2f}")
            outfile.write("\n")
            outfile.write(f"Surface Exterior Luminance from Overcast Sky {bldg_ptr.zone[iz].surf[is].ovrlum:8.2f}\n")
            outfile.write("Surface Exterior Luminances from Clear Sky\n")
            outfile.write("            SunAzm-4 SunAzm-3 SunAzm-2 SunAzm-1 SunAzm-0\n")
            for iphs in range(NPHS-1, -1, -1):
                outfile.write(f"SunAlt {iphs}: ")
                for iths in range(NTHS-1, -1, -1):
                    outfile.write(f" {bldg_ptr.zone[iz].surf[is].skylum[iphs][iths]:8.5f}")
                outfile.write("\n")
            outfile.write("Surface Exterior Luminances from Clear Sun\n")
            outfile.write("            SunAzm-4 SunAzm-3 SunAzm-2 SunAzm-1 SunAzm-0\n")
            for iphs in range(NPHS-1, -1, -1):
                outfile.write(f"SunAlt {iphs}: ")
                for iths in range(NTHS-1, -1, -1):
                    outfile.write(f" {bldg_ptr.zone[iz].surf[is].sunlum[iphs][iths]:8.5f}")
                outfile.write("\n")
            outfile.write(f"Surface_Node_Area {bldg_ptr.zone[iz].surf[is].node_area:8.2f}\n")
            outfile.write(f"Surface_Width_Nodes {bldg_ptr.zone[iz].surf[is].n_width}\n")
            outfile.write(f"Surface_Height_Nodes {bldg_ptr.zone[iz].surf[is].n_height}\n")
            outfile.write(f"Surface_Nodes {bldg_ptr.zone[iz].surf[is].nnodes}\n")
            outfile.write("Surface_Total_Direct_Illuminance_Data\n")
            outfile.write(f"Surface Total Direct Illuminance from Overcast Sky {bldg_ptr.zone[iz].surf[is].TotDirectOvercastIllum:8.2f}\n")
            outfile.write("Surface Total Direct Illuminances from Clear Sky\n")
            outfile.write("            SunAzm-4 SunAzm-3 SunAzm-2 SunAzm-1 SunAzm-0\n")
            for iphs in range(NPHS-1, -1, -1):
                outfile.write(f"SunAlt {iphs}: ")
                for iths in range(NTHS-1, -1, -1):
                    outfile.write(f" {bldg_ptr.zone[iz].surf[is].TotDirectSkyCIllum[iphs][iths]:8.5f}")
                outfile.write("\n")
            outfile.write("Surface Total Direct Illuminances from Clear Sun\n")
            outfile.write("            SunAzm-4 SunAzm-3 SunAzm-2 SunAzm-1 SunAzm-0\n")
            for iphs in range(NPHS-1, -1, -1):
                outfile.write(f"SunAlt {iphs}: ")
                for iths in range(NTHS-1, -1, -1):
                    outfile.write(f" {bldg_ptr.zone[iz].surf[is].TotDirectSunCIllum[iphs][iths]:8.5f}")
                outfile.write("\n")
            outfile.write("Surface_Node_Data\n")
            for inode in range(bldg_ptr.zone[iz].surf[is].nnodes):
                outfile.write(f"\nNode {inode:3d} BldgSystem_Node_Coordinates: ")
                for icoord in range(NCOORDS):
                    outfile.write(f" {bldg_ptr.zone[iz].surf[is].node[inode][icoord]:5.2f}")
                outfile.write("\n")
                outfile.write(f"Surface_Node_Area {bldg_ptr.zone[iz].surf[is].node_areas[inode]:8.2f}\n")
                outfile.write("Surface Node Luminances\n")
                outfile.write(f"Surface Node Direct Luminance from Overcast Sky {bldg_ptr.zone[iz].surf[is].direct_skyolum[inode]:8.2f}\n")
                outfile.write("Surface Node Direct Luminances from Clear Sky\n")
                outfile.write("            SunAzm-4 SunAzm-3 SunAzm-2 SunAzm-1 SunAzm-0\n")
                for iphs in range(NPHS-1, -1, -1):
                    outfile.write(f"SunAlt {iphs}: ")
                    for iths in range(NTHS-1, -1, -1):
                        outfile.write(f" {bldg_ptr.zone[iz].surf[is].direct_skyclum[inode][iphs][iths]:8.5f}")
                    outfile.write("\n")
                outfile.write("Surface Node Direct Luminances from Clear Sun\n")
                outfile.write("            SunAzm-4 SunAzm-3 SunAzm-2 SunAzm-1 SunAzm-0\n")
                for iphs in range(NPHS-1, -1, -1):
                    outfile.write(f"SunAlt {iphs}: ")
                    for iths in range(NTHS-1, -1, -1):
                        outfile.write(f" {bldg_ptr.zone[iz].surf[is].direct_sunclum[inode][iphs][iths]:8.5f}")
                    outfile.write("\n")
                outfile.write(f"Surface Node Total Luminance from Overcast Sky {bldg_ptr.zone[iz].surf[is].skyolum[inode]:8.2f}\n")
                outfile.write("Surface Node Total Luminances from Clear Sky\n")
                outfile.write("            SunAzm-4 SunAzm-3 SunAzm-2 SunAzm-1 SunAzm-0\n")
                for iphs in range(NPHS-1, -1, -1):
                    outfile.write(f"SunAlt {iphs}: ")
                    for iths in range(NTHS-1, -1, -1):
                        outfile.write(f" {bldg_ptr.zone[iz].surf[is].skyclum[inode][iphs][iths]:8.5f}")
                    outfile.write("\n")
                outfile.write("Surface Node Total Luminances from Clear Sun\n")
                outfile.write("            SunAzm-4 SunAzm-3 SunAzm-2 SunAzm-1 SunAzm-0\n")
                for iphs in range(NPHS-1, -1, -1):
                    outfile.write(f"SunAlt {iphs}: ")
                    for iths in range(NTHS-1, -1, -1):
                        outfile.write(f" {bldg_ptr.zone[iz].surf[is].sunclum[inode][iphs][iths]:8.5f}")
                    outfile.write("\n")
            /* Dump window data */
            /* Write SURFACE WINDOW headings lines */
            outfile.write("\n")
            outfile.write("SURFACE WINDOWS\n")
            outfile.write(f"N_Windows {bldg_ptr.zone[iz].surf[is].nwndos}\n")
            for iw in range(bldg_ptr.zone[iz].surf[is].nwndos):
                /* Write WINDOW DATA headings lines */
                outfile.write("\n")
                outfile.write("SURFACE WINDOW DATA\n")
                outfile.write(f"Window {bldg_ptr.zone[iz].surf[is].wndo[iw].name}\n")
                /* window origin in surface system coordinates */
                outfile.write("SurfSystem__Window_Origin")
                for icoord in range(NCOORDS):
                    outfile.write(f" {bldg_ptr.zone[iz].surf[is].wndo[iw].origin[icoord]:5.2f}")
                outfile.write("\n")
                outfile.write(f"Height {bldg_ptr.zone[iz].surf[is].wndo[iw].height:5.2f}\n")
                outfile.write(f"Width {bldg_ptr.zone[iz].surf[is].wndo[iw].width:5.2f}\n")
                outfile.write(f"Glass_Type {bldg_ptr.zone[iz].surf[is].wndo[iw].glass_type}\n")
                outfile.write(f"Shade_Flag {bldg_ptr.zone[iz].surf[is].wndo[iw].shade_flag}\n")
                if bldg_ptr.zone[iz].surf[is].wndo[iw].shade_flag != 0:
                    outfile.write(f"Shade_Type {bldg_ptr.zone[iz].surf[is].wndo[iw].shade_type}\n")
                /* window overhang/fin zone shade depth (ft) (viewed from inside looking outward (0=overhang, 1=right fin, 2=left fin)) */
                outfile.write("Window_Overhang_Fin_Depth_Values")
                for izshade in range(NZSHADES):
                    outfile.write(f" {bldg_ptr.zone[iz].surf[is].wndo[iw].zshade_x[izshade]:5.2f}")
                outfile.write("\n")
                /* window overhang/fin zone shade distance from window (ft) */
                outfile.write("Window_Overhang_Fin_Distance_Values")
                for izshade in range(NZSHADES):
                    outfile.write(f" {bldg_ptr.zone[iz].surf[is].wndo[iw].zshade_y[izshade]:5.2f}")
                outfile.write("\n")
                /* ----- derived quantities ----- */
                outfile.write("BldgSystem_Window_Vertices\n")
                for ivert in range(NVERTS):
                    outfile.write(f"Vertex {ivert}: ")
                    for icoord in range(NCOORDS):
                        outfile.write(f" {bldg_ptr.zone[iz].surf[is].wndo[iw].vert[icoord][ivert]:5.2f}")
                    outfile.write("\n")
                outfile.write("Window Center Exterior Luminance from Overcast Sky\n")
                outfile.write(f"{bldg_ptr.zone[iz].surf[is].wndo[iw].wlumskyo:8.2f}\n")
                outfile.write("Window Center Exterior Luminances from Clear Sky\n")
                outfile.write("            SunAzm-4 SunAzm-3 SunAzm-2 SunAzm-1 SunAzm-0\n")
                for iphs in range(NPHS-1, -1, -1):
                    outfile.write(f"SunAlt {iphs}: ")
                    for iths in range(NTHS-1, -1, -1):
                        outfile.write(f" {bldg_ptr.zone[iz].surf[is].wndo[iw].wlumsky[iphs][iths]:8.2f}")
                    outfile.write("\n")
                outfile.write("Window Center Exterior Luminances from Clear Sun\n")
                outfile.write("            SunAzm-4 SunAzm-3 SunAzm-2 SunAzm-1 SunAzm-0\n")
                for iphs in range(NPHS-1, -1, -1):
                    outfile.write(f"SunAlt {iphs}: ")
                    for iths in range(NTHS-1, -1, -1):
                        outfile.write(f" {bldg_ptr.zone[iz].surf[is].wndo[iw].wlumsun[iphs][iths]:8.2f}")
                    outfile.write("\n")
                outfile.write(f"Window_Node_Area {bldg_ptr.zone[iz].surf[is].wndo[iw].node_area:8.2f}\n")
                outfile.write(f"Window_Width_Nodes {bldg_ptr.zone[iz].surf[is].wndo[iw].n_width}\n")
                outfile.write(f"Window_Height_Nodes {bldg_ptr.zone[iz].surf[is].wndo[iw].n_height}\n")
                outfile.write(f"Window_Nodes {bldg_ptr.zone[iz].surf[is].wndo[iw].nnodes}\n")
                outfile.write("Window_Node_Data\n")
                for inode in range(bldg_ptr.zone[iz].surf[is].wndo[iw].nnodes):
                    outfile.write(f"Node {inode:3d} BldgSystem_Node_Coordinates: ")
                    for icoord in range(NCOORDS):
                        outfile.write(f" {bldg_ptr.zone[iz].surf[is].wndo[iw].node[inode][icoord]:5.2f}")
                    outfile.write("\n")
                    outfile.write(f"Window_Node_Area {bldg_ptr.zone[iz].surf[is].wndo[iw].node_areas[inode]:8.2f}\n")
                    outfile.write("Window Node Luminances\n")
                    outfile.write(f"Window Node Direct Luminance from Overcast Sky {bldg_ptr.zone[iz].surf[is].wndo[iw].direct_skyolum[inode]:8.2f}\n")
                    outfile.write("Window Node Direct Luminances from Clear Sky\n")
                    outfile.write("            SunAzm-4 SunAzm-3 SunAzm-2 SunAzm-1 SunAzm-0\n")
                    for iphs in range(NPHS-1, -1, -1):
                        outfile.write(f"SunAlt {iphs}: ")
                        for iths in range(NTHS-1, -1, -1):
                            outfile.write(f" {bldg_ptr.zone[iz].surf[is].wndo[iw].direct_skyclum[inode][iphs][iths]:8.5f}")
                        outfile.write("\n")
                    outfile.write("Window Node Direct Luminances from Clear Sun\n")
                    outfile.write("            SunAzm-4 SunAzm-3 SunAzm-2 SunAzm-1 SunAzm-0\n")
                    for iphs in range(NPHS-1, -1, -1):
                        outfile.write(f"SunAlt {iphs}: ")
                        for iths in range(NTHS-1, -1, -1):
                            outfile.write(f" {bldg_ptr.zone[iz].surf[is].wndo[iw].direct_sunclum[inode][iphs][iths]:8.5f}")
                        outfile.write("\n")
                    outfile.write(f"Window Node Total Luminance from Overcast Sky {bldg_ptr.zone[iz].surf[is].wndo[iw].skyolum[inode]:8.2f}\n")
                    outfile.write("Window Node Total Luminances from Clear Sky\n")
                    outfile.write("            SunAzm-4 SunAzm-3 SunAzm-2 SunAzm-1 SunAzm-0\n")
                    for iphs in range(NPHS-1, -1, -1):
                        outfile.write(f"SunAlt {iphs}: ")
                        for iths in range(NTHS-1, -1, -1):
                            outfile.write(f" {bldg_ptr.zone[iz].surf[is].wndo[iw].skyclum[inode][iphs][iths]:8.5f}")
                        outfile.write("\n")
                    outfile.write("Window Node Total Luminances from Clear Sun\n")
                    outfile.write("            SunAzm-4 SunAzm-3 SunAzm-2 SunAzm-1 SunAzm-0\n")
                    for iphs in range(NPHS-1, -1, -1):
                        outfile.write(f"SunAlt {iphs}: ")
                        for iths in range(NTHS-1, -1, -1):
                            outfile.write(f" {bldg_ptr.zone[iz].surf[is].wndo[iw].sunclum[inode][iphs][iths]:8.5f}")
                        outfile.write("\n")
            /* Dump CFS Surface data */
            /* Write CFS SURFACE headings lines */
            outfile.write("\n")
            outfile.write("CFS SURFACE\n")
            outfile.write(f"N_CFSs {bldg_ptr.zone[iz].surf[is].ncfs}\n")
            for icfs in range(bldg_ptr.zone[iz].surf[is].ncfs):
                /* Write CFS SURFACE DATA headings lines */
                outfile.write("\n")
                outfile.write("CFS SURFACE DATA\n")
                outfile.write(f"CFS Name {bldg_ptr.zone[iz].surf[is].cfs[icfs].Name()}\n")
                outfile.write(f"CFS Type {bldg_ptr.zone[iz].surf[is].cfs[icfs].TypeName()}\n")
                outfile.write(f"CFS N_Nodes {bldg_ptr.zone[iz].surf[is].cfs[icfs].MeshSize()}\n")
                outfile.write("BldgSystem_CFS_Vertices (inside lower-left corner counter-clockwise)\n")
                for ivert in range(bldg_ptr.zone[iz].surf[is].cfs[icfs].nvert()):
                    outfile.write(f"Vertex {ivert}: ")
                    var pt3TmpPt: BGL.point3 = bldg_ptr.zone[iz].surf[is].cfs[icfs].vert3D(ivert)
                    for icoord in range(NCOORDS):
                        outfile.write(f" {pt3TmpPt[icoord]:5.2f}")
                    outfile.write("\n")
        /* Write ZONE SHADES headings lines */
        outfile.write("\n")
        outfile.write("ZONE SHADES\n")
        outfile.write(f"N_ZShades {bldg_ptr.zone[iz].nzshades}\n")
        /* Write ZONE SHADE DATA */
        for izs in range(bldg_ptr.zone[iz].nzshades):
            outfile.write("\n")
            outfile.write("ZONE SHADE DATA\n")
            outfile.write(f"ZShade {bldg_ptr.zone[iz].zshade[izs].name}\n")
            /* shade origin in zone system coordinates */
            outfile.write("ZoneSystem_ZShade_Origin")
            for icoord in range(NCOORDS):
                outfile.write(f" {bldg_ptr.zone[iz].zshade[izs].origin[icoord]:5.2f}")
            outfile.write("\n")
            outfile.write(f"Height {bldg_ptr.zone[iz].zshade[izs].height:5.2f}\n")
            outfile.write(f"Width {bldg_ptr.zone[iz].zshade[izs].width:5.2f}\n")
            outfile.write(f"ZoneSystem_Azimuth {bldg_ptr.zone[iz].zshade[izs].azm_zs:5.2f}\n")
            outfile.write(f"ZoneSystem_Tilt {bldg_ptr.zone[iz].zshade[izs].tilt_zs:5.2f}\n")
            /* ----- derived quantities ----- */
            outfile.write("BldgSystem_ZShade_Vertices\n")
            for ivert in range(NVERTS):
                outfile.write(f"Vertex {ivert}: ")
                for icoord in range(NCOORDS):
                    outfile.write(f" {bldg_ptr.zone[iz].zshade[izs].vert[icoord][ivert]:5.2f}")
                outfile.write("\n")
            outfile.write(f"BldgSystem_Azimuth {bldg_ptr.zone[iz].zshade[izs].azm_bs:5.2f}\n")
            outfile.write(f"BldgSystem_Tilt {bldg_ptr.zone[iz].zshade[izs].tilt_bs:5.2f}\n")
        /* Write ZONE REFERENCE POINT headings lines */
        outfile.write("\n")
        outfile.write("ZONE REFERENCE POINTS\n")
        outfile.write(f"N_Reference_Points {bldg_ptr.zone[iz].nrefpts}\n")
        /* Dump ref pt data */
        for irp in range(bldg_ptr.zone[iz].nrefpts):
            /* Write REFERENCE POINT DATA headings lines */
            outfile.write("\n")
            outfile.write("ZONE REFERENCE POINT DATA\n")
            outfile.write(f"Reference_Point {bldg_ptr.zone[iz].ref_pt[irp].name}\n")
            /* ref pt in zone system coordinates */
            outfile.write("ZoneSystem_RefPt_Coords")
            for icoord in range(NCOORDS):
                outfile.write(f" {bldg_ptr.zone[iz].ref_pt[irp].zs[icoord]:5.2f}")
            outfile.write("\n")
            outfile.write(f"Zone_Fraction {bldg_ptr.zone[iz].ref_pt[irp].zone_frac:5.2f}\n")
            outfile.write(f"Light_Set_Pt {bldg_ptr.zone[iz].ref_pt[irp].lt_set_pt:5.2f}\n")
            outfile.write(f"Light_Ctrl_Type {bldg_ptr.zone[iz].ref_pt[irp].lt_ctrl_type}\n")
            /* --------------- derived quantities ------------------ */
            /* ref pt in bldg system coordinates */
            outfile.write("BldgSystem_RefPt_Coords")
            for icoord in range(NCOORDS):
                outfile.write(f" {bldg_ptr.zone[iz].ref_pt[irp].bs[icoord]:5.2f}")
            outfile.write("\n")
            outfile.write(f"Reference Point Direct Illuminance from Overcast Sky {bldg_ptr.zone[iz].ref_pt[irp].direct_skyoillum:8.2f}\n")
            outfile.write("\n")
            outfile.write("Reference Point Direct Illuminances from Clear Sky\n")
            outfile.write("            SunAzm-4 SunAzm-3 SunAzm-2 SunAzm-1 SunAzm-0\n")
            for iphs in range(NPHS-1, -1, -1):
                outfile.write(f"SunAlt {iphs}: ")
                for iths in range(NTHS-1, -1, -1):
                    outfile.write(f" {bldg_ptr.zone[iz].ref_pt[irp].direct_skycillum[iphs][iths]:8.5f}")
                outfile.write("\n")
            outfile.write("\n")
            outfile.write("Reference Point Direct Illuminances from Clear Sun\n")
            outfile.write("            SunAzm-4 SunAzm-3 SunAzm-2 SunAzm-1 SunAzm-0\n")
            for iphs in range(NPHS-1, -1, -1):
                outfile.write(f"SunAlt {iphs}: ")
                for iths in range(NTHS-1, -1, -1):
                    outfile.write(f" {bldg_ptr.zone[iz].ref_pt[irp].direct_suncillum[iphs][iths]:8.5f}")
                outfile.write("\n")
            outfile.write("\n")
            outfile.write(f"Reference Point Total Illuminance from Overcast Sky {bldg_ptr.zone[iz].ref_pt[irp].skyoillum:8.2f}\n")
            outfile.write("\n")
            outfile.write("Reference Point Total Illuminances from Clear Sky\n")
            outfile.write("            SunAzm-4 SunAzm-3 SunAzm-2 SunAzm-1 SunAzm-0\n")
            for iphs in range(NPHS-1, -1, -1):
                outfile.write(f"SunAlt {iphs}: ")
                for iths in range(NTHS-1, -1, -1):
                    outfile.write(f" {bldg_ptr.zone[iz].ref_pt[irp].skycillum[iphs][iths]:8.5f}")
                outfile.write("\n")
            outfile.write("\n")
            outfile.write("Reference Point Total Illuminances from Clear Sun\n")
            outfile.write("            SunAzm-4 SunAzm-3 SunAzm-2 SunAzm-1 SunAzm-0\n")
            for iphs in range(NPHS-1, -1, -1):
                outfile.write(f"SunAlt {iphs}: ")
                for iths in range(NTHS-1, -1, -1):
                    outfile.write(f" {bldg_ptr.zone[iz].ref_pt[irp].suncillum[iphs][iths]:8.5f}")
                outfile.write("\n")
            outfile.write("\n")
            outfile.write("Monthly Average Daylight Illuminances\n")
            outfile.write("                                                            Hour of Day\n")
            outfile.write("\n")
            outfile.write("Month      1    2    3    4    5    6    7    8    9   10   11   12   13   14   15   16   17   18   19   20   21   22   23   24\n")
            outfile.write("-----   ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----\n")
            for imon in range(MONTHS):
                outfile.write(f"{imon+1:3d}    ")
                for ihr in range(HOURS):
                    outfile.write(f" {bldg_ptr.zone[iz].ref_pt[irp].day_illum[imon][ihr]:4.0f}")
                outfile.write("\n")
            outfile.write("\n")
            outfile.write(f"Reference Point Daylight Factor for Overcast Sky {bldg_ptr.zone[iz].ref_pt[irp].dfskyo:8.4f}\n")
            outfile.write("\n")
            outfile.write("Reference Point Daylight Factors for Clear Sky\n")
            outfile.write("            SunAzm-4 SunAzm-3 SunAzm-2 SunAzm-1 SunAzm-0\n")
            for iphs in range(NPHS-1, -1, -1):
                outfile.write(f"SunAlt {iphs}: ")
                for iths in range(NTHS-1, -1, -1):
                    outfile.write(f" {bldg_ptr.zone[iz].ref_pt[irp].dfsky[iphs][iths]:8.4f}")
                outfile.write("\n")
            outfile.write("\n")
            outfile.write("Reference Point Daylight Factors for Clear Sun\n")
            outfile.write("            SunAzm-4 SunAzm-3 SunAzm-2 SunAzm-1 SunAzm-0\n")
            for iphs in range(NPHS-1, -1, -1):
                outfile.write(f"SunAlt {iphs}: ")
                for iths in range(NTHS-1, -1, -1):
                    outfile.write(f" {bldg_ptr.zone[iz].ref_pt[irp].dfsun[iphs][iths]:8.4f}")
                outfile.write("\n")
        /* --------------- calculated ZONE quantities ------------------ */
        outfile.write("\n")
        outfile.write("Lighting Zone Monthly Average Fraction Lighting Energy Reduction\n")
        outfile.write("                                                            Hour of Day\n")
        outfile.write("\n")
        outfile.write("Month      1    2    3    4    5    6    7    8    9   10   11   12   13   14   15   16   17   18   19   20   21   22   23   24\n")
        outfile.write("-----   ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----\n")
        for imon in range(MONTHS):
            outfile.write(f"{imon+1:3d}    ")
            for ihr in range(HOURS):
                outfile.write(f" {bldg_ptr.zone[iz].lt_reduc[imon][ihr]:4.2f}")
            outfile.write("\n")
        /* annual avg fraction lighting energy reduction */
        outfile.write("\n")
        outfile.write("Lighting Zone Annual Average Fraction Lighting Energy Reduction\n")
        outfile.write("                                                            Hour of Day\n")
        outfile.write("\n")
        outfile.write("           1    2    3    4    5    6    7    8    9   10   11   12   13   14   15   16   17   18   19   20   21   22   23   24\n")
        outfile.write("        ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----\n")
        outfile.write("       ")
        for ihr in range(HOURS):
            outfile.write(f" {bldg_ptr.zone[iz].annual_reduc[ihr]:4.2f}")
        outfile.write("\n")
    /* Write BUILDING SHADES headings lines */
    outfile.write("\n")
    outfile.write("BUILDING SHADES\n")
    outfile.write(f"N_BShades {bldg_ptr.nbshades}\n")
    /* Write BUILDING SHADE DATA */
    for ish in range(bldg_ptr.nbshades):
        outfile.write("\n")
        outfile.write("BUILDING SHADE DATA\n")
        outfile.write(f"BShade {bldg_ptr.bshade[ish].name}\n")
        /* shade origin in building system coordinates */
        outfile.write("BldgSystem_BShade_Origin")
        for icoord in range(NCOORDS):
            outfile.write(f" {bldg_ptr.bshade[ish].origin[icoord]:5.2f}")
        outfile.write("\n")
        outfile.write(f"Height {bldg_ptr.bshade[ish].height:5.2f}\n")
        outfile.write(f"Width {bldg_ptr.bshade[ish].width:5.2f}\n")
        outfile.write(f"Azimuth {bldg_ptr.bshade[ish].azm:5.2f}\n")
        outfile.write(f"Tilt {bldg_ptr.bshade[ish].tilt:5.2f}\n")
        outfile.write(f"Vis_Refl {bldg_ptr.bshade[ish].vis_refl:5.2f}\n")
        outfile.write(f"Gnd_Refl {bldg_ptr.bshade[ish].gnd_refl:5.2f}\n")
        /* ----- derived quantities ----- */
        outfile.write("BldgSystem_BShade_Vertices\n")
        for ivert in range(NVERTS):
            outfile.write(f"Vertex {ivert}: ")
            for icoord in range(NCOORDS):
                outfile.write(f" {bldg_ptr.bshade[ish].vert[icoord][ivert]:5.2f}")
            outfile.write("\n")
        outfile.write("Building Shade Luminance from Sky for Clear Sky\n")
        for iphs in range(NPHS-1, -1, -1):
            outfile.write(f"SunAlt {iphs}: ")
            for iths in range(NTHS-1, -1, -1):
                outfile.write(f" {bldg_ptr.bshade[ish].skylum[iphs][iths]:5.2f}")
            outfile.write("\n")
        outfile.write("Building Shade Luminance from Sun for Clear Sky\n")
        for iphs in range(NPHS-1, -1, -1):
            outfile.write(f"SunAlt {iphs}: ")
            for iths in range(NTHS-1, -1, -1):
                outfile.write(f" {bldg_ptr.bshade[ish].sunlum[iphs][iths]:5.2f}")
            outfile.write("\n")
        outfile.write(f"Building Shade Luminance for Overcast Sky = {bldg_ptr.bshade[ish].ovrlum:5.2f}\n")
    return
}
/****************************** subroutine dump_lib *****************************/
/* Writes library structure data to disk. */
/****************************************************************************/
/* C Language Implementation of DOE2 Daylighting Algorithms */
/* by Rob Hitchcock */
/* Building Technologies Program, Lawrence Berkeley Laboratory */
/****************************** subroutine dump_lib *****************************/
def dump_lib(
    lib_ptr: LIB,		/* library structure pointer */
    inout outfile: FileHandle)		/* pointer to library data file */
{
    /* LIB dump headings */
    outfile.write("\n")
    outfile.write("LIBRARY DATA\n")
    /* Dump glass data */
    outfile.write("GLASS TYPES\n")
    outfile.write(f"N_Glass_Types {lib_ptr.nglass}\n")
    for ig in range(lib_ptr.nglass):
        /* Write GLASS TYPE DATA headings lines */
        outfile.write("\n")
        outfile.write("GLASS TYPE DATA\n")
        outfile.write(f"Name {lib_ptr.glass[ig].name}\n")
        outfile.write(f"Visible_Transmittance {lib_ptr.glass[ig].vis_trans:10.6f}\n")
        outfile.write(f"Inside_Reflectance {lib_ptr.glass[ig].inside_refl:10.6f}\n")
        outfile.write(f"CAM1 {lib_ptr.glass[ig].cam1:10.6f}\n")
        outfile.write(f"CAM2 {lib_ptr.glass[ig].cam2:10.6f}\n")
        outfile.write(f"CAM3 {lib_ptr.glass[ig].cam3:10.6f}\n")
        outfile.write(f"CAM4 {lib_ptr.glass[ig].cam4:10.6f}\n")
        outfile.write(f"CAM9 {lib_ptr.glass[ig].cam9:10.6f}\n")
        outfile.write(f"E10Hemispherical_Transmittance {lib_ptr.glass[ig].E10hemi_trans:10.6f}\n")
        outfile.write(f"E10Coefficient1 {lib_ptr.glass[ig].E10coef[0]:10.6f}\n")
        outfile.write(f"E10Coefficient2 {lib_ptr.glass[ig].E10coef[1]:10.6f}\n")
        outfile.write(f"E10Coefficient3 {lib_ptr.glass[ig].E10coef[2]:10.6f}\n")
        outfile.write(f"E10Coefficient4 {lib_ptr.glass[ig].E10coef[3]:10.6f}\n")
        outfile.write(f"W4hemi_trans {lib_ptr.glass[ig].W4hemi_trans:10.6f}\n")
        outfile.write(f"W4vis_fit1 {lib_ptr.glass[ig].W4vis_fit1:10.6f}\n")
        outfile.write(f"W4vis_fit2 {lib_ptr.glass[ig].W4vis_fit2:10.6f}\n")
        outfile.write(f"EPlusDiffuse_Trans {lib_ptr.glass[ig].EPlusDiffuse_Trans:10.6f}\n")
        outfile.write(f"EPlusCoef1 {lib_ptr.glass[ig].EPlusCoef[0]:10.6f}\n")
        outfile.write(f"EPlusCoef2 {lib_ptr.glass[ig].EPlusCoef[1]:10.6f}\n")
        outfile.write(f"EPlusCoef3 {lib_ptr.glass[ig].EPlusCoef[2]:10.6f}\n")
        outfile.write(f"EPlusCoef4 {lib_ptr.glass[ig].EPlusCoef[3]:10.6f}\n")
        outfile.write(f"EPlusCoef5 {lib_ptr.glass[ig].EPlusCoef[4]:10.6f}\n")
        outfile.write(f"EPlusCoef6 {lib_ptr.glass[ig].EPlusCoef[5]:10.6f}\n")
    /* Dump wshade data */
    outfile.write("\n")
    outfile.write("WSHADE TYPES\n")
    outfile.write(f"N_WShade_Types {lib_ptr.nwshades}\n")
    for iws in range(lib_ptr.nwshades):
        /* Write WSHADE TYPE DATA headings lines */
        outfile.write("\n")
        outfile.write("WSHADE TYPE DATA\n")
        outfile.write(f"Name {lib_ptr.wshade[iws].name}\n")
        outfile.write(f"Visible_Transmittance {lib_ptr.wshade[iws].vis_trans:5.2f}\n")
        outfile.write(f"Inside_Reflectance {lib_ptr.wshade[iws].inside_refl:5.2f}\n")
    return
}