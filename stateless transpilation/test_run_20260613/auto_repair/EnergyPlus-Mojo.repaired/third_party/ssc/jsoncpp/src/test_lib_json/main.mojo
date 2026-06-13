# // This file is a faithful 1:1 translation of the C++ file to Mojo.
# // No refactoring or renaming has been performed.

# // #pragma GCC diagnostic push
# // #pragma GCC diagnostic ignored "-Wdeprecated-declarations"
# // #elif defined(_MSC_VER)
# // #pragma warning(disable : 4996)
# // #endif

from fuzz import LLVMFuzzerTestOneInput
from jsontest import *
import json
from json import Json

# // using CharReaderPtr = unique_ptr<Json::CharReader>;
alias CharReaderPtr = Json.CharReader

# // #define kint32max Json::Value::maxInt
# // #define kint32min Json::Value::minInt
# // #define kuint32max Json::Value::maxUInt
# // #define kint64max Json::Value::maxInt64
# // #define kint64min Json::Value::minInt64
# // #define kuint64max Json::Value::maxUInt64

let kint32max: Int = Json.Value.maxInt
let kint32min: Int = Json.Value.minInt
let kuint32max: UInt = Json.Value.maxUInt
let kint64max: Int64 = Json.Value.maxInt64
let kint64min: Int64 = Json.Value.minInt64
let kuint64max: UInt64 = Json.Value.maxUInt64

# // static float kfint32max = float(kint32max);
let kfint32max: F32 = F32(kint32max)

# // static float kfuint32max = float(kuint32max);
let kfuint32max: F32 = F32(kuint32max)

# // #if !defined(JSON_USE_INT64_DOUBLE_CONVERSION)
# // static double uint64ToDouble(Json::UInt64 value) {
# //   return static_cast<double>(value);
# // }
# // #else  // if !defined(JSON_USE_INT64_DOUBLE_CONVERSION)
# // static double uint64ToDouble(Json::UInt64 value) {
# //   return static_cast<double>(Json::Int64(value / 2)) * 2.0 +
# //          static_cast<double>(Json::Int64(value & 1));
# // }
# // #endif // if !defined(JSON_USE_INT64_DOUBLE_CONVERSION)

def uint64ToDouble(value: Json.UInt64) -> F64:
    # // #if !defined(JSON_USE_INT64_DOUBLE_CONVERSION)
    return F64(value)
    # // #else  // if !defined(JSON_USE_INT64_DOUBLE_CONVERSION)
    # //   return static_cast<double>(Json::Int64(value / 2)) * 2.0 +
    # //          static_cast<double>(Json::Int64(value & 1));
    # // #endif // if !defined(JSON_USE_INT64_DOUBLE_CONVERSION)


# // static deque<JsonTest::TestCaseFactory> local_;
var local_: List[JsonTest.TestCaseFactory] = List[JsonTest.TestCaseFactory]()

# // #define JSONTEST_FIXTURE_LOCAL(FixtureType, name)                              \
# //   JSONTEST_FIXTURE_V2(FixtureType, name, local_)

# // We manually expand each JSONTEST_FIXTURE_LOCAL below.

