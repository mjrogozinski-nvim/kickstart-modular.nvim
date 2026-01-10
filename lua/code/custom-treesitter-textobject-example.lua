-- just an example
-- the queries are in the queries/<language>/custom.scm
-- custom.scm matches the function argument before mode

for _, mode in ipairs { 'x', 'o' } do
  vim.keymap.set(mode, 'aF', function()
    require('nvim-treesitter.textobjects.select').select_textobject('@custom_capture', 'custom', mode)
  end)
end
