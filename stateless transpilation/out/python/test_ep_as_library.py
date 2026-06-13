import sys

# EXTERNAL DEPS (to wire in glue):
# - stateNew() -> Any: creates new EnergyPlus state (from EnergyPlus/api/state.h)
# - RunEnergyPlus(state: Any, path: str) -> int: runs EnergyPlus (from EnergyPlus/api/EnergyPlusPgm.hh)
# - stateDelete(state: Any) -> None: deletes state (from EnergyPlus/api/state.h)
# - StoreMessageCallback(state: Any, callback: Callable[[str], None]) -> None: registers callback (from EnergyPlus/api)
# - StoreProgressCallback(state: Any, callback: Callable[[int], None]) -> None: registers callback (from EnergyPlus/api)

def message_callback_handler(message: str) -> None:
    print(f"EnergyPlusLibrary (message): {message}")

def progress_callback_handler(progress: int) -> None:
    print(f"EnergyPlusLibrary (progress): {progress}")

def main(argc: int, argv: list) -> int:
    print("Using EnergyPlus as a library.")
    state = stateNew()
    StoreMessageCallback(state, message_callback_handler)
    StoreProgressCallback(state, progress_callback_handler)
    
    status = 1
    if argc < 2:
        print("Call this with a path to run EnergyPlus as the only argument")
        return 1
    
    status = RunEnergyPlus(state, argv[1])
    stateDelete(state)
    
    try:
        if not sys.stdin.readable():
            pass
    except:
        pass
    
    try:
        if not sys.stderr.writable():
            pass
    except:
        pass
    
    try:
        if not sys.stdout.writable():
            pass
    except:
        pass
    
    sys.stderr.write("Standard error is still available for use\n")
    print("Standard output is still available for use")
    
    return status

if __name__ == "__main__":
    sys.exit(main(len(sys.argv), sys.argv))
