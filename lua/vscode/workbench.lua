local M = {}
local settings_ns = vim.api.nvim_create_namespace("nvicode_settings")

local settings = {
  buf = nil,
  win = nil,
  origin_win = nil,
  query = "",
  actions = {},
}

local function valid_win(win)
  return win and vim.api.nvim_win_is_valid(win)
end

local function editor_window()
  local current = vim.api.nvim_get_current_win()
  if vim.bo[vim.api.nvim_win_get_buf(current)].filetype ~= "nvicode_activity" then
    return current
  end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local filetype = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
    if filetype ~= "nvicode_activity" and vim.api.nvim_win_get_config(win).relative == "" then
      return win
    end
  end
  return current
end

local function edit_config(file)
  vim.cmd.edit(vim.fs.joinpath(vim.fn.stdpath("config"), file))
end

local function close_settings()
  if valid_win(settings.win) then
    vim.api.nvim_win_close(settings.win, true)
  end
  settings.win = nil
end

function M.themes()
  Snacks.picker.colorschemes({ layout = { preset = "vscode" } })
end

function M.extensions()
  require("vscode.sidebar").open_extensions()
end

local function settings_entries()
  local origin = valid_win(settings.origin_win) and settings.origin_win or nil
  local wrap = origin and vim.api.nvim_get_option_value("wrap", { win = origin }) or vim.o.wrap
  local columns = origin and vim.api.nvim_get_option_value("colorcolumn", { win = origin }) or ""

  return {
    { section = "Commonly Used" },
    {
      label = "Color Theme",
      description = "Choose the colors used throughout the NVICode workbench.",
      value = vim.g.colors_name or "vscode",
      close = true,
      action = M.themes,
    },
    {
      label = "Editor: Word Wrap",
      description = "Control how long lines wrap inside the editor.",
      value = wrap and "on" or "off",
      action = function()
        if origin then
          vim.api.nvim_set_option_value("wrap", not wrap, { win = origin })
        end
      end,
    },
    {
      label = "Editor: Color Columns",
      description = "Show editor guides at columns 80 and 120.",
      value = columns == "" and "off" or "80, 120",
      action = function()
        if origin then
          vim.api.nvim_set_option_value("colorcolumn", columns == "" and "80,120" or "", { win = origin })
        end
      end,
    },
    { section = "Workbench" },
    {
      label = "Extensions",
      description = "Search, inspect, and install NVICode extensions.",
      value = "Open",
      close = true,
      action = M.extensions,
    },
    {
      label = "Keyboard Shortcuts",
      description = "Browse all currently registered keyboard shortcuts.",
      value = "Open",
      close = true,
      action = function()
        Snacks.picker.keymaps()
      end,
    },
    {
      label = "Language Servers",
      description = "Install and manage language tooling with Mason.",
      value = "Open",
      close = true,
      action = function()
        vim.cmd.Mason()
      end,
    },
    { section = "Configuration" },
    {
      label = "Open User Settings",
      description = "Edit NVICode editor options.",
      value = "Lua",
      close = true,
      action = function()
        edit_config("lua/config/options.lua")
      end,
    },
    {
      label = "Open Keyboard Shortcuts",
      description = "Edit NVICode keybindings.",
      value = "Lua",
      close = true,
      action = function()
        edit_config("lua/config/keymaps.lua")
      end,
    },
    {
      label = "Open Extensions Configuration",
      description = "Edit the native vim.pack extension registry.",
      value = "Lua",
      close = true,
      action = function()
        edit_config("lua/config/plugins.lua")
      end,
    },
  }
end

local function setting_line(label, value, width)
  local left = "    " .. label
  local right = value and ("[ " .. value .. " ]") or ""
  local spaces = math.max(width - vim.fn.strdisplaywidth(left) - vim.fn.strdisplaywidth(right) - 2, 1)
  return left .. string.rep(" ", spaces) .. right
end

