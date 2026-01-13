local ts = vim.treesitter

local function print_gtest_name()
  local bufnr = vim.api.nvim_get_current_buf()
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1

  local parser = ts.get_parser(bufnr, 'cpp')
  local tree = parser:parse()[1]
  local root = tree:root()

  local query = ts.query.get('cpp', 'gtest-names')
  if not query then
    return
  end

  local fixture, test

  for id, node in query:iter_captures(root, bufnr, row, row + 1) do
    local name = query.captures[id]
    local text = ts.get_node_text(node, bufnr)

    if name == 'fixture.name' then
      fixture = text
    elseif name == 'test.name' then
      test = text
    end
  end

  if fixture and test then
    print(fixture .. '.' .. test)
  end
end

-- commnet for demonstration, print TestFixture.TestName when cursor hits line with TEST*
-- vim.api.nvim_create_autocmd('CursorHold', {
--   pattern = '*.cpp',
--   callback = print_gtest_name,
-- })
