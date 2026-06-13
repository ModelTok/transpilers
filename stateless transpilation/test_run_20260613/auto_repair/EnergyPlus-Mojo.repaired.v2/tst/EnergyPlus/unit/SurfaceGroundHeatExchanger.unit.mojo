from SurfaceGroundHeatExchanger import eoshiftArray

def test_eoshiftArrayPos():
    let A = List[Float64](1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0)
    let B = eoshiftArray(A, 2, 0.0)
    let target = List[Float64](3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0, 0.0, 0.0)
    for i in range(len(B)):
        assert B[i] == target[i]

def test_eoshiftArrayNeg():
    let A = List[Float64](1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0)
    let B = eoshiftArray(A, -1, 0.0)
    let target = List[Float64](0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0)
    for i in range(len(B)):
        assert B[i] == target[i]