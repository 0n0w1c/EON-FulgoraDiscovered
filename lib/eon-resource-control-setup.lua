local eon_autoplace_policy = require("lib.eon-autoplace-policy")

---@class EonResourceControlSetupConfig
---@field guarded_resources_enabled boolean

local resource_control_setup = {}

---@param planet_name string
---@return nil
local function enable_planet_resource_autoplace_controls(planet_name)
    eon_autoplace_policy.copy_planet_autoplace_controls_by_category(planet_name, "nauvis", "resource")
end

---@return nil
local function enable_gleba_stone_autoplace()
    eon_autoplace_policy.ensure_planet_autoplace_setting("gleba", "entity", "stone")
    eon_autoplace_policy.set_planet_autoplace_control("gleba", "stone", true)
end

---@param config EonResourceControlSetupConfig
---@return nil
function resource_control_setup.apply(config)
    local guarded_resources_enabled = config.guarded_resources_enabled

    data.raw["noise-expression"]["aquilo_crude_oil_spots"].expression = "0"
    data.raw.planet["aquilo"].map_gen_settings.autoplace_controls = {}

    data.raw["autoplace-control"]["gleba_plants"].localised_description = nil

    enable_gleba_stone_autoplace()

    if guarded_resources_enabled then
        enable_planet_resource_autoplace_controls("nauvis")
        enable_planet_resource_autoplace_controls("gleba")
        enable_planet_resource_autoplace_controls("vulcanus")
    end

    table.insert(data.raw["simple-entity"]["big-volcanic-rock"].minable.results,
        { type = "item", name = "calcite", amount_min = 2, amount_max = 8 })
    table.insert(data.raw["simple-entity"]["huge-volcanic-rock"].minable.results,
        { type = "item", name = "calcite", amount_min = 3, amount_max = 15 })

    data.raw["autoplace-control"]["vulcanus_volcanism"].order = "c-z-ca"
    data.raw["autoplace-control"]["vulcanus_volcanism"].category = "terrain"
    data.raw["autoplace-control"]["vulcanus_volcanism"].localised_description = nil

    data.raw["autoplace-control"]["sulfuric_acid_geyser"].order = "b-z"

    data.raw["autoplace-control"]["scrap"].order = "e-ca"

    eon_autoplace_policy.ensure_planet_autoplace_settings("nauvis", "entity", {
        "calcite",
        "sulfuric-acid-geyser",
        "tungsten-ore",
    })

    data.raw.planet["nauvis"].map_gen_settings.autoplace_controls["sulfuric_acid_geyser"] = {}

    if guarded_resources_enabled then
        data.raw.planet["nauvis"].map_gen_settings.autoplace_controls["calcite"] = {}
        data.raw.planet["nauvis"].map_gen_settings.autoplace_controls["tungsten_ore"] = {}
    end

    data.raw["noise-expression"]["vulcanus_starting_calcite"].expression = "-inf"
    data.raw["noise-expression"]["vulcanus_starting_sulfur"].expression = "-inf"
    data.raw["noise-expression"]["vulcanus_starting_tungsten"].expression = "-inf"
end

return resource_control_setup
