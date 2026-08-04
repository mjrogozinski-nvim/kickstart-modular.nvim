local function project_root()
  local filename = vim.api.nvim_buf_get_name(0)
  local start = filename ~= '' and vim.fs.dirname(filename) or vim.uv.cwd()
  local makefile = vim.fs.find('Makefile', { path = start, upward = true })[1]
  return makefile and vim.fs.dirname(makefile) or nil
end

local function build_and_run_all_tests()
  local root = project_root()
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
            components = {
              { 'on_output_parse', problem_matcher = '$gcc' },
              { 'on_output_quickfix', open = false },
              'default',
            },
          },
          {
            name = 'test',
            cmd = { 'ctest', '--test-dir', 'build', '--output-on-failure' },
            cwd = root,
            components = {
              { 'open_output', direction = 'dock', focus = false, on_start = 'always' },
              'default',
            },
          },
        },
      },
      components = { 'default' },
    })
    :start()
end

local function newest_task(tasks, predicate)
  local newest
  for _, task in ipairs(tasks) do
    if predicate(task) and (not newest or task.id > newest.id) then
      newest = task
    end
  end
  return newest
end

local function summary_task(overseer)
  local status = require('overseer.constants').STATUS
  local tasks = overseer.list_tasks { include_ephemeral = true }
  local parent = newest_task(tasks, function(task)
    return task.parent_id == nil
  end)
  if not parent then
    return nil
  end

  local failed = newest_task(tasks, function(task)
    return task.parent_id == parent.id and task.status == status.FAILURE
  end)
  if failed then
    return failed
  end

  local last_started = newest_task(tasks, function(task)
    return task.parent_id == parent.id and task.status ~= status.PENDING
  end)
  return last_started or parent
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
