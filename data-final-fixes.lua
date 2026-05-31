require("prototypes.remove-planets")
require("prototypes.surface-conditions")
require("prototypes.planet-sounds")

require("prototypes.patches")

---@param planet_name string
---@return any
local function eon_planet_has_unit_spawner_autoplace(planet_name)
    local planet = data.raw.planet and data.raw.planet[planet_name]
    local entity_settings = planet
        and planet.map_gen_settings
        and planet.map_gen_settings.autoplace_settings
        and planet.map_gen_settings.autoplace_settings.entity
        and planet.map_gen_settings.autoplace_settings.entity.settings

    if not entity_settings then return false end

    for entity_name, _ in pairs(entity_settings) do
        local spawner = data.raw["unit-spawner"] and data.raw["unit-spawner"][entity_name]
        if spawner and spawner.autoplace then
            return true
        end
    end

    return false
end

local fulgora = data.raw.planet and data.raw.planet["fulgora"]
if fulgora then
    fulgora.pollutant_type = eon_planet_has_unit_spawner_autoplace("fulgora") and "pollution" or nil
end

---@return nil
local function eon_remove_all_tree_autoplace_from_fulgora()
    local planet = data.raw.planet and data.raw.planet["fulgora"]
    local settings = planet
        and planet.map_gen_settings
        and planet.map_gen_settings.autoplace_settings
        and planet.map_gen_settings.autoplace_settings.entity
        and planet.map_gen_settings.autoplace_settings.entity.settings

    if not settings then return end

    for tree_name, _ in pairs(data.raw.tree or {}) do
        settings[tree_name] = nil
    end
end

eon_remove_all_tree_autoplace_from_fulgora()

---@param recipe_name string
---@return any
local function eon_is_craft_deco_recipe_name(recipe_name)
    return type(recipe_name) == "string" and string.sub(recipe_name, 1, 15) == "craftdeco-base-"
end

---@param technology table
---@return any
local function eon_technology_unlocks_craft_deco_recipe(technology)
    if type(technology.effects) ~= "table" then return false end

    for _, effect in pairs(technology.effects) do
        if effect.type == "unlock-recipe" and eon_is_craft_deco_recipe_name(effect.recipe) then
            return true
        end
    end

    return false
end

---@return nil
local function eon_hide_craft_deco_2_recipes()
    local setting = settings.startup["eon-fd-hide-craft-deco-2-technology"]
    if not (mods["craft-deco-2"] and setting and setting.value) then return end

    for technology_name, technology in pairs(data.raw.technology or {}) do
        if string.match(technology_name, "^craft%-deco.*%-landscaping$")
            or eon_technology_unlocks_craft_deco_recipe(technology)
        then
            technology.hidden = true
            technology.enabled = false
            technology.effects = nil
        end
    end

    for recipe_name, recipe in pairs(data.raw.recipe or {}) do
        if eon_is_craft_deco_recipe_name(recipe_name) then
            recipe.hidden = true
            recipe.enabled = false
        end
    end

    for item_name, item in pairs(data.raw.item or {}) do
        if eon_is_craft_deco_recipe_name(item_name) then
            item.hidden = true
            item.hidden_in_factoriopedia = true
        end
    end
end

eon_hide_craft_deco_2_recipes()

---@param resistance_owner table|nil
---@return boolean
local function eon_set_full_electric_resistance(resistance_owner)
    if not resistance_owner then return false end

    resistance_owner.resistances = resistance_owner.resistances or {}

    for _, resistance in pairs(resistance_owner.resistances) do
        if resistance.type == "electric" then
            resistance.percent = 100
            return true
        end
    end

    table.insert(resistance_owner.resistances, { type = "electric", percent = 100 })
    return true
end