# // struct ValueTest : JsonTest::TestCase {
struct ValueTest(JsonTest.TestCase):
    # //   Json::Value null_;
    var null_: Json.Value = Json.Value()
    # //   Json::Value emptyArray_{Json::arrayValue};
    var emptyArray_: Json.Value = Json.Value(Json.arrayValue)
    # //   Json::Value emptyObject_{Json::objectValue};
    var emptyObject_: Json.Value = Json.Value(Json.objectValue)
    # //   Json::Value integer_{123456789};
    var integer_: Json.Value = Json.Value(123456789)
    # //   Json::Value unsignedInteger_{34567890};
    var unsignedInteger_: Json.Value = Json.Value(34567890)
    # //   Json::Value smallUnsignedInteger_{Json::Value::UInt(Json::Value::maxInt)};
    var smallUnsignedInteger_: Json.Value = Json.Value(Json.UInt(Json.Value.maxInt))
    # //   Json::Value real_{1234.56789};
    var real_: Json.Value = Json.Value(1234.56789)
    # //   Json::Value float_{0.00390625f};
    var float_: Json.Value = Json.Value(0.00390625)
    # //   Json::Value array1_;
    var array1_: Json.Value = Json.Value()
    # //   Json::Value object1_;
    var object1_: Json.Value = Json.Value()
    # //   Json::Value emptyString_{""};
    var emptyString_: Json.Value = Json.Value("")
    # //   Json::Value string1_{"a"};
    var string1_: Json.Value = Json.Value("a")
    # //   Json::Value string_{"sometext with space"};
    var string_: Json.Value = Json.Value("sometext with space")
    # //   Json::Value true_{true};
    var true_: Json.Value = Json.Value(true)
    # //   Json::Value false_{false};
    var false_: Json.Value = Json.Value(false)

    # //   ValueTest() {
    def __init__(inout self):
        # //     array1_.append(1234);
        self.array1_.append(1234)
        # //     object1_["id"] = 1234;
        self.object1_["id"] = 1234

    # //   struct IsCheck {
    struct IsCheck:
        # //     IsCheck();
        # //     bool isObject_{false};
        var isObject_: Bool = false
        # //     bool isArray_{false};
        var isArray_: Bool = false
        # //     bool isBool_{false};
        var isBool_: Bool = false
        # //     bool isString_{false};
        var isString_: Bool = false
        # //     bool isNull_{false};
        var isNull_: Bool = false
        # //     bool isInt_{false};
        var isInt_: Bool = false
        # //     bool isInt64_{false};
        var isInt64_: Bool = false
        # //     bool isUInt_{false};
        var isUInt_: Bool = false
        # //     bool isUInt64_{false};
        var isUInt64_: Bool = false
        # //     bool isIntegral_{false};
        var isIntegral_: Bool = false
        # //     bool isDouble_{false};
        var isDouble_: Bool = false
        # //     bool isNumeric_{false};
        var isNumeric_: Bool = false

    # //   void checkConstMemberCount(const Json::Value& value,
    # //                              unsigned int expectedCount);
    def checkConstMemberCount(self, value: Json.Value, expectedCount: UInt):
        # //     unsigned int count = 0;
        var count: UInt = 0
        # //     Json::Value::const_iterator itEnd = value.end();
        var itEnd: Json.Value.const_iterator = value.end()
        # //     for (Json::Value::const_iterator it = value.begin(); it != itEnd; ++it) {
        var it: Json.Value.const_iterator = value.begin()
        while it != itEnd:
            # //       ++count;
            count += 1
            it += 1
        # //     }
        # //     JSONTEST_ASSERT_EQUAL(expectedCount, count) << "Json::Value::const_iterator";
        JSONTEST_ASSERT_EQUAL(expectedCount, count)

    # //   void checkMemberCount(Json::Value& value, unsigned int expectedCount);
    def checkMemberCount(self, value: Json.Value, expectedCount: UInt):
        # //     JSONTEST_ASSERT_EQUAL(expectedCount, value.size());
        JSONTEST_ASSERT_EQUAL(expectedCount, value.size())
        # //     unsigned int count = 0;
        var count: UInt = 0
        # //     Json::Value::iterator itEnd = value.end();
        var itEnd: Json.Value.iterator = value.end()
        # //     for (Json::Value::iterator it = value.begin(); it != itEnd; ++it) {
        var it: Json.Value.iterator = value.begin()
        while it != itEnd:
            # //       ++count;
            count += 1
            it += 1
        # //     }
        # //     JSONTEST_ASSERT_EQUAL(expectedCount, count) << "Json::Value::iterator";
        JSONTEST_ASSERT_EQUAL(expectedCount, count)
        # //     JSONTEST_ASSERT_PRED(checkConstMemberCount(value, expectedCount));
        self.checkConstMemberCount(value, expectedCount)

    # //   void checkIs(const Json::Value& value, IsCheck& check );
    def checkIs(self, value: Json.Value, check: IsCheck):
        # //     JSONTEST_ASSERT_EQUAL(check.isObject_, value.isObject());
        JSONTEST_ASSERT_EQUAL(check.isObject_, value.isObject())
        # //     JSONTEST_ASSERT_EQUAL(check.isArray_, value.isArray());
        JSONTEST_ASSERT_EQUAL(check.isArray_, value.isArray())
        # //     JSONTEST_ASSERT_EQUAL(check.isBool_, value.isBool());
        JSONTEST_ASSERT_EQUAL(check.isBool_, value.isBool())
        # //     JSONTEST_ASSERT_EQUAL(check.isDouble_, value.isDouble());
        JSONTEST_ASSERT_EQUAL(check.isDouble_, value.isDouble())
        # //     JSONTEST_ASSERT_EQUAL(check.isInt_, value.isInt());
        JSONTEST_ASSERT_EQUAL(check.isInt_, value.isInt())
        # //     JSONTEST_ASSERT_EQUAL(check.isUInt_, value.isUInt());
        JSONTEST_ASSERT_EQUAL(check.isUInt_, value.isUInt())
        # //     JSONTEST_ASSERT_EQUAL(check.isIntegral_, value.isIntegral());
        JSONTEST_ASSERT_EQUAL(check.isIntegral_, value.isIntegral())
        # //     JSONTEST_ASSERT_EQUAL(check.isNumeric_, value.isNumeric());
        JSONTEST_ASSERT_EQUAL(check.isNumeric_, value.isNumeric())
        # //     JSONTEST_ASSERT_EQUAL(check.isString_, value.isString());
        JSONTEST_ASSERT_EQUAL(check.isString_, value.isString())
        # //     JSONTEST_ASSERT_EQUAL(check.isNull_, value.isNull());
        JSONTEST_ASSERT_EQUAL(check.isNull_, value.isNull())
        # // #ifdef JSON_HAS_INT64
        # //     JSONTEST_ASSERT_EQUAL(check.isInt64_, value.isInt64());
        # //     JSONTEST_ASSERT_EQUAL(check.isUInt64_, value.isUInt64());
        # // #else
        # //     JSONTEST_ASSERT_EQUAL(false, value.isInt64());
        # //     JSONTEST_ASSERT_EQUAL(false, value.isUInt64());
        # // #endif
        JSONTEST_ASSERT_EQUAL(check.isInt64_, value.isInt64())
        JSONTEST_ASSERT_EQUAL(check.isUInt64_, value.isUInt64())

    # //   void checkIsLess(const Json::Value& x, const Json::Value& y);
    def checkIsLess(self, x: Json.Value, y: Json.Value):
        # //     JSONTEST_ASSERT(x < y);
        JSONTEST_ASSERT(x < y)
        # //     JSONTEST_ASSERT(y > x);
        JSONTEST_ASSERT(y > x)
        # //     JSONTEST_ASSERT(x <= y);
        JSONTEST_ASSERT(x <= y)
        # //     JSONTEST_ASSERT(y >= x);
        JSONTEST_ASSERT(y >= x)
        # //     JSONTEST_ASSERT(!(x == y));
        JSONTEST_ASSERT(not (x == y))
        # //     JSONTEST_ASSERT(!(y == x));
        JSONTEST_ASSERT(not (y == x))
        # //     JSONTEST_ASSERT(!(x >= y));
        JSONTEST_ASSERT(not (x >= y))
        # //     JSONTEST_ASSERT(!(y <= x));
        JSONTEST_ASSERT(not (y <= x))
        # //     JSONTEST_ASSERT(!(x > y));
        JSONTEST_ASSERT(not (x > y))
        # //     JSONTEST_ASSERT(!(y < x));
        JSONTEST_ASSERT(not (y < x))
        # //     JSONTEST_ASSERT(x.compare(y) < 0);
        JSONTEST_ASSERT(x.compare(y) < 0)
        # //     JSONTEST_ASSERT(y.compare(x) >= 0);
        JSONTEST_ASSERT(y.compare(x) >= 0)

    # //   void checkIsEqual(const Json::Value& x, const Json::Value& y);
    def checkIsEqual(self, x: Json.Value, y: Json.Value):
        # //     JSONTEST_ASSERT(x == y);
        JSONTEST_ASSERT(x == y)
        # //     JSONTEST_ASSERT(y == x);
        JSONTEST_ASSERT(y == x)
        # //     JSONTEST_ASSERT(x <= y);
        JSONTEST_ASSERT(x <= y)
        # //     JSONTEST_ASSERT(y <= x);
        JSONTEST_ASSERT(y <= x)
        # //     JSONTEST_ASSERT(x >= y);
        JSONTEST_ASSERT(x >= y)
        # //     JSONTEST_ASSERT(y >= x);
        JSONTEST_ASSERT(y >= x)
        # //     JSONTEST_ASSERT(!(x < y));
        JSONTEST_ASSERT(not (x < y))
        # //     JSONTEST_ASSERT(!(y < x));
        JSONTEST_ASSERT(not (y < x))
        # //     JSONTEST_ASSERT(!(x > y));
        JSONTEST_ASSERT(not (x > y))
        # //     JSONTEST_ASSERT(!(y > x));
        JSONTEST_ASSERT(not (y > x))
        # //     JSONTEST_ASSERT(x.compare(y) == 0);
        JSONTEST_ASSERT(x.compare(y) == 0)
        # //     JSONTEST_ASSERT(y.compare(x) == 0);
        JSONTEST_ASSERT(y.compare(x) == 0)

    # //   static Json::String normalizeFloatingPointStr(const Json::String& s);
    @staticmethod
    def normalizeFloatingPointStr(s: Json.String) -> Json.String:
        # //     auto index = s.find_last_of("eE");
        var index: Int = s.find_last_of("eE")
        # //     if (index == s.npos)
        if index == s.npos:
            # //       return s;
            return s
        # //     size_t signWidth = (s[index + 1] == '+' || s[index + 1] == '-') ? 1 : 0;
        var signWidth: Int = 1 if (s[index + 1] == '+' or s[index + 1] == '-') else 0
        # //     auto exponentStartIndex = index + 1 + signWidth;
        var exponentStartIndex: Int = index + 1 + signWidth
        # //     Json::String normalized = s.substr(0, exponentStartIndex);
        var normalized: Json.String = s.substr(0, exponentStartIndex)
        # //     auto indexDigit = s.find_first_not_of('0', exponentStartIndex);
        var indexDigit: Int = s.find_first_not_of('0', exponentStartIndex)
        # //     Json::String exponent = "0";
        var exponent: Json.String = "0"
        # //     if (indexDigit != s.npos) { // nonzero exponent
        if indexDigit != s.npos:
            # //       exponent = s.substr(indexDigit);
            exponent = s.substr(indexDigit)
        # //     }
        # //     return normalized + exponent;
        return normalized + exponent

# // Now expand each JSONTEST_FIXTURE_LOCAL manually.

