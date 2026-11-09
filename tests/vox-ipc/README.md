# vox-ipc Lua <-> JSON test harness

Linux harness for the Lua/JSON conversion code in `CvGameCoreDLL_Expansion2/CvConnectionService.cpp`
(`ConvertLuaValuesInDocument`, `ConvertLuaToJsonValue`, `ConvertJsonToLuaValue`, `ProcessLuaResult`,
`CleanLuaErrorMessage`). It runs the real function bodies against real Lua 5.1 and the repo's ArduinoJson 6.20.1.

## Run
```
tests/vox-ipc/run.sh            # extract, build (ASan+UBSan+float-cast-overflow), run; failures + summary only
tests/vox-ipc/run.sh -v         # also passing tests, probe output and the list of known deviations
tests/vox-ipc/run.sh <substr>   # only tests whose name contains substr (e.g. nest_, json_, process_result)
```
Needs g++, python3, Lua 5.1 headers (`/usr/include/lua5.1`, `-llua5.1`). Takes about 35 s (the `perf_*` tests).
Exit code is 1 if any test fails. `KNOWN` lines are deviations from the ideal behaviour that are documented, not failures.

## How it works
- `extract.py` pulls the function bodies out of `CvConnectionService.cpp` by name (brace matching that skips
  comments/strings) into `build/extracted.inc`, with `#line` directives, so compiler/sanitizer messages cite the real
  file and line. Source is only read. Re-run on every build (run.sh does).
- `harness.cpp` has a stand-in `CvConnectionService` (same member signatures, `Log` records messages,
  `SendMessage` serializes into a string, `LogLevel` enum), stubs `DWORD`/`GetTickCount` (advances 5 s per call so the
  once-a-second warning limiter always logs) and `#include`s the `.inc`. Each test runs in a forked child with a
  15 s alarm, so a sanitizer abort, crash or hang is reported against its test without stopping the rest.
- Dialect/arch: `-std=gnu++98` (the game is MSVC 2008). `-m32` is used automatically if a 32-bit toolchain links;
  on this machine it does not (no 32-bit libgcc), so the build is **64-bit**. ArduinoJson nodes are bigger on 64-bit
  (about 24 vs 16 bytes), so document capacities in nodes are roughly 1.5x smaller here than in the game.

## Coverage
- Lua -> JSON: nil/bool/int/float/string, empty/array/map/mixed/sparse tables, numeric/bool/float/negative keys,
  odd numeric keys (1e10, 2^31, inf, 2^53, 1e300), int/double edges (INT_MIN/MAX, 2^53, 2^62, NaN, +-inf, -0),
  strings with NUL / invalid UTF-8 / quotes / control chars, 1 MB and 10 MB strings, function/thread/userdata/lightuserdata
  values and keys, key collisions, nesting 31/32/33/34/100 (array and map), self and mutual references, work explosion
  (2-3 self-references, DAG), metatables (`__index`, `__newindex`, `__len`, `__pairs`... counter proves none run),
  0/1/2/50/500 return values, relative stack indices, Lua stack top unchanged after each conversion, Lua stack
  nearly full (lua_checkstack failure path).
- Overflow: tiny documents, copied-string pools (number keys, `<function>` names), multi-value, zero capacity,
  capacity probes for the 524288 write buffer and 65536 CallExternal request doc, `ProcessLuaResult`
  RESULT_TOO_LARGE (array / map of tables / many values), boundary just under the limit, base-offset stack
  handling (values below `iStackBase` untouched), error responses, 10 MB string response.
- Lifetime: which strings the document copies and which it keeps by pointer (quarantine allocator poisons freed
  Lua blocks; serialize before vs after popping + GC).
- JSON -> Lua: depth 31/32/33/1000 (arrays and objects, built through the API because the text parser stops at 255),
  default nesting limit 10, 200k-element array, 5000-key object, wide nested arrays, null, unicode escapes and
  surrogates, `\u0000`, numbers (1e400, 2^53+1, uint64 max, 1e-400...), full Lua stack, round trip.
- Perf: string-key maps of 1k-16k keys.
