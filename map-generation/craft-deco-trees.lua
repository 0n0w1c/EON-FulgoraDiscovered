local data_util = require("data-util")

local eon_aquilo_on_fulgora = settings.startup["eon-fd-aquilo-on-fulgora"]
    and settings.startup["eon-fd-aquilo-on-fulgora"].value == true

local eon_vulcanus_off_aquilo_mask = eon_aquilo_on_fulgora
    and "eon_identity"
    or "eon_mask_off_aquilo_territory"

---@type table<string, boolean>
local CRAFT_DECO_TREE_SUBGROUPS = {
    ["craftable-simple-trees"] = true,
    ["craftable-alive-trees"] = true,
    ["craftable-trees"] = true,
    ["craftable-alien-biomes-trees"] = true,
}

---@type table<string, boolean>
local NON_NAUVIS_PLANETS = {
    fulgora = true,
    gleba = true,
    vulcanus = true,
    aquilo = true,
}

---@type table<string, boolean>
local PALM_TREES = {
    ["tree-palm-a"] = true,
    ["tree-palm-b"] = true,
}

---@type table<string, boolean>
local VOLCANIC_TREES = {
    ["tree-volcanic-a"] = true,
}


if not (data.raw["noise-expression"] and data.raw["noise-expression"]["eon_vulcanus_ashland_tree_density"]) then
    data:extend({
        {
            type = "noise-expression",
            name = "eon_vulcanus_ashland_tree_density",
            expression = "max(tree_06, tree_08_red, tree_09_red)",
        },
    })
end

---@type table<string, boolean>
local SNOW_TREES = {
    ["tree-snow-a"] = true,
}

---@type string[]
local SNOW_TILE_RESTRICTIONS = {
    "snow-flat",
    "snow-crests",
    "snow-lumpy",
    "snow-patchy",
}

---@type string[]
local PALM_TILE_RESTRICTIONS = {
    "sand-1",
    "sand-2",
    "sand-3",
    "red-desert-0",
    "red-desert-1",
    "red-desert-2",
    "red-desert-3",
}

---@type table<string, string[]>
local ALIEN_BIOMES_TREE_EXPRESSIONS_BY_FAMILY = {
    wetland = { "tree_01", "tree_04", "tree_05", "tree_07" },
    grassland = { "tree_02", "tree_03", "tree_04", "tree_05", "tree_07" },
    dryland = { "tree_06", "tree_06_brown", "tree_08", "tree_08_brown", "tree_09", "tree_09_brown" },
    desert = { "tree_06", "tree_06_brown", "tree_08_red", "tree_09_red" },
    snow = { "tree_02" },
    volcanic = { "tree_06", "tree_08_red", "tree_09_red" },
    palm = { "tree_04", "tree_05" },
}

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
    local expression_name = scatter_expression_name(name)
    local noise_expressions = data.raw["noise-expression"]
    if not noise_expressions or noise_expressions[expression_name] then return end

    data:extend({
        {
            type = "noise-expression",
            name = expression_name,
            expression = "multioctave_noise{x = x, y = y, persistence = 0.55, seed0 = map_seed, seed1 = '" ..
                name .. "', octaves = 2, input_scale = 1/18 * control:trees:frequency, output_scale = 0.7} - 0.58",
        },
    })
end

---@return nil
local function register_palm_expression()
    local expression_name = palm_expression_name()
    local noise_expressions = data.raw["noise-expression"]
    if not noise_expressions or noise_expressions[expression_name] then return end

    data:extend({
        {
            type = "noise-expression",
            name = expression_name,
            expression =
            "clamp((2.5 - elevation) / 2.5, 0, 1) * max(0, multioctave_noise{x = x, y = y, persistence = 0.58, seed0 = map_seed, seed1 = 8675309, octaves = 2, input_scale = 1/96 * control:trees:frequency, output_scale = 1} - 0.48) * 0.014",
        },
    })
end

