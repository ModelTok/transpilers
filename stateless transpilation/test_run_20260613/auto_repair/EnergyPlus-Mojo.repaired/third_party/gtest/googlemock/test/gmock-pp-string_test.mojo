from gmock.internal.gmock-pp import GMOCK_PP_CAT, GMOCK_PP_NARG, GMOCK_PP_NARG0, GMOCK_PP_HAS_COMMA, GMOCK_PP_IS_EMPTY, GMOCK_PP_IF, GMOCK_PP_HEAD, GMOCK_PP_TAIL, GMOCK_PP_IS_BEGIN_PARENS, GMOCK_PP_IS_ENCLOSED_PARENS, GMOCK_PP_REMOVE_PARENS, GMOCK_PP_INC, GMOCK_PP_REPEAT, GMOCK_PP_FOR_EACH, GMOCK_PP_STRINGIZE
from gmock.gmock import EXPECT_THAT, Matcher

def SameExceptSpaces(s: String) -> Matcher[String]:
    def remove_spaces(to_split: String) -> String:
        var result = String(to_split)
        result = result.replace(" ", "")
        return result
    return EXPECT_THAT(remove_spaces(s), remove_spaces(s))  # Note: This is a placeholder translation

def EXPECT_EXPANSION(Result: String, Macro: String) -> None:
    EXPECT_THAT("" + GMOCK_PP_STRINGIZE(Macro), SameExceptSpaces(Result))

def test_Macros_Cat() -> None:
    EXPECT_EXPANSION("14", GMOCK_PP_CAT(1, 4))
    EXPECT_EXPANSION("+=", GMOCK_PP_CAT(+, =))

def test_Macros_Narg() -> None:
    EXPECT_EXPANSION("1", GMOCK_PP_NARG())
    EXPECT_EXPANSION("1", GMOCK_PP_NARG(x))
    EXPECT_EXPANSION("2", GMOCK_PP_NARG(x, y))
    EXPECT_EXPANSION("3", GMOCK_PP_NARG(x, y, z))
    EXPECT_EXPANSION("4", GMOCK_PP_NARG(x, y, z, w))
    EXPECT_EXPANSION("0", GMOCK_PP_NARG0())
    EXPECT_EXPANSION("1", GMOCK_PP_NARG0(x))
    EXPECT_EXPANSION("2", GMOCK_PP_NARG0(x, y))

def test_Macros_Comma() -> None:
    EXPECT_EXPANSION("0", GMOCK_PP_HAS_COMMA())
    EXPECT_EXPANSION("1", GMOCK_PP_HAS_COMMA(, ))
    EXPECT_EXPANSION("0", GMOCK_PP_HAS_COMMA((, )))

def test_Macros_IsEmpty() -> None:
    EXPECT_EXPANSION("1", GMOCK_PP_IS_EMPTY())
    EXPECT_EXPANSION("0", GMOCK_PP_IS_EMPTY(, ))
    EXPECT_EXPANSION("0", GMOCK_PP_IS_EMPTY(a))
    EXPECT_EXPANSION("0", GMOCK_PP_IS_EMPTY(()))
    #define GMOCK_PP_INTERNAL_IS_EMPTY_TEST_1
    EXPECT_EXPANSION("1", GMOCK_PP_IS_EMPTY(GMOCK_PP_INTERNAL_IS_EMPTY_TEST_1))

def test_Macros_If() -> None:
    EXPECT_EXPANSION("1", GMOCK_PP_IF(1, 1, 2))
    EXPECT_EXPANSION("2", GMOCK_PP_IF(0, 1, 2))

def test_Macros_HeadTail() -> None:
    EXPECT_EXPANSION("1", GMOCK_PP_HEAD(1))
    EXPECT_EXPANSION("1", GMOCK_PP_HEAD(1, 2))
    EXPECT_EXPANSION("1", GMOCK_PP_HEAD(1, 2, 3))
    EXPECT_EXPANSION("", GMOCK_PP_TAIL(1))
    EXPECT_EXPANSION("2", GMOCK_PP_TAIL(1, 2))
    EXPECT_EXPANSION("2", GMOCK_PP_HEAD(GMOCK_PP_TAIL(1, 2, 3)))