# // JSONTEST_FIXTURE_LOCAL(ValueTest, checkNormalizeFloatingPointStr)
struct checkNormalizeFloatingPointStr(ValueTest):
    def runTestCase(self):
        # //   struct TestData {
        # //     string in;
        # //     string out;
        # //   } const testData[] = {
        # //       {"0.0", "0.0"},
        # //       {"0e0", "0e0"},
        # //       {"1234.0", "1234.0"},
        # //       {"1234.0e0", "1234.0e0"},
        # //       {"1234.0e-1", "1234.0e-1"},
        # //       {"1234.0e+0", "1234.0e+0"},
        # //       {"1234.0e+001", "1234.0e+1"},
        # //       {"1234e-1", "1234e-1"},
        # //       {"1234e+000", "1234e+0"},
        # //       {"1234e+001", "1234e+1"},
        # //       {"1234e10", "1234e10"},
        # //       {"1234e010", "1234e10"},
        # //       {"1234e+010", "1234e+10"},
        # //       {"1234e-010", "1234e-10"},
        # //       {"1234e+100", "1234e+100"},
        # //       {"1234e-100", "1234e-100"},
        # //   };
        var testData: List[Dict[String, String]] = List[Dict[String, String]](
            {"in": "0.0", "out": "0.0"},
            {"in": "0e0", "out": "0e0"},
            {"in": "1234.0", "out": "1234.0"},
            {"in": "1234.0e0", "out": "1234.0e0"},
            {"in": "1234.0e-1", "out": "1234.0e-1"},
            {"in": "1234.0e+0", "out": "1234.0e+0"},
            {"in": "1234.0e+001", "out": "1234.0e+1"},
            {"in": "1234e-1", "out": "1234e-1"},
            {"in": "1234e+000", "out": "1234e+0"},
            {"in": "1234e+001", "out": "1234e+1"},
            {"in": "1234e10", "out": "1234e10"},
            {"in": "1234e010", "out": "1234e10"},
            {"in": "1234e+010", "out": "1234e+10"},
            {"in": "1234e-010", "out": "1234e-10"},
            {"in": "1234e+100", "out": "1234e+100"},
            {"in": "1234e-100", "out": "1234e-100"},
        )
        # //   for (const auto& td : testData) {
        for td in testData:
            # //     JSONTEST_ASSERT_STRING_EQUAL(normalizeFloatingPointStr(td.in), td.out);
            JSONTEST_ASSERT_STRING_EQUAL(self.normalizeFloatingPointStr(td["in"]), td["out"])
local_.append(JsonTest.TestCaseFactory(checkNormalizeFloatingPointStr()))

# // JSONTEST_FIXTURE_LOCAL(ValueTest, memberCount)
struct memberCount(ValueTest):
    def runTestCase(self):
        # //   JSONTEST_ASSERT_PRED(checkMemberCount(emptyArray_, 0));
        self.checkMemberCount(self.emptyArray_, 0)
        # //   JSONTEST_ASSERT_PRED(checkMemberCount(emptyObject_, 0));
        self.checkMemberCount(self.emptyObject_, 0)
        # //   JSONTEST_ASSERT_PRED(checkMemberCount(array1_, 1));
        self.checkMemberCount(self.array1_, 1)
        # //   JSONTEST_ASSERT_PRED(checkMemberCount(object1_, 1));
        self.checkMemberCount(self.object1_, 1)
        # //   JSONTEST_ASSERT_PRED(checkMemberCount(null_, 0));
        self.checkMemberCount(self.null_, 0)
        # //   JSONTEST_ASSERT_PRED(checkMemberCount(integer_, 0));
        self.checkMemberCount(self.integer_, 0)
        # //   JSONTEST_ASSERT_PRED(checkMemberCount(unsignedInteger_, 0));
        self.checkMemberCount(self.unsignedInteger_, 0)
        # //   JSONTEST_ASSERT_PRED(checkMemberCount(smallUnsignedInteger_, 0));
        self.checkMemberCount(self.smallUnsignedInteger_, 0)
        # //   JSONTEST_ASSERT_PRED(checkMemberCount(real_, 0));
        self.checkMemberCount(self.real_, 0)
        # //   JSONTEST_ASSERT_PRED(checkMemberCount(emptyString_, 0));
        self.checkMemberCount(self.emptyString_, 0)
        # //   JSONTEST_ASSERT_PRED(checkMemberCount(string_, 0));
        self.checkMemberCount(self.string_, 0)
        # //   JSONTEST_ASSERT_PRED(checkMemberCount(true_, 0));
        self.checkMemberCount(self.true_, 0)
        # //   JSONTEST_ASSERT_PRED(checkMemberCount(false_, 0));
        self.checkMemberCount(self.false_, 0)
        # //   JSONTEST_ASSERT_PRED(checkMemberCount(string1_, 0));
        self.checkMemberCount(self.string1_, 0)
        # //   JSONTEST_ASSERT_PRED(checkMemberCount(float_, 0));
        self.checkMemberCount(self.float_, 0)
local_.append(JsonTest.TestCaseFactory(memberCount()))

