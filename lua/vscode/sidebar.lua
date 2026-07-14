local M = {}

local rail_width = 4
local panel_width = 38
local namespace = vim.api.nvim_create_namespace("vscode_activity_bar")
local state = { active = "explorer", windows = {}, actions = {} }

local views = {
  { id = "explorer", icon = "󰉋", label = "Explorer" },
  { id = "search", icon = "󰍉", label = "Search" },
  { id = "source_control", icon = "󰊢", label = "Source Control" },
  { id = "debug", icon = "󰃤", label = "Run and Debug" },
  { id = "extensions", icon = "󰏗", label = "Extensions" },
}

local picker_sources = { "explorer", "grep", "git_status", "lazy" }

local function valid_win(win)
  return win and vim.api.nvim_win_is_valid(win)
end

local function tab_key()
  return tostring(vim.api.nvim_get_current_tabpage())
end

local function panel_layout()
  return {
    preset = "sidebar",
    preview = false,
    layout = { position = "left", width = panel_width },
  }
end

local function close_pickers(except)
  for _, source in ipairs(picker_sources) do
    if source ~= except then
      for _, picker in ipairs(Snacks.picker.get({ source = source, tab = false })) do
        picker:close()
      end
    end
  end
end

local function current_picker()
  for _, source in ipairs(picker_sources) do
    local picker = Snacks.picker.get({ source = source, tab = false })[1]
    if picker then
      return picker
    end
  end
end

local function set_win_options(win)
  local options = {
    cursorcolumn = false,
    cursorline = true,
    foldcolumn = "0",
    list = false,
    number = false,
    relativenumber = false,
    signcolumn = "no",
    spell = false,
    winfixwidth = true,
    wrap = false,
  }
  for name, value in pairs(options) do
    vim.api.nvim_set_option_value(name, value, { win = win })
  end
  vim.api.nvim_set_option_value(
    "winhighlight",
    "Normal:VSCodeActivityBar,NormalNC:VSCodeActivityBar,CursorLine:VSCodeActivityHover,EndOfBuffer:VSCodeActivityBar",
    { win = win }
  )
end

local function render(win)
  if not valid_win(win) then
    return
  end

  local buf = vim.api.nvim_win_get_buf(win)
  local height = math.max(vim.api.nvim_win_get_height(win), 12)
  local lines = {}
  for _ = 1, height do
    lines[#lines + 1] = ""
  end

  local actions = {}
  for index, view in ipairs(views) do
    local line = index * 2
    lines[line] = " " .. view.icon
    actions[line] = view.id
  end
  local settings_line = math.max(height - 1, 12)
  lines[settings_line] = " "
  actions[settings_line] = "settings"

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  state.actions[buf] = actions
  vim.api.nvim_buf_clear_namespace(buf, namespace, 0, -1)

  for line, id in pairs(actions) do
    if id == state.active then
      vim.api.nvim_buf_set_extmark(buf, namespace, line - 1, 0, {
        hl_group = "VSCodeActivitySelected",
        hl_eol = true,
        virt_text = { { "▎", "VSCodeActivityAccent" } },
        virt_text_pos = "overlay",
      })
    end
  end
end

local function activate_at_cursor()
  local buf = vim.api.nvim_get_current_buf()
  local actions = state.actions[buf] or {}
  local id = actions[vim.api.nvim_win_get_cursor(0)[1]]
  if id and M["open_" .. id] then
    M["open_" .. id]()
  end
end

function M.ensure()
  if #vim.api.nvim_list_uis() == 0 then
    return
  end

  local key = tab_key()
  local win = state.windows[key]
  local previous = vim.api.nvim_get_current_win()

  if not valid_win(win) then
    vim.cmd("topleft " .. rail_width .. "vnew")
    win = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_get_current_buf()
    state.windows[key] = win

    vim.api.nvim_buf_set_name(buf, "vscode://activity-bar/" .. key)
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].filetype = "vscode_activity"
    vim.bo[buf].swapfile = false
    vim.bo[buf].undofile = false

    vim.keymap.set("n", "<CR>", activate_at_cursor, { buffer = buf, silent = true })
    vim.keymap.set("n", "<Space>", activate_at_cursor, { buffer = buf, silent = true })
    vim.keymap.set("n", "<LeftRelease>", function()
      vim.schedule(activate_at_cursor)
    end, { buffer = buf, silent = true })
  else
    vim.api.nvim_set_current_win(win)
  end

  -- Snacks sidebars are splits too; always lift the rail out of their layout
  -- tree so it remains the absolute leftmost VS Code activity column.
  vim.api.nvim_set_current_win(win)
  vim.cmd.wincmd("H")
  vim.api.nvim_win_set_width(win, rail_width)
  set_win_options(win)
  render(win)

  if valid_win(previous) and previous ~= win then
    vim.api.nvim_set_current_win(previous)
  end
