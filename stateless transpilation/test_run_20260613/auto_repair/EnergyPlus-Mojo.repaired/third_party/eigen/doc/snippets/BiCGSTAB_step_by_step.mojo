  var n = 10000
  var x = VectorXd(n)
  var b = VectorXd(n)
  var A = SparseMatrix[Float64](n, n)
  /* ... fill A and b ... */ 
  var solver = BiCGSTAB[SparseMatrix[Float64]](A)
  x = VectorXd.Random(n)
  solver.setMaxIterations(1)
  var i = 0
  while True:
    x = solver.solveWithGuess(b, x)
    print(i, ":", solver.error())
    i += 1
    if not (solver.info() != Success and i < 100):
      break