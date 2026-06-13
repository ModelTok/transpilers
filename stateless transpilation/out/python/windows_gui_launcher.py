import ctypes

# EXTERNAL DEPS (to wire in glue):
# None

MAX_PATH = 260
INVALID_FILE_ATTRIBUTES = -1
MB_ICONERROR = 0x00000010
MB_OK = 0x00000000
SW_HIDE = 0

kernel32 = ctypes.windll.kernel32
user32 = ctypes.windll.user32
shell32 = ctypes.windll.shell32

def wWinMain(hInstance, hPrevInstance, lpCmdLine, nCmdShow):
    path = ctypes.create_unicode_buffer(MAX_PATH)
    if kernel32.GetModuleFileNameW(None, path, MAX_PATH) == 0:
        user32.MessageBoxW(None, "Failed to get module file name!", "Error", MB_ICONERROR | MB_OK)
        return 1
    
    directory = path.value
    pos = max(directory.rfind("\\"), directory.rfind("/"))
    if pos != -1:
        directory = directory[:pos]
    
    targetApp = directory + "\\energyplus.exe"
    
    if kernel32.GetFileAttributesW(targetApp) == INVALID_FILE_ATTRIBUTES:
        user32.MessageBoxW(None, "Application not found!", "Error", MB_ICONERROR | MB_OK)
        return 1
    
    args = "auxiliary " + lpCmdLine
    
    hInstance2 = shell32.ShellExecuteW(None, "open", targetApp, args, directory, SW_HIDE)
    
    result = int(hInstance2)
    if result <= 32:
        errorMsg = "Failed to launch application! Error code: " + str(result)
        user32.MessageBoxW(None, errorMsg, "Error", MB_ICONERROR | MB_OK)
        return 1
    
    return 0
