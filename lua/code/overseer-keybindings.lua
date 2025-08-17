-- another option is :OverseerRun cmake\ build
vim.keymap.set('n', '<leader>cb', function()
  require('overseer').run_template { name = 'cmake build' }
end, {
  silent = true,
  desc = 'cmake build (Overseer run cmake build)',
})

vim.keymap.set('n', '<leader>cm', function()
  require('overseer').run_template { name = 'make' }
end, {
  silent = true,
  desc = 'make (Overseer run make)',
})

vim.keymap.set('n', '<leader>co', function()
  require('overseer').toggle()
end, {
  silent = true,
  desc = 'ToggleOverseer (Open Overseer)',
})

vim.keymap.set('n', '<leader>cr', '<cmd>OverseerRun<cr>', {
  silent = true,
  desc = 'OverseerRun (Run Overseer)',
})
