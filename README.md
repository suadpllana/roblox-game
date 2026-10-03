# Steal a Plushie 🧸😈

A Roblox **"Steal a ___"** base tycoon. Buy cute plushies from a conveyor belt.
Each one earns cash every second, even while you're offline. Sneak into other
players' bases to steal their best plushies, and lock your own base so nobody
steals yours.

All of the game is code in this repo. The map, models, UI, saving and Robux
shop are generated at runtime, so you don't need to build anything by hand.

---

## Why this idea?

| Signal | What it means |
|---|---|
| *Steal a Brainrot* set the all-time concurrent player record for any video game (25.8M CCU, Oct 2025) | The "buy → earn → steal" loop is the strongest proven loop on Roblox right now |
| *Steal An Egg* launched **July 2026** and still runs at 1–3M+ concurrent players | The format still works with a **new theme**. It isn't played out. |
| Simulators/tycoons are the highest-grossing Roblox genre; mid-tier ones earn **$3k–$20k/month** | The genre makes money, and solo devs can build it |
| Pet / collectible games earn **$5k–$50k/month** mid-tier | Collectibles with rarities keep players spending |
| *Grow a Garden*-style offline progress drives daily return visits | Players come back daily, which keeps income steady |

Most clones use the "brainrot" meme. **Plushies** are a fresh, kid-friendly,
merch-able theme that appeals to more players. The catalog lives in one file
(`src/shared/Plushies.luau`), so you can **reskin it to whatever meme is trending
in a few minutes**. In this genre, timing matters more than polish.

### What's in it

- **Conveyor of 21 plushies** across 7 rarities (Common → Secret). Mythic and Secret spawns are announced to the whole server
- **Mutations:** Gold (2x), Diamond (3x), Rainbow (5x, animated)
- **Stealing:** hold E on someone's plushie, carry it over your head (you move slower) and run it home. The owner can **touch you** or anyone can **Bonk** you with the bat to make you drop it
- **Base lock:** 60s laser barrier that only you can pass through. Intruders get pushed out
- **Rebirths:** permanent cash multiplier and extra slots
- **Offline earnings**, a **7-day daily streak** (day 7 = free Mystery Box), **friend bonus** (+10% per friend in the server), optional **group bonus**
- **Global leaderboard**, sell plushies (hold F), new-player steal protection
- **Saving:** session-locked DataStore with retries, autosave and safe shutdown. Purchases are never lost or granted twice

### How it makes money (7 game passes + 6 developer products)

| Game passes (one-time) | R$ | Developer products (repeatable) | R$ |
|---|---|---|---|
| 👑 VIP (+25% cash, chat tag) | 199 | 💵 Pile of Cash (5 min of income) | 25 |
| 💰 2x Cash | 299 | 💰 Bag of Cash (20 min) | 79 |
| 🧲 Auto Collect | 99 | 🏦 Vault of Cash (1 h) | 199 |
| 📦 +6 Base Slots | 149 | 🍀 **2x Server Luck** (15 min, whole server, stacks) | 99 |
| 🔒 Super Lock (2x lock time) | 99 | 🎁 Mystery Plushie Box (Epic+) | 129 |
| 🌙 Offline Earnings+ | 129 | 🛡️ Steal Shield (30 min) | 49 |
| ⚡ Speed Boost | 79 | | |

Cash packs scale with each player's income, so they stay worth buying at
every stage. Server Luck is announced with the buyer's name, so buying it is
public, and that tends to get other players buying too. You also get
**Premium Payouts** automatically (Premium players get +10% cash, which
encourages them to keep playing).

---

## ✅ What YOU need to do (about 30–60 minutes)

> **Do I need to connect to Roblox Studio?** No. I can't control Studio,
> and you don't need me to. The whole game is already built into one
> file: **`build/StealAPlushie.rbxlx`**. You open it, test it, and click Publish.

### 1. Open and test the game
1. Install **Roblox Studio**: <https://create.roblox.com/> → *Start Creating*.
2. Download `build/StealAPlushie.rbxlx` from this repo (on GitHub: open the file → *Download raw file*).
3. In Studio: **File → Open from File…** → pick `StealAPlushie.rbxlx`.
4. Press **Play** (F5). You spawn in your base. Walk to the conveyor and press **E** on a plushie to buy it.
5. To test stealing: **Test tab → Clients and Servers → 2 Players → Start**.
6. Shop items are free in Studio while their IDs are `0`, so you can try every pass and product.