# // JSONTEST_FIXTURE_LOCAL(ValueTest, objects)
struct objects(ValueTest):
    def runTestCase(self):
        # //   IsCheck checks;
        var checks: ValueTest.IsCheck = ValueTest.IsCheck()
        # //   checks.isObject_ = true;
        checks.isObject_ = true
        # //   JSONTEST_ASSERT_PRED(checkIs(emptyObject_, checks));
        self.checkIs(self.emptyObject_, checks)
        # //   JSONTEST_ASSERT_PRED(checkIs(object1_, checks));
        self.checkIs(self.object1_, checks)
        # //   JSONTEST_ASSERT_EQUAL(Json::objectValue, emptyObject_.type());
        JSONTEST_ASSERT_EQUAL(Json.objectValue, self.emptyObject_.type())
        # //   JSONTEST_ASSERT(emptyObject_.isConvertibleTo(Json::nullValue));
        JSONTEST_ASSERT(self.emptyObject_.isConvertibleTo(Json.nullValue))
        # //   JSONTEST_ASSERT(!object1_.isConvertibleTo(Json::nullValue));
        JSONTEST_ASSERT(not self.object1_.isConvertibleTo(Json.nullValue))
        # //   JSONTEST_ASSERT(emptyObject_.isConvertibleTo(Json::objectValue));
        JSONTEST_ASSERT(self.emptyObject_.isConvertibleTo(Json.objectValue))
        # //   JSONTEST_ASSERT(!emptyObject_.isConvertibleTo(Json::arrayValue));
        JSONTEST_ASSERT(not self.emptyObject_.isConvertibleTo(Json.arrayValue))
        # //   JSONTEST_ASSERT(!emptyObject_.isConvertibleTo(Json::intValue));
        JSONTEST_ASSERT(not self.emptyObject_.isConvertibleTo(Json.intValue))
        # //   JSONTEST_ASSERT(!emptyObject_.isConvertibleTo(Json::uintValue));
        JSONTEST_ASSERT(not self.emptyObject_.isConvertibleTo(Json.uintValue))
        # //   JSONTEST_ASSERT(!emptyObject_.isConvertibleTo(Json::realValue));
        JSONTEST_ASSERT(not self.emptyObject_.isConvertibleTo(Json.realValue))
        # //   JSONTEST_ASSERT(!emptyObject_.isConvertibleTo(Json::booleanValue));
        JSONTEST_ASSERT(not self.emptyObject_.isConvertibleTo(Json.booleanValue))
        # //   JSONTEST_ASSERT(!emptyObject_.isConvertibleTo(Json::stringValue));
        JSONTEST_ASSERT(not self.emptyObject_.isConvertibleTo(Json.stringValue))
        # //   const Json::Value& constObject = object1_;
        var constObject: Json.Value = self.object1_
        # //   JSONTEST_ASSERT_EQUAL(Json::Value(1234), constObject["id"]);
        JSONTEST_ASSERT_EQUAL(Json.Value(1234), constObject["id"])
        # //   JSONTEST_ASSERT_EQUAL(Json::Value(), constObject["unknown id"]);
        JSONTEST_ASSERT_EQUAL(Json.Value(), constObject["unknown id"])
        # //   const char idKey[] = "id";
        var idKey: String = "id"
        # //   const Json::Value* foundId = object1_.find(idKey, idKey + strlen(idKey));
        var foundId: Optional[Json.Value] = self.object1_.find(idKey, idKey + len(idKey))
        # //   JSONTEST_ASSERT(foundId != None);
        JSONTEST_ASSERT(foundId is not None)
        # //   JSONTEST_ASSERT_EQUAL(Json::Value(1234), *foundId);
        JSONTEST_ASSERT_EQUAL(Json.Value(1234), foundId.value())
        # //   const char unknownIdKey[] = "unknown id";
        var unknownIdKey: String = "unknown id"
        # //   const Json::Value* foundUnknownId =
        # //       object1_.find(unknownIdKey, unknownIdKey + strlen(unknownIdKey));
        var foundUnknownId: Optional[Json.Value] = self.object1_.find(unknownIdKey, unknownIdKey + len(unknownIdKey))
        # //   JSONTEST_ASSERT_EQUAL(None, foundUnknownId);
        JSONTEST_ASSERT_EQUAL(None, foundUnknownId)
        # //   const char yetAnotherIdKey[] = "yet another id";
        var yetAnotherIdKey: String = "yet another id"
        # //   const Json::Value* foundYetAnotherId =
        # //       object1_.find(yetAnotherIdKey, yetAnotherIdKey + strlen(yetAnotherIdKey));
        var foundYetAnotherId: Optional[Json.Value] = self.object1_.find(yetAnotherIdKey, yetAnotherIdKey + len(yetAnotherIdKey))
        # //   JSONTEST_ASSERT_EQUAL(None, foundYetAnotherId);
        JSONTEST_ASSERT_EQUAL(None, foundYetAnotherId)
        # //   Json::Value* demandedYetAnotherId = object1_.demand(
        # //       yetAnotherIdKey, yetAnotherIdKey + strlen(yetAnotherIdKey));
        var demandedYetAnotherId: Optional[Json.Value] = self.object1_.demand(yetAnotherIdKey, yetAnotherIdKey + len(yetAnotherIdKey))
        # //   JSONTEST_ASSERT(demandedYetAnotherId != None);
        JSONTEST_ASSERT(demandedYetAnotherId is not None)
        # //   *demandedYetAnotherId = "baz";
        demandedYetAnotherId.value() = "baz"
        # //   JSONTEST_ASSERT_EQUAL(Json::Value("baz"), object1_["yet another id"]);
        JSONTEST_ASSERT_EQUAL(Json.Value("baz"), self.object1_["yet another id"])
        # //   JSONTEST_ASSERT_EQUAL(Json::Value(1234), object1_["id"]);
        JSONTEST_ASSERT_EQUAL(Json.Value(1234), self.object1_["id"])
        # //   JSONTEST_ASSERT_EQUAL(Json::Value(), object1_["unknown id"]);
        JSONTEST_ASSERT_EQUAL(Json.Value(), self.object1_["unknown id"])
        # //   object1_["some other id"] = "foo";
        self.object1_["some other id"] = "foo"
        # //   JSONTEST_ASSERT_EQUAL(Json::Value("foo"), object1_["some other id"]);
        JSONTEST_ASSERT_EQUAL(Json.Value("foo"), self.object1_["some other id"])
        # //   JSONTEST_ASSERT_EQUAL(Json::Value("foo"), object1_["some other id"]);
        JSONTEST_ASSERT_EQUAL(Json.Value("foo"), self.object1_["some other id"])
        # //   Json::Value got;
        var got: Json.Value = Json.Value()
        # //   bool did;
        var did: Bool
        # //   did = object1_.removeMember("some other id", &got);
        did = self.object1_.removeMember("some other id", got)
        # //   JSONTEST_ASSERT_EQUAL(Json::Value("foo"), got);
        JSONTEST_ASSERT_EQUAL(Json.Value("foo"), got)
        # //   JSONTEST_ASSERT_EQUAL(true, did);
        JSONTEST_ASSERT_EQUAL(true, did)
        # //   got = Json::Value("bar");
        got = Json.Value("bar")
        # //   did = object1_.removeMember("some other id", &got);
        did = self.object1_.removeMember("some other id", got)
        # //   JSONTEST_ASSERT_EQUAL(Json::Value("bar"), got);
        JSONTEST_ASSERT_EQUAL(Json.Value("bar"), got)
        # //   JSONTEST_ASSERT_EQUAL(false, did);
        JSONTEST_ASSERT_EQUAL(false, did)
        # //   object1_["some other id"] = "foo";
        self.object1_["some other id"] = "foo"
        # //   Json::Value* gotPtr = None;
        var gotPtr: Optional[Json.Value] = None
        # //   did = object1_.removeMember("some other id", gotPtr);
        did = self.object1_.removeMember("some other id", gotPtr)
        # //   JSONTEST_ASSERT_EQUAL(None, gotPtr);
        JSONTEST_ASSERT_EQUAL(None, gotPtr)
        # //   JSONTEST_ASSERT_EQUAL(true, did);
        JSONTEST_ASSERT_EQUAL(true, did)
        # //   object1_["some other id"] = "foo";
        self.object1_["some other id"] = "foo"
        # //   const Json::String key("some other id");
        var key: Json.String = "some other id"
        # //   did = object1_.removeMember(key, &got);
        did = self.object1_.removeMember(key, got)
        # //   JSONTEST_ASSERT_EQUAL(Json::Value("foo"), got);
        JSONTEST_ASSERT_EQUAL(Json.Value("foo"), got)
        # //   JSONTEST_ASSERT_EQUAL(true, did);
        JSONTEST_ASSERT_EQUAL(true, did)
        # //   got = Json::Value("bar");
        got = Json.Value("bar")
        # //   did = object1_.removeMember(key, &got);
        did = self.object1_.removeMember(key, got)
        # //   JSONTEST_ASSERT_EQUAL(Json::Value("bar"), got);
        JSONTEST_ASSERT_EQUAL(Json.Value("bar"), got)
        # //   JSONTEST_ASSERT_EQUAL(false, did);
        JSONTEST_ASSERT_EQUAL(false, did)
        # //   object1_["some other id"] = "foo";
        self.object1_["some other id"] = "foo"
        # //   object1_.removeMember(key);
        self.object1_.removeMember(key)
        # //   JSONTEST_ASSERT_EQUAL(Json::nullValue, object1_[key]);
        JSONTEST_ASSERT_EQUAL(Json.nullValue, self.object1_[key])
local_.append(JsonTest.TestCaseFactory(objects()))

