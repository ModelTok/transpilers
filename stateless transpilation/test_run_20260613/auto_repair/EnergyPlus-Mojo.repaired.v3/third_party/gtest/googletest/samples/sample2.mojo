from sample2 import MyString
from memory import memset, memcpy
from string import String
from sys import sizeof

@value
class MyString:
    var c_string_: Pointer[UInt8]
    
    def __init__(inout self):
        self.c_string_ = Pointer[UInt8](None)
    
    def __init__(inout self, a_c_string: String):
        self.c_string_ = Pointer[UInt8](None)
        self.Set(a_c_string)
    
    def __init__(inout self, string: MyString):
        self.c_string_ = Pointer[UInt8](None)
        self.Set(string.c_string_)
    
    def __del__(owned self):
        if self.c_string_:
            self.c_string_.free()
    
    def c_string(self) -> String:
        return String(self.c_string_)
    
    def Length(self) -> Int:
        if self.c_string_ == None:
            return 0
        else:
            return len(String(self.c_string_))
    
    def Set(inout self, c_string: String):
        var temp = MyString.CloneCString(c_string)
        if self.c_string_:
            self.c_string_.free()
        self.c_string_ = temp
    
    @staticmethod
    def CloneCString(a_c_string: String) -> Pointer[UInt8]:
        if a_c_string == "":
            return Pointer[UInt8](None)
        var len = len(a_c_string)
        var clone = Pointer[UInt8].alloc(len + 1)
        memcpy(clone, a_c_string.data(), len + 1)
        return clone