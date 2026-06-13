from Eigen import ArrayXd, tanh

var v: ArrayXd = ArrayXd.LinSpaced(5, 0, 1)
print(tanh(v))