# // JSONTEST_FIXTURE_LOCAL(ValueTest, arrays)
struct arrays(ValueTest):
    def runTestCase(self):
        # //   const unsigned int index0 = 0;
        var index0: UInt = 0
        # //   IsCheck checks;
        var checks: ValueTest.IsCheck = ValueTest.IsCheck()
        # //   checks.isArray_ = true;
        checks.isArray_ = true
        # //   JSONTEST_ASSERT_PRED(checkIs(emptyArray_, checks));
        self.checkIs(self.emptyArray_, checks)
        # //   JSONTEST_ASSERT_PRED(checkIs(array1_, checks));
        self.checkIs(self.array1_, checks)
        # //   JSONTEST_ASSERT_EQUAL(Json::arrayValue, array1_.type());
        JSONTEST_ASSERT_EQUAL(Json.arrayValue, self.array1_.type())
        # //   JSONTEST_ASSERT(emptyArray_.isConvertibleTo(Json::nullValue));
        JSONTEST_ASSERT(self.emptyArray_.isConvertibleTo(Json.nullValue))
        # //   JSONTEST_ASSERT(!array1_.isConvertibleTo(Json::nullValue));
        JSONTEST_ASSERT(not self.array1_.isConvertibleTo(Json.nullValue))
        # //   JSONTEST_ASSERT(emptyArray_.isConvertibleTo(Json::arrayValue));
        JSONTEST_ASSERT(self.emptyArray_.isConvertibleTo(Json.arrayValue))
        # //   JSONTEST_ASSERT(!emptyArray_.isConvertibleTo(Json::objectValue));
        JSONTEST_ASSERT(not self.emptyArray_.isConvertibleTo(Json.objectValue))
        # //   JSONTEST_ASSERT(!emptyArray_.isConvertibleTo(Json::intValue));
        JSONTEST_ASSERT(not self.emptyArray_.isConvertibleTo(Json.intValue))
        # //   JSONTEST_ASSERT(!emptyArray_.isConvertibleTo(Json::uintValue));
        JSONTEST_ASSERT(not self.emptyArray_.isConvertibleTo(Json.uintValue))
        # //   JSONTEST_ASSERT(!emptyArray_.isConvertibleTo(Json::realValue));
        JSONTEST_ASSERT(not self.emptyArray_.isConvertibleTo(Json.realValue))
        # //   JSONTEST_ASSERT(!emptyArray_.isConvertibleTo(Json::booleanValue));
        JSONTEST_ASSERT(not self.emptyArray_.isConvertibleTo(Json.booleanValue))
        # //   JSONTEST_ASSERT(!emptyArray_.isConvertibleTo(Json::stringValue));
        JSONTEST_ASSERT(not self.emptyArray_.isConvertibleTo(Json.stringValue))
        # //   const Json::Value& constArray = array1_;
        var constArray: Json.Value = self.array1_
        # //   JSONTEST_ASSERT_EQUAL(Json::Value(1234), constArray[index0]);
        JSONTEST_ASSERT_EQUAL(Json.Value(1234), constArray[index0])
        # //   JSONTEST_ASSERT_EQUAL(Json::Value(1234), constArray[0]);
        JSONTEST_ASSERT_EQUAL(Json.Value(1234), constArray[0])
        # //   JSONTEST_ASSERT_EQUAL(Json::Value(1234), array1_[index0]);
        JSONTEST_ASSERT_EQUAL(Json.Value(1234), self.array1_[index0])
        # //   JSONTEST_ASSERT_EQUAL(Json::Value(1234), array1_[0]);
        JSONTEST_ASSERT_EQUAL(Json.Value(1234), self.array1_[0])
        # //   array1_[2] = Json::Value(17);
        self.array1_[2] = Json.Value(17)
        # //   JSONTEST_ASSERT_EQUAL(Json::Value(), array1_[1]);
        JSONTEST_ASSERT_EQUAL(Json.Value(), self.array1_[1])
        # //   JSONTEST_ASSERT_EQUAL(Json::Value(17), array1_[2]);
        JSONTEST_ASSERT_EQUAL(Json.Value(17), self.array1_[2])
        # //   Json::Value got;
        var got: Json.Value = Json.Value()
        # //   JSONTEST_ASSERT_EQUAL(true, array1_.removeIndex(2, &got));
        JSONTEST_ASSERT_EQUAL(true, self.array1_.removeIndex(2, got))
        # //   JSONTEST_ASSERT_EQUAL(Json::Value(17), got);
        JSONTEST_ASSERT_EQUAL(Json.Value(17), got)
        # //   JSONTEST_ASSERT_EQUAL(false, array1_.removeIndex(2, &got));
        JSONTEST_ASSERT_EQUAL(false, self.array1_.removeIndex(2, got))
local_.append(JsonTest.TestCaseFactory(arrays()))

# // JSONTEST_FIXTURE_LOCAL(ValueTest, resizeArray)
struct resizeArray(ValueTest):
    def runTestCase(self):
        # //   Json::Value array;
        var array: Json.Value = Json.Value()
        # //   {
        # //     for (Json::ArrayIndex i = 0; i < 10; i++)
        for i in range(10):
            # //       array[i] = i;
            array[i] = i
        # //     JSONTEST_ASSERT_EQUAL(array.size(), 10);
        JSONTEST_ASSERT_EQUAL(array.size(), 10)
        # //     array.resize(15);
        array.resize(15)
        # //     JSONTEST_ASSERT_EQUAL(array.size(), 15);
        JSONTEST_ASSERT_EQUAL(array.size(), 15)
        # //     array.resize(5);
        array.resize(5)
        # //     JSONTEST_ASSERT_EQUAL(array.size(), 5);
        JSONTEST_ASSERT_EQUAL(array.size(), 5)
        # //     array.resize(0);
        array.resize(0)
        # //     JSONTEST_ASSERT_EQUAL(array.size(), 0);
        JSONTEST_ASSERT_EQUAL(array.size(), 0)
        # //   }
        # //   {
        # //     for (Json::ArrayIndex i = 0; i < 10; i++)
        for i in range(10):
            # //       array[i] = i;
            array[i] = i
        # //     JSONTEST_ASSERT_EQUAL(array.size(), 10);
        JSONTEST_ASSERT_EQUAL(array.size(), 10)
        # //     array.clear();
        array.clear()
        # //     JSONTEST_ASSERT_EQUAL(array.size(), 0);
        JSONTEST_ASSERT_EQUAL(array.size(), 0)
        # //   }
local_.append(JsonTest.TestCaseFactory(resizeArray()))

# // JSONTEST_FIXTURE_LOCAL(ValueTest, getArrayValue)
struct getArrayValue(ValueTest):
    def runTestCase(self):
        # //   Json::Value array;
        var array: Json.Value = Json.Value()
        # //   for (Json::ArrayIndex i = 0; i < 5; i++)
        for i in range(5):
            # //     array[i] = i;
            array[i] = i
        # //   JSONTEST_ASSERT_EQUAL(array.size(), 5);
        JSONTEST_ASSERT_EQUAL(array.size(), 5)
        # //   const Json::Value defaultValue(10);
        var defaultValue: Json.Value = Json.Value(10)
        # //   Json::ArrayIndex index = 0;
        var index: UInt = 0
        # //   for (; index <= 4; index++)
        while index <= 4:
            # //     JSONTEST_ASSERT_EQUAL(index, array.get(index, defaultValue).asInt());
            JSONTEST_ASSERT_EQUAL(index, array.get(index, defaultValue).asInt())
            index += 1
        # //   index = 4;
        index = 4
        # //   JSONTEST_ASSERT_EQUAL(array.isValidIndex(index), true);
        JSONTEST_ASSERT_EQUAL(array.isValidIndex(index), true)
        # //   index = 5;
        index = 5
        # //   JSONTEST_ASSERT_EQUAL(array.isValidIndex(index), false);
        JSONTEST_ASSERT_EQUAL(array.isValidIndex(index), false)
        # //   JSONTEST_ASSERT_EQUAL(defaultValue, array.get(index, defaultValue));
        JSONTEST_ASSERT_EQUAL(defaultValue, array.get(index, defaultValue))
        # //   JSONTEST_ASSERT_EQUAL(array.isValidIndex(index), false);
        JSONTEST_ASSERT_EQUAL(array.isValidIndex(index), false)
