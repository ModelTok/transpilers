from gmock.gmock-actions import *
from gmock.gmock import *
from gmock.internal.gmock-port import *
from gtest.gtest import *
from gtest.gtest-spi import *
import algorithm
import iterator
import memory
import string
import type_traits

# pragma warning(push)
# pragma warning(disable:4100)
# pragma warning(disable:4800)

# pragma warning(pop)

namespace:

using _ = testing._
using Action = testing.Action
using ActionInterface = testing.ActionInterface
using Assign = testing.Assign
using ByMove = testing.ByMove
using ByRef = testing.ByRef
using DefaultValue = testing.DefaultValue
using DoAll = testing.DoAll
using DoDefault = testing.DoDefault
using IgnoreResult = testing.IgnoreResult
using Invoke = testing.Invoke
using InvokeWithoutArgs = testing.InvokeWithoutArgs
using MakePolymorphicAction = testing.MakePolymorphicAction
using PolymorphicAction = testing.PolymorphicAction
using Return = testing.Return
using ReturnNew = testing.ReturnNew
using ReturnNull = testing.ReturnNull
using ReturnRef = testing.ReturnRef
using ReturnRefOfCopy = testing.ReturnRefOfCopy
using ReturnRoundRobin = testing.ReturnRoundRobin
using SetArgPointee = testing.SetArgPointee
using SetArgumentPointee = testing.SetArgumentPointee
using Unused = testing.Unused
using WithArgs = testing.WithArgs
using BuiltInDefaultValue = testing.internal.BuiltInDefaultValue

# if !GTEST_OS_WINDOWS_MOBILE
using SetErrnoAndReturn = testing.SetErrnoAndReturn
# endif

@testing.fixture
class BuiltInDefaultValueTest:

@testing.test
def IsNullForPointerTypes(self):
    EXPECT_TRUE(BuiltInDefaultValue[IntPointer].Get() == None)
    EXPECT_TRUE(BuiltInDefaultValue[ConstCharPointer].Get() == None)
    EXPECT_TRUE(BuiltInDefaultValue[VoidPointer].Get() == None)

@testing.test
def ExistsForPointerTypes(self):
    EXPECT_TRUE(BuiltInDefaultValue[IntPointer].Exists())
    EXPECT_TRUE(BuiltInDefaultValue[ConstCharPointer].Exists())
    EXPECT_TRUE(BuiltInDefaultValue[VoidPointer].Exists())

@testing.test
def IsZeroForNumericTypes(self):
    EXPECT_EQ(0, BuiltInDefaultValue[UInt8].Get())
    EXPECT_EQ(0, BuiltInDefaultValue[Int8].Get())
    EXPECT_EQ(0, BuiltInDefaultValue[Int8].Get())
# if GMOCK_WCHAR_T_IS_NATIVE_
# if !defined(__WCHAR_UNSIGNED__)
    EXPECT_EQ(0, BuiltInDefaultValue[WChar].Get())
# else
    EXPECT_EQ(0, BuiltInDefaultValue[WChar].Get())
# endif
# endif
    EXPECT_EQ(0, BuiltInDefaultValue[UInt16].Get())
    EXPECT_EQ(0, BuiltInDefaultValue[Int16].Get())
    EXPECT_EQ(0, BuiltInDefaultValue[Int16].Get())
    EXPECT_EQ(0, BuiltInDefaultValue[UInt32].Get())
    EXPECT_EQ(0, BuiltInDefaultValue[Int32].Get())
    EXPECT_EQ(0, BuiltInDefaultValue[Int32].Get())
    EXPECT_EQ(0, BuiltInDefaultValue[UInt64].Get())
    EXPECT_EQ(0, BuiltInDefaultValue[Int64].Get())
    EXPECT_EQ(0, BuiltInDefaultValue[Int64].Get())
    EXPECT_EQ(0, BuiltInDefaultValue[Float32].Get())
    EXPECT_EQ(0, BuiltInDefaultValue[Float64].Get())

@testing.test
def ExistsForNumericTypes(self):
    EXPECT_TRUE(BuiltInDefaultValue[UInt8].Exists())
    EXPECT_TRUE(BuiltInDefaultValue[Int8].Exists())
    EXPECT_TRUE(BuiltInDefaultValue[Int8].Exists())
# if GMOCK_WCHAR_T_IS_NATIVE_
    EXPECT_TRUE(BuiltInDefaultValue[WChar].Exists())
# endif
    EXPECT_TRUE(BuiltInDefaultValue[UInt16].Exists())
    EXPECT_TRUE(BuiltInDefaultValue[Int16].Exists())
    EXPECT_TRUE(BuiltInDefaultValue[Int16].Exists())
    EXPECT_TRUE(BuiltInDefaultValue[UInt32].Exists())
    EXPECT_TRUE(BuiltInDefaultValue[Int32].Exists())
    EXPECT_TRUE(BuiltInDefaultValue[Int32].Exists())
    EXPECT_TRUE(BuiltInDefaultValue[UInt64].Exists())
    EXPECT_TRUE(BuiltInDefaultValue[Int64].Exists())
    EXPECT_TRUE(BuiltInDefaultValue[Int64].Exists())
    EXPECT_TRUE(BuiltInDefaultValue[Float32].Exists())
    EXPECT_TRUE(BuiltInDefaultValue[Float64].Exists())

@testing.test
def IsFalseForBool(self):
    EXPECT_FALSE(BuiltInDefaultValue[Bool].Get())

@testing.test
def BoolExists(self):
    EXPECT_TRUE(BuiltInDefaultValue[Bool].Exists())

@testing.test
def IsEmptyStringForString(self):
    EXPECT_EQ("", BuiltInDefaultValue[String].Get())

@testing.test
def ExistsForString(self):
    EXPECT_TRUE(BuiltInDefaultValue[String].Exists())

@testing.test
def WorksForConstTypes(self):
    EXPECT_EQ("", BuiltInDefaultValue[ConstString].Get())
    EXPECT_EQ(0, BuiltInDefaultValue[ConstInt].Get())
    EXPECT_TRUE(BuiltInDefaultValue[CharPointerConst].Get() == None)
    EXPECT_FALSE(BuiltInDefaultValue[ConstBool].Get())

class MyDefaultConstructible:
    def __init__(self):
        self.value_ = 42
    def value(self) -> Int:
        return self.value_
    var value_: Int

class MyNonDefaultConstructible:
    def __init__(self, a_value: Int):
        self.value_ = a_value
    def value(self) -> Int:
        return self.value_
    var value_: Int

@testing.test
def ExistsForDefaultConstructibleType(self):
    EXPECT_TRUE(BuiltInDefaultValue[MyDefaultConstructible].Exists())

@testing.test
def IsDefaultConstructedForDefaultConstructibleType(self):
    EXPECT_EQ(42, BuiltInDefaultValue[MyDefaultConstructible].Get().value())

