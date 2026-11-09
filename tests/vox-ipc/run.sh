#!/bin/bash
# Extract, build (ASan+UBSan), run. Prints only failures plus a summary.
#   ./run.sh            quiet: failures + summary (known deviations listed with -v only)
#   ./run.sh -v         also passing tests and known deviations
#   ./run.sh <substr>   only tests whose name contains substr
set -e
cd "$(dirname "$0")"
mkdir -p build
python3 extract.py >/dev/null
ARCH=-m64
if echo 'int main(){}' | g++ -m32 -x c++ - -o build/.m32probe 2>/dev/null; then ARCH=-m32; fi
rm -f build/.m32probe
g++ -std=gnu++98 $ARCH -g -O1 -fno-omit-frame-pointer -Wall -Wno-unused-function -Wno-unused-variable \
    -fsanitize=address,undefined,float-cast-overflow -fno-sanitize-recover=all \
    -I/usr/include/lua5.1 harness.cpp -o build/harness -llua5.1 2>build/compile.log || { echo "BUILD FAILED"; head -40 build/compile.log; exit 2; }
export TMPDIR="$PWD/build"
export ASAN_OPTIONS=detect_leaks=1:abort_on_error=0:allocator_may_return_null=1
export UBSAN_OPTIONS=print_stacktrace=1:halt_on_error=1
set +e
./build/harness "$@"
