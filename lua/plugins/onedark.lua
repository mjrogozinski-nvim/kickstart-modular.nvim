return {
  'navarasu/onedark.nvim',
  priority = 999, -- make sure to load this before all the other start plugins
  config = function()
    require('onedark').setup {
      style = 'warmer',
    }
    require('onedark').load()
  end,
}