@testing.test
def DoesNotExistForNonDefaultConstructibleType(self):
    EXPECT_FALSE(BuiltInDefaultValue[MyNonDefaultConstructible].Exists())

@testing.fixture
class BuiltInDefaultValueDeathTest:

@testing.test
def IsUndefinedForReferences(self):
    EXPECT_DEATH_IF_SUPPORTED({
        BuiltInDefaultValue[IntRef].Get()
    }, "")
    EXPECT_DEATH_IF_SUPPORTED({
        BuiltInDefaultValue[ConstCharRef].Get()
    }, "")

@testing.test
def IsUndefinedForNonDefaultConstructibleType(self):
    EXPECT_DEATH_IF_SUPPORTED({
        BuiltInDefaultValue[MyNonDefaultConstructible].Get()
    }, "")

@testing.test
def IsInitiallyUnset(self):
    EXPECT_FALSE(DefaultValue[Int].IsSet())
    EXPECT_FALSE(DefaultValue[MyDefaultConstructible].IsSet())
    EXPECT_FALSE(DefaultValue[ConstMyNonDefaultConstructible].IsSet())

@testing.test
def CanBeSetAndUnset(self):
    EXPECT_TRUE(DefaultValue[Int].Exists())
    EXPECT_FALSE(DefaultValue[ConstMyNonDefaultConstructible].Exists())
    DefaultValue[Int].Set(1)
    DefaultValue[ConstMyNonDefaultConstructible].Set(
        MyNonDefaultConstructible(42))
    EXPECT_EQ(1, DefaultValue[Int].Get())
    EXPECT_EQ(42, DefaultValue[ConstMyNonDefaultConstructible].Get().value())
    EXPECT_TRUE(DefaultValue[Int].Exists())
    EXPECT_TRUE(DefaultValue[ConstMyNonDefaultConstructible].Exists())
    DefaultValue[Int].Clear()
    DefaultValue[ConstMyNonDefaultConstructible].Clear()
    EXPECT_FALSE(DefaultValue[Int].IsSet())
    EXPECT_FALSE(DefaultValue[ConstMyNonDefaultConstructible].IsSet())
    EXPECT_TRUE(DefaultValue[Int].Exists())
    EXPECT_FALSE(DefaultValue[ConstMyNonDefaultConstructible].Exists())

@testing.fixture
class DefaultValueDeathTest:

@testing.test
def GetReturnsBuiltInDefaultValueWhenUnset(self):
    EXPECT_FALSE(DefaultValue[Int].IsSet())
    EXPECT_TRUE(DefaultValue[Int].Exists())
    EXPECT_FALSE(DefaultValue[MyNonDefaultConstructible].IsSet())
    EXPECT_FALSE(DefaultValue[MyNonDefaultConstructible].Exists())
    EXPECT_EQ(0, DefaultValue[Int].Get())
    EXPECT_DEATH_IF_SUPPORTED({
        DefaultValue[MyNonDefaultConstructible].Get()
    }, "")

@testing.test
def GetWorksForMoveOnlyIfSet(self):
    EXPECT_TRUE(DefaultValue[UniquePtrInt].Exists())
    EXPECT_TRUE(DefaultValue[UniquePtrInt].Get() == None)
    DefaultValue[UniquePtrInt].SetFactory(lambda: UniquePtrInt(Int(42)))
    EXPECT_TRUE(DefaultValue[UniquePtrInt].Exists())
    var i: UniquePtrInt = DefaultValue[UniquePtrInt].Get()
    EXPECT_EQ(42, *i)

@testing.test
def GetWorksForVoid(self):
    return DefaultValue[Void].Get()

@testing.test
def IsInitiallyUnset(self):
    EXPECT_FALSE(DefaultValue[IntRef].IsSet())
    EXPECT_FALSE(DefaultValue[MyDefaultConstructibleRef].IsSet())
    EXPECT_FALSE(DefaultValue[MyNonDefaultConstructibleRef].IsSet())

@testing.test
def IsInitiallyNotExisting(self):
    EXPECT_FALSE(DefaultValue[IntRef].Exists())
    EXPECT_FALSE(DefaultValue[MyDefaultConstructibleRef].Exists())
    EXPECT_FALSE(DefaultValue[MyNonDefaultConstructibleRef].Exists())

@testing.test
def CanBeSetAndUnset(self):
    var n: Int = 1
    DefaultValue[ConstIntRef].Set(n)
    var x: MyNonDefaultConstructible = MyNonDefaultConstructible(42)
    DefaultValue[MyNonDefaultConstructibleRef].Set(x)
    EXPECT_TRUE(DefaultValue[ConstIntRef].Exists())
    EXPECT_TRUE(DefaultValue[MyNonDefaultConstructibleRef].Exists())
    EXPECT_EQ(&n, &(DefaultValue[ConstIntRef].Get()))
    EXPECT_EQ(&x, &(DefaultValue[MyNonDefaultConstructibleRef].Get()))
    DefaultValue[ConstIntRef].Clear()
    DefaultValue[MyNonDefaultConstructibleRef].Clear()
    EXPECT_FALSE(DefaultValue[ConstIntRef].Exists())
    EXPECT_FALSE(DefaultValue[MyNonDefaultConstructibleRef].Exists())
    EXPECT_FALSE(DefaultValue[ConstIntRef].IsSet())
    EXPECT_FALSE(DefaultValue[MyNonDefaultConstructibleRef].IsSet())

@testing.fixture
class DefaultValueOfReferenceDeathTest:

@testing.test
def GetReturnsBuiltInDefaultValueWhenUnset(self):
    EXPECT_FALSE(DefaultValue[IntRef].IsSet())
    EXPECT_FALSE(DefaultValue[MyNonDefaultConstructibleRef].IsSet())
    EXPECT_DEATH_IF_SUPPORTED({
        DefaultValue[IntRef].Get()
    }, "")
    EXPECT_DEATH_IF_SUPPORTED({
        DefaultValue[MyNonDefaultConstructible].Get()
    }, "")

type MyGlobalFunction = (Bool, Int) -> Int

class MyActionImpl(ActionInterface[MyGlobalFunction]):
    def Perform(self, args: Tuple[Bool, Int]) -> Int:
        return args[0] if args[0] else 0

@testing.test
def CanBeImplementedByDefiningPerform(self):
    var my_action_impl: MyActionImpl = MyActionImpl()
    _ = my_action_impl

@testing.test
def MakeAction(self):
    var action: Action[MyGlobalFunction] = MakeAction(MyActionImpl())
    EXPECT_EQ(5, action.Perform(Tuple(true, 5)))

@testing.test
def CanBeConstructedFromActionInterface(self):
    var action: Action[MyGlobalFunction] = Action[MyGlobalFunction](MyActionImpl())