---@param prototype_type string
---@param prototype_name string
---@return boolean
local function eon_is_cold_biter_enemy_prototype(prototype_type, prototype_name)
    if type(prototype_name) ~= "string" then return false end

    if prototype_type == "unit-spawner" then
        return prototype_name == "cb-cold-spawner"
            or string.find(prototype_name, "cold%-spawner", 1, false) ~= nil
            or string.find(prototype_name, "frost%-spawner", 1, false) ~= nil
    end

    if prototype_type == "turret" then
        return string.find(prototype_name, "cold%-worm%-turret", 1, false) ~= nil
            or string.find(prototype_name, "frost%-worm%-turret", 1, false) ~= nil
    end

    if prototype_type == "unit" then
        return string.find(prototype_name, "cold%-biter", 1, false) ~= nil
            or string.find(prototype_name, "cold%-spitter", 1, false) ~= nil
            or string.find(prototype_name, "frost%-biter", 1, false) ~= nil
            or string.find(prototype_name, "frost%-spitter", 1, false) ~= nil
    end

    return false
end

---@return nil
local function eon_make_cold_biters_electric_immune_on_fulgora_aquilo()
    local aquilo_on_fulgora = settings.startup["eon-fd-aquilo-on-fulgora"]
        and settings.startup["eon-fd-aquilo-on-fulgora"].value == true

    if not aquilo_on_fulgora then return end
    if not (mods["Cold_biters"] or mods["Frost_biters"]) then return end

    local patched = 0
    for _, prototype_type in pairs({ "unit-spawner", "turret", "unit" }) do
        for prototype_name, prototype in pairs(data.raw[prototype_type] or {}) do
            if eon_is_cold_biter_enemy_prototype(prototype_type, prototype_name)
                and eon_set_full_electric_resistance(prototype)
            then
                patched = patched + 1
            end
        end
    end

    log("[EON] Cold/Frost Biters electric immunity on Fulgora Aquilo patched prototypes=" .. patched)
end

eon_make_cold_biters_electric_immune_on_fulgora_aquilo()

local eon_repair_rerouted_planet_discovery_technologies

---@return nil
local function eon_remove_hidden_planet_space_connections()
    local connections = data.raw["space-connection"]
    if not connections then return end

    local removed_planets = {
        vulcanus = true,
        aquilo = true,
        gleba = true,
    }

    local function is_removed_planet(name)
        return type(name) == "string" and removed_planets[name]
    end

    local function is_existing_planet(name)
        return type(name) == "string" and data.raw.planet and data.raw.planet[name] ~= nil
    end

    local function connection_touches_planet(connection, planet_name)
        return connection and (connection.from == planet_name or connection.to == planet_name)
    end

    local function connection_touches_removed_planet(connection)
        return connection and (is_removed_planet(connection.from) or is_removed_planet(connection.to))
    end

    local function other_endpoint_from_removed_connection(connection)
        if is_removed_planet(connection.from) then
            return connection.to
        end

        if is_removed_planet(connection.to) then
            return connection.from
        end

        return nil
    end

    local function has_valid_remaining_connection(planet_name)
        for _, connection in pairs(connections) do
            if connection_touches_planet(connection, planet_name)
                and not is_removed_planet(connection.from)
                and not is_removed_planet(connection.to)
            then
                return true
            end
        end

        return false
    end

    local function has_connection_between(from_name, to_name)
        for _, connection in pairs(connections) do
            if (connection.from == from_name and connection.to == to_name)
                or (connection.from == to_name and connection.to == from_name)
            then
                return true
            end
        end

        return false
    end

    local function planet_icon_data(planet_name, shift)
        local planet = data.raw.planet and data.raw.planet[planet_name]
        if not planet then return nil end

        if planet.icon then
            return {
                icon = planet.icon,
                icon_size = planet.icon_size or 64,
                scale = 0.333,
                shift = shift,
            }
        end

        if type(planet.icons) == "table" and planet.icons[1] then
            local icon = table.deepcopy(planet.icons[1])
            icon.scale = 0.333
            icon.shift = shift
            return icon
        end

        return nil
    end

    local function connection_icons(to_planet_name)
        local icons = {
            {
                icon = "__space-age__/graphics/icons/planet-route.png",
            },
        }

        local fulgora_icon = planet_icon_data("fulgora", { -6, -6 })
        local to_icon = planet_icon_data(to_planet_name, { 6, 6 })

        if fulgora_icon then
            table.insert(icons, fulgora_icon)
        end

        if to_icon then
            table.insert(icons, to_icon)
        end

        return icons
    end

    local function connection_name(to_planet_name)
        local base_name = "fulgora-" .. to_planet_name
        if not connections[base_name] then
            return base_name
        end

        local index = 2
        while connections[base_name .. "-" .. index] do
            index = index + 1
        end

        return base_name .. "-" .. index
    end

    local stranded_planets = {}
    local rerouted_planets = {}

    for connection_name_to_remove, connection in pairs(table.deepcopy(connections)) do
        if connection_touches_removed_planet(connection) then
            local other_endpoint = other_endpoint_from_removed_connection(connection)

            if other_endpoint ~= "fulgora"
                and not is_removed_planet(other_endpoint)
                and is_existing_planet(other_endpoint)
            then
                stranded_planets[other_endpoint] = stranded_planets[other_endpoint] or table.deepcopy(connection)
            end

            connections[connection_name_to_remove] = nil
        end
    end

    for planet_name, template in pairs(stranded_planets) do
        if not has_valid_remaining_connection(planet_name) then
            rerouted_planets[planet_name] = true

            if not has_connection_between("fulgora", planet_name) then
                local new_connection = table.deepcopy(template)
                new_connection.name = connection_name(planet_name)
                new_connection.from = "fulgora"
                new_connection.to = planet_name
                new_connection.icons = connection_icons(planet_name)
                new_connection.localised_name = nil
                new_connection.localised_description = nil

                data:extend({ new_connection })
            end
        end
    end

    eon_repair_rerouted_planet_discovery_technologies(rerouted_planets)
