local in_current_buffer = require 'code.utils.buf-key-map'

local function cmake_gf()
  local cword = vim.fn.expand '<cfile>' -- like gf target
  if vim.fn.filereadable(cword) == 1 then
    vim.cmd.edit(cword)
    return
  end
  local cleaned = cword:gsub('%${CMAKE_CURRENT_LIST_DIR}/', '')

  -- Try open relative to current file's directory
  local basedir = vim.fn.expand '%:p:h'
  local target = basedir .. '/' .. cleaned

  if vim.fn.filereadable(target) == 1 then
    vim.cmd.edit(target)
    return
  end
  -- fallback to normal gf
  vim.cmd.normal { args = { 'gf' }, bang = true }
end

local function set_cmake_open_file_keymap()
  vim.keymap.set('n', '<F2>', cmake_gf, in_current_buffer.with_desc 'Go to file under cursor')
end

-- sometimes LSP attaches after ...
set_cmake_open_file_keymap()

vim.api.nvim_create_autocmd('LspAttach', {
  buffer = vim.api.nvim_get_current_buf(),
  callback = set_cmake_open_file_keymap,
})

-- ... or before
set_cmake_open_file_keymap()
