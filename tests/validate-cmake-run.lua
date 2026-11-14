-- Integration check: requires cmake and a C++ compiler on PATH.
local root = vim.fn.tempname()
local function main()
  vim.fn.mkdir(root, 'p')
  root = vim.uv.fs_realpath(root)
  local function write(name, lines)
    vim.fn.writefile(lines, root .. '/' .. name)
  end
  write('main.cpp', { '#include <fstream>', 'int main() { std::ofstream("ran-first") << "ok"; }' })
  write('second.cpp', { '#include <fstream>', 'int main() { std::ofstream("ran-second") << "ok"; }' })
  write(
    'CMakeLists.txt',
    {
      'cmake_minimum_required(VERSION 3.20)',
      'project(run_binding LANGUAGES CXX)',
      'add_executable(first main.cpp)',
      'set_target_properties(first PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/custom/bin")',
    }
  )
  vim.cmd.edit(root .. '/main.cpp')
  local cmake = require 'code.home.cmake'
  local picks = 0
  vim.ui.select = function()
    error 'Single executable must not show a picker'
  end
  cmake.run(0)
  assert(
    vim.wait(30000, function()
      return vim.fn.filereadable(root .. '/ran-first') == 1
    end, 50),
    'single executable did not run'
  )
  vim.fn.delete(root .. '/ran-first')
  local lines = vim.fn.readfile(root .. '/CMakeLists.txt')
  lines[#lines + 1] = 'add_executable(second second.cpp)'
  write('CMakeLists.txt', lines)
  vim.ui.select = function(items, opts, callback)
    picks = picks + 1
    assert(#items == 2)
    assert(items[1].name == 'first' and items[2].name == 'second')
    callback(items[2])
  end
  cmake.run(0)
  assert(
    vim.wait(30000, function()
      return vim.fn.filereadable(root .. '/ran-second') == 1
    end, 50),
    'chosen executable did not run'
  )
  assert(picks == 1 and vim.fn.filereadable(root .. '/ran-first') == 0)
  vim.ui.select = function(_, _, callback)
    picks = picks + 1
    callback(nil)
  end
  vim.fn.delete(root .. '/ran-second')
  cmake.run(0)
  assert(
    vim.wait(30000, function()
      return picks == 2
    end, 50),
    'cancel picker did not appear'
  )
  assert(vim.fn.filereadable(root .. '/ran-second') == 0)
  assert(vim.fn.maparg('<leader>cx', 'n', false, true).desc == 'Build and run executable')
  print 'Run executable: single target, custom output path, multiple targets and cancellation passed'
end
local ok, message = xpcall(main, debug.traceback)
vim.fn.delete(root, 'rf')
if not ok then
  io.stderr:write(message .. '\n')
  vim.cmd 'cquit 1'
else
  vim.cmd 'qall!'
end
