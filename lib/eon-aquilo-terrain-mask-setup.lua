local eon_autoplace_masks = require("lib.eon-autoplace-masks")
local eon_aquilo_registry = require("lib.eon-aquilo-registry")
local eon_terrain_autoplace = require("lib.eon-terrain-autoplace")
local biomes = require("lib.eon-biome-registry")

local aquilo_masks = biomes.get("aquilo").masks

local eon_aquilo_terrain_mask_setup = {}

---@param expression string
---@param in_aquilo_only boolean
---@return string
function eon_aquilo_terrain_mask_setup.mask_resource_tiles(expression, in_aquilo_only)
    local mask = in_aquilo_only and aquilo_masks.resource_tiles or aquilo_masks.off_resource_tiles
    return mask .. "(" .. expression .. ")"
end

---@param options table
---@return nil
function eon_aquilo_terrain_mask_setup.apply(options)
    local aquilo_on_fulgora = options.aquilo_on_fulgora
    local guarded_resources_enabled = options.guarded_resources_enabled

    if guarded_resources_enabled then
        eon_autoplace_masks.apply_group("mask_aquilo_territory", eon_aquilo_registry.territory_mask_autoplace_by_type, {
            ["resource"] = true,
        })
    end

    eon_autoplace_masks.apply_group("mask_aquilo_territory", eon_aquilo_registry.territory_mask_autoplace_by_type, {
        ["tile"] = true,
        ["simple-entity"] = true,
    })
    eon_autoplace_masks.apply_group("mask_aquilo_decorative_territory",
        eon_aquilo_registry.decorative_territory_mask_autoplace_by_type)
    eon_autoplace_masks.apply_group("mask_aquilo_snow_decorative_territory",
        eon_aquilo_registry.snow_decorative_territory_mask_autoplace_by_type)

    if not aquilo_on_fulgora then return end

    eon_terrain_autoplace.extend_tile_restriction(
        "optimized-decorative",
        "aqulio-snowy-decal",
        eon_aquilo_registry.snow_decorative_tiles
    )

    eon_terrain_autoplace.restrict_to_tiles(
        "optimized-decorative",
        "snow-drift-decal",
        eon_aquilo_registry.snow_decorative_tiles
    )
end

return eon_aquilo_terrain_mask_setup