local_.append(JsonTest.TestCaseFactory(getArrayValue()))

# // JSONTEST_FIXTURE_LOCAL(ValueTest, arrayIssue252)
struct arrayIssue252(ValueTest):
    def runTestCase(self):
        # //   int count = 5;
        var count: Int = 5
        # //   Json::Value root;
        var root: Json.Value = Json.Value()
        # //   Json::Value item;
        var item: Json.Value = Json.Value()
        # //   root["array"] = Json::Value::nullSingleton();
        root["array"] = Json.Value.nullSingleton()
        # //   for (int i = 0; i < count; i++) {
        for i in range(count):
            # //     item["a"] = i;
            item["a"] = i
            # //     item["b"] = i;
            item["b"] = i
            # //     root["array"][i] = item;
            root["array"][i] = item
        # //   }
local_.append(JsonTest.TestCaseFactory(arrayIssue252()))

# // JSONTEST_FIXTURE_LOCAL(ValueTest, arrayInsertAtRandomIndex)
struct arrayInsertAtRandomIndex(ValueTest):
    def runTestCase(self):
        # //   Json::Value array;
        var array: Json.Value = Json.Value()
        # //   const Json::Value str0("index2");
        var str0: Json.Value = Json.Value("index2")
        # //   const Json::Value str1("index3");
        var str1: Json.Value = Json.Value("index3")
        # //   array.append("index0"); // append rvalue
        array.append("index0")
        # //   array.append("index1");
        array.append("index1")
        # //   array.append(str0); // append lvalue
        array.append(str0)
        # //   vector<Json::Value*> vec; // storage value address for checking
        var vec: List[Optional[Json.Value]] = List[Optional[Json.Value]]()
        # //   for (Json::ArrayIndex i = 0; i < 3; i++) {
        for i in range(3):
            # //     vec.push_back(&array[i]);
            vec.push_back(array[i])
        # //   }
        # //   JSONTEST_ASSERT_EQUAL(Json::Value("index0"), array[0]); // check append
        JSONTEST_ASSERT_EQUAL(Json.Value("index0"), array[0])
        # //   JSONTEST_ASSERT_EQUAL(Json::Value("index1"), array[1]);
        JSONTEST_ASSERT_EQUAL(Json.Value("index1"), array[1])
        # //   JSONTEST_ASSERT_EQUAL(Json::Value("index2"), array[2]);
        JSONTEST_ASSERT_EQUAL(Json.Value("index2"), array[2])
        # //   JSONTEST_ASSERT(array.insert(0, str1));
        JSONTEST_ASSERT(array.insert(0, str1))
        # //   JSONTEST_ASSERT_EQUAL(Json::Value("index3"), array[0]);
        JSONTEST_ASSERT_EQUAL(Json.Value("index3"), array[0])
        # //   JSONTEST_ASSERT_EQUAL(Json::Value("index0"), array[1]);
        JSONTEST_ASSERT_EQUAL(Json.Value("index0"), array[1])
        # //   JSONTEST_ASSERT_EQUAL(Json::Value("index1"), array[2]);
        JSONTEST_ASSERT_EQUAL(Json.Value("index1"), array[2])
        # //   JSONTEST_ASSERT_EQUAL(Json::Value("index2"), array[3]);
        JSONTEST_ASSERT_EQUAL(Json.Value("index2"), array[3])
        for i in range(3):
            # //     JSONTEST_ASSERT_EQUAL(vec[i], &array[i]);
            JSONTEST_ASSERT_EQUAL(vec[i], array[i])
        # //   vec.push_back(&array[3]);
        vec.push_back(array[3])
        # //   JSONTEST_ASSERT(array.insert(2, "index4"));
        JSONTEST_ASSERT(array.insert(2, "index4"))
        # //   JSONTEST_ASSERT_EQUAL(Json::Value("index3"), array[0]);
        JSONTEST_ASSERT_EQUAL(Json.Value("index3"), array[0])
        # //   JSONTEST_ASSERT_EQUAL(Json::Value("index0"), array[1]);
        JSONTEST_ASSERT_EQUAL(Json.Value("index0"), array[1])
        # //   JSONTEST_ASSERT_EQUAL(Json::Value("index4"), array[2]);
        JSONTEST_ASSERT_EQUAL(Json.Value("index4"), array[2])
        # //   JSONTEST_ASSERT_EQUAL(Json::Value("index1"), array[3]);
        JSONTEST_ASSERT_EQUAL(Json.Value("index1"), array[3])
        # //   JSONTEST_ASSERT_EQUAL(Json::Value("index2"), array[4]);
        JSONTEST_ASSERT_EQUAL(Json.Value("index2"), array[4])
        # //   for (Json::ArrayIndex i = 0; i < 4; i++) {
        for i in range(4):
            # //     JSONTEST_ASSERT_EQUAL(vec[i], &array[i]);
            JSONTEST_ASSERT_EQUAL(vec[i], array[i])
        # //   vec.push_back(&array[4]);
        vec.push_back(array[4])
        # //   JSONTEST_ASSERT(array.insert(5, "index5"));
        JSONTEST_ASSERT(array.insert(5, "index5"))
        # //   JSONTEST_ASSERT_EQUAL(Json::Value("index3"), array[0]);
        JSONTEST_ASSERT_EQUAL(Json.Value("index3"), array[0])
        # //   JSONTEST_ASSERT_EQUAL(Json::Value("index0"), array[1]);
        JSONTEST_ASSERT_EQUAL(Json.Value("index0"), array[1])
        # //   JSONTEST_ASSERT_EQUAL(Json::Value("index4"), array[2]);
        JSONTEST_ASSERT_EQUAL(Json.Value("index4"), array[2])
        # //   JSONTEST_ASSERT_EQUAL(Json::Value("index1"), array[3]);
        JSONTEST_ASSERT_EQUAL(Json.Value("index1"), array[3])
        # //   JSONTEST_ASSERT_EQUAL(Json::Value("index2"), array[4]);
        JSONTEST_ASSERT_EQUAL(Json.Value("index2"), array[4])
        # //   JSONTEST_ASSERT_EQUAL(Json::Value("index5"), array[5]);
        JSONTEST_ASSERT_EQUAL(Json.Value("index5"), array[5])
        for i in range(5):
            # //     JSONTEST_ASSERT_EQUAL(vec[i], &array[i]);
            JSONTEST_ASSERT_EQUAL(vec[i], array[i])
        # //   vec.push_back(&array[5]);
        vec.push_back(array[5])
        # //   JSONTEST_ASSERT(!array.insert(10, "index10"));
        JSONTEST_ASSERT(not array.insert(10, "index10"))
local_.append(JsonTest.TestCaseFactory(arrayInsertAtRandomIndex()))

