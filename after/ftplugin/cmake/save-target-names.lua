local function save_cmake_targets()
  local buf = vim.api.nvim_get_current_buf()
  local lang = 'cmake'

  -- Get parser
  local parser = vim.treesitter.get_parser(buf, lang)
  if not parser then
    vim.notify('No Tree-sitter parser for cmake', vim.log.levels.ERROR)
    return
  end

  local tree = parser:parse()[1]
  local root = tree:root()

  -- Load your query: queries/cmake/target-names.scm
  local query = vim.treesitter.query.get(lang, 'target-names')
  if not query then
    vim.notify('Could not load target-names query', vim.log.levels.ERROR)
    return
  end

  local targets = {}

  for id, node in query:iter_captures(root, buf, 0, -1) do
    local capture = query.captures[id]
    if capture == 'target.name' then
      local text = vim.treesitter.get_node_text(node, buf)
      table.insert(targets, text)
    end
  end

  if #targets == 0 then
    vim.notify('No CMake targets found', vim.log.levels.WARN)
    return
  end

  local out_file = vim.fn.expand '~/cmake-targets.txt'
  vim.fn.writefile(targets, out_file)

  vim.notify(string.format('Saved %d CMake targets to %s', #targets, out_file), vim.log.levels.INFO)
end

vim.api.nvim_create_user_command('SaveCMakeTargets', save_cmake_targets, { desc = 'Extract CMake targets via Tree-sitter' })
