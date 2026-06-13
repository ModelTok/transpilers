from pathlib import Path
def configured_source_directory() -> Path:
    return Path("${CMAKE_SOURCE_DIR}")
def configured_build_directory() -> Path:
    return Path("${CMAKE_BINARY_DIR}")