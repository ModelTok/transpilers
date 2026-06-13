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
// #pragma warning(disable:4786) // Mojo does not have pragma
from BGL import *   // BGL namespace as BGL
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
from Loaddata import *
from struct import *
from geom import *
/****************************** subroutine load_bldg *****************************/
/* Loads a building data file (*.in) from disk into an initialized bldg structure. */
/****************************** subroutine load_bldg *****************************/
def load_bldg(
    bldg_ptr: BLDG*,     /* building structure pointer */
    infile: File,        /* pointer to building data file */
    pofdmpfile: File*)   /* ptr to dump file */
-> Int32:
{
    var cInputLine: String = " " * (MAX_CHAR_LINE + 1)  /* Input line */
    var token: String = ""                               /* Input token pointer */
    var icoord: Int32 = 0
    var im: Int32 = 0
    var iz: Int32 = 0
    var ils: Int32 = 0
    var is: Int32 = 0
    var iw: Int32 = 0
    var ish: Int32 = 0
    var irp: Int32 = 0
    var ihr: Int32 = 0   /* indexes */
    var izshade_x: Int32 = 0
    var izshade_y: Int32 = 0   /* indexes */
    /* Read and discard the second heading line (first line is read in DElight2() main */
    cInputLine = infile.read_line()
    if cInputLine is None: return -1
    /* Read site data */
    cInputLine = infile.read_line()
    if cInputLine is None: return -1
    // sscanf(cInputLine,"%*s %s\n",bldg_ptr->name)
    var parts = cInputLine.split(" ")
    if parts.len >= 2:
        bldg_ptr.name = parts[1]
    cInputLine = infile.read_line()
    if cInputLine is None: return -1
    // sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->lat)
    parts = cInputLine.split(" ")
    if parts.len >= 2:
        bldg_ptr.lat = Float64(parts[1])
    cInputLine = infile.read_line()
    if cInputLine is None: return -1
    // sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->lon)
    parts = cInputLine.split(" ")
    if parts.len >= 2:
        bldg_ptr.lon = Float64(parts[1])
    cInputLine = infile.read_line()
    if cInputLine is None: return -1
    // sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->alt)
    parts = cInputLine.split(" ")
    if parts.len >= 2:
        bldg_ptr.alt = Float64(parts[1])
    cInputLine = infile.read_line()
    if cInputLine is None: return -1
    // sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->azm)
    parts = cInputLine.split(" ")
    if parts.len >= 2:
        bldg_ptr.azm = Float64(parts[1])
    cInputLine = infile.read_line()
    if cInputLine is None: return -1
    // sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->timezone)
    parts = cInputLine.split(" ")
    if parts.len >= 2:
        bldg_ptr.timezone = Float64(parts[1])
    /* monthly atmospheric moisture */
    cInputLine = infile.read_line()
    if cInputLine is None: return -1
    /* tokenize the line label */
    token = cInputLine.split(" ")[0]  // actually we need strtok behavior, use split
    var tokens = cInputLine.split(" ")
    for im in range(MONTHS):
        token = tokens[im + 1]  // skip label
        bldg_ptr.atmmoi[im] = Float64(token)
    /* monthly atmospheric turbidity */
    cInputLine = infile.read_line()
    if cInputLine is None: return -1
    /* tokenize the line label */
    tokens = cInputLine.split(" ")
    for im in range(MONTHS):
        token = tokens[im + 1]
        bldg_ptr.atmtur[im] = Float64(token)
    /* Read and discard ZONES headings lines */
    cInputLine = infile.read_line()
    if cInputLine is None: return -1
    cInputLine = infile.read_line()
    if cInputLine is None: return -1
    /* Read zone data */
    cInputLine = infile.read_line()
    if cInputLine is None: return -1
    // sscanf(cInputLine,"%*s %d\n",&bldg_ptr->nzones)
    parts = cInputLine.split(" ")
    if parts.len >= 2:
        bldg_ptr.nzones = Int32(parts[1])
    for iz in range(bldg_ptr.nzones):
        bldg_ptr.zone[iz] = ZONE()
        if bldg_ptr.zone[iz] is None:
            pofdmpfile.write("ERROR: DElight Insufficient memory for ZONE allocation\n")
            return -1
        struct_init("ZONE", cast[Char8*](bldg_ptr.zone[iz]))
        /* Read and discard ZONE headings lines */
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        // sscanf(cInputLine,"%*s %s\n",bldg_ptr->zone[iz]->name)
        parts = cInputLine.split(" ")
        if parts.len >= 2:
            bldg_ptr.zone[iz].name = parts[1]
        /* zone origin in bldg system coordinates */
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        /* tokenize the line label */
        tokens = cInputLine.split(" ")
        for icoord in range(NCOORDS):
            token = tokens[icoord + 1]
            bldg_ptr.zone[iz].origin[icoord] = Float64(token)
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        // sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->zone[iz]->azm)
        parts = cInputLine.split(" ")
        if parts.len >= 2:
            bldg_ptr.zone[iz].azm = Float64(parts[1])
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        // sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->zone[iz]->mult)
        parts = cInputLine.split(" ")
        if parts.len >= 2:
            bldg_ptr.zone[iz].mult = Float64(parts[1])
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        // sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->zone[iz]->flarea)
        parts = cInputLine.split(" ")
        if parts.len >= 2:
            bldg_ptr.zone[iz].flarea = Float64(parts[1])
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        // sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->zone[iz]->volume)
        parts = cInputLine.split(" ")
        if parts.len >= 2:
            bldg_ptr.zone[iz].volume = Float64(parts[1])
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        // sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->zone[iz]->lighting)
        parts = cInputLine.split(" ")
        if parts.len >= 2:
            bldg_ptr.zone[iz].lighting = Float64(parts[1])
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        // sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->zone[iz]->min_power)
        parts = cInputLine.split(" ")
        if parts.len >= 2:
            bldg_ptr.zone[iz].min_power = Float64(parts[1])
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        // sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->zone[iz]->min_light)
        parts = cInputLine.split(" ")
        if parts.len >= 2:
            bldg_ptr.zone[iz].min_light = Float64(parts[1])
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        // sscanf(cInputLine,"%*s %d\n",&bldg_ptr->zone[iz]->lt_ctrl_steps)
        parts = cInputLine.split(" ")
        if parts.len >= 2:
            bldg_ptr.zone[iz].lt_ctrl_steps = Int32(parts[1])
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        // sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->zone[iz]->lt_ctrl_prob)
        parts = cInputLine.split(" ")
        if parts.len >= 2:
            bldg_ptr.zone[iz].lt_ctrl_prob = Float64(parts[1])
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        // sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->zone[iz]->view_azm)
        parts = cInputLine.split(" ")
        if parts.len >= 2:
            bldg_ptr.zone[iz].view_azm = Float64(parts[1])
        /* Read and discard ZONE LIGHTING SCHEDULE headings lines */
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        /* Read lighting schedule data */
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        // sscanf(cInputLine,"%*s %d\n",&bldg_ptr->zone[iz]->nltsch)
        parts = cInputLine.split(" ")
        if parts.len >= 2:
            bldg_ptr.zone[iz].nltsch = Int32(parts[1])
        for ils in range(bldg_ptr.zone[iz].nltsch):
            bldg_ptr.zone[iz].ltsch[ils] = LTSCH()
            if bldg_ptr.zone[iz].ltsch[ils] is None:
                pofdmpfile.write("ERROR: DElight Insufficient memory for LIGHT SCHEDULE allocation\n")
                return -1
            struct_init("LTSCH", cast[Char8*](bldg_ptr.zone[iz].ltsch[ils]))
            /* Read and discard LIGHTING SCHEDULE DATA headings lines */
            cInputLine = infile.read_line()
            if cInputLine is None: return -1
            cInputLine = infile.read_line()
            if cInputLine is None: return -1
            cInputLine = infile.read_line()
            if cInputLine is None: return -1
            // sscanf(cInputLine,"%*s %s\n",bldg_ptr->zone[iz]->ltsch[ils]->name)
            parts = cInputLine.split(" ")
            if parts.len >= 2:
                bldg_ptr.zone[iz].ltsch[ils].name = parts[1]
            cInputLine = infile.read_line()
            if cInputLine is None: return -1
            // sscanf(cInputLine,"%*s %d\n",&bldg_ptr->zone[iz]->ltsch[ils]->mon_begin)
            parts = cInputLine.split(" ")
            if parts.len >= 2:
                bldg_ptr.zone[iz].ltsch[ils].mon_begin = Int32(parts[1])
            cInputLine = infile.read_line()
            if cInputLine is None: return -1
            // sscanf(cInputLine,"%*s %d\n",&bldg_ptr->zone[iz]->ltsch[ils]->day_begin)
            parts = cInputLine.split(" ")
            if parts.len >= 2:
                bldg_ptr.zone[iz].ltsch[ils].day_begin = Int32(parts[1])
            cInputLine = infile.read_line()
            if cInputLine is None: return -1
            // sscanf(cInputLine,"%*s %d\n",&bldg_ptr->zone[iz]->ltsch[ils]->mon_end)
            parts = cInputLine.split(" ")
            if parts.len >= 2:
                bldg_ptr.zone[iz].ltsch[ils].mon_end = Int32(parts[1])
            cInputLine = infile.read_line()
            if cInputLine is None: return -1
            // sscanf(cInputLine,"%*s %d\n",&bldg_ptr->zone[iz]->ltsch[ils]->day_end)
            parts = cInputLine.split(" ")
            if parts.len >= 2:
                bldg_ptr.zone[iz].ltsch[ils].day_end = Int32(parts[1])
            cInputLine = infile.read_line()
            if cInputLine is None: return -1
            // sscanf(cInputLine,"%*s %d\n",&bldg_ptr->zone[iz]->ltsch[ils]->dow_begin)
            parts = cInputLine.split(" ")
            if parts.len >= 2:
                bldg_ptr.zone[iz].ltsch[ils].dow_begin = Int32(parts[1])
            cInputLine = infile.read_line()
            if cInputLine is None: return -1
            // sscanf(cInputLine,"%*s %d\n",&bldg_ptr->zone[iz]->ltsch[ils]->dow_end)
            parts = cInputLine.split(" ")
            if parts.len >= 2:
                bldg_ptr.zone[iz].ltsch[ils].dow_end = Int32(parts[1])
            /* lighting schedule hourly fractions */
            cInputLine = infile.read_line()
            if cInputLine is None: return -1
            /* tokenize the line label */
            tokens = cInputLine.split(" ")
            for ihr in range(HOURS):
                token = tokens[ihr + 1]
                bldg_ptr.zone[iz].ltsch[ils].frac[ihr] = Float64(token)
        /* Read and discard ZONE SURFACES headings lines */
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        /* Read surface data */
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        // sscanf(cInputLine,"%*s %d\n",&bldg_ptr->zone[iz]->nsurfs)
        parts = cInputLine.split(" ")
        if parts.len >= 2:
            bldg_ptr.zone[iz].nsurfs = Int32(parts[1])
        for is in range(bldg_ptr.zone[iz].nsurfs):
            bldg_ptr.zone[iz].surf[is] = SURF()
            if bldg_ptr.zone[iz].surf[is] is None:
                pofdmpfile.write("ERROR: DElight Insufficient memory for SURFACE allocation\n")
                return -1
            struct_init("SURF", cast[Char8*](bldg_ptr.zone[iz].surf[is]))
            /* Read and discard ZONE SURFACE DATA headings lines */
            cInputLine = infile.read_line()
            if cInputLine is None: return -1
            cInputLine = infile.read_line()
            if cInputLine is None: return -1
            cInputLine = infile.read_line()
            if cInputLine is None: return -1
            // sscanf(cInputLine,"%*s %s\n",bldg_ptr->zone[iz]->surf[is]->name)
            parts = cInputLine.split(" ")
            if parts.len >= 2:
                bldg_ptr.zone[iz].surf[is].name = parts[1]
            /* surface origin in zone system coordinates */
            cInputLine = infile.read_line()
            if cInputLine is None: return -1
            /* tokenize the line label */
            tokens = cInputLine.split(" ")
            for icoord in range(NCOORDS):
                token = tokens[icoord + 1]
                bldg_ptr.zone[iz].surf[is].origin[icoord] = Float64(token)
            cInputLine = infile.read_line()
            if cInputLine is None: return -1
            // sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->zone[iz]->surf[is]->height)
            parts = cInputLine.split(" ")
            if parts.len >= 2:
                bldg_ptr.zone[iz].surf[is].height = Float64(parts[1])
            cInputLine = infile.read_line()
            if cInputLine is None: return -1
            // sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->zone[iz]->surf[is]->width)
            parts = cInputLine.split(" ")
            if parts.len >= 2:
                bldg_ptr.zone[iz].surf[is].width = Float64(parts[1])
            cInputLine = infile.read_line()
            if cInputLine is None: return -1
            // sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->zone[iz]->surf[is]->azm_zs)
            parts = cInputLine.split(" ")
            if parts.len >= 2:
                bldg_ptr.zone[iz].surf[is].azm_zs = Float64(parts[1])
            cInputLine = infile.read_line()
            if cInputLine is None: return -1
            // sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->zone[iz]->surf[is]->tilt_zs)
            parts = cInputLine.split(" ")
            if parts.len >= 2:
                bldg_ptr.zone[iz].surf[is].tilt_zs = Float64(parts[1])
            cInputLine = infile.read_line()
            if cInputLine is None: return -1
            // sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->zone[iz]->surf[is]->vis_refl)
            parts = cInputLine.split(" ")
            if parts.len >= 2:
                bldg_ptr.zone[iz].surf[is].vis_refl = Float64(parts[1])
            cInputLine = infile.read_line()
            if cInputLine is None: return -1
            // sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->zone[iz]->surf[is]->ext_vis_refl)
            parts = cInputLine.split(" ")
            if parts.len >= 2:
                bldg_ptr.zone[iz].surf[is].ext_vis_refl = Float64(parts[1])
            cInputLine = infile.read_line()
            if cInputLine is None: return -1
            // sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->zone[iz]->surf[is]->gnd_refl)
            parts = cInputLine.split(" ")
            if parts.len >= 2:
                bldg_ptr.zone[iz].surf[is].gnd_refl = Float64(parts[1])
            cInputLine = infile.read_line()
            if cInputLine is None: return -1
            // sscanf(cInputLine,"%*s %d\n",&bldg_ptr->zone[iz]->surf[is]->type)
            parts = cInputLine.split(" ")
            if parts.len >= 2:
                bldg_ptr.zone[iz].surf[is].type = Int32(parts[1])
            /* Read and discard SURFACE WINDOWS headings lines */
            cInputLine = infile.read_line()
            if cInputLine is None: return -1
            cInputLine = infile.read_line()
            if cInputLine is None: return -1
            /* Transform surface geometry here for use in CFSSurface construction */
            /* locate all surface vertices in surface coord system */
            rectan(bldg_ptr.zone[iz].surf[is].height, bldg_ptr.zone[iz].surf[is].width, bldg_ptr.zone[iz].surf[is].vert)
            /* locate all surface vertices in zone coord system */
            walloc(bldg_ptr.zone[iz].surf[is].vert, bldg_ptr.zone[iz].surf[is].origin, bldg_ptr.zone[iz].surf[is].azm_zs, bldg_ptr.zone[iz].surf[is].tilt_zs)
            /* locate all surface vertices in bldg coord system */
            zonloc(bldg_ptr.zone[iz].surf[is].vert, bldg_ptr.zone[iz].origin, bldg_ptr.zone[iz].azm)
            /* calculate surface azimuth and tilt in bldg coord system */
            apol(bldg_ptr.zone[iz].surf[is].vert, &bldg_ptr.zone[iz].surf[is].azm_bs, &bldg_ptr.zone[iz].surf[is].tilt_bs)
            /* Read window data */
            cInputLine = infile.read_line()
            if cInputLine is None: return -1
            // sscanf(cInputLine,"%*s %d\n",&bldg_ptr->zone[iz]->surf[is]->nwndos)
            parts = cInputLine.split(" ")
            if parts.len >= 2:
                bldg_ptr.zone[iz].surf[is].nwndos = Int32(parts[1])
            for iw in range(bldg_ptr.zone[iz].surf[is].nwndos):
                bldg_ptr.zone[iz].surf[is].wndo[iw] = WNDO()
                if bldg_ptr.zone[iz].surf[is].wndo[iw] is None:
                    pofdmpfile.write("ERROR: DElight Insufficient memory for WINDOW allocation\n")
                    return -1
                struct_init("WNDO", cast[Char8*](bldg_ptr.zone[iz].surf[is].wndo[iw]))
                /* Read and discard WINDOW headings lines */
                cInputLine = infile.read_line()
                if cInputLine is None: return -1
                cInputLine = infile.read_line()
                if cInputLine is None: return -1
                cInputLine = infile.read_line()
                if cInputLine is None: return -1
                // sscanf(cInputLine,"%*s %s\n",bldg_ptr->zone[iz]->surf[is]->wndo[iw]->name)
                parts = cInputLine.split(" ")
                if parts.len >= 2:
                    bldg_ptr.zone[iz].surf[is].wndo[iw].name = parts[1]
                /* window origin in surface system coordinates */
                cInputLine = infile.read_line()
                if cInputLine is None: return -1
                /* tokenize the line label */
                tokens = cInputLine.split(" ")
                for icoord in range(NCOORDS):
                    token = tokens[icoord + 1]
                    bldg_ptr.zone[iz].surf[is].wndo[iw].origin[icoord] = Float64(token)
                cInputLine = infile.read_line()
                if cInputLine is None: return -1
                // sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->zone[iz]->surf[is]->wndo[iw]->height)
                parts = cInputLine.split(" ")
                if parts.len >= 2:
                    bldg_ptr.zone[iz].surf[is].wndo[iw].height = Float64(parts[1])
                cInputLine = infile.read_line()
                if cInputLine is None: return -1
                // sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->zone[iz]->surf[is]->wndo[iw]->width)
                parts = cInputLine.split(" ")
                if parts.len >= 2:
                    bldg_ptr.zone[iz].surf[is].wndo[iw].width = Float64(parts[1])
                cInputLine = infile.read_line()
                if cInputLine is None: return -1
                // sscanf(cInputLine,"%*s %s\n",bldg_ptr->zone[iz]->surf[is]->wndo[iw]->glass_type)
                parts = cInputLine.split(" ")
                if parts.len >= 2:
                    bldg_ptr.zone[iz].surf[is].wndo[iw].glass_type = parts[1]
                cInputLine = infile.read_line()
                if cInputLine is None: return -1
                // sscanf(cInputLine,"%*s %d\n",&bldg_ptr->zone[iz]->surf[is]->wndo[iw]->shade_flag)
                parts = cInputLine.split(" ")
                if parts.len >= 2:
                    bldg_ptr.zone[iz].surf[is].wndo[iw].shade_flag = Int32(parts[1])
                if bldg_ptr.zone[iz].surf[is].wndo[iw].shade_flag != 0:
                    cInputLine = infile.read_line()
                    if cInputLine is None: return -1
                    // sscanf(cInputLine,"%*s %s\n",bldg_ptr->zone[iz]->surf[is]->wndo[iw]->shade_type)
                    parts = cInputLine.split(" ")
                    if parts.len >= 2:
                        bldg_ptr.zone[iz].surf[is].wndo[iw].shade_type = parts[1]
                /* window overhang/fin zone shade depth (ft) */
                cInputLine = infile.read_line()
                if cInputLine is None: return -1
                /* tokenize the line label */
                tokens = cInputLine.split(" ")
                for izshade_x in range(NZSHADES):
                    token = tokens[izshade_x + 1]
                    bldg_ptr.zone[iz].surf[is].wndo[iw].zshade_x[izshade_x] = Float64(token)
                /* window overhang/fin zone shade distance from window (ft) */
                cInputLine = infile.read_line()
                if cInputLine is None: return -1
                /* tokenize the line label */
                tokens = cInputLine.split(" ")
                for izshade_y in range(NZSHADES):
                    token = tokens[izshade_y + 1]
                    bldg_ptr.zone[iz].surf[is].wndo[iw].zshade_y[izshade_y] = Float64(token)
            /* Read and discard SURFACE CFS headings lines */
            cInputLine = infile.read_line()
            if cInputLine is None: return -1
            cInputLine = infile.read_line()
            if cInputLine is None: return -1
            /* Read CFS data */
            cInputLine = infile.read_line()
            if cInputLine is None: return -1
            // sscanf(cInputLine,"%*s %d\n",&bldg_ptr->zone[iz]->surf[is]->ncfs)
            parts = cInputLine.split(" ")
            if parts.len >= 2:
                bldg_ptr.zone[iz].surf[is].ncfs = Int32(parts[1])
            for icfs in range(bldg_ptr.zone[iz].surf[is].ncfs):
                /* Read and discard CFS headings lines */
                cInputLine = infile.read_line()
                if cInputLine is None: return -1
                cInputLine = infile.read_line()
                if cInputLine is None: return -1
                /* Read and store CFS name line */
                var charCFSname: String = " " * (MAX_CHAR_UNAME + 1)
                cInputLine = infile.read_line()
                if cInputLine is None: return -1
                // sscanf(cInputLine,"%*s %s\n",charCFSname)
                parts = cInputLine.split(" ")
                if parts.len >= 2:
                    charCFSname = parts[1]
                /* CFS origin in surface system coordinates */
                var dCFSorigin: Float64[NCOORDS]
                cInputLine = infile.read_line()
                if cInputLine is None: return -1
                /* tokenize the line label */
                tokens = cInputLine.split(" ")
                for icoord in range(NCOORDS):
                    token = tokens[icoord + 1]
                    dCFSorigin[icoord] = Float64(token)
                var v3CFSoffset: BGL.vector3 = BGL.vector3(dCFSorigin[0], dCFSorigin[1], dCFSorigin[2])
                var dCFSheight: Float64 = 0.0
                var dCFSwidth: Float64 = 0.0
                var dCFSrotation: Float64 = 0.0
                var iCFSnodesheight: Int32 = 0
                var iCFSnodeswidth: Int32 = 0
                cInputLine = infile.read_line()
                if cInputLine is None: return -1
                // sscanf(cInputLine,"%*s %lf\n",&dCFSheight)
                parts = cInputLine.split(" ")
                if parts.len >= 2:
                    dCFSheight = Float64(parts[1])
                cInputLine = infile.read_line()
                if cInputLine is None: return -1
                // sscanf(cInputLine,"%*s %lf\n",&dCFSwidth)
                parts = cInputLine.split(" ")
                if parts.len >= 2:
                    dCFSwidth = Float64(parts[1])
                cInputLine = infile.read_line()
                if cInputLine is None: return -1
                // sscanf(cInputLine,"%*s %lf\n",&dCFSrotation)
                parts = cInputLine.split(" ")
                if parts.len >= 2:
                    dCFSrotation = Float64(parts[1])
                cInputLine = infile.read_line()
                if cInputLine is None: return -1
                // sscanf(cInputLine,"%*s %d\n",&iCFSnodesheight)
                parts = cInputLine.split(" ")
                if parts.len >= 2:
                    iCFSnodesheight = Int32(parts[1])
                cInputLine = infile.read_line()
                if cInputLine is None: return -1
                // sscanf(cInputLine,"%*s %d\n",&iCFSnodeswidth)
                parts = cInputLine.split(" ")
                if parts.len >= 2:
                    iCFSnodeswidth = Int32(parts[1])
                var cCFStype: String = ""
                var charCFStype: String = " " * (MAX_CHAR_UNAME + 1)
                cInputLine = infile.read_line()
                if cInputLine is None: return -1
                // sscanf(cInputLine,"%*s %s\n",charCFStype)
                parts = cInputLine.split(" ")
                if parts.len >= 2:
                    charCFStype = parts[1]
                cCFStype = charCFStype
                var dCFSBFlux: Float64 = 0.0
                var dCFSConeAngle: Float64 = 0.0
                var dCFSTheta: Float64 = 0.0
                var dCFSPhi: Float64 = 0.0
                cInputLine = infile.read_line()
                if cInputLine is None: return -1
                // sscanf(cInputLine,"%*s %lf\n",&dCFSBFlux)
                parts = cInputLine.split(" ")
                if parts.len >= 2:
                    dCFSBFlux = Float64(parts[1])
                cInputLine = infile.read_line()
                if cInputLine is None: return -1
                // sscanf(cInputLine,"%*s %lf\n",&dCFSConeAngle)
                parts = cInputLine.split(" ")
                if parts.len >= 2:
                    dCFSConeAngle = Float64(parts[1])
                cInputLine = infile.read_line()
                if cInputLine is None: return -1
                // sscanf(cInputLine,"%*s %lf\n",&dCFSTheta)
                parts = cInputLine.split(" ")
                if parts.len >= 2:
                    dCFSTheta = Float64(parts[1])
                cInputLine = infile.read_line()
                if cInputLine is None: return -1
                // sscanf(cInputLine,"%*s %lf\n",&dCFSPhi)
                parts = cInputLine.split(" ")
                if parts.len >= 2:
                    dCFSPhi = Float64(parts[1])
        /* Read and discard REFERENCE POINT headings lines */
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        /* Read reference point data */
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        // sscanf(cInputLine,"%*s %d\n",&bldg_ptr->zone[iz]->nrefpts)
        parts = cInputLine.split(" ")
        if parts.len >= 2:
            bldg_ptr.zone[iz].nrefpts = Int32(parts[1])
        for irp in range(bldg_ptr.zone[iz].nrefpts):
            bldg_ptr.zone[iz].ref_pt[irp] = REFPT()
            if bldg_ptr.zone[iz].ref_pt[irp] is None:
                pofdmpfile.write("ERROR: DElight Insufficient memory for REFERENCE POINT allocation\n")
                return -1
            struct_init("REFPT", cast[Char8*](bldg_ptr.zone[iz].ref_pt[irp]))
            /* Read and discard REFERENCE POINT DATA headings lines */
            cInputLine = infile.read_line()
            if cInputLine is None: return -1
            cInputLine = infile.read_line()
            if cInputLine is None: return -1
            cInputLine = infile.read_line()
            if cInputLine is None: return -1
            // sscanf(cInputLine,"%*s %s\n",bldg_ptr->zone[iz]->ref_pt[irp]->name)
            parts = cInputLine.split(" ")
            if parts.len >= 2:
                bldg_ptr.zone[iz].ref_pt[irp].name = parts[1]
            /* reference point in zone system coordinates */
            cInputLine = infile.read_line()
            if cInputLine is None: return -1
            /* tokenize the line label */
            tokens = cInputLine.split(" ")
            for icoord in range(NCOORDS):
                token = tokens[icoord + 1]
                bldg_ptr.zone[iz].ref_pt[irp].zs[icoord] = Float64(token)
            cInputLine = infile.read_line()
            if cInputLine is None: return -1
            // sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->zone[iz]->ref_pt[irp]->zone_frac)
            parts = cInputLine.split(" ")
            if parts.len >= 2:
                bldg_ptr.zone[iz].ref_pt[irp].zone_frac = Float64(parts[1])
            cInputLine = infile.read_line()
            if cInputLine is None: return -1
            // sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->zone[iz]->ref_pt[irp]->lt_set_pt)
            parts = cInputLine.split(" ")
            if parts.len >= 2:
                bldg_ptr.zone[iz].ref_pt[irp].lt_set_pt = Float64(parts[1])
            cInputLine = infile.read_line()
            if cInputLine is None: return -1
            // sscanf(cInputLine,"%*s %d\n",&bldg_ptr->zone[iz]->ref_pt[irp]->lt_ctrl_type)
            parts = cInputLine.split(" ")
            if parts.len >= 2:
                bldg_ptr.zone[iz].ref_pt[irp].lt_ctrl_type = Int32(parts[1])
            /* Allocate memory for window luminance factors for each ref_pt<->wndo combination */
            for is in range(bldg_ptr.zone[iz].nsurfs):
                for iw in range(bldg_ptr.zone[iz].surf[is].nwndos):
                    bldg_ptr.zone[iz].ref_pt[irp].wlum[is][iw] = WLUM()
                    if bldg_ptr.zone[iz].ref_pt[irp].wlum[is][iw] is None:
                        pofdmpfile.write("ERROR: DElight Insufficient memory for WINDOW LUMINANCE allocation\n")
                        return -1
                    struct_init("WLUM", cast[Char8*](bldg_ptr.zone[iz].ref_pt[irp].wlum[is][iw]))
    /* Read and discard BUILDING SHADES headings lines */
    cInputLine = infile.read_line()
    if cInputLine is None: return -1
    cInputLine = infile.read_line()
    if cInputLine is None: return -1
    /* Read building shade data */
    cInputLine = infile.read_line()
    if cInputLine is None: return -1
    // sscanf(cInputLine,"%*s %d\n",&bldg_ptr->nbshades)
    parts = cInputLine.split(" ")
    if parts.len >= 2:
        bldg_ptr.nbshades = Int32(parts[1])
    for ish in range(bldg_ptr.nbshades):
        bldg_ptr.bshade[ish] = BSHADE()
        if bldg_ptr.bshade[ish] is None:
            pofdmpfile.write("ERROR: DElight Insufficient memory for BUILDING SHADE allocation\n")
            return -1
        struct_init("BSHADE", cast[Char8*](bldg_ptr.bshade[ish]))
        /* Read and discard BUILDING SHADE headings lines */
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        // sscanf(cInputLine,"%*s %s\n",bldg_ptr->bshade[ish]->name)
        parts = cInputLine.split(" ")
        if parts.len >= 2:
            bldg_ptr.bshade[ish].name = parts[1]
        /* bldg shade origin in bldg system coordinates */
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        /* tokenize the line label */
        tokens = cInputLine.split(" ")
        for icoord in range(NCOORDS):
            token = tokens[icoord + 1]
            bldg_ptr.bshade[ish].origin[icoord] = Float64(token)
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        // sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->bshade[ish]->height)
        parts = cInputLine.split(" ")
        if parts.len >= 2:
            bldg_ptr.bshade[ish].height = Float64(parts[1])
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        // sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->bshade[ish]->width)
        parts = cInputLine.split(" ")
        if parts.len >= 2:
            bldg_ptr.bshade[ish].width = Float64(parts[1])
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        // sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->bshade[ish]->azm)
        parts = cInputLine.split(" ")
        if parts.len >= 2:
            bldg_ptr.bshade[ish].azm = Float64(parts[1])
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        // sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->bshade[ish]->tilt)
        parts = cInputLine.split(" ")
        if parts.len >= 2:
            bldg_ptr.bshade[ish].tilt = Float64(parts[1])
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        // sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->bshade[ish]->vis_refl)
        parts = cInputLine.split(" ")
        if parts.len >= 2:
            bldg_ptr.bshade[ish].vis_refl = Float64(parts[1])
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        // sscanf(cInputLine,"%*s %lf\n",&bldg_ptr->bshade[ish]->gnd_refl)
        parts = cInputLine.split(" ")
        if parts.len >= 2:
            bldg_ptr.bshade[ish].gnd_refl = Float64(parts[1])
    return 0
}
/****************************** subroutine load_lib *****************************/
/* Loads a library data file (*.lib) from disk into an initialized lib structure. */
/****************************** subroutine load_lib *****************************/
def load_lib(
    lib_ptr: LIB*,         /* library structure pointer */
    infile: File,          /* pointer to library data file */
    pofdmpfile: File*)     /* ptr to dump file */
