local eon_mode = require("lib.eon-mode")
if not eon_mode.planet_sounds then return end

local eon_sound_registry = require("lib.eon-sound-registry")

local RAIN_SOUND_FILENAME = "__space-age__/sound/world/weather/rain.ogg"

---@param value any
---@param filename string
---@return boolean
local function contains_filename(value, filename)
    if type(value) ~= "table" then return false end
    if value.filename == filename then return true end
    for _, child in pairs(value) do
        if contains_filename(child, filename) then return true end
    end
    return false
end

---@param value any
---@return table
local function ensure_array(value)
    if value == nil then return {} end
    if value[1] ~= nil then return value end
    return { value }
end

---@param target table
---@param source table
---@return nil
local function append_list(target, source)
    for _, value in ipairs(source) do
        table.insert(target, value)
    end
end

---@param target_planet_name string
---@param source_planet_name string
---@return nil
local function merge_persistent_sounds(target_planet_name, source_planet_name)
    local target = data.raw.planet[target_planet_name]
    if not target then return end

    local source = data.raw.planet[source_planet_name]
    if not source or not source.persistent_ambient_sounds then return end

    target.persistent_ambient_sounds = target.persistent_ambient_sounds or {}

    local target_pas = target.persistent_ambient_sounds
    local src_pas = source.persistent_ambient_sounds

    if not target_pas or not src_pas then return end

    for _, field_name in ipairs(eon_sound_registry.persistent_sound_fields) do
        local target_values = ensure_array(target_pas[field_name])
        local source_values = ensure_array(src_pas[field_name])

        if eon_mode.biome_weather and source_planet_name == "gleba" and target_planet_name == "nauvis" then
            local filtered = {}
            for _, value in ipairs(source_values) do
                if not contains_filename(value, RAIN_SOUND_FILENAME) then
                    filtered[#filtered + 1] = value
                end
            end
            source_values = filtered
        end

        append_list(target_values, source_values)
        target_pas[field_name] = target_values
    end
end

---@param source_planet_name string
---@param target_planet_name string
---@return nil
local function clone_planet_music(source_planet_name, target_planet_name)
    local clones = {}
    local ambient_sounds = data.raw["ambient-sound"] or {}

    for _, sound in pairs(ambient_sounds) do
        if sound.planet == source_planet_name and not eon_sound_registry.excluded_track_types[sound.track_type] then
            local copy = table.deepcopy(sound)
            copy.name = sound.name .. "-on-" .. target_planet_name
            copy.planet = target_planet_name
            clones[#clones + 1] = copy
        end
    end

    if next(clones) then
        data:extend(clones)
    end
end

for _, clone in ipairs(eon_sound_registry.music_clones) do
    clone_planet_music(clone.source, clone.target)
end

for _, merge in ipairs(eon_sound_registry.persistent_sound_merges) do
    merge_persistent_sounds(merge.target, merge.source)
end
