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
from BGL import BGL
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
from EPlus_Loaddata import *
from struct import *
from geom import *
from stdlib import *
from io import FileReader, FileWriter

/****************************** subroutine LoadDataFromEPlus *****************************/
/* Loads DElight Building data from a disk file generated from EnergyPlus data. */
/* Reads surface vertex coordinates in World Coordinate System */
/****************************** subroutine LoadDataFromEPlus *****************************/
def LoadDataFromEPlus(
    bldg_ptr: BLDG,        /* building structure pointer */
    infile: FileReader,    /* pointer to building data file */
    pofdmpfile: FileWriter /* ptr to dump file */
) -> Int:
{
    var cInputLine: String = "";    /* Input line */
    var token: String = "";         /* Input token pointer */
    var icoord: Int, im: Int, iz: Int, ils: Int, is: Int, iw: Int, ish: Int, irp: Int, ihr: Int; /* indexes */
    var izshade_x: Int, izshade_y: Int; /* indexes */
    /* Read and discard the second heading line (first line is read in exported function) */
    if infile.readline(cInputLine) == -1: return -1
    /* Read site data */
    if infile.readline(cInputLine) == -1: return -1
    # sscanf(cInputLine,"%*s %s\n",bldg_ptr->name);
    var parts: List[String] = cInputLine.split()
    bldg_ptr.name = parts[1]
    if infile.readline(cInputLine) == -1: return -1
    # sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->lat);
    parts = cInputLine.split()
    bldg_ptr.lat = float(parts[1])
    if infile.readline(cInputLine) == -1: return -1
    # sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->lon);
    parts = cInputLine.split()
    bldg_ptr.lon = float(parts[1])
    if infile.readline(cInputLine) == -1: return -1
    # sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->alt);
    parts = cInputLine.split()
    bldg_ptr.alt = float(parts[1])
    if infile.readline(cInputLine) == -1: return -1
    # sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->azm);
    parts = cInputLine.split()
    bldg_ptr.azm = float(parts[1])
    if infile.readline(cInputLine) == -1: return -1
    # sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->timezone);
    parts = cInputLine.split()
    bldg_ptr.timezone = float(parts[1])
    /* monthly atmospheric moisture */
    if infile.readline(cInputLine) == -1: return -1
    /* tokenize the line label */
    token = cInputLine.split()[0]  # discard label
    var tokens: List[String] = cInputLine.split()
    for im in range(MONTHS):
        token = tokens[im+1]
        bldg_ptr.atmmoi[im] = float(token)
    /* monthly atmospheric turbidity */
    if infile.readline(cInputLine) == -1: return -1
    /* tokenize the line label */
    token = cInputLine.split()[0]
    tokens = cInputLine.split()
    for im in range(MONTHS):
        token = tokens[im+1]
        bldg_ptr.atmtur[im] = float(token)
    /* Read and discard ZONES headings lines */
    if infile.readline(cInputLine) == -1: return -1
    if infile.readline(cInputLine) == -1: return -1
    /* Read zone data */
    if infile.readline(cInputLine) == -1: return -1
    # sscanf(cInputLine,"%*s %d\n",&bldg_ptr->nzones);
    parts = cInputLine.split()
    bldg_ptr.nzones = int(parts[1])
    if bldg_ptr.nzones > MAX_BLDG_ZONES:
        pofdmpfile.write("ERROR: DElight exceeded maximum ZONES limit of " + str(MAX_BLDG_ZONES) + "\n")
        return -1
    for iz in range(bldg_ptr.nzones):
        bldg_ptr.zone[iz] = ZONE()
        if bldg_ptr.zone[iz] is None:
            pofdmpfile.write("ERROR: DElight Insufficient memory for ZONE allocation\n")
            return -1
        struct_init("ZONE", bldg_ptr.zone[iz])
        /* Read and discard ZONE headings lines */
        if infile.readline(cInputLine) == -1: return -1
        if infile.readline(cInputLine) == -1: return -1
        if infile.readline(cInputLine) == -1: return -1
        # sscanf(cInputLine,"%*s %s\n",bldg_ptr->zone[iz]->name);
        parts = cInputLine.split()
        bldg_ptr.zone[iz].name = parts[1]
        /* zone origin in bldg system coordinates */
        if infile.readline(cInputLine) == -1: return -1
        /* tokenize the line label */
        token = cInputLine.split()[0]
        tokens = cInputLine.split()
        for icoord in range(NCOORDS):
            token = tokens[icoord+1]
            bldg_ptr.zone[iz].origin[icoord] = float(token)
        if infile.readline(cInputLine) == -1: return -1
        # sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->zone[iz]->azm);
        parts = cInputLine.split()
        bldg_ptr.zone[iz].azm = float(parts[1])
        if infile.readline(cInputLine) == -1: return -1
        # sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->zone[iz]->mult);
        parts = cInputLine.split()
        bldg_ptr.zone[iz].mult = float(parts[1])
        if infile.readline(cInputLine) == -1: return -1
        # sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->zone[iz]->flarea);
        parts = cInputLine.split()
        bldg_ptr.zone[iz].flarea = float(parts[1])
        if infile.readline(cInputLine) == -1: return -1
        # sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->zone[iz]->volume);
        parts = cInputLine.split()
        bldg_ptr.zone[iz].volume = float(parts[1])
        if infile.readline(cInputLine) == -1: return -1
        # sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->zone[iz]->lighting);
        parts = cInputLine.split()
        bldg_ptr.zone[iz].lighting = float(parts[1])
        if infile.readline(cInputLine) == -1: return -1
        # sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->zone[iz]->min_power);
        parts = cInputLine.split()
        bldg_ptr.zone[iz].min_power = float(parts[1])
        if infile.readline(cInputLine) == -1: return -1
        # sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->zone[iz]->min_light);
        parts = cInputLine.split()
        bldg_ptr.zone[iz].min_light = float(parts[1])
        if infile.readline(cInputLine) == -1: return -1
        # sscanf(cInputLine,"%*s %d\n",&bldg_ptr->zone[iz]->lt_ctrl_steps);
        parts = cInputLine.split()
        bldg_ptr.zone[iz].lt_ctrl_steps = int(parts[1])
        if infile.readline(cInputLine) == -1: return -1
        # sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->zone[iz]->lt_ctrl_prob);
        parts = cInputLine.split()
        bldg_ptr.zone[iz].lt_ctrl_prob = float(parts[1])
        if infile.readline(cInputLine) == -1: return -1
        # sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->zone[iz]->view_azm);
        parts = cInputLine.split()
        bldg_ptr.zone[iz].view_azm = float(parts[1])
        if infile.readline(cInputLine) == -1: return -1
        # sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->zone[iz]->max_grid_node_area);
        parts = cInputLine.split()
        bldg_ptr.zone[iz].max_grid_node_area = float(parts[1])
        /* Read and discard ZONE LIGHTING SCHEDULE headings lines */
        if infile.readline(cInputLine) == -1: return -1
        if infile.readline(cInputLine) == -1: return -1
        /* Read lighting schedule data */
        if infile.readline(cInputLine) == -1: return -1
        # sscanf(cInputLine,"%*s %d\n",&bldg_ptr->zone[iz]->nltsch);
        parts = cInputLine.split()
        bldg_ptr.zone[iz].nltsch = int(parts[1])
        if bldg_ptr.zone[iz].nltsch > MAX_LT_SCHEDS:
            pofdmpfile.write("ERROR: DElight exceeded maximum LIGHTING SCHEDULES limit of " + str(MAX_LT_SCHEDS) + "\n")
            return -1
        for ils in range(bldg_ptr.zone[iz].nltsch):
            bldg_ptr.zone[iz].ltsch[ils] = LTSCH()
            if bldg_ptr.zone[iz].ltsch[ils] is None:
                pofdmpfile.write("ERROR: DElight Insufficient memory for LIGHT SCHEDULE allocation\n")
                return -1
            struct_init("LTSCH", bldg_ptr.zone[iz].ltsch[ils])
            /* Read and discard LIGHTING SCHEDULE DATA headings lines */
            if infile.readline(cInputLine) == -1: return -1
            if infile.readline(cInputLine) == -1: return -1
            if infile.readline(cInputLine) == -1: return -1
            # sscanf(cInputLine,"%*s %s\n",bldg_ptr->zone[iz]->ltsch[ils]->name);
            parts = cInputLine.split()
            bldg_ptr.zone[iz].ltsch[ils].name = parts[1]
            if infile.readline(cInputLine) == -1: return -1
            # sscanf(cInputLine,"%*s %d\n",&bldg_ptr->zone[iz]->ltsch[ils]->mon_begin);
            parts = cInputLine.split()
            bldg_ptr.zone[iz].ltsch[ils].mon_begin = int(parts[1])
            if infile.readline(cInputLine) == -1: return -1
            # sscanf(cInputLine,"%*s %d\n",&bldg_ptr->zone[iz]->ltsch[ils]->day_begin);
            parts = cInputLine.split()
            bldg_ptr.zone[iz].ltsch[ils].day_begin = int(parts[1])
            if infile.readline(cInputLine) == -1: return -1
            # sscanf(cInputLine,"%*s %d\n",&bldg_ptr->zone[iz]->ltsch[ils]->mon_end);
            parts = cInputLine.split()
            bldg_ptr.zone[iz].ltsch[ils].mon_end = int(parts[1])
            if infile.readline(cInputLine) == -1: return -1
            # sscanf(cInputLine,"%*s %d\n",&bldg_ptr->zone[iz]->ltsch[ils]->day_end);
            parts = cInputLine.split()
            bldg_ptr.zone[iz].ltsch[ils].day_end = int(parts[1])
            if infile.readline(cInputLine) == -1: return -1
            # sscanf(cInputLine,"%*s %d\n",&bldg_ptr->zone[iz]->ltsch[ils]->dow_begin);
            parts = cInputLine.split()
            bldg_ptr.zone[iz].ltsch[ils].dow_begin = int(parts[1])
            if infile.readline(cInputLine) == -1: return -1
            # sscanf(cInputLine,"%*s %d\n",&bldg_ptr->zone[iz]->ltsch[ils]->dow_end);
            parts = cInputLine.split()
            bldg_ptr.zone[iz].ltsch[ils].dow_end = int(parts[1])
            /* lighting schedule hourly fractions */
            if infile.readline(cInputLine) == -1: return -1
            /* tokenize the line label */
            token = cInputLine.split()[0]
            tokens = cInputLine.split()
            for ihr in range(HOURS):
                token = tokens[ihr+1]
                bldg_ptr.zone[iz].ltsch[ils].frac[ihr] = float(token)
        /* Read and discard ZONE SURFACES headings lines */
        if infile.readline(cInputLine) == -1: return -1
        if infile.readline(cInputLine) == -1: return -1
        /* Read surface data */
        if infile.readline(cInputLine) == -1: return -1
        # sscanf(cInputLine,"%*s %d\n",&bldg_ptr->zone[iz]->nsurfs);
        parts = cInputLine.split()
        bldg_ptr.zone[iz].nsurfs = int(parts[1])
        if bldg_ptr.zone[iz].nsurfs > MAX_ZONE_SURFS:
            pofdmpfile.write("ERROR: DElight exceeded maximum ZONE SURFACES limit of " + str(MAX_ZONE_SURFS) + "\n")
            return -1
        for is in range(bldg_ptr.zone[iz].nsurfs):
            bldg_ptr.zone[iz].surf[is] = SURF()
            if bldg_ptr.zone[iz].surf[is] is None:
                pofdmpfile.write("ERROR: DElight Insufficient memory for SURFACE allocation\n")
                return -1
            struct_init("SURF", bldg_ptr.zone[iz].surf[is])
            /* Read and discard ZONE SURFACE DATA headings lines */
            if infile.readline(cInputLine) == -1: return -1
            if infile.readline(cInputLine) == -1: return -1
            if infile.readline(cInputLine) == -1: return -1
            # sscanf(cInputLine,"%*s %s\n",bldg_ptr->zone[iz]->surf[is]->name);
            parts = cInputLine.split()
            bldg_ptr.zone[iz].surf[is].name = parts[1]
            if infile.readline(cInputLine) == -1: return -1
            # sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->zone[iz]->surf[is]->azm_bs);
            parts = cInputLine.split()
            bldg_ptr.zone[iz].surf[is].azm_bs = float(parts[1])
            bldg_ptr.zone[iz].surf[is].azm_zs = bldg_ptr.zone[iz].surf[is].azm_bs - bldg_ptr.zone[iz].azm
            if infile.readline(cInputLine) == -1: return -1
            # sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->zone[iz]->surf[is]->tilt_bs);
            parts = cInputLine.split()
            bldg_ptr.zone[iz].surf[is].tilt_bs = float(parts[1])
            bldg_ptr.zone[iz].surf[is].tilt_zs = bldg_ptr.zone[iz].surf[is].tilt_bs
            if infile.readline(cInputLine) == -1: return -1
            # sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->zone[iz]->surf[is]->vis_refl);
            parts = cInputLine.split()
            bldg_ptr.zone[iz].surf[is].vis_refl = float(parts[1])
            if infile.readline(cInputLine) == -1: return -1
            # sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->zone[iz]->surf[is]->ext_vis_refl);
            parts = cInputLine.split()
            bldg_ptr.zone[iz].surf[is].ext_vis_refl = float(parts[1])
            if infile.readline(cInputLine) == -1: return -1
            # sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->zone[iz]->surf[is]->gnd_refl);
            parts = cInputLine.split()
            bldg_ptr.zone[iz].surf[is].gnd_refl = float(parts[1])
            /* Vertices in World Coordinate System coordinates */
            var iVertices: Int
            if infile.readline(cInputLine) == -1: return -1
            # sscanf(cInputLine,"%*s %d\n",&iVertices);
            parts = cInputLine.split()
            iVertices = int(parts[1])
            bldg_ptr.zone[iz].surf[is].nvertices = iVertices
            var p3TmpPt: BGL.point3
            var dTmpVertex: List[Float64] = List[Float64](NCOORDS)
            var ivert: Int
            for ivert in range(iVertices):
                if infile.readline(cInputLine) == -1: return -1
                /* tokenize the line label */
                token = cInputLine.split()[0]
                tokens = cInputLine.split()
                for icoord in range(NCOORDS):
                    token = tokens[icoord+1]
                    dTmpVertex[icoord] = float(token)
                p3TmpPt = BGL.point3(dTmpVertex[0], dTmpVertex[1], dTmpVertex[2])
                bldg_ptr.zone[iz].surf[is].vPt3VerticesWCS_OCCW.push_back(p3TmpPt)
            bldg_ptr.zone[iz].surf[is].v3List_WLC.push_back(bldg_ptr.zone[iz].surf[is].vPt3VerticesWCS_OCCW[2])
            bldg_ptr.zone[iz].surf[is].v3List_WLC.push_back(bldg_ptr.zone[iz].surf[is].vPt3VerticesWCS_OCCW[1])
            bldg_ptr.zone[iz].surf[is].v3List_WLC.push_back(bldg_ptr.zone[iz].surf[is].vPt3VerticesWCS_OCCW[0])
            for ivert in range(iVertices-1, 2, -1):
                bldg_ptr.zone[iz].surf[is].v3List_WLC.push_back(bldg_ptr.zone[iz].surf[is].vPt3VerticesWCS_OCCW[ivert])
            /* Read and discard SURFACE WINDOWS headings lines */
            if infile.readline(cInputLine) == -1: return -1
            if infile.readline(cInputLine) == -1: return -1
            /* Read window data */
            if infile.readline(cInputLine) == -1: return -1
            # sscanf(cInputLine,"%*s %d\n",&bldg_ptr->zone[iz]->surf[is]->nwndos);
            parts = cInputLine.split()
            bldg_ptr.zone[iz].surf[is].nwndos = int(parts[1])
            if bldg_ptr.zone[iz].surf[is].nwndos > MAX_SURF_WNDOS:
                pofdmpfile.write("ERROR: DElight exceeded maximum SURFACE WINDOWS limit of " + str(MAX_SURF_WNDOS) + "\n")
                return -1
            for iw in range(bldg_ptr.zone[iz].surf[is].nwndos):
                bldg_ptr.zone[iz].surf[is].wndo[iw] = WNDO()
                if bldg_ptr.zone[iz].surf[is].wndo[iw] is None:
                    pofdmpfile.write("ERROR: DElight Insufficient memory for WINDOW allocation\n")
                    return -1
                struct_init("WNDO", bldg_ptr.zone[iz].surf[is].wndo[iw])
                /* Read and discard WINDOW headings lines */
                if infile.readline(cInputLine) == -1: return -1
                if infile.readline(cInputLine) == -1: return -1
                if infile.readline(cInputLine) == -1: return -1
                # sscanf(cInputLine,"%*s %s\n",bldg_ptr->zone[iz]->surf[is]->wndo[iw]->name);
                parts = cInputLine.split()
                bldg_ptr.zone[iz].surf[is].wndo[iw].name = parts[1]
                if infile.readline(cInputLine) == -1: return -1
                # sscanf(cInputLine,"%*s %s\n",bldg_ptr->zone[iz]->surf[is]->wndo[iw]->glass_type);
                parts = cInputLine.split()
                bldg_ptr.zone[iz].surf[is].wndo[iw].glass_type = parts[1]
                if infile.readline(cInputLine) == -1: return -1
                # sscanf(cInputLine,"%*s %d\n",&bldg_ptr->zone[iz]->surf[is]->wndo[iw]->shade_flag);
                parts = cInputLine.split()
                bldg_ptr.zone[iz].surf[is].wndo[iw].shade_flag = int(parts[1])
                if bldg_ptr.zone[iz].surf[is].wndo[iw].shade_flag != 0:
                    if infile.readline(cInputLine) == -1: return -1
                    # sscanf(cInputLine,"%*s %s\n",bldg_ptr->zone[iz]->surf[is]->wndo[iw]->shade_type);
                    parts = cInputLine.split()
                    bldg_ptr.zone[iz].surf[is].wndo[iw].shade_type = parts[1]
                /* window overhang/fin zone shade depth (ft) */
                if infile.readline(cInputLine) == -1: return -1
                /* tokenize the line label */
                token = cInputLine.split()[0]
                tokens = cInputLine.split()
                for izshade_x in range(NZSHADES):
                    token = tokens[izshade_x+1]
                    bldg_ptr.zone[iz].surf[is].wndo[iw].zshade_x[izshade_x] = float(token)
                /* window overhang/fin zone shade distance from window (ft) */
                if infile.readline(cInputLine) == -1: return -1
                /* tokenize the line label */
                token = cInputLine.split()[0]
                tokens = cInputLine.split()
                for izshade_y in range(NZSHADES):
                    token = tokens[izshade_y+1]
                    bldg_ptr.zone[iz].surf[is].wndo[iw].zshade_y[izshade_y] = float(token)
                /* Vertices in World Coordinate System coordinates */
                if infile.readline(cInputLine) == -1: return -1
                # sscanf(cInputLine,"%*s %d\n",&iVertices);
                parts = cInputLine.split()
                iVertices = int(parts[1])
                bldg_ptr.zone[iz].surf[is].wndo[iw].nvertices = iVertices
                for ivert in range(iVertices):
                    if infile.readline(cInputLine) == -1: return -1
                    /* tokenize the line label */
                    token = cInputLine.split()[0]
                    tokens = cInputLine.split()
                    for icoord in range(NCOORDS):
                        token = tokens[icoord+1]
                        dTmpVertex[icoord] = float(token)
                    p3TmpPt = BGL.point3(dTmpVertex[0], dTmpVertex[1], dTmpVertex[2])
                    bldg_ptr.zone[iz].surf[is].wndo[iw].vPt3VerticesWCS_OCCW.push_back(p3TmpPt)
                bldg_ptr.zone[iz].surf[is].wndo[iw].v3List_WLC.push_back(bldg_ptr.zone[iz].surf[is].wndo[iw].vPt3VerticesWCS_OCCW[2])
                bldg_ptr.zone[iz].surf[is].wndo[iw].v3List_WLC.push_back(bldg_ptr.zone[iz].surf[is].wndo[iw].vPt3VerticesWCS_OCCW[1])
                bldg_ptr.zone[iz].surf[is].wndo[iw].v3List_WLC.push_back(bldg_ptr.zone[iz].surf[is].wndo[iw].vPt3VerticesWCS_OCCW[0])
                for ivert in range(iVertices-1, 2, -1):
                    bldg_ptr.zone[iz].surf[is].wndo[iw].v3List_WLC.push_back(bldg_ptr.zone[iz].surf[is].wndo[iw].vPt3VerticesWCS_OCCW[ivert])
                bldg_ptr.zone[iz].surf[is].wndo[iw].WLCWNDOInit(bldg_ptr.zone[iz].max_grid_node_area)
            /* Read and discard SURFACE CFS headings lines */
            if infile.readline(cInputLine) == -1: return -1
            if infile.readline(cInputLine) == -1: return -1
            /* Read CFS data */
            if infile.readline(cInputLine) == -1: return -1
            # sscanf(cInputLine,"%*s %d\n",&bldg_ptr->zone[iz]->surf[is]->ncfs);
            parts = cInputLine.split()
            bldg_ptr.zone[iz].surf[is].ncfs = int(parts[1])
            if bldg_ptr.zone[iz].surf[is].ncfs > MAX_SURF_CFS:
                pofdmpfile.write("ERROR: DElight exceeded maximum SURFACE CFS limit of " + str(MAX_SURF_CFS) + "\n")
                return -1
            for icfs in range(bldg_ptr.zone[iz].surf[is].ncfs):
                /* Read and discard CFS headings lines */
                if infile.readline(cInputLine) == -1: return -1
                if infile.readline(cInputLine) == -1: return -1
                /* Read and store CFS name line */
                var charCFSname: String = ""
                if infile.readline(cInputLine) == -1: return -1
                # sscanf(cInputLine,"%*s %s\n",charCFSname);
                parts = cInputLine.split()
                charCFSname = parts[1]
                var strCFSParameters: String
                var charCFSParameters: String = ""
                if infile.readline(cInputLine) == -1: return -1
                # sscanf(cInputLine,"%*s %s\n",charCFSParameters);
                parts = cInputLine.split()
                charCFSParameters = parts[1]
                strCFSParameters = charCFSParameters
                var dCFSrotation: Float64
                if infile.readline(cInputLine) == -1: return -1
                # sscanf(cInputLine,"%*s %lf\n",&dCFSrotation);
                parts = cInputLine.split()
                dCFSrotation = float(parts[1])
                /* CFS Vertices in World Coordinate System coordinates */
                if infile.readline(cInputLine) == -1: return -1
                # sscanf(cInputLine,"%*s %d\n",&iVertices);
                parts = cInputLine.split()
                iVertices = int(parts[1])
                var vPt3: List[BGL.point3] = List[BGL.point3]()
                for ivert in range(iVertices):
                    if infile.readline(cInputLine) == -1: return -1
                    /* tokenize the line label */
                    token = cInputLine.split()[0]
                    tokens = cInputLine.split()
                    for icoord in range(NCOORDS):
                        token = tokens[icoord+1]
                        dTmpVertex[icoord] = float(token)
                    p3TmpPt = BGL.point3(dTmpVertex[0], dTmpVertex[1], dTmpVertex[2])
                    vPt3.push_back(p3TmpPt)
                var vPt3WLCOrder: List[BGL.point3] = List[BGL.point3]()
                vPt3WLCOrder.push_back(vPt3[2])
                vPt3WLCOrder.push_back(vPt3[1])
                vPt3WLCOrder.push_back(vPt3[0])
                for ivert in range(vPt3.size()-1, 2, -1):
                    vPt3WLCOrder.push_back(vPt3[ivert])
                var iWLClistn: Int = vPt3WLCOrder.size()
                for ivert in range(iWLClistn):
                    p3TmpPt = vPt3WLCOrder[ivert]
                var pNewCFSSystem: CFSSystem = None
                for iCFSSysItem in range(bldg_ptr.zone[iz].surf[is].vpCFSSystem.size()):
                    if bldg_ptr.zone[iz].surf[is].vpCFSSystem[iCFSSysItem].TypeName() == strCFSParameters:
                        pNewCFSSystem = bldg_ptr.zone[iz].surf[is].vpCFSSystem[iCFSSysItem]
                        break
                if not pNewCFSSystem:
                    var lpCFSSystem: LumParam
                    if not SecretDecoderRing(lpCFSSystem, strCFSParameters):
                        pofdmpfile.write("ERROR: DElight Invalid CFS Parameter - " + lpCFSSystem.BadName + "\n")
                        return -1
                    lpCFSSystem.btdfHSResIn = 300
                    lpCFSSystem.btdfHSResOut = 2500
                    pNewCFSSystem = CFSSystem(strCFSParameters, lpCFSSystem)
                    bldg_ptr.zone[iz].surf[is].vpCFSSystem.push_back(pNewCFSSystem)
                var pNewCFSSurface: CFSSurface = CFSSurface(bldg_ptr.zone[iz].surf[is], strCFSParameters, HemiSphiral(), dCFSrotation, vPt3WLCOrder, bldg_ptr.zone[iz].max_grid_node_area)
                bldg_ptr.zone[iz].surf[is].cfs[icfs] = pNewCFSSurface
            bldg_ptr.zone[iz].surf[is].WLCSURFInit(bldg_ptr.zone[iz].surf[is].name, bldg_ptr.zone[iz].max_grid_node_area)
        /* Read and discard REFERENCE POINT headings lines */
        if infile.readline(cInputLine) == -1: return -1
        if infile.readline(cInputLine) == -1: return -1
        /* Read reference point data */
        if infile.readline(cInputLine) == -1: return -1
        # sscanf(cInputLine,"%*s %d\n",&bldg_ptr->zone[iz]->nrefpts);
        parts = cInputLine.split()
        bldg_ptr.zone[iz].nrefpts = int(parts[1])
        if bldg_ptr.zone[iz].nrefpts > MAX_REF_PTS:
            pofdmpfile.write("ERROR: DElight exceeded maximum ZONE REFERENCE POINTS limit of " + str(MAX_REF_PTS) + "\n")
            return -1
        for irp in range(bldg_ptr.zone[iz].nrefpts):
            bldg_ptr.zone[iz].ref_pt[irp] = REFPT()
            if bldg_ptr.zone[iz].ref_pt[irp] is None:
                pofdmpfile.write("ERROR: DElight Insufficient memory for REFERENCE POINT allocation\n")
                return -1
            struct_init("REFPT", bldg_ptr.zone[iz].ref_pt[irp])
            /* Read and discard REFERENCE POINT DATA headings lines */
            if infile.readline(cInputLine) == -1: return -1
            if infile.readline(cInputLine) == -1: return -1
            if infile.readline(cInputLine) == -1: return -1
            # sscanf(cInputLine,"%*s %s\n",bldg_ptr->zone[iz]->ref_pt[irp]->name);
            parts = cInputLine.split()
            bldg_ptr.zone[iz].ref_pt[irp].name = parts[1]
            /* reference point in world system coordinates */
            if infile.readline(cInputLine) == -1: return -1
            /* tokenize the line label */
            token = cInputLine.split()[0]
            tokens = cInputLine.split()
            for icoord in range(NCOORDS):
                token = tokens[icoord+1]
                bldg_ptr.zone[iz].ref_pt[irp].zs[icoord] = float(token)
                bldg_ptr.zone[iz].ref_pt[irp].bs[icoord] = bldg_ptr.zone[iz].ref_pt[irp].zs[icoord]
            if infile.readline(cInputLine) == -1: return -1
            # sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->zone[iz]->ref_pt[irp]->zone_frac);
            parts = cInputLine.split()
            bldg_ptr.zone[iz].ref_pt[irp].zone_frac = float(parts[1])
            if infile.readline(cInputLine) == -1: return -1
            # sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->zone[iz]->ref_pt[irp]->lt_set_pt);
            parts = cInputLine.split()
            bldg_ptr.zone[iz].ref_pt[irp].lt_set_pt = float(parts[1])
            if infile.readline(cInputLine) == -1: return -1
            # sscanf(cInputLine,"%*s %d\n",&bldg_ptr->zone[iz]->ref_pt[irp]->lt_ctrl_type);
            parts = cInputLine.split()
            bldg_ptr.zone[iz].ref_pt[irp].lt_ctrl_type = int(parts[1])
            /* Allocate memory for window luminance factors for each ref_pt<->wndo combination */
            for is in range(bldg_ptr.zone[iz].nsurfs):
                for iw in range(bldg_ptr.zone[iz].surf[is].nwndos):
                    bldg_ptr.zone[iz].ref_pt[irp].wlum[is][iw] = WLUM()
                    if bldg_ptr.zone[iz].ref_pt[irp].wlum[is][iw] is None:
                        pofdmpfile.write("ERROR: DElight Insufficient memory for WINDOW LUMINANCE allocation\n")
                        return -1
                    struct_init("WLUM", bldg_ptr.zone[iz].ref_pt[irp].wlum[is][iw])
    /* Read and discard BUILDING SHADES headings lines */
    if infile.readline(cInputLine) == -1: return -1
    if infile.readline(cInputLine) == -1: return -1
    /* Read building shade data */
    if infile.readline(cInputLine) == -1: return -1
    # sscanf(cInputLine,"%*s %d\n",&bldg_ptr->nbshades);
    parts = cInputLine.split()
    bldg_ptr.nbshades = int(parts[1])
    if bldg_ptr.nbshades > MAX_BLDG_SHADES:
        pofdmpfile.write("ERROR: DElight exceeded maximum BUILDING SHADES limit of " + str(MAX_BLDG_SHADES) + "\n")
        return -1
    for ish in range(bldg_ptr.nbshades):
        bldg_ptr.bshade[ish] = BSHADE()
        if bldg_ptr.bshade[ish] is None:
            pofdmpfile.write("ERROR: DElight Insufficient memory for BUILDING SHADE allocation\n")
            return -1
        struct_init("BSHADE", bldg_ptr.bshade[ish])
        /* Read and discard BUILDING SHADE headings lines */
        if infile.readline(cInputLine) == -1: return -1
        if infile.readline(cInputLine) == -1: return -1
        if infile.readline(cInputLine) == -1: return -1
        # sscanf(cInputLine,"%*s %s\n",bldg_ptr->bshade[ish]->name);
        parts = cInputLine.split()
        bldg_ptr.bshade[ish].name = parts[1]
        /* bldg shade origin in bldg system coordinates */
        if infile.readline(cInputLine) == -1: return -1
        /* tokenize the line label */
        token = cInputLine.split()[0]
        tokens = cInputLine.split()
        for icoord in range(NCOORDS):
            token = tokens[icoord+1]
            bldg_ptr.bshade[ish].origin[icoord] = float(token)
        if infile.readline(cInputLine) == -1: return -1
        # sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->bshade[ish]->height);
        parts = cInputLine.split()
        bldg_ptr.bshade[ish].height = float(parts[1])
        if infile.readline(cInputLine) == -1: return -1
        # sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->bshade[ish]->width);
        parts = cInputLine.split()
        bldg_ptr.bshade[ish].width = float(parts[1])
        if infile.readline(cInputLine) == -1: return -1
        # sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->bshade[ish]->azm);
        parts = cInputLine.split()
        bldg_ptr.bshade[ish].azm = float(parts[1])
        if infile.readline(cInputLine) == -1: return -1
        # sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->bshade[ish]->tilt);
        parts = cInputLine.split()
        bldg_ptr.bshade[ish].tilt = float(parts[1])
        if infile.readline(cInputLine) == -1: return -1
        # sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->bshade[ish]->vis_refl);
        parts = cInputLine.split()
        bldg_ptr.bshade[ish].vis_refl = float(parts[1])
        if infile.readline(cInputLine) == -1: return -1
        # sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->bshade[ish]->gnd_refl);
        parts = cInputLine.split()
        bldg_ptr.bshade[ish].gnd_refl = float(parts[1])
    return 0
}
/****************************** subroutine LoadLibDataFromEPlus *****************************/
/* Loads DElight Library data from a disk file generated from EnergyPlus data. */
/****************************** subroutine LoadLibDataFromEPlus *****************************/
def LoadLibDataFromEPlus(
    lib_ptr: LIB,          /* library structure pointer */
    infile: FileReader,    /* pointer to library data file */
    pofdmpfile: FileWriter /* ptr to dump file */
) -> Int:
{
    var cInputLine: String = "";    /* Input line */
    var ig: Int;                    /* indexes */
    /* Read and discard heading line */
    if infile.readline(cInputLine) == -1: return -1
    /* Read and discard GLASS TYPES headings lines */
    if infile.readline(cInputLine) == -1: return -1
    if infile.readline(cInputLine) == -1: return -1
    /* Read glass type data */
    if infile.readline(cInputLine) == -1: return -1
    # sscanf(cInputLine,"%*s %d\n",&lib_ptr->nglass);
    var parts: List[String] = cInputLine.split()
    lib_ptr.nglass = int(parts[1])
    if lib_ptr.nglass > MAX_LIB_COMPS:
        pofdmpfile.write("ERROR: DElight exceeded maximum GLASS TYPES limit of " + str(MAX_LIB_COMPS) + "\n")
        return -1
    for ig in range(lib_ptr.nglass):
        lib_ptr.glass[ig] = GLASS()
        if lib_ptr.glass[ig] is None:
            pofdmpfile.write("ERROR: DElight Insufficient memory for GLASS allocation\n")
            return -1
        struct_init("GLASS", lib_ptr.glass[ig])
        /* Read and discard GLASS TYPE DATA headings lines */
        if infile.readline(cInputLine) == -1: return -1
        if infile.readline(cInputLine) == -1: return -1
        if infile.readline(cInputLine) == -1: return -1
        # sscanf(cInputLine,"%*s %s\n",lib_ptr->glass[ig]->name);
        parts = cInputLine.split()
        lib_ptr.glass[ig].name = parts[1]
        if infile.readline(cInputLine) == -1: return -1
        # sscanf(cInputLine,"%*s %lf\n",&lib_ptr->glass[ig]->EPlusDiffuse_Trans);
        parts = cInputLine.split()
        lib_ptr.glass[ig].EPlusDiffuse_Trans = float(parts[1])
        if infile.readline(cInputLine) == -1: return -1
        # sscanf(cInputLine,"%*s %lf\n",&lib_ptr->glass[ig]->inside_refl);
        parts = cInputLine.split()
        lib_ptr.glass[ig].inside_refl = float(parts[1])
        if infile.readline(cInputLine) == -1: return -1
        # sscanf(cInputLine,"%*s %lf\n",&lib_ptr->glass[ig]->EPlusCoef[0]);
        parts = cInputLine.split()
        lib_ptr.glass[ig].EPlusCoef[0] = float(parts[1])
        if infile.readline(cInputLine) == -1: return -1
        # sscanf(cInputLine,"%*s %lf\n",&lib_ptr->glass[ig]->EPlusCoef[1]);
        parts = cInputLine.split()
        lib_ptr.glass[ig].EPlusCoef[1] = float(parts[1])
        if infile.readline(cInputLine) == -1: return -1
        # sscanf(cInputLine,"%*s %lf\n",&lib_ptr->glass[ig]->EPlusCoef[2]);
        parts = cInputLine.split()
        lib_ptr.glass[ig].EPlusCoef[2] = float(parts[1])
        if infile.readline(cInputLine) == -1: return -1
        # sscanf(cInputLine,"%*s %lf\n",&lib_ptr->glass[ig]->EPlusCoef[3]);
        parts = cInputLine.split()
        lib_ptr.glass[ig].EPlusCoef[3] = float(parts[1])
        if infile.readline(cInputLine) == -1: return -1
        # sscanf(cInputLine,"%*s %lf\n",&lib_ptr->glass[ig]->EPlusCoef[4]);
        parts = cInputLine.split()
        lib_ptr.glass[ig].EPlusCoef[4] = float(parts[1])
        if infile.readline(cInputLine) == -1: return -1
        # sscanf(cInputLine,"%*s %lf\n",&lib_ptr->glass[ig]->EPlusCoef[5]);
        parts = cInputLine.split()
        lib_ptr.glass[ig].EPlusCoef[5] = float(parts[1])
    return 0
}
/****************************** subroutine LoadDFs *****************************/
/* Loads DElight calculated Daylight Factor data from a disk file */
/****************************** subroutine LoadDFs *****************************/
def LoadDFs(
    bldg_ptr: BLDG,      /* building structure pointer */
    infile: FileReader    /* pointer to building data file */
) -> Int:
{
    var cInputLine: String = "";    /* Input line */
    var token: String = "";         /* Input token pointer */
    /* Read and discard the first two lines */
    if infile.readline(cInputLine) == -1: return -1
    if infile.readline(cInputLine) == -1: return -1
    /* Read and discard ZONES headings lines */
    if infile.readline(cInputLine) == -1: return -1
    if infile.readline(cInputLine) == -1: return -1
    /* Read zone data */
    if infile.readline(cInputLine) == -1: return -1
    # sscanf(cInputLine,"%*s %d\n",&bldg_ptr->nzones);
    var parts: List[String] = cInputLine.split()
    bldg_ptr.nzones = int(parts[1])
    for iz in range(bldg_ptr.nzones):
        /* Read and discard ZONE headings lines */
        if infile.readline(cInputLine) == -1: return -1
        if infile.readline(cInputLine) == -1: return -1
        if infile.readline(cInputLine) == -1: return -1
        /* Read and discard REFERENCE POINT headings lines */
        if infile.readline(cInputLine) == -1: return -1
        if infile.readline(cInputLine) == -1: return -1
        /* Read reference point data */
        if infile.readline(cInputLine) == -1: return -1
        # sscanf(cInputLine,"%*s %d\n",&bldg_ptr->zone[iz]->nrefpts);
        parts = cInputLine.split()
        bldg_ptr.zone[iz].nrefpts = int(parts[1])
        for irp in range(bldg_ptr.zone[iz].nrefpts):
            /* Read and discard REFERENCE POINT DATA headings lines */
            if infile.readline(cInputLine) == -1: return -1
            if infile.readline(cInputLine) == -1: return -1
            if infile.readline(cInputLine) == -1: return -1
            /* Read Reference_Point_Daylight_Factor_for_Overcast_Sky lines */
            if infile.readline(cInputLine) == -1: return -1
            if infile.readline(cInputLine) == -1: return -1
            # sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->zone[iz]->ref_pt[irp]->dfskyo);
            parts = cInputLine.split()
            bldg_ptr.zone[iz].ref_pt[irp].dfskyo = float(parts[1])
            if infile.readline(cInputLine) == -1: return -1
            if infile.readline(cInputLine) == -1: return -1
            if infile.readline(cInputLine) == -1: return -1
            /* Read the data for Reference Point Daylight Factors for Clear Sky */
            var isunalt: Int
            for isunalt in range(NPHS):
                if infile.readline(cInputLine) == -1: return -1
                /* tokenize the line label */
                token = cInputLine.split()[0]
                var tokens: List[String] = cInputLine.split()
                for isunazm in range(NTHS):
                    token = tokens[isunazm+1]
                    bldg_ptr.zone[iz].ref_pt[irp].dfsky[isunalt][isunazm] = float(token)
            if infile.readline(cInputLine) == -1: return -1
            if infile.readline(cInputLine) == -1: return -1
            if infile.readline(cInputLine) == -1: return -1
            /* Read the data for Reference Point Daylight Factors for Clear Sun */
            for isunalt in range(NPHS):
                if infile.readline(cInputLine) == -1: return -1
                /* tokenize the line label */
                token = cInputLine.split()[0]
                tokens = cInputLine.split()
                for isunazm in range(NTHS):
                    token = tokens[isunazm+1]
                    bldg_ptr.zone[iz].ref_pt[irp].dfsun[isunalt][isunazm] = float(token)
    return 0
}