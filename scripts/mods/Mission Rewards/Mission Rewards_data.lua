local mod = get_mod("Mission Rewards")
local labels = mod:io_dofile("Mission Rewards/scripts/mods/Mission Rewards/Mission Rewards_config")
local widgets = {}

for i = 1, #labels do
    local setting_id = "show_" .. labels[i].key

    widgets[i] = {
        setting_id = setting_id,
        type = "checkbox",
        default_value = true,
        tooltip = setting_id .. "_tooltip",
    }
end

widgets[#widgets + 1] = {
    setting_id = "show_hub_xp_bar",
    type = "checkbox",
    default_value = true,
    tooltip = "show_hub_xp_bar_tooltip",
}

return {
    name = mod:localize("mod_name"),
    description = mod:localize("mod_description"),
    is_togglable = false,
    options = {
        widgets = widgets,
    },
}
