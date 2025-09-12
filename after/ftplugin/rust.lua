local in_current_buffer = require 'code.utils.buf-key-map'

vim.keymap.set('n', '<leader>ct', function()
  vim.cmd.RustLsp { 'testables', bang = false }
end, in_current_buffer.with_desc 'RustTest!')

vim.keymap.set('n', '<leader>x', function()
  vim.cmd.RustLsp 'run'
end, in_current_buffer.with_desc 'Rust run')

vim.keymap.set('n', '<leader>X', function()
  vim.cmd.RustLsp 'debug'
end, in_current_buffer.with_desc 'Rust debug')

-- TODO: remove duplication
-- find a better way of running cargo and populating quickfix list
-- there has to be a ready solution for this!
-- One option is to use
--   lua vim.cmd.RustLsp('renderDiagnostic')
--   but it cycles through all the diagnostics, not just errors

local overseer = require 'overseer'
overseer.register_template {
  name = 'CargoBuild',
  builder = function()
    return {
      cmd = { 'cargo' },
      args = { 'build' },
      components = {
        { 'on_output_quickfix', open = false },
        'default',
      },
    }
  end,
  desc = 'Run `cargo build` in current Rust project',
  tags = { 'rust', 'cargo' },
  priority = 50,
}

vim.keymap.set('n', '<leader>cm', function()
  overseer.run_template { name = 'CargoBuild' }
end, {
  silent = true,
  desc = 'cargo build',
})

overseer.register_template {
  name = 'CargoRun',
  builder = function()
    return {
      cmd = { 'cargo' },
      args = { 'run' },
      components = {
        { 'on_output_quickfix', open = false },
        'default',
      },
    }
  end,
  desc = 'Run `cargo run` in current Rust project',
  tags = { 'rust', 'cargo' },
  priority = 50,
}

vim.keymap.set('n', '<leader>cr', function()
  overseer.run_template { name = 'CargoRun' }
end, {
  silent = true,
  desc = 'cargo run',
})
