local ht = require 'haskell-tools'
local in_current_buffer = require 'code.utils.buf-key-map'

-- haskell-language-server relies heavily on codeLenses,
-- so auto-refresh (see advanced configuration) is enabled by default
vim.keymap.set('n', '<leader>xc', vim.lsp.codelens.run, in_current_buffer.with_desc 'Codelens run')
-- Hoogle search for the type signature of the definition under the cursor
vim.keymap.set('n', '<leader>K', ht.hoogle.hoogle_signature, in_current_buffer.with_desc 'Hoogle signature')
-- Evaluate all code snippets
vim.keymap.set('n', '<leader>xa', ht.lsp.buf_eval_all, in_current_buffer.with_desc 'Evaluate all code snippets')
-- Toggle a GHCi repl for the current package
vim.keymap.set('n', '<leader>xr', ht.repl.toggle, in_current_buffer.with_desc 'Toggle repl for current package')
-- Toggle a GHCi repl for the current buffer
vim.keymap.set('n', '<leader>xf', function()
  ht.repl.toggle(vim.api.nvim_buf_get_name(0))
end, in_current_buffer.with_desc 'Toggle repl in current buffer')
vim.keymap.set('n', '<leader>xq', ht.repl.quit, in_current_buffer.with_desc 'Quit repl')