### 2. Publish
1. **File → Publish to Roblox** → *Create new experience* → name it (e.g. "Steal a Plushie 🧸").
2. **Home → Game Settings**:
   - **Security → Enable Studio Access to API Services**: ON (makes saving work when testing in Studio)
   - **Places → (your place) → Max Players: 8**. Important: there are 8 bases.
3. Publish again (**File → Publish to Roblox**).

### 3. Turn on Robux sales
1. Go to <https://create.roblox.com/dashboard/creations> → your experience → **Monetization**.
2. Under **Passes**, create the 7 passes from the table above (name, icon, price) and copy each **Pass ID**.
3. Under **Developer Products**, create the 6 products and copy each **Product ID**.
4. In Studio, open **ReplicatedStorage → Shared → Config** and paste each ID into the matching `Id = 0` field.
5. Publish again. Purchases are now real Robux.
6. *(Optional)* Create a Roblox group, put its ID in `Config.GroupId`, and group members get +10% cash. You can message group members later, which is a free way to bring players back.

### 4. Go public
1. On the Creator Dashboard: fill in the **Experience Questionnaire** (maturity rating), add an **icon** (512×512) and **thumbnails** (1920×1080). Your icon and thumbnails have the biggest effect on how many people click your game.
2. **Settings → Make Public**.

### 5. Get players
A good game with no traffic earns $0. What works in 2026:
- **Short videos** (TikTok / YouTube Shorts / Reels): "I stole a SECRET plushie 😱" type clips, 1–3 a day for the first few weeks
- **Roblox Ads** (Sponsored Experiences): start with a small budget and keep the best thumbnail
- **Weekly updates**: new plushies, events, limited-time mutations. The Roblox algorithm favors games that update often and keep players coming back
- Ask YouTubers or TikTokers who cover "Steal a" games to try it

### 6. Getting paid (DevEx)
You need to be **13+**, verify your ID, have **≥30,000 earned Robux**, and apply at
<https://create.roblox.com/dashboard/devex>. In 2026, earned Robux pays out at about
**$0.0038 each** (≈ $380 per 100k Robux).

> **Expectations:** most Roblox games never earn much. The ones that do have a strong
> loop (this one copies the best loop on the platform), get regular updates, and get
> marketed. Plan to promote it and add content for a few months. "Passive" income
> comes once the game has a steady player base.

---

## 🎨 Customizing

| Want to… | Edit |
|---|---|
| Change prices, passes, products, economy, timers | `src/shared/Config.luau` |
| Add / rename / rebalance plushies, rarities, mutations | `src/shared/Plushies.luau` |
| Use real 3D models | In Studio, create **ServerStorage → Folder `PlushieModels`** and put a Model in it named exactly like the plushie `Id` (e.g. `KingCorgi`). It replaces the built-in placeholder automatically. |
| Reskin to a new trend (e.g. "Steal a Dino") | Rename plushies in `Plushies.luau`, change `Config.GameName`, swap models |
| Map layout, colors, base size | `src/server/Services/MapBuilder.luau` |

---

## 🛠️ For developers (editing code with Rojo)

The repo is a [Rojo](https://rojo.space/) project:

```
src/shared/   -> ReplicatedStorage.Shared   (Config, Plushies catalog, Format, Remotes)
src/server/   -> ServerScriptService.Server (Main + Services/*)
src/client/   -> StarterPlayerScripts.Client (Main + UI/*)
```

- Live sync: install Rojo (`aftman install`, or the Rojo VS Code extension) and the
  Rojo Studio plugin, run `rojo serve`, then click **Connect** in the Studio plugin.
- Rebuild the place file: `rojo build default.project.json -o build/StealAPlushie.rbxlx`
- CI type-checks every push with `luau-lsp` and builds the place file as a downloadable artifact.

| Server service | Job |
|---|---|
| `DataService` | Load/save with session locking, autosave, receipts |
| `MapBuilder` | Generates the map, bases, conveyor, leaderboard, collision groups |
| `BaseService` | Base assignment, pedestals, sell, lock, collect pad |
| `ConveyorService` | Spawns and moves plushies, buying |
| `StealService` | Grab, carry, drop, and deliver steals |
| `EconomyService` | Income tick, multipliers, rebirths, HUD stats |
| `MonetizationService` | Game passes, developer products, ProcessReceipt |
| `RewardsService` | Offline earnings, daily streak, friend/group bonus |
| `CombatService` | Bonk Bat |
| `LeaderboardService` | Global richest-players board |
