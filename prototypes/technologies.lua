local data_util = require("data-util")

local technologies = data.raw["technology"]

-- Add new technology for traveling to solar system edge
data:extend({
    {
        type = "technology",
        name = "solar-system-edge-discovery",
        icon = "__space-age__/graphics/icons/solar-system-edge.png",
        icon_size = 64,
        essential = true,
        effects =
        {
            {
                type = "unlock-space-location",
                space_location = "solar-system-edge",
                use_icon_overlay_constant = true
            },
            {
                type = "unlock-recipe",
                recipe = "ammoniacal-solution-separation",
            },
            {
                type = "unlock-recipe",
                recipe = "solid-fuel-from-ammonia"
            },
            {
                type = "unlock-recipe",
                recipe = "ammonia-rocket-fuel"
            },
            {
                type = "unlock-recipe",
                recipe = "ice-platform",
            }
        },
        prerequisites = { "electromagnetic-science-pack", "metallurgic-science-pack", "advanced-asteroid-processing" },
        unit =
        {
            count = 2000,
            ingredients =
            {
                { "automation-science-pack",      1 },
                { "logistic-science-pack",        1 },
                { "chemical-science-pack",        1 },
                { "production-science-pack",      1 },
                { "utility-science-pack",         1 },
                { "space-science-pack",           1 },
                { "metallurgic-science-pack",     1 },
                { "agricultural-science-pack",    1 },
                { "electromagnetic-science-pack", 1 }
            },
            time = 60
        }
    },
})

-- Add prerequisite to promethium-science-pack
table.insert(technologies["promethium-science-pack"].prerequisites, "solar-system-edge-discovery")

-- Aquilo
technologies["lithium-processing"].prerequisites = { "rocket-turret", "advanced-asteroid-processing", "heating-tower",
    "asteroid-reprocessing" }

-- Gleba
technologies["agriculture"].prerequisites = { "landfill", "steel-processing" }
technologies["heating-tower"].prerequisites = { "concrete" }

-- Vulcanus
technologies["calcite-processing"].prerequisites = { "production-science-pack" }
technologies["calcite-processing"].research_trigger = nil
technologies["calcite-processing"].unit = {
    count = 100,
    ingredients = {
        { "automation-science-pack", 1 },
        { "logistic-science-pack",   1 },
        { "chemical-science-pack",   1 },
        { "production-science-pack", 1 }
    },
    time = 5
}
technologies["tungsten-carbide"].prerequisites = { "production-science-pack" }
technologies["tungsten-carbide"].research_trigger = nil
technologies["tungsten-carbide"].unit = {
    count = 100,
    ingredients = {
        { "automation-science-pack", 1 },
        { "logistic-science-pack",   1 },
        { "chemical-science-pack",   1 },
        { "production-science-pack", 1 }
    },
    time = 5
}
