-- :Man foo
vim.api.nvim_create_autocmd('FileType', { pattern = 'man', command = [[nnoremap <buffer><silent> q :quit<CR>]] })

-- :h foo
vim.api.nvim_create_autocmd('FileType', { pattern = 'help', command = [[nnoremap <buffer><silent> q :quit<CR>]] })
