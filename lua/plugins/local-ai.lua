local function env(name, fallback)
  local value = vim.env[name]
  if value == nil or value == '' then
    return fallback
  end

  return value
end

local ollama_model = env('CODECOMPANION_OLLAMA_MODEL', 'qwen3-coder:30b')
local ollama_num_ctx = tonumber(env('CODECOMPANION_OLLAMA_NUM_CTX', '32768')) or 32768

local function make_ollama_adapter(name, formatted_name, stream)
  return function()
    return require('codecompanion.adapters').extend('ollama', {
      name = name,
      formatted_name = formatted_name,
      env = {
        url = env('OLLAMA_HOST', 'http://127.0.0.1:11434'),
      },
      opts = {
        stream = stream,
      },
      schema = {
        model = {
          default = ollama_model,
        },
        num_ctx = {
          default = ollama_num_ctx,
        },
        keep_alive = {
          default = env('CODECOMPANION_OLLAMA_KEEP_ALIVE', '30m'),
        },
        temperature = {
          default = 0.2,
        },
        top_p = {
          default = 0.95,
        },
        think = {
          default = false,
        },
      },
    })
  end
end

return {
  {
    'olimorris/codecompanion.nvim',
    version = '^19.0.0',
    cmd = {
      'CodeCompanion',
      'CodeCompanionActions',
      'CodeCompanionChat',
      'CodeCompanionCmd',
    },
    keys = {
      { '<leader>ga', '<cmd>CodeCompanionActions<cr>', desc = '[A]I actions', mode = { 'n', 'v' } },
      { '<leader>gc', '<cmd>CodeCompanionChat Toggle<cr>', desc = '[A]I [c]hat' },
      { '<leader>gC', '<cmd>CodeCompanionChat<cr>', desc = '[A]I new [C]hat' },
      { '<leader>gi', ':CodeCompanion ', desc = '[A]I [i]nline prompt', mode = { 'n', 'v' } },
      { '<leader>gf', ':CodeCompanion /fix ', desc = '[A]I [f]ix selection', mode = 'v' },
      { '<leader>gt', ':CodeCompanion /tests ', desc = '[A]I [t]ests for selection', mode = 'v' },
    },
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
    },
    opts = {
      adapters = {
        http = {
          ollama_local = make_ollama_adapter('ollama_local', 'Ollama Local', true),
          ollama_local_inline = make_ollama_adapter('ollama_local_inline', 'Ollama Local Inline', false),
        },
      },
      interactions = {
        chat = {
          adapter = 'ollama_local',
        },
        inline = {
          adapter = 'ollama_local_inline',
        },
        cmd = {
          adapter = 'ollama_local_inline',
        },
        background = {
          adapter = 'ollama_local',
        },
      },
      opts = {
        log_level = 'INFO',
      },
    },
  },
}

-- vim: ts=2 sts=2 sw=2 et
