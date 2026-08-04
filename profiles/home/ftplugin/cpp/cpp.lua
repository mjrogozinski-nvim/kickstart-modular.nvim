local in_current_buffer = require 'code.utils.buf-key-map'

vim.keymap.set('n', '<leader>o', ':ClangdSwitchSourceHeader<CR>', in_current_buffer.with_desc 'switch header-source')
vim.keymap.set('n', '<F4>', ':ClangdSwitchSourceHeader<CR>', in_current_buffer.with_desc 'switch header-source')
