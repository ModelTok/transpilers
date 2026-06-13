import ctypes
from ctypes import wintypes

# EXTERNAL DEPS (to wire in glue):
# - Windows API: kernel32.GetModuleFileNameW, user32.MessageBoxW, kernel32.GetFileAttributesW, shell32.ShellExecuteW

MAX_PATH = 260
INVALID_FILE_ATTRIBUTES = 0xFFFFFFFF
MB_ICONERROR = 0x10
MB_OK = 0x00
SW_HIDE = 0

GetModuleFileNameW = ctypes.windll.kernel32.GetModuleFileNameW
GetModuleFileNameW.argtypes = [wintypes.HANDLE, wintypes.LPWSTR, wintypes.DWORD]
GetModuleFileNameW.restype = wintypes.DWORD

MessageBoxW = ctypes.windll.user32.MessageBoxW
MessageBoxW.argtypes = [wintypes.HANDLE, wintypes.LPCWSTR, wintypes.LPCWSTR, wintypes.UINT]
MessageBoxW.restype = wintypes.INT

GetFileAttributesW = ctypes.windll.kernel32.GetFileAttributesW
GetFileAttributesW.argtypes = [wintypes.LPCWSTR]
GetFileAttributesW.restype = wintypes.DWORD

ShellExecuteW = ctypes.windll.shell32.ShellExecuteW
ShellExecuteW.argtypes = [wintypes.HANDLE, wintypes.LPCWSTR, wintypes.LPCWSTR, wintypes.LPCWSTR, wintypes.LPCWSTR, wintypes.INT]
ShellExecuteW.restype = wintypes.HINSTANCE

def w_win_main(h_instance, h_prev_instance, lp_cmd_line, n_cmd_show):
    path = ctypes.create_unicode_buffer(MAX_PATH)
    if GetModuleFileNameW(None, path, MAX_PATH) == 0:
        MessageBoxW(None, "Failed to get module file name!", "Error", MB_ICONERROR | MB_OK)
        return 1
    
    directory = path.value
    pos = max(directory.rfind("\\"), directory.rfind("/"))
    if pos != -1:
        directory = directory[:pos]
    
    target_app = directory + "\\energyplus.exe"
    
    if GetFileAttributesW(target_app) == INVALID_FILE_ATTRIBUTES:
        MessageBoxW(None, "Application not found!", "Error", MB_ICONERROR | MB_OK)
        return 1
    
    args = "auxiliary " + lp_cmd_line if lp_cmd_line else "auxiliary "
    
    h_instance2 = ShellExecuteW(None, "open", target_app, args, directory, SW_HIDE)
    
    if int(h_instance2) <= 32:
        error_msg = "Failed to launch application! Error code: " + str(int(h_instance2))
        MessageBoxW(None, error_msg, "Error", MB_ICONERROR | MB_OK)
        return 1
    
    return 0
