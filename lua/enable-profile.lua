Config_variant = os.getenv 'NVIM_CONFIG_VARIANT' or 'home'
local config_dir = vim.fn.stdpath 'config'
vim.opt.runtimepath:prepend(config_dir .. '/profiles/' .. Config_variant)
vim.notify('Profile enabled: ' .. config_dir .. '/profiles/' .. Config_variant, vim.log.levels.INFO)
-- check :messages
