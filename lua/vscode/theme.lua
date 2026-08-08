local M = {}

local function color(group, field, fallback)
  local highlight = vim.api.nvim_get_hl(0, { name = group, link = false })
  local value = highlight[field]
  if type(value) == "number" then
    return string.format("#%06x", value)
  end
  return fallback
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

function M.apply()
  local palette = M.palette()

  vim.api.nvim_set_hl(0, "VSCodeActivityBar", { fg = palette.muted, bg = palette.background })
  vim.api.nvim_set_hl(0, "VSCodeActivityHover", { fg = palette.foreground, bg = palette.hover })
  vim.api.nvim_set_hl(0, "VSCodeActivitySelected", { fg = palette.foreground, bg = palette.background, bold = true })
  vim.api.nvim_set_hl(0, "VSCodeActivityAccent", { fg = palette.accent, bg = palette.background })
  vim.api.nvim_set_hl(0, "VSCodePanelToggle", { fg = palette.muted, bg = palette.background })

  vim.api.nvim_set_hl(0, "vimscodeSettings", { fg = palette.foreground, bg = palette.panel })
  vim.api.nvim_set_hl(0, "vimscodeSettingsBorder", { fg = palette.border, bg = palette.panel })
  vim.api.nvim_set_hl(0, "vimscodeSettingsCursor", { bg = palette.hover })
  vim.api.nvim_set_hl(0, "vimscodeSettingsHeading", { fg = palette.title, bold = true })
  vim.api.nvim_set_hl(0, "vimscodeSetting", { fg = palette.accent })
end

function M.use_terminal()
  vim.cmd("colorscheme default")
  M.apply()
end

function M.name()
  local name = vim.g.colors_name
  return name and name ~= "default" and name or "Terminal"
end

function M.setup()
  M.apply()
  local group = vim.api.nvim_create_augroup("vimscode_theme", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = M.apply,
  })
end

return M
