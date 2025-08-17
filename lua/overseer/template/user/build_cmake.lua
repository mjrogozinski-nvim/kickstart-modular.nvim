-- Function to find 'build' directory in current or parent directories
-- from chat gpt
function Find_build_dir()
  local cwd = vim.fn.getcwd()
  local build_dir = nil
  while cwd do
    if vim.fn.isdirectory(cwd .. '/build') == 1 then
      build_dir = cwd .. '/build'
      break
    end
    local parent = vim.fn.fnamemodify(cwd, ':h')
    if parent == cwd then
      break
    end
    cwd = parent
  end
  return build_dir
end

return {
  name = 'cmake build',
  desc = "Run 'make' in a 'build' folder located in the current or a parent directory.",
  builder = function()
    local build_dir = Find_build_dir()
    return {
      cmd = 'make',
      cwd = build_dir,
      components = { { 'on_output_parse', problem_matcher = '$gcc' }, { 'on_output_quickfix', open = true }, 'default' },
    }
  end,
  condition = {
    callback = function()
      local build_dir = Find_build_dir()
      return build_dir ~= nil
    end,
  },
}
