local M = {}

local function normalize_cmd(cmd)
  if cmd == nil then
    return nil
  end
  if type(cmd) == "string" then
    return { cmd }
  end
  return cmd
end

local default_agents = {
  codex = {
    name = "Codex",
    cmd = { "cx" },
    desc = "Codex CLI agent",
  },
  claude = {
    name = "Claude Code",
    cmd = { "claude" },
    desc = "Claude Code CLI",
  },
  {
    name = "GLM",
    cmd = { "glm" },
    desc = "GLM in the Claude Code CLI",

  },
}

M.defaults = {
  sidebar = {
    width = 50,
    auto_focus = true,
    focus_back = false,
    stay_open = true,
    placeholder = true,
  },
  mappings = {
    toggle = "<leader>af",
    new_session = "<leader>an",
    next_session = "<leader>a]",
    prev_session = "<leader>a[",
    pick_session = "<leader>ap",
  },
  agents = default_agents,
  session = {
    title_format = "%s #%d",
    on_session_created = nil,
    on_session_closed = nil,
    on_session_activated = nil,
  },
}

function M.merge(user_opts)
  local opts = vim.tbl_deep_extend("force", {}, M.defaults, user_opts or {})

  -- Normalize agents table.
  local agents = {}
  for key, agent in pairs(opts.agents or {}) do
    if type(agent) == "string" then
      agents[key] = {
        name = agent,
        cmd = { agent },
      }
    elseif type(agent) == "table" then
      agents[key] = vim.tbl_extend("force", {}, agent)
      agents[key].cmd = normalize_cmd(agents[key].cmd)
    end
  end
  opts.agents = agents

  -- Ensure mappings are unique strings or nil.
  for k, v in pairs(opts.mappings or {}) do
    if v ~= nil and type(v) ~= "string" then
      opts.mappings[k] = nil
    end
  end

  opts.sidebar.width = math.max(opts.sidebar.width or 50, 20)

  M.options = opts
  return opts
end

return M
