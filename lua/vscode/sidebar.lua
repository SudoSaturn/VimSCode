local M = {}

local rail_width = 4
local panel_width = 38
local namespace = vim.api.nvim_create_namespace("nvicode_activity_bar")
local state = { active = "explorer", windows = {}, actions = {}, opening = {} }

local views = {
  { id = "explorer", icon = "󰉋", label = "Explorer" },
  { id = "search", icon = "󰍉", label = "Search" },
  { id = "source_control", icon = "󰊢", label = "Source Control" },
  { id = "extensions", icon = "󰏗", label = "Extensions" },
}

local picker_sources = { "explorer", "grep", "git_status" }

local function refresh_tabline()
  vim.schedule(function()
    vim.cmd("redrawtabline")
  end)
end

local function valid_win(win)
  return win and vim.api.nvim_win_is_valid(win)
end

local function editor_win(win)
  local config = vim.api.nvim_win_get_config(win)
  return config.relative == "" and vim.bo[vim.api.nvim_win_get_buf(win)].buftype == ""
end

local function terminal_parent_win()
  local current = vim.api.nvim_get_current_win()
  if editor_win(current) then
    return current
  end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if editor_win(win) then
      return win
    end
  end
  return current
end

local function tab_key()
  return tostring(vim.api.nvim_get_current_tabpage())
end

local function panel_layout()
  return {
    preview = false,
    on_close = refresh_tabline,
    layout = {
      position = "left",
      width = panel_width,
      box = "vertical",
      { win = "input", height = 1, border = "none" },
      { win = "list", border = "none" },
      { win = "preview", title = "{preview}", height = 0.4, border = "top" },
    },
  }
end

local function git_root()
  local paths = { vim.fn.getcwd() }
  local buffer_name = vim.api.nvim_buf_get_name(0)
  if buffer_name ~= "" and not buffer_name:match("^%w+://") then
    table.insert(paths, 1, vim.fs.dirname(buffer_name))
  end

  for _, path in ipairs(paths) do
    local root = vim.fs.root(path, { ".git" })
    if root then
      return root
    end
  end
end

local function initialize_repository(picker)
  local workspace = vim.fn.getcwd()
  local result = vim.system({ "git", "-C", workspace, "init" }, { text = true }):wait(2000)
  if result.code ~= 0 then
    local message = result.stderr and result.stderr ~= "" and result.stderr or "Unable to initialize repository"
    vim.notify(message, vim.log.levels.ERROR, {
      title = "Source Control",
    })
    return
  end

  picker:close()
  vim.defer_fn(M.open_source_control, 220)
end

local function empty_source_control_picker()
  return Snacks.picker({
    source = "git_status",
    title = "Source Control",
    auto_close = false,
    layout = panel_layout(),
    finder = function()
      return {
        { text = "No repostry found", hl = "Title" },
        { spacer = true },
        { text = "Initialize Repostry", button = true },
      }
    end,
    format = function(item)
      if item.spacer then
        return { { " " } }
      end
      if item.button then
        return {
          {
            "",
            resolve = function(width)
              local label = "   " .. item.text .. "   "
              local padding = math.max(math.floor((width - vim.fn.strdisplaywidth(label)) / 2), 0)
              return {
                { string.rep(" ", padding) },
                { label, "VSCodeSourceControlButton" },
              }
            end,
          },
        }
      end
      return { { item.text, item.hl } }
    end,
    confirm = function(picker, item)
      if item.button then
        initialize_repository(picker)
      end
    end,
  })
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

local function existing_picker(source)
  local pickers = Snacks.picker.get({ source = source, tab = false })
  for index = 2, #pickers do
    pickers[index]:close()
  end
  return pickers[1]
end

local function begin_open(id)
  if state.opening[id] then
    return false
  end
  state.opening[id] = true
  vim.defer_fn(function()
    state.opening[id] = nil
  end, 200)
  return true
end

local function close_extensions()
  local ok, store = pcall(require, "integrations.store")
  return ok and store.close()
end

local function current_picker()
  for _, source in ipairs(picker_sources) do
    local picker = Snacks.picker.get({ source = source, tab = false })[1]
    if picker then
      return picker
    end
  end
