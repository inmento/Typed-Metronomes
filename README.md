# Typed Metronomes

**Typed Metronomes** adds a new family of numbered TM-style moves for Gen1Recomp’s Generation 1 and Generation 2 games. A typed Metronome calls a random move from its assigned type pool, then delegates that move to the game’s normal battle resolver. The called move therefore retains its ordinary accuracy, damage, animation, secondary effect, targeting, charge/recharge, recoil, and type interactions.

The mod is available for **Red, Blue, Yellow, Gold, and Silver** on Gen1Recomp `0.2.19` or later. It requires no ROM import beyond the game already loaded by Gen1Recomp and includes no game art, audio, or ROM-derived assets.

## Type Academy locations

Typed Metronomes are sold individually for **₽3,000**. The Type Academy shelf is appended to the ordinary shop inventory, so standard supplies remain available.

| Game generation | Location | Access |
|---|---|---|
| Gen 1 | **Pewter City Poké Mart** | As soon as Pewter City is reached |
| Gen 2 | **Violet City Poké Mart** | As soon as Violet City is reached |

They are ordinary single-use TMs. Use one from the Bag or Pack, select an eligible party Pokémon, and complete the native learn/forget-move flow. A TM is consumed only after the Pokémon successfully learns its move.

## TM catalogue

The compact learned move names fit the native move list. Generation 1 carries TM51–TM65; Generation 2 also includes TM66–TM68.

| TM | Type | Learned move | Gen 1 | Gen 2 |
|---:|---|---|:---:|:---:|
| TM51 | Normal | `N-METRO` | Yes | Yes |
| TM52 | Fighting | `FIGHT-METRO` | Yes | Yes |
| TM53 | Flying | `FLY-METRO` | Yes | Yes |
| TM54 | Poison | `POIS-METRO` | Yes | Yes |
| TM55 | Ground | `GND-METRO` | Yes | Yes |
| TM56 | Rock | `ROCK-METRO` | Yes | Yes |
| TM57 | Bug | `BUG-METRO` | Yes | Yes |
| TM58 | Ghost | `GHOST-METRO` | Yes | Yes |
| TM59 | Fire | `FIRE-METRO` | Yes | Yes |
| TM60 | Water | `WATER-METRO` | Yes | Yes |
| TM61 | Grass | `GRASS-METRO` | Yes | Yes |
| TM62 | Electric | `ELEC-METRO` | Yes | Yes |
| TM63 | Psychic | `PSY-METRO` | Yes | Yes |
| TM64 | Ice | `ICE-METRO` | Yes | Yes |
| TM65 | Dragon | `DRGN-METRO` | Yes | Yes |
| TM66 | Dark | `DARK-METRO` | No | Yes |
| TM67 | Steel | `STEEL-METRO` | No | Yes |
| TM68 | ??? | `Q-METRO` | No | Yes |

> **TM68 and vanilla Gold/Silver:** Gold/Silver has the `???` move type but no ordinary `???`-type Pokémon. TM68 is included for complete type coverage and becomes teachable automatically if another active content mod adds an eligible `???`-type species.

## Learning eligibility

A Pokémon can learn a typed Metronome when **either its primary or secondary type** matches the TM’s type. This does not depend on whether that Pokémon could learn any particular move that the TM may call. The mod appends only its own moves to each matching species’ effective machine list; it leaves every native and other-mod TM/HM permission intact.

## Random-move pools

Pools are built from the active game’s current move data when the move is used. This allows the mod to follow active move additions and move-type edits from compatible content mods.

| Rule | Behavior |
|---|---|
| Type restriction | The move picks only a move whose declared type matches the taught typed Metronome. |
| Original Metronome | `METRONOME` is excluded from every pool. |
| Typed Metronomes | All `TYPE_METRO_*` moves are excluded from every pool, preventing recursive calls. |
| Gen 1 Struggle | `STRUGGLE` is included only in the Normal pool. Its native typeless-damage behavior is unchanged. |
| Gen 2 Curse | `CURSE` appears once in **every** typed pool. |
| Normal resolution | Every selected move re-enters the game’s normal move pipeline rather than using a simplified replacement effect. |

## Gen 2 Curse rule

Native Gold/Silver Curse treats a Pokémon as a Ghost user when either of its types is Ghost. **Only when Curse is called by a Typed Metronome**, this mod applies the requested primary-type rule:

| User’s type order | Typed-Metronome Curse branch |
|---|---|
| Ghost / Poison | Ghost Curse: half maximum HP is paid and the target is cursed. |
| Poison / Ghost | Non-Ghost Curse: Speed falls while Attack and Defense rise. |

Normal Curse outside a Typed Metronome is not changed.

## Compatibility and limits

The mod uses `engine_internals` only for narrow wrappers around the existing shop and Gen 2 Curse paths. It does not modify maps, map object positions, save layouts, native move records, battle damage formulas, or ROM assets. It is designed to compose with mods that add species or moves: matching species may learn their matching typed TM, and newly added moves of an existing type can enter that type’s pool.

As with any mod that alters battle content, all participants in a link session should use the same enabled-mod set and version.

## Testing

The release suite covers the numbered TM records, Gen1/Gen2 scope, type eligibility, native TM consumption conditions, Type Academy shop targeting, active-data move pools, original/typed Metronome exclusion, Gen 1 Normal Struggle, Gen 2 Curse in every pool, and Ghost-primary versus Ghost-secondary Curse resolution. It should still receive ordinary in-game testing across party learning, shop purchases, and representative battle effects.

## Installation

1. Download the release ZIP from the project’s **Releases** page.
2. Import it through the Gen1Recomp launcher or place the ZIP in the supported mod-import flow for your platform.
3. Enable **Typed Metronomes** for the game you are playing.
4. Visit the matching Type Academy location and purchase the desired TM.

## License

This project is released under the [MIT License](LICENSE).