# // JSONTEST_FIXTURE_LOCAL(ValueTest, null)
struct null(ValueTest):
    def runTestCase(self):
        # //   JSONTEST_ASSERT_EQUAL(Json::nullValue, null_.type());
        JSONTEST_ASSERT_EQUAL(Json.nullValue, self.null_.type())
        # //   IsCheck checks;
        var checks: ValueTest.IsCheck = ValueTest.IsCheck()
        # //   checks.isNull_ = true;
        checks.isNull_ = true
        # //   JSONTEST_ASSERT_PRED(checkIs(null_, checks));
        self.checkIs(self.null_, checks)
        # //   JSONTEST_ASSERT(null_.isConvertibleTo(Json::nullValue));
        JSONTEST_ASSERT(self.null_.isConvertibleTo(Json.nullValue))
        # //   JSONTEST_ASSERT(null_.isConvertibleTo(Json::intValue));
        JSONTEST_ASSERT(self.null_.isConvertibleTo(Json.intValue))
        # //   JSONTEST_ASSERT(null_.isConvertibleTo(Json::uintValue));
        JSONTEST_ASSERT(self.null_.isConvertibleTo(Json.uintValue))
        # //   JSONTEST_ASSERT(null_.isConvertibleTo(Json::realValue));
        JSONTEST_ASSERT(self.null_.isConvertibleTo(Json.realValue))
        # //   JSONTEST_ASSERT(null_.isConvertibleTo(Json::booleanValue));
        JSONTEST_ASSERT(self.null_.isConvertibleTo(Json.booleanValue))
        # //   JSONTEST_ASSERT(null_.isConvertibleTo(Json::stringValue));
        JSONTEST_ASSERT(self.null_.isConvertibleTo(Json.stringValue))
        # //   JSONTEST_ASSERT(null_.isConvertibleTo(Json::arrayValue));
        JSONTEST_ASSERT(self.null_.isConvertibleTo(Json.arrayValue))
        # //   JSONTEST_ASSERT(null_.isConvertibleTo(Json::objectValue));
        JSONTEST_ASSERT(self.null_.isConvertibleTo(Json.objectValue))
        # //   JSONTEST_ASSERT_EQUAL(Json::Int(0), null_.asInt());
        JSONTEST_ASSERT_EQUAL(Json.Int(0), self.null_.asInt())
        # //   JSONTEST_ASSERT_EQUAL(Json::LargestInt(0), null_.asLargestInt());
        JSONTEST_ASSERT_EQUAL(Json.LargestInt(0), self.null_.asLargestInt())
        # //   JSONTEST_ASSERT_EQUAL(Json::UInt(0), null_.asUInt());
        JSONTEST_ASSERT_EQUAL(Json.UInt(0), self.null_.asUInt())
        # //   JSONTEST_ASSERT_EQUAL(Json::LargestUInt(0), null_.asLargestUInt());
        JSONTEST_ASSERT_EQUAL(Json.LargestUInt(0), self.null_.asLargestUInt())
        # //   JSONTEST_ASSERT_EQUAL(0.0, null_.asDouble());
        JSONTEST_ASSERT_EQUAL(0.0, self.null_.asDouble())
        # //   JSONTEST_ASSERT_EQUAL(0.0, null_.asFloat());
        JSONTEST_ASSERT_EQUAL(0.0, self.null_.asFloat())
        # //   JSONTEST_ASSERT_STRING_EQUAL("", null_.asString());
        JSONTEST_ASSERT_STRING_EQUAL("", self.null_.asString())
        # //   JSONTEST_ASSERT_EQUAL(Json::Value::nullSingleton(), null_);
        JSONTEST_ASSERT_EQUAL(Json.Value.nullSingleton(), self.null_)
        # //   JSONTEST_ASSERT_EQUAL(null_, false);
        JSONTEST_ASSERT_EQUAL(self.null_, false)
        # //   JSONTEST_ASSERT_EQUAL(object1_, true);
        JSONTEST_ASSERT_EQUAL(self.object1_, true)
        # //   JSONTEST_ASSERT_EQUAL(!null_, true);
        JSONTEST_ASSERT_EQUAL(not self.null_, true)
        # //   JSONTEST_ASSERT_EQUAL(!object1_, false);
        JSONTEST_ASSERT_EQUAL(not self.object1_, false)
local_.append(JsonTest.TestCaseFactory(null()))

# // JSONTEST_FIXTURE_LOCAL(ValueTest, strings)
struct strings(ValueTest):
    def runTestCase(self):
        # //   JSONTEST_ASSERT_EQUAL(Json::stringValue, string1_.type());
        JSONTEST_ASSERT_EQUAL(Json.stringValue, self.string1_.type())
        # //   IsCheck checks;
        var checks: ValueTest.IsCheck = ValueTest.IsCheck()
        # //   checks.isString_ = true;
        checks.isString_ = true
        # //   JSONTEST_ASSERT_PRED(checkIs(emptyString_, checks));
        self.checkIs(self.emptyString_, checks)
        # //   JSONTEST_ASSERT_PRED(checkIs(string_, checks));
        self.checkIs(self.string_, checks)
        # //   JSONTEST_ASSERT_PRED(checkIs(string1_, checks));
        self.checkIs(self.string1_, checks)
        # //   JSONTEST_ASSERT(emptyString_.isConvertibleTo(Json::nullValue));
        JSONTEST_ASSERT(self.emptyString_.isConvertibleTo(Json.nullValue))
        # //   JSONTEST_ASSERT(!string1_.isConvertibleTo(Json::nullValue));
        JSONTEST_ASSERT(not self.string1_.isConvertibleTo(Json.nullValue))
        # //   JSONTEST_ASSERT(string1_.isConvertibleTo(Json::stringValue));
        JSONTEST_ASSERT(self.string1_.isConvertibleTo(Json.stringValue))
        # //   JSONTEST_ASSERT(!string1_.isConvertibleTo(Json::objectValue));
        JSONTEST_ASSERT(not self.string1_.isConvertibleTo(Json.objectValue))
        # //   JSONTEST_ASSERT(!string1_.isConvertibleTo(Json::arrayValue));
        JSONTEST_ASSERT(not self.string1_.isConvertibleTo(Json.arrayValue))
        # //   JSONTEST_ASSERT(!string1_.isConvertibleTo(Json::intValue));
        JSONTEST_ASSERT(not self.string1_.isConvertibleTo(Json.intValue))
        # //   JSONTEST_ASSERT(!string1_.isConvertibleTo(Json::uintValue));
        JSONTEST_ASSERT(not self.string1_.isConvertibleTo(Json.uintValue))
        # //   JSONTEST_ASSERT(!string1_.isConvertibleTo(Json::realValue));
        JSONTEST_ASSERT(not self.string1_.isConvertibleTo(Json.realValue))
        # //   JSONTEST_ASSERT_STRING_EQUAL("a", string1_.asString());
        JSONTEST_ASSERT_STRING_EQUAL("a", self.string1_.asString())
        # //   JSONTEST_ASSERT_STRING_EQUAL("a", string1_.asCString());
        JSONTEST_ASSERT_STRING_EQUAL("a", self.string1_.asCString())
local_.append(JsonTest.TestCaseFactory(strings()))

