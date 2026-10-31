return {
  'zgs225/pi2.nvim',
  dependencies = { 'MeanderingProgrammer/render-markdown.nvim' },
  opts = {
    cli = { args = { '--provider', 'ollama', '--model', 'qwen3.8:27b-mtp-bf16' } },
    -- Provider URLs and credentials are inherited from ~/.pi/agent/models.json.
    models = { 'qwen3.8:27b-mtp-bf16', 'mtplx/mtplx-qwen38-27b-optimized-speed', 'deepseek-v4.1-flash' },
    -- Keep Space-prefixed shortcuts out of insert mode to avoid typing delays.
    zen = { keys = { toggle = { '<leader>az', modes = { 'n' } } } },
  },
  config = function(_, opts)
    require('pi').setup(opts)
    require('code.pi-local-models').setup()
    -- Pi is loaded after the general Tree-sitter FileType list is built.
    -- Its custom history filetype therefore needs an explicit highlighter.
    vim.api.nvim_create_autocmd('FileType', {
      group = vim.api.nvim_create_augroup('PiMarkdownHighlight', { clear = true }),
      pattern = 'pi-chat-history',
      callback = function(event)
        vim.treesitter.start(event.buf, 'markdown')
        -- Pi's built-in zen toggle only handles the prompt input buffer.
        vim.keymap.set('n', '<leader>az', function()
          -- Pi redirects WinEnter on history buffers back to the prompt.
          -- Suppress that event while opening/closing the reading window.
          local eventignore = vim.o.eventignore
          vim.opt.eventignore:append('WinEnter')
          local ok, err = pcall(function()
            Snacks.zen({
              toggles = {},
              win = { width = opts.zen.width or 100, wo = { wrap = true } },
            })
          end)
          vim.o.eventignore = eventignore
          if not ok then
            error(err)
          end
        end, { buffer = event.buf, nowait = true, desc = 'Toggle Pi response zen mode' })
      end,
    })
  end,
  keys = {
    { '<leader>ai', '<cmd>Pi<cr>', desc = 'Pi chat' },
    { '<leader>am', '<cmd>PiSelectModel<cr>', desc = 'Pi select local model' },
    { '<leader>ar', '<cmd>PiResume<cr>', desc = 'Pi resume session' },
    { '<leader>as', ':PiSendMention<cr>', mode = { 'n', 'x' }, desc = 'Pi mention file or selection' },
  },
}
