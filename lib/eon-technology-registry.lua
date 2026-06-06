local registry = {}

registry.solar_system_edge_discovery = {
    type = "technology",
    name = "solar-system-edge-discovery",
    icon = "__space-age__/graphics/icons/solar-system-edge.png",
    icon_size = 64,
    essential = true,
    effects = {
        {
            type = "unlock-space-location",
            space_location = "solar-system-edge",
            use_icon_overlay_constant = true,
        },
        { type = "unlock-recipe", recipe = "ammoniacal-solution-separation" },
        { type = "unlock-recipe", recipe = "solid-fuel-from-ammonia" },
        { type = "unlock-recipe", recipe = "ammonia-rocket-fuel" },
        { type = "unlock-recipe", recipe = "ice-platform" },
    },
    prerequisites = {
        "electromagnetic-science-pack",
        "metallurgic-science-pack",
        "advanced-asteroid-processing",
    },
    unit = {
        count = 2000,
        ingredients = {
            { "automation-science-pack",      1 },
            { "logistic-science-pack",        1 },
            { "chemical-science-pack",        1 },
            { "production-science-pack",      1 },
            { "utility-science-pack",         1 },
            { "space-science-pack",           1 },
            { "metallurgic-science-pack",     1 },
            { "agricultural-science-pack",    1 },
            { "electromagnetic-science-pack", 1 },
        },
        time = 60,
    },
}

registry.prerequisites_to_append = {
    ["promethium-science-pack"] = {
        "solar-system-edge-discovery",
    },
}

registry.prerequisite_replacements = {
    ["lithium-processing"] = {
        "rocket-turret",
        "advanced-asteroid-processing",
        "heating-tower",
        "asteroid-reprocessing",
    },
    agriculture = { "landfill", "steel-processing" },
    ["heating-tower"] = { "concrete" },
}

registry.unit_replacements = {
    ["calcite-processing"] = {
        prerequisites = { "production-science-pack" },
        research_trigger = false,
        unit = {
            count = 100,
            ingredients = {
                { "automation-science-pack", 1 },
                { "logistic-science-pack",   1 },
                { "chemical-science-pack",   1 },
                { "production-science-pack", 1 },
            },
            time = 30,
        },
    },
    ["tungsten-carbide"] = {
        prerequisites = { "production-science-pack" },
        research_trigger = false,
        unit = {
            count = 200,
            ingredients = {
                { "automation-science-pack", 1 },
                { "logistic-science-pack",   1 },
                { "chemical-science-pack",   1 },
                { "production-science-pack", 1 },
            },
            time = 60,
        },
    },
}

return registry
