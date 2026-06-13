from Eigen import Array, pow

def main():
    var e = Array[Float64, 1, 3](2, -3, 1./3.)
    print("10^[" + str(e) + "] = " + str(pow(10, e)))