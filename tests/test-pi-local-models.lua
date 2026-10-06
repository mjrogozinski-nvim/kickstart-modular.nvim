-- Run with nvim --headless -u NONE -l tests/test-pi-local-models.lua
local root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h')
package.path = root .. '/lua/?.lua;' .. package.path
local sent, sessions, completion = {}, {}, nil
vim.notify = function() end
vim.system = function(_, _, callback) completion = callback end
local Rpc = {
  send = function(_, cmd, callback)
    sent[#sent + 1] = cmd.type
    if cmd.type == 'get_state' then
      callback({ success = true, data = { model = { provider = 'ollama', id = 'qwen3.8:27b-mtp-bf16' } } })
    end
    return true
  end,
}
package.loaded['pi.rpc'] = Rpc
package.loaded['pi.sessions.manager'] = { list_all = function() return sessions end }
require('code.pi-local-models').setup()
local rpc = setmetatable({ _job_id = 1, is_running = function() return true end }, { __index = Rpc })
local target = { type = 'set_model', provider = 'ds4-q2', modelId = 'deepseek-v4.1-flash' }
local function finish(code)
  completion({ code = code, stderr = code == 0 and '' or 'startup failed', stdout = '' })
  vim.wait(50, function() return false end, 10)
end
assert(rpc:send(target))
assert(#sent == 0, 'Model switched before server readiness')
assert(not rpc:send(target), 'Concurrent switch accepted')
finish(0)
assert(sent[1] == 'set_model')
sent = {}
assert(rpc:send(target))
finish(1)
assert(#sent == 0, 'Model switched after startup failure')
sessions = { { _detached_busy = true } }
assert(not rpc:send(target), 'Busy session allowed a switch')
sessions = {}
assert(rpc:send({ type = 'prompt', message = 'test' }))
vim.wait(50, function() return completion ~= nil end, 10)
-- Drain scheduled get_state callback before simulating the startup result.
vim.wait(50, function() return false end, 10)
rpc:send({ type = 'abort' })
finish(0)
assert(not vim.tbl_contains(sent, 'prompt'), 'Aborted prompt was sent after startup')
print('PASS: readiness, failure, concurrent switch, busy session and cancellation guards')