end

local function hide_picker_flags(picker)
  local input = picker and picker.layout and picker.layout.wins and picker.layout.wins.input
  if input then
    input.meta.title_tpl = "{title}"
    picker:update_titles()
  end
end

local function set_win_options(win)
  local options = {
    cursorcolumn = false,
    cursorline = false,
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
    "Normal:VSCodeActivityBar,NormalNC:VSCodeActivityBar,EndOfBuffer:VSCodeActivityBar",
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
    local line = index * 2 - 1
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

    vim.api.nvim_buf_set_name(buf, "nvicode://activity-bar/" .. key)
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].filetype = "nvicode_activity"
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
  local label = ""
  local icon = ""
  for _, view in ipairs(views) do
    if view.id == id then
      label = view.label
      icon = view.icon
      break
    end
  end
  vim.g.nvicode_sidebar_title = label
  vim.g.nvicode_sidebar_icon = icon
  for _, win in pairs(state.windows) do
    render(win)
  end
  refresh_tabline()
end

local function finish_open(id, picker, focus)
  hide_picker_flags(picker)
  refresh_tabline()
  M.set_active(id)
  vim.schedule(function()
    M.ensure()
    if picker and not picker.closed then
      picker:focus(focus)
    end
  end)
  vim.defer_fn(M.ensure, 30)
  return picker
end

function M.open_explorer()
  if not begin_open("explorer") then
    return
  end
  close_extensions()
  close_pickers("explorer")
  local picker = existing_picker("explorer") or Snacks.explorer()
  return finish_open("explorer", picker, "list")
end

function M.open_search()
  if not begin_open("search") then
    return
  end
  close_extensions()
  close_pickers("grep")
  local picker = existing_picker("grep") or Snacks.picker.grep({ auto_close = false, layout = panel_layout() })
  return finish_open("search", picker, "input")
end

function M.open_source_control()
  if not begin_open("source_control") then
    return
  end
  local root = git_root()
  close_extensions()
  close_pickers("git_status")
  if not root then
    local picker = existing_picker("git_status") or empty_source_control_picker()
    return finish_open("source_control", picker, "list")
  end
  local picker = existing_picker("git_status")
    or Snacks.picker.git_status({ auto_close = false, cwd = root, layout = panel_layout() })
  return finish_open("source_control", picker, "list")
end

function M.open_extensions()
  if not begin_open("extensions") then
    return
  end
  close_pickers()
  M.set_active("extensions")
  require("integrations.store").open()
end

function M.open_settings()
  if not begin_open("settings") then
    return
  end
  close_extensions()
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

function M.close_panel()
  local picker = current_picker()
  if picker then
    picker:close()
  end
  close_extensions()
  refresh_tabline()
  M.set_active(nil)
  M.ensure()
end

function M.toggle_terminal_panel()
  local terminal = Snacks.terminal.list()[1]
  if terminal then
    return terminal:toggle()
  end
  return Snacks.terminal.toggle(nil, { win = { relative = "win", win = terminal_parent_win() } })
end

function M.focus_activity_bar()
  M.ensure()
  local win = state.windows[tab_key()]
  if valid_win(win) then
    vim.api.nvim_set_current_win(win)
  end
end

function M.setup()
  _G.VimSCodeToggleTerminalPanel = function()
    M.toggle_terminal_panel()
  end

  local group = vim.api.nvim_create_augroup("nvicode_activity_bar", { clear = true })
  vim.api.nvim_create_autocmd({ "WinResized", "ColorScheme" }, {
    group = group,
    callback = function()
      if vim.v.event and vim.v.event.windows then
        for _, win in ipairs(vim.v.event.windows) do
          if valid_win(win) and vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "nvicode_activity" then
            render(win)
          end
        end
      end
    end,
  })
  vim.api.nvim_create_user_command("ActivityBar", M.focus_activity_bar, { desc = "Focus the VS Code activity bar" })
  vim.api.nvim_create_user_command("Explorer", M.open_explorer, { desc = "Open the Explorer side bar" })
end

return M
