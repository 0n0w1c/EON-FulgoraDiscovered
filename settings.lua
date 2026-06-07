data:extend({
    {
        type = "bool-setting",
        name = "eon-fd-planet-sounds",
        setting_type = "startup",
        default_value = false,
        order = "a",
    },
    {
        type = "bool-setting",
        name = "eon-fd-gleba-enemies-react-to-pollution",
        setting_type = "startup",
        default_value = false,
        order = "b",
    },
    {
        type = "bool-setting",
        name = "eon-fd-use-tungsten-plate",
        setting_type = "startup",
        default_value = false,
        order = "c",
    },
    {
        type = "bool-setting",
        name = "eon-fd-guarded-resources",
        setting_type = "startup",
        default_value = false,
        order = "d",
    },
    {
        type = "bool-setting",
        name = "eon-fd-aquilo-on-fulgora",
        setting_type = "startup",
        default_value = false,
        order = "e"
    },
    {
        type = "bool-setting",
        name = "eon-fd-biome-weather",
        setting_type = "startup",
        default_value = false,
        order = "f",
    },
    {
        type = "bool-setting",
        name = "eon-fd-hide-craft-deco-2-technology",
        setting_type = "startup",
        default_value = false,
        hidden = not mods["craft-deco-2"],
        order = "z"
    },
})
