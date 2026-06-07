local terrain = require("map-generation.terrain")
local enemy_registry = require("lib.eon-enemy-registry")
local biomes = require("lib.eon-biome-registry")
local eon_mode = require("lib.eon-mode")
local eon_autoplace_policy = require("lib.eon-autoplace-policy")

local eon_aquilo_on_fulgora = eon_mode.aquilo_on_fulgora
local aquilo_masks = biomes.get("aquilo").masks
local gleba_masks = biomes.get("gleba").masks
local nauvis_masks = biomes.get("nauvis").masks
local vulcanus_masks = biomes.get("vulcanus").masks

---@param prototype_type string
---@param prototype_name string
---@return table|nil
local function eon_autoplace_prototype(prototype_type, prototype_name)
    local prototype = data.raw[prototype_type] and data.raw[prototype_type][prototype_name]
    if not (prototype and prototype.autoplace and prototype.autoplace.probability_expression) then return nil end
    if type(prototype.autoplace.probability_expression) ~= "string" then return nil end
    return prototype
end

---@param entry table
---@return table|nil
local function eon_capture_enemy_autoplace(entry)
    local prototype = eon_autoplace_prototype(entry.type, entry.name)
    if not prototype then return nil end

    data:extend({
        {
            type = "noise-expression",
            name = entry.expression,
            expression = prototype.autoplace.probability_expression
        },
    })

    return prototype
end

---@param entries table[]
---@param mask_name string
local function eon_apply_masked_enemy_group(entries, mask_name)
    for _, entry in ipairs(entries) do
        local prototype = eon_capture_enemy_autoplace(entry)
        if prototype then
            prototype.autoplace.probability_expression = mask_name .. "(" .. entry.expression .. ")"
        end
    end
end

eon_apply_masked_enemy_group(enemy_registry.data_stage.vanilla_nauvis, nauvis_masks.territory)

if mods[enemy_registry.data_stage.armoured_nauvis.mod] then
    eon_apply_masked_enemy_group(enemy_registry.data_stage.armoured_nauvis.entries, nauvis_masks.territory)
end

if mods[enemy_registry.data_stage.explosive_vulcanus.mod] then
    ---@param expression string
    ---@return string
    local function eon_explosive_probability_expression(expression)
        expression = string.gsub(expression, "^enemy_autoplace_base%(", "eb_enemy_autoplace_base(")
        expression = string.gsub(expression, "([^%w_])enemy_autoplace_base%(", "%1eb_enemy_autoplace_base(")

        return expression
    end

    eon_autoplace_policy.set_planet_autoplace_control("nauvis",
        enemy_registry.data_stage.explosive_vulcanus.autoplace_control)

    for _, entry in ipairs(enemy_registry.data_stage.explosive_vulcanus.entries) do
        local prototype = eon_autoplace_prototype(entry.type, entry.name)
        if prototype then
            prototype.autoplace.control = enemy_registry.data_stage.explosive_vulcanus.autoplace_control

            data:extend({
                {
                    type = "noise-expression",
                    name = entry.expression,
                    expression = eon_explosive_probability_expression(prototype.autoplace.probability_expression)
                },
            })

            if eon_aquilo_on_fulgora then
                prototype.autoplace.probability_expression = vulcanus_masks.terrain .. "(" .. entry.expression .. ")"
            else
                prototype.autoplace.probability_expression =
                    aquilo_masks.off_territory .. "(" .. vulcanus_masks.terrain .. "(" .. entry.expression .. "))"
            end
        end
    end
end

if mods[enemy_registry.data_stage.cold_aquilo.mod] then
    local eon_cold_planet_name = eon_aquilo_on_fulgora and "fulgora" or "nauvis"

    if eon_aquilo_on_fulgora then
        eon_autoplace_policy.set_planet_autoplace_control("nauvis",
            enemy_registry.data_stage.cold_aquilo.autoplace_control, false)
    end

    eon_autoplace_policy.set_planet_autoplace_control(eon_cold_planet_name,
        enemy_registry.data_stage.cold_aquilo.autoplace_control)

    eon_apply_masked_enemy_group(enemy_registry.data_stage.cold_aquilo.entries, aquilo_masks.territory)
end

if mods[enemy_registry.data_stage.electric_fulgora.mod] then
    for _, entry in ipairs(enemy_registry.data_stage.electric_fulgora.entries) do
        local prototype = eon_capture_enemy_autoplace(entry)
        if prototype then
            if eon_aquilo_on_fulgora then
                prototype.autoplace.probability_expression = aquilo_masks.off_territory .. "(" .. entry.expression .. ")"
            else
                prototype.autoplace.probability_expression = entry.expression
            end
        end
    end
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

eon_autoplace_policy.set_planet_autoplace_control("nauvis", "gleba_enemy_base")

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
        " * " .. gleba_masks.territory .. "((" ..
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
