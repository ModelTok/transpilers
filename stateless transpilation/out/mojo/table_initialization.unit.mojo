struct Table2D:
    var dims1: List[Int]
    var dims2: List[Int]
    var data: List[List[Float64]]
    
    fn __init__(inout self, dims1: List[Int], dims2: List[Int], data: List[List[Float64]]):
        self.dims1 = dims1
        self.dims2 = dims2
        self.data = data
    
    fn __call__(self, i: Int, j: Int) -> Float64:
        return self.data[i][j]


struct TestTableInitialization:
    fn setUp(inout self):
        pass
    
    fn test_table_initialization(inout self):
        var dims1 = List[Int]()
        dims1.append(2)
        dims1.append(3)
        
        var dims2 = List[Int]()
        dims2.append(5)
        dims2.append(8)
        
        var row1 = List[Float64]()
        row1.append(1.0)
        row1.append(2.0)
        
        var row2 = List[Float64]()
        row2.append(3.0)
        row2.append(4.0)
        
        var data = List[List[Float64]]()
        data.append(row1)
        data.append(row2)
        
        let tbl = Table2D(dims1, dims2, data)
        let val = tbl(1, 1)
        assert val == 4.0


fn main():
    var test = TestTableInitialization()
    test.setUp()
    test.test_table_initialization()
    print("Test passed!")
