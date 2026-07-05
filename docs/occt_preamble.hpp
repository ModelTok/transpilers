// OpenCASCADE (OCCT) declaration shim for the strict C++ frontend.
//
// Use via the existing project-preamble extension point (see
// `_project_preamble()` in `frontends/cpp/parser/core.py`):
//
//     TRANSPILERS_CPP_PREAMBLE_FILE=docs/occt_preamble.hpp \
//         transpile Foo.cpp --source cpp --target mojo -I include/ --verify
//
// Why this exists (see docs/topologic_migration.md for the full writeup):
// OpenCASCADE-based projects (e.g. github.com/wassimj/Topologic) routinely
// define their public-API export macro (`FOO_API`) in the same header as an
// unrelated OCCT-typed helper. Once local #include resolution (issue #79)
// makes that header visible, *every* file that only wanted the macro also
// inherits an OpenCASCADE dependency it doesn't otherwise touch -- so every
// file in the project fails to parse on an OCCT type name, not just the
// files whose own logic actually does geometry.
//
// Scope: this is NOT a real OCCT binding. It declares just enough of the
// handful of types that show up in that specific macro-coupling pattern
// (TopoDS_Shape used in a hash/comparator helper; TopAbs_ShapeEnum as a
// return type) as opaque shapes, so libclang can build an AST past them.
// It does not model real geometry semantics, and it will not by itself get
// a file whose *own* logic calls deep into the OCCT API (BRepBuilderAPI_*,
// Geom_*, gp_*, ...) all the way to a compiling Mojo/Rust/etc. output --
// that would need a real binding library on the target side, which doesn't
// exist for Mojo today. Extend this file with more opaque types/methods as
// needed; each addition only has to be broad enough for libclang to parse,
// never semantically accurate.

class TopoDS_TShape_Handle {
public:
    void* operator->() const;
};

class TopoDS_Shape {
public:
    TopoDS_TShape_Handle TShape() const;
};

enum TopAbs_ShapeEnum {
    TopAbs_COMPOUND,
    TopAbs_COMPSOLID,
    TopAbs_SOLID,
    TopAbs_SHELL,
    TopAbs_FACE,
    TopAbs_WIRE,
    TopAbs_EDGE,
    TopAbs_VERTEX,
    TopAbs_SHAPE,
};
