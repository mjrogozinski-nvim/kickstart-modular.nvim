vim.api.nvim_create_autocmd({ 'FocusLost', 'BufLeave', 'InsertLeave' }, {
  pattern = '*',
  command = 'silent! update',
})
