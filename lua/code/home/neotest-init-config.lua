---@diagnostic disable-next-line: missing-fields
require('neotest').setup {
  consumers = {
    overseer = require 'neotest.consumers.overseer',
  },
  adapters = {
    require 'neotest-python' {
      dap = { justMyCode = false },
      python = 'python3',
      runner = 'pytest',
    },
    require 'neotest-busted',
    require 'neotest-vim-test' {
      ignore_file_types = { 'python', 'vim', 'lua', 'rust' },
    },
    require 'rustaceanvim.neotest',
  },
}
