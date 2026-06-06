local registry = {}

local function make_set(names)
    local set = {}
    for _, name in ipairs(names) do
        set[name] = true
    end
    return set
end

registry.autoplace_controls = {
    "lithium_brine",
    "fluorine_vent",
    "ammonia_ocean",
}

registry.resource_controls = {
    ["lithium-brine"] = "lithium_brine",
    ["fluorine-vent"] = "fluorine_vent",
}

registry.resources = {
    "lithium-brine",
    "fluorine-vent",
}
registry.resource_set = make_set(registry.resources)

registry.entities = {
    "lithium-brine",
    "fluorine-vent",
    "lithium-iceberg-huge",
    "lithium-iceberg-big",
}
registry.entity_set = make_set(registry.entities)

registry.tiles = {
    "snow-flat",
    "snow-crests",
    "snow-lumpy",
    "snow-patchy",
    "ice-rough",
    "ice-smooth",
    "brash-ice",
    "ammoniacal-ocean",
    "ammoniacal-ocean-2",
}
registry.tile_set = make_set(registry.tiles)

registry.decoratives = {
    "lithium-iceberg-medium",
    "lithium-iceberg-small",
    "lithium-iceberg-tiny",
    "floating-iceberg-large",
    "floating-iceberg-small",
    "aqulio-ice-decal-blue",
    "aqulio-snowy-decal",
    "snow-drift-decal",
}
registry.decorative_set = make_set(registry.decoratives)

registry.snow_decorative_tiles = {
    "snow-flat",
    "snow-crests",
    "snow-lumpy",
    "snow-patchy",
    "ice-rough",
    "ice-smooth",
    "fulgoran-rock",
    "fulgoran-dust",
    "fulgoran-sand",
    "fulgoran-dunes",
    "fulgoran-walls",
    "fulgoran-paving",
    "fulgoran-conduit",
    "fulgoran-machinery",
}
registry.snow_decorative_tile_set = make_set(registry.snow_decorative_tiles)

registry.territory_mask_autoplace_by_type = {
    resource = registry.resources,
    ["simple-entity"] = {
        "lithium-iceberg-huge",
        "lithium-iceberg-big",
    },
    tile = {
        "snow-crests",
        "snow-lumpy",
        "snow-patchy",
    },
}

registry.decorative_territory_mask_autoplace_by_type = {
    ["optimized-decorative"] = {
        "lithium-iceberg-medium",
        "lithium-iceberg-small",
        "lithium-iceberg-tiny",
        "floating-iceberg-large",
        "floating-iceberg-small",
        "aqulio-ice-decal-blue",
    },
}

registry.snow_decorative_territory_mask_autoplace_by_type = {
    ["optimized-decorative"] = {
        "aqulio-snowy-decal",
        "snow-drift-decal",
    },
}

---@param mode table|nil
---@return string
function registry.target_planet_name(mode)
    return mode and mode.aquilo_on_fulgora and "fulgora" or "nauvis"
end

---@param mode table|nil
---@return string
function registry.inactive_planet_name(mode)
    return mode and mode.aquilo_on_fulgora and "nauvis" or "fulgora"
end

return registry
