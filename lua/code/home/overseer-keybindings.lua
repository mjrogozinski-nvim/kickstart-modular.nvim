local overseer_components = require 'code.utils.overseer-components'
local project_root = require 'code.utils.project-root'

local function build_and_run_all_tests()
  local root = project_root({ 'Makefile' })
  if not root then
    vim.notify('No Makefile found for this project', vim.log.levels.ERROR)
    return
  end

  require 'code.utils.save-all-writable-buffers'()
  require('overseer')
    .new_task({
      name = 'run all tests',
      cwd = root,
      strategy = {
        'orchestrator',
        tasks = {
          {
            name = 'build',
            cmd = { 'make', 'build' },
            cwd = root,
            components = overseer_components.build_output(),
          },
          {
            name = 'test',
            cmd = { 'ctest', '--test-dir', 'build', '--output-on-failure' },
            cwd = root,
            components = overseer_components.dock_output(),
          },
        },
      },
      components = { 'default' },
    })
    :start()
end

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

-- another option is :OverseerRun cmake\ build
vim.keymap.set('n', '<leader>cb', function()
  require('overseer').run_task { name = 'cmake build' }
end, {
  silent = true,
  desc = 'cmake build (Overseer run cmake build)',
})

vim.keymap.set('n', '<leader>cm', build_and_run_all_tests, {
  silent = true,
  desc = 'build and run all tests',
})

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
