local menu_simulations = {}

local PATCH_MARKER = "-- EON: keep prerecorded race cars facing along their recorded path"
local TELEPORT_LINE = "          cars[i].teleport(driving_data[i][drive_tick][2])"

local ORIENTATION_PATCH = [[          local current_position = driving_data[i][drive_tick][2]
          cars[i].teleport(current_position)

          -- EON: keep prerecorded race cars facing along their recorded path
          -- The original simulation records riding_state and position, but relies on
          -- vehicle physics to update orientation. Deriving it from the recorded path
          -- makes the replay stable when other prototype changes alter that physics.
          local adjacent_entry = driving_data[i][drive_tick + 1]
          local reverse_facing = false
          if not adjacent_entry and drive_tick > 1 then
            adjacent_entry = driving_data[i][drive_tick - 1]
            reverse_facing = true
          end

          if adjacent_entry then
            local adjacent_position = adjacent_entry[2]
            local dx
            local dy
            if reverse_facing then
              dx = current_position[1] - adjacent_position[1]
              dy = current_position[2] - adjacent_position[2]
            else
              dx = adjacent_position[1] - current_position[1]
              dy = adjacent_position[2] - current_position[2]
            end

            if dx ~= 0 or dy ~= 0 then
              local orientation = math.atan2(dx, -dy) / (2 * math.pi)
              if orientation < 0 then orientation = orientation + 1 end
              cars[i].orientation = orientation
            end
          end]]

---@return boolean
function menu_simulations.patch_fulgora_race_orientation()
    local constants = data.raw["utility-constants"] and data.raw["utility-constants"]["default"]
    local simulations = constants and constants.main_menu_simulations
    local simulation = simulations and simulations["fulgora_race"]
    if not simulation or type(simulation.init) ~= "string" then return false end

    if string.find(simulation.init, PATCH_MARKER, 1, true) then return true end

    local start_index, end_index = string.find(simulation.init, TELEPORT_LINE, 1, true)
    if not start_index then return false end

    simulation.init = string.sub(simulation.init, 1, start_index - 1)
        .. ORIENTATION_PATCH
        .. string.sub(simulation.init, end_index + 1)

    return true
end

return menu_simulations