end

---@param rerouted_planets table<string, boolean>
---@return nil
eon_repair_rerouted_planet_discovery_technologies = function(rerouted_planets)
    if type(rerouted_planets) ~= "table" then return end

    local technologies = data.raw.technology
    if not technologies then return end

    local removed_discovery_prerequisites = {
        ["planet-discovery-aquilo"] = true,
        ["planet-discovery-gleba"] = true,
        ["planet-discovery-vulcanus"] = true,
    }

    ---@type string?
    local replacement_prerequisite = "planet-discovery-fulgora"
    if not technologies[replacement_prerequisite] then
        replacement_prerequisite = nil
    end

    ---@param technology table
    ---@param location_name string
    ---@return boolean
    local function unlocks_space_location(technology, location_name)
        if type(technology.effects) ~= "table" then return false end

        for _, effect in pairs(technology.effects) do
            if effect.type == "unlock-space-location" and effect.space_location == location_name then
                return true
            end
        end

        return false
    end

    ---@param prerequisites table|nil
    ---@return boolean
    local function has_prerequisite(prerequisites, prerequisite_name)
        if type(prerequisites) ~= "table" then return false end

        for _, prerequisite in pairs(prerequisites) do
            if prerequisite == prerequisite_name then
                return true
            end
        end

        return false
    end

    ---@param technology table
    ---@return nil
    local function replace_removed_discovery_prerequisites(technology)
        if type(technology.prerequisites) ~= "table" then return end

        local new_prerequisites = {}
        local removed_any = false

        for _, prerequisite in ipairs(technology.prerequisites) do
            if removed_discovery_prerequisites[prerequisite] then
                removed_any = true
            else
                table.insert(new_prerequisites, prerequisite)
            end
        end

        if not removed_any then return end

        if replacement_prerequisite
            and technology.name ~= replacement_prerequisite
            and not has_prerequisite(new_prerequisites, replacement_prerequisite)
        then
            table.insert(new_prerequisites, replacement_prerequisite)
        end

        technology.prerequisites = new_prerequisites
    end

    for planet_name, should_repair in pairs(rerouted_planets) do
        if should_repair then
            for _, technology in pairs(technologies) do
                if unlocks_space_location(technology, planet_name) then
                    replace_removed_discovery_prerequisites(technology)
                end
            end
        end
    end
end

eon_remove_hidden_planet_space_connections()

---Normalizes Commander enemy candidates on Nauvis.
---Collision masks are shared; tile restrictions define wetland or land placement.
---@class EonCollisionMask
---@field layers table<string, boolean>
---@type EonCollisionMask
local eon_commander_enemy_collision_mask = {
    layers = {
        item = true,
        meltable = true,
        object = true,
        player = true,
        is_object = true,
        is_lower_object = true,
    }
}

