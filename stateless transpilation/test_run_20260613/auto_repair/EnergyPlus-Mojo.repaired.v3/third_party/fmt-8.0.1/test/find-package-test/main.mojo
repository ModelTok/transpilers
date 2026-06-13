from fmt.format import print

def main(argc: Int, argv: Pointer[Pointer[UInt8]]) -> Int:
    for i in range(argc):
        print("{}: {}\n", i, argv[i])
    return 0