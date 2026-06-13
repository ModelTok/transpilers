# EXTERNAL DEPS (to wire in glue):
# - stateNew() -> state: creates new EnergyPlus state (from EnergyPlus/api/state.h)
# - RunEnergyPlus(state, path: String) -> Int: runs EnergyPlus (from EnergyPlus/api/EnergyPlusPgm.hh)
# - stateDelete(state) -> None: deletes state (from EnergyPlus/api/state.h)
# - StoreMessageCallback(state, callback) -> None: registers callback (from EnergyPlus/api)
# - StoreProgressCallback(state, callback) -> None: registers callback (from EnergyPlus/api)

fn message_callback_handler(message: String) -> None:
    print("EnergyPlusLibrary (message): " + message)

fn progress_callback_handler(progress: Int) -> None:
    print("EnergyPlusLibrary (progress): " + str(progress))

fn run_main(argc: Int, argv: List[String]) -> Int:
    print("Using EnergyPlus as a library.")
    var state = stateNew()
    StoreMessageCallback(state, message_callback_handler)
    StoreProgressCallback(state, progress_callback_handler)
    
    var status: Int = 1
    if argc < 2:
        print("Call this with a path to run EnergyPlus as the only argument")
        return 1
    
    status = RunEnergyPlus(state, argv[1])
    stateDelete(state)
    
    print("Standard error is still available for use")
    print("Standard output is still available for use")
    
    return status

fn main() -> None:
    var argc = len(argv)
    _ = run_main(argc, argv)
