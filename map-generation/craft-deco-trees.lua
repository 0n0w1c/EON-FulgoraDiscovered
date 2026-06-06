local data_util = require("data-util")
local eon_mode = require("lib.eon-mode")
local eon_craft_deco_registry = require("lib.eon-craft-deco-registry")
local eon_autoplace_policy = require("lib.eon-autoplace-policy")

local eon_aquilo_on_fulgora = eon_mode.aquilo_on_fulgora

local eon_vulcanus_off_aquilo_mask = eon_aquilo_on_fulgora
    and "eon_identity"
    or "eon_mask_off_aquilo_territory"

local CRAFT_DECO_TREE_SUBGROUPS = eon_craft_deco_registry.trees.subgroups
local NON_NAUVIS_PLANETS = eon_craft_deco_registry.non_nauvis_planets
local PALM_TREES = eon_craft_deco_registry.trees.palm.names
local VOLCANIC_TREES = eon_craft_deco_registry.trees.volcanic.names
local SNOW_TREES = eon_craft_deco_registry.trees.snow.names
local SNOW_TILE_RESTRICTIONS = eon_craft_deco_registry.trees.snow.tile_restrictions
local PALM_TILE_RESTRICTIONS = eon_craft_deco_registry.trees.palm.tile_restrictions
local VOLCANIC_TILE_RESTRICTIONS = eon_craft_deco_registry.trees.volcanic.tile_restrictions
local ALIEN_BIOMES_TREE_EXPRESSIONS_BY_FAMILY = eon_craft_deco_registry.trees.alien_biomes_expression_families

local volcanic_density_expression = eon_craft_deco_registry.trees.volcanic.density_expression
eon_autoplace_policy.ensure_noise_expression(
    volcanic_density_expression.name,
    volcanic_density_expression.expression
)

---@param prototype table
---@return boolean
local function is_non_nauvis_prototype(prototype)
    local simulation = prototype.factoriopedia_simulation
    return simulation ~= nil
        and simulation.planet ~= nil
        and NON_NAUVIS_PLANETS[simulation.planet] == true
end

---@param name string
---@return string|nil
local function get_alien_biomes_family(name)
    return string.match(name, "^tree%-([%a]+)%-")
end

---@param expression_name string|nil
---@return boolean
local function noise_expression_exists(expression_name)
    return expression_name ~= nil
        and data.raw["noise-expression"] ~= nil
        and data.raw["noise-expression"][expression_name] ~= nil
end

