--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.have_nerd_font = true

require 'options'

require 'lazy-bootstrap'

require 'code.sane.change'
require 'code.sane.copy'
require 'code.sane.wincmd'
require 'code.sane.noh'
require 'code.sane.exit-terminal'
require 'code.sane.autosave'
require 'code.copy-file-path'
require 'code.highlight-on-yank'
require 'code.edit-configuration'
require 'code.file-grep'
require 'code.completion-jumping'

require 'code.multi-line-star'
require 'code.make-session'
require 'code.qflist-open-close'
require 'code.qflist-navigation'
require 'code.close-buffer'
require 'code.move-line'
require 'code.mini-surround-fix'
require 'code.overseer-keybindings'
require 'code.neotest-init-config'

require 'code.ast-grep-lspconfig'

require 'code.select-colorscheme'

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
