#!/usr/bin/env bash
set -euf -o pipefail
./build-win.bat MinSizeRel
./build-win.bat Debug
