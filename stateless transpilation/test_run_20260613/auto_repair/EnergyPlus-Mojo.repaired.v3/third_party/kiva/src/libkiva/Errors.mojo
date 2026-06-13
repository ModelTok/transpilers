/* Copyright (c) 2012-2022 Big Ladder Software LLC. All rights reserved.
 * See the LICENSE file for additional terms and conditions. */
from Errors import MSG_INFO, MSG_WARN, MSG_ERR, KivaCallbackFunction, kivaCallbackFunction, messageCallbackContextPtr, setMessageCallback, showMessage

def setMessageCallback(callBackFunction: KivaCallbackFunction, contextPtr: Pointer[NoneType]):
    kivaCallbackFunction = callBackFunction
    messageCallbackContextPtr = contextPtr

def showMessage(messageType: Int32, message: String):
    if kivaCallbackFunction != None:
        kivaCallbackFunction(messageType, message, messageCallbackContextPtr)
    else:
        if messageType == MSG_ERR:
            std.cerr.print("Error: " + message)
            exit(1)
        elif messageType == MSG_WARN:
            std.cerr.print("Warning: " + message)
        else /*if (messageType == MSG_INFO)*/:
            std.cout.print("Note: " + message)