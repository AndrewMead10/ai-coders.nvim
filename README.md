# AI Coders

AI Coders is a Neovim plugin that gives you a right-side sidebar for chatting with multiple terminal-based coding agents such as Codex, Claude Code, or any other CLI-powered assistant. Sessions run in standard Neovim terminal buffers so you can see full streaming output, keep history per chat, and manage multiple conversations side-by-side with your code.

## Features

- Toggleable sidebar pinned on the right (default width `50`).
- Create as many chat sessions as you like, each backed by its own terminal buffer.
- Cycle between active chats or pick one from a quick selector.
- Fully configurable agent registry: give each agent a label and launch command.
- Sensible default keymaps that follow the requested `<leader>a` namespace.

## Default Keymaps

| Mapping          | Action                         |
| ---------------- | ------------------------------ |
| `<leader>af`     | Toggle the sidebar             |
| `<leader>ac`     | Create a new chat session      |
| `<leader>a]`     | Cycle to the next chat session |
| `<leader>a[`     | Cycle to the previous session  |
| `<leader>ap`     | Pick a chat from a list        |

All mappings can be changed (or disabled) via `setup`.

## Installation (AstroNvim example)

Add the plugin to your AstroNvim `plugins/` specification (using lazy.nvim syntax):

```lua
return {
  {
    "yourname/ai-coders",
    lazy = false,
    config = function()
      require("ai_coders").setup {
        sidebar = {
          width = 60,
          auto_focus = true,
        },
        agents = {
          codex = {
            name = "Codex",
            cmd = { "codex", "--chat" },
          },
          claude = {
            name = "Claude Code",
            cmd = { "claude-code", "--chat" },
          },
          open_interpreter = {
            name = "Open Interpreter",
            cmd = { "open-interpreter", "--shell" },
          },
        },
      }
    end,
  },
}
```

Adjust the commands to match the CLIs you have installed. The plugin ships with placeholder commands for Codex (`codex`) and Claude Code (`claude-code`); if you do not have those binaries, replace them.

## Usage

1. Press `<leader>af` to open the sidebar. A help buffer appears if no sessions are active.
2. Press `<leader>ac`, pick an agent from the menu, and a new terminal buffer launches that agent CLI.
3. Use `<leader>a]` / `<leader>a[` to cycle through chats, or `<leader>ap` to pick from a list.
4. Close the sidebar with `<leader>af`. Sessions keep running in the background, so reopening the sidebar restores the last active chat.

## Configuration Reference

```lua
require("ai_coders").setup {
  sidebar = {
    width = 50,         -- sidebar width when opened
    auto_focus = true,  -- focus the sidebar after creating a session
    focus_back = false, -- reserved for future use
    stay_open = true,   -- keep sidebar visible after last session closes
    placeholder = true, -- show a helper buffer when no sessions exist
  },
  mappings = {
    toggle = "<leader>af",
    new_session = "<leader>ac",
    next_session = "<leader>a]",
    prev_session = "<leader>a[",
    pick_session = "<leader>ap",
  },
  agents = {
    codex = { name = "Codex", cmd = { "codex" } },
    claude = { name = "Claude Code", cmd = { "claude-code" } },
  },
  session = {
    title_format = "%s #%d",
    on_session_created = function(session) end,
    on_session_closed = function(session, reason) end,
    on_session_activated = function(session) end,
  },
}
```

- **Agents**: keys are user-facing names for `:AICodersNew {agent}`. `cmd` accepts a string or list.
- **Callbacks**: optional hooks for integrating with status lines or logging.

## Commands

- `:AICodersToggle`
- `:AICodersNew [agent]`
- `:AICodersNext`
- `:AICodersPrev`
- `:AICodersPick`

## Roadmap Ideas

- Persistent session history across Neovim restarts.
- Telescope integration for picking sessions and agents.
- Inline input prompt for sending commands without leaving current window.
- Optional floating-window layout.

Contributions and ideas are welcome—open an issue or pull request! 🌟
