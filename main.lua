-- Typed Metronomes
-- New numbered TM-style items that teach type-restricted random-move attacks.
-- This entrypoint deliberately embeds its small pure rules layer. Mod API 2's
-- sandbox exposes mod:read for data but not a Lua compiler, while a hard-coded
-- `mods.<id>` require breaks validation of an unpacked standalone release.

return function(mod)
  local GameVersion = require("src.core.GameVersion")
  local playing = GameVersion.get()
  local generation = GameVersion.generation(playing)
  if generation ~= 1 and generation ~= 2 then return end

  local Typed = (function()
    local T = {
      PRICE = 3000,
      GEN1_MART_MAP = "PEWTER_MART",
      GEN2_MART_MAP = "VIOLET_MART",
    }
    local catalogue = {
      { number = 51, type = "NORMAL",       move = "TYPE_METRO_NORMAL",   short = "N-METRO" },
      { number = 52, type = "FIGHTING",     move = "TYPE_METRO_FIGHTING", short = "FIGHT-METRO" },
      { number = 53, type = "FLYING",       move = "TYPE_METRO_FLYING",   short = "FLY-METRO" },
      { number = 54, type = "POISON",       move = "TYPE_METRO_POISON",   short = "POIS-METRO" },
      { number = 55, type = "GROUND",       move = "TYPE_METRO_GROUND",   short = "GND-METRO" },
      { number = 56, type = "ROCK",         move = "TYPE_METRO_ROCK",     short = "ROCK-METRO" },
      { number = 57, type = "BUG",          move = "TYPE_METRO_BUG",      short = "BUG-METRO" },
      { number = 58, type = "GHOST",        move = "TYPE_METRO_GHOST",    short = "GHOST-METRO" },
      { number = 59, type = "FIRE",         move = "TYPE_METRO_FIRE",     short = "FIRE-METRO" },
      { number = 60, type = "WATER",        move = "TYPE_METRO_WATER",    short = "WATER-METRO" },
      { number = 61, type = "GRASS",        move = "TYPE_METRO_GRASS",    short = "GRASS-METRO" },
      { number = 62, type = "ELECTRIC",     move = "TYPE_METRO_ELECTRIC", short = "ELEC-METRO" },
      { number = 63, type = "PSYCHIC_TYPE", move = "TYPE_METRO_PSYCHIC",  short = "PSY-METRO" },
      { number = 64, type = "ICE",          move = "TYPE_METRO_ICE",      short = "ICE-METRO" },
      { number = 65, type = "DRAGON",       move = "TYPE_METRO_DRAGON",   short = "DRGN-METRO" },
      { number = 66, type = "DARK",         move = "TYPE_METRO_DARK",     short = "DARK-METRO", gen2 = true },
      { number = 67, type = "STEEL",        move = "TYPE_METRO_STEEL",    short = "STEEL-METRO", gen2 = true },
      { number = 68, type = "CURSE_TYPE",   move = "TYPE_METRO_CURSE",    short = "Q-METRO", gen2 = true },
    }
    local byMove, byType = {}, {}
    for _, row in ipairs(catalogue) do
      row.item = ("TYPE_TM%02d"):format(row.number)
      byMove[row.move], byType[row.type] = row, row
    end
    T.CATALOGUE, T.byType = catalogue, byType
    function T.entries(gen)
      local out = {}
      for _, row in ipairs(catalogue) do
        if gen == 2 or not row.gen2 then out[#out + 1] = row end
      end
      return out
    end
    function T.entryForMove(moveId) return byMove[moveId] end
    function T.isTypedMove(moveId) return byMove[moveId] ~= nil end
    function T.matchesType(types, wanted)
      for _, id in ipairs(types or {}) do if id == wanted then return true end end
      return false
    end
    function T.curseUsesGhostPrimary(types) return types and types[1] == "GHOST" end
    function T.pool(data, row, gen)
      local moves = (data and data.moves) or {}
      local constants = (data and data.constants) or {}
      local order = constants.moveOrder or moves.order or {}
      local pool, seen = {}, {}
      local function add(moveId)
        if seen[moveId] then return end
        local def = moves[moveId]
        if not def or moveId == "METRONOME" or T.isTypedMove(moveId)
            or def.type ~= row.type then return end
        seen[moveId], pool[#pool + 1] = true, moveId
      end
      for _, id in ipairs(order) do add(id) end
      local extras = {}
      for id in pairs(moves) do
        if type(id) == "string" and not seen[id] then extras[#extras + 1] = id end
      end
      table.sort(extras)
      for _, id in ipairs(extras) do add(id) end
      if gen ~= 2 and row.type == "NORMAL" and moves.STRUGGLE and not seen.STRUGGLE then
        seen.STRUGGLE, pool[#pool + 1] = true, "STRUGGLE"
      end
      if gen == 2 and moves.CURSE and not seen.CURSE then
        seen.CURSE, pool[#pool + 1] = true, "CURSE"
      end
      return pool
    end
    function T.pick(data, row, gen, rng)
      local pool = T.pool(data, row, gen)
      if #pool == 0 then return nil end
      if gen == 2 then return pool[(rng and rng(#pool) or 0) + 1] end
      return pool[rng and rng(1, #pool) or 1]
    end
    function T.itemRecord(row, gen)
      local record = {
        id = row.item, name = ("TM%02d"):format(row.number), price = T.PRICE,
        tossable = true, machine = { kind = "TM", move = row.move, number = row.number },
      }
      if gen == 2 then
        record.pocket, record.tmNumber = "TM_HM", row.number + 7
        record.tmLabel, record.teaches = ("TM%02d"):format(row.number), row.move
      end
      return record
    end
    function T.moveRecord(row)
      return {
        id = row.move, name = row.short, type = row.type, power = 0, accuracy = 100,
        pp = 10, category = "status", effect = "TYPE_METRONOME_EFFECT", anim = "METRONOME",
      }
    end
    return T
  end)()

  local marker = "_typedMetronomesInstalled"

  local function copyList(source)
    local out, seen = {}, {}
    for _, id in ipairs(source or {}) do
      if not seen[id] then out[#out + 1], seen[id] = id, true end
    end
    return out, seen
  end

  local function appendCatalogue(target)
    local out, seen = copyList(target)
    for _, row in ipairs(Typed.entries(generation)) do
      if not seen[row.item] then out[#out + 1], seen[row.item] = row.item, true end
    end
    return out
  end

  local function registerContent()
    local effect = "TYPE_METRONOME_EFFECT"
    if generation == 2 then
      -- The selected ID re-enters Battle:useMove, retaining native target, hit,
      -- damage, animation, status, and special-effect behavior.
      mod.content.move_effects:register(effect, {
        kind = "primary",
        run = function(battle, attacker, defender, _, moveId)
          local row = Typed.entryForMove(moveId)
          if not row or (battle.copyDepth or 0) > 0 then
            battle:markMissed()
            battle:emit({ kind = "message", text = "But it failed!" })
            return
          end
          local pick = Typed.pick(battle.data, row, 2, battle.random)
          if not pick then
            battle:markMissed()
            battle:emit({ kind = "message", text = "But it failed!" })
            return
          end
          battle.copyDepth = (battle.copyDepth or 0) + 1
          if pick == "CURSE" then
            battle._typedMetronomeCurseDepth = (battle._typedMetronomeCurseDepth or 0) + 1
          end
          local ok, err = pcall(battle.useMove, battle, attacker, defender, pick)
          if pick == "CURSE" then
            battle._typedMetronomeCurseDepth = math.max(0,
              (battle._typedMetronomeCurseDepth or 1) - 1)
          end
          battle.copyDepth = math.max(0, (battle.copyDepth or 1) - 1)
          if not ok then error(err) end
        end,
      })
      -- Only a Curse called by this mod receives primary-type Ghost semantics.
      local nativeCurse = mod.content.move_effects:get("EFFECT_CURSE")
      local nativeRun = nativeCurse and nativeCurse.run
      if nativeRun then
        mod.content.move_effects:override("EFFECT_CURSE", {
          kind = "primary",
          run = function(battle, attacker, defender, def, moveId, sureHit)
            if (battle._typedMetronomeCurseDepth or 0) <= 0 then
              return nativeRun(battle, attacker, defender, def, moveId, sureHit)
            end
            local species = battle:speciesDef(attacker) or {}
            local types = species.types or attacker.types or {}
            local name = battle:monName(attacker)
            if not Typed.curseUsesGhostPrimary(types) then
              local Effects = require("src.battle.gen2.Effects")
              local stages = battle.stages[battle:sideOf(attacker)]
              if (stages.attack or 0) >= Effects.MAX_STAGE
                  and (stages.defense or 0) >= Effects.MAX_STAGE then
                battle:markMissed()
                battle:emit({ kind = "message", text = name .. "'s ATTACK won't rise anymore!" })
                return
              end
              battle:changeStage(attacker, "speed", -1)
              battle:changeStage(attacker, "attack", 1)
              battle:changeStage(attacker, "defense", 1)
              return
            end
            local target = battle:volatile(defender)
            if target.vanished or (target.substitute or 0) > 0 or target.cursed then
              battle:markMissed()
              battle:emit({ kind = "message", text = "But it failed!" })
              return
            end
            target.cursed = true
            local maxHp = attacker.maxHp or (attacker.stats and attacker.stats.hp) or 1
            local cost = math.max(1, math.floor(maxHp / 2))
            attacker.hp = math.max(0, (attacker.hp or 0) - cost)
            battle:emit({ kind = "damage", side = battle:sideOf(attacker),
              amount = cost, hp = attacker.hp, anim = false })
            battle:emit({ kind = "message", text = name .. " cut its own HP and put a CURSE on "
              .. battle:monName(defender) .. "!" })
          end,
        })
      end
    else
      -- Gen 1's callsMove contract is the native Metronome seam.
      mod.content.move_effects:register(effect, {
        kind = "primary",
        callsMove = function(ctx)
          local row = Typed.entryForMove(ctx.move and ctx.move.id)
          return row and Typed.pick(ctx.battle.data, row, 1, ctx.rng) or nil
        end,
      })
    end
    for _, row in ipairs(Typed.entries(generation)) do
      mod.content.moves:register(row.move, Typed.moveRecord(row))
      mod.content.items:register(row.item, Typed.itemRecord(row, generation))
    end
    -- The merged registry view includes built-in and earlier-mod species before
    -- content freezes, including mod-added species with type IDs.
    for speciesId, species in mod.content.pokemon:each() do
      local types = species and species.types or {}
      for _, row in ipairs(Typed.entries(generation)) do
        if Typed.matchesType(types, row.type) then
          mod.content.pokemon:patch(speciesId, { tmhm = { __append = { row.move } } })
        end
      end
    end
  end

  local function installGen1Academy()
    local ShopMenu = require("src.ui.ShopMenu")
    if ShopMenu[marker] then return end
    local nativeNew = ShopMenu.new
    ShopMenu.new = function(game, stock, onQuit)
      local map = game and game.overworld and game.overworld.map
      local mapId = map and ((map.def and map.def.id) or map.id)
      if mapId == Typed.GEN1_MART_MAP then stock = appendCatalogue(stock) end
      return nativeNew(game, stock, onQuit)
    end
    ShopMenu[marker] = true
  end

  local function installGen2Academy()
    local MartMenu = require("src.ui.gen2.MartMenu")
    if MartMenu[marker] then return end
    local nativeNew = MartMenu.new
    MartMenu.new = function(game, opts)
      local menu = nativeNew(game, opts)
      local world, map = game and game.world, game and game.world and game.world.map
      local mapId = map and ((map.def and map.def.id) or map.id)
      if menu and menu.martType == "STANDARD" and mapId == Typed.GEN2_MART_MAP then
        local existing = {}
        for _, entry in ipairs(menu.entries or {}) do existing[entry.id] = true end
        for _, row in ipairs(Typed.entries(2)) do
          if not existing[row.item] then
            menu.entries[#menu.entries + 1] = {
              id = row.item, name = ("TM%02d"):format(row.number), price = Typed.PRICE,
            }
          end
        end
      end
      return menu
    end
    MartMenu[marker] = true
  end

  registerContent()
  if generation == 2 then installGen2Academy() else installGen1Academy() end
  if mod.log and type(mod.log.info) == "function" then
    mod.log:info("Typed Metronomes active for Generation " .. tostring(generation) .. ".")
  end
end
