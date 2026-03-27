-- prototypes/fulgora-freezing.lua

local freezing_enabled = settings.startup["eon-fd-fulgora-freezing"].value
if not freezing_enabled then return end

local fulgora = data.raw.planet["fulgora"]
if fulgora then
    fulgora.entities_require_heating = true
end

local frost_free_enabled = settings.startup["eon-fd-frost-free"].value
if frost_free_enabled then
    local function strip_frozen_fields(tbl, seen)
        if type(tbl) ~= "table" then return end

        seen = seen or {}
        if seen[tbl] then return end
        seen[tbl] = true

        local remove = {}

        for key, value in pairs(tbl) do
            if type(key) == "string" then
                if key == "frozen_patch"
                    or key == "horizontal_frozen_patch"
                    or key == "vertical_frozen_patch"
                    or key == "platform_frozen"
                    or key == "frozen_patch_in"
                    or key == "frozen_patch_out"
                    or key == "frozen_variant"
                    or key == "thawed_variant"
                    or key:match("_frozen$")
                then
                    remove[#remove + 1] = key
                end
            end

            if type(value) == "table" then
                strip_frozen_fields(value, seen)
            end
        end

        for _, key in pairs(remove) do
            tbl[key] = nil
        end
    end

    for _, prototypes in pairs(data.raw) do
        for _, proto in pairs(prototypes) do
            strip_frozen_fields(proto)
        end
    end
end
