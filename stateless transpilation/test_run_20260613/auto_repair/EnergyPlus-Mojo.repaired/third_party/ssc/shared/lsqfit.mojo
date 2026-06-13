/* 
 * MINPACK-1 Least Squares Fitting Library
 *
 * Original public domain version by B. Garbow, K. Hillstrom, J. More'
 *   (Argonne National Laboratory, MINPACK project, March 1980)
 * See the file DISCLAIMER for copyright information.
 * 
 * Tranlation to C Language by S. Moshier (moshier.net)
 * 
 * Enhancements and packaging by C. Markwardt
 *   (comparable to IDL fitting routine MPFIT
 *    see http://cow.physics.wisc.edu/~craigm/idl/idl.html)
 */
/* Main mpfit library routines (double precision) 
   $Id: mpfit.c,v 1.20 2010/11/13 08:15:35 craigm Exp $
 */
from math import sqrt, fabs, isfinite
from sys import malloc, free

/* Forward declarations of functions in this module */
def mp_fdjac2(funct: mp_func,
	      m: Int, n: Int, def ifree: Pointer[Int], npar: Int, def x: Pointer[Float64], def fvec: Pointer[Float64],
	      def fjac: Pointer[Float64], ldfjac: Int, epsfcn: Float64,
	      def wa: Pointer[Float64], priv: Int, def nfev: Pointer[Int],
	      def step: Pointer[Float64], def dstep: Pointer[Float64], def dside: Pointer[Int],
	      def qulimited: Pointer[Int], def ulimit: Pointer[Float64],
	      def ddebug: Pointer[Int], def ddrtol: Pointer[Float64], def ddatol: Pointer[Float64]) -> Int
def mp_qrfac(m: Int, n: Int, def a: Pointer[Float64], lda: Int, 
	      pivot: Int, def ipvt: Pointer[Int], lipvt: Int,
	      def rdiag: Pointer[Float64], def acnorm: Pointer[Float64], def wa: Pointer[Float64])
def mp_qrsolv(n: Int, def r: Pointer[Float64], ldr: Int, def ipvt: Pointer[Int], def diag: Pointer[Float64],
	       def qtb: Pointer[Float64], def x: Pointer[Float64], def sdiag: Pointer[Float64], def wa: Pointer[Float64])
def mp_lmpar(n: Int, def r: Pointer[Float64], ldr: Int, def ipvt: Pointer[Int], def ifree: Pointer[Int], def diag: Pointer[Float64],
	      def qtb: Pointer[Float64], delta: Float64, def par: Pointer[Float64], def x: Pointer[Float64],
	      def sdiag: Pointer[Float64], def wa1: Pointer[Float64], def wa2: Pointer[Float64])
def mp_enorm(n: Int, def x: Pointer[Float64]) -> Float64
def mp_dmax1(a: Float64, b: Float64) -> Float64
def mp_dmin1(a: Float64, b: Float64) -> Float64
def mp_min0(a: Int, b: Int) -> Int
def mp_covar(n: Int, def r: Pointer[Float64], ldr: Int, def ipvt: Pointer[Int], tol: Float64, def wa: Pointer[Float64]) -> Int

/* Macro to call user function */
# No macro needed; call directly

/* Macro to safely allocate memory */
def mp_malloc(dest: Pointer[Pointer[Float64]], size: Int) -> Int:
    var tmp = malloc[Float64](size)
    dest = tmp
    if dest == nil:
        return MP_ERR_MEMORY
    else:
        for _k in range(size):
            dest[_k] = 0.0
    return 0
}
def mp_malloc_i(dest: Pointer[Pointer[Int]], size: Int) -> Int:
    var tmp = malloc[Int](size)
    dest = tmp
    if dest == nil:
        return MP_ERR_MEMORY
    else:
        for _k in range(size):
            dest[_k] = 0
    return 0
}
def mp_malloc_pp(dest: Pointer[Pointer[Pointer[Float64]]], size: Int) -> Int:
    var tmp = malloc[Pointer[Float64]](size)
    dest = tmp
    if dest == nil:
        return MP_ERR_MEMORY
    else:
        for _k in range(size):
            dest[_k] = nil
    return 0
}
def mpfinite(x: Float64) -> Bool:
    return isfinite(x)

