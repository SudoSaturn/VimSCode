local M = {}

function M.setup()
  require("integrations.workbench").setup()
  require("integrations.editor").setup()
  require("integrations.debug").setup()
  require("integrations.store").setup()
end

return M
