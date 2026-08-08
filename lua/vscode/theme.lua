local M = {}
local terminal_palette
local terminal_mode = false
local applying_terminal_scheme = false

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

local function set_background(groups, background)
  for _, group in ipairs(groups) do
    local highlight = vim.api.nvim_get_hl(0, { name = group, link = false })
    if next(highlight) then
      highlight.default = nil
      highlight.bg = background
      vim.api.nvim_set_hl(0, group, highlight)
    end
  end
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
    separator = blend(background, foreground, 0.18) or muted,
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
  return terminal_mode and terminal_palette ~= nil
end

local function terminal_scheme()
  if not terminal_palette then
    return vim.o.background == "light" and "tokyonight-day" or "tokyonight-night"
  end
  local red, green, blue = terminal_palette.background:match("^#(%x%x)(%x%x)(%x%x)$")
  if red then
    local brightness = tonumber(red, 16) * 0.299 + tonumber(green, 16) * 0.587 + tonumber(blue, 16) * 0.114
    if brightness > 127.5 then
      return "tokyonight-day"
    end
  end
  return "tokyonight-night"
end

local function apply_terminal_palette()
  if not terminal_active() then
    return
  end

  local colors = terminal_palette
  for index = 0, 15 do
    local terminal_color = colors["color" .. index]
    if terminal_color then
      vim.g["terminal_color_" .. index] = terminal_color
    end
  end
  vim.api.nvim_set_hl(0, "Normal", { fg = colors.foreground, bg = colors.background })
  vim.api.nvim_set_hl(0, "NormalNC", { fg = colors.foreground, bg = colors.background })
  vim.api.nvim_set_hl(0, "NormalFloat", { fg = colors.foreground, bg = colors.background })
  vim.api.nvim_set_hl(0, "Terminal", { fg = colors.foreground, bg = colors.background })
  vim.api.nvim_set_hl(0, "FloatBorder", { fg = colors.foreground, bg = colors.background })
  local status_tint = blend(colors.background, color("Identifier", "fg", colors.foreground), 0.09) or colors.background
  vim.api.nvim_set_hl(0, "StatusLine", { fg = colors.foreground, bg = status_tint })
  vim.api.nvim_set_hl(0, "StatusLineNC", { fg = colors.foreground, bg = status_tint })
  vim.api.nvim_set_hl(0, "EndOfBuffer", { fg = colors.background, bg = colors.background })
end

function M.apply()
  apply_terminal_palette()
  local palette = M.palette()
  local separator = palette.separator
  local cursorline = blend(palette.background, palette.foreground, 0.04) or palette.background
  local inactive_tab = blend(palette.background, palette.foreground, 0.035) or palette.background

  -- Keep the active editor line visible without making it compete with the code.
  vim.api.nvim_set_hl(0, "CursorLine", { bg = cursorline })
  vim.api.nvim_set_hl(0, "VSCodeActivityBar", { fg = palette.muted, bg = palette.background })
  vim.api.nvim_set_hl(0, "VSCodeActivityHover", { fg = palette.foreground, bg = palette.hover })
  vim.api.nvim_set_hl(0, "VSCodeActivitySelected", { fg = palette.muted, bg = palette.background })
  vim.api.nvim_set_hl(0, "VSCodeActivityAccent", { fg = palette.accent, bg = palette.background })
  vim.api.nvim_set_hl(0, "VSCodePanelToggle", { fg = palette.muted })
  vim.api.nvim_set_hl(0, "VSCodeSourceControlButton", {
    fg = palette.background,
    bg = palette.accent,
    bold = true,
  })
  vim.api.nvim_set_hl(0, "VSCodeExtensionsSeparator", { fg = palette.separator, bg = palette.background })
  vim.api.nvim_set_hl(0, "WinSeparator", { fg = separator, bg = palette.background })
  vim.api.nvim_set_hl(0, "VertSplit", { fg = separator, bg = palette.background })
  vim.api.nvim_set_hl(0, "SnacksWinSeparator", { fg = separator, bg = palette.background })
  vim.api.nvim_set_hl(0, "TabLine", { fg = palette.muted, bg = palette.background })
  vim.api.nvim_set_hl(0, "TabLineFill", { bg = palette.background })
  vim.api.nvim_set_hl(0, "BufferLineFill", { bg = palette.background })
  vim.api.nvim_set_hl(0, "BufferLineBackground", { fg = palette.muted, bg = palette.background })
  vim.api.nvim_set_hl(0, "BufferLineSeparator", { fg = palette.background, bg = palette.background })
  vim.api.nvim_set_hl(0, "BufferLineRightCustomAreaText1", { fg = palette.muted, bg = palette.background })
  set_background({
    "BufferLineBackground", "BufferLineBuffer", "BufferLineCloseButton", "BufferLineModified",
    "BufferLineDuplicate", "BufferLineNumbers", "BufferLineDiagnostic", "BufferLineError",
    "BufferLineWarning", "BufferLineInfo", "BufferLineHint", "BufferLineErrorDiagnostic",
    "BufferLineWarningDiagnostic", "BufferLineInfoDiagnostic", "BufferLineHintDiagnostic",
    "BufferLinePick", "BufferLineTab", "BufferLineTabClose", "BufferLineTabSeparator",
  }, inactive_tab)

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
  terminal_mode = true
  local ok, tokyonight = pcall(require, "tokyonight")
  if ok then
    tokyonight.setup({
      transparent = terminal_palette ~= nil,
      styles = {
        floats = terminal_palette and "transparent" or "dark",
        sidebars = terminal_palette and "transparent" or "dark",
      },
    })
  end
  applying_terminal_scheme = true
  vim.cmd("colorscheme " .. terminal_scheme())
  applying_terminal_scheme = false
  M.apply()
end

function M.refresh_terminal()
  if not terminal_mode then
    return
  end
  terminal_palette = query_kitty_palette() or terminal_palette
  M.use_terminal()
end

function M.name()
  if terminal_mode then
    return "Terminal"
  end
  local name = vim.g.colors_name
  return name or "Terminal"
end

function M.setup()
  local group = vim.api.nvim_create_augroup("vimscode_theme", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = function()
      if not applying_terminal_scheme then
        terminal_mode = false
        terminal_palette = nil
      end
      M.apply()
    end,
  })
  vim.api.nvim_create_autocmd("FocusGained", {
    group = group,
    callback = M.refresh_terminal,
  })
  M.use_terminal()
end

return M
