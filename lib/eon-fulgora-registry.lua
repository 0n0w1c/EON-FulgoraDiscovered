local fulgora = {}

fulgora.planet_name = "fulgora"

fulgora.cliff_control = "fulgora_cliff"
fulgora.cliffiness_property_expression = "eon_fulgora_cliffiness_off_aquilo"

fulgora.oil_ocean_tiles = {
    "oil-ocean-deep",
    "oil-ocean-deep-2",
    "oil-ocean-shallow",
    "oil-ocean-shallow-2",
}

fulgora.water_tiles = fulgora.oil_ocean_tiles

fulgora.scrap_resource = "scrap"

fulgora.extra_entities_to_mask_off_aquilo = {
    "fulgoran-ruin-attractor",
}

function fulgora.map_gen_settings()
    return data.raw.planet[fulgora.planet_name]
        and data.raw.planet[fulgora.planet_name].map_gen_settings
end

function fulgora.autoplace_settings()
    local map_gen = fulgora.map_gen_settings()
    return map_gen and map_gen.autoplace_settings
end

function fulgora.ensure_cliff_control()
    if data.raw["autoplace-control"][fulgora.cliff_control] then
        data.raw["autoplace-control"][fulgora.cliff_control].order = "c-z-c"
        data.raw["autoplace-control"][fulgora.cliff_control].category = "cliff"
        data.raw["autoplace-control"][fulgora.cliff_control].localised_description = nil
    else
        data:extend({
            {
                type = "autoplace-control",
                name = fulgora.cliff_control,
                order = "c-z-c",
                category = "cliff",
            },
        })
    end

    local map_gen = fulgora.map_gen_settings()
    if map_gen then
        map_gen.autoplace_controls = map_gen.autoplace_controls or {}
        map_gen.autoplace_controls[fulgora.cliff_control] =
            map_gen.autoplace_controls[fulgora.cliff_control] or {}
    end
end

return fulgora
