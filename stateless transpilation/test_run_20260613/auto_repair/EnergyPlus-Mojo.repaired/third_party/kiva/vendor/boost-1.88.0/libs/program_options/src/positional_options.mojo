from boost.program_options.config import *
from boost.program_options.positional_options import *
from boost.limits import *
from cassert import assert

struct positional_options_description:
    var m_trailing: String
    var m_names: List[String]

    def __init__(inout self):

    def add(inout self, name: String, max_count: Int) -> Self:
        assert(max_count != -1 or self.m_trailing.empty())
        if max_count == -1:
            self.m_trailing = name
        else:
            self.m_names.resize(self.m_names.size() + max_count, name)
        return self

    def max_total_count(self) -> UInt:
        return (static_cast[UInt](self.m_names.size()) if self.m_trailing.empty() else (std.numeric_limits[UInt].max()))

    def name_for_position(self, position: UInt) -> String:
        assert(position < self.max_total_count())
        if position < self.m_names.size():
            return self.m_names[position]
        else:
            return self.m_trailing