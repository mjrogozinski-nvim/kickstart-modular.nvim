-- https://github.com/echasnovski/mini.nvim/blob/main/doc/mini-surround.txt#L573C3-L573C45
--
-- Note: if 'timeoutlen' is low enough to cause occasional usage of |s| key
-- (that deletes character under cursor), disable it with the following call: >lua
--
vim.keymap.set({ 'n', 'x' }, 's', '<Nop>')
