/*
 * The authors of this software are Rob Pike and Ken Thompson.
 *              Copyright (c) 2002 by Lucent Technologies.
 * Permission to use, copy, modify, and distribute this software for any
 * purpose without fee is hereby granted, provided that this entire notice
 * is included in all copies of any software which is or includes a copy
 * or modification of this software and in all copies of the supporting
 * documentation for such software.
 * THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT ANY EXPRESS OR IMPLIED
 * WARRANTY.  IN PARTICULAR, NEITHER THE AUTHORS NOR LUCENT TECHNOLOGIES MAKE ANY
 * REPRESENTATION OR WARRANTY OF ANY KIND CONCERNING THE MERCHANTABILITY
 * OF THIS SOFTWARE OR ITS FITNESS FOR ANY PARTICULAR PURPOSE.
 */
from builtin import Pointer, UInt8, Int8, Int
from .utf import Rune, Runeerror, Runemax, Runeself, Runesync

# Constants from anonymous enum
const Bit1: Int = 7
const Bitx: Int = 6
const Bit2: Int = 5
const Bit3: Int = 4
const Bit4: Int = 3
const Bit5: Int = 2
const T1: UInt8 = ((1 << (Bit1 + 1)) - 1) ^ 0xFF  # 0000 0000
const Tx: UInt8 = ((1 << (Bitx + 1)) - 1) ^ 0xFF  # 1000 0000
const T2: UInt8 = ((1 << (Bit2 + 1)) - 1) ^ 0xFF  # 1100 0000
const T3: UInt8 = ((1 << (Bit3 + 1)) - 1) ^ 0xFF  # 1110 0000
const T4: UInt8 = ((1 << (Bit4 + 1)) - 1) ^ 0xFF  # 1111 0000
const T5: UInt8 = ((1 << (Bit5 + 1)) - 1) ^ 0xFF  # 1111 1000
const Rune1: Int = (1 << (Bit1 + 0 * Bitx)) - 1  # 0000 0000 0111 1111
const Rune2: Int = (1 << (Bit2 + 1 * Bitx)) - 1  # 0000 0111 1111 1111
const Rune3: Int = (1 << (Bit3 + 2 * Bitx)) - 1  # 1111 1111 1111 1111
const Rune4: Int = (1 << (Bit4 + 3 * Bitx)) - 1  # 0001 1111 1111 1111 1111 1111
const Maskx: UInt8 = (1 << Bitx) - 1  # 0011 1111
const Testx: UInt8 = Maskx ^ 0xFF  # 1100 0000
const Bad: Rune = Runeerror

def chartorune(inout rune: Rune, str: Pointer[UInt8]) -> Int:
    var c: UInt8
    var c1: UInt8
    var c2: UInt8
    var c3: UInt8
    var l: Int
    # one character sequence
    # 00000-0007F => T1
    c = str[0]
    if c < Tx:
        rune = c
        return 1
    # two character sequence
    # 0080-07FF => T2 Tx
    c1 = str[1] ^ Tx
    if c1 & Testx:
        rune = Bad
        return 1
    if c < T3:
        if c < T2:
            rune = Bad
            return 1
        l = ((c << Bitx) | c1) & Rune2
        if l <= Rune1:
            rune = Bad
            return 1
        rune = l
        return 2
    # three character sequence
    # 0800-FFFF => T3 Tx Tx
    c2 = str[2] ^ Tx
    if c2 & Testx:
        rune = Bad
        return 1
    if c < T4:
        l = ((((c << Bitx) | c1) << Bitx) | c2) & Rune3
        if l <= Rune2:
            rune = Bad
            return 1
        rune = l
        return 3
    # four character sequence (21-bit value)
    # 10000-1FFFFF => T4 Tx Tx Tx
    c3 = str[3] ^ Tx
    if c3 & Testx:
        rune = Bad
        return 1
    if c < T5:
        l = ((((((c << Bitx) | c1) << Bitx) | c2) << Bitx) | c3) & Rune4
        if l <= Rune3:
            rune = Bad
            return 1
        rune = l
        return 4
    # Support for 5-byte or longer UTF-8 would go here, but
    # since we don't have that, we'll just fall through to bad.
    # bad decoding
    rune = Bad
    return 1

def runetochar(str: Pointer[UInt8], rune: Rune) -> Int:
    # Runes are signed, so convert to unsigned for range check.
    var c: UInt32
    # one character sequence
    # 00000-0007F => 00-7F
    c = rune
    if c <= Rune1:
        str[0] = Int8(c)
        return 1
    # two character sequence
    # 0080-07FF => T2 Tx
    if c <= Rune2:
        str[0] = T2 | Int8(c >> (1 * Bitx))
        str[1] = Tx | (c & Maskx)
        return 2
    # If the Rune is out of range, convert it to the error rune.
    # Do this test here because the error rune encodes to three bytes.
    # Doing it earlier would duplicate work, since an out of range
    # Rune wouldn't have fit in one or two bytes.
    if c > Runemax:
        c = Runeerror
    # three character sequence
    # 0800-FFFF => T3 Tx Tx
    if c <= Rune3:
        str[0] = T3 | Int8(c >> (2 * Bitx))
        str[1] = Tx | ((c >> (1 * Bitx)) & Maskx)
        str[2] = Tx | (c & Maskx)
        return 3
    # four character sequence (21-bit value)
    # 10000-1FFFFF => T4 Tx Tx Tx
    str[0] = T4 | Int8(c >> (3 * Bitx))
    str[1] = Tx | ((c >> (2 * Bitx)) & Maskx)
    str[2] = Tx | ((c >> (1 * Bitx)) & Maskx)
    str[3] = Tx | (c & Maskx)
    return 4

def runelen(rune: Rune) -> Int:
    var str: Pointer[UInt8] = Pointer[UInt8].alloc(10)
    var result = runetochar(str, rune)
    str.free()
    return result

def fullrune(str: Pointer[UInt8], n: Int) -> Int:
    if n > 0:
        var c: UInt8 = str[0]
        if c < Tx:
            return 1
        if n > 1:
            if c < T3:
                return 1
            if n > 2:
                if c < T4 or n > 3:
                    return 1
    return 0

def utflen(s: Pointer[UInt8]) -> Int:
    var c: UInt8
    var n: Int
    var rune: Rune
    n = 0
    while True:
        c = s[0]
        if c < Runeself:
            if c == 0:
                return n
            s = s.offset(1)
        else:
            s = s.offset(chartorune(rune, s))
        n += 1
    return 0

def utfrune(s: Pointer[UInt8], c: Rune) -> Pointer[UInt8]:
    var c1: UInt8
    var r: Rune
    var n: Int
    if c < Runesync:  # not part of utf sequence
        # implement strchr manually
        var p = s
        while p[0] != 0:
            if p[0] == c:
                return p
            p = p.offset(1)
        return Pointer[UInt8]()
    while True:
        c1 = s[0]
        if c1 < Runeself:  # one byte rune
            if c1 == 0:
                return Pointer[UInt8]()
            if c1 == c:
                return s
            s = s.offset(1)
            continue
        n = chartorune(r, s)
        if r == c:
            return s
        s = s.offset(n)
    return Pointer[UInt8]()