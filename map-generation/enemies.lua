local terrain = require("map-generation.terrain")

data:extend({
    {
        type = "noise-expression",
        name = "biter_spawner",
        expression = data.raw["unit-spawner"]["biter-spawner"].autoplace.probability_expression
    },
    {
        type = "noise-expression",
        name = "spitter_spawner",
        expression = data.raw["unit-spawner"]["spitter-spawner"].autoplace.probability_expression
    },
    {
        type = "noise-expression",
        name = "small_worm_turret",
        expression = data.raw["turret"]["small-worm-turret"].autoplace.probability_expression
    },
    {
        type = "noise-expression",
        name = "medium_worm_turret",
        expression = data.raw["turret"]["medium-worm-turret"].autoplace.probability_expression
    },
    {
        type = "noise-expression",
        name = "big_worm_turret",
        expression = data.raw["turret"]["big-worm-turret"].autoplace.probability_expression
    },
    {
        type = "noise-expression",
        name = "behemoth_worm_turret",
        expression = data.raw["turret"]["behemoth-worm-turret"].autoplace.probability_expression
    },
})

data.raw["unit-spawner"]["biter-spawner"].autoplace.probability_expression = "eon_mask_nauvis_territory(biter_spawner)"
data.raw["unit-spawner"]["spitter-spawner"].autoplace.probability_expression =
"eon_mask_nauvis_territory(spitter_spawner)"

data.raw["turret"]["small-worm-turret"].autoplace.probability_expression = "eon_mask_nauvis_territory(small_worm_turret)"
data.raw["turret"]["medium-worm-turret"].autoplace.probability_expression =
"eon_mask_nauvis_territory(medium_worm_turret)"

data.raw["turret"]["big-worm-turret"].autoplace.probability_expression = "eon_mask_nauvis_territory(big_worm_turret)"
data.raw["turret"]["behemoth-worm-turret"].autoplace.probability_expression =
"eon_mask_nauvis_territory(behemoth_worm_turret)"

if mods["ArmouredBiters"] then
    local armoured_biter_spawner = data.raw["unit-spawner"] and data.raw["unit-spawner"]["armoured-biter-spawner"]
    if armoured_biter_spawner
        and armoured_biter_spawner.autoplace
        and armoured_biter_spawner.autoplace.probability_expression
    then
        data:extend({
            {
                type = "noise-expression",
                name = "armoured_biter_spawner",
                expression = armoured_biter_spawner.autoplace.probability_expression
            },
        })

        armoured_biter_spawner.autoplace.probability_expression =
        "eon_mask_nauvis_territory(armoured_biter_spawner)"
    end
end

if mods["Explosive_biters"] then
    ---@param expression string
    ---@return string
    local function eon_explosive_probability_expression(expression)
        expression = string.gsub(expression, "^enemy_autoplace_base%(", "eb_enemy_autoplace_base(")
        expression = string.gsub(expression, "([^%w_])enemy_autoplace_base%(", "%1eb_enemy_autoplace_base(")

        return expression
    end

    ---@param prototype_type any
    ---@param prototype_name string
    ---@param expression_name string
    ---@return nil
    local function eon_mask_explosive_autoplace(prototype_type, prototype_name, expression_name)
        local prototype = data.raw[prototype_type] and data.raw[prototype_type][prototype_name]
        if prototype
            and prototype.autoplace
            and prototype.autoplace.probability_expression
        then
            local probability_expression = prototype.autoplace.probability_expression
            if type(probability_expression) ~= "string" then return end

            prototype.autoplace.control = "hot_enemy_base"

            data:extend({
                {
                    type = "noise-expression",
                    name = expression_name,
                    expression = eon_explosive_probability_expression(probability_expression)
                },
            })

            prototype.autoplace.probability_expression =
                "eon_mask_vulcano_terrain(" .. expression_name .. ")"
        end
    end

    if data.raw["planet"]
        and data.raw["planet"]["nauvis"]
        and data.raw["planet"]["nauvis"].map_gen_settings
        and data.raw["planet"]["nauvis"].map_gen_settings.autoplace_controls
    then
        data.raw["planet"]["nauvis"].map_gen_settings.autoplace_controls["hot_enemy_base"] = {}
    end

    eon_mask_explosive_autoplace("unit-spawner", "explosive-biter-spawner", "explosive_biter_spawner")
    eon_mask_explosive_autoplace("turret", "small-explosive-worm-turret", "small_explosive_worm_turret")
    eon_mask_explosive_autoplace("turret", "medium-explosive-worm-turret", "medium_explosive_worm_turret")
    eon_mask_explosive_autoplace("turret", "big-explosive-worm-turret", "big_explosive_worm_turret")
    eon_mask_explosive_autoplace("turret", "behemoth-explosive-worm-turret", "behemoth_explosive_worm_turret")
    eon_mask_explosive_autoplace("turret", "leviathan-explosive-worm-turret", "leviathan_explosive_worm_turret")
    eon_mask_explosive_autoplace("turret", "mother-explosive-worm-turret", "mother_explosive_worm_turret")
