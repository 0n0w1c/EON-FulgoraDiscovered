local eon_aquilo_on_fulgora = settings.startup["eon-fd-aquilo-on-fulgora"]
    and settings.startup["eon-fd-aquilo-on-fulgora"].value

local EON_NUKE_EFFECT_ID = "eon-atomic-rocket-biome-effect"
local EON_NUKE_CRATER_EFFECT_ID = "eon-atomic-rocket-nauvis-crater-effect"

---@param expression string
---@return any
local function eon_mask_off_aquilo_for_nauvis(expression)
    if eon_aquilo_on_fulgora then return expression end
    return "eon_mask_off_aquilo_territory(" .. expression .. ")"
end

---@param prototype table|nil
---@return table|nil
local function eon_get_created_target_effects(prototype)
    return prototype
        and prototype.created_effect
        and prototype.created_effect.action_delivery
        and prototype.created_effect.action_delivery.target_effects
end

---@param source_name string
---@param clone_name string
---@param replacements table<string, string>
---@param before_effects table[]|nil
---@return nil
local function eon_clone_nuke_effect(source_name, clone_name, replacements, before_effects)
    local source = data.raw["explosion"] and data.raw["explosion"][source_name]
    if not source or data.raw["explosion"][clone_name] then return end

    local clone = table.deepcopy(source)
    clone.name = clone_name
    clone.surface_conditions = nil

    local target_effects = eon_get_created_target_effects(clone)
    if target_effects then
        if before_effects then
            for i = #before_effects, 1, -1 do
                table.insert(target_effects, 1, before_effects[i])
            end
        end

        for _, effect in pairs(target_effects) do
            if effect.type == "set-tile" and replacements[effect.tile_name] then
                effect.tile_name = replacements[effect.tile_name]
            end
        end
    end

    data:extend({ clone })
end

---@return nil
local function eon_create_biome_nuke_effects()
    eon_clone_nuke_effect("nuke-effects-vulcanus", "eon-nuke-effects-fulgora", {
        ["lava-hot"] = "oil-ocean-deep",
        ["lava"] = "oil-ocean-shallow",
    })

    eon_clone_nuke_effect("nuke-effects-vulcanus", "eon-nuke-effects-vulcanus-swapped", {
        ["lava-hot"] = "lava",
        ["lava"] = "lava-hot",
    }, {
        {
            type = "set-tile",
            tile_name = "volcanic-cracks-warm",
            radius = 14,
            apply_projection = true,
            tile_collision_mask = {
                layers = {
                    water_tile = true,
                },
            },
        },
    })

    local nauvis_effect = data.raw["explosion"] and data.raw["explosion"]["nuke-effects-nauvis"]
    if nauvis_effect and not data.raw["explosion"]["eon-nuke-crater-nauvis"] then
        local crater = table.deepcopy(nauvis_effect)
        crater.name = "eon-nuke-crater-nauvis"
        crater.surface_conditions = nil
        crater.created_effect = {
            type = "direct",
            action_delivery = {
                type = "instant",
                target_effects = {
                    {
                        type = "create-decorative",
                        decorative = "nuclear-ground-patch",
                        spawn_min_radius = 11.5,
                        spawn_max_radius = 12.5,
                        spawn_min = 30,
                        spawn_max = 40,
                        apply_projection = true,
                        spread_evenly = true,
                    },
                },
            },
        }

        data:extend({ crater })
    end
end

eon_create_biome_nuke_effects()

---@return nil
local function eon_patch_atomic_rocket_nuke_effects()
    local projectile = data.raw["projectile"] and data.raw["projectile"]["atomic-rocket"]
    local target_effects = projectile
        and projectile.action
        and projectile.action.action_delivery
        and projectile.action.action_delivery.target_effects

    if not target_effects then return end

    local eon_nuke_effect_entities = {
        ["eon-nuke-effects-fulgora"] = true,
        ["eon-nuke-effects-vulcanus-swapped"] = true,
    }

    ---@param entity_name string|nil
    ---@return boolean
    local function is_nuke_effect_entity(entity_name)
        return type(entity_name) == "string"
            and (string.match(entity_name, "^nuke%-effects%-") ~= nil
                or eon_nuke_effect_entities[entity_name])
    end

    local filtered = {}
    local inserted_biome_selector = false
    local inserted_crater_selector = false

    local function insert_biome_selector()
        if inserted_biome_selector then return end
        inserted_biome_selector = true
        table.insert(filtered, {
            type = "script",
            effect_id = EON_NUKE_EFFECT_ID,
        })
    end

    local function insert_crater_selector()
        if inserted_crater_selector then return end
        inserted_crater_selector = true
        table.insert(filtered, {
            type = "script",
            effect_id = EON_NUKE_CRATER_EFFECT_ID,
        })
    end

    for _, effect in ipairs(target_effects) do
        if effect.type == "script" and effect.effect_id == EON_NUKE_EFFECT_ID then
            insert_biome_selector()
        elseif effect.type == "script" and effect.effect_id == EON_NUKE_CRATER_EFFECT_ID then
            insert_crater_selector()
        elseif effect.type == "create-entity" and is_nuke_effect_entity(effect.entity_name) then
            insert_biome_selector()
        elseif effect.type == "create-decorative" and effect.decorative == "nuclear-ground-patch" then
            insert_crater_selector()
        else
            table.insert(filtered, effect)
        end
    end

    insert_biome_selector()
    projectile.action.action_delivery.target_effects = filtered
