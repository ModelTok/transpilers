from ...fmt.format-inl import *

@value
struct detail:
    @staticmethod
    def format_float[T: AnyType](buf: Pointer[UInt8], size: Int, format: StringRef, precision: Int, value: T) -> Int:
        #ifdef FMT_FUZZ
        if precision > 100000:
            raise RuntimeError("fuzz mode - avoid large allocation inside snprintf")
        #endif
        let snprintf_ptr: Pointer[FunctionPointer[Int, (Pointer[UInt8], Int, StringRef, *AnyType)]] = FMT_SNPRINTF
        return snprintf_ptr(buf, size, format, value) if precision < 0 else snprintf_ptr(buf, size, format, precision, value)

    # template FMT_API dragonbox::decimal_fp<float> dragonbox::to_decimal(float x) FMT_NOEXCEPT;
    def to_decimal_float(x: F32) -> dragonbox.decimal_fp[F32]:
        return dragonbox.to_decimal(x)

    # template FMT_API dragonbox::decimal_fp<double> dragonbox::to_decimal(double x) FMT_NOEXCEPT;
    def to_decimal_double(x: F64) -> dragonbox.decimal_fp[F64]:
        return dragonbox.to_decimal(x)

# int (*instantiate_format_float)(double, int, detail::float_specs, detail::buffer<char>&) = detail::format_float;
var instantiate_format_float: Pointer[FunctionPointer[Int, (F64, Int, detail.float_specs, detail.buffer[UInt8]&)]] = detail.format_float

#ifndef FMT_STATIC_THOUSANDS_SEPARATOR
    # template FMT_API detail::locale_ref::locale_ref(locale& loc );
    def locale_ref_constructor(loc: Locale) -> detail.locale_ref:
        return detail.locale_ref(loc)

    # template FMT_API locale detail::locale_ref::get<locale>() const;
    def locale_ref_get(loc: detail.locale_ref) -> Locale:
        return loc.get[Locale]()
#endif

# template FMT_API auto detail::thousands_sep_impl(locale_ref) -> thousands_sep_result<char>;
def thousands_sep_impl(loc: detail.locale_ref) -> detail.thousands_sep_result[UInt8]:
    return detail.thousands_sep_impl(loc)

# template FMT_API char detail::decimal_point_impl(locale_ref);
def decimal_point_impl(loc: detail.locale_ref) -> UInt8:
    return detail.decimal_point_impl(loc)

# template FMT_API void detail::buffer<char>::append(const char*, const char*);
def buffer_append(buf: detail.buffer[UInt8], first: StringRef, last: StringRef):
    buf.append(first, last)

# template FMT_API void detail::vformat_to(detail::buffer<char>&, string_view, basic_format_args<FMT_BUFFER_CONTEXT(char)>, detail::locale_ref);
def vformat_to(buf: detail.buffer[UInt8], view: string_view, args: basic_format_args[FMT_BUFFER_CONTEXT(UInt8)], loc: detail.locale_ref):
    detail.vformat_to(buf, view, args, loc)

# template FMT_API int detail::snprintf_float(double, int, detail::float_specs, detail::buffer<char>&);
def snprintf_float_double(value: F64, precision: Int, specs: detail.float_specs, buf: detail.buffer[UInt8]) -> Int:
    return detail.snprintf_float(value, precision, specs, buf)

# template FMT_API int detail::snprintf_float(long double, int, detail::float_specs, detail::buffer<char>&);
def snprintf_float_long_double(value: F64, precision: Int, specs: detail.float_specs, buf: detail.buffer[UInt8]) -> Int:
    return detail.snprintf_float(value, precision, specs, buf)

# template FMT_API int detail::format_float(double, int, detail::float_specs, detail::buffer<char>&);
def format_float_double(value: F64, precision: Int, specs: detail.float_specs, buf: detail.buffer[UInt8]) -> Int:
    return detail.format_float(value, precision, specs, buf)

# template FMT_API int detail::format_float(long double, int, detail::float_specs, detail::buffer<char>&);
def format_float_long_double(value: F64, precision: Int, specs: detail.float_specs, buf: detail.buffer[UInt8]) -> Int:
    return detail.format_float(value, precision, specs, buf)

# template FMT_API auto detail::thousands_sep_impl(locale_ref) -> thousands_sep_result<wchar_t>;
def thousands_sep_impl_wchar(loc: detail.locale_ref) -> detail.thousands_sep_result[WChar]:
    return detail.thousands_sep_impl(loc)

# template FMT_API wchar_t detail::decimal_point_impl(locale_ref);
def decimal_point_impl_wchar(loc: detail.locale_ref) -> WChar:
    return detail.decimal_point_impl(loc)

# template FMT_API void detail::buffer<wchar_t>::append(const wchar_t*, const wchar_t*);
def buffer_append_wchar(buf: detail.buffer[WChar], first: Pointer[WChar], last: Pointer[WChar]):
    buf.append(first, last)

# template struct detail::basic_data<void>;
@value
struct basic_data_void:
    # placeholder for instantiation
