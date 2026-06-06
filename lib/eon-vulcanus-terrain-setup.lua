local eon_autoplace_masks = require("lib.eon-autoplace-masks")
local eon_autoplace_policy = require("lib.eon-autoplace-policy")
local eon_terrain_autoplace = require("lib.eon-terrain-autoplace")
local eon_volcanus_registry = require("lib.eon-volcanus-registry")

---@class EonVulcanusTerrainSetupSettings
---@field aquilo_on_fulgora boolean
---@field vulcanus_off_aquilo_mask string

local eon_vulcanus_terrain_setup = {}

---@return table<string, table>|nil
local function eon_vulcanus_optimized_decorative_settings()
    local planet = data.raw.planet and data.raw.planet["vulcanus"]
    return planet
        and planet.map_gen_settings
        and planet.map_gen_settings.autoplace_settings
        and planet.map_gen_settings.autoplace_settings.decorative
        and planet.map_gen_settings.autoplace_settings.decorative.settings
end

---@return string[]
local function eon_enable_vulcanus_decoratives_on_nauvis()
    local eon_vulcanus_optimized_decorative_names = {}
    local settings = eon_vulcanus_optimized_decorative_settings()

    if settings then
        for decorative_name, _ in pairs(settings) do
            local decorative = data.raw["optimized-decorative"]
                and data.raw["optimized-decorative"][decorative_name]
            if decorative and decorative.autoplace then
                table.insert(eon_vulcanus_optimized_decorative_names, decorative_name)
                data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.decorative.settings[decorative_name] = {}
            end
        end
    end

    return eon_vulcanus_optimized_decorative_names
end

---@param tree_name string
---@param expression string
---@param vulcanus_off_aquilo_mask string
---@return nil
local function eon_set_vulcanus_tree_probability(tree_name, expression, vulcanus_off_aquilo_mask)
    local tree = data.raw.tree and data.raw.tree[tree_name]
    if not (tree and tree.autoplace) then return end

    tree.autoplace.probability_expression =
        vulcanus_off_aquilo_mask .. "(eon_mask_vulcano_terrain(" .. expression .. "))"
end

---@param settings EonVulcanusTerrainSetupSettings
---@return nil
function eon_vulcanus_terrain_setup.apply(settings)
    local aquilo_on_fulgora = settings.aquilo_on_fulgora
    local vulcanus_off_aquilo_mask = settings.vulcanus_off_aquilo_mask

    eon_autoplace_policy.set_planet_autoplace_control("nauvis", "vulcanus_volcanism")

    local eon_vulcanus_tile_names = eon_volcanus_registry.all_tiles

    if aquilo_on_fulgora then
        for _, tile_name in pairs(eon_vulcanus_tile_names) do
            data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.tile.settings[tile_name] = {}
        end
    else
        for _, tile_name in pairs(eon_volcanus_registry.volcano_spot_tiles) do
            data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.tile.settings[tile_name] = {}
        end
    end

    local eon_vulcanus_optimized_decorative_names = eon_enable_vulcanus_decoratives_on_nauvis()

    for _, entity_name in pairs(eon_volcanus_registry.entity_autoplace_on_nauvis) do
        data.raw.planet["nauvis"].map_gen_settings.autoplace_settings.entity.settings[entity_name] = {}
    end

    if aquilo_on_fulgora then
        local eon_vulcanus_tile_probability_expressions = eon_volcanus_registry
        .northern_region_tile_probability_expressions

        for tile_name, probability_expression in pairs(eon_vulcanus_tile_probability_expressions) do
            if data.raw.tile[tile_name] and data.raw.tile[tile_name].autoplace then
                data.raw.tile[tile_name].autoplace.probability_expression =
                    "eon_mask_vulcano_terrain(" .. probability_expression .. ")"
            end
        end

        data.raw.cliff["crater-cliff"].autoplace.probability_expression = "eon_crater_cliff"
    else

        eon_autoplace_masks.apply_group("mask_vulcano_coverage", eon_volcanus_registry.coverage_mask_autoplace_by_type, {
            ["tile"] = true,
        })

        data.raw.tile["volcanic-folds"].autoplace.probability_expression = "eon_updated_volcanic_folds"
        data.raw.tile["volcanic-folds-flat"].autoplace.probability_expression = "eon_updated_volcanic_folds_flat"
        data.raw.tile["lava"].autoplace.probability_expression = "eon_lava_mountains_range"
        data.raw.tile["lava-hot"].autoplace.probability_expression = "eon_lava_hot_mountains_range"
        data.raw.tile["volcanic-cracks-warm"].autoplace.probability_expression = "eon_volcano_cracks_warm_range"
        data.raw.cliff["crater-cliff"].autoplace.probability_expression = "eon_lava_hot_mountains_range"
    end

    local eon_vulcanus_decoratives_off_aquilo = eon_vulcanus_optimized_decorative_names

    local eon_vulcanus_decorative_tile_restrictions = eon_volcanus_registry.decorative_land_tiles
    local eon_vulcanus_lava_fire_tile_restrictions = eon_volcanus_registry.lava_fire_tiles
    local eon_vulcanus_trees_off_aquilo = eon_volcanus_registry.tree_names_off_aquilo

    eon_autoplace_masks.apply_group("mask_vulcano_coverage", eon_volcanus_registry.coverage_mask_autoplace_by_type, {
        ["simple-entity"] = true,
    })
    eon_autoplace_masks.apply_group("mask_vulcano_terrain", eon_volcanus_registry.terrain_mask_autoplace_by_type, {
        ["tree"] = true,
    })

    for _, name in ipairs(eon_vulcanus_trees_off_aquilo) do
        eon_terrain_autoplace.wrap_current_probability_expression("tree", name, vulcanus_off_aquilo_mask)
        eon_terrain_autoplace.restrict_to_tiles("tree", name, eon_vulcanus_decorative_tile_restrictions)
    end

    for tree_name, expression in pairs(eon_volcanus_registry.special_tree_probability_expressions) do
        eon_set_vulcanus_tree_probability(tree_name, expression, vulcanus_off_aquilo_mask)
    end

    for _, decorative_name in ipairs(eon_vulcanus_optimized_decorative_names) do
        eon_autoplace_masks.apply("mask_vulcano_terrain", "optimized-decorative", decorative_name)
    end

    for _, name in ipairs(eon_vulcanus_decoratives_off_aquilo) do
        eon_terrain_autoplace.wrap_current_probability_expression("optimized-decorative", name, vulcanus_off_aquilo_mask)
        eon_terrain_autoplace.restrict_to_tiles("optimized-decorative", name, eon_vulcanus_decorative_tile_restrictions)
    end

    local lava_fire = data.raw["optimized-decorative"] and data.raw["optimized-decorative"]["vulcanus-lava-fire"]
    if lava_fire and lava_fire.autoplace then
        lava_fire.autoplace.probability_expression =
            vulcanus_off_aquilo_mask .. "(eon_mask_vulcano_terrain(0.04))"
        eon_autoplace_policy.set_autoplace_tile_restriction(lava_fire, eon_vulcanus_lava_fire_tile_restrictions)
    end
end

return eon_vulcanus_terrain_setup
