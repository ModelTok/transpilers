from memory import Pointer, DynamicVector
from sys import Int

# Constants
alias MAX_PATH: Int = 260
alias INVALID_FILE_ATTRIBUTES: Int = -1
alias SW_HIDE: Int = 0
alias MB_ICONERROR: Int = 0x00000010
alias MB_OK: Int = 0x00000000

# Type aliases
alias HINSTANCE = Pointer[None]
alias LPWSTR = Pointer[UInt16]
alias wchar_t = UInt16

# External Windows API functions
@external("kernel32", "GetModuleFileNameW")
def GetModuleFileNameW(hModule: HINSTANCE, lpFilename: Pointer[UInt16], nSize: Int) -> Int

@external("user32", "MessageBoxW")
def MessageBoxW(hWnd: Pointer[None], lpText: Pointer[UInt16], lpCaption: Pointer[UInt16], uType: Int) -> Int

@external("kernel32", "GetFileAttributesW")
def GetFileAttributesW(lpFileName: Pointer[UInt16]) -> Int

@external("shell32", "ShellExecuteW")
def ShellExecuteW(hwnd: Pointer[None], lpOperation: Pointer[UInt16], lpFile: Pointer[UInt16], lpParameters: Pointer[UInt16], lpDirectory: Pointer[UInt16], nShowCmd: Int) -> HINSTANCE

# Simple wide string wrapper (simulates wstring)
struct WString:
    var buffer: DynamicVector[UInt16]

    def __init__(inout self):
        self.buffer = DynamicVector[UInt16]()

    def __init__(inout self, literal: StringLiteral):
        self.buffer = DynamicVector[UInt16]()
        for ch in literal:
            self.buffer.push_back(ord(ch) as UInt16)
        self.buffer.push_back(0 as UInt16)

    def __init__(inout self, other: Self):
        self.buffer = DynamicVector[UInt16](other.buffer)

    def __add__(inout self, other: Self) -> Self:
        var result = Self()
        result.buffer = DynamicVector[UInt16](self.buffer)
        for v in other.buffer:
            result.buffer.push_back(v)
        return result

    def __add__(inout self, other: StringLiteral) -> Self:
        return self + WString(other)

    def __iadd__(inout self, other: Self):
        for v in other.buffer:
            self.buffer.push_back(v)

    def __iadd__(inout self, other: StringLiteral):
        self += WString(other)

    def find_last_of(inout self, chars: StringLiteral) -> Int:
        var pos: Int = -1
        for i in range(len(self.buffer)):
            let ch = self.buffer[i]
            for c in chars:
                if ch == (ord(c) as UInt16):
                    pos = i
        return pos

    def resize(inout self, new_size: Int):
        if new_size < len(self.buffer):
            self.buffer.resize(new_size)
            # Ensure null termination
            self.buffer[new_size - 1] = 0 as UInt16
        else:
            # Not needed for this translation

    def c_str(inout self) -> Pointer[UInt16]:
        return self.buffer.data

    def length(inout self) -> Int:
        return len(self.buffer) - 1  # exclude null terminator

def to_wstring(value: Int) -> WString:
    # Simple conversion (works for non-negative values)
    var result = WString()
    if value == 0:
        result += "0"
        return result
    var num = value
    var digits = List[UInt16]()
    while num > 0:
        digits.push_back((num % 10) as UInt16 + ord('0') as UInt16)
        num //= 10
    for i in range(len(digits) - 1, -1, -1):
        result.buffer.push_back(digits[i])
    result.buffer.push_back(0 as UInt16)
    return result

def wWinMain(hInstance: HINSTANCE, hPrevInstance: HINSTANCE, lpCmdLine: LPWSTR, nCmdShow: Int) -> Int:
    var path = WString()
    path.buffer.resize(MAX_PATH)
    path.buffer[0] = 0 as UInt16
    if GetModuleFileNameW(Pointer[None](address_of(1) - 1), path.c_str(), MAX_PATH) == 0:
        MessageBoxW(Pointer[None](), WString("Failed to get module file name!").c_str(), WString("Error").c_str(), MB_ICONERROR | MB_OK)
        return 1
    var directory = WString(path)
    let pos = directory.find_last_of("\\/")
    if pos != -1:
        directory.resize(pos)
    var targetApp = directory + "\\" + WString("energyplus.exe")
    if GetFileAttributesW(targetApp.c_str()) == INVALID_FILE_ATTRIBUTES:
        MessageBoxW(Pointer[None](), WString("Application not found!").c_str(), WString("Error").c_str(), MB_ICONERROR | MB_OK)
        return 1
    var args = WString("auxiliary ")
    args += WString(lpCmdLine)  # need to convert LPWSTR to WString
    let hInstance2 = ShellExecuteW(Pointer[None](), WString("open").c_str(), targetApp.c_str(), args.c_str(), directory.c_str(), SW_HIDE)
    if (hInstance2.address_of().load(Int) as Int) <= 32:
        var errorMsg = WString("Failed to launch application! Error code: ") + to_wstring(hInstance2.address_of().load(Int) as Int)
        MessageBoxW(Pointer[None](), errorMsg.c_str(), WString("Error").c_str(), MB_ICONERROR | MB_OK)
        return 1
    return 0