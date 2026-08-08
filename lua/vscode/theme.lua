local M = {}
local terminal_palette

local function color(group, field, fallback)
  local highlight = vim.api.nvim_get_hl(0, { name = group, link = false })
  local value = highlight[field]
  if type(value) == "number" then
    return string.format("#%06x", value)
  end
  return fallback
end

local function blend(background, foreground, amount)
  local br, bg, bb = background:match("^#(%x%x)(%x%x)(%x%x)$")
  local fr, fg, fb = foreground:match("^#(%x%x)(%x%x)(%x%x)$")
  if not br or not fr then
    return
  end

  local function mix(a, b)
    return math.floor(tonumber(a, 16) * (1 - amount) + tonumber(b, 16) * amount + 0.5)
  end
  return string.format("#%02x%02x%02x", mix(br, fr), mix(bg, fg), mix(bb, fb))
end

function M.palette()
  local background = color("Normal", "bg", "bg")
  local foreground = color("Normal", "fg", "fg")
  local muted = color("Comment", "fg", foreground)
  local accent = color("Identifier", "fg", color("Function", "fg", foreground))

  return {
    accent = accent,
    background = background,
    border = color("FloatBorder", "fg", muted),
    foreground = foreground,
    hover = color("CursorLine", "bg", background),
    muted = muted,
    panel = color("NormalFloat", "bg", background),
    title = color("Title", "fg", accent),
  }
end

local function query_kitty_palette()
  if vim.fn.executable("kitty") ~= 1 then
    return
  end
  if vim.env.TERM ~= "xterm-kitty" and not vim.env.KITTY_WINDOW_ID and not vim.env.KITTY_LISTEN_ON then
    return
  end

  local result = vim.system({ "kitty", "@", "get-colors" }, { text = true }):wait(250)
  if result.code ~= 0 then
    return
  end

  local colors = {}
  for name, value in result.stdout:gmatch("([%a_]+)%s+(#%x%x%x%x%x%x)") do
    colors[name] = value:lower()
  end
  if colors.background and colors.foreground then
    return colors
  end
end

local function terminal_active()
  return vim.g.colors_name == "default" and terminal_palette ~= nil
end

local function apply_terminal_palette()
  if not terminal_active() then
    return
  end

  local colors = terminal_palette
  vim.api.nvim_set_hl(0, "Normal", { fg = colors.foreground, bg = colors.background })
  vim.api.nvim_set_hl(0, "NormalNC", { fg = colors.foreground, bg = colors.background })
  vim.api.nvim_set_hl(0, "NormalFloat", { fg = colors.foreground, bg = colors.background })
  vim.api.nvim_set_hl(0, "FloatBorder", { fg = colors.foreground, bg = colors.background })
  vim.api.nvim_set_hl(0, "StatusLine", { fg = colors.foreground, bg = colors.background })
  vim.api.nvim_set_hl(0, "StatusLineNC", { fg = colors.foreground, bg = colors.background })
  vim.api.nvim_set_hl(0, "EndOfBuffer", { fg = colors.background, bg = colors.background })
end

function M.apply()
  apply_terminal_palette()
  local palette = M.palette()

  vim.api.nvim_set_hl(0, "VSCodeActivityBar", { fg = palette.muted, bg = palette.background })
  vim.api.nvim_set_hl(0, "VSCodeActivityHover", { fg = palette.foreground, bg = palette.hover })
  vim.api.nvim_set_hl(0, "VSCodeActivitySelected", { fg = palette.foreground, bg = palette.background, bold = true })
  vim.api.nvim_set_hl(0, "VSCodeActivityAccent", { fg = palette.accent, bg = palette.background })
  vim.api.nvim_set_hl(0, "VSCodePanelToggle", { fg = palette.muted, bg = palette.background })
  vim.api.nvim_set_hl(0, "VSCodeSourceControlButton", {
    fg = palette.background,
    bg = palette.accent,
    bold = true,
  })

  -- Explorer folder labels should use the same foreground as the active editor theme.
  vim.api.nvim_set_hl(0, "SnacksPickerDirectory", { fg = palette.foreground })
  vim.api.nvim_set_hl(0, "SnacksPickerDir", { fg = palette.foreground })
  vim.api.nvim_set_hl(0, "SnacksPickerListCursorLine", {
    fg = palette.foreground,
    bg = blend(palette.background, palette.foreground, 0.14) or palette.hover,
  })

  vim.api.nvim_set_hl(0, "vimscodeSettings", { fg = palette.foreground, bg = palette.panel })
  vim.api.nvim_set_hl(0, "vimscodeSettingsBorder", { fg = palette.border, bg = palette.panel })
  vim.api.nvim_set_hl(0, "vimscodeSettingsCursor", { bg = palette.hover })
  vim.api.nvim_set_hl(0, "vimscodeSettingsHeading", { fg = palette.title, bold = true })
  vim.api.nvim_set_hl(0, "vimscodeSetting", { fg = palette.accent })
end

function M.use_terminal()
  terminal_palette = query_kitty_palette()
  vim.cmd("colorscheme default")
  M.apply()
end

function M.refresh_terminal()
  if vim.g.colors_name ~= "default" then
    return
  end
  terminal_palette = query_kitty_palette() or terminal_palette
  M.apply()
end

function M.name()
  local name = vim.g.colors_name
  return name and name ~= "default" and name or "Terminal"
end

function M.setup()
  local group = vim.api.nvim_create_augroup("vimscode_theme", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = function()
      if vim.g.colors_name == "default" then
        if terminal_palette then
          M.apply()
        else
          M.refresh_terminal()
        end
      else
        terminal_palette = nil
        M.apply()
      end
    end,
  })
  vim.api.nvim_create_autocmd("FocusGained", {
    group = group,
    callback = M.refresh_terminal,
  })
  M.use_terminal()
end

return M
