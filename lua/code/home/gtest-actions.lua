local M = {}

local api = vim.api
local actions = require 'code.treesitter-actions'

local function unqualified_base_name(base)
  base = base:gsub('%s+', '')
  return base:match '([%a_][%w_]*)<' or base:match '([%a_][%w_]*)$'
end

local function make_filter(macro, suite, name)
  local filter = suite .. '.' .. name
  if macro == 'TEST_P' then
    return filter .. ':*/' .. filter .. '/*'
  end
  return filter
end

local function run_item(item, bufnr)
  require('code.home.cmake').gtest(item, bufnr, false)
end

local function debug_item(item, bufnr)
  require('code.home.cmake').gtest(item, bufnr, true)
end

local function contextual_item(range, data)
  return {
    range = range,
    data = data,
    hint = {
      icon = { '▶', 'DiagnosticOk' },
      text = { 'run this test', 'Comment' },
    },
    actions = {
      {
        lhs = '<leader>cm',
        label = 'run',
        desc = 'build and run GoogleTest on this line',
        callback = function(item, bufnr)
          run_item(item, bufnr)
        end,
      },
      {
        lhs = '<leader>dm',
        label = 'debug',
        desc = 'build and debug GoogleTest on this line',
        callback = function(item, bufnr)
          debug_item(item, bufnr)
        end,
      },
    },
  }
end

local function detect(context)
  local tests = {}
  local classes = {}

  for _, match in ipairs(context.matches) do
    local captures = match.captures
    local test_node = context.first_capture(captures, 'test.definition')
    local class_node = context.first_capture(captures, 'fixture.definition')

    if test_node then
      local macro = context.node_text(context.first_capture(captures, 'test.macro'))
      local suite = context.node_text(context.first_capture(captures, 'test.suite'))
      local name = context.node_text(context.first_capture(captures, 'test.name'))

      if macro and suite and name then
        tests[#tests + 1] = contextual_item(context.node_range(test_node), {
          kind = 'test',
          label = suite .. '.' .. name,
          filter = make_filter(macro, suite, name),
        })
      end
    elseif class_node then
      local range = context.node_range(class_node)
      local key = table.concat({ range.start_row, range.start_col, range.end_row, range.end_col }, ':')
      local class = classes[key]

      if not class then
        class = {
          range = range,
          name = context.node_text(context.first_capture(captures, 'fixture.name')),
          bases = {},
        }
        classes[key] = class
      end

      for _, base_node in ipairs(captures['fixture.base'] or {}) do
        local base = unqualified_base_name(context.node_text(base_node))
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
      tests[#tests + 1] = contextual_item(class.range, {
        kind = 'fixture',
        label = class.name,
        filter = class.name .. '.*:*/' .. class.name .. '.*/*',
      })
    end
  end

  table.sort(tests, function(left, right)
    if left.range.start_row == right.range.start_row then
      return left.range.start_col < right.range.start_col
    end
    return left.range.start_row < right.range.start_row
  end)
  return tests
end

M.provider = {
  id = 'gtest',
  language = 'cpp',
  query = 'gtest-names',
  priority = 100,
  detect = detect,
}

local function active_gtest_item(bufnr)
  for _, item in ipairs(actions.active_items(bufnr)) do
    if item.provider_id == M.provider.id then
      return item
    end
  end
end

local function selected_or_notify()
  local bufnr = api.nvim_get_current_buf()
  local item = active_gtest_item(bufnr)
  if not item then
    vim.notify('Cursor is not on a GoogleTest action hint', vim.log.levels.WARN)
  end
  return item, bufnr
end

function M.run_under_cursor()
  local item, bufnr = selected_or_notify()
  if item then
    run_item(item, bufnr)
  end
end

function M.debug_under_cursor()
  local item, bufnr = selected_or_notify()
  if item then
    debug_item(item, bufnr)
  end
end

function M.test_at_position(bufnr, row, col)
  local item = actions.item_at_position(bufnr, M.provider.id, row, col)
  return item and item.data or nil
end

function M.update_hint(bufnr)
  actions.refresh(bufnr)
end

function M.setup_buffer(bufnr)
  actions.attach(bufnr or api.nvim_get_current_buf(), M.provider)
end

return M
