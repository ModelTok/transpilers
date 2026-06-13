let a = Matrix3i.Random()
let b = Matrix3i.Random()
let c = a.cwiseProduct(b)
print("a:\n", a, "\nb:\n", b, "\nc:\n", c, sep="")