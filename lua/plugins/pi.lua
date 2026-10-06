return {
  'zgs225/pi2.nvim',
  dependencies = { 'MeanderingProgrammer/render-markdown.nvim' },
  opts = {
    cli = { args = { '--provider', 'ollama', '--model', 'qwen3.8:27b-mtp-bf16' } },
    -- Provider URLs and credentials are inherited from ~/.pi/agent/models.json.
    models = { 'qwen3.8:27b-mtp-bf16', 'deepseek-v4.1-flash' },
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