local function render_settings()
  if not settings.buf or not vim.api.nvim_buf_is_valid(settings.buf) then
    return
  end

  local width = valid_win(settings.win) and vim.api.nvim_win_get_width(settings.win) or 90
  local query = settings.query:lower()
  local lines = {
    "  Settings",
    "",
    "    " .. (settings.query ~= "" and settings.query or "Search settings (press /)"),
    "",
  }
  settings.actions = {}

  for _, entry in ipairs(settings_entries()) do
    if entry.section then
      lines[#lines + 1] = "  " .. entry.section
      lines[#lines + 1] = ""
    elseif query == "" or (entry.label .. " " .. entry.description):lower():find(query, 1, true) then
      lines[#lines + 1] = setting_line(entry.label, entry.value, width)
      settings.actions[#lines] = entry
      lines[#lines + 1] = "      " .. entry.description
      lines[#lines + 1] = ""
    end
  end

  vim.bo[settings.buf].modifiable = true
  vim.api.nvim_buf_set_lines(settings.buf, 0, -1, false, lines)
  vim.bo[settings.buf].modifiable = false
  vim.api.nvim_buf_clear_namespace(settings.buf, settings_ns, 0, -1)

  for line, _ in pairs(settings.actions) do
    vim.api.nvim_buf_add_highlight(settings.buf, settings_ns, "NVICodeSetting", line - 1, 0, -1)
  end
  for line, text in ipairs(lines) do
    if text:match("^  [A-Z].*$") and not settings.actions[line] then
      vim.api.nvim_buf_add_highlight(settings.buf, settings_ns, "NVICodeSettingsHeading", line - 1, 0, -1)
    end
  end
end

local function activate_setting()
  local entry = settings.actions[vim.api.nvim_win_get_cursor(0)[1]]
  if not entry then
    return
  end
  if entry.close then
    close_settings()
  end
  entry.action()
  if not entry.close then
    render_settings()
  end
end

local function search_settings()
  vim.ui.input({ prompt = "Search Settings: ", default = settings.query }, function(value)
    if value ~= nil then
      settings.query = value
      render_settings()
    end
  end)
end

function M.settings()
  pcall(function()
    require("integrations.store").close()
  end)
  if valid_win(settings.win) then
    vim.api.nvim_set_current_win(settings.win)
    return settings.win
  end

  settings.origin_win = editor_window()
  if not settings.buf or not vim.api.nvim_buf_is_valid(settings.buf) then
    settings.buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(settings.buf, "nvicode://settings")
    vim.bo[settings.buf].bufhidden = "hide"
    vim.bo[settings.buf].buftype = "nofile"
    vim.bo[settings.buf].filetype = "nvicode_settings"
    vim.bo[settings.buf].swapfile = false

    vim.keymap.set("n", "<CR>", activate_setting, { buffer = settings.buf, silent = true })
    vim.keymap.set("n", "<Space>", activate_setting, { buffer = settings.buf, silent = true })
    vim.keymap.set("n", "/", search_settings, { buffer = settings.buf, silent = true })
    vim.keymap.set("n", "q", close_settings, { buffer = settings.buf, silent = true })
    vim.keymap.set("n", "<Esc>", close_settings, { buffer = settings.buf, silent = true })
    vim.keymap.set("n", "<LeftRelease>", function()
      vim.schedule(activate_setting)
    end, { buffer = settings.buf, silent = true })
  end

  local width = math.min(math.max(vim.o.columns - 8, 60), 104)
  local height = math.min(math.max(vim.o.lines - 8, 20), 34)
  settings.win = vim.api.nvim_open_win(settings.buf, true, {
    relative = "editor",
    row = math.max(math.floor((vim.o.lines - height) / 2) - 1, 0),
    col = math.max(math.floor((vim.o.columns - width) / 2), 0),
    width = width,
    height = height,
    style = "minimal",
    border = "single",
    title = " Settings ",
    title_pos = "left",
    footer = " Enter: Change   /: Search   Esc: Close ",
    footer_pos = "right",
  })

  vim.wo[settings.win].cursorline = true
  vim.wo[settings.win].number = false
  vim.wo[settings.win].relativenumber = false
  vim.wo[settings.win].signcolumn = "no"
  vim.wo[settings.win].wrap = false
  vim.wo[settings.win].winhighlight = "Normal:NVICodeSettings,FloatBorder:NVICodeSettingsBorder,CursorLine:NVICodeSettingsCursor"
  render_settings()

  local first
  for line, _ in pairs(settings.actions) do
    first = not first and line or math.min(first, line)
  end
  if first then
    vim.api.nvim_win_set_cursor(settings.win, { first, 0 })
  end
  return settings.win
end

function M.setup()
  vim.api.nvim_set_hl(0, "NVICodeSettings", { fg = "#cccccc", bg = "#1e1e1e" })
  vim.api.nvim_set_hl(0, "NVICodeSettingsBorder", { fg = "#454545", bg = "#1e1e1e" })
  vim.api.nvim_set_hl(0, "NVICodeSettingsCursor", { bg = "#2a2d2e" })
  vim.api.nvim_set_hl(0, "NVICodeSettingsHeading", { fg = "#ffffff", bold = true })
  vim.api.nvim_set_hl(0, "NVICodeSetting", { fg = "#9cdcfe" })

  vim.api.nvim_create_user_command("Themes", M.themes, { desc = "Browse installed color themes" })
  vim.api.nvim_create_user_command("Extensions", M.extensions, { desc = "Browse configured extensions" })
  vim.api.nvim_create_user_command("Settings", M.settings, { desc = "Open NVICode settings" })
end

return M
