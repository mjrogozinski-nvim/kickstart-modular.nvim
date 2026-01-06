-- Enable spell checking for certain file types
vim.api.nvim_create_autocmd(
  { 'BufRead', 'BufNewFile' },
  {
    pattern = { '*.txt', '*.md', '*.tex', 'gitcommit' },
    callback = function()
      vim.opt.spell = true
      vim.opt.spelllang = 'en,pl'
    end,
  }
)
