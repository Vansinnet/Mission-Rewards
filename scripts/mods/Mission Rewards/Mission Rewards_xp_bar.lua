---@class MissionRewardsMod
local mod = get_mod("Mission Rewards")

local Promise = require("scripts/foundation/utilities/promise")
local UIHudSettings = require("scripts/settings/ui/ui_hud_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")
local UIWorkspaceSettings = require("scripts/settings/ui/ui_workspace_settings")
local class = rawget(_G, "class")
local Color = rawget(_G, "Color")

local LEVEL_WIDTH = 66
local BAR_WIDTH = 420
local NEXT_LEVEL_WIDTH = 82
local PANEL_HEIGHT = 38
local BAR_HEIGHT = 24

local scenegraph_definition = {
    screen = UIWorkspaceSettings.screen,
    panel = {
        horizontal_alignment = "center",
        parent = "screen",
        vertical_alignment = "bottom",
        size = { LEVEL_WIDTH + BAR_WIDTH + NEXT_LEVEL_WIDTH + 16, PANEL_HEIGHT },
        position = { 0, -68, 100 },
    },
    level = {
        horizontal_alignment = "left",
        parent = "panel",
        vertical_alignment = "center",
        size = { LEVEL_WIDTH, PANEL_HEIGHT },
        position = { 0, 0, 1 },
    },
    experience = {
        horizontal_alignment = "left",
        parent = "panel",
        vertical_alignment = "center",
        size = { BAR_WIDTH, BAR_HEIGHT },
        position = { LEVEL_WIDTH + 8, 0, 1 },
    },
    next_level = {
        horizontal_alignment = "left",
        parent = "panel",
        vertical_alignment = "center",
        size = { NEXT_LEVEL_WIDTH, PANEL_HEIGHT },
        position = { LEVEL_WIDTH + BAR_WIDTH + 16, 0, 1 },
    },
}

local experience_passes = {
    {
        pass_type = "texture",
        style_id = "bar",
        value = "content/ui/materials/bars/exp_fill",
        style = {
            horizontal_alignment = "left",
            vertical_alignment = "center",
            size = { 0, BAR_HEIGHT - 10 },
            offset = { 4, 0, 2 },
            color = { 255, 82, 148, 96 },
        },
        change_function = function(content, style)
            style.size[1] = (content.bar_length - 8) * content.progress
        end,
    },
    {
        pass_type = "texture",
        style_id = "end",
        value = "content/ui/materials/bars/simple/end",
        style = {
            horizontal_alignment = "left",
            vertical_alignment = "center",
            size = { 12, BAR_HEIGHT - 10 },
            size_addition = { 0, 18 },
            offset = { 0, 0, 3 },
            color = { 0, 255, 255, 255 },
        },
        change_function = function(content, style)
            local progress = content.progress

            style.offset[1] = 4 + (content.bar_length - 8) * progress - 8
            style.color[1] = 255 * math.min(progress / 0.2, 1)
        end,
    },
    {
        pass_type = "rect",
        style_id = "background",
        style = {
            color = { 235, 4, 7, 6 },
            offset = { 0, 0, 0 },
        },
    },
    {
        pass_type = "texture",
        style_id = "frame",
        value = "content/ui/materials/frames/frame_tile_2px",
        style = {
            color = Color.terminal_frame(255, true),
            offset = { 0, 0, 4 },
            scale_to_material = true,
        },
    },
    {
        pass_type = "text",
        style_id = "xp_text",
        value = "",
        value_id = "xp_text",
        style = {
            horizontal_alignment = "center",
            vertical_alignment = "center",
            offset = { 0, 0, 5 },
            drop_shadow = true,
            font_size = 14,
            font_type = "machine_medium",
            text_color = UIHudSettings.color_tint_main_1,
            text_horizontal_alignment = "center",
            text_vertical_alignment = "center",
        },
    },
}

local function level_plate_definition(show_level_icon)
    local passes = {
        {
            pass_type = "texture",
            style_id = "background",
            value = "content/ui/materials/backgrounds/terminal_basic",
            style = {
                color = Color.terminal_grid_background(245, true),
                offset = { 0, 0, 0 },
                scale_to_material = true,
            },
        },
        {
            pass_type = "texture",
            style_id = "plate",
            value = "content/ui/materials/buttons/primary",
            style = {
                color = Color.white(255, true),
                offset = { 0, 0, 1 },
                scale_to_material = true,
            },
        },
        {
            pass_type = "text",
            style_id = "text",
            value = "",
            value_id = "text",
            style = {
                drop_shadow = true,
                font_size = 22,
                font_type = "machine_medium",
                offset = { show_level_icon and -8 or 0, 0, 3 },
                text_color = UIHudSettings.color_tint_main_1,
                text_horizontal_alignment = "center",
                text_vertical_alignment = "center",
            },
        },
    }

    if show_level_icon then
        passes[#passes + 1] = {
            pass_type = "texture",
            style_id = "level_icon",
            value = "content/ui/materials/symbols/character_level",
            style = {
                horizontal_alignment = "right",
                vertical_alignment = "center",
                size = { 22, 22 },
                offset = { -8, 0, 3 },
                color = UIHudSettings.color_tint_main_1,
            },
        }
    end

    return UIWidget.create_definition(passes, show_level_icon and "next_level" or "level")
