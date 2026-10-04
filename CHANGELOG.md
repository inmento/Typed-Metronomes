## 2026-10-04 — Gen1Recomp 0.3.51 compatibility refresh

- Updated the manifest engine requirement to `>=0.3.51` for the current Mod API 2 runtime.
- Revalidated the existing public hook/registry surface without changing gameplay behavior, assets, save formats, or progression rules.
- This entry is a compatibility maintenance update; install the matching release build before testing.

# Changelog

## 0.2.0 — Native Crystal support

Typed Metronomes now supports **Pokémon Crystal** on Gen1Recomp `0.2.24` and later. Crystal follows the established Gen 2 route for Type Academy Mart insertion, TM51–TM68 registration, Gen 2 move pools, and the typed-only primary-type Curse wrapper; no Gold/Silver behavior or typed-move rule changed.

The integration suite now executes the full Gen 2 scenario under both `gold` and `crystal` identifiers. It verifies Crystal’s Gen 2 items, type learnability, Violet Mart shelf, Curse override and Ghost-primary behavior, and ordinary-Mart exclusion. The release bundles no Crystal ROM data or assets.

## 0.1.0 — Initial release

**Typed Metronomes** introduces new numbered TM-style moves that call random moves from a selected type pool while preserving the engine’s ordinary move-resolution behavior. The release adds TM51–TM65 to Generation 1 and TM51–TM68 to Generation 2, with primary-or-secondary type eligibility and a Type Academy shelf at Pewter City Poké Mart or Violet City Poké Mart respectively.

The initial release excludes original Metronome and every Typed Metronome move from all pools, includes Struggle only in the Generation 1 Normal pool while retaining its native typeless damage, and includes Curse once in every Generation 2 pool. A Curse called by a Typed Metronome follows the requested primary-type Ghost rule; native Curse outside this mod remains unchanged.

The implementation and test suite also preserve native TM learning, duplicate-move refusal, party selection, move replacement, item consumption, damage, animation, status, and special-effect resolution rather than replacing them with a custom battle shortcut.
