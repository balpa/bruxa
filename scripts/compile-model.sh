#!/usr/bin/env bash
# Compile BruxaModel.xcdatamodeld into the runtime BruxaModel.momd.
#
# Run this whenever you edit
#   app/BruxaCore/Sources/BruxaCore/BruxaModel.xcdatamodeld/BruxaModel.xcdatamodel/contents
# Otherwise SwiftPM ships a stale model and CoreData silently uses the old schema.

set -euo pipefail

cd "$(dirname "$0")/.."
SRC="app/BruxaCore/Sources/BruxaCore/BruxaModel.xcdatamodeld"
DST="app/BruxaCore/Sources/BruxaCore/BruxaModel.momd"

if [[ ! -d "$SRC" ]]; then
    echo "Source model not found at $SRC" >&2
    exit 1
fi

rm -rf "$DST"
xcrun momc "$SRC" "$DST"
echo "Compiled $SRC -> $DST"
