local in_current_buffer = require 'code.utils.buf-key-map'
local save_buffers = require 'code.utils.save-writable-buffers'

vim.keymap.set('n', '<leader>o', ':ClangdSwitchSourceHeader<CR>', in_current_buffer.with_desc 'switch header-source')
vim.keymap.set('n', '<F4>', ':ClangdSwitchSourceHeader<CR>', in_current_buffer.with_desc 'switch header-source')

local function build_cmake_gtest_keymap()
  vim.keymap.set('n', '<leader>if', function()
    local task = require('overseer').new_task {
      name = 'cmake build gtest file run',
      strategy = {
        'orchestrator',
        tasks = {
          'cmake build',
          {
            name = 'run gtest file ' .. vim.fn.expand '%',
            cmd = vim.cmd "lua require('neotest').run.run(vim.fn.expand '%')",
            components = { 'default' },
          },
        },
      },
    }
    task:start()
  end, in_current_buffer.with_desc 'build cmake run gtest file')
end

-- TODO: maybe extract it as util
-- TODO: consider using decorator as it only adds build on top of regular <leader>if
vim.api.nvim_create_autocmd({ 'LspAttach', 'BufEnter', 'BufWinEnter' }, {
  pattern = { '*.cpp' },
  callback = build_cmake_gtest_keymap,
})
