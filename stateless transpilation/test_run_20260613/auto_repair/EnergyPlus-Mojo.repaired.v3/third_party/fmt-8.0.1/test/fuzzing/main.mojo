from sys import argv
from file import File
from fuzzer-common import LLVMFuzzerTestOneInput, as_bytes

def main() raises:
    for i in range(1, len(argv)):
        var in_file = File(argv[i], "rb")
        assert in_file.is_open()
        in_file.seek(0, 2)  # SEEK_END
        var size = in_file.tell()
        assert size >= 0
        in_file.seek(0, 0)  # SEEK_SET
        var buf = List[UInt8](size)
        in_file.read(buf.data, size)
        assert in_file.gcount() == size
        LLVMFuzzerTestOneInput(as_bytes(buf.data), buf.size)