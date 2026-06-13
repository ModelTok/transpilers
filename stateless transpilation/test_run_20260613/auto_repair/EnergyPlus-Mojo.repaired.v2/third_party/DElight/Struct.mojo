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

# Use pointer for raw memory access
from memory import Pointer
from string import StringRef

# The following constants are assumed to be defined in the corresponding .mojo modules
# (imported from CONST.H, DBCONST.H, DEF.H, etc.)
# They must be available at compile time.
# For a faithful translation, they are used as global names.

# Assume struct types WNDO, LTSCH, WLUM, REFPT, SURF, ZONE, BLDG, ZSHADE, BSHADE, GLASS, WSHADE, LIB, ZONE_REFL are defined elsewhere.

/****************************** subroutine struct_init *****************************/
/* Initializes data structure elements. */
/****************************** subroutine struct_init *****************************/
def struct_init(
	type: StringRef,	/* string identifier of structure to be initialized */
	sptr: Pointer[Byte]		/* generic pointer to structure to be initialized */
) -> Int32:
{
	var	ii: Int32, jj: Int32, kk: Int32, ll: Int32;
	if (type == "WNDO") {
		(sptr.reinterpret[WNDO]()).name = "";
		for ii in range(NCOORDS):
			(sptr.reinterpret[WNDO]()).origin[ii] = 0.0;
		(sptr.reinterpret[WNDO]()).height = 0.0;
		(sptr.reinterpret[WNDO]()).width = 0.0;
		(sptr.reinterpret[WNDO]()).nvertices = 0;
		(sptr.reinterpret[WNDO]()).glass_type = "";
		(sptr.reinterpret[WNDO]()).shade_flag = 0;
		(sptr.reinterpret[WNDO]()).shade_type = "";
		for ii in range(NZSHADES):
			(sptr.reinterpret[WNDO]()).zshade_x[ii] = 0.0F;
			(sptr.reinterpret[WNDO]()).zshade_y[ii] = 0.0F;
		/* ----- derived quantities ----- */
		for ii in range(NCOORDS):
			for jj in range(NVERTS):
				(sptr.reinterpret[WNDO]()).vert[ii][jj] = 0.0;
		/* ----- interreflection derived quantities ----- */
		(sptr.reinterpret[WNDO]()).node_area = 0.0;
		(sptr.reinterpret[WNDO]()).n_width = 0;
		(sptr.reinterpret[WNDO]()).n_height = 0;
		(sptr.reinterpret[WNDO]()).nnodes = 0;
		for ii in range(MAX_WNDO_NODES):
			(sptr.reinterpret[WNDO]()).node_areas[ii] = 0.0;
			(sptr.reinterpret[WNDO]()).direct_skyolum[ii] = 0.0;
			(sptr.reinterpret[WNDO]()).skyolum[ii] = 0.0;
			for jj in range(NCOORDS):
				(sptr.reinterpret[WNDO]()).node[ii][jj] = 0.0;
		for kk in range(NPHS):
			for ll in range(NTHS):
				(sptr.reinterpret[WNDO]()).wlumsky[kk][ll] = 0.0;
				(sptr.reinterpret[WNDO]()).wlumsun[kk][ll] = 0.0;
				for ii in range(MAX_WNDO_NODES):
					(sptr.reinterpret[WNDO]()).direct_skyclum[ii][kk][ll] = 0.0;
					(sptr.reinterpret[WNDO]()).direct_sunclum[ii][kk][ll] = 0.0;
					(sptr.reinterpret[WNDO]()).skyclum[ii][kk][ll] = 0.0;
					(sptr.reinterpret[WNDO]()).sunclum[ii][kk][ll] = 0.0;
		(sptr.reinterpret[WNDO]()).wlumskyo = 0;
	}
	else if (type == "LTSCH") {
		(sptr.reinterpret[LTSCH]()).name = "";
		(sptr.reinterpret[LTSCH]()).mon_begin = 0;
		(sptr.reinterpret[LTSCH]()).day_begin = 0;
		(sptr.reinterpret[LTSCH]()).mon_end = 0;
		(sptr.reinterpret[LTSCH]()).day_end = 0;
		(sptr.reinterpret[LTSCH]()).dow_begin = 0;
		(sptr.reinterpret[LTSCH]()).dow_end = 0;
		for ii in range(HOURS):
			(sptr.reinterpret[LTSCH]()).frac[ii] = 1.0;
		(sptr.reinterpret[LTSCH]()).doy_begin = 0;
		(sptr.reinterpret[LTSCH]()).doy_end = 0;
	}
	else if (type == "WLUM") {
		for ii in range(NPHS):
			for jj in range(NTHS):
				(sptr.reinterpret[WLUM]()).sfsky[ii][jj] = 0.0;
				(sptr.reinterpret[WLUM]()).sfsun[ii][jj] = 0.0;
		(sptr.reinterpret[WLUM]()).sfskyo = 0.0;
		(sptr.reinterpret[WLUM]()).omega = 0.0;
		(sptr.reinterpret[WLUM]()).omegaw = 0.0;
	}
	else if (type == "REFPT") {
		(sptr.reinterpret[REFPT]()).name = "";
		for ii in range(NCOORDS):
			(sptr.reinterpret[REFPT]()).zs[ii] = 0.0;
			(sptr.reinterpret[REFPT]()).bs[ii] = 0.0;
		(sptr.reinterpret[REFPT]()).zone_frac = 0.0;
		(sptr.reinterpret[REFPT]()).lt_set_pt = 0.0;
		(sptr.reinterpret[REFPT]()).lt_ctrl_type = 0;
		(sptr.reinterpret[REFPT]()).skyoillum = 0.0;
		(sptr.reinterpret[REFPT]()).daylight = 0.0;
		(sptr.reinterpret[REFPT]()).glarendx = 0.0;
		(sptr.reinterpret[REFPT]()).frac_power = 0.0;
		(sptr.reinterpret[REFPT]()).dfskyo = 0.0;
		(sptr.reinterpret[REFPT]()).bfskyo = 0.0;
		for ii in range(NPHS):
			for jj in range(NTHS):
				(sptr.reinterpret[REFPT]()).skycillum[ii][jj] = 0.0;
				(sptr.reinterpret[REFPT]()).suncillum[ii][jj] = 0.0;
				(sptr.reinterpret[REFPT]()).dfsky[ii][jj] = 0.0;
				(sptr.reinterpret[REFPT]()).dfsun[ii][jj] = 0.0;
				(sptr.reinterpret[REFPT]()).bfsky[ii][jj] = 0.0;
				(sptr.reinterpret[REFPT]()).bfsun[ii][jj] = 0.0;
		for ii in range(MONTHS):
			for jj in range(HOURS):
				(sptr.reinterpret[REFPT]()).day_illum[ii][jj] = 0.0;
				(sptr.reinterpret[REFPT]()).glare[ii][jj] = 0.0;
		for ii in range(MAX_ZONE_SURFS):
			for jj in range(MAX_SURF_WNDOS):
				(sptr.reinterpret[REFPT]()).wlum[ii][jj] = None;
		for ii in range(NSKYTYPE):
			(sptr.reinterpret[REFPT]()).dcm_glare[ii] = 0.0;
		/* --------------- interreflection variables --------------- */
		(sptr.reinterpret[REFPT]()).delf_overcast = 0.0;
		(sptr.reinterpret[REFPT]()).direct_skyoillum = 0.0;
		for kk in range(NPHS):
			for ll in range(NTHS):
				(sptr.reinterpret[REFPT]()).delf_skyclear[kk][ll] = 0.0;
				(sptr.reinterpret[REFPT]()).delf_sunclear[kk][ll] = 0.0;
				(sptr.reinterpret[REFPT]()).direct_skycillum[kk][ll] = 0.0;
				(sptr.reinterpret[REFPT]()).direct_suncillum[kk][ll] = 0.0;
	}
	else if (type == "SURF") {
		(sptr.reinterpret[SURF]()).name = "";
		for ii in range(NCOORDS):
			(sptr.reinterpret[SURF]()).origin[ii] = 0.0;
		(sptr.reinterpret[SURF]()).height = 0.0;
		(sptr.reinterpret[SURF]()).width = 0.0;
		(sptr.reinterpret[SURF]()).azm_zs = 0.0;
		(sptr.reinterpret[SURF]()).tilt_zs = 90.0;
		(sptr.reinterpret[SURF]()).vis_refl = 0.5;
		(sptr.reinterpret[SURF]()).ext_vis_refl = 0.0;
		(sptr.reinterpret[SURF]()).gnd_refl = 0.2;
		(sptr.reinterpret[SURF]()).type = 2;
		(sptr.reinterpret[SURF]()).area = 0.0;
		(sptr.reinterpret[SURF]()).E10ndx = 0;
		(sptr.reinterpret[SURF]()).nwndos = 0;
		for ii in range(MAX_SURF_WNDOS):
			(sptr.reinterpret[SURF]()).wndo[ii]  = None;
		(sptr.reinterpret[SURF]()).ncfs = 0;
		for ii in range(MAX_SURF_CFS):
			(sptr.reinterpret[SURF]()).cfs[ii]  = None;
		(sptr.reinterpret[SURF]()).nvertices = 0;
		/* ----- derived quantities ----- */
		for ii in range(NCOORDS):
			(sptr.reinterpret[SURF]()).outward_uvect[ii] = 0.0;
			(sptr.reinterpret[SURF]()).inward_uvect[ii] = 0.0;
			for jj in range(NVERTS):
				(sptr.reinterpret[SURF]()).vert[ii][jj] = 0.0;
		(sptr.reinterpret[SURF]()).azm_bs = 0.0;
		(sptr.reinterpret[SURF]()).tilt_bs = 0.0;
		(sptr.reinterpret[SURF]()).TotDirectOvercastIllum = 0.0;
		for ii in range(NPHS):
			for jj in range(NTHS):
				(sptr.reinterpret[SURF]()).skylum[ii][jj] = 0.0;
				(sptr.reinterpret[SURF]()).sunlum[ii][jj] = 0.0;
				(sptr.reinterpret[SURF]()).TotDirectSkyCIllum[ii][jj] = 0.0;
				(sptr.reinterpret[SURF]()).TotDirectSunCIllum[ii][jj] = 0.0;
		(sptr.reinterpret[SURF]()).ovrlum = 0.0;
		/* ----- interreflection derived quantities ----- */
		for ii in range(NDC):
			(sptr.reinterpret[SURF]()).dircos[ii] = 0.0;
		(sptr.reinterpret[SURF]()).node_area = 0.0;
		(sptr.reinterpret[SURF]()).n_width = 0;
		(sptr.reinterpret[SURF]()).n_height = 0;
		(sptr.reinterpret[SURF]()).nnodes = 0;
		for ii in range(MAX_SURF_NODES):
			(sptr.reinterpret[SURF]()).node_areas[ii] = 0.0;
			(sptr.reinterpret[SURF]()).direct_skyolum[ii] = 0.0;
			(sptr.reinterpret[SURF]()).skyolum[ii] = 0.0;
			for jj in range(NCOORDS):
				(sptr.reinterpret[SURF]()).node[ii][jj] = 0.0;
			for kk in range(NPHS):
				for ll in range(NTHS):
					(sptr.reinterpret[SURF]()).direct_skyclum[ii][kk][ll] = 0.0;
					(sptr.reinterpret[SURF]()).direct_sunclum[ii][kk][ll] = 0.0;
					(sptr.reinterpret[SURF]()).skyclum[ii][kk][ll] = 0.0;
					(sptr.reinterpret[SURF]()).sunclum[ii][kk][ll] = 0.0;
	}
	else if (type == "ZONE") {
		(sptr.reinterpret[ZONE]()).name = "";
		for ii in range(NCOORDS):
			(sptr.reinterpret[ZONE]()).origin[ii] = 0.0;
		(sptr.reinterpret[ZONE]()).azm = 0.0;
		(sptr.reinterpret[ZONE]()).mult = 1.0;
		(sptr.reinterpret[ZONE]()).flarea = 0.0;
		(sptr.reinterpret[ZONE]()).volume = 0.0;
		(sptr.reinterpret[ZONE]()).lighting = 0.0;
		(sptr.reinterpret[ZONE]()).min_power = 0.0;
		(sptr.reinterpret[ZONE]()).min_light = 0.0;
		(sptr.reinterpret[ZONE]()).lt_ctrl_steps = 0;
		(sptr.reinterpret[ZONE]()).lt_ctrl_prob = 1.0;
		(sptr.reinterpret[ZONE]()).view_azm = 0.0;
		(sptr.reinterpret[ZONE]()).max_grid_node_area = 1.0;
		(sptr.reinterpret[ZONE]()).nltsch = 0;
		for ii in range(MAX_LT_SCHEDS):
			(sptr.reinterpret[ZONE]()).ltsch[ii]  = None;
		(sptr.reinterpret[ZONE]()).nsurfs = 0;
		for ii in range(MAX_ZONE_SURFS):
			(sptr.reinterpret[ZONE]()).surf[ii]  = None;
		(sptr.reinterpret[ZONE]()).nzshades = 0;
		for ii in range(MAX_ZONE_SHADES):
			(sptr.reinterpret[ZONE]()).zshade[ii]  = None;
		(sptr.reinterpret[ZONE]()).nrefpts = 0;
		for ii in range(MAX_REF_PTS):
			(sptr.reinterpret[ZONE]()).ref_pt[ii]  = None;
		(sptr.reinterpret[ZONE]()).e10zonename = "";
		(sptr.reinterpret[ZONE]()).eleclt_details = 0;
		(sptr.reinterpret[ZONE]()).frac_power = 0.0;
		(sptr.reinterpret[ZONE]()).ltsch_id = 0;
		for ii in range(MONTHS):
			for jj in range(HOURS):
				(sptr.reinterpret[ZONE]()).annual_reduc[jj] = 0.0;
				(sptr.reinterpret[ZONE]()).lt_reduc[ii][jj] = 0.0;
	}
	else if (type == "BLDG") {
		(sptr.reinterpret[BLDG]()).name = "";
		(sptr.reinterpret[BLDG]()).lat = 0.0;
		(sptr.reinterpret[BLDG]()).lon = 0.0;
		(sptr.reinterpret[BLDG]()).alt = 0.0;
		(sptr.reinterpret[BLDG]()).azm = 0.0;
		(sptr.reinterpret[BLDG]()).timezone = 0;
		for ii in range(MONTHS):
			(sptr.reinterpret[BLDG]()).atmtur[ii] = 0.0;
			(sptr.reinterpret[BLDG]()).atmmoi[ii] = 0.0;
		(sptr.reinterpret[BLDG]()).nzones = 0;
		for ii in range(MAX_BLDG_ZONES):
			(sptr.reinterpret[BLDG]()).zone[ii]  = None;
		(sptr.reinterpret[BLDG]()).nbshades = 0;
		for ii in range(MAX_BLDG_SHADES):
			(sptr.reinterpret[BLDG]()).bshade[ii]  = None;
		/* ----- derived quantities ----- */
		for kk in range(NPHS):
			(sptr.reinterpret[BLDG]()).hillumskyc[kk] = 0.0;
			(sptr.reinterpret[BLDG]()).hillumskyo[kk] = 0.0;
			(sptr.reinterpret[BLDG]()).hillumsunc[kk] = 0.0;
	}
	else if (type == "ZSHADE") {
		(sptr.reinterpret[ZSHADE]()).name = "";
		for ii in range(NCOORDS):
			(sptr.reinterpret[ZSHADE]()).origin[ii] = 0.0;
		(sptr.reinterpret[ZSHADE]()).height = 0.0;
		(sptr.reinterpret[ZSHADE]()).width = 0.0;
		(sptr.reinterpret[ZSHADE]()).azm_zs = 0.0;
		(sptr.reinterpret[ZSHADE]()).tilt_zs = 0.0;
		/* ----- derived quantities ----- */
		for ii in range(NCOORDS):
			for jj in range(NVERTS):
				(sptr.reinterpret[ZSHADE]()).vert[ii][jj] = 0.0;
		(sptr.reinterpret[ZSHADE]()).azm_bs = 0.0;
		(sptr.reinterpret[ZSHADE]()).tilt_bs = 0.0;
	}
	else if (type == "BSHADE") {
		(sptr.reinterpret[BSHADE]()).name = "";
		for ii in range(NCOORDS):
			(sptr.reinterpret[BSHADE]()).origin[ii] = 0.0;
		(sptr.reinterpret[BSHADE]()).height = 0.0;
		(sptr.reinterpret[BSHADE]()).width = 0.0;
		(sptr.reinterpret[BSHADE]()).azm = 0.0;
		(sptr.reinterpret[BSHADE]()).tilt = 0.0;
		(sptr.reinterpret[BSHADE]()).vis_refl = 0.5;
		(sptr.reinterpret[BSHADE]()).gnd_refl = 0.2;
		/* ----- derived quantities ----- */
		for ii in range(NCOORDS):
			for jj in range(NVERTS):
				(sptr.reinterpret[BSHADE]()).vert[ii][jj] = 0.0;
		for ii in range(NPHS):
			for jj in range(NTHS):
				(sptr.reinterpret[BSHADE]()).skylum[ii][jj] = 0.0;
				(sptr.reinterpret[BSHADE]()).sunlum[ii][jj] = 0.0;
		(sptr.reinterpret[BSHADE]()).ovrlum = 0.0;
	}
	else if (type == "GLASS") {
		(sptr.reinterpret[GLASS]()).name = "";
		(sptr.reinterpret[GLASS]()).vis_trans = 1.0;
		(sptr.reinterpret[GLASS]()).inside_refl = 0.15;
		(sptr.reinterpret[GLASS]()).cam1 = 0.0;
		(sptr.reinterpret[GLASS]()).cam2 = 0.0;
		(sptr.reinterpret[GLASS]()).cam3 = 0.0;
		(sptr.reinterpret[GLASS]()).cam4 = 0.0;
		(sptr.reinterpret[GLASS]()).cam9 = 0.0;
		(sptr.reinterpret[GLASS]()).E10hemi_trans = 1.0F;
		(sptr.reinterpret[GLASS]()).W4hemi_trans = 1.0F;
		(sptr.reinterpret[GLASS]()).W4vis_fit1 = 0.0F;
		(sptr.reinterpret[GLASS]()).W4vis_fit2 = 0.0F;
		for ii in range(4):
			(sptr.reinterpret[GLASS]()).E10coef[ii]  = 0.0;
	}
	else if (type == "WSHADE") {
		(sptr.reinterpret[WSHADE]()).name = "";
		(sptr.reinterpret[WSHADE]()).vis_trans = 1.0;
		(sptr.reinterpret[WSHADE]()).inside_refl = 0.0;
	}
	else if (type == "LIB") {
		(sptr.reinterpret[LIB]()).name = "";
		(sptr.reinterpret[LIB]()).nglass = 0;
		(sptr.reinterpret[LIB]()).nwshades = 0;
		for ii in range(MAX_LIB_COMPS):
			(sptr.reinterpret[LIB]()).glass[ii]  = None;
			(sptr.reinterpret[LIB]()).wshade[ii]  = None;
	}
	else if (type == "ZONE_REFL") {
		(sptr.reinterpret[ZONE_REFL]()).nwtot = 0;
		(sptr.reinterpret[ZONE_REFL]()).atot = 0.0;
		(sptr.reinterpret[ZONE_REFL]()).arhtot = 0.0;
		for ii in range(NTILTS):
			(sptr.reinterpret[ZONE_REFL]()).ar[ii]  = 0.0;
			(sptr.reinterpret[ZONE_REFL]()).arh[ii]  = 0.0;
		(sptr.reinterpret[ZONE_REFL]()).avg_refl = 0.0;
	}
	else return (-1);
	return(0);
}