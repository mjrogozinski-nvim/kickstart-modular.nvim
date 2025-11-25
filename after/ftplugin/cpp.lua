local in_current_buffer = require 'code.utils.buf-key-map'

vim.keymap.set('n', '<leader>o', ':ClangdSwitchSourceHeader<CR>', in_current_buffer.with_desc 'switch header-source')
vim.keymap.set('n', '<F4>', ':ClangdSwitchSourceHeader<CR>', in_current_buffer.with_desc 'switch header-source')

-- Function to find 'build' directory in current or parent directories
-- from chat gpt
function Find_build_dir()
  local cwd = vim.fn.getcwd()
  local build_dir = nil
  while cwd do
    if vim.fn.isdirectory(cwd .. '/build') == 1 then
      build_dir = cwd .. '/build'
      break
    end
    local parent = vim.fn.fnamemodify(cwd, ':h')
    if parent == cwd then
      break
    end
    cwd = parent
  end
  return build_dir
end

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
        {
          name = 'cmake build',
          desc = "Run 'make' in a 'build' folder located in the current or a parent directory.",
          cmd = 'make',
          cwd = Find_build_dir(),
          components = { { 'on_output_parse', problem_matcher = '$gcc' }, { 'on_output_quickfix', open = false }, 'default' },
          condition = {
            callback = function()
              local build_dir = Find_build_dir()
              return build_dir ~= nil
            end,
          },
        },
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