---@param name string
---@param expressions string[]
---@return string
local function pick_deterministic_expression(name, expressions)
    if #expressions == 1 then return expressions[1] end

    local total = 0
    for index = 1, #name do
        total = total + string.byte(name, index)
    end

    return expressions[(total % #expressions) + 1]
end

---@param name string
---@return string|nil
local function source_expression_for_tree(name)
    local family = get_alien_biomes_family(name)
    local expressions = family and ALIEN_BIOMES_TREE_EXPRESSIONS_BY_FAMILY[family]
    if not expressions then return nil end

    local available = {}
    for _, candidate in ipairs(expressions) do
        if noise_expression_exists(candidate) then
            table.insert(available, candidate)
        end
    end

    if #available == 0 then return nil end
    return pick_deterministic_expression(name, available)
end

---@param subgroup_name string|nil
---@return boolean
local function is_environment_subgroup(subgroup_name)
    if not subgroup_name then return false end

    local subgroup = data.raw["item-subgroup"] and data.raw["item-subgroup"][subgroup_name]
    return subgroup ~= nil and subgroup.group == "environment"
end

---@param name string
---@return boolean
local function is_craft_deco_tree_item(name)
    if not mods["craft-deco-2"] then return false end

    local item = data.raw.item and data.raw.item[name]
    return item ~= nil
        and is_environment_subgroup(item.subgroup)
        and CRAFT_DECO_TREE_SUBGROUPS[item.subgroup] == true
        and item.place_result == name
end

---@param tree table
---@return boolean
local function is_live_tree(tree)
    return tree.variations ~= nil and tree.pictures == nil
end

---@param result string[]
---@param seen table<string, boolean>
---@param name string
local function add_tree_name(result, seen, name)
    if seen[name] then return end

    local tree = data.raw.tree and data.raw.tree[name]
    if not tree then return end
    if is_non_nauvis_prototype(tree) then return end
    if not is_live_tree(tree) then return end
    if not is_craft_deco_tree_item(name) then return end
    if not source_expression_for_tree(name) then return end

    seen[name] = true
    table.insert(result, name)
end

---@return string[]
local function collect_tree_names()
    local result = {}
    local seen = {}

    if mods["craft-deco-2"] then
        for item_name, _ in pairs(data.raw.item or {}) do
            add_tree_name(result, seen, item_name)
        end
    end

    table.sort(result)
    return result
end

---@param name string
---@return string
local function scatter_expression_name(name)
    return data_util.generate_eon_name("craft-deco-tree-scatter-" .. name)
end

---@return string
local function palm_expression_name()
    return data_util.generate_eon_name("craft-deco-tree-palm-low-elevation")
end

---@param name string
local function register_scatter_expression(name)
    eon_autoplace_policy.ensure_noise_expression(
        scatter_expression_name(name),
        "multioctave_noise{x = x, y = y, persistence = 0.55, seed0 = map_seed, seed1 = '" ..
        name .. "', octaves = 2, input_scale = 1/18 * control:trees:frequency, output_scale = 0.7} - 0.58"
    )
end

---@return nil
local function register_palm_expression()
    eon_autoplace_policy.ensure_noise_expression(
        palm_expression_name(),
        "clamp((2.5 - elevation) / 2.5, 0, 1) * max(0, multioctave_noise{x = x, y = y, persistence = 0.58, seed0 = map_seed, seed1 = 8675309, octaves = 2, input_scale = 1/96 * control:trees:frequency, output_scale = 1} - 0.48) * 0.014"
    )
end

---@param name string
---@param tree table
local function apply_palm_autoplace(name, tree)
    register_palm_expression()

    tree.autoplace = eon_autoplace_policy.autoplace_config({
        control = "trees",
        order = "z[tree]-c[craft-deco-2]-palm-" .. name,
        probability_expression = "eon_mask_nauvis_territory(" .. palm_expression_name() .. ")",
        richness_expression = "clamp(random_penalty_at(24, 1), 0, 1)",
    }, PALM_TILE_RESTRICTIONS)
end

---@param name string
---@param tree table
local function apply_standard_tree_autoplace(name, tree)
    local expression = source_expression_for_tree(name)
    if not expression then return end

    register_scatter_expression(name)

    tree.autoplace = eon_autoplace_policy.autoplace_config({
        control = "trees",
        order = "z[tree]-c[craft-deco-2]-" .. name,
        probability_expression = "eon_mask_nauvis_territory(min(" ..
            expression .. ", " .. scatter_expression_name(name) .. "))",
        richness_expression = "clamp(random_penalty_at(6, 1), 0, 1)",
    })
end

---@param name string
---@param tree table
local function apply_volcanic_autoplace(name, tree)
    tree.autoplace = eon_autoplace_policy.autoplace_config({
        control = "trees",
        order = "z[tree]-c[craft-deco-2]-volcanic-" .. name,
        probability_expression = eon_vulcanus_off_aquilo_mask ..
            "(eon_mask_vulcano_terrain(eon_vulcanus_tree_on_nauvis))",
        richness_expression = "clamp(random_penalty_at(18, 1), 0, 1)",
    }, VOLCANIC_TILE_RESTRICTIONS)
end

---@return string
local function snow_expression_name()
    return data_util.generate_eon_name("craft-deco-tree-snow-aquilo-land")
end

---@return nil
local function register_snow_expression()
    eon_autoplace_policy.ensure_noise_expression(
        snow_expression_name(),
        "max(0, eon_aquilo_land) * max(0, multioctave_noise{x = x, y = y, persistence = 0.55, seed0 = map_seed, seed1 = 26012026, octaves = 2, input_scale = 1/64 * control:trees:frequency, output_scale = 1} - 0.45) * 0.01125"
    )
end

---@param name string
---@param tree table
local function apply_snow_autoplace(name, tree)
    register_snow_expression()

    tree.autoplace = eon_autoplace_policy.autoplace_config({
        control = "trees",
        order = "z[tree]-c[craft-deco-2]-snow-" .. name,
        probability_expression = "eon_mask_aquilo_territory(" .. snow_expression_name() .. ")",
        richness_expression = "clamp(random_penalty_at(14, 1), 0, 1)",
    }, SNOW_TILE_RESTRICTIONS)
end

---@param name string
---@param tree table
local function apply_nauvis_tree_autoplace(name, tree)
    if PALM_TREES[name] then
        apply_palm_autoplace(name, tree)
    elseif VOLCANIC_TREES[name] then
        apply_volcanic_autoplace(name, tree)
    elseif SNOW_TREES[name] then
        apply_snow_autoplace(name, tree)
    else
        apply_standard_tree_autoplace(name, tree)
    end
end

---@param planet_name string
---@return table|nil
local function planet_entity_autoplace_settings(planet_name)
    if planet_name == "fulgora" then return nil end

    local planet = data.raw.planet and data.raw.planet[planet_name]
    local map_gen_settings = planet and planet.map_gen_settings
    if not map_gen_settings then return nil end

    eon_autoplace_policy.set_map_gen_autoplace_control(map_gen_settings, "trees")

    return eon_autoplace_policy.map_gen_autoplace_category_settings(map_gen_settings, "entity")
end

---@param tree_names string[]
local function register_nauvis_tree_settings(tree_names)
    local settings = planet_entity_autoplace_settings("nauvis")
    if not settings then return end

    for _, tree_name in ipairs(tree_names) do
        settings[tree_name] = settings[tree_name] or {}
    end
end

---@param tree_names string[]
local function remove_fulgora_tree_settings(tree_names)
    eon_autoplace_policy.remove_planet_autoplace_settings("fulgora", "entity", tree_names)
end

---@type string[]
local tree_names = collect_tree_names()

for _, tree_name in ipairs(tree_names) do
    apply_nauvis_tree_autoplace(tree_name, data.raw.tree[tree_name])
end

register_nauvis_tree_settings(tree_names)
remove_fulgora_tree_settings(tree_names)
