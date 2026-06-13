from memory import Pointer, Memory
from string import String
from ..stringpiece import StringPiece
from python import len, ord, chr

@staticmethod
def CEscapeString(src: Pointer[UInt8], src_len: Int, dest: Pointer[UInt8], dest_len: Int) -> Int:
    var src_end = src + src_len
    var used: Int = 0
    while src < src_end:
        if dest_len - used < 2:
            return -1
        var c: UInt8 = src[0]
        src += 1
        if c == ord('\n'):
            dest[used] = ord('\\')
            used += 1
            dest[used] = ord('n')
            used += 1
        elif c == ord('\r'):
            dest[used] = ord('\\')
            used += 1
            dest[used] = ord('r')
            used += 1
        elif c == ord('\t'):
            dest[used] = ord('\\')
            used += 1
            dest[used] = ord('t')
            used += 1
        elif c == ord('"'):
            dest[used] = ord('\\')
            used += 1
            dest[used] = ord('"')
            used += 1
        elif c == ord("'"):
            dest[used] = ord('\\')
            used += 1
            dest[used] = ord("'")
            used += 1
        elif c == ord('\\'):
            dest[used] = ord('\\')
            used += 1
            dest[used] = ord('\\')
            used += 1
        else:
            if c < ord(' ') or c > ord('~'):
                if dest_len - used < 5:
                    return -1
                var octal_str = String.from_char_code(c, format="\\{0:03o}")
                for ch in octal_str:
                    dest[used] = ord(ch)
                    used += 1
            else:
                dest[used] = c
                used += 1
    if dest_len - used < 1:
        return -1
    dest[used] = 0
    return used

def CEscape(src: StringPiece) -> String:
    var dest_len = src.size() * 4 + 1
    var dest = Pointer[UInt8].alloc(dest_len)
    var used = CEscapeString(src.data(), src.size(), dest, dest_len)
    var s = String(dest, used)
    Pointer.destroy(dest)
    return s

def PrefixSuccessor(inout prefix: String):
    while len(prefix) > 0:
        var c = prefix[-1]
        if c == chr(0xFF):
            prefix = prefix[:-1]
        else:
            c = chr(ord(c) + 1)
            prefix = prefix[:-1] + c
            break

def StringAppendV(inout dst: String, format: String, *args) raises:
    var space_len = 1024
    var result: String
    while True:
        result = String(format % args)
        if len(result) < space_len:
            dst += result
            return
        space_len = len(result) + 1

def StringPrintf(format: String, *args) raises -> String:
    var result = String()
    StringAppendV(result, format, *args)
    return result