local Sidebar = require("ai_coders.sidebar")

local M = {}

local function prepare_env(extra_env)
  if not extra_env then
    return nil
  end
  local env = {}
  for k, v in pairs(extra_env) do
    env[k] = v
  end
  return env
end

local function sanitize_cmd(cmd)
  if not cmd or #cmd == 0 then
    return nil, "no command provided"
  end
  if type(cmd) == "table" then
    return cmd, nil
  end
  return { cmd }, nil
end

function M.open(opts)
  local cmd, cmd_err = sanitize_cmd(opts.cmd)
  if not cmd then
    return nil, cmd_err
  end

  local win = Sidebar.ensure_open(opts.config)
  if not win then
    return nil, "failed to open sidebar window"
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, "filetype", "ai_coders_terminal")
  vim.api.nvim_buf_set_option(buf, "bufhidden", "hide")

  vim.api.nvim_win_set_buf(win, buf)

  local term_opts = {
    cwd = opts.cwd,
    env = prepare_env(opts.env),
    on_exit = function(job_id, code, event)
      if opts.on_exit then
        opts.on_exit(job_id, code, event)
      end
    end,
  }

  local job_id
  vim.api.nvim_win_call(win, function()
    job_id = vim.fn.termopen(cmd, term_opts)
  end)

  if job_id <= 0 then
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
    return nil, "termopen failed"
  end

  if vim.api.nvim_buf_is_valid(buf) then
    pcall(vim.api.nvim_buf_set_option, buf, "swapfile", false)
    pcall(vim.api.nvim_buf_set_option, buf, "buflisted", false)
  end

  return {
    buf = buf,
    job_id = job_id,
    win = win,
  }
end

return M
