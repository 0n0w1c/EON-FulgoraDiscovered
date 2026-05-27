local eon_aquilo_on_fulgora = settings.startup["eon-fd-aquilo-on-fulgora"]
    and settings.startup["eon-fd-aquilo-on-fulgora"].value

local surface_names = { nauvis = true }
if eon_aquilo_on_fulgora then
    surface_names.fulgora = true
end

local aquilo_cliff_blocking_tile_names = {
    "ammoniacal-ocean",
    "ammoniacal-ocean-2",
    "brash-ice",
    "ice-rough",
    "ice-smooth",
    "snow-crests",
    "snow-flat",
    "snow-lumpy",
    "snow-patchy"
}

local aquilo_cliff_blocking_tile_lookup = {
    ["ammoniacal-ocean"] = true,
    ["ammoniacal-ocean-2"] = true,
    ["brash-ice"] = true,
    ["ice-rough"] = true,
    ["ice-smooth"] = true,
    ["snow-crests"] = true,
    ["snow-flat"] = true,
    ["snow-lumpy"] = true,
    ["snow-patchy"] = true
}


local nauvis_tile_names = {
    ["grass-1"] = true,
    ["grass-2"] = true,
    ["grass-3"] = true,
    ["grass-4"] = true,
    ["dry-dirt"] = true,
    ["dirt-1"] = true,
    ["dirt-2"] = true,
    ["dirt-3"] = true,
    ["dirt-4"] = true,
    ["dirt-5"] = true,
    ["dirt-6"] = true,
    ["dirt-7"] = true,
    ["sand-1"] = true,
    ["sand-2"] = true,
    ["sand-3"] = true,
    ["red-desert-0"] = true,
    ["red-desert-1"] = true,
    ["red-desert-2"] = true,
    ["red-desert-3"] = true
}

local terrain_cliff_rules = {
    {
        cliff_name = "cliff-gleba",
        tile_names = {
            ["natural-yumako-soil"] = true,
            ["natural-jellynut-soil"] = true,
            ["wetland-yumako"] = true,
            ["wetland-jellynut"] = true,
            ["wetland-blue-slime"] = true,
            ["wetland-light-green-slime"] = true,
            ["wetland-green-slime"] = true,
            ["wetland-light-dead-skin"] = true,
            ["wetland-dead-skin"] = true,
            ["wetland-pink-tentacle"] = true,
            ["wetland-red-tentacle"] = true,
            ["gleba-deep-lake"] = true,
            ["lowland-brown-blubber"] = true,
            ["lowland-olive-blubber"] = true,
            ["lowland-olive-blubber-2"] = true,
            ["lowland-olive-blubber-3"] = true,
            ["lowland-pale-green"] = true,
            ["lowland-cream-cauliflower"] = true,
            ["lowland-cream-cauliflower-2"] = true,
            ["lowland-dead-skin"] = true,
            ["lowland-dead-skin-2"] = true,
            ["lowland-cream-red"] = true,
            ["lowland-red-vein"] = true,
            ["lowland-red-vein-2"] = true,
            ["lowland-red-vein-3"] = true,
            ["lowland-red-vein-4"] = true,
            ["lowland-red-vein-dead"] = true,
            ["lowland-red-infection"] = true,
            ["midland-turquoise-bark"] = true,
            ["midland-turquoise-bark-2"] = true,
            ["midland-cracked-lichen"] = true,
            ["midland-cracked-lichen-dull"] = true,
            ["midland-cracked-lichen-dark"] = true,
            ["midland-yellow-crust"] = true,
            ["midland-yellow-crust-2"] = true,
            ["midland-yellow-crust-3"] = true,
            ["midland-yellow-crust-4"] = true,
            ["highland-dark-rock"] = true,
            ["highland-dark-rock-2"] = true,
            ["highland-yellow-rock"] = true,
            ["pit-rock"] = true
        }
    },
    {
        cliff_name = "cliff-vulcanus",
        tile_names = {
            ["volcanic-soil-dark"] = true,
            ["volcanic-soil-light"] = true,
            ["volcanic-ash-soil"] = true,
            ["volcanic-ash-flats"] = true,
            ["volcanic-ash-light"] = true,
            ["volcanic-ash-dark"] = true,
            ["volcanic-ash-cracks"] = true,
            ["volcanic-cracks"] = true,
            ["volcanic-cracks-warm"] = true,
            ["volcanic-cracks-hot"] = true,
            ["volcanic-folds"] = true,
            ["volcanic-folds-flat"] = true,
            ["lava"] = true,
            ["lava-hot"] = true,
            ["volcanic-folds-warm"] = true,
            ["volcanic-jagged-ground"] = true,
            ["volcanic-pumice-stones"] = true,
            ["volcanic-smooth-stone"] = true,
            ["volcanic-smooth-stone-warm"] = true
        }
    }
}

