from sys import dlopen, dlsym, dlclose, dlerror
def main() -> Int32:
    var dlsym_error: Pointer[Byte]
    print("Opening eplus shared library...")
    var handle = dlopen("{EPLUS_INSTALL_NO_SLASH}{LIB_FILE_NAME}".c_str(), 1)  # RTLD_LAZY
    if not handle:
        print("Cannot open library:")
        return 1
    dlerror()  # resets errors
    print("Getting a new state instance...")
    alias fNewState = fn(Pointer[Byte]) -> Pointer[Byte]
    var stateNewPtr = dlsym(handle, "stateNew".c_str())
    dlsym_error = dlerror()
    if dlsym_error:
        print("Cannot load symbol stateNew")
        dlclose(handle)
        return 1
    var stateNew = @_cdecl (fNewState)(stateNewPtr)
    var state = stateNew()
    dlsym_error = dlerror()
    if dlsym_error:
        print("Cannot instantiate a new state from stateNew")
        dlclose(handle)
        return 1
    print("Calling to initialize...")
    alias init_t = fn(Pointer[Byte]) -> ()
    var initPtr = dlsym(handle, "initializeFunctionalAPI".c_str())
    dlsym_error = dlerror()
    if dlsym_error:
        print("Cannot load symbol 'initializeFunctionalAPI':")
        dlclose(handle)
        return 1
    var init = @_cdecl (init_t)(initPtr)
    init(state)
    dlsym_error = dlerror()
    if dlsym_error:
        print("Could not call initialize function")
        dlclose(handle)
        return 1
    print("Getting a new Glycol instance...")
    alias newGly = fn(Pointer[Byte], Pointer[Byte]) -> Pointer[Byte]
    var thisNewGlyPtr = dlsym(handle, "glycolNew".c_str())
    dlsym_error = dlerror()
    if dlsym_error:
        print("Cannot load symbol 'glycolNew':")
        dlclose(handle)
        return 1
    var thisNewGly = @_cdecl (newGly)(thisNewGlyPtr)
    var glycolInstance = thisNewGly(state, "water".c_str())
    dlsym_error = dlerror()
    if dlsym_error:
        print("Cannot get a new glycol instance via glycolNew':")
        dlclose(handle)
        return 1
    print("Calculating Cp at T = 25C...")
    alias cp = fn(Pointer[Byte], Pointer[Byte], Float64) -> Float64
    var glycolCpPtr = dlsym(handle, "glycolSpecificHeat".c_str())
    dlsym_error = dlerror()
    if dlsym_error:
        print("Cannot load symbol 'glycolSpecificHeat':")
        dlclose(handle)
        return 1
    var glycolCp = @_cdecl (cp)(glycolCpPtr)
    var cpValue = glycolCp(state, glycolInstance, 25.0)
    dlsym_error = dlerror()
    if dlsym_error:
        print("Cannot calculate Cp with glycolSpecificHeat':")
        dlclose(handle)
        return 1
    print("Calculated Cp = ", cpValue)
    assert cpValue > 4150.0
    assert cpValue < 4200.0
    print("Closing library...")
    dlclose(handle)
    return 0