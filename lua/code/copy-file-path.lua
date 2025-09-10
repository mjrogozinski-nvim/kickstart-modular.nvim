-- Copy full file path
vim.keymap.set('n', '<leader>fp', function()
  vim.fn.setreg('+', vim.fn.expand '%:p')
  print('Copied full path: ' .. vim.fn.expand '%:p')
end, { desc = 'Copy full file path' })

-- Copy file name
vim.keymap.set('n', '<leader>fn', function()
  vim.fn.setreg('+', vim.fn.expand '%:t')
  print('Copied file name: ' .. vim.fn.expand '%:t')
end, { desc = 'Copy file name' })

-- Copy directory path
vim.keymap.set('n', '<leader>fd', function()
  vim.fn.setreg('+', vim.fn.expand '%:p:h')
  print('Copied directory: ' .. vim.fn.expand '%:p:h')
end, { desc = 'Copy directory path' })
