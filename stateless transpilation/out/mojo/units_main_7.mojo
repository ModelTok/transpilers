import sys

# EXTERNAL DEPS (to wire in glue):
# - gtest: Google Test C++ testing framework

struct GTestFlags:
    var break_on_failure: Bool
    var catch_exceptions: Bool

fn init_google_test(argc: Int, argv: List[String]) -> None:
    pass

fn run_all_tests() -> Int:
    return 0

fn main(argc: Int, argv: List[String]) -> Int:
    var flags = GTestFlags(
        break_on_failure=False,
        catch_exceptions=True
    )

    let enable_gtest_debug_mode = True
    if enable_gtest_debug_mode:
        flags.break_on_failure = True
        flags.catch_exceptions = False

    init_google_test(argc, argv)
    return run_all_tests()
