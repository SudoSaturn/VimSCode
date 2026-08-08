local M = {}
local current_instance
local chrome_namespace = vim.api.nvim_create_namespace("nvicode_extensions_chrome")

local function normalize_disabled_telemetry()
  local telemetry = require("store.telemetry")
  if telemetry._vimscode_normalized then
    return
  end

  local fetch_stats = telemetry.fetch_stats
  telemetry.fetch_stats = function(period, callback)
    if not require("store.config").get().telemetry then
      callback({ installs = {}, views = {} }, nil)
      return
    end
    fetch_stats(period, callback)
  end
  telemetry._vimscode_normalized = true
end

local function setup_image_support()
  if vim.env.TERM ~= "xterm-kitty" or #vim.api.nvim_list_uis() == 0 then
    return
  end

  local ok, image = pcall(require, "image")
  if not ok then
    return
  end

  image.setup({
    backend = "kitty",
    processor = "magick_cli",
    integrations = {
      -- Store renders README images itself to keep previews aligned with the selected extension.
      markdown = { enabled = false },
    },
    max_width_window_percentage = 90,
    max_height_window_percentage = 45,
  })
end

local function extension_path(repo)
  local name = repo.name:gsub("[^%w%._-]", "-")
  return vim.fs.joinpath(vim.fn.stdpath("config"), "lua", "extensions", name .. ".lua")
end

local function is_installed(instance, repo)
  return instance and repo and (instance.state.installed_items[repo.name] or instance.state.installed_items[repo.full_name])
end

local function is_managed(repo)
  return repo and vim.fn.filereadable(extension_path(repo)) == 1
end

