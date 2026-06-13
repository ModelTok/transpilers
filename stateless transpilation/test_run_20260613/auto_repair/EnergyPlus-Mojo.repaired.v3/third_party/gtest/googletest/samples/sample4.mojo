struct Counter:
    var counter_: Int32

    def __init__(inout self):
        self.counter_ = 0

    def Increment(inout self) -> Int32:
        return self.counter_++

    def Decrement(inout self) -> Int32:
        if self.counter_ == 0:
            return self.counter_
        else:
            return self.counter_--

    def Print(self):
        print(self.counter_, end="")