# // JSONTEST_FIXTURE_LOCAL(ValueTest, bools)
struct bools(ValueTest):
    def runTestCase(self):
        # //   JSONTEST_ASSERT_EQUAL(Json::booleanValue, false_.type());
        JSONTEST_ASSERT_EQUAL(Json.booleanValue, self.false_.type())
        # //   IsCheck checks;
        var checks: ValueTest.IsCheck = ValueTest.IsCheck()
        # //   checks.isBool_ = true;
        checks.isBool_ = true
        # //   JSONTEST_ASSERT_PRED(checkIs(false_, checks));
        self.checkIs(self.false_, checks)
        # //   JSONTEST_ASSERT_PRED(checkIs(true_, checks));
        self.checkIs(self.true_, checks)
        # //   JSONTEST_ASSERT(false_.isConvertibleTo(Json::nullValue));
        JSONTEST_ASSERT(self.false_.isConvertibleTo(Json.nullValue))
        # //   JSONTEST_ASSERT(!true_.isConvertibleTo(Json::nullValue));
        JSONTEST_ASSERT(not self.true_.isConvertibleTo(Json.nullValue))
        # //   JSONTEST_ASSERT(true_.isConvertibleTo(Json::intValue));
        JSONTEST_ASSERT(self.true_.isConvertibleTo(Json.intValue))
        # //   JSONTEST_ASSERT(true_.isConvertibleTo(Json::uintValue));
        JSONTEST_ASSERT(self.true_.isConvertibleTo(Json.uintValue))
        # //   JSONTEST_ASSERT(true_.isConvertibleTo(Json::realValue));
        JSONTEST_ASSERT(self.true_.isConvertibleTo(Json.realValue))
        # //   JSONTEST_ASSERT(true_.isConvertibleTo(Json::booleanValue));
        JSONTEST_ASSERT(self.true_.isConvertibleTo(Json.booleanValue))
        # //   JSONTEST_ASSERT(true_.isConvertibleTo(Json::stringValue));
        JSONTEST_ASSERT(self.true_.isConvertibleTo(Json.stringValue))
        # //   JSONTEST_ASSERT(!true_.isConvertibleTo(Json::arrayValue));
        JSONTEST_ASSERT(not self.true_.isConvertibleTo(Json.arrayValue))
        # //   JSONTEST_ASSERT(!true_.isConvertibleTo(Json::objectValue));
        JSONTEST_ASSERT(not self.true_.isConvertibleTo(Json.objectValue))
        # //   JSONTEST_ASSERT_EQUAL(true, true_.asBool());
        JSONTEST_ASSERT_EQUAL(true, self.true_.asBool())
        # //   JSONTEST_ASSERT_EQUAL(1, true_.asInt());
        JSONTEST_ASSERT_EQUAL(1, self.true_.asInt())
        # //   JSONTEST_ASSERT_EQUAL(1, true_.asLargestInt());
        JSONTEST_ASSERT_EQUAL(1, self.true_.asLargestInt())
        # //   JSONTEST_ASSERT_EQUAL(1, true_.asUInt());
        JSONTEST_ASSERT_EQUAL(1, self.true_.asUInt())
        # //   JSONTEST_ASSERT_EQUAL(1, true_.asLargestUInt());
        JSONTEST_ASSERT_EQUAL(1, self.true_.asLargestUInt())
        # //   JSONTEST_ASSERT_EQUAL(1.0, true_.asDouble());
        JSONTEST_ASSERT_EQUAL(1.0, self.true_.asDouble())
        # //   JSONTEST_ASSERT_EQUAL(1.0, true_.asFloat());
        JSONTEST_ASSERT_EQUAL(1.0, self.true_.asFloat())
        # //   JSONTEST_ASSERT_EQUAL(false, false_.asBool());
        JSONTEST_ASSERT_EQUAL(false, self.false_.asBool())
        # //   JSONTEST_ASSERT_EQUAL(0, false_.asInt());
        JSONTEST_ASSERT_EQUAL(0, self.false_.asInt())
        # //   JSONTEST_ASSERT_EQUAL(0, false_.asLargestInt());
        JSONTEST_ASSERT_EQUAL(0, self.false_.asLargestInt())
        # //   JSONTEST_ASSERT_EQUAL(0, false_.asUInt());
        JSONTEST_ASSERT_EQUAL(0, self.false_.asUInt())
        # //   JSONTEST_ASSERT_EQUAL(0, false_.asLargestUInt());
        JSONTEST_ASSERT_EQUAL(0, self.false_.asLargestUInt())
        # //   JSONTEST_ASSERT_EQUAL(0.0, false_.asDouble());
        JSONTEST_ASSERT_EQUAL(0.0, self.false_.asDouble())
        # //   JSONTEST_ASSERT_EQUAL(0.0, false_.asFloat());
        JSONTEST_ASSERT_EQUAL(0.0, self.false_.asFloat())
local_.append(JsonTest.TestCaseFactory(bools()))

# // JSONTEST_FIXTURE_LOCAL(ValueTest, integers)
struct integers(ValueTest):
    def runTestCase(self):
        # //   IsCheck checks;
        var checks: ValueTest.IsCheck = ValueTest.IsCheck()
        # //   Json::Value val;
        var val: Json.Value = Json.Value()
        # //   JSONTEST_ASSERT(Json::Value(17).isConvertibleTo(Json::realValue));
        JSONTEST_ASSERT(Json.Value(17).isConvertibleTo(Json.realValue))
        # //   JSONTEST_ASSERT(Json::Value(17).isConvertibleTo(Json::stringValue));
        JSONTEST_ASSERT(Json.Value(17).isConvertibleTo(Json.stringValue))
        # //   JSONTEST_ASSERT(Json::Value(17).isConvertibleTo(Json::booleanValue));
        JSONTEST_ASSERT(Json.Value(17).isConvertibleTo(Json.booleanValue))
        # //   JSONTEST_ASSERT(!Json::Value(17).isConvertibleTo(Json::arrayValue));
        JSONTEST_ASSERT(not Json.Value(17).isConvertibleTo(Json.arrayValue))
        # //   JSONTEST_ASSERT(!Json::Value(17).isConvertibleTo(Json::objectValue));
        JSONTEST_ASSERT(not Json.Value(17).isConvertibleTo(Json.objectValue))
        # //   JSONTEST_ASSERT(Json::Value(17U).isConvertibleTo(Json::realValue));
        JSONTEST_ASSERT(Json.Value(17U).isConvertibleTo(Json.realValue))
        # //   JSONTEST_ASSERT(Json::Value(17U).isConvertibleTo(Json::stringValue));
        JSONTEST_ASSERT(Json.Value(17U).isConvertibleTo(Json.stringValue))
        # //   JSONTEST_ASSERT(Json::Value(17U).isConvertibleTo(Json::booleanValue));
        JSONTEST_ASSERT(Json.Value(17U).isConvertibleTo(Json.booleanValue))
        # //   JSONTEST_ASSERT(!Json::Value(17U).isConvertibleTo(Json::arrayValue));
        JSONTEST_ASSERT(not Json.Value(17U).isConvertibleTo(Json.arrayValue))
        # //   JSONTEST_ASSERT(!Json::Value(17U).isConvertibleTo(Json::objectValue));
        JSONTEST_ASSERT(not Json.Value(17U).isConvertibleTo(Json.objectValue))
        # //   JSONTEST_ASSERT(Json::Value(17.0).isConvertibleTo(Json::realValue));
        JSONTEST_ASSERT(Json.Value(17.0).isConvertibleTo(Json.realValue))
        # //   JSONTEST_ASSERT(Json::Value(17.0).isConvertibleTo(Json::stringValue));
        JSONTEST_ASSERT(Json.Value(17.0).isConvertibleTo(Json.stringValue))
        # //   JSONTEST_ASSERT(Json::Value(17.0).isConvertibleTo(Json::booleanValue));
        JSONTEST_ASSERT(Json.Value(17.0