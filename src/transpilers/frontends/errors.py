"""Shared frontend exception."""


class UnsupportedConstruct(Exception):
    """A source construct the frontend deliberately refuses to translate
    (out of the supported subset) rather than emit broken output."""
