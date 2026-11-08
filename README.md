# Community-Patch-DLL

## This fork: the IPC build (branch `vox-ipc-5.4.8`)

This is Joeman4248's fork of the Vox Populi DLL. Branch `vox-ipc-5.4.8` is **VP 5.4.8 with
[Vox Deorum](https://github.com/vox-deorum/vox-deorum)'s connection service ported in**: an optional named-pipe
channel that lets a program on the same PC receive the game's events and call Lua functions that mods register,
for example to connect an AI assistant or other tools to a running game.

- **Off by default.** Nothing changes unless the mod option `IPC_CHANNEL` is set to 1. Gameplay and AI are stock VP
  5.4.8 either way.
- **Credit:** the connection service was written by **John Chen ([CIVITAS-John](https://github.com/CIVITAS-John))
  and the Vox Deorum project**, ported here from their DLL fork
  [CIVITAS-John/vox-populi](https://github.com/CIVITAS-John/vox-populi). Everything else is the
  [Community Patch / Vox Populi team](https://github.com/LoneGazebo/Community-Patch-DLL)'s work.
- **Build with MSVC** (GitHub Actions `build_vp.yml`, artifact `VP_MSVC_Release_*`). The clang build doesn't load
  in game.
- **License:** GPL v3 plus the Community Patch EULA, like upstream.

### What changed from VP 5.4.8

See every line: [compare `Release-5.4.8` → `vox-ipc-5.4.8`](https://github.com/Joeman4248/Community-Patch-DLL/compare/Release-5.4.8...vox-ipc-5.4.8).

| File(s) | Change | Written by |
|---|---|---|
| `CvConnectionService.cpp/.h`, `CvConnectionSchema.cpp/.h` (new) | Named-pipe server, JSON messages, `lua_call`, event forwarding | John Chen / Vox Deorum (ported) |
| `Lua/CvLuaSupport.cpp` | Every `GameEvents` hook is also sent to the pipe | John Chen / Vox Deorum (ported) |
| `Lua/CvLuaGame.cpp/.h` | New `Game.RegisterFunction`, `CallExternal`, `BroadcastEvent` and related functions | John Chen / Vox Deorum (ported) |
| `CvDealClasses.cpp` | `DealMade` event sent to the pipe | John Chen / Vox Deorum (ported) |
| `CvGame.cpp` | Starts and stops the service; handles messages during the game update; event counter in saves | John Chen / Vox Deorum (ported) |
| `CustomMods.*`, `NewCustomModOptions.xml` | `IPC_CHANNEL` option (default 0) that switches all of it on | Joeman4248 |
| `ThirdPartyLibs/ArduinoJson.hpp`, `ThirdPartyLibs/msinttypes/` (new) | JSON library and `stdint.h` for the old MSVC toolset | Benoît Blanchon (MIT); Alexander Chemeris (BSD) |
| `VoxPopuli.vcxproj*`, `build_vp_clang*.py` | New sources added to the builds | Joeman4248 |
| `.github/workflows/build_vp.yml` | Download SDKs with `curl.exe` (the `wget.exe` download was corrupt) | Joeman4248 |
| `README.md`, `VOX-IPC.md` | This documentation | Joeman4248 |

**Not ported from Vox Deorum, on purpose:** its reinforcement-learning capture, tactical AI and flavor changes,
player pausing, and `SetVoxDeorumMode` (which hides VP's error dialogs).

**Full details:** [VOX-IPC.md](VOX-IPC.md) covers credits, licenses, what changed, what was left out, building,
installing and updating.

The original Vox Populi README follows.

---

This is the repository for the Civ V SDK + Vox Populi Mod. 

## What is Vox Populi

Started in 2014, Vox Populi (formerly known as the "Community Balance Patch/Overhaul") is a collaborative effort to improve Civilization V's AI and gameplay. It consists of a collection of mods (see below) that are designed to work together seamlessly.

* The Community Patch (CP) is the base mod
	* Contains the gamecore DLL, which is based on C++ code linked against the official Civ V SDK
    * Contains bugfixes (also for multiplayer), performance improvements and many AI enhancements, but minimal gameplay changes
    * Can be used standalone and is the basis for many other mods
* Vox Populi
	* Expands and changes the core mechanics of the game, offering an entirely new Civilization V experience that feels and plays like an evolution of the series
	* Includes City-State Diplomacy by Gazebo, Civ 4 Diplomacy Features by Putmalk and More Luxuries by Barathor
* EUI (optional)
	* Enhanced User Interface

## Where can I learn more

Check out the [forum](https://forums.civfanatics.com/forums/community-patch-project.497/). 

## How can I play this

* You need the latest version of Civilization V (1.0.3.279) with all expansions and DLC.
* [This thread](https://forums.civfanatics.com/threads/community-patch-how-to-install.528034/) on CivFanatics contains a link to the latest release, along with installation instructions.
* You may also download the automatic installer for your desired version from the [Releases page](https://github.com/LoneGazebo/Community-Patch-DLL/releases).

## Development and debugging

See `DEVELOPMENT.md` file for more information.