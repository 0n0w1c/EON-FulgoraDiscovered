local eon_mode = require("lib.eon-mode")
local eon_patch_registry = require("lib.eon-patch-registry")
local eon_autoplace_policy = require("lib.eon-autoplace-policy")
local biomes = require("lib.eon-biome-registry")
local eon_aquilo_on_fulgora = eon_mode.aquilo_on_fulgora

local aquilo_masks = biomes.get("aquilo").masks
local gleba_masks = biomes.get("gleba").masks
local vulcanus_masks = biomes.get("vulcanus").masks

local EON_NUKE_EFFECT_ID = eon_patch_registry.nuke.biome_effect_id
local EON_NUKE_CRATER_EFFECT_ID = eon_patch_registry.nuke.crater_effect_id

---@param expression string
---@return string
local function eon_mask_off_aquilo_for_nauvis(expression)
    if eon_aquilo_on_fulgora then return expression end
    return eon_autoplace_policy.wrap_expression(expression, aquilo_masks.off_territory)
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
    for _, clone in ipairs(eon_patch_registry.nuke.effect_clones) do
        eon_clone_nuke_effect(clone.source, clone.clone, clone.replacements, clone.before_effects)
    end

    local crater_policy = eon_patch_registry.nuke.nauvis_crater
    local nauvis_effect = data.raw["explosion"] and data.raw["explosion"][crater_policy.source]
    if nauvis_effect and not data.raw["explosion"][crater_policy.clone] then
        local crater = table.deepcopy(nauvis_effect)
        crater.name = crater_policy.clone
        crater.surface_conditions = nil
        crater.created_effect = {
            type = "direct",
            action_delivery = {
                type = "instant",
                target_effects = {
                    {
                        type = "create-decorative",
                        decorative = crater_policy.decorative,
                        spawn_min_radius = crater_policy.spawn_min_radius,
                        spawn_max_radius = crater_policy.spawn_max_radius,
                        spawn_min = crater_policy.spawn_min,
                        spawn_max = crater_policy.spawn_max,
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

    local eon_nuke_effect_entities = eon_patch_registry.nuke.cloned_effect_entities

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

---@return string
local function eon_fish_safe_nauvis_water_expression()
    local fish_lava_mask_name = "eon_mask_off_fish_lava"

    if not (data.raw["noise-function"] and data.raw["noise-function"][fish_lava_mask_name]) then
        data:extend({
            {
                type = "noise-function",
                name = fish_lava_mask_name,
                parameters = { "expression" },
                expression =
                    "if(max(" ..
                    "eon_lava_mountains_range, " ..
                    "eon_lava_hot_mountains_range, " ..
                    "lava_basalts_range, " ..
                    "lava_mountains_range, " ..
                    "lava_hot_basalts_range, " ..
                    "lava_hot_mountains_range" ..
                    ") > 0, -inf, expression)"
            }
        })
    end

    local expr = "0.01"
    expr = eon_autoplace_policy.wrap_expression(expr, vulcanus_masks.off_terrain)
    expr = eon_autoplace_policy.wrap_expression(expr, vulcanus_masks.off_coverage)
    expr = eon_autoplace_policy.wrap_expression(expr, fish_lava_mask_name)
    expr = eon_autoplace_policy.wrap_expression(expr, aquilo_masks.off_ammonia_ocean)
    expr = eon_mask_off_aquilo_for_nauvis(expr)

    return expr
end

if fish and fish.autoplace then
    eon_autoplace_policy.set_autoplace_tile_restriction(fish, { "water", "deepwater" })
    eon_autoplace_policy.add_collision_mask_layer(fish, "lava_tile")

    local expression_name = "eon_fish_safe_nauvis_water_probability"
    eon_autoplace_policy.ensure_noise_expression(expression_name, eon_fish_safe_nauvis_water_expression())

    fish.autoplace.probability_expression = expression_name

    local nauvis = data.raw.planet and data.raw.planet["nauvis"]
    local map_gen = nauvis and nauvis.map_gen_settings
    if map_gen then
        map_gen.property_expression_names = map_gen.property_expression_names or {}
        map_gen.property_expression_names["entity:fish:probability"] = expression_name
    end
end

local dead_tree =
 data.raw["tree"] and data.raw["tree"]["dead-grey-trunk"]
local dead_tree_expr = eon_autoplace_policy.autoplace_probability_expression(dead_tree)

if dead_tree_expr then
    local expr = eon_autoplace_policy.wrap_expression(
        dead_tree_expr,
        vulcanus_masks.off_terrain
    )
    expr = eon_autoplace_policy.wrap_expression(expr, gleba_masks.off_territory)
    dead_tree.autoplace.probability_expression = eon_mask_off_aquilo_for_nauvis(expr)
end

---@param type_name string
---@param entity_name string
---@param factor number
---@return nil
local function scale_entity_autoplace(type_name, entity_name, factor)
    local proto = data.raw[type_name] and data.raw[type_name][entity_name]
    eon_autoplace_policy.scale_autoplace_probability(proto, factor)
end

for _, scale_policy in ipairs(eon_patch_registry.autoplace_scale) do
    scale_entity_autoplace(scale_policy.type, scale_policy.name, scale_policy.factor)
end

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

---@param pollutants table
---@return nil
local function eon_move_spores_to_pollution(pollutants)
    if type(pollutants) ~= "table" or pollutants.spores == nil then return end

    if pollutants.pollution == nil then
        pollutants.pollution = eon_autoplace_policy.copy_value(pollutants.spores)
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

for _, prototype_type in pairs(eon_patch_registry.pollution_conversion_prototype_types) do
    for _, proto in pairs(data.raw[prototype_type] or {}) do
        eon_move_spores_to_pollution(proto.absorptions_to_join_attack)
        eon_move_spores_to_pollution(proto.absorptions_per_second)
        eon_move_spores_to_pollution(proto.emissions_per_second)
        eon_move_spores_to_pollution(proto.harvest_emissions)
        eon_convert_energy_source_pollutants(proto.energy_source)
    end
end

for prototype_type, names in pairs(eon_patch_registry.clear_collision_mask) do
    for _, name in ipairs(names) do
        local proto = data.raw[prototype_type] and data.raw[prototype_type][name]
        if proto then proto.collision_mask = nil end
    end
end

for prototype_type, emissions_by_name in pairs(eon_patch_registry.harvest_emissions) do
    for name, emissions in pairs(emissions_by_name) do
        local proto = data.raw[prototype_type] and data.raw[prototype_type][name]
        if proto then proto.harvest_emissions = table.deepcopy(emissions) end
    end
end

for prototype_type, emissions_by_name in pairs(eon_patch_registry.energy_source_emissions_per_minute) do
    for name, emissions in pairs(emissions_by_name) do
        local proto = data.raw[prototype_type] and data.raw[prototype_type][name]
        if proto then
            proto.energy_source = proto.energy_source or {}
            proto.energy_source.emissions_per_minute = table.deepcopy(emissions)
        end
    end
end

if mods["Electric_flying_enemies"] then
    local biter_spawner = data.raw["unit-spawner"] and data.raw["unit-spawner"]["biter-spawner"]
    local biter_spawner_absorption = biter_spawner and biter_spawner.absorptions_per_second

    for _, spawner_name in ipairs(eon_patch_registry.electric_flying_enemies.spawners) do
        local spawner = data.raw["unit-spawner"] and data.raw["unit-spawner"][spawner_name]
        if spawner and biter_spawner_absorption then
            spawner.absorptions_per_second = eon_autoplace_policy.copy_value(biter_spawner_absorption)
        elseif spawner then
            spawner.absorptions_per_second = table.deepcopy(eon_patch_registry.electric_flying_enemies
                .default_spawner_absorption)
        end
        if spawner and spawner.absorptions_per_second then
            eon_move_spores_to_pollution(spawner.absorptions_per_second)
        end
    end

    local eon_unit_pollution_sources = eon_patch_registry.electric_flying_enemies.unit_pollution_sources

    ---@param level number
    ---@return any
    local function eon_get_nauvis_unit_absorption(level)
        local source_name = eon_unit_pollution_sources[level]
        local source = source_name and data.raw["unit"] and data.raw["unit"][source_name]
        if source and source.absorptions_to_join_attack then
            return eon_autoplace_policy.copy_value(source.absorptions_to_join_attack)
        end

        local fallback_pollution = eon_patch_registry.electric_flying_enemies.unit_fallback_pollution[level]
        return { pollution = fallback_pollution or 400 }
    end

    for level = 1, 5 do
        local absorption = eon_get_nauvis_unit_absorption(level)
        for _, pattern in ipairs(eon_patch_registry.electric_flying_enemies.unit_name_patterns) do
            local unit_name = string.format(pattern, level)
            local unit = data.raw["unit"] and data.raw["unit"][unit_name]
            if unit then
                unit.absorptions_to_join_attack = eon_autoplace_policy.copy_value(absorption)
                eon_move_spores_to_pollution(unit.absorptions_to_join_attack)
            end
        end
    end
end

if eon_mode.use_tungsten_plate then
    local tungsten_policy = eon_patch_registry.tungsten_plate_mode

    for _, name in ipairs(tungsten_policy.demolisher_corpses) do
        local corpse = data.raw["simple-entity"] and data.raw["simple-entity"][name]
        local minable = corpse and corpse.minable
        local results = minable and minable.results

        if results then
            for _, result in pairs(results) do
                if result.type == "item" and result.name == tungsten_policy.source_item then
                    result.name = tungsten_policy.replacement_item
                end
            end
        end
    end

    local foundry_recipe = data.raw["recipe"] and data.raw["recipe"][tungsten_policy.foundry_recipe]
    if foundry_recipe and not foundry_recipe.hidden and foundry_recipe.ingredients then
        for _, ingredient in pairs(foundry_recipe.ingredients) do
            if ingredient.name == tungsten_policy.foundry_ingredient then
                ingredient.name = tungsten_policy.replacement_item
            end
        end

        if mods["quality"] then
            local recycling = require("__quality__/prototypes/recycling")
            recycling.generate_recycling_recipe(foundry_recipe)
        end
    end
end
