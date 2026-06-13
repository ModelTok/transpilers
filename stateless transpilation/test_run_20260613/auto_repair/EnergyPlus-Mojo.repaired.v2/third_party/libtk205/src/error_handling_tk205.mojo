from error_handling_tk205 import MsgSeverity, msg_handler
from memory import Pointer
from utils import String

var error_handler_: msg_handler = msg_handler()
var caller_info_: Pointer[None] = Pointer[None]()

def set_error_handler(handler: msg_handler, caller_info: Pointer[None]):
    error_handler_ = handler
    caller_info_ = caller_info

def show_message(severity: MsgSeverity, message: String):
    var severity_str: Dict[MsgSeverity, String] = {
        MsgSeverity.DEBUG_205: "DEBUG",
        MsgSeverity.INFO_205: "INFO",
        MsgSeverity.WARN_205: "WARN",
        MsgSeverity.ERR_205: "ERR"
    }
    if not error_handler_:

    else:
        error_handler_(severity, message, caller_info_)