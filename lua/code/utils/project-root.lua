-- Find a project root by searching upward for any of `markers` (filenames,
-- e.g. { 'CMakeLists.txt' }) from the directory of buffer `bufnr`.
local function start_dir(bufnr)
  local filename = vim.api.nvim_buf_get_name(bufnr or 0)
  return filename ~= '' and vim.fs.dirname(filename) or vim.uv.cwd()
end

return function(markers, bufnr)
  local found = vim.fs.find(markers, { path = start_dir(bufnr), upward = true })[1]
  return found and vim.fs.dirname(found) or nil
end