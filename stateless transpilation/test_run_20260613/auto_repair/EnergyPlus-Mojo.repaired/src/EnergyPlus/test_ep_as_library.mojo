from api.EnergyPlusPgm import EnergyPlusData, stateNew, StoreMessageCallback, StoreProgressCallback, RunEnergyPlus, stateDelete, EnergyPlusState
from sys import stdin, stdout, stderr, argv

alias EXIT_FAILURE = 1
alias EXIT_SUCCESS = 0

def message_callback_handler(message: String):
    print("EnergyPlusLibrary (message):", message)

def progress_callback_handler(progress: Int):
    print("EnergyPlusLibrary (progress):", progress)

def main():
    print("Using EnergyPlus as a library.")
    var state_ptr = reinterpret[Pointer[EnergyPlusData]](stateNew())
    var state = state_ptr[]
    StoreMessageCallback(state, message_callback_handler)
    StoreProgressCallback(state, progress_callback_handler)
    var status: Int = EXIT_FAILURE
    if len(argv) < 2:
        print("Call this with a path to run EnergyPlus as the only argument")
        return EXIT_FAILURE
    status = RunEnergyPlus(state, argv[1])
    stateDelete(reinterpret[EnergyPlusState](state_ptr))
    if not stdin.good():
        stdin.clear()
    if not stderr.good():
        stderr.clear()
    if not stdout.good():
        stdout.clear()
    stderr.print("Standard error is still available for use")
    stdout.print("Standard output is still available for use")
    return status