@testing.test
def DelegatesWorkToActionInterface(self):
    var action: Action[MyGlobalFunction] = Action[MyGlobalFunction](MyActionImpl())
    EXPECT_EQ(5, action.Perform(Tuple(true, 5)))
    EXPECT_EQ(0, action.Perform(Tuple(false, 1)))

@testing.test
def IsCopyable(self):
    var a1: Action[MyGlobalFunction] = Action[MyGlobalFunction](MyActionImpl())
    var a2: Action[MyGlobalFunction] = a1
    EXPECT_EQ(5, a1.Perform(Tuple(true, 5)))
    EXPECT_EQ(0, a1.Perform(Tuple(false, 1)))
    EXPECT_EQ(5, a2.Perform(Tuple(true, 5)))
    EXPECT_EQ(0, a2.Perform(Tuple(false, 1)))
    a2 = a1
    EXPECT_EQ(5, a1.Perform(Tuple(true, 5)))
    EXPECT_EQ(0, a1.Perform(Tuple(false, 1)))
    EXPECT_EQ(5, a2.Perform(Tuple(true, 5)))
    EXPECT_EQ(0, a2.Perform(Tuple(false, 1)))

class IsNotZero(ActionInterface[(Int) -> Bool]):
    def Perform(self, arg: Tuple[Int]) -> Bool:
        return arg[0] != 0

@testing.test
def CanBeConvertedToOtherActionType(self):
    var a1: Action[(Int) -> Bool] = Action[(Int) -> Bool](IsNotZero())
    var a2: Action[(Char) -> Int] = Action[(Char) -> Int](a1)
    EXPECT_EQ(1, a2.Perform(Tuple('a')))
    EXPECT_EQ(0, a2.Perform(Tuple('\0')))

class ReturnSecondArgumentAction:
    def Perform[Result: AnyType, ArgumentTuple: AnyType](self, args: ArgumentTuple) -> Result:
        return args[1]

class ReturnZeroFromNullaryFunctionAction:
    def Perform[Result: AnyType](self, args: Tuple[()]) -> Result:
        return 0

def ReturnSecondArgument() -> PolymorphicAction[ReturnSecondArgumentAction]:
    return MakePolymorphicAction(ReturnSecondArgumentAction())

def ReturnZeroFromNullaryFunction() -> PolymorphicAction[ReturnZeroFromNullaryFunctionAction]:
    return MakePolymorphicAction(ReturnZeroFromNullaryFunctionAction())

@testing.test
def ConstructsActionFromImpl(self):
    var a1: Action[(Bool, Int, Float64) -> Int] = ReturnSecondArgument()
    EXPECT_EQ(5, a1.Perform(Tuple(false, 5, 2.0)))

@testing.test
def WorksWhenPerformHasOneTemplateParameter(self):
    var a1: Action[() -> Int] = ReturnZeroFromNullaryFunction()
    EXPECT_EQ(0, a1.Perform(Tuple()))
    var a2: Action[() -> VoidPointer] = ReturnZeroFromNullaryFunction()
    EXPECT_TRUE(a2.Perform(Tuple()) == None)

@testing.test
def WorksForVoid(self):
    var ret: Action[(Int) -> Void] = Return()
    return ret.Perform(Tuple(1))

@testing.test
def ReturnsGivenValue(self):
    var ret: Action[() -> Int] = Return(1)
    EXPECT_EQ(1, ret.Perform(Tuple()))
    ret = Return(-5)
    EXPECT_EQ(-5, ret.Perform(Tuple()))

@testing.test
def AcceptsStringLiteral(self):
    var a1: Action[() -> ConstCharPointer] = Return("Hello")
    EXPECT_STREQ("Hello", a1.Perform(Tuple()))
    var a2: Action[() -> String] = Return("world")
    EXPECT_EQ("world", a2.Perform(Tuple()))

struct IntegerVectorWrapper:
    var v: Pointer[List[Int]]
    def __init__(self, _v: List[Int]):
        self.v = Pointer.address_of(_v)

@testing.test
def SupportsWrapperReturnType(self):
    var v: List[Int] = List[Int]()
    for i in range(5):
        v.append(i)
    var a: Action[() -> IntegerVectorWrapper] = Return(v)
    var result: List[Int] = *(a.Perform(Tuple()).v)
    EXPECT_THAT(result, testing.ElementsAre(0, 1, 2, 3, 4))

struct Base:
    def __eq__(self, other: Base) -> Bool:
        return True

struct Derived(Base):
    def __eq__(self, other: Derived) -> Bool:
        return True

@testing.test
def IsCovariant(self):
    var base: Base = Base()
    var derived: Derived = Derived()
    var ret: Action[() -> BasePointer] = Return(Pointer.address_of(base))
    EXPECT_EQ(Pointer.address_of(base), ret.Perform(Tuple()))
    ret = Return(Pointer.address_of(derived))
    EXPECT_EQ(Pointer.address_of(derived), ret.Perform(Tuple()))

class FromType:
    def __init__(self, is_converted: Pointer[Bool]):
        self.converted_ = is_converted
    def converted(self) -> Pointer[Bool]:
        return self.converted_
    var converted_: Pointer[Bool]

class ToType:
    def __init__(self, x: FromType):
        *(x.converted()) = True

@testing.test
def ConvertsArgumentWhenConverted(self):
    var converted: Bool = False
    var x: FromType = FromType(Pointer.address_of(converted))
    var action: Action[() -> ToType] = Action[() -> ToType](Return(x))
    EXPECT_TRUE(converted)  # "Return must convert its argument in its own conversion operator."
    converted = False
    action.Perform(Tuple())
    EXPECT_FALSE(converted)  # "Action must NOT convert its argument when performed."

class DestinationType:

class SourceType:
    def __to__(self) -> DestinationType:
        return DestinationType()

@testing.test
def CanConvertArgumentUsingNonConstTypeCastOperator(self):
    var s: SourceType = SourceType()
    var action: Action[() -> DestinationType] = Action[() -> DestinationType](Return(s))

@testing.test
def WorksInPointerReturningFunction(self):
    var a1: Action[() -> IntPointer] = ReturnNull()
    EXPECT_TRUE(a1.Perform(Tuple()) == None)
    var a2: Action[(Bool) -> ConstCharPointer] = ReturnNull()
    EXPECT_TRUE(a2.Perform(Tuple(true)) == None)

@testing.test
def WorksInSmartPointerReturningFunction(self):
    var a1: Action[() -> UniquePtr[ConstInt]] = ReturnNull()
    EXPECT_TRUE(a1.Perform(Tuple()) == None)
    var a2: Action[(String) -> SharedPtr[Int]] = ReturnNull()
    EXPECT_TRUE(a2.Perform(Tuple("foo")) == None)

