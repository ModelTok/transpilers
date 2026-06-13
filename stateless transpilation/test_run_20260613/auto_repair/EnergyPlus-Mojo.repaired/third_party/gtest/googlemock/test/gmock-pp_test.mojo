from gmock.internal.gmock-pp import GMOCK_PP_CAT, GMOCK_PP_INTERNAL_INTERNAL_16TH, GMOCK_PP_NARG, GMOCK_PP_HAS_COMMA, GMOCK_PP_IS_EMPTY, GMOCK_PP_IF, GMOCK_PP_NARG0, GMOCK_PP_HEAD, GMOCK_PP_TAIL, GMOCK_PP_IS_BEGIN_PARENS, GMOCK_PP_IS_ENCLOSED_PARENS, GMOCK_PP_REMOVE_PARENS, GMOCK_PP_INC, GMOCK_PP_COMMA_IF, GMOCK_PP_FOR_EACH, GMOCK_PP_VARIADIC_CALL

def main():

alias GMOCK_TEST_REPLACE_comma_WITH_COMMA_I_comma = ","
alias GMOCK_TEST_REPLACE_comma_WITH_COMMA = lambda x: GMOCK_PP_CAT("GMOCK_TEST_REPLACE_comma_WITH_COMMA_I_", x)

namespace testing:
    namespace internal:
        namespace gmockpp:
            static_assert(GMOCK_PP_CAT(1, 4) == 14, "")
            static_assert(GMOCK_PP_INTERNAL_INTERNAL_16TH(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
                                                          12, 13, 14, 15, 16, 17, 18) == 16,
                          "")
            static_assert(GMOCK_PP_NARG() == 1, "")
            static_assert(GMOCK_PP_NARG(x) == 1, "")
            static_assert(GMOCK_PP_NARG(x, y) == 2, "")
            static_assert(GMOCK_PP_NARG(x, y, z) == 3, "")
            static_assert(GMOCK_PP_NARG(x, y, z, w) == 4, "")
            static_assert(not GMOCK_PP_HAS_COMMA(), "")
            static_assert(GMOCK_PP_HAS_COMMA(b, ), "")
            static_assert(not GMOCK_PP_HAS_COMMA((, )), "")
            static_assert(GMOCK_PP_HAS_COMMA(GMOCK_TEST_REPLACE_comma_WITH_COMMA(comma)),
                          "")
            static_assert(
                GMOCK_PP_HAS_COMMA(GMOCK_TEST_REPLACE_comma_WITH_COMMA(comma(unrelated))),
                "")
            static_assert(not GMOCK_PP_IS_EMPTY(, ), "")
            static_assert(not GMOCK_PP_IS_EMPTY(a), "")
            static_assert(not GMOCK_PP_IS_EMPTY(()), "")
            static_assert(GMOCK_PP_IF(1, 1, 2) == 1, "")
            static_assert(GMOCK_PP_IF(0, 1, 2) == 2, "")
            static_assert(GMOCK_PP_NARG0(x) == 1, "")
            static_assert(GMOCK_PP_NARG0(x, y) == 2, "")
            static_assert(GMOCK_PP_HEAD(1) == 1, "")
            static_assert(GMOCK_PP_HEAD(1, 2) == 1, "")
            static_assert(GMOCK_PP_HEAD(1, 2, 3) == 1, "")
            static_assert(GMOCK_PP_TAIL(1, 2) == 2, "")
            static_assert(GMOCK_PP_HEAD(GMOCK_PP_TAIL(1, 2, 3)) == 2, "")
            static_assert(not GMOCK_PP_IS_BEGIN_PARENS(sss), "")
            static_assert(not GMOCK_PP_IS_BEGIN_PARENS(sss()), "")
            static_assert(not GMOCK_PP_IS_BEGIN_PARENS(sss() sss), "")
            static_assert(GMOCK_PP_IS_BEGIN_PARENS((sss)), "")
            static_assert(GMOCK_PP_IS_BEGIN_PARENS((sss)ss), "")
            static_assert(not GMOCK_PP_IS_ENCLOSED_PARENS(sss), "")
            static_assert(not GMOCK_PP_IS_ENCLOSED_PARENS(sss()), "")
            static_assert(not GMOCK_PP_IS_ENCLOSED_PARENS(sss() sss), "")
            static_assert(not GMOCK_PP_IS_ENCLOSED_PARENS((sss)ss), "")
            static_assert(GMOCK_PP_REMOVE_PARENS((1 + 1)) * 2 == 3, "")
            static_assert(GMOCK_PP_INC(4) == 5, "")

            struct Test[*Args: AnyType]:
                alias kArgs: Int = len(Args.__types__)

            alias GMOCK_PP_INTERNAL_TYPE_TEST = lambda _i, _Data, _element: GMOCK_PP_COMMA_IF(_i) + _element

            static_assert(
                Test[*GMOCK_PP_FOR_EACH(GMOCK_PP_INTERNAL_TYPE_TEST, ~,
                                        (int, float, double, char))].kArgs == 4,
                "")

            alias GMOCK_PP_INTERNAL_VAR_TEST_1 = lambda _x: 1
            alias GMOCK_PP_INTERNAL_VAR_TEST_2 = lambda _x, _y: 2
            alias GMOCK_PP_INTERNAL_VAR_TEST_3 = lambda _x, _y, _z: 3
            alias GMOCK_PP_INTERNAL_VAR_TEST = lambda *args: GMOCK_PP_VARIADIC_CALL(GMOCK_PP_INTERNAL_VAR_TEST_, *args)

            static_assert(GMOCK_PP_INTERNAL_VAR_TEST(x, y) == 2, "")
            static_assert(GMOCK_PP_INTERNAL_VAR_TEST(silly) == 1, "")
            static_assert(GMOCK_PP_INTERNAL_VAR_TEST(x, y, z) == 3, "")

            alias GMOCK_PP_INTERNAL_IS_EMPTY_TEST_1 = None

            static_assert(GMOCK_PP_IS_EMPTY(GMOCK_PP_INTERNAL_IS_EMPTY_TEST_1), "")
            static_assert(GMOCK_PP_IS_EMPTY(), "")
            static_assert(GMOCK_PP_IS_ENCLOSED_PARENS((sss)), "")
            static_assert(GMOCK_PP_IS_EMPTY(GMOCK_PP_TAIL(1)), "")
            static_assert(GMOCK_PP_NARG0() == 0, "")