alias EIGEN_SHOULD_FAIL_TO_BUILD = False

def main():
    @parameter
    if EIGEN_SHOULD_FAIL_TO_BUILD:
        # This is just some text that won't compile as a C++ file, as a basic sanity check for failtest.
        let _: Int = "invalid"
    else:
