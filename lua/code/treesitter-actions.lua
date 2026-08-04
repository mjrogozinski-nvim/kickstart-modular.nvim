local M = {}

local api = vim.api
local ts = vim.treesitter
local namespace = api.nvim_create_namespace 'treesitter-actions'
local states = {}
local warned_collisions = {}

local function capture_map(query, match)
  local captures = {}

  for id, nodes in pairs(match) do
    if type(nodes) ~= 'table' then
      nodes = { nodes }
    end

    local name = query.captures[id]
    if name then
      captures[name] = captures[name] or {}
      vim.list_extend(captures[name], nodes)
    end
  end

  return captures
end

local function first_capture(captures, name)
  return captures[name] and captures[name][1] or nil
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

local function contains(item, row, col)
  local range = item.range
  local after_start = row > range.start_row or (row == range.start_row and col >= range.start_col)
  local before_end = row < range.end_row or (row == range.end_row and col < range.end_col)
  return after_start and before_end
end

local function provider_context(bufnr, provider, query, root)
  local matches = {}

  for pattern, match, metadata in query:iter_matches(root, bufnr) do
    matches[#matches + 1] = {
      captures = capture_map(query, match),
      metadata = metadata,
      pattern = pattern,
    }
  end

  return {
    bufnr = bufnr,
    language = provider.language,
    matches = matches,
    first_capture = first_capture,
    node_text = function(node)
      return node and ts.get_node_text(node, bufnr) or nil
    end,
    node_range = node_range,
  }
end

