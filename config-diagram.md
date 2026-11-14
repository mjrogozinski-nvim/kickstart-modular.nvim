# nvim configuration — architecture diagram

A map of `~/.config/nvim`. The editable source of truth is [config-diagram.mmd](config-diagram.mmd);
re-render with `npx @mermaid-js/mermaid-cli -i config-diagram.mmd -o config-diagram.svg -b white`.

<details open><summary>Diagram</summary>

```mermaid
{% include config-diagram.mmd %}
```

Paste the `.mmd` contents into https://mermaid.live if the include does not render.

</details>

## Reading the map

**Startup chain (`init.lua`):**

1. `mapleader`/`maplocalleader` = space (must be first)
2. `lua/options.lua` — editor options
3. `lua/lazy-bootstrap.lua` — clones `lazy.nvim` into `~/.local/share/nvim/lazy/`, then
   imports specs from: `plugins/`, `plugins/mini/`, `plugins/colorschemes/`,
   `plugins/cpp/`, `plugins/haskell/`, `plugins/rust/`, `plugins/python/`, `plugins/debug/`
4. `lua/enable-profile.lua` — prepends `profiles/$NVIM_CONFIG_PROFILE` (default `home`) to
   `runtimepath`, so `init.lua` can `require 'code.' .. Config_profile .. '.all'`
5. `lua/lsp-config.lua` — native `vim.lsp.enable` for `ast-grep` (config in `lsp/ast-grep.lua`) and `nixd`
6. `code/sane/*` — 13 small behavior fixes
7. `code/*` — ~20 personal mappings/utilities (qflist, sessions, grep, colorcycle, …)
8. profile entrypoint — `home` profile wires `overseer-keybindings` (and `gtest-actions`) to
   overseer / treesitter-actions / dap

**Plugin group highlights:**

| Group | Plugins |
|---|---|
| UI / nav | snacks, which-key, trouble, todo-comments, gitsigns, switch.vim, grug-far, fzf-lua, telescope |
| LSP | nvim-lspconfig + Mason (tool installer, fidget, lazydev), lspsaga, lsp-selection-range, ast-grep, nixd |
| Completion / format | blink.cmp (+ LuaSnip), conform.nvim (format-on-save) |
| Treesitter | nvim-treesitter (eager, `:TSUpdate`), tree-sitter-manager, textobjects, custom `queries/` for cpp/lua/python |
| AI (local-first) | pi2.nvim (ollama, qwen3.8:27b-mtp-bf16), codecompanion (custom Ollama adapters, `local-ai.lua`), render-markdown; both talk to a local Ollama |
| Testing / builds | neotest (+ gtest, python, vim-test, busted adapters), overseer (build/test tasks) |
| Debug | nvim-dap + nvim-dap-virtual-text |
| Git | lazygit, vim-fugitive, gitsigns |
| Languages | rustaceanvim, haskell-tools, clangd_extensions, esp32.nvim, python venv-selector |
| Colors | base16-vim, flexoki, kanagawa, melange, onedark, SpacegrayEighties (cycled via `select-colorscheme`) |
| mini.nvim | ai, files, indentscope, jump2d, move, statusline, surround |

**Support:** `after/ftplugin/` (lua, cmake, python, haskell, rust, gitcommit),
`scripts/pi-local-model.py` (invoked by `code/pi-local-models.lua`),
`tests/` + `Makefile` (headless sanity checks), `ideas/` (vision/tasks).