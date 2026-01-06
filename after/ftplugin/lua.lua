local in_current_buffer = require 'code.utils.buf-key-map'

vim.keymap.set('n', '<leader>cm', ':source %<cr>', in_current_buffer.with_desc 'execute lua file ([m]ake)')
vim.keymap.set('n', '<leader>dm', ':lua require"osv".run_this()<cr>', in_current_buffer.with_desc 'debug lua file (breakpoint required!)')

vim.keymap.set('n', '<leader>dl', function()
  require('osv').launch { port = 8086 }
end, in_current_buffer.with_desc ' Launch Lua debug adapter')

local dap = require 'dap'
dap.configurations.lua = {
  {
    type = 'nlua',
    request = 'attach',
    name = 'Attach to running Neovim instance',
  },
}

dap.adapters.nlua = function(callback, config)
  callback { type = 'server', host = config.host or '127.0.0.1', port = config.port or 8086 }
end
