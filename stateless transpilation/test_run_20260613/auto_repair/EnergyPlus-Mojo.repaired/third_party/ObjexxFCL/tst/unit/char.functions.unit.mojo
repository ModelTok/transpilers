from ObjexxFCL.char.functions import (
    is_blank,
    not_blank,
    is_alpha,
    is_digit,
    is_lower,
    is_upper,
    is_any_of,
    has_any_of,
    not_any_of,
    equal,
    equali,
    lessthan,
    lessthani,
    LLT,
    LLE,
    LGE,
    llt,
    lle,
    lgt,
    lge,
    ICHAR,
    lowercase,
    uppercase,
    lowercased,
    uppercased,
    to_lower,
    to_upper,
)

def charFunctionsTest_Predicate() raises:
    assert(is_blank(' '))
    assert(not is_blank('x'))
    assert(not_blank('x'))
    assert(is_alpha('x'))
    assert(not is_alpha('3'))
    assert(is_digit('4'))
    assert(not is_digit('P'))
    assert(is_lower('e'))
    assert(not is_lower('E'))
    assert(is_upper('B'))
    assert(not is_upper('b'))
    assert(is_any_of('x', "xyz"))
    assert(is_any_of('x', String("xyz")))
    assert(not is_any_of('b', "xyz"))
    assert(has_any_of('x', "xyz"))
    assert(has_any_of('x', "xyz"))
    assert(not has_any_of('b', String("xyz")))
    assert(not has_any_of('b', String("xyz")))
    assert(not not_any_of('x', "xyz"))
    assert(not not_any_of('x', "xyz"))
    assert(not_any_of('b', String("xyz")))
    assert(not_any_of('b', String("xyz")))

def charFunctionsTest_Comparison() raises:
    assert(equal('a', 'a'))
    assert(equal('a', 'a', True))
    assert(not equal('a', 'A'))
    assert(equal('a', 'A', False))
    assert(equali('a', 'A'))
    assert(not equali('a', 'X'))
    assert(lessthan('a', 'b'))
    assert(lessthan('a', 'b', True))
    assert(not lessthan('a', 'B', True))
    assert(lessthan('A', 'b', False))
    assert(not lessthan('b', 'A', False))
    assert(lessthani('a', 'b'))
    assert(lessthani('a', 'B'))
    assert(lessthani('A', 'b'))
    assert(LLT('a', 'b'))
    assert(not LLT('a', 'a'))
    assert(not LLT('b', 'a'))
    assert(LLE('a', 'b'))
    assert(LLE('a', 'a'))
    assert(not LLE('b', 'a'))
    assert(not LGE('a', 'b'))
    assert(LGE('a', 'a'))
    assert(LGE('b', 'a'))
    assert(llt('a', 'b'))
    assert(not llt('a', 'a'))
    assert(not llt('b', 'a'))
    assert(lle('a', 'b'))
    assert(lle('a', 'a'))
    assert(not lle('b', 'a'))
    assert(not lgt('a', 'b'))
    assert(not lgt('a', 'a'))
    assert(lgt('b', 'a'))
    assert(not lge('a', 'b'))
    assert(lge('a', 'a'))
    assert(lge('b', 'a'))

def charFunctionsTest_Conversion() raises:
    assert(ICHAR('c') == 99)

def charFunctionsTest_Modifier() raises:
    var s: Char = 'F'
    assert(s == 'F')
    lowercase(s)
    assert(s == 'f')
    uppercase(s)
    assert(s == 'F')
    assert(equal(s, 'F'))
    assert(not equal(s, 'f'))
    assert(equal(s, 'f', False))
    assert(equali(s, 'F'))
    assert(equali(s, 'f'))
    assert(lowercase(s) == 'f')
    assert(uppercase(s) == 'F')

def charFunctionsTest_Generator() raises:
    let s: Char = 'F'
    assert(lowercased(s) == 'f')
    assert(uppercased(s) == 'F')
    assert(to_lower(s) == 'f')
    assert(to_upper(s) == 'F')

def main() raises:
    charFunctionsTest_Predicate()
    charFunctionsTest_Comparison()
    charFunctionsTest_Conversion()
    charFunctionsTest_Modifier()
    charFunctionsTest_Generator()