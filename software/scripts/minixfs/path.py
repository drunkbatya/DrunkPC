def split(path: str) -> list[str]:
    """'/foo/bar/' -> ['foo', 'bar']. '/' or '' -> []."""
    return [p for p in path.split("/") if p]


def parent(path: str) -> str:
    """'/foo/bar/baz' -> '/foo/bar'. '/foo' -> '/'. '/' -> '/'."""
    components = split(path)
    if not components:
        return "/"
    return "/" + "/".join(components[:-1])


def basename(path: str) -> str:
    """'/foo/bar/baz' -> 'baz'. '/' -> ''."""
    components = split(path)
    return components[-1] if components else ""
