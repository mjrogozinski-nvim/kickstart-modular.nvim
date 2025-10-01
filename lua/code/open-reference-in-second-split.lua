-- it's from chatgpt, maybe to be refactored later, it works fine
-- <leader>v : go to definition in a vertical split, reuse another split if present
vim.keymap.set('n', '<leader>v', function()
  local bufnr = vim.api.nvim_get_current_buf()

  -- pick a position_encoding from an attached client, fallback to utf-16
  local clients = vim.lsp.get_clients { buffer = bufnr }
  local position_encoding = 'utf-16'
  if clients and next(clients) then
    position_encoding = clients[1].offset_encoding or position_encoding
  end

  -- required: pass window (0) and the position_encoding
  local params = vim.lsp.util.make_position_params(0, position_encoding)

  vim.lsp.buf_request(bufnr, 'textDocument/definition', params, function(err, result, _)
    if err then
      vim.notify(err.message or tostring(err), vim.log.levels.ERROR)
      return
    end
    if not result or vim.tbl_isempty(result) then
      vim.notify('No definition found', vim.log.levels.INFO)
      return
    end

    -- result may be a list of locations; pick the first (you can change this)
    local location = nil
    if vim.islist(result) then
      location = result[1]
    else
      location = result
    end

    -- Try to reuse "another" window (prefer the next window in the current tab).
    local cur_win = vim.api.nvim_get_current_win()
    local wins = vim.api.nvim_tabpage_list_wins(0)
    local target_win = nil

    for i, w in ipairs(wins) do
      if w == cur_win and i < #wins then
        target_win = wins[i + 1] -- prefer the next window if any
        break
      end
    end

    -- fallback to any other existing window
    if not target_win then
      for _, w in ipairs(wins) do
        if w ~= cur_win then
          target_win = w
          break
        end
      end
    end

    if target_win then
      vim.api.nvim_set_current_win(target_win)
    else
      vim.cmd 'vsplit'
    end

    -- show_document replaces the deprecated jump_to_location.
    -- pass the same position_encoding and set reuse_win/focus as desired.
    vim.lsp.util.show_document(location, position_encoding, { reuse_win = true, focus = true })
  end)
end, { desc = 'Goto Definition in Vertical Split (reuse existing split if present)' })
