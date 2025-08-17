return {
  'nvimdev/lspsaga.nvim',
  opts = {},
  keys = {
    {
      '<leader>cA',
      '<cmd>Lspsaga code_action<CR>',
      mode = '',
      desc = 'Lspsaga Code Action',
    },
    {
      '<leader>cA',
      '<cmd>Lspsaga range_code_action<CR>',
      mode = 'x',
      desc = 'Range code action',
    },
    {
      '<leader>cd',
      '<cmd>Lspsaga show_line_diagnostics<CR>',
      mode = '',
      desc = 'Show line diagnostics',
    },
    {
      '<leader>cR',
      '<cmd>Lspsaga rename<CR>',
      mode = '',
      desc = 'Lspsaga rename',
    },
  },
  dependencies = {
    'nvim-treesitter/nvim-treesitter', -- optional
    'nvim-tree/nvim-web-devicons', -- optional
  },
}
