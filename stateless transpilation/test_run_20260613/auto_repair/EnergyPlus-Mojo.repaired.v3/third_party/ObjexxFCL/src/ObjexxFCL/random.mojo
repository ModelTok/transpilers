from Array import Array
from Array1D import Array1D
from Optional import Optional
from python import random
from python import time
from math import pow

namespace ObjexxFCL:

    # Internal shared global (anonymous namespace equivalent)
    var random_generator = random.Random()

    # Static distributions (module-level to mimic static local)
    var _random_number_float_dist = random.uniform(0.0, 1.0)  # placeholder, will be reinitialized
    var _random_number_double_dist = random.uniform(0.0, 1.0)
    var _random_float_dist = random.uniform(0.0, 1.0)
    var _random_int_dist_0 = random.uniform(0.0, 1.0)  # for RANDOM(int)
    var _ranf_dist = random.uniform(0.0, pow(2.0, 31) - 1.0)
    var _drandm_dist = random.uniform(0.0, 1.0)
    var _randu_dist = random.uniform(0.0, 1.0)
    var _irandm_dist_0 = random.randint(0, 32767)
    var _irandm_dist_1 = random.randint(0, 2147483647)

    # Reinitialize distributions to match C++ static initialization
    # (In Mojo we cannot have static local, so we set them once at module load)
    # Note: The actual distribution objects are not directly accessible; we use random_generator methods.
    # The reset() calls are no-ops in Mojo.

    def RANDOM_NUMBER(inout harvest: Float32):
        # static uniform_real_distribution< float > distribution( 0.0f, 1.0f );
        harvest = random_generator.uniform(0.0, 1.0)

    def RANDOM_NUMBER(inout harvest: Float64):
        # static uniform_real_distribution< double > distribution( 0.0, 1.0 );
        harvest = random_generator.uniform(0.0, 1.0)

    def RANDOM_NUMBER(inout harvest: Array[Float32]):
        for i in range(harvest.size()):
            harvest[i] = RANDOM(0)

    def RANDOM_NUMBER(inout harvest: Array[Float64]):
        for i in range(harvest.size()):
            harvest[i] = DRANDM(0)

    def RANDOM(inout ranval: Float32):
        # static uniform_real_distribution< float > distribution( 0.0f, 1.0f );
        ranval = random_generator.uniform(0.0, 1.0)

    def RANDOM(iflag: Int32) -> Float32:
        # static uniform_real_distribution< float > distribution( 0.0f, 1.0f );
        if iflag == 1:
            # Reset distribution (no-op in Mojo)

        elif iflag != 0:
            # Reseed generator and reset distribution
            random_generator.seed(iflag)
            # distribution.reset() - no-op
        return random_generator.uniform(0.0, 1.0)

    def RANF(iseed: Optional[Int32] = None) -> Float32:
        # static uniform_real_distribution< float > distribution( 0.0f, pow( 2.0f, 31 ) - 1.0f );
        if iseed.present():
            random_generator.seed(iseed())
        return random_generator.uniform(0.0, pow(2.0, 31) - 1.0)

    def DRANDM(iflag: Int32) -> Float64:
        # static uniform_real_distribution< double > distribution( 0.0, 1.0 );
        if iflag == 1:
            # Reset distribution (no-op)

        elif iflag != 0:
            random_generator.seed(iflag)
            # distribution.reset() - no-op
        return random_generator.uniform(0.0, 1.0)

    def RANDU(i1: Int32, i2: Int32, inout x: Float32):
        # static uniform_real_distribution< float > distribution( 0.0f, 1.0f );
        random_generator.seed(i1 * i2)  # This is not the infamous randu
        x = random_generator.uniform(0.0, 1.0)

    def IRANDM() -> Int32:
        # static uniform_int_distribution< int32_t > distribution( 0, 32767 );
        return Int32(random_generator.randint(0, 32767))

    def IRANDM(iflag: Int32) -> Int32:
        # static uniform_int_distribution< int32_t > distribution( 0, 2147483647 );
        if iflag == 1:
            # Reset distribution (no-op)

        elif iflag != 0:
            random_generator.seed(iflag)
            # distribution.reset() - no-op
        return Int32(random_generator.randint(0, 2147483647))

    def RANDOM_SEED(
        size: Optional[Int32] = None,
        put: Optional[Array1D[Int32]] = None,
        get: Optional[Array1D[Int32]] = None
    ):
        # static vector< int > seed_vals{ int( time( NULL ) ), int( time( NULL ) ) };
        var seed_vals = List[Int32](Int32(time.time()), Int32(time.time()))

        if size.present():
            assert(not put.present() and not get.present())  # At most one arg allowed
            size = Int32(len(seed_vals))
        elif put.present():
            assert(not get.present())  # At most one arg allowed
            seed_vals.clear()
            for i in range(put().size()):
                seed_vals.append(put()[i])
            # seed_seq seed_val_seq( seed_vals.begin(), seed_vals.end() );
            random_generator.seed(tuple(seed_vals))  # Not clear how to know how many seed values the generator is using
        elif get.present():
            # get = 0; // In case it has more elements than seed_vals
            for i in range(min(len(seed_vals), get().size())):
                get()[i] = seed_vals[i]
        else:  # No arguments
            seed_vals = List[Int32](Int32(time.time()), Int32(time.time()))
            random_generator.seed(tuple(seed_vals))  # Not clear how to know how many seed values the generator is using

    def SRAND(iseed: Int32):
        random_generator.seed(iseed)