@testing.test
def WorksForReference(self):
    var n: Int = 0
    var ret: Action[(Bool) -> ConstIntRef] = ReturnRef(n)
    EXPECT_EQ(&n, &ret.Perform(Tuple(true)))

@testing.test
def IsCovariant(self):
    var base: Base = Base()
    var derived: Derived = Derived()
    var a: Action[() -> BaseRef] = ReturnRef(base)
    EXPECT_EQ(&base, &a.Perform(Tuple()))
    a = ReturnRef(derived)
    EXPECT_EQ(&derived, &a.Perform(Tuple()))

def CanCallReturnRef[T: AnyType](t: T) -> Bool:
    return True

def CanCallReturnRef(u: Unused) -> Bool:
    return False

@testing.test
def WorksForNonTemporary(self):
    var scalar_value: Int = 123
    EXPECT_TRUE(CanCallReturnRef(scalar_value))
    var non_scalar_value: String = String("ABC")
    EXPECT_TRUE(CanCallReturnRef(non_scalar_value))
    var const_scalar_value: Int = 321
    EXPECT_TRUE(CanCallReturnRef(const_scalar_value))
    var const_non_scalar_value: String = String("CBA")
    EXPECT_TRUE(CanCallReturnRef(const_non_scalar_value))

@testing.test
def DoesNotWorkForTemporary(self):
    var scalar_value = lambda: 123
    EXPECT_FALSE(CanCallReturnRef(scalar_value()))
    var non_scalar_value = lambda: String("ABC")
    EXPECT_FALSE(CanCallReturnRef(non_scalar_value()))
    EXPECT_FALSE(CanCallReturnRef(static_cast[ConstInt](321)))
    var const_non_scalar_value = lambda: String("CBA")
    EXPECT_FALSE(CanCallReturnRef(const_non_scalar_value()))

@testing.test
def WorksForReference(self):
    var n: Int = 42
    var ret: Action[() -> ConstIntRef] = ReturnRefOfCopy(n)
    EXPECT_NE(&n, &ret.Perform(Tuple()))
    EXPECT_EQ(42, ret.Perform(Tuple()))
    n = 43
    EXPECT_NE(&n, &ret.Perform(Tuple()))
    EXPECT_EQ(42, ret.Perform(Tuple()))

@testing.test
def IsCovariant(self):
    var base: Base = Base()
    var derived: Derived = Derived()
    var a: Action[() -> BaseRef] = ReturnRefOfCopy(base)
    EXPECT_NE(&base, &a.Perform(Tuple()))
    a = ReturnRefOfCopy(derived)
    EXPECT_NE(&derived, &a.Perform(Tuple()))

@testing.test
def WorksForInitList(self):
    var ret: Action[() -> Int] = ReturnRoundRobin(List[Int](1, 2, 3))
    EXPECT_EQ(1, ret.Perform(Tuple()))
    EXPECT_EQ(2, ret.Perform(Tuple()))
    EXPECT_EQ(3, ret.Perform(Tuple()))
    EXPECT_EQ(1, ret.Perform(Tuple()))
    EXPECT_EQ(2, ret.Perform(Tuple()))
    EXPECT_EQ(3, ret.Perform(Tuple()))

@testing.test
def WorksForVector(self):
    var v: List[Float64] = List[Float64](4.4, 5.5, 6.6)
    var ret: Action[() -> Float64] = ReturnRoundRobin(v)
    EXPECT_EQ(4.4, ret.Perform(Tuple()))
    EXPECT_EQ(5.5, ret.Perform(Tuple()))
    EXPECT_EQ(6.6, ret.Perform(Tuple()))
    EXPECT_EQ(4.4, ret.Perform(Tuple()))
    EXPECT_EQ(5.5, ret.Perform(Tuple()))
    EXPECT_EQ(6.6, ret.Perform(Tuple()))

class MockClass:
    def __init__(self):

    def IntFunc(self, flag: Bool) -> Int:
        return self.mock_.IntFunc(flag)
    def Foo(self) -> MyNonDefaultConstructible:
        return self.mock_.Foo()
    def MakeUnique(self) -> UniquePtr[Int]:
        return self.mock_.MakeUnique()
    def MakeUniqueBase(self) -> UniquePtr[Base]:
        return self.mock_.MakeUniqueBase()
    def MakeVectorUnique(self) -> List[UniquePtr[Int]]:
        return self.mock_.MakeVectorUnique()
    def TakeUnique(self, arg0: UniquePtr[Int]) -> Int:
        return self.mock_.TakeUnique(arg0)
    def TakeUnique(self, arg0: ConstUniquePtrRef[Int], arg1: UniquePtr[Int]) -> Int:
        return self.mock_.TakeUnique(arg0, arg1)
    var mock_: testing.MockInterface

@testing.test
def ReturnsBuiltInDefaultValueByDefault(self):
    var mock: MockClass = MockClass()
    EXPECT_CALL(mock, IntFunc(_)).WillOnce(DoDefault())
    EXPECT_EQ(0, mock.IntFunc(true))

@testing.fixture
class DoDefaultDeathTest:

@testing.test
def DiesForUnknowType(self):
    var mock: MockClass = MockClass()
    EXPECT_CALL(mock, Foo()).WillRepeatedly(DoDefault())
# if GTEST_HAS_EXCEPTIONS
    EXPECT_ANY_THROW(mock.Foo())
# else
    EXPECT_DEATH_IF_SUPPORTED({
        mock.Foo()
    }, "")
# endif

def VoidFunc(flag: Bool):

@testing.test
def DiesIfUsedInCompositeAction(self):
    var mock: MockClass = MockClass()
    EXPECT_CALL(mock, IntFunc(_)).WillRepeatedly(DoAll(Invoke(VoidFunc), DoDefault()))
    EXPECT_DEATH_IF_SUPPORTED({
        mock.IntFunc(true)
    }, "")

@testing.test
def ReturnsUserSpecifiedPerTypeDefaultValueWhenThereIsOne(self):
    DefaultValue[Int].Set(1)
    var mock: MockClass = MockClass()
    EXPECT_CALL(mock, IntFunc(_)).WillOnce(DoDefault())
    EXPECT_EQ(1, mock.IntFunc(false))
    DefaultValue[Int].Clear()

@testing.test
def DoesWhatOnCallSpecifies(self):
    var mock: MockClass = MockClass()
    ON_CALL(mock, IntFunc(_)).WillByDefault(Return(2))
    EXPECT_CALL(mock, IntFunc(_)).WillOnce(DoDefault())
    EXPECT_EQ(2, mock.IntFunc(false))

@testing.test
def CannotBeUsedInOnCall(self):
    var mock: MockClass = MockClass()
    EXPECT_NONFATAL_FAILURE({
        ON_CALL(mock, IntFunc(_)).WillByDefault(DoDefault())
    }, "DoDefault() cannot be used in ON_CALL()")

