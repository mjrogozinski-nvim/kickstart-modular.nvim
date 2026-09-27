return {
  'alex35mil/pi.nvim',
  opts = {
    cli = { args = { "--provider", "ollama", "--model", "qwen3.8:27b-mtp-bf16" } },
    -- Provider URLs and credentials are inherited from ~/.pi/agent/models.json.
    models = { 'qwen3.8:27b-mtp-bf16', 'deepseek-v4.1-flash' },
  },
  keys = {
    { '<leader>ai', '<cmd>Pi<cr>', desc = 'Pi chat' },
    { '<leader>am', '<cmd>PiSelectModel<cr>', desc = 'Pi select local model' },
    { '<leader>ar', '<cmd>PiResume<cr>', desc = 'Pi resume session' },
    { '<leader>as', ':PiSendMention<cr>', mode = { 'n', 'x' }, desc = 'Pi mention file or selection' },
  },
}
