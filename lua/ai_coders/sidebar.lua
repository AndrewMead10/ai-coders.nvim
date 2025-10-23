local M = {}

local state = {
  win = nil,
  placeholder_buf = nil,
}

local function escape_label(label)
  return (label or ""):gsub("%%", "%%%%")
end

local function build_header(sessions, current_index)
  if not sessions or vim.tbl_isempty(sessions) then
    return " AI Coders "
  end
  local parts = {}
  for idx, session in ipairs(sessions) do
    local title = escape_label(session.title or session.agent_key or ("Chat " .. idx))
    local tag = string.format("%d:%s", idx, title)
    if idx == current_index then
      table.insert(parts, string.format("[*%s*]", tag))
    else
      table.insert(parts, string.format("[ %s ]", tag))
    end
  end
  return " AI " .. table.concat(parts, " ") .. "  (ac:new | ad:close)"
end

local function valid_win(win)
  return win ~= nil and vim.api.nvim_win_is_valid(win)
end

local function ensure_placeholder_buf()
  if state.placeholder_buf and vim.api.nvim_buf_is_valid(state.placeholder_buf) then
    return state.placeholder_buf
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, "AI Coders Sidebar")
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "bufhidden", "hide")
  vim.api.nvim_buf_set_option(buf, "modifiable", false)

  local lines = {
    " AI Coders Sidebar",
    " ------------------",
    " <leader>a c : new chat",
    " <leader>a f : toggle",
    " <leader>a ] : next chat",
    " <leader>a [ : previous chat",
    " <leader>a d : close chat",
  }
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  state.placeholder_buf = buf
  return buf
end

local function apply_window_options(win)
  vim.api.nvim_win_set_option(win, "number", false)
  vim.api.nvim_win_set_option(win, "relativenumber", false)
  vim.api.nvim_win_set_option(win, "cursorline", false)
  vim.api.nvim_win_set_option(win, "cursorcolumn", false)
  vim.api.nvim_win_set_option(win, "signcolumn", "no")
  vim.api.nvim_win_set_option(win, "wrap", false)
  vim.api.nvim_win_set_option(win, "winfixwidth", true)
end

function M.is_open()
  return valid_win(state.win)
end

function M.close()
  if not M.is_open() then
    return
  end
  local win = state.win
  state.win = nil
  if vim.api.nvim_win_is_valid(win) then
    pcall(vim.api.nvim_win_close, win, true)
  end
end

function M.ensure_open(opts)
  if M.is_open() then
    return state.win
  end

  local width = opts.sidebar.width or 50
  local previous = vim.api.nvim_get_current_win()

  vim.cmd("botright " .. width .. "vsplit")
  local win = vim.api.nvim_get_current_win()
  apply_window_options(win)
  state.win = win

  vim.api.nvim_create_autocmd("WinClosed", {
    desc = "AI Coders sidebar closed",
    callback = function(event)
      if tonumber(event.match) == win then
        state.win = nil
      end
    end,
    once = true,
  })

  if not opts.sidebar.auto_focus and vim.api.nvim_win_is_valid(previous) then
    vim.api.nvim_set_current_win(previous)
  end

  return win
end

function M.show_placeholder(opts)
  if opts.sidebar.placeholder == false then
    return
  end
  local win = M.ensure_open(opts)
  if not win then
    return
  end
  local buf = ensure_placeholder_buf()
  vim.api.nvim_win_set_buf(win, buf)
  M.update_header({}, nil, opts)
end

function M.focus()
  if M.is_open() then
    vim.api.nvim_set_current_win(state.win)
  end
end

function M.show_buffer(buf, opts)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  local win = M.ensure_open(opts)
  if not win then
    return
  end
  vim.api.nvim_win_set_buf(win, buf)
  apply_window_options(win)
end

function M.get_win()
  return state.win
end

function M.update_header(sessions, current_index, opts)
  if not M.is_open() then
    return
  end
  if not opts or opts.sidebar.header == false then
    pcall(vim.api.nvim_win_set_option, state.win, "winbar", "")
    return
  end

  local header = build_header(sessions, current_index)
  pcall(vim.api.nvim_win_set_option, state.win, "winbar", header)
end

return M
