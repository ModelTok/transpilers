from memory import strlen

struct ObjexxFCL:
    @staticmethod
    def SIZEOF(x: Pointer[UInt8]) -> UInt:
        return UInt(strlen(x))