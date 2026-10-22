"""Workspace resolution and packaged prompt for the stateless runner."""

from __future__ import annotations

from pathlib import Path

from transpilers.stateless import runner as T


def test_env_var_overrides_the_workspace(monkeypatch, tmp_path: Path):
    monkeypatch.setenv("TRANSPILERS_STATELESS_DIR", str(tmp_path))
    assert T.workspace_dir() == tmp_path.resolve()


def test_default_workspace_is_the_checkout_folder(monkeypatch):
    monkeypatch.delenv("TRANSPILERS_STATELESS_DIR", raising=False)
    repo_dir = Path(T.__file__).resolve().parents[3] / "stateless transpilation"
    assert T.workspace_dir() == (repo_dir if repo_dir.is_dir() else Path.cwd())


def test_prompt_template_ships_with_the_package():
    assert (Path(T.__file__).with_name("transpile_prompt.md")).is_file()
    assert "{FILE}" in T.PROMPT_TEMPLATE
