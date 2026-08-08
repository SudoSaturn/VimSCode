local M = {}

local panel_width = 38
local header_height = 1

local function valid(win)
  return win and vim.api.nvim_win_is_valid(win)
end

local function editor_window()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    local config = vim.api.nvim_win_get_config(win)
    if config.relative == "" and vim.bo[buf].buftype == "" then
      return win
    end
  end
end

local function activity_window()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "nvicode_activity" then
      return win
    end
  end
end

local function set_window_options(win, options)
  for name, value in pairs(options) do
    vim.api.nvim_set_option_value(name, value, { win = win })
  end
  vim.wo[win].winbar = ""
  vim.wo[win].winhighlight = "WinBar:Normal,WinBarNC:Normal,StatusLine:Normal,StatusLineNC:Normal"
end

local function create_search_buffer()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].buftype = "prompt"
  vim.bo[buf].filetype = "nvicode_extensions_header"
  vim.bo[buf].swapfile = false
  vim.fn.prompt_setprompt(buf, "  > ")
  vim.fn.prompt_setcallback(buf, function()
    require("integrations.store").focus_results()
  end)

  local revision = 0
  vim.api.nvim_buf_attach(buf, false, {
    on_lines = function()
      revision = revision + 1
      local current = revision
      vim.defer_fn(function()
        if current ~= revision or not vim.api.nvim_buf_is_valid(buf) then
          return
        end
        local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or ""
        local prompt = vim.fn.prompt_getprompt(buf)
        local query = vim.startswith(line, prompt) and line:sub(#prompt + 1) or line
        require("integrations.store").set_query(query)
      end, 40)
    end,
  })

  local function focus_results()
    require("integrations.store").focus_results()
  end
  vim.keymap.set({ "n", "i" }, "<Esc>", focus_results, { buffer = buf, silent = true })
  vim.keymap.set("n", "<LeftRelease>", function()
    vim.schedule(function()
      if vim.api.nvim_get_current_buf() == buf then
        vim.cmd.startinsert()
      end
    end)
  end, { buffer = buf, silent = true })
  vim.api.nvim_create_autocmd("WinEnter", {
    buffer = buf,
    callback = function()
      vim.schedule(vim.cmd.startinsert)
    end,
  })
  return buf
end

local Layout = {}
Layout.__index = Layout

function Layout:open(heading, list, preview)
  local editor = editor_window()
  if not valid(editor) then
    return "Extensions requires an editor window"
  end

  self.editor_win = editor
  self.editor_buf = vim.api.nvim_win_get_buf(editor)
  require("vscode.sidebar").ensure()
  local rail = activity_window()
  self.search_buf = create_search_buffer()
  local list_win = vim.api.nvim_open_win(list.state.buf.id, true, {
    split = rail and "right" or "left",
    win = rail or editor,
  })
  vim.api.nvim_win_set_width(list_win, panel_width)
  local header_win = vim.api.nvim_open_win(self.search_buf, false, { split = "above", win = list_win })
  vim.api.nvim_win_set_height(header_win, header_height)

  self.header_win = header_win
  self.list_win = list_win
  self.preview_win = editor

  set_window_options(header_win, {
    cursorline = false,
    foldcolumn = "0",
    list = false,
    number = false,
    relativenumber = false,
    signcolumn = "no",
    winfixheight = true,
    wrap = false,
  })
  set_window_options(list_win, {
    cursorline = true,
    foldcolumn = "0",
    list = false,
    number = false,
    relativenumber = false,
    signcolumn = "no",
    winfixwidth = true,
    wrap = false,
  })
  set_window_options(editor, {
    cursorline = false,
    foldcolumn = "0",
    list = false,
    number = false,
    relativenumber = false,
    signcolumn = "no",
    wrap = false,
  })

  vim.api.nvim_win_set_buf(editor, preview.state.buf.id)
  heading.config.width = vim.api.nvim_win_get_width(header_win)
  vim.wo[header_win].winhighlight = "Normal:SnacksPickerInput,NormalNC:SnacksPickerInput,EndOfBuffer:SnacksPickerInput"

  heading.state.win.id = header_win
  heading.state.win.is_open = true
  list.state.win.id = list_win
  list.state.win.is_open = true
  preview.state.win.id = editor
  preview.state.win.is_open = true

  heading:render(heading.state)
  list:render({ state = "loading" })
  preview:render({ state = "loading" })
  self:update_winbar(list, preview)
  vim.api.nvim_set_current_win(list_win)
end

function Layout:close(heading, list, preview)
  if valid(self.editor_win) and self.editor_buf and vim.api.nvim_buf_is_valid(self.editor_buf) then
    vim.api.nvim_win_set_buf(self.editor_win, self.editor_buf)
  end

  if preview._clear_images then
    preview:_clear_images()
  end
  preview.state.win.id = nil
  preview.state.win.is_open = false
  preview:_buf_destroy()
  heading:close()
  list:close()
  if self.search_buf and vim.api.nvim_buf_is_valid(self.search_buf) then
    vim.api.nvim_buf_delete(self.search_buf, { force = true })
  end

  self.editor_buf = nil
  self.editor_win = nil
  self.header_win = nil
  self.list_win = nil
  self.preview_win = nil
  self.search_buf = nil
end

function Layout:resize(heading)
  if valid(self.header_win) then
    heading.config.width = vim.api.nvim_win_get_width(self.header_win)
    heading:_buf_render()
  end
end

function Layout:resize_content()
end

function Layout:update_winbar()
  if valid(self.list_win) then
    vim.wo[self.list_win].winbar = ""
  end
  if valid(self.preview_win) then
    local label = require("integrations.store").action_label()
    vim.wo[self.preview_win].winbar = "%=%#VSCodeSourceControlButton#%@v:lua.VimSCodeToggleExtension@ " .. label .. " %T "
  end
end

function M.setup()
  local layout = require("store.ui.layout")
  if layout._nvicode_extensions_layout then
    return
  end

  local create = layout.create
  layout.create = function(mode)
    if mode == "tab" then
      return setmetatable({}, Layout)
    end
    return create(mode)
  end
  layout._nvicode_extensions_layout = true
end

return M