local function detect_items(bufnr, provider)
  local ok_parser, parser = pcall(ts.get_parser, bufnr, provider.language)
  local ok_query, query = pcall(ts.query.get, provider.language, provider.query)
  if not ok_parser or not parser or not ok_query or not query then
    return {}
  end

  local tree = parser:parse()[1]
  if not tree then
    return {}
  end

  local ok, detected = pcall(provider.detect, provider_context(bufnr, provider, query, tree:root()))
  if not ok then
    vim.notify(('Tree-sitter action provider %q failed: %s'):format(provider.id, detected), vim.log.levels.ERROR)
    return {}
  end

  local items = {}
  for index, item in ipairs(detected or {}) do
    if item.range and item.range.start_row ~= nil and item.actions then
      item.provider_id = provider.id
      item._provider = provider
      item._order = index
      items[#items + 1] = item
    end
  end
  return items
end

local function provider_items(state, provider)
  local changedtick = api.nvim_buf_get_changedtick(state.bufnr)
  local cached = state.cache[provider.id]
  if not cached or cached.changedtick ~= changedtick or cached.provider ~= provider then
    cached = {
      changedtick = changedtick,
      provider = provider,
      items = detect_items(state.bufnr, provider),
    }
    state.cache[provider.id] = cached
  end
  return cached.items
end

local function local_mapping(mode, lhs)
  local mapping = vim.fn.maparg(lhs, mode, false, true)
  if type(mapping) == 'table' and mapping.buffer == 1 then
    return mapping
  end
end

local function restore_mapping(mode, mapping)
  if vim.fn.exists '*mapset' == 1 then
    vim.fn.mapset(mode, false, mapping)
    return
  end

  local rhs = mapping.callback or mapping.rhs
  vim.keymap.set(mode, mapping.lhs, rhs, {
    buffer = true,
    desc = mapping.desc,
    expr = mapping.expr == 1,
    nowait = mapping.nowait == 1,
    remap = mapping.noremap ~= 1,
    silent = mapping.silent == 1,
  })
end

local function deactivate(state)
  if api.nvim_buf_is_valid(state.bufnr) then
    api.nvim_buf_clear_namespace(state.bufnr, namespace, 0, -1)
  end

  local function restore_keymaps()
    for _, installed in pairs(state.installed) do
      pcall(vim.keymap.del, installed.mode, installed.lhs, { buffer = state.bufnr })
      if installed.previous then
        restore_mapping(installed.mode, installed.previous)
      end
    end
  end

  if api.nvim_buf_is_valid(state.bufnr) then
    if api.nvim_get_current_buf() == state.bufnr then
      restore_keymaps()
    else
      pcall(api.nvim_buf_call, state.bufnr, restore_keymaps)
    end
  end

  state.active_items = {}
  state.installed = {}
end

local function action_priority(candidate)
  return candidate.action.priority or candidate.provider.priority or 0
end

local function winning_actions(active_items)
  local winners = {}
  local ordered = {}

  for _, item in ipairs(active_items) do
    for action_index, action in ipairs(item.actions) do
      local candidate = {
        action = action,
        action_index = action_index,
        item = item,
        provider = item._provider,
      }
      local mode = action.mode or 'n'
      local key = mode .. '\0' .. action.lhs
      local winner = winners[key]

      if not winner or action_priority(candidate) > action_priority(winner) then
        winners[key] = candidate
      elseif action_priority(candidate) == action_priority(winner) then
        local warning_key = table.concat({ key, winner.provider.id, candidate.provider.id }, '\0')
        if not warned_collisions[warning_key] then
          warned_collisions[warning_key] = true
          vim.schedule(function()
            vim.notify(
              ('Tree-sitter actions: %s and %s both define %s; keeping %s'):format(winner.provider.id, candidate.provider.id, action.lhs, winner.provider.id),
              vim.log.levels.WARN
            )
          end)
        end
      end
    end
  end

  for _, item in ipairs(active_items) do
    for action_index, action in ipairs(item.actions) do
      local key = (action.mode or 'n') .. '\0' .. action.lhs
      local winner = winners[key]
      if winner and winner.item == item and winner.action_index == action_index then
        ordered[#ordered + 1] = winner
      end
    end
  end

  return ordered
end

local function hint_chunks(active_items, winners)
  local won = {}
  for _, winner in ipairs(winners) do
    won[winner.item] = won[winner.item] or {}
    won[winner.item][winner.action_index] = true
  end

  local chunks = {}
  local visible_groups = 0
  for _, item in ipairs(active_items) do
    local visible_actions = won[item]
    if visible_actions then
      if visible_groups > 0 then
        chunks[#chunks + 1] = { '  │  ', 'NonText' }
      end
      visible_groups = visible_groups + 1

      local hint = item.hint or {}
      local icon = hint.icon or { '▶', 'DiagnosticOk' }
      local title = hint.text or { item._provider.id, 'Comment' }
      chunks[#chunks + 1] = { (visible_groups == 1 and '  ' or '') .. icon[1] .. ' ', icon[2] or 'DiagnosticOk' }
      chunks[#chunks + 1] = { title[1] .. '  ', title[2] or 'Comment' }

      local action_count = 0
      for action_index, action in ipairs(item.actions) do
        if visible_actions[action_index] then
          if action_count > 0 then
            chunks[#chunks + 1] = { ' · ', 'NonText' }
          end
          action_count = action_count + 1
          chunks[#chunks + 1] = { action.lhs, action.key_hl or 'DiagnosticInfo' }
          chunks[#chunks + 1] = { ' - ' .. action.label, action.label_hl or 'Comment' }
        end
      end
    end
  end
  return chunks
end

local function active_items_on_line(state, row)
  local active = {}
  for _, provider in ipairs(state.providers) do
    for _, item in ipairs(provider_items(state, provider)) do
      if item.range.start_row == row then
        active[#active + 1] = item
      end
    end
  end
  return active
end

function M.refresh(bufnr)
  bufnr = bufnr or api.nvim_get_current_buf()
  local state = states[bufnr]
  if not state then
    return
  end

  deactivate(state)
  if not api.nvim_buf_is_valid(bufnr) or api.nvim_get_current_buf() ~= bufnr then
    return
  end

  local row = api.nvim_win_get_cursor(0)[1] - 1
  local active_items = active_items_on_line(state, row)
  local winners = winning_actions(active_items)
  state.active_items = active_items

  for _, winner in ipairs(winners) do
    local action = winner.action
    local mode = action.mode or 'n'
    local key = mode .. '\0' .. action.lhs
    state.installed[key] = {
      lhs = action.lhs,
      mode = mode,
      previous = local_mapping(mode, action.lhs),
    }
    vim.keymap.set(mode, action.lhs, function()
      action.callback(winner.item, bufnr)
    end, {
      buffer = bufnr,
      desc = action.desc,
      nowait = action.nowait,
      silent = action.silent ~= false,
    })
  end

  local chunks = hint_chunks(active_items, winners)
  if #chunks > 0 then
    api.nvim_buf_set_extmark(bufnr, namespace, row, -1, {
      virt_text = chunks,
      virt_text_pos = 'eol',
      hl_mode = 'combine',
    })
  end
end

local function normalize_providers(providers)
  if providers.id then
    return { providers }
  end
  return providers
end

function M.attach(bufnr, providers)
  bufnr = bufnr or api.nvim_get_current_buf()
  providers = normalize_providers(providers)

  local state = states[bufnr]
  if not state then
    state = {
      bufnr = bufnr,
      providers = {},
      provider_indexes = {},
      cache = {},
      installed = {},
      active_items = {},
    }
    states[bufnr] = state

    local group = api.nvim_create_augroup('TreesitterActions' .. bufnr, { clear = true })
    api.nvim_create_autocmd({ 'BufEnter', 'CursorMoved', 'CursorMovedI', 'TextChanged', 'TextChangedI', 'WinEnter' }, {
      group = group,
      buffer = bufnr,
      callback = function()
        M.refresh(bufnr)
      end,
    })
    api.nvim_create_autocmd('BufLeave', {
      group = group,
      buffer = bufnr,
      callback = function()
        deactivate(state)
      end,
    })
    api.nvim_create_autocmd('BufWipeout', {
      group = group,
      buffer = bufnr,
      callback = function()
        deactivate(state)
        states[bufnr] = nil
      end,
    })
  end

  for _, provider in ipairs(providers) do
    assert(type(provider.id) == 'string', 'Tree-sitter action provider requires an id')
    assert(type(provider.language) == 'string', 'Tree-sitter action provider requires a language')
    assert(type(provider.query) == 'string', 'Tree-sitter action provider requires a query')
    assert(type(provider.detect) == 'function', 'Tree-sitter action provider requires detect()')

    local index = state.provider_indexes[provider.id]
    if index then
      state.providers[index] = provider
      state.cache[provider.id] = nil
    else
      state.providers[#state.providers + 1] = provider
      state.provider_indexes[provider.id] = #state.providers
    end
    pcall(ts.start, bufnr, provider.language)
  end

  vim.schedule(function()
    M.refresh(bufnr)
  end)
end

function M.get_items(bufnr, provider_id)
  local state = states[bufnr]
  if not state then
    return {}
  end

  local result = {}
  for _, provider in ipairs(state.providers) do
    if not provider_id or provider.id == provider_id then
      vim.list_extend(result, provider_items(state, provider))
    end
  end
  return result
end

function M.item_at_position(bufnr, provider_id, row, col)
  local selected
  local selected_span
  for _, item in ipairs(M.get_items(bufnr, provider_id)) do
    if contains(item, row, col) then
      local range = item.range
      local span = (range.end_row - range.start_row) * 1000000 + range.end_col - range.start_col
      if not selected_span or span < selected_span then
        selected = item
        selected_span = span
      end
    end
  end
  return selected
end

function M.active_items(bufnr)
  local state = states[bufnr or api.nvim_get_current_buf()]
  return state and vim.list_slice(state.active_items) or {}
end

return M
