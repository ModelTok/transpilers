from math import sqrt, fabs

# /*
# ************************************************************************
# *	    		    C math library
# * function FMINBR - one-dimensional search for a function minimum
# *			  over the given range
# *
# * Input
# *	double fminbr(a,b,f,tol)
# *	double a; 			Minimum will be seeked for over
# *	double b;  			a range [a,b], a being < b.
# *	double (*f)(double x);		Name of the function whose minimum
# *					will be seeked for
# *	double tol;			Acceptable tolerance for the minimum
# *					location. It have to be positive
# *					(e.g. may be specified as EPSILON)
# *
# * Output
# *	Fminbr returns an estimate for the minimum location with accuracy
# *	3*SQRT_EPSILON*abs(x) + tol.
# *	The function always obtains a local minimum which coincides with
# *	the global one only if a function under investigation being
# *	unimodular.
# *	If a function being examined possesses no local minimum within
# *	the given range, Fminbr returns 'a' (if f(a) < f(b)), otherwise
# *	it returns the right range boundary value b.
# *
# * Algorithm
# *	G.Forsythe, M.Malcolm, C.Moler, Computer methods for mathematical
# *	computations. M., Mir, 1980, p.202 of the Russian edition
# *
# *	The function makes use of the "gold section" procedure combined with
# *	the parabolic interpolation.
# *	At every step program operates three abscissae - x,v, and w.
# *	x - the last and the best approximation to the minimum location,
# *	    i.e. f(x) <= f(a) or/and f(x) <= f(b)
# *	    (if the function f has a local minimum in (a,b), then the both
# *	    conditions are fulfiled after one or two steps).
# *	v,w are previous approximations to the minimum location. They may
# *	coincide with a, b, or x (although the algorithm tries to make all
# *	u, v, and w distinct). Points x, v, and w are used to construct
# *	interpolating parabola whose minimum will be treated as a new
# *	approximation to the minimum location if the former falls within
# *	[a,b] and reduces the range enveloping minimum more efficient than
# *	the gold section procedure.
# *	When f(x) has a second derivative positive at the minimum location
# *	(not coinciding with a or b) the procedure converges superlinearly
# *	at a rate order about 1.324
# *
# ************************************************************************
# */

# #include "assert.h"
# #include "math.h"
# #include "fmin.h"

# #define EPSILON       2.22045e-16
# #define SQRT_EPSILON  1.49012e-08

let EPSILON: Float64 = 2.22045e-16
let SQRT_EPSILON: Float64 = 1.49012e-08

def fminbr(
    a: Float64,
    b: Float64,
    f: fn(Float64, Pointer[Byte]) -> Float64,
    data_in: Pointer[Byte],
    tol: Float64,
) -> Float64:
    var x: Float64
    var v: Float64
    var w: Float64            # /* Abscissae, descr. see above  */
    var fx: Float64           # /* f(x)                         */
    var fv: Float64           # /* f(v)                         */
    var fw: Float64           # /* f(w)                         */
    let r: Float64 = (3.0 - sqrt(5.0)) / 2.0       # /* Gold section ratio           */
    assert(tol > 0 and b > a)
    v = a + r * (b - a)
    fv = f(v, data_in)               # /* First step - always gold section */
    x = v
    w = v
    fx = fv
    fw = fv
    while True:                   # /* Main iteration loop    */
        var range: Float64 = b - a     # /* Range over which the minimum */
        # /* is seeked for                */
        var middle_range: Float64 = (a + b) / 2.0
        var tol_act: Float64 =          # /* Actual tolerance             */
            SQRT_EPSILON * fabs(x) + tol / 3.0
        var new_step: Float64          # /* Step at this iteration       */
        if fabs(x - middle_range) + range / 2.0 <= 2.0 * tol_act:
            return x              # /* Acceptable approx. is found  */
        # /* Obtain the gold section step */
        new_step = r * (x if x < middle_range else b - x) if x < middle_range else r * (a - x)
        # /* Decide if the interpolation can be tried     */
        if fabs(x - w) >= tol_act:     # /* If x and w are distinct      *//* interpolatiom may be tried   */
            var p: Float64     # /* Interpolation step is calcula- */
            var q: Float64     # /* ted as p/q; division operation */
            # /* is delayed until last moment */
            var t: Float64
            t = (x - w) * (fx - fv)
            q = (x - v) * (fx - fw)
            p = (x - v) * q - (x - w) * t
            q = 2.0 * (q - t)
            if q > 0.0:    		# /* q was calculated with the op- */
                p = -p             # /* posite sign; make q positive */
            else:                   # /* and assign possible minus to     */
                q = -q             # /* p                            */
            if fabs(p) < fabs(new_step * q) and    # /* If x+p/q falls in [a,b] */
                p > q * (a - x + 2.0 * tol_act) and   # /* not too close to a and */
                p < q * (b - x - 2.0 * tol_act):     # /* b, and isn't too large */
                new_step = p / q   # /* it is accepted         */
            # /* If p/q is too large then the */
            # /* gold section procedure can   */
            # /* reduce [a,b] range to more   */
            # /* extent                       */
        if fabs(new_step) < tol_act:   # /* Adjust the step to be not less */
            if new_step > 0.0:        # /* than tolerance                 */
                new_step = tol_act
            else:
                new_step = -tol_act
        # /* Obtain the next approximation to min     */
        # /* and reduce the enveloping range      */
        var t2: Float64 = x + new_step      # /* Tentative point for the min  */
        var ft: Float64 = f(t2, data_in)
        if ft <= fx:        # /* t is a better approximation  */
            if t2 < x:          # /* Reduce the range so that */
                b = x           # /* t would fall within it       */
            else:
                a = x
            v = w
            w = x
            x = t2              # /* Assign the best approx to x  */
            fv = fw
            fw = fx
            fx = ft
        else:               # /* x remains the better approx  */
            if t2 < x:          # /* Reduce the range enclosing x     */
                a = t2
            else:
                b = t2
            if ft <= fw or w == x:
                v = w
                w = t2
                fv = fw
                fw = ft
            elif ft <= fv or v == x or v == w:
                v = t2
                fv = ft
        # /* ----- end-of-block ----- */
    # /* ===== End of loop ===== */