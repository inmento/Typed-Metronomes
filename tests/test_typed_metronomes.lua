local root = (... and ... ~= "" and ...) or "."
package.path = root .. "/?.lua;" .. root .. "/?/init.lua;" .. package.path

local Typed = require("typed_metronomes")

local function set(list)
  local out = {}
  for _, id in ipairs(list) do out[id] = true end
  return out
end

local data = {
  constants = {
    moveOrder = {
      "TACKLE", "THUNDERBOLT", "CURSE", "METRONOME", "STRUGGLE",
      "TYPE_METRO_NORMAL", "TYPE_METRO_ELECTRIC", "DARK_PULSE", "CONFUSION",
    },
  },
  moves = {
    TACKLE = { type = "NORMAL" },
    THUNDERBOLT = { type = "ELECTRIC" },
    CURSE = { type = "CURSE_TYPE" },
    METRONOME = { type = "NORMAL" },
    STRUGGLE = { type = "NORMAL" },
    TYPE_METRO_NORMAL = { type = "NORMAL" },
    TYPE_METRO_ELECTRIC = { type = "ELECTRIC" },
    DARK_PULSE = { type = "DARK" },
    CONFUSION = { type = "PSYCHIC_TYPE" },
    MOD_SPARK = { type = "ELECTRIC" },
  },
}

local normal = assert(Typed.byType.NORMAL)
local electric = assert(Typed.byType.ELECTRIC)
local ghost = assert(Typed.byType.GHOST)
local psychic = assert(Typed.byType.PSYCHIC_TYPE)

local gen1Normal = set(Typed.pool(data, normal, 1))
assert(gen1Normal.TACKLE, "Gen 1 Normal pool must include Normal moves")
assert(gen1Normal.STRUGGLE, "Gen 1 Normal pool must include Struggle")
assert(not gen1Normal.METRONOME, "original Metronome must never be callable")
assert(not gen1Normal.TYPE_METRO_NORMAL, "typed Metronomes must never recurse")
assert(not gen1Normal.CURSE, "Gen 1 has no cross-type Curse rule")

local gen1Electric = set(Typed.pool(data, electric, 1))
assert(gen1Electric.THUNDERBOLT and gen1Electric.MOD_SPARK,
  "pool must use active data, including added moves")
assert(not gen1Electric.STRUGGLE, "Struggle belongs only to Gen 1 Normal")
assert(not gen1Electric.TYPE_METRO_ELECTRIC, "typed move must not call itself")

local gen1Psychic = set(Typed.pool(data, psychic, 1))
assert(gen1Psychic.CONFUSION and Typed.matchesType({ "PSYCHIC_TYPE" }, psychic.type),
  "TM63 must use the engine's canonical PSYCHIC_TYPE in pools and eligibility")

local gen2Electric = set(Typed.pool(data, electric, 2))
assert(gen2Electric.THUNDERBOLT and gen2Electric.MOD_SPARK,
  "Gen 2 Electric pool must include matching active moves")
assert(gen2Electric.CURSE, "Gen 2 Curse must be eligible in every typed pool")
assert(not gen2Electric.METRONOME, "original Metronome remains excluded in Gen 2")
assert(not gen2Electric.TYPE_METRO_ELECTRIC, "Gen 2 typed Metronome recursion is excluded")

assert(Typed.matchesType({ "POISON", "GHOST" }, "GHOST"),
  "secondary types may learn matching typed TMs")
assert(not Typed.matchesType({ "POISON", "GHOST" }, "FIRE"),
  "nonmatching types must be ineligible")
assert(Typed.curseUsesGhostPrimary({ "GHOST", "POISON" }),
  "Ghost/Poison must receive typed-Metronome Ghost Curse")
assert(not Typed.curseUsesGhostPrimary({ "POISON", "GHOST" }),
  "Poison/Ghost must receive typed-Metronome non-Ghost Curse")

local tm = Typed.itemRecord(electric, 2)
assert(tm.id == "TYPE_TM62" and tm.name == "TM62" and tm.price == 3000,
  "Electric TM must be numbered and priced correctly")
assert(tm.machine.move == "TYPE_METRO_ELECTRIC" and tm.teaches == "TYPE_METRO_ELECTRIC",
  "Gen 2 item must expose machine and teaches fields")
assert(tm.pocket == "TM_HM" and tm.tmNumber == 69,
  "Gen 2 TM must have a noncolliding pack sort number")

local tm1 = Typed.itemRecord(ghost, 1)
assert(tm1.machine.number == 58 and tm1.teaches == nil,
  "Gen 1 uses native machine data without Gold-only metadata")

assert(#Typed.entries(1) == 15, "Gen 1 must expose TM51–TM65 only")
assert(#Typed.entries(2) == 18, "Gen 2 must expose TM51–TM68")
assert(Typed.pick(data, electric, 1, function(a, b) return a end) == "THUNDERBOLT",
  "Gen 1 picker must use inclusive battle RNG")
assert(Typed.pick(data, electric, 2, function() return 0 end) == "THUNDERBOLT",
  "Gen 2 picker must use zero-based battle RNG")

print("typed metronomes rules tests passed (25 assertions)")
