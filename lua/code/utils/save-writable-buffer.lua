function Save_writable_buffer(buf)
  if
    vim.api.nvim_buf_is_loaded(buf)
    and vim.api.nvim_buf_get_option(buf, 'modifiable')
    and not vim.api.nvim_buf_get_option(buf, 'readonly')
    and vim.api.nvim_buf_get_name(buf) ~= ''
  then
    pcall(function()
      vim.api.nvim_buf_call(buf, function()
        vim.cmd 'silent! update'
      end)
    end)
  end
end

return Save_writable_buffer
