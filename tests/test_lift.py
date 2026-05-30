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


def test_lift_recovers_degraded_method_calls():
    # Method calls through a name-degraded chain (no types) must recover the
    # full member name from tokens, not collapse to `state.(...)`.
    out, _ = lift_source(
        "void f(EnergyPlusData &state, int n){ "
        "  int k = state.dataCoolTower->CoolTowerSys.size(); "
        "  state.dataInput->obj->doThing(n); }")
    assert "state.data_cool_tower.cool_tower_sys.size()" in out
    assert "state.data_input.obj.do_thing(n)" in out


def test_lift_array_member_after_call_recovered():
    # gap 1: ObjexxFCL array-member access `Arr(i).Field` (member AFTER an
    # operator() call) must recover the full chain from tokens, type-less.
    # The 1-based subscript is kept faithfully as a call `arr(i)` (Phase-1).
    out, _ = lift_source(
        "void f(State &state, int i){ "
        "  double t = state.dataZ->zoneHeatBalance(i).MAT; "
        "  if (Zone(i).OutDryBulbTemp > 5.0) return; }")
    assert "t = state.data_z.zone_heat_balance(i).mat" in out
    assert "if zone(i).out_dry_bulb_temp > 5.0:" in out


def test_lift_nested_array_member_chain_recovered():
    # gap 1: chained array-member-after-call `Storage(i).Avail(j)`.
    out, _ = lift_source(
        "void f(State &state, int i, int j){ "
        "  double a = state.dataW->WaterStorage(i).VdotAvailDemand(j); }")
    assert "a = state.data_w.water_storage(i).vdot_avail_demand(j)" in out


def test_lift_namespaced_call_in_condition_recovered():
    # gap 2: UNEXPOSED_EXPR wrapping namespaced calls in conditions.
    # std::abs -> abs (Python builtin); Ns::Func -> snaked func, namespace
    # qualifier dropped. Type-less so the whole comparison degrades to a
    # token stream.
    out, _ = lift_source(
        "double f(double x, const char* a, const char* b){ "
        "  if (std::abs(x) > 1.0) return 1.0; "
        "  while (Util::SameString(a, b)) return 2.0; "
        "  return 0.0; }")
    assert "if abs(x) > 1.0:" in out
    assert "while same_string(a, b):" in out


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
