local Config = require("ai_coders.config")
local Sidebar = require("ai_coders.sidebar")
local Sessions = require("ai_coders.session_manager")

local M = {}

local commands_created = false

local function find_index(list, value)
  for idx, item in ipairs(list) do
    if item == value then
      return idx
    end
  end
end

local function pick_agent()
  local opts = Config.options
  local entries = {}
  for key, agent in pairs(opts.agents or {}) do
    table.insert(entries, {
      key = key,
      name = agent.name or key,
      desc = agent.desc,
    })
  end
  table.sort(entries, function(a, b)
    return a.name < b.name
  end)

  local choices = vim.tbl_map(function(item)
    if item.desc then
      return string.format("%s — %s", item.name, item.desc)
    end
    return item.name
  end, entries)

  return entries, choices
end

local function ensure_placeholder()
  local session = Sessions.current()
  if session then
    Sidebar.show_buffer(session.buf, Config.options)
  else
    Sidebar.show_placeholder(Config.options)
  end
end

function M.toggle()
  if Sidebar.is_open() then
    Sidebar.close()
  else
    ensure_placeholder()
  end
end

function M.new_session(agent_key)
  local opts = Config.options
  if not agent_key then
    local entries, choices = pick_agent()
    if #entries == 0 then
      vim.notify("[ai-coders] no agents configured", vim.log.levels.WARN)
      return
    end

    vim.ui.select(choices, {
      prompt = "Select AI agent",
    }, function(choice)
      if not choice then
        return
      end
      local index = find_index(choices, choice)
      if not index then
        return
      end
      local entry = entries[index]
      Sessions.new_session(entry.key, opts)
    end)
    return
  end

  Sessions.new_session(agent_key, Config.options)
end

function M.next_session()
  Sessions.cycle(1, Config.options)
end

function M.prev_session()
  Sessions.cycle(-1, Config.options)
end

function M.pick_session()
  local opts = Config.options
  local current_sessions = Sessions.sessions()
  if #current_sessions == 0 then
    vim.notify("[ai-coders] no active chats", vim.log.levels.INFO)
    return
  end

  local labels = {}
  for _, session in ipairs(current_sessions) do
    table.insert(labels, session.title)
  end

  vim.ui.select(labels, {
    prompt = "Select AI chat",
  }, function(choice)
    if not choice then
      return
    end
    local idx = find_index(labels, choice)
    if idx then
      Sessions.activate(idx, opts)
    end
  end)
end

local function create_commands()
  if commands_created then
    return
  end
  vim.api.nvim_create_user_command("AICodersToggle", function()
    M.toggle()
  end, {})

  vim.api.nvim_create_user_command(
    "AICodersNew",
    function(cmd)
      local arg = cmd.args ~= "" and cmd.args or nil
      M.new_session(arg)
    end,
    {
      nargs = "?",
      complete = function(arg_lead)
        local results = {}
        for key in pairs(Config.options.agents or {}) do
          if arg_lead == "" or vim.startswith(key, arg_lead) then
            table.insert(results, key)
          end
        end
        table.sort(results)
        return results
      end,
    }
  )

  vim.api.nvim_create_user_command("AICodersNext", function()
    M.next_session()
  end, {})

  vim.api.nvim_create_user_command("AICodersPrev", function()
    M.prev_session()
  end, {})

  vim.api.nvim_create_user_command("AICodersPick", function()
    M.pick_session()
  end, {})

  commands_created = true
end

local function set_keymaps()
  local maps = Config.options.mappings or {}
  local map_opts = { noremap = true, silent = true }
  if maps.toggle then
    vim.keymap.set("n", maps.toggle, M.toggle, vim.tbl_extend("force", map_opts, { desc = "AI Coders: Toggle sidebar" }))
  end
  if maps.new_session then
    vim.keymap.set("n", maps.new_session, function()
      M.new_session()
    end, vim.tbl_extend("force", map_opts, { desc = "AI Coders: New chat" }))
  end
  if maps.next_session then
    vim.keymap.set("n", maps.next_session, M.next_session, vim.tbl_extend("force", map_opts, { desc = "AI Coders: Next chat" }))
  end
  if maps.prev_session then
    vim.keymap.set("n", maps.prev_session, M.prev_session, vim.tbl_extend("force", map_opts, { desc = "AI Coders: Previous chat" }))
  end
  if maps.pick_session then
    vim.keymap.set("n", maps.pick_session, M.pick_session, vim.tbl_extend("force", map_opts, { desc = "AI Coders: Pick chat" }))
  end
end

function M.setup(user_opts)
  local opts = Config.merge(user_opts)
  create_commands()
  set_keymaps()

  if opts.autostart then
    vim.api.nvim_create_autocmd("VimEnter", {
      once = true,
      callback = function()
        local default_agent = opts.autostart_agent or opts.autostart
        if type(default_agent) == "string" then
          M.new_session(default_agent)
        else
          ensure_placeholder()
        end
      end,
    })
  end
end

return M
