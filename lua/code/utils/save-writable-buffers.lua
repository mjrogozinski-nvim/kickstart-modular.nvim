-- TODO: prevent asking to save open e.g. STL headers
function Save_all_writable_buffers()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_option(buf, 'modifiable') then
      local ok, err = pcall(function()
        vim.api.nvim_buf_call(buf, function()
          vim.cmd 'silent! write'
        end)
      end)
    end
  end
end

return Save_all_writable_buffers
