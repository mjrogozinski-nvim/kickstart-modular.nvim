return {
  'stevearc/overseer.nvim',
  opts = {
    templates = {
      'builtin',
    },
    task_list = {
      keymaps = {
        ['<C-k>'] = '<C-w><C-k>',
        ['<C-j>'] = '<C-w><C-j>',
      },
    },
  },
}