---@type string[] Tile names where Gleba pentapod spawners may be autoplaced.
local eon_gleba_wetland_spawner_tiles = {
    "wetland-yumako",
    "wetland-jellynut",
    "wetland-blue-slime",
    "wetland-light-green-slime",
    "wetland-green-slime",
    "wetland-light-dead-skin",
    "wetland-dead-skin",
    "wetland-pink-tentacle",
    "wetland-red-tentacle",
}

---Returns whether a collision mask contains a layer.
---@param mask table|nil Collision mask table from a prototype, if present.
---@param layer string Collision layer name to test.
---@return boolean has_layer True when the layer is present and enabled.
local function eon_collision_mask_has_layer(mask, layer)
    if type(mask) ~= "table" then return false end

    if type(mask.layers) == "table" then
        return mask.layers[layer] == true
    end

    for _, mask_layer in pairs(mask) do
        if mask_layer == layer then return true end
    end

    return false
end

---Adds a collision layer to a prototype collision mask, preserving the 2.0 layers format.
---@param proto table|nil Prototype with a collision_mask field.
---@param layer string Collision layer to add.
---@return boolean changed True when the layer was newly added.
local function eon_add_collision_mask_layer(proto, layer)
    if type(proto) ~= "table" or type(layer) ~= "string" then return false end

    proto.collision_mask = proto.collision_mask or { layers = {} }

    if type(proto.collision_mask.layers) ~= "table" then
        local converted = { layers = {} }
        for _, mask_layer in pairs(proto.collision_mask) do
            if type(mask_layer) == "string" then
                converted.layers[mask_layer] = true
            end
        end
        proto.collision_mask = converted
    end

    if proto.collision_mask.layers[layer] == true then return false end
    proto.collision_mask.layers[layer] = true
    return true
end

---Collects solid, non-water tile names.
---@return string[] tile_names Solid, non-water tile names.
local function eon_collect_solid_tile_names()
    local tiles = {}

    for tile_name, tile in pairs(data.raw["tile"] or {}) do
        local mask = tile.collision_mask
        if eon_collision_mask_has_layer(mask, "ground_tile")
            and not eon_collision_mask_has_layer(mask, "water_tile")
        then
            table.insert(tiles, tile_name)
        end
    end

    if #tiles > 0 then return tiles end

    return {
        "grass-1", "grass-2", "grass-3", "grass-4",
        "dry-dirt", "dirt-1", "dirt-2", "dirt-3", "dirt-4", "dirt-5", "dirt-6", "dirt-7",
        "sand-1", "sand-2", "sand-3",
        "red-desert-0", "red-desert-1", "red-desert-2", "red-desert-3",
    }
end

---@type string[]
local eon_land_spawner_tiles = eon_collect_solid_tile_names()

---Returns whether a prototype participates in enemy-base style autoplace.
---@param proto table|nil Candidate unit-spawner or turret prototype.
---@return boolean is_candidate True when the prototype has an autoplace control.
local function eon_is_autoplaced_enemy_candidate(proto)
    return proto ~= nil
        and proto.autoplace ~= nil
        and proto.autoplace.control ~= nil
end

---Normalizes an autoplaced enemy prototype for Commander expansion.
---@param proto table Unit-spawner or turret prototype to adjust in-place.
---@return nil
local function eon_normalize_autoplaced_enemy_candidate(proto)
    if not eon_is_autoplaced_enemy_candidate(proto) then return end

    proto.collision_mask = table.deepcopy(eon_commander_enemy_collision_mask)

    if proto.name == "gleba-spawner" or proto.name == "gleba-spawner-small" then
        proto.autoplace.tile_restriction = table.deepcopy(eon_gleba_wetland_spawner_tiles)
        return
    end

    proto.autoplace.tile_restriction = table.deepcopy(eon_land_spawner_tiles)
end

for _, prototype_type in pairs({ "unit-spawner", "turret" }) do
    for _, proto in pairs(data.raw[prototype_type] or {}) do
        eon_normalize_autoplaced_enemy_candidate(proto)
    end
end

local eon_fulgora_oil_ocean_tiles = {
    ["oil-ocean-shallow"] = true,
    ["oil-ocean-deep"] = true,
}

