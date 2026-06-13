def main():
    var M = Matrix2f.Random()
    var m = Matrix2f()
    m = M
    print("Here is the matrix m:")
    print(m)
    print("Now we want to copy a column into a row.")
    print("If we do m.col(1) = m.row(0), then m becomes:")
    m.col(1) = m.row(0)
    print(m)
    print("which is wrong!")
    print("Now let us instead do m.col(1) = m.row(0).eval(). Then m becomes")
    m = M
    m.col(1) = m.row(0).eval()
    print(m)
    print("which is right.")