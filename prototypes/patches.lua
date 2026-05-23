local eon_aquilo_on_fulgora = settings.startup["eon-fd-aquilo-on-fulgora"]
    and settings.startup["eon-fd-aquilo-on-fulgora"].value

local function eon_mask_off_aquilo_for_nauvis(expression)
    if eon_aquilo_on_fulgora then
        return expression
    end
    return "eon_mask_off_aquilo_territory(" .. expression .. ")"
end

-- ---------------------------------------------------------------------------
-- Fix: Remove lava and ammoniacal solution tiles from the atomic rocket effects
-- ---------------------------------------------------------------------------
local projectile = data.raw["projectile"] and data.raw["projectile"]["atomic-rocket"]
if projectile
    and projectile.action
    and projectile.action.action_delivery
    and projectile.action.action_delivery.target_effects
then
    local remove = {
        ["nuke-effects-vulcanus"] = true,
        ["nuke-effects-aquilo"] = true,
    }

    local filtered = {}
    for _, effect in ipairs(projectile.action.action_delivery.target_effects) do
        if not (effect.type == "create-entity" and remove[effect.entity_name]) then
            table.insert(filtered, effect)
        end
    end

    projectile.action.action_delivery.target_effects = filtered
end

-- ---------------------------------------------------------------------------
-- Fix: Remove fish from Aquilo and Vulcanus terrain
-- ---------------------------------------------------------------------------
local fish = data.raw["fish"] and data.raw["fish"]["fish"]
if fish and fish.autoplace and fish.autoplace.probability_expression then
    fish.autoplace.probability_expression =
        eon_mask_off_aquilo_for_nauvis("eon_mask_off_vulcano_terrain(" .. fish.autoplace.probability_expression .. ")")
end

-- ---------------------------------------------------------------------------
-- Fix: Remove dead-grey-trunk from Vulcanus and Gleba terrain
-- ---------------------------------------------------------------------------
local dead_tree = data.raw["tree"] and data.raw["tree"]["dead-grey-trunk"]
if dead_tree and dead_tree.autoplace and dead_tree.autoplace.probability_expression then
    local expr = dead_tree.autoplace.probability_expression
    dead_tree.autoplace.probability_expression =
        eon_mask_off_aquilo_for_nauvis("eon_mask_off_gleba_territory(eon_mask_off_vulcano_terrain(" .. expr .. "))")
end

-- ---------------------------------------------------------------------------
-- Fix: Add ashland trees to Vulcanus terrain
-- ---------------------------------------------------------------------------
data:extend({
    {
        type = "noise-expression",
        name = "eon_vulcanus_ashland_tree_density",
        expression = "clamp(0.02 + 0.8 * tree_small_noise, 0, 1)"
    },
})

local function spawn_tree_in_vulcanus(tree_name, multiplier)
    local tree = data.raw["tree"] and data.raw["tree"][tree_name]
    if not (tree and tree.autoplace) then return end

    multiplier = multiplier or 1

    tree.autoplace.probability_expression =
        "eon_mask_vulcano_terrain(" ..
        (multiplier == 1 and "eon_vulcanus_ashland_tree_density"
            or (multiplier .. " * eon_vulcanus_ashland_tree_density")) ..
        ")"
end

spawn_tree_in_vulcanus("ashland-lichen-tree", 0.05)
spawn_tree_in_vulcanus("ashland-lichen-tree-flaming", 0.02)

if data.raw.planet and data.raw.planet["nauvis"] and data.raw.planet["nauvis"].map_gen_settings
    and data.raw.planet["nauvis"].map_gen_settings.autoplace_settings
    and data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.entity
    and data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.entity.settings
then
    data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.entity.settings["ashland-lichen-tree"] = {}
    data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.entity.settings["ashland-lichen-tree-flaming"] = {}
end

-- ---------------------------------------------------------------------------
-- Fix: Scale down the number of Vulcanus simple entities spawned
-- ---------------------------------------------------------------------------
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

-- ---------------------------------------------------------------------------
-- Fix: Add lubricant as a prerequisite for the foundry technology
-- ---------------------------------------------------------------------------
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

-- ---------------------------------------------------------------------------
-- Fix: Remove calcite resource category
-- ---------------------------------------------------------------------------
local calcite = data.raw["resource"] and data.raw["resource"]["calcite"]
if calcite then
    calcite.category = nil
end

-- ---------------------------------------------------------------------------
-- Fix: EON uses pollution, not spores
-- ---------------------------------------------------------------------------
local function eon_copy_pollutant_value(value)
    if type(value) == "table" then
        return table.deepcopy(value)
    end
    return value
end

local function eon_move_spores_to_pollution(pollutants)
    if type(pollutants) ~= "table" or pollutants.spores == nil then return end

    if pollutants.pollution == nil then
        pollutants.pollution = eon_copy_pollutant_value(pollutants.spores)
    end
    pollutants.spores = nil
end

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

-- ---------------------------------------------------------------------------
-- Fix: Electric Flying Enemies / Fulgoran Enemies pollution response
-- ---------------------------------------------------------------------------
if mods["Electric_flying_enemies"] then
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

-- ---------------------------------------------------------------------------
-- Fix: Use tungsten-plate
-- ---------------------------------------------------------------------------
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
