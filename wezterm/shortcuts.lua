local wezterm = require 'wezterm'
local M = {}

M.keys = {
  -- Tabs
  {
    key = 't',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.SpawnTab 'CurrentPaneDomain',
  },
  {
    key = 'w',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.CloseCurrentTab { confirm = true },
  },
  
  -- Panes: Split
  {
    key = '+',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
  },
  {
    key = '_',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
  },
  
  -- Panes: Navigate
  {
    key = 'h',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.ActivatePaneDirection 'Left',
  },
  {
    key = 'l',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.ActivatePaneDirection 'Right',
  },
  {
    key = 'k',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.ActivatePaneDirection 'Up',
  },
  {
    key = 'j',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.ActivatePaneDirection 'Down',
  },
  
  -- Panes: Close
  {
    key = 'x',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.CloseCurrentPane { confirm = true },
  },
  
  -- Font Size adjustment
  {
    key = 'PageUp',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.IncreaseFontSize,
  },
  {
    key = 'PageDown',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.DecreaseFontSize,
  },
  {
    key = 'Delete',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.ResetFontSize,
  },

  -- Reload config
  {
    key = 'r',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.ReloadConfiguration,
  },
}

return M