local function filtered_repositories(instance)
  local repos = instance.state.repos or {}
  local query = instance.state.filter_query or ""
  if query ~= "" then
    local filtered = require("store.ui.store_modal.utils").filter(repos, query)
    repos = filtered or {}
  end

  local mode = instance._nvicode_filter or "all"
  if mode == "all" then
    return vim.list_extend({}, repos)
  end

  local result = {}
  for _, repo in ipairs(repos) do
    local installed = is_installed(instance, repo)
    if (mode == "installed" and installed) or (mode == "available" and not installed) then
      result[#result + 1] = repo
    end
  end
  return result
end

local function refresh(instance)
  if not instance or instance.state.is_closing then
    return
  end
  local repos = filtered_repositories(instance)
  instance.state.currently_displayed_repos = repos
  instance.state.total_installed_count = vim.tbl_count(instance.state.installed_items)
  instance.list:_clear_cache()
  instance.list:render({
    state = "ready",
    items = repos,
    installed_items = instance.state.installed_items,
    sort_type = instance.state.sort_config.type,
    download_stats_monthly = instance.state.download_stats_monthly,
    view_stats_monthly = instance.state.view_stats_monthly,
  })
  instance.heading:render({
    state = "ready",
    filtered_count = #repos,
    installed_count = instance.state.total_installed_count,
  })
end

function M.set_filter(mode)
  local instance = current_instance
  if not instance then
    return
  end
  local aliases = { ["not-installed"] = "available", uninstalled = "available" }
  mode = aliases[mode] or mode
  if mode ~= "all" and mode ~= "installed" and mode ~= "available" then
    vim.notify("Unknown extension filter: " .. tostring(mode), vim.log.levels.WARN, { title = "vimscode Extensions" })
    return
  end
  instance._nvicode_filter = mode
  refresh(instance)
end

function M.choose_filter()
  vim.ui.select({
    { label = "All Extensions", mode = "all" },
    { label = "Installed", mode = "installed" },
    { label = "Not Installed", mode = "available" },
  }, {
    prompt = "Filter Extensions",
    format_item = function(item)
      return item.label
    end,
  }, function(item)
    if item then
      M.set_filter(item.mode)
    end
  end)
end

local function execute_extension_file(path)
  local native_add = vim.pack.add
  vim.pack.add = function(specs, opts)
    return native_add(specs, vim.tbl_deep_extend("force", opts or {}, { confirm = false, load = true }))
  end
  local ok, err = pcall(dofile, path)
  vim.pack.add = native_add
  return ok, err
end

function M.toggle_selected()
  local instance = current_instance
  local repo = instance and instance.state.current_repository
  if not repo then
    vim.notify("Select an extension first", vim.log.levels.INFO, { title = "vimscode Extensions" })
    return
  end

  if is_installed(instance, repo) then
    if not is_managed(repo) then
      vim.notify(
        repo.name .. " is bundled with vimscode and cannot be removed from the Extension Store",
        vim.log.levels.INFO,
        { title = "vimscode Extensions" }
      )
      return
    end
    local ok, err = pcall(vim.pack.del, { repo.name }, { force = true })
    if not ok then
      vim.notify("Unable to uninstall " .. repo.name .. ": " .. tostring(err), vim.log.levels.ERROR)
      return
    end
    vim.fn.delete(extension_path(repo))
    instance.state.installed_items[repo.name] = nil
    refresh(instance)
    vim.notify("Uninstalled " .. repo.name, vim.log.levels.INFO, { title = "vimscode Extensions" })
    return
  end

  local snippet = instance.state.install_catalogue and instance.state.install_catalogue[repo.full_name]
  if not snippet then
    snippet = string.format("vim.pack.add({ %q })", repo.url)
  end
  local path = extension_path(repo)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
  local write_ok, write_err = pcall(vim.fn.writefile, vim.split(snippet, "\n", { plain = true }), path)
  if not write_ok then
    vim.notify("Unable to save extension: " .. tostring(write_err), vim.log.levels.ERROR)
    return
  end

  local ok, err = execute_extension_file(path)
  instance.state.installed_items[repo.name] = true
  refresh(instance)
  if ok then
    vim.notify("Installed " .. repo.name, vim.log.levels.INFO, { title = "vimscode Extensions" })
  else
    vim.notify(
      repo.name .. " was installed, but its setup needs attention:\n" .. tostring(err),
      vim.log.levels.WARN,
      { title = "vimscode Extensions" }
    )
  end
end

function M.action_label()
  local repo = current_instance and current_instance.state.current_repository
  if is_installed(current_instance, repo) then
    return is_managed(repo) and "Uninstall" or "Bundled"
  end
  return "Install"
end

function M.focus_results()
  local instance = current_instance
  if instance and instance.list then
    instance.list:focus()
  end
end

function M.set_query(query)
  local instance = current_instance
  if not instance or instance.state.filter_query == query then
    return
  end
  instance.state.filter_query = query
  refresh(instance)
end

local function map_controls(instance)
  local buffers = {
    instance.list.state.buf.id,
    instance.list.state.buf.install_id,
    instance.preview.state.buf.id,
    instance.preview.state.buf.docs_id,
  }
  for _, buf in ipairs(buffers) do
    vim.keymap.set("n", "i", M.toggle_selected, { buffer = buf, silent = true, desc = "Install or uninstall extension" })
    vim.keymap.set("n", "g", M.choose_filter, { buffer = buf, silent = true, desc = "Filter extensions" })
    vim.keymap.set("n", "0", function()
      M.set_filter("all")
    end, { buffer = buf, silent = true, desc = "Show all extensions" })
    vim.keymap.set("n", "1", function()
      M.set_filter("installed")
    end, { buffer = buf, silent = true, desc = "Show installed extensions" })
    vim.keymap.set("n", "2", function()
      M.set_filter("available")
    end, { buffer = buf, silent = true, desc = "Show extensions not installed" })
  end
end

local function fit(text, width)
  local display_width = vim.fn.strdisplaywidth(text)
  if display_width <= width then
    return text .. string.rep(" ", width - display_width)
  end
  return vim.fn.strcharpart(text, 0, math.max(width - 1, 0)) .. "…"
end

local function apply_nvicode_chrome()
  local heading = require("store.ui.heading")
  if heading._nvicode_patched then
    return
  end

  local new_heading = heading.new
  heading.new = function(config)
    local instance, err = new_heading(config)
    if not instance then
      return nil, err
    end

    instance._buf_start_wave = function() end
    instance._buf_render = function(self)
      if not self.state.buf.id or not vim.api.nvim_buf_is_valid(self.state.buf.id) then
        return
      end
      vim.schedule(function()
        if not self.state.buf.id or not vim.api.nvim_buf_is_valid(self.state.buf.id) then
          return
        end

        local width = math.max(self.config.width or vim.o.columns, 20)
        local query = self.state.filter_query ~= "" and self.state.filter_query or "Search Extensions in Marketplace"
        local lines = { fit("  > " .. query, width) }

        local buf = self.state.buf.id
        vim.bo[buf].modifiable = true
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        vim.bo[buf].modifiable = false
        vim.bo[buf].filetype = "nvicode_extensions_header"
        vim.api.nvim_buf_clear_namespace(buf, chrome_namespace, 0, -1)
        vim.api.nvim_buf_set_extmark(buf, chrome_namespace, 0, 0, {
          end_row = 0,
          end_col = #lines[1],
          hl_group = "SnacksPickerInput",
          hl_eol = true,
        })
        vim.api.nvim_buf_add_highlight(buf, chrome_namespace, "SnacksPickerPrompt", 0, 0, 3)
      end)
    end
    return instance, nil
  end
  heading._nvicode_patched = true

  local store_modal = require("store.ui.store_modal")
  local new_modal = store_modal.new
  store_modal.new = function(config)
    local instance, err = new_modal(config)
    if not instance then
      return nil, err
    end
    current_instance = instance
    instance._nvicode_filter = "all"
    map_controls(instance)

    local render_list = instance.list._render_ready
    instance.list._render_ready = function(self, state)
      render_list(self, state)
      vim.schedule(function()
        local buf = self.state.buf.id
        if not buf or not vim.api.nvim_buf_is_valid(buf) then
          return
        end
        vim.api.nvim_buf_clear_namespace(buf, chrome_namespace, 0, -1)
        local width = self.state.win.id and vim.api.nvim_win_is_valid(self.state.win.id)
            and vim.api.nvim_win_get_width(self.state.win.id)
          or 38
        local rule = "  " .. string.rep("─", math.max(width - 4, 1))
        for line = 0, math.max(vim.api.nvim_buf_line_count(buf) - 2, -1) do
          vim.api.nvim_buf_set_extmark(buf, chrome_namespace, line, 0, {
            virt_lines = { { { rule, "VSCodeExtensionsSeparator" } } },
          })
        end
      end)
    end

    local on_repo = instance.list.config.on_repo
    instance.list.config.on_repo = function(repo)
      on_repo(repo)
      instance.heading:render({})
      instance.layout_provider:update_winbar(instance.list, instance.preview)
    end

    local heading_render = instance.heading.render
    instance.heading.render = function(self, state)
      local render_err = heading_render(self, state)
      if state.filter_query ~= nil and instance._nvicode_filter ~= "all" then
        vim.schedule(function()
          if current_instance == instance then
            refresh(instance)
          end
        end)
      end
      return render_err
    end

    local on_close = instance.config.on_close
    instance.config.on_close = function(...)
      current_instance = nil
      if on_close then
        return on_close(...)
      end
    end
    return instance, nil
  end
end

function M.setup()
  _G.VimSCodeToggleExtension = M.toggle_selected
  normalize_disabled_telemetry()
  setup_image_support()
  apply_nvicode_chrome()
  require("integrations.extensions_layout").setup()
  require("store").setup({
    layout = "tab",
    proportions = { list = 0.34, preview = 0.66 },
    repository_renderer = function(repo, opts)
      return {
        { content = opts.is_installed and "✓" or " ", limit = 1 },
        { content = repo.name, limit = 30 },
      }
    end,
    plugin_manager = "vim.pack",
    plugins_folder = vim.fs.joinpath(vim.fn.stdpath("config"), "lua", "extensions"),
    telemetry = false,
  })

  pcall(vim.api.nvim_del_user_command, "Store")
  vim.api.nvim_create_user_command("Store", M.open, { desc = "Open vimscode Extensions" })
  vim.api.nvim_create_user_command("ExtensionToggle", M.toggle_selected, { desc = "Install or uninstall selected extension" })
  vim.api.nvim_create_user_command("ExtensionFilter", function(args)
    if args.args == "" then
      M.choose_filter()
    else
      M.set_filter(args.args)
    end
  end, {
    nargs = "?",
    complete = function()
      return { "all", "installed", "not-installed" }
    end,
    desc = "Filter the vimscode Extension Store",
  })
end

function M.open()
  require("store").open()
  if #vim.api.nvim_list_uis() > 0 then
    local sidebar = require("vscode.sidebar")
    sidebar.set_active("extensions")
    vim.schedule(sidebar.ensure)
    vim.defer_fn(sidebar.ensure, 80)
    vim.defer_fn(sidebar.ensure, 250)
  end
end

function M.is_open()
  return current_instance ~= nil and not current_instance.state.is_closing
end

function M.close()
  if not M.is_open() then
    return false
  end
  local instance = current_instance
  local ok, err = pcall(function()
    instance:close()
  end)
  if not ok then
    vim.notify("Unable to close Extensions: " .. tostring(err), vim.log.levels.ERROR, { title = "vimscode" })
    return false
  end
  return true
end

return M
