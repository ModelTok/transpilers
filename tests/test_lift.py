"""Never-refuse C++ -> Python lifter."""
from transpilers.lift import lift_source
from transpilers.levels import transpile_level


def test_lift_struct_to_class():
    out, _ = lift_source("struct P { double x = 1.5; int n = 0; bool ok = false; };")
    assert "class P:" in out
    assert "self.x = 1.5" in out and "self.n = 0" in out and "self.ok = False" in out


def test_lift_for_loop_to_while():
    out, _ = lift_source(
        "double dot(const double* a, int n){ double s=0.0; for(int i=0;i<n;i=i+1){ s=s+a[i]; } return s; }")
    assert "def dot(" in out
    assert "i = 0" in out
    assert "while i < n:" in out
    assert "i = i + 1" in out or "i += 1" in out
    assert "s = s + a[i]" in out


def test_lift_member_chain_recovered_from_tokens():
    # `state.dataCoolTower->GetInputFlag` must lift even though the type isn't
    # declared here (AST name-degraded) — recovered from the token stream.
    out, _ = lift_source(
        "void f(EnergyPlusData &state){ if (state.dataCoolTower->GetInputFlag) { return; } }")
    assert "state.data_cool_tower.get_input_flag" in out


def test_lift_recovers_degraded_method_and_array_access():
    # Method calls + ObjexxFCL-style array access through name-degraded chains
    # (no types) must recover the member names from tokens, not vanish.
    out, _ = lift_source(
        "void f(EnergyPlusData &state){ "
        "  auto x = state.dataCoolTower->CoolTowerSys(i); "
        "  int n = state.dataCoolTower->CoolTowerSys.size(); }")
    assert "state.data_cool_tower.cool_tower_sys(i)" in out
    assert "state.data_cool_tower.cool_tower_sys.size()" in out


def test_lift_never_refuses_unknown():
    # A construct the lifter can't handle yet must still produce output + TODO.
    out, _ = lift_source("void g(){ try { foo(); } catch (...) { } }")
    assert "def g(" in out
    assert "TODO[lift]" in out  # didn't crash; stubbed instead


def test_levels_lift_engine(tmp_path):
    f = tmp_path / "k.cpp"
    f.write_text("double sq(double x){ return x*x; }")
    results = transpile_level("file", str(f), engine="lift")
    assert len(results) == 1 and results[0].ok
    assert "def sq(" in results[0].output
