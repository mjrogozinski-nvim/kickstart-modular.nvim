local save_buffers = require 'code.utils.save-all-writable-buffers'

return {
  'nvim-neotest/neotest',
  dependencies = {
    'nvim-neotest/nvim-nio',
    'nvim-lua/plenary.nvim',
    'HiPhish/neotest-busted',
    'antoinemadec/FixCursorHold.nvim',
    'nvim-treesitter/nvim-treesitter',
    'nvim-neotest/neotest-python',
    'nvim-neotest/neotest-vim-test',
    'vim-test/vim-test',
  },
  config = function()
    local vim_test_adapter = require 'neotest-vim-test' {
      ignore_file_types = { 'python', 'vim', 'lua', 'rust' },
    }

    -- to scan for new tests, run :w explicitly even if the file is saved automatically
    -- neotest scans for tests then

    -- scanning for tests initiall is blocking - known limitation

    -- `neotest-vim-test` attempts to call itself through Neotest's subprocess.
    -- With our pinned Neotest version, that child runtimepath does not include
    -- this adapter, causing: `module 'neotest-vim-test' not found`.
    -- Force local adapter methods to bypass subprocess until Neotest is updated.
    vim_test_adapter.is_test_file = vim_test_adapter._is_test_file
    vim_test_adapter.discover_positions = vim_test_adapter._discover_positions
    vim_test_adapter.build_spec = vim_test_adapter._build_spec

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
        vim_test_adapter,
        require 'rustaceanvim.neotest',
      },
    }
  end,
  keys = {
    {
      '<leader>is',
      function()
        require('neotest').summary.toggle()
      end,
      mode = '',
      desc = 'Neotest summary, open tests, integration summary',
    },
    {
      '<leader>io',
      function()
        require('neotest').summary.toggle()
      end,
      mode = '',
      desc = 'Neotest summary, open tests, integration summary',
    },
    {
      '<leader>ir',
      function()
        save_buffers()
        require('neotest').run.run()
      end,
      mode = '',
      desc = 'Neotest run, run test, integration run',
    },
    {
      '<leader>ia',
      function()
        save_buffers()
        require('neotest').run.attach()
      end,
      mode = '',
      desc = 'Neotest attach',
    },
    {
      '<leader>ix',
      function()
        save_buffers()
        require('neotest').run.stop()
      end,
      mode = '',
      desc = 'Neotest stop nearest test',
    },
    {
      '<leader>iR',
      function()
        save_buffers()
        require('neotest').run.run { strategy = 'dap' }
      end,
      mode = '',
      desc = 'Neotest run (debug), run test, integration run',
    },
    {
      '<leader>if',
      function()
        save_buffers()
        require('neotest').run.run(vim.fn.expand '%')
      end,
      mode = '',
      desc = 'Neotest run, run test file, integration for file',
    },
    {
      '<leader>it',
      function()
        require('neotest').output_panel.toggle()
      end,
      mode = '',
      desc = 'Neotest terminal, integration terminal, tests output',
    },
  },
}

-- here maybe a comment about philosophy of leader shortcuts
-- initially I wanted to have leader cto, but it is too long
-- then I tried leader tr, leader tf and have come up with this idea:
-- two letters need to be pressed at least by different fingers
-- preferably with different hands
-- tr does not work, as the same finger needs to move from t to r,
-- making the whole sequence ... sequential :D
-- ir works because fingers can move to i and r in parallel
--
-- let's say in this case i stands for integration (like in integration tests)
-- but really it's because of where these keys are located on the keyboard (:
