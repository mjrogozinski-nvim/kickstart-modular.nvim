-- don't auto comment new line
vim.api.nvim_create_autocmd('BufEnter', { command = [[set formatoptions-=cro]] })
