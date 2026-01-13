-- visual mode -> saves targets from the range
-- normal mode -> save all target from the file
local function save_cmake_targets(opts)
  local buf = vim.api.nvim_get_current_buf()
  local lang = 'cmake'

  -- Default: whole buffer
  local start_row = 0
  local end_row = vim.api.nvim_buf_line_count(buf)

  -- If a range was provided (visual selection or explicit range)
  if opts and opts.range == 2 then
    -- opts.line1 and opts.line2 are 1-based, inclusive
    start_row = opts.line1 - 1
    end_row = opts.line2
  end

  local parser = vim.treesitter.get_parser(buf, lang)
  if not parser then
    vim.notify('No Tree-sitter parser for cmake', vim.log.levels.ERROR)
    return
  end

  local tree = parser:parse()[1]
  local root = tree:root()

  local query = vim.treesitter.query.get(lang, 'target-names')
  if not query then
    vim.notify('Could not load target-names query', vim.log.levels.ERROR)
    return
  end

  local targets = {}

  for id, node in query:iter_captures(root, buf, start_row, end_row) do
    if query.captures[id] == 'target.name' then
      table.insert(targets, vim.treesitter.get_node_text(node, buf))
    end
  end

  if #targets == 0 then
    vim.notify('No CMake targets found', vim.log.levels.WARN)
    return
  end

  local out_file = vim.fn.expand '~/cmake-targets.txt'
  vim.fn.writefile(targets, out_file)

  vim.notify(string.format('Saved %d CMake targets → %s', #targets, out_file), vim.log.levels.INFO)
end

vim.api.nvim_create_user_command('SaveCMakeTargets', function(opts)
  save_cmake_targets(opts)
end, {
  desc = 'Save CMake targets (whole file or visual selection)',
  range = true,
})
