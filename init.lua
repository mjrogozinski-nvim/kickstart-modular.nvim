--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.have_nerd_font = true

require 'options'

require 'lazy-bootstrap'
require 'lsp-config'

require 'code.sane.change'
require 'code.sane.copy'
require 'code.sane.wincmd'
require 'code.sane.noh'
require 'code.sane.exit-terminal'
require 'code.sane.autosave'
require 'code.sane.q-closes-buffers'
require 'code.sane.dont-autocomment-new-line'
require 'code.sane.paste-over-selection'
require 'code.sane.H-jumps-to-bol'
require 'code.sane.L-jumps-to-eol'
require 'code.sane.C-H-jumps-to-bol'
require 'code.sane.C-L-jumps-to-eol'

require 'code.highlight-on-yank'
require 'code.active-file-only-active-line'
require 'code.spell-check-these-files'
require 'code.autoresize'
require 'code.open-reference-in-second-split'

require 'code.copy-file-path'
require 'code.edit-configuration'
require 'code.file-grep'
require 'code.completion-jumping'

require 'code.multi-line-star'
require 'code.make-session'
require 'code.qflist-open-close'
require 'code.qflist-navigation'
require 'code.close-buffer'
require 'code.move-line'
require 'code.overseer-keybindings'
require 'code.neotest-init-config'

require 'code.select-colorscheme'

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
