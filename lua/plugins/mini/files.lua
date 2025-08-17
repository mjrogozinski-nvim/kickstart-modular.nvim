return {
  'echasnovski/mini.files',
  version = false,
  keys = {
    {
      '<leader>e',
      function()
        MiniFiles.open(vim.api.nvim_buf_get_name(0))
      end,
      mode = '',
      desc = '[e]xplorer',
    },
    {
      '<leader>E',
      function()
        MiniFiles.open()
      end,
      mode = '',
      desc = '[e]xplorer in cwd',
    },
  },
  opts = {},
}
