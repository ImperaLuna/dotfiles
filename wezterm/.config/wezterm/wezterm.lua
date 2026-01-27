local wezterm = require("wezterm")
local constants = require("constants")
local shortcuts = require("shortcuts")
local config = wezterm.config_builder()

config.enable_wayland = false

-- Font settings
config.font_size = 12
config.line_height = 1.1

-- Cursor
config.colors = {
	cursor_bg = "white",
	cursor_border = "white"
}
config.default_cursor_style = "BlinkingBar"

--Apperance
config.window_decorations = "NONE"
config.hide_tab_bar_if_only_one_tab = true

config.window_padding = {
left = 0,
right = 0,
top = 0,
bottom = 0
}

config.window_background_image = constants.bg_image
config.window_background_opacity = 0.85

-- Keybindings
config.keys = shortcuts.keys

-- Misc.
config.max_fps = 120

return config

