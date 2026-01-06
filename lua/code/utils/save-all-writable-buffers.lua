require 'code.utils.save-writable-buffer'

function Save_all_writable_buffers()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    Save_writable_buffer(buf)
  end
end

return Save_all_writable_buffers
