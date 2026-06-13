from Reference import Reference_int_const, Reference_int, Reference_string, Reference, associated

def ReferenceTest_Basic():
    var r = Reference_int_const()
    assert not r.attached()
    assert not r.associated()
    var j: Int = 42
    var k: Int = 59
    r.attach(j)
    assert j == 42
    assert r == 42
    assert r.attached()
    assert r.associated()
    assert r.attached(j)
    assert r.associated(j)
    assert not r.attached(k)
    assert not r.associated(k)
    var r2 = Reference_int_const(j)
    assert r.associated(r2)
    assert associated(r, r2)
    r.detach()
    assert not r.attached()
    assert not r.associated()
    assert not r.attached(j)
    assert not r.associated(j)

def ReferenceTest_Advanced():
    var j: Int = 42
    var k: Int = 59
    var r = Reference_int(j)
    assert r.attached()
    assert r.associated()
    assert r.attached(j)
    assert r.associated(j)
    assert not r.attached(k)
    assert not r.associated(k)
    r.detach()
    assert not r.attached()
    assert not r.associated()
    assert not r.attached(j)
    assert not r.associated(j)
    r.attach(j)
    r = k
    assert j == 59
    assert r == 59
    r >>= k
    assert r.attached(k)
    assert r.associated(k)
    assert not r.attached(j)
    assert not r.associated(j)
    var r1 = Reference_int(r)  # Reference of Reference
    assert r1 == k
    var r2 = Reference_int(r1)
    assert r2 == k
    r2 >>= j
    assert r2 == j
    assert r1 == k
    r2 >>= r1
    assert r2 == k

def ReferenceTest_ConstInt():
    var OBJEXXFCL_CATCH_NONCONST_REFERENCE_TO_CONST: Bool = False
    if not OBJEXXFCL_CATCH_NONCONST_REFERENCE_TO_CONST:
        let j: Int = 42
        var r = Reference_int(j)  # Fortran allows POINTER to INTENT(IN) (const) arg
        assert r.attached()
        assert r.associated()
        assert r.attached(j)
        assert r.associated(j)
        assert r == j
        r.detach()
        assert not r.attached()
        assert not r.associated()
        assert not r.attached(j)
        assert not r.associated(j)

def ReferenceTest_String():
    var s = String("A short phrase")
    var r = Reference_string(s)
    assert r.attached()
    assert r.associated()
    assert r.attached(s)
    assert r == s

def ReferenceTest_Allocate():
    # First block
    {
        var r = Reference_int()
        r.allocate()
        r = 123
        assert r.attached()
        assert r.associated()
        assert r.attached()
        assert r == 123
        r.deallocate()
        assert not r.attached()
        assert not r.associated()
        assert not r.attached()
    }
    # Second block
    {
        @value
        struct S:
            var i: Int
            var j: Int
            var k: Int
        var r = Reference[S]()
        r.allocate()
        r().i = 1
        r().j = 2
        r().k = 3
        assert r.attached()
        assert r.associated()
        assert r.attached()
        assert r().i == 1
        r.deallocate()
        assert not r.attached()
        assert not r.associated()
        assert not r.attached()
    }

def main():
    ReferenceTest_Basic()
    ReferenceTest_Advanced()
    ReferenceTest_ConstInt()
    ReferenceTest_String()
    ReferenceTest_Allocate()