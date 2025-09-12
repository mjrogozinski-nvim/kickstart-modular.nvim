---@diagnostic disable-next-line: missing-fields
require('neotest').setup {
  adapters = {
    require 'neotest-python' {
      dap = { justMyCode = false },
      python = 'python3',
      runner = 'pytest',
    },
    require 'neotest-busted',
    require 'neotest-vim-test' {
      ignore_file_types = { 'python', 'vim', 'lua', 'cpp', 'rust' },
    },
    require 'rustaceanvim.neotest',
  },
}