end

if mods["Cold_biters"] then
    local eon_aquilo_on_fulgora = settings.startup["eon-fd-aquilo-on-fulgora"]
        and settings.startup["eon-fd-aquilo-on-fulgora"].value == true

    ---@param prototype_type any
    ---@param prototype_name string
    ---@param expression_name string
    ---@return nil
    local function eon_mask_cold_autoplace(prototype_type, prototype_name, expression_name)
        local prototype = data.raw[prototype_type] and data.raw[prototype_type][prototype_name]
        if prototype
            and prototype.autoplace
            and prototype.autoplace.probability_expression
        then
            data:extend({
                {
                    type = "noise-expression",
                    name = expression_name,
                    expression = prototype.autoplace.probability_expression
                },
            })

            prototype.autoplace.probability_expression = "eon_mask_aquilo_territory(" .. expression_name .. ")"
        end
    end

    local eon_cold_planet_name = eon_aquilo_on_fulgora and "fulgora" or "nauvis"

    if eon_aquilo_on_fulgora then
        local nauvis = data.raw["planet"] and data.raw["planet"]["nauvis"]
        if nauvis
            and nauvis.map_gen_settings
            and nauvis.map_gen_settings.autoplace_controls
        then
            nauvis.map_gen_settings.autoplace_controls["frost_enemy_base"] = nil
        end
    end

    local eon_cold_planet = data.raw["planet"] and data.raw["planet"][eon_cold_planet_name]
    if eon_cold_planet
        and eon_cold_planet.map_gen_settings
        and eon_cold_planet.map_gen_settings.autoplace_controls
    then
        eon_cold_planet.map_gen_settings.autoplace_controls["frost_enemy_base"] = {}
    end

    eon_mask_cold_autoplace("unit-spawner", "cb-cold-spawner", "eon_cb_cold_spawner")
    eon_mask_cold_autoplace("turret", "small-cold-worm-turret", "eon_small_cold_worm_turret")
    eon_mask_cold_autoplace("turret", "medium-cold-worm-turret", "eon_medium_cold_worm_turret")
    eon_mask_cold_autoplace("turret", "big-cold-worm-turret", "eon_big_cold_worm_turret")
    eon_mask_cold_autoplace("turret", "behemoth-cold-worm-turret", "eon_behemoth_cold_worm_turret")
    eon_mask_cold_autoplace("turret", "leviathan-cold-worm-turret", "eon_leviathan_cold_worm_turret")
    eon_mask_cold_autoplace("turret", "mother-cold-worm-turret", "eon_mother_cold_worm_turret")
end