end

eon_patch_atomic_rocket_nuke_effects()

local fish = data.raw["fish"] and data.raw["fish"]["fish"]
if fish and fish.autoplace and fish.autoplace.probability_expression then
    fish.autoplace.probability_expression =
        eon_mask_off_aquilo_for_nauvis("eon_mask_off_vulcano_terrain(" .. fish.autoplace.probability_expression .. ")")
end

local dead_tree = data.raw["tree"] and data.raw["tree"]["dead-grey-trunk"]
if dead_tree and dead_tree.autoplace and dead_tree.autoplace.probability_expression then
    local expr = dead_tree.autoplace.probability_expression
    dead_tree.autoplace.probability_expression =
        eon_mask_off_aquilo_for_nauvis("eon_mask_off_gleba_territory(eon_mask_off_vulcano_terrain(" .. expr .. "))")
end

---@param type_name string
---@param entity_name string
---@param factor number
---@return nil
local function scale_entity_autoplace(type_name, entity_name, factor)
    local proto = data.raw[type_name] and data.raw[type_name][entity_name]
    if proto and proto.autoplace and proto.autoplace.probability_expression then
        proto.autoplace.probability_expression =
            "(" .. factor .. ") * (" .. proto.autoplace.probability_expression .. ")"
    end
end

scale_entity_autoplace("simple-entity", "vulcanus-chimney", 0.2)
scale_entity_autoplace("simple-entity", "vulcanus-chimney-faded", 0.2)
scale_entity_autoplace("simple-entity", "vulcanus-chimney-cold", 0.2)
scale_entity_autoplace("simple-entity", "vulcanus-chimney-short", 0.2)
scale_entity_autoplace("simple-entity", "vulcanus-chimney-truncated", 0.2)
scale_entity_autoplace("simple-entity", "huge-volcanic-rock", 0.4)
scale_entity_autoplace("simple-entity", "big-volcanic-rock", 0.4)

local foundry = data.raw["technology"] and data.raw["technology"]["foundry"]
if foundry and foundry.prerequisites then
    local found = false
    for _, prerequisite in ipairs(foundry.prerequisites) do
        if prerequisite == "lubricant" then
            found = true
            break
        end
    end

    if not found then table.insert(foundry.prerequisites, "lubricant") end
end

local calcite = data.raw["resource"] and data.raw["resource"]["calcite"]
if calcite then
    calcite.category = nil
end

---@param value string
---@return any
local function eon_copy_pollutant_value(value)
    if type(value) == "table" then
        return table.deepcopy(value)
    end
    return value
end

---@param pollutants table
---@return nil
local function eon_move_spores_to_pollution(pollutants)
    if type(pollutants) ~= "table" or pollutants.spores == nil then return end

    if pollutants.pollution == nil then
        pollutants.pollution = eon_copy_pollutant_value(pollutants.spores)
    end
    pollutants.spores = nil
end

---@param energy_source table
---@return nil
local function eon_convert_energy_source_pollutants(energy_source)
    if type(energy_source) ~= "table" then return end
    eon_move_spores_to_pollution(energy_source.emissions_per_minute)
    eon_move_spores_to_pollution(energy_source.emissions_per_second)
end

for _, prototype_type in pairs({
    "unit",
    "spider-unit",
    "unit-spawner",
    "turret",
    "tree",
    "plant",
    "agricultural-tower",
    "assembling-machine",
    "furnace",
    "mining-drill",
    "boiler",
    "generator",
    "reactor",
    "rocket-silo",
    "lab",
}) do
    for _, proto in pairs(data.raw[prototype_type] or {}) do
        eon_move_spores_to_pollution(proto.absorptions_to_join_attack)
        eon_move_spores_to_pollution(proto.absorptions_per_second)
        eon_move_spores_to_pollution(proto.emissions_per_second)
        eon_move_spores_to_pollution(proto.harvest_emissions)
        eon_convert_energy_source_pollutants(proto.energy_source)
    end
end

if data.raw["unit-spawner"] and data.raw["unit-spawner"]["gleba-spawner-small"] then
    data.raw["unit-spawner"]["gleba-spawner-small"].collision_mask = nil
