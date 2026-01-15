require 'snacks'

vim.keymap.set('n', '<leader>bc', function()
  Snacks.bufdelete()
end, { silent = true, desc = 'close buffer' })
