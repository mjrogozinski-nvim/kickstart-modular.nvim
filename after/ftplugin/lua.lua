local in_current_buffer = require 'code.utils.buf-key-map'

vim.keymap.set('n', '<leader>x', ':source %<cr>', in_current_buffer.with_desc 'execute lua file')
vim.keymap.set('n', '<leader>X', ':lua require"osv".run_this()<cr>', in_current_buffer.with_desc 'debug lua file (breakpoint required!)')

vim.keymap.set('n', '<leader>dl', function()
  require('osv').launch { port = 8086 }
end, in_current_buffer.with_desc ' Launch Lua debug adapter')