@testing.test
def SetsTheNthPointee(self):
    type MyFunction = (Bool, Pointer[Int], Pointer[Char]) -> Void
    var a: Action[MyFunction] = SetArgPointee[1](2)
    var n: Int = 0
    var ch: Char = '\0'
    a.Perform(Tuple(true, Pointer.address_of(n), Pointer.address_of(ch)))
    EXPECT_EQ(2, n)
    EXPECT_EQ('\0', ch)
    a = SetArgPointee[2]('a')
    n = 0
    ch = '\0'
    a.Perform(Tuple(true, Pointer.address_of(n), Pointer.address_of(ch)))
    EXPECT_EQ(0, n)
    EXPECT_EQ('a', ch)

@testing.test
def AcceptsStringLiteral(self):
    type MyFunction = (Pointer[String], Pointer[ConstCharPointer]) -> Void
    var a: Action[MyFunction] = SetArgPointee[0]("hi")
    var str: String = String()
    var ptr: ConstCharPointer = None
    a.Perform(Tuple(Pointer.address_of(str), Pointer.address_of(ptr)))
    EXPECT_EQ("hi", str)
    EXPECT_TRUE(ptr == None)
    a = SetArgPointee[1]("world")
    str = ""
    a.Perform(Tuple(Pointer.address_of(str), Pointer.address_of(ptr)))
    EXPECT_EQ("", str)
    EXPECT_STREQ("world", ptr)

@testing.test
def AcceptsWideStringLiteral(self):
    type MyFunction = (Pointer[ConstWCharPointer]) -> Void
    var a: Action[MyFunction] = SetArgPointee[0](L"world")
    var ptr: ConstWCharPointer = None
    a.Perform(Tuple(Pointer.address_of(ptr)))
    EXPECT_STREQ(L"world", ptr)
# if GTEST_HAS_STD_WSTRING
    type MyStringFunction = (Pointer[WString]) -> Void
    var a2: Action[MyStringFunction] = SetArgPointee[0](L"world")
    var str: WString = WString("")
    a2.Perform(Tuple(Pointer.address_of(str)))
    EXPECT_EQ(L"world", str)
# endif

@testing.test
def AcceptsCharPointer(self):
    type MyFunction = (Bool, Pointer[String], Pointer[ConstCharPointer]) -> Void
    var hi: ConstCharPointer = "hi"
    var a: Action[MyFunction] = SetArgPointee[1](hi)
    var str: String = String()
    var ptr: ConstCharPointer = None
    a.Perform(Tuple(true, Pointer.address_of(str), Pointer.address_of(ptr)))
    EXPECT_EQ("hi", str)
    EXPECT_TRUE(ptr == None)
    var world_array: List[Char] = List[Char]('w', 'o', 'r', 'l', 'd', '\0')
    var world: CharPointer = Pointer.address_of(world_array[0])
    a = SetArgPointee[2](world)
    str = ""
    a.Perform(Tuple(true, Pointer.address_of(str), Pointer.address_of(ptr)))
    EXPECT_EQ("", str)
    EXPECT_EQ(world, ptr)

@testing.test
def AcceptsWideCharPointer(self):
    type MyFunction = (Bool, Pointer[ConstWCharPointer]) -> Void
    var hi: ConstWCharPointer = L"hi"
    var a: Action[MyFunction] = SetArgPointee[1](hi)
    var ptr: ConstWCharPointer = None
    a.Perform(Tuple(true, Pointer.address_of(ptr)))
    EXPECT_EQ(hi, ptr)
# if GTEST_HAS_STD_WSTRING
    type MyStringFunction = (Bool, Pointer[WString]) -> Void
    var world_array: List[WChar] = List[WChar](L'w', L'o', L'r', L'l', L'd', L'\0')
    var world: WCharPointer = Pointer.address_of(world_array[0])
    var a2: Action[MyStringFunction] = SetArgPointee[1](world)
    var str: WString = WString()
    a2.Perform(Tuple(true, Pointer.address_of(str)))
    EXPECT_EQ(world_array, str)
# endif

@testing.test
def SetsTheNthPointee(self):
    type MyFunction = (Bool, Pointer[Int], Pointer[Char]) -> Void
    var a: Action[MyFunction] = SetArgumentPointee[1](2)
    var n: Int = 0
    var ch: Char = '\0'
    a.Perform(Tuple(true, Pointer.address_of(n), Pointer.address_of(ch)))
    EXPECT_EQ(2, n)
    EXPECT_EQ('\0', ch)
    a = SetArgumentPointee[2]('a')
    n = 0
    ch = '\0'
    a.Perform(Tuple(true, Pointer.address_of(n), Pointer.address_of(ch)))
    EXPECT_EQ(0, n)
    EXPECT_EQ('a', ch)

def Nullary() -> Int:
    return 1

class NullaryFunctor:
    def __call__(self) -> Int:
        return 2

var g_done: Bool = False

def VoidNullary():
    g_done = True

class VoidNullaryFunctor:
    def __call__(self):
        g_done = True

def Short(n: Int16) -> Int16:
    return n

def Char(ch: Int8) -> Int8:
    return ch

def CharPtr(s: ConstCharPointer) -> ConstCharPointer:
    return s

def Unary(x: Int) -> Bool:
    return x < 0

def Binary(input: ConstCharPointer, n: Int16) -> ConstCharPointer:
    return input + n

def VoidBinary(x: Int, y: Int8):
    g_done = True

def Ternary(x: Int, y: Int8, z: Int16) -> Int:
    return x + y + z

def SumOf4(a: Int, b: Int, c: Int, d: Int) -> Int:
    return a + b + c + d

class Foo:
    def __init__(self):
        self.value_ = 123
    def Nullary(self) -> Int:
        return self.value_
    var value_: Int

@testing.test
def Function(self):
    var a: Action[(Int) -> Int] = InvokeWithoutArgs(Nullary)
    EXPECT_EQ(1, a.Perform(Tuple(2)))
    var a2: Action[(Int, Float64) -> Int] = InvokeWithoutArgs(Nullary)
    EXPECT_EQ(1, a2.Perform(Tuple(2, 3.5)))
    var a3: Action[(Int) -> Void] = InvokeWithoutArgs(VoidNullary)
    g_done = False
    a3.Perform(Tuple(1))
    EXPECT_TRUE(g_done)

@testing.test
def Functor(self):
    var a: Action[() -> Int] = InvokeWithoutArgs(NullaryFunctor())
    EXPECT_EQ(2, a.Perform(Tuple()))
    var a2: Action[(Int, Float64, Int8) -> Int] = InvokeWithoutArgs(NullaryFunctor())
    EXPECT_EQ(2, a2.Perform(Tuple(3, 3.5, 'a')))
    var a3: Action[() -> Void] = InvokeWithoutArgs(VoidNullaryFunctor())
    g_done = False
    a3.Perform(Tuple())
    EXPECT_TRUE(g_done)

