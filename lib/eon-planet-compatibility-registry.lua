local registry = {}

registry.prototype_types = {
    "tile",
    "optimized-decorative",
    "resource",
    "simple-entity",
    "tree",
    "cliff",
    "unit-spawner",
    "turret",
    "lightning-attractor",
}

registry.category_prototype_types = {
    tile = { "tile" },
    decorative = { "optimized-decorative" },
    entity = {
        "resource",
        "simple-entity",
        "tree",
        "cliff",
        "unit-spawner",
        "turret",
        "lightning-attractor",
    },
}

registry.controlled_planets = {
    nauvis = true,
    fulgora = true,
}

registry.property_prefix_by_category = {
    tile = "tile",
    decorative = "decorative",
    entity = "entity",
}

return registry