/*
*     **********
*
*     subroutine mpfit
*
*     the purpose of mpfit is to minimize the sum of the squares of
*     m nonlinear functions in n variables by a modification of
*     the levenberg-marquardt algorithm. the user must provide a
*     subroutine which calculates the functions. the jacobian is
*     then calculated by a finite-difference approximation.
*
*     mp_funct funct - function to be minimized
*     int m          - number of data points
*     int npar       - number of fit parameters
*     double *xall   - array of n initial parameter values
*                      upon return, contains adjusted parameter values
*     mp_par *pars   - array of npar structures specifying constraints;
*                      or 0 (null pointer) for unconstrained fitting
*                      [ see README and mpfit.h for definition & use of mp_par]
*     mp_config *config - pointer to structure which specifies the
*                      configuration of mpfit(); or 0 (null pointer)
*                      if the default configuration is to be used.
*                      See README and mpfit.h for definition and use
*                      of config.
*     void *private  - any private user data which is to be passed directly
*                      to funct without modification by mpfit().
*     mp_result *result - pointer to structure, which upon return, contains
*                      the results of the fit.  The user should zero this
*                      structure.  If any of the array values are to be 
*                      returned, the user should allocate storage for them
*                      and assign the corresponding pointer in *result.
*                      Upon return, *result will be updated, and
*                      any of the non-null arrays will be filled.
*
*
* FORTRAN DOCUMENTATION BELOW
*/
def mpfit(funct: mp_func, m: Int, npar: Int,
	  def xall: Pointer[Float64], def pars: Pointer[mp_par], def config: Pointer[mp_config], private_data: Int, 
	  def result: Pointer[mp_result]) -> Int
{
  var conf: mp_config
  var i: Int, j: Int, info: Int, iflag: Int, nfree: Int, npegged: Int, iter: Int
  var qanylim: Int = 0
  var ij: Int, jj: Int, l: Int
  var actred: Float64, delta: Float64, dirder: Float64, fnorm: Float64, fnorm1: Float64, gnorm: Float64, orignorm: Float64
  var par: Float64, pnorm: Float64, prered: Float64, ratio: Float64
  var sum: Float64, temp: Float64, temp1: Float64, temp2: Float64, temp3: Float64, xnorm: Float64, alpha: Float64
  var one: Float64 = 1.0
  var p1: Float64 = 0.1
  var p5: Float64 = 0.5
  var p25: Float64 = 0.25
  var p75: Float64 = 0.75
  var p0001: Float64 = 1.0e-4
  var zero: Float64 = 0.0
  var nfev: Int = 0
  var step: Pointer[Float64] = nil
  var dstep: Pointer[Float64] = nil
  var llim: Pointer[Float64] = nil
  var ulim: Pointer[Float64] = nil
  var pfixed: Pointer[Int] = nil
  var mpside: Pointer[Int] = nil
  var ifree: Pointer[Int] = nil
  var qllim: Pointer[Int] = nil
  var qulim: Pointer[Int] = nil
  var ddebug: Pointer[Int] = nil
  var ddrtol: Pointer[Float64] = nil
  var ddatol: Pointer[Float64] = nil
  var fvec: Pointer[Float64] = nil
  var qtf: Pointer[Float64] = nil
  var x: Pointer[Float64] = nil
  var xnew: Pointer[Float64] = nil
  var fjac: Pointer[Float64] = nil
  var diag: Pointer[Float64] = nil
  var wa1: Pointer[Float64] = nil
  var wa2: Pointer[Float64] = nil
  var wa3: Pointer[Float64] = nil
  var wa4: Pointer[Float64] = nil
  var ipvt: Pointer[Int] = nil
  var ldfjac: Int
  var outer_loop: Bool = True
  var inner_loop: Bool = False
  var goto_L300: Bool = False
  var goto_L200: Bool = False
  var CLEANUP_done: Bool = False

  /* Default configuration */
  conf.ftol = 1e-10
  conf.xtol = 1e-10
  conf.gtol = 1e-10
  conf.stepfactor = 100.0
  conf.nprint = 1
  conf.epsfcn = MP_MACHEP0
  conf.maxiter = 200
  conf.douserscale = 0
  conf.maxfev = 0
  conf.covtol = 1e-14
  conf.nofinitecheck = 0
  if config != nil {
    /* Transfer any user-specified configurations */
    if config.ftol > 0 { conf.ftol = config.ftol }
    if config.xtol > 0 { conf.xtol = config.xtol }
    if config.gtol > 0 { conf.gtol = config.gtol }
    if config.stepfactor > 0 { conf.stepfactor = config.stepfactor }
    if config.nprint >= 0 { conf.nprint = config.nprint }
    if config.epsfcn > 0 { conf.epsfcn = config.epsfcn }
    if config.maxiter > 0 { conf.maxiter = config.maxiter }
    if config.douserscale != 0 { conf.douserscale = config.douserscale }
    if config.covtol > 0 { conf.covtol = config.covtol }
    if config.nofinitecheck > 0 { conf.nofinitecheck = config.nofinitecheck }
    conf.maxfev = config.maxfev
  }
  info = 0
  iflag = 0
  nfree = 0
  npegged = 0
  if funct == nil {
    return MP_ERR_FUNC
  }
  if (m <= 0) or (xall == nil) {
    return MP_ERR_NPOINTS
  }
  if npar <= 0 {
    return MP_ERR_NFREE
  }
  fnorm = -1.0
  fnorm1 = -1.0
  xnorm = -1.0
  delta = 0.0
  /* FIXED parameters? */
  if mp_malloc_i(pfixed, npar) != 0 { info = MP_ERR_MEMORY; goto CLEANUP }
  if pars != nil {
    for i in range(npar) {
      pfixed[i] = (pars[i].fixed) ? 1 : 0
    }
  }
  /* Finite differencing step, absolute and relative, and sidedness of deriv */
  if mp_malloc(step,  npar) != 0 { info = MP_ERR_MEMORY; goto CLEANUP }
  if mp_malloc(dstep, npar) != 0 { info = MP_ERR_MEMORY; goto CLEANUP }
  if mp_malloc_i(mpside, npar) != 0 { info = MP_ERR_MEMORY; goto CLEANUP }
  if mp_malloc_i(ddebug, npar) != 0 { info = MP_ERR_MEMORY; goto CLEANUP }
  if mp_malloc(ddrtol, npar) != 0 { info = MP_ERR_MEMORY; goto CLEANUP }
  if mp_malloc(ddatol, npar) != 0 { info = MP_ERR_MEMORY; goto CLEANUP }
  if pars != nil {
    for i in range(npar) {
      step[i] = pars[i].step
      dstep[i] = pars[i].relstep
      mpside[i] = pars[i].side
      ddebug[i] = pars[i].deriv_debug
      ddrtol[i] = pars[i].deriv_reltol
      ddatol[i] = pars[i].deriv_abstol
    }
  }
  /* Finish up the free parameters */
  nfree = 0
  if mp_malloc_i(ifree, npar) != 0 { info = MP_ERR_MEMORY; goto CLEANUP }
  for i in range(npar) {
    if pfixed[i] == 0 {
      ifree[j] = i
      nfree += 1
      j += 1
    }
  }
  if nfree == 0 {
    info = MP_ERR_NFREE
    goto CLEANUP
  }
  if pars != nil {
    for i in range(npar) {
      if ( (pars[i].limited[0] and (xall[i] < pars[i].limits[0])) or
	   (pars[i].limited[1] and (xall[i] > pars[i].limits[1])) ) {
	info = MP_ERR_INITBOUNDS
	goto CLEANUP
      }
      if ( (pars[i].fixed == 0) and pars[i].limited[0] and pars[i].limited[1] and
	   (pars[i].limits[0] >= pars[i].limits[1])) {
	info = MP_ERR_BOUNDS
	goto CLEANUP
      }
    }
    if mp_malloc_i(qulim, nfree) != 0 { info = MP_ERR_MEMORY; goto CLEANUP }
    if mp_malloc_i(qllim, nfree) != 0 { info = MP_ERR_MEMORY; goto CLEANUP }
    if mp_malloc(ulim, nfree) != 0 { info = MP_ERR_MEMORY; goto CLEANUP }
    if mp_malloc(llim, nfree) != 0 { info = MP_ERR_MEMORY; goto CLEANUP }
    for i in range(nfree) {
      qllim[i] = pars[ifree[i]].limited[0]
      qulim[i] = pars[ifree[i]].limited[1]
      llim[i]  = pars[ifree[i]].limits[0]
      ulim[i]  = pars[ifree[i]].limits[1]
      if qllim[i] or qulim[i] { qanylim = 1 }
    }
  }
  /* Sanity checking on input configuration */
  if (npar <= 0) or (conf.ftol <= 0) or (conf.xtol <= 0) or
      (conf.gtol <= 0) or (conf.maxiter < 0) or
      (conf.stepfactor <= 0) {
    info = MP_ERR_PARAM
    goto CLEANUP
  }
  /* Ensure there are some degrees of freedom */
  if m < nfree {
    info = MP_ERR_DOF
    goto CLEANUP
  }
  /* Allocate temporary storage */
  if mp_malloc(fvec, m) != 0 { info = MP_ERR_MEMORY; goto CLEANUP }
  if mp_malloc(qtf, nfree) != 0 { info = MP_ERR_MEMORY; goto CLEANUP }
  if mp_malloc(x, nfree) != 0 { info = MP_ERR_MEMORY; goto CLEANUP }
  if mp_malloc(xnew, npar) != 0 { info = MP_ERR_MEMORY; goto CLEANUP }
  if mp_malloc(fjac, m*nfree) != 0 { info = MP_ERR_MEMORY; goto CLEANUP }
  ldfjac = m
  if mp_malloc(diag, npar) != 0 { info = MP_ERR_MEMORY; goto CLEANUP }
  if mp_malloc(wa1, npar) != 0 { info = MP_ERR_MEMORY; goto CLEANUP }
  if mp_malloc(wa2, npar) != 0 { info = MP_ERR_MEMORY; goto CLEANUP }
  if mp_malloc(wa3, npar) != 0 { info = MP_ERR_MEMORY; goto CLEANUP }
  if mp_malloc(wa4, m) != 0 { info = MP_ERR_MEMORY; goto CLEANUP }
  if mp_malloc_i(ipvt, npar) != 0 { info = MP_ERR_MEMORY; goto CLEANUP }
  /* Evaluate user function with initial parameter values */
  iflag = funct(m, npar, xall, fvec, nil, private_data)
  nfev += 1
  if iflag < 0 {
    goto CLEANUP
  }
  fnorm = mp_enorm(m, fvec)
  orignorm = fnorm*fnorm
  /* Make a new copy */
  for i in range(npar) {
    xnew[i] = xall[i]
  }
  /* Transfer free parameters to 'x' */
  for i in range(nfree) {
    x[i] = xall[ifree[i]]
  }
  /* Initialize Levelberg-Marquardt parameter and iteration counter */
  par = 0.0
  iter = 1
  for i in range(nfree) {
    qtf[i] = 0
  }
  /* Beginning of the outer loop */
  # Use while loop to simulate OUTER_LOOP
  while outer_loop and not goto_L300:
    for i in range(nfree) {
      xnew[ifree[i]] = x[i]
    }
    /* XXX call iterproc */
    /* Calculate the jacobian matrix */
    iflag = mp_fdjac2(funct, m, nfree, ifree, npar, xnew, fvec, fjac, ldfjac,
		    conf.epsfcn, wa4, private_data, nfev,
		    step, dstep, mpside, qulim, ulim,
		    ddebug, ddrtol, ddatol)
    if iflag < 0 {
      goto CLEANUP
    }
    /* Determine if any of the parameters are pegged at the limits */
    if qanylim {
      for j in range(nfree) {
        var lpegged: Int = (qllim[j] and (x[j] == llim[j])) ? 1 : 0
        var upegged: Int = (qulim[j] and (x[j] == ulim[j])) ? 1 : 0
        sum = 0
        if lpegged or upegged {
          ij = j*ldfjac
          for i in range(m) {
            sum += fvec[i] * fjac[ij]
            ij += 1
          }
        }
        if lpegged and (sum > 0) {
          ij = j*ldfjac
          for i in range(m) {
            fjac[ij] = 0
            ij += 1
          }
        }
        if upegged and (sum < 0) {
          ij = j*ldfjac
          for i in range(m) {
            fjac[ij] = 0
            ij += 1
          }
        }
      }
    } 
    /* Compute the QR factorization of the jacobian */
    mp_qrfac(m, nfree, fjac, ldfjac, 1, ipvt, nfree, wa1, wa2, wa3)
    /*
     *	 on the first iteration and if mode is 1, scale according
     *	 to the norms of the columns of the initial jacobian.
     */
    if iter == 1 {
      if conf.douserscale == 0 {
        for j in range(nfree) {
          diag[ifree[j]] = wa2[j]
          if wa2[j] == zero {
            diag[ifree[j]] = one
          }
        }
      }
      /*
       *	 on the first iteration, calculate the norm of the scaled x
       *	 and initialize the step bound delta.
       */
      for j in range(nfree) {
        wa3[j] = diag[ifree[j]] * x[j]
      }
      xnorm = mp_enorm(nfree, wa3)
      delta = conf.stepfactor*xnorm
      if delta == zero { delta = conf.stepfactor }
    }
    /*
     *	 form (q transpose)*fvec and store the first n components in
     *	 qtf.
     */
    for i in range(m) {
      wa4[i] = fvec[i]
    }
    jj = 0
    for j in range(nfree) {
      temp3 = fjac[jj]
      if temp3 != zero {
        sum = zero
        ij = jj
        for i in range(j, m) {
          sum += fjac[ij] * wa4[i]
          ij += 1	/* fjac[i+m*j] */
        }
        temp = -sum / temp3
        ij = jj
        for i in range(j, m) {
          wa4[i] += fjac[ij] * temp
          ij += 1	/* fjac[i+m*j] */
        }
      }
      fjac[jj] = wa1[j]
      jj += m+1	/* fjac[j+m*j] */
      qtf[j] = wa4[j]
    }
    /* ( From this point on, only the square matrix, consisting of the
       triangle of R, is needed.) */
    if conf.nofinitecheck {
      /* Check for overflow.  This should be a cheap test here since FJAC
         has been reduced to a (small) square matrix, and the test is
         O(N^2). */
      var off: Int = 0
      var nonfinite: Int = 0
      for j in range(nfree) {
        for i in range(nfree) {
          if mpfinite(fjac[off+i]) == 0 { nonfinite = 1 }
        }
        off += ldfjac
      }
      if nonfinite {
        info = MP_ERR_NAN
        goto CLEANUP
      }
    }
    /*
     *	 compute the norm of the scaled gradient.
     */
    gnorm = zero
    if fnorm != zero {
      jj = 0
      for j in range(nfree) {
        l = ipvt[j]
        if wa2[l] != zero {
          sum = zero
          ij = jj
          for i in range(j+1) {
            sum += fjac[ij]*(qtf[i]/fnorm)
            ij += 1 /* fjac[i+m*j] */
          }
          gnorm = mp_dmax1(gnorm, fabs(sum/wa2[l]))
        }
        jj += m
      }
    }
    /*
     *	 test for convergence of the gradient norm.
     */
    if gnorm <= conf.gtol { info = MP_OK_DIR }
    if info != 0 { goto L300 }
    if conf.maxiter == 0 { goto L300 }
    /*
     *	 rescale if necessary.
     */
    if conf.douserscale == 0 {
      for j in range(nfree) {
        diag[ifree[j]] = mp_dmax1(diag[ifree[j]], wa2[j])
      }
    }
    /*
     *	 beginning of the inner loop.
     */
    inner_loop = True
    while inner_loop:
      # L200:
      /*
       *	    determine the levenberg-marquardt parameter.
       */
      mp_lmpar(nfree, fjac, ldfjac, ipvt, ifree, diag, qtf, delta, par, wa1, wa2, wa3, wa4)
      /*
       *	    store the direction p and x + p. calculate the norm of p.
       */
      for j in range(nfree) {
        wa1[j] = -wa1[j]
      }
      alpha = 1.0
      if qanylim == 0 {
        /* No parameter limits, so just move to new position WA2 */
        for j in range(nfree) {
          wa2[j] = x[j] + wa1[j]
        }
      } else {
        /* Respect the limits.  If a step were to go out of bounds, then 
         * we should take a step in the same direction but shorter distance.
         * The step should take us right to the limit in that case.
         */
        for j in range(nfree) {
          var lpegged: Int = (qllim[j] and (x[j] <= llim[j])) ? 1 : 0
          var upegged: Int = (qulim[j] and (x[j] >= ulim[j])) ? 1 : 0
          var dwa1: Int = (fabs(wa1[j]) > MP_MACHEP0) ? 1 : 0
          if lpegged and (wa1[j] < 0) { wa1[j] = 0 }
          if upegged and (wa1[j] > 0) { wa1[j] = 0 }
          if dwa1 and qllim[j] and ((x[j] + wa1[j]) < llim[j]) {
            alpha = mp_dmin1(alpha, (llim[j]-x[j])/wa1[j])
          }
          if dwa1 and qulim[j] and ((x[j] + wa1[j]) > ulim[j]) {
            alpha = mp_dmin1(alpha, (ulim[j]-x[j])/wa1[j])
          }
        }
        /* Scale the resulting vector, advance to the next position */
        for j in range(nfree) {
          var sgnu: Float64, sgnl: Float64
          var ulim1: Float64, llim1: Float64
          wa1[j] = wa1[j] * alpha
          wa2[j] = x[j] + wa1[j]
          /* Adjust the output values.  If the step put us exactly
           * on a boundary, make sure it is exact.
           */
          sgnu = (ulim[j] >= 0) ? 1.0 : -1.0
          sgnl = (llim[j] >= 0) ? 1.0 : -1.0
          ulim1 = ulim[j]*(1-sgnu*MP_MACHEP0) - ((ulim[j] == 0) ? MP_MACHEP0 : 0)
          llim1 = llim[j]*(1+sgnl*MP_MACHEP0) + ((llim[j] == 0) ? MP_MACHEP0 : 0)
          if qulim[j] and (wa2[j] >= ulim1) {
            wa2[j] = ulim[j]
          }
          if qllim[j] and (wa2[j] <= llim1) {
            wa2[j] = llim[j]
          }
        }
      }
      for j in range(nfree) {
        wa3[j] = diag[ifree[j]]*wa1[j]
      }
      pnorm = mp_enorm(nfree, wa3)
      /*
       *	    on the first iteration, adjust the initial step bound.
       */
      if iter == 1 {
        delta = mp_dmin1(delta, pnorm)
      }
      /*
       *	    evaluate the function at x + p and calculate its norm.
       */
      for i in range(nfree) {
        xnew[ifree[i]] = wa2[i]
      }
      iflag = funct(m, npar, xnew, wa4, nil, private_data)
      nfev += 1
      if iflag < 0 { goto L300 }
      fnorm1 = mp_enorm(m, wa4)
      /*
       *	    compute the scaled actual reduction.
       */
      actred = -one
      if (p1*fnorm1) < fnorm {
        temp = fnorm1/fnorm
        actred = one - temp * temp
      }
      /*
       *	    compute the scaled predicted reduction and
       *	    the scaled directional derivative.
       */
      jj = 0
      for j in range(nfree) {
        wa3[j] = zero
        l = ipvt[j]
        temp = wa1[l]
        ij = jj
        for i in range(j+1) {
          wa3[i] += fjac[ij]*temp
          ij += 1 /* fjac[i+m*j] */
        }
        jj += m
      }
      /* Remember, alpha is the fraction of the full LM step actually
       * taken
       */
      temp1 = mp_enorm(nfree, wa3)*alpha/fnorm
      temp2 = (sqrt(alpha*par)*pnorm)/fnorm
      prered = temp1*temp1 + (temp2*temp2)/p5
      dirder = -(temp1*temp1 + temp2*temp2)
      /*
       *	    compute the ratio of the actual to the predicted
       *	    reduction.
       */
      ratio = zero
      if prered != zero {
        ratio = actred/prered
      }
      /*
       *	    update the step bound.
       */
      if ratio <= p25 {
        if actred >= zero {
          temp = p5
        } else {
          temp = p5*dirder/(dirder + p5*actred)
        }
        if ((p1*fnorm1) >= fnorm) or (temp < p1) {
          temp = p1
        }
        delta = temp*mp_dmin1(delta, pnorm/p1)
        par = par/temp
      } else {
        if (par == zero) or (ratio >= p75) {
          delta = pnorm/p5
          par = p5*par
        }
      }
      /*
       *	    test for successful iteration.
       */
      if ratio >= p0001 {
        /*
         *	    successful iteration. update x, fvec, and their norms.
         */
        for j in range(nfree) {
          x[j] = wa2[j]
          wa2[j] = diag[ifree[j]]*x[j]
        }
        for i in range(m) {
          fvec[i] = wa4[i]
        }
        xnorm = mp_enorm(nfree, wa2)
        fnorm = fnorm1
        iter += 1
      }
      /*
       *	    tests for convergence.
       */
      if (fabs(actred) <= conf.ftol) and (prered <= conf.ftol) and 
          (p5*ratio <= one) {
        info = MP_OK_CHI
      }
      if delta <= conf.xtol*xnorm {
        info = MP_OK_PAR
      }
      if (fabs(actred) <= conf.ftol) and (prered <= conf.ftol) and (p5*ratio <= one)
          and (info == 2) {
        info = MP_OK_BOTH
      }
      if info != 0 {
        goto L300
      }
      /*
       *	    tests for termination and stringent tolerances.
       */
      if (conf.maxfev > 0) and (nfev >= conf.maxfev) {
        /* Too many function evaluations */
        info = MP_MAXITER
      }
      if iter >= conf.maxiter {
        /* Too many iterations */
        info = MP_MAXITER
      }
      if (fabs(actred) <= MP_MACHEP0) and (prered <= MP_MACHEP0) and (p5*ratio <= one) {
        info = MP_FTOL
      }
      if delta <= MP_MACHEP0*xnorm {
        info = MP_XTOL
      }
      if gnorm <= MP_MACHEP0 {
        info = MP_GTOL
      }
      if info != 0 {
        goto L300
      }
      /*
       *	    end of the inner loop. repeat if iteration unsuccessful.
       */
      if ratio < p0001 {
        continue  # goto L200
      }
      break  # successful iteration -> outer loop
    /* end inner loop */
    continue  # goto OUTER_LOOP
  # end outer loop

  L300:
  /*
   *     termination, either normal or user imposed.
   */
  if iflag < 0 {
    info = iflag
  }
  iflag = 0
  for i in range(nfree) {
    xall[ifree[i]] = x[i]
  }
  if (conf.nprint > 0) and (info > 0) {
    iflag = funct(m, npar, xall, fvec, nil, private_data)
    nfev += 1
  }
  /* Compute number of pegged parameters */
  npegged = 0
  if pars != nil {
    for i in range(npar) {
      if ((pars[i].limited[0] and (pars[i].limits[0] == xall[i])) or
          (pars[i].limited[1] and (pars[i].limits[1] == xall[i]))) {
        npegged += 1
      }
    }
  }
  /* Compute and return the covariance matrix and/or parameter errors */
  if (result != nil) and (result.covar != nil) or (result.xerror != nil) {
    mp_covar(nfree, fjac, ldfjac, ipvt, conf.covtol, wa2)
    if result.covar != nil {
      /* Zero the destination covariance array */
      for j in range(npar*npar) { result.covar[j] = 0 }
      /* Transfer the covariance array */
      for j in range(nfree) {
        for i in range(nfree) {
          result.covar[ifree[j]*npar+ifree[i]] = fjac[j*ldfjac+i]
        }
      }
    }
    if result.xerror != nil {
      for j in range(npar) { result.xerror[j] = 0 }
      for j in range(nfree) {
        var cc: Float64 = fjac[j*ldfjac+j]
        if cc > 0 { result.xerror[ifree[j]] = sqrt(cc) }
      }
    }
  }      
  if result != nil {
    // strcpy(result.version, MPFIT_VERSION)
    # In Mojo, we need to copy string; for simplicity use copy
    for k in range(20) {
      if k < len(MPFIT_VERSION) { result.version[k] = MPFIT_VERSION[k] }
      else { result.version[k] = 0 }
    }
    result.bestnorm = mp_dmax1(fnorm, fnorm1)
    result.bestnorm = result.bestnorm * result.bestnorm
    result.orignorm = orignorm
    result.status   = info
    result.niter    = iter
    result.nfev     = nfev
    result.npar     = npar
    result.nfree    = nfree
    result.npegged  = npegged
    result.nfunc    = m
    /* Copy residuals if requested */
    if result.resid != nil {
      for j in range(m) { result.resid[j] = fvec[j] }
    }
  }

  CLEANUP:
  if fvec != nil { free[Float64](fvec) }
  if qtf  != nil { free[Float64](qtf) }
  if x    != nil { free[Float64](x) }
  if xnew != nil { free[Float64](xnew) }
  if fjac != nil { free[Float64](fjac) }
  if diag != nil { free[Float64](diag) }
  if wa1  != nil { free[Float64](wa1) }
  if wa2  != nil { free[Float64](wa2) }
  if wa3  != nil { free[Float64](wa3) }
  if wa4  != nil { free[Float64](wa4) }
  if ipvt != nil { free[Int](ipvt) }
  if pfixed != nil { free[Int](pfixed) }
  if step != nil { free[Float64](step) }
  if dstep != nil { free[Float64](dstep) }
  if mpside != nil { free[Int](mpside) }
  if ddebug != nil { free[Int](ddebug) }
  if ddrtol != nil { free[Float64](ddrtol) }
  if ddatol != nil { free[Float64](ddatol) }
  if ifree != nil { free[Int](ifree) }
  if qllim != nil { free[Int](qllim) }
  if qulim != nil { free[Int](qulim) }
  if llim  != nil { free[Float64](llim) }
  if ulim  != nil { free[Float64](ulim) }
  return info
}
/************************fdjac2.c*************************/
def mp_fdjac2(funct: mp_func,
	      m: Int, n: Int, def ifree: Pointer[Int], npar: Int, def x: Pointer[Float64], def fvec: Pointer[Float64],
	      def fjac: Pointer[Float64], ldfjac: Int, epsfcn: Float64,
	      def wa: Pointer[Float64], priv: Int, def nfev: Pointer[Int],
	      def step: Pointer[Float64], def dstep: Pointer[Float64], def dside: Pointer[Int],
	      def qulimited: Pointer[Int], def ulimit: Pointer[Float64],
	      def ddebug: Pointer[Int], def ddrtol: Pointer[Float64], def ddatol: Pointer[Float64]) -> Int
{
  var i: Int, j: Int, ij: Int
  var iflag: Int = 0
  var eps: Float64, h: Float64, temp: Float64
  var zero: Float64 = 0.0
  var dvec: Pointer[Pointer[Float64]] = nil
  var has_analytical_deriv: Int = 0
  var has_numerical_deriv: Int = 0
  var has_debug_deriv: Int = 0
  temp = mp_dmax1(epsfcn, MP_MACHEP0)
  eps = sqrt(temp)
  ij = 0
  ldfjac = 0 /* Prevents compiler warning */
  if mp_malloc_pp(dvec, npar) != 0 { return MP_ERR_MEMORY }
  for j in range(npar) { dvec[j] = nil }
  /* Initialize the Jacobian derivative matrix */
  for j in range(n*m) { fjac[j] = 0 }
  /* Check for which parameters need analytical derivatives and which
     need numerical ones */
  for j in range(n) {  /* Loop through free parameters only */
    if dside != nil and dside[ifree[j]] == 3 and ddebug[ifree[j]] == 0 {
      /* Purely analytical derivatives */
      dvec[ifree[j]] = fjac.offset(j*m)
      has_analytical_deriv = 1
    } else if dside != nil and ddebug[ifree[j]] == 1 {
      /* Numerical and analytical derivatives as a debug cross-check */
      dvec[ifree[j]] = fjac.offset(j*m)
      has_analytical_deriv = 1
      has_numerical_deriv = 1
      has_debug_deriv = 1
    } else {
      has_numerical_deriv = 1
    }
  }
  /* If there are any parameters requiring analytical derivatives,
     then compute them first. */
  if has_analytical_deriv {
    iflag = funct(m, npar, x, wa, dvec, priv)
    if nfev != nil { *nfev = *nfev + 1 }
    if iflag < 0 { goto DONE }
  }
  if has_debug_deriv {
    printf("FJAC DEBUG BEGIN\n")
    printf("#  %10s %10s %10s %10s %10s %10s\n", 
	   "IPNT", "FUNC", "DERIV_U", "DERIV_N", "DIFF_ABS", "DIFF_REL")
  }
  /* Any parameters requiring numerical derivatives */
  if has_numerical_deriv {
    for j in range(n) {  /* Loop thru free parms */
      var dsidei: Int = (dside != nil) ? dside[ifree[j]] : 0
      var debug: Int = ddebug[ifree[j]]
      var dr: Float64 = ddrtol[ifree[j]]
      var da: Float64 = ddatol[ifree[j]]
      /* Check for debugging */
      if debug {
        printf("FJAC PARM %d\n", ifree[j])
      }
      /* Skip parameters already done by user-computed partials */
      if dside != nil and dsidei == 3 { continue }
      temp = x[ifree[j]]
      h = eps * fabs(temp)
      if step != nil and step[ifree[j]] > 0 { h = step[ifree[j]] }
      if dstep != nil and dstep[ifree[j]] > 0 { h = fabs(dstep[ifree[j]]*temp) }
      if h == zero { h = eps }
      /* If negative step requested, or we are against the upper limit */
      if (dside != nil and dsidei == -1) or 
         (dside != nil and dsidei == 0 and 
          qulimited != nil and ulimit != nil and qulimited[j] and 
          (temp > (ulimit[j]-h))) {
        h = -h
      }
      x[ifree[j]] = temp + h
      iflag = funct(m, npar, x, wa, nil, priv)
      if nfev != nil { *nfev = *nfev + 1 }
      if iflag < 0 { goto DONE }
      x[ifree[j]] = temp
      if dsidei <= 1 {
        /* COMPUTE THE ONE-SIDED DERIVATIVE */
        if debug == 0 {
          /* Non-debug path for speed */
          for i in range(m) {
            fjac[ij] = (wa[i] - fvec[i])/h /* fjac[i+m*j] */
            ij += 1
          }
        } else {
          /* Debug path for correctness */
          for i in range(m) {
            var fjold: Float64 = fjac[ij]
            fjac[ij] = (wa[i] - fvec[i])/h /* fjac[i+m*j] */
            if ((da == 0 and dr == 0 and (fjold != 0 or fjac[ij] != 0)) or
                ((da != 0 or dr != 0) and (fabs(fjold-fjac[ij]) > da + fabs(fjold)*dr))) {
              printf("   %10d %10.4g %10.4g %10.4g %10.4g %10.4g\n", 
		     i, fvec[i], fjold, fjac[ij], fjold-fjac[ij], 
		     (fjold == 0) ? 0.0 : ((fjold-fjac[ij])/fjold))
            }
            ij += 1
          }
        }
      } else {
        /* COMPUTE THE TWO-SIDED DERIVATIVE */
        for i in range(m) {
          fjac[ij] = wa[i]    /* Store temp data: fjac[i+m*j] */
          ij += 1
        }
        /* Evaluate at x - h */
        x[ifree[j]] = temp - h
        iflag = funct(m, npar, x, wa, nil, priv)
        if nfev != nil { *nfev = *nfev + 1 }
        if iflag < 0 { goto DONE }
        x[ifree[j]] = temp
        /* Now compute derivative as (f(x+h) - f(x-h))/(2h) */
        ij -= m
        if debug == 0 {
          for i in range(m) {
            fjac[ij] = (fjac[ij] - wa[i])/(2*h) /* fjac[i+m*j] */
            ij += 1
          }
        } else {
          for i in range(m) {
            var fjold: Float64 = fjac[ij]
            fjac[ij] = (fjac[ij] - wa[i])/(2*h) /* fjac[i+m*j] */
            if ((da == 0 and dr == 0 and (fjold != 0 or fjac[ij] != 0)) or
                ((da != 0 or dr != 0) and (fabs(fjold-fjac[ij]) > da + fabs(fjold)*dr))) {
              printf("   %10d %10.4g %10.4g %10.4g %10.4g %10.4g\n", 
		     i, fvec[i], fjold, fjac[ij], fjold-fjac[ij], 
		     (fjold == 0) ? 0.0 : ((fjold-fjac[ij])/fjold))
            }
            ij += 1
          }
        }	
      }
    }
  }
  if has_debug_deriv {
    printf("FJAC DEBUG END\n")
  }

  DONE:
  if dvec != nil { free[Pointer[Float64]](dvec) }
  if iflag < 0 { return iflag }
  return 0 
}
/************************qrfac.c*************************/
def mp_qrfac(m: Int, n: Int, def a: Pointer[Float64], lda: Int, 
	      pivot: Int, def ipvt: Pointer[Int], lipvt: Int,
	      def rdiag: Pointer[Float64], def acnorm: Pointer[Float64], def wa: Pointer[Float64])
{
  var i: Int, ij: Int, jj: Int, j: Int, jp1: Int, k: Int, kmax: Int, minmn: Int
  var ajnorm: Float64, sum: Float64, temp: Float64
  var zero: Float64 = 0.0
  var one: Float64 = 1.0
  var p05: Float64 = 0.05
  lda = 0   /* Prevent compiler warning */
  lipvt = 0 /* Prevent compiler warning */
  /*
   *     compute the initial column norms and initialize several arrays.
   */
  ij = 0
  for j in range(n) {
    acnorm[j] = mp_enorm(m, a.offset(ij))
    rdiag[j] = acnorm[j]
    wa[j] = rdiag[j]
    if pivot != 0 { ipvt[j] = j }
    ij += m /* m*j */
  }
  /*
   *     reduce a to r with householder transformations.
   */
  minmn = mp_min0(m, n)
  for j in range(minmn) {
    if pivot == 0 { goto L40 }
    /*
     *	 bring the column of largest norm into the pivot position.
     */
    kmax = j
    for k in range(j, n) {
      if rdiag[k] > rdiag[kmax] { kmax = k }
    }
    if kmax == j { goto L40 }
    ij = m * j
    jj = m * kmax
    for i in range(m) {
      temp = a[ij] /* [i+m*j] */
      a[ij] = a[jj] /* [i+m*kmax] */
      a[jj] = temp
      ij += 1
      jj += 1
    }
    rdiag[kmax] = rdiag[j]
    wa[kmax] = wa[j]
    k = ipvt[j]
    ipvt[j] = ipvt[kmax]
    ipvt[kmax] = k
  L40:
    /*
     *	 compute the householder transformation to reduce the
     *	 j-th column of a to a multiple of the j-th unit vector.
     */
    jj = j + m*j
    ajnorm = mp_enorm(m-j, a.offset(jj))
    if ajnorm == zero { goto L100 }
    if a[jj] < zero { ajnorm = -ajnorm }
    ij = jj
    for i in range(j, m) {
      a[ij] /= ajnorm
      ij += 1 /* [i+m*j] */
    }
    a[jj] += one
    /*
     *	 apply the transformation to the remaining columns
     *	 and update the norms.
     */
    jp1 = j + 1
    if jp1 < n {
      for k in range(jp1, n) {
        sum = zero
        ij = j + m*k
        jj = j + m*j
        for i in range(j, m) {
          sum += a[jj]*a[ij]
          ij += 1 /* [i+m*k] */
          jj += 1 /* [i+m*j] */
        }
        temp = sum/a[j+m*j]
        ij = j + m*k
        jj = j + m*j
        for i in range(j, m) {
          a[ij] -= temp*a[jj]
          ij += 1 /* [i+m*k] */
          jj += 1 /* [i+m*j] */
        }
        if (pivot != 0) and (rdiag[k] != zero) {
          temp = a[j+m*k]/rdiag[k]
          temp = mp_dmax1(zero, one-temp*temp)
          rdiag[k] *= sqrt(temp)
          temp = rdiag[k]/wa[k]
          if (p05*temp*temp) <= MP_MACHEP0 {
            rdiag[k] = mp_enorm(m-j-1, a.offset(jp1+m*k))
            wa[k] = rdiag[k]
          }
        }
      }
    }
  L100:
    rdiag[j] = -ajnorm
  }
}
/************************qrsolv.c*************************/
def mp_qrsolv(n: Int, def r: Pointer[Float64], ldr: Int, def ipvt: Pointer[Int], def diag: Pointer[Float64],
	       def qtb: Pointer[Float64], def x: Pointer[Float64], def sdiag: Pointer[Float64], def wa: Pointer[Float64])
{
  var i: Int, ij: Int, ik: Int, kk: Int, j: Int, jp1: Int, k: Int, kp1: Int, l: Int, nsing: Int
  var cosx: Float64, cotan: Float64, qtbpj: Float64, sinx: Float64, sum: Float64, tanx: Float64, temp: Float64
  var zero: Float64 = 0.0
  var p25: Float64 = 0.25
  var p5: Float64 = 0.5
  /*
   *     copy r and (q transpose)*b to preserve input and initialize s.
   *     in particular, save the diagonal elements of r in x.
   */
  kk = 0
  for j in range(n) {
    ij = kk
    ik = kk
    for i in range(j, n) {
      r[ij] = r[ik]
      ij += 1   /* [i+ldr*j] */
      ik += ldr /* [j+ldr*i] */
    }
    x[j] = r[kk]
    wa[j] = qtb[j]
    kk += ldr+1 /* j+ldr*j */
  }
  /*
   *     eliminate the diagonal matrix d using a givens rotation.
   */
  for j in range(n) {
    /*
     *	 prepare the row of d to be eliminated, locating the
     *	 diagonal element using p from the qr factorization.
     */
    l = ipvt[j]
    if diag[l] == zero { goto L90 }
    for k in range(j, n) { sdiag[k] = zero }
    sdiag[j] = diag[l]
    /*
     *	 the transformations to eliminate the row of d
     *	 modify only a single element of (q transpose)*b
     *	 beyond the first n, which is initially zero.
     */
    qtbpj = zero
    for k in range(j, n) {
      /*
       *	    determine a givens rotation which eliminates the
       *	    appropriate element in the current row of d.
       */
      if sdiag[k] == zero { continue }
      kk = k + ldr * k
      if fabs(r[kk]) < fabs(sdiag[k]) {
        cotan = r[kk]/sdiag[k]
        sinx = p5/sqrt(p25+p25*cotan*cotan)
        cosx = sinx*cotan
      } else {
        tanx = sdiag[k]/r[kk]
        cosx = p5/sqrt(p25+p25*tanx*tanx)
        sinx = cosx*tanx
      }
      /*
       *	    compute the modified diagonal element of r and
       *	    the modified element of ((q transpose)*b,0).
       */
      r[kk] = cosx*r[kk] + sinx*sdiag[k]
      temp = cosx*wa[k] + sinx*qtbpj
      qtbpj = -sinx*wa[k] + cosx*qtbpj
      wa[k] = temp
      /*
       *	    accumulate the tranformation in the row of s.
       */
      kp1 = k + 1
      if n > kp1 {
        ik = kk + 1
        for i in range(kp1, n) {
          temp = cosx*r[ik] + sinx*sdiag[i]
          sdiag[i] = -sinx*r[ik] + cosx*sdiag[i]
          r[ik] = temp
          ik += 1 /* [i+ldr*k] */
        }
      }
    }
  L90:
    /*
     *	 store the diagonal element of s and restore
     *	 the corresponding diagonal element of r.
     */
    kk = j + ldr*j
    sdiag[j] = r[kk]
    r[kk] = x[j]
  }
  /*
   *     solve the triangular system for z. if the system is
   *     singular, then obtain a least squares solution.
   */
  nsing = n
  for j in range(n) {
    if (sdiag[j] == zero) and (nsing == n) { nsing = j }
    if nsing < n { wa[j] = zero }
  }
  if nsing < 1 { goto L150 }
  for k in range(nsing) {
    j = nsing - k - 1
    sum = zero
    jp1 = j + 1
    if nsing > jp1 {
      ij = jp1 + ldr * j
      for i in range(jp1, nsing) {
        sum += r[ij]*wa[i]
        ij += 1 /* [i+ldr*j] */
      }
    }
    wa[j] = (wa[j] - sum)/sdiag[j]
  }
 L150:
  /*
   *     permute the components of z back to components of x.
   */
  for j in range(n) {
    l = ipvt[j]
    x[l] = wa[j]
  }
}
/************************lmpar.c*************************/
def mp_lmpar(n: Int, def r: Pointer[Float64], ldr: Int, def ipvt: Pointer[Int], def ifree: Pointer[Int], def diag: Pointer[Float64],
	      def qtb: Pointer[Float64], delta: Float64, def par: Pointer[Float64], def x: Pointer[Float64],
	      def sdiag: Pointer[Float64], def wa1: Pointer[Float64], def wa2: Pointer[Float64]) 
{
  var i: Int, iter: Int, ij: Int, jj: Int, j: Int, jm1: Int, jp1: Int, k: Int, l: Int, nsing: Int
  var dxnorm: Float64, fp: Float64, gnorm: Float64, parc: Float64, parl: Float64, paru: Float64
  var sum: Float64, temp: Float64
  var zero: Float64 = 0.0
  var p1: Float64 = 0.1
  var p001: Float64 = 0.001
  /*
   *     compute and store in x the gauss-newton direction. if the
   *     jacobian is rank-deficient, obtain a least squares solution.
   */
  nsing = n
  jj = 0
  for j in range(n) {
    wa1[j] = qtb[j]
    if (r[jj] == zero) and (nsing == n) { nsing = j }
    if nsing < n { wa1[j] = zero }
    jj += ldr+1 /* [j+ldr*j] */
  }
  if nsing >= 1 {
    for k in range(nsing) {
      j = nsing - k - 1
      wa1[j] = wa1[j]/r[j+ldr*j]
      temp = wa1[j]
      jm1 = j - 1
      if jm1 >= 0 {
        ij = ldr * j
        for i in range(jm1+1) {
          wa1[i] -= r[ij]*temp
          ij += 1
        }
      }
    }
  }
  for j in range(n) {
    l = ipvt[j]
    x[l] = wa1[j]
  }
  /*
   *     initialize the iteration counter.
   *     evaluate the function at the origin, and test
   *     for acceptance of the gauss-newton direction.
   */
  iter = 0
  for j in range(n) { wa2[j] = diag[ifree[j]]*x[j] }
  dxnorm = mp_enorm(n, wa2)
  fp = dxnorm - delta
  if fp <= p1*delta { goto L220 }
  /*
   *     if the jacobian is not rank deficient, the newton
   *     step provides a lower bound, parl, for the zero of
   *     the function. otherwise set this bound to zero.
   */
  parl = zero
  if nsing >= n {
    for j in range(n) {
      l = ipvt[j]
      wa1[j] = diag[ifree[l]]*(wa2[l]/dxnorm)
    }
    jj = 0
    for j in range(n) {
      sum = zero
      jm1 = j - 1
      if jm1 >= 0 {
        ij = jj
        for i in range(jm1+1) {
          sum += r[ij]*wa1[i]
          ij += 1
        }
      }
      wa1[j] = (wa1[j] - sum)/r[j+ldr*j]
      jj += ldr /* [i+ldr*j] */
    }
    temp = mp_enorm(n, wa1)
    parl = ((fp/delta)/temp)/temp
  }
  /*
   *     calculate an upper bound, paru, for the zero of the function.
   */
  jj = 0
  for j in range(n) {
    sum = zero
    ij = jj
    for i in range(j+1) {
      sum += r[ij]*qtb[i]
      ij += 1
    }
    l = ipvt[j]
    wa1[j] = sum/diag[ifree[l]]
    jj += ldr /* [i+ldr*j] */
  }
  gnorm = mp_enorm(n, wa1)
  paru = gnorm/delta
  if paru == zero { paru = MP_DWARF/mp_dmin1(delta, p1) }
  /*
   *     if the input par lies outside of the interval (parl,paru),
   *     set par to the closer endpoint.
   */
  *par = mp_dmax1(*par, parl)
  *par = mp_dmin1(*par, paru)
  if *par == zero { *par = gnorm/dxnorm }
  /*
   *     beginning of an iteration.
   */
 L150:
  iter += 1
  /*
   *	 evaluate the function at the current value of par.
   */
  if *par == zero { *par = mp_dmax1(MP_DWARF, p001*paru) }
  temp = sqrt(*par)
  for j in range(n) { wa1[j] = temp*diag[ifree[j]] }
  mp_qrsolv(n, r, ldr, ipvt, wa1, qtb, x, sdiag, wa2)
  for j in range(n) { wa2[j] = diag[ifree[j]]*x[j] }
  dxnorm = mp_enorm(n, wa2)
  temp = fp
  fp = dxnorm - delta
  /*
   *	 if the function is small enough, accept the current value
   *	 of par. also test for the exceptional cases where parl
   *	 is zero or the number of iterations has reached 10.
   */
  if (fabs(fp) <= p1*delta)
      or ((parl == zero) and (fp <= temp) and (temp < zero))
      or (iter == 10) { goto L220 }
  /*
   *	 compute the newton correction.
   */
  for j in range(n) {
    l = ipvt[j]
    wa1[j] = diag[ifree[l]]*(wa2[l]/dxnorm)
  }
  jj = 0
  for j in range(n) {
    wa1[j] = wa1[j]/sdiag[j]
    temp = wa1[j]
    jp1 = j + 1
    if jp1 < n {
      ij = jp1 + jj
      for i in range(jp1, n) {
        wa1[i] -= r[ij]*temp
        ij += 1 /* [i+ldr*j] */
      }
    }
    jj += ldr /* ldr*j */
  }
  temp = mp_enorm(n, wa1)
  parc = ((fp/delta)/temp)/temp
  /*
   *	 depending on the sign of the function, update parl or paru.
   */
  if fp > zero { parl = mp_dmax1(parl, *par) }
  if fp < zero { paru = mp_dmin1(paru, *par) }
  /*
   *	 compute an improved estimate for par.
   */
  *par = mp_dmax1(parl, *par + parc)
  /*
   *	 end of an iteration.
   */
  goto L150
 L220:
  /*
   *     termination.
   */
  if iter == 0 { *par = zero }
}
/************************enorm.c*************************/
def mp_enorm(n: Int, def x: Pointer[Float64]) -> Float64
{
  var i: Int
  var agiant: Float64, floatn: Float64, s1: Float64, s2: Float64, s3: Float64, xabs: Float64, x1max: Float64, x3max: Float64
  var ans: Float64, temp: Float64
  var rdwarf: Float64 = MP_RDWARF
  var rgiant: Float64 = MP_RGIANT
  var zero: Float64 = 0.0
  var one: Float64 = 1.0
  s1 = zero
  s2 = zero
  s3 = zero
  x1max = zero
  x3max = zero
  floatn = n as Float64
  agiant = rgiant/floatn
  for i in range(n) {
    xabs = fabs(x[i])
    if (xabs > rdwarf) and (xabs < agiant) {
      /*
       *	    sum for intermediate components.
       */
      s2 += xabs*xabs
      continue
    }
    if xabs > rdwarf {
      /*
       *	       sum for large components.
       */
      if xabs > x1max {
        temp = x1max/xabs
        s1 = one + s1*temp*temp
        x1max = xabs
      } else {
        temp = xabs/x1max
        s1 += temp*temp
      }
      continue
    }
    /*
     *	       sum for small components.
     */
    if xabs > x3max {
      temp = x3max/xabs
      s3 = one + s3*temp*temp
      x3max = xabs
    } else {
      if xabs != zero {
        temp = xabs/x3max
        s3 += temp*temp
      }
    }
  }
  /*
   *     calculation of norm.
   */
  if s1 != zero {
    temp = s1 + (s2/x1max)/x1max
    ans = x1max*sqrt(temp)
    return ans
  }
  if s2 != zero {
    if s2 >= x3max {
      temp = s2*(one+(x3max/s2)*(x3max*s3))
    } else {
      temp = x3max*((s2/x3max)+(x3max*s3))
    }
    ans = sqrt(temp)
  } else {
    ans = x3max*sqrt(s3)
  }
  return ans
}
/************************lmmisc.c*************************/
def mp_dmax1(a: Float64, b: Float64) -> Float64
{
  if a >= b { return a }
  else { return b }
}
def mp_dmin1(a: Float64, b: Float64) -> Float64
{
  if a <= b { return a }
  else { return b }
}
def mp_min0(a: Int, b: Int) -> Int
{
  if a <= b { return a }
  else { return b }
}
/************************covar.c*************************/
def mp_covar(n: Int, def r: Pointer[Float64], ldr: Int, def ipvt: Pointer[Int], tol: Float64, def wa: Pointer[Float64]) -> Int
{
  var i: Int, ii: Int, j: Int, jj: Int, k: Int, l: Int
  var kk: Int, kj: Int, ji: Int, j0: Int, k0: Int, jj0: Int
  var sing: Int
  var one: Float64 = 1.0, temp: Float64, tolr: Float64, zero: Float64 = 0.0
  /*
   * form the inverse of r in the full upper triangle of r.
   */
#if 0
  for (j=0; j<n; j++) {
    for (i=0; i<n; i++) {
      printf("%f ", r[j*ldr+i]);
    }
    printf("\n");
  }
#endif
  tolr = tol*fabs(r[0])
  l = -1
  for k in range(n) {
    kk = k*ldr + k
    if fabs(r[kk]) <= tolr { break }
    r[kk] = one/r[kk]
    for j in range(k) {
      kj = k*ldr + j
      temp = r[kk] * r[kj]
      r[kj] = zero
      k0 = k*ldr
      j0 = j*ldr
      for i in range(j+1) {
        r[k0+i] += (-temp*r[j0+i])
      }
    }
    l = k
  }
  /* 
   * Form the full upper triangle of the inverse of (r transpose)*r
   * in the full upper triangle of r
   */
  if l >= 0 {
    for k in range(l+1) {
      k0 = k*ldr
      for j in range(k) {
        temp = r[k*ldr+j]
        j0 = j*ldr
        for i in range(j+1) {
          r[j0+i] += temp*r[k0+i]
        }
      }
      temp = r[k0+k]
      for i in range(k+1) {
        r[k0+i] *= temp
      }
    }
  }
  /*
   * For the full lower triangle of the covariance matrix
   * in the strict lower triangle or and in wa
   */
  for j in range(n) {
    jj = ipvt[j]
    sing = 1 if (j > l) else 0
    j0 = j*ldr
    jj0 = jj*ldr
    for i in range(j+1) {
      ji = j0+i
      if sing { r[ji] = zero }
      ii = ipvt[i]
      if ii > jj { r[jj0+ii] = r[ji] }
      if ii < jj { r[ii*ldr+jj] = r[ji] }
    }
    wa[jj] = r[j0+j]
  }
  /*
   * Symmetrize the covariance matrix in r
   */
  for j in range(n) {
    j0 = j*ldr
    for i in range(j) {
      r[j0+i] = r[i*ldr+j]
    }
    r[j0+j] = wa[j]
  }
#if 0
  for (j=0; j<n; j++) {
    for (i=0; i<n; i++) {
      printf("%f ", r[j*ldr+i]);
    }
    printf("\n");
  }
#endif
  return 0
}
struct lsq_vars_struct {
  var x: Pointer[Float64]
  var y: Pointer[Float64]
  var function: fn(Float64, Pointer[Float64], Int) -> Float64
  var user_data: Int
}
def mpcall(m: Int, n: Int, def p: Pointer[Float64], def dy: Pointer[Float64