---@param cliff LuaEntity
---@return table
local function cliff_scan_area(cliff)
    return {
        left_top = {
            x = cliff.position.x - 3,
            y = cliff.position.y - 3
        },
        right_bottom = {
            x = cliff.position.x + 3,
            y = cliff.position.y + 3
        }
    }
end

---@param cliff LuaEntity
---@return boolean
local function cliff_overlaps_aquilo_tile(cliff)
    local surface = cliff.surface
    local area = cliff_scan_area(cliff)

    if area then
        return surface.count_tiles_filtered({
            area = area,
            name = aquilo_cliff_blocking_tile_names,
            limit = 1
        }) > 0
    end

    local tile = surface.get_tile(cliff.position.x, cliff.position.y)
    return tile and aquilo_cliff_blocking_tile_lookup[tile.name] == true
end

---@param cliff LuaEntity
---@return boolean
local function keep_cliff_off_aquilo_tiles(cliff)
    if not (cliff and cliff.valid) then return false end
    if cliff.name == "crater-cliff" then return true end

    local surface_name = cliff.surface.name
    local should_remove = false

    if eon_aquilo_on_fulgora then
        should_remove = surface_name == "fulgora" and cliff.name == "cliff-fulgora"
    else
        should_remove = surface_name == "nauvis"
    end

    if should_remove and cliff_overlaps_aquilo_tile(cliff) then
        cliff.destroy({ do_cliff_correction = true, raise_destroy = false })
        return false
    end

    return true
end

---@param cliff table
---@return any
local function scan_cliff_terrain(cliff)
    local found = {
        gleba = false,
        vulcanus = false,
        nauvis = false
    }

    local surface = cliff.surface
    local area = cliff_scan_area(cliff)
    local left = math.floor(area.left_top.x)
    local top = math.floor(area.left_top.y)
    local right = math.ceil(area.right_bottom.x) - 1
    local bottom = math.ceil(area.right_bottom.y) - 1

    local gleba_tile_names = terrain_cliff_rules[1].tile_names
    local vulcanus_tile_names = terrain_cliff_rules[2].tile_names

    for x = left, right do
        for y = top, bottom do
            local tile = surface.get_tile(x, y)
            local tile_name = tile and tile.name
            if tile_name then
                if vulcanus_tile_names[tile_name] then
                    found.vulcanus = true
                elseif gleba_tile_names[tile_name] then
                    found.gleba = true
                elseif nauvis_tile_names[tile_name] then
                    found.nauvis = true
                end
            end
        end
    end

    return found
end

---@param cliff table
---@return any
local function target_cliff_rule_for_terrain(cliff)
    local found = scan_cliff_terrain(cliff)

    if (found.vulcanus or found.gleba) and found.nauvis then
        return "destroy"
    end

    if found.vulcanus then
        return terrain_cliff_rules[2]
    end

    if found.gleba then
        return terrain_cliff_rules[1]
    end

    return nil
end

---@param cliff table
---@param target_orientation string
---@return nil
local function rotate_cliff_to_orientation(cliff, target_orientation)
    if not (cliff and cliff.valid and target_orientation) then return end

    local attempts = 0
    while cliff.valid and cliff.cliff_orientation ~= target_orientation and attempts < 20 do
        cliff.rotate()
        attempts = attempts + 1
    end
end

