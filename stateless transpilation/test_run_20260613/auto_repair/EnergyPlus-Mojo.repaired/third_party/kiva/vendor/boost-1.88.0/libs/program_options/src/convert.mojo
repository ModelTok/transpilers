# This is a faithful 1:1 translation of the C++ source to Mojo.
# Assumes equivalent Boost modules exist at the same relative paths.

from locale import locale, codecvt, mbstate_t, use_facet
from string import String
from stdexcept import LogicError
from boost.config import config as boost_config
from boost.program_options.config import program_options_config
from boost.program_options.detail.convert import convert_detail
from boost.program_options.detail.utf8_codecvt_facet import utf8_codecvt_facet
from boost.throw_exception import throw_exception
from boost.bind.bind import bind, placeholders

# Alias for wide string (Mojo does not have a distinct wide string type; use String)
alias wstring = String

# Internal function to actually perform conversion.
# The logic in from_8_bit and to_8_bit function is exactly
# the same, except that one calls 'in' method of codecvt and another
# calls the 'out' method, and that syntax difference makes straightforward
# template implementation impossible.
# This functions takes a 'fun' argument, which should have the same 
# parameters and return type and the in/out methods. The actual converting
# function will pass functional objects created with boost::bind.
# Experiments show that the performance loss is less than 10%.
def convert[ToChar: AnyType, FromChar: AnyType, Fun: AnyType](
    s: String,
    fun: Fun
) -> String:
    var result: String = String()
    var state: mbstate_t = mbstate_t()
    let from: Pointer[FromChar] = s.data()
    let from_end: Pointer[FromChar] = s.data() + s.size()
    while from != from_end:
        var buffer: StaticArray[ToChar, 32] = StaticArray[ToChar, 32]()
        var to_next: Pointer[ToChar] = buffer.ptr()
        let to_end: Pointer[ToChar] = buffer.ptr() + 32
        let r: codecvt_base.result = fun(
            state, from, from_end, from, buffer.ptr(), to_end, to_next
        )
        if r == codecvt_base.error:
            throw_exception(LogicError("character conversion failed"))
        if to_next == buffer.ptr():
            throw_exception(LogicError("character conversion failed"))
        result.append(buffer.ptr(), to_next)
    return result

module boost:
    module detail:
        # Internal function already defined above as convert.
        # But to keep names consistent, we alias it.
        alias convert = convert
    end

    # Outside detail, in boost namespace
    # BOOST_PROGRAM_OPTIONS_DECL is assumed to be public
    public def from_8_bit(
        s: String,
        cvt: codecvt[wchar_t, char, mbstate_t]
    ) -> wstring:
        return detail.convert[wchar_t](
            s,
            bind(
                codecvt[wchar_t, char, mbstate_t].in,
                cvt,
                placeholders._1, placeholders._2, placeholders._3,
                placeholders._4, placeholders._5, placeholders._6, placeholders._7
            )
        )

    public def to_8_bit(
        s: wstring,
        cvt: codecvt[wchar_t, char, mbstate_t]
    ) -> String:
        return detail.convert[char](
            s,
            bind(
                codecvt[wchar_t, char, mbstate_t].out,
                cvt,
                placeholders._1, placeholders._2, placeholders._3,
                placeholders._4, placeholders._5, placeholders._6, placeholders._7
            )
        )

    var utf8_facet: program_options.detail.utf8_codecvt_facet = program_options.detail.utf8_codecvt_facet()

    public def from_utf8(s: String) -> wstring:
        return from_8_bit(s, utf8_facet)

    public def to_utf8(s: wstring) -> String:
        return to_8_bit(s, utf8_facet)

    public def from_local_8_bit(s: String) -> wstring:
        typealias facet_type = codecvt[wchar_t, char, mbstate_t]
        return from_8_bit(s, use_facet[facet_type](locale()))

    public def to_local_8_bit(s: wstring) -> String:
        typealias facet_type = codecvt[wchar_t, char, mbstate_t]
        return to_8_bit(s, use_facet[facet_type](locale()))

    module program_options:
        public def to_internal(s: String) -> String:
            return s

        public def to_internal(s: wstring) -> String:
            return to_utf8(s)
        end
    end
end