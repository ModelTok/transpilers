# EXTERNAL DEPS (to wire in glue):
# - Windows API: kernel32.GetModuleFileNameW, user32.MessageBoxW, kernel32.GetFileAttributesW, shell32.ShellExecuteW

alias MAX_PATH = 260
alias INVALID_FILE_ATTRIBUTES = 0xFFFFFFFF
alias MB_ICONERROR = 0x10
alias MB_OK = 0x00
alias SW_HIDE = 0

@always_inline
fn utf16_from_string(s: String) -> DynamicVector[UInt16]:
    var result = DynamicVector[UInt16]()
    for c in s:
        var code = ord(c)
        if code < 0x10000:
            result.push_back(code)
        else:
            code -= 0x10000
            result.push_back((code >> 10) + 0xD800)
            result.push_back((code & 0x3FF) + 0xDC00)
    result.push_back(0)
    return result

@always_inline
fn utf16_to_string(ptr: UnsafePointer[UInt16]) -> String:
    var result = String()
    var i = 0
    while True:
        let ch = ptr[i]
        if ch == 0:
            break
        i += 1
        if ch < 0xD800 or ch > 0xDBFF:
            result += chr(int(ch))
        else:
            let high = ch
            let low = ptr[i]
            i += 1
            let code = ((int(high) - 0xD800) << 10) + (int(low) - 0xDC00) + 0x10000
            result += chr(code)
    return result

@external("C", "GetModuleFileNameW")
fn GetModuleFileNameW(hModule: UnsafePointer[UInt8], lpFilename: UnsafePointer[UInt16], nSize: UInt32) -> UInt32: ...

@external("C", "MessageBoxW")
fn MessageBoxW(hWnd: UnsafePointer[UInt8], lpText: UnsafePointer[UInt16], lpCaption: UnsafePointer[UInt16], uType: UInt32) -> Int32: ...

@external("C", "GetFileAttributesW")
fn GetFileAttributesW(lpFileName: UnsafePointer[UInt16]) -> UInt32: ...

@external("C", "ShellExecuteW")
fn ShellExecuteW(hwnd: UnsafePointer[UInt8], lpOperation: UnsafePointer[UInt16], lpFile: UnsafePointer[UInt16], lpParameters: UnsafePointer[UInt16], lpDirectory: UnsafePointer[UInt16], nShowCmd: Int32) -> UnsafePointer[UInt8]: ...

fn w_win_main(h_instance: UnsafePointer[UInt8], h_prev_instance: UnsafePointer[UInt8], lp_cmd_line: String, n_cmd_show: Int32) -> Int32:
    var path = DynamicVector[UInt16](capacity=MAX_PATH)
    for _ in range(MAX_PATH):
        path.push_back(0)
    
    if GetModuleFileNameW(UnsafePointer[UInt8](), path.data(), MAX_PATH) == 0:
        var error_utf16 = utf16_from_string("Failed to get module file name!")
        var error_title = utf16_from_string("Error")
        MessageBoxW(UnsafePointer[UInt8](), error_utf16.data(), error_title.data(), MB_ICONERROR | MB_OK)
        return 1
    
    var directory = utf16_to_string(path.data())
    var pos = max(directory.rfind("\\"), directory.rfind("/"))
    if pos != -1:
        directory = directory[:pos]
    
    var target_app = directory + "\\energyplus.exe"
    
    var target_app_utf16 = utf16_from_string(target_app)
    if GetFileAttributesW(target_app_utf16.data()) == INVALID_FILE_ATTRIBUTES:
        var error_msg = utf16_from_string("Application not found!")
        var error_title = utf16_from_string("Error")
        MessageBoxW(UnsafePointer[UInt8](), error_msg.data(), error_title.data(), MB_ICONERROR | MB_OK)
        return 1
    
    var args = "auxiliary " + lp_cmd_line
    
    var args_utf16 = utf16_from_string(args)
    var operation_utf16 = utf16_from_string("open")
    var directory_utf16 = utf16_from_string(directory)
    
    var h_instance2 = ShellExecuteW(UnsafePointer[UInt8](), operation_utf16.data(), target_app_utf16.data(), args_utf16.data(), directory_utf16.data(), SW_HIDE)
    
    if int(h_instance2) <= 32:
        var error_msg_num = "Failed to launch application! Error code: " + str(int(h_instance2))
        var error_utf16 = utf16_from_string(error_msg_num)
        var error_title = utf16_from_string("Error")
        MessageBoxW(UnsafePointer[UInt8](), error_utf16.data(), error_title.data(), MB_ICONERROR | MB_OK)
        return 1
    
    return 0