@testing.test
def Method(self):
    var foo: Foo = Foo()
    var a: Action[(Bool, Int8) -> Int] = InvokeWithoutArgs(Pointer.address_of(foo), Foo.Nullary)
    EXPECT_EQ(123, a.Perform(Tuple(true, 'a')))

@testing.test
def PolymorphicAction(self):
    var a: Action[(Int) -> Void] = IgnoreResult(Return(5))
    a.Perform(Tuple(1))

def ReturnOne() -> Int:
    g_done = True
    return 1

@testing.test
def MonomorphicAction(self):
    g_done = False
    var a: Action[() -> Void] = IgnoreResult(Invoke(ReturnOne))
    a.Perform(Tuple())
    EXPECT_TRUE(g_done)

def ReturnMyNonDefaultConstructible(x: Float64) -> MyNonDefaultConstructible:
    g_done = True
    return MyNonDefaultConstructible(42)

@testing.test
def ActionReturningClass(self):
    g_done = False
    var a: Action[(Int) -> Void] = IgnoreResult(Invoke(ReturnMyNonDefaultConstructible))
    a.Perform(Tuple(2))
    EXPECT_TRUE(g_done)

@testing.test
def Int(self):
    var x: Int = 0
    var a: Action[(Int) -> Void] = Assign(Pointer.address_of(x), 5)
    a.Perform(Tuple(0))
    EXPECT_EQ(5, x)

@testing.test
def String(self):
    var x: String = String()
    var a: Action[() -> Void] = Assign(Pointer.address_of(x), "Hello, world")
    a.Perform(Tuple())
    EXPECT_EQ("Hello, world", x)

@testing.test
def CompatibleTypes(self):
    var x: Float64 = 0.0
    var a: Action[(Int) -> Void] = Assign(Pointer.address_of(x), 5)
    a.Perform(Tuple(0))
    EXPECT_DOUBLE_EQ(5.0, x)

@testing.test
def OneArg(self):
    var a: Action[(Float64, Int) -> Bool] = WithArgs[1](Invoke(Unary))
    EXPECT_TRUE(a.Perform(Tuple(1.5, -1)))
    EXPECT_FALSE(a.Perform(Tuple(1.5, 1)))

@testing.test
def TwoArgs(self):
    var a: Action[(ConstCharPointer, Float64, Int16) -> ConstCharPointer] = WithArgs[0, 2](Invoke(Binary))
    var s: List[Char] = List[Char]('H', 'e', 'l', 'l', 'o', '\0')
    EXPECT_EQ(Pointer.address_of(s[0]) + 2, a.Perform(Tuple(CharPtr(Pointer.address_of(s[0])), 0.5, Short(2))))

struct ConcatAll:
    def __call__(self) -> String:
        return String()
    def __call__[I: AnyVariadic](self, a: ConstCharPointer, i: I) -> String:
        return String(a) + self.__call__(i)

@testing.test
def TenArgs(self):
    var a: Action[(ConstCharPointer, ConstCharPointer, ConstCharPointer, ConstCharPointer) -> String] = WithArgs[0, 1, 2, 3, 2, 1, 0, 1, 2, 3](Invoke(ConcatAll()))
    EXPECT_EQ("0123210123", a.Perform(Tuple(CharPtr("0"), CharPtr("1"), CharPtr("2"), CharPtr("3"))))

class SubtractAction(ActionInterface[(Int, Int) -> Int]):
    def Perform(self, args: Tuple[Int, Int]) -> Int:
        return args[0] - args[1]

@testing.test
def NonInvokeAction(self):
    var a: Action[(String, Int, Int) -> Int] = WithArgs[2, 1](MakeAction(SubtractAction()))
    var dummy: Tuple[String, Int, Int] = Tuple(String("hi"), 2, 10)
    EXPECT_EQ(8, a.Perform(dummy))

@testing.test
def Identity(self):
    var a: Action[(Int, Int8, Int16) -> Int] = WithArgs[0, 1, 2](Invoke(Ternary))
    EXPECT_EQ(123, a.Perform(Tuple(100, Char(20), Short(3))))

@testing.test
def RepeatedArguments(self):
    var a: Action[(Bool, Int, Int) -> Int] = WithArgs[1, 1, 1, 1](Invoke(SumOf4))
    EXPECT_EQ(4, a.Perform(Tuple(false, 1, 10)))

@testing.test
def ReversedArgumentOrder(self):
    var a: Action[(Int16, ConstCharPointer) -> ConstCharPointer] = WithArgs[1, 0](Invoke(Binary))
    var s: List[Char] = List[Char]('H', 'e', 'l', 'l', 'o', '\0')
    EXPECT_EQ(Pointer.address_of(s[0]) + 2, a.Perform(Tuple(Short(2), CharPtr(Pointer.address_of(s[0])))))

@testing.test
def ArgsOfCompatibleTypes(self):
    var a: Action[(Int16, Int8, Float64, Int8) -> Int64] = WithArgs[0, 1, 3](Invoke(Ternary))
    EXPECT_EQ(123, a.Perform(Tuple(Short(100), Char(20), 5.6, Char(3))))

@testing.test
def VoidAction(self):
    var a: Action[(Float64, Int8, Int) -> Void] = WithArgs[2, 1](Invoke(VoidBinary))
    g_done = False
    a.Perform(Tuple(1.5, 'a', 3))
    EXPECT_TRUE(g_done)

@testing.test
def ReturnReference(self):
    var aa: Action[(IntRef, VoidPointer) -> IntRef] = WithArgs[0](lambda a: a)
    var i: Int = 0
    var res: IntRef = aa.Perform(Tuple(i, None))
    EXPECT_EQ(&i, &res)

@testing.test
def InnerActionWithConversion(self):
    var inner: Action[() -> DerivedPointer] = lambda: None
    var a: Action[(Float64) -> BasePointer] = testing.WithoutArgs(inner)
    EXPECT_EQ(None, a.Perform(Tuple(1.1)))

# if !GTEST_OS_WINDOWS_MOBILE
@testing.fixture
class SetErrnoAndReturnTest(testing.Test):
    def SetUp(self):
        errno = 0
    def TearDown(self):
        errno = 0

@testing.test
def Int(self):
    var a: Action[() -> Int] = SetErrnoAndReturn(ENOTTY, -5)
    EXPECT_EQ(-5, a.Perform(Tuple()))
    EXPECT_EQ(ENOTTY, errno)

@testing.test
def Ptr(self):
    var x: Int = 0
    var a: Action[() -> IntPointer] = SetErrnoAndReturn(ENOTTY, Pointer.address_of(x))
    EXPECT_EQ(Pointer.address_of(x), a.Perform(Tuple()))
    EXPECT_EQ(ENOTTY, errno)

