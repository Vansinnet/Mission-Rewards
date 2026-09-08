local mod = get_mod("Mission Rewards")

local LABELS = mod:io_dofile("Mission Rewards/scripts/mods/Mission Rewards/Mission Rewards_config")
local MAP_LENGTHS = mod:io_dofile("Mission Rewards/scripts/mods/Mission Rewards/Mission Rewards_map_lengths")
local BLUEPRINT_PATH = "scripts/ui/view_content_blueprints/mission_tile_blueprints/mission_tile_blueprints"
local TEMPLATE_MARKER = "mission_xp"
local LOGIC_STYLE_ID = "mission_rewards_logic"
local LABEL_HEIGHT = 18
local FIRST_LABEL_OFFSET_Y = 54
local LABEL_STEP_Y = 22
local TARGET_BLUEPRINTS = {
    "small_mission_tile_pass_templates",
    "replay_mission_tile_pass_templates",
}

mod._show_hub_xp_bar = mod:get("show_hub_xp_bar") ~= false

mod:register_hud_element({
    class_name = "HudElementMissionRewardsXpBar",
    filename = "Mission Rewards/scripts/mods/Mission Rewards/Mission Rewards_xp_bar",
    use_hud_scale = true,
    visibility_groups = { "alive" },
})

local function format_reward(value, label)
    if label.per_meter then
        return string.format("%.1f %s", value, label.suffix)
    elseif value >= 1000000 then
        return string.format("%.1fM %s", value / 1000000, label.suffix)
    elseif value >= 1000 then
        return string.format("%.1fK %s", value / 1000, label.suffix)
    end

    return string.format("%d %s", math.floor(value + 0.5), label.suffix)
end

local function label_value(label, xp, dockets, map_length)
    local value = label.source == "xp" and xp or dockets

    if label.per_meter then
        return value and map_length and map_length > 0 and value / map_length or nil
    end

    return value
end

local function main_reward(mission_data, circumstance, base_field, bonus_field)
    local value = mission_data and tonumber(mission_data[base_field])

    return value and value + (circumstance and tonumber(circumstance[bonus_field]) or 0) or nil
end

local function update_offsets(pass, ui_renderer, logic_style, content)
    local hotspot = content.hotspot
    local expansion = hotspot and (content.size and content.size[2] or 0) * 0.5
        * (0.1 * (hotspot.anim_hover_progress or 0) + 0.2 * (hotspot.anim_select_progress or 0)) or 0

    if content.mission_rewards_expansion == expansion then
        return
    end

    content.mission_rewards_expansion = expansion

    local styles = logic_style.parent

    for i = 1, #LABELS do
        local label = LABELS[i]

        if styles[label.text_id].visible ~= false then
            for j = 1, #label.style_ids do
                local style = styles[label.style_ids[j]]

                style.offset[2] = style.base_offset_y + expansion
            end
        end
    end
end


local pass_templates = {
    {
        pass_type = "logic",
        style_id = LOGIC_STYLE_ID,
        value = update_offsets,
        style = {},
    },
}

local function add_label_pass(label, pass_type, layer, z)
    local style_id = label.id .. "_" .. layer
    local style = {
        horizontal_alignment = "center",
        vertical_alignment = "bottom",
        size = {
            label.width,
            LABEL_HEIGHT,
        },
        offset = {
            0,
            label.offset_y,
            z,
        },
    }
    local definition = {
        pass_type = pass_type,
        style_id = style_id,
        style = style,
    }

    if pass_type == "rect" then
        style.color = { 220, 0, 8, 3 }
    elseif pass_type == "texture" then
        definition.value = "content/ui/materials/frames/frame_tile_2px"
        style.scale_to_material = true
        style.color = { 255, 101, 200, 110 }
    else
        definition.value = ""
        definition.value_id = style_id
        style.drop_shadow = true
        style.font_size = label.font_size
        style.font_type = "mono_tide_bold"
        style.text_fit_with = true
        style.text_horizontal_alignment = "center"
        style.text_vertical_alignment = "center"
        style.text_color = { 255, 101, 230, 125 }
    end

    pass_templates[#pass_templates + 1] = definition

    return style_id
end

for i = 1, #LABELS do
    local label = LABELS[i]

    label.id = "mission_" .. label.key
    label.setting_id = "show_" .. label.key
    label.offset_y = FIRST_LABEL_OFFSET_Y + (i - 1) * LABEL_STEP_Y
    label.background_id = add_label_pass(label, "rect", "background", 30)
    label.frame_id = add_label_pass(label, "texture", "frame", 31)
    label.text_id = add_label_pass(label, "text", "text", 32)
    label.style_ids = { label.background_id, label.frame_id, label.text_id }
end

local reward_template = {
    [TEMPLATE_MARKER] = true,
    pass_templates = pass_templates,
    init = function(widget, mission_data, creation_context)
        local content = widget.content
        local styles = widget.style
        local extra_rewards = mission_data and mission_data.extraRewards
        local circumstance = extra_rewards and extra_rewards.circumstance
        local xp = main_reward(mission_data, circumstance, "mission_xp", "xp")
        local dockets = main_reward(mission_data, circumstance, "mission_reward", "credits")
        local map_length = mission_data and MAP_LENGTHS[mission_data.map]
        local next_offset_y = FIRST_LABEL_OFFSET_Y
        local any_visible = false

        content.mission_rewards_expansion = 0

        for i = 1, #LABELS do
            local label = LABELS[i]
            local value = label_value(label, xp, dockets, map_length)
            local visible = value ~= nil and mod:get(label.setting_id) ~= false
            local offset_y = visible and next_offset_y or label.offset_y

            next_offset_y = visible and next_offset_y + LABEL_STEP_Y or next_offset_y
            any_visible = any_visible or visible
            content[label.text_id] = visible and format_reward(value, label) or ""

            for j = 1, #label.style_ids do
                local style = styles[label.style_ids[j]]

                style.visible = visible
                style.base_offset_y = offset_y
                style.offset[2] = offset_y
            end

            if creation_context.is_locked then
                styles[label.frame_id].color[1] = 140
                styles[label.text_id].text_color[1] = 140
            end
        end

        styles[LOGIC_STYLE_ID].visible = any_visible
    end,
}

local function set_reward_template(templates)
    if not templates then
        return
    end

    for i = 1, #templates do
        if templates[i][TEMPLATE_MARKER] then
            templates[i] = reward_template

            return
        end
    end

    templates[#templates + 1] = reward_template
end

local function apply_reward_template(blueprints)
    for i = 1, #TARGET_BLUEPRINTS do
        set_reward_template(blueprints[TARGET_BLUEPRINTS[i]])
    end
end

mod:hook_require(BLUEPRINT_PATH, apply_reward_template)
apply_reward_template(require(BLUEPRINT_PATH))

mod.on_setting_changed = function(setting_id)
    if setting_id == "show_hub_xp_bar" then
        mod._show_hub_xp_bar = mod:get(setting_id) ~= false
    end
end
