local eon_nauvis_cliff_settings = {}

---@return nil
function eon_nauvis_cliff_settings.apply_blended_cliff_settings()
    local nauvis = data.raw.planet and data.raw.planet["nauvis"]
    if not (nauvis and nauvis.map_gen_settings) then return end

    nauvis.map_gen_settings.property_expression_names = nauvis.map_gen_settings.property_expression_names or {}
    nauvis.map_gen_settings.property_expression_names["cliffiness"] = "eon_blended_cliffiness"
    nauvis.map_gen_settings.property_expression_names["cliff_elevation"] = "eon_blended_cliff_elevation"

    local cliff_settings = nauvis.map_gen_settings.cliff_settings
    if cliff_settings then
        cliff_settings.cliff_smoothing = 0
        cliff_settings.cliff_elevation_interval = 12
        cliff_settings.richness = 1.0
    end
end

return eon_nauvis_cliff_settings
