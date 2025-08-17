return {
  'p00f/clangd_extensions.nvim',
  opts = {},
  config = function()
    vim.keymap.set('n', '<leader>th', ':ClangdToggleInlayHints', { desc = 'Toggle inlay hints (clangd)' })
  end,
}
