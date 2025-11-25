return {
  'stevearc/overseer.nvim',
  opts = {
    templates = {
      'builtin',
      'user.run_script',
      'user.compile_cpp',
      'user.build_cmake',
    },
    task_list = {
      keymaps = {
        ['<C-k>'] = '<C-w><C-k>',
        ['<C-j>'] = '<C-w><C-j>',
      },
    },
  },
}