---Excludes Fulgora oil-ocean tiles from a base prototype's autoplace tile restriction.
---@param proto table|nil Candidate spawner or worm prototype.
---@return boolean changed True when the tile restriction was changed.
local function eon_exclude_fulgora_oil_ocean_from_autoplace(proto)
    if type(proto) ~= "table" or type(proto.autoplace) ~= "table" then return false end

    local changed = false
    local restriction = proto.autoplace.tile_restriction

    if type(restriction) ~= "table" then
        proto.autoplace.tile_restriction = table.deepcopy(eon_land_spawner_tiles)
        return true
    end

    local filtered = {}
    local removed = false
    for _, tile_name in pairs(restriction) do
        if eon_fulgora_oil_ocean_tiles[tile_name] then
            removed = true
        else
            table.insert(filtered, tile_name)
        end
    end

    if #filtered == 0 then
        filtered = table.deepcopy(eon_land_spawner_tiles)
        removed = true
    end

    if removed then
        proto.autoplace.tile_restriction = filtered
        changed = true
    end

    return changed
end


---@return nil
local function eon_make_deep_oil_ocean_collide_with_players()
    local tile = data.raw["tile"] and data.raw["tile"]["oil-ocean-deep"]
    if not tile then return end

    if eon_add_collision_mask_layer(tile, "player") then
        log("[EON] oil-ocean-deep collision mask patched with player layer")
    end
end

eon_make_deep_oil_ocean_collide_with_players()

---@return nil
local function eon_prevent_cold_biter_bases_on_fulgora_oil_ocean()
    local aquilo_on_fulgora = settings.startup["eon-fd-aquilo-on-fulgora"]
        and settings.startup["eon-fd-aquilo-on-fulgora"].value == true

    if not aquilo_on_fulgora then return end
    if not (mods["Cold_biters"] or mods["Frost_biters"]) then return end

    local collision_patched = 0
    local restriction_patched = 0
    for _, prototype_type in pairs({ "unit-spawner", "turret" }) do
        for prototype_name, prototype in pairs(data.raw[prototype_type] or {}) do
            if eon_is_cold_biter_enemy_prototype(prototype_type, prototype_name) then
                if eon_add_collision_mask_layer(prototype, "water_tile") then
                    collision_patched = collision_patched + 1
                end
                if eon_exclude_fulgora_oil_ocean_from_autoplace(prototype) then
                    restriction_patched = restriction_patched + 1
                end
            end
        end
    end

    log("[EON] Cold/Frost Biters Fulgora oil-ocean base prevention patched collision_prototypes="
        .. collision_patched .. " tile_restriction_prototypes=" .. restriction_patched)
end

eon_prevent_cold_biter_bases_on_fulgora_oil_ocean()

---@param prototype_type string
---@param prototype_name string
---@return boolean
local function eon_is_fulgoran_enemy_base_prototype(prototype_type, prototype_name)
    if type(prototype_name) ~= "string" then return false end
    if prototype_type ~= "unit-spawner" and prototype_type ~= "turret" then return false end

    return prototype_name == "flying-electric-unit-spawner"
        or prototype_name == "walker-electric-unit-spawner"
        or string.find(prototype_name, "electric%-unit%-spawner", 1, false) ~= nil
end

---@return nil
local function eon_prevent_fulgoran_enemy_bases_on_fulgora_oil_ocean()
    if not mods["Electric_flying_enemies"] then return end

    local collision_patched = 0
    local restriction_patched = 0
    for _, prototype_type in pairs({ "unit-spawner", "turret" }) do
        for prototype_name, prototype in pairs(data.raw[prototype_type] or {}) do
            if eon_is_fulgoran_enemy_base_prototype(prototype_type, prototype_name) then
                if eon_add_collision_mask_layer(prototype, "water_tile") then
                    collision_patched = collision_patched + 1
                end
                if eon_exclude_fulgora_oil_ocean_from_autoplace(prototype) then
                    restriction_patched = restriction_patched + 1
                end
            end
        end
    end

    log("[EON] Fulgoran Enemies oil-ocean base prevention patched collision_prototypes="
        .. collision_patched .. " tile_restriction_prototypes=" .. restriction_patched)
end

eon_prevent_fulgoran_enemy_bases_on_fulgora_oil_ocean()
