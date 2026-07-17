# Setup & running

This repo is source-only (the durable, git-friendly way to build Roblox games).
There are two ways to get it into Roblox Studio.

## About that MCP command

The command you were given —
`claude mcp add ... cmd.exe /c cd %LOCALAPPDATA%\Roblox && mcp.bat` — connects
Claude to **Roblox Studio running on your own Windows PC**. It can't be run from
the cloud environment these files were authored in (that's Linux, with no Studio
and no access to your machine). So instead of poking Studio live, the game was
written as a proper Rojo project you sync in yourself. If you later run Claude
Code locally on Windows with that MCP server connected, it can drive Studio
directly — but you don't need it to play this.

## Option A — Rojo (recommended)

1. **Install Rojo**
   - Via [Aftman](https://github.com/LPGhatguy/aftman): `aftman add rojo-rbx/rojo` then `aftman install`
   - Or download from https://rojo.space and install the Roblox Studio plugin.

2. **Serve** from the repo root:
   ```bash
   rojo serve
   ```

3. In Studio: open a new **Baseplate**, open the **Rojo** plugin, click
   **Connect**. The `src/` tree syncs into `ReplicatedStorage`,
   `ServerScriptService`, and `StarterPlayerScripts`.

4. Press **Play**. The kitchen builds itself.

To build a `.rbxl` without a live session instead:
```bash
rojo build -o BlackoutBakery.rbxlx
```
then open that file in Studio.

## Option B — Paste it in by hand

If you don't want Rojo, mirror the tree manually in Studio:

- `ReplicatedStorage` → a Folder **BlackoutBakery** containing ModuleScripts
  `RecipeConfig`, `GameConfig`, `Net`, `DishMath`, `SoundConfig` (from `src/shared/`).
- `ServerScriptService` → a Folder **BlackoutBakery** containing:
  - `Bootstrap` as a **Script** (the file `Bootstrap.server.lua`; drop the `.server`).
  - `RoleManager`, `OrderManager`, `DishState`, `IngredientStation`,
    `OvenStation`, `TasteService`, `SubmitStation`, `KitchenBuilder` as **ModuleScripts**.
- `StarterPlayer → StarterPlayerScripts` → a Folder **BlackoutBakery** containing:
  - `ClientMain` as a **LocalScript** (the file `ClientMain.client.lua`; drop the `.client`).
  - `ClientTicketUI`, `ClientTasteUI`, `ClientHUD`, `ClientSound` as **ModuleScripts**.

The folder names and layout matter — the scripts `require` each other by path.

## Testing with 2+ players

The game needs at least 2 players (see `GameConfig.MinPlayers`). In Studio use
**Test → Clients and Servers**, set **2 players**, and **Start**. You'll get two
client windows plus a server window; ready up in both.

To poke around solo, temporarily set `GameConfig.MinPlayers = 1` — with one
player you'll be the Reader and the kitchen prompts stay hidden (that's correct
behavior), so bump it back to 2 to actually cook.

## Where to tune things

Everything lives in `src/shared/GameConfig.lua`: shift length, starting
reputation, patience, difficulty ramp, scoring, the bake step
(`RequireBake`, `BakeDuration`), and the `AllowDiscard` hard-fail/soft-fail
switch. Recipes and ingredients are in `src/shared/RecipeConfig.lua`, and every
sound effect is in `src/shared/SoundConfig.lua` (built-in Roblox sounds by
default — replace any `id` with a `rbxassetid://…` to use your own audio).
