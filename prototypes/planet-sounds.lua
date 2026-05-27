local sounds_enabled = settings.startup["eon-fd-planet-sounds"].value
if not sounds_enabled then return end

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

    local target_base_ambience = ensure_array(target_pas.base_ambience)
    local target_wind = ensure_array(target_pas.wind)
    local target_semi_persistent = ensure_array(target_pas.semi_persistent)

    local source_base_ambience = ensure_array(src_pas.base_ambience)
    local source_wind = ensure_array(src_pas.wind)
    local source_semi_persistent = ensure_array(src_pas.semi_persistent)

    append_list(target_base_ambience, source_base_ambience)
    append_list(target_wind, source_wind)
    append_list(target_semi_persistent, source_semi_persistent)

    target_pas.base_ambience = target_base_ambience
    target_pas.wind = target_wind
    target_pas.semi_persistent = target_semi_persistent
end

---@param source_planet_name string
---@param target_planet_name string
---@return nil
local function clone_planet_music(source_planet_name, target_planet_name)
    local clones = {}
    local ambient_sounds = data.raw["ambient-sound"] or {}

    for _, sound in pairs(ambient_sounds) do
        if sound.planet == source_planet_name then
            if sound.track_type ~= "hero-track" then
                local copy = table.deepcopy(sound)
                copy.name = sound.name .. "-on-" .. target_planet_name
                copy.planet = target_planet_name
                clones[#clones + 1] = copy
            end
        end
    end

    if next(clones) then
        data:extend(clones)
    end
end

clone_planet_music("gleba", "nauvis")
clone_planet_music("vulcanus", "nauvis")
clone_planet_music("aquilo", "fulgora")

merge_persistent_sounds("nauvis", "gleba")
merge_persistent_sounds("nauvis", "vulcanus")
merge_persistent_sounds("fulgora", "aquilo")
