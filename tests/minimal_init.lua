vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

local config = vim.fn.stdpath 'config'
local plugins = vim.fn.stdpath 'data' .. '/lazy'

vim.opt.runtimepath:prepend(config)
vim.opt.runtimepath:prepend(config .. '/profiles/home')
for _, plugin in ipairs { 'nvim-treesitter', 'nvim-dap', 'overseer.nvim' } do
  local path = plugins .. '/' .. plugin
  assert(vim.fn.isdirectory(path) == 1, 'required test plugin is not installed: ' .. path)
  vim.opt.runtimepath:prepend(path)
end
vim.opt.runtimepath:append(config .. '/after')

vim.cmd 'filetype plugin on'
require('overseer').setup(require('plugins.overseer').opts)
