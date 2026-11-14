-- Shared CMake actions. Resolve each invocation from its buffer, not editor cwd.
local M = {}
local components = require 'code.utils.overseer-components'
local selections = {}

local function notify(message)
  vim.notify(message, vim.log.levels.ERROR)
end

local function task(name, root, tasks, done)
  local overseer = require 'overseer'
  local parent = overseer.new_task {
    name = name,
    cwd = root,
    strategy = { 'orchestrator', tasks = tasks },
    components = { 'default' },
  }
  if done then
    parent:subscribe('on_complete', function(_, status)
      if status == require('overseer.constants').STATUS.SUCCESS then
        vim.schedule(done)
      end
      return true
    end)
  end
  parent:start()
end

local function presets(root, done)
  if not vim.uv.fs_stat(root .. '/CMakePresets.json') and not vim.uv.fs_stat(root .. '/CMakeUserPresets.json') then
    done(nil)
    return
  end
  vim.system(
    { 'cmake', '--list-presets' },
    { cwd = root, text = true },
    vim.schedule_wrap(function(result)
      if result.code ~= 0 then
        notify(result.stderr)
        return
      end
      local names = {}
      for name in result.stdout:gmatch '\n%s+"([^"]+)"' do
        names[#names + 1] = name
      end
      if #names == 0 then
        done(nil)
        return
      end
      -- Shell toolchain names are useful only when they match an actual preset.
      local preferred = selections[root] or vim.g.cpp_cmake_preset or vim.env.CMAKE_PRESET or vim.env.CXX_TOOLCHAIN
      if vim.tbl_contains(names, preferred) then
        done(preferred)
      elseif #names == 1 then
        done(names[1])
      else
        vim.ui.select(names, { prompt = 'CMake configure preset:' }, function(name)
          if name then
            selections[root] = name
            done(name)
          end
        end)
      end
    end)
  )
end

-- Configure separately: CMake reports the actual binary directory, including
-- inherited presets, includes, macros and external build directories.
function M.build(bufnr, done, codemodel)
  local root = require 'code.utils.project-root'({ 'CMakePresets.json', 'CMakeUserPresets.json', 'CMakeLists.txt' }, bufnr)
  if not root then
    notify 'No CMake project found for this buffer'
    return
  end
  require 'code.utils.save-all-writable-buffers'()
  presets(root, function(preset)
    local cmd = preset and { 'cmake', '--preset', preset }
      or {
        'cmake',
        '-S',
        root,
        '-B',
        root .. '/build',
        '-DCMAKE_BUILD_TYPE=Debug',
      }
    cmd[#cmd + 1] = '-DCMAKE_EXPORT_COMPILE_COMMANDS=ON'
    local configure = require('overseer').new_task {
      name = 'configure',
      strategy = { 'jobstart', use_terminal = false },
      cmd = cmd,
      cwd = root,
      components = components.build_output(),
    }
    configure:subscribe('on_complete', function(current, status)
      if status == require('overseer.constants').STATUS.SUCCESS then
        local output = table.concat(vim.api.nvim_buf_get_lines(current:get_bufnr(), 0, -1, false), '\n')
        local build_dir = output:match 'Build files have been written to: ([^\r\n]+)'
        vim.schedule(function()
          if not build_dir then
            notify 'CMake did not report its build directory'
            return
          end
          local config = vim.g.cpp_cmake_config
          if not config then
            local cache = build_dir .. '/CMakeCache.txt'
            local contents = vim.fn.filereadable(cache) == 1 and table.concat(vim.fn.readfile(cache), '\n') or ''
            config = contents:match 'CMAKE_BUILD_TYPE:STRING=([^\r\n]+)' or 'Debug'
          end
          local context = { root = root, build_dir = build_dir, config = config }
          -- Never replace a project's existing compilation database.
          local link = root .. '/compile_commands.json'
          if not vim.uv.fs_lstat(link) and vim.uv.fs_stat(build_dir .. '/compile_commands.json') then
            vim.uv.fs_symlink(build_dir .. '/compile_commands.json', link)
          end
          local tasks = {}
          if codemodel then
            local query_dir = build_dir .. '/.cmake/api/v1/query'
            local query = query_dir .. '/codemodel-v2'
            if not vim.uv.fs_stat(query) then
              vim.fn.mkdir(query_dir, 'p')
              vim.fn.writefile({}, query)
              -- The first configure located the binary directory. Repeat once
              -- to request CMake's target metadata for this build tree.
              tasks[#tasks + 1] = {
                name = 'discover executable targets',
                cmd = cmd,
                cwd = root,
                components = components.build_output(),
              }
            end
          end
          tasks[#tasks + 1] = {
            name = 'build',
            cmd = { 'cmake', '--build', build_dir, '--config', config, '--parallel' },
            cwd = root,
            components = components.build_output(),
          }
          task('build project', root, tasks, done and function()
            done(context)
          end)
        end)
      end
      return true
    end)
    configure:start()
  end)
end

function M.test(bufnr)
  M.build(bufnr, function(context)
    task('run all tests', context.root, {
      {
        name = 'test',
        cmd = { 'ctest', '--test-dir', context.build_dir, '-C', context.config, '--output-on-failure' },
        cwd = context.root,
        components = components.dock_output(),
      },
    })
  end)
end

local function executable_targets(context)
  local reply_dir = context.build_dir .. '/.cmake/api/v1/reply/'
  local indexes = vim.fn.glob(reply_dir .. 'index-*.json', false, true)
  table.sort(indexes)
  local function read_json(path)
    return vim.json.decode(table.concat(vim.fn.readfile(path), '\n'))
  end
  local index = read_json(assert(indexes[#indexes], 'CMake did not generate target metadata'))
  local reply = assert(index.reply['codemodel-v2'], 'CMake codemodel reply is missing')
  local model = read_json(reply_dir .. assert(reply.jsonFile, reply.error))
  local configuration
  for _, candidate in ipairs(model.configurations or {}) do
    if candidate.name == context.config or candidate.name == '' then
      configuration = candidate
      break
    end
  end
  assert(configuration, 'CMake configuration not found: ' .. context.config)
  local targets = {}
  for _, reference in ipairs(configuration.targets or {}) do
    local target = read_json(reply_dir .. reference.jsonFile)
    if target.type == 'EXECUTABLE' and target.artifacts and target.artifacts[1] then
      local path = target.artifacts[1].path
      if not vim.startswith(path, '/') then
        path = context.build_dir .. '/' .. path
      end
      targets[#targets + 1] = { name = target.name, path = path }
    end
  end
  table.sort(targets, function(left, right)
    return left.name < right.name
  end)
  return targets
end

function M.run(bufnr)
  M.build(bufnr, function(context)
    local ok, targets = pcall(executable_targets, context)
    if not ok then
      notify('Cannot discover CMake executables: ' .. tostring(targets))
      return
    end
    local function execute(target)
      if not target then
        return
      end
      task(
        'run ' .. target.name,
        context.root,
        { {
          name = 'execute ' .. target.name,
          cmd = { target.path },
          cwd = context.root,
          components = components.dock_output(),
        } }
      )
    end
    if #targets == 0 then
      vim.notify('No executable targets in this CMake project', vim.log.levels.WARN)
    elseif #targets == 1 then
      execute(targets[1])
    else
      vim.ui.select(targets, {
        prompt = 'Run executable:',
        format_item = function(target)
          return target.name .. ' — ' .. target.path
        end,
      }, execute)
    end
  end, true)
end

function M.gtest(item, bufnr, debug)
  M.build(bufnr, function(context)
    vim.system(
      { 'ctest', '--test-dir', context.build_dir, '-C', context.config, '--show-only=json-v1' },
      { cwd = context.root, text = true },
      vim.schedule_wrap(function(result)
        local ok, data = pcall(vim.json.decode, result.stdout or '')
        if result.code ~= 0 or not ok then
          notify('Cannot discover CTest executables: ' .. (result.stderr or ''))
          return
        end
        local candidates, seen = {}, {}
        for _, test in ipairs(data.tests or {}) do
          local command = test.command
          if command and command[1] and vim.fn.executable(command[1]) == 1 then
            local cwd = context.build_dir
            for _, property in ipairs(test.properties or {}) do
              if property.name == 'WORKING_DIRECTORY' then
                cwd = property.value
              end
            end
            local key = command[1] .. '\n' .. cwd
            if not seen[key] then
              seen[key] = true
              candidates[#candidates + 1] = { program = command[1], cwd = cwd }
            end
          end
        end
        local function execute(candidate)
          if not candidate then
            return
          end
          local args = { '--gtest_filter=' .. item.data.filter }
          if debug then
            local dap = require 'dap'
            if not dap.adapters.codelldb then
              notify 'codelldb is not configured'
              return
            end
            dap.run {
              name = 'debug ' .. item.data.label,
              type = 'codelldb',
              request = 'launch',
              program = candidate.program,
              cwd = candidate.cwd,
              args = args,
              stopOnEntry = false,
            }
          else
            task('run ' .. item.data.label, context.root, {
              {
                name = 'execute ' .. item.data.label,
                cmd = { candidate.program, unpack(args) },
                cwd = candidate.cwd,
                components = components.dock_output(),
              },
            })
          end
        end
        if #candidates == 1 then
          execute(candidates[1])
        elseif #candidates > 1 then
          vim.ui.select(candidates, {
            prompt = 'GoogleTest executable:',
            format_item = function(candidate)
              return candidate.program
            end,
          }, execute)
        else
          vim.ui.input({ prompt = 'GoogleTest executable: ', default = context.build_dir .. '/', completion = 'file' }, function(path)
            if path and path ~= '' then
              if vim.fn.executable(path) == 1 then
                execute { program = path, cwd = context.build_dir }
              else
                notify('Executable not found: ' .. path)
              end
            end
          end)
        end
      end)
    )
  end)
end

return M
