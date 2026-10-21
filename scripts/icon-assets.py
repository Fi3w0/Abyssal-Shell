#!/usr/bin/env python3
"""Locate optional raster fallbacks using the XDG data search path."""
import json
import os
from pathlib import Path

home = Path(os.environ.get("XDG_DATA_HOME") or Path.home() / ".local/share")
roots = [home] + [Path(p) for p in os.environ.get("XDG_DATA_DIRS", "/usr/local/share:/usr/share").split(":") if p]
result = {}
for root in roots:
    for size in (256, 128, 512, 64):
        path = root / "icons/hicolor" / f"{size}x{size}" / "apps/com.obsproject.Studio.png"
        if path.is_file():
            result["obs"] = path.absolute().as_uri()
            break
    if result:
        break
print(json.dumps(result))
