local eon_aquilo_on_fulgora = settings.startup["eon-fd-aquilo-on-fulgora"]
    and settings.startup["eon-fd-aquilo-on-fulgora"].value

local surface_names = { nauvis = true }
if eon_aquilo_on_fulgora then
    surface_names.fulgora = true
end

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
            ["volcanic-ash-flats"] = true,
            ["volcanic-ash-light"] = true,
            ["volcanic-ash-dark"] = true,
            ["volcanic-ash-cracks"] = true,
            ["volcanic-cracks"] = true,
            ["volcanic-cracks-warm"] = true,
            ["volcanic-cracks-hot"] = true,
            ["volcanic-folds"] = true,
            ["volcanic-folds-flat"] = true,
            ["volcanic-folds-warm"] = true,
            ["volcanic-jagged-ground"] = true,
            ["volcanic-pumice-stones"] = true,
            ["volcanic-smooth-stone"] = true,
            ["volcanic-smooth-stone-warm"] = true
        }
    }
}

local function tile_matches(surface, position, tile_names)
    local tile = surface.get_tile(position.x, position.y)
    return tile and tile_names[tile.name] == true
end

local function cliff_overlaps_tiles(cliff, tile_names)
    local surface = cliff.surface

    if tile_matches(surface, cliff.position, tile_names) then
        return true
    end

    local box = cliff.bounding_box or cliff.selection_box
    if not box then return false end

    local left = math.floor(box.left_top.x)
    local top = math.floor(box.left_top.y)
    local right = math.ceil(box.right_bottom.x) - 1
    local bottom = math.ceil(box.right_bottom.y) - 1

    for x = left, right do
        for y = top, bottom do
            if tile_matches(surface, { x = x, y = y }, tile_names) then
                return true
            end
        end
    end

    return false
end

local function target_cliff_rule_for_terrain(cliff)
    for _, rule in ipairs(terrain_cliff_rules) do
        if cliff_overlaps_tiles(cliff, rule.tile_names) then
            return rule
        end
    end

    return nil
end

local function rotate_cliff_to_orientation(cliff, target_orientation)
    if not (cliff and cliff.valid and target_orientation) then return end

    local attempts = 0
    while cliff.valid and cliff.cliff_orientation ~= target_orientation and attempts < 20 do
        cliff.rotate()
        attempts = attempts + 1
    end
end

local function create_cliff(surface, name, original_cliff_data)
    local create_params = {
        name = name,
        position = original_cliff_data.position,
        direction = original_cliff_data.direction,
        orientation = original_cliff_data.orientation,
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

local function replace_with_terrain_cliff(cliff)
    if not (cliff and cliff.valid) then return end

    local target_rule = target_cliff_rule_for_terrain(cliff)
    if not target_rule then return end

    if target_rule.destroy then
        cliff.destroy({ raise_destroy = false })
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
        orientation = cliff.orientation,
        cliff_orientation = cliff.cliff_orientation,
        force = cliff.force
    }

    cliff.destroy({ raise_destroy = false })

    local created_cliff = create_cliff(surface, target_cliff_name, original_cliff_data)
    if not (created_cliff and created_cliff.valid) then
        create_cliff(surface, original_name, original_cliff_data)
    end
end

local function process_area(surface, area)
    local cliffs = surface.find_entities_filtered({
        area = area,
        type = "cliff"
    })

    for _, cliff in pairs(cliffs) do
        replace_with_terrain_cliff(cliff)
    end
end

script.on_event(defines.events.on_chunk_generated, function(event)
    local surface = event.surface
    if not (surface and surface.valid) then return end
    if not surface_names[surface.name] then return end

    process_area(surface, event.area)
end)