if mods["Electric_flying_enemies"] then
    local eon_aquilo_on_fulgora = settings.startup["eon-fd-aquilo-on-fulgora"]
        and settings.startup["eon-fd-aquilo-on-fulgora"].value == true

    ---@param prototype_type any
    ---@param prototype_name string
    ---@param expression_name string
    ---@return nil
    local function eon_mask_electric_off_aquilo(prototype_type, prototype_name, expression_name)
        local prototype = data.raw[prototype_type] and data.raw[prototype_type][prototype_name]
        if prototype
            and prototype.autoplace
            and prototype.autoplace.probability_expression
        then
            data:extend({
                {
                    type = "noise-expression",
                    name = expression_name,
                    expression = prototype.autoplace.probability_expression
                },
            })

            if eon_aquilo_on_fulgora then
                prototype.autoplace.probability_expression = "eon_mask_off_aquilo_territory(" .. expression_name .. ")"
            else
                prototype.autoplace.probability_expression = expression_name
            end
        end
    end

    eon_mask_electric_off_aquilo("unit-spawner", "flying-electric-unit-spawner",
        "eon_flying_electric_unit_spawner_off_aquilo")
    eon_mask_electric_off_aquilo("unit-spawner", "walker-electric-unit-spawner",
        "eon_walker_electric_unit_spawner_off_aquilo")
end

local eon_nauvis_territory_settings = table.deepcopy(data.raw["planet"]["vulcanus"].map_gen_settings.territory_settings)
data.raw["planet"]["nauvis"].map_gen_settings.territory_settings = eon_nauvis_territory_settings

if eon_nauvis_territory_settings and eon_nauvis_territory_settings.territory_index_expression then
    data:extend({
        {
            type = "noise-expression",
            name = "eon_demolisher_territory_index_no_lava",
            expression = "if(max(eon_lava_mountains_range, eon_lava_hot_mountains_range) > 0, -1, (" ..
                eon_nauvis_territory_settings.territory_index_expression .. "))"
        }
    })

    eon_nauvis_territory_settings.territory_index_expression = "eon_demolisher_territory_index_no_lava"
end

data.raw["noise-expression"]["demolisher_starting_area"].expression = "if(eon_vulcano_coverage > 0.2, 0, 1)"

data.raw["noise-expression"]["demolisher_variation_expression"].expression =
"floor(clamp(distance / (50 * 32) - 0.25, 0, 4)) + (-99 * no_enemies_mode)"

data.raw["planet"]["nauvis"].map_gen_settings.autoplace_controls["gleba_enemy_base"] = {}

local gleba_enemy_frequency = "var('control:gleba_enemy_base:frequency')"
local gleba_enemy_size = "sqrt(var('control:gleba_enemy_base:size'))"

local enemy_cap = 0.004
local fertile_cap = 0.00015
local fertile_scale = 2000
local green_penalty = 12000

---@param a string|number
---@param b string|number
---@return string
local function min_expr(a, b)
    return "min(" .. a .. ", " .. b .. ")"
end

---@vararg string|number
---@return string
local function max_expr(...)
    return "max(" .. table.concat({ ... }, ", ") .. ")"
end

---@param expr string
---@return string
local function gleba_enemy_mask(expr)
    return gleba_enemy_frequency ..
        " * eon_mask_gleba_territory((" ..
        expr ..
        ") * " .. gleba_enemy_size ..
        " * gleba_above_deep_water_mask)"
end

local enemy_autoplace = min_expr(enemy_cap, "enemy_autoplace_base(0, 8)")

local fertile_coastal_enemy_autoplace =
    min_expr(
        fertile_cap,
        "gleba_fertile_spots_coastal * " .. fertile_scale ..
        " - gleba_biome_mask_green * " .. green_penalty
    )

local gleba_enemy_density =
    max_expr(
        "0.001 * gleba_starting_enemies",
        enemy_autoplace,
        fertile_coastal_enemy_autoplace
    )

data.raw["noise-expression"]["gleba_spawner"].expression =
    gleba_enemy_mask(gleba_enemy_density)

data.raw["noise-expression"]["gleba_spawner_small"].expression =
    gleba_enemy_mask(gleba_enemy_density)
