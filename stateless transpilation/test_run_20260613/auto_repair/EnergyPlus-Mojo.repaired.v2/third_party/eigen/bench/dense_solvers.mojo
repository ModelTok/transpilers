def compute_norm_equation[Solver: AnyRegType, MatrixType: AnyRegType](inout solver: Solver, A: MatrixType):
    if A.rows() != A.cols():
        solver.compute(A.transpose() * A)
    else:
        solver.compute(A)

def compute[Solver: AnyRegType, MatrixType: AnyRegType](inout solver: Solver, A: MatrixType):
    solver.compute(A)

def bench[Scalar: AnyRegType, Size: Int](id: Int, rows: Int, size: Int = Size):
    alias Mat = Matrix[Scalar, Dynamic, Size]
    alias MatDyn = Matrix[Scalar, Dynamic, Dynamic]
    alias MatSquare = Matrix[Scalar, Size, Size]
    var A = Mat(rows, size)
    A.setRandom()
    if rows == size:
        A = A * A.adjoint()
    var t_llt = BenchTimer()
    var t_ldlt = BenchTimer()
    var t_lu = BenchTimer()
    var t_fplu = BenchTimer()
    var t_qr = BenchTimer()
    var t_cpqr = BenchTimer()
    var t_cod = BenchTimer()
    var t_fpqr = BenchTimer()
    var t_jsvd = BenchTimer()
    var t_bdcsvd = BenchTimer()
    var svd_opt = ComputeThinU | ComputeThinV
    var tries = 5
    var rep = 1000 // size
    if rep == 0:
        rep = 1
    var llt = LLT[MatSquare](size)
    var ldlt = LDLT[MatSquare](size)
    var lu = PartialPivLU[MatSquare](size)
    var fplu = FullPivLU[MatSquare](size, size)
    var qr = HouseholderQR[Mat](A.rows(), A.cols())
    var cpqr = ColPivHouseholderQR[Mat](A.rows(), A.cols())
    var cod = CompleteOrthogonalDecomposition[Mat](A.rows(), A.cols())
    var fpqr = FullPivHouseholderQR[Mat](A.rows(), A.cols())
    var jsvd = JacobiSVD[MatDyn](A.rows(), A.cols())
    var bdcsvd = BDCSVD[MatDyn](A.rows(), A.cols())
    BENCH(t_llt, tries, rep, compute_norm_equation[type_of(llt), type_of(A)](llt, A))
    BENCH(t_ldlt, tries, rep, compute_norm_equation[type_of(ldlt), type_of(A)](ldlt, A))
    BENCH(t_lu, tries, rep, compute_norm_equation[type_of(lu), type_of(A)](lu, A))
    if size <= 1000:
        BENCH(t_fplu, tries, rep, compute_norm_equation[type_of(fplu), type_of(A)](fplu, A))
    BENCH(t_qr, tries, rep, compute[type_of(qr), type_of(A)](qr, A))
    BENCH(t_cpqr, tries, rep, compute[type_of(cpqr), type_of(A)](cpqr, A))
    BENCH(t_cod, tries, rep, compute[type_of(cod), type_of(A)](cod, A))
    if size * rows <= 10000000:
        BENCH(t_fpqr, tries, rep, compute[type_of(fpqr), type_of(A)](fpqr, A))
    if size < 500:
        BENCH(t_jsvd, tries, rep, jsvd.compute(A, svd_opt))
    BENCH(t_bdcsvd, tries, rep, bdcsvd.compute(A, svd_opt))
    results["LLT"][id] = t_llt.best()
    results["LDLT"][id] = t_ldlt.best()
    results["PartialPivLU"][id] = t_lu.best()
    results["FullPivLU"][id] = t_fplu.best()
    results["HouseholderQR"][id] = t_qr.best()
    results["ColPivHouseholderQR"][id] = t_cpqr.best()
    results["CompleteOrthogonalDecomposition"][id] = t_cod.best()
    results["FullPivHouseholderQR"][id] = t_fpqr.best()
    results["JacobiSVD"][id] = t_jsvd.best()
    results["BDCSVD"][id] = t_bdcsvd.best()

def main():
    labels.push_back("LLT")
    labels.push_back("LDLT")
    labels.push_back("PartialPivLU")
    labels.push_back("FullPivLU")
    labels.push_back("HouseholderQR")
    labels.push_back("ColPivHouseholderQR")
    labels.push_back("CompleteOrthogonalDecomposition")
    labels.push_back("FullPivHouseholderQR")
    labels.push_back("JacobiSVD")
    labels.push_back("BDCSVD")
    for i in range(labels.size):
        results[labels[i]].fill(-1)
    const small = 8
    sizes.push_back(Array2i(small, small))
    sizes.push_back(Array2i(100, 100))
    sizes.push_back(Array2i(1000, 1000))
    sizes.push_back(Array2i(4000, 4000))
    sizes.push_back(Array2i(10000, small))
    sizes.push_back(Array2i(10000, 100))
    sizes.push_back(Array2i(10000, 1000))
    sizes.push_back(Array2i(10000, 4000))
    for k in range(sizes.size):
        print(sizes[k](0), "x", sizes[k](1), "...\n")
        bench[float, Dynamic](k, sizes[k](0), sizes[k](1))
    print("solver/size", width=32)
    print("  ")
    for k in range(sizes.size):
        var ss = StringStream()
        ss << sizes[k](0) << "x" << sizes[k](1)
        print(ss.str(), width=10)
        print(" ")
    print("\n")
    for i in range(labels.size):
        print(labels[i], width=32)
        print("  ")
        var r = (results[labels[i]] * 100000.0).floor() / 100.0
        for k in range(sizes.size):
            print("", width=10)
            if r(k) >= 1e6:
                print("-")
            else:
                print(r(k))
            print(" ")
        print("\n")
    print("<table class=\"manual\">\n")
    print("<tr><th>solver/size</th>\n")
    for k in range(sizes.size):
        print("  <th>", sizes[k](0), "x", sizes[k](1), "</th>")
    print("</tr>\n")
    for i in range(labels.size):
        print("<tr")
        if i % 2 == 1:
            print(" class=\"alt\"")
        print("><td>", labels[i], "</td>")
        var r = (results[labels[i]] * 100000.0).floor() / 100.0
        for k in range(sizes.size):
            if r(k) >= 1e6:
                print("<td>-</td>")
            else:
                print("<td>", r(k))
                if i > 0:
                    print(" (x", numext.round(10.0 * results[labels[i]](k) / results["LLT"](k)) / 10.0, ")")
                if i < 4 and sizes[k](0) != sizes[k](1):
                    print(" <sup><a href=\"#note_ls\">*</a></sup>")
                print("</td>")
        print("</tr>\n")
    print("</table>\n")