---@param surface table
---@param name string
---@param original_cliff_data any
---@return any
local function create_cliff(surface, name, original_cliff_data)
    local create_params = {
        name = name,
        position = original_cliff_data.position,
        direction = original_cliff_data.direction,
        force = original_cliff_data.force,
        create_build_effect_smoke = false,
        raise_built = false
    }

    local entity = surface.create_entity(create_params)

    if entity and entity.valid then
        rotate_cliff_to_orientation(entity, original_cliff_data.cliff_orientation)
        return entity
    end

    return nil
end

---@param cliff table
---@return nil
local function replace_with_terrain_cliff(cliff)
    if not (cliff and cliff.valid) then return end

    local target_rule = target_cliff_rule_for_terrain(cliff)
    if not target_rule then return end

    if target_rule == "destroy" then
        cliff.destroy({ do_cliff_correction = true, raise_destroy = false })
        return
    end

    local target_cliff_name = target_rule.cliff_name
    if not target_cliff_name then return end
    if cliff.name == target_cliff_name then return end

    local surface = cliff.surface
    local original_name = cliff.name
    local original_cliff_data = {
        position = { x = cliff.position.x, y = cliff.position.y },
        direction = cliff.direction,
        cliff_orientation = cliff.cliff_orientation,
        force = cliff.force
    }

    if not cliff.destroy({ raise_destroy = false }) then
        return
    end

    local created_cliff = create_cliff(surface, target_cliff_name, original_cliff_data)
    if not (created_cliff and created_cliff.valid) then
        create_cliff(surface, original_name, original_cliff_data)
    end
end

---@param surface table
---@param area table
---@return nil
local function process_area(surface, area)
    local cliffs = surface.find_entities_filtered({
        area = area,
        type = "cliff"
    })

    for _, cliff in pairs(cliffs) do
        if keep_cliff_off_aquilo_tiles(cliff) and cliff.valid and cliff.name ~= "crater-cliff" then
            replace_with_terrain_cliff(cliff)
        end
    end
end


script.on_event(defines.events.on_chunk_generated, function(event)
    local surface = event.surface
    if not (surface and surface.valid) then return end
    if not surface_names[surface.name] then return end

    process_area(surface, event.area)
end)



local explosive_biter_autoplace_entities = {
    "explosive-biter-spawner",
    "small-explosive-worm-turret",
    "medium-explosive-worm-turret",
    "big-explosive-worm-turret",
    "behemoth-explosive-worm-turret",
    "leviathan-explosive-worm-turret",
    "mother-explosive-worm-turret"
}

---@param control table|nil
---@return table
local function eon_copy_autoplace_control(control)
    if not control then return {} end

    local copy = {}
    for key, value in pairs(control) do
        copy[key] = value
    end
    return copy
end

---@return nil
local function eon_enable_explosive_biters_on_existing_nauvis()
    if not script.active_mods["Explosive_biters"] then return end

    local surface = game.surfaces["nauvis"]
    if not surface then return end

    local map_gen_settings = surface.map_gen_settings
    map_gen_settings.autoplace_controls = map_gen_settings.autoplace_controls or {}

    if not map_gen_settings.autoplace_controls["hot_enemy_base"] then
        map_gen_settings.autoplace_controls["hot_enemy_base"] =
            eon_copy_autoplace_control(map_gen_settings.autoplace_controls["enemy-base"])
    end

    map_gen_settings.autoplace_settings = map_gen_settings.autoplace_settings or {}
    map_gen_settings.autoplace_settings.entity = map_gen_settings.autoplace_settings.entity or { settings = {} }
    map_gen_settings.autoplace_settings.entity.settings = map_gen_settings.autoplace_settings.entity.settings or {}

    for _, entity_name in pairs(explosive_biter_autoplace_entities) do
        if prototypes.entity[entity_name] and prototypes.entity[entity_name].autoplace_specification then
            map_gen_settings.autoplace_settings.entity.settings[entity_name] =
                map_gen_settings.autoplace_settings.entity.settings[entity_name] or {}
        end
    end

    surface.map_gen_settings = map_gen_settings
end

script.on_init(function()
    eon_enable_explosive_biters_on_existing_nauvis()
end)

script.on_configuration_changed(function()
    eon_enable_explosive_biters_on_existing_nauvis()
end)
