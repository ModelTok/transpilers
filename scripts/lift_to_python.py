#!/usr/bin/env python3
"""Thin CLI wrapper — the lifter now lives in the package (transpilers.lift)."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))
from transpilers.lift import main
if __name__ == "__main__":
    main()
