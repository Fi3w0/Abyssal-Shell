#!/usr/bin/env bash
set -euo pipefail

study_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
qml_bin=$(command -v qml || true)
if [[ -z "$qml_bin" ]]; then
    qml_bin=/usr/lib64/qt6/bin/qml
fi
if [[ ! -x "$qml_bin" ]]; then
    echo 'Qt 6 qml runner was not found.' >&2
    exit 1
fi
exec "$qml_bin" "$study_dir/Preview.qml" -- "$@"
