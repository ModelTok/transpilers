from gtest.gtest import *
from gtest.gtest-message import Message
from testing import IsSubstring, StringStreamToString

@test
def MessageTest_DefaultConstructor() raises:
    let msg = Message()
    EXPECT_EQ("", msg.GetString())

@test
def MessageTest_CopyConstructor() raises:
    let msg1 = Message("Hello")
    let msg2 = Message(msg1)
    EXPECT_EQ("Hello", msg2.GetString())

@test
def MessageTest_ConstructsFromCString() raises:
    let msg = Message("Hello")
    EXPECT_EQ("Hello", msg.GetString())

@test
def MessageTest_StreamsFloat() raises:
    let s = (Message() << 1.23456 << " " << 2.34567).GetString()
    EXPECT_PRED_FORMAT2(IsSubstring, "1.234560", s.c_str())
    EXPECT_PRED_FORMAT2(IsSubstring, " 2.345669", s.c_str())

@test
def MessageTest_StreamsDouble() raises:
    let s = (Message() << 1260570880.4555497 << " " << 1260572265.1954534).GetString()
    EXPECT_PRED_FORMAT2(IsSubstring, "1260570880.45", s.c_str())
    EXPECT_PRED_FORMAT2(IsSubstring, " 1260572265.19", s.c_str())

@test
def MessageTest_StreamsPointer() raises:
    var n: Int = 0
    let p = Pointer[Int].address_of(n)
    EXPECT_NE("(null)", (Message() << p).GetString())

@test
def MessageTest_StreamsNullPointer() raises:
    let p = Pointer[Int]()
    EXPECT_EQ("(null)", (Message() << p).GetString())

@test
def MessageTest_StreamsCString() raises:
    EXPECT_EQ("Foo", (Message() << "Foo").GetString())

@test
def MessageTest_StreamsNullCString() raises:
    let p = Pointer[Int8]()
    EXPECT_EQ("(null)", (Message() << p).GetString())

@test
def MessageTest_StreamsString() raises:
    let str = String("Hello")
    EXPECT_EQ("Hello", (Message() << str).GetString())

@test
def MessageTest_StreamsStringWithEmbeddedNUL() raises:
    let char_array_with_nul: String = "Here's a NUL\0 and some more string"
    let string_with_nul = String(char_array_with_nul)
    EXPECT_EQ("Here's a NUL\\0 and some more string", (Message() << string_with_nul).GetString())

@test
def MessageTest_StreamsNULChar() raises:
    EXPECT_EQ("\\0", (Message() << '\0').GetString())

@test
def MessageTest_StreamsInt() raises:
    EXPECT_EQ("123", (Message() << 123).GetString())

@test
def MessageTest_StreamsBasicIoManip() raises:
    EXPECT_EQ("Line 1.\nA NUL char \\0 in line 2.",
              (Message() << "Line 1." << endl << "A NUL char " << ends << flush << " in line 2.").GetString())

@test
def MessageTest_GetString() raises:
    let msg = Message()
    msg << 1 << " lamb"
    EXPECT_EQ("1 lamb", msg.GetString())

@test
def MessageTest_StreamsToOStream() raises:
    let msg = Message("Hello")
    var ss = StringStream()
    ss << msg
    EXPECT_EQ("Hello", StringStreamToString(&ss))

@test
def MessageTest_DoesNotTakeUpMuchStackSpace() raises:
    EXPECT_LE(sizeof[Message](), 16)