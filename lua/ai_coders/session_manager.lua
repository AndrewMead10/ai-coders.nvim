local Terminal = require("ai_coders.terminal")
local Sidebar = require("ai_coders.sidebar")

local M = {}

local sessions = {}
local current_index = nil
local sequence = 0

local function activate_session(index, opts)
  current_index = index
  local session = sessions[index]
  if not session then
    Sidebar.show_placeholder(opts)
    Sidebar.update_header(sessions, current_index, opts)
    return
  end
  Sidebar.show_buffer(session.buf, opts)
  Sidebar.update_header(sessions, current_index, opts)
  if opts.session.on_session_activated then
    pcall(opts.session.on_session_activated, session)
  end
end

local function remove_session(index, opts, reason)
  local session = sessions[index]
  if not session then
    return
  end
  table.remove(sessions, index)
  if opts.session.on_session_closed then
    pcall(opts.session.on_session_closed, session, reason)
  end

  if #sessions == 0 then
    current_index = nil
    if not opts.sidebar.stay_open then
      Sidebar.close()
    else
      Sidebar.show_placeholder(opts)
    end
    Sidebar.update_header({}, nil, opts)
    return
  end

  if current_index == nil or current_index > #sessions then
    current_index = #sessions
  end
  activate_session(current_index, opts)
end

function M.new_session(agent_key, opts)
  local agent = opts.agents[agent_key]
  if not agent then
    vim.notify(string.format("[ai-coders] unknown agent '%s'", tostring(agent_key)), vim.log.levels.ERROR)
    return
  end
  if not agent.cmd or #agent.cmd == 0 then
    vim.notify(string.format("[ai-coders] agent '%s' has no launch command configured", agent_key), vim.log.levels.ERROR)
    return
  end

  sequence = sequence + 1
  local title = agent.name or agent_key
  if opts.session.title_format then
    title = string.format(opts.session.title_format, title, sequence)
  end

  local buf_ref
  local terminal, err = Terminal.open {
    agent_key = agent_key,
    title = title,
    cmd = agent.cmd,
    cwd = agent.cwd,
    env = agent.env,
    config = opts,
    on_exit = function()
      -- Find session index matching this buffer.
      for idx, sess in ipairs(sessions) do
        if buf_ref and sess.buf == buf_ref then
          remove_session(idx, opts, "exit")
          break
        end
      end
    end,
  }

  if not terminal then
    vim.notify("[ai-coders] failed to start agent: " .. (err or "unknown error"), vim.log.levels.ERROR)
    return
  end
  buf_ref = terminal.buf

  local session = {
    id = sequence,
    title = title,
    agent_key = agent_key,
    cmd = agent.cmd,
    buf = terminal.buf,
    job_id = terminal.job_id,
    created_at = os.time(),
  }

  table.insert(sessions, session)
  current_index = #sessions
  Sidebar.show_buffer(session.buf, opts)
  Sidebar.update_header(sessions, current_index, opts)

  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = session.buf,
    once = true,
    callback = function()
      M.remove_by_buf(session.buf, opts, "wipeout")
    end,
  })

  if opts.sidebar.auto_focus then
    Sidebar.focus()
  end

  if opts.session.on_session_created then
    pcall(opts.session.on_session_created, session)
  end

  return session
end

function M.sessions()
  return sessions
end

function M.current()
  return current_index and sessions[current_index] or nil
end

function M.current_index()
  return current_index
end

function M.cycle(offset, opts)
  if #sessions == 0 then
    Sidebar.show_placeholder(opts)
    Sidebar.update_header({}, nil, opts)
    return
  end
  if not current_index then
    current_index = 1
  end

  local next_index = ((current_index - 1 + offset) % #sessions) + 1
  activate_session(next_index, opts)
end

function M.activate(index, opts)
  if not sessions[index] then
    return
  end
  activate_session(index, opts)
end

function M.remove_by_buf(buf, opts, reason)
  for idx, session in ipairs(sessions) do
    if session.buf == buf then
      remove_session(idx, opts, reason or "manual")
      return
    end
  end
end

function M.close_current(opts)
  if not current_index or not sessions[current_index] then
    Sidebar.show_placeholder(opts)
    Sidebar.update_header({}, nil, opts)
    return
  end
  remove_session(current_index, opts, "manual")
end

function M.reset()
  sessions = {}
  current_index = nil
  sequence = 0
end

return M