-> Int32:
{
    var cInputLine: String = " " * (MAX_CHAR_LINE + 1)   /* Input line */
    var ig: Int32 = 0
    var iws: Int32 = 0                     /* indexes */
    /* Read and discard heading line */
    cInputLine = infile.read_line()
    if cInputLine is None: return -1
    /* Read and discard GLASS TYPES headings lines */
    cInputLine = infile.read_line()
    if cInputLine is None: return -1
    cInputLine = infile.read_line()
    if cInputLine is None: return -1
    /* Read glass type data */
    cInputLine = infile.read_line()
    if cInputLine is None: return -1
    // sscanf(cInputLine,"%*s %d\n",&lib_ptr->nglass)
    var parts = cInputLine.split(" ")
    if parts.len >= 2:
        lib_ptr.nglass = Int32(parts[1])
    for ig in range(lib_ptr.nglass):
        lib_ptr.glass[ig] = GLASS()
        if lib_ptr.glass[ig] is None:
            pofdmpfile.write("ERROR: DElight Insufficient memory for GLASS allocation\n")
            return -1
        struct_init("GLASS", cast[Char8*](lib_ptr.glass[ig]))
        /* Read and discard GLASS TYPE DATA headings lines */
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        // sscanf(cInputLine,"%*s %s\n",lib_ptr->glass[ig]->name)
        parts = cInputLine.split(" ")
        if parts.len >= 2:
            lib_ptr.glass[ig].name = parts[1]
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        // sscanf(cInputLine,"%*s %lf\n",&lib_ptr->glass[ig]->vis_trans)
        parts = cInputLine.split(" ")
        if parts.len >= 2:
            lib_ptr.glass[ig].vis_trans = Float64(parts[1])
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        // sscanf(cInputLine,"%*s %lf\n",&lib_ptr->glass[ig]->inside_refl)
        parts = cInputLine.split(" ")
        if parts.len >= 2:
            lib_ptr.glass[ig].inside_refl = Float64(parts[1])
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        // sscanf(cInputLine,"%*s %lf\n",&lib_ptr->glass[ig]->cam1)
        parts = cInputLine.split(" ")
        if parts.len >= 2:
            lib_ptr.glass[ig].cam1 = Float64(parts[1])
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        // sscanf(cInputLine,"%*s %lf\n",&lib_ptr->glass[ig]->cam2)
        parts = cInputLine.split(" ")
        if parts.len >= 2:
            lib_ptr.glass[ig].cam2 = Float64(parts[1])
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        // sscanf(cInputLine,"%*s %lf\n",&lib_ptr->glass[ig]->cam3)
        parts = cInputLine.split(" ")
        if parts.len >= 2:
            lib_ptr.glass[ig].cam3 = Float64(parts[1])
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        // sscanf(cInputLine,"%*s %lf\n",&lib_ptr->glass[ig]->cam4)
        parts = cInputLine.split(" ")
        if parts.len >= 2:
            lib_ptr.glass[ig].cam4 = Float64(parts[1])
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        // sscanf(cInputLine,"%*s %lf\n",&lib_ptr->glass[ig]->cam9)
        parts = cInputLine.split(" ")
        if parts.len >= 2:
            lib_ptr.glass[ig].cam9 = Float64(parts[1])
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        // sscanf(cInputLine,"%*s %lf\n",&lib_ptr->glass[ig]->E10hemi_trans)
        parts = cInputLine.split(" ")
        if parts.len >= 2:
            lib_ptr.glass[ig].E10hemi_trans = Float64(parts[1])
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        // sscanf(cInputLine,"%*s %lf\n",&lib_ptr->glass[ig]->E10coef[0])
        parts = cInputLine.split(" ")
        if parts.len >= 2:
            lib_ptr.glass[ig].E10coef[0] = Float64(parts[1])
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        // sscanf(cInputLine,"%*s %lf\n",&lib_ptr->glass[ig]->E10coef[1])
        parts = cInputLine.split(" ")
        if parts.len >= 2:
            lib_ptr.glass[ig].E10coef[1] = Float64(parts[1])
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        // sscanf(cInputLine,"%*s %lf\n",&lib_ptr->glass[ig]->E10coef[2])
        parts = cInputLine.split(" ")
        if parts.len >= 2:
            lib_ptr.glass[ig].E10coef[2] = Float64(parts[1])
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        // sscanf(cInputLine,"%*s %lf\n",&lib_ptr->glass[ig]->E10coef[3])
        parts = cInputLine.split(" ")
        if parts.len >= 2:
            lib_ptr.glass[ig].E10coef[3] = Float64(parts[1])
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        // sscanf(cInputLine,"%*s %lf\n",&lib_ptr->glass[ig]->EPlusDiffuse_Trans)
        parts = cInputLine.split(" ")
        if parts.len >= 2:
            lib_ptr.glass[ig].EPlusDiffuse_Trans = Float64(parts[1])
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        // sscanf(cInputLine,"%*s %lf\n",&lib_ptr->glass[ig]->EPlusCoef[0])
        parts = cInputLine.split(" ")
        if parts.len >= 2:
            lib_ptr.glass[ig].EPlusCoef[0] = Float64(parts[1])
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        // sscanf(cInputLine,"%*s %lf\n",&lib_ptr->glass[ig]->EPlusCoef[1])
        parts = cInputLine.split(" ")
        if parts.len >= 2:
            lib_ptr.glass[ig].EPlusCoef[1] = Float64(parts[1])
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        // sscanf(cInputLine,"%*s %lf\n",&lib_ptr->glass[ig]->EPlusCoef[2])
        parts = cInputLine.split(" ")
        if parts.len >= 2:
            lib_ptr.glass[ig].EPlusCoef[2] = Float64(parts[1])
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        // sscanf(cInputLine,"%*s %lf\n",&lib_ptr->glass[ig]->EPlusCoef[3])
        parts = cInputLine.split(" ")
        if parts.len >= 2:
            lib_ptr.glass[ig].EPlusCoef[3] = Float64(parts[1])
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        // sscanf(cInputLine,"%*s %lf\n",&lib_ptr->glass[ig]->EPlusCoef[4])
        parts = cInputLine.split(" ")
        if parts.len >= 2:
            lib_ptr.glass[ig].EPlusCoef[4] = Float64(parts[1])
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        // sscanf(cInputLine,"%*s %lf\n",&lib_ptr->glass[ig]->EPlusCoef[5])
        parts = cInputLine.split(" ")
        if parts.len >= 2:
            lib_ptr.glass[ig].EPlusCoef[5] = Float64(parts[1])
    /* Read and discard WSHADE TYPES headings lines */
    cInputLine = infile.read_line()
    if cInputLine is None: return -1
    cInputLine = infile.read_line()
    if cInputLine is None: return -1
    /* Read wshade type data */
    cInputLine = infile.read_line()
    if cInputLine is None: return -1
    // sscanf(cInputLine,"%*s %d\n",&lib_ptr->nwshades)
    parts = cInputLine.split(" ")
    if parts.len >= 2:
        lib_ptr.nwshades = Int32(parts[1])
    for iws in range(lib_ptr.nwshades):
        lib_ptr.wshade[iws] = WSHADE()
        if lib_ptr.wshade[iws] is None:
            pofdmpfile.write("ERROR: DElight Insufficient memory for WINDOW SHADE allocation\n")
            return -1
        struct_init("WSHADE", cast[Char8*](lib_ptr.wshade[iws]))
        /* Read and discard WSHADE TYPE DATA headings lines */
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        // sscanf(cInputLine,"%*s %s\n",lib_ptr->wshade[iws]->name)
        parts = cInputLine.split(" ")
        if parts.len >= 2:
            lib_ptr.wshade[iws].name = parts[1]
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        // sscanf(cInputLine,"%*s %lf\n",&lib_ptr->wshade[iws]->vis_trans)
        parts = cInputLine.split(" ")
        if parts.len >= 2:
            lib_ptr.wshade[iws].vis_trans = Float64(parts[1])
        cInputLine = infile.read_line()
        if cInputLine is None: return -1
        // sscanf(cInputLine,"%*s %lf\n",&lib_ptr->wshade[iws]->inside_refl)
        parts = cInputLine.split(" ")
        if parts.len >= 2:
            lib_ptr.wshade[iws].inside_refl = Float64(parts[1])
    return 0
}