end

local widget_definitions = {
    level = level_plate_definition(false),
    experience = UIWidget.create_definition(experience_passes, "experience", {
        bar_length = BAR_WIDTH,
        progress = 0,
    }, { BAR_WIDTH, BAR_HEIGHT }),
    next_level = level_plate_definition(true),
}

local definitions = {
    scenegraph_definition = scenegraph_definition,
    widget_definitions = widget_definitions,
}

local HudElementMissionRewardsXpBar = class("HudElementMissionRewardsXpBar", "HudElementBase")

local function is_in_hub()
    local state = Managers.state
    local game_mode = state and state.game_mode

    return game_mode and game_mode:game_mode_name() == "hub"
end

local function calculate_level_and_progress(progression, xp_curve)
    local max_level = #xp_curve
    local current_level = tonumber(progression.currentLevel)
    local current_xp = tonumber(progression.currentXp)

    if not current_level or not current_xp or max_level < 2 then
        return nil
    end

    if current_level < max_level then
        local current_xp_in_level = tonumber(progression.currentXpInLevel) or 0
        local needed_xp = tonumber(progression.neededXpForNextLevel) or 0
        local xp_per_level = current_xp_in_level + needed_xp
        local progress = xp_per_level > 0 and current_xp_in_level / xp_per_level or 0

        return current_level, math.min(math.max(progress, 0), 1), current_xp_in_level, xp_per_level
    end

    local xp_per_level = xp_curve[max_level] - xp_curve[max_level - 1]

    if xp_per_level <= 0 then
        return nil
    end

    local xp_over_max_level = math.max(0, current_xp - xp_curve[max_level])
    local additional_levels = math.floor(xp_over_max_level / xp_per_level)
    local current_xp_in_level = xp_over_max_level % xp_per_level
    local progress = current_xp_in_level / xp_per_level

    return current_level + additional_levels, progress, current_xp_in_level, xp_per_level
end

local function format_xp_text(current_xp, xp_per_level)
    return string.format("%d / %d", math.floor(current_xp + 0.5), math.floor(xp_per_level + 0.5))
end

HudElementMissionRewardsXpBar.init = function(self, parent, draw_layer, start_scale)
    HudElementMissionRewardsXpBar.super.init(self, parent, draw_layer, start_scale, definitions)

    self._character_id = nil
    self._fetching_character_id = nil
    self._has_progression = false
    self._destroyed = false
end

HudElementMissionRewardsXpBar._fetch_progression = function(self, character_id)
    local backend = Managers.backend
    local interfaces = backend and backend.interfaces
    local progression_interface = interfaces and interfaces.progression

    if not progression_interface or not backend:authenticated() then
        return
    end

    self._fetching_character_id = character_id

    local progression_promise = progression_interface:get_progression("character", character_id)
    local xp_curve_promise = progression_interface:get_xp_table("character")

    Promise.all(progression_promise, xp_curve_promise):next(function(results)
        if self._destroyed or self._fetching_character_id ~= character_id then
            return
        end

        local progression, xp_curve = unpack(results)
        local level, progress, current_xp_in_level, xp_per_level

        if progression and xp_curve then
            level, progress, current_xp_in_level, xp_per_level = calculate_level_and_progress(progression, xp_curve)
        end

        self._fetching_character_id = nil
        self._character_id = character_id
        self._has_progression = level ~= nil

        if level then
            self._widgets_by_name.level.content.text = tostring(level)
            self._widgets_by_name.experience.content.progress = progress
            self._widgets_by_name.experience.content.xp_text = format_xp_text(current_xp_in_level, xp_per_level)
            self._widgets_by_name.next_level.content.text = tostring(level + 1)
        end
    end):catch(function()
        if not self._destroyed and self._fetching_character_id == character_id then
            self._fetching_character_id = nil
            self._character_id = character_id
            self._has_progression = false
        end
    end)
end

HudElementMissionRewardsXpBar.update = function(self, dt, t, ui_renderer, render_settings, input_service)
    HudElementMissionRewardsXpBar.super.update(self, dt, t, ui_renderer, render_settings, input_service)

    local enabled = mod._show_hub_xp_bar and is_in_hub()
    local player_manager = Managers.player
    local player = enabled and player_manager and player_manager:local_player_safe(1)
    local character_id = player and player:character_id()

    if character_id and character_id ~= self._character_id and character_id ~= self._fetching_character_id then
        self._has_progression = false
        self:_fetch_progression(character_id)
    end

    local visible = enabled and character_id ~= nil and self._has_progression

    self._widgets_by_name.level.content.visible = visible
    self._widgets_by_name.experience.content.visible = visible
    self._widgets_by_name.next_level.content.visible = visible
end

HudElementMissionRewardsXpBar.destroy = function(self, ui_renderer)
    self._destroyed = true

    HudElementMissionRewardsXpBar.super.destroy(self, ui_renderer)
end

return HudElementMissionRewardsXpBar
