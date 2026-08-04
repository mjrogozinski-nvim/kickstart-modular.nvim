return {
  'stevearc/overseer.nvim',
  opts = {
    templates = {
      'builtin',
    },
    task_list = {
      sort = function(left, right)
        if left.parent_id and left.parent_id == right.parent_id then
          return left.id < right.id
        end
        return require('overseer.task_list').default_sort(left, right)
      end,
      keymaps = {
        ['<C-k>'] = '<C-w><C-k>',
        ['<C-j>'] = '<C-w><C-j>',
      },
    },
  },
}
