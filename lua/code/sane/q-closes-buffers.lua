local q_quits_filetypes = {
  'man', -- :Man foo
  'help', -- :h foo
  'fugitive', -- :Git
  'git', -- :Git diff
  'gitsigns-blame', -- :Gitsigns blame, leader hB
  'OverseerOutput', -- Ctrl+S in leader co
  'neotest-summary', -- <leader>io
  'qf' -- quickfix list
}
vim.api.nvim_create_autocmd('FileType', { pattern = q_quits_filetypes, command = [[nnoremap <buffer><silent> q :quit<CR>]] })