def test_Macros_Parentheses() -> None:
    EXPECT_EXPANSION("0", GMOCK_PP_IS_BEGIN_PARENS(sss))
    EXPECT_EXPANSION("0", GMOCK_PP_IS_BEGIN_PARENS(sss()))
    EXPECT_EXPANSION("0", GMOCK_PP_IS_BEGIN_PARENS(sss() sss))
    EXPECT_EXPANSION("1", GMOCK_PP_IS_BEGIN_PARENS((sss)))
    EXPECT_EXPANSION("1", GMOCK_PP_IS_BEGIN_PARENS((sss)ss))
    EXPECT_EXPANSION("0", GMOCK_PP_IS_ENCLOSED_PARENS(sss))
    EXPECT_EXPANSION("0", GMOCK_PP_IS_ENCLOSED_PARENS(sss()))
    EXPECT_EXPANSION("0", GMOCK_PP_IS_ENCLOSED_PARENS(sss() sss))
    EXPECT_EXPANSION("1", GMOCK_PP_IS_ENCLOSED_PARENS((sss)))
    EXPECT_EXPANSION("0", GMOCK_PP_IS_ENCLOSED_PARENS((sss)ss))
    EXPECT_EXPANSION("1 + 1", GMOCK_PP_REMOVE_PARENS((1 + 1)))

def test_Macros_Increment() -> None:
    EXPECT_EXPANSION("1", GMOCK_PP_INC(0))
    EXPECT_EXPANSION("2", GMOCK_PP_INC(1))
    EXPECT_EXPANSION("3", GMOCK_PP_INC(2))
    EXPECT_EXPANSION("4", GMOCK_PP_INC(3))
    EXPECT_EXPANSION("5", GMOCK_PP_INC(4))
    EXPECT_EXPANSION("16", GMOCK_PP_INC(15))

#def JOINER_CAT(a, b) a##b
#def JOINER(_N, _Data, _Elem) JOINER_CAT(_Data, _N) = _Elem

def JOINER(_N: Int, _Data: String, _Elem: String) -> String:
    return _Data + str(_N) + "=" + _Elem

def test_Macros_Repeat() -> None:
    EXPECT_EXPANSION("", GMOCK_PP_REPEAT(JOINER, X, 0))
    EXPECT_EXPANSION("X0=", GMOCK_PP_REPEAT(JOINER, X, 1))
    EXPECT_EXPANSION("X0= X1=", GMOCK_PP_REPEAT(JOINER, X, 2))
    EXPECT_EXPANSION("X0= X1= X2=", GMOCK_PP_REPEAT(JOINER, X, 3))
    EXPECT_EXPANSION("X0= X1= X2= X3=", GMOCK_PP_REPEAT(JOINER, X, 4))
    EXPECT_EXPANSION("X0= X1= X2= X3= X4=", GMOCK_PP_REPEAT(JOINER, X, 5))
    EXPECT_EXPANSION("X0= X1= X2= X3= X4= X5=", GMOCK_PP_REPEAT(JOINER, X, 6))
    EXPECT_EXPANSION("X0= X1= X2= X3= X4= X5= X6=", GMOCK_PP_REPEAT(JOINER, X, 7))
    EXPECT_EXPANSION("X0= X1= X2= X3= X4= X5= X6= X7=", GMOCK_PP_REPEAT(JOINER, X, 8))
    EXPECT_EXPANSION("X0= X1= X2= X3= X4= X5= X6= X7= X8=", GMOCK_PP_REPEAT(JOINER, X, 9))
    EXPECT_EXPANSION("X0= X1= X2= X3= X4= X5= X6= X7= X8= X9=", GMOCK_PP_REPEAT(JOINER, X, 10))
    EXPECT_EXPANSION("X0= X1= X2= X3= X4= X5= X6= X7= X8= X9= X10=", GMOCK_PP_REPEAT(JOINER, X, 11))
    EXPECT_EXPANSION("X0= X1= X2= X3= X4= X5= X6= X7= X8= X9= X10= X11=", GMOCK_PP_REPEAT(JOINER, X, 12))
    EXPECT_EXPANSION("X0= X1= X2= X3= X4= X5= X6= X7= X8= X9= X10= X11= X12=", GMOCK_PP_REPEAT(JOINER, X, 13))
    EXPECT_EXPANSION("X0= X1= X2= X3= X4= X5= X6= X7= X8= X9= X10= X11= X12= X13=", GMOCK_PP_REPEAT(JOINER, X, 14))
    EXPECT_EXPANSION("X0= X1= X2= X3= X4= X5= X6= X7= X8= X9= X10= X11= X12= X13= X14=", GMOCK_PP_REPEAT(JOINER, X, 15))

