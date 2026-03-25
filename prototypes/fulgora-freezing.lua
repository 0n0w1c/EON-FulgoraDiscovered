-- prototypes/fulgora-freezing.lua

local freezing_enabled = settings.startup["eon-fd-fulgora-freezing"].value
if not freezing_enabled then
    return
end

local fulgora = data.raw.planet["fulgora"]
if fulgora then
    fulgora.entities_require_heating = true
end

local frost_free_enabled = settings.startup["eon-fd-frost-free"].value
if frost_free_enabled then
    for prototype_type, prototypes in pairs(data.raw) do
        for _, proto in pairs(prototypes) do
            -- entity-style frozen overlay
            if proto.frozen_patch ~= nil then
                proto.frozen_patch = nil
            end

            if proto.graphics_set and proto.graphics_set.frozen_patch ~= nil then
                proto.graphics_set.frozen_patch = nil
            end

            -- tile frozen swap
            if prototype_type == "tile" then
                if proto.frozen_variant ~= nil then
                    proto.frozen_variant = nil
                end
                if proto.thawed_variant ~= nil then
                    proto.thawed_variant = nil
                end
            end
        end
    end
end
