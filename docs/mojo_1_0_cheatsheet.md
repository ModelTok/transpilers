# Mojo 1.0 cheat sheet (for the C++ → Mojo benchmark)

Toolchain: Mojo 1.0.0b1, the version the transpilers repo pins. Every entry below was compiled and run with this toolchain (test programs in `/root/triage/cheat/`, results in `results.txt`), unless marked "kernel".

## Works

| Need | Write this | Verified |
|---|---|---|
| square root | `from std.math import sqrt` then `sqrt(2.0)` | yes |
| constant | `comptime LIMIT: Int = 3` | yes |
| list | `var xs = List[Int]()`, `xs.append(4)`, `len(xs)`, `xs[0]`, `for x in xs:` | yes |
| copy a list | `var b = a.copy()` | yes |
| sort a list | `sort(xs)` | yes |
| dictionary | `var d = Dict[String, Int]()`, `d["a"] = 1`, `d["a"]` | yes |
| optional value | `var o: Optional[Int] = Optional[Int](5)`, `if o:`, `o.value()` | yes |
| string | `var s = String("abc")`, `s.byte_length()`, `for c in s.codepoints():` | yes |
| tuple | `def pair(a: Int, b: Int) -> Tuple[Int, Int]:` and `t[0]`, `t[1]` | yes |
| struct | `struct Stack(Movable):`, `def __init__(out self):`, `def push(mut self, x: Int):` | yes (kernel style too) |
| largest Int | `Int.MAX` | yes |
| boolean | `var b: Bool = True` | yes |
| variable | `var x = 3`, or `x = 3` on its first use | yes |
| raw pointer | `UnsafePointer[Float64, MutAnyOrigin](unsafe_from_address=addr)` | kernel (the kernels use this for all output) |
| main | `def main() raises:` | yes |

## Does not exist (use the replacement)

| Wrong | Right |
|---|---|
| `Option[T]` | `Optional[T]` |
| `str` | `String` |
| `Boolean` | `Bool` |
| `MAX_VALUE` | `Int.MAX` |
| `out r: Int` argument to return a value | return the value: `def f(x: Int) -> Int:` |

## Not verified in this sheet

- `Ref`, `sign` (appeared as unknown names in compile failures; no test yet).
- `String.is_alpha_numeric`, `String.index_of_first`, `String.Index` and `collections.PriorityQueue` (Python-style names; they were not tested, but each failed to compile in a model output).
- Ownership errors ("cannot transfer out of immutable reference", "expression must be mutable in assignment"): the fix is `var` and `mut`, but I have not tested a minimal case.
