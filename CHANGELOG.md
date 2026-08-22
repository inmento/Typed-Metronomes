# Changelog

## 0.1.0 — Initial release

**Typed Metronomes** introduces new numbered TM-style moves that call random moves from a selected type pool while preserving the engine’s ordinary move-resolution behavior. The release adds TM51–TM65 to Generation 1 and TM51–TM68 to Generation 2, with primary-or-secondary type eligibility and a Type Academy shelf at Pewter City Poké Mart or Violet City Poké Mart respectively.

The initial release excludes original Metronome and every Typed Metronome move from all pools, includes Struggle only in the Generation 1 Normal pool while retaining its native typeless damage, and includes Curse once in every Generation 2 pool. A Curse called by a Typed Metronome follows the requested primary-type Ghost rule; native Curse outside this mod remains unchanged.

The implementation and test suite also preserve native TM learning, duplicate-move refusal, party selection, move replacement, item consumption, damage, animation, status, and special-effect resolution rather than replacing them with a custom battle shortcut.
