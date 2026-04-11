-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Enable ruff LSP alongside basedpyright (LazyVim python extra)
vim.g.lazyvim_python_ruff = "ruff"

-- Enable autoread to automatically reload files when they are changed outside of Neovim
vim.opt.autoread = true
