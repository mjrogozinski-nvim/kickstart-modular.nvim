return {
  -- {
  --   'zbirenbaum/copilot.lua',
  --   lazy = false,
  --   cmd = 'Copilot',
  --   event = 'InsertEnter',
  --   opts = {},
  -- },
  -- {
  --   'zbirenbaum/copilot-cmp',
  --   lazy = false,
  --   after = { 'copilot.lua' },
  --   opts = {},
  -- },
  {
    'github/copilot.vim',
  },
  {
    'CopilotC-Nvim/CopilotChat.nvim',
    branch = 'main',
    dependencies = {
      { 'zbirenbaum/copilot.lua' }, -- or github/copilot.vim
      { 'nvim-lua/plenary.nvim' }, -- for curl, log wrapper
    },
    opts = {},
  },
}
