local M = {}

function M.setup()
  local dap = require("dap")
  local dapui = require("dapui")

  dapui.setup()
  require("nvim-dap-virtual-text").setup()
  require("mason-nvim-dap").setup({
    automatic_installation = true,
    ensure_installed = { "python" },
    handlers = {},
  })

  dap.listeners.after.event_initialized["vscode_dapui"] = function()
    dapui.open()
  end
  dap.listeners.before.event_terminated["vscode_dapui"] = function()
    dapui.close()
  end
  dap.listeners.before.event_exited["vscode_dapui"] = function()
    dapui.close()
  end

  local vscode = require("dap.ext.vscode")
  vscode.json_decode = function(value)
    return vim.json.decode(require("plenary.json").json_strip_comments(value))
  end

  vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "DiagnosticError" })
  vim.fn.sign_define("DapBreakpointCondition", { text = "", texthl = "DiagnosticWarn" })
  vim.fn.sign_define("DapStopped", { text = "", texthl = "DiagnosticInfo", linehl = "Visual" })
end

return M
