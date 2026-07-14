vim.keymap.set('n', '<F2>', function()
  vim.cmd.normal { args = { 'gf' }, bang = true }
end, { desc = 'execute gf with F2' })
