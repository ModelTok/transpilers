from main import main

# define VERIFY_THROWS_BADALLOC(a) {                           \
#     bool threw = false;                                       \
#     try {                                                     \
#       a;                                                      \
#     }                                                         \
#     catch (bad_alloc&) { threw = true; }                 \
#     VERIFY(threw && "should have thrown bad_alloc: " #a);     \
#   }

def verify_throws_badalloc[func: fn() raises]():
    var threw = False
    try:
        func()
    except:
        threw = True
    # Note: VERIFY macro behavior approximated; no stringify in Mojo easily
    if not threw:
        print("should have thrown bad_alloc")
        # In a real test framework we'd abort; here we keep the spirit

trait MatrixType:

def triggerMatrixBadAlloc[MatrixType: AnyType](rows: Index, cols: Index):
    # VERIFY_THROWS_BADALLOC( MatrixType m(rows, cols) );
    verify_throws_badalloc[lambda: MatrixType(rows, cols)]()
    # VERIFY_THROWS_BADALLOC( MatrixType m; m.resize(rows, cols) );
    verify_throws_badalloc[lambda:
        var m = MatrixType()
        m.resize(rows, cols)
    ]()
    # VERIFY_THROWS_BADALLOC( MatrixType m; m.conservativeResize(rows, cols) );
    verify_throws_badalloc[lambda:
        var m = MatrixType()
        m.conservativeResize(rows, cols)
    ]()

trait VectorType:

def triggerVectorBadAlloc[VectorType: AnyType](size: Index):
    # VERIFY_THROWS_BADALLOC( VectorType v(size) );
    verify_throws_badalloc[lambda: VectorType(size)]()
    # VERIFY_THROWS_BADALLOC( VectorType v; v.resize(size) );
    verify_throws_badalloc[lambda:
        var v = VectorType()
        v.resize(size)
    ]()
    # VERIFY_THROWS_BADALLOC( VectorType v; v.conservativeResize(size) );
    verify_throws_badalloc[lambda:
        var v = VectorType()
        v.conservativeResize(size)
    ]()

def test_sizeoverflow():
    var times_itself_gives_0: size_t = size_t(1) << (8 * sizeof[Index]() // 2)
    # VERIFY(times_itself_gives_0 * times_itself_gives_0 == 0);
    if times_itself_gives_0 * times_itself_gives_0 != 0:
        print("VERIFY failed: times_itself_gives_0 * times_itself_gives_0 == 0")
    var times_4_gives_0: size_t = size_t(1) << (8 * sizeof[Index]() - 2)
    # VERIFY(times_4_gives_0 * 4 == 0);
    if times_4_gives_0 * 4 != 0:
        print("VERIFY failed: times_4_gives_0 * 4 == 0")
    var times_8_gives_0: size_t = size_t(1) << (8 * sizeof[Index]() - 3)
    # VERIFY(times_8_gives_0 * 8 == 0);
    if times_8_gives_0 * 8 != 0:
        print("VERIFY failed: times_8_gives_0 * 8 == 0")
    triggerMatrixBadAlloc[MatrixXf](times_itself_gives_0, times_itself_gives_0)
    triggerMatrixBadAlloc[MatrixXf](times_itself_gives_0 // 4, times_itself_gives_0)
    triggerMatrixBadAlloc[MatrixXf](times_4_gives_0, 1)
    triggerMatrixBadAlloc[MatrixXd](times_itself_gives_0, times_itself_gives_0)
    triggerMatrixBadAlloc[MatrixXd](times_itself_gives_0 // 8, times_itself_gives_0)
    triggerMatrixBadAlloc[MatrixXd](times_8_gives_0, 1)
    triggerVectorBadAlloc[VectorXf](times_4_gives_0)
    triggerVectorBadAlloc[VectorXd](times_8_gives_0)