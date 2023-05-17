from pathlib import Path

_this_file = Path(__file__).resolve()

DIR_REPO = _this_file.parent.parent.parent.resolve()

DIR_LOCAL = (DIR_REPO / ".local").resolve()
assert DIR_LOCAL.is_dir(), f"{DIR_LOCAL.as_posix()} is not a dir"

DIR_DOCKER_CACHE = Path("/var/cache/app")

DIR_STATIC = (
    (DIR_DOCKER_CACHE if DIR_DOCKER_CACHE.is_dir() else DIR_LOCAL)
    / "django-static"  # noqa: W503
).resolve()

DIR_STATIC.mkdir(exist_ok=True, mode=0o777)
