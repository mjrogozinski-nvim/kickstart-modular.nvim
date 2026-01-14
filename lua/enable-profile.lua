Config_profile = os.getenv 'NVIM_CONFIG_PROFILE' or 'home'
local config_dir = vim.fn.stdpath 'config'
vim.opt.runtimepath:prepend(config_dir .. '/profiles/' .. Config_profile)
vim.notify('Profile enabled: ' .. config_dir .. '/profiles/' .. Config_profile, vim.log.levels.INFO)
-- check :messages
