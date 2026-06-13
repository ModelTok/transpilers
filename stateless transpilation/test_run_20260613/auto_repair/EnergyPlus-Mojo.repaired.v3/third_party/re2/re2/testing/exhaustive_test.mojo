from exhaustive_tester import EgrepTest

module re2:

    def EgrepLiterals_Lowercase():
        EgrepTest(3, 2, "abc.", 3, "abc", "")

    def EgrepLiterals_MixedCase():
        EgrepTest(3, 2, "AaBb.", 2, "AaBb", "")

    def EgrepLiterals_FoldCase():
        EgrepTest(3, 2, "abAB.", 2, "aBc@_~", "(?i:%s)")

    def EgrepLiterals_UTF8():
        EgrepTest(3, 2, "ab.", 4, "a\xE2\x98\xBA", "")