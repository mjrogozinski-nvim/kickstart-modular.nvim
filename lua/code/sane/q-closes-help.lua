local q_quits_filetypes = {
  'man', -- :Man foo
  'help', -- :h foo
  'fugitive', -- :Git
}
vim.api.nvim_create_autocmd('FileType', { pattern = q_quits_filetypes, command = [[nnoremap <buffer><silent> q :quit<CR>]] })
