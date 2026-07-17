# Blackout Bakery

A 2–4 player co-op baking game for Roblox. One player can **read** the order,
one can **cook**, one can **taste** — and *nobody has all the information*. You
have to talk to each other or the shift falls apart.

## The core idea (and why it's real security, not UI theater)

The whole game hangs on one rule: **the recipe never reaches a client that
isn't the Reader.** It is not hidden with a client-side check — the server
simply never fires the ticket event at anyone but the Reader:

```lua
-- src/server/OrderManager.lua
function OrderManager:refreshTicket()
    local reader = self.ctx.Roles:reader()
    if reader then
        self.ctx.Remotes.Ticket:FireClient(reader, self:snapshot())  -- Reader ONLY
    end
end
```

Cook and Taster clients are never a recipient, so there's no recipe data on
their machines to pull out of the dev console. Same principle applies to taste
hints (fired only at the Taster) and to every kitchen action, which the server
re-checks by role before doing anything (`src/server/IngredientStation.lua`,
`SubmitStation.lua`). The client-side prompt hiding in `ClientMain` is *only*
cosmetic — the server is the authority.

## Roles

| Role   | Can | Can't |
| ------ | --- | ----- |
| **Reader** | See the order tickets (names, ingredients, patience timers) | Interact with any bin, bowl, or oven — their prompts are gone |
| **Cook**   | Add ingredients, **bake in the oven**, scrap the bowl, serve the dish | See the ticket — there's no recipe data on their client at all |
| **Taster** | Taste the in-progress bowl for a fuzzy hint | See the ticket |

- 2 players → Reader + Cook
- 3 players → Reader + Cook + Taster
- 4 players → Reader + Cook + Taster + **second Cook** (kitchen gets busy)

Roles **rotate every round** so everyone plays all three across a session.

## Core loop

1. Lobby — players ready up.
2. Server assigns roles; a **countdown** starts the shift.
3. Orders spawn into a queue, each with a **patience timer**. The Reader sees
   them; the front order is "now serving".
4. Cook builds the dish; Taster tastes for hints; Reader relays the recipe.
5. Cook **bakes** the dish in the oven (it can't be served raw), then serves at
   the window — perfect / close / wrong is scored.
6. Shift ends when the **timer** runs out or **reputation** hits zero.
7. Summary screen → roles rotate → next round.

## Architecture

| Script | Type | Responsibility |
| ------ | ---- | -------------- |
| `RecipeConfig` | Shared Module | Dish + ingredient definitions (the shared, non-secret cookbook) |
| `GameConfig`   | Shared Module | All tuning knobs |
| `Net`          | Shared Module | RemoteEvent definitions + direction |
| `DishMath`     | Shared Module | Dish→recipe similarity scoring & diffs |
| `SoundConfig`  | Shared Module | Named sound effects (built-in `rbxasset://` defaults, swappable) |
| `RoleManager`  | Server | Assigns / rotates Reader, Cook, Taster |
| `OrderManager` | Server | Picks recipes, patience timers, **fires ticket to Reader only** |
| `DishState`    | Server | Tracks the in-progress dish + its bake state |
| `IngredientStation` | Server | ProximityPrompt triggers → role check → DishState / taste |
| `OvenStation`  | Server | The bake step: role check, timed bake, oven glow, bake sounds |
| `TasteService` | Server | Diffs dish vs recipe, fuzzy hint to Taster only |
| `SubmitStation`| Server | Scores final dish (must be baked), adjusts reputation, queues next order |
| `KitchenBuilder`| Server | Spawns the whole playable kitchen (incl. oven) at runtime |
| `Bootstrap`    | Server | Wires everything, sound helpers + runs the game loop |
| `ClientTicketUI` | Client | Renders tickets — only if the ticket event fired for you |
| `ClientTasteUI`  | Client | Renders taste hints |
| `ClientHUD`      | Client | Reputation, timer, score, role badge, bowl/bake state, lobby, summary |
| `ClientSound`    | Client | Plays 2D UI sounds driven by the Sfx remote |
| `ClientMain`     | Client | Routes remotes + local role-based prompt hiding (UX only) |

## Design decisions made

The spec left three open; here's what shipped (all flippable in `GameConfig`):

- **Fuzzy taste hints.** "It needs to be sweeter", "too much flour" — never a
  number. Funnier and harder to cheese than an exact diff.
- **Soft fail.** The Cook can scrap the bowl and restart (`AllowDiscard = true`).
  Set it `false` for hard-fail panic.
- **Labeled bins.** Bins show their ingredient name — friendlier to learn. The
  hidden-info challenge is the *recipe*, not the pantry layout.

## Audio

All sound effects are named in `src/shared/SoundConfig.lua` and default to
Roblox's **built-in `rbxasset://sounds/*`** files, so the game has audio the
moment it runs — no uploads, no moderation wait. Positional kitchen sounds
(adding ingredients, the oven, serving) are played server-side on the world
parts; flat UI sounds (countdown, taste, shift start/end) go through the `Sfx`
remote to `ClientSound`. Swap any `id` for your own `rbxassetid://…` to
reskin the audio.

## Running it

See [`docs/SETUP.md`](docs/SETUP.md). Short version: it's a [Rojo](https://rojo.space)
project — `rojo serve`, connect from the Studio plugin, press Play. The kitchen
builds itself, so a bare baseplate is all you need.

## Build order (from the spec) — all five stages are in here

1. ✅ Single-role prototype (ingredients → serve → score): `DishState`, `DishMath`, `SubmitStation`.
2. ✅ Role assignment + prompts gated by role: `RoleManager`, server-side checks.
3. ✅ Ticket/taste UI fired selectively, not broadcast: `OrderManager`, `TasteService`, `Net`.
4. ✅ Patience timers + reputation loss: `OrderManager`, `Bootstrap`.
5. ✅ Polish — role rotation, difficulty ramp, day-end summary: `Bootstrap`, `ClientHUD`.
