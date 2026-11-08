# IPC build of the Community Patch DLL (branch `vox-ipc-5.4.8`)

This branch is Vox Populi 5.4.8's DLL with **Vox Deorum's connection service** ported in. It adds an optional
named-pipe channel that lets a program on the same PC receive the game's events and call Lua functions that
mods register. All of it sits behind the mod option `IPC_CHANNEL`, which defaults to 0. With it off, the DLL
behaves like stock VP 5.4.8.

Gameplay and AI aren't changed. This is a communication channel only.

## Credits

- **John Chen ([CIVITAS-John](https://github.com/CIVITAS-John)) and the
  [Vox Deorum](https://github.com/vox-deorum/vox-deorum) project** wrote the connection service:
  `CvConnectionService.*`, `CvConnectionSchema.*`, the event forwarding, `Game.RegisterFunction` / `CallExternal`
  and the pipe protocol. This branch ports it from their DLL fork
  [CIVITAS-John/vox-populi](https://github.com/CIVITAS-John/vox-populi) (branch `vox-deorum-5.2`, commit
  `f930310c`, based on VP 5.2) to VP 5.4.8. The protocol is documented in their repository at
  `docs/developers/civ5-dll/connection.md`.
- **The Community Patch / Vox Populi team** ([LoneGazebo/Community-Patch-DLL](https://github.com/LoneGazebo/Community-Patch-DLL))
  for everything else in this repository. See `(1) Community Patch/Credits.txt` for the full list.
- **Benoît Blanchon, [ArduinoJson](https://arduinojson.org/)** (MIT): `ThirdPartyLibs/ArduinoJson.hpp`.
- **Alexander Chemeris, msinttypes** (BSD): `ThirdPartyLibs/msinttypes/`.
- **Firaxis Games / 2K**: Civilization V and the SDK source this DLL is built from. Not affiliated with or
  endorsed by them.
- Port to 5.4.8 by [Joeman4248](https://github.com/Joeman4248), with Claude (Anthropic).

## Licenses

The DLL source stays under this repository's license: GNU GPL v3 plus the Community Patch EULA (`License.rtf`).
Never sell it or pass it off as your own. ArduinoJson (MIT) and msinttypes (BSD) keep their own notices in their
headers.

The main Vox Deorum repository (prompts, docs, the rest of their system) is a separate project under
CC BY-NC-SA 4.0. Nothing from it is included here beyond the DLL code from their GPL DLL fork.

## What this branch changes

Three commits on top of the tag `Release-5.4.8`:

1. **Port Vox Deorum connection service to VP 5.4.8**
   - `CvConnectionService.cpp/.h` and `CvConnectionSchema.cpp/.h`: a pipe server on
     `\\.\pipe\tmp-app.vox-deorum-bridge` (or env `VOX_DEORUM_PIPE_NAME`), with JSON messages separated by
     `!@#$%^!`.
   - `Lua/CvLuaSupport.cpp`: every `GameEvents` hook is also sent to the pipe as a `game_event`, non-blocking,
     before Lua sees it.
   - `CvDealClasses.cpp`: a `DealMade` event (with the traded items), which has no Lua hook of its own.
   - `CvGame.cpp`: the service starts with a game, shuts down with it and handles incoming messages during the
     game update. It also stores an event counter in the save's SaveGameDB.
   - `Lua/CvLuaGame.cpp`: new Lua functions `Game.RegisterFunction`, `UnregisterFunction`, `CallExternal`,
     `BroadcastEvent`, `ProcessConnectionMessages`, `IsExternalRegistered` and `GetCurrentTimeEpochMs`.
   - `CustomMods.*` and `NewCustomModOptions.xml`: the `IPC_CHANNEL` option.
   - `ThirdPartyLibs/`: ArduinoJson and msinttypes. Project files and clang build scripts updated.
2. **CI: download SDKs with curl.exe.** The workflow's `wget.exe` download came out corrupt on GitHub's runners.
3. **Drop the SetVoxDeorumMode call.** Vox Deorum uses it to hide VP's error dialogs; this build keeps them.

**Left out of Vox Deorum on purpose:** its reinforcement-learning capture, its tactical AI and flavor changes,
player pausing and `SetVoxDeorumMode`.

## Build

```
gh workflow run build_vp.yml -R <your fork> --ref vox-ipc-5.4.8
```

**Use the MSVC artifact (`VP_MSVC_Release_*`).** The clang release build doesn't load: GameCore.log shows
"LoadLibrary failed with error 1114" and the game crashes before the main menu. Vox Deorum hit the same problem
and turned clang optimizations off.

## Install

1. Back up the stock `CvGameCore_Expansion2.dll` in `(1) Community Patch` (and the copy in a modpack, if you use
   one).
2. Copy in the built DLL and update its md5 in `(1) Community Patch`'s `.modinfo`.
3. Set `<Row Class="3" Name="IPC_CHANNEL" Value="1"/>` in
   `(1) Community Patch/Database Changes/NewCustomModOptions.xml`. In a modpack, the database comes from
   `Override/CIV5Units.xml`, so change the row there.
4. Load a game. The pipe `\\.\pipe\tmp-app.vox-deorum-bridge` should exist.

To undo, restore the stock DLL and md5. Saves stay compatible either way: the service only writes its event
counter, and only while `IPC_CHANNEL` is on.

## Using it safely

- **Don't use the `lua_execute` message.** It runs code on the game's core Lua state, which all mods share, and a
  test script there crashed the game. Have a UI mod register a function with `Game.RegisterFunction` and call it
  with `lua_call`.
- VP's DLL crashes the game when a game function gets an out-of-range enum (-1 / `NO_*` / `NUM_*`), and `pcall`
  can't catch it.

## Updating to a new VP release

Rebase this branch onto the new `Release-*` tag, fix conflicts (usually `CvGame.cpp`, `CvLuaSupport.cpp` and the
project files), build with MSVC, and check that a save loads and the pipe appears.