---@param name string
---@param tree table
local function apply_palm_autoplace(name, tree)
    register_palm_expression()

    tree.autoplace = {
        control = "trees",
        order = "z[tree]-c[craft-deco-2]-palm-" .. name,
        probability_expression = "eon_mask_nauvis_territory(" .. palm_expression_name() .. ")",
        richness_expression = "clamp(random_penalty_at(24, 1), 0, 1)",
        tile_restriction = PALM_TILE_RESTRICTIONS,
    }
end

---@param name string
---@param tree table
local function apply_standard_tree_autoplace(name, tree)
    local expression = source_expression_for_tree(name)
    if not expression then return end

    register_scatter_expression(name)

    tree.autoplace = {
        control = "trees",
        order = "z[tree]-c[craft-deco-2]-" .. name,
        probability_expression = "eon_mask_nauvis_territory(min(" ..
        expression .. ", " .. scatter_expression_name(name) .. "))",
        richness_expression = "clamp(random_penalty_at(6, 1), 0, 1)",
    }
end

---@param name string
---@param tree table
local function apply_volcanic_autoplace(name, tree)
    tree.autoplace = {
        control = "trees",
        order = "z[tree]-c[craft-deco-2]-volcanic-" .. name,
        probability_expression = eon_vulcanus_off_aquilo_mask ..
        "(eon_mask_vulcano_terrain(eon_vulcanus_tree_on_nauvis))",
        richness_expression = "clamp(random_penalty_at(18, 1), 0, 1)",
        tile_restriction = {
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
    }
end

---@return string
local function snow_expression_name()
    return data_util.generate_eon_name("craft-deco-tree-snow-aquilo-land")
end

---@return nil
local function register_snow_expression()
    local expression_name = snow_expression_name()
    local noise_expressions = data.raw["noise-expression"]
    if not noise_expressions or noise_expressions[expression_name] then return end

    data:extend({
        {
            type = "noise-expression",
            name = expression_name,
            expression =
            "max(0, eon_aquilo_land) * max(0, multioctave_noise{x = x, y = y, persistence = 0.55, seed0 = map_seed, seed1 = 26012026, octaves = 2, input_scale = 1/64 * control:trees:frequency, output_scale = 1} - 0.45) * 0.01125",
        },
    })
end

---@param name string
---@param tree table
local function apply_snow_autoplace(name, tree)
    register_snow_expression()

    tree.autoplace = {
        control = "trees",
        order = "z[tree]-c[craft-deco-2]-snow-" .. name,
        probability_expression = "eon_mask_aquilo_territory(" .. snow_expression_name() .. ")",
        richness_expression = "clamp(random_penalty_at(14, 1), 0, 1)",
        tile_restriction = SNOW_TILE_RESTRICTIONS,
    }
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

    map_gen_settings.autoplace_controls = map_gen_settings.autoplace_controls or {}
    map_gen_settings.autoplace_controls.trees = map_gen_settings.autoplace_controls.trees or {}

    map_gen_settings.autoplace_settings = map_gen_settings.autoplace_settings or {}
    map_gen_settings.autoplace_settings.entity = map_gen_settings.autoplace_settings.entity or { settings = {} }
    map_gen_settings.autoplace_settings.entity.settings = map_gen_settings.autoplace_settings.entity.settings or {}

    return map_gen_settings.autoplace_settings.entity.settings
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
    local planet = data.raw.planet and data.raw.planet["fulgora"]
    local settings = planet
        and planet.map_gen_settings
        and planet.map_gen_settings.autoplace_settings
        and planet.map_gen_settings.autoplace_settings.entity
        and planet.map_gen_settings.autoplace_settings.entity.settings

    if not settings then return end

    for _, tree_name in ipairs(tree_names) do
        settings[tree_name] = nil
    end
end

---@type string[]
local tree_names = collect_tree_names()

for _, tree_name in ipairs(tree_names) do
    apply_nauvis_tree_autoplace(tree_name, data.raw.tree[tree_name])
end

register_nauvis_tree_settings(tree_names)
remove_fulgora_tree_settings(tree_names)
