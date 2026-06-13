from boost.program_options.config import *
from boost.program_options.parsers import *
from boost.program_options.options_description import *
from boost.program_options.value_semantic import *
from boost.program_options.variables_map import *
from cassert import assert

namespace boost:
    namespace program_options:
        @export
        def store(options: parsed_options, xm: variables_map, utf8: bool = False):
            assert(options.description)
            let desc: options_description = *options.description
            var m: Map[String, variable_value] = xm
            var new_final: Set[String] = Set[String]()
            var i: UInt
            var option_name: String
            var original_token: String
            try:
                i = 0
                while i < options.options.size():
                    option_name = options.options[i].string_key
                    if option_name.empty():
                        i += 1
                        continue
                    if options.options[i].unregistered:
                        i += 1
                        continue
                    if xm.m_final.count(option_name):
                        i += 1
                        continue
                    original_token = options.options[i].original_tokens[0] if options.options[i].original_tokens.size() else ""
                    let d: option_description = desc.find(option_name, False, False, False)
                    var v: variable_value = m[option_name]
                    if v.defaulted():
                        v = variable_value()
                    d.semantic().parse(v.value(), options.options[i].value, utf8)
                    v.m_value_semantic = d.semantic()
                    if not d.semantic().is_composing():
                        new_final.insert(option_name)
                    i += 1
            except error_with_option_name as e:
                e.add_context(option_name, original_token, options.m_options_prefix)
                raise
            xm.m_final.insert(new_final.begin(), new_final.end())
            let all: Vector[SharedPtr[option_description]] = desc.options()
            i = 0
            while i < all.size():
                let d: option_description = *all[i]
                var key: String = d.key("")
                if key.empty():
                    i += 1
                    continue
                if m.count(key) == 0:
                    var def: any = any()
                    if d.semantic().apply_default(def):
                        m[key] = variable_value(def, True)
                        m[key].m_value_semantic = d.semantic()
                if d.semantic().is_required():
                    var canonical_name: String = d.canonical_display_name(options.m_options_prefix)
                    if canonical_name.length() > xm.m_required[key].length():
                        xm.m_required[key] = canonical_name
                i += 1

        @export
        def store(options: wparsed_options, m: variables_map):
            store(options.utf8_encoded_options, m, True)

        @export
        def notify(vm: variables_map):
            vm.notify()

        struct abstract_variables_map:
            var m_next: Pointer[abstract_variables_map]

            def __init__(inout self):
                self.m_next = Pointer[abstract_variables_map]()

            def __init__(inout self, next: Pointer[abstract_variables_map]):
                self.m_next = next

            def __getitem__(self, name: String) -> variable_value:
                let v: variable_value = self.get(name)
                if v.empty() and self.m_next:
                    return self.m_next[][name]
                elif v.defaulted() and self.m_next:
                    let v2: variable_value = self.m_next[][name]
                    if not v2.empty() and not v2.defaulted():
                        return v2
                    else:
                        return v
                else:
                    return v

            def next(inout self, next: Pointer[abstract_variables_map]):
                self.m_next = next

        struct variables_map(abstract_variables_map):
            def __init__(inout self):

            def __init__(inout self, next: Pointer[abstract_variables_map]):
                abstract_variables_map.__init__(self, next)

            def clear(inout self):
                Map[String, variable_value].clear(self)
                self.m_final.clear()
                self.m_required.clear()

            def get(self, name: String) -> variable_value:
                var empty: variable_value = variable_value()
                let i: Map[String, variable_value].Iterator = self.find(name)
                if i == self.end():
                    return empty
                else:
                    return i.second

            def notify(inout self):
                var r: Map[String, String].Iterator = self.m_required.begin()
                while r != self.m_required.end():
                    let opt: String = r.first
                    let display_opt: String = r.second
                    let iter: Map[String, variable_value].Iterator = self.find(opt)
                    if iter == self.end() or iter.second.empty():
                        boost.throw_exception(required_option(display_opt))
                    r += 1
                var k: Map[String, variable_value].Iterator = self.begin()
                while k != self.end():
                    if k.second.m_value_semantic:
                        k.second.m_value_semantic.notify(k.second.value())
                    k += 1