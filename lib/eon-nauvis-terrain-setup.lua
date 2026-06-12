local eon_autoplace_masks = require("lib.eon-autoplace-masks")
local eon_nauvis_registry = require("lib.eon-nauvis-registry")
local eon_terrain_autoplace = require("lib.eon-terrain-autoplace")
local biomes = require("lib.eon-biome-registry")

local nauvis_masks = biomes.get("nauvis").masks
local fulgora_masks = biomes.get("fulgora").masks
local aquilo_masks = biomes.get("aquilo").masks

local eon_nauvis_terrain_setup = {}

---@class EonNauvisTerrainSetupConfig
---@field nauvis_territory_expression string Body of the Nauvis territory mask noise function.
---@field nauvis_cliffiness_expression string Nauvis cliff probability expression.
---@field gleba_continuous_cliffiness_expression string Cliffiness expression used in Gleba territory.
---@field vulcanus_cliffiness_expression string Cliffiness expression used in Vulcanus territory.
---@field blended_cliffiness_expression string Combined biome-aware cliffiness expression.
---@field blended_cliff_elevation_expression string Combined biome-aware cliff elevation expression.
---@field mask_native_tiles_off_aquilo boolean Whether native Nauvis tiles must be excluded from Aquilo territory.

---@param config EonNauvisTerrainSetupConfig
---@return nil
function eon_nauvis_terrain_setup.apply(config)
    -- Legacy Fulgora/Aquilo mask names are save-compatibility aliases. Do not remove them.
    local fulgora_territory_expression = "if(eon_fulgora_aquilo_territory_mask, -inf, expression)"
    local aquilo_on_fulgora_territory_expression = "if(y < eon_fulgora_aquilo_boundary, expression, -inf)"

    data:extend({
        {
            type = "noise-expression",
            name = "eon_starting_radius",
            expression = "0.7 * 0.75"
        },
    })

    data.raw.tile["water"].autoplace.probability_expression = "eon_updated_water + if(eon_gleba_region(-10), -inf, 0)"
    data.raw.tile["deepwater"].autoplace.probability_expression =
    "eon_updated_deepwater + if(eon_gleba_region(-100), -inf, 0)"

    data.raw["noise-expression"]["trees_forest_path_cutout_faded"].expression =
    nauvis_masks.territory .. "(trees_forest_path_cutout * 0.3 + tree_small_noise * 0.1)"

    eon_autoplace_masks.apply_group(
        eon_nauvis_registry.native_mask_policy,
        eon_nauvis_registry.native_autoplace_manifest()
    )

    if config.mask_native_tiles_off_aquilo then
        for _, tile_name in ipairs(eon_nauvis_registry.tiles) do
            eon_terrain_autoplace.wrap_current_probability_expression(
                "tile",
                tile_name,
                aquilo_masks.off_territory
            )
        end

        for _, tile_name in ipairs({ "water", "deepwater" }) do
            eon_terrain_autoplace.wrap_current_probability_expression(
                "tile",
                tile_name,
                aquilo_masks.off_territory
            )
        end
    end

    data.raw["noise-expression"]["cliffiness_nauvis"].expression = config.nauvis_cliffiness_expression

    data:extend({
        {
            type = "noise-expression",
            name = "eon_updated_water",
            expression = nauvis_masks.territory .. "(eon_water_base(0, 100) + eon_gleba_region(-100))"
        },
        {
            type = "noise-expression",
            name = "eon_updated_deepwater",
            expression = nauvis_masks.territory .. "(eon_water_base(-2, 200))"
        },
        {
            type = "noise-expression",
            name = "eon_gleba_continuous_cliffiness",
            expression = config.gleba_continuous_cliffiness_expression
        },
        {
            type = "noise-expression",
            name = "eon_vulcanus_cliffiness",
            expression = config.vulcanus_cliffiness_expression
        },
        {
            type = "noise-expression",
            name = "eon_blended_cliffiness",
            expression = config.blended_cliffiness_expression
        },
        {
            type = "noise-expression",
            name = "eon_blended_cliff_elevation",
            expression = config.blended_cliff_elevation_expression
        },
        {
            type = "noise-expression",
            name = "eon_resource_territory",
            expression = "eon_aquilo_base(eon_aquilo_ammonia_depth + 2, 200)"
        },
        {
            type = "noise-function",
            name = "eon_identity",
            parameters = { "expression" },
            expression = "expression"
        },
        {
            type = "noise-function",
            name = nauvis_masks.territory,
            parameters = { "expression" },
            expression = config.nauvis_territory_expression
        },
        {
            type = "noise-function",
            name = nauvis_masks.off_territory,
            parameters = { "expression" },
            expression = "if(" .. nauvis_masks.territory .. "(expression) < 0, expression, -inf)"
        },
        {
            type = "noise-function",
            name = nauvis_masks.resource_territory,
            parameters = { "expression" },
            expression =
            "if(eon_resource_territory <= 0, if(eon_aquilo_mask, if(eon_aquilo_resource_placeable_land, expression, -inf), expression), -inf)"
        },
        {
            type = "noise-function",
            name = fulgora_masks.territory,
            parameters = { "expression" },
            expression = fulgora_territory_expression
        },
        {
            type = "noise-function",
            name = fulgora_masks.off_territory,
            parameters = { "expression" },
            expression = aquilo_on_fulgora_territory_expression
        },
        {
            type = "noise-function",
            name = fulgora_masks.aquilo_territory,
            parameters = { "expression" },
            expression = aquilo_on_fulgora_territory_expression
        },
        {
            type = "noise-function",
            name = fulgora_masks.off_aquilo_territory,
            parameters = { "expression" },
            expression = fulgora_territory_expression
        },
        {
            type = "noise-function",
            name = aquilo_masks.territory_on_fulgora,
            parameters = { "expression" },
            expression = aquilo_on_fulgora_territory_expression
        },
        {
            type = "noise-function",
            name = aquilo_masks.off_territory_on_fulgora,
            parameters = { "expression" },
            expression = fulgora_territory_expression
        },
    })
end

return eon_nauvis_terrain_setup
