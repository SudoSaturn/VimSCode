local M = {}

local function fit(text, width)
  local display_width = vim.fn.strdisplaywidth(text)
  if display_width <= width then
    return text .. string.rep(" ", width - display_width)
  end
  return vim.fn.strcharpart(text, 0, math.max(width - 1, 0)) .. "…"
end

-- Store owns catalogue data, filtering, installs, and README rendering.
-- NVICode supplies the workbench chrome without modifying the dependency.
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
        local query = self.state.filter_query ~= "" and self.state.filter_query or "Press F to search extensions"
        local results = self.state.state == "loading" and "Loading Marketplace…"
          or string.format("%d results  ·  %d installed", self.state.filtered_count or 0, self.state.installed_count or 0)
        local sort = (self.state.sort_type or "recently_updated"):gsub("_", " ")
        local lines = {
          fit("  EXTENSIONS", width),
          fit("    " .. query, width),
          fit("  " .. results .. "  ·  Sort: " .. sort, width),
          fit("", width),
          fit("  MARKETPLACE                                   EXTENSION DETAILS", width),
        }

        local buf = self.state.buf.id
        vim.bo[buf].modifiable = true
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        vim.bo[buf].modifiable = false
        vim.bo[buf].filetype = "nvicode_extensions_header"
      end)
    end
    return instance, nil
  end
  heading._nvicode_patched = true
end

function M.setup()
  apply_nvicode_chrome()
  require("store").setup({
    layout = "tab",
    proportions = { list = 0.34, preview = 0.66 },
    plugin_manager = "vim.pack",
    plugins_folder = vim.fs.joinpath(vim.fn.stdpath("config"), "lua", "extensions"),
    telemetry = false,
  })

  -- Keep Store's documented command while routing every entry point through
  -- NVICode's activity bar and split orchestration.
  pcall(vim.api.nvim_del_user_command, "Store")
  vim.api.nvim_create_user_command("Store", M.open, { desc = "Open NVICode Extensions" })
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

return M
