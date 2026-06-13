from memory import memset_zero
from random import random
from sys import exit

def LLVMFuzzerTestOneInput(data: Pointer[UInt8], size: Int) -> Int:
    ...

def main(argc: Int, argv: Pointer[Pointer[UInt8]]) -> Int:
    var data: UInt8[32]
    for i in range(32):
        for j in range(32):
            data[j] = (random() & 0xFF).cast[UInt8]()
        LLVMFuzzerTestOneInput(Pointer[UInt8](data), 32)
    return 0