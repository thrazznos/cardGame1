import os
import shutil


def resolve_godot_executable() -> str:
    override = os.environ.get("GODOT_BIN") or os.environ.get("GODOT")
    if override:
        executable = shutil.which(os.path.expanduser(override))
        if executable:
            return executable
        raise FileNotFoundError(
            f"Godot override {override!r} was not found. "
            "Set GODOT_BIN/GODOT to a valid executable path or command."
        )

    for candidate in ("godot4", "godot"):
        executable = shutil.which(candidate)
        if executable:
            return executable

    raise FileNotFoundError(
        "Could not find a Godot executable. "
        "Install 'godot4' or 'godot', or set GODOT_BIN/GODOT."
    )
