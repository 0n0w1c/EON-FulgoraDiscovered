local data_util = require("data-util")
local eon_aquilo_registry = require("lib.eon-aquilo-registry")
local eon_fulgora_registry = require("lib.eon-fulgora-registry")
local eon_noise_expressions = require("lib.eon-noise-expressions")
local eon_terrain_autoplace = require("lib.eon-terrain-autoplace")
local eon_terrain_map_gen = require("lib.eon-terrain-map-gen")

local fulgora_aquilo_resources = {}

local eon_aquilo_decorative_names = eon_aquilo_registry.decorative_set
local eon_aquilo_entity_names = eon_aquilo_registry.entity_set
local eon_aquilo_tile_names = eon_aquilo_registry.tile_set

---@return nil
local function mask_fulgora_oil_ocean_off_aquilo_ocean_edge()
    for _, tile_name in pairs(eon_fulgora_registry.oil_ocean_tiles) do
        local tile = data.raw.tile and data.raw.tile[tile_name]
        eon_terrain_autoplace.wrap_probability_expression(tile, "eon_mask_off_aquilo_ocean_edge")
    end
end

---@param mask_resource_tiles fun(expression: string, in_aquilo_only: boolean): string
---@return nil
local function apply_fulgora_aquilo_resources(mask_resource_tiles)
    for _, resource_name in ipairs(eon_aquilo_registry.resources) do
        local resource = data.raw.resource and data.raw.resource[resource_name]

        if resource and resource.autoplace then
            local probability_expression_name = "eon_fulgora_aquilo_" ..
                string.gsub(resource_name, "[^%w_]", "_") .. "_probability"
            local original_probability_expression_name = data_util.generate_eon_name(resource_name)

            eon_noise_expressions.set_or_extend(
                probability_expression_name,
                mask_resource_tiles(original_probability_expression_name, true)
            )

            resource.autoplace.probability_expression = probability_expression_name
            eon_terrain_map_gen.set_entity_property_expression("fulgora", resource_name, "probability",
                probability_expression_name)
            eon_terrain_map_gen.set_resource_property_expression_if_string(
                "fulgora",
                resource_name,
                "richness",
                resource.autoplace.richness_expression
            )
        end
    end
end

---@return nil
local function apply_fulgora_scrap_off_aquilo()
    local scrap = data.raw.resource and data.raw.resource[eon_fulgora_registry.scrap_resource]
    if scrap and scrap.autoplace then
        local probability_expression = scrap.autoplace.probability_expression

        if type(probability_expression) == "string" then
            local probability_expression_name = "eon_fulgora_scrap_probability"
            local richness_expression_name = "eon_fulgora_scrap_richness"
            local scrap_local_expressions = eon_noise_expressions.normalize_local_expressions(scrap.autoplace
            .local_expressions)

            eon_noise_expressions.set_or_extend(
                probability_expression_name,
                "eon_mask_off_aquilo_territory(" .. probability_expression .. ")",
                scrap_local_expressions
            )

            scrap.autoplace.probability_expression = probability_expression_name
            eon_terrain_map_gen.set_entity_property_expression("fulgora", eon_fulgora_registry.scrap_resource,
                "probability", probability_expression_name)

            local richness_expression = scrap.autoplace.richness_expression
            if type(richness_expression) == "string" then
                eon_noise_expressions.set_or_extend(
                    richness_expression_name,
                    richness_expression,
                    scrap_local_expressions
                )
                eon_terrain_map_gen.set_entity_property_expression("fulgora", eon_fulgora_registry.scrap_resource,
                    "richness", richness_expression_name)
            end
        end
    end
end

---@param args table
---@return nil
function fulgora_aquilo_resources.apply(args)
    local mask_resource_tiles = args.mask_resource_tiles

    local fulgora_map_gen = eon_fulgora_registry.map_gen_settings()
    fulgora_map_gen.property_expression_names = fulgora_map_gen.property_expression_names or {}
    fulgora_map_gen.property_expression_names["cliffiness"] =
        eon_fulgora_registry.cliffiness_property_expression

    local fulgora_settings = eon_fulgora_registry.autoplace_settings()

    if fulgora_settings then
        for tile_name, _ in pairs(fulgora_settings.tile.settings) do
            if not eon_aquilo_tile_names[tile_name] and data.raw.tile[tile_name] then
                eon_terrain_autoplace.wrap_probability_expression(data.raw.tile[tile_name],
                    "eon_mask_off_aquilo_territory")
            end
        end

        for decorative_name, _ in pairs(fulgora_settings.decorative.settings) do
            if not eon_aquilo_decorative_names[decorative_name] then
                eon_terrain_autoplace.wrap_probability_expression(data.raw["optimized-decorative"][decorative_name],
                    "eon_mask_off_aquilo_territory")
            end
        end
    end

    mask_fulgora_oil_ocean_off_aquilo_ocean_edge()

    if fulgora_settings then
        for entity_name, _ in pairs(fulgora_settings.entity.settings) do
            if not eon_aquilo_entity_names[entity_name] then
                eon_terrain_autoplace.wrap_probability_expression(
                    eon_terrain_autoplace.entity_prototype(entity_name),
                    "eon_mask_off_aquilo_territory")
            end
        end

        for _, entity_name in pairs(eon_fulgora_registry.extra_entities_to_mask_off_aquilo) do
            eon_terrain_autoplace.wrap_probability_expression(
                eon_terrain_autoplace.entity_prototype(entity_name),
                "eon_mask_off_aquilo_territory")
        end
    end

    apply_fulgora_aquilo_resources(mask_resource_tiles)
    apply_fulgora_scrap_off_aquilo()
end

return fulgora_aquilo_resources
