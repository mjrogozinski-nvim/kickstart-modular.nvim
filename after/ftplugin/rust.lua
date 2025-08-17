local in_current_buffer = require 'code.utils.buf-key-map'

vim.keymap.set('n', '<leader>ct', function()
  vim.cmd.RustLsp { 'testables', bang = false }
end, in_current_buffer.with_desc 'RustTest!')

vim.keymap.set('n', '<leader>x', function()
  vim.cmd.RustLsp 'run'
end, in_current_buffer.with_desc 'Rust run')

vim.keymap.set('n', '<leader>X', function()
  vim.cmd.RustLsp 'debug'
end, in_current_buffer.with_desc 'Rust debug')