end

function M.set_active(id)
  state.active = id
  for _, win in pairs(state.windows) do
    render(win)
  end
end

local function finish_open(id, picker, focus)
  M.set_active(id)
  vim.schedule(function()
    M.ensure()
    if picker and not picker.closed then
      picker:focus(focus)
    end
  end)
  -- Snacks finalizes its sidebar split asynchronously. Re-assert the outer
  -- workbench order once that layout pass has completed.
  vim.defer_fn(M.ensure, 30)
  return picker
end

function M.open_explorer()
  close_pickers("explorer")
  local picker = Snacks.picker.get({ source = "explorer", tab = false })[1] or Snacks.explorer()
  return finish_open("explorer", picker, "list")
end

function M.open_search()
  close_pickers("grep")
  local picker = Snacks.picker.get({ source = "grep", tab = false })[1]
    or Snacks.picker.grep({ auto_close = false, layout = panel_layout() })
  return finish_open("search", picker, "input")
end

function M.open_source_control()
  close_pickers("git_status")
  local picker = Snacks.picker.get({ source = "git_status", tab = false })[1]
    or Snacks.picker.git_status({ auto_close = false, layout = panel_layout() })
  return finish_open("source_control", picker, "list")
end

function M.open_debug()
  close_pickers()
  require("dapui").open()
  M.set_active("debug")
  vim.schedule(M.ensure)
end

function M.open_extensions()
  close_pickers("lazy")
  local picker = Snacks.picker.get({ source = "lazy", tab = false })[1]
    or Snacks.picker.lazy({ auto_close = false, layout = panel_layout() })
  return finish_open("extensions", picker, "input")
end

function M.open_settings()
  M.set_active("settings")
  require("vscode.workbench").settings()
end

function M.toggle_panel()
  local picker = current_picker()
  if picker then
    picker:close()
    M.set_active(nil)
    M.ensure()
  else
    M.open_explorer()
  end
end

function M.focus_activity_bar()
  M.ensure()
  local win = state.windows[tab_key()]
  if valid_win(win) then
    vim.api.nvim_set_current_win(win)
  end
end

function M.setup()
  vim.api.nvim_set_hl(0, "VSCodeActivityBar", { fg = "#858585", bg = "#181818" })
  vim.api.nvim_set_hl(0, "VSCodeActivityHover", { fg = "#ffffff", bg = "#2a2d2e" })
  vim.api.nvim_set_hl(0, "VSCodeActivitySelected", { fg = "#ffffff", bg = "#181818", bold = true })
  vim.api.nvim_set_hl(0, "VSCodeActivityAccent", { fg = "#007acc", bg = "#181818" })

  local group = vim.api.nvim_create_augroup("vscode_activity_bar", { clear = true })
  vim.api.nvim_create_autocmd({ "WinResized", "ColorScheme" }, {
    group = group,
    callback = function()
      if vim.v.event and vim.v.event.windows then
        for _, win in ipairs(vim.v.event.windows) do
          if valid_win(win) and vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "vscode_activity" then
            render(win)
          end
        end
      else
        vim.api.nvim_set_hl(0, "VSCodeActivityBar", { fg = "#858585", bg = "#181818" })
        vim.api.nvim_set_hl(0, "VSCodeActivityHover", { fg = "#ffffff", bg = "#2a2d2e" })
        vim.api.nvim_set_hl(0, "VSCodeActivitySelected", { fg = "#ffffff", bg = "#181818", bold = true })
        vim.api.nvim_set_hl(0, "VSCodeActivityAccent", { fg = "#007acc", bg = "#181818" })
      end
    end,
  })

  vim.api.nvim_create_user_command("ActivityBar", M.focus_activity_bar, { desc = "Focus the VS Code activity bar" })
  vim.api.nvim_create_user_command("Explorer", M.open_explorer, { desc = "Open the Explorer side bar" })
end

return M
