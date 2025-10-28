local in_current_buffer = require 'code.utils.buf-key-map'

vim.keymap.set('n', '<leader>o', ':ClangdSwitchSourceHeader<CR>', in_current_buffer.with_desc 'switch header-source')
vim.keymap.set('n', '<F4>', ':ClangdSwitchSourceHeader<CR>', in_current_buffer.with_desc 'switch header-source')

local function run_build_cmake_gtest_task()
  local task = require('overseer').new_task {
    name = 'cmake build gtest file run',
    strategy = {
      'orchestrator',
      tasks = {
        {
          name = 'save buffers',
          cmd = vim.cmd "lua require 'code.utils.save-writable-buffers'()",
          components = { 'default' },
        },
        'cmake build',
        {
          name = 'run gtest app',
          cmd = 'build/app',
          components = { { 'on_output_quickfix', open = false }, 'default' },
        },
      },
    },
  }
  task:start()
end

local function build_cmake_gtest_keymap()
  vim.keymap.set('n', '<leader>cm', run_build_cmake_gtest_task, in_current_buffer.with_desc 'build cmake run gtest file')
end

-- TODO: maybe extract it as util
-- TODO: consider using decorator as it only adds build on top of regular <leader>if
vim.api.nvim_create_autocmd({ 'LspAttach', 'BufEnter', 'BufWinEnter' }, {
  pattern = { '*.cpp' },
  callback = build_cmake_gtest_keymap,
})
