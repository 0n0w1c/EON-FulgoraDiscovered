local registry = {}

registry.non_nauvis_planets = {
    fulgora = true,
    gleba = true,
    vulcanus = true,
    aquilo = true,
}

registry.trees = {
    subgroups = {
        ["craftable-simple-trees"] = true,
        ["craftable-alive-trees"] = true,
        ["craftable-trees"] = true,
        ["craftable-alien-biomes-trees"] = true,
    },

    palm = {
        names = {
            ["tree-palm-a"] = true,
            ["tree-palm-b"] = true,
        },
        tile_restrictions = {
            "sand-1",
            "sand-2",
            "sand-3",
            "red-desert-0",
            "red-desert-1",
            "red-desert-2",
            "red-desert-3",
        },
    },

    volcanic = {
        names = {
            ["tree-volcanic-a"] = true,
        },
        tile_restrictions = {
            "volcanic-ash-cracks",
            "volcanic-ash-dark",
            "volcanic-ash-flats",
            "volcanic-ash-light",
            "volcanic-ash-soil",
            "volcanic-cracks",
            "volcanic-cracks-hot",
            "volcanic-cracks-warm",
            "volcanic-folds",
            "volcanic-folds-flat",
            "volcanic-folds-warm",
            "volcanic-jagged-ground",
            "volcanic-pumice-stones",
            "volcanic-smooth-stone",
            "volcanic-smooth-stone-warm",
            "volcanic-soil-dark",
            "volcanic-soil-light",
        },
        density_expression = {
            name = "eon_vulcanus_ashland_tree_density",
            expression = "max(tree_06, tree_08_red, tree_09_red)",
        },
    },

    snow = {
        names = {
            ["tree-snow-a"] = true,
        },
        tile_restrictions = {
            "snow-flat",
            "snow-crests",
            "snow-lumpy",
            "snow-patchy",
        },
    },

    alien_biomes_expression_families = {
        wetland = { "tree_01", "tree_04", "tree_05", "tree_07" },
        grassland = { "tree_02", "tree_03", "tree_04", "tree_05", "tree_07" },
        dryland = { "tree_06", "tree_06_brown", "tree_08", "tree_08_brown", "tree_09", "tree_09_brown" },
        desert = { "tree_06", "tree_06_brown", "tree_08_red", "tree_09_red" },
        snow = { "tree_02" },
        volcanic = { "tree_06", "tree_08_red", "tree_09_red" },
        palm = { "tree_04", "tree_05" },
    },
}

registry.rocks = {
    subgroups = {
        ["craftable-rocks"] = true,
        ["craftable-alien-biomes-rocks"] = true,
        ["craftable-simple-rocks"] = true,
    },

    families = {
        {
            base_name = "huge-rock",
            pattern = "^rock%-huge%-",
        },
        {
            base_name = "big-rock",
            pattern = "^rock%-big%-",
        },
    },
}

return registry
