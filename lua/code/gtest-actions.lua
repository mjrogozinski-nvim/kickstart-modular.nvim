local M = {}

local api = vim.api
local ts = vim.treesitter
local uv = vim.uv
local namespace = api.nvim_create_namespace 'gtest-actions'
local cache = {}
local action_keymaps = {}

local function capture_map(query, match)
  local captures = {}

  for id, nodes in pairs(match) do
    if type(nodes) ~= 'table' then
      nodes = { nodes }
    end

    local name = query.captures[id]
    captures[name] = captures[name] or {}
    vim.list_extend(captures[name], nodes)
  end

  return captures
end

local function first_capture(captures, name)
  return captures[name] and captures[name][1] or nil
end

local function node_text(node, bufnr)
  return node and ts.get_node_text(node, bufnr) or nil
end

local function unqualified_base_name(base)
  base = base:gsub('%s+', '')
  return base:match '([%a_][%w_]*)<' or base:match '([%a_][%w_]*)$'
end

local function node_range(node)
  local start_row, start_col, end_row, end_col = node:range()
  return {
    start_row = start_row,
    start_col = start_col,
    end_row = end_row,
    end_col = end_col,
  }
end

local function make_filter(macro, suite, name)
  local filter = suite .. '.' .. name
  if macro == 'TEST_P' then
    return filter .. ':*/' .. filter .. '/*'
  end
  return filter
end

