#define DEFINE_STANDARD_ALLOC

typedef int Standard_Integer;
typedef double Standard_Real;
typedef bool Standard_Boolean;
typedef const char* Standard_CString;
typedef unsigned int Standard_ExtCharacter;

class Standard_OStream {};
class Standard_SStream {};
class TCollection_AsciiString
{
public:
  TCollection_AsciiString() {}
  TCollection_AsciiString(Standard_CString) {}
};
class Standard_Dump
{
public:
  static TCollection_AsciiString Text(const Standard_SStream&) { return TCollection_AsciiString(); }
};

#define Standard_OutOfRange_Raise_if(CONDITION, MESSAGE)
#define Standard_ConstructionError_Raise_if(CONDITION, MESSAGE)
#define Standard_DomainError_Raise_if(CONDITION, MESSAGE)
#define Standard_NullValue_Raise_if(CONDITION, MESSAGE)
#define Standard_NoSuchObject_Raise_if(CONDITION, MESSAGE)
#define Standard_DivideByZero_Raise_if(CONDITION, MESSAGE)

#define DEFINE_STANDARD_EXCEPTION(C1, C2) class C1 {};
#define No_Exception

class Standard_ConstructionError
{
public:
  Standard_ConstructionError(Standard_CString) {}
};

#define OCCT_DUMP_VECTOR_CLASS(...)
#define OCCT_INIT_VECTOR_CLASS(...)
#define OCCT_DUMP_FIELD_VALUE_NUMERICAL(...)
#define OCCT_DUMP_CLASS_BEGIN(...)
#define OCCT_DUMP_FIELD_VALUES_DUMPED(...)
#define OCCT_DUMP_BASE_CLASS(...)
#define OCCT_INIT_FIELD_VALUE_INTEGER(...)
#define OCCT_INIT_FIELD_VALUE_REAL(...)

template <typename T> class NCollection_Mat4 {};


constexpr double RealSmall() { return 1e-16; }
constexpr double Epsilon(double) { return 1e-16; }
constexpr bool IsOdd(int theValue) { return (theValue % 2) != 0; }
constexpr bool IsEven(int theValue) { return (theValue % 2) == 0; }

class Precision
{
public:
  static constexpr double Confusion() { return 1e-7; }
  static constexpr double Angular() { return 1e-12; }
};
