vim.keymap.set('n', '<leader>fg', ':%!rg ', { desc = 'file grep' })
vim.keymap.set('n', '<leader>fG', ':%!rg --invert-match ', { desc = 'inverse file grep' })