local function parse_items(bufnr)
  local ok_parser, parser = pcall(ts.get_parser, bufnr, 'cpp')
  local query = ts.query.get('cpp', 'gtest-names')
  if not ok_parser or not parser or not query then
    return {}
  end

  local tree = parser:parse()[1]
  if not tree then
    return {}
  end

  local tests = {}
  local classes = {}
  local root = tree:root()

  for _, match in query:iter_matches(root, bufnr) do
    local captures = capture_map(query, match)
    local test_node = first_capture(captures, 'test.definition')
    local class_node = first_capture(captures, 'fixture.definition')

    if test_node then
      local macro = node_text(first_capture(captures, 'test.macro'), bufnr)
      local suite = node_text(first_capture(captures, 'test.suite'), bufnr)
      local name = node_text(first_capture(captures, 'test.name'), bufnr)

      if macro and suite and name then
        local item = node_range(test_node)
        item.label = suite .. '.' .. name
        item.filter = make_filter(macro, suite, name)
        item.kind = 'test'
        tests[#tests + 1] = item
      end
    elseif class_node then
      local range = node_range(class_node)
      local key = table.concat({ range.start_row, range.start_col, range.end_row, range.end_col }, ':')
      local class = classes[key]

      if not class then
        class = range
        class.name = node_text(first_capture(captures, 'fixture.name'), bufnr)
        class.bases = {}
        classes[key] = class
      end

      for _, base_node in ipairs(captures['fixture.base'] or {}) do
        local base = unqualified_base_name(node_text(base_node, bufnr))
        if base then
          class.bases[base] = true
        end
      end
    end
  end

  local fixture_names = {}
  for _, class in pairs(classes) do
    if class.bases.Test or class.bases.TestWithParam then
      fixture_names[class.name] = true
    end
  end

  local changed = true
  while changed do
    changed = false
    for _, class in pairs(classes) do
      if not fixture_names[class.name] then
        for base in pairs(class.bases) do
          if fixture_names[base] then
            fixture_names[class.name] = true
            changed = true
            break
          end
        end
      end
    end
  end

  for _, class in pairs(classes) do
    if fixture_names[class.name] then
      class.label = class.name
      class.filter = class.name .. '.*:*/' .. class.name .. '.*/*'
      class.kind = 'fixture'
      class.bases = nil
      tests[#tests + 1] = class
    end
  end

  return tests
end

local function items(bufnr)
  local changedtick = api.nvim_buf_get_changedtick(bufnr)
  if not cache[bufnr] or cache[bufnr].changedtick ~= changedtick then
    cache[bufnr] = {
      changedtick = changedtick,
      items = parse_items(bufnr),
    }
  end
  return cache[bufnr].items
end

local function contains(item, row, col)
  local after_start = row > item.start_row or (row == item.start_row and col >= item.start_col)
  local before_end = row < item.end_row or (row == item.end_row and col < item.end_col)
  return after_start and before_end
end

function M.test_at_position(bufnr, row, col)
  local selected
  local selected_span

  for _, item in ipairs(items(bufnr)) do
    if contains(item, row, col) then
      local span = (item.end_row - item.start_row) * 1000000 + item.end_col - item.start_col
      if not selected_span or span < selected_span then
        selected = item
        selected_span = span
      end
    end
  end

  return selected
end

local function test_on_hint_line(bufnr)
  local row = api.nvim_win_get_cursor(0)[1] - 1
  for _, item in ipairs(items(bufnr)) do
    if item.start_row == row then
      return item
    end
  end
end

local function enable_action_keymaps(bufnr)
  if action_keymaps[bufnr] then
    return
  end

  vim.keymap.set('n', '<leader>cm', M.run_under_cursor, {
    buffer = bufnr,
    silent = true,
    desc = 'build and run GoogleTest on this line',
  })
  vim.keymap.set('n', '<leader>dm', M.debug_under_cursor, {
    buffer = bufnr,
    silent = true,
    desc = 'build and debug GoogleTest on this line',
  })
  action_keymaps[bufnr] = true
end

local function disable_action_keymaps(bufnr)
  if not action_keymaps[bufnr] then
    return
  end

  pcall(vim.keymap.del, 'n', '<leader>cm', { buffer = bufnr })
  pcall(vim.keymap.del, 'n', '<leader>dm', { buffer = bufnr })
  action_keymaps[bufnr] = nil
end

function M.update_hint(bufnr)
  if not api.nvim_buf_is_valid(bufnr) or api.nvim_get_current_buf() ~= bufnr then
    return
  end

  api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
  local item = test_on_hint_line(bufnr)
  if not item then
    disable_action_keymaps(bufnr)
    return
  end

  enable_action_keymaps(bufnr)
  api.nvim_buf_set_extmark(bufnr, namespace, item.start_row, -1, {
    virt_text = {
      { '  ▶ ', 'DiagnosticOk' },
      { 'run this test  ', 'Comment' },
      { '<leader>cm', 'DiagnosticInfo' },
      { ' - run  ', 'Comment' },
      { '·  ', 'NonText' },
      { '<leader>dm', 'DiagnosticInfo' },
      { ' - debug', 'Comment' },
    },
    virt_text_pos = 'eol',
    hl_mode = 'combine',
  })
end

local function project_paths(bufnr)
  local filename = api.nvim_buf_get_name(bufnr)
  local start = filename ~= '' and vim.fs.dirname(filename) or uv.cwd()
  local cmake_file = vim.fs.find('CMakeLists.txt', { path = start, upward = true })[1]
  if not cmake_file then
    return nil
  end

  local root = vim.fs.dirname(cmake_file)
  return root, root .. '/build'
end

local function task_then_success(definition, on_success)
  local overseer = require 'overseer'
  local success = require('overseer.constants').STATUS.SUCCESS
  local task = overseer.new_task(definition)

  task:subscribe('on_complete', function(_, status)
    if status == success then
      vim.schedule(on_success)
    end
    return true
  end)
  task:start()
end

local function ensure_compile_commands_link(root)
  local link = root .. '/compile_commands.json'
  if not uv.fs_lstat(link) then
    uv.fs_symlink('build/compile_commands.json', link)
  end
end

local function build_then(bufnr, on_success)
  local root, build_dir = project_paths(bufnr)
  if not root then
    vim.notify('No CMakeLists.txt found for this test', vim.log.levels.ERROR)
    return
  end

  local function build()
    task_then_success({
      name = 'build GoogleTest executable',
      cmd = { 'cmake', '--build', build_dir, '--parallel' },
      cwd = root,
      components = {
        { 'on_output_parse', problem_matcher = '$gcc' },
        { 'on_output_quickfix', open = false },
        'default',
      },
    }, function()
      on_success(root, build_dir)
    end)
  end

  if uv.fs_stat(build_dir .. '/CMakeCache.txt') then
    build()
    return
  end

  task_then_success({
    name = 'configure GoogleTest project',
    cmd = {
      'cmake',
      '-S',
      root,
      '-B',
      build_dir,
      '-DCMAKE_BUILD_TYPE=Debug',
      '-DCMAKE_EXPORT_COMPILE_COMMANDS=ON',
    },
    cwd = root,
    components = {
      { 'on_output_parse', problem_matcher = '$gcc' },
      { 'on_output_quickfix', open = false },
      'default',
    },
  }, function()
    ensure_compile_commands_link(root)
    build()
  end)
end

local function selected_test_or_notify(bufnr)
  local item = test_on_hint_line(bufnr)
  if not item then
    vim.notify('Cursor is not on a GoogleTest action hint', vim.log.levels.WARN)
  end
  return item
end

function M.run_under_cursor()
  local bufnr = api.nvim_get_current_buf()
  local item = selected_test_or_notify(bufnr)
  if not item then
    return
  end

  require('code.utils.save-all-writable-buffers')()
  local root, build_dir = project_paths(bufnr)
  if not root then
    vim.notify('No CMakeLists.txt found for this test', vim.log.levels.ERROR)
    return
  end

  ensure_compile_commands_link(root)
  local tasks = {}

  if not uv.fs_stat(build_dir .. '/CMakeCache.txt') then
    tasks[#tasks + 1] = {
      name = 'configure',
      cmd = {
        'cmake',
        '-S',
        root,
        '-B',
        build_dir,
        '-DCMAKE_BUILD_TYPE=Debug',
        '-DCMAKE_EXPORT_COMPILE_COMMANDS=ON',
      },
      cwd = root,
      components = {
        { 'on_output_parse', problem_matcher = '$gcc' },
        { 'on_output_quickfix', open = false },
        'default',
      },
    }
  end

  tasks[#tasks + 1] = {
    name = 'build',
    cmd = { 'cmake', '--build', build_dir, '--parallel' },
    cwd = root,
    components = {
      { 'on_output_parse', problem_matcher = '$gcc' },
      { 'on_output_quickfix', open = false },
      'default',
    },
  }
  tasks[#tasks + 1] = {
    name = 'execute ' .. item.label,
    cmd = { build_dir .. '/app', '--gtest_filter=' .. item.filter },
    cwd = root,
    components = {
      { 'open_output', direction = 'dock', focus = false, on_start = 'always' },
      'default',
    },
  }

  require('overseer').new_task {
    name = 'run ' .. item.label,
    cwd = root,
    strategy = {
      'orchestrator',
      tasks = tasks,
    },
    components = { 'default' },
  }:start()
end

function M.debug_under_cursor()
  local bufnr = api.nvim_get_current_buf()
  local item = selected_test_or_notify(bufnr)
  if not item then
    return
  end

  require('code.utils.save-all-writable-buffers')()
  build_then(bufnr, function(root, build_dir)
    local executable = build_dir .. '/app'
    if not uv.fs_stat(executable) then
      vim.notify('GoogleTest executable not found: ' .. executable, vim.log.levels.ERROR)
      return
    end

    local dap = require 'dap'
    if not dap.adapters.codelldb then
      vim.notify('codelldb is not available; install it with :MasonInstall codelldb', vim.log.levels.ERROR)
      return
    end

    dap.run {
      name = 'debug ' .. item.label,
      type = 'codelldb',
      request = 'launch',
      program = executable,
      cwd = root,
      args = { '--gtest_filter=' .. item.filter },
      stopOnEntry = false,
    }
  end)
end

function M.setup_buffer(bufnr)
  bufnr = bufnr or api.nvim_get_current_buf()
  if vim.b[bufnr].gtest_actions_setup then
    return
  end
  vim.b[bufnr].gtest_actions_setup = true

  pcall(ts.start, bufnr, 'cpp')

  local group = api.nvim_create_augroup('GtestActions' .. bufnr, { clear = true })
  api.nvim_create_autocmd({ 'BufEnter', 'CursorMoved', 'CursorMovedI', 'TextChanged', 'TextChangedI' }, {
    group = group,
    buffer = bufnr,
    callback = function()
      M.update_hint(bufnr)
    end,
  })
  api.nvim_create_autocmd('BufWipeout', {
    group = group,
    buffer = bufnr,
    callback = function()
      cache[bufnr] = nil
      action_keymaps[bufnr] = nil
    end,
  })

  vim.schedule(function()
    M.update_hint(bufnr)
  end)
end

return M
