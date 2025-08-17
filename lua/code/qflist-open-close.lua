vim.keymap.set('n', '<leader>cl', ':cclose<CR>', { silent = true, desc = '[C][l]ose quickfix list' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })
-- TODO: ? <leader>q for closing, now it's <leader>cl
