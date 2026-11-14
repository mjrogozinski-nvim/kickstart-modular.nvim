vim.keymap.set('n', '<leader>cx', function()
  require('code.home.cmake').run(0)
end, { silent = true, desc = 'Build and run executable' })

local function summary_task(overseer)
  local status = require('overseer.constants').STATUS
  local tasks = overseer.list_tasks { include_ephemeral = true }
  local parent
  for _, task in ipairs(tasks) do
    if task.parent_id == nil and (not parent or task.id > parent.id) then
      parent = task
    end
  end
  if not parent then
    return nil
  end
  local failed, last
  for _, task in ipairs(tasks) do
    if task.parent_id == parent.id then
      if task.status == status.FAILURE and (not failed or task.id > failed.id) then
        failed = task
      end
      if task.status ~= status.PENDING and (not last or task.id > last.id) then
        last = task
      end
    end
  end
  return failed or last or parent
end

vim.keymap.set('n', '<leader>cb', function()
  require('code.home.cmake').build(0)
end, { silent = true, desc = 'Build project with CMake' })

vim.keymap.set('n', '<leader>cm', function()
  require('code.home.cmake').test(0)
end, { silent = true, desc = 'build and run all tests' })

vim.keymap.set('n', '<leader>co', function()
  local overseer = require 'overseer'
  local task = summary_task(overseer)
  overseer.toggle { focus_task_id = task and task.id or nil }
end, {
  silent = true,
  desc = 'ToggleOverseer (Open Overseer)',
})

vim.keymap.set('n', '<leader>cr', '<cmd>OverseerRun<cr>', {
  silent = true,
  desc = 'OverseerRun (Run Overseer)',
})
