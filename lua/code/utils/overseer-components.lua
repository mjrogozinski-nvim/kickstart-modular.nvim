local M = {}

-- Build-style tasks: surface compiler diagnostics without opening the quickfix window.
function M.build_output()
  return {
    { 'on_output_parse', problem_matcher = '$gcc' },
    { 'on_output_quickfix', open = false },
    'default',
  }
end

-- Interactive tasks: show output in a docked window instead of the task list.
function M.dock_output()
  return {
    { 'open_output', direction = 'dock', focus = false, on_start = 'always' },
    'default',
  }
end

return M