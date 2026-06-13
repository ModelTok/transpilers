from unicode_groups import URange16, UGroup
# namespace re2
let code1 = List[URange16](URange16(0x30, 0x39))  # /* \d */
let code2 = List[URange16](URange16(0x9, 0xa), URange16(0xc, 0xd), URange16(0x20, 0x20))  # /* \s */
let code3 = List[URange16](URange16(0x30, 0x39), URange16(0x41, 0x5a), URange16(0x5f, 0x5f), URange16(0x61, 0x7a))  # /* \w */
let perl_groups = List[UGroup](
	UGroup("\\d", 1, code1.data, 1, 0, 0),
	UGroup("\\D", -1, code1.data, 1, 0, 0),
	UGroup("\\s", 1, code2.data, 3, 0, 0),
	UGroup("\\S", -1, code2.data, 3, 0, 0),
	UGroup("\\w", 1, code3.data, 4, 0, 0),
	UGroup("\\W", -1, code3.data, 4, 0, 0),
)
let num_perl_groups = 6
let code4 = List[URange16](URange16(0x30, 0x39), URange16(0x41, 0x5a), URange16(0x61, 0x7a))  # /* [:alnum:] */
let code5 = List[URange16](URange16(0x41, 0x5a), URange16(0x61, 0x7a))  # /* [:alpha:] */
let code6 = List[URange16](URange16(0x0, 0x7f))  # /* [:ascii:] */
let code7 = List[URange16](URange16(0x9, 0x9), URange16(0x20, 0x20))  # /* [:blank:] */
let code8 = List[URange16](URange16(0x0, 0x1f), URange16(0x7f, 0x7f))  # /* [:cntrl:] */
let code9 = List[URange16](URange16(0x30, 0x39))  # /* [:digit:] */
let code10 = List[URange16](URange16(0x21, 0x7e))  # /* [:graph:] */
let code11 = List[URange16](URange16(0x61, 0x7a))  # /* [:lower:] */
let code12 = List[URange16](URange16(0x20, 0x7e))  # /* [:print:] */
let code13 = List[URange16](URange16(0x21, 0x2f), URange16(0x3a, 0x40), URange16(0x5b, 0x60), URange16(0x7b, 0x7e))  # /* [:punct:] */
let code14 = List[URange16](URange16(0x9, 0xd), URange16(0x20, 0x20))  # /* [:space:] */
let code15 = List[URange16](URange16(0x41, 0x5a))  # /* [:upper:] */
let code16 = List[URange16](URange16(0x30, 0x39), URange16(0x41, 0x5a), URange16(0x5f, 0x5f), URange16(0x61, 0x7a))  # /* [:word:] */
let code17 = List[URange16](URange16(0x30, 0x39), URange16(0x41, 0x46), URange16(0x61, 0x66))  # /* [:xdigit:] */
let posix_groups = List[UGroup](
	UGroup("[:alnum:]", 1, code4.data, 3, 0, 0),
	UGroup("[:^alnum:]", -1, code4.data, 3, 0, 0),
	UGroup("[:alpha:]", 1, code5.data, 2, 0, 0),
	UGroup("[:^alpha:]", -1, code5.data, 2, 0, 0),
	UGroup("[:ascii:]", 1, code6.data, 1, 0, 0),
	UGroup("[:^ascii:]", -1, code6.data, 1, 0, 0),
	UGroup("[:blank:]", 1, code7.data, 2, 0, 0),
	UGroup("[:^blank:]", -1, code7.data, 2, 0, 0),
	UGroup("[:cntrl:]", 1, code8.data, 2, 0, 0),
	UGroup("[:^cntrl:]", -1, code8.data, 2, 0, 0),
	UGroup("[:digit:]", 1, code9.data, 1, 0, 0),
	UGroup("[:^digit:]", -1, code9.data, 1, 0, 0),
	UGroup("[:graph:]", 1, code10.data, 1, 0, 0),
	UGroup("[:^graph:]", -1, code10.data, 1, 0, 0),
	UGroup("[:lower:]", 1, code11.data, 1, 0, 0),
	UGroup("[:^lower:]", -1, code11.data, 1, 0, 0),
	UGroup("[:print:]", 1, code12.data, 1, 0, 0),
	UGroup("[:^print:]", -1, code12.data, 1, 0, 0),
	UGroup("[:punct:]", 1, code13.data, 4, 0, 0),
	UGroup("[:^punct:]", -1, code13.data, 4, 0, 0),
	UGroup("[:space:]", 1, code14.data, 2, 0, 0),
	UGroup("[:^space:]", -1, code14.data, 2, 0, 0),
	UGroup("[:upper:]", 1, code15.data, 1, 0, 0),
	UGroup("[:^upper:]", -1, code15.data, 1, 0, 0),
	UGroup("[:word:]", 1, code16.data, 4, 0, 0),
	UGroup("[:^word:]", -1, code16.data, 4, 0, 0),
	UGroup("[:xdigit:]", 1, code17.data, 3, 0, 0),
	UGroup("[:^xdigit:]", -1, code17.data, 3, 0, 0),
)
let num_posix_groups = 28
# // namespace re2