local root = (... and ... ~= "" and ...) or "."

local function registry(base)
  local entries, patches, overrides = {}, {}, {}
  local api = {}
  function api:register(id, value)
    assert(entries[id] == nil and (not base or base[id] == nil), "duplicate " .. id)
    entries[id] = value
    return value
  end
  function api:override(id, value)
    overrides[id] = value
    return value
  end
  function api:patch(id, value)
    patches[id] = patches[id] or {}
    patches[id][#patches[id] + 1] = value
    local record = (base and base[id]) or entries[id]
    if record and value.tmhm and value.tmhm.__append then
      record.tmhm = record.tmhm or {}
      for _, move in ipairs(value.tmhm.__append) do
        local seen = false
        for _, old in ipairs(record.tmhm) do if old == move then seen = true end end
        if not seen then record.tmhm[#record.tmhm + 1] = move end
      end
    end
    return value
  end
  function api:get(id)
    return overrides[id] or entries[id] or (base and base[id])
  end
  function api:each()
    local ids, seen = {}, {}
    for id in pairs(base or {}) do ids[#ids + 1], seen[id] = id, true end
    for id in pairs(entries) do
      if not seen[id] then ids[#ids + 1] = id end
    end
    local index = 0
    return function()
      index = index + 1
      local id = ids[index]
      if not id then return nil end
      return id, api:get(id)
    end
  end
  api.entries, api.patches, api.overrides = entries, patches, overrides
  return api
end

local function has(list, needle)
  for _, value in ipairs(list or {}) do if value == needle then return true end end
  return false
end

local function makeMod(species)
  local moves = registry({})
  local items = registry({})
  local effects = registry({
    EFFECT_CURSE = { kind = "primary", run = function() return "native curse" end },
  })
  local pokemon = registry(species)
  return {
    content = {
      moves = moves, items = items, move_effects = effects,
      pokemon = pokemon,
    },
    log = { info = function() end },
  }
end

local function clearModules()
  for name in pairs(package.loaded) do
    if name:match("^mods%.typed_metronomes")
        or name == "src.core.GameVersion"
        or name == "src.ui.ShopMenu"
        or name == "src.ui.gen2.MartMenu"
        or name == "src.battle.gen2.Effects" then
      package.loaded[name] = nil
    end
  end
end

local function runGen1()
  clearModules()
  local ShopMenu = {}
  ShopMenu.new = function(_, stock) return { stock = stock } end
  package.preload["src.core.GameVersion"] = function()
    return { get = function() return "red" end, generation = function() return 1 end }
  end
  package.preload["src.ui.ShopMenu"] = function() return ShopMenu end
  package.preload["mods.typed_metronomes.typed_metronomes"] = function()
    return dofile(root .. "/typed_metronomes.lua")
  end

  local species = {
    PIKACHU = { types = { "ELECTRIC" }, tmhm = { "THUNDER" } },
    GENGAR = { types = { "GHOST", "POISON" }, tmhm = {} },
    RATTATA = { types = { "NORMAL" }, tmhm = {} },
  }
  local mod = makeMod(species)
  assert(dofile(root .. "/main.lua"))(mod)

  assert(mod.content.items.entries.TYPE_TM51 and mod.content.items.entries.TYPE_TM65,
    "Gen 1 must register TM51–TM65")
  assert(not mod.content.items.entries.TYPE_TM66, "Gen 1 must not register Dark TM")
  assert(has(species.PIKACHU.tmhm, "TYPE_METRO_ELECTRIC"),
    "matching primary type must learn its typed TM")
  assert(has(species.GENGAR.tmhm, "TYPE_METRO_GHOST")
      and has(species.GENGAR.tmhm, "TYPE_METRO_POISON"),
    "dual type must learn both matching typed TMs")
  assert(not has(species.RATTATA.tmhm, "TYPE_METRO_FIRE"),
    "nonmatching type must not receive unrelated typed TM")

  local pewter = ShopMenu.new({ overworld = { map = { id = "PEWTER_MART" } } }, { "POTION" })
  assert(has(pewter.stock, "TYPE_TM51") and has(pewter.stock, "TYPE_TM65"),
    "Pewter Mart must receive the Gen 1 Type Academy shelf")
  local other = ShopMenu.new({ overworld = { map = { id = "VIRIDIAN_MART" } } }, { "POTION" })
  assert(not has(other.stock, "TYPE_TM51"), "other Gen 1 Marts must remain unchanged")
end

local function runGen2()
  clearModules()
  local MartMenu = {}
  MartMenu.new = function(_, opts)
    return { martType = opts.martType or "STANDARD", entries = {
      { id = "POTION", name = "POTION", price = 300 },
    } }
  end
  package.preload["src.core.GameVersion"] = function()
    return { get = function() return "gold" end, generation = function() return 2 end }
  end
  package.preload["src.ui.gen2.MartMenu"] = function() return MartMenu end
  package.preload["src.battle.gen2.Effects"] = function() return { MAX_STAGE = 6 } end
  package.preload["mods.typed_metronomes.typed_metronomes"] = function()
    return dofile(root .. "/typed_metronomes.lua")
  end

  local species = {
    PIKACHU = { types = { "ELECTRIC" }, tmhm = {} },
    GENGAR = { types = { "GHOST", "POISON" }, tmhm = {} },
    RATTATA = { types = { "NORMAL" }, tmhm = {} },
  }
  local mod = makeMod(species)
  assert(dofile(root .. "/main.lua"))(mod)

  assert(mod.content.items.entries.TYPE_TM68,
    "Gen 2 must register the ??? typed TM")
  assert(mod.content.items.entries.TYPE_TM62.teaches == "TYPE_METRO_ELECTRIC",
    "Gold custom TM must expose its taught move")
  assert(has(species.GENGAR.tmhm, "TYPE_METRO_GHOST")
      and has(species.GENGAR.tmhm, "TYPE_METRO_POISON"),
    "Gold dual type must receive both typed TM learnability entries")
  assert(mod.content.move_effects.overrides.EFFECT_CURSE,
    "Gold must wrap Curse only for the typed-call semantic")

  local curse = mod.content.move_effects.overrides.EFFECT_CURSE.run
  local function curseBattle(types)
    local events, stageChanges = {}, {}
    local attacker = { species = "TEST", hp = 40, maxHp = 40 }
    local defender = { species = "TARGET", hp = 50, maxHp = 50 }
    local battle = {
      _typedMetronomeCurseDepth = 1,
      stages = { player = { attack = 0, defense = 0, speed = 0 } },
      speciesDef = function() return { types = types } end,
      monName = function(_, mon) return mon == attacker and "USER" or "TARGET" end,
      sideOf = function() return "player" end,
      volatile = function(self, mon)
        self._volatiles = self._volatiles or {}
        self._volatiles[mon] = self._volatiles[mon] or {}
        return self._volatiles[mon]
      end,
      changeStage = function(_, _, stat, amount)
        stageChanges[#stageChanges + 1] = { stat, amount }
      end,
      emit = function(_, event) events[#events + 1] = event end,
      markMissed = function() error("unexpected Curse failure") end,
    }
    curse(battle, attacker, defender, {}, "CURSE", false)
    return battle, attacker, defender, events, stageChanges
  end
  local ghostBattle, ghostUser, ghostTarget, _, ghostStages = curseBattle({ "GHOST", "POISON" })
  assert(ghostBattle:volatile(ghostTarget).cursed and ghostUser.hp == 20 and #ghostStages == 0,
    "Ghost/Poison must use the typed-Metronome Ghost Curse branch")
  local poisonBattle, poisonUser, poisonTarget, _, poisonStages = curseBattle({ "POISON", "GHOST" })
  assert(not poisonBattle:volatile(poisonTarget).cursed and poisonUser.hp == 40
      and #poisonStages == 3 and poisonStages[1][1] == "speed",
    "Poison/Ghost must use the typed-Metronome non-Ghost Curse branch")

  local violet = MartMenu.new({ world = { map = { id = "VIOLET_MART" } } },
    { martType = "STANDARD" })
  local violetIds = {}
  for _, entry in ipairs(violet.entries) do violetIds[entry.id] = true end
  assert(violetIds.TYPE_TM51 and violetIds.TYPE_TM68,
    "Violet Mart must receive every Gen 2 Type Academy TM")

  local other = MartMenu.new({ world = { map = { id = "AZALEA_MART" } } },
    { martType = "STANDARD" })
  for _, entry in ipairs(other.entries) do
    assert(not tostring(entry.id):match("^TYPE_TM"), "other Gold Marts must remain unchanged")
  end
end

runGen1()
runGen2()
print("typed metronomes integration tests passed (17 assertions)")
