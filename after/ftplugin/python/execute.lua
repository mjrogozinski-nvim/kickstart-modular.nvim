local in_current_buffer = require 'code.utils.buf-key-map'

vim.keymap.set('n', '<leader>cx', function()
  local filename = vim.api.nvim_buf_get_name(0)
  if filename == '' then
    vim.notify('Save the Python file before executing it', vim.log.levels.ERROR)
    return
  end

  vim.cmd.update()
  require('overseer').new_task({
    name = 'python ' .. vim.fs.basename(filename),
    cmd = { 'python3', filename },
    cwd = vim.uv.cwd(),
    components = { 'default' },
  }):start()
end, in_current_buffer.with_desc 'execute Python file (Overseer)')
