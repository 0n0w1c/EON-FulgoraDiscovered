local eon_tile_registry = require("lib.eon-tile-registry")

local eon_runtime_cliffs = {}

local aquilo_cliff_blocking_tile_names = eon_tile_registry.cliff_blocking.aquilo_names
local aquilo_cliff_blocking_tile_lookup = eon_tile_registry.cliff_blocking.aquilo_set
local nauvis_tile_names = eon_tile_registry.cliff_blocking.nauvis_set
local terrain_cliff_rules = eon_tile_registry.cliff_blocking.rules

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
local function keep_cliff_off_aquilo_tiles(cliff, args)
    if not (cliff and cliff.valid) then return false end
    if cliff.name == "crater-cliff" then return true end

    local surface_name = cliff.surface.name
    local should_remove = false

    if args and args.aquilo_on_fulgora then
        should_remove = false
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

---@param surface LuaSurface
---@param area BoundingBox
---@param args table|nil
---@return nil
function eon_runtime_cliffs.process_area(surface, area, args)
    args = args or {}

    local cliffs = surface.find_entities_filtered({
        area = area,
        type = "cliff"
    })

    for _, cliff in pairs(cliffs) do
        if keep_cliff_off_aquilo_tiles(cliff, args) and cliff.valid and cliff.name ~= "crater-cliff" then
            replace_with_terrain_cliff(cliff)
        end
    end
end

return eon_runtime_cliffs
