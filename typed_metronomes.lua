-- Typed Metronomes: pure content and battle-selection rules.
-- This module deliberately owns no save state and never mutates native move data.

local TypedMetronomes = {}

TypedMetronomes.PRICE = 3000
TypedMetronomes.GEN1_MART_MAP = "PEWTER_MART"
TypedMetronomes.GEN2_MART_MAP = "VIOLET_MART"

local CATALOGUE = {
  { number = 51, type = "NORMAL",     move = "TYPE_METRO_NORMAL",   short = "N-METRO" },
  { number = 52, type = "FIGHTING",   move = "TYPE_METRO_FIGHTING", short = "FIGHT-METRO" },
  { number = 53, type = "FLYING",     move = "TYPE_METRO_FLYING",   short = "FLY-METRO" },
  { number = 54, type = "POISON",     move = "TYPE_METRO_POISON",   short = "POIS-METRO" },
  { number = 55, type = "GROUND",     move = "TYPE_METRO_GROUND",   short = "GND-METRO" },
  { number = 56, type = "ROCK",       move = "TYPE_METRO_ROCK",     short = "ROCK-METRO" },
  { number = 57, type = "BUG",        move = "TYPE_METRO_BUG",      short = "BUG-METRO" },
  { number = 58, type = "GHOST",      move = "TYPE_METRO_GHOST",    short = "GHOST-METRO" },
  { number = 59, type = "FIRE",       move = "TYPE_METRO_FIRE",     short = "FIRE-METRO" },
  { number = 60, type = "WATER",      move = "TYPE_METRO_WATER",    short = "WATER-METRO" },
  { number = 61, type = "GRASS",      move = "TYPE_METRO_GRASS",    short = "GRASS-METRO" },
  { number = 62, type = "ELECTRIC",   move = "TYPE_METRO_ELECTRIC", short = "ELEC-METRO" },
  -- Both the type-chart registry and active Red/Gold move/species data use
  -- PSYCHIC_TYPE as the canonical Psychic identifier.
  { number = 63, type = "PSYCHIC_TYPE", move = "TYPE_METRO_PSYCHIC", short = "PSY-METRO" },
  { number = 64, type = "ICE",        move = "TYPE_METRO_ICE",      short = "ICE-METRO" },
  { number = 65, type = "DRAGON",     move = "TYPE_METRO_DRAGON",   short = "DRGN-METRO" },
  { number = 66, type = "DARK",       move = "TYPE_METRO_DARK",     short = "DARK-METRO", gen2 = true },
  { number = 67, type = "STEEL",      move = "TYPE_METRO_STEEL",    short = "STEEL-METRO", gen2 = true },
  { number = 68, type = "CURSE_TYPE", move = "TYPE_METRO_CURSE",    short = "Q-METRO", gen2 = true },
}

TypedMetronomes.CATALOGUE = CATALOGUE

local byMove, byType = {}, {}
for _, row in ipairs(CATALOGUE) do
  row.item = ("TYPE_TM%02d"):format(row.number)
  byMove[row.move] = row
  byType[row.type] = row
end
TypedMetronomes.byMove = byMove
TypedMetronomes.byType = byType

function TypedMetronomes.isGen2(generation)
  return generation == 2
end

function TypedMetronomes.entries(generation)
  local out = {}
  for _, row in ipairs(CATALOGUE) do
    if generation == 2 or not row.gen2 then out[#out + 1] = row end
  end
  return out
end

function TypedMetronomes.isTypedMove(moveId)
  return byMove[moveId] ~= nil
end

function TypedMetronomes.entryForMove(moveId)
  return byMove[moveId]
end

function TypedMetronomes.itemRecord(row, generation)
  local record = {
    id = row.item,
    name = ("TM%02d"):format(row.number),
    price = TypedMetronomes.PRICE,
    tossable = true,
    machine = { kind = "TM", move = row.move, number = row.number },
  }
  if generation == 2 then
    -- Gold/Silver Pack fields.  Top-level item records deliberately retain
    -- generation-specific metadata that the shared schema does not own.
    record.pocket = "TM_HM"
    record.tmNumber = row.number + 7 -- native Gen 2's seven HMs occupy 51–57 internally
    record.tmLabel = ("TM%02d"):format(row.number)
    record.teaches = row.move
  end
  return record
end

function TypedMetronomes.moveRecord(row, generation)
  return {
    id = row.move,
    name = row.short,
    type = row.type,
    power = 0,
    accuracy = 100,
    pp = 10,
    category = "status",
    effect = "TYPE_METRONOME_EFFECT",
    -- Existing Metronome animation assets are used by the engine; no game art
    -- is packaged by this mod.
    anim = "METRONOME",
  }
end

function TypedMetronomes.matchesType(types, wanted)
  for _, typeId in ipairs(types or {}) do
    if typeId == wanted then return true end
  end
  return false
end

function TypedMetronomes.primaryType(types)
  return types and types[1] or nil
end

local function contains(list, value)
  for _, entry in ipairs(list) do if entry == value then return true end end
  return false
end

-- Builds an explicit, deterministic pool from the active merged game data.
-- `moveOrder` is authoritative when present so RNG is stable for a given game;
-- unknown mod-added moves are appended in ID order afterward.
function TypedMetronomes.pool(data, row, generation)
  local moves = (data and data.moves) or {}
  local constants = (data and data.constants) or {}
  local order = constants.moveOrder or moves.order or {}
  local pool, seen = {}, {}

  local function add(moveId)
    if seen[moveId] then return end
    local def = moves[moveId]
    if not def then return end
    if moveId == "METRONOME" or TypedMetronomes.isTypedMove(moveId) then return end
    if def.type ~= row.type then return end
    seen[moveId] = true
    pool[#pool + 1] = moveId
  end

  for _, moveId in ipairs(order) do add(moveId) end

  local extras = {}
  for moveId in pairs(moves) do
    if type(moveId) == "string" and not seen[moveId] then extras[#extras + 1] = moveId end
  end
  table.sort(extras)
  for _, moveId in ipairs(extras) do add(moveId) end

  -- Struggle has Normal metadata but engine-defined typeless damage. It is
  -- intentionally eligible only in the Normal typed pool when present.
  if generation ~= 2 and row.type == "NORMAL" and moves.STRUGGLE
      and not seen.STRUGGLE then
    seen.STRUGGLE = true
    pool[#pool + 1] = "STRUGGLE"
  end

  -- Curse is a special engine type but is intentionally eligible once in every
  -- Gen 2 typed pool. It is added after the normal type-filter pass.
  if generation == 2 and moves.CURSE and not seen.CURSE then
    seen.CURSE = true
    pool[#pool + 1] = "CURSE"
  end

  return pool
end

function TypedMetronomes.pick(data, row, generation, rng)
  local pool = TypedMetronomes.pool(data, row, generation)
  if #pool == 0 then return nil end
  if generation == 2 then
    -- Gold's battle RNG returns 0..n-1.
    return pool[(rng and rng(#pool) or 0) + 1]
  end
  -- Gen 1's battle RNG returns inclusive a..b.
  return pool[rng and rng(1, #pool) or 1]
end

-- Only a Curse called by this mod uses primary-type semantics. Native Curse
-- keeps the engine's default "either type is Ghost" behavior.
function TypedMetronomes.curseUsesGhostPrimary(types)
  return TypedMetronomes.primaryType(types) == "GHOST"
end

function TypedMetronomes.appendOnce(list, value)
  list = list or {}
  if not contains(list, value) then list[#list + 1] = value end
  return list
end

return TypedMetronomes
