if vim.g.loaded_ai_coders then
  return
end
vim.g.loaded_ai_coders = true

local ok, ai_coders = pcall(require, "ai_coders")
if not ok then
  return
end

ai_coders.setup()
