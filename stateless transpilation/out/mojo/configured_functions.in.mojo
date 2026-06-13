# Copyright (c) 1996-present, The Board of Trustees of the University of Illinois,
# The Regents of the University of California, through Lawrence Berkeley National Laboratory
# (subject to receipt of any required approvals from the U.S. Dept. of Energy), Oak Ridge
# National Laboratory, managed by UT-Battelle, Alliance for Energy Innovation, LLC, and other
# contributors. All rights reserved.


fn configured_source_directory() -> String:
    return String("${CMAKE_SOURCE_DIR}")


fn configured_build_directory() -> String:
    return String("${CMAKE_BINARY_DIR}")