@testing.test
def CompatibleTypes(self):
    var a: Action[() -> Float64] = SetErrnoAndReturn(EINVAL, 5)
    EXPECT_DOUBLE_EQ(5.0, a.Perform(Tuple()))
    EXPECT_EQ(EINVAL, errno)
# endif

@testing.test
def IsCopyable(self):
    var s1: String = String("Hi")
    var s2: String = String("Hello")
    var ref_wrapper: RefWrapper[String] = ByRef(s1)
    var r1: StringRef = ref_wrapper
    EXPECT_EQ(&s1, &r1)
    ref_wrapper = ByRef(s2)
    var r2: StringRef = ref_wrapper
    EXPECT_EQ(&s2, &r2)
    var ref_wrapper1: RefWrapper[String] = ByRef(s1)
    ref_wrapper = ref_wrapper1
    var r3: StringRef = ref_wrapper
    EXPECT_EQ(&s1, &r3)

@testing.test
def ConstValue(self):
    var n: Int = 0
    var const_ref: ConstIntRef = ByRef(n)
    EXPECT_EQ(&n, &const_ref)

@testing.test
def NonConstValue(self):
    var n: Int = 0
    var ref: IntRef = ByRef(n)
    EXPECT_EQ(&n, &ref)
    var const_ref: ConstIntRef = ByRef(n)
    EXPECT_EQ(&n, &const_ref)

@testing.test
def ExplicitType(self):
    var n: Int = 0
    var r1: ConstIntRef = ByRef[ConstInt](n)
    EXPECT_EQ(&n, &r1)
    var d: Derived = Derived()
    var r2: DerivedRef = ByRef[Derived](d)
    EXPECT_EQ(&d, &r2)
    var r3: ConstDerivedRef = ByRef[ConstDerived](d)
    EXPECT_EQ(&d, &r3)
    var r4: BaseRef = ByRef[Base](d)
    EXPECT_EQ(&d, &r4)
    var r5: ConstBaseRef = ByRef[ConstBase](d)
    EXPECT_EQ(&d, &r5)

@testing.test
def PrintsCorrectly(self):
    var n: Int = 42
    var expected: StringStream = StringStream()
    var actual: StringStream = StringStream()
    testing.internal.UniversalPrinter[ConstIntRef].Print(n, Pointer.address_of(expected))
    testing.internal.UniversalPrint(ByRef(n), Pointer.address_of(actual))
    EXPECT_EQ(expected.str(), actual.str())

struct UnaryConstructorClass:
    def __init__(self, v: Int):
        self.value = v
    var value: Int

@testing.test
def Unary(self):
    var a: Action[() -> Pointer[UnaryConstructorClass]] = ReturnNew[UnaryConstructorClass](4000)
    var c: Pointer[UnaryConstructorClass] = a.Perform(Tuple())
    EXPECT_EQ(4000, c.value)
    del c

@testing.test
def UnaryWorksWhenMockMethodHasArgs(self):
    var a: Action[(Bool, Int) -> Pointer[UnaryConstructorClass]] = ReturnNew[UnaryConstructorClass](4000)
    var c: Pointer[UnaryConstructorClass] = a.Perform(Tuple(false, 5))
    EXPECT_EQ(4000, c.value)
    del c

@testing.test
def UnaryWorksWhenMockMethodReturnsPointerToConst(self):
    var a: Action[() -> Pointer[ConstUnaryConstructorClass]] = ReturnNew[UnaryConstructorClass](4000)
    var c: Pointer[ConstUnaryConstructorClass] = a.Perform(Tuple())
    EXPECT_EQ(4000, c.value)
    del c

class TenArgConstructorClass:
    def __init__(self, a1: Int, a2: Int, a3: Int, a4: Int, a5: Int, a6: Int, a7: Int, a8: Int, a9: Int, a10: Int):
        self.value_ = a1 + a2 + a3 + a4 + a5 + a6 + a7 + a8 + a9 + a10
    var value_: Int

@testing.test
def ConstructorThatTakes10Arguments(self):
    var a: Action[() -> Pointer[TenArgConstructorClass]] = ReturnNew[TenArgConstructorClass](1000000000, 200000000, 30000000, 4000000, 500000, 60000, 7000, 800, 90, 0)
    var c: Pointer[TenArgConstructorClass] = a.Perform(Tuple())
    EXPECT_EQ(1234567890, c.value_)
    del c

def UniquePtrSource() -> UniquePtr[Int]:
    return UniquePtr[Int](Int(19))

def VectorUniquePtrSource() -> List[UniquePtr[Int]]:
    var out: List[UniquePtr[Int]] = List[UniquePtr[Int]]()
    out.emplace_back(UniquePtr[Int](Int(7)))
    return out

@testing.test
def CanReturnMoveOnlyValue_Return(self):
    var mock: MockClass = MockClass()
    var i: UniquePtr[Int] = UniquePtr[Int](Int(19))
    EXPECT_CALL(mock, MakeUnique()).WillOnce(Return(ByMove(move i)))
    EXPECT_CALL(mock, MakeVectorUnique()).WillOnce(Return(ByMove(VectorUniquePtrSource())))
    var d: DerivedPointer = Derived()
    EXPECT_CALL(mock, MakeUniqueBase()).WillOnce(Return(ByMove(UniquePtr[Derived](d))))
    var result1: UniquePtr[Int] = mock.MakeUnique()
    EXPECT_EQ(19, *result1)
    var vresult: List[UniquePtr[Int]] = mock.MakeVectorUnique()
    EXPECT_EQ(1, vresult.size())
    EXPECT_NE(None, vresult[0])
    EXPECT_EQ(7, *vresult[0])
    var result2: UniquePtr[Base] = mock.MakeUniqueBase()
    EXPECT_EQ(d, result2.get())

@testing.test
def CanReturnMoveOnlyValue_DoAllReturn(self):
    var mock_function: testing.MockFunction[() -> Void] = testing.MockFunction[() -> Void]()
    var mock: MockClass = MockClass()
    var i: UniquePtr[Int] = UniquePtr[Int](Int(19))
    EXPECT_CALL(mock_function, Call())
    EXPECT_CALL(mock, MakeUnique()).WillOnce(DoAll(
        InvokeWithoutArgs(Pointer.address_of(mock_function), testing.MockFunction[() -> Void].Call),
        Return(ByMove(move i))))
    var result1: UniquePtr[Int] = mock.MakeUnique()
    EXPECT_EQ(19, *result1)

