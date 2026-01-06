require 'code.utils.save-writable-buffer'

vim.api.nvim_create_autocmd({ 'FocusLost', 'BufLeave', 'InsertLeave' }, {
  pattern = '*',
  callback = function(ev)
    Save_writable_buffer(ev.buf)
  end,
})
