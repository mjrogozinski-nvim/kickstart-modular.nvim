-- Gate Pi RPC model switches and prompts on the local server lifecycle.
local M = {}
local busy = false
local targets = {
  ollama = 'qwen3.8:27b-mtp-bf16',
  ['ds4-q2'] = 'deepseek-v4.1-flash',
  ['ds4-q4'] = 'deepseek-v4.1-flash',
}

function M.setup()
  local Rpc = require 'pi.rpc'
  if Rpc._local_models_installed then return end
  Rpc._local_models_installed = true
  local send = Rpc.send
  local function fail(cmd, callback, message)
    vim.notify(message, vim.log.levels.ERROR, { title = 'Pi local models' })
    if callback then
      callback({ type = 'response', command = cmd.type, id = cmd.id, success = false, error = message })
    end
    return false
  end
  Rpc.send = function(self, cmd, callback)
    if cmd.type == 'abort' and self._local_model_pending then
      self._local_model_pending.cancelled = true
    end
    local prompt = cmd.type == 'prompt'
    local switching = cmd.type == 'set_model'
    if not switching and not prompt then
      if busy and (cmd.type == 'steer' or cmd.type == 'follow_up') then
        return fail(cmd, callback, 'Wait for the local model transition to finish')
      end
      return send(self, cmd, callback)
    end
    if busy then return fail(cmd, callback, 'A local model transition is already in progress') end
    for _, session in ipairs(require('pi.sessions.manager').list_all()) do
      if session._detached_busy or session._detached_retrying or session._detached_compacting
        or (session.chat and session.chat:is_streaming()) then
        return fail(cmd, callback, 'Wait for or abort the active Pi turn before switching or starting another turn')
      end
    end
    busy = true
    local pending = { job = self._job_id }
    self._local_model_pending = pending
    local function prepare(provider, model)
      if targets[provider] ~= model then
        busy = false
        self._local_model_pending = nil
        return fail(cmd, callback, 'This setup manages only Qwen 3.8 and DeepSeek V4.1 Q2/Q4')
      end
      if switching then vim.notify('Preparing ' .. provider .. ' (unload → start → ready)…') end
      vim.system({ 'python3', vim.fn.stdpath('config') .. '/scripts/pi-local-model.py', provider },
        { text = true }, vim.schedule_wrap(function(result)
          busy = false
          self._local_model_pending = nil
          if pending.cancelled then
            fail(cmd, callback, 'Local model request cancelled; no prompt was sent')
          elseif result.code ~= 0 then
            fail(cmd, callback, vim.trim(result.stderr or '') .. '\n' .. vim.trim(result.stdout or ''))
          elseif self:is_running() and self._job_id == pending.job then
            send(self, cmd, callback)
            if switching then vim.notify('Local server ready: ' .. provider) end
          else
            fail(cmd, callback, 'Pi session closed during model startup')
          end
        end))
      return true
    end
    if switching then return prepare(cmd.provider, cmd.modelId) end
    -- Resume/new-tab sessions also prepare their selected server before inference.
    local sent = send(self, { type = 'get_state' }, function(res)
      vim.schedule(function()
        local model = res.success and res.data and res.data.model
        if not model then
          busy = false
          self._local_model_pending = nil
          fail(cmd, callback, res.error or 'Could not determine the selected model')
          return
        end
        prepare(model.provider, model.id)
      end)
    end)
    if not sent then busy = false; self._local_model_pending = nil end
    return sent
  end
end

return M