def test_Macros_ForEach() -> None:
    EXPECT_EXPANSION("", GMOCK_PP_FOR_EACH(JOINER, X, ()))
    EXPECT_EXPANSION("X0=a", GMOCK_PP_FOR_EACH(JOINER, X, (a)))
    EXPECT_EXPANSION("X0=a X1=b", GMOCK_PP_FOR_EACH(JOINER, X, (a, b)))
    EXPECT_EXPANSION("X0=a X1=b X2=c", GMOCK_PP_FOR_EACH(JOINER, X, (a, b, c)))
    EXPECT_EXPANSION("X0=a X1=b X2=c X3=d", GMOCK_PP_FOR_EACH(JOINER, X, (a, b, c, d)))
    EXPECT_EXPANSION("X0=a X1=b X2=c X3=d X4=e", GMOCK_PP_FOR_EACH(JOINER, X, (a, b, c, d, e)))
    EXPECT_EXPANSION("X0=a X1=b X2=c X3=d X4=e X5=f", GMOCK_PP_FOR_EACH(JOINER, X, (a, b, c, d, e, f)))
    EXPECT_EXPANSION("X0=a X1=b X2=c X3=d X4=e X5=f X6=g", GMOCK_PP_FOR_EACH(JOINER, X, (a, b, c, d, e, f, g)))
    EXPECT_EXPANSION("X0=a X1=b X2=c X3=d X4=e X5=f X6=g X7=h", GMOCK_PP_FOR_EACH(JOINER, X, (a, b, c, d, e, f, g, h)))
    EXPECT_EXPANSION("X0=a X1=b X2=c X3=d X4=e X5=f X6=g X7=h X8=i", GMOCK_PP_FOR_EACH(JOINER, X, (a, b, c, d, e, f, g, h, i)))
    EXPECT_EXPANSION("X0=a X1=b X2=c X3=d X4=e X5=f X6=g X7=h X8=i X9=j", GMOCK_PP_FOR_EACH(JOINER, X, (a, b, c, d, e, f, g, h, i, j)))
    EXPECT_EXPANSION("X0=a X1=b X2=c X3=d X4=e X5=f X6=g X7=h X8=i X9=j X10=k", GMOCK_PP_FOR_EACH(JOINER, X, (a, b, c, d, e, f, g, h, i, j, k)))
    EXPECT_EXPANSION("X0=a X1=b X2=c X3=d X4=e X5=f X6=g X7=h X8=i X9=j X10=k X11=l", GMOCK_PP_FOR_EACH(JOINER, X, (a, b, c, d, e, f, g, h, i, j, k, l)))
    EXPECT_EXPANSION("X0=a X1=b X2=c X3=d X4=e X5=f X6=g X7=h X8=i X9=j X10=k X11=l X12=m", GMOCK_PP_FOR_EACH(JOINER, X, (a, b, c, d, e, f, g, h, i, j, k, l, m)))
    EXPECT_EXPANSION("X0=a X1=b X2=c X3=d X4=e X5=f X6=g X7=h X8=i X9=j X10=k X11=l X12=m X13=n", GMOCK_PP_FOR_EACH(JOINER, X, (a, b, c, d, e, f, g, h, i, j, k, l, m, n)))
    EXPECT_EXPANSION("X0=a X1=b X2=c X3=d X4=e X5=f X6=g X7=h X8=i X9=j X10=k X11=l X12=m X13=n X14=o", GMOCK_PP_FOR_EACH(JOINER, X, (a, b, c, d, e, f, g, h, i, j, k, l, m, n, o)))

def main() -> None:
    test_Macros_Cat()
    test_Macros_Narg()
    test_Macros_Comma()
    test_Macros_IsEmpty()
    test_Macros_If()
    test_Macros_HeadTail()
    test_Macros_Parentheses()
    test_Macros_Increment()
    test_Macros_Repeat()
    test_Macros_ForEach()