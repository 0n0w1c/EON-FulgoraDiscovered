local sounds_enabled = settings.startup["eon-fd-planet-sounds"].value
if not sounds_enabled then return end

local function ensure_array(v)
    if v == nil then return {} end
    if v[1] ~= nil then return v end
    return { v }
end

local function should_skip_sound(entry)
    if not entry or not entry.sound then
        return false
    end

    local sound = entry.sound

    if sound.filename then
        if string.find(sound.filename, "rain") then
            return true
        end
    end

    if sound.variations then
        for _, v in ipairs(sound.variations) do
            if v.filename then
                if string.find(v.filename, "ice%-cracks") then
                    return true
                end
            end
        end
    end

    return false
end

local function append_list(dst, src)
    for i = 1, #src do
        local entry = src[i]

        if not should_skip_sound(entry) then
            dst[#dst + 1] = table.deepcopy(entry)
        end
    end
end

local function merge_persistent_sounds(target_planet_name, source_planet_name)
    local target = data.raw.planet[target_planet_name]
    if not target then return end

    local source = data.raw.planet[source_planet_name]
    if not source or not source.persistent_ambient_sounds then return end

    target.persistent_ambient_sounds = target.persistent_ambient_sounds or {}

    local target_pas = target.persistent_ambient_sounds
    if not target_pas then return end
    local src_pas = source.persistent_ambient_sounds
    if not src_pas then return end

    target_pas.base_ambience = ensure_array(target_pas.base_ambience)
    target_pas.wind = ensure_array(target_pas.wind)
    target_pas.semi_persistent = ensure_array(target_pas.semi_persistent)

    append_list(target_pas.base_ambience, ensure_array(src_pas.base_ambience))
    append_list(target_pas.wind, ensure_array(src_pas.wind))
    append_list(target_pas.semi_persistent, ensure_array(src_pas.semi_persistent))
end

local function clone_planet_music(source_planet_name, target_planet_name)
    local clones = {}
    local ambient_sounds = data.raw["ambient-sound"] or {}

    for _, sound in pairs(ambient_sounds) do
        if sound.planet == source_planet_name then
            -- skip hero tracks: only one allowed per planet
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