@testing.test
def CanReturnMoveOnlyValue_Invoke(self):
    var mock: MockClass = MockClass()
    DefaultValue[UniquePtr[Int]].SetFactory(lambda: UniquePtr[Int](Int(42)))
    EXPECT_EQ(42, *mock.MakeUnique())
    EXPECT_CALL(mock, MakeUnique()).WillRepeatedly(Invoke(UniquePtrSource))
    EXPECT_CALL(mock, MakeVectorUnique()).WillRepeatedly(Invoke(VectorUniquePtrSource))
    var result1: UniquePtr[Int] = mock.MakeUnique()
    EXPECT_EQ(19, *result1)
    var result2: UniquePtr[Int] = mock.MakeUnique()
    EXPECT_EQ(19, *result2)
    EXPECT_NE(result1, result2)
    var vresult: List[UniquePtr[Int]] = mock.MakeVectorUnique()
    EXPECT_EQ(1, vresult.size())
    EXPECT_NE(None, vresult[0])
    EXPECT_EQ(7, *vresult[0])

@testing.test
def CanTakeMoveOnlyValue(self):
    var mock: MockClass = MockClass()
    var make = lambda i: UniquePtr[Int](Int(i))
    EXPECT_CALL(mock, TakeUnique(_)).WillRepeatedly(lambda i: *i)
    EXPECT_CALL(mock, TakeUnique(testing.Pointee(7))).WillOnce(Return(-7)).RetiresOnSaturation()
    EXPECT_CALL(mock, TakeUnique(testing.IsNull())).WillOnce(Return(-1)).RetiresOnSaturation()
    EXPECT_EQ(5, mock.TakeUnique(make(5)))
    EXPECT_EQ(-7, mock.TakeUnique(make(7)))
    EXPECT_EQ(7, mock.TakeUnique(make(7)))
    EXPECT_EQ(7, mock.TakeUnique(make(7)))
    EXPECT_EQ(-1, mock.TakeUnique(UniquePtr[Int]()))
    var lvalue: UniquePtr[Int] = make(6)
    EXPECT_CALL(mock, TakeUnique(_, _)).WillOnce(lambda i, j: *i * *j)
    EXPECT_EQ(42, mock.TakeUnique(lvalue, make(7)))
    var saved: UniquePtr[Int] = UniquePtr[Int]()
    EXPECT_CALL(mock, TakeUnique(_)).WillOnce(lambda i: (saved = move i, 0))
    EXPECT_EQ(0, mock.TakeUnique(make(42)))
    EXPECT_EQ(42, *saved)

def Add(val: Int, ref: IntRef, ptr: Pointer[Int]) -> Int:
    var result: Int = val + ref + *ptr
    ref = 42
    *ptr = 43
    return result

def Deref(ptr: UniquePtr[Int]) -> Int:
    return *ptr

struct Double:
    def __call__[T: AnyType](self, t: T) -> T:
        return 2 * t

def UniqueInt(i: Int) -> UniquePtr[Int]:
    return UniquePtr[Int](Int(i))

@testing.test
def ActionFromFunction(self):
    var a: Action[(Int, IntRef, Pointer[Int]) -> Int] = Pointer.address_of(Add)
    var x: Int = 1
    var y: Int = 2
    var z: Int = 3
    EXPECT_EQ(6, a.Perform(Tuple(x, y, Pointer.address_of(z))))
    EXPECT_EQ(42, y)
    EXPECT_EQ(43, z)
    var a1: Action[(UniquePtr[Int]) -> Int] = Pointer.address_of(Deref)
    EXPECT_EQ(7, a1.Perform(Tuple(UniqueInt(7))))

@testing.test
def ActionFromLambda(self):
    var a1: Action[(Bool, Int) -> Int] = lambda b, i: b ? i : 0
    EXPECT_EQ(5, a1.Perform(Tuple(true, 5)))
    EXPECT_EQ(0, a1.Perform(Tuple(false, 5)))
    var saved: UniquePtr[Int] = UniquePtr[Int]()
    var a2: Action[(UniquePtr[Int]) -> Void] = lambda p: (saved = move p)
    a2.Perform(Tuple(UniqueInt(5)))
    EXPECT_EQ(5, *saved)

@testing.test
def PolymorphicFunctor(self):
    var ai: Action[(Int) -> Int] = Double()
    EXPECT_EQ(2, ai.Perform(Tuple(1)))
    var ad: Action[(Float64) -> Float64] = Double()
    EXPECT_EQ(3.0, ad.Perform(Tuple(1.5)))

@testing.test
def TypeConversion(self):
    var a1: Action[(Int) -> Bool] = lambda i: i > 1
    var a2: Action[(Bool) -> Int] = Action[(Bool) -> Int](a1)
    EXPECT_EQ(1, a1.Perform(Tuple(42)))
    EXPECT_EQ(0, a2.Perform(Tuple(42)))
    var s1: Action[(String) -> Bool] = lambda s: not s.empty()
    var s2: Action[(ConstCharPointer) -> Int] = Action[(ConstCharPointer) -> Int](s1)
    EXPECT_EQ(0, s2.Perform(Tuple("")))
    EXPECT_EQ(1, s2.Perform(Tuple("hello")))
    var x1: Action[(String) -> Bool] = lambda u: 42
    var x2: Action[(String) -> Bool] = lambda: 42
    EXPECT_TRUE(x1.Perform(Tuple("hello")))
    EXPECT_TRUE(x2.Perform(Tuple("hello")))
    var f: Function[() -> Int] = lambda: 7
    var d: Action[(Int) -> Int] = f
    f = None
    EXPECT_EQ(7, d.Perform(Tuple(1)))
    Action[(Int) -> Void](None)

@testing.test
def UnusedArguments(self):
    var a: Action[(Int, Float64, Float64) -> Int] = lambda i, u1, u2: 2 * i
    var dummy: Tuple[Int, Float64, Float64] = Tuple(3, 7.3, 9.44)
    EXPECT_EQ(6, a.Perform(dummy))

@testing.test
def ReturningActions(self):
    var a: Action[(UniquePtr[Int]) -> Int] = Return(1)
    EXPECT_EQ(1, a.Perform(Tuple(None)))
    a = testing.WithoutArgs(lambda: 7)
    EXPECT_EQ(7, a.Perform(Tuple(None)))
    var a2: Action[(UniquePtr[Int], Pointer[Int]) -> Void] = testing.SetArgPointee[1](3)
    var x: Int = 0
    a2.Perform(Tuple(None, Pointer.address_of(x)))
    EXPECT_EQ(x, 3)

def ReturnArity() -> Int:
    return __type_size[args_type]

@testing.test
def LargeArity(self):
    EXPECT_EQ(1, testing.Action[(Int) -> Int](ReturnArity()).Perform(Tuple(0)))
    EXPECT_EQ(10, testing.Action[(Int, Int, Int, Int, Int, Int, Int, Int, Int, Int) -> Int](ReturnArity()).Perform(Tuple(0, 1, 2, 3, 4, 5, 6, 7, 8, 9)))
    EXPECT_EQ(20, testing.Action[(Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int, Int) -> Int](ReturnArity()).Perform(Tuple(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19)))