end

if data.raw["unit-spawner"] and data.raw["unit-spawner"]["gleba-spawner"] then
    data.raw["unit-spawner"]["gleba-spawner"].collision_mask = nil
end

if data.raw["plant"] and data.raw["plant"]["jellystem"] then
    data.raw["plant"]["jellystem"].harvest_emissions = { pollution = 15 }
end

if data.raw["plant"] and data.raw["plant"]["yumako-tree"] then
    data.raw["plant"]["yumako-tree"].harvest_emissions = { pollution = 15 }
end

if data.raw["agricultural-tower"] and data.raw["agricultural-tower"]["agricultural-camp"] then
    local tower = data.raw["agricultural-tower"]["agricultural-camp"]
    tower.energy_source = tower.energy_source or {}
    tower.energy_source.emissions_per_minute = { pollution = 4 }
end

if data.raw["agricultural-tower"] and data.raw["agricultural-tower"]["agricultural-tower"] then
    local tower = data.raw["agricultural-tower"]["agricultural-tower"]
    tower.energy_source = tower.energy_source or {}
    tower.energy_source.emissions_per_minute = { pollution = 4 }
end

if mods["Electric_flying_enemies"] then
    ---@param value any
    ---@return any
    local function eon_copy_table_or_value(value)
        if type(value) == "table" then
            return table.deepcopy(value)
        end
        return value
    end

    local biter_spawner = data.raw["unit-spawner"] and data.raw["unit-spawner"]["biter-spawner"]
    local biter_spawner_absorption = biter_spawner and biter_spawner.absorptions_per_second

    for _, spawner_name in ipairs({
        "flying-electric-unit-spawner",
        "walker-electric-unit-spawner",
    }) do
        local spawner = data.raw["unit-spawner"] and data.raw["unit-spawner"][spawner_name]
        if spawner and biter_spawner_absorption then
            spawner.absorptions_per_second = eon_copy_table_or_value(biter_spawner_absorption)
        elseif spawner then
            spawner.absorptions_per_second = { pollution = { absolute = 20, proportional = 0.01 } }
        end
        if spawner and spawner.absorptions_per_second then
            eon_move_spores_to_pollution(spawner.absorptions_per_second)
        end
    end

    local eon_unit_pollution_sources = {
        [1] = "small-biter",
        [2] = "medium-biter",
        [3] = "big-biter",
        [4] = "behemoth-biter",
        [5] = "behemoth-biter",
    }

    ---@param level number
    ---@return any
    local function eon_get_nauvis_unit_absorption(level)
        local source_name = eon_unit_pollution_sources[level]
        local source = source_name and data.raw["unit"] and data.raw["unit"][source_name]
        if source and source.absorptions_to_join_attack then
            return eon_copy_table_or_value(source.absorptions_to_join_attack)
        end

        local fallback_pollution = ({ 4, 20, 80, 400, 400 })[level]
        return { pollution = fallback_pollution or 400 }
    end

    for level = 1, 5 do
        local absorption = eon_get_nauvis_unit_absorption(level)
        for _, unit_name in ipairs({
            "flying-electric-unit-" .. level,
            "walking-electric-unit-" .. level,
        }) do
            local unit = data.raw["unit"] and data.raw["unit"][unit_name]
            if unit then
                unit.absorptions_to_join_attack = eon_copy_table_or_value(absorption)
                eon_move_spores_to_pollution(unit.absorptions_to_join_attack)
            end
        end
    end
end

local use_tungsten_setting = settings.startup["eon-fd-use-tungsten-plate"]
if use_tungsten_setting and use_tungsten_setting.value then
    local demolisher_corpses = {
        "small-demolisher-corpse",
        "medium-demolisher-corpse",
        "big-demolisher-corpse",
    }

    for _, name in ipairs(demolisher_corpses) do
        local corpse = data.raw["simple-entity"] and data.raw["simple-entity"][name]
        local minable = corpse and corpse.minable
        local results = minable and minable.results

        if results then
            for _, result in pairs(results) do
                if result.type == "item" and result.name == "tungsten-ore" then
                    result.name = "tungsten-plate"
                end
            end
        end
    end

    local foundry_recipe = data.raw["recipe"] and data.raw["recipe"]["foundry"]
    if foundry_recipe and not foundry_recipe.hidden and foundry_recipe.ingredients then
        for _, ingredient in pairs(foundry_recipe.ingredients) do
            if ingredient.name == "tungsten-carbide" then
                ingredient.name = "tungsten-plate"
            end
        end

        if mods["quality"] then
            local recycling = require("__quality__/prototypes/recycling")
            recycling.generate_recycling_recipe(foundry_recipe)
        end
    end
end
