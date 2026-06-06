local terrain = require("map-generation.terrain")
local eon_autoplace_masks = require("lib.eon-autoplace-masks")
local eon_resource_registry = require("lib.eon-resource-registry")
local eon_mode = require("lib.eon-mode")
local eon_resource_mode = require("lib.eon-resource-mode")
local eon_aquilo_resource_tiles = require("lib.eon-aquilo-resource-tile-policy")
local eon_guarded_resource_biome_policy = require("lib.eon-guarded-resource-biome-policy")
local eon_resource_aligned_decorative_policy = require("lib.eon-resource-aligned-decorative-policy")
local eon_resource_control_setup = require("lib.eon-resource-control-setup")
local eon_direct_resource_expression_policy = require("lib.eon-direct-resource-expression-policy")
local eon_vulcanus_resource_expressions = require("lib.eon-vulcanus-resource-expression-prototypes")
local eon_vulcanus_tungsten_policy = require("lib.eon-vulcanus-tungsten-resource-policy")
local eon_resource_masks = require("lib.eon-resource-masks")
local eon_guarded_nauvis_resource_mask_policy = require("lib.eon-guarded-nauvis-resource-mask-policy")
local eon_nauvis_resource_setting_policy = require("lib.eon-nauvis-resource-setting-policy")

local guarded_resources_enabled = eon_mode.guarded_resources
local eon_aquilo_on_fulgora = eon_mode.aquilo_on_fulgora
local eon_resource_mode_values = eon_resource_mode.values({
    aquilo_on_fulgora = eon_aquilo_on_fulgora,
    guarded_resources_enabled = guarded_resources_enabled,
})

local eon_unrestricted_vulcanus_resource_mode = eon_resource_mode_values.unrestricted_vulcanus_resource_mode
local mask_vulcanus_resources_off_ammonia_ocean = eon_resource_mode_values.mask_vulcanus_resources_off_ammonia_ocean
local eon_vulcanus_resource_richness_expression = eon_resource_mode_values.vulcanus_resource_richness_expression
local eon_vulcanus_tungsten_richness_expression = eon_resource_mode_values.vulcanus_tungsten_richness_expression
local resource_masks = eon_resource_masks.from_mode_values(eon_resource_mode_values)
local mask_off_ammonia_ocean = resource_masks.mask_off_ammonia_ocean
local mask_off_aquilo_territory = resource_masks.mask_off_aquilo_territory
local mask_off_aquilo_resource_tiles = resource_masks.mask_off_aquilo_resource_tiles
local mask_vulcanus_resource_terrain = resource_masks.mask_vulcanus_resource_terrain
local mask_vulcanus_coverage = resource_masks.mask_vulcanus_coverage

if guarded_resources_enabled then
    eon_guarded_nauvis_resource_mask_policy.apply({
        resources = eon_resource_registry.guarded_nauvis_resources,
        apply_resource_territory_mask = function(resource_name)
            eon_autoplace_masks.apply("mask_resource_territory", "resource", resource_name)
        end,
    })
end

eon_resource_control_setup.apply({
    guarded_resources_enabled = guarded_resources_enabled,
})

data:extend(eon_vulcanus_resource_expressions.noise_prototypes({
    guarded_resources_enabled = guarded_resources_enabled,
    mask_vulcanus_resource_terrain = mask_vulcanus_resource_terrain,
    mask_off_ammonia_ocean = mask_off_ammonia_ocean,
    mask_off_aquilo_resource_tiles = mask_off_aquilo_resource_tiles,
    vulcanus_resource_richness_expression = eon_vulcanus_resource_richness_expression,
}))

eon_vulcanus_tungsten_policy.configure({
    guarded_resources_enabled = guarded_resources_enabled,
    guarded_policy = eon_resource_registry.guarded_tungsten_policy,
    tungsten_richness_expression = eon_vulcanus_tungsten_richness_expression,
    mask_off_aquilo_territory = mask_off_aquilo_territory,
    mask_off_ammonia_ocean = mask_off_ammonia_ocean,
    mask_vulcanus_coverage = mask_vulcanus_coverage,
    apply_resource_territory_mask = function(resource_name)
        eon_autoplace_masks.apply("mask_resource_territory", "resource", resource_name)
    end,
})

if guarded_resources_enabled then
    eon_direct_resource_expression_policy.apply_entry(eon_resource_registry.guarded_direct_resource_expressions[1])

    eon_vulcanus_tungsten_policy.set_guarded_resource_probability({
        resource_name = "tungsten-ore",
        probability = "vulcanus_tungsten_ore_probability * (1 - clamp(vulcanus_sulfuric_acid_region_patchy, 0, 1))",
        mask_off_aquilo_territory = mask_off_aquilo_territory,
        mask_off_ammonia_ocean = mask_off_ammonia_ocean,
        mask_vulcanus_coverage = mask_vulcanus_coverage,
    })

    eon_guarded_resource_biome_policy.align({ aquilo_on_fulgora = eon_aquilo_on_fulgora })

    eon_direct_resource_expression_policy.apply_entries(eon_resource_registry.guarded_direct_resource_expressions)

    if not eon_aquilo_on_fulgora then
        eon_direct_resource_expression_policy.apply_entries(eon_resource_registry
        .guarded_aquilo_nauvis_direct_resource_expressions)
    end
else
    eon_direct_resource_expression_policy.apply_entries(eon_resource_registry.unrestricted_direct_resource_expressions)
end

eon_resource_aligned_decorative_policy.apply({
    guarded_resources_enabled = guarded_resources_enabled,
    entries_by_mode = eon_resource_registry.vulcanus_resource_aligned_decoratives,
    mask_off_ammonia_ocean = mask_off_ammonia_ocean,
    mask_vulcanus_resource_terrain = mask_vulcanus_resource_terrain,
})

eon_nauvis_resource_setting_policy.apply_unrestricted_vulcanus_resource_boost({
    enabled = eon_unrestricted_vulcanus_resource_mode,
    boost_policy = require("lib.eon-unrestricted-vulcanus-resource-boost"),
    resource_configs = eon_resource_registry.unrestricted_vulcanus_resource_configs,
})

eon_nauvis_resource_setting_policy.mask_off_ammonia_ocean({
    enabled = mask_vulcanus_resources_off_ammonia_ocean,
    ocean_policy = require("lib.eon-resource-ocean-policy"),
    mask_off_ammonia_ocean = mask_off_ammonia_ocean,
})

eon_aquilo_resource_tiles.apply_resource_probability_masks()
