local function set_paste_inside_binding_for(textobject)
  vim.keymap.set({ 'n', 'v' }, '<leader>p' .. textobject, '"_di' .. textobject .. 'P', { desc = 'paste over ' .. textobject })
end

set_paste_inside_binding_for 'w'
set_paste_inside_binding_for 'W'
set_paste_inside_binding_for '<'
set_paste_inside_binding_for '>'

-- for some reason just typing worked, but mapping did not
vim.keymap.set('n', '<leader>pq', function()
  local keys = vim.api.nvim_replace_termcodes('"_diqP', true, false, true)
  vim.api.nvim_feedkeys(keys, 'x', false)
end, { desc = 'paste over inside quote, replace inside quote' })
