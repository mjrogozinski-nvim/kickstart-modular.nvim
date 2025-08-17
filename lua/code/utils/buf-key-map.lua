-- without specifying bufnr, keymaps are available in other buffers
local M = {}

function M.with_desc(description)
  local bufnr = vim.api.nvim_get_current_buf()
  return { noremap = true, silent = true, buffer = bufnr, desc = description }
end

return M
