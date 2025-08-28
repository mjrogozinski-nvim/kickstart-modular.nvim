-- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
-- - sd'   - [S]urround [D]elete [']quotes
-- - sr)'  - [S]urround [R]eplace [)] [']
return {
  'nvim-mini/mini.surround',
  opts = {},
  version = false,
  config = function()
    -- https://github.com/nvim-mini/mini.nvim/blob/main/doc/mini-surround.txt#L573C3-L573C45
    --
    -- Note: if 'timeoutlen' is low enough to cause occasional usage of |s| key
    -- (that deletes character under cursor), disable it with the following call: >lua
    --
    vim.keymap.set({ 'n', 'x' }, 's', '<Nop>')
  end,
}
