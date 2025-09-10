local cmp = require 'blink.cmp'

vim.keymap.set({ 'i', 's' }, '<C-L>', function()
  if not cmp.is_active() then
    return
  end
  cmp.accept()
  cmp.snippet_forward()
end, { silent = true, noremap = true })

vim.keymap.set({ 'i', 's' }, '<C-H>', function()
  cmp.snippet_backward()
end, { silent = true })
