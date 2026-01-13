local in_current_buffer = require 'code.utils.buf-key-map'

vim.keymap.set('n', ',v', '<cmd>VenvSelect<cr>', in_current_buffer.with_desc 'Select venv')
