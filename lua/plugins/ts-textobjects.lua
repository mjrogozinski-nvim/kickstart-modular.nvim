return {
  'nvim-treesitter/nvim-treesitter-textobjects',
  branch = 'main',
  dependencies = { 'nvim-treesitter/nvim-treesitter', branch = 'main' },
  init = function()
    vim.g.no_plugin_maps = true
  end,
  config = function()
    require('nvim-treesitter-textobjects').setup {
      select = {
        lookahead = true,
        selection_modes = {
          ['@parameter.outer'] = 'v',
          ['@function.outer'] = 'V',
          ['@class.outer'] = '<c-v>',
        },
        include_surrounding_whitespace = true,
      },
      move = {
        set_jumps = true,
      },
    }

    local select = require 'nvim-treesitter-textobjects.select'
    vim.keymap.set({ 'x', 'o' }, 'af', function()
      select.select_textobject('@function.outer', 'textobjects')
    end, { desc = 'Select outer function' })
    vim.keymap.set({ 'x', 'o' }, 'if', function()
      select.select_textobject('@function.inner', 'textobjects')
    end, { desc = 'Select inner function' })
    vim.keymap.set({ 'x', 'o' }, 'ac', function()
      select.select_textobject('@class.outer', 'textobjects')
    end, { desc = 'Select outer class' })
    vim.keymap.set({ 'x', 'o' }, 'ic', function()
      select.select_textobject('@class.inner', 'textobjects')
    end, { desc = 'Select inner class' })
    vim.keymap.set({ 'x', 'o' }, 'aa', function()
      select.select_textobject('@parameter.outer', 'textobjects')
    end, { desc = 'Select outer parameter' })
    vim.keymap.set({ 'x', 'o' }, 'ia', function()
      select.select_textobject('@parameter.inner', 'textobjects')
    end, { desc = 'Select inner parameter' })
    vim.keymap.set({ 'x', 'o' }, 'as', function()
      select.select_textobject('@local.scope', 'locals')
    end, { desc = 'Select language scope' })

    local swap = require 'nvim-treesitter-textobjects.swap'
    vim.keymap.set('n', '<leader>a', function()
      swap.swap_next '@parameter.inner'
    end, { desc = 'Swap with next parameter' })
    vim.keymap.set('n', '<leader>A', function()
      swap.swap_previous '@parameter.inner'
    end, { desc = 'Swap with previous parameter' })

    local move = require 'nvim-treesitter-textobjects.move'
    vim.keymap.set({ 'n', 'x', 'o' }, ']m', function()
      move.goto_next_start('@function.outer', 'textobjects')
    end, { desc = 'Next function start' })
    vim.keymap.set({ 'n', 'x', 'o' }, ']]', function()
      move.goto_next_start('@class.outer', 'textobjects')
    end, { desc = 'Next class start' })
    vim.keymap.set({ 'n', 'x', 'o' }, ']o', function()
      move.goto_next_start({ '@loop.inner', '@loop.outer' }, 'textobjects')
    end, { desc = 'Next loop start' })
    vim.keymap.set({ 'n', 'x', 'o' }, ']s', function()
      move.goto_next_start('@local.scope', 'locals')
    end, { desc = 'Next scope' })
    vim.keymap.set({ 'n', 'x', 'o' }, ']z', function()
      move.goto_next_start('@fold', 'folds')
    end, { desc = 'Next fold' })
    vim.keymap.set({ 'n', 'x', 'o' }, ']M', function()
      move.goto_next_end('@function.outer', 'textobjects')
    end, { desc = 'Next function end' })
    vim.keymap.set({ 'n', 'x', 'o' }, '][', function()
      move.goto_next_end('@class.outer', 'textobjects')
    end, { desc = 'Next class end' })
    vim.keymap.set({ 'n', 'x', 'o' }, '[o', function()
      move.goto_previous_start({ '@loop.inner', '@loop.outer' }, 'textobjects')
    end, { desc = 'Previous loop start' })
    vim.keymap.set({ 'n', 'x', 'o' }, '[m', function()
      move.goto_previous_start('@function.outer', 'textobjects')
    end, { desc = 'Previous function start' })
    vim.keymap.set({ 'n', 'x', 'o' }, '[[', function()
      move.goto_previous_start('@class.outer', 'textobjects')
    end, { desc = 'Previous class start' })
    vim.keymap.set({ 'n', 'x', 'o' }, '[M', function()
      move.goto_previous_end('@function.outer', 'textobjects')
    end, { desc = 'Previous function end' })
    vim.keymap.set({ 'n', 'x', 'o' }, '[]', function()
      move.goto_previous_end('@class.outer', 'textobjects')
    end, { desc = 'Previous class end' })
    vim.keymap.set({ 'n', 'x', 'o' }, ']c', function()
      move.goto_next('@conditional.outer', 'textobjects')
    end, { desc = 'Next conditional' })
    vim.keymap.set({ 'n', 'x', 'o' }, '[c', function()
      move.goto_previous('@conditional.outer', 'textobjects')
    end, { desc = 'Previous conditional' })
  end,
}
