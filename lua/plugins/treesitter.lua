return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy = false,
    build = ':TSUpdate',
    config = function()
      local parsers = { 'bash', 'c', 'cpp', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc' }
      local ts = require 'nvim-treesitter'

      ts.setup()
      ts.install(parsers)

      local patterns = {}
      for _, parser in ipairs(parsers) do
        for _, filetype in ipairs(vim.treesitter.language.get_filetypes(parser)) do
          table.insert(patterns, filetype)
        end
      end

      vim.api.nvim_create_autocmd('FileType', {
        pattern = patterns,
        callback = function()
          vim.treesitter.start()
        end,
      })
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
